*! version 0.1.37 07sep2026
*! parqit — a grammar of data manipulation for Stata, backed by Parquet (embedded DuckDB engine)
*! Authors: Miguel Portela (Universidade do Minho & NIPE), Rute Costa, Paulo Guimarães and Marta Silva (BPLIM / Banco de Portugal)
*! License: MIT (see LICENSE in the parqit repository)

program define parqit, rclass
    version 16.0
    gettoken todo 0 : 0, parse(" ,")
    if (`"`todo'"' == "generate") local todo "gen"
    if `"`todo'"' == "" {
        di as err "parqit: subcommand required; see {help parqit}"
        exit 198
    }

    local cmds version selftest use save describe glimpse open close       ///
        keep drop gen egen replace rename order sort gsort collapse        ///
        contract duplicates sample collect count head list show explain    ///
        set merge append joinby reshape pivot sql query summarize tabulate ///
        path view views misstable levelsof ds lookfor codebook distinct    ///
        tabstat correlate pwcorr histogram mergein appendin menu _dlgvars  ///
        _dlgcontext _dlgsource
    local k : list posof `"`todo'"' in cmds
    if (`k' == 0) {
        di as err `"parqit: unknown subcommand `"`todo'"'"'
        exit 198
    }
    _parqit_`todo' `0'
    return add
end

* ----------------------------------------------------------------------------
* plugin management
* ----------------------------------------------------------------------------

program define _parqit_ensure_plugin
    version 16.0
    capture plugin call parqit_plugin, ping 03
    if (_rc == 0) {
        _parqit_check_numeric_contract "`parqit_numeric_contract'"
        exit
    }

    local pp
    if `"$PARQIT_PLUGIN_PATH"' != "" {
        capture confirm file `"$PARQIT_PLUGIN_PATH"'
        if (_rc) {
            di as err `"parqit: \$PARQIT_PLUGIN_PATH is set but no file exists at `"$PARQIT_PLUGIN_PATH"'"'
            exit 601
        }
        local pp `"$PARQIT_PLUGIN_PATH"'
    }
    else {
        capture findfile parqit.plugin
        if (_rc) {
            di as err "parqit: could not find {bf:parqit.plugin} along the adopath"
            di as err "install the platform binary for your OS, or point the global {bf:PARQIT_PLUGIN_PATH} at a locally built plugin"
            exit 601
        }
        local pp `"`r(fn)'"'
        * Stata hands this path raw to dlopen, which does not expand ~ —
        * sysdir-based results like ~/ado/plus/p/parqit.plugin must be expanded
        if (substr(`"`pp'"', 1, 2) == "~/") {
            local home : env HOME
            if (`"`home'"' != "") {
                local pp `"`home'`=substr(`"`pp'"', 2, .)'"'
            }
        }
    }

    capture program parqit_plugin, plugin using(`"`pp'"')
    if (_rc != 0 & _rc != 110) {
        di as err `"parqit: failed to load the compiled plugin from `"`pp'"' (rc = `=_rc')"'
        di as err "the binary may be for a different platform; see BUILDING.md to build from source"
        exit 498
    }

    plugin call parqit_plugin, ping 03
    _parqit_check_numeric_contract "`parqit_numeric_contract'"
end

program define _parqit_check_numeric_contract
    version 16.0
    args contract
    if ("`contract'" == "3") exit
    di as err "parqit: ado and plugin numerical revisions do not match"
    di as err "restart Stata after installing the matching files; check PARQIT_PLUGIN_PATH if set"
    exit 198
end

* ----------------------------------------------------------------------------
* version / selftest
* ----------------------------------------------------------------------------

program define _parqit_version, rclass
    version 16.0
    syntax
    _parqit_ensure_plugin
    plugin call parqit_plugin, version
    if ("`parqit_openmp'" != "0" | "`parqit_parallel_backend'" != "duckdb") {
        di as err "parqit: install the matching plugin and restart Stata"
        exit 498
    }
    di as txt "parqit version " as res "`parqit_plugin_version'" ///
        as txt "  (engine: DuckDB " as res "`parqit_duckdb_version'" ///
        as txt ", Stata Plugin Interface " as res "`parqit_spi_version'" ///
        as txt ", parallelism: DuckDB)"
    return local parqit_version `"`parqit_plugin_version'"'
    return local duckdb_version `"`parqit_duckdb_version'"'
    return local parallel_backend "duckdb"
    return scalar openmp = 0
    return scalar openmp_version = real("`parqit_openmp_version'")
    return scalar openmp_max_threads = real("`parqit_openmp_max_threads'")
end

program define _parqit_selftest, rclass
    version 16.0
    syntax
    _parqit_ensure_plugin

    mata: assert(_parqit_hex("") == "")
    mata: assert(_parqit_hex("parqit") == "706172716974")
    mata: assert(_parqit_hex("Olá 🦆") == "4f6cc3a120f09fa686")
    mata: assert(_parqit_unhex("706172716974") == "parqit")
    mata: assert(_parqit_unhex(_parqit_hex(`"pa"th's\bad"')) == `"pa"th's\bad"')

    mata: st_local("echo_in", _parqit_hex("Olá 🦆 / path with 'quotes'"))
    plugin call parqit_plugin, echo `echo_in'
    if `"`parqit_echo'"' != `"`echo_in'"' {
        di as err "parqit selftest: hex codec mismatch between ado and plugin"
        exit 920
    }

    mata: st_local("tdirhex", _parqit_hex(st_global("c(tmpdir)")))
    plugin call parqit_plugin, selftest `tdirhex'
    if `"`parqit_selftest'"' != "ok" {
        di as err "parqit selftest: failed (no result from plugin)"
        exit 920
    }
    di as txt "parqit selftest: " as res "ok" ///
        as txt "  (codecs, engine, Parquet write/read and metadata verified in-process)"
    return local selftest "ok"
    return scalar openmp_threads = real("`parqit_openmp_threads'")
end

program define _parqit_menu
    version 16.0
    syntax
    * idempotent per session: `window menu append` would duplicate the entry
    if ("${PARQIT_MENU_ON}" == "1") {
        di as txt "(parqit is already on the User menu this session)"
        exit
    }
    * One submenu under Stata's User menu, in the order of a session and with
    * the task wording of Stata's own Data/File menus: read; describe and
    * explore; change; combine; materialise; manage. Every "..." item opens a
    * dialog; the last group runs a command directly, as official menus do.
    * Mnemonics (&) are unique within the submenu.
    capture {
        window menu append submenu "stUser" "&parqit"
        window menu append item "&parqit" "&Read data (lazy view or into memory)..." "db parqit_read"
        window menu append item "&parqit" "&Describe and explore data..." "db parqit_explore"
        window menu append item "&parqit" "Summary &statistics, tables, and correlations..." "db parqit_stats"
        window menu append separator "&parqit"
        window menu append item "&parqit" "Keep or drop &observations, or draw a sample..." "db parqit_filter"
        window menu append item "&parqit" "Keep, drop, order, sort, or rename &variables..." "db parqit_vars"
        window menu append item "&parqit" "&Create or change variables..." "db parqit_gen"
        window menu append item "&parqit" "Colla&pse, contract, pivot table, or reshape..." "db parqit_pivot"
        window menu append item "&parqit" "Combine datasets (&merge, append, joinby)..." "db parqit_combine"
        window menu append separator "&parqit"
        window menu append item "&parqit" "Save as Parquet or co&llect into memory..." "db parqit_write"
        window menu append item "&parqit" "Views, SQL, and &engine settings..." "db parqit_views"
        window menu append separator "&parqit"
        window menu append item "&parqit" "Vers&ion" "parqit version"
        window menu append item "&parqit" "Self-&test" "parqit selftest"
        window menu append item "&parqit" "&Help on parqit" "help parqit"
        window menu append item "&parqit" "Technical re&ference" "help parqit_technical"
        window menu refresh
    }
    if (_rc) {
        di as err "parqit menu: menus need GUI Stata — this session appears" ///
            " to be console or batch mode"
        exit 199
    }
    global PARQIT_MENU_ON 1
    di as txt "(parqit added to the {bf:User} menu; add the line " ///
        as res "parqit menu" as txt " to your profile.do to keep it across sessions)"
end

* ----------------------------------------------------------------------------
* source adapters — let parqit read non-Parquet inputs
*   parquet/dir/glob : scanned in place (out-of-core)
*   csv/tsv/txt      : scanned in place via DuckDB read_csv_auto (out-of-core)
*   dta / xls / xlsx : NOT engine-scannable, so the ado imports them into a
*                      throwaway frame (the working dataset is untouched) and
*                      snapshots to a Parquet bridge the engine then scans. Best
*                      for small inputs (a lookup .dta, an .xlsx) — for a large
*                      master prefer `use file.dta` + `parqit open _data`.
* The raw path travels through the global PARQIT_RS_IN to survive spaces/quotes.
* ----------------------------------------------------------------------------

* Dialog support: fill a dialog's LIST member with variable names so the
* dialogs' COMBOBOX pickers can be populated on demand — Stata's own
* use/describe/merge dialogs' "Populate" idiom (use_option_wrk_dlg.ado:
* `.dlgname.listname[i] = ...` + .repopulate; dialog LISTs are class members
* writable from ado). Called from a dialog button program via
*   parqit _dlgvars <dlgname> <listname>                 (the current view)
*   parqit _dlgvars <dlgname> <listname>, data           (Stata memory)
*   parqit _dlgvars <dlgname> <listname> using <source>  (a Parquet footer)
* and must NEVER break the dialog: any failure (no view open, no plugin, a
* non-Parquet source, no such dialog) leaves the list empty, sets the
* dialog's optional DOUBLE property pq_populate_error to 1 (the official
* main_des_error pattern, so the dialog can say so in a stopbox) and exits 0.
* Interactive-only glue — intentionally undocumented in the help.
program define _parqit__dlgvars, rclass
    version 16.0
    syntax [anything] [using/] [, Data Numeric(name)]
    gettoken dlgname anything : anything
    gettoken listname anything : anything
    return local varlist ""
    return scalar k = 0
    if ("`dlgname'" == "" | "`listname'" == "") exit
    capture confirm name `dlgname'
    if (_rc) exit
    capture confirm name `listname'
    if (_rc) exit
    capture .`dlgname'.pq_populate_error.setvalue 0
    capture .`dlgname'.`listname'.Arrdropall
    if ("`numeric'" != "") capture .`dlgname'.`numeric'.Arrdropall
    if (`"`using'"' != "" & "`data'" != "") {
        capture .`dlgname'.pq_populate_error.setvalue 1
        exit
    }
    local vars
    local numvars
    capture {
        if ("`data'" != "") {
            quietly ds
            local vars `"`r(varlist)'"'
            if ("`numeric'" != "") {
                quietly ds, has(type numeric)
                local numvars `"`r(varlist)'"'
            }
        }
        else if (`"`using'"' != "") {
            quietly _parqit_describe `"`using'"'
            local ncols = r(n_cols)
            if (`ncols' > 0) {
                forvalues i = 1/`ncols' {
                    local vars `"`vars' `r(name_`i')'"'
                }
            }
        }
        else {
            _parqit_ensure_plugin
            tempfile resp
            mata: st_local("whathex", _parqit_hex("describe"))
            mata: st_local("resphex", _parqit_hex(st_local("resp")))
            plugin call parqit_plugin, view_info `whathex' `resphex'
            mata: _parqit_collect_names("`resp'", "")
            local vars `"`parqit_dsnames'"'
            if ("`numeric'" != "") {
                mata: _parqit_collect_names("`resp'", "n")
                local numvars `"`parqit_dsnames'"'
            }
        }
    }
    if (_rc) {
        capture .`dlgname'.pq_populate_error.setvalue 1
        exit
    }
    local vars = strtrim(`"`vars'"')
    local nvars : word count `vars'
    return local varlist `"`vars'"'
    return scalar k = `nvars'
    * A later Populate may have fewer variables than the previous source.
    * Clear the class array first so stale tail entries cannot survive.
    local i 1
    foreach v of local vars {
        capture .`dlgname'.`listname'[`i'] = "`v'"
        if (_rc) continue, break
        local ++i
    }
    if ("`numeric'" != "") {
        local i 1
        foreach v of local numvars {
            capture .`dlgname'.`numeric'[`i'] = "`v'"
            if (_rc) continue, break
            local ++i
        }
    }
    * Class writes above may themselves set/clear r(); publish the helper's
    * contract only after all best-effort dialog interaction is complete.
    capture confirm name `dlgname'   /* leave the private helper's _rc at zero */
    return local varlist `"`vars'"'
    return scalar k = `nvars'
    return local numeric `"`numvars'"'
end

* GUI context queries use the view registry, never source rows.
program define _parqit__dlgcontext, rclass
    version 16.0
    syntax namelist(min=1 max=1 name=dlg) [, Data Target REPORT]
    tempname prior
    _return hold `prior'
    local view ""
    local context "Current view: none"
    capture {
        _parqit_ensure_plugin
        plugin call parqit_plugin, view_alive
        mata: st_local("view", _parqit_unhex(st_local("parqit_view_current")))
    }
    if (_rc) local context "Current view: unavailable"
    else if ("`view'" != "") local context "Current view: `view'"
    if ("`target'" != "") local context = "Selected view: " + cond("`view'"=="", "none", "`view'")
    if ("`data'" != "") local context "Source: dataset in Stata memory"
    capture .`dlg'.main.tx_context.setlabel `"`context'"'
    capture .`dlg'.pq_view_live.setvalue `=("`view'"!="")'
    capture .`dlg'.pq_view_name.setvalue "`view'"
    _return restore `prior'
    return add
    if ("`report'" != "") {
        return local view "`view'"
        return local context `"`context'"'
    }
end

