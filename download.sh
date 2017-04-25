#!/bin/sh

set -e

system="x86_64-linux-gnu"

mkdir -p "$HOME/.hybrid-bin"
cd "$HOME/.hybrid-bin"

rm -f list.txt.new
wget -O list.txt.new "https://raw.githubusercontent.com/darealshinji/hybrid-debian/test/list.txt"
#cp -f "$HOME/Downloads/hybrid-debian/list.txt" list.txt.new

linecount=$(grep '^[A-Za-z]' list.txt.new | wc -l)

for n in `seq 1 $linecount`; do
  line="$(grep '^[A-Za-z]' list.txt.new | sed -n "${n}p")"
  tool=$(echo $line | cut -d' ' -f1)
  version=$(echo $line | cut -d' ' -f2)
  checksum=$(echo $line | cut -d' ' -f3)

  tarball="${tool}-${version}-bin.tar.xz"

  if [ -e list.txt ]; then
    current_version=$(grep "^$tool" list.txt | cut -d' ' -f2)
    oldfiles="$(grep "^$tool" list.txt | awk '{$1=$2=$3=""; print $0}')"
  fi

  missing="false"
  # assume filenames w/o spaces
  for f in $oldfiles; do
    test -e $f || missing="true"
  done

  if [ "x$current_version" != "x$version" -o "$missing" = "true" ]; then
    rm -f $tarball
    wget -q --show-progress "https://sourceforge.net/projects/hybrid-tools/files/$system/$tarball"
    echo "$checksum *$tarball" | sha256sum -c
    rm -f $oldfiles
    tar xf $tarball
    rm -f $tarball
  fi
done

mv -f list.txt.new list.txt

