# qlx

## QuakeLive Dedicated server

based on:
https://github.com/derkahless/QuakeLiveDS_Scripts/commit/121b05c96f7ab211baad46ebde0484fbad242fd1
https://github.com/ezagainov/ql-docker/commit/018801ad01d00dd8a61ee2e5a22b99c0ca7e98f5

Features a Docker image for running a dedicated Quake Live server.  It includes installation of minqlx and bundles most of the custom maps from the Steam workshop.

## Installation and Usage

To start a new server using this image:

1. Create a directory to store the persistent Redis database files. `mkdir -p data/redis`
2. Edit configuration in `config/`
3. Launch the qlx stack using `docker-compose up -d`. This will build and execute redis and qlx servers

The image exposes a few environment variables to control deployment:

1. `name`: The name of the server
2. `admin`: The steamid of the server admin.  This person will automatically get rcon access to the server when they are connected.
3. `gameport`: The port to start the server on.
4. `rconport`: The port to listen for remote rcon connections from.

To use a custom server configuration, or to add additional files, you can either fork this repository and edit the included files and then build a new image, mount the files into the container using docker's `-v localpath:containerpath` option, or go into the container and edit them manually using `sudo docker exec -t -i containerid /bin/bash`

