*! tsvy.ado v1.6 - 26aug2026
*! Motor generico de estimacion + test (F de Wald + Bonferroni + Compact
*! Letter Display) con encuestas complejas, usando svylet como unico motor.
*! Requiere Stata 16 o superior EN LA INSTALACION (usa frame create/
*! frame ...: ...); el "version 14" de las lineas de abajo NO es sobre
*! eso, ver la nota v1.6 (revertida) inmediatamente debajo.
*!
*! v1.6 -- REVERTIDO (mismo dia): se probo cambiar "version 14" a
*! "version 16" en las dos declaraciones del programa, con la idea de
*! que "frame create"/"frame `frame': ..." (Stata 16+) necesitaba ese
*! ajuste. Esa idea era INCORRECTA y se revirtio antes de mandar el
*! paquete a revision: "version 14" NO bloquea comandos mas nuevos como
*! frame (el motivo real por el que se requiere Stata 16 es que el
*! EJECUTABLE de Stata 14/15 no trae el comando frame en absoluto, sin
*! importar que "version" declare el programa) -- eso ya se confirmo
*! funcionando en produccion real con "version 14" + frames durante toda
*! esta sesion. Peor: "version 14" SI cambia el formato de nombres de
*! ecuacion que da "svy: proportion ..., over()" (por-categoria bajo
*! version 14 vs "@"-combinado nativo en Stata 19+, CONFIRMADO en Stata
*! real -- ver ejemplo_svylet.do, ejemplo 10). El camino conjunto de
*! tsvy (over() unico, boot()==0 & sexovar()=="", lineas ~415-424 mas
*! abajo) llama "svy: proportion ..., over(combo)" DIRECTO y despues
*! empareja columnas via coleq() contra el label/ordinal/codigo de
*! level() -- exactamente la logica que depende del formato por-
*! categoria. Cambiar a "version 16" habria roto silenciosamente
*! "tsvy, stat(proportion)" en el camino por defecto (coleq() ya no
*! encuentra las `k_total' columnas esperadas, exit 498). Revertido a
*! "version 14" en ambos lugares -- sin cambio de comportamiento neto
*! respecto a v1.5.
*!
*! v1.5 -- agrega refyear(): columnas P_VS_REF/SIG_VS_REF, comparando
*! CADA anio contra un anio BASE fijo (ej. refyear(2026)), Bonferroni
*! sobre k-1 comparaciones -- una FAMILIA DE HIPOTESIS DISTINTA de la
*! que responde GRUPO/F_WALD/P_WALD (que compara TODOS los pares entre
*! si, Bonferroni sobre k(k-1)/2). Encontrado al comparar las letras
*! GRUPO de tsvy contra un script de referencia que solo comparaba cada
*! anio contra 2026 (Bonferroni sobre 3 comparaciones, no sobre 6 como
*! el CLD): ~17% de las 81 comparaciones "anio vs 2026" derivadas de
*! GRUPO no coincidian con el resultado directo del script de
*! referencia -- NINGUNA de las dos salidas estaba mal, son PREGUNTAS
*! DISTINTAS (ver svylet.sthlp, seccion Remarks, para la justificacion
*! completa y las referencias: Dunn 1961; Dunnett 1955, 1964; Hsu 1996).
*! refyear() deja elegir la pregunta "vs un anio base" ademas de (no en
*! reemplazo de) GRUPO/CLD. Mismo criterio de autosuficiencia que v1.4
*! (FIX 2/FIX 3): el camino nuevo arma el contraste con llamadas mata:
*! de una linea (vectorizadas), sin definir una funcion mata nueva
*! dentro de "program define tsvy"; el camino viejo pasa ref() a
*! svylet.ado (que si define su propia funcion mata, a nivel de
*! archivo, para esto -- ver svylet.ado v1.4).
*!
*! v1.4 -- FIX: el error estandar de niveles de caida() que UNEN varias
*! strata del diseno original (tipico de REGION, que agrupa muchos
*! departamentos/DOMINIO) no coincidia con el que da correr
*! "svy: STAT ..., over(caida_var ANIO_)" a mano. Hasta v1.3, tsvy
*! filtraba PRIMERO ("if caida_var==valor") y recien ahi corria
*! "over(ANIO_)" (via svylet) -- en teoria equivalente para estimacion
*! de subpoblaciones, pero en datos reales de produccion (ENA) la
*! estimacion puntual (ESTIMA) coincidia exacto contra el calculo de
*! referencia, mientras que el error estandar de REGION quedaba
*! sistematicamente MAS CHICO (5%-20% segun anio/region); NACIONAL (1
*! sola categoria) y NOMBREDD_ (cada categoria ~ 1 sola strata) SI
*! coincidian exacto. Confirmado celda por celda contra dos .xlsx de
*! salida (uno del pipeline via tsvy, otro de "svy linearized: total
*! ..., over(REGION ANIO_)" corrido a mano sobre el mismo dataset/
*! diseno) -- ver PR/commit que agrego esta nota para el detalle
*! completo.
*!
*! Ahora, cuando boot()==0 y no se paso sexovar() (el caso de
*! produccion actual), tsvy corre UN SOLO "svy: STAT ..., over(caida_var
*! ANIO_)" conjunto por cada variable de caida() -- el MISMO comando
*! que el calculo de referencia -- y extrae despues, para cada valor de
*! caida_var, el bloque de columnas de e(b)/e(V) que le corresponde
*! (bloque contiguo, gracias a que el agrupamiento auxiliar se arma con
*! "egen group(caida_var ANIO_)", que ordena ascendente por caida_var y
*! despues por ANIO_ dentro de cada caida_var). El test F/CLD se sigue
*! corriendo por separado DENTRO de cada bloque (anios de un mismo
*! valor de caida_var entre si, nunca contra otro valor de caida_var) --
*! ver el comentario junto al "foreach a of local caida" en el cuerpo
*! del programa. boot()>0 y sexovar() TODAVIA usan el camino viejo
*! (if + over(ANIO_) por separado) -- ninguno de los dos aparece en el
*! uso de produccion actual, y extenderles el camino nuevo sin poder
*! correr Stata para validarlo ahora mismo es mas riesgo del que vale
*! la pena por ahora.
*!
*! FIX 2 (mismo v1.4, encontrado al probar el FIX de arriba en
*! produccion real): el camino nuevo NO puede depender de que
*! svylet.ado este completamente cargado -- probado que una llamada
*! muda al comando svylet (sin argumentos, solo para forzar la carga)
*! NO alcanza para que Stata registre _svylet_seleccionar ni compile
*! svylet_core(): fallaba con "command _svylet_seleccionar is
*! unrecognized" en cuanto el camino nuevo corria SOLO (boot()==0, sin
*! sexovar(), osea la corrida tipica: NINGUN bloque llega a invocar el
*! comando svylet como tal). Por eso el camino nuevo ahora es
*! autosuficiente: define su propia copia de svylet_core() (llamada
*! tsvy_core(), identica) y hace la seleccion de filas de e(b)/e(V) que
*! antes hacia _svylet_seleccionar() en linea, sin llamar a ningun
*! programa de otro archivo .ado.
*!
*! FIX 3 (mismo v1.4, encontrado al probar el FIX 2 en produccion real):
*! tsvy_core() no se puede definir DENTRO de "program define tsvy ...
*! end" -- Mata solo compila una definicion de funcion como bloque
*! mata: de nivel de archivo, nunca anidada en el cuerpo de un programa
*! Stata (fallaba al cargar el .ado con r(9611), con o sin "quietly"
*! alrededor). tsvy_core() vive, igual que svylet_core() en svylet.ado,
*! en su propio bloque mata: DESPUES del "end" que cierra el programa,
*! al final de este archivo.
*!
*! v1.3 -- Renombrado de tabsvylet a tsvy (mismo comando, sin cambios de
*! comportamiento) -- nombre mas compacto, mantiene la referencia a "tab"
*! del patron de tabsvy/tabsvyexport que sigue. tabsvylet.ado/.sthlp ya
*! no existen en el repo; el reemplazo es tsvy.ado/tsvy.sthlp/tsvy_es.sthlp.
*!
*! v1.2 -- FIX: if `if' NUNCA funcionaba (bug desde v1.0). El if-exp que
*! deja syntax [if] en el macro `if' YA incluye la palabra "if" (patron
*! estandar "cmd `if' `in'"); el codigo envolvia ese `if' de nuevo dentro
*! de una expresion booleana propia (filtro_base/subset), dejando un "if"
*! suelto en medio de la expresion -- fallaba con rc=111 en TODA
*! combinacion caida()/especie en cuanto se pasaba un if() (incluso el
*! del propio ejemplo de USO en este mismo encabezado, linea de abajo).
*! Reemplazado por marksample touse -- ver el comentario junto a
*! "marksample touse, novarlist" en el cuerpo del programa.
*!
*! Companero de tabsvy/tabsvyexport (github.com/atalaveracuya/tabsvy):
*! misma idea (un loop sobre niveles de agregacion -- NACIONAL/REGION/
*! NOMBREDD_ -- que acumula filas en un frame, listas para reshape wide y
*! exportar a Excel), pero en vez de "svy + parmby" (que solo da la tabla
*! de puntos), llama a svylet por cada combinacion (nivel de agregacion x
*! valor x [sexo]), que YA corre "svy: mean/total/proportion/ratio"
*! internamente -- asi que la tabla de puntos Y el test de comparacion
*! entre anios (F omnibus + Bonferroni + letras CLD) salen de la MISMA
*! pasada de estimacion, sin correr "svy:" dos veces y sin pegar los
*! resultados por posicion en matrices sueltas.
*!
*! v1.1 -- agrega denominator(varname), passthrough directo a
*! svylet(stat(ratio)). Requerido cuando stat(ratio); ignorado (con
*! aviso) en cualquier otro stat().
*!
*! Este comando NO modifica ni depende del codigo interno de tabsvy.ado
*! -- vive en el repo de svylet porque svylet es el motor que necesita.
*! Si mas adelante conviene fusionarlo dentro de tabsvy como un
*! ENGINE(svylet), este archivo es el punto de partida para eso.
*!
*! Reemplaza, para el caso "necesito tabla de puntos POR ANIO y ademas
*! saber si los anios son significativamente distintos entre si", el
*! patron manual que se repetia (matrices AC/AR, loops while, locales
*! indexados por posicion "F_r`r'_sp`o'", pegado por "in `fila'") en
*! especies_varestruc_svylet.do -- ver ejemplo_uso_tsvy.do para el
*! mismo cuadro de especies pecuarias reducido de ~300 lineas a un puñado
*! de llamadas.
*!
*! LIMITACIONES respecto a tabsvy (deliberadas, por ahora):
*!   - Una sola variable de analisis por llamada (igual que svylet: no
*!     acepta varlist). Para varias variables (ej. 13 especies), llamar
*!     tsvy una vez por variable, como en el ejemplo.
*!   - No tiene keepcat()/tipo() (el loop de bloques tematicos de tabsvy).
*!     Si tu caso los necesita, seguis usando tabsvy (motor svy+parmby)
*!     para esos cuadros -- tsvy es especificamente para cuadros que
*!     SI necesitan el test entre anios.
*!   - Cada combinacion (nivel de agregacion x valor x [sexo]) necesita
*!     AL MENOS 2 anios presentes en los datos para poder correr el test
*!     (requisito de svylet, k>=2). Si un dominio tiene un solo anio de
*!     datos, esa combinacion se salta con un aviso (no hay nada que
*!     comparar ahi) -- a diferencia de tabsvy, que si puede tabular un
*!     dominio con un solo anio (no necesita comparar nada).
*!
*! USO (mismo espiritu que tabsvy -- declarar el estrato/diseno y
*! NACIONAL=1 antes, como siempre; una llamada por variable, un loop
*! afuera si hay varias):
*!
*!     svyset CONGLO_ANIO, strata(ESTRATO_ANIO) weight(FACTORFINAL) ///
*!         vce(linearized) singleunit(certainty)
*!
*!     tsvy if pecuario==1 & cuenta_ua==1 & omision_esp==0,       ///
*!         varname(P404A_n_UA_1) stat(total)                           ///
*!         years(2023 2024 2025 2026) frame(F1) replace
*!
*! (para la especie 2, misma llamada con varname(P404A_n_UA_2) y SIN
*! `replace`, para seguir acumulando en el mismo frame F1)
*!
*! USO CON DIMENSION SEXO (agrega sexo al loop, y una columna SEXO al
*! frame acumulador):
*!
*!     tsvy if omision==0, varname(indicador) stat(proportion) ///
*!         level(1) years(2023 2024 2025 2026) sexovar(sexo) frame(F2) replace
*!
*! El frame que deja tsvy trae: NIVEL CAIDA [SEXO] var ANIO ESTIMA
*! ERROR_ST CV LIM_INF LIM_SUP N_SIN_PON N_PONDERA REF_ F_WALD P_WALD
*! GRUPO -- mismo esquema de columnas que deja tabsvy (compatible con
*! tabsvyexport para el bloque ESTIMA/REF_), mas F_WALD/P_WALD (constantes
*! dentro de cada bloque nivel-valor-[sexo], repetidas por anio) y GRUPO
*! (la letra CLD de ESE anio dentro de su bloque). Si se paso refyear(),
*! ademas trae P_VS_REF/SIG_VS_REF (Bonferroni de ESE anio contra el
*! anio base, k-1 comparaciones -- ver Remarks en svylet.sthlp sobre la
*! diferencia con GRUPO/CLD); si no se paso, esas dos columnas quedan en
*! missing/vacias. Para exportar TODAS las columnas (como hace
*! especies_varestruc_svylet.do a mano), el patron es:
*!
*!     frame F1: reshape wide ESTIMA REF_ ERROR_ST LIM_INF LIM_SUP CV    ///
*!         N_PONDERA N_SIN_PON GRUPO P_VS_REF SIG_VS_REF,                ///
*!         i(NIVEL CAIDA var F_WALD P_WALD) j(ANIO)
*!
*! (F_WALD/P_WALD quedan en i() porque son constantes dentro del grupo --
*! no varian por anio, no hace falta que el reshape las repita sufijadas)
*!
*! Requiere: svylet (este mismo repo) y frameappend (SSC) -- la misma
*! dependencia que ya pide tabsvy para acumular filas sin postfile/tempfile.
*!
*! Author: Andres Talavera Cuya. Afiliacion indicada solo para fines de
*! identificacion -- este software no es un producto oficial de INEI y
*! INEI no es responsable por el. Distribuido bajo GNU GPL v3
*! (https://www.gnu.org/licenses/gpl-3.0.txt).

capture program drop tsvy
program define tsvy
    version 14
    syntax [if], VARNAME(string) YEARS(numlist ascending) STAT(string) ///
        [                                                              ///
        CAIDA(string)         /// niveles de agregacion. Def: "NACIONAL REGION NOMBREDD_"
        SEXOVAR(string)       /// variable extra de desagregacion (ej. sexo). Opcional
        LEVEL(integer 1)      /// solo aplica a stat(proportion) -- ver help svylet
        DENOMINATOR(string)   /// requerido si stat(ratio) -- ver help svylet
        ALPHA(real 0.05)      /// nivel de significancia del test (svylet)
        BOOT(integer 0)       /// replicas bootstrap del F omnibus (svylet), 0 = solo analitico
        BSEED(integer -1)     ///
        EXPECTCATS(numlist)   /// categorias que DEBERIA tener VARNAME -- valida antes de estimar
        FRAME(name)           /// frame acumulador. Def: ACUM_ALL
        THRESHOLD(real 15)    /// umbral de CV(%) para marcar "a/"
        REFYEAR(string)       /// anio base para P_VS_REF/SIG_VS_REF (ej. 2026) -- ver help
        REPLACE                /// si se especifica, reinicia el frame acumulador
        ]

    * ---------------------------------------------------------------
    * v1.2 -- if/in via marksample, no manipulando el texto crudo de
    * `if' a mano. Bug real encontrado en produccion: el macro `if' que
    * deja syntax [if] YA INCLUYE la palabra "if" (igual que `in' incluye
    * "in") -- es el patron estandar "cmd `varlist' `if' `in'", sin
    * reescribir el "if" a mano. La version anterior no lo sabia: envolvia
    * `if' de nuevo en filtro_base = "(`if')" y lo pegaba con & dentro de
    * subset, asi que ante un if() real (ej. "if pecuario==1 & cuenta_ua==1
    * & omision_esp==0") terminaba corriendo
    * "svylet ... if NACIONAL == 1 & (if pecuario==1 & ...)"
    * -- un "if" suelto en medio de una expresion booleana, invalido --
    * fallaba SIEMPRE que se pasaba un if() a tsvy, en cualquier
    * caida()/especie (rc=111, "<primera palabra del if> not found").
    * touse (variable 0/1, marksample estandar) evita esa ambiguedad de
    * raiz: se antepone "if `touse'" explicitamente en cada uso, nunca se
    * reconstruye la expresion original como texto. tempvar (no un nombre
    * literal "touse"): subset queda "... & `touse'" y eso se le pasa TAL
    * CUAL a svylet, que internamente hace su PROPIO marksample touse
    * (nombre literal, sin tempvar) -- si tsvy tambien usara el
    * nombre literal "touse", cada llamada a svylet lo sobreescribiria
    * dentro del mismo loop, corrompiendo el touse de las iteraciones
    * siguientes. Con tempvar, el touse de tsvy y el de svylet son
    * columnas distintas por construccion, nunca chocan.
    * ---------------------------------------------------------------
    tempvar touse
    marksample touse, novarlist

    local stat = lower("`stat'")
    if !inlist("`stat'", "mean", "proportion", "total", "ratio") {
        di as err "tsvy: stat() debe ser mean, proportion, total o ratio"
        exit 198
    }
    if "`stat'" == "ratio" & "`denominator'" == "" {
        di as err "tsvy: stat(ratio) requiere denominator(varname)"
        exit 198
    }
    if "`caida'"  == "" local caida "NACIONAL REGION NOMBREDD_"
    if "`frame'"  == "" local frame "ACUM_ALL"

    capture confirm variable `varname'
    if _rc {
        di as err "tsvy: no se encontro la variable `varname'"
        exit 111
    }
    if "`denominator'" != "" {
        capture confirm variable `denominator'
        if _rc {
            di as err "tsvy: no se encontro la variable denominator(`denominator')"
            exit 111
        }
    }
    capture confirm variable ANIO_
    if _rc {
        di as err "tsvy: no se encontro la variable ANIO_ en los datos actuales."
        exit 111
    }

    * ---------------------------------------------------------------
    * Validacion fail-fast de categorias declaradas (igual criterio que
    * expectcats() en tabsvy): si alguien cambio la codificacion de
    * VARNAME sin avisar, se corta ACA, no despues de exportar mal.
    * ---------------------------------------------------------------
    if "`expectcats'" != "" {
        quietly levelsof `varname' if `touse', local(catlist_obs)
        local catlist_obs : list sort catlist_obs
        local catlist_exp : list sort expectcats
        if "`catlist_obs'" != "`catlist_exp'" {
            di as err "tsvy: las categorias observadas de `varname' (`catlist_obs') no coinciden con expectcats(`expectcats')."
            di as err "  Revise la codificacion (value label) de `varname' antes de seguir."
            exit 498
        }
    }

    * ---------------------------------------------------------------
    * Deteccion de los codigos REALES de ANIO_ presentes (mismo criterio
    * que tabsvy v1.3): years() es la lista de anios reales de ESTA base,
    * en orden cronologico -- no asume que ANIO_ va 1..k sin huecos.
    * ---------------------------------------------------------------
    local nyears : word count `years'
    quietly levelsof ANIO_ if `touse', local(codigos_anio)
    local ncodigos : word count `codigos_anio'
    if `ncodigos' != `nyears' {
        di as err "tsvy: years() tiene `nyears' elemento(s) pero ANIO_ tiene `ncodigos' codigo(s) distinto(s) en los datos actuales (`codigos_anio')."
        di as err "  Deben coincidir uno a uno: el codigo mas chico de ANIO_ -> el primer anio de years(), en orden cronologico."
        exit 198
    }

    * ---------------------------------------------------------------
    * v1.4 -- refyear(): traduce el anio calendario (ej. 2026) al codigo
    * REAL de ANIO_ que le corresponde, usando la MISMA correspondencia
    * posicional years()<->codigos_anio ya validada arriba -- nunca se
    * decodifica contra el value label de ANIO_ (mismo criterio que el
    * resto del programa). refyear() habilita las columnas P_VS_REF/
    * SIG_VS_REF del frame acumulador (comparacion Bonferroni de cada
    * anio contra refyear(), k-1 comparaciones -- ver help para la
    * diferencia con GRUPO/CLD, que compara TODOS los pares). Si no se
    * especifica, esas columnas quedan en missing/vacias.
    * ---------------------------------------------------------------
    local refcode = .
    if "`refyear'" != "" {
        local pos = 0
        local j = 0
        foreach yr of local years {
            local j = `j' + 1
            if "`yr'" == "`refyear'" local pos = `j'
        }
        if `pos' == 0 {
            di as err "tsvy: refyear(`refyear') no esta en years(`years')."
            exit 198
        }
        local refcode : word `pos' of `codigos_anio'
    }
    local refopt ""
    if `refcode' != . local refopt "ref(`refcode')"

    * ---------------------------------------------------------------
    * Frame acumulador
    * ---------------------------------------------------------------
    if "`replace'" != "" {
        capture frame drop `frame'
    }
    capture confirm frame `frame'
    if _rc {
        frame create `frame'
    }

    local bloques_saltados = 0
    local bloques_ok = 0

    * ------------------------------------------------------------------
    * v1.4 -- el camino nuevo de mas abajo (ver nota junto al "foreach a")
    * necesita el mismo motor F omnibus + Bonferroni + CLD que
    * svylet_core() en svylet.ado, pero NO puede llamar a svylet_core()
    * (funcion mata) ni a _svylet_seleccionar() (subrutina Stata) TAL
    * CUAL viven ahi: probado en produccion real que, si el comando
    * svylet en si nunca llega a ejecutarse dentro de la MISMA corrida de
    * tsvy (el caso comun: boot()==0 y sin sexovar(), que es exactamente
    * el camino que NO llama a svylet), Stata puede no haber registrado
    * _svylet_seleccionar todavia -- una llamada muda al comando svylet
    * (sin argumentos, para forzar la carga) NO alcanza: falla igual con
    * "command _svylet_seleccionar is unrecognized" (confirmado con log
    * real). En vez de depender de CUANDO/SI Stata termina de cargar el
    * resto de svylet.ado, tsvy.ado define su PROPIA copia de la funcion
    * mata (tsvy_core(), identica a svylet_core()) e implementa la
    * seleccion de filas de e(b)/e(V) en linea, sin subrutina aparte --
    * autosuficiente, sin depender del orden/momento de carga de otro
    * archivo .ado. Si el motor F/CLD de svylet_core() cambia, replicar
    * el cambio en tsvy_core() tambien.
    *
    * tsvy_core() NO puede definirse ACA (dentro de "program define tsvy
    * ... end"): Mata solo permite compilar una definicion de funcion
    * ("void nombre(...) { ... }") como bloque mata: de NIVEL DE ARCHIVO,
    * no anidada dentro del cuerpo de un programa Stata (probado: falla
    * al cargar el .ado con r(9611), sin importar si el bloque mata: va
    * envuelto en quietly o no). Por eso vive DESPUES del "end" que
    * cierra este programa, al final del archivo -- mismo lugar donde
    * vive el bloque mata: de svylet.ado, fuera de cualquier "program
    * define". Se carga junto con el resto del archivo apenas se invoca
    * el comando tsvy (una invocacion real, no una llamada muda a otro
    * archivo -- ver el parrafo de arriba sobre por que ESO fallaba).
    * ------------------------------------------------------------------

    foreach a of local caida {
        quietly levelsof `a' if `touse', local(niveles_caida)
        local n_niveles : word count `niveles_caida'

        * ----------------------------------------------------------------
        * v1.4 -- camino NUEVO (default: boot()==0 y sin sexovar()): un
        * solo "svy: STAT `varname', over(`a' ANIO_)" conjunto para TODOS
        * los valores de `a' a la vez -- el MISMO comando que produce el
        * numero de referencia cuando se corre a mano (ej.
        * "svy linearized: total PROD, over(REGION ANIO_)"). Ver nota de
        * cabecera (v1.4) sobre por que hace falta -- resumen: filtrar
        * "if `a'==valor" y recien ahi correr over(ANIO_) daba, en datos
        * reales, un error estandar mas chico que el correcto para
        * niveles que unen varias strata (REGION), aunque la estimacion
        * puntual coincidiera exacto.
        *
        * `combo' agrupa (`a', ANIO_) con egen group(), que numera
        * ascendente por `a' primero y por ANIO_ despues DENTRO de cada
        * `a' -- por construccion, todas las filas de un mismo valor de
        * `a' quedan en un rango CONTIGUO de valores de `combo', sin
        * huecos. Eso es lo que permite correr el svy: UNA sola vez para
        * toda la variable de caida() y despues cortar, por valor de
        * `a', el bloque de columnas de e(b)/e(V) que le corresponde --
        * en vez de tener que decodificar el nombre de ecuacion/columna
        * que Stata le pondria a un over() de DOS variables directo
        * (over(`a' ANIO_)), que no se pudo verificar sin correr Stata.
        * ----------------------------------------------------------------
        if `boot' == 0 & "`sexovar'" == "" {
            if `n_niveles' < 1 {
                continue
            }

            tempvar combo
            quietly egen `combo' = group(`a' ANIO_) if `touse'

            if "`stat'" == "mean" {
                capture noisily svy: mean `varname' if `touse', over(`combo')
            }
            else if "`stat'" == "total" {
                capture noisily svy: total `varname' if `touse', over(`combo')
            }
            else if "`stat'" == "ratio" {
                capture noisily svy: ratio `varname'/`denominator' if `touse', over(`combo')
            }
            else {
                capture noisily svy: proportion `varname' if `touse', over(`combo')
            }
            if _rc {
                di as err "tsvy: svy fallo (rc=" _rc ") para el over(`a' ANIO_) " ///
                    "conjunto -- se saltan los " `n_niveles' " bloque(s) de `a'" ///
                    " (revise el diseno/datos)"
                local bloques_saltados = `bloques_saltados' + `n_niveles'
                continue
            }

            tempname B_all V_all
            matrix `B_all' = e(b)
            matrix `V_all' = e(V)
            local df_r = e(df_r)
            if "`df_r'" == "" {
                di as err "tsvy: e(df_r) no disponible tras el svy -- revisar version de Stata/diseno"
                exit 498
            }
            tempname Nmat_all Nsubpmat_all Rtable_all
            capture matrix `Nmat_all' = e(_N)
            capture matrix `Nsubpmat_all' = e(_N_subp)
            capture matrix `Rtable_all' = r(table)

            * `k_total' (numero de categorias distintas de `combo') se
            * calcula con levelsof, NO con colsof(e(b)) -- para
            * stat(proportion), e(b) trae una ECUACION por cada valor de
            * `varname' concatenada en la misma fila, asi que
            * colsof(e(b)) séria k_total*num_ecuaciones, no k_total solo.
            * Mismo criterio que usa svylet.ado en su propio comando (ahi
            * tambien sale de levelsof sobre la variable de over(), nunca
            * de colsof de la matriz).
            quietly levelsof `combo' if `touse', local(niveles_combo)
            local k_total : word count `niveles_combo'

            * Misma logica que _svylet_seleccionar en svylet.ado, duplicada
            * aca EN LINEA en vez de llamada como subrutina de otro archivo
            * -- ver nota v1.4 de mas arriba (junto a la definicion de
            * tsvy_core()) sobre por que.
            tempname b_sel_all V_sel_all
            local idx_usar_all ""
            if "`stat'" == "proportion" {
                * e(b) trae una ECUACION por cada valor de `varname', y
                * DENTRO de cada ecuacion, una columna por categoria de
                * over() (`combo' aca). Se identifica la ecuacion de
                * `level' por el texto del value label, por "_prop_N"
                * (posicion ordinal, sin label), o por el codigo numerico
                * plano -- mismo criterio que svylet.ado.
                local vallab : value label `varname'
                local buscado_label ""
                if "`vallab'" != "" {
                    local buscado_label : label `vallab' `level'
                }
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

                local ecuaciones : coleq `B_all'
                local i = 0
                foreach eq of local ecuaciones {
                    local i = `i' + 1
                    if "`eq'" == "`buscado_label'" | "`eq'" == "`buscado_ordinal'" ///
                        | "`eq'" == "`buscado_numerico'" {
                        local idx_usar_all "`idx_usar_all' `i'"
                    }
                }
                if wordcount("`idx_usar_all'") != `k_total' {
                    di as err "tsvy: no se pudieron identificar exactamente " `k_total' ///
                        " filas para el valor " "`level'" " de " "`varname'" " en e(b) " ///
                        "(over(`a' ANIO_) conjunto)."
                    di as err "  buscado como texto de label: " "`buscado_label'"
                    di as err "  buscado como ordinal sin label: " "`buscado_ordinal'"
                    di as err "  buscado como codigo numerico plano: " "`buscado_numerico'"
                    di as err "  filas encontradas: " wordcount("`idx_usar_all'") " de " `k_total' " esperadas"
                    di as err "  ajustar level() si el valor de exito no es 1."
                    exit 498
                }
            }
            else {
                forvalues i = 1/`k_total' {
                    local idx_usar_all "`idx_usar_all' `i'"
                }
            }

            matrix `b_sel_all' = J(`k_total', 1, .)
            matrix `V_sel_all' = J(`k_total', `k_total', 0)
            local fila = 0
            foreach i of local idx_usar_all {
                local fila = `fila' + 1
                matrix `b_sel_all'[`fila', 1] = `B_all'[1, `i']
                local col = 0
                foreach j of local idx_usar_all {
                    local col = `col' + 1
                    matrix `V_sel_all'[`fila', `col'] = `V_all'[`i', `j']
                }
            }

            * N ponderado/sin ponderar y limites de IC por categoria de
            * `combo', en el orden de `idx_usar_all' -- mismo patron que
            * usa svylet.ado internamente, con el mismo swap e(_N) <->
            * e(_N_subp) del fix de N_PONDERA/N_SIN_PON: e(_N) es el
            * tamano SIN ponderar y e(_N_subp) el PONDERADO (ver nota en
            * svylet.ado, seccion "tempname Nmat Nsubpmat Rtable").
            tempname Nout_sinpon_all Nout_pond_all LIout_all LSout_all
            matrix `Nout_sinpon_all' = J(`k_total', 1, .)
            matrix `Nout_pond_all'   = J(`k_total', 1, .)
            matrix `LIout_all'       = J(`k_total', 1, .)
            matrix `LSout_all'       = J(`k_total', 1, .)
            local fila = 0
            foreach i of local idx_usar_all {
                local fila = `fila' + 1
                capture matrix `Nout_sinpon_all'[`fila', 1] = `Nmat_all'[1, `i']
                capture matrix `Nout_pond_all'[`fila', 1]   = `Nsubpmat_all'[1, `i']
                capture matrix `LIout_all'[`fila', 1]       = `Rtable_all'["ll", `i']
                capture matrix `LSout_all'[`fila', 1]       = `Rtable_all'["ul", `i']
            }

            * Chequeo defensivo: `combo' deberia ser una secuencia DENSA
            * 1..`k_total' (min=1, max=k_total, sin huecos) -- es la
            * garantia de egen group() de la que depende todo el corte
            * por bloques mas abajo (rango contiguo de columnas por
            * valor de `a'). Si no se cumple, es mas seguro cortar ahi
            * que seguir con indices desalineados.
            quietly summarize `combo' if `touse', meanonly
            if r(min) != 1 | r(max) != `k_total' {
                di as err "tsvy: `combo' (group de `a' x ANIO_) no es una secuencia " ///
                    "densa 1..`k_total' (min=" r(min) " max=" r(max) ") -- no deberia " ///
                    "pasar, revise version de Stata/datos."
                exit 498
            }

            foreach cval of local niveles_caida {
                quietly summarize `combo' if `a' == `cval' & `touse', meanonly
                local start_pos = r(min)
                local end_pos   = r(max)
                local k_cat = `end_pos' - `start_pos' + 1

                quietly levelsof ANIO_ if `a' == `cval' & `touse', local(anios_este_cval)
                if wordcount("`anios_este_cval'") != `k_cat' {
                    di as err "tsvy: no se pudo alinear el bloque de `a'=`cval' contra " ///
                        "ANIO_ (`k_cat' posicion(es) vs " wordcount("`anios_este_cval'") ///
                        " anio(s)) -- revise los datos."
                    exit 498
                }

                if `k_cat' < 2 {
                    di as err "tsvy: se salta `a'=`cval' -- necesita al menos 2 anios" ///
                        " con datos (tiene `k_cat')."
                    local bloques_saltados = `bloques_saltados' + 1
                    continue
                }

                tempname bmat Vmat nspmat npmat limat lsmat
                mata: st_matrix("`bmat'", st_matrix("`b_sel_all'")[(`start_pos'::`end_pos'), 1])
                mata: st_matrix("`Vmat'", st_matrix("`V_sel_all'")[(`start_pos'::`end_pos'), (`start_pos'::`end_pos')])
                mata: st_matrix("`nspmat'", st_matrix("`Nout_sinpon_all'")[(`start_pos'::`end_pos'), 1])
                mata: st_matrix("`npmat'", st_matrix("`Nout_pond_all'")[(`start_pos'::`end_pos'), 1])
                mata: st_matrix("`limat'", st_matrix("`LIout_all'")[(`start_pos'::`end_pos'), 1])
                mata: st_matrix("`lsmat'", st_matrix("`LSout_all'")[(`start_pos'::`end_pos'), 1])

                mata: tsvy_core("`bmat'", "`Vmat'", `df_r', `alpha', `k_cat')
                local F_omni = r(F_omnibus)
                local p_omni = r(p_omnibus)
                forvalues i = 1/`k_cat' {
                    local letra_`i'  "`r(letra_`i')'"
                    local codigo_`i' : word `i' of `anios_este_cval'
                }

                * -- v1.4 -- refyear(): igual idea que ref() en svylet.ado
                * (k-1 contrastes vs una categoria base, Bonferroni sobre
                * k-1), pero armado con llamadas mata: de UNA linea cada
                * una (vectorizadas, sin loop), en vez de definir una
                * funcion mata nueva -- ver nota v1.4 de cabecera sobre
                * por que una funcion mata no puede vivir dentro de
                * "program define tsvy". `refpos_local' es la posicion
                * DENTRO de este bloque (`a'=`cval') del anio base --
                * puede no estar presente en TODOS los bloques (un
                * dominio chico podria no tener datos justo del anio
                * base), en cuyo caso P_VS_REF queda en missing para ese
                * bloque.
                tempname pvsrefmat
                matrix `pvsrefmat' = J(`k_cat', 1, .)
                local refpos_local = 0
                if `refcode' != . {
                    local j = 0
                    foreach code of local anios_este_cval {
                        local j = `j' + 1
                        if `code' == `refcode' local refpos_local = `j'
                    }
                }
                if `refpos_local' > 0 {
                    tempname vdiag vrefcol vse vt vpraw
                    mata: st_matrix("`vdiag'", diagonal(st_matrix("`Vmat'")))
                    mata: st_matrix("`vrefcol'", st_matrix("`Vmat'")[.,`refpos_local'])
                    mata: st_matrix("`vse'", sqrt(st_matrix("`vdiag'") :+ st_matrix("`vdiag'")[`refpos_local',1] :- 2:*st_matrix("`vrefcol'")))
                    mata: st_matrix("`vt'", (st_matrix("`bmat'") :- st_matrix("`bmat'")[`refpos_local',1]) :/ st_matrix("`vse'"))
                    mata: st_matrix("`vpraw'", 2:*ttail(`df_r', abs(st_matrix("`vt'"))) :* (`k_cat'-1))
                    mata: st_matrix("`pvsrefmat'", rowmin((st_matrix("`vpraw'"), J(`k_cat',1,1))))
                    matrix `pvsrefmat'[`refpos_local', 1] = .
                }

                di as text _n "{hline 70}"
                di as text "tsvy (over conjunto) -- `stat' de `varname', `a'=`cval', over(ANIO_)"
                di as text "{hline 70}"
                if `F_omni' == . {
                    di as err "  F no calculable -- ver aviso arriba (varianza no definida en alguna categoria)."
                }
                else {
                    di as text "  F(" %3.0f `=`k_cat'-1' ", " %6.0f `=`df_r'-(`k_cat'-1)+1' ") = " ///
                        as res %9.4f `F_omni' as text "   Prob > F = " as res %6.4f `p_omni'
                }

                capture frame drop FILAS_TMP
                frame create FILAS_TMP
                frame FILAS_TMP {
                    quietly set obs `k_cat'
                    gen str12  NIVEL      = subinstr("`a'", "_", "", .)
                    gen double CAIDA      = `cval'
                    gen byte   ANIO       = .
                    gen double ESTIMA     = .
                    gen double ERROR_ST   = .
                    gen double LIM_INF    = .
                    gen double LIM_SUP    = .
                    gen double N_SIN_PON  = .
                    gen double N_PONDERA  = .
                    gen double F_WALD     = `F_omni'
                    gen double P_WALD     = `p_omni'
                    gen str5   GRUPO      = ""
                    gen double P_VS_REF   = .
                    gen str3   SIG_VS_REF = ""
                    gen byte   var        = 1

                    forvalues i = 1/`k_cat' {
                        local pos = 0
                        local j = 0
                        foreach code of local codigos_anio {
                            local j = `j' + 1
                            if `code' == `codigo_`i'' local pos = `j'
                        }
                        if `pos' == 0 {
                            di as err "tsvy: no se pudo mapear el codigo de ANIO_ " ///
                                "`codigo_`i'' contra codigos_anio (`codigos_anio') -- revise years()."
                            exit 498
                        }
                        local yval : word `pos' of `years'

                        quietly replace ANIO      = `yval'                    in `i'
                        quietly replace ESTIMA    = el(`bmat', `i', 1)        in `i'
                        quietly replace ERROR_ST  = sqrt(el(`Vmat', `i', `i')) in `i'
                        quietly replace LIM_INF   = el(`limat', `i', 1)       in `i'
                        quietly replace LIM_SUP   = el(`lsmat', `i', 1)       in `i'
                        quietly replace N_SIN_PON = el(`nspmat', `i', 1)      in `i'
                        quietly replace N_PONDERA = el(`npmat', `i', 1)       in `i'
                        quietly replace GRUPO     = "`letra_`i''"             in `i'
                        quietly replace P_VS_REF  = el(`pvsrefmat', `i', 1)   in `i'
                    }
                    gen double CV = (ERROR_ST / ESTIMA) * 100
                    gen str2 REF_ = ""
                    replace REF_ = "a/" if CV > `threshold' & CV != .
                    replace SIG_VS_REF = "*"   if P_VS_REF < 0.10 & P_VS_REF != .
                    replace SIG_VS_REF = "**"  if P_VS_REF < 0.05 & P_VS_REF != .
                    replace SIG_VS_REF = "***" if P_VS_REF < 0.01 & P_VS_REF != .
                }
                frame `frame': frameappend FILAS_TMP
                capture frame drop FILAS_TMP
                local bloques_ok = `bloques_ok' + 1
            }
            continue
        }

        * ----------------------------------------------------------------
        * Camino VIEJO (boot()>0 o sexovar()!="") -- sin cambios de fondo
        * respecto a v1.3: filtra "if `a'==`cval' [& `sexovar'==`sval']"
        * y corre svylet ..., over(ANIO_) para cada bloque por separado.
        * Ver nota v1.4 de cabecera sobre por que el camino nuevo no
        * cubre estos dos casos todavia.
        * ----------------------------------------------------------------
        foreach cval of local niveles_caida {

            local niveles_sexo "."
            if "`sexovar'" != "" {
                local cond_niv "`a' == `cval' & `touse'"
                quietly levelsof `sexovar' if `cond_niv', local(niveles_sexo)
            }

            foreach sval of local niveles_sexo {
                local subset "`a' == `cval' & `touse'"
                if "`sexovar'" != "" local subset "`subset' & `sexovar' == `sval'"

                * refopt() es GLOBAL a toda la corrida de tsvy, pero un
                * bloque (`a'=`cval' [`sexovar'=`sval']) chico podria no
                * tener datos justo del anio de refyear() -- svylet.ado
                * corta con error duro si se le pasa un ref() que no esta
                * entre las categorias de ESE over() especifico (correcto
                * para una llamada directa de un usuario, pero rompería
                * el loop aca). Por eso se arma `refopt_bloque' recien
                * aca, verificando PRIMERO si refcode esta presente en
                * este bloque puntual -- si no esta, se omite ref() SOLO
                * para este bloque (P_VS_REF queda missing ahi), sin
                * saltarse el resto del bloque.
                local refopt_bloque ""
                if "`refopt'" != "" {
                    quietly count if `subset' & ANIO_ == `refcode'
                    if r(N) > 0 local refopt_bloque "`refopt'"
                }

                capture noisily svylet `varname' if `subset', over(ANIO_) ///
                    stat(`stat') level(`level') denominator(`denominator') ///
                    alpha(`alpha') boot(`boot') bseed(`bseed') `refopt_bloque'
                if _rc {
                    di as err "tsvy: svylet fallo (rc=" _rc ") para " ///
                        "`a'=`cval'" cond("`sexovar'"!="", " `sexovar'=`sval'", "") ///
                        " -- se salta este bloque (revise si tiene al menos 2 anios con datos)"
                    local bloques_saltados = `bloques_saltados' + 1
                    continue
                }

                tempname bmat Vmat nspmat npmat limat lsmat pvsrefmat
                matrix `bmat'   = r(b)
                matrix `Vmat'   = r(V)
                matrix `nspmat' = r(n_sin_ponderar)
                matrix `npmat'  = r(n_ponderado)
                matrix `limat'  = r(ci_lower)
                matrix `lsmat'  = r(ci_upper)
                matrix `pvsrefmat' = r(p_vsref)
                local F_omni = r(F_omnibus)
                local p_omni = r(p_omnibus)
                local k_cat  = r(k_categorias)
                forvalues i = 1/`k_cat' {
                    local letra_`i'  "`r(letra_`i')'"
                    local codigo_`i' "`r(nombre_categoria_`i')'"
                }

                capture frame drop FILAS_TMP
                frame create FILAS_TMP
                frame FILAS_TMP {
                    quietly set obs `k_cat'
                    gen str12  NIVEL      = subinstr("`a'", "_", "", .)
                    gen double CAIDA      = `cval'
                    gen byte   ANIO       = .
                    gen double ESTIMA     = .
                    gen double ERROR_ST   = .
                    gen double LIM_INF    = .
                    gen double LIM_SUP    = .
                    gen double N_SIN_PON  = .
                    gen double N_PONDERA  = .
                    gen double F_WALD     = `F_omni'
                    gen double P_WALD     = `p_omni'
                    gen str5   GRUPO      = ""
                    gen double P_VS_REF   = .
                    gen str3   SIG_VS_REF = ""
                    gen byte   var        = 1
                    if "`sexovar'" != "" {
                        gen double SEXO = `sval'
                    }

                    forvalues i = 1/`k_cat' {
                        * `codigo_`i'' es el codigo REAL de ANIO_ para esta
                        * categoria (r(nombre_categoria_i), devuelto por
                        * svylet) -- se mapea contra years() por POSICION
                        * ascendente dentro de codigos_anio, igual criterio
                        * que tabsvy: no se decodifica contra el value label
                        * de ANIO_ (mas fragil), se usa el orden cronologico
                        * que el propio usuario declaro en years().
                        local pos = 0
                        local j = 0
                        foreach code of local codigos_anio {
                            local j = `j' + 1
                            if `code' == `codigo_`i'' local pos = `j'
                        }
                        if `pos' == 0 {
                            di as err "tsvy: no se pudo mapear el codigo de ANIO_ " ///
                                "`codigo_`i'' contra codigos_anio (`codigos_anio') -- revise years()."
                            exit 498
                        }
                        local yval : word `pos' of `years'

                        quietly replace ANIO      = `yval'                    in `i'
                        quietly replace ESTIMA    = el(`bmat', `i', 1)        in `i'
                        quietly replace ERROR_ST  = sqrt(el(`Vmat', `i', `i')) in `i'
                        quietly replace LIM_INF   = el(`limat', `i', 1)       in `i'
                        quietly replace LIM_SUP   = el(`lsmat', `i', 1)       in `i'
                        quietly replace N_SIN_PON = el(`nspmat', `i', 1)      in `i'
                        quietly replace N_PONDERA = el(`npmat', `i', 1)       in `i'
                        quietly replace GRUPO     = "`letra_`i''"             in `i'
                    }
                    gen double CV = (ERROR_ST / ESTIMA) * 100
                    gen str2 REF_ = ""
                    replace REF_ = "a/" if CV > `threshold' & CV != .
                }
                frame `frame': frameappend FILAS_TMP
                capture frame drop FILAS_TMP
                local bloques_ok = `bloques_ok' + 1
            }
        }
    }

    frame `frame' {
        count
        di as text "tsvy: `frame' acumula ahora " as result r(N) as text ///
            " filas (VARNAME=`varname' STAT=`stat', " as result `bloques_ok' ///
            as text " bloques estimados, " as result `bloques_saltados' ///
            as text " saltados)"
    }
end

* -------------------------------------------------------------------------
* v1.4 -- tsvy_core(): copia PROPIA (autosuficiente, ver nota junto al
* "foreach a of local caida" en el cuerpo de "program define tsvy") del
* motor F omnibus + Bonferroni + Compact Letter Display de svylet.ado
* (svylet_core(), en svylet.ado). Debe vivir ACA, a nivel de archivo
* (fuera de cualquier "program define"), porque Mata no permite
* compilar una definicion de funcion dentro del cuerpo de un programa
* Stata (r(9611) si se intenta). Si el motor de svylet_core() cambia,
* replicar el cambio aca tambien.
* -------------------------------------------------------------------------
version 14
* "capture" ACA (a nivel Stata, antes de entrar al bloque mata:), no
* adentro del bloque -- un "mata drop" de una funcion que todavia no
* existe (la PRIMERA vez que este archivo se carga en la sesion) tira
* error, y adentro del bloque mata: ese error no lo atrapa ningun
* "capture" (ya se dejo de estar en modo Stata) -- cortaria la carga
* del archivo antes de llegar siquiera a la definicion de la funcion.
capture mata: mata drop tsvy_core()
mata:

void tsvy_core(string scalar bname, string scalar Vname, real scalar df,
                real scalar alpha, real scalar k)
{
    real matrix b, V, R, RVR, Pmat
    real scalar stat_wald, Fstat, p_omni, i, j, npares, t, se, p_raw, p_adj
    real scalar k_dim, df_ajustado

    b = st_matrix(bname)
    V = st_matrix(Vname)

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

    npares = k*(k-1)/2
    Pmat = J(k,k,.)
    for (i=1; i<=k-1; i++) {
        for (j=i+1; j<=k; j++) {
            if (var_degenerada[i]==1 | var_degenerada[j]==1) {
                p_adj = .
                Pmat[i,j] = p_adj
                Pmat[j,i] = p_adj
                continue
            }
            se = sqrt(V[i,i] + V[j,j] - 2*V[i,j])
            if (se > 0) {
                t = (b[j]-b[i]) / se
                p_raw = 2*ttail(df, abs(t))
                p_adj = min((p_raw*npares, 1))
            }
            else {
                p_adj = 1
            }
            Pmat[i,j] = p_adj
            Pmat[j,i] = p_adj
        }
    }

    string colvector letra_grupo
    letra_grupo = J(k,1,"")
    real scalar total_subsets, s, bitpos, ok, contenido, letra_idx, g
    real colvector miembros
    real matrix subsets_validos, maximales
    string scalar letra_actual
    subsets_validos = J(0, k, .)

    total_subsets = 2^k - 1
    for (s=total_subsets; s>=1; s--) {
        miembros = J(k,1,0)
        for (bitpos=1; bitpos<=k; bitpos++) {
            if ( mod(floor(s / 2^(bitpos-1)), 2) == 1 ) miembros[bitpos] = 1
        }
        if (sum(miembros) < 1) continue
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

    maximales = J(0,k,.)
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
        letra_actual = char(96 + letra_idx)
        for (i=1; i<=k; i++) {
            if (maximales[g,i]==1) letra_grupo[i] = letra_grupo[i] + letra_actual
        }
    }

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
