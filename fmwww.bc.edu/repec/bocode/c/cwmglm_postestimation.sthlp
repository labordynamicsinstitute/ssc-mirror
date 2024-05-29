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
{cmd:predict} creates group memberships based on the posterior probabilities or on the {it: maximum a posteriori probabilities} (MAP). The latter estimator assigns to the mixture component with the largest posterior probability.

{marker syn_predict}{...}
{title:Syntax for predict}
{pstd}{cmd: predict} have two alternate syntaxes{p_end}
{p 8 17 2}
{cmd: predict} {it: {help stub: stub}}, {cmd: posterior}  calculates posterior latent class probability. It creates a number of variables equal to the number of latent classes in the model. Each variable is named according to {it: stub}. 

{p 8 17 2}
{cmd: predict} {it: {help varname: varname}}, {cmd: map}  calculates a single variable containing MAP group memberships. 

{marker des_bootstrap}{...}
{title:Description for cwmbootstrap}

{pstd}
{cmd:cwmbootstrap} calculates bootstrap standard errors for the last cwm estimates in memory. {cmd: cwmbootstrap}  uses returned results of {cmd: cwmglm} to obtain bootstrap standard errors for the following estimates:{p_end}
{phang2} {cmd: e(b)}            coefficient vector of the glm {p_end}
{phang2} {cmd: e(p_multi_#)}    probabilities of a each outcome for the xmultinomial variables {p_end}
{phang2} {cmd: e(p_binomial)}   probabilities of a positive outcome for the xbinomial variables {p_end}
{phang2} {cmd: e(lambda)}       mean of the xpoisson variables {p_end}
{phang2} {cmd: e(mu)}           mean of the xnorm variables {p_end}

{marker syntax_cwmboostrap}{...}
{title:Syntax for cwmbootstrap}
{pstd}
{cmd:cwmbootstrap} , [reps(#)]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Optional}
{synopt:{opt reps} (#)}  Number of bootstrap replications. Default is 100 {p_end}

{title:Returned results for cwmbootstrap}
{pstd}{cmd: cwmbootstrap} returns the following results:{p_end}
{phang2} {cmd: r(b)} inference table for e(b) {p_end}
{phang2} {cmd: r(p_multi)} inference table for e(p_multi_#) {p_end}
{phang2} {cmd: r(p_binomial)} inference table for e(p_binomial) {p_end}
{phang2} {cmd: r(lambda)} inference table for e(lambda) {p_end}
{phang2} {cmd: r(mu)} inference table for e(mu) {p_end}



{marker des_compare}{...}
{title:Description for cwmcompare}

{pstd}
{cmd:cwmbootstrap} calculates AIC and BIC for nesting CWMs.{p_end}


{marker syntax_cwmcompare}{...}
{title:Syntax for cwmcompare}
{pstd}
{cmd:cwmbootstrap } {it: namelist}{p_end} 
{phang} where {it: namelist} is a list of estimates calculated with {cmd: cwmglm} and saved using {cmd: estimates store} {p_end}

{title:Returned results for cwmcompare}
{pstd}{cmd: cwmcompare} returns the following results:{p_end}
{phang2} {cmd: r(table)} the information criteria table for the different estimates {p_end}
{phang2} {cmd: r(bestAIC)} the estimate name of the model with the minimum AIC {p_end}
{phang2} {cmd: r(bestBIC)} the estimate name of the model with the minimum BIC {p_end}
{marker example_s}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2} {cmd:. use students, clear}    

{pstd}Mixture of regressions with random covariates, model VVV{p_end}
{phang2} {cmd:. cwmglm weight height heightf,  k(2)  xnormal(height heightf) vvv  }

{pstd}Predict posterior class memberships. Note that 2 variables are predicted: cluster1 and cluster2{p_end}
{phang2} {cmd:. predict cluster, posterior}

{pstd}Predict MAP{p_end}
{phang2} {cmd:. predict cluster, map}

{pstd}Bootstrap{p_end}
{phang2} {cmd:. cwmbootstrap, nreps(1000)}

{pstd}Comparing a CWM and a finite mixture model{p_end}
{phang2} {cmd:. cwmglm weight height heightf,  k(2)  xnormal(height heightf) vvv  }

{phang2} {cmd:. estimates store cwm}

{phang2} {cmd:. cwmglm weight height heightf,  k(2)  vvv  }

{phang2} {cmd:. estimates store fmm}

{phang2} {cmd:. cwmcompare cwm fmm}

{title:Authors}

{phang} Daniele Spinelli, corresponding author (University of Milano-Bicocca, daniele.spinelli@unimib.it) {p_end}
{phang} Salvatore Ingrassia (University of Catania, s.ingrassia@unict.it) {p_end}
{phang} Giorgio Vittadini (University of Milano-Bicocca, giorgio.vittadinid@unimib.it) {p_end}


