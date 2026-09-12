*! calibra.ado - Calibracion de pesos muestrales / estimador GREG
*! Metodo de Deville y Sarndal (1992), JASA 87(418):376-382
*! version 1.0.0  10sep2026
*! Uso previsto: encuestas de hogares y agropecuarias (ENAHO, ENA - INEI Peru)

program define calibra, rclass
    version 14

    syntax varlist(numeric) [if] [in] [pweight] , ///
        GENerate(name) TOTals(numlist) ///
        [ METHod(string) BOunds(numlist min=2 max=2) ///
          TOLerance(real 1e-6) ITERate(integer 100) NOGRaph ]

    marksample touse
    markout `touse' `varlist'

    * --------------------------------------------------------------
    * peso de diseno (obligatorio, tipo pweight)
    * --------------------------------------------------------------
    if "`weight'" == "" {
        display as error "calibra requiere especificar el peso de diseno como [pweight=variable]"
        exit 198
    }
    if "`weight'" != "pweight" {
        display as error "calibra solo admite pesos de tipo pweight"
        exit 198
    }
    tempvar dwgt
    quietly generate double `dwgt' `exp'
    markout `touse' `dwgt'

    quietly count if `dwgt' <= 0 & `touse'
    if r(N) > 0 {
        display as error "el peso de diseno (pweight) debe ser estrictamente positivo en toda la muestra"
        exit 198
    }

    quietly count if `touse'
    if r(N) == 0 {
        display as error "no hay observaciones para calibrar (revise if/in y valores faltantes)"
        exit 2000
    }

    * --------------------------------------------------------------
    * metodo
    * --------------------------------------------------------------
    if "`method'" == "" local method "linear"
    local method = lower("`method'")
    if !inlist("`method'","linear","raking","logit") {
        display as error "method() debe ser linear, raking o logit"
        exit 198
    }

    * --------------------------------------------------------------
    * limites (bounds)
    * --------------------------------------------------------------
    local haslimits = ("`bounds'" != "")
    if "`method'" == "logit" & !`haslimits' {
        display as error "el metodo logit requiere bounds(L U), con L < 1 < U"
        exit 198
    }
    local Lb 0
    local Ub 0
    if `haslimits' {
        tokenize `bounds'
        local Lb `1'
        local Ub `2'
        if (`Lb' >= 1) | (`Ub' <= 1) {
            display as error "bounds(L U) debe cumplir L < 1 < U"
            exit 198
        }
    }

    * --------------------------------------------------------------
    * totales poblacionales: uno por cada variable auxiliar
    * --------------------------------------------------------------
    local nT : word count `totals'
    local nV : word count `varlist'
    if `nT' != `nV' {
        display as error "el numero de totales especificados en totals() (`nT') no coincide con el numero de variables auxiliares en varlist (`nV')"
        exit 198
    }

    tempname Tvec
    matrix `Tvec' = J(1,`nV',0)
    local i = 1
    foreach t of local totals {
        matrix `Tvec'[1,`i'] = `t'
        local ++i
    }

    * --------------------------------------------------------------
    * variable de salida
    * --------------------------------------------------------------
    confirm new variable `generate'
    quietly generate double `generate' = .

    * --------------------------------------------------------------
    * motor Mata
    * --------------------------------------------------------------
    mata: calibra_engine("`varlist'", "`dwgt'", "`touse'", "`generate'", ///
                          st_matrix("`Tvec'"), "`method'", `haslimits', ///
                          `Lb', `Ub', `tolerance', `iterate')

    * --------------------------------------------------------------
    * recuperar resultados desde Mata
    * --------------------------------------------------------------
    local conv  = __calibra_conv
    local iterN = __calibra_iter
    local ntrim = __calibra_ntrim
    local gmin  = __calibra_gmin
    local gmax  = __calibra_gmax
    local nn    = __calibra_n

    tempname Tantes Tdespues tabla
    matrix `Tantes'   = __calibra_Tdhat
    matrix `Tdespues' = __calibra_Tw

    capture matrix drop __calibra_Tdhat __calibra_Tw
    capture scalar drop __calibra_conv __calibra_iter __calibra_ntrim ///
                        __calibra_gmin __calibra_gmax __calibra_n

    if ("`method'" != "linear") & (`conv' == 0) {
        display as error "AVISO: el algoritmo no convergio en `iterate' iteraciones (tolerance=`tolerance')."
        if "`method'" == "logit" {
            display as error "Con method(logit), la no convergencia suele indicar que bounds(`Lb' `Ub') es demasiado estrecho para alcanzar los totales pedidos: pruebe primero method(linear) o method(raking) sin limites para ver que rango de g=w/d se necesita, y elija bounds() que lo cubra."
        }
        else {
            display as error "Revise iterate()/tolerance() o la escala de las variables auxiliares."
        }
    }

    * --------------------------------------------------------------
    * reporte
    * --------------------------------------------------------------
    display as text _newline "Calibracion de pesos muestrales (Deville-Sarndal, 1992)"
    display as text "{hline 62}"
    display as text "Metodo:              " as result "`method'"
    display as text "Variables auxiliares:" as result " `varlist'"
    display as text "Peso de diseno:      " as result "`dwgt'" _continue
    display as text "   Observaciones: " as result `nn'
    if "`method'" != "linear" {
        display as text "Iteraciones:         " as result `iterN'
        display as text "Convergencia:        " as result cond(`conv'==1,"si","NO")
    }
    if `haslimits' {
        display as text "Limites g=w/d (L,U): " as result "(`Lb' , `Ub')"
        display as text "Pesos recortados:    " as result `ntrim'
    }
    display as text "Rango factor g=w/d:  " as result %9.4f `gmin' as text " a " as result %9.4f `gmax'
    display as text "{hline 62}"
    display as text "Totales poblacionales: objetivo vs. estimado antes/despues de calibrar"

    matrix `tabla' = `Tvec'' , `Tantes' , `Tdespues'
    matrix colnames `tabla' = objetivo antes_de_calibrar despues_de_calibrar
    matrix rownames `tabla' = `varlist'
    matlist `tabla', border(top bottom) format(%14.2f) twidth(20)

    * --------------------------------------------------------------
    * grafico del factor de ajuste
    * --------------------------------------------------------------
    if "`nograph'" == "" {
        tempvar gfactor
        quietly generate double `gfactor' = `generate'/`dwgt' if `touse'
        quietly histogram `gfactor' if `touse', ///
            title("Distribucion del factor de ajuste g = w{sub:k}/d{sub:k}") ///
            xtitle("g") name(calibra_g, replace)
    }

    * --------------------------------------------------------------
    * resultados r()
    * --------------------------------------------------------------
    return scalar converged = `conv'
    return scalar iter      = `iterN'
    return scalar ntrimmed  = `ntrim'
    return scalar gmin      = `gmin'
    return scalar gmax      = `gmax'
    return scalar N         = `nn'
    return local  method    "`method'"
    return local  generate  "`generate'"
    return matrix totals_target `Tvec'
    return matrix totals_before `Tantes'
    return matrix totals_after  `Tdespues'

end

* ====================================================================
* Motor de calculo en Mata
* ====================================================================

capture mata: mata drop calibra_linear()
capture mata: mata drop calibra_raking()
capture mata: mata drop calibra_logit()
capture mata: mata drop calibra_engine()

mata:

// --------------------------------------------------------------
// 1. Metodo lineal (distancia ji-cuadrado). Solucion cerrada.
//    g = 1 + X*lambda ,  lambda = (X'DX)^{-1} (T - X'd)
// --------------------------------------------------------------
real colvector calibra_linear(real matrix X, real colvector d, real colvector T)
{
    real matrix    XtDX
    real colvector Tdhat, lambda, g

    XtDX   = cross(X, d, X)
    Tdhat  = cross(X, d)
    lambda = invsym(XtDX) * (T - Tdhat)
    g      = 1 :+ X * lambda
    return(g)
}

// --------------------------------------------------------------
// 2. Raking (razon exponencial). Newton-Raphson.
//    g = exp(X*lambda) ; resuelve sum d*x*exp(x'lambda) = T
// --------------------------------------------------------------
real colvector calibra_raking(real matrix X, real colvector d, real colvector T,
                               real scalar tol, real scalar maxiter,
                               real scalar iterused, real scalar converged)
{
    real scalar    p, it
    real colvector lambda, g, phi, delta, u
    real matrix    Jmat

    p         = cols(X)
    lambda    = J(p,1,0)
    converged = 0
    it        = 0

    for (it=1; it<=maxiter; it++) {
        u   = X*lambda
        u   = rowmax((u, J(rows(u),1,-700)))
        u   = rowmin((u, J(rows(u),1, 700)))
        g   = exp(u)
        phi = cross(X, d:*g) - T
        if (max(abs(phi)) < tol) {
            converged = 1
            break
        }
        Jmat  = cross(X, d:*g, X)
        delta = invsym(Jmat) * phi
        lambda = lambda - delta
    }
    iterused = min((it, maxiter))
    u = X*lambda
    u = rowmax((u, J(rows(u),1,-700)))
    u = rowmin((u, J(rows(u),1, 700)))
    g = exp(u)
    return(g)
}

// --------------------------------------------------------------
// 3. Logistico acotado (Deville-Sarndal), g en [L,U]
// --------------------------------------------------------------
real colvector calibra_logit(real matrix X, real colvector d, real colvector T,
                              real scalar L, real scalar U,
                              real scalar tol, real scalar maxiter,
                              real scalar iterused, real scalar converged)
{
    real scalar    p, it, cc
    real colvector lambda, u, ee, num, den, g, gp, phi, delta
    real matrix    Jmat

    p         = cols(X)
    lambda    = J(p,1,0)
    cc        = (U-L)/((1-L)*(U-1))
    converged = 0
    it        = 0

    for (it=1; it<=maxiter; it++) {
        u   = X*lambda
        u   = cc:*u
        u   = rowmax((u, J(rows(u),1,-700)))
        u   = rowmin((u, J(rows(u),1, 700)))
        ee  = exp(u)
        num = L*(U-1) :+ U*(1-L):*ee
        den = (U-1)   :+ (1-L):*ee
        g   = num:/den
        phi = cross(X, d:*g) - T
        if (max(abs(phi)) < tol) {
            converged = 1
            break
        }
        gp    = cc*(1-L)*(U-1)*(U-L):*ee :/ den:^2
        Jmat  = cross(X, d:*gp, X)
        delta = invsym(Jmat)*phi
        lambda = lambda - delta
    }
    iterused = min((it, maxiter))

    u   = X*lambda
    u   = cc:*u
    u   = rowmax((u, J(rows(u),1,-700)))
    u   = rowmin((u, J(rows(u),1, 700)))
    ee  = exp(u)
    num = L*(U-1) :+ U*(1-L):*ee
    den = (U-1)   :+ (1-L):*ee
    g   = num:/den
    return(g)
}

// --------------------------------------------------------------
// Motor principal: lee datos de Stata, despacha por metodo,
// aplica recorte (bounds) cuando corresponde, escribe el peso
// calibrado de vuelta en Stata y deja escalares/matrices
// temporales para que el .ado arme el reporte y return().
// --------------------------------------------------------------
void calibra_engine(string scalar varlist, string scalar wgtvar,
                     string scalar touse, string scalar newwgt,
                     real rowvector T0, string scalar method,
                     real scalar haslimits, real scalar L, real scalar U,
                     real scalar tol, real scalar maxiter)
{
    real matrix    X
    real colvector d, T, g, w, Tdhat, Tw
    real scalar    n, p, it, conv, ntrim, gmin, gmax

    X = st_data(., varlist, touse)
    d = st_data(., wgtvar,  touse)
    n = rows(X)
    p = cols(X)
    T = T0'

    if (cols(T0) != p) {
        errprintf("calibra: el numero de totales no coincide con el numero de variables auxiliares\n")
        exit(198)
    }

    it   = 0
    conv = 1

    if (method == "linear") {
        g = calibra_linear(X, d, T)
    }
    else if (method == "raking") {
        g = calibra_raking(X, d, T, tol, maxiter, it, conv)
    }
    else if (method == "logit") {
        g = calibra_logit(X, d, T, L, U, tol, maxiter, it, conv)
    }
    else {
        errprintf("calibra: metodo no reconocido: %s\n", method)
        exit(198)
    }

    ntrim = 0
    if (haslimits & (method=="linear" | method=="raking")) {
        ntrim = sum(g:<L :| g:>U)
        g     = rowmax((g, J(n,1,L)))
        g     = rowmin((g, J(n,1,U)))
    }

    w     = d :* g
    Tdhat = cross(X,d)
    Tw    = cross(X,w)
    gmin  = min(g)
    gmax  = max(g)

    st_store(., newwgt, touse, w)

    st_numscalar("__calibra_conv",  conv)
    st_numscalar("__calibra_iter",  it)
    st_numscalar("__calibra_ntrim", ntrim)
    st_numscalar("__calibra_gmin",  gmin)
    st_numscalar("__calibra_gmax",  gmax)
    st_numscalar("__calibra_n",     n)
    st_matrix("__calibra_Tdhat",    Tdhat)
    st_matrix("__calibra_Tw",       Tw)
}

end
