FROM debian:stretch-slim

ARG OC_CONFIG=oc.cfg
ARG OC_SCRIPT=oc.sh

RUN apt update
RUN apt install -y openconnect haproxy vpnc-scripts iproute2 iputils-ping

COPY --chown=root:root ${OC_CONFIG} /oc.cfg
COPY --chown=root:root ${OC_SCRIPT} /oc.sh
RUN  chmod ug+x /oc.sh

COPY --chown=root:root run.sh /run.sh

CMD /run.sh
