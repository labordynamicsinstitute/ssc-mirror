{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar references" "help gvar_references"}{...}
{vieweralsosee "gvar estimate" "help gvar_estimate"}{...}
{vieweralsosee "gvar solve" "help gvar_solve"}{...}
{vieweralsosee "gvar irf" "help gvar_irf"}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{vieweralsosee "gvar bforecast" "help gvar_bforecast"}{...}
{vieweralsosee "gvar bdic" "help gvar_bdic"}{...}
{viewerjumpto "Syntax" "gvar_bayes##syntax"}{...}
{viewerjumpto "Description" "gvar_bayes##description"}{...}
{viewerjumpto "Options" "gvar_bayes##options"}{...}
{viewerjumpto "The sampler" "gvar_bayes##sampler"}{...}
{viewerjumpto "The priors" "gvar_bayes##priors"}{...}
{viewerjumpto "Remarks" "gvar_bayes##remarks"}{...}
{viewerjumpto "Examples" "gvar_bayes##examples"}{...}
{viewerjumpto "Stored results" "gvar_bayes##results"}{...}
{title:Title}

{phang}
{bf:gvar bayes} {hline 2} Bayesian estimation of the country models


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar bayes} [{cmd:,} {it:options}]

{synoptset 34 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Prior}
{synopt:{opt prior(string)}}{cmd:mn} (default), {cmd:ssvs}, {cmd:ng} or {cmd:hs}.{p_end}

