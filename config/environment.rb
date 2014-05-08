require File.expand_path('../boot', __FILE__)

Dotenv.load('./local.env') unless (ENV['LOCAL_ENV_SETUP'] == 'true')

require File.expand_path('../application', __FILE__)
