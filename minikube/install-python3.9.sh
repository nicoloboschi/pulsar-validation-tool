#!/bin/bash

set -e
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt list | grep python3.9

sudo apt-get install python3.9 -y
sudo update-alternatives --config python3
python3 -V
