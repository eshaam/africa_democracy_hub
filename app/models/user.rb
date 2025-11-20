class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :country, optional: true
  belongs_to :city, optional: true
  has_many :petitions

  # Safe Geocoding: Only run if lat/long changed and present
  reverse_geocoded_by :latitude, :longitude
  
  after_validation :safe_reverse_geocode, if: ->(obj){ obj.latitude.present? && obj.latitude_changed? }

  def safe_reverse_geocode
    # Wrap in rescue to prevent API errors from blocking the user flow
    begin
      reverse_geocode
      if address.present?
        results = Geocoder.search([latitude, longitude])
        assign_location_associations(results.first) if results.present?
      end
    rescue => e
      Rails.logger.error "Geocoder Error: #{e.message}"
      # Continue without location details if API fails
    end
  end

  def assign_location_associations(geo)
    return unless geo && geo.country.present?

    # Find or Create Country
    country_rec = Country.find_or_create_by(name: geo.country) do |c|
      c.iso_code = geo.country_code.upcase if geo.country_code
    end
    self.country = country_rec

    # Find or Create City
    if geo.city.present?
      city_rec = City.find_or_create_by(name: geo.city, country: country_rec)
      self.city = city_rec
    end
  end

  def onboarded?
    terms_accepted_at.present?
  end
end