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

# where are we?
UB_LIBDIR=/opt/var/lib/unbound
UB_VARDIR=/opt/var/lib/unbound
UB_PIDFILE=$UB_VARDIR/unbound.pid

# conf deconstructed
UB_TOTAL_CONF=$UB_VARDIR/unbound.conf
UB_CORE_CONF=$UB_VARDIR/server.conf.tmp
UB_CTRL_CONF=$UB_VARDIR/ctrl.conf.tmp
UB_SRV_CONF=$UB_VARDIR/unbound_srv.conf
UB_ZONE_CONF=$UB_VARDIR/zone.conf.tmp
UB_EXT_CONF=$UB_VARDIR/unbound_ext.conf

# TLS keys
UB_TLS_FWD_FILE=$UB_VARDIR/ca-certificates.crt
UB_TLS_ETC_FILE=/etc/ssl/certs/ca-certificates.crt

# start files
UB_RKEY_FILE=$UB_VARDIR/root.key
UB_RHINT_FILE=$UB_VARDIR/root.hints

# control app keys
UB_CTLKEY_FILE=$UB_VARDIR/unbound_control.key
UB_CTLPEM_FILE=$UB_VARDIR/unbound_control.pem
UB_SRVKEY_FILE=$UB_VARDIR/unbound_server.key
UB_SRVPEM_FILE=$UB_VARDIR/unbound_server.pem

# helper apps
UB_ANCHOR=/opt/sbin/unbound-anchor
UB_CONTROL=/opt/sbin/unbound-control
UB_CONTROL_CFG="$UB_CONTROL -c $UB_TOTAL_CONF"

# reset as a combo with UB_B_NTP_BOOT and some time stamp files
UB_B_READY=1

# keep track of assignments during inserted resource records
UB_LIST_INSECURE=""

##############################################################################

. /usr/sbin/helper.sh  # Merlin Add-on helpers

##############################################################################

bundle_domain_insecure() {
  UB_LIST_INSECURE="$UB_LIST_INSECURE $1"
}

