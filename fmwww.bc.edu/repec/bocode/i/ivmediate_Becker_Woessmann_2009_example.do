* Dippel, Ferrara, Heblich (2019) ivmediate: Causal mediation analysis in instrumental variables regressions
* empirical example do file, based on data from Becker and Woessmann (2009) table 3

qui do "Z:\Dropbox\projects\ivmediate\ado file\ivmediate.ado"

sjlog using "Z:\Dropbox\projects\ivmediate\data\DFH_SJ_example", replace

	// open Becker and Woessmann (2009) replication data
	use "ipehd_qje2009_master.dta"

	// define the vector of control variables
	global controls "f_jew f_fem f_young f_pruss hhsize pop gpop f_miss"

	// run iv-mediation analysis
	ivmediate inctax $controls, mediator(f_rw) treatment(f_prot) instrument(kmwitt)

sjlog type "Z:\Dropbox\projects\ivmediate\data\DFH_SJ_example.smcl", replace
