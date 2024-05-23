{smcl}


{marker xt2treatments-estimates-event-studies-with-two-treatments}{...}
{title:{cmd:xt2treatments} estimates event studies with two treatments}


{marker syntax}{...}
{title:Syntax}

{text}{phang2}{cmd:xt2treatments} varname(numeric) [{it:if}], {bf:treatment}(varname numeric) {bf:control}(varname numeric), [{bf:pre}(#) {bf:post}(#) {bf:baseline}({it:string}) {bf:weighting}(string) {bf:graph}]{p_end}


{pstd}{cmd:xt2treatments} estimates average treatment effects on the treated (ATT) when there are two treatments. The first treatment is the treatment of interest, and the second treatment is the control.{p_end}

{pstd}The package can be installed with{p_end}

{p 8 16 2}net install xt2treatments, from(https://raw.githubusercontent.com/codedthinking/xt2treatments/main/) replace


{marker options}{...}
{title:Options}


{marker options-1}{...}
{dlgtab:Options}

{synoptset tabbed}{...}
{synopthdr:Option}
{synoptline}
{synopt:{bf:treatment}}Dummy variable indicating the treatment of interest.{p_end}
{synopt:{bf:control}}Dummy variable indicating the control treatment.{p_end}
{synopt:{bf:pre}}Number of periods before treatment to include in the estimation (default 1){p_end}
{synopt:{bf:post}}Number of periods after treatment to include in the estimation (default 3){p_end}
{synopt:{bf:baseline}}Either a negative number between {cmd:-pre} and {cmd:-1} or {cmd:average}, or {cmd:atet}. If {cmd:-k}, the baseline is the kth period before the treatment. If {cmd:average}, the baseline is the average of the pre-treatment periods. If {cmd:atet}, the regression table reports the average of the post-treatment periods minus the average of the pre-treatment periods. Default is {cmd:-1}.{p_end}
{synopt:{bf:weighting}}Method to weight different cohorts in the estimation.{p_end}
{synopt:{bf:graph} (optional)}Plot the event study graph with the default settings of {cmd:hetdid_coefplot}.{p_end}
{synoptline}


{marker weighting-methods}{...}
{dlgtab:Weighting methods}

{synoptset tabbed}{...}
{synopthdr:Method}
{synoptline}
{synopt:{bf:equal} (default)}Each cohort is weighted equally.{p_end}
{synopt:{bf:proportional}}Cohorts are weighted linearly by the number of observations, (n0 + n1), where n0 is the number of controls, n1 is the number of treated units.{p_end}
{synopt:{bf:optimal}}Cohorts are weighted by the inverse of the standard error of the treatment effect estimate of the cohort, (n0 * n1) / (n0 + n1).{p_end}
{synoptline}


{marker examples}{...}
{title:Examples}

{p 8 16 2}use "xt2treatments_testdata.dta", clear

{p 8 16 2}xtset i t

{p 8 16 2}xt2treatments y, treatment(treatmentB) control(treatmentA) pre(1) post(3) weighting(equal)

{p 8 16 2}Panel variable: i (strongly balanced)
 Time variable: t, 1 to 10
         Delta: 1 unit

Event study relative to -1               Number of obs = 1,000

------------------------------------------------------------------------------
           y |       ATET   Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
          -1 |          0  (omitted)
           0 |    .464904   .0179099    25.96   0.000     .4298014    .5000067
           1 |   .4581741   .0177579    25.80   0.000     .4233694    .4929789
           2 |   .4108288   .0173002    23.75   0.000     .3769211    .4447366
           3 |   .3221394      .0199    16.19   0.000     .2831362    .3611426
------------------------------------------------------------------------------

{p 8 16 2}xt2treatments y, treatment(treatmentB) control(treatmentA) pre(3) post(3) weighting(optimal) graph

{p 8 16 2}Panel variable: i (strongly balanced)
 Time variable: t, 1 to 10
         Delta: 1 unit

Event study relative to -1               Number of obs = 1,000

------------------------------------------------------------------------------
           y |       ATET   Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
          -3 |   .0188954   .0377553     0.50   0.617    -.0551037    .0928944
          -2 |    -.01291   .0288885    -0.45   0.655    -.0695304    .0437105
          -1 |          0  (omitted)
           0 |   .2940147   .0263712    11.15   0.000     .2423281    .3457014
           1 |   .2639324   .0261562    10.09   0.000     .2126672    .3151977
           2 |    .270967   .0253986    10.67   0.000     .2211866    .3207474
           3 |    .283611    .029183     9.72   0.000     .2264135    .3408086
------------------------------------------------------------------------------




{marker background}{...}
{title:Background}

{pstd}{cmd:xthdidregress} estimates ATT against various control groups. However, it does not allow for two treatments.{p_end}

{pstd}When the control group is another treatment happening at the same time, the ATT is the difference between the treatment and the control.{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}The command returns, as part of {cmd:e()}, the coefficients and standard errors. See {cmd:ereturn list} after running the command. Typical post-estimation commands can be used, such as {cmd:outreg2}, {cmd:estout}, or {cmd:coefplot}.{p_end}


{marker authors}{...}
{title:Authors}

{text}{phang2}Miklós Koren (Central European University, {browse "https://koren.mk"}), {it:maintainer}{p_end}



{marker license-and-citation}{...}
{title:License and Citation}

{pstd}You are free to use this package under the terms of its {browse "https://github.com/codedthinking/xt2treatments/blob/main/LICENSE"}. If you use it, please cite the software package in your work:{p_end}

{text}{phang2}Koren, Miklós. (2024). XT2TREATMENTS - event study with two treatments [Computer software]. Avilable at {browse "https://github.com/codedthinking/xt2treatments"}{p_end}
