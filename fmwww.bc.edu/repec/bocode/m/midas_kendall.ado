*! version 2.0.0 25mar2026  Ben A. Dwamena (University of Michigan)
cap program drop midas_kendall
program define midas_kendall, rclass
    version 17

    syntax varlist(min=4 max=4 numeric) [if] [in] , ///
        [ CC(real 0.5)                            ///
          XTItle(string asis)                     ///
          YTItle(string asis)                     ///
          TITle(string asis)                      ///
          SUBTitle(string asis)                   ///
          NAME(name) REPlace                      ///
          * ]

    marksample touse

    quietly count if `touse'
    if (r(N) == 0) error 2000

    local link "logit"
    if ("`title'"=="") local title `"Kendall Plot"'

    tokenize `varlist'
    local tp `1'
    local fp `2'
    local fn `3'
    local tn `4'

    tempvar ndis nnondis sens spec xv yv
    quietly {
        gen double `ndis'    = `tp' + `fn' if `touse'
        gen double `nnondis' = `tn' + `fp' if `touse'

        replace `touse' = 0 if missing(`tp', `fp', `fn', `tn')
        replace `touse' = 0 if `ndis' <= 0 | `nnondis' <= 0

        gen double `sens' = .
        gen double `spec' = .
        gen double `xv'   = .
        gen double `yv'   = .

        replace `sens' = (`tp' + `cc') / (`ndis' + 2*`cc') if `touse'
        replace `spec' = (`tn' + `cc') / (`nnondis' + 2*`cc') if `touse'

        replace `xv' = log(`sens'/(1-`sens')) if `touse'
        replace `yv' = log(`spec'/(1-`spec')) if `touse'
        if ("`xtitle'"=="") local xtitle "Theoretical cumulative under independence"
        if ("`ytitle'"=="") local ytitle "Empirical Kendall cumulative"
    }

    quietly count if `touse'
    if (r(N) == 0) error 2000

    // Extract data into Mata using fixed global names before preserve/clear
    mata: _midas_kx = st_data(., "`xv'", "`touse'")
    mata: _midas_ky = st_data(., "`yv'", "`touse'")
    mata: _midas_ko = bv_kendallplot(_midas_kx, _midas_ky)
    mata: st_numscalar("_midas_kn", rows(_midas_ko))
    local kn = _midas_kn
    cap scalar drop _midas_kn

    preserve
        quietly {
        clear
        set obs `kn'
        gen double theo = .
        gen double emp  = .
        mata: st_store(., "theo", _midas_ko[,1])
        mata: st_store(., "emp",  _midas_ko[,2])
        } // end quietly

        local nameopt
        if ("`name'"!="") {
            local rep = cond("`replace'"!="", " replace", "")
            local nameopt `", name(`name'`rep')"'
        }

        twoway ///
            (function y = x, range(0 1) lpattern(dash)) ///
            (scatter emp theo, msymbol(o)) ///
            , ///
            aspect(1) ///
            xtitle(`"`xtitle'"') ///
            ytitle(`"`ytitle'"') ///
            title(`"`title'"') ///
            subtitle(`"`subtitle'"') ///
            legend(off) ///
            `options' ///
            `nameopt'
    restore

    mata: st_numscalar("r(kendall_tau)", bv_kendall_tau(_midas_kx, _midas_ky))

    return scalar n = `kn'
    return scalar kendall_tau = r(kendall_tau)
    return scalar cc = `cc'
    return local input_mode "tp fp fn tn"
    // Clean up Mata globals
    cap mata: mata drop _midas_kx _midas_ky _midas_ko
end


capture mata: mata drop bv_kendallplot()
mata:
real matrix bv_kendallplot(real colvector x, real colvector y)
{
    real scalar n, i
    real colvector rx, ry, w, wsort, theor, ox, oy

    n = rows(x)

    // Statistical ranks via order()
    ox = order(x, 1)
    rx = J(n, 1, .)
    for (i=1; i<=n; i++) rx[ox[i]] = i
    rx = rx :/ (n + 1)

    oy = order(y, 1)
    ry = J(n, 1, .)
    for (i=1; i<=n; i++) ry[oy[i]] = i
    ry = ry :/ (n + 1)

    w  = J(n, 1, 0)
    for (i=1; i<=n; i++) {
        w[i] = mean((rx :<= rx[i]) :* (ry :<= ry[i]))
    }

    wsort = sort(w, 1)
    theor = (1::n) :/ (n + 1)

    return((theor, wsort))
}
end


capture mata: mata drop bv_kendall_tau()
mata:
real scalar bv_kendall_tau(real colvector x, real colvector y)
{
    real scalar n, i, j, s, dx, dy

    n = rows(x)
    if (n < 2) return(.)

    s = 0
    for (i=1; i<=n-1; i++) {
        for (j=i+1; j<=n; j++) {
            dx = x[j] - x[i]
            dy = y[j] - y[i]
            s = s + sign(dx*dy)
        }
    }

    return( 2*s / (n*(n-1)) )
}
end
