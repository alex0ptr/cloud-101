#!/bin/bash
set -euxo pipefail

cowsay -f dragon "What does a dragon say when he sees two knights? - Ugggh... Canned food again"

# templated by terraform
dockerImage="${docker_image}"
tableName="${table_name}"

echo "whoami: $(whoami)"
echo "pwd: $(pwd)"
echo "using dockerImage: $dockerImage"
echo "using tableName: $tableName"

service docker start

export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | rev | cut -c '2-' | rev)
eval "$(aws ecr get-login --no-include-email)"

docker run \
    -d \
    --mount src="/home/app/",target=/config,type=bind \
    --env tableName="$tableName" \
    -p 8080:8080 \
    "$dockerImage"
