#
# Builder image
#
FROM golang:1.15 AS builder

ARG RESTIC_VERSION=0.10.0
ARG RESTIC_SHA256=067fbc0cf0eee4afdc361e12bd03b266e80e85a726647e53709854ec142dd94e
ARG GO_CRON_VERSION=0.0.4
ARG GO_CRON_SHA256=6c8ac52637150e9c7ee88f43e29e158e96470a3aaa3fcf47fd33771a8a76d959
ARG RCLONE_VERSION=1.53.1
ARG RCLONE_AMD64_SHA256=0008edeefde5bc2d516f1ea23170a9abac795565e03470c4e5b6a4a361cf9a89
ARG RCLONE_ARM_SHA256=0f830af66d664113fd80b0c7513dd1b2b70c629d011d60d8c1e00973147e4c06
ARG RCLONE_ARM64_SHA256=e51c70a1267ca141f7134de93446d85d2a36d8a3462f2f77fa6ec6c24ae65cb0
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
FROM alpine:3.12

RUN apk add --update --no-cache ca-certificates fuse nfs-utils openssh tzdata bash curl docker-cli

ENV RESTIC_REPOSITORY /mnt/restic

COPY --from=builder /usr/local/bin/* /usr/local/bin/
COPY backup prune /usr/local/bin/
COPY entrypoint /

ENTRYPOINT ["/entrypoint"]
