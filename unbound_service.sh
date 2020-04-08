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
UB_INIT_FILE=/opt/etc/init.d/S61unbound

# helper apps
UB_ANCHOR=$UB_BINDIR/unbound-anchor
UB_CONTROL=$UB_BINDIR/unbound-control
UB_CHECKCONF=$UB_BINDIR/unbound-checkconf

# necessary for proper timezone in unbound.log
export TZ=$(cat /etc/TZ)

# Source ASUSWRT-Merlin helper functions
. /usr/sbin/helper.sh

unbound_mkdir() {
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

  # if [ "$(nvram get ntp_ready)" -eq "1" ] ; then
  #   # NTP is done so its like you actually had an RTC
  #   UB_B_NTP_BOOT=0
  # else
  #   # DNSSEC-TIME will not reconcile
  #   UB_B_NTP_BOOT=1
  # fi
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

  {
  # Some query privacy but "strict" will break some servers
  if [ "$UB_B_QUERY_MIN" -gt 0 ] ; then
    echo "  qname-minimisation: yes"
  else
    echo "  qname-minimisation: no"
  fi
  } >> "$UB_CORE_CONF"

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
	  for domain in $(echo "$UB_LIST_INSECURE" | openssl enc -a -d) ; do
        # Except and accept domains without (DNSSEC); work around broken domains
        echo "  domain-insecure: $domain"
      done
      echo
    } >> "$UB_CORE_CONF"
  fi

  if  [ -n "$UB_LIST_PRIVATE" ] ; then
    {
	  for domain in $(echo "$UB_LIST_PRIVATE" | openssl enc -a -d) ; do
        # Except and accept domains without (DNSSEC); work around broken domains
        echo "  private-domain: $domain"
      done
      echo
    } >> "$UB_CORE_CONF"
  fi
}

##############################################################################

unbound_uci() {

  UB_B_ENABLED="$(am_settings_get unbound_enable)"; [ -z "$UB_B_ENABLED" ] && UB_B_ENABLED=1
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
    UB_N_EDNS_SIZE=1280
  fi

  if [ "$UB_N_RX_PORT" -ne 53 ] \
  && { [ "$UB_N_RX_PORT" -lt 1024 ] || [ 65535 -lt "$UB_N_RX_PORT" ] ; } ; then
    UB_N_RX_PORT=5653
  fi

  if [ "$UB_TTL_MIN" -gt 1800 ] ; then
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
      echo "$UB_CUSTOM_SERVER_CONFIG" | openssl enc -a -d
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
      echo "$UB_CUSTOM_EXTEND_CONFIG" | openssl enc -a -d
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
  logger -t "Unbound-UI" "Configuring Unbound..."
  if [ -f "$UB_TOTAL_CONF" ]; then
    cp -p "$UB_TOTAL_CONF" "$UB_TOTAL_CONF".keep
  fi
  # create necessary directories and files
  unbound_mkdir
  # server:
  unbound_conf
  # control:
  unbound_control
  # merge
  unbound_include
  [ -f /jffs/scripts/unbound.postconf ] && sh $UB_ADDON_DIR/unbound.postconf "$UB_TOTAL_CONF"
  # check final configuration file for errors, log results in syslog
  if $UB_CHECKCONF "$UB_TOTAL_CONF" 1>/dev/null 2>&1; then
    logger -t "Unbound-UI" "Unbound Configuration complete."
  else
    logger -t "Unbound-UI" "Unbound Configuration errors. Reverting to previous config."
    cp -p "$UB_TOTAL_CONF" "$UB_TOTAL_CONF".bad
    mv -f "$UB_TOTAL_CONF".keep "$UB_TOTAL_CONF"
  fi
}

