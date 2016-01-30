require 'dashing'
require_relative 'lib/audit'

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end

end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

#Registrate service audit endpoint
use Sinatra do
  get('/audit') {
    Audit::trace
  }
end

run Sinatra::Application