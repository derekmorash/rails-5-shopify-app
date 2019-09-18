# Update Shopify App Gem to version 11

## Updating the app

### Update Ruby

1. Change ruby version in `Gemfile`:
    ```
    ruby '2.6.3'
    ```
2. Update `Dockerfile` to use the official ruby 2.6.3 alpine image:
    ```
    FROM ruby:2.6.3-alpine
    ```
3.  Now build and run the containers.
    ```
    docker-compose build
    ```
    ```
    docker-compose up
    ```

### Update Shopify Gems

1. Update `shopify_app` gem in `Gemfile`:
    ```Ruby
    gem 'shopify_app', '>= 11.1.0'
    ```
    Then run `bundle install`
2. Add an environment variable for the Shopify API version we want to use to `.env`:
    ```
    SHOPIFY_API_VERSION=2019-04
    ```
3. Make the following two changes to `shopify_app.rb` to configure the Shopify API version:
    
    Add the api_version config property.
    ```ruby
    config.api_version = ENV['SHOPIFY_API_VERSION'].to_s
    ```

    Then as a temporary fix for a bug in the `shopify_app` gem version 11.0.1 add the following to the top of the file. Ignore this for v11.1.0+
    ```ruby
    ShopifyAPI::Base.api_version = ENV['SHOPIFY_API_VERSION'].to_s
    ```
4. Add a `api_version` method to the model that we're using as our session repository, in our case it's the Shop model, `app/models/shop.rb`:

    ```ruby
    def api_version
      ShopifyApp.configuration.api_version
    end
    ```
    This method returns the API version we configured in shopify_app.rb
5. Version 11 of the shopify_app gem requires the change of `@shop_session.url` to `@shop_session.domain`, in our case this happens in `embedded_app.html.erb`.

### Update Rails

1. Update rails version in `Gemfile`:
    ```
    gem 'rails', '~> 6.0.0.rc1'
    ```
2. Other gems will need to be updated to work with rails 6:
    - `gem 'pg', '>= 0.18.4', '< 2.0'`
    - `gem 'bootsnap', '>= 1.4.2', require: false`
    - Replace:
      ```ruby
      # Easy installation and use of chromedriver to run system tests with Chrome
      gem 'chromedriver-helper'
      ```
      with:
      ```ruby
      # Easy installation and use of web drivers to run system tests with browsers
      gem 'webdrivers'
      ```
3. Rails 6 requires you to specify the host. In config/environments/development.rb add:
    ```ruby
    config.hosts << ENV['APP_BASE_HOST'].to_s || 'localhost'
    ```
    Then add APP_BASE_HOST to .env
    ```
    APP_BASE_HOST=my_app.ngrok.io
    ```





## Update Postgres

1. Export the current database. Make sure the containers are running.
    ```
    docker-compose exec ORIGINAL_POSTGRES_CONTAINER pg_dump -U ORIGINAL_POSTGRES_USER ORIGINAL_POSTGRES_DATABASE > dump.sql
    ```
    Where ORIGINAL_POSTGRES_CONTAINER is probably postgres and ORIGINAL_POSTGRES_USER is the database user for that container.

    dump.sql will be saved on your local disk in your current directory

    If there is an error about failing to start the container try using a regular docker exec command instead of docker-compose:
    ```
    docker exec -t POSTGRESS_CONTAINER_NAME pg_dump -c -U ORIGINAL_POSTGRES_USER ORIGINAL_POSTGRES_DATABASE > dump.sql
    ```
2. Now that the databases are backed up we can remove the outdated postgres container and volume so we can start fresh.
    There are probably safer ways to backup the container
3. Update the image for the postgres container.
    ```yml
    postgres:
        image: 'postgres:11.5-alpine'
        environment:
          POSTGRES_DB: 'shopify_base_app_development'
          POSTGRES_USER: 'shopify_base_app_development'
          POSTGRES_PASSWORD: 'yourpassword'
        volumes:
          - 'postgres:/var/lib/postgresql/data'
        env_file:
          - '.env'
    ```
    Now build and run the containers.
    ```
    docker-compose build
    ```
    ```
    docker-compose up
    ```
4. Copy the dump file to the new postgres container
    ```
    docker cp dump.sql NEW_POSTGRES_CONTAINER:/var/lib/postgresql/data/dump.sql
    ```
    Where NEW_POSTGRES_CONTAINER is the name of the container. Use `docker ps` to find the container name, in this case it's `shopify_base_app_postgres_1`. The container name will be whatever the service is called in our `docker-comose.yml` file, prefixed with the `COMPOSE_PROJECT_NAME` environment variable.
5. Import the dump file from the old database into the new one.
    Enter the new postgres container with bash.
    ```
    docker exec -it NEW_POSTGRES_CONTAINER bash
    ```
    Where NEW_POSTGRES_CONTAINER is the name of the container we found above.
    
    Then change into the data directory.
    ```
    cd /var/lib/postgresql/data/
    ```
    Confirm that the dump.sql file is there. `ls`

    Now import dump file
    ```
    psql -U NEW_POSTGRES_USER < dump.sql
    ```
    Where NEW_POSTGRES_USER is the database user for the new container, in this case `shopify_base_app_development`.

### Resources
https://peter.grman.at/upgrade-postgres-9-container-to-10/

https://simkimsia.com/how-to-restore-database-dumps-for-postgres-in-docker-container/
