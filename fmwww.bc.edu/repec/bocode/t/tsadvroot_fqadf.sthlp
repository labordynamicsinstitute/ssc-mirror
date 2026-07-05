{smcl}
{* *! version 1.0.0  03jul2026}{...}
{viewerjumpto "Syntax" "tsadvroot_fqadf##syntax"}{...}
{viewerjumpto "Description" "tsadvroot_fqadf##description"}{...}
{viewerjumpto "Options" "tsadvroot_fqadf##options"}{...}
{viewerjumpto "Bootstrap" "tsadvroot_fqadf##bootstrap"}{...}
{viewerjumpto "Source compatibility" "tsadvroot_fqadf##compat"}{...}
{viewerjumpto "Stored results" "tsadvroot_fqadf##results"}{...}
{viewerjumpto "Examples" "tsadvroot_fqadf##examples"}{...}
{viewerjumpto "References" "tsadvroot_fqadf##references"}{...}
{vieweralsosee "tsadvroot" "help tsadvroot"}{...}
{vieweralsosee "tsadvroot qadf" "help tsadvroot_qadf"}{...}
{vieweralsosee "tsadvroot npadf" "help tsadvroot_npadf"}{...}
{vieweralsosee "tsadvroot cisur" "help tsadvroot_cisur"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] qreg" "help qreg"}{...}
{title:Title}

