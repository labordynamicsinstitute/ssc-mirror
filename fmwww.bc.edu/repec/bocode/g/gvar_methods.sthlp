{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar references" "help gvar_references"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{viewerjumpto "The model" "gvar_methods##model"}{...}
{viewerjumpto "Estimation" "gvar_methods##estimation"}{...}
{viewerjumpto "Solving" "gvar_methods##solving"}{...}
{viewerjumpto "zeta and eta" "gvar_methods##zetaeta"}{...}
{viewerjumpto "The singular covariance" "gvar_methods##singular"}{...}
{viewerjumpto "Dynamic analysis" "gvar_methods##dynamics"}{...}
{viewerjumpto "The bootstrap" "gvar_methods##bootstrap"}{...}
{viewerjumpto "Step to source map" "gvar_methods##map"}{...}
{viewerjumpto "Where the sources are wrong" "gvar_methods##defects"}{...}
{viewerjumpto "Weak exogeneity: a known deviation" "gvar_methods##wedev"}{...}
{viewerjumpto "Checks that do not work" "gvar_methods##nonchecks"}{...}
{title:Title}

{phang}
{bf:gvar methods} {hline 2} equations, the step-to-source map, and where the
reference implementations disagree


{marker model}{...}
{title:The model}

{pstd}
{it:N} units, unit {it:i} carrying {it:k_i} domestic variables. The global
vector {it:x_t} stacks them all and has length {it:K = sum k_i}. Link
matrices {it:W_i}, of dimension {it:(k_i + k*_i) x K}, select each unit's own
variables and build its foreign block:

        {it:z_it = W_i x_t = (y_it', y*_it')'}

{pstd}
Each foreign variable is a weighted average over the units that own the
matching domestic variable, with the weights renormalised to sum to one. A
weakly exogenous {it:global} variable, which no unit owns, gets an unweighted
indicator row instead.


{marker estimation}{...}
{title:Estimation}

{pstd}
The country model is a VECMX* with {it:y*} treated as I(1) and weakly
exogenous. Reduced-rank ML follows Johansen, conditional on the foreign
block, with critical values from Pesaran, Shin and Smith (2000) indexed by
the deterministic case, {it:n - r} and {it:k}. Three deterministic cases are
supported, in the MacKinnon-Haug-Michelis numbering:

{p2colset 9 20 22 2}{...}
{p2col:{bf:case 2}}restricted intercept, no trend{p_end}
{p2col:{bf:case 3}}unrestricted intercept, no trend{p_end}
{p2col:{bf:case 4}}unrestricted intercept, restricted trend{p_end}
{p2colreset}{...}

{pstd}
In cases 2 and 4 the first row of {it:beta} carries the deterministic term,
which is why {helpb gvar_overid:gvar overid} lists {cmd:_cons} or
{cmd:_trend} as the leading row of {it:beta}.


{marker solving}{...}
{title:Solving}

{pstd}
Writing each country model in VARX* levels form and stacking through the link
matrices gives

        {it:G0 x_t = h0 + h1 t + sum_l H_l x(t-l) + zeta_t}

{pstd}
with {it:G0 = stack(A_i0 W_i)} and {it:H_l = stack(A_il W_i)}. Inverting:

        {it:x_t = d0 + d1 t + sum_l F_l x(t-l) + eta_t},
        {it:F_l = G0^-1 H_l},   {it:eta_t = G0^-1 zeta_t}

{pstd}
{cmd:gvar solve} reports the eigenvalues of the companion matrix. A GVAR with
{it:K} variables and {it:sum r_i} cointegrating relations should have exactly
{it:K - sum r_i} unit roots; the command checks that and says so.


{marker zetaeta}{...}
{title:zeta and eta: which covariance goes where}

{pstd}
This distinction causes more errors than anything else in the model, so it is
worth stating flatly.

{p2colset 9 22 24 2}{...}
{p2col:{it:zeta_t}}the stacked country-model residuals. Covariance
{it:Sigma_zeta}.{p_end}
{p2col:{it:eta_t}}the reduced-form innovations, {it:G0^-1 zeta_t}. Covariance
{it:Sigma_eta = G0^-1 Sigma_zeta G0^-1'}.{p_end}
{p2colreset}{...}

{pstd}
{bf:Impulse responses, variance decompositions and persistence profiles}
{bf:take Sigma_zeta.}
The formula is
{it:Phi_h G0^-1 Sigma_zeta e_j / sqrt(e_j' Sigma_zeta e_j)},
and {it:irf.m} forms {cmd:G\Sigma_u} internally. Supplying
{it:Sigma_eta} applies {it:G0^-1} twice and cross-mixes every shock.

{pstd}
{bf:Historical decompositions and forecast error bands take Sigma_eta,}
because they work from the reduced form directly.

{pstd}
{bf:The Beveridge-Nelson trend/cycle decomposition takes Sigma_eta too} - or
rather it cumulates {it:eta}, not {it:zeta}. See
{helpb gvar_methods##defects:below}.


{marker singular}{...}
{title:The singular covariance, and what to do about it}

{pstd}
{it:Sigma_zeta} is {it:K x K} but is built from {it:T} observations, so its
rank is at most {it:T}. In any GVAR with more variables than periods it is
singular by construction. In the shipped 26-unit demo {it:K} = 136,
{it:T} = 134 and the rank is 133.

{pstd}
Nothing that needs a Cholesky factor can therefore be computed unaided: no
orthogonalised IRF, no structural GIRF over a large leading block, no
orthogonal FEVD, no historical decomposition, and no bootstrap draw in
orthogonalised space. Generalized responses need no factor and are what the
literature reports for systems this size.

{pstd}
The remedies, both from the Toolbox:

{p2colset 9 26 28 2}{...}
{p2col:{cmd:shrink}}shrink the correlation matrix towards the identity with
the intensity that minimises expected quadratic loss, then rescale by the
original standard deviations, so the variances are untouched. In the demo
this gives lambda* = 0.375 and restores full rank.{p_end}
{p2col:{cmd:lambda(#)}}set the intensity by hand.{p_end}
{p2col:{cmd:vcov(blockdiag)}}zero every cross-unit covariance, which imposes
that shocks are uncorrelated across units.{p_end}
{p2col:{cmd:shuffle}}for the bootstrap only: resample whole date columns
instead of orthogonalised scalars. This needs no factor at all and preserves
the empirical cross-section correlation exactly.{p_end}
{p2colreset}{...}

{pstd}
For a model with {it:K > T}, {cmd:shuffle} is the better bootstrap. Measured
on the demo over 100 kept replications, it discarded 13 draws as unstable
against 59 for {cmd:shrinkdraw}, and gave narrower bands (mean width 0.0094
against 0.0108).


{marker dynamics}{...}
{title:Dynamic analysis}

{pstd}
{bf:Generalized IRF} (Pesaran and Shin 1998). Invariant to the ordering of
the variables, which is why it is the default: with 136 variables no Cholesky
ordering is defensible. The shocks are correlated by construction, so the
responses do not decompose into orthogonal contributions.

{pstd}
{bf:Orthogonalised IRF.} Cholesky on the whole system. Depends on the order
of {it:x_t}; see {helpb gvar_describe:gvar describe, order}. Note that in a
GVAR the impact matrix is {it:G0^-1 P}, not {it:P}, so it is {bf:not}
triangular even though {it:P} is.

{pstd}
{bf:Structural GIRF.} Orthogonalises only a leading block. Which variables
lead is the identifying assumption, set with {cmd:first()} and
{cmd:vorder()}. The block size {it:n0} is derived from that choice, never
typed.

{pstd}
{bf:Generalized FEVD} does not sum to one across shocks, because the shocks
are correlated. That is a property of the estimator, not a defect; the
reported TOTAL column shows how far from one it falls. Use {cmd:type(oirf)}
for shares that do sum to one.

{pstd}
{bf:Persistence profiles} (Pesaran and Shin 1996) start at one by
construction and must converge to zero. A relation that does not settle back
is not a long-run relation, whatever the rank test said.


{marker bootstrap}{...}
{title:The bootstrap}

{pstd}
{cmd:reps()} on {helpb gvar_irf:gvar irf}, {helpb gvar_pp:gvar pp} and
{helpb gvar_stability:gvar stability} runs the full model-level bootstrap of
{it:bootstrap_GVAR.m}. Every step of the point estimate is replicated:

{p 8 12 2}
1. recentre the country-model residuals by row means{p_end}
{p 8 12 2}
2. draw, either by resampling {it:K x T} orthogonalised scalars or, with
{cmd:shuffle}, whole date columns{p_end}
{p 8 12 2}
3. regenerate the global vector from the reduced form, holding the first
{it:pmax} observations at their actual values{p_end}
{p 8 12 2}
4. rebuild each unit's domestic and foreign blocks through {it:W_i}{p_end}
{p 8 12 2}
5. re-estimate all country models at their own (p, q, case, rank){p_end}
{p 8 12 2}
6. re-stack, re-solve, discard the replication if unstable, capped at
2B{p_end}
{p 8 12 2}
7. recompute the statistic{p_end}

{pstd}
The number discarded is reported, and matters: a high discard rate means the
bands are conditioned on a non-random subset of draws.

{pstd}
Quantiles follow the source: (0.05, 0.50, 0.95) for the dynamic objects,
(0.90, 0.95, 0.99) for the stability battery, which is one-sided. Note that a
95th percentile from {it:B} draws is the 0.95{it:B}-th order statistic; these
statistics are right-skewed, so a small {it:B} biases the critical value
{bf:down} and inflates rejections. Use {cmd:reps(200)} or more.


{marker bayes}{...}
{title:The Bayesian branch}

{pstd}
{helpb gvar_bayes:gvar bayes} replaces
{helpb gvar_estimate:gvar estimate}: it samples every country VARX* by MCMC
instead of fitting it by reduced-rank ML, then writes the posterior mean into
the same country-model slots, so {helpb gvar_solve:gvar solve} and the whole
dynamic-analysis group proceed unchanged. It follows {it:BVAR_linear.cpp} in
BGVAR.

{pstd}
{bf:The sampler is two loops per sweep}, not one. The coefficients are drawn
equation by equation as a GLS draw conditioned on {it:every} other equation
through {it:L^-1}; then the free elements of {it:L} are drawn by regressing each
equation's residual on the earlier ones. {it:BVAR_linear.cpp} also contains a
joint version at line 413 that draws the two together, conditioning only on the
{it:preceding} equations -- it sits inside a comment block and is not what runs.
Two different conditional distributions, both producing plausible posteriors, and
no convergence diagnostic distinguishes them.

{pstd}
{bf:Sigma = L D L'}, and the direction is fixed by the source rather than
chosen. {it:BVAR_linear.cpp}:412 forms the structural residuals as
{it:(Y - X A) L^-1'} and :780 takes those as the series whose variance {bf:is}
{it:D}, so {it:D = L^-1 Sigma L^-1'}. {it:utils.R}:381 writes the product out and
:809 confirms the stored factor is {it:L} and not its inverse. It is also what
makes the whitening work: the coefficient draw multiplies by {it:L^-1}, which
only yields independent components if {it:L^-1 Sigma L^-1'} is diagonal.

{pstd}
{bf:The four priors are four fill-rules for V}, not four samplers. They share
both loops above entirely; all that changes is how the prior variance matrix is
refilled each sweep. Minnesota sets it once and deterministically; SSVS refills
it from a spike and slab; Normal-Gamma and Horseshoe refill it from a
global-local hierarchy. See {helpb gvar_bayes:gvar bayes} for each.

{pstd}
{bf:Three pieces are not in the BGVAR source tree} and had to be written from
their published algorithms, then gated on their own tests rather than against
another implementation:

{p 8 12 2}
the generalised inverse Gaussian draw for {cmd:prior(ng)} -- {it:do_rgig1.cpp}
delegates to the {bf:GIGrvg} package. Gated against the closed-form GIG moments,
{it:E[X] = sqrt(chi/psi) K_(l+1)(w)/K_l(w)}.{p_end}

{p 8 12 2}
Geweke's diagnostic for {helpb gvar_bconv:gvar bconv} -- {cmd:conv.diag}
delegates to {bf:coda}. Gated on the spectral density at zero against its
closed form for an AR(1), on the {bf:size} of the test under i.i.d. chains, and
on its {bf:power} against a drifting chain and a random walk.{p_end}

{p 8 12 2}
the stochastic-volatility sampler -- BGVAR calls
{cmd:stochvol::update_fast_sv}. The {bf:target} is reproduced exactly, the
{bf:algorithm} is not: the source interweaves (Kastner and
Fruehwirth-Schnatter 2014), which lowers autocorrelation without changing the
posterior, so this sampler converges to the same distribution and may mix more
slowly. Gated on the mixture's moments against {it:log(chi^2_1)}, on recovery of
a known volatility path, and on {bf:not} inventing variation in
constant-variance data.{p_end}

{pstd}
{bf:Stability is screened per draw, globally.} The eigenvalue trim stacks each
retained draw, takes the largest companion eigenvalue modulus, and discards
draws at or above the cutoff -- 1.05 by default, as BGVAR's
{cmd:.gvar.stacking.wrapper} does, stopping outright below 10 stable draws. It is
a global rule because a country model can be perfectly stable while the
assembled system is not, and the reverse. On the shipped 26-unit demo those
moduli run about 1.09 to 1.31, so the default discards everything and the
command says so with the numbers; see {helpb gvar_bayes:gvar bayes}.

{pstd}
{bf:What the Bayesian branch does not produce is a cointegrating rank.} A VARX
in levels imposes none, so {it:beta} and {it:alpha} do not exist for it.
{helpb gvar_pp:gvar pp} and {helpb gvar_overid:gvar overid} are defined on those
vectors and refuse rather than use whatever an earlier
{helpb gvar_estimate:gvar estimate} left behind, and
{helpb gvar_solve:gvar solve} skips its {it:K - sum(r)} unit-root count, which
has nothing to compare against. The reduced-form tools -- {helpb gvar_irf:irf},
{helpb gvar_fevd:fevd}, {helpb gvar_hd:hd},
{helpb gvar_forecast:forecast} -- work from either estimator.


{marker map}{...}
{title:Step to source map}

{synoptset 30 tabbed}{...}
{synopthdr:step}
{synoptline}
{synopt:link matrices}{it:create_linkmatrices.m}{p_end}
{synopt:weight matrices}{it:build_wmat.m}, {it:weightmat.m},
{it:update_matrix.m}{p_end}
{synopt:foreign variables}{it:create_foreignvariables.m}{p_end}
{synopt:unit root tests}{it:adf.m}, {it:ws.m}, {it:unitroot_tests.m}{p_end}
{synopt:lag selection}{it:select_varxlag.m}, {it:AIC_SBC.m}{p_end}
{synopt:cointegration}{it:cointegration_test.m}, {it:get_rank.m}{p_end}
{synopt:VECMX* ML}{it:mlcoint.m}; restricted, {it:mlcoint_r.m}{p_end}
{synopt:VARX* recovery}{it:vecx2varx.m}{p_end}
{synopt:stacking and solving}{it:solve_GVAR.m}{p_end}
{synopt:weak exogeneity}{it:test_weakexogeneity.m},
{it:select_lags_we.m}{p_end}
{synopt:contemporaneous effects}{it:contmpcoeff.m}{p_end}
{synopt:average correlations}{it:avgcorrs.m}, {it:corrmat.m}{p_end}
{synopt:serial correlation F}{it:Ftest_rsc.m}{p_end}
{synopt:multivariate diagnostics}GVARX {it:.jb.multi}, {it:.pt.multi},
{it:.bgserial}, {it:.arch.multi}{p_end}
{synopt:structural stability}{it:kraplob.m}, {it:nyblom.m},
{it:schow.m}{p_end}
{synopt:over-identifying restrictions}{it:overid_restr.m},
{it:mlcoint_r.m}{p_end}
{synopt:Granger causality}GVARX {it:.grangerGVAR}, vars
{it:causality()}{p_end}
{synopt:impulse responses}{it:irf.m}, {it:phi.m}{p_end}
{synopt:variance decomposition}{it:fevd.m}{p_end}
{synopt:persistence profiles}{it:pprofile.m}{p_end}
{synopt:reordering for SGIRF}{it:reorder_GVAR.m}{p_end}
{synopt:covariance handling}{it:transform_varcov.m},
{it:ShrinkageCorrLstar.m}{p_end}
{synopt:forecasting}{it:forecast_GVAR.m}, {it:con_forecast_GVAR.m}{p_end}
{synopt:trend/cycle}{it:TCdecomp.m}, {it:TC_trend_restr.m}{p_end}
{synopt:historical decomposition}BGVAR {it:hd.R}{p_end}
{synopt:connectedness}BGVAR {it:conn}; Diebold and Yilmaz (2014){p_end}
{synopt:bootstrap}{it:bootstrap_GVAR.m},
{it:bootstrap_GVAR_ss.m}{p_end}
{synoptline}


{marker defects}{...}
{title:Where the sources are wrong}

{pstd}
Eight defects were found in the reference implementations while porting them.
Where reproducing the source's behaviour is useful -- because published results
depend on it -- the source's version is available behind an option and the
corrected version is the default. Two of the eight are not offered that way, and
the entries say why.

{pstd}
{bf:1. gvar.m passes the wrong residual to TCdecomp.}
{it:TCdecomp.m} documents its third argument as the reduced-form residual and
builds its multiplier from {it:H0\H(:,:,j)}, but {it:gvar.m:3106} calls it
with {it:zeta}, the structural residual. Cumulating {it:zeta} against a
reduced-form long-run multiplier leaves {it:C(1)(I - G0) sum eta_s} in the
"cycle", which is I(1). Measured on the demo, ADF over all 136 cycle series
finds 136 of 136 stationary using {it:eta} against 103 of 136 using
{it:zeta}. Default {cmd:residuals(eta)}; {cmd:residuals(zeta)} reproduces the
Toolbox.

{pstd}
{bf:2. .bgserial omits the error-correction terms.}
GVARX's Breusch-Godfrey test takes {cmd:ylagged <- x$datamat[, -(1:K)]}, every
regressor of the fitted model. For a VECMX* that includes the {it:r_i}
error-correction terms. Passing only the short-run block inflates the
statistic in proportion to {it:r_i / k_i}: empirical size of the
Edgerton-Shukur F moved from 0.108 to 0.066 on average, and from 0.248 to
0.116 for Australia, whose rank is 5 of 6.

{pstd}
{bf:3. con_forecast_GVAR.m indexes Omega beyond its own dimensions.}
It sizes {it:omega_Hbar_tilda} at {it:K x H_bar} but then indexes it with the
forecast horizon, so it only works when {it:H <= H_bar}. Truncating the update
at {it:H_bar} would be wrong, because the conditioning still moves later
horizons through the cross-horizon covariance block. Omega is built to
{it:max(H, H_bar)} here: same formula, wider index range.

{pstd}
{bf:4. hd.R feeds the trend coefficient in unscaled.}
{cmd:HDtrend_big[,nn] <- TT + Fcomp %*% HDtrend_big[,nn-1]} supplies a
constant {it:TT} every period, but the model's deterministic input at period
{it:nn} is {it:d1 * trend_nn}. The error grows linearly and is propagated by
the companion matrix. {it:hd.R} also starts its initial-condition block one
application of {it:Fcomp} short. Both are hidden by its trailing residual
slice, which is defined as data minus the sum of everything else. Corrected,
the leftover falls from 48.7 to 9.4e-13 on a series whose level is 4.8, and
the largest contributor to US output changes. {cmd:bgvar} reproduces
{it:hd.R}.


{pstd}
{bf:5. BVAR_linear.cpp writes a variance into a slot that holds a LOG variance.}
The homoskedastic branch executes {cmd:cur_sv.fill(sig2)} where {it:Sv_draw} is a
log variance everywhere else in the file: it initialises to {it:-3}, all four of
its uses are {it:exp(-0.5 Sv)}, the SV branch fills it from
{cmd:update_fast_sv}, and it is returned raw. The commented-out {cmd:log()} on
the next line was stranded by a switch to {cmd:unsafe_col}. The scaling
multiplies both sides of each equation, so a constant cancels from the likelihood
but {bf:not} against the prior precision -- and for macro data in logs
{it:sigma^2} is of order 0.01, so {it:exp(-0.01)} is essentially one and the
prior dominates far more than intended. {cmd:bgvarsv} reproduces it.

{pstd}
{bf:6. The Horseshoe's endogenous zeta update is not the same expression as the
other two.} Two of the three read
{cmd:zeta = 1/rgamma(1, 1/(1 + 1/tau))} and the endogenous one reads
{cmd:zeta_A_endo = 1.0/rgamma(1, 1 + 1/(1/tau_A_endo))}. Since
{it:1 + 1/(1/tau)} is {it:1 + tau} and is not wrapped in {it:1/(...)}, that block
draws its auxiliary with scale {it:1 + tau} where the others use
{it:tau/(1 + tau)} -- a rate of 0.99 against 101 at {it:tau = 0.01}. Two of the
three lines agree with each other and with the published augmentation; one does
not. {cmd:bgvarhs} reproduces it.

{pstd}
{bf:7. predict.R freezes the trend and starts the state a period early.}
{cmd:.get_companion} carries the deterministic block forward with
{cmd:diag(nd)}, so a trend stays at its last in-sample value and the drift
contribution is {it:a1*T} at every horizon instead of {it:a1*(T+h)}: a trended
forecast is flat in its trend component. Separately, the state is initialised at
{cmd:Xn[bigT,]}, which {cmd:.mlag} fills with {it:y_(T-1)...y_(T-p)}, so the
first companion multiply returns the {it:fitted} value at {it:T} and horizon
{it:h} is really {it:T+h-1}. {helpb gvar_bforecast:gvar bforecast} reuses the
same routine {helpb gvar_forecast:gvar forecast} uses, which starts from the
observed terminal values and advances the trend, so both are fixed by
construction. {bf:Not} offered as an option: a forecast whose first horizon is an
in-sample fit is not a defensible convention to reproduce.

{pstd}
{bf:8. Two source paths disagree about whether Bmu is a variance or an sd.}
{it:utils.R}:752 passes {cmd:sd = Bmu} to the SV prior while
{it:BVAR_linear.cpp}:252 passes {cmd:sqrt(Bmu)} as the sd, i.e. treats {it:Bmu}
as a variance. With the default {it:Bmu = 100^2} the two readings differ by a
factor of {it:10^4} in the prior variance. The C++ path is the one that runs for
BGVAR's sampler, so {it:Bmu} is a variance here. Recorded rather than corrected,
because there is nothing to correct -- the source is inconsistent with itself,
and the prior is diffuse enough either way that it changes little in practice.


{marker wedev}{...}
{title:Weak exogeneity: a known deviation}

{pstd}
{cmd:gvar wetest} implements {it:test_weakexogeneity.m} and reproduces its
formula, its restriction count and its degrees of freedom, but {bf:not} the
{it:F} values printed on the {it:exogeneity_test} sheet of the shipped full
demo. This is stated here rather than buried because it is the one published
quantity in the Toolbox's demo output that this package does not reproduce.

{pstd}
What agrees, against that sheet, for the 26-country demo:

{p2colset 9 34 36 2}{...}
{p2col:marginal-model orders (p*, q*)}25 of 26 units{p_end}
{p2col:degrees of freedom}24 of 26 units{p_end}
{p2col:5% critical values}the same 24 units, exactly{p_end}
{p2col:the 5% verdict per test}198 of 206, 96.1%{p_end}
{p2col:{it:F} values to 1e-6 relative}0 of 206{p_end}
{p2colreset}{...}

{pstd}
So the deviation is systematic in the {it:F} values while the dimensions are
right: {cmd:bra:lr} is 3.808566 here against a published 7.940544 at degrees of
freedom that agree exactly (118). The two degrees-of-freedom misses are
{cmd:chl}, which follows from its order miss and so is not independent, and
{cmd:usa}, which is off by one in the other direction and is.

{pstd}
{bf:Read the pattern, not the level.} 96.1% of the tests reach the same
conclusion at 5% as the published sheet, and the rejection rate is what
Dees, di Mauro, Pesaran and Smith (2007) interpret. Individual {it:F} values
should not be quoted against the Toolbox's.

{pstd}
{bf:Why this is not fixable from the reference.} Computing the test in Python
from the Toolbox's {it:own} published {it:beta} ({it:ECMS_CVs}) and its {it:own}
published data ({it:countrydata.xls}), with the documented formula, also gives
3.808566. Formula, data, {it:beta}, dimensions and restriction count all agree,
so the error-correction terms actually fed to the published run are not
{it:beta'Z1} for the {it:beta} that run published. That is a property of the
reference output. Note also that all 26 log-likelihoods match to 2.3e-12, which
pins the cointegrating space, and the {it:F} test is invariant to any nonsingular
transformation of the error-correction terms -- so a different {it:beta} basis
cannot be the explanation either.

{pstd}
{bf:Ruled out, so as not to be re-attempted.} The Toolbox specifies the
marginal model's foreign block separately from the country model's weakly
exogenous block ({it:fvflag_we} / {it:gvflag_we}, {it:gvar.m}:1680-1714), and its
on-screen note at that pause offers "include the foreign variable, eps, in all
country models" for DdPS(2007). That facility is available here as
{cmd:weforeign()} on {help gvar_wetest:gvar wetest}, and it defaults to off --
because it is {it:not} what the published sheet was run with. Solving
{it:degfr = T - (1 + r + ls*k + ln*ks_we)} against the sheet's own critical
values gives 24 of 26 units with {it:ks_we = ks} and none at all with
{it:ks_we = ks + 1}; {cmd:bra} settles it alone, at a published 118 against 117
with the extra column. Also ruled out: the star variables (2.7e-15), the weight
matrix (1.7e-16), the {it:F} formula, and the critical-value function.

{pstd}
{it:_test62.do} keeps every number above under test, so the two move together.


{marker nonchecks}{...}
{title:Checks that look convincing and are not}

{pstd}
Recorded because each cost real time during development.

{phang}
{bf:A decomposition whose last slice is defined residually cannot be}
{bf:validated by checking that it sums to the data.} That identity holds by
construction however wrong the other blocks are. Check the size of the
residual slice.

{phang}
{bf:A persistence profile starts at one for any covariance matrix,} because
the same Sigma sits in its numerator and denominator at {it:h} = 0. It cannot
detect a wrong covariance argument. An orthogonalised FEVD summing to one
can.

{phang}
{bf:Comparing the size of two candidate cycles cannot separate them.} In
{it:TCdecomp} the cycle is the OLS residual on {it:[1, trend]}, hence
orthogonal to the trend by construction under either residual. Only a
stationarity test discriminates.

{phang}
{bf:A discrepancy that grows with the horizon cannot come from an}
{bf:initialisation error.} Read the shape of the error before forming a
hypothesis about its cause.

{phang}
{bf:svmat defaults to float.} Validating a Mata computation against Stata's
{cmd:regress} by round-tripping through {cmd:svmat} truncates to seven
significant digits and looks like a real discrepancy. Use {cmd:svmat double}.

{phang}
{bf:A check that reads the producer's output cannot detect that the consumer}
{bf:never reads it.} {cmd:gvar bayes} sampled correctly and stored its draws, and
41 checks confirmed the sampler by reading those draws directly -- while nothing
copied them into the slots {helpb gvar_solve:gvar solve} reads, so every impulse
response after it was the ML model. At least one check per feature has to travel
the documented user-facing path.

{phang}
{bf:Every property of Sigma except Sigma.} The country covariance was built as
{it:inv(L) D inv(L)'} where the source says {it:L D L'} -- a 31.5% error, live in
three commands. Checks existed for its shape, its symmetry, the ranges of what
depended on it, and how it responded to the prior. All four are {bf:invariant to
inverting L}. A quantity needs at least one check against an {bf:independent
construction of the same quantity} -- the same number arrived at another way, not
a property it happens to have.

{phang}
{bf:A suite that samples only the easy region certifies nothing about the hard}
{bf:one.} The GIG sampler passed 17 of 17 while broken for {it:omega} below about
{it:1e-4}, because the smallest {it:omega} any check used was 0.63 -- and the
Normal-Gamma prior routinely visits {it:1e-3} and below. The range a test covers
is part of what it asserts, and nothing in a green result says what that range
was.

{phang}
{bf:In Stata and Mata a missing value compares GREATER than any number,} so
{it:missing > x} is true and a comparison involving a missing silently {bf:passes}.
This produced a green check whose reported quantity printed as {cmd:.} -- caught
only because the check printed the number as well as the verdict. Note the
asymmetry: {it:missing < x} is false and fails correctly, so half of all
comparisons are safe and the pattern "we use comparisons everywhere and they
work" holds right up to the one that does not. Guard {it:>} and {it:>=} with
{it:x < .}, and never initialise an extremum to {cmd:-.}, which {bf:is} missing.

{phang}
{bf:rc == 0 means a command ran, not that its answer means anything.}
{cmd:irf}, {cmd:fevd}, {cmd:hd} and {cmd:forecast} all returned 0 on a model
{helpb gvar_solve:gvar solve} had just declared unstable with six roots above
unity. Usability needs its own assertion.

{phang}
{bf:Narrowing a false claim until it passes is fitting the test to the output.}
An assertion that pD falls as the prior tightens failed; restricting it to a
"sane" range failed again; the claim was simply false -- pD is
concentration times curvature and therefore U-shaped. The third version asserted
something true instead. Two related habits: when a fix lands, grep for what the
{bf:documentation} still claims -- the Sigma correction left the wrong formula in
four places including the command's own printed output -- and when a class of
defect appears, grep the package for it rather than fixing the instance, which is
how one new {cmd:display as error} inside a summary block turned up sixteen
others.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
