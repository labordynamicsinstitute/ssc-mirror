*! version 0.21.4  5apr2021
*! Valor cuota y patrimonio CIC y FCS
*! autor George G. Vega Yon

// Valor cuota de los fondos
cap program drop valcuofon_afc
program def valcuofon_afc

	vers 11.0

	syntax [, Agno(integer 2021) Save(string) Clear]
	
	if (length(`"`save'"')) preserve
	else if ((c(N)+c(k)) != 0) & length("`clear'") == 0 {
		di as error "No, los datos en la memoria se perder{c a'}n" as text " (use la opci{c o'}n " as result "clear)"
		exit 4
	}
	
	if (`agno' > 2008) {
		qui {
			insheet ///
				fecha valor_cuota_cic valor_patrimonio_cic  valor_cuota_fcs valor_patrimonio_fcs ///
					using "https://www.spensiones.cl/apps/valoresCuotaFondo/vcfAFCxls.php?aaaa=`agno'", ///
					delim(";") clear
			drop in 1/2
		}
	}
	else {
		qui {
			insheet ///
				fecha valor_cuota_cic valor_patrimonio_cic nada ///
					using "https://www.spensiones.cl/apps/valoresCuotaFondo/vcfAFCxls.php?aaaa=`agno'", ///
					delim(";") clear
			
			drop nada
			drop in 1/2
		}
	}
	
	// Arreglando valores numericos
	quietly {
		foreach var of varlist valor* {
			replace `var' = subinstr(`var', ".", "", .)
			destring `var', replace dpcomma
		}
	}
	
	// Etiquetando variables
	lab var valor_cuota_cic "Valor cuota CIC"
	lab var valor_patrimonio_cic "Patrimonio CIC"
	
	if (`agno' > 2008) {
		lab var valor_cuota_fcs "Valor cuota FCS"
		lab var valor_patrimonio_fcs "Patrimonio FCS"
	}
	
	// Arreglando fecha
	gen fecha2 = date(fecha, "YMD")
	drop fecha
	ren fecha2 fecha
	format fecha %td
	
	order fecha
	label data "Valores cuota y patrimonio diarios de los Fondos de Cesantia durante el `agno'"
	
	if length(`"`save'"') != 0 save `save', replace
end