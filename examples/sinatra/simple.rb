class Simple < Sinatra::Base
  get '/public' do
    'This is a public resource.'
  end

  get '/protected' do
    env['bcsec'].authentication_required!
    username = env['bcsec'].user.username

    "This is a protected resource.  You are accessing it as #{username}."
  end
end
