{smcl}
{* *! version 2  DEC2013}{...}
{cmd:help pisastats} {right:also see:  {help pisareg} {help pisacmd} {help pisaqreg} {help pisaoaxaca} {help pisadeco} {help pv}}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:[R] pisastats} } Basic statistics with PISA data{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 18 2}
{cmd:pisastats}
	{it:{help indep_vars}}
	{cmd:,}  stats(string) pv(string) cnt(string) save(string) over(var) round(int) fast sas
	
{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main options}

{synopt :{opt stats(string)}} Specifies a list of statistics to be calculated with PISA data. You can ask for any statistic available after -sum, detail- command. Not specifying this option will produce an output with means of variables and plausible values {p_end}

{synopt :{opt pv(string)}} Specifies a cognitive domain for which you want to calculate statistics. You should use 4 letter codes which are identical to last four letters of variables containing plausible values in the original PISA datasets. For example, math will produce results for mathematics as pv*math is the name of plausible values for mathematic literacy in all PISA datasets, while read will produce results for reading. Not specifying this option will result in estimates for variables only. {p_end}

{synopt :{opt cnt(string)}} Specifies a list of countries for which you want to obtain results. If OECD is specified, then results are provided for all OECD countries. If ALL is specified, then results are provided for all countries participating in PISA cycle. When PARTNERS is specified, then results are provided for partner non-OECD countries and economies. Results can be provided for distinct groups of countries by specifying a list with three letter ISO codes. For example, ("AUS DEU POL") will produce results for Australia, Germany, and Poland. The OECD average is calculated only when OECD or ALL is specified {p_end}

{synopt :{help prefix_saving_option:{bf:{ul:save}(}{it:filename}{bf:, ...)}}}save
	results to {it:filename}{p_end}
	
{synopt :{opt over(var)}} Specifies a categorical variable for which you want to obtain statistics by each category. The variable must be numerical with a sequence of integers denoting each category {p_end}

{syntab: Optional}


{synopt :{opt round(int)}} Specifies how many decimal places you want to see in results tables {p_end}

{synopt :{opt fast}} Specifying this option dramatically speeds up calculations at the cost of not fully valid estimates of standard errors. Statistic itself is calculated properly, however, standard errors are provided only for means using the           Stata svy linearized command. These standard errors are usually overstimated comparing to the standard BRR method. {p_end}

{synopt :{opt sas}} Specifying this option standard deviations are calculated using SAS formulas that are used for the OECD reports {p_end}

{synoptline}


{title:Description}

{pstd}
{cmd:pisastats} Calculates basic statistics with PISA data. Standard errors are obtained by using the BRR method and statistics for plausible values are calculated using all five plausible values. The command uses survey information provided in the original publicly available PISA datasets. You need to keep variables like cnt, schoolid, w_fstuwt and cnt to be able to use this command.

{title:Examples}

{pstd}

{phang2}{cmd:. pisastats scieeff, over(gender) pv(scie) cnt(POL) save(example1) round(2)} {p_end}

{phang2}{cmd:. pisastats scieeff, pv(scie) cnt(FRA) save(example2) round(2)} {p_end}

{phang2}{cmd:. pisastats scieeff, over(gender) pv(scie) cnt(AUS ARG) stats("p50 sd") save(example3) round(2)}  {p_end}

{phang2}{cmd:. pisastats scieeff, over(gender) pv(scie) cnt(ALL) save(example4) round(2)} {p_end}

{phang2}{cmd:. pisastats scieeff, pv(scie) stats("mean sd p5 p10 p25 p50 p75 p90 p95") cnt(ALL) save(example5) round(2)} {p_end}

{phang2}{cmd:. pisastats scieeff, pv(scie) cnt(ALL) save(example6) round(2) fast} {p_end}
