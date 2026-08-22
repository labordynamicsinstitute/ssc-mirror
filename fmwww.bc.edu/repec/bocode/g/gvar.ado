*! gvar 1.0.1  21aug2026
*! Global Vector Autoregressive modelling: estimation, inference and
*! dynamic analysis (Pesaran-Schuermann-Weiner / Dees-di Mauro-Pesaran-Smith)
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* A faithful Stata implementation of
*   - GVAR Toolbox 2.0 (L. Vanessa Smith & Alessandro Galesi, August 2014)
*   - GVARX 1.2        (Ho Tsung-wu)
*   - BGVAR 2.6.0      (Boeck, Feldkircher & Huber)
*
* See  help gvar          for the overview
*      help gvar methods  for the equation-by-equation derivation and the
*                         step -> source map

program define gvar, rclass
    version 14.0

    _gvar_engine

    gettoken sub 0 : 0, parse(" ,")

    if ("`sub'" == "" | substr("`sub'", 1, 1) == ",") {
        _gvar_usage
        exit 198
    }

    local S = lower("`sub'")

    * ---- data and setup ---------------------------------------------------
    if ("`S'" == substr("setup", 1, max(3, length("`S'"))))       local go setup
    else if ("`S'" == substr("weights", 1, max(2, length("`S'")))) local go weights
    else if ("`S'" == substr("foreign", 1, max(3, length("`S'")))) local go foreign
    else if ("`S'" == substr("describe", 1, max(3, length("`S'")))) local go describe
    else if ("`S'" == "import")                                    local go import

    * ---- pre-estimation testing -------------------------------------------
    else if ("`S'" == substr("unitroot", 1, max(4, length("`S'")))) local go unitroot
    else if ("`S'" == substr("lags", 1, max(3, length("`S'"))))     local go lags
    else if ("`S'" == substr("coint", 1, max(3, length("`S'"))))    local go coint

    * ---- estimation --------------------------------------------------------
    else if ("`S'" == substr("estimate", 1, max(3, length("`S'")))) local go estimate
    else if ("`S'" == substr("solve", 1, max(3, length("`S'"))))    local go solve
    else if ("`S'" == substr("dominant", 1, max(3, length("`S'")))) local go dominant
    else if ("`S'" == substr("bayes", 1, max(3, length("`S'"))))    local go bayes

    * ---- post-estimation testing -------------------------------------------
    else if ("`S'" == substr("wetest", 1, max(2, length("`S'"))))    local go wetest
    else if ("`S'" == substr("overid", 1, max(4, length("`S'"))))    local go overid
    else if ("`S'" == substr("stability", 1, max(4, length("`S'")))) local go stability
    else if ("`S'" == substr("diagnostics", 1, max(4, length("`S'")))) local go diag
    else if ("`S'" == substr("avgcorr", 1, max(3, length("`S'"))))   local go avgcorr
    else if ("`S'" == substr("contemp", 1, max(4, length("`S'"))))   local go contemp
    else if ("`S'" == "gc")                                          local go gc

    * ---- dynamic analysis ---------------------------------------------------
    else if ("`S'" == "irf")                                         local go irf
    else if ("`S'" == "fevd")                                        local go fevd
    else if ("`S'" == "pp")                                          local go pp
    else if ("`S'" == "hd")                                          local go hd
    else if ("`S'" == substr("spillover", 1, max(4, length("`S'")))) local go spillover
    else if ("`S'" == substr("forecast", 1, max(4, length("`S'"))))  local go forecast
    else if ("`S'" == substr("tcdecomp", 1, max(2, length("`S'"))))  local go tcdecomp

    * ---- Bayesian post-estimation -------------------------------------------
    else if ("`S'" == substr("bconv", 1, max(5, length("`S'"))))     local go bconv
    else if ("`S'" == substr("bdic", 1, max(4, length("`S'"))))      local go bdic
    else if ("`S'" == substr("bforecast", 1, max(5, length("`S'")))) local go bfore

    * ---- reporting and state -------------------------------------------------
    else if ("`S'" == substr("report", 1, max(3, length("`S'"))))    local go report
    else if ("`S'" == "save")                                        local go savemodel
    else if ("`S'" == "use")                                         local go usemodel
    else if ("`S'" == "clear")                                       local go clearmodel
    else if ("`S'" == "getdata")                                     local go getdata

    else {
        di as err "unknown gvar subcommand: {bf:`sub'}"
        _gvar_usage
        exit 198
    }


    * A routed subcommand whose ado is absent has two quite different causes, and
    * the message used to assert the wrong one.  "not present in your
    * installation" tells the user their copy is broken and invites them to
    * reinstall; for a subcommand that was never written that is simply false,
    * and reinstalling cannot fix it.  Anything listed here is routed on purpose
    * -- so the name resolves and the abbreviation works -- but is not in this
    * release.
    * Anything listed here is routed on purpose -- so the name resolves and the
    * abbreviation works -- but is not in this release.  Empty now that
    * bforecast has landed; keep the branch, because the alternative when the
    * next planned subcommand is routed is a message telling the user their
    * installation is broken when it is not.
    local planned ""
    capture findfile _gvar_`go'.ado
    if (_rc) {
        if ("`planned'" != "" & strpos(" `planned' ", " `go' ")) {
            di as err "{bf:gvar `sub'} is not implemented in this release."
            exit 199
        }
        di as err "gvar `go': the file for this subcommand is missing from your"
        di as err "installation (expected {bf:_gvar_`go'.ado} on the adopath)."
        di as err "Re-install the package; every other subcommand was found."
        exit 601
    }

    _gvar_`go' `0'
    return add
