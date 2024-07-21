# Rubyの公式イメージをインストール
FROM ruby:3.3.0

WORKDIR /ocr_check_app

RUN apt-get update
RUN apt install -y vim less

COPY Gemfile Gemfile.lock /
RUN bundle install

COPY . .