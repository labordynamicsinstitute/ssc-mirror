{smcl}
{* *! version 2.0  28nov2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] meta" "help meta"}{...}
{viewerjumpto "Syntax" "midas_quadas2##syntax"}{...}
{viewerjumpto "Description" "midas_quadas2##description"}{...}
{viewerjumpto "Options" "midas_quadas2##options"}{...}
{viewerjumpto "Examples" "midas_quadas2##examples"}{...}
{viewerjumpto "Stored results" "midas_quadas2##results"}{...}
{viewerjumpto "Author" "midas_quadas2##author"}{...}
{title:Title}

{phang}
{bf:midas_quadas2} {hline 2} Create QUADAS-2 quality assessment plots for systematic reviews


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:midas_quadas2}
{cmd:,}
{opt id(varname)}
{opt robvars(varlist)}
{opt acvars(varlist)}
{opt plot(string)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt id(varname)}}variable identifying individual studies{p_end}
{synopt:{opt robvars(varlist)}}variables for Risk of Bias assessment{p_end}
{synopt:{opt acvars(varlist)}}variables for Applicability Concerns assessment{p_end}
{synopt:{opt plot(string)}}type of plot: {bf:bar} or {bf:sum}{p_end}

{syntab:Optional}
{synopt:{opt col:or}}produce color plots instead of grayscale{p_end}
{synopt:{opt scheme(string)}}specify Stata graphics scheme{p_end}
{synopt:{opt sav:ing(string)}}save combined graph{p_end}
{synopt:{it:graph_options}}additional graph options to pass through{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas_quadas2} creates quality assessment plots following the QUADAS-2 
(Quality Assessment of Diagnostic Accuracy Studies-2) framework for systematic 
reviews of diagnostic test accuracy studies. The command produces two types of 
visualizations:

{phang}
{bf:Bar plots} ({cmd:plot(bar)}) - Display the proportion of studies rated as 
having low, unclear, or high risk of bias/applicability concerns for each 
assessment criterion. These plots provide an overview of methodological quality 
across all included studies.

{phang}
{bf:Summary (traffic-light) plots} ({cmd:plot(sum)}) - Display the quality 
assessment for each individual study across all criteria using a traffic-light 
display. Each study is represented as a row, and each criterion as a column, 
with symbols indicating the risk level.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt id(varname)} specifies the variable that uniquely identifies each study in 
the dataset. This is typically a study identifier or author-year combination. 
For summary plots, the study labels will be displayed on the y-axis.

{phang}
{opt robvars(varlist)} specifies the variables containing Risk of Bias 
assessments. Each variable should represent one QUADAS-2 signaling question or 
domain. Variables must be string variables containing the values "low", 
"unclear", or "high". Variable labels will be used as criterion labels in the 
plots.

{phang}
{opt acvars(varlist)} specifies the variables containing Applicability Concerns 
assessments. Like {opt robvars}, these should be string variables with values 
"low", "unclear", or "high". Variable labels will be used as criterion labels.

{phang}
{opt plot(string)} specifies the type of plot to create. Must be either:
{p_end}
{p 12 16 2}{bf:bar} - Creates horizontal stacked bar charts showing the 
percentage distribution of quality ratings{p_end}
{p 12 16 2}{bf:sum} - Creates traffic-light plots showing individual study 
assessments{p_end}

{dlgtab:Optional}

{phang}
{opt color} produces colored plots instead of the default grayscale. In color 
mode:
{p_end}
{p 12 16 2}- Low risk is displayed in green{p_end}
{p 12 16 2}- Unclear risk is displayed in yellow/gold{p_end}
{p 12 16 2}- High risk is displayed in red{p_end}

{pmore}
In grayscale mode:
{p_end}
{p 12 16 2}- Low risk is displayed with white fill{p_end}
{p 12 16 2}- Unclear risk is displayed in gray{p_end}
{p 12 16 2}- High risk is displayed in black{p_end}

{phang}
{opt scheme(string)} specifies a Stata graphics scheme. Default is {bf:s2mono}. 
You can use any installed Stata scheme (e.g., s1color, economist, sj).

{phang}
{opt saving(string)} saves the combined graph to a file. Specify the filename 
with or without the .gph extension.

{phang}
{it:graph_options} are additional options passed to the underlying {cmd:graph} 
commands. These can include options like {cmd:name()}, {cmd:title()}, etc.


{marker examples}{...}
{title:Examples}

