# SoundScan

Audio upload and analysis service.

## Overview

SoundScan is focused on taking an uploaded MP3 file, reading its metadata, checking whether it has already been processed, scoring its audio quality, and returning a clean JSON response.

The work documented here is limited to the audio analysis service layer:

- `server/app/services/audio/analyzer.rb`
- `server/app/services/audio/analysis_serializer.rb`
- `server/app/services/audio/outlier_detector.rb`
- `server/app/services/audio/outlier_rules.rb`
- `server/app/services/audio_uploads/analysis_error.rb`

Together, these files form the core flow for an upload: extract MP3 metadata, validate the file, detect duplicates, evaluate quality outliers, save the analysis record, and serialize the result for the API response.

## Tech Stack

This part of the project is built with Ruby on Rails on the backend. The audio metadata is read with `ruby-mp3info`, while Rails models and Active Record handle saving each analysis result.

The main technical pieces used in the files above are:

- Ruby service objects for keeping the upload analysis logic organized.
- `ruby-mp3info` for reading MP3 duration, bitrate, sample rate, and header data.
- `Digest::SHA256` for creating a stable file hash and detecting duplicate uploads.
- Active Record for saving the final `AudioUpload` analysis record.
- Custom error classes so analysis failures can be handled clearly by the API layer.

## Project Structure

The audio work is split into small files so each class has one clear responsibility.

`Audio::Analyzer` is the main entry point. It receives the uploaded audio file, reads the MP3 metadata, validates the file, checks for duplicates, runs the outlier detector, saves the result, and returns the serialized response.

`Audio::AnalysisSerializer` shapes the saved upload into the response format used by the API. It keeps the response predictable by returning the upload id, duration, quality score, outlier status, outlier codes, and basic metadata.

`Audio::OutlierDetector` applies the quality scoring rules. It checks for critical issues first, then falls back to moderate rules when no critical rule is found.

`Audio::OutlierRules` keeps the actual scoring rules in one place. This makes it easier to adjust thresholds later without digging through the main analyzer flow.

`AudioUploads::AnalysisError` is used when metadata extraction or saving the analysis fails. It gives the upload flow a specific error type instead of exposing low-level exceptions directly.

## Getting Started

The analysis code lives inside the Rails server, so run setup commands from the `server` folder.

```sh
cd server
bundle install
bin/rails db:setup
bin/rails server
```

The analyzer expects an uploaded MP3 file. It uses the file's temporary path while processing, so it is designed to run as part of a normal Rails file upload request rather than as a standalone script.

## API

The upload flow is used by the JSON API endpoint:

```http
POST /api/upload
```

The request should include an `audio` file parameter containing an MP3 file.

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

If the file cannot be analyzed, the custom analysis error allows the API to return a clear failure response instead of an unexpected server error.

## Testing

The most useful tests for these files are service-level tests. The analyzer should be tested with valid MP3 uploads, invalid files, duplicate uploads, metadata extraction failures, and database save failures.

The outlier detector can be tested separately with fake metadata objects. That keeps the scoring rules easy to verify without needing a real audio file for every case.

The serializer should be tested with a saved `AudioUpload` record so the API response stays stable as the project grows.

From the `server` folder, the Rails test suite can be run with:

```sh
bin/rails test
```

## Architecture

An upload enters through `Audio::Analyzer.call`. The analyzer extracts metadata with `Mp3Info`, rejects invalid MP3 structure, hashes the file contents with SHA-256, and checks the database for an existing upload with the same hash.

After that, `Audio::OutlierDetector` calculates the quality score. Critical rules take priority because they represent stronger signals that the file is outside the expected range. If no critical rule applies, the detector checks moderate rules and subtracts their penalties from a starting score of 10.

Once the record is saved, `Audio::AnalysisSerializer` turns the `AudioUpload` model into a small JSON-friendly hash. This keeps API formatting separate from analysis and persistence.

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

## Trade-offs
1. **Fast execution over Deep Inspection**  Used lightweight mp3info for metadata inspection over deep audio inspection which could require more dependencies.
2. **Easy setup over Production-grade Security** By sticking only to mp3info header checks are acquire simple codebase and requires no extra installation.

## Future Improvements

Future work could add more detailed audio checks, such as loudness, clipping and analyzing sound.

The outlier rules could also be expanded after analyzing the sound, loudness etc.

Dedicated tests for the analyzer, serializer, detector, and rules would make the service safer to change. A later version could also move permanent file storage into Active Storage or another storage service if uploaded audio needs to be kept after analysis.
