*! qardl_export v1.2.0 - Export QARDL results to CSV, LaTeX or Markdown
*! Translates saveQARDLResults, saveQARDLECMResults, saveARDLTable,
*! saveARDLLaTeX and saveARDLMarkdown from GAUSS QARDL 3.1.1
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*!   qardl_export using filename [, format(csv|latex|markdown) replace
*!                                  digits(#) ci level(#) ecm ]

program define qardl_export
    version 14.0

    syntax using/ [, FORMat(string) REPLACE DIGits(integer 4) ///
        CI LEVel(cilevel) ECM]

    if "`e(cmd)'" != "qardl" {
        di as error "qardl estimation results not found"
        exit 301
    }

    if "`format'" == "" {
        * infer from the extension
        local ext = lower(substr("`using'", strrpos("`using'", ".") + 1, .))
        if "`ext'" == "tex"                    local format "latex"
        else if inlist("`ext'", "md", "mdown") local format "markdown"
        else                                   local format "csv"
    }
    local format = lower("`format'")
    if !inlist("`format'", "csv", "latex", "markdown") {
        di as error "format() must be csv, latex, or markdown"
        exit 198
    }

    if `digits' < 0 | `digits' > 12 {
        di as error "digits() must be between 0 and 12"
        exit 198
    }

    local p = e(p)
    local q = e(q)
    local k = e(k)
    local ntau = e(ntau)
    local depvar "`e(depvar)'"
    local indepvars "`e(indepvars)'"
    local nobs = e(N)

    local sb = e(scale_beta)
    local ss = e(scale_short)
    if `sb' >= . local sb = (`nobs' - 1)^2
    if `ss' >= . local ss = `nobs' - 1

    tempname tau_vec beta beta_cov gamma gamma_cov phi phi_cov
    mat `tau_vec' = e(tau)
    mat `beta' = e(beta)
    mat `beta_cov' = e(beta_cov)
    mat `gamma' = e(gamma)
    mat `gamma_cov' = e(gamma_cov)
    mat `phi' = e(phi)
    mat `phi_cov' = e(phi_cov)

    local zcrit = invnormal(1 - (100 - `level') / 200)

    * ------------------------------------------------------------
    * Open the file
    * ------------------------------------------------------------
    tempname fh
    capture file close `fh'
    file open `fh' using "`using'", write text `replace'

    local phinames ""
    forvalues j = 1/`p' {
        local phinames "`phinames' L`j'.`depvar'"
    }

    if "`format'" == "csv" {
        file write `fh' "block,parameter,tau,estimate,std_err,z,p_value"
        if "`ci'" != "" file write `fh' ",ci_lower,ci_upper"
        file write `fh' _n

        _qardl_exp_rows `fh' csv "beta"  `beta'  `beta_cov'  `tau_vec' `k' `sb' "`indepvars'" `digits' "`ci'" `zcrit'
        _qardl_exp_rows `fh' csv "gamma" `gamma' `gamma_cov' `tau_vec' `k' `ss' "`indepvars'" `digits' "`ci'" `zcrit'
        _qardl_exp_rows `fh' csv "phi"   `phi'   `phi_cov'   `tau_vec' `p' `ss' "`phinames'"   `digits' "`ci'" `zcrit'
    }
    else if "`format'" == "markdown" {
        file write `fh' "# QARDL(`p',`q') results" _n _n
        file write `fh' "- Dependent variable: `depvar'" _n
        file write `fh' "- Regressors: `indepvars'" _n
        file write `fh' "- Observations: `nobs'" _n
        file write `fh' "- Quantiles: "
        forvalues i = 1/`ntau' {
            local tv : di %4.2f `tau_vec'[`i',1]
            file write `fh' "`tv' "
        }
        file write `fh' _n
        file write `fh' "- Covariance: `e(covariance)'" _n _n

        _qardl_exp_mdhead `fh' "Long-run parameters: beta(tau)" "`ci'"
        _qardl_exp_rows `fh' md "beta" `beta' `beta_cov' `tau_vec' `k' `sb' "`indepvars'" `digits' "`ci'" `zcrit'
        file write `fh' _n
        _qardl_exp_mdhead `fh' "Short-run impact parameters: gamma(tau)" "`ci'"
        _qardl_exp_rows `fh' md "gamma" `gamma' `gamma_cov' `tau_vec' `k' `ss' "`indepvars'" `digits' "`ci'" `zcrit'
        file write `fh' _n
        _qardl_exp_mdhead `fh' "Short-run AR parameters: phi(tau)" "`ci'"
        _qardl_exp_rows `fh' md "phi" `phi' `phi_cov' `tau_vec' `p' `ss' "`phinames'" `digits' "`ci'" `zcrit'
        file write `fh' _n
        file write `fh' "Significance: *** p<0.01, ** p<0.05, * p<0.10" _n
    }
    else {
        local ncol = cond("`ci'" != "", 7, 5)
        file write `fh' "\begin{table}[htbp]" _n
        file write `fh' "\centering" _n
        file write `fh' "\caption{QARDL(`p',`q') estimates for \texttt{`depvar'}}" _n
        file write `fh' "\label{tab:qardl}" _n
        file write `fh' "\begin{tabular}{ll" _c
        forvalues c = 3/`ncol' {
            file write `fh' "r"
        }
        file write `fh' "r}" _n
        file write `fh' "\hline\hline" _n
        file write `fh' "Parameter & $\tau$ & Estimate & Std.\ err. & $z$ & $p$"
        if "`ci'" != "" file write `fh' " & CI lower & CI upper"
        file write `fh' " \\" _n "\hline" _n

        file write `fh' "\multicolumn{`ncol'}{l}{\textit{Long-run} $\beta(\tau)$} \\" _n
        _qardl_exp_rows `fh' tex "beta" `beta' `beta_cov' `tau_vec' `k' `sb' "`indepvars'" `digits' "`ci'" `zcrit'
        file write `fh' "\hline" _n
        file write `fh' "\multicolumn{`ncol'}{l}{\textit{Short-run impact} $\gamma(\tau)$} \\" _n
        _qardl_exp_rows `fh' tex "gamma" `gamma' `gamma_cov' `tau_vec' `k' `ss' "`indepvars'" `digits' "`ci'" `zcrit'
        file write `fh' "\hline" _n
        file write `fh' "\multicolumn{`ncol'}{l}{\textit{Short-run AR} $\phi(\tau)$} \\" _n
        _qardl_exp_rows `fh' tex "phi" `phi' `phi_cov' `tau_vec' `p' `ss' "`phinames'" `digits' "`ci'" `zcrit'

        file write `fh' "\hline\hline" _n
        file write `fh' "\multicolumn{`ncol'}{l}{\footnotesize N = `nobs'." _c
        file write `fh' " Covariance: `e(covariance)'." _c
        file write `fh' " *** p<0.01, ** p<0.05, * p<0.10} \\" _n
        file write `fh' "\end{tabular}" _n
        file write `fh' "\end{table}" _n
    }

    * ------------------------------------------------------------
    * ECM block
    * ------------------------------------------------------------
    if "`ecm'" != "" & "`e(model)'" == "qardl-ecm" {
        if inlist("`e(ecmtype)'", "twostep", "both") {
            tempname ea er eac erc
            mat `ea' = e(ecm_alpha)
            mat `eac' = e(ecm_alpha_cov)
            mat `er' = e(ecm_rho)
            mat `erc' = e(ecm_rho_cov)

            if "`format'" == "csv" {
                _qardl_exp_rows `fh' csv "alpha" `ea' `eac' `tau_vec' 1 1 "alpha" `digits' "`ci'" `zcrit'
                _qardl_exp_rows `fh' csv "rho"   `er' `erc' `tau_vec' 1 1 "rho"   `digits' "`ci'" `zcrit'
            }
            else if "`format'" == "markdown" {
                file write `fh' _n
                _qardl_exp_mdhead `fh' "Two-step ECM: alpha(tau) and rho(tau)" "`ci'"
                _qardl_exp_rows `fh' md "alpha" `ea' `eac' `tau_vec' 1 1 "alpha" `digits' "`ci'" `zcrit'
                _qardl_exp_rows `fh' md "rho"   `er' `erc' `tau_vec' 1 1 "rho"   `digits' "`ci'" `zcrit'
            }
        }
    }

    file close `fh'

    di as txt _n "  Results written to " as res "`using'" as txt " (`format')"
