{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtpanic" "help xtpanic"}{...}
{vieweralsosee "xtflexur (library)" "help xtflexur"}{...}
{viewerjumpto "Factor model" "xtpanic_methods##model"}{...}
{viewerjumpto "Number of factors" "xtpanic_methods##nf"}{...}
{viewerjumpto "Idiosyncratic ADF" "xtpanic_methods##adf"}{...}
{viewerjumpto "Pooled tests" "xtpanic_methods##pool"}{...}
{viewerjumpto "Step-to-code map" "xtpanic_methods##map"}{...}
{title:Title}

{phang}
{bf:xtpanic methods} {hline 2} Methods and formulas for {helpb xtpanic}

{marker model}{...}
{title:Factor model}

{pstd}
PANIC assumes the differenced data follow an approximate factor model,
{it:dX{sub:t} = L F{sub:t} + e{sub:t}}, where {it:F{sub:t}} are r common factors,
{it:L} the loadings, and {it:e{sub:t}} idiosyncratic errors. For the trend model
the differences are demeaned first. Factors and loadings are estimated by
principal components: with the T x N matrix of (demeaned) differences X, an
eigen-decomposition of X'X (or XX' when T<N) gives the loadings from the largest
r eigenvectors, F-hat = X L / N, and the idiosyncratic residuals
e-hat = X - F-hat L'.

{marker nf}{...}
{title:Number of common factors (Bai-Ng 2002)}

{pstd}
For k = 1..kmax, let V(k) be the average residual sum of squares from the k-factor
fit. The information criterion (ICp, the default) minimizes
{it:ln V(k) + k (N+T)/(NT) ln(min(N,T))} over k; PCp and AIC/BIC variants are also
available. The reported number of factors is the minimizer (ICp2).

{marker adf}{...}
{title:Idiosyncratic ADF}

{pstd}
The idiosyncratic residuals are cumulated, {it:E{sub:it} = sum_{s<=t} e-hat{sub:is}},
and an augmented Dickey-Fuller regression {it:without} deterministic terms is run
for each unit:

{p 12 12 2}{it:dE{sub:it} = rho E{sub:i,t-1} + sum_j c{sub:j} dE{sub:i,t-j} + u{sub:it}}.{p_end}

{pstd}
The reported statistic is the t-ratio on {it:rho}; the lag order is chosen by AIC,
SIC, or a general-to-specific t-test (default). Because the deterministics have
been removed by the factor/differencing step, the limiting distribution is the
Dickey-Fuller {it:no-constant} distribution for {bf:both} the constant and trend
models (Bai and Ng 2004). p-values use the finite-sample response surface
{it:CV(p,T) = c1 + c2/T + c3/T^2} with a nearest-critical-value lookup.

{marker pool}{...}
{title:Pooled panel tests}

{pstd}
The individual p-values {it:p{sub:i}} are combined into the Fisher-type statistics

{p 12 12 2}{it:P = -2 sum ln(p{sub:i})}  ~  chi-square(2N),{p_end}
{p 12 12 2}{it:Pm = ( -2 sum ln(p{sub:i}) - 2N ) / sqrt(4N)}  ~  N(0,1).{p_end}

{pstd}
Both reject the unit-root null for large values.

{marker map}{...}
{title:Step-to-code map}

{synoptset 30 tabbed}{...}
{synopthdr:computation}
{synoptline}
{synopt:principal-components factors}Mata {cmd:_xtp_pca}{p_end}
{synopt:number of factors (Bai-Ng 2002 IC)}Mata {cmd:_xtp_fnumber}{p_end}
{synopt:idiosyncratic ADF (no deterministics)}Mata {cmd:_xtp_adfnc} / {cmd:_xtp_getlag}{p_end}
{synopt:DF-no-constant p-value (response surface)}Mata {cmd:_xtp_pval}{p_end}
{synopt:pooled P and Pm}Mata {cmd:_xtp_run}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}Each block reproduces the corresponding GAUSS procedure in {cmd:BNG_PANIC}
(TSPDLIB); the statistics and p-values match Table 3 of Nazlioglu et al. (2023)
(the healthcare-expenditure application) to the last reported digit.{p_end}

{title:Reference}

{phang}Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and cointegration.
{it:Econometrica} 72: 1127-1177.{p_end}

{pstd}{helpb xtpanic:Back to xtpanic} {c |} {helpb xtflexur:xtflexur library}{p_end}
