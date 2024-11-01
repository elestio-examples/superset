#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -eo pipefail

REQUIREMENTS_LOCAL="/app/docker/requirements-local.txt"
# If Cypress run – overwrite the password for admin and export env variables
if [ "$CYPRESS_CONFIG" == "true" ]; then
    export SUPERSET_CONFIG=tests.integration_tests.superset_test_config
    export SUPERSET_TESTENV=true
    export SUPERSET__SQLALCHEMY_DATABASE_URI=postgresql+psycopg2://superset:superset@db:5432/superset
fi
#
# Make sure we have dev requirements installed
#
if [ -f "${REQUIREMENTS_LOCAL}" ]; then
  echo "Installing local overrides at ${REQUIREMENTS_LOCAL}"
  pip install -r "${REQUIREMENTS_LOCAL}"
else
  echo "Skipping local overrides"
fi

if [[ "${1}" == "worker" ]]; then
  echo "Starting Celery worker..."
  
  # Update package list and install necessary tools
  apt update && apt install -y wget unzip curl

  # Determine architecture (amd64 or arm64)
  ARCH=$(dpkg --print-architecture)

  # Download and install Google Chrome based on architecture
  if [ "$ARCH" = "amd64" ]; then
      wget -q https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/google-chrome-stable_114.0.5735.90-1_amd64.deb
      apt-get install -y --no-install-recommends ./google-chrome-stable_114.0.5735.90-1_amd64.deb
      rm -f google-chrome-stable_114.0.5735.90-1_amd64.deb
  elif [ "$ARCH" = "arm64" ]; then
      wget -q https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/google-chrome-stable_114.0.5735.90-1_arm64.deb
      apt-get install -y --no-install-recommends ./google-chrome-stable_114.0.5735.90-1_arm64.deb
      rm -f google-chrome-stable_114.0.5735.90-1_arm64.deb
  else
      echo "Unsupported architecture: $ARCH"
      exit 1
  fi

  # Install Chromedriver based on Chrome version and architecture
  CHROMEDRIVER_VERSION=$(curl --silent https://chromedriver.storage.googleapis.com/LATEST_RELEASE_114)
  if [ "$ARCH" = "amd64" ]; then
      wget -q https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip
  elif [ "$ARCH" = "arm64" ]; then
      wget -q https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux_arm64.zip
  fi

  # Unzip Chromedriver and move it to /usr/bin
  unzip chromedriver_linux*.zip -d /usr/bin
  chmod 755 /usr/bin/chromedriver
  rm -f chromedriver_linux*.zip

  # Start the Celery worker
  celery --app=superset.tasks.celery_app:app worker -O fair -l INFO
elif [[ "${1}" == "beat" ]]; then
  echo "Starting Celery beat..."
  celery --app=superset.tasks.celery_app:app beat --pidfile /tmp/celerybeat.pid -l INFO -s "${SUPERSET_HOME}"/celerybeat-schedule
elif [[ "${1}" == "app" ]]; then
  echo "Starting web app..."
  flask run -p 8088 --with-threads --reload --debugger --host=0.0.0.0
elif [[ "${1}" == "app-gunicorn" ]]; then
  echo "Starting web app..."
  /usr/bin/run-server.sh
fi
