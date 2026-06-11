*! qqr 1.0.0 16may2026
*! Quantile-on-Quantile Regression (Sim & Zhou, 2015)
*! Author: Merwan Roudane  <merwanroudane920@gmail.com>

program qqr, rclass
    version 14
    syntax varlist(min=2 max=2 numeric) [if] [in],     ///
        [ TAU(string)                                  ///
          THETA(string)                                ///
          Bandwidth(real 0)                            ///
          METHod(string)                               ///
          BOOTse                                       ///
          NBoot(integer 200)                           ///
          BCI                                          ///
          BSAVE(string asis)                           ///
          LEVel(cilevel)                               ///
          SAVing(string asis)                          ///
          REPLACE                                      ///
          noPROGress ]

    marksample touse
    tokenize `varlist'
    local y `1'
    local x `2'

    if "`tau'"==""    local tau    "0.05(0.05)0.95"
    if "`theta'"==""  local theta  "0.05(0.05)0.95"
    if "`method'"=="" local method "kernel"

    if !inlist("`method'", "kernel", "subset") {
        di as err "method() must be {kernel} or {subset}"
        exit 198
    }

    numlist "`tau'"
    local tau   `r(numlist)'
    numlist "`theta'"
    local theta `r(numlist)'

    local M : word count `tau'
    local L : word count `theta'

    qui count if `touse'
    local N = r(N)
    if `N' < 20 {
        di as err "need at least 20 observations (got `N')"
        exit 2001
    }

    tempname Tau Theta OUT B SE TST PVAL R2
    mata: st_matrix("`Tau'",   strtoreal(tokens(st_local("tau")))')
    mata: st_matrix("`Theta'", strtoreal(tokens(st_local("theta")))')

    if "`progress'"=="" {
        di as txt _n "{hline 62}"
        di as txt "  Quantile-on-Quantile Regression  (Sim & Zhou 2015)"
        di as txt "{hline 62}"
        di as txt "  y = " as res "`y'" as txt "    x = " as res "`x'"
        di as txt "  n = " as res "`N'" as txt ///
           "    Y-quantiles = " as res "`M'" as txt ///
           "    X-quantiles = " as res "`L'"
        di as txt "  method = " as res "`method'"
        if `bandwidth' > 0 di as txt "  bandwidth = " as res %6.4f `bandwidth'
        di as txt "{hline 62}"
    }

    local boot = cond("`bootse'"!="", 1, 0)

    mata: lqqr_qqr_run("`y'", "`x'", "`touse'", "`Tau'", "`Theta'", ///
                   `bandwidth', "`method'", `boot', `nboot', "`OUT'")

    * Reshape into M*L matrices
    mata: lqqr_qqr_reshape("`OUT'", `M', `L', "`B'", "`SE'", "`TST'", "`PVAL'", "`R2'")

    * Joint bootstrap CIs on the surface (also needed to write a draws file)
    local docb = cond("`bci'"!="" | `"`bsave'"'!="", 1, 0)
    if `docb' {
        if "`progress'"=="" di as txt "  joint bootstrap: " as res "`nboot'" ///
            as txt " reps, level = " as res "`level'" as txt "  ..."
        mata: lqqr_qqr_bootci("`y'", "`x'", "`touse'", "`Tau'", "`Theta'", ///
                  `bandwidth', "`method'", `nboot', `level', "`OUT'")
        * OUT now carries two extra cols: cilo cihi
    }

    * Write the joint draws file (long form: rep tau theta beta) for qqtest/qqribbon/qqdiff
    if `"`bsave'"' != "" {
        preserve
        drop _all
        mata: lqqr_qqr_bootlong()
        if "`replace'"=="replace" save `bsave', replace
        else                       save `bsave'
        restore
        if "`progress'"=="" di as txt "  draws file saved: " as res `"`bsave'"'
    }

    * Save long-format dataset
    if `"`saving'"' != "" {
        preserve
        drop _all
        if `docb' mata: (void) st_addvar("double", ("tau","theta","coef","se","t","p","r2","cilo","cihi"))
        else      mata: (void) st_addvar("double", ("tau","theta","coef","se","t","p","r2"))
        mata: M_QQ = st_matrix("`OUT'"); (void) st_addobs(rows(M_QQ)); st_store(.,.,M_QQ)
        if "`replace'"=="replace" save `saving', replace
        else                       save `saving'
        restore
    }

    * Display table + summary BEFORE returning matrices (return matrix moves them)
    if "`progress'"=="" {
        di as txt _n "  {bf:Coefficient table  beta(tau, theta)   [rows = tau, cols = theta]}"
        mata: lqqr_print_matrix("`B'", "`PVAL'", strtoreal(tokens(st_local("tau")))', strtoreal(tokens(st_local("theta")))')

        tempname S
        mata: lqqr_summary_mat("`OUT'", "`S'")
        di as txt _n "  {bf:Coefficient statistics}"
        di as txt "    mean   = " as res %9.4f `S'[1,1]
        di as txt "    median = " as res %9.4f `S'[1,2]
        di as txt "    min    = " as res %9.4f `S'[1,3]
        di as txt "    max    = " as res %9.4f `S'[1,4]
        di as txt "    sd     = " as res %9.4f `S'[1,5]
        di as txt _n "  {bf:Significance}"
        di as txt "    p<0.10 : " as res %4.0f `S'[1,6] as txt " / " %4.0f `S'[1,9]
        di as txt "    p<0.05 : " as res %4.0f `S'[1,7] as txt " / " %4.0f `S'[1,9]
        di as txt "    p<0.01 : " as res %4.0f `S'[1,8] as txt " / " %4.0f `S'[1,9]
        di as txt _n "  note: *** p<0.01  ** p<0.05  * p<0.10"
        di as txt "{hline 62}"
    }

    * Now return matrices (these MOVE the tempname matrices to r())
    return matrix coef  = `B'
    return matrix se    = `SE'
    return matrix t     = `TST'
    return matrix p     = `PVAL'
    return matrix r2    = `R2'
    return matrix tau   = `Tau'
    return matrix theta = `Theta'
    return scalar N = `N'
    return local  method  "`method'"
    return local  depvar  "`y'"
    return local  indvar  "`x'"
end
