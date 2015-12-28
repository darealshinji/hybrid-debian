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
    rm -f $zip
    if [ -d "$bin/avisynthExtension_${pkg_ver}" ]; then
        mv -f "$bin/avisynth/avisynthExtension_${pkg_ver}/dynamic"/* "$bin"
        mv -f "$bin/avisynth/avisynthExtension_${pkg_ver}"/*.exe "$bin"
        mv -f "$bin/avisynth/avisynthExtension_${pkg_ver}"/*.dll "$bin"
        mv -f "$bin/avisynth/avisynthExtension_${pkg_ver}/avisynthPlugins" "$bin/avisynth"
        rm -rf "$bin/avisynth/avisynthExtension_${pkg_ver}"
    else
        mv -f "$bin/avisynth/dynamic"/* "$bin"
        mv -f "$bin/avisynth"/*.exe "$bin"
        mv -f "$bin/avisynth"/*.dll "$bin"
        mv -f "$bin/avisynth/avisynthPlugins" "$bin/avisynth"
    fi
    echo $pkg_ver > "$bin/avisynth/version"
fi

