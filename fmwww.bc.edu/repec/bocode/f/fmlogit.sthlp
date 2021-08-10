{smcl}
{* 14Feb2017/24Jun2013/05Jan2008/30dec2006/06sep2006/03aug2006}{...}
{hline}
help for {hi:fmlogit}
{hline}

{title:Fitting a fractional multinomial logit model by quasi maximum likelihood}

{p 8 17 2}
{cmd:fmlogit} 
{it:depvars} 
{weight} 
{ifin}
[{cmd:,} 
{cmdab:eta:var(}{it:varlist}{cmd:)} 
{cmd:rpr}
{cmdab:cl:uster(}{it:clustervar}{cmd:)} 
{cmdab:c:onstraints(}{it:numlist}|{it:matname}{cmd:})}
{cmdab:l:evel(}{it:#}{cmd:)} 
{cmd:nolog}
{cmdab:nocon:stant}
{it:maximize_options} 
]

{p 4 4 2}{cmd:by} {it:...} {cmd::} may be used with {cmd:fmlogit}; see help
{help by}. 

{p 4 4 2}{cmd:fweight}s, and {cmd:pweight}s are allowed; see help {help weights}.

{p 4 4 2}{cmd:etavar} may contain factor variables; see {help fvvarlist}.


{title:Description}

{p 4 4 2} 
{cmd:fmlogit} fits by quasi maximum likelihood a fractional multinomial logit
model. Each variable in depvarlist ranges between 0 and 1 and all variables in 
depvarlist must, for each observation, add up to 1: for example, they may be
proportions. It is a multivariate generalization of the fractional logit model
proposed by Papke and Wooldridge (1996). 

{p 4 4 2}
Note that cases will be ignored if the one or more of the dependent variables 
has a value less zero or more than one or if the dependent variables don't add 
up to one.

{p 4 4 2}
Also note that {cmd:fmlogit} always implies the {help vce_option : vce(robust)} option because 
the model is fitted using quasi maximum likelihood.


{title:Options}

{p 4 8 2}{cmd:etavar()} specifies the explanatory variables. (The name of this 
option originates from the symbol commonly used for the linear predictor, the
Greek letter eta.)

{p 4 8 2}{cmd:rpr}  reports the estimated coefficients transformed to relative
proportion ratios, i.e., exp(b) rather than b.  Standard errors and confidence
intervals are similarly transformed.  This option affects how results are 
displayed, not how they are estimated.  

{p 8 8 2}Relative proportion ratios can be useful when the model contains 
interaction terms, as in that case marginal effects as computed by dfmlogit
will no longer be appropriate. Relative proportion ratios for the 
interaction terms can still be interpreted as the factor by which the 
relative proportion ratio changes, as is discussed in Buis (2010).

{p 4 8 2}{cmd:cluster(}{it:clustervar}{cmd:)} specifies that the observations
are independent across groups (clusters) but not necessarily within groups.
{it:clustervar} specifies to which group each observation belongs; e.g.,
{cmd:cluster(personid)} in data with repeated observations on individuals.  See
{hi:[U] 23.14 Obtaining robust variance estimates}.  

{p 4 8 2} {cmdab:c:onstraints(}{it:numlist}|{it:matname}{cmd:})} specifies
linear constraint(s) that are to be applied to the model; see help 
{help constraint}.

{p 4 8 2}{cmd:level(}{it:#}{cmd:)} specifies the confidence level, in percent,
for the confidence intervals of the coefficients; see help {help level}.

{p 4 8 2}{cmd:nolog} suppresses the iteration log.

{p 4 8 2}{cmdab:nocon:stant} suppresses the constant in the eta equations.

{p 4 8 2}{it:maximize_options} control the maximization process; see 
help {help maximize}. If you are seeing many "(not concave)" messages in the 
log, using the {cmd:difficult} option may help convergence.

       
{title:Example}

{cmd}
    use http://fmwww.bc.edu/repec/bocode/c/citybudget.dta, clear

    gen pol = minorityleft + 2*noleft
    label define pol 0 "left parties are majority" ///
                     1 "left parties are minority" /// 
                     2 "no left party"                
    label value pol pol
    label var pol "political orientation of city government"

    fmlogit governing safety education recreation social urbanplanning, ///
        eta(i.pol houseval popdens)

    margins, dydx(*) predict(outcome(governing))
    margins, dydx(*) predict(outcome(safety))
    margins, dydx(*) predict(outcome(education))
    margins, dydx(*) predict(outcome(recreation))
    margins, dydx(*) predict(outcome(social))
    margins, dydx(*) predict(outcome(urbanplanning)) 
{txt}
{p 4 4 2}({stata "fmlogit_ex":click to run}){p_end}


{title:Author}

{p 4 4 2}Maarten L. Buis, University of Konstanz{break}maarten.buis@uni.kn


{title:References}

{p 4 4 2}
Buis, M.L. 2010.  Stata tip 87: Interpretation of interactions in non-linear 
models.  {it:The Stata Journal} 10(2): 305-308.

{p 4 4 2}
Papke, Leslie E. and Jeffrey M. Wooldridge. 1996.
Econometric Methods for Fractional Response Variables with an Application to 
401(k) Plan Participation Rates. {it:Journal of Applied Econometrics} 11(6):619{c -}632.


{title:Also see}

{p 4 13 2}
Online: help for {help fmlogit postestimation}, 

{p 4 13 2}
If installed: {help dirifit}
