*! qqsurf3d 1.0.0 29may2026
*! MATLAB-style filled 3D surface for QQR / QQ-KRLS results.
*! Renders beta(tau,theta) as an oblique-projected, colour-filled surface
*! (bilinear-interpolated tiles) with a wireframe mesh, a floor/z-axis frame
*! and a side colour bar -- the look of Fig. 9 in Adebayo, Ozkan & Eweade
*! (2024, J. Cleaner Prod. 440:140832).
*! Author: Merwan Roudane

program qqsurf3d
    version 14
    syntax [using/] [,                       ///
        Value(name)                          ///
        VARiable(name)                       ///
        BAND(name)                           ///
        COLORMAP(name)                        ///
        LEVELS(integer 18)                   ///
        FINE(integer 64)                     ///
        MSize(string)                        ///
        CBSize(string)                       ///
        AZIMuth(real 35)                     ///
        ELEvation(real 25)                   ///
        ZSCale(real 0.6)                     ///
        Title(string)                        ///
        XTitle(string)                       ///
        YTitle(string)                       ///
        ZTitle(string)                       ///
        NOWIRE                               ///
        NOCBar                               ///
        SAVE(string)                         ///
        Name(string asis)                    ///
        SCheme(string)                       ///
        REPLACE ]

    if "`value'"==""    local value    "coef"
    if "`colormap'"=="" local colormap "jet"
    if "`msize'"==""    local msize    "medlarge"
    if "`cbsize'"==""   local cbsize   "vlarge"
    if `"`title'"' == ""  local title  "QQR 3D surface"
    if `"`xtitle'"' == "" local xtitle "{&theta}"
    if `"`ytitle'"' == "" local ytitle "{&tau}"
    if `"`ztitle'"' == "" local ztitle "{&beta}"
    if "`scheme'"==""     local scheme "s2color"
    if `levels' < 4 local levels 4

    preserve

    if `"`using'"' != "" {
        qui use `"`using'"', clear
    }

    cap confirm variable `value'
    if _rc {
        di as err "value variable `value' not found"
        exit 111
    }
    foreach v in tau theta {
        cap confirm variable `v'
        if _rc {
            di as err "expected variable `v' in dataset"
            exit 111
        }
    }

    if "`variable'" != "" {
        cap confirm variable variable
        if !_rc qui keep if variable == "`variable'"
    }
    if "`band'" != "" {
        cap confirm variable band
        if !_rc qui keep if band == "`band'"
    }

    * Need a genuine grid in both dimensions to build a surface.
    qui levelsof theta, local(_thv)
    qui levelsof tau,   local(_tav)
    local nT : word count `_thv'
    local nA : word count `_tav'
    if `nT' < 2 | `nA' < 2 {
        di as err "qqsurf3d needs at least 2 distinct tau and 2 distinct theta values"
        exit 459
    }

    * Colours (levels colours, evenly sampled along the colormap).
    qui su `value', meanonly
    local zmn = r(min)
    local zmx = r(max)
    _qqcolors, map(`colormap') zmin(`zmn') zmax(`zmx') levels(`levels')
    local colors `"`r(colors)'"'

    * ---- Build all geometry in one Mata pass --------------------------------
    * Reads theta/tau/`value' from the data; writes a NEW dataset of plot
    * points (_px3,_py3 = projected coords, _bkt3 = colour bucket 1..levels,
    * _cb3 = 1 for colour-bar swatches) and returns wireframe / frame / label
    * coordinates as local macros.
    mata: lqqr_surf3d_build("`value'", `levels', `fine', `azimuth', `elevation', `zscale')

    * ---- Colour-bar value labels (interpretation guide) --------------------
    local barRng = `barTop' - `barBot'
    local zRng_v = `zmax_v' - `zmin_v'

    * ---- Assemble surface + colour-bar scatter overlays ---------------------
    local surf ""
    local cbar ""
    forval k = 1/`levels' {
        local col : word `k' of `colors'
        local col = subinstr(`"`col'"', `"""', "", .)
        local surf `surf' (scatter _py3 _px3 if _bkt3==`k' & _cb3==0, ///
            msymbol(square) msize(`msize') mcolor("`col'") mlcolor("`col'") mlwidth(vvthin))
        if "`nocbar'"=="" {
            local cbar `cbar' (scatter _py3 _px3 if _bkt3==`k' & _cb3==1, ///
                msymbol(square) msize(`cbsize') mcolor("`col'") mlcolor("`col'") mlwidth(vvthin))
        }
    }

    * Wireframe mesh on top of the fill (optional).
    local wireplot ""
    if "`nowire'"=="" & `"`wire'"' != "" {
        local wireplot (pci `wire', lcolor(gs6%40) lwidth(vvthin))
    }

    * Colour-bar text labels (only when a bar is drawn): ~7 evenly spaced
    * values from zmin (bottom) to zmax (top) plus a caption naming the encoded
    * quantity, so the bar reads as an interpretation key.
    local cbtext ""
    if "`nocbar'"=="" {
        local nlab = 6
        forval j = 0/`nlab' {
            local fr   = `j'/`nlab'
            local ypos = `barBot' + `fr'*`barRng'
            local zval = `zmin_v' + `fr'*`zRng_v'
            local lbl  : di %6.3f `zval'
            local cbtext `cbtext' text(`ypos' `barX' `"`lbl'"', size(vsmall) placement(e))
        }
        local cbcap = `barTop' + 0.10*`barRng' + 0.04
        local cbtext `cbtext' text(`cbcap' `barX' `"`ztitle'"', size(small) placement(e))
    }

    local namopt
    if `"`name'"' != "" {
        if strpos(`"`name'"', ",") local namopt name(`name')
        else                       local namopt name(`name', replace)
    }

    twoway (pci `frame',   lcolor(gs10) lwidth(thin))                ///
           (pci `tickseg', lcolor(gs8)  lwidth(thin))                ///
           `surf'                                                    ///
           `wireplot'                                                ///
           `cbar'                                                    ///
           ,                                                         ///
           legend(off) aspectratio(1) scheme(`scheme')              ///
           title(`"`title'"', size(medium))                         ///
           subtitle(`"projection az=`azimuth' el=`elevation'  (colour = {bf:`value'})"', size(vsmall)) ///
           xscale(off) yscale(off) xlabel(none) ylabel(none)        ///
           xtitle("") ytitle("")                                    ///
           plotregion(margin(large))                                ///
           `ticktext'                                                ///
           text(`thy' `thx' `"`xtitle'"', size(medsmall) placement(s)) ///
           text(`tay' `tax' `"`ytitle'"', size(medsmall) placement(c)) ///
           text(`zly' `zlx' `"`ztitle'"', size(medium) placement(n)) ///
           `cbtext'                                                  ///
           `namopt'

    if `"`save'"' != "" {
        if "`replace'"=="replace" graph export `"`save'"', replace
        else                      graph export `"`save'"'
    }

    restore
end

* ===========================================================================
* Mata worker: build the projected surface geometry.
* ===========================================================================
version 14
mata:
mata set matastrict off

void lqqr_surf3d_build(string scalar val, real scalar K, real scalar fine,
                       real scalar azimuth, real scalar elevation,
                       real scalar zscale)
{
    real colvector th, ta, z, thv, tav
    real matrix    Z
    real scalar    nT, nA, o, r, c, zmin, zmax, zr
    real scalar    cA, sA, sE
    real scalar    i, j, idx, nf
    real scalar    uu, vv, gt, gtau, ci, ri, frt, fra, za, zb, zz, ww
    real scalar    u1, v1, w1, u2, v2, w2, px1, py1, px2, py2
    real colvector PX, PY, BKT, depth, CB, ord, pxv, pyv
    real scalar    pxmn, pxmx, pymn, pymx, pxr, barX
    string scalar  wire, box

    th = st_data(., "theta")
    ta = st_data(., "tau")
    z  = st_data(., val)

    thv = uniqrows(th)          // sorted distinct theta
    tav = uniqrows(ta)          // sorted distinct tau
    nT  = rows(thv)
    nA  = rows(tav)

    // Build the value grid Z[tau-row, theta-col]; gaps stay missing.
    Z = J(nA, nT, .)
    for (o=1; o<=rows(z); o++) {
        r = selectindex(tav :== ta[o])[1]
        c = selectindex(thv :== th[o])[1]
        Z[r, c] = z[o]
    }

    zmin = min(z)
    zmax = max(z)
    zr   = zmax - zmin
    if (zr <= 0) zr = 1

    cA = cos(azimuth   * pi()/180)
    sA = sin(azimuth   * pi()/180)
    sE = sin(elevation * pi()/180)
    if (fine < nT) fine = nT
    if (fine < nA) fine = nA

    // ---- Wireframe mesh on the native grid (theta- and tau-direction edges)
    wire = ""
    for (r=1; r<=nA; r++) {
        for (c=1; c<=nT-1; c++) {
            if (Z[r,c]!=. & Z[r,c+1]!=.) {
                u1=(c-1)/(nT-1); v1=(r-1)/(nA-1); w1=(Z[r,c]  -zmin)/zr
                u2=(c  )/(nT-1); v2=v1;           w2=(Z[r,c+1]-zmin)/zr
                px1=u1*cA-v1*sA; py1=(u1*sA+v1*cA)*sE + w1*zscale
                px2=u2*cA-v2*sA; py2=(u2*sA+v2*cA)*sE + w2*zscale
                wire = wire+" "+strofreal(py1)+" "+strofreal(px1)+" "+strofreal(py2)+" "+strofreal(px2)
            }
        }
    }
    for (c=1; c<=nT; c++) {
        for (r=1; r<=nA-1; r++) {
            if (Z[r,c]!=. & Z[r+1,c]!=.) {
                u1=(c-1)/(nT-1); v1=(r-1)/(nA-1); w1=(Z[r,c]  -zmin)/zr
                u2=u1;           v2=(r)/(nA-1);   w2=(Z[r+1,c]-zmin)/zr
                px1=u1*cA-v1*sA; py1=(u1*sA+v1*cA)*sE + w1*zscale
                px2=u2*cA-v2*sA; py2=(u2*sA+v2*cA)*sE + w2*zscale
                wire = wire+" "+strofreal(py1)+" "+strofreal(px1)+" "+strofreal(py2)+" "+strofreal(px2)
            }
        }
    }
    st_local("wire", wire)

    // ---- Dense bilinear-interpolated fill tiles
    nf  = fine*fine
    PX  = J(nf,1,.); PY = J(nf,1,.); BKT = J(nf,1,.); depth = J(nf,1,.)
    idx = 0
    for (i=1; i<=fine; i++) {
        uu = (i-1)/(fine-1)                 // theta in [0,1]
        gt = uu*(nT-1)+1
        ci = floor(gt); if (ci<1) ci=1; if (ci>nT-1) ci=nT-1
        frt = gt-ci
        for (j=1; j<=fine; j++) {
            vv = (j-1)/(fine-1)             // tau in [0,1]
            gtau = vv*(nA-1)+1
            ri = floor(gtau); if (ri<1) ri=1; if (ri>nA-1) ri=nA-1
            fra = gtau-ri
            za = Z[ri,  ci] + frt*(Z[ri,  ci+1]-Z[ri,  ci])
            zb = Z[ri+1,ci] + frt*(Z[ri+1,ci+1]-Z[ri+1,ci])
            zz = za + fra*(zb-za)
            ww = (zz-zmin)/zr
            idx++
            PX[idx]    = uu*cA - vv*sA
            PY[idx]    = (uu*sA+vv*cA)*sE + ww*zscale
            depth[idx] = uu*sA + vv*cA
            BKT[idx]   = floor(ww*K)+1
            if (BKT[idx]<1) BKT[idx]=1
            if (BKT[idx]>K) BKT[idx]=K
        }
    }

    // Painter's order: draw far (large depth) first, near last.
    ord   = order(depth, -1)
    PX    = PX[ord]; PY = PY[ord]; BKT = BKT[ord]
    CB    = J(rows(PX),1,0)

    // ---- Extents (ignore missing tiles from grid gaps)
    pxv = select(PX, PX:!=.)
    pyv = select(PY, PY:!=.)
    pxmn = min(pxv); pxmx = max(pxv)
    pymn = min(pyv); pymx = max(pyv)
    pxr  = pxmx-pxmn; if (pxr<=0) pxr = 1

    // ---- Colour-bar swatch points (one per bucket) at the right margin
    barX = pxmx + 0.12*pxr + 0.04
    for (i=1; i<=K; i++) {
        PX  = PX  \ barX
        PY  = PY  \ (pymn + (i-0.5)/K*(pymx-pymn))
        BKT = BKT \ i
        CB  = CB  \ 1
    }

    // ---- Full 3D bounding box (cube): bottom + top rectangles + 4 verticals
    string scalar frame, tickseg, ticktext, q
    real matrix RC, VC
    real scalar thmin, thmax, taumin, taumax, kk, step, frac, val2, uu2, vv2
    real scalar off1, off2, ii
    q = char(34)
    frame = ""
    RC = (0,0 \ 1,0 \ 1,1 \ 0,1 \ 0,0)
    for (i=1; i<=4; i++) {
        u1=RC[i,1]; v1=RC[i,2]; u2=RC[i+1,1]; v2=RC[i+1,2]
        // bottom edge (w=0)
        px1=u1*cA-v1*sA; py1=(u1*sA+v1*cA)*sE
        px2=u2*cA-v2*sA; py2=(u2*sA+v2*cA)*sE
        frame=frame+" "+strofreal(py1)+" "+strofreal(px1)+" "+strofreal(py2)+" "+strofreal(px2)
        // top edge (w=1)
        frame=frame+" "+strofreal(py1+zscale)+" "+strofreal(px1)+" "+strofreal(py2+zscale)+" "+strofreal(px2)
    }
    VC = (0,0 \ 1,0 \ 1,1 \ 0,1)
    for (i=1; i<=4; i++) {
        u1=VC[i,1]; v1=VC[i,2]
        px1=u1*cA-v1*sA; py1=(u1*sA+v1*cA)*sE
        frame=frame+" "+strofreal(py1)+" "+strofreal(px1)+" "+strofreal(py1+zscale)+" "+strofreal(px1)
    }
    st_local("frame", frame)

    // ---- Axis tick marks + numeric labels (theta, tau, z) ----------------
    thmin=thv[1]; thmax=thv[nT]; taumin=tav[1]; taumax=tav[nA]
    off1=0.035          // tick-mark length
    off2=0.10           // tick-label offset
    tickseg=""; ticktext=""

    // theta ticks along the front-bottom edge (v=0); labels below (south)
    step = ceil(nT/9); if (step<1) step=1
    for (kk=1; kk<=nT; kk=kk+step) {
        uu2 = (thmax>thmin ? (thv[kk]-thmin)/(thmax-thmin) : 0)
        px1=uu2*cA;              py1=(uu2*sA)*sE
        px2=uu2*cA+off1*sA;      py2=(uu2*sA-off1*cA)*sE
        tickseg=tickseg+" "+strofreal(py1)+" "+strofreal(px1)+" "+strofreal(py2)+" "+strofreal(px2)
        px2=uu2*cA+off2*sA;      py2=(uu2*sA-off2*cA)*sE
        ticktext=ticktext+" text("+strofreal(py2)+" "+strofreal(px2)+" "+q+strofreal(thv[kk],"%3.2f")+q+", size(vsmall) placement(c))"
    }
    // tau ticks along the front-bottom edge (u=0); labels to the left
    step = ceil(nA/9); if (step<1) step=1
    for (kk=1; kk<=nA; kk=kk+step) {
        vv2 = (taumax>taumin ? (tav[kk]-taumin)/(taumax-taumin) : 0)
        px1=-vv2*sA;             py1=(vv2*cA)*sE
        px2=-off1*cA-vv2*sA;     py2=(-off1*sA+vv2*cA)*sE
        tickseg=tickseg+" "+strofreal(py1)+" "+strofreal(px1)+" "+strofreal(py2)+" "+strofreal(px2)
        px2=-off2*cA-vv2*sA;     py2=(-off2*sA+vv2*cA)*sE
        ticktext=ticktext+" text("+strofreal(py2)+" "+strofreal(px2)+" "+q+strofreal(tav[kk],"%3.2f")+q+", size(vsmall) placement(c))"
    }
    // z (beta) ticks up the left vertical edge at corner (u=0,v=1); labels west
    for (ii=0; ii<=5; ii++) {
        frac = ii/5
        val2 = zmin + frac*(zmax-zmin)
        px1=-sA;                 py1=cA*sE + frac*zscale
        px2=-off1*cA-sA;         py2=py1
        tickseg=tickseg+" "+strofreal(py1)+" "+strofreal(px1)+" "+strofreal(py2)+" "+strofreal(px2)
        px2=-off2*cA-sA
        ticktext=ticktext+" text("+strofreal(py1)+" "+strofreal(px2)+" "+q+strofreal(val2,"%5.2f")+q+", size(vsmall) placement(w))"
    }
    st_local("tickseg",  tickseg)
    st_local("ticktext", ticktext)

    // ---- Axis-title anchor coordinates (outside the tick numbers)
    st_local("thx", strofreal(0.5*cA+0.20*sA));   st_local("thy", strofreal((0.5*sA-0.20*cA)*sE))
    st_local("tax", strofreal(-0.20*cA-0.5*sA));  st_local("tay", strofreal((-0.20*sA+0.5*cA)*sE))
    st_local("zlx", strofreal(-0.18*cA-sA));      st_local("zly", strofreal((-0.18*sA+cA)*sE+1.10*zscale))

    // ---- Colour-bar geometry + value range for labels
    st_local("barX",   strofreal(barX))
    st_local("barTop", strofreal(pymx))
    st_local("barBot", strofreal(pymn))
    st_local("zmin_v", strofreal(zmin))
    st_local("zmax_v", strofreal(zmax))

    // ---- Replace the dataset with the plot points
    stata("clear")
    (void) st_addobs(rows(PX))
    (void) st_addvar("double", ("_px3","_py3","_bkt3","_cb3"))
    st_store(., "_px3",  PX)
    st_store(., "_py3",  PY)
    st_store(., "_bkt3", BKT)
    st_store(., "_cb3",  CB)
}
end
