ImpactDialing::Application.configure do
  #michael
  TWILIO_APP_SID   = "AP7d39738c833e144064374b12681bf0ba"
  TWILIO_ACCOUNT   = "AC422d17e57a30598f8120ee67feae29cd"
  TWILIO_AUTH      = "897298ab9f34357f651895a7011e1631"
  APP_NUMBER       = "7029797309"
  HOLD_MUSIC_URL   = "https://s3.amazonaws.com/hold_music/impactdialing_holdmusic_v1.mp3"
  MANDRILL_API_KEY = 'qlYdRXlyROwaN9Tqk1QrhA'

  #monitor
   MONITOR_TWILIO_APP_SID="APa5ea5d37745f53d3289b4326051743b0"

  #Brian?
  #TWILIO_ACCOUNT="ACc0208d4be3e204d5812af2813683243a"
  #TWILIO_AUTH="4e179c64daa7c9f5108bd6623c98aea6"
  #APP_NUMBER="5104048117"

  PUSHER_APP_ID          = "6868"
  PUSHER_KEY             = "1e93714ff1e5907aa618"
  PUSHER_SECRET          = "26b438b5e27a3e84d59c"
  TWILIO_ERROR           = "http://status-impactdialing.heroku.com/twilio/error_development"
  STRIPE_PUBLISHABLE_KEY = "pk_test_C7afhsETXQncQqcBQ2Hr2f0M"
  STRIPE_SECRET_KEY      = "sk_test_EHZciy2zvJc6UelOAMdFX6wX"

  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching             = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = false
  config.action_mailer.delivery_method = :test

  config.active_support.deprecation = :log

  # http://rdoc.info/github/jnunemaker/httparty/HTTParty/ClassMethods#ssl_ca_file-instance_method
  Twilio.default_options[:ssl_ca_file] = ENV['SSL_CERT_FILE']
end
