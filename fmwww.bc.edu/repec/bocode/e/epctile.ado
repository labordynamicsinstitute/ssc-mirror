*! percentile as estimation procedure
* v.1.2 by Stas Kolenikov, skolenik at gmail dot com

program define epctile, eclass sortpreserve properties(svyb svyj)
  * survey properties of the program?

  version 11
  if !replay() {
     syntax varname [if] [in] [pw fw iw/], Percentiles(numlist) ///
         [ svy over(varlist) Level(cilevel) subpop(string) VALuemask( string ) SPEClabel noSE ]

     * the main study variable
     local y `varlist'

     * sample conditions
     marksample touse
     sort `touse' `over' `y'

     * parse the subpop option
     if "`subpop'"!="" {
        ParseSubPop `subpop', touse(`touse')
        local subpop subpop( `subpop' )
     }

     * parse the weights
     tempvar wgt
     if "`weight'" == "" {
       * no weight specified
       qui gen byte `wgt' = `touse'
     }
     else {
       * something was put down as weights
       qui gen double `wgt' = `exp' * `touse'
       local wexp [pw=`wgt']
     }
     * parse the survey option
     if "`svy'"~="" {
       * are there survey settings to fall back on?
       qui svyset
       if "`r(wvar)'" != "" {
         * if there are any weights found in svy settings, replace the weight var
         qui replace `wgt' = `r(wvar)'
       }
       if "`r(settings)'" != ", clear" {
         * if there are any svy settings at all
         local svy svy , `subpop' :
       }
       else {
         * svy option was specified, but no svy settings found
         di as err "Warning: no svy settings found"
         local wexp [pw=`wgt']
       }
       if "`if'`in'"!="" {
         * if/in or subpop?
         qui count if `touse'
         if r(N) != _N di as err "Warning: if and in conditions should be implemented via svy, subpop option"
       }
     }

     qui sum `wgt' if `touse'
     local sumw = r(sum)

     * check if percentiles are within bounds
     tokenize `percentiles'
     local np : word count `percentiles'
     forvalues j=1/`np' {
        local p`j' : word `j' of `percentiles'
        if `p`j'' < 10 local p`j' 0`p`j''
        if `p`j'' <= 0 & `p`j''>=100 {
           di as err "percentiles must be between 0 and 100"
           exit 198
        }
     }

     qui count if `touse'
     local nobs = r(N)

     tempname b bb V
     * 1. get percentiles via _pctile
     if "`over'" == "" {
        _pctile `y' [pw=`wgt'] if `touse', percentiles( `percentiles' )

        mat `b' = J(1,`np',.)
        forvalues j=1/`np' {
           mat `b'[1,`j'] = r(r`j')
           local cnames `cnames' `=subinstr("p`p`j''",".","d",.)'
        }
     }
     else {
        * handle the OVER option here!
        unab overlist : `over'
        * number of variables
        local novervar : word count `overlist'

        FormXLevels `overlist', valuemask( "`valuemask'" )

        mat `b' = J(1,`np'*`s(ncombos)', .)
        * the parameter estimates should run by percentile, then by `over' variables
        * to match the estimation output of -mean-

        forvalues k=1/`s(ncombos)' {
           _pctile `y' [pw=`wgt'] if `touse' `s(if`k')', percentiles( `percentiles' )
           forvalues j=1/`np' {
              mat `b'[1,(`j'-1)*`s(ncombos)' + `k'] = r(r`j')
           }
        }
        forvalues j=1/`np' {
           forvalues k=1/`s(ncombos)' {
              if "`speclabel'" == "" local cnames `cnames' `=subinstr("p`p`j''",".","d",.)':`s(vmlab`k')'
              else                   local cnames `cnames' `=subinstr("p`p`j''",".","d",.)'_`s(vmlab`k')'
           }
        }
     }

     if "`se'" != "nose" {

     * 2. compute the linearization pieces
     if "`over'" == "" {
       forvalues k=1/`np' {
          tempvar d`k'
          qui gen `d`k'' = (  (`y'<`b'[1,`k']) - 0.01*`p`k'' )
          local dlist `dlist' `d`k''
       }
     }
     else {
       qui forvalues k=1/`np' {
          tempvar d`k'
          gen `d`k'' = .
          forvalues j=1/`s(ncombos)' {
            replace `d`k'' = (  (`y'<`b'[1,(`k'-1)*`s(ncombos)' + `j']) - 0.01*`p`k'' ) if `touse' `s(if`j')'
          }
          local dlist `dlist' `d`k''
       }
     }

     * 3. compute the covariance with -svy: mean-
     if "`over'" != "" local overopt over(`over', nolabel)
     qui `svy' mean `dlist' if `touse' `wexp', `overopt'
     local vcetype `e(vcetype)'
     local vce `e(vce)'
     mat `V' = e(V)

     * sreturn values are lost by now
     if "`over'"!= "" FormXLevels `overlist', valuemask( "`valuemask'" )

     * 4. compute the Woodruff estimates of variance
     tempname scale
     mat `scale' = J(1,`np'*`e(N_over)',.)
     forvalues j=1/`np' {
        if "`over'" != "" {
          forvalues k=1/`s(ncombos)' {
             local pplus  = `p`j'' + 200*_se[ `d`j'':`s(lab`k')' ]
             if `pplus' >= 100 local pplus `p`j''
             * have to use one-sided derivative
             local pminus = `p`j'' - 200*_se[ `d`j'':`s(lab`k')' ]
             if `pminus' <= 0 local pminus `p`j''
             * have to use one-sided derivative
             _pctile `y' [pw=`wgt'] if `touse' `s(if`k')', percentiles( `pminus' `pplus' )
             mat `scale'[1,(`j'-1)*`s(ncombos)'+`k'] = 100*( r(r2) - r(r1) )/( `pplus'-`pminus' )
