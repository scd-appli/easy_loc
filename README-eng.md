# easy_loc

A mobile application that returns which French university libraries (BU) have a book, based on its ISBN/ISSN.

## Features
- Scan ISBN/ISSN barcodes with the camera.
- Scan ISBN/ISSN barcodes from text.
- Google Maps links for libraries possessing the book.
- Dark/Light mode support.
- Language support (French, English)
- History of searched books.
- Export history to CSV, including library count, a list of associated PPNs, and the UNIMARC code 200 (derived from the first PPN of the list).
- Share the history file.

### CSV Export

Use the default (RFC conform) configuration:

    , as field separator
    " as text delimiter and
    \r\n as eol.

Excel  by default use `;` as field separator. So it will give this (it can also have issues with the formatting) :

![Example of incorrect CSV formatting in Excel](assets/example-incorrect-formatting.png)

To correctly use the CSV format in excel follows these steps:
 1. Open Excel and go to the "Data" tab.
 2. Click on "Get Data" or "From Text/CSV".

 ![Excel Data tab with From Text/CSV option highlighted](assets/from-text-csv.png)

 3. Select the CSV file you want to import.
 4. In the import dialog, make sure to set the delimiter to the comma (`,`) et the encoding to unicode UTF-8 and click on load.

 ![Excel import dialog showing comma delimiter selection](assets/delimiter-dialog.png)

 5. Your all set. It should give something like this:

 ![Example of correct CSV formatting in Excel after import](assets/correct-formatting.png)
