{smcl}
{* *! version 1.2.3 08Aug2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "help corr2tex" "help corr2tex"}{...}
{viewerjumpto "Syntax" "corr2tex##syntax"}{...}
{viewerjumpto "Description" "corr2tex##description"}{...}
{viewerjumpto "Options" "corr2tex##options"}{...}
{viewerjumpto "Examples" "corr2tex##examples"}{...}
{viewerjumpto "Authors" "corr2tex##authors"}{...}
{viewerjumpto "Version" "corr2tex##version"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{bf:corr2tex} {hline 2}}Export publication-ready correlation matrices to LaTeX with significance stars{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:corr2tex} {varlist} [{cmd:if}] [{cmd:in}], 
{cmd:SAVing(}{it:filename}{cmd:)} 
[
{cmdab:DEC:imal(}{it:#}{cmd:)}
{cmdab:REPL:ace}
{cmdab:LAND:scape}
{cmdab:TIt:le(}{it:string}{cmd:)}
{cmdab:THREE:line}
{cmdab:LAB:el}
{cmdab:NOTE(}{it:string}{cmd:)}
{cmdab:STAR}
]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt saving(filename)}}output LaTeX filename{p_end}

{syntab:Main}
{synopt:{opt dec:imal(#)}}decimal places for coefficients (default: 3){p_end}
{synopt:{opt rep:lace}}overwrite existing file{p_end}

{syntab:Formatting}
{synopt:{opt land:scape}}landscape page orientation{p_end}
{synopt:{opt ti:tle(string)}}table caption text{p_end}
{synopt:{opt three:line}}use booktabs three-line table style{p_end}
{synopt:{opt lab:el}}use variable labels instead of names{p_end}
{synopt:{opt note(string)}}custom table note text{p_end}
{synopt:{opt star}}add significance stars to correlations{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:corr2tex} generates publication-quality correlation matrices in LaTeX format. 
The command automatically calculates Pearson correlation coefficients, formats them 
with specified decimal places, and adds significance stars when requested. Key features include:

{pstd}
{ul:Matrix Features}{p_end}
{phang2}- Complete correlation matrix with diagonal elements set to 1{p_end}
{phang2}- Automatic handling of numeric variables{p_end}
{phang2}- Significance stars: * p<0.10, ** p<0.05, *** p<0.01 ({opt star} option){p_end}
{phang2}- Stars displayed only in lower triangle to avoid duplication{p_end}

{pstd}
{ul:Formatting Options}{p_end}
{phang2}- Variable label support ({opt label} option){p_end}
{phang2}- Flexible decimal formatting (0-6 places){p_end}
{phang2}- Landscape mode for wide matrices{p_end}
{phang2}- Booktabs professional table format{p_end}
{phang2}- Custom table notes and captions{p_end}

{pstd}
{ul:Output Features}{p_end}
{phang2}- Complete compilable LaTeX document{p_end}
{phang2}- Automatic escaping of LaTeX special characters{p_end}
{phang2}- Mathematical mode for proper number formatting{p_end}
{phang2}- Three-line table style with notes section{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Required}
{phang}
{opt saving(filename)} specifies the output .tex file path. Required. Enclose paths with spaces in quotes.

{dlgtab:Main}
{phang}
{opt decimal(#)} sets the number of decimal places for correlation coefficients. 
Default is 3. Valid range is 0-6. Sample size (N) always displayed as integer.

{phang}
{opt replace} overwrites existing output file without warning.

{dlgtab:Formatting}
{phang}
{opt landscape} orients table in landscape mode using pdflscape package. Recommended for matrices with >5 variables.

{phang}
{opt title(string)} adds a table caption. Use double quotes for multi-line titles. LaTeX special characters not automatically escaped.

{phang}
{opt threeline} applies professional booktabs table style with three rules (toprule, midrule, bottomrule) and dedicated notes section.

{phang}
{opt label} uses variable labels instead of variable names for row and column headers. If no label exists, uses variable name.

{phang}
{opt note(string)} adds custom explanatory text to the table notes. Maximum 200 characters recommended.

{phang}
{opt star} adds significance stars to correlation coefficients in the lower triangle:
{p_end}
{p 8 12 2}- * p < 0.10{p_end}
{p 8 12 2}- ** p < 0.05{p_end}
{p 8 12 2}- *** p < 0.01{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{ul:Basic correlation matrix}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. corr2tex price mpg weight, saving("table1.tex") replace}{p_end}

{pstd}{ul:Matrix with significance stars}{p_end}
{phang2}{cmd:. corr2tex price mpg headroom trunk, saving("corr.tex") ///}{p_end}
{phang3}{cmd:star decimal(2) replace}{p_end}

{pstd}{ul:Publication-ready table with all options}{p_end}
{phang2}{cmd:. corr2tex price mpg headroom trunk length, ///}{p_end}
{phang3}{cmd:saving("corr_matrix.tex") replace ///}{p_end}
{phang3}{cmd:star decimal(3) landscape threeline ///}{p_end}
{phang3}{cmd:label title("Vehicle Characteristics Correlation Matrix") ///}{p_end}
{phang3}{cmd:note("Data from 1978 Automobile Survey; N = 74")}{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
{bf:Wu Lianghai}{p_end}
{pstd}School of Economics, Anhui University of Technology{p_end}
{pstd}Ma'anshan, China{p_end}
{pstd}{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
{bf:Wu Hanyan}{p_end}
{pstd}College of Economics and Management, Nanjing University of Aeronautics and Astronautics{p_end}
{pstd}Nanjing, China{p_end}
{pstd}{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}
{bf:Hu Fangfang}{p_end}
{pstd}School of Business, Wanjiang University of Technology{p_end}
{pstd}Ma'anshan, China{p_end}
{pstd}{browse "mailto:huff470@163.com":huff470@163.com}{p_end}

{pstd}
{it:Please report any issues or suggestions to the authors.}

{marker version}{...}
{title:Version}

{pstd}
{cmd:corr2tex} version 1.2.3 - 08 August 2025

{title:Updates}

{pstd}
{ul:Version 1.2.3}{p_end}
{phang2}- Fixed LaTeX math mode formatting for correlation coefficients{p_end}
{phang2}- Improved table column specification for better compatibility{p_end}
{phang2}- Enhanced error handling for decimal place specification{p_end}

{pstd}
{ul:Version 1.2.0}{p_end}
{phang2}- Added significance stars option ({opt star}){p_end}
{phang2}- Automatic notes for significance levels{p_end}
{phang2}- Improved landscape mode formatting{p_end}

{title:Also see}

{p 4 4 2}
{help correlate}, 
{help pwcorr}, 
{help esttab} (SSC), 
{help sumtex}, 
{help regtex}
{p_end}