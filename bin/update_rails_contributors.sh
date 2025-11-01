#!/bin/bash

# RVM bootstrap expects some variables to be unset
set +u
set -ex

nice --adjustment=19 rvm in $HOME/rails-contributors/current do bin/rails runner -e production Repo.sync
