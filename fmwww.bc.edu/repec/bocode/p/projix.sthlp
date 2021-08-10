{smcl}
{* 16dec2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "html" "html"}{...}
{vieweralsosee "out()" "outopt"}{...}
{vieweralsosee "cdl" "cdl"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:projix} {hline 2} Index of project output files
 
{title:Syntax}

{pmore}{cmd:projix}{space 2}{cmd:define} {p_end}
{pmore}{cmd:projix} [{cmd:compile}] [{cmd:using} {it:{help path_el}}]


{title:Description}

{pstd}{cmd:projix} compiles an index of all output files for a project.
As it stands, "output files" means html files created with the {help outopt:out option} or {help html} command.

{pstd}The index will have one row per project file, and as many columns as you define. A column definition has four parts:

{pmore}1) a heading{p_end}
{pmore}2) cell text{p_end}
{pmore}3) 'tool-tip' text{p_end}
{pmore}4) a flag indicating that clicking on the cell should open the file{p_end}

{pstd}The following functions will produce file-specific info, when included in the cell or tool-tip text:

{pmore}{cmd:meta(}{opt t:itle)}{p_end}
{pmore}{cmd:meta(}{opt r:evision)}{p_end}
{pmore}{cmd:meta(}{opt d:escription)}{p_end}
{pmore}{opt path(start[,stop])}

{pstd}For example, the definition dataset:

{col 10}{cmd:heading}{col 25}{cmd:cell}{col 40}{cmd:tip}{col 55}{cmd:link}
{col 10}{hline 60}
{col 10}Topic{col 25}path(-2,-2)
{col 10}Document{col 25}meta(title){col 40}meta(desc){col 55}1


{pstd}would produce a 2-column index something like the following:

{col 10}{bf:Topic}{col 35}{bf:Document}
{col 10}{hline 40}
{col 10}Important things{col 35}{help The most important thing we ever thought of:Primus}
{col 10}Important things{col 35}{help Another fairly important thing:Secundus}
{col 10}Other things{col 35}{help This thing is not all that important:Another}
{col 10}Other things{col 35}{help This thing is not all that important:A Further}
{col 10}Trivial things{col 35}{help We should get rid of this thing:grit in the gears}

{pstd}Column 1 (headed {cmd:Topic}) would show the name of the directory immediately holding the document;
Column 2 (headed {cmd:Document}) would show the document title from the metadata.
Hovering over a cell in column 2 would bring up a tool-tip with the document description, and clicking on a cell in column 2 would open the document in the browser
(that part isn't functional in this help file of course...).


{title:projix define}

{pstd}{cmd:projix define} creates a dataset to hold the index definition, containing the variables {cmd:heading}, {cmd:cell}, {cmd:tip}, and {cmd:link}.  Add 1 observation to the dataset for each desired column in the index. For {cmd:link}, any non-zero, non-missing value will make that column a clickable link to the file.

{title:projix compile}

{pstd}{cmd:projix compile} creates the index file, in the {help current project directory} using the definition dataset specified, or {cmd:projix.dta} in the {help current project directory} by default.

{title:The functions}

{pstd}The {opt meta()} functions simply replace themselves with the relevant metadata from the document. In particular, {cmd:meta(title)} is the metadata title, not the filename. But the filename can be retrieved with the {cmd:path()} function.

{pstd}The {opt path(start[,stop])} function defines a segment of the entire filepath to display, where {it:start} and {it:stop} are positive or negative integer offsets from the ends of the filepath.

{pstd}For example, following are some functions and their results, using the filepath {cmd:C:\a\b\e\file.ext}.

{p2colset 9 22 22 2}{...}
{p2col:{ul:Function}}{ul:Result}{p_end}
{p2col:{cmd:path(1,2)}}{cmd:C:\a}{p_end}
{p2col:{cmd:path(2)}}{cmd:a\b\e\file.ext}{p_end}
{p2col:{cmd:path(-1)}}{cmd:file.ext}{p_end}
{p2col:{cmd:path(-2)}}{cmd:e\file.ext}{p_end}
{p2col:{cmd:path(-2,-2)}}{cmd:e}{p_end}

