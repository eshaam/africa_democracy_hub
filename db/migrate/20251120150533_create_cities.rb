class CreateCities < ActiveRecord::Migration[7.2]
  def change
    create_table :cities, id: :uuid do |t|
      t.references :country, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
  end
end
