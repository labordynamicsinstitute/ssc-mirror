*! mmd_2s.ado v3.0 - 26jul2026
*! Two-sample Maximum Mean Discrepancy (MMD) test, peso OPCIONAL
*! FUSION de mmd_2s.ado (v1.0, no ponderado) + mmd_2s_pond.ado (v2.0-beta,
*! ponderado) en un solo archivo -- mismo patron que kstest.ado: el peso
*! se especifica con la sintaxis NATIVA de Stata [pweight/aweight/iweight],
*! no con una opcion propia. Sin peso, se genera w=1 para todos, y el
*! resultado es identico (a precision de maquina) a como se comportaba
*! mmd_2s.ado v1.0 -- ya no hace falta un .do aparte para validar que las
*! dos versiones "coinciden", porque ahora es UN SOLO codigo.
*!
*! Cambios de diseño respecto a los dos archivos anteriores:
*!   1) Un solo programa, un solo set de funciones Mata (antes habia
*!      mmd_fast/mmd_fast_mk/mmd_sigma_median sin peso Y
*!      fast_mmd_pond/fast_mk_mmd_pond/mmd_sigma_median_pond ponderados,
*!      duplicados).
*!   2) Guarda explicita de missing() en by() (y en el peso), igual que
*!      kstest -- antes, un by() o wt() con missing podia colarse en la
*!      muestra sin excluirse solo (marksample NO revisa por defecto
*!      variables pasadas como opcion, solo el varlist principal).
*!   3) Correccion "+1" en el p-valor (Davison & Hinkley): antes
*!      mean(boot>=stat) podia dar exactamente 0; ahora (count+1)/(B+1),
*!      igual que kstest -- el piso de resolucion 1/(B+1) queda
*!      incorporado en la formula misma, no solo manejado aparte en
*!      mmd_volcano.ado.
*!
*! Distribuido bajo licencia GPL v3 (https://www.gnu.org/licenses/gpl-3.0.txt)
*!
*! Kernel: RBF (gaussiano), multi-kernel promedio sobre sigma/2, sigma, 2*sigma
*! sigma: heuristica de mediana de distancias pareadas (submuestra <=2000,
*!        ponderada via Efraimidis-Spirakis sin reemplazo si hay peso)
*! p-valor: bootstrap con reemplazo del pool (H0), B replicas (default 200)
*! neff: tamaño efectivo de Kish (Monahan 2011, eq. 12.4.5) -- con peso=1
*!       para todos, neff se reduce exactamente al N crudo.

program define mmd_2s, rclass
    version 14
    syntax varname(numeric) [pweight aweight iweight] [if] [in], BY(varname numeric) ///
        [BOOT(integer 200) REPS(integer 1) SEED(integer -1) BOXPLOT ///
         KDENSITY BW(real 0) NPOINTS(integer 200)]

    tempvar touse
    marksample touse, novarlist
    markout `touse' `varlist'
    // guarda explicita para by() -- marksample NO revisa por defecto una
    // variable pasada como opcion (solo el varlist principal), asi que
    // sin esta linea un by() con missing podia colarse en la muestra
    // (mismo fix que ya usa kstest.ado)
    qui replace `touse' = 0 if missing(`by')

    if `reps' < 1 {
        di as err "reps() debe ser >= 1"
        exit 198
    }

    // peso OPCIONAL via sintaxis nativa de Stata -- si no se especifica
    // ningun [weight], w=1 para todos y el resultado coincide exactamente
    // con la version no ponderada anterior
    tempvar w
    local hasweight = ("`weight'" != "")
    if `hasweight' {
        local wexp = trim(`"`exp'"')
        if substr(`"`wexp'"', 1, 1) == "=" {
            local wexp = trim(substr(`"`wexp'"', 2, .))
        }
        quietly gen double `w' = `wexp' if `touse'
        quietly replace `touse' = 0 if `touse' & (`w' <= 0 | missing(`w'))
    }
    else {
        quietly gen double `w' = 1 if `touse'
    }

    quietly count if `touse'
    if r(N) < 20 {
        di as err "insuficientes observaciones (minimo 20 en total, tras excluir missing/peso<=0)"
        exit 2001
    }

    mata: mmd_2s_run("`varlist'", "`by'", "`w'", "`touse'", `boot', `reps', `seed')

    return scalar mmd_stat      = r(mmd_stat)
    return scalar mmd_stat_sd   = r(mmd_stat_sd)
    return scalar mmd_stat_cv   = r(mmd_stat_cv)
    return scalar mmd_stat_cv_se = r(mmd_stat_cv_se)
    return scalar mmd_boot_mean = r(mmd_boot_mean)
    return scalar p_boot        = r(p_boot)
    return scalar effect_size   = r(effect_size)
    return scalar nA            = r(nA)
    return scalar nB            = r(nB)
    return scalar neff_A        = r(neff_A)
    return scalar neff_B        = r(neff_B)
    return scalar sigma         = r(sigma)
    return scalar N_boot        = `boot'
    return scalar N_reps        = `reps'
    return local  weighted      = cond(`hasweight', "yes", "no")

    if "`boxplot'" != "" {
        local stat_f : display %9.6f r(mmd_stat)
        local pv_f   : display %9.4f r(p_boot)
        local es_f   : display %9.4f r(effect_size)
        local nfA_f  : display %9.1f r(neff_A)
        local nfB_f  : display %9.1f r(neff_B)
        local gtitle "Distribucion de `varlist' por `by'"
        if `hasweight' local gtitle "`gtitle' (grafico NO ponderado)"
        * mismo contenido y formato de anotacion que usa kdensity (linea
        * 397 mas abajo) -- antes este note() mezclaba texto entre comillas
        * con codigos de formato tipo "display" (%6.1f r(neff_A)), que NO
        * es sintaxis valida para note() y por eso salia mal
        graph box `varlist' if `touse', over(`by') ///
            title("`gtitle'") ///
            note("MMD_STAT=`stat_f'   p_boot(B=`boot')=`pv_f'   effect size=`es_f'" ///
                 "neffA=`nfA_f'  neffB=`nfB_f'  reps=`reps'") ///
            ytitle("`varlist'")
    }

    if "`kdensity'" != "" {
        mata: mmd_kde_graph("`varlist'", "`by'", "`w'", "`touse'", `=r(sigma)', `bw', `npoints', ///
            `=r(mmd_stat)', `=r(p_boot)', `=r(effect_size)', `=r(neff_A)', `=r(neff_B)', `boot', `reps')
    }
end

version 14
mata:
mata clear

real scalar n_efectivo(real colvector w)
{
    // Kish effective sample size (Monahan 2011, eq. 12.4.5). Con w=1
    // para todos: sum(w)^2/sum(w^2) = n^2/n = n -- se reduce al N crudo.
    real colvector ww
    ww = select(w, (w:<. :& w:>0))
    if (rows(ww)==0) return(0)
    return(sum(ww)^2 / sum(ww:^2))
}

real scalar mmd_median_p(real colvector v)
{
    real scalar n
    real colvector s
    n = rows(v)
    s = sort(v,1)
    if (mod(n,2)==1) return(s[(n+1)/2])
    else             return((s[n/2]+s[n/2+1])/2)
}

real colvector wsample_norepl(real colvector w, real scalar k)
{
    // Efraimidis-Spirakis: muestreo ponderado SIN reemplazo. Con w
    // constante, key = runiform()^(1/w) = runiform() para todos, por lo
    // que esto se reduce a una permutacion uniforme (igual que jumble()),
    // consistente con el caso sin peso.
    real matrix M
    real scalar n
    n = rows(w)
    M = (runiform(n,1):^(1:/w), (1::n))
    M = sort(M, -1)
    return(M[1::k,2])
}

real scalar mmd_sigma_median(real colvector x, real colvector w)
{
    // Con n<=2000 (caso tipico) el resultado no depende de los pesos en
    // absoluto -- se usan TODOS los pares, ponderar la eleccion de
    // submuestra no aplica.
    real colvector xx, idx, d
    real scalar n, i, j, k, npairs

    xx = x
    n  = rows(xx)
    if (n > 2000) {
        idx = wsample_norepl(w, 2000)
        xx  = xx[idx]
        n   = 2000
    }
    if (n < 10) return(.)
    npairs = n*(n-1)/2
    d = J(npairs,1,.)
    k = 1
    for (i=1; i<=n-1; i++) {
        for (j=i+1; j<=n; j++) {
            d[k] = abs(xx[i]-xx[j])
            k++
        }
    }
    return(mmd_median_p(d))
}

real scalar fast_mmd(real colvector x, real colvector y, real scalar sigma,
                      real colvector wx, real colvector wy, real scalar m)
{
    // Estimador rapido/lineal de MMD por pares aleatorios (Gretton).
    // El peso entra SOLO como promedio ponderado del kernel h por PAR,
    // no como normalizador separado por grupo (ver comparacion con
    // kstest en la conversacion: son diseños distintos, ambos validos).
    // Con wx=wy=1, w_par=1 para todos los pares y esto se reduce
    // EXACTAMENTE a mean(h).
    //
    // "m" (mitad del numero de pares) se recibe YA CALCULADO desde
    // fast_mk_mmd -- antes se recalculaba neff_x/neff_y/m ADENTRO de
    // esta funcion, y como fast_mk_mmd la llama 3 veces (sigma/2, sigma,
    // 2*sigma) con los MISMOS pesos, eso repetia el mismo calculo 3
    // veces de mas. Medido en Python (misma logica, ver
    // comparar_tiempo_mmd.py): ~19% mas rapido sacandolo de aca.
    real scalar gamma, sw_par, val
    real colvector idxx, idxy, xs, ys, wxs, wys
    real colvector x1,x2,y1,y2,wx1,wx2,wy1,wy2,h,w_par

    if (m < 1 | sigma <= 0) return(.)

    gamma = 1/(2*sigma^2)

    // la eleccion de QUIENES entran al par es uniforme (jumble), no
    // ponderada -- el peso solo determina CUANTO cuenta cada par elegido
    idxx = jumble((1::rows(x))); idxx = idxx[1::2*m]
    idxy = jumble((1::rows(y))); idxy = idxy[1::2*m]

    xs = x[idxx]; wxs = wx[idxx]
    ys = y[idxy]; wys = wy[idxy]

    x1 = xs[1::m];   x2 = xs[(m+1)::(2*m)]
    y1 = ys[1::m];   y2 = ys[(m+1)::(2*m)]
    wx1 = wxs[1::m]; wx2 = wxs[(m+1)::(2*m)]
    wy1 = wys[1::m]; wy2 = wys[(m+1)::(2*m)]

    h = exp(-gamma:*(x1:-x2):^2) :+ exp(-gamma:*(y1:-y2):^2) ///
        :- exp(-gamma:*(x1:-y2):^2) :- exp(-gamma:*(x2:-y1):^2)

    w_par  = (wx1:*wx2 :+ wy1:*wy2) :/ 2
    sw_par = sum(w_par)
    if (sw_par == 0) return(.)
    val = sum(h:*w_par)/sw_par

    return(max((val,0)))   // clip a 0 -- MMD^2 teorico nunca es negativo
}

real scalar fast_mk_mmd(real colvector x, real colvector y, real scalar sigma,
                         real colvector wx, real colvector wy)
{
    // multi-kernel: promedio sobre 3 anchos de banda distintos.
    // neff/m dependen SOLO de los pesos (no de sigma) -- se calculan
    // una sola vez aca, no dentro de fast_mmd (ver nota ahi).
    real scalar v1, v2, v3, m
    m = floor(min((n_efectivo(wx), n_efectivo(wy)))/2)
    v1 = fast_mmd(x, y, sigma/2, wx, wy, m)
    v2 = fast_mmd(x, y, sigma,   wx, wy, m)
    v3 = fast_mmd(x, y, sigma*2, wx, wy, m)
    return((v1+v2+v3)/3)
}

void mmd_2s_run(string scalar varname, string scalar byname, string scalar wtname,
                 string scalar touse, real scalar B, real scalar REPS, real scalar seedopt)
{
    real colvector v, g, w, x, y, wx, wy, pooled_v, pooled_w, idx
    real colvector bx, bwx, byv, bwy, mmdboot, statreps, uniq, btmp
    real scalar nA, nB, ntot, sigma, stat, statsd, statcv, statcv_se
    real scalar neffA, neffB, i, j, pv, mn, count_ge

    if (seedopt >= 0) rseed(seedopt)

    st_view(v=., ., varname, touse)
    st_view(g=., ., byname,  touse)
    st_view(w=., ., wtname,  touse)

    uniq = uniqrows(g)
    if (rows(uniq) != 2) {
        printf("{err}la variable by() debe tener exactamente 2 valores distintos\n")
        exit(198)
    }

    x  = select(v, g:==uniq[1]); wx = select(w, g:==uniq[1])
    y  = select(v, g:==uniq[2]); wy = select(w, g:==uniq[2])
    nA = rows(x); nB = rows(y)

    neffA = n_efectivo(wx)
    neffB = n_efectivo(wy)

    sigma = mmd_sigma_median(v, w)
    if (sigma == . | sigma == 0) {
        printf("{err}no fue posible calcular sigma (datos insuficientes o varianza nula)\n")
        exit(198)
    }

    // estadistico observado: promedio de REPS llamadas independientes
    statreps = J(REPS,1,.)
    for (i=1; i<=REPS; i++) statreps[i] = fast_mk_mmd(x, y, sigma, wx, wy)
    statreps = select(statreps, statreps:<.)
    if (rows(statreps)==0) {
        printf("{err}neff insuficiente (m<1): neff_A=%9.2f  neff_B=%9.2f\n", neffA, neffB)
        exit(198)
    }
    stat   = mean(statreps)
    statsd = (REPS>1 ? sqrt(variance(statreps)) : .)
    statcv = (REPS>1 & stat!=0 ? statsd/stat : .)
    statcv_se = (REPS>1 & stat!=0 ? statcv/sqrt(REPS) : .)

    // bootstrap CON reemplazo del pool -- cada replica se promedia sobre
    // REPS corridas igual que el estadistico observado (fix critico
    // validado por simulacion: si no, el bootstrap queda con mas
    // varianza que "stat" y el test se sesga a NO rechazar)
    pooled_v = x \ y
    pooled_w = wx \ wy
    ntot     = nA + nB

    mmdboot = J(B,1,.)
    for (i=1; i<=B; i++) {
        idx  = ceil(ntot*runiform(ntot,1))
        bx   = pooled_v[idx[1::nA]];       bwx = pooled_w[idx[1::nA]]
        byv  = pooled_v[idx[(nA+1)::ntot]]; bwy = pooled_w[idx[(nA+1)::ntot]]
        if (REPS>1) {
            btmp = J(REPS,1,.)
            for (j=1; j<=REPS; j++) btmp[j] = fast_mk_mmd(bx, byv, sigma, bwx, bwy)
            mmdboot[i] = mean(btmp)
        }
        else {
            mmdboot[i] = fast_mk_mmd(bx, byv, sigma, bwx, bwy)
        }
    }

    // p-valor con correccion "+1" (Davison & Hinkley) -- igual que
    // kstest.ado. Nunca da exactamente 0; el piso de resolucion
    // 1/(B+1) queda incorporado en la formula misma.
    count_ge = sum(mmdboot :>= stat)
    pv = (count_ge + 1) / (B + 1)
    mn = mean(mmdboot)

    st_numscalar("r(mmd_stat)",      stat)
    st_numscalar("r(mmd_stat_sd)",   statsd)
    st_numscalar("r(mmd_stat_cv)",    statcv)
    st_numscalar("r(mmd_stat_cv_se)", statcv_se)
    st_numscalar("r(mmd_boot_mean)", mn)
    st_numscalar("r(p_boot)",        pv)
    st_numscalar("r(effect_size)",   stat/mn)
    st_numscalar("r(nA)",            nA)
    st_numscalar("r(nB)",            nB)
    st_numscalar("r(neff_A)",        neffA)
    st_numscalar("r(neff_B)",        neffB)
    st_numscalar("r(sigma)",         sigma)

    printf("\n{title:MMD - test de dos muestras}\n")
    printf("{txt}Variable: {res}%s{txt}   By: {res}%s\n", varname, byname)
    printf("{txt}Grupo A: n=%g  neff=%9.2f\n", nA, neffA)
    printf("{txt}Grupo B: n=%g  neff=%9.2f\n", nB, neffB)
    printf("{txt}sigma (heuristica mediana):      {res}%9.6f\n", sigma)
    if (REPS>1) {
        printf("{txt}MMD estadistico observado (media de %g reps): {res}%9.6f\n", REPS, stat)
        printf("{txt}  dispersion de una corrida individual (cv_draw):  {res}%6.1f%%{txt}  -- no baja con reps()\n", statcv*100)
        printf("{txt}  error estandar del promedio reportado (cv_se):  {res}%6.1f%%{txt}  -- SI baja con reps() (=cv_draw/sqrt(reps))\n", statcv_se*100)
        if (statcv_se > 0.20) {
            printf("{txt}{err}   AVISO: cv_se>20%%, el promedio reportado aun es impreciso -- suba reps()\n")
        }
    }
    else printf("{txt}MMD estadistico observado:      {res}%9.6f\n", stat)
    printf("{txt}MMD bootstrap (media, B=%g):    {res}%9.6f\n", B, mn)
    printf("{txt}p-valor (bootstrap, +1 correccion):  {res}%9.4f\n", pv)
    printf("{txt}Effect size (stat/boot_mean):   {res}%9.4f\n", stat/mn)
    printf("\n")
}

void mmd_kde_graph(string scalar varname, string scalar byname, string scalar wtname,
                    string scalar touse, real scalar sigma, real scalar bwopt,
                    real scalar npoints, real scalar stat, real scalar pv, real scalar es,
                    real scalar neffA, real scalar neffB, real scalar Nboot, real scalar Nreps)
{
    // Densidad kernel gaussiana (KDE) por grupo, ponderada. Con peso=1
    // para todos se reduce exactamente al KDE simple.
    real colvector v, g, w, x, y, wx, wy, uniq, grid, dx, dy
    real scalar bw, i, gmin, gmax, pad, swx, swy
    string scalar note1, cmd

    st_view(v=., ., varname, touse)
    st_view(g=., ., byname,  touse)
    st_view(w=., ., wtname,  touse)

    uniq = uniqrows(g)
    x  = select(v, g:==uniq[1]); wx = select(w, g:==uniq[1])
    y  = select(v, g:==uniq[2]); wy = select(w, g:==uniq[2])
    swx = sum(wx); swy = sum(wy)

    bw = (bwopt > 0 ? bwopt : sigma)
    if (bw <= 0 | swx==0 | swy==0) {
        printf("{err}bandwidth o pesos invalidos para kdensity\n")
        exit(198)
    }

    gmin = min(v); gmax = max(v)
    pad  = bw
    grid = rangen(gmin-pad, gmax+pad, npoints)

    dx = J(npoints,1,.)
    dy = J(npoints,1,.)
    for (i=1; i<=npoints; i++) {
        dx[i] = sum(wx:*normalden((grid[i]:-x):/bw)) / (bw*swx)
        dy[i] = sum(wy:*normalden((grid[i]:-y):/bw)) / (bw*swy)
    }

    stata("preserve")
    stata("clear")
    stata("quietly set obs " + strofreal(npoints))
    (void) st_addvar("double", "grid")
    (void) st_addvar("double", "dens_g1")
    (void) st_addvar("double", "dens_g2")
    st_store(., "grid",    grid)
    st_store(., "dens_g1", dx)
    st_store(., "dens_g2", dy)

    note1 = sprintf(`"note("MMD_STAT=%9.6f   p_boot(B=%g)=%9.4f   effect size=%9.4f" "neff1=%9.1f  neff2=%9.1f  reps=%g  bw=%9.4f")"', ///
                     stat, Nboot, pv, es, neffA, neffB, Nreps, bw)

    cmd = `"twoway (line dens_g1 grid, lcolor(blue) lwidth(medthick)) "' +
          `"(line dens_g2 grid, lcolor(red) lwidth(medthick)), "' +
          sprintf(`"legend(order(1 "%s=%g" 2 "%s=%g")) "', byname, uniq[1], byname, uniq[2]) +
          sprintf(`"title("Densidad de %s por %s (KDE, bw ligado al test MMD)") "', varname, byname) +
          "ytitle(Densidad) " + sprintf(`"xtitle("%s")"', varname) + " " + note1

    stata(cmd)
    stata("restore")
}
end
