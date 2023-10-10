#!/bin/sh
set -e

export DEBIAN_FRONTEND=noninteractive

GPG_HASHICORP_KEYRING=/usr/share/keyrings/hashicorp-archive-keyring.gpg
APT_HASHICORP="deb [arch=$(dpkg --print-architecture) signed-by=$GPG_HASHICORP_KEYRING] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

cat /tmp/ssh_id_rsa.pub > /home/ubuntu/.ssh/authorized_keys

apt-get -q update
apt-get -q -y install wget openssh-server

wget -q -O- $GPG_HASHICORP | gpg --dearmor -o $GPG_HASHICORP_KEYRING
echo $APT_HASHICORP > /etc/apt/sources.list.d/hashicorp.list

apt-get -q update
apt-get -q -y install consul
