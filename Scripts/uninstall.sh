#!/bin/bash
# SvS.yenidosya kaldırma
DEST=/Applications/SvS.yenidosya.app
pluginkit -e ignore -i com.svs.yenidosya.FinderExtension 2>/dev/null
pluginkit -r "$DEST/Contents/PlugIns/FinderExtension.appex" 2>/dev/null
pkill -x SvS.yenidosya 2>/dev/null
rm -rf "$DEST"
killall Finder 2>/dev/null
echo "SvS.yenidosya kaldırıldı."
