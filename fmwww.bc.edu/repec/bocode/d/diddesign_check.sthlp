{smcl}
{* *! version 1.1.0  29jan2026}{...}
{vieweralsosee "diddesign" "help diddesign"}{...}
{vieweralsosee "diddesign_check" "help diddesign_check"}{...}
{vieweralsosee "diddesign_plot" "help diddesign_plot"}{...}
{vieweralsosee "diddesign_intro" "help diddesign_intro"}{...}
{viewerjumpto "Syntax" "diddesign_check##syntax"}{...}
{viewerjumpto "Description" "diddesign_check##description"}{...}
{viewerjumpto "Options" "diddesign_check##options"}{...}
{viewerjumpto "Stored results" "diddesign_check##results"}{...}
{viewerjumpto "Methods and formulas" "diddesign_check##methods"}{...}
{viewerjumpto "References" "diddesign_check##references"}{...}

{title:Title}

{phang}
{bf:diddesign_check} {hline 2} Diagnostic Tests for Parallel Trends Assumption

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:diddesign_check}
{depvar}
[{it:covariates}]
{ifin}
{cmd:,}
{opth treatment(varname)}
{opth time(varname)}
{c -(}{opth id(varname)} | {opth post(varname)} [{opt rcs}]{c )-}
[{it:options}]

{pstd}
where {it:covariates} specifies optional control variables.

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth treatment(varname)}}treatment indicator variable{p_end}
{synopt:{opth time(varname)}}time variable{p_end}

{syntab:Data Type (one required)}
{synopt:{opth id(varname)}}unit identifier for panel data{p_end}
{synopt:{opth post(varname)}}post-treatment indicator for RCS data{p_end}

{syntab:Design}
{synopt:{opt design(did|sa)}}design type; default is {cmd:did}{p_end}
{synopt:{opt panel}}panel data format (default if {opt id()} specified){p_end}
{synopt:{opt rcs}}repeated cross-section format; optional when {opt post()} already implies RCS{p_end}

