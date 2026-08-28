{smcl}
{* *! version 1.6.0  26aug2026}{...}
{vieweralsosee "svylet" "help svylet_es"}{...}
{vieweralsosee "tsvy (English)" "help tsvy"}{...}
{viewerjumpto "Sintaxis" "tsvy_es##syntax"}{...}
{viewerjumpto "Descripcion" "tsvy_es##description"}{...}
{viewerjumpto "Opciones" "tsvy_es##options"}{...}
{viewerjumpto "Comentarios" "tsvy_es##remarks"}{...}
{viewerjumpto "Ejemplos" "tsvy_es##examples"}{...}
{viewerjumpto "Estructura del frame" "tsvy_es##frame"}{...}
{viewerjumpto "Referencias" "tsvy_es##references"}{...}
{viewerjumpto "Autor" "tsvy_es##author"}{...}
{viewerjumpto "Vea tambien" "tsvy_es##also_see"}{...}
{hline}
{title:Titulo}

{phang}
{bf:tsvy} {hline 2} Tabla de estimaciones puntuales y test de
Wald/Bonferroni/CLD, por nivel de agregacion y anio, usando
{helpb svylet_es} como motor de estimacion


{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:tsvy}
{ifin}{cmd:,}
{cmdab:varn:ame(}{it:varname}{cmd:)}
{cmdab:years:(}{it:numlist}{cmd:)}
{cmdab:stat:(}{it:statname}{cmd:)}
[{it:opciones}]

