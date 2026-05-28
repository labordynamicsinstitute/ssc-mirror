*! _dnqr_silent_qreg.ado  version 1.0.1  27may2026
*! Private wrapper: runs qreg in absolute silence so its iteration log
*! does not leak from inside the IVQR grid search.
*!
*! Author : Dr Merwan Roudane  <merwanroudane920@gmail.com>

program define _dnqr_silent_qreg, eclass
        version 13.0
        syntax varlist [if] [in], Quantile(real)
        quietly {
                capture qreg `varlist' `if' `in', quantile(`quantile') nolog
        }
        if _rc {
                ereturn clear
                exit _rc
        }
end
