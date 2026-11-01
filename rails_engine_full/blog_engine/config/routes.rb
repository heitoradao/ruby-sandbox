BlogEngine::Engine.routes.draw do
  resources :posts, only: %i[index show new create]
  root to: "posts#index"
end
