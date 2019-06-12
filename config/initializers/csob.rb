

CsobPaymentGateway.configure do |config|
  config.close_payment      = true
  config.currency           = 'CZK'
  config.environment        = Rails.env.production? ? :production : :development
  config.gateway_url        = "https://iapi.iplatebnibrana.csob.cz/api/v1.7"
  config.keys_directory     = "csob_keys"
  config.merchant_id        = "A3922iW4Up"
  config.private_key        = "rsa_A3922iW4Up.key"
  config.public_key         = "rsa_A3922iW4Up.pub"
  config.return_method_post = true
  config.return_url         = "https://devel.tyb.cz/command/csob_back"
end