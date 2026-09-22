{smcl}
{* *! version 8.0 20sep2026 Anthony Facundo Huaynate Onofre}{...}
{viewerjumpto "Syntax" "dbcrp##syntax"}{...}
{viewerjumpto "Description" "dbcrp##description"}{...}
{viewerjumpto "Options" "dbcrp##options"}{...}
{viewerjumpto "Remarks" "dbcrp##remarks"}{...}
{viewerjumpto "Examples" "dbcrp##examples"}{...}
{viewerjumpto "Author" "dbcrp##author"}{...}
{title:Title}

{p2colset 5 14 16 2}{...}
{p2col:{cmd:dbcrp} {hline 2}}Data directa del BCRP para Stata{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:dbcrp} {it:codigo(s)} [{it:inicio} {it:fin}] [{cmd:,} {opt n:ames(string)}]


{marker description}{...}
{title:Descripción}

{p 4 4 2}
{cmd:dbcrp} es un comando nativo para Stata que permite descargar, limpiar y estructurar series de tiempo macroeconómicas directamente desde el API del Banco Central de Reserva del Perú (BCRP). 

{p 4 4 2}
El comando detecta automáticamente si la serie es anual, trimestral o mensual, se encarga de los formatos de fecha del BCRP y junta varias series en una sola base lista para usar en Stata. Esta versión incluye un motor de red universal para evadir bloqueos institucionales de Firewall.

{p 4 4 2}
{bf:Importante:} No se recomienda mezclar distintas frecuencias (mensual con anual) en una misma ejecución.


{marker options}{...}
{title:Opciones}

{p 4 8 2}
{opt names(string)} permite renombrar las variables al instante. Debe contener exactamente la misma cantidad de palabras que series solicitadas.


{marker remarks}{...}
{title:Notas sobre el uso}

{p 4 4 2}
{bf:Rango de fechas (INICIO FIN):} Si no se especifican años, el comando enviará una solicitud limpia y el API del BCRP devolverá la historia reciente por defecto. Si deseas delimitar un periodo, debes especificar estrictamente ambos años (inicio y fin).

{p 4 4 2}
{bf:Formato de fecha inteligente:} Puedes ingresar simplemente los años (ej. {cmd:2015 2024}) y {cmd:dbcrp} autocompletará los meses o trimestres exactos para evitar errores en el servidor del banco. Si necesitas cortes específicos, el número después del guion depende de la frecuencia: para datos {bf:mensuales} va de 1 a 12 (ej. {cmd:2015-1} = enero), y para {bf:trimestrales} de 1 a 4 (ej. {cmd:2015-1} = primer trimestre).

{p 4 4 2}
{bf:Notas y Etiquetas:} Para mantener la limpieza en los cuadros de regresión, {cmd:dbcrp} deja las etiquetas (labels) en blanco, pero guarda el título completo original del BCRP de forma segura en las notas de la variable. Para consultarlo, simplemente escribe {help notes} en Stata.


{marker examples}{...}
{title:Ejemplos de uso}

{p 4 4 2}1. Descargar la historia reciente por defecto (Piloto automático){p_end}
{p 8 8 2}{stata dbcrp PN39276BQ PN39279BQ}{p_end}

{p 4 4 2}2. Descargar un rango de años usando autocompletado inteligente{p_end}
{p 8 8 2}{stata dbcrp PN01770AM PN01771AM 2015 2024, names(PBI sec_prima)}{p_end}

{p 4 4 2}3. Descargar especificando los meses/trimestres de corte exactos{p_end}
{p 8 8 2}{stata dbcrp PN01770AM PN01771AM 2015-5 2024-10}{p_end}


{marker author}{...}
{title:Autor}

{p 4 4 2}
Anthony Facundo Huaynate Onofre{break}
{browse "https://github.com/Anthony-maxed/STATA-dbcrp":GitHub del Proyecto}{break}
Licencia: MIT
{p_end}
