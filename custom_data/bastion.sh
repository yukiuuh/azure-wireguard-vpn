#!/bin/sh

apt update
apt -y upgrade

ufw allow ssh
ufw --force enable
