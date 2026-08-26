{smcl}
{* *! version 1.0.0  24aug2026}{...}
{vieweralsosee "ardldml" "help ardldml"}{...}
{vieweralsosee "ardldml methods" "help ardldml_methods"}{...}
{vieweralsosee "ardldml postestimation" "help ardldml_postestimation"}{...}
{viewerjumpto "The data" "ardldml_examples##data"}{...}
{viewerjumpto "A first fit" "ardldml_examples##first"}{...}
{viewerjumpto "The full workflow" "ardldml_examples##workflow"}{...}
{viewerjumpto "Four regimes" "ardldml_examples##regimes"}{...}
{viewerjumpto "Simulated data" "ardldml_examples##simulated"}{...}
{viewerjumpto "Reproducing the reference" "ardldml_examples##reference"}{...}
{viewerjumpto "Author" "ardldml_examples##author"}{...}

{title:Title}

{phang}
{bf:ardldml examples} {hline 2} a worked session with {helpb ardldml}


{marker data}{...}
{title:The data}

{pstd}
The package ships the monthly series behind the paper's main application:
exchange-rate pass-through to U.S. prices, nine FRED-MD series over 1973m1 to
2020m12. Retrieve them with {cmd:net get}:

{phang2}{cmd:. net get ardldml}{p_end}
{phang2}{cmd:. use ardldml_passthrough, clear}{p_end}
{phang2}{cmd:. describe}{p_end}

{pstd}
The paper takes the log CPI as the outcome and the log trade-weighted dollar as
the focal regressor, conditioning on seven macroeconomic and financial controls.
Take the logs yourself -- {cmd:ardldml} does no transformation:

