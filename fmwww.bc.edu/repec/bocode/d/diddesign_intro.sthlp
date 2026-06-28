{smcl}
{* *! version 1.1.0  31jan2026}{...}
{vieweralsosee "diddesign" "help diddesign"}{...}
{vieweralsosee "diddesign_check" "help diddesign_check"}{...}
{vieweralsosee "diddesign_plot" "help diddesign_plot"}{...}
{vieweralsosee "diddesign_intro" "help diddesign_intro"}{...}
{viewerjumpto "Introduction" "diddesign_intro##intro"}{...}
{viewerjumpto "Traditional DID" "diddesign_intro##traditional"}{...}
{viewerjumpto "Double DID Method" "diddesign_intro##method"}{...}
{viewerjumpto "Staggered Adoption" "diddesign_intro##sa"}{...}
{viewerjumpto "Parallel trends assessment" "diddesign_intro##assessment"}{...}
{viewerjumpto "Workflow" "diddesign_intro##workflow"}{...}
{viewerjumpto "References" "diddesign_intro##references"}{...}

{title:Title}

{phang}
{bf:diddesign_intro} {hline 2} Introduction to Double Difference-in-Differences

{marker intro}{...}
{title:Introduction}

{pstd}
The {cmd:diddesign} package implements the Double Difference-in-Differences
(Double DID) method proposed by Egami and Yamauchi (2023). This method
addresses the question of how researchers can optimally use multiple
pre-treatment periods to improve the DID design.

{pstd}
Multiple pre-treatment periods provide three key benefits:

{phang2}
1. {bf:Assessing the parallel trends assumption:} Pre-treatment periods enable
placebo tests by applying DID to periods before treatment. The package also
reports equivalence confidence intervals to provide positive evidence for
approximate parallel trends.

{phang2}
2. {bf:Improving estimation accuracy:} Under the extended parallel trends
assumption, combining multiple DID estimators via GMM increases estimation
accuracy. The Double DID estimator achieves variance no larger than the
standard DID, the sequential DID, or the two-way fixed effects estimator.

{phang2}
3. {bf:Allowing for a more flexible parallel trends assumption:} The sequential
DID estimator requires only the parallel trends-in-trends assumption, which
permits linear time-varying unmeasured confounding.

{pstd}
The package provides three commands:

{phang2}
{helpb diddesign} - Main estimation command for Double DID

{phang2}
{helpb diddesign_check} - Parallel trends assessment and diagnostics

{phang2}
{helpb diddesign_plot} - Visualization of results

{marker traditional}{...}
{title:Traditional DID}

{pstd}
The traditional Difference-in-Differences (DID) estimator compares changes
in outcomes between treatment and control groups:

{p 8 8 2}
tau_DID = (Y_bar_T,post - Y_bar_T,pre) - (Y_bar_C,post - Y_bar_C,pre)

{pstd}
where T denotes the treated group and C denotes the control group.

{pstd}
{bf:Assumption 1 (Parallel Trends):} The traditional DID estimator requires
that, absent treatment, the outcome trend of the treated group would have been
the same as the outcome trend of the control group. Formally:

{p 8 8 2}
E[Y(0)_T,post - Y(0)_T,pre] = E[Y(0)_C,post - Y(0)_C,pre]

{pstd}
This assumption is inherently untestable because it involves counterfactual
outcomes. However, pre-treatment periods can be used to assess its plausibility.

{marker method}{...}
{title:Double DID Method}

{pstd}
The Double DID method combines two DID estimators via the generalized method
of moments (GMM) to achieve better properties than either estimator alone.

{pstd}
{bf:Assumption 2 (Extended Parallel Trends):} This assumption requires that
parallel trends hold for all pairs of adjacent time periods, including
pre-treatment periods. Formally, both of the following conditions hold:

{p 8 8 2}
E[Y(0)_T,t=2 - Y(0)_T,t=1] = E[Y(0)_C,t=2 - Y(0)_C,t=1]

{p 8 8 2}
E[Y(0)_T,t=1 - Y(0)_T,t=0] = E[Y(0)_C,t=1 - Y(0)_C,t=0]

{pstd}
where t=0,1 are pre-treatment periods and t=2 is the post-treatment period.

{pstd}
{bf:Assumption 3 (Parallel Trends-in-Trends):} This weaker assumption requires
only that the {it:change} in outcome trends is the same across treatment and
control groups. Formally:

{p 8 8 2}
[E[Y(0)_T,t=2 - Y(0)_T,t=1] - E[Y(0)_T,t=1 - Y(0)_T,t=0]]

{p 8 8 2}
= [E[Y(0)_C,t=2 - Y(0)_C,t=1] - E[Y(0)_C,t=1 - Y(0)_C,t=0]]

{pstd}
This assumption permits linear time-varying unmeasured confounding, where
unobserved confounding increases or decreases over time at a constant rate.

{pstd}
{bf:Relationship between assumptions:} The extended parallel trends assumption
(Assumption 2) implies both the standard parallel trends assumption (Assumption
1) and the parallel trends-in-trends assumption (Assumption 3). However,
Assumptions 1 and 3 are logically independent; neither implies the other.

{pstd}
{bf:The sequential DID estimator:} The sequential DID (sDID) estimator
subtracts the earlier pre-treatment DID from the standard DID in the
default lead(0) case:

{p 8 8 2}
tau_sDID = DID(t=2,t=1) - DID(t=1,t=0)

{pstd}
where DID(t1,t2) denotes the standard DID using periods t1 and t2. The sDID
estimator is consistent under Assumption 3 (parallel trends-in-trends).
When {cmd:lead()>0} is requested in {helpb diddesign}, the command instead uses
the lead-specific dynamic extension from Appendix E, anchored at the last
pre-treatment period rather than the adjacent post-treatment difference shown
above. See {helpb diddesign} for the runtime {cmd:lead()} contract and Appendix E
for the generalized {it:k}-th order difference definition.

