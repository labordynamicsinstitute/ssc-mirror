{smcl}
{* *! version 1.0  22jul2026}{...}
{viewerjumpto "Sintaxis" "atip_mahal##syntax"}{...}
{viewerjumpto "Descripcion" "atip_mahal##description"}{...}
{viewerjumpto "Opciones" "atip_mahal##options"}{...}
{viewerjumpto "Resultados almacenados" "atip_mahal##results"}{...}
{viewerjumpto "Metodos y formulas" "atip_mahal##methods"}{...}
{viewerjumpto "Validacion" "atip_mahal##validation"}{...}
{viewerjumpto "Ejemplos" "atip_mahal##examples"}{...}
{viewerjumpto "Autor" "atip_mahal##author"}{...}
{title:Titulo}

{phang}
{bf:atip_mahal} {hline 2} Distancia de Mahalanobis MULTIVARIADA (2 o mas variables)


{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:atip_mahal} {varlist} {ifin}{cmd:,}
{cmdab:group:(}{varlist}{cmd:)}
[{it:opciones}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Requerida}
{synopt:{cmdab:group:(}{varlist}{cmd:)}}variable(s) que definen el grupo de referencia{p_end}

{syntab:Opcionales}
{synopt:{cmdab:alpha:(}{it:#}{cmd:)}}percentil de la chi-cuadrado usado como umbral; por defecto {cmd:alpha(0.995)}{p_end}
{synopt:{cmdab:gen:(}{it:name}{cmd:)}}nombre de la variable de flag (0/1); por defecto {cmd:MAHAL_MV}{p_end}
{synopt:{cmdab:gendist:(}{it:name}{cmd:)}}nombre de la variable con D2; por defecto {cmd:D2_MV}{p_end}
{synopt:{cmd:classic}}usa covarianza clasica en vez de MCD. {bf:Por defecto (sin esta opcion) se usa MCD} (Minimum Covariance Determinant, Rousseeuw & Van Driessen 1999) -- ver seccion {bf:Robustez (MCD)} abajo{p_end}
{synopt:{cmdab:support:(}{it:#}{cmd:)}}fraccion de observaciones usada como subconjunto "apretado" en MCD; por defecto {cmd:support(0.75)}{p_end}
{synopt:{cmdab:nstarts:(}{it:#}{cmd:)}}numero de arranques aleatorios del algoritmo MCD; por defecto {cmd:nstarts(20)}{p_end}
{synopt:{cmdab:seed:(}{it:#}{cmd:)}}semilla aleatoria para MCD; por defecto {cmd:seed(12345)}{p_end}
{synopt:{cmd:graph}}dibuja la elipse de tolerancia (contorno del umbral chi2) superpuesta a los puntos, una elipse por grupo. {bf:Solo disponible con exactamente 2 variables (k=2)}{p_end}
{synopt:{cmdab:npoints:(}{it:#}{cmd:)}}resolucion de la elipse (numero de puntos del contorno); por defecto {cmd:npoints(200)}{p_end}
{synopt:{cmd:compare}}con {cmd:graph}, superpone la elipse clasica Y la MCD (con sus respectivos centroides) en el mismo grafico, para comparar visualmente el efecto del enmascaramiento -- estilo comparativo de multiples metodos (Rousseeuw & Van Driessen 1999){p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:atip_mahal} calcula la distancia de Mahalanobis {bf:genuinamente
multivariada} entre 2 o mas variables, usando su matriz de
covarianza -- a diferencia de la regla MHLBS de {help atip_reglas},
que es univariada (equivale a z² de una sola variable, sin considerar
relaciones entre variables).

{pstd}
Detecta {bf:combinaciones anomalas} que ningun z-score univariado
puede ver: por ejemplo, un productor con superficie declarada dentro
de rango normal Y produccion dentro de rango normal, pero cuya
combinacion implica un rendimiento absurdo -- exactamente el tipo de
anomalia que interesa detectar en variables tipo RDTO, pero que
{cmd:atip_reglas}/{cmd:atip_score} no pueden ver porque solo trabajan
sobre el rendimiento ya calculado (un solo numero), no sobre sus
componentes por separado.

{pstd}
{bf:Formula:} D² = (x-media)' Σ⁻¹ (x-media), calculado dentro de cada
{cmd:group()}. El umbral es el percentil {cmd:alpha()} de una
distribucion chi-cuadrado con k grados de libertad (k = numero de
variables).


{marker options}{...}
{title:Opciones}

{phang}
{cmdab:group:(}{varlist}{cmd:)} {it:(requerida)} variable(s) que
definen el grupo dentro del cual se calcula la media vectorial y la
matriz de covarianza de referencia.

{phang}
{cmdab:alpha:(}{it:#}{cmd:)} percentil de la chi-cuadrado usado como
umbral de deteccion. Por defecto 0.995 (equivalente, para 1 variable,
al umbral 8 aproximado de MHLBS en {cmd:atip_reglas}). Valores mas
altos (ej. 0.999) hacen el criterio mas estricto.

{phang}
{cmdab:gen:(}{it:name}{cmd:)} / {cmdab:gendist:(}{it:name}{cmd:)}
nombres de las variables de salida (flag binario y distancia D2
continua, respectivamente).

{phang}
{cmd:graph} dibuja la {bf:elipse de tolerancia} -- el contorno
{x : (x-media)'Sigma^-1(x-media)=umbral} -- superpuesto a los puntos,
calculada via descomposicion espectral de la covarianza de referencia
(Rousseeuw & Leroy 1987, {it:Robust Regression and Outlier Detection},
Wiley). Se dibuja {bf:una elipse por cada valor de {cmd:group()}}, ya
que cada grupo tiene su propia referencia. Los puntos se colorean
segun {cmd:gen()} (gris=no outlier, rojo=outlier). Requiere
exactamente {bf:2 variables} -- con 3 o mas, el contorno seria un
elipsoide que no se puede graficar en 2D directamente; se documenta
como mejora pendiente (ver nota al final de esta seccion).

{phang}
{cmdab:npoints:(}{it:#}{cmd:)} controla la resolucion de la elipse
(cuantos puntos se usan para dibujar el contorno). 200 por defecto es
mas que suficiente para una curva visualmente lisa.


{marker results}{...}
{title:Resultados almacenados}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Escalares}{p_end}
{synopt:{cmd:r(n_outliers)}}numero de observaciones marcadas{p_end}
{synopt:{cmd:r(threshold)}}umbral chi2(k, alpha) usado{p_end}
{synopt:{cmd:r(nvars)}}numero de variables (k) usadas{p_end}
{p2colreset}{...}


{marker methods}{...}
{title:Metodos y formulas}

{pstd}
Para cada grupo, se calcula la media vectorial y la matriz de
covarianza (muestral, ddof=1) de las variables en {varlist}. Para
cada observacion, D² es la distancia de Mahalanobis al centro del
grupo, ponderada por la matriz de covarianza inversa -- geometricamente,
mide cuantas "elipses de covarianza" separan al punto del centro,
en vez de cuantas desviaciones estandar en cada eje por separado.

{pstd}
{bf:Grupos con muy pocos casos o covarianza singular} (variables
perfectamente colineales) se omiten silenciosamente (D2 queda
missing para esos casos), avisando la cantidad afectada en pantalla.

{pstd}
{bf:Limitacion de la covarianza CLASICA (comportamiento por defecto,
sin {cmd:mcd}):} tiene el mismo problema de enmascaramiento (masking)
que la media/SD univariada de {help atip_reglas} en su modo
{cmd:classic} -- con varios outliers multivariados simultaneos, se
inflan la covarianza y se esconden entre si.

{pstd}
{bf:Opcion {cmd:mcd}:} implementa Minimum Covariance Determinant
(Rousseeuw & Van Driessen 1999, "A Fast Algorithm for the Minimum
Covariance Determinant Estimator", Technometrics) -- busca el
subconjunto de tamaño {cmd:support()}·n con menor determinante de
covarianza (el nucleo "mas apretado" de los datos), y calcula la
referencia SOLO con ese subconjunto, ignorando los puntos mas
dispersos al construir la vara de medir. Punto de ruptura hasta 50%,
igual filosofia que {cmd:robust} en {help atip_reglas} pero para el
caso multivariado. La covarianza cruda del subconjunto se reescala
con el factor de consistencia estandar de Croux & Haesbroeck (1999).


{marker validation}{...}
{title:Robustez (MCD) y estado de validacion general}

{pstd}
{bf:Comparacion de 3 metodos (1000 datasets simulados, 22jul2026):}
Mahalanobis clasico, "leave-one-out" (LOO, cada punto evaluado
excluyendose a si mismo de su propia referencia), y MCD. Recall
(sensibilidad) por nivel de contaminacion:

{phang2}3% de contaminacion:  Clasico 100%   LOO 100%   MCD 100%{p_end}
{phang2}5% de contaminacion:  Clasico 90.2%   LOO 97.0%   MCD 100%{p_end}
{phang2}10% de contaminacion:  Clasico 1.2%   LOO 8.1%   MCD 100%{p_end}
{phang2}20% de contaminacion:  Clasico 0.0%   LOO 0.0%   MCD 100%{p_end}

{pstd}
{bf:Clasico y LOO colapsan catastroficamente a partir de 10% de
contaminacion} (recall cercano a 0%) -- LOO solo protege a un punto
de distorsionar SU PROPIA referencia, pero con varios outliers
simultaneos siguen distorsionando la referencia de los demas entre
si (no tiene un punto de ruptura real). {bf:MCD se mantuvo en 100% de
deteccion en todos los niveles}, a cambio de un costo pequeño en
calibracion: falsos positivos bajo datos limpios ≈1.2% (vs. 0.5%
esperado con {cmd:alpha(0.995)}), sustancialmente mejor que dejar el
problema sin resolver.

{pstd}
{bf:Por eso MCD es el comportamiento POR DEFECTO.} Use {cmd:classic}
solo si tiene una razon especifica para no querer la proteccion
adicional (ej. replicar exactamente resultados de una version previa
del pipeline). Si el grupo es muy chico y el algoritmo MCD no
converge bien, el comando cae automaticamente al calculo clasico y
avisa en pantalla -- no hay riesgo real de dejar el default activado
siempre.

{pstd}
{bf:Sobre el metodo clasico (sin {cmd:mcd}):} bajo datos limpios sin
outliers, su calibracion es buena (falsos positivos 0.37%, cercano al
0.5% esperado). Su potencia depende fuertemente de {bf:cuanto se
rompe la correlacion esperada}, no solo de que exista contaminacion:
con una violacion fuerte de la correlacion (2-3 SD en direccion
opuesta a lo esperado) la deteccion fue 100% incluso sin {cmd:mcd},
pero con una violacion mas moderada (1-1.5 SD) cayo a ~27% -- es
decir, {cmd:atip_mahal} es muy bueno detectando combinaciones
{it:claramente} anomalas, pero no sustituye a las reglas univariadas
de {help atip_reglas} para detectar valores extremos en una sola
dimension.


{marker examples}{...}
{title:Ejemplos}

{pstd}Ejemplo de la documentacion (superficie/produccion, 6 puntos) -- caso por DEFECTO (MCD){p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input sup prod grupo}{p_end}
{phang2}{cmd:. 2.0  7.5  1}{p_end}
{phang2}{cmd:. 2.5 10.5  1}{p_end}
{phang2}{cmd:. 3.0 11.0  1}{p_end}
{phang2}{cmd:. 3.5 15.0  1}{p_end}
{phang2}{cmd:. 4.0 15.0  1}{p_end}
{phang2}{cmd:. 4.0  8.0  1}{p_end}
{phang2}{cmd:. end}{p_end}
{phang2}{cmd:. atip_mahal sup prod, group(grupo) alpha(0.90)}{p_end}
{phang2}{cmd:. list sup prod D2_MV MAHAL_MV}{p_end}

{pstd}
{bf:Resultado real (verificado, seed(12345) por defecto):} el punto
anomalo (fila 6: sup=4.0, prod=8.0) da {bf:D2≈57.15}, por encima del
umbral chi2(2,0.90)=4.605 -- {bf:MAHAL_MV=1}, correctamente detectado.
Los otros 5 puntos dan D2 entre 0.60 y 1.78, todos por debajo del
umbral.

{pstd}Mismo ejemplo con {cmd:classic} -- para comparar{p_end}
{phang2}{cmd:. atip_mahal sup prod, group(grupo) alpha(0.90) classic}{p_end}
{phang2}{cmd:. list sup prod D2_MV MAHAL_MV}{p_end}

{pstd}
{bf:Resultado real:} con {cmd:classic}, el mismo punto anomalo da
{bf:D2≈3.91} -- por DEBAJO del umbral 4.605, {bf:MAHAL_MV=0}, NO
detectado. Esta comparacion, con solo 6 observaciones, ya muestra la
ventaja practica de MCD: el mismo caso claramente anomalo pasa de
"no detectado" (clasico) a "detectado" (MCD por defecto), porque MCD
excluye al propio punto anomalo de calcular su vara de medir, en vez
de dejar que la distorsione.

{pstd}
{bf:Sobre el D2≈74 de la documentacion de {help atip_reglas}:} ese
numero usa una tercera metodologia distinta -- referencia externa
manual (solo los 5 puntos limpios, calculada en Mata directamente sin
usar {cmd:atip_mahal}), evaluando el sexto por fuera de ese calculo.
Los tres numeros (3.91 clasico, 57.15 MCD, 74.0 referencia externa
manual) son todos "correctos" para su propia metodologia -- la
lectura util es que los tres coinciden en la DIRECCION (el punto 6 es
claramente el mas anomalo de los seis), aunque no en la escala
exacta.

{pstd}Con auto.dta (weight y length, dos variables continuas correlacionadas) -- usa MCD por defecto{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. atip_mahal weight length, group(foreign)}{p_end}
{phang2}{cmd:. list make weight length D2_MV if MAHAL_MV==1, sep(0)}{p_end}

{pstd}Comparando contra {cmd:classic} -- con contaminacion baja deberian ser similares{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. atip_mahal weight length, group(foreign)}{p_end}
{phang2}{cmd:. rename MAHAL_MV MAHAL_MV_mcd}{p_end}
{phang2}{cmd:. atip_mahal weight length, group(foreign) classic}{p_end}
{phang2}{cmd:. tab MAHAL_MV MAHAL_MV_mcd}{p_end}

{pstd}Con {cmd:graph} -- elipse de tolerancia, una por grupo{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. atip_mahal weight length, group(foreign) graph}{p_end}
{phang2}{cmd:. * verificado: los 4 outliers (AMC Pacer, Cad. Seville, Plym. Arrow,}{p_end}
{phang2}{cmd:. * Peugeot 604) caen visiblemente FUERA de la elipse de su grupo}{p_end}

{pstd}Con {cmd:graph compare} -- superpone elipse clasica y MCD, para ver el enmascaramiento{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. atip_mahal weight length, group(foreign) graph compare}{p_end}
{phang2}{cmd:. * la elipse clasica (gris) sale mas GRANDE que la MCD (naranja) --}{p_end}
{phang2}{cmd:. * la covarianza clasica esta inflada por los propios outliers que}{p_end}
{phang2}{cmd:. * se usaron para calcularla, mientras que MCD los excluye}{p_end}

{pstd}
{bf:Limitacion conocida de {cmd:graph}:} solo funciona con k=2
variables. Con k=3 o mas, el contorno del umbral es un elipsoide
(o hiperelipsoide) que no se puede graficar directamente en 2D. Una
extension pendiente para k>2 es el "distance-distance plot" (Rousseeuw
& Van Zomeren 1990, "Unmasking Multivariate Outliers and Leverage
Points", JASA) -- grafica D2 clasico (eje X) vs. D2 robusto MCD (eje
Y), funciona para cualquier k, pero no esta implementado en esta
version.


{marker author}{...}
{title:Autor / notas de desarrollo}

{pstd}
Andres Talavera Cuya{break}
Direccion Nacional de Censos y Encuestas -- INEI Peru{break}
Email: atalaveracuya@gmail.com

{pstd}
Complementa a
{help atip_reglas}, {help atip_score} y {help atip_volcano} (univariados)
para el caso donde la anomalia solo es visible en la relacion entre
dos o mas variables, no en ninguna por separado.

{hline}
{title:Licencia}

{pstd}
Este modulo se distribuye bajo los terminos de la GPL v3
({browse "https://www.gnu.org/licenses/gpl-3.0.txt":https://www.gnu.org/licenses/gpl-3.0.txt}).
