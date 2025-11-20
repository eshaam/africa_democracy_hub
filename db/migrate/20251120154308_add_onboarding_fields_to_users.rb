class AddOnboardingFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :full_name, :string
    add_column :users, :phone_number, :string
    
    # Location Data
    add_column :users, :latitude, :float
    add_column :users, :longitude, :float
    add_column :users, :address, :text # Full formatted address from Geocoder
    
    # Terms
    add_column :users, :terms_accepted_at, :datetime
    
    # Track onboarding state in DB (optional, but safer than cache for long processes)
    add_column :users, :onboarding_status, :string, default: 'new' # new, name_set, phone_set, loc_set, completed
  end
end
