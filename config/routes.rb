Wiki::Engine.routes.draw do

  root 'application#root'
  match '_new/*path', to: 'pages#new', via: :get, as: 'new_page'
  match '_edit/*path', to: 'pages#edit', via: :get, as: 'edit_page'
  match '_update/*path', to: 'pages#update', via: [:put, :patch], as: 'update_page'
  match '_create/*path', to: 'pages#create', via: [:post], as: 'create_page'
  match '_delete/*path', to: 'pages#destroy', via: [:get, :delete], as: 'destroy_page'

  match '_list', to: 'pages#index', via: :get, as: 'pages'
  match '_log', to: 'pages#log', via: :get, as: 'log'

  match "*path", to: "application#display", via: :get, as: 'page'
  match "*path", to: "application#display", via: :get, as: 'attachment'

end
