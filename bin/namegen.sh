#!/usr/bin/env sh

dict="/usr/share/dict/words"
a=`sed -n "$(shuf -n 1 -i 1-$(wc -l "$dict"|cut -f1 -d ' ')) p" "$dict"`
echo "$a"$((RANDOM))