{syntab:Chain}
{synopt:{opt draws(#)}}retained sweeps before thinning. Default 1000.{p_end}
{synopt:{opt burn:in(#)}}discarded sweeps. Default 1000.{p_end}
{synopt:{opt thin(#)}}keep one sweep in {it:#}. Default 1.{p_end}
{synopt:{opt seed(string)}}passed to {helpb set seed}.{p_end}

{syntab:Minnesota, {cmd:prior(mn)}}
{synopt:{opt lambda1(#)}}overall tightness. Default 0.1.{p_end}
{synopt:{opt lambda2(#)}}cross-variable factor. Default 0.5.{p_end}
{synopt:{opt lambda3(#)}}weakly exogenous factor. Default 0.5.{p_end}
{synopt:{opt lambda4(#)}}deterministic factor. Default 100.{p_end}
{synopt:{opt prm:ean(#)}}prior mean on the first own lag. Default 1.{p_end}

{syntab:Spike and slab, {cmd:prior(ssvs)}}
{synopt:{opt tau0(#)}}spike sd, in OLS standard errors. Default 0.1.{p_end}
{synopt:{opt tau1(#)}}slab sd, in OLS standard errors. Default 10.{p_end}
{synopt:{opt pi(#)}}prior weight on the SPIKE. Default 0.5.{p_end}
{synopt:{opt kappa0(#)}}spike sd for the covariance factor. Default 0.1.{p_end}
{synopt:{opt kappa1(#)}}slab sd for the covariance factor. Default 10.{p_end}
{synopt:{opt qij(#)}}prior weight on the spike in {it:L}. Default 0.5.{p_end}

{syntab:Normal-Gamma, {cmd:prior(ng)}}
{synopt:{opt tauth:eta(#)}}shape of the local variances. Default {it:1/ln(M)} per unit.{p_end}
{synopt:{opt dlam:bda(#)}}gamma shape on the global variances. Default 0.01.{p_end}
{synopt:{opt elam:bda(#)}}gamma rate on the global variances. Default 0.01.{p_end}
{synopt:{opt nosampletau}}hold {it:tau} fixed instead of sampling it.{p_end}

{syntab:Horseshoe, {cmd:prior(hs)}}
{synopt:{opt bgvarhs}}reproduce the source's endogenous {it:zeta} update. See {it:Remarks}.{p_end}

{syntab:Variances and reporting}
{synopt:{opt sv}}stochastic volatility instead of a constant variance.{p_end}
{synopt:{opt a1(#)}}inverse-gamma shape on sigma^2. Default 0.01. Ignored under {opt sv}.{p_end}
{synopt:{opt b1(#)}}inverse-gamma rate on sigma^2. Default 0.01. Ignored under {opt sv}.{p_end}
{synopt:{opt trim(#)}}discard draws whose largest companion eigenvalue modulus is at or above {it:#}. Default 1.05. See {it:Remarks}.{p_end}
{synopt:{opt noeigen:trim}}keep every draw. BGVAR's {cmd:eigen=FALSE}.{p_end}
{synopt:{opt bgvar:sv}}reproduce BGVAR's homoskedastic branch. See {help gvar_methods}.{p_end}
{synopt:{opt nosum:mary}}suppress the report.{p_end}
{synoptline}

{pstd}
The Horseshoe takes no tuning hyperparameters. That is the point of it: the
half-Cauchy scales are learnt rather than set.

{pstd}
{cmd:gvar foreign} must have run first. {cmd:gvar bayes} replaces
{helpb gvar_estimate:gvar estimate}: it is an alternative way to obtain the
country-model coefficients, after which
{helpb gvar_solve:gvar solve} and the whole dynamic-analysis group proceed
unchanged.


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar bayes} estimates every country VARX* by Markov chain Monte Carlo
rather than by maximum likelihood, and stores the retained draws. It follows
{it:BVAR_linear.cpp} in the {bf:BGVAR} package.

{pstd}
Each unit is sampled independently, exactly as BGVAR does. The model is not
stacked until {helpb gvar_solve:gvar solve} runs, and the eigenvalue trim is
a {bf:global} rule applied after stacking, because a country model can be
perfectly stable while the stacked system is not, and the reverse.


{marker options}{...}
{title:Options}

{dlgtab:Prior}

{phang}
{opt prior(string)} selects the prior. {cmd:mn} is the Minnesota prior of
{it:helper.cpp get_Vminnesota}; {cmd:ssvs} is stochastic search variable
selection; {cmd:ng} is the Normal-Gamma global-local shrinkage prior; and
{cmd:hs} is the Horseshoe. All four of BGVAR's priors are available. An
unrecognised string is refused by name rather than silently falling back to
the default.

{dlgtab:Chain}

{phang}
{opt draws(#)}, {opt burnin(#)} and {opt thin(#)} control the chain.
{it:draws} counts sweeps AFTER burn-in and BEFORE thinning, so
{cmd:draws(1000) thin(2)} keeps 500. A {it:draws}/{it:thin} below one is
refused rather than quietly keeping nothing.

{phang}
{opt seed(string)} is passed straight to {helpb set seed}. Set it. An MCMC
result that cannot be reproduced is not a result, and
{cmd:gvar bayes} makes no attempt to guess a seed for you.

{dlgtab:Normal-Gamma}

{phang}
{opt tautheta(#)} is the shape of the local variances. Left empty it takes
BGVAR's per-entity default {it:1/ln(M)}, where {it:M} is that unit's number
of endogenous variables -- so it genuinely differs across units and cannot be
reported as one number.

{phang}
The local variances are drawn from a generalised inverse Gaussian with shape
{it:tautheta - 0.5}. A {bf:negative} shape is perfectly proper -- it is the
reciprocal branch of the GIG -- and {it:1/ln(M)} itself falls below 0.5 for
any unit with eight or more endogenous variables, so values below 0.5 are
allowed. Only {cmd:tautheta(0.5)} exactly is refused: that puts the shape at
zero, where the sampler has no normalisable proposal. BGVAR's default rule
never produces it, since {it:1/ln(M) = 0.5} would need {it:M = e^2}.

{phang}
{opt nosampletau} holds {it:tau} at {opt tautheta()} for the whole chain.
BGVAR {bf:samples} it by default, by random-walk Metropolis on {it:log tau}
with the proposal standard deviation adapted over the first half of burn-in,
so {cmd:nosampletau} is the departure from the source, not the default.

{dlgtab:Variances}

{phang}
{opt bgvarsv} reproduces BGVAR's homoskedastic branch, which writes a
variance into a slot every other line of the file treats as a {bf:log}
variance. See {help gvar_methods} and the remark below.


{marker sampler}{...}
{title:The sampler}

{pstd}
Two loops per sweep, per unit:

{p 8 12 2}
1. the coefficients, equation by equation, as a GLS draw conditioned on
{bf:every} other equation through {it:L^-1};{p_end}
{p 8 12 2}
2. the free elements of {it:L}, by regressing each equation's residual on the
earlier ones,{p_end}

{pstd}
so {it:Sigma = L D L'} comes out of one sweep. {it:L} is unit lower triangular in
every draw: its diagonal is never sampled and its upper triangle never touched.

{pstd}
{bf:That direction is not a matter of taste.} {it:BVAR_linear.cpp}:412 forms the
structural residuals as {it:(Y - X A) L^-1'}, and :780 takes those as the series
whose variance {bf:is} {it:D}. So {it:D = L^-1 Sigma L^-1'} and hence
{it:Sigma = L D L'}. {it:utils.R}:381 writes it out, and :809 confirms the stored
factor is {it:L} rather than its inverse. It is also what makes the sampler's own
whitening work: the coefficient draw multiplies by {it:L^-1}, which only yields
independent components if {it:L^-1 Sigma L^-1'} is diagonal.

{pstd}
{bf:Note} that {it:BVAR_linear.cpp} also contains a joint version at line 413
which draws the coefficients and {it:L} together, conditioning only on the
{it:preceding} equations. It sits inside a comment block and is not what runs.
The two are different conditional distributions, both produce plausible
posteriors, and no convergence diagnostic distinguishes them; only reading the
file does.


{marker priors}{...}
{title:The priors}

{pstd}
All three priors are a rule for filling the prior variance matrix {it:V},
not three different samplers. That is worth knowing before reading the
options: they share step 1 and step 2 above entirely.

{pstd}
{bf:Minnesota} sets {it:V} once, deterministically:

{p 8 8 2}{it:own lag} {space 8}{it:(l1/l)^2}{p_end}
{p 8 8 2}{it:cross lag} {space 6}{it:(l1 l2/l)^2 s_i/s_j}{p_end}
{p 8 8 2}{it:weakly exog} {space 4}{it:(l1 l3/(l+1))^2 s_i/s_j*}{p_end}
{p 8 8 2}{it:deterministic} {space 2}{it:l4 s_i}{p_end}

{pstd}
The weakly exogenous block runs from lag {bf:zero} -- the contemporaneous
star variables are regressors -- which is why its denominator is {it:(l+1)}
and not {it:l}.

{pstd}
{bf:SSVS} refills {it:V} every sweep from a spike-and-slab, and reports a
posterior inclusion probability per coefficient. {opt pi()} is the prior
weight on the {bf:spike}, so raising it keeps fewer variables.

{pstd}
{bf:Normal-Gamma} refills {it:V} from a hierarchy with one global variance per
lag and one local variance per coefficient:

{p 8 8 2}{it:theta_ij ~ G(tau, tau lambda^2 / 2)} {space 3}local, drawn as a GIG{p_end}
{p 8 8 2}{it:lambda^2 ~ G(d + tau k, e + tau sum(theta) prod / 2)} {space 1}global{p_end}

{pstd}
{it:lambda} is a running {bf:product} over lags, so shrinkage compounds with
lag length: lag 3 is shrunk by {it:lambda1 lambda2 lambda3}, not by
{it:lambda3} alone.

{pstd}
The endogenous lags and the weakly exogenous block have {bf:separate}
hierarchies -- columns 0 and 1 of {it:lambda2_A} in the source. Sharing one
would tie the shrinkage on a unit's own lags to the shrinkage on its
trade-weighted foreign variables, which is exactly what the two columns exist
to avoid.

{pstd}
{bf:Horseshoe} is also global-local, but writes its half-Cauchy tails as a
pair of inverse-gamma steps:

{p 8 8 2}{it:lambda_j | nu_j, tau ~ IG(1, 1/nu_j + a_j^2/(2 tau))}{p_end}
{p 8 8 2}{it:nu_j} {space 5}{it:| lambda_j  ~ IG(1, 1 + 1/lambda_j)}{p_end}
{p 8 8 2}{it:tau} {space 6}{it:| zeta, a   ~ IG((n+1)/2, 1/zeta + sum(a^2/lambda)/2)}{p_end}
{p 8 8 2}{it:zeta} {space 5}{it:| tau       ~ IG(1, 1 + 1/tau)}{p_end}

{pstd}
so it needs no GIG draw at all and takes no tuning hyperparameters. It has
{bf:three} hierarchies where Normal-Gamma has two: the endogenous lags, the
weakly exogenous block, and the free elements of {it:L} each carry their own
{it:tau} and {it:zeta}. Normal-Gamma handles {it:L} through a separate
{it:lambda2_L} instead, so the layout does not carry over between them.

{pstd}
Neither {cmd:ng} nor {cmd:hs} touches the deterministic rows. The constant and
any trend keep their flat prior variance, exactly as in the source -- the
hierarchy is not asked to shrink an intercept.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Set a seed, and report it.} Everything else in this help page is
secondary to that.

{pstd}
{bf:On a large system in levels, the default prior mean gives an unstable GVAR.}
{opt prmean()} sets the prior mean on each variable's own first lag, and its
default of 1 is a {bf:random-walk} prior -- which is the standard choice for
macro data in levels, and which pushes every one of those roots towards the unit
circle. Stack 26 country models and the assembled system tips over. Measured on
the shipped 26-unit demo with

        {cmd:. gvar bayes, prior(mn) prmean(}{it:p}{cmd:) lambda1(}{it:l}{cmd:) noeigentrim draws(60) burnin(60) seed(20260812)}
        {cmd:. gvar solve}

{p 8 8 2}{it:prmean}{space 4}{it:lambda1}{space 4}{it:largest non-unit |eig|}{space 4}{it:explosive}{p_end}
{p 8 8 2}{space 5}1{space 8}0.10{space 12}1.02737{space 14}3{p_end}
{p 8 8 2}{space 5}0{space 8}0.10{space 12}0.99856{space 14}0{p_end}
{p 8 8 2}{space 5}0{space 8}0.05{space 12}0.99422{space 14}0{p_end}
{p 8 8 2}{space 5}0{space 8}0.02{space 12}0.71056{space 14}0{p_end}
{p 8 8 2}{space 5}0{space 8}0.01{space 12}0.59987{space 14}0{p_end}

{pstd}
{bf:Why "non-unit", and what the plain maximum would tell you.} Two of the 272
companion roots sit {bf:on} the unit circle at every one of those
configurations, so the plain {it:max |eig|} is exactly 1.00000 for all four
{opt prmean(0)} rows and cannot distinguish them. Those two are the dominant
block's: it is a three-variable VECM of cointegrating rank 1, so it carries
3 - 1 = 2 unit roots, and {cmd:gvar bayes} does not touch it -- the sampler fits
the {it:country} models as a VARX in levels, which is also why the 69 unit roots
of the ML fit (K minus the sum of the ranks) do not survive into these rows. The
column above therefore reports the largest modulus more than 1e-8 away from 1.
Roots {bf:above} 1 are kept, which is why the {opt prmean(1)} row reads 1.02737
in both senses; a filter meant to remove unit roots must never hide an explosive
one. {it:explosive} counts roots beyond 1 + 1e-8.

{pstd}
So {opt prmean(0)} -- shrinking towards white noise rather than towards a random
walk -- is what makes this model usable, and {opt lambda1(0.1)} with it lands at
0.998: stable without crushing the dynamics, which {it:lambda1} of 0.02 and 0.01
plainly do. This is why every example above passes {opt prmean(0)}. The
{opt prmean(1)} row is genuinely explosive -- three roots outside the circle, not
a numerical artefact of roots sitting on it.

{pstd}
{bf:The default trim discards every draw of a large model in levels, and you
will meet this on the shipped demo.} {opt trim()} keeps a draw only if the
largest companion eigenvalue modulus of the {it:whole stacked GVAR} is below
the cutoff. For the 26-unit demo -- 134 endogenous variables, 268 companion
eigenvalues -- those moduli run about 1.09 to 1.31, so BGVAR's 1.05 default
leaves nothing and the command stops.

{pstd}
That is not a sign of a bad fit. A GVAR estimated in {bf:levels} has many roots
close to unity, and the {it:maximum} of several hundred of them sits a little
above one in almost every draw. BGVAR's 1.05 is calibrated on much smaller
models, and BGVAR stops in the same situation for the same reason -- so the
behaviour here is the source's, deliberately.

{pstd}
When it happens the command prints the minimum, median and maximum of the
moduli. Read them, then either raise {opt trim()} past them or pass
{opt noeigentrim} to keep every draw. Do {bf:not} just lengthen the chain: that
changes how many draws there are, not where the moduli sit.

{pstd}
{bf:Trimming happens before the posterior mean is taken}, so the mean is over
surviving draws only. And it is a {bf:global} rule applied after stacking,
because a country model can be perfectly stable while the assembled system is
not, and the reverse -- trimming unit by unit would throw away draws the global
model would have kept.

{pstd}
{bf:What gvar bayes writes, and what it does not.} It fills the reduced-form
country-model slots -- the lag coefficients, the weakly exogenous coefficients,
the intercept, the trend, and the residual covariance -- so
{helpb gvar_solve:gvar solve}, {helpb gvar_irf:gvar irf},
{helpb gvar_fevd:gvar fevd}, {helpb gvar_hd:gvar hd} and
{helpb gvar_forecast:gvar forecast} all work from it unchanged. It does
{bf:not} produce cointegrating vectors, because a VARX in levels imposes no
rank. {helpb gvar_pp:gvar pp} and {helpb gvar_overid:gvar overid} are defined on
those vectors and refuse rather than use whatever an earlier
{helpb gvar_estimate:gvar estimate} left behind. {helpb gvar_solve:gvar solve}
likewise skips its {it:K - sum(r)} unit-root count, which has nothing to compare
against here.

{pstd}
{bf:The homoskedastic log-variance defect.} BGVAR's homoskedastic branch
executes {cmd:cur_sv.fill(sig2)} into a slot that is a log variance
everywhere else in the file: it initialises to {it:-3}, all four of its uses
are {it:exp(-0.5 Sv)}, the stochastic-volatility branch fills it from
{it:update_fast_sv}, and it is returned raw. The consequence is that the data
are weighted by {it:exp(-sigma^2)} rather than {it:1/sigma^2}. The scaling
multiplies both sides of each equation, so a constant cancels from the
likelihood but {bf:not} against the prior precision -- and for macro data in
logs {it:sigma^2} is of order 0.01, so {it:exp(-0.01)} is essentially one and
the prior dominates far more than intended. This package writes
{it:log sigma^2} by default; {opt bgvarsv} reproduces the source exactly, the
same way {helpb gvar_tcdecomp:gvar tcdecomp} handles the zeta/eta swap.

{pstd}
{bf:The GIG sampler behind prior(ng) is not transcribed from BGVAR.}
{it:do_rgig1.cpp} handles only the degenerate ends and delegates the general
case to the {bf:GIGrvg} package, a dependency rather than part of the source
tree. So it was written from the algorithm and gated on its own test against
the closed-form GIG moments, which Stata cannot evaluate directly -- there is
no {cmd:besselk()} -- so {it:K_nu(x)} is computed from its integral
representation and that quadrature is checked first against the exact
half-integer closed form.

{pstd}
{bf:Stochastic volatility.} {opt sv} replaces the constant variance with

{p 8 8 2}{it:log(eps_t^2 + 1e-40) = h_t + log(chi^2_1)}{p_end}
{p 8 8 2}{it:h_t = mu + phi (h_{t-1} - mu) + sigma eta_t}{p_end}

{pstd}
using the 10-component normal mixture of Omori, Chib, Shephard and Nakajima
(2007) for {it:log(chi^2_1)}, with BGVAR's priors: {it:mu ~ N(0, 100^2)},
{it:phi} a stretched {it:Beta(25, 1.5)} on {it:(-1,1)}, and
{it:sigma^2 ~ Gamma(1/2, 1/2)}. The last two are {bf:not} conjugate, so both get
an independence Metropolis step -- which is what stochvol's
{cmd:ProposalSigma2::INDEPENDENCE} amounts to.

{pstd}
{bf:It is not bit-comparable to stochvol, and that is deliberate.} BGVAR calls
{cmd:stochvol::update_fast_sv}, the Kastner and Fruehwirth-Schnatter (2014)
sampler with ancillarity-sufficiency interweaving. {cmd:stochvol} is a
dependency, not part of the BGVAR source, so the algorithm cannot be
transcribed -- the same situation as {cmd:GIGrvg} for {cmd:prior(ng)} and
{cmd:coda} for {helpb gvar_bconv:gvar bconv}. What is reproduced is the
{bf:target}: the same model, the same priors, the same mixture. ASIS is an
efficiency device -- it lowers autocorrelation, it does not change the posterior
-- so this sampler converges to the same distribution and may mix more slowly.
Run {helpb gvar_bconv:gvar bconv} and look.

{pstd}
Measured on simulated data with a known volatility path, T = 500, true
{it:(mu, phi, sigma) = (-1.00, 0.95, 0.25)}: the posterior mean path correlates
0.75 with the truth, and the parameters come back at
{it:(-1.27, 0.86, 0.37)}. {it:sigma} is the hardest of the three and carries real
posterior uncertainty at that sample size. {it:phi} landing below 0.95 is the
{it:Beta(25, 1.5)} prior pulling towards its own mean of about 0.887, not an
error -- if you want a less opinionated {it:phi}, that prior is where to look.

{pstd}
{bf:What the stacked GVAR uses under sv.} {it:Sigma_t} varies with {it:t}, so one
covariance has to be chosen for the stacking. The source takes the
{bf:elementwise median over time} ({it:utils.R}:381 and :387, where the collapsed
margin is time -- not the mean, and not {it:Sigma} at one period). That is
reproduced. Note an elementwise median of positive-definite matrices need not
itself be positive definite; the package checks rather than assumes, so a
Cholesky-based decomposition may refuse and ask for {opt shrink}.

{pstd}
{opt sv} and {opt bgvarsv} are refused together. {opt bgvarsv} reproduces
BGVAR's {bf:homoskedastic} branch and source defect #8, so it has nothing to say
about a stochastic-volatility fit.

{pstd}
The path is available from Mata as {cmd:gvar_getbSV(}{it:i}{cmd:)}, a
{it:T*M x draws} matrix of log variances; {cmd:colshape(v, T)'} rebuilds one
draw's {it:T x M} surface. {cmd:gvar_getbS()} stays the per-equation summary.

{pstd}
{bf:The Horseshoe's three zeta updates are not the same expression in the
source.} Two of them read

{p 8 8 2}{cmd:zeta = 1/R::rgamma(1, 1/(1 + 1 / tau));}{p_end}

{pstd}
and the endogenous one reads

{p 8 8 2}{cmd:zeta_A_endo = 1.0/R::rgamma(1, 1 + 1/(1 / tau_A_endo));}{p_end}

{pstd}
{it:1 + 1/(1/tau)} is {it:1 + tau}, and it is not wrapped in {it:1/(...)}, so
that one block draws its auxiliary with scale {it:1 + tau} where the other two
use {it:1/(1 + 1/tau) = tau/(1 + tau)}. At {it:tau = 0.01} that is a rate of
0.99 against 101. Two of the three lines agree with each other and with the
published augmentation; one does not. This package uses the consistent form by
default and {opt bgvarhs} reproduces the source, the same arrangement as
{opt bgvarsv} for the log-variance defect.

{pstd}
{bf:Integer division in the Horseshoe's global shape.} {it:(n+1)/2},
{it:(nstar+1)/2} and {it:(v+1)/2} are integer divisions in the source, because
{it:n}, {it:nstar} and {it:v} are all declared {cmd:int}. With {it:n = 50} the
shape is 25, not 25.5. Reproduced rather than silently promoted: it is what
runs, and the difference is too small to justify diverging over.


{marker examples}{...}
{title:Examples}

{pstd}
Setup, using the shipped 26-unit demo (see {help gvar_datasets}):{p_end}
{phang2}{cmd:. use gvar_demo26, clear}{p_end}
{phang2}{cmd:. gvar setup y Dp eq ep r lr, unit(country) time(quarter) global(poil pmat pmetal) gendog(poil=usa pmat=usa pmetal=usa) spec(gvar_demospec)}{p_end}
{phang2}{cmd:. gvar weights using gvar_flows, flow(trade) source(partner) destination(home) year(year) years(2009 2011) type(1) map(gvar_demoagg)}{p_end}
{phang2}{cmd:. gvar foreign}{p_end}

{pstd}
Minnesota prior, then solve and trace an impulse response as usual. Note
{opt prmean(0)} and {opt noeigentrim} -- see {it:Remarks} for why the defaults
do not work on this particular model:{p_end}
{phang2}{cmd:. gvar bayes, prior(mn) prmean(0) noeigentrim draws(2000) burnin(2000) seed(20260811)}{p_end}
{phang2}{cmd:. gvar solve}{p_end}
{phang2}{cmd:. gvar irf, shock(usa:r) step(24) graph}{p_end}

{pstd}
Spike and slab, with a stronger prior weight on the spike:{p_end}
{phang2}{cmd:. gvar bayes, prior(ssvs) pi(0.8) prmean(0) noeigentrim draws(2000) burnin(2000) seed(20260811)}{p_end}

{pstd}
Normal-Gamma, letting {it:tautheta} take its per-unit default and be
sampled:{p_end}
{phang2}{cmd:. gvar bayes, prior(ng) prmean(0) noeigentrim draws(2000) burnin(2000) seed(20260811)}{p_end}

{pstd}
The same, with the shape pinned and the hierarchy made tighter:{p_end}
{phang2}{cmd:. gvar bayes, prior(ng) tautheta(0.7) nosampletau prmean(0) noeigentrim draws(2000) burnin(2000) seed(20260811)}{p_end}

{pstd}
With stochastic volatility.  Check the chains afterwards: the sampler here is not
the interweaved one, so mixing may be slower than stochvol's:{p_end}
{phang2}{cmd:. gvar bayes, prior(mn) prmean(0) sv noeigentrim draws(2000) burnin(2000) seed(20260811)}{p_end}
{phang2}{cmd:. gvar bconv}{p_end}

{pstd}
Horseshoe, which takes no tuning hyperparameters at all:{p_end}
{phang2}{cmd:. gvar bayes, prior(hs) prmean(0) noeigentrim draws(2000) burnin(2000) seed(20260811)}{p_end}

{pstd}
Horseshoe reproducing the source's endogenous {it:zeta} update, for
comparison:{p_end}
{phang2}{cmd:. gvar bayes, prior(hs) bgvarhs prmean(0) noeigentrim draws(2000) burnin(2000) seed(20260811)}{p_end}

{pstd}
A historical decomposition needs a Cholesky factor of {it:Sigma_zeta}, which is
singular on this data under {bf:either} estimator -- 136 variables, 134 quarters
-- so {opt shrink} is required. That is not a Bayesian matter; the ML fit needs
it too:{p_end}
{phang2}{cmd:. gvar hd, variables(usa:y) shrink graph}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar bayes} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(draws)}}retained draws per unit, after thinning{p_end}
{synopt:{cmd:r(burnin)}}discarded sweeps{p_end}
{synopt:{cmd:r(thin)}}the thinning interval{p_end}
{synopt:{cmd:r(trim)}}the eigenvalue trim {cmd:gvar solve} will apply{p_end}
{synopt:{cmd:r(prior)}}the prior, as typed{p_end}
{synopt:{cmd:r(priorno)}}1 Minnesota, 2 SSVS, 3 Normal-Gamma, 4 Horseshoe{p_end}
{synoptline}

{pstd}
The draws themselves are held in the model and reached from Mata:
{cmd:gvar_getbA(}{it:i}{cmd:)} the coefficients,
{cmd:gvar_getbL(}{it:i}{cmd:)} the covariance factor,
{cmd:gvar_getbS(}{it:i}{cmd:)} the residual variances, and
{cmd:gvar_getbG(}{it:i}{cmd:)} the prior-specific block -- inclusion
indicators under {cmd:prior(ssvs)}, local prior variances under
{cmd:prior(ng)} and {cmd:prior(hs)}, and unused under {cmd:prior(mn)}.
{cmd:gvar_getbprior()} records which.


{marker source}{...}
{title:Source}

{pstd}
BGVAR {it:src/BVAR_linear.cpp}, {it:src/helper.cpp} {cmd:get_Vminnesota},
{it:src/do_rgig1.cpp}, {it:R/utils.R}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