* File inspection controls apply only to Parquet sources; no adapter is run.
program define _parqit__dlgsource, rclass
    version 16.0
    syntax namelist(min=1 max=1 name=dlg) [using/] [, REPORT]
    tempname prior
    _return hold `prior'
    local base = substr(`"`using'"', strrpos(`"`using'"', "/")+1, .)
    local ext ""
    if (strpos(`"`base'"', ".")) local ext = lower(substr(`"`base'"', strrpos(`"`base'"', ".")+1, .))
    local footer = (`"`using'"' != "" & !inlist("`ext'", "csv", "tsv", "txt", "tab", "dta", "xls", "xlsx"))
    local legacy = inlist("`ext'", "dta", "xls", "xlsx")
    local usemode 1
    capture local usemode = .`dlg'.main.rb_use.value
    if (!`usemode') {
        local footer 0
        capture local legacy = .`dlg'.main.rb_open.value
    }
    local action = cond(`footer', "enable", "disable")
    capture .`dlg'.main.bu_desc.`action'
    capture .`dlg'.main.bu_pop.`action'
    local action = cond(`legacy', "enable", "disable")
    capture .`dlg'.main.tx_enc.`action'
    capture .`dlg'.main.cb_enc.`action'
    _return restore `prior'
    return add
    if ("`report'" != "") return scalar footer = `footer'
end

* One-line, truthful performance hint shown when parqit spots a faster path for a
* large operation (e.g. a big native mergein DuckDB could join out of core).
* Muted by `global PARQIT_NOTIPS 1`. Researcher-facing text is English.
program define _parqit_tip
    version 16.0
    args msg
    if ("${PARQIT_NOTIPS}" != "") exit
    di as txt `"(tip: `msg' — see {help parqit_technical##perf:performance tips}; "' ///
        as txt `"{bf:global PARQIT_NOTIPS 1} mutes these)"'
end

* Persistent bridges must outlive Stata's tempfile lifecycle while a lazy view
* references them.  The plugin atomically reserves a private directory using
* the real OS PID, an operation counter and a strong nonce; it also keeps the
* ownership token, so only package-created paths can ever be erased here.
program define _parqit_bridge_new, rclass
    version 16.0
    args kind
    _parqit_ensure_plugin
    mata: st_local("_bridge_tmphex", _parqit_hex(st_global("c(tmpdir)")))
    mata: st_local("_bridge_kindhex", _parqit_hex(st_local("kind")))
    capture noisily plugin call parqit_plugin, bridge_new `_bridge_tmphex' `_bridge_kindhex'
    if (_rc) exit _rc
    mata: st_local("bridge", _parqit_unhex(st_local("parqit_bridge")))
    return local bridge `"`bridge'"'
end

program define _parqit_bridge_discard
    version 16.0
    args bridge
    if (`"`bridge'"' == "") exit
    _parqit_ensure_plugin
    mata: st_local("_bridge_hex", _parqit_hex(st_local("bridge")))
    plugin call parqit_plugin, bridge_discard `_bridge_hex'
end

program define _parqit_import_to_bridge, rclass
    version 16.0
    args kind                                /* dta | excel | csv */
    local src `"${PARQIT_RS_IN}"'
    local enc `"${PARQIT_RS_ENC}"'
    _parqit_bridge_new import
    local bridge `"`r(bridge)'"'
    tempname fr
    capture noisily frame create `fr'
    local rc = _rc
    * BRIDGE-QUIET-1: the import and the snapshot are package internals; their
    * chatter ("(3 vars, 6 obs)", "(6 obs, 2 vars written to …/bridge.parquet)")
    * only exposed a temporary path the user never named. `capture noisily {
    * quietly ... }` keeps the FAILURE loud — quietly does not suppress error
    * output, and the plugin's SF_error text and rc still reach the caller,
    * while dropping the success noise.
    * BRIDGE-LOSS-1 (audit 2026-08-22, A5-3/A5-2/A2-8): the bridge is a parqit
    * save of the imported frame, so the save-side conversions apply to it —
    * extended missings .a-.z collapse to ., fractional date/period counts
    * round, legacy 8-bit text is transcoded (encoding() chooses the code page,
    * windows-1252 by default). Those LOSSES stay loud: the save's r() results
    * are read back, printed as notes naming the bridged file, and returned.
    local b_ext ""
    local b_frac ""
    local b_tvars ""
    local b_tcells 0
    local b_tmeta 0
    local b_enc ""
    if (!`rc') capture noisily frame `fr' {
        quietly {
            if ("`kind'" == "dta")        use `"`src'"', clear
            else if ("`kind'" == "excel") import excel `"`src'"', firstrow clear
            else                          import delimited `"`src'"', clear
            if (c(k) == 0 | _N == 0) {
                * still snapshot an empty schema so downstream errors are about
                * the data, not a missing file
            }
            parqit save `"`bridge'"', replace data encoding(`"`enc'"')
            local b_ext `"`r(ext_missing)'"'
            local b_frac `"`r(frac_dates)'"'
            local b_tvars `"`r(transcoded_vars)'"'
            local b_tcells = cond(r(transcoded_cells) < ., r(transcoded_cells), 0)
            local b_tmeta = cond(r(transcoded_meta) < ., r(transcoded_meta), 0)
            local b_enc `"`r(encoding)'"'
        }
    }
    if (!`rc') local rc = _rc
    capture frame drop `fr'
    local drop_rc = _rc
    if (!`rc' & `drop_rc') local rc = `drop_rc'
    if (`rc') {
        * The import/save error is authoritative; cleanup is best-effort and
        * must never replace that original return code.
        capture _parqit_bridge_discard `"`bridge'"'
        exit `rc'
    }
    _parqit_lossy_notes, ext(`"`b_ext'"') frac(`"`b_frac'"') transvars(`"`b_tvars'"') ///
        transcells(`b_tcells') transmeta(`b_tmeta') encoding(`"`b_enc'"') ///
        source(`"`src'"')
    return local bridge `"`bridge'"'
    return local ext_missing `"`b_ext'"'
    return local frac_dates `"`b_frac'"'
    return local transcoded_vars `"`b_tvars'"'
    return scalar transcoded_cells = `b_tcells'
    return scalar transcoded_meta = `b_tmeta'
    return local encoding `"`b_enc'"'
end

program define _parqit_resolve_source, rclass
    version 16.0
    args mode                                /* source | using */
    local raw `"${PARQIT_RS_IN}"'
    * extension of the final path component (basename), case-insensitive
    local base = substr(`"`raw'"', strrpos(`"`raw'"', "/") + 1, .)
    local ext ""
    if (strpos("`base'", ".") > 0) ///
        local ext = lower(substr("`base'", strrpos("`base'", ".") + 1, .))
    local fmt "parquet"
    local bridge ""
    local kind ""
    if (inlist("`ext'", "csv", "tsv", "txt", "tab")) {
        if ("`mode'" == "using") local kind "csv"   /* bridge small CSV lookups */
        else local fmt "csv"                        /* big side: scan out-of-core */
    }
    else if ("`ext'" == "dta") local kind "dta"
    else if (inlist("`ext'", "xls", "xlsx")) local kind "excel"
    if ("`kind'" != "") {
        _parqit_import_to_bridge `kind'
        local raw `"`r(bridge)'"'
        local bridge `"`raw'"'
        * BRIDGE-LOSS-1: the bridge's lossy conversions travel up to the caller
        return local ext_missing `"`r(ext_missing)'"'
        return local frac_dates `"`r(frac_dates)'"'
        return local transcoded_vars `"`r(transcoded_vars)'"'
        return scalar transcoded_cells = r(transcoded_cells)
        return scalar transcoded_meta = r(transcoded_meta)
        return local encoding `"`r(encoding)'"'
    }
    return local path `"`raw'"'
    return local fmt "`fmt'"
    return local bridge `"`bridge'"'
end

* BRIDGE-LOSS-1: after _parqit_resolve_source, capture the bridge's loss
* results into the caller's _bl_* locals (c_local) so the public command can
* return them additively once its own work is done.
program define _parqit_bridge_losses
    version 16.0
    syntax [, ext(string) frac(string) tvars(string) tcells(string) tmeta(string) enc(string)]
    c_local _bl_ext `"`ext'"'
    c_local _bl_frac `"`frac'"'
    c_local _bl_tvars `"`tvars'"'
    c_local _bl_tcells = cond("`tcells'" == "" | "`tcells'" == ".", "0", "`tcells'")
    c_local _bl_tmeta = cond("`tmeta'" == "" | "`tmeta'" == ".", "0", "`tmeta'")
    c_local _bl_enc `"`enc'"'
end

* ... and return them (only the ones that carry information, like a save)
program define _parqit_return_losses, rclass
    version 16.0
    syntax [, ext(string) frac(string) tvars(string) tcells(string) tmeta(string) enc(string)]
    if (`"`ext'"' != "") return local ext_missing `"`ext'"'
    if (`"`frac'"' != "") return local frac_dates `"`frac'"'
    if (`"`tvars'"' != "") return local transcoded_vars `"`tvars'"'
    if ("`tcells'" != "" & "`tcells'" != "0") return scalar transcoded_cells = `tcells'
    if ("`tmeta'" != "" & "`tmeta'" != "0") return scalar transcoded_meta = `tmeta'
    if (`"`enc'"' != "" & ("`tcells'" != "0" | "`tmeta'" != "0")) return local encoding `"`enc'"'
end

* ----------------------------------------------------------------------------
* parqit use — lazy view by default; , clear = read into memory now
* ----------------------------------------------------------------------------

program define _parqit_use, rclass
    version 16.0
    * owned is INTERNAL (not in the help): the view takes ownership of the
    * backing file and the plugin erases it on close/replace — only
    * parqit open _data passes it for its per-promotion bridge snapshots.
    capture syntax [anything(name=namelist)] using/ [, clear Name(name) OWNed RELAXed ENCoding(string)]
    if (_rc) {
        capture syntax anything(name=fileraw id="filename") [, clear Name(name) OWNed RELAXed ENCoding(string)]
        if (_rc) {
            * USE-OPT-1 (audit 2026-08-22, A5-13): an unknown option used to
            * surface as "filename required" — name the option instead
            capture syntax [anything] [using/] [, clear Name(name) OWNed RELAXed ENCoding(string) *]
            if (!_rc & `"`options'"' != "") {
                di as err `"parqit use: option `options' not allowed"'
                exit 198
            }
            syntax anything(name=fileraw id="filename") [, clear Name(name) OWNed RELAXed ENCoding(string)]
        }
        local using `fileraw'
        local namelist
    }
    local _sq_relaxed = ("`relaxed'" != "")
    _parqit_ensure_plugin
    if ("`clear'" != "" & "`name'" != "") {
        di as err "parqit use: name() applies to lazy views; omit clear"
        exit 198
    }

    * resolve the input: parquet/csv scan in place; dta/xls/xlsx -> Parquet
    * bridge (the working dataset is left untouched). encoding() is the legacy
    * code page for non-UTF-8 text in a .dta/Excel bridge (BRIDGE-LOSS-1).
    global PARQIT_RS_IN `"`using'"'
    global PARQIT_RS_ENC `"`encoding'"'
    _parqit_resolve_source source
    global PARQIT_RS_ENC
    local using `"`r(path)'"'
    local _sq_fmt "`r(fmt)'"
    local _sq_bridge `"`r(bridge)'"'
    _parqit_bridge_losses, ext(`"`r(ext_missing)'"') frac(`"`r(frac_dates)'"') ///
        tvars(`"`r(transcoded_vars)'"') tcells("`r(transcoded_cells)'") ///
        tmeta("`r(transcoded_meta)'") enc(`"`r(encoding)'"')
    if (`"`encoding'"' != "" & `"`_sq_bridge'"' == "") {
        di as txt "note: encoding() applies to a .dta/Excel source bridged to Parquet; " ///
            "a Parquet/CSV source is read as UTF-8 (ignored)"
    }

    if ("`clear'" == "") {
        * open (or replace) the named lazy view — schema probed, no rows loaded
        if ("`name'" == "") local name "default"
        tempfile req
        local _sq_file `"`using'"'
        local _sq_namelist `"`namelist'"'
        local _sq_vname "`name'"
        * A dta/xls/xlsx bridge, or the reserved open-data path passed through
        * the internal owned option, transfers its plugin-issued token to this
        * view only after view_open succeeds.
        local _sq_owned_file ""
        if (`"`_sq_bridge'"' != "") local _sq_owned_file `"`_sq_bridge'"'
        else if ("`owned'" != "")   local _sq_owned_file `"`using'"'
        mata: _parqit_wr_view_open_request("`req'")
        capture noisily plugin call parqit_plugin, view_open `reqhex'
        local rc = _rc
        if (`rc') {
            capture _parqit_bridge_discard `"`_sq_owned_file'"'
            exit `rc'
        }
        mata: st_local("vname", _parqit_unhex(st_local("parqit_view_name")))
        di as txt "(lazy view " as res "`vname'" as txt " opened over " ///
            as res `"`using'"' as txt ": " as res "`parqit_view_k'" ///
            as txt " columns; schema probed, no rows loaded — use {bf:parqit collect} or {bf:parqit save})"
        _parqit_return_losses, ext(`"`_bl_ext'"') frac(`"`_bl_frac'"') tvars(`"`_bl_tvars'"') ///
            tcells("`_bl_tcells'") tmeta("`_bl_tmeta'") enc(`"`_bl_enc'"')
        return add
        return scalar k = `parqit_view_k'
        return local view "`vname'"
        if (`"`_sq_owned_file'"' != "") return local bridge `"`_sq_owned_file'"'
        exit
    }

    * materialise now; open views are untouched (a plain read is just a read)

    tempfile req resp strl
    local _sq_file `"`using'"'
    local _sq_namelist `"`namelist'"'
    mata: _parqit_wr_use_request("`req'", "`resp'", "`strl'")
    capture noisily plugin call parqit_plugin, use_prepare `reqhex'
    local rc = _rc
    if (`rc') {
        capture _parqit_bridge_discard `"`_sq_bridge'"'
        exit `rc'
    }

    capture noisily _parqit_load_core, resp(`"`resp'"') strl(`"`strl'"') tag("`parqit_tag'") ///
        n(`parqit_n') names("`parqit_names'")
    local rc = _rc
    if (`rc') {
        capture _parqit_bridge_discard `"`_sq_bridge'"'
        exit `rc'
    }

    * COPYSOURCE-1: remember the identity of the file just loaded so an
    * explicit `parqit save ..., copysource` can prove it is copying THAT file
    * (size, mtime, ctime, inode, footer digest — FP-2); the nonce in
    * _dta[_parqit_fast_source_nonce] ties the dataset in memory to it.
    global PARQIT_FAST_SOURCE_NONCE
    global PARQIT_FAST_SOURCE_PATH
    global PARQIT_FAST_SOURCE_SIZE
    global PARQIT_FAST_SOURCE_MTIME
    global PARQIT_FAST_SOURCE_CTIME
    global PARQIT_FAST_SOURCE_INODE
    global PARQIT_FAST_SOURCE_FOOTER
    if ("`parqit_fast_source_ok'" == "1") {
        if ("${PARQIT_FAST_SOURCE_SEQ}" == "") global PARQIT_FAST_SOURCE_SEQ = 0
        global PARQIT_FAST_SOURCE_SEQ = ${PARQIT_FAST_SOURCE_SEQ} + 1
        local _parqit_fast_nonce "`c(pid)'_${PARQIT_FAST_SOURCE_SEQ}"
        mata: st_local("_parqit_fast_path", _parqit_unhex(st_local("parqit_fast_source_path")))
        char _dta[_parqit_fast_source_nonce] "`_parqit_fast_nonce'"
        global PARQIT_FAST_SOURCE_NONCE "`_parqit_fast_nonce'"
        global PARQIT_FAST_SOURCE_PATH `"`_parqit_fast_path'"'
        global PARQIT_FAST_SOURCE_SIZE "`parqit_fast_source_size'"
        global PARQIT_FAST_SOURCE_MTIME "`parqit_fast_source_mtime'"
        global PARQIT_FAST_SOURCE_CTIME "`parqit_fast_source_ctime'"
        global PARQIT_FAST_SOURCE_INODE "`parqit_fast_source_inode'"
        global PARQIT_FAST_SOURCE_FOOTER "`parqit_fast_source_footer'"
        mata: (void) st_updata(0)
    }

    * a dta/xls/xlsx bridge has been consumed into memory — drop it now
    if (`"`_sq_bridge'"' != "") {
        capture noisily _parqit_bridge_discard `"`_sq_bridge'"'
        if (_rc) exit _rc
    }

    di as txt "(" as res "`parqit_k'" as txt " vars, " as res "`parqit_n'" ///
        as txt `" obs read from `_sq_file')"'
    _parqit_return_losses, ext(`"`_bl_ext'"') frac(`"`_bl_frac'"') tvars(`"`_bl_tvars'"') ///
        tcells("`_bl_tcells'") tmeta("`_bl_tmeta'") enc(`"`_bl_enc'"')
    return add
    return scalar N = `parqit_n'
    return scalar k = `parqit_k'
end

* shared staging: create vars in a tempframe, fetch, decorate, atomic swap
program define _parqit_load_core
    version 16.0
    * N-2G31: n() is a string, not n(integer) — syntax's integer parser
    * rejects any VALUE above 2,147,483,647 with a bare "option n() invalid"
    * before code runs, which is exactly how a 2.67B-row trades glob died
    * (live find). The plugin guards the SPI's 2^31-1 observation ceiling
    * with a real message before we get here; this parse-and-check is the
    * defence in depth that keeps the failure loud if a future path skips it.
    syntax, resp(string) strl(string) tag(string) n(string) [names(string)]
    confirm number `n'
    if (`n' > 2147483647) {
        local nfmt = strtrim("`: di %21.0fc `n''")
        di as err "parqit: the result has `nfmt' rows — more than the" ///
            " 2,147,483,647 observations the Stata plugin interface can" ///
            " address; aggregate or filter the lazy view first (parqit" ///
            " collapse, parqit keep if/in), or write it with parqit save"
        exit 901
    }

    tempname stage
    local curframe = c(frame)
    local loadrc = 0
    frame create `stage'
    frame `stage' {
        capture noisily {
            mata: _parqit_resp_create(`"`resp'"', `n')
            if (`n' > 0) {
                plugin call parqit_plugin `names' in 1/`n', use_fetch `tag'
            }
            mata: _parqit_apply_strl(`"`strl'"')
            mata: _parqit_resp_decorate(`"`resp'"')
            if (`"`parqit_dtalabel'"' != "") {
                mata: st_local("dl", _parqit_unhex(st_local("parqit_dtalabel")))
                * DTALABEL-LEN-1: a foreign >80-char dataset label must never
                * abort the load (Stata `label data` errors r(133)); truncate to
                * fit and apply best-effort, matching the metadata-restore charter.
                capture label data `"`dl'"'
                if (_rc) {
                    capture label data `"`=substr(`"`dl'"', 1, 80)'"'
                }
            }
            if (`"`parqit_sortedby'"' != "") {
                mata: st_local("sq_sortedby", _parqit_unhex(st_local("parqit_sortedby")))
                capture sort `sq_sortedby', stable
                if (_rc) {
                    di as txt "note: saved sortedby metadata was not accepted by Stata; marker skipped"
                }
            }
        }
        local loadrc = _rc
    }
    if (`loadrc') {
        frame drop `stage'
        exit `loadrc'
    }

    * Atomic swap by adopting the staged frame under the live name, rather
    * than deep-copying the (possibly multi-GB) result into `curframe`. The
    * stage is known-good at this point and the old data is discarded only
    * after the new frame is complete, so the validate-then-mutate guarantee
    * (charter §6.9) holds: if the fill above had failed we exited before here
    * with `curframe` untouched. This makes the swap O(1) in the data size and
    * avoids a transient second copy of the result in memory. `nobreak` closes
    * the one remaining hole: a user Break landing between `frame drop` and
    * `frame rename` would lose BOTH the old and the new data, so the whole
    * swap must be uninterruptible.
    nobreak {
        frame change `stage'
        frame drop `curframe'
        frame rename `stage' `curframe'
        global S_FN
        global S_FNDATE
        mata: (void) st_updata(0)
    }
end

* ----------------------------------------------------------------------------
* verbs on the lazy view
* ----------------------------------------------------------------------------

program define _parqit_keep
    version 16.0
    gettoken first : 0, parse(" ")
    if (`"`first'"' == "if") {
        gettoken first 0 : 0, parse(" ")
        _parqit_op_filter keep_if `0'
        exit
    }
    if (`"`first'"' == "in") {
        gettoken first 0 : 0, parse(" ")
        _parqit_op_keepin keep_in `0'
        exit
    }
    _parqit_op_names keep_vars `0'
end

program define _parqit_drop
    version 16.0
    gettoken first : 0, parse(" ")
    if (`"`first'"' == "if") {
        gettoken first 0 : 0, parse(" ")
        _parqit_op_filter drop_if `0'
        exit
    }
    if (`"`first'"' == "in") {
        * DROP-IN-1 (audit 2026-09-01, F10): native `drop in` exists; parqit
        * answered "variable in not found" — the complement of keep in
        gettoken first 0 : 0, parse(" ")
        _parqit_op_keepin drop_in `0'
        exit
    }
    _parqit_op_names drop_vars `0'
end

program define _parqit_op_filter
    version 16.0
    gettoken op 0 : 0, parse(" ")
    if (strtrim(`"`0'"') == "") {
        di as err "parqit: expression required"
        exit 198
    }
    _parqit_ensure_plugin
    tempfile req
    local _sq_op "`op'"
    local _sq_expr `"`0'"'
    mata: _parqit_wr_op_expr_request("`req'")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

program define _parqit_op_names
    version 16.0
    gettoken op 0 : 0, parse(" ")
    if (strtrim(`"`0'"') == "") {
        di as err "parqit: variable list required"
        exit 198
    }
    _parqit_ensure_plugin
    tempfile req
    local _sq_op "`op'"
    local _sq_names `"`0'"'
    mata: _parqit_wr_op_names_request("`req'")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

program define _parqit_op_keepin
    version 16.0
    * forms: f/l  |  #  — with Stata's range grammar (KEEPIN-FL-1, audit
    * 2026-08-22 A3-9): `f' and `l' may be numbers, the letters f (first) and
    * l (last), or negative counts from the end (-1 = last); `l'/negatives
    * resolve against the view's current row count (one count query — rigor
    * over cost), exactly like native `keep in`. The first token is the plugin
    * op: keep_in or drop_in (DROP-IN-1), which share the grammar.
    gettoken op 0 : 0, parse(" ")
    local verb = cond("`op'" == "drop_in", "drop", "keep")
    local range = strtrim(`"`0'"')
    local f 1
    local l .
    if (strpos(`"`range'"', "/")) {
        local f = strtrim(substr(`"`range'"', 1, strpos(`"`range'"', "/") - 1))
        local l = strtrim(substr(`"`range'"', strpos(`"`range'"', "/") + 1, .))
    }
    else {
        * Stata: `keep in #' keeps exactly that observation
        local f `range'
        local l `range'
    }
    _parqit_ensure_plugin
    local needs_n = (inlist(`"`f'"', "l", "L") | inlist(`"`l'"', "l", "L") | ///
        substr(`"`f'"', 1, 1) == "-" | substr(`"`l'"', 1, 1) == "-")
    if (`needs_n') {
        mata: st_local("whathex", _parqit_hex("count"))
        capture noisily plugin call parqit_plugin, view_info `whathex'
        if (_rc) exit _rc
        local N = `parqit_n'
    }
    foreach b in f l {
        if (inlist(`"``b''"', "f", "F")) local `b' 1
        else if (inlist(`"``b''"', "l", "L")) local `b' `N'
        else if (substr(`"``b''"', 1, 1) == "-") {
            capture confirm integer number ``b''
            if (_rc) {
                di as err "parqit `verb' in: range must be f/l with integer, f/l or negative bounds"
                exit 198
            }
            local `b' = `N' + ``b'' + 1
        }
    }
    capture confirm integer number `f'
    local bad = _rc
    capture confirm integer number `l'
    if (`bad' | _rc) {
        di as err "parqit `verb' in: range must be f/l with integer, f/l or negative bounds"
        exit 198
    }
    if (`f' < 1 | `l' < `f') {
        di as err "parqit `verb' in: invalid range `range' (observations 1 to `=cond("`N'" == "", "N", "`N'")')"
        exit 198
    }
    tempfile req
    local _sq_op "`op'"
    local _sq_f `f'
    local _sq_l `l'
    mata: _parqit_wr_op_keepin_request("`req'")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

program define _parqit_gen
    version 16.0
    * parqit gen [type] name = expr [if cond]
    local vtype
    gettoken t1 rest : 0, parse(" =")
    local isty 0
    if inlist("`t1'", "byte", "int", "long", "float", "double", "strL") local isty 1
    if (substr("`t1'", 1, 3) == "str" & !`isty') {
        capture confirm integer number `=substr("`t1'", 4, .)'
        if (!_rc) local isty 1
    }
    if (`isty') {
        local vtype `t1'
        local 0 `"`rest'"'
    }
    gettoken name 0 : 0, parse(" =")
    gettoken eq 0 : 0, parse(" =")
    if (`"`eq'"' != "=") {
        di as err "parqit gen: expected name = expression"
        exit 198
    }
    confirm name `name'
    mata: _parqit_split_if(st_local("0"))
    _parqit_ensure_plugin
    tempfile req
    local _sq_name "`name'"
    local _sq_type "`vtype'"
    mata: _parqit_wr_op_gen_request("`req'", "gen")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

program define _parqit_replace
    version 16.0
    gettoken name 0 : 0, parse(" =")
    gettoken eq 0 : 0, parse(" =")
    if (`"`eq'"' != "=") {
        di as err "parqit replace: expected name = expression"
        exit 198
    }
    confirm name `name'
    mata: _parqit_split_if(st_local("0"))
    _parqit_ensure_plugin
    tempfile req
    local _sq_name "`name'"
    local _sq_type ""
    mata: _parqit_wr_op_gen_request("`req'", "replace")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

program define _parqit_egen
    version 16.0
    * parqit egen [type] name = fcn(expr) [, by(varlist)]
    local vtype
    gettoken t1 rest : 0, parse(" =")
    local isty 0
    if inlist("`t1'", "byte", "int", "long", "float", "double", "strL") local isty 1
    if (substr("`t1'", 1, 3) == "str" & !`isty') {
        capture confirm integer number `=substr("`t1'", 4, .)'
        if (!_rc) local isty 1
    }
    if (`isty') {
        local vtype `t1'
        local 0 `"`rest'"'
    }
    gettoken name 0 : 0, parse(" =")
    gettoken eq 0 : 0, parse(" =")
    if (`"`eq'"' != "=") {
        di as err "parqit egen: expected name = fcn(expression)"
        exit 198
    }
    confirm name `name'
    * extract fcn(...) by matching parentheses, not by cutting at the first comma
    * (which split cond(x>0, y, .) mid-expression) — EGEN-1. The remainder after
    * the matching ")" is the option list ([, by(...)]).
    local rest0 = strtrim(`"`0'"')
    local p = strpos(`"`rest0'"', "(")
    if (`p' == 0) {
        di as err "parqit egen: expected fcn(expression)"
        exit 198
    }
    local fcn = strtrim(substr(`"`rest0'"', 1, `p' - 1))
    local n = strlen(`"`rest0'"')
    local depth 0
    local close 0
    local i = `p'
    while (`i' <= `n') {
        local ch = substr(`"`rest0'"', `i', 1)
        if ("`ch'" == "(")      local depth = `depth' + 1
        else if ("`ch'" == ")") {
            local depth = `depth' - 1
            if (`depth' == 0) {
                local close = `i'
                continue, break
            }
        }
        local i = `i' + 1
    }
    if (`close' == 0) {
        di as err "parqit egen: expected fcn(expression)"
        exit 198
    }
    local fexpr = substr(`"`rest0'"', `p' + 1, `close' - `p' - 1)
    local 0 = substr(`"`rest0'"', `close' + 1, .)
    syntax [, by(string)]
    _parqit_ensure_plugin
    tempfile req
    local _sq_name "`name'"
    local _sq_type "`vtype'"
    local _sq_fcn "`fcn'"
    local _sq_expr `"`fexpr'"'
    local _sq_by `"`by'"'
    mata: _parqit_wr_op_egen_request("`req'")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

program define _parqit_rename
    version 16.0
    * Two documented forms (RENAME-1):
    *   parqit rename oldname newname
    *   parqit rename (oldlist) (newlist)   [equal lengths, renamed pairwise]
    local in = strtrim(`"`0'"')
    if (substr(`"`in'"', 1, 1) == "(") {
        local c1 = strpos(`"`in'"', ")")
        if (`c1' == 0) {
            di as err "parqit rename: expected (oldlist) (newlist)"
            exit 198
        }
        local oldlist = strtrim(substr(`"`in'"', 2, `c1' - 2))
        local rest = strtrim(substr(`"`in'"', `c1' + 1, .))
        local c2 = strpos(`"`rest'"', ")")
        if (substr(`"`rest'"', 1, 1) != "(" | `c2' == 0) {
            di as err "parqit rename: expected (oldlist) (newlist)"
            exit 198
        }
        local newlist = strtrim(substr(`"`rest'"', 2, `c2' - 2))
        local tail = strtrim(substr(`"`rest'"', `c2' + 1, .))
        if (`"`tail'"' != "") {
            di as err "parqit rename: unexpected text after (newlist)"
            exit 198
        }
        local nold : word count `oldlist'
        local nnew : word count `newlist'
        if (`nold' != `nnew' | `nold' == 0) {
            di as err "parqit rename: oldlist and newlist must have the same (nonzero) length"
            exit 198
        }
        foreach nn of local newlist {
            confirm name `nn'
        }
        _parqit_ensure_plugin
        tempfile req
        local _sq_oldlist `"`oldlist'"'
        local _sq_newlist `"`newlist'"'
        mata: _parqit_wr_rename_many("`req'")
        capture noisily plugin call parqit_plugin, view_op `reqhex'
        if (_rc) exit _rc
        exit
    }
    gettoken oldn 0 : 0, parse(" ")
    gettoken newn 0 : 0, parse(" ")
    if (`"`oldn'"' == "" | `"`newn'"' == "" | strtrim(`"`0'"') != "") {
        di as err "parqit rename: syntax is parqit rename oldname newname  or  parqit rename (oldlist) (newlist)"
        exit 198
    }
    _parqit_rename_one `"`oldn'"' `"`newn'"'
end

program define _parqit_rename_one
    version 16.0
    args oldn newn
    confirm name `newn'
    _parqit_ensure_plugin
    tempfile req
    local _sq_old `"`oldn'"'
    local _sq_new `"`newn'"'
    mata: _parqit_wr_op_rename_request("`req'")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

program define _parqit_order
    version 16.0
    _parqit_op_names order `0'
end

program define _parqit_sort
    version 16.0
    if (strtrim(`"`0'"') == "") {
        di as err "parqit sort: variable list required"
        exit 198
    }
    _parqit_ensure_plugin
    tempfile req
    local _sq_keys `"`0'"'
    local _sq_desc ""
    foreach t of local 0 {
        local _sq_desc "`_sq_desc' 0"
    }
    mata: _parqit_wr_op_sort_request("`req'")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

program define _parqit_gsort
    version 16.0
    * tokens like -wage +id
    local keys
    local desc
    foreach t of local 0 {
        local s = substr(`"`t'"', 1, 1)
        if ("`s'" == "-") {
            local keys `"`keys' `=substr(`"`t'"', 2, .)'"'
            local desc "`desc' 1"
        }
        else if ("`s'" == "+") {
            local keys `"`keys' `=substr(`"`t'"', 2, .)'"'
            local desc "`desc' 0"
        }
        else {
            local keys `"`keys' `t'"'
            local desc "`desc' 0"
        }
    }
    if (strtrim(`"`keys'"') == "") {
        di as err "parqit gsort: variable list required"
        exit 198
    }
    _parqit_ensure_plugin
    tempfile req
    local _sq_keys `"`keys'"'
    local _sq_desc "`desc'"
    mata: _parqit_wr_op_sort_request("`req'")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

* Shared parser for aggregate specs `(stat) [tgt=]src ... [(stat) ...]' —
* collapse and pivot speak the same grammar. The first token is the calling
* verb (for error messages); the rest is the caller's `0'. Returns via
* c_local: `specs' as stat|tgt|src triples (tgt empty = keep source name)
* and `rest' as everything from the comma on, ready for -syntax-.
program define _parqit_parse_aggspecs
    version 16.0
    gettoken verb 0 : 0, parse(" ")
    * COLLAPSE-WEIGHTS: weights are not supported; reject them clearly rather
    * than letting the spec parser mangle "[fweight=n]" into a confusing
    * "variable n] not found" error. A "[" here can only be a weight expression.
    if (strpos(`"`0'"', "[") > 0) {
        di as err "parqit `verb': weights ([fweight=exp], [aweight=exp], " ///
            "[pweight=exp], [iweight=exp]) are not supported"
        exit 198
    }
    local stat "mean"
    local specs
    local pend
    local pendtgt 0
    local parsing 1
    while (`parsing') {
        gettoken tok 0 : 0, parse(" ,()=")
        if (`"`tok'"' == "" | `"`tok'"' == ",") {
            if ("`pend'" != "") local specs `"`specs' `stat'||`pend'"'
            local pend
            if (`"`tok'"' == ",") local 0 `", `0'"'
            local parsing 0
            continue
        }
        if (`"`tok'"' == "(") {
            if ("`pend'" != "") local specs `"`specs' `stat'||`pend'"'
            local pend
            gettoken stat 0 : 0, parse(" ()")
            gettoken close 0 : 0, parse(" ()")
            if (`"`close'"' != ")") {
                di as err "parqit `verb': malformed (statistic)"
                exit 198
            }
            continue
        }
        if (`"`tok'"' == "=") {
            if ("`pend'" == "" | `pendtgt') {
                di as err "parqit `verb': misplaced ="
                exit 198
            }
            local pendtgt 1
            continue
        }
        if (`pendtgt') {
            local specs `"`specs' `stat'|`pend'|`tok'"'
            local pend
            local pendtgt 0
            continue
        }
        if ("`pend'" != "") local specs `"`specs' `stat'||`pend'"'
        local pend `"`tok'"'
    }
    c_local specs `"`specs'"'
    c_local rest `"`0'"'
end

program define _parqit_collapse
    version 16.0
    * (stat) [tgt=]src ... [(stat) ...] , by(varlist)
    _parqit_parse_aggspecs collapse `0'
    local 0 `"`rest'"'
    if (strtrim(`"`specs'"') == "") {
        di as err "parqit collapse: nothing to compute"
        exit 198
    }
    syntax [, by(string)]
    _parqit_ensure_plugin
    tempfile req
    local _sq_specs `"`specs'"'
    local _sq_by `"`by'"'
    mata: _parqit_wr_op_collapse_request("`req'")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

program define _parqit_pivot
    version 16.0
    * (stat) [tgt=]src ... [(stat) ...] , rows(varlist) cols(varname)
    * The Excel-style pivot table as a lazy verb: collapse the specs by
    * (rows, cols), then spread cols' values into one wide column per value
    * (reshape wide of the targets, i(rows) j(cols)). The plugin applies the
    * two stages atomically — a refused spread leaves the view untouched.
    _parqit_parse_aggspecs pivot `0'
    local 0 `"`rest'"'
    if (strtrim(`"`specs'"') == "") {
        di as err "parqit pivot: nothing to compute; e.g. " ///
            "parqit pivot (sum) sales, rows(region) cols(quarter)"
        exit 198
    }
    syntax , Rows(string) Cols(name)
    _parqit_ensure_plugin
    tempfile req
    local _sq_specs `"`specs'"'
    local _sq_rows `"`rows'"'
    local _sq_col "`cols'"
    mata: _parqit_wr_pivot_request("`req'")
    capture noisily plugin call parqit_plugin, view_pivot `reqhex'
    if (_rc) exit _rc
end

program define _parqit_contract
    version 16.0
    syntax anything(name=vars) [, Freq(name)]
    _parqit_ensure_plugin
    tempfile req
    local _sq_names `"`vars'"'
    local _sq_freq "`freq'"
    mata: _parqit_wr_op_contract_request("`req'")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

program define _parqit_duplicates, rclass
    version 16.0
    gettoken sub 0 : 0, parse(" ,")
    if (`"`sub'"' == "report" | `"`sub'"' == "list") {
        syntax anything(name=vars) [, Limit(integer 20)]
        _parqit_ensure_plugin
        tempfile req resp
        local _sq_what = cond("`sub'" == "report", "dupreport", "duplist")
        local _sq_vars `"`vars'"'
        local _sq_limit `limit'
        mata: _parqit_wr_stats_request("`req'", "`resp'")
        capture noisily plugin call parqit_plugin, view_stats `reqhex'
        if (_rc) exit _rc
        if ("`sub'" == "report") {
            mata: _parqit_print_dupreport("`resp'")
            return scalar unique_value = `parqit_dup_unique'
            return scalar surplus = `parqit_dup_surplus'
            return scalar N = `parqit_dup_total'
        }
        else {
            mata: _parqit_print_duplist("`resp'")
        }
        exit
    }
    if (`"`sub'"' != "drop") {
        di as err "parqit duplicates: drop, report or list"
        exit 198
    }
    syntax [anything(name=vars)] [, force]
    _parqit_ensure_plugin
    tempfile req
    local _sq_names `"`vars'"'
    local _sq_force = ("`force'" != "")
    mata: _parqit_wr_op_dupdrop_request("`req'")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

program define _parqit_sample
    version 16.0
    syntax anything(name=amount) [, Count seed(integer -1)]
    confirm number `amount'
    if missing(`amount') {
        di as err "parqit sample: amount must be a finite number"
        exit 198
    }
    _parqit_ensure_plugin
    tempfile req
    local _sq_amount : display %24.17e (`amount')
    local _sq_count = cond("`count'" != "", "true", "false")
    local _sq_seed `seed'
    mata: _parqit_wr_op_sample_request("`req'")
    capture noisily plugin call parqit_plugin, view_op `reqhex'
    if (_rc) exit _rc
end

* ----------------------------------------------------------------------------
* materialisers and introspection
* ----------------------------------------------------------------------------

program define _parqit_collect, rclass
    version 16.0
    syntax [, clear]
    if ("`clear'" == "" & c(changed) & (c(N) > 0 | c(k) > 0)) {
        error 4
    }
    _parqit_ensure_plugin
    tempfile req resp strl
    local _sq_limit -1
    local _sq_cmdlabel "collect"
    mata: _parqit_wr_collect_request("`req'", "`resp'", "`strl'")
    capture noisily plugin call parqit_plugin, view_collect_prepare `reqhex'
    if (_rc) exit _rc

    _parqit_load_core, resp(`"`resp'"') strl(`"`strl'"') tag("`parqit_tag'") ///
        n(`parqit_n') names("`parqit_names'")

    plugin call parqit_plugin, view_alive
    mata: st_local("vname", _parqit_unhex(st_local("parqit_view_current")))
    di as txt "(" as res "`parqit_k'" as txt " vars, " as res "`parqit_n'" ///
        as txt " obs collected; view " as res "`vname'" as txt " remains open)"
    return scalar N = `parqit_n'
    return scalar k = `parqit_k'
end

program define _parqit_count, rclass
    version 16.0
    gettoken first : 0, parse(" ")
    if (`"`first'"' == "if") {
        gettoken first 0 : 0, parse(" ")
        if (strtrim(`"`0'"') == "") {
            di as err "parqit count: expression required after if"
            exit 198
        }
        _parqit_ensure_plugin
        tempfile req resp
        local _sq_what "countif"
        local _sq_vars ""
        local _sq_expr `"`0'"'
        mata: _parqit_wr_stats_request("`req'", "`resp'")
        capture noisily plugin call parqit_plugin, view_stats `reqhex'
        if (_rc) exit _rc
        di as txt "  " as res %21.0fc `parqit_n'
        return scalar N = `parqit_n'
        exit
    }
    syntax
    _parqit_ensure_plugin
    mata: st_local("whathex", _parqit_hex("count"))
    capture noisily plugin call parqit_plugin, view_info `whathex'
    if (_rc) exit _rc
    di as txt "  " as res %21.0fc `parqit_n'
    return scalar N = `parqit_n'
end

program define _parqit_head, rclass
    version 16.0
    syntax [anything(name=nrows)]
    if (`"`nrows'"' == "") local nrows 5
    confirm integer number `nrows'
    * a negative/zero count would reach the plugin as "no limit" and
    * materialise the entire view — refuse it here, loudly
    if (`nrows' < 1 | `nrows' >= .) {
        di as err "parqit head: # must be a positive integer"
        exit 198
    }
    _parqit_ensure_plugin
    tempfile req resp strl
    local _sq_limit `nrows'
    local _sq_cmdlabel "head"
    mata: _parqit_wr_collect_request("`req'", "`resp'", "`strl'")
    capture noisily plugin call parqit_plugin, view_collect_prepare `reqhex'
    if (_rc) exit _rc

    tempname stage
    local rc = 0
    frame create `stage'
    frame `stage' {
        capture noisily {
            mata: _parqit_resp_create("`resp'", `parqit_n')
            if (`parqit_n' > 0) {
                plugin call parqit_plugin `parqit_names' in 1/`parqit_n', use_fetch `parqit_tag'
            }
            mata: _parqit_apply_strl("`strl'")
            mata: _parqit_resp_decorate("`resp'")
            list, abbreviate(12)
        }
        local rc = _rc
    }
    frame drop `stage'
    if (`rc') exit `rc'
    return scalar N = `parqit_n'
end

program define _parqit_list, rclass
    version 16.0
    * parqit list [varlist] [if exp] [in f/l]   (non-mutating preview)
    local vars
    local ifexp
    local f 0
    local l 0
    local limit 20
    local parsing 1
    while (`parsing') {
        gettoken tok : 0, parse(" ")
        if (`"`tok'"' == "") {
            local parsing 0
            continue
        }
        if (`"`tok'"' == "if") {
            gettoken tok 0 : 0, parse(" ")
            mata: _parqit_split_in(st_local("0"))
            local ifexp `"`parqit_inexpr'"'
            if ("`parqit_inrange'" != "") {
                local f = real(word("`parqit_inrange'", 1))
                local l = real(word("`parqit_inrange'", 2))
            }
            local parsing 0
            continue
        }
        if (`"`tok'"' == "in") {
            gettoken tok 0 : 0, parse(" ")
            gettoken rng 0 : 0, parse(" ")
            if (strpos(`"`rng'"', "/")) {
                local f = real(substr(`"`rng'"', 1, strpos(`"`rng'"', "/") - 1))
                local l = real(substr(`"`rng'"', strpos(`"`rng'"', "/") + 1, .))
            }
            else {
                local f = real(`"`rng'"')
                local l = `f'
            }
            continue
        }
        gettoken tok 0 : 0, parse(" ")
        local vars `vars' `tok'
    }
    if (`f' < 0 | `l' < `f' | (`f' == 0 & `l' != 0) | `f' == . | `l' == .) {
        di as err "parqit list: invalid in range"
        exit 198
    }
    _parqit_ensure_plugin
    tempfile req resp strl
    * A default preview is a LIMIT, not an explicit in 1/20 range: on a view
    * with fewer than 20 rows native list shows what exists instead of r(198).
    local _sq_limit = cond(`f' == 0, cond(`"`ifexp'"' != "", 200, `limit'), -1)
    local _sq_pvars `"`vars'"'
    local _sq_pfilter `"`ifexp'"'
    local _sq_pf `f'
    local _sq_pl `l'
    local _sq_cmdlabel "list"
    mata: _parqit_wr_collect_request("`req'", "`resp'", "`strl'")
    capture noisily plugin call parqit_plugin, view_collect_prepare `reqhex'
    if (_rc) exit _rc

    tempname stage
    local rc = 0
    frame create `stage'
    frame `stage' {
        capture noisily {
            mata: _parqit_resp_create("`resp'", `parqit_n')
            if (`parqit_n' > 0) {
                plugin call parqit_plugin `parqit_names' in 1/`parqit_n', use_fetch `parqit_tag'
            }
            mata: _parqit_apply_strl("`strl'")
            mata: _parqit_resp_decorate("`resp'")
            list, abbreviate(12)
        }
        local rc = _rc
    }
    frame drop `stage'
    if (`rc') exit `rc'
    if (`"`ifexp'"' != "" & `f' == 0 & `parqit_n' == 200) {
        di as txt "(showing the first 200 matching rows; add {bf:in f/l} to page)"
    }
    return scalar N = `parqit_n'
end

program define _parqit_ds, rclass
    version 16.0
    syntax
    _parqit_ensure_plugin
    tempfile resp
    mata: st_local("whathex", _parqit_hex("describe"))
    mata: st_local("resphex", _parqit_hex(st_local("resp")))
    capture noisily plugin call parqit_plugin, view_info `whathex' `resphex'
    if (_rc) exit _rc
    mata: _parqit_collect_names("`resp'", "")
    di as txt `"`parqit_dsnames'"'
    return local varlist `"`parqit_dsnames'"'
end

program define _parqit_lookfor, rclass
    version 16.0
    syntax anything(name=terms)
    _parqit_ensure_plugin
    tempfile resp
    mata: st_local("whathex", _parqit_hex("describe"))
    mata: st_local("resphex", _parqit_hex(st_local("resp")))
    capture noisily plugin call parqit_plugin, view_info `whathex' `resphex'
    if (_rc) exit _rc
    local _sq_terms `"`terms'"'
    mata: _parqit_lookfor_resp("`resp'")
    return local varlist `"`parqit_dsnames'"'
end

program define _parqit_codebook, rclass
    version 16.0
    syntax [anything(name=vars)]
    _parqit_ensure_plugin
    tempfile req resp
    local _sq_what "codebook"
    local _sq_vars `"`vars'"'
    mata: _parqit_wr_stats_request("`req'", "`resp'")
    capture noisily plugin call parqit_plugin, view_stats `reqhex'
    if (_rc) exit _rc
    mata: _parqit_print_codebook("`resp'")
end

program define _parqit_distinct, rclass
    version 16.0
    syntax [anything(name=vars)] [, Joint]
    _parqit_ensure_plugin
    tempfile req resp
    local _sq_what "distinct"
    local _sq_vars `"`vars'"'
    local _sq_joint = ("`joint'" != "")
    mata: _parqit_wr_stats_request("`req'", "`resp'")
    capture noisily plugin call parqit_plugin, view_stats `reqhex'
    if (_rc) exit _rc
    mata: _parqit_print_distinct("`resp'")
    return scalar N = `parqit_n'
    return scalar ndistinct = `parqit_ndistinct'
end

program define _parqit_tabstat, rclass
    version 16.0
    gettoken vars 0 : 0, parse(",")
    local vars = strtrim(`"`vars'"')
    if ("`vars'" == "") {
        di as err "parqit tabstat: a numeric varlist is required"
        exit 198
    }
    syntax [, Statistics(string) by(name) SAVE]
    if (`"`statistics'"' == "") local statistics "mean"
    _parqit_ensure_plugin
    tempfile req resp
    local _sq_what "tabstat"
    local _sq_vars `"`vars'"'
    local _sq_stats = strlower(`"`statistics'"')
    local _sq_by "`by'"
    local _sq_save "`save'"
    mata: _parqit_wr_stats_request("`req'", "`resp'")
    capture noisily plugin call parqit_plugin, view_stats `reqhex'
    if (_rc) exit _rc
    mata: _parqit_print_tabstat("`resp'")
    if ("`save'" != "") {
        if ("`by'" == "") return matrix StatTotal = `parqit_ts_mat1'
        else {
            forvalues i = 1/`parqit_ts_groups' {
                return matrix Stat`i' = `parqit_ts_mat`i''
                return local name`i' `"`parqit_ts_name`i''"'
            }
        }
    }
end

program define _parqit_correlate, rclass
    version 16.0
    syntax anything(name=vars)
    _parqit_ensure_plugin
    tempfile req resp
    local _sq_what "corr"
    local _sq_vars `"`vars'"'
    local _sq_pairwise "false"
    mata: _parqit_wr_stats_request("`req'", "`resp'")
    capture noisily plugin call parqit_plugin, view_stats `reqhex'
    if (_rc) exit _rc
    local _sq_sig ""
    local _sq_obs ""
    tempname C
    local _sq_corr_matrix "`C'"
    mata: _parqit_print_corr("`resp'")
    if ("`parqit_corr_matrices'" == "1") return matrix C = `C'
    return scalar N = `parqit_corr_n'
    return scalar rho = `parqit_corr_last'
end

program define _parqit_pwcorr, rclass
    version 16.0
    gettoken vars 0 : 0, parse(",")
    local vars = strtrim(`"`vars'"')
    syntax [, obs sig]
    _parqit_ensure_plugin
    tempfile req resp
    local _sq_what "corr"
    local _sq_vars `"`vars'"'
    local _sq_pairwise "true"
    mata: _parqit_wr_stats_request("`req'", "`resp'")
    capture noisily plugin call parqit_plugin, view_stats `reqhex'
    if (_rc) exit _rc
    local _sq_sig "`sig'"
    local _sq_obs "`obs'"
    tempname C Nobs P
    local _sq_corr_matrix "`C'"
    local _sq_count_matrix "`Nobs'"
    local _sq_p_matrix "`P'"
    mata: _parqit_print_corr("`resp'")
    if ("`parqit_corr_matrices'" == "1") {
        return matrix C = `C'
        return matrix Nobs = `Nobs'
        if ("`sig'" != "") return matrix sig = `P'
    }
    return scalar N = `parqit_corr_n'
    return scalar rho = `parqit_corr_last'
end

program define _parqit_histogram, rclass
    version 16.0
    syntax anything(name=var) [, Bins(integer 0) NODRAW]
    if (`bins' < 0) {
        di as err "parqit histogram: bins() must be nonnegative (0 selects automatic bins)"
        exit 198
    }
    _parqit_ensure_plugin
    tempfile req resp
    local _sq_what "hist"
    local _sq_vars `"`var'"'
    local _sq_bins `bins'
    mata: _parqit_wr_stats_request("`req'", "`resp'")
    capture noisily plugin call parqit_plugin, view_stats `reqhex'
    if (_rc) exit _rc

    * tiny bin table → scratch frame → bar chart; the data never loads
    tempname hf
    local nb = `parqit_hist_bins'
    frame create `hf'
    frame `hf' {
        qui set obs `nb'
        qui gen double __mid = .
        qui gen double __freq = 0
        mata: _parqit_fill_hist("`resp'")
        if ("`nodraw'" == "") {
            local draw_width = cond(`parqit_hist_width' > 0, `parqit_hist_width', 1)
            twoway bar __freq __mid, barwidth(`draw_width') ///
                xtitle(`"`var'"') ytitle("frequency") name(parqit_hist, replace)
        }
    }
    frame drop `hf'
    return scalar N = `parqit_n'
    return scalar bins = `parqit_hist_bins'
    return scalar width = `parqit_hist_width'
    return scalar start = `parqit_hist_lo'
end

program define _parqit_show
    version 16.0
    syntax
    _parqit_ensure_plugin
    tempfile resp
    mata: st_local("whathex", _parqit_hex("show"))
    mata: st_local("resphex", _parqit_hex(st_local("resp")))
    capture noisily plugin call parqit_plugin, view_info `whathex' `resphex'
    if (_rc) exit _rc
    mata: _parqit_print_resp("`resp'", "sql")
end

program define _parqit_explain
    version 16.0
    syntax
    _parqit_ensure_plugin
    tempfile resp
    mata: st_local("whathex", _parqit_hex("explain"))
    mata: st_local("resphex", _parqit_hex(st_local("resp")))
    capture noisily plugin call parqit_plugin, view_info `whathex' `resphex'
    if (_rc) exit _rc
    mata: _parqit_print_resp("`resp'", "plan")
end

program define _parqit_glimpse
    version 16.0
    _parqit_describe `0'
end

program define _parqit_describe, rclass
    version 16.0
    syntax [anything(name=target)]
    _parqit_ensure_plugin

    if (`"`target'"' == "") {
        * describe the open view
        tempfile resp
        mata: st_local("whathex", _parqit_hex("describe"))
        mata: st_local("resphex", _parqit_hex(st_local("resp")))
        capture noisily plugin call parqit_plugin, view_info `whathex' `resphex'
        if (_rc) exit _rc
        mata: st_local("vsrc", _parqit_unhex(st_local("parqit_view_src")))
        di as txt ""
        di as txt "  lazy view over " as res `"`vsrc'"'
        di as txt "  columns: " as res "`parqit_view_k'" ///
            as txt "   pipeline steps: " as res "`parqit_view_stages'"
        di as txt ""
        mata: _parqit_print_view_describe("`resp'")
        return scalar n_cols = `parqit_view_k'
        return scalar n_columns = `parqit_view_k'   /* pq-compatible alias */
        return scalar n_steps = `parqit_view_stages'
        exit
    }

    local file `target'
    * DESCRIBE-EXT-1: describe/glimpse of a SOURCE is a Parquet footer read; it
    * deliberately does not invoke the CSV/Stata/Excel adapters (documented in
    * the help). Handing a .csv/.dta to read_parquet produced the engine's raw
    * "Invalid Input Error" with rc 920 — technically loud, but it named neither
    * the cause nor the remedy. Classify the extension the same way
    * _parqit_resolve_source does (basename, final dot, case-insensitive).
    * A Hive directory may legitimately be named with any suffix, so only a
    * non-directory is classified by extension.
    mata: st_local("_d_isdir", strofreal(direxists(st_local("file"))))
    local _d_base = substr(`"`file'"', strrpos(`"`file'"', "/") + 1, .)
    local _d_ext ""
    if ("`_d_isdir'" == "0" & strpos(`"`_d_base'"', ".") > 0) ///
        local _d_ext = lower(substr(`"`_d_base'"', strrpos(`"`_d_base'"', ".") + 1, .))
    if inlist("`_d_ext'", "csv", "tsv", "txt", "tab", "dta") | ///
       inlist("`_d_ext'", "xls", "xlsx") {
        di as err "parqit describe: reads Parquet footers only (file, glob or Hive directory)"
        di as err `"open `_d_ext' input with {bf:parqit use using `file'} and describe the view instead"'
        exit 198
    }
    tempfile req resp
    local _sq_file `"`file'"'
    mata: _parqit_wr_describe_request("`req'", "`resp'")
    capture noisily plugin call parqit_plugin, describe `reqhex'
    if (_rc) exit _rc

    di as txt ""
    di as txt `"  `_sq_file'"'
    di as txt "  rows: " as res %20.0fc `parqit_n' ///
        as txt "   columns: " as res "`parqit_k'" ///
        as txt "   row groups: " as res "`parqit_row_groups'" ///
        as txt "   files: " as res "`parqit_n_files'" ///
        as txt "   parqit metadata: " as res cond("`parqit_has_meta'" == "1", "yes", "no")
    di as txt ""
    mata: _parqit_resp_describe("`resp'")

    return scalar n_rows = `parqit_n'
    return scalar n_cols = `parqit_k'
    return scalar n_columns = `parqit_k'   /* pq-compatible alias of n_cols */
    return scalar n_row_groups = `parqit_row_groups'
    return scalar n_files = `parqit_n_files'
    return scalar has_parqit_meta = ("`parqit_has_meta'" == "1")
    forvalues i = 1/`parqit_k' {
        return local name_`i' `"`parqit_dname_`i''"'
        return local type_`i' `"`parqit_dtype_`i''"'
        return local stata_type_`i' `"`parqit_dstype_`i''"'
    }
end

* ----------------------------------------------------------------------------
* parqit save — view → parquet when a view is open; else in-memory → parquet
* ----------------------------------------------------------------------------

* Lossy-conversion notes shared by every Parquet-write path (in-memory save,
* view save, and the parqit open _data bridge) so the warnings never depend on
* which path produced the loss (ATOM-2). Each list is space-separated variable
* names; an empty list prints nothing.
program define _parqit_lossy_notes
    version 16.0
    syntax [, ext(string) frac(string) TRANSvars(string) ///
        TRANScells(integer 0) TRANSmeta(integer 0) ENCoding(string) SOURCE(string)]
    * BRIDGE-LOSS-1: a source() names the bridged file so the reader knows the
    * conversions happened while snapshotting it, not to the dataset in memory
    if (`"`source'"' != "" & (`transcells' > 0 | `transmeta' > 0 | ///
        `"`ext'"' != "" | `"`frac'"' != "")) {
        di as txt "note: while bridging " as res `"`source'"' ///
            as txt " to Parquet (a parqit save of the imported data):"
    }
    if (`transcells' > 0 | `transmeta' > 0) {
        * ENC-2: legacy 8-bit text was transcoded on the way out, never refused
        local nmeta = strtrim("`: di %20.0fc `transmeta''")
        local ncells = strtrim("`: di %20.0fc `transcells''")
        local what
        if (`transmeta' > 0) {
            local what "`nmeta' metadata item(s) (labels, value labels, notes, characteristics)"
        }
        if (`transcells' > 0) {
            if (`"`what'"' != "") local what "`what'; "
            local what "`what'`ncells' string cell(s) in `transvars'"
        }
        di as txt "note: text that was not valid UTF-8 (legacy 8-bit bytes) was " ///
            "transcoded from " as res "`encoding'" as txt " to UTF-8: " ///
            as res `"`what'"' as txt " — see {bf:encoding()} in {help parqit}"
    }
    if (`"`ext'"' != "") {
        di as txt "note: extended missing values (.a-.z) in " ///
            as res `"`ext'"' ///
            as txt " were written as nulls (Parquet has a single missing concept)"
    }
    if (`"`frac'"' != "") {
        di as txt "note: non-integer date/period values in " ///
            as res `"`frac'"' as txt " were rounded to the nearest unit"
    }
end

program define _parqit_save, rclass
    version 16.0
    syntax anything(name=target id="filename") [, replace Data ///
        COMPression(string) compression_level(integer -1) PARTition_by(string) ///
        Chunk(integer -1) ENCoding(string) COPYsource partitions(string)]

    local dest `target'
    * PART-MODE-1: partitions(replace|append) updates an existing Hive tree
    * partition by partition; it needs partition_by() and excludes replace
    local partitions = strlower(strtrim("`partitions'"))
    if ("`partitions'" != "" & !inlist("`partitions'", "replace", "append")) {
        di as err "parqit save: partitions() must be replace or append"
        exit 198
    }
    if ("`partitions'" != "" & "`partition_by'" == "") {
        di as err "parqit save: partitions(`partitions') needs partition_by()"
        exit 198
    }
    if ("`partitions'" != "" & "`replace'" != "") {
        di as err "parqit save: partitions(`partitions') and replace are mutually exclusive;" ///
            " replace rewrites the whole tree, partitions() touches only the partitions in the result"
        exit 198
    }
    if ("`partitions'" != "" & "`copysource'" != "") {
        di as err "parqit save: copysource copies one file; partitions() is not available with it"
        exit 198
    }
    _parqit_ensure_plugin
    plugin call parqit_plugin, view_alive

    if ("`copysource'" != "" & "`parqit_view_alive'" == "1" & "`data'" == "") {
        di as err "parqit save: copysource applies to a save of the dataset in memory;" ///
            " add the data option (or close the view) to use it"
        exit 198
    }
    if ("`parqit_view_alive'" == "1" & "`data'" == "") {
        mata: st_local("vname", _parqit_unhex(st_local("parqit_view_current")))
        di as txt "(materialising view " as res "`vname'" ///
            as txt " — the dataset in memory is untouched; use the " ///
            as txt "{bf:data} option to export memory instead)"
        tempfile req
        local _sq_dest `"`dest'"'
        local _sq_replace = ("`replace'" != "")
        local _sq_comp `"`compression'"'
        local _sq_complevel = `compression_level'
        local _sq_partition `"`partition_by'"'
        local _sq_pmode "`partitions'"
        local _sq_chunk = `chunk'
        local _sq_encoding `"`encoding'"'
        mata: _parqit_wr_view_save_request("`req'")
        capture noisily plugin call parqit_plugin, view_save `reqhex'
        if (_rc) exit _rc
        mata: st_local("destabs", _parqit_unhex(st_local("parqit_dest")))
        * A view over a Parquet source carries no Stata extended missings, so
        * only the date/period rounding note can fire here (parqit_frac_dates is
        * set by view_save; parqit_ext_missing stays empty) — ATOM-2.
        _parqit_lossy_notes, ext(`"`parqit_ext_missing'"') frac(`"`parqit_frac_dates'"')
        di as txt "(" as res "`parqit_written_n'" as txt " obs, " ///
            as res "`parqit_written_k'" as txt `" vars written to `destabs')"'
        return local filename `"`destabs'"'
        return local view "`vname'"
        return scalar N = `parqit_written_n'
        return scalar k = `parqit_written_k'
        return local ext_missing `"`parqit_ext_missing'"'
        return local frac_dates `"`parqit_frac_dates'"'
        exit
    }

    if (c(k) == 0) {
        di as err "no variables defined"
        exit 111
    }
    qui ds
    local allvars `r(varlist)'

    tempfile req
    local _sq_dest `"`dest'"'
    local _sq_replace = ("`replace'" != "")
    local _sq_comp `"`compression'"'
    local _sq_complevel = `compression_level'
    local _sq_partition `"`partition_by'"'
    local _sq_pmode "`partitions'"
    local _sq_chunk = `chunk'
    local _sq_encoding `"`encoding'"'
    local _sq_dtalabel `: data label'
    local _sq_sortedby `: sortedby'
    local _sq_direct = 0
    * COPYSOURCE-1 (audit 2026-08-22, A4-1/A4-2): the source-copy path never
    * runs automatically any more — c(changed) cannot prove the dataset equals
    * the file (Stata exempts sort/gsort and Mata st_store/st_view writes). It
    * is an explicit opt-in, and every failed check is a loud refusal: the
    * dataset must be the one loaded by the last `parqit use ..., clear`
    * (nonce), untouched (c(changed)==0, no filename), and the plugin re-proves
    * the file's identity (size, mtime, ctime, inode, footer digest), names,
    * N and sort order before — and again right before publishing — the copy.
    if ("`copysource'" != "") {
        local _fast_nonce : char _dta[_parqit_fast_source_nonce]
        local _fast_global `"${PARQIT_FAST_SOURCE_NONCE}"'
        if (`"`_fast_global'"' == "" | `"`_fast_nonce'"' != `"`_fast_global'"') {
            di as err "parqit save: copysource — the dataset in memory is not the one" ///
                " loaded by the last {bf:parqit use ..., clear} of a single Parquet file" ///
                " (no source to copy); use the default save"
            exit 198
        }
        if (c(changed) != 0 | `"`c(filename)'"' != "") {
            di as err "parqit save: copysource — the dataset in memory has been changed" ///
                " since it was loaded (c(changed) is " c(changed) "); use the default save"
            exit 198
        }
        local _sq_direct = 1
        local _sq_source `"$PARQIT_FAST_SOURCE_PATH"'
        local _sq_source_size `"$PARQIT_FAST_SOURCE_SIZE"'
        local _sq_source_mtime `"$PARQIT_FAST_SOURCE_MTIME"'
        local _sq_source_ctime `"$PARQIT_FAST_SOURCE_CTIME"'
        local _sq_source_inode `"$PARQIT_FAST_SOURCE_INODE"'
        local _sq_source_footer `"$PARQIT_FAST_SOURCE_FOOTER"'
        local _sq_nobs = _N
    }
    * VALLAB-ALL-1: every value label defined in the dataset travels, attached
    * or not (native save keeps `label define` orphans too)
    quietly label dir
    local _sq_vallabs_all `"`r(names)'"'
    mata: _parqit_wr_save_request("`req'")

    if (`_sq_direct') {
        capture noisily plugin call parqit_plugin `allvars', save_data_direct `reqhex'
        if (_rc) exit _rc
        if ("`parqit_direct_done'" != "1") {
            di as err "parqit save: copysource — the source copy did not complete; use the default save"
            exit 920
        }
        mata: st_local("destabs", _parqit_unhex(st_local("parqit_dest")))
        _parqit_lossy_notes, ext(`"`parqit_ext_missing'"') frac(`"`parqit_frac_dates'"') ///
            transvars(`"`parqit_transcoded_vars'"') transcells(`parqit_transcoded_cells') ///
            transmeta(`parqit_transcoded_meta') encoding(`"`parqit_encoding'"')
        di as txt "(" as res "`parqit_written_n'" as txt " obs, " ///
            as res "`parqit_written_k'" as txt `" vars written to `destabs' — copied from the unchanged source file)"'
        return local filename `"`destabs'"'
        return scalar N = `parqit_written_n'
        return scalar k = `parqit_written_k'
        return local ext_missing `"`parqit_ext_missing'"'
        return local frac_dates `"`parqit_frac_dates'"'
        return local transcoded_vars `"`parqit_transcoded_vars'"'
        return scalar transcoded_cells = `parqit_transcoded_cells'
        return scalar transcoded_meta = `parqit_transcoded_meta'
        return local encoding `"`parqit_encoding'"'
        return local copysource `"`_sq_source'"'
        exit
    }

    capture noisily plugin call parqit_plugin `allvars', save_data `reqhex'
    if (_rc) exit _rc

    mata: st_local("destabs", _parqit_unhex(st_local("parqit_dest")))
    _parqit_lossy_notes, ext(`"`parqit_ext_missing'"') frac(`"`parqit_frac_dates'"') ///
        transvars(`"`parqit_transcoded_vars'"') transcells(`parqit_transcoded_cells') ///
        transmeta(`parqit_transcoded_meta') encoding(`"`parqit_encoding'"')
    di as txt "(" as res "`parqit_written_n'" as txt " obs, " ///
        as res "`parqit_written_k'" as txt `" vars written to `destabs')"'
    return local filename `"`destabs'"'
    return scalar N = `parqit_written_n'
    return scalar k = `parqit_written_k'
    return local transcoded_vars `"`parqit_transcoded_vars'"'
    return scalar transcoded_cells = `parqit_transcoded_cells'
    return scalar transcoded_meta = `parqit_transcoded_meta'
    return local encoding `"`parqit_encoding'"'
    return local ext_missing `"`parqit_ext_missing'"'
    return local frac_dates `"`parqit_frac_dates'"'
end

* ----------------------------------------------------------------------------
* parqit open _data — promote the in-memory dataset to a lazy view
* ----------------------------------------------------------------------------

program define _parqit_open, rclass
    version 16.0
    syntax anything(name=what) [, Name(name) ENCoding(string)]
    if (`"`what'"' != "_data") {
        di as err "parqit open: only {bf:parqit open _data} is supported"
        exit 198
    }
    if (c(k) == 0) {
        di as err "no variables defined"
        exit 111
    }
    local nobs = _N
    _parqit_ensure_plugin
    * Reserve atomically in the plugin.  c(pid) and c(processid) are empty on
    * some supported StataNow builds, so an ado-side per-session counter cannot
    * distinguish concurrent sessions sharing TMPDIR (BRIDGE-XPROC-1).
    _parqit_bridge_new opendata
    local bridge `"`r(bridge)'"'
    capture noisily {
        quietly _parqit_save `"`bridge'"', replace data encoding(`"`encoding'"')
    }
    local rc = _rc
    if (`rc') {
        capture _parqit_bridge_discard `"`bridge'"'
        exit `rc'
    }
    * The bridge snapshot applies the same lossy conversions as any in-memory
    * save (extended missings -> null, fractional dates rounded, legacy text
    * transcoded — BRIDGE-LOSS-1). _parqit_save's own notes were suppressed by
    * `qui'; surface them here so the loss is not silent when the dataset is
    * later collected/saved through the view (ATOM-2), and return them.
    local _parqit_open_ext  `"`r(ext_missing)'"'
    local _parqit_open_frac `"`r(frac_dates)'"'
    local _parqit_open_tvars `"`r(transcoded_vars)'"'
    local _parqit_open_tcells = cond(r(transcoded_cells) < ., r(transcoded_cells), 0)
    local _parqit_open_tmeta = cond(r(transcoded_meta) < ., r(transcoded_meta), 0)
    local _parqit_open_enc `"`r(encoding)'"'
    capture noisily {
        if ("`name'" == "") qui _parqit_use using `"`bridge'"', owned
        else                qui _parqit_use using `"`bridge'"', name(`name') owned
    }
    local rc = _rc
    if (`rc') {
        capture _parqit_bridge_discard `"`bridge'"'
        exit `rc'
    }
    di as txt "(in-memory dataset promoted to a lazy view; " ///
        as txt "manipulate with parqit verbs, then parqit collect or parqit save)"
    _parqit_lossy_notes, ext(`"`_parqit_open_ext'"') frac(`"`_parqit_open_frac'"') ///
        transvars(`"`_parqit_open_tvars'"') transcells(`_parqit_open_tcells') ///
        transmeta(`_parqit_open_tmeta') encoding(`"`_parqit_open_enc'"')
    _parqit_return_losses, ext(`"`_parqit_open_ext'"') frac(`"`_parqit_open_frac'"') ///
        tvars(`"`_parqit_open_tvars'"') tcells("`_parqit_open_tcells'") ///
        tmeta("`_parqit_open_tmeta'") enc(`"`_parqit_open_enc'"')
    return add
    if (`nobs' >= 1000000) {
        local nstr : di %15.0fc `nobs'
            _parqit_tip `"promoting `=trim("`nstr'")' obs writes a temporary bridge; if you only need to merge/append a small disk lookup, {bf:parqit mergein}/{bf:parqit appendin} keeps the data in Stata and skips it"'
    }
    return local bridge `"`bridge'"'
end

program define _parqit_close
    version 16.0
    syntax [anything(name=which)]
    _parqit_ensure_plugin
    if (`"`which'"' == "") {
        plugin call parqit_plugin, view_close
        di as txt "(current view closed)"
        exit
    }
    if (`"`which'"' == "_all") {
        mata: st_local("whex", _parqit_hex("_all"))
    }
    else {
        confirm name `which'
        mata: st_local("whex", _parqit_hex(st_local("which")))
    }
    capture noisily plugin call parqit_plugin, view_close `whex'
    if (_rc) exit _rc
    di as txt "(view`=cond("`which'"=="_all","s","")' closed)"
end

* parqit view             -> list open views (same as parqit views)
* parqit view <name>      -> make <name> the current view
* parqit view <name>: cmd -> run one parqit command against <name>, then restore
program define _parqit_view, rclass
    version 16.0
    if (strtrim(`"`0'"') == "") {
        _parqit_views
        return add
        exit
    }
    gettoken name 0 : 0, parse(" :")
    confirm name `name'
    gettoken colon : 0, parse(" :")
    _parqit_ensure_plugin

    if (`"`colon'"' != ":") {
        mata: st_local("nhex", _parqit_hex(st_local("name")))
        capture noisily plugin call parqit_plugin, view_switch `nhex'
        if (_rc) exit _rc
        di as txt "(current view: " as res "`name'" as txt ")"
        return local view "`name'"
        exit
    }

    * prefix form: remember current, switch, run, switch back
    gettoken colon 0 : 0, parse(" :")
    plugin call parqit_plugin, view_alive
    mata: st_local("prev", _parqit_unhex(st_local("parqit_view_current")))
    mata: st_local("nhex", _parqit_hex(st_local("name")))
    capture noisily plugin call parqit_plugin, view_switch `nhex'
    if (_rc) exit _rc
    capture noisily parqit `0'
    local rc = _rc
    if ("`prev'" != "" & "`prev'" != "`name'") {
        mata: st_local("phex", _parqit_hex(st_local("prev")))
        capture plugin call parqit_plugin, view_switch `phex'
        if (_rc) {
            local swrc = _rc
            di as err "parqit view: could not switch back to view `prev'; "  ///
                "the current view is now `name' — use {bf:parqit view `prev'} to return"
            exit `swrc'
        }
    }
    if (`rc') exit `rc'
    return add
end

program define _parqit_views, rclass
    version 16.0
    syntax
    _parqit_ensure_plugin
    tempfile resp
    mata: st_local("rhex", _parqit_hex(st_local("resp")))
    capture noisily plugin call parqit_plugin, view_list `rhex'
    if (_rc) exit _rc
    if (`parqit_n_views' == 0) {
        di as txt "(no views open)"
        return scalar n_views = 0
        exit
    }
    mata: _parqit_print_views("`resp'")
    return scalar n_views = `parqit_n_views'
end

program define _parqit_set
    version 16.0
    gettoken what 0 : 0, parse(" ")
    /* SET-TEMPDIR-2: take the value via macro expansion so ONE surrounding pair
     * of quotes the caller used — regular "..." OR compound `"..."' (mandatory
     * for a path with spaces) — is stripped and `value' is the literal setting.
     * Keeping the quotes left a later regular-quoted reference ("`value'")
     * expanding to ""/abs/path"", which Stata parses as an arithmetic expression
     * (a leading "/" divides by the first path component) and aborts with
     * `<first component> not found`, rc 111 — so `parqit set tempdir "/scratch/me"`
     * failed on every Unix absolute path. With the quotes gone, direxists/hex and
     * the engine all receive the real path. */
    local value `0'
    local value = strtrim(`"`value'"')
    if !inlist("`what'", "statamissing", "threads", "memory_limit", "tempdir") {
        di as err "parqit set: expected statamissing|threads|memory_limit|tempdir <value>"
        exit 198
    }
    if ("`what'" == "statamissing" & !inlist("`value'", "on", "off")) {
        di as err "parqit set statamissing: on or off"
        exit 198
    }
    * SET-TEMPDIR-1: DuckDB accepts a non-existent spill dir silently and only
    * fails much later at spill time. Warn now (but do not block: the user may
    * create it before the first out-of-core query).
    if ("`what'" == "tempdir" & `"`value'"' != "") {
        mata: st_local("_dirok", strofreal(direxists(st_local("value"))))
        if ("`_dirok'" == "0") {
            di as txt "note: parqit set tempdir — directory does not exist yet: " ///
                as res `"`value'"' as txt "; spill will fail unless it is created"
        }
    }
    _parqit_ensure_plugin
    mata: st_local("whathex", _parqit_hex(st_local("what")))
    mata: st_local("valhex", _parqit_hex(st_local("value")))
    capture noisily plugin call parqit_plugin, set `whathex' `valhex'
    if (_rc) exit _rc
end

* ----------------------------------------------------------------------------
* two-table verbs: merge / append / joinby (using side stays on disk)
* ----------------------------------------------------------------------------

program define _parqit_merge, rclass
    version 16.0
    * lazy kinds: 1:1|m:1|1:m; recognise m:m only to refuse it precisely
    gettoken kind 0 : 0, parse(" ")
    if !inlist("`kind'", "1:1", "m:1", "1:m", "m:m") {
        di as err "parqit merge: kind must be 1:1, m:1, 1:m or m:m"
        exit 198
    }
    if ("`kind'" == "m:m") {
        di as err "parqit merge: lazy m:m is refused because a lazy plan cannot preserve native Stata's physical within-key row order"
        di as err "use {bf:parqit joinby} for Cartesian matches or {bf:parqit mergein m:m} for native sequential behavior"
        exit 198
    }
    local keys
    gettoken tok : 0, parse(" ")
    while (`"`tok'"' != "using" & `"`tok'"' != "") {
        gettoken tok 0 : 0, parse(" ")
        local keys `keys' `tok'
        gettoken tok : 0, parse(" ")
    }
    if (strtrim("`keys'") == "") {
        di as err "parqit merge: key varlist required"
        exit 198
    }
    syntax using/ [, keep(string) KEEPUSing(string) GENerate(name) NOGENerate ENCoding(string)]
    if ("`generate'" != "" & "`nogenerate'" != "") {
        di as err "parqit merge: generate() and nogenerate are mutually exclusive"
        exit 198
    }
    * keep() is a set of master/using/match: build it from idempotent flags so a
    * repeated token (keep(master master)) cannot flip the mask to another subset
    * the way additive bits did (MERGE-2).
    local m_master 0
    local m_using  0
    local m_match  0
    if ("`keep'" != "") {
        foreach w of local keep {
            if inlist("`w'", "master", "1") local m_master 1
            else if inlist("`w'", "using", "2") local m_using 1
            else if inlist("`w'", "match", "matched", "3") local m_match 1
            else {
                di as err "parqit merge: keep() takes master, using and/or match"
                exit 198
            }
        }
    }
    local mask = `m_master' + 2 * `m_using' + 4 * `m_match'
    _parqit_ensure_plugin
    * a dta/xls/xlsx/csv using side is imported to a small Parquet bridge;
    * encoding() names its legacy code page (BRIDGE-LOSS-1)
    global PARQIT_RS_IN `"`using'"'
    global PARQIT_RS_ENC `"`encoding'"'
    capture noisily _parqit_resolve_source using
    local rc = _rc
    global PARQIT_RS_ENC
    if (`rc') exit `rc'
    local using `"`r(path)'"'
    local bridge `"`r(bridge)'"'
    _parqit_bridge_losses, ext(`"`r(ext_missing)'"') frac(`"`r(frac_dates)'"') ///
        tvars(`"`r(transcoded_vars)'"') tcells("`r(transcoded_cells)'") ///
        tmeta("`r(transcoded_meta)'") enc(`"`r(encoding)'"')
    tempfile req
    local _sq_op "merge"
    local _sq_kind "`kind'"
    local _sq_keys "`keys'"
    local _sq_file `"`using'"'
    local _sq_keepusing `"`keepusing'"'
    local _sq_gen "`generate'"
    local _sq_nogen = ("`nogenerate'" != "")
    local _sq_mask `mask'
    local _sq_owned_n = (`"`bridge'"' != "")
    if (`_sq_owned_n') local _sq_owned_1 `"`bridge'"'
    mata: _parqit_wr_twotable_request("`req'")
    capture noisily plugin call parqit_plugin, view_twotable `reqhex'
    local rc = _rc
    if (`rc') {
        capture _parqit_bridge_discard `"`bridge'"'
        exit `rc'
    }
    _parqit_return_losses, ext(`"`_bl_ext'"') frac(`"`_bl_frac'"') tvars(`"`_bl_tvars'"') ///
        tcells("`_bl_tcells'") tmeta("`_bl_tmeta'") enc(`"`_bl_enc'"')
    return add
    if (`"`bridge'"' != "") return local bridge `"`bridge'"'
end

program define _parqit_append, rclass
    version 16.0
    * parqit append using <file> [<file> ...] [, generate(name)]
    gettoken usingtok 0 : 0, parse(" ")
    if (`"`usingtok'"' != "using") {
        di as err "parqit append: syntax is parqit append using <files> [, generate()]"
        exit 198
    }
    local nf 0
    local parsing 1
    while (`parsing') {
        gettoken f 0 : 0, parse(" ,")
        if (`"`f'"' == "" | `"`f'"' == ",") {
            if (`"`f'"' == ",") local 0 `", `0'"'
            local parsing 0
            continue
        }
        local ++nf
        local _sq_file_`nf' `"`f'"'
    }
    if (`nf' == 0) {
        di as err "parqit append: at least one using file required"
        exit 198
    }
    syntax [, GENerate(name) ENCoding(string)]
    _parqit_ensure_plugin
    * import any dta/xls/xlsx/csv source to a Parquet bridge; encoding() names
    * the legacy code page of every bridged file (BRIDGE-LOSS-1); the losses of
    * all bridges are accumulated into one r() set
    local _sq_owned_n 0
    local _bl_ext ""
    local _bl_frac ""
    local _bl_tvars ""
    local _bl_tcells 0
    local _bl_tmeta 0
    local _bl_enc ""
    forvalues i = 1/`nf' {
        global PARQIT_RS_IN `"`_sq_file_`i''"'
        global PARQIT_RS_ENC `"`encoding'"'
        capture noisily _parqit_resolve_source using
        local rc = _rc
        global PARQIT_RS_ENC
        if (`rc') {
            if (`_sq_owned_n' > 0) {
                forvalues j = 1/`_sq_owned_n' {
                    capture _parqit_bridge_discard `"`_sq_owned_`j''"'
                }
            }
            exit `rc'
        }
        local _sq_file_`i' `"`r(path)'"'
        local bridge `"`r(bridge)'"'
        if (`"`bridge'"' != "") {
            local ++_sq_owned_n
            local _sq_owned_`_sq_owned_n' `"`bridge'"'
            local _one_ext `"`r(ext_missing)'"'
            local _one_frac `"`r(frac_dates)'"'
            local _one_tvars `"`r(transcoded_vars)'"'
            local _bl_ext : list _bl_ext | _one_ext
            local _bl_frac : list _bl_frac | _one_frac
            local _bl_tvars : list _bl_tvars | _one_tvars
            if (r(transcoded_cells) < .) local _bl_tcells = `_bl_tcells' + r(transcoded_cells)
            if (r(transcoded_meta) < .) local _bl_tmeta = `_bl_tmeta' + r(transcoded_meta)
            if (`"`r(encoding)'"' != "") local _bl_enc `"`r(encoding)'"'
        }
    }
    tempfile req
    local _sq_op "append"
    local _sq_nfiles `nf'
    local _sq_gen "`generate'"
    mata: _parqit_wr_append_request("`req'")
    capture noisily plugin call parqit_plugin, view_twotable `reqhex'
    local rc = _rc
    if (`rc') {
        if (`_sq_owned_n' > 0) {
            forvalues j = 1/`_sq_owned_n' {
                capture _parqit_bridge_discard `"`_sq_owned_`j''"'
            }
        }
        exit `rc'
    }
    _parqit_return_losses, ext(`"`_bl_ext'"') frac(`"`_bl_frac'"') tvars(`"`_bl_tvars'"') ///
        tcells("`_bl_tcells'") tmeta("`_bl_tmeta'") enc(`"`_bl_enc'"')
    return add
    return scalar n_bridges = `_sq_owned_n'
    if (`_sq_owned_n' > 0) {
        forvalues j = 1/`_sq_owned_n' {
            return local bridge_`j' `"`_sq_owned_`j''"'
        }
    }
end

program define _parqit_joinby, rclass
    version 16.0
    * parqit joinby keys using <file>
    local keys
    gettoken tok : 0, parse(" ")
    while (`"`tok'"' != "using" & `"`tok'"' != "") {
        gettoken tok 0 : 0, parse(" ")
        local keys `keys' `tok'
        gettoken tok : 0, parse(" ")
    }
    if (strtrim("`keys'") == "") {
        di as err "parqit joinby: key varlist required"
        exit 198
    }
    syntax using/ [, ENCoding(string)]
    _parqit_ensure_plugin
    global PARQIT_RS_IN `"`using'"'
    global PARQIT_RS_ENC `"`encoding'"'
    capture noisily _parqit_resolve_source using
    local rc = _rc
    global PARQIT_RS_ENC
    if (`rc') exit `rc'
    local using `"`r(path)'"'
    local bridge `"`r(bridge)'"'
    _parqit_bridge_losses, ext(`"`r(ext_missing)'"') frac(`"`r(frac_dates)'"') ///
        tvars(`"`r(transcoded_vars)'"') tcells("`r(transcoded_cells)'") ///
        tmeta("`r(transcoded_meta)'") enc(`"`r(encoding)'"')
    tempfile req
    local _sq_op "joinby"
    local _sq_keys "`keys'"
    local _sq_file `"`using'"'
    local _sq_owned_n = (`"`bridge'"' != "")
    if (`_sq_owned_n') local _sq_owned_1 `"`bridge'"'
    mata: _parqit_wr_twotable_request("`req'")
    capture noisily plugin call parqit_plugin, view_twotable `reqhex'
    local rc = _rc
    if (`rc') {
        capture _parqit_bridge_discard `"`bridge'"'
        exit `rc'
    }
    _parqit_return_losses, ext(`"`_bl_ext'"') frac(`"`_bl_frac'"') tvars(`"`_bl_tvars'"') ///
        tcells("`_bl_tcells'") tmeta("`_bl_tmeta'") enc(`"`_bl_enc'"')
    return add
    if (`"`bridge'"' != "") return local bridge `"`bridge'"'
end

* ----------------------------------------------------------------------------
* mergein / appendin — join the IN-MEMORY dataset with a disk file, fast.
*   The in-memory data stays put (no bridge round-trip through DuckDB); parqit
*   reads only the needed columns of the disk side (Parquet/CSV/dta/xlsx, with
*   projection pushdown) into a throwaway frame, then a NATIVE merge/append
*   runs. This is the fast route when the DISK side is the smaller (lookup) one;
*   for big-on-big prefer the out-of-core `parqit use … ; parqit merge` path.
* ----------------------------------------------------------------------------

program define _parqit_mergein, rclass
    version 16.0
    if (c(k) == 0) {
        di as err "parqit mergein: no data in memory (it joins the in-memory "  ///
            "dataset with a disk file; load data first)"
        exit 111
    }
    gettoken mtype 0 : 0, parse(" ")
    if !inlist("`mtype'", "1:1", "m:1", "1:m", "m:m") {
        di as err "parqit mergein: merge type must be 1:1, m:1, 1:m or m:m"
        exit 198
    }
    local keys
    gettoken tok : 0, parse(" ")
    while (`"`tok'"' != "using" & `"`tok'"' != "") {
        gettoken tok 0 : 0, parse(" ")
        local keys `keys' `tok'
        gettoken tok : 0, parse(" ")
    }
    if (strtrim("`keys'") == "") {
        di as err "parqit mergein: key varlist required"
        exit 198
    }
    syntax using/ [, KEEPUSing(string) keep(string) GENerate(name)       ///
        NOGENerate ASSERT(string) UPDATE replace NOLabel NONotes FORCE       ///
        NOREPort]

    * read only keys + keepusing of the disk side (projection pushdown)
    tempname fr
    tempfile tmp
    frame create `fr'
    frame `fr' {
        if ("`keepusing'" != "") qui parqit use `keys' `keepusing' using `"`using'"', clear
        else                     qui parqit use using `"`using'"', clear
        local disk_n = _N
        qui save `"`tmp'"', replace
    }
    frame drop `fr'

    if (`disk_n' >= 1000000) {
        local dstr : di %15.0fc `disk_n'
        _parqit_tip `"the disk side has `=trim("`dstr'")' obs; for a large two-table join it can be faster to do it out of core in parqit ({bf:parqit open _data} ; {bf:parqit merge} {it:...} {bf:using} {it:`using'} ; {bf:parqit collect}) and bring back only the result"'
    }

    * forward every native-merge option that was given
    local opts
    if ("`keepusing'" != "") local opts `opts' keepusing(`keepusing')
    if ("`keep'"      != "") local opts `opts' keep(`keep')
    if ("`generate'"  != "") local opts `opts' generate(`generate')
    if ("`nogenerate'"!= "") local opts `opts' nogenerate
    if (`"`assert'"'  != "") local opts `opts' assert(`assert')
    if ("`update'"    != "") local opts `opts' update
    if ("`replace'"   != "") local opts `opts' replace
    if ("`nolabel'"   != "") local opts `opts' nolabel
    if ("`nonotes'"   != "") local opts `opts' nonotes
    if ("`force'"     != "") local opts `opts' force
    if ("`noreport'"  != "") local opts `opts' noreport
    merge `mtype' `keys' using `"`tmp'"', `opts'
end

program define _parqit_appendin
    version 16.0
    * keep() names variables of the USING file (native append semantics), so it
    * must not be validated against the in-memory master — pass it through as a
    * string and let native append judge it
    syntax using/ [, KEEP(string) FORCE]

    * read only the keep() columns of the disk side (projection pushdown)
    tempname fr
    tempfile tmp
    frame create `fr'
    frame `fr' {
        if ("`keep'" != "") qui parqit use `keep' using `"`using'"', clear
        else                qui parqit use using `"`using'"', clear
        local disk_n = _N
        qui save `"`tmp'"', replace
    }
    frame drop `fr'
    if (`disk_n' >= 1000000) {
        local dstr : di %15.0fc `disk_n'
        _parqit_tip `"appending `=trim("`dstr'")' obs into Stata; for a large append you only need on disk, {bf:parqit use} {it:A} ; {bf:parqit append using} {it:B} ; {bf:parqit save} stays out of core"'
    }
    local opts
    if ("`keep'"  != "") local opts `opts' keep(`keep')
    if ("`force'" != "") local opts `opts' force
    append using `"`tmp'"', `opts'
end

* ----------------------------------------------------------------------------
* M4: reshape, sql/query escape hatches, summaries, path
* ----------------------------------------------------------------------------

program define _parqit_reshape
    version 16.0
    gettoken dir 0 : 0, parse(" ,")
    if !inlist("`dir'", "long", "wide") {
        di as err "parqit reshape: direction must be long or wide"
        exit 198
    }
    * stubs up to the comma
    local stubs
    local parsing 1
    while (`parsing') {
        gettoken tok 0 : 0, parse(" ,")
        if (`"`tok'"' == "" | `"`tok'"' == ",") {
            if (`"`tok'"' == ",") local 0 `", `0'"'
            local parsing 0
            continue
        }
        local stubs `stubs' `tok'
    }
    if (strtrim("`stubs'") == "") {
        di as err "parqit reshape: stub varlist required"
        exit 198
    }
    syntax, i(string) j(name)
    _parqit_ensure_plugin
    tempfile req
    local _sq_dir "`dir'"
    local _sq_stubs "`stubs'"
    local _sq_i `"`i'"'
    local _sq_j "`j'"
    mata: _parqit_wr_reshape_request("`req'")
    capture noisily plugin call parqit_plugin, view_reshape `reqhex'
    if (_rc) exit _rc
end

program define _parqit_sql, rclass
    version 16.0
    * parqit sql "<DuckDB SQL>" [, clear]
    gettoken q 0 : 0, parse(",")
    local q = strtrim(`"`q'"')
    local q `q'
    * A SQL console habit is to end a statement with semicolon.  parqit opens
    * the text as a lazy subquery, where that terminator would sit inside
    * parentheses and make otherwise valid SQL fail.  Remove terminators only
    * from the trimmed tail; semicolons inside SQL strings remain untouched.
    while (`"`q'"' != "" & substr(`"`q'"', strlen(`"`q'"'), 1) == ";") {
        local q = strtrim(substr(`"`q'"', 1, strlen(`"`q'"') - 1))
    }
    if (`"`q'"' == "") {
        di as err `"parqit sql: a quoted SQL query is required"'
        exit 198
    }
    syntax [, clear Name(name)]
    if ("`name'" != "" & "`clear'" != "") {
        di as err "parqit sql: name() applies to lazy views; omit clear"
        exit 198
    }
    if ("`name'" == "") local name "default"
    _parqit_ensure_plugin
    plugin call parqit_plugin, view_alive
    mata: st_local("sql_prev", _parqit_unhex(st_local("parqit_view_current")))
    local sql_target "`name'"
    if ("`clear'" != "") {
        tempname sql_candidate
        local name "`sql_candidate'"
    }
    tempfile req
    local _sq_sql `"`q'"'
    local _sq_vname "`name'"
    mata: _parqit_wr_sql_request("`req'")
    capture noisily plugin call parqit_plugin, view_sql `reqhex'
    if (_rc) exit _rc
    if ("`clear'" != "") {
        * SQL-CANDNAME-1: the collect runs while the CANDIDATE view (a tempname)
        * is current, so its own "view __000000 remains open" line leaked an
        * internal name and contradicted r(view). Quiet the success line only —
        * capture noisily keeps any failure visible — and reprint below with the
        * committed name.
        capture noisily quietly _parqit_collect, clear
        local collect_rc = _rc
        if (`collect_rc') {
            mata: st_local("candhex", _parqit_hex(st_local("name")))
            capture plugin call parqit_plugin, view_close `candhex'
            if ("`sql_prev'" != "") {
                mata: st_local("prevhex", _parqit_hex(st_local("sql_prev")))
                capture plugin call parqit_plugin, view_switch `prevhex'
            }
            exit `collect_rc'
        }
        local sql_n = r(N)
        local sql_k = r(k)
        mata: st_local("candhex", _parqit_hex(st_local("name")))
        mata: st_local("targethex", _parqit_hex(st_local("sql_target")))
        capture noisily plugin call parqit_plugin, view_commit `candhex' `targethex'
        if (_rc) exit _rc
        di as txt "(" as res "`sql_k'" as txt " vars, " as res "`sql_n'" ///
            as txt " obs collected; view " as res "`sql_target'" as txt " remains open)"
        return local view "`sql_target'"
        return add
        exit
    }
    mata: st_local("vname", _parqit_unhex(st_local("parqit_view_name")))
    di as txt "(view " as res "`vname'" as txt " opened over the SQL result: " ///
        as res "`parqit_view_k'" as txt " columns)"
    return scalar k = `parqit_view_k'
    return local view "`vname'"
end

program define _parqit_query
    version 16.0
    gettoken frag 0 : 0, parse(",")
    local frag = strtrim(`"`frag'"')
    local frag `frag'
    if (`"`frag'"' == "") {
        di as err `"parqit query: a quoted SQL fragment is required (e.g. "qualify row_number() over (...) = 1")"'
        exit 198
    }
    _parqit_ensure_plugin
    tempfile req
    local _sq_frag `"`frag'"'
    mata: _parqit_wr_query_request("`req'")
    capture noisily plugin call parqit_plugin, view_query `reqhex'
    if (_rc) exit _rc
end

program define _parqit_summarize, rclass
    version 16.0
    syntax [anything(name=vars)] [, Detail]
    _parqit_ensure_plugin
    tempfile req resp
    local _sq_what = cond("`detail'" != "", "detail", "summarize")
    local _sq_vars `"`vars'"'
    mata: _parqit_wr_stats_request("`req'", "`resp'")
    capture noisily plugin call parqit_plugin, view_stats `reqhex'
    if (_rc) exit _rc
    if ("`detail'" == "") {
        mata: _parqit_print_summarize("`resp'")
        return scalar N    = real("`parqit_sum_n'")
        return scalar sum_w = real("`parqit_sum_n'")
        return scalar mean = real("`parqit_sum_mean'")
        return scalar sd   = real("`parqit_sum_sd'")
        return scalar min  = real("`parqit_sum_min'")
        return scalar max  = real("`parqit_sum_max'")
        return scalar sum  = real("`parqit_sum_sum'")
        return scalar Var  = real("`parqit_sum_var'")
        exit
    }
    mata: _parqit_print_detail("`resp'")
    return scalar N        = real("`parqit_det_n'")
    return scalar sum_w    = real("`parqit_det_n'")
    return scalar sum      = real("`parqit_det_sum'")
    return scalar mean     = real("`parqit_det_mean'")
    return scalar sd       = real("`parqit_det_sd'")
    return scalar Var      = real("`parqit_det_var'")
    return scalar skewness = real("`parqit_det_skew'")
    return scalar kurtosis = real("`parqit_det_kurt'")
    return scalar min      = real("`parqit_det_min'")
    return scalar max      = real("`parqit_det_max'")
    foreach p in 1 5 10 25 50 75 90 95 99 {
        return scalar p`p' = real("`parqit_det_p`p''")
    }
end

program define _parqit_tabulate, rclass
    version 16.0
    syntax anything(name=vars) [, Missing ROW COL NOLabel]
    local nv : word count `vars'
    if (`nv' < 1 | `nv' > 2) {
        di as err "parqit tabulate: one variable (oneway) or two (twoway)"
        exit 198
    }
    * TAB-LABEL-1: value labels are displayed like native tabulate unless
    * nolabel asks for the codes (read by the Mata printers)
    local parqit_tab_nolabel = ("`nolabel'" != "")
    _parqit_ensure_plugin
    tempfile req resp
    local _sq_what = cond(`nv' == 2, "tab2", "tabulate")
    local _sq_vars `"`vars'"'
    local _sq_missing = ("`missing'" != "")
    mata: _parqit_wr_stats_request("`req'", "`resp'")
    capture noisily plugin call parqit_plugin, view_stats `reqhex'
    if (_rc) exit _rc
    if (`nv' == 1) {
        mata: _parqit_print_tabulate("`resp'")
        return scalar N = `parqit_tab_n'
        return scalar r = `parqit_tab_r'
        exit
    }
    local parqit_tab2_row = ("`row'" != "")
    local parqit_tab2_col = ("`col'" != "")
    mata: _parqit_print_tab2("`resp'")
    return scalar N = `parqit_tab_n'
    return scalar r = `parqit_tab_r'
    return scalar c = `parqit_tab_c'
end

program define _parqit_misstable, rclass
    version 16.0
    gettoken maybe : 0, parse(" ,")
    local what "misstable"
    if (`"`maybe'"' == "patterns") {
        gettoken maybe 0 : 0, parse(" ,")
        local what "misspatterns"
    }
    else if (`"`maybe'"' == "summarize") {
        gettoken maybe 0 : 0, parse(" ,")
    }
    syntax [anything(name=vars)]
    _parqit_ensure_plugin
    tempfile req resp
    local _sq_what "`what'"
    local _sq_vars `"`vars'"'
    mata: _parqit_wr_stats_request("`req'", "`resp'")
    capture noisily plugin call parqit_plugin, view_stats `reqhex'
    if (_rc) exit _rc
    if ("`what'" == "misspatterns") {
        mata: _parqit_print_misspatterns("`resp'")
        return scalar r = `parqit_mp_r'
        return scalar N = `parqit_mp_n'
        exit
    }
    mata: _parqit_print_misstable("`resp'")
    return scalar N = `parqit_n'
    return scalar n_complete = `parqit_n_complete'
