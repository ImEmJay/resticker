#
# Builder image
#
FROM golang:1.12 AS builder

ARG RESTIC_VERSION=0.9.6
ARG RESTIC_SHA256=1cc8655fa99f06e787871a9f8b5ceec283c856fa341a5b38824a0ca89420b0fe
ARG GO_CRON_VERSION=0.0.4
ARG GO_CRON_SHA256=6c8ac52637150e9c7ee88f43e29e158e96470a3aaa3fcf47fd33771a8a76d959
ARG RCLONE_VERSION=1.50.2
ARG RCLONE_AMD64_SHA256=2112883164f1f341b246a275936e7c3019d68135002098d84637839dec9526c8
ARG RCLONE_ARM_SHA256=9d24fd374e1f2b586f4660796180ad882e8b390dcfb7274f22595b3bd3a448e6
ARG RCLONE_ARM64_SHA256=2e46b367e6c7302de1259db0c9ae6d782d08566557d58479e378029e12037427
ARG DRONE_STAGE_ARCH
ARG PLATFORM=$DRONE_STAGE_ARCH

RUN curl -sL -o go-cron.tar.gz https://github.com/djmaze/go-cron/archive/v${GO_CRON_VERSION}.tar.gz \
 && echo "${GO_CRON_SHA256}  go-cron.tar.gz" | sha256sum -c - \
 && tar xzf go-cron.tar.gz \
 && cd go-cron-${GO_CRON_VERSION} \
 && go build \
 && mv go-cron /usr/local/bin/go-cron \
 && cd .. \
 && rm go-cron.tar.gz go-cron-${GO_CRON_VERSION} -fR

RUN curl -sL -o rclone.zip https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-${PLATFORM}.zip \
 && eval "echo \${RCLONE_$(echo $PLATFORM | tr '[a-z]' '[A-Z]')_SHA256} rclone.zip" | sha256sum -c - \
 && apt-get update -qq \
 && apt-get install -yq unzip \
 && unzip -a rclone.zip \
 && mv rclone-v${RCLONE_VERSION}-linux-${PLATFORM}/rclone /usr/local/bin/rclone \
 && rm rclone.zip rclone-v${RCLONE_VERSION}-linux-${PLATFORM} -fR \
 && rm /var/lib/apt/lists/* -fR

RUN curl -sL -o restic.tar.gz https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic-${RESTIC_VERSION}.tar.gz \
 && echo "${RESTIC_SHA256}  restic.tar.gz" | sha256sum -c - \
 && tar xzf restic.tar.gz \
 && cd restic-${RESTIC_VERSION} \
 && go run build.go \
 && mv restic /usr/local/bin/restic \
 && cd .. \
 && rm restic.tar.gz restic-${RESTIC_VERSION} -fR

#
# Final image
#
FROM alpine:3.10

RUN apk add --update --no-cache ca-certificates fuse nfs-utils openssh tzdata bash curl
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community/ docker-cli

ENV RESTIC_REPOSITORY /mnt/restic

COPY --from=builder /usr/local/bin/* /usr/local/bin/
COPY backup /usr/local/bin/
COPY entrypoint /

ENTRYPOINT ["/entrypoint"]
