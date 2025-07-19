florindjp v1.0

DESCRIPCIÓN

El comando florindjp crea un gráfico en forma de flor para visualizar indicadores, donde cada pétalo representa un indicador y su longitud corresponde a su valor. Toma en consideración que el rango de valores que podría adoptar cada uno de los indicadores debe ser el mismo para el conjunto de indcadores que conforman el gráfico de flor. Los indicadores se agrupan por dimensiones, lo que facilita la comparación visual de su desempeño en diferentes áreas del conocimiento. En el centro del gráfico, se pueden incluir información específica que describa el origen de la información. 

Sintaxis 

florindjp <varname> , dimension(string) indicador(string) [title(string) graph_options(string) text1(string) text2(string) text3(string) text4(string) text5(string) text6(string) note(string) ]

OPCIONES

<varname>:  Especifica el nombre de la variable numérica que contiene los valores de los indicadores.

dimension(string):  Especifica el nombre de la variable de cadena que contiene las dimensiones(secciones) de los indicadores. Usar nombres cortos.

indicador(string):  Especifica el nombre de la variable de cadena que contiene los nombres de los indicadores. Usar nombres cortos.

title(string):  Especifica el título del gráfico.

graph_options(string):  Especifica opciones adicionales para el gráfico, como colores de línea, estilos de marcador, etc.  Se pueden usar cualquier opción válida para el comando twoway.

Las siguientes opciones de texto aparecen en la parte central de la flor. Al ser un espacio reducido es importante colocar información muy puntual que permita describir la información que se presenta. Podrias incluirse el año de cálculo, origen de los datos, nombre del informe, zona geográfica que influye, dependencia que atiende, nombre de la empresa, etc.

text1(string):  Especifica el texto que se mostrará en la posición 1 del gráfico.

text2(string):  Especifica el texto que se mostrará en la posición 2 del gráfico.

text3(string):  Especifica el texto que se mostrará en la posición 3 del gráfico.

text4(string):  Especifica el texto que se mostrará en la posición 4 del gráfico.

text5(string):  Especifica el texto que se mostrará en la posición 5 del gráfico.

text6(string):  Especifica el texto que se mostrará en la posición 6 del gráfico.

note(string):  Especifica el texto de la nota al pie del gráfico. Generalmente se emplea para poner la instancia que genera el informe.


EJEMPLOS

1er ejemplo

clear
sysuse auto
decode foreign, gen(fore)
florindjp price, dimension(fore) indicador(make)  text1("Precios de Automóviles") text2("Comparación entre marcas") text3("Principales Marcas ") text4("Dólares") text5("Reales")  text6("Agosto 2020")

2do ejemplo

clear
sysuse census
decode region, gen(region2)
florindjp divorce, dimension(region2) indicador(state)  text1("Divorcios por Estados") text2("Estados Unidos") text3("Censo de Población 1980") text4("Personas")


3er ejemplo

clear
set obs 70
gen val = runiform(0,.99)
gen dim = mod(_n, 4)
tostring dim, replace
gen ind= "Indicador " + string(_n)
florindjp val, dimension(dim) indicador(ind)  text1("Datos Relevantes") text2("Regiones") text3("Personas") text4("Agosto 2024") title("Datos Relevantes para las Regiones 2024") note("Fuente: Elaboración propia")



INFORMACIÓN ADICIONAL
El comando florindjp genera un gráfico de flor donde cada pétalo representa un indicador. La longitud del pétalo es proporcional al valor del indicador. Los indicadores se agrupan por dimensiones, lo que permite comparar visualmente su desempeño en diferentes contextos.


AUTOR
Jorge Alberto Pérez Cruz
FADYCS-UAT
Tamaulipas, MX
jperezc@docentes.uat.edu.mx

FECHA
23 de enero de 2025
