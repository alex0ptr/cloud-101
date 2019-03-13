#!/bin/bash
set -euo pipefail

echo "This is provision.sh 👋"
sudo amazon-linux-extras install docker
sudo usermod -a -G docker ec2-user
