# Docker Container

We provide Sandboxy server Docker images using the GitHub container registry.

## Available Images

* `ghcr.io/sandboxy-org/sandboxy:master` (latest build)
* `ghcr.io/sandboxy-org/sandboxy:<tag>` (specific Git tag)
* `ghcr.io/sandboxy-org/sandboxy:latest` (latest Git tag, which is the stable release)

See [here](https://github.com/sandboxy-org/sandboxy/pkgs/container/sandboxy) for all available tags.

## Usage

### Quick Start

```bash
docker run ghcr.io/sandboxy-org/sandboxy:master
```

### Data persistence

To persist worlds and configuration between container recreation, mount volumes for `/var/lib/sandboxy/` and `/etc/sandboxy/`:

```bash
docker create -v /home/sandboxy/data/:/var/lib/sandboxy/ -v /home/sandboxy/conf/:/etc/sandboxy/ ghcr.io/sandboxy-org/sandboxy:master
```

### docker-compose

Example `docker-compose.yml`:

```yaml
version: "3.8"

services:
  sandboxy:
    image: ghcr.io/sandboxy-org/sandboxy:master
    container_name: sandboxy
    restart: unless-stopped
    ports:
      - "30000:30000/udp"  # Game
      - "30000:30000/tcp"  # Web interface
    volumes:
      - /home/sandboxy/data/:/var/lib/sandboxy/
      - /home/sandboxy/conf/:/etc/sandboxy/
```
