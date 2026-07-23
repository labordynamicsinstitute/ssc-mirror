{smcl}
{* *! version 1.0.0  20jul2026}{...}
{vieweralsosee "bootur" "help bootur"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Model" "bootur_methods##model"}{...}
{viewerjumpto "ADF regression" "bootur_methods##adf"}{...}
{viewerjumpto "Detrending" "bootur_methods##detrend"}{...}
{viewerjumpto "Lag selection" "bootur_methods##lag"}{...}
{viewerjumpto "Bootstrap schemes" "bootur_methods##boot"}{...}
{viewerjumpto "Union test" "bootur_methods##union"}{...}
{viewerjumpto "Multiple testing" "bootur_methods##mult"}{...}
{viewerjumpto "Compatibility map" "bootur_methods##map"}{...}
{title:Title}

{phang}
{bf:bootur methods} {hline 2} Methodology and step-to-equation map for {helpb bootur}

{marker model}{...}
{title:Model and hypotheses}

{pstd}
For a series y(t) the augmented Dickey-Fuller (ADF) regression is

{p 12 12 2}{cmd:d.y(t) = gamma*y(t-1) + sum_{j=1..p} phi(j)*d.y(t-j) + d(t)'beta + e(t),}

{pstd}
where d(t) collects the deterministic terms. The unit root null is
{cmd:H0: gamma = 0} (a unit root; the largest autoregressive root equals one)
against the stationary alternative {cmd:Ha: gamma < 0}. The reported
"estimate of the largest root" is {cmd:1 + gamma^hat}.

{marker adf}{...}
{title:ADF test statistic}

{pstd}
The test statistic is the usual t-ratio on gamma^hat. Following Palm, Smeekes
and Urbain (2008), the bootstrap is a {it:residual} (under-the-alternative)
bootstrap: the model above is estimated on the observed data and two residual
series are retained -- the full residuals e^hat(t) (used for the sieve
schemes) and the restricted residuals under the null,
{cmd:eb(t) = d.y(t) - gamma^hat*y(t-1)} (used as the increments for the
resampling and wild schemes).

{marker detrend}{...}
{title:Detrending (OLS and QD)}

{pstd}
Two-step detrending removes the deterministic component before running the ADF
regression. With {cmd:detrend(OLS)} the terms are removed by ordinary least
squares; with {cmd:detrend(QD)} by quasi-differencing at the local-to-unity
point cbar/T (Elliott, Rothenberg and Stock, 1996), with cbar = 7 for an
intercept and cbar = 13.5 for an intercept and trend. {cmd:detrend(OLS)} gives
the standard ADF test and {cmd:detrend(QD)} the DF-GLS test. The {cmd:adf}
subcommand also offers one-step detrending ({cmd:onestep}), in which the
deterministic terms enter the regression directly.

{marker lag}{...}
{title:Lag length selection}

{pstd}
The lag order p is chosen between {opt minlag()} and {opt maxlag()} by an
information criterion: {cmd:AIC}, {cmd:BIC}, or the modified criteria
{cmd:MAIC}/{cmd:MBIC} of Ng and Perron (2001) with the Perron and Qu (2008)
correction (all lags are evaluated on a common sample). With {cmd:scale(1)}
the criteria are rescaled for nonstationary volatility using the
Nadaraya-Watson variance estimator of Cavaliere et al. (2015). Setting
{cmd:minlag()} equal to {cmd:maxlag()} fixes the lag length. The default
{opt maxlag()} follows a Schwert-type rule with a small-sample correction.

{marker boot}{...}
{title:Bootstrap schemes}

{pstd}
Let l be the block length. The bootstrap builds a pseudo series by cumulating
resampled or reweighted increments:{p_end}
{phang2}{cmd:MBB} {hline 1} moving-block bootstrap: resample blocks of the
increments (Paparoditis and Politis, 2003; Palm, Smeekes and Urbain, 2011).{p_end}
{phang2}{cmd:BWB} {hline 1} block wild bootstrap: multiply blocks by i.i.d.
N(0,1) draws (Shao, 2011; Smeekes and Urbain, 2014).{p_end}
{phang2}{cmd:DWB} {hline 1} dependent wild bootstrap: multiply by a Gaussian
vector with the trapezoidal self-convolution covariance (Shao, 2010; Rho and
Shao, 2019). The weight matrix is the matrix square root of that covariance,
with eigenvalues floored at 1e-10 and eigenvectors sign-normalised for
cross-platform reproducibility.{p_end}
{phang2}{cmd:AWB} {hline 1} autoregressive wild bootstrap (default): an AR(1)
wild sequence with parameter {cmd:ar = 0.01^(1/l)} (Smeekes and Urbain, 2014;
Friedrich, Smeekes and Urbain, 2020).{p_end}
{phang2}{cmd:SB}/{cmd:SWB} {hline 1} sieve and sieve-wild bootstraps: regenerate
the increments through the fitted AR filter using resampled ({cmd:SB}) or
wild-reweighted ({cmd:SWB}) sieve residuals (Chang and Park, 2003; Cavaliere and
Taylor, 2009; Smeekes and Taylor, 2012).{p_end}

{pstd}
Every bootstrap replication recomputes the {it:entire} statistic, including the
information-criterion lag selection, so the bootstrap distribution reflects the
selection uncertainty of the observed statistic (this is essential for correct
size).

{marker union}{...}
{title:Union test}

{pstd}
The union statistic is the minimum, over the four combinations of deterministic
component (intercept; intercept and trend) and detrending (OLS; QD), of the
individual statistics each scaled by its own bootstrap quantile at the level
{opt level()} (Harvey, Leybourne and Taylor, 2012; Smeekes and Taylor, 2012).
No deterministic specification need be chosen.

{marker mult}{...}
{title:Multiple-testing control}

{pstd}
{cmd:fdr} implements the step-down procedure controlling the false discovery
rate (Moon and Perron, 2012; Romano, Shaikh and Wolf, 2008): critical values
are built from the ordered bootstrap statistics so that the expected proportion
of false rejections is bounded by {opt level()}. {cmd:sqt} implements the
bootstrap sequential quantile test (Smeekes, 2015): groups of series defined by
{opt steps()} are tested in sequence until the first non-rejection; with unit
steps this is the StepM procedure of Romano and Wolf (2005). {cmd:panel} averages
the individual statistics into the group-mean statistic and compares it with the
bootstrap distribution of the average.

{marker map}{...}
{title:Step-to-equation map}

{pstd}This Stata port reproduces the R package {bf:bootUR} routine by routine.{p_end}
{p2colset 5 34 36 2}{...}
{p2col:{cmd:bu_adf_fit}}ADF regression; t- and normalised statistics{p_end}
{p2col:{cmd:bu_detrend}}OLS / QD (GLS) detrending{p_end}
{p2col:{cmd:bu_ic}, {cmd:bu_selectlags}}AIC/BIC/MAIC/MBIC lag selection{p_end}
{p2col:{cmd:bu_rescale}, {cmd:bu_npve}}nonstationary-volatility rescaling{p_end}
{p2col:{cmd:bu_dgp_panel}}residual bootstrap DGP{p_end}
{p2col:{cmd:bu_boot_dgp}}MBB/BWB/DWB/AWB/SB/SWB pseudo series{p_end}
{p2col:{cmd:bu_dwb_s}}DWB self-convolution weight matrix{p_end}
{p2col:{cmd:bu_scaling}, {cmd:bu_union}}union scaling and statistic{p_end}
{p2col:{cmd:bu_iadf}}bootstrap p-values{p_end}
{p2col:{cmd:bu_fdr}}false-discovery-rate step-down{p_end}
{p2col:{cmd:bu_bsqt}}sequential quantile test{p_end}
{p2col:{cmd:bu_fpval}}MacKinnon (1996) asymptotic p-value{p_end}
{p2colreset}{...}

{pstd}
The deterministic parts (ADF statistics, gamma estimates, selected lags and the
MacKinnon p-values) reproduce the R output to machine precision; the bootstrap
p-values are Monte Carlo estimates and therefore differ only by simulation
noise for a given random-number seed.

{title:Author}

{pstd}Dr Merwan Roudane {hline 1} merwanroudane920@gmail.com {hline 1}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
