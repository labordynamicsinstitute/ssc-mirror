*--------------------------------------------------------------------*
* editanything_example.do
*
*   Tour of -editanything- usage patterns.  Each block is independent;
*   un-comment the one you want to try.
*
*   . help editanything   // full reference
*--------------------------------------------------------------------*

version 14
clear all


*--------------------------------------------------------------------*
* 1.  Edit a Stata-supplied ado the safe way
*--------------------------------------------------------------------*
*   Just calling -editanything regress- on a base ado is refused;
*   pass -replace- to copy it into PERSONAL first.
*
* editanything regress, replace
* editanything ttest,   replace


*--------------------------------------------------------------------*
* 2.  Render a help file in the Viewer (SMCL)
*--------------------------------------------------------------------*
*   With .sthlp / .hlp / .smcl the markup is rendered;
*   other text shows verbatim.
*
* editanything regress.sthlp, view
* editanything summarize,     view
* editanything analysis.log,  view


*--------------------------------------------------------------------*
* 3.  Edit any non-Stata text file from inside Stata
*--------------------------------------------------------------------*
*   The Do-file Editor is happy with plain text regardless of suffix.
*
* editanything README.md
* editanything pipeline.py
* editanything cleanup.R
* editanything analysis.html
* editanything config/settings.toml
* editanything raw/survey_responses.csv


*--------------------------------------------------------------------*
* 4.  Hand a file off to the OS default app
*--------------------------------------------------------------------*
*   For huge logs, PDFs, spreadsheets, or anything binary.
*
* editanything quarterly_report.pdf, external
* editanything roster.xlsx,          external
* editanything massive_analysis.log, external


*--------------------------------------------------------------------*
* 5.  Spin up a brand-new file and open it
*--------------------------------------------------------------------*
*   Default extension is .ado; override with ext().
*
* editanything new_helper,    new
* editanything project_notes, new ext(md)
* editanything bootstrap,     new ext(do)


*--------------------------------------------------------------------*
* 6.  Look up where a file lives without opening it
*--------------------------------------------------------------------*
*   r(file), r(size), r(extension), r(basename) are returned.
*
* editanything regress, showpath
* display "regress.ado is at: `r(file)'"
* display "size: `r(size)' bytes"


*--------------------------------------------------------------------*
* 7.  Copy a file to the clipboard
*--------------------------------------------------------------------*
*   pbcopy / clip / xclip under the hood -- paste anywhere.
*
* editanything mymodel.do, clipboard


*--------------------------------------------------------------------*
* 8.  Force-edit a base file (NOT recommended)
*--------------------------------------------------------------------*
*   Edits in /ado/base/ get clobbered by `update all`.
*   Prefer -replace- almost always.
*
* editanything regress, force


*--------------------------------------------------------------------*
* 9.  Personal override before community-contributed
*--------------------------------------------------------------------*
*   If you have your own outreg2.ado in PERSONAL, prefer it.
*
* editanything outreg2, personal


*--------------------------------------------------------------------*
* 10. Combine with a custom ext() to skip the .ado fallback
*--------------------------------------------------------------------*
*   ext(md) makes -editanything notes- look for notes.md, not notes.ado.
*
* editanything notes, ext(md)
* editanything todo,  ext(txt)
