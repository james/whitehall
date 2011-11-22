module Whitehall
  autoload :Random, 'whitehall/random'
  autoload :RandomKey, 'whitehall/random_key'
  autoload :FormBuilder, 'whitehall/form_builder'
  autoload :QuietAssetLogger, 'whitehall/quiet_asset_logger'
  autoload :Presenters, 'whitehall/presenters'
  autoload :StaticAssetServing, 'whitehall/static_asset_serving'

  class << self
    def platform
      ENV["FACTER_govuk_platform"] || Rails.env
    end
  end
end