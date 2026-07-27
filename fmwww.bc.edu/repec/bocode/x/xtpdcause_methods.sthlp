{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtpdcause" "help xtpdcause"}{...}
{vieweralsosee "xtpdroot (library)" "help xtpdroot"}{...}
{title:Title}

{phang}
{bf:xtpdcause methods} {hline 2} Formulas for the factor-corrected panel
Granger-causality test

{title:Factor correction}

{pstd}
Let {it:y_it} = ({it:d_it}, {it:c_it}) be the bivariate series (dependent,
causing) for unit {it:i}. The common-factor structure is estimated from the
{it:standardized first differences} {it:Dz_it} = {it:Dy_it}/sd({it:Dy_it}),
stacked as a (T-1) x 2N matrix {it:DZ}.{p_end}

{phang}{bf:PANIC.} The common factors {it:F} and loadings {it:L} are the
principal components of {it:DZ}: {it:DZ} = {it:F L'} + {it:e}. The number of
factors is the Bai-Ng (2002) IC2 minimizer over 0..{it:kmax}. The de-factored
differences {it:e} = {it:DZ} - {it:F L'} are cumulated back to levels.{p_end}

{phang}{bf:PANIC-CA.} A single factor is proxied by the cross-section average
{it:Fbar_t} = mean over the 2N columns of {it:DZ}; loadings are the OLS
projection of each column on {it:Fbar}, and the de-factored differences are
cumulated.{p_end}

{phang}{bf:none.} No factor removal; the VAR is run on the raw levels with an
intercept.{p_end}

{title:Lag-augmented VAR and the Wald test}

{pstd}
For each unit the (factor-corrected) bivariate series is fitted as a VAR of order
{it:p} + {it:dmax}, where {it:p} is chosen by AIC or BIC (maximum {it:pmax}) and
{it:dmax} extra lags are appended. Writing the {it:depvar} equation as{p_end}

{pmore}{it:d_t} = sum_(j=1..p+dmax) a_j d_(t-j) + sum_(j=1..p+dmax) b_j c_(t-j) +
u_t,{p_end}

{pstd}
the Wald statistic tests {it:H0}: {it:b_1} = ... = {it:b_p} = 0 (the first {it:p}
lags of {it:causevar}; the {it:dmax} augmenting lags are left unrestricted). With
{it:RSS_r} and {it:RSS_ur} the restricted and unrestricted residual sums of
squares of the {it:depvar} equation,{p_end}

{pmore}{it:W} = {it:p} x [({it:RSS_r} - {it:RSS_ur})/{it:p}] /
[{it:RSS_ur}/({it:T} - k)] ~ chi2({it:p}),{p_end}

{pstd}
which is asymptotically chi-square with {it:p} degrees of freedom irrespective of
the integration order of the data (Toda-Yamamoto).{p_end}

{title:Panel pooling}

{pstd}
Let {it:pv_i} = 1 - F_chi2({it:W_i}; {it:p_i}) be the unit p-values. The panel
statistics are the Fisher combinations{p_end}

{pmore}{bf:P}  = -2 sum_i ln({it:pv_i})  ~ chi2(2N){p_end}
{pmore}{bf:Pm} = (P - 2N)/sqrt(4N)       ~ N(0,1).{p_end}

{pstd}
Holm's step-down procedure is applied to the {it:pv_i} to give family-wise
error-controlled individual p-values, identifying the panels responsible for a
panel rejection.

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
