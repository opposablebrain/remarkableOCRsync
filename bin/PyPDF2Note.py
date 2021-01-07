from PyPDF2.generic import (
    DictionaryObject,
    NumberObject,
    FloatObject,
    NameObject,
    TextStringObject,
    ArrayObject
)

def createNote(x1, y1, x2, y2, note, color = [0.71, 0.7, 0.7]):
    newNote = DictionaryObject()

    newNote.update({
        # make note read-only and prevent its deletion (Apple Preview does not honor these, because standards)
        NameObject("/F"): NumberObject(64+128),
        NameObject("/Type"): NameObject("/Annot"),
        NameObject("/Subtype"): NameObject("/Text"),

        NameObject("/Contents"): TextStringObject(note),

        NameObject("/C"): ArrayObject([FloatObject(c) for c in color]),
        NameObject("/Rect"): ArrayObject([
            FloatObject(x1),
            FloatObject(y1),
            FloatObject(x2),
            FloatObject(y2)
        ]),
    })

    return newNote

def addNoteToPage(note, page, output):
    note_ref = output._addObject(note);

    if "/Annots" in page:
        page[NameObject("/Annots")].append(note_ref)
    else:
        page[NameObject("/Annots")] = ArrayObject([note_ref])
