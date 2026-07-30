{smcl}
{* *! sriinei.sthlp v1.0.0  Andres Talavera  INEI/DNCE  26jul2026}{...}
{hline}
{title:Titulo}

{phang}
{bf:sriinei} {hline 2} Descarga un modulo de microdatos desde el portal
SRIENAHO/SIRTOD del INEI (Peru), dado el codigo de encuesta y el numero
de modulo -- modo manual, funciona para cualquier encuesta del portal.

{hline}
{title:Sintaxis}

{p 8 17 2}
{cmd:sriinei} {cmd:,}
    {opth codigo(#)}
    {opth modulo(#)}
    {opth tipo(string)}
    {opth destino(string)}
    [{opt replace}]
    [{opt nounzip}]

{hline}
{title:Descripcion}

{pstd}
{cmd:sriinei} descarga un modulo especifico de microdatos del portal de
INEI, construyendo la URL segun el patron oficial:

{p 8 8 2}
{it:https://proyectos.inei.gob.pe/iinei/srienaho/descarga/{FMT}/{COD}-Modulo{N}.zip}

{pstd}
{cmd:sriinei} no asume nada sobre que encuesta corresponde a cada
codigo -- se pasa el {opt codigo()} y el {opt modulo()} tal cual
aparecen en la URL de descarga del portal, para {bf:cualquier} encuesta
publicada en SRIENAHO (ENAHO, ENA, ENAPRES, o cualquier otra). Este
diseño deliberadamente simple (sin catalogo de años/modulos embebido)
evita que el comando quede desactualizado si INEI reorganiza o agrega
encuestas -- funciona igual de bien para una encuesta publicada ayer
que para una de hace diez años, sin mantenimiento.

{pstd}
{bf:Como encontrar codigo() y modulo()}: entra al portal de microdatos
({browse "https://proyectos.inei.gob.pe/microdatos/":https://proyectos.inei.gob.pe/microdatos/}),
elegi la encuesta y el año, y anda al link de descarga de cualquier
modulo -- el nombre del archivo tiene la forma {it:{COD}-Modulo{N}.zip}.
Esos dos numeros son los que se pasan a {opt codigo()} y {opt modulo()}.

{hline}
{title:Opciones}

{phang}
{opth codigo(#)} codigo de la encuesta/ronda en el portal SRIENAHO.

{phang}
{opth modulo(#)} numero de modulo dentro de esa encuesta/ronda.

{phang}
{opth tipo(string)} formato de descarga: {cmd:spss} | {cmd:stata} |
{cmd:csv} | {cmd:dbf}. La disponibilidad de formato depende de la
encuesta y el año -- no toda combinacion existe.

{phang}
{opth destino(string)} carpeta donde se guarda el archivo descargado.

{phang}
{opt replace} vuelve a descargar aunque el archivo ya exista en
{opt destino()}.

{phang}
{opt nounzip} deja el archivo comprimido (.zip) sin descomprimir.

{hline}
{title:Ejemplos}

{pstd}Un modulo, formato Stata (codigo/modulo genericos -- reemplazar por los que veas en el portal){p_end}
{phang2}{cmd:. sriinei, codigo(906) modulo(1234) tipo(stata) destino("C:\ENA\raw")}{p_end}

{pstd}Sin descomprimir, para revisar despues{p_end}
{phang2}{cmd:. sriinei, codigo(1036) modulo(1895) tipo(csv) destino("C:\ENA\raw") nounzip}{p_end}

{pstd}Forzando nueva descarga aunque ya exista{p_end}
{phang2}{cmd:. sriinei, codigo(1036) modulo(1895) tipo(stata) destino("C:\ENA\raw") replace}{p_end}

{hline}
{title:Referencia}

{pstd}
Portal de Microdatos INEI:{break}
{browse "https://proyectos.inei.gob.pe/microdatos/":https://proyectos.inei.gob.pe/microdatos/}

{pstd}
Patron URL de descarga directa:{break}
{it:https://proyectos.inei.gob.pe/iinei/srienaho/descarga/{FMT}/{COD}-Modulo{N}.zip}

{hline}
{title:Autor}

{pstd}
Andres Talavera{break}
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
{bf:sriinei} v1.0.0 -- Junio 2026
