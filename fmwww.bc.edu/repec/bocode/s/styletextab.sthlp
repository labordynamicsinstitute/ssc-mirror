{smcl}
{* *! version 1.1  07jul2023}{...}
{viewerjumpto "Syntax" "styletextab##syntax"}{...}
{viewerjumpto "Description" "styletextab##description"}{...}
{viewerjumpto "Options" "styletextab##options"}{...}
{viewerjumpto "Remarks" "styletextab##remarks"}{...}
{viewerjumpto "Examples" "styletextab##examples"}{...}
{viewerjumpto "Author" "styletextab##author"}{...}
{vieweralsosee "gautils" "help gautils"}{...}
{cmd:help styletextab}{right: {browse "https://github.com/gaksaray/stata-gautils/"}}
{hline}

{title:Title}

{phang}
{bf:styletextab} {hline 2} Restyle LaTeX tables exported by the collect suite of commands


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd: styletextab}
[{cmd:using} {it:{help filename}}]
[{cmd:,} {cmd:saving(}{it:filename} [{cmd:,} {opt replace}]{cmd:)} {it:options}]

{synoptset 21}{...}
{synopthdr}
{synoptline}
{synopt:{opt frag:ment}}keep only LaTeX {it:tabular} environment{p_end}
{synopt:{opt table:only}}keep only LaTeX {it:table} environment{p_end}
{synopt:[{cmd:no}]{opt book:tabs}}specify whether to use LaTeX booktabs rules (default is {opt booktabs}){p_end}
{synopt:{opt lab:el}{cmd:(}{it:marker}{cmd:)}}label the table for cross-referencing{p_end}
{synopt:{opt ls:cape}}wrap the table in a LaTeX {it:landscape} environment{p_end}
{synopt:{opt geometry}[{cmd:(}{it:pkgopts}{cmd:)}]}load LaTeX geometry package to customize page layout{p_end}
{synopt:{opt lipsum}[{cmd:(}{it:pkgopts}{cmd:)}]}load LaTeX lipsum package to produce dummy text{p_end}
{synopt:{opt before:text}{cmd:(}{it:string}{cmd:)}}add text before table{p_end}
{synopt:{opt after:text}{cmd:(}{it:string}{cmd:)}}add text after table{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:styletextab} improves the appearance and formatting of default LaTeX tables
exported by the {cmd:collect} suite of commands.
It integrates advanced LaTeX packages such as
{browse "https://ftp.heanet.ie/mirrors/ctan.org/tex/macros/latex/contrib/booktabs/booktabs.pdf":booktabs} (for better vertical spacing around horizontal rules),
{browse "https://ftp.heanet.ie/mirrors/ctan.org/tex/macros/latex/contrib/threeparttable/threeparttable.pdf":threeparttable} (for refined formatting of table notes), and
{browse "https://ftp.heanet.ie/mirrors/ctan.org/tex/macros/latex/contrib/pdflscape/pdflscape.pdf":pdflscape} (for landscape tables accommodating wider data displays).

{pstd}
Typically, {cmd:styletextab} is executed immediately after {cmd:collect} exports.
However, it can also be applied to any .tex file specified by the {opt using} option.
It can save the output to any .tex file specified by the {opt saving()} option.
The file suffixes are optional, as .tex is assumed by default.
If the {opt using} option is not provided,
{cmd:styletextab} assumes the intention to modify the most recently exported LaTeX table.
Similarly, if the {opt saving()} option is omitted,
{cmd: styletextab} assumes the intention to overwrite the original file.


{marker options}{...}
{title:Options}

{phang}
{cmd:tableonly} keeps the {it:table} section only (and discards the rest):

{p 8 8 2} {it:\begin{tabular}} {p_end}
{p 8 8 2} ... {p_end}
{p 8 8 2} {it:\end{tabular}} {p_end}

{p 8 8 2} The resulting .tex file can be included in a LaTeX document via {bf:\input} macro.

{phang}
{cmd:fragment} keeps the {it:tabular} section only (and discards the rest):

{p 8 8 2} {it:\begin{table}[!h]} {p_end}
{p 8 8 2} ... {p_end}
{p 8 8 2} {it:\end{table}} {p_end}

