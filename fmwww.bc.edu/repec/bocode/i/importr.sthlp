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
{cmd:importr} (v2.0.0) provides a robust bridge to import R data files (.Rdata, .Rda, .Rds) 
into Stata. It uses a dual-bridge architecture to ensure compatibility across 
different system environments.

{title:How it Works}

{p 4 4 2}
The command follows a two-step fallback logic:

{p 4 8 2}
1. {cmd:R Bridge}: It first attempts to call {cmd:Rscript}. If found, it uses 
R and the {cmd:haven} package to convert the data. {p_end}

{p 4 8 2}
2. {cmd:Python Bridge}: If R is not found, it attempts to use Stata's internal 
{help python} integration and the {cmd:pyreadstat} library. {p_end}

{title:Standalone Utilities}

{p 4 4 2}
For users working outside of Stata, this package also includes standalone 
Python utilities ({cmd:RtoStata.py} and {cmd:pythontoR.py}) for bi-directional 
conversion between R and Stata formats. See the {cmd:README.md} for details.

{title:Requirements}

{p 4 4 2}
To use the R Bridge (Default):
{p 8 12 2} - R and {cmd:Rscript} must be in your system's PATH. {p_end}
{p 8 12 2} - R package {cmd:haven} must be installed. {p_end}

{p 4 4 2}
To use the Python Bridge (Fallback):
{p 8 12 2} - Stata 16 or newer. {p_end}
{p 8 12 2} - Python library {cmd:pyreadstat} must be installed. {p_end}
{p 8 12 2} - Installation command: {cmd:python pip install pyreadstat} {p_end}

{title:Options}

{p 4 8 2}
{cmd:clear} clears any data currently in Stata's memory before importing. {p_end}

{p 4 8 2}
{cmd:rds} specifies that the source file is an RDS file. Usually detected 
automatically. {p_end}

{title:Examples}

{p 4 4 2}Import an R workspace file (tries R first, then Python):{p_end}
{p 8 12 2}{cmd:. importr using "mydata.Rdata", clear}{p_end}

{p 4 4 2}Import an RDS file:{p_end}
{p 8 12 2}{cmd:. importr using "results.rds", clear}{p_end}

{title:Author}

{p 4 4 2}Eric A. Booth{break} 
         eric.a.booth@gmail.com{break}
         {browse "http://www.eric-booth.com"}

{title:Also see}

{p 4 8 2}On-line:  help for {help import}, {help python}, {help shell}
