{smcl}
{* *! version 1.0  30jan2023}{...}
{viewerjumpto "Syntax" "fragtextab##syntax"}{...}
{viewerjumpto "Description" "fragtextab##description"}{...}
{viewerjumpto "Examples" "fragtextab##examples"}{...}
{viewerjumpto "Author" "fragtextab##author"}{...}
{vieweralsosee "gautils" "help gautils"}{...}
{cmd:help fragtextab}{right: {browse "https://github.com/gaksaray/stata-gautils/"}}
{hline}

{title:Title}

{phang}
{bf:fragtextab} {hline 2} Fragmentize LaTeX tables exported by collect suite of commands


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd: fragtextab} [using {it:{help filename}}[{it:.tex}], {cmd:saving(}{it:filename}[{it:.tex}] [{cmd:,} {opt replace}]{cmd:)} {opt noi:sily}]


{marker description}{...}
{title:Description}

{pstd}
Stata 17 introduced {cmd:collect} suite of commands
({help collect}, {help table}, and {help etable}),
all of which can {help collect export:export} as LaTeX files.
{help collect_export##tex_opttbl:TeX options} include {opt tableonly}
for exporting only the table to the specified file,
which is useful for including the table in a LaTeX document
via {it:\input{}} command.
However, the output includes a {it:table} environment
in addition to the {it:tabular} environment,
which prevents using more advanced LaTeX packages
such as {browse "https://ftp.heanet.ie/mirrors/ctan.org/tex/macros/latex/contrib/threeparttable/threeparttable.pdf":threeparttable}.
There is no option to "fragmentize",
i.e., to suppress the table's opening and closing specifications.

{pstd}
{cmd:fragtextab} does just that!
It essentially takes a .tex file,
and throws everything out except the {it:tabular} section:

{pstd}{it:\begin{tabular}}{p_end}
{pstd}...{p_end}
{pstd}{it:\end{tabular}}{p_end}

{pstd}It is usually run right after {cmd:collect} commands,
although not necessarily.
{cmd:fragtextab} can edit any .tex file specified by {opt using} option
and save to any .tex file specified by {opt saving} option.
File suffixes are optional (.tex is assumed).
If {opt using} option is omitted,
{cmd:fragtextab} assumes that you want to convert the most recent LaTeX table exported.
If {opt saving} option is omitted,
{cmd: fragtextab} assumes that you want to overwrite.
Finally, {opt noisily} option is there
if you want to print out the resulting LaTeX code to Stata console.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse auto, clear}{p_end}
{phang}{cmd:. regress price mpg}{p_end}
{phang}{cmd:. estimates store m1}{p_end}
{phang}{cmd:. etable, est(m1) export(table1.tex, replace)}{it: // full compilable document}{p_end}
{phang}{cmd:. fragtextab}{bind:                                 }{it: // only tabular environment}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Gorkem Aksaray, Trinity College Dublin.{p_end}
{p 4}Email: {browse "mailto:aksarayg@tcd.ie":aksarayg@tcd.ie}{p_end}
{p 4}Personal Website: {browse "https://sites.google.com/site/gorkemak/":sites.google.com/site/gorkemak}{p_end}
{p 4}GitHub: {browse "https://github.com/gaksaray/":github.com/gaksaray}{p_end}
