#!/bin/sh

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

log() {
  logger -t "IntelNCM" "$@"
}
##########
stop_() {
  gcom -d $1 -s /etc/gcom/xmm-disconnect.gcom
}
##########
start_() {
  local PORT=$1
  SCRIPT=/etc/gcom/xmm-connect.gcom
  GO=$(APN=$APN gcom -d $PORT -s $SCRIPT)
  IPADDR=$(echo "$GO" | awk -F [,] '/^\+CGPADDR/{gsub("\"", ""); print $2}')
  RETRIES=0
  until [ $IPADDR ]; do
    GO=$(APN=$APN gcom -d $PORT -s $SCRIPT)
    IPADDR=$(echo "$GO" | awk -F [,] '/^\+CGPADDR/{gsub("\"", ""); print $2}')
    if [ $(echo "$GO" | grep CONNECT) ]; then
      log "Modem connected"
    else
      RETRIES=$(($RETRIES + 1))
      if [ $RETRIES -ge 5 ]; then
        log "Modem failed to connect"
        return 1
      fi
    fi
  done
  log "Obtained IP Address $IPADDR "
}
############

cellular_() {
  local PORT=$1
  local INTERFACE=$2
  local dev=$3
  SCRIPT=/etc/gcom/xmm-config.gcom
  if [ $(ls $SCRIPT) ]; then
    DATA=$(gcom -d $PORT -s $SCRIPT)
    IPADDR=$(echo "$DATA" | awk -F [,] '/^\+CGPADDR/{gsub("\"|\r",""); print $2}' | sed 's/[[:space:]]//g')
    DNS0=$(echo "$DATA" | awk -F [,] '/^\+XDNS: 0/{gsub("\r|\"",""); print $2" "$3}' | sed 's/^[[:space:]]//g')
    DNS1=$(echo "$DATA" | awk -F [,] '/^\+XDNS: 1/{gsub("\r|\"",""); print $2" "$3}' | sed 's/^[[:space:]]//g')
    if [ "$(echo $DNS0 | grep 0.0.0.0)" ]; then
      DNS=$DNS1
    else
      DNS=$DNS0
    fi
  else
    logger -t "$NODE" "Failed to connect network"
    exit 0
  fi
  for d in $DNS; do
    if [ $(echo "$NS" | grep "$d") ]; then
      false
    else
      if [ "$d" != "0.0.0.0" ]; then
        NS="$NS $d"
      fi
    fi
  done
  DNS=$NS
  if [ $IPADDR ]; then
    GATEWAY=$(echo $IPADDR | awk -F [.] '{print $1"."$2"."$3".1"}')
  else
    logger -t "$NODE" "Failed to obtain IP-address"
    exit 0
  fi
  proto_init_update "$dev" 1
  proto_set_keep 1
  proto_add_ipv4_address "$(echo ${IPADDR})" "255.255.255.0"
  proto_add_ipv4_route "0.0.0.0" 0 "$GATEWAY" "" 10
  proto_send_update "$interface"
  proto_add_dns_server "$DNS"
  proto_add_dynamic_defaults
  ip link set dev $dev arp off
}

##########

INCLUDE_ONLY=1

proto_intel_ncm_init_config() {
  log "Start intel_ncm proto initialization"
  proto_config_add_string "apn"
  proto_config_add_string "device"
  no_device=1
  available=1
  log "intel_ncm proto initialized"
}

proto_intel_ncm_setup() {
  local interface="$1"

  local manufacturer initialize setmode connect finalize ifname devname devpath

  local modem device apn auth username password pincode delay mode pdptype profile $PROTO_DEFAULT_OPTIONS
  log "Start Setup for ${interface}"
  json_get_var device device
  log "modem ${device}"
  json_get_vars apn $PROTO_DEFAULT_OPTIONS
  log "APN=${apn}"

  log "Going to bring up interface ${interface} with device ${device}"

  [ "$metric" = "" ] && metric="0"

  [ -n "$profile" ] || profile=1

  pdptype=$(echo "$pdptype" | awk '{print toupper($0)}')
  [ "$pdptype" = "IP" -o "$pdptype" = "IPV6" -o "$pdptype" = "IPV4V6" ] || pdptype="IP"

  [ -n "$ctl_device" ] && device=$ctl_device

  [ -n "$device" ] || {
    log "No control device specified"
    proto_notify_error "$interface" NO_DEVICE
    proto_set_available "$interface" 0
    return 1
  }

  device="$(readlink -f $device)"
  [ -e "$device" ] || {
    log "Control device not valid"
    proto_set_available "$interface" 0
    return 1
  }

  devname="$(basename "$device")"
  case "$devname" in
  'tty'*)
    devpath="$(readlink -f /sys/class/tty/$devname/device)"
    ifname="$(ls "$devpath"/subsystem/drivers/cdc_ncm/*/net | grep eth | sort | head -n 1)"
    ;;
  *)
    devpath="$(readlink -f /sys/class/usbmisc/$devname/device/)"
    ifname="$(ls "$devpath"/net)"
    ;;
  esac
  [ -n "$ifname" ] || {
    log "The interface could not be found."
    proto_notify_error "$interface" NO_IFACE
    proto_set_available "$interface" 0
    return 1
  }
  log "Select Ethernet port ${ifname}"

  [ -n "$delay" ] && sleep "$delay"

  log "Bring up interface ${interface} with ethernet port ${ifname}"
  start_ $device
  [ $? = 1 ] && {
    log "Error during connect"
    return
  }
  log "Connected"
  #  proto_init_update "${ifname}" 1
  #  proto_send_update "$interface"
  cellular_ $device $interface $ifname
  log "Ready to process traffic"
}
proto_intel_ncm_teardown() {
  local interface="$1"
  local iface="$2"
  local device
  log "Bringing interface ${interface} down"
  json_get_var device device
  stop_ $device
  log "Connection terminated"
  #  proto_init_update "*" 0
  proto_send_update "$interface"

}

add_protocol intel_ncm
