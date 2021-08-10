*! version 0.21.04  5apr2021

// Valor cuota de los fondos
cap program drop valcuofon_afp
program def valcuofon_afp
	syntax [, AGNOInicio(integer 2021) AGNOFin(integer 2021) Fondo(string) Save(string) Clear]
	
	vers 9.0
	
	if length("`fondo'") == 0 local fondo = "A"
	else if !regexm("`fondo'", "^(A|B|C|D|E)$") {
		di as error "No existe el fondo {bf:`fondo'}"
		di as text "(pruebe con los fondos A, B, C, D o E)"
		exit
	}
	
	if length(`"`save'"') != 0 preserve
	else if ((c(N)+c(k)) != 0) & length("`clear'") == 0 {
		di as error "No, los datos en la memoria se perder{c a'}n" as text " (use la opci{c o'}n " as result "clear)"
		exit 4
	}
	
	qui insheet ///
			using "https://www.spensiones.cl/apps/valoresCuotaFondo/vcfAFPxls.php?aaaaini=`agnoinicio'&aaaafin=`agnofin'&tf=`fondo'&fecconf=`agnofin'1231", ///
			delim(";") clear	
	
	// Generando fecha
	qui gen fecha = date(v1, "YMD")
	qui drop v1
	format fecha %td
	
	// Generando grupos de datos
	tempvar grupo
	qui gen `grupo' = 1
	qui replace `grupo' = `grupo'[_n - 1] + (fecha[_n - 1] != . & fecha==.) if _n > 3
	
	local grupo0 = `grupo'[1]
	local grupoN = `grupo'[_N]
	
	tempfile descargado
	cap save `descargado'
	
	forval i = `grupo0'/`grupoN' {
		cap keep if `grupo' == `i'
		
		foreach var of varlist v* {
			
			if `var'[3] != "" { // Verifica que la variable exista para la obs
				// Cambia nombre
				if length(`var'[2]) != 0 local afp = `var'[2]
				
				local tmplab = `var'[3]+" fondo `fondo' `afp'"
				lab var `var' "`tmplab'"
				
				local tmpname = lower(strtoname(`var'[3])+"_"+strtoname("`afp'"))
				ren `var' `tmpname'
				
				// Ajusta valores
				qui {
					replace `tmpname' = subinstr(`tmpname', ".", "", .)
					replace `tmpname' = "" in 1/3
					destring `tmpname', replace dpcomma
				}
			}
			else drop `var'
			
		}
		
		qui drop in 1/2
		
		drop if fecha==.
		
		tempfile parte`i'
		cap save `parte`i''
		
		use `descargado'
	}
	
	clear
	
	use `parte1'
	forval i = 2/`grupoN' {
	order fecha
		append using `parte`i''
	}
	
	
	
	order fecha
	
	label data "Valores cuota (fondo `fondo') y patrimonio de las AFP en el periodo `agnoinicio'-`agnofin'"
	drop `grupo'
	if length(`"`save'"') != 0 save `save', replace
end

