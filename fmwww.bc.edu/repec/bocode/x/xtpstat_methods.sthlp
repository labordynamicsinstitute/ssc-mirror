{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtpstat" "help xtpstat"}{...}
{vieweralsosee "xtpdroot (library)" "help xtpdroot"}{...}
{viewerjumpto "Factors" "xtpstat_methods##fac"}{...}
{viewerjumpto "KPSS statistic" "xtpstat_methods##kpss"}{...}
{viewerjumpto "Pooling" "xtpstat_methods##pool"}{...}
{viewerjumpto "Step-to-code map" "xtpstat_methods##map"}{...}
{title:Title}

{phang}
{bf:xtpstat methods} {hline 2} Methods and formulas for {helpb xtpstat}

{marker fac}{...}
{title:Common factors}

{pstd}
The differenced data (demeaned for the trend model) are decomposed into common
factors and idiosyncratic errors by principal components; the number of factors
is chosen by the Bai-Ng (2002) ICp2 criterion (see {helpb xtpanic_methods}). The
idiosyncratic residuals are cumulated to recover the idiosyncratic component in
levels, {it:E{sub:it} = sum e-hat{sub:is}}.

{marker kpss}{...}
{title:Idiosyncratic KPSS}

{pstd}
Each unit's cumulated idiosyncratic component is regressed on the deterministic
terms; with residuals {it:v{sub:t}} and partial sums {it:S{sub:t} = sum v}, the
KPSS statistic is

{p 12 12 2}{it:KPSS = ( sum S{sub:t}^2 ) / ( T^2 * lrv )},{p_end}

{pstd}
where {it:lrv} is the long-run variance estimated by the Sul-Phillips-Choi (2003)
{it:prewhitened} Bartlett kernel: an AR order is selected by BIC, the residuals
are prewhitened, a Bartlett kernel with an Andrews-Monahan plug-in bandwidth is
applied, and the estimate is recoloured, subject to the SPC boundary rule.

{marker pool}{...}
{title:Pooling}

{pstd}
KPSS p-values {it:p{sub:i}} come from the paper's response surface (a fourth-order
polynomial in 1/T for each of 221 percentiles). They are combined into

{p 8 10 2}{bf:Ppc} = {it:-2 sum ln(p{sub:i})} ~ chi-square(2N);{p_end}
{p 8 10 2}{bf:Pm} = {it:(Ppc - 2N)/sqrt(4N)} ~ N(0,1);{p_end}
{p 8 10 2}{bf:Zpc} = {it:sum Phi^{-1}(p{sub:i}) / sqrt(N)} ~ N(0,1) (Choi);{p_end}
{p 8 10 2}{bf:W} = {it:sqrt(N)(mean(KPSS) - mu)/sqrt(v)} (Hadri LM),{p_end}

{pstd}
with (mu, v) = (1/6, 1/45) for the constant model and (1/15, 11/6300) for the
trend model. Ppc, Pm and W reject stationarity for large values; Zpc for very
negative values.

{marker map}{...}
{title:Step-to-code map}

{synoptset 30 tabbed}{...}
{synopthdr:computation}
{synoptline}
{synopt:factors (Bai-Ng 2002)}Mata {cmd:_xtpk_pca} / {cmd:_xtpk_fnumber2}{p_end}
{synopt:idiosyncratic KPSS}Mata {cmd:_xtpk_kpss}{p_end}
{synopt:SPC prewhitened Bartlett lrv}Mata {cmd:_xtpk_alrv}{p_end}
{synopt:response-surface p-value}Mata {cmd:_xtpk_pval}{p_end}
{synopt:pooled Ppc, Pm, Zpc, W}Mata {cmd:_xtpk_run}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}Each block reproduces the GAUSS routine {cmd:BNG_PANICkpss}; the statistics
and p-values match the GAUSS output on the OPEC CO2 data to the last digit.{p_end}

{title:Reference}

{phang}Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and cointegration.
{it:Econometrica} 72: 1127-1177.{p_end}

{pstd}{helpb xtpstat:Back to xtpstat} {c |} {helpb xtpdroot:xtpdroot library}{p_end}