unbound_mountui() {
  # Does the firmware support addons?
  if ! nvram get rc_support | grep -q am_addons;
  then
      logger -t "Unbound-UI" "This firmware does not support addons!"
      exit 5
  fi

  if [ ! -f $UB_ADDON_DIR/Unbound.asp ]; then
    logger -t "Unbound-UI" "WebUI files missing!"
    exit 5
  fi

  # Obtain the first available mount point in $am_webui_page
  am_get_webui_page $UB_ADDON_DIR/Unbound.asp

  if [ "$am_webui_page" = "none" ]
  then
      logger -t "Unbound-UI" "Unable to install Unbound-UI"
      exit 5
  fi
  logger -t "Unbound-UI" "Mounting Unbound-UI as $am_webui_page"

  # Copy custom page
  cp $UB_ADDON_DIR/Unbound.asp /www/user/"$am_webui_page"

  if [ "$(uname -o)" = "ASUSWRT-Merlin-LTS" ]; then
    # John's fork
    # Copy state.js (if no other script has done it yet) so we can modify it
    if [ ! -f /tmp/state.js ]
    then
        cp /www/state.js /tmp/
        # fix left-menubar highlighting for Tools menu
        sed -i "/^if(current_url.indexOf(\"cloud\") == 0)/i if(current_url.indexOf(\"user\") == 0)\t/\/\ Unbound-UI Addition\nL1 = 7;\t/\/\ Unbound-UI Addition" /tmp/state.js
        mount -o bind /tmp/state.js /www/state.js
    fi

    if ! /bin/grep "^tablink.*\"$am_webui_page\"" /tmp/state.js >/dev/null 2>&1; then
      # Insert link at the end of the Tools menu.  Match partial string, since tabname can change between builds (if using an AS tag)
      sed -i "s/\(^tabtitle\[12\].*\)\([\).*$]\)/\1, \"Unbound\"\2/" /tmp/state.js
      sed -i "s/\(^tablink\[12\].*\)\([\).*$]\)/\1, \"$am_webui_page\"\2/" /tmp/state.js
      # sed and binding mounts don't work well together, so remount modified file
      umount /www/state.js 2>/dev/null
      mount -o bind /tmp/state.js /www/state.js
    fi
  else
    # Merlin
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
  fi

}

unbound_unmountui() {

  # Does the firmware support addons?
  if ! nvram get rc_support | grep -q am_addons;
  then
      logger -t "Unbound-UI" "This firmware does not support addons!"
      exit 5
  fi

  am_get_webui_page $UB_ADDON_DIR/Unbound.asp

  if [ "$(uname -o)" = "ASUSWRT-Merlin-LTS" ]; then
    # John's fork
    # Remove unbound tab from menu. TODO - don't also delete Unbound stats page
    sed -i "s/\(^tabtitle\[12\].*\)\(, \"Unbound\"\)\(.*$\)/\1\3/" /tmp/state.js
    sed -i "s/\(^tablink\[12\].*\)\(, \"$am_webui_page\"\)\(.*$\)/\1\3/" /tmp/state.js
    sed -i "\~Unbound-UI Addition~d" /tmp/state.js
    umount /www/state.js 2>/dev/null
    if diff /tmp/state.js /www/state.js; then
      rm /tmp/state.js
    else
      # Still some modifications from another script so remount
      mount -o bind /tmp/state.js /www/state.js
    fi
  else
    # Merlin
    # Remove unbound tab from menu. TODO - don't also delete Unbound stats page
    sed -i "\~tabName: \"Unbound\"},~d" /tmp/menuTree.js
    umount /www/require/modules/menuTree.js 2>/dev/null
    if diff /tmp/menuTree.js /www/require/modules/menuTree.js; then
      rm /tmp/menuTree.js
    else
      # Still some modifications from another script so remount
      mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
    fi
  fi

  if [ ! -f $UB_ADDON_DIR/Unbound.asp ]; then
    logger -t "Unbound-UI" "WebUI files missing!"
    exit 5
  fi

  if [ "$am_webui_page" = "none" ]
  then
      logger -t "Unbound-UI" "Unmount: web page not present"
  elif [ -f /www/user/"$am_webui_page" ]; then
      rm /www/user/"$am_webui_page" && logger -t "Unbound-UI" "Unmount: page removed"
  fi
  for i in $(/bin/grep -l UnboundUI-by-dave14305 /www/user/user*.asp 2>/dev/null)
  do
    rm "$i"
  done

}

dnsmasq_postconf() {

  if [ "$UB_B_ENABLED" = "1" ] && [ -n "$UB_N_RX_PORT" ]; then
        pc_delete "servers-file" "$1"
        pc_delete "resolv-file" "$1"  # for John's fork
        pc_delete "server=127.0." "$1"  # to disable other DNS services (e.g. Unbound, dnscrypt-proxy, Stubby)
        pc_append "server=127.0.0.1#$UB_N_RX_PORT" "$1"
        pc_replace "cache-size=1500" "cache-size=0" "$1"
        pc_delete "trust-anchor=" "$1"
        pc_delete "dnssec" "$1"
        pc_append "proxy-dnssec" "$1"
  fi
}