{pstd}
donde {it:statname} es una de {cmd:mean}, {cmd:total}, {cmd:proportion},
o {cmd:ratio}.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Principales}
{synopt:{opt varn:ame(varname)}}variable de analisis; requerida. El
numerador, cuando {cmd:stat(ratio)}{p_end}
{synopt:{opt years(numlist)}}anios calendario realmente presentes en
{cmd:ANIO_} en los datos actuales, en orden ascendente; requerida{p_end}
{synopt:{opt stat(statname)}}estadistico a estimar y testear:
{cmd:mean}, {cmd:total}, {cmd:proportion}, o {cmd:ratio}; requerida{p_end}
{synopt:{opt caida(varlist)}}variables que definen los niveles de
agregacion sobre los que hacer el loop; por defecto
{cmd:caida(NACIONAL REGION NOMBREDD_)}{p_end}
{synopt:{opt sexovar(varname)}}una variable de cruce adicional (por
ejemplo, sexo); si se da, se estima y testea por separado cada
combinacion de valor de {cmd:caida()} x valor de {it:sexovar}{p_end}
{synopt:{opt l:evel(#)}}ver {helpb svylet_es}; solo importa con
{cmd:stat(proportion)}; por defecto {cmd:level(1)}{p_end}
{synopt:{opt d:enominator(varname)}}ver {helpb svylet_es}; requerida con
{cmd:stat(ratio)}, se ignora en cualquier otro caso{p_end}
{synopt:{opt expectcats(numlist)}}categorias que {it:varname} deberia
tomar; {cmd:tsvy} se detiene antes de estimar nada si las
categorias observadas no coinciden exactamente{p_end}

{syntab:Passthrough a svylet}
{synopt:{opt a:lpha(#)}}ver {helpb svylet_es}; por defecto
{cmd:alpha(0.05)}{p_end}
{synopt:{opt boot(#)}}ver {helpb svylet_es}; por defecto {cmd:boot(0)}{p_end}
{synopt:{opt bseed(#)}}ver {helpb svylet_es}{p_end}

{syntab:Vs-una-referencia (opcional)}
{synopt:{opt refyear(#)}}anio calendario (uno de {cmd:years()}) a usar
como base fija. Agrega las columnas {cmd:P_VS_REF}/{cmd:SIG_VS_REF},
comparando CADA anio contra {cmd:refyear()} (Bonferroni sobre {it:k}-1
comparaciones) -- una pregunta DISTINTA de {cmd:GRUPO} (CLD de todos los
pares); ver {help svylet_es##remarks_ref:Comentarios en svylet_es.sthlp}{p_end}

{syntab:Salida}
{synopt:{opt frame(name)}}frame acumulador; por defecto
{cmd:frame(ACUM_ALL)}{p_end}
{synopt:{opt threshold(#)}}umbral de CV(%) por encima del cual una fila
se marca {cmd:REF_ = "a/"}; por defecto {cmd:threshold(15)}{p_end}
{synopt:{opt replace}}elimina y recrea el frame acumulador en vez de
agregarle filas{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:varname} debe existir en los datos actuales; tambien debe existir una
variable llamada literalmente {cmd:ANIO_} (la variable que
{cmd:tsvy} pasa como {cmd:over()} en cada llamada a
{helpb svylet_es}). El dataset ya debe estar declarado con
{helpb svyset}, igual que para {helpb svylet_es}.

{pstd}
{bf:Requiere Stata 16.0 o superior.} {cmd:tsvy} acumula su salida con
{helpb frame:frames} ({cmd:frame create}, {cmd:frame }{it:nombre}{cmd::}),
una funcionalidad introducida en Stata 16; no corre en Stata 14 o 15.
{helpb svylet_es} en si no depende de frames y corre desde Stata 14 en
adelante.


{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:tsvy} arma, en una sola pasada, la tabla que normalmente
necesita quien trabaja con cortes transversales repetidos u olas panel de
una encuesta compleja: estimaciones puntuales desagregadas por nivel de
agregacion (nacional, regional, local, ...) y por anio, {it:junto con} un
test de si la estimacion de cada nivel realmente cambio de un anio a
otro. Recorre cada nivel de agregacion nombrado en {cmd:caida()},
corriendo el mismo calculo de F omnibus/Bonferroni/CLD que
{helpb svylet_es} una vez por combinacion (nivel x valor x [valor de
{cmd:sexovar}]), y acumula una fila por anio en un frame listo para
{cmd:reshape wide} y exportar -- asi que la tabla de puntos y el test
F/Bonferroni/CLD salen de la misma llamada, sin una pasada separada que
haya que mantener alineada a mano. Si ese calculo por bloque es una
llamada literal al comando {cmd:svylet}, o la misma logica corrida en
linea, depende de cual de los dos caminos internos de {cmd:tsvy} toma
una llamada dada -- ver {help tsvy_es##remarks_limits:Comentarios} mas
abajo.

{pstd}
{cmd:tsvy} es un companero de
{browse "https://github.com/atalaveracuya/tabsvy":tabsvy}/{cmd:tabsvyexport}
(una herramienta separada, de proposito general, del mismo autor, que
sigue el mismo diseno de recorrer-y-acumular, pero corre
{cmd:svy: + parmby} en cada nivel -- solo estimaciones puntuales, sin
test entre anios). Si usa {cmd:tabsvy} y ademas necesita saber si los
anios son significativamente distintos entre si dentro de cada nivel,
{cmd:tsvy} es la misma idea con {helpb svylet_es} como motor; si
nunca uso {cmd:tabsvy}, {cmd:tsvy} funciona solo, sin necesitar nada
de ese repositorio.

{pstd}
{cmd:tsvy} {it:no} modifica ni depende del codigo interno de
{cmd:tabsvy.ado} -- vive en el repositorio de {cmd:svylet} porque
{helpb svylet_es} es el motor que necesita. Si resulta util, integrarlo
dentro de {cmd:tabsvy} mismo como un motor alternativo es un paso natural
a futuro (ver {cmd:AUDIT.md} en el repositorio de {cmd:svylet}), pero eso
requiere acceso de escritura al repositorio de {cmd:tabsvy} que este
comando no asume.


{marker options}{...}
{title:Opciones}

{dlgtab:Principales}

{phang}
{opt varname(varname)} es la unica variable de analisis, exactamente
como en {helpb svylet_es}: no un {it:varlist}. Para tabular varias
variables, llame a {cmd:tsvy} una vez por variable, hacia el mismo
{cmd:frame()} (ver {help tsvy_es##examples:Ejemplos}).

{phang}
{opt years(numlist)} lista los anios calendario reales presentes en
{cmd:ANIO_} en los datos {it:actuales}, en orden cronologico ascendente
-- no se asume que van de 1 a k sin huecos. {cmd:tsvy} lee los
codigos distintos que realmente tiene {cmd:ANIO_} con {helpb levelsof} y
los mapea, por posicion ascendente, uno a uno contra {cmd:years()}; se
detiene con un error si las cantidades no coinciden. Esto sigue la misma
logica de {cmd:years()} que ya tiene {cmd:tabsvy} (desde su v1.3), asi
que una base a la que le falta un anio entero se maneja simplemente
listando los anios que {it:si} estan presentes, sin decodificar el value
label de {cmd:ANIO_}.

{phang}
{opt stat(statname)} se pasa directo a {helpb svylet_es}: {cmd:mean},
{cmd:total}, {cmd:proportion}, o {cmd:ratio}.

{phang}
{opt caida(varlist)} lista las variables cuyos valores distintos definen
los niveles de agregacion sobre los que hacer el loop -- por ejemplo, una
variable constante {cmd:NACIONAL} (ver
{help tsvy_es##remarks:Comentarios}), un codigo de region, un codigo
de departamento. Por defecto {cmd:caida(NACIONAL REGION NOMBREDD_)},
igual que el default de {cmd:tabsvy} y la convencion que documenta (una
variable {cmd:NACIONAL} igual a 1 para toda observacion, que representa
"sin desagregar"). Cada valor distinto de cada variable en {cmd:caida()}
obtiene su propio bloque de filas en la salida.

{phang}
{opt sexovar(varname)} agrega una segunda variable de cruce: en vez de
una llamada a {helpb svylet_es} por valor de {cmd:caida()},
{cmd:tsvy} la llama una vez por combinacion (valor de {cmd:caida()},
valor de {it:sexovar}), y agrega una columna {cmd:SEXO} al frame
acumulador.

{phang}
{opt level(#)}, {opt denominator(varname)}, y {opt alpha(#)} se pasan
directo a {helpb svylet_es}; ver ahi. {opt denominator()} es requerida
con {cmd:stat(ratio)}.

{phang}
{opt expectcats(numlist)} declara, de entrada, que categorias deberia
tomar {it:varname} (por ejemplo, {cmd:expectcats(1 2)} para un indicador
dicotomico). Si las categorias realmente observadas en los datos no
coinciden exactamente, {cmd:tsvy} se detiene antes de estimar nada,
la misma validacion temprana que hace {cmd:tabsvy} con su propio
{cmd:expectcats()}.

{dlgtab:Passthrough a svylet}

{phang}
{opt boot(#)} y {opt bseed(#)} se pasan directo a cada llamada de
{helpb svylet_es}; ver ahi, incluyendo los requisitos de diseno para
{cmd:boot()} (hace falta declarar tanto una UPM {it:como} un estrato en
el {helpb svyset} actual).

{dlgtab:Salida}

{phang}
{opt frame(name)} nombra el frame acumulador. Si todavia no existe, se
crea; las filas existentes se conservan (y se agregan las nuevas) salvo
que tambien se de {opt replace}.

{phang}
{opt threshold(#)} es el umbral del coeficiente de variacion (en
porcentaje) por encima del cual la columna {cmd:REF_} de una fila se fija
en {cmd:"a/"}, una marca comun para una estimacion demasiado imprecisa
(alta variabilidad muestral) para reportar con confianza.

{phang}
{opt replace} elimina y recrea {cmd:frame()} en vez de agregarle filas a
lo que ya tenga. Usela en la primera llamada de una secuencia (ver
{help tsvy_es##examples:Ejemplos}); omitala en las llamadas
siguientes que deban acumularse en el mismo frame.


{marker remarks}{...}
{title:Comentarios y ejemplos}

{pstd}
Los comentarios se presentan bajo los siguientes titulos:

{phang2}{help tsvy_es##remarks_nacional:La convencion NACIONAL}{p_end}
{phang2}{help tsvy_es##remarks_limits:Diferencias con tabsvy, y limitaciones actuales}{p_end}

{marker remarks_nacional}{...}
{pstd}{bf:La convencion NACIONAL}

{pstd}
El {cmd:caida()} por defecto de {cmd:tsvy} espera una variable
llamada literalmente {cmd:NACIONAL}, constante en 1 para toda
observacion, igual que documenta el propio README de {cmd:tabsvy}
({cmd:gen NACIONAL = 1}). Esto es lo que permite que un solo loop
{cmd:caida("NACIONAL REGION NOMBREDD_")} produzca un bloque "nacional"
(un unico valor, sin desagregacion real) junto a desagregaciones
genuinas de region/departamento, usando el mismo mecanismo para ambas
cosas.

{marker remarks_limits}{...}
{pstd}{bf:Diferencias con tabsvy, y limitaciones actuales}

{phang2}o cada llamada a {helpb svylet_es} dentro de {cmd:tsvy}
necesita al menos 2 anios de datos para correr el test (requisito propio
de {cmd:svylet} sobre {cmd:over()}); un bloque de {cmd:caida()} x
[{cmd:sexovar}] con un solo anio de datos se salta con un aviso y no
aporta filas. {cmd:tabsvy} no tiene esta restriccion, porque no necesita
comparar anios entre si.{p_end}
{phang2}o {cmd:tsvy} todavia no tiene las opciones
{cmd:keepcat()}/{cmd:tipo()} de {cmd:tabsvy} para recorrer un bloque
tematico de varias variables indicadoras 0/1 a la vez. Si una tabla
necesita ese patron, siga usando {cmd:tabsvy} para eso, o llame a
{cmd:tsvy} una vez por indicador hacia el mismo {cmd:frame()} y
etiquete el bloque usted mismo (ver
{help tsvy_es##examples:Ejemplos}).{p_end}
{phang2}o {cmd:tsvy} requiere que la variable over() pasada
internamente a {helpb svylet_es} se llame exactamente {cmd:ANIO_}; no es
configurable.{p_end}
{phang2}o (v1.4) cuando {cmd:boot()} es 0 (el default) y no se paso
{cmd:sexovar()}, {cmd:tsvy} corre un solo
{cmd:svy: STAT ..., over(caida_var ANIO_)} conjunto por cada variable de
{cmd:caida()} -- el mismo comando que correria a mano para tener una
tabla de referencia -- en vez de filtrar a un valor de {cmd:caida()} por
vez y correr {cmd:over(ANIO_)} dentro de ese filtro. Esto importa para un
nivel que agrupa varias strata del diseno original (una region formada
por varios departamentos, por ejemplo): en datos reales de produccion,
filtrar primero daba un error estandar sistematicamente mas chico que el
de la llamada conjunta con {cmd:over()}, aunque la estimacion puntual
coincidiera exacto de las dos formas. {cmd:boot()>0} y {cmd:sexovar()}
todavia usan el camino viejo de filtrar y despues {cmd:over(ANIO_)}.{p_end}
{phang2}o solo el camino VIEJO (el de justo arriba --
{cmd:boot()>0}/{cmd:sexovar()}) hace una llamada literal al comando
{cmd:svylet}, una vez por (valor de {cmd:caida()} x [valor de
{cmd:sexovar}]). El camino por defecto de {cmd:over()} conjunto NO
llama a {cmd:svylet} -- corre {cmd:svy:} directo y calcula el F
omnibus/Bonferroni/CLD con su propia copia del mismo motor Mata, para
que {cmd:tsvy.ado} no dependa de que {cmd:svylet} se haya invocado
directo antes en la misma sesion para que sus subrutinas queden
cargadas (ver la nota v1.4 en el encabezado de {cmd:tsvy.ado} para el
por que). Los dos caminos implementan la misma matematica exacta y dan
resultados identicos -- esto solo importa si esta, por ejemplo,
rastreando llamadas con {cmd:trace on} o revisando puntualmente si
{cmd:svylet} en si corrio.{p_end}


{marker examples}{...}
{title:Ejemplos}

{pstd}
El script de abajo (preparacion + ejemplos 1-5) esta confirmado corriendo
de punta a punta sin error en Stata real. El {cmd:.} inicial antes de un
comando de una sola linea es el prompt de comando (convencion estandar de
los help files de Stata, no es parte del comando, y es seguro copiarlo
tal cual); las lineas dentro del bloque {cmd:foreach} del ejemplo 3 se
muestran sin el, porque un {cmd:.} dejado en cada linea de un bloque
{cmd:foreach}/{cmd:forvalues} de varias lineas -- incluido el cuerpo y la
llave de cierre -- rompe el parseo del bloque en Stata al pegarlo en un
do-file. Las lineas de comentario (que empiezan con {cmd:*}) no llevan
prompt de ningun modo; se muestran aca tal como quedarian en su propio
do-file.

{pstd}
Cada ejemplo de abajo es autocontenido y corre sobre {cmd:auto.dta}, uno
de los datasets de ejemplo incluidos en Stata -- alcanza con
{cmd:sysuse auto}, no hace falta ningun dato externo. Igual que con
{helpb svylet_es}, {cmd:auto.dta} no tiene un diseno de encuesta real,
asi que la preparacion de abajo es la minima que deja correr a
{cmd:tsvy} (cada observacion como su propia UPM); ver
{helpb svylet_es} para por que {cmd:_n} no se pasa directo a
{cmd:svyset}, y para un ejemplo de bootstrap con un diseno real de
conglomerados con varias filas. {cmd:auto.dta} tampoco tiene una variable
de anio, asi que {cmd:ANIO_} se fabrica solo para poder ejercitar la
mecanica a traves del tiempo -- en un uso real, {cmd:ANIO_} y la
convencion {cmd:NACIONAL} vienen de la misma preparacion que ya se usa
antes de llamar a {cmd:tabsvy} (ver su README).

{phang2}{cmd:* Preparacion}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen long psu_id = _n}{p_end}
{phang2}{cmd:. svyset psu_id}{p_end}
{phang2}{cmd:. gen byte NACIONAL = 1}{p_end}
{phang2}{cmd:. gen int ANIO_ = 2021 + mod(_n, 3)}{p_end}

{pstd}
{bf:Ejemplo 1: una llamada, varios niveles de agregacion.} {cmd:mean} de
{cmd:mpg}, tres niveles ({cmd:NACIONAL} y ambos valores de
{cmd:foreign}), tres anios cada uno -- estimaciones puntuales mas el test
F/Bonferroni/CLD entre anios, todo en un frame, una sola llamada:{p_end}
{phang2}{cmd:* Ejemplo 1: una llamada, varios niveles de agregacion}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:  caida(NACIONAL foreign) frame(F1) replace}{p_end}
{phang2}{cmd:. frame F1: list NIVEL CAIDA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CAIDA)}{p_end}

{pstd}
{bf:Ejemplo 2: {cmd:proportion}}, con {cmd:expectcats()} vigilando la
codificacion de la variable de analisis ({cmd:foreign} debe tomar
exactamente 0/1, o {cmd:tsvy} se detiene antes de estimar
nada):{p_end}
{phang2}{cmd:* Ejemplo 2: proportion, con expectcats()}{p_end}
{phang2}{cmd:. tsvy, varname(foreign) stat(proportion) level(1) ///}{p_end}
{phang2}{cmd:   years(2021 2022 2023) expectcats(0 1)  ///}{p_end}
{phang2}{cmd:   caida(NACIONAL) frame(F2) replace}{p_end}
{phang2}{cmd:. frame F2: list NIVEL CAIDA ANIO ESTIMA CV REF_ F_WALD P_WALD GRUPO}{p_end}

{pstd}
{bf:Ejemplo 3: {cmd:total}}, varias variables acumuladas en el mismo
frame ({cmd:replace} solo en la primera llamada -- este es el patron
para recorrer {cmd:tsvy} sobre muchas variables de analisis, tal
como un pipeline real lo recorre sobre muchos indicadores). Note que el
bloque {cmd:foreach} de abajo no lleva {cmd:.} inicial en ninguna de sus
lineas -- ver la nota al inicio de esta seccion sobre por que:{p_end}
{phang2}{cmd:* Ejemplo 3: total, varias variables en el mismo frame}{p_end}
{phang2}{cmd:local variables mpg weight length}{p_end}
{phang2}{cmd:local i = 0}{p_end}
{phang2}{cmd:foreach v of local variables {c 123}}{p_end}
{phang2}{cmd:local i = `i' + 1}{p_end}
{phang2}{cmd: tsvy, varname(`v') stat(total) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd: caida(NACIONAL) frame(F3) `=cond(`i'==1, "replace", "")'}{p_end}
{phang2}{cmd:{c 125}}{p_end}
{phang2}{cmd:frame F3: list NIVEL CAIDA ANIO ESTIMA F_WALD P_WALD GRUPO}{p_end}

{pstd}
{bf:Ejemplo 4: una segunda dimension de cruce} con {cmd:sexovar()} --
aca, una particion por precio hace de sustituto de una particion
demografica real como sexo:{p_end}
{phang2}{cmd:* Ejemplo 4: una segunda dimension de cruce con sexovar()}{p_end}
{phang2}{cmd:. gen byte grupo_precio = (price > 6000)}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:  caida(NACIONAL) sexovar(grupo_precio) frame(F4) replace}{p_end}
{phang2}{cmd:. frame F4: list NIVEL CAIDA SEXO ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CAIDA SEXO)}{p_end}

{pstd}
{bf:Ejemplo 5: {cmd:ratio}} -- {opt denominator()} es requerida, y es una
opcion aparte de {opt varname()} (el numerador), no una expresion
{cmd:num/den}:{p_end}
{phang2}{cmd:* Ejemplo 5: ratio -- denominator() es una opcion aparte}{p_end}
{phang2}{cmd:. tsvy, varname(trunk) stat(ratio) denominator(length) ///}{p_end}
{phang2}{cmd:years(2021 2022 2023) caida(NACIONAL foreign) frame(F5) replace}{p_end}
{phang2}{cmd:. frame F5: list NIVEL CAIDA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CAIDA)}{p_end}

{pstd}
{bf:Ejemplo 6: restringir el universo con {cmd:[if]}.} {cmd:tsvy}
acepta un {cmd:if} inicial igual que {cmd:svy:}, y lo pasa a cada llamada
a {helpb svylet} que el loop hace internamente -- no esta limitado al
cruce {cmd:caida()}/{cmd:sexovar()}. Usela cuando la estimacion deba
correr sobre una subpoblacion en vez de todo el dataset (por ejemplo,
solo los registros que pasan una condicion de elegibilidad o control de
calidad definida antes). Abajo, {cmd:rep78} viene missing en 5 autos de
{cmd:auto.dta}; restringir a {cmd:rep78 < .} los saca del universo antes
de estimar, igual que un pipeline real restringe a los registros que
pasan su propio filtro antes de llamar a {cmd:svy: total}:{p_end}
{phang2}{cmd:* Ejemplo 6: restringir el universo con [if]}{p_end}
{phang2}{cmd:. tsvy if rep78 < ., varname(weight) stat(total) ///}{p_end}
{phang2}{cmd:    years(2021 2022 2023) caida(NACIONAL foreign) frame(F6) replace}{p_end}
{phang2}{cmd:. frame F6: list NIVEL CAIDA ANIO ESTIMA F_WALD P_WALD GRUPO, sepby(NIVEL CAIDA)}{p_end}

{pstd}
{bf:Este {cmd:if} importa en cada llamada de un loop, no solo en la
primera.} Si su pipeline estima varios indicadores, cada uno bajo su
propia condicion de elegibilidad, ponga esa condicion en todas las
llamadas a {cmd:tsvy} dentro del loop -- {cmd:replace} sigue yendo
solo en la primera llamada, pero el {cmd:if} va en todas:{p_end}
{phang2}{cmd:. foreach v of local variables {c 123}}{p_end}
{phang2}{cmd:    local i = `i' + 1}{p_end}
{phang2}{cmd:    tsvy if elegible == 1 & control_calidad == 0, ///}{p_end}
{phang2}{cmd:        varname(`v') stat(total) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:        caida(NACIONAL) frame(F7) `=cond(`i'==1, "replace", "")'}{p_end}
{phang2}{cmd:{c 125}}{p_end}

{pstd}
El mismo patron escala directo a un pipeline real de encuesta compleja:
mantenga el loop {cmd:forvalues}/{cmd:foreach} del ejemplo 3, reemplace
{cmd:mpg weight length} por su propia lista de variables indicadoras,
agregue la condicion {cmd:if} que sus datos realmente necesiten (como en
el ejemplo 6), y reemplace {cmd:caida(NACIONAL foreign)} por las
variables de nivel de agregacion que realmente tengan sus datos (un total
nacional mas las variables tipo region/departamento que apliquen).{p_end}

{pstd}
{bf:Ejemplo 7: {cmd:refyear()} -- comparar cada anio contra UN anio
base.} {cmd:GRUPO} (usado en todos los ejemplos de arriba) responde
"que anios difieren ENTRE SI" -- todos los pares, Bonferroni sobre
{it:k}(k-1)/2 comparaciones. {cmd:refyear()} responde una pregunta mas
angosta y DISTINTA -- "que anios difieren de ESTE anio base" -- solo
{it:k}-1 comparaciones, Bonferroni sobre {it:k}-1 (Dunn 1961) -- y
agrega {cmd:P_VS_REF}/{cmd:SIG_VS_REF} al frame junto a (no en lugar de)
{cmd:GRUPO}. Las dos pueden legitimamente no coincidir sobre los mismos
datos porque testean familias distintas de hipotesis; ver
{help svylet_es##remarks_ref:Comentarios en svylet_es.sthlp} para el por
que, y para la comparacion trabajada que motivo agregar {cmd:refyear()}
en primer lugar. Abajo, 2023 es el anio base -- cada otro anio recibe un
p-valor {cmd:P_VS_REF} contra el, y la propia fila de 2023 queda missing
(un anio no se testea contra si mismo):{p_end}
{phang2}{cmd:* Ejemplo 7: refyear() -- contra un anio base, no todos los pares}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    caida(NACIONAL foreign) refyear(2023) frame(F8) replace}{p_end}
{phang2}{cmd:. frame F8: list NIVEL CAIDA ANIO ESTIMA GRUPO P_VS_REF SIG_VS_REF, sepby(NIVEL CAIDA)}{p_end}

{pstd}
{bf:Ejemplo 8: {cmd:refyear()} junto con {cmd:sexovar()}.} {cmd:refyear()}
se pasa directo a cada llamada a {helpb svylet_es} que hace el loop, asi
que funciona igual sin importar si {cmd:tsvy} toma el camino de
{cmd:over()} conjunto (ejemplo 7 de arriba) o el camino de filtrar y
despues {cmd:over(ANIO_)} que todavia usan {cmd:sexovar()} y {cmd:boot()}
(ver {help tsvy_es##remarks_limits:Comentarios}) -- cada bloque de
({cmd:caida()}, {it:sexovar}) recibe su propio chequeo de base
{cmd:refyear()} y su propia columna {cmd:P_VS_REF}, exactamente como si
hubiera llamado {cmd:svylet ..., ref()} a mano dentro de cada bloque:{p_end}
{phang2}{cmd:* Ejemplo 8: refyear() + sexovar() juntos}{p_end}
{phang2}{cmd:. tsvy, varname(mpg) stat(mean) years(2021 2022 2023) ///}{p_end}
{phang2}{cmd:    caida(NACIONAL) sexovar(grupo_precio) refyear(2023) frame(F9) replace}{p_end}
{phang2}{cmd:. frame F9: list NIVEL CAIDA SEXO ANIO ESTIMA GRUPO P_VS_REF SIG_VS_REF, sepby(NIVEL CAIDA SEXO)}{p_end}


{marker frame}{...}
{title:Estructura del frame}

{pstd}
{cmd:tsvy} deja las siguientes variables en {cmd:frame()}, una fila
por (nivel de {cmd:caida()}, valor, [valor de {it:sexovar}], anio):

{synoptset 16 tabbed}{...}
{synopt:{cmd:NIVEL}}el nombre de la variable de {cmd:caida()} para esta
fila (sin el {cmd:_} final si lo tuviera, siguiendo la convencion de
{cmd:tabsvy} -- ej. {cmd:NOMBREDD_} se convierte en {cmd:NOMBREDD}){p_end}
{synopt:{cmd:CAIDA}}el valor de esa variable{p_end}
{synopt:{cmd:SEXO}}valor de {cmd:sexovar()}, si se dio{p_end}
{synopt:{cmd:var}}fijo en 1 (se mantiene solo por compatibilidad de
columnas con el propio frame de {cmd:tabsvy}, donde identifica una
categoria de una variable categorica){p_end}
{synopt:{cmd:ANIO}}anio calendario (mapeado desde {cmd:years()}){p_end}
{synopt:{cmd:ESTIMA}}estimacion puntual{p_end}
{synopt:{cmd:ERROR_ST}}error estandar{p_end}
{synopt:{cmd:CV}}coeficiente de variacion, en porcentaje{p_end}
{synopt:{cmd:LIM_INF LIM_SUP}}limites de confianza{p_end}
{synopt:{cmd:N_SIN_PON N_PONDERA}}tamano de muestra sin ponderar /
ponderado{p_end}
{synopt:{cmd:REF_}}{cmd:"a/"} si {cmd:CV} supera {cmd:threshold()}{p_end}
{synopt:{cmd:F_WALD P_WALD}}estadistico F de Wald global y su p-valor
analitico -- {it:constante entre todos los anios dentro del mismo
bloque}, ya que el test compara todos los anios de ese bloque a la
vez{p_end}
{synopt:{cmd:GRUPO}}el codigo del Compact Letter Display para el anio de
{it:esta fila} dentro de su bloque -- varia por anio{p_end}
{synopt:{cmd:P_VS_REF}}p-valor ajustado por Bonferroni ({it:k}-1
comparaciones) del anio de {it:esta fila} contra {cmd:refyear()}; missing
si no se especifico {cmd:refyear()}, y siempre missing en la fila del
propio {cmd:refyear()} -- una familia de comparaciones DISTINTA de
{cmd:GRUPO}, ver {help svylet_es##remarks_ref:Comentarios en svylet_es.sthlp}{p_end}
{synopt:{cmd:SIG_VS_REF}}estrellas de significancia para {cmd:P_VS_REF}:
{cmd:"*"} p<0.10, {cmd:"**"} p<0.05, {cmd:"***"} p<0.01{p_end}
{p2colreset}{...}

{pstd}
Como {cmd:F_WALD}/{cmd:P_WALD} son constantes dentro de un bloque y
{cmd:GRUPO} varia por anio, un {cmd:reshape wide} posterior deberia
listar {cmd:GRUPO} entre las variables que se reestructuran (asi se
convierte en {cmd:GRUPO2023}, {cmd:GRUPO2024}, ...) pero dejar
{cmd:F_WALD}/{cmd:P_WALD} en {cmd:i()} en cambio, para que se lleven una
sola vez por bloque en vez de repetirse innecesariamente por anio:

{phang2}{cmd:. reshape wide ESTIMA REF_ ERROR_ST LIM_INF LIM_SUP CV N_PONDERA N_SIN_PON GRUPO,}{p_end}
{phang2}{cmd:        i(NIVEL CAIDA var F_WALD P_WALD) j(ANIO)}{p_end}

{pstd}
Este esquema es por lo demas compatible con la mitad de estimaciones
puntuales de {cmd:tabsvyexport} ({cmd:ESTIMA}/{cmd:REF_} por anio), ya
que {cmd:tabsvyexport} ya descarta toda columna que no necesita antes de
su propio reshape.


{marker references}{...}
{title:Referencias}

{pstd}
Ver {helpb svylet_es} para la bibliografia estadistica detras del test
F, las comparaciones de Bonferroni, y {cmd:boot()}. Los contrastes
{it:k}-1 contra la base de {cmd:refyear()} usan la misma correccion de
Bonferroni que {cmd:GRUPO}, aplicada a una familia de comparaciones mas
chica y DISTINTA (Dunn, O.J. 1961. Multiple comparisons among means.
{it:Journal of the American Statistical Association} 56(293): 52-64).


{marker author}{...}
{title:Autor}

{pstd}
Andres Talavera Cuya. La afiliacion se indica solo para fines de
identificacion -- este software no es un producto oficial de INEI y INEI
no es responsable por el. Distribuido bajo la licencia GNU General
Public License v3 (https://www.gnu.org/licenses/gpl-3.0.txt).

{pstd}
Codigo fuente, instrucciones de instalacion, y el motor de estimacion
{helpb svylet_es:svylet}:
{browse "https://github.com/atalaveracuya/svylet"}. Todavia no es un
paquete de SSC; descargue {cmd:tsvy.ado} y este help en un
directorio de su {stata "adopath"} (o clone el repositorio y agreguelo
con {cmd:adopath ++ <ruta>}). Tambien requiere
{stata "ssc install frameappend":frameappend} (SSC).

{pstd}
Cita sugerida: Talavera Cuya, A. 2026. tsvy: modulo de Stata para
armar tablas de estimaciones puntuales con un test de significancia
anio-a-anio entre niveles de agregacion, para datos de encuestas
complejas. Disponible en
{browse "https://github.com/atalaveracuya/svylet"}.


{marker also_see}{...}
{title:Vea tambien}

{psee}
En linea: {helpb svylet_es}, {helpb svy}
{p_end}

{psee}
In English: {helpb tsvy}
{p_end}
