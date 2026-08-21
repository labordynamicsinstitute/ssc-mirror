*! svylet.ado v1.0 - 16aug2026
*! Wald omnibus F-test + Bonferroni pairwise comparisons + Compact Letter
*! Display (CLD) for means, proportions, and totals under survey design.
*! Adds r(letra_1..k) and r(nombre_categoria_1..k) so the CLD letters can
*! be read programmatically after the command runs, not only displayed.
*! Author: Andres Talavera Cuya. Affiliation stated for identification
*! purposes only -- this software is not an official product of INEI
*! and INEI bears no responsibility for it. Developed independently by
*! the author; views, methods, and results are the author's own and do
*! not necessarily reflect the position of INEI.
*! Distributed under the GNU General Public License v3
*! (https://www.gnu.org/licenses/gpl-3.0.txt).
*!
*! See svylet.sthlp for full documentation, options, examples, and
*! references.

program define svylet, rclass
    version 14
    syntax varname(numeric) [if] [in], OVER(varname) ///
        STAT(string) [ALPHA(real 0.05) REFGROUP(integer 1) LEVEL(integer 1) ///
        BOOT(integer 0) BSEED(integer -1)]

    local stat = lower("`stat'")
    if !inlist("`stat'", "mean", "proportion", "total") {
        di as err "stat() debe ser mean, proportion o total"
        exit 198
    }

    marksample touse
    markout `touse' `over'

    quietly levelsof `over' if `touse', local(niveles_over)
    local k : word count `niveles_over'
    if `k' < 2 {
        di as err "over() debe tener al menos 2 categorias en la muestra"
        exit 198
    }

    * -- Correr el comando svy correspondiente ------------------------------
    if "`stat'" == "mean" {
        svy: mean `varlist' if `touse', over(`over')
    }
    else if "`stat'" == "total" {
        svy: total `varlist' if `touse', over(`over')
    }
    else {
        svy: proportion `varlist' if `touse', over(`over')
    }

    tempname B V
    matrix `B' = e(b)
    matrix `V' = e(V)
    local df_r = e(df_r)
    if "`df_r'" == "" {
        di as err "e(df_r) no disponible tras el svy -- revisar version de Stata/diseno"
        exit 498
    }

    * -- Seleccionar las filas relevantes de b/V (subrutina reutilizable, ----
    *    la necesita tambien el loop de boot() mas abajo) --------------------
    tempname b_sel V_sel
    _svylet_seleccionar `B' `V' `k' `level' "`stat'" "`varlist'" `b_sel' `V_sel'

    * -- Motor Mata: F omnibus + Bonferroni + CLD ----------------------------
    mata: svylet_core("`b_sel'", "`V_sel'", `df_r', `alpha', `k')

    * r() es un solo espacio global -- CUALQUIER comando que corra despues
    * (incluido todo el bloque boot(), que llama svy:/count muchas veces)
    * lo sobreescribe. Guardar TODO lo que hace falta para la salida final
    * en locales/matrices propias ACA, antes de que arranque boot() -- no
    * confiar en que r(...) siga disponible mas adelante en el programa.
    local F_obs     = r(F_omnibus)
    local p_obs     = r(p_omnibus)
    local n_pares   = r(n_pares)
    tempname b_obs
    matrix `b_obs' = r(b)
    forvalues i = 1/`k' {
        local letra_`i' "`r(letra_`i')'"
    }

    * -- boot(): prepivoting del F omnibus (Beran 1988) ----------------------
    * Ver notas del encabezado -- pool de conglomerados de TODOS los grupos,
    * dentro de su estrato original, reasignados al azar en la misma
    * proporcion de tamanos que el dato real (fuerza H0 sin asumir
    * independencia -- Hall & Wilson 1991).
    local p_boot_omni = .
    local B_efectivo = .
    if `boot' > 0 {
        * e(psu)/e(strata) (nombre simple) vs e(psu1)/e(strata1) (marco
        * multietapico) vs e(su)/e(su1) ("sampling unit", el termino que
        * usa el propio svyset en su salida: "Sampling unit 1: cluster5")
        * -- se prueban las tres formas. La hipotesis de psu/psu1 quedo
        * DESCARTADA con datos reales: incluso con conglomerados genuinos
        * de mas de un caso (Number of PSUs=20, df=18), e(psu) y e(psu1)
        * seguian vacios -- el nombre real del macro es otro.
        local psuvar    "`e(psu)'"
        local stratavar "`e(strata)'"
        if "`psuvar'" == "" {
            local psuvar "`e(psu1)'"
        }
        if "`psuvar'" == "" {
            local psuvar "`e(su)'"
        }
        if "`psuvar'" == "" {
            local psuvar "`e(su1)'"
        }
        if "`stratavar'" == "" {
            local stratavar "`e(strata1)'"
        }
        if "`psuvar'" == "" | "`stratavar'" == "" {
            di as err "boot() requiere que svyset tenga psu() y strata() declarados"
            di as err "  e(psu)=" "`e(psu)'" "  e(psu1)=" "`e(psu1)'" ///
                "  e(su)=" "`e(su)'" "  e(su1)=" "`e(su1)'"
            di as err "  e(strata)=" "`e(strata)'" "  e(strata1)=" "`e(strata1)'"
            di as err "  ninguna de las formas probadas (psu/psu1/su/su1)" ///
                " funciono -- correr ereturn list despues del svy: para" ///
                " ver el nombre real del macro en esta version de Stata."
            exit 498
        }

        tempname n_por_grupo
        matrix `n_por_grupo' = J(`k', 1, .)
        local n_total_orig = 0
        local i = 0
        foreach niv of local niveles_over {
            local i = `i' + 1
            quietly count if `over' == `niv' & `touse'
            matrix `n_por_grupo'[`i', 1] = r(N)
            local n_total_orig = `n_total_orig' + r(N)
        }

        * Acumular los F de cada replica en una MATRIZ de Stata en memoria,
        * no con postfile/tempfile. postfile esta pensado para construir
        * datasets completos, no para juntar 300 numeros sueltos -- y cada
        * capa de archivo temporal (tempfile + postfile, mas los 300
        * preserve/restore del loop) es una oportunidad mas de colision de
        * nombres en el directorio temp de Windows (la causa mas probable
        * del mensaje cosmetico "file ... not found" que aparecia antes,
        * incluso despues de un primer intento de arreglo via frame -- ese
        * intento seguia usando un archivo en disco para leer los
        * resultados, por eso no lo resolvio). Con una matriz en memoria no
        * hay ningun archivo de por medio para esta parte.
        tempname resultados_boot
        matrix `resultados_boot' = J(`boot', 1, .)

        if `bseed' >= 0 set seed `bseed'
        local reps_ok = 0
        forvalues rep = 1/`boot' {
            preserve
            quietly keep if `touse'
            tempvar newpsu orden grupo_pseudo
            capture noisily {
                bsample, cluster(`psuvar') strata(`stratavar') idcluster(`newpsu')
                * El total de observaciones DESPUES de bsample no tiene por
                * que coincidir con el original -- conglomerados de tamano
                * desigual + remuestreo con reemplazo cambian el total real
                * en cada replica. Los tamanos de pseudo-grupo se recalculan
                * proporcionalmente sobre el total REAL de esta replica, no
                * sobre el original -- si no, "in a/b" termina pidiendo
                * observaciones que no existen ("observation numbers out of
                * range"), confirmado con datos reales.
                quietly count
                local n_actual = r(N)
                quietly gen double `orden' = runiform()
                sort `orden'
                quietly gen `grupo_pseudo' = .
                local acumulado = 0
                local asignado = 0
                local i = 0
                foreach niv of local niveles_over {
                    local i = `i' + 1
                    if `i' == `k' {
                        * el ultimo grupo se lleva el resto exacto, para
                        * garantizar que la suma de todos los ni sea
                        * exactamente n_actual (evita perder o sobrar obs
                        * por redondeo)
                        local ni = `n_actual' - `asignado'
                    }
                    else {
                        local ni_orig = `n_por_grupo'[`i', 1]
                        local ni = round(`n_actual' * `ni_orig' / `n_total_orig')
                    }
                    if `ni' > 0 {
                        quietly replace `grupo_pseudo' = `niv' in `=`acumulado'+1'/`=`acumulado'+`ni''
                    }
                    local acumulado = `acumulado' + `ni'
                    local asignado = `asignado' + `ni'
                }
                quietly svyset `newpsu', strata(`stratavar') singleunit(certainty)
                if "`stat'" == "mean" {
                    quietly svy: mean `varlist', over(`grupo_pseudo')
                }
                else if "`stat'" == "total" {
                    quietly svy: total `varlist', over(`grupo_pseudo')
                }
                else {
                    quietly svy: proportion `varlist', over(`grupo_pseudo')
                }
                tempname Bb Vb b_sel_b V_sel_b
                matrix `Bb' = e(b)
                matrix `Vb' = e(V)
                _svylet_seleccionar `Bb' `Vb' `k' `level' "`stat'" "`varlist'" `b_sel_b' `V_sel_b'
                mata: st_numscalar("r(Frep)", svylet_fomnibus_only(st_matrix("`b_sel_b'"), st_matrix("`V_sel_b'"), `df_r', `k'))
            }
            if _rc == 0 {
                matrix `resultados_boot'[`rep', 1] = r(Frep)
                local reps_ok = `reps_ok' + 1
            }
            restore
        }

        * Agregacion final directo en Mata sobre la matriz -- sin dataset,
        * sin archivo, sin frame. select() descarta las filas "." (replicas
        * que fallaron); el resto es la misma formula de siempre:
        *   p = (# replicas con F_replica >= F_obs, +1) / (B_efectivo + 1)
        local B_efectivo = 0
        local p_boot_omni = .
        mata: svylet_agregar_boot("`resultados_boot'", `F_obs')
        local B_efectivo = r(B_efectivo)
        if `B_efectivo' > 0 {
            local p_boot_omni = r(p_boot)
        }
    }

    * -- Salida a la ventana de resultados (todavia sin exportar a archivo) --
    di as text _n "{hline 70}"
    di as text "svylet -- `stat' de `varlist', over(`over')"
    di as text "{hline 70}"
    di as text "F de Wald (ANOVA global, ajustado por diseno):"
    if `F_obs' == . {
        di as err "  F no calculable: al menos una categoria de over() tiene" ///
            " varianza no definida (proporcion exactamente 0 o 1 sin" ///
            " variabilidad, u otra causa de SE indefinido) -- ver aviso arriba."
    }
    else {
        di as text "  F(" %3.0f `=`k'-1' ", " %6.0f `=`df_r'-(`k'-1)+1' ") = " as res %9.4f `F_obs' ///
            as text "   Prob > F (analitico) = " as res %6.4f `p_obs'
    }
    if `boot' > 0 {
        if `B_efectivo' > 0 {
            di as text "  Prob > F (bootstrap, prepivotado, B=" %4.0f `B_efectivo' ///
                " de " %4.0f `boot' " replicas validas) = " as res %6.4f `p_boot_omni'
        }
        else {
            di as err "  bootstrap: ninguna replica valida -- revisar diseno/psu/strata"
        }
    }
    di as text _n "Grupos (letras compartidas = NO significativamente distintos," ///
        " Bonferroni analitico sobre " %2.0f `n_pares' " pares -- NO recalibrado por boot();" ///
        " [?] = varianza no definida, NO tratar como sin diferencia):"
    forvalues i = 1/`k' {
        local nom_grupo : word `i' of `niveles_over'
        di as text "  `over' = `nom_grupo'" _col(20) as res %9.4f el(`b_obs', `i', 1) ///
            as text "   grupo: " as res "`letra_`i''"
    }

    return scalar F_omnibus      = `F_obs'
    return scalar p_omnibus      = `p_obs'
    return scalar p_omnibus_boot = `p_boot_omni'
    return scalar B_efectivo     = `B_efectivo'
    return scalar df_num         = `k' - 1
    return scalar df_den          = `df_r' - (`k'-1) + 1
    return scalar k_categorias   = `k'
    * Letras CLD y nombre de cada categoria de over(), expuestos
    * explicitamente via return local -- antes solo vivian en locales
    * internos (leidos de r(letra_N) puesto por Mata via st_global) que
    * se usaban para el "di" de pantalla, pero nunca se devolvian
    * formalmente. Sin esto, un pipeline que llama a svylet y despues
    * necesita las letras (no solo verlas en pantalla) no tenia forma
    * confiable de leerlas de vuelta.
    forvalues i = 1/`k' {
        local nom_grupo_`i' : word `i' of `niveles_over'
        return local letra_`i' "`letra_`i''"
        return local nombre_categoria_`i' "`nom_grupo_`i''"
    }
