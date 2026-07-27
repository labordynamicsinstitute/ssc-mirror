{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtfaclm" "help xtfaclm"}{...}
{vieweralsosee "xtpdroot (library)" "help xtpdroot"}{...}
{title:Title}

{phang}
{bf:xtfaclm methods} {hline 2} Formulas for the factor-augmented two-break panel
LM test

{title:Iterated break and factor estimation}

{pstd}
Let {it:Dy_it} be the first differences. Starting from {it:Dy}, the procedure
iterates:{p_end}

{phang}1. {bf:Breaks.} For each unit the two break dates that minimise the
residual sum of squares of {it:Dy_it} on the (differenced) two-break deterministic
terms are found by grid search; the residuals {it:r_it} and fitted values are
stored.{p_end}

{phang}2. {bf:Factors.} The number of common factors is chosen by the Bai-Ng
(2002) criterion and {it:nf} factors {it:F_t} with loadings {it:L_i} are extracted
from {it:r} by principal components.{p_end}

{phang}3. {bf:De-factoring.} The common component {it:F L'} is removed from {it:Dy}
and the loop repeats until the idiosyncratic variance changes by less than 0.001.{p_end}

{pstd}
The converged idiosyncratic differences are {it:e_it} = {it:Dy_it} - (fitted
break term) - {it:F_t L_i'}.

{title:Two-break LM regression with factors}

{pstd}
For each unit the LM score is the partial sum {it:S_t} = sum_{s<=t} {it:e_is},
rescaled within the three regimes defined by the two breaks (the Lee-Strazicich
transformation). The augmented LM regression is{p_end}

{pmore}{it:Dy_t} = {it:phi S_(t-1)} + {it:a' Dz_t} + sum_j {it:b_j D S_(t-j)}
+ {it:h' F_t} + {it:u_t},{p_end}

{pstd}
where {it:z} collects the trend and the two break dummies (level breaks) or the
trend, break dummies and broken trends (level & trend breaks), and {it:F_t} are
the estimated common factors. The statistic is the {it:t}-ratio on {it:phi}. The
lag {it:j} is chosen by AIC, BIC or a general-to-specific {it:t}-rule.

{title:Response-surface p-value and panel pooling}

{pstd}
Because the two-break LM null distribution depends on the break fractions and the
number of augmentation lags, the p-value is read from an embedded MacKinnon-type
response surface (a cubic-in-quantile interpolation of tabulated critical values,
indexed by the break configuration, {it:T} and the lag length). The unit p-values
{it:pv_i} are combined into{p_end}

{pmore}{bf:P}  = -2 sum_i ln({it:pv_i})  ~ chi2(2N),   {bf:Pm} = (P - 2N)/sqrt(4N).

{title:A note on lag selection}

{pstd}
The AIC and BIC criteria depend only on the regression sum of squares and are
invariant to the (arbitrary) sign and rotation of the estimated common factors, so
they reproduce the source routine exactly. The general-to-specific {it:t}-rule, as
written in the original code, evaluates the {it:t}-statistic of the last common
{it:factor} rather than the last lagged difference; that statistic is not
identified in sign or rotation, so the selected lag can vary with the linear-
algebra library. {cmd:xtfaclm} therefore defaults to BIC.

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
