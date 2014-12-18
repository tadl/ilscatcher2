Rails.application.routes.draw do

  match "account/login" => "account#login", via: [:get, :post]
  match "account/login_refresh" => "account#login_refresh", via: [:get, :post]
  match "account/logout" => "account#logout", via: [:get, :post]
  match "account/place_holds" => "account#place_holds", via: [:get, :post]
  match "account/checkouts" => "account#checkouts", via: [:get, :post]
  match "account/renew_items" => "account#renew_items", via: [:get, :post]
  match "account/check_token" => "account#check_token", via: [:get, :post]
  match "account/password_reset" => "account#password_reset", via: [:get, :post]
  match "account/holds" => "account#holds", via: [:get, :post]
  match "items/details" => "items#details", via: [:get, :post]
  match "search/basic" => "search#basic", via: [:get, :post]
  match "web/locations" => "web#locations", via: [:get, :post]
  match "web/events" => "web#events", via: [:get, :post]
  match "web/news" => "web#news", via: [:get, :post]

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
