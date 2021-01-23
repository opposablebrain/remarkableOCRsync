#!/usr/bin/env sh

if (( $# == 1 )); then
	if [ "$1" == "web" ];then
		WEBSYNC=true
	elif [ "$1" == "ssh" ]; then
		WEBSYNC=false
	fi
else
	echo "Usage:"
	echo "$0 [web|ssh]"
	exit 255
fi

# These are arbitrary. Pick what you like.
NBDIR=notebooks
DATADIR=rmdata
METADIR=meta


# This is the file where you put the hashes of the RM notebooks, one per line (see README)
NBCONF=notebooks.conf

# Whatever your remarkable is named in .ssh/config (or use the IP)
RMHOST=remarkable

# Where your content is stored on the tablet, under the root HOME folder
# This should be /home/root/.local/share/remarkable/xochitl; I soft link that to ~/content
RMPATH=content

# Optional flag to automatically commit and push all the content whenever anything changes
# Obviously, you should only do this in your own repo
COMMITNEW=false

# A temp folder
TMPDIR=tmp

# You can prolly leave these alone
RSYNCARGS="-rtc --delete --exclude=*.lock --exclude=*.thumbnails --exclude=*.textconversion"
RSYNCARGS_SSH="--rsync-path=/opt/bin/rsync"
PGFMT="Letter"

# Eh, on some systems the shell builtin doesn't support advanced options. This is a quick workaround.
ECHO=$(which echo)

mkdir -p $NBDIR $DATADIR $METADIR

if [ "$COMMITNEW" = true ]; then
	echo "=========="
	$ECHO -n Pulling remote...
	if git pull; then
		echo "success."
	else
		echo "failed. Aborting."
		exit 16
	fi
fi

exec 7< "$NBCONF"

while read -u 7 nbname; do
	echo "=========="
	echo
	echo
	echo "=========="
	echo $nbname

	echo "----------"
	
	$ECHO -n "Syncing..."
	if [ "$WEBSYNC" = true ]; then
		if ! ./bin/fetchweb.sh "$nbname" "$TMPDIR"; then
			echo "failed to fetch via web interface. Aborting."
			rm -rf "$TMPDIR"
			exit 20 
		fi
		if rsync $RSYNCARGS -nq "$TMPDIR/"* "$DATADIR/$nbname/"; then
			numtxfr=$(rsync $RSYNCARGS --stats "$TMPDIR/" "$DATADIR/$nbname/"|grep "files transferred"|sed "s/[^[:digit:]]//g")
			echo success. "$numtxfr" files received.
			nb=$(find "$DATADIR/$nbname/" -name "*.content"|cut -f1 -d '.'|sed 's/.*\///g')
			echo "UUID=$nb"
			./bin/genmetadata.sh "$nbname" > "$DATADIR/$nbname/$nb.metadata" # awful. just awful
			rm -rf "$TMPDIR"
		else
			echo "failed. Aborting."
			rm -rf "$TMPDIR"
			exit 33
		fi		
	else
		# This part is a little fragile, since we're not parsing the JSON properly.
		# Also if there are two documents (of any type) with the exact same name, you'll get errors
		if nb=$(ssh rm "grep -r \"\\\"$nbname\\\"\" $RMPATH/*.metadata"|grep "\"visibleName\""|sed 's/.*\/\(.*\)\.metadata.*/\1/');then
			echo "UUID:$nb"
		else
			echo "failed. Aborting. Check that device is SSH-accessible."
			exit 34
		fi

		if rsync $RSYNCARGS $RSYNCARGS_SSH -nq "$RMHOST:$RMPATH/$nb*" "$DATADIR/$nbname"; then
			numtxfr=$(rsync $RSYNCARGS $RSYNCARGS_SSH --stats "$RMHOST:$RMPATH/$nb*" "$DATADIR/$nbname"|grep "files transferred"|sed "s/[^[:digit:]]//g")
			echo success. "$numtxfr" files received.
		else
			echo "failed. Aborting. Check that SSH access is working and that you don't have two documents named \"$nbname\""
			exit 35
		fi
	fi
	
	if [ $numtxfr -eq 0 ];then
		echo No updates. Next notebook...
		continue
	fi

	$ECHO -n "Converting to PDF..."
	convert xc:none -page "$PGFMT" template.pdf
	if rm2pdf -t template.pdf "$DATADIR/$nbname"/$nb "$NBDIR/$nbname.pdf";then
		echo success.
		rm template.pdf
		if [ "$WEBSYNC" = true ]; then
			rm "$DATADIR/$nbname/$nb.metadata" # still terrible
		fi
	else
		echo "failed. Aborting."
		exit 14
	fi	
	

	$ECHO -n "Updating page checksums..."
	if ./bin/checksums.py "$METADIR" "$DATADIR" "$nbname" "$nb" "_new"; then
		echo success.
	else
		echo $?
		echo "failed. Aborting."
		exit 17
	fi
	
	echo "Extracting new or updated pages..."
	mkdir -p "$NBDIR/$nbname"_pages
	if ./bin/findnew.py "$nb" > /dev/null;then 
		for ki in $(./bin/findnew.py "$nb");do 
			$ECHO -En "   >page-$ki"...
			pagepath="$NBDIR/$nbname"_pages/"page-$ki.png"
			if convert -density 500 -define profile:skip=ICC "$NBDIR/$nbname.pdf[$ki]" -background white -alpha remove "$pagepath"; then
				echo success.
			else
				echo "failed. Aborting."
				exit 12
			fi
		done;
	else 
		echo $?
		echo "Error inspecting $nbname indices. Aborting.";
		exit 11
	fi

	if ls "$NBDIR/$nbname"_pages/page-*.png 1> /dev/null 2>&1; then
		echo "OCR..."
		for ki in "$NBDIR/$nbname"_pages/page-*.png; do 
			$ECHO -n "   >${ki%.png}.txt"...;
			if ./bin/textract.py "$ki" "${ki%.png}.txt";then
				echo success.
			else
				echo "failed. Aborting."
				rm -f "$NBDIR/$nbname"_pages/page-*.png
				exit 15
			fi
		done
	fi

	echo "Annotating PDF..."
	if ./bin/annotatePDF.py "$NBDIR/$nbname";then
		echo "success."
		mv "$NBDIR/$nbname"_annotated.pdf "$NBDIR/$nbname.pdf"
	else
		echo "failed. Aborting"
		exit 18
	fi

	echo "Cleaning up"
	rm -f "magick-*"
	rm -f "$NBDIR/$nbname"_pages/page-*.png
	mv "$METADIR/$nb"_index_new.json "$METADIR/$nb"_index.json
	mv "$METADIR/$nb"_hashes_new.json "$METADIR/$nb"_hashes.json
	
	if [ "$COMMITNEW" = true ]; then
		# check if we need to commit anything
		if [[ -z $(git status -s) ]];then
			echo No changes
		else 
			echo "Committing changes"
			git pull
			git add $NBDIR
			git add $METADIR
			git status --porcelain
			msg=$(git status --porcelain|tr -s '\n' ' ')
			git commit -qam "$msg"
			git push -q
		fi
	fi
done
exec 7<&-
echo "=========="
