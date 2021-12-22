program define var_nr_options_display, rclass
version 16.0

	syntax , OPTname(string) [IDENT NSTEPS IMPACT SHUT PCTG METHOD SAVEFMT SHCKPLT NDRAWS ERRLMT UPDTFRQCY UPDT ALL]
	
	if ("`all'"!="") mata: opt_display(`optname')
	
	else {
		if ("`ident'"!="") mata: display("Identification option (ident): "+`optname'.ident)
		
		if ("`nsteps'"!="") mata: display("IRF maximum horizon (nsteps): "+strofreal(`optname'.nsteps)
		
		if ("`impact'"!="") mata: display("IRF impact: one std deviation (0) or unitary (1) (impact): "+strofreal(`optname'.impact)
		
		if ("`shut'"!="") mata: display("IRF set to zero one row of companion matrix (shut): "+strofreal(`optname'.shut)
		
		if ("`pctg'"!="") mata: display("IRF error bands percentile (pctg): "+strofreal(`optname'.pctg))
		
		if ("`method'"!="") mata: display("IRF re-sampling method, bootstrap (bs) or wild-bootsrap (wild) (method): "+`optname'.method)
		
		if ("`savefmt'"!="") mata: display("Plot file format (save_fmt): "+`optname'.save_fmt)
		
		if ("`shckplt'"!="") mata: display("Which variable(s) to plot (shck_plt): "+`optname'.shck_plt)
		
		if ("`ndraws'"!="") mata: display("Number of desired draws using [narrative] sign restrictions (ndraws): "+strofreal(`optname'.ndraws))
		
		if ("`errlmt'"!="") mata: display("Maximum failed [narrative] sign restriction draws allowed (err_limit): "+strofreal(`optname'.err_lmt))
		
		if ("`updtfrqcy'"!="") mata: display("[Narrative] sign restricts updates progress per (updt_frqcy) draws: "+strofreal(`optname'.updt_frqcy))
		
		if ("`updt'"!="") mata: "Display progress on [narrative] sign restriction loops (upt): "+`optname'.updt
	}
	
end