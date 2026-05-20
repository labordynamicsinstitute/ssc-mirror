*! _mc_est_taols v1.1.0  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Transformed & Augmented OLS estimator (Sun et al. 2025/2026).

program define _mc_est_taols, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in], TRend(string) K(integer)  ///
        NX(integer) [RESid(name)]
    marksample touse

    qui capture mata: __mc_loaded()
    if _rc qui _mc_mata

    gettoken yv xv : varlist
    local nall : word count `xv'
    if `nall' != 2*`nx' {
        di as err "_mc_est_taols: regressor count must be 2*nx"
        exit 198
    }
    local Xcumlist
    local Xflist
    local i = 0
    foreach v of local xv {
        local ++i
        if `i' <= `nx' local Xcumlist `Xcumlist' `v'
        else            local Xflist   `Xflist'   `v'
    }
    qui tsset, noquery
    qui sort `r(timevar)'
    local Dxlist
    local i = 0
    foreach v of local Xflist {
        local ++i
        tempvar Dv`i'
        qui gen double `Dv`i'' = `v' - `v'[_n-1] if `touse'
        qui replace `Dv`i'' = 0 if missing(`Dv`i'') & `touse'
        local Dxlist `Dxlist' `Dv`i''
    }

    tempname b V rss r2 N
    mata: _mc_taols_compute("`yv'", "`Xcumlist'", "`Xflist'", "`Dxlist'", ///
                            "`trend'", `k', "`touse'",                    ///
                            "`b'", "`V'", "`rss'", "`r2'", "`N'", "`resid'")
    return matrix b   = `b'
    return matrix V   = `V'
    return scalar rss = `rss'
    return scalar r2  = `r2'
    return scalar N   = `N'
end
