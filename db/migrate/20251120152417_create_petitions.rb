class CreatePetitions < ActiveRecord::Migration[7.2]
  def change
    create_table :petitions, id: :uuid do |t|
      # Optional: Link to a User if they are registered, otherwise just store chat_id
      t.references :user, type: :uuid, foreign_key: true, null: true
      t.string :telegram_chat_id
      
      t.string :topic
      t.text :raw_input
      t.text :final_content
      t.string :status, default: 'pending' # pending, processing, completed, failed

      t.timestamps
    end
    
    add_index :petitions, :telegram_chat_id
  end
end
