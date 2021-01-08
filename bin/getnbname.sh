#!/usr/bin/env sh

# arg1 = notebook UUID
if (( $# != 2 )); then
    echo "Usage: $0 notebook_uuid nbdict_file"
    exit 10
fi

SEP=','
nb="$1"
NBDICT="$2"

if grep -sq "$nb" $NBDICT;then
	grep -m1 "$nb" $NBDICT|cut -f2 -d "$SEP"
else
	exit 20
fi