install_unboundui() {
  install_unbound() {
    echo "Installing Unbound from Entware..."
    if [ -f /opt/bin/opkg ]; then
      opkg update
      opkg install unbound-daemon unbound-anchor unbound-checkconf unbound-control || return 1
    else
      echo "Entware not installed. Please install via AMTM."
      return 1
    fi
  }

  if [ ! -f /opt/sbin/unbound ]; then
    echo "Unbound is not installed."
    if install_unbound; then
      echo "Unbound installation successful."
    else
      echo "Unbound installation failed."
      exit 5
    fi
  fi

  if [ ! -d $UB_ADDON_DIR ]; then
    mkdir -p $UB_ADDON_DIR && chmod 755 $UB_ADDON_DIR
  fi

  curl -o $UB_ADDON_DIR/Unbound.asp https://raw.githubusercontent.com/dave14305/Unbound-Merlin-UI/master/Unbound.asp
  curl -o $UB_ADDON_DIR/unbound_service.sh https://raw.githubusercontent.com/dave14305/Unbound-Merlin-UI/master/unbound_service.sh

  if [ -f $UB_ADDON_DIR/unbound_service.sh ]; then
    chmod 755 $UB_ADDON_DIR/unbound_service.sh
  else
    echo "Error downloading service script!"
    exit 5
  fi

  # Borrowed from Adamm00
  # https://github.com/Adamm00/IPSet_ASUS/blob/master/firewall.sh#L269
  if [ ! -f "/jffs/scripts/service-event" ]; then
      echo "#!/bin/sh" > /jffs/scripts/service-event
      echo >> /jffs/scripts/service-event
  elif [ -f "/jffs/scripts/service-event" ] && ! head -1 /jffs/scripts/service-event | grep -qE "^#!/bin/sh"; then
      sed -i '1s~^~#!/bin/sh\n~' /jffs/scripts/service-event
  fi
  if [ ! -x "/jffs/scripts/service-event" ]; then
    chmod 755 /jffs/scripts/service-event
  fi
  if ! grep -vE "^#" /jffs/scripts/service-event | grep -qF "sh $UB_ADDON_DIR/unbound_service.sh"; then
    cmdline="if [ \"\$2\" = \"unbound\" ]; then sh $UB_ADDON_DIR/unbound_service.sh \"\$1\" ; fi # Unbound-UI Addition"
    sed -i '\~# Unbound-UI Addition~d' /jffs/scripts/service-event
    echo "$cmdline" >> /jffs/scripts/service-event
  fi

  if [ ! -f "/jffs/scripts/services-start" ]; then
      echo "#!/bin/sh" > /jffs/scripts/services-start
      echo >> /jffs/scripts/services-start
  elif [ -f "/jffs/scripts/services-start" ] && ! head -1 /jffs/scripts/services-start | grep -qE "^#!/bin/sh"; then
      sed -i '1s~^~#!/bin/sh\n~' /jffs/scripts/services-start
  fi
  if [ ! -x "/jffs/scripts/services-start" ]; then
    chmod 755 /jffs/scripts/services-start
  fi
  if ! grep -vE "^#" /jffs/scripts/services-start | grep -qF "sh $UB_ADDON_DIR/unbound_service.sh"; then
    cmdline="sh $UB_ADDON_DIR/unbound_service.sh mountui # Unbound-UI Addition"
    sed -i '\~# Unbound-UI Addition~d' /jffs/scripts/services-start
    echo "$cmdline" >> /jffs/scripts/services-start
  fi

  if [ ! -f "/jffs/scripts/dnsmasq.postconf" ]; then
      echo "#!/bin/sh" > /jffs/scripts/dnsmasq.postconf
      echo >> /jffs/scripts/dnsmasq.postconf
  elif [ -f "/jffs/scripts/dnsmasq.postconf" ] && ! head -1 /jffs/scripts/dnsmasq.postconf | grep -qE "^#!/bin/sh"; then
      sed -i '1s~^~#!/bin/sh\n~' /jffs/scripts/dnsmasq.postconf
  fi
  if [ ! -x "/jffs/scripts/dnsmasq.postconf" ]; then
    chmod 755 /jffs/scripts/dnsmasq.postconf
  fi
  if ! grep -vE "^#" /jffs/scripts/dnsmasq.postconf | grep -qF "sh $UB_ADDON_DIR/unbound_service.sh"; then
    cmdline="sh $UB_ADDON_DIR/unbound_service.sh dnsmasq_postconf \"\$1\" # Unbound-UI Addition"
    sed -i '\~# Unbound-UI Addition~d' /jffs/scripts/dnsmasq.postconf
    echo "$cmdline" >> /jffs/scripts/dnsmasq.postconf
  fi

  if [ -f "$UB_INIT_FILE" ] && [ ! -f "/opt/etc/init.d/back.S61unbound" ]; then
    cp -p "$UB_INIT_FILE" "/opt/etc/init.d/back.S61unbound"
  fi
  {
    echo "#!/bin/sh"
    echo ""
    echo ". /usr/sbin/helper.sh"
    echo "logger -t Unbound-UI \"Sending \$1 command to Unbound via \$0\""
    echo "export TZ=\$(cat /etc/TZ)"
    echo "if [ \"\$(am_settings_get unbound_enable)\" = \"0\" ]; then"
    echo "  ENABLED=no"
    echo "else"
    echo "  ENABLED=yes"
    echo "fi"
    echo "PROCS=unbound"
    echo "ARGS=\"-c $UB_TOTAL_CONF\""
    echo "PREARGS=\"nohup\""
    echo "PRECMD=\"\""
    echo "POSTCMD=\"service restart_dnsmasq\""
    echo "DESC=\$PROCS"
    echo "PATH=/opt/sbin:/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    echo ""
    echo ". /opt/etc/init.d/rc.func"
    echo ""
    echo "# if time is not synced, allow NTP server names to pass without DNSSEC validation"
    echo "if [ -n \"\$(pidof unbound)\" ] && [ \"\$(nvram get ntp_ready)\" != \"1\" ]; then"
    echo "  [ -n \"\$(nvram get ntp_server0)\" ] && $UB_CONTROL insecure_add \"\$(nvram get ntp_server0)\""
    echo "  [ -n \"\$(nvram get ntp_server1)\" ] && $UB_CONTROL insecure_add \"\$(nvram get ntp_server1)\""
    echo "fi"
  } > $UB_INIT_FILE

  echo "Enabling Unbound UI..."
  sh $UB_ADDON_DIR/unbound_service.sh mountui
  service restart_unbound
  service restart_dnsmasq
}