{pstd}
{bf:The Double DID estimator:} The Double DID optimally combines the standard
DID and sequential DID estimators using GMM:

{p 8 8 2}
tau_dDID = w1 x tau_DID + w2 x tau_sDID

{pstd}
where w1 + w2 = 1, and the weights are chosen to minimize asymptotic variance:

{p 8 8 2}
w1 = [Var(tau_sDID) - Cov(tau_DID,tau_sDID)] / [Var(tau_DID) + Var(tau_sDID) - 2 x Cov(tau_DID,tau_sDID)]

{pstd}
Under the extended parallel trends assumption, the Double DID achieves variance
no larger than any of its component estimators. When only parallel
trends-in-trends holds, the Double DID converges to the sequential DID.

{pstd}
{bf:Generalized K-DID:} When more than two pre-treatment periods are available,
the {cmd:kmax()} option enables the generalized K-DID estimator (Appendix E of
the paper). The k-th component estimator uses a k-th order difference operator
that can account for (k-1)-th degree polynomial time-varying confounding. The
K-DID combines K component estimators via the same GMM framework. Optional
J-test moment selection ({cmd:jtest(on)}) uses Hansen's overidentification test
to adaptively drop potentially violated moment conditions.

{marker sa}{...}
{title:Staggered Adoption Design}

{pstd}
In many settings, different units receive treatment at different times. This
is called {bf:staggered adoption (SA)} or {bf:staggered treatment timing}.

{pstd}
{bf:Key features of SA designs:}

{phang2}
- Multiple treatment timing groups (cohorts)

{phang2}
- Not-yet-treated units serve as controls for newly-treated units

{phang2}
- Treatment effects are aggregated using time weights

{pstd}
The SA-Double-DID estimator computes:

{p 8 8 2}
tau_SA = Sum_t pi_t x tau_t

{pstd}
where pi_t is the proportion of units treated at time t, and tau_t is the
cohort-specific Double DID estimate.

{pstd}
{bf:The treatment timing matrix (Gmat):}

{pstd}
The package uses a treatment timing matrix to track each unit's treatment
status over time:

{p 8 12 2}
{cmd:0} = control or not-yet-treated

{p 8 12 2}
{cmd:1} = first treatment period (treatment onset)

{p 8 12 2}
{cmd:-1} = post-treatment (already treated in previous periods)

{marker assessment}{...}
{title:Parallel trends assessment}

{pstd}
{bf:Placebo tests:}

{pstd}
The {cmd:diddesign_check} command applies DID estimation to pre-treatment
periods only. If parallel trends hold, these placebo estimates should be
close to zero.

{pstd}
{bf:Limitations of traditional hypothesis testing:}

{pstd}
A common practice is to test H0: pre-trend = 0 and interpret non-rejection
as evidence for parallel trends. However, this reasoning is flawed. Failing
to reject the null may occur either because trends are truly parallel {it:or}
because the test lacks statistical power (e.g., small sample size).

{pstd}
{bf:Equivalence testing:}

{pstd}
Equivalence testing addresses this limitation by reversing the hypotheses:

{p 8 12 2}
H0: |pre-trend| >= delta (pre-trends are large)

{p 8 12 2}
H1: |pre-trend| < delta (pre-trends are small, within equivalence bound delta)

{pstd}
Rejecting H0 provides {it:positive evidence} that pre-trends are small, rather
than merely reflecting low statistical power.

{pstd}
{bf:Interpreting the 95% standardized equivalence CI:}

{pstd}
The command reports the 95% standardized equivalence confidence interval,
which indicates the smallest delta for which equivalence can be established.
This interval is expressed in units of the baseline control group standard
deviation.

{phang2}
- Narrower intervals provide stronger evidence for parallel trends

{phang2}
- Substantive interpretation should consider domain knowledge about what
constitutes a meaningful deviation

{marker workflow}{...}
{title:Recommended workflow}

{pstd}
{bf:Step 1: Assess parallel trends}

{pstd}
Use {helpb diddesign_check} to perform placebo tests on pre-treatment periods.
Specify the outcome variable, treatment indicator, unit identifier, and time
variable. Multiple lag periods can be tested to assess parallel trends across
different pre-treatment intervals. Examine the equivalence confidence intervals;
smaller intervals provide stronger support for the parallel trends assumption.

{pstd}
{bf:Step 2: Visualize diagnostics}

{pstd}
Use {helpb diddesign_plot} to generate diagnostic visualizations after running
{cmd:diddesign_check}. The trends plot displays outcome trajectories for
treatment and control groups, allowing visual inspection of whether groups
follow similar patterns before treatment. The placebo plot shows equivalence
confidence intervals centered around zero, with bounds indicating the magnitude
of potential pre-trends.

{pstd}
{bf:Step 3: Estimate treatment effects}

{pstd}
If diagnostics are satisfactory, use {helpb diddesign} to estimate treatment
effects. The command computes the Double DID estimator, which optimally
combines DID and sequential DID (sDID) using GMM weights. For staggered
adoption designs, specify {cmd:design(sa)} to account for multiple treatment
timing groups.

{pstd}
{bf:Step 4: Report results}

{pstd}
In publications, report both the diagnostic results (Steps 1-2) and the
main estimates (Step 3). Key elements to include:

{phang2}
- Equivalence CI bounds and the threshold used for assessment

{phang2}
- Trends plot showing pre-treatment patterns for both groups

{phang2}
- Double DID estimate with standard error and confidence interval

{phang2}
- GMM weights indicating the contribution of DID and sDID components

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
