capture program drop power_cmd_swgee_init
program power_cmd_swgee_init, sclass
   version 15.1
   sreturn clear
   sreturn local pss_numopts "size z_power t_power nclust nper n es phi tau0 tau1 tau2 rho1 rho2 posdeff"
   sreturn local pss_colnames "size z_power t_power nclust nper n es phi tau0 tau1 tau2 rho1 rho2 posdeff"
   sreturn local pss_alltabcolnames "size z_power t_power nclust nper n es phi tau0 tau1 tau2 rho1 rho2 posdeff"
   sreturn local pss_collabels `""Alpha" "Z_Power"  "T_Power" "N_Clust" "N_Period" "N_Ind" "Effect_Size" "Phi" "Tau_0" "Tau_1" "Tau_2" "Rho_1" "Rho_2" "Pos_Def""'
end 
