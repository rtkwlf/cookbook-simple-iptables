require 'serverspec'

set :backend, :exec

# Require support files
Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |file| require_relative(file) }