/*
             mat `scale'[1,(`j'-1)*`s(ncombos)'+`k'] = ( r(r2) - r(r1) )/( 4 * _se[ `d`j'':`s(lab`k')' ] )
             if `pplus' == `p`j'' | `pminus' == `p`j'' {
                mat `scale'[1,(`j'-1)*`s(ncombos)'+`k'] = 2 * `scale'[1,(`j'-1)*`s(ncombos)'+`k']
             }
*/
          }
        }
        else {
          local pplus  = `p`j'' + 200*_se[ `d`j'' ]
          if `pplus' >= 100 local pplus `p`j''
          * have to use one-sided derivative
          local pminus = `p`j'' - 200*_se[ `d`j'' ]
          if `pminus' <= 0 local pminus `p`j''
          * have to use one-sided derivative
          _pctile `y' [pw=`wgt'] if `touse', percentiles( `pminus' `pplus' )
          mat `scale'[1,`j'] = 100*( r(r2) - r(r1) )/( `pplus'-`pminus' )
/*
          mat `scale'[1,`j'] = ( r(r2) - r(r1) )/( 4 * _se[ `d`j'' ] )
          if `pplus' == `p`j'' | `pminus' == `p`j'' mat `scale'[1,`j'] = 2 * `scale'[1,`j']
*/
        }
     }

     * 5. combine into the covariance matrix of the percentiles
     mat `V' = diag( `scale' ) * `V' * diag( `scale' )
     }

     else {
       * no standard errors
       mat `V' = J( colsof(`b'), colsof(`b'), 0 )
     }

     * grand finale: nice labels
     mat rownames `V' = `cnames'
     mat colnames `V' = `cnames'

     mat rownames `b' = `y'
     mat colnames `b' = `cnames'

     mat colnames `scale' = `cnames'
     mat rownames `scale' = `y'

     ereturn post `b' `V', obs(`nobs') depname(`y') esample(`touse')
     ereturn matrix scale  = `scale'
     ereturn scalar N_over = `np'
     ereturn local over      `over'
     ereturn local depvar    `y'
     ereturn local vce       `vce'
     ereturn local vcetype   `vcetype'
     ereturn local cmd       epctile
     * set e(cmd) last
  }
  else { // replay
     if "`e(cmd)'"!="epctile" error 301
     syntax [, Level(cilevel)]
  }
  * output any header above the coefficient table
  di _n as text "Percentile estimation"
  ereturn display, level(`level')
  di _n
end



program define ParseSubPop
   * Jeff Pitblado's suggestion: undocumented _svy_subpop marking tool
   syntax [varlist(max=1 default=none)] [if/] , touse(varname)
   * subpop is [varname] [if]
   * target: zero out observations outside of the subpopulation
   * the input variable is typically `touse'

   confirm variable `touse'

   if "`varlist'`if'" == "" {
      di as err "undefined subpopulation"
      exit 198
   }
   qui {
      if "`varlist'" == "" local varlist 1
      if "`if'" == "" local if 1
      replace `touse' = `touse' & (`varlist') & (`if')
   }
end

exit

History:

v. 1.0 -- March 05, 2010. Basic features: percentiles for i.i.d. data and -svy- via the option
v. 1.1 -- March 06, 2010. Options: over, valuemask, speclabel, subpop,
v. 1.2 -- May 25, 2010.   Fixed an issue with standard errors and -over- option


Simulations:

* i.i.d. data
set seed 10101
pro def epctsim
  drop _all
  set obs 1000
  gen y = uniform()
  epctile y , p(25 50 75)
end

simulate _b _se , reps(1000) saving( epctile_iid, replace) : epctsim
sum

* stratified single stage
clear all
set seed 10101
set obs 500000
gen long id = _n
gen byte h = (_n-1)/10000+1
bysort h (id) : gen m = 2+uniform() if _n == 1
bysort h (id) : gen s = 0.5+0.1*uniform() if _n == 1
bysort h (id) : replace m = m[1]
bysort h (id) : replace s = s[1]
gen y = exp( m + rnormal()*s )
sum y, d
scalar pop05 = r(p5)
foreach k in 10 25 50 75 90 95 {
  scalar pop`k' = r(p`k')
}
sort s id
egen strata = group( h )

