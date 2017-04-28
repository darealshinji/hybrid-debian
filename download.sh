#!/bin/sh
#set -e

system="x86_64-linux-gnu"

mkdir -p "$HOME/.hybrid-bin"
cd "$HOME/.hybrid-bin"

pkgs="packages.txt"
rm -f ${pkgs}.new
wget -O ${pkgs}.new "https://raw.githubusercontent.com/darealshinji/hybrid-debian/tools/$pkgs"
#cp -f "$HOME/Downloads/hybrid-debian/$pkgs" ${pkgs}.new
test -e $pkgs || cp ${pkgs}.new $pkgs

linecount=$(grep '^[A-Za-z]' ${pkgs}.new | wc -l)

for n in `seq 1 $linecount`; do
  line="$(grep '^[A-Za-z]' ${pkgs}.new | sed -n "${n}p")"
  tool=$(echo $line | awk '{print $1}')
  version=$(echo $line | awk '{print $2}')
  checksum=$(echo $line | awk '{print $3}')

  tarball="${tool}-${version}-bin.tar.xz"

  if [ -e $pkgs ]; then
    current_version=$(grep "^$tool" $pkgs | awk '{print $2}')
    oldfiles="$(grep "^$tool" $pkgs | awk '{$1=$2=$3=""; print $0}')"
  fi

  missing="false"
  # assume filenames w/o spaces
  for f in $oldfiles; do
    test -e $f || missing="true"
  done

  if [ "x$current_version" = "xdropped" ]; then
    rm -f $tarball $oldfiles
  elif [ "x$current_version" != "x$version" -o "$missing" = "true" ]; then
    rm -f $tarball
    wget -q --show-progress "https://sourceforge.net/projects/hybrid-tools/files/$system/$tool/$tarball"
    echo "$checksum *$tarball" | sha256sum -c
    rm -f $oldfiles
    tar xf $tarball
    rm -f $tarball
  fi
done

mv -f ${pkgs}.new $pkgs

