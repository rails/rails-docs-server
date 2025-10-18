#!/bin/bash

set -ex

nice --adjustment=19 rvm in $HOME/rails-contributors/current bin/rails runner -e production Repo.sync
