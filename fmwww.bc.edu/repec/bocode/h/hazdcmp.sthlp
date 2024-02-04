{smcl}
{* 26JUN2023}{...}

{title:Title}

{pstd}{hi:hazdcmp} {hline 2}  multivariate decomposition for hazard rate models


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

{pstd}
Returned results facilitate add-hoc manipulations, such as averaging results from decompositions  with different choices of reference group (shown below).

{title:Syntax}

{p 8 16 2}
{cmd:hazdcmp} {depvar} {indepvars} [aw iw pw fw] [, {it:options} ]  {cmdab:by(}{it:groupvar}{cmd:)} {cmdab:id(}{it:idvar}{cmd:)} {cmdab:offset(}{it:offvar}{cmd:)} 
{p_end}

{p 4 4 2} where

{p 8 16 2} {cmd:by(}{it:groupvar}{cmd:)} specifies a binary variable coded 0 or 1 identifying the two groups;

{p 8 16 2} {cmd:id(}{it:idvar}{cmd:)} specifies the id number associated with the {it:person-level} record (see, e.g., {helpb stset});

{p 8 16 2} {cmd:offset(}{it:offvar}{cmd:)} specifies the required logged exposure time for continuous-time models, i.e., log(_t - _t0) or 0 (or logged time-interval width) for discrete-time models (see, e.g., {helpb stsplit});

{synoptset 25 tabbed}{...}
{marker opt}{synopthdr:options}
{synoptline}
{synopt :{opt reverse}}reverse decomposition by swapping groups.
    {p_end}
{synopt :{opt scale(real)}}multiply coefficients and standard errors by a scaling factor [default scale(1)].
    {p_end}
{synopt :{opt discrete(string)}}fit a discrete-time hazard model where string is logit or cloglog [default continuous-time (piecewise-constant exponential) hazard model].
    {p_end} 
{col 6} {cmd:aweight}, {cmd:iweight}, {cmd:pweight}, and {cmd:fweight}s are allowed (see {helpb weight}); {opt robust} and {opt cluster} are supported (see {helpb robust} and {helpb cluster}).
    

{title:Example: Hazard Rate Regression Decomposition (continuous and discrete time) }


{pstd} hazdcmp devnt a1-a6 pctsmom nfamtran medu inc1000 nosibs magebir, by(blk) id(iid) offset(logexp) scale(1000)

{pstd} hazdcmp devnt a1-a6 pctsmom nfamtran medu inc1000 nosibs magebir, by(blk) id(iid) offset(logone) scale(100) discrete(logit)



{title:Example: Averaging over Decompositions with Different Reference Groups}


{col 8} // vignette #1 (combining results of two decompositions with difference reference groups)
{col 8} // (combining results of two decompositions with difference reference groups)
{col 8}
{col 8} // model from group A's perspective (group A as standard)
{col 8} hazdcmp devnt a1-a6 pctsmom nfamtran medu inc1000 nosibs magebir, ///
{col 12}      by(blk) id(iid) offset(logexp) scale(1000) 
{col 8} local vnames  "`e(cvarlist)'"   // get complete list of varnames
{col 8}
{col 8} mat bA = e(b)
{col 8} mat VA = e(V)
{col 8}
{col 8} // model from group B's perspective (group B as standard)
{col 8} hazdcmp devnt a1-a6 pctsmom nfamtran medu inc1000 nosibs magebir, ///
{col 12}      by(blk) id(iid) offset(logexp) scale(1000) reverse  
{col 8}
{col 8} mat bB = e(b)
{col 8} mat VB = e(V)	
{col 8}  
{col 8} mata:
{col 8}  b0   = st_matrix("bA")
{col 8}  V0   = st_matrix("VA")
{col 8}  b1   = st_matrix("bB")
{col 8}  V1   = st_matrix("VB")
{col 8}  s   = 1000  // scale factor 
{col 8}// sign change for averaging
{col 8}  b    =  s * (b0 - b1)/2
{col 8}  V    = s^2 * (V0 + V1):/4 
{col 8}  k    = cols(b)
{col 8}  bE   = sum(b[1..k/2])
{col 8}  bC   = sum(b[k/2..k])
{col 8}  VE   = sum(V[1..k/2,1..k/2])
{col 8}  VC   = sum(V[k/2..k, k/2..k])
{col 8}  bR   = bE, bC, bE + bC
{col 8}  T    = VE,VC,(VE + VC)
{col 8}  VR   = diag(T)
{col 8} st_matrix("b", b)
{col 8} st_matrix("V", V)
{col 8} st_matrix("bR", bR)
{col 8} st_matrix("VR", VR)
{col 8} st_matrix("VR", VR)
{col 8} end
{col 8}
{col 8} matrix colnames b = `vnames'
{col 8} matrix colnames V = `vnames'
{col 8} matrix rownames V = `vnames'
{col 8} matrix colnames bR = E C Total
{col 8} matrix colnames VR = E C Total
{col 8} matrix rownames VR = E C Total
{col 8} 
{col 8} eret post b V , depname("Averaged")
{col 8} eret display, cformat(%6.5f) level(95)
{col 8} eret post bR VR, depname("Total")
{col 8} eret display,  cformat(%6.5f) level(95)


{title:Saved Results}
{pstd}

{cmd:hazdcmp} saves the following macros:

{synoptset 15 tabbed}{...}
{synopt:{cmd:e(indvars)}}  a list of independent variables input to {cmd:hazdcmp} (i.e., the model's varlist)
    {p_end}
{synopt:{cmd:e(depvar)}}  dependent variable
    {p_end}
{synopt:{cmd:e(scale)}}  scaling value
    {p_end}
{synopt:{cmd:e(cvarlist)}}  list of coefficient names in output table of {cmd:hazdcmp}
    {p_end}

{cmd:hazdcmp} saves the following matrices in {cmd:e()}:

{synoptset 15 tabbed}{...}
{synopt:{cmd:e(b)}} unscaled estimates
    {p_end}
{synopt:{cmd:e(V)}} unscaled variance/covariance matrix of estimates
    {p_end}
{synopt:}
    {p_end}

{title:References}

{phang} Powers, Daniel A. and Myeong-Su Yun (2009). “Multivariate Decomposition for Hazard Rate Models.”  {it:Sociological Methodology}, 39: 233-263.
{p_end}

{title:Authors}

{p 4 4 2}Daniel A. Powers, University of Texas at Austin, dpowers@austin.utexas.edu
{p_end}
{p 4 4 2}Myeong-Su Yun, Inha University, msyun@inha.ac.kr
{p_end}
{p 4 4 2}Hirotoshi Yoshioka, University of Texas at Austin, hiro12@prc.utexas.edu
{p_end}

{title: Also see}

{p 4 13 2} Online help for {helpb mvdcmp}
{p_end}

