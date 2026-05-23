*! mixi12_egh 1.0.0  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Engsted-Gonzalo-Haldrup (1997) one-step residual ADF test of
*  multicointegration.  Applies an ADF test to the residual u_t of the
*  single multicointegration regression
*        Y_t = α + δ_1 t + δ_2 t² + β'·X_t + γ'·x_t + u_t.
*  Delegates to {bf:multicoint, test(egh)} and returns the EGH critical
*  values from Engsted-Gonzalo-Haldrup (1997, Tables 1–2).

program define mixi12_egh, rclass
    version 14
    syntax varlist(min=2 ts numeric) [if] [in], ///
        [ EST(string) TRend(string) AUTOLag(string) MAXLag(integer 8) ///
          LEAds(integer 2) DLags(integer 2) KERnel(string) ///
          K(integer 12) LEVel(cilevel) ]
    gettoken y x : varlist

    capture which multicoint
    if _rc {
        di as err "mixi12_egh requires the {bf:multicoint} package."
        di as err `"Run "ssc install multicoint" or place multicoint.ado on the adopath."'
        exit 199
    }

    if "`est'"     == "" local est     "ols"
    if "`trend'"   == "" local trend   "c"
    if "`autolag'" == "" local autolag "bic"
    if "`kernel'"  == "" local kernel  "bartlett"

    quietly multicoint `y' `x' `if' `in',                       ///
        est(`est') test(egh) trend(`trend')                     ///
        autolag(`autolag') maxlag(`maxlag')                     ///
        leads(`leads') dlags(`dlags')                           ///
        kernel(`kernel') k(`k') notable

    local stat = e(egh_stat)
    local cv01 = e(egh_cv01)
    local cv025 = e(egh_cv025)
    local cv05 = e(egh_cv05)
    local cv10 = e(egh_cv10)
    local lag = e(egh_lags)

    local verdict "no multicointegration"
    if (`stat' < `cv10')  local verdict = "10%"
    if (`stat' < `cv05')  local verdict = "5%"
    if (`stat' < `cv025') local verdict = "2.5%"
    if (`stat' < `cv01')  local verdict = "1%"

    di
    di as text "{hline 78}"
    di as text "{bf:One-step residual ADF multicointegration test}"
    di as text "{hline 78}"
    di as text _col(2) "Flow y_t  :" _col(20) "`y'"
    di as text _col(2) "Flow x_t  :" _col(20) "`x'"
    di as text _col(2) "Estimator :" _col(20) "`est'"
    di as text _col(2) "Trend     :" _col(20) "`trend'"
    di as text _col(2) "ADF lag   :" _col(20) "`lag'"
    di as text "{hline 78}"
    di as text _col(2) "Test statistic" _col(28) %10.4f `stat'
    di as text "{hline 78}"
    di as text _col(2) "Critical values" _col(28) "  1%" _col(40) " 2.5%" ///
        _col(52) "  5%" _col(64) " 10%"
    di as result _col(28) %8.3f `cv01' _col(40) %8.3f `cv025' ///
        _col(52) %8.3f `cv05' _col(64) %8.3f `cv10'
    di as text "{hline 78}"
    di as text _col(2) "Reject H0 of NO multicointegration at:  " ///
        as result "`verdict'"
    di as text "{hline 78}"

    return scalar t      = `stat'
    return scalar cv01   = `cv01'
    return scalar cv025  = `cv025'
    return scalar cv05   = `cv05'
    return scalar cv10   = `cv10'
    return scalar lags   = `lag'
    return local verdict "`verdict'"
end
