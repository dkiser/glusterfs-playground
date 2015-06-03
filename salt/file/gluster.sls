

create-partition-table:
  cmd.run:
    - name: parted -s /dev/sdb mklabel gpt
    - unless:
      - parted -s /dev/sdb print 1

{% set end_mb = salt['cmd.run']('parted -s /dev/sdb print 2> /dev/null | grep "Disk.*/" | grep -m 1 -o  -E "[0-9]+"') %}
create-brick-partition:
  cmd.run:
    - name: parted -s /dev/sdb mkpart primary xfs 0 {{end_mb}}
    - unless:
      - parted -s /dev/sdb1
    - require:
      - cmd: create-partition-table

format-brick-partition:
  cmd.run:
    - name: mkfs.xfs -i size=512 /dev/sdb1
    - unless:
      - blkid -p -n xfs  /dev/sdb1
    - require:
      - cmd: create-brick-partition


mount-brick-vol:
  mount.mounted:
    - name: /srv/sdb1
    - device: /dev/sdb1
    - fstype: xfs
    - mkmnt: True
    - persist: True
    - opts:
      - defaults
    - require:
      - cmd: format-brick-partition

mkdir-brick:
  file.directory:
    - name: /srv/sdb1/brick
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
    - require:
      - mount: mount-brick-vol

glusterfs-epel:
  pkgrepo.managed:
    - humanname: "GlusterFS is a clustered file-system capable of scaling to several petabytes."
    - baseurl: http://download.gluster.org/pub/gluster/glusterfs/LATEST/EPEL.repo/epel-$releasever/$basearch/
    - enabled: 1
    - gpgcheck: 1
    - gpgkey: http://download.gluster.org/pub/gluster/glusterfs/LATEST/EPEL.repo/pub.key

glusterfs-noarch-epel:
  pkgrepo.managed:
    - humanname: "GlusterFS is a clustered file-system capable of scaling to several petabytes."
    - baseurl: http://download.gluster.org/pub/gluster/glusterfs/LATEST/EPEL.repo/epel-$releasever/noarch
    - enabled: 1
    - gpgcheck: 1
    - gpgkey: http://download.gluster.org/pub/gluster/glusterfs/LATEST/EPEL.repo/pub.key

{% set gluster_packages = ['glusterfs-server', 'glusterfs-fuse', 'glusterfs-geo-replication'] %}
{% for pkg in gluster_packages %}
{{pkg}}:
  pkg.installed:
  - require:
    - pkgrepo: glusterfs-epel
    - pkgrepo: glusterfs-noarch-epel
{% endfor %}


gluster-service:
  service.running:
    - name: glusterd
    - enable: True


gluster-port-111:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - match: state
    - connstate: NEW
    - dport: 111
    - proto: tcp
    - save: True

gluster-port-24007-24008:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - match: state
    - connstate: NEW
    - dport: 24007:24008
    - proto: tcp
    - save: True

gluster-port-2409:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - match: state
    - connstate: NEW
    - dport: 24009:24010
    - proto: tcp
    - save: True


peer-clusters:
  glusterfs.peered:
    - names:
      - 192.168.69.20
      - 192.168.69.30
      - 192.168.69.40

Replicated Volume:
  glusterfs.created:
    - name: volume1
    - bricks:
      - 192.168.69.20:/srv/sdb1/brick
      - 192.168.69.30:/srv/sdb1/brick
      - 192.168.69.40:/srv/sdb1/brick
    - replica: 3
    - start: True

Start Volume:
  glusterfs.started:
    - name: volume1


/mnt/gluster:
  mount.mounted:
    - device: 192.168.69.20:/volume1
    - fstype: glusterfs
    - mkmnt: True
    - opts:
      #- defaults
      - selinux
      #- "context=system_u:system_r:svirt_lxc_net_t:s0"
      #- context="system_u:object_r:svirt_sandbox_file_t:s0"
