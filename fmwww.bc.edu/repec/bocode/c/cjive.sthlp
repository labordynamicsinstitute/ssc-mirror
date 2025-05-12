{smcl}
{* *! version 1.0 January 2024}{...}
{cmd:help cjive}
{hline}

{title:Title}

{phang}
{cmd:cjive} {hline 2} cluster jackknife instrumental variable estimator. 

{title:Syntax}

{p 8 17 2}
{cmd:cjive} {it:depvar} {it:covariates} ({it:treatvarlist} = {it:instruments}){cmd:,} {opt cluster(varname)} [{opt gen(varlist)}]

{title:Description}

{pstd}
{cmd:cjive} estimates the coefficient on an endogenous treatment variable with JIVE in the presence of clustering. This version uses leverages and Mata for increased speed and efficiency. 

For more details about the estimator, see Frandsen, Leslie, McIntyre, Cluster Jackknife Instrumental Variables Estimation, {it: Review of Economics and Statistics} 2025. 

{pstd}
The model assumes a standard linear IV setup:

{pstd}
y = βd + Xγ + ε    

{pstd}
d = Zπ + Xρ + ν



{phang}
The endogenous treatment(s) {it:treatmentvar} are instrumented using {it:instruments}, controlling for covariates {it:covariates}. All variables may vary at the individual level, and clustering is specified with the {opt cluster()} option. 


{title:Options}

{pstd}
{opt cluster(varname)} specifies the variable defining the clusters. This is required.

{phang}
{opt gen(varlist)} optionally specifies variable names to store the cluster jackknifed instruments (in the order corresponding to each endogenous variable). The number of names must match the number of endogenous variables.

{title:Returned Results}

{pstd}
{cmd:cjive} returns coefficient estimates and clustered standard errors for the endogenous variables. Internally, it also generates and (optionally) saves the leave-one-cluster-out leverage-adjusted fitted values used as instruments.

{pstd}
Stored in {cmd:e()}:

{synoptset 20 tabbed}
{synopt:{cmd:e(b)}}vector of estimated coefficients on the endogenous variables, no constant {p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimator{p_end}
{synopt:{cmd:e(N)}}number of observations used{p_end}
{synopt:{cmd:e(depvar)}}name of the dependent variable{p_end}
{synopt:{cmd:e(cmd)}}{cmd:cjive}{p_end}
{synopt:{cmd:e(title)}}CJIVE{p_end}

{title:Examples}

{phang}{cmd:. cjive y x1 x2 (d = z1 z2), cluster(group_id)}{p_end}

{phang}{cmd:. cjive y x1 (d1 d2 = z1 z2 z3), cluster(state) gen(lv1 lv2)}{p_end}

{title:Author}

{pstd}
Brigham Frandsen {break}
Brigham Young University{break}
Email: frandsen@byu.edu

{pstd}
Emily Leslie {break}
Brigham Young University{break}
Email: emily.leslie@byu.edu

{pstd}
Samuel McIntyre{break}
Brigham Young University{break}
Email: spm42@byu.edu

{title:Also see}

{psee}
Help: {help ivregress}

{pstd}
Frandsen, Leslie, McIntyre. Cluster Jackknife Instrumental Variables Estimation, {it: Review of Economics and Statistics} 2025. 


{hline}
