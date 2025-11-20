class EnableUuid < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'pgcrypto' unless connection.adapter_name == 'SQLite'
  end
end
