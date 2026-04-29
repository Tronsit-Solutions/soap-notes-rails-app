module Api
  class TranscriptionsController < ApplicationController
    def create
      if params[:audio].blank?
        return render json: { error: "No audio file provided" }, status: :bad_request
      end

      Rails.logger.info("Starting transcription for: #{params[:audio].original_filename}")

      transcribed_data = TranscriptionService.new(params[:audio]).call

      # Store the transcription in the database
      transcription = Transcription.create!(
        audio_file_name: params[:audio].original_filename,
        transcribed_text: transcribed_data[:transcript]
      )

      Rails.logger.info("Transcription completed for: #{params[:audio].original_filename}")
      
      # Return the transcribed data along with the transcription ID
      render json: transcribed_data.merge(transcription_id: transcription.id)
    rescue TranscriptionService::TranscriptionError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.fatal("Unexpected Error in TranscriptionsController: #{e.message}\n#{e.backtrace.join('\n')}")
      render json: { error: "An unexpected error occurred" }, status: :internal_server_error
    end

    private

    def api_request?
      # This check is useful if you later add cookie sessions or CSRF, but for API only it's often not needed.
      # However, for an "API-mode" app, verify_authenticity_token is usually not there.
      # But sometimes people add it back or this file might be used differently.
      true
    end
  end
end
