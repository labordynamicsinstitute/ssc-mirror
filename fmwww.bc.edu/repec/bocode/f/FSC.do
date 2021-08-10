* Note: unfortunately the FSC data are confidential and cannot be released, 
* so the first part of the analysis has been commented out 

** First part of the FSC analysis 
*clear
*set memory 100m
*set more off
*use FSC-mvmeta, clear
*stset duration allchd
*xi: mvmeta_make stcox ages i.fg, strata(sex tr) nohr ///
*    saving(FSCstage1) replace by(cohort) usevars(i.fg) names(b V) esave(N)

 
* Second stage:

* DISPLAY DATA
use FSCstage1, clear
format b* V* %5.3f
l cohort b_Ifg_2 b_Ifg_3 b_Ifg_4 b_Ifg_5 V_Ifg_2_Ifg_2 V_Ifg_3_Ifg_3, clean noobs

* MULTIVARIATE META-ANALYSES
mvmeta b V

* UNIVARIATE META-ANALYSES
mvmeta b V, vars(b_Ifg_2)
mvmeta b V, vars(b_Ifg_3)
mvmeta b V, vars(b_Ifg_4)
mvmeta b V, vars(b_Ifg_5)
