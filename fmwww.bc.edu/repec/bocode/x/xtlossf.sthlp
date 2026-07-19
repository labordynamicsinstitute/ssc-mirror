{smcl}
{* *! version 1.0.0  18jul2026}{...}
{vieweralsosee "xtoutliers" "help xtoutliers"}{...}
{vieweralsosee "xtvsom" "help xtvsom"}{...}
{vieweralsosee "xtrobust" "help xtrobust"}{...}
{vieweralsosee "xtoutliers methods" "help xtoutliers_methods"}{...}
{viewerjumpto "Syntax" "xtlossf##syntax"}{...}
{viewerjumpto "Description" "xtlossf##description"}{...}
{viewerjumpto "Options" "xtlossf##options"}{...}
{viewerjumpto "Method" "xtlossf##method"}{...}
{viewerjumpto "Output" "xtlossf##output"}{...}
{viewerjumpto "Examples" "xtlossf##examples"}{...}
{viewerjumpto "Stored results" "xtlossf##results"}{...}
{viewerjumpto "References" "xtlossf##references"}{...}
{viewerjumpto "Author" "xtlossf##author"}{...}
{title:Title}

{phang}
{bf:xtlossf} {hline 2} Distribution-free outlier detection via loss functions

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtlossf} {it:basevar} {it:futurevar} {ifin} [{cmd:,} {it:options}]

