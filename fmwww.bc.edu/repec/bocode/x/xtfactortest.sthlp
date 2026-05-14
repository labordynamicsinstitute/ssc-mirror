{smcl}
{* *! version 1.0.0  12 May 2026}{...}
{vieweralsosee "[XT] xtreg"      "help xtreg"}{...}
{vieweralsosee "xtdcce2"          "help xtdcce2"}{...}
{vieweralsosee "xthbtest"         "help xthbtest"}{...}
{vieweralsosee "xtcd2"            "help xtcd2"}{...}
{viewerjumpto "Syntax"            "xtfactortest##syntax"}{...}
{viewerjumpto "Description"       "xtfactortest##desc"}{...}
{viewerjumpto "Background"        "xtfactortest##bg"}{...}
{viewerjumpto "When to use"       "xtfactortest##when"}{...}
{viewerjumpto "Decision tree"     "xtfactortest##decision"}{...}
{viewerjumpto "Subcommands"       "xtfactortest##subs"}{...}
{viewerjumpto "Options"           "xtfactortest##opts"}{...}
{viewerjumpto "Interpretation"    "xtfactortest##interp"}{...}
{viewerjumpto "Workflow"          "xtfactortest##workflow"}{...}
{viewerjumpto "Examples"          "xtfactortest##ex"}{...}
{viewerjumpto "Pitfalls / FAQ"    "xtfactortest##faq"}{...}
{viewerjumpto "Stored results"    "xtfactortest##saved"}{...}
{viewerjumpto "References"        "xtfactortest##refs"}{...}
{viewerjumpto "Author"            "xtfactortest##author"}{...}

{title:Title}

{phang}
{bf:xtfactortest} {hline 2} A practitioner's battery of specification tests
for heterogeneous panel data models with interactive (multifactor) error
effects.  Tells you whether you actually need CCE or PC at all, and if
you do, which flavour.


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtfactortest}
{it:subcommand}
{depvar} {indepvars}
{ifin}
[{cmd:,} {it:options}]

{p 4 6 2}
A balanced panel previously declared with {help xtset} is required.
The cross-section dimension N must exceed the number of regressors K and the
time-series dimension T must satisfy T > K+1.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Subcommand (required)}
{synopt :{opt hb}}HB-CCE test of heterogeneity bias in pooled CCE
   (Juodis & Reese 2026, Lesson 2; modifies Campello, Galvao & Juhl 2019){p_end}
{synopt :{opt lm}}LM-X test for conditional independence between regressors
   and factor loadings (Kapetanios, Serlenga & Shin 2024){p_end}
{synopt :{opt hausman}}Hausman-type test of correlated factor loadings
   (Kapetanios, Serlenga & Shin 2023; FE vs CCE){p_end}
{synopt :{opt joint}}Joint HBFB test for heterogeneity OR factor-omission bias
   (Juodis & Reese 2026, Appendix A.2.2){p_end}
{synopt :{opt all}}Run all four tests with a summary table, a decision rule
   and a 2x2 panel of diagnostic graphs{p_end}

