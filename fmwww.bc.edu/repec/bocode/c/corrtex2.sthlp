{smcl}
{* *! version 2.9 12Aug2025}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{bf:corrtex2} {hline 2}}Export correlation matrix to publication-quality LaTeX table{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab:corrtex2}
{varlist}
[{cmd:if}]
[{cmd:in}]
,
{cmd:file}({it:string})
[
{cmd:digits}({it:integer})
{cmd:landscape}
{cmd:longtable}
{cmd:append}
{cmd:replace}
{cmd:casewise}
{cmd:placement}({it:string})
{cmd:title}({it:string})
{cmd:key}({it:string})
{cmd:na}({it:string})
{cmd:noscreen}
{cmd:nbobs}
{cmd:fontsize}({it:string})
]

{title:Description}

{pstd}
{cmd:corrtex2} exports a correlation matrix to a publication-quality LaTeX table with the following features:{p_end}

{p 8 8 2}
- Automatically handles Chinese/English variable labels{break}
- Adds significance stars (*** p<0.01, ** p<0.05, * p<0.10){break}
- Generates standalone LaTeX documents compilable with XeLaTeX{break}
- Supports landscape orientation and longtable formats{break}
- Includes observation counts with {cmd:nbobs} option{break}
- Uses LaTeX dcolumn package for perfect decimal alignment{break}
- Compatible with amsmath package for robust star formatting
- Supports by-group processing for subgroup analysis

{title:Options}

{phang}{cmd:file}({it:string}) specifies the output LaTeX file (required).{p_end}

{phang}{cmd:digits}({it:integer}) sets decimal precision (default=3).{p_end}

{phang}{cmd:landscape} formats table in landscape orientation.{p_end}

{phang}{cmd:longtable} uses longtable environment for multi-page tables.{p_end}

{phang}{cmd:append}/{cmd:replace} specifies file handling behavior.{p_end}

{phang}{cmd:casewise} uses casewise deletion for correlations.{p_end}

{phang}{cmd:placement}({it:string}) sets LaTeX table placement (e.g., "htbp").{p_end}

{phang}{cmd:title}({it:string}) specifies custom table title.{p_end}

{phang}{cmd:key}({it:string}) sets LaTeX label prefix.{p_end}

{phang}{cmd:na}({it:string}) specifies missing value representation.{p_end}

{phang}{cmd:noscreen} suppresses on-screen output.{p_end}

{phang}{cmd:nbobs} displays observation counts below correlations.{p_end}

{phang}{cmd:fontsize}({it:string}) sets LaTeX font size (e.g., "\small", "\footnotesize").{p_end}

{title:Examples}

{phang}{ul:Example 1: Basic usage with decimal alignment}{p_end}
{phang2}{cmd:. cd "E:\益友学术\鼎园会计130期\report"}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. corrtex2 price mpg weight length, file("mytable.tex") replace}{p_end}

{phang}{ul:Example 2: Chinese variables with advanced formatting}{p_end}
{phang2}{cmd:. use "E:\益友学术\鼎园会计130期\data\asure.dta", clear}{p_end}
{phang2}{cmd:. corrtex2 ESG NCSKEW DUVOL ret roa tobinq, ///}{p_end}
{phang2}{cmd:    file("ESG_table.tex") replace ///}{p_end}
{phang2}{cmd:    title("ESG相关性分析") ///}{p_end}
{phang2}{cmd:    landscape longtable ///}{p_end}
{phang2}{cmd:    fontsize("\small") ///}{p_end}
{phang2}{cmd:    digits(4) nbobs}{p_end}

{phang}{ul:Example 3: Grouped correlations by ownership type (SOE vs non-SOE)}{p_end}
{phang2}{cmd:. bys soe: corrtex2 ESG NCSKEW DUVOL ret roa tobinq, ///}{p_end}
{phang2}{cmd:    file("ESG_table2.tex") replace ///}{p_end}
{phang2}{cmd:    title("ESG相关性分析") ///}{p_end}
{phang2}{cmd:    landscape longtable ///}{p_end}
{phang2}{cmd:    fontsize("\small") ///}{p_end}
{phang2}{cmd:    digits(4) nbobs}{p_end}

{phang}{ul:Example 4: Custom formatting for large tables}{p_end}
{phang2}{cmd:. corrtex2 var1-var10, file("bigtable.tex") replace ///}{p_end}
{phang2}{cmd:    digits(2) longtable landscape ///}{p_end}
{phang2}{cmd:    fontsize("\footnotesize") nbobs}{p_end}

{title:Authors}

{pstd}Wu Lianghai{p_end}
{pstd}Anhui University of Technology (AHUT){p_end}
{pstd}Email: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}Hu Fangfang{p_end}
{pstd}Wanjiang University of Technology (WJUT){p_end}
{pstd}Email: {browse "mailto:huff470@163.com":huff470@163.com}{p_end}

{pstd}Wu Hanyan{p_end}
{pstd}Nanjing University of Aeronautics and Astronautics (NUAA){p_end}
{pstd}Email: {browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}Zhao Xin{p_end}
{pstd}Anhui University of Technology (AHUT){p_end}
{pstd}Email: {browse "mailto:1980124145@qq.com":1980124145@qq.com}{p_end}

{title:Acknowledgements} 

{pstd}We sincerely thank Christopher F. Baum and Kit Baum for their guidance and selfless support.{p_end}

{title:Also see}

{p 4 13 2}
{help correlate},
{help pwcorr},
{help corr2tex},
{help corrtex}
{p_end}