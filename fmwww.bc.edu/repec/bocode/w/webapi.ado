*! webapi v0.1.0  2026-07-04
*! Fetch an authenticated JSON web API into Stata as a dataset.
*!
*! A small, dependency-free generalisation of the pattern documented in
*! Booth (2026, googlesheets/googlechart): a request to a URL, an
*! authentication step, and a JSON reply parsed back into variables and
*! observations.  webapi handles the HTTP + auth + JSON-to-table steps with
*! the Python standard library, so no pip packages or virtualenv are needed.
*!
*!   webapi get  using "<URL>" [, options]
*!   webapi post using "<URL>" , body("<json>") [, options]
*!
*! Options:
*!   records(path)      dot-path to the JSON array of records (default: the
*!                      whole reply).  e.g. records("data") or records("results.items")
*!   params(k=v|k=v)    pipe-delimited query-string parameters
*!   headers(H:V|H:V)   pipe-delimited request headers
*!   bearer(token)      send Authorization: Bearer <token>
*!   basicauth(user:pw) send HTTP basic authentication
*!   apikeyheader(H:V)  send an API key as a header
*!   apikeyparam(k=v)   send an API key as a query parameter
*!   body(text)         request body (POST); JSON content-type assumed
*!   timeout(#)         seconds before giving up (default 30)
*!   tsv(path)          keep the intermediate TSV at this path
*!   stringall          import every column as a string
*!   clear              replace data in memory (like import delimited)
*!   verbose            echo the underlying python invocation

program define webapi, rclass
    version 16.0

    gettoken sub 0 : 0
    local sub = lower(strtrim("`sub'"))
    if "`sub'" == "help" {
        help webapi
        exit 0
    }
    if !inlist("`sub'", "get", "post") {
        display as error "webapi: first word must be {bf:get}, {bf:post}, or {bf:help}"
        display as error `"  Syntax: {bf:webapi get using "URL", records(...) [options]}"'
        exit 198
    }

    syntax using/, [ HEADers(string) PARAms(string)                        ///
        BEARER(string) BASICauth(string)                                   ///
        APIKEYHeader(string) APIKEYParam(string)                           ///
        RECords(string) BODY(string) TIMEout(integer 30)                   ///
        EVERY(real 0) TIMES(integer 0)                                     ///
        TSV(string) STRINGall CLEAR Verbose ]

    local url `"`using'"'
    local method = upper("`sub'")

    * --- discover the helper -------------------------------------------
    capture findfile webapi_helper.py
    if _rc {
        display as error "webapi: webapi_helper.py not on the adopath. Reinstall the package."
        exit 601
    }
    local helper "`r(fn)'"

    * --- output paths --------------------------------------------------
    if `"`tsv'"' == "" {
        tempfile datatsv
        local outdata `"`datatsv'"'
    }
    else {
        local outdata `"`tsv'"'
    }
    tempfile status argjson

    * --- assemble the request as a tab-separated key/value file --------
    * A flat key<TAB>value file (rather than JSON built in Stata) means URLs,
    * tokens, and parameter values need no escaping on the Stata side.
    tempname h
    file open `h' using `"`argjson'"', write text replace
    file write `h' "method"  _tab "`method'"    _n
    file write `h' "url"     _tab `"`url'"'      _n
    file write `h' "records" _tab `"`records'"'  _n
    file write `h' "timeout" _tab "`timeout'"    _n
    if `"`headers'"'      != "" file write `h' "headers_raw"   _tab `"`headers'"'      _n
    if `"`params'"'       != "" file write `h' "params_raw"    _tab `"`params'"'       _n
    if `"`bearer'"'       != "" file write `h' "bearer"        _tab `"`bearer'"'       _n
    if `"`basicauth'"'    != "" file write `h' "basic"         _tab `"`basicauth'"'    _n
    if `"`apikeyheader'"' != "" file write `h' "apikey_header" _tab `"`apikeyheader'"' _n
    if `"`apikeyparam'"'  != "" file write `h' "apikey_param"  _tab `"`apikeyparam'"'  _n
    if `"`body'"'         != "" file write `h' "body"          _tab `"`body'"'         _n
    file write `h' "out_tsv" _tab `"`outdata'"'  _n
    file close `h'

    * --- python + polling settings -------------------------------------
    if lower("`c(os)'") == "windows" local PY "python"
    else                             local PY "python3"
    if "`verbose'" != "" {
        display as text `"[webapi] `PY' "`helper'" "`argjson'" "`status'""'
    }
    if `every' < 0 local every 0
    * every() without times() polls a bounded number of times, so a call
    * always returns; times() alone (no wait) just repeats back-to-back.
    if `every' > 0 & `times' <= 0 local times 12
    if `times' <= 0 local times 1
    local polling = (`times' > 1)
    if "`stringall'" != "" local scols "stringcols(_all)"

    tempfile master

    forvalues _p = 1/`times' {
        quietly shell `PY' "`helper'" "`argjson'" "`status'"

        capture confirm file `"`status'"'
        if _rc {
            display as error "webapi: the helper produced no output. Is python3 on your PATH?"
            exit 198
        }

        * read the key=value status
        local st ""
        local err ""
        local msg ""
        local nrows 0
        local ncols 0
        local http ""
        tempname sh
        file open `sh' using `"`status'"', read text
        file read `sh' line
        while r(eof) == 0 {
            local eq = strpos(`"`line'"', "=")
            if `eq' > 0 {
                local k = substr(`"`line'"', 1, `eq'-1)
                local v = substr(`"`line'"', `eq'+1, .)
                if "`k'" == "status"       local st    `"`v'"'
                else if "`k'" == "error"   local err   `"`v'"'
                else if "`k'" == "message" local msg   `"`v'"'
                else if "`k'" == "nrows"   local nrows `"`v'"'
                else if "`k'" == "ncols"   local ncols `"`v'"'
                else if "`k'" == "http_status" local http `"`v'"'
            }
            file read `sh' line
        }
        file close `sh'

        if "`st'" != "ok" {
            display as error "webapi `sub': `err' -- `msg'"
            exit 198
        }

        if `polling' {
            * accumulate one snapshot per poll, stamped with the poll index
            * and the wall-clock time, so a stream of pulls stacks into a panel.
            import delimited using `"`outdata'"', delimiters(tab) varnames(1) clear `scols'
            quietly gen long _poll = `_p'
            quietly gen str12 _polltime = "`c(current_time)'"
            if `_p' > 1 quietly append using `"`master'"'
            quietly save `"`master'"', replace
            display as text "  poll `_p'/`times' at `c(current_time)': `nrows' rows (HTTP `http')"
            if `_p' < `times' & `every' > 0 sleep `=int(`every'*1000)'
        }
        else {
            import delimited using `"`outdata'"', delimiters(tab) varnames(1) `clear' `scols'
        }
    }

    if `polling' {
        quietly use `"`master'"', clear
        sort _poll
        display as result _n "[webapi `sub']  `times' polls, `=_N' total rows accumulated"
        return scalar polls = `times'
        return scalar nrows = _N
    }
    else {
        display as result _n "[webapi `sub']  `nrows' rows, `ncols' columns  (HTTP `http')"
        return scalar nrows = `nrows'
        return scalar ncols = `ncols'
    }
    return local http `"`http'"'
    return local url  `"`url'"'
end