##############################################################################

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
  mkdir -p "$UB_VARDIR"
  rm -f "$UB_VARDIR"/dhcp_*
  touch "$UB_TOTAL_CONF"
  cp -p /opt/etc/unbound/* "$UB_VARDIR"/

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

  if [ -f "$UB_CTLKEY_FILE" ] || [ -f "$UB_CTLPEM_FILE" ] \
  || [ -f "$UB_SRVKEY_FILE" ] || [ -f "$UB_SRVPEM_FILE" ] ; then
    # Keys (some) exist already; do not create new ones
    chmod 640 "$UB_CTLKEY_FILE" "$UB_CTLPEM_FILE" \
              "$UB_SRVKEY_FILE" "$UB_SRVPEM_FILE"

  elif [ -x /usr/sbin/unbound-control-setup ] ; then
    case "$UB_D_CONTROL" in
      [2-3])
        # unbound-control-setup for encrypt opt. 2 and 3, but not 4 "static"
        /opt/sbin/unbound-control-setup -d "$UB_VARDIR"

        chown -R nobody:nobody    "$UB_CTLKEY_FILE" "$UB_CTLPEM_FILE" \
                                  "$UB_SRVKEY_FILE" "$UB_SRVPEM_FILE"

        chmod 640 "$UB_CTLKEY_FILE" "$UB_CTLPEM_FILE" \
                  "$UB_SRVKEY_FILE" "$UB_SRVPEM_FILE"

        cp -p "$UB_CTLKEY_FILE" /opt/etc/unbound/unbound_control.key
        cp -p "$UB_CTLPEM_FILE" /opt/etc/unbound/unbound_control.pem
        cp -p "$UB_SRVKEY_FILE" /opt/etc/unbound/unbound_server.key
        cp -p "$UB_SRVPEM_FILE" /opt/etc/unbound/unbound_server.pem
        ;;
    esac
  fi


  if [ "$(nvram get ntp_ready)" -eq "1" ] ; then
    # NTP is done so its like you actually had an RTC
    UB_B_READY=1
    UB_B_NTP_BOOT=0

  else
    # DNSSEC-TIME will not reconcile
    UB_B_READY=0
    UB_B_NTP_BOOT=1
  fi
}

##############################################################################

unbound_control() {
  echo "# $UB_CTRL_CONF generated by UCI $( date -Is )" > "$UB_CTRL_CONF"


  if [ "$UB_D_CONTROL" -gt 1 ] ; then
    if [ ! -f "$UB_CTLKEY_FILE" ] || [ ! -f "$UB_CTLPEM_FILE" ] \
    || [ ! -f "$UB_SRVKEY_FILE" ] || [ ! -f "$UB_SRVPEM_FILE" ] ; then
      # Key files need to be present; if unbound-control-setup was found, then
      # they might have been made during unbound_makedir() above.
      UB_D_CONTROL=0
    fi
  fi


  case "$UB_D_CONTROL" in
    1)
      {
        # Local Host Only Unencrypted Remote Control
        echo "remote-control:"
        echo "  control-enable: yes"
        echo "  control-use-cert: no"
        echo "  control-interface: 127.0.0.1"
        echo "  control-interface: ::1"
        echo
      } >> "$UB_CTRL_CONF"
      ;;

    2)
      {
        # Local Host Only Encrypted Remote Control
        echo "remote-control:"
        echo "  control-enable: yes"
        echo "  control-use-cert: yes"
        echo "  control-interface: 127.0.0.1"
        echo "  control-interface: ::1"
        echo "  server-key-file: $UB_SRVKEY_FILE"
        echo "  server-cert-file: $UB_SRVPEM_FILE"
        echo "  control-key-file: $UB_CTLKEY_FILE"
        echo "  control-cert-file: $UB_CTLPEM_FILE"
        echo
      } >> "$UB_CTRL_CONF"
      ;;

    [3-4])
      {
        # Network Encrypted Remote Control
        # (3) may auto setup and (4) must have static key/pem files
        # TODO: add UCI list for interfaces to bind
        echo "remote-control:"
        echo "  control-enable: yes"
        echo "  control-use-cert: yes"
        echo "  control-interface: 0.0.0.0"
        echo "  control-interface: ::0"
        echo "  server-key-file: $UB_SRVKEY_FILE"
        echo "  server-cert-file: $UB_SRVPEM_FILE"
        echo "  control-key-file: $UB_CTLKEY_FILE"
        echo "  control-cert-file: $UB_CTLPEM_FILE"
        echo
      } >> "$UB_CTRL_CONF"
      ;;
  esac
}

##############################################################################

unbound_conf() {
  local rt_mem rt_conn rt_buff modulestring domain ifsubnet

  {
    # server: for this whole function
    echo "# $UB_CORE_CONF generated by UCI $( date -Is )"
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


  if /opt/sbin/unbound -V | grep -q "Linked libs:.*libevent" ; then
    # heavy variant using "threads" may need substantial resources
    echo "  num-threads: 2" >> "$UB_CORE_CONF"
  else
    # light variant with one "process" is much more efficient with light traffic
    echo "  num-threads: 1" >> "$UB_CORE_CONF"
  fi


  {
    # Limited threading (2) with one shared slab
    echo "  msg-cache-slabs: 1"
    echo "  rrset-cache-slabs: 1"
    echo "  infra-cache-slabs: 1"
    echo "  key-cache-slabs: 1"
    echo
    # Logging
    if [ "$UB_D_LOGDEST" == "syslog" ] ; then
		echo "  use-syslog: yes"
	else
		echo "  logfile: $UB_VARDIR/unbound.log"
	fi
    echo "  log-time-ascii: yes"
    if [ "$UB_D_LOGEXTRA" == "1" ] ; then
		echo "  log-tag-queryreply: yes"
		echo "  log-servfail: yes"
		echo "  log-local-actions: yes"
    fi
    if [ "$UB_B_STATSLOG" == "1" ] ; then
		echo "  statistics-interval: 3600"
	else
		echo "  statistics-interval: 0"
	fi
	echo "  statistics-cumulative: no"
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

  else
    {
      # Log Less
      echo "  extended-statistics: no"
      echo
    } >> "$UB_CORE_CONF"
  fi


  case "$UB_D_PROTOCOL" in
    ip4_only)
      {
        echo "  edns-buffer-size: $UB_N_EDNS_SIZE"
        echo "  port: $UB_N_RX_PORT"
        echo "  outgoing-port-permit: 10240-65535"
        echo "  interface: 127.0.0.1"
        echo "  outgoing-interface: 0.0.0.0"
        echo "  do-ip4: yes"
        echo "  do-ip6: no"
        echo
      } >> "$UB_CORE_CONF"
      ;;

    ip6_prefer)
      {
        echo "  edns-buffer-size: $UB_N_EDNS_SIZE"
        echo "  port: $UB_N_RX_PORT"
        echo "  outgoing-port-permit: 10240-65535"
        echo "  interface: 127.0.0.1"
        echo "  interface: ::1"
        echo "  outgoing-interface: 0.0.0.0"
        echo "  outgoing-interface: ::0"
        echo "  do-ip4: yes"
        echo "  do-ip6: yes"
        echo "  prefer-ip6: yes"
        echo
      } >> "$UB_CORE_CONF"
      ;;

    mixed)
      {
        # Interface Wildcard (access contol handled by "option local_service")
        echo "  edns-buffer-size: $UB_N_EDNS_SIZE"
        echo "  port: $UB_N_RX_PORT"
        echo "  outgoing-port-permit: 10240-65535"
        echo "  interface: 127.0.0.1"
        echo "  interface: ::1"
        echo "  outgoing-interface: 0.0.0.0"
        echo "  outgoing-interface: ::0"
        echo "  do-ip4: yes"
        echo "  do-ip6: yes"
        echo
      } >> "$UB_CORE_CONF"
      ;;

    *)
      if [ "$UB_B_READY" -eq 0 ] ; then
        logger -t unbound -s "default protocol configuration"
      fi


      {
        # outgoing-interface has useful defaults; incoming is localhost though
        echo "  edns-buffer-size: $UB_N_EDNS_SIZE"
        echo "  port: $UB_N_RX_PORT"
        echo "  outgoing-port-permit: 10240-65535"
        echo "  interface: 0.0.0.0"
        echo "  interface: ::0"
        echo
      } >> "$UB_CORE_CONF"
      ;;
  esac


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
      # Other harding and options for an embedded router
      echo "  harden-short-bufsize: yes"
      echo "  harden-large-queries: yes"
      echo "  harden-glue: yes"
      echo "  use-caps-for-id: no"
      echo
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

  elif [ "$UB_B_READY" -eq 0 ] ; then
    logger -t unbound -s "default memory configuration"
  fi


  # Assembly of module-config: options is tricky; order matters
  modulestring="iterator"


  if [ "$UB_B_DNSSEC" -gt 0 ] ; then
    if [ "$UB_B_NTP_BOOT" -gt 0 ] ; then
      # DNSSEC chicken and egg with getting NTP time
      echo "  val-override-date: -1" >> "$UB_CORE_CONF"
    fi


    {
      echo "  harden-dnssec-stripped: yes"
      echo "  val-clean-additional: yes"
      echo "  ignore-cd-flag: yes"
    } >> "$UB_CORE_CONF"


    modulestring="validator $modulestring"
  fi


  if [ "$UB_B_DNS64" -gt 0 ] ; then
    echo "  dns64-prefix: $UB_IP_DNS64" >> "$UB_CORE_CONF"

    modulestring="dns64 $modulestring"
  fi


  {
    # Print final module string
    echo "  module-config: \"$modulestring\""
    echo
  }  >> "$UB_CORE_CONF"


  case "$UB_D_RECURSION" in
    passive)
      {
        # Some query privacy but "strict" will break some servers
        if [ "$UB_B_QRY_MINST" -gt 0 ] && [ "$UB_B_QUERY_MIN" -gt 0 ] ; then
          echo "  qname-minimisation: yes"
          echo "  qname-minimisation-strict: yes"
        elif [ "$UB_B_QUERY_MIN" -gt 0 ] ; then
          echo "  qname-minimisation: yes"
        else
          echo "  qname-minimisation: no"
        fi
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
        # Some query privacy but "strict" will break some servers
        if [ "$UB_B_QRY_MINST" -gt 0 ] && [ "$UB_B_QUERY_MIN" -gt 0 ] ; then
          echo "  qname-minimisation: yes"
          echo "  qname-minimisation-strict: yes"
        elif [ "$UB_B_QUERY_MIN" -gt 0 ] ; then
          echo "  qname-minimisation: yes"
        else
          echo "  qname-minimisation: no"
        fi
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

    *)
      if [ "$UB_B_READY" -eq 0 ] ; then
        logger -t unbound -s "default recursion configuration"
      fi
      ;;
  esac


  {
    # Reload records more than 20 hours old
    # DNSSEC 5 minute bogus cool down before retry
    # Adaptive infrastructure info kept for 15 minutes
    echo "  cache-min-ttl: $UB_TTL_MIN"
    echo "  cache-max-ttl: 72000"
    echo "  val-bogus-ttl: 300"
    echo "  infra-host-ttl: 900"
    echo
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
      echo "  private-address: 100.64.0.0/10"
      echo "  private-address: 169.254.0.0/16"
      echo "  private-address: 172.16.0.0/12"
      echo "  private-address: 192.168.0.0/16"
      echo "  private-address: fc00::/7"
      echo "  private-address: fe80::/10"
      echo
    } >> "$UB_CORE_CONF"
  fi


  if [ "$UB_B_LOCL_BLCK" -gt 0 ] ; then
    {
      # Remove DNS reponses from upstream with loopback IP
      # Black hole DNS method for ad blocking, so consider...
      echo "  private-address: 127.0.0.0/8"
      echo "  private-address: ::1/128"
      echo
    } >> "$UB_CORE_CONF"
  fi


  if  [ -n "$UB_LIST_INSECURE" ] ; then
    {
	  for domain in $(echo $UB_LIST_INSECURE | /opt/bin/base64 -d) ; do
        # Except and accept domains without (DNSSEC); work around broken domains
        echo "  domain-insecure: $domain"
      done
      echo
    } >> "$UB_CORE_CONF"
  fi

  if  [ -n "$UB_LIST_PRIVATE" ] ; then
    {
	  for domain in $(echo $UB_LIST_PRIVATE | /opt/bin/base64 -d) ; do
        # Except and accept domains without (DNSSEC); work around broken domains
        echo "  private-domain: $domain"
      done
      echo
    } >> "$UB_CORE_CONF"
  fi

  # if [ "$UB_B_LOCL_SERV" -gt 0 ] ; then
    # {
      # ifsubnet="$(netstat -rn | grep br0$ | cut -d' ' -f 1)/24"
      # echo "  access-control: ${ifsubnet} allow"
      # echo "  access-control: 127.0.0.0/8 allow"
      # echo "  access-control: ::1/128 allow"
      # echo "  access-control: fe80::/10 allow"
      # echo
    # } >> "$UB_CORE_CONF"

  # else
    # {
      # echo "  access-control: 0.0.0.0/0 allow"
      # echo "  access-control: ::0/0 allow"
      # echo
    # } >> "$UB_CORE_CONF"
  # fi
}

##############################################################################

unbound_uci() {

  UB_D_CONTROL=$(am_settings_get unbound_control); [ -z "$UB_D_CONTROL" ] && UB_D_CONTROL=1
  UB_B_DNSSEC=$(am_settings_get unbound_validator); [ -z "$UB_B_DNSSEC" ] && UB_B_DNSSEC=1
  UB_D_LOGDEST=$(am_settings_get unbound_logdest); [ -z "$UB_D_LOGDEST" ] && UB_D_LOGDEST=syslog
  UB_D_LOGEXTRA=$(am_settings_get unbound_logextra); [ -z "$UB_D_LOGEXTRA" ] && UB_D_LOGEXTRA=0
  UB_D_VERBOSE=$(am_settings_get unbound_verbosity); [ -z "$UB_D_VERBOSE" ] && UB_D_VERBOSE=1
  UB_B_EXT_STATS=$(am_settings_get unbound_extended_stats); [ -z "$UB_B_EXT_STATS" ] && UB_B_EXT_STATS=1
  UB_D_PROTOCOL=$(am_settings_get unbound_protocol); [ -z "$UB_D_PROTOCOL" ] && UB_D_PROTOCOL=ip4_only
  UB_N_EDNS_SIZE=$(am_settings_get unbound_edns_size); [ -z "$UB_N_EDNS_SIZE" ] && UB_N_EDNS_SIZE=1280
  UB_N_RX_PORT=$(am_settings_get unbound_listen_port); [ -z "$UB_N_RX_PORT" ] && UB_N_RX_PORT=53535
  UB_D_RESOURCE=$(am_settings_get unbound_resource); [ -z "$UB_D_RESOURCE" ] && UB_D_RESOURCE=default
  UB_B_DNS64=$(am_settings_get unbound_dns64); [ -z "$UB_B_DNS64" ] && UB_B_DNS64=0
  UB_IP_DNS64=$(am_settings_get unbound_dns64_prefix); [ -z "$UB_IP_DNS64" ] && UB_IP_DNS64=64:ff9b::/96
  UB_D_RECURSION=$(am_settings_get unbound_recursion); [ -z "$UB_D_RECURSION" ] && UB_D_RECURSION=passive
  UB_B_QUERY_MIN=$(am_settings_get unbound_query_minimize); [ -z "$UB_B_QUERY_MIN" ] && UB_B_QUERY_MIN=1
  UB_B_QRY_MINST=$(am_settings_get unbound_query_min_strict); [ -z "$UB_B_QRY_MINST" ] && UB_B_QRY_MINST=0
  UB_B_HIDE_BIND=$(am_settings_get unbound_hide_binddata); [ -z "$UB_B_HIDE_BIND" ] && UB_B_HIDE_BIND=1
  UB_TTL_MIN=$(am_settings_get unbound_ttl_min); [ -z "$UB_TTL_MIN" ] && UB_TTL_MIN=120
  UB_D_PRIV_BLCK=$(am_settings_get unbound_rebind_protection); [ -z "$UB_D_PRIV_BLCK" ] && UB_D_PRIV_BLCK=1
  UB_B_LOCL_BLCK=$(am_settings_get unbound_rebind_localhost); [ -z "$UB_B_LOCL_BLCK" ] && UB_B_LOCL_BLCK=1
#  UB_B_LOCL_SERV=$(am_settings_get unbound_localservice); [ -z "$UB_B_LOCL_SERV" ] && UB_B_LOCL_SERV=1
  UB_LIST_INSECURE="$(am_settings_get unbound_domain_insecure)"
  UB_LIST_PRIVATE="$(am_settings_get unbound_domain_rebindok)"
  UB_B_NTP_BOOT=$(am_settings_get unbound_validator_ntp); [ -z "$UB_B_NTP_BOOT" ] && UB_B_NTP_BOOT=1
  UB_B_STATSLOG=$(am_settings_get unbound_statslog); [ -z "$UB_B_STATSLOG" ] && UB_B_STATSLOG=0
  
  if [ "$UB_N_EDNS_SIZE" -lt 512 ] || [ 4096 -lt "$UB_N_EDNS_SIZE" ] ; then
    logger -t unbound -s "edns_size exceeds range, using default"
    UB_N_EDNS_SIZE=1280
  fi

  if [ "$UB_N_RX_PORT" -ne 53 ] \
  && { [ "$UB_N_RX_PORT" -lt 1024 ] || [ 65535 -lt "$UB_N_RX_PORT" ] ; } ; then
    logger -t unbound -s "privileged port or in 5 digits, using default"
    UB_N_RX_PORT=53535
  fi

  if [ "$UB_TTL_MIN" -gt 1800 ] ; then
    logger -t unbound -s "ttl_min could have had awful side effects, using 300"
    UB_TTL_MIN=300
  fi
}

##############################################################################

unbound_include() {
  echo "# $UB_TOTAL_CONF generated by UCI $( date -Is )" > "$UB_TOTAL_CONF"


  if [ -f "$UB_CORE_CONF" ] ; then
    # Yes this all looks busy, but it is in TMPFS. Working on separate files
    # and piecing together is easier. UCI order is less constrained.
    cat "$UB_CORE_CONF" >> "$UB_TOTAL_CONF"
    rm  "$UB_CORE_CONF"
  fi


  if [ -f "$UB_SRV_CONF" ] ; then
    {
      # Pull your own "server:" options here
      echo "include: $UB_SRV_CONF"
      echo
    }>> "$UB_TOTAL_CONF"
  fi


  if [ -f "$UB_ZONE_CONF" ] ; then
    # UCI defined forward, stub, and auth zones
    cat "$UB_ZONE_CONF" >> "$UB_TOTAL_CONF"
    rm  "$UB_ZONE_CONF"
  fi


  if [ -f "$UB_CTRL_CONF" ] ; then
    # UCI defined control application connection
    cat "$UB_CTRL_CONF" >> "$UB_TOTAL_CONF"
    rm  "$UB_CTRL_CONF"
  fi


  if [ -f "$UB_EXT_CONF" ] ; then
    {
      # Pull your own extend feature clauses here
      echo "include: $UB_EXT_CONF"
      echo
    } >> "$UB_TOTAL_CONF"
  fi
}

##############################################################################
# Main
  logger -t unbound "Configuring Unbound..."
  unbound_uci
  unbound_mkdir
  # server:
  unbound_conf
  # control:
  unbound_control
  # merge
  unbound_include
  logger -t unbound "Unbound Configuration complete."

##############################################################################

