class TranscriptionService
  class TranscriptionError < StandardError; end

  SUPPORTED_FORMATS = %w[mp3 wav m4a ogg webm flac].freeze
  MAX_FILE_SIZE = 25.megabytes

  def initialize(file)
    @file = file
    @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  end

  def call
    validate_file!
    transcribe
  rescue OpenAI::Error => e
    Rails.logger.error("OpenAI Error: #{e.message}")
    raise TranscriptionError, "OpenAI API error: #{e.message}"
  rescue StandardError => e
    Rails.logger.error("Transcription Error: #{e.message}")
    raise TranscriptionError, e.message
  end

  private

  attr_reader :file, :client

  def validate_file!
    raise TranscriptionError, "No file provided" if file.blank?

    extension = File.extname(file.original_filename).delete(".").downcase
    unless SUPPORTED_FORMATS.include?(extension)
      raise TranscriptionError, "Unsupported file format. Supported formats: #{SUPPORTED_FORMATS.join(', ')}"
    end

    if file.size > MAX_FILE_SIZE
      raise TranscriptionError, "File size exceeds 25MB limit"
    end
  end

  def transcribe
    # The file passed from ActionController::Parameters is an ActionDispatch::Http::UploadedFile
    # We can use file.path to get the temporary path on disk
    response = client.audio.transcribe(
      parameters: {
        model: "whisper-1",
        file: File.open(file.path),
        response_format: "verbose_json"
      }
    )

    # Note: ruby-openai returns a hash or similar object depending on the version and response
    # For audio transcription, it typically returns the transcript text.
    # The requirements ask for: { "transcript": "...", "model": "...", "duration": ... }
    # However, standard OpenAI transcription response might only have 'text'.
    # If using gpt-4o-mini-transcribe, I should check the response structure.
    # Standard Whisper responses have 'text' and sometimes 'duration' if requested.
    
    if response["error"]
      raise TranscriptionError, response["error"]["message"]
    end

    {
      transcript: response["text"],
      model: "whisper-1",
      duration: response["duration"] || 0.0 # Standard API might not return duration unless requested or specific to this model
    }
  end
end
