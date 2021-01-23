#!/usr/bin/env python3
import json
import sys
import os.path

METADIR = "meta"

if len(sys.argv) > 1:
    nb = sys.argv[1]
else:
    print("Usage:\n"+sys.argv[0]+" notebook_uuid")
    sys.exit(13)

prefix = os.path.join(METADIR,nb)

BOOTSTRAP = False
if not os.path.isfile(prefix+"_hashes.json"):
    # Original hashes were not found, so we need to bootstrap
    BOOTSTRAP = True


#Don't worry about indices if we don't have a past reference file
if not BOOTSTRAP:
    try:
        idxdict0 = json.load(open(prefix+"_index.json"))
        idxdictN = json.load(open(prefix+"_index_new.json"))
    except:
        print("Error: index file not found in "+prefix)
        sys.exit(11)

    reidx = False
    startReidx = -1
    for key in idxdict0.keys():
        if key in idxdictN:
            if idxdict0[key] != idxdictN[key]:
                #print(str(idxdict0[key]) + " -> " + str(idxdictN[key]))
                # Pages got renumbered
                reidx = True
                startReidx = idxdict0[key] if idxdict0[key] < idxdictN[key] else idxdictN[key]
                break
        else:
            #A page got deleted
            reidx = True
            startReidx = idxdict0[key]
            break


if BOOTSTRAP or reidx:
    try:
        print
        idxdictN = json.load(open(prefix+"_index_new.json"))
        hashdictN = json.load(open(prefix+"_hashes_new.json"))
    except:
        print("Error: hash or index file not found in "+prefix)
        sys.exit(11)
    for key in hashdictN.keys():
        # we have found the first page where indices differ and will rebuild the OCR following that page
        if idxdictN[key] >= startReidx:
            print(idxdictN[key])
else:
    try:
        hashdict0 = json.load(open(prefix+"_hashes.json"))
        hashdictN = json.load(open(prefix+"_hashes_new.json"))
    except:
        print("Error: hash file not found in "+prefix)
        sys.exit(11)

    for key in hashdictN.keys():
        if key in hashdict0:
            if hashdict0[key] != hashdictN[key]:
                print(idxdictN[key])
        else:
            print(idxdictN[key])
