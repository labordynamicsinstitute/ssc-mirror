*! mixi12_mco 1.0.0  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Multicointegration analysis in the I(1) flow / I(2) stock setting.
*
*  In the mixed-integration framework, multicointegration is the special
*  case in which the I(2) variables in the system are NOT directly
*  observed — they are constructed as cumulants of underlying I(1) flow
*  variables — and a polynomial cointegration links the cumulated stocks
*  to the original flows.  Granger-Lee (1989, 1990) is the classical
*  reference; Engsted-Gonzalo-Haldrup (1997) provide the one-step
*  residual ADF.
*
*  This routine is a thin wrapper around the user's {bf:multicoint}
*  package (Roudane 2026), which actually performs the cumulation,
*  estimation (OLS / FM-OLS / DOLS / CCR / IM-OLS / TAOLS) and tests
*  (GL / EGH / TAOLS).  Output is reformatted in the mixi12 visual style.
*
*  Syntax:
*     mixi12_mco y_flow x_flowlist [if] [in] ,
*         [ EST(name)  TEst(name)  TR:end(spec)  NOConstant
*           LAGS(#)  AUTOLag(crit)  MAXLags(#)
*           LEads(#)  DLags(#)
*           KERnel(name)  BWidth(#)  K(#)
*           LEvel(#)  GRAPH  GRSave(file)  NOTable ]

program define mixi12_mco, eclass
    version 14
    syntax varlist(min=2 ts numeric) [if] [in],                  ///
        [                                                         ///
        EST(string)                                               ///
        TEst(string)                                              ///
        TRend(string)                                             ///
        NOConstant                                                ///
        LAGS(integer 0)                                           ///
        AUTOLag(string)                                           ///
        MAXLag(integer 8)                                         ///
        LEAds(integer 2)                                          ///
        DLags(integer 2)                                          ///
        KERnel(string)                                            ///
        BWidth(integer 0)                                         ///
        K(integer 12)                                             ///
        LEVel(cilevel)                                            ///
        GRAPH                                                     ///
        GRSave(string)                                            ///
        NOTable                                                   ///
        ]
    gettoken y x : varlist

    capture which multicoint
    if _rc {
        di as err "mixi12_mco requires the {bf:multicoint} package."
        di as err `"Run "ssc install multicoint" or place multicoint.ado on the adopath."'
        exit 199
    }

    if "`est'"     == "" local est     "taols"
    if "`test'"    == "" local test    "all"
    if "`trend'"   == "" local trend   "c"
    if "`autolag'" == "" local autolag "bic"
    if "`kernel'"  == "" local kernel  "bartlett"

    // header
    di
    di as text "{hline 78}"
    di as text "{bf:mixi12_mco — multicointegration (I(1) flow / I(2) stock)}"
    di as text "{hline 78}"
    di as text _col(2) "Flow dependent (y_t):"   _col(28) "`y'"
    di as text _col(2) "Flow regressors (x_t):"  _col(28) "`x'"
    di as text _col(2) "Estimator:"              _col(28) "`est'"
    di as text _col(2) "Test:"                   _col(28) "`test'"
    di as text _col(2) "Trend:"                  _col(28) "`trend'"
    di as text "{hline 78}"
    di as text _col(2) "Underlying regression (after cumulation):"
    di as text _col(4) "{bf:Y_t = α + δ_1·t + δ_2·t² + β'·X_t + γ'·x_t + u_t}"
    di as text _col(4) "where Y_t = Σ y_s and X_t = Σ x_s are I(2)."
    di as text "{hline 78}"

    // delegate
    local optstr = "est(`est') test(`test') trend(`trend')"
    local optstr "`optstr' autolag(`autolag') maxlag(`maxlag')"
    local optstr "`optstr' leads(`leads') dlags(`dlags') kernel(`kernel')"
    local optstr "`optstr' k(`k')"
    local leads = `leads'
    local dlags = `dlags'
    if "`noconstant'" != "" local optstr "`optstr' noconstant"
    if `lags' > 0 local optstr "`optstr' lags(`lags')"
    if `bwidth' > 0 local optstr "`optstr' bwidth(`bwidth')"
    if "`graph'" != "" local optstr "`optstr' graph"
    if "`grsave'" != "" local optstr "`optstr' grsave(`grsave')"
    if "`notable'" != "" local optstr "`optstr' notable"

    multicoint `y' `x' `if' `in', `optstr'

    // forward e() return contents from multicoint
    ereturn local cmd "mixi12_mco"
    ereturn local subcmd "mco"
    ereturn local estimator "`est'"
    ereturn local test "`test'"

end
