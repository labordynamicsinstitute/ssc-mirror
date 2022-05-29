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
{opt t:argetpopulation}(A, B \ C, D) 
{opt r:esponsepopulation}(a, b \ c, d) 
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Required}

{synopt:{opt t:argetpopulation}} 2x2 table of outcome and exposure (A, B \ C, D) 
for the target population

{synopt:{opt r:esponsepopulation}} 2x2 table of outcome and exposure (a, b \ c, d) 
for the response population. 
{error: Note that all the cell values in the response population must be lower than or equal to the cell values in the target population}

{syntab:Optional}

{synopt:{opt noq:uietly}(integer)} See output from {help csi:csi} in the log

{synopt:{opt nr:esponse}(integer)} The total for the responses must be set here, when 
exposure isn't binary

{synopt:{opt nt:arget}} The total for the targets must be set here, when 
exposure isn't binary

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}{bf:rori} calculates the relative odds ratio (ROR) in a 2x2 table of 
outcome and exposure.

{pstd}{bf:rori} also calculates the Prevalence ratios of the exposure groups.
When exposure isn't binary, it is possible to specify N for the target and 
response populations. 

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

{pstd}Odds ratios are estimated using {help csi:csi}.
The standard errors for the odds ratios are from the log of the confidence interval 
bounds. 

{pstd}"Confidence intervals for the PR were found using the same simple 
approximate formula as for the ROR." (Nohr 2018)


{marker examples}{...}
{title:Examples}
{phang}{bf:When exposure is binary}{p_end}
{phang}Data are rounded and from Table 1 and Table 2 in (Austin 1981){p_end}
{phang}{stata `"rori, t(30, 63 \ 401, 2807) r(25, 45 \ 347, 2313)"'}{p_end}
{phang}To see the returned matrix:{p_end}
{phang}{stata `"matlist r(rori)"'}{p_end}
{phang}{stata `"matlist r(pr_ror)"'}{p_end}
{phang}{stata `"matlist r(pr)"'}{p_end}


{phang}{bf:When exposure is not binary}{p_end}
{phang}Consider the data:{p_end}

-----------------------------------
             |        outcome      
             |      0     1   Total
-------------+---------------------
  subgroup   |                     
    exposure |                     
      Grp1   |    330   190     520
      Grp2   |     40    60     100
      Grp3   |     70    50     120
      Total  |    440   300     740
  Total      |                     
    exposure |                     
      Grp1   |    730   230     960
      Grp2   |    150   110     260
      Grp3   |    420   250     670
      Total  |  1,300   590   1,890
-----------------------------------

{phang}The totals needs to be set to get the correct prevalence ratios when Grp2
is compared to Grp1 (reference):{p_end}
{phang}{stata `"rori, t(110, 230 \ 150, 730) r(60, 190 \ 40, 330) nt(1890) nr(740)"'}{p_end}
{phang}{stata `"matlist r(rori)"'}{p_end}
{phang}{stata `"matlist r(pr_ror)"'}{p_end}
{phang}{stata `"matlist r(pr)"'}{p_end}


{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(pru)}}The prevalence ratio (PR) of the unexposed.{p_end}
{synopt:{cmd:r(pre)}}The prevalence ratio (PR) of the exposed.{p_end}
{synopt:{cmd:r(ror)}}The relative odds ratio (ROR).{p_end}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(rori)}}Matrix with the odds ratio for the response 2x2 table of 
outcome and exposure, the odds ratio for the target 2x2 table of 
outcome and exposure, and the relative odds ratio (ROR). All with confidence interval.{p_end}
{synopt:{cmd:r(pr)}}The prevalence ratios (PR) with confidence interval.{p_end}
{synopt:{cmd:r(pr_rori)}}A combination of {cmd:r(pr)} and {cmd:r(rori)}.{p_end}

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