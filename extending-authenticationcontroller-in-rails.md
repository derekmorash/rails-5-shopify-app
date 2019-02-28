# Extending ShopifyApp::AuthenticatedController in Rails

Common methods used by multiple controllers
Define global before_actions

Example:
A before_action that redirects users from accessing any part of the app if they don't have an active app charge. Define and call a method in one place that happens for every part of the of the app instead of doing it multiple times in each controller.

```rb
# /app/controllers/shopify_application_controller.rb
class ShopifyApplicationController < ShopifyApp::AuthenticatedController
  protected

  def my_method(message)
    puts message
  end
end
```

```rb
# /app/controllers/my_controller.rb
class MyController < ShopifyApplicationController
  before_action only: [:index] do
    my_method("Hello, World.")
  end

  def index
  end
end
```
