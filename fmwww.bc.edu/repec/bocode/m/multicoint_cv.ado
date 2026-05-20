*! multicoint_cv v1.1.0  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Display Engsted-Gonzalo-Haldrup (1997) critical values for the ADF test
*! of multicointegration.

program define multicoint_cv, rclass
    version 14.0
    syntax , [ TRend(string) M1(integer 1) M2(integer 1) Tsize(integer 0) ]
    local T = `tsize'

    qui capture mata: __mc_loaded()
    if _rc qui _mc_mata

    if "`trend'" == "" local trend ct
    local trend = lower("`trend'")
    if !inlist("`trend'","ct","ctt") {
        di as err "trend() must be ct or ctt"
        exit 198
    }
    if !inlist(`m2',1,2) {
        di as err "m2 must be 1 or 2"
        exit 198
    }
    if `m1' < 0 | `m1' > 4 {
        di as err "m1 must be in 0..4"
        exit 198
    }

    di _n as txt "{hline 78}"
    di as txt "Engsted-Gonzalo-Haldrup (1997) critical values - ADF test for multicointegration"
    di as txt "Trend: " as res "`trend'" as txt "    m1 (I(1) regressors): " as res `m1'  ///
       as txt "    m2 (I(2) regressors): " as res `m2'
    di as txt "{hline 78}"
    di as txt %9s "T" "  " %10s "1%" "  " %10s "2.5%" "  " %10s "5%" "  " %10s "10%"
    di as txt "{hline 78}"

    tempname cv01 cv025 cv05 cv10
    foreach TT of numlist 25 50 100 250 500 {
        mata: _mc_egh_cv("`trend'", `m1', `m2', `TT', ///
                         "`cv01'", "`cv025'", "`cv05'", "`cv10'")
        di as txt %9.0f `TT' "  " as res %10.3f `cv01'  ///
           "  " as res %10.3f `cv025' "  " as res %10.3f `cv05'                 ///
           "  " as res %10.3f `cv10'
    }
    di as txt "{hline 78}"

    if `T' > 0 {
        mata: _mc_egh_cv("`trend'", `m1', `m2', `T', ///
                         "`cv01'", "`cv025'", "`cv05'", "`cv10'")
        local v1   = `cv01'
        local v25  = `cv025'
        local v5   = `cv05'
        local v10v = `cv10'
        di _n as txt "Interpolated for T = `T':"
        di as txt "    1%   = " as res %8.3f `v1'   ///
           as txt "    2.5% = " as res %8.3f `v25'  ///
           as txt "    5%   = " as res %8.3f `v5'   ///
           as txt "    10%  = " as res %8.3f `v10v'
        return scalar cv01  = `v1'
        return scalar cv025 = `v25'
        return scalar cv05  = `v5'
        return scalar cv10  = `v10v'
    }
    di _n as txt "Source: Engsted Gonzalo Haldrup (1997), Tables 1 and 2."
end
