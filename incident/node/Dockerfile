# Ubuntu + osctrl-cli (to read enroll secret/flags) + osquery.
ARG OSCTRL_VERSION=0.6.3
FROM jmpsec/osctrl-cli:${OSCTRL_VERSION}

ARG OSQUERY_VERSION=5.24.0
ARG TARGETARCH

USER root
ADD https://pkg.osquery.io/deb/osquery_${OSQUERY_VERSION}-1.linux_${TARGETARCH}.deb /tmp/osquery.deb
RUN dpkg -i /tmp/osquery.deb && rm /tmp/osquery.deb

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
