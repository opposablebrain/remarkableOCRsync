#!/usr/bin/env python3
import boto3
import sys
import os

SMALL_FILE_BYTES = 50000

if len(sys.argv) < 3:
    print ("Usage:\n" + sys.argv[0] + " input_file output_file")
    sys.exit(100);

# Input
documentName = sys.argv[1]

# Output
outputName = sys.argv[2]

# Read document content
with open(documentName, 'rb') as document:
    imageBytes = bytearray(document.read())

if len(imageBytes) < SMALL_FILE_BYTES:
    print ("input file seems too small to bother...",end='')
    sys.exit(0)

# Amazon Textract client
textract = boto3.client('textract')

# Call Amazon Textract
response = textract.detect_document_text(Document={'Bytes': imageBytes})

# Count total length of text
alltext = ""
for item in response["Blocks"]:
    if item["BlockType"] == "LINE":
        alltext = alltext + item["Text"] + os.linesep

if len(alltext) > 0:
    try:
        # Print detected text
        with open(outputName, 'w') as output:
            print (alltext, file=output)
    except:
        sys.exit(23)
else:
    print("no text detected...",end='')
    try:
        os.remove(outputName) 
    except:
        print(".x.",end='')