{phang2}{cmd:. foreach v in cpi neer m2 ip oil {c -(}}{p_end}
{phang2}{cmd:.     replace `v' = ln(`v')}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. tsset mdate}{p_end}

{pstd}
The four interest and unemployment rates stay in levels: they are already in
percentage-point units and can approach zero.


{marker first}{...}
{title:A first fit}

{pstd}
The late Great Moderation, 1999m1-2007m12, which is the regime where the paper's
diagnostic changes the verdict:

{phang2}{cmd:. keep if inrange(mdate, tm(1999m1), tm(2007m12))}{p_end}
{phang2}{cmd:. ardldml cpi neer, controls(m2 ffr ip unrate oil gs10 baa)}{break}
{cmd:      integrated(m2 ip oil gs10 baa ffr) lags(4) blocks(5) buffer(6)}{break}
{cmd:      breps(999) seed(20260625) showfirst}{p_end}

{pstd}
Points worth noticing in the output. The design length is 103, not 108: the
lag structure consumes p+1 observations. Six of the seven controls are being
treated as I(1), which is what makes the trend-absorption mechanism live. And
{opt showfirst} reports that the m_Z projection kept just one control level --
the empirical counterpart of a high effective integrated count, meaning very
little trend was absorbed here.

{pstd}
{bf:Do not read the statistic against 4.94 or 5.73.} The bootstrap critical
value in the table is the only valid reference.


{marker workflow}{...}
{title:The full workflow}

{pstd}
A single fit is never the answer. The three checks below are what turn it into a
result.

{pstd}
{bf:1. Is the control set eating the relation?}

{phang2}{cmd:. estat absorption, drop(m2 oil)}{p_end}

{pstd}
Money and the oil price are dropped because they are the controls most likely to
share a stochastic trend with the pass-through relation itself. Read Delta_W and
the verdict line together with the four standard errors.

{pstd}
{bf:2. Does the verdict survive the tuning choices?}

{phang2}{cmd:. estat penalty}{p_end}

{pstd}
Watch the {cmd:selZ} column and whether theta keeps its sign across the grid.

{pstd}
{bf:3. What would the classical test have said?}

{phang2}{cmd:. estat classical}{p_end}

{pstd}
The bracket is simulated at this sample size, so it is a fair comparison rather
than an asymptotic table applied to 103 observations.

{pstd}
{bf:And look at the null you are testing against:}

{phang2}{cmd:. estat null}{p_end}
{phang2}{cmd:. estat blocks, graph}{p_end}


{marker regimes}{...}
{title:Four regimes at once}

{pstd}
The paper's Table 11 runs the test separately across four monetary regimes. The
loop below reproduces its structure and collects the results:

{phang2}{cmd:. use ardldml_passthrough, clear}{p_end}
{phang2}{cmd:. foreach v in cpi neer m2 ip oil {c -(}}{p_end}
{phang2}{cmd:.     replace `v' = ln(`v')}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. tsset mdate}{p_end}
{phang2}{cmd:. tempname M}{p_end}
{phang2}{cmd:. matrix `M' = J(4, 4, .)}{p_end}
{phang2}{cmd:. local i = 0}{p_end}
{phang2}{cmd:. foreach r in "1973m1 1985m12" "1986m1 1998m12" ///}{p_end}
{phang2}{cmd:              "1999m1 2007m12" "2008m1 2020m12" {c -(}}{p_end}
{phang2}{cmd:.     local ++i}{p_end}
{phang2}{cmd:.     local a : word 1 of `r'}{p_end}
{phang2}{cmd:.     local b : word 2 of `r'}{p_end}
{phang2}{cmd:.     preserve}{p_end}
{phang2}{cmd:.     keep if inrange(mdate, tm(`a'), tm(`b'))}{p_end}
{phang2}{cmd:.     ardldml cpi neer, controls(m2 ffr ip unrate oil gs10 baa) ///}{p_end}
{phang2}{cmd:         integrated(m2 ip oil gs10 baa ffr) lags(4) blocks(5) ///}{p_end}
{phang2}{cmd:         buffer(6) breps(999) seed(`=20260625 + `i'') notable nolegend}{p_end}
{phang2}{cmd:.     matrix `M'[`i',1] = e(N)}{p_end}
{phang2}{cmd:.     matrix `M'[`i',2] = e(F)}{p_end}
{phang2}{cmd:.     matrix `M'[`i',3] = e(crit)}{p_end}
{phang2}{cmd:.     matrix `M'[`i',4] = e(p)}{p_end}
{phang2}{cmd:.     restore}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. matrix colnames `M' = n F boot_cv95 boot_p}{p_end}
{phang2}{cmd:. matrix list `M', format(%9.3f)}{p_end}

{pstd}
Note the {cmd:seed()} is varied across regimes. Reusing one seed would give
every regime the same wild-weight stream, which is not wrong but is needlessly
correlated across the table.


{marker simulated}{...}
{title:Simulated data: does it have size and power?}

{pstd}
The shipped {cmd:ardldml_example.do} includes a Monte Carlo check on the
paper's own design: independent random walks under the null, and a genuinely
cointegrated system under the alternative, with high-dimensional nuisance in
both. Run it to see the rejection rate near or below nominal under the null and
high under the alternative:

{phang2}{cmd:. net get ardldml}{p_end}
{phang2}{cmd:. do ardldml_example.do}{p_end}

{pstd}
The one trap when writing your own size study: {bf:vary the seed on every
replication}. Calling {cmd:ardldml} with a fixed {cmd:seed()} resets the
random-number stream to the same state each time, so every replication draws the
same wild weights and the size estimate becomes degenerate. The data varying per
replication is not enough.


{marker reference}{...}
{title:Reproducing the reference implementation}

{pstd}
{cmd:ardldml_validate.do} checks sixty quantities against an independent Python
implementation of the same paper, on the paper's own application:

{phang2}{cmd:. do ardldml_validate.do}{p_end}

{pstd}
It prints reference and Stata values side by side and exits with an error if any
disagree. See {helpb ardldml_methods:ardldml methods} for what "agree" means
here and for the one published figure that turns out to be a solver-tolerance
artifact in the reference rather than a difference in method.

{pstd}
To reproduce a bootstrap {it:exactly} across languages, export the wild weights
from the other implementation as a B-by-n text matrix and feed them in:

{phang2}{cmd:. ardldml cpi neer, controls(...) integrated(...) etafile(eta.txt)}{p_end}

{pstd}
where n is the design length {cmd:e(N)}. Seeding alone will not do it: Stata's
random-number generator is not NumPy's.


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
