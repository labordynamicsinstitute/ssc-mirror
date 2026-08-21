{smcl}
{* *! version 1.1.0  16aug2026}{...}

{title:Title}

{phang}
{bf:svylet} {hline 2} Wald omnibus F-test, Bonferroni pairwise comparisons,
and Compact Letter Display (CLD) for means, proportions, and totals under
survey design


{title:Syntax}

{p 8 17 2}
{cmd:svylet} {varname} {ifin}{cmd:,}
{cmdab:over:(}{varname}{cmd:)}
{cmdab:stat:(}{cmd:mean}|{cmd:proportion}|{cmd:total}{cmd:)}
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmdab:over:(}{varname}{cmd:)}}grouping variable (e.g. survey year); 2+ categories{p_end}
{synopt:{cmdab:stat:(}{it:string}{cmd:)}}{cmd:mean}, {cmd:proportion}, or {cmd:total} -- which {cmd:svy} estimator to run{p_end}
{synopt:{cmdab:alpha:(}{it:#}{cmd:)}}significance level; default {cmd:alpha(0.05)}{p_end}
{synopt:{cmdab:level:(}{it:#}{cmd:)}}for {cmd:stat(proportion)} only: which value of {varname} counts as "success"; default {cmd:level(1)}{p_end}
{synopt:{cmdab:boot:(}{it:#}{cmd:)}}number of bootstrap replications to prepivot the omnibus F-test; default {cmd:boot(0)} (off, analytic F only){p_end}
{synopt:{cmdab:bseed:(}{it:#}{cmd:)}}seed for the bootstrap; default uses current Stata seed{p_end}
{synoptline}

{pstd}
Must be run after {cmd:svyset}.


{title:Description}

{pstd}
{cmd:svylet} tests whether a mean, proportion, or total differs across the
categories of {cmd:over()} (e.g., across survey years) under a complex
survey design, and reports the result as a Compact Letter Display:
categories sharing at least one letter are {bf:not} significantly
different from each other; categories sharing no letter {bf:are}
significantly different. This is the same convention used in agronomic
ANOVA post-hoc tables (Tukey/Duncan-style letter groupings), adapted here
to a design-based Wald test instead of classical ANOVA.

{pstd}
Specifically, {cmd:svylet} reports:

{phang2}1. A design-based Wald omnibus F-test for whether {it:any} category
differs from the others, using the small-sample adjustment of Korn &
Graubard (1990) -- the same adjustment Stata applies by default when
{help test} or {help testparm} follows any {cmd:svy:} estimation command.{p_end}

{phang2}2. All pairwise comparisons between categories, with Bonferroni
correction for multiple comparisons.{p_end}

{phang2}3. The resulting Compact Letter Display.{p_end}


{title:Options}

{phang}
{cmdab:over:(}{varname}{cmd:)} {it:(required)} grouping variable, e.g. year
of survey. Must have 2 or more distinct categories in the estimation
sample.

{phang}
{cmdab:stat:(}{cmd:mean}|{cmd:proportion}|{cmd:total}{cmd:)} {it:(required)}
selects the underlying {cmd:svy} estimation command.

{phang}
{cmdab:alpha:(}{it:#}{cmd:)} significance level for the omnibus test and
for building the CLD letter groups from the Bonferroni-adjusted pairwise
p-values. Default {cmd:alpha(0.05)}.

{phang}
{cmdab:level:(}{it:#}{cmd:)} relevant only for {cmd:stat(proportion)}: which
value of {varname} is the "success" category. Default {cmd:level(1)}.

{phang}
{cmdab:boot:(}{it:#}{cmd:)} number of bootstrap replications for
prepivoting the omnibus F (see {it:Remarks}). Default {cmd:boot(0)},
analytic F only.

{phang}
{cmdab:bseed:(}{it:#}{cmd:)} seed for {cmd:boot()}'s random number stream.


{title:Remarks}

{pstd}
Remarks are presented under the following headings:

{phang2}Benefits of using svylet{p_end}

{phang2}Working hypothesis{p_end}

{phang2}Degenerate variance{p_end}

{phang2}Bootstrap prepivoting of the omnibus F-test (boot()){p_end}

{dlgtab:Benefits of using svylet}

{phang2}- One command covers mean, proportion, and total, instead of three
separate ad hoc implementations with potentially inconsistent
significance logic.{p_end}

{phang2}- Does not depend on {help margins}/{help testparm} chaining
correctly after non-{cmd:regress} {cmd:svy:} commands -- builds directly
from {cmd:e(b)}/{cmd:e(V)}/{cmd:e(df_r)}, which every {cmd:svy:} command
returns.{p_end}

{phang2}- Uses the Korn & Graubard (1990) adjustment, Stata's own default
for {cmd:test}/{cmd:testparm} after {cmd:svy:} -- results match the
official command exactly, not an approximation.{p_end}

{phang2}- Reports results as a Compact Letter Display: easier to read at
a glance than a table of up to k(k-1)/2 pairwise p-values.{p_end}

{phang2}- Explicitly detects and flags degenerate variance (e.g. a
proportion of exactly 0 or 1) instead of silently misreporting it as "no
difference."{p_end}

{phang2}- Optional bootstrap prepivoting ({cmd:boot()}) for domains where
the design degrees of freedom are small and the asymptotic F reference
may be imprecise.{p_end}

{phang2}- Generalizes to any grouping variable in {cmd:over()} -- not
limited to comparing years, though that is the most common use.{p_end}

{dlgtab:Working hypothesis}

{pstd}
{bf:In svylet, specifically}

{pstd}
Let theta_1, ..., theta_k denote the population mean/proportion/total of
the {cmd:k} categories of {cmd:over()}, R the (k-1) x k contrast matrix
that compares each category against a reference category (the one
{cmd:svylet} uses internally), and r = 0. Every test below is a Wald test
of R*theta = r: it only needs the unrestricted estimate and its variance,
so {cmd:svylet} builds it directly from {cmd:e(b)}/{cmd:e(V)}, without
re-estimating anything under the null.

{pstd}
{bf:Omnibus F}: H0: theta_1 = theta_2 = ... = theta_k (no real difference
anywhere). H1: {it:not all} theta_i are equal (generic: it does not say
which category differs or in what direction, only that full equality
fails).

{pstd}
{bf:Pairwise Bonferroni comparisons}: for each pair (i,j), H0: theta_i =
theta_j (those two specific categories are equal); H1: theta_i is not
equal to theta_j (two-sided: neither "greater than" nor "less than" is
tested, only "different"). The omnibus test comes first because testing
all pairs without it inflates the chance of finding a "significant" pair
by chance alone as the number of pairs grows; the CLD is the compact way
to display the result of all pairwise tests at once.

{dlgtab:Degenerate variance}

{pstd}
When a category of {cmd:over()} has no variability (e.g. a proportion of
exactly 0 or 1), its design-based standard error is undefined. {cmd:svylet}
detects this, reports the omnibus F as not calculable when it affects the
test, and marks the CLD letter for the affected categories as {bf:[?]}
rather than a real letter -- {bf:[?]} should never be read as "no
difference"; it means the comparison could not be computed for that
category.

{dlgtab:Bootstrap prepivoting of the omnibus F-test (boot())}

{pstd}
When {cmd:boot(#)} is specified, the omnibus F p-value is additionally
recalibrated by bootstrap (prepivoting, Beran 1988), useful when the design
degrees of freedom are small enough that the asymptotic F reference may be
imprecise:

{phang2}1. The pool of observations across all {cmd:over()} categories is
resampled with replacement (Rao, Wu & Yue 1992; Beaumont & Patak 2012).{p_end}

{phang2}2. {cmd:over()} labels are reassigned at random across the
resampled pool, in the same proportions as the original group sizes --
this enforces the null hypothesis in the resampling itself (Hall & Wilson
1991, first guideline).{p_end}

{phang2}3. The bootstrapped quantity is the studentized F statistic itself,
recomputed each replicate from its own design-based variance, not a raw
difference (Hall & Wilson 1991, second guideline).{p_end}

{pstd}
{cmd:boot()} recalibrates the omnibus F only; the pairwise Bonferroni
comparisons always use the analytic t({cmd:df}) reference.


{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(F_omnibus)}}Wald F statistic for the omnibus test (missing if not calculable){p_end}
{synopt:{cmd:r(p_omnibus)}}p-value of the omnibus test (analytic){p_end}
{synopt:{cmd:r(p_omnibus_boot)}}p-value of the omnibus test (bootstrap-prepivoted; missing unless {cmd:boot()} specified){p_end}
{synopt:{cmd:r(B_efectivo)}}number of valid bootstrap replicates used{p_end}
{synopt:{cmd:r(df_num)}}numerator degrees of freedom ({cmd:over()} categories minus 1){p_end}
{synopt:{cmd:r(df_den)}}denominator degrees of freedom (Korn-Graubard adjusted){p_end}
{synopt:{cmd:r(k_categorias)}}number of {cmd:over()} categories (k){p_end}
{p2colreset}{...}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(letra_1)}, ..., {cmd:r(letra_k)}}CLD letter group for each category of {cmd:over()}, in the same order as {cmd:levelsof over()}{p_end}
{synopt:{cmd:r(nombre_categoria_1)}, ..., {cmd:r(nombre_categoria_k)}}the value of {cmd:over()} that each {cmd:r(letra_i)} corresponds to{p_end}
{p2colreset}{...}

{pstd}
Illustration of {cmd:return list} after {cmd:svylet mpg, over(rep78)
stat(mean)} on {cmd:sysuse auto} (structure based on the code and on the
F/p/letters already confirmed in Example 1 above; exact scalar precision
and Stata's item ordering were not captured from a live run){p_end}

{p 8 8 2}
{cmd:. return list}{break}
{break}
{cmd:scalars:}{break}
{space 18}{cmd:r(k_categorias) =  5}{break}
{space 22}{cmd:r(df_den) =  64}{break}
{space 22}{cmd:r(df_num) =  4}{break}
{space 20}{cmd:r(B_efectivo) =  .}{break}
{space 12}{cmd:r(p_omnibus_boot) =  .}{break}
{space 19}{cmd:r(p_omnibus) =  .0386...}{break}
{space 19}{cmd:r(F_omnibus) =  2.6941...}{break}
{break}
{cmd:macros:}{break}
{space 8}{cmd:r(nombre_categoria_5) : "5"}{break}
{space 8}{cmd:r(nombre_categoria_4) : "4"}{break}
{space 8}{cmd:r(nombre_categoria_3) : "3"}{break}
{space 8}{cmd:r(nombre_categoria_2) : "2"}{break}
{space 8}{cmd:r(nombre_categoria_1) : "1"}{break}
{space 22}{cmd:r(letra_5) : "a"}{break}
{space 21}{cmd:r(letra_4) : "ab"}{break}
{space 21}{cmd:r(letra_3) : "b"}{break}
{space 21}{cmd:r(letra_2) : "ab"}{break}
{space 21}{cmd:r(letra_1) : "ab"}

{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen id = _n}{p_end}
{phang2}{cmd:. svyset id, strata(foreign) singleunit(certainty)}{p_end}

{pstd}Mean: does mpg differ by number of repair records?{p_end}
{phang2}{cmd:. svylet mpg, over(rep78) stat(mean)}{p_end}

{pstd}Proportion: does the share of foreign cars differ by rep78?{p_end}
{phang2}{cmd:. svylet foreign, over(rep78) stat(proportion)}{p_end}

{pstd}Total: does total vehicle weight differ by rep78?{p_end}
{phang2}{cmd:. svylet weight, over(rep78) stat(total)}{p_end}

{pstd}Mean, with bootstrap-prepivoted omnibus F (requires a clustering
variable with more than one observation per cluster){p_end}
{phang2}{cmd:. sort rep78 mpg}{p_end}
{phang2}{cmd:. gen cluster5 = ceil(_n/5)}{p_end}
{phang2}{cmd:. svyset cluster5, strata(foreign) singleunit(certainty)}{p_end}
{phang2}{cmd:. svylet mpg, over(rep78) stat(mean) boot(300) bseed(12345)}{p_end}

{pstd}Proportion, second reference dataset{p_end}
{phang2}{cmd:. webuse nlsw88, clear}{p_end}
{phang2}{cmd:. gen id2 = _n}{p_end}
{phang2}{cmd:. svyset id2, strata(race) singleunit(certainty)}{p_end}
{phang2}{cmd:. svylet union, over(industry) stat(proportion)}{p_end}


{title:References}

{phang}
Beaumont, J.-F., and Z. Patak. 2012. On the generalized bootstrap for
sample surveys with special attention to Poisson sampling.
{it:International Statistical Review} 80(1): 127-148.

{phang}
Beran, R. 1988. Prepivoting test statistics: a bootstrap view of
asymptotic refinements. {it:Journal of the American Statistical
Association} 83(403): 687-697.

{phang}
Cochran, W.G. 1977. {it:Sampling Techniques}, 3rd ed. New York: Wiley.
(ch. 6, ratio estimation)

{phang}
Hall, P., and S.R. Wilson. 1991. Two guidelines for bootstrap hypothesis
testing. {it:Biometrics} 47(2): 757-762.

{phang}
Korn, E.L., and B.I. Graubard. 1990. Simultaneous testing of regression
coefficients with complex survey data: use of Bonferroni t statistics.
{it:American Statistician} 44(4): 270-276.

{phang}
Piepho, H.P. 2004. An algorithm for a letter-based representation of
all-pairwise comparisons. {it:Journal of Computational and Graphical
Statistics} 13(2): 456-466.

{phang}
Rao, J.N.K., C.F.J. Wu, and K. Yue. 1992. Some recent work on resampling
methods for complex surveys. {it:Survey Methodology} 18(2): 209-217.


{title:Author}

{p 4 4 2}
Andres Talavera Cuya{break}
Instituto Nacional de Estadistica e Informatica (INEI), Peru{break}
Comments and bug reports welcome.

{p 4 4 2}
This software was developed by the author in a personal capacity. It is
not an official product of INEI, and INEI bears no responsibility for it.
The views, methods, and results expressed here are the author's own and
do not necessarily reflect the position of INEI.


{title:ESPANOL}

{pstd}
Resumen en espanol del mismo comando -- ver las secciones en ingles arriba
para el detalle completo y las citas bibliograficas exactas. El orden de
las secciones sigue la misma convencion: Que hace, Opciones, Remarks
(con Beneficios primero), Resultados guardados, Ejemplos.{p_end}

{dlgtab:Que hace}

{pstd}
{cmd:svylet} prueba si una media, proporcion o total difiere entre las
categorias de {cmd:over()} bajo diseno muestral complejo, y reporta el
resultado como un Compact Letter Display: categorias que comparten al
menos una letra NO son significativamente distintas entre si; categorias
sin ninguna letra en comun SI lo son -- la misma convencion de las tablas
ANOVA post-hoc en agronomia (Tukey/Duncan), adaptada aqui a un test de
Wald bajo diseno muestral en vez de ANOVA clasico. Reporta: (1) un F de
Wald omnibus con el ajuste de Korn & Graubard (1990) -- el mismo que usa
Stata por defecto en {cmd:test}/{cmd:testparm} despues de cualquier
{cmd:svy:}; (2) las comparaciones pareadas entre todas las categorias, con
correccion de Bonferroni; (3) el Compact Letter Display resultante.

{dlgtab:Opciones}

{pstd}
Ver la seccion "Options" en ingles arriba -- misma lista, mismos defaults:
{cmd:over()} y {cmd:stat()} son requeridas; {cmd:alpha()}, {cmd:level()},
{cmd:boot()}, y {cmd:bseed()} son opcionales.{p_end}

{dlgtab:Remarks}

{pstd}
Se presentan bajo los siguientes titulos:

{phang2}Beneficios de usar svylet{p_end}

{phang2}Hipotesis de trabajo{p_end}

{phang2}Varianza degenerada{p_end}

{phang2}Bootstrap con prepivoting del F omnibus (boot()){p_end}

{dlgtab:Beneficios de usar svylet}

{phang2}- Un solo comando cubre media, proporcion y total, en vez de tres
implementaciones ad hoc separadas con logica de significancia
potencialmente inconsistente entre si.{p_end}

{phang2}- No depende de que {cmd:margins}/{cmd:testparm} encadenen bien
tras comandos {cmd:svy:} que no sean {cmd:regress} -- se construye directo
desde {cmd:e(b)}/{cmd:e(V)}/{cmd:e(df_r)}, que cualquier comando
{cmd:svy:} devuelve.{p_end}

{phang2}- Usa el ajuste de Korn & Graubard (1990), el mismo default de
Stata para {cmd:test}/{cmd:testparm} tras {cmd:svy:} -- los resultados
coinciden exactamente con el comando oficial, no es una aproximacion.{p_end}

{phang2}- Reporta los resultados como Compact Letter Display: mas facil de
leer de un vistazo que una tabla de hasta k(k-1)/2 p-valores pareados.{p_end}

{phang2}- Detecta y marca explicitamente la varianza degenerada (ej. una
proporcion exactamente 0 o 1) en vez de reportarla en silencio como "sin
diferencia".{p_end}

{phang2}- Prepivoting por bootstrap opcional ({cmd:boot()}) para dominios
con pocos grados de libertad de diseno, donde la referencia F asintotica
puede ser imprecisa.{p_end}

{phang2}- Se generaliza a cualquier variable de agrupacion en
{cmd:over()} -- no esta limitado a comparar anios, aunque sea el uso mas
comun.{p_end}

{dlgtab:Hipotesis de trabajo}

{pstd}
{bf:En svylet, concretamente}

{pstd}
Sean theta_1, ..., theta_k la media/proporcion/total poblacional de las k
categorias de {cmd:over()}, R la matriz de contrastes (k-1) x k que
compara cada categoria contra una de referencia (la que {cmd:svylet} usa
internamente), y r = 0. Cada test de abajo es un test de Wald de
R*theta = r: solo necesita el estimador sin restringir y su varianza,
asi que {cmd:svylet} lo construye directo desde {cmd:e(b)}/{cmd:e(V)},
sin volver a estimar nada bajo la hipotesis nula.

{pstd}
{bf:F omnibus}: H0: theta_1 = theta_2 = ... = theta_k (no hay ninguna
diferencia real entre ellas). H1: {it:no todas} son iguales (generica: no
dice cual categoria difiere ni en que sentido, solo que la igualdad
completa no se sostiene).

{pstd}
{bf:Comparaciones pareadas de Bonferroni}: para cada par (i,j), H0:
theta_i = theta_j (esas dos categorias especificas son iguales); H1:
theta_i distinto de theta_j (bilateral: no se prueba "mayor que" ni
"menor que", solo "distinto"). El omnibus va primero porque probar todos
los pares sin el como filtro infla la probabilidad de encontrar algun par
"significativo" por puro azar a medida que crece la cantidad de pares; el
CLD es la forma compacta de mostrar el resultado de todas las pruebas
pareadas a la vez.

{dlgtab:Varianza degenerada}

{pstd}
Cuando una categoria de {cmd:over()} no tiene variabilidad (ej. una
proporcion exactamente 0 o 1), su error estandar por diseno queda
indefinido. {cmd:svylet} lo detecta, reporta el F omnibus como no
calculable cuando esto lo afecta, y marca la letra CLD de las categorias
afectadas como {bf:[?]} en vez de una letra real -- {bf:[?]} nunca debe
leerse como "sin diferencia"; significa que la comparacion no se pudo
calcular para esa categoria.

{dlgtab:Bootstrap con prepivoting del F omnibus (boot())}

{pstd}
Con {cmd:boot(#)}, el p-valor del F omnibus se recalibra ademas por
bootstrap (prepivoting, Beran 1988), util cuando los grados de libertad de
diseno son chicos y la referencia F asintotica puede ser imprecisa: (1) se
remuestrea con reemplazo el pool de observaciones de todas las categorias
de {cmd:over()} (Rao, Wu & Yue 1992; Beaumont & Patak 2012); (2) las
etiquetas de {cmd:over()} se reasignan al azar entre el pool remuestreado,
en la misma proporcion que los tamanos originales -- esto fuerza la
hipotesis nula en el propio remuestreo (Hall & Wilson 1991, primera
regla); (3) lo que se bootstrapea es el propio estadistico F studentizado,
recalculado en cada replica con su propia varianza, no una diferencia
cruda (Hall & Wilson 1991, segunda regla). {cmd:boot()} recalibra solo el
F omnibus; las comparaciones pareadas de Bonferroni siempre usan la
referencia t({cmd:df}) analitica.

{dlgtab:Resultados guardados}

{pstd}
Ver la seccion "Stored results" en ingles arriba -- mismos nombres de
escalares y macros ({cmd:r(F_omnibus)}, {cmd:r(p_omnibus)},
{cmd:r(letra_1)}...{cmd:r(letra_k)}, etc.), no traducidos (son
literalmente los nombres que hay que usar en Stata), incluida la
ilustracion de {cmd:return list}.{p_end}

{dlgtab:Ejemplos}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen id = _n}{p_end}
{phang2}{cmd:. svyset id, strata(foreign) singleunit(certainty)}{p_end}
{phang2}{cmd:. svylet mpg, over(rep78) stat(mean)}{p_end}
{phang2}{cmd:. svylet foreign, over(rep78) stat(proportion)}{p_end}
{phang2}{cmd:. svylet weight, over(rep78) stat(total)}{p_end}

{pstd}
Ver la seccion "Examples" en ingles arriba para los ejemplos completos,
incluido el bootstrap y el segundo dataset de referencia.

{dlgtab:Nota de responsabilidad}

{pstd}
Este comando fue desarrollado por el autor a titulo personal. No
pertenece al INEI ni cuenta con su respaldo institucional; el INEI no se
responsabiliza por su contenido, uso o resultados. Las opiniones, metodos
y resultados aqui expresados son de exclusiva responsabilidad del autor y
no reflejan necesariamente la posicion del INEI.
