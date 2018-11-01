FROM ruby:2.3-alpine

RUN apk add --update \
  build-base \
  libxml2-dev \
  libxslt-dev \
  nodejs

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 4567
CMD ["bundle", "exec", "middleman"]