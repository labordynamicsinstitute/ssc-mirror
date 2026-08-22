*! _gvar_getdata 1.0.1  21aug2026
*! gvar getdata -- fetch the example datasets, which are distributed separately
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* WHY THIS EXISTS
*   SSC caps a package description at 100 lines.  Listing 26 datasets as f lines
*   put gvar at 114 and it was refused.  Kit Baum's own remedy was to keep the
*   data out of the package and fetch it with a single command:
*
*     "if the .dta files could be installed from a single command, those files
*      can be available from SSC using ssc copy commands, so you would just
*      need a single ado that invokes ssc copy commands for each of the ...
*      datasets"
*
*   So nothing is dropped from the project: every dataset the documentation
*   mentions is still available, it just arrives on request rather than at
*   install time.  The alternative -- deleting the data -- would have made the
*   documented examples unrunnable, which is not a trade worth making.
*
* WHERE THE FILES COME FROM
*   from(ssc)    one -ssc copy FILENAME- per dataset.  ssc copy takes a FILE
*                name, not a package name -- "ssc copy filename copies a
*                specific file stored at SSC to your computer" -- which is
*                exactly what Kit meant by "ssc copy commands for EACH of the
*                datasets".  pkg() is therefore not needed on this route; the
*                files simply have to be present in the archive.
*   from(net)    one -net get PKG- for the whole set of ancillary files, from
*                an SSC package name or a URL given in pkg().  net get fetches
*                a package's ancillary files together, so it is one call, not
*                one per file.
*
*   No default is guessed.  from() is required, because silently choosing a
*   download source for the user is not this command's business.
*
*   Both mechanisms write to the CURRENT directory, so dir() is honoured by
*   moving there and moving back -- on the failure paths too.

