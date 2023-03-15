*! version 1.1.2  15feb2023  kaplandm.github.io  (new: qregplot compatibility!)
program sivqr, eclass properties(svyb) byable(recall)
 version 11
 if (!replay()) {
  * Check for i. and give instructions: ibn. and noconstant
  tempname chki chkibn
  local `chki' = strpos(`"`0'"',"i.")
  if (``chki'') {
    di as error "To use {bf:i.} factor variable syntax for regressors, instead use {bf:ibn.} and add the {bf:noconstant} option"
  }
  local `chkibn' = strpos(`"`0'"',"ibn.")

  * Save for e(cmdline)
  local 00 `"sivqr `0'"'

  * Parse variables with _iv_parse (as in ivregress.ado)
  _iv_parse `0'
  tempname lhs Xendo Xexog Zexcl
  local `lhs' `s(lhs)'
  local `Xendo' `s(endog)'
  local `Xexog' `s(exog)'
  local `Zexcl' `s(inst)'
  local 0 `s(zero)'
  if !wordcount("``Xendo''") {
    // could just stop and say to run qreg, but maybe some people want smoothed QR
  }

  * Parse arguments for qregplot
  tempname qregplot_ifin qregplot_oth
  syntax [if] [in] [pweight iweight fweight/] , Quantile(real) *
  local `qregplot_ifin' `if' `in'
  local `qregplot_oth' `options'

  * Parse arguments for sivqr
  syntax [if] [in] [pweight iweight fweight/] , Quantile(real) [Bandwidth(real -112358) Level(cilevel) Reps(integer 0) LOGiterations noCONstant SEED(integer 112358) INITial(string) noDOTS]
  if (``chkibn''>0 & "`constant'"!="noconstant") {
    di as error "To use {bf:ibn.} factor variable syntax for regressors, add the {bf:noconstant} option"
  }
  if (`quantile'<=0) {
    di as error "{bf:quantile(`quantile')} is out of range: must be >0"
    exit 198
  }
  else if (`quantile'>=100) {
    di as error "{bf:quantile(`quantile')} is out of range: must be <100"
    exit 198
  }
  else if (`quantile'>=1) {
    local quantile = `quantile'/100
  }
  if (`level'<10 | `level'>99.99) { // matches regress
    di as error "{bf:level(`level')} is out of range: must be between 10 and 99.99 inclusive"
    exit 198
  }
  if (`reps'<2 & `reps'!=0) {
    // di as text "Note: computing analytic standard errors (not bootstrap) because reps<2"
    local reps 0
  }
  if (`bandwidth'==-112358) {
    if ("`weight'"!="") {
      di as text "Warning: plug-in bandwidth ignores weights (assumes iid)"
    }
  }
  else if (`bandwidth'<0) {
    di as error "{bf:bandwidth(`bandwidth')} is out of range: must be non-negative real number"
    exit 198
  }
  local wgtvar = ""
  if ("`weight'"!="") {
    tempvar wgtvar
    gen `wgtvar' = `exp'
    di as text "Warning: coefficient estimates are valid, but standard errors assume iid data"
    di as text "         (usually not true with weights)"
  }

  marksample touse
  markout `touse' ``lhs'' ``Xexog'' ``Xendo'' ``Zexcl''

  qui count if `touse'
  if (r(N) == 0) { 
    error 2000
  }
  else {
    local nobs `=r(N)'
  }

  * Main subroutine call
  tempname sivqrb sivqrV sivqrh sivqrhhat sivqrhhatmax initname
  if ("`initial'"=="") {
    * qreg doesn't support noconstant, so adjust after
    if ("`weight'"!="") {
      * Using aweight so can use Stata version 11; o/w need Stata 12 for pw/iw
      qui qreg ``lhs'' ``Xendo'' ``Xexog'' if `touse' [aw=`exp'] , quantile(`quantile')
    }
    else {
      qui qreg ``lhs'' ``Xendo'' ``Xexog'' if `touse' , quantile(`quantile')
    }
    matrix `initname' = e(b)
    if ("`constant'"=="noconstant") {
      matrix `initname' = `initname'[1,1..(colsof(`initname')-1)]
    }
  }
  else {
    matrix `initname' = `initial'
  }
  tempname seedname
  local `seedname' = c(seed)
  mata: sivqrmain("``lhs''", "``Xendo''", "``Xexog''", "``Zexcl''", "`touse'", `quantile', `bandwidth', `reps', "`logiterations'"=="logiterations", "`constant'"=="noconstant", "`wgtvar'", `seed', "`dots'"=="nodots", "`sivqrb'", "`sivqrV'", "`sivqrh'", "`sivqrhhat'", "`sivqrhhatmax'", "`initname'")
  set seed ``seedname''

  * Store return values
  if ("`constant'"=="noconstant") {
    matrix colnames `sivqrb' = ``Xendo'' ``Xexog''
  }
  else {
    matrix colnames `sivqrb' = ``Xendo'' ``Xexog'' _cons
  }
  tempname erpwgt erpopt
  local `erpwgt' = ""
  if ("`weight'"!="") {
    local `erpwgt' = "[`weight'=`exp'] "
  }
  local `erpopt' = `"depname("``lhs''") obs(`nobs') esample(`touse')"'
  capture confirm matrix `sivqrV'
  // [redundant w/ ereturn post]  ereturn clear
  if _rc { // `sivqrV' does not exist
    ereturn post `sivqrb' ``erpwgt'', ``erpopt'' properties("b")
  }
  else { // `sivqrV' exists
    local names : colfullnames `sivqrb'
    matrix rownames `sivqrV' = `names'
    matrix colnames `sivqrV' = `names'
    ereturn post `sivqrb' `sivqrV' ``erpwgt'', ``erpopt'' properties("b V")
  }
  ereturn scalar reps = `reps' // # bootstrap replications
  if (strtrim("``Xexog''")=="") {
    ereturn local insts "``Zexcl''"
    ereturn local exogr ""
  }
  else {
    ereturn local insts "``Xexog'' ``Zexcl''"
    ereturn local exogr "``Xexog''"
  }
  ereturn local instd "``Xendo''"
  ereturn local title "Smoothed instrumental variables quantile regression (SIVQR)"
  if ("`constant'"=="noconstant") {
    ereturn local constant "noconstant"
  }
  ereturn scalar bwidth = `sivqrh' //matches qreg name (though different meaning!)
  ereturn scalar bwidth_req = `sivqrhhat'
  if (`bandwidth'<0) {
    ereturn scalar bwidth_max = `sivqrhhatmax'
  }
  ereturn scalar q = `quantile'
  ereturn local vcetype Robust
  if (`reps'>1) {
    ereturn local vcetype Bootstrap
  }
  ereturn local cmdline `"`00'"'
  ereturn local cmd "sivqr" // should be last to store (according to ereturn entry in Stata Manual)
 }
 else { // replay
  if `"`e(cmd)'"' != "sivqr" { 
    error 301
  }
  else if _by() {
    error 190
  }
  syntax [, Level(cilevel)]
 }

  * Print results header; see https://www.stata.com/manuals13/pdisplay.pdf
  di as text ""
  di as text "Smoothed instrumental variables quantile regression (SIVQR)" ///
     as text "   Quantile = "                   as result trim("`: display %6.0g e(q)'")
  di as text "Smoothing bandwidth used = "      as result %-9.0g e(bwidth) ///
     as text "                Number of obs ="  as result %11.0gc e(N)

  * Print results
  // [redundant]  return clear
  ereturn display , level(`level')
  if ("`e(instd)'"=="") {
    di as text "(no endogenous regressors)"
  }
  else {
    di as text "Instrumented:  " e(instd)
    di as text "Instruments:   " e(insts)
  }

  * To help compatibility with qregplot
  ereturn local ifin ``qregplot_ifin''
  ereturn local oth  ``qregplot_oth''
