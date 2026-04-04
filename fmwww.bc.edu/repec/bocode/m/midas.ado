*! Ben A. Dwamena: ben@bennybeaubooks.com 
*! version 3.01 April 3, 2026
*! version 3.00 March 30, 2026
*! version 2.00 November 27, 2025
*! version 1.00 January 31, 2021

 cap program drop midas
 program midas, byable(recall)
  version 16
  if _by() {
		local bycmd "by `_byvars' :"
	}

	gettoken subcmd 0 : 0, parse(" :,=[]()+-")

	local l = strlen("`subcmd'")
	//Data  Commands
		if ("`subcmd'"==bsubstr("clust2bin", 1, max(4, `l')))  { 
		midas_bclust2bin `0'
	}
		else if ("`subcmd'"==bsubstr("con2bin", 1, max(4, `l'))) { 
		midas_con2bin `0'
	}		
		else if ("`subcmd'"==bsubstr("ipd2ad", 1, max(4, `l'))) 	{  
		midas_ipd2ad `0'
	}	
		else if ("`subcmd'"==bsubstr("ord2bin", 1, max(3, `l'))) 	{  
		midas_ord2bin `0'
	}	
		else if ("`subcmd'"==bsubstr("simdata", 1, max(3, `l'))) {  
		midas_simdata `0'
	}	
	//Exploratory Commands
		else if ("`subcmd'"=="quadas") { 
		midas_quadas `0'
	}
		else if ("`subcmd'"=="quadas2") { 
		midas_quadas2 `0'
	}
		else if ("`subcmd'"==bsubstr("chiplot", 1, max(4, `l'))) 		{  
		midas_chiplot `0'
	}
		else if ("`subcmd'"==bsubstr("bivbox", 1, max(3, `l'))) 		{  
		midas_bivbox `0'
	}	
		else if ("`subcmd'"==bsubstr("kendall", 1, max(3, `l'))) 		{  
		midas_kendall `0'
	}
		else if ("`subcmd'"==bsubstr("assess", 1, max(3, `l'))) 		{  
		midas_assess `0'
	}	
	   else if ("`subcmd'"=="binsse") {  
		midas_binsse `0'
	}
		else if ("`subcmd'"==bsubstr("eforest", 1, max(4, `l'))) {
		midas_eforest `0'
	}
	//Estimation	Commands
		else if ("`subcmd'"=="mle") { 
		`bycmd' midas_mle `0'
	}
		else if ("`subcmd'"=="qrsim") {
		`bycmd' midas_qrsim `0'
	}
		else if ("`subcmd'"=="inla") { 
		`bycmd' midas_inla `0'
	}
		else if ("`subcmd'"=="mh") {
		`bycmd' midas_mh `0'
	}
		else if ("`subcmd'"=="hmc") { 
		midas_hmc `0'
	} 
	//Postestimation Commands
		else if ("`subcmd'"==bsubstr("condiplot", 1, max(4, `l'))) {  
		midas_condiplot `0'
	}	
		else if ("`subcmd'"=="rgsroc") {  
		midas_rgsroc `0'
	}		
		else if ("`subcmd'"=="bvsroc") { 
		midas_bvsroc `0'
	}
		else if ("`subcmd'"=="fagan") {  
		midas_fagan `0'
	}
		else if ("`subcmd'"==bsubstr("lrmat", 1, max(3, `l'))) 		{  
		midas_lrmat `0'
	}	
		else if ("`subcmd'"==bsubstr("bayesplot", 1, max(6, `l'))) { 
		midas_bayesplot `0'
	}	
		else if ("`subcmd'"==bsubstr("sforest", 1, max(4, `l'))) {
		midas_sforest `0'
	}
		else if ("`subcmd'"==bsubstr("pubbias", 1, max(3, `l'))) 		{  
		midas_pubbias `0'
	}
		else if ("`subcmd'"==bsubstr("hsruc", 1, max(3, `l'))) {
		midas_hsruc `0'
	}
		else if ("`subcmd'"==bsubstr("subgroup", 1, max(3, `l'))) {
		midas_subgroup `0'
	}
		else if ("`subcmd'"==bsubstr("metareg", 1, max(5, `l'))) {
		midas_metareg `0'
	}
		else if ("`subcmd'"==bsubstr("het", 1, max(3, `l'))) {
		midas_het `0'
	}
	else {
				if ("`subcmd'"=="") {
				di as smcl as err "syntax error"
				di as smcl as err "{p 4 4 2}"
				di as smcl as err ///
				"{bf:midas} must be followed by a subcommand."
				di as smcl as err ///
				"You might type {bf:midas mle}, {bf:midas eforest}, {bf:midas sforest}, {bf:midas het}, {bf:midas hsruc}"
				di as smcl as err "etc."
				di as smcl as err "{p_end}"
				exit 198
		}

		capture which midas_`subcmd'
			if (_rc) { 
			if (_rc==1) {
				exit 1
			}
				di as smcl as err ///
				"unrecognized subcommand:  {bf:midas `subcmd'}"
				exit 199
			
		}
				midas_`subcmd' `0'
	}
		
end


exit
