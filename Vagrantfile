# -*- mode: ruby -*-
# vi: set ft=ruby :

# Check to see if there's an SSH agent running with keys.
`ssh-add -l`

unless $?.success?
  puts 'Your SSH does not currently contain any keys (or is stopped.)'
  puts 'Please start it and add your SSH key (OSX: ssh-add) to continue.'
  exit 1
end

systemMemory = `sysctl -n hw.memsize`.to_i / 1024 / 1024
humanReadableSystemMemory = systemMemory / 1024
puts 'system memory is ' + humanReadableSystemMemory.to_s + 'GB'

if systemMemory < 2048
  puts 'This Vagrant environment requires a minimum memory of 2GB'
  exit 1
end

unless Vagrant.has_plugin?('vagrant-host-shell')
  puts "This Vagrant environment requires the 'vagrant-host-shell' plugin."
  puts 'Please run `vagrant plugin install vagrant-host-shell` and then run this command again.'
  exit 1
end

unless Vagrant.has_plugin?('landrush')
  puts "This Vagrant environment requires the 'landrush' plugin."
  puts 'Please run `vagrant plugin install landrush` and then run this command again.'
  exit 1
end

# uncomment if using parallels as the provisioner
#unless Vagrant.has_plugin?("vagrant-parallels")
#  puts "This Vagrant environment requires the 'vagrant-parallels' plugin."
#  puts "Please run `vagrant plugin install vagrant-parallels` and then run this command again."
#  exit 1
#end

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.provider 'virtualbox'
  config.vm.box = 'ubuntu/trusty64'
  # @todo verify this is the latest box to download or don't use box_url setting
  #config.vm.box_url = "https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/20150609.0.10/providers/virtualbox.box"
  # uncomment below for parallels;
  #config.vm.box_url = "https://atlas.hashicorp.com/parallels/boxes/ubuntu-14.04/versions/1.0.5/providers/parallels.box"
  config.vm.provision :shell, path: 'provision/bootstrap.sh'

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # change the host ports if you're running more than 1 project at a time
  config.vm.network 'forwarded_port', guest: 80, host: 8080, auto_correct: true
  config.vm.network 'forwarded_port', guest: 443, host: 8443, auto_correct: true
  config.vm.network 'forwarded_port', guest: 3306, host: 33066, auto_correct: true


  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  #config.vm.network "private_network", ip: "192.168.33.10"
  # disable network because of landrush vagrant plugin
  config.landrush.enabled = true # Enable the Landrush plugin.
  # Set a custom TLD to use for this VM.
  # landrush tld becomes {projectRootName}.dev
  config.landrush.tld = 'dev' # Set a custom TLD to use for this VM.

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  #, nfs: true for optional speed up?
  # change this to /var/www/{projectFolderName}.dev
  config.vm.synced_folder '.', '/var/www/chancegarcia.dev', owner: 'www-data', group: 'www-data'

  # for github interaction using existing keys
  config.ssh.forward_agent = true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
   config.vm.provider 'virtualbox' do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "2048"
  #   vb.cpus = 2
     host = RbConfig::CONFIG['host_os']

      # Give VM 1/4 system memory or 2GB (whichever is greater) & access to all cpu cores on the host
      if host =~ /darwin/
        cpus = `sysctl -n hw.ncpu`.to_i
        # sysctl returns Bytes and we need to convert to MB
        mem = `sysctl -n hw.memsize`.to_i / 1024 / 1024 / 4
      elsif host =~ /linux/
        cpus = `nproc`.to_i
        # meminfo shows KB and we need to convert to MB
        mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024 / 4
      else # sorry Windows folks, I can't help you
        cpus = 2
        mem = 2048
      end

      if mem < 2048
        mem = 2048
      end

      #vb.customize ["modifyvm", :id, "--memory", mem]
      #vb.customize ["modifyvm", :id, "--cpus", cpus]
      # use shortcut to set memory and cpu
      vb.memory = mem
      vb.cpus = cpus
   end
  
  # use this if parallels is the provider
  #config.vm.provider "parallels" do |vb|
  #  host = RbConfig::CONFIG['host_os']

      # Give VM 1/4 system memory & access to all cpu cores on the host
#      if host =~ /darwin/
#        cpus = `sysctl -n hw.ncpu`.to_i
        # sysctl returns Bytes and we need to convert to MB
#        mem = `sysctl -n hw.memsize`.to_i / 1024 / 1024 / 4
#      elsif host =~ /linux/
#        cpus = `nproc`.to_i
        # meminfo shows KB and we need to convert to MB
#        mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024 / 4
#      else # sorry Windows folks, I can't help you
#        cpus = 2
#        mem = 2048
#      end

#      if mem < 2048
#        mem = 2048
#      end

#      vb.memory = mem
#      vb.cpus = cpus
#  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL
end
