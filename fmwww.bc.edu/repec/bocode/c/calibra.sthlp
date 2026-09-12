{smcl}
{* *! version 1.0.0  10sep2026}{...}
{vieweralsosee "svyset" "help svyset"}{...}
{vieweralsosee "ipfraking" "help ipfraking"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "calibra##syntax"}{...}
{viewerjumpto "Description" "calibra##description"}{...}
{viewerjumpto "Options" "calibra##options"}{...}
{viewerjumpto "Remarks" "calibra##remarks"}{...}
{viewerjumpto "Examples" "calibra##examples"}{...}
{viewerjumpto "Stored results" "calibra##results"}{...}
{viewerjumpto "References" "calibra##references"}{...}
{title:Title}

{phang}
{bf:calibra} {hline 2} Calibracion de factores de expansion (pesos muestrales)
por el metodo de Deville y Sarndal (1992)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:calibra} {varlist} {ifin} {cmd:[}{cmd:pweight}{cmd:=}{it:pesodis}{cmd:]}{cmd:,}
{cmd:generate(}{it:nuevopeso}{cmd:)} {cmd:totals(}{it:numlist}{cmd:)}
{cmd:[}{cmd:method(}{it:linear}{cmd:|}{it:raking}{cmd:|}{it:logit}{cmd:)}
{cmd:bounds(}{it:L U}{cmd:)} {cmd:tolerance(}{it:#}{cmd:)}
{cmd:iterate(}{it:#}{cmd:)} {cmd:nograph}{cmd:]}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Requeridas}
{synopt:{opt gen:erate(nuevopeso)}}nombre de la nueva variable con los pesos calibrados{p_end}
{synopt:{opt tot:als(numlist)}}totales poblacionales objetivo, uno por cada
variable en {it:varlist}, en el mismo orden{p_end}

{syntab:Opcionales}
{synopt:{opt meth:od(metodo)}}funcion de distancia: {cmd:linear} (por defecto),
{cmd:raking} o {cmd:logit}{p_end}
{synopt:{opt bo:unds(L U)}}limites inferior/superior para g{subscript:k}=w{subscript:k}/d{subscript:k}.
Obligatorio con {cmd:method(logit)}; opcional (recorte posterior) con
{cmd:linear} y {cmd:raking}{p_end}
{synopt:{opt tol:erance(#)}}tolerancia de convergencia para metodos iterativos;
por defecto {cmd:1e-6}{p_end}
{synopt:{opt iter:ate(#)}}numero maximo de iteraciones Newton-Raphson;
por defecto {cmd:100}{p_end}
{synopt:{opt nograph}}suprime el histograma del factor de ajuste g{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{cmd:calibra} requiere un peso de diseno especificado como {cmd:pweight}. Debe
ir precedido de {cmd:[pweight=}{it:pesodis}{cmd:]}. {it:varlist} debe ser
numerica (variables auxiliares de calibracion: dummies de dominio, tramos de
edad, etc.). {cmd:by} no esta permitido.


{marker description}{...}
{title:Description}

{pstd}
{cmd:calibra} ajusta los factores de expansion iniciales (pesos de diseno
d{subscript:k}) de una encuesta por muestreo, produciendo nuevos pesos
calibrados w{subscript:k} tales que los totales estimados de un conjunto de
variables auxiliares reproducen {it:exactamente} los totales poblacionales
conocidos (proyecciones de poblacion, totales de marco muestral, resultados
censales), minimizando una funcion de distancia entre w{subscript:k} y
d{subscript:k}. Este es el principio del estimador GREG (regresion
generalizada) de Deville y Sarndal (1992), ampliamente usado en el ajuste de
factores de expansion de encuestas de hogares (ENAHO) y agropecuarias (ENA)
del INEI.


{marker options}{...}
{title:Options}

{dlgtab:Requeridas}

{phang}
{opt generate(nuevopeso)} nombra la variable que contendra los pesos
calibrados w{subscript:k}. Debe ser un nombre de variable nuevo.

{phang}
{opt totals(numlist)} lista de totales poblacionales conocidos, en el mismo
orden que las variables en {it:varlist}. Por ejemplo, si {it:varlist} es
{cmd:urbano rural}, {cmd:totals()} debe contener la poblacion proyectada
urbana y rural, en ese orden, de modo que la suma de ambos totales sea la
poblacion total del dominio de estimacion.

{dlgtab:Opcionales}

{phang}
{opt method(metodo)} funcion de distancia G(w,d) a minimizar:

{p2colset 9 24 26 2}{...}
{p2col:{cmd:linear}}distancia ji-cuadrado. Solucion cerrada (sin iteracion).
Es el GREG clasico. Puede producir g{subscript:k}=w{subscript:k}/d{subscript:k}
negativos o extremos si las variables auxiliares no estan bien escaladas o hay
dominios pequenos.{p_end}
{p2col:{cmd:raking}}razon exponencial (raking ratio generalizado). Siempre
produce g{subscript:k}>0. Iterativo (Newton-Raphson). Equivale al raking/IPF
clasico cuando las auxiliares son dummies de categorias.{p_end}
{p2col:{cmd:logit}}acota g{subscript:k} estrictamente dentro de
[L,U] especificado en {cmd:bounds()}. Iterativo. Es la opcion recomendada
cuando se requiere controlar el rango de variacion de los pesos por razones
de varianza/practicas de produccion (p.ej., ENAHO).{p_end}
{p2colreset}{...}

{phang}
{opt bounds(L U)} limites L y U (con L<1<U) para el factor de ajuste
g{subscript:k}=w{subscript:k}/d{subscript:k}.

{p 8 8 2}
Con {cmd:method(logit)} el acotamiento esta incorporado matematicamente en la
funcion de calibracion: ningun g{subscript:k} puede salir de [L,U], sin
importar cuantas iteraciones se requieran.

{p 8 8 2}
Con {cmd:method(linear)} o {cmd:method(raking)}, {cmd:bounds()} es opcional y
actua como un {it:recorte posterior}: se calcula la solucion sin restriccion
y luego se recortan a L o U los g{subscript:k} que excedan los limites. Esto
es una aproximacion practica (no una reoptimizacion completa como el metodo
lineal truncado de Deville-Sarndal-Sautory 1993); tras el recorte los
totales pueden no cuadrar de forma exacta, y {cmd:calibra} reporta cuantos
pesos fueron recortados.

{phang}
{opt tolerance(#)} tolerancia para declarar convergencia en {cmd:raking} y
{cmd:logit}: se detiene cuando el mayor desajuste absoluto entre el total
estimado y el objetivo es menor que {cmd:#}. Por defecto {cmd:1e-6}.

{phang}
{opt iterate(#)} numero maximo de iteraciones Newton-Raphson. Por defecto
{cmd:100}. Si no converge, {cmd:calibra} emite un aviso pero reporta los
pesos de la ultima iteracion.

{phang}
{opt nograph} suprime el histograma del factor de ajuste g=w/d que se
produce por defecto.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:El problema de calibracion.} Se busca w{subscript:k} que minimice
sum G(w{subscript:k},d{subscript:k}) sujeto a
sum w{subscript:k} x{subscript:k} = T, donde x{subscript:k} es el vector de
variables auxiliares de la unidad k y T el vector de totales poblacionales
conocidos. La condicion de primer orden siempre toma la forma
g{subscript:k} = w{subscript:k}/d{subscript:k} = F(x{subscript:k}'lambda),
donde F es la funcion de calibracion asociada a la distancia elegida, y
lambda es un vector de multiplicadores de Lagrange que se obtiene resolviendo
sum d{subscript:k} x{subscript:k} F(x{subscript:k}'lambda) = T.

{pstd}
{bf:Metodo lineal} (distancia ji-cuadrado, G(w,d)=(w-d)^2/2d): F(u)=1+u, lo
que hace el sistema lineal en lambda y da solucion cerrada:

{p 8 8 2}
lambda = (X'DX)^-1 (T - X'd),   g = 1 + X*lambda,   w = d*g

{pstd}
donde X es la matriz n x p de auxiliares, D=diag(d).

{pstd}
{bf:Raking} (distancia de Kullback-Leibler, G(w,d)=w*ln(w/d)-w+d): F(u)=exp(u).
La ecuacion de calibracion es no lineal y se resuelve por Newton-Raphson,
partiendo de lambda=0 (g=1):

{p 8 8 2}
lambda_(t+1) = lambda_t - J(lambda_t)^-1 * phi(lambda_t)

{pstd}
con phi(lambda)=X'(d*g)-T y J(lambda)=X'diag(d*g)X.

{pstd}
{bf:Logistico acotado}: para L<1<U, con c=(U-L)/[(1-L)(U-1)],

{p 8 8 2}
g(u) = [L(U-1) + U(1-L)e^(cu)] / [(U-1) + (1-L)e^(cu)]

{pstd}
que satisface g(0)=1, g->L cuando u->-infinito, g->U cuando u->+infinito.
Tambien se resuelve por Newton-Raphson, usando la derivada cerrada de g(u).

{pstd}
{bf:Recomendaciones practicas para ENAHO/ENA}: (1) incluya siempre, entre las
variables auxiliares, las categorias de post-estratificacion usadas en el
diseno (area urbano/rural, dominios geograficos) para asegurar consistencia
con las proyecciones de poblacion oficiales; (2) evite incluir simultaneamente
un conjunto completo de dummies de una variable categorica junto con un
termino constante, pues XtDX resulta singular (colinealidad exacta); (3) para
produccion de factores de expansion definitivos, {cmd:method(logit)} con
bounds() moderados (p.ej. 0.5 y 2) suele preferirse porque evita pesos
calibrados excesivamente dispares, a costa de mayor complejidad computacional.

{pstd}
{bf:Diferencias con {cmd:ipfraking} (Kolenikov)}: {cmd:ipfraking} implementa
especificamente el ajuste proporcional iterativo (IPF) clasico para
variables categoricas cruzadas (marginales de tablas de contingencia,
metodo de Deming-Stephan), reportando ademas diagnosticos especificos de
convergencia por margen. {cmd:calibra} generaliza el marco: acepta
variables auxiliares {it:continuas o categoricas} (no solo margenes de
tablas), permite elegir entre tres funciones de distancia distintas
(incluyendo la version lineal con solucion cerrada, y la logistica acotada,
ninguna de las cuales resuelve {cmd:ipfraking}), y devuelve directamente el
peso calibrado listo para {cmd:svyset}. En la practica: use {cmd:ipfraking}
si su problema es estrictamente ajustar margenes de una tabla de
contingencia (raking clasico multi-via); use {cmd:calibra} si necesita
variables auxiliares continuas, el metodo lineal (GREG), o control explicito
de los limites de g mediante el metodo logistico.


{marker examples}{...}
{title:Examples}

{pstd}Ejemplo con datos simulados que imitan una muestra ENAHO, calibrando
a totales por area (urbano/rural) y grupo de edad{p_end}

{phang2}{cmd:. } {stata "do ejemplo_calibra.do":ejemplo_calibra.do (ver archivo adjunto)}{p_end}

{pstd}Version resumida:{p_end}

{phang2}{cmd:. use enaho_simulada, clear}{p_end}
{phang2}{cmd:. calibra urbano rural edad_0_14 edad_15_64 edad_65mas [pweight=factor07], generate(factor_cal) totals(6200000 12500000 5100000 10800000 2800000) method(linear)}{p_end}

{phang2}{cmd:. calibra urbano rural edad_0_14 edad_15_64 edad_65mas [pweight=factor07], generate(factor_cal2) totals(6200000 12500000 5100000 10800000 2800000) method(logit) bounds(0.5 2)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:calibra} guarda lo siguiente en {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}numero de observaciones usadas{p_end}
{synopt:{cmd:r(converged)}}1 si el algoritmo iterativo convergio, 0 si no
(siempre 1 con method(linear)){p_end}
{synopt:{cmd:r(iter)}}numero de iteraciones Newton-Raphson realizadas{p_end}
{synopt:{cmd:r(ntrimmed)}}numero de pesos recortados por bounds()
(solo linear/raking){p_end}
{synopt:{cmd:r(gmin)}}valor minimo de g=w/d{p_end}
{synopt:{cmd:r(gmax)}}valor maximo de g=w/d{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(method)}}metodo utilizado{p_end}
{synopt:{cmd:r(generate)}}nombre de la variable con los pesos calibrados{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(totals_target)}}totales poblacionales objetivo{p_end}
{synopt:{cmd:r(totals_before)}}totales estimados con el peso de diseno original{p_end}
{synopt:{cmd:r(totals_after)}}totales estimados con el peso calibrado{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Deville, J.-C. and Sarndal, C.-E. 1992. Calibration Estimators in Survey
Sampling. {it:Journal of the American Statistical Association} 87(418):
376-382.

{phang}
Deville, J.-C., Sarndal, C.-E., and Sautory, O. 1993. Generalized Raking
Procedures in Survey Sampling. {it:Journal of the American Statistical
Association} 88(423): 1013-1020.

{phang}
Kolenikov, S. {cmd:ipfraking}: Stata module to perform iterative
proportional fitting (raking) of survey weights. Statistical Software
Components, Boston College.


{title:Author}

{phang}
{bf:Mario Anderson Apaza Ñupa} ({browse "mailto:rioma310@gmail.com":rioma310@gmail.com})

{phang}
{bf:Lirys Alejandra del Castillo Aliaga} ({browse "mailto:alejandra18lia@gmail.com":alejandra18lia@gmail.com})
  
