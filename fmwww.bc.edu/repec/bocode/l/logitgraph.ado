program define logitgraph
    syntax varlist, [keepvarorder] [keepcatorder] [linedist(numlist)] [bgcolor(string)] [textcolor(string)] [textsize(numlist)] [lcolor(string)] [lcolor0(string)] [lcolor1(string)] [colorlongway] [ptcolor(string)] [ptsize(numlist)] [labelgap(numlist)] [hideci] [hidecilim] [linewidth(numlist)] [basecolor(string)] [basewidth(numlist)]

	version 18
* Preserve

preserve

* Variables

	local numvar : word count `varlist'
	local primvar = word("`varlist'",1)
	local indepvar = trim(subinstr("`varlist'", "`primvar'", "", 1))
	local numindepvar : word count `indepvar'

* Comprobación de tamaño superior al número de variables

	quietly count
	if r(N) <= `numindepvar' {
		quietly set obs `numindepvar'
	}

* Creación de tabla de regresión

	quietly gen coef = .
	quietly gen liminf = .
	quietly gen limsup = .



** Ordenación por significación

	if "`keepvarorder'" == "" {
		quietly gen namevar = ""
		quietly gen precoef = .
		quietly logit `varlist'
		matrix prelogtab = r(table)
		local obs = 1
		forval k = 1/`numindepvar' {
			local varname = word("`indepvar'", `k')
			quietly replace namevar = "`varname'" in `obs'
			quietly replace precoef = prelogtab[1,`obs'] in `obs'
			local obs = `obs' + 1
		}
		quietly gen absprecoef = abs(precoef)
		gsort -absprecoef

		local varlist = "`primvar' "
		forval l = 1/`numindepvar' {
			local varname = namevar[`l']
			local varlist = "`varlist'`varname' "
		}
		local indepvar = trim(subinstr("`varlist'", "`primvar'", "", 1))
	}


