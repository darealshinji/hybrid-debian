#!/bin/sh

pkg_ver=${1}

url=http://www.selur.de/sites/default/files/hybrid_downloads/avisynth
zip=avisynthExtension_${pkg_ver}.7z
bin="$HOME/.hybrid-bin"

# check if the 7z file is available
wget -q --spider $url/$zip

if [ $? = 0 ] ; then
    rm -rf "$bin/avisynth"
    # old files
    rm -rf "$bin/avisynthPlugins" "$bin/platforms"
    rm -f "$bin/*.exe" "$bin/*.dll" "$bin/AVSMeter.ini" "$bin/avisynthExtension_*.7z"
    mkdir -p "$bin/avisynth"
    cd "$bin/avisynth"
    wget $url/$zip
    7z x $zip
    echo $pkg_ver > "$bin/avisynth/version"
    rm -f "$bin/$zip"
fi

