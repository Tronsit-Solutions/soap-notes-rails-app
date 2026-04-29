module Api
  class SoapNotesController < ApplicationController
    def create
      transcription = if transcription_params[:transcription_id].present?
        transcription = Transcription.find_by(id: transcription_params[:transcription_id])
        return render json: { error: "Transcription not found" }, status: :not_found unless transcription
        transcription
      else
        transcript = transcription_params[:transcript]
        return render json: { error: "Transcription text is required" }, status: :bad_request if transcript.blank?

        Transcription.create!(audio_file_name: nil, transcribed_text: transcript)
      end

      soap_note_data = nil

      ApplicationRecord.transaction do
        soap_note_data = SoapNoteService.new(transcription.transcribed_text).call

        transcription.create_soap_note!(
          subjective: soap_note_data["subjective"],
          objective: soap_note_data["objective"],
          assessment: soap_note_data["assessment"],
          plan: soap_note_data["plan"]
        )
      end

      render json: soap_note_data.merge(transcription_id: transcription.id)
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue SoapNoteService::SoapNoteError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.fatal("Unexpected Error in SoapNotesController: #{e.message}\n#{e.backtrace.join('\n')}")
      render json: { error: "An unexpected error occurred" }, status: :internal_server_error
    end

    private

    def transcription_params
      params.permit(:transcription_id, :transcript)
    end
  end
end