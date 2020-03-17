#!/bin/sh

MyAddonDir=/jffs/addons/unboundui

install_unbound() {
  echo "Installing Unbound from Entware..."
  if [ -f /opt/bin/opkg ]; then
    opkg update
    opkg install unbound-daemon unbound-anchor unbound-checkconf unbound-control coreutils-base64 || return 1
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

if [ ! -d $MyAddonDir ]; then
  mkdir -p $MyAddonDir && chmod 755 $MyAddonDir
fi

curl -o $MyAddonDir/Unbound.asp https://raw.githubusercontent.com/dave14305/Unbound-Merlin-UI/master/Unbound.asp
curl -o $MyAddonDir/unbound_service.sh https://raw.githubusercontent.com/dave14305/Unbound-Merlin-UI/master/unbound_service.sh

if [ -f $MyAddonDir/unbound_service.sh ]; then
  chmod 755 $MyAddonDir/unbound_service.sh
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
if ! grep -vE "^#" /jffs/scripts/service-event | grep -qF "sh $MyAddonDir/unbound_service.sh"; then
  cmdline="if [ \"\$2\" = \"unbound\" ]; then sh $MyAddonDir/unbound_service.sh \"\$1\" ; fi # Unbound-UI Addition"
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
if ! grep -vE "^#" /jffs/scripts/services-start | grep -qF "sh $MyAddonDir/unbound_service.sh"; then
  cmdline="sh $MyAddonDir/unbound_service.sh mountui # Unbound-UI Addition"
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
if ! grep -vE "^#" /jffs/scripts/dnsmasq.postconf | grep -qF "sh $MyAddonDir/unbound_service.sh"; then
  cmdline="sh $MyAddonDir/unbound_service.sh dnsmasq_postconf \"\$1\" # Unbound-UI Addition"
  sed -i '\~# Unbound-UI Addition~d' /jffs/scripts/dnsmasq.postconf
  echo "$cmdline" >> /jffs/scripts/dnsmasq.postconf
fi

echo "Enabling Unbound UI..."
. $MyAddonDir/unbound_service.sh mountui