{phang}
{bf:tsadvroot fqadf} {hline 2} Fourier quantile ADF unit-root test with
smooth structural changes (Li and Zheng 2018)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tsadvroot} {cmd:fqadf} {varname} {ifin}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt t:au(numlist)}}quantile(s) in (0,1); default
{cmd:tau(0.1(0.1)0.9)}{p_end}
{synopt:{opt m:odel(string)}}{cmd:c} (constant) or {cmd:ct} (constant and
trend){p_end}
{synopt:{opt l:ags(#)}}{it:fixed} number of lags of D.{it:varname}
(no selection); default {cmd:lags(8)}, the source default{p_end}
{synopt:{opt f:req(#)}}Fourier frequency k; default {cmd:freq(3)}, the
source default (Li-Zheng recommend trying k = 1, 2, 3){p_end}
{synopt:{opt nb:oot(#)}}bootstrap replications; default {cmd:nboot(1000)};
{cmd:nboot(0)} or {opt nobootstrap} skips the bootstrap{p_end}
{synopt:{opt seed(#)}}random-number seed for the bootstrap (0 = do not
set){p_end}
{synopt:{opt noboot:strap}}skip the bootstrap (statistics only){p_end}
{synopt:{opt gr:aph}}profile plot of t_n(tau) with bootstrap critical-value
curves{p_end}
{synopt:{opt na:me(string)}}graph name{p_end}
{synopt:{opt nopr:int}}suppress the results table{p_end}
{synoptline}
{p 4 6 2}The data must be {helpb tsset}, contiguous within the sample.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tsadvroot fqadf} implements the quantile unit-root test of Li and Zheng
(2018), which augments the Koenker-Xiao (2004) quantile autoregression with
a single-frequency Fourier component

{p 8 8 2}
sin(2 pi k t / n) and cos(2 pi k t / n)

{pstd}
that captures smooth (gradual) structural changes in the deterministic part
of the series without having to date any break. The t_n(tau) statistic is
the Koenker-Xiao t-ratio computed on the Fourier-augmented quantile
regression; because its distribution depends on the Fourier terms, inference
uses a residual-based bootstrap under the unit-root null (see below).


{marker options}{...}
{title:Options}

{phang}
{opt lags(#)}: unlike {helpb tsadvroot_qadf:qadf}, the number of lagged
differences is {it:fixed} (no information criterion), exactly as in the
source procedure. Use e.g. {cmd:lags(1)} or {cmd:lags(4)} for short series -
the source default of 8 costs 9 observations.

{phang}
{opt freq(#)} is the integer Fourier frequency k. Li and Zheng (2018)
find that a single small frequency (k up to 3) captures a wide variety of
smooth-break shapes.

{phang}
{opt nboot(#)}, {opt seed(#)}: number of bootstrap replications and RNG
seed. With several quantiles in {opt tau()}, each replication evaluates the
statistic at every requested quantile from the same pseudo-series.


{marker bootstrap}{...}
{title:Bootstrap procedure (Li and Zheng 2018, p. 86)}

{pstd}Exactly as in the source:{p_end}
{phang2}1. Estimate by OLS the null regression of y on the deterministics
(constant, trend if {cmd:model(ct)}), the full-sample Fourier terms and p
lagged differences; keep the residuals.{p_end}
{phang2}2. Fit an AR(1) (without constant) to those residuals; centre the
innovations.{p_end}
{phang2}3. Resample the centred innovations with replacement and cumulate
them into a pure random walk y*.{p_end}
{phang2}4. Recompute the full Fourier-QADF statistic on y* (including the
re-construction of the Fourier terms on the trimmed pseudo-sample).{p_end}
{phang2}5. Repeat {opt nboot()} times.{p_end}

{pstd}
{bf:Critical values.} The displayed decisions use the {it:left-tail} 1st,
5th and 10th percentiles of the bootstrap distribution (the test rejects for
large negative t_n), together with the bootstrap p-value
P(t_n* <= t_n observed). For strict source compatibility, the order
statistics computed by the GAUSS code - the 0.99 x B, 0.95 x B and
0.90 x B elements of the ascending-sorted bootstrap statistics - are also
stored, in columns 4-6 of {cmd:r(boot)} ({cmd:cvsrc1}, {cmd:cvsrc5},
{cmd:cvsrc10}). Note that those source order statistics are upper-tail
quantiles; for a left-tailed test the left-tail values (columns 1-3) are the
ones consistent with the bootstrap p-value.


{marker compat}{...}
{title:Source compatibility (qr_fourier_adf.src)}

{pstd}The following source conventions are reproduced exactly:{p_end}
{phang2}- lags are fixed at {opt lags()} (all p lags always included), no
selection;{p_end}
{phang2}- the test's Fourier terms are built on the {it:trimmed} sample:
the index restarts at 1 after dropping p+1 observations and the denominator
is the trimmed length (source line {cmd:t = rows(y)} after
{cmd:trimr});{p_end}
{phang2}- the bootstrap's null-model Fourier terms are instead built on the
{it:full} sample length before trimming (source order of operations);{p_end}
{phang2}- the trend regressor is the original observation index;{p_end}
{phang2}- in the t_n statistic the projection matrix P_X removes
{it:everything except} y_t-1 (constant, lagged differences, Fourier terms
and, under {cmd:model(ct)}, the trend);{p_end}
{phang2}- delta-squared uses w = quantile-regression residuals (source
passes {cmd:miss()});{p_end}
{phang2}- the pseudo-series has length T - p - 2 (AR(1) step loses one more
observation), and each bootstrap statistic is computed by the full test
routine on it;{p_end}
{phang2}- the GAUSS 0.99/0.95/0.90 order statistics are reported unchanged
in {cmd:r(boot)} columns 4-6.{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(T)}}sample size{p_end}
{synopt:{cmd:r(N)}}effective sample (T - p - 1){p_end}
{synopt:{cmd:r(lags)}}p{p_end}
{synopt:{cmd:r(k)}}Fourier frequency{p_end}
{synopt:{cmd:r(nboot)}}bootstrap replications{p_end}
{p2col 5 18 22 2: Scalars (only with a single tau)}{p_end}
{synopt:{cmd:r(tn)}}Fourier quantile ADF statistic{p_end}
{synopt:{cmd:r(rho_tau)}}quantile AR(1) coefficient{p_end}
{synopt:{cmd:r(delta2)}}delta-squared{p_end}
{synopt:{cmd:r(pboot)}}bootstrap p-value{p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}left-tail bootstrap
critical values{p_end}
{synopt:{cmd:r(cvsrc1)}, {cmd:r(cvsrc5)}, {cmd:r(cvsrc10)}}GAUSS-source
order statistics{p_end}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}per-quantile: tau, rho_tau, ., delta2, tn{p_end}
{synopt:{cmd:r(boot)}}per-quantile: cvlt1 cvlt5 cvlt10 cvsrc1 cvsrc5
cvsrc10 pboot{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{phang}{cmd:. webuse air2, clear}{p_end}
{phang}{cmd:. gen lair = ln(air)}{p_end}
{phang}{cmd:. tsadvroot fqadf lair, tau(0.5) model(ct) freq(1) lags(4) nboot(500) seed(12345)}{p_end}
{phang}{cmd:. tsadvroot fqadf lair, model(c) freq(2) lags(2) nboot(500) seed(1) graph}{p_end}
{phang}{cmd:. tsadvroot fqadf lair, tau(0.25 0.75) nobootstrap}{p_end}


{marker references}{...}
{title:References}

{phang}
Koenker, R., and Z. Xiao. 2004. Unit root quantile autoregression inference.
{it:Journal of the American Statistical Association} 99: 775-787.

{phang}
Li, H., and C. Zheng. 2018. Unit root quantile autoregression testing with
smooth structural changes. {it:Finance Research Letters} 25: 83-89.


{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}


{title:Also see}

{psee}
Help: {helpb tsadvroot}, {helpb tsadvroot_qadf}, {helpb tsadvroot_npadf},
{helpb tsadvroot_cisur}
{p_end}
