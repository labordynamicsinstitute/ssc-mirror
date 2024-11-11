{smcl}
{* 08oct2024}{...}
{hi:help twolevelr2}{...}
{right:{browse "http://github.com/benjann/twolevelr2/"}}
{hline}

{title:Title}

{pstd}{hi:twolevelr2} {hline 2} Within, between, and overall R-squared in linear
    two-level models


{title:Syntax}

{p 8 15 2}
    {cmd:twolevelr2} {depvar} {indepvars} {ifin}{cmd:,}
    {cmd:i(}{it:{help varname:groupvar}}{cmd:)}
    [ {opth pw:eights(varlist)} {opth fw:eights(varlist)} {opt joint:ly}
      {opt noi:sily} {opt v2tol(#)} {it:options} ]

{pstd}
    {it:indepvars} may contain factor variables; see {help fvvarlist}.
    {p_end}


{title:Description}

{pstd}
    {cmd:twolevelr2} computes the within, between, and overall R-squared for
    a two-level model as proposed by Holm et al. (2024).


{title:Options}

{phang}
    {cmd:i(}{it:{help varname:groupvar}}{cmd:)} specifies the variable identifying
    the group structure for the random effects (i.e. the level-two units). Option
    {cmd:i()} is required.

{phang}
    {cmd:pweights(}{help varname:{it:wvar1}} [{help varname:{it:wvar2}}]{cmd:)}
    specifies sampling weights, where variable {it:wvar1} contains (conditional)
    level-one weights and variable {it:wvar2} contains level-two weights (assumed 1 if
    omitted). Only one of {cmd:pweights()} and {cmd:fweights()} is allowed.

{phang}
    {cmd:fweights(}{help varname:{it:wvar1}} [{help varname:{it:wvar2}}]{cmd:)}
    specifies frequency weights, where variable {it:wvar1} contains
    level-one weights and variable {it:wvar2} contains level-two
    weights (assumed 1 if omitted). Only one of {cmd:pweights()} and {cmd:fweights()} is allowed.

{phang}
    {opt joint:ly} requests joint estimation of a multivariate model across all
    level-one variables. By default, the required level-one and level-two variances
    and covariances are obtained by running separate models for each 
    pair of variables. Specify option {cmd:jointly} if you want to obtain
    the variances and covariances from a joint model across all
    variables. The two estimation approaches are asymptotically equivalent, but
    lead to numerically different results in finite samples. Estimating a joint
    model is computationally expensive unless the number of variables is
    small.

{phang}
    {opt noi:sily} echoes the output of the employed calls to {helpb gsem}
    in the results window.

{phang}
    {opt v2tol(#)} sets the tolerance level for diagnosing lack of variance at
    level two. The default is {cmd:v2tol(1e-15)}. If the group means of a level-one
    variable have a variance that is less than the tolerance level, the level-two variance
    of the variable is assumed to be zero (to make estimation feasible).

{phang}
    {it:options} are options passed through to model estimation; see
    {helpb gsem}.


{title:Examples}

        {com}. {stata "use https://www.stata-press.com/data/r18/gsem_nlsy"}
        . {stata twolevelr2 ln_wage i.union grade ttl_exp tenure c.tenure#c.tenure, i(idcode)}{txt}


{title:Returned results}

{pstd} Scalars:

{p2colset 5 20 20 2}{...}
{p2col : {cmd:r(N)}}number of observations
    {p_end}
{p2col : {cmd:r(N_g)}}number of groups (level-two units)
    {p_end}
{p2col : {cmd:r(k_x)}}number of level-one predictors
    {p_end}
{p2col : {cmd:r(k_z)}}number of level-two predictors
    {p_end}
{p2col : {cmd:r(k_o)}}number of omitted predictors
    {p_end}
{p2col : {cmd:r(r2_w)}}within R-squared
    {p_end}
{p2col : {cmd:r(r2_b)}}between R-squared
    {p_end}
{p2col : {cmd:r(r2)}}overall (global) R-squared
    {p_end}

{pstd} Macros:

{p2col : {cmd:r(cmd)}}{cmd:twolevelr2}
    {p_end}
{p2col : {cmd:r(cmdline)}}command as typed
    {p_end}
{p2col : {cmd:r(ivar)}}variable denoting groups
    {p_end}
{p2col : {cmd:r(depvar)}}name of dependent variable
    {p_end}
{p2col : {cmd:r(xvars)}}names of level-one predictors
    {p_end}
{p2col : {cmd:r(zvars)}}names of level-two predictors
    {p_end}
{p2col : {cmd:r(ovars)}}names of omitted predictors
    {p_end}
{p2col : {cmd:r(jointly)}}{cmd:jointly} or empty
    {p_end}
{p2col : {cmd:r(pweights)}}sampling weight variables or empty
    {p_end}
{p2col : {cmd:r(fweights)}}frequency weight variables or empty
    {p_end}

{pstd} Matrices:

{p2col : {cmd:r(b_e)}}level-one coefficients of level-one predictors
    {p_end}
{p2col : {cmd:r(b_u)}}level-two coefficients of level-one predictors
    {p_end}
{p2col : {cmd:r(b_z)}}coefficients of level-two predictors
    {p_end}
{p2col : {cmd:r(V_e)}}level-one covariance matrix
    {p_end}
{p2col : {cmd:r(V_u)}}level-two covariance matrix
    {p_end}
{p2col : {cmd:r(V_z)}}covariance matrix of level-two predictors
    {p_end}


{title:References}

{phang}
    Holm, A., B. Jann, K.B. Karlson. 2024. Explained Variance in
    Two-Level Models: A New Approach. Available from
    {browse "https://doi.org/10.31235/osf.io/x6gva"}.


{title:Author}

{pstd}
    Ben Jann, University of Bern, ben.jann@unibe.ch

{pstd}
    Thanks for citing this software as follows:

{pmore}
    Jann, B. (2024). twolevelr2: Stata module to compute within, between, and
    overall R-squared in linear two-level models. Available from
    {browse "https://github.com/benjann/twolevelr2/"}.


{title:Also see}

{psee}
    Online:  help for
    {helpb xtreg}, {helpb mixed}, {helpb gsem}
