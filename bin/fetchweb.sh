#!/usr/bin/env sh

# arg1 = notebook UUID
# arg2 = dest folder
if (( $# != 2 )); then
    echo "Usage: $0 notebook_uuid dest_folder"
    exit 10
fi

ZIPDIR="$2"
nb="$1"
zipdest="$ZIPDIR/$nb.zip"

ECHO=$(which echo)

mkdir -p "$ZIPDIR"

$ECHO -n "Fetching notebook..."
if ./remarkable.php download -u "$1" "$zipdest";then
	echo "success."
else
	echo "failed. Aborting."
	exit 20
fi

$ECHO -n "Unpacking..."
if unzip -o -qq "$zipdest" -d "$ZIPDIR";then
	echo "success."
	rm "$zipdest"
else
	echo "failed. Aborting."
	exit 30
fi

# The web interface is weird and sometimes just numbers the page files 0.rm, 1.rm, 2.rm instead of naming them [uuid].rm 
# It also sometimes fails to provide metadata files for pages. Meh.
if [ -f "$ZIPDIR/$nb/0.rm" ]; then
	$ECHO -n "Normalizing..."
	numpages=$(cat "$ZIPDIR/$nb.content"|jq -r .pageCount)
	for ki in $(seq 0 $(( $numpages - 1 )));do
		pageID=$(cat "$ZIPDIR/$nb.content"|jq -r .pages\[$ki\])
		mv "$ZIPDIR/$nb/$ki.rm" "$ZIPDIR/$nb/$pageID.rm"
		mv "$ZIPDIR/$nb/$ki-metadata.json" "$ZIPDIR/$nb/$pageID-metadata.json" 2>/dev/null
	done
	echo "done"
fi