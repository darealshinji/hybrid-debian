#!/bin/sh

set -e

system="x86_64-linux-gnu"

mkdir -p "$HOME/.hybrid-bin"
cd "$HOME/.hybrid-bin"

rm -f list.txt.new
wget -O list.txt.new "https://raw.githubusercontent.com/darealshinji/hybrid-debian/test/list.txt"

for n in `seq 1 $(cat list.txt.new | wc -l)`; do
  line="$(sed -n "${n}p" list.txt.new)"
  tool=$(echo $line | cut -d' ' -f1)
  version=$(echo $line | cut -d' ' -f2)
  chksum=$(echo $line | cut -d' ' -f3)
  tarball="${tool}-${version}-bin.tar.xz"
  test ! -e list.txt || version_current=$(grep "^$tool" list.txt | cut -d' ' -f2)
  if [ "x$version_current" != "x$version" ]; then
    rm -f $tarball
    wget -nv --show-progress "https://sourceforge.net/projects/hybrid-tools/files/$system/$tarball"
    echo "$chksum *$tarball" | sha256sum -c
    tar xf $tarball
    rm -f $tarball
  fi
done

mv -f list.txt.new list.txt

