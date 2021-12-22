{smcl}
{* *! version November 29, 2021 @ 17:24:25 UK}{...}
{* link to manual entries (really meant for stata to link to its own docs}{...}
{vieweralsosee "[R] regress" "mansection R regress"}{...}
{vieweralsosee "[ME] mixed" "mansection R mixed"}{...}
{vieweralsosee "[D] statsby" "mansection D statsby"}{...}
{viewerjumpto "Syntax" "twostep##syntax"}{...}
{viewerjumpto "Description" "twostep##description"}{...}
{viewerjumpto "Cluster CPR-Plot" "twostep##clustercpr"}{...}
{viewerjumpto "Clustercpr examples" "twostep##clustercprexamples"}{...}
{viewerjumpto "Clustercpr options" "twostep##clustercproptions"}{...}
{viewerjumpto "Cluster level data" "twostep##mk2nd"}{...}
{viewerjumpto "Dot chart" "twostep##dot"}{...}
{viewerjumpto "Dot examples" "twostep##dotexamples"}{...}
{viewerjumpto "Dot options" "twostep##dotoptions"}{...}
{viewerjumpto "EDV examples" "twostep##edvexamples"}{...}
{viewerjumpto "EDV model" "twostep##edv"}{...}
{viewerjumpto "EDV options" "twostep##edvoptions"}{...}
{viewerjumpto "Unit CPR-Plot" "twostep##unitcpr"}{...}
{viewerjumpto "Unitcpr examples" "twostep##unitcprexamples"}{...}
{viewerjumpto "Unitcpr options" "twostep##unitcproptions"}{...}
{viewerjumpto "Unitregby plot" "twostep##unitregby"}{...}
{viewerjumpto "Unitregby examples" "twostep##unitregbyexamples"}{...}
{viewerjumpto "Unitregby options" "twostep##unitregbyoptions"}{...}

{viewerjumpto "Acknowledgements" "twostep##acknowledgements"}{...}
{viewerjumpto "Author" "twostep##author"}{...}
{viewerjumpto "References" "twostep##references"}{...}
{...}
{title:Title}

{phang}
{cmd:twostep} {hline 2} Twostep multilevel analysis
{p_end}

{marker syntax}{...}

{title:Syntax 1}

{pstd}
{cmd:twostep} is both, a prefix command (Syntax 1), and a standalone
command (Syntax 2). The main purpose is the prefix command:
{p_end}

{* put the syntax in what follows. Don't forget to use [ ] around optional items}{...}
{p 8 16 2}
 {cmd:twostep}
 {it:cluster_id}
 [{cmd:,}
 {it:twostep-options}
 ]{cmd::}
 {it:cmd-1}
 {cmd:||}
 {it:cmd-2}
{p_end}

{pstd}
{it:cmd-1} may be an estimation command such as {help regress}, {help logit}, etc., or 
{p_end}

{p 8 16 2}
 {cmd:unitcpr}
 {varlist}1
 {ifin}
 {weight}
 {cmd:||}
 {varlist}2
[ {cmd:using} {help filename} ]
 [, {it:unitcpr-options} ]
{p_end}

{pstd}
{it:cmd-2} may be one of the following special purpose commands 
{p_end}

{p 8 16 2}
 {cmd:clustercpr}
 {varlist}2
 {ifin}
[ {cmd:using} {help filename} ]
 [, {it: clustercpr-options} ]
{p_end}

{p 8 16 2}
 {cmd:dot}
 {varlist}2
 {ifin}
[ {cmd:using} {help filename} ]
 [, {it: dot-options} ]
{p_end}

{p 8 16 2}
 {cmd:edv}
 {varlist}2
 {ifin}
[ {cmd:using} {help filename} ]
 [, {it: edv-options} ]
{p_end}

{p 8 16 2}
 {cmd:mk2nd}
 {varlist}2
 {ifin}
[ {cmd:using} {help filename} ]
 [, {it: mk2nd-options} ]
{p_end}

{p 8 16 2}
 {cmd:unitreby}
 {varlist}2
 {ifin}
[ {cmd:using} {help filename} ]
 [, {it: unitregby-options} ]
{p_end}

{pstd}
or an arbitrary Stata command with the syntax
{p_end}

{p 8 16 2}
 {cmd:cmd}
 {varlist}2
 {ifin}
 [, {it: options} ]
{p_end}

{pstd} The latter usage is being called "fallback mode" in the
following.
{p_end}

{* the new Stata help format of putting detail before generality}{...}
{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:clustercpr-options}
{synopt:{opt method(arg)}}Options allowed for the EDV model {help twostep##edv}{p_end}
{synopt:{opt lowess:opts(options)}}Options allowed for {help twoway lowess}{p_end}
{synopt:{opt reg:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{syntab:dot-options}
{synopt:{opt ci:opts(options)}}Options allowed for {help twoway rcap}{p_end}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{syntab:edv-options}
{synopt:{opt method(arg)}}Method for cluster level estimation{p_end}
{synopt:{it:regress options}}Method allowed for {help regress}{p_end}
{syntab:mk2nd-options}
{synopt:{opt clear}}It's ok to replace data{p_end}
{syntab:twostep-options}
{synopt:{opt stats(namelist)}}Additional Stats for cluster level{p_end}
{syntab:unitcpr-options}
{synopt:{opt all:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt by:opts(options)}}Options allowed for {help by_option:graph, by()}{p_end}
{synopt:{opt lowess:opts(options)}}Options allowed for {help twoway lowess}{p_end}
{synopt:{opt reg:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{syntab:unitregby-options}
{synopt:{opt all:opts(options)}}Options listed in {help line option}{p_end}
{synopt:{opt by:opts(options)}}Options allowed for {help by_option:graph, by()}{p_end}
{synopt:{opt di:screte(varlist)}}Treat cluster level vars as discrete}{p_end}
{synopt:{opt nq:uantiles(#)}}Grouping for cluster level varlist{p_end}
{synopt:{opt reg:opts(options)}}Options listed in {help line option}{p_end}
{synopt:{opt u:nitby(varlist)}}Additional grouping on unit level varlist{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}{it:clusterid} refers to a {it:varlist} identifying 
clusters in the unit level data set. {it:varlist2} refer to
variables on the cluster level, including the variables holding the
statistics estimated on the unit level for each cluster.{p_end}

{p 4 6 2}{cmd:using} {it:filename} refers to a data set holding the
cluster level variables. In this data set, {it:varlist1} must uniquelly
identify the observations. If {cmd:using} is not specified, the
cluster level variables must be in the data set in memory. 

{p 4 6 2}{cmd:weight}s are allowed for {it:cmd1} if the estimation command
being used allows weights. In the case of {cmd:unitcpr}, {cmd:fweight}s,
{cmd:aweight}s and {cmd:pweight}s are allowed; see help {help weight}.
{cmd:weight}s are not allowed for {it:cmd2}.

{marker description}{...}
{title:Description}

{pstd}{cmd:twostep} is a bundle of programs to ease multilevel
analyses with the twostep approach. The twostep approach to mulitlevel
analysis means to separately estimate a parameter of interest in a unit
level data set (e.g. individuals) for all categories of a cluster
level variable (e.g. countries, states, schools, etc.). The twostep approach
is sometimes seen as superior to the more standard one-step approach
(see {help mixed}) if the numbers of observation on the second level
becomes small (see Achen {help twostep##achen05:2005}). Additionally,
two-step mulitlevel analysis may be used for checking the model
assumptions of the one-step approach, or for exploratory data analysis
of multilevel data.{p_end}

{pstd}Most of the methods implemented in {cmd:twostep} are just
wrappers, which can be also produced by standard Stata
commands. However, the idea of {cmd:twostep} is to offer
several related methods with very similar commands. We hope that this helps
researchers to follow the twostep approach more interactively.{p_end}

{pstd}The following examples highlight this consistent design of
{cmd:twostep} using a subset of the forth round of the European
Quality of Life Survey (EQLS). The EQLS is a survey on probability
samples of respondents in all European Union member countries and
hence a typical example of an international comparative data set. A
special feature of the EQLS is that it also contains a number of
cluster level variables in the unit level data set. The following
examples use hdirank, i.e. the rank of a country in the Human
Development Index.{p_end}

{pstd}{cmd:twostep} contains the following methods: {p_end}

{p 4 6 4}o {it:Estimated Dependend Variable Model} (EDV regression) as
described by Lewis and Linzer ({help twostep##lewis05:2005}). In this
model, the estimated regression coefficients for each cluster of the
unit level data set are feed as dependent variable into a linear
regression on the cluster level. The cluster level regression is
weighted by an inverse function of the uncertainty of the model
estimates. For example, {p_end}

{p 6 6 4}. {stata "use eqls_4x, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || edv _b_hhinc hdirank"}{p_end}

{p 6 6 4}estimates an EDV regression of the unit level coefficients
for hhinc (household income) on the cluster level variable hdirank
(the rank of the human development index). See section {help "twostep##edv":EDV model} for variants of the EDV model.

{p 4 6 4}o {it:Horizontally labeled dot charts of coefficients} with
confidence intervals as shown by Bowers and Drake ({help twostep##bowers05:2005}, figure
1). For example, {p_end}

{p 6 6 4}. {stata "use eqls_4x, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || dot _b_hhinc hdirank"}{p_end}

{p 6 6 4}shows a plot of all the estimated unit level coefficients for
hhinc in a dot chart, where the coefficients are sorted by the field
rank of the cluster level variable hdirank. See section
{help "twostep##dot":Dot chart} for variants of this plot.{p_end}

{p 4 6 4}o {it:Component plus residual plots} for all the unit level
models. This plot is a variant of a plot proposed by Bowers and
Drake ({help "twostep##bowers05":2005}, figure 2). For example, {p_end}

{p 6 6 4}. {stata "use eqls_4x, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: unitcpr lsat hhinc i.sex || _b_hhinc hdirank"}{p_end}

{p 6 6 4}shows the component plus residual plots of the coefficient for
hhinc for each cluster (i.e. country). Each of the plots show the regression
line for all observations in comparison to the cluster specific
regression lines and in comparison to a cluster specific
non-parametric regression (LOWESS). The single plots are sorted by the
field rank of the cluster level variable hdirank. See section
{help "twostep##unitcpr":unitcpr} for variants of this plot. Also see
{help cprplot} for a general description of the component plus
residual plot.

{p 4 6 4}o {it:Component plus residual plots} for the EDV regression
models on the cluster level. This plot is a straightforward application
of the standard component plus residual plot for the case of an
estimated dependend variable. For example, {p_end}

{p 6 6 4}. {stata "use eqls_4x, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || clustercpr _b_hhinc hdirank"}{p_end}

{p 6 6 4} shows a component plus residual plot for the EDV model of
the estimated unit level regression coefficients of hhinc on the
cluster level variable hdirank. The plot contains the regression line
and a non-parametric regression line (LOWESS). See section
{help "twostep##clustercpr":clustercpr} for variants of this
plot. Also see {help cprplot} for a general description of the
component plus residual plot.{p_end}

{p 4 6 4}o {it:Plots of grouped predictions of unit level models} as
proposed by Bowers and Drake ({help "twostep##bowers05":2005}, figure
3) -- we call this a "unitregby plot" in the following. For example,
{p_end}

{p 6 6 4}. {stata "use eqls_4x, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || unitregby _b_hhinc hdirank"}{p_end}

{p 6 6 4} uses a unitregby plot to show regression lines based on the
coefficient of hhinc for the unit level regressions of all clusters,
whereby the clusters are grouped into categories derived from the
cluster level variable hdirank.
See section {help "twostep##unitregby":unitregby} for variants of this
plot.{p_end}

{p 4 6 4}o {it:Distributional diagnostic plots} for the estimated
regression coefficients of the unit level regression model. These
plots are particularly useful to inspect the distributional
assumptions for random intercept and/or random coefficient models. For
example, {p_end}

{p 6 6 4}. {stata "use eqls_4x, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry: regress lsat hhinc i.sex || pnorm _b_hhinc"}{p_end}

{p 6 6 4} shows a standardized normal plot for the cluster specific
estimated regression coefficient of hhinc. Instead of {help pnorm}
all commands described in {help diagnostic plots} except {cmd:qqplot}
can be used. 
{p_end}

{p 4 6 4}o {it:Fallback mode:} Besides the methods described,
{cmd:twostep} has a fallback mode that allows the specification of
arbitrary Stata commands to analyze the unit level regression
coefficients (or other model statistics) on the cluster level. For example,
{p_end}

{p 6 6 4}. {stata "use eqls_4x, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry, stats(r2): regress lsat hhinc i.sex || scatter _stat_r2 hdirank"}{p_end}

{p 6 6 4} shows a scatter plot of R2 form the unit level regressions
on the cluster level variable hdirank. The fallback mode, assumes that
the Stata command follows a standard syntax. Moreover, the first
variable of the variable list of the fallback mode command must be an
estimate or a statistic of the unit level models. {p_end}

{p 4 6 4}o {it:Creation of cluster level data set} As a second fallback
mode, {cmd:twostep} can be used to create a cluster level data set
holding regression coefficients of the unit level regressions. This is
useful for two-step multilevel analyses that cannot be
done with any the implemented methods. For example, {p_end}

{p 6 6 4}. {stata "use eqls_4x, clear"}{p_end}
{p 6 6 4}. {stata "twostep cntry, stats(r2): regress lsat hhinc i.sex || mk2nd _all hdirank"}{p_end}

{p 6 6 4} creates a data set holding {it:all} the cluster specific unit
level regression coefficients, their standard errors and the cluster
level variable hdirank. The standalone command {cmd:twostep} can then
be used to estimate an EDV model for each of the coefficents,
including the constant: {p_end}

{p 6 6 4}. {stata "twostep _b_cons hdirank"}{p_end}
{p 6 6 4}. {stata "twostep _b_hhinc hdirank"}{p_end}
{p 6 6 4}. {stata "twostep _b_2_sex hdirank"}{p_end}

{pstd} The following descriptions of the programs are arranged in
alphabetical order. {p_end}

{marker clustercpr}{...}
{title:Cluster level component plus residual plot}

{pstd}{it:Cluster level component plus residual plots} are shown with the cluster
level command {cmd:clustercprt}. The general syntax is : {p_end}

{p 8 16 2}
 {cmd:twostep}
 {varlist}1{cmd::} {it:modcmd} {it:depvar1}
 {varlist}2 [, {help options}1] {cmd:||}
 {cmd:clustercpr}
 {it:depvar1} 
 {varlist}3
[ {cmd:using} {help filename} ]
 [, {help options}2 ]
{p_end}

{pstd}with {it:modcmd} being an arbitrary estimation command (such as
{cmd:regress}, {cmd:logit}, {cmd:areg}, etc.

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:options1}
{synopt:{it:regress options}}Options allowed for {it:modcmd}{p_end}
{syntab:options2}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{opt reg:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt lowess:opts(options)}}Options allowed for {help twoway lowess}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}

{synoptline}
{p2colreset}{...}

{pstd} {it:varlist1} defines the clusters within the unit level
data set, i.e. the variable(s) identifying the cluster to which each
unit belongs. These are typically countries in international
comparative data, or states within countries, or students within
faculties, etc. The model behind the colon is then estimated for each
cluster, and one of the coefficients, or another model statistic are
feed into an EDV model. Finally, a component plus residual plot is
shown for the first independent variable of the EDV model.{p_end}

{pstd}{it:depvar1} and {it:varlist2} define the dependent and
independent variables for the unit level regression model
respectively. The model is estimated for each category of {it:varlist1}.{p_end}

{pstd}{it:depvar2} and {it:varlist3} define both, the EDV model and
the basic design of the component plus residual plot. {it:depvar2}
must refer to the estimated coefficient of one of the independent
variables of the unit level regression. This is done by adding
{cmd:_b_} in front of variable name, or, in case of factor variables,
by adding {cmd:_b_#_} with # referring to the category of the
respective variable. We suggest to use {cmd:twostep ... || mk2nd _all}
for checking the implied coefficient names in case of factor variables
with interactions. {p_end}

{pstd}{it:varlist3} specifies the independent variables of the EDV
model and the first variable of {it:varlist3} defines the variable for
which the component plus residual plot is being shown. The variables
must be constant within each category of {it:varlist1}. Moroever the
variables must exist, either in the unit level data set itself, or in
the data set specified by {help using}. {p_end}

{pstd}{cmd:using} {it:filename} refers to a data set holding the
cluster level variables. In this data set, {it:varlist1} must uniquely
identify the observations. If {cmd:using} is not specified, the
cluster level variables must be in the data set in memory. 

{marker clustercproptions}{...}
{title:clustercpr options}

{phang}{opt scopts(options)} define the look of the symbols for the
cluster level observations. {it:options} can be any of the options
allowed for {cmd:twoway scatter}. Among these options,
{cmd:msymbol()}, {cmd:msize()}, and {cmd:mcolor()} may be particularly
usefull. {p_end}

{phang} {opt regopts(options)} define the look of the regression
line. {it:options} can be any of the options allowed for
{cmd:twoway line}. Among these options, {cmd:lcolor()}, {cmd:lwidth()}, and
{cmd:msize()} may be particularly useful. {p_end}

{phang} {opt lowess(options)} define the look of the lines for the
non-parametric regression line. {it:options} can be any of the options
allowed for {cmd:twoway line}. Among these options, {cmd:lcolor()},
{cmd:lwidth()}, and {cmd:msize()} may be particularly usefull. {p_end}

{phang}{opt twoway options} options allowed for {help graph twoway}.{p_end}

{marker clustercprexamples}{...}
{title:clustercpr examples}

{phang}. {stata "use eqls_4x, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || clustercpr _b_hhinc hdirank"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || clustercpr _b_hhinc hdirank corrupt"}{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || clustercpr _b_hhinc hdirank, regopts(lcolor(none))"}{break}
erases the linear fit from the graph.
{p_end}

{marker mk2nd}{...}
{title:Cluster level data sets}

{pstd}{cmd:mk2nd} creates cluster level data sets holding selected
estimated coefficients, their standard errors and selected cluster
level variables{p_end}

{p 8 16 2}
 {cmd:twostep}
 [ {cmd:, stats(}{it:name}{cmd:)} ]
 {varlist}1{cmd::} {it:modcmd} {it:depvar1}
 {varlist}2 [, {help options}1] {cmd:||}
 {cmd:mk2nd}
 {it:elist} 
 {varlist}3
[ {cmd:using} {help filename} ]
 [ {cmd:, clear} ]
{p_end}

{pstd}with {it:modcmd} being an arbitrary estimation command (such as
{cmd:regress}, {cmd:logit}, {cmd:areg}, etc., and {it:elist}
being a list of names for regression coefficients and model statistics. 

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:twostep-options}
{synopt:{opt stats(namelist)}}Additional Stats for cluster level{p_end}
{syntab:options1}
{synopt:{it:model options}}Options allowed for {it:modcmd}{p_end}
{syntab:mk2nd-options}
{synopt:{cmd:clear}}Okay to replace the data in memory{p_end}

{synoptline}
{p2colreset}{...}

{pstd} {it:varlist1} defines the clusters within the unit level
data set, i.e. the variable(s) identifying the cluster to which each
unit belongs. These are typically countries in international
comparative data, or states within countries, or students within
faculties, etc. 

{pstd}{it:elist} and {it:varlist2} define the dependent and
independent variables for the unit level regression model
respectively. The model is estimated for each category of {it:varlist1}.{p_end}

{pstd}{it:elist} and {it:varlist3} define the coefficients and cluster
level variables to be stored in the data set to be created. {it:elist}
must refer to the estimated coefficient of one of the independent
variables of the unit level regression. The keyword {cmd:_all} can be
used to store all coefficients and standard errors. {p_end}

{pstd}{cmd:using} {it:filename} refers to a data set holding the
cluster level variables. In this data set, {it:varlist1} must uniquely
identify the observations. If {cmd:using} is not specified, the
cluster level variables must be in the data set in memory. 

{marker mk2ndoptions}{...}
{title:mk2nd options}

{phang}{opt stats(namelist)} define the model statistics to be stored
together with the model coefficients. {it:names} can be any scalar
stored behind by the estimation command used for the unit level
regression. For example, to store the R-square of a
linear regression model, use {cmd:stats(r2)}. {p_end}

{phang}{opt clear} specifies that it is okay to replace the data in
 memory, even though the current data have not been
 saved to disk.

{marker mk2ndexamples}{...}
{title:mk2nd examples}

{phang}. {stata "use eqls_4x, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || mk2nd _b_hhinc hdirank"}{break}
creates a cluster level data set holding the unit level's estimated regression
coefficients of hhinc with their standard errors, and numbers of
observations, as well as the cluster level variable
hdirank. {p_end}

{phang}. {stata "use eqls_4x, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || mk2nd _all hdirank"}{break}
as before, but with all the unit level regression
coefficients/standard errors. {p_end}

{phang}. {stata "use eqls_4x, clear"}{p_end}
{phang}. {stata "twostep cntry, stats(r2 r2_a ll): regress lsat hhinc i.sex || mk2nd _all hdirank"}{break}
as before, but including unit selected statistics of the unit level regression models.{p_end}

{marker dot}{...}
{title:Dot chart}

{pstd}{it:Horizontally labeled dot charts} with confidence intervals
of the unit level regression coefficients are shown with the cluster
level command {cmd:dot}. The general syntax is : {p_end}

{p 8 16 2}
 {cmd:twostep}
 [ {cmd:, stats(}{it:names}{cmd:)} ]
 {varlist}1{cmd::} {it:modcmd} {it:depvar1}
 {varlist}2 [, {help options}1] {cmd:||}
 {cmd:dot}
 {it:depvar1} 
 {varlist}3
[ {cmd:using} {help filename} ]
 [, {help options}2 ]
{p_end}

{pstd}with {it:modcmd} being an arbitrary estimation command (such as
{cmd:regress}, {cmd:logit}, {cmd:areg}, etc.

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:twostep}
{synopt:{opt stats(namelist)}}Additional model statistics{p_end}
{syntab:options1}
{synopt:{it:regress options}}Options allowed for {help regress}{p_end}
{syntab:options2}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{opt ci:opts(options)}}Options allowed for {help twoway rcap}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}

{synoptline}
{p2colreset}{...}

{pstd} {it:varlist1} defines the clusters within the unit level
data set, i.e. the variable(s) that identify the cluster to which each
unit belongs. These are typically countries in international
comparative data, or states within countries, or students within
faculties, etc. The model behind the colon is then estimated
for each cluster defined by {it:varlist1} and one of the coefficients,
or another model statistic is then shown as a horizontally labeled dot
chart. Confidence intervals are shown for the estimated coefficients,
only.{p_end}

{pstd}{it:depvar1} and {it:varlist2} define the dependent and
independent variables for the unit level regression model
respectively. The model is estimated for each category of {it:varlist1}
and the results are used for the plot. {p_end}

{pstd}{it:depvar2} and {it:varlist3} control the design of the dot
chart. Thereby, {it:depvar2} can be any variable available in the
cluster level data set. Usually {it:depvar2} will refer to the variable
that holds the estimated coefficient of one of the independent
variables of the unit level regression. Alternatively, {it:depvar2}
may refer to the name of some other model statistic of the unit level
regression model. These other model statics can be requested with the
options {cmd:stats(}{it:name}{cmd:)} (see below).{p_end}

{pstd}In order to create a plot for the estimated regression
coefficients, add {cmd:_b_} in front of name of the selected
independent variable, or, in case of factor variables, by adding
{cmd:_b_#_} whith # refering to the category of the respective
variable. We suggest to use {cmd:twostep ... || mk2nd _all} for
checking the implied coefficient names in case of factor variables
with interactions. {p_end}

{pstd}In order to create a plot for an arbitrary model statistic
{cmd:_stat_} in front of name of the statistic. The statistic must
have been specified in the option
{cmd:stats(}{it:name}{cmd:)}. Theses statistics are shown without confidence
intervals.{p_end}

{pstd}{it:varlist3} specifies the order of the statistics in plot. If
{it:varlist3} is not specified, the plot is ordered by statistic
itself (from the lowest to the largest). If specified, the statistcs
are ordered by the field rank of {it:varlist3}. The variables must
be constant within each category of {it:varlist1}. Moroever the
variables must exist, either in the unit level data set itself, or in
the data set specified by {help using}. {p_end}

{pstd}{cmd:using} {it:filename} refers to a data set holding the
cluster level variables. In this data set, {it:varlist1} must uniquelly
identify the observations. If {cmd:using} is not specified, the
cluster level variables must be in the data set in memory. 

{marker dotoptions}{...}
{title:Dot options}

{phang}{opt stats(namelist)} define the model statistics to be stored
together with the model coefficients. {it:names} can be any scalar
stored behind by the estimation command used for the unit level
regression. For example, to store the R-square of a
linear regression model, use {cmd:stats(r2)}. {p_end}

{phang}{opt scopt(options)} defines the look of the dots. {it:options}
can be any of the options allowed for {cmd:twoway scatter}. Among
these options, {cmd:msymbol()}, {cmd:msize()}, and
{cmd:mcolor()} may be particularly usefull. {p_end}

{phang} {opt ciopt(options)} defines the look of the confidence
intervals (if any). {it:options} can be any of the options allowed for
{cmd:twoway rcap}. Among these options, {cmd:lcolor()},
{cmd:lwidth()}, and {cmd:msize()} may be particularly useful. {p_end}

{phang}{opt twoway options} options allowed for {help graph twoway}.{p_end}

{marker dotexamples}{...}
{title:Dot examples}

{phang}. {stata "use eqls_4x, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || dot _b_hhinc"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || dot _b_hhinc hdirank"}{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || dot _b_hhinc hdirank, scopts(mcolor(red) ms(S)) ciopts(lwidth(0))"}{break}
just to show how {cmd:scopts()} and {cmd:ciopts()} work.

{phang}. {stata "twostep cntry, stats(r2): regress lsat hhinc i.sex || dot _stat_r2"}{break}
to show R-squared instead of coefficients.
{p_end}

{phang}. {stata "twostep cntry, stats(r2): regress lsat hhinc i.sex || dot _stat_r2, title(R{superscript:2} by country) xtitle(R{superscript:2}) ysize(5) "} {break}
an example with twoway options.
{p_end}

{marker edv}
{title:EDV model}

{pstd}The {it:Estimated Dependent Variable} Model (EDV model) is
estimated with the cluster level command {cmd:edv}, or with
{cmd:twostep} used as a standalone command on a data set created with
the cluster level command {cmd:mk2nd}. The general syntax is :
{p_end}

{p 8 16 2}
 {cmd:twostep}
 {varlist}1{cmd::} {cmd:regress} {it:depvar1}
 {varlist}2 [, {help options}1] {cmd:||}
 {cmd:edv}
 {it:depvar1} 
 {varlist}3
[ {cmd:using} {help filename} ]
 [, {help options}2 ]
{p_end}

{pstd}or{p_end}

{p 8 16 2}
 {cmd:twostep}
 {it:depvar} 
 {varlist}
 [, {help options}2 ]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:options1}
{synopt:{it:regress options}}Options allowed for {help regress}{p_end}
{syntab:options2}
{synopt:{opt method(arg)}}One of ols, wls, borjas, fgls1, fgls2{p_end}
{synopt:{it:regress options}}Options allowed for {help regress}{p_end}
{synoptline}
{p2colreset}{...}

{pstd} {it:varlist1} defines the clusters within the unit level
data set, i.e. the variable(s) that identify the cluster to which each
unit belongs. These are typically countries in international
comparative data, or states within countries, or students within
faculties, etc. The regression model behind the colon is then
estimated for each cluster defined by {it:varlist1} and one of the
coefficients of that model is feed as the dependent variable into the
EDV model.{p_end}

{pstd}{it:depvar1} and {it:varlist2} define the dependent and
independent variables for the unit level regression model
respectively; see help {help regress}. The model is estimated for each
category of {it:varlist1} and the results are pushed into the EDV
model. {p_end}

{pstd}{it:depvar2} and {it:varlist3} define the EDV model. Thereby,
{it:depvar2} must refer to the estimated coefficient of one of the
independent variables of the unit level regression. This is done by
adding {cmd:_b_} in front of variable name, or, in case of factor
variables, by adding {cmd:_b_#_} with # referring to the category of
the respective variable. We suggest to use {cmd:twostep ... || mk2nd _all}
for checking the implied coefficient names in case of factor
variables with interactions. {p_end}

{pstd}{it:varlist3} specifies the independent variables of the EDV
model. The variables must be constant within each category of
{it:varlist1}. Moreover the variables must exist, either in the unit
level data set itself, or in the data set specified by {help using}. {p_end}

{pstd}{cmd:using} {it:filename} refers to a data set holding the
cluster level variables. In this data set, {it:varlist1} must uniquely
identify the observations. If {cmd:using} is not specified, the
cluster level variables must be in the data set in memory. 

{pstd}{ul:Technical Note:} Instead of {cmd:regress}, {cmd:twostep}
allows arbitrary estimation commands for {it:cmd1}. Hence, it is
technically possible to run the EDV model on unit level regression
coefficients of {cmd:logit}, {cmd:probit}, {cmd:xtreg} or
whatever. Since the statistical properties of the EDV model has only
been shown for linear regression, {cmd:twostep} issues a warning
message when the unit level command is not {cmd:regress}. 
{p_end}

{marker edvoptions}{...}
{title:Edv Options}

{phang}{opt method(name)} defines the function used to weight the
observations in the EDV model. {cmd:name} can be any of {cmd:borjas},
{cmd:fgls1} (default), {cmd:fgls2}, {cmd:ols}, and {cmd:wls}.{p_end}

{pmore}{cmd:borjas} weights the observations using as proposed by
Borjas and Sueyoshi ({help twostep##borjas94:1994}).{p_end}

{pmore}{cmd:fgls1} weights the observations using the FGLS approach
described by Lewis and Linzer ({help twostep##lewis05:2005}:351-352). This is the default if
{opt method()} is not specified.{p_end}

{pmore}{cmd:fgls2} weights the observations using the FGLS approach
described by Lewis and Linzer ({help twostep##lewis05:2005}:352-354).{p_end}

{pmore}{cmd:ols} does not apply weights to the second level
regression. {p_end}

{pmore}{cmd:wls} weights the observations by the reciprocal value of
the regression coefficient's variance.{p_end}

{phang}{opt regress option} options allowed for {help regress}.{p_end}

{marker edvexamples}{...}
{title:EDV model examples}

{phang}. {stata "use eqls_4x, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || edv _b_hhinc hdirank"}{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc age if sex == 1 || edv _b_hhinc hdirank if !mi(eu15)"}{break}

{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || edv _b_hhinc hdirank, method(ols)"}{break}
to regress _b_hhinc on hdirank without any weights at all

{phang}. {stata "gen lsat2 = lsat > 5 if !mi(lsat)"}{p_end}
{phang}. {stata "twostep cntry: probit lsat2 hhinc i.sex || edv _b_hhinc hdirank, method(borjas)"}{break}
for using twostep with probit.
{p_end}

{marker unitcpr}{...}
{title:Unit level component plus residual plot}

{pstd}{it:Component plus residual plots} for all the unit level
regression models are shown with the unit level command
{cmd:unitcpr}. The general syntax is : {p_end}

{p 8 16 2}
 {cmd:twostep}
 [, {cmd:stats(}{it:name}{cmd:}) ]
 {varlist}1{cmd:: unitcpr} {it:depvar1}
 {varlist}2
 [, {help options}1 ]
 {cmd:||}
 {it:depvar2} 
 {varlist}3
[ {cmd:using} {help filename} ]
 [, {help options}1 ]
{p_end}

{pstd}{ul:Note:} Unlike the other parts of {cmd:towstep}, {cmd:unitcpr} does not have a cluster level command.{p_end}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:options1}
{synopt:{it:regress options}}Options allowed for {help regress}{p_end}
{syntab:options2}
{synopt:{opt all:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt reg:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt lowess:opts(options)}}Options allowed for {help twoway line}{p_end}
{synopt:{opt sc:opts(options)}}Options allowed for {help twoway scatter}{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}

{synoptline}
{p2colreset}{...}

{pstd} {it:varlist1} defines the clusters within the unit level
data set, i.e. the variable(s) identifying the cluster to which each
unit belongs. These are typically countries in international
comparative data, or states within countries, or students within
faculties, etc. 

{pstd}{it:depvar1} and {it:varlist2} define the dependent and
independent variables for unit level linear regression models. The
models are estimated for each cluster defined by {varlist}1. A
component plus residual plot is then shown for each of these
models. {p_end}

{pstd}{it:depvar2} and {it:varlist3} control the design of the
component plus residual plots. {it:depvar2} refers one of the
independent variables of the unit level model, i.e. to
{it:varlist2}. Corresponding to the other twostep-methods, this is
done by putting {cmd:_b_} in front of the name of the selected
independent variable, or, in case of factor variables, by adding
{cmd:_b_#_} with # referring to the category of the respective
variable. We suggest to use {cmd:twostep ... || mk2nd all} for
checking the implied coefficient names in case of factor variables
with interactions. {p_end}

{pstd}{it:varlist3} specifies the order of single component plus
residual plots in the graph. If specified, the plots are ordered by
the field rank of {it:varlist3}. The variables must be constant within
each category of {it:varlist1}. Moreover the variables must exist,
either in the unit level data set itself, or in the data set specified
by {help using}. {it:varlist3} may refer to stats specified in the
option {cmd:stats()}. {p_end}

{pstd}{cmd:using} {it:filename} refers to a data set holding the
cluster level variables. In this data set, {it:varlist1} must uniquelly
identify the observations. If {cmd:using} is not specified, the
cluster level variables must be in the data set in memory. 

{marker unitcpr-options}{...}
{title:unitcpr options}

{phang}{opt stats(namelist)} define the model statistics to be stored
together with the model coefficients. {it:names} can be any scalar
stored behind by {cmd:regress}. For example, to store the R-square,
use {cmd:stats(r2)}. {p_end}

{phang} {opt allopts(options)} defines the look of regression line
for all units . {it:options} can be
any of the options allowed for {cmd:twoway line}. Among these options,
{cmd:lcolor()}, and {cmd:lwidth()} may be particularly
usefull. {p_end}

{phang} {opt regopts(options)} defines the look of cluster specific
regression lines. {it:options} can be any of the options allowed for
{cmd:twoway line}. Among these options, {cmd:lcolor()}, and
{cmd:lwidth()} may be particularly usefull. {p_end}

{phang} {opt lowessopts(options)} defines the look of cluster specific
LOWESS lines. {it:options} can be any of the options allowed for
{cmd:twoway line}. Among these options, {cmd:lcolor()}, and
{cmd:lwidth()} may be particularly usefull. {p_end}

{phang}{opt scopt(options)} defines the look of the dots. {it:options}
can be any of the options allowed for {cmd:twoway scatter}. Among
these options, {cmd:msymbol()}, {cmd:msize()}, and
{cmd:mcolor()} may be particularly usefull. {p_end}

{phang}{opt twoway options} options allowed for {help graph twoway}.{p_end}

{marker unitcprexamples}{...}
{title:unitcpr examples}

{phang}. {stata "use eqls_4x, clear"}{p_end}
{phang}. {stata "twostep cntry: unitcpr lsat hhinc i.sex || _b_hhinc"}{break}
for the most simple case}{p_end}

{phang}. {stata "twostep cntry: unitcpr lsat hhinc i.sex || _b_hhinc hdirank, scopts(ms(i)) allopts(lwidth(0))"}{break}
to show cluster specific regression and LOWESS lines, only.

{phang}. {stata "twostep cntry, stats(r2): unitcpr lsat hhinc i.sex || _b_hhinc _stat_r2"}{break}
to order plots by R-square.
{p_end}

{marker unitregby}{...}
{title:Unitregby plot}

{pstd}The {it:unitregby plot} shows regression lines of all the unit
level regressions for groups of cluster and/or unit level data,
similar to figure 3 in Bowers and Drake ({help twostep##bowers05:2005}). The general syntax is:
{p_end}

{p 8 16 2}
 {cmd:twostep}
 {varlist}1{cmd::} {it:modcmd} {it:depvar1}
 {varlist}2 [, {help options}1] {cmd:||}
 {cmd:clustercpr}
 {it:depvar2} 
 {varlist}3
 [ {cmd:using} {help filename} ]
 [, {help options}2 ]
{p_end}

{pstd}with {it:modcmd} being an arbitrary estimation command (such as
{cmd:regress}, {cmd:logit}, {cmd:areg}, etc. 

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:options1}
{synopt:{it:regress options}}Options allowed for {it:modcmd}{p_end}
{syntab:options2}
{synopt:{opt all:opts(options)}}Options listed in {help line option}{p_end}
{synopt:{opt by:opts(options)}}Options allowed for {help by_option:graph, by()}{p_end}
{synopt:{opt di:screte(varlist)}}Treat cluster level vars as discrete}{p_end}
{synopt:{opt nq:uantiles(#)}}Grouping for cluster level varlist{p_end}
{synopt:{opt reg:opts(options)}}Options listed in {help line option}{p_end}
{synopt:{opt u:nitby(varlist)}}Additional grouping on unit level varlist{p_end}
{synopt:{it:twoway options}}Options allowed for {help graph twoway}{p_end}
{synoptline}
{p2colreset}{...}

{pstd} {it:varlist1} defines the clusters within the unit level
data set, i.e. the variable(s) identifying the cluster to which each
unit belongs. These are typically countries in international
comparative data, or states within countries, or students within
faculties, etc. The model behind the colon is then estimated for each
cluster, and one of the coefficients is feed into the
unitregby plot.{p_end}

{pstd}{it:depvar1} and {it:varlist2} define the dependent and
independent variables for the unit level regression model
respectively. The model is estimated for each category of
{it:varlist1}.{p_end}

{pstd}{it:depvar2} and defines the regression coefficient that defines
the slope of the regression lines shown in the
unitregby plot. {it:depvar2} must refer to the estimated coefficient
of one of the independent variables of the unit level regression. This
is done by adding {cmd:_b_} in front of variable name, or, in case of
factor variables, by adding {cmd:_b_#_} with # referring to the
category of the respective variable. We suggest to use
{cmd:twostep ... || mk2nd _all}
for checking the implied coefficient names in case
of factor variables with interactions. {p_end} 

{pstd}{it:varlist3} is used to specify groups of cluster level
units. {it:varlist3} thereby refer to cluster level variables, i.e.
the variables must be constant within each category of
{it:varlist1}. Moreover the variables must exist, either in the unit
level data set itself, or in the data set specified by {help using}. By
default the variables of {it:varlist3} are dichotomized at the median
to reduce the number of groups, but this can be changed considerably;
see options {cmd:discrete()}, {cmd:nquantiles()}, and {cmd:unitby()}
below.{p_end}

{pstd}{cmd:using} {it:filename} refers to a data set holding the
cluster level variables. In this data set, {it:varlist1} must uniquely
identify the observations. If {cmd:using} is not specified, the
cluster level variables must be in the data set in memory. 

{marker unitregbyoptions}{...}
{title:unitregby options}

{phang}{opt all:opts(options)} define the look of the lines in the
background of the sub-graphs. By default, {it:unitregby} draws a
background graph that shows the regression lines for {it:all} clusters
units. This is meant to ease the comparison of each subgroup with the
other group. However, the background graph can be nuisance in some
situations, and is perhaps also a matter of taste. The background
options allows the user to fine tune the background graph, including a
complete removal. {it:options} can be any of the options listed in 
{help line option}. Specify {cmd:allopts(lcolor(none))} to remove the
background graph. {p_end}

{phang}{opt by:opts(options)} is used to define the overall
arrangement of the unitregby plot. {it:options} can be any of the
options allowed for {help graph by}. Among these options,
{cmd:rows(#)}, {cmd:cols(#)}, and {cmd:compact} may be particularly
useful. We stress that the overall titles, subtitle, notes, and
captions should be specified here.{p_end}

{phang}{opt di:screte(varlist)} turns of the default categorization
off the variables in the varlist. Assuming continuous cluster level
variables to be the standard case, {it:unitregby} dichotimizes all the
cluster level variables by default. This automatic grouping is turned
of for all variables in the varlist. Note that the option allows
arbitrary groupings of the cluster units by feeding custom-made
variables into {it:discrete()}. See option {cmd:nquantiles()} for
other means to change the default categorization of cluster level
variables.

{phang}{opt reg:opts(options)} defines the appearance of the regression
lines. {it:options} can be any of the {help line options}. The line
options {cmd:lcolor()} and {cmd:lwidth()} may be particularly
useful.{p_end}

{phang}{opt nq:uantiles(#)} defines the number of groups created from
each of the cluster level variables of {it:varlist3}. Assuming
continuous cluster level variables to be the standard case,
{it:unitregby} dichotimizes all the cluster level variables by
default. The option {it:nquantiles(#)} can be used to define the
number of groups to be created. Specifically, # is a number that
defines the number of quantiles to be used for the grouping of the
variables. {cmd:nquantiles(4)}, for example, groups cluster level
variables into four groups by using the 1st, 2nd, and 3rd
quartile. See option {cmd:disrete()} for other means to control
the grouping.{p_end}

{phang}{opt u:nitby(varlist)} is used to allow additional groupings
based on unit-level variables. In presence of {it:unitby()}, the
unit-level regression models are estimated separately for each
{it:combination} of the cluster level identifier and the variables
specified. The unitby-variables are then also used for the definition
of the various sub-graphs.{p_end}

{phang}{opt twoway options} options allowed for {help graph twoway}.{p_end}

{marker clustercprexamples}{...}
{title:clustercpr examples}

{phang}. {stata "use eqls_4x, clear"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || unitregby _b_hhinc hdirank"}{p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || unitregby _b_hhinc hdirank corrupt"}{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc i.sex || unitregby _b_hhinc hdirank, allopts(lcolor(none))"}{break}
erases the background graph.{p_end}

{phang}. {stata "twostep cntry: regress lsat hhinc age || unitregby _b_hhinc hdirank, nq(4) unitby(sex) byopts(cols(2)) ysize(8)"} {break}
demonstrates some flexibility.{p_end}

{phang}. {stata "gen oldeu = !mi(eu15)"} {p_end}
{phang}. {stata "twostep cntry: regress lsat hhinc age || unitregby _b_hhinc hdirank oldeu, nq(4) discrete(oldeu) byopts(cols(2)) ysize(8)"} {break}
shows an example for the usage of option discrete.{p_end}

{marker acknowledgments}{...}
{title:Acknowledgements}

{pstd} We wish to thank Kekeli Abbey, Lena Hipp, Armin Sauermann and for beta
testing. Ulrich Kohler wishes to thank the participants of summer's
2017 and winter's 2020/21 multilevel seminar for commenting earlier
versions of {cmd:twostep}.

{marker author}{...}
{title:Authors}

{pstd}
Ulrich Kohler, University of Potsdam{break}
email: {browse "mailto:ukohler@uni-potsdam.de":ukohler@uni-potsdam.de}{break}
web: {browse "https://www.uni-potsdam.de/soziologie-methoden/":https://www.uni-potsdam.de/soziologie-methoden/}
{p_end}

{pstd}
Johannes Giesecke, Humbold University Berlin{break}
email: {browse "johannes.giesecke@hu-berlin.de":johannes.giesecke@hu-berlin.de"}
{break}
web: {browse "https://www.sowi.hu-berlin.de/de/lehrbereiche/empisoz/a-z/giesecke"}
{p_end}

{marker references}{...}
{title:References}

{pstd} {marker achen05}{...} Achen, C., 2005. Two-Step Hierarchical
Estimation: Beyond Regression Analysis. Political Analysis, 13,
447-456.

{pstd} {marker borjas94} Borjas, G.J. and G.T. Sueyoshi, G.T. (1994). A
two-stage estimator for probit models with structural group effects.
Journal of Econometrics, 1994, 64, 165-182

{pstd} {marker bowers05}{...} Bowers, J. and K. Drake, 2005. EDA for
HLM: Visualization when Probabilistic Inference Fails Political
Analysis, 13, 301-326.

{marker lewis05}{...}
{pstd}Lewis, F.B. and D.A. Linzer, 2005. Estimating
Regression Model in Which the Dependent Variable is Based on
Estimates. Political Analysis, 2005, 13, 345-364
{p_end}

