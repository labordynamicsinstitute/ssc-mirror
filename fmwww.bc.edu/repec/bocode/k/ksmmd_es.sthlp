{smcl}
{* *! version 0.3  16sep2026}{...}
{vieweralsosee "svylet" "help svylet_es"}{...}
{vieweralsosee "tsvy" "help tsvy_es"}{...}
{vieweralsosee "ksmmd (English)" "help ksmmd"}{...}
{viewerjumpto "Sintaxis" "ksmmd_es##syntax"}{...}
{viewerjumpto "Descripcion" "ksmmd_es##description"}{...}
{viewerjumpto "Opciones" "ksmmd_es##options"}{...}
{viewerjumpto "Comentarios" "ksmmd_es##remarks"}{...}
{viewerjumpto "Ejemplos" "ksmmd_es##examples"}{...}
{viewerjumpto "Resultados almacenados" "ksmmd_es##results"}{...}
{viewerjumpto "Referencias" "ksmmd_es##references"}{...}
{viewerjumpto "Autor" "ksmmd_es##author"}{...}
{viewerjumpto "Vea tambien" "ksmmd_es##also_see"}{...}
{hline}
{title:Titulo}

{phang}
{bf:ksmmd} {hline 2} Test distribucional de k-muestras, ponderado, que
combina Kolmogorov-Smirnov (T de Kiefer) y Maximum Mean Discrepancy
(MMD via Random Fourier Features)

{phang}
{it:Version {bf:0.2} (16sep2026)}{p_end}


{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:ksmmd} {it:varname} {ifin}{cmd:,} {cmdab:by:(}{it:groupvar}{cmd:)}
[{it:opciones}]

