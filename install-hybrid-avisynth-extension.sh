#!/bin/sh

ver_url=https://raw.githubusercontent.com/darealshinji/hybrid-debian/avisynth-extension/version
pkg_ver=$(wget -O - $ver_url)

url=http://www.selur.de/sites/default/files/hybrid_downloads/avisynth
zip=avisynthExtension_${pkg_ver}.7z
bin="$HOME/.hybrid-bin"

# check if the 7z file is available
wget -q --spider $url/$zip

if [ $? = 0 ] ; then
    mkdir -p "$bin"
    rm -rf "$bin/avisynthPlugins" "$bin/dynamic" "$bin/platforms"
    rm -f "$bin/*.exe" "$bin/*.dll" "$bin/AVSMeter.ini" "$bin/avisynthExtension_*.7z"
    cd "$bin"
    wget $url/$zip
    7z x $zip
    echo $pkg_ver > "$bin/avisynthPlugins/version"
    rm -f "$bin/$zip"
fi

