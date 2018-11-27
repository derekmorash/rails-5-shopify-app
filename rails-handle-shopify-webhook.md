# Handle Shopify Webhooks in Ruby on Rails

Webhooks are a way for Shopify to send data to your app when events in a merchants store happen, such as order or product updates. The ShopifyApp gem makes it easy to subscribe to and manage the webhooks that are required for your app. We'll look at two ways of handling webhooks using the ShopifyApp gem in Ruby on Rails.

### Note about Mandatory Webhooks

If you're using the *shopify_app* gem you can use the [webhooks manager](https://github.com/Shopify/shopify_app#webhooksmanager) to configure the webhooks our app needs. However, Mandatory webhooks differ slightly in the way they're configured. I have another article about how to set these up [Mandatory-Webhooks.md]().

## Configure Webhook

Start by subscribing to the webhooks we want our app to listen for.

```rb
ShopifyApp.configure do |config|
  config.webhooks = [
    {topic: 'orders/create', address: 'https://my-app.com/webhooks/orders_create'}
    {topic: 'orders/update', address: 'https://my-app.com/webhooks/orders_update'}
    {topic: 'orders/paid', address: 'https://my-app.com/webhooks/orders_paid'}
  ]
end
```

This will subscribe your app to a shops webhooks when the app is installed by a merchant. The topic tells Shopify which webhook to subscribe to and the address is the URL for your app that you want the webhook to be sent to.

## Jobs

Create a job for each webhook like this (`app/jobs/orders_create_job.rb`):

```rb
class OrdersCreateJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    shop.with_shopify_session do
      # redact information related to this shop
    end
  end
end
```

In this job, we can do all the processing we want like updating a database, sending emails with the webhook data, or creating support tickets.

If our app is using a job queuing service like Sidekiq then these jobs will be processed in the background, if not the job will just be run inline.

That's it, as long as you create a job that matches its webhook topic then the ShopifyApp gem will handle it.

## Custom webhooks controller

The ShopifyApp gem is now receiving the webhook and sending it to ActiveJob to be processed. That's it, we're done! You may however want to have your own controller to handle webhooks. If your app needs to do something different than just queuing a job then the default webhook manager may be limiting for you. The ShopifyApp gem can still help us with this.

## Routes

Now that the webhooks are configured we need to set up routes that Shopify can post to when a webhook is fired. We can make the endpoint locations be whatever we want, then map them to the appropriate controller methods (we will make this controller after).

```rb
post '/webhooks/orders_create', :to => 'custom_webhooks#orders_create'
post '/webhooks/orders_update', :to => 'custom_webhooks#orders_update'
post '/webhooks/orders_paid', :to => 'custom_webhooks#orders_paid'
```

## Custom webhooks controller set up

Create a new controller called `CustomWebhooksController`. Add methods for each webhook we want to use to the controller.

```
rails generate controller CustomWebhooks
```

Or manually create `app/controllers/custom_webhooks_controller.rb`.

Add stub endpoint methods:

```rb
class CustomWebhooksController < ApplicationController
  
  def orders_create
  end

  def orders_update
  end

  def orders_paid
  end

  ...

end
```

Create a private method that only excepts only the params we want and returns them. The `except` method returns a hash with everything except for the given values.

```rb
private
def webhook_params
  params.except(:controller, :action, :type)
end
```

Now we can use `webhook_params` in our controller methods to access the data sent by the webhook request.

### Webhook verification

Webhooks need to be verified before being processed to be sure that the request came from shopify and not someone else.

In the header of the request, Shopify includes an HMAC. This is the SHA256 digest calculated from the body of the request and your apps shared secret. To verify the webhook you have to calculate this HMAC and compare it to the one in the request header, if they match then it is a valid webhook from Shopify.

Shopify's [getting started with webhooks guide](https://help.shopify.com/en/api/getting-started/webhooks#verify-webhook) has a good section on how to manually verify webhooks.

Luckily the [shopify_app gem](https://github.com/Shopify/shopify_app) can handle this for us, no need to worry about calculating and compare the HMAC. To do this include ShopifyApp::WebhookVerification at the start of the controller class.

```rb
class CustomWebhooksController < ApplicationController
  include ShopifyApp::WebhookVerification
  ...
end
```

### Complete the endpoint methods

Start by setting the params permitted attribute to true, then we can use `webhook_params` to do whatever we want with the webhook data.

Then we need to return a response to Shopify to say everything is okay. Webhooks need to respond with a 200 series status code. Calling `head :no_content` will respond with a `"204 no content"` status. We aren't sending any data back to Shopify with these webhooks so 204 just indicates that the webhook was received and there's nothing to send back.

```rb
def orders_create
  params.permit!
  OrdersCreateJob.perform_later(shop_domain: shop_domain, webhook: webhook_params.to_h)
  head :no_content
end
```

Before `head` is called we can do whatever we want with the webhook data. Here we are queuing the job we created earlier.

Now ActiveJob will handle the heavy lifting of the webhook in the background and we don't have to worry about having the main app do extra processing.