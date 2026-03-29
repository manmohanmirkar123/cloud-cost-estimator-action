FROM alpine:3.20

LABEL maintainer="cloud-cost-awareness@example.com"
LABEL description="Cloud Cost Awareness Action with Infracost"

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    git \
    && rm -rf /var/cache/apk/*

# Install Infracost CLI latest
RUN curl -fsSL https://raw.githubusercontent.com/infracost/infracost/main/scripts/install.sh | sh \
    && mv /root/.infracost/infracost-linux64 /usr/local/bin/infracost \
    && chmod +x /usr/local/bin/infracost

WORKDIR /iac

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