end

program define _parqit_levelsof, rclass
    version 16.0
    syntax anything(name=var) [, Limit(integer 5000)]
    _parqit_ensure_plugin
    tempfile req resp
    local _sq_what "levelsof"
    local _sq_vars `"`var'"'
    local _sq_limit `limit'
    mata: _parqit_wr_stats_request("`req'", "`resp'")
    capture noisily plugin call parqit_plugin, view_stats `reqhex'
    if (_rc) exit _rc
    mata: _parqit_build_levels("`resp'")
    mata: printf("{txt}%s\n",_parqit_text(st_local("parqit_levels")))
    return local levels `"`parqit_levels'"'
    return scalar r = `parqit_n_levels'
end

program define _parqit_path, rclass
    version 16.0
    syntax anything(name=target id="filename")
    local file `target'
    _parqit_ensure_plugin
    mata: st_local("phex", _parqit_hex(st_local("file")))
    capture noisily plugin call parqit_plugin, path `phex'
    if (_rc) exit _rc
    mata: st_local("pabs", _parqit_unhex(st_local("parqit_path")))
    di as txt `"  `pabs'"' as txt cond("`parqit_path_exists'" == "1", "", "  (does not exist)")
    return local path `"`pabs'"'
    return scalar exists = ("`parqit_path_exists'" == "1")
