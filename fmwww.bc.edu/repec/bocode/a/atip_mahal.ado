*! atip_mahal.ado v3.0.0  Andres Talavera  INEI/DNCE  22jul2026
*! Distribuido bajo licencia GPL v3 (https://www.gnu.org/licenses/gpl-3.0.txt)
program define atip_mahal, rclass
    version 14
    syntax varlist(numeric min=2) [if] [in], GROUP(varlist) ///
        [ALPHA(real 0.995) GEN(name) GENDIST(name) CLASSIC SUPPORT(real 0.75) ///
         NSTARTS(integer 20) SEED(integer 12345) GRAPH COMPARE NPOINTS(integer 200)]
    if "`gen'"     == "" local gen "MAHAL_MV"
    if "`gendist'" == "" local gendist "D2_MV"
    marksample touse
    markout `touse' `varlist' `group'
    local nvars : word count `varlist'
    quietly count if `touse'
    if r(N) <= `nvars' {
        di as err "insuficientes observaciones (se necesitan mas de `nvars' con datos completos)"
        exit 2001
    }
    tempvar grp
    quietly egen `grp' = group(`group') if `touse'
    local thresh = invchi2(`nvars', `alpha')
    capture drop `gendist'
    capture drop `gen'
    quietly gen double `gendist' = .
    quietly gen byte `gen' = .
    mata: atip_mahal_run("`varlist'", "`grp'", "`touse'", "`gendist'", ("`classic'"==""), `support', `nstarts', `seed')
    quietly replace `gen' = (`gendist' > `thresh') if `touse' & `gendist'<.
    label variable `gendist' "Distancia de Mahalanobis multivariada (D^2), `nvars' variables"
    label variable `gen' "Outlier multivariado (D2 > chi2(`nvars',`alpha')=`=round(`thresh',0.001)')"
    quietly count if `gendist'>=. & `touse'
    local n_sincalc = r(N)
    quietly count if `gen'==1
    di as text _n "Variables: `varlist'  (k=`nvars')"
    di as text "Umbral chi2(`nvars', `alpha') = " as res %6.3f `thresh'
    di as text "Outliers multivariados detectados: " as res r(N)
    if `n_sincalc' > 0 {
        di as text "Aviso: " as res `n_sincalc' as text " observaciones sin D2 calculado (grupo con muy pocos casos o covarianza singular)"
    }
    return scalar n_outliers = r(N)
    return scalar threshold  = `thresh'
    return scalar nvars      = `nvars'
    if "`graph'" != "" {
        if `nvars' != 2 {
            di as err "la opcion graph solo esta implementada para exactamente 2 variables (k=2); tiene `nvars'"
            exit 198
        }
        mata: atip_mahal_graph("`varlist'", "`grp'", "`touse'", "`gen'", ///
            ("`classic'"==""), `support', `nstarts', `seed', `thresh', `npoints', ("`compare'"!=""))
    }
