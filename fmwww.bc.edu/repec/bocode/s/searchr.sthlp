{smcl}
{* *! version 1.0 15Jul2022}{...}
{hline}

{title:Title}

{p2colset 5 16 16 2}{...}
{p2col:{hi: searchr} {hline 2}}Search the similar packages in R software within Stata Command Window.{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:searchr} keywords [{cmd:,} {it:options}]



{p 8 14 2}

{synoptset 14}{...}
{synopthdr:Options}
{synoptline}
{synopt:{cmdab:NS:imilar}}
Specify the top N observations are reported. Default value is 15.
{p_end}
{synopt:{cmdab:matchit}}
Use the matchit routine to implement the text similar analysis. If not specified, the default approach is based on the same word count between
keywords and text.
{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{bf:searchr} make it easy for users to search the related functions in R within Stata command window.
The source data comes from   {browse "https://cran.r-project.org/":R CRAN}. Specify, this function is 
designed to find the related packages based on similar text patterns. Two approaches are introduced.
The first one is based on the matchit routine. All the default options in this function are used. The second 
one is  based on the the same word count between keywords and text.

{title:Examples}

{pstd}

{pstd}Find the related functions based on matchit{p_end}

{phang2}. {stata "searchr quantile regression,matchit "}{p_end}

{pstd}Based on the number of words{p_end}

{phang2}. {stata "searchr quantile regression"}{p_end}   

{pstd}Specify the observations are listed{p_end}

{phang2}. {stata "searchr quantile regression,nsimilar(5)"}{p_end}   

{phang2}. {stata "searchr spatial panel,nsimilar(20) matchit"}{p_end}   

{title:Author}

{phang}
{cmd:Wanhai, You* (游万海)}  School of Economics and Management, Fuzhou University, Fuzhou, China.{break}
E-mail: {browse "mailto:ywhfzu@163.com":ywhfzu@163.com}. {break}
{p_end}

{phang}
{cmd:Jianping, Li (李建平)}  School of Economics and Management, University of Chinese Academy of Sciences, Beijing, China.{break}
E-mail: {browse "ljp@ucas.ac.cn":ljp@ucas.ac.cn}. {break}
{p_end}

{phang}
{cmd:Yujun, Lian (连玉君)} Lingnan College, Sun Yat-Sen University, China.{break}
E-mail: {browse "mailto:arlionn@163.com":arlionn@163.com}. {break}
Blog: {browse "lianxh.cn":https://www.lianxh.cn}. {break}
{p_end}

{title:For problems and suggestions}

{p 4 4 2}
Any problems or suggestions are welcome, please Email to
{browse "mailto:ywhfzu@163.com":ywhfzu@163.com}. 

{title:Note}

{p 4 4 2}
Please install {it:{help matchit}} command when one use this command first time.To download it, type the following command {break}
or click on it: {stata "ssc install matchit, all replace": ssc install matchit, all replace}. 

{title:Also see}

{p 4 4 2}
Online: help for {help matchit}, {help reclink}.
