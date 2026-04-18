*! _cupfm_export.ado - Export results (Excel, LaTeX, CSV) for cupfm
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Version: 1.0.1 - 2026-04-16 (First SSC submission)

capture program drop _cupfm_export
program define _cupfm_export
    version 14
    // STATA 17 BATCH FIX: integer() options cause r(197) in batch mode.
    // All numeric options declared as string() and converted manually.
    syntax, ///
        DEPvar(string)     ///
        INDepvars(string)  ///
        Ng(string)         ///
        Tobs(string)       ///
        Rfact(string)      ///
        Bwuse(string)      ///
        Niter(string)      ///
        FORmat(string)     ///   excel|latex|csv|all
        SAVing(string)
    // Convert string -> integer
    local ng    = int(real("`ng'"))
    local tobs  = int(real("`tobs'"))
    local rfact = int(real("`rfact'"))
    local bwuse = int(real("`bwuse'"))
    local niter = int(real("`niter'"))

    local nv : word count `indepvars'

    // ─── Retrieve matrices ───────────────────────────────────────────────
    tempname B_lsdv B_bai B_cup B_cup2 B_bc
    tempname T_lsdv T_bai T_cup T_cup2 T_bc
    matrix `B_lsdv'  = _cupfm_b_lsdv
    matrix `B_bai'   = _cupfm_b_baifm
    matrix `B_cup'   = _cupfm_b_cupfm
    matrix `B_cup2'  = _cupfm_b_cupfm2
    matrix `B_bc'    = _cupfm_b_cupbc
    matrix `T_lsdv'  = _cupfm_t_lsdv
    matrix `T_bai'   = _cupfm_t_baifm
    matrix `T_cup'   = _cupfm_t_cupfm
    matrix `T_cup2'  = _cupfm_t_cupfm2
    matrix `T_bc'    = _cupfm_t_cupbc

    local cv01 = invnormal(0.995)   // 2.576
    local cv05 = invnormal(0.975)   // 1.960
    local cv10 = invnormal(0.950)   // 1.645

    // ═══════════════════════════════════════════════════════════════════
    //  EXCEL EXPORT
    // ═══════════════════════════════════════════════════════════════════
    if "`format'" == "excel" | "`format'" == "all" {
        local xlsname = "`saving'.xlsx"
        capture rm "`xlsname'"

        putexcel set "`xlsname'", replace sheet("Coefficients")

        putexcel A1 = "cupfm -- Panel Cointegration with Common Factors"
        putexcel A2 = "Bai, Kao & Ng (2009) | Bai & Kao (2005)"
        putexcel A3 = "Date: `c(current_date)'  |  Author: Dr. Merwan Roudane"
        putexcel A4 = ""

        putexcel A5 = "Variable"   B5 = "LSDV"      C5 = "Bai FM"
        putexcel D5 = "CupFM"      E5 = "CupFM-bar" F5 = "CupBC"
        putexcel A5:F5, bold border(bottom)

        local row = 6
        forvalues j = 1/`nv' {
            local vname : word `j' of `indepvars'

            putexcel A`row' = "`vname'"
            putexcel B`row' = `B_lsdv'[1,`j'] ///
                              C`row' = `B_bai'[1,`j']  ///
                              D`row' = `B_cup'[1,`j']  ///
                              E`row' = `B_cup2'[1,`j'] ///
                              F`row' = `B_bc'[1,`j']
            local ++row

            local t1 = `T_lsdv'[1,`j']
            local t2 = `T_bai'[1,`j']
            local t3 = `T_cup'[1,`j']
            local t4 = `T_cup2'[1,`j']
            local t5 = `T_bc'[1,`j']
            putexcel A`row' = ""
            putexcel B`row' = "(`=string(`t1', "%6.3f")')" ///
                              C`row' = "(`=string(`t2', "%6.3f")')" ///
                              D`row' = "(`=string(`t3', "%6.3f")')" ///
                              E`row' = "(`=string(`t4', "%6.3f")')" ///
                              F`row' = "(`=string(`t5', "%6.3f")')"
            local ++row
        }

        putexcel A`row' = "Iterations" B`row' = "---" C`row' = "1" ///
                          D`row' = "`niter'"   E`row' = "`niter'"  ///
                          F`row' = "20"
        local ++row
        putexcel A`row' = "N (units)"   B`row' = `ng'   C`row' = `ng' D`row' = `ng'  E`row' = `ng'  F`row' = `ng'
        local ++row
        putexcel A`row' = "T (periods)" B`row' = `tobs' C`row' = `tobs' D`row' = `tobs' E`row' = `tobs' F`row' = `tobs'
        local ++row
        putexcel A`row' = "r (factors)" B`row' = `rfact' C`row' = `rfact' D`row' = `rfact' E`row' = `rfact' F`row' = `rfact'
        local ++row
        putexcel A`row' = "Bandwidth"   B`row' = `bwuse' C`row' = `bwuse' D`row' = `bwuse' E`row' = `bwuse' F`row' = `bwuse'
        local ++row
        putexcel A`row' = "*** p<0.01  ** p<0.05  * p<0.10  (t-stats in parentheses)"
        putexcel A`=`row'+1' = "Ref: Bai, Kao & Ng (2009, JoE 149:82-99)"

        di as text "  Excel file saved: `xlsname'"
    }

    // ═══════════════════════════════════════════════════════════════════
    //  LaTeX EXPORT
    // ═══════════════════════════════════════════════════════════════════
    if "`format'" == "latex" | "`format'" == "all" {
        local texname = "`saving'.tex"
        capture file close ftex
        file open ftex using "`texname'", write replace

        file write ftex "% cupfm -- Panel Cointegration Estimation Results" _n
        file write ftex "% Bai, Kao \& Ng (2009) | Bai \& Kao (2005)" _n
        file write ftex "% Generated: `c(current_date)'" _n
        file write ftex "\begin{table}[htbp]" _n
        file write ftex "  \centering" _n
        file write ftex "  \small" _n
        file write ftex "  \caption{Panel Cointegration Estimation Results}" _n
        file write ftex "  \label{tab:cupfm}" _n
        file write ftex "  \begin{tabular}{l*{5}{c}}" _n
        file write ftex "    \hline\hline" _n
        file write ftex "    & LSDV & Bai FM & CupFM & CupFM-bar & CupBC \\" _n
        file write ftex "    \hline" _n

        forvalues j = 1/`nv' {
            local vname : word `j' of `indepvars'
            local vn_tex = subinstr("`vname'", "_", "\_", .)

            forvalues e = 1/5 {
                local bnames "B_lsdv B_bai B_cup B_cup2 B_bc"
                local bn : word `e' of `bnames'
                local tnames "T_lsdv T_bai T_cup T_cup2 T_bc"
                local tn : word `e' of `tnames'
                local bv`e' = ``bn''[1, `j']
                local tv`e' = ``tn''[1, `j']
                local absT = abs(`tv`e'')
                local stars`e' = ""
                if `absT' >= `cv01' local stars`e' "^{***}"
                else if `absT' >= `cv05' local stars`e' "^{**}"
                else if `absT' >= `cv10' local stars`e' "^{*}"
            }

            file write ftex "    `vn_tex'"
            forvalues e = 1/5 {
                file write ftex " & $`=string(`bv`e'', "%7.4f")'`stars`e''$"
            }
            file write ftex " \\" _n

            file write ftex "    "
            forvalues e = 1/5 {
                file write ftex " & (`=string(`tv`e'', "%6.3f")')"
            }
            file write ftex " \\" _n

            if `j' < `nv' file write ftex "    & & & & & \\" _n
        }

        file write ftex "    \hline" _n
        file write ftex "    Iterations & --- & 1 & `niter' & `niter' & 20 \\" _n
        file write ftex "    N (units) & \multicolumn{5}{c}{`ng'} \\" _n
        file write ftex "    T (periods) & \multicolumn{5}{c}{`tobs'} \\" _n
        file write ftex "    r (factors) & \multicolumn{5}{c}{`rfact'} \\" _n
        file write ftex "    Bandwidth & \multicolumn{5}{c}{`bwuse' (Bartlett)} \\" _n
        file write ftex "    \hline\hline" _n
        file write ftex "  \end{tabular}" _n
        file write ftex "  \begin{tablenotes}" _n
        file write ftex "    \footnotesize" _n
        file write ftex "    \item \textit{Notes}: \$t\$-statistics in parentheses." _n
        file write ftex "    \$^{***}p<0.01\$, \$^{**}p<0.05\$, \$^{*}p<0.10\$." _n
        file write ftex "    CupFM = Continuously-Updated FM (Bai, Kao \& Ng 2009, Theorem~3)." _n
        file write ftex "    CupBC = Continuously-Updated Bias-Corrected (Theorem~2)." _n
        file write ftex "    Bai FM = Two-Step FM (Bai \& Kao 2005)." _n
        file write ftex "    LSDV = Least-Squares (within), ignores cross-sectional dependence." _n
        file write ftex "  \end{tablenotes}" _n
        file write ftex "\end{table}" _n
        file close ftex

        di as text "  LaTeX file saved: `texname'"
    }

    // ═══════════════════════════════════════════════════════════════════
    //  CSV EXPORT
    // ═══════════════════════════════════════════════════════════════════
    if "`format'" == "csv" | "`format'" == "all" {
        local csvname = "`saving'.csv"
        capture file close fcsv
        file open fcsv using "`csvname'", write replace

        file write fcsv "Variable,Estimator,Coefficient,t-statistic,Stars" _n
        file write fcsv "depvar: `depvar',N: `ng',T: `tobs',r: `rfact',bw: `bwuse'" _n

        local est_names "LSDV" "Bai_FM" "CupFM" "CupFM_bar" "CupBC"
        local bnames "B_lsdv B_bai B_cup B_cup2 B_bc"
        local tnames "T_lsdv T_bai T_cup T_cup2 T_bc"

        forvalues j = 1/`nv' {
            local vname : word `j' of `indepvars'
            forvalues e = 1/5 {
                local ename : word `e' of `est_names'
                local bn : word `e' of `bnames'
                local tn : word `e' of `tnames'
                local bv = ``bn''[1, `j']
                local tv = ``tn''[1, `j']
                local absT = abs(`tv')
                local stars = ""
                if `absT' >= `cv01' local stars "***"
                else if `absT' >= `cv05' local stars "**"
                else if `absT' >= `cv10' local stars "*"
                file write fcsv "`vname',`ename',`=string(`bv', "%10.6f")',`=string(`tv', "%8.4f")',`stars'" _n
            }
        }
        file close fcsv

        di as text "  CSV file saved: `csvname'"
    }
end
