{smcl}
{* *! version 1.0.0 09jun2026}{...}
{vieweralsosee "xttestpanel" "help xttestpanel"}{...}
{vieweralsosee "xttestpanel het" "help xttestpanel_het"}{...}
{vieweralsosee "xttestpanel serial" "help xttestpanel_serial"}{...}
{vieweralsosee "xttestpanel csd" "help xttestpanel_csd"}{...}
{vieweralsosee "xttestpanel hausman" "help xttestpanel_hausman"}{...}
{vieweralsosee "xttestpanel vif" "help xttestpanel_vif"}{...}
{title:Title}

{phang}
{bf:xttestpanel func} {hline 2} Nonparametric functional-form test (Lin, Li & Sun 2014)

{title:Syntax}

{p 8 17 2}
{cmd:xttestpanel func} [{depvar} {indepvars}] {ifin}
[{cmd:,} {opt reps(#)} {opt bw(#)} {opt graph}]

{pstd}
This is a {bf:fixed-effects} test. The postestimation form refits with FE if the model
in memory is not FE.

{title:Description}

{pstd}
{cmd:xttestpanel func} implements the consistent nonparametric specification test of
{bf:Lin, Li & Sun (2014)} for the {bf:linear functional form} of a fixed-effects panel
regression. The null is that the parametric (linear) form is correct; the alternative
is any smooth nonparametric departure.

{pstd}
The statistic is a kernel-weighted quadratic form in the FE within residuals,

{p 12 12 2}{it:J_n = sum_(i != j) e_i e_j K_h(x_i - x_j) / (n(n-1))},{p_end}

{pstd}
standardized by its estimated variance to a {bf:J_n ~ N(0,1)} limit (upper-tailed:
large positive values reject linearity). Because the asymptotic approximation can be
poor in finite samples, a {bf:wild bootstrap} p-value (Rademacher weights) is also
reported and is the recommended one for inference.

{pstd}
A Gaussian product kernel is used on the standardized regressors with a Silverman-type
bandwidth {it:h = n^(-1/(4+p))}, overridable with {opt bw()}.

{title:Options}

{phang}{opt reps(#)} number of wild-bootstrap replications; default {cmd:199}. Use
299-499 for publication.{p_end}
{phang}{opt bw(#)} kernel bandwidth on the standardized regressor scale; default is the
Silverman rule.{p_end}
{phang}{opt graph} FE residuals against the first regressor with a lowess curve; a
non-flat curve indicates misspecification.{p_end}

{pstd}
{it:Performance note:} the test is O(n^2) in the number of observations and is capped
at n = 5000. For larger panels subsample first.

{title:Stored results}

{synoptset 14 tabbed}{...}
{synopt:{cmd:r(jn)}}standardized Lin-Li-Sun statistic{p_end}
{synopt:{cmd:r(p_asy)}}asymptotic (N(0,1)) p-value{p_end}
{synopt:{cmd:r(p_boot)}}wild-bootstrap p-value (recommended){p_end}
{synopt:{cmd:r(bw)}}bandwidth used{p_end}

{title:Examples}

{phang2}{cmd:. xttestpanel func ln_wage age tenure hours, reps(299)}{p_end}
{phang2}{cmd:. xttestpanel func ln_wage age tenure hours, bw(0.8) graph}{p_end}

{title:References}

{phang}Lin, Z., Q. Li, and Y. Sun. 2014. {it:Journal of Econometrics} 178: 167-179.{p_end}

{title:Author}
{pstd}Merwan Roudane {hline 1} merwanroudane920@gmail.com {hline 1}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
