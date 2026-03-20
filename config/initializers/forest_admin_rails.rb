ForestAdminRails.configure do |config|
  config.auth_secret = ENV.fetch("FOREST_AUTH_SECRET")
  config.env_secret = ENV.fetch("FOREST_ENV_SECRET")
  config.application_url = ENV.fetch("APPLICATION_URL", "http://localhost:3000")
end
