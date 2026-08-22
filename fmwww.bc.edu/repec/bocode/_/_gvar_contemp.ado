*! _gvar_contemp 1.0.1  21aug2026
*! gvar contemp -- contemporaneous effects of the foreign variables on their
*! domestic counterparts, with OLS, White and Newey-West standard errors.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   pick the elements of Lambda_0 whose domestic and foreign variable names
*   coincide, and report them with all three standard-error types
*                                       <- Toolbox contmpcoeff.m
*   White standard errors               <- Toolbox mlcoint.m (HCW block)
*   Newey-West standard errors          <- Toolbox neweywest.m

program define _gvar_contemp, rclass
    version 14.0

    syntax [, VCE(string) ALL noSUMmary SAVing(name) ///
              LEVel(cilevel) GRaph NAME(string) ]

    _gvar_require estimate

    if ("`vce'" == "") local vce nwest
    local vce = lower("`vce'")
    if ("`vce'" == "ols")         local sc 4
    else if ("`vce'" == "robust") local sc 5
    else if ("`vce'" == "nwest")  local sc 6
    else {
        di as err "vce() must be {bf:ols}, {bf:robust} or {bf:nwest}"
        exit 198
    }

    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("cn", invtokens(gvar_getcname()'))
    mata: st_local("vn", invtokens(gvar_getvname()'))

    tempname R
    mata: st_matrix("`R'", gvar_contemp())
    local nr = rowsof(`R')
    if (`nr' == 0) {
        di as err "no unit has a foreign variable matching one of its own"
        exit 459
    }

    * which variables actually appear
    local vl ""
    forvalues q = 1/`nr' {
        local j = `R'[`q', 2]
        local v : word `j' of `vn'
        local p : list posof "`v'" in vl
        if (`p' == 0) local vl "`vl' `v'"
    }
    local vl = trim("`vl'")
    local nv : word count `vl'

    if ("`summary'" != "nosummary") {
        _gvar_title "Contemporaneous effects of foreign variables on domestic counterparts"
        di as text "  Coefficient on D.x* in the VECMX*, with " ///
                   as result "`vce'" as text " t-ratios beneath."
        di ""
        local w = 14 + 11 * `nv'
        if (`w' > 120) local w 120
        di as text "{hline `w'}"
        di as text %-13s "  Unit" _continue
        foreach v of local vl {
            di as text %11s abbrev("`v'", 10) _continue
        }
        di ""
        di as text "{hline `w'}"

        local nsig 0
        local ntot 0
        forvalues i = 1/`N' {
            local u : word `i' of `cn'
            local any 0
            forvalues q = 1/`nr' {
                if (`R'[`q', 1] == `i') local any 1
            }
            if (`any' == 0) continue

            * coefficient row
            di as text "  " %-11s abbrev("`u'", 11) _continue
            foreach v of local vl {
                local jj : list posof "`v'" in vn
                local b .
                local s .
                forvalues q = 1/`nr' {
                    if (`R'[`q',1] == `i' & `R'[`q',2] == `jj') {
                        local b = `R'[`q', 3]
                        local s = `R'[`q', `sc']
                        continue, break
                    }
                }
                if (`b' >= .) {
                    di as text %11s "." _continue
                }
                else {
                    local ++ntot
                    local st ""
                    if (`s' > 0 & `s' < .) {
                        local t = `b' / `s'
                        local pv = 2 * normal(-abs(`t'))
                        _gvar_stars `pv'
                        local st "`r(stars)'"
                        if ("`st'" != "") local ++nsig
                    }
                    di as result %8.3f `b' as text %-3s "`st'" _continue
                }
            }
            di ""

            * t-ratio row
            di as text "  " %-11s "" _continue
            foreach v of local vl {
                local jj : list posof "`v'" in vn
                local b .
                local s .
                forvalues q = 1/`nr' {
                    if (`R'[`q',1] == `i' & `R'[`q',2] == `jj') {
                        local b = `R'[`q', 3]
                        local s = `R'[`q', `sc']
                        continue, break
                    }
                }
                if (`b' >= . | `s' >= . | `s' <= 0) {
                    di as text %11s "" _continue
                }
                else {
                    * build the string first: -display- parses
                    *   %fmt "(" + string(...)
                    * as a call to a function named +string()
                    local tt = "(" + string(`b' / `s', "%5.2f") + ")"
                    di as text %11s "`tt'" _continue
                }
            }
            di ""
        }
        di as text "{hline `w'}"
        di as text "  * p<0.10   ** p<0.05   *** p<0.01   (" ///
                   as result `nsig' as text " of " as result `ntot' ///
                   as text " significant at 10%)"
        di as text "  A dot means the unit has no such pair: either it does not"
        di as text "  own the domestic variable, or its foreign counterpart is"
        di as text "  not in the model.  Only variables appearing on BOTH sides"
        di as text "  have a contemporaneous coefficient."
        if ("`all'" != "") {
            di ""
            di as text "  {bf:All three standard errors}"
            di as text "{hline 74}"
            di as text %-11s "  Unit" %-9s "variable" _col(24) "coef" ///
               _col(36) "OLS" _col(48) "White" _col(60) "Newey-West"
            di as text "{hline 74}"
            forvalues q = 1/`nr' {
                local ii = `R'[`q', 1]
                local jj = `R'[`q', 2]
                local u : word `ii' of `cn'
                local v : word `jj' of `vn'
                di as text "  " %-9s abbrev("`u'", 9) ///
                   %-9s abbrev("`v'", 9) ///
                   _col(20) as result %10.4f `=`R'[`q',3]' ///
                   _col(32) as result %10.4f `=`R'[`q',4]' ///
                   _col(44) as result %10.4f `=`R'[`q',5]' ///
                   _col(56) as result %10.4f `=`R'[`q',6]'
            }
            di as text "{hline 74}"
            di as text "  The three differ only in how the residual covariance" ///
                       " is estimated;"
            di as text "  the coefficient is the same OLS estimate in every" ///
                       " column."
        }
        di as text "  These are impact elasticities with respect to the foreign"
        di as text "  counterpart; values near one indicate strong contemporaneous"
        di as text "  international transmission (Dees, di Mauro, Pesaran & Smith"
        di as text "  2007, Table 6)."
        di ""
    }

    * ---- graph --------------------------------------------------------------
    * The elasticities with a confidence interval, one point per (unit,
    * variable).  The reference line is at one, not zero: DdPS (2007, Table 6)
    * read these against unity, since an elasticity of one means the domestic
    * variable moves one-for-one with its foreign counterpart on impact.
    if ("`graph'" != "") {
        tempname G
        matrix `G' = J(`nr', 4, .)
        local zc = invnormal(1 - (1 - `level' / 100) / 2)
        forvalues q = 1/`nr' {
            matrix `G'[`q', 1] = `R'[`q', 1]
            matrix `G'[`q', 2] = `R'[`q', 3]
            * mark the ones whose interval excludes one.  sc is already the
            * column of the requested standard error (4 ols, 5 robust, 6 nwest)
            local se = `R'[`q', `sc']
            matrix `G'[`q', 3] = 1
            matrix `G'[`q', 4] = 0
            if (`se' < . & `se' > 0) {
                if (abs(`R'[`q',3] - 1) > `zc' * `se') matrix `G'[`q', 4] = 1
            }
        }
        local sub "impact elasticity; marked where the `level'% interval excludes one"
        * below = 2: the comparison is two-sided, so the flag decides
        _gvar_dotplot `G' `nr' "`cn'" ///
            "Contemporaneous effects of the foreign variables" "`sub'" ///
            "elasticity" "`name'" 2
    }

    if ("`saving'" != "") {
        matrix `saving' = `R'
    }
    return matrix contemp = `R', copy
    return local  vce "`vce'"
end
