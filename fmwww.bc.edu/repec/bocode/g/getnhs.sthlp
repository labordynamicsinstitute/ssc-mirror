{smcl}
{* 	*! version 1.0  1 May Dec2022}{...}
{cmd:help getnhs} 
{hline}

{title:Title}

{p2colset 5 12 16 2}{...}
{p2col :{hi:getnhs} {hline 2}}Download NHANES data{p_end}
{p2colreset}{...}


{title:Syntax}
{p 8 16 2}{cmd:getnhs} {it:year DATASET} 

{p 4 4 2}{it:year} refers to the year of NHANES data;
{it:DATASET} refers to the name of the dataset, such as DEMO.


{title:Description}

{pstd}
{cmd:getnhs} download NHANES data (1999 onwards) into Stata format. 

{title:Example: Basic use}

{pstd}The following syntax downloads 2010 DEMO data (demographic data)  {p_end}
{tab}{cmd:. getnhs 2010 DEMO}

{pstd}The following syntax downloads 2016 diabetes questionnaire data {p_end}
{tab}{cmd:. getnhs 2016 DIQ}

{pstd} For the 2017-2020 data, the name of the dataset has a prefix P-. So the syntax is slightly different. The following syntax downloads 2017-2020 diabetes questionnaire data {p_end}
{tab}{cmd:. getnhs 2019 P_DIQ}


{title:Author}

{pstd}
Zumin Shi, 
Department of Human Nutrition, 
College of Health Sciences, QU Health, 
Qatar University, Qatar. 
(zumin.shi@gmail.com)
