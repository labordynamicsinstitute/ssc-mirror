*! qardl_full v1.2.0 - Integrated QARDL workflow
*! Translates qardlFull from GAUSS QARDL 3.1.1
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*!   qardl_full y x1 x2 [if] [in], tau(numlist) [options]
*!
*! Runs the whole applied sequence in one call:
*!   1. information-criterion lag selection
*!   2. levels-form QARDL estimation
*!   3. QARDL-ECM estimation
*!   4. residual diagnostics on the levels fit
*!
*! No cointegration pre-test is run.  The Pesaran-Shin-Smith bounds test is
*! a conditional-mean (OLS) procedure and is not part of this package; see
*! the note in help qardl.

program define qardl_full, eclass
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in], TAU(numlist >0 <1 sort) ///
        [PMAX(integer 8) QMAX(integer 8) PMIN(integer 1) QMIN(integer 0) ///
         CRITerion(string) COVariance(string) HAClags(integer 0) ///
         ECMType(string) ///
         SYMmetry NODIAGnostics GRAPH]

    marksample touse

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    if "`criterion'" == "" local criterion "bic"
    if "`covariance'" == "" local covariance "iid"
    if "`ecmtype'" == "" local ecmtype "both"

    di as txt _n "{hline 70}"
    di as res "  QARDL Integrated Workflow"
    di as txt "  Cho, Kim & Shin (2015), Journal of Econometrics"
    di as txt "{hline 70}"
    di as txt "  Dependent variable : " as res "`depvar'"
    di as txt "  Regressors         : " as res "`indepvars'"
    di as txt "{hline 70}"

    * ------------------------------------------------------------
    * Step 1: lag selection
    * ------------------------------------------------------------
    di as txt _n as res "  Step 1: " as txt "selecting lag orders (" ///
        upper("`criterion'") ") ..."

    _qardl_icmean `varlist' if `touse', pmin(`pmin') pmax(`pmax') ///
        qmin(`qmin') qmax(`qmax') criterion(`criterion')

    local pst = r(p_opt)
    local qst = r(q_opt)

    di as txt "  " upper("`criterion'") "-selected: p = " as res `pst' ///
        as txt ", q = " as res `qst'

    * ------------------------------------------------------------
    * Steps 2 and 3: QARDL levels and ECM
    * ------------------------------------------------------------
    di as txt _n as res "  Step 2-3: " as txt "estimating QARDL and QARDL-ECM ..."

    qardl `varlist' if `touse', tau(`tau') p(`pst') q(`qst') ///
        covariance(`covariance') haclags(`haclags') ///
        ecm ecmtype(`ecmtype') `symmetry' `graph'

    ereturn local criterion "`criterion'"
    ereturn local workflow "qardl_full"

    * ------------------------------------------------------------
    * Step 4: residual diagnostics
    * ------------------------------------------------------------
    if "`nodiagnostics'" == "" {
        di as txt _n as res "  Step 4: " as txt "residual diagnostics ..."
        qardl_diag
    }

    * ------------------------------------------------------------
    * Summary
    * ------------------------------------------------------------
    di as txt _n "{hline 70}"
    di as res "  Workflow summary"
    di as txt "{hline 70}"
    di as txt "  Selected order     : " as res "QARDL(`pst',`qst')" ///
        as txt "  by " upper("`criterion'")
    di as txt "  Covariance         : " as res "`covariance'"
    di as txt "  ECM parameterisation: " as res "`ecmtype'"
    di as txt "{hline 70}"
    di as txt "  Next steps you may want:"
    di as txt "    {cmd:qardl_boot}      block-bootstrap confidence intervals"
    di as txt "    {cmd:qardl_qirf}      quantile impulse responses"
    di as txt "    {cmd:qardl_forecast}  dynamic forecasts"
    di as txt "    {cmd:qardl_export}    export the tables"
    di as txt "{hline 70}"
end