{p 8 8 2} The resulting .tex file can be manually wrapped inside a custom {it:table} environment in a LaTeX document via {bf:\input} macro. {p_end}

{phang}
[{cmd:no}]{cmd:booktabs} replaces the default {bf:\cline} with the {bf:\cmidrule} macro from LaTeX's {bf:booktabs} package.

{phang}
{cmd:label(}{it:marker}{cmd:)} adds an additional line right after {bf:\caption} with {bf:\label} macro specifying the label marker for the table. This is used for cross-referencing the table within a LaTeX document.

{phang}
{cmd:lscape} invokes LaTeX's {bf:pdflscape} package to wrap the table in a landscape layout. This makes it easier to view tables that are too wide to fit in a portait page (for example, regression comparison tables with more than 5-6 models).

{phang}
{cmd:geometry}[{cmd:(}{it:pkgopts}{cmd:)}] invokes LaTeX's
{browse "https://ftp.heanet.ie/mirrors/ctan.org/tex/macros/latex/contrib/geometry/geometry.pdf":geometry}
package to customize page layout.
The default is to insert {bf:geometry} package by itself without any option. Alternatively, use {it:pkgopts} to specify package options.

{phang}
{cmd:lipsum}[{cmd:(}{it:pkgopts}{cmd:)}] invokes LaTeX's
{browse "https://ftp.heanet.ie/mirrors/ctan.org/tex/macros/latex/contrib/lipsum/lipsum.pdf":lipsum}
package to produce dummy text in {opt beforetext()} and {opt aftertext()}.
This is useful for simulating content around a table to visualize how it would appear within a document.
The default is to insert {bf:lipsum} package by itself without any option. Alternatively, use {it:pkgopts} to specify package options.

{phang}
{cmd:beforetext(}string{cmd:)} and {cmd:aftertext(}string{cmd:)}
add the text {it:string} before and after the table
(relevant only if {opt fragment} and {opt tableonly} options are omitted).
{cmd:beforetext()} and {cmd:aftertext()} may be repeated
to add multiple paragraphs separated by an empty line.


{marker remarks}{...}
{title:Remarks}

