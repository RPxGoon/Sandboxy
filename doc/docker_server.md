# Running a Sandboxy Server with Docker

This guide explains how to set up a Sandboxy server using Docker.

## Quick Start

1. Pull the official image:
```
docker pull sandboxyorg/sandboxyserver
```

2. Create a directory for your server data:
```
mkdir ~/sandboxyserver
cd ~/sandboxyserver
```

3. Start the server:
```
docker run -d \
    --name sandboxyserver \
    -p 30000:30000/udp \
    -v $(pwd):/var/lib/sandboxy \
    sandboxyorg/sandboxyserver
```

The server will now be running on port 30000.

## Configuration

### Server Settings

Create a `sandboxy.conf` file in your server directory with your settings:

```conf
name = My Sandboxy Server
description = Welcome to my server!
port = 30000
max_users = 15
enable_pvp = true

# Game settings
creative_mode = false
enable_damage = true
```

### World Data

World data is stored in:
```
/var/lib/sandboxy/worlds/
```

### Installing Mods

Place mods in:
```
/var/lib/sandboxy/mods/
```

### Docker Compose

Example docker-compose.yml:

```yaml
version: "3"
services:
  sandboxyserver:
    image: sandboxyorg/sandboxyserver:latest
    container_name: sandboxyserver
    restart: unless-stopped
    ports:
      - "30000:30000/udp"
    volumes:
      - ./:/var/lib/sandboxy
```

## Building Custom Server Image

Create a Dockerfile:

```dockerfile
FROM sandboxyorg/sandboxyserver

# Install additional packages
RUN apk add --no-cache ...

# Add custom mods
COPY mods/ /var/lib/sandboxy/mods/

# Add custom configuration
COPY sandboxy.conf /etc/sandboxy/sandboxy.conf
```

Build and run:
```
docker build -t mysandboxyserver .
docker run -d --name mysandboxyserver -p 30000:30000/udp mysandboxyserver
```