end

* ----------------------------------------------------------------------------
* Mata: hex codec twin + protocol writers/readers
* ----------------------------------------------------------------------------


version 16.0
mata:
mata set matastrict on

string scalar _parqit_hex(string scalar s)
{
    string scalar    d
    real rowvector   b
    string rowvector h
    real scalar      i, n

    d = "0123456789abcdef"
    n = strlen(s)
    if (n == 0) return("")
    b = ascii(s)
    h = J(1, n, "")
    for (i = 1; i <= n; i++) {
        h[i] = substr(d, floor(b[i] / 16) + 1, 1) + substr(d, mod(b[i], 16) + 1, 1)
    }
    return(invtokens(h, ""))
}

string scalar _parqit_unhex(string scalar x0)
{
    string scalar    d, x
    string rowvector parts
    real scalar      i, n, hi, lo

    d = "0123456789abcdef"
    x = strlower(x0)
    n = strlen(x)
    if (n == 0) return("")
    if (mod(n, 2)) {
        _error(3300, "parqit: malformed hex payload")
    }
    parts = J(1, n / 2, "")
    for (i = 1; i <= n / 2; i++) {
        hi = strpos(d, substr(x, 2 * i - 1, 1)) - 1
        lo = strpos(d, substr(x, 2 * i, 1)) - 1
        if (hi < 0 | lo < 0) {
            _error(3300, "parqit: malformed hex payload")
        }
        parts[i] = char(hi * 16 + lo)
    }
    return(invtokens(parts, ""))
}

