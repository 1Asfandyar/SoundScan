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

The flow is intentionally simple and service-driven.

An upload enters through `Audio::Analyzer.call`. The analyzer extracts metadata with `Mp3Info`, rejects invalid MP3 structure, hashes the file contents with SHA-256, and checks the database for an existing upload with the same hash.

After that, `Audio::OutlierDetector` calculates the quality score. Critical rules take priority because they represent stronger signals that the file is outside the expected range. If no critical rule applies, the detector checks moderate rules and subtracts their penalties from a starting score of 10.

Once the record is saved, `Audio::AnalysisSerializer` turns the `AudioUpload` model into a small JSON-friendly hash. This keeps API formatting separate from analysis and persistence.

## Outlier Logic

The outlier logic is based on a simple assumption: unusual duration, bitrate, or sample rate values are useful early signals that an MP3 may not be a normal-quality upload.

The score starts at `10`. If a critical rule matches, only that critical rule is used and its penalty is subtracted. At the moment, critical rules include files shorter than 5 seconds, longer than 900 seconds, or files with a bitrate above 340 kbps. Each critical rule subtracts `9`, which leaves the upload with a score of `1`.

If no critical rule matches, the detector checks moderate rules instead. A bitrate below 96 kbps subtracts `4`, and a sample rate below 3200 Hz subtracts `3`. The remaining value becomes the final `quality_score`.

These signals were chosen because they are available directly from MP3 metadata and are quick to evaluate. Duration catches files that are too short to be useful or too long for the expected upload range, bitrate helps flag very low-quality or unusually large files, and sample rate helps catch audio that may sound poor or be encoded below normal expectations.

## Assumptions

The current implementation assumes the uploaded file should be an MP3 and that checking the `.mp3` extension plus MP3 header details is enough for this stage of the project.

It also assumes duplicate detection should be based on the exact file contents. If the same audio is uploaded with even a tiny byte-level change, it will receive a different SHA-256 hash and will not be treated as the same file.

The outlier rules are intentionally heuristic. They do not prove that an audio file is good or bad; they give the API a lightweight way to flag files that deserve attention.

## Trade-offs

The analyzer handles several steps in one place, which keeps the upload flow easy to follow. The trade-off is that it has a few responsibilities: metadata extraction, validation, duplicate checking, outlier scoring, and saving. If the flow grows, some of those steps could be split into smaller collaborators.

The outlier rules are simple Ruby hashes with lambdas. This keeps them readable and easy to change, but it does mean there is no separate rule engine or admin-managed configuration.

The stored `storage_path` is the temporary upload path used during analysis. That is enough for recording what was processed during this flow, but it is not the same as long-term file storage.

## Future Improvements

Future work could add more detailed audio checks, such as codec validation, channel count, loudness, clipping, or corrupted-frame detection.

The outlier rules could also be expanded with clearer severity levels, rule descriptions, and user-facing messages instead of returning only rule codes.

Dedicated tests for the analyzer, serializer, detector, and rules would make the service safer to change. A later version could also move permanent file storage into Active Storage or another storage service if uploaded audio needs to be kept after analysis.
