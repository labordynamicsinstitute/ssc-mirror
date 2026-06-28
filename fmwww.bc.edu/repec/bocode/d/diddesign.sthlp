{smcl}
{* *! version 1.0.0  16jan2026}{...}
{vieweralsosee "diddesign" "help diddesign"}{...}
{vieweralsosee "diddesign_check" "help diddesign_check"}{...}
{vieweralsosee "diddesign_plot" "help diddesign_plot"}{...}
{vieweralsosee "diddesign_intro" "help diddesign_intro"}{...}
{viewerjumpto "Syntax" "diddesign##syntax"}{...}
{viewerjumpto "Description" "diddesign##description"}{...}
{viewerjumpto "Options" "diddesign##options"}{...}
{viewerjumpto "Stored results" "diddesign##results"}{...}
{viewerjumpto "Methods and formulas" "diddesign##methods"}{...}
{viewerjumpto "References" "diddesign##references"}{...}

{title:Title}

{phang}
{bf:diddesign} {hline 2} Double Difference-in-Differences Estimation

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:diddesign}
{depvar}
[{it:covariates}]
{ifin}
{cmd:,}
{opth treatment(varname)}
{opth time(varname)}
[{it:options}]

{pstd}
where {it:covariates} specifies optional control variables.
Alternatively, use the {opt covariates()} option.

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth treatment(varname)}}treatment indicator variable{p_end}
{synopt:{opth time(varname)}}time variable{p_end}

{syntab:Model}
{synopt:{opth covariates(string)}}optional control variables; supports factor variables{p_end}

{syntab:Design}
{synopt:{opt design(did|sa)}}estimation design; default is {cmd:did}{p_end}
{synopt:{opt panel}}panel data format (default){p_end}
{synopt:{opt rcs}}repeated cross-section data format; optional when {opt post()} already implies RCS{p_end}

{syntab:Panel Options}
{synopt:{opth id(varname)}}unit identifier variable (required for panel){p_end}

{syntab:RCS Options}
{synopt:{opth post(varname)}}post-treatment indicator (required for RCS; also triggers RCS auto-detection){p_end}

