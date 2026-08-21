{smcl}
{* *! version 3.1.0  03aug2026}{...}
{vieweralsosee "putexcel" "help putexcel"}{...}
{vieweralsosee "putdocx" "help putdocx"}{...}
{vieweralsosee "[D] zipfile" "help zipfile"}{...}
{viewerjumpto "Syntax" "xlimage##syntax"}{...}
{viewerjumpto "Description" "xlimage##description"}{...}
{viewerjumpto "Options" "xlimage##options"}{...}
{viewerjumpto "How it works" "xlimage##how"}{...}
{viewerjumpto "Requirements" "xlimage##req"}{...}
{viewerjumpto "Remarks" "xlimage##remarks"}{...}
{viewerjumpto "Examples" "xlimage##examples"}{...}
{viewerjumpto "Author" "xlimage##author"}{...}
{title:Title}

{phang}
{bf:xlimage} {hline 2} Insert or replace an image in an Excel workbook without
stacking copies and without Python

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xlimage} {cmd:using} {it:workbook.xlsx}{cmd:,}
{opt i:mage(filename)}
{opt c:ell(cellref)}
[{opt sheet(name)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt i:mage(filename)}}image file to place (for example a {cmd:.png}
exported with {helpb graph export}){p_end}
{synopt:{opt c:ell(cellref)}}anchor cell of the image, for example {cmd:A3}{p_end}

{syntab:Optional}
{synopt:{opt sheet(name)}}worksheet holding the image; the first sheet by default{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xlimage} places an image in an Excel workbook at the specified cell. If that
cell does not yet hold an image, the image is {it:inserted}; if one is already
anchored there, it is {it:replaced}. In both cases it avoids the common problem
with {helpb putexcel}, whereby re-running a do-file does not overwrite images but
stacks new copies at the same position, inflating the file with invisible
duplicates.

{pstd}
Because of this, the {it:same} command line can be used on every run: the first
time it inserts and later runs replace, with no duplicated code and no stacked
images. The title, tables, formatting, and other images in the workbook are left
untouched.

{marker options}{...}
{title:Options}

{phang}
{opt image(filename)} is the image to place. Any format Excel supports is
allowed; a {cmd:.png} exported from a Stata graph is the typical case. When an
existing image is replaced, the new image keeps the position and size defined in
the workbook. Required.

{phang}
{opt cell(cellref)} is the cell where the image is anchored (upper-left corner),
for example {cmd:A3}. It is case-insensitive. Required.

{phang}
{opt sheet(name)} selects the worksheet. If omitted, the first sheet of the
workbook is used. Use it when the workbook has several sheets.

{marker how}{...}
{title:How it works}

{pstd}
An {cmd:.xlsx} file is internally a ZIP archive of XML parts. {cmd:xlimage}
unzips it with {helpb unzipfile} and, depending on the case: if an image is
already anchored at the cell, it overwrites only that internal image file
(leaving the rest of the structure untouched); if none is anchored there, it
adds the new anchor to the sheet's existing drawing, or creates the drawing,
relationships, and content-type entry needed to anchor the new image. It then
re-zips the archive with {helpb zipfile}. When an existing image is replaced,
the anchor structure is not rewritten, so the operation cannot corrupt the
workbook.

{pstd}
Both Office anchor kinds ({cmd:oneCellAnchor} and {cmd:twoCellAnchor}) are
recognized, with or without a namespace prefix, as are workbooks with several
sheets and several images per sheet.

{marker req}{...}
{title:Requirements}

{pstd}
Stata 14 or later (for {helpb unzipfile} and {helpb zipfile}). No Python or any
external package is required.

{marker remarks}{...}
{title:Remarks}

{pstd}
The workbook must exist before calling {cmd:xlimage}: the command places images
into a workbook, it does not create the workbook itself. Create it first with
{helpb putexcel} (which handles cells and formatting), then call {cmd:xlimage}
to place the graphs.

{pstd}
The workbook must not be open in Excel while the command runs, because the file
is locked and cannot be rewritten.

{pstd}
This is a beta release, tested with workbooks produced by {helpb putexcel} and
with templates saved by Excel. If a workbook has an unusual drawing structure and
the command does not place the image as expected, please report the case to the
author.

{marker examples}{...}
{title:Examples}

{pstd}Prepare a template with a title and table (preserving its formatting):{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. putexcel set report.xlsx, sheet(Sheet1) modify}{p_end}
{phang2}{cmd:. putexcel A1 = "Price by origin"}{p_end}
{phang2}{cmd:. putexcel save}{p_end}

{pstd}Place the graph: the {it:same} line works every time (inserts the first
time, replaces afterwards):{p_end}
{phang2}{cmd:. graph box price, over(foreign)}{p_end}
{phang2}{cmd:. graph export g.png, replace width(1000)}{p_end}
{phang2}{cmd:. xlimage using report.xlsx, image(g.png) cell(A3) sheet(Sheet1)}{p_end}

{pstd}On a later run with new data, use exactly the same line and the image is
replaced without stacking:{p_end}
{phang2}{cmd:. graph box mpg, over(foreign)}{p_end}
{phang2}{cmd:. graph export g.png, replace width(1000)}{p_end}
{phang2}{cmd:. xlimage using report.xlsx, image(g.png) cell(A3) sheet(Sheet1)}{p_end}

{pstd}Several images on one sheet: each anchor cell is independent, so replacing
one leaves the others in place:{p_end}
{phang2}{cmd:. xlimage using report.xlsx, image(logo.png) cell(A1) sheet(Sheet1)}{p_end}
{phang2}{cmd:. xlimage using report.xlsx, image(g.png)    cell(A20) sheet(Sheet1)}{p_end}

{marker author}{...}
{title:Author}

{pstd}Mario Anderson Apaza {c N~}aupa{p_end}
{pstd}Lima, Peru{p_end}
{pstd}Email: {browse "mailto:rioma310@gmail.com":rioma310@gmail.com}{p_end}