// ---- JSON building: every double quote comes from char(34), so no Mata
// ---- compound-literal delimiter ambiguity can ever corrupt a request.

string scalar _parqit_jq(string scalar s)
{
    return(char(34) + s + char(34))
}

string scalar _parqit_jstr(string scalar s)
{
    return(_parqit_jq(_parqit_hex(s)))
}

string scalar _parqit_jpair(string scalar key, string scalar rawjson)
{
    return(_parqit_jq(key) + ":" + rawjson)
}

string scalar _parqit_jtext(string scalar key, string scalar value)
{
    return(_parqit_jpair(key, _parqit_jstr(value)))
}

string scalar _parqit_jlist(string rowvector items)
{
    string scalar out
    real scalar   i

    out = "["
    for (i = 1; i <= cols(items); i++) {
        if (i > 1) out = out + ","
        out = out + _parqit_jstr(items[i])
    }
    return(out + "]")
}

string scalar _parqit_jobj(string rowvector pairs)
{
    string scalar out
    real scalar   i

    out = "{"
    for (i = 1; i <= cols(pairs); i++) {
        if (i > 1) out = out + ","
        out = out + pairs[i]
    }
    return(out + "}")
}

void _parqit_write_file(string scalar path, string scalar content)
{
    real scalar fh

    fh = fopen(path, "w")
    fwrite(fh, content)
    fclose(fh)
}

void _parqit_emit(string scalar req, string scalar payload)
{
    _parqit_write_file(req, payload)
    st_local("reqhex", _parqit_hex(req))
}

// ---- request writers --------------------------------------------------

void _parqit_wr_use_request(string scalar req, string scalar resp,
                             string scalar strl)
{
    string rowvector p
    string scalar    vl

    p = (_parqit_jtext("cmd", "use_prepare"),
         _parqit_jpair("files", "[" + _parqit_jstr(st_local("_sq_file")) + "]"))
    vl = st_local("_sq_namelist")
    if (strtrim(vl) != "") {
        p = (p, _parqit_jpair("varlist", _parqit_jlist(tokens(vl))))
    }
    if (st_local("_sq_relaxed") == "1") {
        p = (p, _parqit_jpair("relaxed", "true"))
    }
    if (st_local("_sq_fmt") == "csv") {
        p = (p, _parqit_jpair("csv", "true"))
    }
    p = (p, _parqit_jtext("respfile", resp),
            _parqit_jtext("strlfile", strl),
            _parqit_jtext("tmpdir", st_global("c(tmpdir)")))
    _parqit_emit(req, _parqit_jobj(p))
}

void _parqit_wr_view_open_request(string scalar req)
{
    string rowvector p
    string scalar    vl

    p = (_parqit_jtext("cmd", "view_open"),
         _parqit_jtext("name", st_local("_sq_vname")),
         _parqit_jpair("files", "[" + _parqit_jstr(st_local("_sq_file")) + "]"))
    vl = st_local("_sq_namelist")
    if (strtrim(vl) != "") {
        p = (p, _parqit_jpair("varlist", _parqit_jlist(tokens(vl))))
    }
    if (st_local("_sq_owned_file") != "") {
        p = (p, _parqit_jpair("owned_files",
                "[" + _parqit_jstr(st_local("_sq_owned_file")) + "]"))
    }
    if (st_local("_sq_relaxed") == "1") {
        p = (p, _parqit_jpair("relaxed", "true"))
    }
    if (st_local("_sq_fmt") == "csv") {
        p = (p, _parqit_jpair("csv", "true"))
    }
    p = (p, _parqit_jtext("tmpdir", st_global("c(tmpdir)")))
    _parqit_emit(req, _parqit_jobj(p))
}

void _parqit_wr_describe_request(string scalar req, string scalar resp)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "describe"),
        _parqit_jpair("files", "[" + _parqit_jstr(st_local("_sq_file")) + "]"),
        _parqit_jtext("respfile", resp),
        _parqit_jtext("tmpdir", st_global("c(tmpdir)")))))
}

void _parqit_wr_collect_request(string scalar req, string scalar resp,
                                 string scalar strl)
{
    string rowvector p

    /* MSG-LABEL-1: collect/head/list share this entry point; the label lets the
     * plugin name the command the user typed in every message. Absent (older
     * caller) means collect, so the wire stays backward-compatible. */
    p = (_parqit_jtext("cmd", "view_collect_prepare"),
         _parqit_jtext("respfile", resp),
         _parqit_jtext("strlfile", strl),
         _parqit_jpair("limit", st_local("_sq_limit")),
         _parqit_jtext("label",
             (st_local("_sq_cmdlabel") != "" ? st_local("_sq_cmdlabel") : "collect")),
         _parqit_jtext("tmpdir", st_global("c(tmpdir)")))
    if (st_local("_sq_pvars") != "") {
        p = (p, _parqit_jpair("vars", _parqit_jlist(tokens(st_local("_sq_pvars")))))
    }
    if (st_local("_sq_pfilter") != "") {
        p = (p, _parqit_jtext("filter", st_local("_sq_pfilter")))
    }
    if (st_local("_sq_pf") != "" & st_local("_sq_pf") != "0") {
        p = (p, _parqit_jpair("f", st_local("_sq_pf")),
                _parqit_jpair("l", st_local("_sq_pl")))
    }
    _parqit_emit(req, _parqit_jobj(p))
}

void _parqit_wr_op_expr_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", st_local("_sq_op")),
        _parqit_jtext("expr", st_local("_sq_expr")))))
}

void _parqit_wr_op_names_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", st_local("_sq_op")),
        _parqit_jpair("names", _parqit_jlist(tokens(st_local("_sq_names")))))))
}

void _parqit_wr_op_keepin_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", st_local("_sq_op") == "drop_in" ? "drop_in" : "keep_in"),
        _parqit_jpair("f", st_local("_sq_f")),
        _parqit_jpair("l", st_local("_sq_l")))))
}

void _parqit_wr_op_rename_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", "rename"),
        _parqit_jtext("old", st_local("_sq_old")),
        _parqit_jtext("new", st_local("_sq_new")))))
}

void _parqit_wr_rename_many(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", "rename_many"),
        _parqit_jpair("old_names", _parqit_jlist(tokens(st_local("_sq_oldlist")))),
        _parqit_jpair("new_names", _parqit_jlist(tokens(st_local("_sq_newlist")))))))
}

void _parqit_wr_op_sample_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", "sample"),
        _parqit_jpair("amount", st_local("_sq_amount")),
        _parqit_jpair("count", st_local("_sq_count")),
        _parqit_jpair("seed", st_local("_sq_seed")))))
}

void _parqit_wr_op_gen_request(string scalar req, string scalar op)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", op),
        _parqit_jtext("name", st_local("_sq_name")),
        _parqit_jtext("type", st_local("_sq_type")),
        _parqit_jtext("expr", st_local("parqit_expr")),
        _parqit_jtext("ifexpr", st_local("parqit_ifexpr")))))
}

void _parqit_wr_op_egen_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", "egen"),
        _parqit_jtext("name", st_local("_sq_name")),
        _parqit_jtext("type", st_local("_sq_type")),
        _parqit_jtext("fcn", st_local("_sq_fcn")),
        _parqit_jtext("expr", st_local("_sq_expr")),
        _parqit_jpair("by", _parqit_jlist(tokens(st_local("_sq_by")))))))
}

void _parqit_wr_op_sort_request(string scalar req)
{
    string rowvector keys, descs
    string scalar    dj
    real scalar      i

    keys = tokens(st_local("_sq_keys"))
    descs = tokens(st_local("_sq_desc"))
    dj = "["
    for (i = 1; i <= cols(keys); i++) {
        if (i > 1) dj = dj + ","
        dj = dj + (i <= cols(descs) & descs[i] == "1" ? "true" : "false")
    }
    dj = dj + "]"
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", "sort"),
        _parqit_jpair("keys", _parqit_jlist(keys)),
        _parqit_jpair("desc", dj))))
}

void _parqit_wr_op_collapse_request(string scalar req)
{
    string rowvector items, parts
    string scalar    sj
    real scalar      i

    items = tokens(st_local("_sq_specs"))
    sj = "["
    for (i = 1; i <= cols(items); i++) {
        parts = _parqit_fields(items[i], 3)
        if (i > 1) sj = sj + ","
        sj = sj + _parqit_jobj((
            _parqit_jtext("stat", parts[1]),
            _parqit_jtext("target", parts[2]),
            _parqit_jtext("source", parts[3])))
    }
    sj = sj + "]"
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", "collapse"),
        _parqit_jpair("specs", sj),
        _parqit_jpair("by", _parqit_jlist(tokens(st_local("_sq_by")))))))
}

void _parqit_wr_pivot_request(string scalar req)
{
    string rowvector items, parts
    string scalar    sj
    real scalar      i

    items = tokens(st_local("_sq_specs"))
    sj = "["
    for (i = 1; i <= cols(items); i++) {
        parts = _parqit_fields(items[i], 3)
        if (i > 1) sj = sj + ","
        sj = sj + _parqit_jobj((
            _parqit_jtext("stat", parts[1]),
            _parqit_jtext("target", parts[2]),
            _parqit_jtext("source", parts[3])))
    }
    sj = sj + "]"
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_pivot"),
        _parqit_jpair("specs", sj),
        _parqit_jpair("rows", _parqit_jlist(tokens(st_local("_sq_rows")))),
        _parqit_jtext("col", st_local("_sq_col")))))
}

void _parqit_wr_op_contract_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", "contract"),
        _parqit_jpair("names", _parqit_jlist(tokens(st_local("_sq_names")))),
        _parqit_jtext("freq", st_local("_sq_freq")))))
}

