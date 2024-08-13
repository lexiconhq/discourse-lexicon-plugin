DiscourseLexiconPlugin::Engine.routes.draw do
  post 'push_notifications/subscribe' => 'expo_pn#subscribe'
  post 'push_notifications/delete_subscribe' => 'expo_pn#unsubscribe'
  post 'auth/apple/login' => 'apple_auth#login'
  post 'auth/activate_account' => 'activate_account#perform_account_activation'

  get 'auth/status' => 'auth#authentication_status'
  get 'auth/user' => 'user#get_current_user'
end
