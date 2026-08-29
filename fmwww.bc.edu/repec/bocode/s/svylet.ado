*! svylet.ado v1.6 - 27aug2026
*! Wald omnibus F-test + Bonferroni pairwise comparisons + Compact Letter
*! Display (CLD) for means, totals, proportions, and ratios under survey
*! design.
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
*! v1.5 -- FIX real (encontrado corriendo revision_pre_ssc.do en Stata
*! real, StataNow 19.5, antes de mandar el paquete a SSC): over() STRING
*! (ej. una variable armada con decode()) hacia que "over() debe tener
*! al menos 2 categorias en la muestra" saltara SIEMPRE, sin importar
*! cuantas categorias reales tuviera la variable. Causa raiz: la linea
*! "markout `touse' `over' `denominator'" (sin la opcion strok) hace que
*! Stata excluya el 100% de las observaciones en cuanto CUALQUIER
*! variable de su lista es de tipo string -- no solo las de string vacio,
*! TODAS -- confirmado aislando el markout solo (fuera de svylet.ado) con
*! datos donde la variable string no tenia NINGUN valor vacio. touse
*! quedaba en 0 para las 74 observaciones de auto.dta, "levelsof origin
*! if touse" devolvia vacio, y el chequeo de k<2 saltaba por una causa
*! que no tenia nada que ver con el numero real de categorias. Afecta a
*! CUALQUIER llamada con over() string -- el camino numerico (el uso mas
*! comun) nunca estuvo afectado, porque strok no cambia el manejo de
*! variables numericas. Corregido agregando ", strok" al markout. Este
*! bug estaba presente desde v1.0; el ejemplo de over() string agregado
*! al help en esta misma sesion (svylet.sthlp) nunca se habia corrido en
*! Stata real hasta ahora -- ver revision_pre_ssc.do en el repo, seccion 5.
*!
*! v1.6 -- FIX (encontrado revisando tabulados de produccion reales,
*! tipo_actividad/Pecuaria): filas con las 4 categorias de over() con
*! estimacion presente (ninguna realmente faltante) igual mostraban el F
*! omnibus en blanco, porque 1-3 de esas 4 categorias tenian proporcion
*! exactamente 0% (varianza degenerada). Causa raiz: el contraste R del
*! F omnibus (svylet_core(), Mata) se armaba con las k categorias
*! COMPLETAS -- una sola con V[i,i] missing o <=0 propaga "." por
*! R*V*R' y lusolve() devuelve missing para TODO el estadistico, aunque
*! el resto de las k-1 categorias tuvieran variables perfectamente
*! calculables. Mismo criterio que ya se aplicaba a los pares (Pmat: una
*! categoria degenerada solo invalida SUS pares, no todos) -- ahora el F
*! omnibus se calcula sobre el SUBCONJUNTO de categorias con varianza
*! definida (minimo 2, no se puede testear una igualdad con menos). Con
*! 0 categorias degeneradas el resultado es identico al de v1.5 (mismo
*! contraste, misma formula). Replicado en tsvy.ado (tsvy_core(), que
*! mantiene su propia copia de este motor -- ver nota ahi sobre por que
*! no puede llamar a svylet_core() entre archivos .ado separados de SSC).
*!
*! v1.5 (parte 2, mismo dia, corriendo el FIX de arriba en Stata real):
*! con touse corregido, over() string sigue sin funcionar -- ahora falla
*! en el "svy: mean/total/proportion/ratio ..., over(`over')" interno con
*! el error NATIVO de Stata "string variables not allowed in varlist;
*! invalid over() option" (r(109)). Esto es una limitacion DURA de
*! svy: mismo (over() debe ser numerico, sin excepcion) -- no algo que
*! svylet pueda evitar sin re-mapear el string a codigos numericos por
*! dentro (no intentado; agrega complejidad no validada en Stata real
*! justo antes de una entrega). La documentacion previa ("varname may be
*! numeric or string") era incorrecta desde antes de esta sesion -- ver
*! svylet.sthlp/svylet_es.sthlp. Agregado un chequeo temprano (justo
*! despues de syntax) que detecta over() string y corta con un mensaje
*! claro sugiriendo encode(), en vez de dejar que el usuario llegue al
*! error crudo de Stata mas abajo.
*!
*! v1.1 -- auditoria: dos cambios de comportamiento respecto a v1.0:
*!   1. boot(): la reasignacion de pseudo-grupo bajo H0 (prepivoting,
*!      Beran 1988 / Hall & Wilson 1991) ahora se hace a nivel de
*!      CONGLOMERADO (`newpsu' tras bsample), no a nivel de observacion.
*!      En v1.0, un sorteo por FILA + reparto en bloques de filas
*!      contiguas partia un mismo conglomerado entre varios pseudo-
*!      grupos, destruyendo la correlacion intra-conglomerado que el
*!      propio diseno (svyset) asume al calcular varianza -- eso sesga
*!      el p-valor bootstrap hacia el rechazo (ver simulacion en
*!      sim/simulacion_bootstrap.py: con v1.0 el error tipo I bajo H0
*!      queda inflado por encima del alpha nominal; con v1.1 queda
*!      centrado en el nominal). Respaldo: Rao & Wu (1988, JASA),
*!      Rust & Rao (1996, Stat Methods Med Res), Wolter (2007,
*!      "Introduction to Variance Estimation" 2nd ed, cap. 6),
*!      Field & Welsh (2007, JRSS-B), Hall & Wilson (1991, Biometrics),
*!      Canty & Davison (1999, The Statistician), Davison & Hinkley
*!      (1997, "Bootstrap Methods and Their Application", cap. 3 y 9).
*!   2. refgroup() ELIMINADO de la sintaxis. Estaba declarado desde v1.0
*!      pero nunca se usaba en el programa ni en el motor Mata -- el
*!      contraste F omnibus siempre corria contra el grupo 1. Al revisar
*!      la matematica: el estadistico de Wald para "todos los grupos
*!      iguales" es INVARIANTE al grupo de referencia elegido, porque
*!      cualquier conjunto de k-1 contrastes independientes que genere
*!      el mismo subespacio da el mismo Wald (R2 = A*R para A invertible
*!      => (R2 b)'(R2 V R2')^-1(R2 b) = (R b)'(R V R')^-1(R b)). Por eso
*!      no se "implementa" refgroup(): no hay nada que implementar que
*!      cambie el resultado. Dejarlo en la sintaxis como no-op silencioso
*!      es peor que quitarlo -- un usuario que lo pase ahora obtiene un
*!      error claro de Stata ("option refgroup() not allowed") en vez de
*!      creer que cambio algo cuando no lo hizo.
*!   3. Nota agregada: level() solo tiene efecto para stat(proportion).
*!      Si se pasa level() distinto del default junto con mean/total, se
*!      muestra un aviso (no es un error -- level() simplemente no aplica
*!      ahi) en vez de ignorarlo en silencio.
*!
*! v1.2 -- agrega stat(ratio): svy: ratio numerador/denominador, over().
*!   El denominador se pasa por la opcion denominator(varname), no por
*!   texto "num/den" en varlist -- svylet arma la sintaxis "num/den" que
*!   svy: ratio espera internamente. e(b)/e(V) de svy: ratio tienen la
*!   MISMA forma que mean/total (una sola ecuacion, k columnas, una por
*!   categoria de over()) -- por eso _svylet_seleccionar no necesito
*!   cambios: su rama "else" (ya usada por mean/total) sirve igual para
*!   ratio, sin logica nueva de seleccion de ecuacion.
*!
*! v1.3 -- FIX: r(n_ponderado)/r(n_sin_ponderar) devolvian los valores
*!   INVERTIDOS desde v1.0 (e(_N) mapeado a "ponderado" y e(_N_subp) a
*!   "sin ponderar" -- al reves). Encontrado en produccion via tsvy:
*!   en la columna N_SIN_PON del frame acumulador aparecia un numero del
*!   orden de millones (identico a ESTIMA en stat(total) con varname
*!   constante =1, que por construccion ES el tamano de poblacion
*!   ponderado) en vez de un conteo de casos de muestra. Ver nota junto a
*!   "tempname Nmat Nsubpmat Rtable" en el cuerpo del programa. Afecta a
*!   TODO llamador de svylet que use r(n_ponderado)/r(n_sin_ponderar) --
*!   en particular tsvy (columnas N_PONDERA/N_SIN_PON del frame
*!   acumulador). No afecta r(b)/r(V) ni el test F/CLD -- esas cantidades
*!   nunca pasaron por Nmat/Nsubpmat.
*!
*! v1.4 -- agrega ref(): comparaciones "cada categoria de over() contra
*!   una categoria base fija", Bonferroni sobre k-1 comparaciones -- una
*!   FAMILIA DE HIPOTESIS DISTINTA de la que responde el F omnibus + CLD
*!   existente (que compara TODOS los pares, Bonferroni sobre
*!   k(k-1)/2). Ver svylet.sthlp, seccion Remarks, para la justificacion
*!   y las referencias (Dunn 1961; Dunnett 1955, 1964; Hsu 1996) sobre
*!   por que estas dos preguntas dan, legitimamente, resultados
*!   distintos para el MISMO dato -- encontrado al comparar las letras
*!   CLD de tsvy contra un script de referencia que solo comparaba cada
*!   anio contra el anio mas reciente (Bonferroni sobre 3 comparaciones,
*!   no sobre 6): ninguna de las dos salidas estaba mal, respondian
*!   preguntas distintas.
*!
*! See svylet.sthlp for full documentation, options, examples, and
*! references.

program define svylet, rclass
    version 14
    syntax varname(numeric) [if] [in], OVER(varname) ///
        STAT(string) [ALPHA(real 0.05) LEVEL(integer 1) ///
        DENOMINATOR(varname numeric) BOOT(integer 0) BSEED(integer -1) ///
        REF(string)]

    * over() DEBE ser numerico -- svy: mean/total/proportion/ratio no
    * aceptan un over() string en absoluto ("string variables not
    * allowed in varlist; invalid over() option", r(109)), confirmado en
    * Stata real (StataNow 19.5). Rechazar ACA con un mensaje claro, antes
    * de marksample/markout, en vez de dejar que el usuario llegue al
    * error crudo de Stata mas abajo -- sugiere encode() como salida.
    capture confirm string variable `over'
    if !_rc {
        di as err "over(`over') es una variable string -- svy: `stat' no acepta over() string."
        di as err "Solucion: encode `over', gen(nombre_numerico) y use over(nombre_numerico)."
        exit 109
    }

    local stat = lower("`stat'")
    if !inlist("`stat'", "mean", "proportion", "total", "ratio") {
        di as err "stat() debe ser mean, proportion, total o ratio"
        exit 198
    }
    if "`stat'" != "proportion" & `level' != 1 {
        di as text "Nota: level() solo tiene efecto con stat(proportion) -- se ignora para `stat'."
    }
    if "`stat'" == "ratio" & "`denominator'" == "" {
        di as err "stat(ratio) requiere denominator(varname) -- el numerador es `varlist'"
        exit 198
    }
    if "`stat'" != "ratio" & "`denominator'" != "" {
        di as text "Nota: denominator() solo tiene efecto con stat(ratio) -- se ignora para `stat'."
    }

    marksample touse
    * strok: SIN esta opcion, markout excluye TODAS las observaciones
    * (no solo las de string vacio) en cuanto `over' es string -- no un
    * comportamiento documentado de forma obvia, confirmado en Stata real
    * (ver changelog v1.4.1 arriba): "markout touse over" sobre una
    * variable string (ej. over() con decode()) dejaba touse=0 para el
    * 100% de las observaciones, y el error resultante ("over() debe
    * tener al menos 2 categorias") no tenia nada que ver con la causa
    * real. strok le dice a markout que una variable string no-missing
    * (incluida "") se trate como valida -- las observaciones con string
    * REALMENTE vacio en `over' siguen quedando excluidas mas abajo,
    * porque levelsof nunca las cuenta como una categoria (una categoria
    * "" no es una categoria valida de over() para el test).
    markout `touse' `over' `denominator', strok

    quietly levelsof `over' if `touse', local(niveles_over)
    local k : word count `niveles_over'
    if `k' < 2 {
        di as err "over() debe tener al menos 2 categorias en la muestra"
        exit 198
    }

    * -- v1.4 -- ref(): comparaciones "cada categoria vs una categoria
    * base", Bonferroni sobre k-1 comparaciones -- PREGUNTA DISTINTA de
    * la que responde el F omnibus + CLD de mas abajo (que compara TODOS
    * los pares, Bonferroni sobre k(k-1)/2). Ver help para la cita de
    * literatura sobre por que estas dos familias de hipotesis dan,
    * legitimamente, resultados distintos (Dunn 1961; Dunnett 1955).
    local ref_idx = 0
    if "`ref'" != "" {
        local i = 0
        foreach v of local niveles_over {
            local i = `i' + 1
            if `v' == `ref' local ref_idx = `i'
        }
        if `ref_idx' == 0 {
            di as err "svylet: ref(`ref') no es un valor observado de over(`over') en la muestra."
            di as err "  valores observados: `niveles_over'"
            exit 198
        }
    }

    * -- Correr el comando svy correspondiente ------------------------------
    if "`stat'" == "mean" {
        svy: mean `varlist' if `touse', over(`over')
    }
    else if "`stat'" == "total" {
        svy: total `varlist' if `touse', over(`over')
    }
    else if "`stat'" == "ratio" {
        svy: ratio `varlist'/`denominator' if `touse', over(`over')
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
    * Capturar N, N_subp, y r(table) INMEDIATAMENTE, antes de que
    * cualquier otro comando pueda tocar e()/r() -- mismo criterio que
    * ya establecimos: guardar apenas esta disponible, no confiar en que
    * sobreviva hasta mas adelante en el programa.
    *
    * v1.2 -- FIX: `Nmat' (e(_N)) y `Nsubpmat' (e(_N_subp)) estaban
    * INVERTIDOS al exponerse como r(n_ponderado)/r(n_sin_ponderar) desde
    * v1.0. Confirmado con datos reales (ENA, stat(total) con varname
    * constante =1): para NIVEL=NACIONAL/ANIO=2026, e(_N) devolvia
    * 20783 (el N de casos SIN ponderar, coincide con el conteo de filas
    * de la muestra ese anio) y e(_N_subp) devolvia 2057264.91... --
    * EXACTAMENTE igual a r(b) (la estimacion PONDERADA, ya que
    * varname=1 hace que total(varname) sea el tamano de poblacion
    * ponderado). O sea e(_N) es el tamano SIN ponderar y e(_N_subp) es
    * el PONDERADO -- al reves de lo que el nombre "_N_subp" sugiere y de
    * lo que este mismo archivo asumia. Los nombres de macro (`Nmat'/
    * `Nsubpmat') se mantienen como estaban (mapeados 1 a 1 a e(_N)/
    * e(_N_subp) respectivamente, para no confundir de donde viene cada
    * uno) -- el swap se hace mas abajo, en el return matrix, que es
    * donde se decide el significado (ponderado/sin ponderar) que ve
    * quien llama.
    tempname Nmat Nsubpmat Rtable
    capture matrix `Nmat' = e(_N)
    capture matrix `Nsubpmat' = e(_N_subp)
    capture matrix `Rtable' = r(table)

    * -- Seleccionar las filas relevantes de b/V (subrutina reutilizable, ----
    *    la necesita tambien el loop de boot() mas abajo) --------------------
    tempname b_sel V_sel
    _svylet_seleccionar `B' `V' `k' `level' "`stat'" "`varlist'" `b_sel' `V_sel'
    local idx_usar "`r(idx_usar)'"

    * -- v1.4 -- ref(): k-1 contrastes de Wald "categoria vs ref_idx",
    * Bonferroni sobre k-1 (no sobre k(k-1)/2 como el CLD). Usa el MISMO
    * b_sel/V_sel/df_r ya calculados -- ningun svy: adicional.
    tempname p_vsref p_vsref_raw
    matrix `p_vsref'     = J(`k', 1, .)
    matrix `p_vsref_raw' = J(`k', 1, .)
    if `ref_idx' > 0 {
        mata: svylet_vsref("`b_sel'", "`V_sel'", `df_r', `ref_idx', `k', "`p_vsref'", "`p_vsref_raw'")
    }

    * N ponderado / sin ponderar por categoria, en el mismo orden que
    * b_sel/V_sel (usa los mismos indices de columna que ya selecciono
    * _svylet_seleccionar). Si e(_N)/e(_N_subp) no existieran por algun
    * motivo (comando svy distinto sin esa info), quedan en missing en
    * vez de cortar la ejecucion -- esto es informativo, no critico para
    * el test en si.
    tempname Nout Nsubpout
    matrix `Nout' = J(`k', 1, .)
    matrix `Nsubpout' = J(`k', 1, .)

    * Limite inferior/superior del IC por categoria: se leen DIRECTO de
    * r(table) (filas "ll"/"ul"), NO se reconstruyen con una formula
    * simetrica propia. r(table) ya trae el IC correcto para cada
    * stat() -- simetrico para mean/total, en escala logit para
    * proportion (respeta [0,1]) -- construirlo de nuevo a mano
    * arriesgaba reimplementar mal esa transformacion. Usar lo que Stata
    * ya calculo es mas robusto que reimplementarlo.
    tempname LIout LSout
    matrix `LIout' = J(`k', 1, .)
    matrix `LSout' = J(`k', 1, .)
    local fila = 0
    foreach i of local idx_usar {
        local fila = `fila' + 1
        capture matrix `Nout'[`fila', 1] = `Nmat'[1, `i']
        capture matrix `Nsubpout'[`fila', 1] = `Nsubpmat'[1, `i']
        capture matrix `LIout'[`fila', 1] = `Rtable'["ll", `i']
        capture matrix `LSout'[`fila', 1] = `Rtable'["ul", `i']
    }

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

        * Tamanos por grupo medidos en NUMERO DE CONGLOMERADOS distintos
        * (no en numero de filas -- v1.1: la unidad que se reasigna bajo
        * H0 es el conglomerado, asi que las proporciones deben calcularse
        * sobre esa misma unidad).
        tempname n_psu_por_grupo
        matrix `n_psu_por_grupo' = J(`k', 1, .)
        local n_psu_total_orig = 0
        local i = 0
        foreach niv of local niveles_over {
            local i = `i' + 1
            quietly levelsof `psuvar' if `over' == `niv' & `touse', local(__psulet_lv)
            local n_psu_niv : word count `__psulet_lv'
            matrix `n_psu_por_grupo'[`i', 1] = `n_psu_niv'
            local n_psu_total_orig = `n_psu_total_orig' + `n_psu_niv'
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
            tempvar newpsu psu_first psu_orden rank_psu grupo_asig grupo_pseudo
            capture noisily {
                bsample, cluster(`psuvar') strata(`stratavar') idcluster(`newpsu')

                * v1.1 -- Reasignar el pseudo-grupo a nivel de CONGLOMERADO
                * (`newpsu', el conglomerado ya remuestreado por bsample),
                * NO a nivel de observacion. Un solo sorteo por
                * conglomerado; el conglomerado entero se mueve como
                * bloque indivisible al pseudo-grupo que le toque -- nunca
                * se parte entre dos pseudo-grupos. Esto es lo que
                * preserva la correlacion intra-conglomerado que el propio
                * diseno (y el F observado) asume al calcular varianza
                * (ver referencias en el encabezado).
                quietly bysort `newpsu': gen byte `psu_first' = (_n==1)
                quietly count if `psu_first'
                local n_psu_actual = r(N)

                quietly gen double `psu_orden' = runiform() if `psu_first'
                quietly egen `rank_psu' = rank(`psu_orden') if `psu_first', unique

                quietly gen `grupo_asig' = .
                local acumulado = 0
                local asignado = 0
                local i = 0
                foreach niv of local niveles_over {
                    local i = `i' + 1
                    if `i' == `k' {
                        * el ultimo grupo se lleva el resto exacto, para
                        * garantizar que la suma de todos los ni sea
                        * exactamente n_psu_actual (evita perder o sobrar
                        * conglomerados por redondeo)
                        local ni = `n_psu_actual' - `asignado'
                    }
                    else {
                        local ni_orig = `n_psu_por_grupo'[`i', 1]
                        local ni = round(`n_psu_actual' * `ni_orig' / `n_psu_total_orig')
                    }
                    if `ni' > 0 {
                        quietly replace `grupo_asig' = `niv' if `psu_first' & ///
                            `rank_psu' > `acumulado' & `rank_psu' <= `acumulado' + `ni'
                    }
                    local acumulado = `acumulado' + `ni'
                    local asignado = `asignado' + `ni'
                }
                * Expandir la etiqueta asignada en el "primero de cada
                * conglomerado" a TODAS sus filas -- max() por `newpsu',
                * ya que dentro de cada conglomerado solo esa fila tiene
                * un valor no-missing.
                quietly bysort `newpsu': egen `grupo_pseudo' = max(`grupo_asig')

                quietly svyset `newpsu', strata(`stratavar') singleunit(certainty)
                if "`stat'" == "mean" {
                    quietly svy: mean `varlist', over(`grupo_pseudo')
                }
                else if "`stat'" == "total" {
                    quietly svy: total `varlist', over(`grupo_pseudo')
                }
                else if "`stat'" == "ratio" {
                    quietly svy: ratio `varlist'/`denominator', over(`grupo_pseudo')
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
    local etiqueta_var "`varlist'"
    if "`stat'" == "ratio" local etiqueta_var "`varlist'/`denominator'"
    di as text "svylet -- `stat' de `etiqueta_var', over(`over')"
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
    * Grados de libertad de diseno SIN el ajuste Korn-Graubard (el que
    * necesita un IC estandar tipo b +/- t(df)*se) -- df_den de arriba
    * es el ajustado para el F omnibus, un numero distinto a proposito
    * (ver help, seccion Korn-Graubard). Devolver los dos por separado
    * para que quien arme una tabla de IC no use por error el ajustado.
    return scalar df_raw          = `df_r'
    * Estimaciones puntuales, varianza, y tamanos de muestra por
    * categoria -- lo que hace falta para armar una tabla de punto
    * (estimacion + error estandar + IC + casos) sin tener que correr
    * svy: total/mean/proportion una SEGUNDA vez por separado. svylet ya
    * corrio esa estimacion internamente -- exponerla evita duplicar el
    * trabajo de estimacion (confirmado con datos reales de ENA: correr
    * la estimacion dos veces en paralelo fue la fuente de varios bugs
    * de alineacion en el pipeline de especies).
    return matrix b               = `b_obs'
    return matrix V               = `V_sel'
    * Swap deliberado -- ver nota junto a "tempname Nmat Nsubpmat Rtable"
    * mas arriba: e(_N) (-> `Nout') resulto ser el tamano SIN ponderar y
    * e(_N_subp) (-> `Nsubpout') el PONDERADO, al reves de la asuncion
    * original.
    return matrix n_ponderado     = `Nsubpout'
    return matrix n_sin_ponderar  = `Nout'
    * Limite inferior/superior tal como los devolvio Stata en r(table)
    * (ver nota mas arriba de por que no se reconstruyen a mano).
    return matrix ci_lower        = `LIout'
    return matrix ci_upper        = `LSout'
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

    * -- v1.4 -- ref(): p-valores "vs categoria base", crudo y ajustado
    * por Bonferroni (k-1 comparaciones) -- vacios (missing) si ref() no
    * se especifico, y en la posicion de la propia categoria base.
    return scalar ref_idx        = `ref_idx'
    return matrix p_vsref        = `p_vsref'
    return matrix p_vsref_raw    = `p_vsref_raw'
end

* -------------------------------------------------------------------------
* Subrutina compartida: selecciona de una matriz e(b)/e(V) las k filas que
* corresponden a las categorias de over() (para proportion, solo las del
* valor `level' del indicador). Usada tanto por el calculo analitico como
* por cada replica del bootstrap -- un solo lugar donde vive esta logica.
* -------------------------------------------------------------------------
capture program drop _svylet_seleccionar
program define _svylet_seleccionar, rclass
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
    * Exponer los indices de columna usados -- el caller los necesita
    * para extraer en el mismo orden otras cantidades por categoria que
    * no pasan por esta subrutina (ej. e(_N), e(_N_subp)).
    return local idx_usar "`idx_usar'"
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
    // (matematicamente invariante al grupo de referencia elegido -- ver
    // nota v1.1 en el encabezado del .ado sobre por que refgroup() se
    // elimino en vez de "implementarse": cualquier conjunto de k-1
    // contrastes independientes que genere el mismo subespacio da
    // identico Wald).
    // Ajuste de Korn & Graubard (1990), que es el DEFAULT de Stata para
    // testparm/test despues de un comando svy: -- confirmado contra
    // datos reales (sysuse auto): sin este ajuste, svylet daba F(4,67)
    // mientras que "svy: regress + testparm" daba F(4,64) para el MISMO
    // dato y diseno. La formula (ver "help test", opcion nosvyadjust):
    //   sin ajuste (lo que Stata llama nosvyadjust): W/k ~ F(k,d)
    //   CON ajuste (el default real de Stata):
    //     (d-k+1)/(k*d) * W ~ F(k, d-k+1)
    // con k = dimension del test (aqui, num_grupos-1) y d = e(df_r).
    //
    // v1.6 -- FIX: hasta v1.5, R se armaba con las k categorias
    // COMPLETAS (incluyendo las de varianza degenerada), asi que UNA
    // sola categoria con proporcion exactamente 0 o 1 (sin variabilidad)
    // hacia que TODO el F omnibus quedara en missing -- el "." de esa
    // categoria se propaga por R*V*R' y lusolve() devuelve missing,
    // aunque el resto de las categorias tuvieran variables perfectamente
    // calculables. Confirmado en produccion (tsvy, tabulado real):
    // filas con 4 de 4 anios con "Estimacion" (ninguno realmente
    // faltante) igual daban F en blanco porque 1-3 de esos anios eran
    // exactamente 0%. Igual que ya se hacia para los pares (Pmat, mas
    // abajo: una categoria degenerada solo invalida SUS pares, no todos)
    // ahora el F omnibus se calcula sobre el SUBCONJUNTO de categorias
    // con varianza definida, excluyendo las degeneradas del contraste en
    // vez de dejar que su "." contamine todo. Minimo 2 categorias
    // validas para poder testear una igualdad (con 0 o 1, no hay nada
    // que comparar) -- con 0 degeneradas, idx_validas es 1..k y el
    // resultado es identico al de v1.5.
    real scalar k_dim, df_ajustado, k_valida
    real colvector idx_validas, b_valida
    real matrix V_valida
    idx_validas = select((1::k), var_degenerada :== 0)
    k_valida = rows(idx_validas)
    if (k_valida >= 2) {
        b_valida = b[idx_validas]
        V_valida = V[idx_validas, idx_validas]
        k_dim = k_valida - 1
        R = J(k_dim, k_valida, 0)
        for (i=2; i<=k_valida; i++) {
            R[i-1,1] = -1
            R[i-1,i] = 1
        }
        RVR = R*V_valida*R'
        stat_wald = (R*b_valida)' * lusolve(RVR, R*b_valida)
        df_ajustado = df - k_dim + 1
        Fstat = (df_ajustado / (k_dim * df)) * stat_wald
        p_omni = 1 - F(k_dim, df_ajustado, Fstat)
        if (k_valida < k) {
            printf("{txt}  F omnibus calculado con %g de %g categorias" +
                   " (las de varianza degenerada quedan afuera del" +
                   " contraste, no del reporte -- sus puntos siguen" +
                   " listados, su letra queda en [?]).\n", k_valida, k)
        }
    }
    else {
        k_dim = .
        df_ajustado = .
        Fstat = .
        p_omni = .
        printf("{txt}  F omnibus no calculable: menos de 2 categorias" +
               " con varianza definida (%g de %g).\n", k_valida, k)
    }

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

// v1.4 -- ref(): contrastes de Wald de UNA categoria contra una
// categoria BASE fija (ref_idx), k-1 comparaciones -- distinto del F
// omnibus + CLD de arriba (que compara TODOS los pares, k(k-1)/2
// comparaciones). Corrige por Bonferroni sobre k-1 (min(1, p_crudo *
// (k-1))), el mismo criterio que Dunn (1961, JASA) para "comparar
// varios grupos contra un control" -- MAS simple y MAS conservador que
// el metodo de un solo paso de Dunnett (1955, JASA; 1964, Biometrics),
// que usa la distribucion t multivariada para aprovechar que las k-1
// comparaciones comparten la misma categoria base y ganar potencia; no
// implementado aca (ver help para el detalle y las referencias).
void svylet_vsref(string scalar bname, string scalar Vname, real scalar df,
                   real scalar ref_idx, real scalar k,
                   string scalar pname, string scalar prawname)
{
    real matrix b, V
    real colvector p_adj, p_raw
    real scalar i, se, t, ncomp

    b = st_matrix(bname)
    V = st_matrix(Vname)
    p_adj = J(k,1,.)
    p_raw = J(k,1,.)
    ncomp = k - 1

    for (i=1; i<=k; i++) {
        if (i == ref_idx) continue
        if (missing(V[i,i]) | missing(V[ref_idx,ref_idx]) | V[i,i]<=0 | V[ref_idx,ref_idx]<=0) continue
        se = sqrt(V[i,i] + V[ref_idx,ref_idx] - 2*V[i,ref_idx])
        if (se<=0 | missing(se)) continue
        t = (b[i] - b[ref_idx]) / se
        p_raw[i] = 2*ttail(df, abs(t))
        p_adj[i] = min((p_raw[i]*ncomp, 1))
    }
    st_matrix(pname, p_adj)
    st_matrix(prawname, p_raw)
}
end