{syntab:Test Options}
{synopt:{opt lag(numlist)}}lag periods for placebo tests; default is {cmd:lag(1)}{p_end}
{synopt:{opt nboot(#)}}number of bootstrap iterations ({cmd:# >= 2}); default is {cmd:nboot(30)}{p_end}
{synopt:{opt thres(#)}}SA design threshold; only valid with {cmd:design(sa)}{p_end}

{syntab:Inference}
{synopt:{opth cluster(varname)}}cluster variable for standard errors; required for RCS data{p_end}
{synopt:{opt seed(#)}}random number seed{p_end}

{syntab:Display}
{synopt:{opt quiet}}suppress bootstrap progress display and quiet-gated placebo diagnostic notes{p_end}
{synopt:{opt parallel}}reserved for future use; currently has no effect{p_end}
{synoptline}

{p 4 6 2}
{it:depvar} is the outcome variable. Control variables can be specified 
directly after {it:depvar} in the varlist. {it:covariates} supports factor-variable 
notation; see {help fvvarlist}. For example, {cmd:diddesign_check y i.region, ...} 
automatically expands categorical variable {cmd:region} into dummy variables.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:diddesign_check} performs diagnostic tests for the parallel trends assumption
in difference-in-differences designs. The command implements placebo tests that
estimate treatment effects in pre-treatment periods where no effect should exist
if parallel trends holds.

{pstd}
The command computes:

{phang2}
1. {bf:Placebo estimates}: DID estimates using pre-treatment periods only
{p_end}

{phang2}
2. {bf:Standardized estimates}: Placebo estimates standardized by the control 
group outcome standard deviation at the baseline period for comparability
{p_end}

{phang2}
3. {bf:Bootstrap standard errors}: Standard errors via block bootstrap
{p_end}

{phang2}
4. {bf:Equivalence confidence intervals (EqCI)}: 95% CIs for equivalence testing
{p_end}

{pstd}
{bf:Interpreting results:}

{pstd}
If the parallel trends assumption holds, placebo estimates should be close to zero.
The equivalence CI provides a way to assess how small the pre-trends are:

{phang2}
- Smaller EqCI bounds provide stronger evidence for parallel trends
{p_end}

{phang2}
- The paper does not impose a universal EqCI cutoff; researchers should use
substantive domain knowledge to judge whether the reported interval is narrow
enough for the application at hand
{p_end}

{pstd}
For {bf:standard DID designs} ({cmd:design(did)}), placebo tests are computed 
directly from pre-treatment periods.

{pstd}
For {bf:staggered adoption designs} ({cmd:design(sa)}), placebo tests account 
for multiple treatment timing groups and compute time-weighted averages.

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth treatment(varname)} specifies the binary treatment indicator variable.
Units with treatment equal to 1 are in the treatment group; units with 
treatment equal to 0 are in the control group.

{phang}
{opth time(varname)} specifies the time period variable. This variable may be
numeric or string. String time labels are automatically encoded to numeric
period indices only when that encoding preserves the observed order of
distinct labels in the estimation sample. If labels such as {cmd:t1},
{cmd:t2}, and {cmd:t10} would be silently reordered lexicographically or by
their numeric suffixes during encoding, {cmd:diddesign_check} stops with an
error and asks users to recode {cmd:time()} to a numeric or lexically
ordered variable first.

{dlgtab:Data Type}

{pstd}
One of {opt id()} or {opt post()} must be specified to indicate the data type:

{phang}
{opth id(varname)} specifies the variable identifying units (individuals, 
firms, states, etc.). Required for {bf:panel data}. When {opt id()} is specified,
the command assumes panel data format unless {opt rcs} is also specified.
String unit identifiers are automatically encoded to numeric using
{cmd:egen group()}.

{phang}
{opth post(varname)} specifies the binary post-treatment indicator variable (0/1).
Required for {bf:repeated cross-section (RCS) data}. In RCS data, different 
individuals are sampled at each time period, so there is no unit tracking.
The {opt treatment()} variable serves as the group indicator (treatment group 
vs control group), while {opt post()} indicates pre- vs post-treatment periods.
Values within the 1e-6 tolerance band around 0 or 1 are canonicalized to the
exact binary values before validation and placebo estimation.
When {opt panel} and {opt rcs} are both omitted, specifying {opt post()}
already makes the command auto-detect the RCS data type; {opt rcs} is optional
and only makes that choice explicit.

{dlgtab:Design}

{phang}
{opt design(did|sa)} specifies the design type. {cmd:did} (default) is for 
standard DID with a single treatment time. {cmd:sa} is for staggered adoption 
designs with multiple treatment times across units.
{bf:Note:} SA design only supports panel data; specifying {opt design(sa)} with 
{opt rcs} will result in an error. The current {cmd:design(sa)} implementation
also requires complete and unique {cmd:id()} x {cmd:time()} cells, that is, a
balanced panel with exactly one observation per unit-period, and at least
three distinct time periods so the SA DID/sDID estimators can use the
{cmd:{t-2, t-1, t}} window.

{phang}
{opt panel} indicates panel data format. This is automatically assumed when 
{opt id()} is specified without {opt rcs}. For SA design, panel is required.

{phang}
{opt rcs} indicates repeated cross-section data format. When specified, 
{opt post()} is required to identify post-treatment periods. When both
{opt panel} and {opt rcs} are omitted, {opt post()} already implies RCS, so
{opt rcs} is optional. The {opt panel} and {opt rcs} options are mutually
exclusive.

{dlgtab:Test Options}

{phang}
{opt lag(numlist)} specifies the lag periods for placebo tests. Default is 
{cmd:lag(1)}, testing parallel trends between periods t-1 and t-2. Multiple 
lags can be specified (e.g., {cmd:lag(1 2 3)}) to test multiple pre-treatment 
periods. Lag values must be non-negative integers less than the maximum available 
pre-treatment periods. Lag values that exceed this limit are automatically 
filtered out and a warning is displayed. {cmd:lag(0)} is allowed but compares 
the treatment period to the immediately preceding period, so it is reported with 
a warning rather than treated as a true placebo test.

{phang}
{opt nboot(#)} specifies the number of bootstrap iterations for standard error 
estimation. {cmd:#} must be an integer greater than or equal to 2. Default is
{cmd:nboot(30)}. For publication-quality placebo inference, consider using
around 2000 bootstrap iterations to match the empirical applications in
Egami and Yamauchi (2023).

{phang}
{opt thres(#)} specifies the minimum number of treated units required per 
period for SA design. Default is {cmd:thres(2)}. This option is only allowed 
with {cmd:design(sa)}; {cmd:design(did)} will reject it.

{dlgtab:Inference}

{phang}
{opth cluster(varname)} specifies the variable for cluster-robust bootstrap.
If not specified for panel data, clustering defaults to the unit level. For
RCS data, {cmd:cluster()} is required and should identify the
treatment-assignment bootstrap block; the command now rejects RCS runs that
omit {cmd:cluster()}.

{phang}
{opt seed(#)} sets the random number seed for reproducibility.

{dlgtab:Display}

{phang}
{opt quiet} suppresses the bootstrap progress display and the
display-stage placebo diagnostic notes emitted by {cmd:diddesign_check}
that explicitly follow the {opt quiet} contract. This is useful when
running the command in batch mode, in loops, or when embedding
{cmd:diddesign_check} in programs. Suppressed warnings include the
interpretive note for {cmd:lag(0)} and warnings about dropped or raw-only
lags. Note that progress display is only shown for SA design
({cmd:design(sa)}); standard DID does not display progress. Input-validation
or preprocessing notices that occur before this diagnostic display stage
may still appear, including duplicate covariates being removed.

{phang}
{opt parallel} is reserved for future use; currently has no effect.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:diddesign_check} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations in the posted diagnostic sample represented by {cmd:e(placebo)} and {cmd:e(sample)}{p_end}
{synopt:{cmd:e(n_lags)}}number of identified lag periods{p_end}
{synopt:{cmd:e(n_boot)}}number of bootstrap iterations{p_end}
{synopt:{cmd:e(n_boot_valid)}}number of valid bootstrap iterations{p_end}
{synopt:{cmd:e(n_clusters)}}number of clusters in the posted union diagnostic sample{p_end}
{synopt:{cmd:e(n_lags_posted)}}number of placebo lag values posted in {cmd:e(b)} and {cmd:e(V)}{p_end}
{synopt:{cmd:e(level)}}confidence level used for placebo confidence intervals (90){p_end}
{synopt:{cmd:e(is_panel)}}1 if panel data, 0 if RCS data{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:diddesign_check}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(design)}}design type ({cmd:did} or {cmd:sa}){p_end}
{synopt:{cmd:e(datatype)}}data type ({cmd:panel} or {cmd:rcs}){p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(treatment)}}name of treatment variable{p_end}
{synopt:{cmd:e(id)}}name of unit identifier variable for panel results; empty for RCS results{p_end}
{synopt:{cmd:e(time)}}name of time variable used to index diagnostic periods{p_end}
{synopt:{cmd:e(post)}}name of post-treatment indicator variable for RCS results; empty for panel results{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(sample_ifin)}}stored {cmd:if}/{cmd:in} sample restriction for the diagnostic object; used to verify compatibility with matching estimation results{p_end}
{synopt:{cmd:e(covariates)}}names of covariate variables using the original model syntax{p_end}
{synopt:{cmd:e(covars)}}alias of {cmd:e(covariates)} for cross-command compatibility{p_end}
{synopt:{cmd:e(identified_lags)}}lag values retained in {cmd:e(placebo)} after support checks (including raw-only rows){p_end}
{synopt:{cmd:e(posted_lags)}}lag values with standardized placebo estimates posted in {cmd:e(b)} and {cmd:e(V)}{p_end}
{synopt:{cmd:e(raw_only_lags)}}lag values retained in {cmd:e(placebo)} with raw placebo results only; standardized columns are missing{p_end}
{synopt:{cmd:e(unidentified_lags)}}requested lag values dropped because placebo inference is not identifiable on either standardized or raw scales{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V} when {cmd:e(n_lags_posted) > 0}; empty when no standardized placebo lag is posted{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}posted standardized placebo coefficient vector when {cmd:e(n_lags_posted) > 0}; when {cmd:e(n_lags_posted)=0}, Stata still retains a 1x1 internal placeholder matrix named {cmd:__no_posted_standardized_lags__} to preserve eclass compatibility, but it is not part of the public inference contract{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of posted standardized placebo estimates when {cmd:e(n_lags_posted) > 0}; when {cmd:e(n_lags_posted)=0}, Stata still retains a 1x1 internal placeholder matrix named {cmd:__no_posted_standardized_lags__} to preserve eclass compatibility, but it is not part of the public inference contract{p_end}
{synopt:{cmd:e(placebo)}}placebo test results matrix with columns:{p_end}
{synopt:}{it:lag}: lag value{p_end}
{synopt:}{it:estimate}: standardized placebo estimate{p_end}
{synopt:}{it:std_error}: bootstrap standard error (standardized){p_end}
{synopt:}{it:estimate_orig}: original (unstandardized) estimate{p_end}
{synopt:}{it:std_error_orig}: bootstrap standard error (original){p_end}
{synopt:}{it:EqCI95_LB}: 95% equivalence CI lower bound{p_end}
{synopt:}{it:EqCI95_UB}: 95% equivalence CI upper bound{p_end}
{synopt:{cmd:e(trends)}}trends data matrix for plotting{p_end}
{synopt:{cmd:e(n_boot_valid_lag)}}lag-specific bootstrap support matrix with columns {cmd:n_boot_valid_std} and {cmd:n_boot_valid_raw}{p_end}
{synopt:{cmd:e(n_clusters_lag)}}lag-specific cluster support matrix with one column {cmd:n_clusters} (standard DID only){p_end}
{synopt:{cmd:e(Gmat)}}treatment timing matrix (SA design only){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the posted diagnostic sample backing {cmd:e(placebo)}; this is the union of retained placebo support rows, not the full raw command sample{p_end}

{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Placebo estimation}

{pstd}
For lag k, the placebo estimate is computed as:

{p 8 8 2}
tau_placebo(k) = DID(t-k, t-k-1)

{pstd}
where DID(t1, t2) is the difference-in-differences estimator comparing periods 
t1 and t2. Under parallel trends, tau_placebo(k) should equal zero.

{pstd}
{bf:Standardization}

{pstd}
The command always computes both standardized and unstandardized placebo 
estimates.

{pstd}
Estimates are standardized by the control group outcome standard deviation 
at the baseline period (pre-treatment control observations):

{p 8 8 2}
tau_std = tau / sd(Y_control_baseline)

{pstd}
where {it:Y_control_baseline} is the outcome for control units (Gi=0) at the 
baseline time period (It=0). This standardization allows comparison across 
different lag periods and outcome variables, providing effect sizes in 
standard deviation units (similar to Cohen's d).

{pstd}
{bf:Equivalence confidence intervals}

{pstd}
The equivalence CI is computed using the TOST (Two One-Sided Tests) method:

{p 8 8 2}
90% CI = estimate +/- 1.645 * SE

{p 8 8 2}
EqCI95 = (-nu, nu) where nu = max(|90% CI upper|, |90% CI lower|)

{pstd}
This interval reports the smallest symmetric equivalence range supported at the
5% significance level. Researchers should decide whether that range is
substantively negligible for their application.

{pstd}
{bf:Bootstrap variance}

{pstd}
Standard errors are computed via block bootstrap at the cluster level:

{p 8 12 2}
1. Resample clusters with replacement
{p_end}
{p 8 12 2}
2. Recompute placebo estimates on bootstrap sample
{p_end}
{p 8 12 2}
3. Repeat n_boot times
{p_end}
{p 8 12 2}
4. SE = sd(bootstrap estimates)
{p_end}

{marker references}{...}
{title:References}

{phang}
Egami, N. and S. Yamauchi. 2023.
Using Multiple Pretreatment Periods to Improve Difference-in-Differences
and Staggered Adoption Designs.
{it:Political Analysis} 31(2): 195-212.
{browse "https://doi.org/10.1017/pan.2022.8"}
{p_end}

{title:Author}

{pstd}
Xuanyu Cai{break}
City University of Macau{break}
xuanyuCAI@outlook.com

{pstd}
Wenli Xu{break}
City University of Macau{break}
wlxu@cityu.edu.mo

{title:Also see}

{psee}
Online: {helpb diddesign}, {helpb diddesign_check}, {helpb diddesign_plot}, {helpb diddesign_intro}
{p_end}
