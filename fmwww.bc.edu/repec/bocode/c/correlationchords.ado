* correlationchords - Circular chord diagram of correlations
* Author: Domínguez-Durán, Emilio emilienko@gmail.com
* v1.0 Oct 4 2024

program define correlationchords
	version 18.0
	syntax varlist, test(string) startangle(numlist) strength(numlist) labeldistance(numlist) labelorientation(string) labelcolor(string) labelsize(string) colorscheme(string) [customlabel(string)] [significationdiscrete(numlist)] [colordiscrete(string)] [linewidthdiscrete(numlist)] [colordiscretesignificative(string)] [linewidthdiscretesignificative(numlist)] [colordiscretenotsignificative(string)] [linewidthdiscretenotsignificative(numlist)] [significationcontinuous(numlist)] [colorcontinuousmin(string)] [linewidthcontinuousmin(numlist)] [colorcontinuousmax(string)] [linewidthcontinuousmax(numlist)] [sensecontinuous(string)] [legend]

* Guardado de datos
preserve

* Variables locales
local lados : word count `varlist'
local númerocurvas = `lados' * (`lados' - 1) / 2
local ángulosector = c(pi) * 2 / `lados'
local ánguloinicio = `startangle' * 2 * c(pi) / 360
local distanciaetiqueta = `labeldistance'
local menosdistanciaetiqueta = `distanciaetiqueta' * (-1)

* Comprobación de dicotomía
if "`test'" == "exact1sided" {
	forval q = 1/`lados' {
		local vardicotómica : word `q' of `varlist'
		quietly tabulate `vardicotómica'
		if r(r) > 2 {
			display as error "The variable `vardicotómica' is not a dichotomous variable, and the one-sided Fisher's exact test is not allowed."
			exit 999
		}	
	} 	
}

