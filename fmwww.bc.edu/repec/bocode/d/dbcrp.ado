*! version 8.0 dbcrp - Creado por Anthony Facundo Huaynate Onofre
capture program drop dbcrp
program define dbcrp
    version 15
    syntax anything(name=args) [, Names(string)]
    
    local n_words : word count `args'
    
    * INTELIGENCIA: Identificar fechas al final de forma segura
    local num_fechas = 0
    if `n_words' >= 1 {
        local fin_test : word `n_words' of `args'
        if regexm("`fin_test'", "^[0-9]") {
            local num_fechas = 1
            if `n_words' >= 2 {
                local ini_test : word `= `n_words' - 1' of `args'
                if regexm("`ini_test'", "^[0-9]") {
                    local num_fechas = 2
                }
            }
        }
    }
    
    * Asignar inicio y fin (Ajuste a documentacion oficial del BCRP)
    if `num_fechas' == 2 {
        local p_fin = `n_words'
        local p_ini = `n_words' - 1
        local p_series = `n_words' - 2
        local fin : word `p_fin' of `args'
        local ini : word `p_ini' of `args'
    }
    else if `num_fechas' == 1 {
        local p_ini = `n_words'
        local p_series = `n_words' - 1
        local ini : word `p_ini' of `args'
        local fin ""
    }
    else {
        local p_series = `n_words'
        local ini ""
        local fin ""
    }
    
    if `p_series' <= 0 {
        display as error "Error: Debes ingresar al menos el codigo de una serie."
        exit 198
    }
    
    local listaseries ""
    forval i = 1/`p_series' {
        local s : word `i' of `args'
        local listaseries "`listaseries' `s'"
    }
    
    if "`names'" != "" {
        local n_names : word count `names'
        if `n_names' != `p_series' {
            display as error "Error: Indicaste `p_series' serie(s) pero diste `n_names' nombre(s) en names()."
            exit 198
        }
    }
    
    tempfile temp_raw temp_clean temp_serie base_consolidada
    local contador = 1
    local freq_base = 0
    
    foreach serie in `listaseries' {
        
        * INTELIGENCIA DE URL
        local len = length("`serie'")
        local char_freq = upper(substr("`serie'", `len', 1))
        
        if "`ini'" != "" & "`fin'" != "" {
            local url_ini "`ini'"
            local url_fin "`fin'"
            if regexm("`url_ini'", "^[0-9][0-9][0-9][0-9]$") {
                if "`char_freq'" == "M" | "`char_freq'" == "Q" {
                    local url_ini "`url_ini'-1"
                }
            }
            if regexm("`url_fin'", "^[0-9][0-9][0-9][0-9]$") {
                if "`char_freq'" == "M" {
                    local url_fin "`url_fin'-12"
                }
                else if "`char_freq'" == "Q" {
                    local url_fin "`url_fin'-4"
                }
            }
            local url "https://estadisticas.bcrp.gob.pe/estadisticas/series/api/`serie'/csv/`url_ini'/`url_fin'"
        }
        else if "`ini'" != "" & "`fin'" == "" {
            local url_ini "`ini'"
            if regexm("`url_ini'", "^[0-9][0-9][0-9][0-9]$") {
                if "`char_freq'" == "M" | "`char_freq'" == "Q" {
                    local url_ini "`url_ini'-1"
                }
            }
            local url "https://estadisticas.bcrp.gob.pe/estadisticas/series/api/`serie'/csv/`url_ini'"
        }
        else {
            local url "https://estadisticas.bcrp.gob.pe/estadisticas/series/api/`serie'/csv"
        }
        
        * =========================================================
        * MOTOR UNIVERSAL ANTIBLOQUEO (cURL / PowerShell / copy)
        * =========================================================
        capture erase "`temp_raw'"
        local descargado = 0
        local os_temp = subinstr("`temp_raw'", "\", "/", .) 
        
        * 1. Motor Primario: cURL (Nativo en Mac, Linux y Win10+)
        if `descargado' == 0 {
            capture quietly shell curl -s -k -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" "`url'" -o "`os_temp'"
            capture confirm file "`temp_raw'"
            if _rc == 0 {
                local descargado = 1
            }
        }
        
        * 2. Motor Secundario: PowerShell (Para Windows si cURL falla)
        if `descargado' == 0 & "`c(os)'" == "Windows" {
            capture quietly shell powershell -Command "$client = new-object System.Net.WebClient; $client.Headers.Add('User-Agent','Mozilla/5.0 (Windows NT 10.0; Win64; x64)'); $client.DownloadFile('`url'', '`os_temp'');"
            capture confirm file "`temp_raw'"
            if _rc == 0 {
                local descargado = 1
            }
        }
        
        * 3. Motor Terciario: Stata Copy (Fallback final)
        if `descargado' == 0 {
            capture copy "`url'" "`temp_raw'", replace
            capture confirm file "`temp_raw'"
            if _rc == 0 {
                local descargado = 1
            }
        }
        
        * Control final de conexión
        if `descargado' == 0 {
            display as error "ERROR BCRP: El Firewall del banco rechazo la peticion de la serie `serie'."
            display as text "-> URL bloqueada: `url'"
            exit 601
        }
        * =========================================================
        
        capture erase "`temp_clean'"
        filefilter "`temp_raw'" "`temp_clean'", from("<br>") to("\n") replace
        
        capture import delimited "`temp_clean'", clear varnames(nonames)
        
        * Validacion de archivo corrupto por bloqueo
        capture confirm variable v2
        if _rc != 0 {
            display as error "ERROR BCRP: El banco bloqueo la descarga (Error 403) o la serie `serie' no existe."
            exit 111
        }
        
        quietly {
            local titulo_full = v2[1]
            if "`names'" != "" {
                local var_nom : word `contador' of `names'
            }
            else {
                local var_nom "`serie'"
            }
            rename v1 periodo
            rename v2 `var_nom'
            
            note `var_nom': Nombre original BCRP: `titulo_full'
            drop in 1 
            destring `var_nom', replace force
            
            gen str_lower = lower(periodo)
            gen byte freq = 1 
            replace freq = 4 if regexm(str_lower, "t[1-4]")
            replace freq = 12 if regexm(str_lower, "(ene|feb|mar|abr|may|jun|jul|ago|sep|set|oct|nov|dic)")
            
            if `contador' == 1 {
                local freq_base = freq[1]
            }
            else {
                if freq[1] != `freq_base' {
                    display as error "ERROR: Estas intentando mezclar series de distinta frecuencia."
                    exit 198
                }
            }
            
            if freq[1] == 1 {
                gen fecha = real(periodo)
                format fecha %tg
            }
            if freq[1] == 4 {
                gen trim = real(regexs(1)) if regexm(str_lower, "t([1-4])")
                gen anio = real(regexs(1)) if regexm(str_lower, "([0-9]+)$")
                replace anio = anio + 1900 if anio > 50 & anio < 100
                replace anio = anio + 2000 if anio <= 50
                gen fecha = yq(anio, trim)
                format fecha %tq
                drop trim anio
            }
            if freq[1] == 12 {
                gen mes = .
                replace mes = 1 if regexm(str_lower, "ene")
                replace mes = 2 if regexm(str_lower, "feb")
                replace mes = 3 if regexm(str_lower, "mar")
                replace mes = 4 if regexm(str_lower, "abr")
                replace mes = 5 if regexm(str_lower, "may")
                replace mes = 6 if regexm(str_lower, "jun")
                replace mes = 7 if regexm(str_lower, "jul")
                replace mes = 8 if regexm(str_lower, "ago")
                replace mes = 9 if regexm(str_lower, "sep|set")
                replace mes = 10 if regexm(str_lower, "oct")
                replace mes = 11 if regexm(str_lower, "nov")
                replace mes = 12 if regexm(str_lower, "dic")
                
                gen anio = real(regexs(1)) if regexm(str_lower, "([0-9]+)$")
                replace anio = anio + 1900 if anio > 50 & anio < 100
                replace anio = anio + 2000 if anio <= 50
                gen fecha = ym(anio, mes)
                format fecha %tm
                drop mes anio
            }
            
            drop str_lower freq periodo
            
            if `contador' == 1 {
                save "`base_consolidada'", replace
            }
            else {
                save "`temp_serie'", replace
                use "`base_consolidada'", clear
                merge 1:1 fecha using "`temp_serie'", nogenerate
                save "`base_consolidada'", replace
            }
            local contador = `contador' + 1
        }
    }
    
    quietly {
        use "`base_consolidada'", clear
        tsset fecha
        order fecha
    }
    display as result "Proceso terminado."
    display as text "Para citar este comando: Huaynate Onofre, A. (2026). dbcrp: Stata module to download BCRP data."
end