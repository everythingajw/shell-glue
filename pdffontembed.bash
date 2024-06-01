#!/bin/bash

usage() {
    cat <<EOF
usage: pdffontembed <infile> <outfile>
EOF
    exit 1
}

eecho() {
    echo "$@" >&2
}

if [ "$#" != 2 ]; then
    usage
fi

infile="$1"
outfile="$2"

# ghostscript (at least with the given options) won't crash if the input
# file doesn't exist, so we'll check that ahead of time.
if [ ! -f $infile ]; then
    eecho "No such file $infile"
    exit 1
fi

# https://stackoverflow.com/a/41243959
gs -dNOPAUSE -dBATCH -dNOPLATFONTS -sDEVICE=pdfwrite -dEmbedAllFonts=true -sOutputFile="$outfile" -c '<</NeverEmbed []>> setdistillerparams' -f "$infile"

