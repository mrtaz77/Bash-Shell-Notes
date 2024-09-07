touch {old_report,draft}.docx {old_photo,snapshot}.png
mkdir documents images
mv draft.docx final_report.docx
mv *.docx documents
mv *.png images
ls -R .
mkdir archived
mv documents/old* archived
mv images/old* archived