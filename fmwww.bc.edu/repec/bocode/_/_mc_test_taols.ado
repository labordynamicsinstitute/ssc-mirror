*! _mc_test_taols v1.1.0  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Sun et al. (2026) adaptive F-test for cointegration vs multicointegration.

program define _mc_test_taols, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in],            ///
        TRend(string)  K(integer)  NX(integer)
    marksample touse

    qui capture mata: __mc_loaded()
    if _rc qui _mc_mata

    gettoken Ycum xv : varlist

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

    tempvar yflow
    qui gen double `yflow' = `Ycum' - `Ycum'[_n-1] if `touse'
    qui replace `yflow' = `Ycum' if missing(`yflow') & `touse'

    tempname Fm Fmp Fc Fcp Fa Fap ww
    mata: _mc_taols_test_compute("`Ycum'","`yflow'",                ///
        "`Xcumlist'","`Xflist'","`Dxlist'",                          ///
        "`trend'", `k', `nx', "`touse'",                             ///
        "`Fm'","`Fmp'","`Fc'","`Fcp'","`Fa'","`Fap'","`ww'")

    return scalar Fm     = `Fm'
    return scalar Fm_p   = `Fmp'
    return scalar Fc     = `Fc'
    return scalar Fc_p   = `Fcp'
    return scalar Fa     = `Fa'
    return scalar Fa_p   = `Fap'
    return scalar weight = `ww'
end
