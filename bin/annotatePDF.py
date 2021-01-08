#!/usr/bin/env python3
from PyPDF2 import PdfFileWriter, PdfFileReader
from PyPDF2Note import createNote, addNoteToPage
import sys
import os.path

if len(sys.argv) < 2:
    print ("Usage:\n" + sys.argv[0] + " notebook_name")
    sys.exit(100);

nbname = sys.argv[1]
notename = "page"
outname = nbname+"_annotated.pdf"

try:
	pdfInput = PdfFileReader(open(nbname+".pdf", "rb"))
except:
	print("Could not open PDF for annotation")
	sys.exit(10)

pdfOutput = PdfFileWriter()

for pageno in range(pdfInput.numPages):

	print("   >page "+str(pageno)+"...", end='')
	
	page = pdfInput.getPage(pageno)

	# Try to read note file for this page
	notefile = os.path.join(nbname+'_pages','page-'+str(pageno)+'.txt')
	notes = ""
	if os.path.exists(notefile):
		try:
			with open(notefile) as f:
			    notes = "\n".join(line.strip() for line in f)
		except:
			print('Found but could not open annotation file for page ' + str(pageno))
			sys.exit(20)
	else:
		print('no note file. ', end='')

	if len(notes) > 0:
		xnote = 0
		ynote = page.mediaBox.getHeight()

		note = createNote(xnote, ynote, 0, 0, notes)

		addNoteToPage(note, page, pdfOutput)
	else:
		print('empty notes. ', end='')

	pdfOutput.addPage(page)
	print('done.')
	
try:
	outputStream = open(outname, "wb")
	pdfOutput.write(outputStream)
except:
	print("Could not open PDF for writing")
	sys.exit(30)
