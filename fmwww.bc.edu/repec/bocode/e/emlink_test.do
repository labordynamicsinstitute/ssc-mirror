*! emlink_test.do -- prueba autocontenida de emlink
*! Genera dos bases ficticias donde SABEMOS quien es quien, corre emlink
*! y reporta precision / recall / F1 contra la verdad.
*!
*! Uso:
*!   1. Copiar emlink.ado, emlink_engine.mata y emlink.sthlp a la carpeta
*!      personal de ados (ver: display c(sysdir_personal))
*!   2. do emlink_test.do

clear all
set more off
set seed 20260828

capture which emlink
if _rc {
    di as error "emlink no esta instalado. Copie emlink.ado y"
    di as error "emlink_engine.mata a: " c(sysdir_personal)
    exit 111
}

* ==================================================================
* 1. Generar poblacion ficticia
* ==================================================================
local NCOM  = 300      // personas presentes en AMBAS bases (matches reales)
local NSOLO = 100      // personas presentes en una sola base

tempfile base_master base_using

* --- pools de nombres ---
local nombres  "JOSE MARIA LUIS ROSA CARLOS ANA JUAN CARMEN PEDRO ELENA JORGE SILVIA MIGUEL TERESA VICTOR LUCIA RAUL SONIA MARCO NELLY FELIX IRMA OSCAR GLORIA HUGO"
local apellidos "QUISPE MAMANI FLORES GARCIA CONDORI HUAMAN APAZA CHOQUE VILCA CCAPA RAMOS TORRES GODOS VARGAS NINA ZAPANA YANA CALLA PARI LAURA CHAMBI TICONA COILA LARICO CUTIPA"
local nn : word count `nombres'
local na : word count `apellidos'

qui set obs `=`NCOM' + `NSOLO''
gen long persona = _n
gen str20 nom  = ""
gen str20 apat = ""
gen str20 amat = ""
gen str6  ubig = ""

qui forvalues i = 1/`=_N' {
    local a = 1 + int(runiform()*`nn')
    local b = 1 + int(runiform()*`na')
    local c = 1 + int(runiform()*`na')
    local d = 1 + int(runiform()*40)
    replace nom  = "`: word `a' of `nombres''"    in `i'
    replace apat = "`: word `b' of `apellidos''"  in `i'
    replace amat = "`: word `c' of `apellidos''"  in `i'
    replace ubig = string(`d', "%06.0f")          in `i'
}

