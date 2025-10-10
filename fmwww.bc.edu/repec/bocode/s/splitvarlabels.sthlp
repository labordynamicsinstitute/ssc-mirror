{smcl}
{* *! touched NJC 26sep2025}{...}
{* *! version 1.2.1  08oct2025}{...}
{vieweralsosee "[D] label" "help label"}{...}
{vieweralsosee "[G-2] graph bar" "help graph bar"}{...}
{vieweralsosee "[G-2] graph hbar" "help graph hbar"}{...}
{vieweralsosee "[G-2] graph dot" "help graph dot"}{...}
{viewerjumpto "Syntax" "splitvarlabels##syntax"}{...}
{viewerjumpto "Description" "splitvarlabels##description"}{...}
{viewerjumpto "Options" "splitvarlabels##options"}{...}
{viewerjumpto "Examples" "splitvarlabels##examples"}{...}
{viewerjumpto "Saved Results" "splitvarlabels##results"}{...}
{viewerjumpto "Authors" "splitvarlabels##authors"}{...}
{viewerjumpto "Acknowledgments" "splitvarlabels##acknowledgments"}{...}
{title:Title}

{phang}
{bf:splitvarlabels} {hline 2} Split variable labels for multiline graph display


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:splitvarlabels}
{varlist}
[{cmd:,} {opt len:gth(#)} {opt b:reak} {opt d:elimiter(string)} {opt loc:al(name)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt len:gth(#)}}target maximum length of each line; default is {cmd:length(15)}{p_end}
{synopt:{opt b:reak}}allow breaking words mid-word if necessary{p_end}
{synopt:{opt d:elimiter(string)}}split at a specified delimiter character{p_end}
{synopt:{opt loc:al(name)}}store results in specified local macro{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:splitvarlabels} allows you to include variable labels in graphs on multiple lines 
produced directly or indirectly by {helpb graph bar}, {helpb graph hbar} or {helpb graph dot}. 

{pstd} 
It does so by splitting the variable labels into smaller pieces and returning those pieces 
in a form appropriate for specification as part of a {cmd:graph} command, typically with the 
{cmd:ascategory} option. A multiline format reduces how often variable labels overlap or 
are truncated. The variable labels themselves are unchanged. 

{pstd}
The variables must be specified in the same order when using {cmd:splitvarlabels} and in any
subsequent {cmd:graph} command. Otherwise, a mislabelling error is likely. 

{pstd}
The command displays the split labels as it processes them so you can immediately see 
how the labels will appear without waiting to generate a graph.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt length(#)} specifies the target maximum length for each line of the split label. 
The default is 15 characters. By default, the command attempts to keep whole words intact, which may result in lines exceeding this length when necessary to avoid breaking words.

{phang}
{opt break} allows the command to break words mid-word to strictly enforce the length limit. 
As noted above, by default, {cmd:splitvarlabels} preserves whole words even if doing so exceeds
the specified length. Use this option when strict length limits are more important than 
keeping words intact, such as when working with narrow graph spaces or strict formatting requirements.

{phang}
{opt delimiter(string)} specifies a delimiter at which to split the label. When this option is specified 
and the delimiter is found in the label, the label is split just before the delimiter, overriding 
the {opt length()} setting for that split. This is particularly useful for splitting at natural 
breakpoints such as parentheses, colons, or dashes. The delimiter itself remains at the beginning 
of the next line. Note that when a delimiter is found, its position becomes the effective length 
for all subsequent splits of that particular label. This means that text following the delimiter 
will continue to be split at this same length, which may produce unexpected results if the 
remaining text is lengthy.

{phang}
{opt local(name)} stores the relabeling specification in the specified local macro, in addition to the standard {cmd:s(relabel)} storage. 
This may be useful in programming contexts or when processing multiple variable sets.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Example 1: Basic usage with long labels}{p_end}

{pstd}Long variable labels often overlap or get truncated in graphs. {cmd:splitvarlabels} solves this problem by splitting them across multiple lines:{p_end}

{phang2}. {stata sysuse uslifeexp.dta, clear}{p_end}

{phang2}. {stata label var le_wmale "Life expectancy of white males in the United States of America"}{p_end}
{phang2}. {stata label var le_wfemale "Life expectancy of white females in the United States of America"}{p_end}
{phang2}. {stata label var le_bmale "Life expectancy of black males in the United States of America"}{p_end}
{phang2}. {stata label var le_bfemale "Life expectancy of black females in the United States of America"}{p_end}

{phang2}. {stata local le le_wmale le_wfemale le_bmale le_bfemale}{p_end}
{phang2}. {stata splitvarlabels `le'}{p_end}
{phang2}. {stata graph bar `le', ascategory yvar(relabel(`s(relabel)'))}{p_end}

{pstd}{bf:Example 2: Using with graph wrappers like statplot}{p_end}

{pstd}{cmd:splitvarlabels} works with graph wrapper commands that indirectly use {helpb graph bar}, {helpb graph hbar} or {helpb graph dot} as well. 
Here we use it with {cmd:statplot} from SSC:{p_end}

{phang2}. {stata ssc install statplot}{p_end}
{phang2}. {stata splitvarlabels `le', length(20)}{p_end}
{phang2}. {stata statplot `le', varopts(label(labsize(small)) relabel(`s(relabel)'))}{p_end}

