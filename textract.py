#!/usr/bin/env python3
import boto3
import sys

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
    print ("Input file seems too small to bother")
    sys.exit(0)

# Amazon Textract client
textract = boto3.client('textract')

# Call Amazon Textract
response = textract.detect_document_text(Document={'Bytes': imageBytes})

try:
    # Print detected text
    with open(outputName, 'w') as output:
        for item in response["Blocks"]:
            if item["BlockType"] == "LINE":
                print (item["Text"], file=output)
except:
    sys.exit(23)