<a href="https://elest.io">
  <img src="https://elest.io/images/elestio.svg" alt="elest.io" width="150" height="75">
</a>

[![Discord](https://img.shields.io/static/v1.svg?logo=discord&color=f78A38&labelColor=083468&logoColor=ffffff&style=for-the-badge&label=Discord&message=community)](https://discord.gg/4T4JGaMYrD "Get instant assistance and engage in live discussions with both the community and team through our chat feature.")
[![Elestio examples](https://img.shields.io/static/v1.svg?logo=github&color=f78A38&labelColor=083468&logoColor=ffffff&style=for-the-badge&label=github&message=open%20source)](https://github.com/elestio-examples "Access the source code for all our repositories by viewing them.")
[![Blog](https://img.shields.io/static/v1.svg?color=f78A38&labelColor=083468&logoColor=ffffff&style=for-the-badge&label=elest.io&message=Blog)](https://blog.elest.io "Latest news about elestio, open source software, and DevOps techniques.")

# Superset, verified and packaged by Elestio

[Superset](https://github.com/apache/superset) is a modern data exploration and data visualization platform. Superset can replace or augment proprietary business intelligence tools for many teams. Superset integrates well with a variety of data sources.

<img src="https://github.com/elestio-examples/superset/raw/main/superset.jpg" alt="sole" width="800">

Deploy a <a target="_blank" href="https://elest.io/open-source/superset">fully managed superset</a> on <a target="_blank" href="https://elest.io/">elest.io</a> if you want automated backups, reverse proxy with SSL termination, firewall, automated OS & Software updates, and a team of Linux experts and open source enthusiasts to ensure your services are always safe, and functional.

[![deploy](https://github.com/elestio-examples/superset/raw/main/deploy-on-elestio.png)](https://dash.elest.io/deploy?source=cicd&social=dockerCompose&url=https://github.com/elestio-examples/superset)

# Why use Elestio images?

- Elestio stays in sync with updates from the original source and quickly releases new versions of this image through our automated processes.
- Elestio images provide timely access to the most recent bug fixes and features.
- Our team performs quality control checks to ensure the products we release meet our high standards.

# Usage

## Git clone

You can deploy it easily with the following command:

    git clone https://github.com/elestio-examples/superset.git

Copy the .env file from tests folder to the project directory

    cp ./tests/.env ./.env

Edit the .env file with your own values.

Create data folders with correct permissions

    mkdir -p ./docker
    chown -R 1000:1000 ./docker

    mkdir -p ./superset_home
    chown -R 1000:1000 ./superset_home

    mkdir -p ./redis
    chown -R 1000:1000 ./redis

    mkdir -p ./db_home
    chown -R 1000:1000 ./db_home

    chmod +x ./docker
    chmod +x ./docker/*.sh

Run the project with the following command

    docker-compose up -d

You can access the Web UI at: `http://your-domain:8088`

## Docker-compose

Here are some example snippets to help you get started creating a container.

    x-superset-image: &superset-image apache/superset:${TAG:-latest-dev}
    x-superset-depends-on: &superset-depends-on
        - db
        - redis
    x-superset-volumes:
        &superset-volumes # /app/pythonpath_docker will be appended to the PYTHONPATH in the final container
        - ./docker:/app/docker
        - ./superset_home:/app/superset_home

    version: "3.3"
    services:
    redis:
        image: redis:7
        restart: always
        volumes:
            - ./redis:/data

    db:
        env_file: ./.env
        image: postgres:14
        restart: always
        volumes:
            - ./db_home:/var/lib/postgresql/data

    superset:
        env_file: ./.env
        image: *superset-image
        command: ["/app/docker/docker-bootstrap.sh", "app-gunicorn"]
        user: "root"
        restart: always
        ports:
            - 172.17.0.1:8088:8088
        depends_on: *superset-depends-on
        volumes: *superset-volumes

    superset-init:
        image: *superset-image
        command: ["/app/docker/docker-init.sh"]
        env_file: ./.env
        depends_on: *superset-depends-on
        user: "root"
        volumes: *superset-volumes
        healthcheck:
            disable: true

    superset-worker:
        image: *superset-image
        command: ["/app/docker/docker-bootstrap.sh", "worker"]
        env_file: ./.env
        restart: always
        depends_on: *superset-depends-on
        user: "root"
        volumes: *superset-volumes
        healthcheck:
            test:
                [
                "CMD-SHELL",
                "celery -A superset.tasks.celery_app:app inspect ping -d celery@$$HOSTNAME",
                ]

    superset-worker-beat:
        image: *superset-image
        command: ["/app/docker/docker-bootstrap.sh", "beat"]
        env_file: ./.env
        restart: always
        depends_on: *superset-depends-on
        user: "root"
        volumes: *superset-volumes
        healthcheck:
            disable: true


# Maintenance

## Logging

The Elestio Superset Docker image sends the container logs to stdout. To view the logs, you can use the following command:

    docker-compose logs -f

To stop the stack you can use the following command:

    docker-compose down

## Backup and Restore with Docker Compose

To make backup and restore operations easier, we are using folder volume mounts. You can simply stop your stack with docker-compose down, then backup all the files and subfolders in the folder near the docker-compose.yml file.

Creating a ZIP Archive
For example, if you want to create a ZIP archive, navigate to the folder where you have your docker-compose.yml file and use this command:

    zip -r myarchive.zip .

Restoring from ZIP Archive
To restore from a ZIP archive, unzip the archive into the original folder using the following command:

    unzip myarchive.zip -d /path/to/original/folder

Starting Your Stack
Once your backup is complete, you can start your stack again with the following command:

    docker-compose up -d

That's it! With these simple steps, you can easily backup and restore your data volumes using Docker Compose.

# Links

- <a target="_blank" href="https://github.com/apache/superset">Superset Github repository</a>

- <a target="_blank" href="https://superset.apache.org/docs/intro">Superset documentation</a>

- <a target="_blank" href="https://github.com/elestio-examples/superset">Elestio/superset Github repository</a>
