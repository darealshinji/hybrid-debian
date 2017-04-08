#!/bin/sh

# requires: GNU toolchain, autoreconf, wget, unzip
# optional: upx

echo "Check for tools:"
for cmd in gcc g++ make strip autoreconf wget unzip; do
  printf "  $cmd ==> "
  if [ "$(whereis -b $cmd)" = "${cmd}:" ]; then
    echo "missing"
    exit 1
  else
    echo "found"
  fi
done
echo ""

export CFLAGS="-w -O3 -fstack-protector -D_FORTIFY_SOURCE=2"
export CXXFLAGS="$CFLAGS"
export LDLFAGS="-Wl,-z,relro"

set -e
set -x

mkdir -p "$HOME/.hybrid-bin"
cd "$HOME/.hybrid-bin"

wget="wget -nv --show-progress -c"

# DivX265
$wget -O DivX265 "http://download.divx.com/hevc/DivX265_1_5_8"

# neroAac
$wget "http://ftp6.nero.com/tools/NeroAACCodec-1.5.1.zip"
rm -f neroAacEnc
unzip -j NeroAACCodec-1.5.1.zip linux/neroAacEnc
rm NeroAACCodec-1.5.1.zip

# tsmuxer
$wget -O tsmuxer.tgz 'https://docs.google.com/uc?authuser=0&id=0B0VmPcEZTp8NekJxLUVJRWMwejQ&export=download'
tar xf tsmuxer.tgz ./tsMuxeR
if [ "$(whereis -b upx)" != "upx:" ]; then
  upx -d tsMuxeR
elif [ "$(whereis -b upx-ucl)" != "upx-ucl:" ]; then
  upx-ucl -d tsMuxeR
else
  $wget "https://github.com/upx/upx/releases/download/v3.93/upx-3.93-amd64_linux.tar.xz"
  tar xf upx-3.93-amd64_linux.tar.xz
  upx-3.93-amd64_linux/upx -d tsMuxeR
  rm -rf upx-3.93-amd64_linux*
fi
strip tsMuxeR
rm tsmuxer.tgz

chmod a+x DivX265 neroAacEnc tsMuxeR

# faac
$wget -O faac-1.28+cvs20151130.tar.xz "http://http.debian.net/debian/pool/non-free/f/faac/faac_1.28+cvs20151130.orig.tar.xz"
tar xf faac-1.28+cvs20151130.tar.xz
cd faac-1.28+cvs20151130
autoreconf -if >/dev/null
./configure --disable-shared --with-mp4v2
make -j`nproc` V=0
strip frontend/faac
mv -f frontend/faac ..
cd ..
rm -rf faac-1.28+cvs20151130*

# fdk-aac
$wget -O fdk-aac-0.1.5.tar.gz "https://github.com/mstorsjo/fdk-aac/archive/v0.1.5.tar.gz"
tar xf fdk-aac-0.1.5.tar.gz
cd fdk-aac-0.1.5
autoreconf -if >/dev/null
./configure --disable-shared --enable-example
make -j`nproc` V=0
strip aac-enc
mv -f aac-enc ..
cd ..
rm -rf fdk-aac-0.1.5*

set +x
set +e

echo ""
echo ""
echo "=== check if binaries are working ==="
printf "aac-enc:    "
if [ "$(./aac-enc 2>&1 | head -n1)" = './aac-enc [-r bitrate] [-t aot] [-a afterburner] [-s sbr] [-v vbr] in.wav out.aac' ]; then
  echo "OK"; else echo "FAIL";
fi
printf "DivX265:    "
if [ "$(./DivX265 -h 2>&1 | head -n1)" = 'DivX 265/HEVC Encoder (version 1.5.0.8) 2000-2015 DivX, LLC.' ]; then
  echo "OK"; else echo "FAIL";
fi
printf "faac:       "
if [ "$(./faac --help 2>&1 | head -n1)" = 'Freeware Advanced Audio Coder' ]; then
  echo "OK"; else echo "FAIL";
fi
printf "neroAacEnc: "
if [ "$(./neroAacEnc -help 2>&1 | sed -n '3p')" = '*  Nero AAC Encoder                                         *' ]; then
  echo "OK"; else echo "FAIL";
fi
printf "tsMuxeR:    "
if [ "$(./tsMuxeR | head -n1)" = 'Network Optix tsMuxeR.  Version 2.6.11. www.networkoptix.com' ]; then
  echo "OK"; else echo "FAIL";
fi
echo ""
echo ""

