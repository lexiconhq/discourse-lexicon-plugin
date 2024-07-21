DiscourseLexiconPlugin::Engine.routes.draw do
  post 'push_notifications/subscribe' => 'expo_pn#subscribe'
  post 'push_notifications/delete_subscribe' => 'expo_pn#unsubscribe'

  post '/delete_user' => 'delete_user#delete'
end
