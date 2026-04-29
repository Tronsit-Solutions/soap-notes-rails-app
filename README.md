# Medscribe API

A Rails API implementation for audio transcription using OpenAI's `gpt-4o-mini-transcribe` model.

## Requirements

- Ruby 3.x
- Rails 8.x
- OpenAI API Key

## Setup

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Configure environment variables:**
   Copy `.env.example` to `.env` and add your OpenAI API Key:
   ```bash
   cp .env.example .env
   ```
   Then edit `.env` and set `OPENAI_API_KEY=your_actual_key_here`.

## Running the Server

Start the Rails server:
```bash
bin/rails server
```
The server will start on `http://localhost:3000`.

## Testing the API

You can test the transcription endpoint using `curl`. Replace `audio_file.mp3` with a path to your actual audio file.

```bash
curl -X POST http://localhost:3000/api/transcribe \
  -F "audio=@/path/to/your/audio_file.mp3"
```

### Supported Formats
- mp3
- wav
- m4a
- ogg
- webm
- flac

### Example Response
On success (200 OK):
```json
{
  "transcript": "Hello, this is a test transcription.",
  "model": "gpt-4o-mini-transcribe",
  "duration": 4.2
}
```

On failure (422 Unprocessable Entity):
```json
{
  "error": "File size exceeds 25MB limit"
}
```

## Project Structure

- `app/controllers/api/transcriptions_controller.rb`: Handles HTTP requests and parameter extraction.
- `app/services/transcription_service.rb`: Contains the core logic for file validation and OpenAI API communication.
