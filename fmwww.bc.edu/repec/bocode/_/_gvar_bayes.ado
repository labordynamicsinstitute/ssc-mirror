*! _gvar_bayes 1.0.1  21aug2026
*! gvar bayes -- Bayesian GVAR, one shrinkage prior per country model.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Inventory section 12.  BGVAR src/BVAR_linear.cpp and src/helper.cpp.
*
* Each country model is a VARX*(p,q) sampled by Gibbs.  The sampler is two
* loops per sweep, following BVAR_linear.cpp lines 342-412:
*
*   1  the coefficients, equation by equation, as a GLS draw conditioned on
*      every OTHER equation through L^{-1}
*   2  the free elements of L, one row at a time, by regressing this
*      equation's residual on the earlier equations' residuals
*
* so Sigma = L^{-1} D L^{-1}' comes out of the same sweep.  The file also
* contains a joint version at line 413 that samples the coefficients and L
* together -- it is inside a comment block and is NOT what runs.
*
* The prior enters only as a diagonal precision, which is why the four priors
* differ in how they fill V and not in how they sample.  This release
* implements the Minnesota prior; SSVS, Normal-Gamma and Horseshoe follow.
*
* Step -> source map
*   equation-by-equation GLS draw     <- BVAR_linear.cpp 342-376
*   free elements of L                <- BVAR_linear.cpp 378-410
*   Minnesota prior variance          <- helper.cpp get_Vminnesota
*   AR(p) sigma for the prior scale   <- helper.cpp get_ar
*   burn-in, thinning                 <- BVAR_linear.cpp 806-811
*   eigenvalue trim, GLOBAL not local <- BGVAR.R .gvar.stacking.wrapper

