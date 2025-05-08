#!/usr/bin/env bash
set -e
# Update package list and install python3-pip
sudo apt-get update
sudo apt-get install -y python3-pip
# Upgrade pip and install common python packages
python3 -m pip install --upgrade pip
pip3 install numpy scipy matplotlib
