# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.define "appserver", primary: true do |appserver|
    appserver.vm.network "forwarded_port", guest: 80, host: 8080

    # Basic Ubuntu packages
    appserver.vm.provision "shell", :privileged => false, :inline => <<-SHELL
      sudo apt-get update
      sudo apt-get install -y software-properties-common nginx-full graphicsmagick ghostscript git-core
    SHELL

    # nodejs installation
    appserver.vm.provision "shell", :inline => <<-SHELL
      git clone https://github.com/creationix/nvm ~/.nvm
      echo "source ~/.nvm/nvm.sh" | tee ~/.bashrc
      source ~/.nvm/nvm.sh
      nvm install v0.10
      nvm use 0.10
      nvm alias default 0.10

      npm install -g forever
    SHELL
      
    # Mongo server installation
    appserver.vm.provision "shell", :inline => <<-SHELL
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
      echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.0.list
      apt-get update
      apt-get install -y mongodb-org
    SHELL

    # Copy host machine SSH key to guest, so deployments work easily the first time
    if File.exist?("#{Dir.home}/.ssh/id_rsa.pub")
      ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
      appserver.vm.provision "shell", :inline => <<-SHELL
        echo #{ssh_pub_key} >> /root/.ssh/authorized_keys
      SHELL
    end
  end

  config.vm.define "buildmachine" do |buildmachine|
  end
end

