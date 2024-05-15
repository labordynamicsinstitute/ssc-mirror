{smcl}
{* 13May2024}{...}
{* 01May2024}{...}
{* 10Apr2024}{...}
{* 29Mar2024}{...}
{* 10Mar2021}{...}
{* 03Mar2021}{...}
{* 04Dec2017}{...}
{* 09Aug2016}{...}
{* 17Jun2016}{...}
{* 17sep2014}{...}
{* 06Aug2014}{...}
{* 24Mar2014}{...}
{* 11Feb2014}{...}
{cmd:help itsa}{right: ({browse "https://doi.org/10.1177/1536867X211025840":SJ21-2: st0389_6})}
{hline}

{title:Title}

{p2colset 5 13 15 2}{...}
{p2col :{hi:itsa} {hline 2}}Interrupted time-series analysis for single and multiple groups {p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{cmd:itsa} {depvar} [{indepvars}] {ifin} {weight}{cmd:,}
{cmdab:trp:eriod(}{it:{help datetime:date}}{cmd:)} 
[{opt sing:le} {opt treat:id(#)}
{cmdab:cont:id(}{it:{help numlist:numlist}}{cmd:)} {opt prais} {opt lag(#)}
{opt fig:ure}[{cmd:(}{it:{help twoway_options:twoway_options}}{cmd:)}]
{opt low:ess} {opt posttr:end} {opt repl:ace} {opt pre:fix(string)}
[{it:model_options}]

{pstd}
{it:indepvars} may contain factor variables; see {helpb fvvarlist}.
{it:depvar} and {it:indepvars} may contain time-series operators; see 
{helpb tsvarlist}. {opt aweight}s are allowed with the {cmd:newey} option; see {helpb weight}. See
{manhelp glm_postestimation R:glm postestimation} and 
{manhelp prais_postestimation TS:prais postestimation} for features available
after estimation.{p_end}

{pstd}
A dataset for a single panel must be declared to be time-series data by using
{cmd:tsset} {it:timevar}. When the dataset contains multiple panels, a
strongly balanced panel dataset using {cmd:tsset} {it:panelvar} {it:timevar}
must be declared. See {helpb tsset}.


{title:Description}

{pstd}
{cmd:itsa} estimates the effect of an intervention when the outcome variable
is ordered as a time series and a number of observations are available in both
preintervention and postintervention periods. The study design is generally
referred to as an interrupted time-series analysis (ITSA) because the
intervention is expected to interrupt the level or trend subsequent to its
introduction (Campbell and Stanley 1966; Glass, Willson, and Gottman 1975;
Shadish, Cook, and Campbell 2002).

{pstd}
{cmd:itsa} is a wrapper program for {helpb glm} by default, and produces
Newey-West standard errors to adjust for an error structure that is assumed 
to be heteroskedastic and possibly autocorrelated up to some user-defined lag.
It can optionally be a wrapper for {helpb prais}, which uses the generalized 
least-squares method to estimate the parameters in a linear regression model 
in which the errors are assumed to follow a first-order autoregressive process.

{pstd}
{cmd:itsa} estimates treatment effects for either a single treatment group
(with preintervention and postintervention observations) or a multiple-group
comparison (that is, the single treatment group is compared with one or more
control groups). Additionally, {cmd:itsa} can estimate treatment effects for
multiple treatment periods. Because itsa is a wrapper for {helpb glm}, all
available model options are allowed. {p_end}



{title:Options}

{phang}
{cmd:trperiod(}{it:date}{cmd:)} specifies the time period when the
intervention begins. The value(s) entered for time period(s) must be in the same
units as the panel time variable specified in {cmd:tsset} {it:timevar}; see
{helpb tsset}. Dates should be specified using the respective
pseudofunction (see {helpb datetime:datetime}), such as {cmd:trperiod(2020)} 
for a four-digit year, {cmd:trperiod(2019m11)} for quarterly data or 
{cmd:trperiod(20jan2021)} for daily data. Multiple periods may be specified, 
separated by a semicolon, as {cmd:trperiod(2019m6; 2019m11)}; {cmd:trperiod()} is
required.

{phang}
{cmd:single} indicates that {cmd:itsa} will be used for a single-group
analysis. Conversely, omitting {cmd:single} indicates that {cmd:itsa} is for
a multiple-group comparison.

{phang}
{cmd:treatid(}{it:#}{cmd:)} specifies the identifier of the single treated
unit under study when the dataset contains multiple panels. The value entered
must be in the same units as the panel variable specified in {cmd:tsset}
{it:panelvar timevar}; see {helpb tsset}.  When the dataset contains data for
only a single panel, {cmd:treatid()} must be omitted.

{phang}
{cmd:contid(}{it:numlist}{cmd:)} specifies a list of identifiers to be used as
control units in the multiple-group analysis. The values entered must be in
the same units as the panel variable specified in {cmd:tsset} {it:panelvar}
{it:timevar}; see {helpb tsset}. If {cmd:contid()} is not specified, all
nontreated units in the data will be used as controls.

{phang}
{cmd:prais} specifies to fit a {helpb prais} model. If {cmd:prais} is
not specified, {cmd:itsa} will use {helpb glm} with Newey-West standard errors, 
as the default model.

{phang}
{cmd:lag(}{it:#}{cmd:)} specifies the maximum lag to be considered in the
autocorrelation structure when a {cmd:glm} model with Newey-West standard errors 
is chosen. If the user specifies {cmd:lag(0)}, the default, the output is the 
same as {cmd:glm,} {cmd:vce(robust)}.  An error message will appear if 
both {cmd:prais} and {cmd:lag()} are specified, because {cmd:prais} implements 
an AR(1) model by design.

{phang}
{cmd:figure}[{cmd:(}{it:{help twoway_options:twoway_options}}{cmd:)}] produces
a line plot of the predicted {it:depvar} variable combined with a scatterplot
of the actual values of {it:depvar} over time. In a multiple-group analysis,
{cmd:figure} plots the average values of all controls used in the analysis
(more specifically, data for specified controls are collapsed and the monthly
observations are averaged). Specifying {cmd:figure} without options uses the
default graph settings. Note: in Stata version 18, the legend appears on
the right side of the graph by default. To ensure that the legend appears at 
the bottom center, type as an option: {cmd:figure(legend(position(6)))}

{phang}
{cmd:lowess} plots a lowess smoothed line of {it:depvar} on {it:timevar}.

{phang}
{cmd:posttrend} produces posttreatment trend estimates using {helpb lincom},
for the specified model. In the case of a single-group ITSA, one estimate is
produced. In the case of a multiple-group ITSA, an estimate is produced for
the treatment group, the control group, and the difference. In the case of
multiple treatment periods, a separate table is produced for each treatment
period.

{phang}
{cmd:replace} replaces variables created by {cmd:itsa} if they already exist. If 
{cmd:prefix()} is specified, only variables created by {cmd:itsa} with the
same prefix will be replaced.

{phang}
{cmd:prefix(}{it:string}{cmd:)} adds a prefix to the names of variables
created by {cmd:itsa}. Short prefixes are recommended.

{phang}
{it:model_options} specify all available options for {helpb prais} when the
{cmd:prais} option is chosen; otherwise, all available options for 
{helpb glm} can be specified.


{title:Remarks} 

{pstd}
Regression (with methods to account for autocorrelation) is the most commonly
used modeling technique in interrupted time-series analyses. When there is
only one group under study (no comparison groups), the regression model
assumes the following form (Simonton 1977a, 1977b; Huitema and McKean 2000;
Linden and Adams 2011):

{pmore}
Y_t = Beta_0 + Beta_1(T) + Beta_2(X_t) + Beta_3(TX_t){space 5}(1)

{pstd}
Here Y_t is the aggregated outcome variable measured at each equally spaced
time point t, T is the time since the start of the study, X_t is a dummy
(indicator) variable representing the intervention (preintervention periods 0,
otherwise 1), and TX_t is an interaction term between X_t and a sequentially 
numbered variable starting in the period immediately following the intervention.

{pstd}
In the case of a single-group study, Beta_0 represents the intercept or
starting level of the outcome variable. Beta_1 is the slope or trajectory of
the outcome variable until the introduction of the intervention. Beta_2
represents the change in the level of the outcome that occurs in the period
immediately following the introduction of the intervention (compared with the
counterfactual). Beta_3 represents the difference between preintervention and
postintervention slopes of the outcome. Thus we look for significant p-values
in Beta_2 to indicate an immediate treatment effect, or in Beta_3 to indicate
a treatment effect over time (Linden and Adams 2011). However, single-group
ITSA models may provide misleading results, so multiple-group ITSA models
should be implemented whenever possible (Linden 2017b and 2017c).

{pstd}
When one or more control groups are available for comparison, the regression
model in (1) is expanded to include four additional terms (Beta_4 to Beta_7)
(Simonton 1977a, 1977b; Linden and Adams 2011):

{pmore} Y_t = Beta_0 + Beta_1(T) + Beta_2(X_t) + Beta_3(TX_t) +
Beta_4(Z) + Beta_5(ZT) + Beta_6(ZX_t) + Beta_7(ZTX_t){space 5}(2)

{pstd}
Here Z is a dummy variable to denote the cohort assignment (treatment or
control), and ZT, ZX_t, and ZTX_t are all interaction terms among previously
described variables. Now the coefficients Beta_0 to Beta_3 represent the
control group, and the coefficients Beta_4 to Beta_7 represent values of the
treatment group. More specifically, Beta_4 represents the difference in the
level (intercept) of the dependent variable between treatment and controls
prior to the intervention, Beta_5 represents the difference in the slope
(trend) of the dependent variable between treatment and controls prior to the
intervention, Beta_6 indicates the difference between treatment and control
groups in the level of the dependent variable immediately following
introduction of the intervention, and Beta_7 represents the difference between
treatment and control groups in the slope (trend) of the dependent variable
after initiation of the intervention compared with preintervention (akin to a
difference-in-differences of slopes).

{pstd}
The two parameters Beta_4 and Beta_5 play a particularly important role in
establishing whether the treatment and control groups are balanced on both the
level and the trajectory of the dependent variable in the preintervention
period. If these data were from a randomized controlled trial, we would
expect similar levels and slopes prior to the intervention. However, in an
observational study where equivalence between groups cannot be ensured, any
observed differences will likely raise concerns about the ability to draw
causal inferences about the relationship between the intervention and the
outcomes (Linden and Adams 2011). See Linden (2017a) for many
additional ITSA postestimation measures.


{title:Examples}

{pstd}
There are three general scenarios in which {cmd:itsa} can be implemented: 1) a
single-group ITSA using data with only the one panel, 2) a single-group ITSA
in data where there are other panels, and 3) a multiple-group ITSA. The
examples below are described accordingly, using data from Abadie, Diamond, and
Hainmueller (2010) and Linden and Adams (2011):

{pstd}
{opt 1) Single-group ITSA in data with only one panel:}{p_end}

{pmore}
Load single panel data and declare the dataset as time series: {p_end}

{pmore2}{bf:{stata "use cigsales_single, clear":. use cigsales_single, clear}}{p_end}
{pmore2}{bf:{stata "tsset year": . tsset year}} {p_end}

{pmore}
We specify a single-group ITSA and 1989 as the first year of the intervention,
plot the results, and produce a table of the posttreatment trend estimates.
We then run {helpb actest} to test for autocorrelation over the past 12
periods. (See Linden and Yarnold [2016] for a comprehensive
discussion.){p_end}

{phang3}{bf:{stata "itsa cigsale, single trperiod(1989) lag(1) figure(legend(position(6))) posttrend": . itsa cigsale, single trperiod(1989) lag(1) figure(legend(position(6))) posttrend}}{p_end}
{phang3}{bf:{stata "actest, lags(12)": . actest, lags(12)}}{p_end}

{pmore}
Same as above but now we use the rescaled outcome ({opt cigsale_scaled}) which lies between 0 and 1, and accordingly, we specify the binomial GLM family with logit link {p_end}

{phang3}{bf:{stata "itsa cigsale_scaled, single trperiod(1989) lag(1) fig posttrend f(binomial) replace": . itsa cigsale_scaled, single trperiod(1989) lag(1) fig posttrend f(binomial) l(logit) replace}} {p_end}
{phang3}{bf:{stata "actest, lags(12)": . actest, lags(12)}}{p_end}

{pmore}
Now we use the rescaled outcome ({opt cigsale_count}) which is a non-negative integer, and accordingly, we specify the poisson GLM family with log link {p_end}

{phang3}{bf:{stata "itsa cigsale_count, single trperiod(1989) lag(1) fig posttrend f(poisson) l(log) replace": . itsa cigsale_scaled, single trperiod(1989) lag(1) fig posttrend f(poisson)l(log) replace}}{p_end}
{phang3}{bf:{stata "actest, lags(12)": . actest, lags(12)}}{p_end}


{pstd}
{opt 2) Single-group ITSA in data with multiple panels:}{p_end}

{pmore}
Load multiple-panel data and declare the dataset as panel: {p_end}

{phang3}{bf:{stata "use cigsales, clear":. use cigsales, clear}}{p_end}
{phang3}{bf:{stata "tsset state year":. tsset state year}}{p_end}

{pmore}
We specify a single-group ITSA with California (state number 3 in the study)
as the treatment group and 1989 as the first year of the intervention, plot
the results with an added lowess smoother, and produce a table of the posttreatment trend estimates. 
We then run {helpb actest} to test for autocorrelation over the past 12
periods.

{phang3}{bf:{stata "itsa cigsale, single treat(3) trperiod(1989) lag(1) figure(legend(position(6))) low posttrend replace": . itsa cigsale, single treatid(3) trperiod(1989) lag(1) figure(legend(position(6))) low posttrend replace}}{p_end}
{phang3}{bf:{stata "actest, lags(12)": . actest, lags(12)}}{p_end}

{pmore}
Same as above, but we specify {cmd:prais} to fit an AR(1) model.  We
specify {cmd:rhotype(tscorr)}, which bases p on the autocorrelation of the
residuals, and add robust standard errors.

{phang3}{bf:{stata "itsa cigsale, single treatid(3) trperiod(1989) fig posttrend replace prais rhotype(tscorr) vce(robust)":. itsa cigsale, single treatid(3) trperiod(1989) fig posttrend replace prais rhotype(tscorr) vce(robust)}}{p_end}

{pmore}
Here we specify two treatment periods, starting in 1982 and 1989 and specify
that {cmd:xlabel()} shows 5-year increments. We also add a lowess smoother to the graph.

{phang3}{bf:{stata "itsa cigsale, single treat(3) trperiod(1982; 1989) lag(1) figure(xlabel(1970(5)2000)) low posttr replace":. itsa cigsale, single treatid(3) trperiod(1982; 1989) lag(1) figure(xlabel(1970(5)2000)) low posttr replace}}{p_end}

{pmore}
Here we limit the range of observations to the period 1975 to 1995.

{phang3}{bf:{stata "itsa cigsale if inrange(year, 1975, 1995), single treatid(3) trperiod(1982; 1989) lag(1) figure posttr replace":. itsa cigsale if inrange(year, 1975, 1995), single treatid(3) trperiod(1982; 1989) lag(1) figure posttr replace}}


{pstd}
{opt 3) Multiple-group ITSA:}{p_end}

{pmore}
We specify a multiple-group ITSA by omitting {cmd:single} and allowing all
other groups in the file to be used as control groups.{p_end}

{phang3}{bf:{stata "itsa cigsale, treatid(3) trperiod(1989) lag(1) figure(legend(position(6))) posttrend replace":. itsa cigsale, treatid(3) trperiod(1989) lag(1) figure(legend(position(6))) posttrend replace}}{p_end}

{pmore}
Here we specify the ITSA model using weights described in Abadie et al. (2010) as {opt aweights} and estimate the weighted model.

{phang3}{bf:{stata "itsa cigsale [aw=weights], treatid(3) trperiod(1989) replace figure(xlabel(1970(5)2000)) posttrend": . itsa cigsale [aw=weights], treatid(3) trperiod(1989) replace figure(xlabel(1970(5)2000)) posttrend}}

{pmore}
Same as above, but we now indicate specific control groups to use in the
analysis that were identified using {helpb itsamatch}.

{phang3}{bf:{stata "itsa cigsale, treatid(3) trperiod(1989) contid(4 8 19) lag(1) replace figure(xlabel(1970(5)2000)) posttrend": . itsa cigsale, treatid(3) trperiod(1989) contid(4 8 19) lag(1) replace figure(xlabel(1970(5)2000)) posttrend}}

{pmore}
Same as above, but now we use the rescaled [0,1] version of the outcome ({opt cigsale_scaled}) with matches identified using {helpb itsamatch}.

{phang3}{bf:{stata "itsa cigsale_scaled, trperiod(1989) treatid(3) contid(23) replace posttrend f(binomial) fig": . itsa cigsale_scaled, trperiod(1989) treatid(3) contid(23) replace posttrend f(binomial) fig}}

{pmore}
Now we use the rescaled count version of the outcome ({opt cigsale_count}) with matches identified using {helpb itsamatch}.

{phang3}{bf:{stata "itsa  cigsale_count, trperiod(1989) treatid(3) contid(4 8 19) replace posttrend f(poisson) fig": . itsa  cigsale_count, trperiod(1989) treatid(3) contid(4 8 19) replace posttrend f(poisson) fig}}



{marker output_table}{...}
{title:Output table}

{pstd}
{cmd:itsa} produces several variables, as defined under {cmd:Remarks} above.
Below is a cross reference to default names for those variables that appear in
the regression output tables (and used when {cmd:posttrend} is specified).
Variables starting with {cmd:_z} are added to the dataset only when a
multiple-group comparison is specified. {cmd:(trperiod)} is a suffix added to
certain variables indicating the start of the intervention period. This is
particularly helpful for differentiating between added variables when multiple
interventions are specified. If the user specifies a {cmd:prefix()}, it will
be applied to all variables generated by {cmd:itsa}.

{synoptset 18}{...}
{synopt:Variable}Description{p_end}
{synoptline}
{synopt:{cmd:_}{it:depvar}}dependent variable{p_end}
{synopt:{cmd:_t}}time since start of study{p_end}
{synopt:{cmd:_x(trperiod)}}dummy variable representing the intervention periods (preintervention periods {cmd:0}, otherwise {cmd:1}){p_end}
{synopt:{cmd:_x_t(trperiod)}}interaction between {cmd:_x} and a sequentially numbered variable starting in the period immediately following the intervention{p_end}
{synopt:{cmd:_z}}dummy variable to denote the cohort assignment (treatment or control){p_end}
{synopt:{cmd:_z_x(trperiod)}}interaction of {cmd:_z} and {cmd:_x}{p_end}
{synopt:{cmd:_z_x_t(trperiod)}}interaction of {cmd:_z}, {cmd:_x}, and {cmd:_t}{p_end}
{synopt:{cmd:_s_}{it:depvar}{cmd:_pred}}predicted value generated after running {cmd:itsa} for a single group {p_end}
{synopt:{cmd:_m_}{it:depvar}{cmd:_pred}}predicted value generated after running {cmd:itsa} for a multiple-group comparison {p_end}
{synoptline}
{p2colreset}{...}


{title:Acknowledgments}

{p 4 4 2}
I owe a tremendous debt of gratitude to Nicholas J. Cox for his never-ending
support and patience with me while originally developing {cmd:itsa}. I would
also like to thank Steven J. Samuels for creating the {cmd:posttrend} option
and help with various other improvements to {cmd:itsa}. Federico Tedeschi 
found an error in the multiple-group or multiple-intervention posttrend
estimation. Nicola Orsini correctly noted that {cmd:_t} should start at 0,
rather than 1. 


{title:References}

{phang}
Abadie, A., A. Diamond, and J. Hainmueller. 2010. 
Synthetic control methods for comparative case studies: Estimating the
effect of California's tobacco control program.
{it:Journal of the American Statistical Association} 
105: 493-505. 

{phang}
Campbell, D. T., and J. C. Stanley. 1966. 
{it:Experimental and Quasi-Experimental Designs for Research.}
Chicago: Rand McNally.

{phang}
Glass, G. V., V. L. Willson, and J. M. Gottman. 1975. 
{it:Design and Analysis of Time-Series Experiments.} 
Boulder, CO: Colorado Associated University Press.

{phang}
Huitema, B. E., and J. W. McKean. 2000.
Design specification issues in time-series intervention models.
{it:Educational and Psychological Measurement}
60: 38-58.

{phang}
Linden, A. 2015.
{browse "http://www.stata-journal.com/article.html?article=st0389":Conducting interrupted time series analysis for single and multiple group comparisons}.
{it:Stata Journal}.
15: 480-500.

{phang}
------. 2017a.
{browse "http://www.stata-journal.com/article.html?article=st0389_3":A comprehensive set of postestimation measures to enrich interrupted time-series analysis}.
{it:Stata Journal}
17: 73-88.

{phang}
------. 2017b.
Challenges to validity in single-group interrupted time series analysis.
{it:Journal of Evaluation in Clinical Practice}.
23: 413-418.

{phang}
------. 2017c.
Persistent threats to validity in single-group interrupted time series analysis with a crossover design.
{it:Journal of Evaluation in Clinical Practice}.
23: 419-425.

{phang}
------. 2018a. 
Combining synthetic controls and interrupted time series analysis to improve causal inference in program evaluation. 
{it:Journal of Evaluation in Clinical Practice} 
24: 447-453.

{phang}
------. 2018b.
A matching framework to improve causal inference in interrupted time series analysis. 
{it:Journal of Evaluation in Clinical Practice} 
24: 408-415.

{phang}
------. 2018c. Using permutation tests to enhance causal inference in interrupted time series analysis. 
{it:Journal of Evaluation in Clinical Practice}
24: 496-501.

{phang}
------. 2022.
{browse "https://journals.sagepub.com/doi/full/10.1177/1536867X221083929":Erratum: A comprehensive set of postestimation measures to enrich interrupted time-series analysis}.
{it:Stata Journal}
22: 231-233. 

{phang} 
Linden, A., and J. L. Adams. 2011. 
Applying a propensity-score based weighting model to interrupted time
series data: Improving causal inference in program evaluation. 
{it:Journal of Evaluation in Clinical Practice} 
17: 1231-1238.

{phang}
Linden, A., and P. R. Yarnold. 2016.
Using machine learning to identify structural breaks in single-group
interrupted time series designs.
{it:Journal of Evaluation in Clinical Practice}
22: 855-859.

{phang}
Shadish, S. R., T. D. Cook, and D. T. Campbell. 2002.
{it:Experimental and Quasi-Experimental Designs for Generalized Causal Inference.} 
Boston: Houghton Mifflin.

{phang} 
Simonton, D. K. 1977a. 
Cross-sectional time-series experiments: Some suggested statistical analyses. 
{it:Psychological Bulletin} 
84: 489-502.

{phang} 
Simonton, D. K. 1977b. Erratum to Simonton. {it:Psychological Bulletin}
84: 1097.


{title:Author}

{pstd}Ariel Linden{p_end}
{pstd}Linden Consulting Group, LLC{p_end}
{pstd}alinden@lindenconsulting.org{p_end}
       
 
{title:Also see}
{p 4 14 2}	
          Article:  {it:Stata Journal}, volume 21, number 2: {browse "https://doi.org/10.1177/1536867X211025840":st0389_6},{break}
					{it:Stata Journal}, volume 17, number 4: {browse "http://www.stata-journal.com/article.html?article=up0057":st0389_5},{break}
                    {it:Stata Journal}, volume 17, number 2: {browse "http://www.stata-journal.com/article.html?article=up0055":st0389_4},{break}
                    {it:Stata Journal}, volume 17, number 1: {browse "http://www.stata-journal.com/article.html?article=st0389_3":st0389_3},{break}
                    {it:Stata Journal}, volume 16, number 3: {browse "http://www.stata-journal.com/article.html?article=up0052":st0389_2},{break}
                    {it:Stata Journal}, volume 16, number 2: {browse "http://www.stata-journal.com/article.html?article=up0051":st0389_1},{break}
                    {it:Stata Journal}, volume 15, number 2: {browse "http://www.stata-journal.com/article.html?article=st0389":st0389}

{p 7 14 2}Help: {helpb glm}, {helpb newey}, {helpb prais}, {helpb actest} (if installed), {helpb itsamatch} (if installed), {helpb itsaperm} (if installed), {helpb xtitsa} (if installed)
 {p_end}
