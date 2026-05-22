![banner](https://raw.githubusercontent.com/11notes/static/refs/heads/master/img/banner/README.png)

# PATCHMON
![size](https://img.shields.io/badge/image_size-253MB-green?color=%2338ad2d)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/master/img/markdown/transparent5x2px.png)![pulls](https://img.shields.io/docker/pulls/11notes/patchmon?color=2b75d6)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/master/img/markdown/transparent5x2px.png)[<img src="https://img.shields.io/github/issues/11notes/docker-patchmon?color=7842f5">](https://github.com/11notes/docker-patchmon/issues)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/master/img/markdown/transparent5x2px.png)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

run patchmon rootless and distroless.

# INTRODUCTION 📢

[PatchMon](https://github.com/PatchMon/PatchMon) (created by [PatchMon](https://github.com/PatchMon)) is an enterprise-grade platform that gives operations teams a single pane of glass to monitor, patch and secure their Linux fleet, with FreeBSD and Windows agent support.

# SYNOPSIS 📖
**What can I do with this?** This image will run PatchMon [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md) for more security.

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image has no shell since it is [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)
>* ... this image supports 32bit architecture
>* ... this image is auto updated to the latest version via CI/CD
>* ... this image has a health check
>* ... this image runs read-only
>* ... this image is automatically scanned for CVEs before and after publishing
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | **size on disk** | **init default as** | **[distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)** | supported architectures
| ---: | ---: | :---: | :---: | :---: |
| 11notes/patchmon | 253MB | 1000:1000 | ✅ | amd64, arm64, armv7 |
| patchmon/patchmon-server | 639MB | 65532:65532 | ❌ | amd64, arm64 |

# VOLUMES 📁
* **/patchmon/var** - Directory of dynamic data like ssg updates

# COMPOSE ✂️
```yaml
name: "patchmon"

x-lockdown: &lockdown
  # prevents write access to the image itself
  read_only: true
  # prevents any process within the container to gain more privileges
  security_opt:
    - "no-new-privileges=true"

services:
  server:
    depends_on:
      postgres:
        condition: "service_healthy"
        restart: true
      redis:
        condition: "service_healthy"
        restart: true
    image: "11notes/patchmon:2.0.2"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      DATABASE_URL: "postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/postgres"
      REDIS_PASSWORD: "${REDIS_PASSWORD}"
      CORS_ORIGIN: "${CORS_ORIGIN}"
      JWT_SECRET: "${JWT_SECRET}"
    volumes:
      - "server.var:/patchmon/var"
    ports:
      - "3000:3000/tcp"
    networks:
      frontend:
      backend:
    restart: "always"

  postgres:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-postgres
    image: "11notes/postgres:18"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_BACKUP_SCHEDULE: "0 3 * * *"
    volumes:
      - "postgres.etc:/postgres/etc"
      - "postgres.var:/postgres/var"
      - "postgres.backup:/postgres/backup"
    tmpfs:
      - "/postgres/run:uid=1000,gid=1000"
      - "/postgres/log:uid=1000,gid=1000"
    networks:
      backend:
    restart: "always"

  redis:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-redis
    image: "11notes/redis:8.6.3"
    <<: *lockdown
    environment:
      REDIS_PASSWORD: "${REDIS_PASSWORD}"
      TZ: "Europe/Zurich"
    networks:
      backend:
    volumes:
      - "redis.etc:/redis/etc"
      - "redis.var:/redis/var"
    tmpfs:
      - "/run:uid=1000,gid=1000"
    restart: "always"

volumes:
  server.var:
  postgres.etc:
  postgres.var:
  postgres.backup:
  redis.etc:
  redis.var:

networks:
  frontend:
  backend:
    internal: true
```
To find out how you can change the default UID/GID of this container image, consult the [RTFM](https://github.com/11notes/RTFM/blob/main/linux/container/image/11notes/how-to.changeUIDGID.md#change-uidgid-the-correct-way).

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /patchmon | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [2.0.2](https://hub.docker.com/r/11notes/patchmon/tags?name=2.0.2)
* [2.0.2-unraid](https://hub.docker.com/r/11notes/patchmon/tags?name=2.0.2-unraid)
* [2.0.2-nobody](https://hub.docker.com/r/11notes/patchmon/tags?name=2.0.2-nobody)

### There is no latest tag, what am I supposed to do about updates?
It is my opinion that the ```:latest``` tag is a bad habbit and should not be used at all. Many developers introduce **breaking changes** in new releases. This would messed up everything for people who use ```:latest```. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:2.0.2``` you can use ```:2``` or ```:2.0```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version. Which in theory should not introduce breaking changes.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/patchmon:2.0.2
docker pull ghcr.io/11notes/patchmon:2.0.2
docker pull quay.io/11notes/patchmon:2.0.2
```

# UNRAID VERSION 🟠
This image supports unraid by default. Simply add **-unraid** to any tag and the image will run as 99:100 instead of 1000:1000.

# NOBODY VERSION 👻
This image supports nobody by default. Simply add **-nobody** to any tag and the image will run as 65534:65534 instead of 1000:1000.

# SOURCE 💾
* [11notes/patchmon](https://github.com/11notes/docker-patchmon)

# PARENT IMAGE 🏛️
> [!IMPORTANT]
>This image is not based on another image but uses [scratch](https://hub.docker.com/_/scratch) as the starting layer.
>The image consists of the following distroless layers that were added:
>* [11notes/distroless](https://github.com/11notes/docker-distroless/blob/master/arch.dockerfile) - contains users, timezones and Root CA certificates, nothing else
>* [11notes/distroless:localhealth](https://github.com/11notes/docker-distroless/blob/master/localhealth.dockerfile) - app to execute HTTP requests only on 127.0.0.1

# BUILT WITH 🧰
* [PatchMon](https://github.com/PatchMon/PatchMon)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-patchmon/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-patchmon/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-patchmon/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 22.05.2026, 08:56:00 (CET)*