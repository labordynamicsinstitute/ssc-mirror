{smcl}
{* *! version 1.0.0 16Jul2024}{...}
{title:Title}

{p2colset 5 22 23 2}{...}
{p2col:{hi:halfnorm dist} {hline 2}} half-normal distribution functions {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
The half-normal density distribution function using data stored in memory

{p 8 17 2}
{cmd:halfnormden} {it:{help newvarname:newvarname}} [if] [in] {cmd:,} {opt x(varname)} [ {opt th:eta(varname)} {opt m:ean(varname)} {opt s:d(varname)} ] 

{pstd}
Immediate form of {cmd:halfnormden}

{p 8 17 2}
{cmd:halfnormdeni} {it:x} [{cmd:,} {opt th:eta(#)} {opt m:ean(#)} {opt s:d(#)} ] 

{phang}
where {cmd:{it:x}} is the value to be evaluated


{pstd}
The inverse cumulative standard half-normal distribution function using data stored in memory

{p 8 17 2}
{cmd:halfinvnorm} {it:{help newvarname:newvarname}} [if] [in] {cmd:,} {opt p(varname)} [ {opt th:eta(varname)} {opt m:ean(varname)} {opt s:d(varname)} ] 

{pstd}
Immediate form of {cmd:halfinvnorm}

{p 8 17 2}
{cmd:halfinvnormi} {it:p} [{cmd:,} {opt th:eta(#)} {opt m:ean(#)} {opt s:d(#)} ] 

{phang}
where {cmd:{it:p}} represents the significance level 


{pstd}
The cumulative standard half-normal distribution using data stored in memory 

{p 8 17 2}
{cmd:halfnorm} {it:{help newvarname:newvarname}} [if] [in] {cmd:,} {opt z(varname)} [  {opt th:eta(varname)} {opt m:ean(varname)} {opt s:d(varname)} ] 

{pstd}
Immediate form of {cmd:halfnorm}

{p 8 17 2}
{cmd:halfnormi} {it:z} [{cmd:,} {opt th:eta(#)} {opt m:ean(#)} {opt s:d(#)} ] 

{phang}
where {cmd:{it:z}} represents the {it:z} score 



{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:halfnormden}
{synopt :{opt x(varname)}}variable containing the {it:x} values to be evaluated; {opt required} {p_end}
{synopt :{opt th:eta(varname)}}variable containing the {it:theta} parameter values; default is sqrt(pi/2) {p_end}
{synopt :{opt m:ean(varname)}}variable containing the distribution means; default is means set at 0 {p_end}
{synopt :{opt s:d(varname)}}variable containing the distribution standard deviations; default is sd set at 1 {p_end}

{syntab:halfinvnorm}
{synopt :{opt p(varname)}}variable containing the {it:p} values; {opt required} {p_end}
{synopt :{opt th:eta(varname)}}variable containing the {it:theta} parameter values; default is sqrt(pi/2) {p_end}
{synopt :{opt m:ean(varname)}}variable containing the distribution means; default is means set at 0 {p_end}
{synopt :{opt s:d(varname)}}variable containing the distribution standard deviations; default is sd set at 1 {p_end}

{syntab:halfnorm}
{synopt :{opt z(varname)}}variable containing the {it:z} scores; {opt required} {p_end}
{synopt :{opt th:eta(varname)}}variable containing the {it:theta} parameter values; default is sqrt(pi/2) {p_end}
{synopt :{opt m:ean(varname)}}variable containing the distribution means; default is means set at 0 {p_end}
{synopt :{opt s:d(varname)}}variable containing the distribution standard deviations; default is sd set at 1{p_end}

{syntab:halfnormdeni, halfinvnormi, halfnormi}
{synopt :{opt th:eta(#)}}specify the {it:theta} parameter value; default is sqrt(pi/2) {p_end}
{synopt :{opt m:ean(#)}}specify the mean of the distribution; default is {opt mean(0)} {p_end}
{synopt :{opt s:d(#)}}specify the standard deviation of the distribution; default is {opt sd(1)} {p_end}
{synoptline}

 
{p 4 6 2}
{p2colreset}{...}				
	
{title:Description}

{pstd}
{cmd:halfnormden} computes the half-normal density distribution function, {cmd:halfinvnorm} computes the inverse cumulative standard half-normal distribution function, 
and {cmd:halfnorm} computes the cumulative standard half-normal distribution. The half-normal distribution is a Normal distribution truncated to only have a nonzero 
density for values to the right of the peak. In the half-normal distribution, the parameter {it:theta} is related to the standard deviation (sd) of the corresponding normal 
distribution by the equation {it:theta} = sqrt(pi/2)/sd. The default {it:theta} is sqrt(pi/2) which corresponds to sd = 1. 
(see {browse "https://en.wikipedia.org/wiki/Half-normal_distribution"}).

{pstd}
{cmd:halfnormdeni}, {cmd:halfinvnormi} and {cmd:halfnormi} are the immediate forms of {cmd:halfnormden}, {cmd:invnorm} and {cmd:normd}, respectively; see {help immed}.



{title:Examples}
{synoptline}
{pstd}{opt halfnormden} using data stored in memory{p_end}

{pmore} set-up{p_end}
{pmore2}{cmd:. clear}{p_end}
{pmore2}{cmd:. set obs 501}{p_end}
{pmore2}{cmd:. gen x = 0 + (_n - 1) * .01}{p_end}

{pmore} compute half-normal density distribution using defaults of mean = 0, sd = 1 and graph results{p_end}
{pmore2}{cmd:. halfnormden halfnormden, x(x)}{p_end}
{pmore2}{cmd:. line halfnormden x}{p_end}

{pmore} compute normal density distribution for comparison and graph results{p_end}
{pmore2}{cmd:. gen x2 = -5 + (_n - 1) * .02}{p_end}
{pmore2}{cmd:. gen normden = normalden(x2)}{p_end}
{pmore2}{cmd:. tw(line halfnormden x)(line normden x2)}{p_end}

{pstd}{cmd:halfnormdeni} to specify values manually{p_end}

{pmore} using defaults; mean = 0 and sd = 1{p_end}
{pmore2}{cmd:. halfnormdeni 0.10}{p_end}

{pmore} set mean = 2 and sd = 4{p_end}
{pmore2}{cmd:. halfnormdeni 0.10, m(2) s(4)}{p_end}
{synoptline}
{pstd}{opt halfinvnorm} using data stored in memory{p_end}

{pmore} set-up{p_end}
{pmore2}{cmd:. clear}{p_end}
{pmore2}{cmd:. set obs 501}{p_end}
{pmore2}{cmd:. gen p = 0 + (_n - 1) * .002}{p_end}

{pmore} compute inverse half-normal density distribution using defaults of mean = 0, sd = 1 and graph results{p_end}
{pmore2}{cmd:. halfinvnorm halfinvnorm, p(p)}{p_end}
{pmore2}{cmd:. line halfinvnorm p}{p_end}

{pmore} generate values specifying means and sds{p_end}
{pmore2}{cmd:. generate mean = 2}{p_end}
{pmore2}{cmd:. generate sd = 4}{p_end}
{pmore2}{cmd:. halfinvnorm halfinvnorm2, p(p) mean(mean) sd(sd)}{p_end}

{pstd}{cmd:halfinvnormi} to specify values manually{p_end}

{pmore} using defaults; mean = 0 and sd = 1{p_end}
{pmore2}{cmd:. halfinvnormi 0.50}{p_end}

{pmore} specifying values for mean and sd{p_end}
{pmore2}{cmd:. halfinvnormi 0.50, m(2) s(4)}{p_end}
{synoptline}
{pstd}{opt halfnorm} using data stored in memory{p_end}

{pmore} set-up{p_end}
{pmore2}{cmd:. clear}{p_end}
{pmore2}{cmd:. set obs 501}{p_end}
{pmore2}{cmd:. gen z = 0 + (_n - 1) * .01}{p_end}

{pmore} compute cumulative standard half-normal distribution using defaults of mean = 0, sd = 1 and graph results{p_end}
{pmore2}{cmd:. halfnorm halfnorm, z(z)}{p_end}
{pmore2}{cmd:. line halfnorm z}{p_end}

{pmore} compute cumulative standard normal distribution for comparison and graph results{p_end}
{pmore2}{cmd:. gen z2 = -5 + (_n - 1) * .02}{p_end}
{pmore2}{cmd:. gen normal = normal(z2)}{p_end}
{pmore2}{cmd:. tw(line halfnorm z)(line normal z2)}{p_end}

{pstd}{cmd:halfnormi} to specify values manually{p_end}

{pmore} using defaults; mean = 0 and sd = 1{p_end}
{pmore2}{cmd:. halfnormi 1.2}{p_end}

{pmore} specifying values for mean and sd{p_end}
{pmore2}{cmd:. halfnormi 1.2, m(0) s(4)}{p_end}
{synoptline}


{title:Stored results}

{pstd}
{cmd:halfnormdeni}, {cmd:halfinvnormi} and {cmd:halfnormi} store the following in {cmd:r()}, respectively:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(halfnormden)}}half-normal density distribution {p_end}
{synopt:{cmd:r(halfinvnorm)}}inverse cumulative standard half-normal distribution {p_end}
{synopt:{cmd:r(halfnorm)}}cumulative standard half-normal distribution {p_end}
{p2colreset}{...}



{marker citation}{title:Citation of {cmd:halfnorm dist}}

{p 4 8 2}{cmd:halfnorm dist} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2024). HALFNORM DIST: Stata module for computing half-normal distribution functions {p_end}


{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC {p_end}
{p 4 8 2}	alinden@lindenconsulting.org {p_end}

         

{marker acknowledgments}{...}
{title:Acknowledgments}

{p 4 4 2}
I wish to thank John Moran for advocating that I write this package.

		 
		 
{title:Also see}

{p 4 8 2} Online: {helpb normalden()}, {helpb invnormal()}, {helpb normal()}, {helpb norm dist} (if installed) {p_end}

