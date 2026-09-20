# SoundScan

Audio upload and analysis service.

## Overview

SoundScan is focused on taking an uploaded MP3 file, reading its metadata, checking whether it has already been processed, scoring its audio quality, and returning a clean JSON response.

## Tech Stack

The project is built with Ruby on Rails on the backend. The audio metadata is read with `ruby-mp3info`, while Rails models and Active Record handle saving each analysis result.

The main technical pieces are:

- `ruby-mp3info` for reading MP3 duration, bitrate, sample rate, and header data.
- `Digest::SHA256` for creating a stable file hash and detecting duplicate uploads.

## Project Structure

The audio work is split into small files so each class has one clear responsibility.

`Audio::Analyzer` is the main entry point. It receives the uploaded audio file, reads the MP3 metadata, validates the file, checks for duplicates, runs the outlier detector, saves the result, and returns the serialized response.

`Audio::AnalysisSerializer` shapes the saved upload into the response format used by the API. It keeps the response predictable by returning the upload id, duration, quality score, outlier status, outlier codes, and basic metadata.

`Audio::OutlierDetector` applies the quality scoring rules. It checks for critical issues first, then falls back to moderate rules when no critical rule is found.

`Audio::OutlierRules` keeps the actual scoring rules in one place. This makes it easier to adjust thresholds later without digging through the main analyzer flow.

`AudioUploads::AnalysisError` is used when metadata extraction or saving the analysis fails. It gives the upload flow a specific error type instead of exposing low-level exceptions directly.

## Getting Started

This project has two parts:

- backend API in `server/`
- frontend app in `client/`

The frontend is intentionally run outside Docker during development. The backend runs in Docker, while the React app runs locally with Vite.

### Prerequisites

- Docker Desktop or Docker Engine installed
- Docker Compose plugin enabled (`docker compose`)
- Node.js 18+ and npm installed for the frontend
- Ruby 3.3+ and Bundler only if you want to run Rails locally outside Docker

### Backend setup (Docker)

From the project root, run:

```sh
docker compose down -v
docker compose build --no-cache server
docker compose up -d db
docker compose run --rm server bin/rails db:setup
docker compose up --build
```

This starts the PostgreSQL database and the Rails API on:

```text
http://localhost:3000
```

### Frontend setup (local, outside Docker)

In a second terminal, run:

```sh
cd client
npm install
npm run dev
```

This starts the React app on:

```text
http://localhost:5173
```

### Normal workflow

Start the backend:

```sh
docker compose up --build
```

Then in a second terminal, start the frontend:

```sh
cd client
npm run dev
```

### Local backend setup (optional)

If you want to run the Rails app directly on your machine instead of Docker, use the `server` folder:

```sh
cd server
bundle install
bin/rails db:setup
bin/rails server
```

### Troubleshooting

If you see `Bundler::GemNotFound`, the Ruby gems were not installed successfully. Rebuild the backend image:

```sh
docker compose build --no-cache server
```

If the database is missing or the app cannot connect, run:

```sh
docker compose run --rm server bin/rails db:setup
```

If the frontend has missing packages or install issues, run:

```sh
cd client
rm -rf node_modules package-lock.json
npm install
```

If you are using the older standalone Compose command, `docker-compose` can usually be swapped for `docker compose` with the same arguments.

