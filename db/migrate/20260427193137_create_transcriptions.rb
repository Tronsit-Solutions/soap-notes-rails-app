class CreateTranscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :transcriptions do |t|
      t.string :audio_file_name
      t.text :transcribed_text

      t.timestamps
    end
  end
end
