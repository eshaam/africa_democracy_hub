class AddStateToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :current_step, :string
    add_column :users, :step_data, :json, default: {}
  end
end
