*! 1.0.0 Ariel Linden 05Apr2026 


program define srh_test
	version 11

	syntax varlist(min=3 max=3) [if] [in]

	tokenize `varlist'
	local depvar `1'
	local f1     `2'
	local f2     `3'

	marksample touse

	// generate ranked y variable
	tempvar yvar
	quietly egen `yvar' = rank(`depvar') if `touse'

	// quietly run ANOVA
	quietly anova `yvar' `f1'##`f2' if `touse'

	// get scalars for computations and table
	local N      = e(N)
	local mss    = e(mss)
	local rss    = e(rss)
	local df_m   = e(df_m)
	local df_r   = e(df_r)
	local Fmodel = e(F)
	local Pmodel = Ftail(`df_m', `df_r', `Fmodel')

	local sstot  = `mss' + `rss'
	local mstot  = `sstot' / (`N' - 1)
	local ms_m   = `mss'  / `df_m'
	local ms_r   = `rss'  / `df_r'
	local df_tot = `N' - 1

	// count per-term results stored by anova, and find longest term name
	local maxterms 0
	local maxnmlen 0
	forval k = 1/20 {
		capture confirm scalar e(ss_`k')
		if _rc == 0 {
			local maxterms `k'
			local nm_k = e(term_`k')
			local nmlen = length("`nm_k'")
			if `nmlen' > `maxnmlen' local maxnmlen `nmlen'
		}
		else continue, break
	}

	// get label lengths for header
	local lw     = max(10, `maxnmlen')
	local indent = 24 - `lw'
	local hleft  = `lw' + 1
	local hright = 72

	// create table
	local sep "{space `indent'}{hline `hleft'}{c +}{hline `hright'}"

	// header
	di ""
	di as result "Scheirer-Ray-Hare Test (non-parametric alternative to two-way ANOVA)"
	di as txt ""	
	di as txt "                         Number of obs = " as res %9.0f `N'
	di ""

	// column headers
	di as txt								///
	   "{space `indent'}" %`lw's "Source"	///
	   " {c |}"								///
	   " " %10s "Partial SS"				///
	       %11s "df"						///
	       %11s "MS"						///
	       %9s  "F"							///
	       %10s "Prob>F"					///
	       %6s  "H"							///
	       %14s "Prob>chi2"

	// top separator
	di as txt "`sep'"

	// model row
	di as txt "{space `indent'}" %`lw's "Model" " {c |} "	///
	   as res												///
	   %10.4f `mss'											///
	   %11.0f `df_m'										///
	   %12.4f `ms_m'										///
	   %10.4f `Fmodel'										///
	   %8.4f  `Pmodel'										///
	   as txt %9s ""										///
	   %10s "" 

	// blank row
	di as txt "{space `indent'}" %`lw's "" " {c |}"

	// pre-term rows
	forval k = 1/`maxterms' {
		local ss_k  = e(ss_`k')
		local df_k  = e(df_`k')
		local ms_k  = `ss_k' / `df_k'
		local f_k   = e(F_`k')
		local pF_k  = Ftail(`df_k', `df_r', `f_k')
		local h_k   = `ss_k' / `mstot'
		local p_k   = chi2tail(`df_k', `h_k')
		local nm_k  = e(term_`k')

		di as txt "{space `indent'}" %`lw's "`nm_k'" " {c |} "	///
		   as res												///
		   %10.4f `ss_k'										///
		   %11.0f `df_k'										///
		   %12.4f `ms_k'										///
		   %10.4f `f_k'											///
		   %8.4f  `pF_k'										///
		   %9.4f  `h_k'											///
		   %10.4f `p_k'
	}

	// blank row
	di as txt "{space `indent'}" %`lw's "" " {c |}"

	// residual row
	di as txt "{space `indent'}" %`lw's "Residual" " {c |} "	///
	   as res													///
	   %10.4f `rss'												///
	   %11.0f `df_r'											///
	   %12.4f `ms_r'

	// separator after residual
	di as txt "`sep'"

	// total row
	di as txt "{space `indent'}" %`lw's "Total" " {c |} "	///
	   as res												///
	   %10.4f `sstot'										///
	   %11.0f `df_tot'										///
	   %12.4f `mstot'

end
