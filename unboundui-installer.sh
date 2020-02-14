#!/bin/sh

MyAddonDir=/jffs/addons/unboundui

if [ ! -f /opt/sbin/unbound ]; then
  echo "Unbound is not installed. Exiting..."
  exit 1
fi

if [ ! -d $MyAddonDir ]; then
  mkdir -p $MyAddonDir && chmod 755 $MyAddonDir
fi

curl -o $MyAddonDir/Unbound.asp https://raw.githubusercontent.com/dave14305/Unbound-Merlin-UI/master/Unbound.asp
curl -o $MyAddonDir/unboundui-enable.sh https://raw.githubusercontent.com/dave14305/Unbound-Merlin-UI/master/unboundui-enable.sh
curl -o $MyAddonDir/unbound_service.sh https://raw.githubusercontent.com/dave14305/Unbound-Merlin-UI/master/unbound_service.sh

[ -f $MyAddonDir/unboundui-enable.sh ] && chmod 755 $MyAddonDir/unboundui-enable.sh || echo "Error downloading enable script!"
[ -f $MyAddonDir/unbound_service.sh ] && chmod 755 $MyAddonDir/unbound_service.sh || echo "Error downloading service script!"

# Borrowed from Adamm00
# https://github.com/Adamm00/IPSet_ASUS/blob/master/firewall.sh#L269
if [ ! -f "/jffs/scripts/service-event" ]; then
    echo "#!/bin/sh" > /jffs/scripts/service-event
    echo >> /jffs/scripts/service-event
elif [ -f "/jffs/scripts/service-event" ] && ! head -1 /jffs/scripts/service-event | grep -qE "^#!/bin/sh"; then
    sed -i '1s~^~#!/bin/sh\n~' /jffs/scripts/service-event
fi
if ! grep -vE "^#" /jffs/scripts/service-event | grep -qF "sh $MyAddonDir/unbound_service.sh"; then
  cmdline="if [ \"\$2\" = \"unbound\" ]; then sh $MyAddonDir/unbound_service.sh \"\$1\" ; fi # Unbound-UI Addition"
  sed -i '\~# Unbound-UI Addition~d' /jffs/scripts/service-event
  echo "$cmdline" >> /jffs/scripts/service-event
fi

. $MyAddonDir/unboundui-enable.sh
