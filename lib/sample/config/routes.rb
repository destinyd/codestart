Rails.application.routes.draw do
  mount Test::Engine => '/', :as => 'test'
end
