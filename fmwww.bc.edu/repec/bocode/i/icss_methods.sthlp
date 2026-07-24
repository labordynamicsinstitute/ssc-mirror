{smcl}
{* 23jul2026}{...}
{vieweralsosee "icss" "help icss"}{...}
{vieweralsosee "flexur (library)" "help flexur"}{...}
{viewerjumpto "Model and hypothesis" "icss_methods##model"}{...}
{viewerjumpto "The three statistics" "icss_methods##stats"}{...}
{viewerjumpto "Long-run fourth moment" "icss_methods##lrv"}{...}
{viewerjumpto "Critical values" "icss_methods##cv"}{...}
{viewerjumpto "ICSS algorithm" "icss_methods##algo"}{...}
{viewerjumpto "Step-to-equation map" "icss_methods##map"}{...}
{title:Title}

{phang}
{bf:icss methods} {hline 2} Methods and formulas for {helpb icss}

{marker model}{...}
{title:Model and null hypothesis}

{pstd}
Let {it:e(t)}, {it:t}=1,...,{it:T}, be a zero-mean process with unconditional
variance {it:sigma^2(t)}. The null hypothesis is constancy of the unconditional
variance,

{p 8 8 2}{bf:H0:} {it:sigma^2(1) = sigma^2(2) = ... = sigma^2(T)}.{p_end}

{pstd}
Define the cumulative sum of squares {it:C(k) = sum_{t=1..k} e(t)^2} with total
{it:C(T)}, and the centered statistic {it:D(k) = C(k)/C(T) - k/T}. Under H0 the
tests converge to the supremum of a standard Brownian bridge, sup_r |W*(r)|.

{marker stats}{...}
{title:The three statistics}

{pstd}{bf:Inclán-Tiao (test=it), eq. (1):}{p_end}
{p 8 8 2}{it:IT = sqrt(T/2) * max_k |D(k)|}.{p_end}
{pstd}Its limit is free of nuisance parameters {it:only} when the data are i.i.d.
and mesokurtic (fourth moment = 3*sigma^4). Otherwise the limit depends on the
kurtosis and on the persistence of the conditional variance, and the test
over-rejects.{p_end}

{pstd}{bf:kappa1 (test=k1), Proposition 2:}{p_end}
{p 8 8 2}{it:B(k) = |C(k) - k*s2|},  {it:s2 = C(T)/T},  {it:a4 = (1/T) sum e(t)^4},{p_end}
{p 8 8 2}{it:kappa1 = T^(-1/2) * max_k B(k) / sqrt(a4 - s2^2)}.{p_end}
{pstd}The denominator estimates the standard deviation of {it:e(t)^2} and removes
the dependence on the fourth moment; valid for i.i.d. data of any kurtosis.{p_end}

{pstd}{bf:kappa2 (test=k2), Proposition 3:}{p_end}
{p 8 8 2}{it:G(k) = C(k) - (k/T)*C(T)},{p_end}
{p 8 8 2}{it:kappa2 = T^(-1/2) * max_k |G(k)| / sqrt(omega4)},{p_end}
{pstd}where {it:omega4} is the {it:long-run} variance of {it:xi(t) = e(t)^2 - s2}.
Replacing the short-run scale of {it:kappa1} by the long-run scale accounts for
autocorrelation in the squared series, i.e. conditional heteroskedasticity. This
is the statistic recommended for financial returns.{p_end}

{marker lrv}{...}
{title:Long-run fourth moment (kappa2)}

{pstd}
{it:omega4} is estimated nonparametrically from the autocovariances
{it:gamma(j)} of {it:xi(t)}:{p_end}
{p 8 8 2}{it:omega4-hat = gamma(0) + 2 * sum_{j=1..m} w(j,m) * gamma(j)},{p_end}
{pstd}with a Bartlett kernel {it:w(j,m) = 1 - j/(m+1)} ({cmd:kernel(bartlett)}) or a
quadratic-spectral kernel ({cmd:kernel(qs)}, default). The bandwidth {it:m} is
either fixed ({cmd:bwidth()}) or chosen by the Newey-West (1994) automatic rule
seeded by {cmd:binit()} (default 4), exactly as in {cmd:variance.src}.{p_end}

{marker cv}{...}
{title:Critical values and p-values}

{pstd}
Because the ICSS algorithm evaluates the statistic on sub-samples of varying
length, {cmd:icss} uses the paper's finite-sample {bf:response surfaces} for the
5% critical value as a function of {it:T} (Table 2 / the GAUSS constants). For the
whole-sample test the reported p-value is computed from the common asymptotic
distribution K(x) = P(sup_r|W*(r)| <= x), giving tail probability
{it:2 * sum_{j>=1} (-1)^(j+1) exp(-2 j^2 x^2)}.

{marker algo}{...}
{title:The ICSS iterative algorithm}

{pstd}
Multiple breaks are located by the Inclán-Tiao ICSS procedure (paper, Section 5),
ported verbatim from {cmd:icss.src}:{p_end}

{p 8 12 2}1. On the current segment, find the point that maximizes the statistic;
if it exceeds the 5% critical value, record a candidate break and recurse
on the left and right sub-segments ({it:nbrseq}, {it:bypass}, {it:selec}).{p_end}
{p 8 12 2}2. Bracket the first and last breaks and iterate inward
({it:nbreaks}).{p_end}
{p 8 12 2}3. Fine-tune: re-test each break against its two neighbours and drop it
if it is no longer significant; repeat until the break set is stable (up to 20
sweeps).{p_end}

{marker map}{...}
{title:Step-to-equation / step-to-code map}

{synoptset 30 tabbed}{...}
{synopthdr:computation}
{synoptline}
{synopt:{it:C(k), D(k)} cumulative sums}Inclán-Tiao (1994){p_end}
{synopt:{it:IT} statistic, eq. (1)}Mata {cmd:_icss_stat}, test=0{p_end}
{synopt:{it:kappa1}, Proposition 2}Mata {cmd:_icss_stat}, test=1{p_end}
{synopt:{it:kappa2}, Proposition 3}Mata {cmd:_icss_stat}, test=2{p_end}
{synopt:{it:omega4-hat} long-run 4th moment}Mata {cmd:_icss_lvar} (+ {cmd:_icss_lagsel}){p_end}
{synopt:5% critical value response surface}Mata {cmd:_icss_cv}{p_end}
{synopt:asymptotic p-value}Mata {cmd:_icss_pval}{p_end}
{synopt:ICSS multiple-break search}Mata {cmd:_icss_icss} / {cmd:_icss_nbreaks} / {cmd:_icss_nbrseq}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}Every block reproduces the corresponding GAUSS procedure in {cmd:icss.src}
and {cmd:variance.src} one-to-one; the {it:kappa2} long-run estimator matches
the quadratic-spectral / Newey-West default used in the paper's empirical
application.{p_end}

{title:Reference}

{phang}Sansó, A., V. Aragó, and J. L. Carrion-i-Silvestre. 2004. Testing for
changes in the unconditional variance of financial time series. {it:Revista de
Economía Financiera} 4: 32-53.{p_end}

{pstd}{helpb icss:Back to icss} {c |} {helpb flexur:flexur library}{p_end}
