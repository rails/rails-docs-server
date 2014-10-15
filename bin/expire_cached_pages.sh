#!/bin/bash

cd ~/rails-contributors/current
bundle exec rails runner ApplicationUtils.expire_cache