{syntab :Estimation / test options}
{synopt :{opth cross(varlist)}}extra observables to augment the CCE proxy
   matrix bar-Z (e.g. macro controls that should help span the factor
   space; rarely needed){p_end}
{synopt :{opt npc(#)}}number of leading principal components of the regressors
   used as instruments in the LM-X and HBFB tests.  Default {bf:1}; KSS 2024
   Theorem 1 / Remark 5 prove validity even when the true r > 1 because the
   portmanteau argument only requires the LEADING component to load.
   Increase only if you suspect a very rich factor structure.{p_end}
{synopt :{opt level(#)}}confidence / significance level (default 95){p_end}

{syntab :Reporting / output}
{synopt :{opt nograph}}suppress all graphs{p_end}
{synopt :{opth graphsave(prefix)}}filename prefix for saved .png graphs;
   produces {it:prefix}{cmd:_hb.png}, {it:prefix}{cmd:_lm.png},
   {it:prefix}{cmd:_haus.png}, {it:prefix}{cmd:_summary.png},
   {it:prefix}{cmd:_all.png}{p_end}
{synopt :{opt replace}}overwrite existing graph files{p_end}
{synopt :{opt noheader}}suppress the title block{p_end}
{synopt :{opt compact}}print the test statistic table only; suppress
   coefficient comparisons and CCE-MG estimates{p_end}
{synoptline}


{marker desc}{...}
{title:Description}

{pstd}
{cmd:xtfactortest} is a Stata library implementing a coherent battery of
specification tests for heterogeneous panel data models of the form

{p 8 16 2}
y_it  =  beta_i' x_it  +  gamma_i' f_t  +  eps_it ,

{p 8 16 2}
x_it  =  Lambda_i' f_t  +  v_it          (i = 1..N , t = 1..T)

{pstd}
with heterogeneous slope coefficients beta_i, heterogeneous factor
loadings gamma_i and Lambda_i, an r-vector of unobserved common factors
f_t, and idiosyncratic errors eps_it and v_it.

{pstd}
Such Interactive-Effects (IE) panels nest both the standard two-way
fixed effects (2W-FE) model and the Common Correlated Effects (CCE)
framework of Pesaran (2006).  Whether or not a researcher needs
CCE / PC depends on two concurrent issues:

{p 8 12 2}
(a) whether the slopes beta_i are heterogeneous and, if so, whether
that heterogeneity is correlated with VARIANCE features of the
regressors (Campello, Galvao & Juhl 2019);

{p 8 12 2}
(b) whether the regressors are correlated with the unobserved factor
loadings gamma_i (Bai 2009; Kapetanios, Serlenga & Shin 2023, 2024).

{pstd}
xtfactortest answers each question with a dedicated test plus a joint
test, and provides an explicit decision rule based on the five-lessons
review of Juodis & Reese (2026).


{marker bg}{...}
{title:Background -- why the tests matter}

{pstd}
The CCE estimator of Pesaran (2006) replaces the unobserved factors
f_t by the cross-sectional averages of y and x, producing a
residual-maker M_Fhat that partials out the common component.  CCE is
simple, robust to heterogeneous slopes, and is implemented in Stata by
{help xtdcce2} (Ditzen 2018).

{pstd}
Twenty years on, three practical concerns have emerged from the
applied-CCE literature (Juodis & Reese 2026):

{p 8 12 2}
1. The POOLED CCE estimator (CCEP) can be biased when slopes are
heterogeneous and that heterogeneity is correlated with the variance
of the regressors AFTER the CCE projection -- a direct analogue of the
OLS-FE heterogeneity bias of Campello et al. (2019).

{p 8 12 2}
2. If the regressors are CONDITIONALLY INDEPENDENT of the loadings
gamma_i, the simple two-way FE estimator remains consistent even
under IE (Coakley, Fuertes & Smith 2006; Westerlund 2019a).  In that
case CCE is unnecessary, possibly inefficient, and brings several
nontrivial complications (rank condition, leakage of nuisance
factors).

{p 8 12 2}
3. The Hausman-style choice between FE and PC/CCE is itself a test
about whether the regressors are correlated with the loadings;
Bai's (2009) original Hausman test is inconsistent in some regions
of the heterogeneous-slope DGP (Kapetanios, Serlenga & Shin 2023).

{pstd}
xtfactortest implements all four of the corresponding tests at once
and produces a single decision recommendation.


{marker when}{...}
{title:When to use each test}

{dlgtab:hb -- HB-CCE  (Juodis-Reese 2026, Lesson 2)}

{pstd}
Use the HB-CCE test AFTER you have decided that CCE estimation is
needed and you are choosing between the POOLED (CCEP) and MEAN-GROUP
(CCE-MG) variants.

{phang}
H_0 :  E[ X_i' M_Fhat X_i  (beta_i - beta_CCEMG) ]  =  0_K

{phang}
H_1 :  individual slopes beta_i are correlated with the unit-specific
CCE "information matrix"  X_i' M_Fhat X_i ;  under H_1 the pooled CCEP
is asymptotically biased.

{phang}
{bf:Practical guidance.}  Rejection => use the mean-group estimator
CCE-MG ({cmd:xtdcce2} option {cmd:lr}) rather than the pooled CCEP
({cmd:xtdcce2} default).  Not rejecting does not imply CCEP is
efficient; it implies CCEP is consistent for this sample.

{dlgtab:lm -- LM-X  (Kapetanios-Serlenga-Shin 2024)}

{pstd}
Use the LM-X test BEFORE deciding to estimate with CCE or PC at all.
Use it whenever you would otherwise apply Pesaran's (2015) CD test as
a diagnostic for cross-section dependence: rejection of CD does NOT
imply that 2W-FE is inconsistent.

{phang}
H_0 :  x_it is conditionally independent of gamma_i given f_t.

{phang}
H_1 :  regressors x_it correlated with factor loadings gamma_i.

{phang}
{bf:Practical guidance.}  Not rejecting H_0 means the simple 2W-FE
estimator is consistent under IE (Coakley-Fuertes-Smith result);
the user can keep 2W-FE for simplicity / efficiency and apply HAC
robust SE (Kapetanios, Serlenga & Shin 2023, eq. 11).  Rejection
means 2W-FE is biased: use CCE-MG or PC.

{dlgtab:hausman -- FE vs CCE  (Kapetanios-Serlenga-Shin 2023)}

{pstd}
Use the Hausman-type test as a SECOND OPINION on what LM-X tells you:
it compares the actual point estimates of 2W-FE and CCE-MG.  A large
coefficient gap is direct, intuitive evidence that the FE estimator
is inconsistent.

{phang}
H_0 :  regressors uncorrelated with loadings => beta_FE = beta_CCE
asymptotically.

{phang}
H_1 :  regressors correlated with loadings => beta_FE biased,
beta_CCE consistent => measurable coefficient gap.

{phang}
{bf:Practical guidance.}  LM-X and Hausman test essentially the same
hypothesis but from complementary angles: LM-X uses moment conditions
on FE residuals (no CCE estimation needed), Hausman uses the actual
coefficient gap.  When both reject, the conclusion is robust.

{dlgtab:joint -- HBFB  (Juodis-Reese 2026, App. A.2.2)}

{pstd}
Use the HBFB joint test as a single-shot Wald check on whether 2W-FE
is plausible at all.

{phang}
H_0 :  2W-FE has NEITHER heterogeneity bias NOR factor-omission bias.

{phang}
H_1 :  at least one source of bias is present.

{phang}
{bf:Practical guidance.}  Useful when you want a single omnibus
diagnostic.  If it does not reject, neither HB-CCE nor LM-X will (with
prob -> 1), so 2W-FE is safe.  If it rejects, you need the individual
tests above to identify which bias.


{marker decision}{...}
{title:Decision tree (Juodis-Reese 2026, Lessons 1-2)}

{pstd}
The {bf:all} subcommand automates the following logic:

{p 8 12 2}
{bf:Step 1.}  Run LM-X (or HBFB).  If H_0 not rejected =>  estimate
with 2W-FE + Driscoll-Kraay or cluster-robust SE.  Stop.

{p 8 12 2}
{bf:Step 2.}  If LM-X rejects: factor structure matters.  Run HB-CCE.

{p 8 12 2}
{bf:Step 3.}  If HB-CCE not rejected: slopes appear homogeneous.
Estimate with pooled CCEP ({cmd:xtdcce2}, default options).

{p 8 12 2}
{bf:Step 4.}  If HB-CCE rejects: estimate with the mean-group CCE-MG
({cmd:xtdcce2 ..., lr}).  In dynamic models add the half-panel jackknife
correction ({cmd:xtdcce2 ..., lr hpj}).

{pstd}
This decision tree is printed at the bottom of the {bf:all} subcommand's
output, instantiated with the actual rejections in your sample.


{marker subs}{...}
{title:Subcommands -- formulas and theory}

{dlgtab:hb -- HB-CCE test  (Juodis-Reese 2026, Lesson 2)}

{pstd}
Let  M_Fhat = I_T - Fhat (Fhat'Fhat)^(-1) Fhat'  be the CCE residual
maker, with  Fhat = (bar-y, bar-X)  the cross-sectional averages.
Compute the unit-specific CCE slopes

{p 8 16 2}
beta_hat_{i,CCE}  =  ( X_i' M_Fhat X_i )^(-1)  X_i' M_Fhat y_i

{pstd}
and the CCE-MG estimator

{p 8 16 2}
beta_hat_{CCE-MG}  =  N^(-1)  Sum_i  beta_hat_{i,CCE}

{pstd}
The HB-CCE moment condition is

{p 8 16 2}
delta_hat_{HB,i}  =  [ X_i' M_Fhat X_i  -  N^(-1) Sum_j X_j' M_Fhat X_j ]
                    ( beta_hat_{i,CCE} - beta_hat_{CCE-MG} )

{pstd}
with  delta_hat_{HB} = (1/N) Sum_i delta_hat_{HB,i}  and non-parametric
variance

{p 8 16 2}
Var_hat( delta_hat_{HB} )  =  N^(-2)  Sum_i  delta_hat_{HB,i}
                              delta_hat_{HB,i}'

{pstd}
Under H_0 and standard regularity conditions

{p 8 16 2}
{bf:HB}  =  delta_hat_{HB}'  Var_hat^(-1)  delta_hat_{HB}
         ~  chi^2(K)

{pstd}
where K is the number of regressors.  Asymptotic theory holds for both
N -> infinity with T fixed and joint (N,T) -> infinity.


{dlgtab:lm -- LM-X test  (Kapetanios-Serlenga-Shin 2024)}

{pstd}
Apply the two-way within transformation

{p 8 16 2}
ddot-y_it  =  y_it  -  bar-y_{i.}  -  bar-y_{.t}  +  bar-y_{..}

{pstd}
and similarly for x.  Compute the individual FE estimator

{p 8 16 2}
beta_hat_{FE,i}  =  ( ddot-X_i' ddot-X_i )^(-1)  ddot-X_i' ddot-y_i

{pstd}
and the FE residuals

{p 8 16 2}
u_hat_i  =  ddot-y_i  -  ddot-X_i  beta_hat_{FE,i}.

{pstd}
Extract the leading  r = {opt npc()}  principal components of the
regressors from the eigendecomposition of

{p 8 16 2}
S  =  (NT)^(-1)  Sum_i  ddot-X_i  ddot-X_i'

{pstd}
and set  Fhat_X = sqrt(T) * (eigenvectors of S corresponding to the r
largest eigenvalues).  Form the projected regressors

{p 8 16 2}
Xhat_i  =  Fhat_X  ( Fhat_X' Fhat_X )^(-1)  Fhat_X'  ddot-X_i.

{pstd}
The LM-X statistic is the score-form Wald

{p 8 16 2}
{bf:LM_X}  =  [ N^(-1/2) Sum_i  Xhat_i' u_hat_i / T ]'
              V_hat^(-1)
              [ N^(-1/2) Sum_i  Xhat_i' u_hat_i / T ]
           ~  chi^2(K)

{pstd}
with sandwich variance

{p 8 16 2}
V_hat  =  N^(-1)  Sum_i  Xhat_i' u_hat_i u_hat_i' Xhat_i  /  T^2 .

{pstd}
KSS 2024 prove that the test follows chi^2(K) under H_0 even when the
true number of factors r > 1 (portmanteau result, Theorem 1).  This is
why setting {bf:npc(1)} works in essentially all practical settings.


{dlgtab:hausman -- FE vs CCE  (Kapetanios-Serlenga-Shin 2023)}

{pstd}
Compute the mean-group 2W-FE and CCE-MG estimators along with their
non-parametric variances

{p 8 16 2}
V_FE   =  [N(N-1)]^(-1)  Sum_i  (beta_hat_{i,FE}  - beta_hat_FE )
                                (beta_hat_{i,FE}  - beta_hat_FE )'

{p 8 16 2}
V_CCE  =  [N(N-1)]^(-1)  Sum_i  (beta_hat_{i,CCE} - beta_hat_{CCE-MG})
                                (beta_hat_{i,CCE} - beta_hat_{CCE-MG})'

{pstd}
and the cross-covariance

{p 8 16 2}
Cov    =  [N(N-1)]^(-1)  Sum_i  (beta_hat_{i,FE}  - beta_hat_FE )
                                (beta_hat_{i,CCE} - beta_hat_{CCE-MG})'

{pstd}
The Hausman-type statistic is

{p 8 16 2}
{bf:H}  =  ( beta_hat_FE - beta_hat_{CCE-MG} )'
           ( V_FE + V_CCE - Cov - Cov' )^(-1)
           ( beta_hat_FE - beta_hat_{CCE-MG} )
        ~  chi^2(K)


{dlgtab:joint -- HBFB  (Juodis-Reese 2026, App. A.2.2)}

{pstd}
The HBFB statistic stacks the HB-CCE moments and a KSS-style
factor-omission moment into a 2K-dim vector

{p 8 16 2}
delta_hat_{HBFB,i}  =  ( delta_hat_{HB,i}' ,  delta_hat_{FB,i}' )'

{pstd}
where  delta_hat_{FB,i}  =  Xhat_i' u_hat_{FE,i} / T  is the LM-X
moment for unit i.  The joint statistic

{p 8 16 2}
{bf:HBFB}  =  delta_hat_{HBFB}'  Var_hat^(-1)  delta_hat_{HBFB}
           ~  chi^2(2K)


{marker opts}{...}
{title:Options -- details}

{phang}
{opth cross(varlist)} -- appends extra observed variables to the
cross-sectional average matrix bar-Z.  Use this when there are
additional relevant macro-level variables that should help span the
unobserved factor space (cf. Pesaran et al. 2013, Pesaran 2007 in the
CIPS context).  Most empirical work does not need this option.

{phang}
{opt npc(#)} -- sets the number of regressor principal components used
as instruments in the LM-X test.  The KSS 2024 portmanteau result
(their Theorem 1, Remark 5) supports {bf:npc(1)} even when the true
number of factors r > 1.  Increase only if your regressors clearly
carry several distinct trends (e.g. cross-country macro panels with
multiple global shocks).

{phang}
{opt level(#)} -- significance level used for all four test decisions
and the 95% confidence intervals on the Hausman coefficient plot.

{phang}
{opt graphsave(prefix)} -- writes the PNG files
{it:prefix}_hb.png, {it:prefix}_lm.png, {it:prefix}_haus.png,
{it:prefix}_summary.png and the combined view {it:prefix}_all.png.
Each individual graph also remains in memory under the names
{cmd:xtft_hb}, {cmd:xtft_lm}, {cmd:xtft_haus}, {cmd:xtft_summary},
{cmd:xtft_all}, so you can redisplay any of them later with
{cmd:graph display xtft_hb} etc.

{phang}
{opt compact} -- prints only the test header + statistic table; the
coefficient comparison block and CCE-MG coefficient block are omitted.


{marker interp}{...}
{title:Interpreting the output}

{pstd}
For each subcommand xtfactortest prints (i) a citation block, (ii) the
null and alternative in plain English, (iii) the statistic / df /
p-value / decision row.  When run with {bf:all} a unified summary
table and a plain-English decision rule are appended.

{pstd}
The output of {bf:all} is colour-coded:

{p 8 12 2}
- {it:Statistic} : printed in result colour; df is the chi^2 dof, not
a sample-size statistic.

{p 8 12 2}
- {it:Decision} : if the p-value is below  1 - {bf:level}/100  (default
0.05) the row is marked in red as REJECT H0; otherwise green "do not
reject".

{pstd}
The {bf:Decision rule} paragraph at the bottom translates the four
rejections (HB-CCE, LM-X, Hausman, HBFB) into one of five recommended
estimators:

{p 12 16 2}
- no rejection            =>  2W-FE
{p_end}
{p 12 16 2}
- LM/Hausman reject, HB not =>  CCEP (pooled CCE)
{p_end}
{p 12 16 2}
- HB rejects, LM/Hausman not =>  CCE-MG (mean-group CCE)
{p_end}
{p 12 16 2}
- both reject              =>  CCE-MG (with HPJ in dynamic settings)
{p_end}
{p 12 16 2}
- mixed                    =>  see individual results
{p_end}

{pstd}
The 2x2 graph window combines the four individual diagnostic plots.
The HB-CCE histogram of individual slopes is directly comparable to
Fig. 3 of Campello et al. (2019); the LM-X scatter and the FE-vs-CCE
coefficient plot replicate Figs. 1 and 2 of Juodis & Reese (2026).


{marker workflow}{...}
{title:Recommended workflow for empirical papers}

{phang}{bf:Step 1.}  Declare the panel:
        {p_end}
{phang2}{cmd:xtset id time}{p_end}

{phang}{bf:Step 2.}  Diagnose cross-section dependence (still
recommended even though CD rejection alone is not informative about
FE inconsistency, cf. KSS 2024):
        {p_end}
{phang2}{cmd:xtreg y x1 x2, fe}{p_end}
{phang2}{cmd:xtcd2 e(sample)}{p_end}

{phang}{bf:Step 3.}  Run the xtfactortest battery:
        {p_end}
{phang2}{cmd:xtfactortest all y x1 x2 x3}{p_end}

{phang}{bf:Step 4.}  Follow the recommendation produced by the
decision rule.  Then estimate using {help xtdcce2}:
        {p_end}
{phang2}{cmd:xtdcce2 y x1 x2 x3, crosssectional(_all) lr(L.y x1) ...}{p_end}

{phang}{bf:Step 5.}  Report all four xtfactortest statistics in the
specification-test appendix of your paper to allow the reader to
evaluate your estimation choice.


{marker ex}{...}
{title:Examples}

{pstd}
{bf:Stata example panel (Penn World Table productivity data):}{p_end}
{phang2}{cmd:. use https://www.stata-press.com/data/r17/productivity, clear}{p_end}
{phang2}{cmd:. xtset state year}{p_end}

{pstd}
Run all four tests with default graphs and decision rule:{p_end}
{phang2}{cmd:. xtfactortest all gsp pcap pc emp unemp}{p_end}

{pstd}
HB-CCE test only, saving the figure:{p_end}
{phang2}{cmd:. xtfactortest hb gsp pcap pc emp, graphsave(myout) replace}{p_end}

{pstd}
LM-X test with two principal components:{p_end}
{phang2}{cmd:. xtfactortest lm gsp pcap pc emp, npc(2)}{p_end}

{pstd}
Hausman-type test at the 1% level, compact output:{p_end}
{phang2}{cmd:. xtfactortest hausman gsp pcap pc emp, level(99) compact}{p_end}

{pstd}
Full battery followed by CCE estimation (using {help xtdcce2}):{p_end}
{phang2}{cmd:. xtfactortest all gsp pcap pc emp}{p_end}
{phang2}{cmd:. xtdcce2 gsp pcap pc emp , crosssectional(_all) lr}{p_end}


{marker faq}{...}
{title:Common pitfalls and FAQ}

{phang}
{bf:Q1.  My CD test rejects.  Does that mean I must use CCE?}{break}
A.  No.  Pesaran's CD test signals the PRESENCE of cross-section
dependence, not the inconsistency of 2W-FE.  The Coakley-Fuertes-Smith
(2006) / Westerlund (2019a) result says 2W-FE is consistent if
regressors are conditionally independent of loadings.  Run {bf:lm} or
{bf:hausman} to verify before switching to CCE.

{phang}
{bf:Q2.  HB-CCE rejects but Hausman does not.  Which estimator?}{break}
A.  HB-CCE is a test of POOLED CCE inconsistency under heterogeneous
slopes.  Hausman compares the MEAN-GROUP versions of FE and CCE.  The
pattern "HB reject, Hausman do not reject" implies your slopes are
heterogeneous but in a way that is uncorrelated with loadings;
therefore use {bf:CCE-MG} ({cmd:xtdcce2 ..., lr}) or 2W-FE-MG, but
NOT pooled CCEP.

{phang}
{bf:Q3.  My panel has T = 10.  Are these tests reliable?}{break}
A.  All four tests are formally derived under joint (N,T) -> infinity.
KSS 2024 and Campello et al. (2019) show good finite-sample size and
power for T as small as 5 (LM-X) and 10 (HB) when the cross-section
is moderate (N >= 30).  See Tables 1-5 of the respective papers.

{phang}
{bf:Q4.  My panel is unbalanced.}{break}
A.  xtfactortest currently requires a balanced panel; it errors out
otherwise.  Pre-process with {help xtbalance} (Stata Journal package)
or by restricting the sample to a balanced subset before calling
xtfactortest.  An unbalanced extension is on the roadmap.

{phang}
{bf:Q5.  I have a dynamic panel (lagged dependent variable).}{break}
A.  All four tests remain valid under serial correlation of the
idiosyncratic errors and lagged dependent variables, provided the
factor structure is correctly specified.  After deciding to use CCE,
add the HPJ bias correction via {cmd:xtdcce2 ..., lr hpj}.

{phang}
{bf:Q6.  My regressors include time-invariant variables.}{break}
A.  Time-invariant regressors are absorbed by the two-way within
transformation and the CCE residual maker.  Their slopes are not
identified and they should be removed from the {indepvars} list.

{phang}
{bf:Q7.  Some tests reject, some don't.  Which estimator should I
report?}{break}
A.  Follow the decision rule printed at the end of {bf:all}.  When in
doubt, the mean-group CCE-MG is the safer default: it is robust to
slope heterogeneity AND to factor structure, at the cost of moderate
efficiency loss when both are absent (Juodis & Reese 2026, Lesson 2).

{phang}
{bf:Q8.  How is xtfactortest related to xthbtest?}{break}
A.  {help xthbtest} (Hong & Galvao, original Campello-Galvao-Juhl
implementation) tests heterogeneity bias of the OLS-FE estimator
using the within projection M_iota.  xtfactortest's HB-CCE subcommand
replaces M_iota with the CCE residual maker M_Fhat to test
heterogeneity bias of the CCEP estimator -- the modification
proposed in Juodis & Reese (2026, Lesson 2).

{phang}
{bf:Q9.  How does this compare to Bai's (2009) Hausman test?}{break}
A.  Bai's H_B compares FE with the iterative PC estimator.  KSS
(2023) and Westerlund (2019b) show that this test is inconsistent
against the alternative of correlated loadings when slopes are
heterogeneous.  xtfactortest's {bf:hausman} subcommand uses the
KSS (2023) modification with the non-parametric V_NON estimator,
which is consistent under both homogeneous AND heterogeneous slopes.


{marker saved}{...}
{title:Stored results}

{pstd}
{cmd:xtfactortest} {it:subcmd} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars (all subcommands)}{p_end}
{synopt:{cmd:r(N)}}cross-sectional dimension{p_end}
{synopt:{cmd:r(T)}}time-series dimension{p_end}
{synopt:{cmd:r(K)}}number of regressors{p_end}
{synopt:{cmd:r(df)}}degrees of freedom of the chi^2 test{p_end}
{synopt:{cmd:r(pvalue)}}p-value of the test{p_end}

{p2col 5 22 26 2: Scalars (subcommand-specific)}{p_end}
{synopt:{cmd:r(HB) | r(LM) | r(H) | r(HBFB)}}test statistic{p_end}
{synopt:{cmd:r(npc)}}number of PCs used (LM-X only){p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(test)}}short name of the test{p_end}
{synopt:{cmd:r(ref)}}methodological reference{p_end}

{p2col 5 22 26 2: Matrices (HB-CCE)}{p_end}
{synopt:{cmd:r(beta_CCEMG)}}CCE-MG mean-group coefficients{p_end}
{synopt:{cmd:r(Var_CCEMG)}}Pesaran-2006 nonparametric variance{p_end}
{synopt:{cmd:r(beta_i)}}N x K matrix of individual CCE slopes{p_end}
{synopt:{cmd:r(delta_HB)}}sample moment  delta_hat_HB{p_end}

{p2col 5 22 26 2: Matrices (LM-X)}{p_end}
{synopt:{cmd:r(diag_lm)}}N x 2 diagnostic data (PC projection, residuals){p_end}

{p2col 5 22 26 2: Matrices (Hausman)}{p_end}
{synopt:{cmd:r(beta_FE) r(beta_CCE)}}coefficient vectors{p_end}
{synopt:{cmd:r(V_FE) r(V_CCE)}}variance matrices{p_end}


{marker refs}{...}
{title:References}

{phang}
Bai, J. (2009). Panel data models with interactive fixed effects.
{it:Econometrica} 77(4): 1229-1279.

{phang}
Campello, M., A.F. Galvao & T. Juhl (2019). Testing for slope
heterogeneity bias in panel data models.
{it:Journal of Business & Economic Statistics} 37(4): 749-760.

{phang}
Coakley, J., A.-M. Fuertes & R.P. Smith (2006). Unobserved
heterogeneity in panel time series models.
{it:Computational Statistics & Data Analysis} 50: 2361-2380.

{phang}
Ditzen, J. (2018). Estimating dynamic common-correlated effects in
Stata.  {it:Stata Journal} 18(3): 585-617.

{phang}
Juodis, A. & S. Reese (2026). Five lessons for applied researchers
from twenty years of common correlated effects estimation.
{it:Journal of Econometrics} 253: 106120.

{phang}
Kapetanios, G., L. Serlenga & Y. Shin (2023). Testing for correlation
between the regressors and factor loadings in heterogeneous panels
with interactive effects.
{it:Empirical Economics} 64: 2611-2659.

{phang}
Kapetanios, G., L. Serlenga & Y. Shin (2024). An LM test for the
conditional independence between regressors and factor loadings in
panel data models with interactive effects.
{it:Journal of Business & Economic Statistics} 42(2): 743-761.

{phang}
Pesaran, M.H. (2006). Estimation and inference in large heterogeneous
panels with a multifactor error structure.
{it:Econometrica} 74: 967-1012.

{phang}
Pesaran, M.H. (2015). Testing weak cross-sectional dependence in large
panels. {it:Econometric Reviews} 34(6-10): 1089-1117.

{phang}
Westerlund, J. (2019a). On estimation and inference in heterogeneous
panel regressions with interactive effects.
{it:Journal of Time Series Analysis} 40: 852-857.

{phang}
Westerlund, J. (2019b). Testing additive versus interactive effects in
fixed-T panels. {it:Economics Letters} 174: 5-8.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{cmd:merwanroudane920@gmail.com}{break}
{it:xtfactortest v1.0 -- May 2026}

{pstd}
Please cite the underlying methodological papers (Campello et al. 2019;
Juodis & Reese 2026; Kapetanios, Serlenga & Shin 2023, 2024) when
reporting test results obtained with this package.

{pstd}
For bug reports, feature requests or methodological discussion please
email the author or open a thread on Statalist with subject
{cmd:[xtfactortest]}.