{pstd}{bf:Example 3: Demonstrating the break option}{p_end}

{pstd}Sometimes you need strict length control, even if it means breaking words. The {opt break} option allows this:{p_end}

{phang2}. {stata sysuse auto, clear}{p_end}
{phang2}. {stata label var mpg "Fuel-efficiency-measurement in miles per gallon"}{p_end}

{pstd}Default behavior keeps "Fuel-efficiency-measurement" intact despite exceeding 10 characters in length:{p_end}
{phang2}. {stata splitvarlabels mpg, length(10)}{p_end}

{pstd}With the {cmd:break} option, the command enforces a strict 10-character limit:{p_end}
{phang2}. {stata splitvarlabels mpg, length(10) break}{p_end}

{pstd}{bf:Example 4: Getting meaningful labels}{p_end}

{pstd}When graphing statistics, Stata's default labels like "mean of collgrad" may not be what the user requires. {cmd:splitvarlabels} provides the actual variable labels:{p_end}

{phang2}. {stata sysuse nlsw88, clear}{p_end}

{phang2}. {stata label var collgrad "Individual graduated from college"}{p_end}
{phang2}. {stata label var married "Individual is currently married"}{p_end}
{phang2}. {stata label var c_city "Individual lives in central city"}{p_end}

{pstd}Without {cmd:splitvarlabels}, you get "mean of collgrad", "mean of married", etc.:{p_end}
{phang2}. {stata graph hbar (mean) collgrad married c_city, ascategory title("Select Means")}{p_end}

{pstd}To manually fix this without {cmd:splitvarlabels} is somewhat tedious:{p_end}
{phang2}{cmd:graph hbar (mean) collgrad married c_city, ascategory yvar(relabel(1 "`:var label collgrad'" 2 "`:var label married'" 3 "`:var label c_city'")) title("Select Means")}{p_end}

{pstd}Or spelling out the labels manually:{p_end}
{phang2}. {stata graph hbar (mean) collgrad married c_city, ascategory yvar(relabel(1 "Individual graduated from college" 2 "Individual is currently married" 3 "Individual lives in central city")) title("Select Means")}{p_end}

{pstd}With {cmd:splitvarlabels}, it's relatively straightforward:{p_end}
{phang2}. {stata splitvarlabels collgrad married c_city}{p_end}
{phang2}. {stata graph hbar (mean) collgrad married c_city, ascategory yvar(relabel(`s(relabel)')) title("Select Means")}{p_end}

{pstd}{bf:Example 5: Using local() option for multiple graphs}{p_end}

{pstd}When creating multiple related graphs, the {opt local()} option lets you store different label sets without rerunning {cmd:splitvarlabels} immediately before each graph:{p_end}

{phang2}. {stata label var union "Individual is member of labor union"}{p_end}
{phang2}. {stata label var south "Individual resides in southern region"}{p_end}
{phang2}. {stata label var smsa "Individual lives in standard metropolitan statistical area"}{p_end}

{phang2}. {stata local demographics collgrad married union}{p_end}
{phang2}. {stata local geography south c_city smsa}{p_end}

{phang2}. {stata splitvarlabels `demographics', local(demo_labels)}{p_end}
{phang2}. {stata splitvarlabels `geography', local(geo_labels)}{p_end}

{pstd}Now you can create multiple graphs without rerunning {cmd:splitvarlabels}:{p_end}
{phang2}. {stata graph hbar (mean) `demographics', ascategory yvar(relabel(`demo_labels')) title("Demographics")}{p_end}
{phang2}. {stata graph hbar (mean) `geography', ascategory yvar(relabel(`geo_labels')) title("Geography")}{p_end}

{pstd}{bf:Example 6: Using delimiter for metadata on separate lines}{p_end}

{pstd}The {opt delimiter()} option is particularly useful when adding metadata like sample size or units to labels. 
It ensures the metadata appears on a separate line by splitting at a natural breakpoint:{p_end}

{phang2}. {stata webuse nhanes2, clear}{p_end}
{phang2}. {stata summarize bmi weight height}{p_end}
{phang2}. {stata label var bmi "Body Mass Index (kg/m²)"}{p_end}
{phang2}. {stata label var weight "Body Weight (kg)"}{p_end}
{phang2}. {stata label var height "Standing Height (cm)"}{p_end}

{pstd}Split at the opening parenthesis to place units on a separate line:{p_end}
{phang2}. {stata splitvarlabels bmi weight height, delimiter("(")}{p_end}
{phang2}. {stata statplot bmi weight height, over(sex) varopts(relabel(`s(relabel)'))}{p_end}


{marker results}{...}
{title:Saved Results}

{pstd}
{cmd:splitvarlabels} saves the following in {cmd:s()}:

{pstd}
{cmd:s(relabel)} contains the relabeling specification for use with graph commands. 
If the {opt local()} option is specified, the same relabeling specification is also stored in the specified local macro.


{marker authors}{...}
{title:Authors}

{pstd}Kabira Namit{break}
World Bank{break}
knamit@worldbank.org

{pstd}Nicholas J. Cox{break}
Durham University{break}
n.j.cox@durham.ac.uk


{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
{cmd:splitvarlabels} was directly inspired by and heavily influenced by Nicholas Winter and Ben Jann's {cmd:splitvallabels} (August 2008), available on SSC.


