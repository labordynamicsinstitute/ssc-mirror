*! atip_volcano.ado v1.0.0  Andres Talavera  INEI/DNCE  21jul2026
program define atip_volcano
    version 14
    syntax varname(numeric), NREGLAS(varname numeric) ///
        [ID(varname) NTHRESH(integer 3) MAGTHRESH(real 2) ///
         TITLE(string) SEED(integer 12345) SAVING(string)]
    local mag `varlist'
    tempvar yjit prioritario
    set seed `seed'
    quietly gen double `yjit' = `nreglas' + (runiform()-0.5)*0.5
    quietly gen byte `prioritario' = (`nreglas' >= `nthresh' & `mag' >= `magthresh')
    if "`title'" == "" local title "Volcano de outliers: magnitud vs. evidencia (N reglas)"
    local lblopt
    if "`id'" != "" local lblopt "mlabel(`id') mlabsize(vsmall) mlabpos(3)"
    quietly summarize `mag'
    local xmax = r(max)*1.15
    twoway ///
        (scatter `yjit' `mag' if `prioritario'==0, mcolor(gs8%55) msize(small)) ///
        (scatter `yjit' `mag' if `prioritario'==1, mcolor(red) msize(medsmall) `lblopt') ///
        , ///
        yline(`=`nthresh'-0.5', lpattern(dash) lcolor(gs6)) ///
        xline(`magthresh', lpattern(dash) lcolor(gs6)) ///
        ylabel(0(1)5) ///
        xscale(range(0 `xmax')) ///
        legend(order(1 "No prioritario" 2 "Evidencia fuerte + magnitud grande") pos(6) rows(1) size(small)) ///
        xtitle("Magnitud local (|z|)") ///
        ytitle("N de reglas disparadas (0-5, jitter vertical)") ///
        title("`title'") ///
        note("Lineas punteadas: N_REGLAS>=`nthresh'  y  |z|>=`magthresh'." ///
             "Y llevan jitter aleatorio (+-0.25) solo para separar visualmente puntos con el mismo conteo -- el eje real es discreto 0-5.") ///
        `=cond("`saving'"!="", `"saving("`saving'", replace)"', "")'
    di as text _n "Casos totales: " as res _N
    quietly count if `prioritario'==1
    di as text "Casos prioritarios (evidencia fuerte + magnitud grande): " as res r(N)
end
