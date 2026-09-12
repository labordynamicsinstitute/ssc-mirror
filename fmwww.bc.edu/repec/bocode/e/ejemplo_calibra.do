/*==============================================================
  ejemplo_calibra.do
  Ejemplo reproducible de uso de `calibra`, con datos simulados
  que imitan una muestra ENAHO: calibracion a totales por
  area (urbano/rural) y grupo de edad.

  Requiere: calibra.ado / calibra.sthlp en el adopath

  IMPORTANTE sobre este ejemplo:
  Los totales "objetivo" se calculan a partir de los propios
  totales estimados con el peso de diseno (no son numeros
  inventados sueltos), aplicando un ajuste modesto (+8% en la
  poblacion total, con una redistribucion ligera entre area y
  grupos de edad), tal como ocurriria al actualizar una muestra
  a una nueva proyeccion de poblacion. Esto garantiza que el
  ejercicio sea internamente consistente y que los limites de
  bounds() en el metodo logit sean alcanzables.
==============================================================*/

clear all
set more off
set seed 20260910

* --------------------------------------------------------------
* 1. Simular una "muestra ENAHO" de 4000 hogares/personas
* --------------------------------------------------------------
quietly {
    set obs 4000

    * Dominio geografico simulado: 70% urbano, 30% rural
    generate byte area_urbana = runiform() < 0.70
    generate byte urbano = area_urbana
    generate byte rural  = 1 - area_urbana

    * Grupo de edad (3 categorias), con distribucion algo distinta
    * entre urbano y rural, como ocurre en la realidad
    generate double u_edad = runiform()
    generate byte grupo_edad = 1
    replace  grupo_edad = 2 if u_edad > 0.28
    replace  grupo_edad = 3 if u_edad > 0.28 + 0.58
    drop u_edad

    generate byte edad_0_14   = (grupo_edad==1)
    generate byte edad_15_64  = (grupo_edad==2)
    generate byte edad_65mas  = (grupo_edad==3)

    * Peso de diseno inicial (factor de expansion), con algo de
    * variabilidad por conglomerado/estrato simulado
    generate double factor07 = 380 + 60*rnormal()
    replace factor07 = 150 if factor07 < 150
}

label define area 0 "Rural" 1 "Urbano"
label values area_urbana area

tabulate area_urbana grupo_edad, cell

* --------------------------------------------------------------
* 2. Totales poblacionales "objetivo", construidos a partir de
*    los totales estimados por diseno (consistente con la escala
*    real de la muestra), con un ajuste ilustrativo de +8% en la
*    poblacion total y una redistribucion leve de proporciones
* --------------------------------------------------------------
quietly total urbano rural edad_0_14 edad_15_64 edad_65mas [pweight=factor07]
matrix b = e(b)

display as text "Totales estimados con el peso de diseno original:"
matrix list b

local N_hat    = b[1,1] + b[1,2]
local N_target = `N_hat' * 1.08

* Reparto por area: proporciones objetivo (pueden diferir algo de
* la muestra, p.ej. porque la nueva proyeccion actualiza la
* distribucion urbano/rural)
local T_urbano = `N_target' * 0.74
local T_rural  = `N_target' * 0.26

* Reparto por edad: proporciones objetivo (deben sumar 1, para
* que sea consistente con el mismo total poblacional N_target)
local T_edad1 = `N_target' * 0.27
local T_edad2 = `N_target' * 0.58
local T_edad3 = `N_target' * 0.15

display as text _newline "Poblacion total (diseno):     " as result %12.0f `N_hat'
display as text "Poblacion total (objetivo):   " as result %12.0f `N_target'
display as text "Totales objetivo por variable:"
display as text "  urbano     = " as result %12.0f `T_urbano'
display as text "  rural      = " as result %12.0f `T_rural'
display as text "  edad_0_14  = " as result %12.0f `T_edad1'
display as text "  edad_15_64 = " as result %12.0f `T_edad2'
display as text "  edad_65mas = " as result %12.0f `T_edad3'

* --------------------------------------------------------------
* 3. Calibracion - metodo lineal (GREG clasico)
* --------------------------------------------------------------
calibra urbano rural edad_0_14 edad_15_64 edad_65mas ///
    [pweight=factor07], ///
    generate(factor_lineal) ///
    totals(`T_urbano' `T_rural' `T_edad1' `T_edad2' `T_edad3') ///
    method(linear)

return list

* --------------------------------------------------------------
* 4. Calibracion - raking (razon exponencial, pesos siempre > 0)
* --------------------------------------------------------------
calibra urbano rural edad_0_14 edad_15_64 edad_65mas ///
    [pweight=factor07], ///
    generate(factor_raking) ///
    totals(`T_urbano' `T_rural' `T_edad1' `T_edad2' `T_edad3') ///
    method(raking) nograph

* --------------------------------------------------------------
* 5. Calibracion - logistico acotado: g en [0.5 , 2]
*    (recomendado para produccion de factores definitivos; con
*    un ajuste de +8% en la poblacion, un rango [0.5,2] es mas
*    que suficiente y el algoritmo deberia converger rapido)
* --------------------------------------------------------------
calibra urbano rural edad_0_14 edad_15_64 edad_65mas ///
    [pweight=factor07], ///
    generate(factor_logit) ///
    totals(`T_urbano' `T_rural' `T_edad1' `T_edad2' `T_edad3') ///
    method(logit) bounds(0.5 2) tolerance(1e-8) iterate(50) nograph

* --------------------------------------------------------------
* 6. Comparacion rapida de los tres factores resultantes
* --------------------------------------------------------------
generate g_lineal = factor_lineal/factor07
generate g_raking = factor_raking/factor07
generate g_logit  = factor_logit/factor07

summarize g_lineal g_raking g_logit, detail

* --------------------------------------------------------------
* 7. Verificacion final: los totales calibrados deben cuadrar
*    (exactamente con linear/raking; con logit deben quedar muy
*    cerca, dado que el ajuste requerido cabe dentro de bounds())
* --------------------------------------------------------------
quietly total urbano rural edad_0_14 edad_15_64 edad_65mas [pweight=factor_logit]
matrix list e(b)
