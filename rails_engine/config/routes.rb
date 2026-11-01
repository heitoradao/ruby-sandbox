HelloEngine::Engine.routes.draw do
  get "greet/:name", to: "greetings#show"
end
