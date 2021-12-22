*! version 1.1  2021-08-23 Mark Chatfield

program power_cmd_tworates_zhu_init, sclass
version 15
sreturn clear
sreturn local pss_numopts "r1 OVERDISPersion irr DURation VARMethod"
sreturn local pss_allcolnames "alpha power N N1 N2 nratio r1 r2 IRR overdispersion duration varmethod delta"
sreturn local pss_alltabcolnames "alpha power N N1 N2 IRR r1 r2 duration overdispersion"
sreturn local pss_delta "IRR"
*above helpful for graphs
sreturn local pss_titletest " for the comparison of rates using negative binomial regression"
sreturn local pss_samples "twosample"
end
