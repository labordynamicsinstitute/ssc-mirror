{smcl}
{* *! version 1.0.0  16may2026}{...}
{title:Title}

{p 4 19 2}
{hi:qqcauseplot} {hline 2}  Line plot of quantile-causality test statistics

{title:Syntax}

{p 8 17 2}
{cmd:qqcauseplot} [{cmd:using} {it:filename}] [{cmd:,} {it:options}]

{synoptset 26}{...}
{synopthdr}
{synoptline}
{synopt:{opt t:itle(string)}}plot title{p_end}
{synopt:{opt sub:title(string)}}subtitle{p_end}
{synopt:{opt xt:itle(string)}}x-axis title{p_end}
{synopt:{opt yt:itle(string)}}y-axis title{p_end}
{synopt:{opt sa:ve(filename)}}export graph{p_end}
{synopt:{opt name(name)}}graph window name{p_end}
{synopt:{opt sch:eme(name)}}Stata scheme{p_end}
{synopt:{opt replace}}overwrite when saving{p_end}
{synoptline}

{title:Description}

{p 4 4 2}
{cmd:qqcauseplot} plots the quantile causality test statistic over the τ grid
with horizontal lines marking the 5% and 10% critical values from N(0,1).
Regions where |T| > 1.96 are shaded.{p_end}

{title:Example}

{phang2}{cmd:. qqgcause sp500 oil, saving(c.dta) replace}{p_end}
{phang2}{cmd:. qqcauseplot using c.dta, title("Oil -> S&P 500")}{p_end}

{title:See also}

{p 4 8 2}{help qqgcause}{p_end}
