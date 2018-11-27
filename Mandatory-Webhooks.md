# Handle Shopify Mandatory Webhooks in Ruby on Rails

Since May 25th, 2018 GDPR has imposed obligations on any party that collects, stores, or processes personal data. App developers have the responsibility to comply with these regulations. Fortunately, Shopify has implemented endpoints to help app developers deal with data privacy to meet the requirements of GDPR.

Read about [Shopify API GDPR requirements](https://help.shopify.com/en/api/guides/gdpr-resources).

## Mandatory Webhooks

Mandatory webhooks differ slightly from regular webhooks from Shopify. If you're using the *shopify_app* gem you can use the [webhooks manager](https://github.com/Shopify/shopify_app#webhooksmanager) to configure your apps needed webhooks. The difference being the way that mandatory webhooks get subscribed to, there is no configuration in your app code unlike regular webhooks.

Read about [getting started with Shopify webhooks](https://help.shopify.com/en/api/getting-started/webhooks).

## Mandatory webhooks app set up

We have to go into our apps set up in the partners dashboard and find the mandatory webhooks section. Here we specify the URLs for our app that Shopify can send the webhook to.

- `https://my-app.com/webhooks/customer_data_request`
- `https://my-app.com/webhooks/customer_redact`
- `https://my-app.com/webhooks/shop_redact`

![Shopify app set up; mandatory webhooks.](assets/mandatory-webhooks.png)

Shopify now knows where to send the webhook, it's up to our app to verify and handle the request.

## Handling the webhook request

The ShopifyApp gem works like magic, when it receives a mandatory webhook from a Shopify store it will automatically look for a job with the same name as the webhook topic and que it to be processed.

For example, if the topic is `shop/redact` then it will look for a job called `ShopRedactJob`.

Create a job for each webhook like this (`app/jobs/shop_redact_job.rb`):

```rb
class ShopRedactJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    shop.with_shopify_session do
      # redact information related to this shop
      ...
    end
  end
end
```

In this job, we can do all the processing we want like creating support tickets, deleting database information, sending emails, etc.

Once you have a job for each webhook 

## Custom webhook handling

If you'd like to create your own controller to handle then you can read [rails-handle-shopify-webhook.md](), it goes over how to set up routes and end points for any webhook and how to verify that a request actually came from shopify.
