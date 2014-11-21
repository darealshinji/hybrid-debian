#!/bin/sh

QT=$1

URL=http://www.selur.de/sites/default/files/hybrid_downloads
available_ver1=$(wget -q -O - $URL/version.txt)
available_ver2=$(wget -q -O - http://forum.selur.de/feed-rss-topic32.xml | \
perl -ne 'printf qq[%s\n], $1 if m/<strong>([^<]+)<\/strong>/' | head -n1 | cut -d' ' -f3)

available_ver1_np=$(echo $available_ver1 | sed -e 's/\.//g')
available_ver2_np=$(echo $available_ver2 | sed -e 's/\.//g')

if [ $available_ver1_np -gt $available_ver2_np ] ; then
   available_ver=$available_ver2
else
   available_ver=$available_ver1
fi

YY=$(echo $available_ver | cut -d'.' -f1 | tail -c+3)
MM=$(echo $available_ver | cut -d'.' -f2)
DD=$(echo $available_ver | cut -d'.' -f3)
revision=$(echo $available_ver | cut -d'.' -f4)

if [ $revision != 1 ] ; then
   REV=$revision
fi

VER=$YY$MM$DD$REV
BITS=$(getconf LONG_BIT)

ZIP="Hybrid_${VER}_${BITS}bit_binary_qt${QT}.zip"

mkdir -p "$HOME/.hybrid-bin"
cd "$HOME/.hybrid-bin"

# check if the zip is available
wget -q --spider $URL/$ZIP

if [ $? = 0 ] ; then
   test -f "Hybrid-$QT" && mv -f "Hybrid-$QT" "Hybrid-$QT.old"
   rm -f *.zip
   wget $URL/$ZIP
   unzip $ZIP
   mv Hybrid Hybrid-$QT
   chmod 0755 Hybrid-$QT
   rm -f *.zip
fi
