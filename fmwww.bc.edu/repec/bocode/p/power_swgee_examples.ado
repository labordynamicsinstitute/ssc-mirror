program power_swgee_examples
	version 15.1
	`1'
end

program define power_swgee_examples_1
	preserve
	clear
	qui set obs 15
	forvalues i=1/4 {
		gen var`i'=0
	}
	replace var4 = 1
	replace var3 = 1 in 1/10
	replace var2 = 1 in 1/5

	power swgee, mu0(0.1) muT(0.2) es(2) design(var1-var4) nclust(15) nper(4) n(100) family(poisson) link(log) ///
	corstr(proportional decay) tau0(0.04(0.01)0.06) rho1(0.02) rho2(0.7) alpha(0.05) table ///
	graph(xdimension(tau0) ydimension(t_power))
	restore
end

program define power_swgee_examples_2
	preserve
	clear
	power swgee, mu0(0.1) muT(0.2) es(2) nclust(15) nper(4) n(100) family(binomial) link(logit) ///
	corstr(exponential decay) tau0(0.04(0.01)0.06) rho1(0.02) alpha(0.05) table ///
	graph(xdimension(tau0) ydimension(t_power))
	matrix list r(mus)
	restore
end



