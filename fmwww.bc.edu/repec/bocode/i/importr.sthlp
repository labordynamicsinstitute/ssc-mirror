{smcl}
{* May2026}{...}
{hline}
help for {hi:importr}
{hline}

{title:Import R data files into Stata via R or Python}

{p 4 8 2} 
{cmd:importr}
{cmd:using} {it:filename}
[{cmd:,} {cmd:clear} {cmd:rds}]

{title:Description}

{p 4 4 2}
{cmd:importr} (v2.0.2) imports R data files (.Rdata, .Rda, .Rds) into Stata.
R stores these as compressed binary objects in its own serialization format,
so something outside Stata has to do the decoding. {cmd:importr} can use
either of two external routes, so it works on machines with R and on machines
without it.

{title:How it Works}

{p 4 4 2}
{cmd:importr} tries each bridge in turn and keeps whichever one actually
returns a dataset. It reports the bridge that succeeded, so you always know
which route ran.

{p 4 8 2}
1. {cmd:R bridge}: writes a short R script and runs it with {cmd:Rscript},
converting the file through the {cmd:haven} package. {p_end}

{p 4 8 2}
2. {cmd:Python bridge}: if the R bridge does not produce a dataset,
{cmd:importr} falls back to Stata's {help python} integration, reading the
file with {cmd:pyreadr} and writing the .dta with {cmd:pyreadstat}. {p_end}

{p 4 4 2}
{it:Note on R factors.} The two bridges do not encode factors identically.
The R bridge returns a factor as a numeric variable carrying a Stata value
label; the Python bridge returns it as a string variable. Everything else
(integers, doubles, logicals, character) lands the same way either route.
If your do-file depends on a factor's storage type, check it after import
rather than assuming.

{title:Requirements}

{p 4 4 2}
Stata 16 or newer, plus {it:one} of the following.

{p 4 4 2}
For the R bridge:{p_end}
{p 8 12 2} - R installed, with {cmd:Rscript} on the PATH that Stata sees. {p_end}
{p 8 12 2} - R package {cmd:haven}. {p_end}

{p 4 4 2}
For the Python bridge:{p_end}
{p 8 12 2} - Stata's Python integration configured ({stata python query}). {p_end}
{p 8 12 2} - Python libraries {cmd:pyreadr} and {cmd:pyreadstat}. {p_end}
{p 8 12 2} - Install with: {stata python pip install pyreadr pyreadstat} {p_end}

{p 4 4 2}
If R is installed but {cmd:importr} does not find it, the usual cause is that
{cmd:Rscript} is not on the PATH Stata inherits, which need not match the PATH
in your terminal. On macOS an R installed under
{cmd:/Library/Frameworks/R.framework} is a common example.

{title:Files that ship with the package}

{p 4 4 2}
Two small example R files ship with the package,
{cmd:importr_example.rdata} and {cmd:importr_example.rds}, so the examples
below are runnable. They are ancillary files, which {cmd:ssc install importr}
does not copy, so fetch them with {stata net get importr}.

{p 4 4 2}
For conversion work outside Stata, the source repository also carries two
standalone Python utilities, {cmd:RtoStata.py} and {cmd:pythontoR.py}, for
bi-directional conversion between R and Stata formats:
{browse "https://github.com/ericabooth/importR-stata"}.

{title:Options}

{p 4 8 2}
{cmd:clear} clears any data currently in Stata's memory before importing. {p_end}

{p 4 8 2}
{cmd:rds} specifies that the source file is an RDS file. Usually detected 
automatically. {p_end}

{title:Stored results}

{p 4 4 2}
{cmd:importr} stores the following in {cmd:r()}:

{p 4 8 2}{cmd:r(nobs)}     number of observations imported {p_end}
{p 4 8 2}{cmd:r(nvars)}    number of variables imported {p_end}
{p 4 8 2}{cmd:r(filename)} the file that was read {p_end}

{title:Examples}

{p 4 4 2}
The package ships a small example file. Retrieve the ancillary files first
with {stata net get importr}, then run these from the same folder.

{p 4 4 2}Import an R workspace file (tries R first, then Python):{p_end}
{p 8 12 2}{cmd:. importr using "importr_example.rdata", clear}{p_end}
{p 8 12 2}{cmd:. describe}{p_end}
{p 8 12 2}{cmd:. list}{p_end}

{p 4 4 2}Import an RDS file:{p_end}
{p 8 12 2}{cmd:. importr using "importr_example.rds", clear}{p_end}
{p 8 12 2}{cmd:. summarize revenue}{p_end}

{p 4 4 2}Check what was read, without looking at the data:{p_end}
{p 8 12 2}{cmd:. importr using "importr_example.rdata", clear}{p_end}
{p 8 12 2}{cmd:. display r(nobs) " obs, " r(nvars) " vars from " r(filename)}{p_end}

{p 4 4 2}
A file that is not there is reported as such, with return code 601, rather
than as a bridge or library failure:{p_end}
{p 8 12 2}{cmd:. importr using "nosuch.Rdata", clear}{p_end}

{title:Author}

{p 4 4 2}Eric A. Booth{break} 
         eric.a.booth@gmail.com{break}
         {browse "http://www.eric-booth.com"}

{title:Also see}

{p 4 8 2}On-line:  help for {help import}, {help python}, {help shell}