{pstd}Setup: Load example dataset{p_end}
{phang2}{cmd:. use http://fmwww.bc.edu/repec/bocode/m/quadas2data.dta, clear}{p_end}

{pstd}Or create example dataset manually:{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str20 study str10 rob1 str10 rob2 str10 rob3 str10 ac1 str10 ac2}{p_end}
{phang2}{cmd:"Smith 2020" "low" "low" "unclear" "low" "low"}{p_end}
{phang2}{cmd:"Jones 2021" "high" "low" "low" "low" "unclear"}{p_end}
{phang2}{cmd:"Brown 2022" "low" "unclear" "high" "unclear" "low"}{p_end}
{phang2}{cmd:end}{p_end}

{phang2}{cmd:. label variable rob1 "Patient Selection"}{p_end}
{phang2}{cmd:. label variable rob2 "Index Test"}{p_end}
{phang2}{cmd:. label variable rob3 "Reference Standard"}{p_end}
{phang2}{cmd:. label variable ac1 "Patient Selection"}{p_end}
{phang2}{cmd:. label variable ac2 "Index Test"}{p_end}

{pstd}Example 1: Create grayscale bar charts{p_end}
{phang2}{cmd:. midas_quadas2, id(study) robvars(rob1 rob2 rob3) acvars(ac1 ac2) plot(bar)}{p_end}

{pstd}Example 2: Create color bar charts{p_end}
{phang2}{cmd:. midas_quadas2, id(study) robvars(rob1 rob2 rob3) acvars(ac1 ac2) plot(bar) color}{p_end}

{pstd}Example 3: Create traffic-light summary plot in grayscale{p_end}
{phang2}{cmd:. midas_quadas2, id(study) robvars(rob1 rob2 rob3) acvars(ac1 ac2) plot(sum)}{p_end}

{pstd}Example 4: Create color traffic-light plot with custom scheme{p_end}
{phang2}{cmd:. midas_quadas2, id(study) robvars(rob1 rob2 rob3) acvars(ac1 ac2) plot(sum) color scheme(s1color)}{p_end}

{pstd}Example 5: Create and save plots{p_end}
{phang2}{cmd:. midas_quadas2, id(study) robvars(rob1 rob2 rob3) acvars(ac1 ac2) plot(sum) color saving(quadas2_plots)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:midas_quadas2} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of studies{p_end}
{p2colreset}{...}


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Data preparation:}

{pmore}
Before using {cmd:midas_quadas2}, ensure your data are properly formatted:

{p 8 12 2}1. Each observation should represent one study{p_end}

{p 8 12 2}2. Quality assessment variables must be string variables containing 
exactly "low", "unclear", or "high" (case-sensitive){p_end}

{p 8 12 2}3. Add descriptive variable labels to your quality assessment 
variables - these will appear as criterion labels in the plots{p_end}

{p 8 12 2}4. The study ID variable should contain unique, meaningful study 
identifiers (e.g., "Author Year"){p_end}

{pstd}
{bf:Interpreting the plots:}

{pmore}
{it:Bar plots} show the overall methodological quality across studies. A high 
proportion of "low risk" ratings (green or white bars) indicates good overall 
study quality. Large proportions of "unclear" or "high" risk suggest potential 
quality issues.

{pmore}
{it:Traffic-light plots} allow assessment of individual study quality patterns. 
Each row represents a study, each column a quality criterion. Patterns of red 
or yellow/gold circles across a row indicate studies with potential bias. 
Patterns down a column indicate criteria that are problematic across multiple 
studies.

{pstd}
{bf:QUADAS-2 framework:}

{pmore}
The QUADAS-2 tool assesses four key domains:

{p 12 16 2}1. Patient Selection{p_end}
{p 12 16 2}2. Index Test{p_end}
{p 12 16 2}3. Reference Standard{p_end}
{p 12 16 2}4. Flow and Timing{p_end}

{pmore}
Each domain is assessed for Risk of Bias (first three domains also for 
Applicability Concerns). Your {opt robvars} should include variables for each 
relevant domain's risk of bias assessment, and {opt acvars} should include 
applicability assessments.


{marker references}{...}
{title:References}

{pstd}
Whiting PF, Rutjes AW, Westwood ME, et al. QUADAS-2: a revised tool for the 
quality assessment of diagnostic accuracy studies. {it:Ann Intern Med}. 
2011;155(8):529-536. doi:10.7326/0003-4819-155-8-201110180-00009


{marker author}{...}
{title:Author}

{pstd}
For questions, bug reports, or suggestions, please contact the package maintainer.


{title:Also see}

{psee}
Online: {manhelp meta R}, {manhelp graph G-2}
{p_end}
