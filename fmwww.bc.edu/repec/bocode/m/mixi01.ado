*! mixi01 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! mixi01 — Mixed Integration Econometric Methods
*! Master dispatcher command

program define mixi01, eclass sortpreserve
    version 17.0

    /* ── handle empty call or option-only calls ── */
    if `"`0'"' == "" {
        _mixi01_banner
        di as txt "  Type {cmd:mixi01} {it:subcmd} {cmd:--help} for subcommand help"
        di as txt "  Available: {cmd:fmols fmvar fmiv acl svar vecm irf test}"
        di ""
        exit 0
    }

    /* ── check for comma-prefixed options (mixi01, version) ── */
    local 0_copy `"`0'"'
    local has_comma = strpos(`"`0_copy'"', ",")
    
    if `has_comma' > 0 {
        local before_comma = substr(`"`0_copy'"', 1, `has_comma' - 1)
        local before_comma = strtrim(`"`before_comma'"')
        
        if `"`before_comma'"' == "" {
            /* pure option call: mixi01, version */
            local after_comma = substr(`"`0_copy'"', `has_comma' + 1, .)
            local after_comma = strtrim(`"`after_comma'"')
            local after_lower = strlower(`"`after_comma'"')
            
            if `"`after_lower'"' == "version" | `"`after_lower'"' == "ver" {
                _mixi01_version
                exit 0
            }
            else if `"`after_lower'"' == "cite" | `"`after_lower'"' == "citation" {
                _mixi01_cite
                exit 0
            }
            else if `"`after_lower'"' == "help" {
                _mixi01_banner
                _mixi01_help
                exit 0
            }
            else {
                di as err `"unknown option: `after_comma'"'
                exit 198
            }
        }
    }

    /* ── parse subcommand ── */
    gettoken subcmd rest : 0

    local subcmd = strlower(`"`subcmd'"')

    /* ── dispatch ── */
    if `"`subcmd'"' == "fmols" {
        mixi01_fmols `rest'
    }
    else if `"`subcmd'"' == "fmvar" {
        mixi01_fmvar `rest'
    }
    else if `"`subcmd'"' == "fmiv" {
        mixi01_fmiv `rest'
    }
    else if `"`subcmd'"' == "acl" {
        mixi01_acl `rest'
    }
    else if `"`subcmd'"' == "svar" {
        mixi01_svar `rest'
    }
    else if `"`subcmd'"' == "vecm" {
        mixi01_vecm `rest'
    }
    else if `"`subcmd'"' == "irf" {
        mixi01_irf `rest'
    }
    else if `"`subcmd'"' == "test" {
        mixi01_test `rest'
    }
    else if `"`subcmd'"' == "graph" {
        mixi01_graph `rest'
    }
    else if `"`subcmd'"' == "table" {
        mixi01_table `rest'
    }
    else if `"`subcmd'"' == "lrcov" {
        mixi01_lrcov `rest'
    }
    else if `"`subcmd'"' == "version" {
        _mixi01_version
    }
    else if `"`subcmd'"' == "cite" | `"`subcmd'"' == "citation" {
        _mixi01_cite
    }
    else if `"`subcmd'"' == "help" | `"`subcmd'"' == "--help" {
        _mixi01_banner
        _mixi01_help
    }
    else {
        di as err `"mixi01: unknown subcommand {bf:`subcmd'}"'
        di as err "  Valid subcommands: fmols fmvar fmiv acl svar vecm irf test"
        di as err "  Type {cmd:mixi01, help} for usage information"
        exit 198
    }
end


/* ================================================================== */
/*  Banner display                                                     */
/* ================================================================== */
program define _mixi01_banner
    version 17.0
    di ""
    di as txt "{hline 68}"
    di as res _col(4) "mixi01" as txt " {c -}{c -} Mixed Integration Econometric Methods"
    di as txt _col(4) "Version " as res "1.0.0" as txt " | " as res "2026-05-20"
    di as txt "{hline 68}"
    di as txt _col(4) "Based on:"
    di as txt _col(6) "Phillips (1995), " ///
              "Kitamura & Phillips (1997),"
    di as txt _col(6) "Fisher, Huh & Pagan (2015), " ///
              "Chen (2022)"
    di as txt "{hline 68}"
end


