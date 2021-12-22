program define var_nr_options, rclass
version 16.0

	syntax , OPTname(string) [IDENT(string) NSTEPS(numlist int >0 max=1) IMPACT(numlist int max=1) SHUT(numlist int max=1) PCTG(numlist >0 <100 max=1) METHOD(string) SAVEFMT(string) SHCKPLT(string) NDRAWS(numlist int >0 max=1) ERRLMT(numlist int >0 max=1) UPDTFRQCY(numlist int >0 max=1) UPDT(string)]
	
	if ("`ident'"!="") {
		if ("`ident'"=="sr" | "`ident'"=="oir" | "`ident'"=="bq") {
			mata: `optname'.ident= "`ident'"
		}
		else {
			di as error "Identification must = {oir}, {bq}, or {sr}"
			exit 198
		}
	}
	
	if ("`nsteps'"!="") mata: `optname'.nsteps= `nsteps'
	
	if ("`impact'"!="") {
		if (`impact'==0 | `impact'==1) {
			mata: `optname'.impact= `impact'
		}
		else {
			di as error "Impact must = 0 or 1"
			exit 198
		}
	}
	
	if ("`shut'"!="") {
		if (`shut'==0 | `shut'==1) {
			mata: `optname'.shut= `shut'
		}
		else {
			di as error "Shut must = 0 or 1"
			exit 198
		}
	}
	
	if ("`pctg'"!="") mata: `optname'.pctg= `pctg'
	
	if ("`method'"!="") {
		if ("`method'"=="bs" | "`method'"=="wild") {
			mata: `optname'.method= "`method'"
		}
		else {
			di as error "Method must = {bs} or {wild}"
			exit 198
		}
	}
	
	if ("`savefmt'"!="") mata: `optname'.save_fmt= "`savefmt'"
	
	if ("`shckplt'"!="") mata: `optname'.shck_plt= "`shckplt'"
	
	if ("`ndraws'"!="") mata: `optname'.ndraws= `ndraws'
	
	if ("`errlmt'"!="") mata: `optname'.err_lmt= `errlmt'
	
	if ("`updtfrqcy'"!="") mata: `optname'.updt_frqcy= `updtfrqcy'
	
	if ("`updt'"!="") {
		if ("`updt'"=="yes" | "`updt'"=="no") {
			mata: `optname'.updt= "`updt'"
		}
		else {
			di as error "Update must = {yes} or {no}"
			exit 198
		}
	}
	
end