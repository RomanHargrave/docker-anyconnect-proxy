#!/bin/bash

_pid_file=/oc.pid
_cfg_file=${OC_CONFIG_FILE:-/oc.cfg}
_hac_file=/haproxy.cfg
_hap_file=/haproxy.pid

OC_OPTS="--background --pid-file=$_pid_file --config=${OC_CONFIG_FILE:-/oc.cfg} $OC_EXTRA_OPTS"


################################################
# OpenConnect Lifecycle Functions              #
################################################

start_oc() {
   if [ "x$OC_PASSWORD" != "x" ]; then
      if [ "x$OC_USERNAME" = "x" ]; then echo "password is set, but username is not"; exit 22; fi
      echo -n "$OC_PASSWORD" | /usr/sbin/openconnect $OC_OPTS --user="$OC_USERNAME" --passwd-on-stdin "$OC_SERVER"
   else
      /usr/sbin/openconnect $OC_OPTS "$OC_SERVER"
   fi

   sleep 1

   if ! check_oc; then
      echo "OpenConnect didn't start. No clue why."
      exit 22
   else
      ip link list
      ip route
   fi
}

get_oc_pid() {
   cat "$_pid_file"
}

check_oc() {
   kill -s 0 $(get_oc_pid)
}

reconnect_oc() {
   kill -USR2 $(get_oc_pid)
}

stop_oc() {
   kill $(get_oc_pid)
}


check_upstream() {
   ping -c 2 "$UPSTREAM" 2>&1 >/dev/null
}

################################################
# Haproxy Lifecycle Functions                  #
################################################

start_haproxy() {
   /usr/sbin/haproxy -p "$_hap_file" -f "$_hac_file" -D
   sleep 1
   if ! check_haproxy; then
      echo "Haproxy did not start."
      exit 22
   fi
}

get_haproxy_pid() {
   cat "$_hap_file"
}

check_haproxy() {
   kill -s 0 $(get_haproxy_pid)
}

# Start the VPN. If it fails to start, exit.
start_oc

while ! check_upstream; do
   echo "Waiting for upstream to become available"
   sleep 5
done

# Write out haproxy configuration
cat > "$_hac_file" <<PROX
global
   maxconn 9999
   user root
   group root
   daemon

defaults
   timeout connect 25s
   timeout client 10h
   timeout server 10h
   mode tcp

frontend container_frontend
   bind *:$UPSTREAM_PORT
   default_backend container_backend

backend container_backend
   server upstream $UPSTREAM:$UPSTREAM_PORT
PROX

# Start haproxy
start_haproxy

echo "$(date) Started. OpenConnect has PID $(get_oc_pid), haproxy has PID $(get_haproxy_pid)"
echo "$(date) Proxying (any):$UPSTREAM_PORT => $UPSTREAM:$UPSTREAM_PORT"
echo "$(date) Entering liveness test loop."

while true; do
   # If OC isn't running, start it again
   if ! check_oc; then
      echo "$(date) Restarting OpenConnect client"
      start_oc
      echo "$(date) OpenConnect now has PID $(get_oc_pid)"
   elif ! check_upstream; then
      echo "$(date) Upstream not responding. Asking OC to reconnect."
      reconnect_oc
   fi

   if ! check_haproxy; then
      echo "$(date) Restarting haproxy"
      start_haproxy
      echo "$(date) haproxy now has PID $(get_haproxy_pid)"
   fi
   sleep 30
done

