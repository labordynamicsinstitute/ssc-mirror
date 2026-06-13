{smcl}
{* *! version 1.0.0 09jun2026}{...}
{vieweralsosee "xttestpanel" "help xttestpanel"}{...}
{vieweralsosee "xttestpanel serial" "help xttestpanel_serial"}{...}
{vieweralsosee "xttestpanel csd" "help xttestpanel_csd"}{...}
{vieweralsosee "xttestpanel func" "help xttestpanel_func"}{...}
{vieweralsosee "xttestpanel hausman" "help xttestpanel_hausman"}{...}
{vieweralsosee "xttestpanel vif" "help xttestpanel_vif"}{...}
{title:Title}

{phang}
{bf:xttestpanel het} {hline 2} Heteroskedasticity tests for panel-data models

{title:Syntax}

{p 8 17 2}
{cmd:xttestpanel het} [{depvar} {indepvars}] {ifin}
[{cmd:,} {opt model(string)} {opt z(varlist)} {opt robust} {opt graph}]

{pstd}
Postestimation form (no varlist) reuses the last {helpb xtreg}/{helpb reghdfe};
see {helpb xttestpanel:the overview}.

{title:Description}

{pstd}
{cmd:xttestpanel het} tests the null of {bf:homoskedastic idiosyncratic disturbances}
in a panel regression. It fits the requested model, takes the residuals, and runs a
battery of artificial-regression LM tests of squared residuals on auxiliary
regressors {it:z} (the model regressors by default).

{pstd}
The variants reported depend on {opt model()}:

{p2colset 9 24 26 2}{...}
{p2col :{bf:fe} (default)}within (FE) residuals; reports the Breusch-Pagan and
Koenker statistics plus the {bf:Juhl & Sosa-Escudero (2014)} F form, which is valid
for fixed-effects models with large {it:N}.{p_end}
{p2col :{bf:re}}random-effects residuals; the Breusch-Pagan/Koenker LM corresponds to
the Holly-Gardiol / Baltagi-Jung-Song test of homoskedastic individual effects.{p_end}
{p2col :{bf:tw}}two-way fixed effects (uses {helpb reghdfe} if installed, else an
internal two-way within transform); reports the conditional-moment test of
{bf:Feng, Li, Tong & Luo (2020)}.{p_end}
{p2colreset}{...}

{title:Options}

{phang}{opt model(fe|re|tw)} working model; default {cmd:fe}.{p_end}
{phang}{opt z(varlist)} auxiliary regressors used in the variance equation; default
is the model's own regressors.{p_end}
{phang}{opt robust} emphasises the Koenker (studentized) statistic, which is robust to
non-normal errors. Both BP and Koenker are always printed.{p_end}
{phang}{opt graph} scatter of squared residuals against the first {it:z} with a lowess
fit; an upward/curved fit signals heteroskedasticity.{p_end}

{title:Statistics}

{pstd}
Let {it:e} be the residuals, {it:s2 = mean(e^2)}, and {it:W = (1, z)}.

{p 8 8 2}o Breusch-Pagan: {bf:BP = 0.5 x ESS} from regressing {it:e^2/s2} on {it:W};
~ chi2({it:p}).{p_end}
{p 8 8 2}o Koenker (robust): {bf:K = n x R^2} from regressing {it:e^2} on {it:W};
~ chi2({it:p}). Robust to non-normality.{p_end}
{p 8 8 2}o Juhl-Sosa-Escudero / Feng et al.: F (or CM) form of the same auxiliary
regression on the appropriate (FE or two-way) residuals.{p_end}

{title:Stored results}

{synoptset 18 tabbed}{...}
{synopt:{cmd:r(bp)}}Breusch-Pagan statistic{p_end}
{synopt:{cmd:r(p_bp)}}its p-value{p_end}
{synopt:{cmd:r(koenker)}}Koenker statistic{p_end}
{synopt:{cmd:r(p_koenker)}}its p-value{p_end}
{synopt:{cmd:r(df)}}degrees of freedom{p_end}
{synopt:{cmd:r(model)}}model used{p_end}

{title:Examples}

{phang2}{cmd:. xttestpanel het ln_wage age tenure hours, model(fe) graph}{p_end}
{phang2}{cmd:. xttestpanel het ln_wage age tenure hours, model(tw)}{p_end}
{phang2}{cmd:. xtreg ln_wage age tenure hours, re}{p_end}
{phang2}{cmd:. xttestpanel het}{p_end}

{title:References}

{phang}Juhl, T., and W. Sosa-Escudero. 2014. {it:Journal of Econometrics} 178: 484-494.{p_end}
{phang}Feng, S., G. Li, T. Tong, and S. Luo. 2020. {it:Journal of Applied Statistics} 47: 91-116.{p_end}
{phang}Holly, A., and L. Gardiol. 2000. In {it:Panel Data Econometrics} (Krishnakumar & Ronchetti, eds).{p_end}

{title:Author}
{pstd}Merwan Roudane {hline 1} merwanroudane920@gmail.com {hline 1}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
