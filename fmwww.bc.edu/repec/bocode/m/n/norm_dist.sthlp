{smcl}
{* *! version 1.0.0 01Dec2023}{...}
{title:Title}

{p2colset 5 18 19 2}{...}
{p2col:{hi:norm dist} {hline 2}} normal and inverse normal distribution functions with added mean and standard deviation  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
The inverse cumulative standard normal distribution function using data stored in memory

{p 8 17 2}
{cmd:invnorm} {it:{help newvarname:newvarname}} [if] [in] {cmd:,} {opt p(varname)} [ {opt m:ean(varname)} {opt s:d(varname)} ] 


{pstd}
Immediate form of {cmd:invnorm}

{p 8 17 2}
{cmd:invnormi} {it:p} [{cmd:,} {opt m:ean(#)} {opt s:d(#)} ] 

{phang}
where {cmd:{it:p}} represents the significance level 


{pstd}
The cumulative standard normal distribution using data stored in memory 

{p 8 17 2}
{cmd:normd} {it:{help newvarname:newvarname}} [if] [in] {cmd:,} {opt z(varname)} [ {opt m:ean(varname)} {opt s:d(varname)} ] 


{pstd}
Immediate form of {cmd:norm}

{p 8 17 2}
{cmd:normi} {it:z} [{cmd:,} {opt m:ean(#)} {opt s:d(#)} ] 

{phang}
where {cmd:{it:z}} represents the {it:z} score 



{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:normd}
{synopt :{opt z(varname)}}variable containing the {it:z} scores; {opt required} {p_end}
{synopt :{opt m:ean(varname)}}variable containing the distribution means; default is means set at 0{p_end}
{synopt :{opt s:d(varname)}}variable containing the distribution standard deviations; default is sds set at 1{p_end}

{syntab:invnorm}
{synopt :{opt p(varname)}}variable containing the {it:p} values; {opt required} {p_end}
{synopt :{opt m:ean(varname)}}variable containing the distribution means; default is to set the means at 0{p_end}
{synopt :{opt s:d(varname)}}variable containing the distribution standard deviations; default is to set the sds at 1{p_end}

{syntab:normi and invnormi}
{synopt :{opt m:ean(#)}}specify the mean of the distribution; default is {opt mean(0)}{p_end}
{synopt :{opt s:d(#)}}specify the standard deviation of the distribution; default is {opt sd(1)}{p_end}
{synoptline}

 
{p 4 6 2}
{p2colreset}{...}				
	
{title:Description}

{pstd}
{cmd:invnorm} computes the inverse cumulative standard normal distribution function and {cmd:normd} computes the cumulative standard normal distribution, allowing
the user to specify the means and standard deviations. This extends official Stata's {help invnormal:invnormal} and {help normal:normal} functions that assume
a mean of 0 and a standard deviation of 1. {cmd:invnorm} is equivalent to R's qnorm function and {cmd:normd} is equivalent to R's pnorm function 
(see {browse "https://stat.ethz.ch/R-manual/R-devel/library/stats/html/Normal.html"}).

{pstd}
{cmd:invnormi} and {cmd:normi} are the immediate forms of {cmd:invnorm} and {cmd:normd}, respectively; see {help immed}.



{title:Examples}

{pstd}{opt invnorm} using data stored in memory{p_end}

{pmore} set-up{p_end}
{pmore2}{cmd:. clear}{p_end}
{pmore2}{cmd:. set obs 1000}{p_end}
{pmore2}{cmd:. gen p = runiform()}{p_end}
{pmore2}{cmd:. gen mean = rnormal(2,4)}{p_end}
{pmore2}{cmd:. gen sd = rnormal(4,2)}{p_end}

{pmore} generate z scores using defaults (means=0, sds=1){p_end}
{pmore2}{cmd:. invnorm zval, p(p)}{p_end}

{pmore} generate z scores specifying means and sds{p_end}
{pmore2}{cmd:. invnorm zval2, p(p) mean(mean) sd(sd)}{p_end}

{pstd}{cmd:invnormi} to specify values manually{p_end}

{pmore} using defaults; mean = 0 and sd = 1{p_end}
{pmore2}{cmd:. invnormi 0.05}{p_end}

{pmore} specifying values for mean and sd{p_end}
{pmore2}{cmd:. invnormi 0.05, m(2) s(4)}{p_end}


{pstd}{opt normd} using data stored in memory{p_end}

{pmore} set-up{p_end}
{pmore2}{cmd:. clear}{p_end}
{pmore2}{cmd:. set obs 1000}{p_end}
{pmore2}{cmd:. gen z = rnormal(0,1)}{p_end}
{pmore2}{cmd:. gen mean = rnormal(2,4)}{p_end}
{pmore2}{cmd:. gen sd = rnormal(4,2)}{p_end}

{pmore} generate p values using defaults (means=0, sds=1){p_end}
{pmore2}{cmd:. normd pval, z(z)}{p_end}

{pmore} generate p values specifying means and sds{p_end}
{pmore2}{cmd:. normd pval2, z(z) mean(mean) sd(sd)}{p_end}

{pstd}{cmd:normi} to specify values manually{p_end}

{pmore} using defaults; mean = 0 and sd = 1{p_end}
{pmore2}{cmd:. normi -1.6448536}{p_end}

{pmore} specifying values for mean and sd{p_end}
{pmore2}{cmd:. normi -1.6448536, m(2) s(4)}{p_end}



{title:Stored results}

{pstd}
{cmd:invnormi} and {cmd:normi} store the following in {cmd:r()}, respectively:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(invnorm)}}inverse cumulative standard normal distribution {p_end}
{synopt:{cmd:r(normd)}}cumulative standard normal distribution {p_end}
{p2colreset}{...}



{marker citation}{title:Citation of {cmd:norm dist}}

{p 4 8 2}{cmd:norm dist} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2023). NORM DIST: Stata module for computing normal and inverse normal distribution functions with added mean and standard deviation {p_end}


{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}{browse "mailto:alinden@lindenconsulting.org":alinden@lindenconsulting.org}{p_end}
{p 4 8 2}{browse "http://www.lindenconsulting.org"}{p_end}

         

{title:Also see}

{p 4 8 2} Online: {helpb invnormal}, {helpb normal} {p_end}

