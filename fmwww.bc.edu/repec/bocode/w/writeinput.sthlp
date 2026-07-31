{smcl}
{* May2026}{...}
{hline}
help for {hi:writeinput}
{hline}

{title:Advanced dataset-to-input command generator}

{p 4 8 2} 
{cmd:writeinput}
{it:varlist} 
[{cmd:if} {it:exp}] 
[{cmd:in} {it:range}] 
[{cmd:using} {it:newfile}]
[{cmd:,} 
{cmdab:rep:lace} 
{cmd:append}
{cmdab:nocl:ear} 
{cmdab:n:ote(}{it:string}{cmd:)}
{cmd:header(}{it:string}{cmd:)}
{cmd:labels}
{cmd:dates}
{cmd:dryrun}
{cmd:markdown}
{cmd:precision(}{it:str}{cmd:)}
{cmd:maxobs(}{it:#}{cmd:)}
{cmd:sort(}{it:varlist}{cmd:)}
{cmd:sample(}{it:#}{cmd:)}
{cmd:seed(}{it:#}{cmd:)}
{cmd:varlab}
{cmd:generic}
{cmd:frame(}{it:name}{cmd:)}]

{title:Description}

{p 4 4 2}
{cmd:writeinput} (v3.0.1) is a robust utility for generating reproducible Stata
{help input} code from data currently in memory. It is specifically designed to 
facilitate sharing "Minimum Working Examples" (MWEs) on forums like Statalist 
or technical support emails.

{p 4 4 2}
Compared to version 1.x and 2.x, this version adds significant intelligence 
regarding data precision (hexadecimal support), extended missing values (.a-.z), 
and modern Stata 16+ features like {help frames}.

{title:Robustness & Correctness Options}

{p 4 8 2}
{cmd:precision(}{it:str}{cmd:)} controls numeric precision. Use {cmd:precision(hex)} 
to write {cmd:double} variables in hexadecimal format (`%21x`), ensuring 
bit-for-bit exactness when the data is re-read. You can also pass standard 
formats like {cmd:precision(%20.0g)}. {p_end}

{p 4 8 2}
{it:Extended Missings}: The command automatically detects and preserves 
extended missing values (.a, .b, ..., .z). {p_end}

{p 4 8 2}
{it:String Escaping}: All string values are automatically wrapped in 
{help res_unquoted:compound double quotes} (`` `" "' ``), making the output 
immune to corruption from internal double quotes or backticks. {p_end}

{title:Feature Options}

{p 4 8 2}
{cmd:maxobs(}{it:#}{cmd:)} caps the number of rows written (default 500). 
Set to 0 to disable the limit. This prevents accidental massive file creation. {p_end}

{p 4 8 2}
{cmd:varlab} embeds variable labels as comments directly above the {cmd:input} line. {p_end}

{p 4 8 2}
{cmd:sort(}{it:varlist}{cmd:)} sorts the observations by the specified variables 
before writing, ensuring a consistent and logical order. {p_end}

{p 4 8 2}
{cmd:sample(}{it:#}{cmd:)} and {cmd:seed(}{it:#}{cmd:)} allow you to write a 
randomly drawn, reproducible subset of your data. {p_end}

{p 4 8 2}
{cmd:generic} renames all output variables to v1, v2, ... to anonymize the 
data structure while preserving the underlying logic. {p_end}

{p 4 8 2}
{cmd:markdown} wraps the results window output in a fenced code block with 
Stata syntax highlighting, ready for pasting into GitHub or Stack Overflow. {p_end}

{p 4 8 2}
{cmd:frame(}{it:name}{cmd:)} allows you to pull data from a specific Stata 16+ 
frame without leaving your current workspace. {p_end}

{p 4 8 2}
{cmd:append} allows adding the generated code to the end of an existing file. {p_end}

{title:Examples}

{p 4 4 2}High-precision export for technical support:{p_end}
{p 8 12 2}{cmd:. writeinput mpg price weight, precision(hex) dryrun}{p_end}

{p 4 4 2}Create an anonymized, sorted random sample for a forum post:{p_end}
{p 8 12 2}{cmd:. writeinput age inc race, sample(20) seed(123) sort(age) generic markdown}{p_end}

{p 4 4 2}Include variable metadata and a project header:{p_end}
{p 8 12 2}{cmd:. writeinput *, varlab header("** Project X | Date: $S_DATE") dryrun}{p_end}

{title:Returned Values}

{p 4 8 2}The command returns the following in {cmd:r()}: {p_end}
{synoptset 15 tabbed}{...}
{synopt:{cmd:r(filename)}}The path to the created file{p_end}
{synopt:{cmd:r(nobs)}}Number of observations written{p_end}
{synopt:{cmd:r(nvars)}}Number of variables written{p_end}
{synopt:{cmd:r(varlist)}}The list of variables written{p_end}
{synopt:{cmd:r(truncated)}}1 if maxobs was reached, 0 otherwise{p_end}

{title:Author}

{p 4 4 2}Eric A. Booth{break} 
         eric.a.booth@gmail.com{break}
         {browse "http://www.eric-booth.com"}

{title:Also see}

{p 4 8 2}On-line:  help for {help input}, {help dataex}, {help frames}