void _parqit_wr_op_dupdrop_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_op"),
        _parqit_jtext("op", "dupdrop"),
        _parqit_jpair("names", _parqit_jlist(tokens(st_local("_sq_names")))),
        _parqit_jpair("force", st_local("_sq_force") == "1" ? "true" : "false"))))
}

void _parqit_wr_view_save_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_save"),
        _parqit_jtext("dest", st_local("_sq_dest")),
        _parqit_jtext("tmpdir", st_global("c(tmpdir)")),
        _parqit_jpair("replace", st_local("_sq_replace") == "1" ? "true" : "false"),
        _parqit_jtext("compression", strlower(strtrim(st_local("_sq_comp")))),
        _parqit_jpair("compression_level", st_local("_sq_complevel")),
        _parqit_jpair("chunk", st_local("_sq_chunk")),
        _parqit_jtext("encoding", strlower(strtrim(st_local("_sq_encoding")))),
        _parqit_jtext("partition_mode", st_local("_sq_pmode")),
        _parqit_jpair("partition_by", _parqit_jlist(tokens(st_local("_sq_partition")))))))
}

void _parqit_wr_save_request(string scalar req)
{
    string scalar    j, name, src, vlname, ent
    string rowvector partv
    real scalar      i, k, lv, nlab, c
    string colvector labnames, texts, charnames
    real colvector   values

    k = st_nvar()
    j = "{" + _parqit_jtext("cmd", "save_data")
    j = j + "," + _parqit_jtext("dest", st_local("_sq_dest"))
    j = j + "," + _parqit_jtext("tmpdir", st_global("c(tmpdir)"))
    j = j + "," + _parqit_jtext("dtalabel", st_local("_sq_dtalabel"))
    j = j + "," + _parqit_jpair("sortedby",
                              _parqit_jlist(tokens(st_local("_sq_sortedby"))))
    j = j + "," + _parqit_jpair("replace",
                              st_local("_sq_replace") == "1" ? "true" : "false")
    j = j + "," + _parqit_jtext("compression",
                              strlower(strtrim(st_local("_sq_comp"))))
    j = j + "," + _parqit_jpair("compression_level", st_local("_sq_complevel"))
    j = j + "," + _parqit_jpair("chunk", st_local("_sq_chunk"))
    j = j + "," + _parqit_jtext("encoding",
                              strlower(strtrim(st_local("_sq_encoding"))))
    if (st_local("_sq_direct") == "1") {
        j = j + "," + _parqit_jtext("source_file", st_local("_sq_source"))
        j = j + "," + _parqit_jtext("source_size", st_local("_sq_source_size"))
        j = j + "," + _parqit_jtext("source_mtime", st_local("_sq_source_mtime"))
        j = j + "," + _parqit_jtext("source_ctime", st_local("_sq_source_ctime"))
        j = j + "," + _parqit_jtext("source_inode", st_local("_sq_source_inode"))
        j = j + "," + _parqit_jtext("source_footer", st_local("_sq_source_footer"))
        j = j + "," + _parqit_jpair("nobs", st_local("_sq_nobs"))
    }
    partv = (strtrim(st_local("_sq_partition")) == "" ? J(1, 0, "")
             : tokens(st_local("_sq_partition")))
    j = j + "," + _parqit_jpair("partition_by", _parqit_jlist(partv))
    j = j + "," + _parqit_jtext("partition_mode", st_local("_sq_pmode"))

    j = j + "," + _parqit_jq("vars") + ":["
    labnames = J(0, 1, "")
    for (i = 1; i <= k; i++) {
        if (i > 1) j = j + ","
        name = st_varname(i)
        src = st_global(name + "[src_name]")
        if (src == "") src = name
        vlname = st_varvaluelabel(i)
        if (vlname != "") labnames = labnames \ vlname
        j = j + _parqit_jobj((
            _parqit_jtext("name", name),
            _parqit_jtext("source", src),
            _parqit_jtext("type", st_vartype(i)),
            _parqit_jtext("fmt", st_varformat(i)),
            _parqit_jtext("varlab", st_varlabel(i)),
            _parqit_jtext("vallab", vlname)))
    }
    j = j + "]"

    /* VALLAB-ALL-1 (audit 2026-08-22, A1-10/A2-11): native save keeps every
     * value label defined in the dataset, attached to a variable or not
     * (`label define` orphans); serialise them all, not only the attached ones
     * (the ado passes `label dir` in _sq_vallabs_all) */
    labnames = uniqrows(labnames \ tokens(st_local("_sq_vallabs_all"))')
    j = j + "," + _parqit_jq("vallabs") + ":["
    nlab = 0
    for (lv = 1; lv <= rows(labnames); lv++) {
        if (labnames[lv] == "" | !st_vlexists(labnames[lv])) continue
        st_vlload(labnames[lv], values, texts)
        if (nlab++ > 0) j = j + ","
        j = j + "{" + _parqit_jtext("name", labnames[lv]) + ","
        j = j + _parqit_jq("entries") + ":["
        for (i = 1; i <= rows(values); i++) {
            if (i > 1) j = j + ","
            ent = strtrim(strofreal(values[i], "%21.0g"))
            j = j + "[" + _parqit_jq(ent) + "," + _parqit_jstr(texts[i]) + "]"
        }
        j = j + "]}"
    }
    j = j + "]"

    j = j + "," + _parqit_jq("chars") + ":["
    nlab = 0
    charnames = st_dir("char", "_dta", "*")
    for (c = 1; c <= rows(charnames); c++) {
        if (charnames[c] == "_parqit_fast_source_nonce") continue
        if (nlab++ > 0) j = j + ","
        j = j + "[" + _parqit_jstr("_dta") + "," + _parqit_jstr(charnames[c]) + ","
        j = j + _parqit_jstr(st_global("_dta[" + charnames[c] + "]")) + "]"
    }
    for (i = 1; i <= k; i++) {
        name = st_varname(i)
        charnames = st_dir("char", name, "*")
        for (c = 1; c <= rows(charnames); c++) {
            if (nlab++ > 0) j = j + ","
            j = j + "[" + _parqit_jstr(name) + "," + _parqit_jstr(charnames[c]) + ","
            j = j + _parqit_jstr(st_global(name + "[" + charnames[c] + "]")) + "]"
        }
    }
    j = j + "]}"

    _parqit_emit(req, j)
}

// split "expr [if cond]" at the first top-level bare `if'
void _parqit_split_if(string scalar src)
{
    real scalar      i, n, depth, instr
    string scalar    c, q

    n = strlen(src)
    depth = 0
    instr = 0
    q = ""
    for (i = 1; i <= n; i++) {
        c = substr(src, i, 1)
        if (instr) {
            if (c == q) instr = 0
            continue
        }
        if (c == char(34)) {
            instr = 1
            q = char(34)
            continue
        }
        if (c == "(") depth++
        else if (c == ")") depth--
        else if (depth == 0 & c == "i" & substr(src, i, 3) == "if ") {
            if (i == 1 | substr(src, i - 1, 1) == " ") {
                st_local("parqit_expr", strtrim(substr(src, 1, i - 1)))
                st_local("parqit_ifexpr", strtrim(substr(src, i + 3, .)))
                return
            }
        }
    }
    st_local("parqit_expr", strtrim(src))
    st_local("parqit_ifexpr", "")
}

string rowvector _parqit_fields(string scalar line, real scalar n)
{
    string rowvector t, out
    real scalar      i

    t = ustrsplit(line, "\|")
    out = J(1, n, "")
    for (i = 1; i <= min((n, cols(t))); i++) out[i] = t[i]
    return(out)
}

/* Stream complete hex records, including those above fget's 32 KiB limit. */
string matrix _parqit_fget(real scalar fh)
{
    string matrix line, chunk
    line = fgetnl(fh)
    if (line == J(0,0,"")) return(line)
    while (substr(line,strlen(line),1) != char(10)) {
        chunk = fgetnl(fh)
        if (chunk == J(0,0,"")) return(line)
        line = line + chunk
    }
    line = substr(line,1,strlen(line)-1)
    if (substr(line,strlen(line),1) == char(13))
        line = substr(line,1,strlen(line)-1)
    return(line)
}

/* Read the whole response file and split into records on the newline. Mata's
 * fget() caps a line at 32768 bytes and continues the remainder as a bogus
 * record, which truncates/corrupts a long hex field (a 32000-byte value label,
 * a long note/characteristic) — META-1. fread()+split has no line-length limit;
 * a hex/ASCII record never contains a newline, so the split is exact. */
string colvector _parqit_resp_lines(string scalar resp)
{
    real scalar      fh
    string scalar    buf, chunk
    string colvector all

    fh = fopen(resp, "r")
    buf = ""
    while ((chunk = fread(fh, 1048576)) != J(0, 0, "")) buf = buf + chunk
    fclose(fh)
    if (buf == "") return(J(0, 1, ""))
    all = ustrsplit(buf, char(10))'
    /* META-D: select() is O(n). The prior `out = out \ all[i]` grew the whole
     * vector per line — O(n^2), so a large parqit.vallabs (a legitimate 30k+
     * geographic crosswalk, or a hostile 1M-entry label) hung the load. */
    return(select(all, all :!= ""))
}

void _parqit_resp_create(string scalar resp, real scalar n)
{
    real scalar      idx, _li, _nl
    string scalar    line, name, code, fmt
    string rowvector f
    string colvector _lines

    /* fread()+split, not fget(): a >32768-byte record (e.g. a long hex source
     * name) would be split by fget's line cap and abort the load — META-1 */
    _lines = _parqit_resp_lines(resp)
    _nl = rows(_lines)
    for (_li = 1; _li <= _nl; _li++) {
        line = _lines[_li]
        f = _parqit_fields(line, 8)
        if (f[1] != "var") continue
        name = _parqit_unhex(f[3])
        code = _parqit_unhex(f[5])
        idx = st_addvar(code, name)
        fmt = _parqit_unhex(f[6])
        /* META-A: a corrupt/foreign parqit.schema can carry a display format
         * Stata rejects (a string %fmt on a numeric, an absurd width). Bare
         * st_varformat aborts rc 3300 and would throw away the good DATA and
         * every other valid metadatum; apply through a capture so a bad format
         * is warned-and-skipped, matching the value-label/char/dtalabel guards.
         * A legitimate format carries no command metacharacters, so reject any
         * that does — which also blocks injection through the _stata call. */
        if (fmt != "") {
            if (strpos(fmt, char(96)) | strpos(fmt, char(39)) |
                strpos(fmt, char(34)) | strpos(fmt, char(36)) |
                strpos(fmt, char(0)) | strpos(fmt, char(10)) |
                strpos(fmt, char(13)))
                printf("note: %s: skipping malformed display format\n", name)
            else if (_stata("format " + name + " " + fmt, 1))
                printf("note: %s: skipping display format %s (not accepted by Stata)\n",
                       name, fmt)
        }
    }
    if (n > 0) st_addobs(n)
}

void _parqit_apply_strl(string scalar path)
{
    real scalar   fh, v, o, len, pos, have, eof
    string scalar buf, chunk

    if (!fileexists(path)) return
    fh = fopen(path, "r")
    /* fixed 35-byte header: var(10) + obs(13) + len(12) — must match the
     * writer in plugin_io.cpp fill_column. PERF-STRL-1: parse from 8 MiB
     * gulps instead of TWO fread() calls per cell — the per-record syscall
     * pair dominated text-heavy reads (a 200k-cell strL column spent ~4.5x
     * the equivalent str# fill here). Record format unchanged. */
    buf = ""
    pos = 1
    eof = 0
    while (1) {
        have = strlen(buf) - pos + 1
        if (have < 35 & !eof) {
            chunk = fread(fh, 8388608)
            if (chunk == J(0, 0, "")) eof = 1
            else {
                buf = substr(buf, pos, .) + chunk
                pos = 1
            }
            continue
        }
        if (have < 35) break
        v   = strtoreal(substr(buf, pos, 10))
        o   = strtoreal(substr(buf, pos + 10, 13))
        len = strtoreal(substr(buf, pos + 23, 12))
        if (have < 35 + len) {
            if (eof) break
            chunk = fread(fh, max((8388608, len)))
            if (chunk == J(0, 0, "")) eof = 1
            else {
                buf = substr(buf, pos, .) + chunk
                pos = 1
            }
            continue
        }
        st_sstore(o, v, len > 0 ? substr(buf, pos + 35, len) : "")
        pos = pos + 35 + len
    }
    fclose(fh)
}

void _parqit_resp_decorate(string scalar resp)
{
    real scalar      nv, i, v, _li, _nl, vlk
    string scalar    line, name, varlab, vallab, labname, txt, tgt, cname, vraw
    string rowvector f
    string colvector vl_names, vl_texts_all, vl_owner, _lines
    real colvector   vl_vals_all, sel

    _lines = _parqit_resp_lines(resp)
    _nl = rows(_lines)
    /* META-D: preallocate to the line-count upper bound and index-assign; the
     * prior `vl_owner = vl_owner \ labname` per accepted entry was O(n^2). */
    vl_owner = J(_nl, 1, "")
    vl_vals_all = J(_nl, 1, .)
    vl_texts_all = J(_nl, 1, "")
    vlk = 0
    for (_li = 1; _li <= _nl; _li++) {
        line = _lines[_li]
        f = _parqit_fields(line, 8)
        if (f[1] == "var") {
            name = _parqit_unhex(f[3])
            varlab = _parqit_unhex(f[7])
            vallab = _parqit_unhex(f[8])
            if (varlab != "") st_varlabel(name, varlab)
            /* a foreign value-label NAME that is not a legal Stata name would
             * abort st_varvaluelabel — warn and skip, never fail the load */
            if (vallab != "" & st_isnumvar(name)) {
                if (st_isname(vallab)) st_varvaluelabel(name, vallab)
                else printf("note: %s: skipping value label with invalid name %s\n",
                            name, vallab)
            }
            if (_parqit_unhex(f[4]) != name) {
                st_global(name + "[src_name]", _parqit_unhex(f[4]))
            }
        }
        else if (f[1] == "vlab") {
            labname = _parqit_unhex(f[3])
            vraw = _parqit_unhex(f[2])
            v = strtoreal(vraw)
            txt = _parqit_unhex(f[4])
            /* Stata value-label keys must be integers and the label a legal
             * name; a foreign/corrupt file can carry neither. Skip loudly so a
             * non-integer key (1.5, "abc") can never silently overwrite a real
             * key or abort the load. */
            if (!st_isname(labname))
                printf("note: skipping value label with invalid name %s\n", labname)
            else if (v == . & strtrim(vraw) != ".")
                /* META-C: a non-numeric key ("abc", "") strtoreal's to plain
                 * missing and used to fall through the finite-only guard
                 * below, adding a spurious `.`-keyed entry to the label
                 * (colliding last-wins across several bad keys). Reject only
                 * a FAILED parse: a literal "." and the extended missings
                 * ".a"-".z" are legitimate label keys whose labels survive
                 * the round-trip (v07/t01 pin exactly that) and stay accepted. */
                printf("note: value label %s: skipping non-numeric key %s\n",
                       labname, vraw)
            else if (v < . & (v != trunc(v) | abs(v) >= 2147483648))
                printf("note: value label %s: skipping non-integer/out-of-range key %s\n", labname, vraw)
            else {
                /* Stata caps value-label text at 32,000 characters; an
                 * oversized text from a crafted parqit.vallabs footer would
                 * abort st_vlmodify and kill the whole load — truncate and
                 * warn instead, matching the warn-and-continue charter of the
                 * name/key guards above (and DTALABEL-LEN-1). */
                if (strlen(txt) > 32000) {
                    printf("note: value label %s: text for key %s truncated to 32,000 bytes\n",
                           labname, vraw)
                    txt = substr(txt, 1, 32000)
                }
                vlk++
                vl_owner[vlk] = labname
                vl_vals_all[vlk] = v
                vl_texts_all[vlk] = txt
            }
        }
        else if (f[1] == "char") {
            tgt = _parqit_unhex(f[2])
            cname = _parqit_unhex(f[3])
            /* a char whose target/name is not a legal Stata name would abort
             * st_global; warn and skip the characteristic instead */
            if (!st_isname(cname) | !(tgt == "_dta" | st_isname(tgt)))
                printf("note: skipping characteristic %s[%s] (invalid name)\n",
                       tgt, cname)
            /* PARQIT-CHAR-01: a projection (subset use / contract / collapse /
             * keep / drop / reshape …) can remove the variable that carried the
             * char or note (notes are chars). Applying st_global to an absent
             * variable aborts with rc 3300 and kills an otherwise-good load, so
             * apply only to _dta or a variable that survives in the staged
             * result. Use _st_varindex (returns . for an absent name) — the
             * underscore-less st_varindex ABORTS rc 3500 on an absent name, so
             * it cannot be the guard; and _st_varindex("_dta") is ., so the
             * _dta branch must stay explicit. _st_varindex is reached only for
             * a legal tgt (the invalid-name branch above already returned). */
            else if (tgt == "_dta" | _st_varindex(tgt) < .) {
                /* CHAR-LEN-1 (audit 2026-08-22, A2-7): Stata stores at most
                 * 67,783 bytes in a characteristic (st_global silently stores
                 * NOTHING beyond that, rc 0) — a foreign char, or a legacy note
                 * that grew under transcoding, vanished silently. Truncate and
                 * say so, like the 32,000-byte value-label text guard. */
                txt = _parqit_unhex(f[4])
                if (strlen(txt) > 67783) {
                    printf("note: characteristic %s[%s] holds %g bytes; Stata keeps at most 67,783 — truncated (the file keeps the full text)\n",
                           tgt, cname, strlen(txt))
                    txt = substr(txt, 1, 67783)
                }
                st_global(tgt + "[" + cname + "]", txt)
            }
            else
                printf("note: dropping characteristic %s[%s] (variable not in result)\n",
                       tgt, cname)
        }
        else if (f[1] == "dlabel") {
            st_local("parqit_dtalabel", f[2])
        }
        else if (f[1] == "sortedby") {
            st_local("parqit_sortedby", f[2])
        }
        else if (f[1] == "drop") {
            displayas("error")
            printf("warning: column %s dropped: %s\n",
                   _parqit_unhex(f[2]), _parqit_unhex(f[3]))
        }
        else if (f[1] == "warn") {
            displayas("text")
            printf("note: %s\n", _parqit_unhex(f[2]))
        }
    }
    if (vlk > 0) {
        vl_owner = vl_owner[|1 \ vlk|]
        vl_vals_all = vl_vals_all[|1 \ vlk|]
        vl_texts_all = vl_texts_all[|1 \ vlk|]
        vl_names = uniqrows(vl_owner)
        nv = rows(vl_names)
        for (i = 1; i <= nv; i++) {
            sel = selectindex(vl_owner :== vl_names[i])
            st_vlmodify(vl_names[i], vl_vals_all[sel], vl_texts_all[sel])
        }
    }
}

void _parqit_resp_describe(string scalar resp)
{
    real scalar      i, k, _li, _nl
    real colvector   sel
    string scalar    line, dt
    string rowvector f
    string colvector dnames, dtypes, snames, stypes, sfmts, _lines

    /* fread()+split, not fget(): a >32768-byte record (e.g. a long hex source
     * name) would be split by fget's line cap and abort the load — META-1 */
    _lines = _parqit_resp_lines(resp)
    _nl = rows(_lines)
    dnames = dtypes = snames = stypes = sfmts = J(0, 1, "")
    for (_li = 1; _li <= _nl; _li++) {
        line = _lines[_li]
        f = _parqit_fields(line, 8)
        if (f[1] == "dtype") {
            dnames = dnames \ _parqit_unhex(f[2])
            dtypes = dtypes \ _parqit_unhex(f[3])
        }
        else if (f[1] == "var") {
            snames = snames \ _parqit_unhex(f[3])
            stypes = stypes \ _parqit_unhex(f[5])
            sfmts  = sfmts  \ _parqit_unhex(f[6])
        }
        else if (f[1] == "drop") {
            displayas("error")
            printf("  (column %s not loadable: %s)\n",
                   _parqit_unhex(f[2]), _parqit_unhex(f[3]))
        }
    }

    displayas("text")
    printf("  %-32s %-18s %-10s %s\n", "variable", "parquet type", "stata type", "format")
    printf("  %s\n", 72 * "-")
    k = rows(snames)
    for (i = 1; i <= k; i++) {
        /* DESCRIBE-ALIGN-1 (audit 2026-09-01, F3): the engine type is looked
         * up by the variable's NAME (the dtype records now carry the Stata
         * name, in the var records' manifest order); a positional fallback
         * only when the name is absent. The old positional zip shifted every
         * type after a Hive partition key, which the scan lists last while the
         * manifest keeps it in its original place. */
        sel = selectindex(dnames :== snames[i])
        dt = (rows(sel) >= 1 ? dtypes[sel[1]] : (i <= rows(dtypes) ? dtypes[i] : ""))
        printf("  %-32s %-18s %-10s %s\n", snames[i], dt, stypes[i], sfmts[i])
        st_local("parqit_dname_" + strofreal(i), snames[i])
        st_local("parqit_dtype_" + strofreal(i), dt)
        st_local("parqit_dstype_" + strofreal(i), stypes[i])
    }
    printf("\n")
}

void _parqit_print_resp(string scalar resp, string scalar kind)
{
    real scalar      _li, _nl
    string scalar    line
    string rowvector f
    string colvector _lines

    _lines = _parqit_resp_lines(resp)
    _nl = rows(_lines)
    displayas("text")
    for (_li = 1; _li <= _nl; _li++) {
        line = _lines[_li]
        f = _parqit_fields(line, 3)
        if (f[1] == kind & kind == "sql") {
            printf("%s\n", _parqit_unhex(f[2]))
        }
        else if (f[1] == kind) {
            printf("%s\n%s\n", _parqit_unhex(f[2]), _parqit_unhex(f[3]))
        }
    }
}

void _parqit_print_view_describe(string scalar resp)
{
    real scalar      fh
    string scalar    line, kind
    string rowvector f

    fh = fopen(resp, "r")
    displayas("text")
    printf("  %-32s %-8s %-12s %s\n", "variable", "kind", "format", "label")
    printf("  %s\n", 72 * "-")
    while ((line = _parqit_fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 7)
        if (f[1] != "vcol") continue
        kind = (_parqit_unhex(f[4]) == "s" ? "string" : "numeric")
        printf("  %-32s %-8s %-12s %s\n", _parqit_text(_parqit_unhex(f[3])), kind,
               _parqit_text(_parqit_unhex(f[5])), _parqit_text(_parqit_unhex(f[6])))
        if (f[7] != "") {
            /* NAME-CASE-1: alias inside the view; exact Stata name on collect/save */
            printf("  %-32s (Stata name %s: differs only by case from another variable)\n",
                   "", _parqit_text(_parqit_unhex(f[7])))
        }
    }
    fclose(fh)
    printf("\n")
}
end

version 16.0
mata:

void _parqit_wr_twotable_request(string scalar req)
{
    real scalar      i, nf
    string scalar    owned
    string rowvector p

    p = (_parqit_jtext("cmd", "view_twotable"),
         _parqit_jtext("op", st_local("_sq_op")),
         _parqit_jpair("files", "[" + _parqit_jstr(st_local("_sq_file")) + "]"),
         _parqit_jpair("keys", _parqit_jlist(tokens(st_local("_sq_keys")))),
         _parqit_jtext("tmpdir", st_global("c(tmpdir)")))
    nf = strtoreal(st_local("_sq_owned_n"))
    if (missing(nf)) nf = 0
    if (nf > 0) {
        owned = "["
        for (i = 1; i <= nf; i++) {
            if (i > 1) owned = owned + ","
            owned = owned + _parqit_jstr(st_local("_sq_owned_" + strofreal(i)))
        }
        p = (p, _parqit_jpair("owned_files", owned + "]"))
    }
    if (st_local("_sq_op") == "merge") {
        p = (p, _parqit_jtext("kind", st_local("_sq_kind")),
                _parqit_jpair("keepusing",
                            _parqit_jlist(tokens(st_local("_sq_keepusing")))),
                _parqit_jtext("gen", st_local("_sq_gen")),
                _parqit_jpair("nogen",
                            st_local("_sq_nogen") == "1" ? "true" : "false"),
                _parqit_jpair("keep_mask", st_local("_sq_mask")))
    }
    _parqit_emit(req, _parqit_jobj(p))
}

void _parqit_wr_append_request(string scalar req)
{
    real scalar      i, nf, no
    string scalar    flist, owned
    string rowvector p

    nf = strtoreal(st_local("_sq_nfiles"))
    flist = "["
    for (i = 1; i <= nf; i++) {
        if (i > 1) flist = flist + ","
        flist = flist + _parqit_jstr(st_local("_sq_file_" + strofreal(i)))
    }
    flist = flist + "]"
    p = (
        _parqit_jtext("cmd", "view_twotable"),
        _parqit_jtext("op", "append"),
        _parqit_jpair("files", flist),
        _parqit_jpair("keys", "[]"),
        _parqit_jtext("gen", st_local("_sq_gen")),
        _parqit_jtext("tmpdir", st_global("c(tmpdir)")))
    no = strtoreal(st_local("_sq_owned_n"))
    if (missing(no)) no = 0
    if (no > 0) {
        owned = "["
        for (i = 1; i <= no; i++) {
            if (i > 1) owned = owned + ","
            owned = owned + _parqit_jstr(st_local("_sq_owned_" + strofreal(i)))
        }
        p = (p, _parqit_jpair("owned_files", owned + "]"))
    }
    _parqit_emit(req, _parqit_jobj(p))
}
end

version 16.0
mata:

void _parqit_wr_reshape_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_reshape"),
        _parqit_jtext("dir", st_local("_sq_dir")),
        _parqit_jpair("stubs", _parqit_jlist(tokens(st_local("_sq_stubs")))),
        _parqit_jpair("i", _parqit_jlist(tokens(st_local("_sq_i")))),
        _parqit_jtext("j", st_local("_sq_j")))))
}

