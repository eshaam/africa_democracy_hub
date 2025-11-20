class CreateCountries < ActiveRecord::Migration[7.2]
  def change
    create_table :countries, id: :uuid do |t|
      t.string :name, null: false
      t.string :iso_code, limit: 2 # e.g., "KE", "NG", "ZA"
      t.string :phone_code # e.g., "+254", "+234"
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
