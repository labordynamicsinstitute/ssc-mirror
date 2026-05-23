*! mixi12_trans 1.0.0  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Kongsted (2005) / Kurita (2011) I(2)-to-I(1) transformation LR test.
*
*  Given a previously fitted I(2) VAR (via mixi12_johansen), test whether a
*  user-supplied p × q matrix G defines a valid linear transformation that
*  reduces the I(2) variables to an I(1) system - i.e. whether
*  sp(τ) = sp(G), where τ = (β, β_⊥1).
*
*  Syntax:
*      mixi12_trans , G(matname) [LEVEL(cilevel)]
*
*  The G matrix is interpreted as p × q.  Typical examples:
*      money multiplier:    G = (1, -1, 0)'  applied to (m2, mb, p)
*      price homogeneity:   G = (1, -1, 0, 0)'  on (m, p, y, R)

program define mixi12_trans, rclass
    version 14
    syntax [, Gmat(string) G(string) LEVel(cilevel)]
    if "`gmat'" == "" local gmat "`g'"
    if "`gmat'" == "" {
        di as err "mixi12_trans: specify the candidate matrix via g(matname) or gmat(matname)"
        exit 198
    }

    // require previous mixi12_johansen
    if "`e(cmd)'" != "mixi12_johansen" {
        di as err "mixi12_trans requires a previous mixi12_johansen estimation"
        exit 301
    }
    local p = e(p)
    local r = e(rank)
    local s1 = e(s1)
    local s2 = e(s2)
    local N = e(N)

    tempname GG beta2 LR df pval
    matrix `GG' = `gmat'
    matrix `beta2' = e(beta2)

    if rowsof(`GG') != `p' {
        di as err "G must have `p' rows (one per variable in the I(2) VAR)"
        exit 198
    }

    _mixi12_mata
    mata: _mixi12_kongsted_runner("`GG'", "`beta2'", `N')

    local LR = r(LR)
    local df = r(df)
    local pval = chi2tail(`df', `LR')

    di
    di as text "{hline 78}"
    di as text "{bf:I(2)-to-I(1) transformation LR test}"
    di as text "{hline 78}"
    di as text _col(2) "H0: sp(τ) = sp(G)   — the linear combinations in G"
    di as text _col(8) "reduce the I(2) system to I(1)."
    di as text "{hline 78}"
    di as text _col(2) "Variables:" _col(20) "`e(depvars)'"
    di as text _col(2) "VAR lags:"   _col(20) "`e(lags)'"
    di as text _col(2) "(r, s_1, s_2):" _col(20) "(`r', `s1', `s2')"
    di as text _col(2) "N effective:" _col(20) "`N'"
    di as text "{hline 78}"
    di as text _col(2) "Candidate matrix G:"
    matlist `GG', format(%6.3f)
    di as text "{hline 78}"
    di as text _col(2) "LR statistic:" _col(28) %12.4f `LR'
    di as text _col(2) "Degrees of freedom:" _col(28) %12.0f `df'
    di as text _col(2) "p-value (χ²):" _col(28) %12.4f `pval'
    di as text "{hline 78}"
    local verdict = cond(`pval' < 0.05, "Reject — G is NOT a valid transformation", ///
                          "Do not reject — G is a valid I(2)-to-I(1) transformation")
    di as text _col(2) "Conclusion:" as result _col(20) "`verdict'"
    di as text "{hline 78}"

    return scalar LR = `LR'
    return scalar df = `df'
    return scalar p  = `pval'
    return local verdict "`verdict'"
end

version 14
mata:
void _mixi12_kongsted_runner(string scalar Gname, string scalar bname,
                             real scalar Tn)
{
    real matrix G, beta2
    real scalar LR, df
    G = st_matrix(Gname)
    beta2 = st_matrix(bname)
    _mixi12_kongsted(beta2, G, Tn, LR, df)
    st_numscalar("r(LR)", LR)
    st_numscalar("r(df)", df)
}
end
