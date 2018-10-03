class ShopRedactJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    # webhook paylod: {"shop_id": "123456789","shop_domain": "shop-name.myshopify.com"}
    shop = Shop.find_by(shopify_domain: shop_domain)

    puts '==================================='
    puts 'ShopRedactJob received from webhook'
    puts '==================================='
    puts webhook.to_json

    shop.with_shopify_session do
    end
  end
end
