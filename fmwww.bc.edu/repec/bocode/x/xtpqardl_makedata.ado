*! xtpqardl_makedata v1.0.1 — Generate panel data for PQARDL testing
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

capture program drop xtpqardl_makedata
program define xtpqardl_makedata
	version 15.1
	syntax , [N(integer 10) T(integer 50) Seed(integer 12345) ///
			 K(integer 2) BETA1(real 2.5) BETA2(real 1.8) ///
			 PHI(real 0.35) CLEAR]
	
	if "`clear'" != "" {
		clear
	}
	
	if c(N) > 0 & "`clear'" == "" {
		di as err "data in memory would be lost; use clear option"
		exit 4
	}
	
	clear
	set seed `seed'
	
	local nobs = `n' * `t'
	
	di
	di in smcl in gr "{hline 70}"
	di in gr "{bf:XTPQARDL Data Generator}" _col(50) in ye "v1.0.1"
	di in smcl in gr "{hline 70}"
	di in gr "  Panels (N):          " in ye "`n'"
	di in gr "  Time periods (T):    " in ye "`t'"
	di in gr "  Variables (K):       " in ye "`k'"
	di in gr "  True beta_1:         " in ye "`beta1'"
	di in gr "  True beta_2:         " in ye "`beta2'"
	di in gr "  True phi (AR):       " in ye "`phi'"
	di in gr "  Seed:                " in ye "`seed'"
	di in smcl in gr "{hline 70}"
	
	* Generate panel structure
	qui set obs `nobs'
	qui gen int id = ceil(_n / `t')
	qui gen int time = mod(_n - 1, `t') + 1
	qui xtset id time
	
	* Generate I(1) independent variables per panel
	qui gen double x1 = 0
	qui gen double x2 = 0
	qui gen double y = 0
	
	* Panel-specific heterogeneity
	qui gen double alpha_i = 0
	qui gen double phi_i = 0
	
	forvalues i = 1/`n' {
		* Panel-specific intercept
		qui replace alpha_i = rnormal(0, 0.5) if id == `i' & time == 1
		qui replace alpha_i = alpha_i[_n-1] if id == `i' & time > 1
		
		* Panel-specific AR coefficient (heterogeneous short-run)
		local phi_i = `phi' + rnormal() * 0.1
		if `phi_i' >= 1 local phi_i = 0.85
		if `phi_i' <= -1 local phi_i = -0.85
		qui replace phi_i = `phi_i' if id == `i'
		
		* Generate random walks for x variables
		qui replace x1 = rnormal(0, 1) if id == `i' & time == 1
		qui replace x2 = rnormal(0, 1) if id == `i' & time == 1
		
		forvalues tt = 2/`t' {
			qui replace x1 = x1[_n-1] + rnormal(0, 0.5) ///
				if id == `i' & time == `tt'
			qui replace x2 = x2[_n-1] + rnormal(0, 0.5) ///
				if id == `i' & time == `tt'
		}
		
		* Generate y with cointegrating relationship + AR dynamics
		* y_it = alpha_i + phi_i * y_{it-1} + beta_1*x1 + beta_2*x2 + e_it
		* (in levels, with error correction towards equilibrium)
		qui replace y = alpha_i + `beta1' * x1 + `beta2' * x2 + rnormal(0, 1) ///
			if id == `i' & time == 1
		
		forvalues tt = 2/`t' {
			* ECM-type DGP: Δy = ρ*(y_{t-1} - β'x_{t-1}) + γ'Δx + ε
			* where ρ = phi - 1 (speed of adjustment)
			local rho = `phi_i' - 1
			qui replace y = y[_n-1] + ///
				`rho' * (y[_n-1] - `beta1'*x1[_n-1] - `beta2'*x2[_n-1] - alpha_i) + ///
				`beta1' * (x1 - x1[_n-1]) * (1 + 0.3*rnormal()) + ///
				`beta2' * (x2 - x2[_n-1]) * (1 + 0.3*rnormal()) + ///
				rnormal(0, 0.8) ///
				if id == `i' & time == `tt'
		}
	}
	
	* Generate first differences and lags for user convenience
	sort id time
	qui by id: gen double dy = y - y[_n-1]
	qui by id: gen double dx1 = x1 - x1[_n-1]
	qui by id: gen double dx2 = x2 - x2[_n-1]
	qui by id: gen double ly = y[_n-1]
	
	* Add if more x variables requested
	if `k' > 2 {
		forvalues j = 3/`k' {
			qui gen double x`j' = 0
			forvalues i = 1/`n' {
				qui replace x`j' = rnormal(0, 1) if id == `i' & time == 1
				forvalues tt = 2/`t' {
					qui replace x`j' = x`j'[_n-1] + rnormal(0, 0.5) ///
						if id == `i' & time == `tt'
				}
			}
			qui by id: gen double dx`j' = x`j' - x`j'[_n-1]
		}
	}
	
	* Labels
	label variable id "Panel ID"
	label variable time "Time period"
	label variable y "Dependent variable (I(1))"
	label variable x1 "Independent variable 1 (I(1))"
	label variable x2 "Independent variable 2 (I(1))"
	label variable dy "First difference of y"
	label variable dx1 "First difference of x1"
	label variable dx2 "First difference of x2"
	label variable ly "Lagged y"
	label variable alpha_i "Panel-specific intercept"
	label variable phi_i "Panel-specific AR coefficient"
	
	di
	di in gr "  Data generated successfully."
	di in gr "  True DGP: y_it = alpha_i + " in ye "`beta1'" in gr "*x1 + " ///
		in ye "`beta2'" in gr "*x2 + ECM dynamics"
	di in gr "  Use: " in ye "xtpqardl dy dx1 dx2, lr(l.y x1 x2) tau(0.25 0.5 0.75) pmg"
	di in smcl in gr "{hline 70}"
end
