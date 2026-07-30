{smcl}
{* *! version 3.0-es  26jul2026}{...}
{viewerjumpto "Sintaxis" "mmd_2s##syntax"}{...}
{viewerjumpto "Descripcion" "mmd_2s##description"}{...}
{viewerjumpto "Opciones" "mmd_2s##options"}{...}
{viewerjumpto "Resultados guardados" "mmd_2s##results"}{...}
{viewerjumpto "Metodos y formulas" "mmd_2s##methods"}{...}
{viewerjumpto "Ejemplos" "mmd_2s##examples"}{...}
{viewerjumpto "Autor" "mmd_2s##author"}{...}
{title:Titulo}

{phang}
{bf:mmd_2s} {hline 2} Test de dos muestras Maximum Mean Discrepancy (MMD), ponderacion opcional


{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:mmd_2s} {varname} {ifin} {weight}{cmd:,}
{cmdab:by:(}{varname}{cmd:)}
[{it:opciones}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Requerido}
{synopt:{cmdab:by:(}{varname}{cmd:)}}variable de agrupamiento; debe tener exactamente 2 valores distintos{p_end}

{syntab:Opcional}
{synopt:{cmdab:boot:(}{it:#}{cmd:)}}numero de replicas de bootstrap; por defecto {cmd:boot(200)}{p_end}
{synopt:{cmdab:reps:(}{it:#}{cmd:)}}numero de corridas independientes que se promedian para el estadistico observado; por defecto {cmd:reps(1)}{p_end}
{synopt:{cmdab:seed:(}{it:#}{cmd:)}}semilla del generador aleatorio (Mata {cmd:rseed()}); por defecto usa la semilla actual de Stata{p_end}
{synopt:{cmd:boxplot}}dibuja un boxplot (NO ponderado) de {varname} por {cmd:by()}, anotado con p-boot, effect size y neff{p_end}
{synopt:{cmd:kdensity}}dibuja la densidad kernel (ponderada, si corresponde) de ambos grupos{p_end}
{synopt:{cmdab:bw:(}{it:#}{cmd:)}}ancho de banda para {cmd:kdensity}; por defecto usa el sigma del propio test{p_end}
{synopt:{cmdab:npoints:(}{it:#}{cmd:)}}numero de puntos de grilla para {cmd:kdensity}; por defecto 200{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
Se permiten {cmd:aweight}, {cmd:pweight} e {cmd:iweight}; ver {help weight}.
La ponderacion es totalmente {bf:opcional} -- omiti {cmd:[weight]} para el test sin ponderar.{p_end}


{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:mmd_2s} pone a prueba la hipotesis nula de que dos muestras
independientes provienen de la misma distribucion, usando un
estadistico Maximum Mean Discrepancy (MMD) con kernel RBF (gaussiano) y
un p-valor por bootstrap.

{pstd}
{bf:La version 3.0 fusiona los anteriores {cmd:mmd_2s} (sin ponderar) y
{cmd:mmd_2s_pond} (ponderado) en un solo comando}, siguiendo el mismo
diseño que {help kstest:kstest.ado}: la ponderacion se especifica con la
sintaxis {bf:nativa} de Stata ({cmd:[pweight/aweight/iweight]}), no con
una opcion propia obligatoria. Si no se especifica ningun peso, se usa
un peso interno de 1 para cada observacion, y el comando reproduce
exactamente (a precision de maquina) el comportamiento del antiguo
{cmd:mmd_2s} v1.0 sin ponderar, con los mismos {cmd:seed()}/{cmd:boot()}/
{cmd:reps()}. Ya no existe un archivo {cmd:mmd_2s_pond} separado que
mantener sincronizado -- un solo codigo, un solo set de funciones Mata,
el peso vale 1 por defecto.

{pstd}
El estimador de base es el MMD de tiempo lineal por pares aleatorios
(estilo Gretton): se sortean pares al azar dentro de cada grupo, se
calcula una combinacion de 4 terminos con kernel RBF por par, y el
promedio (ponderado, si corresponde) entre pares es el estadistico,
acotado en 0 y promediado sobre tres anchos de banda (sigma/2, sigma,
2*sigma). Cuando se especifican pesos, {bf:quienes} entran a cada par se
sigue eligiendo de forma uniforme al azar; el peso solo afecta
{bf:cuanto cuenta} un par ya elegido (ver {help mmd_2s##methods:Metodos
y formulas}). Es una eleccion de diseño deliberada, adecuada al
estimador por pares -- {bf:no} es el mismo patron de normalizacion que
usa {help kstest:kstest} (que pondera la ECDF completa de cada grupo por
su propio peso total). Los dos comandos ponderan de formas
estructuralmente distintas, apropiadas a su propio estadistico.


{marker options}{...}
{title:Opciones}

{phang}
{cmdab:by:(}{varname}{cmd:)} {it:(requerido)} especifica la variable de
agrupamiento. Debe tomar exactamente dos valores distintos en la
muestra de estimacion (tras excluir automaticamente los missing de
{cmd:by()}); el comando termina con error si no es asi.

{phang}
{it:{help weight}} ({cmd:aweight}/{cmd:pweight}/{cmd:iweight}) es
{it:opcional}. Si se especifica, los valores de peso no positivos o
missing se excluyen automaticamente de la muestra (mismo tratamiento
que un {cmd:by()} missing). Si se omite, cada observacion recibe peso 1.

{phang}
{cmdab:boot:(}{it:#}{cmd:)} numero de replicas de bootstrap para armar
la distribucion nula (remuestreo con reemplazo del pool combinado; los
pesos viajan junto con cada fila). Por defecto 200; subilo para mas
resolucion en el p-valor (el minimo detectable es 1/(boot+1)).

{phang}
{cmdab:reps:(}{it:#}{cmd:)} numero de corridas independientes que se
promedian para formar el estadistico observado. Como el estimador
submuestrea los datos, una sola corrida puede ser ruidosa, sobre todo
con tamaño de muestra efectivo chico. {cmd:reps(1)} (por defecto)
replica una corrida unica; se recomienda {cmd:reps(20)} o mas para uso
en produccion. Con {cmd:reps(#)>1}, {cmd:r(mmd_stat_sd)} reporta la
desviacion estandar entre corridas como diagnostico de estabilidad.

{phang}
{cmdab:seed:(}{it:#}{cmd:)} fija la semilla de Mata via {cmd:rseed()}
antes de cualquier remuestreo, para reproducibilidad. Si se omite, se
usa el estado aleatorio actual de Mata.

{phang}
{cmd:boxplot} dibuja un {cmd:graph box} de {varname} segun {cmd:by()} (el
boxplot en si NO esta ponderado -- es solo ayuda visual), anotado con
p-boot, effect size y neff de ambos grupos.

{phang}
{cmd:kdensity} dibuja curvas de densidad kernel para ambos grupos,
ponderadas si se especifico un peso, con ancho de banda anclado al
sigma del propio test salvo que {cmd:bw()} lo sobreescriba.


{marker results}{...}
{title:Resultados guardados}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Escalares}{p_end}
{synopt:{cmd:r(mmd_stat)}}estadistico MMD observado (promedio de {cmd:reps()} corridas){p_end}
{synopt:{cmd:r(mmd_stat_sd)}}desviacion estandar entre corridas de {cmd:reps()} (missing si {cmd:reps(1)}){p_end}
{synopt:{cmd:r(mmd_boot_mean)}}media de la distribucion nula de bootstrap{p_end}
{synopt:{cmd:r(p_boot)}}p-valor de bootstrap, {cmd:(#(boot>=stat)+1)/(boot()+1)} (correccion "+1" de Davison-Hinkley -- nunca da exactamente 0){p_end}
{synopt:{cmd:r(effect_size)}}{cmd:mmd_stat / mmd_boot_mean}{p_end}
{synopt:{cmd:r(nA)} / {cmd:r(nB)}}tamaño de muestra crudo, cada grupo{p_end}
{synopt:{cmd:r(neff_A)} / {cmd:r(neff_B)}}tamaño de muestra efectivo de Kish (= n crudo si no se pondero){p_end}
{synopt:{cmd:r(sigma)}}ancho de banda del kernel RBF (heuristica de mediana){p_end}
{synopt:{cmd:r(N_boot)} / {cmd:r(N_reps)}}numero de replicas/corridas usadas{p_end}
{p2colreset}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(weighted)}}{cmd:"yes"} o {cmd:"no"}{p_end}
{p2colreset}{...}


{marker methods}{...}
{title:Metodos y formulas}

{pstd}
{bf:Tamaño de muestra efectivo:} n_eff = (sum w)^2 / sum(w^2) (Kish, via
Monahan 2011, ec. 12.4.5). Se reduce al n crudo cuando w=1 para todos.

{pstd}
{bf:Estadistico MMD (una corrida):} sea m = floor(min(neff_A,neff_B)/2).
Se sortean 2m indices {bf:de forma uniforme al azar} (sin reemplazo) de
cada grupo, se parten en dos mitades, y se arma
h = k(x1,x2)+k(y1,y2)-k(x1,y2)-k(x2,y1) con kernel RBF. El estadistico
es el {bf:promedio ponderado de h} usando pesos por par
w_par=(wx1*wx2+wy1*wy2)/2, acotado en 0. Ojo: esto pondera la
{it:contribucion} de cada par ya elegido de forma uniforme -- NO hace
que una observacion de peso alto tenga mas chance de ser sorteada para
un par. Se repite con anchos de banda sigma/2, sigma, 2*sigma y se
promedia, y eso se vuelve a promediar sobre {cmd:reps()}.

{pstd}
{bf:Ancho de banda (sigma):} mediana de las diferencias absolutas
pareadas sobre la variable combinada; si el pool tiene mas de 2000
observaciones, primero se sortea una submuestra de 2000 (ponderada, sin
reemplazo, Efraimidis-Spirakis) -- con 2000 o menos, el resultado no
depende de los pesos en absoluto.

{pstd}
{bf:Bootstrap:} la muestra combinada (valores y pesos juntos) se
remuestrea con reemplazo {cmd:boot()} veces; se recalcula el mismo
estadistico cada vez. p-valor = (# replicas >= observado + 1) /
(boot() + 1).


{marker examples}{...}
{title:Ejemplos}

{pstd}Preparacion{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}Sin ponderar (no se especifica {cmd:[weight]}): ¿el rendimiento (mpg) tiene la misma distribucion en autos importados vs. nacionales?{p_end}
{phang2}{cmd:. mmd_2s mpg, by(foreign) boot(200) seed(12345)}{p_end}

{pstd}Mismo ejemplo, con grafico de densidad kernel{p_end}
{phang2}{cmd:. mmd_2s mpg, by(foreign) boot(200) seed(12345) kdensity}{p_end}

{pstd}Estabilizando el estadistico con {cmd:reps()} y el boxplot diagnostico{p_end}
{phang2}{cmd:. mmd_2s price, by(foreign) boot(200) reps(20) seed(12345) boxplot}{p_end}

{pstd}Preparacion, segunda base{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}

{pstd}Ponderado, con {cmd:aweight}: ¿el salario (wage) tiene la misma distribucion segun afiliacion sindical (union)?{p_end}
{phang2}{cmd:. mmd_2s wage [aweight=hours], by(union) boot(500) reps(20) seed(12345) boxplot}{p_end}

{pstd}Chequeo de reduccion al caso no ponderado (peso constante = 1){p_end}
{phang2}{cmd:. gen peso1 = 1}{p_end}
{phang2}{cmd:. mmd_2s wage [aweight=peso1], by(union) boot(500) reps(20) seed(12345)}{p_end}
{phang2}{cmd:. * comparar r(mmd_stat), r(p_boot) y r(effect_size) contra la corrida sin [weight], misma seed()}{p_end}
{phang2}{cmd:. mmd_2s wage, by(union) boot(500) reps(20) seed(12345)}{p_end}

{pstd}
{bf:Ejemplo con datos reales, microdatos publicos}: superficie cosechada
entre cultivos transitorios y permanentes ({cmd:p204_tipo}), usando la
Encuesta Nacional Agropecuaria (ENA) de Peru, ponderado por el factor de
expansion. Los datos se descargan directo del portal oficial de
microdatos de INEI con el comando complementario {help sriinei:sriinei}
(tambien disponible en SSC) -- este paquete no distribuye ningun archivo
de datos. {bf:Probado y validado} por el autor con datos reales:{p_end}
{phang2}{cmd:. sriinei, codigo(1036) modulo(1895) tipo(csv) destino("C:\BD_INEI\mic")}{p_end}
{phang2}{cmd:. cd "C:\BD_INEI\mic\1036-Modulo1895"}{p_end}
{phang2}{cmd:. use 03_CAP200AB, clear}{p_end}
{phang2}{cmd:. keep if codigo==1 & inlist(p204_tipo,1,2)}{p_end}
{phang2}{cmd:. gen sup_cosechada=p217_sup_ha}{p_end}
{phang2}{cmd:. drop if missing(sup_cosechada, factor)}{p_end}
{phang2}{cmd:. gen double sup_cosechada_log = log(sup_cosechada + 1)}{p_end}
{phang2}{cmd:. timer clear}{p_end}
{phang2}{cmd:. timer on 1}{p_end}
{phang2}{cmd:. mmd_2s sup_cosechada_log [aweight=factor], by(p204_tipo) boot(30) reps(20) kdensity}{p_end}
{phang2}{cmd:. timer off 1}{p_end}
{phang2}{cmd:. timer list}{p_end}


{marker author}{...}
{title:Autor / notas de desarrollo}

{pstd}
La v3.0 de {cmd:mmd_2s} fusiona el antiguo par
{cmd:mmd_2s}/{cmd:mmd_2s_pond} en un solo comando, adoptando el diseño
de ponderacion opcional de {help kstest:kstest.ado} (Ariel Linden). Ver
tambien {help sriinei:sriinei}, un comando complementario para descargar
microdatos publicos directo de un portal oficial de estadisticas
(usado en el ejemplo con datos reales de arriba).

{pstd}
Andres Talavera Cuya{break}
Direccion Nacional de Censos y Encuestas -- INEI Peru{break}
Junio 2026

{hline}
{title:Licencia}

{pstd}
Este modulo se distribuye bajo los terminos de la GPL v3
({browse "https://www.gnu.org/licenses/gpl-3.0.txt":https://www.gnu.org/licenses/gpl-3.0.txt}).

{hline}
{title:Version}

{pstd}
{bf:mmd_2s} v3.0 -- 26jul2026
