{smcl}
{* *! version 2.2.1  01Feb2026}{...}
{viewerjumpto "Syntax" "rddid##syntax"}{...}
{viewerjumpto "Description" "rddid##description"}{...}
{viewerjumpto "Options" "rddid##options"}{...}
{viewerjumpto "Examples" "rddid##examples"}{...}
{viewerjumpto "Saved Results" "rddid##saved_results"}{...}
{viewerjumpto "Author" "rddid##author"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:rddid} {hline 2}}Difference-in-Discontinuities Estimation based on rdrobust{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:rddid} {depvar} {it:runvar} {ifin} {cmd:,} {opth group(varname)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opth group(varname)}}Variable indicating treatment (1) vs control (0) group; {bf:required}.{p_end}
{synopt :{opt c(#)}}RD cutoff for the running variable (default 0).{p_end}
{synopt :{opt bw(string)}}Bandwidth selection method: {opt common} (default) or {opt independent}.{p_end}
{synopt :{opt bwselect(string)}}Bandwidth selector: {opt mserd} (default), {opt msetwo}, {opt cerrd}, etc.{p_end}
{synopt :{opt h(numlist)}}Manually specify bandwidths. Accepts 1, 2, or 4 numbers to control symmetric or asymmetric bandwidths per group.{p_end}
{synopt :{opt est(string)}}Estimation type: {opt robust} (default), {opt conventional}, or {opt biascorrected}.{p_end}
{synopt :{opt bootstrap}}Request bootstrapped standard errors (default is analytic).{p_end}
{synopt :{opt reps(int)}}Number of bootstrap replications (default 50).{p_end}
{synopt :{opt seed(int)}}Set random-number seed before bootstrap.{p_end}
{synopt :{it:rdrobust_options}}Any other options (e.g., {opt vce(hc1)}, {opt kernel(...)}) are passed directly to {cmd:rdrobust}.{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:rddid} performs a Difference-in-Discontinuities estimation. It estimates the discontinuity in {depvar} at the cutoff of {it:runvar} for a Treated group and subtracts the discontinuity found in a Control group.

{pstd}
It relies on {cmd:rdrobust} for underlying estimation and bandwidth selection.

{pstd}
Without the {opt bootstrap} option, analytic standard errors are computed assuming independence between groups.
This assumption is appropriate when groups correspond to distinct units (e.g., different countries or boundaries).
When groups share the same units (e.g., panel pre/post), use {opt bootstrap} to obtain valid standard errors.

{marker options}{...}
{title:Options}

{phang}
{opt group(varname)} specifies the binary variable defining the groups. 1 must indicate the Treated/Post group, and 0 must indicate the Control/Pre group.

{phang}
{opt c(#)} specifies the RD cutoff for the running variable. The default is 0.

{phang}
{opt bw(string)} specifies how bandwidths are calculated if {opt h()} is not used. {opt common} calculates the optimal bandwidth for the Treated group and applies it to the Control group. {opt independent} calculates separate optimal bandwidths for each group.

{phang}
{opt bwselect(string)} specifies the bandwidth selector used by {cmd:rdbwselect}. The default is {opt mserd} (MSE-optimal, common). Other options include {opt msetwo} (MSE-optimal, two different), {opt cerrd} (CER-optimal, common), and {opt certwo} (CER-optimal, two different). Only relevant when {opt h()} is not specified.

{phang}
{opt h(numlist)} allows manual specification of bandwidths. If specified, this overrides {opt bw()}. It accepts three formats:{p_end}
{phang2}* {bf:1 number} (e.g., {cmd:h(5)}): Sets a symmetric bandwidth of 5.0 for both Treated and Control groups.{p_end}
{phang2}* {bf:2 numbers} (e.g., {cmd:h(5 10)}): Sets a symmetric bandwidth of 5.0 for the Treated group and 10.0 for the Control group.{p_end}
{phang2}* {bf:4 numbers} (e.g., {cmd:h(1 2 3 4)}): Sets fully asymmetric bandwidths. Treated group uses 1 (Left) and 2 (Right). Control group uses 3 (Left) and 4 (Right).{p_end}

{phang}
{opt est(string)} selects the estimation type. The default is {opt robust}, which uses bias-corrected point estimates with robust standard errors following Calonico, Cattaneo, and Titiunik (2014). {opt conventional} uses conventional point estimates and standard errors. {opt biascorrected} uses bias-corrected point estimates with conventional standard errors. Can be abbreviated as {opt est()}.

{phang}
{opt bootstrap} calculates standard errors using a bootstrap procedure. If this is not specified, the command calculates analytic standard errors assuming independence between the two groups. When combined with {cmd:vce(cluster {it:varname})}, the bootstrap resamples whole clusters rather than individual observations (cluster bootstrap). In the analytic path, {cmd:vce()} is passed directly to {cmd:rdrobust}.

{phang}
{opt reps(int)} specifies the number of bootstrap replications. The default is 50. This option is only relevant when {opt bootstrap} is specified.

{phang}
{opt seed(int)} sets the random-number seed before the bootstrap loop, ensuring reproducible results. This option is only relevant when {opt bootstrap} is specified.

{phang}
{it:rdrobust_options} allow you to customize the underlying estimation. For example, you can pass {cmd:vce(cluster id)} to cluster standard errors within each group's RD estimation, or {cmd:covs({it:varlist})} to include covariates.

{marker examples}{...}
{title:Examples}

{phang}1. Standard estimation (Common bandwidth, analytic SEs){p_end}
{phang}{cmd:. rddid outcome score, group(treated)}{p_end}

{phang}2. Non-zero cutoff{p_end}
{phang}{cmd:. rddid outcome score, group(treated) c(50)}{p_end}

{phang}3. Independent bandwidths for Treated and Control groups{p_end}
{phang}{cmd:. rddid outcome score, group(treated) bw(independent)}{p_end}

{phang}4. Manual asymmetric bandwidths (Treated: 5 Left/10 Right; Control: 5 Left/5 Right){p_end}
{phang}{cmd:. rddid outcome score, group(treated) h(5 10 5 5)}{p_end}

{phang}5. Bootstrapped standard errors (200 reps, reproducible){p_end}
{phang}{cmd:. rddid outcome score, group(treated) bootstrap reps(200) seed(12345)}{p_end}

{phang}6. Bootstrapped standard errors with cluster resampling{p_end}
{phang}{cmd:. rddid outcome score, group(treated) bootstrap reps(200) vce(cluster id)}{p_end}

{phang}7. Conventional estimation (non-bias-corrected){p_end}
{phang}{cmd:. rddid outcome score, group(treated) est(conventional)}{p_end}

{phang}8. CER-optimal bandwidth selector{p_end}
{phang}{cmd:. rddid outcome score, group(treated) bwselect(cerrd)}{p_end}

{marker saved_results}{...}
{title:Saved Results}

{pstd}{cmd:rddid} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt :{cmd:e(N)}}total sample size{p_end}
{synopt :{cmd:e(N_t)}}sample size for Treated group{p_end}
{synopt :{cmd:e(N_c)}}sample size for Control group{p_end}
{synopt :{cmd:e(tau_t)}}RD estimate for Treated group{p_end}
{synopt :{cmd:e(se_t)}}standard error for Treated group (analytic only){p_end}
{synopt :{cmd:e(tau_c)}}RD estimate for Control group{p_end}
{synopt :{cmd:e(se_c)}}standard error for Control group (analytic only){p_end}
{synopt :{cmd:e(h_t_l)}}bandwidth for Treated group (left of cutoff){p_end}
{synopt :{cmd:e(h_t_r)}}bandwidth for Treated group (right of cutoff){p_end}
{synopt :{cmd:e(h_c_l)}}bandwidth for Control group (left of cutoff){p_end}
{synopt :{cmd:e(h_c_r)}}bandwidth for Control group (right of cutoff){p_end}
{synopt :{cmd:e(cutoff)}}RD cutoff value{p_end}
{synopt :{cmd:e(bs_reps)}}number of bootstrap replications requested (bootstrap only){p_end}
{synopt :{cmd:e(bs_good)}}number of successful bootstrap replications (bootstrap only){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt :{cmd:e(cmd)}}{cmd:rddid}{p_end}
{synopt :{cmd:e(bw_type)}}bandwidth selection method ({cmd:common} or {cmd:independent}){p_end}
{synopt :{cmd:e(estimation)}}estimation type ({cmd:robust}, {cmd:conventional}, or {cmd:biascorrected}){p_end}
{synopt :{cmd:e(vce)}}{cmd:bootstrap} or {cmd:analytic}{p_end}
{synopt :{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt :{cmd:e(runvar)}}name of running variable{p_end}
{synopt :{cmd:e(group)}}name of group variable{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt :{cmd:e(b)}}the Difference-in-Discontinuities estimate{p_end}
{synopt :{cmd:e(V)}}variance matrix of the estimate{p_end}
{synopt :{cmd:e(bs_dist)}}vector of bootstrap replicate estimates (bootstrap only){p_end}

{marker also_see}{...}
{title:Also see}

{pstd}{help rddidplot:rddidplot} — postestimation command for side-by-side RD plots{p_end}

{marker author}{...}
{title:Author}
{pstd}Jonathan Dries{p_end}
{pstd}LUISS Guido Carli University{p_end}
{pstd}Email: jvdries@luiss.it{p_end}
