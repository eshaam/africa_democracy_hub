class CreateTownhallDocuments < ActiveRecord::Migration[7.2]
  def change
    create_table :townhall_documents, id: :uuid do |t|
      t.references :user, type: :uuid, foreign_key: true
      t.string :title
      t.string :file_type # e.g., 'application/pdf'
      t.text :extracted_text # Raw text from PDF
      t.text :ai_summary     # The simplified version
      t.string :status, default: 'pending' # pending, processing, completed, failed

      t.timestamps
    end
  end
end
