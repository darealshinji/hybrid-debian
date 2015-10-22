#!/bin/sh

title=$1
pkg_ver=$2

url=http://www.selur.de/sites/default/files/hybrid_downloads/avisynth
zip=avisynthExtension_${pkg_ver}.7z
bin="$HOME/.hybrid-bin"

# check if the 7z file is available
wget -q --spider $url/$zip

if [ $? = 0 ] ; then
    rm -rf "$bin/avisynth" "$bin/avisynthPlugins" "$bin/platforms"
    rm -f "$bin"/*.exe "$bin"/*.dll "$bin"/AVSMeter* "$bin"/*.7z

    mkdir -p "$bin/avisynth"
    cd "$bin/avisynth"

    wget $url/$zip 2>&1 | sed -u 's/^[a-zA-Z\-].*//; s/.* \{1,2\}\([0-9]\{1,3\}\)%.*/\1\n#Downloading... \1%/; s/^20[0-9][0-9].*/#Done./' | \
            zenity --progress \
                   --title="$title" \
                   --text "Wait a few seconds until the donwload is finished ..." \
                   --auto-close

    7z x $zip | zenity --progress \
                   --pulsate \
                   --title="Extract package" \
                   --auto-close

    echo $pkg_ver > "$bin/avisynth/version"
    rm -f $zip

    mv -f "$bin/avisynth/dynamic"/* "$bin"
    mv -f "$bin/avisynth"/*.exe "$bin"
    mv -f "$bin/avisynth"/*.dll "$bin"
    mv -f "$bin/avisynth/AVSMeter.ini" "$bin"
fi

