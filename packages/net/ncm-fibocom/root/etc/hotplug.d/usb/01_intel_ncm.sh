#!/bin/sh
NODE="IntelNCM"

[ "$ACTION" = bind -a "$DEVTYPE" = usb_device ] || exit 0

. /lib/functions.sh
. /lib/netifd/netifd-proto.sh

vid=$(cat /sys$DEVPATH/idVendor)
pid=$(cat /sys$DEVPATH/idProduct)

logger -t $NODE "deviceId=$vid:$pid  dump=$(env)"
[ "$vid:$pid" = "8087:095a"  ] || exit 0
logger -t $NODE Matched

find_wwan_iface() {
        local cfg="$1"
        local proto
        config_get proto "$cfg" proto
        [ "$proto" = intel_ncm ] || return 0
        proto_set_available "$cfg" 1
        ifup $cfg
        logger -t $NODE "Bring up interface $cfg"
        exit 0
}



config_load network
config_foreach find_wwan_iface interface
