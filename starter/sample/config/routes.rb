Rails.application.routes.draw do
  mount Starter::Engine => '/', :as => 'starter'
end
