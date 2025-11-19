*! 1.0.0 Ariel Linden 13Nov2025

// initializer
program power_cmd_abk_init, sclass
	version 16.0
	
	sreturn clear
	sreturn local pss_target "delta"
	sreturn local pss_targetlabel "delta"
	sreturn local pss_numopts "n phases mobs delta icc phi alpha power"
	sreturn local pss_title " for a balanced (AB)^k design with multiple cases"
	sreturn local pss_colnames "delta phases mobs icc phi"
	sreturn local pss_samples "twosample"

end
