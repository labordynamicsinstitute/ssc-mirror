*! aardl — Augmented ARDL cointegration analysis (8 model types)
*! Version 2.0.0 — 2026-08-28
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Independent Researcher
*!
*! Model types
*!   aardl    — Augmented ARDL (Sam, McNown & Goh 2019)
*!   baardl   — Bootstrap Augmented ARDL
*!   faardl   — Fourier Augmented ARDL
*!   fbaardl  — Fourier Bootstrap Augmented ARDL
*!   nardl    — Augmented NARDL (asymptotic)
*!   fanardl  — Fourier Augmented NARDL
*!   banardl  — Bootstrap Augmented NARDL
*!   fbanardl — Fourier Bootstrap Augmented NARDL
*!
*! References
*!   Sam, McNown & Goh (2019), Economic Modelling 80, 130-141
*!       <doi:10.1016/j.econmod.2018.11.001>
*!   McNown, Sam & Goh (2018), Applied Economics 50, 1509-1521
*!       <doi:10.1080/00036846.2017.1366643>
*!   Bertelli, Vacca & Zoia (2022), Economic Modelling 116, 105987
*!       <doi:10.1016/j.econmod.2022.105987>
*!   Yilanci, Bozoklu & Gorus (2020), Sustainable Cities and Society 60, 102244
*!       <doi:10.1016/j.scs.2020.102244>
*!   Shin, Yu & Greenwood-Nimmo (2014), in Festschrift in Honor of Peter Schmidt
*!       <doi:10.1007/978-1-4899-8008-3_9>
*!   Pesaran, Shin & Smith (2001), J. Applied Econometrics 16, 289-326
*!       <doi:10.1002/jae.616>
*!   Kripfganz & Schneider (2020), Oxford Bulletin of Economics and Statistics
*!       82, 1456-1481 <doi:10.1111/obes.12377>
*!   Brown, Durbin & Evans (1975), JRSS-B 37, 149-192
*!   Newey & West (1987), Econometrica 55, 703-708 <doi:10.2307/1913610>

