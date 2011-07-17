class Simple < Sinatra::Base
  get '/public' do
    'This is a public resource.'
  end

  get '/protected' do
    env['aker.check'].authentication_required!
    username = env['aker.check'].user.username

    "This is a protected resource.  You are accessing it as #{username}."
  end
end
