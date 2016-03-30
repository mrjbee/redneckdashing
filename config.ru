require 'dashing'
#FIXME no time to find out cause of LoadError: cannot infer basepath
require '/opt/redneckdashing/lib/audit'

configure do
  set :auth_token, 'MY_AUTH_TOKEN'

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
    Audit::trace_components.join '</br>'
  }
end

run Sinatra::Application
