{smcl}
{* 26JAN2022}{...}

{title:Title}

{pstd}{hi:hazdcmp} {hline 2}  multivariate decomposition for piecewise constant hazard rate models


{title:Description}

{pstd}
{cmd: hazdcmp} extends the Oaxaca-Blinder decomposition to decompose a group difference 
in hazard rates into components reflecting the portion of the difference attributable to group differences in characteristics (endowments) 
and to group differences in effects (coefficients) as well as the detailed (multivariate) 
decomposition results as described by Powers and Yun (2009). 

{pstd}
Input to {cmd: hazdcmp} is assumed to be in the form of split-episode data (see {helpb stsplit}) 
with a binary dependent variable coded 0 for a censored episode and 1 for an event 
along with a set of independent variables (including dummy variables for the episode-specific risks) 
and an offset. Models are fit without the constant term to accommodate 
all the baseline hazard components. Different specifications of the baseline hazard may require 
that the user include their own constant term. 

{title:Syntax}

{p 8 16 2}
{cmd:hazdcmp} {depvar} {indepvars} [, {it:options} ]  {cmdab:by(}{it:groupvar}{cmd:)} {cmdab:id(}{it:idvar}{cmd:)} {cmdab:offset(}{it:offvar}{cmd:)} 
{p_end}

{p 4 4 2} where

{p 8 16 2} {cmd:by(}{it:groupvar}{cmd:)} specifies a binary variable coded 0 or 1 identifying the two groups;

{p 8 16 2} {cmd:id(}{it:idvar}{cmd:)} specifies the id number associated with the {it:person-level} record (see, e.g., {helpb stsplit});

{p 8 16 2} {cmd:offset(}{it:offvar}{cmd:)} specifies the required logged exposure time for the continuous-time model, i.e., log(_t - _t0) or 0 (or logged time-interval width) for the discrete-time model (see, e.g., {helpb stsplit});

{synoptset 25 tabbed}{...}
{marker opt}{synopthdr:options}
{synoptline}
{synopt :{opt reverse}}reverse decomposition by swapping groups
    {p_end}
{synopt :{opt scale(real)}}multiply coefficients and standard errors by a scaling factor [default scale(1)]
    {p_end}
{synopt :{opt discrete}}fit a discrete-time logit hazard model. [default continuous-time (piecewise-constant exponential hazard model]
    {p_end} 
  
{cmd:robust} and {cmd:cluster} are supported (see {help robust} and {help cluster}).

{title:Example}

{p 0 15 2}
{title:hazard rate regression decomposition}
{p_end}

{pstd} hazdcmp devnt a1-a6 pctsmom nfamtran medu inc1000 nosibs magebir, by(blk) id(iid) offset(logexp) scale(1000)

{pstd} hazdcmp devnt a1-a6 pctsmom nfamtran medu inc1000 nosibs magebir, by(blk) id(iid) offset(logone) scale(100) discrete

{title:Saved Results}
{pstd}

{cmd:hazdcmp} saves the following matrices in {cmd:e()}:

{synoptset 15 tabbed}{...}
{synopt:{cmd:e(bE)}} unscaled estimates of detailed E component
    {p_end}
{synopt:{cmd:e(VE)}} unscaled variance/covariance matrix of detailed E component
    {p_end}
{synopt:{cmd:e(bC)}} unscaled estimates of detailed C component
    {p_end}
{synopt:{cmd:e(VC)}} unscaled variance/covariance matrix of detailed C component
    {p_end}
{synopt:}
    {p_end}

{title:References}

{phang} Powers, Daniel A. and Myeong-Su Yun (2009). “Multivariate Decomposition for Hazard Rate Models.”  {it:Sociological Methodology}, 39: 233-263.
{p_end}

{title:Authors}

{p 4 4 2}Daniel A. Powers, University of Texas at Austin, dpowers@austin.utexas.edu
{p_end}
{p 4 4 2}Hirotoshi Yoshioka, University of Texas at Austin, hiro12@prc.utexas.edu
{p_end}

{title: Also see}

{p 4 13 2} Online help for {helpb mvdcmp}
{p_end}

