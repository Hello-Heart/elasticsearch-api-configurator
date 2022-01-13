FROM ruby:3-alpine

MAINTAINER devops@helloheart.com

ENV CONFIGFILES_PATH=/configurations
USER nobody

COPY deploy.rb /
COPY configurations $CONFIGFILES_PATH

ENTRYPOINT ruby /deploy.rb