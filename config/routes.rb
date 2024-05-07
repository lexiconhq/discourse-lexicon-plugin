DiscourseLexiconPlugin::Engine.routes.draw do
  post '/subscribe' => 'expo_pn#subscribe'
  post '/delete_subscribe' => 'expo_pn#unsubscribe'

  post '/delete_user' => 'delete_user#delete'
end