* ==================================================================
* 2. Base MASTER: personas 1..NCOM (comunes) + NSOLO propias
* ==================================================================
preserve
    gen long id_master = _n
    * verdad: persona <= NCOM esta en ambas bases
    gen byte en_ambas = (persona <= `NCOM')
    qui save `base_master', replace
restore

* ==================================================================
* 3. Base USING: las mismas NCOM personas CON ERRORES + otras NSOLO
* ==================================================================
preserve
    qui keep if persona <= `NCOM'
    gen long id_using = persona          // verdad: id_using == persona

    * --- inyectar errores controlados ---
    * (a) tildes
    qui replace nom = subinstr(nom, "JOSE", "JOSÉ", 1)   if runiform() < .15
    qui replace nom = subinstr(nom, "VICTOR", "VÍCTOR", 1) if runiform() < .15
    * (b) transposicion de dos letras en el apellido paterno
    qui gen byte _tr = runiform() < .15
    qui replace apat = substr(apat,1,1) + substr(apat,3,1) + ///
                       substr(apat,2,1) + substr(apat,4,.) if _tr & length(apat)>3
    qui drop _tr
    * (c) apellido materno faltante
    qui replace amat = "" if runiform() < .20
    * (d) nombre abreviado a inicial
    qui replace nom = substr(nom,1,1) if runiform() < .08
    * (e) ubigeo faltante
    qui replace ubig = "" if runiform() < .10

    * --- agregar NSOLO personas que NO estan en master ---
    local nrows = _N
    qui set obs `=`nrows' + `NSOLO''
    qui forvalues i = `=`nrows'+1'/`=_N' {
        local a = 1 + int(runiform()*`nn')
        local b = 1 + int(runiform()*`na')
        local c = 1 + int(runiform()*`na')
        local d = 1 + int(runiform()*40)
        replace nom  = "`: word `a' of `nombres''"   in `i'
        replace apat = "`: word `b' of `apellidos''" in `i'
        replace amat = "`: word `c' of `apellidos''" in `i'
        replace ubig = string(`d', "%06.0f")         in `i'
        replace id_using = 900000 + `i'              in `i'
    }
    qui keep id_using nom apat amat ubig
    qui save `base_using', replace
restore

* ==================================================================
* 4. NORMALIZACION (obligatoria antes de emlink)
* ==================================================================
foreach f in `base_master' `base_using' {
    qui use `"`f'"', clear
    foreach v of varlist nom apat amat {
        qui replace `v' = upper(`v')
        qui replace `v' = ustrto(ustrnormalize(`v', "nfd"), "ascii", 2)
        qui replace `v' = ustrregexra(`v', "[^A-ZÑ ]", " ")
        qui replace `v' = strtrim(stritrim(`v'))
    }
    * clave de bloqueo: primeras 3 letras de cada apellido
    qui gen str3 pref_pat = substr(apat, 1, 3)
    qui gen str3 pref_mat = substr(amat, 1, 3)
    qui save `"`f'"', replace
}

* ==================================================================
* 5. Correr emlink
* ==================================================================
use `base_master', clear

emlink using `base_using',                                   ///
    idmaster(id_master) idusing(id_using)                    ///
    strvars(nom=nom apat=apat amat=amat)                     ///
    ubigeo(ubig=ubig)                                        ///
    block(pref_pat pref_mat)                                 ///
    swapnames clear

* ==================================================================
* 6. Evaluar contra la verdad
* ==================================================================
* Verdad: el par es correcto si id_master == id_using
*         (por construccion, persona i en master <-> id_using i)
gen byte verdad = (_ml_idmaster == _ml_idusing) & (_ml_idusing < 900000)

qui count if verdad
local n_true_bloque = r(N)

qui count if _ml_status == 2 & _ml_best == 1 & verdad == 1
local tp = r(N)
qui count if _ml_status == 2 & _ml_best == 1 & verdad == 0
local fp = r(N)

local prec = cond(`tp'+`fp' > 0, `tp'/(`tp'+`fp'), 0)
local rec  = `tp' / `NCOM'
local f1   = cond(`prec'+`rec' > 0, 2*`prec'*`rec'/(`prec'+`rec'), 0)

di ""
di as text "{hline 60}"
di as text "RESULTADO DE LA VALIDACION"
di as text "{hline 60}"
di as text "Matches reales existentes:      " as result %8.0f `NCOM'
di as text "Matches capturados por bloqueo: " as result %8.0f `n_true_bloque' ///
   as text "  (recall bloqueo " as result %5.1f 100*`n_true_bloque'/`NCOM' as text "%)"
di as text "Enlaces correctos (TP):         " as result %8.0f `tp'
di as text "Enlaces incorrectos (FP):       " as result %8.0f `fp'
di as text ""
di as text "Precision: " as result %6.3f `prec'
di as text "Recall:    " as result %6.3f `rec'
di as text "F1:        " as result %6.3f `f1'
di as text "{hline 60}"

if `f1' > .85 {
    di as result "OK -- emlink recupera los enlaces esperados."
}
else if `f1' > .60 {
    di as err "PARCIAL -- revisar bloqueo y umbral."
}
else {
    di as err "FALLA -- revisar la especificacion."
}

* Inspeccionar la zona clerical
qui count if _ml_status == 1
if r(N) > 0 {
    di ""
    di as text "Zona clerical (primeros 10 casos):"
    list _ml_idmaster _ml_idusing _ml_post _ml_weight verdad ///
        if _ml_status == 1 in 1/10, noobs
}
