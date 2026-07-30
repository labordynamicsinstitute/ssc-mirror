*! sriinei.ado v1.0.0  Andres Talavera  INEI/DNCE  26jul2026
*! Descarga un modulo de microdatos desde el portal SRIENAHO/SIRTOD de
*! INEI, dado el codigo de encuesta y el numero de modulo -- modo
*! puramente MANUAL, sin catalogo embebido de años/modulos por encuesta.
*! Funciona para CUALQUIER encuesta del portal desde el primer dia, con
*! la misma confiabilidad, porque no promete conocer de antemano los
*! codigos/modulos de ninguna encuesta -- los pasa el usuario, tal cual
*! los ve en la URL del portal.
*!
*! URL: https://proyectos.inei.gob.pe/iinei/srienaho/descarga/{FMT}/{COD}-Modulo{N}.zip
*!
*! Distribuido bajo licencia GPL v3 (https://www.gnu.org/licenses/gpl-3.0.txt)

program define sriinei
    version 14.0

    syntax , CODigo(integer)   ///
             MODulo(integer)   ///
             TIPO(string)      ///
             DEStino(string)   ///
             [ REPLACE         ///
               NOUNzip ]

    local tipo_u = upper("`tipo'")
    if !inlist("`tipo_u'", "SPSS", "STATA", "CSV", "DBF") {
        di as error "tipo() debe ser: spss | stata | csv | dbf"
        exit 198
    }

    local archivo "`codigo'-Modulo`modulo'"
    local url "https://proyectos.inei.gob.pe/iinei/srienaho/descarga/`tipo_u'/`archivo'.zip"

    cap mkdir "`destino'"

    local ya_existe = 0
    if "`replace'" == "" {
        capture confirm file "`destino'/`archivo'.zip"
        if _rc == 0 local ya_existe = 1
        if `ya_existe' == 0 & "`nounzip'" == "" {
            capture confirm file "`destino'/`archivo'.dta"
            if _rc == 0 local ya_existe = 1
        }
    }

    if `ya_existe' {
        di as text "`archivo' (`tipo_u') ya existe en `destino' -- se omite (usar 'replace' para forzar)"
        exit 0
    }

    di as text "Descargando `archivo' (`tipo_u')..."
    di as text "URL: `url'"
    capture copy "`url'" "`destino'/`archivo'.zip", replace
    if _rc != 0 {
        di as error "ERROR descargando `archivo' -- verificar que codigo() y modulo() sean correctos"
        di as error "(confirmar en el portal: https://proyectos.inei.gob.pe/microdatos/)"
        exit _rc
    }

    if "`nounzip'" == "" {
        local pwd_actual "`c(pwd)'"
        quietly cd "`destino'"
        capture unzipfile "`archivo'.zip", replace
        if _rc != 0 {
            di as error "ERROR descomprimiendo `archivo'.zip -- el .zip quedo descargado igual"
        }
        else {
            erase "`archivo'.zip"
            di as text "Listo: `destino'/`archivo'.dta (u otro formato segun tipo())"
        }
        quietly cd "`pwd_actual'"
    }
    else {
        di as text "Listo (sin descomprimir): `destino'/`archivo'.zip"
    }
end
