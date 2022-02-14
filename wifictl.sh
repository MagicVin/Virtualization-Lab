#!/bin/bash

#
# script for easily deploy/control wifi on Alpinelinx
# Feb 14, 2022
# v.xin.zhang@gmail.com
#

install_sw() {
  apk update
  apk add wireless-tools wpa_supplicant bash
}

scan_wifi() {
  ip link set dev $WLAN up
  SSIDs=(`iwlist $WLAN scanning | awk -F: '/SSID/ {print $NF}' | sed 's/"//g'`)
}

show_ssids() {
  echo "Available connections(SSIDs):"
  echo ${SSIDs[@]} | sed 's/ /\n/g'
}

check_wifi() {
  [ $# -ne 2 ] && help_msg && exit -1 
  scan_wifi  
  for i in ${SSIDs[@]} ;{
    [ $i == $1 ] && SSID=$1
  }

  [ `echo $2 | wc -c` -gt 8 ] && PASSWD=$2 || PASSWD=

  [ ! $SSID ] && echo "SSID:\"$1\" can not be found in this LAN, please check again!" && exit -1
  [ ! $PASSWD ] && echo "the length of password must be equal to or greater than 8" && exit -1
}

view_wifi() {
  wpa_passphrase $SSID $PASSWD 
}

conf_wifi() {
  check_wifi $@
  [ -s $WIFI_CONF ] && {
    echo "$WIFI_CONF exist!"
    echo "make a copy: ${WIFI_CONF}~"
    cp ${WIFI_CONF} ${WIFI_CONF}~
  }
  echo "$WIFI_CONF created"
  wpa_passphrase $SSID $PASSWD | tee $WIFI_CONF
}

start_wifi() {
  [ ! -s $WIFI_CONF ] && echo "$WIFI_CONF can not be found, please use cmds to generate it: $0 config [ssid] [password]" && exit -1
  echo "link up $WLAN"
  ip link set dev $WLAN up
  echo "loading wifi config ..."
  wpa_supplicant -i $WLAN -c $WIFI_CONF &
  echo "$!" > $WIFI_PID
  echo "fetching network setting ..."
  udhcpc -i $WLAN -p $UDPCHC_PID
  ip addr show dev $WLAN
}

press_wifi() {
  Status=`ip addr show $WLAN | sed -n 's/^.*state \(.*\) qlen.*$/\1/p' | awk '{print $1}'`
  case $Status in
    "UP") #  the connection is up, so down the connection
      ps aux | grep $WLAN | awk '{print $1}' | xargs sudo kill -9 > /dev/null 2>&1
      sleep 1
      sudo ip link set dev $WLAN down
      sleep 1
      sudo ip addr flush $WLAN 
    ;;
    *) # not UP then up the connection
      ps aux | grep $WLAN | awk '{print $1}' | xargs sudo kill -9 > /dev/null 2>&1
      sleep 1
      sudo ip link set dev $WLAN up 
      sleep 1
      sudo wpa_supplicant -i $WLAN -c $WIFI_CONF & > /dev/null 2>&1
      sudo udhcpc -i $WLAN & > /dev/null 2>&1
    ;;
  esac
}

used_wifi() {
  wifi_id=0
  printf "%-5s %-10s\n" "ID" "NAME"
  for wifi in ${WIFI_SHIFT[@]} ;{
    printf "%-5s %-10s\n" "$wifi_id" "${wifi##*/}" | sed 's/.wifi//'
    let wifi_id++
  }
}

shift_wifi() {
  [ $# -ne 1 ] && used_wifi
  [ -s /etc/wpa_supplicant/${1}.wifi ] && sudo cat /etc/wpa_supplicant/${1}.wifi > $WIFI_CONF
}

help_msg() {
  msg=(
   \ $0 install\;
    $0 scan\;
    $0 check [ssid] [password]\;
    $0 config [ssid] [password]\;
    $0 'shift' [id]\;
    $0 press\;
  )
  echo "${msg[@]}" | sed 's/;/\n/g'
}

WLAN=wlan0
SSIDs=
PASSWD=
SSID=
WIFI_SHIFT=(`ls /etc/wpa_supplicant/*wifi`)
WIFI_CONF=/etc/wpa_supplicant/wpa_supplicant.conf
WIFI_PID=/etc/wpa_supplicant/wifi_pid.txt
UDPCHC_PID=/etc/wpa_supplicant/udhcpc_pid.txt

if [ ! -e /bin/bash ] 
then
  apk update
  apk add bash
fi

case $1 in 
  "install") 
    install_sw
  ;;
  "scan")
    scan_wifi
    show_ssids
  ;;
  "check")
    shift
    check_wifi $@
    view_wifi
  ;;
  "config")
    shift
    conf_wifi $@
  ;;
  "shift")
    shift
    shift_wifi $1
  ;;
  "press")
    press_wifi
  ;;
  *)
    help_msg
  ;;
esac