end

* ---------------------------------------------------------------------------
program define _gvar_usage
    version 14.0
    di ""
    di as text "{hline 78}"
    di as text "  {bf:gvar} " _col(18) "Global Vector Autoregressive modelling"
    di as text "{hline 78}"
    di as text "  Data and setup"
    di as text "    {bf:gvar setup}" _col(22) "declare units, time, variables and the deterministic case"
    di as text "    {bf:gvar weights}" _col(22) "build or install the weight matrices"
    di as text "    {bf:gvar foreign}" _col(22) "construct the foreign-specific (star) variables"
    di as text "    {bf:gvar describe}" _col(22) "descriptive statistics of all variable blocks"
    di as text "    {bf:gvar import}" _col(22) "read a GVAR Toolbox workbook or a BGVAR-style list"
    di as text ""
    di as text "  Pre-estimation testing"
    di as text "    {bf:gvar unitroot}" _col(22) "ADF, WS, ADF-GLS, PP and KPSS on every variable block"
    di as text "    {bf:gvar lags}" _col(22) "VARX* order selection and residual serial correlation"
    di as text "    {bf:gvar coint}" _col(22) "trace / max-eigenvalue tests and rank selection"
    di as text ""
    di as text "  Estimation"
    di as text "    {bf:gvar estimate}" _col(22) "VECMX* reduced-rank ML of every country model"
    di as text "    {bf:gvar solve}" _col(22) "link matrices, stacking, reduced form and eigenvalues"
    di as text "    {bf:gvar bayes}" _col(22) "Bayesian GVAR with MN, SSVS, NG or HS shrinkage"
    di as text "    {bf:gvar dominant}" _col(22) "dominant-unit / global-exogenous model"
    di as text ""
    di as text "  Post-estimation testing"
    di as text "    {bf:gvar wetest}" _col(22) "weak exogeneity test"
    di as text "    {bf:gvar overid}" _col(22) "over-identifying restrictions LR test"
    di as text "    {bf:gvar stability}" _col(22) "structural stability battery"
    di as text "    {bf:gvar diag}" _col(22) "residual diagnostics"
    di as text "    {bf:gvar avgcorr}" _col(22) "average pairwise cross-section correlations"
    di as text "    {bf:gvar contemp}" _col(22) "contemporaneous effects of foreign variables"
    di as text "    {bf:gvar gc}" _col(22) "Granger causality"
    di as text ""
    di as text "  Dynamic analysis"
    di as text "    {bf:gvar irf}" _col(22) "generalized, orthogonalised and structural IRF"
    di as text "    {bf:gvar fevd}" _col(22) "generalised and orthogonalised FEVD"
    di as text "    {bf:gvar pp}" _col(22) "persistence profiles"
    di as text "    {bf:gvar hd}" _col(22) "historical decomposition"
    di as text "    {bf:gvar spillover}" _col(22) "connectedness table and indices"
    di as text "    {bf:gvar forecast}" _col(22) "unconditional and conditional forecasts"
    di as text "    {bf:gvar tcdecomp}" _col(22) "permanent / transitory decomposition"
    di as text ""
    di as text "  Reporting"
    di as text "    {bf:gvar report}" _col(22) "run the standard battery and build the dashboard"
    di as text "    {bf:gvar save} / {bf:gvar use}" _col(22) "serialise or restore the fitted model"
    di as text "{hline 78}"
    di as text "  See {help gvar} for the full syntax and {help gvar_methods:help gvar methods}"
    di as text "  for the equation-by-equation derivation."
    di ""
end
