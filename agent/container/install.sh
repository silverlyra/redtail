#!/bin/sh

set -e

apt-get update
apt-get install -y redis

rm -fr /var/lib/apt/lists/*
