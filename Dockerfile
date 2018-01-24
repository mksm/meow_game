FROM ruby:2.2.4-slim

RUN apt-get update && apt-get install --no-install-recommends -y \
  g++  \
  gcc  \
  make

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 20 --retry 5

COPY . ./

EXPOSE 80

CMD ["thin", "-e", "production", "-p", "80", "start"]