{syntab:Inference}
{synopt:{opth cluster(varname)}}cluster variable for standard errors; required for RCS data{p_end}
{synopt:{opt nboot(#)}}number of bootstrap replications ({cmd:# >= 2}); default is {cmd:30}{p_end}
{synopt:{opt seboot}}use bootstrap percentile confidence intervals{p_end}
{synopt:{opt seed(#)}}random number seed for reproducibility{p_end}

{syntab:Dynamic Effects}
{synopt:{opt lead(numlist)}}lead periods for dynamic effects; default is {cmd:0}{p_end}

{syntab:Staggered Adoption}
{synopt:{opt thres(#)}}minimum treated units threshold for {cmd:design(sa)}; default is {cmd:2}{p_end}

{syntab:Generalized K-DID}
{synopt:{opt kmax(#)}}maximum number of moment conditions (K-DID components); default is {cmd:2}{p_end}
{synopt:{opt jtest(on|off)}}enable/disable J-test moment selection; default is {cmd:off}{p_end}

{syntab:Reporting}
{synopt:{opt level(#)}}confidence level; default is {cmd:95}{p_end}
{synopt:{opt quiet}}suppress bootstrap progress display{p_end}
{synopt:{opt parallel}}enable parallel bootstrap (requires SSC {cmd:parallel} package){p_end}
{synoptline}

{p 4 6 2}
{it:covariates} supports factor-variable notation; see {help fvvarlist}.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:diddesign} implements the Double Difference-in-Differences (Double DID) 
method from Egami and Yamauchi (2023). The method optimally combines the 
standard DID estimator with the sequential DID (s-DID) estimator using GMM 
weights to improve efficiency while maintaining robustness.

{pstd}
For {bf:standard DID designs} ({cmd:design(did)}), the command estimates both 
DID and s-DID, then computes the GMM-optimal weighted combination (Double DID).
When {cmd:kmax()} is set to a value greater than 2 and sufficient pre-treatment
periods are available, the command uses the generalized K-DID estimator from
Appendix E of Egami and Yamauchi (2023), combining up to K moment conditions
via GMM. The k-th component uses the k-th order parallel trends assumption,
which can account for (k-1)-th degree polynomial time-varying confounding.

{pstd}
For {bf:staggered adoption (SA) designs} ({cmd:design(sa)}), the command handles 
multiple treatment timing groups and computes time-weighted averages across 
cohorts.

{pstd}
The Double DID estimator is:

{p 8 8 2}
tau_dDID = w1 * tau_DID + w2 * tau_sDID

{pstd}
where w1 and w2 are GMM-optimal weights that minimize the asymptotic variance,
and tau_sDID denotes the sequential DID (s-DID) estimator.

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth treatment(varname)} specifies the binary treatment indicator variable.
For panel data, the treatment variable indicates whether unit i is treated at 
time t (1 = treated, 0 = control). For RCS data, the treatment variable 
indicates treatment group membership.

{phang}
{opth time(varname)} specifies the time variable (e.g., year). This variable
may be numeric or string. String time labels are encoded automatically to
numeric period indices only when that encoding preserves the observed order
of distinct labels in the estimation sample. If labels such as {cmd:t1},
{cmd:t2}, and {cmd:t10} would be silently reordered lexicographically or by
their numeric suffixes during encoding, {cmd:diddesign} stops with an error
and asks users to recode {cmd:time()} to a numeric or lexically ordered
variable first.

{dlgtab:Model}

{phang}
{it:covariates} specified directly after the dependent variable in the varlist
are optional control variables (e.g., {cmd:diddesign y x1 x2 x3, ...}).
Alternatively, the {opt covariates()} option below can be used to specify 
control variables.

{phang}
{opth covariates(fvvarlist)} specifies additional control variables to include 
in the estimation. This option has no limit on the number of variables and 
can be combined with inline covariates. These variables are included as 
covariates in the difference-in-differences regression to improve precision 
and control for confounding factors.

{pmore}
Factor-variable notation is supported; see {help fvvarlist}. For example,
{cmd:covariates(i.region)} automatically expands a categorical variable
{cmd:region} into dummy variables. If {cmd:region} is stored as a string,
it is encoded automatically before factor expansion. Factor variables are
expanded using {cmd:fvrevar} before estimation, and the number of expanded
variables is displayed.

{pmore}
Examples of factor-variable syntax:

{p 8 12 2}{cmd:i.region} - indicator (dummy) variables for categorical region{p_end}
{p 8 12 2}{cmd:ib3.region} - same as above, but with region=3 as base{p_end}
{p 8 12 2}{cmd:ibn.region} - no base category (include all levels){p_end}
{p 8 12 2}{cmd:c.x1#c.x2} - interaction of continuous variables{p_end}
{p 8 12 2}{cmd:i.region#c.gdp} - interaction of factor and continuous{p_end}

{dlgtab:Design}

{phang}
{opt design(did|sa)} specifies the estimation design. {cmd:did} (default) 
uses the standard DID design with a single treatment time. {cmd:sa} uses 
the staggered adoption design for multiple treatment times across units.
The current {cmd:design(sa)} implementation requires complete and unique
{cmd:id()} x {cmd:time()} cells, that is, a balanced panel with exactly one
observation per unit-period. It also requires at least three distinct time
periods so the SA DID/sDID estimators can use the {cmd:{t-2, t-1, t}} window.

{phang}
{opt panel} indicates that the data is in panel format where the same units 
are observed over time. This is the default when {opt id()} is specified.

{phang}
{opt rcs} indicates that the data is in repeated cross-section format where
different units are observed at each time point. When using RCS data,
the {opt post()} option is required. If {opt post()} is already specified,
explicit {opt rcs} is optional and only makes the data type declaration
more explicit.

{dlgtab:Panel Options}

{phang}
{opth id(varname)} specifies the variable identifying units (individuals, 
firms, states, etc.). This option is required for panel data. String variables 
are automatically encoded to numeric using {cmd:egen group()}.

{dlgtab:RCS Options}

{phang}
{opth post(varname)} specifies the post-treatment period indicator variable
for repeated cross-section data. This variable should equal 1 for post-treatment
periods and 0 for pre-treatment periods. Values within the 1e-6 tolerance band
around 0 or 1 are canonicalized to the exact binary values before validation
and estimation. This option is required when using RCS data and, when supplied
without {opt panel}, it is sufficient to trigger RCS auto-detection even if
explicit {opt rcs} is omitted.

{dlgtab:Inference}

{phang}
{opth cluster(varname)} specifies the variable for cluster-robust bootstrap 
standard errors. If not specified for panel data, clustering is done at the 
unit level (same as {cmd:id()}). For RCS data, {cmd:cluster()} is required and
should identify the treatment-assignment bootstrap block; the command now
rejects RCS runs that omit {cmd:cluster()}. String variables are
automatically encoded to numeric.

{phang}
{opt nboot(#)} specifies the number of bootstrap replications for variance 
estimation. {cmd:#} must be an integer greater than or equal to 2. The default
is 30. For publication-quality results, consider using around 2000
replications to match the empirical applications in Egami and Yamauchi (2023).
If fewer than 10 replications are requested
and all iterations succeed, {cmd:diddesign} reports this as a low-{cmd:nboot()}
warning rather than as a bootstrap-failure warning.

{phang}
{opt seboot} requests that bootstrap percentile confidence intervals be used
instead of asymptotic normal confidence intervals.
This option only affects the standard DID design.

{phang}
{opt seed(#)} sets the random number seed for reproducibility of bootstrap 
results.

{dlgtab:Dynamic Effects}

{phang}
{opt lead(numlist)} specifies the lead periods for dynamic effects.
The default is 0, which estimates the instantaneous treatment effect. The
window shorthand below describes the default lead(0) case. When
{cmd:lead()>0} is requested in the standard DID design, the command instead
uses the lead-specific dynamic extension from Appendix E, anchored at the
last pre-treatment period and targeting the requested post-treatment lead.
Positive values therefore estimate dynamic effects `k' periods after
treatment using the {cmd:{c -(}-1, lead{c )-}} contrast implied by that
Appendix E construction. In the
staggered adoption design, positive values estimate time-average SA-ATT
effects `k' periods after adoption.

{dlgtab:Staggered Adoption}

{phang}
{opt thres(#)} specifies the minimum number of treated units required for a 
time period to be included in the SA analysis. The default is 2. Periods with 
fewer treated units are excluded from the estimation.

{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence 
intervals. The default is 95.

{phang}
{opt quiet} suppresses the bootstrap progress display. This is useful when 
running the command in batch mode or when progress messages are not needed.

{phang}
{opt parallel} enables parallel bootstrap computation using the SSC
{cmd:parallel} package. When specified, bootstrap replications are distributed
across multiple Stata instances for faster computation. Requires
{cmd:ssc install parallel} and Stata/MP or SE. If the {cmd:parallel}
package is not available, computation falls back to sequential bootstrap
with a warning.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:diddesign} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(n_units)}}number of units (panel data only; missing for RCS){p_end}
{synopt:{cmd:e(n_periods)}}number of time periods{p_end}
{synopt:{cmd:e(n_boot)}}number of bootstrap replications{p_end}
{synopt:{cmd:e(n_clusters)}}number of clusters in the posted estimation sample{p_end}
{synopt:{cmd:e(n_lead)}}number of retained lead periods{p_end}
{synopt:{cmd:e(n_lead_requested)}}number of leads requested in {cmd:lead()}{p_end}
{synopt:{cmd:e(n_lead_filtered)}}number of requested leads filtered out before estimation{p_end}
{synopt:{cmd:e(n_lead_identified)}}number of retained leads with at least one posted coefficient in {cmd:e(b)}{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(is_panel)}}1 if panel data, 0 otherwise{p_end}
{synopt:{cmd:e(n_boot_success)}}number of bootstrap iterations with at least one finite DID/sDID component estimate{p_end}
{synopt:{cmd:e(seboot)}}1 if bootstrap CI used, 0 otherwise{p_end}
{synopt:{cmd:e(kmax)}}maximum K-DID components requested{p_end}
{synopt:{cmd:e(jtest_on)}}1 if J-test moment selection enabled, 0 otherwise{p_end}
{synopt:{cmd:e(parallel)}}1 if parallel bootstrap was used, 0 otherwise{p_end}

{p2col 5 20 24 2: Scalars (SA design only)}{p_end}
{synopt:{cmd:e(n_periods_valid)}}number of adoption periods that actually enter SA estimation{p_end}
{synopt:{cmd:e(thres)}}minimum treated units threshold used{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:diddesign}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(design)}}estimation design ({cmd:did} or {cmd:sa}){p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(treatment)}}name of treatment variable{p_end}
{synopt:{cmd:e(covariates)}}names of covariates{p_end}
{synopt:{cmd:e(covars)}}alias of {cmd:e(covariates)} for cross-command compatibility{p_end}
{synopt:{cmd:e(id)}}name of unit identifier variable{p_end}
{synopt:{cmd:e(time)}}name of time variable{p_end}
{synopt:{cmd:e(post)}}name of post-treatment indicator variable (RCS only){p_end}
{synopt:{cmd:e(datatype)}}data type ({cmd:panel} or {cmd:rcs}){p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(sample_ifin)}}stored {cmd:if}/{cmd:in} sample restriction; used to verify cross-command sample compatibility such as {cmd:diddesign_plot, use_check()}{p_end}
{synopt:{cmd:e(ci_method)}}confidence interval method ({cmd:bootstrap} or {cmd:asymptotic}){p_end}
{synopt:{cmd:e(lead)}}lead values that still have at least one coefficient posted in {cmd:e(b)} and {cmd:e(V)}{p_end}
{synopt:{cmd:e(requested_lead)}}lead values originally requested in {cmd:lead()}{p_end}
{synopt:{cmd:e(filtered_lead)}}requested lead values filtered out before estimation{p_end}
{synopt:{cmd:e(identified_lead)}}retained lead values with at least one coefficient posted in {cmd:e(b)} and {cmd:e(V)}{p_end}
{synopt:{cmd:e(unidentified_lead)}}requested lead values with no coefficient posted in {cmd:e(b)} and {cmd:e(V)}{p_end}
{synopt:{cmd:e(time_weight_labels)}}pipe-delimited adoption period labels for {cmd:e(time_weights)} (SA design only){p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector with columns named {cmd:dDID:lead_}{it:k}{cmd:},
{cmd:DID:lead_}{it:k}{cmd:}, {cmd:sDID:lead_}{it:k} for standard DID design;
{cmd:SA_dDID:lead_}{it:k}{cmd:}, {cmd:SA_DID:lead_}{it:k}{cmd:}, 
{cmd:SA_sDID:lead_}{it:k} for SA design{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the posted estimator vector; in mixed-support multi-lead SA runs, it uses jointly observed posted bootstrap draws for postestimation{p_end}
{synopt:{cmd:e(estimates)}}estimation results matrix with columns: lead, estimate, 
std_error, ci_lo, ci_hi, weight; in mixed-support multi-lead SA runs, component DID/sDID {it:std_error} and {it:ci_*} use lead-specific marginal bootstrap draws and may differ from {cmd:diag(e(V))}{p_end}
{synopt:{cmd:e(lead_values)}}posted lead values vector aligned with {cmd:e(b)} and {cmd:e(V)}{p_end}
{synopt:{cmd:e(bootstrap_support)}}per-lead bootstrap support counts with columns {cmd:n_valid_did}, {cmd:n_valid_sdid}, and {cmd:n_joint_valid}; rows align with retained {cmd:lead()} values and {cmd:e(weights)}{p_end}
{synopt:{cmd:e(weights)}}GMM weights matrix with columns: w_did, w_sdid{p_end}
{synopt:{cmd:e(W)}}GMM optimal weight matrix; single lead returns 2 x 2, multiple leads return one row per lead with the flattened 2 x 2 matrix{p_end}
{synopt:{cmd:e(vcov_gmm)}}variance-covariance matrix of moment conditions; single lead returns 2 x 2, multiple leads return one row per lead with the flattened 2 x 2 matrix{p_end}

{p2col 5 20 24 2: Matrices (K-DID with {cmd:kmax()>2} only)}{p_end}
{synopt:{cmd:e(k_summary)}}K summary matrix with columns K_init, K_sel, K_final; one row per lead{p_end}
{synopt:{cmd:e(moment_selected)}}moment selection mask (0/1) per lead and component{p_end}
{synopt:{cmd:e(moment_dropped_jtest)}}moments dropped by J-test (0/1) per lead and component{p_end}
{synopt:{cmd:e(moment_dropped_numerical)}}moments dropped for numerical reasons (0/1) per lead and component{p_end}
{synopt:{cmd:e(jtest_stats)}}J-test statistics with columns J_stat, J_df, J_pval; one row per lead{p_end}

{p2col 5 20 24 2: Matrices (SA design only)}{p_end}
{synopt:{cmd:e(time_weights)}}union-level SA time weights over adoption periods that enter the posted common-support SA targets under the requested {cmd:lead()}; when multiple leads are requested, this is a summary over the union of those common-support periods rather than a per-lead surface{p_end}
{synopt:{cmd:e(time_weight_periods)}}adoption periods corresponding to each row of {cmd:e(time_weights)}{p_end}
{synopt:{cmd:e(time_weights_by_lead)}}lead-specific SA time weights; rows follow {cmd:e(time_weight_periods)}, columns follow requested {cmd:lead()} values, and each lead column re-normalizes only over periods where both SA-DID and SA-sDID are jointly identified for that lead{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the posted estimation sample, that is, the union of retained lead-specific support rows that enter at least one DID/sDID component after listwise deletion{p_end}

{pstd}
Coefficient labels such as {cmd:DID:lead_0} are stored as Stata equation names.
For postestimation commands, use equation syntax rather than the raw colon label:
{cmd:lincom [DID]lead_0}, {cmd:test [DID]lead_0 = 0}, or
{cmd:lincom _b[DID:lead_0]}. The same pattern applies to
{cmd:dDID}, {cmd:sDID}, {cmd:SA_dDID}, {cmd:SA_DID}, and {cmd:SA_sDID}.
In general, a stored label of {cmd:DID:lead_}{it:k} is accessed as
{cmd:[DID]lead_}{it:k}; for example, {cmd:[DID]lead_{it:k}} means
"the {cmd:DID} equation at lead {it:k}".

{marker methods}{...}
{title:Methods and formulas}

{pstd}
The Double DID method optimally combines the standard DID estimator with the 
sequential DID (s-DID) estimator using the generalized method of moments (GMM).
When {cmd:kmax()} > 2, the generalized K-DID extension from Appendix E is used,
combining K component estimators. Each k-th component uses a k-th order
difference operator that accounts for (k-1)-th degree polynomial confounding.

{pstd}
{bf:Identification assumptions:}

{p 8 8 2}
The standard DID estimator (tau_DID) requires the {it:parallel trends assumption}: 
the outcome trend of the control group would have been the same as the trend 
of the treatment group in the absence of treatment.

{p 8 8 2}
The sequential DID estimator (tau_sDID) requires only the weaker 
{it:parallel trends-in-trends assumption}: the change in outcome trends is the 
same across treatment and control groups.

{pstd}
{bf:Estimation:}

{p 8 8 2}
tau_DID uses the last pre-treatment period and the requested post-treatment
lead, that is, the 2x2 contrast on periods {cmd:{c -(}-1, lead{c )-}}.

{p 8 8 2}
tau_sDID applies the same 2x2 regression to the first-differenced outcome,
which is equivalent to subtracting the earlier pre-treatment DID from the
standard DID in the default lead(0) case when two pre-treatment periods are
available.

{pstd}
When {cmd:lead()>0} is requested, the command instead uses the lead-specific
dynamic extension from Appendix E, anchored at the last pre-treatment period
rather than the adjacent post-treatment difference shown above.

{pstd}
The generalized K-DID with {cmd:kmax()>2} uses the Appendix E difference
operator. If fewer pre-treatment periods are available than requested by
{cmd:kmax()}, the effective K is automatically truncated to the data support.
Numerical fallback drops the highest-order moments if the bootstrap VCOV
is near-singular.

{pstd}
The Double DID estimator combines both estimators via GMM:

{p 8 8 2}
tau_dDID = w1 * tau_DID + w2 * tau_sDID

{pstd}
where w1 + w2 = 1 and the GMM optimal weight matrix W is the inverse of the 
variance-covariance matrix of the two estimators. This yields the smallest 
asymptotic variance among all weighted combinations. See Egami and Yamauchi 
(2023, equations 12-14) for details.

{pstd}
When more than two pre-treatment periods are available and {cmd:kmax()>2},
the K-DID extends the moment set beyond DID and sDID using higher-order
difference operators. The GMM-optimal weight matrix is estimated from
bootstrap covariance of the K component estimators. Optional J-test moment
selection ({cmd:jtest(on)}) uses Hansen's overidentification test to adaptively
drop violated moment conditions from lowest order first.

{pstd}
In the paper's theoretical moment-selection result, when only parallel trends-in-trends is plausible, the Double DID converges to the sequential DID. The current {cmd:diddesign} command still reports the GMM-weighted {bf:Double-DID} row together with {bf:DID} and {bf:sDID}; interpret those reported estimates alongside {helpb diddesign_check} diagnostics rather than expecting the displayed {bf:Double-DID} row to automatically collapse to {bf:sDID}.

{pstd}
For staggered adoption designs, the SA-Double-DID estimator computes 
time-weighted averages across treatment cohorts, with weights proportional to 
the number of newly treated units in each period.

{title:Example Data Files}

{pstd}
The package includes two example datasets that are automatically installed:

{phang2}
{bf:malesky2014.dta} - Vietnam communes data from Malesky et al. (2014)

{phang2}
{bf:paglayan2019.dta} - US states panel data from Paglayan (2019)

{pstd}
After installation, you can load the data from any directory with {helpb sysuse}:

{phang2}
{cmd:. sysuse malesky2014, clear}

{phang2}
{cmd:. sysuse paglayan2019, clear}

{pstd}
To download the optional example do-files into the current directory, run:

{phang2}
{cmd:. net get diddesign}

{pstd}
Then run the complete example analyses:

{phang2}
{cmd:. do example_malesky.do}

{phang2}
{cmd:. do example_paglayan.do}

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