void _parqit_wr_sql_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_sql"),
        _parqit_jtext("name", st_local("_sq_vname")),
        _parqit_jtext("sql", st_local("_sq_sql")),
        _parqit_jtext("tmpdir", st_global("c(tmpdir)")))))
}

void _parqit_wr_query_request(string scalar req)
{
    _parqit_emit(req, _parqit_jobj((
        _parqit_jtext("cmd", "view_query"),
        _parqit_jtext("fragment", st_local("_sq_frag")))))
}

void _parqit_wr_stats_request(string scalar req, string scalar resp)
{
    string rowvector p

    p = (_parqit_jtext("cmd", "view_stats"),
         _parqit_jtext("what", st_local("_sq_what")),
         _parqit_jpair("vars", _parqit_jlist(tokens(st_local("_sq_vars")))),
         _parqit_jtext("respfile", resp))
    if (st_local("_sq_limit") != "") {
        p = (p, _parqit_jpair("limit", st_local("_sq_limit")))
    }
    if (st_local("_sq_expr") != "") {
        p = (p, _parqit_jtext("expr", st_local("_sq_expr")))
    }
    if (st_local("_sq_joint") == "1") {
        p = (p, _parqit_jpair("joint", "true"))
    }
    if (st_local("_sq_pairwise") != "") {
        p = (p, _parqit_jpair("pairwise", st_local("_sq_pairwise")))
    }
    if (st_local("_sq_missing") == "1") {
        p = (p, _parqit_jpair("missing", "true"))
    }
    if (st_local("_sq_stats") != "") {
        p = (p, _parqit_jpair("stats", _parqit_jlist(tokens(st_local("_sq_stats")))))
    }
    if (st_local("_sq_by") != "") {
        p = (p, _parqit_jtext("by", st_local("_sq_by")))
    }
    if (st_local("_sq_bins") != "" & st_local("_sq_bins") != "0") {
        p = (p, _parqit_jpair("bins", st_local("_sq_bins")))
    }
    _parqit_emit(req, _parqit_jobj(p))
}

string scalar _parqit_controls(string scalar src)
{
    string scalar s
    s = src
    s = subinstr(s,char(0),"\0")
    s = subinstr(s,char(10),"\n")
    s = subinstr(s,char(13),"\r")
    return(subinstr(s,char(31),"\x1f"))
}

string scalar _parqit_text(string scalar src)
{
    real scalar i
    string scalar out, c, s
    s = _parqit_controls(src)
    out = ""
    for (i = 1; i <= strlen(s); i++) {
        c = substr(s, i, 1)
        out = out + (c == "{" ? "{c -(}" : (c == "}" ? "{c )-}" : c))
    }
    return(out)
}

string scalar _parqit_num(string scalar s, string scalar fmt)
{
    return(strofreal(strtoreal(s), fmt))
}

string scalar _parqit_rtext(string scalar src, real scalar width)
{
    string scalar s
    s = _parqit_controls(src)
    return(max((0,width-udstrlen(s))) * " " + _parqit_text(s))
}

string scalar _parqit_clip(string scalar src, real scalar width)
{
    string scalar s
    s = src
    if (udstrlen(s)>width) s = udsubstr(s,1,width-1)+"~"
    s = _parqit_controls(s)
    if (udstrlen(s)<=width) return(s)
    return(udsubstr(s,1,width-1)+"~")
}

transmorphic scalar _parqit_statsmeta(string scalar resp)
{
    real scalar fh
    string scalar line
    string rowvector f
    transmorphic scalar out
    out = asarray_create("string", 1)
    fh = fopen(resp, "r")
    while ((line = _parqit_fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 7)
        if (f[1] != "smeta") continue
        asarray(out, _parqit_unhex(f[3]),
                (_parqit_unhex(f[4]), _parqit_unhex(f[5]),
                 _parqit_unhex(f[6]), f[2], _parqit_unhex(f[7])))
    }
    fclose(fh)
    return(out)
}

string rowvector _parqit_statmeta(transmorphic scalar metadata, string scalar name)
{
    if (asarray_contains(metadata, name)) return(asarray(metadata, name))
    return((name, "", "", "n", ""))
}

void _parqit_print_summarize(string scalar resp)
{
    real scalar      fh, i
    string scalar    line
    string rowvector f, meta
    transmorphic scalar metadata

    metadata = _parqit_statsmeta(resp)
    fh = fopen(resp, "r")
    displayas("text")
    printf("\n    Variable {c |}        Obs        Mean    Std. dev.       Min        Max\n")
    printf("{hline 13}{c +}{hline 57}\n")
    i = 0
    while ((line = fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 7)
        if (f[1] == "sumextra") {
            st_local("parqit_sum_sum", f[2])
            st_local("parqit_sum_var", f[3])
            continue
        }
        if (f[1] != "stat") continue
        if (i > 0 & mod(i, 5) == 0) printf("\n")
        meta = _parqit_statmeta(metadata, _parqit_unhex(f[7]))
        printf("{txt}%s {c |} {res}%10s   %9s   %9s  %9s  %9s\n",
               _parqit_rtext(abbrev(meta[1], 12),12),
               _parqit_num(f[2], "%10.0gc"),
               _parqit_num(f[3], "%9.0g"), _parqit_num(f[4], "%9.0g"),
               _parqit_num(f[5], "%9.0g"), _parqit_num(f[6], "%9.0g"))
        i++
        st_local("parqit_sum_n", f[2] == "." ? "0" : f[2])
        st_local("parqit_sum_mean", f[3])
        st_local("parqit_sum_sd", f[4])
        st_local("parqit_sum_min", f[5])
        st_local("parqit_sum_max", f[6])
    }
    fclose(fh)
    if (st_local("parqit_sum_n") == "") st_local("parqit_sum_n", "0")
    if (st_local("parqit_sum_mean") == "") st_local("parqit_sum_mean", ".")
    if (st_local("parqit_sum_sd") == "") st_local("parqit_sum_sd", ".")
    if (st_local("parqit_sum_min") == "") st_local("parqit_sum_min", ".")
    if (st_local("parqit_sum_max") == "") st_local("parqit_sum_max", ".")
}

/* RENDER-NATIVE-1 (audit 2026-08-22, A3-6): render a numeric level the way
 * native tabulate does — with the variable's display format (%9.0g when it has
 * none), so 0.30000000000000004 prints as .3 and 1e-07 as 1.00e-07. A missing
 * ("." or unparsable text) and every string level are left as they are. */
string scalar _parqit_render_num(string scalar raw, string scalar fmt)
{
    real scalar   v
    string scalar out

    v = strtoreal(raw)
    if (v == . & strtrim(raw) != ".") return(raw)
    if (v == .) return(".")
    out = strtrim(strofreal(v, fmt == "" ? "%9.0g" : fmt))
    return(out == "" ? raw : out)
}

/* TAB-LABEL-1 (audit 2026-09-01, F12): the value-label text of a numeric
 * level (its engine text form), or "" when the level carries no label; keys
 * compare numerically so 1 and 1.0 both find the entry for 1. */
string scalar _parqit_vlabel(string scalar raw, string colvector keys,
                             string colvector texts)
{
    real scalar v, i

    if (rows(keys) == 0) return("")
    v = strtoreal(raw)
    if (v == .) return("")
    for (i = 1; i <= rows(keys); i++) {
        if (strtoreal(keys[i]) == v) return(texts[i])
    }
    return("")
}

void _parqit_print_tabulate(string scalar resp)
{
    real scalar      fh, total, rows, n, i, uselab, stub
    string scalar    line, kind, fmt, raw, lab, title
    string rowvector f, vars, meta
    string colvector vals, lkeys, ltexts
    real colvector   counts
    transmorphic scalar metadata

    metadata = _parqit_statsmeta(resp)
    fh = fopen(resp, "r")
    vals = J(0, 1, "")
    counts = J(0, 1, .)
    lkeys = ltexts = J(0, 1, "")
    uselab = (st_local("parqit_tab_nolabel") != "1")
    kind = "n"
    fmt = ""
    while ((line = _parqit_fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 3)
        if (f[1] == "tabh") {
            kind = f[2]
            fmt = _parqit_unhex(f[3])
            continue
        }
        if (f[1] == "tvl") {
            lkeys = lkeys \ _parqit_unhex(f[2])
            ltexts = ltexts \ _parqit_unhex(f[3])
            continue
        }
        if (f[1] != "tab") continue
        counts = counts \ strtoreal(f[2])
        raw = _parqit_unhex(f[3])
        /* a labelled numeric level shows its label, like native tabulate */
        lab = (kind == "n" & uselab) ? _parqit_vlabel(raw, lkeys, ltexts) : ""
        vals = vals \ (lab != "" ? lab
                                 : (kind == "n" ? _parqit_render_num(raw, fmt) : raw))
    }
    fclose(fh)
    total = sum(counts)
    rows = rows(vals)
    st_local("parqit_tab_n", strofreal(total, "%21.0g"))
    st_local("parqit_tab_r", strofreal(rows, "%21.0g"))
    displayas("text")
    if (rows==0) {
        printf("no observations\n")
        return
    }
    vars = tokens(st_local("_sq_vars"))
    meta = _parqit_statmeta(metadata,vars[1])
    title = meta[2]=="" ? meta[1] : meta[2]
    stub = max((11,min((40,st_numscalar("c(linesize)")-37,
                max((udstrlen(title),max(udstrlen(vals))))+1))))
    if (meta[4]=="s" & substr(meta[5],1,3)=="str" & meta[5]!="strL")
        stub = max((stub,min((40,st_numscalar("c(linesize)")-37,
                              strtoreal(substr(meta[5],4,.))))))
    printf("\n{txt}%s {c |}%11s%12s%12s\n", _parqit_rtext(_parqit_clip(title,stub),stub),
           "Freq.", "Percent", "Cum.")
    printf("{hline %g}{c +}{hline 35}\n", stub+1)
    n = 0
    for (i = 1; i <= rows; i++) {
        n = n + counts[i]
        printf("{txt}%s {c |}{res}%11s%12.2f%12.2f\n",
               _parqit_rtext(_parqit_clip(vals[i],stub),stub), strofreal(counts[i],"%10.0gc"),
               100 * counts[i] / total, 100 * n / total)
    }
    printf("{txt}{hline %g}{c +}{hline 35}\n", stub+1)
    printf("%s {c |}{res}%11s%12.2f\n", _parqit_rtext("Total",stub),
           strofreal(total,"%10.0gc"),100)
}
end

version 16.0
mata:

void _parqit_print_views(string scalar resp)
{
    real scalar      fh
    string scalar    line, cur
    string rowvector f

    fh = fopen(resp, "r")
    displayas("text")
    printf("\n    %-20s %8s %8s   %s\n", "view", "columns", "steps", "source")
    printf("    %s\n", 70 * "-")
    while ((line = fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 6)
        if (f[1] != "view") continue
        cur = (f[2] == "1" ? "* " : "  ")
        printf("  %s%-20s %8s %8s   %s\n", cur, _parqit_unhex(f[5]), f[3], f[4],
               _parqit_text(_parqit_clip(_parqit_unhex(f[6]),40)))
    }
    fclose(fh)
    printf("    (* = current)\n\n")
}
end

version 16.0
mata:

void _parqit_print_misstable(string scalar resp)
{
    real scalar      fh, nm, nt, ncomp
    string scalar    line
    string rowvector f

    fh = fopen(resp, "r")
    displayas("text")
    printf("\n    Variable {c |}    Missing    Observed         Obs   %% missing\n")
    printf("{hline 13}{c +}{hline 48}\n")
    nt = 0
    while ((line = fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 4)
        if (f[1] != "miss") continue
        nm = strtoreal(f[2])
        nt = strtoreal(f[3])
        printf("{txt}%s {c |}{res}%11s%12s%12s%12.2f\n",
               _parqit_rtext(abbrev(_parqit_unhex(f[4]),12),12),
               strofreal(nm,"%10.0gc"), strofreal(nt-nm,"%10.0gc"), strofreal(nt,"%10.0gc"),
               nt > 0 ? 100 * nm / nt : 0)
    }
    fclose(fh)
    /* the plugin computed complete observations row-wise over the
     * selected variables (count of rows with no missing in any of them) */
    ncomp = strtoreal(st_local("parqit_n_complete"))
    printf("{txt}{hline 62}\n")
    printf("Complete observations: {res}%s{txt} of {res}%s{txt} (%5.2f%%)\n",
           strtrim(strofreal(ncomp,"%18.0gc")),strtrim(strofreal(nt,"%18.0gc")),
           nt > 0 ? 100 * ncomp / nt : 0)
}

void _parqit_print_detail(string scalar resp)
{
    real scalar      fh, i, p, pad
    string scalar    line, name, title, ename
    string rowvector f, pl, meta, ex, rightlab, rightval
    transmorphic scalar metadata

    metadata = _parqit_statsmeta(resp)
    pl = ("1", "5", "10", "25", "50", "75", "90", "95", "99")
    fh = fopen(resp, "r")
    displayas("text")
    ename = ""
    ex = J(1, 8, ".")
    while ((line = fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 10)
        if (f[1] == "dtotal") {
            st_local("parqit_det_sum", f[2])
            continue
        }
        if (f[1] == "dext") {
            ex = f[2..9]
            ename = _parqit_unhex(f[10])
            continue
        }
        f = _parqit_fields(line, 19)
        if (f[1] != "det") continue
        name = _parqit_unhex(f[19])
        meta = _parqit_statmeta(metadata, name)
        title = meta[2] == "" ? meta[1] : meta[2]
        /* Native summarize centers the title by its UTF-8 byte length. */
        pad = max((0, floor((61 - strlen(title)) / 2)))
        printf("\n{txt}%s%s\n{hline 61}\n", pad * " ", _parqit_text(title))
        if (strtoreal(f[2]) == 0) printf("no observations\n")
        else {
            if (ename != name) {
                errprintf("parqit: detail output needs the rebuilt plugin; restart Stata\n")
                _error(198)
            }
            printf("{txt}      Percentiles      Smallest\n")
            for (i = 1; i <= 4; i++) {
                printf("{txt}%2s%% {res}%12s      %9s", pl[i],
                       _parqit_num(f[9+i], "%9.0g"), _parqit_num(ex[i], "%9.0g"))
                if (i >= 3) printf("{txt}       %-12s{res}%11s",
                    i == 3 ? "Obs" : "Sum of wgt.", _parqit_num(f[2], "%10.0gc"))
                printf("\n")
            }
            printf("\n{txt}50%% {res}%12s{txt}                      Mean        {res}%11s\n",
                   _parqit_num(f[14], "%9.0g"), _parqit_num(f[3], "%9.0g"))
            printf("{txt}                        Largest       Std. dev.   {res}%11s\n",
                   _parqit_num(f[4], "%9.0g"))
            rightlab = ("", "Variance", "Skewness", "Kurtosis")
            rightval = ("", f[5], f[6], f[7])
            for (i = 1; i <= 4; i++) {
                printf("{txt}%2s%% {res}%12s      %9s", pl[i+5],
                       _parqit_num(f[14+i], "%9.0g"), _parqit_num(ex[i+4], "%9.0g"))
                if (i >= 2) printf("{txt}       %-12s{res}%11s",
                    rightlab[i], _parqit_num(rightval[i], "%9.0g"))
                printf("\n")
            }
        }
        st_local("parqit_det_n", f[2])
        st_local("parqit_det_mean", f[3])
        st_local("parqit_det_sd", f[4])
        st_local("parqit_det_var", f[5])
        st_local("parqit_det_skew", f[6])
        st_local("parqit_det_kurt", f[7])
        st_local("parqit_det_min", f[8])
        st_local("parqit_det_max", f[9])
        for (p = 1; p <= 9; p++) {
            st_local("parqit_det_p" + pl[p], f[9 + p])
        }
        ename = ""
    }
    fclose(fh)
}

/* Type, not the spelling of a value, determines its sort order. */
string colvector _parqit_axis_order(string colvector vals, string scalar kind)
{
    string colvector u
    u = uniqrows(vals)
    if (rows(u)>0 & kind=="n") u = u[order(strtoreal(u),1)]
    return(u)
}

void _parqit_print_tab2(string scalar resp)
{
    real scalar      fh, i, j, r, c, n, total, stub, capacity, b, last, row, col, pad
    string scalar    line, rt, ct
    string rowvector f, vars, meta
    string colvector rv, cv, cells_r, cells_c
    real colvector   cells_n
    real matrix      M
    real colvector   rowtot
    real rowvector   coltot

    string scalar    k1, k2, f1, f2, lab
    string colvector rvd, cvd, lk1, lt1, lk2, lt2
    real scalar      uselab
    transmorphic scalar metadata

    metadata = _parqit_statsmeta(resp)
    fh = fopen(resp, "r")
    cells_r = cells_c = J(0, 1, "")
    cells_n = J(0, 1, .)
    lk1 = lt1 = lk2 = lt2 = J(0, 1, "")
    uselab = (st_local("parqit_tab_nolabel") != "1")
    k1 = k2 = "n"
    f1 = f2 = ""
    while ((line = _parqit_fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 5)
        if (f[1] == "t2h") {
            k1 = f[2]
            k2 = f[3]
            f1 = _parqit_unhex(f[4])
            f2 = _parqit_unhex(f[5])
            continue
        }
        if (f[1] == "tvl1") {  /* TAB-LABEL-1: row-axis value labels */
            lk1 = lk1 \ _parqit_unhex(f[2])
            lt1 = lt1 \ _parqit_unhex(f[3])
            continue
        }
        if (f[1] == "tvl2") {  /* column-axis value labels */
            lk2 = lk2 \ _parqit_unhex(f[2])
            lt2 = lt2 \ _parqit_unhex(f[3])
            continue
        }
        if (f[1] != "t2") continue
        cells_n = cells_n \ strtoreal(f[2])
        cells_r = cells_r \ _parqit_unhex(f[3])
        cells_c = cells_c \ _parqit_unhex(f[4])
    }
    fclose(fh)
    rv = _parqit_axis_order(cells_r,k1)
    cv = _parqit_axis_order(cells_c,k2)
    r = rows(rv)
    c = rows(cv)
    M = J(r, c, 0)
    n = rows(cells_n)
    for (i = 1; i <= n; i++) {
        M[selectindex(rv :== cells_r[i]), selectindex(cv :== cells_c[i])] =
            cells_n[i]
    }
    rowtot = rowsum(M)
    coltot = colsum(M)
    total = sum(M)
    /* RENDER-NATIVE-1: display labels use the variables' formats (numeric);
     * TAB-LABEL-1: a labelled level shows its value label unless nolabel */
    rvd = rv
    cvd = cv
    if (k1 == "n") {
        for (i = 1; i <= r; i++) {
            lab = uselab ? _parqit_vlabel(rv[i], lk1, lt1) : ""
            rvd[i] = (lab != "" ? lab : _parqit_render_num(rv[i], f1))
        }
    }
    if (k2 == "n") {
        for (j = 1; j <= c; j++) {
            lab = uselab ? _parqit_vlabel(cv[j], lk2, lt2) : ""
            cvd[j] = (lab != "" ? lab : _parqit_render_num(cv[j], f2))
        }
    }

    st_local("parqit_tab_n", strofreal(total, "%21.0g"))
    st_local("parqit_tab_r", strofreal(r, "%21.0g"))
    st_local("parqit_tab_c", strofreal(c, "%21.0g"))
    displayas("text")
    if (total==0) {
        printf("no observations\n")
        return
    }
    vars = tokens(st_local("_sq_vars"))
    meta = _parqit_statmeta(metadata,vars[1])
    rt = meta[2]=="" ? meta[1] : meta[2]
    meta = _parqit_statmeta(metadata,vars[2])
    ct = meta[2]=="" ? meta[1] : meta[2]
    row = st_local("parqit_tab2_row")=="1"
    col = st_local("parqit_tab2_col")=="1"
    if (row | col) {
        printf("\n{txt}{c TLC}{hline 19}{c TRC}\n{c |} Key               {c |}\n")
        printf("{c LT}{hline 19}{c RT}\n{c |}     frequency     {c |}\n")
        if (row) printf("{c |}  row percentage   {c |}\n")
        if (col) printf("{c |} column percentage {c |}\n")
        printf("{c BLC}{hline 19}{c BRC}\n")
    }
    stub = max((10,min((20,max((udstrlen(rt),max(udstrlen(rvd))))))))
    capacity = max((1,floor((st_numscalar("c(linesize)")-stub-13)/11)))
    for (b=1; b<=c; b=b+capacity) {
        last = min((c,b+capacity-1))
        if (capacity<c) printf("\n{txt}Columns %g-%g of %g\n",b,last,c)
        pad = max((1,floor((11*(last-b+1)-1-udstrlen(ct))/2)+1))
        printf("\n{txt}%s {c |}%s%s\n", _parqit_rtext("",stub),pad*" ",_parqit_text(ct))
        printf("%s {c |}",_parqit_rtext(_parqit_clip(rt,stub),stub))
        for (j=b; j<=last; j++) printf("%s%s",j>b ? " " : "",_parqit_rtext(_parqit_clip(cvd[j],10),10))
        printf(" {c |}%10s\n","Total")
        printf("{hline %g}{c +}{hline %g}{c +}{hline 10}\n",stub+1,11*(last-b+1))
        for (i=1; i<=r+1; i++) {
            if (i>1 & (row | col | i==r+1))
                printf("{txt}{hline %g}{c +}{hline %g}{c +}{hline 10}\n",stub+1,11*(last-b+1))
            printf("{txt}%s {c |}{res}",_parqit_rtext(i<=r ? _parqit_clip(rvd[i],stub) : "Total",stub))
            for (j=b; j<=last; j++) printf("%s%10s",j>b ? " " : "",
                strofreal(i<=r ? M[i,j] : coltot[j],"%9.0gc"))
            printf("{txt} {c |}{res}%10s\n",strofreal(i<=r ? rowtot[i] : total,"%9.0gc"))
            if (row) {
                printf("{txt}%s {c |}{res}",_parqit_rtext("",stub))
                for (j=b; j<=last; j++) printf("%s%10.2f",j>b ? " " : "",
                    100*(i<=r ? M[i,j]/rowtot[i] : coltot[j]/total))
                printf("{txt} {c |}{res}%10.2f\n",100)
            }
            if (col) {
                printf("{txt}%s {c |}{res}",_parqit_rtext("",stub))
                for (j=b; j<=last; j++) printf("%s%10.2f",j>b ? " " : "",
                    i<=r ? 100*M[i,j]/coltot[j] : 100)
                printf("{txt} {c |}{res}%10.2f\n",i<=r ? 100*rowtot[i]/total : 100)
            }
        }
    }
}

void _parqit_build_levels(string scalar resp)
{
    real scalar      fh, n, x
    string scalar    line, out, v, kind
    string rowvector f

    kind = st_local("parqit_lvl_kind")
    fh = fopen(resp, "r")
    out = ""
    n = 0
    while ((line = _parqit_fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 2)
        if (f[1] != "lvl") continue
        v = _parqit_unhex(f[2])
        n++
        if (n > 1) out = out + " "
        if (kind == "s") out = out + "`" + char(34) + v + char(34) + "'"
        else {
            /* RENDER-NATIVE-1 (A3-6): native levelsof renders an integer level
             * with %21.0g and a non-integer through Stata's macro formatting
             * (`local x = value`: .3, 1.00000000000e-07); do the same so
             * r(levels) matches native text for text */
            x = strtoreal(v)
            if (x < . & x == trunc(x)) out = out + strtrim(strofreal(x, "%21.0g"))
            else if (x < .) {
                if (_stata("local __parqit_lv = " + v, 1) == 0)
                    out = out + st_local("__parqit_lv")
                else out = out + v
            }
            else out = out + v
        }
    }
    fclose(fh)
    st_local("parqit_levels", out)
}
end

