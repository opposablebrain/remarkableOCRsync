#!/usr/bin/env sh

# arg1 = notebook name
# arg2 = destination file

if (( $# != 1 )); then
    echo "Usage: $0 notebook_name"
    exit 10
fi

ECHO=$(which echo)
nbname="$1"
outfile="$2"

#make a fake metadata file for rm2pdf. Ugh.
time=$(($(date +%s%N)/1000000))
ver=$(( RANDOM % 20 + 10))
echo '{'
echo '"lastModified": "'$time'",'
echo '"version": '$ver','
echo '"visibleName": "'$nbname'"'
echo '}'