/* ================================================================== */
/*  Version display                                                    */
/* ================================================================== */
program define _mixi01_version
    version 17.0
    di ""
    di as txt "{hline 68}"
    di as res _col(4) "mixi01" as txt " {c -}{c -} Mixed Integration Econometric Methods"
    di as txt _col(4) "Version " as res "1.0.0" as txt " | " as res "2026-05-20"
    di as txt "{hline 68}"
    di as txt _col(4) "Stata requirement : " as res "version 17.0+"
    di as txt _col(4) "Mata library      : " as res "_mixi01_mata.mata"
    di as txt _col(4) "License           : " as res "MIT"
    di as txt "{hline 68}"
    di ""
end


/* ================================================================== */
/*  Citation display                                                   */
/* ================================================================== */
program define _mixi01_cite
    version 17.0
    di ""
    di as txt "{hline 68}"
    di as res _col(4) "Citation Information for mixi01"
    di as txt "{hline 68}"
    di ""
    di as txt "  If you use {cmd:mixi01} in your research, please cite:"
    di ""
    di as res "  [Software]"
    di as txt "  mixi01: Mixed Integration Econometric Methods for Stata."
    di as txt "  Version 1.0.0, 2026."
    di ""
    di as res "  [Methodological references]"
    di ""
    di as txt "  Phillips, P.C.B. (1995). Fully modified least squares and"
    di as txt "    vector autoregression. {it:Econometrica}, 63(5), 1023-1078."
    di ""
    di as txt "  Kitamura, Y. & Phillips, P.C.B. (1997). Fully modified IV,"
    di as txt "    GIVE and GMM estimation with possibly non-stationary"
    di as txt "    regressors and instruments. {it:Journal of Econometrics},"
    di as txt "    80(1), 85-123."
    di ""
    di as txt "  Fisher, L.A., Huh, H.-S. & Pagan, A.R. (2015). Econometric"
    di as txt "    methods for modelling systems with a mixture of I(1) and"
    di as txt "    I(0) variables. {it:Journal of Applied Econometrics},"
    di as txt "    31(5), 892-911."
    di ""
    di as txt "  Chen, P. (2022). Vector error correction models with"
    di as txt "    stationary and nonstationary variables."
    di as txt "    SSRN Working Paper No. 4218834."
    di ""
    di as txt "  Peng, Z. & Dong, C. (2021). Augmented cointegrating"
    di as txt "    linear models with possibly strongly correlated"
    di as txt "    stationary and nonstationary regressors."
    di as txt "    SSRN Working Paper No. 3943779."
    di ""
    di as txt "{hline 68}"
    di ""
end


/* ================================================================== */
/*  Help display                                                       */
/* ================================================================== */
program define _mixi01_help
    version 17.0
    di ""
    di as txt "  {ul:Estimation commands}"
    di as txt "    {cmd:mixi01 fmols}" _col(25) "Fully Modified OLS (single equation)"
    di as txt "    {cmd:mixi01 fmvar}" _col(25) "Fully Modified VAR (system)"
    di as txt "    {cmd:mixi01 fmiv}"  _col(25) "Fully Modified IV / GMM"
    di as txt "    {cmd:mixi01 acl}"   _col(25) "Augmented Cointegrating Linear (Peng-Dong 2021)"
    di as txt "    {cmd:mixi01 svar}"  _col(25) "Structural VAR with mixed integration"
    di as txt "    {cmd:mixi01 vecm}"  _col(25) "VECM for cointegrated I(1) subsystem"
    di ""
    di as txt "  {ul:Post-estimation}"
    di as txt "    {cmd:mixi01 irf}"   _col(25) "Impulse response functions"
    di as txt "    {cmd:mixi01 test}"  _col(25) "Wald tests (mixed-asymptotics)"
    di as txt "    {cmd:mixi01 graph}" _col(25) "Visualisation (IRF, FEVD, etc.)"
    di as txt "    {cmd:mixi01 table}" _col(25) "Redisplay estimation table"
    di ""
    di as txt "  {ul:Utilities}"
    di as txt "    {cmd:mixi01 lrcov}" _col(25) "Long-run covariance estimation"
    di as txt "    {cmd:mixi01, version}" _col(25) "Show version information"
    di as txt "    {cmd:mixi01, cite}" _col(25) "Show citation information"
    di ""
end
