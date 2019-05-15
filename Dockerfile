FROM debian:stretch-slim

ARG OC_CONFIG=oc.cfg
ARG OC_SCRIPT=oc.sh

RUN apt update
RUN apt install -y openconnect haproxy vpnc-scripts iproute2 iputils-ping

COPY /oc.cfg
COPY /oc.sh
RUN  chown root:root /oc.cfg /oc.sh && chmod ug+x /oc.sh

COPY run.sh /run.sh
RUN  chown root:root /run.sh

VOLUME   ["/srv/proxy"]
CMD      /run.sh
