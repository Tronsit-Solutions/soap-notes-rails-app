class SoapNoteService
  class SoapNoteError < StandardError; end

  def initialize(transcription)
    @transcription = transcription
    @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  end

  def call
    generate_soap_note
  rescue OpenAI::Error => e
    Rails.logger.error("OpenAI Error: #{e.message}")
    raise SoapNoteError, "OpenAI API error: #{e.message}"
  rescue StandardError => e
    Rails.logger.error("SOAP Note Generation Error: #{e.message}")
    raise SoapNoteError, e.message
  end

  private

  attr_reader :transcription, :client

  def generate_soap_note
    prompt = <<~PROMPT
      Based on the following medical transcription, generate a SOAP note in JSON format.

      Transcription: #{transcription}

      SOAP Note Structure:
      - Subjective: Patient's reported symptoms and history
      - Objective: Observable facts and clinical findings
      - Assessment: Diagnosis or impression
      - Plan: Treatment plan and next steps

      Return the response as a JSON object with keys: "subjective", "objective", "assessment", "plan"
    PROMPT

    response = client.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    if response["error"]
      raise SoapNoteError, response["error"]["message"]
    end

    content = response.dig("choices", 0, "message", "content")
    begin
      JSON.parse(content)
    rescue JSON::ParserError
      raise SoapNoteError, "Failed to parse SOAP note response"
    end
  end
end