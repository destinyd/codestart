Rails.application.routes.draw do
  mount Test::Engine => '/', :as => 'test'
  mount PlayAuth::Engine => '/auth', :as => :auth
end
