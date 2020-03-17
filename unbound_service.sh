#!/bin/sh
##############################################################################
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# Copyright (C) 2016 Eric Luehrsen
#
##############################################################################
#
# Unbound is a full featured recursive server with many options. The UCI
# provided tries to simplify and bundle options. This should make Unbound
# easier to deploy. Even light duty routers may resolve recursively instead of
# depending on a stub with the ISP. The UCI also attempts to replicate dnsmasq
# features as used in base LEDE/OpenWrt. If there is a desire for more
# detailed tuning, then manual conf file overrides are also made available.
#
##############################################################################

# Adapted for ASUSWRT-Merlin from OpenWRT unbound.sh

# Unbound Directory locations
UB_BINDIR=/opt/sbin
UB_VARDIR=/opt/var/lib/unbound
UB_ADDON_DIR=/jffs/addons/unboundui
UB_PIDFILE=$UB_VARDIR/unbound.pid

# conf deconstructed
UB_TOTAL_CONF=$UB_VARDIR/unbound.conf
UB_CORE_CONF=$UB_VARDIR/server.conf.tmp
UB_CTRL_CONF=$UB_VARDIR/ctrl.conf.tmp
UB_SRV_CONF=$UB_VARDIR/unbound_srv.conf
UB_EXT_CONF=$UB_VARDIR/unbound_ext.conf

# TLS keys
UB_TLS_FWD_FILE=$UB_VARDIR/ca-certificates.crt
UB_TLS_ETC_FILE=/etc/ssl/certs/ca-certificates.crt

# start files
UB_RKEY_FILE=$UB_VARDIR/root.key
UB_RHINT_FILE=$UB_VARDIR/root.hints

# helper apps
UB_ANCHOR=$UB_BINDIR/unbound-anchor
UB_CONTROL=$UB_BINDIR/unbound-control
UB_CHECKCONF=$UB_BINDIR/unbound-checkconf

# Source ASUSWRT-Merlin helper functions
. /usr/sbin/helper.sh

