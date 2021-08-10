* Poverty prediction in Ecuador; v 1.2 by Daniel Jaramillo & Sergio Guerra

program pobrezaECU
	version 12
	args year quarter

	capture rename fexp FEXP
	capture confirm variable FEXP area ciudad zona
if (_rc) {
    display as error "The survey ENEMDU has not been uploaded or some relevant variable is missing. You can download the complete dataset in this url: http://www.ecuadorencifras.gob.ec/enemdu-2015/"
    exit 111
}

	capture confirm integer number `year'
if (_rc) {
    display as error "Syntax error. The year of the uploaded survey is missing."
    exit 111
}

	capture confirm integer number `quarter'
if (_rc) {
    display as error "Syntax error. The quarter of the uploaded survey is missing."
    exit 111
}
	
	qui {
	gen a1=`year' if `year'>=2007
	replace a1=. if a1==0
	local y =a1
	gen a2=`quarter' if `quarter'>=1 & `quarter'<=4 
	replace a1=. if a1==0
	local q =a2
	drop a1 a2
	}
	
	capture confirm integer number `y'
if (_rc) {
    display as error "The argument {hi:year} must be an integer greater than or equal to 2007."
    exit 498
}

	capture confirm integer number `q'
if (_rc) {
    display as error "The argument {hi:quarter} must be an integer between 1 and 4."
    exit 498
}