program define _gvar_getdata, rclass
    version 14.0

    syntax [anything] [, FROM(string) PKG(string) DIR(string) ///
                         LIST REPLACE noSUMmary ]

    * ----------------------------------------------------------------------
    * The datasets, grouped as the documentation groups them
    * ----------------------------------------------------------------------
    local demo   "gvar_demo26 gvar_flows gvar_demospec gvar_demoagg"
    local extra  "gvar_demo gvar_demoregions gvar_eer gvar_mr gvar_pricevol"
    local wmats  "gvar_w_eer_fin0708 gvar_w_eer_fin0711 gvar_w_eer_fin11"
    local wmats  "`wmats' gvar_w_eer_inv gvar_w_eer_inv2 gvar_w_eer_knn8"
    local wmats  "`wmats' gvar_w_eer_trade00 gvar_w_eer_trade0006"
    local wmats  "`wmats' gvar_w_eer_trade0012 gvar_w_eer_trade12"
    local wmats  "`wmats' gvar_w_gvarx_tv gvar_w_gvarx2014 gvar_w_mr_8016"
    local wmats  "`wmats' gvar_w_mr_tv gvar_w_test"
    local test   "gvar_test"

    local all "`demo' `extra' `wmats' `test'"

    * ----------------------------------------------------------------------
    * Which ones
    * ----------------------------------------------------------------------
    local want = lower(trim("`anything'"))
    if ("`want'" == "" | "`want'" == "demo")  local files "`demo'"
    else if ("`want'" == "all")               local files "`all'"
    else if ("`want'" == "weights")           local files "`wmats'"
    else if ("`want'" == "extra")             local files "`extra'"
    else {
        * treat it as an explicit list, and check every name before fetching
        local files ""
        local bad ""
        foreach f of local want {
            local f = subinstr("`f'", ".dta", "", .)
            if (strpos(" `all' ", " `f' ")) local files "`files' `f'"
            else                            local bad   "`bad' `f'"
        }
        if ("`bad'" != "") {
            di as err "gvar getdata: not a dataset in this collection:`bad'"
            di as err "type {bf:gvar getdata, list} for the names, or use one of"
            di as err "{bf:demo}, {bf:weights}, {bf:extra}, {bf:all}"
            exit 198
        }
    }

    * ----------------------------------------------------------------------
    * list only
    * ----------------------------------------------------------------------
    if ("`list'" != "") {
        _gvar_title "The gvar example datasets"
        di as text "  Distributed separately from the package; fetch with"
        di as text "  {bf:gvar getdata} {it:group}{bf:, from() pkg()}."
        di ""
        di as text "  {bf:demo}    " as result "`demo'"
        di as text "          " as text "the four the documented examples use"
        di ""
        di as text "  {bf:extra}   " as result "`extra'"
        di ""
        di as text "  {bf:weights} " as result "`: word 1 of `wmats''" as text " ... (" ///
           as result "`: word count `wmats''" as text " alternative link matrices)"
        di ""
        di as text "  {bf:all}     " as result "`: word count `all''" as text " datasets"
        di ""
        return local demo    "`demo'"
        return local extra   "`extra'"
        return local weights "`wmats'"
        return local all     "`all'"
        exit
    }

    * ----------------------------------------------------------------------
    * Source
    * ----------------------------------------------------------------------
    if ("`from'" == "") {
        di as err "gvar getdata: {bf:from()} is required."
        di as err ""
        di as err "The datasets are not installed with the package -- SSC caps a"
        di as err "package description at 100 lines and 26 data files do not fit."
        di as err "Name where they should come from:"
        di as err ""
        di as err "    {bf:gvar getdata demo, from(ssc) pkg(}{it:package}{bf:)}"
        di as err "    {bf:gvar getdata all,  from(net) pkg(}{it:url}{bf:)}"
        di as err ""
        di as err "See {bf:help gvar_getdata}.  {bf:gvar getdata, list} shows the names."
        exit 198
    }
    local from = lower(trim("`from'"))
    if (!inlist("`from'", "ssc", "net")) {
        di as err "gvar getdata: from() must be {bf:ssc} or {bf:net}"
        exit 198
    }
    * pkg() is required only for net get, which addresses a PACKAGE.
    * ssc copy addresses a FILE, so it needs no package name at all.
    if ("`from'" == "net" & "`pkg'" == "") {
        di as err "gvar getdata: {bf:pkg()} is required with {bf:from(net)}"
        di as err "give the SSC package name or the URL that holds the datasets"
        exit 198
    }

    * ----------------------------------------------------------------------
    * Destination
    * ----------------------------------------------------------------------
    local back `"`c(pwd)'"'
    if ("`dir'" != "") {
        capture mkdir `"`dir'"'
        capture cd `"`dir'"'
        if (_rc) {
            di as err `"gvar getdata: cannot use dir(`dir')"'
            exit 170
        }
    }
    local dest `"`c(pwd)'"'

    * ----------------------------------------------------------------------
    * Fetch
    * ----------------------------------------------------------------------
    local n : word count `files'
    if ("`summary'" != "nosummary") {
        _gvar_title "Fetching the gvar example datasets"
        di as text "  source      " as result "`from'" as text "  " as result "`pkg'"
        di as text "  destination " as result `"`dest'"'
        di as text "  files       " as result "`n'"
        di ""
    }

    local got 0
    local skipped 0
    local failed ""

    * net get fetches a package's ancillary files TOGETHER, so it is one call.
    * Doing it inside the per-file loop would re-download the whole set once per
    * dataset.
    if ("`from'" == "net") {
        capture net get `"`pkg'"', replace
        if (_rc) {
            qui cd `"`back'"'
            di as err `"gvar getdata: net get `pkg' failed, rc `=_rc'"'
            di as err "check the package name or URL:"
            di as err `"    {bf:. net from `pkg'}"'
            exit 198
        }
    }

    foreach f of local files {
        * Do not overwrite unless asked: someone may have edited a local copy.
        capture confirm file "`f'.dta"
        if (_rc == 0 & "`replace'" == "") {
            local ++skipped
            if ("`summary'" != "nosummary") ///
                di as text "  " %-24s "`f'.dta" as text "already here, kept"
            continue
        }
        if ("`from'" == "ssc") {
            * ssc copy takes a FILE name.  One call per dataset, which is what
            * "ssc copy commands for each of the datasets" means.
            capture ssc copy `f'.dta, replace
            local rc = _rc
        }
        else {
            * net get already ran; the file either arrived or it did not.
            local rc = 0
        }
        capture confirm file "`f'.dta"
        if (`rc' | _rc) {
            local failed "`failed' `f'"
            if ("`summary'" != "nosummary") ///
                di as text "  " %-24s "`f'.dta" as err "not delivered"
            continue
        }
        local ++got
        if ("`summary'" != "nosummary") ///
            di as text "  " %-24s "`f'.dta" as result "ok"
    }

    if ("`summary'" != "nosummary") {
        di ""
        di as text "  fetched " as result "`got'" as text ", already present " ///
           as result "`skipped'" as text ", failed " as result ///
           "`: word count `failed''"
        if ("`failed'" != "") {
            di ""
            di as err "  Not delivered:`failed'"
            di as text "  This is about the SOURCE, not your installation."
            if ("`from'" == "ssc") {
                di as text "  ssc copy needs each file to be present in the"
                di as text "  archive.  Check one by hand:"
                di as text "      {bf:. ssc copy `: word 1 of `failed''.dta}"
            }
            else {
                di as text "  Check what that package actually carries:"
                di as text `"      {bf:. net from `pkg'}"'
            }
        }
        else if (`got' > 0 | `skipped' > 0) {
            di ""
            di as text "  In " as result `"`dest'"' as text ", so {bf:use gvar_demo26}"
            di as text "  works from there.  {bf:gvar_example.do} is the worked analysis."
        }
    }

    * Always return to where the user was, including after a partial failure.
    qui cd `"`back'"'

    return local files   "`files'"
    return local failed  "`failed'"
    return scalar got     = `got'
    return scalar skipped = `skipped'
    return scalar nfail   = `: word count `failed''
end
