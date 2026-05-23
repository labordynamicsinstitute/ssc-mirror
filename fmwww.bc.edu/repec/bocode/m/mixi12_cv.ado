*! mixi12_cv 1.0.0  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Critical-value lookup for mixi12 tests.
*
*  Syntax:
*     mixi12_cv haldrup , M1(integer) M2(integer) TSize(integer)
*         — Haldrup (1994b, Table 1) residual-ADF critical values.
*
*     mixi12_cv johansen , DF(integer)
*         — χ²(df) tabulated thresholds used by Paruolo Q(r,s_1) under
*           the joint hypothesis.
*
*     mixi12_cv dp
*         — Pantula (1986) F-test critical values used by Dickey-Pantula
*           sequential procedure.

program define mixi12_cv, rclass
    version 14
    gettoken sub 0 : 0, parse(" ,")
    if "`sub'" == "haldrup" {
        syntax , M1(integer) M2(integer) TSize(integer)
        _mixi12_mata
        mata: _mixi12_haldrup_cv_runner(`m1', `m2', `tsize')
        local cv01 = r(cv01)
        local cv025 = r(cv025)
        local cv05  = r(cv05)
        local cv10  = r(cv10)
        di as text "{hline 78}"
        di as text "{bf:Critical values - I(2) cointegration ADF test (intercept)}"
        di as text "{hline 78}"
        di as text _col(2) "m1 = `m1'   m2 = `m2'   T = `tsize'"
        di as text "{hline 78}"
        di as text _col(2) "Percentile" _col(20) "1%" _col(32) "2.5%" ///
                   _col(44) "5%" _col(56) "10%"
        di as result _col(2) "Critical value" ///
                 _col(20) %8.3f `cv01' _col(32) %8.3f `cv025' ///
                 _col(44) %8.3f `cv05' _col(56) %8.3f `cv10'
        di as text "{hline 78}"
        return scalar cv01 = `cv01'
        return scalar cv025 = `cv025'
        return scalar cv05 = `cv05'
        return scalar cv10 = `cv10'
    }
    else if "`sub'" == "johansen" {
        syntax , DF(integer)
        local cv01 = invchi2tail(`df', 0.01)
        local cv05 = invchi2tail(`df', 0.05)
        local cv10 = invchi2tail(`df', 0.10)
        di as text "{hline 78}"
        di as text "{bf:χ²(`df') critical values}"
        di as text "{hline 78}"
        di as text _col(2) "Percentile" _col(20) "1%" _col(32) "5%" ///
                   _col(44) "10%"
        di as result _col(2) "Critical value" ///
                 _col(20) %8.3f `cv01' _col(32) %8.3f `cv05' ///
                 _col(44) %8.3f `cv10'
        di as text "{hline 78}"
        return scalar cv01 = `cv01'
        return scalar cv05 = `cv05'
        return scalar cv10 = `cv10'
    }
    else if "`sub'" == "dp" {
        di as text "{hline 78}"
        di as text "{bf:Sequential F critical values - I(2) unit root test (constant only)}"
        di as text "{hline 78}"
        di as text _col(2) "n" _col(14) "F1 (5%)" _col(28) "F2 (5%)" ///
                   _col(42) "F3 (5%)"
        di as result _col(2) "25"   _col(14) "5.18" _col(28) "5.13" _col(42) "5.18"
        di as result _col(2) "50"   _col(14) "4.48" _col(28) "4.47" _col(42) "4.71"
        di as result _col(2) "100"  _col(14) "4.05" _col(28) "4.10" _col(42) "4.51"
        di as result _col(2) "250"  _col(14) "3.80" _col(28) "3.93" _col(42) "4.42"
        di as result _col(2) "500"  _col(14) "3.72" _col(28) "3.86" _col(42) "4.38"
        di as result _col(2) "∞"    _col(14) "3.66" _col(28) "3.84" _col(42) "4.35"
        di as text "{hline 78}"
    }
    else {
        di as err "mixi12_cv: subcommand must be haldrup | johansen | dp"
        exit 198
    }
end
