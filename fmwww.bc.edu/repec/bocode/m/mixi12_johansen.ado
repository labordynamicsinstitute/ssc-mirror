*! mixi12_johansen 1.0.2  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Two-step Johansen (1995, 1997) maximum-likelihood analysis of a VAR with
*  potentially I(2) variables, augmented with the Paruolo (1996) joint
*  Q(r, s1) rank test.

program define mixi12_johansen, eclass
    version 14
    syntax varlist(min=2 ts numeric) [if] [in],   ///
        [                                          ///
        LAGS(integer 2)                            ///
        TREND(string)                              ///
        Rank(integer -1)                           ///
        S1(integer -1)                             ///
        JOint                                      ///
        ALPha(real 0.05)                           ///
        SAVing(string)                             ///
        ]

    if "`trend'" == "" local trend "c"
    local tcode = cond("`trend'"=="none", 1, ///
                  cond("`trend'"=="c",    2, ///
                  cond("`trend'"=="ct",   4, 2)))

    marksample touse, novarlist
    qui count if `touse'
    local N = r(N)
    local p : word count `varlist'

    _mixi12_mata

    if `lags' < 2 {
        di as err "mixi12_johansen: VAR(k) needs k >= 2 for an I(2) analysis"
        exit 198
    }

    // joint Paruolo Q table -- runner reads varlist via st_view
    tempname Qtab
    mata: _mixi12_paruoloQ_runner("`varlist'", "`touse'", `lags', `tcode')
    matrix `Qtab' = r(Q)

    di
    di as text "{hline 78}"
    di as text "{bf:Joint Q(r, s_1) rank test for the I(2) VAR}"
    di as text "{hline 78}"
    di as text _col(2) "Variables:" _col(16) "`varlist'"
    di as text _col(2) "Lag length:" _col(16) "`lags'"
    di as text _col(2) "Trend spec:" _col(16) "`trend'"
    di as text _col(2) "Sample N:" _col(16) "`N'"
    di as text "{hline 78}"
    di as text _col(2) "Q(P_1,R) = TRACE(R) + TRACE(P_1|R)"
    di as text "{hline 78}"
    di as text _col(2) "r \ s_1" _continue
    forvalues j = 0/`=`p'-1' {
        di as text _col(`=16 + `j'*11') "s_1=`j'" _continue
    }
    di
    di as text "{hline 78}"
    forvalues r = 0/`=`p'-1' {
        local row = `r' + 1
        local s1max = `p' - `r' - 1
        di as result _col(2) "r = `r'" _continue
        forvalues j = 2/`=`p'+1' {
            local s1idx = `j' - 2
            local col = 14 + (`j'-2)*11
            if `s1idx' > `s1max'  di as text _col(`col') "    -   " _continue
            else {
                local val = `Qtab'[`row',`j']
                if `val' < .  di as result _col(`col') %9.2f `val' _continue
                else          di as text   _col(`col') "    .   " _continue
            }
        }
        di
    }
    di as text "{hline 78}"

    // auto rank pick (rough): smallest (r, s1) such that Q < χ² 95%
    if `rank' < 0 {
        local rauto = 0
        local s1auto = 0
        local picked 0
        forvalues r = 0/`=`p'-1' {
            forvalues j = 0/`=`p'-`r'-1' {
                local row = `r' + 1
                local col = `j' + 2
                local q = `Qtab'[`row',`col']
                if `q' == . continue
                local df = (`p'-`r')*(`p'-`r') - `j'*`j'
                if `df' <= 0 continue
                local crit = invchi2tail(`df', `alpha')
                if `q' < `crit' {
                    local rauto = `r'
                    local s1auto = `j'
                    local picked 1
                    continue, break
                }
            }
            if `picked' continue, break
        }
        local rank = `rauto'
        local s1 = `s1auto'
        di as text _col(2) "Auto-selected (r, s_1) = (" as result "`rank', `s1'" ///
            as text ") at 5% level"
    }

    if `s1' < 0 local s1 = 0
    if `rank' == 0 {
        di as text "{p 2 4 2}Rank zero selected - model collapses to VAR in differences.{p_end}"
        ereturn clear
        ereturn scalar rank = 0
        ereturn scalar s1 = `s1'
        ereturn local cmd "mixi12_johansen"
        exit 0
    }

    // Step 2 estimation -- runner reads varlist via st_view
    mata: _mixi12_johansen2_runner("`varlist'", "`touse'", `lags', `tcode', `rank', `s1')

    matrix beta    = r(beta)
    matrix alpha   = r(alpha)
    matrix beta_p  = r(beta_p)
    matrix alpha_p = r(alpha_p)
    matrix beta1   = r(beta1)
    matrix beta2   = r(beta2)

    di
    di as text "{hline 78}"
    di as text "{bf:Two-step Johansen I(2) estimates}   r = `rank', s_1 = `s1'"
    di as text "{hline 78}"
    di as text _col(2) "Cointegrating vectors β (p × r):"
    matlist beta, format(%9.4f)
    di as text "{hline 78}"
    di as text _col(2) "Loading matrix α (p × r):"
    matlist alpha, format(%9.4f)
    di as text "{hline 78}"
    di as text _col(2) "β_⊥1 (p × s_1):  I(1) common trends weights"
    matlist beta1, format(%9.4f)
    di as text "{hline 78}"
    di as text _col(2) "β_⊥2 (p × s_2):  I(2) common trends weights"
    matlist beta2, format(%9.4f)
    di as text "{hline 78}"

    ereturn clear
    ereturn matrix beta    = beta
    ereturn matrix alpha   = alpha
    ereturn matrix beta_p  = beta_p
    ereturn matrix alpha_p = alpha_p
    ereturn matrix beta1   = beta1
    ereturn matrix beta2   = beta2
    ereturn matrix Q       = `Qtab'
    ereturn scalar rank    = `rank'
    ereturn scalar s1      = `s1'
    ereturn scalar s2      = `p' - `rank' - `s1'
    ereturn scalar p       = `p'
    ereturn scalar N       = `N'
    ereturn scalar lags    = `lags'
    ereturn local trend    "`trend'"
    ereturn local cmd      "mixi12_johansen"
    ereturn local depvars  "`varlist'"
end

version 14
mata:
void _mixi12_paruoloQ_runner(string scalar vl, string scalar tn,
                              real scalar k, real scalar tcode)
{
    real matrix X, Qtab
    st_view(X=., ., vl, tn)
    _mixi12_paruoloQ(X, k, tcode, Qtab)
    st_matrix("r(Q)", Qtab)
}

void _mixi12_johansen2_runner(string scalar vl, string scalar tn,
                               real scalar k, real scalar tcode,
                               real scalar r, real scalar s1)
{
    real matrix X
    real matrix beta, alpha, betaP, alphaP, beta1, beta2, phi, eta
    real colvector lam2, Qs
    real scalar Tu
    st_view(X=., ., vl, tn)
    _mixi12_johansen2(X, k, tcode, r, s1,
        beta, alpha, betaP, alphaP, beta1, beta2, phi, eta,
        lam2, Qs, Tu)
    st_matrix("r(beta)",    beta)
    st_matrix("r(alpha)",   alpha)
    st_matrix("r(beta_p)",  betaP)
    st_matrix("r(alpha_p)", alphaP)
    st_matrix("r(beta1)",   beta1)
    st_matrix("r(beta2)",   beta2)
}
end
