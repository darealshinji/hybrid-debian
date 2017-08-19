Binaries and sources of the encoding tools are on [Sourceforge](https://sourceforge.net/projects/hybrid-tools/).

Don't use the scripts directly but instead always download the latest version from Github.

Usage examples:

``` sh
#!/bin/sh -e
out=$(tempfile -m 0755 -s '.sh')
wget -c -O $out "https://github.com/darealshinji/hybrid-debian/raw/tools/download.sh"
xterm -T "Update/install Hybrid encoder tools" -e $out
rm $out
```

```sh
#!/bin/sh -e
out=$(tempfile -m 0755 -s '.sh')
wget -c -O $out "https://github.com/darealshinji/hybrid-debian/raw/tools/get-nonfree.sh"
exec $out
rm $out
```