{p 8 17 2}
{it:varname} puede ponderarse con {cmd:[}{help weight:pweight}{cmd:|}{help weight:aweight}{cmd:|}{help weight:iweight}{cmd:]}.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Principal}
{synopt:{opt by:(groupvar)}}variable que identifica los {it:k} grupos a
comparar; requerida, {it:k} {>=} 2 valores distintos, string o numerica{p_end}
{synopt:{opt reps:(#)}}numero de permutaciones para ambos p-valores;
por defecto {cmd:reps(1000)}{p_end}
{synopt:{opt seed(#)}}semilla aleatoria, pasada a {helpb set seed} de Stata{p_end}
{synopt:{opt dots}}muestra un punto de progreso por cada permutacion{p_end}
{synopt:{opt graph}}dibuja las CDF empiricas ponderadas por grupo, mas
la CDF agrupada{p_end}
{synopt:{opt posthoc}}tabla de a pares para KS y MMD, con p-valores
ajustados por Bonferroni/Sidak/Holm/FDR{p_end}

{syntab:MMD (Random Fourier Features)}
{synopt:{opt bw(#)}}bandwidth del kernel RBF; por defecto
{cmd:bw(-1)} dispara la heuristica de mediana (ver
{help ksmmd_es##remarks_rff:Comentarios}) sobre una submuestra
aleatoria de hasta 2.000 observaciones{p_end}
{synopt:{opt nf:eatures(#)}}numero de random Fourier features (la
dimension {it:D} de la aproximacion); por defecto {cmd:nfeatures(200)}{p_end}
{synopt:{opt mmdtype(string)}}{cmd:vspool} (por defecto),
{cmd:maxpairwise} o {cmd:fuse} -- ver {help ksmmd_es##remarks_mmdtype:Comentarios}{p_end}

{syntab:Alcance}
{synopt:{opt ksonly}}salta el calculo de MMD, reporta solo el
estadistico KS (Kiefer){p_end}
{synopt:{opt mmdonly}}salta el calculo de KS, reporta solo MMD{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:ksmmd} testea si {it:k} {cmd:>=} 2 grupos (nombrados en
{opt by()}) provienen de la misma distribucion de {it:varname},
calculando {it:dos} estadisticos de test a partir de un {bf:unico}
remuestreo por permutacion:

{phang2}o una generalizacion a k-muestras del test de
Kolmogorov-Smirnov (T de Kiefer -- Kiefer 1959), el mismo estadistico
que calcula {helpb kstest} (Ariel Linden, SSC {browse "https://ideas.repec.org/c/boc/bocode/s459801.html":s459801}), pero
reimplementado aca para que {it:varname} se ordene una sola vez (no en
cada permutacion) -- ver
{help ksmmd_es##remarks_why:Comentarios: por que reimplementar kstest}.{p_end}
{phang2}o una generalizacion a k-muestras del Maximum Mean Discrepancy
(MMD -- Gretton et al. 2012) con kernel RBF, aproximado via Random
Fourier Features (Rahimi & Recht 2007) para que siga siendo viable a
N de tamano de encuesta (~10^5), a diferencia de {browse "https://ideas.repec.org/c/boc/bocode/s459820.html":mmd_2s} (Boston
College SSC {cmd:s459820}), que solo compara 2 grupos con kernel
exacto O(N^2).{p_end}

{pstd}
Los dos estadisticos son ponderados (via el peso de encuesta/analitico
que se pase), los dos se testean por permutacion, y {cmd:ksmmd} es
autocontenido en Mata -- no llama a {helpb kstest} ni a {cmd:mmd_2s},
y no requiere {helpb svyset} (no usa la estructura de estratos/UPM del
diseno muestral; ver
{help ksmmd_es##remarks_weights:Comentarios: los pesos no son el diseno de encuesta}).

{pstd}
{cmd:ksmmd} es un comando {bf:standalone} -- no tiene un loop propio de
{cmd:caida()}/{cmd:cruce()} como {helpb tsvy}. Corralo una vez por cada
universo que ya hayas acotado con {cmd:[if]}/{cmd:subpop()}, igual que
{helpb kstest}. Si/como se integra a la opcion {cmd:mmd} de
{cmd:tsvy} es una decision separada y posterior (ver {cmd:tsvy_es.sthlp},
opcion {cmd:mmd}).


{marker options}{...}
{title:Opciones}

{dlgtab:Principal}

{phang}
{opt by(groupvar)} nombra la variable que identifica los {it:k} grupos.
Debe tener al menos 2 valores distintos en la muestra de analisis; los
valores string se recodifican a 1..{it:k} internamente (y se mapean de
vuelta a sus etiquetas originales en la salida).

{phang}
{opt reps(#)} es el numero de replicas de permutacion usadas para
{bf:ambos} p-valores (KS y MMD) -- un solo remuestreo compartido, no
dos separados. Bajalo (ej. {cmd:reps(200)}) para una pasada rapida y
exploratoria; subilo (ej. {cmd:reps(1000)} o mas) para el resultado
que vas a reportar. Ver
{help ksmmd_es##remarks_agile:Comentarios: agil vs. final}.

{phang}
{opt seed(#)} fija la semilla aleatoria antes de sortear las
permutaciones (y, si no se da {opt bw()}, antes de la submuestra de la
heuristica de mediana y de las frecuencias aleatorias de Fourier) --
pasala para una corrida reproducible.

{phang}
{opt dots} imprime un punto de progreso por permutacion, misma
convencion que {helpb kstest}.

{phang}
{opt graph} dibuja las CDF empiricas ponderadas, una por grupo mas la
curva agrupada (punteada) -- mismo estilo que {cmd:kstest ..., graph},
guardado en un grafico llamado {cmd:ksmmd_ecdf}. Es la visual natural
para el estadistico KS; MMD no tiene una curva 1-D propia (vive en el
espacio de features aleatorias), pero la misma ECDF sigue siendo la
referencia relevante para el, dado que los dos operan sobre la misma
{it:varname}.

{phang}
{opt posthoc} agrega, despues del resultado omnibus, una tabla de a
pares por cada estadistico (KS y MMD) sobre las {it:k}({it:k}-1)/2
combinaciones de grupos, cada una con p-valores crudos y ajustados por
Bonferroni/Sidak/Holm/FDR -- mismo formato que {cmd:kstest ...,
posthoc}. Cada par vuelve a correr {opt reps()} permutaciones
restringidas a esos dos grupos.

{dlgtab:MMD (Random Fourier Features)}

{phang}
{opt bw(#)} es el bandwidth del kernel RBF. El default, {cmd:bw(-1)},
dispara el bandwidth por heuristica de mediana (Garreau, Jitkrittum &
Kanagawa 2017) calculado sobre una submuestra aleatoria de hasta 2.000
observaciones (no el dataset completo, por costo -- ver
{help ksmmd_es##remarks_rff:Comentarios}). Pasa un valor positivo para
fijarlo vos mismo, por ejemplo para comparabilidad entre llamadas
repetidas.

{phang}
{opt nfeatures(#)} es {it:D}, el numero de random Fourier features
usadas para aproximar el kernel RBF. Por defecto {cmd:nfeatures(200)}.
Un {it:D} mayor ajusta mejor la aproximacion de MMD (el error esperado
cae como {it:D}^-0.5 -- Sutherland & Schneider 2015) a un costo de
computo proporcional; ver
{help ksmmd_es##remarks_agile:Comentarios: agil vs. final}.

{phang}
{opt mmdtype(string)} elige la regla de combinacion k-muestras para
MMD: {cmd:vspool} (por defecto), {cmd:maxpairwise} o {cmd:fuse}. Ver
{help ksmmd_es##remarks_mmdtype:Comentarios} para las formulas
exactas, las citas, por que una tercera opcion de una version
anterior ({cmd:pairwise}) se elimino por ser matematicamente redundante
con {cmd:vspool}, y el estado de validacion de {cmd:fuse}. {opt bw()}
se {bf:ignora} si se pasa {cmd:mmdtype(fuse)} -- {cmd:fuse} siempre
ancla su propia grilla interna de bandwidths en la heuristica de
mediana.

{dlgtab:Alcance}

{phang}
{opt ksonly} salta por completo el calculo de MMD -- util para una
pasada rapida cuando solo hace falta el resultado KS (mas barato y
exacto), o mientras se explora antes de decidir {opt bw()}/{opt nfeatures()}.

{phang}
{opt mmdonly} salta el calculo de KS, reportando solo MMD.
{opt ksonly} y {opt mmdonly} son mutuamente excluyentes.


{marker remarks}{...}
{title:Comentarios y ejemplos}

{pstd}
Los comentarios se presentan bajo los siguientes titulos:

{phang2}{help ksmmd_es##remarks_why:Por que reimplementar kstest en vez de llamarlo}{p_end}
{phang2}{help ksmmd_es##remarks_mmdtype:mmdtype() -- vspool, maxpairwise y fuse}{p_end}
{phang2}{help ksmmd_es##remarks_rff:MMD via Random Fourier Features}{p_end}
{phang2}{help ksmmd_es##remarks_weights:Los pesos no son el diseno de encuesta}{p_end}
{phang2}{help ksmmd_es##remarks_kmd:KMD se evaluo y se descarto}{p_end}
{phang2}{help ksmmd_es##remarks_agile:Agil vs. final: reps() y nfeatures()}{p_end}

{marker remarks_why}{...}
{pstd}{bf:Por que reimplementar kstest en vez de llamarlo}

{pstd}
{cmd:kstest} (Ariel Linden, SSC {cmd:s459801}) ya calcula la T de
Kiefer por permutacion, pero su motor Mata reordena {it:varname}
adentro de cada una de las {opt reps()} replicas (su permutacion de
etiqueta de grupo se aplica {it:antes} del ordenamiento, no despues).
Para un solo test de 2 o mas muestras, ese es un costo menor. Para
{cmd:ksmmd}, KS y MMD comparten exactamente el mismo sorteo de
permutaciones, y el costo de MMD ya escala con
{it:reps()}*{it:N}*{opt nfeatures()} -- reordenar {it:N} valores encima
de eso, {it:reps()} veces, es evitable: ordenar {it:varname} {bf:una
sola vez} y permutar solo la etiqueta de grupo adosada a cada posicion
ordenada es matematicamente equivalente (una permutacion de las
etiquetas de una secuencia ordenada fija), y elimina un factor
O(N log N) de cada replica.

{marker remarks_mmdtype}{...}
{pstd}{bf:mmdtype() -- vspool, maxpairwise y fuse}

{pstd}
{cmd:mmdtype(vspool)} (por defecto):

{p 8 8 2}T_MMD = sum_j Wsum_j * ||mu_j - mu_pool||^2{p_end}

{pstd}
el mismo patron "cada grupo contra el pool" que usa la T de Kiefer
para generalizar el estadistico D de 2 muestras a k muestras. Esto es
{bf:algebraicamente identico} (verificado directamente, una
descomposicion tipo Huygens/ANOVA en espacio de Hilbert:
sum_j n_j||mu_j-mu_pool||^2 = (1/N)*sum_{{c i<j}} n_i n_j ||mu_i-mu_j||^2)
a la forma pairwise-ponderada con kernel RBF de Ong, Chen, Zhu &
Zhang (2023, {it:Mathematics} 11(20)) y, en el marco general de
k-muestras con tamanos desiguales, Zhang, Guo & Zhou (2022, {it:J.
Econometrics}) -- el mismo estadistico salvo una constante positiva
({it:Wtot}, el peso total, que no depende de la permutacion de
etiquetas y por lo tanto nunca cambia el p-valor de permutacion).

{pstd}
{cmd:mmdtype(maxpairwise)}:

{p 8 8 2}T_MMD = max_{{c k<l}} [Wsum_k*Wsum_l/(Wsum_k+Wsum_l)] * ||mu_k - mu_l||^2{p_end}

{pstd}
Kim (2021, {it:Bernoulli} 27(1)), forma ponderada para tamanos
desiguales (su Remark 3.3, adaptada aca con {cmd:Wsum} en vez de
{it:n} para pesos de encuesta continuos). A diferencia de
{cmd:vspool} (que promedia la discrepancia entre {it:todos} los
grupos), {cmd:maxpairwise} es sensible a que un {it:solo} par de
grupos difiera fuerte aunque el resto de los pares sean identicos --
un perfil de hipotesis alternativa genuinamente distinto, no un
reescalado de {cmd:vspool}.

{pstd}
Una version anterior de este comando ofrecia una tercera opcion,
{cmd:mmdtype(pairwise)}, calculada {it:sin} el peso
{cmd:Wsum_k*Wsum_l/Wtot}. Una vez agregado ese peso, queda {bf:exactamente}
igual a {cmd:vspool} (no solo proporcional -- el mismo numero), asi
que se elimino por redundante en vez de mantenerla como una tercera
alternativa ilusoria.

{pstd}
{cmd:mmdtype(fuse)} (agregada en v0.4) -- MMD-FUSE (Biggs, Schrab &
Gretton 2023, NeurIPS): en vez de un solo bandwidth elegido por la
heuristica de mediana, combina el T_MMD de {cmd:vspool} a lo largo de
una grilla {bf:fija} de cuatro bandwidths (1x, 1.5x, 2x, 3x la
heuristica de mediana) via un soft-max regularizado por KL, sin pagar
el costo de una correccion de Bonferroni ni partir la muestra:

{p 8 8 2}T_FUSE = (1/lambda) * log( mean_g[ exp(lambda * T_g) ] ),
T_g = T_MMD_vspool(bw_g) / sqrt(Nhat(bw_g)){p_end}

{pstd}
donde {cmd:Nhat(bw)} pone en una escala comun el T_MMD de cada
bandwidth antes de combinarlos (si no, el bandwidth con features de
mayor varianza dominaria el log-sum-exp sin que eso refleje mas
evidencia real). El teorema de calibracion por permutacion (Hemerik &
Goeman 2018) vale para {bf:cualquier} estadistico fijo, asi que la
grilla y {cmd:lambda=0.1} no necesitan respaldo de la literatura para
que el p-valor de permutacion siga siendo exacto bajo la nula -- pero,
con la misma honestidad que el resto de este comando, esa grilla y ese
{cmd:lambda} especificos salen de una busqueda sistematica en
Python/numpy sobre datos simulados durante el desarrollo de este
paquete ({cmd:sim/prototipo_mmd_fuse*.py}), no de un valor que
recomiende el paper de MMD-FUSE. Motivo: la potencia de un solo
bandwidth resulto sensible al {it:tipo} de alternativa (un bandwidth
muy grande diluye un corrimiento de ubicacion, uno muy chico se ahoga
en ruido de permutacion) sobre datos reales de produccion -- la grilla
se eligio para no tener que adivinar ese tipo de antemano. Validada
para el control de la tasa de error Tipo I (R=20000, sin inflacion,
los mismos 3 escenarios de peso que el resto de este comando, tanto en
k=2 como en k=4 -- ver {cmd:sim/resultados_ksmmd_mmd_fuse_2muestras_tipo1.txt}
y {cmd:sim/resultados_ksmmd_mmd_fuse_4muestras_tipo1.txt}) y, con
kernel exacto en un prototipo de Python (R=300), fue la {bf:unica} de
8 grillas x 6 lambdas probadas que se mantuvo robusta a la vez contra
un corrimiento de ubicacion (50-53% de potencia) Y una diferencia de
escala/dispersion (89.7-91.3%) -- grillas que ganaban bajo un tipo de
alternativa se derrumbaban bajo el otro.

{pstd}
La grilla y {cmd:lambda} {bf:no} son configurables via opciones --
exponerlas ampliaria la superficie de validacion sin que exista
todavia evidencia de que otra combinacion sea mejor. {opt bw()} se
ignora con {cmd:mmdtype(fuse)} por el mismo motivo: la grilla solo
esta validada anclada en la heuristica de mediana interna. Costo de
memoria: {cmd:fuse} arma {opt nfeatures()} features aleatorias por
{bf:cada} uno de sus 4 puntos de grilla (4x la memoria de {cmd:Phi}
que {cmd:vspool}/{cmd:maxpairwise} con el mismo {opt nfeatures()}).

{pstd}
{bf:Estado de validacion propio de fuse}: el codigo Mata de {cmd:fuse}
se escribio sin tener Stata real disponible -- el algebra es la misma
que ya se valido en Python/numpy -- pero desde entonces se
{bf:confirmo contra Stata real, en dos escalas}. Escala chica
({cmd:auto.dta}, Ejemplo 5 de abajo, {cmd:mpg}, {cmd:by(g)
mmdtype(fuse) reps(500)}): {cmd:T_MMD=0.4980 p=0.7126} sin error,
mismo orden de magnitud que {cmd:mmdtype(vspool)} sobre los mismos
datos/pesos (Ejemplo 2: {cmd:T_MMD=0.7422 p=0.5629}). Escala de
produccion (un outcome real de encuesta por anio, N=141,151 en 4
grupos, {opt reps(200)} {opt nfeatures(500)} -- 2000 columnas RFF en
total, 4x {opt nfeatures()} por los 4 puntos de grilla, sin problema
de memoria en la practica): corrio en 364.97 segundos sin error,
{cmd:T_MMD=1848.9130 p=0.6617} -- practicamente el mismo p-valor que
el {cmd:p=0.6667} de {cmd:mmdtype(vspool)} sobre los mismos
datos/seed, y el post-hoc pairwise de {cmd:fuse} muestra el mismo
patron cualitativo que el de {cmd:vspool} (ningun par significativo
despues de corregir por comparaciones multiples, a diferencia del
post-hoc de KS, que si encuentra al anio mas reciente distinto de los
otros tres). Sin errores de sintaxis ni de indexado en ninguna de las
dos escalas.

{marker remarks_rff}{...}
{pstd}{bf:MMD via Random Fourier Features}

{pstd}
Un MMD exacto con kernel RBF necesita la matriz de kernel N x N
completa -- O(N^2), inviable con N en el orden de cientos de miles (el
problema exacto que hacia demasiado lento a {cmd:mmd_2s} en produccion
para este caso). {cmd:ksmmd} en cambio aproxima el kernel con
{opt nfeatures()} random Fourier features (Rahimi & Recht 2007):
phi(x) = sqrt(2/D) * cos(omega*x + b), omega ~ N(0, 1/bw^2),
b ~ Uniform(0, 2*pi) -- convirtiendo el costo en O(reps * N * D),
lineal en {it:N}.

{pstd}
La cota de error conocida es sobre el estadistico MMD en si, no solo
sobre el kernel (Sutherland & Schneider 2015, Theorem 1):
P(|MMD_RFF - MMD| >= eps) <= 2*exp(-D*eps^2/128), error absoluto
esperado <= 8*sqrt(2*pi/D) -- bajar a la mitad el error esperado
requiere {bf:cuadruplicar} {opt nfeatures()}. Choi & Kim (2024)
muestran ademas que, con {it:D} fijo, la potencia del test basado en
RFF no esta garantizada de ser consistente -- un {opt nfeatures()}
bajo puede perder potencia frente al MMD exacto, por eso
{opt nfeatures()} sigue la misma logica agil-despues-final que
{opt reps()} (ver {help ksmmd_es##remarks_agile:Comentarios} abajo).

{pstd}
{opt bw(-1)} (el default) usa el bandwidth por heuristica de mediana
(Garreau, Jitkrittum & Kanagawa 2017) sobre una submuestra aleatoria
de hasta 2.000 observaciones, no el dataset completo -- calcular la
mediana exacta de todas las distancias par-a-par es en si O(n^2).

{marker remarks_weights}{...}
{pstd}{bf:Los pesos no son el diseno de encuesta}

{pstd}
{cmd:ksmmd} admite {cmd:[aweight/pweight/iweight]} y los usa en todo
el calculo (medias ponderadas por grupo en el espacio de features,
ECDF ponderada), pero {bf:no} usa la estructura de estratos/UPM de
{helpb svyset} -- misma limitacion que {cmd:mmd_2s} y {cmd:kstest}.
Una busqueda de la literatura indexada (septiembre 2026) no encontro
{bf:ningun} test MMD o de energy-statistics peer-reviewed que trate
especificamente pesos de diseno muestral (probabilidad desigual). Lo
que existe es {it:importance weighting} (Bellot & van der Schaar 2021,
UAI, WMMD; Bharti et al. 2023, ICML; Diesendruck et al. 2018/2019) --
un concepto {bf:distinto}, que corrige sesgo de seleccion entre 2
distribuciones, no representa una poblacion via un factor de
expansion. Insertar {cmd:Wsum} en el estimador plug-in de MMD, como un
promedio tipo Horvitz-Thompson, es una extension razonable, pero no
tiene un paper que pruebe su validez bajo pesos de encuesta
especificamente -- justamente porque ese paper no parece existir, la
unica forma honesta de confiar en ella es una simulacion Monte Carlo
de tasa de error Tipo I (el mismo tipo que ya se corrio para
{cmd:kstest} en el directorio {cmd:sim/} de este repositorio), no una
cita. Esa simulacion ya se corrio para las {bf:dos} opciones de
{cmd:mmdtype()}: {cmd:vspool} ({cmd:sim/simulacion_ksmmd_mmd_tipo1.py}
/ {cmd:resultados_ksmmd_mmd_tipo1.txt}) y {cmd:maxpairwise}
({cmd:sim/simulacion_ksmmd_mmd_maxpairwise_tipo1.py} /
{cmd:resultados_ksmmd_mmd_maxpairwise_tipo1.txt}) -- mismo diseno de 3
escenarios que la simulacion de {cmd:kstest} en ambos casos, tasa de
rechazo en el peor caso alrededor de 6% (vs. 5% nominal) bajo H0
verdadera para cualquiera de las dos opciones, consistente con, y no
peor que, el resultado propio de {cmd:kstest}.

{marker remarks_kmd}{...}
{pstd}{bf:KMD se evaluo y se descarto}

{pstd}
Una tercera familia de medidas de disimilitud distribucional, KMD
(Huang & Sen 2024, {it:JASA} -- "A Kernel Measure of Dissimilarity
between M Distributions"), se leyo completa y se considero para
{cmd:ksmmd}. Se descarto por decision explicita: su estimador
publicado (un estadistico de grafo de k-vecinos-mas-cercanos) no tiene
version ponderada en el paper, lo que choca con el requisito que
motivo todo este comando ("que respete el diseno muestral o use
pesos, como kstest"). Construir un grafo de k-NN rapido en Mata (sin
una estructura tipo KD-tree) es ademas un problema de rendimiento
aparte, del mismo calibre que el que resuelven las Random Fourier
Features para MMD -- no es algo que se resuelva "de yapa" en esta
version.

{marker remarks_agile}{...}
{pstd}{bf:Agil vs. final: reps() y nfeatures()}

{pstd}
Tanto {opt reps()} como {opt nfeatures()} cambian precision por
velocidad. Para una pasada rapida y exploratoria (decidir si una
diferencia parece siquiera digna de reportarse), bajalos a los dos,
ej. {cmd:reps(200) nfeatures(50)}. Para el numero que vas a citar
realmente, subilos a los dos, ej. {cmd:reps(1000) nfeatures(500)} o
mas -- ninguno de los dos defaults es un numero magico, son puntos de
partida para ajustar contra tu propio N y presupuesto de tiempo.


{marker examples}{...}
{title:Ejemplos}

{pstd}
Cada ejemplo de abajo corre sobre {cmd:auto.dta}, uno de los datasets
incluidos en Stata -- alcanza con {cmd:sysuse auto}, no hace falta
dato externo.

{phang2}{cmd:* Preparacion}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen byte g = 1 + mod(_n, 3)}{p_end}
{phang2}{cmd:. gen double wgt = 1}{p_end}

{pstd}
{bf:Ejemplo 1: sin ponderar, pasada rapida.} 3 pseudo-grupos, ambos
estadisticos, pocas permutaciones por velocidad:{p_end}
{phang2}{cmd:* Ejemplo 1: pasada rapida sin ponderar}{p_end}
{phang2}{cmd:. ksmmd mpg, by(g) reps(200)}{p_end}

{pstd}
{bf:Ejemplo 2: ponderado, con grafico y posthoc.} Usa {cmd:wgt} (aca
constante, en lugar de un peso analitico/de encuesta real):{p_end}
{phang2}{cmd:* Ejemplo 2: ponderado, grafico, posthoc}{p_end}
{phang2}{cmd:. ksmmd mpg [aweight=wgt], by(g) reps(500) seed(20260916) ///}{p_end}
{phang2}{cmd:    graph posthoc}{p_end}

{pstd}
{bf:Ejemplo 3: maxpairwise en vez de vspool}, sensible a que un solo
par de grupos diverja:{p_end}
{phang2}{cmd:* Ejemplo 3: maxpairwise}{p_end}
{phang2}{cmd:. ksmmd mpg [aweight=wgt], by(g) mmdtype(maxpairwise) ///}{p_end}
{phang2}{cmd:    reps(500)}{p_end}

{pstd}
{bf:Ejemplo 4: solo KS}, saltando MMD por completo para una vista
rapida:{p_end}
{phang2}{cmd:* Ejemplo 4: ksonly}{p_end}
{phang2}{cmd:. ksmmd mpg [aweight=wgt], by(g) ksonly reps(200)}{p_end}

{pstd}
{bf:Ejemplo 5: fuse}, combinando una grilla de bandwidths en vez de
uno solo (ver {help ksmmd_es##remarks_mmdtype:Comentarios} para su
estado de validacion antes de usarlo en produccion):{p_end}
{phang2}{cmd:* Ejemplo 5: fuse}{p_end}
{phang2}{cmd:. ksmmd mpg [aweight=wgt], by(g) mmdtype(fuse) reps(500)}{p_end}


{marker results}{...}
{title:Resultados almacenados}

{pstd}
{cmd:ksmmd} deja lo siguiente en {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Escalares}{p_end}
{synopt:{cmd:r(T_KS)}}estadistico T de Kiefer (missing si {opt mmdonly})}{p_end}
{synopt:{cmd:r(P_KS)}}p-valor de permutacion para T_KS{p_end}
{synopt:{cmd:r(T_MMD)}}estadistico MMD, segun {opt mmdtype()} (missing si {opt ksonly})}{p_end}
{synopt:{cmd:r(P_MMD)}}p-valor de permutacion para T_MMD{p_end}
{synopt:{cmd:r(reps)}}numero de permutaciones usadas{p_end}
{synopt:{cmd:r(k)}}numero de grupos{p_end}
{synopt:{cmd:r(npairs)}}numero de pares en la tabla posthoc (si {opt posthoc}){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(by)}}nombre de la variable {opt by()}{p_end}
{synopt:{cmd:r(mmdtype)}}{cmd:vspool}, {cmd:maxpairwise} o {cmd:fuse}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(pairwise_ks)}}tabla de a pares para KS (si {opt posthoc}
y no {opt mmdonly}) -- columnas
Stat/P_raw/P_bonf/P_sidak/P_holm/P_fdr, una fila por par{p_end}
{synopt:{cmd:r(pairwise_mmd)}}tabla de a pares para MMD (si
{opt posthoc} y no {opt ksonly}), mismo formato de columnas{p_end}
{p2colreset}{...}


{marker references}{...}
{title:Referencias}

{pstd}
Kiefer, J. (1959). K-sample analogues of the Kolmogorov-Smirnov and
Cramer-v. Mises tests. {it:Ann. Math. Statist.} 30(2), 420-447.

{pstd}
Gretton, A., Borgwardt, K.M., Rasch, M.J., Scholkopf, B., Smola, A.
(2012). A Kernel Two-Sample Test. {it:JMLR} 13(25), 723-773.

{pstd}
Rahimi, A., Recht, B. (2007). Random Features for Large-Scale Kernel
Machines. {it:NeurIPS} 20.

{pstd}
Biggs, F., Schrab, A., Gretton, A. (2023). MMD-FUSE: Learning and
Combining Kernels for Two-Sample Testing Without Data Splitting.
{it:NeurIPS} 36. arXiv:2306.08777.

{pstd}
Hemerik, J., Goeman, J.J. (2018). Exact testing with random
permutations. {it:Test} 27(4), 811-825.

{pstd}
Sutherland, D.J., Schneider, J. (2015). On the Error of Random Fourier
Features. {it:UAI} 2015.

{pstd}
Ong, C.S., Chen, X., Zhu, D., Zhang, Y. (2023). Testing Equality of
Several Distributions at High Dimensions: A Maximum Mean
Discrepancy-Based Approach. {it:Mathematics} 11(20), 4272.

{pstd}
Zhang, Y., Guo, X., Zhou, W. (2022). Testing equality of several
distributions in separable metric spaces: a maximum mean discrepancy
based approach. {it:J. Econometrics}.

{pstd}
Kim, I. (2021). Comparing a large number of multivariate
distributions. {it:Bernoulli} 27(1), 419-441.

{pstd}
Sejdinovic, D., Sriperumbudur, B., Gretton, A., Fukumizu, K. (2013).
Equivalence of distance-based and RKHS-based statistics in hypothesis
testing. {it:Ann. Statist.} 41(5), 2263-2291.

{pstd}
Rizzo, M.L., Szekely, G.J. (2010). DISCO analysis: a nonparametric
extension of analysis of variance. {it:Ann. Appl. Stat.} 4(2), 1034-1055.

{pstd}
Szekely, G.J., Rizzo, M.L. (2004). Testing for Equal Distributions in
High Dimension. {it:InterStat}, Nov(5).

{pstd}
Rizzo, M.L., Szekely, G.J. (2016). Energy distance. {it:WIREs
Computational Statistics} 8(1), 27-38.

{pstd}
Garreau, D., Jitkrittum, W., Kanagawa, M. (2017). Large sample
analysis of the median heuristic. arXiv:1707.07269.

{pstd}
Choi, S., Kim, I. (2024). Computational-Statistical Trade-off in
Kernel Two-Sample Testing with Random Fourier Features. arXiv:2407.08976.

{pstd}
Huang, Z., Sen, B. (2024). A Kernel Measure of Dissimilarity between M
Distributions. {it:JASA} 119(548), 3020-3032 (evaluada, {bf:no}
incorporada -- ver {help ksmmd_es##remarks_kmd:Comentarios}).


{marker author}{...}
{title:Autor}

{pstd}
Andres Talavera Cuya. Afiliacion indicada solo para fines de
identificacion -- este software no es un producto oficial de INEI y
INEI no es responsable por el. Distribuido bajo GNU General Public
License v3 (https://www.gnu.org/licenses/gpl-3.0.txt).

{pstd}
El motor de remuestreo de la version 0.2 (una permutacion a la vez)
{bf:si} se corrio contra Stata real en la sesion que produjo este
archivo, incluso sobre datos de produccion reales (N~127,000). La
version 0.3 reescribe ese motor para procesar las permutaciones en
bloques vectorizados en vez de una a la vez (la mejora de v0.2 sobre
{cmd:mmd_2s} fue de solo ~4-5x en la practica, muy por debajo del
~N/D esperado al reemplazar un kernel exacto O(N^2) por random
features O(N*D)); los estadisticos resultantes siguen la misma
algebra, pero la reescritura en si {bf:no} se pudo correr todavia
contra Stata real (sin Stata disponible en el entorno donde se
escribio) -- ver la nota de v0.3 y la advertencia cerca del inicio de
{cmd:ksmmd.ado} para los pasos de validacion pendientes antes de
confiar en el en produccion.

{pstd}
La version 0.4 agrega {cmd:mmdtype(fuse)} (MMD-FUSE). Su control de la
tasa de error Tipo I se valido a R=20000 via una reimplementacion
separada en Python/numpy de la misma algebra (k=2 y k=4, ver
{help ksmmd_es##remarks_mmdtype:Comentarios}). El codigo Mata en si ya
se confirmo contra Stata real tanto a escala chica ({cmd:auto.dta})
como de produccion (N=141,151, 4 grupos, {opt reps(200)}
{opt nfeatures(500)}, 364.97 segundos, sin error) -- ver
{help ksmmd_es##remarks_mmdtype:Comentarios} para ambos resultados.

{pstd}
Codigo fuente: {browse "https://github.com/atalaveracuya/svylet"}.
Todavia no es un paquete SSC; descarga {cmd:ksmmd.ado} y este help
file a un directorio en tu {stata "adopath"}.


{marker also_see}{...}
{title:Vea tambien}

{psee}
Online: {helpb svylet_es}, {helpb tsvy_es}, {helpb svy}
{p_end}

{psee}
English: {helpb ksmmd}
{p_end}
