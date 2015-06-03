# glusterfs-playground

Quick playground for a 3 node Vagrant glusterfs cluster provisioned via Salt provisioner.

# Having vboxfs mount problems?

> Do following if you have vboxfs mount problems (and give it a few minutes)

```bash
for host in gluster1 gluster2 gluster3; do
  vagrant up $host;
  vagrant ssh $host -c 'sudo /etc/init.d/vboxadd setup';
  vagrant reload $host;
done
```
