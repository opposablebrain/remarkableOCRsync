#!/usr/bin/env python3
import json
import hashlib
import sys
import os.path


if len(sys.argv) > 4:
	METADIR = sys.argv[1]
	RMDIR = sys.argv[2]
	nbname = sys.argv[3]
	nb = sys.argv[4]
else:
	print("Usage:\n"+sys.argv[0]+" notebook_name notebook_hash [output_suffix]")
	sys.exit(13)

if len(sys.argv) > 5:
	suffix = sys.argv[5]
else:
	suffix = "";

DIR = os.path.join(RMDIR,nbname,nb)

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
	with open(os.path.join(METADIR,nbname+"_index" + suffix + ".json"), 'w') as out:
		print(json.dumps(idxdict, indent = 2), file=out)

	with open(os.path.join(METADIR+"/"+nbname+"_hashes" + suffix + ".json"), 'w') as out:
		print(json.dumps(hashdict, indent = 2), file=out)

except:
	sys.exit(11)