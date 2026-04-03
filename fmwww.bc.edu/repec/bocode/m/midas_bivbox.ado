*! version 2.7.5 26mar2026  Ben A. Dwamena (University of Michigan)
*! midas_bivbox: robust/classical bivariate boxplot for DTA data
*! Input: tp fp fn tn
*! Internal transform: logit sensitivity and logit specificity only
*! v2.7.5: all return values via return scalar/matrix (no st_numscalar to r());
*!         suppress (N missing values generated) messages;
*!         mata: single-line vectorized st_store for plot data

cap program drop midas_bivbox
program define midas_bivbox, rclass
    version 17

    syntax varlist(min=4 max=4 numeric) [if] [in] , ///
        [ ROBust CLASSical                        ///
          ID(varname)                             ///
          CUTOff(real 7)                          ///
          CC(real 0.5)                            ///
          LABeloutliers                           ///
          INNERLevel(real 0.50)                   ///
          OUTERPattern(string)                    ///
          INNERPattern(string)                    ///
          ASPECT(real 1)                          ///
          XTItle(string asis)                     ///
          YTItle(string asis)                     ///
          TITle(string asis)                      ///
          SUBTitle(string asis)                   ///
          NAME(name) REPlace                      ///
          NORMtest ROBNormtest BACONtest          ///
          * ]

    marksample touse

    quietly count if `touse'
    if (r(N) == 0) error 2000

    if ("`robust'" != "" & "`classical'" != "") {
        di as err "choose only one of robust or classical"
        exit 198
    }
    if ("`robust'" == "" & "`classical'" == "") local robust robust

    if (`cutoff' <= 0) {
        di as err "cutoff() must be > 0"
        exit 198
    }
    if (`cc' < 0) {
        di as err "cc() must be >= 0"
        exit 198
    }
    if (`aspect' <= 0) {
        di as err "aspect() must be > 0"
        exit 198
    }
    if (`innerlevel' <= 0 | `innerlevel' >= 1) {
        di as err "innerlevel() must be between 0 and 1"
        exit 198
    }
    if ("`normtest'" != "" & "`robnormtest'" != "") {
        di as err "choose only one of normtest or robnormtest"
        exit 198
    }

    if ("`bacontest'" != "") {
        capture which bacon
        if (_rc) {
            di as err "option bacontest requires the user-written command {bf:bacon}"
            di as err "Install it first with: {bf:ssc install bacon}"
            exit 111
        }
    }

    if (`"`outerpattern'"' == "") local outerpattern dash
    if (`"`innerpattern'"' == "") local innerpattern solid
    if (`"`title'"'        == "") local title `"Bivariate Boxplot"'
    if (`"`xtitle'"'       == "") local xtitle "Logit Sensitivity"
    if (`"`ytitle'"'       == "") local ytitle "Logit Specificity"

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

        replace `xv' = logit(`sens') if `touse'
        replace `yv' = logit(`spec') if `touse'
    }

    quietly count if `touse'
    if (r(N) == 0) error 2000
    local N = r(N)

    mata: _bvbox_M = J(0,2,.)
    mata: st_view(_bvbox_M, ., ("`xv'","`yv'"), "`touse'")
    mata: _bvbox_OUT = bv_box_compute(_bvbox_M, `cutoff', ("`robust'"!=""), `innerlevel')
    mata: _bvbox_M = J(0,0,.)

    mata: st_numscalar("_bvbox_ninner", rows(_bvbox_OUT.xp))
    mata: st_numscalar("_bvbox_nouter", rows(_bvbox_OUT.xpp))

    local diag_color ""
    local diag_text  ""
    local noteopt    ""

    * --- initialise robnormtest locals (used later for display & traffic-light) ---
    local _rqq     .
    local _rslope  .
    local _rintcpt .
    local _rmaxdev .
    local _rmethod ""

    tempvar _bvb_flag _bvb_dist _bvb_lab _bvb_baconflag
    preserve
        quietly keep if `touse'
        quietly gen byte   `_bvb_flag' = .
        quietly gen double `_bvb_dist' = .

        mata: st_store(., "`_bvb_flag'", _bvbox_OUT.flag)
        mata: st_store(., "`_bvb_dist'", _bvbox_OUT.dist)

        if ("`id'" != "") {
            capture confirm string variable `id'
            if !_rc {
                gen strL `_bvb_lab' = `id'
            }
            else {
                tostring `id', gen(`_bvb_lab') format(%18.0g) force
            }
        }

        if ("`bacontest'" != "") {
            capture noisily bacon `xv' `yv', generate(`_bvb_baconflag')
            if (_rc) {
                di as err "bacon failed; continuing without BACON diagnostics"
                gen byte `_bvb_baconflag' = .
            }
            else {
                quietly count if `_bvb_baconflag' == 1
                return scalar bacon_outliers = r(N)
                return scalar bacon_prop = r(N) / _N
            }
        }

        * ---------------------------------------------------------------
        * robnormtest: compute all diagnostics, store in locals FIRST,
        * then issue return statements, then display from locals.
        * This avoids the problem where return local clears r().
        * ---------------------------------------------------------------
        if ("`robnormtest'" != "") {
            tempvar d2 q absdev _bvb_xc _bvb_yc _bvb_num _bvb_den

            gen double `d2' = `_bvb_dist'^2
            sort `d2'
            gen double `q' = invchi2(2, (_n - 0.5)/`N')

            quietly correlate `d2' `q'
            local _rqq = r(rho)

            * compute slope/intercept manually
            quietly summarize `d2', meanonly
            local mx = r(mean)
            quietly summarize `q', meanonly
            local my = r(mean)
            quietly gen double `_bvb_xc' = `d2' - `mx'
            quietly gen double `_bvb_yc' = `q' - `my'
            quietly gen double `_bvb_num' = `_bvb_xc' * `_bvb_yc'
            quietly gen double `_bvb_den' = `_bvb_yc' * `_bvb_yc'
            quietly summarize `_bvb_num', meanonly
            local sxy = r(sum)
            quietly summarize `_bvb_den', meanonly
            local syy = r(sum)
            if (`syy' > 0) {
                local _rslope  = `sxy' / `syy'
                local _rintcpt = `mx' - `_rslope' * `my'
            }

            gen double `absdev' = abs(`d2' - `q')
            quietly summarize `absdev', meanonly
            local _rmaxdev = r(max)
            local _rmethod "robust ellipticity diagnostic"

            * --- return values ---
            return scalar robnorm_rqq       = `_rqq'
            return scalar robnorm_slope     = `_rslope'
            return scalar robnorm_intercept = `_rintcpt'
            return scalar robnorm_maxdev    = `_rmaxdev'
            return local  robnorm_method      "`_rmethod'"

            * --- display from locals (safe from r() clearing) ---
            di as txt _n "Bivariate normality / ellipticity diagnostic"
            di as txt "Method: " as res "`_rmethod'"
            di as txt "Number of studies = " as res %9.0f `N'
            di as txt "Correlation(QQ)   = " as res %9.4f `_rqq'
            di as txt "Slope             = " as res %9.4f `_rslope'
            di as txt "Intercept         = " as res %9.4f `_rintcpt'
            di as txt "Max abs deviation = " as res %9.4f `_rmaxdev'
        }

        * --- traffic-light logic uses locals, not r() ---
        local qqcorr `_rqq'
        local maxdev `_rmaxdev'
        local bprop  .
        if ("`bacontest'" != "") {
            capture confirm scalar r(bacon_prop)
            if !_rc local bprop = r(bacon_prop)
        }

        if ("`robnormtest'" != "" | "`bacontest'" != "") {
            if ("`robnormtest'" != "" & "`bacontest'" != "") {
                if (`qqcorr' >= 0.97 & `bprop' <= 0.10) {
                    local diag_color "GREEN"
                    local diag_text  "Approximate ellipticity supported"
                }
                else if (`qqcorr' >= 0.95 & `bprop' <= 0.15) {
                    local diag_color "YELLOW"
                    local diag_text  "Departure likely driven by few outliers"
                }
                else if (`qqcorr' < 0.90 | `bprop' > 0.30 | `maxdev' > 2) {
                    local diag_color "RED"
                    local diag_text  "Evidence of structural non-ellipticity"
                }
                else {
                    local diag_color "YELLOW"
                    local diag_text  "Mixed diagnostic evidence"
                }
            }
            else if ("`robnormtest'" != "") {
                if (`qqcorr' >= 0.97 & `maxdev' < 1) {
                    local diag_color "GREEN"
                    local diag_text  "Robust ellipticity supported"
                }
                else if (`qqcorr' >= 0.93) {
                    local diag_color "YELLOW"
                    local diag_text  "Borderline robust ellipticity"
                }
                else {
                    local diag_color "RED"
                    local diag_text  "Poor robust ellipticity fit"
                }
            }
            else if ("`bacontest'" != "") {
                if (`bprop' <= 0.10) {
                    local diag_color "GREEN"
                    local diag_text  "Few multivariate outliers detected"
                }
                else if (`bprop' <= 0.25) {
                    local diag_color "YELLOW"
                    local diag_text  "Moderate outlier contamination"
                }
                else {
                    local diag_color "RED"
                    local diag_text  "Substantial multivariate contamination"
                }
            }
        }

        * --- expand dataset in-memory to hold curve/segment data ---
        local _npts = _N
        local _ninn = scalar(_bvbox_ninner)
        local _nout = scalar(_bvbox_nouter)
        local _ntot = `_npts' + `_ninn' + `_nout' + 4

        quietly {
            gen double xp  = .
            gen double yp  = .
            gen double xpp = .
            gen double ypp = .
            gen double s1x = .
            gen double s1y = .
            gen double s2x = .
            gen double s2y = .
            gen int    _ptype = 0

            set obs `_ntot'
        }

        mata: _bvb_npts = `_npts'
        mata: _bvb_ninn = `_ninn'
        mata: _bvb_nout = `_nout'
        mata: _bvb_rows_inn = (_bvb_npts+1)::(_bvb_npts+_bvb_ninn)
        mata: st_store(_bvb_rows_inn, "xp",     _bvbox_OUT.xp)
        mata: st_store(_bvb_rows_inn, "yp",     _bvbox_OUT.yp)
        mata: st_store(_bvb_rows_inn, "_ptype", J(_bvb_ninn, 1, 1))
        mata: _bvb_rows_out = (_bvb_npts+_bvb_ninn+1)::(_bvb_npts+_bvb_ninn+_bvb_nout)
        mata: st_store(_bvb_rows_out, "xpp",    _bvbox_OUT.xpp)
        mata: st_store(_bvb_rows_out, "ypp",    _bvbox_OUT.ypp)
        mata: st_store(_bvb_rows_out, "_ptype", J(_bvb_nout, 1, 2))
        mata: _bvb_base = _bvb_npts + _bvb_ninn + _bvb_nout
        mata: st_store(_bvb_base+1, "s1x", _bvbox_OUT.seg1[1])
        mata: st_store(_bvb_base+1, "s1y", _bvbox_OUT.seg1y[1])
        mata: st_store(_bvb_base+1, "_ptype", 3)
        mata: st_store(_bvb_base+2, "s1x", _bvbox_OUT.seg1[2])
        mata: st_store(_bvb_base+2, "s1y", _bvbox_OUT.seg1y[2])
        mata: st_store(_bvb_base+2, "_ptype", 3)
        mata: st_store(_bvb_base+3, "s2x", _bvbox_OUT.seg2[1])
        mata: st_store(_bvb_base+3, "s2y", _bvbox_OUT.seg2y[1])
        mata: st_store(_bvb_base+3, "_ptype", 4)
        mata: st_store(_bvb_base+4, "s2x", _bvbox_OUT.seg2[2])
        mata: st_store(_bvb_base+4, "s2y", _bvbox_OUT.seg2y[2])
        mata: st_store(_bvb_base+4, "_ptype", 4)

        local labcmd
        if ("`labeloutliers'" != "" & "`id'" != "") {
            local labcmd ///
            (scatter `yv' `xv' if `_bvb_flag'==1, msymbol(Oh) msize(*2.5) mlabel(`_bvb_lab') mlabsize(vsmall) mlabpos(0) mlabgap(0))
        }

        local nameopt
        if ("`name'" != "") {
            local rep = cond("`replace'" != "", " replace", "")
            local nameopt `", name(`name'`rep')"'
        }

        if (`"`diag_color'"' != "") {
            local noteopt `"note("Traffic-light: `diag_color' -- `diag_text'")"'
        }

        // Legend: when labeloutliers adds plot 3, ellipses shift to 5,6 and lines to 7,8
        if ("`labeloutliers'" != "" & "`id'" != "") {
            local legendopt legend(order(1 "Inside fence" 3 "Outside fence" 4 "Inner ellipse" 5 "Outer ellipse" 6 "Sp on Se" 7 "Se on Sp"))
        }
        else {
            local legendopt legend(order(1 "Inside fence" 2 "Outside fence" 3 "Inner ellipse" 4 "Outer ellipse" 5 "Sp on Se" 6 "Se on Sp"))
        }

        twoway ///
            (scatter `yv' `xv' if `_bvb_flag'==0 & _ptype==0, msymbol(o)) ///
            (scatter `yv' `xv' if `_bvb_flag'==1 & _ptype==0 & "`labeloutliers'"=="", msymbol(Oh)) ///
            `labcmd' ///
            (line yp  xp  if _ptype==1, lpattern(`innerpattern')) ///
            (line ypp xpp if _ptype==2, lpattern(`outerpattern')) ///
            (line s1y s1x if _ptype==3, lpattern(dot) lwidth(thick)) ///
            (line s2y s2x if _ptype==4, lpattern(longdash) lwidth(thick)) ///
            , ///
            aspect(`aspect') ///
            xlab(, grid) ylab(, grid) ///
            xtitle(`"`xtitle'"') ///
            ytitle(`"`ytitle'"') ///
            title(`"`title'"') ///
            subtitle(`"`subtitle'"') ///
            `legendopt' ///
            `noteopt' ///
            `options' ///
            `nameopt'
    restore

    * Display traffic-light assessment panel
    if (`"`diag_color'"' != "") {
        di as txt _n "{hline 55}"
        di as txt "  Bivariate ellipticity assessment"
        di as txt "{hline 55}"
        if ("`diag_color'" == "GREEN") {
            di as txt "  Status : " as result "GREEN  -- " as txt "`diag_text'"
        }
        else if ("`diag_color'" == "YELLOW") {
            di as txt "  Status : " as result "YELLOW -- " as txt "`diag_text'"
        }
        else {
            di as txt "  Status : " as result "RED    -- " as txt "`diag_text'"
        }
        if ("`robnormtest'" != "") {
            di as txt "  QQ corr: " as res %7.4f `_rqq' ///
                      as txt "   MaxDev: " as res %7.4f `_rmaxdev'
        }
        if ("`bacontest'" != "") {
            capture confirm scalar r(bacon_outliers)
            if !_rc {
                di as txt "  BACON outliers: " as res %4.0f r(bacon_outliers) ///
                          as txt "  (" as res %5.1f 100*r(bacon_prop) as txt "%)"
            }
        }
        di as txt "{hline 55}"
        di as txt "  Implication for pooling:"
        if ("`diag_color'" == "GREEN") {
            di as txt "  Bivariate normal assumption tenable."
            di as txt "  HSROC / bivariate model appropriate."
        }
        else if ("`diag_color'" == "YELLOW") {
            di as txt "  Moderate departure from ellipticity."
            di as txt "  Inspect outliers; consider sensitivity analysis."
        }
        else {
            di as txt "  Substantial non-ellipticity detected."
            di as txt "  Bivariate model assumptions may be violated."
            di as txt "  Consider subgroup analysis or robust pooling."
        }
        di as txt "{hline 55}"
    }

    if ("`normtest'" != "") {
        noisily di as txt _n "Classical multivariate normality diagnostic"
        capture noisily mvtest normality `xv' `yv' if `touse'
        if (_rc) {
            di as err "mvtest normality failed"
        }
        else {
            return local normtest_method "mvtest normality"
            scalar _bvbox_mvp = .
            capture scalar _bvbox_mvp = r(p_hz)
            if (_rc) capture scalar _bvbox_mvp = r(p_dh)
            if (_rc) capture scalar _bvbox_mvp = r(p)
            if (_rc) capture scalar _bvbox_mvp = r(P)
            capture confirm scalar _bvbox_mvp
            if (!_rc & !missing(_bvbox_mvp)) {
                return scalar normtest_p = _bvbox_mvp
            }
        }
    }

    * --- extract return values from Mata struct into locals/tempnames ---
    tempname _bvb_ctr _bvb_scl _bvb_bnd
    local _bvb_corr   .
    local _bvb_nout   .
    capture {
        mata: st_matrix("`_bvb_ctr'", _bvbox_OUT.center)
        mata: st_matrix("`_bvb_scl'", _bvbox_OUT.scale)
        mata: st_matrix("`_bvb_bnd'", _bvbox_OUT.bounds)
        mata: st_local("_bvb_corr", strofreal(_bvbox_OUT.corr))
        mata: st_local("_bvb_nout", strofreal(sum(_bvbox_OUT.flag)))
        matrix colnames `_bvb_ctr' = x y
        matrix colnames `_bvb_scl' = sx sy
        matrix colnames `_bvb_bnd' = minx maxx miny maxy
    }

    * --- issue all return statements together (no interleaved mata: calls) ---
    capture return matrix center = `_bvb_ctr'
    capture return matrix scale  = `_bvb_scl'
    capture return matrix bounds = `_bvb_bnd'
    return scalar corr   = `_bvb_corr'
    return scalar cutoff = `cutoff'
    return scalar n      = `N'
    return scalar n_out  = `_bvb_nout'
    return local input_mode "tp fp fn tn"
    return local link "logit"
    return scalar cc = `cc'
    if (`"`diag_color'"' != "") return local diag_color "`diag_color'"
    if (`"`diag_text'"'  != "") return local diag_text  "`diag_text'"

    capture mata: mata drop _bvbox_OUT
end


mata:
real scalar _bvb_median(real colvector v)
{
    real colvector s
    real scalar n
    s = sort(v, 1)
    n = rows(s)
    if (n == 0) {
        return(.)
    }
    if (mod(n,2)==1) {
        return(s[(n+1)/2])
    }
    return((s[n/2] + s[n/2+1])/2)
}

real rowvector bv_biweight(real matrix A, real scalar const1, real scalar const2, real scalar err)
{
    real scalar n, c1, c2, c2orig, tol, i, j, l, rxy, term, sxsafe, sysafe
    real colvector x, y, w, wold, z1, z2, esq
    real scalar mx,my,madx,mady,tx,ty,sx,sy,mz1,mz2,madz1,madz2,tz1,tz2,sz1,sz2
    real colvector ux, ux1, xc, uy, uy1, yc, uz1, u1, z1c, uz2, u2, z2c, w1, ink

    n=rows(A); x=A[,1]; y=A[,2]; c1=const1; c2=const2; tol=err

    mx=_bvb_median(x); my=_bvb_median(y)
    madx=_bvb_median(abs(x:-mx)); mady=_bvb_median(abs(y:-my))

    tx=mx; sx=mean(abs(x:-mx))
    if (madx != 0) {
        ux=(x:-mx):/(c1*madx); ink=(abs(ux):<1)
        ux1=select(ux,ink); xc=select(x,ink); w1=(1:-ux1:^2):^2
        tx=mx+sum((xc:-mx):*w1)/sum(w1)
        sx=sqrt(n)*sqrt(sum((xc:-mx):^2:*(1:-ux1:^2):^4))/abs(sum((1:-ux1:^2):*(1:-5:*ux1:^2)))
    }

    ty=my; sy=mean(abs(y:-my))
    if (mady != 0) {
        uy=(y:-my):/(c1*mady); ink=(abs(uy):<1)
        uy1=select(uy,ink); yc=select(y,ink); w1=(1:-uy1:^2):^2
        ty=my+sum((yc:-my):*w1)/sum(w1)
        sy=sqrt(n)*sqrt(sum((yc:-my):^2:*(1:-uy1:^2):^4))/abs(sum((1:-uy1:^2):*(1:-5:*uy1:^2)))
    }

    z1=(y:-ty):/sy:+(x:-tx):/sx; z2=(y:-ty):/sy:-(x:-tx):/sx
    mz1=_bvb_median(z1); madz1=_bvb_median(abs(z1:-mz1))
    mz2=_bvb_median(z2); madz2=_bvb_median(abs(z2:-mz2))

    tz1=mz1; sz1=mean(abs(z1:-mz1))
    if (madz1 != 0) {
        uz1=(z1:-mz1):/(c1*madz1); ink=(abs(uz1):<1)
        u1=select(uz1,ink); z1c=select(z1,ink); w1=(1:-u1:^2):^2
        tz1=mz1+sum((z1c:-mz1):*w1)/sum(w1)
        sz1=sqrt(n)*sqrt(sum((z1c:-mz1):^2:*(1:-u1:^2):^4))/abs(sum((1:-u1:^2):*(1:-5:*u1:^2)))
    }

    tz2=mz2; sz2=mean(abs(z2:-mz2))
    if (madz2 != 0) {
        uz2=(z2:-mz2):/(c1*madz2); ink=(abs(uz2):<1)
        u2=select(uz2,ink); z2c=select(z2,ink); w1=(1:-u2:^2):^2
        tz2=mz2+sum((z2c:-mz2):*w1)/sum(w1)
        sz2=sqrt(n)*sqrt(sum((z2c:-mz2):^2:*(1:-u2:^2):^4))/abs(sum((1:-u2:^2):*(1:-5:*u2:^2)))
    }

    esq=((z1:-tz1):/sz1):^2:+((z2:-tz2):/sz2):^2
    w=J(n,1,0); c2orig=c2

    for (i=1; i<=10; i++) {
        w=(esq:<c2):*(1:-esq:/c2):^2
        l=sum(w:==0)
        if (l<0.5*n) {
            break
        }
        c2=2*c2
    }

    tx=sum(w:*x)/sum(w); sx=sqrt(sum(w:*(x:-tx):^2)/sum(w))
    ty=sum(w:*y)/sum(w); sy=sqrt(sum(w:*(y:-ty):^2)/sum(w))
    rxy=sum(w:*(x:-tx):*(y:-ty))/(sx*sy*sum(w))
    wold=w

    for (i=1; i<=100; i++) {
        sxsafe=(sx>0)*sx+(sx<=0)*1e-12
        sysafe=(sy>0)*sy+(sy<=0)*1e-12
        z1=((y:-ty):/sysafe:+(x:-tx):/sxsafe):/sqrt(2*(1+rxy))
        z2=((y:-ty):/sysafe:-(x:-tx):/sxsafe):/sqrt(2*(1-rxy))
        esq=z1:^2:+z2:^2; c2=c2orig
        for (j=1; j<=10; j++) {
            w=(esq:<c2):*(1:-esq:/c2):^2
            l=sum(w:==0)
            if (l<0.5*n) {
                break
            }
            c2=2*c2
        }
        tx=sum(w:*x)/sum(w); sx=sqrt(sum(w:*(x:-tx):^2)/sum(w))
        ty=sum(w:*y)/sum(w); sy=sqrt(sum(w:*(y:-ty):^2)/sum(w))
        rxy=sum(w:*(x:-tx):*(y:-ty))/(sx*sy*sum(w))
        term=sum((w:-wold):^2)/((sum(w)/n)^2)
        if (term<tol) {
            break
        }
        wold=w; c2=c2orig
    }
    return((tx,ty,sx,sy,rxy))
}

struct bvbox_out {
    real colvector xp
    real colvector yp
    real colvector xpp
    real colvector ypp
    real colvector seg1
    real colvector seg1y
    real colvector seg2
    real colvector seg2y
    real rowvector bounds
    real rowvector center
    real rowvector scale
    real scalar corr
    real colvector dist
    real colvector flag
}

struct bvbox_out bv_box_compute(real matrix A, real scalar d, real scalar use_robust, real scalar innerlevel)
{
    real rowvector par
    real scalar m1,m2,s1,s2,r,em,einner,emax,r1,r2
    real scalar maxxl,minxl,maxyl,minyl,b1,a1,y1,y2,b2,a2,x1,x2,maxx,minx,maxy,miny
    real colvector x,y,e,e2,eok,esort,theta,xp,yp,xpp,ypp,flag
    real scalar idx
    struct bvbox_out scalar out

    if (use_robust) {
        par = bv_biweight(A, 9, 36, 1e-4)
        par = (par[1], par[2], par[3], par[4], par[5])
    }
    else {
        m1 = mean(A[,1])
        m2 = mean(A[,2])
        s1 = sqrt(variance(A[,1])[1,1])
        s2 = sqrt(variance(A[,2])[1,1])
        r  = quadcross(A[,1]-m1, A[,2]-m2)[1,1] / ///
             sqrt(quadcross(A[,1]-m1, A[,1]-m1)[1,1] * quadcross(A[,2]-m2, A[,2]-m2)[1,1])
        par = (m1, m2, s1, s2, r)
    }
    m1 = par[1]; m2 = par[2]; s1 = par[3]; s2 = par[4]; r = par[5]

    if (s1<=0) s1 = 1e-8
    if (s2<=0) s2 = 1e-8
    if (abs(r)>=1) r = sign(r)*0.999999

    x=(A[,1]:-m1):/s1; y=(A[,2]:-m2):/s2
    e=sqrt((x:^2:+y:^2:-2*r:*x:*y):/(1-r^2)); e2=e:^2
    em=_bvb_median(e)

    esort = sort(e,1)
    idx   = ceil(innerlevel*rows(esort))
    if (idx < 1) idx = 1
    if (idx > rows(esort)) idx = rows(esort)
    einner = esort[idx]

    eok=select(e,e2:<d*em^2)
    if (rows(eok)>0) {
        emax=max(eok)
    }
    else {
        emax=max(e)
    }
    flag=(e:>emax)

    r1=einner*sqrt((1+r)/2); r2=einner*sqrt((1-r)/2)
    theta=(2*pi()/360):*range(0,360,3)
    xp=m1:+(r1:*cos(theta):+r2:*sin(theta)):*s1
    yp=m2:+(r1:*cos(theta):-r2:*sin(theta)):*s2

    r1=emax*sqrt((1+r)/2); r2=emax*sqrt((1-r)/2)
    xpp=m1:+(r1:*cos(theta):+r2:*sin(theta)):*s1
    ypp=m2:+(r1:*cos(theta):-r2:*sin(theta)):*s2

    maxxl=max(xpp); minxl=min(xpp); maxyl=max(ypp); minyl=min(ypp)
    b1=(r*s2)/s1; a1=m2-b1*m1; y1=a1+b1*minxl; y2=a1+b1*maxxl
    b2=(r*s1)/s2; a2=m1-b2*m2; x1=a2+b2*minyl; x2=a2+b2*maxyl

    maxx=max((A[,1]\xp\xpp\x1\x2)); minx=min((A[,1]\xp\xpp\x1\x2))
    maxy=max((A[,2]\yp\ypp\y1\y2)); miny=min((A[,2]\yp\ypp\y1\y2))

    out.xp    =xp; out.yp   =yp; out.xpp  =xpp; out.ypp  =ypp
    out.seg1  =(minxl\maxxl); out.seg1y=(y1\y2)
    out.seg2  =(x1\x2); out.seg2y=(minyl\maxyl)
    out.bounds=(minx,maxx,miny,maxy)
    out.center=(m1,m2); out.scale=(s1,s2); out.corr=r
    out.dist  =e; out.flag=flag
    return(out)
}

end
