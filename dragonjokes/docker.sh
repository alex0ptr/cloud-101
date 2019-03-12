#!/usr/bin/env bash
set -e
set -u
set -o pipefail

mvn package
version=$(cat target/maven-archiver/pom.properties | grep version | cut -d '=' -f 2)
docker build . -t "dragonjokes:$version"
aws ecr create-repository --repository-name dragonjokes || true
eval "$(aws ecr get-login --no-include-email)"
imageUri=$(aws ecr describe-repositories --repository-names dragonjokes --query 'repositories[0].repositoryUri' --output text)
docker tag "dragonjokes:$version" "$imageUri:$version"
docker push "$imageUri:$version"