end
version 14
mata:
void atip_mahal_run(string scalar varlist, string scalar grpvar,
                     string scalar touse, string scalar distvar,
                     real scalar usemcd, real scalar support,
                     real scalar nstarts, real scalar seedopt)
{
    real matrix X, Xg
    real colvector g, D2, idx
    real scalar n, i, ng, ngroups, nvars
    if (seedopt >= 0) rseed(seedopt)
    st_view(X=., ., tokens(varlist), touse)
    st_view(g=., ., grpvar, touse)
    n     = rows(X)
    nvars = cols(X)
    D2    = J(n,1,.)
    ngroups = max(g)
    for (i=1; i<=ngroups; i++) {
        idx = selectindex(g:==i)
        ng  = rows(idx)
        if (ng <= nvars) continue
        Xg = X[idx,.]
        if (usemcd) D2[idx] = mcd_mahalanobis(Xg, support, nstarts)
        else        D2[idx] = clasico_mahalanobis(Xg)
    }
    st_store(., distvar, touse, D2)
}
real colvector clasico_mahalanobis(real matrix Xg)
{
    real matrix ref
    ref = clasico_ref(Xg)
    return(mahal_desde_ref(Xg, ref))
}
real matrix clasico_ref(real matrix Xg)
{
    real rowvector media
    real matrix S
    media = mean(Xg)
    S = variance(Xg)
    if (rank(S) < cols(Xg)) return(J(1,cols(Xg),.) \ J(cols(Xg),cols(Xg),.))
    return(media \ S)
}
real colvector mahal_desde_ref(real matrix Xg, real matrix ref)
{
    real rowvector media
    real matrix S, Sinv
    real colvector D2
    real scalar ng, i, k
    k = cols(Xg)
    media = ref[1,.]
    S = ref[2::(k+1),.]
    ng = rows(Xg)
    if (media[1]==.) return(J(ng,1,.))
    Sinv = invsym(S)
    D2 = J(ng,1,.)
    for (i=1; i<=ng; i++) D2[i] = (Xg[i,.]-media)*Sinv*(Xg[i,.]-media)'
    return(D2)
}
real colvector mcd_mahalanobis(real matrix Xg, real scalar support, real scalar nstarts)
{
    real matrix ref
    ref = mcd_ref(Xg, support, nstarts)
    return(mahal_desde_ref(Xg, ref))
}
real matrix mcd_ref(real matrix Xg, real scalar support, real scalar nstarts)
{
    real scalar ng, k, h, s, iter, maxiter, best_det, det_cur
    real matrix Xh, S_best, S_cur
    real rowvector media_best, media_cur
    real colvector idx_init, dist_all, order_idx, idx_h
    real matrix Sinv
    ng = rows(Xg)
    k  = cols(Xg)
    h  = ceil(ng*support)
    if (h <= k) h = k+1
    maxiter = 15
    best_det = .
    for (s=1; s<=nstarts; s++) {
        idx_init = jumble((1::ng))[1::h]
        Xh = Xg[idx_init,.]
        media_cur = mean(Xh)
        S_cur = variance(Xh)
        if (rank(S_cur) < k) continue
        for (iter=1; iter<=maxiter; iter++) {
            Sinv = invsym(S_cur)
            dist_all = J(ng,1,.)
            for (i=1; i<=ng; i++) {
                dist_all[i] = (Xg[i,.]-media_cur)*Sinv*(Xg[i,.]-media_cur)'
            }
            order_idx = order(dist_all,1)
            idx_h = order_idx[1::h]
            Xh = Xg[idx_h,.]
            media_cur = mean(Xh)
            S_cur = variance(Xh)
            if (rank(S_cur) < k) break
        }
        if (rank(S_cur) < k) continue
        det_cur = det(S_cur)
        if (best_det==. | det_cur < best_det) {
            best_det = det_cur
            media_best = media_cur
            S_best = S_cur
        }
    }
    if (best_det==.) return(clasico_ref(Xg))
    real scalar frac, c_factor
    frac = h/ng
    c_factor = frac / chi2(k+2, invchi2(k,frac))
    S_best = S_best * c_factor
    return(media_best \ S_best)
}
void atip_mahal_graph(string scalar varlist, string scalar grpvar,
                       string scalar touse, string scalar genflag,
                       real scalar usemcd, real scalar support,
                       real scalar nstarts, real scalar seedopt,
                       real scalar thresh, real scalar npoints,
                       real scalar docompare)
{
    real matrix X, Xg, refC, refM, S, eigvec
    real colvector g, flag, idx, eigval, theta
    real rowvector media
    real scalar n, i, ng, ngroups, metodo
    real matrix ellx, elly, grpid_ell, met_ell, allx, ally, allgrp, allflag
    real matrix cenx, ceny, cengrp, cenmet
    string scalar cmd, note1
    string rowvector varnames
    varnames = tokens(varlist)
    if (seedopt >= 0) rseed(seedopt)
    st_view(X=., ., varnames, touse)
    st_view(g=., ., grpvar, touse)
    st_view(flag=., ., genflag, touse)
    n = rows(X)
    ngroups = max(g)
    allx = J(0,1,.); ally = J(0,1,.); allgrp = J(0,1,.); allflag = J(0,1,.)
    ellx = J(0,1,.); elly = J(0,1,.); grpid_ell = J(0,1,.); met_ell = J(0,1,.)
    cenx = J(0,1,.); ceny = J(0,1,.); cengrp = J(0,1,.); cenmet = J(0,1,.)
    theta = rangen(0, 2*pi(), npoints)
    for (i=1; i<=ngroups; i++) {
        idx = selectindex(g:==i)
        ng  = rows(idx)
        if (ng <= cols(X)) continue
        Xg = X[idx,.]
        allx = allx \ Xg[.,1]
        ally = ally \ Xg[.,2]
        allgrp = allgrp \ J(ng,1,i)
        allflag = allflag \ flag[idx]
        for (metodo=1; metodo<=(docompare ? 2 : 1); metodo++) {
            real scalar es_mcd_este
            es_mcd_este = (metodo==1 ? usemcd : !usemcd)
            if (es_mcd_este) refM = mcd_ref(Xg, support, nstarts)
            else             refM = clasico_ref(Xg)
            media = refM[1,.]
            if (media[1]==.) continue
            S = refM[2::3,.]
            symeigensystem(S, eigvec=., eigval=.)
            if (min(eigval) <= 0) continue
            real matrix circ, scaled, pts
            circ = (cos(theta), sin(theta))
            scaled = circ * diag(sqrt(thresh:*eigval))
            pts = scaled * eigvec' :+ media
            ellx = ellx \ pts[.,1]
            elly = elly \ pts[.,2]
            grpid_ell = grpid_ell \ J(npoints,1,i)
            met_ell = met_ell \ J(npoints,1,metodo)
            cenx = cenx \ media[1]
            ceny = ceny \ media[2]
            cengrp = cengrp \ i
            cenmet = cenmet \ metodo
        }
    }
    stata("preserve")
    stata("clear")
    stata("set obs " + strofreal(rows(allx) + rows(ellx) + rows(cenx)))
    (void) st_addvar("double", "gx")
    (void) st_addvar("double", "gy")
    (void) st_addvar("double", "ggrp")
    (void) st_addvar("byte",   "gflag")
    (void) st_addvar("byte",   "gtipo")
    (void) st_addvar("byte",   "gmet")
    real scalar r0, r1
    r0 = rows(allx)
    r1 = rows(ellx)
    st_store((1::r0), ("gx","gy","ggrp","gflag","gtipo","gmet"),
             (allx, ally, allgrp, allflag, J(r0,1,2), J(r0,1,1)))
    st_store((r0+1::r0+r1), ("gx","gy","ggrp","gtipo","gmet"),
             (ellx, elly, grpid_ell, J(r1,1,1), met_ell))
    st_store((r0+r1+1::r0+r1+rows(cenx)), ("gx","gy","ggrp","gtipo","gmet"),
             (cenx, ceny, cengrp, J(rows(cenx),1,0), cenmet))
    stata("quietly replace gflag=0 if gflag>=. & gtipo!=2")
    note1 = sprintf(`"note("Elipse: umbral chi2(2)=%9.3f")"', thresh)
    cmd = `"twoway (scatter gy gx if gtipo==2 & gflag==0, mcolor(gs8%55) msize(small)) "' +
          `"(scatter gy gx if gtipo==2 & gflag==1, mcolor(red) msize(medsmall)) "'
    for (i=1; i<=ngroups; i++) {
        cmd = cmd + sprintf(`"(line gy gx if gtipo==1 & ggrp==%g & gmet==1, lcolor(gs6) lpattern(dash) lwidth(medthick)) "', i)
        if (docompare) {
            cmd = cmd + sprintf(`"(line gy gx if gtipo==1 & ggrp==%g & gmet==2, lcolor(orange) lpattern(shortdash) lwidth(medthick)) "', i)
        }
    }
    cmd = cmd + `"(scatter gy gx if gtipo==0 & gmet==1, mcolor(gs2) msymbol(D) msize(medium)) "'
    if (docompare) {
        cmd = cmd + `"(scatter gy gx if gtipo==0 & gmet==2, mcolor(orange) msymbol(D) msize(medium)) "'
    }
    if (docompare) {
        cmd = cmd + `", "' +
              sprintf(`"legend(order(1 "No outlier" 2 "Outlier" 3 "Elipse %s" 4 "Elipse %s" 5 "Centroide %s" 6 "Centroide %s") pos(6) rows(2)) "', ///
                      (usemcd ? "MCD" : "clasica"), (usemcd ? "clasica" : "MCD"), ///
                      (usemcd ? "MCD" : "clasica"), (usemcd ? "clasica" : "MCD"))
    }
    else {
        cmd = cmd + `", "' +
              sprintf(`"legend(order(1 "No outlier" 2 "Outlier" 3 "Elipse (%s)" 4 "Centroide") pos(6) rows(1)) "', (usemcd ? "MCD" : "clasica"))
    }
    cmd = cmd + sprintf(`"xtitle("%s") ytitle("%s") "', varnames[1], varnames[2]) +
          `"title("Elipse de tolerancia -- Mahalanobis multivariado") "' + note1
    stata(cmd)
    stata("restore")
}
end
