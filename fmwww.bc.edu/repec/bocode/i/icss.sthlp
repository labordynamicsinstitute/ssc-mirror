{smcl}
{* 23jul2026}{...}
{vieweralsosee "icss methods" "help icss_methods"}{...}
{vieweralsosee "flexur (library)" "help flexur"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tsset" "help tsset"}{...}
{viewerjumpto "Syntax" "icss##syntax"}{...}
{viewerjumpto "Description" "icss##description"}{...}
{viewerjumpto "Options" "icss##options"}{...}
{viewerjumpto "Examples" "icss##examples"}{...}
{viewerjumpto "Stored results" "icss##results"}{...}
{viewerjumpto "Interpreting the output" "icss##interpret"}{...}
{viewerjumpto "Remarks" "icss##remarks"}{...}
{viewerjumpto "References" "icss##refs"}{...}
{title:Title}

{phang}
{bf:icss} {hline 2} Iterated Cumulative Sum of Squares test for changes in the
unconditional variance of a time series (Sansó, Aragó & Carrion-i-Silvestre, 2004)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:icss} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt t:est(string)}}test statistic: {cmd:it}, {cmd:k1}, {cmd:k2} (default) or
{cmd:all}{p_end}
{synopt:{opt k:ernel(string)}}long-run kernel for {cmd:k2}: {cmd:qs} (default) or
{cmd:bartlett}{p_end}
{synopt:{opt b:width(#)}}fixed bandwidth for {cmd:k2}; omit for automatic
selection{p_end}
{synopt:{opt bin:it(#)}}initial parameter for automatic bandwidth (default 4){p_end}
{synopt:{opt nodem:ean}}do not subtract the sample mean before testing{p_end}
{synopt:{opt all}}run the three tests IT, {it:kappa1} and {it:kappa2}{p_end}

{syntab:Plot}
{synopt:{opt g:raph}}plot the squared series with the detected breaks and
segment variances{p_end}
{synopt:{opt gname(name)}}name of the graph{p_end}
{synopt:{opt graphopts(str)}}any {help twoway} options passed to the graph{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}The series should be a zero-mean (or mean-removed) stochastic process such
as asset {it:returns} or a regression residual. {cmd:icss} works on the sample
defined by {cmd:tsset} when set; otherwise the data are used in dataset order.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:icss} implements the Iterated Cumulative Sum of Squares (ICSS) algorithm of
Inclán and Tiao (1994) to detect multiple changes in the {it:unconditional}
variance of a time series, using the three test statistics studied by Sansó,
Aragó and Carrion-i-Silvestre (2004):

{p 8 12 2}{bf:IT} {hline 1} the original Inclán-Tiao statistic. Valid only for
i.i.d. mesokurtic (Gaussian-kurtosis) data; it over-rejects for leptokurtic
series and for conditionally heteroskedastic ((G)ARCH) series.{p_end}
{p 8 12 2}{bf:kappa1} {hline 1} corrects the statistic for non-mesokurtosis
(excess/deficient kurtosis) but still assumes serial independence.{p_end}
{p 8 12 2}{bf:kappa2} {hline 1} additionally corrects for persistence in the
conditional variance through a nonparametric long-run fourth-moment estimator
(Bartlett or quadratic-spectral kernel with automatic Newey-West (1994)
bandwidth). This is the statistic the authors {bf:recommend} for financial data.{p_end}

{pstd}
For each requested test, {cmd:icss} reports the whole-sample statistic, its 5%
finite-sample critical value (from the paper's response surface), an asymptotic
p-value, and the full set of break dates located by the iterative ICSS
procedure. See {helpb icss_methods:help icss methods} for the equation-by-equation
derivation and the step-to-equation map.

{pstd}
{cmd:icss} is part of the {helpb flexur:flexur} library of flexible unit-root and
stationarity tests.

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt test(string)} selects the statistic. {cmd:it} = Inclán-Tiao; {cmd:k1} =
{it:kappa1}; {cmd:k2} = {it:kappa2} (the default and recommended choice);
{cmd:all} reports all three side by side (reproduces the comparison in the
paper's Table 12).

{phang}
{opt kernel(string)} chooses the kernel used to estimate the long-run
fourth moment for {cmd:k2}: {cmd:qs} (quadratic spectral, default) or
{cmd:bartlett}. Ignored for {cmd:it} and {cmd:k1}.

{phang}
{opt bwidth(#)} fixes the bandwidth (lag truncation) for the {cmd:k2} long-run
estimator. If omitted, the bandwidth is chosen automatically by the Newey-West
(1994) data-dependent rule.

{phang}
{opt binit(#)} sets the initial parameter of the automatic bandwidth rule
(the paper uses 4, the default).

{phang}
{opt nodemean} skips subtraction of the sample mean. By default {cmd:icss}
analyzes {it:e = x - mean(x)}; use this option when the input is already a
zero-mean series.

{phang}
{opt all} is a synonym for {cmd:test(all)}.

{dlgtab:Plot}

{phang}
{opt graph} draws the squared (de-meaned) series together with a step function
of the ICSS segment variances and vertical lines at the detected break dates, in
the style of Figure 1 of Sansó et al. (2004).

{phang}
{opt gname(name)} assigns a name to the graph (with {cmd:replace}).

{phang}
{opt graphopts(string)} passes any additional {help twoway} options to the graph.

{marker examples}{...}
{title:Examples}

{pstd}Load a return series and test with the recommended {it:kappa2} statistic:{p_end}
{phang2}{cmd:. tsset date}{p_end}
{phang2}{cmd:. icss ret, test(k2)}{p_end}

{pstd}Compare all three statistics (as in Table 12 of the paper):{p_end}
{phang2}{cmd:. icss ret, test(all)}{p_end}

{pstd}Bartlett kernel with a fixed bandwidth of 6 and a break plot:{p_end}
{phang2}{cmd:. icss ret, test(k2) kernel(bartlett) bwidth(6) graph}{p_end}

{pstd}A quick simulated check (one true break at t=250):{p_end}
{phang2}{cmd:. set obs 500}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen double y = rnormal()*cond(t<=250,1,2)}{p_end}
{phang2}{cmd:. icss y, test(k2) graph}{p_end}

{pstd}A full self-test harness ships with the package:{p_end}
{phang2}{cmd:. do icss_example.do}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:icss} is {cmd:rclass}. It stores (values shown are for the last test in
the list; per-test copies carry the suffix {cmd:_0}=IT, {cmd:_1}=kappa1,
{cmd:_2}=kappa2):{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(T)}}number of usable observations{p_end}
{synopt:{cmd:r(nbreaks)}}number of detected changes in variance{p_end}
{synopt:{cmd:r(stat_}{it:#}{cmd:)}}whole-sample statistic{p_end}
{synopt:{cmd:r(cv5_}{it:#}{cmd:)}}5% response-surface critical value{p_end}
{synopt:{cmd:r(pval_}{it:#}{cmd:)}}asymptotic p-value{p_end}
{synopt:{cmd:r(nbreaks_}{it:#}{cmd:)}}number of breaks for test {it:#}{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:icss}{p_end}
{synopt:{cmd:r(tests)}}list of tests run{p_end}
{synopt:{cmd:r(kernel)}}kernel used{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(breaks)}}positions of the detected breaks{p_end}
{synopt:{cmd:r(segs)}}per-segment {it:from}, {it:to}, {it:variance}, {it:sd}{p_end}
{p2colreset}{...}

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:Whole-sample statistic vs 5% critical value} {hline 1} a value above the
critical value rejects the null of a constant unconditional variance over the
{it:whole} sample. The p-value is computed from the asymptotic sup|Brownian
bridge| distribution common to the three statistics.

{pstd}
{bf:Detected changes in variance} {hline 1} the ICSS algorithm partitions the
sample; each row is a break with its observation number, its calendar date (when
{cmd:tsset} is in effect) and the standard deviation of the segment that follows
it.

{pstd}
{bf:Reading across tests} {hline 1} if {cmd:it} (and often {cmd:k1}) flag many
breaks while {cmd:k2} flags few or none, the extra breaks are most likely
{it:spurious}, driven by fat tails and/or volatility clustering rather than by
genuine level shifts in variance. This is the central message of Sansó et al.
(2004): prefer {cmd:k2} for financial series.

{marker remarks}{...}
{title:Remarks and practical guidance}

{phang}o Feed {cmd:icss} a mean-zero series: asset {it:returns}, or residuals from
a mean/trend regression. Prices or trending levels violate the constant-mean
assumption.{p_end}

{phang}o Break detection uses the 5% finite-sample critical value throughout, as
in the original GAUSS code; the reported p-value is for the whole-sample test
only.{p_end}

{phang}o For strongly persistent (near-IGARCH) processes all three tests can
diverge and detect spurious breaks; in that case model the conditional variance
directly (e.g. {helpb arch}) instead of treating the volatility as piecewise
constant.{p_end}

{phang}o A minimum of about 15 observations is required; break locations are
approximate to within a few observations, as is inherent to the ICSS search.{p_end}

{marker refs}{...}
{title:References}

{phang}Inclán, C., and G. C. Tiao. 1994. Use of cumulative sums of squares for
retrospective detection of changes of variance. {it:Journal of the American
Statistical Association} 89: 913-923.{p_end}

{phang}Newey, W. K., and K. D. West. 1994. Automatic lag selection in covariance
matrix estimation. {it:Review of Economic Studies} 61: 631-653.{p_end}

{phang}Sansó, A., V. Aragó, and J. L. Carrion-i-Silvestre. 2004. Testing for
changes in the unconditional variance of financial time series. {it:Revista de
Economía Financiera} 4: 32-53.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS routines {cmd:icss.src} / {cmd:variance.src}
by A. Sansó, V. Aragó and J. L. Carrion-i-Silvestre. Part of the
{helpb flexur:flexur} library.{p_end}
