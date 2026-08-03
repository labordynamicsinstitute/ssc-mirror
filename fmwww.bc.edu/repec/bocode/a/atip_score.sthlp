{smcl}
{* *! version 1.0  21jul2026}{...}
{viewerjumpto "Sintaxis" "atip_score##syntax"}{...}
{viewerjumpto "Descripcion" "atip_score##description"}{...}
{viewerjumpto "Opciones" "atip_score##options"}{...}
{viewerjumpto "Resultados almacenados" "atip_score##results"}{...}
{viewerjumpto "Ejemplos" "atip_score##examples"}{...}
{viewerjumpto "Autor" "atip_score##author"}{...}
{title:Titulo}

{phang}
{bf:atip_score} {hline 2} Score de atipicos en dos ejes: evidencia (N reglas) y magnitud (|z|)


{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:atip_score} {varname}{cmd:,}
{cmdab:group:(}{varlist}{cmd:)}
[{it:opciones}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Requerida}
{synopt:{cmdab:group:(}{varlist}{cmd:)}}variable(s) que definen el grupo de referencia{p_end}

{syntab:Opcionales (identicas a {help atip_reglas})}
{synopt:{cmdab:rules:(}{it:string}{cmd:)}}subconjunto de reglas a aplicar{p_end}
{synopt:{cmdab:sdthresh3:(}{it:#}{cmd:)}}umbral SD_MEAN_3{p_end}
{synopt:{cmdab:sdthresh2:(}{it:#}{cmd:)}}umbral SD_MEAN_2{p_end}
{synopt:{cmdab:zthresh:(}{it:#}{cmd:)}}umbral ZSCORE{p_end}
{synopt:{cmd:zsymmetric}}ZSCORE de dos colas{p_end}
{synopt:{cmdab:mahalthresh:(}{it:#}{cmd:)}}umbral MHLBS{p_end}

{syntab:Especificas de atip_score}
{synopt:{cmdab:genscore:(}{it:name}{cmd:)}}nombre de la variable de magnitud; por defecto {cmd:MAGNITUD_LOCAL}{p_end}
{synopt:{cmdab:gennreglas:(}{it:name}{cmd:)}}nombre de la variable de evidencia; por defecto {cmd:N_REGLAS}{p_end}
{synopt:{cmd:classic}}usa media/DE en vez de mediana/MAD (se pasa a {help atip_reglas}). {bf:Por defecto (sin esta opcion) se usa la referencia robusta} -- ver {help atip_reglas##robustness:atip_reglas, seccion Robustez}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:atip_score} generaliza {help atip_reglas} (lo llama
internamente): en vez de colapsar las 5 reglas en un solo flag
binario, calcula {bf:dos ejes continuos por separado}:

{pstd}
{cmd:N_REGLAS} -- cuantas de las 5 reglas dispararon (0 a 5). Es el
eje de "evidencia", analogo al -log10(p) que usa {cmd:mmd_volcano}
para el test MMD, pero sin inventar un p-valor formal que estas
reglas heuristicas no tienen realmente.

{pstd}
{cmd:MAGNITUD_LOCAL} -- |z| = |(x-media)/DE|, el eje de "que tan
lejos" esta el valor, comparable entre variables y grupos distintos.

{pstd}
Mantener estos dos ejes separados (en vez de combinarlos en un solo
score) es deliberado: permite despues distinguir visualmente, con
{help atip_volcano}, un caso "grande pero con poca evidencia" (podria
ser variabilidad real) de un caso "grande y con mucha evidencia"
(prioridad real de revision) -- una distincion que se pierde si se
combinan en un unico numero de entrada.

{pstd}
Diseño basado en Waal, Pannekoek & Scholtus (2011), {it:Handbook of
Statistical Data Editing and Imputation} -- score de edicion
selectiva (score local x score global), adaptado aqui como ejes
visuales en lugar de un producto escalar.


{marker options}{...}
{title:Opciones}

{pstd}
Las opciones de reglas ({cmd:rules()}, {cmd:sdthresh3()},
{cmd:sdthresh2()}, {cmd:zthresh()}, {cmd:zsymmetric},
{cmd:mahalthresh()}) son identicas a {help atip_reglas} y se pasan
directamente a esa llamada interna.

{phang}
{cmdab:genscore:(}{it:name}{cmd:)} nombre de la variable de magnitud
local generada. Por defecto {cmd:MAGNITUD_LOCAL}.

{phang}
{cmdab:gennreglas:(}{it:name}{cmd:)} nombre de la variable de conteo
de reglas generada. Por defecto {cmd:N_REGLAS}.


{marker results}{...}
{title:Resultados almacenados}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Escalares}{p_end}
{synopt:{cmd:r(n_evidencia_fuerte)}}numero de observaciones con {cmd:N_REGLAS>=3}{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Ejemplos}

{pstd}Uso basico sobre auto.dta (price por foreign){p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. atip_score price, group(foreign)}{p_end}
{phang2}{cmd:. tab N_REGLAS}{p_end}
{phang2}{cmd:. list make foreign price MAGNITUD_LOCAL N_REGLAS if N_REGLAS>=3, sep(0)}{p_end}

{pstd}Con nlsw88.dta (wage por union) -- confirmado con datos reales, n=1878: 67 casos (3.6%) con N_REGLAS>=3 y |z|>=2{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. drop if missing(wage, union)}{p_end}
{phang2}{cmd:. atip_score wage, group(union)}{p_end}
{phang2}{cmd:. tab N_REGLAS}{p_end}

{pstd}Encadenado con atip_volcano para visualizar{p_end}
{phang2}{cmd:. atip_volcano MAGNITUD_LOCAL, nreglas(N_REGLAS) nthresh(3) magthresh(2) id(idcode)}{p_end}

{pstd}Con {cmd:classic} -- solo si tiene una razon especifica para no querer la referencia robusta{p_end}
{phang2}{cmd:. atip_score wage, group(union) classic}{p_end}
{phang2}{cmd:. * ver seccion "Robustez ante contaminacion" en help atip_reglas}{p_end}


{marker author}{...}
{title:Autor / notas de desarrollo}

{pstd}
Andres Talavera Cuya{break}
Direccion Nacional de Censos y Encuestas -- INEI Peru{break}
Email: atalaveracuya@gmail.com

{pstd}
Comandos relacionados: {help atip_reglas} (base) y {help atip_volcano}
(visualizacion) -- instalar los tres juntos, {cmd:atip_score} llama a
{cmd:atip_reglas} internamente.

{hline}
{title:Licencia}

{pstd}
Este modulo se distribuye bajo los terminos de la GPL v3
({browse "https://www.gnu.org/licenses/gpl-3.0.txt":https://www.gnu.org/licenses/gpl-3.0.txt}).
