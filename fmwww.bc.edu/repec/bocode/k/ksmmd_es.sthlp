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
proporcional al peso de hasta 2.000 observaciones{p_end}
{synopt:{opt nf:eatures(#)}}numero de random Fourier features (la
dimension {it:D} de la aproximacion); por defecto {cmd:nfeatures(200)},
redondeado hacia arriba a un numero par si hace falta{p_end}
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
Kanagawa 2017) calculado sobre una submuestra de hasta 2.000
observaciones (no el dataset completo, por costo), sorteada con
probabilidad proporcional al peso de encuesta (v0.7 -- ver
{help ksmmd_es##remarks_rff:Comentarios}). Pasa un valor positivo para
fijarlo vos mismo, por ejemplo para comparabilidad entre llamadas
repetidas.

{phang}
{opt nfeatures(#)} es {it:D}, el numero de random Fourier features
usadas para aproximar el kernel RBF. Por defecto {cmd:nfeatures(200)},
redondeado hacia arriba a un numero par si se pasa un valor impar (la
construccion "z-tilde" de v0.7 siempre produce un numero par de
columnas -- ver {help ksmmd_es##remarks_rff:Comentarios}).
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
{phang2}{help ksmmd_es##remarks_combo:Por que combinar KS y MMD}{p_end}
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

{marker remarks_combo}{...}
{pstd}{bf:Por que combinar KS y MMD}

{pstd}
Los dos estadisticos no se combinan solo por conveniencia de este
paquete. Kiefer (1959, Sec. 6, texto completo leido) muestra que los
tests tipo {bf:sup} (su T, la generalizacion k-muestral de KS) tienen
garantizada una potencia minima contra {it:cualquier} alternativa
puntual; los tests tipo {bf:integral} (como los tests tipo omega^2, y
MMD es uno de esa familia) no tienen esa garantia, pero pueden ser mas
potentes contra alternativas difusas en vez de concentradas en un solo
punto -- KS y MMD son complementarios por diseno. Ong, Chen, Zhu &
Zhang (2023) hacen el mismo punto desde el lado de MMD: recomiendan
textualmente correr un test tipo MMD {bf:y} un test tipo
energy-distance juntos, porque en la practica rara vez se sabe de
antemano si dos distribuciones difieren en ubicacion/forma (la
fortaleza de KS) o en momentos superiores/estructura de covarianza (la
fortaleza de MMD).

{pstd}
Por separado, la T de Kiefer no exige que los tamanos de grupo n_j/N
converjan a proporciones fijas cuando N crece -- tranquiliza para
grupos desbalanceados (un caso comun cuando {opt by()} agrupa por anio
y los tamanos de cohorte difieren). La propia discusion del paper sobre
F no continua (empates) es coherente con el manejo de empates de este
comando (el {cmd:jumpmask} interno del codigo Mata: los empates nunca
se tratan como evidencia, lo cual es conservador -- solo puede hacer al
test levemente menos potente, nunca anti-conservador).

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
k-muestras con tamanos desiguales, Zhang, Guo & Zhou (2024, {it:J.
Econometrics} 239(2)) -- el mismo estadistico salvo una constante positiva
({it:Wtot}, el peso total, que no depende de la permutacion de
etiquetas y por lo tanto nunca cambia el p-valor de permutacion).

{pstd}
{bf:v0.7:} {cmd:ksmmd} calcula directamente la forma par-a-par de esta
identidad, T_MMD = (1/Wtot) * sum_{{c a<b}} Wsum_a*Wsum_b*||mu_a-mu_b||^2_U,
usando la forma {bf:insesgada} (U-estadistico) de ||.||^2_U en vez de
la forma sesgada (V-estadistico) usada hasta v0.6 -- Gretton et al.
(2012) dan ambas para el caso de 2 muestras; la eleccion importa aca
porque el termino "propio" de cada grupo en la forma sesgada incluye
parejas de la MISMA unidad (i=i'), cuya contribucion ponderada es una
constante aditiva fija bajo pesos IGUALES (nunca afecto el p-valor de
permutacion) pero deja de serlo bajo pesos de encuesta DESIGUALES
(depende de que unidades caen en cada grupo bajo cada permutacion) --
una posible fuente sutil de perdida de potencia. La forma insesgada
quita esas parejas de la misma unidad grupo por grupo (cae de vuelta a
la forma sesgada solo si el denominador del de-bias de un grupo es
numericamente inseguro, p.ej. un grupo extremadamente chico o con
pesos muy concentrados). {cmd:mmdtype(maxpairwise)} recibe el mismo
tratamiento, por consistencia -- ver abajo. Esto cambia {bf:solo} el
estimador usado (no la validez: el teorema de permutacion de Hemerik &
Goeman vale para cualquier estadistico fijo); re-validado por
simulacion (tasa de error Tipo I, R=2.000, k=4, los mismos 3 escenarios
de peso adversos --
{cmd:sim/simulacion_ksmmd_v07_tipo1.py} /
{cmd:resultados_ksmmd_v07_tipo1.txt} -- tasas de rechazo entre 3.6% y
5.8% en los 3 escenarios y las 3 opciones de {opt mmdtype()}, sin
inflacion frente al 5% nominal; un chequeo algebraico previo confirma
que la reescritura par-a-par coincide, hasta error de punto flotante,
con la formula "cada grupo contra el pool" de arriba cuando el de-bias
esta apagado).

{pstd}
El puente al marco DISCO/energy-distance de Rizzo & Szekely, via
Sejdinovic, Sriperumbudur, Gretton & Fukumizu (2013), es real pero
tiene un alcance preciso (texto completo leido): Rizzo & Szekely (2010,
DISCO), Corolario 2, muestra que la descomposicion "cada grupo contra
el pool" existe {bf:solo} para una distancia {bf:cuadratica} (tipo
RKHS) -- la energy distance original de Szekely & Rizzo (2004) usa un
exponente no cuadratico y no tiene tal descomposicion, solo una suma
pareada. Por eso {cmd:vspool} necesita especificamente un kernel (una
forma cuadratica), no cualquier distancia. Ademas, el kernel que hace
que MMD sea {bf:igual} a la energy distance Euclidea literal NO es
RBF -- es un kernel no acotado, k1(z,z')=0.5*(||z||+||z'||-||z-z'||).
RBF si genera una semimetrica de tipo negativo (asi que sigue
detectando cualquier diferencia distribucional, no solo un corrimiento
de media), pero es una version {bf:acotada/saturada} de la Euclidea,
no la energy distance Euclidea en si.

{pstd}
{cmd:mmdtype(maxpairwise)}:

{p 8 8 2}T_MMD = max_{{c k<l}} [Wsum_k*Wsum_l/(Wsum_k+Wsum_l)] * ||mu_k - mu_l||^2_U{p_end}

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
El paper (texto completo leido) da una guia explicita sobre cuando
preferir cada forma: {cmd:maxpairwise} esta pensado para alternativas
{it:dispersas} (un solo grupo distinto de los demas); {cmd:vspool}/
{cmd:fuse} para alternativas {it:densas} (varios grupos difieren). Los
estadisticos tipo-promedio pierden potencia al crecer k bajo
alternativas dispersas; {cmd:maxpairwise} la mantiene. Su optimalidad
minimax (Sec. 6 del paper) esta condicionada a supuestos tecnicos de
kernel acotado/subgaussiano y a una clase especifica de alternativas,
y NO se transfiere automaticamente a la version ponderada por pesos de
encuesta que implementa este comando.

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
heuristica de mediana, combina el T_MMD (insesgado, v0.7) de
{cmd:vspool} a lo largo de una {bf:grilla} de bandwidths via un
soft-max regularizado por KL, sin pagar el costo de una correccion de
Bonferroni ni partir la muestra:

{p 8 8 2}T_FUSE = (1/lambda) * log( mean_g[ exp(lambda * T_g) ] ),
T_g = T_MMD_vspool_U(bw_g, kernel_g) / sqrt(Nhat(g)){p_end}

{pstd}
donde {cmd:Nhat(g)} pone en una escala comun el T_MMD de cada punto de
grilla antes de combinarlos (si no, el punto con features de mayor
varianza dominaria el log-sum-exp sin que eso refleje mas evidencia
real). El teorema de calibracion por permutacion (Hemerik & Goeman
2018) vale para {bf:cualquier} estadistico fijo, asi que la grilla y
{cmd:lambda} no necesitan respaldo de la literatura para que el
p-valor de permutacion siga siendo exacto bajo la nula; sus 2
condiciones concretas se cumplen aca: (a) el estadistico observado se
evalua como una permutacion mas (el "+1" en (count+1)/(reps+1)), y (b)
la grilla y {cmd:lambda} quedan fijas {bf:antes} de ver las
permutaciones de cada corrida (nunca dependen del dato que se esta
probando).

{pstd}
{bf:v0.7:} tanto la grilla como {cmd:lambda} ahora siguen directamente
al paper MMD-FUSE (PDF leido completo), generalizados al contexto de
{cmd:ksmmd} (k grupos, ponderado, RFF):

{phang2}o {bf:lambda} = sqrt(n_min*(n_min-1)), n_min = el tamano del
grupo MAS CHICO -- la formula del propio paper (sus Teoremas 2-3
exigen que lambda sea asintoticamente proporcional a n para potencia
optima, y todos sus experimentos usan exactamente esto con n=tamano de
la muestra mas chica en su contexto de 2 muestras; coincide
exactamente con el paper cuando k=2, y se extiende a k>2 via el grupo
mas chico como decision propia de diseno de {cmd:ksmmd}, no del
paper). Reemplaza el {cmd:lambda=0.1} fijo usado hasta v0.6, que a su
vez salia de una busqueda sistematica en Python/numpy sobre datos
simulados ({cmd:sim/prototipo_mmd_fuse*.py}) hecha porque la formula
del paper todavia no se habia probado en el contexto ponderado/RFF de
este comando.{p_end}
{phang2}o {bf:grilla}: 10 bandwidths -- 5 de una discretizacion
uniforme entre 0.5x el percentil 5 y 2x el percentil 95 de las
distancias entre unidades (sobre una submuestra {it:ponderada}, v0.7 --
ver abajo), por {bf:2} familias de kernel, Gaussiana {bf:y} Laplace,
igualando el diseno validado empiricamente por el propio paper (su
Apendice A.2/A.4, que usa 10-20 bandwidths por familia con las mismas
2 familias). El rango del paper es mas ancho (10-20 vs. 5 por familia
aca) puramente por costo de memoria a escala de encuesta (N~10^5) --
ver abajo. Reemplaza la grilla fija de 4 puntos (1x, 1.5x, 2x, 3x la
heuristica de mediana, solo Gaussiana) usada hasta v0.6.{p_end}

{pstd}
Ambos cambios estan re-validados por simulacion (tasa de error Tipo I,
R=2.000, k=4 -- el uso real de produccion, agrupando por
{opt by(anio)} -- los mismos 3 escenarios de peso adversos que el
resto de este comando: {cmd:sim/simulacion_ksmmd_v07_tipo1.py} /
{cmd:resultados_ksmmd_v07_tipo1.txt}; tasas de rechazo entre 3.6% y
5.8% en los 3 escenarios, sin inflacion frente al 5% nominal, para
{cmd:fuse} {bf:y} las otras 2 opciones de {opt mmdtype()} en la misma
corrida). La validacion de potencia de la grilla anterior (chequeo de
Tipo I con R=20000 a k=2 y k=4, mas un prototipo de Python con kernel
exacto robusto a la vez contra un corrimiento de ubicacion y una
diferencia de escala/dispersion --
{cmd:sim/resultados_ksmmd_mmd_fuse_*_tipo1.txt},
{cmd:sim/prototipo_mmd_fuse*.py}) queda como registro de la validacion
propia del diseno v0.4-v0.6; no se traslada automaticamente a la
grilla nueva, pero nada en la construccion de la grilla nueva (un
superconjunto en espiritu: mas cobertura de bandwidths, una segunda
familia de kernel) sugiere que deberia ser menos potente.

{pstd}
La grilla y {cmd:lambda} {bf:siguen sin ser} configurables via
opciones -- exponerlas ampliaria la superficie de validacion sin que
exista evidencia de que otra combinacion sea mejor. {opt bw()} se
ignora con {cmd:mmdtype(fuse)} por el mismo motivo. Costo de memoria:
{cmd:fuse} arma {opt nfeatures()} features aleatorias por {bf:cada}
uno de sus 10 puntos de grilla (10x la memoria de {cmd:Phi} que
{cmd:vspool}/{cmd:maxpairwise} con el mismo {opt nfeatures()} -- con
{opt nfeatures(200)} por defecto son 2.000 columnas RFF en total, el
mismo orden de magnitud que la configuracion {opt reps(200)}
{opt nfeatures(500)} / grilla de 4 puntos (2.000 columnas) ya
confirmada sin problema de memoria en datos reales de produccion
(N=141.151) en v0.4 -- ver la nota de validacion abajo). {cmd:Nhat(g)}
se sigue calculando sobre una submuestra de hasta 300 observaciones en
vez del dataset agrupado completo (por costo) -- la Definicion 1 del
propio paper usa el dataset completo; esto sigue siendo un apartamiento
deliberado y documentado, una posible perdida de potencia (no un
riesgo de validez).

{pstd}
{bf:Estado de validacion propio de fuse}: el codigo Mata de {cmd:fuse}
de las versiones {bf:v0.4-v0.6} (grilla fija de 4 puntos, lambda=0.1)
se confirmo contra Stata real en dos escalas -- ver el registro
completo de esas corridas y valores en el encabezado de
{cmd:ksmmd.ado}. La reescritura de {bf:v0.7} (grilla nueva, lambda
nuevo, el kernel Laplace, el U-estadistico insesgado, la heuristica de
mediana ponderada) se escribio y valido en Python/numpy (chequeo
algebraico mas la simulacion de Tipo I de arriba) sin una sesion de
Stata real disponible en ese entorno de desarrollo -- la misma
situacion que ya documentaron las primeras versiones de v0.3/v0.4.
{bf:Confirmada} a escala chica (21sep2026, {cmd:auto.dta}, 5 variantes
de sintaxis corridas contra Stata real -- {cmd:vspool} sin ponderar,
{cmd:vspool} ponderado con {opt graph}/{opt posthoc},
{opt mmdtype(maxpairwise)}, {opt ksonly}, {opt mmdtype(fuse)}): las 5
corrieron {bf:sin error}. {bf:Tambien confirmada a escala de
produccion} el mismo dia (un outcome real de encuesta agrupado por una
variable ordinal, N~141.000): una primera tanda de 5 configuraciones (incluyendo
{opt graph}/{opt posthoc}, un {opt bw()} fijo, {opt ksonly}/
{opt mmdonly}, y una corrida agil) uso {opt mmdtype(vspool)} en todos
los casos, y una segunda tanda -- corrida despues del fix del bug de
abajo -- agrego {opt mmdtype(maxpairwise)} y {opt mmdtype(fuse)} (con
{opt nfeatures(200)} y {opt nfeatures(500)}, es decir 10x500=5.000
columnas de {cmd:Phi}, la configuracion sin confirmar por memoria que
se senalaba antes) con {opt posthoc}, todas {bf:sin error}. Las
{bf:3} opciones de {opt mmdtype()} y KS quedan confirmadas ahora en
{bf:ambas} escalas -- no queda ninguna configuracion pendiente para
v0.7. Ver el encabezado de {cmd:ksmmd.ado} para los estadisticos y
tiempos exactos de ambas escalas.

{pstd}
{bf:Sobre los valores NEGATIVOS de T_MMD}: las 3 opciones de
{opt mmdtype()} ahora pueden reportar un T_MMD {bf:negativo} (visto en
la corrida contra Stata real de arriba, ej. T_MMD=-0.1721) -- esto es
esperado, no un error. Hasta v0.6, T_MMD era una cantidad sesgada
(V-estadistico), siempre >= 0. El estimador insesgado (U-estadistico)
de v0.7 apunta a una cantidad poblacional (MMD^2) cuyo piso es
exactamente 0 bajo la nula; un estimador insesgado de un valor en el
piso de su propio rango tiene que poder ir en ambas direcciones, o
estaria sesgado hacia arriba -- Gretton et al. (2012) documentan
exactamente esto para el caso de 2 muestras. Bajo (o cerca de) la
nula, el estimador fluctua alrededor de 0, asi que valores negativos
chicos son la firma esperada de que la nula esta cerca de ser cierta,
no evidencia de un error. El p-valor de permutacion sigue siendo
valido de todas formas: se calibra contra la MISMA distribucion nula,
que fluctua de la misma manera, asi que un T_MMD observado muy
negativo naturalmente da un p-valor {bf:alto} (como en el ejemplo de
{cmd:fuse} de arriba, p=0.9142).

{pstd}
{bf:Bug encontrado y corregido} (21sep2026): {opt mmdtype(maxpairwise)}
tenia especificamente un bug real ligado a este comportamiento
negativo nuevo -- encontrado por el usuario en una corrida de
produccion, donde un par post-hoc (k=2) cuyo estadistico real era
negativo se reportaba silenciosamente como T_MMD=0.0000 y p=1.0000,
{bf:exactos}, en vez del valor negativo real. Causa raiz: el maximo
corriente arrancaba en 0 (correcto para la {it:suma} corriente de
{cmd:vspool}, incorrecto para el {it:maximo} corriente de
{cmd:maxpairwise} una vez que los terminos pueden ser negativos) --
corregido arrancandolo en un centinela muy negativo, asi que el maximo
real (positivo o negativo) siempre se encuentra. Re-validado con una
simulacion de Tipo I nueva (sin inflacion) y un sanity check dedicado.
Ver el encabezado de {cmd:ksmmd.ado} para el analisis completo de la
causa raiz. Este bug NO afectaba a {cmd:vspool} ni a {cmd:fuse}
({cmd:fuse} solo usa la rama de {cmd:vspool} internamente) -- estaba
aislado a {opt mmdtype(maxpairwise)}. Cualquier corrida de
{opt mmdtype(maxpairwise)} hecha con un {cmd:ksmmd.ado} anterior a
este fix deberia repetirse. El fix en si se confirmo el mismo dia con
una corrida de re-validacion a escala de produccion (los mismos datos
reales de encuesta): los mismos 2 pares post-hoc que antes mostraban
T_MMD=0.0000/p=1.0000 ahora mostraron correctamente sus valores
negativos reales (T_MMD=-174.9475 y -361.6898), coincidiendo casi
exacto con el posthoc propio de {cmd:vspool} para esos pares -- lo
esperado, ya que {cmd:vspool} y {cmd:maxpairwise} son algebraicamente
el mismo estadistico a k=2 (ver la discusion de arriba).

{marker remarks_rff}{...}
{pstd}{bf:MMD via Random Fourier Features}

{pstd}
Un MMD exacto con kernel RBF necesita la matriz de kernel N x N
completa -- O(N^2), inviable con N en el orden de cientos de miles (el
problema exacto que hacia demasiado lento a {cmd:mmd_2s} en produccion
para este caso). {cmd:ksmmd} en cambio aproxima el kernel con
{opt nfeatures()} random Fourier features (Rahimi & Recht 2007),
convirtiendo el costo en O(reps * N * D), lineal en {it:N}. Desde
v0.7, las features son la construccion "z-tilde" de menor varianza
(Sutherland & Schneider 2015, ecs. 5-7): phi(x) = sqrt(1/(D/2)) *
[cos(omega_1 x), sin(omega_1 x), ..., cos(omega_{{c D/2}} x),
sin(omega_{{c D/2}} x)], omega_m ~ N(0, 1/bw^2) -- {bf:sin} fase
aleatoria y D/2 frecuencias, en vez de la construccion anterior
("z-breve": coseno con fase aleatoria, D frecuencias). Mismo costo
computacional, varianza estrictamente menor para el kernel Gaussiano
al mismo {it:D}. {opt nfeatures()} se redondea hacia arriba a un
numero par si hace falta, porque esta construccion siempre devuelve un
numero par de columnas (D/2 cosenos + D/2 senos).

{pstd}
La cota de error conocida es sobre el estadistico MMD en si (no su
cuadrado), no solo sobre el kernel (Sutherland & Schneider 2015,
Seccion 3.3):
P(|MMD_RFF - MMD| >= eps) <= 2*exp(-D*eps^2/128), error absoluto
esperado <= 8*sqrt(2*pi/D) -- bajar a la mitad el error esperado
requiere {bf:cuadruplicar} {opt nfeatures()}. ({bf:Corregido} sep2026,
tras leer el PDF completo con verificacion cruzada de extraccion: un
"corregido 19sep2026" anterior, hecho por busqueda bibliografica sin
acceso al texto completo, habia cambiado por error esta cota a MMD^2
y la habia citado como "Theorem 1" -- el texto primario (pagina 7)
confirma que la cota es sobre MMD sin elevar al cuadrado, y que el
resultado es un parrafo sin numerar dentro de la Seccion 3.3 (el paper
no tiene ningun teorema numerado, solo Proposiciones 1-10). Ambos
errores se revierten aca.) Choi, I. & Kim, I. (2024) muestran algo
{bf:mas fuerte} que "puede perder potencia": su Teorema 3 prueba
INCONSISTENCIA GENUINA con {it:D} fijo -- existen infinitos pares de
distribuciones distintas donde la potencia asintotica queda acotada
por alpha sin importar el tamano de muestra, si D no crece con N. No
hay una tasa universal D=O(sqrt(N)); la tasa necesaria depende de la
suavidad de la alternativa, no observable (sus Teoremas 6-7, Prop. 8).
Evidencia empirica a favor del default: en su caso univariado (d=1, el
mismo caso de {cmd:ksmmd}) D=200 ya iguala la potencia del MMD exacto
en sus simulaciones -- respalda {opt nfeatures(200)} por default. Su
Teorema 7 tambien advierte que subir D hasta ~n (tamano del grupo
minimo) recupera la tasa optima pero el costo vuelve a ser esencialmente
O(N^2) -- "D grande para el resultado final" no es gratis, mismo
patron agil-despues-final que {opt reps()} (ver
{help ksmmd_es##remarks_agile:Comentarios} abajo).

{pstd}
Aparte de la aproximacion RFF, la potencia de MMD frente a un
corrimiento de ubicacion depende del bandwidth por un motivo mas
basico (Reddi, Ramdas, Poczos, Singh & Wasserman 2015, Lemma 1): la
MMD^2 poblacional con kernel Gaussiano escala como
2*corrimiento^2/bandwidth^2 (1+o(1)) -- un bandwidth grande respecto al
corrimiento diluye la senal de forma {bf:cuadratica}, no exponencial
({bf:corregido} sep2026: una version anterior de esta nota decia
"exponencialmente chico", frase que el paper no respalda; su teorema
formal de potencia es ademas un resultado explicito de ALTA DIMENSION
(n y d a infinito conjuntamente, bandwidth=Omega(sqrt(d))), que no
aplica literalmente a una variable escalar como edad, d=1 -- solo el
mecanismo del Lemma 1 citado generaliza por analogia algebraica a
d=1). De cualquier forma, un {opt bw()} mal elegido puede no ver una
diferencia real que KS si detecta (parte de la motivacion de
{cmd:mmdtype(fuse)}, ver {help ksmmd_es##remarks_mmdtype:Comentarios}).

{pstd}
{opt bw(-1)} (el default) usa el bandwidth por heuristica de mediana
(Garreau, Jitkrittum & Kanagawa 2017) sobre una submuestra de hasta
2.000 observaciones, no el dataset completo -- calcular la mediana
exacta de todas las distancias par-a-par es en si O(n^2). {bf:v0.7:}
esa submuestra se sortea con probabilidad proporcional al peso de
encuesta (un muestreo ponderado sin reemplazo tipo Efraimidis-Spirakis)
en vez de uniformemente, como se hacia hasta v0.6 -- una inconsistencia
de diseno corregida; ningun paper de esta bibliografia cubre la
heuristica de mediana bajo pesos, asi que esta es una extension propia
de {cmd:ksmmd}, re-validada por la simulacion de Tipo I citada en
{help ksmmd_es##remarks_mmdtype:Comentarios} (mmdtype()). Nota de
convencion (texto completo leido): {cmd:ksmmd} usa bw = mediana(|y_i-
y_j|) = sqrt(Hn), donde Hn es la mediana de las distancias {it:al
cuadrado}; la formula principal del paper es nu=sqrt(Hn/2), un factor
sqrt(2) mas chico, pero su propia nota al pie 1 reconoce que "algunos
autores simplemente eligen nu=sqrt(Hn)" -- la convencion de
{cmd:ksmmd} es una variante real de la literatura, no un error. La
Sec. 4 del paper tambien muestra {bf:empiricamente} que la heuristica
de mediana elige un bandwidth demasiado grande especificamente cuando
los grupos difieren en {bf:varianza/escala} y no en ubicacion --
respaldo independiente (mas alla de las simulaciones propias de este
paquete) para usar {cmd:mmdtype(fuse)} cuando se sospecha una
diferencia de dispersion, no solo un corrimiento.

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
cita. Esa simulacion se corrio primero (hasta v0.6) para {cmd:vspool}
({cmd:sim/simulacion_ksmmd_mmd_tipo1.py}
/ {cmd:resultados_ksmmd_mmd_tipo1.txt}) y {cmd:maxpairwise}
({cmd:sim/simulacion_ksmmd_mmd_maxpairwise_tipo1.py} /
{cmd:resultados_ksmmd_mmd_maxpairwise_tipo1.txt}) -- mismo diseno de 3
escenarios que la simulacion de {cmd:kstest} en ambos casos, tasa de
rechazo en el peor caso alrededor de 6% (vs. 5% nominal) bajo H0
verdadera para cualquiera de las dos opciones, consistente con, y no
peor que, el resultado propio de {cmd:kstest}. {bf:v0.7} repitio esta
validacion desde cero para el estimador rediseñado (U-estadistico
insesgado, RFF z-tilde, heuristica de mediana ponderada -- ver
{help ksmmd_es##remarks_mmdtype:Comentarios} para los cambios propios
de la grilla/lambda de {cmd:fuse}), las 3 opciones de {opt mmdtype()}
juntas, R=2.000 con k=4:
{cmd:sim/simulacion_ksmmd_v07_tipo1.py} /
{cmd:resultados_ksmmd_v07_tipo1.txt} -- tasas de rechazo entre 3.6% y
5.8% en los mismos 3 escenarios, no peor que el diseno anterior.

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
Cramer-v. Mises tests. {it:Ann. Math. Statist.} 30(2), 420-447. DOI:
10.1214/aoms/1177706261.

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
permutations. {it:Test} 27(4), 811-825. DOI: 10.1007/s11749-017-0571-1.

{pstd}
Sutherland, D.J., Schneider, J. (2015). On the Error of Random Fourier
Features. {it:UAI} 2015.

{pstd}
Ong, Z.P., Chen, A.A., Zhu, T., Zhang, J.-T. (2023). Testing Equality
of Several Distributions at High Dimensions: A Maximum-Mean-
Discrepancy-Based Approach. {it:Mathematics} 11(20), 4374. DOI:
10.3390/math11204374. ({bf:Corregida} 19sep2026 -- una version
anterior de esta cita tenia los autores equivocados y el numero de
articulo equivocado; ver la nota de verificacion en el encabezado de
{cmd:ksmmd.ado}.)

{pstd}
Zhang, J.-T., Guo, J., Zhou, B. (2024). Testing equality of several
distributions in separable metric spaces: a maximum mean discrepancy
based approach. {it:J. Econometrics} 239(2). ({bf:Corregida}
19sep2026 -- mismo motivo que arriba: autores y anio equivocados.)

{pstd}
Kim, I. (2021). Comparing a large number of multivariate
distributions. {it:Bernoulli} 27(1), 419-441. DOI: 10.3150/20-BEJ1244.

{pstd}
Sejdinovic, D., Sriperumbudur, B., Gretton, A., Fukumizu, K. (2013).
Equivalence of distance-based and RKHS-based statistics in hypothesis
testing. {it:Ann. Statist.} 41(5), 2263-2291. DOI: 10.1214/13-AOS1140.

{pstd}
Rizzo, M.L., Szekely, G.J. (2010). DISCO analysis: a nonparametric
extension of analysis of variance. {it:Ann. Appl. Stat.} 4(2),
1034-1055. DOI: 10.1214/09-AOAS245.

{pstd}
Szekely, G.J., Rizzo, M.L. (2004). Testing for Equal Distributions in
High Dimension. {it:InterStat}, Nov(5).

{pstd}
Rizzo, M.L., Szekely, G.J. (2016). Energy distance. {it:WIREs
Computational Statistics} 8(1), 27-38. DOI: 10.1002/wics.1375.

{pstd}
Garreau, D., Jitkrittum, W., Kanagawa, M. (2017). Large sample
analysis of the median heuristic. arXiv:1707.07269.

{pstd}
Reddi, S.J., Ramdas, A., Poczos, B., Singh, A., Wasserman, L. (2015).
On the High Dimensional Power of a Linear-Time Two Sample Test under
Mean-shift Alternatives. {it:Proc. AISTATS 2015}, PMLR v38.
arXiv:1411.6314.

{pstd}
Choi, I., Kim, I. (2024). Computational-Statistical Trade-off in
Kernel Two-Sample Testing with Random Fourier Features. arXiv:2407.08976.
({bf:Corregida} sep2026, tras leer el PDF completo: el primer autor es
Ikjun Choi, inicial correcta "I.", no "S." -- tercer error real de
atribucion en esta bibliografia, esta vez detectado por lectura de
texto completo, no por busqueda de metadatos.)

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
La version 0.5 tambien corrige dos errores de cita en la seccion de
Referencias de abajo (autores equivocados, y en un caso ademas el
numero de articulo equivocado) detectados al chequear la bibliografia
contra metadata de fuente primaria el 19sep2026, en respuesta a una
pregunta directa sobre si estas citas se habian verificado contra el
documento original antes de usar sus formulas -- no se habian
verificado; ver la nota de verificacion cerca del final del
encabezado de {cmd:ksmmd.ado} para el detalle de que se chequeo y que
no.

{pstd}
La version 0.6 revisa la bibliografia contra los PDF {bf:completos}
(compartidos por el usuario via Google Drive; 15 de 16 leidos de punta
a punta). Esa lectura completa encontro 3 correcciones adicionales que
la verificacion de metadatos de la version 0.5 no podia detectar
(errores de CONTENIDO/formula, no solo de autor/anio/DOI): la cota de
Sutherland & Schneider (revertida de MMD^2 a MMD, cita corregida de
"Theorem 1" a "Seccion 3.3"), la motivacion de {cmd:mmdtype(fuse)}
(escala cuadratica de Reddi et al., no exponencial), y un tercer error
de atribucion (Choi, I., no Choi, S.) -- mas la aclaracion de que el
paper MMD-FUSE si recomienda un valor de lambda (lambda~n), del que
{cmd:ksmmd} se aparta deliberadamente. Sin cambios de algebra ni de
Mata -- ningun T_KS/T_MMD/p-valor cambia con esta version, solo texto
de documentacion; ver el encabezado de {cmd:ksmmd.ado} (v0.6) para el
detalle completo de las correcciones y las mejoras de documentacion
agregadas.

{pstd}
La version 0.7 implementa las 5 mejoras de diseno que la lectura de la
v0.6 habia dejado como trabajo futuro, cada una re-validada con su
propia simulacion Monte Carlo de tasa de error Tipo I antes de
aplicarse (R=2.000, k=4, los mismos 3 escenarios de peso adversos que
el resto de este comando -- {cmd:sim/simulacion_ksmmd_v07_tipo1.py} /
{cmd:resultados_ksmmd_v07_tipo1.txt} -- tasas de rechazo entre 3.6% y
5.8% en los 3 escenarios para {opt mmdtype(vspool)},
{opt mmdtype(maxpairwise)} {bf:y} {opt mmdtype(fuse)}, sin inflacion
frente al 5% nominal; un chequeo algebraico aparte confirma que el
estadistico reescrito coincide, hasta error de punto flotante, con la
formula de v0.6 cuando el nuevo de-bias esta apagado): un estimador de
MMD insesgado (U-estadistico), una construccion "z-tilde" de random
Fourier features de menor varianza, una formula lambda~n y una grilla
de bandwidths por cuantiles con 2 familias de kernel para
{opt mmdtype(fuse)}, y una submuestra ponderada (en vez de uniforme)
para el bandwidth por heuristica de mediana. T_KS queda igual; T_MMD
{bf:si} cambia respecto a v0.6 en las 3 opciones de {opt mmdtype()}
(un estimador distinto y mas eficiente de la misma cantidad
poblacional, no una hipotesis nula distinta) -- ver
{help ksmmd_es##remarks_mmdtype:Comentarios} (mmdtype()) y
{help ksmmd_es##remarks_rff:Comentarios} (MMD via Random Fourier
Features) para el detalle de cada cambio. La reescritura Mata de esta
version se {bf:confirmo contra Stata real en ambas escalas} (21sep2026):
a escala chica ({cmd:auto.dta}, 5 variantes de sintaxis cubriendo las
3 opciones de {opt mmdtype()}, las 5 sin error) y a {bf:escala de
produccion} (un outcome real de encuesta agrupado por una variable
ordinal, N~141.000 en 4 grupos, ponderado por un peso de encuesta
continuo, {opt reps(200)} {opt nfeatures(500)} con
{opt graph}/{opt posthoc}: 155.42 segundos,
sin error; mas {opt ksonly}, {opt mmdonly}, un {opt bw()} fijo, y una
corrida agil; mas, tras un bug real encontrado y corregido en
{opt mmdtype(maxpairwise)} ese mismo dia (ver la nota de validacion
abajo), una corrida de seguimiento en produccion que confirmo tambien
{opt mmdtype(maxpairwise)} y {opt mmdtype(fuse)}, incluyendo
{opt fuse} con {opt nfeatures(500)} -- 5.000 columnas de {cmd:Phi},
sin problema de memoria) -- KS y las {bf:3} opciones de
{opt mmdtype()} quedan confirmadas ahora en {bf:ambas} escalas; no
queda ninguna configuracion pendiente para v0.7. Ver la nota de
validacion bajo {help ksmmd_es##remarks_mmdtype:Comentarios}
(mmdtype()) para las corridas y valores exactos, el detalle del bug y
su fix, y por que T_MMD ahora puede salir negativo (esperado, no un
error).

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
