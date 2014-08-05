#!/bin/sh

QT=$1

URL=http://www.selur.de/sites/default/files/hybrid_downloads
available_ver=$(wget -q -O - $URL/version.txt)

YY=$(echo $available_ver | cut -d'.' -f1 | tail -c+3)
MM=$(echo $available_ver | cut -d'.' -f2)
DD=$(echo $available_ver | cut -d'.' -f3)
_REV=$(echo $available_ver | cut -d'.' -f4)

if [ $_REV != 1 ] ; then
   REV=_$_REV
fi

VER=$YY$MM$DD$REV
BITS=$(getconf LONG_BIT)

ZIP="Hybrid_${VER}_${BITS}bit_binary_qt${QT}.zip"

mkdir -p "$HOME/.hybrid-bin"
cd "$HOME/.hybrid-bin"

# check if the zip is available
wget -q --spider $URL/$ZIP

if [ $? = 0 ] ; then
   mv -f "Hybrid-$QT" "Hybrid-$QT.old"
   rm -f *.zip
   wget $URL/$ZIP
   unzip $ZIP
   mv Hybrid Hybrid-$QT
   chmod 0755 Hybrid-$QT
   rm -f *.zip
fi
