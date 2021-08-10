{smcl}
{* *! version 1.1 30may2017}{...}
{cmd:help screen}
{hline}

{title:Title}

{phang}
{bf:screen} {hline 2} Screens observations that meet specific distributional criteria in terms
of percentile, standard deviation or interquartile range, and generates a binary variable equal to 1 if the 
observation meets the criteria and equal to 0 if it does not.


{title:Syntax}

{p 8 17 2}
{cmdab:screen}
{varlist}
{ifin}
[{cmd:,} {it:options}]


{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth t:ype(string)}}specifies type of sceening; options are:
		{opt t:ype(per|sd|iqr)}{p_end}
{synopt:{opt l:ower(#)}}specifies lower tail screening threshold; 
		e.g.: {opt l:ower(0.1)}{p_end}
{synopt:{opt u:pper(#)}}specifies upper tail screening threshold;
		e.g.: {opt u:pper(3)}{p_end}	
{syntab:Options}
{synopt:{opt i:ter(#)}}specifies number of screening iterations; only an option			
		for {opt t:ype(sd)}{p_end}
{synopt:{opt g:en(#)}}if {opt g:en(1)} clone of {varlist} is 
		generated and screened observations are replaced with the non-screened tail-end 
		values; if {opt g:en(2)} clone of {varlist} is generated and 
		screened observations are replaced with the mean if {opt t:ype(per|sd)} 
		and the median if {opt t:ype(iqr)}; if {opt g:en(3)} clone of {varlist} is 
		generated and screened observations are replaced with missing values{p_end}
{synopt:{opth s:econd(varlist)}}specifies second level variable screening; calculates 
		summary statistics of second level variables excluding first level screened 
		observations, before screening at the second level{p_end}

{title:Description}

{pstd}
{cmd:screen} identifies observations that meet specific distributional criteria in terms of percentile, 
standard deviation or interquartile range, and generates a binary variable equal to 1 if the 
observation meets the criteria and equal to 0 if it does not. For example, screen 
can identify observations that lie more than 3 standard deviations above and below the mean, observations that 
are above the 99.9th percentile, or observations that are 1.5 IQR above the third quartile (Q3). 
The command {cmd:screen} can be two-tailed or one-tailed by specifying {opt l:ower(#)} and/or {opt u:pper(#)}. 
The option {opt g:en(#)} generates a clone variable for each variable in your {varlist} and replaces screened 
observations with the non-screened tail-end values, the mean or median, or missing values. The option {opth s:econd(varlist)} 
allows sequential ordered screening by screening second level variables after screening a first level variable.
The option {opt i:ter(#)} runs multiple standard deviation screening iterations. This module is useful 
for screening distributional outliers. 


{title:Options}	

{dlgtab:Main}

{phang}
{opt t:ype(per|sd|iqr)} specifies that observations should be screened in terms of upper and/or lower
tail percentiles, standard deviations above and/or below the mean, or in terms of location beyond the
IQR fences.

{phang}
{opt l:ower(#)}	specifies the bottom tail screening threshold. If {opt l:ower(2)} and {opt t:ype(per)}, 
{cmd:screen} identifies observations below the 2nd percentile in terms of {varlist}; if {opt t:ype(sd)}, 
{cmd:screen} identifies observations that are more than 2 standard deviations below the mean; if 
{opt t:ype(iqr)}, {cmd:screen} identifies observations that are more than 2 interquartile range (IQR, 
distance from Q1 to Q3) below the first quartile (Q1, the 25th percentile). 

{phang}
{opt u:pper(#)}	specifies the top tail screening threshold. If {opt u:pper(2)} and {opt t:ype(per)}, 
{cmd:screen} identifies observations above the 98th percentile in terms of {varlist}; if {opt t:ype(sd)}, 
{cmd:screen} identifies observations that are more than 2 standard deviations above the mean; if 
{opt t:ype(iqr)}, {cmd:screen} identifies observations that are more than 2 interquartile range (IQR, 
distance from Q1 to Q3) above the third quartile (Q3, the 75th percentile).

{dlgtab:Options}

{phang}	
{opt i:ter(#)} specifies the number of screening iterations and is only an option for {opt t:ype(sd)}.
If {opt i:ter(2)} and {opt l:ower(2)}, {cmd:screen} identifies observations that are more than 2 
standard deviations below the mean, recalculates the mean and standard deviation excluding 
observations from the first iteration and reidentifies observations that are more than 2 standard deviations
below the mean. Useful when extreme outliers distort the first iteration mean and standard deviation statistics.

{phang}	
{opt g:en(#)} generates a clone variable of {varlist} and replaces screened observations with the non-screened tail-end
values if {opt g:en(1)}, with the mean if {opt g:en(2)} or with the median if {opt g:en(2)} and 
{opt t:ype(iqr)}, or with missing values if {opt g:en(3)}. If {opt g:en(1)}, {opt t:ype(per)}, {opt l:ower(2)} and  {opt u:pper(3)}, {cmd:screen}
generates a clone variable, identifies observations below the 2nd percentile and above the 97th percentile and replaces 
these with, respectively, the closest non-screened observation value to the 2nd and 97th percentile value. When {opt g:en(2)}
is stated the mean and median are calculated excluding screened observations. 

{phang}	
{opth s:econd(varlist)} specifies a second level {varlist} that should be screened after a first level variable screening. 
Summary statistics are estimated for second level variables excluding observations screened at the first level. A
screen variable is generated for both first and second level variables. Nota bene, screened observations at level one are not
necessarily screened at level two. If daily food consumption in grams is a level one variable, and caloric intake is 
a level two variable, a consumption of 5,000 grams of cucumber is likely screened at the first level, but not necessarily
at the second level given the low calorific content of cucumbers. If the user wishes to exclude all level one screened observations 
the user must specify the command {cmd:screen} using the {opt if} condition.

{title:Example}	

{phang}{cmd:. screen expenditure_percapita, type(sd) lower(3) upper(3) iter(2)}{p_end}

{phang}{cmd:. screen grams_consumed, t(per) u(2.5) gen(1) second(caloric_intake iron_intake protein_intake)}{p_end} 
{phang}{cmd:. screen caloric_intake if poor==1, t(iqr) l(3) u(1.5) g(2)}{p_end} 

{title:Author}

{pstd}
Marco Santacroce, International Food Policy Research Institute, Washington DC, USA (marcosantacroce.it@gmail.com)

{title:Citation}

{phang}	
Santacroce, Marco (2017).
screen: STATA command to identify observations that meet specific distributional criteria.

{phang}
