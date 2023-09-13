

// 'SCUL': Implements regularized synthetic control estimators for single and multiple-treated unit settings


cls

set varabbrev off

u scul_basque, clear
cls
scul gdpcap, ahead(3) trdate(1975) ///
trunit(5) lamb(lopt) ///
scheme(white_tableau) ///
obscol(black) cfcol(red) legpos(4)

u "scul_p99_region", clear
cls
scul cigsale, ///
	ahead(1)  ///
	trdate(1989) ///
	trunit(3) ///
	lamb(lopt) ///
	scheme(white_tableau) ///
	obscol(black) ///
	cfcol(blue) ///
	legpos(7) q(1) cv(adaptive) //
	
u scul_Reunification, clear
cls
scul gdp, ///
        ahead(8) ///
        trdate(1990) ///
        trunit(7) ///
        scheme(white_cividis) ///
        lambda(lopt) ///
        obscol(black) ///
	cfcol(blue) ///
	intname(Reunification) ///
	cv(adaptive)
	

u Gas_Holiday, clear

loc int_time = td(24mar2022)

// td(18mar2022)  MD // td(24mar2022) GA // td(02apr2022) CT 

scul regular, ///
	ahead(28)  ///
	trdate(`int_time') ///
	trunit(11) ///
	lamb(lopt) ///
	scheme(white_tableau) ///
	obscol(black) ///
	cfcol(red) ///
	legpos(7) ///
	before(28) after(28) ///
	multi tr(treat) ///
	donadj(et) ///
	intname("Gas Holiday") ///
	rellab(-28(7)28) cv(adaptive) trans(norm)


u scul_Taxes, clear
loc int_time: disp tq(2012q1)
cls

scul gdp, ahead(4) trunit(20) trdate(`int_time') ///
	lambda(lopt) ///
	obscol(black) ///
	cfcol(blue) ///
	q(.5) cv(adaptive) legpos(7)

	
u scul_Invasion, clear
cls

scul gdp, ///
        ahead(3) ///
        trdate(2014) ///
        trunit(18) ///
        lambda(lopt) ///
	intname(Invasion) ///
	cv(adaptive) ///
	trans(norm) ///
	q(.5) legpos(11) ///
	obscol("28 87 152") ///
	cfcol("227 168 103")
	
u scul_Stadium, clear
cls

scul realgrossvpa, ///
        ahead(4) ///
        trdate(2017) ///
        trunit(7) ///
        lambda(lopt) ///
	intname("Stadium") ///
	cv(adaptive) ///
	q(1) legpos(6) ///
	obscol("28 87 152") ///
	cfcol("227 168 103")

