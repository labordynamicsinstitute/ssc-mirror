{smcl}
{* *! version 1.0.2  19jul2024}{...}
{* *! Sebastian Kripfganz, www.kripfganz.de}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[R] regress postestimation time series" "help regress postestimationts"}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtdpdserial##syntax"}{...}
{viewerjumpto "Description" "xtdpdserial##description"}{...}
{viewerjumpto "Options" "xtdpdserial##options"}{...}
{viewerjumpto "Remarks" "xtdpdserial##remarks"}{...}
{viewerjumpto "Example" "xtdpdserial##example"}{...}
{viewerjumpto "Saved results" "xtdpdserial##results"}{...}
{viewerjumpto "Version history and updates" "xtdpdserial##update"}{...}
{viewerjumpto "Author" "xtdpdserial##author"}{...}
{viewerjumpto "References" "xtdpdserial##references"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{bf:xtdpdserial} {hline 2}}Panel data serial correlation tests{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{phang}
Syntax 1

{p 8 16 2}{cmd:xtdpdserial} [{varname}] {ifin} [{cmd:,} {it:{help xtdpdserial##options:options}}]

{phang}
Syntax 2

{p 8 16 2}{cmd:xtdpdserial} [{varname}] {ifin} [{cmd:,} {opt s:tatistics}{cmd:(}{it:{help xtdpdserial##statistics:statistics}}{cmd:)} {opt nor:esiduals}]


{marker options}{...}
{synoptset 21 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Main}
{synopt:{opt pm}}compute portmanteau test{p_end}
{synopt:{opt d:ifference}}compute test based on first differences{p_end}
{synopt:{opt sd:ifference}}compute test based on seasonal differences{p_end}
{synopt:{opt o:rder(#)}}restrict maximum order of serial correlation{p_end}
{synopt:{opt l:agrange(#_1 [#_2])}}restrict range of lags to be used{p_end}
{synopt:[{cmdab:full:}]{opt c:ollapse}}compute collapsed version of the test{p_end}
{synopt:{opt nof:orward}}ignore forward-looking covariance restrictions{p_end}
{synopt:{opt nob:ackward}}ignore backward-looking covariance restrictions{p_end}
{synopt:{opt nor:esiduals}}do not check for regression residuals; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
Syntax 1 computes a single test statistic as specified.{p_end}

{marker statistics}{...}
{p 4 6 2}
In Syntax 2, {it:statistics} can be one or more of

{p 8 12 2}
{it:stat}[{opt c}][{cmd:(}{it:#_1} [{it:#_2}]{cmd:)}]

{pmore}
where {it:stat} refers to one of the statistics below, which correspond to the minimum abbreviations of the respective Syntax 1 options.
The optional element {opt c} requests a collapsed version of the test (for statistics {cmd:d} or {cmd:sd}).
The optional syntax component {cmd:(}{it:#_1}{cmd:)} with one argument is equivalent to specifying {opt order(#_1)} from Syntax 1.
With two arguments, {cmd:(}{it:#_1} {it:#_2}{cmd:)} is equivalent to specifying {opt lagrange(#_1 #_2)} from Syntax 1.

{synoptset 21 tabbed}{...}
{synopthdr:stat}
{synoptline}
{synopt:{opt pm}}compute portmanteau test{p_end}
{synopt:{opt c}|{opt fullc}}compute collapsed portmanteau test{p_end}
{synopt:{opt d}}compute test based on first differences{p_end}
{synopt:{opt sd}}compute test based on seasonal differences{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
The default is Syntax 2 with {cmd:statistics(pm sdc dc fullc)}.{p_end}

{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:xtdpdserial}; see {helpb xtset:[XT] xtset}.{p_end}
{p 4 6 2}
{it:varname} may contain time-series operators; see {help tsvarlist}.{p_end}
{p 4 6 2}
{cmd:xtdpdserial} is a community-contributed program. The current version requires Stata version 13 or higher; see {help xtdpdserial##update:version history and updates}.{p_end}
{p 4 6 2}
If {it:varname} is not specified, {cmd:xtdpdserial} can be used as a postestimation command for {helpb regress}, {helpb xtreg:xtreg, fe}, and {helpb xtreg:xtreg, re},
as well as the community-contributed commands {helpb xtdpdbc} and {helpb xtdpdgmm}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdpdserial} implements serial correlation tests for linear panel data models that fall into the framework of the portmanteau test developed by Jochmans (2020).
Special cases are the Arellano and Bond (1991) and Yamagata (2008) tests, and further variants proposed by Kripfganz, Demetrescu, and Hosseinkouchack (2024) designed to improve the power of the test.

{pstd}
By default, these are postestimation tests for serial correlation in the idiosyncratic error component e_it from a linear error components model with combined error term u_i + e_it, where u_i is the group-specific error component.
The test accounts for the estimation error in the regression residuals. If {it:varname} is specified, the command applies a standalone test to the specified variable instead of residuals.

{pstd}
Applied to regression residuals, these tests allow the independent variables in the regression model to be strictly exogenous, predetermined, or endogenous,
as long as the estimator is consistent under the null hypothesis of serially uncorrelated errors. The tests are robust to heteroskedasticity by construction.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt pm} requests to compute the portmanteau test using all available covariance restrictions, as proposed by Jochmans (2020).

{phang}
{opt difference} requests to compute the test with covariance restrictions entirely based on first differences, as proposed by Arellano and Bond (1991) and Yamagata (2008).

{phang}
{opt sdifference} requests to compute the tests with restrictions on the covariances between first differences and seasonal differences, as proposed by Kripfganz, Demetrescu, and Hosseinkouchack (2024).

{phang}
{opt order(#)} requests to exclude covariance restrictions that are unaffected by serial correlation of up to order {it:#}. By default, arbitrary higher-order serial correlation is allowed under the alternative hypothesis.
{opt order(#)} is equivalent to {cmd:lagrange(2 }{it:#}{cmd:)}, unless option {opt difference} is also specified, in which case it is equivalent to {cmd:lagrange(2 }{it:#-1}{cmd:)}.

{phang}
{opt lagrange(#_1 [#_2])} limits the range of lags of {it:varlist} to be used in the backward-looking covariance restrictions. By default, {cmd:lagrange(2 .)}, all available lags from lag 2 onwards are used.
Alternative lower and upper bounds can be specified with {it:#_1} and {it:#_2}, respectively. A missing value for {it:#_2} requests all available lags to be used starting with {it:#_1}.
{opt lagrange(#_1)} with only one argument is equivalent to {opt lagrange(#_1 #_1)} with two identical arguments. If option {opt difference} is specified, the lag range refers to lags of first differences.

{phang}
{opt collapse} or {opt fullcollapse} request to compute a collapsed version of the test, which involves sums of covariance restrictions, to limit the degrees of freedom,
as proposed by Kripfganz, Demetrescu, and Hosseinkouchack (2024). With {opt fullcollapse}, the degrees of freedom are reduced to 1.

{phang}
{opt noforward} requests to ignore forward-looking covariance restrictions. This option is implied by option {opt difference} but otherwise seldom used.

{phang}
{opt nobackward} requests to ignore backward-looking covariance restrictions. This option is seldom used.

{phang}
{opt noresiduals} requests to skip checks whether {it:varname} is collinear with the regression residuals from the previously estimated model. This option is not recommended.
If applied to regression residuals, the command should instead be used as a postestimation command without explicitly specifying {it:varname}. Otherwise, the test results will be invalid.


{marker remarks}{...}
{title:Remarks}

{pstd}
Remarks are presented under the following headings:

{phang2}{help xtdpdserial##remarks_pm:Portmanteau test}{p_end}
{phang2}{help xtdpdserial##remarks_dimensionality:Dimensionality reduction}{p_end}
{phang2}{help xtdpdserial##remarks_d:Tests based on first differences}{p_end}
{phang2}{help xtdpdserial##remarks_sd:Tests based on seasonal differences}{p_end}


{marker remarks_pm}{...}
{title:Portmanteau test}

{pstd}
Using Stata's {help tsvarlist:time-series operators}, the portmanteau test proposed by Jochmans (2020) evaluates the T(T-1)/2-1 covariance restrictions

{pmore2}
Cov ({cmd:L}{it:#}{cmd:.}{it:ue}, {cmd:D.}{it:e}) = 0 for {it:#} = 2, 3, ... and {it:#} = -1

{pstd}
under the null hypothesis of no serial correlation in the idiosyncratic error component {it:e} of a linear model with error component structure {it:ue} = {it:u} + {it:e}, where {it:u} is the time-invariant group-specific error component.
Covariance restrictions with positive lag orders {it:#} = 2, 3, ... are referred to as backward looking, while the covariance restrictions with the negative lag order {it:#} = -1 are referred to as forward looking.

{pstd}
The portmanteau test requires at least 3 consecutive observations over time. It can be more powerful than traditional tests based on first differences, especially when T (the maximum number of observations per group) is very small.
However, because the number of covariance restrictions increases quadratically with T, it can quickly lose power even for moderately small T, especially when N (the number of groups) is only moderately large.


{marker remarks_dimensionality}{...}
{title:Dimensionality reduction}

{pstd}
To avoid power problems, several strategies can be employed to limit the degrees of freedom of the test, as proposed by Kripfganz, Demetrescu, and Hosseinkouchack (2024).
Collapsing, implemented with option {opt collapse}, linearly combines the covariance restrictions into fewer ones by averaging them across time periods.
Full collapsing with option {opt fullcollapse} goes one step further by also averaging across lag orders {it:#}, creating a test with only 1 degree of freedom.

{pstd}
Another strategy is curtailing the maximum order of serial correlation that is detectable by the test. This is done with option {opt order(#)} or, equivalently, option {cmd:lagrange(2 }{it:#}{cmd:)}.
This restricts the maximum lag order in the covariance restrictions. Collapsing and curtailing can be combined.


{marker remarks_d}{...}
{title:Tests based on first differences}

{pstd}
Tests based on {help tsvarlist:first differences}

{pmore2}
Cov ({cmd:L}{it:#}{cmd:D.}{it:e}, {cmd:D.}{it:e}) = 0 for {it:#} = 2, 3, ...

{pstd}
are immune to power distortions from large variances of the group-specific error component {it:u} because {cmd:D.}{it:ue} = {cmd:D.}{it:e}. However, they have low power against highly autocorrelated alternatives close to a random walk.
These tests require T >= 4.

{pstd}
The Arellano and Bond (1991) tests are collapsed versions (with 1 degree of freedom) of these first-difference tests with a single choice of the lag order {it:#}.
They can be obtained by combining the Syntax 1 options {opt difference} {opt collapse} {cmd:lagrange(}{it:#} {it:#}{cmd:)}.
The Yamagata (2008) test is a joint test for all possible lag orders, obtained by jointly specifying {opt difference} {opt collapse} without a restriction of the lag range.

{pstd}
Note that a maximum serial correlation of order {it:#} in the idiosyncratic error component {it:e} in levels corresponds to a maximum serial correlation of order {it:#}-1 in the first-differenced errors {cmd:D.}{it:e}.
It is for this reason that option {opt order(#)} corresponds to {cmd:lagrange(2 }{it:#-1}{cmd:)} when specified with option {opt difference}.


{marker remarks_sd}{...}
{title:Tests based on seasonal differences}

{pstd}
Tests based on {help tsvarlist:seasonal differences} (also referred to as sandwich differences)

{pmore2}
Cov ({cmd:FS}({it:#}+1){cmd:.}{it:e}, {cmd:D.}{it:e}) = 0 for {it:#} = 2, 3, ...

{pstd}
are also unaffected by high variances of {it:u} because {cmd:S.}{it:ue} = {cmd:S.}{it:e}. They retain power even under a random-walk alternative, and they have been shown to often be more powerful than the portmanteau test,
partly due to their more conservative use of degrees of freedom. These tests have been proposed by Kripfganz, Demetrescu, and Hosseinkouchack (2024). They can be implemented with Syntax 1 option {opt sdifference}.
Option {opt collapse} is generally recommended as well. These tests also require T >= 4.


{marker example}{...}
{title:Example}

{pstd}Setup{p_end}
{phang2}. {stata webuse abdata}{p_end}

{pstd}Fixed-effects estimator{p_end}
{phang2}. {stata xtreg n w k, fe vce(r)}{p_end}

{pstd}Jochmans portmanteau test for no autocorrelation{p_end}
{phang2}. {stata xtdpdserial, pm}{p_end}

{pstd}Arellano-Bond tests for no autocorrelation in first differences of order 2, 3, or 4{p_end}
{phang2}. {stata xtdpdserial, d c l(2)}{p_end}
{phang2}. {stata xtdpdserial, d c l(3)}{p_end}
{phang2}. {stata xtdpdserial, d c l(4)}{p_end}

{pstd}Yamagata test for no autocorrelation in first differences of arbitrary order{p_end}
{phang2}. {stata xtdpdserial, d c}{p_end}

{pstd}Kripfganz-Demetrescu-Hosseinkouchack tests for no autocorrelation{p_end}
{phang2}. {stata xtdpdserial, sd c o(2)}{p_end}
{phang2}. {stata xtdpdserial, sd c}{p_end}

{pstd}All of the previous tests together{p_end}
{phang2}. {stata xtdpdserial, s(pm dc(2 2) dc(3 3) dc(4 4) dc sdc(2) sdc)}{p_end}


{marker results}{...}
{title:Saved results}

{pstd}
{cmd:xtdpdserial} with Syntax 1 saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(chi2)}}value of the test statistic{p_end}
{synopt:{cmd:r(df)}}degrees of freedom{p_end}
{synopt:{cmd:r(p)}}p-value{p_end}
{p2colreset}{...}

{pstd}
{cmd:xtdpdserial} with Syntax 2 saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(chi2_}{it:#}{cmd:)}}value of the {it:#}-th test statistic{p_end}
{synopt:{cmd:r(df_}{it:#}{cmd:)}}degrees of freedom of the {it:#}-th test{p_end}
{synopt:{cmd:r(p_}{it:#}{cmd:)}}p-value of the {it:#}-th test{p_end}
{p2colreset}{...}


{marker update}{...}
{title:Version history and updates}

{pstd}{cmd:xtdpdserial} is a community-contributed program. To determine the currently installed version, type{p_end}
{phang2}. {stata which xtdpdserial, all}{p_end}

{pstd}To update the {cmd:xtdpdserial} package to the latest version, type{p_end}
{phang2}. {stata `"net install xtdpdserial, from("http://www.kripfganz.de/stata/") replace"'}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Sebastian Kripfganz, University of Exeter, {browse "http://www.kripfganz.de"}


{marker references}{...}
{title:References}

{phang}
Arellano, M., and S. R. Bond. 1991.
Some tests of specification for panel data: Monte Carlo evidence and an application to employment equations.
{it:Review of Economic Studies} 58: 277-297.

{phang}
Jochmans, K. 2020.
Testing for correlation in error-component models.
{it:Journal of Applied Econometrics} 35: 860-878.

{phang}
Kripfganz, S., M. Demetrescu, and M. Hosseinkouchack. 2024.
Serial correlation testing in error component models with moderately small T.
{it:Manuscript}.

{phang}
Yamagata, T. 2008.
A joint serial correlation test for linear panel data models.
{it:Journal of Econometrics} 146: 135-145.
