{smcl}
{* *! version 1.0.0  16may2026}{...}
{title:Title}

{p 4 19 2}
{hi:qqtable} {hline 2}  Formatted console and LaTeX table from QQ results

{title:Syntax}

{p 8 17 2}
{cmd:qqtable} [{cmd:using} {it:filename}] [{cmd:,} {it:options}]

{synoptset 24}{...}
{synopthdr}
{synoptline}
{synopt:{opt v:alue(varname)}}value to tabulate (default {bf:coef}){p_end}
{synopt:{opt stars}}append significance stars{p_end}
{synopt:{opt var:iable(name)}}filter by variable{p_end}
{synopt:{opt band(name)}}filter by band{p_end}
{synopt:{opt dig:its(#)}}decimal digits (default 3){p_end}
{synopt:{opt lat:ex(filename)}}export LaTeX table{p_end}
{synopt:{opt t:itle(string)}}table title{p_end}
{synopt:{opt replace}}overwrite LaTeX file{p_end}
{synoptline}

{title:Example}

{phang2}{cmd:. qqtable using qq.dta, value(coef) stars latex(table.tex) replace}{p_end}

{title:See also}

{p 4 8 2}{help qqheat}, {help qqr}, {help mqqr}{p_end}