** Continúa la creación de la tabla de regresión

	quietly logit `varlist'
	matrix logtab = r(table)

	local obs = 1
	local comb = 1
	forval a = 1/`numindepvar' {
		local varname = word("`indepvar'", `a')
		quietly tab `varname'
		local levelsof`a' = r(r)
		local comb = `comb' * r(r)
		quietly replace coef = logtab[1,`obs'] in `obs'
		quietly replace liminf = logtab[5,`obs'] in `obs'
		quietly replace limsup = logtab[6,`obs'] in `obs'
		local obs = `obs' + 1
	}
	local betapos = `numindepvar' + 1
	local beta = logtab[1,`betapos']
	local betainf = logtab[5,`betapos']
	local betasup = logtab[6,`betapos']

* Creación de combinaciones

** Comprobación de tamaño superior al número de variables

	quietly count
	if r(N) <= `comb' {
		quietly set obs `comb'
	}

** Crea las variables

	forval b = 1/`numindepvar' {
		quietly gen varindep`b' = .
	}

** Crea las combinaciones

	local divisor = `comb'
	forval c = 1/`numindepvar' {
		local divisor = `divisor' / `levelsof`c''
		forval d = 1/`comb' {
			local order = mod(ceil(`d'/`divisor')-1,`levelsof`c'') + 1

*** En caso de ordenación de negativos

	if "`keepcatorder'" == "" {
			local neg = coef[`c']
			if `neg' < 0 {
				local order = `levelsof`c''- `order' + 1
			}
	}

** Continúa la creación de combinaciones

			local varname = word("`indepvar'", `c')
			quietly levelsof `varname'
			local valuesof`c' = r(levels)
			local value = word("`valuesof`c''",`order')
			quietly replace varindep`c' = `value' in `d'
		}
	}

* Calcula puntos

	quietly gen punto = .
	quietly gen puntoinf = .
	quietly gen puntosup = .

	forval e = 1/`comb' {
		local punto = 0
		local puntoinf = 0
		local puntosup = 0
		forval f = 1/ `numindepvar' {
			local punto = `punto' + varindep`f'[`e'] * coef[`f']
			local puntoinf = `puntoinf' + varindep`f'[`e'] * liminf[`f']
			local puntosup = `puntosup' + varindep`f'[`e'] * limsup[`f']
		}

** Añade valores beta

	local punto = `punto' + `beta'
	local puntoinf = `puntoinf' + `betainf'
	local puntosup = `puntosup' + `betasup'

** De logit a prob

	local punto = exp(`punto') / (1 + exp(`punto'))
	local puntoinf = exp(`puntoinf') / (1 + exp(`puntoinf'))
	local puntosup = exp(`puntosup') / (1 + exp(`puntosup'))

** Inserción de puntos

	quietly replace punto = `punto' in `e'
	quietly replace puntoinf = `puntoinf' in `e'
	quietly replace puntosup = `puntosup' in `e'
}

* Opciones de gráfico

** Construcción de color

	if "`lcolor0'" != "" {

	local colorinicio = "`lcolor0'"
	local colorfinal = "`lcolor1'"
	local significacióncolorinicio = 0
	
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
	
*** Cálculo de HSV
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
		if "`colorlongway'" == "" {
			if `huedifference' < -180 {
				local h2 = `h2' + 360
			}
			if `huedifference' > 180 {
				local h2 = `h2' - 360
			}		
		}
		if "`colorlongway'" != "" {
			if `huedifference' >= -180 & `huedifference' < 0 {
				local h2 = `h2' + 360
			}
			if `huedifference' <= 180 & `huedifference' >= 0 {
				local h2 = `h2' - 360
			}
		}

	}

	if "`linedist'" == "" {
		local linedist = 1
	}
	if "`textcolor'" == "" {
		local textcolor = "black"
	}
	if "`textsize'" == "" {
		local textsize = 8
	}
	if "`ptcolor'" == "" {
		local ptcolor = "`lcolor'"
	}
	if "`ptsize'" == "" {
		local ptsize = 6
	}
	if "`labelgap'" == "" {
		local labelgap = 5
	}			
	if "`linewidth'" == "" {
		local linewidth = 3
	}
	if "`basecolor'" == "" {
		local basecolor = "200 200 200"
	}
	if "`basewidth'" == "" {
		local basewidth = 1
	}

	local ipsize = `linewidth' * 2
	local bpsize = `basewidth' * 2	
		
	local backline = `"lcolor("`basecolor'") lwidth(`basewidth'pt)"'
	local interval = `"lwidth(`linewidth'pt)"'
	local bpoint = `"mcolor("`basecolor'") msymbol(pipe) msize(`bpsize'pt) mlwidth(`basewidth'pt)"'
	local ipoint = `"msymbol(pipe) msize(`ipsize'pt) mlwidth(`linewidth'pt)"'
	local point = `"mlwidth(`linewidth'pt) msymbol(circle) msize(`ptsize'pt) mlabgap(`labelgap'pt) mlabcolor("`textcolor'") mlabsize(`textsize'pt)"'
	local legend = `"msymbol(none) mlabcolor("`textcolor'") mlabsize(`textsize'pt)"'
	local linelegend = `"lcolor("`basecolor'") lwidth(`basewidth'pt)"'

* Construcción de gráfico

	local xstart = `numindepvar' * (-0.2) - 0.1
	local numlines = `comb' + `comb' / `levelsof`numindepvar'' - 1
	local ystart = - `numlines' * `linedist'
		
	local norte = 2 * `linedist'
	local sur = ((`numlines' * `linedist') + `linedist') * (-1)
	local oeste = - (0.2 * `numindepvar')
	local este = 1.1
	local ladohor = (`este' - `oeste')
	local ladover = (`norte' - `sur')
	local ysize = `ladover' * 4 / 10
	local xsize = `ladohor' * 5.5
	if `ysize' <= 1 {
		local ysize = 1
	}
	if `ysize' >= 100 {
		local ysize = 100
	}	
	
	local graph = "twoway (, legend(off) xscale(off range(`oeste' `este')) yscale(off range(`sur' `norte')) xlabel(minmax, nogrid) ylabel(minmax, nogrid) ysize(`ysize') xsize(`xsize') graphregion(margin(0 0 0 0)) plotregion(color(`bgcolor') margin(0 0 0 0)))"

	forval g = 1/`comb' {
		local y = (`g' * (-1) - floor((`g'-1)/`levelsof`numindepvar'')) * `linedist'
		local x = punto[`g']
		local xform : display %9.3f `x'
		local xinf = puntoinf[`g']
		local xsup = puntosup[`g']
		
		if "`lcolor'" == "" & "`lcolor0'" == "" {
		local lcolor = "0 0 0"
		}	
		
		if "`lcolor'" != "" {
		local lcolor = "`lcolor'"
		}
		
		if "`lcolor0'" != "" {
		local hcolor = round((`h1' * (1-`xform') + `h2' * `xform'),0.001)
		local scolor = round((`s1' * (1-`xform') + `s2' * `xform'),0.001)
		local vcolor = round((`v1' * (1-`xform') + `v2' * `xform'),0.001)
		local lcolor = "hsv `hcolor' `scolor' `vcolor'"
		}

		local graph = `"`graph' (pci `y' 0 `y' 1, `backline') (scatteri `y' 0, `bpoint') (scatteri `y' 1, `bpoint') "'
		
		if "`hideci'" == "" {
		local graph = `"`graph' (pci `y' `xinf' `y' `xsup', lcolor("`lcolor'") `interval') "'
		}

		if "`hidecilim'" == "" {
		local graph = `"`graph' (scatteri `y' `xinf', `ipoint' mcolor("`lcolor'")) (scatteri `y' `xsup', `ipoint' mcolor("`lcolor'")) "'
		}	

		if "`ptcolor'" == "" {	
		local graph = `"`graph' (scatteri `y' `x' (12) "`xform'", `point' mfcolor("`lcolor'") mlcolor("`lcolor'")) "'
		}

		if "`ptcolor'" != "" {
		local graph = `"`graph' (scatteri `y' `x' (12) "`xform'", `point' mfcolor("`ptcolor'") mlcolor("`lcolor'")) "'
		}		
	}

* Puntos de leyenda

	local alto = (`numlines' + 1) * `linedist'
	local x = (-0.2 * `numindepvar') + 0.1
	local xline = `x' + 0.1
	local numpuntos = 1
	forval h = 1/`numindepvar' {
		local alto = `alto' / `levelsof`h''
		local numpuntos = `numpuntos' * `levelsof`h''
		local varname = word("`indepvar'", `h')
		forval i = 1/`numpuntos' {
			local order = (mod((`i' - 1),`levelsof`h'')) + 1

** En caso de ordenación de negativos

	if "`keepcatorder'" == "" {
			local neg = coef[`h']
			if `neg' < 0 {
				local order = `levelsof`h''- `order' + 1
			}
	}

* Continúa Puntos de leyenda

			local valueforlabel = word("`valuesof`h''",`order')
			local label : label (`varname') `valueforlabel'
			if `h' < `numindepvar' {
				local y = (`alto' / 2 + `alto' * (`i' - 1)) * (-1)
				local yline1 = `y' + `alto' / 2 - 0.6 * `linedist'
				local yline2 = `y' - `alto' / 2 + 0.6 * `linedist'
				local graph = `"`graph'  (scatteri `y' `x' (0) "`label'", `legend') (pci `yline1' `xline' `yline2' `xline', `linelegend') "' 
			}
			if `h' == `numindepvar' {
				local y = (`i' * (-1) - floor((`i'-1)/`levelsof`numindepvar'')) * `linedist'
				local yline1 = `y' + 0.4
				local yline2 = `y' - 0.4
				local graph = `"`graph'  (scatteri `y' `x' (0) "`label'", `legend') "' 
			}
		}
		local x = `x' + 0.2
		local xline = `xline' + 0.2
	}

* Títulos de leyenda

	local x = (-0.2 * `numindepvar') + 0.1
	forval j = 1/`numindepvar' {
		local label = word("`indepvar'",`j')
		local varlabel : variable label `label'
		if "`varlabel'" == "" {
			local varlabel = "`label'"
		}
		local graph = `"`graph' (scatteri `linedist' `x' (0) "{bf:`varlabel'}", `legend') "'
		local x = `x' + 0.2
	}

*display `"`graph'"'	

`graph'



end
