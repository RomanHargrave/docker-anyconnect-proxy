FROM debian:stretch-slim

ARG OC_CONFIG=oc.cfg
ARG OC_SCRIPT=oc.sh

RUN apt update
RUN apt install -y openconnect haproxy vpnc-scripts iproute2 iputils-ping

# Create a CSD user if we intend to execute the cisco trojan instead of using a wrapper
RUN useradd -r csd-user

COPY trojans/ /trojans

COPY ${OC_CONFIG} /oc.cfg
COPY ${OC_SCRIPT} /oc.sh
RUN  chown root:root /oc.cfg /oc.sh && chmod ug+x /oc.sh

COPY run.sh /run.sh
RUN  chown root:root /run.sh

VOLUME   ["/srv/proxy"]
CMD      /run.sh
