{smcl}
{* *! version 1.0.0  19Aug2026}{...}
{viewerjumpto "Syntax" "plssem2_estat##syntax"}{...}
{viewerjumpto "Description" "plssem2_estat##description"}{...}
{viewerjumpto "Options" "plssem2_estat##options"}{...}
{viewerjumpto "Examples" "plssem2_estat##examples"}{...}
{viewerjumpto "Stored results" "plssem2_estat##results"}{...}
{title:Title}

{p 4 18 2}
{hi:plssem2 postestimation} -- Postestimation tools for {helpb plssem2}

{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:estat loadings} [{cmd:,} {it:{help plssem2_estat##options:options}}]{p_end}
{p 8 12 2}
{cmd:estat weights} [{cmd:,} {it:{help plssem2_estat##options:options}}]{p_end}
{p 8 12 2}
{cmd:estat reliability} [{cmd:,} {it:{help plssem2_estat##options:options}}]{p_end}
{p 8 12 2}
{cmd:estat htmt} [{cmd:,} {it:{help plssem2_estat##options:options}}]{p_end}
{p 8 12 2}
{cmd:estat effects} [{cmd:,} {it:{help plssem2_estat##options:options}}]{p_end}
{p 8 12 2}
{cmd:estat q2} [{cmd:,} {it:{help plssem2_estat##options:options}}]{p_end}
{p 8 12 2}
{cmd:estat vif} [{cmd:,} {it:{help plssem2_estat##options:options}}]{p_end}
{p 8 12 2}
{cmd:estat f2} [{cmd:,} {it:{help plssem2_estat##options:options}}]{p_end}
{p 8 12 2}
{cmd:estat summarize} [{cmd:,} {it:{help plssem2_estat##options:options}}]{p_end}
{p 8 12 2}
{cmd:estat group} [{cmd:,} {it:{help plssem2_estat##options:options}}]{p_end}

{marker description}{...}
{title:Description}

{pstd}
These commands provide postestimation tools for {helpb plssem2}.

{phang}{cmd:estat loadings}
displays the outer loadings of every indicator on its latent variable,
together with the bootstrap standard errors and, when {cmd:boot()} was used
with {cmd:plssem2}, the bootstrap confidence intervals.

{phang}{cmd:estat weights}
displays the outer weights used to build the composite scores, with
bootstrap standard errors and confidence intervals when available.

{phang}{cmd:estat reliability}
displays Cronbach's alpha, the composite reliability (rho_c) and the average
variance extracted (AVE) of every latent variable.  Conventional thresholds:
alpha and rho_c >= 0.7, AVE >= 0.5.

{phang}{cmd:estat htmt}
displays the heterotrait-monotrait ratio of correlations (HTMT) matrix.
Discriminant validity is supported if all HTMT values are below 0.90
(0.85 for conceptually distinct constructs).

{phang}{cmd:estat effects} [{cmd:,} {bf:direct} {bf:indirect} {bf:total}]
displays the direct, indirect and total effects among the latent variables.
By default all three tables are shown; use the options to select subsets.
When {cmd:boot()} was used, bootstrap confidence intervals are displayed and
the indirect effects can be interpreted as {bf:mediation effects}: an
indirect path (e.g., {it:X -> M -> Y}) is significant if its confidence
interval excludes zero.

{phang}{cmd:estat q2}
displays the Stone-Geisser cross-validated Q2 (redundancy and communality)
obtained with the {cmd:blindfold()} option of {cmd:plssem2}, at the latent
variable level and at the indicator level.  Q2 > 0 indicates predictive
relevance.

{phang}{cmd:estat vif}
displays the variance inflation factors of the structural (inner) model
predictors.  VIF < 5 (or 10) indicates no problematic collinearity.  For
formative blocks the outer VIFs are reported in the measurement-model
section of the main output.

{phang}{cmd:estat f2}
displays the Cohen effect sizes f2 of the structural paths
(benchmarks: 0.02 small, 0.15 medium, 0.35 large).

{phang}{cmd:estat summarize}
displays the summary statistics of the indicators.

{phang}{cmd:estat group}
redisplays the multi-group analysis performed with the {cmd:group()} option
of {cmd:plssem2}.

{marker options}{...}
{title:Options}

{phang}{opt level(#)}
sets the confidence level of the displayed bootstrap confidence intervals.
The default is the level used by {cmd:plssem2} (stored in
{cmd:e(level)}).

{phang}{opt direct, indirect, total}
with {cmd:estat effects}, select which effect tables are displayed.
By default all three are displayed.

{marker examples}{...}
{title:Examples}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. use esg_simdata, clear}{p_end}
{phang2}{cmd:. plssem2 (E > e1-e4) (S > s1-s4) (G > g1-g4) (RA > ra1-ra4) (MP > mp1-mp4) (RM > rm1-rm4)} ///{break}
{cmd:  (Innov > in1-in4) (Effic > ef1-ef4) (Green > gr1-gr4), } ///{break}
{cmd: structural(HQD RA MP RM ESG, RA ESG, MP ESG, RM ESG)} ///{break}
{cmd: higher("ESG: E S G, formative; HQD: Innov Effic Green, reflective")} ///{break}
{cmd: boot(999) seed(20260819) bca blindfold(7)}{p_end}

{pstd}Postestimation{p_end}
{phang2}{cmd:. estat loadings, level(95)}{p_end}
{phang2}{cmd:. estat weights}{p_end}
{phang2}{cmd:. estat reliability}{p_end}
{phang2}{cmd:. estat htmt}{p_end}
{phang2}{cmd:. estat effects, indirect total}{p_end}
{phang2}{cmd:. estat q2}{p_end}
{phang2}{cmd:. estat vif}{p_end}
{phang2}{cmd:. estat f2}{p_end}
    {hline}

{marker results}{...}
{title:Stored results}

{pstd}
The {cmd:estat} subcommands display results stored by {cmd:plssem2} in
{cmd:e()}; see {help plssem2##results:Stored results} in
{helpb plssem2:help plssem2}.  They do not modify {cmd:e()}.  (Note: the
subcommands are also available as the ado-files {cmd:estat_loadings.ado},
{cmd:estat_weights.ado}, etc., so that both the {cmd:e(estat_cmd)} mechanism
and the direct {cmd:estat} dispatch work.)

{title:Also see}

{p 4 6 2}
{helpb plssem2:plssem2} -- Partial least squares structural equation
modeling{p_end}
{p 4 6 2}
{helpb plssem2_predict:plssem2 predict} -- predict after plssem2{p_end}
