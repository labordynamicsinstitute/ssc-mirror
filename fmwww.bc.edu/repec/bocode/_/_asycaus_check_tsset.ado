*! _asycaus_check_tsset v1.0.1  24may2026
*! Verifies that the data are tsset.   Internal helper for the asycaus suite.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _asycaus_check_tsset
    capture xtset
    if !_rc exit
    capture tsset
    if _rc {
        di as err "data must be {help tsset:tsset} (time series)"
        exit 459
    }
end
