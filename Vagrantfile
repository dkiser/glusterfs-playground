# -*- mode: ruby -*-

# vi: set ft=ruby :

boxes = [
    {
        :name => "gluster1",
        :mem => "1024",
        :cpu => "1",
        :ip => "192.168.69.20"
    },
    {
        :name => "gluster2",
        :mem => "1024",
        :cpu => "1",
        :ip => "192.168.69.30"
    },
    {
        :name => "gluster3",
        :mem => "1024",
        :cpu => "1",
        :ip => "192.168.69.40"
    }
]

Vagrant.configure(2) do |config|


  config.vm.box = "centos7-minimal-x86_64.box"
  config.vm.box_url = "https://f0fff3908f081cb6461b407be80daf97f07ac418.googledrive.com/host/0BwtuV7VyVTSkUG1PM3pCeDJ4dVE/centos7.box"

  # For masterless, mount your salt file root
  config.vm.synced_folder "salt/file", "/srv/salt"
  config.vm.synced_folder "salt/pillar", "/srv/pillar"

  boxes.each do |opts|
    config.vm.define opts[:name] do |config|
      config.vm.hostname = opts[:name]
      config.vm.network "private_network", ip: opts[:ip]

      config.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", opts[:mem]]
        v.customize ["modifyvm", :id, "--cpus", opts[:cpu]]

        # setup disks for gluster bricks
        file_to_disk = './.vagrant/' + opts[:name] + '.brick.vdi'
        unless File.exist?(file_to_disk)
          v.customize ['createhd', '--filename', file_to_disk, '--size', 100]
        end
        v.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
      end

      ## Use all the defaults:
      config.vm.provision :salt do |salt|
        salt.minion_config = "salt/minion"
        salt.run_highstate = true
      end



    end
  end
end
