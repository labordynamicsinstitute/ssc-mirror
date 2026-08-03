{smcl}
{* *! version 1.0  21jul2026}{...}
{viewerjumpto "Sintaxis" "atip_volcano##syntax"}{...}
{viewerjumpto "Descripcion" "atip_volcano##description"}{...}
{viewerjumpto "Opciones" "atip_volcano##options"}{...}
{viewerjumpto "Ejemplos" "atip_volcano##examples"}{...}
{viewerjumpto "Autor" "atip_volcano##author"}{...}
{title:Titulo}

{phang}
{bf:atip_volcano} {hline 2} Grafico de atipicos: magnitud (X) vs. evidencia (Y)


{marker syntax}{...}
{title:Sintaxis}

{p 8 17 2}
{cmd:atip_volcano} {varname}{cmd:,}
{cmdab:nreglas:(}{varname}{cmd:)}
[{it:opciones}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Requerida}
{synopt:{cmdab:nreglas:(}{varname}{cmd:)}}variable con el conteo de reglas disparadas (0-5), tipicamente {cmd:N_REGLAS} de {help atip_score}{p_end}

{syntab:Opcionales}
{synopt:{cmdab:id:(}{varname}{cmd:)}}variable para etiquetar los puntos prioritarios en el grafico{p_end}
{synopt:{cmdab:nthresh:(}{it:#}{cmd:)}}umbral de evidencia (N_REGLAS) para considerar "prioritario"; por defecto {cmd:nthresh(3)}{p_end}
{synopt:{cmdab:magthresh:(}{it:#}{cmd:)}}umbral de magnitud (|z|) para considerar "prioritario"; por defecto {cmd:magthresh(2)}{p_end}
{synopt:{cmdab:title:(}{it:string}{cmd:)}}titulo del grafico{p_end}
{synopt:{cmdab:seed:(}{it:#}{cmd:)}}semilla para el jitter vertical; por defecto {cmd:seed(12345)}{p_end}
{synopt:{cmdab:saving:(}{it:filename}{cmd:)}}guarda el grafico con {cmd:graph save}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Descripcion}

{pstd}
{cmd:atip_volcano} dibuja un grafico de dispersion con la {bf:magnitud
local} ({varname}, tipicamente {cmd:MAGNITUD_LOCAL} de
{help atip_score}) en el eje X y la {bf:evidencia}
({cmd:nreglas()}, el conteo de 0 a 5 reglas disparadas) en el eje Y.
Los casos con evidencia fuerte ({cmd:nreglas()>=nthresh}) Y magnitud
grande ({varname}{cmd:>=magthresh}) se marcan en rojo, con etiqueta
si se especifica {cmd:id()}.

{pstd}
Sigue el mismo lenguaje visual que {cmd:mmd_volcano} (magnitud en X,
evidencia en Y, cuadrante prioritario resaltado) para mantener
consistencia entre los reportes de deteccion de outliers y los de
comparacion de distribuciones (MMD). La diferencia clave: aqui el
eje Y {bf:no} es -log10(p) -- es un conteo discreto real (0-5),
porque las reglas heuristicas de {help atip_reglas} no tienen un
p-valor formal. Por eso se aplica un jitter aleatorio vertical
(±0.25) solo para que los puntos con el mismo conteo no queden
exactamente superpuestos en una linea horizontal; el dato de fondo
sigue siendo discreto.


{marker options}{...}
{title:Opciones}

{phang}
{cmdab:nreglas:(}{varname}{cmd:)} {it:(requerida)} variable numerica
con el conteo de reglas disparadas, valores esperados 0-5.

{phang}
{cmdab:id:(}{varname}{cmd:)} variable (numerica o string) usada para
etiquetar los puntos marcados como prioritarios. Sin esta opcion, los
puntos prioritarios se muestran sin texto.

{phang}
{cmdab:nthresh:(}{it:#}{cmd:)} umbral minimo de {cmd:nreglas()} para
que un caso se considere de evidencia fuerte. Por defecto 3 (de 5).

{phang}
{cmdab:magthresh:(}{it:#}{cmd:)} umbral minimo de magnitud local para
que un caso se considere grande. Por defecto 2 (equivalente a
|z|>=2).


{marker examples}{...}
{title:Ejemplos}

{pstd}Con auto.dta (requiere haber corrido atip_score antes){p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. atip_score price, group(foreign)}{p_end}
{phang2}{cmd:. atip_volcano MAGNITUD_LOCAL, nreglas(N_REGLAS) nthresh(3) magthresh(2) id(make) ///}{p_end}
{phang2}{cmd:      title("Volcano de atipicos - price por foreign")}{p_end}

{pstd}Con nlsw88.dta -- confirmado con datos reales (n=1878): 67 casos prioritarios, patron esperado con la mayoria de puntos rojos en la esquina superior derecha{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}
{phang2}{cmd:. drop if missing(wage, union)}{p_end}
{phang2}{cmd:. atip_score wage, group(union)}{p_end}
{phang2}{cmd:. atip_volcano MAGNITUD_LOCAL, nreglas(N_REGLAS) nthresh(3) magthresh(2) id(idcode) ///}{p_end}
{phang2}{cmd:      title("Volcano de atipicos - wage por union")}{p_end}


{marker author}{...}
{title:Autor / notas de desarrollo}

{pstd}
Andres Talavera Cuya{break}
Direccion Nacional de Censos y Encuestas -- INEI Peru{break}
Email: atalaveracuya@gmail.com

{pstd}
Comandos relacionados: {help atip_reglas} y {help atip_score} (insumo directo
de este comando) -- instalar los tres juntos. Ver
tambien {cmd:mmd_volcano} para el equivalente aplicado al test MMD.

{hline}
{title:Licencia}

{pstd}
Este modulo se distribuye bajo los terminos de la GPL v3
({browse "https://www.gnu.org/licenses/gpl-3.0.txt":https://www.gnu.org/licenses/gpl-3.0.txt}).
