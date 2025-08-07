{smcl}
{* *! version 3.8.7 05Aug2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "help regtex" "help regtex"}{...}
{viewerjumpto "Syntax" "regtex##syntax"}{...}
{viewerjumpto "Description" "regtex##description"}{...}
{viewerjumpto "Options" "regtex##options"}{...}
{viewerjumpto "Examples" "regtex##examples"}{...}
{viewerjumpto "Authors" "regtex##authors"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:regtex} {hline 2}}Export regression results to publication-ready LaTeX tables{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
{cmd:regtex} {it:model_list} [{cmd:if}] [{cmd:in}], {cmd:SAVing(}{it:filename}{cmd:)} 
[{cmdab:DEC:imal(}{it:#}{cmd:)} 
{cmdab:STARLevels(}{it:numlist}{cmd:)} 
{cmdab:REPL:ace} 
{cmdab:VCE(}{it:vcetype}{cmd:)} 
{cmdab:Title(}{it:string}{cmd:)} 
{cmd:threeline} 
{cmdab:LAND:scape} 
{cmd:modelnames(}{it:"name1" "name2" ...}{cmd:)} ]


{marker description}{...}
{title:Description}

{pstd}
{cmd:regtex} exports regression results from multiple models to a publication-ready LaTeX table.
It automatically handles coefficient formatting, significance stars, standard errors, and model statistics.
The output is a complete .tex file with proper LaTeX document structure.

{pstd}
Key features:{p_end}
{phang2}- Supports multiple regression models in one table{p_end}
{phang2}- Formats coefficients and standard errors with significance stars{p_end}
{phang2}- Auto-removes trailing zeros in decimals{p_end}
{phang2}- Includes landscape mode and three-line table formatting{p_end}
{phang2}- Generates full LaTeX document with required packages{p_end}
{phang2}- Custom model names with support for spaces (use quotes){p_end}


{marker options}{...}
{title:Options}

{dlgtab:Required}
{phang}
{cmd:saving(}{it:filename}{cmd:)} specifies the output .tex file path.

{dlgtab:Main}
{phang}
{cmd:decimal(}{it:#}{cmd:)} sets decimal places for numbers (default: 3).

{phang}
{cmd:starlevels(}{it:numlist}{cmd:)} sets p-value thresholds for stars (default: 0.10 0.05 0.01).

{phang}
{cmd:replace} overwrites existing file.

{phang}
{cmd:vce(}{it:vcetype}{cmd:)} specifies variance-covariance estimator (e.g., {cmd:vce(robust)}).

{dlgtab:Formatting}
{phang}
{cmd:title(}{it:string}{cmd:)} adds table caption.

{phang}
{cmd:threeline} adds three-part table with significance note.

{phang}
{cmd:landscape} orients table in landscape mode.

{phang}
{cmd:modelnames(}{it:"name1" "name2" ...}{cmd:)} provides custom model names. Names must be quoted and separated by spaces. 
Number of names must match number of models. Names may contain spaces if enclosed in quotes (e.g., {cmd:modelnames("Baseline" "Full Model")}).


{marker examples}{...}
{title:Examples}

{pstd}{ul:Basic usage with two models}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. regtex "price weight" "price weight mpg", saving("table.tex") replace}{p_end}

{pstd}{ul:Advanced options with custom formatting}{p_end}
{phang2}{cmd:. regtex "price weight" "price weight mpg", ///}{p_end}
{phang3}{cmd:saving("table.tex") replace ///}{p_end}
{phang3}{cmd:decimal(2) ///}{p_end}
{phang3}{cmd:starlevels(0.05 0.01) ///}{p_end}
{phang3}{cmd:vce(robust) ///}{p_end}
{phang3}{cmd:title("Auto Price Regressions") ///}{p_end}
{phang3}{cmd:threeline ///}{p_end}
{phang3}{cmd:landscape ///}{p_end}
{phang3}{cmd:modelnames("Simple Model" "Extended")}{p_end}


{marker authors}{...}
{title:Authors}

{pstd}
Wu Lianghai{p_end}
{pstd}School of Economics, Anhui University of Technology, Ma'anshan, China{p_end}
{pstd}{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
Wu Hanyan{p_end}
{pstd}College of Economics and Management, Nanjing University of Aeronautics and Astronautics, China{p_end}
{pstd}{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}
Wu Xinzhuo{p_end}
{pstd}Shenzhen MSU-BIT University (Undergraduate) / University of Bristol (Postgraduate){p_end}
{pstd}{browse "mailto:2957833979@qq.com":2957833979@qq.com}{p_end}

{pstd}
{it:Please report issues and suggestions to the authors.}{p_end}

{title:Version}

{pstd}
{cmd:regtex} version 3.8.7 - 05 August 2025{p_end}
{pstd}{ul:Updates}:{p_end}
{phang2}- Fixed {cmd:modelnames()} option to support quoted names with spaces{p_end}
{phang2}- Added model name count validation{p_end}
{phang2}- Improved error handling for model specification{p_end}