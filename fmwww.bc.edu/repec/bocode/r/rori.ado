*! Package rori v. 0.11
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2022-05-29 Version bug fixed
*! 2022-05-23 created

*capture program drop rori
program define rori, rclass
    version 12
    
    syntax, ///
        Targetpopulation(string)    /*ABCD*/ ///
        Responsepopulation(string)  /*abcd*/ ///
        [noQuietly NTarget(integer 0) NResponse(integer 0)]
    * disease vs exposure
    matrix _t = `targetpopulation'
    matrix _r = `responsepopulation'
    mata: st_local("_tst", strofreal(any(st_matrix("_t") :< st_matrix("_r"))))
    if `_tst' mata: _error("Target cells must be greater than response cells")
    if "`quietly'" == "" local QUIETLY quietly
    
    local _lvl = `c(level)'
    local _z = invnormal(0.5 + `_lvl' / 200)
    
    local _exponly 0
    scalar _N_t = _t[1,1] + _t[1,2] + _t[2,1] + _t[2,2]
    if `ntarget' > `=_N_t' {
        scalar _N_t = `ntarget'
        local _exponly 1
    }
    
    scalar _N_r = _r[1,1] + _r[1,2] + _r[2,1] + _r[2,2]
    if `nresponse' > `=_N_r' {
        scalar _N_r = `nresponse'
        local _exponly 1
    }
    
    // Exposed targets
    scalar _ne_t = `=_t[1,1] + _t[2,1]' 
    `QUIETLY' cii `=_N_t' `=_ne_t', wald level(`_lvl')
    scalar _pe_t = r(mean)
    scalar _se_pe_t = r(se)
    
    //Unexposed targets
    scalar _nu_t = _N_t - _ne_t
    `QUIETLY' cii `=_N_t' `=_nu_t', wald level(`_lvl')
    scalar _pu_t = r(mean)
    scalar _se_pu_t = r(se)
    
    // Exposed response
    scalar _ne_r = `=_r[1,1] + _r[2,1]' 
    `QUIETLY' cii `=_N_r' `=_ne_r', wald level(`_lvl')
    scalar _pe_r = r(mean)
    scalar _se_pe_r = r(se)

    // Unexposed response
    scalar _nu_r = _N_r - _ne_r 
    `QUIETLY' cii `=_N_r' `=_nu_r', wald level(`_lvl')
    scalar _pu_r = r(mean)
    scalar _se_pu_r = r(se)

    scalar _pre = _pe_r / _pe_t
    scalar _se_pr_e = sqrt(_se_pe_r - _se_pe_t)
    matrix _pr_e = _ne_r, _pe_r, _ne_t, _pe_t, ///
        _pre, _pre - `_z' * _se_pr_e, _pre + `_z' * _se_pr_e
    scalar _pru = _pu_r / _pu_t
    scalar _se_pr_u = sqrt(_se_pu_r - _se_pu_t)
    matrix _pr_u = _nu_r, _pu_r, _nu_t, _pu_t, ///
        _pru, _pru - `_z' * _se_pr_u, _pru + `_z' * _se_pr_u
    if `_exponly' {
        matrix _pr = _pr_e
        matrix rownames _pr = Exposed
    }
    else {
        matrix _pr = _pr_u \ _pr_e
        matrix rownames _pr = Unexposed Exposed        
    }
    matrix colnames _pr = n(r) p(r) n(t) p(t) PR "[`_lvl'%" CI]
    
    * disease vs exposure
    `QUIETLY' csi `=_t[1,1]' `=_t[1,2]' `=_t[2,1]' `=_t[2,2]', or level(`_lvl')
    matrix _or_t = r(or), r(lb_or), r(ub_or)
    scalar _se_or_t = (log(r(ub_or)) - log(r(lb_or))) / 2 / `_z'

    * disease vs exposure
    `QUIETLY' csi `=_r[1,1]' `=_r[1,2]' `=_r[2,1]' `=_r[2,2]', or level(`_lvl')
    matrix _or_r = r(or), r(lb_or), r(ub_or) 
    scalar _se_or_r = (log(r(ub_or)) - log(r(lb_or))) / 2 / `_z'

    scalar _ror = `=_or_r[1,1]' / `=_or_t[1,1]'
    scalar _ln_se_ror = sqrt(_se_or_r ^ 2 - _se_or_t ^ 2)
    scalar _ror_lb = _ror * exp(-`_z' * _ln_se_ror)
    scalar _ror_ub = _ror * exp( `_z' * _ln_se_ror)
    
    matrix rori = _or_r \ _or_t \ _ror, `=_ror_lb',  `=_ror_ub'
    matrix colnames rori = OR "[`_lvl'%" CI]
    matrix rownames rori = Response Target ROR
    
    if `_exponly' matrix _rori = _ror, `=_ror_lb',  `=_ror_ub'
    else matrix _rori =J(1,3,.) \  _ror, `=_ror_lb',  `=_ror_ub'
    matrix colnames _rori = ROR "[`_lvl'%" CI]
    matrix pr_ror = (_pr, _rori)

    return scalar ror = _ror
    return scalar pre = _pre
    return scalar pru = _pru
    
    return matrix pr_ror = pr_ror
    return matrix pr = _pr
    return matrix rori = rori

    capture scalar drop _*
    capture macro drop _*
    capture matrix drop _*
end


*/
/*
-----------------------------------
             |        outcome      
             |      0     1   Total
-------------+---------------------
  subgroup   |                     
    exposure |                     
      Grp1   |    330   190     520
      Grp2   |     40    60     100
      Grp3   |     70    50     120
      Total  |    440   300     740
  Total      |                     
    exposure |                     
      Grp1   |    730   230     960
      Grp2   |    150   110     260
      Grp3   |    420   250     670
      Total  |  1,300   590   1,890
-----------------------------------
*/
/*
cls
program drop rori
rori, t(110, 230 \ 150, 730) r(60, 190 \ 40, 330)
matprint r(pr_ror)
rori, t(110, 230 \ 150, 730) r(60, 190 \ 40, 330) nt(1890) nr(740)
matprint r(pr_ror)
*/