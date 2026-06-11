*! qqtest 1.0.0 16may2026
*! Formal tests on the QQR surface beta(tau,theta) via the joint bootstrap
*! Author: Merwan Roudane
*!
*! Reads a draws file written by  qqr ... , bsave("draws.dta")
*! Tests:
*!   zero        H0: beta(tau,theta) = 0 for all (tau,theta)
*!   symmetry    H0: beta(tau,theta) = beta(1-tau,theta)   (symmetry in tau)
*!   constancy   H0: slope is constant across quantiles
*!                   dim(tau)   -> constant across tau within each theta
*!                   dim(theta) -> constant across theta within each tau
*! Statistics: KS (sup-t), Cramer-von Mises, Wald.  p-values from the joint
*! bootstrap (re-centered draws) and, for Wald, the chi2 asymptotic.

program qqtest, rclass
    version 14
    syntax [using/] [, TEST(string) DIM(string) ]

    if "`test'"=="" local test "zero"
    local test = lower("`test'")
    if !inlist("`test'", "zero", "symmetry", "constancy") {
        di as err "test() must be {bf:zero}, {bf:symmetry} or {bf:constancy}"
        exit 198
    }
    if "`dim'"=="" local dim "tau"
    local dim = lower("`dim'")
    if !inlist("`dim'", "tau", "theta") {
        di as err "dim() must be {bf:tau} or {bf:theta}"
        exit 198
    }

    if "`test'"=="zero"      local tcode 1
    if "`test'"=="symmetry"  local tcode 2
    if "`test'"=="constancy" local tcode 3
    local dcode = cond("`dim'"=="theta", 2, 1)

    preserve
    if `"`using'"' != "" qui use `"`using'"', clear

    foreach v in rep tau theta beta {
        cap confirm variable `v'
        if _rc {
            di as err "expected variable {bf:`v'} in the draws file " ///
                "(create it with {bf:qqr ..., bsave())})"
            exit 111
        }
    }

    qui su rep, meanonly
    local B = r(max)
    if `B' < 10 {
        di as err "draws file has too few bootstrap replications (B = `B')"
        exit 2001
    }

    mata: lqqr_boot_recon()

    tempname RES
    mata: lqqr_qqtest_run(`tcode', `dcode', "`RES'")

    local q   = `RES'[1,1]
    local KS  = `RES'[1,2]
    local pKS = `RES'[1,3]
    local CvM = `RES'[1,4]
    local pCv = `RES'[1,5]
    local Wld = `RES'[1,6]
    local pWc = `RES'[1,7]
    local pWb = `RES'[1,8]

    restore

    * ---- pretty header ----
    if "`test'"=="zero"      local h0 "beta(tau,theta) = 0 for all (tau,theta)"
    if "`test'"=="symmetry"  local h0 "beta(tau,theta) = beta(1-tau,theta)"
    if "`test'"=="constancy" local h0 "beta constant across `dim'"

    di as txt _n "{hline 64}"
    di as txt "  QQR surface test  (joint bootstrap, B = " as res "`B'" as txt ")"
    di as txt "{hline 64}"
    di as txt "  H0 : " as res "`h0'"
    di as txt "  restrictions (q) = " as res "`q'"
    di as txt "{hline 64}"
    di as txt %-18s "  statistic" %12s "value" %12s "p (boot)" %12s "p (chi2)"
    di as txt "{hline 64}"
    di as txt %-18s "  KS (sup-t)" as res %12.4f `KS' %12.4f `pKS' as txt %12s "."
    di as txt %-18s "  Cramer-von M." as res %12.4f `CvM' %12.4f `pCv' as txt %12s "."
    di as txt %-18s "  Wald" as res %12.4f `Wld' %12.4f `pWb' %12.4f `pWc'
    di as txt "{hline 64}"
    di as txt "  small p  =>  reject H0"

    return scalar q     = `q'
    return scalar KS    = `KS'
    return scalar p_KS  = `pKS'
    return scalar CvM   = `CvM'
    return scalar p_CvM = `pCv'
    return scalar Wald  = `Wld'
    return scalar p_Wald_boot = `pWb'
    return scalar p_Wald_chi2 = `pWc'
    return local  test  "`test'"
    return local  dim   "`dim'"
end