save strpop, replace

pro def epctsvysim
   use strpop, clear
   gen r1 = uniform()
   gen r2 = uniform()
   sort strata r1 r2
   bysort strata (r1 r2) : keep if _n < 20+strata
   gen samplw = 10000/(20+strata)
   svyset [pw=samplw], strata(strata)
   epctile y, p(5 10 25 50 75 90 95) svy
end

simulate _b _se , reps(1000) saving( epctile_svy, replace) : epctsvysim
foreach k in 05 10 25 50 75 90 95 {
  gen byte reject_l`k' = ( p`k'_b_cons + invnorm( 0.05 )*p`k'_se_cons > scalar( pop`k') )
  gen byte reject_u`k' = ( p`k'_b_cons + invnorm( 0.95 )*p`k'_se_cons < scalar( pop`k') )
}
sum
foreach x of varlist reject* {
  bitest `x' == 0.05
}

* stratified two-stage
clear all
set seed 10201
set obs 50
gen double m = 2+uniform()
gen double s = 0.5+0.2*uniform()
sort s
gen byte strata = _n
gen int Nh = 100 + rnbinomial( 10, 0.2 )
gen byte nh = 2 + (uniform()<0.4) + (uniform()<0.1)
tab nh
expand Nh
gen double y0 = exp( m + s*rnormal() )
gen int PSU = _n
gen int Mhi = 20 + rnbinomial( 10, 0.1 )
sum Mhi
expand Mhi
gen double y = y0 - ( ln(uniform()) + ln(uniform())  + ln(uniform()) + 3 )
bysort strata PSU : gen byte first = (_n==1)

sum y, d
scalar pop05 = r(p5)
foreach k in 10 25 50 75 90 95 {
  scalar pop`k' = r(p`k')
}

compress

save strpop2, replace

pro def epctsvy2sim
   use strpop2, clear
   gen float r1 = uniform() if first
   gen float r2 = uniform() if first
   bysort strata PSU (first) : replace r1 = r1[_N]
   bysort strata PSU (first) : replace r2 = r2[_N]
   bysort strata (r1 r2 first) : gen iPSU = sum( first )
   bysort strata r1 r2 (first) : replace iPSU = iPSU[_N]
   * sample of PSUs
   keep if iPSU <= nh
   * sample of observations
   gen float r3 = uniform()
   gen float r4 = uniform()
   bysort strata iPSU (r3 r4) : keep if _n <= 10
   gen samplw = Mhi/10 * Nh/nh
   svyset iPSU [pw=samplw], strata(strata)
   epctile y, p(5 10 25 50 75 90 95) svy
end

clear
set mem 80m

simulate _b _se , reps(1000) saving( epctile_svy2, replace) : epctsvy2sim
foreach k in 05 10 25 50 75 90 95 {
  gen byte reject_l`k' = ( p`k'_b_cons + invnorm( 0.05 )*p`k'_se_cons > scalar( pop`k') )
  gen byte reject_u`k' = ( p`k'_b_cons + invnorm( 0.95 )*p`k'_se_cons < scalar( pop`k') )
}
sca li
sum
foreach x of varlist reject* {
  bitest `x' == 0.05
}