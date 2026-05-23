*! mixi12_gl 1.0.0  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Granger-Lee (1989, 1990) two-step multicointegration test.  This is the
*  original test for the I(1) flow / I(2) stock case:
*     Stage 1: regress y_t on x_t and save residual Z_t.
*     Stage 2: cumulate Z_t into S_t, regress S_t on x_t and ADF-test the
*              stage-2 residual.
*  Delegates to {bf:multicoint, test(gl)}.

program define mixi12_gl, rclass
    version 14
    syntax varlist(min=2 ts numeric) [if] [in], ///
        [ EST(string) TRend(string) AUTOLag(string) MAXLag(integer 8) ///
          LEAds(integer 2) DLags(integer 2) KERnel(string) ///
          K(integer 12) LEVel(cilevel) ]
    gettoken y x : varlist

    capture which multicoint
    if _rc {
        di as err "mixi12_gl requires the {bf:multicoint} package."
        di as err `"Run "ssc install multicoint" or place multicoint.ado on the adopath."'
        exit 199
    }

    if "`est'"     == "" local est     "ols"
    if "`trend'"   == "" local trend   "c"
    if "`autolag'" == "" local autolag "bic"
    if "`kernel'"  == "" local kernel  "bartlett"

    quietly multicoint `y' `x' `if' `in',                        ///
        est(`est') test(gl) trend(`trend')                       ///
        autolag(`autolag') maxlag(`maxlag')                      ///
        leads(`leads') dlags(`dlags')                            ///
        kernel(`kernel') k(`k') notable

    local stat = e(gl_stat)
    local cv05 = e(gl_cv05)

    di
    di as text "{hline 78}"
    di as text "{bf:Two-step multicointegration test}"
    di as text "{hline 78}"
    di as text _col(2) "Flow y_t :"  _col(20) "`y'"
    di as text _col(2) "Flow x_t :"  _col(20) "`x'"
    di as text _col(2) "Estimator :" _col(20) "`est'"
    di as text _col(2) "Trend     :" _col(20) "`trend'"
    di as text "{hline 78}"
    di as text _col(2) "GL statistic" _col(28) %10.4f `stat'
    di as text _col(2) "5% critical value" _col(28) %10.4f `cv05'
    local verdict = cond(`stat' < `cv05', ///
        "Reject H0 — multicointegration found at 5%", ///
        "Do not reject H0 — no multicointegration at 5%")
    di as text "{hline 78}"
    di as text _col(2) "Conclusion: " as result "`verdict'"
    di as text "{hline 78}"

    return scalar stat   = `stat'
    return scalar cv05   = `cv05'
    return local verdict "`verdict'"
end
