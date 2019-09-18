FROM ruby:2.6.3-alpine

RUN apk update && apk add build-base nodejs postgresql-dev

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --binstubs

COPY . .

LABEL maintainer="Able Sense <support@ablesense.com>"

CMD puma -C config/puma.rb
