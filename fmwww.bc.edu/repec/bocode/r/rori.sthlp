{smcl}
{* *! version 1.0  5 Jan 2022}{...}
{viewerjumpto "Syntax" "rori##syntax"}{...}
{viewerjumpto "Description" "rori##description"}{...}
{viewerjumpto "Examples" "rori##examples"}{...}
{viewerjumpto "Author and support" "rori##author"}{...}
{viewerjumpto "References" "rori##references"}{...}
{title:Title}
{phang}
{bf:rori} {hline 2} Immediate command for estimation of selection bias through 
relative odds ratio (ROR) with large sample confidence interval

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:rori, }
{opt t:argetpopulation}(a matrix name or a matrix definition) 
{opt r:esponsepopulation}(a matrix name or a matrix definition) 
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Required}

{synopt:{opt t:argetpopulation}} a matrix name or a matrix definition of 
exposure (rows) and maybe an binary outcome (columns) for the target population

{synopt:{opt r:esponsepopulation}} a matrix name or a matrix definition of 
exposure (rows) and maybe an binary outcome (columns) for the response population. 
{error: Note that all the cell values in the response population must be lower than or equal to the cell values in the target population}

{syntab:Optional}

{synopt:{opt ref:erence}(integer)} Set reference row number in ror table


{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}{bf:rori} calculates the relative odds ratios (ROR) in a exposure by 
binary outcome table.

{pstd}{bf:rori} also calculates the ratios of relative frequencies (RRF) of 
the exposure groups.

{pstd}The key point in {cmd:rori} is that Nohr(2006) produces a formula for 
"the asymptotic variance of the difference between the estimate based on a 
random subpopulation and that based on the total population, 
Var[estimate_sub - estimate_tot] = Var[estimate_sub] - Var[estimate_tot]".

{pstd}The relative odds ratio (ROR) is used to quantify selection bias. (Nohr 2018, modified)

{pstd}"Response bias is an often neglected consideration when evaluating the 
results of epidemiologic surveys, usually because of a paucity of information 
about nonrespondents." (Austin 1981)

{pstd}"The effect of nonparticipation was described by a relative odds ratio 
(ROR), calculated as the OR (participants)/ OR (source population)" (Nohr 2006)

{pstd}"The relative odds ratio (ROR) computed as the cross product ratio of the 
participation rates in the four exposure by outcome categories" (Nohr 2018)

{pstd}In other words, the log of the relative odds ratio (ROR) is a contrast of 
the log of the participation rates in the four outcomes by exposure categories

{pstd}The method for the confidence interval was based on the observation that, 
if the subsample is a random sample from the total sample, then for large samples 
we have Var[ROR] as the square root of Var(OR response) - Var(OR target) (Nohr 2006, modified)

{pstd}"The formula (for Var[ROR]) does not hold in general, ie, 
if the subsample is not a random sample from the total sample." (Nohr 2006, modified)

{pstd}"The method of calculating confidence intervals gave almost identical 
results using non-parametric bootstrap. (Nohr 2006, modified)

{pstd}"The simple approach based on equation 1 gave 95% confidence intervals 
with coverage probabilities in the range from 94.4% to 96.0%" (Nohr 2006)


