#!/bin/bash
apt update -y
apt install -y nginx
systemctl start nginx
systemctl enable nginx
