*! _dnqr_mata.ado  version 1.0.1  27may2026
*! Internal loader: compiles the dnqr Mata library on first invocation
*! per Stata session.  Called automatically by nqar/dnqr/dnqr_plot/...
*!
*! Author : Dr Merwan Roudane  <merwanroudane920@gmail.com>

program define _dnqr_mata
        version 13.0
        // Probe whether the Mata library is in memory by looking up a
        // known function symbol via findexternal(); robust to -mata clear-.
        local __dnqr_ok 0
        capture mata: st_local("__dnqr_ok", ///
                strofreal(findexternal("dnqr_rowstd()") != NULL))
        if "`__dnqr_ok'" == "1" exit
        capture findfile _dnqr_init.mata
        if _rc {
                di as err "{bf:_dnqr_init.mata} not found on the adopath"
                di as err "(the dnqr package is missing its Mata library)"
                exit 601
        }
        quietly do "`r(fn)'"
end
