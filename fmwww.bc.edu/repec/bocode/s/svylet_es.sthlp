{smcl}
{* *! version 1.5.0  26aug2026}{...}
{vieweralsosee "[R] svy: mean" "help mean"}{...}
{vieweralsosee "[R] svy: total" "help total"}{...}
{vieweralsosee "[R] svy: proportion" "help proportion"}{...}
{vieweralsosee "[R] svy postestimation" "help svy postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tsvy" "help tsvy_es"}{...}
{vieweralsosee "svylet (English)" "help svylet"}{...}
{viewerjumpto "Sintaxis" "svylet_es##syntax"}{...}
{viewerjumpto "Descripcion" "svylet_es##description"}{...}
{viewerjumpto "Opciones" "svylet_es##options"}{...}
{viewerjumpto "Comentarios" "svylet_es##remarks"}{...}
{viewerjumpto "Ejemplos" "svylet_es##examples"}{...}
{viewerjumpto "Resultados guardados" "svylet_es##results"}{...}
{viewerjumpto "Referencias" "svylet_es##references"}{...}
{viewerjumpto "Autor" "svylet_es##author"}{...}
{viewerjumpto "Vea tambien" "svylet_es##also_see"}{...}
{hline}
{title:Titulo}

{phang}
{bf:svylet} {hline 2} Test F de Wald global, comparaciones pareadas con
correccion de Bonferroni, y Compact Letter Display, para
{cmd:svy:}{space 1}{cmd:mean}/{cmd:total}/{cmd:proportion}/{cmd:ratio}


{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:svylet}
{it:varname}
{ifin}{cmd:,}
{cmdab:over:(}{it:varname}{cmd:)}
{cmdab:stat:(}{it:statname}{cmd:)}
[{it:opciones}]

