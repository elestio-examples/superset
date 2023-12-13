#!/usr/bin/env bash
sed -i "s~--password ~--password ${ADMIN_PASSWORD}~g" ./docker/docker-init.sh
sed -i "s~--email ~--email ${ADMIN_EMAIL}~g" ./docker/docker-init.sh
docker buildx build . --output type=docker,name=elestio4test/superset:latest | docker load