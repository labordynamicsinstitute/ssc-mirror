{smcl}
{* *! version 1.0 31 Maj 2022}{...}
{vieweralsosee "Help cwmglm (if installed)" "help cwmglm"}{...}
{p2col:{bf:cwmglm} }Postestimation tools for cwmglm{p_end}

{marker description}{...}
{title:Postestimation commands}

{pstd}
{cmd:cwmglm} allows {cmd: predict} and {cmd: cwmbootstrap}.



{marker des_predict}{...}
{title:Description for predict}

{pstd}
{cmd:predict} creates a new variable containing group memberships based on the 
{it: maximum a posteriori probabilities} (MAP). Observations are assigned to mixture components if the posterior probability is maximum.

{marker syn_predict}{...}
{title:Syntax for predict}
{cmd: predict} {it: {help varname: varname}}

{marker des_predict}{...}
{title:Description for cwmbootstrap}

{pstd}
{cmd:predict} displays non parametric bootstrap estimates and standard error for the last cwm in memory.


{marker syntax_cwmboostrap}{...}
{title:Syntax for cwmbootstrap}
{p 8 17 2}

{cmdab:cmwbootstrap} , [nreps(#)]

{synoptset 82 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Optional}
{synopt:{opt nreps} (#)}  Number of bootstrap replications. Default is 100 {p_end}

{cmd: cwmbootstrap}  uses returned results of {cmd: cwmglm} to obtain bootstrap standard errors for the following estimates:

{phang} e(b)            coefficient vector of the glm {p_end}
{phang} e(p_multi_#)    probabilities of a each outcome for the xmultinomial variables . {p_end}
{phang} e(p_binomial)   probabilities of a positive outcome for the xbinomial variables {p_end}	  
{phang} e(lambda)       mean of the xpoisson variables {p_end}	  
{phang} e(mu)           mean of the xnorm variables {p_end} 	

{cmd: cwmbootstrap} returns the following results:

{phang} r(b) inference table for e(b) 	 {p_end} 	   
{phang} r(p_multi) inference table for e(p_multi_#)  {p_end} 	  
{phang} r(p_binomial) inference table for e(p_binomial) {p_end} 	  
{phang} r(lambda) inference table for e(lambda) {p_end} 	  
{phang} r(mu) inference table for e(mu) {p_end} 	  

{marker example_s}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2} {cmd:. use students, clear}    

{pstd}Mixture of regressions with random covariates, model VVV{p_end}
{phang2} {cmd:. cwmglm weight height heightf,  k(2)  posterior(z) xnormal(height heightf) vvv  }

{pstd}Predict MAP{p_end}
{phang2} {cmd:. predict cluster}

{pstd}Bootstrap{p_end}
{phang2} {cmd:. cwmbootstrap, nreps(1000)}

