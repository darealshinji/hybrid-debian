#!/bin/sh

system="x86_64-linux-gnu"

pkgs=$(mktemp --tmpdir='/tmp' --suffix='.txt' packages_XXXXXXXX)
wget -q -O $pkgs "https://raw.githubusercontent.com/darealshinji/hybrid-debian/tools/packages.txt"

dest="$(mktemp --directory --tmpdir="$HOME" hybrid_tools_sources_XXXXXXXX)"
cd "$dest"

linecount=$(grep '^[A-Za-z]' $pkgs | wc -l)

for n in `seq 1 $linecount`; do
  line="$(grep '^[A-Za-z]' $pkgs | sed -n "${n}p")"
  tool=$(echo $line | awk '{print $1}')
  version=$(echo $line | awk '{print $2}')
  if [ "x$version" != "xdeprecated" ]; then
    wget -q --show-progress "https://sourceforge.net/projects/hybrid-tools/files/$system/$tool/${tool}-${version}-src.tar.xz"
  fi
done

echo ""
echo "Source files saved to \`$dest'"