uninstall_unboundui() {
  echo "Uninstalling Unbound UI..."
  sh $UB_ADDON_DIR/unbound_service.sh unmountui
  if [ -f "/opt/etc/init.d/back.S61unbound" ]; then
    echo -n "Restoring original S61unbound init script..."
    cp -p "/opt/etc/init.d/back.S61unbound" "$UB_INIT_FILE" && echo "done."
  fi
  echo -n "Removing custom script entries..."
  sed -i '\~# Unbound-UI Addition~d' /jffs/scripts/service-event
  sed -i '\~# Unbound-UI Addition~d' /jffs/scripts/services-start
  sed -i '\~# Unbound-UI Addition~d' /jffs/scripts/dnsmasq.postconf
  echo "done."
  echo "Restarting dnsmasq..."
  service restart_dnsmasq
  echo -n "Removing Merlin addon custom settings..."
  sed -i '\~^unbound_~d' /jffs/addons/custom_settings.txt && echo "done."
  echo "Remove Entware Unbound installation? [Y/N]"
  read -r "CONFIRM_REMOVE"
  if [ "$CONFIRM_REMOVE" = "Y" ] || [ "$CONFIRM_REMOVE" = "y" ]; then
    echo "Stopping Unbound..."
    $UB_CONTROL stop
    echo -n "Removing Entware unbound packages..."
    opkg --autoremove remove unbound-anchor unbound-checkconf unbound-control unbound-daemon && echo "done."
    echo -n "Removing Unbound configuration directory..."
    rm -rf $UB_VARDIR && echo "done."
  else
    echo "Leaving Unbound installed."
  fi
  echo -n "Removing addons directory..."
  rm -rf $UB_ADDON_DIR && echo "done."
}

# main
if [ "$#" -ge "1" ]; then
  # get configuration options from Merlin API
  unbound_uci
  case "$1" in
    restart)
      if [ "$UB_B_ENABLED" = "1" ] && [ "$UB_N_RX_PORT" = "$($UB_CHECKCONF -o port)" ]; then
        restart_action="reload"
      fi
      generate_conf
      if [ "$restart_action" = "reload" ]; then
        # Minor config changes handled by a reload
        $UB_CONTROL reload
      else
        # requires a hard stop for port change or disabling
        if [ -n "$(pidof unbound)" ]; then
          # Unbound is already running
          $UB_CONTROL stop
        fi
        if [ "$UB_B_ENABLED" = "1" ]; then
          # only start it again if it's enabled in the GUI
          $UB_CONTROL start
        fi
      fi
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
    install)
      install_unboundui
      ;;
    uninstall)
      uninstall_unboundui
      ;;
    *)
      logger -t "Unbound-UI" "Unrecognized service handler $*"
      ;;
  esac
else
  echo "ERROR: Unbound called without required action parameter."
  exit 1
fi
