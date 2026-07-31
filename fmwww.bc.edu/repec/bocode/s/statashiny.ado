*! version 1.5.0  26may2026  Eric A. Booth
*! - output(table) now emits value-label text for labeled numeric variables
*!   (e.g. "Foreign" instead of 1); falls back to the number when unlabeled.
program define statashiny
    version 16
    
    * 1. Backward Compatibility Check
    local first : word 1 of `0'
    if inlist("`first'", "init", "input_num", "input_check", "output_val", "output_table", "output_raw", "data_from_memory", "calc", "build") {
        gettoken subcmd 0 : 0, parse(" ,")
        _statashiny_`subcmd' `0'
        exit
    }

    * 2. Raw HTML / Calc Check (Bypass syntax for complex strings)
    local check : copy local 0
    if ustrpos(`"`macval(check)'"', "output(raw)") > 0 {
        _statashiny_handle_raw `0'
        exit
    }
    if ustrpos(`"`macval(check)'"', "calc(") > 0 {
        _statashiny_handle_calc `0'
        exit
    }

    * 3. Consolidated Syntax
    syntax [anything(name=id)] [, ///
        Input(string) Output(string) Calc(string) Build ///
        Title(string) Subtitle(string) Replace Open ///
        Label(string) Val(string) Min(real -1000) Max(real 1000) Step(real 1) ///
        Vars(varlist) Checked Toggles ///
        Prefix(string) Suffix(string) ///
        EXPort(string) ]

    * Initialization
    if "`title'" != "" | "`replace'" != "" {
        _statashiny_init, title(`"`title'"') subtitle(`"`subtitle'"') `replace'
    }

    * Inputs
    if "`input'" != "" {
        if inlist("`input'", "num", "number") {
            _statashiny_input_num, var("`id'") label("`label'") val("`val'") min(`min') max(`max') step(`step')
        }
        else if inlist("`input'", "check", "checkbox") {
            _statashiny_input_check, var("`id'") label("`label'") `checked'
        }
    }

    * Outputs
    if "`output'" != "" {
        if inlist("`output'", "val", "value") {
            _statashiny_output_val, id("`id'") label("`label'") prefix("`prefix'") suffix("`suffix'")
        }
        else if "`output'" == "table" {
            _statashiny_output_table, id("`id'") label("`label'")
            _statashiny_data_from_memory, id("`id'") vars(`vars')
            if "`toggles'" != "" {
                local i = 0
                foreach v of varlist `vars' {
                    local lab : var label `v'
                    if "`lab'" == "" local lab "`v'"
                    _statashiny_input_check, var("toggle_`id'_`i'") label("Show `lab'") checked
                    _statashiny_calc "if (window.table_`id') table_`id'.column(`i').visible(document.getElementById('toggle_`id'_`i'').checked);"
                    local ++i
                }
            }
        }
    }

    * Build
    if "`build'" != "" {
        _statashiny_build, `open' export(`"`export'"')
    }
    
    * Help fallback
    if "`id'`input'`output'`calc'`build'`title'" == "" {
        help statashiny
    }
end

