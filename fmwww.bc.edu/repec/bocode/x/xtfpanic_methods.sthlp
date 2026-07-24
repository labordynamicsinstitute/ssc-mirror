{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtfpanic" "help xtfpanic"}{...}
{vieweralsosee "xtflexur (library)" "help xtflexur"}{...}
{viewerjumpto "Fourier detrending" "xtfpanic_methods##fourier"}{...}
{viewerjumpto "Factors" "xtfpanic_methods##factors"}{...}
{viewerjumpto "Fourier-LM statistic" "xtfpanic_methods##lm"}{...}
{viewerjumpto "p-values and pooling" "xtfpanic_methods##pool"}{...}
{viewerjumpto "Step-to-code map" "xtfpanic_methods##map"}{...}
{title:Title}

{phang}
{bf:xtfpanic methods} {hline 2} Methods and formulas for {helpb xtfpanic}

{marker fourier}{...}
{title:Fourier detrending}

{pstd}
Let {it:dX{sub:t}} be the first differences. A flexible Fourier trend is removed
from each series by regressing {it:dX{sub:it}} on the differenced deterministic
terms {it:dz{sub:t}}, where

{p 8 8 2}{it:z{sub:t} = [ t, cos(2 pi k t/T), sin(2 pi k t/T) : k=1..m ]}{p_end}

{pstd}
and m is the maximum cumulative frequency ({opt freq()}). The residuals
{it:rr{sub:it}} are the Fourier-detrended differences.

{marker factors}{...}
{title:Common factors}

{pstd}
The number of common factors is estimated by the Bai-Ng (2002) information
criterion on {it:rr}, and the factors F-hat and loadings are extracted by
principal components (the shared {helpb xtflexur} engine). The idiosyncratic
component is {it:ww{sub:it} = dX{sub:it} - Fourier fit - F-hat loadings}.

{marker lm}{...}
{title:Fourier-LM statistic}

{pstd}
For each unit, the cumulated idiosyncratic component {it:S{sub:it} = sum ww} is
tested with a score-type LM regression

{p 8 8 2}{it:dX{sub:it} = phi S{sub:i,t-1} + dz{sub:t} g + F-hat d + sum_j c{sub:j} dS{sub:i,t-j} + u{sub:it}},{p_end}

{pstd}
and the statistic is the t-ratio on {it:phi}. The lag order is chosen by AIC,
SIC, or a general-to-specific t-test (default). Including {it:dz} and F-hat as
regressors purges the smooth break and the common factors.

{marker pool}{...}
{title:p-values and pooling}

{pstd}
The distribution of the Fourier-LM statistic depends on the sample size, the
number of lags, and the frequency m. The paper's response surface gives the
critical value at each of 221 percentiles as
{it:CV = c1 + c2/T + c3/T^2 + c4(p/T) + c5(p/T)^2} (p = lags), tabulated
separately for m = 0, 1, 2, 3. A local MacKinnon (1996) inversion returns the
p-value {it:p{sub:i}}, and the individual p-values are pooled into

{p 12 12 2}{it:P = -2 sum ln(p{sub:i})}  ~  chi-square(2N),{p_end}
{p 12 12 2}{it:Pm = (P - 2N)/sqrt(4N)}  ~  N(0,1),{p_end}

{pstd}
both rejecting the unit-root null for large values.

{marker map}{...}
{title:Step-to-code map}

{synoptset 30 tabbed}{...}
{synopthdr:computation}
{synoptline}
{synopt:Fourier detrending of differences}Mata {cmd:_xtfp_run}{p_end}
{synopt:factors (Bai-Ng 2002)}Mata {cmd:_xtfp_pca} / {cmd:_xtfp_fnumber2}{p_end}
{synopt:Fourier-LM statistic + lags}Mata {cmd:_xtfp_lmtau}{p_end}
{synopt:response-surface p-value}Mata {cmd:_xtfp_pval} (+ {cmd:_xtfp_rs0..3}){p_end}
{synopt:pooled P and Pm}Mata {cmd:_xtfp_run}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}Each block reproduces the GAUSS code {cmd:appl3_PANIC_fourier}; the
statistics and p-values match Table 3 of Nazlioglu et al. (2023) (both m=1 and
m=1,2) to the last reported digit.{p_end}

{title:Reference}

{phang}Nazlioglu, S., et al. 2023. Smooth structural changes and common factors in
nonstationary panel data. {it:Econometric Reviews} 42(1): 78-97.{p_end}

{pstd}{helpb xtfpanic:Back to xtfpanic} {c |} {helpb xtflexur:xtflexur library}{p_end}
