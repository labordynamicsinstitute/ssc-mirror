set varabbrev off


// Basque

u "http://fmwww.bc.edu/repec/bocode/s/scul_basque.dta", clear

qui xtset
local lbl: value label `r(panelvar)'

loc unit ="Basque Country (Pais Vasco)":`lbl'


loc int_time = 1975

qui xtset
cls

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >= `int_time',1,0)

scul gdpcap, ahead(3) treat(treat) ///
obscol(black) cfcol("170 19 15") legpos(11)

scul gdpcap, ahead(3) treat(treat) ///
obscol(black) cfcol("170 19 15") legpos(11) trans(norm)


cls

// Prop 99 Division
loc int_time = 1989

u "http://fmwww.bc.edu/repec/bocode/s/scul_p99_region", clear
qui xtset
local lbl: value label `r(panelvar)'

loc unit ="California":`lbl'
qui xtset
g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >= `int_time',1,0)
cls

scul cigsale, ///
        ahead(1)  ///
        treated(treat) ///
        obscol(black) ///
        cfcol(blue) ///
        legpos(7) cv(adaptive)
cls
/*	
// BP Analysis
loc dv score

loc covs index_score buzz_score ///
impression_score ///
quality_score ///
value_score satisfaction_score ///
recommend_score

loc int_time: di tm(2010m4)


 Run only if you have an hour and a half to spare.
u "http://fmwww.bc.edu/repec/bocode/s/scul_bp.dta", clear

replace yougovname = subinstr(yougovname, ".", "",.)

labmask id, value(yougovname)
local lbl: value label id


loc unit ="BP":`lbl'
qui xtset
cls

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >= `int_time',1,0)

format date %tm

lab var date "Month"

xtset id date, m // !! Makes our data panel data

keep if date <= tm(2012m6)

cls

scul score, ///
        ahead(6) ///
        treat(treat) ///
        obscol(black) ///
        cfcol(red) ///
        legpos(5) ///
        cv(adaptive)    
*/
cls
//West Germany
u "http://fmwww.bc.edu/repec/bocode/s/scul_Reunification.dta", clear
loc int_time = 1990
cls
qui xtset
local lbl: value label `r(panelvar)'


loc unit ="West Germany":`lbl'

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >=`int_time',1,0)

// ssc inst labvars
labvars gdp treat "GDP per Capita" "Reunification"

scul gdp, ///
        tr(treat) ///
        ahead(8)  ///
        cfcol(red) obscol(black) cv(adaptive) ///
        legpos(9) //

scul gdp, ///
        tr(treat) ///
        ahead(8)  ///
        cfcol(red) obscol(black) cv(adaptive) ///
        legpos(9) plat times(1/2) //
cls
	
//Kansas Tax Cuts

u "http://fmwww.bc.edu/repec/bocode/s/scul_Taxes", clear
loc int_time: disp tq(2012q1)
cls
qui xtset
local lbl: value label `r(panelvar)'


loc unit ="Kansas":`lbl'

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >=`int_time',1,0)


scul gdp, ahead(4) treated(treat) ///
        obscol(black) ///
        cfcol(blue) ///
        q(.5) cv(adaptive) legpos(7)
cls
	
//Ukraine Invasion Effect on GDP

u "http://fmwww.bc.edu/repec/bocode/s/scul_invasion.dta", clear
loc int_time = 2014
cls
qui xtset
local lbl: value label `r(panelvar)'


loc unit ="Ukraine":`lbl'

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >=`int_time',1,0)

scul gdp, ahead(4) treated(treat) ///
        obscol(black) ///
        cfcol(blue) ///
        q(.5) cv(adaptive) legpos(7)
	
scul gdp, ahead(4) treated(treat) ///
        obscol(black) ///
        cfcol(blue) ///
        cv(adaptive) legpos(7) pla sqerr(1.2)

cls	
//Effect of Stadium on Housing Prices     
u "http://fmwww.bc.edu/repec/bocode/s/scul_Stadium.dta", clear
loc int_time = 2017
cls
qui xtset
local lbl: value label `r(panelvar)'


loc unit ="Cobb":`lbl'

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >=`int_time',1,0)


scul realgrossvpa, ahead(4) treated(treat) ///
        obscol(black) ///
        cfcol(blue) ///
        q(1) cv(adaptive) legpos(7)
cls
//Gas Holiday Studies

u "http://fmwww.bc.edu/repec/bocode/g/GasHoliday.dta", clear

xtset id date, d

scul regular, ///
        ahead(28)  ///
        treat(treat) ///
        obscol(black) ///
        cfcol(170 19 15) ///
        legpos(7) ///
        before(28) after(28) ///
        donadj(et) ///
        rellab(-28(7)28) //

