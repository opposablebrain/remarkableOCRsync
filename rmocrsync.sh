#!/usr/bin/env sh

# These are arbitrary. Pick what you like.
NBDIR=notebooks
DATADIR=rmdata
METADIR=meta

# This is the file where you put the hashes of the RM notebooks, one per line (see README)
NBCONF=notebooks.conf

# Whatever your remarkable is named in .ssh/config (or use the IP)
RMHOST=rm

# Where your content is stored on the tablet, under the root HOME folder
# This should be /home/root/.local/share/remarkable/xochitl; I soft link that to ~/content
RMPATH=content

# Optional flag to automatically commit and push all the content whenever anything changes
# Obviously, you should only do this in your own repo
COMMITNEW=false

# You can prolly leave these alone
RSYNCARGS="-uav --delete --exclude="*.thumbnails" --rsync-path=/opt/bin/rsync"
PGFMT="Letter"

# Eh, on some systems the shell builtin doesn't support advanced options. This is a quick workaround.
ECHO=$(which echo)

mkdir -p $NBDIR $DATADIR $METADIR

for nb in $(cat "$NBCONF"); do
	echo $nb
	$ECHO -n Connecting...

	if timeout 1s ssh $RMHOST "true";then
		echo "success."
	else
		echo "failed. Aborting."
		exit 15
	fi 

	nbname=$(ssh $RMHOST "cat $RMPATH/$nb.metadata" |jq -r .visibleName)
	
	$ECHO -n "Syncing..."
	if rsync $RSYNCARGS -nq "$RMHOST:$RMPATH/$nb*" "$DATADIR/$nbname"; then 
		numtxfr=$(rsync $RSYNCARGS --stats "$RMHOST:$RMPATH/$nb*" "$DATADIR/$nbname"|grep "files transferred"|sed "s/[^[:digit:]]//g")
		echo success. "$numtxfr" files received.
	else
		echo "failed. Aborting."
		exit 13
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
	else
		echo "failed. Aborting."
		exit 14
	fi	
	
	$ECHO -n "Updating page checksums..."
	if ./checksums.py "$METADIR" "$DATADIR" "$nbname" "$nb" "_new"; then
		echo success.
	else
		echo $?
		echo "failed. Aborting."
		exit 17
	fi
	
	echo "Extracting new or updated pages..."
	mkdir -p "$NBDIR/$nbname"_pages
	if ./findnew.py "$nbname" > /dev/null;then 
		for ki in $(./findnew.py "$nbname");do 
			$ECHO -En "   >page-$ki"...
			pagepath="$NBDIR/$nbname"_pages/"page-$ki.png"
			if convert -density 800 -define profile:skip=ICC "$NBDIR/$nbname.pdf[$ki]" -background white -alpha remove "$pagepath"; then
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
			$ECHO -n "   >$ki"...;
			if ./textract.py "$ki" "${ki%.png}.txt";then
				echo success.
			else
				echo $?
				echo "failed. Aborting."
				exit 15
			fi
		done
	fi
	echo "Cleaning up"
	rm -f "$NBDIR/$nbname"_pages/page-*.png
	mv "$METADIR/$nbname"_index_new.json "$METADIR/$nbname"_index.json
	mv "$METADIR/$nbname"_hashes_new.json "$METADIR/$nbname"_hashes.json
	
	if [ "$COMMITNEW" = true ]; then
		# check if need to commit
		if [[ -z $(git status -s) ]];then
			echo No changes
		else 
			echo "Committing changes"
			git pull
			git add notebooks
			git add meta
			git status --porcelain
			git commit -qam "$(date)"
			git push -q
		fi
	fi
done