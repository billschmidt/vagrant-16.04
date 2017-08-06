# -*- mode: ruby -*-
# vi: set ft=ruby :

def install_dep(name, version, install_dir = nil)
    install_dir ||= '/etc/puppet/modules'
    "mkdir -p #{install_dir} && (puppet module list | grep #{name}) || puppet module install -v #{version} #{name}"
end

require 'yaml'
dir = File.dirname(File.expand_path(__FILE__))

# defaults
settings = YAML::load_file("#{dir}/vagrant.yml")

Vagrant.configure("2") do |config|

    config.vm.box = "ubuntu/xenial64"
    config.vm.network "private_network", ip: "192.168.50.100"
    config.vm.synced_folder ".", settings['synced_folder']

    config.vm.provider "virtualbox" do |v|
        v.memory = 4096
        v.cpus = 4
        v.name = settings['fqdn']
    end

    # ssh settings
    # use the insecure key because whatever
    config.ssh.insert_key = false

    config.vm.provision "shell", inline: <<-SHELL
        export DEBIAN_FRONTEND=noninteractive
        apt update
        apt upgrade -y
        apt install -y vim ntp ntpdate postfix openssl imagemagick git subversion node-less unzip libssh2-1-dev xvfb puppet ant openjdk-8-jdk openjdk-8-jre nodejs npm
    SHELL

    #config.vm.share_folder "puppet_mount", "/puppet", "puppet"

    config.vm.provision :shell, :inline => install_dep('puppet-php', '4.0.0')
    config.vm.provision :shell, :inline => install_dep('puppet-nginx', '0.6.0')
    config.vm.provision :shell, :inline => install_dep('puppetlabs-postgresql', '4.9.0')

    # master of puppets
    config.vm.provision :puppet do |puppet|
      puppet.manifests_path = 'bootstrap/puppet/manifests'
      puppet.module_path = 'bootstrap/puppet/modules'
      puppet.manifest_file = 'default.pp'
      puppet.facter = settings
    end

    config.vm.provision :shell, run: "always", inline: <<-SHELL
        service php7.1-fpm restart && service nginx restart
    SHELL

end