program define _statashiny_handle_raw
    local js : copy local 0
    local start = ustrpos(`"`macval(js)'"', "label(") + 6
    local rest = usubstr(`"`macval(js)'"', `start', .)
    local end = ustrrpos(`"`macval(rest)'"', ")")
    local html = usubstr(`"`macval(rest)'"', 1, `end'-1)
    local html = strtrim(`"`macval(html)'"')
    if usubstr(`"`macval(html)'"', 1, 2) == `"`""' & usubstr(`"`macval(html)'"', -2, 2) == `""'"' {
        local html = usubstr(`"`macval(html)'"', 3, ustrlen(`"`macval(html)'"')-4)
    }
    else if usubstr(`"`macval(html)'"', 1, 1) == `"""' & usubstr(`"`macval(html)'"', -1, 1) == `"""' {
        local html = usubstr(`"`macval(html)'"', 2, ustrlen(`"`macval(html)'"')-2)
    }
    _statashiny_output_raw `macval(html)'
end

program define _statashiny_handle_calc
    local js : copy local 0
    local start = ustrpos(`"`macval(js)'"', "calc(") + 5
    local rest = usubstr(`"`macval(js)'"', `start', .)
    local end = ustrrpos(`"`macval(rest)'"', ")")
    local code = usubstr(`"`macval(rest)'"', 1, `end'-1)
    local code = strtrim(`"`macval(code)'"')
    if usubstr(`"`macval(code)'"', 1, 2) == `"`""' & usubstr(`"`macval(code)'"', -2, 2) == `""'"' {
        local code = usubstr(`"`macval(code)'"', 3, ustrlen(`"`macval(code)'"')-4)
    }
    else if usubstr(`"`macval(code)'"', 1, 1) == `"""' & usubstr(`"`macval(code)'"', -1, 1) == `"""' {
        local code = usubstr(`"`macval(code)'"', 2, ustrlen(`"`macval(code)'"')-2)
    }
    _statashiny_calc `macval(code)'
end

program define _statashiny_init
    syntax [, Title(string) Subtitle(string) Replace]
    if "`title'" == "" local title "StataShiny Dashboard"
    global S_title `"`title'"'
    global S_subtitle `"`subtitle'"'
    global S_inputs ""
    global S_outputs ""
    global S_calc_js ""
    global S_table_list ""
    di as txt "StataShiny initialized: `title'"
end

program define _statashiny_input_num
    syntax, Var(string) Label(string) [Val(string) Min(real -1000) Max(real 1000) Step(real 1)]
    if "`val'" == "" local val 0
    local html `"<div class="mb-3">"'
    local html `"`html'<label class="form-label small uppercase fw-bold">`label'</label>"'
    local html `"`html'<input type="number" class="form-control form-control-sm" id="`var'" value="`val'" min="`min'" max="`max'" step="`step'" oninput="updateDashboard()">"'
    local html `"`html'</div>"'
    global S_inputs `"$S_inputs `html'"'
end

program define _statashiny_input_check
    syntax, Var(string) Label(string) [Checked]
    local chk = cond("`checked'"!="", "checked", "")
    local html `"<div class="form-check mb-2">"'
    local html `"`html'<input class="form-check-input" type="checkbox" id="`var'" `chk' onchange="updateDashboard()">"'
    local html `"`html'<label class="form-check-label small">`label'</label>"'
    local html `"`html'</div>"'
    global S_inputs `"$S_inputs `html'"'
end

program define _statashiny_output_val
    syntax, Id(string) Label(string) [Prefix(string) Suffix(string)]
    local html `"<div class="card mb-3 statashiny-component"><div class="card-body">"'
    local html `"`html'<h6 class="card-subtitle mb-2 text-muted uppercase small fw-bold">`label'</h6>"'
    local html `"`html'<div class="card-text h4 text-primary">`prefix'<span id="`id'">---</span>`suffix'</div>"'
    local html `"`html'</div></div>"'
    global S_outputs `"$S_outputs `html'"'
end

program define _statashiny_output_raw
    local html : copy local 0
    global S_outputs `"$S_outputs `macval(html)'"'
end

program define _statashiny_output_table
    syntax, Id(string) Label(string)
    local html `"<div class="card mb-3 statashiny-component"><div class="card-body">"'
    local html `"`html'<h6 class="card-subtitle mb-3 text-muted uppercase small fw-bold">`label'</h6>"'
    local html `"`html'<div class="table-responsive"><table id="`id'" class="table table-hover table-sm stripe row-border" style="width:100%"></table></div>"'
    local html `"`html'</div></div>"'
    global S_outputs `"$S_outputs `html'"'
end

program define _statashiny_data_from_memory
    syntax, Id(string) [Vars(varlist)]
    global S_table_list "$S_table_list `id':`vars'|"
end

program define _statashiny_calc
    local js : copy local 0
    local js = strtrim(`"`macval(js)'"')
    if usubstr(`"`macval(js)'"', 1, 2) == `"`""' & usubstr(`"`macval(js)'"', -2, 2) == `""'"' {
        local js = usubstr(`"`macval(js)'"', 3, ustrlen(`"`macval(js)'"')-4)
    }
    else if usubstr(`"`macval(js)'"', 1, 1) == `"""' & usubstr(`"`macval(js)'"', -1, 1) == `"""' {
        local js = usubstr(`"`macval(js)'"', 2, ustrlen(`"`macval(js)'"')-2)
    }
    global S_calc_js `"$S_calc_js `macval(js)' "'
end

program define _statashiny_build
    syntax [, Open EXPort(string)]

    * Resolve output path:
    *   - No export() → "statashiny_dashboard.html" in current working directory
    *   - export("name.html")          → CWD/name.html (relative)
    *   - export("/abs/path/file.html") → absolute path used verbatim
    *   - export("rel/dir/file.html")   → CWD/rel/dir/file.html
    if `"`export'"' == "" {
        local path `"`c(pwd)'/statashiny_dashboard.html"'
    }
    else {
        local path `"`export'"'
        * Treat as relative if it doesn't start with "/" (Unix) or a drive letter (Windows).
        if substr(`"`path'"', 1, 1) != "/" & substr(`"`path'"', 2, 1) != ":" {
            local path `"`c(pwd)'/`path'"'
        }
    }

    tempname fh
    cap file open `fh' using `"`path'"', write replace
    if _rc {
        di as error `"statashiny build: cannot write to "`path'""'
        di as error `"  (check that the directory exists and is writable)"'
        exit 603
    }
    local title : copy global S_title
    local subtitle : copy global S_subtitle
    local inputs : copy global S_inputs
    local outputs : copy global S_outputs
    local scripts : copy global S_calc_js

    file write `fh' "<!DOCTYPE html><html><head><meta charset='utf-8'><title>`macval(title)'</title>" _n
    file write `fh' "<link href='https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css' rel='stylesheet'>" _n
    file write `fh' "<link rel='stylesheet' type='text/css' href='https://cdn.datatables.net/1.13.4/css/dataTables.bootstrap5.min.css'/>" _n
    file write `fh' "<script src='https://code.jquery.com/jquery-3.6.0.min.js'></script>" _n
    file write `fh' "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>" _n
    file write `fh' "<script type='text/javascript' src='https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js'></script>" _n
    file write `fh' "<script type='text/javascript' src='https://cdn.datatables.net/1.13.4/js/dataTables.bootstrap5.min.js'></script>" _n
    file write `fh' "<style>body{padding:30px;background:#f8f9fa;font-family:sans-serif;}.statashiny-component{border:none;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,0.05);background:white;margin-bottom:1.5rem;}.sidebar{padding:25px;background:#fff;}.form-label{font-weight:700;font-size:0.75rem;color:#666;}.uppercase{text-transform:uppercase;letter-spacing:1px;}</style></head><body>" _n

    file write `fh' "<div class='container-fluid'><div class='row mb-2'><div class='col-12'><h2 class='fw-bold text-dark'>`macval(title)'</h2>" _n
    if `"`macval(subtitle)'"' != "" {
        file write `fh' `"<h5 class='text-muted'>`macval(subtitle)'</h5>"' _n
    }
    file write `fh' "<hr></div></div><div class='row'>" _n
    if trim(`"`macval(inputs)'"') != "" {
        file write `fh' `"<div class='col-md-3'><div class='statashiny-component sidebar shadow-sm'><h6>Parameters</h6><hr> `macval(inputs)' </div></div>"' _n
        file write `fh' `"<div class='col-md-9'> `macval(outputs)' </div></div></div>"' _n
    }
    else {
        file write `fh' `"<div class='col-12'> `macval(outputs)' </div></div></div>"' _n
    }
    file write `fh' "<script>" _n
    local tlist "$S_table_list"
    while "`tlist'" != "" {
        gettoken entry tlist : tlist, parse("|")
        if "`entry'" == "|" continue
        local id = substr("`entry'", 1, strpos("`entry'", ":")-1)
        local vars = substr("`entry'", strpos("`entry'", ":")+1, .)
        if "`vars'" == "" local vars _all
        file write `fh' "var cols_`id' = ["
        foreach v of varlist `vars' {
            local lab : var label `v'
            if "`lab'" == "" local lab "`v'"
            file write `fh' "{ title: '`lab'' },"
        }
        file write `fh' "]; var data_`id' = ["
        forvalues i = 1/`=_N' {
            file write `fh' "["
            foreach v of varlist `vars' {
                capture confirm numeric variable `v'
                if _rc {
                    * string variable: quote in single-quotes for JS
                    local val = `v'[`i']
                    file write `fh' "'`val'', "
                }
                else if missing(`v'[`i']) {
                    * Stata's . (missing) is not valid JS — emit null instead.
                    * Without this, the whole data array fails to parse and DataTables
                    * silently shows an empty table.
                    file write `fh' "null, "
                }
                else {
                    local val = `v'[`i']
                    * Labeled numeric: emit the value-label text (as a JS string)
                    * instead of the bare numeric code, e.g. "Foreign" not 1.
                    * Falls back to the number when the value has no label entry.
                    local vlname : value label `v'
                    if "`vlname'" != "" & `val' == int(`val') {
                        local lbl : label `vlname' `val'
                        local lbl = subinstr(`"`macval(lbl)'"', "\", "\\", .)
                        local lbl = subinstr(`"`macval(lbl)'"', "'", "\'", .)
                        file write `fh' `"'`macval(lbl)'', "'
                    }
                    else {
                        file write `fh' "`val', "
                    }
                }
            }
            file write `fh' "],"
        }
        file write `fh' "]; window.table_`id' = null;" _n
        file write `fh' "$(document).ready(function(){ window.table_`id' = $('#`id'').DataTable({data:data_`id', columns:cols_`id', pageLength:10}); });" _n
    }
    file write `fh' "function updateDashboard(){ try{ " _n
    file write `fh' `"`macval(scripts)'"' _n
    file write `fh' " }catch(e){console.warn('Dashboard update failed:', e);} }" _n
    file write `fh' "$(document).ready(function(){ setTimeout(updateDashboard, 700); });" _n
    file write `fh' "</script></body></html>" _n
    file close `fh'
    di as txt "StataShiny built." _n as smcl `"File: {browse `"`path'"'}"'
    if "`open'" != "" {
        cap file close _ss_fh
        tempfile _ss_sh
        if ("`c(os)'" == "MacOSX") | regexm("`c(machine_type)'", "Mac") {     // Apple-Silicon Stata reports c(os)=="Unix"
            file open _ss_fh using "`_ss_sh'", write text replace
            file write _ss_fh "/usr/bin/open " _char(34) `"`path'"' _char(34) _n
            file close _ss_fh
            shell sh "`_ss_sh'"
        }
        else if "`c(os)'" == "Windows" {
            file open _ss_fh using "`_ss_sh'.cmd", write text replace
            file write _ss_fh "start " _char(34) _char(34) " " _char(34) `"`path'"' _char(34) _n
            file close _ss_fh
            shell "`_ss_sh'.cmd"
        }
        else {
            file open _ss_fh using "`_ss_sh'", write text replace
            file write _ss_fh "xdg-open " _char(34) `"`path'"' _char(34) _n
            file close _ss_fh
            shell sh "`_ss_sh'"
        }
    }
end
