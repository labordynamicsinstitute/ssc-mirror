{smcl}
{* *! version 1.0  21jul2026}{...}
{viewerjumpto "Sintaxis" "atip_reglas##syntax"}{...}
{viewerjumpto "Descripcion" "atip_reglas##description"}{...}
{viewerjumpto "Opciones" "atip_reglas##options"}{...}
{viewerjumpto "Resultados almacenados" "atip_reglas##results"}{...}
{viewerjumpto "Metodos y formulas" "atip_reglas##methods"}{...}
{viewerjumpto "Robustez ante contaminacion" "atip_reglas##robustness"}{...}
{viewerjumpto "Ejemplos" "atip_reglas##examples"}{...}
{viewerjumpto "Autor" "atip_reglas##author"}{...}
{title:Titulo}

{phang}
{bf:atip_reglas} {hline 2} Deteccion de atipicos (outliers) por ensamble de 5 reglas clasicas


{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:atip_reglas} {varname}{cmd:,}
{cmdab:group:(}{varlist}{cmd:)}
[{it:opciones}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Requerida}
{synopt:{cmdab:group:(}{varlist}{cmd:)}}variable(s) que definen el grupo de referencia (ej. departamento, cultivo){p_end}

{syntab:Opcionales}
{synopt:{cmdab:rules:(}{it:string}{cmd:)}}subconjunto de reglas a aplicar, de {cmd:sd3 sd2 zscore iqr mahal}; por defecto las 5{p_end}
{synopt:{cmdab:sdthresh3:(}{it:#}{cmd:)}}umbral de la regla SD_MEAN_3; por defecto {cmd:sdthresh3(3)}{p_end}
{synopt:{cmdab:sdthresh2:(}{it:#}{cmd:)}}umbral de la regla SD_MEAN_2; por defecto {cmd:sdthresh2(2)}{p_end}
{synopt:{cmdab:zthresh:(}{it:#}{cmd:)}}umbral de la regla ZSCORE; por defecto {cmd:zthresh(2)}{p_end}
{synopt:{cmd:zsymmetric}}usa ZSCORE de dos colas (|z|>zthresh); por defecto es de una cola (z>zthresh){p_end}
{synopt:{cmdab:mahalthresh:(}{it:#}{cmd:)}}umbral de la regla MHLBS (Mahalanobis univariado = z^2); por defecto {cmd:mahalthresh(8)}{p_end}
{synopt:{cmdab:gen:(}{it:name}{cmd:)}}nombre de la variable de salida (union de las 5 reglas); por defecto {cmd:OUTLIERS}{p_end}
{synopt:{cmd:classic}}usa media y desviacion estandar clasicas en vez de mediana/MAD. {bf:Por defecto (sin esta opcion) se usa la referencia robusta} (mediana/MAD) -- ver seccion {bf:Robustez ante contaminacion} abajo{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:atip_reglas} aplica un ensamble de 5 reglas clasicas de deteccion
de atipicos (outliers) dentro de cada grupo definido por {cmd:group()}:
desviacion respecto a la media (3 y 2 desviaciones estandar), z-score,
rango intercuartilico (Tukey) y distancia de Mahalanobis univariada.
Genera una variable binaria (por defecto {cmd:OUTLIERS}) que marca 1
si {it:cualquiera} de las reglas activas dispara para esa observacion
(union, no interseccion) -- una estrategia de alta sensibilidad
pensada para screening/pre-revision, no para confirmacion estadistica
formal.

{pstd}
Este comando corrige dos problemas frecuentes en implementaciones
tipicas de estas reglas: (1) la regla IQR suele usar {bf:OR} en vez de
{bf:AND} en la condicion de "valor normal", lo que anula silenciosamente
la deteccion de atipicos por el lado bajo; aqui esta corregido. (2) La
regla ZSCORE suele detectar solo un lado (cola alta); aqui es asi por
defecto tambien (para no romper el comportamiento esperado por defecto),
pero {cmd:zsymmetric} permite usar la version de dos colas.

{pstd}
La distancia de Mahalanobis, al ser univariada aqui, es
matematicamente identica al cuadrado del z-score -- se calcula
directamente como tal, sin necesidad de {cmd:mahascore} ni {cmd:frame}s.

{pstd}
Vease tambien {help atip_score} (generaliza esto a dos ejes continuos
en vez de un flag binario) y {help atip_volcano} (grafico de
magnitud vs. evidencia).


{marker options}{...}
{title:Opciones}

{phang}
{cmdab:group:(}{varlist}{cmd:)} {it:(requerida)} variable(s) que
definen el grupo dentro del cual se calculan media, desviacion
estandar y cuartiles de referencia (ej. {cmd:CCDD_ P204_NOM P204_COD}).

{phang}
{cmdab:rules:(}{it:string}{cmd:)} permite activar solo un subconjunto
de las 5 reglas, por ejemplo {cmd:rules(iqr mahal)} para usar solo
esas dos. Por defecto se aplican las 5: {cmd:sd3 sd2 zscore iqr mahal}.

{phang}
{cmd:zsymmetric} cambia la regla ZSCORE de una cola (solo valores
altos) a dos colas (altos y bajos). Util si el interes no se limita a
valores anormalmente altos.

{phang}
{cmdab:gen:(}{it:name}{cmd:)} nombre de la variable binaria de salida.
Ademas de esta, el comando genera (y no elimina) las variables
intermedias {cmd:SD_MEAN_3}, {cmd:SD_MEAN_2}, {cmd:ZSCORE_I},
{cmd:ZSCORE}, {cmd:IQR}, {cmd:DIST}, {cmd:MHLBS} -- utiles para
inspeccionar que regla especifica disparo en cada caso.


{marker results}{...}
{title:Resultados almacenados}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Escalares}{p_end}
{synopt:{cmd:r(n_outliers)}}numero de observaciones marcadas por la variable de salida{p_end}
{p2colreset}{...}


{marker methods}{...}
{title:Metodos y formulas}

{pstd}
{bf:SD_MEAN_3 / SD_MEAN_2:} marca 1 si el valor esta fuera de
media ± k·DE (k=3 o k=2), calculado dentro de cada {cmd:group()}.

{pstd}
{bf:ZSCORE:} z = (x-media)/DE; marca 1 si z>zthresh (una cola, por
defecto) o |z|>zthresh (con {cmd:zsymmetric}).

{pstd}
{bf:IQR (Tukey):} marca 1 si x esta fuera de
[Q1-1.5·RIC, Q3+1.5·RIC], con RIC=Q3-Q1, calculado dentro de cada
{cmd:group()}.

{pstd}
{bf:MHLBS:} distancia de Mahalanobis univariada, DIST=z^2; marca 1 si
DIST>mahalthresh. Bajo normalidad, DIST sigue una chi-cuadrado con 1
grado de libertad.

{pstd}
{bf:Union:} la variable de salida es 1 si cualquiera de las reglas
activas dio 1 para esa observacion.


{marker robustness}{...}
{title:Robustez ante contaminacion (efecto de enmascaramiento)}

{pstd}
{bf:Hallazgo (validado por simulacion, 1000 datasets, 74,000
observaciones, 21jul2026):} las reglas basadas en media/desviacion
estandar (SD_MEAN_3, SD_MEAN_2, ZSCORE, MHLBS) sufren de
{it:enmascaramiento} (masking, Hampel et al. 1986): a mayor
proporcion de outliers verdaderos en los datos, la propia presencia
de esos outliers infla la media y la desviacion estandar de
referencia, haciendo que los outliers dejen de verse "extremos"
relativos a una vara de medir ya distorsionada. La media y la SD
tienen punto de ruptura 0% -- un solo valor extremo puede desplazar
la media arbitrariamente.

{pstd}
En la simulacion, la sensibilidad (recall) del criterio estricto
(N_REGLAS>=3, equivalente a exigir 3 de las 5 reglas) cayo asi con
el nivel de contaminacion real de la muestra:

{phang2}3% de contaminacion: recall (mean/SD) = 95.5%{p_end}
{phang2}5% de contaminacion: recall (mean/SD) = 85.3%{p_end}
{phang2}10% de contaminacion: recall (mean/SD) = 66.6%{p_end}
{phang2}20% de contaminacion: recall (mean/SD) = 27.4%{p_end}

{pstd}
{bf:La regla IQR (Tukey) no sufre este problema} -- tiene punto de
ruptura 25% (aguanta hasta un cuarto de datos contaminados sin
distorsionarse), por eso {cmd:atip_reglas} (union de las 5 reglas)
se mantiene con recall >92% incluso al 20% de contaminacion: la
propia union rescata lo que las reglas basadas en SD pierden.

{pstd}
{bf:Por eso, desde esta version, la referencia robusta (mediana/MAD)
es el comportamiento POR DEFECTO} de {cmd:atip_reglas}/{cmd:atip_score},
reemplazando media/SD por mediana y MAD (median absolute deviation),
escalada por la constante de consistencia 1.4826 para que sea
comparable a una SD bajo normalidad (Iglewicz & Hoaglin 1993, "How to
Detect and Handle Outliers", ASQC Press). La mediana tiene punto de
ruptura 50%. Verificado por simulacion: el recall del criterio
estricto al 20% de contaminacion sube de 27.4% (media/SD) a
{bf:95.5%} (mediana/MAD).

{pstd}
{bf:Resguardo ante empates:} si en un grupo mas de la mitad de los
valores son identicos a la mediana, el MAD sale 0, lo cual haria que
el z-score robusto se disparara a infinito para cualquier desviacion
minima. En ese caso, {cmd:atip_reglas} usa automaticamente media/SD
como respaldo {it:solo para ese grupo} (el resto de grupos sigue
usando mediana/MAD), y avisa en pantalla cuantas observaciones se
vieron afectadas. Este escenario es mas comun de lo que parece con
datos de encuesta muy redondeados o con muchas respuestas identicas.

{pstd}
{bf:Use {cmd:classic}} para volver al comportamiento anterior
(media/SD unicamente, sin mediana/MAD ni el resguardo de empates) --
por ejemplo para replicar exactamente resultados de una version
previa del pipeline, o si por alguna razon especifica se prefiere la
referencia clasica.

{pstd}
{bf:Recomendacion practica:} deje el default (robusto) en la gran
mayoria de casos -- con contaminacion baja (pocos casos dispersos),
clasico y robusto dan resultados casi identicos, asi que no hay costo
real en dejarlo activado siempre; con contaminacion alta o
sistematica (ej. un error de captura que afecta a toda una sede
operativa), el default robusto es sustancialmente mejor. Use
{cmd:classic} solo si tiene una razon especifica para no querer la
proteccion adicional.


{marker examples}{...}
{title:Ejemplos}

{pstd}Deteccion basica sobre auto.dta (price por foreign){p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. atip_reglas price, group(foreign)}{p_end}
{phang2}{cmd:. list make foreign price OUTLIERS if OUTLIERS==1, sep(0)}{p_end}

{pstd}Usando solo IQR y Mahalanobis, con ZSCORE de dos colas si se activara{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. atip_reglas price, group(foreign) rules(iqr mahal)}{p_end}

{pstd}Con nlsw88.dta (wage por union){p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. drop if missing(wage, union)}{p_end}
{phang2}{cmd:. atip_reglas wage, group(union) zsymmetric}{p_end}
{phang2}{cmd:. tab union OUTLIERS}{p_end}

{pstd}Comparando el default (robusto) contra {cmd:classic} -- con contaminacion baja (como auto.dta) deberian ser similares{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. atip_reglas price, group(foreign)}{p_end}
{phang2}{cmd:. rename OUTLIERS OUTLIERS_robusto}{p_end}
{phang2}{cmd:. atip_reglas price, group(foreign) classic}{p_end}
{phang2}{cmd:. tab OUTLIERS OUTLIERS_robusto}{p_end}

{pstd}{bf:Mahalanobis MULTIVARIADO (2 variables) -- fuera del alcance de {cmd:atip_reglas}, ilustrativo}{p_end}
{pstd}La regla MHLBS de {cmd:atip_reglas} es univariada (equivale a z²
de una sola variable). El siguiente bloque en Mata muestra el caso
{bf:genuinamente} multivariado -- superficie y produccion juntas,
usando su correlacion -- que detecta un productor con ambas variables
individualmente normales pero cuya COMBINACION rompe el patron
esperado (ver seccion "Ejemplos" mas abajo para el detalle numerico
completo){p_end}
{phang2}{cmd:. mata:}{p_end}
{phang2}{cmd:: sup  = (2.0\2.5\3.0\3.5\4.0)}{p_end}
{phang2}{cmd:: prod = (7.5\10.5\11.0\15.0\15.0)}{p_end}
{phang2}{cmd:: X = sup,prod}{p_end}
{phang2}{cmd:: media = mean(X)}{p_end}
{phang2}{cmd:: S = variance(X)}{p_end}
{phang2}{cmd:: Sinv = luinv(S)}{p_end}
{phang2}{cmd:: nuevo = (4.0,8.0)}{p_end}
{phang2}{cmd:: diff = nuevo - media}{p_end}
{phang2}{cmd:: D2 = diff*Sinv*diff'}{p_end}
{phang2}{cmd:: D2}{p_end}
{phang2}{cmd:: end}{p_end}
{phang2}{cmd:. * D2 deberia salir ~74 -- muy por encima de un caso tipico (D2<2),}{p_end}
{phang2}{cmd:. * a pesar de que ni superficie=4 ni produccion=8 son individualmente}{p_end}
{phang2}{cmd:. * atipicos en sus respectivas distribuciones marginales}{p_end}

{pstd}
{bf:Nota:} este bloque calcula media/covarianza usando SOLO los 5
puntos de referencia (sin el sexto), evaluando el caso nuevo por
fuera -- una referencia "externa" o "limpia". El comando
{help atip_mahal} calcula media/covarianza {bf:incluyendo} todas las
observaciones del grupo (referencia "auto-inclusiva", igual criterio
que el resto de {cmd:atip_reglas}), asi que con muestras chicas puede
dar un D2 bastante menor para el mismo caso, por el efecto de
enmascaramiento -- ver {help atip_mahal##examples:atip_mahal,
seccion Ejemplos} para el mismo caso corrido con el comando real.


{marker author}{...}
{title:Autor / notas de desarrollo}

{pstd}
Andres Talavera Cuya{break}
Direccion Nacional de Censos y Encuestas -- INEI Peru{break}
Email: atalaveracuya@gmail.com

{pstd}
Comandos relacionados: {help atip_score} y {help atip_volcano} --
instalar los tres juntos ({cmd:atip_score} llama a {cmd:atip_reglas}
internamente).

{hline}
{title:Licencia}

{pstd}
Este modulo se distribuye bajo los terminos de la GPL v3
({browse "https://www.gnu.org/licenses/gpl-3.0.txt":https://www.gnu.org/licenses/gpl-3.0.txt}).