end
*
*
*
* Setting "version" here recommended by https://www.stata.com/manuals/m-2version.pdf
version 11
mata:
void sivqrmain(string scalar Yname, string matrix Dname, string matrix Xexogname, string matrix Zexclname, string scalar touse, real scalar tau, real scalar h, real scalar reps, real scalar logiterations, real scalar noconst, string scalar wgtname, real scalar seed, real scalar nodots, string scalar sivqrbname, string scalar sivqrVname, string scalar sivqrhname, string scalar sivqrhhatname, string scalar sivqrhhatmaxname, string scalar binitname) {
  real colvector Y, binit, weights, sivqrb, wstar, IQRs, hhats
  real matrix D, Xexog, Zexcl, Z, X, tmp, bstars, corrmat
  real scalar n, hhat, db, sivqrh, i, junk, k25, k75, eps25, eps75, p25, p75, N01iqr, Vhat, Vsd, sighat, hVCE
  string scalar iterlog

  iterlog = "off"
  if (logiterations) {
    iterlog = "on"
  }

  // initial value (from user or else qreg)
  binit = st_matrix(binitname)' // transposed to be colvector
  db = length(binit)
  st_eclear()
  st_rclear()

  st_view(Y, ., Yname, touse) // outcome (dependent variable)
  n = length(Y)
  weights = J(n,1,1)
  if (wgtname!="") {
    st_view(weights, ., wgtname, touse) // endog regressors
    weights = n * weights / sum(weights) // normalize: sum to n
  }
  st_view(D, ., Dname, touse) // endog regressors
  st_view(Xexog, ., Xexogname, touse) // exog regressors
  st_view(Zexcl, ., Zexclname, touse)

  Z = (J(n,1,1), Xexog, Zexcl) // all instruments (including intercept)
  X = (D, Xexog, J(n,1,1)) // all regressors (including intercept), conventional Stata order (endog, exog, _cons)
  if (noconst) { // same but no intercept/constant term
    Z = (Xexog, Zexcl)
    X = (D, Xexog)
  }
  if (cols(Zexcl)<cols(D)) {
    _error("Need at least one excluded instrument per endogenous regressor")
  }
  else if (cols(Zexcl)>cols(D)) {
    Z = (J(n,1,1), Xexog, Z*invsym(quadcross(Z,Z))*quadcross(Z,D) )
    if (noconst) { // same but no intercept/constant term
      Z = (Xexog, Z*invsym(quadcross(Z,Z))*quadcross(Z,D) )
    }
  }

  if (db<cols(X)) {
    _error("The matrix (row vector) named in the initial() option is too short; may be due to perfect multicollinearity (try running qreg or ivregress to see if any regressors are dropped due to perfect multicollinearity, then re-run sivqr without those variables)")
  }
  else if (db>cols(X)) {
    _error("The matrix (row vector) named in the initial() option is too long.")
  }

  if (h<0) {
    // compute plug-in bandwidth
    // binit = sivqrest(tau, Y, X, Z, 0, binit, weights, junk, iterlog)
    hhats = sivqrbw(tau, Y, X, binit, n, db)
    binit = sivqrest(tau, Y, X, Z, hhats[1], binit, weights, junk, iterlog)
    hhats = sivqrbw(tau, Y, X, binit, n, db)
    hhat = hhats[1]
  }
  else {
    hhats = h
    hhat = h
  }
  sivqrh = .
  retraw = sivqrest(tau, Y, X, Z, hhat, binit, weights, sivqrh, iterlog)
  sivqrb = retraw
  st_numscalar(sivqrhhatname, hhat)
  if (length(hhats)>1) {
    st_numscalar(sivqrhhatmaxname, max(hhats))
  }
  st_numscalar(sivqrhname, sivqrh)
  st_matrix(sivqrbname, sivqrb')

  if (reps>=2) {
    if (!nodots) {
      printf("{txt}Bootstrap replications ({res:%g})\n", reps)
      printf("{c -}{c -}{c -}{c -}{c +}{c -}{c -}{c -} 1 {c -}{c -}{c -}{c +}{c -}{c -}{c -} 2 {c -}{c -}{c -}{c +}{c -}{c -}{c -} 3 {c -}{c -}{c -}{c +}{c -}{c -}{c -} 4 {c -}{c -}{c -}{c +}{c -}{c -}{c -} 5\n")
      displayflush()
    }
    rseed(seed) // to be reproducible
    bstars = J(reps,db,.)
    for (i=1; i<=reps; i++) {
      // Dirichlet weights for Bayesian bootstrap
      wstar = rexponential(n,1,1)
      //wstar = invexponential(1, runiform(n,1))
      wstar = n * wstar / sum(wstar)
      wstar = wstar:*weights
      wstar = n * wstar / sum(wstar)
      // Estimate with weights
      bstars[i,.] = sivqrest(tau, Y, X, Z, sivqrh, sivqrb, wstar, junk, iterlog)'
      if (!nodots) {
        printf(".")
        if (mod(i,50)==0) {
          printf("%6.0g", i)
          if (i<reps) printf("\n")
        }
        displayflush()
      }
    }
    if (!nodots) {
      printf("\n")
    }
    if (reps<4) {
      st_matrix( sivqrVname , variance(bstars) )
    }
    else {
      // Compute "robust" covariance matrix based on correlation and IQRs
      IQRs = J(db,1,.)
      // Compute sample quantiles as in (1) in https://doi.org/10.1016/j.jeconom.2016.09.015
      k25 = floor(0.25*(reps+1));  eps25 = (0.25*(reps+1))-k25
      k75 = floor(0.75*(reps+1));  eps75 = (0.75*(reps+1))-k75
      for (i=1; i<=db; i++) {
        tmp = sort(bstars[,i], 1)
        p25 = ((1-eps25)*tmp[k25]+eps25*tmp[k25+1])
        p75 = ((1-eps75)*tmp[k75]+eps75*tmp[k75+1])
        IQRs[i] = p75-p25
      }
      N01iqr = (invnormal(0.75) - invnormal(0.25))
      // Given asy normal approx, std dev ~= IQR/N01iqr, and cov=(corr)(sd1)(sd2)
      st_matrix( sivqrVname , correlation(bstars):*(IQRs*IQRs')/N01iqr^2 )
    }
  }
  else { // compute analytic SE
    Vhat = Y - X*sivqrb  // additive residuals
    _sort(Vhat,1) // sort in place (argument 1=1st column)
    // Compute Silverman-type "sigma hat" and bandwidth
    Vsd = sqrt(variance(Vhat))
    k25 = floor(0.25*(n+1));  eps25 = (0.25*(n+1))-k25
    k75 = floor(0.75*(n+1));  eps75 = (0.75*(n+1))-k75
    p25 = ((1-eps25)*Vhat[k25]+eps25*Vhat[k25+1])
    p75 = ((1-eps75)*Vhat[k75]+eps75*Vhat[k75+1])
    sighat = min((Vsd, (p75-p25)/(invnormal(0.75)-invnormal(0.25))))
    hVCE = 1.06*n^(-1/5)*sighat

    Shat = tau*(1-tau)*quadcross(Z,Z)/n
    Jhat = quadcross(Z, normalden(Vhat/hVCE), X) / (n*hVCE)
    Shatinv = invsym(Shat)
    st_matrix( sivqrVname , invsym(Jhat' * Shatinv * Jhat) / n )
    // Jhatinv = inv(Jhat)
    // st_matrix( sivqrVname , Jhatinv*Shat*Jhatinv' )
  }
}


// Try to estimate with bandwidth hhat; increase if necessary to get numerical solution
real colvector sivqrest(real scalar tau, real colvector Y, real matrix X, real matrix Z, real scalar hhat, real colvector binit, real colvector weights, real scalar storeHhere, string scalar iterlog) {
  real scalar n, h, ecnl, convnl
  real scalar hinit, hcur, hfac, hlo, hhi
  real scalar HMAX
  real colvector ret, bbest
  real scalar lastec //last solvenl() error code
  string scalar lastet //last solvenl() error text
  transmorphic scalar S // for solvenl()

  n = length(Y)
  if (length(weights)==1) { // should never happen
    weights = J(n,1,1)
    // weights = J(n,1,weights)
  }

  // bandwidth search initialization
  if (hhat==0) {
    hcur = hinit = 0.001
    hfac = 100
  }
  else {
    hcur = hinit = hhat
    hfac = 10
  }
  hlo = hhat
  hhi = .
  bbest = binit

  // solvenl() initialization
  S = solvenl_init()
  solvenl_init_type(S, "zero")
  solvenl_init_numeq(S, length(binit))
  solvenl_init_evaluator(S, &objnl())
  solvenl_init_conv_maxiter(S, 400) // matches gmmq.R
  solvenl_init_iter_log(S, iterlog)
  solvenl_init_technique(S, "broyden") // no analytic Jacobian allowed so broyden better than newton
  solvenl_init_argument(S, 1, weights:*Z)
  solvenl_init_argument(S, 2, X)

  // Loop: h<=hlo<hcur<hhi, where hhi can be solved by solvenl() but hlo cannot
  lastec = .
  lastet = ""
  HMAX = 1e10
  while (hcur<=HMAX & hcur>epsilon(1)*1e2 & (hhi==. | (hhi/hlo)>1.4)) {
    solvenl_init_argument(S, 3, hcur\tau\n\Y)
    solvenl_init_startingvals(S, bbest)
    ecnl = _solvenl_solve(S)
    convnl = solvenl_result_converged(S)
    if (ecnl==0 & convnl==1) { // found solution
      bbest = solvenl_result_values(S)
      hhi = hcur
      hlo = hhat
      if (hcur==hhat) { //found solution w/ user-requested h
        break
      }
      else if (hhi/hinit>2.5 | hhat==0) { 
        hcur = (hlo+hhi)*(2/3)
      }
      else {
        hcur = hinit
      }
    }
    else if (any(ecnl:==(0\1\6\20::22\27))) { // did not find solution
      lastec = ecnl
      lastet = solvenl_result_error_text(S)
      hlo = hcur
      if (hhi==.) { // keep going up till find hcur that actually works
        hcur = hcur*hfac
      }
      else {
        hcur = (hlo+hhi)/2
      }
    }
    else { //bad error (not just lack of convergence); exit
      _error(ecnl, solvenl_result_error_text(S))
    }
  } //end while loop

  if (hcur>HMAX) {
    printf("error in solvenl()\n")
    if (lastec==21) {
      printf("May be due to perfect multicollinearity; try running qreg or ivregress to see if any regressors are dropped due to perfect multicollinearity, then re-run sivqr without those variables.\n")
    }
    _error(lastec, lastet)
  }

  storeHhere = hhi
  return(bbest)
}


// Compute plug-in bandwidth from Stata Journal article
real colvector sivqrbw(real scalar tau, real colvector Y, real matrix X, real colvector binit, real scalar n, real scalar db) {
  real scalar k, eps, k25, eps25, k75, eps75, p25, p75
  real scalar h1, h2, h3, Vsd, sighat
  real colvector Vhat

  // Get residuals based on binit
  Vhat = Y - X*binit
  // Shift Vhat distribution such that tau-quantile=0
  _sort(Vhat,1) // sort in place (argument 1=1st column)
  k = floor(tau*(n+1))
  eps = tau*(n+1) - k
  Vhat = Vhat :- (Vhat[k] + eps*(Vhat[k+1]-Vhat[k]))

  // Compute Silverman-type "sigma hat"
  Vsd = sqrt(variance(Vhat))
  k25 = floor(0.25*(n+1));  eps25 = (0.25*(n+1))-k25
  k75 = floor(0.75*(n+1));  eps75 = (0.75*(n+1))-k75
  p25 = ((1-eps25)*Vhat[k25]+eps25*Vhat[k25+1])
  p75 = ((1-eps75)*Vhat[k75]+eps75*Vhat[k75+1])
  sighat = min((Vsd, (p75-p25)/(invnormal(0.75)-invnormal(0.25))))
  
  // Compute kernel estimated h
  h1 = sivqrbwK(tau, n, db, sighat, Vhat)

  // Compute Gaussian reference h
  h2 = sivqrbwG(tau, n, db, sighat)  //adj'd to allow tau=.5

  // Compute Silverman bandwidth
  h3 = 1.06*n^(-1/5)*sighat

  // Return all (will try min later, then next-lowest, etc.)
  return( sort( (h1,h2,h3)' , 1 ) )
}


// Kernel plug-in bandwidth
real scalar sivqrbwK(real scalar tau, real scalar n, real scalar db, real scalar sighat, real colvector Vhat) {
  real scalar f0hat, fdhat, s, b, tmp, tmp2, Ztau
  Ztau = invnormal(tau)
  // compute \hat{s}
  tmp = normalden(Ztau) * (Ztau^2 - 1)^2
  s = (2*sqrt(pi()))^(-1/5) * n^(-1/5) * sighat * (tmp)^(-1/5)
  // compute \hat{b}
  tmp = 3 / (4*sqrt(pi()))
  tmp2 = normalden(Ztau) * Ztau^2 * (3-Ztau^2)^2
  b = n^(-1/7) * sighat * (tmp/tmp2)^(1/7)
  // compute f0hat to est. f_v(0) = 1/(ns) sum K(-\hat{v}_i/s)
  f0hat = sum(normalden(-Vhat/s)) / (n*s)
  // compute fd0hat to est. f_v'(0) = 1/(nb^2) sum K'(-\hat{v}_i/b)
     // rem phi'(x)=(-x)*phi(x)
  fd0hat = sum((Vhat/b):*normalden(-Vhat/b)) / (n*b^2)
  // plug into formula for h*
  return( n^(-1/3) * (3*db*f0hat/(fd0hat^2))^(1/3) )
}


// Gaussian reference bandwidth
real scalar sivqrbwG(real scalar tau, real scalar n, real scalar db, real scalar sighat) {
  real scalar Ztau, denom
  Ztau = max( ( invnormal(0.55) , abs(invnormal(tau)) ) ) // avoid denom~0
  denom = Ztau^2 * normalden(Ztau)
  return( n^(-1/3) * sighat * (3*db/denom)^(1/3) )
}


// Smoothed indicator function
// (Simpler and more robust than that of Kaplan and Sun (2017))
real colvector Itilde(real colvector u) {
  real colvector ret
  ret = J(length(u),1,1)
  inds1 = selectindex(abs(u):<1)
  inds2 = selectindex(u:<=-1)
  ret[inds2] = J(length(inds2),1,0)
  // Kaplan & Sun (2017): ret[inds1] = J(length(inds1),1,1/2) + (105/64)*( u[inds1] - (5/3)*u[inds1]:^3 + (7/5)*u[inds1]:^5 - (3/7)*u[inds1]:^7 )
  ret[inds1] = J(length(inds1),1,1/2) + u[inds1]:/2
  return(ret)
}


// Objective function for solvenl()
// gmmq.R (unweighted): return(colMeans(Z*array(data=Itilde(-L/h)-tau,dim=dim(Z)))) with L = Y-X*b
void objnl(real colvector b, real colvector values, real matrix Zw, real matrix X, real colvector htaunY) {
  values = quadcross(Zw , (Itilde(-(htaunY[|4\.|]-X*b)/htaunY[1]) - J(htaunY[3],1,htaunY[2]))) / htaunY[3]
}

end // end mata
