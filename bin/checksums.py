#!/usr/bin/env python3
import json
import hashlib
import sys
import os.path


if len(sys.argv) > 3:
	METADIR = sys.argv[1]
	RMDIR = sys.argv[2]
	nb = sys.argv[3]
else:
	sys.exit(13)

if len(sys.argv) > 4:
	suffix = sys.argv[4]
else:
	suffix = "";

DIR = os.path.join(RMDIR,nb,nb)

input_file = open(DIR+".content")
json_array = json.load(input_file)
pages=json_array['pages']

hashdict={}
idxdict={}

for pp in range(len(pages)):
	hash = hashlib.md5(open(os.path.join(DIR,pages[pp]+".rm"),'rb').read()).hexdigest()
	hashdict[pages[pp]] = hash
	idxdict[pages[pp]] = pp

try:
	with open(os.path.join(METADIR,nb+"_index" + suffix + ".json"), 'w') as out:
		print(json.dumps(idxdict, indent = 2), file=out)

	with open(os.path.join(METADIR+"/"+nb+"_hashes" + suffix + ".json"), 'w') as out:
		print(json.dumps(hashdict, indent = 2), file=out)

except:
	sys.exit(11)