*Variables para colores discretos
if "`colorscheme'" == "discrete" {
	local significación = `significationdiscrete'
	local significacióncorregida = `significación' / ((`lados'*(`lados'-1)) / 2)
}

*Estas variables locales son para colores continuos
if "`colorscheme'" == "continuous" {
	local colorinicio = "`colorcontinuousmax'"
	local colorfinal = "`colorcontinuousmin'"
	local significacióncolorinicio = "`significationcontinuous'"
	local máximogruesolínea = "`linewidthcontinuousmin'"
	local mínimogruesolínea = "`linewidthcontinuousmax'"
	local intervalogruesolínea = `máximogruesolínea' - `mínimogruesolínea'
	local iniciored = word("`colorinicio'",1)
	local r1 = `iniciored' / 255
	local iniciogreen = word("`colorinicio'",2)
	local g1 = `iniciogreen' / 255
	local inicioblue = word("`colorinicio'",3)
	local b1 = `inicioblue' / 255
	local finalred = word("`colorfinal'",1)
	local r2 = `finalred' / 255
	local finalgreen = word("`colorfinal'",2)
	local g2 = `finalgreen' / 255
	local finalblue = word("`colorfinal'",3)
	local b2 = `finalblue' / 255
	**Cálculo de HSV
		local max1 = max(`r1', `g1', `b1')
		local min1 = min(`r1', `g1', `b1')
		local max2 = max(`r2', `g2', `b2')
		local min2 = min(`r2', `g2', `b2')
	*** Cálculo de V
		local v1 = `max1'
		local v2 = `max2'
	*** Cálculo de S
		if `v1' == 0 {
			local s1 = 0
		}
		if `v1' != 0 {
			local s1 = 1 - (`min1' / `max1')
		}
		if `v2' == 0 {
			local s2 = 0
		}
		if `v2' != 0 {
			local s2 = 1 - (`min2' / `max2')
		}
	*** Cálculo de H

		if `max1' == `r1' & `g1' >= `b1' {
			local h1 = 60 * ((`g1'-`b1')/(`max1'-`min1'))
		}
		if `max1' == `r1' & `g1' < `b1' {
			local h1 = 60 * ((`g1'-`b1')/(`max1'-`min1')) + 360
		}
		if `max1' == `g1' {
			local h1 = 60 * ((`b1'-`r1')/(`max1'-`min1')) + 120
		}
		if `max1' == `b1' {
			local h1 = 60 * ((`r1'-`g1')/(`max1'-`min1')) + 240
		}
		if `max1' == `min1' {
			local h1 = 0
		}		
		if `max2' == `r2' & `g2' >= `b2' {
			local h2 = 60 * ((`g2'-`b2')/(`max2'-`min2'))
		}
		if `max2' == `r2' & `g2' < `b2' {
			local h2 = 60 * ((`g2'-`b2')/(`max2'-`min2')) + 360
		}
		if `max2' == `g2' {
			local h2 = 60 * ((`b2'-`r2')/(`max2'-`min2')) + 120
		}
		if `max2' == `b2' {
			local h2 = 60 * ((`r2'-`g2')/(`max2'-`min2')) + 240
		}
		if `max2' == `min2' {
			local h2 = 0
		}
	
	***Camino corto o largo
	local huedifference = `h2' - `h1'
		if "`sensecontinuous'" == "short" {
			if `huedifference' < -180 {
				local h2 = `h2' + 360
			}
			if `huedifference' > 180 {
				local h2 = `h2' - 360
			}		
		}
		if "`sensecontinuous'" == "long" {
			if `huedifference' >= -180 & `huedifference' < 0 {
				local h2 = `h2' + 360
			}
			if `huedifference' <= 180 & `huedifference' >= 0 {
				local h2 = `h2' - 360
			}
		}
	}

* Constructor de polígonos
forval i = 1/`lados' {
	if `"`customlabel'"' != "" { 
		local etiqueta : word `i' of `customlabel'
	}
	else {
		local etiqueta : word `i' of `varlist'
	}
	local ángulo = `ánguloinicio' - `ángulosector'*(`i'-1)
	local ángulogrados = round(mod((`ángulo' * 360 / 2 / c(pi)),360),0.1)
	if "`labelorientation'" == "perpendicular" {
		local ángulotexto = `ángulogrados' - 90
		if `ángulogrados' > 180 {
			local ángulotexto = mod((`ángulogrados' + 90),360)
		} 
	}
	if "`labelorientation'" == "parallel" {
		local ángulotexto = `ángulogrados'
		if `ángulogrados' <= 270 & `ángulogrados' > 90 {
			local ángulotexto = mod((`ángulogrados' + 180),360)
		} 
	}
	local xcord = sin(`ángulo') * `distanciaetiqueta'
	local ycord = cos(`ángulo') * `distanciaetiqueta'
	local xcord`i' = cos(`ángulo')
	local ycord`i' = sin(`ángulo')
	local gráfico = `"`gráfico' (scatteri `xcord' `ycord' (0) "`etiqueta'", msymbol(none) mlabcolor("`labelcolor'") mlabangle(`ángulotexto') mlabsize("`labelsize'"))"'
}

* Añade líneas de conexión
** Genera número mínimo de observaciones
	quietly count
	if r(N) <= 101 {
		quietly set obs 101
	}
	if r(N) <= `númerocurvas' {
		quietly set obs `númerocurvas' 
	}

** Ordena por significación
	quietly gen valorp = .
	quietly gen primeravariable = .
	quietly gen segundavariable = .
	local iteración = 0

	display in smcl as text "{c TLC}{hline 50}{c TRC}"
	display in smcl as text "{c |} {col 4}CIRCULAR CHORD DIAGRAM OF CORRELATIONS" as text "{col 52}{c |}"
	display in smcl as text "{c LT}{hline 50}{c RT}"
	if "`test'" == "chi2" {
	display in smcl as text "{c |} {col 4}Test:" as result "{col 36} Pearson's χ² test" as text "{col 52}{c |}"
	}
	if "`test'" == "exact1sided" {
	display in smcl as text "{c |} {col 4}Test:" as result "{col 21} One-sided Fisher's test" as text "{col 52}{c |}"
	}
	if "`test'" == "exact2sided" {
	display in smcl as text "{c |} {col 4}Test:" as result "{col 20} Two-sided Fisher's test" as text "{col 52}{c |}"
	}
	
	forval j = 1/`lados' {
		if `j' < `lados' {
			local jmasuno = `j' + 1
        	local var1 : word `j' of `varlist'
			display in smcl as text "{c LT}{hline 50}{c RT}"		
			display in smcl as text "{c |} {col 4}`var1'" "{col 52}{c |}"
			forval k = `jmasuno'/`lados' {
			local iteración = `iteración' + 1
        	local var2 : word `k' of `varlist'
        	if "`test'" == "chi2" {
        		local paramp = "r(p)"
        	}
        	if "`test'" == "exact2sided" {
        		local paramp = "r(p_exact)"
        	}
        	if "`test'" == "exact1sided" {
        		local paramp = "r(p1_exact)"
        	}        	        	
			quietly tabulate `var1' `var2', chi2 exact
			display in smcl as text "{c |} {col 7}`var2'" as result "{col 41}" %9.0g `paramp' as text "{col 52}{c |}"
			quietly replace valorp = `paramp' in `iteración'
			quietly replace primeravariable = `j' in `iteración'
			quietly replace segundavariable = `k' in `iteración'
			}
		}
	}
	display in smcl as text "{c BLC}{hline 50}{c BRC}"
	gsort -valorp

** Genera las curvas
	quietly gen t = (_n - 1) / 100 if _n <= 101
	forval j = 1/`lados' {
		if `j' < `lados' {
			local jmasuno = `j' + 1
			forval k = `jmasuno'/`lados' {
				local iteración = `iteración' + 1
				local x0 = `xcord`j''
				local y0 = `ycord`j''
				local x3 = `xcord`k''
				local y3 = `ycord`k''
				local longitud = ((`x3'-`x0')^2+(`y3'-`y0')^2)^0.5
				local correcciónsegúnángulo = (`longitud' * (-1) / 2 + 1) ^ `strength'
				local x1 = `xcord`j'' * `correcciónsegúnángulo'
				local y1 = `ycord`j'' * `correcciónsegúnángulo'
				local x2 = `xcord`k'' * `correcciónsegúnángulo'
				local y2 = `ycord`k'' * `correcciónsegúnángulo'			
				quietly gen xpuntos_`j'_`k' = (1-t)^3 * `x0' + 3 * (1-t)^2 * t * `x1' + 3 * (1-t) * t^2 * `x2' + t^3 * `x3' if _n <= 101
				quietly gen ypuntos_`j'_`k' = (1-t)^3 * `y0' + 3 * (1-t)^2 * t * `y1' + 3 * (1-t) * t^2 * `y2' + t^3 * `y3' if _n <= 101
        }
    }
}

* Construcción de cadena de curvas
	forval l = 1/`númerocurvas' {
		local valorp =  valorp[`l']
		local primeravariable =  primeravariable[`l']
		local segundavariable =  segundavariable[`l']

**Opciones para colores continuos
		if "`colorscheme'" == "continuous" {
			if `valorp' <= `significacióncolorinicio' {
			local valorpescalado = `valorp' / `significacióncolorinicio'
			local hinterpolate = `h1' * `valorpescalado' + `h2' * (1 - `valorpescalado')
			local sinterpolate = round(`s1' * `valorpescalado' + `s2' * (1 - `valorpescalado'),0.001)
			local vinterpolate = round(`v1' * `valorpescalado' + `v2' * (1 - `valorpescalado'),0.001)
			local gruesolínea = `intervalogruesolínea' * (1 - `valorpescalado') + `mínimogruesolínea'
			local colorlínea = `"hsv `hinterpolate' `sinterpolate' `vinterpolate'"'
			}
			if `valorp' > `significacióncolorinicio' {
				local gruesolínea = "0"
			}
		}

** Opciones para valores discretos
		if "`colorscheme'" == "discrete" {
			if `valorp' < `significación' {
				local colorlínea = `"`colordiscrete'"'
				local gruesolínea = "`linewidthdiscrete'"
			}
			if `valorp' >= `significación' {
				local gruesolínea = "0"
			}
			if "`colordiscretenotsignificative'" != "" {
				if `valorp' >= `significación' {
					local colorlínea = `"`colordiscretenotsignificative'"'
					local gruesolínea = "`linewidthdiscretenotsignificative'"
				}
			}
			if "`colordiscretesignificative'" != "" {
				if `valorp' < `significacióncorregida' {
					local colorlínea = `"`colordiscretesignificative'"'
					local gruesolínea = "`linewidthdiscretesignificative'"
				}
			}
		}

* Construcción de cadena Bézier
		local curvasbézier = `"`curvasbézier' (line ypuntos_`primeravariable'_`segundavariable' xpuntos_`primeravariable'_`segundavariable', lcolor("`colorlínea'") lwidth(`gruesolínea'pt))"'
	}

local gráfico = `"`gráfico' `curvasbézier'"'


* Ajuste de propiedades de gráfico
local gráfico = `"`gráfico'(, aspectratio(1) legend(off) xsize(10) ysize(10) xscale(off range(`menosdistanciaetiqueta' `distanciaetiqueta')) yscale(off range(`menosdistanciaetiqueta' `distanciaetiqueta')) xlabel(, nogrid) ylabel(, nogrid) plotregion(margin(1 1 1 1)))"'


*Constructor de leyenda
if "`colorscheme'" == "continuous" {
	if "`legend'" != "" {		
		local gráfico = `"`gráfico',"'
		local intervaloleyenda = `significacióncolorinicio' / 8
		local etiquetaleyenda = `significacióncolorinicio'
		local abscisaetiquetaleyenda = (`distanciaetiqueta' + 0.05) * (-1)
		local ordenadaetiquetaleyenda = `distanciaetiqueta'
		forval m = 1/9 {
			local colorleyenda = `etiquetaleyenda' / `significacióncolorinicio'
			local hleg = `h1' * `colorleyenda' + `h2' * (1 - `colorleyenda')
			local sleg = `s1' * `colorleyenda' + `s2' * (1 - `colorleyenda')
			local vleg = `v1' * `colorleyenda' + `v2' * (1 - `colorleyenda')
			local gráfico = `"`gráfico' text(`abscisaetiquetaleyenda' `ordenadaetiquetaleyenda' "`etiquetaleyenda'", box bcolor("hsv `hleg' `sleg' `vleg'") size(10pt) width(40pt) height(15pt) justification(center) alignment(middle))"'
			local etiquetaleyenda = (`etiquetaleyenda' - `intervaloleyenda')
			local abscisaetiquetaleyenda = `abscisaetiquetaleyenda' + 0.05
		}
	}
} 

* Contructor del gráfico con twoway
local gráfico = `"twoway`gráfico'"'
`gráfico'

end