{p 8 15 2}
{cmd:xtlossf} {it:var} {ifin}{cmd:,} {cmd:lag} [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Loss}
{synopt:{opt q(#)}}loss exponent q; default {cmd:q(-0.5)}{p_end}
{synopt:{opt mix:edsign}}use the mixed-sign loss {cmd:|F-B|(|F|+|B|)}{c 94}{cmd:q} (Part II){p_end}
{synopt:{opt ti:nvariant(tvar)}}time-invariant loss, exponent {cmd:t*q+t-1} (Part I){p_end}
{synopt:{opt sig:ned}}also compute the signed loss and use two-sided bounds{p_end}
{synopt:{opt lag}}base = {cmd:L.}{it:var} within panel (chronological time){p_end}

{syntab:Critical value}
{synopt:{opt c(#)}}fixed critical value C{p_end}
{synopt:{opt quan:tile(#)}}C = the given quantile of the loss (0{c 45}1){p_end}
{synopt:{opt tu:key(#)}}C = Q3 + (#){c 215}IQR of the loss; default rule {cmd:tukey(1.5)}{p_end}
{synopt:{opt cp:lus(#)}}upper bound for the signed loss{p_end}
{synopt:{opt cm:inus(#)}}lower bound for the signed loss{p_end}

{syntab:Calibration / reporting}
{synopt:{opt fit}}estimate {cmd:q} and {cmd:C} from a criteria table by regression{p_end}
{synopt:{opt list(#)}}number of outliers to list; default {cmd:list(20)}{p_end}
{synopt:{opt graph}}draw the criticality and loss figures{p_end}
{synopt:{opt name(string)}}stub for graph names{p_end}
{synopt:{opt nolab:el}}show numeric panel codes instead of labels{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtlossf} detects outliers in panel data without any distributional
assumptions, following Coleman and Bryan (2025). It compares a {it:base} value
{cmd:B} and a {it:future}/comparison value {cmd:F} through a loss function and
flags observations whose loss exceeds a critical value {cmd:C}.{p_end}

{pstd}
Two data types are supported. For {bf:nonnegative} data (Part I) the loss is
{cmd:L = |F-B|{&times}B}{c 94}{cmd:q}; for {bf:mixed-sign} data (Part II, option
{opt mixedsign}) it is {cmd:L = |F-B|{&times}(|F|+|B|)}{c 94}{cmd:q}, with the
continuity convention {cmd:L(0,0)=0}. The signed loss (option {opt signed})
multiplies by the sign of {cmd:F-B} and uses separate upper/lower bounds so that
positive and negative outliers can be treated differently.{p_end}

{pstd}
{cmd:B} and {cmd:F} can be two variables (two versions of an estimate, or an
estimate versus its true value {c 45} {it:nominal} time), or successive periods
of one variable ({opt lag}, {it:chronological} time). The command saves the loss
and the outlier flag as {cmd:_xtlossf_L} and {cmd:_xtlossf_out} (and
{cmd:_xtlossf_S} when {opt signed}).{p_end}

{marker options}{...}
{title:Options}

{phang}{opt q(#)} is the loss exponent. {cmd:q=0} is the absolute difference;
{cmd:q=-1} is the (average) absolute relative difference; intermediate values
trade the two off. The default {cmd:q=-0.5} is the theoretically justified choice
when {cmd:B} and {cmd:F} are unbiased estimates whose variance is proportional to
the level (Part I).{p_end}

{phang}{opt tinvariant(tvar)} incorporates elapsed time so losses at different
horizons are comparable. The time variable is rescaled so its last value is 1,
and the exponent becomes {cmd:t*q+t-1} (nonnegative data only).{p_end}

{phang}{opt c(#)}, {opt quantile(#)}, {opt tukey(#)} set the critical value C. If
none is given, the Tukey upper fence {cmd:Q3 + 1.5{&times}IQR} of the loss is
used. C is an empirical choice; there is no significance test, by design.{p_end}

{phang}{opt fit} switches to calibration mode: supply a small table whose two
variables are the base-size midpoints and the {cmd:{&epsilon}} midpoints of a set
of preexisting outlier criteria; {cmd:xtlossf} regresses
{cmd:log {&epsilon} = -q log B + K} and reports the implied {cmd:q} and
{cmd:C = exp(K)} (source paper, Eq. I.19{c 45}I.20).{p_end}

{marker method}{...}
{title:Method}

{pstd}
The loss function is derived axiomatically (symmetry, monotone in the difference,
decreasing in the level); a Lie symmetry fixes the difference exponent to 1,
leaving {cmd:q}. An observation is an outlier whenever {cmd:L > C}. The boundary
{cmd:L = C} is a straight line in log{c 45}log space, which is what the
criticality graph plots. Full derivations:
{helpb xtoutliers_methods:xtoutliers methods}.{p_end}

{marker output}{...}
{title:Interpreting the output}

{phang}o {bf:Critical value C} {c 45} the loss threshold and the rule used to set
it.{p_end}

{phang}o {bf:Outliers} {c 45} count and share; the listing shows the largest-loss
units with their base, future, and loss values (and panel/time labels when
{helpb xtset}).{p_end}

{phang}o {bf:graph} {c 45} (a) the criticality plot in logs with the {cmd:L=C}
line (points above are outliers); (b) the loss by observation with the cutoff.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Compare two census counts (nonnegative, q=-1/2):{p_end}
{phang2}{cmd:. xtlossf pop2010 pop2020 , q(-0.5) graph}{p_end}

{pstd}Successive periods of one series, chronological time:{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xtlossf sales , lag q(-0.5) tukey(3)}{p_end}

{pstd}Mixed-sign data with signed bounds:{p_end}
{phang2}{cmd:. xtlossf forecast actual , mixedsign signed}{p_end}

{pstd}Calibrate q and C from a criteria table:{p_end}
{phang2}{cmd:. xtlossf Bmid epsmid , fit}{p_end}

{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations used{p_end}
{synopt:{cmd:r(nout)}}number of outliers{p_end}
{synopt:{cmd:r(q)}}loss exponent{p_end}
{synopt:{cmd:r(C)}}critical value{p_end}
{synopt:{cmd:r(Cplus)}, {cmd:r(Cminus)}}signed bounds (if {opt signed}){p_end}
{synopt:{cmd:r(K)}}intercept (in {opt fit} mode){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(part)}}I (nonnegative) or II (mixed sign){p_end}

{pstd}And the variables {cmd:_xtlossf_L}, {cmd:_xtlossf_out} (and
{cmd:_xtlossf_S}) are added to the data.{p_end}

{marker references}{...}
{title:References}

{phang}Coleman, C.D., and T. Bryan. 2025. Loss Functions for Detecting Outliers
in Panel Data. arXiv:2509.07014v2.{p_end}

{phang}Coleman, C.D. 2025. Loss Functions for Measuring the Accuracy of
Nonnegative Cross-Sectional Predictions. arXiv:2505.18130.{p_end}

{phang}Tukey, J.W. 1977. {it:Exploratory Data Analysis}. Addison-Wesley.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
