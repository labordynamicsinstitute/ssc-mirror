*! _trop_estat_table
*! Export TROP estimation results as formatted academic tables
*
*  Syntax:
*      estat table [, Format(string) SAVing(string) TItle(string) NOtes(string)
*                     STArs APPend Replace DECimals(integer 4)]
*
*  Formats:
*      display  - Stata console table (default)
*      latex    - LaTeX tabular environment (AER/QJE style)
*      markdown - GitHub-flavored Markdown table
*      csv      - Comma-separated values
*
*  Description:
*      Produces a publication-quality results table from the e() values
*      stored after a trop estimation command.  Supports four output
*      formats and optional significance stars.

program define _trop_estat_table
    version 17
    syntax [, Format(string) SAVing(string) TItle(string) NOtes(string) ///
        STArs APPend Replace DECimals(integer 4)]

    // ── validate estimation context ──────────────────────────────────────
    if "`e(cmd)'" != "trop" {
        di as error "estat table requires trop estimation results"
        exit 301
    }

    // ── defaults ─────────────────────────────────────────────────────────
    if `"`format'"' == "" local format "display"

    // Validate format option
    if !inlist("`format'", "display", "latex", "markdown", "csv") {
        di as error "format() must be one of: display, latex, markdown, csv"
        exit 198
    }

    if `"`title'"' == "" local title "TROP Estimation Results"

    // ── extract e() results ──────────────────────────────────────────────
    local att = e(att)
    local se  = e(se)
    local ci_lower = e(ci_lower)
    local ci_upper = e(ci_upper)
    local pvalue = e(pvalue)
    local lambda_time = e(lambda_time)
    local lambda_unit = e(lambda_unit)
    local lambda_nn = e(lambda_nn)
    local method "`e(method)'"

    // Sample dimensions
    local N_units = e(N_units)
    local N_periods = e(N_periods)
    local N_treated = e(N_treated_units)
    local bootstrap_reps = e(bootstrap_reps)

    // Optional scalars (may be missing)
    capture local loocv_rmse = e(loocv_rmse)
    if _rc local loocv_rmse = .
    capture local effective_rank = e(effective_rank)
    if _rc local effective_rank = .
    capture local converged = e(converged)
    if _rc local converged = .

    // ── significance stars ───────────────────────────────────────────────
    local star ""
    if "`stars'" != "" & !missing(`pvalue') {
        if `pvalue' < 0.01      local star "***"
        else if `pvalue' < 0.05 local star "**"
        else if `pvalue' < 0.1  local star "*"
    }

    // ── format strings ───────────────────────────────────────────────────
    local fmt_coef  "%`=`decimals'+3'.`decimals'f"
    local fmt_int   "%8.0f"
    local fmt_rank  "%6.1f"

    // ── file handling ────────────────────────────────────────────────────
    if `"`saving'"' != "" {
        // Check append/replace logic
        if "`append'" == "" & "`replace'" == "" {
            capture confirm file `"`saving'"'
            if !_rc {
                di as error "file `saving' already exists"
                di as error "specify {bf:replace} to overwrite or {bf:append} to add"
                exit 602
            }
        }
        tempname fh
        if "`append'" != "" {
            file open `fh' using `"`saving'"', write text append
        }
        else {
            file open `fh' using `"`saving'"', write text replace
        }
    }

    // ── dispatch to format-specific output ───────────────────────────────
    if "`format'" == "display" {
        _trop_table_display, att(`att') se(`se') ci_lower(`ci_lower')    ///
            ci_upper(`ci_upper') pvalue(`pvalue') star("`star'")          ///
            lambda_time(`lambda_time') lambda_unit(`lambda_unit')         ///
            lambda_nn(`lambda_nn') method("`method'")                     ///
            n_units(`N_units') n_periods(`N_periods')                     ///
            n_treated(`N_treated') bootstrap_reps(`bootstrap_reps')       ///
            loocv_rmse(`loocv_rmse') effective_rank(`effective_rank')     ///
            converged(`converged') title(`"`title'"')                     ///
            decimals(`decimals')
    }
    else if "`format'" == "latex" {
        _trop_table_latex, att(`att') se(`se') ci_lower(`ci_lower')      ///
            ci_upper(`ci_upper') pvalue(`pvalue') star("`star'")          ///
            lambda_time(`lambda_time') lambda_unit(`lambda_unit')         ///
            lambda_nn(`lambda_nn') method("`method'")                     ///
            n_units(`N_units') n_periods(`N_periods')                     ///
            n_treated(`N_treated') bootstrap_reps(`bootstrap_reps')       ///
            loocv_rmse(`loocv_rmse') effective_rank(`effective_rank')     ///
            converged(`converged') title(`"`title'"') notes(`"`notes'"')  ///
            decimals(`decimals') fh(`fh')
    }
    else if "`format'" == "markdown" {
        _trop_table_markdown, att(`att') se(`se') ci_lower(`ci_lower')   ///
            ci_upper(`ci_upper') pvalue(`pvalue') star("`star'")          ///
            lambda_time(`lambda_time') lambda_unit(`lambda_unit')         ///
            lambda_nn(`lambda_nn') method("`method'")                     ///
            n_units(`N_units') n_periods(`N_periods')                     ///
            n_treated(`N_treated') bootstrap_reps(`bootstrap_reps')       ///
            loocv_rmse(`loocv_rmse') effective_rank(`effective_rank')     ///
            converged(`converged') title(`"`title'"') notes(`"`notes'"')  ///
            decimals(`decimals') fh(`fh')
    }
    else if "`format'" == "csv" {
        _trop_table_csv, att(`att') se(`se') ci_lower(`ci_lower')        ///
            ci_upper(`ci_upper') pvalue(`pvalue') star("`star'")          ///
            lambda_time(`lambda_time') lambda_unit(`lambda_unit')         ///
            lambda_nn(`lambda_nn') method("`method'")                     ///
            n_units(`N_units') n_periods(`N_periods')                     ///
            n_treated(`N_treated') bootstrap_reps(`bootstrap_reps')       ///
            loocv_rmse(`loocv_rmse') effective_rank(`effective_rank')     ///
            converged(`converged') title(`"`title'"') notes(`"`notes'"')  ///
            decimals(`decimals') fh(`fh')
    }

    // ── close file ───────────────────────────────────────────────────────
    if `"`saving'"' != "" {
        file close `fh'
        di as txt "(results written to {bf:`saving'})"
    }
end


/* ═══════════════════════════════════════════════════════════════════════════
   Display format — Stata console
   ═══════════════════════════════════════════════════════════════════════════ */
program define _trop_table_display
    syntax , att(string) se(string) ci_lower(string) ci_upper(string)     ///
        pvalue(string) lambda_time(string) lambda_unit(string) ///
        lambda_nn(string) method(string) n_units(string) n_periods(string)  ///
        n_treated(string) bootstrap_reps(string) loocv_rmse(string)         ///
        effective_rank(string) converged(string) title(string)              ///
        decimals(integer) [star(string)]

    local fmt "%`=`decimals'+3'.`decimals'f"
    local w 47

    di as txt ""
    di as txt "{hline `w'}"
    di as txt _col(2) "`title'"
    di as txt "{hline `w'}"

    // ATT with stars
    local att_str : di `fmt' `att'
    local att_str = strtrim("`att_str'")
    di as txt _col(2) "ATT" _col(30) as res "`att_str'`star'"

    // Standard error in parentheses
    if !missing(`se') {
        local se_str : di `fmt' `se'
        local se_str = strtrim("`se_str'")
        di as txt _col(30) as res "(`se_str')"
    }

    // Confidence interval
    if !missing(`ci_lower') & !missing(`ci_upper') {
        local ci_l_str : di `fmt' `ci_lower'
        local ci_u_str : di `fmt' `ci_upper'
        local ci_l_str = strtrim("`ci_l_str'")
        local ci_u_str = strtrim("`ci_u_str'")
        di as txt _col(2) "95% CI" _col(30) as res "[`ci_l_str', `ci_u_str']"
    }

    // p-value
    if !missing(`pvalue') {
        if `pvalue' < 0.001 {
            di as txt _col(2) "p-value" _col(30) as res "<0.001"
        }
        else {
            local pv_str : di %7.3f `pvalue'
            local pv_str = strtrim("`pv_str'")
            di as txt _col(2) "p-value" _col(30) as res "`pv_str'"
        }
    }

    di as txt "{hline `w'}"

    // Hyperparameters
    if !missing(`lambda_time') {
        local lt_str : di `fmt' `lambda_time'
        di as txt _col(2) "{&lambda}_time" _col(30) as res strtrim("`lt_str'")
    }
    if !missing(`lambda_unit') {
        local lu_str : di `fmt' `lambda_unit'
        di as txt _col(2) "{&lambda}_unit" _col(30) as res strtrim("`lu_str'")
    }
    if !missing(`lambda_nn') {
        local ln_str : di `fmt' `lambda_nn'
        di as txt _col(2) "{&lambda}_nn" _col(30) as res strtrim("`ln_str'")
    }

    di as txt "{hline `w'}"

    // Sample info
    if !missing(`n_units') {
        di as txt _col(2) "N (units)" _col(30) as res %8.0f `n_units'
    }
    if !missing(`n_periods') {
        di as txt _col(2) "T (periods)" _col(30) as res %8.0f `n_periods'
    }
    if !missing(`n_treated') {
        di as txt _col(2) "N_treated" _col(30) as res %8.0f `n_treated'
    }
    if !missing(`bootstrap_reps') & `bootstrap_reps' > 0 {
        di as txt _col(2) "Bootstrap reps" _col(30) as res %8.0f `bootstrap_reps'
    }
    di as txt _col(2) "Method" _col(30) as res "`method'"

    di as txt "{hline `w'}"

    // Diagnostics
    if !missing(`loocv_rmse') {
        local rmse_str : di `fmt' `loocv_rmse'
        di as txt _col(2) "LOOCV RMSE" _col(30) as res strtrim("`rmse_str'")
    }
    if !missing(`effective_rank') {
        local rank_str : di %6.1f `effective_rank'
        di as txt _col(2) "Effective rank" _col(30) as res strtrim("`rank_str'")
    }
    if !missing(`converged') {
        local conv_str = cond(`converged' == 1, "Yes", "No")
        di as txt _col(2) "Convergence" _col(30) as res "`conv_str'"
    }

    di as txt "{hline `w'}"

    // Stars legend
    if "`star'" != "" {
        di as txt _col(2) "{it:*** p<0.01, ** p<0.05, * p<0.1}"
    }
end


/* ═══════════════════════════════════════════════════════════════════════════
   LaTeX format — AER/QJE tabular style
   ═══════════════════════════════════════════════════════════════════════════ */
program define _trop_table_latex
    syntax , att(string) se(string) ci_lower(string) ci_upper(string)     ///
        pvalue(string) lambda_time(string) lambda_unit(string) ///
        lambda_nn(string) method(string) n_units(string) n_periods(string)  ///
        n_treated(string) bootstrap_reps(string) loocv_rmse(string)         ///
        effective_rank(string) converged(string) title(string)              ///
        decimals(integer) [notes(string) fh(string) star(string)]

    local fmt "%`=`decimals'+3'.`decimals'f"

    // Build LaTeX star notation
    local latex_star ""
    if "`star'" == "***"     local latex_star "^{***}"
    else if "`star'" == "**" local latex_star "^{**}"
    else if "`star'" == "*"  local latex_star "^{*}"

    // Format values
    local att_str : di `fmt' `att'
    local att_str = strtrim("`att_str'")
    local se_str : di `fmt' `se'
    local se_str = strtrim("`se_str'")

    // Macro for writing: either to file or display
    if "`fh'" != "" {
        file write `fh' "\begin{table}[htbp]" _n
        file write `fh' "\centering" _n
        file write `fh' `"\caption{`title'}"' _n
        file write `fh' "\begin{tabular}{lc}" _n
        file write `fh' "\hline\hline" _n
        file write `fh' " & (1) \\" _n
        file write `fh' "\hline" _n

        // ATT
        file write `fh' `"ATT & \$`att_str'`latex_star'\$ \\"' _n
        if !missing(`se') {
            file write `fh' `" & (`se_str') \\"' _n
        }

        file write `fh' "\hline" _n

        // Hyperparameters
        if !missing(`lambda_time') {
            local lt_str : di `fmt' `lambda_time'
            local lt_str = strtrim("`lt_str'")
            file write `fh' `"\$\\lambda_{time}\$ & `lt_str' \\"' _n
        }
        if !missing(`lambda_unit') {
            local lu_str : di `fmt' `lambda_unit'
            local lu_str = strtrim("`lu_str'")
            file write `fh' `"\$\\lambda_{unit}\$ & `lu_str' \\"' _n
        }
        if !missing(`lambda_nn') {
            local ln_str : di `fmt' `lambda_nn'
            local ln_str = strtrim("`ln_str'")
            file write `fh' `"\$\\lambda_{nn}\$ & `ln_str' \\"' _n
        }

        file write `fh' "\hline" _n

        // Sample info
        if !missing(`n_units') {
            file write `fh' "N (units) & " (`n_units') " \\" _n
        }
        if !missing(`n_periods') {
            file write `fh' "T (periods) & " (`n_periods') " \\" _n
        }
        if !missing(`bootstrap_reps') & `bootstrap_reps' > 0 {
            file write `fh' "Bootstrap reps & " (`bootstrap_reps') " \\" _n
        }
        file write `fh' `"Method & `method' \\"' _n

        file write `fh' "\hline\hline" _n

        // Notes
        file write `fh' "\multicolumn{2}{l}{\footnotesize Standard errors in parentheses} \\" _n
        if "`star'" != "" {
            file write `fh' "\multicolumn{2}{l}{\footnotesize *** p\$<\$0.01, ** p\$<\$0.05, * p\$<\$0.1} \\" _n
        }
        if `"`notes'"' != "" {
            file write `fh' `"\multicolumn{2}{l}{\footnotesize `notes'} \\"' _n
        }

        file write `fh' "\end{tabular}" _n
        file write `fh' "\end{table}" _n
    }
    else {
        // Display LaTeX to console
        di as txt "\begin{table}[htbp]"
        di as txt "\centering"
        di as txt `"\caption{`title'}"'
        di as txt "\begin{tabular}{lc}"
        di as txt "\hline\hline"
        di as txt " & (1) \\"
        di as txt "\hline"
        di as txt `"ATT & $`att_str'`latex_star'$ \\"'
        if !missing(`se') {
            di as txt `" & (`se_str') \\"'
        }
        di as txt "\hline"
        if !missing(`lambda_time') {
            local lt_str : di `fmt' `lambda_time'
            local lt_str = strtrim("`lt_str'")
            di as txt `"$\lambda_{time}$ & `lt_str' \\"'
        }
        if !missing(`lambda_unit') {
            local lu_str : di `fmt' `lambda_unit'
            local lu_str = strtrim("`lu_str'")
            di as txt `"$\lambda_{unit}$ & `lu_str' \\"'
        }
        if !missing(`lambda_nn') {
            local ln_str : di `fmt' `lambda_nn'
            local ln_str = strtrim("`ln_str'")
            di as txt `"$\lambda_{nn}$ & `ln_str' \\"'
        }
        di as txt "\hline"
        if !missing(`n_units') {
            di as txt "N (units) & " `n_units' " \\"
        }
        if !missing(`n_periods') {
            di as txt "T (periods) & " `n_periods' " \\"
        }
        if !missing(`bootstrap_reps') & `bootstrap_reps' > 0 {
            di as txt "Bootstrap reps & " `bootstrap_reps' " \\"
        }
        di as txt `"Method & `method' \\"'
        di as txt "\hline\hline"
        di as txt "\multicolumn{2}{l}{\footnotesize Standard errors in parentheses} \\"
        if "`star'" != "" {
            di as txt "\multicolumn{2}{l}{\footnotesize *** p$<$0.01, ** p$<$0.05, * p$<$0.1} \\"
        }
        di as txt "\end{tabular}"
        di as txt "\end{table}"
    }
end


/* ═══════════════════════════════════════════════════════════════════════════
   Markdown format — GitHub-flavored table
   ═══════════════════════════════════════════════════════════════════════════ */
program define _trop_table_markdown
    syntax , att(string) se(string) ci_lower(string) ci_upper(string)     ///
        pvalue(string) lambda_time(string) lambda_unit(string) ///
        lambda_nn(string) method(string) n_units(string) n_periods(string)  ///
        n_treated(string) bootstrap_reps(string) loocv_rmse(string)         ///
        effective_rank(string) converged(string) title(string)              ///
        decimals(integer) [notes(string) fh(string) star(string)]

    local fmt "%`=`decimals'+3'.`decimals'f"

    // Format values
    local att_str : di `fmt' `att'
    local att_str = strtrim("`att_str'")
    local se_str : di `fmt' `se'
    local se_str = strtrim("`se_str'")

    if "`fh'" != "" {
        file write `fh' `"## `title'"' _n
        file write `fh' "" _n
        file write `fh' "| | Estimate |" _n
        file write `fh' "|---|---|" _n
        file write `fh' `"| ATT | `att_str'`star' |"' _n
        if !missing(`se') {
            file write `fh' `"| | (`se_str') |"' _n
        }
        if !missing(`ci_lower') & !missing(`ci_upper') {
            local ci_l_str : di `fmt' `ci_lower'
            local ci_u_str : di `fmt' `ci_upper'
            local ci_l_str = strtrim("`ci_l_str'")
            local ci_u_str = strtrim("`ci_u_str'")
            file write `fh' `"| 95% CI | [`ci_l_str', `ci_u_str'] |"' _n
        }
        if !missing(`lambda_time') {
            local lt_str : di `fmt' `lambda_time'
            local lt_str = strtrim("`lt_str'")
            file write `fh' `"| {&lambda}_time | `lt_str' |"' _n
        }
        if !missing(`lambda_unit') {
            local lu_str : di `fmt' `lambda_unit'
            local lu_str = strtrim("`lu_str'")
            file write `fh' `"| {&lambda}_unit | `lu_str' |"' _n
        }
        if !missing(`lambda_nn') {
            local ln_str : di `fmt' `lambda_nn'
            local ln_str = strtrim("`ln_str'")
            file write `fh' `"| {&lambda}_nn | `ln_str' |"' _n
        }
        if !missing(`n_units') {
            file write `fh' "| N (units) | " (`n_units') " |" _n
        }
        if !missing(`n_periods') {
            file write `fh' "| T (periods) | " (`n_periods') " |" _n
        }
        if !missing(`n_treated') {
            file write `fh' "| N_treated | " (`n_treated') " |" _n
        }
        if !missing(`bootstrap_reps') & `bootstrap_reps' > 0 {
            file write `fh' "| Bootstrap reps | " (`bootstrap_reps') " |" _n
        }
        file write `fh' `"| Method | `method' |"' _n
        file write `fh' "" _n
        if "`star'" != "" {
            file write `fh' "_*** p<0.01, ** p<0.05, * p<0.1_" _n
        }
        if `"`notes'"' != "" {
            file write `fh' `"_`notes'_"' _n
        }
    }
    else {
        // Display to console
        di as txt ""
        di as txt "## `title'"
        di as txt ""
        di as txt "| | Estimate |"
        di as txt "|---|---|"
        di as txt `"| ATT | `att_str'`star' |"'
        if !missing(`se') {
            di as txt `"| | (`se_str') |"'
        }
        if !missing(`ci_lower') & !missing(`ci_upper') {
            local ci_l_str : di `fmt' `ci_lower'
            local ci_u_str : di `fmt' `ci_upper'
            local ci_l_str = strtrim("`ci_l_str'")
            local ci_u_str = strtrim("`ci_u_str'")
            di as txt `"| 95% CI | [`ci_l_str', `ci_u_str'] |"'
        }
        if !missing(`lambda_time') {
            local lt_str : di `fmt' `lambda_time'
            local lt_str = strtrim("`lt_str'")
            di as txt `"| {&lambda}_time | `lt_str' |"'
        }
        if !missing(`lambda_unit') {
            local lu_str : di `fmt' `lambda_unit'
            local lu_str = strtrim("`lu_str'")
            di as txt `"| {&lambda}_unit | `lu_str' |"'
        }
        if !missing(`lambda_nn') {
            local ln_str : di `fmt' `lambda_nn'
            local ln_str = strtrim("`ln_str'")
            di as txt `"| {&lambda}_nn | `ln_str' |"'
        }
        if !missing(`n_units') {
            di as txt "| N (units) | " `n_units' " |"
        }
        if !missing(`n_periods') {
            di as txt "| T (periods) | " `n_periods' " |"
        }
        if !missing(`n_treated') {
            di as txt "| N_treated | " `n_treated' " |"
        }
        if !missing(`bootstrap_reps') & `bootstrap_reps' > 0 {
            di as txt "| Bootstrap reps | " `bootstrap_reps' " |"
        }
        di as txt `"| Method | `method' |"'
        di as txt ""
        if "`star'" != "" {
            di as txt "_*** p<0.01, ** p<0.05, * p<0.1_"
        }
    }
end


/* ═══════════════════════════════════════════════════════════════════════════
   CSV format — machine-readable export
   ═══════════════════════════════════════════════════════════════════════════ */
program define _trop_table_csv
    syntax , att(string) se(string) ci_lower(string) ci_upper(string)     ///
        pvalue(string) lambda_time(string) lambda_unit(string) ///
        lambda_nn(string) method(string) n_units(string) n_periods(string)  ///
        n_treated(string) bootstrap_reps(string) loocv_rmse(string)         ///
        effective_rank(string) converged(string) title(string)              ///
        decimals(integer) [notes(string) fh(string) star(string)]

    local fmt "%`=`decimals'+3'.`decimals'f"

    // Format numeric values
    local att_str : di `fmt' `att'
    local att_str = strtrim("`att_str'")

    if "`fh'" != "" {
        file write `fh' "Parameter,Value" _n
        file write `fh' `"ATT,`att_str'"' _n
        if !missing(`se') {
            local se_str : di `fmt' `se'
            local se_str = strtrim("`se_str'")
            file write `fh' `"SE,`se_str'"' _n
        }
        if !missing(`ci_lower') & !missing(`ci_upper') {
            local ci_l_str : di `fmt' `ci_lower'
            local ci_u_str : di `fmt' `ci_upper'
            local ci_l_str = strtrim("`ci_l_str'")
            local ci_u_str = strtrim("`ci_u_str'")
            file write `fh' `"CI_lower,`ci_l_str'"' _n
            file write `fh' `"CI_upper,`ci_u_str'"' _n
        }
        if !missing(`pvalue') {
            local pv_str : di %8.6f `pvalue'
            local pv_str = strtrim("`pv_str'")
            file write `fh' `"p_value,`pv_str'"' _n
        }
        if !missing(`lambda_time') {
            local lt_str : di `fmt' `lambda_time'
            local lt_str = strtrim("`lt_str'")
            file write `fh' `"lambda_time,`lt_str'"' _n
        }
        if !missing(`lambda_unit') {
            local lu_str : di `fmt' `lambda_unit'
            local lu_str = strtrim("`lu_str'")
            file write `fh' `"lambda_unit,`lu_str'"' _n
        }
        if !missing(`lambda_nn') {
            local ln_str : di `fmt' `lambda_nn'
            local ln_str = strtrim("`ln_str'")
            file write `fh' `"lambda_nn,`ln_str'"' _n
        }
        if !missing(`n_units') {
            file write `fh' "N_units," (`n_units') _n
        }
        if !missing(`n_periods') {
            file write `fh' "N_periods," (`n_periods') _n
        }
        if !missing(`n_treated') {
            file write `fh' "N_treated," (`n_treated') _n
        }
        if !missing(`bootstrap_reps') & `bootstrap_reps' > 0 {
            file write `fh' "bootstrap_reps," (`bootstrap_reps') _n
        }
        file write `fh' `"method,`method'"' _n
        if !missing(`loocv_rmse') {
            local rmse_str : di `fmt' `loocv_rmse'
            local rmse_str = strtrim("`rmse_str'")
            file write `fh' `"loocv_rmse,`rmse_str'"' _n
        }
        if !missing(`effective_rank') {
            local rank_str : di %6.1f `effective_rank'
            local rank_str = strtrim("`rank_str'")
            file write `fh' `"effective_rank,`rank_str'"' _n
        }
        if !missing(`converged') {
            file write `fh' "converged," (`converged') _n
        }
    }
    else {
        // Display CSV to console
        di as txt "Parameter,Value"
        di as txt `"ATT,`att_str'"'
        if !missing(`se') {
            local se_str : di `fmt' `se'
            local se_str = strtrim("`se_str'")
            di as txt `"SE,`se_str'"'
        }
        if !missing(`ci_lower') & !missing(`ci_upper') {
            local ci_l_str : di `fmt' `ci_lower'
            local ci_u_str : di `fmt' `ci_upper'
            local ci_l_str = strtrim("`ci_l_str'")
            local ci_u_str = strtrim("`ci_u_str'")
            di as txt `"CI_lower,`ci_l_str'"'
            di as txt `"CI_upper,`ci_u_str'"'
        }
        if !missing(`pvalue') {
            local pv_str : di %8.6f `pvalue'
            local pv_str = strtrim("`pv_str'")
            di as txt `"p_value,`pv_str'"'
        }
        if !missing(`lambda_time') {
            local lt_str : di `fmt' `lambda_time'
            local lt_str = strtrim("`lt_str'")
            di as txt `"lambda_time,`lt_str'"'
        }
        if !missing(`lambda_unit') {
            local lu_str : di `fmt' `lambda_unit'
            local lu_str = strtrim("`lu_str'")
            di as txt `"lambda_unit,`lu_str'"'
        }
        if !missing(`lambda_nn') {
            local ln_str : di `fmt' `lambda_nn'
            local ln_str = strtrim("`ln_str'")
            di as txt `"lambda_nn,`ln_str'"'
        }
        if !missing(`n_units') {
            di as txt "N_units," `n_units'
        }
        if !missing(`n_periods') {
            di as txt "N_periods," `n_periods'
        }
        if !missing(`n_treated') {
            di as txt "N_treated," `n_treated'
        }
        if !missing(`bootstrap_reps') & `bootstrap_reps' > 0 {
            di as txt "bootstrap_reps," `bootstrap_reps'
        }
        di as txt `"method,`method'"'
        if !missing(`loocv_rmse') {
            local rmse_str : di `fmt' `loocv_rmse'
            local rmse_str = strtrim("`rmse_str'")
            di as txt `"loocv_rmse,`rmse_str'"'
        }
        if !missing(`effective_rank') {
            local rank_str : di %6.1f `effective_rank'
            local rank_str = strtrim("`rank_str'")
            di as txt `"effective_rank,`rank_str'"'
        }
        if !missing(`converged') {
            di as txt "converged," `converged'
        }
    }
end