version 16.0
mata:

// split "expr [in f/l]" at a trailing ` in f/l'
void _parqit_split_in(string scalar src)
{
    real scalar      p
    string scalar    tailpart
    string rowvector t

    st_local("parqit_inexpr", strtrim(src))
    st_local("parqit_inrange", "")
    p = strrpos(src, " in ")
    if (p == 0) return
    tailpart = strtrim(substr(src, p + 4, .))
    if (tailpart == "") return
    t = ustrsplit(tailpart, "/")
    if (cols(t) == 2) {
        if (strtoreal(t[1]) != . & strtoreal(t[2]) != .) {
            st_local("parqit_inexpr", strtrim(substr(src, 1, p - 1)))
            st_local("parqit_inrange", strtrim(t[1]) + " " + strtrim(t[2]))
        }
    }
    else if (cols(t) == 1) {
        if (strtoreal(t[1]) != .) {
            st_local("parqit_inexpr", strtrim(substr(src, 1, p - 1)))
            st_local("parqit_inrange", strtrim(t[1]) + " " + strtrim(t[1]))
        }
    }
}

void _parqit_collect_names(string scalar resp, string scalar kind)
{
    real scalar      fh
    string scalar    line, out
    string rowvector f

    fh = fopen(resp, "r")
    out = ""
    while ((line = fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 6)
        if (f[1] != "vcol") continue
        if (kind != "") {
            if (_parqit_unhex(f[4]) != kind) continue
        }
        out = out + (out == "" ? "" : " ") + _parqit_unhex(f[3])
    }
    fclose(fh)
    st_local("parqit_dsnames", out)
}

void _parqit_lookfor_resp(string scalar resp)
{
    real scalar      fh, i, hit
    string scalar    line, name, lab, out
    string rowvector f, terms

    terms = tokens(strlower(st_local("_sq_terms")))
    fh = fopen(resp, "r")
    out = ""
    displayas("text")
    while ((line = _parqit_fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 6)
        if (f[1] != "vcol") continue
        name = _parqit_unhex(f[3])
        lab = _parqit_unhex(f[6])
        hit = 0
        for (i = 1; i <= cols(terms); i++) {
            if (strpos(strlower(name), terms[i]) | strpos(strlower(lab), terms[i])) {
                hit = 1
            }
        }
        if (hit) {
            printf("  %-32s %s\n", _parqit_text(name), _parqit_text(lab))
            out = out + (out == "" ? "" : " ") + name
        }
    }
    fclose(fh)
    if (out == "") printf("  (nothing matched)\n")
    st_local("parqit_dsnames", out)
}

void _parqit_print_codebook(string scalar resp)
{
    real scalar      fh, width, gap
    string scalar    line, kind, lo, hi
    string rowvector f, meta
    transmorphic scalar metadata

    metadata = _parqit_statsmeta(resp)
    width = st_numscalar("c(linesize)")
    fh = fopen(resp, "r")
    displayas("text")
    while ((line = _parqit_fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 9)
        if (f[1] != "cb") continue
        meta = _parqit_statmeta(metadata,_parqit_unhex(f[6]))
        gap = max((1,width-udstrlen(meta[1])-udstrlen(meta[2])))
        printf("\n{txt}{hline %g}\n%s%s%s\n{hline %g}\n",width,
               _parqit_text(meta[1]),gap*" ",_parqit_text(meta[2]),width)
        kind = f[5]=="s" ? "String" : "Numeric"
        if (meta[5]!="") kind = kind+" ("+meta[5]+")"
        lo = _parqit_unhex(f[7])
        hi = _parqit_unhex(f[8])
        if (f[5]!="s") {
            lo = _parqit_render_num(lo,meta[3])
            hi = _parqit_render_num(hi,meta[3])
        }
        else {
            lo = char(34)+_parqit_clip(lo,24)+char(34)
            hi = char(34)+_parqit_clip(hi,24)+char(34)
        }
        printf("\n{txt}                  Type: {res}%s\n",_parqit_text(kind))
        printf("\n{txt}                 Range: {res}[%s,%s]\n",_parqit_text(lo),_parqit_text(hi))
        printf("{txt}         Unique values: {res}%s\n",strtrim(_parqit_num(f[4],"%18.0gc")))
        printf("{txt}               Missing: {res}%s/%s\n",strtrim(_parqit_num(f[3],"%18.0gc")),
               strtrim(_parqit_num(f[2],"%18.0gc")))
    }
    fclose(fh)
    printf("\n")
}

void _parqit_print_distinct(string scalar resp)
{
    real scalar      fh, lastd
    string scalar    line
    string rowvector f

    fh = fopen(resp, "r")
    displayas("text")
    printf("\n    Variable {c |}    Distinct           Obs\n")
    printf("{hline 13}{c +}{hline 28}\n")
    lastd = .
    while ((line = fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 4)
        if (f[1] == "dst") {
            printf("{txt}%s {c |}{res}%12s%14s\n",
                   _parqit_rtext(abbrev(_parqit_unhex(f[4]),12),12),
                   _parqit_num(f[2],"%12.0gc"),_parqit_num(f[3],"%14.0gc"))
            lastd = strtoreal(f[2])
        }
        else if (f[1] == "dstj") {
            printf("{txt}%s {c |}{res}%12s%14s\n",_parqit_rtext("(joint)",12),
                   _parqit_num(f[2],"%12.0gc"),_parqit_num(f[3],"%14.0gc"))
            lastd = strtoreal(f[2])
        }
    }
    fclose(fh)
    printf("\n")
    st_local("parqit_ndistinct", strofreal(lastd, "%21.0g"))
}

void _parqit_print_dupreport(string scalar resp)
{
    real scalar      fh, copies, groups, uniq, surplus, total
    string scalar    line
    string rowvector f

    fh = fopen(resp, "r")
    displayas("text")
    printf("\nDuplicates in terms of %s\n",_parqit_text(st_local("_sq_vars")))
    printf("\n{hline 38}\n%9s {c |}%13s%14s\n", "Copies", "Observations", "Surplus")
    printf("{hline 10}{c +}{hline 27}\n")
    uniq = 0
    surplus = 0
    total = 0
    while ((line = fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 3)
        if (f[1] != "dupr") continue
        copies = strtoreal(f[2])
        groups = strtoreal(f[3])
        printf("{res}%9.0f {txt}{c |}{res}%13.0f%14.0f\n", copies, copies * groups,
               (copies - 1) * groups)
        uniq = uniq + groups
        surplus = surplus + (copies - 1) * groups
        total = total + copies * groups
    }
    fclose(fh)
    printf("{txt}{hline 38}\n")
    st_local("parqit_dup_unique", strofreal(uniq, "%21.0g"))
    st_local("parqit_dup_surplus", strofreal(surplus, "%21.0g"))
    st_local("parqit_dup_total", strofreal(total, "%21.0g"))
}

void _parqit_print_duplist(string scalar resp)
{
    real scalar      fh, i, k
    string scalar    line, value
    string rowvector f, parts, names, meta
    transmorphic scalar metadata

    metadata = _parqit_statsmeta(resp)
    names = J(1,0,"")
    k = 0
    fh = fopen(resp, "r")
    displayas("text")
    while ((line = _parqit_fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 2)
        if (f[1] == "duph2") {
            k = strtoreal(f[2])
            f = _parqit_fields(line,k+2)
            parts = J(1,k,"")
            for (i=1; i<=k; i++) parts[i] = _parqit_unhex(f[i+2])
            names = parts
            printf("\n  ")
            for (i = 1; i <= k; i++) printf("%-14s", _parqit_text(abbrev(parts[i],13)))
            printf("\n  %s\n", (14 * cols(parts)) * "-")
        }
        else if (f[1] == "dupl2") {
            f = _parqit_fields(line,k+1)
            printf("  ")
            for (i = 1; i <= k; i++) {
                value = _parqit_unhex(f[i+1])
                meta = _parqit_statmeta(metadata,names[i])
                if (meta[4]!="s") value = _parqit_render_num(value,meta[3])
                value = _parqit_clip(value,13)
                printf("%s%s",_parqit_text(value),max((0,14-udstrlen(value)))*" ")
            }
            printf("\n")
        }
        else if (f[1]=="duph" | f[1]=="dupl") {
            errprintf("parqit: duplicate output needs the rebuilt plugin; restart Stata\n")
            _error(198)
        }
    }
    fclose(fh)
    printf("\n")
}

void _parqit_print_misspatterns(string scalar resp)
{
    real scalar i, j, n, total, shown, count
    string scalar pattern, names, item
    string rowvector f, vars
    string colvector lines

    lines = _parqit_resp_lines(resp)
    total = .
    vars = J(1,0,"")
    for (i=1; i<=rows(lines); i++) {
        f = _parqit_fields(lines[i],3)
        if (f[1]=="mph") vars = tokens(_parqit_unhex(f[2]))
        if (f[1]=="mptotal") total = strtoreal(f[2])
    }
    if (total==.) {
        errprintf("parqit: pattern output needs the rebuilt plugin; restart Stata\n")
        _error(198)
    }
    printf("\n{txt}   Missing-value patterns\n     (1 means complete)\n")
    printf("\n   Frequency   Percent {c |}   Pattern\n                       {c |}")
    for (j=1; j<=cols(vars); j++) printf("%3.0f",j)
    printf("\n  {hline 21}{c +}{hline %g}\n",3*cols(vars)+2)
    n = shown = 0
    for (i=1; i<=rows(lines); i++) {
        f = _parqit_fields(lines[i],3)
        if (f[1]!="mpat") continue
        pattern = _parqit_unhex(f[3])
        count = strtoreal(f[2])
        printf("{res}%12.0f%10.2f {txt}{c |}{res}",count,total>0 ? 100*count/total : .)
        for (j=1; j<=cols(vars); j++) printf("%3.0f",substr(pattern,j,1)=="+")
        printf("\n")
        shown = shown+count
        n++
    }
    printf("{txt}  {hline 21}{c +}{hline %g}\n",3*cols(vars)+2)
    printf("{res}%12.0f%10.2f {txt}{c |}\n",shown,total>0 ? 100*shown/total : .)
    if (shown<total) printf("{txt}Shown: the 100 most frequent patterns (%s observations in all)\n",
                            strtrim(strofreal(total,"%18.0gc")))
    names = "  Variables are"
    for (j=1; j<=cols(vars); j++) {
        item = " ("+strtrim(strofreal(j))+") "+vars[j]
        if (udstrlen(names)+udstrlen(item)>st_numscalar("c(linesize)")) {
            printf("{txt}%s\n",_parqit_text(names))
            names = " "
        }
        names = names+item
    }
    printf("\n{txt}%s\n",_parqit_text(names))
    st_local("parqit_mp_r", strofreal(n, "%21.0g"))
    st_local("parqit_mp_n", strofreal(total, "%21.0g"))
}

string scalar _parqit_statname(string scalar s)
{
    string rowvector keys, labels
    real scalar i
    keys = ("n", "count", "mean", "sd", "var", "sum", "min", "max", "range", "median")
    labels = ("N", "N", "Mean", "SD", "Variance", "Sum", "Min", "Max", "Range", "p50")
    for (i=1; i<=cols(keys); i++) if (s==keys[i]) return(labels[i])
    return(s)
}

void _parqit_print_tabstat(string scalar resp)
{
    real scalar i, j, ns, k, nt, ng, g, v, stub, across, capacity, b, last, rr
    string scalar by, label, title, mat, suffix
    string colvector lines, groups, lkeys, ltexts
    string rowvector f, stats, labels, vars, displayvars, meta
    real matrix S
    transmorphic scalar metadata

    stats = tokens(st_local("_sq_stats"))
    vars = tokens(st_local("_sq_vars"))
    by = st_local("_sq_by")
    ns = cols(stats)
    k = cols(vars)
    labels = J(1,ns,"")
    for (i=1; i<=ns; i++) labels[i] = _parqit_statname(stats[i])
    lines = _parqit_resp_lines(resp)
    metadata = _parqit_statsmeta(resp)
    displayvars = vars
    for (i=1; i<=k; i++) {
        meta = _parqit_statmeta(metadata,vars[i])
        displayvars[i] = meta[1]
    }
    lkeys = ltexts = J(0,1,"")
    nt = 0
    for (i=1; i<=rows(lines); i++) {
        f = _parqit_fields(lines[i], 3)
        if (f[1]=="ts") nt++
        if (f[1]=="tsvl") {
            lkeys = lkeys \ _parqit_unhex(f[2])
            ltexts = ltexts \ _parqit_unhex(f[3])
        }
    }
    ng = nt/k
    S = J(ng*ns,k,.)
    groups = J(ng,1,"")
    nt = 0
    for (i=1; i<=rows(lines); i++) {
        f = _parqit_fields(lines[i], ns+3)
        if (f[1]!="ts") continue
        nt++
        g = ceil(nt/k)
        v = mod(nt-1,k)+1
        S[((g-1)*ns+1)..(g*ns),v] = strtoreal(f[2..(ns+1)])'
        groups[g] = _parqit_unhex(f[ns+3])
    }
    if (by!="") {
        meta = _parqit_statmeta(metadata, by)
        for (g=1; g<=ng; g++) {
            label = meta[4]=="n" ? _parqit_vlabel(groups[g],lkeys,ltexts) : ""
            groups[g] = label!="" ? label :
                (meta[4]=="n" ? _parqit_render_num(groups[g],meta[3]) : groups[g])
        }
    }
    st_local("parqit_ts_groups", strofreal(ng))
    if (st_local("_sq_save")!="") {
        for (g=1; g<=ng; g++) {
            mat = st_tempname()
            st_matrix(mat, S[((g-1)*ns+1)..(g*ns),.])
            st_matrixrowstripe(mat, (J(ns,1,""),labels'))
            st_matrixcolstripe(mat, (J(k,1,""),displayvars'))
            suffix = strtrim(strofreal(g))
            st_local("parqit_ts_mat"+suffix, mat)
            st_local("parqit_ts_name"+suffix, groups[g])
        }
    }
    if (ng==0) {
        printf("{txt}no observations\n")
        return
    }
    displayas("text")
    stub = k==1 ? 12 : 8
    if (by!="") {
        if (k==1) printf("\n{txt}Summary for variables: %s\n", _parqit_text(displayvars[1]))
        else printf("\n{txt}Summary statistics: %s\n", invtokens(labels, ", "))
        printf("Group variable: %s", _parqit_text(meta[1]))
        if (meta[2]!="") printf(" (%s)", _parqit_text(meta[2]))
        printf("\n")
        stub = max((8,min((16,max(udstrlen(groups)))),min((16,udstrlen(meta[1])))))
        if (meta[4]=="s" & substr(meta[5],1,3)=="str" & meta[5]!="strL")
            stub = max((stub,min((16,strtoreal(substr(meta[5],4,.))))))
    }
    across = k==1 ? ns : k
    capacity = max((1, floor((st_numscalar("c(linesize)")-stub-2)/10)))
    for (b=1; b<=across; b=b+capacity) {
        last = min((across,b+capacity-1))
        title = by!="" ? abbrev(meta[1],stub) : (k==1 ? "Variable" : "Stats")
        printf("\n{txt}%s {c |}", _parqit_rtext(title,stub))
        for (j=b; j<=last; j++) printf("%s", _parqit_rtext(k==1 ? labels[j] : abbrev(displayvars[j],9),10))
        printf("\n{hline %g}{c +}{hline %g}\n", stub+1,10*(last-b+1))
        for (g=1; g<=ng; g++) {
            if (g>1 & k>1 & ns>1) printf("{txt}{hline %g}{c +}{hline %g}\n",stub+1,10*(last-b+1))
            for (i=1; i<=(k==1 ? 1 : ns); i++) {
                label = by!="" ? (i==1 ? _parqit_clip(groups[g],stub) : "") :
                    (k==1 ? abbrev(displayvars[1],stub) : labels[i])
                printf("{txt}%s {c |}{res}", _parqit_rtext(label,stub))
                for (j=b; j<=last; j++) {
                    rr = (g-1)*ns + (k==1 ? j : i)
                    printf("%10s", strofreal(S[rr,k==1 ? 1 : j], "%9.0g"))
                }
                printf("\n")
            }
        }
        printf("{txt}{hline %g}\n", stub+2+10*(last-b+1))
    }
}

real scalar _parqit_corr_subnormal_p(real scalar r, real scalar sine, real scalar nu)
{
    real scalar b, q, term, series, correction, add, next, j, k, odd, coef, logp, h
    b = nu/2
    term = series = 1
    correction = 0
    if (r>=sine) {
        if (nu>=2200 | sine==0) return(0)
        q = sine*sine
        k = floor(b)
        odd = mod(nu,2)
        coef = odd ? 2/pi() : 1
        for (j=1; j<=k; j++) coef = coef*(odd ? 2*j/(2*j+1) : (2*j-1)/(2*j))
        for (j=1; j<=64; j++) {
            term = term*q*(odd ? 2*(k+j)/(2*(k+j)+1) : (2*(k+j)-1)/(2*(k+j)))
            add = term-correction
            next = series+add
            correction = (next-series)-add
            series = next
            if (term<series*2^-60) break
        }
        if (j>64) return(.)
        logp = nu*ln(sine)+ln(r*coef*series)
    }
    else {
        if (b<512) return(.)
        q = (1-r*r)/(r*r)
        for (j=1; j<=64; j++) {
            term = -term*((j-.5)/(b+j))*q
            add = term-correction
            next = series+add
            correction = (next-series)-add
            series = next
            if (abs(term)<abs(series)*2^-60) break
        }
        if (j>64 | series<=0) return(.)
        /* Stirling remainder here is below 2e-22 for b>=512. */
        h = 1/b
        coef = exp(-h/8+h^3/192-h^5/640)/sqrt(pi()*b)
        logp = b*ln1p(-r*r)+ln(coef*series/r)
    }
    /* Mata exp() itself flushes subnormal results; scale before exponentiation. */
    return(exp(logp+512*ln(2))*2^-512)
}

real scalar _parqit_corr_p(real scalar rho, real scalar sine, real scalar n,
                           real scalar perfect, real scalar domain)
{
    real scalar r, p
    if (rho>=. | sine>=. | n<3) return(.)
    if (perfect) return(0)
    r = abs(rho)
    if (r==0) return(1)
    if (n==3) {
        if (r>=sine) return((2/pi())*atan(sine/r))
        return(1-(2/pi())*atan(r/sine))
    }
    if (n==4) {
        if (r>=sine) return((sine*sine)/(1+r))
        return(1-r)
    }
    if (!domain) return(.)
    p = r>=sine ? ibeta((n-2)/2,.5,sine*sine) : ibetatail(.5,(n-2)/2,r*r)
    if (p==0) p = _parqit_corr_subnormal_p(r,sine,n-2)
    return(p)
}

void _parqit_print_corr(string scalar resp)
{
    real scalar      fh, i, j, k, minn, lastr, b, last, width, pairwise, needsig, badtail
    string scalar    line
    string rowvector f
    string colvector names
    real matrix      R, Nm, P, Sine, Perfect, Domain

    fh = fopen(resp, "r")
    names = J(0, 1, "")
    while ((line = fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 7)
        if (f[1] != "cor") continue
        i = strtoreal(f[2])
        if (i > rows(names)) names = names \ _parqit_unhex(f[6])
    }
    fclose(fh)
    k = rows(names)
    R = J(k, k, .)
    Nm = J(k, k, .)
    needsig = st_local("_sq_sig")!=""
    P = needsig ? J(k,k,.) : J(0,0,.)
    Sine = P
    Perfect = P
    Domain = P
    fh = fopen(resp, "r")
    while ((line = fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 7)
        if (f[1] == "cgeom") {
            if (needsig) {
                i = strtoreal(f[2])
                j = strtoreal(f[3])
                Sine[i,j] = strtoreal(f[4])
                Perfect[i,j] = strtoreal(f[5])
                Domain[i,j] = strtoreal(f[6])
            }
            continue
        }
        if (f[1] != "cor") continue
        i = strtoreal(f[2])
        j = strtoreal(f[3])
        R[i, j] = strtoreal(f[4])
        Nm[i, j] = strtoreal(f[5])
        R[j, i] = R[i, j]
        Nm[j, i] = Nm[i, j]
    }
    fclose(fh)

    minn = .
    lastr = .
    badtail = 0
    for (i = 1; i <= k; i++) {
        for (j = 1; j <= i; j++) {
            if (R[i,j] < . & abs(R[i,j]) > 1) {
                errprintf("parqit: correlation outside its mathematical range\n")
                _error(498)
            }
            if (i != j) lastr = R[i, j]
            if (needsig & i!=j & R[i,j] < . & Nm[i,j] >= 3) {
                P[i,j] = _parqit_corr_p(R[i,j],Sine[i,j],Nm[i,j],Perfect[i,j],Domain[i,j])
                badtail = badtail | P[i,j]>=.
                P[j,i] = P[i,j]
            }
        }
        if (Nm[i, i] < minn) minn = Nm[i, i]
    }
    displayas("text")
    if (badtail) printf("note: a p-value outside the supported beta-function domain was returned as missing\n")
    pairwise = st_local("_sq_pairwise") == "true"
    if (!pairwise) printf("{txt}(obs=%s)\n", strtrim(strofreal(minn, "%18.0g")))
    width = max((1, floor((st_numscalar("c(linesize)") - 14) / 9)))
    for (b = 1; b <= k; b = b + width) {
        last = min((k, b + width - 1))
        printf("\n{txt}             {c |}")
        for (j = b; j <= last; j++) printf("%s", _parqit_rtext(abbrev(names[j],8),9))
        printf("\n{hline 13}{c +}{hline %g}\n", 9*(last-b+1))
        for (i = b; i <= k; i++) {
            printf("{txt}%s {c |}{res}", _parqit_rtext(abbrev(names[i],12),12))
            for (j = b; j <= min((i,last)); j++) printf("%9.4f", R[i,j])
            printf("\n")
            if (st_local("_sq_sig") != "") {
                printf("{txt}             {c |}{res}")
                for (j = b; j <= min((i-1,last)); j++) printf("%9.4f", P[i,j])
                printf("\n")
            }
            if (st_local("_sq_obs") != "") {
                printf("{txt}             {c |}{res}")
                for (j = b; j <= min((i,last)); j++) printf("%9.0f", Nm[i,j])
                printf("\n")
            }
            if (st_local("_sq_sig") != "" | st_local("_sq_obs") != "")
                printf("{txt}             {c |}\n")
        }
    }
    if (!pairwise) printf("\n")
    st_local("parqit_corr_matrices", "0")
    if (k > st_numscalar("c(max_matdim)")) {
        printf("{txt}note: matrix results exceed Stata's matrix dimension limit; table and scalars returned\n")
        st_local("parqit_corr_n", strofreal(minn, "%21.0g"))
        st_local("parqit_corr_last", strofreal(lastr, "%21.0g"))
        return
    }
    st_matrix(st_local("_sq_corr_matrix"), R)
    st_matrixrowstripe(st_local("_sq_corr_matrix"), (J(k,1,""),names))
    st_matrixcolstripe(st_local("_sq_corr_matrix"), (J(k,1,""),names))
    if (pairwise) {
        st_matrix(st_local("_sq_count_matrix"), Nm)
        st_matrixrowstripe(st_local("_sq_count_matrix"), (J(k,1,""),names))
        st_matrixcolstripe(st_local("_sq_count_matrix"), (J(k,1,""),names))
        if (st_local("_sq_sig") != "") {
            st_matrix(st_local("_sq_p_matrix"), P)
            st_matrixrowstripe(st_local("_sq_p_matrix"), (J(k,1,""),names))
            st_matrixcolstripe(st_local("_sq_p_matrix"), (J(k,1,""),names))
        }
    }
    st_local("parqit_corr_matrices", "1")
    st_local("parqit_corr_n", strofreal(minn, "%21.0g"))
    st_local("parqit_corr_last", strofreal(lastr, "%21.0g"))
}

void _parqit_fill_hist(string scalar resp)
{
    real scalar      fh, b
    string scalar    line
    string rowvector f

    fh = fopen(resp, "r")
    while ((line = fget(fh)) != J(0, 0, "")) {
        f = _parqit_fields(line, 4)
        if (f[1] != "hb") continue
        b = strtoreal(f[2]) + 1
        if (b < 1 | b > st_nobs() | b == .) {
            displayas("error")
            printf("parqit histogram: internal bin record out of range: %s (frame obs %f)\n",
                   line, st_nobs())
            _error(3300, "parqit histogram: bin/frame mismatch")
        }
        st_store(b, "__freq", strtoreal(f[3]))
        st_store(b, "__mid", strtoreal(f[4]))
    }
    fclose(fh)
}
end
