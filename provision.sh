#!/usr/bin/env bash

echo I am provisioning...
sudo apt-get update
echo installing git...
sudo apt-get install -y git-core
echo installing curl...
sudo apt-get install -y curl
echo installing ruby library dependencies...
sudo apt-get install -y libxslt-dev 
sudo apt-get install -y libxml2-dev
sudo apt-get install -y libpq-dev
echo installing ruby 1.9.3 using brightbox ppa
sudo apt-get install -y python-software-properties
sudo apt-add-repository -y ppa:brightbox/ruby-ng 
sudo apt-get update
sudo apt-get install -y ruby1.9.1
sudo apt-get install -y ruby1.9.1-dev
sudo apt-get install -y make g++ gcc libssl-dev
sudo gem install bundler
echo end of provisioning


