#!/bin/sh
set -e

GPG_DOCKER_KEYRING=/usr/share/keyrings/docker.gpg
APT_DOCKER="deb [arch=$(dpkg --print-architecture) signed-by=$GPG_DOCKER_KEYRING] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

GPG_GETENVOY_KEYRING=/usr/share/keyrings/getenvoy-keyring.gpg
APT_GETENVOY="deb [arch=$(dpkg --print-architecture) signed-by=$GPG_GETENVOY_KEYRING] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main"

CNI_PLUGINS_URL='https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz'

apt-get -q update
apt-get -q -y install wget

wget -q -O- $GPG_DOCKER | gpg --dearmor -o $GPG_DOCKER_KEYRING
echo $APT_DOCKER > /etc/apt/sources.list.d/docker.list

wget -q -O- $GPG_GETENVOY | gpg --dearmor -o $GPG_GETENVOY_KEYRING
echo $APT_GETENVOY > /etc/apt/sources.list.d/getenvoy.list

apt-get -q update
apt-get -q -y install docker-ce containerd.io getenvoy-envoy nfs-common

mkdir -p /opt/cni/bin
wget -q -O /tmp/cni-plugins.tgz $CNI_PLUGINS_URL
tar -vxf /tmp/cni-plugins.tgz -C /opt/cni/bin
chown root.root /opt/cni/bin
chmod 755 /opt/cni/bin/*
rm /tmp/cni-plugins.tgz

usermod -aG docker nomad

apt-get -q -y purge wget
apt-get -q -y clean
apt-get -q -y autoclean

mkdir /etc/systemd/resolved.conf.d/
mv /tmp/docker-dns.conf /etc/systemd/resolved.conf.d/docker.conf
chown root.root /etc/systemd/resolved.conf.d/docker.conf
chmod 644 /etc/systemd/resolved.conf.d/docker.conf
systemctl restart systemd-resolved

mv /tmp/daemon.json /etc/docker/daemon.json
chown root.root /etc/docker/daemon.json
chmod 644 /etc/docker/daemon.json
systemctl restart docker

mount --make-shared /