## API
### Call with Postman
To test this endpoint using Postman, configure your request using the following steps:
1. Set the HTTP method dropdown to POST
2. Enter your API endpoint URL (e.g., http://localhost:3000/api/upload).
3. Navigate to the Headers tab.
4. Add the following key-value pair: Key: Accept and Value: application/json
5. Navigate to the Body tab..
6. Select the form-data option and set Key 'audio'. Hover over the input box, click the dropdown menu that appears on the right side of the field, and change the type from Text to File.
7. Select the file and send

On success, the analyzer returns a response shaped like this:

```json
{
  "success": true,
  "result": {
    "id": 1,
    "duplicate": false,
    "duration": "03:24",
    "is_outlier": false,
    "outliers": [],
    "quality_score": 10,
    "metadata": {
      "filename": "track.mp3",
      "bitrate_kbps": 128,
      "sample_rate_hz": 44100
    }
  }
}
```

## Testing
Added unit specs in two files:
- `server/spec/models/audio_upload_spec.rb`
- `server/spec/requests/api/audio_uploads_spec.rb`

To run unit specs execute:

```bash
docker-compose run --rm -e RAILS_ENV=test server bundle exec rspec --format documentation
```

## Architecture

This application is built using a simple, step-by-step pipeline. Instead of putting all the code in one place, it splits the work into readable DRY specialized parts.

* **The Server (Rails 8 Backend):** It takes the uploaded file (postman request), analyze and save it to database, returns the analysis result.
* **The Database (PostgreSQL):** It securely stores the file details.
* **The Container (Docker Compose):** A box that wraps the Server and Database together so the app can run on any computer with just one command.

## The 3 Layers of Defense (Simple Breakdown)

###  1. Controller-Level Checks
This is the very first line of defense. It first identify params, only permits required ones. Identification of duplicate files including fake or no file attachment is the part of these checks as well.

###  2. Model-Level Validations
It inspects the details of the data right before saving. If something is wrong, it creates a nice error message (like *"must be a grade between 1 and 10"*) to show to the user.

### 3. DB-Level Constraints
This is the ultimate, unbreakable layer built directly into our PostgreSQL database. Even if a bug in our code bypasses the first two layers, the database will physically block duplicate or invalid data from corrupting our tables. Few examples are uniqueness constraints, not null contraints etc.

A key example is the unique index on `audio_uploads.file_hash`. This ensures that the same MP3 content cannot be saved twice, while also making duplicate lookups fast and efficient at query time.

### Step-by-Step File Journey
When a file is uploaded, it goes through 3 quick steps:

1. **Check for Duplicates:** The app looks at the file's digital fingerprint (SHA-256). If the exact same file was uploaded before, it stops immediately and return.
2. **Check for Fake Files:** The app opens the file headers using `Mp3Info`. If the file is actually a hidden image or video (like a `.jpg` renamed to `.mp3`), the app catches it and rejects it.
3. **Calculate the Score:** The app checks the file against our quality rules. It subtracts points for any issues found and outputs the final quality score out of 10.


## Outlier Logic

We have two types of outliers, the critical and the moderate outlier, each containing two seperate parameters to identify where it lies. The outlier logic is assuming that we have unusual duration, bitrate, or sample rate values that signals that an MP3 may not be of a normal-quality.

The score starts at `10`. If a critical rule matches, the system then skips to check other rules and straight away subtracts `9`, which leaves the upload with a score of `1`. At the moment, critical rules include files shorter than 5 seconds, longer than 900 seconds( less value indicates file sample is too less to analyze, higher value indicates its probably too long to analyze assuming we are analyzing mp3 music files only), or files with a bitrate above 340 kbps( indicates its fake or currupted file).

If no critical rule matches, the detector checks moderate rules instead. A bitrate below 96 kbps subtracts `4`, and a sample rate below 3200 Hz subtracts `3`. Adds total outliers score and subtract it from 10.

These signals were chosen because they are available directly from MP3 metadata and are quick to evaluate. Duration catches files that are too short to be useful or too long for the expected upload range, bitrate helps flag very low-quality or unusually large files, and sample rate helps catch audio that may sound poor or be encoded below normal expectations.

## Assumptions
1. **Format Scope:** The current implementation assumes that our system only analyzes and processes MP3 music files with a maximum duration of 15 minutes.
2. **Originality Verification:** The system assumes that checking the `.mp3` extension along with MP3 header profiles (including emphasis and layer values) is sufficient to verify file originality.
3. **Tamper Indicators:** The design assumes that a header configuration where `emphasis == 3` or `layer != 3` indicates that a file extension has been tampered with.
4. **Duplicate Safeguards:** The detection layer assumes duplicate files should be identified solely using an exact matching SHA-256 hash footprint.
5. **File Storage:** This app only analyze the mp3 file and share results, we dont need to store this file anywhere, app will process, save results and response.

## Trade-offs
1. **Fast execution over Deep Inspection:**  Used lightweight mp3info for metadata inspection over deep audio inspection which could require more dependencies.
2. **Easy setup over Production-grade Security:** By sticking only to mp3info header checks are acquire simple codebase and requires no extra installation.

## Future Improvements

Future work could add more detailed audio checks, such as loudness, clipping and analyzing sound.

The outlier rules could also be expanded after analyzing the sound, loudness etc.

Dedicated tests for the analyzer, serializer, detector, and rules would make the service safer to change. A later version could also move permanent file storage into Active Storage or another storage service if uploaded audio needs to be kept after analysis.

Dedicated frontend with frontend validations and error handling, would use typescript instead of plain js. Could add frontend specs aswell.