end

* ============================================================
* Markdown table header
* ============================================================
capture program drop _qardl_exp_mdhead
program define _qardl_exp_mdhead
    args fh title ci

    file write `fh' "## `title'" _n _n
    file write `fh' "| Parameter | tau | Estimate | Std. err. | z | p |"
    if "`ci'" != "" file write `fh' " CI lower | CI upper |"
    file write `fh' _n
    file write `fh' "|---|---:|---:|---:|---:|---:|"
    if "`ci'" != "" file write `fh' "---:|---:|"
    file write `fh' _n
end

* ============================================================
* Emit one parameter block
*   se = sqrt(diag(cov)/scale), matching the display tables
* ============================================================
capture program drop _qardl_exp_rows
program define _qardl_exp_rows
    args fh fmt block param cov tau_vec dim scale rownames digits ci zcrit

    local ntau = rowsof(`tau_vec')
    local nrows = rowsof(`param')
    local d = `digits'

    local idx = 1
    forvalues t = 1/`ntau' {
        local tv = `tau_vec'[`t', 1]
        foreach v of local rownames {
            if `idx' <= `nrows' {
                local est = `param'[`idx', 1]
                local vv = `cov'[`idx', `idx'] / `scale'
                if `vv' > 0 {
                    local se = sqrt(`vv')
                    local z = `est' / `se'
                    local pv = 2 * normal(-abs(`z'))
                    local lo = `est' - `zcrit' * `se'
                    local hi = `est' + `zcrit' * `se'
                }
                else {
                    local se = .
                    local z = .
                    local pv = .
                    local lo = .
                    local hi = .
                }

                if `pv' >= .          local star ""
                else if `pv' < 0.01   local star "***"
                else if `pv' < 0.05   local star "**"
                else if `pv' < 0.10   local star "*"
                else                  local star ""

                local se_s : di %`= `d' + 6'.`d'f `se'
                local es_s : di %`= `d' + 6'.`d'f `est'
                local z_s  : di %9.3f `z'
                local p_s  : di %7.4f `pv'
                local lo_s : di %`= `d' + 6'.`d'f `lo'
                local hi_s : di %`= `d' + 6'.`d'f `hi'
                local tv_s : di %4.2f `tv'

                if "`fmt'" == "csv" {
                    file write `fh' "`block',`v',`tv_s',"
                    file write `fh' "`= trim("`es_s'")',`= trim("`se_s'")',"
                    file write `fh' "`= trim("`z_s'")',`= trim("`p_s'")'"
                    if "`ci'" != "" {
                        file write `fh' ",`= trim("`lo_s'")',`= trim("`hi_s'")'"
                    }
                    file write `fh' _n
                }
                else if "`fmt'" == "md" {
                    file write `fh' "| `v' | `tv_s' | `= trim("`es_s'")'`star' | "
                    file write `fh' "`= trim("`se_s'")' | `= trim("`z_s'")' | `= trim("`p_s'")' |"
                    if "`ci'" != "" {
                        file write `fh' " `= trim("`lo_s'")' | `= trim("`hi_s'")' |"
                    }
                    file write `fh' _n
                }
                else {
                    local vtex = subinstr("`v'", "_", "\_", .)
                    file write `fh' "\texttt{`vtex'} & `tv_s' & "
                    file write `fh' "`= trim("`es_s'")'\sym{`star'} & `= trim("`se_s'")' & "
                    file write `fh' "`= trim("`z_s'")' & `= trim("`p_s'")'"
                    if "`ci'" != "" {
                        file write `fh' " & `= trim("`lo_s'")' & `= trim("`hi_s'")'"
                    }
                    file write `fh' " \\" _n
                }
                local ++idx
            }
        }
    }
end
