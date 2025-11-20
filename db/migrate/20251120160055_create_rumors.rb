class CreateRumors < ActiveRecord::Migration[7.2]
  def change
    create_table :rumors, id: :uuid do |t|
      t.references :user, type: :uuid, foreign_key: true
      t.references :country, type: :uuid, foreign_key: true
      
      t.text :content, null: false
      t.string :status, default: 'pending' # pending, analyzed, flagged_human
      
      # AI Analysis Fields
      t.string :danger_level # Low, Medium, High
      t.string :sentiment    # Positive, Neutral, Negative
      t.text :ai_summary     # The 2-sentence fact check
      t.json :raw_ai_response # Full JSON data from Gemini

      t.timestamps
    end
  end
end
