# =============================================================================
# OpenHostingNOC - All-in-One Deployable Image
# =============================================================================
# Packages the entire project with docker-cli and docker-compose so the
# NOC platform can be deployed with a single `docker run` command.
#
# Usage:
#   docker pull ghcr.io/samsesh/opennoc:latest
#   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
#     ghcr.io/samsesh/opennoc install
# =============================================================================

FROM docker:28-cli AS base

LABEL org.opencontainers.image.title="OpenHostingNOC"
LABEL org.opencontainers.image.description="Self-hosted Network Operations Center for hosting providers"
LABEL org.opencontainers.image.url="https://github.com/samsesh/OpenHostingNOC"
LABEL org.opencontainers.image.source="https://github.com/samsesh/OpenHostingNOC"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache bash docker-compose curl wget jq gettext openssl

WORKDIR /opennoc

COPY . .

RUN chmod +x scripts/*.sh security/suricata/install.sh

ENTRYPOINT ["/opennoc/scripts/install.sh"]
CMD []