program define _gvar_bayes, rclass
    version 14.0

    syntax [,                                   ///
        PRIOR(string)                           ///
        DRAWS(integer 1000)                     ///
        BURNin(integer 1000)                    ///
        THIN(integer 1)                         ///
        LAMBDA1(real 0.1)                       ///
        LAMBDA2(real 0.5)                       ///
        LAMBDA3(real 0.5)                       ///
        LAMBDA4(real 100)                       ///
        PRMean(real 1)                          ///
        A1(real 0.01)                           ///
        B1(real 0.01)                           ///
        TRIM(real 1.05)                         ///
        TAU0(real 0.1)                          ///
        TAU1(real 10)                           ///
        PI(real 0.5)                            ///
        KAPPA0(real 0.1)                        ///
        KAPPA1(real 10)                         ///
        QIJ(real 0.5)                           ///
        TAUTHeta(string)                        ///
        DLAMbda(real 0.01)                      ///
        ELAMbda(real 0.01)                      ///
        NOSAMPLETAU                             ///
        BGVARsv                                 ///
        BGVARHS                                 ///
        NOEIGENtrim                             ///
        SV                                      ///
        SEED(string)                            ///
        noSUMmary                               ///
    ]

    _gvar_require foreign

    if ("`prior'" == "") local prior mn
    local prior = lower("`prior'")
    local pnum 0
    if (inlist("`prior'", "mn", "minnesota"))       local pnum 1
    else if (inlist("`prior'", "ssvs"))             local pnum 2
    else if (inlist("`prior'", "ng", "normalgamma"))  local pnum 3
    else if (inlist("`prior'", "hs", "horseshoe"))    local pnum 4
    if (`pnum' == 0) {
        di as err "prior(`prior') is not one this command knows."
        di as err "Available: {bf:mn} (Minnesota), {bf:ssvs} (spike and slab),"
        di as err "{bf:ng} (Normal-Gamma) and {bf:hs} (Horseshoe)."
        exit 198
    }

    * tautheta() left empty means BGVAR's per-entity default, 1/ln(M), which
    * utils.R:298 substitutes for every entity with more than one endogenous
    * variable.  It cannot be resolved here because M varies by unit, so a
    * missing value is passed down and gvar_brun fills it in per unit.
    if ("`tautheta'" == "") local tautheta .
    else {
        capture confirm number `tautheta'
        if (_rc) {
            di as err "tautheta() must be a number"
            exit 198
        }
    }
    if (`pnum' == 3) {
        * The local variances are GIG draws with shape tau - 0.5.  A NEGATIVE
        * shape is perfectly proper -- it is the reciprocal branch, and BGVAR's
        * own default 1/ln(M) goes below 0.5 for any entity with 8 or more
        * endogenous variables -- so tautheta() below 0.5 is allowed.  Only
        * tautheta() == 0.5 exactly is refused: that puts the GIG shape at zero,
        * where the Gamma-proposal sampler has no normalisable proposal.  BGVAR's
        * default rule never produces it (1/ln(M) = 0.5 needs M = e^2).
        if (`tautheta' < .) {
            if (`tautheta' <= 0) {
                di as err "tautheta() must be positive"
                exit 198
            }
            if (abs(`tautheta' - 0.5) < 1e-8) {
                di as err "tautheta() may not be 0.5: the local variances are"
                di as err "GIG draws with shape tautheta - 0.5, and a shape of"
                di as err "exactly zero leaves the sampler no normalisable"
                di as err "proposal.  Values above and below 0.5 are both fine."
                exit 198
            }
        }
        if (`dlambda' <= 0 | `elambda' <= 0) {
            di as err "dlambda() and elambda() are gamma hyperparameters and"
            di as err "must be positive"
            exit 198
        }
    }
    if (`pnum' == 2) {
        if (`tau0' <= 0 | `tau1' <= 0 | `tau1' <= `tau0') {
            di as err "tau0() and tau1() must be positive with tau1 > tau0:"
            di as err "tau0 scales the spike and tau1 the slab, both in units"
            di as err "of each coefficient's OLS standard error."
            exit 198
        }
        if (`pi' <= 0 | `pi' >= 1 | `qij' <= 0 | `qij' >= 1) {
            di as err "pi() and qij() are prior probabilities and must lie"
            di as err "strictly between 0 and 1"
            exit 198
        }
    }
    if (`draws' < 1 | `burnin' < 0 | `thin' < 1) {
        di as err "draws() >= 1, burnin() >= 0 and thin() >= 1"
        exit 198
    }
    if (`draws' / `thin' < 1) {
        di as err "draws()/thin() is less than one: nothing would be kept"
        exit 198
    }
    if ("`seed'" != "") set seed `seed'

    mata: st_local("N", strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))

    local nkeep = floor(`draws' / `thin')
    if ("`summary'" != "nosummary") {
        di as text "  sampling " as result `N' as text " country model(s): " ///
           as result `burnin' as text " burn-in + " as result `draws' ///
           as text " draws, thinned by " as result `thin' as text ///
           " -> " as result `nkeep' as text " kept ..."
    }

    * svmode 1 reproduces BGVAR's homoskedastic branch exactly, which fills
    * the LOG variance with the variance itself (source defect #8).  The
    * default is the corrected version.
    * svmode 0  homoskedastic, log sigma^2 stored (corrected default)
    *        1  homoskedastic, reproducing BGVAR's cur_sv.fill(sig2), defect #8
    *        2  stochastic volatility
    local svmode 0
    if ("`bgvarsv'" != "") local svmode 1
    if ("`sv'" != "")      local svmode 2
    if ("`sv'" != "" & "`bgvarsv'" != "") {
        di as err "{bf:sv} and {bf:bgvarsv} contradict each other: bgvarsv"
        di as err "reproduces BGVAR's HOMOSKEDASTIC branch (source defect #8),"
        di as err "so it has nothing to say about a stochastic-volatility fit."
        exit 198
    }

    * BGVAR samples tau by default (utils.R:436 sample_tau=TRUE), so a fixed
    * shape is the exception there rather than the rule.  nosampletau holds it
    * at tautheta() for the whole chain.
    local stau 1
    if ("`nosampletau'" != "") local stau 0

    * The Horseshoe's ENDOGENOUS zeta update is written differently from the
    * other two in the source -- scale 1+tau where they use 1/(1+1/tau), which
    * is 1+tau against tau/(1+tau).  Source defect #11.  Corrected by default;
    * bgvarhs reproduces it, the same arrangement as bgvarsv for defect #8.
    local hsmode 0
    if ("`bgvarhs'" != "") local hsmode 1

    mata: gvar_bayesrun(`draws', `burnin', `thin', `lambda1', `lambda2', ///
                        `lambda3', `lambda4', `prmean', `a1', `b1', ///
                        `svmode', `pnum', `tau0', `tau1', `pi', ///
                        `kappa0', `kappa1', `qij', `tautheta', ///
                        `dlambda', `elambda', `stau', `hsmode')

    * ---------------------------------------------------------------------
    * The eigenvalue trim, then the write-back.  Both were missing: gvar bayes
    * used to store its draws, print "Next: gvar solve stacks the posterior
    * mean", and stop -- while gvar solve read slots nothing had written, so it
    * refused with rc 301 or stacked whatever gvar estimate had left behind.
    *
    * Order matters.  The trim discards draws, so the posterior mean has to be
    * taken AFTER it, over the surviving draws only.  Taking it first would
    * report a mean that includes the draws the trim was asked to remove.
    * ---------------------------------------------------------------------
    local ndtot = `nkeep'
    local nstab = `nkeep'
    local ntrim 0
    if ("`noeigentrim'" == "") {
        if ("`summary'" != "nosummary") {
            di as text "  trimming: stacking " as result `nkeep' ///
               as text " draw(s) to find the largest companion" _n ///
               "  eigenvalue of each ..."
        }
        mata: st_local("nstab", strofreal(gvar_btrim(`trim')))
        local ntrim = `ndtot' - `nstab'
        if (`nstab' < 10) {
            * Report the DISTRIBUTION, not just the count.  "0 of 60 stable" does
            * not say whether the draws sit just above the cutoff -- in which
            * case the cutoff is simply tight for this model -- or far above it,
            * which would mean something is wrong with the model rather than
            * with the trim.  The user cannot choose a sensible trim() without
            * seeing where the moduli actually are.
            mata: st_local("f1", strofreal(min(gvar_getbfeig())))
            mata: st_local("f5", strofreal(gvar_quantile(gvar_getbfeig(), 0.5)))
            mata: st_local("f9", strofreal(max(gvar_getbfeig())))
            di as err "Fewer than 10 stable draws: only `nstab' of `ndtot' had"
            di as err "a largest companion eigenvalue below `trim' in modulus."
            di as err ""
            di as err "Largest companion eigenvalue modulus across the draws:"
            di as err "    min " %9.5f `f1' "   median " %9.5f `f5' ///
                      "   max " %9.5f `f9'
            di as err ""
            di as err "BGVAR stops here too (.gvar.stacking.wrapper), and its"
            di as err "1.05 default is calibrated on smaller models.  A GVAR in"
            di as err "levels with many near-unit roots puts the MAXIMUM of"
            di as err "several hundred moduli just above one in most draws, so"
            di as err "a tight cutoff can discard all of them without anything"
            di as err "being wrong with the fit."
            di as err ""
            di as err "Read the three numbers above and then either raise"
            di as err "{bf:trim()} past them, or pass {bf:noeigentrim} to keep"
            di as err "every draw.  Do not simply lengthen the chain: that"
            di as err "changes how many draws there are, not where the moduli"
            di as err "sit."
            exit 498
        }
    }

    mata: gvar_bpost()
    mata: st_local("nok", strofreal(gvar_getbdraws()))

    if ("`summary'" != "nosummary") {
        _gvar_title "Bayesian GVAR"
        if (`pnum' == 3) {
            di as text "  Prior: {bf:Normal-Gamma}, the global-local" ///
                       " shrinkage of {it:BVAR_linear.cpp}"
            di as text "  prior == 3."
            di as text "    local  theta_ij ~ G(tau, tau lambda^2 / 2)," ///
                       " drawn as a GIG"
            di as text "    global lambda^2 ~ G(d + tau k, e + tau" ///
                       " sum(theta) prod / 2)"
            if (`tautheta' >= .) {
                di as text "    shape  tau" _col(46) "tau  = " ///
                   as result "1/ln(M)" as text "  per entity"
            }
            else {
                di as text "    shape  tau" _col(46) "tau  = " ///
                   as result %7.4f `tautheta'
            }
            di as text "    gamma  d" _col(46) as text "d    = " ///
               as result %7.4f `dlambda'
            di as text "    gamma  e" _col(46) as text "e    = " ///
               as result %7.4f `elambda'
            if (`stau') {
                di as text "    tau is {bf:sampled} by random-walk Metropolis," ///
                           " as BGVAR does"
                di as text "    by default; the proposal sd adapts over the" ///
                           " first half of"
                di as text "    burn-in.  {bf:nosampletau} holds it fixed."
            }
            else {
                di as text "    tau is {bf:held fixed} (nosampletau).  BGVAR" ///
                           " samples it by default."
            }
            di ""
            di as text "  The endogenous lags and the weakly exogenous block"
            di as text "  have {bf:separate} hierarchies -- columns 0 and 1 of"
            di as text "  lambda2_A in the source.  Sharing one would tie the"
            di as text "  shrinkage on a country's own lags to the shrinkage on"
            di as text "  its trade-weighted foreign variables."
            di ""
            di as text "  Shrinkage {bf:compounds with lag length}: lambda is a"
            di as text "  running product, so lag 3 is shrunk by l1*l2*l3, not"
            di as text "  by l3 alone.  The source uses the product over lags"
            di as text "  strictly BEFORE the current one when drawing lambda"
            di as text "  and INCLUDING it when drawing theta -- two different"
            di as text "  products a few lines apart."
            di ""
            di as text "  The GIG draws are clamped to [1e-7, 1e+7] as the"
            di as text "  source does: chi = (A - prior)^2 goes to zero for a"
            di as text "  coefficient the data pins at its prior mean, and an"
            di as text "  unclamped 1e-300 variance breaks the next Cholesky."
            di ""
            di as text "  {bf:The GIG sampler is not from BGVAR.}" ///
                       "  do_rgig1.cpp"
            di as text "  delegates to the GIGrvg package, so it was written"
            di as text "  from the algorithm and validated against the GIG"
            di as text "  moments; see {bf:_test45.do}."
        }
        else if (`pnum' == 4) {
            di as text "  Prior: {bf:Horseshoe}, {it:BVAR_linear.cpp}" ///
                       " prior == 4."
            di as text "    local  lambda_j ~ IG(1, 1/nu_j +" ///
                       " a_j^2/(2 tau))"
            di as text "           nu_j     ~ IG(1, 1 + 1/lambda_j)"
            di as text "    global tau      ~ IG((n+1)/2, 1/zeta +" ///
                       " sum(a^2/lambda)/2)"
            di as text "           zeta     ~ IG(1, 1 + 1/tau)"
            di as text "    and V = tau * lambda, elementwise."
            di ""
            di as text "  The half-Cauchy tails are written as a pair of"
            di as text "  inverse-gamma steps, so unlike Normal-Gamma this"
            di as text "  prior needs no GIG draw at all and nothing in it had"
            di as text "  to be reconstructed -- it is entirely in the source."
            di ""
            di as text "  {bf:Three} hierarchies, not two: the endogenous lags,"
            di as text "  the weakly exogenous block, and the free elements of"
            di as text "  L each carry their own tau and zeta.  Normal-Gamma"
            di as text "  has only two and handles L separately, so the layout"
            di as text "  does not carry over between them."
            di ""
            if (`hsmode' == 1) {
                di as text "  {bf:bgvarhs}: reproducing the source's" ///
                           " ENDOGENOUS zeta"
                di as text "  update, which reads scale 1 + tau where the" ///
                           " other two"
                di as text "  read 1/(1 + 1/tau).  Source defect #11."
            }
            else {
                di as text "  The source's ENDOGENOUS zeta update reads"
                di as text "    zeta = 1/rgamma(1, 1 + 1/(1/tau))"
                di as text "  where the exogenous and L blocks both read"
                di as text "    zeta = 1/rgamma(1, 1/(1 + 1/tau))."
                di as text "  1 + 1/(1/tau) is 1 + tau, unwrapped, so that one"
                di as text "  block draws its auxiliary with scale 1+tau"
                di as text "  instead of tau/(1+tau) -- a rate of 0.99 against"
                di as text "  101 at tau = 0.01.  Two of the three lines agree"
                di as text "  with each other and with the published"
                di as text "  augmentation; one does not.  Source defect #11,"
                di as text "  corrected here.  {bf:bgvarhs} reproduces it."
            }
            di ""
            di as text "  (n+1)/2 is an INTEGER division in the source, since"
            di as text "  n, nstar and v are all declared int -- shape 25, not"
            di as text "  25.5, when n = 50.  Reproduced rather than promoted."
        }
        else if (`pnum' == 2) {
            di as text "  Prior: {bf:SSVS}, the spike and slab of" ///
                       " {it:BVAR_linear.cpp} prior == 2."
            di as text "    spike sd  tau0 * se(coef)" _col(46) ///
               "tau0 = " as result %7.4f `tau0'
            di as text "    slab  sd  tau1 * se(coef)" _col(46) ///
               as text "tau1 = " as result %7.4f `tau1'
            di as text "    inclusion prior on A" _col(46) ///
               as text "p    = " as result %7.4f `pi'
            di as text "    spike/slab sd on L" _col(46) ///
               as text "k0/k1= " as result %7.4f `kappa0' as text " /" ///
               as result %7.4f `kappa1'
            di as text "    inclusion prior on L" _col(46) ///
               as text "q    = " as result %7.4f `qij'
            di ""
            di as text "  tau0 and tau1 scale with each coefficient's OLS"
            di as text "  standard error, so the spike and the slab are"
            di as text "  measured in what the data can resolve rather than"
            di as text "  in absolute size."
            di ""
            di as text "  {bf:gamma == 1 is the SLAB.}  BGVAR's"
            di as text "  {it:draw_bernoulli(p)} returns ZERO with probability"
            di as text "  p, and the probability it is given is the SPIKE's."
            di as text "  Reading it the usual way round inverts every"
            di as text "  inclusion probability while leaving the sampler"
            di as text "  looking perfectly healthy."
        }
        else {
            di as text "  Prior: {bf:Minnesota}, as {it:helper.cpp" ///
                       " get_Vminnesota} writes it."
        * _col(40) was overrun by the longest label, which ran the formula
        * into the hyperparameter.  46 clears "(l1 l3/(l+1))^2 s_i/s_j*".
        di as text "    own lag        (l1/l)^2" _col(46) ///
           "l1 = " as result %7.4f `lambda1'
        di as text "    cross lag      (l1 l2/l)^2 s_i/s_j" _col(46) ///
           as text "l2 = " as result %7.4f `lambda2'
        di as text "    weakly exog    (l1 l3/(l+1))^2 s_i/s_j*" _col(46) ///
           as text "l3 = " as result %7.4f `lambda3'
        di as text "    deterministic  l4 s_i" _col(46) ///
           as text "l4 = " as result %7.1f `lambda4'
        }
        di as text "  Prior mean on the first own lag: " as result `prmean' ///
           as text "  (1 = random walk, 0 = white noise)"
        di ""
        if (`pnum' == 1) {
            di as text "  The weakly exogenous block runs from lag" ///
                       " {bf:zero} --"
            di as text "  the contemporaneous star variables are regressors --"
            di as text "  which is why its denominator is (l+1) and not l."
            di ""
        }
        di as text "{hline 74}"
        di as text "  Sampler"
        di as text "{hline 74}"
        di as text "  Two loops per sweep, per country model:"
        di as text "    1  coefficients, equation by equation, a GLS draw"
        di as text "       conditioned on every other equation through L^-1"
        di as text "    2  the free elements of L, by regressing each"
        di as text "       equation's residual on the earlier ones"
        di as text "  so Sigma = L D L' comes from the same sweep -- that way"
        di as text "  round, because the structural residuals are (Y-XA)L^-1"
        di as text "  and D is THEIR variance (BVAR_linear.cpp:412, :780)."
        di as text "  BVAR_linear.cpp also contains a joint version at line" ///
                   " 413 that"
        di as text "  draws the coefficients and L together; it is commented" ///
                   " out and is"
        di as text "  {bf:not} what runs."
        di ""
        if (`svmode' == 1) {
            di as text "  {err:bgvarsv}: reproducing BGVAR's homoskedastic"
            di as text "  branch, which fills the LOG variance with the"
            di as text "  variance itself.  The data are then weighted by"
            di as text "  exp(-sigma^2) rather than 1/sigma^2, so the prior"
            di as text "  dominates far more than intended.  Source defect #8."
        }
        else {
            di as text "  Variances: inverse gamma, a1 = " as result `a1' ///
               as text ", b1 = " as result `b1' as text "."
            di as text "  The log variance is stored as {bf:log sigma^2}," ///
                       " which is the"
            di as text "  convention every consumer of it assumes." ///
                       "  {bf:bgvarsv} reproduces"
            di as text "  BGVAR's branch instead; see {help gvar_methods}."
        }
        di ""
        di as text "  " as result `nok' as text " draw(s) kept per country" ///
           " model."
        if ("`noeigentrim'" == "") {
            di as text "  Eigenvalue trim at " as result `trim' as text ///
               ": " as result `nstab' as text " of " as result `ndtot' ///
               as text " draw(s) kept, " as result `ntrim' as text " dropped."
            mata: st_local("fmin", strofreal(min(gvar_getbfeig())))
            mata: st_local("fmax", strofreal(max(gvar_getbfeig())))
            di as text "  Largest companion eigenvalue modulus over the kept" ///
                       " draws:"
            di as text "    min " as result %9.5f `fmin' as text ///
               "   max " as result %9.5f `fmax'
            di as text "  The trim is a {bf:global} rule applied after" ///
                       " stacking, because a"
            di as text "  country model can be stable while the system is" ///
                       " not, and the"
            di as text "  reverse.  {bf:noeigentrim} keeps every draw."
            * The moduli are already in hand, so say what they imply rather
            * than leaving the user to find it out from gvar solve.  If not one
            * draw is inside the unit circle then no choice of trim() helps and
            * the posterior mean cannot be stable either.
            if (`fmin' > 1) {
                di ""
                di as text "  {err:Every draw has a largest modulus above" ///
                           " one.}  No cutoff can"
                di as text "  fix that: the posterior mean will not be a" ///
                           " stable GVAR, and"
                di as text "  impulse responses from it will not die out."
                di as text "  {bf:prmean(1)} is a random-walk prior -- it" ///
                           " pushes every own"
                di as text "  first lag towards one, which is what puts the" ///
                           " roots on the"
                di as text "  circle.  On a large system in levels" ///
                           " {bf:prmean(0)} pulls them"
                di as text "  inside; on the shipped 26-unit demo" ///
                           " {bf:prmean(0) lambda1(0.1)}"
                di as text "  gives a largest modulus of 0.998 with no root" ///
                           " above unity."
            }
        }
        else {
            di as text "  {bf:noeigentrim}: no draw was discarded.  BGVAR" ///
                       " trims at 1.05 by"
            di as text "  default, so unstable draws may be in the posterior" ///
                       " mean."
        }
        di ""
        di as text "  The posterior mean is now in the country-model slots," ///
                   " so {bf:gvar solve}"
        di as text "  and the whole dynamic-analysis group proceed unchanged;" ///
                   " see"
        di as text "  {help gvar_bayes}."
        di ""
    }

    return scalar draws  = `nok'
    return scalar burnin = `burnin'
    return scalar thin   = `thin'
    return scalar trim   = `trim'
    return scalar ndrawn = `ndtot'
    return scalar ntrim  = `ntrim'
    return scalar nstable = `nstab'
    return local  prior  "`prior'"
    return scalar priorno = `pnum'
end