end

* -------------------------------------------------------------------------
* Subrutina compartida: selecciona de una matriz e(b)/e(V) las k filas que
* corresponden a las categorias de over() (para proportion, solo las del
* valor `level' del indicador). Usada tanto por el calculo analitico como
* por cada replica del bootstrap -- un solo lugar donde vive esta logica.
* -------------------------------------------------------------------------
capture program drop _svylet_seleccionar
program define _svylet_seleccionar
    args Bmat Vmat k level stat varname bout Vout

    local idx_usar ""
    if "`stat'" == "proportion" {
        * Para proportion, e(b) tiene una ECUACION por cada valor de
        * `varname', y DENTRO de cada ecuacion, una columna por categoria
        * de over(). El NOMBRE de la ecuacion depende de si `varname'
        * tiene value label definido -- CONFIRMADO con datos reales las
        * DOS formas (sysuse auto, foreign 0/1):
        *   - CON value label: el texto del label (ej. "Domestic"/"Foreign").
        *   - SIN value label: "_prop_N", donde N es la POSICION ORDINAL
        *     del valor entre los valores distintos de la variable (no el
        *     valor en si) -- ej. con foreign_sinlabel (valores 0 y 1),
        *     la ecuacion del valor 1 se llama "_prop_2" (segundo valor
        *     en orden), NO "_prop_1" ni "1". El intento anterior de usar
        *     el codigo numerico plano ("1") tambien fallo -- confirmado
        *     que esa forma no existe en ningun caso real probado.
        * Se filtra por `coleq', nunca por `colnames' ni por un patron
        * de texto con "@" -- eso resulto ser solo como "matrix list"
        * pinta dos niveles juntos en pantalla, no texto real.
        local vallab : value label `varname'
        local buscado_label ""
        if "`vallab'" != "" {
            local buscado_label : label `vallab' `level'
        }

        * Posicion ordinal del valor `level' entre los valores distintos
        * de `varname' (para armar "_prop_N" en el caso sin value label).
        quietly levelsof `varname', local(valores_x)
        local rank = 0
        local i = 0
        foreach v of local valores_x {
            local i = `i' + 1
            if `v' == `level' {
                local rank = `i'
            }
        }
        local buscado_ordinal = "_prop_`rank'"
        local buscado_numerico = "`level'"

        local ecuaciones : coleq `Bmat'
        local i = 0
        foreach eq of local ecuaciones {
            local i = `i' + 1
            if "`eq'" == "`buscado_label'" | "`eq'" == "`buscado_ordinal'" ///
                | "`eq'" == "`buscado_numerico'" {
                local idx_usar "`idx_usar' `i'"
            }
        }
        if wordcount("`idx_usar'") != `k' {
            local nombres : colnames `Bmat'
            di as err "no se pudieron identificar exactamente " `k' ///
                " filas para el valor " "`level'" " de " "`varname'" " en e(b)."
            di as err "  buscado como texto de label: " "`buscado_label'"
            di as err "  buscado como ordinal sin label: " "`buscado_ordinal'"
            di as err "  buscado como codigo numerico plano: " "`buscado_numerico'"
            di as err "  filas encontradas: " wordcount("`idx_usar'") " de " `k' " esperadas"
            di as err "  ecuacion / nombre de columna reales en e(b):"
            local i = 0
            foreach eq of local ecuaciones {
                local i = `i' + 1
                local nom : word `i' of `nombres'
                di as err "    [" `i' "] eq=" "`eq'" "  col=" "`nom'"
            }
            di as err "  ajustar level() si el valor de exito no es 1."
            exit 498
        }
    }
    else {
        forvalues i = 1/`k' {
            local idx_usar "`idx_usar' `i'"
        }
    }

    matrix `bout' = J(`k', 1, .)
    matrix `Vout' = J(`k', `k', 0)
    local fila = 0
    foreach i of local idx_usar {
        local fila = `fila' + 1
        matrix `bout'[`fila', 1] = `Bmat'[1, `i']
        local col = 0
        foreach j of local idx_usar {
            local col = `col' + 1
            matrix `Vout'[`fila', `col'] = `Vmat'[`i', `j']
        }
    }
end

version 14
mata:
mata clear

// Version liviana: solo el F omnibus, sin Bonferroni/CLD -- es todo lo que
// necesita cada replica del bootstrap (recalcular CLD 1000 veces seria
// trabajo de sobra, ya que boot() solo recalibra el F omnibus, no los pares).
real scalar svylet_fomnibus_only(real matrix b, real matrix V, real scalar df, real scalar k)
{
    real matrix R, RVR
    real scalar i, stat_wald, k_dim, df_ajustado

    k_dim = k - 1
    R = J(k_dim, k, 0)
    for (i=2; i<=k; i++) {
        R[i-1,1] = -1
        R[i-1,i] = 1
    }
    RVR = R*V*R'
    stat_wald = (R*b)' * lusolve(RVR, R*b)
    df_ajustado = df - k_dim + 1
    return((df_ajustado / (k_dim * df)) * stat_wald)
}

// Agregacion final del boot(): sin dataset, sin archivo, sin frame -- opera
// directo sobre la matriz de Stata que acumulo los F de cada replica
// (missing "." en las filas de replicas que fallaron). Mismo criterio de
// siempre: p = (# replicas con F_replica >= F_obs, +1) / (B_efectivo+1),
// corregido por continuidad (Davison & Hinkley 1997).
void svylet_agregar_boot(string scalar matname, real scalar F_obs)
{
    real matrix todas, validas
    real scalar B_efectivo, cruzan

    todas = st_matrix(matname)
    validas = select(todas, todas :!= .)
    B_efectivo = rows(validas)

    st_numscalar("r(B_efectivo)", B_efectivo)
    if (B_efectivo > 0) {
        cruzan = sum(validas :>= F_obs)
        st_numscalar("r(p_boot)", (cruzan + 1) / (B_efectivo + 1))
    }
}

void svylet_core(string scalar bname, string scalar Vname, real scalar df,
                  real scalar alpha, real scalar k)
{
    real matrix b, V, R, RVR, Pmat
    real scalar stat_wald, Fstat, p_omni, i, j, npares, t, se, p_raw, p_adj
    string matrix letras
    real matrix grupos_bin
    real scalar ngrupos, g, tam, ok, a, incluido

    b = st_matrix(bname)
    V = st_matrix(Vname)

    // ---- Deteccion de varianza degenerada/faltante (proporciones en 0
    // o 1 exactos, sin variabilidad -- comun en dominios chicos) -----------
    // Sin esto, un V[i,i] faltante se propaga silenciosamente y Mata trata
    // "." como "mas grande que cualquier numero" en comparaciones, lo que
    // puede terminar agrupando una categoria como "no significativamente
    // distinta" SIN que el test se haya podido calcular en realidad -- eso
    // es un resultado enganoso, no un resultado conservador.
    real colvector var_degenerada
    var_degenerada = J(k,1,0)
    for (i=1; i<=k; i++) {
        if (missing(V[i,i]) | V[i,i] <= 0) var_degenerada[i] = 1
    }
    if (sum(var_degenerada) > 0) {
        printf("{txt}Aviso: varianza no definida (o cero) en %g de %g categorias" +
               " -- probablemente una proporcion exactamente 0 o 1 sin variabilidad.\n",
               sum(var_degenerada), k)
        printf("{txt}  Categorias afectadas (indice dentro de over(), no el valor): ")
        for (i=1; i<=k; i++) {
            if (var_degenerada[i]==1) printf("%g ", i)
        }
        printf("\n{txt}  Sus letras se muestran como [?] -- NO tratar como" +
               " sin diferencia, el test no se pudo calcular ahi.\n")
    }

    // ---- F omnibus: H0 b1=b2=...=bk, contraste contra el grupo 1 ----
    // Ajuste de Korn & Graubard (1990), que es el DEFAULT de Stata para
    // testparm/test despues de un comando svy: -- confirmado contra
    // datos reales (sysuse auto): sin este ajuste, svylet daba F(4,67)
    // mientras que "svy: regress + testparm" daba F(4,64) para el MISMO
    // dato y diseno. La formula (ver "help test", opcion nosvyadjust):
    //   sin ajuste (lo que Stata llama nosvyadjust): W/k ~ F(k,d)
    //   CON ajuste (el default real de Stata):
    //     (d-k+1)/(k*d) * W ~ F(k, d-k+1)
    // con k = dimension del test (aqui, num_grupos-1) y d = e(df_r).
    real scalar k_dim, df_ajustado
    k_dim = k - 1
    R = J(k_dim, k, 0)
    for (i=2; i<=k; i++) {
        R[i-1,1] = -1
        R[i-1,i] = 1
    }
    RVR = R*V*R'
    stat_wald = (R*b)' * lusolve(RVR, R*b)
    df_ajustado = df - k_dim + 1
    Fstat = (df_ajustado / (k_dim * df)) * stat_wald
    p_omni = 1 - F(k_dim, df_ajustado, Fstat)

    // ---- Pares con correccion Bonferroni ----
    npares = k*(k-1)/2
    Pmat = J(k,k,.)
    for (i=1; i<=k-1; i++) {
        for (j=i+1; j<=k; j++) {
            if (var_degenerada[i]==1 | var_degenerada[j]==1) {
                // No calculable -- se deja explicitamente en missing, NO
                // se fuerza a 1 ni se deja que la aritmetica con "." lo
                // decida por accidente.
                p_adj = .
                Pmat[i,j] = p_adj
                Pmat[j,i] = p_adj
                continue
            }
            se = sqrt(V[i,i] + V[j,j] - 2*V[i,j])
            if (se > 0) {
                t = (b[j]-b[i]) / se
                p_raw = 2*ttail(df, abs(t))   // ttail = cola superior de t(df)
                p_adj = min((p_raw*npares, 1))
            }
            else {
                p_adj = 1
            }
            Pmat[i,j] = p_adj
            Pmat[j,i] = p_adj
        }
    }

    // ---- Compact Letter Display: enumerar subconjuntos maximales
    //      mutuamente no-significativos (misma logica que la version
    //      Python ya validada) ----
    string colvector letra_grupo
    letra_grupo = J(k,1,"")
    real matrix candidatos
    real scalar nc, es_maximal
    string scalar letra_actual
    real scalar letra_idx

    // enumerar todos los subconjuntos no vacios (k<=~8 en la practica, 2^k manejable)
    real scalar total_subsets, s, bitpos
    real colvector miembros
    real matrix subsets_validos
    subsets_validos = J(0, k, .)

    total_subsets = 2^k - 1
    for (s=total_subsets; s>=1; s--) {
        miembros = J(k,1,0)
        for (bitpos=1; bitpos<=k; bitpos++) {
            if ( mod(floor(s / 2^(bitpos-1)), 2) == 1 ) miembros[bitpos] = 1
        }
        if (sum(miembros) < 1) continue
        // Nunca incluir categorias de varianza degenerada en ningun
        // subconjunto candidato -- no pueden ser "iguales" NI "distintas"
        // a nadie si el test no se pudo calcular ahi.
        ok = 1
        for (i=1; i<=k & ok; i++) {
            if (miembros[i]==1 & var_degenerada[i]==1) {
                ok = 0
                break
            }
        }
        if (ok==0) continue
        for (i=1; i<=k & ok; i++) {
            if (miembros[i]==0) continue
            for (j=i+1; j<=k; j++) {
                if (miembros[j]==0) continue
                if (Pmat[i,j] < alpha) {
                    ok = 0
                    break
                }
            }
        }
        if (ok==1) subsets_validos = subsets_validos \ miembros'
    }

    // quedarse solo con los MAXIMALES (no contenidos en otro valido)
    real matrix maximales
    maximales = J(0,k,.)
    real scalar contenido
    for (s=1; s<=rows(subsets_validos); s++) {
        contenido = 0
        for (i=1; i<=rows(subsets_validos); i++) {
            if (i==s) continue
            if (all(subsets_validos[s,] :<= subsets_validos[i,]) &
                sum(subsets_validos[s,]) < sum(subsets_validos[i,])) {
                contenido = 1
                break
            }
        }
        if (contenido==0) maximales = maximales \ subsets_validos[s,]
    }

    letra_idx = 0
    for (g=1; g<=rows(maximales); g++) {
        letra_idx++
        letra_actual = char(96 + letra_idx)   // 97='a'
        for (i=1; i<=k; i++) {
            if (maximales[g,i]==1) letra_grupo[i] = letra_grupo[i] + letra_actual
        }
    }

    // Categorias de varianza degenerada: marcar explicitamente con "?",
    // nunca dejarlas con una letra real ni vacias sin explicacion.
    for (i=1; i<=k; i++) {
        if (var_degenerada[i]==1) letra_grupo[i] = "?"
    }

    st_numscalar("r(F_omnibus)", Fstat)
    st_numscalar("r(p_omnibus)", p_omni)
    st_numscalar("r(n_pares)", npares)
    st_matrix("r(b)", b)
    for (i=1; i<=k; i++) {
        st_global("r(letra_"+strofreal(i)+")", letra_grupo[i])
    }
}
end