{pstd}
donde {it:statname} es una de {cmd:mean}, {cmd:total}, {cmd:proportion}, o
{cmd:ratio}.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Principales}
{synopt:{opt over(varname)}}variable que define los grupos a comparar;
requerida{p_end}
{synopt:{opt stat(statname)}}estadistico a estimar y comparar:
{cmd:mean}, {cmd:total}, {cmd:proportion}, o {cmd:ratio}; requerida{p_end}
{synopt:{opt l:evel(#)}}categoria de {it:varname} a testear, cuando
{cmd:stat(proportion)}; por defecto {cmd:level(1)}. Se ignora (con aviso)
para {cmd:mean}, {cmd:total}, y {cmd:ratio}{p_end}
{synopt:{opt d:enominator(varname)}}variable denominador, cuando
{cmd:stat(ratio)} -- {it:varname} (el argumento principal) es el
numerador. Requerida con {cmd:stat(ratio)}, se ignora (con aviso) en
cualquier otro caso{p_end}
{synopt:{opt a:lpha(#)}}nivel de significancia usado para las
comparaciones pareadas de Bonferroni y el Compact Letter Display; por
defecto {cmd:alpha(0.05)}{p_end}

{syntab:Vs-una-referencia (opcional)}
{synopt:{opt ref(#)}}valor de {cmd:over()} a usar como categoria base
fija. Agrega {cmd:k-1} contrastes de Wald con Bonferroni (cada otra
categoria contra {cmd:ref()}) junto al CLD de todos-contra-todos -- una
familia de hipotesis DISTINTA, no un reemplazo; ver
{help svylet_es##remarks_ref:Comentarios}{p_end}

{syntab:Bootstrap (opcional)}
{synopt:{opt boot(#)}}numero de replicas bootstrap para un p-valor
prepivotado del test F global; por defecto {cmd:boot(0)}, es decir, solo
el p-valor analitico{p_end}
{synopt:{opt bseed(#)}}semilla pasada a {cmd:set seed} antes de correr
las replicas de {cmd:boot()}; si se omite, queda la semilla que Stata
ya tenia{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:varname} debe ser numerica. Los pesos ({cmd:fweight}, {cmd:pweight})
y las variables de diseno no se especifican en {cmd:svylet} mismo: el
dataset ya debe estar declarado con {helpb svyset} antes de llamar a
{cmd:svylet}, igual que para {cmd:svy:}.


{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:svylet} apunta a cualquier encuesta compleja con diseno
multietapico, estratificado y por conglomerados, con factores de
expansion -- encuestas de presupuesto de hogares, de fuerza laboral,
demograficas y de salud, encuestas panel de hogares, y microdatos de uso
publico similares -- donde ya se usa {cmd:svy:} y hace falta un test de
significancia (segun el diseno) entre las categorias de una variable de
agrupacion (anios, olas, regiones, cohortes), no solo las estimaciones
puntuales que {cmd:svy:} ya reporta.

{pstd}
{cmd:svylet} responde la pregunta que {cmd:svy:}{space 1}{cmd:mean},
{cmd:total}, y {cmd:proportion} con {cmd:over()} dejan abierta: ¿son las
{it:k} estimaciones de grupo realmente distintas entre si, considerando
el diseno muestral? Corre el comando {cmd:svy:} correspondiente una sola
vez internamente, y luego:

{phang2}1. testea la hipotesis nula global de que las {it:k} estimaciones
de grupo son todas iguales, con un test F de Wald con el ajuste de grados
de libertad de Korn & Graubard (1990) (el mismo ajuste que
{cmd:test}/{cmd:testparm} aplican por defecto despues de {cmd:svy:});{p_end}
{phang2}2. testea cada comparacion pareada entre los {it:k} grupos, con
correccion de Bonferroni para las k(k-1)/2 comparaciones;{p_end}
{phang2}3. asigna un Compact Letter Display (CLD): los grupos que
comparten al menos una letra no son significativamente distintos entre
si a {cmd:alpha()}, despues de la correccion de Bonferroni.{p_end}

{pstd}
Como {cmd:svylet} ya corrio {cmd:svy:} internamente, tambien expone las
estimaciones puntuales, errores estandar, limites de confianza, y
tamanos de muestra por grupo via {cmd:return}, asi que quien lo llama no
necesita correr el mismo comando {cmd:svy:} una segunda vez solo para
armar una tabla de puntos junto al test. Ver
{help svylet_es##results:Resultados guardados} mas abajo, y ver
{helpb tsvy_es} para un comando que usa exactamente esto para armar
una tabla completa (nacional/region/departamento, por anio) en una sola
pasada.


{marker options}{...}
{title:Opciones}

{dlgtab:Principales}

{phang}
{opt over(varname)} especifica la variable cuyas categorias definen los
grupos a comparar (por ejemplo, una variable de anio). Debe tener al
menos 2 valores distintos en la muestra de estimacion; {cmd:svylet} se
detiene con un error si no. {it:varname} debe ser NUMERICA --
{cmd:svy: mean}/{cmd:total}/{cmd:proportion}/{cmd:ratio} no aceptan un
{cmd:over()} string en absoluto ({cmd:svylet} chequea esto y se detiene
con un mensaje claro que nombra {helpb encode} como solucion, en vez de
dejar que el {cmd:svy:} interno falle con su propio error menos
especifico). Si tiene un value label, {cmd:svylet} no lo usa para el test
en si (los
valores se muestran tal como los devuelve {cmd:levelsof}), asi que el
mapeo de un codigo crudo a una etiqueta legible, si hace falta, queda a
cargo de quien llama (ver la logica de {cmd:years()} en
{helpb tsvy_es} para una forma de hacer esto sin depender de un
value label).

{phang}
{opt stat(statname)} elige que comando {cmd:svy:} corre {cmd:svylet}
internamente: {cmd:mean}, {cmd:total}, {cmd:proportion}, o {cmd:ratio}
(agregado en la version 1.2). A diferencia de {cmd:svy:} mismo,
{cmd:svylet} acepta exactamente una variable de analisis por llamada (no
un {it:varlist}, y no una expresion {cmd:num/den} para {cmd:ratio} --
ver {opt denominator()} mas abajo), porque el test esta definido sobre
las categorias de {cmd:over()} para una sola cantidad medida. Para
testear varias variables, llame a {cmd:svylet} una vez por variable.

{phang}
{opt level(#)} selecciona, solo para {cmd:stat(proportion)}, a que
categoria de {it:varname} se refieren el test y las estimaciones
puntuales (el valor de "exito"). {it:varname} produce una fila de salida
en {cmd:svy: proportion} por cada valor distinto que toma; {opt level(#)}
le dice a {cmd:svylet} cual de esas filas llevar a traves del test. No
tiene efecto para {cmd:mean}, {cmd:total}, o {cmd:ratio}, y {cmd:svylet}
imprime un aviso si se fija en algo distinto de su valor por defecto
junto con cualquiera de esos.

{phang}
{opt denominator(varname)} nombra la variable denominador, requerida
cuando {cmd:stat(ratio)} -- el argumento principal del comando,
{it:varname}, es el numerador. {cmd:svylet} arma internamente la
expresion {cmd:num/den} que {cmd:svy: ratio} espera; nunca hace falta
escribir la barra a mano. {cmd:e(b)}/{cmd:e(V)} de
{cmd:svy: ratio ..., over()} tienen la misma forma que {cmd:mean}/
{cmd:total} (una sola ecuacion, una columna por categoria de
{cmd:over()}), asi que el test, las comparaciones de Bonferroni, y el
Compact Letter Display funcionan exactamente igual para {cmd:ratio} que
para {cmd:mean}/{cmd:total}. Se ignora (con aviso) para cualquier otro
{cmd:stat()}.

{phang}
{opt alpha(#)} fija el nivel de significancia para las comparaciones
pareadas ajustadas por Bonferroni que alimentan el Compact Letter
Display. No afecta el p-valor del test F global en si, solo que grupos
terminan compartiendo letra.

{dlgtab:Bootstrap}

{phang}
{opt boot(#)} pide un p-valor calibrado por bootstrap para el test F
global, ademas del analitico, usando el enfoque de prepivotado de Beran
(1988) adaptado para test de hipotesis por Hall & Wilson (1991): se
juntan los datos de todos los grupos de {cmd:over()}, se remuestrean
conglomerados (unidades primarias de muestreo, UPM) completos con
reemplazo dentro de su estrato original ({helpb bsample},
{cmd:cluster()} {cmd:strata()}), y luego se reasigna aleatoriamente cada
{it:conglomerado remuestreado como bloque entero} a un pseudo-grupo, en
las mismas proporciones (por numero de conglomerados) que los grupos
reales de {cmd:over()}, para que la hipotesis nula se cumpla por
construccion en cada replica. Ver {help svylet_es##remarks:Comentarios}
para por que la reasignacion se hace por conglomerado completo y no por
observacion individual, y {help svylet_es##references:Referencias} para
la bibliografia que lo respalda. {cmd:boot(0)}, el default, se salta todo
esto y solo reporta el p-valor analitico.

{pmore}
{cmd:boot()} requiere que el {helpb svyset} actual declare tanto una UPM
como un estrato (se prueban todos los nombres internos donde Stata
{cmd:svy:} puede guardarlos -- {cmd:e(psu)}, {cmd:e(psu1)}, {cmd:e(su)},
{cmd:e(su1)}, y lo correspondiente para estrato); {cmd:svylet} se
detiene con un error claro, mostrando que contenia cada uno de esos
macros, si ninguno resuelve a una variable real.

{phang}
{opt bseed(#)} pasa una semilla a {cmd:set seed} justo antes de correr
las replicas de {cmd:boot()}, para que los resultados sean reproducibles.
Si se omite, se usa tal cual la semilla en la que ya este el generador de
numeros aleatorios de Stata.


{marker remarks}{...}
{title:Comentarios y ejemplos}

{pstd}
Los comentarios se presentan bajo los siguientes titulos:

{phang2}{help svylet_es##remarks_test:El test F global y el ajuste Korn-Graubard}{p_end}
{phang2}{help svylet_es##remarks_cld:Pares de Bonferroni y el Compact Letter Display}{p_end}
{phang2}{help svylet_es##remarks_ref:ref(): comparar contra una base fija, no contra todos los pares}{p_end}
{phang2}{help svylet_es##remarks_degenerate:Varianza degenerada (proporciones exactamente 0 o 1)}{p_end}
{phang2}{help svylet_es##remarks_boot:Por que boot() remuestrea y reasigna por UPM completa}{p_end}
{phang2}{help svylet_es##remarks_limits:Lo que svylet deliberadamente no hace}{p_end}

{marker remarks_test}{...}
{pstd}{bf:El test F global y el ajuste Korn-Graubard}

{pstd}
El test global es un test de Wald de H0: las {it:k} medias/totales/
proporciones de grupo son todas iguales, construido a partir de los
{it:k}-1 contrastes de cada grupo contra el primero. Esto es
matematicamente {it:identico} sin importar que grupo se use como
contraste de referencia -- cualquier conjunto de {it:k}-1 contrastes
independientes que genere el mismo subespacio da el mismo estadistico de
Wald, porque es una reparametrizacion lineal del mismo test. (Una version
anterior de {cmd:svylet} aceptaba una opcion {cmd:refgroup()} que
aparentaba dejar cambiar el grupo de referencia; se elimino en la version
1.1 una vez confirmada esta invarianza algebraicamente -- no habia nada
que implementar. Ver el registro de cambios al inicio de
{cmd:svylet.ado}.)

{pstd}
El propio {cmd:test}/{cmd:testparm} de Stata despues de un comando
{cmd:svy:} aplica, por defecto, el ajuste de grados de libertad de Korn &
Graubard (1990): con {it:k}-1 la dimension del test y {it:d} =
{cmd:e(df_r)} los grados de libertad de diseno,

{pmore}
{cmd:F = [(d - (k-1) + 1) / ((k-1)*d)] * W}{space 4}con{space 4}
{cmd:F ~ F(k-1, d-(k-1)+1)}

{pstd}
donde {it:W} es el estadistico de Wald crudo. {cmd:svylet} aplica el
mismo ajuste (confirmado comparando la salida de {cmd:svylet} contra
{cmd:svy: regress} + {cmd:testparm} sobre el mismo diseno y datos).

{marker remarks_cld}{...}
{pstd}{bf:Pares de Bonferroni y el Compact Letter Display}

{pstd}
Cada uno de los {it:k}(k-1)/2 pares de categorias de {cmd:over()} se
compara con un test t ajustado por diseno, y el p-valor crudo se
multiplica por el numero de pares (con tope en 1) -- la correccion de
Bonferroni estandar. Los grupos se asignan luego al menor numero de
letras tal que dos grupos comparten una letra si y solo si pertenecen a
algun subconjunto maximal de grupos que son todos no-significativos entre
si a {cmd:alpha()}. Esta es la misma logica que usa {cmd:pwcompare, cld}
y la salida clasica tipo "letter display" de los paquetes de ANOVA:
letras compartidas significan "no distinguibles aca", no "iguales".

{marker remarks_ref}{...}
{pstd}{bf:ref(): comparar contra una base fija, no contra todos los pares}

{pstd}
GRUPO/CLD y {cmd:ref()} responden dos preguntas DISTINTAS, y pueden
legitimamente no coincidir sobre el mismo dato -- ninguna de las dos esta
"mal" cuando eso pasa. Esto importa en la practica: al comparar las letras
CLD de tsvy contra un script de referencia que solo comparaba cada anio
contra el mas reciente, alrededor del 17% de las comparaciones anio-vs-2026
derivadas no coincidian, enteramente porque los dos procedimientos testean
familias de hipotesis distintas (ver el registro de cambios v1.5 de
tsvy.ado para el ejemplo completo).

{pstd}
GRUPO/CLD (el default, siempre se calcula) responde "cuales de estas
{it:k} categorias difieren entre SI" -- se comparan los {it:k}(k-1)/2
pares, y la correccion de Bonferroni multiplica cada p-valor crudo por
{it:k}(k-1)/2. {cmd:ref(#)} responde una pregunta mas chica y DISTINTA --
"cuales categorias difieren de ESTA UNICA categoria base" -- solo {it:k}-1
comparaciones estan en esa familia, asi que la correccion de Bonferroni
multiplica por {it:k}-1 en vez de {it:k}(k-1)/2. Una comparacion que
sobrevive Bonferroni con {it:k}-1 comparaciones puede no sobrevivirlo con
{it:k}(k-1)/2 (y, menos intuitivo pero igual de legitimo, tambien puede
pasar al reves, en cualquiera de las dos direcciones), porque las dos
correcciones controlan la tasa de error familiar sobre DOS familias de
hipotesis distintas, no la misma familia con distinto tamano de muestra.
Dunn (1961) es la referencia clasica para aplicar la desigualdad de
Bonferroni a problemas de comparaciones multiples, incluyendo comparar
varios grupos contra un control.

{pstd}
Las {it:k}-1 comparaciones que arma {cmd:ref()} comparten la misma
categoria base, asi que sus estadisticos de test estan correlacionados
entre si de una forma conocida -- un procedimiento de todos-los-pares (el
CLD de este mismo comando, el metodo de Tukey, o un Bonferroni simple
dividido entre {it:k}-1 comparaciones como hace {cmd:ref()}) no aprovecha
esa correlacion y por eso es mas conservador de lo necesario para esta
familia especifica. Dunnett (1955, 1964) derivo un procedimiento de un
solo paso para exactamente este diseno "varios tratamientos vs un
control" que usa la correlacion entre los {it:k}-1 contrastes para
obtener valores criticos mas ajustados (menos conservadores, con mas
potencia) sin dejar de controlar la tasa de error familiar al nivel
nominal; ver tambien Hsu (1996, capitulo 4) y Bretz, Hothorn & Westfall
(2010, capitulo 4) para tratamientos modernos y ejemplos resueltos (el
paquete {cmd:multcomp} de R de estos ultimos lo implementa como
{cmd:contrMat(..., type="Dunnett")}). {cmd:ref()} en este comando usa la
division simple de Bonferroni (Dunn 1961), no el valor critico de un solo
paso de Dunnett -- siempre es valido (Bonferroni nunca infla la tasa de
falsos positivos, sin importar la estructura de correlacion) pero algo
mas conservador que el de Dunnett para esta familia especifica de
comparaciones; implementar los valores criticos genuinos de Dunnett
requiere la distribucion t multivariada, no intentado aca. Ver
{help svylet_es##references:Referencias} mas abajo.

{marker remarks_degenerate}{...}
{pstd}{bf:Varianza degenerada (proporciones exactamente 0 o 1)}

{pstd}
Un grupo con una proporcion de exactamente 0 o 1 -- comun en dominios
chicos -- tiene una varianza basada en diseno no definida o cero. En vez
de tratar eso en silencio como "sin diferencia" (una varianza faltante
comparada contra un numero se trata internamente como mas grande que
cualquier numero real, lo que de otro modo fusionaria ese grupo con
cualquier comparacion que corra al final), {cmd:svylet} marca esas
categorias explicitamente, les asigna la letra {cmd:?}, y las excluye de
todo subconjunto candidato en el Compact Letter Display. Se imprime un
aviso nombrando las categorias afectadas (por su posicion dentro de
{cmd:over()}, no su valor crudo). Trate {cmd:?} como "el test no se pudo
calcular aca", nunca como "sin diferencia".

{pstd}
El F omnibus solo excluye del contraste a las categorias degeneradas --
no queda missing solo porque UNA categoria de varias sea degenerada.
Mientras al menos 2 categorias tengan varianza definida y positiva, el F
omnibus y su p-valor se calculan sobre ese subconjunto (se imprime un
aviso indicando cuantas de las categorias de {cmd:over()} se usaron);
con menos de 2 categorias utilizables no queda nada que testear, asi que
{cmd:r(F_omnibus)}/{cmd:r(p_omnibus)} quedan missing. Los puntos
estimados y las comparaciones pareadas que no involucran una categoria
degenerada no se ven afectados de ninguna forma.

{marker remarks_boot}{...}
{pstd}{bf:Por que boot() remuestrea y reasigna por UPM completa}

{pstd}
El paso de reasignacion de {cmd:boot()} tiene que mover unidades
primarias de muestreo (conglomerados) completas, nunca observaciones
individuales, de su grupo original de {cmd:over()} a un pseudo-grupo.
Partir las observaciones de un conglomerado entre distintos pseudo-grupos
destruye la correlacion intra-conglomerado que el estimador de varianza
basado en diseno (y el estadistico F observado) asume al calcular
varianza, subestimando la variabilidad de la distribucion de referencia
nula del bootstrap e inflando la tasa de falsos positivos. Una simulacion
Monte Carlo bajo una hipotesis nula verdadera (10,000 datasets simulados,
199 replicas bootstrap cada uno) encontro que la reasignacion a nivel de
fila que usaba {cmd:svylet} 1.0 rechazaba una nula verdadera cerca del
9.3% de las veces a un nivel nominal del 5% -- casi el doble -- mientras
que la reasignacion a nivel de conglomerado que se usa desde la 1.1
rechazaba cerca del 3.2% de las veces (conservador, no inflado). Ver
{cmd:AUDIT.md} y {cmd:sim/simulacion_bootstrap.py} en el repositorio de
{cmd:svylet} para la simulacion completa y sus resultados, y
{help svylet_es##references:Referencias} mas abajo para la bibliografia
que respalda por que el remuestreo y la reasignacion bajo un diseno
complejo tienen que preservar el conglomerado como la unidad de
intercambiabilidad.

{marker remarks_limits}{...}
{pstd}{bf:Lo que svylet deliberadamente no hace}

{phang2}o {cmd:svylet} toma una variable de analisis a la vez, no un
{it:varlist} -- ver {helpb tsvy_es} para hacer un loop de esto sobre
muchas variables y muchos niveles de agregacion a la vez.{p_end}
{phang2}o {cmd:svylet} no cruza {cmd:over()} con una segunda dimension de
agrupamiento en la misma llamada (por ejemplo, "por anio, por separado
dentro de cada region"); filtre los datos con {cmd:if} y llame a
{cmd:svylet} de nuevo para cada region, o use {helpb tsvy_es}, que
hace exactamente eso internamente.{p_end}
{phang2}o el resultado del test F global no depende de, ni puede
cambiarse, segun que categoria de {cmd:over()} se trate como referencia
(ver {help svylet_es##remarks_test:arriba}).{p_end}


{marker examples}{...}
{title:Ejemplos}

{pstd}
El {cmd:.} inicial antes de cada linea de abajo es el prompt de comando,
mostrado aca solo porque es la convencion estandar de los help files de
Stata -- no es parte del comando. Copiar un ejemplo de una sola linea
con el {cmd:.} incluido funciona bien (el ejecutor de do-files de Stata
lo tolera), pero copiar un bloque {cmd:foreach}/{cmd:forvalues} de varias
lineas con un {cmd:.} en cada linea, incluido el cuerpo y la llave de
cierre, rompe el parseo del bloque en Stata. Al copiar un ejemplo de
loop a un do-file, saque el {cmd:.} inicial primero.

{pstd}Preparacion: un diseno donde cada observacion es su propia UPM (sin
conglomerados reales en {cmd:auto.dta}, esto alcanza solo para la ruta
analitica){p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen long psu_id = _n}{p_end}
{phang2}{cmd:. svyset psu_id}{p_end}

{pstd}{cmd:proportion}: ¿es distinta la participacion de autos importados
entre categorias de estado de reparacion?{p_end}
{phang2}{cmd:. svylet foreign, over(rep78) stat(proportion) level(1)}{p_end}

{pstd}{cmd:mean}: ¿difiere el promedio de millas por galon entre
categorias de estado de reparacion?{p_end}
{phang2}{cmd:. svylet mpg, over(rep78) stat(mean)}{p_end}

{pstd}{cmd:total}: ¿difiere el peso total de los vehiculos entre
categorias de estado de reparacion?{p_end}
{phang2}{cmd:. svylet weight, over(rep78) stat(total)}{p_end}

{pstd}{cmd:ratio}: ¿difiere la razon baul/largo entre categorias de
estado de reparacion? {opt denominator()} es una opcion aparte, no una
expresion {cmd:num/den} escrita en el argumento principal{p_end}
{phang2}{cmd:. svylet trunk, over(rep78) stat(ratio) denominator(length)}{p_end}

{pstd}{cmd:over()} debe ser numerica -- si la variable de agrupacion que
tiene es STRING (por ejemplo {cmd:origin}, con texto "Domestic"/
"Foreign"), pasela primero por {helpb encode} y use la variable numerica
resultante:{p_end}
{phang2}{cmd:. decode foreign, generate(origin)}{p_end}
{phang2}{cmd:. encode origin, generate(origin_num)}{p_end}
{phang2}{cmd:. svylet mpg, over(origin_num) stat(mean)}{p_end}

{pstd}Con un p-valor calibrado por bootstrap (necesita un diseno con UPM
y estratos reales; {cmd:industry}/{cmd:south} en {cmd:nlsw88.dta} se usan
aca solo para tener conglomerados con varias filas y demostrar el
mecanismo, no como un diseno de encuesta real):{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. svyset industry, strata(south) singleunit(certainty)}{p_end}
{phang2}{cmd:. svylet wage, over(race) stat(mean) boot(200) bseed(20260824)}{p_end}

{pstd}Un nivel de significancia mas laxo amplia que grupos terminan
compartiendo letra (menos grupos terminan "significativamente
distintos"), sin cambiar el test F global en si, solo las comparaciones
pareadas detras de {cmd:GRUPO}:{p_end}
{phang2}{cmd:. svylet mpg, over(rep78) stat(mean) alpha(0.10)}{p_end}

{pstd}{cmd:ref()}: compara cada categoria de {cmd:rep78} contra UNA sola
base fija (aca, 5 = "Excelente") en vez de todos los pares -- {it:k}-1
contrastes ajustados por Bonferroni (Dunn 1961), una familia de
hipotesis DISTINTA del CLD de todos los pares de arriba (ver
{help svylet_es##remarks_ref:Comentarios}). Este es el patron para "cada
grupo, ¿cambio respecto a una categoria/anio de referencia?", la
pregunta que responde {cmd:refyear()} de {helpb tsvy_es} a traves del
tiempo -- ver su help para un ejemplo resuelto con anios:{p_end}
{phang2}{cmd:. svylet mpg, over(rep78) stat(mean) ref(5)}{p_end}
{phang2}{cmd:. return list}{p_end}
{phang2}{cmd:. matrix list r(p_vsref)}{p_end}

{pstd}Leyendo el p-valor vs-base por categoria de forma programatica
(missing en la posicion de {cmd:r(ref_idx)} misma, y en todo el vector
si no se especifico {cmd:ref()}):{p_end}
{phang2}{cmd:. forvalues i = 1/`r(k_categorias)' {c 123}}{p_end}
{phang2}{cmd:.     if `i'' != `r(ref_idx)'' di "rep78 = " `r(nombre_categoria_`i'')' ///}{p_end}
{phang2}{cmd:.        "  p vs base = " el(r(p_vsref), `i'', 1)}{p_end}
{phang2}{cmd:. {c 125}}{p_end}

{pstd}Leyendo los resultados despues de que corre el comando -- los
escalares y matrices de {help svylet_es##results:Resultados guardados}
arriba:{p_end}
{phang2}{cmd:. svylet mpg, over(rep78) stat(mean)}{p_end}
{phang2}{cmd:. return list}{p_end}
{phang2}{cmd:. matrix list r(b)}{p_end}

{pstd}Leyendo las letras y estimaciones por categoria programaticamente,
una categoria a la vez (este es exactamente el patron que usa
{helpb tsvy_es} internamente para armar una tabla fila por
fila):{p_end}
{phang2}{cmd:. forvalues i = 1/`r(k_categorias)' {c 123}}{p_end}
{phang2}{cmd:.     di "rep78 = " `r(nombre_categoria_`i'')' ///}{p_end}
{phang2}{cmd:.        "  estimacion = " el(r(b), `i'', 1) ///}{p_end}
{phang2}{cmd:.        "  letra = " `r(letra_`i'')'}{p_end}
{phang2}{cmd:. {c 125}}{p_end}


{marker results}{...}
{title:Resultados guardados}

{pstd}
{cmd:svylet} guarda lo siguiente en {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 26 2: Escalares}{p_end}
{synopt:{cmd:r(F_omnibus)}}estadistico F de Wald global (ajustado por
Korn-Graubard); missing si no se puede calcular (ver
{cmd:r(k_categorias)} mas abajo){p_end}
{synopt:{cmd:r(p_omnibus)}}p-valor analitico del test F global{p_end}
{synopt:{cmd:r(p_omnibus_boot)}}p-valor calibrado por bootstrap; missing
salvo que se haya especificado {cmd:boot()} y al menos una replica haya
tenido exito{p_end}
{synopt:{cmd:r(B_efectivo)}}numero de replicas de {cmd:boot()} que
terminaron sin error; missing si no se especifico {cmd:boot()}{p_end}
{synopt:{cmd:r(df_num)}}grados de libertad del numerador del test global
({it:k}-1){p_end}
{synopt:{cmd:r(df_den)}}grados de libertad del denominador del test
global (ajustados por Korn-Graubard){p_end}
{synopt:{cmd:r(df_raw)}}grados de libertad de diseno de {cmd:e(df_r)},
{it:sin ajustar} -- use este, no {cmd:r(df_den)}, si arma un intervalo de
confianza tipo {it:t} ordinario a mano{p_end}
{synopt:{cmd:r(k_categorias)}}numero de categorias de {cmd:over()}
testeadas ({it:k}){p_end}
{synopt:{cmd:r(ref_idx)}}posicion (1,...,{it:k}) de {cmd:ref()} dentro de
las categorias de {cmd:over()}; 0 si no se especifico {cmd:ref()}{p_end}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{p2col 5 24 26 2: Macros}{p_end}
{synopt:{cmd:r(letra_}{it:i}{cmd:)}}codigo del Compact Letter Display
para la {it:i}-esima categoria de {cmd:over()} ({cmd:?} si esa categoria
tuvo varianza degenerada), {it:i} = 1,...,{it:k}{p_end}
{synopt:{cmd:r(nombre_categoria_}{it:i}{cmd:)}}valor de {cmd:over()} al
que corresponde la {it:i}-esima categoria, {it:i} = 1,...,{it:k}{p_end}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{p2col 5 24 26 2: Matrices}{p_end}
{synopt:{cmd:r(b)}}{it:k} x 1: estimacion puntual para cada categoria de
{cmd:over()}, en el mismo orden que
{cmd:r(nombre_categoria_}{it:i}{cmd:)}{p_end}
{synopt:{cmd:r(V)}}{it:k} x {it:k}: matriz de varianzas-covarianzas
basada en diseno de {cmd:r(b)}{p_end}
{synopt:{cmd:r(n_ponderado)}}{it:k} x 1: tamano de muestra ponderado
({cmd:e(_N_subp)}) por categoria{p_end}
{synopt:{cmd:r(n_sin_ponderar)}}{it:k} x 1: tamano de muestra sin
ponderar ({cmd:e(_N)}) por categoria{p_end}
{synopt:{cmd:r(ci_lower)}}{it:k} x 1: limite inferior de confianza por
categoria, leido directo de {cmd:r(table)} de la llamada {cmd:svy:}
subyacente (en la escala logit-transformada que Stata mismo usa para
{cmd:proportion}, no reconstruido a mano){p_end}
{synopt:{cmd:r(ci_upper)}}{it:k} x 1: limite superior de confianza por
categoria, misma fuente que {cmd:r(ci_lower)}{p_end}
{synopt:{cmd:r(p_vsref)}}{it:k} x 1: p-valor ajustado por Bonferroni
({it:k}-1 comparaciones) de cada categoria contra la categoria de
{cmd:ref()}; missing en todas si no se especifico {cmd:ref()}, y en la
posicion de {cmd:r(ref_idx)} siempre (una categoria no se testea contra
si misma){p_end}
{synopt:{cmd:r(p_vsref_raw)}}{it:k} x 1: las mismas comparaciones,
p-valor crudo (sin ajustar) -- para uso de auditoria/diagnostico; aplique
su propia correccion si el Bonferroni simple de {cmd:r(p_vsref)} no es lo
que necesita{p_end}
{p2colreset}{...}

{pstd}
{cmd:r(b)}, {cmd:r(V)}, {cmd:r(n_ponderado)}, {cmd:r(n_sin_ponderar)},
{cmd:r(ci_lower)}, y {cmd:r(ci_upper)} le permiten a quien llama armar
una tabla completa de puntos (estimacion, error estandar via
{cmd:sqrt(diag(r(V)))}, intervalo de confianza, tamanos de muestra) sin
correr el comando {cmd:svy:} subyacente una segunda vez. {helpb tsvy_es}
esta construido enteramente sobre estos returns.


{marker references}{...}
{title:Referencias}

{pstd}
Beran, R. 1988.
Prepivoting test statistics: A bootstrap view of asymptotic refinements.
{it:Journal of the American Statistical Association} 83(403): 687{c -}697.

{pstd}
Bretz, F., T. Hothorn, y P. Westfall. 2010.
{it:Multiple Comparisons Using R}. Boca Raton, FL: CRC Press.

{pstd}
Canty, A. J., y A. C. Davison. 1999.
Resampling-based variance estimation for labour force surveys.
{it:The Statistician} 48(3): 379{c -}391.

{pstd}
Davison, A. C., y D. V. Hinkley. 1997.
{it:Bootstrap Methods and Their Application}. Cambridge University Press.

{pstd}
Dunn, O. J. 1961.
Multiple comparisons among means.
{it:Journal of the American Statistical Association} 56(293): 52{c -}64.

{pstd}
Dunnett, C. W. 1955.
A multiple comparison procedure for comparing several treatments with a
control.
{it:Journal of the American Statistical Association} 50(272): 1096{c -}1121.

{pstd}
Dunnett, C. W. 1964.
New tables for multiple comparisons with a control.
{it:Biometrics} 20(3): 482{c -}491.

{pstd}
Field, C. A., y A. H. Welsh. 2007.
Bootstrapping clustered data.
{it:Journal of the Royal Statistical Society, Series B} 69(3): 369{c -}390.

{pstd}
Hall, P., y S. R. Wilson. 1991.
Two guidelines for bootstrap hypothesis testing.
{it:Biometrics} 47(2): 757{c -}762.

{pstd}
Hsu, J. C. 1996.
{it:Multiple Comparisons: Theory and Methods}. Boca Raton, FL: Chapman &
Hall/CRC.

{pstd}
Korn, E. L., y B. I. Graubard. 1990.
Simultaneous testing of regression coefficients with complex survey data:
Use of Bonferroni t statistics.
{it:The American Statistician} 44(4): 270{c -}276.

{pstd}
Rao, J. N. K., y C. F. J. Wu. 1988.
Resampling inference with complex survey data.
{it:Journal of the American Statistical Association} 83(401): 231{c -}241.

{pstd}
Rust, K. F., y J. N. K. Rao. 1996.
Variance estimation for complex surveys using replication techniques.
{it:Statistical Methods in Medical Research} 5(3): 283{c -}310.

{pstd}
Wolter, K. M. 2007.
{it:Introduction to Variance Estimation}. 2nd ed. Springer.


{marker author}{...}
{title:Autor}

{pstd}
Andres Talavera Cuya. La afiliacion se indica solo para fines de
identificacion -- este software no es un producto oficial de INEI y INEI
no es responsable por el. Desarrollado independientemente por el autor;
las opiniones, metodos, y resultados son propios del autor y no reflejan
necesariamente la posicion de INEI. Distribuido bajo la licencia GNU
General Public License v3
(https://www.gnu.org/licenses/gpl-3.0.txt).

{pstd}
Codigo fuente, instrucciones de instalacion, y el comando companero
{helpb tsvy_es:tsvy}:
{browse "https://github.com/atalaveracuya/svylet"}. Todavia no es un
paquete de SSC; descargue {cmd:svylet.ado} y este help en un directorio
de su {stata "adopath"} (o clone el repositorio y agreguelo con
{cmd:adopath ++ <ruta>}).

{pstd}
Cita sugerida: Talavera Cuya, A. 2026. svylet: modulo de Stata para
testear la igualdad de medias, totales, proporciones, y razones
ponderadas por diseno muestral entre grupos. Disponible en
{browse "https://github.com/atalaveracuya/svylet"}.


{marker also_see}{...}
{title:Vea tambien}

{psee}
En linea: {helpb tsvy_es}, {helpb svy}, {helpb svy postestimation},
{helpb mean}, {helpb total}, {helpb proportion}, {helpb test},
{helpb testparm}, {helpb pwcompare}, {helpb bsample}
{p_end}

{psee}
In English: {helpb svylet}
{p_end}
