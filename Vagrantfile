# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "hashicorp/precise64"
  config.vm.hostname = "VertDevelopment"

  config.vm.provision :shell, :path => "provision.sh"
  config.vm.synced_folder ".", "/home/vert"
end