capture program drop aardl
program define aardl, eclass sortpreserve
    version 17

    if replay() {
        if "`e(cmd)'" != "aardl" error 301
        _coef_table_header
        di as txt ""
        _coef_table
        exit
    }

    // =====================================================================
    // 1. SYNTAX
    // =====================================================================
    syntax varlist(min=2 ts fv) [if] [in], ///
        [                                  ///
        TYpe(string)                       /// model type (default aardl)
        DECompose(varlist ts)              /// NARDL partial-sum variables
        MAXLag(integer 4)                  /// maximum lag order
        MAXk(real 5)                       /// maximum Fourier frequency
        KSTep(real 0.1)                    /// Fourier grid increment
        KMOde(string)                      /// auto | integer | fractional
        IC(string)                         /// aic | bic | hqic
        SEARch(string)                     /// full | sequential
        REPS(integer 999)                  /// bootstrap replications
        Level(cilevel)                     ///
        HORizon(integer 24)                /// multiplier horizon
        BANds(integer 500)                 /// draws for multiplier CI bands
        VCE(string)                        /// ols | robust | hac | newey
        LAGs(integer -1)                   /// HAC bandwidth
        case(integer 3)                    /// PSS case 1-5
        Bootstrap(string)                  /// mcnown | bvz
        XDGP(string)                       /// rw | vecm : marginal x process
        GRAPHPrefix(string)                ///
        NOFourier NODIag NODYNmult NOADVanced NOSTABility ///
        NOTable NOHEader NOGraph NOBOUNDSgraph            ///
        ]

    // ---- model type ------------------------------------------------------
    if "`type'" == "" local type "aardl"
    local type = lower("`type'")
    if !inlist("`type'", "aardl", "baardl", "faardl", "fbaardl", ///
                         "nardl", "fanardl", "banardl", "fbanardl") {
        di as err "type() must be one of: aardl, baardl, faardl, fbaardl,"
        di as err "                       nardl, fanardl, banardl, fbanardl"
        exit 198
    }
    local is_nardl     = inlist("`type'", "nardl", "fanardl", "banardl", "fbanardl")
    local has_bootstrap = inlist("`type'", "baardl", "fbaardl", "banardl", "fbanardl")
    local has_fourier   = inlist("`type'", "faardl", "fbaardl", "fanardl", "fbanardl")
    if "`nofourier'" != "" local has_fourier 0

    if `is_nardl' & "`decompose'" == "" {
        di as err "NARDL types require decompose()"
        exit 198
    }
    if !`is_nardl' & "`decompose'" != "" {
        di as err "decompose() is only for the NARDL types"
        exit 198
    }

    // ---- information criterion -------------------------------------------
    if "`ic'" == "" local ic "bic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic", "hqic") {
        di as err "ic() must be aic, bic or hqic"
        exit 198
    }

    // ---- search strategy --------------------------------------------------
    if "`search'" == "" local search "auto"
    local search = lower("`search'")
    if !inlist("`search'", "auto", "full", "sequential", "seq") {
        di as err "search() must be full, sequential or auto"
        exit 198
    }
    if "`search'" == "seq" local search "sequential"

    // ---- Fourier mode -----------------------------------------------------
    if "`kmode'" == "" local kmode "auto"
    local kmode = lower("`kmode'")
    if !inlist("`kmode'", "auto", "integer", "fractional") {
        di as err "kmode() must be auto, integer or fractional"
        exit 198
    }
    if `kstep' <= 0 | `kstep' > 1 {
        di as err "kstep() must be in (0, 1]"
        exit 198
    }
    if `has_fourier' & "`kmode'" == "integer" & `maxk' < 1 {
        di as err "kmode(integer) needs maxk() of at least 1"
        exit 198
    }

    // ---- bootstrap method -------------------------------------------------
    if "`bootstrap'" == "" local bootstrap "bvz"
    local bootstrap = lower("`bootstrap'")
    if !inlist("`bootstrap'", "mcnown", "bvz") {
        di as err "bootstrap() must be mcnown or bvz"
        exit 198
    }
    if "`xdgp'" == "" local xdgp "rw"
    local xdgp = lower("`xdgp'")
    if !inlist("`xdgp'", "rw", "vecm") {
        di as err "xdgp() must be rw or vecm"
        exit 198
    }
    if `reps' < 99 & `has_bootstrap' {
        di as txt "note: reps(`reps') is low; 999 or more is recommended for inference"
    }

    // ---- covariance estimator ---------------------------------------------
    if "`vce'" == "" local vce "ols"
    local vce = lower("`vce'")
    if "`vce'" == "newey" local vce "hac"
    if !inlist("`vce'", "ols", "robust", "hac") {
        di as err "vce() must be ols, robust, hac (= newey)"
        exit 198
    }
    local vcode = cond("`vce'"=="ols", 0, cond("`vce'"=="robust", 1, 2))

    // ---- other validation --------------------------------------------------
    if `maxlag' < 1 | `maxlag' > 12 {
        di as err "maxlag() must be between 1 and 12"
        exit 198
    }
    if !inlist(`case', 1, 2, 3, 4, 5) {
        di as err "case() must be 1, 2, 3, 4 or 5"
        exit 198
    }
    if `horizon' < 1 local horizon 24
    if "`level'" == "" local level = c(level)

    // =====================================================================
    // 2. SAMPLE
    // =====================================================================
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'
    if `nindep' < 1 {
        di as err "at least one independent variable is required"
        exit 198
    }

    qui tsset
    local timevar  "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    local tdelta   = r(tdelta)
    if "`panelvar'" != "" {
        di as err "aardl is for pure time-series data; this dataset is a panel"
        exit 198
    }

    marksample touse
    if "`decompose'" != "" markout `touse' `decompose'

    qui count if `touse'
    local T = r(N)
    if `T' < 30 {
        di as err "too few observations (`T'); aardl needs at least 30"
        exit 2001
    }

    // The bootstrap and the recursive-residual code both need a gap-free
    // sample, so refuse rather than return silently wrong numbers.
    qui summarize `timevar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    local expect = (`tmax' - `tmin')/`tdelta' + 1
    if abs(`T' - `expect') > 1e-6 {
        di as err "the estimation sample has internal gaps or missing values"
        di as err "(`T' usable observations spanning `expect' periods)."
        di as err "aardl requires a contiguous sample; fix the gaps or restrict"
        di as err "the sample with if/in to a gap-free window."
        exit 459
    }

    // =====================================================================
    // 3. AUXILIARY VARIABLES
    // =====================================================================
    capture drop _aardl_trend
    qui gen double _aardl_trend = (`timevar' - `tmin')/`tdelta' + 1 if `touse'
    label var _aardl_trend "aardl: linear trend / Fourier time index"

    tempvar one
    qui gen byte `one' = 1 if `touse'

    // ---- NARDL partial sums ------------------------------------------------
    local dec_names ""
    local allx ""
    local renamed ""
    if `is_nardl' {
        foreach xv of local decompose {
            local base = subinstr("`xv'", ".", "_", .)
            local pn "`base'_pos"
            local nn "`base'_neg"
            capture confirm variable `pn'
            local clash1 = (_rc == 0)
            capture confirm variable `nn'
            local clash2 = (_rc == 0)
            if `clash1' | `clash2' {
                local pn "_aardl_`base'_pos"
                local nn "_aardl_`base'_neg"
                local renamed "`renamed' `base'"
            }
            capture drop `pn'
            capture drop `nn'

            tempvar dx pp nn2
            qui gen double `dx'  = D.`xv' if `touse'
            qui gen double `pp'  = cond(missing(`dx'), 0, max(`dx', 0)) if `touse'
            qui gen double `nn2' = cond(missing(`dx'), 0, min(`dx', 0)) if `touse'
            qui gen double `pn' = sum(`pp')
            qui gen double `nn' = sum(`nn2')
            qui replace `pn' = . if !`touse'
            qui replace `nn' = . if !`touse'
            label var `pn' "aardl: positive partial sum of `xv'"
            label var `nn' "aardl: negative partial sum of `xv'"

            local dec_names "`dec_names' `base'"
            local dec_pos_`base' "`pn'"
            local dec_neg_`base' "`nn'"
            local allx "`allx' `pn' `nn'"
        }
        foreach xv of local indepvars {
            local isdec 0
            foreach dv of local decompose {
                if "`xv'" == "`dv'" local isdec 1
            }
            if !`isdec' local allx "`allx' `xv'"
        }
    }
    else {
        local allx "`indepvars'"
    }
    local K : word count `allx'

    // ---- deterministic block ----------------------------------------------
    local detreg ""
    local regopts ""
    if `case' == 1 local regopts "noconstant"
    if `case' >= 4 local detreg "_aardl_trend"

    // ---- estimation sample: fixed at maxlag lags for every candidate ------
    tempvar esample
    qui gen byte `esample' = (`touse' & _aardl_trend > `maxlag' + 1)
    qui count if `esample'
    local Nfix = r(N)
    if `Nfix' < 20 {
        di as err "maxlag(`maxlag') leaves only `Nfix' usable observations"
        exit 2001
    }

    // =====================================================================
    // 4. HEADER
    // =====================================================================
    if "`noheader'" == "" {
        local ttl "Augmented ARDL (A-ARDL)"
        if "`type'" == "baardl"   local ttl "Bootstrap Augmented ARDL (BA-ARDL)"
        if "`type'" == "faardl"   local ttl "Fourier Augmented ARDL (FA-ARDL)"
        if "`type'" == "fbaardl"  local ttl "Fourier Bootstrap Augmented ARDL (FBA-ARDL)"
        if "`type'" == "nardl"    local ttl "Augmented NARDL (A-NARDL)"
        if "`type'" == "fanardl"  local ttl "Fourier Augmented NARDL (FA-NARDL)"
        if "`type'" == "banardl"  local ttl "Bootstrap Augmented NARDL (BA-NARDL)"
        if "`type'" == "fbanardl" local ttl "Fourier Bootstrap Augmented NARDL (FBA-NARDL)"

        local casetxt "unrestricted intercept, no trend"
        if `case' == 1 local casetxt "no intercept, no trend"
        if `case' == 2 local casetxt "restricted intercept, no trend"
        if `case' == 4 local casetxt "unrestricted intercept, restricted trend"
        if `case' == 5 local casetxt "unrestricted intercept, unrestricted trend"

        di as txt ""
        di as txt "{hline 78}"
        di as res _col(3) "`ttl'"
        di as txt _col(3) "{it:Sam, McNown & Goh (2019) three-test framework}"
        di as txt "{hline 78}"
        di as txt _col(5) "Dependent variable" _col(30) ": " as res "`depvar'"
        if `is_nardl' {
            di as txt _col(5) "Decomposed variable(s)" _col(30) ": " as res "`decompose'"
        }
        di as txt _col(5) "Independent variable(s)" _col(30) ": " as res "`indepvars'"
        di as txt _col(5) "Time variable" _col(30) ": " as res "`timevar'" ///
           as txt " (" as res "`tmin'" as txt " to " as res "`tmax'" as txt ")"
        di as txt _col(5) "Observations" _col(30) ": " as res "`Nfix'" ///
           as txt " of `T' (maxlag = `maxlag')"
        di as txt _col(5) "Maximum lag order" _col(30) ": " as res "`maxlag'"
        di as txt _col(5) "Information criterion" _col(30) ": " as res upper("`ic'")
        di as txt _col(5) "PSS case" _col(30) ": " as res "Case `case'" ///
           as txt " (`casetxt')"
        local vtxt "conventional (OLS)"
        if "`vce'" == "robust" local vtxt "heteroskedasticity-robust (HC1)"
        if "`vce'" == "hac"    local vtxt "Newey-West HAC"
        di as txt _col(5) "Covariance estimator" _col(30) ": " as res "`vtxt'"
        if `has_fourier' {
            di as txt _col(5) "Fourier grid" _col(30) ": " as res ///
               "k = `kstep' ... `maxk'" as txt ", kmode(" as res "`kmode'" as txt ")"
        }
        if `has_bootstrap' {
            local bm "Bertelli, Vacca & Zoia (2022) conditional"
            if "`bootstrap'" == "mcnown" local bm "McNown, Sam & Goh (2018) unconditional"
            di as txt _col(5) "Bootstrap" _col(30) ": " as res "`bm'"
            di as txt _col(5) "Replications" _col(30) ": " as res "`reps'"
            local xd "unit root imposed on x"
            if "`xdgp'" == "vecm" local xd "estimated marginal VECM for x"
            di as txt _col(5) "Marginal x process" _col(30) ": " as res "`xd'"
        }
        di as txt "{hline 78}"
    }
    if "`renamed'" != "" {
        di as txt ""
        di as txt "note: partial sums for `renamed' were named with an _aardl_ prefix"
        di as txt "      because variables with the plain _pos/_neg names already exist."
    }

    // =====================================================================
    // 5. FOURIER FREQUENCY (step 1)
    // =====================================================================
    local kstar = 0
    local ktype ""
    local breaktype ""
    if `has_fourier' {
        _aardl_fourier `depvar', xvars(`allx') esample(`esample')          ///
            trendvar(_aardl_trend) nobs(`Nfix') maxlag(`maxlag')           ///
            maxk(`maxk') kstep(`kstep') kmode(`kmode') detvars(`detreg')   ///
            regopts(`regopts') graphprefix(`graphprefix') `nograph'
        local kstar     = r(kstar)
        local kint      = r(kint)
        local kfrac     = r(kfrac)
        local ktype     "`r(ktype)'"
        local breaktype "`r(breaktype)'"
        local detreg "`detreg' _aardl_sin _aardl_cos"
    }
    else {
        capture drop _aardl_sin
        capture drop _aardl_cos
    }

    // ---- deterministic block passed to the bootstrap engine --------------
    local detvars ""
    local conscol 0
    local trendcol 0
    local nd 0
    if `case' != 1 {
        local ++nd
        local conscol = `nd'
        local detvars "`detvars' `one'"
    }
    if `case' >= 4 {
        local ++nd
        local trendcol = `nd'
        local detvars "`detvars' _aardl_trend"
    }
    if `has_fourier' {
        local detvars "`detvars' _aardl_sin _aardl_cos"
        local nd = `nd' + 2
    }

    // =====================================================================
    // 6. LAG SELECTION (step 2) — every candidate on the SAME sample
    // =====================================================================
    local ncomb = 1
    forvalues i = 1/`K' {
        local ncomb = `ncomb'*(`maxlag'+1)
    }
    local nmodels = `maxlag'*`ncomb'
    local usesearch "`search'"
    if "`usesearch'" == "auto" {
        local usesearch = cond(`nmodels' <= 6000, "full", "sequential")
    }

    di as txt ""
    if "`usesearch'" == "full" {
        di as txt _col(3) "Selecting lag orders by " upper("`ic'") ///
           " (exhaustive search over `nmodels' models)..."
    }
    else {
        di as txt _col(3) "Selecting lag orders by " upper("`ic'") ///
           " (sequential search; exhaustive would need `nmodels' models)..."
    }

    tempname bestic
    scalar `bestic' = .
    local best_p 1
    forvalues i = 1/`K' {
        local best_q_`i' = 0
    }
    local nfit 0

    if "`usesearch'" == "full" {
        forvalues p = 1/`maxlag' {
            local cmax = `ncomb' - 1
            forvalues c = 0/`cmax' {
                local rem = `c'
                forvalues vi = 1/`K' {
                    local div 1
                    local left = `K' - `vi'
                    forvalues r = 1/`left' {
                        local div = `div'*(`maxlag'+1)
                    }
                    local q_`vi' = floor(`rem'/`div')
                    local rem = `rem' - `q_`vi''*`div'
                }
                local ql ""
                forvalues vi = 1/`K' {
                    local ql "`ql' `q_`vi''"
                }
                _aardl_fitic, depvar(`depvar') xvars(`allx') detreg(`detreg') ///
                    p(`p') qlist(`ql') esample(`esample') ic(`ic') regopts(`regopts')
                local ++nfit
                if r(ok) {
                    if r(icval) < scalar(`bestic') | missing(scalar(`bestic')) {
                        scalar `bestic' = r(icval)
                        local best_p = `p'
                        forvalues vi = 1/`K' {
                            local best_q_`vi' = `q_`vi''
                        }
                    }
                }
            }
        }
    }
    else {
        // (a) p with every q at its maximum
        local ql ""
        forvalues vi = 1/`K' {
            local ql "`ql' `maxlag'"
            local best_q_`vi' = `maxlag'
        }
        forvalues p = 1/`maxlag' {
            _aardl_fitic, depvar(`depvar') xvars(`allx') detreg(`detreg') ///
                p(`p') qlist(`ql') esample(`esample') ic(`ic') regopts(`regopts')
            local ++nfit
            if r(ok) {
                if r(icval) < scalar(`bestic') | missing(scalar(`bestic')) {
                    scalar `bestic' = r(icval)
                    local best_p = `p'
                }
            }
        }
        // (b) two sweeps over the individual q orders
        forvalues sweep = 1/2 {
            forvalues vi = 1/`K' {
                forvalues qq = 0/`maxlag' {
                    local ql ""
                    forvalues w = 1/`K' {
                        if `w' == `vi' local ql "`ql' `qq'"
                        else           local ql "`ql' `best_q_`w''"
                    }
                    _aardl_fitic, depvar(`depvar') xvars(`allx') detreg(`detreg') ///
                        p(`best_p') qlist(`ql') esample(`esample') ic(`ic')       ///
                        regopts(`regopts')
                    local ++nfit
                    if r(ok) {
                        if r(icval) < scalar(`bestic') | missing(scalar(`bestic')) {
                            scalar `bestic' = r(icval)
                            local best_q_`vi' = `qq'
                        }
                    }
                }
            }
        }
    }

    if missing(scalar(`bestic')) {
        di as err "no ARDL model could be estimated; check the data and maxlag()"
        exit 498
    }

    local qlist ""
    local lagstr "`best_p'"
    forvalues vi = 1/`K' {
        local qlist "`qlist' `best_q_`vi''"
        local lagstr "`lagstr',`best_q_`vi''"
    }
    di as txt _col(5) "Models estimated: " as res "`nfit'" ///
       as txt "   best " upper("`ic'") " = " as res %12.4f scalar(`bestic')

    // =====================================================================
    // 7. FINAL ESTIMATION
    // =====================================================================
    _aardl_reglist, depvar(`depvar') xvars(`allx') detreg(`detreg') ///
        p(`best_p') qlist(`qlist')
    local rhs "`r(rhs)'"

    qui regress D.`depvar' `rhs' if `esample', `regopts'
    tempname bols Vols
    local nobs  = e(N)
    local df_m  = e(df_m)
    local df_r  = e(df_r)
    local r2    = e(r2)
    local r2_a  = e(r2_a)
    local ll    = e(ll)
    local mss   = e(mss)
    local rss   = e(rss)
    local rmse  = e(rmse)
    local Fmod  = e(F)
    local npar  = e(rank)
    local aicv  = -2*`ll' + 2*`npar'
    local bicv  = -2*`ll' + `npar'*ln(`nobs')
    local hqicv = -2*`ll' + 2*`npar'*ln(ln(`nobs'))

    tempvar resid fitted
    qui predict double `resid', residuals
    qui predict double `fitted', xb

    // keep the OLS fit available for estat-based diagnostics
    capture estimates drop _aardl_ols
    estimates store _aardl_ols

    // ---- HAC bandwidth ----------------------------------------------------
    local hlag = `lags'
    if `hlag' < 0 {
        local hlag = floor(4*(`nobs'/100)^(2/9))
        if `hlag' < 1 local hlag 1
    }

    // ---- inference fit ----------------------------------------------------
    if "`vce'" == "robust" {
        qui regress D.`depvar' `rhs' if `esample', `regopts' vce(robust)
    }
    else if "`vce'" == "hac" {
        qui newey D.`depvar' `rhs' if `esample', lag(`hlag') `regopts'
    }
    mat `bols' = e(b)
    mat `Vols' = e(V)
    capture estimates drop _aardl_inf
    estimates store _aardl_inf

    // =====================================================================
    // 8. COINTEGRATION TESTS
    // =====================================================================
    local fovterms "L.`depvar'"
    local findterms ""
    foreach xv of local allx {
        local fovterms  "`fovterms' L.`xv'"
        local findterms "`findterms' L.`xv'"
    }
    if `case' == 2 local fovterms "`fovterms' _cons"
    if `case' == 4 local fovterms "`fovterms' _aardl_trend"

    qui test `fovterms'
    local Fov = r(F)
    if missing(`Fov') local Fov = r(chi2)/r(df)
    local Fov_p = r(p)

    local alpha = _b[L.`depvar']
    local t_DV  = _b[L.`depvar']/_se[L.`depvar']

    qui test `findterms'
    local Find = r(F)
    if missing(`Find') local Find = r(chi2)/r(df)
    local Find_p = r(p)

    // =====================================================================
    // 9. EC REPRESENTATION (delta method) AND ereturn post
    // =====================================================================
    local ia = colnumb(`bols', "L.`depvar'")
    local ilr ""
    foreach xv of local allx {
        local cnm "L.`xv'"
        local cpos = colnumb(`bols', "`cnm'")
        local ilr "`ilr' `cpos'"
    }
    if `case' == 2 {
        local cpos = colnumb(`bols', "_cons")
        local ilr "`ilr' `cpos'"
    }
    if `case' == 4 {
        local cpos = colnumb(`bols', "_aardl_trend")
        local ilr "`ilr' `cpos'"
    }
    local nlrp : word count `ilr'

    tempname ILR
    mat `ILR' = J(1, `nlrp', .)
    local w 0
    foreach c of local ilr {
        local ++w
        mat `ILR'[1,`w'] = `c'
    }

    mata: _aardl_ec("`bols'", "`Vols'", `ia', "`ILR'")
    tempname bec Vec PERM
    mat `bec'  = r(bec)
    mat `Vec'  = r(Vec)
    mat `PERM' = r(perm)

    // ---- names and equations ----------------------------------------------
    local oldnames : colnames `bols'
    local newnames "L.`depvar'"
    local eqn      "ADJ"
    foreach xv of local allx {
        local newnames "`newnames' `xv'"
        local eqn      "`eqn' LR"
    }
    if `case' == 2 {
        local newnames "`newnames' _cons"
        local eqn      "`eqn' LR"
    }
    if `case' == 4 {
        local newnames "`newnames' _aardl_trend"
        local eqn      "`eqn' LR"
    }
    local ncols = colsof(`bols')
    forvalues j = 1/`ncols' {
        local keep 1
        if `j' == `ia' local keep 0
        foreach c of local ilr {
            if `j' == `c' local keep 0
        }
        if `keep' {
            local nm : word `j' of `oldnames'
            local newnames "`newnames' `nm'"
            local eqn      "`eqn' SR"
        }
    }

    mat colnames `bec' = `newnames'
    mat colnames `Vec' = `newnames'
    mat rownames `Vec' = `newnames'
    mat coleq    `bec' = `eqn'
    mat coleq    `Vec' = `eqn'
    mat roweq    `Vec' = `eqn'

    // ---- error-correction term --------------------------------------------
    tempvar ect
    qui gen double `ect' = `depvar' if `esample'
    local jj 0
    foreach xv of local allx {
        local ++jj
        local lrc = `bec'[1, 1+`jj']
        qui replace `ect' = `ect' - `lrc'*`xv' if `esample'
    }
    if `case' == 2 {
        qui replace `ect' = `ect' - `bec'[1, 1+`nlrp']*1 if `esample'
    }
    label var `ect' "aardl: error-correction term"

    // =====================================================================
    // 10. COEFFICIENT TABLE
    // =====================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "ARDL(`lagstr') regression, EC representation"
    di as txt "{hline 78}"
    di as txt _col(5) "Dependent lag p" _col(45) as res %8.0f `best_p'
    local vi 0
    foreach xv of local allx {
        local ++vi
        di as txt _col(5) "`xv' lag q" _col(45) as res %8.0f `best_q_`vi''
    }
    if `has_fourier' {
        di as txt _col(5) "Fourier frequency k*" _col(45) as res %8.2f `kstar' ///
           as txt "   (`ktype', `breaktype' break)"
    }
    di as txt _col(5) "Observations" _col(45) as res %8.0f `nobs'
    di as txt _col(5) "R-squared" _col(45) as res %8.4f `r2'
    di as txt _col(5) "Adjusted R-squared" _col(45) as res %8.4f `r2_a'
    di as txt _col(5) "Log likelihood" _col(45) as res %12.4f `ll'
    di as txt _col(5) "AIC" _col(45) as res %12.4f `aicv'
    di as txt _col(5) "BIC" _col(45) as res %12.4f `bicv'
    di as txt _col(5) "HQIC" _col(45) as res %12.4f `hqicv'
    di as txt _col(5) "Root MSE" _col(45) as res %12.6f `rmse'
    if "`vce'" == "hac" {
        di as txt _col(5) "Newey-West lag" _col(45) as res %8.0f `hlag'
    }
    di as txt "{hline 78}"

    // =====================================================================
    // 11. THE THREE TESTS
    // =====================================================================
    local boot_ok 0
    tempname BND
    mat `BND' = J(3, 3, .)

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Table 3: Augmented ARDL cointegration tests"
    di as txt _col(5) "{it:Sam, McNown & Goh (2019) three-test framework}"
    di as txt "{hline 78}"

    if `has_bootstrap' {
        di as txt ""
        di as txt _col(5) "Bootstrapping the null distribution (`reps' replications)..."
        tempname QM
        mat `QM' = J(1, `K', .)
        local vi 0
        forvalues vi = 1/`K' {
            mat `QM'[1,`vi'] = `best_q_`vi''
        }
        local s0 = `maxlag' + 1

        capture noisily _aardl_bootstrap, depvar(`depvar') xvars(`allx')   ///
            detvars(`detvars') p(`best_p') qmat(`QM') s0(`s0')            ///
            reps(`reps') bmethod(`bootstrap') caseval(`case')             ///
            vcode(`vcode') hlag(`hlag') conscol(`conscol')                ///
            trendcol(`trendcol') touse(`touse') xdgp(`xdgp')
        if _rc == 0 {
            local boot_ok 1
            local Fov_bp   = r(Fov_bp)
            local tDV_bp   = r(tDV_bp)
            local Find_bp  = r(Find_bp)
            foreach a in 10 5 1 {
                local Fov_cv`a'  = r(Fov_cv`a')
                local tDV_cv`a'  = r(tDV_cv`a')
                local Find_cv`a' = r(Find_cv`a')
            }
            local nvalid = r(nvalid)

            di as txt ""
            di as txt "  {hline 72}"
            di as txt _col(5) "Test" _col(19) "Statistic" _col(32) "Boot. p" ///
               _col(43) "10% cv" _col(54) "5% cv" _col(64) "1% cv"
            di as txt "  {hline 72}"
            di as txt _col(5) "F_overall" _col(17) as res %10.4f `Fov' ///
               _col(30) %8.4f `Fov_bp' _col(40) %9.4f `Fov_cv10' ///
               _col(51) %9.4f `Fov_cv5' _col(61) %9.4f `Fov_cv1' _c
            _aardl_stars `Fov_bp'
            di as txt _col(5) "t_DV" _col(17) as res %10.4f `t_DV' ///
               _col(30) %8.4f `tDV_bp' _col(40) %9.4f `tDV_cv10' ///
               _col(51) %9.4f `tDV_cv5' _col(61) %9.4f `tDV_cv1' _c
            _aardl_stars `tDV_bp'
            di as txt _col(5) "F_ind" _col(17) as res %10.4f `Find' ///
               _col(30) %8.4f `Find_bp' _col(40) %9.4f `Find_cv10' ///
               _col(51) %9.4f `Find_cv5' _col(61) %9.4f `Find_cv1' _c
            _aardl_stars `Find_bp'
            di as txt "  {hline 72}"
            di as txt _col(5) "{it:F tests are upper-tail, t_DV is lower-tail.}"
            di as txt _col(5) "{it:Valid replications: `nvalid' of `reps'.}"

            mat `BND'[1,1] = `Fov'
            mat `BND'[1,2] = 0
            mat `BND'[1,3] = `Fov_cv5'
            mat `BND'[2,1] = `t_DV'
            mat `BND'[2,2] = `tDV_cv5'
            mat `BND'[2,3] = 0
            mat `BND'[3,1] = `Find'
            mat `BND'[3,2] = 0
            mat `BND'[3,3] = `Find_cv5'

            local sig_fov  = (`Fov_bp'  < 0.05)
            local sig_tdv  = (`tDV_bp'  < 0.05)
            local sig_find = (`Find_bp' < 0.05)
        }
        else {
            di as err "the bootstrap failed; falling back to asymptotic bounds"
            local has_bootstrap 0
        }
    }

    if !`boot_ok' {
        // ---- asymptotic bounds ------------------------------------------
        di as txt ""
        di as txt "  {hline 72}"
        di as txt _col(5) "Test" _col(20) "Statistic" _col(35) "I(0) 5%" ///
           _col(48) "I(1) 5%" _col(61) "Decision"
        di as txt "  {hline 72}"

        local f_i0 = .
        local f_i1 = .
        local t_i0 = .
        local t_i1 = .
        capture qui ardlbounds, case(`case') stat(f) n(`nobs') k(`K')
        if _rc == 0 {
            tempname FCV
            mat `FCV' = r(cvmat)
            local f_i0 = el(`FCV',1,3)
            local f_i1 = el(`FCV',1,4)
        }
        capture qui ardlbounds, case(`case') stat(t) n(`nobs') k(`K')
        if _rc == 0 {
            tempname TCV
            mat `TCV' = r(cvmat)
            local t_i0 = el(`TCV',1,3)
            local t_i1 = el(`TCV',1,4)
        }
        local d_fov = "inconclusive"
        if `Fov' > `f_i1' & !missing(`f_i1') local d_fov "reject H0"
        if `Fov' < `f_i0' & !missing(`f_i0') local d_fov "do not reject"
        local d_tdv = "inconclusive"
        if `t_DV' < `t_i1' & !missing(`t_i1') local d_tdv "reject H0"
        if `t_DV' > `t_i0' & !missing(`t_i0') local d_tdv "do not reject"

        di as txt _col(5) "F_overall" _col(18) as res %10.4f `Fov' ///
           _col(33) %9.4f `f_i0' _col(46) %9.4f `f_i1' as txt _col(60) "`d_fov'"
        di as txt _col(5) "t_DV" _col(18) as res %10.4f `t_DV' ///
           _col(33) %9.4f `t_i0' _col(46) %9.4f `t_i1' as txt _col(60) "`d_tdv'"

        // ---- F_ind: Sam et al. (2019) tables, NOT the regression p-value --
        local s_i0 = .
        local s_i1 = .
        capture _aardl_samcv, caseval(`case') k(`K') n(`nobs')
        if _rc == 0 {
            if r(ok) {
                tempname SCV
                mat `SCV' = r(cvmat)
                local s_i0 = el(`SCV',2,1)
                local s_i1 = el(`SCV',2,2)
                local samapprox = r(approx)
                local samuse    = r(usecase)
                local samn      = r(nused)
            }
        }
        local d_find = "inconclusive"
        if `Find' > `s_i1' & !missing(`s_i1') local d_find "reject H0"
        if `Find' < `s_i0' & !missing(`s_i0') local d_find "do not reject"
        di as txt _col(5) "F_ind" _col(18) as res %10.4f `Find' ///
           _col(33) %9.4f `s_i0' _col(46) %9.4f `s_i1' as txt _col(60) "`d_find'"
        di as txt "  {hline 72}"

        if missing(`f_i0') {
            di as txt _col(5) "note: {bf:ardlbounds} is not installed, so the F and t bounds"
            di as txt _col(5) "      are unavailable.  Install it with"
            di as txt _col(5) "      {stata ssc install ardlbounds}"
        }
        else {
            di as txt _col(5) "{it:F and t bounds: Kripfganz & Schneider (2020) via ardlbounds.}"
        }
        if !missing(`s_i1') {
            local sn "N = `samn'"
            if "`samn'" == "." | "`samn'" == "" local sn "asymptotic (N > 80)"
            di as txt _col(5) "{it:F_ind bounds: Sam, McNown & Goh (2019) Table for Case `samuse',}"
            di as txt _col(5) "{it:k = `K', `sn'.}"
            if `samapprox' {
                di as txt _col(5) "{it:Case `case' is not tabulated by Sam et al.; Case `samuse' is used.}"
            }
        }
        else {
            di as txt _col(5) "note: no tabulated F_ind bounds for k = `K' (tables cover k = 1-7)."
            di as txt _col(5) "      Use a bootstrap type() for valid F_ind inference."
        }
        di as txt ""
        di as txt _col(5) "{it:The regression p-value for F_ind is NOT valid under I(1)}"
        di as txt _col(5) "{it:regressors and is deliberately not reported.}"

        mat `BND'[1,1] = `Fov'
        mat `BND'[1,2] = `f_i0'
        mat `BND'[1,3] = `f_i1'
        mat `BND'[2,1] = `t_DV'
        mat `BND'[2,2] = `t_i1'
        mat `BND'[2,3] = `t_i0'
        mat `BND'[3,1] = `Find'
        mat `BND'[3,2] = `s_i0'
        mat `BND'[3,3] = `s_i1'

        // significance uses the upper bound (conservative, purely-I(1) case)
        local sig_fov  = (`Fov'  > `f_i1') & !missing(`f_i1')
        local sig_tdv  = (`t_DV' < `t_i1') & !missing(`t_i1')
        local sig_find = (`Find' > `s_i1') & !missing(`s_i1')
    }

    // ---- conclusion --------------------------------------------------------
    // Sam et al. (2019), p.2 and p.14:
    //   insignificant t_DV -> degenerate lagged DEPENDENT variable case
    //                         (= degenerate case #2 of McNown et al. 2018)
    //   insignificant F_ind -> degenerate lagged INDEPENDENT variable(s) case
    //                         (= degenerate case #1 of McNown et al. 2018)
    di as txt ""
    if `sig_fov' & `sig_tdv' & `sig_find' {
        di as res _col(5) ">>> Cointegration: all three tests reject."
        local coint "cointegrated"
    }
    else if `sig_fov' & `sig_tdv' & !`sig_find' {
        di as res _col(5) ">>> Degenerate lagged independent variable(s) case"
        di as res _col(5) "    (degenerate case #1 of McNown et al. 2018)."
        di as txt _col(5) "    F_ov and t_DV reject but F_ind does not: the equation"
        di as txt _col(5) "    collapses to a generalised Dickey-Fuller regression and"
        di as txt _col(5) "    `depvar' is I(0).  No cointegration."
        local coint "degenerate_indep"
    }
    else if `sig_fov' & !`sig_tdv' & `sig_find' {
        di as res _col(5) ">>> Degenerate lagged dependent variable case"
        di as res _col(5) "    (degenerate case #2 of McNown et al. 2018)."
        di as txt _col(5) "    F_ov and F_ind reject but t_DV does not.  No cointegration."
        local coint "degenerate_dep"
    }
    else {
        di as res _col(5) ">>> No cointegration."
        local coint "no_cointegration"
    }
    di as txt "{hline 78}"

    // =====================================================================
    // 12. NARDL ASYMMETRY TESTS
    // =====================================================================
    if `is_nardl' {
        di as txt ""
        di as txt "{hline 78}"
        di as res _col(5) "Table 3b: Asymmetry tests (Wald)"
        di as txt _col(5) "{it:Shin, Yu & Greenwood-Nimmo (2014)}"
        di as txt "{hline 78}"
        di as txt _col(5) "Variable" _col(24) "Horizon" _col(40) "Statistic" ///
           _col(55) "p-value"
        di as txt "  {hline 72}"
        foreach base of local dec_names {
            local pn "`dec_pos_`base''"
            local nn "`dec_neg_`base''"

            // long run: beta+ = beta- is equivalent to pi+ = pi- (common alpha)
            capture qui test L.`pn' = L.`nn'
            if _rc == 0 {
                local w1 = r(F)
                if missing(`w1') local w1 = r(chi2)
                di as txt _col(5) "`base'" _col(24) "Long run" _col(38) ///
                   as res %10.4f `w1' _col(53) %10.4f r(p) _c
                _aardl_stars `=r(p)'
            }

            // short run: sum of the Dx+ coefficients = sum of the Dx- ones
            local ip 0
            local inn 0
            local w 0
            foreach xv of local allx {
                local ++w
                if "`xv'" == "`pn'" local ip  = `w'
                if "`xv'" == "`nn'" local inn = `w'
            }
            local qp : word `ip'  of `qlist'
            local qn : word `inn' of `qlist'
            local sp ""
            forvalues j = 0/`qp' {
                if `j' == 0 local sp "`sp' + _b[D.`pn']"
                else        local sp "`sp' + _b[L`j'.D.`pn']"
            }
            local sn ""
            forvalues j = 0/`qn' {
                if `j' == 0 local sn "`sn' + _b[D.`nn']"
                else        local sn "`sn' + _b[L`j'.D.`nn']"
            }
            local sp = substr("`sp'", 3, .)
            local sn = substr("`sn'", 3, .)
            capture qui testnl (`sp') = (`sn')
            if _rc == 0 {
                local w2 = r(chi2)
                di as txt _col(5) "`base'" _col(24) "Short run" _col(38) ///
                   as res %10.4f `w2' _col(53) %10.4f r(p) _c
                _aardl_stars `=r(p)'
            }
        }
        di as txt "  {hline 72}"
        di as txt _col(5) "{it:Long run: H0 pi+ = pi-.  Short run: H0 sum(omega+) = sum(omega-).}"
        di as txt ""
    }

    // =====================================================================
    // 13. DIAGNOSTICS
    // =====================================================================
    tempname DIAG
    local havediag 0
    qui estimates restore _aardl_ols
    if "`nodiag'" == "" {
        capture noisily _aardl_diagtest `resid', esample(`esample')
        if _rc == 0 {
            capture mat `DIAG' = r(diag)
            if _rc == 0 local havediag 1
        }
    }

    // =====================================================================
    // 14. STABILITY: CUSUM AND CUSUMSQ
    // =====================================================================
    qui estimates restore _aardl_ols
    local cusum_v ""
    local cusumsq_v ""
    if "`nostability'" == "" {
        local cons1 = cond(`case'==1, 0, 1)
        capture noisily _aardl_stability `rhs', depvar(D.`depvar')       ///
            esample(`esample') timevar(`timevar') constant(`cons1')      ///
            graphprefix(`graphprefix') `nograph'
        if _rc == 0 {
            local cusum_v   "`r(cusum_verdict)'"
            local cusumsq_v "`r(cusumsq_verdict)'"
        }
    }

    // =====================================================================
    // 15. DYNAMIC MULTIPLIERS
    // =====================================================================
    qui estimates restore _aardl_inf
    if "`nodynmult'" == "" {
        local pairsopt ""
        if `is_nardl' local pairsopt "pairs(`dec_names')"
        capture noisily _aardl_dynmult, depvar(`depvar') shocks(`allx')  ///
            qlist(`qlist') plags(`best_p') horizon(`horizon')            ///
            bands(`bands') level(`level') `pairsopt'                     ///
            graphprefix(`graphprefix') `nograph'
    }

    // =====================================================================
    // 16. ADVANCED ANALYSIS
    // =====================================================================
    qui estimates restore _aardl_inf
    local halflife = .
    local domroot  = .
    if "`noadvanced'" == "" {
        capture noisily _aardl_advanced, depvar(`depvar') xvars(`allx')  ///
            plags(`best_p') horizon(`horizon') kstar(`kstar')            ///
            level(`level') caseval(`case') trendvar(_aardl_trend)        ///
            graphprefix(`graphprefix') `nograph'
        if _rc == 0 {
            local halflife = r(halflife)
            local domroot  = r(domroot)
        }
    }

    // =====================================================================
    // 17. GRAPHS
    // =====================================================================
    if "`nograph'" == "" {
        tempvar dyv
        qui gen double `dyv' = D.`depvar' if `esample'
        local bootopt ""
        if `boot_ok' {
            capture confirm matrix _aardl_bootdist
            if _rc == 0 {
                local bootopt "bootmat(_aardl_bootdist) bootstats(`Fov' `t_DV' `Find')"
            }
        }
        local bndopt "boundsmat(`BND')"
        if "`noboundsgraph'" != "" local bndopt ""
        capture noisily _aardl_graphs, resid(`resid') fitted(`fitted')   ///
            dy(`dyv') esample(`esample') timevar(`timevar') ect(`ect')   ///
            depvar(`depvar') graphprefix(`graphprefix') `bndopt' `bootopt'
    }

    // =====================================================================
    // 18. POST RESULTS
    // =====================================================================
    tempname bECM VECM
    mat `bECM' = `bols'
    mat `VECM' = `Vols'

    ereturn post `bec' `Vec', esample(`esample') depname(D.`depvar') dof(`df_r')

    ereturn scalar N      = `nobs'
    ereturn scalar N_full = `T'
    ereturn scalar df_m   = `df_m'
    ereturn scalar df_r   = `df_r'
    ereturn scalar r2     = `r2'
    ereturn scalar r2_a   = `r2_a'
    ereturn scalar ll     = `ll'
    ereturn scalar mss    = `mss'
    ereturn scalar rss    = `rss'
    ereturn scalar rmse   = `rmse'
    ereturn scalar F      = `Fmod'
    ereturn scalar aic    = `aicv'
    ereturn scalar bic    = `bicv'
    ereturn scalar hqic   = `hqicv'
    ereturn scalar case   = `case'
    ereturn scalar maxlag = `maxlag'
    ereturn scalar p      = `best_p'
    ereturn scalar kstar  = `kstar'
    ereturn scalar hlag   = `hlag'
    ereturn scalar nmodels = `nfit'
    ereturn scalar ecm_coef = `alpha'
    ereturn scalar horizon  = `horizon'
    ereturn scalar level    = `level'
    if `halflife' < . ereturn scalar halflife = `halflife'
    if `domroot'  < . ereturn scalar domroot  = `domroot'

    ereturn scalar F_pss = `Fov'
    ereturn scalar t_pss = `t_DV'
    ereturn scalar F_ind = `Find'
    if `boot_ok' {
        ereturn scalar reps    = `reps'
        ereturn scalar Fov_bp  = `Fov_bp'
        ereturn scalar tDV_bp  = `tDV_bp'
        ereturn scalar Find_bp = `Find_bp'
        ereturn scalar Fov_cv5  = `Fov_cv5'
        ereturn scalar tDV_cv5  = `tDV_cv5'
        ereturn scalar Find_cv5 = `Find_cv5'
    }
    local vi 0
    foreach xv of local allx {
        local ++vi
        local cn = subinstr("`xv'", ".", "_", .)
        ereturn scalar q_`cn' = `best_q_`vi''
    }

    ereturn local cmd        "aardl"
    ereturn local cmdline    "aardl `0'"
    ereturn local depvar     "`depvar'"
    ereturn local indepvars  "`indepvars'"
    ereturn local allx       "`allx'"
    ereturn local ecmvars    "`rhs'"
    ereturn local fovterms   "`fovterms'"
    ereturn local findterms  "`findterms'"
    ereturn local type       "`type'"
    ereturn local ic         "`ic'"
    ereturn local vce        "`vce'"
    ereturn local vcetype    = cond("`vce'"=="hac", "Newey-West", ///
                              cond("`vce'"=="robust", "Robust", ""))
    ereturn local search     "`usesearch'"
    ereturn local model      "ec"
    ereturn local timevar    "`timevar'"
    ereturn local coint_status "`coint'"
    ereturn local predict    "aardl_p"
    ereturn local title      "ARDL(`lagstr') regression, EC representation"
    if `has_fourier' {
        ereturn local kmode     "`kmode'"
        ereturn local ktype     "`ktype'"
        ereturn local breaktype "`breaktype'"
    }
    if `is_nardl' {
        ereturn local decompose "`decompose'"
        ereturn local decnames  "`dec_names'"
    }
    if `has_bootstrap' {
        ereturn local bootstrap "`bootstrap'"
        ereturn local xdgp      "`xdgp'"
    }
    if "`cusum_v'" != "" {
        ereturn local cusum   "`cusum_v'"
        ereturn local cusumsq "`cusumsq_v'"
    }
    ereturn matrix b_ecm = `bECM'
    ereturn matrix V_ecm = `VECM'
    ereturn matrix bounds = `BND'
    if `havediag' ereturn matrix diagnostics = `DIAG'

    // ---- display the EC coefficient table ---------------------------------
    if "`notable'" == "" {
        di as txt ""
        _coef_table_header
        di as txt ""
        _coef_table, level(`level')
        di as txt _col(5) "{it:ADJ = speed of adjustment; LR = long-run coefficients}"
        di as txt _col(5) "{it:(delta method); SR = short-run coefficients.}"
    }

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "aardl complete."
    di as txt _col(5) "Kept variables: _aardl_trend" _c
    if `has_fourier' di as txt " _aardl_sin _aardl_cos" _c
    if `is_nardl' {
        foreach base of local dec_names {
            di as txt " `dec_pos_`base'' `dec_neg_`base''" _c
        }
    }
    di as txt ""
    di as txt _col(5) "The OLS companion fit is stored as {bf:_aardl_ols}."
    di as txt "{hline 78}"
end

// =========================================================================
// helper: build the regressor list for a given (p, q) configuration
// =========================================================================
capture program drop _aardl_reglist
program define _aardl_reglist, rclass
    version 17
    syntax , DEPvar(string) XVars(string) P(integer) QList(string) ///
        [ DETreg(string) ]

    local rhs "`detreg' L.`depvar'"
    foreach xv of local xvars {
        local rhs "`rhs' L.`xv'"
    }
    forvalues j = 1/`p' {
        local rhs "`rhs' L`j'.D.`depvar'"
    }
    local vi 0
    foreach xv of local xvars {
        local ++vi
        local q : word `vi' of `qlist'
        forvalues j = 0/`q' {
            if `j' == 0 local rhs "`rhs' D.`xv'"
            else        local rhs "`rhs' L`j'.D.`xv'"
        }
    }
    return local rhs "`rhs'"
end

// =========================================================================
// helper: fit one candidate model and return its information criterion
// =========================================================================
capture program drop _aardl_fitic
program define _aardl_fitic, rclass
    version 17
    syntax , DEPvar(string) XVars(string) P(integer) QList(string) ///
        ESample(varname) IC(string) [ DETreg(string) REGopts(string) ]

    _aardl_reglist, depvar(`depvar') xvars(`xvars') p(`p') qlist(`qlist') ///
        detreg(`detreg')
    local rhs "`r(rhs)'"

    capture qui regress D.`depvar' `rhs' if `esample', `regopts'
    if _rc {
        return scalar ok = 0
        exit
    }
    if e(N) < e(rank) + 10 {
        return scalar ok = 0
        exit
    }
    local n  = e(N)
    local k  = e(rank)
    local ll = e(ll)
    if "`ic'" == "aic"       local v = -2*`ll' + 2*`k'
    else if "`ic'" == "bic"  local v = -2*`ll' + `k'*ln(`n')
    else                     local v = -2*`ll' + 2*`k'*ln(ln(`n'))

    return scalar ok    = 1
    return scalar icval = `v'
    return scalar N     = `n'
end

// =========================================================================
// Mata: EC representation by the delta method
// =========================================================================
version 17
mata:
void _aardl_ec(string scalar bn, string scalar vn, real scalar ia,
               string scalar ilrn)
{
    real rowvector b, ilr, bnew
    real matrix    V, G, Vnew
    real scalar    k, nlr, i, j, r, a
    real colvector isSR

    b   = st_matrix(bn)
    V   = st_matrix(vn)
    ilr = st_matrix(ilrn)
    k   = cols(b)
    nlr = cols(ilr)
    a   = b[ia]

    // which original columns pass straight through as short-run terms
    isSR = J(k, 1, 1)
    isSR[ia] = 0
    for (i=1; i<=nlr; i++) isSR[ilr[i]] = 0

    G    = J(k, k, 0)
    bnew = J(1, k, 0)

    // row 1: the adjustment coefficient
    bnew[1] = a
    G[1,ia] = 1

    // rows 2..nlr+1: long-run coefficients -b_j/a
    for (i=1; i<=nlr; i++) {
        j = ilr[i]
        bnew[1+i]  = -b[j]/a
        G[1+i, j]  = -1/a
        G[1+i, ia] =  b[j]/(a*a)
    }

    // remaining rows: short-run coefficients, original order
    r = 1 + nlr
    for (j=1; j<=k; j++) {
        if (isSR[j]) {
            r++
            bnew[r] = b[j]
            G[r,j]  = 1
        }
    }

    Vnew = G*V*transposeonly(G)
    Vnew = makesymmetric(Vnew)

    st_matrix("r(bec)", bnew)
    st_matrix("r(Vec)", Vnew)
    st_matrix("r(perm)", G)
}
end