{pstd}
Stata 17 introduced the {cmd:collect} suite of commands
({help collect}, {help table}, {help etable}, and, as of version 18, {help dtable}),
all of which can {help collect export:export} tables as LaTeX files.
By default, the output is a standalone compilable document.
{help collect_export##tex_opttbl:TeX export options} include {opt tableonly}
for exporting only the {it:table} environment,
which can be included in a LaTeX document using the {bf:\input} macro.
Additionally, {help collect_style_tex##syntax:TeX style options} include
{opt begintable} for specifying whether to use the {it:table} environment
or retain only the tabular environment,
and {opt centering} for specifying whether to center table horizontally
on the page using the {bf:\centering} macro.
Although it is possible to produce a fragment (i.e., {it:tabular}-only) table
and wrap it in a custom table environment in a separate document,
the default standalone document mode is convenient for
quickly assessing the appearance of the LaTeX tables.

{pstd}
However, the default output of the {cmd:collect} suite of commands
has several basic visual imperfections:
horizontal lines are drawn by {bf:\cline},
footnotes are centered by default and do not have the same width as the table,
and there is no option to rotate the table.
{cmd:styletextab}, by default, addresses these issues.
It replaces {bf:\cline} with the {bf:\cmidrule} of the
{browse "https://ftp.heanet.ie/mirrors/ctan.org/tex/macros/latex/contrib/booktabs/booktabs.pdf":booktabs} package for aesthetically pleasing vertical spacing.
It also wraps footnotes within the {bf:\tablenotes} environment of the
{browse "https://ftp.heanet.ie/mirrors/ctan.org/tex/macros/latex/contrib/threeparttable/threeparttable.pdf":threeparttable} package for proper formatting.
Additionally, {cmd:styletextab} offers an option to rotate tables
(i.e., switch to landscape layout)
by wrapping tables within the {bf:\landscape} environment of
{browse "https://ftp.heanet.ie/mirrors/ctan.org/tex/macros/latex/contrib/pdflscape/pdflscape.pdf":pdflscape} package.

{pstd}
{cmd:styletextab} operates by dissecting a .tex table file into its constituent sections
and utilizing {help file} commands to reformat and improve the look of the tables.
An advantage of {cmd:styletextab} is its ability to transition seamlessly between
different modes without the need to recreate the table from scratch.


{marker examples}{...}
{title:Examples}

{pstd}Export a collect table as .tex file:{p_end}
{phang}{cmd:. sysuse auto, clear}{p_end}
{phang}{cmd:. regress price mpg}{p_end}
{phang}{cmd:. estimates store m1}{p_end}
{phang}{cmd:. regress price mpg i.foreign}{p_end}
{phang}{cmd:. estimates store m2}{p_end}
{phang}{cmd:. etable, estimates(m1 m2) mstat(N) column(index) ///}{p_end}
{phang}{cmd:> {space 4}showstars showstarsnote{space 20} ///}{p_end}
{phang}{cmd:> {space 4}title("Table title"){space 24}///}{p_end}
{phang}{cmd:> {space 4}note("Note: Table notes go here."){space 10}///}{p_end}
{phang}{cmd:> {space 4}export(mytable.tex, replace)}{p_end}

{pstd}Restyle with default settings (booktabs + threeparttable):{p_end}
{phang}{cmd:. styletextab} {p_end}

{pstd}Switch to landscape and save it as a different file:{p_end}
{phang}{cmd:. styletextab using mytable, saving(mytable_lscape) lscape}{p_end}

{pstd}Add a label marker and some text before and after the table:{p_end}
{phang}{cmd:. styletextab, {space 41} ///}{p_end}
{phang}{cmd:> {space 4}label(fig:reg1){space 35} ///}{p_end}
{phang}{cmd:> {space 4}before(Table~\ref{fig:reg1} presents regressions.) ///}{p_end}
{phang}{cmd:> {space 4}after(This text comes after Table~\ref{fig:reg1}.)}{p_end}

{pstd}Add multiple paragraphs of text and increase page margins:{p_end}
{phang}{cmd:. styletextab, {space 52} ///}{p_end}
{phang}{cmd:> {space 4}label(fig:reg1){space 46} ///}{p_end}
{phang}{cmd:> {space 4}geometry(margin=1in){space 41} ///}{p_end}
{phang}{cmd:> {space 4}lipsum(auto-lang=true){space 39} ///}{p_end}
{phang}{cmd:> {space 4}before(\section*{Regression models}){space 25} ///}{p_end}
{phang}{cmd:> {space 4}before(Table~\ref{fig:reg1} presents regressions.{space 12} ///}{p_end}
{phang}{cmd:> {space 11}These regressions are very interesting. \lipsum[1]){space 3} ///}{p_end}
{phang}{cmd:> {space 4}before(Let's see how they look:){space 29} ///}{p_end}
{phang}{cmd:> {space 4}after(This text comes after Table~\ref{fig:reg1}. \lipsum[2]) ///}{p_end}
{phang}{cmd:> {space 4}after(\lipsum[3])}{p_end}

{pstd}Keep the {it:table} environment only:{p_end}
{phang}{cmd:. styletextab, tableonly}{p_end}
{pstd}{it:(going back to the standalone document format from mytable.tex would retain the caption and footnotes)}

{pstd}Keep the {it:tabular} environment only:{p_end}
{phang}{cmd:. styletextab, fragment}{space 1}{p_end}
{pstd}{it:(going back to the standalone document format from mytable.tex would discard the caption and footnotes)}


{marker author}{...}
{title:Author}

{pstd}
Gorkem Aksaray, Trinity College Dublin.{p_end}
{p 4}Email: {browse "mailto:aksarayg@tcd.ie":aksarayg@tcd.ie}{p_end}
{p 4}Personal Website: {browse "https://sites.google.com/site/gorkemak/":sites.google.com/site/gorkemak}{p_end}
{p 4}GitHub: {browse "https://github.com/gaksaray/":github.com/gaksaray}{p_end}
