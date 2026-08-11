*! mcs 2.2.1 jo/cfb 9aug2026
// 1.2.0: guard against indices > lastobs
// 1.2.1: add returns
// 1.3.0: modify loss functions 
// 1.3.1: guard against non-positives for qlike
// 1.3.2: return includedR as well as includedSQ
// 2.0.0: link to Claude translation of R code
// 2.1.0: reinstate auto-blocksize calc using blockboot bstar()
// 2.1.1: capture gaps, missings
// 2.2.1: rename to mcset
capture program drop mcset
mata: mata clear
program define mcset, rclass
version 14

// syntax varlist(numeric ts) [if] [in], GENerate(string) [DOUBLE] ///
syntax varlist(numeric) [if] [in],  ///
								   TYPEBOOT(string) ///
								   TYPELOSS(string) ///
								   LBLOCK(string) ///
								   [ ///
								   BOOTDRAWS(integer 100) ///
								   ALPHA(real 0.1) ///
								   STAT(string) /// 
								   SEED(integer -1) ///
								   ]
								  
marksample touse
qui count if `touse'
if (`r(N)'<2) {
	display as error "Actual and Predicted values must have at least two observations"
	exit
}

// loc tloss levelse levelae volse2 volae2 volqlike volr2log varnormal vardiff 		 
loc tloss rmse mae mape qlike
loc wt: list posof "`typeloss'" in tloss
if !`wt' {
	display as error _n "Valid options for option type are:"
	display as error _n "rmse  (loss function using root mean squared error)"
	display as error _n "mae   (loss function using mean absolute error)"
	display as error _n "mape  (loss function using mean absolute percent error)"
	display as error _n "qlike (loss function using )Gaussian quasi-likelihood"
/*
	display as error "volse2 (LOSS VOLATILITY function using square error)"
	display as error "volae2 (LOSS VOLATILITY function using absolute error)"
	display as error "volqlike (LOSS VOLATILITY function using qlike)"
	display as error "volr2log (LOSS VOLATILITY function using r2log)"
	display as error "varnormal (LOSS VaR function using type NORMAL)"
	display as error "vardiff (LOSS VaR function using type DIFFERENTIABLE)"
*/
	error 198
	exit
}

loc schemes sbb cbb mbb // nbb
loc wh : list posof "`typeboot'" in schemes
if !`wh' {
  di as err "Error: type must be chosen from"
  display as error "                    sbb (stationary block bootstrap)"
  display as error "                    cbb (circular block bootstrap)"
  display as error "                    mbb (moving block bootstrap)"
// DISABLED display as error "                    nbb (nonoverlapping block bootstrap)"
  error 198
  exit
}

if "`stat'" == "" | "`stat'" == "TR" {
	loc stat TR
}
else {
	if "`stat'" != "Tmax" {
	di as error "Error: stat must be either TR or Tmax"
	error 198
	exit
	}
}

loc _lblk `lblock'

local boots = `bootdraws'

if `seed'!=-1 {
   local seednum = `seed'
   set seed `seednum'
}

mata: mata clear

// experimental: difficult to retain names of original series
// tsrevar `varlist'
// loc varlist `r(varlist)'

local yvar  : word 1 of `varlist'		// yvar is the variable with realised (actual) values
local xvars : list varlist - yvar		// xvars is the varlist with evaluated (predicted) values
local M0    : word count `xvars'

qui reg `yvar' `xvars' if `touse'
tempvar nes
g `nes' = !e(sample)
// su `nes'

// di "`xvars'"

// for qlike, require positive values

qui replace `yvar' = . if `nes'
su `yvar' if `touse', meanonly
if "`typeloss'"=="qlike" & `r(min)'<=0 {
	di as err _n "Error: qlike requires positive values for `yvar'"
	exit
}

foreach v of local xvars {
	qui replace `v' = . if `nes'
	su `v' if `touse', meanonly
	if "`typeloss'"=="qlike" & `r(min)'<=0 {
		di as err _n "Error: qlike requires positive values for `v'"
		error 198
	}
}