{marker examples}{...}
{title:Examples}
{phang}{bf:Immediate inputs}{p_end}
{phang}Data are rounded and from Table 1 and Table 2 in (Austin 1981){p_end}
{phang}{stata `"rori, t(30, 63 \ 401, 2807) r(25, 45 \ 347, 2313)"'}{p_end}
{phang}To see the returned matrix:{p_end}
{phang}{stata `"matlist r(ror)"'}{p_end}
{phang}{stata `"matlist r(rrf)"'}{p_end}

{phang}If there is only one column in the entered tables/matrices, only the
the ratios of relative frequencies (RRF) are returned:{p_end}
{phang}{stata `"rori, t(22193 \ 17277 \ 9065) r(7719 \ 5297 \ 2291)"'}{p_end}
{phang}To see the returned matrix:{p_end}
{phang}{stata `"matlist r(rrf)"'}{p_end}

{phang}{bf:Using datasets}{p_end}
{phang}Consider the data:{p_end}
{phang}{stata `"use highbp rural agegrp using "https://www.stata-press.com/data/r17/nhanes2.dta", clear"'}{p_end}
{phang}{error:In the following, it is wrongly assumed that the rural subpopulation is a random sample from the whole population.}{p_end}

{phang}We want to investigate whether there is selection bias for the 
age proportions in the rural population compared to whole population.{p_end}

{phang}Generate the target matrix (age distribution for the whole population):{p_end}
{phang}{stata `"tab agegrp, matcell(tgtage)"'}{p_end}
{phang}{stata `"matrix rownames tgtage = 20- 30- 40- 50- 60- 70+"'}{p_end}
{phang}{stata `"matrix colnames tgtage = n"'}{p_end}

{phang}Generate the response matrix (age distribution for the rural population):{p_end}
{phang}{stata `"tab agegrp if rural, matcell(rspage)"'}{p_end}
{phang}{stata `"matrix rownames rspage = 20- 30- 40- 50- 60- 70+"'}{p_end}
{phang}{stata `"matrix colnames rspage = n"'}{p_end}

{phang}Use {cmd:rori} to get the ratios of relative frequencies (RRF) with 
confidence intervals{p_end}
{phang}{stata `"rori, t(tgtage) r(rspage)"'}{p_end}
{phang}{stata `"matlist r(rrf)"'}{p_end}

{phang}We want to investigate whether there is selection bias for the effect 
(odds ratio) of age proportions on high blood pressure limiting data to the 
rural part of the whole population.{p_end}

{phang}Generate the target matrix (age distribution by high blood pressure for 
the whole population):{p_end}
{phang}{stata `"tab agegrp highbp, matcell(tgtage)"'}{p_end}
{phang}{stata `"matrix rownames tgtage = 20- 30- 40- 50- 60- 70+"'}{p_end}
{phang}{stata `"matrix colnames tgtage = no yes"'}{p_end}
{phang}Generate the target matrix (age distribution by high blood pressure for 
the rural population):{p_end}
{phang}{stata `"tab agegrp highbp if rural, matcell(rspage)"'}{p_end}
{phang}{stata `"matrix rownames rspage = 20- 30- 40- 50- 60- 70+"'}{p_end}
{phang}{stata `"matrix colnames rspage = n yes"'}{p_end}
{phang}Use {cmd:rori} to get the relative odds ratios (ROR) with 
confidence intervals{p_end}
{phang}{stata `"rori, t(tgtage) r(rspage)"'}{p_end}
{phang}{stata `"matlist r(ror)"'}{p_end}
{phang}{cmd:rori} also returns the ratios of relative frequencies (RRF) by 
outcome values with confidence intervals{p_end}
{phang}{stata `"matlist r(rrf)"'}{p_end}
{phang}As a default the reference row for relative odds ratios (ROR) is the 
first. With option {opt ref:erence}(integer) another reference row can be chosen.
Row 3 is chosen beow:{p_end}
{phang}{stata `"rori, t(tgtage) r(rspage) ref(3)"'}{p_end}
{phang}{stata `"matlist r(ror)"'}{p_end}
{phang}The ratios of relative frequencies (RRF) are unchanged by this option.{p_end}
{phang}{stata `"matlist r(rrf)"'}{p_end}


{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(ror)}}Matrix with the odds ratios exposure by outcome table 
for the response, the odds ratios exposure by outcome table 
for the target, and the relative odds ratio (ROR). 
All with confidence interval.{p_end}
{synopt:{cmd:r(rrf)}}The ratios of relative frequencies (RRF) with confidence 
intervals.{p_end}


{marker author}{...}
{title:Author and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Author:}{break}
 	Victoria Petrine Lindblad Nielsen, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}

{marker references}{...}
{title:References}

{pstd}Austin MA, Criqui MH, Barrett-Connor E, Holdbrook MJ. 
The effect of response bias on the odds ratio. 
Am J Epidemiol. 1981;114:137–43

{pstd}Nohr EA, Frydenberg M, Henriksen TB, Olsen J. 
Does low participation in cohort studies induce bias? 
Epidemiology. 2006;17:413–8

{pstd}Nohr EA, Liew Z. 
How to investigate and adjust for selection bias in cohort studies. 
Acta Obstet Gynecol Scand. 2018 Apr;97(4):407-41