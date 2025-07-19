*! florindjp v1.0: Gráfico de flor para visualizar indicadores.

program define florindjp
    version 16

     syntax varlist(numeric min=1 max=1) [if] [in] [, dimension(string) indicador(string) title(string) graph_options(string) text1(string) text2(string) text3(string) text4(string) text5(string) text6(string) note(string)]
	

   
    local numvars : word count `varlist'
    if `numvars' != 1 { 
        di as error "Error: Se debe especificar 1 variable numérica (valor)."
        exit 198
    }

   
    
    local dimension = "`dimension'"
    local indicador = "`indicador'"
    
   
    if "`circulo'" == "" {
        summ `varlist', d
        global circulo=`r(max)'
    }
    else {
        global circulo=`circulo'
    }

    
    egen orden=group(`dimension')
    sort orden `varlist'
    gen double angpri=_n*2*_pi/_N
    
    gen double xcirculo=($circulo*cos(angpri))
    gen double ycirculo=($circulo*sin(angpri))
    gen double xvalor=(((`varlist')+$circulo)*cos(angpri)) 
    gen double yvalor=(((`varlist')+$circulo)*sin(angpri)) 

    cap drop xeti yeti
    gen xeti=(($circulo*1.5)*cos(angpri)) 
    gen yeti=(($circulo*1.5)*sin(angpri))

    cap drop etique
    gen etique=`indicador'+"("+string(`varlist',"%2.1f")+")" 

    cap drop quad
    gen quad=.  
    replace quad=1 if xcirculo>=0 & ycirculo>=0 
    replace quad=2 if xcirculo<=0 & ycirculo>=0   
    replace quad=3 if xcirculo<=0 & ycirculo<=0
    replace quad=4 if xcirculo>=0 & ycirculo<=0

    cap drop angulo 
    gen double angulo=.
    replace angulo=(angpri*(180/_pi))-180 if angpri >  _pi & !inlist(quad,2,4)
    replace angulo=(angpri*(180/_pi))     if angpri <= _pi & !inlist(quad,2,4)
    replace angulo=(angpri*(180/_pi))-180 if angpri <= _pi & quad==2
    replace angulo=(angpri*(180/_pi))     if angpri >  _pi & quad==4

    local labs2
    qui levelsof etique, local(lvls) 
    foreach x of local lvls {
        summ angulo if etique=="`x'" 
        local labs2 `labs2' (scatter yeti xeti if etique== "`x'"  , mc(none) mlabel(etique) mlabangle(`r(mean)')  mlabpos(0) mlabcolor(black*255) mlabsize(.95))  
    } 

    local dime
    local i
    levelsof `dimension', local(lvls)  
    local items=`r(r)'
    local i=1
    foreach x of local lvls {
        colorpalette, n("`items'") nograph
        local dime `dime' (pcspike yvalor xvalor ycirculo xcirculo if `dimension'=="`x'", lc("`r(p`i')'") lw(2.5)) ||  
        local ++i
    }

    cap drop tag
    egen tag=tag(`dimension')
    recode tag(0=.)

    gen double xdimension= .
    gen double ydimension= .
    gen double angledimension= .

    levelsof `dimension' if tag==1, local(lvls)
    foreach x of local lvls {
    qui summ angpri if `dimension'=="`x'"
        replace angledimension=(`r(max)'+`r(min)')/2 if tag==1 & `dimension'=="`x'"
        replace xdimension=($circulo*.9*cos(angledimension)) if tag==1 & `dimension'=="`x'"
        replace ydimension=($circulo*.9*sin(angledimension)) if tag==1 & `dimension'=="`x'"
    }

    replace angledimension=(angledimension*(180/_pi))-180 if tag==1 & angpri >  _pi & !inlist(quad,2,4)
    replace angledimension=(angledimension*(180/_pi))     if tag==1 & angpri <= _pi & !inlist(quad,2,4)
    replace angledimension=(angledimension*(180/_pi))-180 if tag==1 & angpri <= _pi & quad==2
    replace angledimension=(angledimension*(180/_pi))     if tag==1 & angpri >  _pi & quad==4

    local labdimension
    levelsof `dimension' if tag==1, local(lvls)
    foreach x of local lvls {
        qui summ angledimension if `dimension'== "`x'" & tag==1, meanonly
        local labdimension `labdimension' (scatter ydimension xdimension if `dimension'=="`x'" & tag==1, mc(none) mlabel(`dimension') mlabangle(`r(mean)')  mlabpos(0) mlabcolor(black*255) mlabsize(1.0))
    }

    summarize ycirculo
    local ymax=r(max)
    local ypost1=`ymax'*0.5
    local ypost2=`ymax'*0.2
    local ypost3=`ymax'*-0.1
    local ypost4=`ymax'*-0.4
    local ypost5=`ymax'*-0.6
    local ypost6=`ymax'*-0.7

    twoway `dime' `labs2' `labdimension',  ///
         title("`title'") xlabel(-1$edge $edge, nogrid) ylabel(-1$edge $edge, nogrid) ///
        xsize(40) ysize(40) aspect(1) legend(off) scheme(white_brbg)  ///
        graphregion(margin(l+5r+5)) yscale(off) xscale(off)  ///
        `graph_options'  /// 
         text(`ypost1' 0 "`text1'", size(2.5) box just(center) margin(t+2 b+2) fcolor(none) lw(none) color()) ///  
        text(`ypost2' 0 "`text2'", size(1.8) box just(center) margin(t+2 b+2) fcolor(none) lw(none) color()) ///  
        text(`ypost3' 0 "`text3'", size(1.8) box just(center) margin(t+2 b+2) fcolor(none) lw(none) color()) ///  
        text(`ypost4' 0 "`text4'", size(1.8) box just(center) margin(t+2 b+2) fcolor(none) lw(none) color()) ///  
        text(`ypost5' 0 "`text5'", size(1.8) box just(center) margin(t+2 b+2) fcolor(none) lw(none) color()) ///  
        text(`ypost6' 0 "`text6'", size(1.8) box just(center) margin(t+2 b+2) fcolor(none) lw(none) color()) ///  
        note("`note'", size(1.4)) 
drop orden-angledimension
end
