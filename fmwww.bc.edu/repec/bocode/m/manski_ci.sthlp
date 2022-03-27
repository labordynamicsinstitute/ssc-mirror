{smcl}
{* 25mar2022}{...}
{cmd:help manski_ci}{right:Version 1.1}
{hline}

{title:Title}

{pstd}
{hi:manski_ci} {hline 2} uses Manski type bounds (Manski 2003) to calculate confidence intervals 
around a treatment variable's regression coefficient in a (covariate-adjusted) regression. {p_end}

{marker syntax}{title:Syntax}

{pstd} 
{cmd:manski_ci} [if] [in] {cmd:, }
{opt out:come(dependentvar)}
{opt tr:eat(treatvar)}
[{opt cov:ars(covars)}
{opt regt:ype(string)}
{opt dis:playall}
{opt miss:ingflag(missingindicator)}
{opt max(num)}
{opt min(num)}
{opt vce(typeofse)}
{opt level(cilevel)}]


{marker desc}{title:Description}

{pstd} {cmd:manski_ci} is designed for use in the context of randomized controlled trials (RCTs) with missing outcomes 
(usually with different rates of missingness across experimental arms). The command infers worst case and best case values of an outcome 
as described in Manski (2003). This command takes the lower bound of the (covariate-adjusted) regression that assumes the worst case outcomes
and the upper bound  of the (covariate-adjusted) regression that assumes the best case outcome. This gives the user a more conservative 
confidence interval around their (covariate-adjusted) regression estimate of the treatment effect. {p_end}

{marker opt}{title:Options}

{pstd} {opt out:come(dependentvar)} name of the outcome or dependent variable {p_end} 
{pstd} {opt tr:eat(treatvar)} name of the treatment variable; must be binary {p_end} 
{pstd} {opt cov:ars(covars)} optional - list of covariate variables (accepts {cmd:i.} and {cmd:c.} prefixes){p_end} 
{pstd} {opt regt:ype(regressiontype)} optional - type of regression; defaults to OLS (i.e. {cmd:regress}){p_end} 
{pstd} {opt dis:playall} optional - shows all operations {p_end} 
{pstd} {opt mis:singflag(missingindicator)} optional - this package automatically infers missingness based on missing outcome value; to override, specify custom missingness indicator {p_end} 
{pstd} {opt max(num)} optional - the command automatically takes the maximum value of the outcome variable from the observed data; to override, use this option to specify the maximum possible value{p_end}

{pstd} {opt min(num)} optional - the command automatically takes the minimum value of the outcome variable from the observed data; to override, use this  option to specify the minimum possible value{p_end}

{pstd} {opt vce(seadjust)} optional - used the same as in base Stata (e.g., {inp:vce(robust)}){p_end} 

{pstd} {opt l:evel(cilevel)} optional - the package defaults to a 95% CI; to override as in base Stata (e.g., {inp:level(99)}){p_end} 


{marker ex}{title:Examples}

{pstd} {inp:sysuse auto}{p_end}
{pstd} {inp:manski_ci, outcome(rep78) treat(foreign) covars(c.mpg) vce(robust)}{p_end}


{marker res}{title:Saved Results}

{pstd}
{cmd:manski_ci} saves the confidence intervals in {cmd:e()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:e(manski_ci)}}treatment effect regression coefficient with adjusted CIs{p_end}
{synopt:{cmd:e(best)}} regression table of the best case {p_end}
{synopt:{cmd:e(worst)}} regression table of the worst case {p_end}

{title:Notes}

{pstd}This package preserves data if you use the if/in functionality. Please note that this may slow down this command when used with large datasets.{p_end}

{title:References}

{pstd}Manski, C. F. 2003. Partial identification of probability distributions. Springer Science & Business Media.{p_end}

{title:Author}
{pstd}John Ternovski{p_end}
{pstd}Georgetown University{p_end}
{pstd}{browse "mailto:johnt1@gmail.com":johnt1@gmail.com}{p_end}

