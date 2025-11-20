Geocoder.configure(
  # Geocoding options
  timeout: 5,                 # seconds
  lookup: :nominatim,         # name of geocoding service (symbol)
  ip_lookup: :ipinfo_io,      # name of IP address geocoding service (symbol)
  language: :en,              # ISO-639 language code
  units: :km,                 # :km for kilometers or :mi for miles

  # Caching (optional but recommended)
  # cache: Redis.new,
  # cache_prefix: 'geocoder:'
)