// ensure that multiple models are provided
if `M0' < 2 {
	display as error "At least two models must be specified"
	error 102
	exit
}

tempvar trd
qui gen `trd' = _n if `touse' 
qui replace `trd' = . if `nes'
qui sum `trd'
local initobs = r(min)
// guard against referring to lastobs 
// local lastobs = r(max) 
local lastobs = r(max) - `initobs' + 1
local totalobs = r(N) // `lastobs' // - `initobs' + 1
// di "`initobs' `lastobs' `totalobs'"
di _n "T = `totalobs'" 

qui tsset `trd'
qui tsreport
if (r(N_gaps) >0) {
	di as err _n "Error: Gaps in timeseries not allowed."
	error 198
}

loc broutine "`typeboot'indx2"
// di "`broutine'"

// create Mata loss matrix, bootstrap mIndices matrix
mata: part0("`yvar'", "`xvars'", "`touse'", "`typeloss'",`M0',"`typeboot'","`broutine'",`boots',`initobs',`lastobs',`totalobs',`_lblk')
// mata: res = mcs_run(mL, 0.15,    50,     "Tmax",      0, 3, 1, 123)
mata: res = mcs_run(loss, `alpha', `boots', "`stat'","`typeboot'", "`typeloss'",`_lblk', 1, 1, `seed',`initobs',`lastobs',`totalobs',"`broutine'")
mata: mcs_show(res)

return local cmdname = "mcs"
return local actual "`yvar'"
return local predicted "`mn'"
return local stat = "`stat'"
return sca N = `totalobs'
return local typeloss = "`typeloss'"
return local typeboot = "`typeboot'"
return sca bootdraws = `bootdraws'
return sca lblock = k
return sca N_models = N_models
return sca N_included = included
return sca N_excluded = excluded
return local included = incl
return local excluded = excl
matrix rownames mcsres = `mn'
matrix colnames mcsres = Included Lblock Avg_Loss pv_H0 MCS_pv
return matrix mcsres = mcsres
matrix rownames blklen = Min Mean Max `mn'
return matrix blklen = blklen
end
 

// -----------------------------------------------------------------------------
mata:
mata set matastrict on 

void part0(
				string scalar yvar, 
				string scalar xvars,  
				string scalar touse, 
				string scalar typeloss, 
				real scalar M0, 
				string scalar typeboot,
				string scalar broutine,
				real scalar boots,
				real scalar initobs,
				real scalar lastobs,
				real scalar totalobs,
				real scalar lblock)	
{
	external real matrix  loss, mIndices
	external string vector mnames
	external real colvector indices
	real scalar boot
	real matrix means
	
	mnames = tokens(xvars)	
	lossescmd(yvar, xvars, touse, typeloss)
	M0 = cols(loss)
    means = mean(loss)
	
//	"means"
//	means

// "initobs, lastobs, totalobs, lblock"
// initobs, lastobs, totalobs, lblock
	
// call bootstrap routine within this loop
// mcs: build up a single matrix of mIndices

	mIndices = J(totalobs,boots,.)

// relocated to mcs_run
// must generate auto blocklength before call to bootstrap from loss series

/*	
	for (boot=1; boot<=boots; boot++) {
		if (broutine=="cbbindx2") {
			cbbindx2(initobs,lastobs,totalobs,lblock)
		}
		if (broutine=="sbbindx2") {
			sbbindx2(initobs,lastobs,totalobs,lblock)
		}
		if (broutine=="mbbindx2") {
			mbbindx2(initobs,lastobs,totalobs,lblock)
		}
		mIndices[.,boot] = indices
		
//		boot
	}
	"here"
//	mIndices
*/
}
	
// ----------------------------------------------------------------------------

void  lossescmd(string scalar yvar, ///
				string scalar xvars, ///
				string scalar touse, ///
				string scalar typeloss)
{
	external real matrix Y, X, loss
	real scalar onen
	st_view(Y, ., yvar, touse)
	st_view(X=., ., tokens(xvars), touse)
	
// cfb loss is a matrix with rows defined by touse and cols for each X
//     indic can be folded into losses

// create losses as Mata matrix
	loss=J(rows(X),cols(X),.)
//	loss=J(rows(X),cols(X),.)
	onen = 1/rows(X)

//	st_view(lossmat=., ., tokens(lossvars), touse)
//	st_view(indic=., ., tokens(newvars), touse)
	if (typeloss == "rmse") {
		loss[., .] = sqrt(onen :* (X :- Y):^2)
	}
	else if (typeloss == "mae") {
		loss[., .] = onen :* abs(X :- Y)
	}
	else if (typeloss == "mape") {
		loss[., .] = onen :* abs((X :- Y):/ X)
	}
	else if (typeloss == "qlike") {
//  fails for nonpositive X, Y
	loss[., .] = onen :* ((X :/ Y) - log(X :/ Y) :-1) 
	}
}
	
	
// ── Struct to hold results (replaces R's SSM S4 class) ──────────────────────
struct MCS_result {
    real matrix  tab          // iM x 3: avg loss, H0 p-value, MCS p-value
    string vector model_names // all model names (starting set)
    string vector included    // models in the MCS
    string vector excluded    // eliminated models
    real scalar  alpha
    real scalar  B
    real scalar  k
    real scalar  seed
    string scalar statistic
	string scalar typeboot
	string scalar typeloss
    real scalar  elapsed      // seconds
}

// ============================================================================
// MAIN MCS PROCEDURE
// ============================================================================

// Arguments
//   mL_in     : iT x iM loss matrix (rows = obs, cols = models)
//   alpha     : significance level (default 0.15)
//   B         : bootstrap replications (default 1000)
//   statistic : "Tmax" or "TR"
//   k         : block length (0 = auto-select)
//   min_k     : minimum block length when k auto-selected (default 3)
//   verbose   : 1 = print progress, 0 = silent
//   seed      : random seed (0 = draw one randomly)
//
// Returns: struct MCS_result

struct MCS_result scalar mcs_run(
    real matrix mL_in,
    real scalar alpha,
    real scalar B,
    string scalar statistic,
	string scalar typeboot,
	string scalar typeloss,
    real scalar k,
    real scalar min_k,
    real scalar verbose,
    real scalar seed,
	real scalar initobs,
	real scalar lastobs,
	real scalar totalobs,
	string scalar broutine)
{
    // ── ALL declarations hoisted to function top (Mata requirement) ────────
    struct MCS_result scalar out
	
// cfb
	external real matrix mIndices
	external string vector mnames
	external real colvector indices
	real colvector x, blklen, optblk
	string scalar tauto
	external real scalar lblock
	real scalar minn, mu, maxx
	real matrix  mL, mTab
//    real matrix  mL, mIndices, mTab
    real matrix  mD_ij_bar, mD_ij_bar_res_b, mD_i_bar_res
    real matrix  mD_ij_bar_var, aD_ij_flat
    real matrix  tij, tij_flat, ti_res
    real matrix  order_idx, slice_b, abs_tij
    real vector  vD_i_bar, vD_i_bar_res_b, vD_i_bar_var
    real vector  ti, T_stat_res, model_idx, keep
    real vector  draws_ij, row_max, pvals_sofar
    real scalar  iM, iT, iM_start
    real scalar  i, j, b, e, boot
    real scalar  p_val, T_stat, elapsed
    real scalar  sd_ij, sd_i, d_res, rm_max, orig_idx
    real scalar  pmax, col_order
    string vector vModels, vModels_start
    string vector incl, excl
    real matrix  mL_res

    // ── timer ─────────────────────────────────────────────────────────────
    timer_clear(1)
    timer_on(1)
	
    // ── input validation ───────────────────────────────────────────────────
 //   if (statistic != "Tmax" & statistic != "TR")
 //       _error(3498, `"statistic must be "Tmax" or "TR""')
//  "alpha"
// alpha
    if (alpha < 0 | alpha > 1) _error(3498, "alpha must be in (0,1)")
    if (B < 1)    _error(3498, "B must be positive")
    if (B < 100 & verbose) printf("Warning: B is small.\n")
    if (min_k < 0) _error(3498, "min_k must be non-negative")

    // ── seed ───────────────────────────────────────────────────────────────
 //   if (seed_in == 0) {
 //       seed_used = runiformint(1, 1, 1, 100000)[1,1]
 //       rseed(seed_used)
 //   } else {
 //       seed_used = seed_in
 //       rseed(seed_used)
 //   }

    // ── setup ──────────────────────────────────────────────────────────────
    mL = mL_in
    iM = cols(mL)
    iT = rows(mL)

    vModels = J(1, iM, "")
	for (i = 1; i <= iM; i++) vModels[i] = mnames[i]
//    for (i = 1; i <= iM; i++) vModels[i] = "model_" + strofreal(i)
    vModels_start = vModels

	optblk = J(cols(mL),1,.)
	blklen = J(cols(mL)+3,1,k)
	if (k == 0) {
// auto block length from blockboot modified bstar2()

	if (broutine=="sbbindx2") {
		tauto = "sbb"
	}
	else {
		tauto = "cbb"
	}
	for (i = 1; i <= iM; i++) {
//		x = mL[.,i] 
		bstar2(mL[.,i], tauto)
		optblk[i] = lblock
//		i, lblock
		}
	minn = min(optblk)
	mu   = mean(optblk)
	maxx = max(optblk)
	blklen = minn \ mu \ maxx \ optblk
	k = maxx
	if (verbose) printf("Auto block length k = %g\n", k)
	}
	st_matrix("blklen",blklen)
	
	// ── auto block length from R routine ──────────────────────────────────────
/*
	if (k == 0) {
//        pmax = max((1, floor(4*(iT/100)^(2/9))))
// cfb revise this to allow larger auto block size
		pmax = max((1, 2*iT/100))
        k = 0
        for (i = 1; i <= iM; i++) {
            col_order = mcs_ar_order(mL[., i], pmax)
            if (col_order > k) k = col_order
        }
        if (k < min_k) k = min_k
    }
    if (verbose) printf("Block length k = %g\n", k)
*/
    // ── generate bootstrap indices once ───────────────────────────────────

//  mIndices = mcs_GetIndices(iT, k, B)
//  mIndices

// relocated from part0
	
	for (boot=1; boot<=B; boot++) {
		if (broutine=="cbbindx2") {
			cbbindx2(initobs,lastobs,totalobs,k)
		}
		if (broutine=="sbbindx2") {
			sbbindx2(initobs,lastobs,totalobs,k)
		}
		if (broutine=="mbbindx2") {
			mbbindx2(initobs,lastobs,totalobs,k)
		}
		mIndices[.,boot] = indices
	}

    // ── results table: avg loss | H0 p-val | MCS p-val ────────────────────
    iM_start  = iM
    mTab      = J(iM_start, 3, .)
    for (i = 1; i <= iM_start; i++) mTab[i, 1] = mean(mL[., i])

    // index mapping current columns back to original positions
    model_idx = (1::iM_start)

    // ── elimination loop ───────────────────────────────────────────────────
    while (cols(mL) > 1) {

        iM      = cols(mL)
        vModels = vModels_start[model_idx']

        // pairwise differentials
        mcs_GetD(mL, mD_ij_bar, vD_i_bar)

        // bootstrap resampled differentials
        // 3-D array [i,j,b] stored as iM x (iM*B): col (b-1)*iM+j holds slice b col j
        aD_ij_flat   = J(iM, iM * B, 0)
        mD_i_bar_res = J(iM, B, 0)

        for (b = 1; b <= B; b++) {
            mL_res = mL[mIndices[., b], .]
            mcs_GetD(mL_res, mD_ij_bar_res_b, vD_i_bar_res_b)
            aD_ij_flat[., ((b-1)*iM + 1)..(b*iM)] = mD_ij_bar_res_b
            mD_i_bar_res[., b] = vD_i_bar_res_b
        }

        // bootstrap variances
        mD_ij_bar_var = J(iM, iM, 0)
        vD_i_bar_var  = J(iM, 1, 0)

        for (i = 1; i <= iM; i++) {
            for (j = i; j <= iM; j++) {
                if (i != j) {
                    draws_ij = J(B, 1, 0)
                    for (b = 1; b <= B; b++) {
                        draws_ij[b] = aD_ij_flat[i, (b-1)*iM + j]
                    }
                    mD_ij_bar_var[i,j] = mean((draws_ij :- mD_ij_bar[i,j]):^2)
                    mD_ij_bar_var[j,i] = mD_ij_bar_var[i,j]
                }
            }
            vD_i_bar_var[i] = mean((mD_i_bar_res[i, .]' :- vD_i_bar[i]):^2)
        }

        // t-statistics
        tij      = J(iM, iM, 0)
        ti       = J(iM, 1, 0)
        ti_res   = J(iM, B, 0)
        tij_flat = J(iM, iM * B, 0)

        for (i = 1; i <= iM; i++) {
            for (j = i; j <= iM; j++) {
                if (i != j) {
                    sd_ij = sqrt(mD_ij_bar_var[i,j])
                    if (sd_ij == 0) sd_ij = 1e-16
                    tij[i,j] = mD_ij_bar[i,j] / sd_ij
                    tij[j,i] = -tij[i,j]
                    for (b = 1; b <= B; b++) {
                        d_res = aD_ij_flat[i, (b-1)*iM + j]
                        tij_flat[i, (b-1)*iM + j] = (d_res - mD_ij_bar[i,j]) / sd_ij
                        tij_flat[j, (b-1)*iM + i] = -tij_flat[i, (b-1)*iM + j]
                    }
                }
            }
            sd_i = sqrt(vD_i_bar_var[i])
            if (sd_i == 0) sd_i = 1e-16
            ti[i] = vD_i_bar[i] / sd_i
            for (b = 1; b <= B; b++) {
                ti_res[i, b] = (mD_i_bar_res[i, b] - vD_i_bar[i]) / sd_i
            }
        }

        // test statistic and p-value
        if (statistic == "Tmax") {
            T_stat     = max(ti)
            T_stat_res = J(B, 1, 0)
            for (b = 1; b <= B; b++) T_stat_res[b] = max(ti_res[., b])
            p_val = mean(T_stat_res :> T_stat)
            e = 1
            i = 1
            while (i <= iM) {
                if (ti[i] == T_stat) {
                    e = i
                    i = iM + 1
                }
                else {
                    i++
                }
            }
        }
        else {  // TR
            abs_tij    = abs(tij)
            T_stat     = max(abs_tij)
            T_stat_res = J(B, 1, 0)
            for (b = 1; b <= B; b++) {
                slice_b       = tij_flat[., ((b-1)*iM + 1)..(b*iM)]
                T_stat_res[b] = max(abs(slice_b))
            }
            p_val   = mean(T_stat_res :> T_stat)
            row_max = J(iM, 1, 0)
            for (i = 1; i <= iM; i++) row_max[i] = max(tij[i, .])
            rm_max = max(row_max)
            e = 1
            i = 1
            while (i <= iM) {
                if (row_max[i] == rm_max) {
                    e = i
                    i = iM + 1
                }
                else {
                    i++
                }
            }
        }

        // store p-values
        orig_idx          = model_idx[e]
        mTab[orig_idx, 2] = p_val
        pvals_sofar       = select(mTab[., 2], mTab[., 2] :< .)
        mTab[orig_idx, 3] = max(pvals_sofar)

        if (verbose) {
            printf("--------------------------------------------------------\n")
            printf("The current p-Value for H_{0,M_k} is %6.3f\n", p_val)
            if (p_val < alpha) {
                printf("Model %s is eliminated from the Superior Set of Models\n",
                       vModels[e])
            }
            printf("The current MCS p-Value is %6.3f\n", mTab[orig_idx, 3])
        }

        // drop eliminated column
        keep = J(1, 0, 0)
        for (i = 1; i <= iM; i++) {
            if (i != e) keep = (keep, i)
        }
        mL        = mL[., keep]
        model_idx = model_idx[keep']
    }

    // ── last survivor gets p-value = 1 ────────────────────────────────────
    for (i = 1; i <= iM_start; i++) {
        if (mTab[i, 2] == .) mTab[i, 2] = 1
        if (mTab[i, 3] == .) mTab[i, 3] = 1
    }

    // ── sort by MCS p-value ────────────────────────────────────────────────
    order_idx     = order(mTab[., 3], 1)
    mTab          = mTab[order_idx, .]
    vModels_start = vModels_start[order_idx']

    // ── included / excluded ────────────────────────────────────────────────
    incl = J(1, 0, "")
    excl = J(1, 0, "")
    for (i = 1; i <= iM_start; i++) {
        if (mTab[i, 2] > alpha) incl = (incl, vModels_start[i])
        else                    excl = (excl, vModels_start[i])
    }

    // ── timing ────────────────────────────────────────────────────────────
    timer_off(1)
    elapsed = timer_value(1)[1]

    // ── populate output struct ─────────────────────────────────────────────
    out.tab         = mTab
    out.model_names = vModels_start
    out.included    = incl
    out.excluded    = excl
    out.alpha       = alpha
    out.B           = B
    out.k           = k
    out.seed        = seed
    out.statistic   = statistic
	out.typeboot    = typeboot
	out.typeloss    = typeloss
    out.elapsed     = elapsed
	
    return(out)
}

// GetD: compute pairwise loss differentials and row means
// Returns mD_ij_bar (iM x iM) and vD_i_bar (iM x 1) via pointers
void mcs_GetD(real matrix mL,
              real matrix mD_ij_bar,   // passed by reference, output
              real vector vD_i_bar)    // passed by reference, output
{
    real scalar iM, i, j
    real vector vLossDiff

    iM = cols(mL)
    mD_ij_bar = J(iM, iM, 0)
    vD_i_bar  = J(iM, 1, 0)

    for (i = 1; i <= iM; i++) {
        for (j = i; j <= iM; j++) {
            if (i != j) {
                vLossDiff      = mL[., i] :- mL[., j]
                mD_ij_bar[i,j] = mean(vLossDiff)
                mD_ij_bar[j,i] = -mD_ij_bar[i,j]
            }
        }
        vD_i_bar[i] = sum(mD_ij_bar[i, .]) / (iM - 1)
    }
}
// ============================================================================
// DISPLAY (replaces R's show() method for SSM objects)
// ============================================================================
void mcs_show(struct MCS_result scalar res)
{
    real scalar i, j
	real matrix mcsres
	string scalar mn, incl, excl
	mcsres = J(rows(res.tab),5,0)
	i = length(res.excluded)+1
	for(j=i;j<=rows(res.tab);j++) mcsres[j,1] = 1
    printf("\n------------------------------------------\n")
    printf("-           MCS p-Values                 -\n")
    printf("------------------------------------------\n")
    printf("%-15s %5s %12s %12s %20s %15s\n",
           "Model", "Included", "Lblock", "Avg.Loss", "p-Val(H0,Mk)", "MCS p-Value")
//   printf("%-15s %12s %20s %15s\n",
//           "-----", "--------", "------------", "-----------")
    for (i = 1; i <= rows(res.tab); i++) {
        printf("%-15s %5.0f %12.0f %12.4f %20.4f %15.4f\n",
               res.model_names[i], mcsres[i,1], res.k, res.tab[i,1], res.tab[i,2], res.tab[i,3])
		mcsres[i,2] = res.k
		mcsres[i,3] = res.tab[i,1]
		mcsres[i,4] = res.tab[i,2]
		mcsres[i,5] = res.tab[i,3]
    }
    printf("\nDetails\n")
    printf("------------------------------------------\n")
    printf("Number of eliminated models     : %g\n", length(res.excluded))
	printf("Number of included models       : %g\n", length(res.included))
    printf("Models in the Superior Set      : ")
    for (j = 1; j <= length(res.included); j++) {
        if (j > 1) printf(", ")
        printf("%s", res.included[j])
    }
//	i = length(res.excluded)+1
//	for(j=i;j<=rows(res.tab);j++) mcsres[j,1] = 1
    printf("\nStatistic                       : %s\n", res.statistic)
	printf("Typeboot                        : %s\n", res.typeboot)
	printf("Typeloss                        : %s\n", res.typeloss)
    printf("Significance level              : %g\n", res.alpha)
	printf("Block length                    : %g\n", res.k)
	if (res.seed != -1) {
    printf("Seed used for the bootstrap     : %g\n",  res.seed)
	}
    printf("Elapsed time                    : %g seconds\n", res.elapsed)
	
	st_matrix("mcsres",mcsres)
	for(j=1;j<=rows(res.tab);j++) mn = mn + " " + res.model_names[j]
	for(j=1;j<=length(res.excluded);j++) excl = excl + " " + res.model_names[j]
	for(j=i;j<=rows(res.tab);j++) incl = incl + " " + res.model_names[j]
	st_local("mn",mn)
	st_local("stat",res.statistic)
	st_numscalar("k",res.k)
	st_numscalar("N_models",rows(res.tab))
	st_numscalar("included",length(res.included))
	st_numscalar("excluded",length(res.excluded))
	st_strscalar("incl",incl)
	st_strscalar("excl",excl)
}

// Optimal block length from blockboot 1.6
// declarations added for matastrict
// modify to take x directly

void bstar2(
			real colvector x,
//			string scalar selvar,
			string scalar tauto
)
{
//	real vector x
	real scalar BstarSB, BstarCB
// cfb declarations added for matastrict
	external real scalar lblock
    real scalar T, Kn, mmax, Bmax, c, rhokcrit, mean_x, var_x, k, T1
	real scalar sumsignif, mhatindex, mhat, M, Ghat, DCBhat, DSBhat
	real matrix rhok, insignif, runsuminsignif, x1, x2, signif, acov, kk
	real matrix lam, valueindex
	
//	x = st_data(., vname, selvar)
	T = length(x)

	Kn = (5 > ceil(log10(length(x))) ? 5 : ceil(log10(T))) 
	mmax = ceil(sqrt(T))+Kn
	Bmax = ceil(3*sqrt(T) < T/3 ? 3*sqrt(T) : T/3)
	c = invnormal(0.975)
	
	rhokcrit = c*sqrt(log10(T)/T)

	// Computes autocorrelation
	mean_x = mean(x)
	var_x = mean((x :- mean_x) :^ 2)

	rhok = J(mmax, 1, .)
	insignif = J(mmax, 1, .)
	runsuminsignif = J(mmax-Kn+1, 1, .)
	
    for (k = 1; k <= mmax; k++) {
        x1 = x[1::(T - k)]
		T1 = length(x1)
        x2 = x[(1 + k)::T]
        rhok[k,1] = (mean((x1 :- mean_x) :* (x2 :- mean_x)) / var_x)*(T1/T)
    }
		
	for (k = 1; k <= mmax; k++) {
		insignif[k,1] = abs(rhok[k,1]) < rhokcrit	// Find insignificant autocorr
	}
	
	signif = 1 :- insignif	// Find significant autocorr
	sumsignif = sum(signif)
	
	for (k = 1; k <= mmax-Kn+1; k++) {
		runsuminsignif[k,1] = sum(insignif[(k::(k+Kn-1)),1])	// Running sum of Kn elements
	}
	
	maxindex((runsuminsignif :== Kn), 1, valueindex=., .)
	mhatindex = valueindex[1,1]

	if (mhatindex > 1) {
		mhat = mhatindex
	}
	else if (sumsignif > 0) {
		minindex((sumsignif :== 0), 1, valueindex=., .)
		mhatindex = valueindex[1,1]
		mhat = mhatindex
	}
	else if (sumsignif == 0) {
		mhat = 1
	}

	M = (2*mhat > mmax ? mmax : 2*mhat)
	
	// Computes autocovariances
	
	acov = J(2 * M + 1, 1, .)  // Preallocate result vector

    for (k = -M; k <= M; k++) {
        if (k < 0) {
            // Negative lag
            x1 = x[(1 - k)::T]
            x2 = x[1::(T + k)]
			T1 = length(x2)
        } else if (k > 0) {
            // Positive lag
            x1 = x[1::(T - k)]
			T1 = length(x1)
            x2 = x[(1 + k)::T]
        } else {
            // Zero lag
            x1 = x
			T1 = length(x1)
            x2 = x
        }
        acov[M + 1 + k] = (mean((x1 :- mean_x) :* (x2 :- mean_x)))*(T1/T)
    }
//    acov
	
	kk = (-M::M)
	lam = (abs(kk:/M):>=0):*(abs(kk:/M):<0.5):+2:*(1:-abs(kk:/M)):*(abs(kk:/M):>=0.5):*(abs(kk:/M):<=1)
	Ghat = sum(lam :* abs(kk) :* acov)
	DCBhat = (4/3)*sum(lam :* acov)^2
	DSBhat = 2*sum(lam :* acov)^2
	BstarSB = ((2*Ghat^2)/DSBhat)^(1/3)*T^(1/3)
	BstarCB = ((2*(Ghat^2)/DCBhat)^(1/3))*(T^(1/3))

	BstarSB = (BstarSB > Bmax ? Bmax : (BstarSB < 1 ? 1 : round(BstarSB)))
	BstarCB = (BstarCB > Bmax ? Bmax : (BstarCB < 1 ? 1 : ceil(BstarCB)))
	
//	st_numscalar("_lblk", BstarCB)
	lblock = BstarCB
	if (tauto=="sbb") { 
		lblock = BstarSB
//		st_numscalar("_lblk",BstarSB) 
	} 
}

// circular block bootstrap extracted from blockboot.ado
void cbbindx2(
				real scalar iniobs,
				real scalar endobs,
				real scalar nobs,
				real scalar lbck
				)
{
	external real colvector indices
	real scalar i
	// iniobs endobs nobs lbck
	indices = J(nobs,1,0)
	for (i=1;i<=nobs;i=i+lbck) {
		indices[i,1] = runiformint(1,1, iniobs, endobs)
	}
	for (i=1;i<=nobs;i++) {
		indices[i,1] = indices[i,1]:>0 ? indices[i,1] : ///
		(indices[i-1,1]:<endobs ? indices[i-1,1]+1 : iniobs)
	}
}


// stationary block bootstrap extracted from blockboot.ado
void sbbindx2(
				real scalar iniobs,
				real scalar endobs,
				real scalar nobs,
				real scalar lbck
				)
{
	external real colvector indices
	real scalar prob, i

	prob = 1/lbck	// Define the probability of a new block
	//nobs, prob, maxval
	indices = J(nobs,1,0)
	indices = runiformint(nobs,1, iniobs, endobs) :* (runiform(nobs, 1) :< prob)
	indices[1,1]= runiformint(1,1, iniobs, endobs)
	for (i=1;i<=nobs;i++) {
		indices[i] = indices[i]:>0 ? indices[i] : ///
		(indices[i-1]:<endobs ? indices[i-1]+1 : iniobs)
	}
}

// moving block bootstrap extracted from blockboot.ado
void mbbindx2(
				real scalar iniobs,
				real scalar endobs,
				real scalar nobs,
				real scalar lbck
				)
{
	external real colvector indices
	real scalar i
	//nobs, lbck, maxval
	indices = J(nobs,1,0)
	for (i=1;i<=nobs;i=i+lbck) {
		indices[i,1] = runiformint(1,1, iniobs, nobs-lbck+1)
	}
	for (i=1;i<=nobs;i++) {
		indices[i,1] = indices[i,1]:>0 ? indices[i,1] : indices[i-1,1]+1
	}
}

end