qui {	
	preliminary_changes `year' `quarter'
	poverty_recovery
	poverty_growth 
	poverty_overtendency 
	poverty_undertendency 
	
	**************************
	* Presenting the results *
	**************************
	
	local period =`year'+1
	
	* Error estandar pobreza *
	
	global ee_pobreza_1 =($Pobreza_recuperacion*(100-$Pobreza_recuperacion)/$familia)^0.5
	global ee_pobreza_2 =($Pobreza_crecimiento*(100-$Pobreza_crecimiento)/$familia)^0.5
	global ee_pobreza_3 =($Pobreza_sobre_tendencia*(100-$Pobreza_sobre_tendencia)/$familia)^0.5
	global ee_pobreza_4 =($Pobreza_bajo_tendencia*(100-$Pobreza_bajo_tendencia)/$familia)^0.5
	
	* Error estandar pobreza extrema *
	
	global ee_extrema_1 =($Extrema_recuperacion*(100-$Extrema_recuperacion)/$familia)^0.5
	global ee_extrema_2 =($Extrema_crecimiento*(100-$Extrema_crecimiento)/$familia)^0.5
	global ee_extrema_3 =($Extrema_sobre_tendencia*(100-$Extrema_sobre_tendencia)/$familia)^0.5
	global ee_extrema_4 =($Extrema_bajo_tendencia*(100-$Extrema_bajo_tendencia)/$familia)^0.5
		
	* General settings *
	
	g ciclo=[_n] in 1/4
	la def fase 1 "Recovery" 2 "Expansion" 3 "Recession" 4 "Depression"
	la values ciclo fase
	la var ciclo "Business Cycle"
	
	********************
	* Poverty settings *
	********************
	
	g t_pobreza = $Pobreza_recuperacion if ciclo==1
	replace t_pobreza = $Pobreza_crecimiento  if ciclo==2
	replace t_pobreza = $Pobreza_sobre_tendencia if ciclo==3
	replace t_pobreza = $Pobreza_bajo_tendencia if ciclo==4
	format t_pobreza %9.2f
	la var t_pobreza "Poverty"
	
	g t_error = $ee_pobreza_1 if ciclo==1
	replace t_error = $ee_pobreza_2 if ciclo==2
	replace t_error = $ee_pobreza_3 if ciclo==3
	replace t_error = $ee_pobreza_4 if ciclo==4
	format t_error %9.4f
	la var t_error "Std. Err."
	
	g l_inf_pob = $Pobreza_recuperacion-1.96*$ee_pobreza_1 if ciclo==1
	replace l_inf_pob = $Pobreza_crecimiento-1.96*$ee_pobreza_2 if ciclo==2
	replace l_inf_pob = $Pobreza_sobre_tendencia-1.96*$ee_pobreza_3 if ciclo==3
	replace l_inf_pob = $Pobreza_bajo_tendencia-1.96*$ee_pobreza_4 if ciclo==4
	format l_inf_pob %9.4f
	la var l_inf_pob "[95% Conf."
	
	g l_sup_pob = $Pobreza_recuperacion+1.96*$ee_pobreza_1 if ciclo==1
	replace l_sup_pob = $Pobreza_crecimiento+1.96*$ee_pobreza_2 if ciclo==2
	replace l_sup_pob = $Pobreza_sobre_tendencia+1.96*$ee_pobreza_3 if ciclo==3
	replace l_sup_pob = $Pobreza_bajo_tendencia+1.96*$ee_pobreza_4 if ciclo==4
	format l_sup_pob %9.4f
	la var l_sup_pob " Interval]"
	
	****************************
	* Extreme poverty settings *
	****************************
	
	g t_extrema = $Extrema_recuperacion if ciclo==1
	replace t_extrema = $Extrema_crecimiento  if ciclo==2
	replace t_extrema = $Extrema_sobre_tendencia if ciclo==3
	replace t_extrema = $Extrema_bajo_tendencia if ciclo==4
	format t_extrema %9.2f
	la var t_extrema "Extreme Poverty"
	
	g t_error_extr = $ee_extrema_1 if ciclo==1
	replace t_error_extr = $ee_extrema_2 if ciclo==2
	replace t_error_extr = $ee_extrema_3 if ciclo==3
	replace t_error_extr = $ee_extrema_4 if ciclo==4
	format t_error_extr %9.4f
	la var t_error_extr "Std. Err."
	
	g l_inf_ext = $Extrema_recuperacion-1.96*$ee_extrema_1 if ciclo==1
	replace l_inf_ext = $Extrema_crecimiento-1.96*$ee_extrema_2 if ciclo==2
	replace l_inf_ext = $Extrema_sobre_tendencia-1.96*$ee_extrema_3 if ciclo==3
	replace l_inf_ext = $Extrema_bajo_tendencia-1.96*$ee_extrema_4 if ciclo==4
	format l_inf_ext %9.4f
	la var l_inf_ext "[95% Conf."
	
	
	g l_sup_ext = $Extrema_recuperacion+1.96*$ee_extrema_1 if ciclo==1
	replace l_sup_ext = $Extrema_crecimiento+1.96*$ee_extrema_2 if ciclo==2
	replace l_sup_ext = $Extrema_sobre_tendencia+1.96*$ee_extrema_3 if ciclo==3
	replace l_sup_ext = $Extrema_bajo_tendencia+1.96*$ee_extrema_4 if ciclo==4
	format l_sup_ext %9.4f
	la var l_sup_ext " Interval]"
}
	di ""
	di "Poverty `year'-Q`quarter': " %4.2f $pobreza_t
	di ""
	di "Poverty `period'-Q`quarter':"
	tabdis ciclo if ciclo<=4, cell(t_pobreza t_error l_inf_pob l_sup_pob) cen
	di ""
	di "Extreme poverty `year'-Q`quarter': " %4.2f $extrema_t 
	di ""
	di "Extreme poverty `period'-Q`quarter':"
	tabdis ciclo if ciclo<=4, cell(t_extrema t_error_extr l_inf_ext l_sup_ext) cen
	
	qui { 
	**************************
	* drop useless variables *
	**************************
	
	drop year_t1 trim_t1 Lp Lpe pob_t transicion_* income_1 l_sup_ext ///
	l_inf_ext t_error_extr t_extrema l_sup_pob l_inf_pob t_error t_pobreza ///
	ciclo extreme_est_* poverty_est_* ingr_pc_est_* ingr_hogar_est_* ///
	otros_est_* desem_est_* inadec_est_* adec_est_* ingresos_est_* mediana_* ///
	otros idhogar npersona id ingrnl ingrtl	
	}
end