unbound_mkdir() {
  local filestuff

  if [ -f "$UB_RKEY_FILE" ] ; then
    filestuff=$( cat "$UB_RKEY_FILE" )

    case "$filestuff" in
      *"state=2 [  VALID  ]"*)
        # Lets not lose RFC 5011 tracking if we don't have to
        cp -p "$UB_RKEY_FILE" "$UB_RKEY_FILE".keep
        ;;
    esac
  fi

  # Blind copy /etc/unbound to /var/lib/unbound
  [ ! -d "$UB_VARDIR" ] && mkdir -p "$UB_VARDIR"
  touch "$UB_TOTAL_CONF"
  #cp -p /opt/etc/unbound/* "$UB_VARDIR"/

  if [ ! -f "$UB_RHINT_FILE" ] ; then
    curl -o "$UB_RHINT_FILE" https://www.internic.net/domain/named.cache
  fi

  if [ ! -f "$UB_RKEY_FILE" ] && [ -x "$UB_ANCHOR" ] ; then
      $UB_ANCHOR -a "$UB_RKEY_FILE"
  fi

  if [ -f "$UB_RKEY_FILE".keep ] ; then
    # root.key.keep is reused if newest
    cp -u "$UB_RKEY_FILE".keep "$UB_RKEY_FILE"
    rm -f "$UB_RKEY_FILE".keep
  fi

  if [ -f "$UB_TLS_ETC_FILE" ] ; then
    # copy the cert bundle into jail
    cp -p "$UB_TLS_ETC_FILE" "$UB_TLS_FWD_FILE"
  fi

  # Ensure access and prepare to jail
  chown -R nobody:nobody "$UB_VARDIR"
  chmod 755 "$UB_VARDIR"
  chmod 644 "$UB_VARDIR"/*

  if [ "$(nvram get ntp_ready)" -eq "1" ] ; then
    # NTP is done so its like you actually had an RTC
    UB_B_NTP_BOOT=0
  else
    # DNSSEC-TIME will not reconcile
    UB_B_NTP_BOOT=1
  fi
}

##############################################################################

unbound_control() {
  echo "# $UB_CTRL_CONF generated on $( date -Is )" > "$UB_CTRL_CONF"

  {
    # Local Host Only Unencrypted Remote Control
    echo "remote-control:"
    echo "  control-enable: yes"
    echo "  control-use-cert: no"
    echo
  } >> "$UB_CTRL_CONF"

}

##############################################################################

unbound_conf() {
  local rt_mem rt_conn rt_buff modulestring domain

  {
    # server: for this whole function
    echo "# $UB_CORE_CONF generated on $( date -Is )"
    echo "server:"
    echo "  username: nobody"
    echo "  chroot: $UB_VARDIR"
    echo "  directory: $UB_VARDIR"
    echo "  pidfile: $UB_PIDFILE"
  } > "$UB_CORE_CONF"

  if [ -f "$UB_TLS_FWD_FILE" ] ; then
    # TLS cert bundle for upstream forwarder and https zone files
    # This is loaded before drop to root, so pull from /etc/ssl
    echo "  tls-cert-bundle: $UB_TLS_FWD_FILE" >> "$UB_CORE_CONF"
  fi

  if [ -f "$UB_RHINT_FILE" ] ; then
    # Optional hints if found
    echo "  root-hints: $UB_RHINT_FILE" >> "$UB_CORE_CONF"
  fi

  if [ "$UB_B_DNSSEC" -gt 0 ] && [ -f "$UB_RKEY_FILE" ] ; then
    {
      echo "  auto-trust-anchor-file: $UB_RKEY_FILE"
      echo
    } >> "$UB_CORE_CONF"
  else
    echo >> "$UB_CORE_CONF"
  fi

  if $UB_BINDIR/unbound -V | grep -q "Linked libs:.*libevent" ; then
    # heavy variant using "threads" may need substantial resources
    echo "  num-threads: 2" >> "$UB_CORE_CONF"
  else
    # light variant with one "process" is much more efficient with light traffic
    echo "  num-threads: 1" >> "$UB_CORE_CONF"
  fi

  {
    # Logging
    if [ "$UB_D_LOGDEST" = "file" ] ; then
  		echo "  logfile: $UB_VARDIR/unbound.log"
      echo "  log-time-ascii: yes"
  	fi
    if [ "$UB_D_LOGEXTRA" = "1" ] ; then
  		echo "  log-tag-queryreply: yes"
  		echo "  log-servfail: yes"
    fi
    if [ "$UB_D_STATSLOG" -gt 0 ] ; then
      echo "  statistics-interval: (($UB_D_STATSLOG*60))"
  	fi
  } >> "$UB_CORE_CONF"

  if [ "$UB_D_VERBOSE" -ge 0 ] && [ "$UB_D_VERBOSE" -le 5 ] ; then
    echo "  verbosity: $UB_D_VERBOSE" >> "$UB_CORE_CONF"
  fi

  if [ "$UB_B_EXT_STATS" -gt 0 ] ; then
    {
      # Log More
      echo "  extended-statistics: yes"
      echo
    } >> "$UB_CORE_CONF"
  fi

# Common protocol settings
  {
    if [ "$UB_N_EDNS_SIZE" -lt 4096 ]; then
      echo "  edns-buffer-size: $UB_N_EDNS_SIZE"
    fi
    echo "  outgoing-port-permit: 10240-65535"
    if [ "$UB_N_RX_PORT" -ge 10240 ] && [ "$UB_N_RX_PORT" -le 65535 ]; then
      echo "  outgoing-port-avoid: $UB_N_RX_PORT"
    fi
    echo "  port: $UB_N_RX_PORT"
    echo "  interface: 127.0.0.1"
  } >> "$UB_CORE_CONF"

  if [ "$(nvram get ipv6_service)" != "disabled" ]; then
    {
      echo "  prefer-ip6: yes"
      echo
    } >> "$UB_CORE_CONF"
  else
    {
      echo "  do-ip6: no"
      echo
    } >> "$UB_CORE_CONF"
  fi

  case "$UB_D_RESOURCE" in
    # Tiny - Unbound's recommended cheap hardware config
    tiny)   rt_mem=1  ; rt_conn=2  ; rt_buff=1 ;;
    # Small - Half RRCACHE and open ports
    small)  rt_mem=8  ; rt_conn=10 ; rt_buff=2 ;;
    # Medium - Nearly default but with some added balancintg
    medium) rt_mem=16 ; rt_conn=15 ; rt_buff=4 ;;
    # Large - Double medium
    large)  rt_mem=32 ; rt_conn=20 ; rt_buff=4 ;;
    # Whatever unbound does
    *) rt_mem=0 ; rt_conn=0 ;;
  esac

  if [ "$rt_mem" -gt 0 ] ; then
    {
      # Set memory sizing parameters
      echo "  msg-buffer-size: $((rt_buff*8192))"
      echo "  outgoing-range: $((rt_conn*32))"
      echo "  num-queries-per-thread: $((rt_conn*16))"
      echo "  outgoing-num-tcp: $((rt_conn))"
      echo "  incoming-num-tcp: $((rt_conn))"
      echo "  rrset-cache-size: $((rt_mem*256))k"
      echo "  msg-cache-size: $((rt_mem*128))k"
      echo "  key-cache-size: $((rt_mem*128))k"
      echo "  neg-cache-size: $((rt_mem*64))k"
      echo "  infra-cache-numhosts: $((rt_mem*256))"
      echo
    } >> "$UB_CORE_CONF"
  fi

  # Assembly of module-config: options is tricky; order matters
  modulestring="iterator"

  if [ "$UB_B_DNSSEC" -gt 0 ] ; then
    modulestring="validator $modulestring"
  fi

  {
    # Print final module string
    echo "  module-config: \"$modulestring\""
    echo
  }  >> "$UB_CORE_CONF"

  # Some query privacy but "strict" will break some servers
  if [ "$UB_B_QUERY_MIN" -gt 0 ] ; then
    echo "  qname-minimisation: yes"
  else
    echo "  qname-minimisation: no"
  fi

  case "$UB_D_RECURSION" in
    passive)
      {
        # Use DNSSEC to quickly understand NXDOMAIN ranges
        if [ "$UB_B_DNSSEC" -gt 0 ] ; then
          echo "  aggressive-nsec: yes"
          echo "  prefetch-key: no"
        fi
        # On demand fetching
        echo "  prefetch: no"
        echo "  target-fetch-policy: \"0 0 0 0 0\""
        echo
      } >> "$UB_CORE_CONF"
      ;;

    aggressive)
      {
        # Use DNSSEC to quickly understand NXDOMAIN ranges
        if [ "$UB_B_DNSSEC" -gt 0 ] ; then
          echo "  aggressive-nsec: yes"
          echo "  prefetch-key: yes"
        fi
        # Prefetch what can be
        echo "  prefetch: yes"
        echo "  target-fetch-policy: \"3 2 1 0 0\""
        echo
      } >> "$UB_CORE_CONF"
      ;;
  esac

  {
    if [ "$UB_TTL_MIN" -gt 0 ]; then
      echo "  cache-min-ttl: $UB_TTL_MIN"
      echo
    fi
  } >> "$UB_CORE_CONF"

  {
    # Block server id and version DNS TXT records
    echo "  hide-identity: yes"
    echo "  hide-version: yes"
    echo
  } >> "$UB_CORE_CONF"

  if [ "$UB_D_PRIV_BLCK" -gt 0 ] ; then
    {
      # Remove _upstream_ or global reponses with private addresses.
      # Unbounds own "local zone" and "forward zone" may still use these.
      # RFC1918, RFC3927, RFC4291, RFC6598, RFC6890
      echo "  private-address: 10.0.0.0/8"
      echo "  private-address: 169.254.0.0/16"
      echo "  private-address: 172.16.0.0/12"
      echo "  private-address: 192.168.0.0/16"
      echo "  private-address: fc00::/7"
      echo "  private-address: fe80::/10"
      echo "  private-address: 127.0.0.0/8"
      echo "  private-address: ::1/128"
      echo
    } >> "$UB_CORE_CONF"
  fi

  if  [ -n "$UB_LIST_INSECURE" ] ; then
    {
	  for domain in $(echo "$UB_LIST_INSECURE" | /opt/bin/base64 -d) ; do
        # Except and accept domains without (DNSSEC); work around broken domains
        echo "  domain-insecure: $domain"
      done
      echo
    } >> "$UB_CORE_CONF"
  fi

  if  [ -n "$UB_LIST_PRIVATE" ] ; then
    {
	  for domain in $(echo "$UB_LIST_PRIVATE" | /opt/bin/base64 -d) ; do
        # Except and accept domains without (DNSSEC); work around broken domains
        echo "  private-domain: $domain"
      done
      echo
    } >> "$UB_CORE_CONF"
  fi
}

##############################################################################

unbound_uci() {

  UB_B_DNSSEC=$(nvram get dnssec_enable); [ -z "$UB_B_DNSSEC" ] && UB_B_DNSSEC=1
  UB_D_LOGDEST=$(am_settings_get unbound_logdest); [ -z "$UB_D_LOGDEST" ] && UB_D_LOGDEST=syslog
  UB_D_LOGEXTRA=$(am_settings_get unbound_logextra); [ -z "$UB_D_LOGEXTRA" ] && UB_D_LOGEXTRA=0
  UB_D_VERBOSE=$(am_settings_get unbound_verbosity); [ -z "$UB_D_VERBOSE" ] && UB_D_VERBOSE=1
  UB_B_EXT_STATS=$(am_settings_get unbound_extended_stats); [ -z "$UB_B_EXT_STATS" ] && UB_B_EXT_STATS=0
  UB_N_EDNS_SIZE=$(am_settings_get unbound_edns_size); [ -z "$UB_N_EDNS_SIZE" ] && UB_N_EDNS_SIZE=1280
  UB_N_RX_PORT=$(am_settings_get unbound_listen_port); [ -z "$UB_N_RX_PORT" ] && UB_N_RX_PORT=5653
  UB_D_RESOURCE=$(am_settings_get unbound_resource); [ -z "$UB_D_RESOURCE" ] && UB_D_RESOURCE=default
  UB_D_RECURSION=$(am_settings_get unbound_recursion); [ -z "$UB_D_RECURSION" ] && UB_D_RECURSION=passive
  UB_B_QUERY_MIN=$(am_settings_get unbound_query_minimize); [ -z "$UB_B_QUERY_MIN" ] && UB_B_QUERY_MIN=1
  UB_B_HIDE_BIND=$(am_settings_get unbound_hide_binddata); [ -z "$UB_B_HIDE_BIND" ] && UB_B_HIDE_BIND=1
  UB_TTL_MIN=$(am_settings_get unbound_ttl_min); [ -z "$UB_TTL_MIN" ] && UB_TTL_MIN=120
  UB_D_PRIV_BLCK=$(nvram get dns_norebind); [ -z "$UB_D_PRIV_BLCK" ] && UB_D_PRIV_BLCK=0
  UB_LIST_INSECURE="$(am_settings_get unbound_domain_insecure)"
  UB_LIST_PRIVATE="$(am_settings_get unbound_domain_rebindok)"
  UB_CUSTOM_SERVER_CONFIG="$(am_settings_get unbound_custom_server)"
  UB_CUSTOM_EXTEND_CONFIG="$(am_settings_get unbound_custom_extend)"
  UB_D_STATSLOG=$(am_settings_get unbound_statslog); [ -z "$UB_D_STATSLOG" ] && UB_D_STATSLOG=0

  if [ "$UB_N_EDNS_SIZE" -lt 512 ] || [ 4096 -lt "$UB_N_EDNS_SIZE" ] ; then
    logger -t unbound -s "edns_size exceeds range, using default"
    UB_N_EDNS_SIZE=1280
  fi

  if [ "$UB_N_RX_PORT" -ne 53 ] \
  && { [ "$UB_N_RX_PORT" -lt 1024 ] || [ 65535 -lt "$UB_N_RX_PORT" ] ; } ; then
    logger -t unbound -s "privileged port or in 5 digits, using default"
    UB_N_RX_PORT=5653
  fi

  if [ "$UB_TTL_MIN" -gt 1800 ] ; then
    logger -t unbound -s "ttl_min could have had awful side effects, using 300"
    UB_TTL_MIN=300
  fi
}

##############################################################################

unbound_include() {
  echo "# $UB_TOTAL_CONF generated on $( date -Is )" > "$UB_TOTAL_CONF"


  if [ -f "$UB_CORE_CONF" ] ; then
    # Yes this all looks busy, but it is in TMPFS. Working on separate files
    # and piecing together is easier. UCI order is less constrained.
    cat "$UB_CORE_CONF" >> "$UB_TOTAL_CONF"
    rm  "$UB_CORE_CONF"
  fi

  if [ -n "$UB_CUSTOM_SERVER_CONFIG" ]; then
    {
      echo "# Begin Server custom config from WebUI"
      echo "$UB_CUSTOM_SERVER_CONFIG" | /opt/bin/base64 -d
      echo
      echo "# End Server custom config from WebUI"
    } >> $UB_TOTAL_CONF
  fi

  if [ -s "$UB_SRV_CONF" ] ; then
    {
      # Pull your own "server:" options here
      echo "include: $UB_SRV_CONF"
      echo
    }>> "$UB_TOTAL_CONF"
  fi

  if [ -f "$UB_CTRL_CONF" ] ; then
    # UCI defined control application connection
    cat "$UB_CTRL_CONF" >> "$UB_TOTAL_CONF"
    rm  "$UB_CTRL_CONF"
  fi

  if [ -n "$UB_CUSTOM_EXTEND_CONFIG" ]; then
    {
      echo "# Begin Extended custom config from WebUI"
      echo "$UB_CUSTOM_EXTEND_CONFIG" | /opt/bin/base64 -d
      echo
      echo "# End Extended custom config from WebUI"
    } >> $UB_TOTAL_CONF
  fi

  if [ -s "$UB_EXT_CONF" ] ; then
    {
      # Pull your own extend feature clauses here
      echo "include: $UB_EXT_CONF"
      echo
    } >> "$UB_TOTAL_CONF"
  fi
}

generate_conf() {
  logger -t unbound "Configuring Unbound..."
  cp -p "$UB_TOTAL_CONF" "$UB_TOTAL_CONF".keep
  # get configuration options from Merlin API
  unbound_uci
  # create necessary directories and files
  unbound_mkdir
  # server:
  unbound_conf
  # control:
  unbound_control
  # merge
  unbound_include
  [ -f /jffs/scripts/unbound.postconf ] && . $UB_ADDON_DIR/unbound.postconf "$UB_TOTAL_CONF"
  # check final configuration file for errors, log results in syslog
  if $UB_CHECKCONF "$UB_TOTAL_CONF" 1>/dev/null 2>&1; then
    logger -t unbound "Unbound Configuration complete."
  else
    logger -t unbound "Unbound Configuration errors. Reverting to previous config."
    cp -p "$UB_TOTAL_CONF" "$UB_TOTAL_CONF".bad
    mv -f "$UB_TOTAL_CONF".keep "$UB_TOTAL_CONF"
  fi
}

unbound_mountui() {
  # Does the firmware support addons?
  nvram get rc_support | grep -q am_addons
  if [ $? != 0 ]
  then
      logger "Unbound-UI" "This firmware does not support addons!"
      exit 5
  fi

  if [ ! -f $UB_ADDON_DIR/Unbound.asp ]; then
    logger "Unbound-UI" "WebUI files missing!"
    exit 5
  fi

  # Obtain the first available mount point in $am_webui_page
  am_get_webui_page $UB_ADDON_DIR/Unbound.asp

  if [ "$am_webui_page" = "none" ]
  then
      logger "Unbound-UI" "Unable to install Unbound-UI"
      exit 5
  fi
  logger "Unbound-UI" "Mounting Unbound-UI as $am_webui_page"

  # Copy custom page
  cp $UB_ADDON_DIR/Unbound.asp /www/user/$am_webui_page

  # Copy menuTree (if no other script has done it yet) so we can modify it
  if [ ! -f /tmp/menuTree.js ]
  then
      cp /www/require/modules/menuTree.js /tmp/
      mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
  fi

  if ! /bin/grep "{url: \"$am_webui_page\", tabName: \"Unbound\"}," /tmp/menuTree.js >/dev/null 2>&1; then
    # Insert link at the end of the Tools menu.  Match partial string, since tabname can change between builds (if using an AS tag)
    sed -i "/url: \"Tools_OtherSettings.asp\", tabName:/a {url: \"$am_webui_page\", tabName: \"Unbound\"}," /tmp/menuTree.js
    # sed and binding mounts don't work well together, so remount modified file
    umount /www/require/modules/menuTree.js 2>/dev/null
    mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
  fi
}

unbound_unmountui() {

  # Remove unbound tab from menu. TODO - don't also delete Unbound stats page
  sed -i "\~tabName: \"Unbound\"},~d" /tmp/menuTree.js
  umount /www/require/modules/menuTree.js 2>/dev/null
  if diff /tmp/menuTree.js /www/require/modules/menuTree.js; then
    rm /tmp/menuTree.js
  else
    # Still some modifications from another script so remount
    mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
  fi

  # Does the firmware support addons?
  nvram get rc_support | grep -q am_addons
  if [ $? != 0 ]
  then
      logger "Unbound-UI" "This firmware does not support addons!"
      exit 5
  fi

  if [ ! -f $UB_ADDON_DIR/Unbound.asp ]; then
    logger "Unbound-UI" "WebUI files missing!"
    exit 5
  fi

  am_get_webui_page $UB_ADDON_DIR/Unbound.asp

  if [ "$am_webui_page" = "none" ]
  then
      logger "Unbound-UI" "Unmount: web page not present"
  elif [ -f /www/user/$am_webui_page ]; then
      rm /www/user/$am_webui_page && logger "Unbound-UI" "Unmount: page removed"
  fi
  for i in $(/bin/grep -l UnboundUI-by-dave14305 /www/user/user*.asp 2>/dev/null)
  do
    rm $i
  done

}

dnsmasq_postconf() {
  CONFIG="$1"
  UNBOUNDLISTENADDR="$(am_settings_get unbound_listen_port)"
  if [ -n "$(pidof unbound)" ] && [ -n "$UNBOUNDLISTENADDR" ]; then
        pc_delete "servers-file" "$CONFIG"
        pc_append "server=127.0.0.1#$UNBOUNDLISTENADDR" "$CONFIG"
        pc_replace "cache-size=1500" "cache-size=0" "$CONFIG"
        pc_delete "trust-anchor=" "$CONFIG"
        pc_delete "dnssec" "$CONFIG"
        pc_append "proxy-dnssec" "$CONFIG"
  fi
}

export TZ=$(cat /etc/TZ)
# main
if [ "$#" -ge "1" ]; then
  case "$1" in
    restart)
      if [ "$(am_settings_get unbound_listen_port)" != "$($UB_CHECKCONF -o port)" ]; then
        restart_action="restart"
      fi
      generate_conf
      if [ -n "$(pidof unbound)" ]; then
        if [ $restart_action = "restart" ]; then
          $UB_CONTROL stop
          $UB_CONTROL start
        else
          $UB_CONTROL reload
        fi
      else
        $UB_CONTROL start
      fi
      service restart_dnsmasq
      ;;
    stop)
      $UB_CONTROL stop
      service restart_dnsmasq
      ;;
    mountui)
      unbound_mountui
      ;;
    unmountui)
      unbound_unmountui
      ;;
    dnsmasq_postconf)
      dnsmasq_postconf "$2"
      ;;
    *)
      logger -t unbound "Unrecognized service handler $*"
      ;;
  esac
else
  echo "ERROR: Unbound called without required action parameter."
  exit 1
fi
