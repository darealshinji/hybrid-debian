#!/bin/sh

pkg_ver=${1}

url=http://www.selur.de/sites/default/files/hybrid_downloads/avisynth
zip=avisynthExtension_${pkg_ver}.7z
bin="$HOME/.hybrid-bin"

# check if the 7z file is available
wget -q --spider $url/$zip

if [ $? = 0 ] ; then
    rm -rf "$bin/avisynth" "$bin/avisynthPlugins" "$bin/platforms"
    rm -f "$bin/*.exe" "$bin/*.dll" "$bin/AVSMeter*" "$bin/*.7z"
    mkdir -p "$bin/avisynth"
    cd "$bin/avisynth"
    wget $url/$zip
    7z x $zip
    echo $pkg_ver > "$bin/avisynth/version"
    rm -f $zip
    mv -f "$bin/avisynth/dynamic"/* "$bin"
    mv -f "$bin/avisynth"/*.exe "$bin"
    mv -f "$bin/avisynth"/*.dll "$bin"
    mv -f "$bin/avisynth/AVSMeter.ini" "$bin"
    # http://forum.selur.de/topic968-linux-hybrid-doesnt-find-avsmeterexe.html
    cp -f "$bin/AVSMeter.exe" "$bin/AVSMeter"
fi

