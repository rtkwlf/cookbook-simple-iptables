require "chefspec"

RSpec.configure do |config|
  config.cookbook_path = ["..",
                          "spec/support/cookbooks"]
end
