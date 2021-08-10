{smcl}
{* *! version 1.1  15July2015}{}{...}
{* *! Author: Volker Ludwig}
{cmd:help xtfeis} 
{hline}

{title:Title}

{p 8 16 2}
{cmd:xtfeis} {hline 2} User-written ado to estimate linear Fixed-Effects model with Individual-specific Slopes (FEIS) {p_end}


{title:Syntax}


{p 8 16 2}
{cmd:xtfeis} {varlist} {ifin} [{cmd:,}] [{cmd:slope(}{varlist}{cmd:)}] [{cmd:noconstant}] [{cmd:cluster(}{varname}{cmd:)}] [{cmd:transformed(}{stubname}{cmd:)}]



{title:Description}

{pstd}
{cmd:xtfeis} estimates linear Fixed-Effects models with Individual-specific Slopes (Br{c u:}derl and Ludwig 2015; Wooldridge 2010, pp. 374-381). 
You need to declare the current data set to be panel data before using this command, see {cmd:xtset}.
Estimation requires at least q+1 observations per unit where q is the number of slope parameters (including possibly a constant).
{cmd:xtfeis} automatically selects only those units from the current data set with at least q+1 observations.

{title:Options}

{dlgtab:Options}

{phang}
{opt slope(slopevars)} specifies the names of variables that interact with time-constant individual heterogeneity, i.e. variables with individual-specific slopes.
Often, these variables are some function of time to allow for heterogeneous growth.
By default, individual-specific constants are included as {it:slopevar}. Specify {opt noconstant} to omit them.   

{pmore}
If {opt slope()} is not specified, the model collapses to the standard linear Fixed-Effects model, see {cmd: xtreg, fe}.

{phang}
{opt noconstant} requests estimation of a model with individual-specific slopes only (i.e., individual-specific constants are omitted).

{phang}
{opt cluster(clustvar)} requests panel-robust standard errors. Panel-robust standard errors are robust to arbitrary forms of serial correlation within groups formed by {it:clustvar} as well as heteroscedasticity across groups. 

{phang}
{opt transformed(stubname)} requests within-transformed variables are added to the current data set. Added variables are named as the untransformed variables prefixed by {it:stubname}. 



{title:Examples}

{cmd:. webuse nlswork} 

Estimate standard Fixed-Effects model with panel-robust standard errors
{cmd:. xtfeis ln_wage msp tenure ttl_exp year, cluster(idcode)} 

Estimate Fixed-Effects model with Individual-specific Slope for total work experience
{cmd:. xtfeis ln_wage msp tenure year, slope(ttl_exp) cluster(idcode)}

Estimate Fixed-Effects model with Individual-specific Slope, add transformed variables to current data set
{cmd:. xtfeis ln_wage msp tenure year, slope(ttl_exp) cluster(idcode) transformed(t_)} 



{title:References}

Br{c u:}derl, J., Ludwig, V. (2015). Fixed-Effects Panel Regression. In: H. Best and C. Wolf (eds.), The Sage Handbook of Regression Analysis and Causal Inference. London: Sage, pp. 327-357.
Wooldridge, J. (2010). Econometrics of Cross Section and Panel Data, Cambridge: MIT Press, 2nd edition.


{title:Author}

Volker Ludwig
Department of Sociology, University of Munich (LMU)
volker.ludwig@soziologie.uni-muenchen.de
