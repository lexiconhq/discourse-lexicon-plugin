DiscourseLexiconPlugin::Engine.routes.draw do
  post 'push_notifications/subscribe' => 'expo_pn#subscribe'
  post 'push_notifications/delete_subscribe' => 'expo_pn#unsubscribe'

  get 'auth/user' => 'user#get_current_user'
end
