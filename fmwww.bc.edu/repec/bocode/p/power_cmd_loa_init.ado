*! 1.0.0 Ariel Linden 15May2023

// initializer
program power_cmd_loa_init, sclass
	version 11.0
	sreturn clear
	sreturn local pss_argnames "power N gamma alpha delta mu sd"
	sreturn local pss_numopts "mu delta sd alpha gamma power"
	sreturn local pss_title " for a limits of agreement (LOA) analysis"
	sreturn local pss_allcolnames "power N alpha gamma delta mu sd"
	sreturn local pss_alltabcolnames "power N alpha gamma delta mu sd"
	sreturn local pss_samples "twosample"
end

