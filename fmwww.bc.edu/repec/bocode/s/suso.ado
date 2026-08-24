*! suso v1.7.26 build 2026-08-21-SUITETRIAGE  (suite-wide triage navigation; see help)
*! suso v1.6.0  18jun2026  (suso backup: full-workspace archive orchestrator (from data_backup notebook) + internal export start->poll->download helper)
*! Author: Attique Ur Rehman, Economist, The World Bank (DEC, Enterprise Surveys)
*!         attique@worldbank.org  ·  https://sites.google.com/view/attique-ur-rehman
*! The World Bank — Development Economics (DEC) · Enterprise Surveys
*! Requires: a Java 11+ runtime (check with: suso doctor) and suso.jar on the adopath.
*-------------------------------------------------------------------------------
* suso — a thin, safe Stata front-end over the Survey Solutions REST API.
*
* The heavy lifting (HTTP, JSON, loading results into the dataset) is done by
* suso.jar via -javacall-. This .ado parses syntax, builds requests, enforces
* safety checks around destructive operations, writes an audit log, paginates,
* and returns results in r().
*
* See:  help suso
*-------------------------------------------------------------------------------

* ----- Mata helpers (URL-encoding + JSON string escaping), UTF-8 byte-correct ----
capture mata: mata drop suso_urlencode()
capture mata: mata drop suso_urlencode_var()
capture mata: mata drop suso_jsonesc()
capture mata: mata drop suso_jsonesc_var()
version 14.2
mata:
mata set matastrict off

string scalar suso_urlencode(string scalar s)
{
    real scalar   i, n, c
    string scalar out, ch, hex
    hex = "0123456789ABCDEF"
    out = ""
    n   = strlen(s)                      // byte length
    for (i=1; i<=n; i++) {
        ch = substr(s, i, 1)             // one byte
        if (regexm(ch, "[A-Za-z0-9._~-]")) out = out + ch
        else {
            c   = ascii(ch)
            out = out + "%" + substr(hex, floor(c/16)+1, 1) + substr(hex, mod(c, 16)+1, 1)
        }
    }
    return(out)
}

void suso_urlencode_var(string scalar src, string scalar dst)
{
    real scalar i
    for (i=1; i<=st_nobs(); i++)
        st_sstore(i, dst, suso_urlencode(st_sdata(i, src)))
}

string scalar suso_jsonesc(string scalar s)
{
    real scalar i, c
    string scalar out, ch, hex
    out = ""
    hex = "0123456789ABCDEF"
    for (i=1; i<=strlen(s); i++) {
        ch = substr(s,i,1)
        c = ascii(ch)
        if      (c==34) out = out + "\" + char(34)
        else if (c==92) out = out + "\\"
        else if (c==8)  out = out + "\b"
        else if (c==9)  out = out + "\t"
        else if (c==10) out = out + "\n"
        else if (c==12) out = out + "\f"
        else if (c==13) out = out + "\r"
        else if (c==60) out = out + "\u003C"
        else if (c==62) out = out + "\u003E"
        else if (c==38) out = out + "\u0026"
        else if (c<32)  out = out + "\u00" + substr(hex,floor(c/16)+1,1) + ///
            substr(hex,mod(c,16)+1,1)
        else            out = out + ch
    }
    return(out)
}

void suso_jsonesc_var(string scalar src, string scalar dst)
{
    real scalar i
    for (i=1; i<=st_nobs(); i++)
        st_sstore(i, dst, suso_jsonesc(st_sdata(i, src)))
}
end

*===============================================================================
* Router
*===============================================================================
program suso, rclass
    version 14.2
    * Every routed command starts with a clean request body. Callers that need a
    * body set it after their syntax/validation checks.
    capture macro drop SUSO_BODY_REQ
    gettoken noun 0 : 0, parse(" ,")
    local noun = strlower(`"`noun'"')

    if "`noun'"=="" {
        di as txt _n "{bf:suso} — talk to Survey Solutions from Stata."
        di as txt    "  1.  {bf:suso config , server(<url>) workspace(<ws>) user(<apiuser>) password(<pw>)}"
        di as txt    "  2.  {bf:suso ping}                 {txt}(check it works)"
        di as txt    "  3.  {bf:suso examples}             {txt}(copy/paste recipes)"
        di as txt _n "Type {stata suso examples:suso examples} for ready-to-run commands, " ///
                     "{stata suso endpoints:suso endpoints} for the full list, or {help suso} for help." _n
        exit
    }
    if inlist("`noun'","help","?") {
        capture help suso
        if _rc di as txt "suso — install suso.sthlp, then:  {bf:help suso}   (or {bf:suso examples})"
        exit
    }
    if inlist("`noun'","examples","example","recipes","cheatsheet","cheat") {
        _suso_examples
        exit
    }
    if inlist("`noun'","endpoints","endpoint","commands","menu","list") {
        _suso_endpoints
        exit
    }

    * single-word commands
    if "`noun'"=="login" {
        _suso_prompt
        exit
    }
    if "`noun'"=="backup" {
        _suso_backup `macval(0)'
        return add
        exit
    }
    if inlist("`noun'","config","doctor","ping","raw","version","about") {
        if "`noun'"=="version" | "`noun'"=="about" {
            _suso_about
            return add
            exit
        }
        _suso_`noun' `macval(0)'
        return add
        exit
    }

    * normalise plural nouns
    if "`noun'"=="assignments"   local noun assignment
    if "`noun'"=="interviews"    local noun interview
    if "`noun'"=="questionnaires" local noun questionnaire
    if "`noun'"=="exports"       local noun export
    if "`noun'"=="users"         local noun user
    if "`noun'"=="supervisors"   local noun supervisor
    if "`noun'"=="interviewers"  local noun interviewer
    if "`noun'"=="workspaces"    local noun workspace
    if "`noun'"=="setting"       local noun settings
    if "`noun'"=="statistic" | "`noun'"=="stats" local noun statistics
    if "`noun'"=="map"           local noun maps
    if "`noun'"=="para"          local noun paradata

    if !inlist("`noun'","assignment","interview","questionnaire","export","user","maps") ///
     & !inlist("`noun'","supervisor","interviewer","workspace","settings","statistics","paradata") {
        di as err "suso: unknown subcommand '`noun''.  See {help suso}."
        exit 198
    }

    _suso_`noun' `macval(0)'
    return add
end

*===============================================================================
* Configuration
*===============================================================================
program _suso_config, rclass
    version 14.2
    syntax [, SERVER(string) Workspace(string) User(string) Password(string)   ///
        TOKEN(string) AUTH(string) JAR(string) PROXYHost(string)               ///
        PROXYPort(integer 0) PROXYUser(string) PROXYPass(string)               ///
        INSECURE NOINSECURE CONNTimeout(integer 0) READTimeout(integer 0)      ///
        MAXrows(integer 0) AUDITfile(string) GUID(string) QVER(integer 0)      ///
        EXPORTPw(string) SHOW CLEAR ]

    if "`insecure'"!="" & "`noinsecure'"!="" {
        di as err "suso config: specify only one of insecure or noinsecure."
        exit 198
    }

    if "`clear'"!="" {
        capture macro drop SUSO_BASE SUSO_WS SUSO_USER SUSO_PWD SUSO_TOKEN          ///
            SUSO_AUTHTYPE SUSO_PROXYHOST SUSO_PROXYPORT SUSO_PROXYUSER SUSO_PROXYPWD ///
            SUSO_INSECURE SUSO_CONNTO SUSO_READTO SUSO_MAXROWS SUSO_AUDIT            ///
            SUSO_GUID SUSO_QVER SUSO_EXPORTPWD SUSO_JAR
        di as txt "suso: configuration cleared for this session."
        exit
    }

    if "`server'"!="" {
        local server = trim("`server'")
        if substr("`server'", -1, 1)=="/" local server = substr("`server'", 1, length("`server'")-1)
        global SUSO_BASE "`server'"
    }
    if "`workspace'"!="" global SUSO_WS       "`workspace'"
    if "`user'"!=""      global SUSO_USER     "`user'"
    if "`password'"!=""  global SUSO_PWD      "`password'"
    if "`token'"!=""     global SUSO_TOKEN    "`token'"
    if "`auth'"!=""      global SUSO_AUTHTYPE = strlower("`auth'")
    if "`jar'"!=""       global SUSO_JAR      "`jar'"
    if "`proxyhost'"!="" global SUSO_PROXYHOST "`proxyhost'"
    if `proxyport'>0     global SUSO_PROXYPORT "`proxyport'"
    if "`proxyuser'"!="" global SUSO_PROXYUSER "`proxyuser'"
    if "`proxypass'"!="" global SUSO_PROXYPWD  "`proxypass'"
    if "`insecure'"!=""  global SUSO_INSECURE  "1"
    if "`noinsecure'"!="" global SUSO_INSECURE "0"
    * These options and the Java backend both use milliseconds. Do not scale
    * them again here (older builds accidentally multiplied them by 1,000).
    if `conntimeout'>0   global SUSO_CONNTO  "`conntimeout'"
    if `readtimeout'>0   global SUSO_READTO  "`readtimeout'"
    if `maxrows'>0       global SUSO_MAXROWS "`maxrows'"
    if "`auditfile'"!="" global SUSO_AUDIT   "`auditfile'"
    if "`guid'"!=""      global SUSO_GUID    "`guid'"
    if `qver'>0          global SUSO_QVER    "`qver'"
    if `"`exportpw'"'!="" global SUSO_EXPORTPWD `"`exportpw'"'   // export-archive password

    _suso_init

    if "`insecure'"!="" {
        di as err "suso: WARNING — TLS certificate-chain verification is DISABLED for this session."
        di as err "      Hostname matching remains enabled; this mode is scoped to suso's HTTP client."
        di as err "      Use this only as a last resort behind the corporate proxy. Prefer importing"
        di as err "      the WBG root CA into your Stata JVM trust store (see the README)."
    }

    if "`show'"!="" | trim(`"`server'`workspace'`user'`password'`token'`auth'`jar'`proxyhost'`exportpw'"')=="" {
        _suso_showconfig
    }
end

program _suso_showconfig
    di as txt _n "{hline 62}"
    di as txt "suso configuration (this Stata session)"
    di as txt "{hline 62}"
    di as txt "  server      : " as res cond("$SUSO_BASE"=="","(not set)","$SUSO_BASE")
    di as txt "  workspace   : " as res cond("$SUSO_WS"=="","(not set)","$SUSO_WS")
    if "$SUSO_GUID"!="" {
        di as txt "  questionnaire: " as res "$SUSO_GUID" ///
            cond("$SUSO_QVER"!=""," (v$SUSO_QVER)"," (any version)")
    }
    di as txt "  auth        : " as res cond("$SUSO_AUTHTYPE"=="","basic","$SUSO_AUTHTYPE")
    di as txt "  user        : " as res cond("$SUSO_USER"=="","(not set)","$SUSO_USER")
    di as txt "  password    : " as res cond("$SUSO_PWD"=="","(not set)","********")
    if "$SUSO_TOKEN"!="" di as txt "  bearer token: " as res "********"
    if `"$SUSO_EXPORTPWD"'!="" di as txt "  export pw   : " as res "********"
    di as txt "  jar         : " as res cond("$SUSO_JAR"=="","(auto-locate on adopath)","$SUSO_JAR")
    if "$SUSO_PROXYHOST"!="" di as txt "  proxy       : " as res "$SUSO_PROXYHOST:$SUSO_PROXYPORT"
    di as txt "  TLS chain   : " as res cond("$SUSO_INSECURE"=="1","DISABLED (hostname still checked)","verified")
    di as txt "  timeouts ms : " as res "connect=$SUSO_CONNTO  read=$SUSO_READTO"
    di as txt "  list max rows: " as res "$SUSO_MAXROWS" as txt " (API list/all safety cap; not paradata/export size)"
    local af "$SUSO_AUDIT"
    if "`af'"=="" local af "`c(sysdir_personal)'suso_audit.log"
    capture confirm file `"`af'"'
    local afstate = cond(_rc,"not present; paradata/read-only commands do not write it","exists")
    di as txt "  destructive audit destination: " as res `"`af'"'
    di as txt "  audit status: " as res "`afstate'"
    di as txt "{hline 62}"
end

program _suso_about, rclass
    di as txt _n "{hline 66}"
    di as txt "  suso  v1.7.26 (build 2026-08-21-SUITETRIAGE)  —  Survey Solutions REST API client for Stata"
    di as txt "{hline 66}"
    di as txt "  Author       : Attique Ur Rehman, Economist, The World Bank"
    di as txt "                 Development Economics (DEC) · Enterprise Surveys"
    di as txt "  Email        : attique@worldbank.org"
    di as txt "  Web          : https://sites.google.com/view/attique-ur-rehman"
    di as txt "{hline 66}"
    di as txt "  Java backend : suso.jar (requires a Java 11+ runtime)"
    di as txt "  Help         : {help suso}        Diagnostics: {stata suso doctor:suso doctor}"
    di as txt "{hline 66}"
    return local version "1.7.26"
    return local build "2026-08-21-SUITETRIAGE"
    return local expected_backend "1.7.11-AUDITFIX"
end

*===============================================================================
* Diagnostics
*===============================================================================
program _suso_doctor, rclass
    version 14.2
    syntax [, STRICT]
    local ok 1
    local backend ""
    local javaver ""
    di as txt _n "{hline 62}"
    di as txt "suso doctor — environment check"
    di as txt "{hline 62}"
    di as txt "Stata"
    di as txt "  ado code build : " as res "1.7.26-SUITETRIAGE"
    di as txt "  version       : " as res "`c(flavor)' `c(stata_version)'"
    di as txt "  sysdir PLUS   : " as res "`c(sysdir_plus)'"
    di as txt "  sysdir PERSON : " as res "`c(sysdir_personal)'"

    di as txt "Java backend"
    capture _suso_jar
    if _rc {
        local ok 0
        di as err "  suso.jar      : NOT FOUND — put it on the adopath or set -suso config , jar(...)-"
    }
    else {
        di as txt "  suso.jar      : " as res "$SUSO_JAR"
        capture noisily javacall org.worldbank.suso.Stata jvm , classpath("$SUSO_JAR")
        if _rc {
            local ok 0
            di as err "  javacall      : FAILED (rc=`=_rc') — is Java available to Stata? See {help java}."
        }
        else if "$SUSO_JAVAOK"=="1" {
            local backend "$SUSO_JARBUILD"
            local javaver "$SUSO_JAVAVER"
            di as txt "  Java 11+      : " as res "yes  ($SUSO_JAVAVER)"
            di as txt "  backend build : " as res cond("$SUSO_JARBUILD"=="","(not reported)","$SUSO_JARBUILD")
            if "$SUSO_JARBUILD"!="1.7.11-AUDITFIX" {
                local ok 0
                di as err "  WARNING       : suso.ado and suso.jar are from different builds."
                di as err "                  Reinstall both files from the same v1.7.26 package, then restart Stata."
            }
        }
        else {
            local ok 0
            local javaver "$SUSO_JAVAVER"
            di as err "  Java 11+      : NO ($SUSO_JAVAVER) — PATCH operations require Java 11 or newer."
        }
    }
    _suso_showconfig
    return scalar ok = `ok'
    return local ado_build "1.7.26-SUITETRIAGE"
    return local backend_build "`backend'"
    return local java_version "`javaver'"
    capture macro drop SUSO_JAVAVER SUSO_JAVAOK SUSO_JARBUILD
    if "`strict'"!="" & !`ok' exit 459
end

program _suso_ping, rclass
    version 14.2
    syntax [, VERBOSE]
    _suso_call , method(GET) path(/api/v2/export) query(limit=1) `verbose'
    di as txt "suso: connection OK (HTTP " as res "`r(http)'" as txt ") to $SUSO_BASE/$SUSO_WS"
    return add
end

*===============================================================================
* Core helpers
*===============================================================================
program _suso_init
    if "$SUSO_AUTHTYPE"=="" global SUSO_AUTHTYPE "basic"
    if "$SUSO_CONNTO"==""   global SUSO_CONNTO   "30000"
    if "$SUSO_READTO"==""   global SUSO_READTO   "300000"
    if "$SUSO_MAXROWS"==""  global SUSO_MAXROWS  "100000"
    if "$SUSO_PWD"=="" & "$SUSO_TOKEN"=="" {
        local e : environment SUSO_PASSWORD
        if "`e'"!="" global SUSO_PWD "`e'"
    }
    * Ask for the API user/password if they were never supplied (basic auth only).
    if "$SUSO_AUTHTYPE"=="basic" & "$SUSO_TOKEN"=="" & ("$SUSO_USER"=="" | "$SUSO_PWD"=="") {
        _suso_prompt , user("$SUSO_USER")
    }
end

program _suso_prompt, rclass
    syntax [ , USER(string) ]
    _suso_jar
    mata: st_global("SUSO_PROMPT_USER", st_local("user"))
    capture noisily javacall org.worldbank.suso.Stata prompt , classpath("$SUSO_JAR")
    local jrc = _rc
    capture macro drop SUSO_PROMPT_USER
    if `jrc' {
        di as err "suso: credential prompt could not run (rc=`jrc')."
        di as err "      Set them directly:  suso config , user(<name>) password(<pw>)"
        exit `jrc'
    }
    if "$SUSO_RC"!="0" {
        local m "$SUSO_MSG"
        if "`m'"=="" local m "credential prompt cancelled"
        capture macro drop SUSO_RC SUSO_MSG
        di as err "suso: `m'"
        exit 198
    }
    capture macro drop SUSO_RC SUSO_MSG
    di as txt "suso: signed in as " as res "$SUSO_USER" as txt "."
end

program _suso_unzip, rclass
    syntax , FILE(string) [ DIR(string) PWD(string) ]
    _suso_jar
    * default destination: a folder named after the archive, beside it
    if `"`dir'"' == "" {
        local k = strrpos(`"`file'"', ".")
        if `k' > 0 local dir = substr(`"`file'"', 1, `k'-1)
        else       local dir `"`file'"'
    }
    mata: st_global("SUSO_ZIP_FILE", st_local("file"))
    mata: st_global("SUSO_ZIP_DIR",  st_local("dir"))
    mata: st_global("SUSO_ZIP_PWD",  st_local("pwd"))
    capture noisily javacall org.worldbank.suso.Stata unzip , classpath("$SUSO_JAR")
    local jrc = _rc
    capture macro drop SUSO_ZIP_FILE SUSO_ZIP_DIR SUSO_ZIP_PWD
    if `jrc' {
        di as err "suso: unzip bridge failed (rc=`jrc')."
        exit `jrc'
    }
    local rc = real("$SUSO_RC")
    if `rc'!=0 & !missing(`rc') {
        local m "$SUSO_MSG"
        if "`m'"=="" local m "unzip failed"
        capture macro drop SUSO_RC SUSO_MSG SUSO_UNZIP_N SUSO_UNZIP_DIR
        di as err "suso: `m'"
        exit `rc'
    }
    if "$SUSO_MSG"!="" di as txt "suso: $SUSO_MSG"
    di as txt "suso: extracted " as res "$SUSO_UNZIP_N" as txt " file(s) to " as res `"$SUSO_UNZIP_DIR"'
    return local unzipdir `"$SUSO_UNZIP_DIR"'
    return scalar nfiles = real("$SUSO_UNZIP_N")
    capture macro drop SUSO_RC SUSO_MSG SUSO_UNZIP_N SUSO_UNZIP_DIR
end

program _suso_gql, rclass
    syntax [ , TODATA NODEpath(string) VERBOSE ]
    _suso_init
    _suso_jar
    if "$SUSO_BASE"=="" {
        di as err "suso: no server configured.  suso config , server(<url>) workspace(<name>)"
        exit 198
    }
    * Body / operations / file / name are passed by the caller as SUSO_GQL_* globals
    * (set via mata to avoid macro-expansion of JSON braces and quotes).
    mata: st_global("SUSO_GQL_NODEPATH",   st_local("nodepath"))
    global SUSO_GQL_TODATA = cond("`todata'"!="","1","0")
    global SUSO_VERBOSE    = cond("`verbose'"!="","1","0")
    tempfile __suso_prior_gql
    local __suso_hadprior 0
    if "`todata'"!="" {
        capture quietly save `"`__suso_prior_gql'"'
        if !_rc local __suso_hadprior 1
        clear
    }
    capture noisily javacall org.worldbank.suso.Stata gql , classpath("$SUSO_JAR")
    local jrc = _rc
    local rc    "$SUSO_RC"
    local http  "$SUSO_HTTP"
    local msg   `"$SUSO_MSG"'
    local nobs  "$SUSO_NOBS"
    local nvars "$SUSO_NVARS"
    local total "$SUSO_TOTALCOUNT"
    local fkeys "$SUSO_FKEYS"
    foreach k of local fkeys {
        local F_`k' `"${SUSO_F_`k'}"'
    }
    capture macro drop SUSO_GQL_BODY SUSO_GQL_OPERATIONS SUSO_GQL_MAP SUSO_UP_FILE ///
        SUSO_UP_NAME SUSO_GQL_NODEPATH SUSO_GQL_TODATA SUSO_VERBOSE
    if `jrc' {
        if `__suso_hadprior' capture quietly use `"`__suso_prior_gql'"', clear
        di as err "suso: the Java call failed (Stata rc=`jrc'). See:  suso doctor"
        exit `jrc'
    }
    if "`rc'"=="" {
        if `__suso_hadprior' capture quietly use `"`__suso_prior_gql'"', clear
        di as err "suso: no response from the Java backend."
        exit 459
    }
    if "`rc'"!="0" {
        if `__suso_hadprior' capture quietly use `"`__suso_prior_gql'"', clear
        di as err `"suso: `macval(msg)'"'
        exit 459
    }
    if "`todata'"!="" {
        if "`nobs'"!=""  return scalar nobs  = real("`nobs'")
        if "`nvars'"!="" return scalar nvars = real("`nvars'")
        if "`total'"!="" return scalar totalcount = real("`total'")
    }
    foreach k of local fkeys {
        return local `k' `"`F_`k''"'
    }
    return local http "`http'"
    capture macro drop SUSO_RC SUSO_HTTP SUSO_MSG SUSO_BODY SUSO_NOBS SUSO_NVARS SUSO_TOTALCOUNT SUSO_FKEYS
    local gl : all globals
    foreach g of local gl {
        if substr("`g'",1,7)=="SUSO_F_" capture macro drop `g'
    }
end

program _suso_maps, rclass
    version 14.2
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")

    if "`verb'"=="list" {
        syntax [ , WORKSPACE(string) PAGESize(integer 100) VERBOSE ]
        if "`workspace'"=="" local workspace "$SUSO_WS"
        if `"`workspace'"'=="" {
            di as err "suso maps: no workspace set. Run:  suso config , workspace(<name>)"
            di as err "           or add  workspace(<name>)  to this command."
            exit 198
        }
        _suso_maps_fetch , workspace(`"`workspace'"') pagesize(`pagesize') `verbose'
        local got   = r(nobs)
        local total = r(totalcount)
        local extra ""
        if "`total'"!="" & "`total'"!="." local extra " (of `total' on server)"
        di as txt "suso: fetched " as res "`got'" as txt " map(s)`extra'."
        return scalar nobs = `got'
        if "`total'"!="" & "`total'"!="." return scalar totalcount = `total'
        exit
    }
    if "`verb'"=="upload" {
        syntax , FILE(string) [ NAME(string) WORKSPACE(string) VERBOSE ]
        if "`workspace'"=="" local workspace "$SUSO_WS"
        if `"`workspace'"'=="" {
            di as err "suso maps: no workspace set. Run:  suso config , workspace(<name>)"
            di as err "           or add  workspace(<name>)  to this command."
            exit 198
        }
        _suso_jsonesc `"`workspace'"'
        local jws `"`r(js)'"'
        local fn `"`name'"'
        if `"`fn'"' == "" {
            local f2 = subinstr(`"`file'"', "\", "/", .)
            local k  = strrpos(`"`f2'"', "/")
            if `k' > 0 local fn = substr(`"`f2'"', `k'+1, .)
            else       local fn `"`f2'"'
        }
        * Survey Solutions uploadMap takes a .zip archive (shapefile family / GeoTIFF / TPK).
        local ops `"{"query":"mutation(__DOLLAR__file:Upload!,__DOLLAR__workspace:String){uploadMap(file:__DOLLAR__file,workspace:__DOLLAR__workspace){fileName size shapeType wkid importDateUtc}}","variables":{"file":null,"workspace":"`jws'"}}"'
        mata: st_global("SUSO_GQL_BODY",       "")
        mata: st_global("SUSO_GQL_OPERATIONS", st_local("ops"))
        mata: st_global("SUSO_UP_FILE",        st_local("file"))
        mata: st_global("SUSO_UP_NAME",        st_local("fn"))
        _suso_gql , `verbose'
        local h = r(http)
        di as txt "suso: uploaded " as res `"`fn'"' as txt " to workspace " as res "`workspace'" as txt " (HTTP `h')."
        return scalar http = `h'
        exit
    }
    if "`verb'"=="delete" {
        syntax , NAME(string) [ WORKSPACE(string) CONFIRM VERBOSE ]
        if "`workspace'"=="" local workspace "$SUSO_WS"
        if `"`workspace'"'=="" {
            di as err "suso maps: no workspace set. Run:  suso config , workspace(<name>)"
            di as err "           or add  workspace(<name>)  to this command."
            exit 198
        }
        _suso_block , action("DELETE map `name' from workspace `workspace' (irreversible)") `confirm'
        _suso_maps_del1 , workspace(`"`workspace'"') name(`"`name'"') `verbose'
        local h = r(http)
        _suso_audit , action("map delete") target("`name'") http("`h'")
        di as txt "suso: deleted map " as res "`name'" as txt " (HTTP `h')."
        return scalar http = `h'
        exit
    }
    if "`verb'"=="deleteall" {
        syntax [ , WORKSPACE(string) Iknowthis(string) SLEEP(integer 200) PAGESize(integer 100) DRYrun VERBOSE ]
        if "`workspace'"=="" local workspace "$SUSO_WS"
        if `"`workspace'"'=="" {
            di as err "suso maps: no workspace set. Run:  suso config , workspace(<name>)"
            di as err "           or add  workspace(<name>)  to this command."
            exit 198
        }
        preserve
        _suso_maps_fetch , workspace(`"`workspace'"') pagesize(`pagesize') `verbose'
        local N = r(nobs)
        if `N'==0 {
            di as txt "suso maps: workspace " as res "`workspace'" as txt " has no maps — nothing to delete."
            restore
            exit
        }
        * Two-phase safety (mirrors the wipe notebook): a dry run unless the user
        * confirms by typing the workspace name in iknowthis().
        local doit = 0
        if "`dryrun'"=="" & `"`iknowthis'"'==`"`workspace'"' local doit = 1
        if `doit'==0 {
            di as txt _n "{hline 64}"
            di as txt "  suso maps deleteall   —   DRY RUN (nothing deleted)"
            di as txt "{hline 64}"
            di as txt "  Workspace : " as res "`workspace'"
            di as txt "  Maps      : " as res "`N'" as txt " would be permanently deleted."
            local show = min(`N',8)
            di as txt "  Sample    :"
            forvalues i = 1/`show' {
                di as txt "      " as res `"`=fileName[`i']'"'
            }
            if `N' > `show' di as txt "      ... and " as res "`=`N'-`show''" as txt " more."
            di as err _n "  This is IRREVERSIBLE. To delete ALL `N' map(s), type the workspace name:"
            di as err "      suso maps deleteall , iknowthis(`workspace')"
            restore
            exit
        }
        di as txt "suso maps: deleting " as res "`N'" as txt " map(s) from workspace " as res "`workspace'" as txt " ..."
        local ok = 0
        local fail = 0
        forvalues i = 1/`N' {
            local fn = fileName[`i']
            capture _suso_maps_del1 , workspace(`"`workspace'"') name(`"`fn'"')
            if _rc local ++fail
            else   local ++ok
            if mod(`i',100)==0 di as txt "  ... `i'/`N'   (" as res "`ok'" as txt " ok, " as res "`fail'" as txt " failed)"
            if `sleep' > 0 sleep `sleep'
        }
        _suso_audit , action("maps deleteall") target("`workspace' (`ok'/`N' deleted)") http("")
        local fx ""
        if `fail' > 0 local fx " — `fail' failed (re-run  suso maps list  to see any stragglers)"
        di as txt _n "suso maps: deleted " as res "`ok'" as txt " of `N' map(s) from " as res "`workspace'" as txt "`fx'."
        restore
        return scalar deleted = `ok'
        return scalar failed  = `fail'
        return scalar total   = `N'
        exit
    }
    if inlist("`verb'","assign","unassign") {
        syntax , NAME(string) USER(string) [ WORKSPACE(string) VERBOSE ]
        if "`workspace'"=="" local workspace "$SUSO_WS"
        if `"`workspace'"'=="" {
            di as err "suso maps: no workspace set. Run:  suso config , workspace(<name>)"
            di as err "           or add  workspace(<name>)  to this command."
            exit 198
        }
        if "`verb'"=="assign" {
            local mut  "addUserToMap"
            local prep "to"
        }
        else {
            local mut  "deleteUserFromMap"
            local prep "from"
        }
        _suso_jsonesc `"`name'"'
        local jn  `"`r(js)'"'
        _suso_jsonesc `"`user'"'
        local ju  `"`r(js)'"'
        _suso_jsonesc `"`workspace'"'
        local jws `"`r(js)'"'
        local body `"{"query":"mutation(__DOLLAR__fileName:String!,__DOLLAR__userName:String!,__DOLLAR__workspace:String){`mut'(fileName:__DOLLAR__fileName,userName:__DOLLAR__userName,workspace:__DOLLAR__workspace){fileName}}","variables":{"fileName":"`jn'","userName":"`ju'","workspace":"`jws'"}}"'
        mata: st_global("SUSO_GQL_BODY",       st_local("body"))
        mata: st_global("SUSO_GQL_OPERATIONS", "")
        mata: st_global("SUSO_UP_FILE",        "")
        _suso_gql , `verbose'
        local h = r(http)
        di as txt "suso: map " as res "`name'" as txt " `verb'ed `prep' user " as res "`user'" as txt " (HTTP `h')."
        return scalar http = `h'
        exit
    }
    di as err "suso maps: unknown action '`verb''.  See {help suso}."
    exit 198
end

program _suso_maps_fetch, rclass
    * Load ALL maps in a workspace into memory (paginating with skip), since the
    * server caps a page at ~100. Returns r(nobs) and r(totalcount).
    syntax , WORKSPACE(string) [ PAGESize(integer 100) VERBOSE ]
    _suso_jsonesc `"`workspace'"'
    local jws `"`r(js)'"'
    tempfile acc
    local skip    = 0
    local total   = .
    local haveacc = 0
    local page    = 0
    while 1 {
        local page = `page' + 1
        local body `"{"query":"query(__DOLLAR__workspace:String,__DOLLAR__take:Int,__DOLLAR__skip:Int){maps(workspace:__DOLLAR__workspace,take:__DOLLAR__take,skip:__DOLLAR__skip){totalCount nodes{fileName size shapeType shapesCount wkid importDateUtc uploadedBy}}}","variables":{"workspace":"`jws'","take":`pagesize',"skip":`skip'}}"'
        mata: st_global("SUSO_GQL_BODY",       st_local("body"))
        mata: st_global("SUSO_GQL_OPERATIONS", "")
        mata: st_global("SUSO_UP_FILE",        "")
        _suso_gql , todata nodepath(maps.nodes) `verbose'
        local n = r(nobs)
        if "`r(totalcount)'"!="" & "`r(totalcount)'"!="." local total = r(totalcount)
        if `n'==0 continue, break
        if `haveacc' append using `acc'
        quietly save `acc', replace
        local haveacc = 1
        local skip = `skip' + `n'
        if `total'!=. & `skip' >= `total' continue, break
        if `page' >= 2000 continue, break
    }
    if `haveacc' use `acc', clear
    else clear
    return scalar nobs = _N
    if `total'!=. return scalar totalcount = `total'
end

program _suso_maps_del1, rclass
    * Delete one map (deleteMap GraphQL mutation). No interactive guard — callers
    * (suso maps delete / deleteall) handle confirmation. Returns r(http).
    syntax , WORKSPACE(string) NAME(string) [ VERBOSE ]
    _suso_jsonesc `"`name'"'
    local jn  `"`r(js)'"'
    _suso_jsonesc `"`workspace'"'
    local jws `"`r(js)'"'
    local body `"{"query":"mutation(__DOLLAR__workspace:String,__DOLLAR__fileName:String!){deleteMap(workspace:__DOLLAR__workspace,fileName:__DOLLAR__fileName){fileName}}","variables":{"workspace":"`jws'","fileName":"`jn'"}}"'
    mata: st_global("SUSO_GQL_BODY",       st_local("body"))
    mata: st_global("SUSO_GQL_OPERATIONS", "")
    mata: st_global("SUSO_UP_FILE",        "")
    _suso_gql , `verbose'
    return scalar http = r(http)
end

program _suso_export_get, rclass
    * Start one export, poll to completion, download it. Errors (exit 459) on
    * failure/timeout so callers can wrap in capture. A Completed job with no
    * data file returns r(status)=="NoFile" (not an error). Mirrors the backup
    * notebook's start_export / wait_for_export / download_export chain.
    syntax , TYPE(string) SAVING(string) [ GUID(string) QVER(integer 0)         ///
        ISTATUS(string) FROM(string) TO(string) REDUCED META NOMETA             ///
        POLLSecs(integer 10) JOBTimeout(integer 3600) replace VERBOSE ]
    if "`istatus'"=="" local istatus "All"
    local metaopt = cond("`nometa'"!="","nometa","meta")
    local redopt  = cond("`reduced'"!="","paradatareduced","")
    suso export start , type(`type') guid(`guid') qver(`qver') istatus(`istatus') ///
        from(`from') to(`to') `redopt' `metaopt' `verbose'
    local jid `"`r(jobid)'"'
    if `"`jid'"'=="" {
        di as err "suso: export start returned no JobId."
        exit 459
    }
    local elapsed = 0
    local status  ""
    local hasfile "true"
    while 1 {
        suso export status , id(`jid') `verbose'
        local status  `"`r(exportstatus)'"'
        local hasfile `"`r(hasexportfile)'"'
        if "`status'"=="Completed" continue, break
        if inlist("`status'","Fail","Failed","Canceled","Cancelled") {
            di as err "suso: export job `jid' `status'."
            exit 459
        }
        if `elapsed' >= `jobtimeout' {
            di as err "suso: export job `jid' timed out after `jobtimeout's (status=`status')."
            exit 459
        }
        sleep `=`pollsecs'*1000'
        local elapsed = `elapsed' + `pollsecs'
    }
    * Completed but no data for this type -> nothing to download (not a failure).
    if inlist(lower(`"`hasfile'"'),"false","0","no") {
        return local saved  ""
        return scalar jobid = `jid'
        return local status "NoFile"
        exit
    }
    capture suso export download , id(`jid') saving(`"`saving'"') `replace' `verbose'
    if _rc {
        * the /file endpoint can 403/404 for a beat right after Completed: retry once
        sleep 2000
        suso export download , id(`jid') saving(`"`saving'"') `replace' `verbose'
    }
    return local saved  `"`r(saved)'"'
    return scalar jobid = `jid'
    return local status "`status'"
end

program _suso_backup, rclass
    * Full-workspace backup (mirrors data_backup_SuSo notebook), built entirely
    * on existing suso verbs:
    *   questionnaires/  questionnaires_list.dta + <title>_v<ver>_document.json
    *   exports/         <title>_v<ver>_<TYPE>.zip  (one per questionnaire x type)
    *   workspace/       assignments.dta, supervisors.dta
    version 14.2
    syntax , DIR(string) [ TYPEs(string) ISTATUS(string) NOMETA                  ///
        POLLSecs(integer 10) JOBTimeout(integer 3600)                            ///
        NOExports NOQuestionnaires NOWorkspace VERBOSE ]

    if "$SUSO_BASE"=="" | "$SUSO_WS"=="" {
        di as err "suso backup: configure first.  suso config , server(<url>) workspace(<name>)"
        exit 198
    }
    if `"`types'"'=="" local types "STATA"
    if "`istatus'"=="" local istatus "All"
    local metaopt = cond("`nometa'"!="","nometa","meta")

    local dir = subinstr(`"`dir'"', "\", "/", .)
    if substr(`"`dir'"',-1,1)=="/" local dir = substr(`"`dir'"',1,length(`"`dir'"')-1)
    capture mkdir `"`dir'"'
    capture mkdir `"`dir'/exports"'
    capture mkdir `"`dir'/questionnaires"'
    capture mkdir `"`dir'/workspace"'

    di as txt "{hline 66}"
    di as txt "suso backup:  " as res "$SUSO_BASE/$SUSO_WS" as txt "  ->  " as res `"`dir'"'
    di as txt "{hline 66}"

    preserve
    local nok   = 0
    local nfail = 0
    local nskip = 0

    * ---- questionnaires: list metadata ----
    local haveq = 0
    capture suso questionnaire list , all
    if _rc {
        di as err "  questionnaires: list FAILED (rc=`=_rc') — skipping documents & exports."
        local ++nfail
    }
    else {
        local haveq = 1
        quietly save `"`dir'/questionnaires/questionnaires_list.dta"', replace
        di as txt "  questionnaires: " as res "`=_N'" as txt " version(s)"
    }

    * ---- per-version: document + exports (none of these clobber the dataset) ----
    if `haveq' {
        local nq = _N
        forvalues i = 1/`nq' {
            local guid  = QuestionnaireId[`i']
            local ver   = Version[`i']
            local title = Title[`i']
            local tag = ustrregexra(`"`title'"', "[^A-Za-z0-9._-]+", "_")
            local tag = ustrregexra(`"`tag'"', "^_+|_+$", "")
            if "`tag'"=="" local tag "questionnaire"
            if length(`"`tag'"') > 40 local tag = substr(`"`tag'"',1,40)
            local gid = lower(subinstr("`guid'","-","",.))
            * The GUID makes filenames collision-proof when titles/versions match.
            local stub "`tag'_`gid'_v`ver'"

            if "`noquestionnaires'"=="" {
                capture suso questionnaire document , guid(`guid') qver(`ver') saving(`"`dir'/questionnaires/`stub'_document.json"') replace
                if _rc local ++nfail
            }
            if "`noexports'"=="" {
                foreach et of local types {
                    local dest `"`dir'/exports/`stub'_`et'.zip"'
                    di as txt "  export: " as res "`stub' [`et']" as txt " ..."
                    capture _suso_export_get , type(`et') guid(`guid') qver(`ver') ///
                        istatus(`istatus') `metaopt' pollsecs(`pollsecs')          ///
                        jobtimeout(`jobtimeout') saving(`"`dest'"') replace `verbose'
                    if _rc {
                        local ++nfail
                        di as err "    FAILED (rc=`=_rc')"
                    }
                    else if `"`r(status)'"'=="NoFile" {
                        local ++nskip
                        di as txt "    no data — skipped"
                    }
                    else {
                        local ++nok
                        di as txt "    saved " as res `"`r(saved)'"'
                    }
                }
            }
        }
    }

    * ---- workspace objects (these reload the dataset, so do them last) ----
    if "`noworkspace'"=="" {
        capture suso assignment list , all
        if _rc {
            di as err "  assignments: FAILED (rc=`=_rc')"
            local ++nfail
        }
        else {
            quietly save `"`dir'/workspace/assignments.dta"', replace
            di as txt "  assignments: " as res "`=_N'" as txt " saved"
        }
        capture suso supervisor list , all
        if _rc {
            di as err "  supervisors: FAILED (rc=`=_rc')"
            local ++nfail
        }
        else {
            quietly save `"`dir'/workspace/supervisors.dta"', replace
            di as txt "  supervisors: " as res "`=_N'" as txt " saved"
        }
    }

    restore
    di as txt _n "{hline 66}"
    di as txt "suso backup: done.  " as res "`nok'" as txt " export(s) saved, "    ///
        as res "`nskip'" as txt " empty/skipped, " as res "`nfail'" as txt " failed."
    di as txt "Output: " as res `"`dir'"'
    return scalar ok      = `nok'
    return scalar skipped = `nskip'
    return scalar failed  = `nfail'
end

program _suso_jar
    if "$SUSO_JAR"=="" {
        * 1) Prefer the JAR installed beside the ado that Stata actually loaded.
        * This avoids pairing a new ado with a duplicate, stale backend.
        capture findfile suso.ado
        if !_rc {
            local ad = subinstr(`"`r(fn)'"', "\", "/", .)
            local k = strrpos(`"`ad'"', "/")
            if `k'>0 {
                local dir = substr(`"`ad'"', 1, `k')
                foreach c in `"`dir'suso.jar"' `"`dir'jar/suso.jar"' {
                    capture confirm file `"`c'"'
                    if !_rc {
                        global SUSO_JAR `"`c'"'
                        continue, break
                    }
                }
            }
        }
    }
    if "$SUSO_JAR"=="" {
        * 2) anywhere else on the adopath
        capture findfile suso.jar
        if !_rc global SUSO_JAR "`r(fn)'"
    }
    if "$SUSO_JAR"=="" {
        * 3) standard Stata folders
        foreach w in PERSONAL PLUS SITE OLDPLACE {
            capture local root : sysdir `w'
            if !_rc & `"`root'"'!="" {
                local root = subinstr(`"`root'"', "\", "/", .)
                foreach c in `"`root'suso.jar"' `"`root's/suso.jar"' `"`root'jar/suso.jar"' {
                    capture confirm file `"`c'"'
                    if !_rc {
                        global SUSO_JAR `"`c'"'
                        continue, break
                    }
                }
            }
            if "$SUSO_JAR"!="" continue, break
        }
    }
    if "$SUSO_JAR"=="" {
        di as err "suso: could not locate suso.jar."
        di as err "      Put it next to suso.ado (e.g. in `c(sysdir_plus)'s/) or run:"
        di as err "      suso config , jar(c:/full/path/to/suso.jar)"
        exit 601
    }
    * Normalize Windows backslashes to forward slashes for javacall/Java.
    mata: st_global("SUSO_JAR", subinstr(st_global("SUSO_JAR"), char(92), char(47)))
    capture confirm file "$SUSO_JAR"
    if _rc {
        di as err "suso: jar not found at:  $SUSO_JAR"
        di as err "      Fix with:  suso config , jar(c:/full/path/to/suso.jar)"
        exit 601
    }
end

* The workhorse: set bridge globals, call Java, surface results / errors in r().
* The request BODY (if any) is set by the caller in global SUSO_BODY_REQ.
program _suso_call, rclass
    version 14.2
    syntax , METHOD(string) PATH(string) [ QUERY(string) CType(string)         ///
        ACCept(string) TODATA ARRAYkey(string) SAVEfile(string)                ///
        DESTRUCTIVE ALLOW ROOT VERBOSE ]

    _suso_init
    _suso_jar

    if "$SUSO_BASE"=="" {
        di as err "suso: no server configured.  suso config , server(<url>) workspace(<name>)"
        exit 198
    }
    if "$SUSO_WS"=="" & "`root'"=="" {
        di as err "suso: no workspace configured.  suso config , workspace(<name>)"
        exit 198
    }

    global SUSO_PATH     `"`path'"'
    global SUSO_METHOD   "`method'"
    global SUSO_QUERY    `"`query'"'
    global SUSO_CTYPE    "`ctype'"
    global SUSO_ACCEPT   "`accept'"
    * Resolve a relative save path against Stata's working dir (not the JVM's, which
    * is the bundled-JDK bin folder). Absolute = starts with drive (C:), / or \.
    if `"`savefile'"' != "" {
        local _abs 0
        if substr(`"`savefile'"',2,1)==":"  local _abs 1
        if substr(`"`savefile'"',1,1)=="/"  local _abs 1
        if substr(`"`savefile'"',1,1)=="\"  local _abs 1
        if !`_abs' local savefile `"`c(pwd)'/`savefile'"'
    }
    global SUSO_SAVEFILE `"`savefile'"'
    global SUSO_ARRAYKEY "`arraykey'"
    global SUSO_TODATA   = cond("`todata'"!="","1","0")
    global SUSO_VERBOSE  = cond(("`verbose'"!="" | "$SUSO_DEBUG"=="1"),"1","0")
    global SUSO_DESTRUCTIVE       = cond("`destructive'"!="","1","0")
    global SUSO_ALLOW_DESTRUCTIVE = cond("`allow'"!="","1","0")
    if "`root'"!="" global SUSO_PATHBASE ""
    else            global SUSO_PATHBASE "/$SUSO_WS"
    * SUSO_BODY_REQ is set by the caller (may be empty). Check its length without
    * expanding it inline (the body holds double quotes / $ and would break a "..." compare).
    local _brq : copy global SUSO_BODY_REQ
    if `:length local _brq'==0 global SUSO_BODY_REQ ""

    tempfile __suso_prior_data
    local __suso_hadprior 0
    if "`todata'"!="" {
        capture quietly save `"`__suso_prior_data'"'
        if !_rc local __suso_hadprior 1
        clear
    }

    capture noisily javacall org.worldbank.suso.Stata run , classpath("$SUSO_JAR")
    local jrc = _rc

    local rc       "$SUSO_RC"
    local http     "$SUSO_HTTP"
    local msg      `"$SUSO_MSG"'
    local nobs     "$SUSO_NOBS"
    local nvars    "$SUSO_NVARS"
    local total    "$SUSO_TOTALCOUNT"
    local saved    `"$SUSO_SAVED"'
    local bytes    "$SUSO_BYTES"
    local datecols "$SUSO_DATECOLS"
    local fkeys    "$SUSO_FKEYS"
    foreach k of local fkeys {
        local F_`k' `"${SUSO_F_`k'}"'
    }

    if `jrc' {
        if `__suso_hadprior' capture quietly use `"`__suso_prior_data'"', clear
        _suso_clearbridge
        di as err "suso: the Java call failed (Stata rc=`jrc')."
        di as err "      Check suso.jar and that Stata runs Java 11+ :  suso doctor"
        exit `jrc'
    }
    if "`rc'"=="" {
        if `__suso_hadprior' capture quietly use `"`__suso_prior_data'"', clear
        _suso_clearbridge
        di as err "suso: no response from the Java backend (it may not have executed)."
        exit 459
    }
    if "`rc'"!="0" {
        if `__suso_hadprior' capture quietly use `"`__suso_prior_data'"', clear
        _suso_clearbridge
        di as err `"suso: `macval(msg)'"'
        exit 459
    }

    * ---- success ----
    if "`todata'"!="" {
        if "`datecols'"!="" capture _suso_todate `datecols'
        if "`nobs'"!=""  return scalar nobs  = real("`nobs'")
        if "`nvars'"!="" return scalar nvars = real("`nvars'")
        if "`total'"!="" return scalar totalcount = real("`total'")
    }
    if "`savefile'"!="" {
        return local saved `"`saved'"'
        if "`bytes'"!="" return scalar bytes = real("`bytes'")
    }
    foreach k of local fkeys {
        return local `k' `"`F_`k''"'
    }
    return local http "`http'"
    if `"`macval(msg)'"'!="" return local message `"`macval(msg)'"'

    _suso_clearbridge
end

program _suso_clearbridge
    capture macro drop SUSO_PATH SUSO_METHOD SUSO_QUERY SUSO_BODY_REQ SUSO_CTYPE   ///
        SUSO_ACCEPT SUSO_SAVEFILE SUSO_ARRAYKEY SUSO_TODATA SUSO_VERBOSE           ///
        SUSO_DESTRUCTIVE SUSO_ALLOW_DESTRUCTIVE SUSO_PATHBASE SUSO_RC SUSO_HTTP    ///
        SUSO_MSG SUSO_BODY SUSO_NOBS SUSO_NVARS SUSO_TOTALCOUNT SUSO_LIMIT         ///
        SUSO_OFFSET SUSO_SAVED SUSO_BYTES SUSO_DATECOLS SUSO_FKEYS
    local gl : all globals
    foreach g of local gl {
        if substr("`g'", 1, 7)=="SUSO_F_" capture macro drop `g'
    }
end

* Convert ISO-8601 string columns (flagged by the backend) to Stata %tc doubles.
program _suso_todate
    version 14.2
    foreach v of local 0 {
        capture confirm string variable `v'
        if _rc continue
        local lbl : variable label `v'
        tempvar t
        quietly gen double `t' = clock(subinstr(substr(`v',1,23),"T"," ",1), "YMDhms")
        quietly replace `t' = clock(subinstr(substr(`v',1,19),"T"," ",1), "YMDhms") ///
            if missing(`t') & `v'!=""
        quietly drop `v'
        quietly rename `t' `v'
        format `v' %tcCCYY-NN-DD_HH:MM:SS
        if `"`lbl'"'!="" label variable `v' `"`lbl'"'
    }
end

* Generic paginator. MODE is "rows" (offset=#rows skipped) or "page" (offset/page=page no.).
program _suso_getall, rclass
    version 14.2
    syntax , PATH(string) MODE(string) SIZEparam(string) PAGEparam(string)     ///
        [ BASEQ(string) MAXsize(integer 200) ARRAYkey(string) ROOT VERBOSE     ///
          ALL LIMIT(integer 0) OFFSET(integer -1) PAGE(integer -1) PAGESize(integer 0) ]

    local rootopt = cond("`root'"!="","root","")
    local vopt    = cond("`verbose'"!="","verbose","")

    local size = `pagesize'
    if `size'<=0       local size = `maxsize'
    if `size'>`maxsize' local size = `maxsize'
    if `size'<=0       local size 100

    local single 0
    if (`offset'>=0 | `page'>=0) local single 1
    if "`all'"=="" & `single'==0 local single 1

    if "`mode'"=="rows" local pos = cond(`offset'>=0, `offset', 0)
    else if `page'>=0    local pos = `page'
    else if `offset'>=0  local pos = `offset'
    else                 local pos = 1

    local maxrows = real("$SUSO_MAXROWS")
    if `maxrows'<=0 local maxrows 100000

    tempfile acc __suso_getall_prior
    local __suso_hadprior 0
    capture quietly save `"`__suso_getall_prior'"'
    if !_rc local __suso_hadprior 1
    local got 0
    local total .
    local first 1

    while (1) {
        local q "`baseq'"
        if "`q'"!="" local q "`q'&"
        local q "`q'`pageparam'=`pos'&`sizeparam'=`size'"

        capture noisily _suso_call , method(GET) path(`path') query(`q') todata ///
            arraykey(`arraykey') `rootopt' `vopt'
        if _rc {
            local callrc = _rc
            if `__suso_hadprior' capture quietly use `"`__suso_getall_prior'"', clear
            else clear
            exit `callrc'
        }
        local n = r(nobs)
        if "`n'"=="" local n 0
        if !missing(r(totalcount)) local total = r(totalcount)

        * A valid empty response has no variables, so there is no first page to
        * save as an accumulator. Return the empty dataset cleanly.
        if `first' & `n'==0 {
            return scalar nobs = 0
            if !missing(`total') return scalar totalcount = `total'
            exit
        }

        if `first' {
            quietly save `"`acc'"', replace
            local first 0
        }
        else {
            tempfile pg
            quietly save `"`pg'"', replace
            quietly use `"`acc'"', clear
            capture quietly append using `"`pg'"'
            if _rc {
                local arc = _rc
                di as err "suso: pagination failed because column types differ across pages."
                di as err "      No partial result is being returned (append rc=`arc')."
                if `__suso_hadprior' capture quietly use `"`__suso_getall_prior'"', clear
                else clear
                exit 459
            }
            quietly save `"`acc'"', replace
        }
        local got = `got' + `n'

        if `single'                                continue, break
        if `n'==0                                  continue, break
        if `limit'>0 & `got'>=`limit'              continue, break
        if `got'>=`maxrows' {
            di as txt "suso: reached safety cap of `maxrows' rows ({bf:SUSO_MAXROWS}). For very large pulls use {bf:suso export}."
            continue, break
        }
        if !missing(`total') & `got'>=`total'      continue, break

        * The server may return fewer rows than requested (it caps the page size).
        * Adopt its real page size so the next page's offset stays aligned (no gaps).
        if `n'>0 & `n'<`size' local size = `n'

        if "`mode'"=="rows" local pos = `pos' + `n'
        else                local pos = `pos' + 1
    }

    quietly use `"`acc'"', clear
    if `limit'>0 & _N>`limit' quietly keep in 1/`limit'

    return scalar nobs = _N
    if !missing(`total') return scalar totalcount = `total'
end

* ---- safety gates --------------------------------------------------------------
program _suso_block
    version 14.2
    syntax , ACTion(string) [ CONFIRM ]
    if "`confirm'"=="" {
        di as err "{hline 64}"
        di as err "DESTRUCTIVE OPERATION — not executed."
        di as err "  `action'"
        di as err " "
        di as err "  Re-run with the  {bf:, confirm}  option to actually perform it."
        di as err "{hline 64}"
        exit 1
    }
end

program _suso_block_ws
    version 14.2
    syntax , NAME(string) [ Iknowthis(string) ]
    if `"`iknowthis'"' != `"`name'"' {
        di as err "{hline 64}"
        di as err "DELETE WORKSPACE — refusing (this permanently removes ALL data in it)."
        di as err "  To proceed you must type the exact workspace name back:"
        di as err "      suso workspace delete , name(`name') iknowthis(`name')"
        di as err "{hline 64}"
        exit 1
    }
end

program _suso_audit
    version 14.2
    syntax , ACTion(string) [ TARGET(string) HTTP(string) ]
    local f "$SUSO_AUDIT"
    if "`f'"=="" local f "`c(sysdir_personal)'suso_audit.log"
    capture file open _sa using `"`f'"', write append text
    if _rc exit
    file write _sa `"`c(current_date)' `c(current_time)' | user=$SUSO_USER | $SUSO_BASE/$SUSO_WS | `action' | target=`target' | http=`http'"' _n
    file close _sa
end

* ---- tiny utilities ------------------------------------------------------------
program _suso_enc, rclass
    gettoken val : 0
    mata: st_local("___enc", suso_urlencode(st_local("val")))
    return local enc `"`___enc'"'
end

program _suso_jsonesc, rclass
    gettoken val : 0
    mata: st_local("___js", suso_jsonesc(st_local("val")))
    return local js `"`___js'"'
end

* Resolve the Headquarters workspace root used by links in paradata HTML.
* hqurl() is useful when a report is built offline; otherwise the current
* suso config server()/workspace() values are used automatically.
program _suso_para_hqbase, rclass
    version 14.2
    syntax [, HQURL(string) ]
    local base = strtrim(`"`hqurl'"')
    if `"`base'"'=="" {
        local server = strtrim(`"$SUSO_BASE"')
        local ws     = strtrim(`"$SUSO_WS"')
        while substr(`"`server'"',-1,1)=="/" & length(`"`server'"')>0 {
            local server = substr(`"`server'"',1,length(`"`server'"')-1)
        }
        while substr(`"`ws'"',1,1)=="/" & length(`"`ws'"')>0 {
            local ws = substr(`"`ws'"',2,.)
        }
        while substr(`"`ws'"',-1,1)=="/" & length(`"`ws'"')>0 {
            local ws = substr(`"`ws'"',1,length(`"`ws'"')-1)
        }
        if `"`server'"'!="" & `"`ws'"'!="" local base `"`server'/`ws'"'
    }
    while substr(`"`base'"',-1,1)=="/" & length(`"`base'"')>0 {
        local base = substr(`"`base'"',1,length(`"`base'"')-1)
    }
    if `"`base'"'!="" {
        local low = lower(`"`base'"')
        if substr(`"`low'"',1,7)!="http://" & substr(`"`low'"',1,8)!="https://" {
            di as err "suso paradata: hqurl() must start with http:// or https:// and include the workspace."
            exit 198
        }
        if strpos(`"`base'"',char(34)) | strpos(`"`base'"',char(39)) |       ///
            strpos(`"`base'"',"<") | strpos(`"`base'"',">") |              ///
            strpos(`"`base'"'," ") | strpos(`"`base'"',"?") |              ///
            strpos(`"`base'"',"#") | strpos(`"`base'"',"@") {
            di as err "suso paradata: hqurl() must be a plain Headquarters workspace URL (no credentials, quotes, spaces, query, or fragment)."
            exit 198
        }
    }
    return local url `"`base'"'
    return scalar enabled = (`"`base'"'!="")
end

* Build the interview -> assignment lookup from a Survey Solutions main export.
* The assignment number is optional: interview links still work without data().
program _suso_para_hqmap, rclass
    version 14.2
    syntax using/ , SAVing(string)
    preserve
    quietly use `"`using'"', clear
    tempvar __suso_hqassignment
    local hasassignment 0
    capture confirm string variable interview__id, exact
    if !_rc {
        capture confirm variable assignment__id, exact
        if !_rc {
            capture confirm string variable assignment__id, exact
            if !_rc quietly gen str40 `__suso_hqassignment' = substr(strtrim(assignment__id),1,40)
            else {
                capture confirm numeric variable assignment__id, exact
                if !_rc quietly gen str40 `__suso_hqassignment' = strtrim(string(assignment__id,"%21.0f")) if !missing(assignment__id)
            }
            capture confirm variable `__suso_hqassignment', exact
            if !_rc {
                local hasassignment 1
                quietly keep interview__id `__suso_hqassignment'
                quietly rename `__suso_hqassignment' hq_assignment
                quietly keep if strtrim(interview__id)!=""
                quietly duplicates drop
                tempvar __suso_hqdup
                quietly bysort interview__id: gen byte `__suso_hqdup' = _N>1
                quietly count if `__suso_hqdup'
                if r(N)>0 {
                    di as err "suso paradata: data() has conflicting assignment__id values for the same interview__id."
                    di as err "                 Supply the one-row-per-interview main export."
                    exit 459
                }
                quietly drop `__suso_hqdup'
                quietly gen byte __suso_hasa = hq_assignment!=""
                gsort interview__id -__suso_hasa hq_assignment
                quietly by interview__id: keep if _n==1
                quietly drop __suso_hasa
                quietly count if hq_assignment!=""
                if r(N)==0 local hasassignment 0
            }
        }
    }
    if !`hasassignment' {
        quietly clear
        quietly set obs 0
        quietly gen str80 interview__id = ""
        quietly gen str40 hq_assignment = ""
    }
    quietly save `"`saving'"', replace
    restore
    return scalar hasassignment = `hasassignment'
end

program _suso_isuuid, rclass
    gettoken val : 0
    local val = trim("`val'")
    if regexm("`val'","^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$") ///
        return scalar isuuid = 1
    else return scalar isuuid = 0
end

* Build "{guid}${version}" without ever putting a literal $ into a macro.
program _suso_qid, rclass
    version 14.2
    syntax , GUID(string) [ QVER(integer 0) ]
    if `qver'>0 return local qid "`guid'__DOLLAR__`qver'"
    else        return local qid "`guid'"
end

* Fill guid/qver in the CALLER from the session defaults ($SUSO_GUID/$SUSO_QVER)
* whenever the user omitted them, so the questionnaire only needs to be set once.
program _suso_gq
    args g q
    if `"`g'"'=="" & "$SUSO_GUID"!="" c_local guid "$SUSO_GUID"
    if (`"`q'"'=="" | `"`q'"'=="0") & "$SUSO_QVER"!="" c_local qver "$SUSO_QVER"
end

* Require a questionnaire (after _suso_gq); friendly message if still missing.
program _suso_needq
    args g
    if `"`g'"'=="" {
        di as err "suso: this needs a questionnaire. Either add  guid(<GUID>) qver(<ver>)  ,"
        di as err "      or set it once for the session:  suso config , guid(<GUID>) qver(<ver>)"
        di as err "      (find the GUID/version with:  suso questionnaire list )"
        exit 198
    }
end

*===============================================================================
* raw — escape hatch to call any endpoint
*===============================================================================
program _suso_raw, rclass
    version 14.2
    syntax anything(name=path id="path"), [ METHOD(string) Query(string)       ///
        CType(string) ACCept(string) TODATA ARRAYkey(string) SAVEfile(string)  ///
        BODY(string) ROOT ALLOWdestructive VERBOSE REPLACE ]
    if "`method'"=="" local method GET
    local method = strupper(strtrim("`method'"))
    if `"`body'"'!="" global SUSO_BODY_REQ `"`body'"'
    local allowopt = cond("`allowdestructive'"!="","allow","")
    * DELETE is destructive independently of whether permission was granted.
    local destopt  = cond("`method'"=="DELETE","destructive","")
    local rootopt  = cond("`root'"!="","root","")
    local vopt     = cond("`verbose'"!="","verbose","")
    local todopt   = cond("`todata'"!="","todata","")
    if `"`savefile'"'!="" & "`replace'"=="" {
        capture confirm file `"`savefile'"'
        if !_rc {
            di as err `"suso raw: savefile already exists: `savefile'"'
            di as err "          Re-run with replace to overwrite it."
            exit 602
        }
    }
    _suso_call , method(`method') path(`path') query(`query') ct(`ctype') acc(`accept') ///
        `todopt' arraykey(`arraykey') savefile(`savefile') `rootopt' `destopt' `allowopt' `vopt'
    if "`method'"=="DELETE" {
        _suso_audit , action("raw DELETE") target(`"`path'"') http("`r(http)'")
    }
    return add
end

*===============================================================================
* Assignments
*===============================================================================
program _suso_assignment, rclass
    version 14.2
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")

    if "`verb'"=="list" {
        syntax [, SEARCHby(string) GUID(string) QVER(integer 0) RESPonsible(string) ///
            SUPervisor(string) ORDer(string) ARCHIVEd ALL LIMIT(integer 0)          ///
            OFFSET(integer -1) PAGESize(integer 0) VERBOSE ]
        _suso_gq "`guid'" "`qver'"
        local q ""
        if "`searchby'"!="" {
            _suso_enc `"`searchby'"'
            local q "`q'&SearchBy=`r(enc)'"
        }
        if "`guid'"!="" {
            _suso_qid , guid(`guid') qver(`qver')
            _suso_enc `"`r(qid)'"'
            local q "`q'&QuestionnaireId=`r(enc)'"
        }
        if "`responsible'"!="" {
            _suso_enc `"`responsible'"'
            local q "`q'&Responsible=`r(enc)'"
        }
        if "`supervisor'"!=""  {
            _suso_enc `"`supervisor'"'
            local q "`q'&SupervisorId=`r(enc)'"
        }
        if "`order'"!=""       {
            _suso_enc `"`order'"'
            local q "`q'&Order=`r(enc)'"
        }
        if "`archived'"!=""    local q "`q'&ShowArchive=true"
        if substr("`q'",1,1)=="&" local q = substr("`q'",2,.)
        local vopt = cond("`verbose'"!="","verbose","")
        _suso_getall , path(/api/v1/assignments) mode(rows) sizeparam(Limit) pageparam(Offset) ///
            maxsize(200) arraykey(Assignments) baseq(`q') `all' limit(`limit') offset(`offset') ///
            pagesize(`pagesize') `vopt'
        di as txt "suso: fetched " as res "`=r(nobs)'" as txt " assignment(s)" ///
            cond(!missing(r(totalcount))," of `=r(totalcount)' on server","")
        return add
        exit
    }

    if "`verb'"=="get" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(GET) path(/api/v1/assignments/`id') `verbose'
        di as txt "Assignment " as res "`id'" as txt ":  responsible=" as res `"`r(responsiblename)'"' ///
            as txt "  quantity=" as res `"`r(quantity)'"' as txt "  done=" as res `"`r(interviewscount)'"' ///
            as txt "  archived=" as res `"`r(archived)'"'
        return add
        exit
    }

    if "`verb'"=="history" {
        syntax , ID(string) [ START(integer 0) LENGTH(integer 1000) VERBOSE ]
        _suso_call , method(GET) path(/api/v1/assignments/`id'/history)            ///
            query(start=`start'&length=`length') todata arraykey(History) `verbose'
        di as txt "suso: " as res "`=r(nobs)'" as txt " history record(s) for assignment `id'."
        return add
        exit
    }

    if "`verb'"=="quantitysettings" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(GET) path(/api/v1/assignments/`id'/assignmentQuantitySettings) `verbose'
        di as txt "Assignment `id': CanChangeQuantity=" as res `"`r(canchangequantity)'"'
        return add
        exit
    }

    if "`verb'"=="create" {
        syntax , RESPonsible(string) [ GUID(string) QVER(integer 0)             ///
            QUANTity(string) EMAIL(string) PASSword(string) WEBmode             ///
            AUDIO COMMents(string) TARGETarea(string) IDENTifying(string) VERBOSE ]
        _suso_gq "`guid'" "`qver'"
        _suso_needq "`guid'"
        _suso_qid , guid(`guid') qver(`qver')
        local qid "`r(qid)'"
        _suso_jsonesc `"`responsible'"'
        local resp "`r(js)'"
        local body `"{"Responsible":"`resp'","QuestionnaireId":"`qid'""'
        if "`quantity'"!=""   local body `"`body',"Quantity":`quantity'"'
        if "`email'"!="" {
            _suso_jsonesc `"`email'"'
            local body `"`body',"Email":"`r(js)'""'
        }
        if "`password'"!="" {
            _suso_jsonesc `"`password'"'
            local body `"`body',"Password":"`r(js)'""'
        }
        if "`webmode'"!=""    local body `"`body',"WebMode":true"'
        if "`audio'"!=""      local body `"`body',"IsAudioRecordingEnabled":true"'
        if "`comments'"!="" {
            _suso_jsonesc `"`comments'"'
            local body `"`body',"Comments":"`r(js)'""'
        }
        if "`targetarea'"!="" {
            _suso_jsonesc `"`targetarea'"'
            local body `"`body',"TargetArea":"`r(js)'""'
        }
        if `"`identifying'"'!="" local body `"`body',"IdentifyingData":`identifying'"'
        else                     local body `"`body',"IdentifyingData":[]"'
        local body `"`body'}"'
        global SUSO_BODY_REQ `"`body'"'
        _suso_call , method(POST) path(/api/v1/assignments) `verbose'
        di as txt "suso: assignment created (HTTP " as res "`r(http)'" as txt ")."
        return add
        exit
    }

    if "`verb'"=="assign" {
        syntax , ID(string) RESPonsible(string) [ VERBOSE ]
        _suso_jsonesc `"`responsible'"'
        local r "`r(js)'"
        global SUSO_BODY_REQ `"{"Responsible":"`r'"}"'
        _suso_call , method(PATCH) path(/api/v1/assignments/`id'/assign) `verbose'
        di as txt "suso: assignment `id' reassigned (HTTP " as res "`r(http)'" as txt ")."
        return add
        exit
    }

    if "`verb'"=="quantity" {
        syntax , ID(string) N(string) [ VERBOSE ]
        if !regexm("`n'","^-?[0-9]+$") {
            di as err "suso: -n()- must be an integer (use -1 for unlimited)."
            exit 198
        }
        global SUSO_BODY_REQ "`n'"
        _suso_call , method(PATCH) path(/api/v1/assignments/`id'/changeQuantity) `verbose'
        di as txt "suso: assignment `id' quantity set to " as res "`n'" as txt " (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="close" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(PATCH) path(/api/v1/assignments/`id'/close) `verbose'
        di as txt "suso: assignment `id' closed (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="archive" {
        syntax , ID(string) [ CONFIRM VERBOSE ]
        _suso_block , action("Archive assignment `id' in workspace $SUSO_WS") `confirm'
        _suso_call , method(PATCH) path(/api/v1/assignments/`id'/archive) destructive allow `verbose'
        _suso_audit , action("assignment archive") target("`id'") http("`r(http)'")
        di as txt "suso: assignment `id' archived (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="unarchive" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(PATCH) path(/api/v1/assignments/`id'/unarchive) `verbose'
        di as txt "suso: assignment `id' unarchived (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="audio" {
        syntax , ID(string) [ ON OFF VERBOSE ]
        if "`on'"!="" & "`off'"!="" {
            di as err "suso: specify only one of -on- or -off-."
            exit 198
        }
        if "`on'"=="" & "`off'"=="" {
            _suso_call , method(GET) path(/api/v1/assignments/`id'/recordAudio) `verbose'
            di as txt "Assignment `id': audio recording Enabled=" as res `"`r(enabled)'"'
            return add
            exit
        }
        local en = cond("`on'"!="","true","false")
        global SUSO_BODY_REQ `"{"Enabled":`en'}"'
        _suso_call , method(PATCH) path(/api/v1/assignments/`id'/recordAudio) `verbose'
        di as txt "suso: assignment `id' audio recording = " as res "`en'" as txt " (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="targetarea" {
        syntax , ID(string) AREA(string) [ VERBOSE ]
        _suso_jsonesc `"`area'"'
        local a "`r(js)'"
        global SUSO_BODY_REQ `""`a'""'
        _suso_call , method(POST) path(/api/v1/assignments/`id'/changeTargetArea) `verbose'
        di as txt "suso: assignment `id' target area updated (HTTP `r(http)')."
        return add
        exit
    }

    di as err "suso assignment: unknown action '`verb''.  See {help suso}."
    exit 198
end

*===============================================================================
* Interviews
*===============================================================================
program _suso_interview, rclass
    version 14.2
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")

    if "`verb'"=="list" {
        syntax [, GUID(string) QVER(integer 0) STATUS(string) ID(string)        ///
            ALL LIMIT(integer 0) PAGE(integer -1) PAGESize(integer 0) VERBOSE ]
        _suso_gq "`guid'" "`qver'"
        local q ""
        if "`guid'"!=""   local q "`q'&questionnaireId=`guid'"
        if `qver'>0       local q "`q'&questionnaireVersion=`qver'"
        if "`status'"!="" local q "`q'&status=`status'"
        if "`id'"!=""     local q "`q'&interviewId=`id'"
        if substr("`q'",1,1)=="&" local q = substr("`q'",2,.)
        local vopt = cond("`verbose'"!="","verbose","")
        _suso_getall , path(/api/v1/interviews) mode(page) sizeparam(pageSize) pageparam(page) ///
            maxsize(100) arraykey(Interviews) baseq(`q') `all' limit(`limit') page(`page')      ///
            pagesize(`pagesize') `vopt'
        di as txt "suso: fetched " as res "`=r(nobs)'" as txt " interview(s)" ///
            cond(!missing(r(totalcount))," of `=r(totalcount)' on server","")
        return add
        exit
    }

    if "`verb'"=="get" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(GET) path(/api/v1/interviews/`id') todata arraykey(Answers) `verbose'
        di as txt "suso: " as res "`=r(nobs)'" as txt " answer rows for interview `id'."
        return add
        exit
    }

    if "`verb'"=="stats" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(GET) path(/api/v1/interviews/`id'/stats) `verbose'
        di as txt "Interview `id': answered=" as res `"`r(answered)'"' as txt "  invalid=" ///
            as res `"`r(invalid)'"' as txt "  withcomments=" as res `"`r(withcomments)'"' ///
            as txt "  status=" as res `"`r(status)'"'
        return add
        exit
    }

    if "`verb'"=="history" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(GET) path(/api/v1/interviews/`id'/history) todata arraykey(Records) `verbose'
        di as txt "suso: " as res "`=r(nobs)'" as txt " history record(s) for interview `id'."
        return add
        exit
    }

    if "`verb'"=="pdf" {
        syntax , ID(string) SAVING(string) [ replace VERBOSE ]
        if "`replace'"=="" {
            capture confirm new file `"`saving'"'
            if _rc {
                di as err "suso: file already exists. Use -replace-."
                exit 602
            }
        }
        _suso_call , method(GET) path(/api/v1/interviews/`id'/pdf) savefile(`saving') accept(application/pdf) `verbose'
        di as txt "suso: saved interview PDF to " as res `"`r(saved)'"' as txt " (`r(bytes)' bytes)."
        return add
        exit
    }

    if inlist("`verb'","approve","hqapprove","hqunapprove") {
        syntax , ID(string) [ COMMENT(string) VERBOSE ]
        local q ""
        if "`comment'"!="" {
            _suso_enc `"`comment'"'
            local q "comment=`r(enc)'"
        }
        _suso_call , method(PATCH) path(/api/v1/interviews/`id'/`verb') query(`q') `verbose'
        di as txt "suso: interview `id' `verb' OK (HTTP `r(http)')."
        return add
        exit
    }

    if inlist("`verb'","reject","hqreject") {
        syntax , ID(string) [ COMMENT(string) RESPonsible(string) VERBOSE ]
        local q ""
        if "`comment'"!=""     {
            _suso_enc `"`comment'"'
            local q "comment=`r(enc)'"
        }
        if "`responsible'"!="" {
            _suso_enc `"`responsible'"'
            local q "`q'&responsibleId=`r(enc)'"
        }
        if substr("`q'",1,1)=="&" local q = substr("`q'",2,.)
        _suso_call , method(PATCH) path(/api/v1/interviews/`id'/`verb') query(`q') `verbose'
        di as txt "suso: interview `id' `verb' OK (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="assign" | "`verb'"=="assignsupervisor" {
        syntax , ID(string) [ RESPonsible(string) RESPONSIBLEID(string) RESPONSIBLEName(string) VERBOSE ]
        local rid "`responsibleid'"
        local rnm "`responsiblename'"
        if "`responsible'"!="" {
            _suso_isuuid `"`responsible'"'
            if r(isuuid) local rid "`responsible'"
            else         local rnm "`responsible'"
        }
        if "`rid'"=="" & "`rnm'"=="" {
            di as err "suso: specify responsible(), responsibleid() or responsiblename()."
            exit 198
        }
        if "`rid'"!="" global SUSO_BODY_REQ `"{"ResponsibleId":"`rid'"}"'
        else {
            _suso_jsonesc `"`rnm'"'
            global SUSO_BODY_REQ `"{"ResponsibleName":"`r(js)'"}"'
        }
        _suso_call , method(PATCH) path(/api/v1/interviews/`id'/`verb') `verbose'
        di as txt "suso: interview `id' `verb' OK (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="comment" {
        syntax , ID(string) QUESTION(string) COMMENT(string) [ VERBOSE ]
        _suso_enc `"`comment'"'
        local q "comment=`r(enc)'"
        _suso_call , method(POST) path(/api/v1/interviews/`id'/comment/`question') query(`q') `verbose'
        di as txt "suso: comment added to interview `id' (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="commentbyvar" {
        syntax , ID(string) VARiable(string) COMMENT(string) [ ROSTERvector(numlist) VERBOSE ]
        _suso_enc `"`comment'"'
        local q "comment=`r(enc)'"
        foreach rv of numlist `rostervector' {
            local q "`q'&rosterVector=`rv'"
        }
        _suso_call , method(POST) path(/api/v1/interviews/`id'/comment-by-variable/`variable') query(`q') `verbose'
        di as txt "suso: comment added to interview `id', variable `variable' (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="delete" {
        syntax , ID(string) [ CONFIRM VERBOSE ]
        _suso_block , action("DELETE interview `id' in workspace $SUSO_WS (irreversible)") `confirm'
        _suso_call , method(DELETE) path(/api/v1/interviews/`id') destructive allow `verbose'
        _suso_audit , action("interview delete") target("`id'") http("`r(http)'")
        di as txt "suso: interview `id' deleted (HTTP `r(http)')."
        return add
        exit
    }

    di as err "suso interview: unknown action '`verb''.  See {help suso}."
    exit 198
end

*===============================================================================
* Questionnaires
*===============================================================================
program _suso_questionnaire, rclass
    version 14.2
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")

    if "`verb'"=="list" {
        syntax [, ALL LIMIT(integer 0) OFFSET(integer -1) PAGESize(integer 0) VERBOSE ]
        local vopt = cond("`verbose'"!="","verbose","")
        _suso_getall , path(/api/v1/questionnaires) mode(page) sizeparam(limit) pageparam(offset) ///
            maxsize(40) arraykey(Questionnaires) `all' limit(`limit') offset(`offset')             ///
            pagesize(`pagesize') `vopt'
        di as txt "suso: fetched " as res "`=r(nobs)'" as txt " questionnaire(s)" ///
            cond(!missing(r(totalcount))," of `=r(totalcount)' on server","")
        return add
        exit
    }

    if "`verb'"=="get" {
        syntax [, GUID(string) QVER(integer 0) VERBOSE ]
        _suso_gq "`guid'" "`qver'"
        _suso_needq "`guid'"
        if `qver'>0 {
            _suso_call , method(GET) path(/api/v1/questionnaires/`guid'/`qver') `verbose'
            di as txt "Questionnaire " as res `"`r(title)'"' as txt " (v`qver'), variable=" ///
                as res `"`r(variable)'"'
        }
        else {
            _suso_call , method(GET) path(/api/v1/questionnaires/`guid') todata arraykey(Questionnaires) `verbose'
            di as txt "suso: " as res "`=r(nobs)'" as txt " version(s) of questionnaire `guid'."
        }
        return add
        exit
    }

    if "`verb'"=="document" {
        syntax , SAVING(string) [ GUID(string) QVER(integer 0) replace VERBOSE ]
        _suso_gq "`guid'" "`qver'"
        _suso_needq "`guid'"
        if `qver'<=0 {
            di as err "suso: questionnaire document needs a version: qver(<n>) (or set it via suso config)."
            exit 198
        }
        if "`replace'"=="" {
            capture confirm new file `"`saving'"'
            if _rc {
                di as err "suso: file already exists. Use -replace-."
                exit 602
            }
        }
        _suso_call , method(GET) path(/api/v1/questionnaires/`guid'/`qver'/document) savefile(`saving') `verbose'
        di as txt "suso: saved questionnaire document to " as res `"`r(saved)'"' as txt " (`r(bytes)' bytes)."
        return add
        exit
    }

    if "`verb'"=="interviews" {
        syntax [, GUID(string) QVER(integer 0) ALL LIMIT(integer 0) OFFSET(integer -1) PAGESize(integer 0) VERBOSE ]
        _suso_gq "`guid'" "`qver'"
        _suso_needq "`guid'"
        if `qver'<=0 {
            di as err "suso: questionnaire interviews needs a version: qver(<n>) (or set it via suso config)."
            exit 198
        }
        local vopt = cond("`verbose'"!="","verbose","")
        _suso_getall , path(/api/v1/questionnaires/`guid'/`qver'/interviews) mode(page)         ///
            sizeparam(limit) pageparam(offset) maxsize(200) arraykey(Interviews) `all'           ///
            limit(`limit') offset(`offset') pagesize(`pagesize') `vopt'
        di as txt "suso: fetched " as res "`=r(nobs)'" as txt " interview(s) for questionnaire `guid' v`qver'."
        return add
        exit
    }

    if "`verb'"=="audio" {
        syntax [, GUID(string) QVER(integer 0) GET ON OFF VERBOSE ]
        if ("`on'"!="" & "`off'"!="") | ("`get'"!="" & ("`on'"!="" | "`off'"!="")) {
            di as err "suso: use get, on, or off — only one at a time."
            exit 198
        }
        _suso_gq "`guid'" "`qver'"
        _suso_needq "`guid'"
        if `qver'<=0 {
            di as err "suso: questionnaire audio needs a version: qver(<n>) (or set it via suso config)."
            exit 198
        }
        if "`get'"!="" | ("`on'"=="" & "`off'"=="") {
            _suso_call , method(GET) path(/api/v1/questionnaires/`guid'/`qver'/recordAudio) `verbose'
            di as txt "Questionnaire `guid' v`qver': audio recording Enabled=" as res `"`r(enabled)'"'
        }
        else {
            local en = cond("`on'"!="","true","false")
            global SUSO_BODY_REQ `"{"Enabled":`en'}"'
            _suso_call , method(POST) path(/api/v1/questionnaires/`guid'/`qver'/recordAudio) `verbose'
            di as txt "suso: questionnaire `guid' v`qver' audio recording set to " as res "`en'" as txt " (HTTP `r(http)')."
        }
        return add
        exit
    }

    if "`verb'"=="criticality" {
        syntax [, GUID(string) QVER(integer 0) GET LEVEL(string) VERBOSE ]
        _suso_gq "`guid'" "`qver'"
        _suso_needq "`guid'"
        if `qver'<=0 {
            di as err "suso: questionnaire criticality needs a version: qver(<n>) (or set it via suso config)."
            exit 198
        }
        if "`get'"!="" | "`level'"=="" {
            _suso_call , method(GET) path(/api/v1/questionnaires/`guid'/`qver'/criticalityLevel) `verbose'
            di as txt "Questionnaire `guid' v`qver': criticality Enabled=" as res `"`r(enabled)'"'
        }
        else {
            if !inlist(strproper("`level'"),"Unknown","Ignore","Warn","Block") {
                di as err "suso: level() must be one of Unknown, Ignore, Warn, Block."
                exit 198
            }
            global SUSO_BODY_REQ `"{"CriticalityLevel":"`=strproper("`level'")'"}"'
            _suso_call , method(POST) path(/api/v1/questionnaires/`guid'/`qver'/criticalityLevel) `verbose'
            di as txt "suso: questionnaire `guid' v`qver' criticality set to " as res "`level'" as txt " (HTTP `r(http)')."
        }
        return add
        exit
    }

    di as err "suso questionnaire: unknown action '`verb''.  See {help suso}."
    exit 198
end

*===============================================================================
* Export
*===============================================================================
program _suso_export, rclass
    version 14.2
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")

    if "`verb'"=="list" {
        syntax [, TYPE(string) ISTATUS(string) GUID(string) QVER(integer 0)     ///
            ESTATUS(string) HASfile ALL LIMIT(integer 0) OFFSET(integer -1)     ///
            PAGESize(integer 0) VERBOSE ]
        _suso_gq "`guid'" "`qver'"
        local q ""
        if "`type'"!=""    local q "`q'&exportType=`type'"
        if "`istatus'"!="" local q "`q'&interviewStatus=`istatus'"
        if "`guid'"!="" {
            _suso_qid , guid(`guid') qver(`qver')
            _suso_enc `"`r(qid)'"'
            local q "`q'&questionnaireIdentity=`r(enc)'"
        }
        if "`estatus'"!="" local q "`q'&exportStatus=`estatus'"
        if "`hasfile'"!="" local q "`q'&hasFile=true"
        if substr("`q'",1,1)=="&" local q = substr("`q'",2,.)
        local vopt = cond("`verbose'"!="","verbose","")
        _suso_getall , path(/api/v2/export) mode(rows) sizeparam(limit) pageparam(offset) ///
            maxsize(200) arraykey() baseq(`q') `all' limit(`limit') offset(`offset')       ///
            pagesize(`pagesize') `vopt'
        di as txt "suso: fetched " as res "`=r(nobs)'" as txt " export job(s)."
        return add
        exit
    }

    if "`verb'"=="start" {
        syntax , TYPE(string) [ ISTATUS(string) GUID(string) QVER(integer 0)    ///
            FROM(string) TO(string) META NOMETA PARADATAReduced VERBOSE ]
        _suso_gq "`guid'" "`qver'"
        _suso_needq "`guid'"
        if `qver'<=0 {
            di as err "suso: export needs a questionnaire VERSION. Add qver(<n>) ,"
            di as err "      or set it once:  suso config , guid(<GUID>) qver(<n>)"
            exit 198
        }
        if "`istatus'"=="" local istatus All
        _suso_qid , guid(`guid') qver(`qver')
        local qid "`r(qid)'"
        local body `"{"ExportType":"`type'","QuestionnaireId":"`qid'","InterviewStatus":"`istatus'""'
        if "`from'"!="" {
            _suso_jsonesc `"`from'"'
            local body `"`body',"From":"`r(js)'""'
        }
        if "`to'"!="" {
            _suso_jsonesc `"`to'"'
            local body `"`body',"To":"`r(js)'""'
        }
        if "`meta'"!=""   local body `"`body',"IncludeMeta":true"'
        if "`nometa'"!="" local body `"`body',"IncludeMeta":false"'
        if "`paradatareduced'"!="" local body `"`body',"ParadataReduced":true"'
        local body `"`body'}"'
        global SUSO_BODY_REQ `"`body'"'
        _suso_call , method(POST) path(/api/v2/export) `verbose'
        di as txt "suso: export started — JobId=" as res `"`r(jobid)'"' as txt "  status=" ///
            as res `"`r(exportstatus)'"' as txt " (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="status" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(GET) path(/api/v2/export/`id') `verbose'
        di as txt "Export `id': status=" as res `"`r(exportstatus)'"' as txt "  progress=" ///
            as res `"`r(progress)'"' as txt "%  hasFile=" as res `"`r(hasexportfile)'"'
        return add
        exit
    }

    if "`verb'"=="get" {
        * one-shot convenience: start -> poll -> download [-> unzip]
        syntax , TYPE(string) SAVING(string) [ GUID(string) QVER(integer 0)     ///
            ISTATUS(string) FROM(string) TO(string) PARADATAReduced META NOMETA ///
            POLLSecs(integer 10) JOBTimeout(integer 3600) replace               ///
            UNZIP UNZIPW(string) UNZIPto(string) VERBOSE ]
        local redopt = cond("`paradatareduced'"!="","reduced","")
        _suso_export_get , type(`type') saving(`"`saving'"') guid(`guid')       ///
            qver(`qver') istatus(`istatus') from(`from') to(`to') `redopt'      ///
            `meta' `nometa' pollsecs(`pollsecs') jobtimeout(`jobtimeout')       ///
            `replace' `verbose'
        local gstatus `"`r(status)'"'
        local gsaved  `"`r(saved)'"'
        return add
        if "`gstatus'"=="NoFile" {
            di as txt "suso: job completed with no data file for this type/filter — nothing to download."
            exit
        }
        di as txt "suso: downloaded export to " as res `"`gsaved'"'
        if "`unzip'"!="" | `"`unzipw'"'!="" | `"`unzipto'"'!="" {
            if `"`unzipw'"'=="" local unzipw `"$SUSO_EXPORTPWD"'
            _suso_unzip , file(`"`gsaved'"') dir(`"`unzipto'"') pwd(`"`unzipw'"')
            return local unzipdir `"`r(unzipdir)'"'
            return scalar unzipped = r(nfiles)
        }
        exit
    }

    if "`verb'"=="download" {
        syntax , ID(string) SAVING(string) [ replace UNZIP UNZIPW(string) UNZIPto(string) VERBOSE ]
        if "`replace'"=="" {
            capture confirm new file `"`saving'"'
            if _rc {
                di as err "suso: file already exists. Use -replace-."
                exit 602
            }
        }
        _suso_call , method(GET) path(/api/v2/export/`id'/file) savefile(`saving') accept(application/zip) `verbose'
        di as txt "suso: downloaded export to " as res `"`r(saved)'"' as txt " (`r(bytes)' bytes)."
        local zsaved `"`r(saved)'"'
        local zhttp = r(http)
        return add
        if "`unzip'"!="" | `"`unzipw'"'!="" {
            if `"`unzipw'"'=="" local unzipw `"$SUSO_EXPORTPWD"'
            _suso_unzip , file(`"`zsaved'"') dir(`"`unzipto'"') pwd(`"`unzipw'"')
            return local unzipdir `"`r(unzipdir)'"'
            return scalar unzipped = r(nfiles)
            return scalar http = `zhttp'
        }
        exit
    }

    if "`verb'"=="cancel" {
        syntax , ID(string) [ CONFIRM VERBOSE ]
        _suso_block , action("Cancel/delete export job `id' in workspace $SUSO_WS") `confirm'
        _suso_call , method(DELETE) path(/api/v2/export/`id') destructive allow `verbose'
        _suso_audit , action("export cancel") target("`id'") http("`r(http)'")
        di as txt "suso: export job `id' cancelled (HTTP `r(http)')."
        return add
        exit
    }

    di as err "suso export: unknown action '`verb''.  See {help suso}."
    exit 198
end

*===============================================================================
* Users / Supervisors / Interviewers
*===============================================================================
program _suso_user, rclass
    version 14.2
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")

    if "`verb'"=="get" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(GET) path(/api/v1/users/`id') `verbose'
        di as txt "User " as res `"`r(username)'"' as txt ":  role=" as res `"`r(role)'"' ///
            as txt "  locked=" as res `"`r(islocked)'"' as txt "  archived=" as res `"`r(isarchived)'"'
        return add
        exit
    }

    if "`verb'"=="create" {
        syntax , ROLE(string) Username(string) Password(string) [ FULLname(string) ///
            PHONE(string) EMAIL(string) SUPERVISOR(string) VERBOSE ]
        if !inlist(strproper("`role'"),"Supervisor","Interviewer","Headquarter","Observer","Apiuser") {
            di as err "suso: role() must be Supervisor, Interviewer, Headquarter, Observer, or ApiUser."
            exit 198
        }
        local role = cond(strlower("`role'")=="apiuser","ApiUser",strproper("`role'"))
        _suso_jsonesc `"`username'"'
        local un "`r(js)'"
        _suso_jsonesc `"`password'"'
        local pw "`r(js)'"
        local body `"{"Role":"`role'","UserName":"`un'","Password":"`pw'""'
        if "`fullname'"!="" {
            _suso_jsonesc `"`fullname'"'
            local body `"`body',"FullName":"`r(js)'""'
        }
        if "`phone'"!="" {
            _suso_jsonesc `"`phone'"'
            local body `"`body',"PhoneNumber":"`r(js)'""'
        }
        if "`email'"!="" {
            _suso_jsonesc `"`email'"'
            local body `"`body',"Email":"`r(js)'""'
        }
        if "`supervisor'"!="" {
            _suso_jsonesc `"`supervisor'"'
            local body `"`body',"Supervisor":"`r(js)'""'
        }
        local body `"`body'}"'
        global SUSO_BODY_REQ `"`body'"'
        _suso_call , method(POST) path(/api/v1/users) `verbose'
        di as txt "suso: user '`username'' created (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="archive" {
        syntax , ID(string) [ CONFIRM VERBOSE ]
        _suso_block , action("Archive user `id' AND ALL of their interviewers in workspace $SUSO_WS") `confirm'
        _suso_call , method(PATCH) path(/api/v1/users/`id'/archive) destructive allow `verbose'
        _suso_audit , action("user archive") target("`id'") http("`r(http)'")
        di as txt "suso: user `id' archived (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="unarchive" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(PATCH) path(/api/v1/users/`id'/unarchive) `verbose'
        di as txt "suso: user `id' unarchived (HTTP `r(http)')."
        return add
        exit
    }

    di as err "suso user: unknown action '`verb''.  See {help suso}."
    exit 198
end

program _suso_supervisor, rclass
    version 14.2
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")

    if "`verb'"=="list" {
        syntax [, ALL LIMIT(integer 0) OFFSET(integer -1) PAGESize(integer 0) VERBOSE ]
        local vopt = cond("`verbose'"!="","verbose","")
        _suso_getall , path(/api/v1/supervisors) mode(page) sizeparam(limit) pageparam(offset) ///
            maxsize(200) arraykey(Users) `all' limit(`limit') offset(`offset')                  ///
            pagesize(`pagesize') `vopt'
        di as txt "suso: fetched " as res "`=r(nobs)'" as txt " supervisor(s)."
        return add
        exit
    }
    if "`verb'"=="get" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(GET) path(/api/v1/supervisors/`id') `verbose'
        di as txt "Supervisor " as res `"`r(username)'"' as txt ":  archived=" as res `"`r(isarchived)'"'
        return add
        exit
    }
    if "`verb'"=="interviewers" {
        syntax , ID(string) [ ALL LIMIT(integer 0) OFFSET(integer -1) PAGESize(integer 0) VERBOSE ]
        local vopt = cond("`verbose'"!="","verbose","")
        _suso_getall , path(/api/v1/supervisors/`id'/interviewers) mode(page) sizeparam(limit) ///
            pageparam(offset) maxsize(200) arraykey(Users) `all' limit(`limit') offset(`offset') ///
            pagesize(`pagesize') `vopt'
        di as txt "suso: fetched " as res "`=r(nobs)'" as txt " interviewer(s) under supervisor `id'."
        return add
        exit
    }
    di as err "suso supervisor: unknown action '`verb''.  See {help suso}."
    exit 198
end

program _suso_interviewer, rclass
    version 14.2
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")

    if "`verb'"=="get" {
        syntax , ID(string) [ VERBOSE ]
        _suso_call , method(GET) path(/api/v1/interviewers/`id') `verbose'
        di as txt "Interviewer " as res `"`r(username)'"' as txt ":  supervisor=" as res `"`r(supervisorname)'"' ///
            as txt "  locked=" as res `"`r(islocked)'"' as txt "  archived=" as res `"`r(isarchived)'"'
        return add
        exit
    }
    if "`verb'"=="actionslog" {
        syntax , ID(string) [ START(string) END(string) VERBOSE ]
        local q ""
        if "`start'"!="" {
            _suso_enc `"`start'"'
            local q "`q'&start=`r(enc)'"
        }
        if "`end'"!=""   {
            _suso_enc `"`end'"'
            local q "`q'&end=`r(enc)'"
        }
        if substr("`q'",1,1)=="&" local q = substr("`q'",2,.)
        _suso_call , method(GET) path(/api/v1/interviewers/`id'/actions-log) query(`q') todata arraykey() `verbose'
        di as txt "suso: " as res "`=r(nobs)'" as txt " action-log record(s) for interviewer `id'."
        return add
        exit
    }
    di as err "suso interviewer: unknown action '`verb''.  See {help suso}."
    exit 198
end

*===============================================================================
* Workspaces  (server-level; default to server root, override with -usews-)
*===============================================================================
program _suso_workspace, rclass
    version 14.2
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")

    if "`verb'"=="list" {
        syntax [, INCLUDEDISabled USEWS VERBOSE ]
        local rootopt = cond("`usews'"=="","root","")
        local q "Start=0&Length=1000"
        if "`includedisabled'"!="" local q "`q'&IncludeDisabled=true"
        _suso_call , method(GET) path(/api/v1/workspaces) query(`q') todata arraykey() `rootopt' `verbose'
        di as txt "suso: fetched " as res "`=r(nobs)'" as txt " workspace(s)."
        return add
        exit
    }

    if "`verb'"=="get" {
        syntax , NAME(string) [ USEWS VERBOSE ]
        local rootopt = cond("`usews'"=="","root","")
        _suso_call , method(GET) path(/api/v1/workspaces/`name') `rootopt' `verbose'
        di as txt "Workspace " as res `"`r(name)'"' as txt " — " as res `"`r(displayname)'"'
        return add
        exit
    }

    if "`verb'"=="status" {
        syntax , NAME(string) [ USEWS VERBOSE ]
        local rootopt = cond("`usews'"=="","root","")
        _suso_call , method(GET) path(/api/v1/workspaces/status/`name') `rootopt' `verbose'
        di as txt _n "Workspace status: " as res `"`name'"'
        di as txt "  can be deleted    : " as res `"`r(canbedeleted)'"'
        di as txt "  questionnaires    : " as res `"`r(existingquestionnairescount)'"'
        di as txt "  supervisors       : " as res `"`r(supervisorscount)'"'
        di as txt "  interviewers      : " as res `"`r(interviewerscount)'"'
        di as txt "  maps              : " as res `"`r(mapscount)'"'
        return add
        exit
    }

    if "`verb'"=="create" {
        syntax , NAME(string) DISPLAYname(string) [ USEWS VERBOSE ]
        if !regexm("`name'","^[0-9a-z,]+$") | length("`name'")>12 {
            di as err "suso: workspace name must match ^[0-9,a-z]+$ and be <= 12 chars."
            exit 198
        }
        local rootopt = cond("`usews'"=="","root","")
        _suso_jsonesc `"`displayname'"'
        local dn "`r(js)'"
        global SUSO_BODY_REQ `"{"Name":"`name'","DisplayName":"`dn'"}"'
        _suso_call , method(POST) path(/api/v1/workspaces) `rootopt' `verbose'
        di as txt "suso: workspace '`name'' created (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="update" {
        syntax , NAME(string) DISPLAYname(string) [ USEWS VERBOSE ]
        local rootopt = cond("`usews'"=="","root","")
        _suso_jsonesc `"`displayname'"'
        local dn "`r(js)'"
        global SUSO_BODY_REQ `"{"DisplayName":"`dn'"}"'
        _suso_call , method(PATCH) path(/api/v1/workspaces/`name') `rootopt' `verbose'
        di as txt "suso: workspace '`name'' updated (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="enable" {
        syntax , NAME(string) [ USEWS VERBOSE ]
        local rootopt = cond("`usews'"=="","root","")
        _suso_call , method(POST) path(/api/v1/workspaces/`name'/enable) `rootopt' `verbose'
        di as txt "suso: workspace '`name'' enabled (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="disable" {
        syntax , NAME(string) [ CONFIRM USEWS VERBOSE ]
        _suso_block , action("Disable workspace '`name'' (users can no longer use it)") `confirm'
        local rootopt = cond("`usews'"=="","root","")
        _suso_call , method(POST) path(/api/v1/workspaces/`name'/disable) destructive allow `rootopt' `verbose'
        _suso_audit , action("workspace disable") target("`name'") http("`r(http)'")
        di as txt "suso: workspace '`name'' disabled (HTTP `r(http)')."
        return add
        exit
    }

    if "`verb'"=="delete" {
        syntax , NAME(string) [ Iknowthis(string) FORCE USEWS VERBOSE ]
        local rootopt = cond("`usews'"=="","root","")

        * 1) typed-name confirmation
        _suso_block_ws , name(`name') iknowthis(`iknowthis')

        * 2) status pre-check
        _suso_call , method(GET) path(/api/v1/workspaces/status/`name') `rootopt'
        local can = strlower(`"`r(canbedeleted)'"')
        di as txt _n "About to DELETE workspace '" as res "`name'" as txt "':"
        di as txt "    questionnaires=" as res `"`r(existingquestionnairescount)'"' as txt ///
                  "  supervisors=" as res `"`r(supervisorscount)'"' as txt ///
                  "  interviewers=" as res `"`r(interviewerscount)'"' as txt ///
                  "  maps=" as res `"`r(mapscount)'"' as txt "  canBeDeleted=" as res "`can'"
        if "`can'"!="true" & "`can'"!="1" & "`force'"=="" {
            di as err "suso: the server reports this workspace CANNOT be safely deleted (CanBeDeleted=`can')."
            di as err "      It still contains data/users. Disable it instead, or override with -force- if you are certain."
            exit 1
        }

        * 3) execute
        _suso_call , method(DELETE) path(/api/v1/workspaces/`name') destructive allow `rootopt' `verbose'
        _suso_audit , action("workspace DELETE") target("`name'") http("`r(http)'")
        di as txt "suso: workspace '`name'' deleted (HTTP " as res "`r(http)'" as txt ").  Success=" as res `"`r(success)'"'
        return add
        exit
    }

    if "`verb'"=="assign" {
        syntax , USERIDS(string) WORKSpaces(string) [ MODE(string) SUPERVISOR(string) USEWS VERBOSE ]
        local rootopt = cond("`usews'"=="","root","")
        if "`mode'"=="" local mode Assign
        if !inlist(strproper("`mode'"),"Assign","Add","Remove") {
            di as err "suso: mode() must be Assign, Add or Remove."
            exit 198
        }
        * UserIds array
        local uids ""
        foreach u of local userids {
            local uids `"`uids',"`u'""'
        }
        local uids = substr(`"`uids'"',2,.)
        * Workspaces array
        local wss ""
        foreach w of local workspaces {
            if "`supervisor'"!="" local wss `"`wss',{"Workspace":"`w'","SupervisorId":"`supervisor'"}"'
            else                  local wss `"`wss',{"Workspace":"`w'"}"'
        }
        local wss = substr(`"`wss'"',2,.)
        global SUSO_BODY_REQ `"{"UserIds":[`uids'],"Workspaces":[`wss'],"Mode":"`=strproper("`mode'")'"}"'
        _suso_call , method(POST) path(/api/v1/workspaces/assign) `rootopt' `verbose'
        di as txt "suso: workspace assignment updated (HTTP `r(http)')."
        return add
        exit
    }

    di as err "suso workspace: unknown action '`verb''.  See {help suso}."
    exit 198
end

*===============================================================================
* Settings
*===============================================================================
program _suso_settings, rclass
    version 14.2
    gettoken what 0 : 0
    local what = strlower("`what'")
    if "`what'"!="globalnotice" {
        di as err "suso settings: only 'globalnotice' is supported.  See {help suso}."
        exit 198
    }
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")

    if "`verb'"=="get" {
        syntax [, VERBOSE]
        _suso_call , method(GET) path(/api/v1/settings/globalnotice) `verbose'
        di as txt "Global notice: " as res `"`r(message)'"'
        return add
        exit
    }
    if "`verb'"=="set" {
        syntax , MESSAGE(string) [ VERBOSE ]
        _suso_jsonesc `"`message'"'
        local m "`r(js)'"
        global SUSO_BODY_REQ `"{"Message":"`m'"}"'
        _suso_call , method(PUT) path(/api/v1/settings/globalnotice) `verbose'
        di as txt "suso: global notice set (HTTP `r(http)')."
        return add
        exit
    }
    if "`verb'"=="clear" {
        syntax [, CONFIRM VERBOSE]
        _suso_block , action("Clear the workspace-wide global notice") `confirm'
        _suso_call , method(DELETE) path(/api/v1/settings/globalnotice) ///
            destructive allow `verbose'
        _suso_audit , action("settings globalnotice clear") ///
            target("$SUSO_WS") http("`r(http)'")
        di as txt "suso: global notice cleared (HTTP `r(http)')."
        return add
        exit
    }
    di as err "suso settings globalnotice: action must be get, set or clear."
    exit 198
end

*===============================================================================
* Statistics
*===============================================================================
program _suso_statistics, rclass
    version 14.2
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")

    if "`verb'"=="questionnaires" {
        syntax [, VERBOSE]
        _suso_call , method(GET) path(/api/v1/statistics/questionnaires) todata arraykey() `verbose'
        di as txt "suso: " as res "`=r(nobs)'" as txt " questionnaire(s) with data."
        return add
        exit
    }

    if "`verb'"=="questions" {
        syntax [, GUID(string) QVER(integer 0) VERBOSE ]
        _suso_gq "`guid'" "`qver'"
        _suso_needq "`guid'"
        local q "questionnaireId=`guid'"
        if `qver'>0 local q "`q'&version=`qver'"
        _suso_call , method(GET) path(/api/v1/statistics/questions) query(`q') todata arraykey() `verbose'
        di as txt "suso: " as res "`=r(nobs)'" as txt " question(s) with data."
        return add
        exit
    }

    if "`verb'"=="report" {
        syntax , QUESTION(string) [ GUID(string) QVER(integer 0) EXPORTtype(string) ///
            SAVING(string) replace Query(string) VERBOSE ]
        _suso_gq "`guid'" "`qver'"
        _suso_needq "`guid'"
        local q "QuestionnaireId=`guid'&Question=`question'"
        if `qver'>0          local q "`q'&Version=`qver'"
        if "`exporttype'"!="" local q "`q'&exportType=`exporttype'"
        if `"`query'"'!=""   local q `"`q'&`query'"'
        if "`saving'"!="" {
            if "`replace'"=="" {
                capture confirm new file `"`saving'"'
                if _rc {
                    di as err "suso: file already exists. Use -replace-."
                    exit 602
                }
            }
            _suso_call , method(GET) path(/api/v1/statistics) query(`q') savefile(`saving') `verbose'
            di as txt "suso: saved statistics report to " as res `"`r(saved)'"' as txt " (`r(bytes)' bytes)."
        }
        else {
            _suso_call , method(GET) path(/api/v1/statistics) query(`q') todata arraykey() `verbose'
            di as txt "suso: loaded statistics report (" as res "`=r(nobs)'" as txt " rows)."
        }
        return add
        exit
    }

    di as err "suso statistics: action must be report, questions or questionnaires."
    exit 198
end

*===============================================================================
* Paradata — download / load the SuSo paradata export and analyse timing and
* interviewer behaviour (speeding, night work, answer churn, duration outliers).
*
*   suso paradata get      start->poll->download type(Paradata), unzip, load
*   suso paradata load     load a local paradata .zip / .tab (offline)
*   suso paradata timing   event data -> per-interview / question / interviewer
*   suso paradata flags    per-interview red flags + interviewer league table
*   suso paradata skips    historical AnswerRemoved runs + final-state review
*   suso paradata report   one-page self-contained HTML QC report with figures
*   suso paradata qx       parse the exported questionnaire HTML (text, skips, validations)
*   suso paradata check    evaluate the skip logic + option values against exported data
*   suso paradata suite    all three QC pages (behaviour, skip review, data QC) in one tabbed HTML
*
* Design notes (kept deliberately vectorised: one import, 2 sorts, 1 collapse):
*   - Works with both paradata layouts: v21.01+ (event, timestamp_utc, tz_offset)
*     and legacy (action, timestamp [device-local], offset).
*   - Durations use UTC when available; device-local time is used only for the
*     night-work metric. Negative gaps (device clock skew) are floored at 0.
*   - "Active" time caps every inter-event gap at gapmins() (default 30) and
*     zeroes Paused->next-event gaps, the standard SuSo paradata convention.
*   - Timing metrics use Interviewer-role events when the role column identifies
*     them (approve/reject traffic is excluded); event COUNTS (rejections etc.)
*     always use all rows. Override with -allroles-.
*===============================================================================
program _suso_paradata, rclass
    version 14.2
    gettoken verb 0 : 0, parse(" ,")
    local verb = strlower("`verb'")
    if inlist("`verb'","fetch","download")                    local verb get
    if inlist("`verb'","import","read")                       local verb load
    if inlist("`verb'","time","timings","durations")          local verb timing
    if inlist("`verb'","flag","quality","anomalies")           local verb flags
    if inlist("`verb'","skip","skipcheck","gates","cascades") local verb skips
    if inlist("`verb'","html","dashboard","qc")               local verb report
    if inlist("`verb'","questionnaire","instrument")           local verb qx
    if inlist("`verb'","skiplogic","datacheck","codebook")      local verb check
    if inlist("`verb'","all","combined","onepage")               local verb suite

    if "`verb'"=="get" {
        _suso_para_get `macval(0)'
        return add
        exit
    }
    if "`verb'"=="load" {
        _suso_para_load `macval(0)'
        return add
        exit
    }
    if "`verb'"=="timing" {
        _suso_para_timing `macval(0)'
        return add
        exit
    }
    if "`verb'"=="flags" {
        _suso_para_flags `macval(0)'
        return add
        exit
    }
    if "`verb'"=="skips" {
        _suso_para_skips `macval(0)'
        return add
        exit
    }
    if "`verb'"=="report" {
        _suso_para_report `macval(0)'
        return add
        exit
    }
    if "`verb'"=="qx" {
        _suso_para_qxload `macval(0)'
        return add
        exit
    }
    if "`verb'"=="check" {
        _suso_para_check `macval(0)'
        return add
        exit
    }
    if "`verb'"=="suite" {
        _suso_para_suite `macval(0)'
        return add
        exit
    }
    di as err "suso paradata: action must be get, load, timing, flags, skips, report, qx, check or suite.  See {help suso##paradata:help suso}."
    exit 198
end

* ---- get: export type(Paradata) from the server, unzip, load ------------------
program _suso_para_get, rclass
    version 14.2
    syntax [, SAVing(string) DIR(string) GUID(string) QVER(integer 0)          ///
        ISTATUS(string) FROM(string) TO(string) REDUCED PWD(string)            ///
        UNZIPW(string) POLLSecs(integer 10) JOBTimeout(integer 3600)           ///
        replace VERBOSE ]
    if `"`unzipw'"'!="" local pwd `"`unzipw'"'    // unzipw() = house synonym for pwd()
    if `"`pwd'"'==""    local pwd `"$SUSO_EXPORTPWD"'   // default from suso config , exportpw()

    if `"`saving'"'=="" {
        local stamp : di %tcCCYYNNDD-HHMMSS ///
            clock("`c(current_date)' `c(current_time)'", "DMYhms")
        local stamp = trim("`stamp'")
        local saving "suso_paradata_`stamp'.zip"
    }
    else if "`replace'"=="" {
        capture confirm new file `"`saving'"'
        if _rc {
            di as err "suso: file already exists. Use -replace-."
            exit 602
        }
    }
    local redopt = cond("`reduced'"!="","reduced","")

    di as txt "suso paradata: requesting a Paradata export (this can take a while on large surveys) ..."
    _suso_export_get , type(Paradata) saving(`"`saving'"') guid(`guid')        ///
        qver(`qver') istatus(`istatus') from(`from') to(`to') `redopt'         ///
        pollsecs(`pollsecs') jobtimeout(`jobtimeout') replace `verbose'
    if "`r(status)'"=="NoFile" {
        di as txt "suso paradata: the server reports no paradata for this questionnaire/filter — nothing to load."
        return local status "NoFile"
        exit
    }
    local zip `"`r(saved)'"'
    return local saved `"`zip'"'

    capture noisily _suso_unzip , file(`"`zip'"') dir(`"`dir'"') pwd(`"`pwd'"')
    if _rc {
        local rc = _rc
        di as err _n "suso paradata: could not extract the downloaded archive."
        if `"`pwd'"'=="" {
            di as err "  Your server may password-protect exports (Export Encryption). The"
            di as err "  download itself succeeded and is kept — no need to re-export. Retry:"
        }
        else {
            di as err "  A password was supplied but extraction still failed — wrong password,"
            di as err "  or a corrupt download. The archive is kept; retry without re-exporting:"
        }
        di as err `"      suso paradata load , file("`zip'") unzipw("<export password>")"'
        di as err `"  or set it once per session:   suso config , exportpw("<export password>")"'
        exit `rc'
    }
    local xdir `"`r(unzipdir)'"'
    return local unzipdir `"`xdir'"'

    _suso_para_load , dir(`"`xdir'"')
    if "`reduced'"!="" {
        char _dta[suso_paradata_reduced] 1
        di as err "suso paradata: reduced export loaded. Omitted enable/validity events can"
        di as err "                 change adjacency and timing context; prefer full paradata for QC."
    }
    return add
    di as txt "suso paradata: archive kept at " as res `"`zip'"'
    di as txt "               reload offline anytime:  {bf:suso paradata load , file(...)}"
end

* ---- load: local .tab / .zip / extracted folder --------------------------------
program _suso_para_load, rclass
    version 14.2
    syntax [, FILE(string) DIR(string) PWD(string) UNZIPW(string) ]
    if `"`unzipw'"'!="" local pwd `"`unzipw'"'    // unzipw() = house synonym for pwd()
    if `"`pwd'"'==""    local pwd `"$SUSO_EXPORTPWD"'   // default from suso config , exportpw()

    if `"`file'"'=="" & `"`dir'"'=="" {
        di as err "suso paradata load: specify the downloaded export,  file(<paradata .zip or .tab>)."
        exit 198
    }

    * a .zip is extracted first (Java backend: handles SuSo's ZipCrypto passwords)
    if `"`file'"'!="" {
        capture confirm file `"`file'"'
        if _rc {
            di as err `"suso paradata: file not found:  `file'"'
            exit 601
        }
        local k = strrpos(`"`file'"', ".")
        local ext = cond(`k'>0, lower(substr(`"`file'"', `k', .)), "")
        if "`ext'"==".zip" {
            capture noisily _suso_unzip , file(`"`file'"') pwd(`"`pwd'"')
            if _rc {
                local rc = _rc
                di as err _n "suso paradata: could not extract the archive."
                if `"`pwd'"'=="" di as err `"  If your server password-protects exports, add unzipw() or set:  suso config , exportpw("...")"'
                else            di as err "  A password was supplied but extraction failed — check the password."
                exit `rc'
            }
            local dir `"`r(unzipdir)'"'
            local file ""
        }
        else if !inlist("`ext'",".tab",".txt",".tsv") {
            di as err "suso paradata: expected a .zip (SuSo export) or the tab-delimited paradata file."
            exit 198
        }
    }

    * locate the paradata tab file inside an extracted folder
    if `"`file'"'=="" {
        local dnorm = subinstr(`"`dir'"', "\", "/", .)
        if substr(`"`dnorm'"',-1,1)=="/" local dnorm = substr(`"`dnorm'"',1,length(`"`dnorm'"')-1)
        local cands : dir `"`dnorm'"' files "*.tab"
        local pick ""
        foreach f of local cands {
            if lower(`"`f'"')=="paradata.tab" local pick `"`f'"'
        }
        if `"`pick'"'=="" {
            foreach f of local cands {
                if `"`pick'"'=="" local pick `"`f'"'
            }
        }
        if `"`pick'"'=="" {
            di as err `"suso paradata: no .tab file found in  `dnorm'"'
            di as err "               (a Paradata export contains paradata.tab — is this the right archive?)"
            exit 601
        }
        local file `"`dnorm'/`pick'"'
    }

    di as txt "suso paradata: importing " as res `"`file'"' as txt " ..."
    import delimited using `"`file'"', delimiter(tab) varnames(1)              ///
        stringcols(_all) bindquote(nobind) encoding(utf-8) clear

    _suso_para_prep

    * summary (one sort; leaves the data ordered iid/event-order)
    tempvar f1
    quietly bysort interview__id (para_ord para_seq): gen byte `f1' = (_n==1)
    quietly count if `f1'
    local nint = r(N)
    quietly summarize para_tsu
    if r(N)>0 {
        local d0 : di %tcCCYY-NN-DD r(min)
        local d1 : di %tcCCYY-NN-DD r(max)
        local period `", `d0' to `d1'"'
    }
    else local period ""

    di as txt "suso paradata: loaded " as res "`=_N'" as txt " event(s) from " ///
        as res "`nint'" as txt " interview(s)`period'."
    di as txt _n "  what next:"
    di as txt "    {bf:suso paradata report}   one-page QC report with figures (recommended first look)"
    di as txt "    {bf:suso paradata flags}    behaviour red flags per interview + interviewer league"
    di as txt "    {bf:suso paradata timing}   durations & answer speed (by interview / question / interviewer)"
    di as txt "    {bf:suso paradata skips}    historical AnswerRemoved runs, nearby/linked answer variables, and final-state review"
    di as txt "  tip: timing/flags/skips replace the loaded events — {bf:save events.dta} first if you plan"
    di as txt "       to iterate on thresholds; {bf:report} takes care of this by itself."
    return scalar nevents = _N
    return scalar nints   = `nint'
    return local  tabfile `"`file'"'
end

* ---- prep: harmonise columns across SuSo versions, parse times, mark events ----
program _suso_para_prep
    version 14.2
    if `"`: char _dta[suso_paradata]'"'=="events" {
        * Current prepared-event files are reusable.  Older saved preparations
        * lack explicit UTC/offset validity and cannot be safely upgraded from
        * their already-coerced clock fields; require the original tab export.
        capture confirm variable para_utc_valid, exact
        local __oldprep = _rc
        capture confirm variable para_off_valid, exact
        local __oldprep = max(`__oldprep',_rc)
        if !`__oldprep' {
            char _dta[suso_paradata_schema] 1714
            exit
        }
        di as err "suso paradata: this saved events dataset was prepared by an older build."
        di as err "                 Reload the original paradata tab file with {bf:suso paradata load}."
        exit 459
    }

    capture confirm string variable interview__id
    if _rc {
        di as err "suso paradata: no string interview__id column — this does not look like a Survey Solutions paradata file."
        exit 459
    }
    quietly count if strtrim(interview__id)==""
    if r(N)>0 {
        local nblank = r(N)
        di as err "suso paradata: `nblank' event row(s) have a missing/blank interview__id."
        di as err "                 Repair or remove those source rows before running paradata QC."
        exit 459
    }
    * legacy column names
    capture confirm variable event
    if _rc {
        capture confirm variable action
        if !_rc rename action event
    }
    capture confirm string variable event
    if _rc {
        di as err "suso paradata: no (string) event/action column found."
        exit 459
    }

    * numeric within-interview sequence (order), with file order as tiebreaker
    quietly gen double para_seq = _n
    capture confirm variable order
    if !_rc {
        capture confirm string variable order
        if !_rc quietly gen double para_ord = real(order)
        else    quietly gen double para_ord = order
    }
    else quietly gen double para_ord = _n
    quietly replace para_ord = para_seq if missing(para_ord)
    label variable para_seq "paradata: file row (tiebreak)"
    label variable para_ord "paradata: event order within interview"

    * timestamps: v21.01+ = timestamp_utc (+ tz_offset); legacy = timestamp local (+ offset)
    local tsvar ""
    capture confirm variable timestamp_utc
    if !_rc local tsvar timestamp_utc
    else {
        capture confirm variable timestamp
        if !_rc local tsvar timestamp
    }
    if "`tsvar'"=="" {
        di as err "suso paradata: no timestamp_utc/timestamp column — cannot compute timings."
        exit 459
    }
    capture confirm string variable `tsvar'
    if !_rc {
        * Official paradata timestamps include milliseconds. Preserve the first
        * three fractional digits; the whole-second fallback supports old files.
        quietly gen double para_ts = clock(subinstr(substr(`tsvar',1,23),"T"," ",1), "YMDhms")
        quietly replace para_ts = clock(subinstr(substr(`tsvar',1,19),"T"," ",1), "YMDhms") ///
            if missing(para_ts) & `tsvar'!=""
        quietly count if missing(para_ts) & `tsvar'!=""
        if r(N)>0 di as txt "suso paradata: note — " as res "`=r(N)'" as txt " event(s) had unparseable timestamps (left missing)."
    }
    else quietly gen double para_ts = `tsvar'      // already numeric (%tc)

    * timezone offset -> milliseconds (formats like +05:30:00 / -04:00:00 / 05:30:00)
    local tzvar ""
    capture confirm string variable tz_offset
    if !_rc local tzvar tz_offset
    else {
        capture confirm string variable offset
        if !_rc local tzvar offset
    }
    if "`tzvar'"!="" {
        tempvar sgn body kp offh offm offs offshape
        quietly gen byte `sgn'  = 1 - 2*(substr(strtrim(`tzvar'),1,1)=="-")
        quietly gen `body' = strtrim(cond(inlist(substr(strtrim(`tzvar'),1,1),"+","-"), ///
            substr(strtrim(`tzvar'),2,.), strtrim(`tzvar')))
        quietly gen long `kp'   = strpos(`body', ":")
        quietly gen double `offh' = real(substr(`body',1,`kp'-1)) if `kp'>0
        quietly gen double `offm' = real(substr(`body',`kp'+1,2)) if `kp'>0
        quietly gen double `offs' = real(substr(`body',`kp'+4,2)) if ///
            `kp'>0 & length(`body')==`kp'+5
        quietly replace `offs' = 0 if `kp'>0 & length(`body')==`kp'+2
        quietly gen byte `offshape' = `kp'>1 & inlist(length(`body'),`kp'+2,`kp'+5) & ///
            (length(`body')==`kp'+2 | substr(`body',`kp'+3,1)==":")
        quietly gen double para_off = `sgn' * (3600000*`offh' + 60000*`offm' + ///
            1000*`offs') ///
            if `kp'>0
        quietly gen byte para_off_valid = !missing(para_off) & ///
            `offh'>=0 & `offh'<=14 & `offm'>=0 & `offm'<60 & ///
            `offs'>=0 & `offs'<60 & `offh'==floor(`offh') & ///
            `offm'==floor(`offm') & `offs'==floor(`offs') & `offshape' & ///
            abs(para_off)<=14*3600000
        quietly replace para_off = . if !para_off_valid
    }
    else {
        quietly gen double para_off = .
        quietly gen byte para_off_valid = 0
    }

    * UTC clock for durations, device-local clock for time-of-day
    if "`tsvar'"=="timestamp_utc" {
        quietly gen double para_tsu = para_ts
        quietly gen double para_tsl = para_ts + para_off if para_off_valid
        quietly gen byte para_utc_valid = !missing(para_ts)
    }
    else {   // legacy: timestamp is device-local
        quietly gen double para_tsl = para_ts
        * A missing legacy offset prevents UTC alignment but not within-interview
        * durations. Preserve the local clock as the duration fallback and mark
        * the offset unknown rather than silently pretending it is UTC.
        quietly gen double para_tsu = cond(para_off_valid, para_ts-para_off, para_ts)
        quietly gen byte para_utc_valid = !missing(para_ts) & para_off_valid
    }
    format para_tsu para_tsl %tcCCYY-NN-DD_HH:MM:SS
    label variable para_tsu "paradata: event time (UTC)"
    label variable para_tsl "paradata: event time (device local)"
    label variable para_off_valid "paradata: timezone offset parsed"
    label variable para_utc_valid "paradata: timestamp comparable in UTC"
    quietly drop para_ts

    * normalised event name + indicators (names vary slightly across versions)
    quietly gen para_ev = lower(strtrim(event))
    quietly gen byte para_ans = (para_ev=="answerset")
    quietly gen byte para_rem = (para_ev=="answerremoved")
    quietly gen byte para_inv = (strpos(para_ev,"declaredinvalid")>0)
    quietly gen byte para_cmp = (para_ev=="completed")
    quietly gen byte para_rst = (para_ev=="restarted")
    quietly gen byte para_rej = (strpos(para_ev,"rejectedby")==1)
    quietly gen byte para_pau = (para_ev=="paused")
    quietly gen byte para_vset = (para_ev=="variableset")
    quietly gen byte para_ven  = (para_ev=="variableenabled")
    quietly gen byte para_vdis = (para_ev=="variabledisabled")
    label variable para_ev  "paradata: event (lowercase)"
    label variable para_ans "AnswerSet"
    label variable para_rem "AnswerRemoved"
    label variable para_inv "declared invalid"
    label variable para_cmp "Completed"
    label variable para_rst "Restarted"
    label variable para_rej "Rejected (SV/HQ)"
    label variable para_pau "Paused"
    label variable para_vset "VariableSet"
    label variable para_ven  "VariableEnabled"
    label variable para_vdis "VariableDisabled"

    * Parse event parameters into variable, answer value and optional roster
    * address. Official SuSo formats are:
    *   AnswerSet     varname||value||OptionalRosterAddress
    *   AnswerRemoved varname||OptionalRosterAddress
    *   Variable*     varname||value||OptionalRosterAddress
    * The question-instance key prevents values from different roster rows from
    * being combined when reconstructing an exact answer transition.
    capture confirm string variable parameters
    if !_rc {
        tempvar pc quoted p1 rest p2 isqevent
        quietly gen strL `pc' = parameters
        quietly gen byte `quoted' = substr(`pc',1,1)==char(34) & ///
            substr(`pc',length(`pc'),1)==char(34) & length(`pc')>=2
        quietly replace `pc' = substr(`pc',2,length(`pc')-2) if `quoted'
        quietly replace `pc' = substr(`pc',2,.) if substr(`pc',1,1)==char(34)
        quietly gen long `p1' = strpos(`pc', "||")
        quietly gen strL `rest' = substr(`pc',`p1'+2,.) if `p1'>0
        quietly gen long `p2' = strpos(`rest', "||") if `p1'>0
        quietly gen byte `isqevent' = para_ans | para_rem | para_inv | ///
            strpos(para_ev,"declaredvalid")>0 | para_ev=="commentset" | ///
            para_vset | para_ven | para_vdis

        quietly gen str80 para_var = cond(`p1'>0, substr(`pc',1,`p1'-1), `pc') ///
            if `isqevent'
        quietly gen strL para_val = ""
        quietly replace para_val = cond(`p2'>0, substr(`rest',1,`p2'-1), `rest') ///
            if (para_ans | para_vset | para_ven | para_vdis) & `p1'>0

        quietly gen str160 para_roster = ""
        quietly replace para_roster = substr(`rest',`p2'+2,160) ///
            if (para_ans | para_vset | para_ven | para_vdis) & `p2'>0
        quietly replace para_roster = substr(`rest',1,160) ///
            if (para_rem | para_inv | strpos(para_ev,"declaredvalid")>0) & `p1'>0
        quietly replace para_roster = substr(`rest',`p2'+2,160) ///
            if para_ev=="commentset" & `p2'>0
        quietly replace para_roster = strtrim(para_roster)
        quietly replace para_roster = substr(para_roster,1,length(para_roster)-1) ///
            if length(para_roster)>0 & substr(para_roster,-1,1)==char(34)

        quietly gen str244 para_qkey = substr(para_var + ///
            cond(para_roster!="", "||" + para_roster, ""), 1, 244) ///
            if para_var!=""
        quietly gen str244 para_qdisp = substr(para_var + ///
            cond(para_roster!="", " [roster " + para_roster + "]", ""), 1, 244) ///
            if para_var!=""

        label variable para_var    "paradata: question variable"
        label variable para_val    "paradata: answer/calculated-variable value"
        label variable para_roster "paradata: optional roster address"
        label variable para_qkey   "paradata: question-instance key"
        label variable para_qdisp  "paradata: question instance (display)"
    }

    char _dta[suso_paradata] events
    char _dta[suso_paradata_schema] 1714
end

* ---- guard: the current dataset must be prepared paradata of the given kind ----
program _suso_para_need
    version 14.2
    args kind
    if `"`: char _dta[suso_paradata]'"'!="`kind'" {
        if "`kind'"=="events" {
            di as err "suso paradata: no paradata events in memory."
            di as err "      Load them first:   suso paradata get   |   suso paradata load , file(...)"
        }
        else {
            di as err "suso paradata: no paradata `kind' table in memory."
        }
        exit 459
    }
    if "`kind'"=="events" {
        capture confirm variable para_utc_valid, exact
        local __oldprep = _rc
        capture confirm variable para_off_valid, exact
        local __oldprep = max(`__oldprep',_rc)
        if `__oldprep' {
            di as err "suso paradata: these events were prepared by an older package build."
            di as err "                 Reload the original paradata tab file before running QC."
            exit 459
        }
        char _dta[suso_paradata_schema] 1714
    }
    if "`kind'"=="events" & `"`: char _dta[suso_paradata_reduced]'"'=="1" {
        di as err "suso paradata: WARNING — this is a reduced export; some event context is absent."
    }
    * self-heal: a crashed earlier run can leave temp-named columns behind; a later
    * -tempvar- may be issued the same name and its -gen- would then fail with r(110)
    capture quietly ds __0*
    if !_rc {
        if "`r(varlist)'"!="" quietly drop `r(varlist)'
    }
end

* ---- varsel: restrict answer-level events to selected variables ---------------
* Keeps structural events (sessions, completions, workflow) so timing and status
* derivation stay intact; answer/removal/comment events survive only when the
* variable matches one of the (wildcard-capable) patterns in vars().
program _suso_para_varsel, rclass
    version 14.2
    syntax [, VARS(string) ]
    if `"`vars'"'=="" exit
    capture confirm variable para_var, exact
    if _rc {
        di as txt "  vars(): the paradata has no variable names (parameters column absent) - option ignored."
        exit
    }
    tempvar kev
    quietly gen byte `kev' = !(para_ans | para_rem | para_ev=="commentset")
    foreach p of local vars {
        quietly replace `kev' = 1 if (para_ans | para_rem | para_ev=="commentset") & strmatch(para_var, "`p'")
    }
    quietly count if `kev' & para_ans
    local na = r(N)
    quietly keep if `kev'
    quietly drop `kev'
    di as txt "  vars(): question/skip detail restricted to " as res "`na'" as txt ///
        " answer events on the selected variables (`vars')."
    di as txt "  whole-interview timing, actor attribution and workflow signals still use the complete field stream."
    return scalar nanskept = `na'
end

* ---- derive: shared event-level derivations (roles, gaps, sessions) ------------
program _suso_para_derive, rclass
    version 14.2
    syntax [, GAPMins(real 30) FASTsecs(real 2) ALLRoles CACHEToken(string) ]
    * Invalidate any earlier cache stamp before touching derived columns.  Only
    * a fully successful run receives the private capability used by report.
    char _dta[suso_para_derived_schema] ""
    char _dta[suso_para_derived_token] ""
    char _dta[suso_para_derived_n] ""
    char _dta[suso_para_derived_gapmins] ""
    char _dta[suso_para_derived_fastsecs] ""
    char _dta[suso_para_derived_allroles] ""
    char _dta[suso_para_derived_rolenote] ""
    if missing(`gapmins') | missing(`fastsecs') | `gapmins'<=0 | `fastsecs'<=0 {
        di as err "suso paradata: gapmins() and fastsecs() must be positive."
        exit 198
    }
    local gapsecs = `gapmins'*60
    capture drop para_role
    * derived columns from a previous (possibly interrupted) run
    capture drop para_ivw para_resp para_gap para_gap_raw para_prevp            ///
        para_prevcmp para_brk para_session para_act para_act_first              ///
        para_ansgap para_fast para_fastrun para_night para_tivw para_tivwl para_one ///
        para_preload para_fieldans para_fieldrem para_fieldcmp para_fieldrst    ///
        para_cawi para_firstpass para_rework para_actor para_actor_key          ///
        para_actorchange para_primary para_firstinterviewer para_lasteditor     ///
        para_nactors para_handoff para_primary_answers para_primary_questions  ///
        para_clockback para_time_missing para_local_missing para_index

    * Interviewer-role detection. Map the documented labels/codes directly so
    * a Supervisor/HQ/API-only extract can never become interviewer traffic.
    * For genuinely unknown legacy codes only, use Completed events as fallback.
    local rolenote "all roles (no role column)"
    quietly gen byte para_ivw = 1
    capture confirm variable role
    if !_rc & "`allroles'"=="" {
        capture confirm string variable role
        if !_rc quietly gen para_role = lower(strtrim(role))
        else    quietly gen para_role = lower(strtrim(strofreal(role,"%18.0g")))
        tempvar knownrole
        quietly gen byte `knownrole' = inlist(para_role,"interviewer","1",      ///
            "supervisor","2","headquarter","headquarters","3") |            ///
            inlist(para_role,"administrator","4","api","api user","5","0")
        quietly count if `knownrole'
        if r(N)>0 {
            quietly replace para_ivw = inlist(para_role,"interviewer","1")
            local rolenote "Interviewer-role events (documented role mapping)"
        }
        else {
            local rcode ""
            quietly count if para_cmp
            if r(N)>0 {
                preserve
                quietly keep if para_cmp & para_role!=""
                if _N>0 {
                    quietly contract para_role
                    gsort -_freq para_role
                    local rcode = para_role[1]
                }
                restore
            }
            if "`rcode'"!="" {
                quietly replace para_ivw = (para_role=="`rcode'")
                local rolenote `"interviewer role inferred as legacy code `rcode' (modal role on Completed events)"'
            }
            else {
                quietly replace para_ivw = 0
                local rolenote "no interviewer role found"
            }
        }
    }
    if "`allroles'"!="" local rolenote "all roles (allroles)"

    * CAPI preload values arrive as AnswerSet events at InterviewCreated time,
    * before the tablet's first field session. Keep them in history/final-state
    * reconstruction, but exclude them from interviewer behaviour metrics.
    tempvar created firststart
    quietly egen double `created' = min(cond(para_ev=="interviewcreated",para_tsu,.)), ///
        by(interview__id)
    quietly egen double `firststart' = min(cond(inlist(para_ev,"resumed",       ///
        "restarted"),para_ord,.)), by(interview__id)
    quietly gen byte para_preload = para_ans & para_ivw & !missing(`created') & ///
        para_tsu==`created' & (missing(`firststart') | para_ord<`firststart')
    quietly gen byte para_fieldans = para_ans & para_ivw & !para_preload
    quietly gen byte para_fieldrem = para_rem & para_ivw
    quietly gen byte para_fieldcmp = para_cmp & para_ivw
    quietly gen byte para_fieldrst = para_rst & para_ivw
    quietly sort interview__id para_ord para_seq
    quietly by interview__id: gen long para_index = _n
    label variable para_preload  "initial CAPI preload AnswerSet"
    label variable para_fieldans "interviewer AnswerSet (preload excluded)"
    label variable para_fieldrem "interviewer AnswerRemoved"
    label variable para_fieldcmp "interviewer Completed"
    label variable para_fieldrst "interviewer Restarted"

    * Carry the active field actor through actor-less structural events.  The raw
    * responsible column is retained; para_actor is the timing/attribution key.
    quietly gen str244 para_actor = ""
    capture confirm string variable responsible
    if !_rc {
        quietly replace para_actor = strtrim(responsible) if para_ivw
        quietly bysort interview__id para_ivw (para_ord para_seq): replace ///
            para_actor = para_actor[_n-1] if para_ivw & para_actor=="" & _n>1
    }
    * Keep unattributed field events auditable without merging every blank login into
    * one fictitious cross-interview actor (which would manufacture overlap).
    quietly replace para_actor = "(unattributed:" + substr(interview__id,1,80) + ")" ///
        if para_ivw & para_actor=="" & (para_fieldans | para_fieldrem | ///
        para_fieldcmp | para_fieldrst | para_inv)
    quietly bysort interview__id para_ivw (para_ord para_seq): replace ///
        para_actor = para_actor[_n-1] if para_ivw & para_actor=="" & _n>1
    quietly gen str244 para_actor_key = ustrlower(strtrim(para_actor))

    * Event-level interview mode.  Mixed CAPI/CAWI histories are retained rather
    * than classifying the whole record from only its last mode-change event.
    quietly gen byte para_cawi = .
    capture confirm string variable parameters
    if !_rc {
        quietly replace para_cawi = strpos(lower(parameters),"cawi")>0 ///
            if para_ev=="interviewmodechanged"
        quietly bysort interview__id (para_ord para_seq): replace para_cawi = ///
            para_cawi[_n-1] if missing(para_cawi) & _n>1
    }
    * Missing means the source did not establish collection mode.  Do not
    * silently call that CAPI: mode-dependent timing signals are suppressed
    * downstream until an InterviewModeChanged(CAPI/CAWI) event is available.
    label variable para_cawi "paradata: interview mode (0 CAPI, 1 CAWI, . unknown)"

    * First-pass behaviour ends at the first interviewer completion.  Later
    * rejection/reassignment corrections stay in total/workflow metrics but do
    * not dilute the evidence from the original interview.
    tempvar firstcmpord
    quietly egen double `firstcmpord' = min(cond(para_fieldcmp,para_index,.)), ///
        by(interview__id)
    quietly gen byte para_firstpass = missing(`firstcmpord') | para_index<=`firstcmpord'
    quietly gen byte para_rework = !para_firstpass
    label variable para_firstpass "event at/before first interviewer completion"
    label variable para_rework "event after first interviewer completion"

    * Gaps within the interviewer-role stream.  Clock reversals are evidence of
    * unreliable timing, not zero-second answers: preserve the raw gap, mark it,
    * and exclude it from active/speed calculations.
    tempvar startmark endmark received productive prevactor bump block          ///
        haswork candidate candcum sameav lastav prevav newreach workevent
    quietly bysort interview__id para_ivw (para_ord para_seq): ///
        gen double para_gap_raw = (para_tsu - para_tsu[_n-1])/1000 ///
        if para_ivw & _n>1 & !missing(para_tsu,para_tsu[_n-1])
    quietly gen byte para_clockback = para_ivw & para_gap_raw<0 & !missing(para_gap_raw)
    quietly gen double para_gap = para_gap_raw if para_gap_raw>=0
    quietly bysort interview__id para_ivw (para_ord para_seq): ///
        gen byte para_prevp = (para_pau[_n-1]==1) if para_ivw & _n>1
    quietly replace para_prevp = 0 if missing(para_prevp)
    quietly bysort interview__id para_ivw (para_ord para_seq): ///
        gen byte para_prevcmp = (para_cmp[_n-1]==1) if para_ivw & _n>1
    quietly replace para_prevcmp = 0 if missing(para_prevcmp)

    * Session segmentation.  Start/restart/receipt, a prior Pause/Completed,
    * long inactivity, or an actor handoff opens a raw segment.  A segment counts
    * only if it contains real field work; this coalesces repeated workflow
    * markers and prevents ReceivedByInterviewer from becoming phantom work.
    quietly gen byte `startmark' = para_ivw & inlist(para_ev,"resumed","restarted")
    quietly gen byte `endmark' = para_ivw & inlist(para_ev,"paused","completed")
    quietly gen byte `received' = para_ivw & para_ev=="receivedbyinterviewer"
    quietly gen byte `productive' = para_ivw & (para_fieldans | para_fieldrem | ///
        para_inv | para_ev=="commentset")
    quietly bysort interview__id para_ivw (para_ord para_seq): gen str244 ///
        `prevactor' = para_actor_key[_n-1] if para_ivw & _n>1
    quietly gen byte para_actorchange = para_ivw & para_actor_key!="" & ///
        `prevactor'!="" & para_actor_key!=`prevactor'
    * Different tablets can have different clocks.  A handoff is already a
    * zero-contribution session boundary, so a cross-actor negative delta is not
    * evidence that either actor's within-session clock ran backward.
    quietly replace para_clockback = 0 if para_actorchange
    quietly gen byte `bump' = para_ivw & (`startmark' | `received' |       ///
        para_prevp | para_prevcmp | para_actorchange |                    ///
        (!missing(para_gap) & para_gap>`gapsecs'))
    quietly bysort interview__id para_ivw (para_ord para_seq): gen long ///
        `block' = sum(`bump') if para_ivw
    quietly egen byte `haswork' = max(`productive' | (para_fieldcmp & para_firstpass)), ///
        by(interview__id para_ivw `block')
    quietly gen byte `candidate' = para_ivw & (`startmark' | `productive' | ///
        (para_fieldcmp & para_firstpass))
    quietly bysort interview__id para_ivw `block' (para_ord para_seq): gen long ///
        `candcum' = sum(`candidate') if para_ivw
    quietly gen byte para_brk = `candidate' & `candcum'==1 & `haswork'
    quietly bysort interview__id para_ivw (para_ord para_seq): gen long ///
        para_session = sum(para_brk) if para_ivw
    quietly replace para_session = . if para_ivw & !`haswork'

    * Every cross-segment interval is zero.  Within a productive segment, retain
    * ordinary structural intervals and the final interval ending at Pause or
    * Completed, capped at gapmins().
    quietly gen double para_act = 0
    quietly replace para_act = min(para_gap,`gapsecs') if para_ivw & ///
        para_session>0 & `haswork' & !missing(para_gap) & !para_brk & ///
        !`bump' & !para_prevp & !para_prevcmp
    quietly gen double para_act_first = para_act if para_firstpass
    quietly gen double para_ansgap = para_gap if para_fieldans & !para_brk &    ///
        !para_actorchange & para_session>0 & !missing(para_gap)
    * a repeat AnswerSet on the same variable (multi-select taps, list items,
    * immediate revisions) is not a newly reached question - keep it out of the
    * answer-speed clock so tapping through a checklist cannot look like speeding
    quietly gen byte `newreach' = para_fieldans
    capture confirm variable para_var
    if !_rc {
        local __akey para_var
        capture confirm variable para_qkey
        if !_rc local __akey para_qkey
        quietly gen `sameav' = `__akey' if para_fieldans
        quietly bysort interview__id para_actor_key para_session (para_ord para_seq): ///
            gen `lastav' = `sameav'
        quietly by interview__id para_actor_key para_session: replace `lastav' = ///
            `lastav'[_n-1] if `lastav'=="" & _n>1
        quietly by interview__id para_actor_key para_session: gen `prevav' = ///
            `lastav'[_n-1] if _n>1
        quietly replace para_ansgap = . if para_fieldans & `__akey'!="" & `prevav'==`__akey'
        quietly replace `newreach' = 0 if para_fieldans & `__akey'!="" & ///
            `prevav'==`__akey'
    }
    quietly gen byte   para_fast   = (para_ansgap<`fastsecs') if !missing(para_ansgap)
    quietly gen long para_fastrun = .
    quietly bysort interview__id para_actor_key para_session (para_ord para_seq): ///
        replace para_fastrun = cond(!para_firstpass,0,                         ///
        cond(!missing(para_ansgap),cond(para_fast,                             ///
        cond(_n==1,1,para_fastrun[_n-1]+1),0),                                ///
        cond(`newreach',0,cond(_n==1,0,para_fastrun[_n-1]))))
    quietly gen byte   para_night  = para_fieldans & !missing(para_tsl) & ///
                                     (hh(para_tsl)>=22 | hh(para_tsl)<6)
    quietly gen byte `workevent' = para_ivw & (`startmark' | `productive' | `endmark')
    quietly gen double para_tivw   = para_tsu if `workevent' & para_session>0 & `haswork'
    quietly gen double para_tivwl  = para_tsl if `workevent' & para_session>0 & `haswork'
    quietly gen byte para_time_missing = para_ivw & (`productive' | para_fieldcmp) & ///
        missing(para_tsu)
    quietly gen byte para_local_missing = para_fieldans & missing(para_tsl)
    quietly gen byte   para_one    = 1

    * Deterministic interview attribution.  Primary = most distinct first-pass
    * question instances, then most first-pass AnswerSet events, most active
    * seconds, earliest answer, and finally the normalized actor key.  Last editor
    * remains separate, so a post-rejection correction never inherits the original
    * enumerator's behavioural evidence.
    tempvar pkey qtag actorq actora actoract actorfirst edit atag
    capture confirm variable para_qkey, exact
    if !_rc quietly gen str244 `pkey' = para_qkey
    else {
        capture confirm variable para_var, exact
        if !_rc quietly gen str244 `pkey' = para_var
        else quietly gen str244 `pkey' = ""
    }
    quietly egen byte `qtag' = tag(interview__id para_actor_key `pkey') if ///
        para_fieldans & para_firstpass & para_actor_key!="" & `pkey'!=""
    quietly egen double `actorq' = total(cond(missing(`qtag'),0,`qtag')), ///
        by(interview__id para_actor_key)
    quietly egen double `actora' = total(para_fieldans & para_firstpass), ///
        by(interview__id para_actor_key)
    quietly egen double `actoract' = total(cond(para_firstpass,para_act,0)), ///
        by(interview__id para_actor_key)
    quietly egen double `actorfirst' = min(cond(para_fieldans & para_firstpass, ///
        para_ord,.)), by(interview__id para_actor_key)
    gsort interview__id -`actorq' -`actora' -`actoract' `actorfirst' ///
        para_actor_key para_ord para_seq
    quietly by interview__id: gen str244 para_primary = para_actor[1] ///
        if `actora'[1]>0
    quietly by interview__id: gen double para_primary_answers = `actora'[1]
    quietly by interview__id: gen double para_primary_questions = `actorq'[1]

    quietly gen byte `edit' = para_fieldans | para_fieldrem
    gsort interview__id -`edit' -para_ord -para_seq para_actor_key
    quietly by interview__id: gen str244 para_lasteditor = para_actor[1] if `edit'[1]
    gsort interview__id -para_fieldans para_ord para_seq para_actor_key
    quietly by interview__id: gen str244 para_firstinterviewer = para_actor[1] ///
        if para_fieldans[1]
    quietly egen byte `atag' = tag(interview__id para_actor_key) if ///
        `edit' & para_actor_key!=""
    quietly egen double para_nactors = total(cond(missing(`atag'),0,`atag')), ///
        by(interview__id)
    quietly replace para_primary = para_lasteditor if para_primary=="" & ///
        para_lasteditor!=""
    quietly gen byte para_handoff = para_nactors>1
    quietly gen str244 para_resp = para_primary
    quietly sort interview__id para_ord para_seq
    * These fields were historically declared str244 for safety.  On a
    * multi-million-row export that can add several gigabytes to every temporary
    * dataset even when actor names are only a few characters long.  -compress-
    * is lossless and pays for one linear scan here, before the report reuses the
    * derived stream many times.
    foreach __cv in para_role para_actor para_actor_key para_primary           ///
        para_firstinterviewer para_lasteditor para_resp para_var para_roster   ///
        para_qkey para_qdisp {
        capture confirm variable `__cv', exact
        if !_rc quietly compress `__cv'
    }
    char _dta[suso_para_derived_schema] 1716
    char _dta[suso_para_derived_token] `"`cachetoken'"'
    char _dta[suso_para_derived_n] `=_N'
    char _dta[suso_para_derived_gapmins] `gapmins'
    char _dta[suso_para_derived_fastsecs] `fastsecs'
    char _dta[suso_para_derived_allroles] `=cond("`allroles'"!="","1","0")'
    char _dta[suso_para_derived_rolenote] `"`rolenote'"'
    label variable para_primary "primary first-pass field enumerator"
    label variable para_firstinterviewer "first field enumerator"
    label variable para_lasteditor "last field answer/removal editor"
    label variable para_nactors "distinct field actors"
    label variable para_handoff "more than one field actor"
    label variable para_resp "primary field enumerator (compatibility alias)"
    return local rolenote `"`rolenote'"'
end

* ---- timing: events in memory  ->  one row per interview / question / interviewer
program _suso_para_timing, rclass
    version 14.2
    syntax [, BY(string) GAPMins(real 30) FASTsecs(real 2) ALLRoles VARS(string) PREComputed(string) ]
    _suso_para_need events

    if "`by'"=="" local by interview
    if !inlist("`by'","interview","question","interviewer") {
        di as err "suso paradata timing: by() must be interview, question or interviewer."
        exit 198
    }
    if `gapmins'<=0 | `fastsecs'<=0 {
        di as err "suso paradata timing: gapmins() and fastsecs() must be positive."
        exit 198
    }
    if `"`precomputed'"'=="" {
        _suso_para_derive , gapmins(`gapmins') fastsecs(`fastsecs') `allroles'
        local rolenote `"`r(rolenote)'"'
    }
    else {
        foreach v in para_ivw para_fieldans para_fieldrem para_fieldcmp       ///
            para_fieldrst para_firstpass para_rework para_actor para_actor_key ///
            para_session para_brk para_act para_act_first para_ansgap         ///
            para_fast para_fastrun para_night para_tivw para_tivwl para_one   ///
            para_preload para_cawi para_clockback para_time_missing           ///
            para_local_missing para_primary para_firstinterviewer             ///
            para_lasteditor para_resp para_nactors para_handoff               ///
            para_primary_answers para_primary_questions para_ans para_rem     ///
            para_cmp para_rst para_rej para_inv para_off para_off_valid {
            capture confirm variable `v', exact
            if _rc {
                di as err "suso paradata timing: internal precomputed event cache is incomplete (`v' missing)."
                exit 459
            }
        }
        local __ds : char _dta[suso_para_derived_schema]
        local __dt : char _dta[suso_para_derived_token]
        local __dn : char _dta[suso_para_derived_n]
        local __dg : char _dta[suso_para_derived_gapmins]
        local __df : char _dta[suso_para_derived_fastsecs]
        local __da : char _dta[suso_para_derived_allroles]
        local __wantall = cond("`allroles'"!="","1","0")
        if "`__ds'"!="1716" | `"`__dt'"'!=`"`precomputed'"' |            ///
            real("`__dn'")!=_N | real("`__dg'")!=`gapmins' |              ///
            real("`__df'")!=`fastsecs' |                                     ///
            "`__da'"!="`__wantall'" {
            di as err "suso paradata timing: internal precomputed event cache uses different timing settings."
            exit 459
        }
        local rolenote : char _dta[suso_para_derived_rolenote]
        if `"`rolenote'"'=="" local rolenote "precomputed interviewer-role events"
    }


    * ---------------- by(question): median seconds per question -----------------
    if "`by'"=="question" {
        * Derive timing on the complete event stream first.  vars() may focus
        * question diagnostics, but it must never remove a session boundary or
        * change an answer gap before that gap is calculated.
        _suso_para_varsel , vars(`"`vars'"')
        capture confirm variable para_var
        if _rc {
            di as err "suso paradata timing: no parameters column in this paradata (reduced export?) — cannot time questions."
            exit 459
        }
        quietly keep if para_fieldans & para_firstpass & para_var!=""
        if _N==0 {
            di as err "suso paradata timing: no AnswerSet events to time."
            exit 2000
        }
        tempvar tag
        quietly bysort para_var interview__id: gen byte `tag' = (_n==1)
        collapse (sum) n_set=para_one n_interviews=`tag' n_fast=para_fast          ///
            (count) n_timed=para_ansgap                                            ///
            (p50) med_s=para_ansgap (p90) p90_s=para_ansgap, by(para_var) fast
        rename para_var variable
        quietly gen double fast_share = n_fast/n_timed if n_timed>0
        label variable variable     "question variable"
        label variable n_set        "answers set"
        label variable n_interviews "interviews answering"
        label variable n_timed      "answers with a timed gap"
        label variable med_s        "median sec to answer"
        label variable p90_s        "p90 sec to answer"
        label variable fast_share   "share answered < `fastsecs' sec"
        format med_s p90_s %9.1f
        format fast_share %5.2f
        gsort -med_s
        char _dta[suso_paradata] qtiming
        char _dta[suso_paradata_schema] 1714
        di as txt "suso paradata: question timing for " as res "`=_N'" as txt ///
            " variable(s) (`rolenote'); sorted slowest first."
        return scalar nvars = _N
        exit
    }

    * ---------------- by(interviewer): pooled per-interviewer -------------------
    if "`by'"=="interviewer" {
        if `"`vars'"'!="" di as txt "  vars(): ignored for interviewer timing; whole-interview behaviour uses the complete field stream."
        quietly keep if para_ivw & para_actor_key!=""
        if _N==0 {
            di as err "suso paradata timing: no interviewer-role events found."
            exit 2000
        }
        tempvar tag
        quietly bysort para_actor interview__id: gen byte `tag' = (_n==1)
        collapse (sum) n_interviews=`tag' n_events=para_one n_answers=para_fieldans  ///
            n_removed=para_fieldrem active_s=para_act n_fast=para_fast n_night=para_night ///
            (count) n_timed=para_ansgap (p50) ans_med_s=para_ansgap                  ///
            (p90) ans_p90_s=para_ansgap, by(para_actor) fast
        rename para_actor responsible
        quietly gen double active_hr   = active_s/3600
        quietly gen double fast_share  = n_fast/n_timed    if n_timed>0
        quietly gen double night_share = n_night/n_answers if n_answers>0
        quietly gen double churn       = n_removed/max(n_answers,1)
        quietly drop active_s
        label variable n_interviews "interviews worked"
        label variable active_hr    "active hours (gap-capped)"
        label variable ans_med_s    "median sec to answer"
        label variable ans_p90_s    "p90 sec to answer"
        label variable fast_share   "share answers < `fastsecs' sec"
        label variable night_share  "share answers 22:00-05:59"
        label variable churn        "AnswerRemoved / AnswerSet"
        format active_hr ans_med_s ans_p90_s %9.1f
        format fast_share night_share churn %5.2f
        sort ans_med_s
        char _dta[suso_paradata] ivtiming
        char _dta[suso_paradata_schema] 1714
        di as txt "suso paradata: interviewer timing for " as res "`=_N'" as txt ///
            " interviewer(s) (`rolenote'); sorted fastest first."
        return scalar nivw = _N
        exit
    }

    * ---------------- by(interview): the canonical QC table ---------------------
    if `"`vars'"'!="" di as txt "  vars(): question detail only; interview timing, behaviour and workflow use all interviewer activity."
    tempfile LPF
    preserve
        quietly keep if para_ivw & para_session>0 & !missing(para_tivw)
        if _N>0 {
            collapse (min) sess_start=para_tivw (max) sess_end=para_tivw       ///
                (max) sess_firstpass=para_firstpass, by(interview__id para_session) fast
            quietly sort interview__id para_session
            quietly by interview__id: gen double __pause =                    ///
                (sess_start-sess_end[_n-1])/60000 if _n>1
            quietly replace __pause = . if __pause<0
            quietly gen double __prepause = __pause if sess_firstpass
            collapse (max) longest_pause_min=__pause                           ///
                longest_precompletion_pause_min=__prepause, by(interview__id) fast
        }
        else {
            quietly clear
            quietly set obs 0
            quietly gen str80 interview__id = ""
            quietly gen double longest_pause_min = .
            quietly gen double longest_precompletion_pause_min = .
        }
        quietly save `"`LPF'"'
    restore

    tempvar ansfirst remfirst fastfirst nightfirst gapfirst daytag daytagfirst   ///
        localday brkfirst brkrework cawians capians cawiansall capiansall       ///
        clockfirst timefirst localfirst modefirst modeall tfirstpass tfirstpasslocal offfirst ///
        pactor pansall pansfirst premall pfast pnight pgap pclock ptime plocal   ///
        pcawi pmode poff pfr
    quietly gen byte `ansfirst' = para_fieldans & para_firstpass
    quietly gen byte `remfirst' = para_fieldrem & para_firstpass
    quietly gen byte `fastfirst' = para_fast if para_firstpass
    quietly gen byte `nightfirst' = para_night & para_firstpass
    quietly gen double `gapfirst' = para_ansgap if para_firstpass
    quietly gen byte `brkfirst' = para_brk & para_firstpass
    quietly gen byte `brkrework' = para_brk & para_rework
    quietly gen byte `cawians' = para_fieldans & para_firstpass & para_cawi==1
    quietly gen byte `capians' = para_fieldans & para_firstpass & para_cawi==0
    quietly gen byte `cawiansall' = para_fieldans & para_cawi==1
    quietly gen byte `capiansall' = para_fieldans & para_cawi==0
    quietly gen byte `clockfirst' = para_clockback & para_firstpass
    quietly gen byte `timefirst' = para_time_missing & para_firstpass
    quietly gen byte `localfirst' = para_local_missing & para_firstpass
    quietly gen byte `modefirst' = para_fieldans & para_firstpass & missing(para_cawi)
    quietly gen byte `modeall' = para_fieldans & missing(para_cawi)
    quietly gen double `tfirstpass' = para_tivw if para_firstpass
    quietly gen double `tfirstpasslocal' = para_tivwl if para_firstpass
    quietly gen double `offfirst' = para_off if para_fieldans & para_firstpass & ///
        para_off_valid
    * Canonical behaviour belongs to the deterministic primary first-pass actor.
    * Keep the all-actor first-pass metrics too for lifecycle/coverage diagnostics.
    quietly gen byte `pactor' = para_actor_key==ustrlower(strtrim(para_primary)) & ///
        para_primary!="" & para_ivw
    quietly gen byte `pansall' = para_fieldans & `pactor'
    quietly gen byte `pansfirst' = para_fieldans & para_firstpass & `pactor'
    quietly gen byte `premall' = para_fieldrem & `pactor'
    quietly gen byte `pfast' = para_fast if `pansfirst'
    quietly gen byte `pnight' = para_night if `pansfirst'
    quietly gen double `pgap' = para_ansgap if `pansfirst'
    quietly gen byte `pclock' = para_clockback & para_firstpass & `pactor'
    quietly gen byte `ptime' = para_time_missing & para_firstpass & `pactor'
    quietly gen byte `plocal' = para_local_missing & para_firstpass & `pactor'
    quietly gen byte `pcawi' = para_cawi if `pansfirst'
    quietly gen byte `pmode' = `pansfirst' & missing(para_cawi)
    quietly gen double `poff' = para_off if `pansfirst' & para_off_valid
    quietly gen long `pfr' = para_fastrun if para_firstpass & `pactor'
    quietly gen long `localday' = dofc(para_tivwl) if !missing(para_tivwl)
    quietly egen byte `daytag' = tag(interview__id `localday') if !missing(`localday')
    quietly egen byte `daytagfirst' = tag(interview__id `localday') if ///
        para_firstpass & !missing(`localday')

    * One primary-tablet offset vote per interview, then the survey mode.  This
    * makes standalone Night flags use the same atypical-offset guard as HTML.
    local __ptzhastz 0
    local __ptzmode 0
    preserve
        quietly keep if `pansfirst' & para_off_valid & !missing(para_off)
        if _N>0 {
            quietly contract interview__id para_off, freq(__pk)
            gsort interview__id -__pk para_off
            quietly by interview__id: keep if _n==1
            * collapse (count) requires a numeric source in Stata.  __pk is the
            * numeric contract frequency and is nonmissing on the one retained
            * row per interview, so counting it gives the intended number of
            * interviews voting for each offset.
            collapse (count) __ni=__pk, by(para_off) fast
            gsort -__ni para_off
            local __ptzmode = para_off[1]
            local __ptzhastz 1
        }
    restore

    collapse (sum) n_events=para_one n_answers=para_fieldans n_removed=para_fieldrem ///
        n_answers_first=`ansfirst' n_removed_first=`remfirst'                    ///
        n_answers_all=para_ans n_removed_all=para_rem n_preload=para_preload         ///
        n_invalid=para_inv n_completed=para_fieldcmp n_restarted=para_fieldrst     ///
        n_completed_all=para_cmp n_restarted_all=para_rst                          ///
        n_rejected=para_rej n_breaks=para_brk                                      ///
        sessions_first=`brkfirst' sessions_rework=`brkrework'                     ///
        active_s=para_act active_s_first=para_act_first                            ///
        n_fast_total=para_fast n_fast=`fastfirst'                                  ///
        n_night_total=para_night n_night=`nightfirst'                              ///
        n_clockback_total=para_clockback n_clockback=`clockfirst'                  ///
        n_time_missing_total=para_time_missing n_time_missing=`timefirst'          ///
        n_local_missing_total=para_local_missing n_local_missing=`localfirst'      ///
        n_mode_unknown_total=`modeall' n_mode_unknown=`modefirst'                  ///
        work_days=`daytag'                                                         ///
        work_days_first=`daytagfirst'                                              ///
        n_cawi_answers=`cawians' n_capi_answers=`capians'                          ///
        n_cawi_answers_total=`cawiansall' n_capi_answers_total=`capiansall'        ///
        primary_n_answers_metric=`pansall'                                         ///
        primary_n_answers_first_metric=`pansfirst'                                 ///
        primary_n_removed_metric=`premall' primary_n_fast=`pfast'                  ///
        primary_n_night=`pnight' primary_n_clockback=`pclock'                      ///
        primary_n_time_missing=`ptime' primary_n_local_missing=`plocal'            ///
        primary_n_mode_unknown=`pmode'                                             ///
        (count) n_timed_total=para_ansgap n_timed=`gapfirst'                       ///
        primary_n_timed=`pgap'                                                     ///
        (p50) ans_med_total_s=para_ansgap ans_med_s=`gapfirst'                     ///
        primary_ans_med_s=`pgap'                                                   ///
        (p90) ans_p90_total_s=para_ansgap ans_p90_s=`gapfirst'                     ///
        primary_ans_p90_s=`pgap'                                                   ///
        (max) fast_run=para_fastrun primary_fast_run=`pfr'                         ///
        (min) primary_cawi_min=`pcawi' primary_off_min=`poff'                      ///
        (max) primary_cawi_max=`pcawi' primary_off_max=`poff'                      ///
        (min) t_first=para_tivw t_first_local=para_tivwl                           ///
        (max) t_last=para_tivw t_last_local=para_tivwl                             ///
        (min) t_first_first=`tfirstpass' t_first_first_local=`tfirstpasslocal'     ///
        (max) t_last_first=`tfirstpass' t_last_first_local=`tfirstpasslocal'       ///
        (min) off_first_min=`offfirst' (max) off_first_max=`offfirst'              ///
        (first) responsible=para_resp primary_interviewer=para_primary             ///
        first_interviewer=para_firstinterviewer last_editor=para_lasteditor        ///
        n_field_actors=para_nactors handoff=para_handoff                           ///
        primary_answers=para_primary_answers primary_questions=para_primary_questions, ///
        by(interview__id) fast

    quietly gen double active_min  = active_s/60
    quietly gen double active_first_min = active_s_first/60
    quietly gen double span_min    = (t_last-t_first)/60000 if !missing(t_first,t_last)
    quietly gen double span_first_min = (t_last_first-t_first_first)/60000 if ///
        !missing(t_first_first,t_last_first)
    quietly gen byte started = (n_answers>0 | n_removed>0 | n_completed>0 | n_restarted>0)
    * Session-start events themselves are boundaries; the first one is session
    * one, not a break plus an extra phantom session.
    quietly gen double sessions = cond(started,max(1,n_breaks),0)
    quietly replace sessions_first = 0 if !started
    quietly replace sessions_rework = 0 if !started
    quietly gen double fast_share  = n_fast/n_timed    if n_timed>0
    quietly gen double fast_share_total = n_fast_total/n_timed_total if n_timed_total>0
    quietly gen double night_share = n_night/n_answers_first if n_answers_first>0
    quietly gen double night_share_total = n_night_total/n_answers if n_answers>0
    quietly gen double churn       = n_removed/max(n_answers,1)
    quietly gen double primary_fast_share = primary_n_fast/primary_n_timed if ///
        primary_n_timed>0
    quietly gen double primary_night_share = primary_n_night/                  ///
        primary_n_answers_first_metric if primary_n_answers_first_metric>0
    quietly gen double primary_churn = primary_n_removed_metric/               ///
        max(primary_n_answers_metric,1)
    quietly gen byte primary_timing_ok = primary_n_clockback==0 &              ///
        primary_n_time_missing==0 & primary_n_mode_unknown==0
    quietly gen byte primary_local_time_ok = primary_n_local_missing==0 &       ///
        primary_n_mode_unknown==0
    quietly gen byte primary_iscawi = primary_cawi_min==1 & primary_cawi_max==1
    quietly gen byte primary_mixedmode = primary_cawi_min!=primary_cawi_max &  ///
        !missing(primary_cawi_min,primary_cawi_max)
    quietly gen byte primary_mode_unknown = primary_n_answers_first_metric>0 & ///
        primary_n_mode_unknown>0
    quietly gen byte primary_tzodd = primary_n_answers_first_metric>0 &         ///
        (missing(primary_off_min) | primary_off_min!=primary_off_max)
    if `__ptzhastz' quietly replace primary_tzodd = 1 if                       ///
        primary_n_answers_first_metric>0 & !missing(primary_off_min) &          ///
        primary_off_min!=`__ptzmode'
    quietly gen double pace_apm    = n_answers/active_min if active_min>0
    quietly gen byte timing_ok = n_clockback==0 & n_time_missing==0 & n_mode_unknown==0
    quietly gen byte timing_ok_total = n_clockback_total==0 & n_time_missing_total==0 & ///
        n_mode_unknown_total==0
    quietly gen byte local_time_ok = n_local_missing==0 & n_mode_unknown==0
    quietly gen byte local_time_ok_total = n_local_missing_total==0 & n_mode_unknown_total==0
    quietly gen byte iscawi = n_cawi_answers>0 & n_capi_answers==0
    quietly gen byte mixedmode = n_cawi_answers>0 & n_capi_answers>0
    quietly gen byte iscawi_total = n_cawi_answers_total>0 & n_capi_answers_total==0
    quietly gen byte mixedmode_total = n_cawi_answers_total>0 & n_capi_answers_total>0
    quietly gen byte mode_unknown = n_answers_first>0 & n_mode_unknown>0
    quietly gen byte mode_unknown_total = n_answers>0 & n_mode_unknown_total>0
    quietly gen byte tzodd_first_all = n_answers_first>0 & ///
        (missing(off_first_min) | off_first_min!=off_first_max)
    quietly gen byte tzodd = tzodd_first_all
    quietly gen byte overnight_precompletion = work_days_first>1 if work_days_first<.
    quietly gen byte postcompletion_return = sessions_rework>0
    quietly merge 1:1 interview__id using `"`LPF'"', keep(master match) nogenerate
    quietly replace longest_pause_min = 0 if sessions<=1 & missing(longest_pause_min)
    quietly replace longest_precompletion_pause_min = 0 if sessions_first<=1 & ///
        missing(longest_precompletion_pause_min)
    quietly drop active_s active_s_first n_breaks n_fast n_fast_total n_night   ///
        n_night_total primary_n_fast primary_n_night primary_n_clockback        ///
        primary_n_time_missing primary_n_local_missing primary_n_mode_unknown   ///
        primary_cawi_min                                                   ///
        primary_cawi_max primary_off_min primary_off_max

    format t_first t_last t_first_local t_last_local t_first_first t_last_first  ///
        t_first_first_local t_last_first_local %tcCCYY-NN-DD_HH:MM:SS
    format active_min active_first_min span_min span_first_min longest_pause_min ///
        longest_precompletion_pause_min ans_med_s ans_p90_s ans_med_total_s     ///
        ans_p90_total_s pace_apm %9.1f
    format fast_share fast_share_total night_share night_share_total churn %5.2f
    label variable interview__id "interview id"
    label variable responsible   "primary first-pass field enumerator"
    label variable primary_interviewer "primary first-pass field enumerator"
    label variable first_interviewer "first field enumerator"
    label variable last_editor "last field editor"
    label variable n_field_actors "distinct field actors"
    label variable handoff "multiple field actors"
    label variable n_events      "paradata events"
    label variable n_answers     "interviewer AnswerSet (preload excluded)"
    label variable n_removed     "interviewer AnswerRemoved"
    label variable n_answers_all "AnswerSet events (all roles, incl. preload)"
    label variable n_removed_all "AnswerRemoved events (all roles)"
    label variable n_preload     "initial preload AnswerSet events"
    label variable n_invalid     "validation-error events"
    label variable n_completed   "Completed events"
    label variable n_restarted   "Restarted events"
    label variable n_completed_all "Completed events (all roles)"
    label variable n_restarted_all "Restarted events (all roles)"
    label variable n_rejected    "rejections (SV+HQ)"
    label variable n_timed       "first-pass answers with a timed gap"
    label variable n_timed_total "all answers with a timed gap"
    label variable sessions      "work sessions"
    label variable span_min      "first-to-last fieldwork event, min"
    label variable active_min    "active time, min (gap-capped)"
    label variable active_first_min "active time through first completion, min"
    label variable ans_med_s     "first-pass median sec to answer"
    label variable ans_p90_s     "first-pass p90 sec to answer"
    label variable fast_share    "first-pass share answers < `fastsecs' sec"
    label variable fast_run      "longest first-pass fast-answer run (actor/session safe)"
    label variable primary_n_timed "primary actor first-pass timed answers"
    label variable primary_ans_med_s "primary actor first-pass median sec to answer"
    label variable primary_fast_share "primary actor first-pass fast share"
    label variable primary_fast_run "primary actor longest first-pass fast run"
    label variable primary_night_share "primary actor first-pass night share"
    label variable primary_churn "primary actor AnswerRemoved / AnswerSet"
    label variable night_share   "share answers 22:00-05:59"
    label variable churn         "AnswerRemoved / AnswerSet"
    label variable pace_apm      "answers per active minute"
    label variable started       "fieldwork started (any interviewer activity)"
    order interview__id responsible primary_interviewer first_interviewer last_editor ///
        n_field_actors handoff started n_events n_answers n_removed n_preload          ///
        n_answers_all n_removed_all n_invalid                                      ///
        n_completed n_restarted n_rejected sessions sessions_first sessions_rework  ///
        span_min span_first_min longest_pause_min longest_precompletion_pause_min ///
        work_days work_days_first                                                  ///
        overnight_precompletion postcompletion_return active_min active_first_min    ///
        ans_med_s ans_p90_s fast_share fast_run night_share churn pace_apm t_first t_last
    sort interview__id

    char _dta[suso_paradata]      timing
    char _dta[suso_paradata_schema] 1714
    char _dta[suso_para_gapmins]  `gapmins'
    char _dta[suso_para_fastsecs] `fastsecs'

    quietly summarize active_min, detail
    local medact : di %9.1f r(p50)
    local tothr  : di %9.1f r(sum)/60
    quietly summarize ans_med_s, detail
    local medans : di %9.1f r(p50)
    di as txt "suso paradata: timing built for " as res "`=_N'" as txt " interview(s)  (`rolenote')."
    di as txt "  median active time " as res trim("`medact'") as txt " min   |   median sec/answer " ///
        as res trim("`medans'") as txt "   |   total interviewer time " as res trim("`tothr'") as txt " hr"
    di as txt "  gaps capped at " as res "`gapmins'" as txt " min; fast answer = < " ///
        as res "`fastsecs'" as txt " sec.   Next:  {bf:suso paradata flags}"
    di as txt "  how to read: {bf:active_min} = hands-on time; a median {bf:ans_med_s} under ~2s or"
    di as txt "  {bf:fast_share} above ~0.3 in a completed interview suggests speeding — see {bf:flags}."
    return scalar nints     = _N
    return scalar medactive = real("`medact'")
    return scalar medans    = real("`medans'")
end

* ---- flags: per-interview red flags + interviewer league table -----------------
program _suso_para_flags, rclass
    version 14.2
    syntax [, GAPMins(real 30) FASTsecs(real 2) ALLRoles MINactive(real 5)      ///
        BURSTrun(integer 8) BURSTshare(real -1) NIGHTshare(real 0.25) CHURN(real 0.20) ///
        Zcut(real 3.5) TOP(integer 15) SAVing(string) replace ]

    local kind : char _dta[suso_paradata]
    if "`kind'"=="events" {
        quietly _suso_para_timing , by(interview) gapmins(`gapmins') fastsecs(`fastsecs') `allroles'
    }
    else if "`kind'"=="timing" {
        local __tschema : char _dta[suso_paradata_schema]
        local __oldtiming = (`"`__tschema'"'!="1714")
        foreach __tv in primary_n_answers_metric primary_n_answers_first_metric ///
            primary_n_timed primary_ans_med_s primary_fast_share               ///
            primary_fast_run primary_mode_unknown active_first_min             ///
            timing_ok local_time_ok mode_unknown iscawi mixedmode {
            capture confirm variable `__tv', exact
            if _rc local __oldtiming 1
        }
        if `__oldtiming' {
            di as err "suso paradata flags: this timing table was built by an older package."
            di as err "                     Reload the original paradata events and rebuild timing."
            exit 459
        }
    }
    else {
        _suso_para_need events    // prints the friendly "load first" error
    }
    local gapused  : char _dta[suso_para_gapmins]
    if "`gapused'"=="" local gapused `gapmins'

    capture drop f_speed f_burst f_short f_night f_churn f_outlier n_flags z_active

    * absolute-threshold flags (missing-safe: a missing metric never flags)
    capture confirm variable fast_run, exact
    if _rc quietly gen long fast_run = 0
    capture confirm variable timing_ok, exact
    if _rc quietly gen byte timing_ok = 1
    capture confirm variable local_time_ok, exact
    if _rc quietly gen byte local_time_ok = 1
    capture confirm variable active_first_min, exact
    if _rc quietly gen double active_first_min = active_min
    capture confirm variable iscawi, exact
    if _rc quietly gen byte iscawi = 0
    capture confirm variable mixedmode, exact
    if _rc quietly gen byte mixedmode = 0
    capture confirm variable mode_unknown, exact
    if _rc quietly gen byte mode_unknown = 0
    capture confirm variable tzodd, exact
    if _rc quietly gen byte tzodd = 0
    * Preserve whole-first-pass quality/mode for duration signals before any
    * primary-actor behaviour projection.
    capture confirm variable interview_timing_ok, exact
    if _rc quietly gen byte interview_timing_ok = timing_ok
    capture confirm variable interview_local_time_ok, exact
    if _rc quietly gen byte interview_local_time_ok = local_time_ok
    capture confirm variable interview_iscawi, exact
    if _rc quietly gen byte interview_iscawi = iscawi
    capture confirm variable interview_mixedmode, exact
    if _rc quietly gen byte interview_mixedmode = mixedmode
    capture confirm variable interview_mode_unknown, exact
    if _rc quietly gen byte interview_mode_unknown = mode_unknown
    * In a standalone timing table, score actor-owned behaviour on the same
    * deterministic primary actor used by the HTML.  In the report path pa_*
    * has already been projected into the ordinary columns, so keep those.
    local vmed ans_med_s
    local vtimed n_timed
    local vrun fast_run
    local vnight night_share
    local vchurn churn
    local vtq timing_ok
    local vlq local_time_ok
    local vcawi iscawi
    local vmixed mixedmode
    local vmode mode_unknown
    local vtzodd tzodd
    local vans n_answers
    capture confirm variable pa_timed, exact
    local __reportpath = !_rc
    if `__reportpath' local vans pa_answers
    if !`__reportpath' {
        capture confirm variable primary_n_timed, exact
        if !_rc {
            local vmed primary_ans_med_s
            local vtimed primary_n_timed
            local vrun primary_fast_run
            local vnight primary_night_share
            local vchurn primary_churn
            local vtq primary_timing_ok
            local vlq primary_local_time_ok
            local vcawi primary_iscawi
            local vmixed primary_mixedmode
            local vmode primary_mode_unknown
            local vtzodd primary_tzodd
            local vans primary_n_answers_metric
        }
    }
    tempvar capiok durcapi durtiming churnsupport
    quietly gen byte `capiok' = `vcawi'!=1 & `vmixed'!=1 & `vmode'!=1
    quietly gen byte `durtiming' = interview_timing_ok
    quietly gen byte `durcapi' = interview_iscawi!=1 & interview_mixedmode!=1 & ///
        interview_mode_unknown!=1
    quietly gen double `churnsupport' = `vans'
    if `burstshare'>=0 di as txt "  note: burstshare() is deprecated; B now consistently means fast_run >= burstrun()."
    quietly gen byte f_speed = `capiok' & `vtq' & !missing(`vmed') & ///
        `vmed'<`fastsecs' & `vtimed'>=10
    quietly gen byte f_burst = `capiok' & `vtq' & `vrun'>=`burstrun' & `vtimed'>=10
    quietly gen byte f_short = `durcapi' & `durtiming' & n_completed>0 & active_first_min<`minactive'
    quietly gen byte f_night = `capiok' & `vlq' & `vtzodd'!=1 & !missing(`vnight') & ///
        `vnight'>`nightshare' & `vtimed'>=10
    quietly gen byte f_churn = !missing(`vchurn') & `vchurn' > `churn' & `churnsupport'>=10

    * Make the standalone flags table self-explanatory: its displayed behaviour
    * columns are the same primary-actor metrics that generated S/B/N/C.  Retain
    * the former all-first-pass values under explicit audit names.
    if !`__reportpath' & "`vmed'"=="primary_ans_med_s" {
        capture confirm variable all_first_n_timed, exact
        if _rc quietly gen double all_first_n_timed = n_timed
        capture confirm variable all_first_ans_med_s, exact
        if _rc quietly gen double all_first_ans_med_s = ans_med_s
        capture confirm variable all_first_ans_p90_s, exact
        if _rc quietly gen double all_first_ans_p90_s = ans_p90_s
        capture confirm variable all_first_fast_share, exact
        if _rc quietly gen double all_first_fast_share = fast_share
        capture confirm variable all_first_fast_run, exact
        if _rc quietly gen double all_first_fast_run = fast_run
        capture confirm variable all_first_night_share, exact
        if _rc quietly gen double all_first_night_share = night_share
        capture confirm variable all_actor_churn, exact
        if _rc quietly gen double all_actor_churn = churn
        quietly replace n_timed = primary_n_timed
        quietly replace ans_med_s = primary_ans_med_s
        quietly replace ans_p90_s = primary_ans_p90_s
        quietly replace fast_share = primary_fast_share
        quietly replace fast_run = primary_fast_run
        quietly replace night_share = primary_night_share
        quietly replace churn = primary_churn
        quietly replace timing_ok = primary_timing_ok
        quietly replace local_time_ok = primary_local_time_ok
        quietly replace iscawi = primary_iscawi
        quietly replace mixedmode = primary_mixedmode
        quietly replace mode_unknown = primary_mode_unknown
        quietly replace tzodd = primary_tzodd
    }

    * robust two-sided outlier on log active time (modified z, Iglewicz-Hoaglin)
    quietly gen byte f_outlier = 0
    quietly gen double z_active = .
    tempvar lx dev
    quietly gen double `lx' = ln(active_first_min) if active_first_min>0 & `durtiming' & `durcapi'
    quietly summarize `lx', detail
    if r(N)>=10 {
        local medlx = r(p50)
        quietly gen double `dev' = abs(`lx'-`medlx')
        quietly summarize `dev', detail
        if r(p50)>0 {
            quietly replace z_active  = 0.6745*(`lx'-`medlx')/r(p50)
            quietly replace f_outlier = abs(z_active)>`zcut' & !missing(z_active)
        }
    }
    label variable z_active "robust z of ln(active_min)"

    quietly gen byte n_flags = f_speed+f_burst+f_short+f_night+f_churn+f_outlier
    label variable f_speed   "median sec/answer < `fastsecs' (10+ timed answers)"
    label variable f_burst   "fast-answer run >= `burstrun'"
    label variable f_short   "completed with active < `minactive' min"
    label variable f_night   "night share > `nightshare'"
    label variable f_churn   "answer churn > `churn'"
    label variable f_outlier "robust |z| active time > `zcut'"
    label variable n_flags   "number of flags raised"
    char _dta[suso_paradata] timing
    char _dta[suso_paradata_schema] 1714

    * ---- summary ----
    local nints = _N
    quietly count if n_flags>0
    local nflag = r(N)
    local pflag : di %4.1f 100*`nflag'/max(`nints',1)
    foreach f in speed burst short night churn outlier {
        quietly count if f_`f'
        local c_`f' = r(N)
    }
    di as txt _n "{hline 72}"
    di as res "  suso paradata flags" as txt "   (`nints' interviews; gaps capped at `gapused' min)"
    di as txt "{hline 72}"
    di as txt "  flagged interviews : " as res "`nflag'" as txt "  (" as res trim("`pflag'") as txt "%)"
    di as txt "    S  sustained speeding   median sec/answer < `fastsecs'        : " as res "`c_speed'"
    di as txt "    B  answer bursts        fast-answer run >= `burstrun'          : " as res "`c_burst'"
    di as txt "    T  too short            completed, active < `minactive' min       : " as res "`c_short'"
    di as txt "    N  night work           night share > `nightshare' (10+ timed ans): " as res "`c_night'"
    di as txt "    C  answer churn         removed/set > `churn' (10+ answers)       : " as res "`c_churn'"
    di as txt "    Z  duration outlier     robust |z| > `zcut'                   : " as res "`c_outlier'"

    * ---- top flagged interviews ----
    if `nflag'>0 {
        gsort -n_flags ans_med_s interview__id
        local k = min(`top', `nflag')
        di as txt _n "  top `k' flagged interview(s):"
        di as txt "  {ul:interview}  {ul:interviewer }  {ul:flags }  {ul: act.min}  {ul:sec/ans}  {ul:fast}  {ul:night}"
        forvalues i = 1/`k' {
            local id8 = substr(interview__id[`i'],1,8)
            local rsp : di %-12s abbrev(responsible[`i'],12)
            local pat = cond(f_speed[`i'],"S","-") + cond(f_burst[`i'],"B","-")   ///
                      + cond(f_short[`i'],"T","-") + cond(f_night[`i'],"N","-")   ///
                      + cond(f_churn[`i'],"C","-") + cond(f_outlier[`i'],"Z","-")
            local am : di %8.1f active_min[`i']
            local ms : di %7.1f ans_med_s[`i']
            local fs : di %4.2f fast_share[`i']
            local ns : di %5.2f night_share[`i']
            di as txt "  " as res "`id8'" as txt "   `rsp'" as txt " " as res "`pat'" ///
                as txt " `am'  `ms'  `fs'  `ns'"
        }
        sort interview__id
    }

    * ---- interviewer league table (share of their interviews flagged) ----
    quietly count if responsible!=""
    if r(N)>0 {
        preserve
        quietly gen byte __any = n_flags>0
        collapse (count) n_ints=n_flags (sum) n_flagged=__any                    ///
            (p50) ans_med_s active_min (mean) fast_share night_share, by(responsible) fast
        quietly drop if responsible==""
        quietly gen double flag_share = n_flagged/n_ints
        gsort -flag_share -n_flagged responsible
        local k = min(10, _N)
        di as txt _n "  interviewers, by share of interviews flagged (top `k'):"
        di as txt "  {ul:interviewer     }  {ul:ints}  {ul:flagged}  {ul:share}  {ul:med act.min}  {ul:med sec/ans}"
        forvalues i = 1/`k' {
            local rsp : di %-16s abbrev(responsible[`i'],16)
            local ni  : di %4.0f n_ints[`i']
            local nf  : di %5.0f n_flagged[`i']
            local sh  : di %5.2f flag_share[`i']
            local am  : di %9.1f active_min[`i']
            local ms  : di %9.1f ans_med_s[`i']
            di as txt "  `rsp'  `ni'   `nf'   " as res "`sh'" as txt "    `am'      `ms'"
        }
        restore
    }
    di as txt _n "  data in memory = one row per interview with f_* flags (see {bf:describe})."
    di as txt "{hline 72}"

    if `"`saving'"'!="" {
        if "`replace'"=="" {
            capture confirm new file `"`saving'"'
            if _rc {
                di as err "suso: file already exists. Use -replace-."
                exit 602
            }
        }
        quietly save `"`saving'"', `replace'
        di as txt "suso paradata: flag table saved to " as res `"`saving'"'
    }

    return scalar nints    = `nints'
    return scalar nflagged = `nflag'
    foreach f in speed burst short night churn outlier {
        return scalar n_`f' = `c_`f''
    }
end

* ---- final-data adjudication for affected question instances -----------------
* Input using-file: one row per interview x removal-run x question instance.
* Output: exact final-data state and effective enablement classification.
program _suso_para_casefinal, rclass
    version 14.2
    syntax using/ , DATA(string) SAVing(string) [ QXMETA(string) ]
    confirm file `"`using'"'
    confirm file `"`data'"'

    tempfile CASES IDS FD META ACC VC ONE
    quietly use `"`using'"', clear
    foreach v in interview__id sk_run affected_var affected_roster affected_qkey affected_qdisp {
        capture confirm variable `v', exact
        if _rc {
            di as err "suso paradata: internal final-data check is missing `v'."
            exit 459
        }
    }
    quietly save `"`CASES'"'

    preserve
        quietly keep interview__id
        quietly duplicates drop
        quietly save `"`IDS'"'
    restore

    * Restrict the final export to interviews that appear in the removal cases.
    quietly use `"`data'"', clear
    capture confirm string variable interview__id
    if _rc {
        di as err "suso paradata skips: data() must contain string interview__id."
        exit 459
    }
    quietly merge m:1 interview__id using `"`IDS'"', keep(match) nogenerate
    quietly duplicates drop
    tempvar __dup
    quietly bysort interview__id: gen byte `__dup' = _N>1
    quietly count if `__dup'
    if r(N)>0 {
        di as err "suso paradata skips: data() has duplicate interview__id rows with different final values."
        di as err "                      Supply the one-row-per-interview main export, not a roster export."
        exit 459
    }
    quietly drop `__dup'
    * Survey Solutions' exported missing sentinels must be blank before both
    * answer-state checks and enablement expressions are evaluated.  Otherwise
    * -999999999 can falsely resolve a removed answer as present.
    quietly ds, has(type numeric)
    local __numvars `r(varlist)'
    foreach __z of local __numvars {
        quietly replace `__z' = . if `__z'==-999999999
    }
    quietly ds, has(type string)
    local __strvars `r(varlist)'
    foreach __z of local __strvars {
        if "`__z'"!="interview__id" quietly replace `__z' = "" if ///
            upper(strtrim(`__z'))=="##N/A##"
    }
    quietly save `"`FD'"'

    * Merge inherited questionnaire conditions onto every affected variable.
    quietly use `"`CASES'"', clear
    if `"`qxmeta'"'!="" {
        preserve
            quietly use `"`qxmeta'"', clear
            quietly keep qx_var qx_type qx_section qx_subsection qx_section_enable ///
                qx_group_enable qx_item_enable qx_enable qx_enable_deps          ///
                qx_calc qx_section_tri qx_group_tri qx_item_tri
            quietly bysort qx_var: keep if _n==1
            quietly rename qx_var affected_var
            quietly gen byte qx_known = 1
            quietly save `"`META'"'
        restore
        quietly merge m:1 affected_var using `"`META'"', keep(master match) nogenerate
    }
    capture confirm variable qx_known
    if _rc quietly gen byte qx_known = 0
    foreach v in qx_type qx_section qx_subsection qx_section_enable qx_group_enable ///
        qx_item_enable qx_enable qx_enable_deps qx_calc qx_section_tri            ///
        qx_group_tri qx_item_tri {
        capture confirm variable `v', exact
        if _rc quietly gen strL `v' = ""
    }
    quietly replace qx_known = 0 if missing(qx_known)
    quietly save `"`CASES'"', replace
    quietly levelsof affected_var, local(avars) clean

    * Empty accumulator with the same identifying fields.
    quietly use `"`CASES'"', clear
    quietly keep if 0
    quietly gen byte final_status = .
    quietly gen byte final_answered = .
    quietly gen byte final_enabled = .
    quietly gen double final_enable_tri = .
    quietly gen strL final_note = ""
    quietly save `"`ACC'"', replace

    foreach v of local avars {
        quietly use `"`CASES'"', clear
        quietly keep if affected_var=="`v'"
        if _N==0 continue
        local qknown = qx_known[1]
        local secraw `"`=qx_section_enable[1]'"'
        local grpraw `"`=qx_group_enable[1]'"'
        local itemraw `"`=qx_item_enable[1]'"'
        local secexpr `"`=qx_section_tri[1]'"'
        local grpexpr `"`=qx_group_tri[1]'"'
        local itemexpr `"`=qx_item_tri[1]'"'
        local qtype `"`=lower(qx_type[1])'"'
        local ismulti = strpos(`"`qtype'"',"multi")>0 | strpos(`"`qtype'"',"multy")>0
        local isyesno = strpos(`"`qtype'"',"yes/no")>0 | strpos(`"`qtype'"',"yesno")>0
        local iscombo = strpos(`"`qtype'"',"combo")>0
        local isordered = strpos(`"`qtype'"',"ordered")>0 | strpos(`"`qtype'"',"rank")>0

        * Roster instances require the corresponding roster export, not the main
        * one-row-per-interview file supplied to suite data().
        preserve
            quietly keep if affected_roster!=""
            if _N>0 {
                quietly gen byte final_status = 6
                quietly gen byte final_answered = .
                quietly gen byte final_enabled = .
                quietly gen double final_enable_tri = .
                quietly gen strL final_note = "roster instance - check the corresponding roster export"
                quietly append using `"`ACC'"'
                quietly save `"`ACC'"', replace
            }
        restore
        quietly keep if affected_roster==""
        if _N==0 continue
        quietly save `"`VC'"', replace

        quietly use `"`FD'"', clear
        tempvar __final_answered __final_enabled __final_enable_tri          ///
            __section_tri __group_tri __item_tri
        local splitvars ""
        capture confirm variable `v', exact
        if _rc {
            capture unab splitvars : `v'__*
            if _rc {
                quietly use `"`VC'"', clear
                quietly gen byte final_status = 5
                quietly gen byte final_answered = .
                quietly gen byte final_enabled = .
                quietly gen double final_enable_tri = .
                quietly gen strL final_note = "variable not found in supplied data() file"
                quietly append using `"`ACC'"'
                quietly save `"`ACC'"', replace
                continue
            }
        }

        if `"`splitvars'"'=="" {
            capture confirm numeric variable `v'
            if !_rc quietly gen byte `__final_answered' = !missing(`v')
            else quietly gen byte `__final_answered' = (`v'!="" & `v'!="##N/A##")
        }
        else {
            * Split exports have two distinct shapes. Checkbox multi-selects
            * use 0/1 option dummies; combobox/ordered multi-selects and list
            * questions store values in their members. Detect an unexpected
            * non-dummy family conservatively when presentation metadata is old.
            local splitvalues = `iscombo' | `isordered'
            if `ismulti' & !`isyesno' & !`splitvalues' {
                tempvar __nondummy
                quietly gen byte `__nondummy' = 0
                foreach sv of local splitvars {
                    capture confirm numeric variable `sv'
                    if !_rc quietly replace `__nondummy' = 1 if ///
                        !missing(`sv') & !inlist(`sv',0,1)
                    else quietly replace `__nondummy' = 1 if !inlist( ///
                        lower(strtrim(`sv')),"","0","1","false","true", ///
                        "no","yes","##n/a##")
                }
                quietly count if `__nondummy'
                if r(N)>0 local splitvalues 1
                quietly drop `__nondummy'
            }
            quietly gen byte `__final_answered' = 0
            foreach sv of local splitvars {
                capture confirm numeric variable `sv'
                if !_rc {
                    if `ismulti' & !`isyesno' & !`splitvalues' ///
                        quietly replace `__final_answered' = 1 if `sv'==1
                    else quietly replace `__final_answered' = 1 if !missing(`sv')
                }
                else {
                    if `ismulti' & !`isyesno' & !`splitvalues' ///
                        quietly replace `__final_answered' = 1 if ///
                        !inlist(lower(strtrim(`sv')),"","0","false","no","##n/a##")
                    else quietly replace `__final_answered' = 1 if `sv'!="" & `sv'!="##N/A##"
                }
            }
        }

        * Each hierarchy component is evaluated separately. Tri-state values use
        * 0=false, 1=true, .5=unknown; AND is min(), so a known false parent
        * correctly disables a child even when the child's own referent is blank.
        foreach c in sec grp item {
            local raw  `"``c'raw'"'
            local expr `"``c'expr'"'
            local tri "`__item_tri'"
            if "`c'"=="sec" local tri "`__section_tri'"
            if "`c'"=="grp" local tri "`__group_tri'"
            if `qknown'!=1 {
                quietly gen double `tri' = .5
            }
            else if strtrim(`"`raw'"')=="" {
                quietly gen double `tri' = 1
            }
            else if strtrim(`"`expr'"')=="" {
                quietly gen double `tri' = .5
            }
            else {
                capture quietly gen double `tri' = (`expr')
                if _rc quietly gen double `tri' = .5
                else quietly replace `tri' = .5 if missing(`tri') | ///
                    !inlist(`tri',0,.5,1)
            }
        }
        quietly gen double `__final_enable_tri' = min(`__section_tri',`__group_tri',`__item_tri')
        quietly gen byte `__final_enabled' = cond(`__final_enable_tri'==.5,.,`__final_enable_tri')
        quietly keep interview__id `__final_answered' `__final_enabled' `__final_enable_tri'
        quietly rename `__final_answered' final_answered
        quietly rename `__final_enabled' final_enabled
        quietly rename `__final_enable_tri' final_enable_tri
        quietly save `"`ONE'"', replace

        quietly use `"`VC'"', clear
        * ONE is built from all removal-case interviews that exist in data().
        * For the current affected variable, VC can be a strict subset.  Never
        * admit using-only rows here: they have no sk_run/affected identifiers
        * and would corrupt the run-level accumulator.
        quietly merge m:1 interview__id using `"`ONE'"', ///
            keep(master match) gen(__fm)
        quietly gen byte final_status = 5 if __fm==1
        quietly replace final_status = 1 if __fm==3 & final_answered==1 & ///
            (final_enabled==1 | missing(final_enabled))
        quietly replace final_status = 7 if __fm==3 & final_answered==1 & final_enabled==0
        quietly replace final_status = 2 if __fm==3 & final_answered==0 & final_enabled==0
        quietly replace final_status = 3 if __fm==3 & final_answered==0 & final_enabled==1
        quietly replace final_status = 4 if __fm==3 & final_answered==0 & missing(final_enabled)
        quietly gen strL final_note = ""
        quietly replace final_note = "answered in final data" if final_status==1
        quietly replace final_note = "answered although final questionnaire logic disables it" if final_status==7
        quietly replace final_note = "blank as expected - final questionnaire logic disables it" if final_status==2
        quietly replace final_note = "blank although final questionnaire logic enables it" if final_status==3
        quietly replace final_note = "blank and final enablement could not be evaluated" if final_status==4
        quietly replace final_note = "interview not found in supplied data() file" if final_status==5
        quietly drop __fm
        quietly append using `"`ACC'"'
        quietly save `"`ACC'"', replace
    }

    quietly use `"`ACC'"', clear
    quietly sort interview__id sk_run affected_qdisp
    quietly save `"`saving'"', replace
    quietly count if final_status==1
    return scalar n_answered = r(N)
    quietly count if final_status==7
    return scalar n_answereddisabled = r(N)
    quietly count if final_status==2
    return scalar n_expectedblank = r(N)
    quietly count if inlist(final_status,3,4,5,6,7)
    return scalar n_check = r(N)
end

* ---- final exported value for the nearby/linked AnswerSet ---------------------
* The answer transition shown in a removal card is historical. This helper keeps
* that event separate from the current value in the supplied final main export.
program _suso_para_triggerfinal, rclass
    version 14.2
    syntax using/ , DATA(string) SAVing(string)
    confirm file `"`using'"'
    confirm file `"`data'"'

    tempfile CASES IDS FD ACC VC ONE
    quietly use `"`using'"', clear
    foreach v in interview__id sk_run trigger trigger_roster trigval oldval qx_optmap qx_type {
        capture confirm variable `v'
        if _rc {
            di as err "suso paradata: internal historical/final value check is missing `v'."
            exit 459
        }
    }
    quietly bysort interview__id sk_run: keep if _n==1
    quietly save `"`CASES'"'

    preserve
        quietly keep interview__id
        quietly duplicates drop
        quietly save `"`IDS'"'
    restore

    quietly use `"`data'"', clear
    capture confirm string variable interview__id
    if _rc {
        di as err "suso paradata skips: data() must contain string interview__id."
        exit 459
    }
    quietly merge m:1 interview__id using `"`IDS'"', keep(match) nogenerate
    quietly duplicates drop
    tempvar __dup
    quietly bysort interview__id: gen byte `__dup' = _N>1
    quietly count if `__dup'
    if r(N)>0 {
        di as err "suso paradata skips: data() has duplicate interview__id rows with different final values."
        di as err "                      Supply the one-row-per-interview main export, not a roster export."
        exit 459
    }
    quietly drop `__dup'
    * Apply the same canonical Survey Solutions missing sentinels used by the
    * data-QC path before reconstructing parent or split final values.
    quietly ds, has(type numeric)
    local __numvars `r(varlist)'
    foreach __z of local __numvars {
        quietly replace `__z' = . if `__z'==-999999999
    }
    quietly ds, has(type string)
    local __strvars `r(varlist)'
    foreach __z of local __strvars {
        if "`__z'"!="interview__id" quietly replace `__z' = "" if ///
            upper(strtrim(`__z'))=="##N/A##"
    }
    quietly save `"`FD'"'

    quietly use `"`CASES'"', clear
    quietly keep if 0
    quietly gen byte trigger_final_status = .
    quietly gen strL trigger_final_value = ""
    quietly gen strL trigger_final_label = ""
    quietly gen strL trigger_final_show = ""
    quietly gen byte trigger_final_matches_event = .
    quietly gen byte trigger_final_returns_old = .
    quietly gen strL trigger_final_text = ""
    quietly save `"`ACC'"', replace

    quietly use `"`CASES'"', clear
    quietly levelsof trigger, local(tvars) clean
    foreach v of local tvars {
        quietly use `"`CASES'"', clear
        quietly keep if trigger=="`v'"
        local qtype `"`=lower(qx_type[1])'"'
        local ismulti = strpos(`"`qtype'"',"multi")>0 | strpos(`"`qtype'"',"multy")>0
        local istextlist = strpos(`"`qtype'"',"text list")>0 | strpos(`"`qtype'"',"textlist")>0
        local iscombo = strpos(`"`qtype'"',"combo")>0
        local isordered = strpos(`"`qtype'"',"ordered")>0 | strpos(`"`qtype'"',"rank")>0

        * Main exports have one row per interview and cannot identify roster rows.
        preserve
            quietly keep if trigger_roster!=""
            if _N>0 {
                quietly gen byte trigger_final_status = 4
                quietly gen strL trigger_final_value = ""
                quietly gen strL trigger_final_label = ""
                quietly gen strL trigger_final_show = ""
                quietly gen byte trigger_final_matches_event = .
                quietly gen byte trigger_final_returns_old = .
                quietly gen strL trigger_final_text = ///
                    "Final export value was not checked because this is a roster instance; use the corresponding roster export."
                quietly append using `"`ACC'"'
                quietly save `"`ACC'"', replace
            }
        restore
        quietly keep if trigger_roster==""
        if _N==0 continue
        quietly save `"`VC'"', replace

        quietly use `"`FD'"', clear
        tempvar __trigger_final_value
        local splitvars ""
        capture confirm variable `v', exact
        if _rc {
            capture unab splitvars : `v'__*
            if _rc {
                quietly use `"`VC'"', clear
                quietly gen byte trigger_final_status = 3
                quietly gen strL trigger_final_value = ""
                quietly gen strL trigger_final_label = ""
                quietly gen strL trigger_final_show = ""
                quietly gen byte trigger_final_matches_event = .
                quietly gen byte trigger_final_returns_old = .
                quietly gen strL trigger_final_text = ///
                    "Final export value was not checked because the answer-event variable is not present in data()."
                quietly append using `"`ACC'"'
                quietly save `"`ACC'"', replace
                continue
            }
        }

        * Ordered/ranked multi-select families encode ranks against option-code
        * suffixes, while old metadata may not identify whether a non-dummy
        * family is ordered or combobox. Do not manufacture an exact value in
        * either ambiguous case; return an explicit not-evaluable status.
        local splitunsupported 0
        local splitwhy ""
        if `"`splitvars'"'!="" & `isordered' {
            local splitunsupported 1
            local splitwhy "ordered/ranked split multi-select export"
        }
        else if `"`splitvars'"'!="" & `ismulti' & !`iscombo' {
            tempvar __nondummy
            quietly gen byte `__nondummy' = 0
            foreach sv of local splitvars {
                capture confirm numeric variable `sv'
                if !_rc quietly replace `__nondummy' = 1 if ///
                    !missing(`sv') & !inlist(`sv',0,1)
                else quietly replace `__nondummy' = 1 if !inlist( ///
                    lower(strtrim(`sv')),"","0","1","false","true", ///
                    "no","yes","##n/a##")
            }
            quietly count if `__nondummy'
            if r(N)>0 {
                local splitunsupported 1
                local splitwhy "split multi-select export with unknown presentation"
            }
            quietly drop `__nondummy'
        }
        if `splitunsupported' {
            quietly use `"`VC'"', clear
            quietly gen byte trigger_final_status = 6
            quietly gen strL trigger_final_value = ""
            quietly gen strL trigger_final_label = ""
            quietly gen strL trigger_final_show = ""
            quietly gen byte trigger_final_matches_event = .
            quietly gen byte trigger_final_returns_old = .
            quietly gen strL trigger_final_text = ///
                "Final export value was not compared because `splitwhy' cannot be reconstructed exactly without presentation metadata."
            quietly append using `"`ACC'"'
            quietly save `"`ACC'"', replace
            continue
        }

        if `"`splitvars'"'=="" {
            capture confirm numeric variable `v'
            if !_rc quietly gen strL `__trigger_final_value' = ///
                cond(missing(`v'), "", strtrim(string(`v', "%21.0g")))
            else quietly gen strL `__trigger_final_value' = ///
                cond(`v'=="" | `v'=="##N/A##", "", `v')
        }
        else {
            * Reconstruct the documented parent value. Checkbox multi-select
            * dummies contribute their option-code suffix; combobox slots and
            * ordinary split values contribute their cell value. Text lists use
            * a vertical bar, while categorical values use commas.
            local splitsep = cond(`istextlist',"|",",")
            quietly gen strL `__trigger_final_value' = ""
            foreach sv of local splitvars {
                local suffix = substr("`sv'",length("`v'")+3,.)
                tempvar svtxt take
                capture confirm numeric variable `sv'
                if !_rc {
                    quietly gen strL `svtxt' = cond(missing(`sv'),"",      ///
                        strtrim(string(`sv',"%21.0g")))
                    if `ismulti' & !`iscombo' {
                        quietly gen byte `take' = (`sv'==1) if !missing(`sv')
                        quietly replace `svtxt' = "`suffix'" if `take'==1
                        quietly replace `svtxt' = "" if `take'!=1
                    }
                }
                else {
                    quietly gen strL `svtxt' = cond(`sv'=="" | `sv'=="##N/A##","",`sv')
                    if `ismulti' & !`iscombo' {
                        quietly gen byte `take' = !inlist(lower(strtrim(`sv')),"","0","false","no")
                        quietly replace `svtxt' = "`suffix'" if `take'==1
                        quietly replace `svtxt' = "" if `take'!=1
                    }
                }
                quietly replace `__trigger_final_value' = `__trigger_final_value' +   ///
                    cond(`__trigger_final_value'!="" & `svtxt'!="","`splitsep'","") + `svtxt'
                quietly drop `svtxt'
                capture quietly drop `take'
            }
        }
        quietly keep interview__id `__trigger_final_value'
        quietly rename `__trigger_final_value' trigger_final_value
        quietly save `"`ONE'"', replace

        quietly use `"`VC'"', clear
        * ONE contains every removal-case interview in the final export, while
        * VC contains only runs whose selected trigger is `v'.  Keeping using-only
        * rows would create observations with missing sk_run and make the final
        * run-key isid fail (notably under vars() on heterogeneous interviews).
        quietly merge m:1 interview__id using `"`ONE'"', ///
            keep(master match) gen(__tf)
        quietly gen byte trigger_final_status = 5 if __tf==1
        quietly replace trigger_final_status = 2 if __tf==3 & trigger_final_value==""
        quietly replace trigger_final_status = 1 if __tf==3 & trigger_final_value!=""
        quietly gen strL trigger_final_label = ""
        quietly gen strL __dummy_label = ""
        mata: _suso_qx_apply_labels("trigger_final_value", "trigger_final_value", ///
            "qx_optmap", "trigger_final_label", "__dummy_label")
        quietly drop __dummy_label __tf
        quietly gen strL trigger_final_show = trigger_final_value + ///
            cond(trigger_final_label!="", " - " + trigger_final_label, "")

        tempvar __fn __tn __on
        quietly gen double `__fn' = real(trigger_final_value)
        quietly gen double `__tn' = real(trigval)
        quietly gen double `__on' = real(oldval)
        quietly gen byte trigger_final_matches_event = .
        quietly replace trigger_final_matches_event = ///
            cond(!missing(`__fn') & !missing(`__tn'), `__fn'==`__tn', ///
            trigger_final_value==trigval) if trigger_final_status==1
        quietly gen byte trigger_final_returns_old = .
        quietly replace trigger_final_returns_old = ///
            cond(!missing(`__fn') & !missing(`__on'), `__fn'==`__on', ///
            trigger_final_value==oldval) if trigger_final_status==1 & oldval!=""
        if `ismulti' {
            * Multi-select order is not semantically meaningful. Compare unique,
            * sorted code sets so "1,3" and "3,1" match.
            forvalues rr = 1/`=_N' {
                if trigger_final_status[`rr']!=1 continue
                local fset = subinstr(trigger_final_value[`rr'],","," ",.)
                local eset = subinstr(trigval[`rr'],","," ",.)
                local oset = subinstr(oldval[`rr'],","," ",.)
                foreach which in f e o {
                    local norm ""
                    foreach token of local `which'set {
                        local number = real("`token'")
                        if !missing(`number') local token = strtrim(string(`number',"%21.0g"))
                        local norm "`norm' `token'"
                    }
                    local `which'set = strtrim("`norm'")
                }
                local fset : list uniq fset
                local eset : list uniq eset
                local oset : list uniq oset
                local fset : list sort fset
                local eset : list sort eset
                local oset : list sort oset
                quietly replace trigger_final_matches_event = ("`fset'"=="`eset'") in `rr'
                if oldval[`rr']!="" quietly replace trigger_final_returns_old = ///
                    ("`fset'"=="`oset'") in `rr'
            }
        }

        quietly gen strL trigger_final_text = ""
        quietly replace trigger_final_text = trigger + ///
            " = " + trigger_final_show + ". It matches the historical event value." ///
            if trigger_final_status==1 & trigger_final_matches_event==1
        quietly replace trigger_final_text = trigger + ///
            " = " + trigger_final_show + ". The historical event was not final; " + ///
            "the export returned to the earlier value." ///
            if trigger_final_status==1 & trigger_final_matches_event==0 & ///
            trigger_final_returns_old==1
        quietly replace trigger_final_text = trigger + ///
            " = " + trigger_final_show + ". This differs from the historical event value " + ///
            trigval + "." if trigger_final_status==1 & ///
            trigger_final_matches_event==0 & trigger_final_returns_old!=1
        quietly replace trigger_final_text = trigger + ///
            " is blank." if trigger_final_status==2
        quietly replace trigger_final_text = ///
            "Final export row was not found for this interview." if trigger_final_status==5

        quietly append using `"`ACC'"'
        quietly save `"`ACC'"', replace
    }

    quietly use `"`ACC'"', clear
    quietly keep interview__id sk_run trigger_final_status trigger_final_value   ///
        trigger_final_label trigger_final_show trigger_final_matches_event       ///
        trigger_final_returns_old trigger_final_text
    quietly sort interview__id sk_run
    quietly by interview__id sk_run: keep if _n==1
    quietly isid interview__id sk_run
    quietly save `"`saving'"', replace
    quietly count if trigger_final_status==1 & trigger_final_matches_event==0
    return scalar ndifferent = r(N)
    quietly count if trigger_final_status==1 & trigger_final_returns_old==1
    return scalar nreturnedold = r(N)
end

* ---- standalone Skip page browser engine (split for Stata program-size cap) ---
program _suso_para_skip_page_js
    version 14.2
    args hf
    if "`hf'"=="" exit 198
    file write `hf' `"var SKP={"' _n
    file write `hf' `"norm:function(s){return String(s===null||s===undefined?'':s).trim().toLowerCase().replace(/[^a-z0-9]/g,'');},"' _n
    file write `hf' `"statusOK:function(x,s){if(!s)return true;if(s==='APP')return x.wc==='approvebysup'||x.wc==='approvebyhq';return x.ws===s||this.norm(x.wc)===this.norm(s)||this.norm(x.ws)===this.norm(s);},"' _n
    file write `hf' `"scope:function(a,k,s){var z=[];for(var i=0;i<a.length;i++)if((!k||a[i].ak===k)&&this.statusOK(a[i],s))z.push(a[i]);return z;},"' _n
    file write `hf' `"stats:function(a){var z={h:a.length,q:0,need:0,re:0,ev:0,ch:0,cev:0,out:0,tu:0,resolved:0};for(var i=0;i<a.length;i++){z.q+=a[i].q;z.need+=a[i].need;z.re+=a[i].re;z.ev+=a[i].ev;z.ch+=a[i].cp?1:0;z.cev+=a[i].cev;z.out+=a[i].out;z.tu+=a[i].tu?1:0;if(a[i].t==='C')z.resolved++;}return z;},"' _n
    file write `hf' `"actors:function(a){var m=Object.create(null),z=[],i,x;for(i=0;i<a.length;i++){x=a[i];if(!m[x.ak])m[x.ak]={k:x.ak,n:x.an,c:0};m[x.ak].c++;}for(var k in m)if(Object.prototype.hasOwnProperty.call(m,k))z.push(m[k]);z.sort(function(x,y){return x.n.localeCompare(y.n)||x.k.localeCompare(y.k);});return z;},"' _n
    file write `hf' `"statuses:function(a){var m=Object.create(null),z=[],i,x;for(i=0;i<a.length;i++){x=a[i];if(!x.ws)continue;if(!m[x.ws])m[x.ws]={k:x.ws,c:0};m[x.ws].c++;}for(var k in m)if(Object.prototype.hasOwnProperty.call(m,k))z.push(m[k]);z.sort(function(x,y){return x.k.localeCompare(y.k);});return z;},"' _n
    file write `hf' `"patterns:function(a){var m=Object.create(null),z=[],i,x,p;for(i=0;i<a.length;i++){x=a[i];p=m[x.gk];if(!p)p=m[x.gk]={k:x.gk,l:x.gl,h:0,ch:0,ev:0,cev:0,out:0,ids:Object.create(null)};p.h++;p.ch+=x.cp?1:0;p.ev+=x.ev;p.cev+=x.cev;p.out+=x.out;p.ids[x.id]=1;}for(var k in m)if(Object.prototype.hasOwnProperty.call(m,k)){p=m[k];p.ni=Object.keys(p.ids).length;delete p.ids;z.push(p);}z.sort(function(x,y){return y.ev-x.ev||y.h-x.h||x.l.localeCompare(y.l);});return z;},"' _n
    file write `hf' `"groups:function(a){var m=Object.create(null),z=[],i,x,g;for(i=0;i<a.length;i++){x=a[i];if(x.t==='C')continue;g=m[x.gk];if(!g)g=m[x.gk]={k:x.gk,l:x.gl,need:0,ids:Object.create(null),cases:[]};g.need+=x.need;g.ids[x.id]=1;g.cases.push(x);}for(var k in m)if(Object.prototype.hasOwnProperty.call(m,k)){g=m[k];g.ni=Object.keys(g.ids).length;delete g.ids;g.cases.sort(function(x,y){var sx=x.t==='A'?2:1,sy=y.t==='A'?2:1;return sy-sx||y.need-x.need||y.q-x.q||x.id.localeCompare(y.id);});z.push(g);}z.sort(function(x,y){return y.need-x.need||x.l.localeCompare(y.l);});return z;}"' _n
    file write `hf' `"};if(typeof module!=='undefined'&&module.exports)module.exports=SKP;"' _n
    file write `hf' `"function E(s){return String(s===null||s===undefined?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');}"' _n
    file write `hf' `"function el(x){return document.getElementById(x);}"' _n
    file write `hf' `"function initActors(){var a=SKP.actors(SK.cases),s=el('sk_actor'),o=document.createElement('option');s.innerHTML='';o.value='';o.textContent='All removal-run actors ('+a.length+')';s.appendChild(o);for(var i=0;i<a.length;i++){o=document.createElement('option');o.value=a[i].k;o.textContent=a[i].n+' ('+a[i].c+')';s.appendChild(o);}}"' _n
    file write `hf' `"function initStatuses(){var a=SKP.statuses(SK.cases),s=el('sk_status'),o=document.createElement('option'),has=false,i;for(i=0;i<SK.cases.length;i++)if(SK.cases[i].wc==='approvebysup'||SK.cases[i].wc==='approvebyhq'){has=true;break;}s.innerHTML='';o.value='';o.textContent='All statuses';s.appendChild(o);for(i=0;i<a.length;i++){o=document.createElement('option');o.value=a[i].k;o.textContent=a[i].k+' ('+a[i].c+')';s.appendChild(o);}if(has){o=document.createElement('option');o.value='APP';o.textContent='Approved only (Sup + HQ)';s.insertBefore(o,s.options[1]||null);}}"' _n
    file write `hf' `"function actorLabel(k){var o=el('sk_actor').options;for(var i=0;i<o.length;i++)if(o[i].value===k)return o[i].text.replace(/ \([0-9]+\)$/,'');return k;}"' _n
    file write `hf' `"function renderSkip(){var k=el('sk_actor').value,w=el('sk_status').value,a=SKP.scope(SK.cases,k,w),st=SKP.stats(a),p=SKP.patterns(a),g=SKP.groups(a),i,s='',sb=[];el('sk_hist').textContent=st.h.toLocaleString();el('sk_q').textContent=st.q.toLocaleString();el('sk_need').textContent=st.need.toLocaleString();el('sk_re').textContent=st.re.toLocaleString();el('sk_ev').textContent=st.ev.toLocaleString();el('sk_compact').textContent=(st.ch+' / '+st.cev);el('sk_outside').textContent=st.out.toLocaleString();if(k)sb.push(actorLabel(k));if(w)sb.push(w==='APP'?'Approved only (Sup + HQ)':w);el('sk_scope').textContent='Showing '+st.h.toLocaleString()+' exhaustive removal histories'+(sb.length?' for '+sb.join(' / '):' in the current vars()/role scope')+'. Loaded totals: '+SK.meta.role.toLocaleString()+' role-scoped and '+SK.meta.allRole.toLocaleString()+' all-role raw events.';for(i=0;i<p.length;i++)s+='<tr><td>'+E(p[i].l)+'</td><td class=\"r\">'+p[i].h.toLocaleString()+'</td><td class=\"r\">'+p[i].ch.toLocaleString()+'</td><td class=\"r\">'+p[i].ni.toLocaleString()+'</td><td class=\"r\">'+p[i].ev.toLocaleString()+'</td><td class=\"r\">'+p[i].out.toLocaleString()+'</td></tr>';el('sk_patterns').innerHTML=s;el('sk_patterns_empty').textContent=p.length?'':'No removal histories for this selection.';s='';for(i=0;i<g.length;i++)s+='<details open><summary class=\"gate\"><b>'+E(g[i].l)+'</b> &nbsp;-&nbsp; '+g[i].cases.length+' case(s), '+g[i].need+' question-history unit(s) to check, in '+g[i].ni+' interview(s)</summary>'+g[i].cases.map(function(x){return x.card;}).join('')+'</details>';if(!g.length)s='<div class=\"state resolved\"><b>No final-data checks are indicated for this selection.</b> Every matching identifiable item is answered or correctly blank under final questionnaire logic.</div>';el('sk_verify').innerHTML=s;var r=[];for(i=0;i<a.length;i++)if(a[i].t==='C')r.push(a[i]);el('sk_resolved_summary').textContent='Show '+r.length+' resolved historical case(s)';el('sk_resolved').innerHTML=r.map(function(x){return x.card;}).join('');el('sk_resolved_more').textContent=r.length?'':'No resolved histories for this selection.';var hA=false;for(i=0;i<a.length;i++)if(a[i].t==='A'){hA=true;break;}if(parent!==window)parent.postMessage({type:'suso-tab-badge',n:st.need,sev:(hA?'b':(st.need>0?'w':'g'))},'*');updateSkipSections(st,a,p,hA);}"' _n
    file write `hf' `"function setActor(k,label,notify){var s=el('sk_actor'),found=false;for(var i=0;i<s.options.length;i++)if(s.options[i].value===k){found=true;break;}if(k&&!found){var o=document.createElement('option');o.value=k;o.textContent=(label||k)+' (0)';s.appendChild(o);}s.value=k||'';renderSkip();if(notify&&parent!==window)parent.postMessage({type:'suso-actor-filter',key:s.value,label:s.value?actorLabel(s.value):''},'*');}"' _n
    file write `hf' `"function setStatus(k,notify){var s=el('sk_status'),found=!k,o;for(var i=0;k&&i<s.options.length;i++)if(s.options[i].value===k){found=true;break;}if(k&&!found){o=document.createElement('option');o.value=k;o.textContent=(k==='APP'?'Approved only (Sup + HQ)':k)+' (0)';s.appendChild(o);}s.value=k||'';renderSkip();if(notify&&parent!==window)parent.postMessage({type:'suso-status-filter',key:s.value},'*');}"' _n
    file write `hf' `"/* triage sections: live severity, pills, findings (Skips & removals) */"' _n
    file write `hf' `"var secState=Object.create(null), secDefaultsDone=false;"' _n
    file write `hf' `"function secApply(id){"' _n
    file write `hf' `"  var s=el(id); if(!s) return;"' _n
    file write `hf' `"  var st=secState[id]||(secState[id]={open:false,sev:''});"' _n
    file write `hf' `"  s.className='sblock'+(st.sev?(' sv-'+st.sev):'')+(st.open?' open':'');"' _n
    file write `hf' `"  var b=s.querySelector('.shead');"' _n
    file write `hf' `"  if(b) b.setAttribute('aria-expanded',st.open?'true':'false');"' _n
    file write `hf' `"}"' _n
    file write `hf' `"function secOpen(id,open){ var st=secState[id]||(secState[id]={open:false,sev:''}); st.open=!!open; secApply(id); }"' _n
    file write `hf' `"function secToggle(id){ var st=secState[id]||(secState[id]={open:false,sev:''}); st.open=!st.open; secApply(id); }"' _n
    file write `hf' `"function secSev(id,sev){ var st=secState[id]||(secState[id]={open:false,sev:''}); st.sev=sev||''; secApply(id); }"' _n
    file write `hf' `"function setPill(pid,cid,n,sev){"' _n
    file write `hf' `"  var txt=(n>0)?n.toLocaleString():'\u2713', cls=(n>0)?sev:'g';"' _n
    file write `hf' `"  var p=el(pid); if(p){ p.textContent=txt; p.className='pillc '+cls; p.style.display=''; }"' _n
    file write `hf' `"  var c=el(cid); if(c){ c.textContent=txt; c.className='n '+cls; c.style.display=''; }"' _n
    file write `hf' `"}"' _n
    file write `hf' `"function setFind(fid,txt){ var f=el(fid); if(f) f.textContent=txt; }"' _n
    file write `hf' `"function plural(n,s,p){ return n===1?s:(p||(s+'s')); }"' _n
    file write `hf' `"function initSkipSections(){"' _n
    file write `hf' `"  var i, hs=document.querySelectorAll('.sblock .shead');"' _n
    file write `hf' `"  for(i=0;i<hs.length;i++)(function(b){ b.addEventListener('click',function(){ var s=b.parentNode; if(s&&s.id) secToggle(s.id); }); })(hs[i]);"' _n
    file write `hf' `"  var cs=document.querySelectorAll('.chipx');"' _n
    file write `hf' `"  for(i=0;i<cs.length;i++)(function(a){ a.addEventListener('click',function(ev){"' _n
    file write `hf' `"    if(ev&&ev.preventDefault) ev.preventDefault();"' _n
    file write `hf' `"    var id=a.getAttribute('data-sec'); if(!id) return;"' _n
    file write `hf' `"    secOpen(id,true);"' _n
    file write `hf' `"    var s=el(id); if(s&&s.scrollIntoView) s.scrollIntoView({behavior:'smooth',block:'start'});"' _n
    file write `hf' `"  }); })(cs[i]);"' _n
    file write `hf' `"  var ea=el('sk_expall'), ec=el('sk_collall'), all=document.querySelectorAll('.sblock'), j;"' _n
    file write `hf' `"  if(ea) ea.addEventListener('click',function(){ for(j=0;j<all.length;j++) if(all[j].id) secOpen(all[j].id,true); });"' _n
    file write `hf' `"  if(ec) ec.addEventListener('click',function(){ for(j=0;j<all.length;j++) if(all[j].id) secOpen(all[j].id,false); });"' _n
    file write `hf' `"}"' _n
    file write `hf' `"function updateSkipSections(st,a,p,hasA){"' _n
    file write `hf' `"  var i, cases=st.h-st.resolved, ids=Object.create(null), niv=0;"' _n
    file write `hf' `"  for(i=0;i<a.length;i++) if(a[i].t!=='C'&&!ids[a[i].id]){ ids[a[i].id]=1; niv++; }"' _n
    file write `hf' `"  secSev('s_ver', hasA?'b':(st.need>0?'w':'g'));"' _n
    file write `hf' `"  setPill('p_ver','cb_ver',st.need,(hasA?'b':'w'));"' _n
    file write `hf' `"  setFind('f_ver', cases>0"' _n
    file write `hf' `"    ? (cases.toLocaleString()+' '+plural(cases,'case')+' - '+st.need.toLocaleString()+' question-history '+plural(st.need,'unit')+' to check - '+niv.toLocaleString()+' '+plural(niv,'interview'))"' _n
    file write `hf' `"    : 'No final-data checks are indicated for this selection');"' _n
    file write `hf' `"  secSev('s_pat','');"' _n
    file write `hf' `"  setFind('f_pat', st.h>0"' _n
    file write `hf' `"    ? (p.length.toLocaleString()+' pattern '+plural(p.length,'group')+' across '+st.h.toLocaleString()+' '+plural(st.h,'history','histories'))"' _n
    file write `hf' `"    : 'No removal histories for this selection');"' _n
    file write `hf' `"  secSev('s_res','g');"' _n
    file write `hf' `"  setPill('p_res','cb_res',st.resolved,'g');"' _n
    file write `hf' `"  setFind('f_res', st.resolved.toLocaleString()+' resolved historical '+plural(st.resolved,'case'));"' _n
    file write `hf' `"  if(!secDefaultsDone){ secDefaultsDone=true; secOpen('s_ver',true); }"' _n
    file write `hf' `"}"' _n
    file write `hf' `"initActors();initStatuses();initSkipSections();renderSkip();el('sk_actor').addEventListener('change',function(){setActor(this.value,actorLabel(this.value),true);});el('sk_status').addEventListener('change',function(){setStatus(this.value,true);});window.addEventListener('message',function(ev){var d=ev.data||{};if(ev.source!==parent)return;if(d.type==='suso-actor-filter'&&typeof d.key==='string'&&typeof d.label==='string'&&d.key.length<=500&&d.label.length<=500)setActor(d.key,d.label,false);if(d.type==='suso-status-filter'&&typeof d.key==='string'&&d.key.length<=500)setStatus(d.key,false);});"' _n
end

* ---- skips: historical answer-removal runs and nearby/linked answers --------
* A "cascade" is a compact run of >= cascade() consecutive AnswerRemoved events
* near an AnswerSet. It is a screening signal, not proof of causation or proof
* that the affected questions remain blank in the final interview.
program _suso_para_skips, rclass
    version 14.2
    syntax [, CASCade(integer 3) WINdow(real 60) TOP(integer 15) SAVing(string) replace ///
        QX(string) DATA(string) MESSages(string) HTML(string) DETail(string) VARS(string) ///
        HQURL(string) FULL ALLRoles PREComputed(string) STATUSMap(string) ]
    _suso_para_need events
    if `"`precomputed'"'=="" quietly _suso_para_derive , gapmins(30) fastsecs(2) `allroles'
    else {
        foreach v in para_ivw para_fieldans para_fieldrem para_actor           ///
            para_actor_key para_primary para_lasteditor para_tsu para_ord para_seq {
            capture confirm variable `v', exact
            if _rc {
                di as err "suso paradata skips: internal precomputed event cache is incomplete (`v' missing)."
                exit 459
            }
        }
        local __ds : char _dta[suso_para_derived_schema]
        local __dt : char _dta[suso_para_derived_token]
        local __dn : char _dta[suso_para_derived_n]
        local __dg : char _dta[suso_para_derived_gapmins]
        local __df : char _dta[suso_para_derived_fastsecs]
        local __da : char _dta[suso_para_derived_allroles]
        local __wantall = cond("`allroles'"!="","1","0")
        if "`__ds'"!="1716" | `"`__dt'"'!=`"`precomputed'"' |            ///
            real("`__dn'")!=_N | real("`__dg'")!=30 | real("`__df'")!=2 | ///
            "`__da'"!="`__wantall'" {
            di as err "suso paradata skips: internal precomputed event cache uses different derivation settings."
            exit 459
        }
    }
    if `"`qx'"'!=""   local qx   = subinstr(`"`qx'"',   "\", "/", .)
    if `"`data'"'!="" local data = subinstr(`"`data'"', "\", "/", .)
    if `"`data'"'!="" {
        capture confirm file `"`data'"'
        if _rc {
            di as err `"suso paradata skips: final data file not found: `data'"'
            exit 601
        }
    }
    _suso_para_hqbase , hqurl(`"`hqurl'"')
    local hqbase `"`r(url)'"'
    _suso_para_hesc `"`hqbase'"'
    local hqbaseh `"`r(out)'"'
    tempfile SKHQ
    local hasassignment 0
    if `"`data'"'!="" {
        quietly _suso_para_hqmap using `"`data'"', saving(`"`SKHQ'"')
        local hasassignment = r(hasassignment)
    }
    if `cascade'<1 {
        di as err "suso paradata skips: cascade() is the minimum run of AnswerRemoved events; use 1 or more."
        exit 198
    }
    if `window'<=0 {
        di as err "suso paradata skips: window() must be positive (seconds)."
        exit 198
    }

    * Parse questionnaire metadata. qx_enable is the EFFECTIVE condition:
    * section + subsection/group + item-level conditions. Keeping the components
    * separately lets final-data adjudication apply three-valued logic correctly:
    * a false parent condition disables a question even when a child referent is blank.
    local hasqx 0
    tempfile QXT QXMETA
    if `"`qx'"'!="" {
        preserve
        _suso_para_qxload , file(`"`qx'"')
        quietly keep qx_var qx_type qx_text qx_section qx_subsection qx_enable  ///
            qx_enable_deps qx_section_enable qx_group_enable qx_item_enable       ///
            qx_calc qx_optmap qx_section_tri qx_group_tri qx_item_tri
        quietly bysort qx_var: keep if _n==1
        quietly save `"`QXMETA'"'
        local nqx = _N
        forvalues j = 1/`nqx' {
            local qxname_`j' `"`=qx_var[`j']'"'
            local qxen_`j' = substr(qx_enable[`j'], 1, 1600)
            local qxdeps_`j' = substr(qx_enable_deps[`j'], 1, 4000)
            local qxsec_`j' = substr(qx_section[`j'], 1, 80)
        }
        quietly rename qx_var trigger
        quietly save `"`QXT'"'
        restore
        local hasqx 1
    }

    local hasvar 0
    capture confirm variable para_var
    if !_rc local hasvar 1
    if !`hasvar' di as txt "suso paradata skips: note — no parameters column (reduced export?); cascades are detected but trigger variables cannot be named."

    * Backfill question-instance fields when events were prepared by an older
    * build. Exact roster-aware transitions require para_qkey/para_roster.
    if `hasvar' {
        capture confirm variable para_val
        if _rc quietly gen strL para_val = ""
        capture confirm variable para_roster
        if _rc quietly gen str160 para_roster = ""
        capture confirm variable para_qkey
        if _rc {
            quietly gen str244 para_qkey = substr(para_var +               ///
                cond(para_roster!="", "||" + para_roster, ""),1,244)      ///
                if para_var!=""
            di as txt "  note: this prepared event table predates roster-aware keys; non-roster transitions remain exact, roster transitions should be rebuilt with {bf:suso paradata load}."
        }
        capture confirm variable para_qdisp
        if _rc quietly gen str244 para_qdisp = substr(para_var +           ///
            cond(para_roster!="", " [roster " + para_roster + "]", ""),  ///
            1,244) if para_var!=""
        * Some reduced/older prepared tables have a usable variable/roster
        * address but a blank qkey.  Normalize those rows before state history
        * and run-level distinct-item accounting; otherwise a real removal is
        * silently dropped from every final-state bucket.
        quietly replace para_qkey = substr(para_var + cond(para_roster!="",  ///
            "||" + para_roster, ""), 1, 244) if para_var!="" &              ///
            (para_qkey=="" | (para_roster!="" & para_qkey==para_var))
        quietly replace para_qdisp = substr(para_var + cond(para_roster!="", ///
            " [roster " + para_roster + "]", ""), 1, 244) if para_var!="" & ///
            (para_qdisp=="" | (para_roster!="" & para_qdisp==para_var))
    }
    else {
        * Reduced paradata may contain no Parameters payload at all.  Keep the
        * event-only cascade detector operational with explicitly unknown
        * question metadata; do not let later carry-forward code reference
        * variables that do not exist.
        capture confirm variable para_val, exact
        if _rc quietly gen strL para_val = ""
        capture confirm variable para_roster, exact
        if _rc quietly gen str160 para_roster = ""
        capture confirm variable para_qkey, exact
        if _rc quietly gen str244 para_qkey = ""
        capture confirm variable para_qdisp, exact
        if _rc quietly gen str244 para_qdisp = ""
    }

    capture drop sk_*
    quietly gen byte sk_isrem = para_fieldrem

    * Keep the complete all-role raw count next to the role-scoped inventory.
    * By default para_fieldrem is interviewer-role fieldwork; allroles makes it
    * coincide with the eligible all-role stream.  The two totals are reported
    * explicitly so "all removals" is never ambiguous.
    quietly count if para_rem
    local nraw_allroles_global = r(N)
    quietly count if sk_isrem
    local nraw_role_global = r(N)

    * One canonical current/final workflow status per interview.  This is the
    * same map used by Behaviour and Question timing: data() wins when it has
    * interview__status; otherwise the last workflow event is used.
    tempfile SKSTATUS
    local skstatusfile `"`statusmap'"'
    if `"`skstatusfile'"'!="" {
        capture confirm file `"`skstatusfile'"'
        if _rc {
            di as err "suso paradata skips: internal status map was not found."
            exit 601
        }
    }
    else {
        local __statusdata ""
        if `"`data'"'!="" local __statusdata `"data(`"`data'"')"'
        quietly _suso_para_statusmap , saving(`"`SKSTATUS'"') `__statusdata' replace
        local skstatusfile `"`SKSTATUS'"'
    }

    * vars() is an output filter only. Cascade construction must always use the
    * untouched event stream; otherwise dropping intervening events changes
    * adjacency and can manufacture a removal run that never occurred.
    quietly gen byte sk_vsel = 1
    if `"`vars'"'!="" & `hasvar' {
        quietly replace sk_vsel = 0
        foreach p of local vars {
            quietly replace sk_vsel = 1 if (para_fieldans | para_fieldrem) & strmatch(para_var, "`p'")
        }
    }
    else if `"`vars'"'!="" & !`hasvar' {
        di as txt "  vars(): ignored because this reduced paradata has no question-variable names."
    }

    * Final state is computed per exact question instance (variable + roster
    * address). Keep the full state history as well so the candidate AnswerSet can
    * be described as changed, repeated, first observed, or re-entered.
    tempfile FSTATE HSTATE
    local hasfstate 0
    local hashstate 0
    if `hasvar' {
        preserve
        quietly keep if (para_ans | para_rem) & para_qkey!=""
        if _N>0 {
            quietly gen str16 hist_event = cond(para_ans,"answerset","answerremoved")
            quietly gen strL hist_val = cond(para_ans,para_val,"")
            quietly gen str244 trigger_qkey = para_qkey
            quietly gen double hist_ord = para_ord
            quietly gen double hist_seq = para_seq
            quietly gen double hist_tsu = para_tsu
            quietly keep interview__id trigger_qkey hist_event hist_val ///
                hist_ord hist_seq hist_tsu
            quietly save `"`HSTATE'"'
            local hashstate 1
        }
        restore

        preserve
        quietly keep if (para_ans | para_rem) & para_qkey!=""
        if _N>0 {
            sort interview__id para_qkey para_ord para_seq
            quietly by interview__id para_qkey: keep if _n==_N
            quietly gen byte sk_finalans = para_ans
            quietly keep interview__id para_qkey sk_finalans
            quietly save `"`FSTATE'"'
            local hasfstate 1
        }
        restore
    }

    * Interview ownership is the deterministic primary first-pass actor.  Keep the
    * actual removal-run actor separately in sk_actor; a late correction must never
    * relabel the whole interview or its behaviour history.
    quietly gen str244 sk_resp = para_primary
    quietly replace sk_resp = para_lasteditor if sk_resp=="" & para_lasteditor!=""

    * Carry the exact preceding and following AnswerSet through the stream.
    * Along with the variable and value, retain roster address, instance key,
    * event order, file-row tiebreaker, and timestamp.
    if `hasvar' quietly gen str80 sk_lastvar = para_var if para_fieldans
    else        quietly gen str80 sk_lastvar = "(unnamed)" if para_fieldans
    quietly gen strL   sk_lastval    = para_val if para_fieldans
    quietly gen str160 sk_lastroster = para_roster if para_fieldans
    quietly gen str244 sk_lastqkey   = para_qkey if para_fieldans
    quietly gen double sk_lastts     = para_tsu if para_fieldans
    quietly gen double sk_lastord    = para_ord if para_fieldans
    quietly gen double sk_lastseq    = para_seq if para_fieldans

    * A removal history belongs to the actor who emitted its AnswerRemoved run.
    * Retain the normalized key as well as the display name: primary interviewer
    * and last editor are interview context, never substitutes for run ownership.
    quietly gen str244 sk_actor = para_actor
    quietly gen str244 sk_actor_key = para_actor_key

    quietly gen str80  sk_nextvar    = sk_lastvar
    quietly gen strL   sk_nextval    = sk_lastval
    quietly gen str160 sk_nextroster = sk_lastroster
    quietly gen str244 sk_nextqkey   = sk_lastqkey
    quietly gen double sk_nextts     = sk_lastts
    quietly gen double sk_nextord    = sk_lastord
    quietly gen double sk_nextseq    = sk_lastseq

    * Shrink the wide working strings before the full-stream carry-forward
    * sorts.  This is lossless and materially reduces sort/temp I/O on large
    * paradata exports.
    capture quietly compress sk_resp sk_lastvar sk_lastroster sk_lastqkey      ///
        sk_actor sk_actor_key sk_nextvar sk_nextroster sk_nextqkey

    quietly bysort interview__id (para_ord para_seq): ///
        replace sk_lastvar = sk_lastvar[_n-1] if missing(sk_lastseq) & _n>1
    quietly by interview__id: replace sk_lastval = sk_lastval[_n-1] if missing(sk_lastseq) & _n>1
    quietly by interview__id: replace sk_lastroster = sk_lastroster[_n-1] if missing(sk_lastseq) & _n>1
    quietly by interview__id: replace sk_lastqkey = sk_lastqkey[_n-1] if missing(sk_lastseq) & _n>1
    quietly by interview__id: replace sk_lastts = sk_lastts[_n-1] if missing(sk_lastseq) & _n>1
    quietly by interview__id: replace sk_lastord = sk_lastord[_n-1] if missing(sk_lastseq) & _n>1
    quietly by interview__id: replace sk_lastseq = sk_lastseq[_n-1] if missing(sk_lastseq) & _n>1

    * SuSo may record a removal run before the AnswerSet that triggered it, so
    * carry the next AnswerSet backward as an equally explicit candidate.
    gsort interview__id -para_ord -para_seq
    quietly by interview__id: replace sk_nextvar = sk_nextvar[_n-1] if missing(sk_nextseq) & _n>1
    quietly by interview__id: replace sk_nextval = sk_nextval[_n-1] if missing(sk_nextseq) & _n>1
    quietly by interview__id: replace sk_nextroster = sk_nextroster[_n-1] if missing(sk_nextseq) & _n>1
    quietly by interview__id: replace sk_nextqkey = sk_nextqkey[_n-1] if missing(sk_nextseq) & _n>1
    quietly by interview__id: replace sk_nextts = sk_nextts[_n-1] if missing(sk_nextseq) & _n>1
    quietly by interview__id: replace sk_nextord = sk_nextord[_n-1] if missing(sk_nextseq) & _n>1
    quietly by interview__id: replace sk_nextseq = sk_nextseq[_n-1] if missing(sk_nextseq) & _n>1
    sort interview__id para_ord para_seq

    * Interview keys for the review page.
    tempfile SKKEY
    local haskey 0
    preserve
    quietly keep if para_ev=="keyassigned"
    capture confirm string variable parameters
    if !_rc & _N>0 {
        local haskey 1
        quietly bysort interview__id (para_ord para_seq): keep if _n==_N
        quietly gen ikey = substr(strtrim(parameters), 1, 12)
        quietly keep interview__id ikey
        quietly save `"`SKKEY'"'
    }
    restore

    * Runs are constructed on the FULL event stream.  Every maximal consecutive
    * same-actor AnswerRemoved run is an inventory history.  cascade()/window()
    * classify a compact-priority subset; they never delete a raw removal from
    * the inventory.  AnswerSet context is reconstructed for every history,
    * independently of whether that history meets the compact threshold.
    sort interview__id para_ord para_seq
    tempvar rise rmin rmax rspan rtimed dtprev dtnext prevnear nextnear
    quietly by interview__id: gen byte `rise' = sk_isrem & ///
        (sk_isrem[_n-1]!=1 | para_actor_key!=para_actor_key[_n-1])
    quietly by interview__id: gen double sk_run = sum(`rise')
    quietly bysort interview__id sk_run sk_isrem (para_ord para_seq): ///
        gen long sk_len = _N if sk_isrem
    quietly by interview__id sk_run sk_isrem: gen byte sk_first = (_n==1) & sk_isrem
    quietly egen double `rmin' = min(cond(sk_isrem, para_tsu, .)), by(interview__id sk_run)
    quietly egen double `rmax' = max(cond(sk_isrem, para_tsu, .)), by(interview__id sk_run)
    quietly egen long `rtimed' = total(cond(sk_isrem & !missing(para_tsu),1,0)), ///
        by(interview__id sk_run)
    quietly gen double `rspan' = `rmax' - `rmin'
    quietly gen double `dtprev' = para_tsu - sk_lastts if sk_first
    quietly gen double `dtnext' = sk_nextts - `rmax' if sk_first
    quietly gen byte sk_history1 = sk_first
    quietly gen byte sk_history = sk_isrem
    quietly gen byte sk_prevcontext = 0
    quietly gen byte sk_nextcontext = 0
    quietly gen byte `prevnear' = sk_first & `rtimed'==sk_len & !missing(sk_len) ///
        & inrange(`dtprev', 0, `window'*1000) & `rspan'<=`window'*1000 & sk_lastvar!=""
    quietly gen byte `nextnear' = sk_first & `rtimed'==sk_len & !missing(sk_len) ///
        & inrange(`dtnext', 0, `window'*1000) & `rspan'<=`window'*1000 & sk_nextvar!=""
    quietly gen byte sk_prevnear = `prevnear'
    quietly gen byte sk_nextnear = `nextnear'
    quietly replace sk_prevcontext = sk_prevnear
    quietly replace sk_nextcontext = sk_nextnear
    quietly gen byte sk_useprev = sk_prevcontext & (!sk_nextcontext |        ///
        missing(`dtnext') | (!missing(`dtprev') & `dtprev'<=`dtnext'))
    quietly replace sk_useprev = 1 if sk_prevcontext & sk_nextcontext &      ///
        missing(`dtprev') & missing(`dtnext')
    quietly gen byte sk_casc1 = sk_first & sk_len>=`cascade' &              ///
        (sk_prevnear | sk_nextnear)
    quietly gen byte sk_timing_unknown1 = sk_first & !sk_casc1 &           ///
        (`rtimed'<sk_len |                                                  ///
        (sk_lastvar!="" & missing(sk_lastts)) |                            ///
        (sk_nextvar!="" & missing(sk_nextts)))
    tempvar runiscasc
    quietly egen byte `runiscasc' = max(sk_casc1), by(interview__id sk_run)
    quietly gen byte sk_casc = sk_isrem & `runiscasc'
    quietly gen byte sk_timing_unknown = sk_isrem & sk_timing_unknown1
    quietly bysort interview__id sk_run (para_ord para_seq):                 ///
        replace sk_timing_unknown = sk_timing_unknown[_n-1] if _n>1 & sk_isrem
    quietly gen str80 sk_trig = cond(sk_useprev, sk_lastvar, sk_nextvar) if sk_first
    quietly gen strL sk_trigval = cond(sk_useprev, sk_lastval, sk_nextval) if sk_first
    quietly gen str160 sk_trigroster = cond(sk_useprev, sk_lastroster, sk_nextroster) if sk_first
    quietly gen str244 sk_trigqkey = cond(sk_useprev, sk_lastqkey, sk_nextqkey) if sk_first
    quietly gen double sk_trigts = cond(sk_useprev, sk_lastts, sk_nextts) if sk_first
    quietly gen double sk_trigord = cond(sk_useprev, sk_lastord, sk_nextord) if sk_first
    quietly gen double sk_trigseq = cond(sk_useprev, sk_lastseq, sk_nextseq) if sk_first
    foreach sv in sk_trig sk_trigval sk_trigroster sk_trigqkey {
        quietly bysort interview__id sk_run (para_ord para_seq): ///
            replace `sv' = `sv'[_n-1] if `sv'=="" & _n>1
    }
    foreach nv in sk_useprev sk_trigts sk_trigord sk_trigseq {
        quietly bysort interview__id sk_run (para_ord para_seq): ///
            replace `nv' = `nv'[_n-1] if missing(`nv') & _n>1
    }
    * Apply vars() only AFTER every inventory history and its compact flag exist.
    * Keep a focused history when either its context AnswerSet or at least one
    * affected removal matches.  Global construction/counts remain untouched.
    quietly gen byte sk_focus1 = sk_first
    if `"`vars'"'!="" & `hasvar' {
        tempvar remsel runsel trigsel runtrigsel
        quietly gen byte `remsel' = sk_vsel & sk_isrem
        quietly egen byte `runsel' = max(`remsel'), by(interview__id sk_run)
        quietly gen byte `trigsel' = 0
        foreach p of local vars {
            quietly replace `trigsel' = 1 if sk_first & ///
                ((sk_prevcontext & strmatch(sk_lastvar, "`p'")) | ///
                 (sk_nextcontext & strmatch(sk_nextvar, "`p'")))
        }
        quietly egen byte `runtrigsel' = max(`trigsel'), by(interview__id sk_run)
        quietly replace sk_focus1 = sk_first & (`runsel'==1 | `runtrigsel'==1)
    }
    tempvar runfocus
    quietly egen byte `runfocus' = max(sk_focus1), by(interview__id sk_run)
    quietly gen byte sk_viewhistory1 = sk_first & `runfocus'
    quietly gen byte sk_viewrem = sk_isrem & `runfocus'
    quietly gen byte sk_viewcasc1 = sk_casc1 & `runfocus'
    quietly gen byte sk_viewcasc = sk_casc & `runfocus'
    quietly gen byte sk_viewtimingunknown1 = sk_timing_unknown1 & `runfocus'
    quietly gen byte sk_viewtimingunknown = sk_timing_unknown & `runfocus'

    quietly count if sk_history1
    local nhist_global = r(N)
    quietly count if sk_casc1
    local ncasc_global = r(N)
    quietly count if sk_casc
    local ncompactevents_global = r(N)
    quietly count if sk_timing_unknown1
    local ntimingunknown_global = r(N)
    quietly count if sk_timing_unknown
    local ntimingunknownevents_global = r(N)

    * Determine the final state of each distinct question INSTANCE affected by
    * each run. Roster rows with the same variable name remain separate.
    if `hasfstate' {
        quietly merge m:1 interview__id para_qkey using `"`FSTATE'"', ///
            keep(master match) nogenerate
    }
    else quietly gen byte sk_finalans = .
    tempvar namedtag blanktag
    quietly egen byte `namedtag' = tag(interview__id sk_run para_qkey) ///
        if sk_viewrem & para_qkey!=""
    quietly replace `namedtag' = 0 if missing(`namedtag')
    * A history may mix named questions with removal rows whose identity payload
    * is blank.  Retain exactly one explicit identity-unavailable unit per such
    * history.  It is a separate final-check category and is never passed to the
    * final-data matcher as though an empty variable name were real.
    quietly egen byte `blanktag' = tag(interview__id sk_run) ///
        if sk_viewrem & para_qkey==""
    quietly replace `blanktag' = 0 if missing(`blanktag')
    quietly gen byte sk_hist_namedtag = `namedtag'
    quietly gen byte sk_identityunknown = `blanktag'
    quietly gen byte sk_hist_qtag = sk_hist_namedtag | sk_identityunknown
    quietly gen byte sk_qtag = sk_hist_qtag & sk_casc

    * Existing casc_* fields remain the compact-priority layer used by Behaviour
    * risk logic.  Parallel hist_* fields adjudicate the exhaustive inventory.
    quietly gen byte sk_reanswered = sk_qtag & sk_finalans==1
    quietly gen byte sk_open       = sk_qtag & sk_finalans==0
    quietly gen byte sk_unknown    = sk_qtag & missing(sk_finalans)
    quietly gen byte sk_hist_reanswered = sk_hist_qtag & sk_finalans==1
    quietly gen byte sk_hist_open       = sk_hist_qtag & sk_finalans==0
    quietly gen byte sk_hist_unknown    = sk_hist_qtag & missing(sk_finalans)

    * One row per affected question instance. This is later compared with the
    * supplied final export and the effective questionnaire logic.
    tempfile CASEV FINALV FINALCASE FINALINT
    local hascasev 0
    if `hasvar' {
        preserve
        quietly keep if sk_hist_namedtag
        if _N>0 {
            quietly keep interview__id sk_run para_var para_roster para_qkey ///
                para_qdisp sk_casc
            quietly rename (para_var para_roster para_qkey para_qdisp sk_casc) ///
                (affected_var affected_roster affected_qkey affected_qdisp compact)
            quietly save `"`CASEV'"'
            local hascasev 1
        }
        restore
    }

    quietly count if sk_viewhistory1
    local nhist = r(N)
    quietly count if sk_viewrem
    local nremevents = r(N)
    quietly count if sk_viewcasc1
    local ncasc = r(N)
    quietly count if sk_viewcasc
    local nwiped = r(N)                 // backward-compatible: removal-event count
    local noutsideevents = `nremevents' - `nwiped'
    quietly count if sk_viewtimingunknown1
    local ntimingunknown = r(N)
    quietly count if sk_viewtimingunknown
    local ntimingunknownevents = r(N)
    quietly count if sk_hist_qtag
    local naffectedqall = r(N)          // distinct question-within-run cases
    quietly count if sk_hist_reanswered
    local nreansweredall = r(N)
    quietly count if sk_hist_open
    local nopenall = r(N)
    quietly count if sk_hist_unknown
    local nunknownall = r(N)
    quietly count if sk_identityunknown
    local nidentityunknownall = r(N)

    * ---- cascade-level detail: exact candidate transition + affected states ----
    local hasdet 0
    local hasfinaldata 0
    if `"`data'"'!="" local hasfinaldata 1
    local nfinalansweredall 0
    local nanswereddisabledall 0
    local nexpectedblankall 0
    local nblankenabledall 0
    local nlogicunknownall 0
    local nnotindataall 0
    local nfinalcheckall = `nopenall' + `nunknownall'
    tempfile skdet
    if `nhist'>0 {
        local hasdet 1
        preserve
        quietly keep if sk_viewrem
        sort interview__id sk_run para_ord para_seq
        quietly by interview__id sk_run: gen long sk_k = _n
        quietly gen str80 sk_itemvar = para_var
        quietly gen str244 sk_itemdisp = para_qdisp
        quietly replace sk_itemvar = "(identity unavailable)" if sk_identityunknown
        quietly replace sk_itemdisp = "(question identity unavailable in paradata)" ///
            if sk_identityunknown

        * Build distinct, roster-aware lists for all affected instances and for
        * each final-state bucket shown to supervisors.
        quietly gen strL sk_wvars = ""
        quietly gen strL sk_wl = ""
        quietly gen strL sk_wr = ""
        quietly gen strL sk_wo = ""
        quietly gen strL sk_wu = ""
        if `hasvar' {
            quietly by interview__id sk_run: replace sk_wvars = ///
                cond(_n==1, cond(sk_hist_qtag, sk_itemvar, ""), ///
                cond(sk_hist_qtag, sk_wvars[_n-1] + cond(sk_wvars[_n-1]=="", "", ", ") + sk_itemvar, sk_wvars[_n-1]))
            quietly by interview__id sk_run: replace sk_wl = ///
                cond(_n==1, cond(sk_hist_qtag, sk_itemdisp, ""), ///
                cond(sk_hist_qtag, sk_wl[_n-1] + cond(sk_wl[_n-1]=="", "", ", ") + sk_itemdisp, sk_wl[_n-1]))
            quietly by interview__id sk_run: replace sk_wr = ///
                cond(_n==1, cond(sk_hist_reanswered, sk_itemdisp, ""), ///
                cond(sk_hist_reanswered, sk_wr[_n-1] + cond(sk_wr[_n-1]=="", "", ", ") + sk_itemdisp, sk_wr[_n-1]))
            quietly by interview__id sk_run: replace sk_wo = ///
                cond(_n==1, cond(sk_hist_open, sk_itemdisp, ""), ///
                cond(sk_hist_open, sk_wo[_n-1] + cond(sk_wo[_n-1]=="", "", ", ") + sk_itemdisp, sk_wo[_n-1]))
            quietly by interview__id sk_run: replace sk_wu = ///
                cond(_n==1, cond(sk_hist_unknown, sk_itemdisp, ""), ///
                cond(sk_hist_unknown, sk_wu[_n-1] + cond(sk_wu[_n-1]=="", "", ", ") + sk_itemdisp, sk_wu[_n-1]))
        }

        collapse (last) wvars=sk_wvars wl=sk_wl wl_reanswered=sk_wr             ///
            wl_open=sk_wo wl_unknown=sk_wu                                      ///
            avar=sk_nextvar aval=sk_nextval aroster=sk_nextroster               ///
            aqkey=sk_nextqkey aord=sk_nextord aseq=sk_nextseq ats=sk_nextts     ///
            pvar=sk_lastvar pval=sk_lastval proster=sk_lastroster               ///
            pqkey=sk_lastqkey pord=sk_lastord pseq=sk_lastseq pts=sk_lastts     ///
            (max) tend=para_tsu                                                  ///
            (count) nrem=sk_k (sum) nqrem=sk_hist_qtag                         ///
            nreanswered=sk_hist_reanswered nopen=sk_hist_open                  ///
            nunknown=sk_hist_unknown n_identityunknown=sk_identityunknown      ///
            (min) ts0=para_tsu                                                  ///
            (first) trigger=sk_trig trigval=sk_trigval                          ///
            trigger_roster=sk_trigroster trigger_qkey=sk_trigqkey              ///
            trigger_tsu=sk_trigts trigger_ord=sk_trigord trigger_seq=sk_trigseq ///
            useprev=sk_useprev prevok=sk_prevnear nextok=sk_nextnear            ///
            prevcontext=sk_prevcontext nextcontext=sk_nextcontext               ///
            compact=sk_casc timing_unknown=sk_timing_unknown                    ///
            actor=sk_actor actor_key=sk_actor_key resp=sk_resp,               ///
            by(interview__id sk_run) fast

        * Context is retained for every inventory history.  prevok/nextok state
        * whether it also passed the bounded compact-pattern proximity test.
        quietly replace pvar = "" if prevcontext!=1
        quietly replace pval = "" if pvar==""
        quietly replace proster = "" if pvar==""
        quietly replace pqkey = "" if pvar==""
        quietly replace pord = . if pvar==""
        quietly replace pseq = . if pvar==""
        quietly replace pts = . if pvar==""
        quietly replace avar = "" if nextcontext!=1
        quietly replace aval = "" if avar==""
        quietly replace aroster = "" if avar==""
        quietly replace aqkey = "" if avar==""
        quietly replace aord = . if avar==""
        quietly replace aseq = . if avar==""
        quietly replace ats = . if avar==""

        * Questionnaire metadata distinguishes five relationship cases:
        *   1 linked candidate; 2 conditions exist but do not reference it;
        *   3 known questions with no item-level condition shown; 4 variables absent from preview;
        *   5 a mixture of known and absent variables.
        quietly gen byte conf = 0
        quietly gen int nqknown = 0
        quietly gen int nqcond = 0
        quietly gen int nqabsent = 0
        quietly gen int nlinked = 0
        quietly gen int nlinked_direct = 0
        quietly gen int nlinked_indirect = 0
        quietly gen byte reltype = 2
        if `hasqx' {
            forvalues r = 1/`=_N' {
                local wlw = subinstr(wvars[`r'], ",", " ", .)
                local av = avar[`r']
                local pv = pvar[`r']
                local up = useprev[`r']
                local hitAd 0
                local hitAi 0
                local hitPd 0
                local hitPi 0
                local nknown 0
                local ncond 0
                local nabs 0
                foreach w of local wlw {
                    local qi 0
                    forvalues qj = 1/`nqx' {
                        if `"`w'"'==`"`qxname_`qj''"' {
                            local qi `qj'
                            continue, break
                        }
                    }
                    if `qi'>0 local ++nknown
                    else local ++nabs
                    local ee ""
                    local dd ""
                    if `qi'>0 {
                        local ee `"`qxen_`qi''"'
                        local dd `"`qxdeps_`qi''"'
                    }
                    if `"`ee'"'=="" continue
                    local ++ncond
                    if "`av'"!="" {
                        if ustrregexm(`"`ee'"', "(^|[^A-Za-z0-9_])`av'([^A-Za-z0-9_]|$)") local ++hitAd
                        else if ustrregexm(`"`dd'"', "(^|[^A-Za-z0-9_])`av'([^A-Za-z0-9_]|$)") local ++hitAi
                    }
                    if "`pv'"!="" {
                        if ustrregexm(`"`ee'"', "(^|[^A-Za-z0-9_])`pv'([^A-Za-z0-9_]|$)") local ++hitPd
                        else if ustrregexm(`"`dd'"', "(^|[^A-Za-z0-9_])`pv'([^A-Za-z0-9_]|$)") local ++hitPi
                    }
                }
                local hitA = `hitAd' + `hitAi'
                local hitP = `hitPd' + `hitPi'
                quietly replace nqknown = `nknown' in `r'
                quietly replace nqcond = `ncond' in `r'
                quietly replace nqabsent = `nabs' in `r'

                if `hitA'>0 & (`hitP'==0 | `up'==0) {
                    quietly replace conf = 2 in `r'
                    quietly replace nlinked = `hitA' in `r'
                    quietly replace nlinked_direct = `hitAd' in `r'
                    quietly replace nlinked_indirect = `hitAi' in `r'
                    quietly replace trigger = avar[`r'] in `r'
                    quietly replace trigval = aval[`r'] in `r'
                    quietly replace trigger_roster = aroster[`r'] in `r'
                    quietly replace trigger_qkey = aqkey[`r'] in `r'
                    quietly replace trigger_tsu = ats[`r'] in `r'
                    quietly replace trigger_ord = aord[`r'] in `r'
                    quietly replace trigger_seq = aseq[`r'] in `r'
                    quietly replace useprev = 0 in `r'
                }
                else if `hitP'>0 {
                    quietly replace conf = 1 in `r'
                    quietly replace nlinked = `hitP' in `r'
                    quietly replace nlinked_direct = `hitPd' in `r'
                    quietly replace nlinked_indirect = `hitPi' in `r'
                    quietly replace trigger = pvar[`r'] in `r'
                    quietly replace trigval = pval[`r'] in `r'
                    quietly replace trigger_roster = proster[`r'] in `r'
                    quietly replace trigger_qkey = pqkey[`r'] in `r'
                    quietly replace trigger_tsu = pts[`r'] in `r'
                    quietly replace trigger_ord = pord[`r'] in `r'
                    quietly replace trigger_seq = pseq[`r'] in `r'
                    quietly replace useprev = 1 in `r'
                }
            }
        }
        quietly gen byte linkmode = 0
        quietly replace linkmode = 1 if nlinked_direct>0 & nlinked_indirect==0
        quietly replace linkmode = 2 if nlinked_direct==0 & nlinked_indirect>0
        quietly replace linkmode = 3 if nlinked_direct>0 & nlinked_indirect>0
        quietly replace reltype = 6 if !`hasqx'
        quietly replace reltype = 1 if conf>0
        quietly replace reltype = 3 if conf==0 & nqknown==nqrem & nqcond==0 & nqrem>0 & `hasqx'
        quietly replace reltype = 4 if conf==0 & nqknown==0 & nqrem>0 & `hasqx'
        quietly replace reltype = 5 if conf==0 & nqknown>0 & nqknown<nqrem & `hasqx'
        quietly gen byte allsvc = reltype==4
        quietly gen byte allalways = reltype==3
        quietly gen byte mixedqx = reltype==5

        if `hasqx' {
            quietly merge m:1 trigger using `"`QXT'"', keep(master match) nogenerate
        }
        else {
            quietly gen str60 qx_type = ""
            quietly gen strL qx_text = ""
            quietly gen strL qx_section = ""
            quietly gen strL qx_enable = ""
            quietly gen strL qx_optmap = ""
        }

        * The questionnaire-adjudicated trigger remains in the one-row-per-run
        * detail table. It is not merged back onto the multi-row event stream: that
        * merge is unnecessary for interview-level counts and was a repeated source
        * of fragile run-key failures on large real paradata exports.

        * Exact value history for the chosen AnswerSet and question instance.
        quietly gen str16 prev_event = ""
        quietly gen strL prev_value = ""
        quietly gen double prev_ord = .
        quietly gen double prev_seq = .
        quietly gen double prev_tsu = .
        quietly gen strL oldval = ""
        tempfile DETBASE PREVSTATE PREVANS
        quietly save `"`DETBASE'"'
        local hasprevstate 0
        local hasprevans 0
        if `hashstate' {
            quietly keep interview__id sk_run trigger_qkey trigger_ord trigger_seq
            quietly drop if trigger_qkey=="" | missing(trigger_ord)
            if _N>0 {
                quietly joinby interview__id trigger_qkey using `"`HSTATE'"', unmatched(none)
                quietly keep if hist_ord<trigger_ord | ///
                    (hist_ord==trigger_ord & hist_seq<trigger_seq)
                if _N>0 {
                    quietly sort interview__id sk_run hist_ord hist_seq
                    quietly by interview__id sk_run: keep if _n==_N
                    quietly rename hist_event prev_event
                    quietly rename hist_val prev_value
                    quietly rename hist_ord prev_ord
                    quietly rename hist_seq prev_seq
                    quietly rename hist_tsu prev_tsu
                    quietly gen str244 __suso_runkey = interview__id + "|" + ///
                        strtrim(string(sk_run,"%21.0g"))
                    quietly keep __suso_runkey prev_event prev_value ///
                        prev_ord prev_seq prev_tsu
                    quietly bysort __suso_runkey: keep if _n==1
                    quietly isid __suso_runkey
                    quietly save `"`PREVSTATE'"'
                    local hasprevstate 1
                }
            }

            quietly use `"`DETBASE'"', clear
            quietly keep interview__id sk_run trigger_qkey trigger_ord trigger_seq
            quietly drop if trigger_qkey=="" | missing(trigger_ord)
            if _N>0 {
                quietly joinby interview__id trigger_qkey using `"`HSTATE'"', unmatched(none)
                quietly keep if hist_event=="answerset" & ///
                    (hist_ord<trigger_ord | (hist_ord==trigger_ord & hist_seq<trigger_seq))
                if _N>0 {
                    quietly sort interview__id sk_run hist_ord hist_seq
                    quietly by interview__id sk_run: keep if _n==_N
                    quietly rename hist_val oldval
                    quietly gen str244 __suso_runkey = interview__id + "|" + ///
                        strtrim(string(sk_run,"%21.0g"))
                    quietly keep __suso_runkey oldval
                    quietly bysort __suso_runkey: keep if _n==1
                    quietly isid __suso_runkey
                    quietly save `"`PREVANS'"'
                    local hasprevans 1
                }
            }
        }
        quietly use `"`DETBASE'"', clear
        quietly gen str244 __suso_runkey = interview__id + "|" + ///
            strtrim(string(sk_run,"%21.0g"))
        quietly isid __suso_runkey
        if `hasprevstate' quietly merge 1:1 __suso_runkey using `"`PREVSTATE'"', ///
            update replace nogenerate
        if `hasprevans' quietly merge 1:1 __suso_runkey using `"`PREVANS'"', ///
            update replace nogenerate
        quietly drop __suso_runkey

        quietly gen byte transition = 0
        quietly replace transition = 1 if trigger_qkey!="" & prev_event=="" & trigval!=""
        quietly replace transition = 2 if prev_event=="answerset" & oldval!=trigval
        quietly replace transition = 3 if prev_event=="answerset" & oldval==trigval
        quietly replace transition = 4 if prev_event=="answerremoved" & trigval!=""

        quietly gen strL oldlabel = ""
        quietly gen strL newlabel = ""
        mata: _suso_qx_apply_labels("oldval", "trigval", "qx_optmap", "oldlabel", "newlabel")
        quietly gen strL oldshow = oldval + cond(oldlabel!="", " - " + oldlabel, "")
        quietly gen strL newshow = trigval + cond(newlabel!="", " - " + newlabel, "")
        quietly gen strL trigger_display = trigger + ///
            cond(trigger_roster!="", " [roster " + trigger_roster + "]", "")
        quietly gen str40 trigger_when = ""
        quietly replace trigger_when = string(trigger_tsu/86400000, "%tdDD_Mon_CCYY") + ///
            " " + string(trigger_tsu, "%tcHH:MM:SS") + " UTC" if !missing(trigger_tsu)
        quietly gen str40 transition_status = "Historical event not reconstructed"
        quietly replace transition_status = "Historical first observed value" if transition==1
        quietly replace transition_status = "Historical value change" if transition==2
        quietly replace transition_status = "Historical repeated value" if transition==3
        quietly replace transition_status = "Historical re-entry after removal" if transition==4
        quietly gen strL transition_text = ///
            "Exact historical answer transition could not be reconstructed from the available paradata."
        quietly replace transition_text = cond(trigger_when!="", "At " + trigger_when + ", ", "") + ///
            trigger_display + " was recorded as " + newshow + ///
            "; no earlier state event for this question instance was found." if transition==1
        quietly replace transition_text = cond(trigger_when!="", "At " + trigger_when + ", ", "") + ///
            trigger_display + " changed from " + oldshow + " to " + newshow + ///
            ". This describes that historical AnswerSet, not necessarily the final exported value." ///
            if transition==2
        quietly replace transition_text = cond(trigger_when!="", "At " + trigger_when + ", ", "") + ///
            trigger_display + " was recorded again as " + newshow + ///
            "; the value did not change at that event." if transition==3
        quietly replace transition_text = cond(trigger_when!="", "At " + trigger_when + ", ", "") + ///
            trigger_display + " was re-entered as " + newshow + " after being cleared" + ///
            cond(oldshow!="", "; the earlier recorded value was " + oldshow, "") + "." ///
            if transition==4

        * Compare every affected question instance with the FINAL export and the
        * inherited questionnaire logic. This removes false positives where the
        * final value is blank precisely because the final screening state disables it.
        tempfile DETTRANS
        quietly save `"`DETTRANS'"'
        if `"`data'"'!="" & `hascasev' {
            local qxopt ""
            if `hasqx' local qxopt `"qxmeta(`"`QXMETA'"')"'
            quietly _suso_para_casefinal using `"`CASEV'"', data(`"`data'"') ///
                saving(`"`FINALV'"') `qxopt'
            quietly use `"`FINALV'"', clear
            quietly gen byte __fa = final_status==1
            quietly gen byte __ad = final_status==7
            quietly gen byte __eb = final_status==2
            quietly gen byte __be = final_status==3
            quietly gen byte __lu = final_status==4
            quietly gen byte __nd = inlist(final_status,5,6)
            quietly gen byte __ck = inlist(final_status,3,4,5,6,7)
            quietly gen strL __la = cond(__fa,affected_qdisp,"")
            quietly gen strL __ld = cond(__ad,affected_qdisp,"")
            quietly gen strL __le = cond(__eb,affected_qdisp,"")
            quietly gen strL __lb = cond(__be,affected_qdisp,"")
            quietly gen strL __ll = cond(__lu,affected_qdisp,"")
            quietly gen strL __ln = cond(__nd,affected_qdisp,"")
            quietly gen strL __lc = cond(__ck,affected_qdisp,"")
            quietly sort interview__id sk_run affected_qdisp
            foreach z in la ld le lb ll ln lc {
                quietly by interview__id sk_run: replace __`z' = ///
                    cond(_n==1,__`z',cond(__`z'!="",__`z'[_n-1] + ///
                    cond(__`z'[_n-1]=="","",", ") + __`z',__`z'[_n-1]))
            }
            quietly collapse (sum) n_final_answered=__fa                    ///
                n_answered_disabled=__ad n_expected_blank=__eb                  ///
                n_blank_enabled=__be n_logic_unknown=__lu n_notindata=__nd      ///
                n_final_check=__ck (last) wl_final_answered=__la                ///
                wl_answered_disabled=__ld wl_expected_blank=__le                ///
                wl_blank_enabled=__lb wl_logic_unknown=__ll                     ///
                wl_notindata=__ln wl_final_check=__lc,                          ///
                by(interview__id sk_run) fast
            quietly summarize n_final_answered
            local nfinalansweredall = r(sum)
            quietly summarize n_answered_disabled
            local nanswereddisabledall = r(sum)
            quietly summarize n_expected_blank
            local nexpectedblankall = r(sum)
            quietly summarize n_blank_enabled
            local nblankenabledall = r(sum)
            quietly summarize n_logic_unknown
            local nlogicunknownall = r(sum)
            quietly summarize n_notindata
            local nnotindataall = r(sum)
            quietly summarize n_final_check
            local nfinalcheckall = r(sum) + `nidentityunknownall'
            quietly gen str244 __suso_runkey = interview__id + "|" + ///
                strtrim(string(sk_run,"%21.0g"))
            quietly bysort __suso_runkey: keep if _n==1
            quietly isid __suso_runkey
            quietly save `"`FINALCASE'"', replace

            tempfile FINALCASEMAP
            quietly keep __suso_runkey n_final_answered n_answered_disabled ///
                n_expected_blank n_blank_enabled n_logic_unknown n_notindata ///
                n_final_check wl_final_answered wl_answered_disabled ///
                wl_expected_blank wl_blank_enabled wl_logic_unknown ///
                wl_notindata wl_final_check
            quietly save `"`FINALCASEMAP'"', replace

            quietly use `"`DETTRANS'"', clear
            quietly gen str244 __suso_runkey = interview__id + "|" + ///
                strtrim(string(sk_run,"%21.0g"))
            quietly isid __suso_runkey
            quietly merge 1:1 __suso_runkey using `"`FINALCASEMAP'"', ///
                keep(master match) nogenerate
            quietly drop __suso_runkey
        }
        else quietly use `"`DETTRANS'"', clear

        * Keep the historical AnswerSet separate from the value in the final
        * export. A transition such as 1 -> 6 may be an intermediate event even
        * when the current exported value has subsequently returned to 1.
        tempfile DETFINAL TRIGFINAL
        quietly save `"`DETFINAL'"', replace
        if `"`data'"'!="" {
            quietly _suso_para_triggerfinal using `"`DETFINAL'"', ///
                data(`"`data'"') saving(`"`TRIGFINAL'"')
            tempfile TRIGFINALMAP
            quietly use `"`TRIGFINAL'"', clear
            quietly gen str244 __suso_runkey = interview__id + "|" + ///
                strtrim(string(sk_run,"%21.0g"))
            quietly bysort __suso_runkey: keep if _n==1
            quietly isid __suso_runkey
            quietly keep __suso_runkey trigger_final_status trigger_final_value ///
                trigger_final_label trigger_final_show trigger_final_matches_event ///
                trigger_final_returns_old trigger_final_text
            quietly save `"`TRIGFINALMAP'"', replace

            quietly use `"`DETFINAL'"', clear
            quietly gen str244 __suso_runkey = interview__id + "|" + ///
                strtrim(string(sk_run,"%21.0g"))
            quietly isid __suso_runkey
            quietly merge 1:1 __suso_runkey using `"`TRIGFINALMAP'"', ///
                keep(master match) nogenerate
            quietly drop __suso_runkey
        }
        else quietly use `"`DETFINAL'"', clear
        foreach v in trigger_final_status trigger_final_matches_event            ///
            trigger_final_returns_old {
            capture confirm variable `v'
            if _rc quietly gen byte `v' = .
        }
        foreach v in trigger_final_value trigger_final_label trigger_final_show  ///
            trigger_final_text {
            capture confirm variable `v'
            if _rc quietly gen strL `v' = ""
        }

        quietly merge m:1 interview__id using `"`skstatusfile'"',             ///
            keep(master match) nogenerate
        foreach v in ws ws_paradata ws_data ws_source ws_class {
            capture confirm variable `v', exact
            if _rc quietly gen str40 `v' = ""
            quietly replace `v' = "" if missing(`v')
        }
        capture confirm variable ws_mismatch, exact
        if _rc quietly gen byte ws_mismatch = 0
        quietly replace ws_mismatch = 0 if missing(ws_mismatch)

        quietly gen byte final_data_checked = `hasfinaldata'
        foreach v in n_final_answered n_answered_disabled n_expected_blank      ///
            n_blank_enabled n_logic_unknown n_notindata n_final_check {
            capture confirm variable `v'
            if _rc quietly gen long `v' = 0
            quietly replace `v' = 0 if missing(`v')
        }
        foreach v in wl_final_answered wl_answered_disabled wl_expected_blank   ///
            wl_blank_enabled wl_logic_unknown wl_notindata wl_final_check {
            capture confirm variable `v'
            if _rc quietly gen strL `v' = ""
        }
        quietly gen strL wl_identity_unknown = ""
        quietly replace wl_identity_unknown = "(question identity unavailable in paradata)" ///
            if n_identityunknown>0
        quietly replace n_final_check = n_final_check + n_identityunknown      ///
            if final_data_checked
        quietly replace wl_final_check = strtrim(wl_final_check +              ///
            cond(wl_final_check!="" & n_identityunknown>0, ", ", "") +       ///
            wl_identity_unknown) if final_data_checked
        quietly replace n_final_check = nopen+nunknown if !final_data_checked
        quietly replace wl_final_check = strtrim(wl_open + ///
            cond(wl_open!="" & wl_unknown!="", ", ", "") + wl_unknown) ///
            if !final_data_checked

        * Recompute exhaustive final-state totals after adding identity-unknown
        * units.  Also save one row per history for the parallel hist_*/casc_*
        * interview summaries below.
        quietly summarize n_final_answered
        local nfinalansweredall = r(sum)
        quietly summarize n_answered_disabled
        local nanswereddisabledall = r(sum)
        quietly summarize n_expected_blank
        local nexpectedblankall = r(sum)
        quietly summarize n_blank_enabled
        local nblankenabledall = r(sum)
        quietly summarize n_logic_unknown
        local nlogicunknownall = r(sum)
        quietly summarize n_notindata
        local nnotindataall = r(sum)
        quietly summarize n_final_check
        local nfinalcheckall = r(sum)
        quietly save `"`FINALCASE'"', replace
        quietly save `"`skdet'"'
        if `"`detail'"'!="" quietly copy `"`skdet'"' `"`detail'"', replace
        restore

        * Final-data counts for the Behaviour dashboard and saved skip table.
        if `hasfinaldata' {
            preserve
                quietly use `"`FINALCASE'"', clear
                foreach z in final_answered answered_disabled expected_blank    ///
                    blank_enabled logic_unknown notindata final_check {
                    quietly gen long __c_`z' = 0
                }
                quietly replace __c_final_answered = n_final_answered*compact
                quietly replace __c_answered_disabled = n_answered_disabled*compact
                quietly replace __c_expected_blank = n_expected_blank*compact
                quietly replace __c_blank_enabled = n_blank_enabled*compact
                quietly replace __c_logic_unknown = n_logic_unknown*compact
                quietly replace __c_notindata = n_notindata*compact
                quietly replace __c_final_check = n_final_check*compact
                quietly collapse (sum) hist_finalanswered=n_final_answered      ///
                    hist_answered_disabled=n_answered_disabled                  ///
                    hist_expectedblank=n_expected_blank                         ///
                    hist_blank_enabled=n_blank_enabled                          ///
                    hist_logicunknown=n_logic_unknown hist_notindata=n_notindata ///
                    hist_finalcheck=n_final_check                               ///
                    casc_finalanswered=__c_final_answered                       ///
                    casc_answered_disabled=__c_answered_disabled                ///
                    casc_expectedblank=__c_expected_blank                       ///
                    casc_blank_enabled=__c_blank_enabled                        ///
                    casc_logicunknown=__c_logic_unknown                         ///
                    casc_notindata=__c_notindata                                ///
                    casc_finalcheck=__c_final_check, by(interview__id) fast
                quietly gen byte casc_datachecked = 1
                quietly gen byte hist_datachecked = 1
                quietly save `"`FINALINT'"', replace
            restore
        }

        * No run-level lookup is merged back to the event stream. Interview-level
        * cascade counts below are invariant to candidate re-attribution; the detailed
        * review and trigger summary use the adjudicated one-row-per-run table.
    }

    quietly gen byte sk_viewoutside = sk_viewrem & !sk_viewcasc
    quietly gen byte sk_outside = sk_isrem & !sk_casc
    tempfile SKACT
    local hasact 0
    if `nhist'>0 {
        preserve
            quietly keep if sk_viewhistory1
            quietly replace sk_actor_key = "__unknown_removal_actor__" if sk_actor_key==""
            quietly replace sk_actor = "Unknown removal actor" if sk_actor==""
            quietly sort interview__id sk_actor_key sk_actor
            quietly by interview__id sk_actor_key: keep if _n==1
            quietly gen byte __oneactor = 1
            quietly collapse (sum) n_removal_actors=__oneactor                ///
                (first) removal_actor=sk_actor, by(interview__id) fast
            quietly replace removal_actor = "Multiple removal actors" if    ///
                n_removal_actors>1
            quietly save `"`SKACT'"'
            local hasact 1
        restore
    }

    * ---- stage 1: collapse to (interview x context answer) -----------------
    * Compatibility casc_* fields remain compact-only.  removal_/hist_* fields
    * are the exhaustive inventory, while *_all fields stay global when vars()
    * requests a focused view.
    collapse (sum) n_answers=para_fieldans n_removed=para_fieldrem            ///
        n_removed_allroles=para_rem removed_view=sk_viewrem                   ///
        n_removal_histories=sk_viewhistory1                                   ///
        n_removal_histories_all=sk_history1                                   ///
        n_cascades=sk_viewcasc1 n_cascades_all=sk_casc1                       ///
        casc_removed=sk_viewcasc casc_removed_all=sk_casc                     ///
        outside_removed=sk_viewoutside outside_removed_all=sk_outside         ///
        timing_unknown_histories=sk_viewtimingunknown1                        ///
        timing_unknown_histories_all=sk_timing_unknown1                       ///
        timing_unknown_events=sk_viewtimingunknown                            ///
        timing_unknown_events_all=sk_timing_unknown                           ///
        removal_questions=sk_hist_qtag removal_open=sk_hist_open              ///
        removal_reanswered=sk_hist_reanswered removal_unknown=sk_hist_unknown ///
        removal_identityunknown=sk_identityunknown                            ///
        casc_questions=sk_qtag casc_open=sk_open                              ///
        casc_reanswered=sk_reanswered casc_unknown=sk_unknown                 ///
        (first) responsible=sk_resp, by(interview__id sk_trig) fast
    tempfile sk1
    quietly save `"`sk1'"'

    di as txt _n "{hline 72}"
    di as res "  suso paradata skips" as txt "   (cascade = >=`cascade' removals within `window's of an answer)"
    di as txt "{hline 72}"

    * ---- survey-level: adjudicated answer variables recurring across runs -------
    if `hasvar' & `nhist'>0 & `hasdet' {
        quietly use `"`skdet'"', clear
        quietly keep if trigger!=""
        if _N>0 {
            quietly gen byte __one = 1
            quietly bysort trigger interview__id: gen byte __itag = (_n==1)
            quietly collapse (sum) n_flips=__one wiped=nrem n_ints=__itag, ///
                by(trigger) fast
            quietly rename trigger sk_trig
            gsort -wiped -n_flips sk_trig
            local k = min(10, _N)
            tempname SKT
            matrix `SKT' = J(`k', 3, 0)
            local trigret ""
            di as txt "  nearby or questionnaire-linked answer variables associated with the most removal events (top `k'):"
            di as txt "  {ul:variable                }  {ul:runs}  {ul:interviews}  {ul:removal events}"
            forvalues i = 1/`k' {
                local vv : di %-24s abbrev(sk_trig[`i'],24)
                local nf : di %5.0f n_flips[`i']
                local ni : di %10.0f n_ints[`i']
                local wp : di %13.0f wiped[`i']
                di as txt "  " as res "`vv'" as txt "  `nf'  `ni'  `wp'"
                local trigret `"`trigret' `=sk_trig[`i']'"'
                matrix `SKT'[`i',1] = n_flips[`i']
                matrix `SKT'[`i',2] = n_ints[`i']
                matrix `SKT'[`i',3] = wiped[`i']
            }
            return local triggers `"`trigret'"'
            return matrix triggers_stats = `SKT'
        }
        quietly use `"`sk1'"', clear
    }

    * ---- stage 2: one row per interview ----
    quietly gen byte sk_tg = (sk_trig!="")
    collapse (sum) n_answers n_removed n_removed_allroles removed_view          ///
        n_removal_histories n_removal_histories_all n_cascades n_cascades_all   ///
        casc_removed casc_removed_all outside_removed outside_removed_all       ///
        timing_unknown_histories timing_unknown_histories_all                  ///
        timing_unknown_events timing_unknown_events_all                        ///
        removal_questions removal_open removal_reanswered removal_unknown       ///
        removal_identityunknown casc_questions casc_open casc_reanswered        ///
        casc_unknown n_triggers=sk_tg                                           ///
        (first) responsible, by(interview__id) fast
    if `hasact' quietly merge 1:1 interview__id using `"`SKACT'"',            ///
        keep(master match) nogenerate
    capture confirm variable removal_actor, exact
    if _rc quietly gen str40 removal_actor = ""
    capture confirm variable n_removal_actors, exact
    if _rc quietly gen long n_removal_actors = 0
    if `hasfinaldata' & `hasdet' quietly merge 1:1 interview__id using `"`FINALINT'"', ///
        keep(master match) nogenerate
    quietly merge 1:1 interview__id using `"`skstatusfile'"',                ///
        keep(master match) nogenerate
    foreach v in hist_finalanswered hist_answered_disabled hist_expectedblank  ///
        hist_blank_enabled hist_logicunknown hist_notindata hist_finalcheck     ///
        hist_datachecked                                                       ///
        casc_finalanswered casc_answered_disabled casc_expectedblank          ///
        casc_blank_enabled casc_logicunknown casc_notindata casc_finalcheck       ///
        casc_datachecked {
        capture confirm variable `v'
        if _rc quietly gen long `v' = 0
        quietly replace `v' = 0 if missing(`v')
    }
    quietly gen double wipe_share = casc_removed/max(n_answers,1)
    label variable interview__id "interview id"
    label variable responsible   "primary interviewer / last-editor context"
    label variable removal_actor "actual removal-run actor (multiple if applicable)"
    label variable n_removal_actors "distinct actors with focused removal histories"
    label variable n_answers     "AnswerSet events"
    label variable n_removed     "AnswerRemoved events in current role scope (global)"
    label variable n_removed_allroles "AnswerRemoved events across all roles (global)"
    label variable removed_view  "all AnswerRemoved events in focused inventory histories"
    label variable n_removal_histories "all focused consecutive removal histories"
    label variable n_removal_histories_all "all consecutive removal histories (global)"
    label variable n_cascades    "focused compact-priority removal histories"
    label variable n_cascades_all "compact-priority removal histories (global)"
    label variable casc_removed    "focused AnswerRemoved events in compact histories"
    label variable casc_removed_all "AnswerRemoved events in compact histories (global)"
    label variable outside_removed "focused raw events outside compact-priority histories"
    label variable removal_questions "all focused question-within-history units"
    label variable removal_open "inventory units whose final paradata event is AnswerRemoved"
    label variable removal_reanswered "inventory units re-answered later"
    label variable removal_unknown "inventory units with unknown paradata final state"
    label variable removal_identityunknown "histories with an identity-unavailable question unit"
    label variable hist_finalanswered "inventory units answered in final data"
    label variable hist_answered_disabled "inventory final answers present while disabled"
    label variable hist_expectedblank "inventory final blanks expected because disabled"
    label variable hist_blank_enabled "inventory final blanks while enabled"
    label variable hist_logicunknown "inventory final blanks with enablement unknown"
    label variable hist_notindata "inventory units absent from supplied data"
    label variable hist_finalcheck "inventory units needing final-data review"
    label variable casc_questions  "compact-priority question-within-run cases affected"
    label variable casc_open       "affected questions whose final event is AnswerRemoved"
    label variable casc_reanswered "affected questions re-answered later"
    label variable casc_unknown      "affected questions with unknown paradata final state"
    label variable casc_finalanswered "affected questions answered in final data"
    label variable casc_answered_disabled "final answers present while disabled"
    label variable casc_expectedblank  "final blanks expected because disabled"
    label variable casc_blank_enabled  "final blanks while enabled"
    label variable casc_logicunknown   "final blanks with enablement unknown"
    label variable casc_notindata      "affected instances absent from supplied data"
    label variable casc_finalcheck     "affected instances needing final-data review"
    label variable casc_datachecked    "final data and inherited logic evaluated"
    label variable n_triggers          "distinct nearby or questionnaire-linked answer variables"
    label variable wipe_share      "removal events / answers set"
    format wipe_share %5.2f
    sort interview__id
    char _dta[suso_paradata] skips

    quietly count if n_removal_histories>0
    local naff = r(N)
    local nints = _N
    di as txt "  removal histories " as res "`nhist'" as txt "  |  raw events " ///
        as res "`nremevents'" as txt "  |  compact histories/events " as res ///
        "`ncasc'/`nwiped'" as txt "  |  outside-pattern events " as res "`noutsideevents'"
    di as txt "  question-history units " as res "`naffectedqall'"             ///
        as txt "  |  re-answered later " as res "`nreansweredall'" ///
        as txt "  |  interviews affected " as res "`naff'" as txt " of " as res "`nints'"
    if `hasfinaldata' di as txt "  final export: answered " as res "`nfinalansweredall'" ///
        as txt "  |  blank as expected (disabled) " as res "`nexpectedblankall'" ///
        as txt "  |  answered while disabled " as res "`nanswereddisabledall'" ///
        as txt "  |  blank while enabled " as res "`nblankenabledall'" ///
        as txt "  |  logic/data unresolved " as res "`=`nlogicunknownall'+`nnotindataall''"
    else di as txt "  no data() supplied: action triage falls back to paradata final state."

    * ---- top interviews ----
    if `naff'>0 {
        gsort -removed_view -n_removal_histories interview__id
        local k = min(`top', `naff')
        di as txt _n "  interviews with the most removal events (top `k'):"
        di as txt "  {ul:interview}  {ul:actual removal actor}  {ul:histories}  {ul:raw events}  {ul:compact}  {ul:outside}"
        forvalues i = 1/`k' {
            local id8 = substr(interview__id[`i'],1,8)
            local rsp : di %-20s abbrev(removal_actor[`i'],20)
            local nh : di %9.0f n_removal_histories[`i']
            local nr : di %5.0f removed_view[`i']
            local nc : di %7.0f casc_removed[`i']
            local no : di %7.0f outside_removed[`i']
            di as txt "  " as res "`id8'" as txt "   `rsp'  `nh'  `nr'  `nc'  `no'"
        }
        sort interview__id

        * ---- interviewer league (share of interviews with any cascade) ----
        quietly count if responsible!=""
        if r(N)>0 {
            preserve
            tempvar anyc
            quietly gen byte `anyc' = n_cascades>0
            collapse (count) n_ints=n_cascades (sum) n_casc=`anyc'                ///
                flips=n_cascades wiped=casc_removed, by(responsible) fast
            quietly drop if responsible==""
            quietly gen double casc_share = n_casc/n_ints
            gsort -casc_share -wiped responsible
            local k = min(10, _N)
            di as txt _n "  primary-interviewer context, by compact-history share (top `k'):"
            di as txt "  {ul:primary context }  {ul:ints}  {ul:w/ compact}  {ul:share}  {ul:histories}  {ul:compact events}"
            forvalues i = 1/`k' {
                local rsp : di %-16s abbrev(responsible[`i'],16)
                local ni : di %4.0f n_ints[`i']
                local nc : di %10.0f n_casc[`i']
                local sh : di %5.2f casc_share[`i']
                local nf : di %5.0f flips[`i']
                local wp : di %5.0f wiped[`i']
                di as txt "  `rsp'  `ni'  `nc'  " as res "`sh'" as txt "  `nf'  `wp'"
            }
            restore
        }
    }
    di as txt _n "  A cascade can be a legitimate correction; systematic patterns by the"
    di as txt "  unresolved final states and repeated questionnaire-linked patterns warrant review."
    di as txt "  data in memory = one row per interview; merge on interview__id with"
    di as txt "  the {bf:suso paradata flags} table for a combined QC file."
    di as txt "{hline 72}"

    * ---- supervisor action list: one clear message per cascade -------------------
    * Every line is built in expression-land (never through macros): answer values
    * and question wording can contain quotes/backticks/dollars that would break
    * macro expansion, so data only ever reaches the screen/file via (exp).
    if `hasdet' {
        preserve
        quietly use `"`skdet'"', clear
        gsort -nqrem -nrem interview__id sk_run
        local hasqxt 0
        capture confirm variable qx_text
        if !_rc local hasqxt 1

        * ---- automatic triage: classify every case, roll up to findings -------------
        quietly gen byte nsecs = 1
        quietly gen byte selferased = 0
        quietly gen strL wlc = wl
        forvalues r = 1/`=_N' {
            local wlw = subinstr(wvars[`r'], ",", " ", .)
            local trg = trigger[`r']
            local selfr 0
            local secs ""
            foreach w of local wlw {
                if "`w'"=="`trg'" & "`trg'"!="" local selfr 1
                if `hasqxt' {
                    local qi 0
                    forvalues qj = 1/`nqx' {
                        if `"`w'"'==`"`qxname_`qj''"' {
                            local qi `qj'
                            continue, break
                        }
                    }
                    local ss ""
                    if `qi'>0 local ss `"`qxsec_`qi''"'
                    if `"`ss'"'!="" & strpos(`"|`secs'|"', `"|`ss'|"')==0 local secs `"`secs'|`ss'"'
                }
            }
            quietly replace selferased = `selfr' in `r'
            local nsc = length(`"`secs'"') - length(subinstr(`"`secs'"', "|", "", .))
            if `nsc'>0 quietly replace nsecs = `nsc' in `r'
        }
        * Case severity is based on the FINAL export when data() is supplied.
        * Blank-but-disabled questions are resolved, not action items. Without
        * data(), retain the conservative paradata-only fallback.
        quietly egen long __ckint = total(n_final_check), by(interview__id)
        quietly gen str1 tier = "C"
        quietly gen strL why = "Resolved - historical removal only"

        quietly replace why = "Resolved - final export is consistent with final questionnaire logic" ///
            if final_data_checked & n_final_check==0
        quietly replace tier = "V" if final_data_checked & n_final_check>0
        quietly replace why = "Check final data - " + strofreal(n_answered_disabled) + ///
            " answered while disabled; " + strofreal(n_blank_enabled) + ///
            " blank while enabled; " + strofreal(n_logic_unknown) + ///
            " logic unknown; " + strofreal(n_notindata) + " not in supplied data; " + ///
            strofreal(n_identityunknown) + " question identity unavailable" ///
            if final_data_checked & n_final_check>0

        quietly replace why = "Resolved - all affected questions were answered again" ///
            if !final_data_checked & nopen==0 & nunknown==0
        quietly replace tier = "V" if !final_data_checked & (nopen>0 | nunknown>0)
        quietly replace why = "Check final data - " + strofreal(nopen) + ///
            " question-history unit(s) still end in AnswerRemoved; " + strofreal(nunknown) + ///
            " have unknown paradata state" if !final_data_checked & tier=="V"

        * Priority is allowed only when unresolved final-data checks remain.
        quietly replace tier = "A" if tier=="V" & __ckint>=3
        quietly replace why = "Priority check - three or more unresolved question-history units in this interview" ///
            if tier=="A"
        capture quietly drop __ckint
        quietly save `"`skdet'"', replace
        if `"`detail'"'!="" quietly copy `"`skdet'"' `"`detail'"', replace
        * Findings roll-up. Keep names and interview lists in variables rather
        * than embedding enumerator names in local-macro names (names may contain
        * spaces or punctuation).
        tempvar rg itag rtag reviewer rids rq ri vtag
        quietly gen str120 `reviewer' = substr(cond(actor!="",actor,resp),1,120)
        quietly egen long `rg' = group(`reviewer') if tier=="A" & `reviewer'!=""
        quietly bysort `rg' interview__id: gen byte `itag' = (_n==1) if !missing(`rg')
        quietly sort `rg' interview__id sk_run
        quietly gen strL `rids' = ""
        quietly by `rg': replace `rids' = ///
            cond(_n==1, cond(`itag'==1,substr(interview__id,1,8),""), ///
            cond(`itag'==1, strtrim(`rids'[_n-1] + " " + substr(interview__id,1,8)), `rids'[_n-1])) ///
            if !missing(`rg')
        quietly egen long `rq' = total(cond(tier=="A",nqrem,0)), by(`rg')
        quietly egen long `ri' = total(cond(tier=="A",`itag',0)), by(`rg')
        quietly by `rg': gen byte `rtag' = (_n==_N) if !missing(`rg')
        quietly count if `rtag'==1
        local ninv = r(N)

        quietly sort interview__id sk_run
        quietly by interview__id: gen byte `vtag' = tier=="V" & sum(tier=="V")==1
        quietly count if `vtag'==1
        local nver = r(N)
        quietly count if tier=="C"
        local nclr = r(N)
        local clrline ""
        foreach w in "Resolved - final export is consistent with final questionnaire logic" ///
            "Resolved - all affected questions were answered again" ///
            "Resolved - historical removal only" {
            quietly count if tier=="C" & why=="`w'"
            if r(N)>0 local clrline "`clrline'`=cond("`clrline'"=="","",", ")'`w' x`r(N)'"
        }
        gsort -nqrem -nrem interview__id sk_run
        quietly gen strL m_head = "HISTORY " + strofreal(_n) + " of `nhist'.  Interview " ///
            + interview__id + ".  Enumerator: " + cond(actor!="", actor, resp)          ///
            + cond(missing(ts0), ".  Removal-run time unavailable.",         ///
            ".  Removal run on " + string(ts0/86400000, "%tdDD_Mon_CCYY") + " at " + ///
            string(ts0, "%tcHH:MM") + " UTC.")
        quietly gen strL m_event = "HISTORICAL ANSWER EVENT: " + transition_text
        quietly gen strL m_finalevent = cond(trigger_final_text!="", ///
            "CURRENT FINAL VALUE: " + trigger_final_text, "")
        quietly gen strL m_rel = "RELATIONSHIP: no questionnaire relationship was established."
        quietly replace m_rel = "RELATIONSHIP: " + strofreal(nlinked_direct) + ///
            " affected question/roster instance(s) directly reference [" + trigger + ///
            "] in their enabling conditions. This is a questionnaire relationship, not proof of cause." ///
            if reltype==1 & linkmode==1
        quietly replace m_rel = "RELATIONSHIP: " + strofreal(nlinked_indirect) + ///
            " affected question/roster instance(s) depend indirectly on [" + trigger + ///
            "] through one or more calculated variables. This is a questionnaire relationship, not proof of cause." ///
            if reltype==1 & linkmode==2
        quietly replace m_rel = "RELATIONSHIP: " + strofreal(nlinked_direct) + ///
            " affected instance(s) reference [" + trigger + "] directly and " + ///
            strofreal(nlinked_indirect) + " depend on it through calculated variables. " + ///
            "This is a questionnaire relationship, not proof of cause." if reltype==1 & linkmode==3
        quietly replace m_rel = "RELATIONSHIP: affected questionnaire questions have enabling conditions, but none references [" + ///
            trigger + "]; it is the nearest AnswerSet only." if reltype==2
        quietly replace m_rel = "RELATIONSHIP: no bounded nearby AnswerSet was identified; this history remains in the exhaustive removal inventory." ///
            if trigger==""
        quietly replace m_rel = "RELATIONSHIP: affected items are ordinary questionnaire questions with no effective enabling condition. They are not service fields; [" + ///
            trigger + "] is the nearest AnswerSet only." if reltype==3
        quietly replace m_rel = "RELATIONSHIP: affected field names were not found in the parsed questionnaire metadata; [" + ///
            trigger + "] is timing context only." if reltype==4
        quietly replace m_rel = "RELATIONSHIP: affected items mix questionnaire questions and fields absent from questionnaire metadata; no causal link was established." if reltype==5
        quietly replace m_rel = "RELATIONSHIP: questionnaire metadata was not supplied, so the relationship could not be assessed; the nearby AnswerSet is timing context only." if reltype==6

        quietly gen strL m_what = "REMOVAL HISTORY: " + strofreal(nrem) + ///
            " AnswerRemoved event(s) affected " + strofreal(nqrem) + ///
            " distinct question/roster instance(s)."
        quietly replace m_what = m_what + cond(compact,                       ///
            " It meets the compact-priority rule.",                          ///
            cond(timing_unknown, " Compact-pattern timing could not be classified.", ///
            " It is outside the compact-priority rule."))
        quietly gen strL m_state = "CURRENT PARADATA STATE: " + strofreal(nreanswered) + ///
            " answered again; " + strofreal(nopen) + " still end in AnswerRemoved; " + ///
            strofreal(nunknown) + " have unknown state."
        quietly replace m_state = "FINAL DATA ASSESSMENT: " + strofreal(n_final_answered) + ///
            " answered; " + strofreal(n_expected_blank) + ///
            " blank as expected because final logic disables them; " + ///
            strofreal(n_answered_disabled) + " answered while disabled; " + ///
            strofreal(n_blank_enabled) + " blank while enabled; " + ///
            strofreal(n_logic_unknown) + " with logic unknown; " + ///
            strofreal(n_notindata) + " not found in supplied data; " +        ///
            strofreal(n_identityunknown) + " question identity unavailable." ///
            if final_data_checked

        quietly gen strL m_q = ""
        quietly gen strL m_s = ""
        quietly gen strL m_e = ""
        if `hasqxt' {
            quietly replace m_q = "ANSWER-EVENT QUESTION [" + trigger + "]: " + char(34) ///
                + substr(qx_text,1,160) + char(34) if qx_text!=""
            quietly replace m_s = "SECTION: " + substr(qx_section,1,60) if qx_section!=""
            quietly replace m_e = "This answer-event question is asked only when: " + ///
                substr(qx_enable,1,120) if qx_enable!=""
        }
        quietly gen strL m_w = "ALL AFFECTED ITEMS: " + wl if wl!=""
        quietly gen strL m_res = "ANSWERED AGAIN: " + wl_reanswered if wl_reanswered!=""
        quietly gen strL m_open = "CHECK IN FINAL DATA: " + wl_final_check if wl_final_check!=""
        quietly gen strL m_expected = "BLANK AS EXPECTED (DISABLED): " + ///
            wl_expected_blank if wl_expected_blank!=""
        quietly gen strL m_finalanswered = "ANSWERED IN FINAL DATA: " + ///
            wl_final_answered if wl_final_answered!=""

        quietly gen strL m_a = "NO ACTION NEEDED: final values are either present or correctly blank under the final questionnaire logic." ///
            if tier=="C" & final_data_checked
        quietly replace m_a = "NO ACTION NEEDED: keep this as interview history only." ///
            if tier=="C" & !final_data_checked
        quietly replace m_a = "NEXT STEP: review only these unresolved items in the final export: " + ///
            wl_final_check + ". Reject only when a value is blank AND the effective final logic evaluates to enabled." ///
            if tier=="V"
        quietly replace m_a = "PRIORITY CHECK: review these unresolved items and the exact history: " + ///
            wl_final_check + "." if tier=="A"
        local k = min(`top', _N)
        local mh 0
        if `"`messages'"'!="" {
            if "`replace'"=="" {
                capture confirm new file `"`messages'"'
                if _rc {
                    di as err "suso: messages() file already exists. Use -replace-."
                    exit 602
                }
            }
            tempname mf
            quietly file open `mf' using `"`messages'"', write replace text
            local mh 1
            file write `mf' "PARADATA SKIP/REMOVAL REVIEW" _n
            file write `mf' "Generated `c(current_date)' `c(current_time)' by suso paradata skips (suso v1.7.26)" _n
            file write `mf' "Definition: every consecutive same-actor AnswerRemoved history is inventoried; cascade(`cascade')/window(`window') marks the compact-priority subset." _n
            file write `mf' "`nhist' histories and `nremevents' raw role-scoped event(s); `ncasc' compact histories / `nwiped' compact events; `noutsideevents' outside-pattern events; `naffectedqall' question-history units." _n
            file write `mf' "Loaded all-role raw total: `nraw_allroles_global'; current role-scope raw total: `nraw_role_global'." _n
            if `hasfinaldata' file write `mf' "Final export assessment: `nfinalansweredall' answered; `nanswereddisabledall' answered while disabled; `nexpectedblankall' blank as expected because disabled; `nfinalcheckall' require review." _n
            else file write `mf' "No data() supplied; `nopenall' still end in AnswerRemoved and `nunknownall' have unknown paradata state." _n
            file write `mf' _n "BOTTOM LINE: `=`ninv'+`nver'' finding(s) need attention - `nclr' cases are resolved and require no action." _n
            forvalues r = 1/`=_N' {
                if `rtag'[`r']!=1 continue
                file write `mf' _n "INVESTIGATE " (`reviewer'[`r']) ": " (strofreal(`ri'[`r'])) " interview(s) with priority unresolved histories, " (strofreal(`rq'[`r'])) " question-history units affected." _n
                file write `mf' "  interviews: " (`rids'[`r']) _n
                file write `mf' "  do: open each in Headquarters and review the exact answer transition, unresolved variables, and final export." _n
            }
            forvalues r = 1/`=_N' {
                if `vtag'[`r']!=1 continue
                file write `mf' _n "VERIFY " (substr(interview__id[`r'],1,8)) " (" (cond(resp[`r']!="",resp[`r'],actor[`r'])) "): " (why[`r']) "." _n
            }
            if `nclr'>0 file write `mf' _n "Auto-cleared as routine: `clrline'." _n
            file write `mf' _n "Case-by-case detail below is for reference only." _n
        }
        di as txt _n "  {hline 70}"
        di as res "  BOTTOM LINE: `=`ninv'+`nver'' finding(s) need attention — `nclr' of `nhist' histories are resolved (no action)."
        di as txt "  {hline 70}"
        forvalues r = 1/`=_N' {
            if `rtag'[`r']!=1 continue
            di as res "  INVESTIGATE  " (`reviewer'[`r']) as txt ": " (`ri'[`r']) " interview(s), " (`rq'[`r']) " unresolved questions."
            di as txt "               ids: " (`rids'[`r'])
            di as txt "               do: review the exact answer transition, unresolved variables, and final export."
        }
        forvalues r = 1/`=_N' {
            if `vtag'[`r']!=1 continue
            di as res "  VERIFY       " (substr(interview__id[`r'],1,8)) as txt "  " ///
                (cond(resp[`r']!="",resp[`r'],actor[`r'])) " — " (why[`r'])
        }
        if `nclr'>0 di as txt "  cleared      `clrline'"
        if !`hasqxt' di as txt "  tip: add qx(questionnaire.html) for question wording and stronger triage."
        if "`full'"=="" {
            di as txt "  (add the {bf:full} option for the complete case-by-case list)"
            local k 0
        }
        forvalues i = 1/`k' {
            di as txt ""
            di as res "  " m_head[`i']
            di as txt "  " m_event[`i']
            if m_finalevent[`i']!="" di as txt "  " m_finalevent[`i']
            di as txt "  " m_rel[`i']
            di as txt "  " m_what[`i']
            if `mh' {
                file write `mf' _n "----------------------------------------------------------------------" _n
                file write `mf' (m_head[`i']) _n
                file write `mf' (m_event[`i']) _n
                if m_finalevent[`i']!="" file write `mf' (m_finalevent[`i']) _n
                file write `mf' (m_rel[`i']) _n
                file write `mf' (m_what[`i']) _n
            }
            foreach mv in m_state m_a m_q m_s m_e m_w m_res m_finalanswered m_expected m_open {
                if `mv'[`i']!="" {
                    di as txt "  " `mv'[`i']
                    if `mh' file write `mf' (`mv'[`i']) _n
                }
            }
        }
        if `mh' {
            file write `mf' _n "----------------------------------------------------------------------" _n
            file write `mf' "General note: a historical removal run is not itself a problem. Review unresolved final states first; repeated questionnaire-linked patterns are secondary context." _n
            file close `mf'
            di as txt _n "  vendor/supervisor message file written: " as res `"`messages'"'
        }

        * ---- shareable Skip/Removal Review page (self-contained, printable) --------
        if `"`html'"'!="" {
            if "`replace'"=="" {
                capture confirm new file `"`html'"'
                if _rc {
                    di as err "suso: html() file already exists. Use -replace-."
                    exit 602
                }
            }
            tempfile DET1 DET2
            quietly save `"`DET1'"'
            * Exact old/new transition is already stored in DET1.
            quietly use `"`DET1'"', clear
            if `haskey' quietly merge m:1 interview__id using `"`SKKEY'"', keep(master match) nogenerate
            capture confirm variable ikey
            if _rc quietly gen ikey = ""
            if `hasassignment' quietly merge m:1 interview__id using `"`SKHQ'"', keep(master match) nogenerate
            capture confirm variable hq_assignment, exact
            if _rc quietly gen str40 hq_assignment = ""
            quietly replace hq_assignment = "" if missing(hq_assignment)
            gsort -nqrem -nrem interview__id sk_run
            * pre-built display columns: data reaches the file only via (exp)
            quietly gen str120 h_ac = substr(cond(actor!="", actor,             ///
                "Unknown removal actor"),1,120)
            quietly gen strL h_iid = interview__id
            quietly gen strL h_tg = trigger
            quietly gen strL h_tv0 = trigval
            quietly gen strL h_qt = ""
            quietly gen strL h_sc = ""
            quietly gen strL h_en = ""
            if `hasqxt' {
                quietly replace h_qt = substr(qx_text,1,300)
                quietly replace h_sc = substr(qx_section,1,80)
                quietly replace h_en = substr(qx_enable,1,200)
            }
            quietly gen strL h_wl = substr(wlc,1,600)
            quietly gen strL h_event = transition_text
            quietly gen str40 h_eventstatus = transition_status
            quietly gen strL h_finalevent = trigger_final_text
            quietly gen strL h_check = wl_final_check
            quietly gen strL h_key = ikey
            quietly gen strL h_ws = ws
            quietly gen str100 h_gkey = cond(reltype==1, ///
                cond(linkmode==2,"indirect:",cond(linkmode==3,"mixedlink:","direct:")) + trigger, ///
                cond(reltype==3, "always", cond(reltype==4, "external", ///
                cond(reltype==5, "mixed", cond(reltype==6, "noqx", "unlinked")))))
            quietly gen str244 h_group = cond(reltype==1, ///
                cond(linkmode==2,"Indirect questionnaire relationship: ", ///
                cond(linkmode==3,"Direct and indirect questionnaire relationship: ", ///
                "Direct questionnaire relationship: ")) + ///
                cond(trigger!="",trigger,"(unknown)"), ///
                cond(reltype==3, "Questionnaire questions with no item-level condition shown", ///
                cond(reltype==4, "Fields outside questionnaire metadata", ///
                cond(reltype==5, "Mixed questionnaire/external fields", ///
                cond(reltype==6, "Questionnaire metadata not supplied", "Cause not identified")))))
            * Structured client-side filtering uses the actual removal-run actor.
            * Never fall back to resp (the primary/last interview owner), because a
            * later correction actor must not inherit somebody else's removal run.
            quietly gen str244 js_actor_key = actor_key
            quietly replace js_actor_key = ustrlower(strtrim(actor)) if          ///
                js_actor_key=="" & actor!=""
            quietly replace js_actor_key = "__unknown_removal_actor__" if       ///
                js_actor_key==""
            quietly gen str244 js_actor = cond(actor!="",actor,                 ///
                "Unknown removal actor")
            quietly gen str244 js_group = h_group
            quietly gen strL h_iid_url = ""
            quietly gen strL h_assignment_url = ""
            mata: suso_urlencode_var("h_iid", "h_iid_url")
            mata: suso_urlencode_var("hq_assignment", "h_assignment_url")
            foreach v in h_ac h_iid h_tg h_tv0 h_qt h_sc h_en h_wl h_event ///
                h_eventstatus h_finalevent h_check h_key h_ws h_group hq_assignment ///
                wl_final_answered wl_answered_disabled wl_expected_blank {
                quietly replace `v' = subinstr(subinstr(subinstr(`v',"&","&amp;",.),"<","&lt;",.),">","&gt;",.)
                quietly replace `v' = subinstr(subinstr(`v',char(34),"&#34;",.),char(39),"&#39;",.)
            }

            quietly gen strL h_links = ""
            if `"`hqbase'"'!="" {
                tempvar hqb
                quietly gen strL `hqb' = `"`hqbaseh'"'
                quietly replace h_links = "<span class=" + char(34) + "hqlinks" + char(34) + ">" + ///
                    "<a class=" + char(34) + "hqlink" + char(34) + " target=" + char(34) + "_blank" + char(34) + ///
                    " rel=" + char(34) + "noopener noreferrer" + char(34) + " href=" + char(34) + ///
                    `hqb' + "/Interview/Review/" + h_iid_url + char(34) + ">Open interview</a>" + ///
                    cond(hq_assignment!="", "<a class=" + char(34) + "hqlink secondary" + char(34) + ///
                    " target=" + char(34) + "_blank" + char(34) + " rel=" + char(34) + "noopener noreferrer" + char(34) + ///
                    " href=" + char(34) + `hqb' + "/Assignments/" + h_assignment_url + char(34) + ">Open assignment</a>", "") + ///
                    "</span>"
            }

            quietly gen str12 h_class = cond(tier=="A","priority", ///
                cond(tier=="V","verify","resolved"))
            quietly gen strL h_open = "<div class=" + char(34) + "case " + ///
                h_class + char(34) + ">"
            quietly gen strL h_chip = "<div class=" + char(34) + "chip " + ///
                h_class + char(34) + ">Resolved - no action</div>" if tier=="C"
            quietly replace h_chip = "<div class=" + char(34) + "chip " + ///
                h_class + char(34) + ">Check final data - " + ///
                strofreal(cond(final_data_checked,n_final_check,nopen+nunknown)) + ///
                " question-history unit(s)</div>" if tier=="V"
            quietly replace h_chip = "<div class=" + char(34) + "chip " + ///
                h_class + char(34) + ">Priority check - " + ///
                strofreal(cond(final_data_checked,n_final_check,nopen+nunknown)) + ///
                " question-history unit(s)</div>" if tier=="A"

            quietly gen strL h_l1 = "<div class=" + char(34) + "c1" + char(34) + ">" ///
                + cond(h_key!="", "<b class=" + char(34) + "mono" + char(34) + ">" + h_key + "</b> &nbsp;&middot;&nbsp; <span class=" + char(34) + "mono small" + char(34) + ">" + h_iid + "</span>", ///
                       "<span class=" + char(34) + "mono" + char(34) + ">" + h_iid + "</span>") ///
                + " &nbsp;&middot;&nbsp; <b>" + h_ac + "</b> &nbsp;&middot;&nbsp; " ///
                + cond(missing(ts0),"time unavailable",string(ts0/86400000, "%tdDD_Mon_CCYY") + " " + string(ts0, "%tcHH:MM") + " UTC") + ///
                cond(h_ws!=""," &nbsp;&middot;&nbsp; " + h_ws,"") + h_links + "</div>"

            quietly gen strL h_eventbox = "<div class=" + char(34) + "eventbox" + char(34) + "><div class=" + char(34) + "eventstatus" + char(34) + ">" + h_eventstatus + "</div><b>Historical answer event:</b> " + h_event
            quietly replace h_eventbox = h_eventbox + "<div class=" + char(34) + "eventquestion" + char(34) + "><b>Question:</b> &quot;" + h_qt + "&quot;</div>" if h_qt!=""
            quietly replace h_eventbox = h_eventbox + "</div>"
            quietly gen strL h_finalbox = ""
            quietly replace h_finalbox = "<div class=" + char(34) + "finalbox" + char(34) + "><b>Current final export:</b> " + h_finalevent + "</div>" if h_finalevent!=""
            quietly gen strL h_rel = "<div class=" + char(34) + "relbox" + char(34) + "><b>No questionnaire relationship found:</b> the answer event is shown only because it was nearest in the event sequence.</div>"
            quietly replace h_rel = "<div class=" + char(34) + "relbox linked" + char(34) + "><b>Direct questionnaire relationship:</b> " + strofreal(nlinked_direct) + " affected question/roster instance(s) directly reference <span class=" + char(34) + "mono" + char(34) + ">" + h_tg + "</span> in their enabling conditions. This does not prove cause by itself.</div>" if reltype==1 & linkmode==1
            quietly replace h_rel = "<div class=" + char(34) + "relbox linked" + char(34) + "><b>Indirect questionnaire relationship:</b> " + strofreal(nlinked_indirect) + " affected question/roster instance(s) depend on <span class=" + char(34) + "mono" + char(34) + ">" + h_tg + "</span> through calculated variables. This does not prove cause by itself.</div>" if reltype==1 & linkmode==2
            quietly replace h_rel = "<div class=" + char(34) + "relbox linked" + char(34) + "><b>Direct and indirect questionnaire relationship:</b> " + strofreal(nlinked_direct) + " affected instance(s) reference <span class=" + char(34) + "mono" + char(34) + ">" + h_tg + "</span> directly and " + strofreal(nlinked_indirect) + " depend on it through calculated variables. This does not prove cause by itself.</div>" if reltype==1 & linkmode==3
            quietly replace h_rel = "<div class=" + char(34) + "relbox" + char(34) + "><b>No questionnaire relationship found:</b> affected questions have enabling conditions, but none references <span class=" + char(34) + "mono" + char(34) + ">" + h_tg + "</span>.</div>" if reltype==2
            quietly replace h_rel = "<div class=" + char(34) + "relbox" + char(34) + "><b>Questionnaire questions with no effective enabling condition:</b> these are ordinary questionnaire variables, not service fields. <span class=" + char(34) + "mono" + char(34) + ">" + h_tg + "</span> is the nearest AnswerSet only.</div>" if reltype==3
            quietly replace h_rel = "<div class=" + char(34) + "relbox" + char(34) + "><b>Fields outside questionnaire metadata:</b> none of the affected names was found in the parsed questionnaire. The nearby AnswerSet is timing context only.</div>" if reltype==4
            quietly replace h_rel = "<div class=" + char(34) + "relbox" + char(34) + "><b>Mixed field types:</b> affected items include questionnaire questions and fields absent from questionnaire metadata. No causal link was established.</div>" if reltype==5
            quietly replace h_rel = "<div class=" + char(34) + "relbox" + char(34) + "><b>Questionnaire relationship not assessed:</b> no questionnaire metadata was supplied. The nearby AnswerSet is timing context only.</div>" if reltype==6
            quietly replace h_rel = "<div class=" + char(34) + "relbox" + char(34) + "><b>No bounded nearby AnswerSet:</b> this history remains in the exhaustive inventory, but no answer-event relationship is asserted.</div>" if h_tg==""

            quietly gen strL h_l2 = "<div class=" + char(34) + "c2" + char(34) + "><b>Removal history:</b> " + strofreal(nrem) + " AnswerRemoved event(s) affected <b>" + strofreal(nqrem) + "</b> distinct question/roster unit(s). <b>Pattern:</b> " + cond(compact,"compact priority",cond(timing_unknown,"timing unknown","outside compact rule")) + ".</div>"
            quietly gen strL h_state = "<div class=" + char(34) + "state resolved" + char(34) + "><b>Final data assessment:</b> " + strofreal(n_final_answered) + " answered; " + strofreal(n_expected_blank) + " blank as expected because disabled; 0 require review.</div>" if tier=="C" & final_data_checked
            quietly replace h_state = "<div class=" + char(34) + "state resolved" + char(34) + "><b>Current paradata state:</b> all affected items were answered again.</div>" if tier=="C" & !final_data_checked
            quietly replace h_state = "<div class=" + char(34) + "state verify" + char(34) + "><b>Final data assessment:</b> " + strofreal(n_final_answered) + " answered; " + strofreal(n_expected_blank) + " blank as expected because disabled; " + strofreal(n_answered_disabled) + " answered while disabled; " + strofreal(n_blank_enabled) + " blank while enabled; " + strofreal(n_logic_unknown) + " logic unknown; " + strofreal(n_notindata) + " not in supplied data.</div>" if tier=="V"
            quietly replace h_state = "<div class=" + char(34) + "state priority" + char(34) + "><b>Final data assessment:</b> " + strofreal(n_final_answered) + " answered; " + strofreal(n_expected_blank) + " blank as expected because disabled; " + strofreal(n_final_check) + " require review.</div>" if tier=="A"
            quietly replace h_state = subinstr(h_state,".</div>","; " + strofreal(n_identityunknown) + " question identity unavailable.</div>",1) if n_identityunknown>0

            quietly gen strL h_do = "<div class=" + char(34) + "action resolved" + char(34) + "><b>No action needed.</b> Final values are present or correctly blank under the final questionnaire logic.</div>" if tier=="C" & final_data_checked
            quietly replace h_do = "<div class=" + char(34) + "action resolved" + char(34) + "><b>No action needed.</b> Keep this only as interview history.</div>" if tier=="C" & !final_data_checked
            quietly replace h_do = "<div class=" + char(34) + "action verify" + char(34) + "><b>Review only:</b> <span class=" + char(34) + "mono" + char(34) + ">" + h_check + "</span>. A blank value is actionable only when effective final logic says enabled.</div>" if tier=="V"
            quietly replace h_do = "<div class=" + char(34) + "action priority" + char(34) + "><b>Priority review:</b> <span class=" + char(34) + "mono" + char(34) + ">" + h_check + "</span>. Also inspect the exact interview history.</div>" if tier=="A"

            quietly gen strL h_l3 = ""
            quietly replace h_l3 = "<blockquote><b>Answer-event question:</b> <span class=" + char(34) + "mono" + char(34) + ">" + h_tg + "</span>" + cond(h_qt!=""," &nbsp; &quot;" + h_qt + "&quot;","") + "</blockquote>" if h_tg!=""
            quietly gen strL h_l4 = ""
            quietly replace h_l4 = "Section: " + h_sc if h_sc!=""
            quietly replace h_l4 = h_l4 + cond(h_l4!="", " &nbsp;&middot;&nbsp; ", "") + "Asked only when: <span class=" + char(34) + "mono" + char(34) + ">" + h_en + "</span>" if h_en!=""
            quietly replace h_l4 = "<div class=" + char(34) + "meta" + char(34) + ">" + h_l4 + "</div>" if h_l4!=""
            quietly gen strL h_l5 = "<div class=" + char(34) + "meta" + char(34) + ">All affected items: <span class=" + char(34) + "mono" + char(34) + ">" + h_wl + cond(length(wlc)>600, " ...", "") + "</span></div>" if h_wl!=""
            quietly gen strL h_fa = "<div class=" + char(34) + "meta linked" + char(34) + ">Answered in final data: <span class=" + char(34) + "mono" + char(34) + ">" + wl_final_answered + "</span></div>" if wl_final_answered!=""
            quietly gen strL h_ad = "<div class=" + char(34) + "meta caution" + char(34) + ">Answered although disabled: <span class=" + char(34) + "mono" + char(34) + ">" + wl_answered_disabled + "</span></div>" if wl_answered_disabled!=""
            quietly gen strL h_eb = "<div class=" + char(34) + "meta linked" + char(34) + ">Blank as expected because disabled: <span class=" + char(34) + "mono" + char(34) + ">" + wl_expected_blank + "</span></div>" if wl_expected_blank!=""
            quietly gen strL h_l6 = "<div class=" + char(34) + "meta" + char(34) + ">AnswerSet order: " + string(trigger_ord,"%12.0g") + "; removal-run start: " + string(ts0,"%tcCCYY-NN-DD_HH:MM:SS") + "; raw removal events: " + strofreal(nrem) + ".</div>"
            quietly gen strL h_tech = "<details class=" + char(34) + "tech" + char(34) + "><summary>Technical details</summary>" + h_l3 + h_l4 + h_l5 + h_fa + h_ad + h_eb + h_l6 + "</details>"
            quietly gen strL h_card = h_open + h_chip + h_l1 + h_eventbox +     ///
                h_finalbox + h_rel + h_l2 + h_state + h_do + h_tech + "</div>"

            * JSON-escape in Mata directly from variables.  This avoids routing
            * questionnaire text, actor names, or answer values through Stata
            * macro expansion and neutralizes </script>-style payloads.
            foreach __jv in actor_key actor group group_key iid ws wc card {
                quietly gen strL j_`__jv' = ""
            }
            quietly replace j_actor_key = js_actor_key
            quietly replace j_actor = js_actor
            quietly replace j_group = js_group
            quietly replace j_group_key = h_gkey
            quietly replace j_iid = interview__id
            quietly replace j_ws = ws
            quietly replace j_wc = ws_class
            quietly replace j_card = h_card
            foreach __jv in actor_key actor group group_key iid ws wc card {
                mata: suso_jsonesc_var("j_`__jv'", "j_`__jv'")
            }
            quietly gen strL j_obj = "{" + char(34) + "ak" + char(34) +       ///
                ":" + char(34) + j_actor_key + char(34) + "," + char(34) +   ///
                "an" + char(34) + ":" + char(34) + j_actor + char(34) +      ///
                "," + char(34) + "gk" + char(34) + ":" + char(34) +          ///
                j_group_key + char(34) + "," + char(34) + "gl" + char(34) +  ///
                ":" + char(34) + j_group + char(34) + "," + char(34) +       ///
                "id" + char(34) + ":" + char(34) + j_iid + char(34) +        ///
                "," + char(34) + "ws" + char(34) + ":" + char(34) + j_ws + char(34) + ///
                "," + char(34) + "wc" + char(34) + ":" + char(34) + j_wc + char(34) + ///
                "," + char(34) + "t" + char(34) + ":" + char(34) + tier +   ///
                char(34) + "," + char(34) + "q" + char(34) + ":" +          ///
                strofreal(nqrem) + "," + char(34) + "need" + char(34) + ":" + ///
                strofreal(n_final_check) + "," + char(34) + "re" + char(34) + ///
                ":" + strofreal(nreanswered) + "," + char(34) + "ev" +      ///
                char(34) + ":" + strofreal(nrem) + "," + char(34) +          ///
                "cp" + char(34) + ":" + strofreal(compact) + "," + char(34) + ///
                "tu" + char(34) + ":" + strofreal(timing_unknown) + "," + char(34) + ///
                "cev" + char(34) + ":" + strofreal(nrem*compact) + "," + char(34) + ///
                "out" + char(34) + ":" + strofreal(nrem*(1-compact)) + "," + char(34) + ///
                "card" + char(34) + ":" + char(34) + j_card + char(34) + "}"
            local ncheckall = `nfinalcheckall'
            local now = trim("`c(current_date)' `c(current_time)'")
            local wst ""
            if "$SUSO_WS"!="" {
                _suso_para_hesc `"$SUSO_WS"'
                local wst " — `r(out)'"
            }
            tempname hf
            quietly file open `hf' using `"`html'"', write replace text
            file write `hf' `"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Skip Removal Review</title><style>"' _n
            file write `hf' `"body{margin:0;font-family:Segoe UI,Arial,sans-serif;background:#f4f5f7;color:#1a1a1a}"' _n
            file write `hf' `".logobar{background:#fff;padding:10px 28px;border-bottom:1px solid #e0e0e0}"' _n
            file write `hf' `".logobar .wbtxt{font-size:13px;letter-spacing:.06em;color:#002244;font-weight:600}.logobar .wbtxt span{color:#8a8a8a;font-weight:400}"' _n
            file write `hf' `".mast{background:#002244;color:#fff;padding:18px 28px}.mast h1{margin:0;font-size:21px;font-weight:600}.mast .sub{color:#c9d4e0;font-size:12.5px;margin-top:5px}"' _n
            file write `hf' `".wrap{max-width:900px;margin:0 auto;padding:16px 28px 40px}"' _n
            file write `hf' `".cards{display:flex;flex-wrap:wrap;gap:10px;margin:12px 0}"' _n
            file write `hf' `".card{flex:1 1 140px;background:#fff;border:1px solid #e3e6ea;border-radius:8px;padding:10px 13px;border-top:3px solid #002244}"' _n
            file write `hf' `".card.warn{border-top-color:#c48a00}.card.dim{border-top-color:#9aa7b5}"' _n
            file write `hf' `".card .v{font-size:20px;font-weight:700;color:#002244}.card .k{font-size:11px;color:#666;margin-top:2px;text-transform:uppercase;letter-spacing:.04em}"' _n
            file write `hf' `".filterbar{display:flex;align-items:end;gap:12px;background:#fff;border:1px solid #e3e6ea;border-radius:8px;padding:10px 14px;margin:0 0 12px}.filterbar label{display:block;font-size:10.5px;text-transform:uppercase;letter-spacing:.04em;color:#666;margin-bottom:4px}.filterbar select{min-width:260px;max-width:100%;padding:7px 9px;border:1px solid #bfc8d2;border-radius:5px;background:#fff;color:#1a1a1a}.scope{font-size:11.5px;color:#666;padding-bottom:7px}.empty{font-size:12.5px;color:#666;background:#fff;border:1px solid #e3e6ea;border-radius:6px;padding:10px 12px;margin:8px 0}"' _n
            file write `hf' `".how{background:#fdf6e3;border:1px solid #ecd9a0;border-radius:8px;padding:12px 16px;font-size:13px;line-height:1.55;margin:12px 0}"' _n
            file write `hf' `"h2{font-size:15px;color:#002244;border-bottom:2px solid #C9A227;padding-bottom:4px;margin:22px 0 8px}"' _n
            file write `hf' `"table{border-collapse:collapse;width:100%;font-size:12.5px;background:#fff}"' _n
            file write `hf' `"th{background:#002244;color:#fff;text-align:left;padding:6px 8px;font-weight:600}td{padding:5px 8px;border-bottom:1px solid #eef0f2}td.r,th.r{text-align:right}"' _n
            file write `hf' `".case{background:#fff;border:1px solid #e3e6ea;border-left:4px solid #7b8794;border-radius:8px;padding:12px 16px;margin:10px 0;position:relative;page-break-inside:avoid}"' _n
            file write `hf' `".case.resolved{border-left-color:#2f7d4a}.case.verify{border-left-color:#c48a00}.case.priority{border-left-color:#a33}"' _n
            file write `hf' `".chip{position:absolute;top:10px;right:12px;border-radius:12px;font-size:11px;padding:3px 10px;font-weight:700}"' _n
            file write `hf' `".chip.resolved{background:#eaf5ec;color:#1e6b34;border:1px solid #bfe0c8}.chip.verify{background:#fdf6e3;color:#7a5b00;border:1px solid #ecd9a0}.chip.priority{background:#fbeaea;color:#8a1f1f;border:1px solid #e8bcbc}"' _n
            file write `hf' `".c1{font-size:12.5px;color:#444;margin-right:190px}.c2{font-size:13.5px;margin-top:8px;line-height:1.45}"' _n
            file write `hf' `".eventquestion{margin-top:5px;color:#44515f}.eventstatus{display:inline-block;margin:0 7px 4px 0;padding:2px 7px;border-radius:10px;background:#002244;color:#fff;font-size:10.5px;font-weight:700}.eventbox,.relbox,.finalbox{font-size:12.5px;line-height:1.5;border-radius:6px;padding:8px 10px;margin-top:7px;background:#f7f8fa;border:1px solid #e2e6ea}.finalbox{background:#edf5fb;border-color:#bfd4e5;color:#173b5e}.relbox.linked{background:#eef8f0;border-color:#cfe4d3}.state,.action{font-size:12.5px;line-height:1.45;border-radius:6px;padding:7px 10px;margin-top:7px}.state.resolved,.action.resolved{background:#eef7f0;color:#1e6b34}.state.verify,.action.verify{background:#fdf6e3;color:#6f5600}.state.priority,.action.priority{background:#fbeaea;color:#8a1f1f}"' _n
            file write `hf' `"blockquote{margin:8px 0;padding:8px 12px;background:#f7f8fa;border-left:3px solid #c9cfd6;font-size:12.5px;color:#333}"' _n
            file write `hf' `".meta{font-size:11.5px;color:#666;margin-top:4px}.meta.linked{color:#1e6b34}.caution{color:#7a5b00}.mono{font-family:Consolas,monospace}"' _n
            file write `hf' `".hqlinks{display:inline-flex;gap:5px;margin-left:10px;vertical-align:middle}.hqlink{display:inline-block;padding:3px 8px;border-radius:5px;background:#002244;color:#fff;text-decoration:none;font-size:10.5px;font-weight:600}.hqlink.secondary{background:#fff;color:#002244;border:1px solid #9fb0c1}.hqlink:hover{text-decoration:underline}"' _n
            file write `hf' `".small{font-size:10.5px;color:#888}.tech{margin-top:8px}.tech summary{cursor:pointer;color:#556575;font-size:11.5px}.techsum{background:#fff;border:1px solid #e3e6ea;border-radius:8px;padding:8px 12px;margin:12px 0}.techsum>summary{cursor:pointer;color:#556575;font-size:12.5px;font-weight:600}"' _n
            file write `hf' `"details{margin:4px 0}summary.gate{cursor:pointer;font-size:13.5px;color:#002244;padding:8px 10px;background:#f5f7f9;border:1px solid #dce2e8;border-radius:6px;margin-top:14px}"' _n
            file write `hf' `".foot{font-size:11px;color:#777;margin-top:24px;line-height:1.5}"' _n
            file write `hf' `"@media print{body{background:#fff}.case{border:1px solid #bbb;border-left-width:4px}.sbody{display:block!important}.chipnav{position:static}.shead .chev{display:none}}"' _n
            file write `hf' `".chipnav{position:sticky;top:0;z-index:6;background:#f4f5f7;padding:8px 0 6px;margin:0 0 4px;border-bottom:1px solid #e3e6ea;display:flex;gap:6px;flex-wrap:wrap;align-items:center}"' _n
            file write `hf' `".chipx{display:inline-flex;align-items:center;gap:6px;background:#fff;border:1px solid #dfe4e8;border-radius:14px;padding:4px 11px;font-size:12px;color:#33404d;text-decoration:none;cursor:pointer}"' _n
            file write `hf' `".chipx:hover{border-color:#9fb2c4}"' _n
            file write `hf' `".chipx .n{font-weight:700;font-size:11px;padding:0 6px;border-radius:8px;font-variant-numeric:tabular-nums}"' _n
            file write `hf' `".chipx .n.b{background:#fbeaea;color:#8a1f1f}.chipx .n.w{background:#fdf6e3;color:#7a5b00}.chipx .n.g{color:#1e6b34}"' _n
            file write `hf' `".chiputil{margin-left:auto;color:#556575;background:transparent;border:0;font:inherit;font-size:12px;cursor:pointer;padding:4px 8px;border-radius:14px}"' _n
            file write `hf' `".chiputil:hover{background:#fff;box-shadow:inset 0 0 0 1px #dfe4e8}.chiputil+.chiputil{margin-left:0}"' _n
            file write `hf' `".sblock{background:#fff;border:1px solid #e3e6ea;border-radius:8px;margin:10px 0;overflow:hidden}"' _n
            file write `hf' `".sblock.sv-b{border-left:3px solid #a33}.sblock.sv-w{border-left:3px solid #C9A227}.sblock.sv-g{border-left:3px solid #7fbf95}"' _n
            file write `hf' `".shead{display:flex;width:100%;align-items:baseline;gap:10px;padding:11px 16px;background:transparent;border:0;cursor:pointer;text-align:left;font-family:inherit}"' _n
            file write `hf' `".shead h2{margin:0;font-size:15px;color:#002244;font-weight:600;border-bottom:0;padding-bottom:0}"' _n
            file write `hf' `".pillc{font-size:11px;font-weight:700;padding:1px 8px;border-radius:9px;position:relative;top:-1px;font-variant-numeric:tabular-nums}"' _n
            file write `hf' `".pillc.b{background:#fbeaea;color:#8a1f1f}.pillc.w{background:#fdf6e3;color:#7a5b00}.pillc.g{background:#eaf5ec;color:#1e6b34}"' _n
            file write `hf' `".shead .sfind{color:#556575;font-size:12.5px;margin-left:auto;text-align:right;max-width:52%}"' _n
            file write `hf' `".shead .chev{color:#8a97a4;font-size:11px;flex:0 0 auto;transition:transform .15s}"' _n
            file write `hf' `".sblock.open .chev{transform:rotate(90deg)}"' _n
            file write `hf' `".sbody{display:none;padding:2px 16px 14px;border-top:1px solid #eef0f2}"' _n
            file write `hf' `".sblock.open .sbody{display:block}"' _n
            file write `hf' `"@media (prefers-reduced-motion: reduce){.shead .chev{transition:none}}"' _n
            file write `hf' `"</style></head><body>"' _n
            file write `hf' `"<div class="logobar"><!-- wbLogo slot: replace content with the base64 banner img -->"' _n
            file write `hf' `"<span class="wbtxt">THE WORLD BANK <span>| Development Economics - Policy Indicators</span> &nbsp;-&nbsp; ENTERPRISE SURVEYS <span>- What Businesses Experience</span></span></div>"' _n
            file write `hf' `"<div class="mast"><h1>Skip Removal Review`wst'</h1>"' _n
            file write `hf' `"<div class="sub">Generated `now' &nbsp;-&nbsp; every consecutive same-actor AnswerRemoved history is inventoried; cascade(`cascade') and window(`window') classify the compact-priority subset</div></div>"' _n
            file write `hf' `"<div class="wrap">"' _n
            file write `hf' `"<div class="filterbar"><div><label for="sk_actor">Removal-run actor / enumerator</label><select id="sk_actor"></select></div><div><label for="sk_status">Current/final interview status</label><select id="sk_status"></select></div><div class="scope" id="sk_scope"></div></div>"' _n
            file write `hf' `"<div class="cards">"' _n
            file write `hf' `"<div class="card"><div class="v" id="sk_hist">-</div><div class="k">removal histories</div></div>"' _n
            file write `hf' `"<div class="card dim"><div class="v" id="sk_ev">-</div><div class="k">raw AnswerRemoved events</div></div>"' _n
            file write `hf' `"<div class="card"><div class="v" id="sk_compact">-</div><div class="k">compact histories / events</div></div>"' _n
            file write `hf' `"<div class="card dim"><div class="v" id="sk_outside">-</div><div class="k">events outside compact pattern</div></div>"' _n
            file write `hf' `"<div class="card"><div class="v" id="sk_q">-</div><div class="k">question-history units affected</div></div>"' _n
            file write `hf' `"<div class="card warn"><div class="v" id="sk_need">-</div><div class="k">need final-data check</div></div>"' _n
            file write `hf' `"<div class="card"><div class="v" id="sk_re">-</div><div class="k">answered again later</div></div>"' _n
            file write `hf' `"</div>"' _n
            file write `hf' `"<nav class='chipnav' aria-label='Review sections'>"' _n
            file write `hf' `"<a class='chipx' href='#s_ver' data-sec='s_ver'>Verification cases<span class='n' id='cb_ver' style='display:none'></span></a>"' _n
            file write `hf' `"<a class='chipx' href='#s_pat' data-sec='s_pat'>Patterns</a>"' _n
            file write `hf' `"<a class='chipx' href='#s_res' data-sec='s_res'>Resolved<span class='n' id='cb_res' style='display:none'></span></a>"' _n
            file write `hf' `"<button type='button' class='chiputil' id='sk_expall'>Expand all</button>"' _n
            file write `hf' `"<button type='button' class='chiputil' id='sk_collall'>Collapse all</button>"' _n
            file write `hf' `"</nav>"' _n
            file write `hf' `"<div class="how"><b>Coverage:</b> every role-scoped AnswerRemoved event is retained, including singleton and paired histories. <b>Compact priority</b> means at least `cascade' consecutive removals, a fully timed run within `window' seconds, and a bounded nearby AnswerSet. Outside-pattern and timing-unknown histories still receive final-state adjudication. Question identity unavailable is an explicit review category. A questionnaire relationship is context, not proof of cause.</div>"' _n
            quietly save `"`DET2'"'

            file write `hf' `"<div class='sblock' id='s_pat'><button class='shead' type='button' aria-expanded='false'><h2>Technical pattern summary</h2><span class='sfind' id='f_pat'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
            file write `hf' `"<div class="meta">This table covers every filtered inventory history. Compact histories are the threshold/window subset; outside events are retained rather than discarded.</div>"' _n
            file write `hf' `"<table><thead><tr><th>relationship / variable</th><th class="r">all histories</th><th class="r">compact</th><th class="r">interviews</th><th class="r">raw events</th><th class="r">outside events</th></tr></thead><tbody id="sk_patterns"></tbody></table><div id="sk_patterns_empty" class="meta"></div>"' _n
            file write `hf' `"</div></div>"' _n
            file write `hf' `"<div class='sblock' id='s_ver'><button class='shead' type='button' aria-expanded='false'><h2>Cases needing verification</h2><span class='pillc' id='p_ver' style='display:none'></span><span class='sfind' id='f_ver'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
            file write `hf' `"<div class="note">These cases contain an enabled blank, unevaluable logic, a missing variable/roster instance, an answer while disabled, or an identity-unavailable removal. Blank-but-disabled questions are resolved automatically.</div>"' _n
            file write `hf' `"<div id="sk_verify"></div>"' _n
            file write `hf' `"</div></div>"' _n
            file write `hf' `"<div class='sblock' id='s_res'><button class='shead' type='button' aria-expanded='false'><h2>Resolved history - no action</h2><span class='pillc' id='p_res' style='display:none'></span><span class='sfind' id='f_res'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
            file write `hf' `"<details><summary id="sk_resolved_summary" style="cursor:pointer;font-size:13px;color:#555;padding:6px 0"></summary><div id="sk_resolved"></div></details><div id="sk_resolved_more" class="meta"></div>"' _n
            file write `hf' `"</div></div>"' _n
            file write `hf' `"<div class="foot">Produced by suso paradata skips (suso v1.7.26). Exhaustive histories are audit inventory; compact classification is a prioritization signal, not proof of misconduct. Actor ownership is the actor who emitted the AnswerRemoved run. Current/final status uses data() when supplied, otherwise paradata workflow history.</div>"' _n
            file write `hf' `"</div><script>"' _n
            file write `hf' `"var SK={meta:{allRole:`nraw_allroles_global',role:`nraw_role_global',globalHistories:`nhist_global',globalCompact:`ncasc_global',globalCompactEvents:`ncompactevents_global'},cases:["' _n
            quietly use `"`DET2'"', clear
            forvalues i = 1/`=_N' {
                file write `hf' (cond(`i'==1,"",",")) (j_obj[`i']) _n
            }
            file write `hf' `"]};"' _n
            _suso_para_skip_page_js `hf'
            file write `hf' `"</script></body></html>"' _n
            file close `hf'
            di as txt "  shareable review page written: " as res `"`html'"'
            if `"`hqbase'"'!="" {
                di as txt "  Headquarters links: " as res `"`hqbase'"' as txt " (interviews" ///
                    cond(`hasassignment', " + assignments", " only; assignment__id not found") ")"
            }
            else di as txt "  Headquarters links: disabled (configure server/workspace or add hqurl())."
        }
        restore
    }

    * html() is a file-creation contract even when the inventory is empty.
    * Emit a valid zero-state page instead of silently leaving the requested
    * suite tab missing.
    if !`hasdet' & `"`html'"'!="" {
        if "`replace'"=="" {
            capture confirm new file `"`html'"'
            if _rc {
                di as err "suso: html() file already exists. Use -replace-."
                exit 602
            }
        }
        tempname zhf
        quietly file open `zhf' using `"`html'"', write replace text
        file write `zhf' `"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Skip Removal Review</title><style>body{font-family:Segoe UI,Arial,sans-serif;background:#f4f5f7;color:#1a1a1a;margin:0}.mast{background:#002244;color:#fff;padding:20px 28px}.box{max-width:820px;margin:24px auto;background:#fff;border:1px solid #dfe4e8;border-radius:8px;padding:22px}.n{font-size:26px;font-weight:700;color:#002244}</style></head><body>"' _n
        file write `zhf' `"<div class="mast"><h2>Skip Removal Review</h2></div><div class="box"><div class="n">0 removal histories</div><p>No AnswerRemoved events match the current role and vars() scope.</p><p>Loaded raw total across all roles: <b>`nraw_allroles_global'</b>; current role-scope raw total: <b>`nraw_role_global'</b>.</p></div></body></html>"' _n
        file close `zhf'
        di as txt "  shareable review page written (zero inventory): " as res `"`html'"'
    }

    if `"`saving'"'!="" {
        if "`replace'"=="" {
            capture confirm new file `"`saving'"'
            if _rc {
                di as err "suso: file already exists. Use -replace-."
                exit 602
            }
        }
        quietly save `"`saving'"', `replace'
        di as txt "suso paradata: skip table saved to " as res `"`saving'"'
    }

    return scalar nints     = `nints'
    return scalar nhistories = `nhist'
    return scalar nhistories_global = `nhist_global'
    return scalar ncascades = `ncasc'
    return scalar ncascades_global = `ncasc_global'
    return scalar nwiped       = `nwiped'
    return scalar nremovalevents = `nremevents'
    return scalar nremovalevents_global = `nraw_role_global'
    return scalar nremovalevents_allroles = `nraw_allroles_global'
    return scalar ncompactevents = `nwiped'
    return scalar ncompactevents_global = `ncompactevents_global'
    return scalar noutsideevents = `noutsideevents'
    return scalar noutsideevents_global = `nraw_role_global' - `ncompactevents_global'
    return scalar ntimingunknownhistories = `ntimingunknown'
    return scalar ntimingunknownhistories_global = `ntimingunknown_global'
    return scalar ntimingunknownevents = `ntimingunknownevents'
    return scalar ntimingunknownevents_global = `ntimingunknownevents_global'
    return scalar naffectedquestions = `naffectedqall'
    return scalar nidentityunknown = `nidentityunknownall'
    return scalar nreanswered    = `nreansweredall'
    return scalar nopen          = `nopenall'
    return scalar nunknown       = `nunknownall'
    return scalar nfinalanswered = `nfinalansweredall'
    return scalar nanswereddisabled = `nanswereddisabledall'
    return scalar nexpectedblank = `nexpectedblankall'
    return scalar nblankenabled  = `nblankenabledall'
    return scalar nlogicunknown  = `nlogicunknownall'
    return scalar nnotindata     = `nnotindataall'
    return scalar nfinalcheck    = `nfinalcheckall'
    return scalar hasfinaldata   = `hasfinaldata'
    return scalar naffected      = `naff'
    return local hqurl `"`hqbase'"'
end

* ---- report: dynamic self-contained HTML QC report ------------------------------
* All derived QC payloads are embedded as JSON; vanilla JS (no CDN, works
* offline) recomputes every figure and table live.  The optional raw-history
* explorer reads a user-selected local paradata.tab on demand; source events
* are intentionally not embedded.
* ---- report writer: static JavaScript kept outside the main report program -----
* Stata hard-limits each compiled program to 135,600 bytes.  Keeping this static
* browser engine in its own helper preserves ample compiler headroom.
program _suso_para_report_js
    version 14.2
    args fh
    if "`fh'"=="" {
        di as err "suso internal error: report file handle was not supplied."
        exit 198
    }
    file write `fh' `"/* suso paradata report - dynamic engine. Pure compute core in P (node-testable), DOM layer below. */"' _n
    file write `fh' `"var P = {"' _n
    file write `fh' `"  letters: ['S','B','T','N','C','Z','P','O'],"' _n
    file write `fh' `"  names: ['Speeding','Fast streak','Too short','Night work','Churn','Duration outlier','Faster than peers','Shared-minute screen'],"' _n
    file write `fh' `"  presets: {"' _n
    file write `fh' `"    standard:{burst:8,minact:5,n1:22,n2:6,nshare:0.25,churn:0.20,z:3.5,peer:0.35,ov:3,nmin:10},"' _n
    file write `fh' `"    lenient:{fs:1.5,burst:12,minact:3,n1:22,n2:6,nshare:0.35,churn:0.30,z:4,peer:0.25,ov:5,nmin:15},"' _n
    file write `fh' `"    strict:{fs:3,burst:6,minact:10,n1:22,n2:6,nshare:0.15,churn:0.15,z:3,peer:0.45,ov:2,nmin:8}"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  sum: function(a){ var s=0,i; for(i=0;i<a.length;i++) s+=a[i]; return s; },"' _n
    file write `fh' `"  norm: function(s){ return String(s===null||s===undefined?'':s).trim().toLowerCase(); },"' _n
    file write `fh' `"  questionIndex: function(rows){"' _n
    file write `fh' `"    var m=Object.create(null),i,k,r;"' _n
    file write `fh' `"    for(i=0;i<(rows||[]).length;i++){ r=rows[i]; k=P.norm(r.r||r.k); if(!m[k]) m[k]=[]; m[k].push(r); }"' _n
    file write `fh' `"    return m;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  questionRows: function(all,index,resp,ws){"' _n
    file write `fh' `"    var src=resp?(index[P.norm(resp)]||[]):(all||[]),out=[],i,sk=String(ws||'');"' _n
    file write `fh' `"    for(i=0;i<src.length;i++) if(String(src[i].s||'')===sk) out.push(src[i]);"' _n
    file write `fh' `"    return out;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  questionCompare: function(a,b,key,dir){"' _n
    file write `fh' `"    var av=a[key],bv=b[key],mul=(dir===1?-1:1);"' _n
    file write `fh' `"    if(av===null||av===undefined){if(bv===null||bv===undefined)return a.v===b.v?0:(a.v<b.v?-1:1);return 1;}"' _n
    file write `fh' `"    if(bv===null||bv===undefined)return -1;"' _n
    file write `fh' `"    if(av===bv)return a.v===b.v?0:(a.v<b.v?-1:1);"' _n
    file write `fh' `"    return (av<bv?-1:1)*mul;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  questionSort: function(rows,key,dir){return rows.sort(function(a,b){return P.questionCompare(a,b,key,dir);});},"' _n
    file write `fh' `"  removalView: function(rows,resp,ws){"' _n
    file write `fh' `"    var scoped=[],groups=Object.create(null),rk=P.norm(resp),sk=String(ws||''),i,r,k,g;"' _n
    file write `fh' `"    var out={histories:0,questions:0,check:0,reanswered:0,events:0,compactHistories:0,compactEvents:0,outsideEvents:0,timingUnknown:0,active:0,resolved:0,rows:scoped,patterns:[]};"' _n
    file write `fh' `"    for(i=0;i<(rows||[]).length;i++){"' _n
    file write `fh' `"      r=rows[i]; if(resp&&(r.k||P.norm(r.a))!==rk) continue;if(sk==='APP'&&r.wc!=='approvebysup'&&r.wc!=='approvebyhq')continue;if(sk&&sk!=='APP'&&String(r.ws||'')!==sk&&P.norm(r.wc)!==P.norm(sk))continue;scoped.push(r);"' _n
    file write `fh' `"      out.histories++; out.questions+=r.q||0; out.check+=r.ck||0; out.reanswered+=r.ra||0; out.events+=r.n||0;"' _n
    file write `fh' `"      if(r.cp){out.compactHistories++;out.compactEvents+=r.n||0;}else out.outsideEvents+=r.n||0;if(r.tu)out.timingUnknown++;"' _n
    file write `fh' `"      if(r.tier==='C') out.resolved++; else out.active++;"' _n
    file write `fh' `"      k=r.t||'(no nearby / linked variable identified)';"' _n
    file write `fh' `"      if(!groups[k]) groups[k]={v:k,h:0,n:0,ch:0,cn:0,out:0,ids:Object.create(null)};g=groups[k];g.h++;g.n+=r.n||0;if(r.cp){g.ch++;g.cn+=r.n||0;}else g.out+=r.n||0;g.ids[r.id]=1;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    for(k in groups) if(Object.prototype.hasOwnProperty.call(groups,k)){ g=groups[k]; g.i=Object.keys(g.ids).length; delete g.ids; out.patterns.push(g); }"' _n
    file write `fh' `"    out.patterns.sort(function(a,b){if(b.n!==a.n)return b.n-a.n;if(b.h!==a.h)return b.h-a.h;return a.v<b.v?-1:1;});"' _n
    file write `fh' `"    return out;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  f1: function(x,d){ if(x===null||x===undefined||isNaN(x)) return '.'; return x.toFixed(d===undefined?1:d); },"' _n
    file write `fh' `"  inWindow: function(h,n1,n2){ if(n1===n2) return false; if(n1<n2) return h>=n1&&h<n2; return h>=n1||h<n2; },"' _n
    file write `fh' `"  fastShare: function(row,fs){"' _n
    file write `fh' `"    if(!row.g) return row.fsh;"' _n
    file write `fh' `"    var t=P.sum(row.g); if(t<=0) return null;"' _n
    file write `fh' `"    var f=0,i,lim=Math.max(0,Math.ceil(fs*2-1e-9)); for(i=0;i<row.g.length&&i<lim;i++) f+=row.g[i];"' _n
    file write `fh' `"    return f/t;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  nightShare: function(row,n1,n2){"' _n
    file write `fh' `"    if(!row.h) return row.nsh;"' _n
    file write `fh' `"    var t=P.sum(row.h); if(t<=0) return null;"' _n
    file write `fh' `"    var s=0,i; for(i=0;i<24;i++) if(P.inWindow(i,n1,n2)) s+=row.h[i];"' _n
    file write `fh' `"    return s/t;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  median: function(a){"' _n
    file write `fh' `"    if(!a.length) return null;"' _n
    file write `fh' `"    var b=a.slice().sort(function(x,y){return x-y;});"' _n
    file write `fh' `"    var m=Math.floor(b.length/2);"' _n
    file write `fh' `"    return b.length%2 ? b[m] : (b[m-1]+b[m])/2;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  pctl: function(a,p){"' _n
    file write `fh' `"    if(!a.length) return null;"' _n
    file write `fh' `"    var b=a.slice().sort(function(x,y){return x-y;});"' _n
    file write `fh' `"    var i=Math.ceil(p*b.length)-1;"' _n
    file write `fh' `"    if(i<0) i=0; if(i>b.length-1) i=b.length-1;"' _n
    file write `fh' `"    return b[i];"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  zctx: function(rows){"' _n
    file write `fh' `"    var lx=[],i;"' _n
    file write `fh' `"    for(i=0;i<rows.length;i++) if(rows[i].itq===1&&rows[i].af>0&&rows[i].im!==1&&rows[i].imm!==1) lx.push(Math.log(rows[i].af));"' _n
    file write `fh' `"    if(lx.length<10) return null;"' _n
    file write `fh' `"    var med=P.median(lx), dev=[],j;"' _n
    file write `fh' `"    for(j=0;j<lx.length;j++) dev.push(Math.abs(lx[j]-med));"' _n
    file write `fh' `"    var mad=P.median(dev);"' _n
    file write `fh' `"    if(!(mad>0)) return null;"' _n
    file write `fh' `"    return {med:med, mad:mad};"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  zval: function(row,ctx){"' _n
    file write `fh' `"    var tq=row.itq, m=row.im, mm=row.imm;"' _n
    file write `fh' `"    if(!ctx||tq!==1||m===1||mm===1||!(row.af>0)) return null;"' _n
    file write `fh' `"    return 0.6745*(Math.log(row.af)-ctx.med)/ctx.mad;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  team: function(rows){"' _n
    file write `fh' `"    var med=[],nq=[],act=[],i,r;"' _n
    file write `fh' `"    for(i=0;i<rows.length;i++){"' _n
    file write `fh' `"      r=rows[i];"' _n
    file write `fh' `"      if(r.af!==null&&r.af!==undefined) act.push(r.af);"' _n
    file write `fh' `"      if(r.med!==null) med.push(r.med);"' _n
    file write `fh' `"      if(r.nq!==null&&r.nq!==undefined) nq.push(r.nq);"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    return {med:P.median(med), nq:P.median(nq), act:P.median(act)};"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  isCapi: function(row){ return row.m!==1 && row.mm!==1 && row.mu!==1; },"' _n
    file write `fh' `"  flagsFor: function(row,S,ctx){"' _n
    file write `fh' `"    var capi=P.isCapi(row);"' _n
    file write `fh' `"    var primaryView=!row.vr || row.vp===1;"' _n
    file write `fh' `"    var dcapi=row.im!==1&&row.imm!==1, dtq=row.itq;"' _n
    file write `fh' `"    var support=row.vr?(row.vans||0):(row.pans||row.nt||0);"' _n
    file write `fh' `"    var nsh=P.nightShare(row,S.n1,S.n2), z=P.zval(row,ctx);"' _n
    file write `fh' `"    return ["' _n
    file write `fh' `"      capi && row.tq===1 && row.med!==null && row.med<S.fs && row.nt>=S.nmin,"' _n
    file write `fh' `"      capi && row.tq===1 && row.fr>=S.burst && row.nt>=S.nmin,"' _n
    file write `fh' `"      primaryView && dcapi && dtq===1 && row.nc>0 && row.af!==null && row.af<S.minact,"' _n
    file write `fh' `"      capi && row.lq===1 && row.to!==1 && nsh!==null && nsh>S.nshare && row.nt>=S.nmin,"' _n
    file write `fh' `"      row.ch!==null && row.ch>S.churn && support>=S.nmin,"' _n
    file write `fh' `"      primaryView && dcapi && dtq===1 && z!==null && Math.abs(z)>S.z,"' _n
    file write `fh' `"      capi && row.tq===1 && row.rt!==null && row.rt<S.peer && row.nt>=S.nmin,"' _n
    file write `fh' `"      row.ov>=S.ov"' _n
    file write `fh' `"    ];"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  resub: function(row){ return row.rj>0 && row.rbc===1 && row.re===0; },"' _n
    file write `fh' `"  softResub: function(row){"' _n
    file write `fh' `"    return row.rj>0 && row.rbc===1 && row.re>0 && row.rq!==null && row.rq>=1 && row.rq<=2 && row.rb!==null && row.rb>=0 && row.rb<10;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  unknownResub: function(row){ return row.rj>0 && row.rbc===1 && row.re>0 && (row.rq===null||row.rq===0); },"' _n
    file write `fh' `"  multiDay: function(row){ return row.on===1&&row.ilq===1&&row.ito!==1; },"' _n
    file write `fh' `"  postEdit: function(row){ return (row.pcf||0)>0; },"' _n
    file write `fh' `"  unresolvedRemoval: function(row){ return row.fdc===1 ? (row.fck||0)>0 : ((row.cop||0)+(row.cu||0))>0; },"' _n
    file write `fh' `"  domains: function(row){"' _n
    file write `fh' `"    var f=row._f||[false,false,false,false,false,false,false,false];"' _n
    file write `fh' `"    var pace=(f[0]?1:0)+(f[1]?1:0)+(f[6]?1:0), duration=(f[2]?1:0)+(f[5]?1:0);"' _n
    file write `fh' `"    var n=(pace>0?1:0)+(duration>0?1:0)+(f[3]?1:0)+(f[4]?1:0)+(f[7]?1:0);"' _n
    file write `fh' `"    return {n:n,pace:pace,duration:duration};"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  tierFor: function(row){"' _n
    file write `fh' `"    var d=P.domains(row);"' _n
    file write `fh' `"    if(row._r) return 'A';"' _n
    file write `fh' `"    if(d.n>=3) return 'A';"' _n
    file write `fh' `"    if(d.n>=2 || d.pace>=2 || d.duration>=2 || row._f[7]) return 'V';"' _n
    file write `fh' `"    if(P.softResub(row) || P.unknownResub(row) || P.unresolvedRemoval(row) || row.wsm===1) return 'V';"' _n
    file write `fh' `"    if(row._n>0 || P.multiDay(row) || P.postEdit(row)) return 'W';"' _n
    file write `fh' `"    return '';"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  evidence: function(row,S,team,meta){"' _n
    file write `fh' `"    meta=meta||{};"' _n
    file write `fh' `"    var out=[], f=row._f;"' _n
    file write `fh' `"    if(f[7]) out.push({t:'flag', s:(row.ova||'An interviewer')+' recorded answers in this and another interview in '+row.ov+' shared UTC-minute bucket(s). This is a screening match, not proof of simultaneous interviewing.'+(row.ovd?(' Trace: '+row.ovd):'')});"' _n
    file write `fh' `"    if(row._r){"' _n
    file write `fh' `"      var w='Rejected, then re-completed ';"' _n
    file write `fh' `"      if(row.rb!==null) w+=P.f1(row.rb,0)+' min later ';"' _n
    file write `fh' `"      out.push({t:'hard', s:w+'with no question changed between rejection and re-completion.'});"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    else if(P.softResub(row)) out.push({t:'flag', s:'Rejected, re-completed after '+P.f1(row.rb,0)+' min with '+row.rq+' distinct question(s) touched in '+row.re+' edit event(s)'+(row.rba?(' by '+row.rba):'')+(row.rbv?(' ['+row.rbv+']'):'')+'.'});"' _n
    file write `fh' `"    else if(P.unknownResub(row)) out.push({t:'flag', s:'Rejected and re-completed after '+row.re+' edit event(s), but this reduced paradata does not identify the distinct questions touched.'});"' _n
    file write `fh' `"    else if(row.rbb===1) out.push({t:'info', s:'A rejection/completion cycle has reversed timestamps; its turnaround duration was not scored.'});"' _n
    file write `fh' `"    var metricActor=row.vr||row.r;"' _n
    file write `fh' `"    if(f[0]) out.push({t:'flag', s:'Interviewer '+metricActor+' had a typical first-pass answer time of '+P.f1(row.med,1)+' s across '+row.nt+' timed answers'+(team.med!==null?' (team typical '+P.f1(team.med,1)+' s)':'')+'.'});"' _n
    file write `fh' `"    if(f[6]) out.push({t:'flag', s:'Finished its questions in '+P.f1(100*row.rt,0)+'% of the time colleagues typically need on those same questions.'});"' _n
    file write `fh' `"    if(f[1]){"' _n
    file write `fh' `"      var wfs=P.fastShare(row,S.fs);"' _n
    file write `fh' `"      out.push({t:'flag', s:'Interviewer '+metricActor+' had a within-session streak of '+row.fr+' consecutive first-pass questions, each answered in under '+(meta.fastsecs||2)+' s'+(wfs!==null?(' ('+P.f1(100*wfs,0)+'% of first-pass timed answers were under '+S.fs+' s)'):'')+'.'});"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    if(f[2]){"' _n
    file write `fh' `"      var w2='First completion followed only '+P.f1(row.af,1)+' min of active first-pass work';"' _n
    file write `fh' `"      if(row.nq!==null&&row.nq!==undefined&&team.nq!==null) w2+=' - '+row.nq+' distinct questions answered (team median '+P.f1(team.nq,0)+')';"' _n
    file write `fh' `"      out.push({t:'flag', s:w2+'.'});"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    if(f[3]){"' _n
    file write `fh' `"      var w3=P.f1(100*P.nightShare(row,S.n1,S.n2),0)+'% of answering happened between '+S.n1+':00 and '+S.n2+':00 device time.';"' _n
    file write `fh' `"      if(row.to===1) w3+=' Caution: this tablet clock is unreliable (offset differs from the team or changed mid-fieldwork).';"' _n
    file write `fh' `"      out.push({t:'flag', s:w3, cav:(row.to===1)});"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    if(f[4]) out.push({t:'flag', s:P.f1(100*row.ch,0)+' answers removed per 100 set.'});"' _n
    file write `fh' `"    if(f[5]) out.push({t:'flag', s:'First-pass active time '+P.f1(row.af,1)+' min is far outside the survey-wide pattern.'});"' _n
    file write `fh' `"    if(row.vr && row.vp!==1 && row.itq===1 && row.im!==1 && row.imm!==1 && row.nc>0 && row.af!==null && row.af<S.minact) out.push({t:'info', s:'The interview-level short-duration context belongs to primary interviewer '+row.r+'; it is not attributed to selected correction actor '+row.vr+'.'});"' _n
    file write `fh' `"    if(P.unresolvedRemoval(row)) out.push({t:'flag', s:'Final-data review after a historical removal run: '+row.fda+' answered; '+row.fad+' answered while disabled; '+row.feb+' blank as expected because disabled; '+row.fbe+' blank while enabled; '+row.flu+' logic unknown; '+row.fnd+' not in supplied data.'});"' _n
    file write `fh' `"    else if(row.cas>0) out.push({t:'info', s:'Historical removal run resolved: '+row.fda+' answered and '+row.feb+' correctly blank because disabled. No action from this history alone.'});"' _n
    file write `fh' `"    if(row.ho===1) out.push({t:'info', s:'Fieldwork involved '+row.na+' actors. Primary: '+row.r+' ('+P.f1(100*row.pas,0)+'% of field answers); last editor: '+(row.le||'-')+'. Metrics and flags are attributed to the actor who generated them, not automatically to the last editor.'});"' _n
    file write `fh' `"    if(P.multiDay(row)) out.push({t:'flag', s:'First-pass work continued on '+row.wd+' device-local dates ('+(row.d0||'?')+' to '+(row.d1||'?')+'), with a longest pre-completion pause of '+P.f1(row.lpp,0)+' min. Active work excludes that pause.'});"' _n
    file write `fh' `"    else if(row.on===1) out.push({t:'info', s:'First-pass work spans multiple recorded local dates, but local-clock quality is unreliable; no multi-day review signal was applied.'});"' _n
    file write `fh' `"    else if(row.lp!==null && row.lp>=60) out.push({t:'info', s:'Longest pause between work sessions was '+P.f1(row.lp,0)+' min; active time excludes it.'});"' _n
    file write `fh' `"    if(row.pr===1) out.push({t:'info', s:'The case returned to field activity after an earlier completion; total active time is '+P.f1(row.act,1)+' min versus '+P.f1(row.af,1)+' min through first completion.'});"' _n
    file write `fh' `"    if(row.m===1) out.push({t:'info', s:'Selected behavior actor worked in CAWI - actor speed, streak, night and peer signals were not applied.'});"' _n
    file write `fh' `"    if(row.mm===1) out.push({t:'info', s:'Selected behavior actor has mixed CAPI/CAWI answers - actor timing signals were suppressed.'});"' _n
    file write `fh' `"    if(row.mu===1) out.push({t:'info', s:'Selected actor collection mode is unavailable in this paradata - mode-dependent timing signals were suppressed.'});"' _n
    file write `fh' `"    if(row.tq!==1) out.push({t:'info', s:'Selected actor timing is incomplete or reversed; actor speed, streak and peer signals were suppressed.'});"' _n
    file write `fh' `"    if(row.itq!==1 || row.im===1 || row.imm===1) out.push({t:'info', s:'Whole-interview first-pass timing/mode quality is unsuitable; short-duration and duration-outlier signals were suppressed.'});"' _n
    file write `fh' `"    if(row.wsm===1) out.push({t:'flag', s:'Workflow status differs between paradata ('+(row.wsp||'-')+') and final data ('+(row.wsd||'-')+'). The displayed status comes from '+row.wss+'.'});"' _n
    file write `fh' `"    if(row.to===1 && !f[3]){"' _n
    file write `fh' `"      if(row.tz!==null && meta.tzmode!==undefined && meta.tzmode!==null && Math.abs(row.tz-meta.tzmode)<0.05)"' _n
    file write `fh' `"        out.push({t:'info', s:'The tablet clock offset changed during fieldwork on this interview - its hours are unreliable.'});"' _n
    file write `fh' `"      else out.push({t:'info', s:'Tablet clock offset '+(row.tz===null?'?':P.f1(row.tz,1))+' h differs from the team ('+P.f1(meta.tzmode,1)+' h).'});"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    if(P.postEdit(row)) out.push({t:'flag', s:'Interviewer recorded '+row.pcf+' answer edit(s) after completion outside a rejection-correction episode.'+(row.pcd?(' Trace: '+row.pcd):'')});"' _n
    file write `fh' `"    else if((row.pca||0)>0) out.push({t:'info', s:'Post-completion audit trail contains '+row.pca+' answer edit(s)'+(row.pcn>0?(' ('+row.pcn+' by Supervisor/HQ/API roles)'):'')+'.'+(row.pcd?(' Outside-cycle trace: '+row.pcd):'' )});"' _n
    file write `fh' `"    if(row.ve!==null && row.ve>0) out.push({t:'info', s:row.ve+' validation error(s) still open.'});"' _n
    file write `fh' `"    return out;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  forActor: function(row,a){"' _n
    file write `fh' `"    var x=Object.create(null),k; for(k in row) if(Object.prototype.hasOwnProperty.call(row,k)) x[k]=row[k];"' _n
    file write `fh' `"    x.itq=row.itq; x.ilq=row.ilq; x.im=row.im; x.imm=row.imm; x.imu=row.imu; x.ito=row.ito; x.iaf=row.af; x.iact=row.act;"' _n
    file write `fh' `"    x.vr=a.r; x.vp=a.p; x.vf=a.f; x.vl=a.l; x.vshare=a.share; x.vans=a.ans; x.vansf=a.ansf; x.vq=a.q; x.vss=a.ss; x.vact=a.act; x.vaf=a.af;"' _n
    file write `fh' `"    x.med=a.med; x.nt=a.nt; x.fsh=a.fsh; x.nsh=a.nsh; x.ch=a.ch; x.rt=a.rt; x.fr=a.fr; x.ov=a.ov; x.ova=a.r; x.ovd=a.ovd||'';"' _n
    file write `fh' `"    x.tq=a.tq; x.lq=a.lq; x.m=a.m; x.mm=a.mm; x.mu=a.mu; x.tz=a.tz; x.to=a.to; x.h=a.h||null; x.g=a.g||null;"' _n
    file write `fh' `"    return x;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  filterRows: function(rows,resp,ws,fd,fv,actors){"' _n
    file write `fh' `"    var out=[],i,j,r,a,x,amap=null,rkey=P.norm(resp);"' _n
    file write `fh' `"    if(resp){ amap=Object.create(null); for(j=0;j<(actors||[]).length;j++) if(P.norm(actors[j].r)===rkey) amap[actors[j].id]=actors[j]; }"' _n
    file write `fh' `"    for(i=0;i<rows.length;i++){"' _n
    file write `fh' `"      r=rows[i];"' _n
    file write `fh' `"      x=r;"' _n
    file write `fh' `"      if(resp){"' _n
    file write `fh' `"        a=amap[r.id]||null;"' _n
    file write `fh' `"        if(!a) continue; x=P.forActor(r,a);"' _n
    file write `fh' `"      }"' _n
    file write `fh' `"      if(ws){"' _n
    file write `fh' `"        if(ws==='APP'){ if(r.wsc!=='approvebyhq' && r.wsc!=='approvebysup') continue; }"' _n
    file write `fh' `"        else if(r.ws!==ws) continue;"' _n
    file write `fh' `"      }"' _n
    file write `fh' `"      if(fd && fv){ if(!r.f || r.f[fd]!==fv) continue; }"' _n
    file write `fh' `"      out.push(x);"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    return out;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  aggregate: function(rows,S,ctx){"' _n
    file write `fh' `"    if(arguments.length<3) ctx=P.zctx(rows); var tot=[0,0,0,0,0,0,0,0], flagged=[], tiers={A:0,V:0,W:0}, i,j;"' _n
    file write `fh' `"    for(i=0;i<rows.length;i++){"' _n
    file write `fh' `"      var f=P.flagsFor(rows[i],S,ctx), n=0;"' _n
    file write `fh' `"      for(j=0;j<8;j++){ if(f[j]){tot[j]++;n++;} }"' _n
    file write `fh' `"      rows[i]._f=f; rows[i]._n=n;"' _n
    file write `fh' `"      rows[i]._r=P.resub(rows[i]);"' _n
    file write `fh' `"      rows[i]._d=P.domains(rows[i]);"' _n
    file write `fh' `"      rows[i]._t=P.tierFor(rows[i]);"' _n
    file write `fh' `"      if(rows[i]._t!==''){ flagged.push(rows[i]); tiers[rows[i]._t]++; }"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    var rank={A:0,V:1,W:2};"' _n
    file write `fh' `"    flagged.sort(function(a,b){"' _n
    file write `fh' `"      if(rank[a._t]!==rank[b._t]) return rank[a._t]-rank[b._t];"' _n
    file write `fh' `"      if(b._d.n!==a._d.n) return b._d.n-a._d.n;"' _n
    file write `fh' `"      if(b._n!==a._n) return b._n-a._n;"' _n
    file write `fh' `"      if(b.wip!==a.wip) return b.wip-a.wip;"' _n
    file write `fh' `"      var am=a.med===null?1e9:a.med, bm=b.med===null?1e9:b.med;"' _n
    file write `fh' `"      return am-bm;"' _n
    file write `fh' `"    });"' _n
    file write `fh' `"    return {tot:tot, flagged:flagged, tiers:tiers, n:rows.length, ctx:ctx};"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  niceBin: function(p99){"' _n
    file write `fh' `"    var c=[1,2,5,10,15,30,60,120,240,480], i, b=1;"' _n
    file write `fh' `"    for(i=0;i<c.length;i++){ b=c[i]; if(c[i]*20>=p99) break; }"' _n
    file write `fh' `"    return b;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  binsActive: function(rows){"' _n
    file write `fh' `"    var act=[],i;"' _n
    file write `fh' `"    for(i=0;i<rows.length;i++) if(rows[i].af!==null&&rows[i].af!==undefined) act.push(rows[i].af);"' _n
    file write `fh' `"    if(!act.length) return {w:1,c:[]};"' _n
    file write `fh' `"    var s=act.slice().sort(function(x,y){return x-y;});"' _n
    file write `fh' `"    var p99=Math.max(s[Math.min(s.length-1,Math.floor(0.99*s.length))],1);"' _n
    file write `fh' `"    var w=P.niceBin(p99), c=[],k;"' _n
    file write `fh' `"    for(k=0;k<20;k++) c.push(0);"' _n
    file write `fh' `"    for(i=0;i<act.length;i++) c[Math.min(Math.floor(act[i]/w),19)]++;"' _n
    file write `fh' `"    return {w:w,c:c};"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  binsMed: function(rows){"' _n
    file write `fh' `"    var c=[],k,i;"' _n
    file write `fh' `"    for(k=0;k<21;k++) c.push(0);"' _n
    file write `fh' `"    for(i=0;i<rows.length;i++) if(rows[i].med!==null) c[Math.min(Math.floor(rows[i].med),20)]++;"' _n
    file write `fh' `"    return c;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  hourTotals: function(rows){"' _n
    file write `fh' `"    var t=[],k,i,j;"' _n
    file write `fh' `"    for(k=0;k<24;k++) t.push(0);"' _n
    file write `fh' `"    var any=false;"' _n
    file write `fh' `"    for(i=0;i<rows.length;i++){"' _n
    file write `fh' `"      if(!rows[i].h) continue;"' _n
    file write `fh' `"      any=true;"' _n
    file write `fh' `"      for(j=0;j<24;j++) t[j]+=rows[i].h[j];"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    return any?t:null;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  dailyTotals: function(daily,resp){"' _n
    file write `fh' `"    var m=Object.create(null),i,k;"' _n
    file write `fh' `"    for(i=0;i<daily.length;i++){"' _n
    file write `fh' `"      if(resp&&P.norm(daily[i].r)!==P.norm(resp)) continue;"' _n
    file write `fh' `"      k=daily[i].d;"' _n
    file write `fh' `"      m[k]=(m[k]||0)+daily[i].c;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    var keys=Object.keys(m).sort(), out=[];"' _n
    file write `fh' `"    for(i=0;i<keys.length;i++) out.push({d:keys[i],c:m[keys[i]]});"' _n
    file write `fh' `"    return out;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  league: function(rows,actors,S,resp){"' _n
    file write `fh' `"    var allowed=Object.create(null), rowmap=Object.create(null), m=Object.create(null), i,a,g,any,q,capi;"' _n
    file write `fh' `"    for(i=0;i<rows.length;i++){ allowed[rows[i].id]=1; rowmap[rows[i].id]=rows[i]; }"' _n
    file write `fh' `"    for(i=0;i<actors.length;i++){"' _n
    file write `fh' `"      a=actors[i]; if(!allowed[a.id]||!a.r||(resp&&P.norm(a.r)!==P.norm(resp))) continue;"' _n
    file write `fh' `"      if(!m[a.r]) m[a.r]={r:a.r,n:0,primary:0,correction:0,fl:0,ov:0,act:[],med:[],fsh:[],nsh:[]};"' _n
    file write `fh' `"      g=m[a.r]; q=rowmap[a.id]||{}; capi=P.isCapi(a); any=false; g.n++; if(a.p===1) g.primary++; else g.correction++;"' _n
    file write `fh' `"      if(capi && a.tq===1 && a.nt>=S.nmin && a.med!==null && a.med<S.fs) any=true;"' _n
    file write `fh' `"      if(capi && a.tq===1 && a.nt>=S.nmin && a.fr>=S.burst) any=true;"' _n
    file write `fh' `"      if(capi && a.lq===1 && a.to!==1 && a.nt>=S.nmin && a.nsh!==null && a.nsh>S.nshare) any=true;"' _n
    file write `fh' `"      if(a.ans>=S.nmin && a.ch!==null && a.ch>S.churn) any=true;"' _n
    file write `fh' `"      if(capi && a.tq===1 && a.nt>=S.nmin && a.rt!==null && a.rt<S.peer) any=true;"' _n
    file write `fh' `"      if(a.ov>=S.ov) any=true;"' _n
    file write `fh' `"      if((P.resub(q)||P.softResub(q)||P.unknownResub(q)) && P.norm(q.rba)===P.norm(a.r)) any=true;"' _n
    file write `fh' `"      if(any) g.fl++; g.ov+=a.ov||0;"' _n
    file write `fh' `"      if(a.af!==null&&a.af!==undefined) g.act.push(a.af);"' _n
    file write `fh' `"      if(a.med!==null) g.med.push(a.med);"' _n
    file write `fh' `"      if(a.fsh!==null) g.fsh.push(a.fsh);"' _n
    file write `fh' `"      if(a.nsh!==null) g.nsh.push(a.nsh);"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    var out=[],k;"' _n
    file write `fh' `"    for(k in m){ if(Object.prototype.hasOwnProperty.call(m,k)) out.push(m[k]); }"' _n
    file write `fh' `"    for(i=0;i<out.length;i++){"' _n
    file write `fh' `"      out[i].medact=P.median(out[i].act);"' _n
    file write `fh' `"      out[i].medmed=P.median(out[i].med);"' _n
    file write `fh' `"      out[i].mfsh=out[i].fsh.length?P.sum(out[i].fsh)/out[i].fsh.length:null;"' _n
    file write `fh' `"      out[i].mnsh=out[i].nsh.length?P.sum(out[i].nsh)/out[i].nsh.length:null;"' _n
    file write `fh' `"      out[i].share=out[i].fl/out[i].n;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    out.sort(function(a,b){ if(b.share!==a.share) return b.share-a.share; return b.n-a.n; });"' _n
    file write `fh' `"    return out;"' _n
    file write `fh' `"  },"' _n
    file write `fh' `"  csv: function(flagged,S,team,meta){"' _n
    file write `fh' `"    var Q=String.fromCharCode(34);"' _n
    file write `fh' `"    function cell(x){"' _n
    file write `fh' `"      if(x===null||x===undefined) return '';"' _n
    file write `fh' `"      var s=String(x);"' _n
    file write `fh' `"      if(/^[\x00-\x20]*[=+\-@]/.test(s)) s=String.fromCharCode(39)+s;"' _n
    file write `fh' `"      if(s.indexOf(',')>=0||s.indexOf(Q)>=0||s.indexOf('\n')>=0||s.indexOf('\r')>=0) return Q+s.split(Q).join(Q+Q)+Q;"' _n
    file write `fh' `"      return s;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    meta=meta||{};"' _n
    file write `fh' `"    var head=['tier','risk_domains','flags','interview_key','interview_id','assignment_id','metric_actor','primary_interviewer','last_editor','first_interviewer','metric_actor_answer_share','metric_actor_answers','metric_actor_first_pass_answers','metric_actor_active_first_pass_min','metric_actor_active_total_min','metric_actor_question_instances','metric_actor_sessions','field_actor_count','primary_answer_share','status','status_source','status_paradata','status_final_data','status_mismatch','first_pass_first_day','first_pass_last_day','first_pass_work_days','interview_sessions_total','interview_sessions_first_pass','interview_sessions_rework','interview_active_first_pass_min','interview_active_total_min','interview_elapsed_span_min','interview_first_pass_span_min','longest_pause_min','longest_precompletion_pause_min','continued_multiple_days','postcompletion_return','metric_actor_timing_ok','metric_actor_local_time_ok','metric_actor_mode','interview_timing_ok','interview_mode','metric_actor_timed_answers','interview_timed_answers_total','interview_questions_answered','primary_question_instances','sec_per_answer','fast_share','fast_run','night_share','churn','peer_ratio','overlap_actor','overlap_min_actor','overlap_min_all_actors','overlap_trace','rejections','resubmit_min','resubmit_questions','resubmit_edit_events','resubmit_field_edit_events','resubmit_actor','resubmit_question_list','cascades','questions_affected','post_completion_field_answer_sets','post_completion_all_answer_edits','post_completion_nonfield_edits','post_completion_outside_cycle','post_completion_field_outside_cycle','post_completion_nonfield_outside_cycle','post_completion_trace','open_errors','review_reasons','context_notes','interview_url','assignment_url'];"' _n
    file write `fh' `"    var lines=[head.join(',')], i, r, j, pat,ev,why,notes,vals,base,iu,au;"' _n
    file write `fh' `"    var tname={A:'INVESTIGATE',V:'VERIFY',W:'WATCH'};"' _n
    file write `fh' `"    for(i=0;i<flagged.length;i++){"' _n
    file write `fh' `"      r=flagged[i]; pat='';"' _n
    file write `fh' `"      for(j=0;j<8;j++) if(r._f[j]) pat+=P.letters[j];"' _n
    file write `fh' `"      if(r._r) pat+='R';"' _n
    file write `fh' `"      if(P.softResub(r)) pat+='Q'; if(P.unknownResub(r)) pat+='X'; if(P.unresolvedRemoval(r)) pat+='U'; if(P.multiDay(r)) pat+='D'; if(P.postEdit(r)) pat+='E'; if(r.wsm===1) pat+='M';"' _n
    file write `fh' `"      ev=P.evidence(r,S,team,meta); why=[]; notes=[];"' _n
    file write `fh' `"      for(j=0;j<ev.length;j++){ if(ev[j].t==='info') notes.push(ev[j].s); else why.push(ev[j].s); }"' _n
    file write `fh' `"      base=meta.hq?String(meta.hq).replace(/\/+$/,''):''; iu=base?(base+'/Interview/Review/'+encodeURIComponent(r.id)):''; au=(base&&r.a)?(base+'/Assignments/'+encodeURIComponent(r.a)):'';"' _n
    file write `fh' `"      vals=[tname[r._t],r._d?r._d.n:'',pat,r.k,r.id,r.a,(r.vr||r.r),r.r,r.le,r.fi,P.f1(r.vr?r.vshare:r.pas,3),(r.vr?r.vans:r.pans),(r.vr?r.vansf:r.pansf),P.f1(r.vr?r.vaf:r.paf,2),P.f1(r.vr?r.vact:r.pact,2),(r.vr?r.vq:r.pq),(r.vr?r.vss:r.pss),r.na,P.f1(r.pas,3),r.ws,r.wss,r.wsp,r.wsd,r.wsm,r.d0,r.d1,r.wd,r.ss,r.sf,r.sr,P.f1(r.af,2),P.f1(r.act,2),P.f1(r.sp,1),P.f1(r.spf,1),P.f1(r.lp,1),P.f1(r.lpp,1),(P.multiDay(r)?1:0),r.pr,r.tq,r.lq,(r.mu===1?'UNKNOWN':(r.mm===1?'MIXED':(r.m===1?'CAWI':'CAPI'))),r.itq,(r.imu===1?'UNKNOWN':(r.imm===1?'MIXED':(r.im===1?'CAWI':'CAPI'))),r.nt,r.ntt,r.nq,r.pq,P.f1(r.med,2),P.f1(P.fastShare(r,S.fs),3),r.fr,P.f1(P.nightShare(r,S.n1,S.n2),3),P.f1(r.ch,3),P.f1(r.rt,3),r.ova,r.ov,r.ovt,r.ovd,r.rj,P.f1(r.rb,1),r.rq,r.re,r.ref,r.rba,r.rbv,r.cas,r.wip,r.pc,r.pca,r.pcn,r.pco,r.pcf,r.pcno,r.pcd,(r.ve===null?'':r.ve),why.join(' | '),notes.join(' | '),iu,au];"' _n
    file write `fh' `"      for(j=0;j<vals.length;j++) vals[j]=cell(vals[j]); lines.push(vals.join(','));"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    return lines.join('\n');"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"};"' _n
    file write `fh' `"if (typeof module!=='undefined' && module.exports) module.exports=P;"' _n
    file write `fh' _n
    file write `fh' `"/* ---------------- DOM layer (browser only) ---------------- */"' _n
    file write `fh' `"if (typeof document!=='undefined') {"' _n
    file write `fh' _n
    file write `fh' `"var Q=String.fromCharCode(34);"' _n
    file write `fh' `"var expOpen=Object.create(null);"' _n
    file write `fh' `"var lastA=null, lastS=null, lastTeam=null;"' _n
    file write `fh' `"function el(id){ return document.getElementById(id); }"' _n
    file write `fh' `"function fmt(x,d){"' _n
    file write `fh' `"  if(x===null||x===undefined||isNaN(x)) return '.';"' _n
    file write `fh' `"  var s=x.toFixed(d===undefined?1:d);"' _n
    file write `fh' `"  return s;"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function fmtc(x){"' _n
    file write `fh' `"  if(x===null||x===undefined) return '.';"' _n
    file write `fh' `"  var s=String(Math.round(x)), out='', c=0, i;"' _n
    file write `fh' `"  for(i=s.length-1;i>=0;i--){ out=s.charAt(i)+out; c++; if(c%3===0&&i>0) out=','+out; }"' _n
    file write `fh' `"  return out;"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function esc(s){"' _n
    file write `fh' `"  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function attr(s){ return esc(s).replace(/"/g,'&quot;').replace(/'/g,'&#39;'); }"' _n
    file write `fh' `"function hqLinks(r){"' _n
    file write `fh' `"  var b=(D.meta&&D.meta.hq)?String(D.meta.hq):'';"' _n
    file write `fh' `"  if(!b) return '';"' _n
    file write `fh' `"  b=b.replace(/\/+$/,'');"' _n
    file write `fh' `"  var iu=b+'/Interview/Review/'+encodeURIComponent(r.id);"' _n
    file write `fh' `"  var s='<span class='+Q+'hqlinks'+Q+'><a class='+Q+'hqlink'+Q+' target='+Q+'_blank'+Q+' rel='+Q+'noopener noreferrer'+Q+' href='+Q+attr(iu)+Q+'>Open interview</a>';"' _n
    file write `fh' `"  if(r.a){ var au=b+'/Assignments/'+encodeURIComponent(r.a); s+='<a class='+Q+'hqlink secondary'+Q+' target='+Q+'_blank'+Q+' rel='+Q+'noopener noreferrer'+Q+' href='+Q+attr(au)+Q+'>Open assignment</a>'; }"' _n
    file write `fh' `"  return s+'</span>';"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function copyText(t){"' _n
    file write `fh' `"  var ta=document.createElement('textarea');"' _n
    file write `fh' `"  ta.value=t; ta.style.position='fixed'; ta.style.left='-999px';"' _n
    file write `fh' `"  document.body.appendChild(ta); ta.select();"' _n
    file write `fh' `"  try{ document.execCommand('copy'); }catch(e){}"' _n
    file write `fh' `"  document.body.removeChild(ta);"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"function svgBars(counts,labels,hi,opts){"' _n
    file write `fh' `"  opts=opts||{};"' _n
    file write `fh' `"  function at(n,v){ return ' '+n+'='+Q+v+Q; }"' _n
    file write `fh' `"  var w=opts.w||940, hgt=opts.hgt||170, lstep=opts.lstep||1, showv=opts.vals||false;"' _n
    file write `fh' `"  var k=counts.length, maxc=0, i;"' _n
    file write `fh' `"  for(i=0;i<k;i++) if(counts[i]>maxc) maxc=counts[i];"' _n
    file write `fh' `"  if(maxc<=0||k===0) return '<p class=\"nodata\">Nothing to plot for this selection.</p>';"' _n
    file write `fh' `"  var plotw=w-16, ploth=hgt-34, step=plotw/k, barw=Math.max(Math.floor(step)-2,1);"' _n
    file write `fh' `"  var s='<svg'+at('viewBox','0 0 '+w+' '+hgt)+at('width','100%')+at('xmlns','http://www.w3.org/2000/svg')+'>';"' _n
    file write `fh' `"  s+='<text'+at('x',8)+at('y',12)+at('font-size',10)+at('fill','#888')+'>max '+fmtc(maxc)+'</text>';"' _n
    file write `fh' `"  s+='<line'+at('x1',8)+at('y1',hgt-22)+at('x2',w-8)+at('y2',hgt-22)+at('stroke','#d5d9de')+'></line>';"' _n
    file write `fh' `"  for(i=0;i<k;i++){"' _n
    file write `fh' `"    var c=counts[i], hb=Math.round(c/maxc*(ploth-16));"' _n
    file write `fh' `"    if(c>0&&hb<2) hb=2;"' _n
    file write `fh' `"    var x=Math.round(8+i*step), y=hgt-22-hb;"' _n
    file write `fh' `"    var col=(hi&&hi.indexOf(i)>=0)?'#C9A227':'#002244';"' _n
    file write `fh' `"    if(c>0) s+='<rect'+at('x',x)+at('y',y)+at('width',barw)+at('height',hb)+at('fill',col)+'><title>'+fmtc(c)+'</title></rect>';"' _n
    file write `fh' `"    if(showv&&c>0) s+='<text'+at('x',x+Math.floor(barw/2))+at('y',y-4)+at('font-size',10)+at('fill','#333')+at('text-anchor','middle')+'>'+fmtc(c)+'</text>';"' _n
    file write `fh' `"    if(i%lstep===0&&labels[i]) s+='<text'+at('x',x+Math.floor(barw/2))+at('y',hgt-9)+at('font-size',9.5)+at('fill','#666')+at('text-anchor','middle')+'>'+esc(labels[i])+'</text>';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  s+='</svg>';"' _n
    file write `fh' `"  return s;"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"function settings(){"' _n
    file write `fh' `"  return {"' _n
    file write `fh' `"    resp: el('c_resp').value,"' _n
    file write `fh' `"    ws:   el('c_ws').value,"' _n
    file write `fh' `"    fd:   el('c_fd').value,"' _n
    file write `fh' `"    fv:   el('c_fv').value,"' _n
    file write `fh' `"    fs:   D.meta.lite===1 ? D.meta.fastsecs : Math.max(0.5,parseFloat(el('c_fs').value)||2),"' _n
    file write `fh' `"    burst:Math.max(3,parseInt(el('c_burst').value,10)||8),"' _n
    file write `fh' `"    minact:parseFloat(el('c_minact').value)||5,"' _n
    file write `fh' `"    n1:   parseInt(el('c_n1').value,10),"' _n
    file write `fh' `"    n2:   parseInt(el('c_n2').value,10),"' _n
    file write `fh' `"    nshare:(parseFloat(el('c_nshare').value)||25)/100,"' _n
    file write `fh' `"    churn:(parseFloat(el('c_churn').value)||20)/100,"' _n
    file write `fh' `"    z:    parseFloat(el('c_z').value)||3.5,"' _n
    file write `fh' `"    peer:(parseFloat(el('c_peer').value)||35)/100,"' _n
    file write `fh' `"    ov:   Math.max(1,parseInt(el('c_ov').value,10)||3),"' _n
    file write `fh' `"    nmin: Math.max(3,parseInt(el('c_nmin').value,10)||10),"' _n
    file write `fh' `"    top:  Math.max(1,parseInt(el('c_top').value,10)||25)"' _n
    file write `fh' `"  };"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function applyPreset(p){"' _n
    file write `fh' `"  if(p==='custom'||!P.presets[p]) return;"' _n
    file write `fh' `"  var t=P.presets[p];"' _n
    file write `fh' `"  el('c_fs').value=D.meta.lite===1?D.meta.fastsecs:((t.fs!==undefined)?t.fs:D.meta.fastsecs);"' _n
    file write `fh' `"  el('c_burst').value=t.burst;"' _n
    file write `fh' `"  el('c_minact').value=t.minact;"' _n
    file write `fh' `"  el('c_n1').value=t.n1; el('c_n2').value=t.n2;"' _n
    file write `fh' `"  el('c_nshare').value=Math.round(t.nshare*100);"' _n
    file write `fh' `"  el('c_churn').value=Math.round(t.churn*100);"' _n
    file write `fh' `"  el('c_z').value=t.z;"' _n
    file write `fh' `"  el('c_peer').value=Math.round(t.peer*100);"' _n
    file write `fh' `"  el('c_ov').value=t.ov;"' _n
    file write `fh' `"  el('c_nmin').value=t.nmin;"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function postActorFilter(){"' _n
    file write `fh' `"  var sel=el('c_resp'),value=sel.value||'',label=value&&sel.selectedIndex>=0?sel.options[sel.selectedIndex].text.replace(/ \([^)]*\)$/,''):'';"' _n
    file write `fh' `"  if(window.parent!==window) window.parent.postMessage({type:'suso-actor-filter',key:P.norm(value),label:label},'*');"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function postStatusFilter(){if(window.parent!==window)window.parent.postMessage({type:'suso-status-filter',key:el('c_ws').value||''},'*');}"' _n
    file write `fh' `"function applyActorFilterMessage(d){"' _n
    file write `fh' `"  var sel=el('c_resp'), key=P.norm(d&&d.key), lab=P.norm(d&&d.label), value='', found=(!key&&!lab), i, ok;"' _n
    file write `fh' `"  for(i=0;(key||lab)&&i<sel.options.length;i++){ ok=P.norm(sel.options[i].value); if(ok===key||(lab&&ok===lab)){ value=sel.options[i].value; found=true; break; } }"' _n
    file write `fh' `"  if(!found&&key){var o=document.createElement('option');o.value=d.key;o.textContent=(d.label||d.key)+' (0 timing rows)';sel.appendChild(o);value=d.key;found=true;}"' _n
    file write `fh' `"  if(!found||sel.value===value) return;"' _n
    file write `fh' `"  sel.value=value; renderAll();"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function applyStatusFilterMessage(d){var s=el('c_ws'),k=String(d&&d.key||''),i,found=!k;for(i=0;k&&i<s.options.length;i++)if(s.options[i].value===k){found=true;break;}if(found&&s.value!==k){s.value=k;renderAll();}}"' _n
    file write `fh' `"window.addEventListener('message',function(ev){"' _n
    file write `fh' `"  // The actor-only branch was guarded by ev.source!==window.parent||d.type!=='suso-actor-filter'; the shared guard below also admits status sync."' _n
    file write `fh' `"  var d=ev.data||{};if(window.parent===window||ev.source!==window.parent||typeof d.key!=='string'||d.key.length>500)return;if(d.type==='suso-actor-filter'&&typeof d.label==='string'&&d.label.length<=500)applyActorFilterMessage(d);if(d.type==='suso-status-filter')applyStatusFilterMessage(d);"' _n
    file write `fh' `"});"' _n
    file write `fh' `"function resetSettings(){"' _n
    file write `fh' `"  el('c_resp').value='';"' _n
    file write `fh' `"  el('c_ws').value='';"' _n
    file write `fh' `"  el('c_fd').value='';"' _n
    file write `fh' `"  fvOptions();"' _n
    file write `fh' `"  el('c_preset').value='standard';"' _n
    file write `fh' `"  applyPreset('standard');"' _n
    file write `fh' `"  el('c_top').value=25;"' _n
    file write `fh' `"  expOpen=Object.create(null); qSortKey='o'; qSortDir=-1;"' _n
    file write `fh' `"  renderAll();"' _n
    file write `fh' `"  postActorFilter();"' _n
    file write `fh' `"  postStatusFilter();"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"function fvOptions(){"' _n
    file write `fh' `"  var dim=el('c_fd').value, s='<option value='+Q+Q+'>-</option>', i, j, cnt=Object.create(null);"' _n
    file write `fh' `"  if(dim && D.meta && D.meta.fdims){"' _n
    file write `fh' `"    for(i=0;i<D.rows.length;i++){"' _n
    file write `fh' `"      var rv=(D.rows[i].f&&D.rows[i].f[dim])?D.rows[i].f[dim]:'';"' _n
    file write `fh' `"      if(rv) cnt[rv]=(cnt[rv]||0)+1;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    for(i=0;i<D.meta.fdims.length;i++){"' _n
    file write `fh' `"      if(D.meta.fdims[i].v!==dim) continue;"' _n
    file write `fh' `"      var vv=D.meta.fdims[i].vals;"' _n
    file write `fh' `"      for(j=0;j<vv.length;j++){"' _n
    file write `fh' `"        var lab=(vv[j].l&&vv[j].l!==vv[j].c)?(vv[j].c+' '+vv[j].l):vv[j].c;"' _n
    file write `fh' `"        s+='<option value='+Q+esc(vv[j].c)+Q+'>'+esc(lab)+' ('+(cnt[vv[j].c]||0)+')</option>';"' _n
    file write `fh' `"      }"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  el('c_fv').innerHTML=s;"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"var qSortKey='o', qSortDir=-1, qActorIndex=P.questionIndex(D.aq||[]);"' _n
    file write `fh' `"function qSort(k){"' _n
    file write `fh' `"  if(qSortKey===k) qSortDir=-qSortDir; else { qSortKey=k; qSortDir=-1; }"' _n
    file write `fh' `"  renderQuestions();"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"function renderQuestions(){"' _n
    file write `fh' `"  var filt=(el('c_q').value||'').toLowerCase(), resp=el('c_resp').value, ws=el('c_ws').value;"' _n
    file write `fh' `"  var src=P.questionRows(D.q,qActorIndex,resp,ws), rows=[],i;"' _n
    file write `fh' `"  for(i=0;i<src.length;i++) if(!filt||src[i].v.toLowerCase().indexOf(filt)>=0) rows.push(src[i]);"' _n
    file write `fh' `"  P.questionSort(rows,qSortKey,qSortDir);"' _n
    file write `fh' `"  var s='<tr><th class=\"srt\" onclick=\"qSort(String.fromCharCode(118))\">question</th>'+"' _n
    file write `fh' `"        '<th class=\"r srt\" title=\"First-pass AnswerSet saves; revisions and roster instances can count more than once\" onclick=\"qSort(String.fromCharCode(110))\">answer events</th>'+"' _n
    file write `fh' `"        '<th class=\"r srt\" title=\"Unique interview IDs with at least one event for this question\" onclick=\"qSort(String.fromCharCode(110,105))\">distinct interviews</th>'+"' _n
    file write `fh' `"        '<th class=\"r srt\" title=\"Newly reached events with a valid within-session time gap; denominator for the timing columns\" onclick=\"qSort(String.fromCharCode(110,116))\">timed reaches</th>'+"' _n
    file write `fh' `"        '<th class=\"r srt\" onclick=\"qSort(String.fromCharCode(109,101,100))\">median gap (s)</th>'+"' _n
    file write `fh' `"        '<th class=\"r srt\" onclick=\"qSort(String.fromCharCode(112,57,48))\">p90 gap (s)</th>'+"' _n
    file write `fh' `"        '<th class=\"r srt\" onclick=\"qSort(String.fromCharCode(102,115,104))\">share &lt; '+fmt(D.meta.fastsecs,1)+' s</th></tr>';"' _n
    file write `fh' `"  var k=rows.length;"' _n
    file write `fh' `"  for(i=0;i<k;i++){"' _n
    file write `fh' `"    var q=rows[i];"' _n
    file write `fh' `"    s+='<tr><td class=\"mono\">'+esc(q.v)+'</td><td class=\"r\">'+fmtc(q.n)+'</td><td class=\"r\">'+fmtc(q.ni)+"' _n
    file write `fh' `"       '</td><td class=\"r\">'+fmtc(q.nt)+'</td><td class=\"r\">'+fmt(q.med)+'</td><td class=\"r\">'+fmt(q.p90)+'</td><td class=\"r\">'+fmt(q.fsh,2)+'</td></tr>';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  el('t_q').innerHTML=s;"' _n
    file write `fh' `"  var sb=[],scope,msg; if(resp) sb.push(resp); if(ws) sb.push(ws==='APP'?'Approved only (Sup + HQ)':ws);"' _n
    file write `fh' `"  scope=sb.length?(' for '+sb.join(' / ')):' across all enumerators and statuses';"' _n
    file write `fh' `"  if(!src.length) msg='No first-pass answer events'+scope+' in this vars() scope.';"' _n
    file write `fh' `"  else if(!rows.length) msg='No question names match the search'+scope+'.';"' _n
    file write `fh' `"  else if(filt) msg='Showing '+rows.length+' of '+src.length+' observed questions matching the search'+scope+'.';"' _n
    file write `fh' `"  else msg='Showing all '+rows.length+' observed question'+(rows.length===1?'':'s')+scope+'.';"' _n
    file write `fh' `"  el('q_more').textContent=msg;"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"function renderRemovals(resp,ws){"' _n
    file write `fh' `"  var V=P.removalView(D.rem||[],resp,ws),body=el('t_rsum'),i,s='',cs,shown=0,match,key=P.norm(resp),sw=String(ws||''),cw;"' _n
    file write `fh' `"  if(body){"' _n
    file write `fh' `"    for(i=0;i<V.patterns.length;i++){var g=V.patterns[i];s+='<tr><td class='+Q+'mono'+Q+'>'+esc(g.v)+'</td><td class='+Q+'r'+Q+'>'+fmtc(g.h)+'</td><td class='+Q+'r'+Q+'>'+fmtc(g.ch)+'</td><td class='+Q+'r'+Q+'>'+fmtc(g.i)+'</td><td class='+Q+'r'+Q+'>'+fmtc(g.n)+'</td><td class='+Q+'r'+Q+'>'+fmtc(g.cn)+'</td><td class='+Q+'r'+Q+'>'+fmtc(g.out)+'</td></tr>'; }"' _n
    file write `fh' `"    if(!s) s='<tr><td colspan='+Q+'7'+Q+' class='+Q+'nodata'+Q+'>No removal histories for this actor/status and vars() scope.</td></tr>';"' _n
    file write `fh' `"    body.innerHTML=s;"' _n
    file write `fh' `"    el('r_more').textContent=V.histories+' exhaustive histor'+(V.histories===1?'y':'ies')+', '+V.events+' raw events, '+V.compactHistories+' compact histories / '+V.compactEvents+' compact events, and '+V.outsideEvents+' outside-pattern events in this actor/status scope.';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  cs=document.querySelectorAll('.bremcase');"' _n
    file write `fh' `"  for(i=0;i<cs.length;i++){cw=String(cs[i].getAttribute('data-statusclass')||'');match=(!resp||P.norm(cs[i].getAttribute('data-actor'))===key)&&(!sw||(sw==='APP'?(cw==='approvebysup'||cw==='approvebyhq'):(String(cs[i].getAttribute('data-status')||'')===sw||P.norm(cw)===P.norm(sw))));cs[i].style.display=match?'':'none';if(match)shown++;}"' _n
    file write `fh' `"  if(el('r_action_note')) el('r_action_note').textContent=V.active+' case(s) require a final-data check in this actor/status scope.';"' _n
    file write `fh' `"  if(el('r_action_none')) el('r_action_none').style.display=V.active===0?'':'none';"' _n
    file write `fh' `"  return V;"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"function chipsFor(r){"' _n
    file write `fh' `"  var s='',j;"' _n
    file write `fh' `"  if(r._r) s+='<span class='+Q+'chip hard'+Q+' title='+Q+'Rejected and re-completed with no answers changed'+Q+'>Resubmitted unchanged</span>';"' _n
    file write `fh' `"  else if(P.softResub(r)) s+='<span class='+Q+'chip'+Q+' title='+Q+'Quick rejection cycle with one or two distinct questions touched'+Q+'>Quick correction</span>';"' _n
    file write `fh' `"  else if(P.unknownResub(r)) s+='<span class='+Q+'chip'+Q+' title='+Q+'Rejection correction edits are present but question identities are unavailable'+Q+'>Correction scope unknown</span>';"' _n
    file write `fh' `"  for(j=0;j<8;j++){"' _n
    file write `fh' `"    if(!r._f[j]) continue;"' _n
    file write `fh' `"    var cls='chip';"' _n
    file write `fh' `"    s+='<span class='+Q+cls+Q+'>'+P.names[j]+'</span>';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  if(P.unresolvedRemoval(r)) s+='<span class='+Q+'chip'+Q+' title='+Q+'Historical removal run with unresolved final-data assessment'+Q+'>Final-data check</span>';"' _n
    file write `fh' `"  else if(r.cas>0) s+='<span class='+Q+'chip info'+Q+' title='+Q+'Historical removal run resolved by final data and logic; no action'+Q+'>Removal history resolved</span>';"' _n
    file write `fh' `"  if(r.m===1) s+='<span class='+Q+'chip info'+Q+'>CAWI</span>';"' _n
    file write `fh' `"  if(r.mm===1) s+='<span class='+Q+'chip info'+Q+'>Mixed mode</span>';"' _n
    file write `fh' `"  if(P.multiDay(r)) s+='<span class='+Q+'chip info'+Q+' title='+Q+'Trustworthy first-pass work continued on more than one device-local date'+Q+'>Multiple field dates</span>';"' _n
    file write `fh' `"  else if(r.on===1) s+='<span class='+Q+'chip info'+Q+' title='+Q+'Recorded dates span days but local-clock quality is unreliable'+Q+'>Dates uncertain</span>';"' _n
    file write `fh' `"  if(P.postEdit(r)) s+='<span class='+Q+'chip'+Q+' title='+Q+'Interviewer answer edits after completion outside a rejection cycle'+Q+'>Post-completion field edits</span>';"' _n
    file write `fh' `"  else if((r.pcno||0)>0) s+='<span class='+Q+'chip info'+Q+' title='+Q+'Supervisor/HQ/API review edits after completion'+Q+'>Post-completion review edits</span>';"' _n
    file write `fh' `"  if(r.ho===1) s+='<span class='+Q+'chip info'+Q+' title='+Q+'More than one field actor contributed'+Q+'>Actor handoff</span>';"' _n
    file write `fh' `"  if(r.wsm===1) s+='<span class='+Q+'chip'+Q+' title='+Q+'Paradata and final-data workflow status differ'+Q+'>Status mismatch</span>';"' _n
    file write `fh' `"  if(r.to===1) s+='<span class='+Q+'chip info'+Q+' title='+Q+'Tablet timezone differs from the team or changed - hours unreliable'+Q+'>Clock suspect</span>';"' _n
    file write `fh' `"  return s;"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function detailHtml(r,S,team){"' _n
    file write `fh' `"  var ev=P.evidence(r,S,team,D.meta), s='', i;"' _n
    file write `fh' `"  var ma=r.vr||r.r, maf=r.vr?r.vaf:r.paf, mat=r.vr?r.vact:r.pact, mans=r.vr?r.vans:r.pans, mansf=r.vr?r.vansf:r.pansf, mq=r.vr?r.vq:r.pq, mss=r.vr?r.vss:r.pss;"' _n
    file write `fh' `"  s+='<div class='+Q+'facts'+Q+'><b>Interview:</b> <span class='+Q+'mono'+Q+'>'+esc(r.id)+'</span>'+"' _n
    file write `fh' `"     '<span class='+Q+'cpy'+Q+' data-t='+Q+attr(r.id)+Q+'>copy id</span>';"' _n
    file write `fh' `"  s+=' <button type='+Q+'button'+Q+' class='+Q+'pbtn ghost hv-open'+Q+' data-history-id='+Q+attr(r.id)+Q+'>View event history</button>';"' _n
    file write `fh' `"  if(r.k) s+=' &nbsp; <b>Key:</b> <span class='+Q+'mono'+Q+'>'+esc(r.k)+'</span><span class='+Q+'cpy'+Q+' data-t='+Q+attr(r.k)+Q+'>copy key</span>';"' _n
    file write `fh' `"  s+=hqLinks(r);"' _n
    file write `fh' `"  s+=' &nbsp; <b>Status:</b> '+esc(r.ws||'-')+' <span class='+Q+'legend'+Q+'>('+esc(r.wss||'paradata')+')</span> &nbsp; <b>Field dates:</b> '+esc(r.d0||'-')+(r.d1&&r.d1!==r.d0?(' to '+esc(r.d1)):'')+"' _n
    file write `fh' `"     ' &nbsp; <b>Primary actor:</b> '+esc(r.r||'-')+(r.vr&&r.vr!==r.r?(' &nbsp; <b>Metrics actor:</b> '+esc(r.vr)):'')+(r.ho===1?(' &nbsp; <b>Last editor:</b> '+esc(r.le||'-')):'')+"' _n
    file write `fh' `"     ' &nbsp; <b>Interview workflow:</b> '+r.ss+' sessions ('+r.sf+' first-pass + '+r.sr+' rework), '+fmt(r.af,1)+' first-pass / '+fmt(r.act,1)+' total active min, '+fmt(r.sp,0)+' min elapsed span, '+fmt(r.lp,0)+' min longest pause' +"' _n
    file write `fh' `"     ' &nbsp; <b>'+esc(ma)+' contribution:</b> '+fmtc(mans)+' answers ('+fmtc(mansf)+' first-pass), '+fmt(maf,1)+' first-pass / '+fmt(mat,1)+' total active min, '+fmtc(r.nt)+' timed'+(mq!==null?(', '+fmtc(mq)+' question instances'):'')+(mss!==null?(', '+fmtc(mss)+' sessions'):'')+"' _n
    file write `fh' `"     ' &nbsp; <b>Restarts:</b> '+r.rs+' &nbsp; <b>Rejections:</b> '+r.rj+"' _n
    file write `fh' `"     ((r.tz!==null)?(' &nbsp; <b>Device offset:</b> '+fmt(r.tz,1)+' h'):'')+'</div>';"' _n
    file write `fh' `"  for(i=0;i<ev.length;i++){"' _n
    file write `fh' `"    var cls=(ev[i].t==='hard')?'ev hard':'ev';"' _n
    file write `fh' `"    var pre=(ev[i].t==='hard')?'<b style='+Q+'color:#8a1f1f'+Q+'>! </b>':((ev[i].t==='info')?'<span style='+Q+'color:#888'+Q+'>i </span>':'<span style='+Q+'color:#C9A227'+Q+'>&#9679; </span>');"' _n
    file write `fh' `"    s+='<div class='+Q+cls+Q+'>'+pre+esc(ev[i].s)+'</div>';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  if(!D.meta.lite && (r.h||r.g)){"' _n
    file write `fh' `"    s+='<div style='+Q+'display:flex;flex-wrap:wrap;gap:18px;margin-top:8px'+Q+'>';"' _n
    file write `fh' `"    if(r.h){"' _n
    file write `fh' `"      var labH=[],hiH=[],x;"' _n
    file write `fh' `"      for(x=0;x<24;x++){ labH.push(String(x)); if(P.inWindow(x,S.n1,S.n2)) hiH.push(x); }"' _n
    file write `fh' `"      s+='<div style='+Q+'flex:1 1 320px'+Q+'><div class='+Q+'legend'+Q+'>Answers by hour (device time)</div>'+svgBars(r.h,labH,hiH,{w:460,hgt:100,lstep:3})+'</div>';"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    if(r.g){"' _n
    file write `fh' `"      var labG=[],hiG=[],y;"' _n
    file write `fh' `"      for(y=0;y<41;y++){ labG.push(y<40?String(y/2):'20+'); if(y<S.fs*2) hiG.push(y); }"' _n
    file write `fh' `"      s+='<div style='+Q+'flex:1 1 320px'+Q+'><div class='+Q+'legend'+Q+'>Seconds per answer</div>'+svgBars(r.g,labG,hiG,{w:460,hgt:100,lstep:4})+'</div>';"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    s+='</div>';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  return s;"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function renderWorst(){"' _n
    file write `fh' `"  var A=lastA, S=lastS, team=lastTeam;"' _n
    file write `fh' `"  if(!A) return;"' _n
    file write `fh' `"  var s='<tr><th></th><th>interview</th><th>metrics actor / primary</th><th>field date(s)</th><th>signals</th><th class=\"r\">first-pass min</th><th class=\"r\">sec/ans</th></tr>';"' _n
    file write `fh' `"  var F=A.flagged, kk=Math.min(F.length,S.top), i;"' _n
    file write `fh' `"  var tlab={A:'Investigate',V:'Verify',W:'Watch'};"' _n
    file write `fh' `"  for(i=0;i<kk;i++){"' _n
    file write `fh' `"    var r=F[i];"' _n
    file write `fh' `"    var keyc=r.k?('<span class='+Q+'mono'+Q+'><b>'+esc(r.k)+'</b></span>'):('<span class='+Q+'mono'+Q+'>'+esc(r.id.substring(0,8))+'</span>');"' _n
    file write `fh' `"    s+='<tr class='+Q+'wrow'+Q+' data-i='+Q+i+Q+'>'+"' _n
    file write `fh' `"       '<td><span class='+Q+'tier '+r._t+Q+'>'+tlab[r._t]+'</span></td>'+"' _n
    file write `fh' `"       '<td>'+keyc+'</td>'+"' _n
    file write `fh' `"       '<td>'+esc(r.vr||r.r)+(r.vr&&r.vr!==r.r?('<br><span class='+Q+'legend'+Q+'>primary: '+esc(r.r)+'</span>'):'')+'</td>'+"' _n
    file write `fh' `"       '<td>'+esc(r.d0||'-')+(r.d1&&r.d1!==r.d0?('<br>'+esc(r.d1)):'')+'</td>'+"' _n
    file write `fh' `"       '<td>'+chipsFor(r)+'</td>'+"' _n
    file write `fh' `"       '<td class=\"r\">'+fmt(r.af)+'</td>'+"' _n
    file write `fh' `"       '<td class=\"r\">'+fmt(r.med)+'</td></tr>';"' _n
    file write `fh' `"    if(expOpen[r.id]) s+='<tr class='+Q+'wdet'+Q+'><td colspan='+Q+'7'+Q+'>'+detailHtml(r,S,team)+'</td></tr>';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  el('t_worst').innerHTML=s;"' _n
    file write `fh' `"  el('w_none').textContent = F.length===0 ? 'Nothing to review for this selection - no signals and no cascades.' : (F.length>kk?('Showing '+kk+' of '+F.length+' - raise Show top to see more.'):'');"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"function renderAll(){"' _n
    file write `fh' `"  var S=settings();"' _n
    file write `fh' `"  var rows=P.filterRows(D.rows,S.resp,S.ws,S.fd,S.fv,D.actors);"' _n
    file write `fh' `"  var benchmarkRows=P.filterRows(D.rows,'',S.ws,S.fd,S.fv,D.actors);"' _n
    file write `fh' `"  var A=P.aggregate(rows,S,P.zctx(benchmarkRows));"' _n
    file write `fh' `"  var team=P.team(benchmarkRows);"' _n
    file write `fh' `"  lastA=A; lastS=S; lastTeam=team;"' _n
    file write `fh' `"  var scope=S.resp?('actor '+S.resp):'all field actors';"' _n
    file write `fh' `"  if(S.ws) scope+=(S.ws==='APP')?', approved interviews':(', status '+S.ws);"' _n
    file write `fh' `"  if(S.fd && S.fv) scope+=', '+S.fd+' = '+S.fv;"' _n
    file write `fh' _n
    file write `fh' `"  el('k_started').textContent=fmtc(A.n);"' _n
    file write `fh' `"  el('k_inv').textContent=fmtc(A.tiers.A);"' _n
    file write `fh' `"  el('k_ver').textContent=fmtc(A.tiers.V);"' _n
    file write `fh' `"  var acts=[],i;"' _n
    file write `fh' `"  for(i=0;i<rows.length;i++) if(rows[i].af!==null) acts.push(rows[i].af);"' _n
    file write `fh' `"  el('k_medact').textContent=fmt(P.median(acts));"' _n
    file write `fh' `"  el('k_medans').textContent=fmt(team.med);"' _n
    file write `fh' _n
    file write `fh' `"  var verdict, vc, tA=A.tiers.A, tV=A.tiers.V, tW=A.tiers.W;"' _n
    file write `fh' `"  if(tA>0){ verdict=fmtc(tA)+' interview(s) need investigation, '+fmtc(tV)+' to verify and '+fmtc(tW)+' to watch, out of '+fmtc(A.n)+' for '+scope+'.'; vc='bad'; }"' _n
    file write `fh' `"  else if(tV>0){ verdict=fmtc(tV)+' interview(s) to verify and '+fmtc(tW)+' to watch, out of '+fmtc(A.n)+' for '+scope+' - no hard evidence at these thresholds.'; vc='warn'; }"' _n
    file write `fh' `"  else if(tW>0){ verdict='Only single, isolated signals ('+fmtc(tW)+' interview(s) to watch) for '+scope+'.'; vc='warn'; }"' _n
    file write `fh' `"  else { verdict='No behaviour signals raised for '+scope+' at the current sensitivity.'; vc='ok'; }"' _n
    file write `fh' `"  el('verdict').textContent=verdict;"' _n
    file write `fh' `"  el('verdict').className='verdict '+vc;"' _n
    file write `fh' _n
    file write `fh' `"  el('ch_flags').innerHTML=svgBars(A.tot,"' _n
    file write `fh' `"    ['S speed','B streak','T short','N night','C churn','Z outlier','P peers','O overlap'],[7],"' _n
    file write `fh' `"    {hgt:150,vals:true})+'<div class='+Q+'legend'+Q+'>S sustained speeding &nbsp; B a within-actor/session run of fast answers &nbsp; T first completion too quickly &nbsp; N night work &nbsp; C answer churn &nbsp; Z first-pass duration outlier &nbsp; P far faster than peers on the same questions &nbsp; O actor-specific shared UTC-minute screen</div>';"' _n
    file write `fh' _n
    file write `fh' `"  var BA=P.binsActive(rows), labA=[], hiA=[];"' _n
    file write `fh' `"  for(i=0;i<20;i++){ labA.push(String(i*BA.w)); if((i+1)*BA.w<=S.minact) hiA.push(i); }"' _n
    file write `fh' `"  el('ch_act').innerHTML=svgBars(BA.c,labA,hiA,{lstep:2});"' _n
    file write `fh' `"  el('n_act').textContent='Bins of '+BA.w+' min; gold bins fall under the '+S.minact+'-minute floor.';"' _n
    file write `fh' _n
    file write `fh' `"  var BM=P.binsMed(rows), labM=[], hiM=[];"' _n
    file write `fh' `"  for(i=0;i<21;i++){ labM.push(i<20?String(i):'20+'); if(i<S.fs) hiM.push(i); }"' _n
    file write `fh' `"  el('ch_med').innerHTML=svgBars(BM,labM,hiM,{lstep:2});"' _n
    file write `fh' `"  el('n_med').textContent='Gold bars: interviews where a typical question was answered in under '+S.fs+' seconds - too fast for a real conversation.';"' _n
    file write `fh' _n
    file write `fh' `"  var HT=P.hourTotals(rows), labH=[], hiH=[];"' _n
    file write `fh' `"  for(i=0;i<24;i++){ labH.push(String(i)); if(P.inWindow(i,S.n1,S.n2)) hiH.push(i); }"' _n
    file write `fh' `"  if(HT) el('ch_hour').innerHTML=svgBars(HT,labH,hiH,{lstep:2});"' _n
    file write `fh' `"  else el('ch_hour').innerHTML='<p class=\"nodata\">Hour detail not embedded for this survey size.</p>';"' _n
    file write `fh' _n
    file write `fh' `"  var DT=P.dailyTotals(D.daily,S.resp), dc=[], dl=[], dstep=Math.max(1,Math.floor(DT.length/8));"' _n
    file write `fh' `"  for(i=0;i<DT.length;i++){ dc.push(DT[i].c); dl.push(i%dstep===0?DT[i].d.substring(5):''); }"' _n
    file write `fh' `"  el('ch_daily').innerHTML=svgBars(dc,dl,[],{lstep:1});"' _n
    file write `fh' _n
    file write `fh' `"  var L=P.league(rows,D.actors,S,S.resp), s='<tr><th>enumerator</th><th class=\"r\">interviews touched</th><th class=\"r\">med first-pass active min</th><th class=\"r\">med sec/ans</th><th class=\"r\" title=\"enumerator median sec per answer over team median: 0.5 means twice as fast as the team\">vs team</th><th class=\"r\">fast share</th><th class=\"r\">night share</th><th class=\"r\" title=\"shared UTC-minute screening buckets, summed for this actor\">overlap</th><th class=\"r\">flagged</th><th style=\"width:110px\">flag share</th></tr>';"' _n
    file write `fh' `"  var k=Math.min(L.length,30);"' _n
    file write `fh' `"  for(i=0;i<k;i++){"' _n
    file write `fh' `"    var g=L[i];"' _n
    file write `fh' `"    var vst=(g.medmed!==null&&team.med!==null&&team.med>0)?(g.medmed/team.med):null;"' _n
    file write `fh' `"    s+=(g.fl>0?'<tr class=\"hot\">':'<tr>')+'<td>'+esc(g.r)+'</td><td class=\"r\">'+fmtc(g.n)+'</td><td class=\"r\">'+fmt(g.medact)+"' _n
    file write `fh' `"       '</td><td class=\"r\">'+fmt(g.medmed)+'</td><td class=\"r\">'+fmt(vst,2)+'</td><td class=\"r\">'+fmt(g.mfsh,2)+'</td><td class=\"r\">'+fmt(g.mnsh,2)+"' _n
    file write `fh' `"       '</td><td class=\"r\">'+fmtc(g.ov)+'</td><td class=\"r\">'+fmtc(g.fl)+'</td><td><span class=\"bar\" style=\"width:'+Math.round(100*g.share)+'px\"></span> '+fmt(100*g.share)+'%</td></tr>';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  el('t_league').innerHTML=s;"' _n
    file write `fh' `"  el('l_more').textContent = L.length>k ? ('Top '+k+' of '+L.length+' enumerators by flag share.') : '';"' _n
    file write `fh' _n
    file write `fh' `"  renderWorst();"' _n
    file write `fh' `"  renderQuestions();"' _n
    file write `fh' `"  var RV=renderRemovals(S.resp,S.ws);"' _n
    file write `fh' `"  updateSections(A,S,team,acts,DT,L,RV);"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"/* ---- triage sections: live severity, pills, chips, findings ---- */"' _n
    file write `fh' `"var secState=Object.create(null), secDefaultsDone=false;"' _n
    file write `fh' `"function secApply(id){"' _n
    file write `fh' `"  var s=el(id); if(!s) return;"' _n
    file write `fh' `"  var st=secState[id]||(secState[id]={open:false,sev:''});"' _n
    file write `fh' `"  s.className='sblock'+(st.sev?(' sv-'+st.sev):'')+(st.open?' open':'');"' _n
    file write `fh' `"  var b=s.querySelector('.shead');"' _n
    file write `fh' `"  if(b) b.setAttribute('aria-expanded',st.open?'true':'false');"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function secOpen(id,open){ var st=secState[id]||(secState[id]={open:false,sev:''}); st.open=!!open; secApply(id); }"' _n
    file write `fh' `"function secToggle(id){ var st=secState[id]||(secState[id]={open:false,sev:''}); st.open=!st.open; secApply(id); }"' _n
    file write `fh' `"function secSev(id,sev){ var st=secState[id]||(secState[id]={open:false,sev:''}); st.sev=sev||''; secApply(id); }"' _n
    file write `fh' `"function setPill(pid,cid,n,sev){"' _n
    file write `fh' `"  var txt=(n>0)?fmtc(n):'\u2713', cls=(n>0)?sev:'g';"' _n
    file write `fh' `"  var p=el(pid); if(p){ p.textContent=txt; p.className='pillc '+cls; p.style.display=''; }"' _n
    file write `fh' `"  var c=el(cid); if(c){ c.textContent=txt; c.className='n '+cls; c.style.display=''; }"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function setFind(fid,txt){ var f=el(fid); if(f) f.textContent=txt; }"' _n
    file write `fh' `"function plural(n,s,p){ return n===1?s:(p||(s+'s')); }"' _n
    file write `fh' `"function postTabBadge(nA,nV){"' _n
    file write `fh' `"  if(window.parent===window) return;"' _n
    file write `fh' `"  window.parent.postMessage({type:'suso-tab-badge',n:nA+nV,sev:(nA>0?'b':(nV>0?'w':'g'))},'*');"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function initSections(){"' _n
    file write `fh' `"  var i, hs=document.querySelectorAll('.sblock .shead');"' _n
    file write `fh' `"  for(i=0;i<hs.length;i++)(function(b){ b.addEventListener('click',function(){ var s=b.parentNode; if(s&&s.id) secToggle(s.id); }); })(hs[i]);"' _n
    file write `fh' `"  var cs=document.querySelectorAll('.chipx');"' _n
    file write `fh' `"  for(i=0;i<cs.length;i++)(function(a){ a.addEventListener('click',function(ev){"' _n
    file write `fh' `"    if(ev&&ev.preventDefault) ev.preventDefault();"' _n
    file write `fh' `"    var id=a.getAttribute('data-sec'); if(!id) return;"' _n
    file write `fh' `"    secOpen(id,true);"' _n
    file write `fh' `"    var s=el(id); if(s&&s.scrollIntoView) s.scrollIntoView({behavior:'smooth',block:'start'});"' _n
    file write `fh' `"  }); })(cs[i]);"' _n
    file write `fh' `"  var ea=el('e_expall'), ec=el('e_collall'), all=document.querySelectorAll('.sblock'), j;"' _n
    file write `fh' `"  if(ea) ea.addEventListener('click',function(){ for(j=0;j<all.length;j++) if(all[j].id) secOpen(all[j].id,true); });"' _n
    file write `fh' `"  if(ec) ec.addEventListener('click',function(){ for(j=0;j<all.length;j++) if(all[j].id) secOpen(all[j].id,false); });"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function updateSections(A,S,team,acts,DT,L,RV){"' _n
    file write `fh' `"  var tA=A.tiers.A, tV=A.tiers.V, tW=A.tiers.W, i;"' _n
    file write `fh' `"  secSev('s_att', tA>0?'b':(tV>0?'w':'g'));"' _n
    file write `fh' `"  setPill('p_att','cb_att',tA+tV,(tA>0?'b':'w'));"' _n
    file write `fh' `"  setFind('f_att',(tA+tV+tW>0)"' _n
    file write `fh' `"    ? (fmtc(tA)+' investigate + '+fmtc(tV)+' verify'+(tW>0?(' + '+fmtc(tW)+' watch'):'')+' of '+fmtc(A.n)+' in view')"' _n
    file write `fh' `"    : ('No interview meets the attention bar for '+fmtc(A.n)+' in view'));"' _n
    file write `fh' `"  setFind('f_flags', A.flagged.length>0"' _n
    file write `fh' `"    ? (fmtc(A.flagged.length)+' '+plural(A.flagged.length,'interview')+' carr'+(A.flagged.length===1?'ies':'y')+' at least one review signal')"' _n
    file write `fh' `"    : 'No review signals at the current sensitivity');"' _n
    file write `fh' `"  var nz=A.tot[5];"' _n
    file write `fh' `"  secSev('s_dur', nz>0?'w':'g'); setPill('p_dur','cb_dur',nz,'w');"' _n
    file write `fh' `"  setFind('f_dur', acts.length"' _n
    file write `fh' `"    ? (fmtc(acts.length)+' timed - median '+fmt(P.median(acts))+' min (IQR '+fmt(P.pctl(acts,0.25))+'-'+fmt(P.pctl(acts,0.75))+') - '+(nz>0?(fmtc(nz)+' duration '+plural(nz,'outlier')+' at |z| > '+S.z):('no duration outliers at |z| > '+S.z)))"' _n
    file write `fh' `"    : 'No first-pass active-time measurements in view');"' _n
    file write `fh' `"  var ns=A.tot[0];"' _n
    file write `fh' `"  secSev('s_speed', ns>0?'w':'g'); setPill('p_speed','cb_speed',ns,'w');"' _n
    file write `fh' `"  setFind('f_speed',(ns>0?(fmtc(ns)+' '+plural(ns,'interview')+' with a median under '+S.fs+' s'):('No interview medians under '+S.fs+' s'))+(team.med!==null?(' - benchmark median '+fmt(team.med)+' s'):''));"' _n
    file write `fh' `"  var nn=A.tot[3];"' _n
    file write `fh' `"  secSev('s_night', nn>0?'w':'g'); setPill('p_night','cb_night',nn,'w');"' _n
    file write `fh' `"  setFind('f_night', nn>0"' _n
    file write `fh' `"    ? (fmtc(nn)+' '+plural(nn,'interview')+' put over '+Math.round(S.nshare*100)+'% of answers in the '+S.n1+':00-'+S.n2+':00 window')"' _n
    file write `fh' `"    : ('Night answering stays at or under '+Math.round(S.nshare*100)+'% ('+S.n1+':00-'+S.n2+':00 device time)'));"' _n
    file write `fh' `"  var dcs=[]; for(i=0;i<DT.length;i++) dcs.push(DT[i].c);"' _n
    file write `fh' `"  setFind('f_daily', DT.length"' _n
    file write `fh' `"    ? (fmtc(DT.length)+' fieldwork '+plural(DT.length,'day')+' - median '+fmtc(P.median(dcs))+' answer events/day')"' _n
    file write `fh' `"    : 'No dated answer events in view');"' _n
    file write `fh' `"  var fl=0, names=[];"' _n
    file write `fh' `"  for(i=0;i<L.length;i++) if(L[i].fl>0){ fl++; if(names.length<2) names.push(L[i].r); }"' _n
    file write `fh' `"  secSev('s_enum', fl>0?'w':'g'); setPill('p_enum','cb_enum',fl,'w');"' _n
    file write `fh' `"  setFind('f_enum', L.length"' _n
    file write `fh' `"    ? (fmtc(L.length)+' '+plural(L.length,'enumerator')+' in view - '+(fl>0?(fmtc(fl)+' flagged'+((fl===names.length)?(' ('+names.join(', ')+')'):'')):'none flagged'))"' _n
    file write `fh' `"    : 'No enumerator activity in view');"' _n
    file write `fh' `"  var qsrc=P.questionRows(D.q,qActorIndex,S.resp,S.ws), qm=qsrc.length, qf=0;"' _n
    file write `fh' `"  for(i=0;i<qm;i++) if(qsrc[i].med!==null&&qsrc[i].med<S.fs&&qsrc[i].nt>=S.nmin) qf++;"' _n
    file write `fh' `"  secSev('s_qt', qf>0?'w':'g'); setPill('p_qt','cb_qt',qf,'w');"' _n
    file write `fh' `"  setFind('f_qt', qm"' _n
    file write `fh' `"    ? (qf>0?(fmtc(qf)+' of '+fmtc(qm)+' observed '+plural(qm,'question')+' with a median under '+S.fs+' s (at '+S.nmin+'+ timed reaches)'):('No question median under '+S.fs+' s across '+fmtc(qm)+' observed (at '+S.nmin+'+ timed reaches)'))"' _n
    file write `fh' `"    : 'No first-pass answer events in this scope');"' _n
    file write `fh' `"  if(RV&&el('s_rem')){"' _n
    file write `fh' `"    secSev('s_rem', RV.active>0?'w':'g'); setPill('p_rem','cb_rem',RV.active,'w');"' _n
    file write `fh' `"    setFind('f_rem', fmtc(RV.histories)+' '+plural(RV.histories,'history','histories')+' in scope - '+(RV.active>0?(fmtc(RV.active)+' need a final-data check'):'all resolved')+' - '+fmtc(RV.resolved)+' resolved');"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  if(!secDefaultsDone){ secDefaultsDone=true; secOpen('s_att',true); secOpen('s_flags',true); }"' _n
    file write `fh' `"  postTabBadge(tA,tV);"' _n
    file write `fh' `"}"' _n
    file write `fh' `"function initControls(){"' _n
    file write `fh' `"  var rs=Object.create(null), i, names=[];"' _n
    file write `fh' `"  for(i=0;i<D.actors.length;i++) rs[D.actors[i].r]=1;"' _n
    file write `fh' `"  for(var k in rs){ if(Object.prototype.hasOwnProperty.call(rs,k)&&k!=='') names.push(k); }"' _n
    file write `fh' `"  names.sort();"' _n
    file write `fh' `"  var s='<option value=\"\">All enumerators ('+names.length+')</option>';"' _n
    file write `fh' `"  for(i=0;i<names.length;i++) s+='<option value='+Q+attr(names[i])+Q+'>'+esc(names[i])+'</option>';"' _n
    file write `fh' `"  el('c_resp').innerHTML=s;"' _n
    file write `fh' `"  var wsm=Object.create(null), wnames=[], napp=0;"' _n
    file write `fh' `"  for(i=0;i<D.rows.length;i++){ var w=D.rows[i].ws||''; if(w) wsm[w]=(wsm[w]||0)+1; if(D.rows[i].wsc==='approvebyhq'||D.rows[i].wsc==='approvebysup') napp++; }"' _n
    file write `fh' `"  for(var k2 in wsm){ if(Object.prototype.hasOwnProperty.call(wsm,k2)) wnames.push(k2); }"' _n
    file write `fh' `"  wnames.sort();"' _n
    file write `fh' `"  var so='<option value='+Q+Q+'>All statuses</option>';"' _n
    file write `fh' `"  if(napp>0) so+='<option value='+Q+'APP'+Q+'>Approved only (Sup + HQ) ('+napp+')</option>';"' _n
    file write `fh' `"  for(i=0;i<wnames.length;i++) so+='<option value='+Q+attr(wnames[i])+Q+'>'+esc(wnames[i])+' ('+wsm[wnames[i]]+')</option>';"' _n
    file write `fh' `"  el('c_ws').innerHTML=so;"' _n
    file write `fh' `"  var fds=(D.meta&&D.meta.fdims)?D.meta.fdims:[];"' _n
    file write `fh' `"  if(fds.length){"' _n
    file write `fh' `"    var fo='<option value='+Q+Q+'>None</option>';"' _n
    file write `fh' `"    for(i=0;i<fds.length;i++) fo+='<option>'+esc(fds[i].v)+'</option>';"' _n
    file write `fh' `"    el('c_fd').innerHTML=fo;"' _n
    file write `fh' `"    fvOptions();"' _n
    file write `fh' `"    el('c_fd').addEventListener('change',function(){ fvOptions(); renderAll(); });"' _n
    file write `fh' `"  } else {"' _n
    file write `fh' `"    el('ctl_fd').style.display='none';"' _n
    file write `fh' `"    el('ctl_fv').style.display='none';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  var hsel='';"' _n
    file write `fh' `"  for(i=0;i<24;i++) hsel+='<option>'+i+'</option>';"' _n
    file write `fh' `"  el('c_n1').innerHTML=hsel; el('c_n2').innerHTML=hsel;"' _n
    file write `fh' `"  el('c_n1').value=22; el('c_n2').value=6;"' _n
    file write `fh' `"  el('c_fs').value=D.meta.fastsecs;"' _n
    file write `fh' `"  el('c_preset').value='standard';"' _n
    file write `fh' `"  el('c_adv').addEventListener('click',function(){"' _n
    file write `fh' `"    var a=el('advrow');"' _n
    file write `fh' `"    a.style.display=(a.style.display==='none')?'flex':'none';"' _n
    file write `fh' `"  });"' _n
    file write `fh' `"  el('c_preset').addEventListener('change',function(){ applyPreset(el('c_preset').value); renderAll(); });"' _n
    file write `fh' `"  el('c_resp').addEventListener('change',function(){ renderAll(); postActorFilter(); });"' _n
    file write `fh' `"  el('c_ws').addEventListener('change',function(){renderAll();postStatusFilter();});"' _n
    file write `fh' `"  var simp=['c_fv','c_top'];"' _n
    file write `fh' `"  for(i=0;i<simp.length;i++) el(simp[i]).addEventListener('change',renderAll);"' _n
    file write `fh' `"  var adv=['c_fs','c_burst','c_minact','c_n1','c_n2','c_nshare','c_churn','c_z','c_peer','c_ov','c_nmin'];"' _n
    file write `fh' `"  for(i=0;i<adv.length;i++) el(adv[i]).addEventListener('change',function(){ el('c_preset').value='custom'; renderAll(); });"' _n
    file write `fh' `"  el('c_q').addEventListener('input',renderQuestions);"' _n
    file write `fh' `"  el('c_qorder').addEventListener('click',function(){qSortKey='o';qSortDir=-1;renderQuestions();});"' _n
    file write `fh' `"  el('c_reset').addEventListener('click',resetSettings);"' _n
    file write `fh' `"  el('c_csv').addEventListener('click',function(){"' _n
    file write `fh' `"    if(!lastA) return;"' _n
    file write `fh' `"    var body=P.csv(lastA.flagged,lastS,lastTeam,D.meta);"' _n
    file write `fh' `"    var a=document.createElement('a');"' _n
    file write `fh' `"    a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(body);"' _n
    file write `fh' `"    a.download='suso_review_list.csv';"' _n
    file write `fh' `"    document.body.appendChild(a); a.click(); document.body.removeChild(a);"' _n
    file write `fh' `"  });"' _n
    file write `fh' `"  el('t_worst').addEventListener('click',function(ev){"' _n
    file write `fh' `"    var t=ev.target||ev.srcElement;"' _n
    file write `fh' `"    if(t && t.className && String(t.className).indexOf('hv-open')>=0){"' _n
    file write `fh' `"      if(window.susoOpenHistory) window.susoOpenHistory(t.getAttribute('data-history-id')||'');"' _n
    file write `fh' `"      return;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    if(t && t.className && String(t.className).indexOf('cpy')>=0){"' _n
    file write `fh' `"      copyText(t.getAttribute('data-t')||'');"' _n
    file write `fh' `"      t.textContent='copied';"' _n
    file write `fh' `"      return;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    while(t && t!==this && (!t.getAttribute || t.getAttribute('data-i')===null)) t=t.parentNode;"' _n
    file write `fh' `"    if(t && t.getAttribute && t.getAttribute('data-i')!==null){"' _n
    file write `fh' `"      var r=lastA.flagged[parseInt(t.getAttribute('data-i'),10)];"' _n
    file write `fh' `"      if(r){ expOpen[r.id]=!expOpen[r.id]; renderWorst(); }"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"  });"' _n
    file write `fh' `"  if(D.meta.lite===1){"' _n
    file write `fh' `"    el('c_n1').disabled=true; el('c_n2').disabled=true; el('c_fs').disabled=true;"' _n
    file write `fh' `"    el('lite_note').textContent='Large survey: per-interview hour/gap detail was not embedded, so the night window and fast-seconds controls use the values fixed at build time.';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"}"' _n
    file write `fh' `"initControls();"' _n
    file write `fh' `"initSections();"' _n
    file write `fh' `"renderAll();"' _n
    file write `fh' `"}"' _n
    file write `fh' _n
    file write `fh' `"</script></body></html>"' _n
end

* ---- one canonical current/final workflow-status map ---------------------------
* The Behaviour queue and Question timing must use the same status definition:
* final data wins when data() supplies interview__status; otherwise use the last
* recognized workflow event, falling back to In progress after fieldwork starts.
program _suso_para_statusmap, rclass
    version 14.2
    syntax , SAVing(string) [DATA(string) replace]
    _suso_para_need events

    tempfile BASE DATAWS
    local hasdataws 0
    local hasparastatus 0

    preserve
        tempvar started evn
        quietly keep interview__id para_fieldans para_fieldrem para_fieldcmp ///
            para_fieldrst para_ev para_ord para_seq
        quietly sort interview__id para_ord para_seq
        quietly by interview__id: egen byte `started' = max(                 ///
            para_fieldans | para_fieldrem | para_fieldcmp | para_fieldrst)
        quietly gen str40 `evn' = subinstr(subinstr(para_ev, "approved",      ///
            "approve", .), "rejected", "reject", .)
        quietly gen str40 ws_paradata = ""
        quietly replace ws_paradata = "Completed"       if `evn'=="completed"
        quietly replace ws_paradata = "In progress"     if `evn'=="restarted"
        quietly replace ws_paradata = "Approved by Sup" if `evn'=="approvebysupervisor"
        quietly replace ws_paradata = "Rejected by Sup" if `evn'=="rejectbysupervisor"
        quietly replace ws_paradata = "Approved by HQ"  if inlist(`evn',     ///
            "approvebyheadquarter", "approvebyheadquarters")
        quietly replace ws_paradata = "Rejected by HQ"  if inlist(`evn',     ///
            "rejectbyheadquarter", "rejectbyheadquarters")
        quietly replace ws_paradata = "Unapproved by HQ" if                  ///
            `evn'=="unapprovebyheadquarters"
        quietly count if ws_paradata!=""
        local hasparastatus = r(N)>0
        quietly by interview__id: replace ws_paradata = ws_paradata[_n-1]     ///
            if ws_paradata=="" & _n>1
        quietly by interview__id: keep if _n==_N
        quietly replace ws_paradata = "" if !`started'
        quietly replace ws_paradata = "In progress" if ws_paradata=="" & `started'
        quietly keep interview__id ws_paradata
        quietly save `"`BASE'"'
    restore

    if `"`data'"'!="" {
        preserve
            quietly use `"`data'"', clear
            capture confirm string variable interview__id, exact
            if _rc {
                di as err "suso paradata report: data() requires a string interview__id variable."
                di as err "                         Use the one-row-per-interview Survey Solutions main export."
                exit 459
            }
            capture confirm variable interview__status, exact
            if !_rc {
                tempvar wsdata wsdup
                capture confirm string variable interview__status
                if !_rc quietly gen str244 `wsdata' = strtrim(interview__status)
                else {
                    capture decode interview__status, gen(`wsdata')
                    if _rc {
                        capture quietly drop `wsdata'
                        quietly gen str244 `wsdata' = strtrim(strofreal(        ///
                            interview__status,"%18.0g"))
                        quietly replace `wsdata' = "Deleted"                if interview__status==-1
                        quietly replace `wsdata' = "Restored"               if interview__status==0
                        quietly replace `wsdata' = "Created"                if interview__status==20
                        quietly replace `wsdata' = "SupervisorAssigned"     if interview__status==40
                        quietly replace `wsdata' = "InterviewerAssigned"    if interview__status==60
                        quietly replace `wsdata' = "RejectedBySupervisor"   if interview__status==65
                        quietly replace `wsdata' = "ReadyForInterview"      if interview__status==80
                        quietly replace `wsdata' = "SentToCapi"             if interview__status==85
                        quietly replace `wsdata' = "Restarted"              if interview__status==95
                        quietly replace `wsdata' = "Completed"              if interview__status==100
                        quietly replace `wsdata' = "ApprovedBySupervisor"   if interview__status==120
                        quietly replace `wsdata' = "RejectedByHeadquarters" if interview__status==125
                        quietly replace `wsdata' = "ApprovedByHeadquarters" if interview__status==130
                    }
                    else quietly replace `wsdata' = strtrim(`wsdata')
                    quietly replace `wsdata' = "" if missing(interview__status)
                }
                quietly keep interview__id `wsdata'
                quietly rename `wsdata' ws_data
                quietly duplicates drop
                quietly bysort interview__id: gen byte `wsdup' = _N>1
                quietly count if `wsdup'
                if r(N)>0 {
                    di as err "suso paradata report: data() has duplicate interview__id rows with conflicting interview__status values."
                    di as err "                         Supply a one-row-per-interview main export."
                    exit 459
                }
                quietly drop `wsdup'
                quietly bysort interview__id: keep if _n==1
                quietly save `"`DATAWS'"'
                local hasdataws 1
            }
        restore
    }

    preserve
        quietly use `"`BASE'"', clear
        if `hasdataws' quietly merge 1:1 interview__id using `"`DATAWS'"',    ///
            keep(master match) nogenerate
        else quietly gen str244 ws_data = ""
        quietly replace ws_data = "" if missing(ws_data)
        quietly gen str244 ws = cond(ws_data!="",ws_data,ws_paradata)
        tempvar wspn wsdn
        quietly gen str244 `wspn' = lower(subinstr(strtrim(ws_paradata)," ","",.))
        quietly gen str244 `wsdn' = lower(subinstr(strtrim(ws_data)," ","",.))
        foreach vv in `wspn' `wsdn' {
            quietly replace `vv' = subinstr(`vv',"headquarters","hq",.)
            quietly replace `vv' = subinstr(`vv',"headquarter","hq",.)
            quietly replace `vv' = subinstr(`vv',"supervisor","sup",.)
            quietly replace `vv' = subinstr(`vv',"approved","approve",.)
            quietly replace `vv' = subinstr(`vv',"rejected","reject",.)
            quietly replace `vv' = "inprogress" if inlist(`vv',"restart","restarted")
        }
        quietly gen byte ws_mismatch = ws_data!="" & ws_paradata!="" &       ///
            `wsdn'!=`wspn'
        quietly gen str12 ws_source = cond(ws_data!="","final data","paradata")
        quietly gen str40 ws_class = cond(`wsdn'!="",`wsdn',`wspn')
        quietly drop `wspn' `wsdn'
        label variable ws "display workflow status (final data preferred)"
        label variable ws_paradata "workflow state at last paradata event"
        label variable ws_data "interview__status in final data"
        label variable ws_mismatch "paradata/final-data status mismatch"
        quietly keep interview__id ws ws_paradata ws_data ws_source ws_class ws_mismatch
        if "`replace'"!="" quietly save `"`saving'"', replace
        else quietly save `"`saving'"'
    restore

    return scalar hasdataws = `hasdataws'
    return scalar hasparastatus = `hasparastatus'
end

* ---- compact exact Question-timing payload -------------------------------------
* Status scopes are computed from raw eligible events so p50/p90 and fast-share
* remain exact.  Each event contributes to its exact status, All statuses (""),
* and, when applicable, the combined Sup+HQ Approved scope ("APP").
program _suso_para_questionpayload, rclass
    version 14.2
    syntax , STATUSMap(string) QSAVing(string) AQSAVing(string)              ///
        PEERSAVing(string) [VARS(string) QORDER(string)]
    _suso_para_need events

    local haspeerq 0
    local hasq 0
    local hasaq 0

    preserve
        capture confirm variable para_var
        if !_rc {
            quietly keep para_fieldans para_firstpass para_cawi para_var     ///
                para_ansgap
            quietly keep if para_fieldans & para_firstpass & !para_cawi &    ///
                para_var!="" & !missing(para_ansgap)
            if _N>0 {
                local haspeerq 1
                quietly keep para_var para_ansgap
                quietly compress
                collapse (p50) qmed=para_ansgap, by(para_var) fast
                quietly keep if !missing(qmed)
                quietly save `"`peersaving'"'
            }
        }
    restore

    preserve
        capture confirm variable para_var
        local hasvar = !_rc
        if `hasvar' {
            local __qseq ""
            capture confirm variable para_seq, exact
            if !_rc local __qseq para_seq
            quietly keep interview__id para_actor para_actor_key para_var    ///
                para_one para_fast para_ansgap para_fieldans para_firstpass  ///
                para_ans para_rem para_ev `__qseq'
            if "`__qseq'"=="" quietly gen double para_seq = .
            quietly keep if para_fieldans & para_firstpass & para_var!=""
        }
        if `hasvar' & _N>0 _suso_para_varsel , vars(`"`vars'"')
        if `hasvar' & _N>0 {
            local hasq 1
            * One invariant display rank is shared by every actor/status scope.
            * With qx(), the parser's DOM row order is the static questionnaire
            * design/CAPI order.  Variables absent from that preview follow it
            * alphabetically.  Without qx(), the first source event is the
            * deterministic fallback (then variable name when source order is
            * unavailable or tied).  Scope-specific first occurrences must not
            * reshuffle the table when a user changes a filter.
            * Assign the invariant rank directly on eligible event rows.  The
            * earlier implementation opened a second preserve here while this
            * program's caller dataset was already preserved, which Stata
            * correctly rejected with r(621).  Direct ranking also avoids
            * writing and rereading a multi-million-row temporary copy.
            if `"`qorder'"'!="" {
                quietly merge m:1 para_var using `"`qorder'"',             ///
                    keep(master match) nogenerate
                tempvar qunknown
                quietly gen byte `qunknown' = missing(qx_order)
                quietly egen long qorder = group(`qunknown' qx_order       ///
                    para_var), missing
                quietly drop qx_order `qunknown'
            }
            else {
                tempvar qfirst qnoseq
                quietly egen double `qfirst' = min(para_seq), by(para_var)
                quietly gen byte `qnoseq' = missing(`qfirst')
                quietly egen long qorder = group(`qnoseq' `qfirst'         ///
                    para_var), missing
                quietly drop `qfirst' `qnoseq'
            }
            quietly drop para_fieldans para_firstpass para_ans para_rem para_ev
            quietly compress
            quietly merge m:1 interview__id using `"`statusmap'"',           ///
                keep(master match) nogenerate keepusing(ws ws_class)
            tempvar oid app copies which qstatus qscope tag scopestr
            * Collapse on a compact numeric status key.  Carrying a str244
            * status through a 2x/3x expansion is needlessly expensive on a
            * multi-million-event survey.
            quietly egen long `qstatus' = group(ws), label
            quietly clonevar `qscope' = `qstatus'
            quietly gen long `oid' = _n
            quietly gen byte `app' = inlist(ws_class,"approvebyhq","approvebysup")
            quietly gen byte `copies' = 2 + `app'
            quietly drop ws ws_class `qstatus'
            quietly expand `copies'
            quietly bysort `oid': gen byte `which' = _n
            quietly replace `qscope' = 0  if `which'==2
            quietly replace `qscope' = -1 if `which'==3
            quietly drop `app' `copies' `which' `oid'
            quietly compress
            tempfile QEVENTS
            quietly save `"`QEVENTS'"'

            quietly bysort `qscope' para_var interview__id: gen byte `tag' = _n==1
            collapse (sum) qn=para_one qni=`tag' qnf=para_fast              ///
                (count) qnt=para_ansgap                                    ///
                (p50) qmed=para_ansgap (p90) qp90=para_ansgap,             ///
                by(`qscope' qorder para_var) fast
            quietly gen double qfsh = qnf/qnt if qnt>0
            quietly decode `qscope', gen(`scopestr')
            quietly replace `scopestr' = ""    if `qscope'==0
            quietly replace `scopestr' = "APP" if `qscope'==-1
            quietly drop `qscope'
            quietly rename `scopestr' qscope
            quietly sort qscope qorder para_var
            quietly save `"`qsaving'"'

            quietly use `"`QEVENTS'"', clear
            quietly keep if para_actor_key!=""
            if _N>0 {
                local hasaq 1
                tempvar atag
                quietly bysort para_actor_key `qscope' para_var interview__id: ///
                    gen byte `atag' = _n==1
                collapse (sum) aqn=para_one aqni=`atag' aqnf=para_fast       ///
                    (count) aqnt=para_ansgap                                ///
                    (p50) aqmed=para_ansgap (p90) aqp90=para_ansgap         ///
                    (first) aq_actor=para_actor,                            ///
                    by(para_actor_key `qscope' qorder para_var) fast
                quietly gen double aqfsh = aqnf/aqnt if aqnt>0
                quietly decode `qscope', gen(`scopestr')
                quietly replace `scopestr' = ""    if `qscope'==0
                quietly replace `scopestr' = "APP" if `qscope'==-1
                quietly drop `qscope'
                quietly rename `scopestr' qscope
                quietly sort para_actor_key qscope qorder para_var
                quietly save `"`aqsaving'"'
            }
        }
    restore

    return scalar haspeerq = `haspeerq'
    return scalar hasq = `hasq'
    return scalar hasaq = `hasaq'
end

* ---- browser-only raw event-history explorer ---------------------------------
* The report never embeds the multi-million-row source.  The user explicitly
* selects paradata.tab in the browser; a Web Worker scans it in bounded chunks,
* keeps only a compact interview-to-byte-range index, and reads one interview on
* demand.  Keeping this static engine in its own program also preserves Stata's
* fixed per-program compiler headroom.
program _suso_para_history_js
    version 14.2
    args fh
    if "`fh'"=="" {
        di as err "suso internal error: history-viewer file handle was not supplied."
        exit 198
    }
    file write `fh' `"<script>"' _n
    file write `fh' `"/* suso raw history viewer - local file only; no source events are embedded or uploaded. */"' _n
    file write `fh' `"function historyCoreFactory(){"' _n
    file write `fh' `"  'use strict';"' _n
    file write `fh' `"  var decoder=new TextDecoder('utf-8',{fatal:true});"' _n
    file write `fh' `"  function decode(bytes){return decoder.decode(bytes);}"' _n
    file write `fh' `"  function decodeField(raw){"' _n
    file write `fh' `"    var i,out;"' _n
    file write `fh' `"    if(raw.length>=2&&raw[0]===34&&raw[raw.length-1]===34){"' _n
    file write `fh' `"      out=[];"' _n
    file write `fh' `"      for(i=1;i<raw.length-1;i++){if(raw[i]===34&&raw[i+1]===34){out.push(34);i++;}else out.push(raw[i]);}"' _n
    file write `fh' `"      return decode(new Uint8Array(out));"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    return decode(raw);"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function parseRecord(bytes,quoted){"' _n
    file write `fh' `"    var out=[],start=0,i=0,inQ=false,atStart=true,c;"' _n
    file write `fh' `"    if(!quoted){for(i=0;i<=bytes.length;i++)if(i===bytes.length||bytes[i]===9){out.push(decode(bytes.subarray(start,i)));start=i+1;}return out;}"' _n
    file write `fh' `"    while(i<=bytes.length){"' _n
    file write `fh' `"      if(i===bytes.length){out.push(decodeField(bytes.subarray(start,i)));break;}"' _n
    file write `fh' `"      c=bytes[i];"' _n
    file write `fh' `"      if(inQ){if(c===34){if(bytes[i+1]===34){i+=2;continue;}inQ=false;}i++;continue;}"' _n
    file write `fh' `"      if(c===34&&atStart){inQ=true;atStart=false;i++;continue;}"' _n
    file write `fh' `"      if(c===9){out.push(decodeField(bytes.subarray(start,i)));start=i+1;atStart=true;i++;continue;}"' _n
    file write `fh' `"      atStart=false;i++;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    return out;"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function field(bytes,target,quoted){"' _n
    file write `fh' `"    var col=0,start=0,i=0,inQ=false,atStart=true,c;"' _n
    file write `fh' `"    if(!quoted){for(i=0;i<=bytes.length;i++)if(i===bytes.length||bytes[i]===9){if(col===target)return decode(bytes.subarray(start,i));col++;start=i+1;}return '';}"' _n
    file write `fh' `"    while(i<=bytes.length){"' _n
    file write `fh' `"      if(i===bytes.length||(!inQ&&bytes[i]===9)){"' _n
    file write `fh' `"        if(col===target)return decodeField(bytes.subarray(start,i));"' _n
    file write `fh' `"        col++;start=i+1;atStart=true;i++;continue;"' _n
    file write `fh' `"      }"' _n
    file write `fh' `"      c=bytes[i];"' _n
    file write `fh' `"      if(inQ){if(c===34){if(bytes[i+1]===34){i+=2;continue;}inQ=false;}i++;continue;}"' _n
    file write `fh' `"      if(c===34&&atStart){inQ=true;atStart=false;i++;continue;}"' _n
    file write `fh' `"      atStart=false;i++;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    return '';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function walkRecords(bytes,eof,onRecord,quoted){"' _n
    file write `fh' `"    var start=0,i=0,inQ=false,atStart=true,c,end,dataEnd;"' _n
    file write `fh' `"    if(!quoted){while(i<bytes.length){c=bytes[i];if(c===10||c===13){if(c===13&&i+1===bytes.length&&!eof)break;dataEnd=i;end=(c===13&&bytes[i+1]===10)?i+2:i+1;onRecord(bytes.subarray(start,dataEnd),start,end);start=end;i=end;}else i++;}if(eof){if(start<bytes.length)onRecord(bytes.subarray(start),start,bytes.length);return bytes.length;}return start;}"' _n
    file write `fh' `"    while(i<bytes.length){"' _n
    file write `fh' `"      c=bytes[i];"' _n
    file write `fh' `"      if(inQ){if(c===34){if(bytes[i+1]===34){i+=2;continue;}inQ=false;}i++;continue;}"' _n
    file write `fh' `"      if(c===34&&atStart){inQ=true;atStart=false;i++;continue;}"' _n
    file write `fh' `"      if(c===9){atStart=true;i++;continue;}"' _n
    file write `fh' `"      if(c===10||c===13){"' _n
    file write `fh' `"        if(c===13&&i+1===bytes.length&&!eof)break;"' _n
    file write `fh' `"        dataEnd=i;end=(c===13&&bytes[i+1]===10)?i+2:i+1;"' _n
    file write `fh' `"        onRecord(bytes.subarray(start,dataEnd),start,end);"' _n
    file write `fh' `"        start=end;i=end;inQ=false;atStart=true;continue;"' _n
    file write `fh' `"      }"' _n
    file write `fh' `"      atStart=false;i++;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    if(eof){"' _n
    file write `fh' `"      if(inQ)throw new Error('Unterminated quoted field near byte '+start+'.');"' _n
    file write `fh' `"      if(start<bytes.length)onRecord(bytes.subarray(start),start,bytes.length);"' _n
    file write `fh' `"      return bytes.length;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    return start;"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function normHeader(s){return String(s||'').replace(/^\uFEFF/,'').trim().toLowerCase();}"' _n
    file write `fh' `"  function normId(s){return String(s||'').trim().toLowerCase();}"' _n
    file write `fh' `"  function find(headers,names,required){"' _n
    file write `fh' `"    var i,j,n=headers.map(normHeader);"' _n
    file write `fh' `"    for(i=0;i<names.length;i++){j=n.indexOf(names[i]);if(j>=0)return j;}"' _n
    file write `fh' `"    if(required)throw new Error('Required column not found: '+names[0]+'.');"' _n
    file write `fh' `"    return -1;"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function schema(headers){"' _n
    file write `fh' `"    var utc=find(headers,['timestamp_utc'],false),legacy=find(headers,['timestamp'],false);"' _n
    file write `fh' `"    if(utc<0&&legacy<0)throw new Error('Required timestamp_utc/timestamp column not found.');"' _n
    file write `fh' `"    return {headers:headers,id:find(headers,['interview__id','interview_id'],true),order:find(headers,['order'],false),event:find(headers,['event','action'],true),responsible:find(headers,['responsible'],false),role:find(headers,['role'],false),timestamp:utc>=0?utc:legacy,sourceUtc:utc>=0,tz:find(headers,['tz_offset','offset'],false),parameters:find(headers,['parameters'],false)};"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function value(values,i){return i>=0&&i<values.length?values[i]:'';}"' _n
    file write `fh' `"  function rowFrom(values,s,seq,byte){return {order:value(values,s.order),event:value(values,s.event),responsible:value(values,s.responsible),role:value(values,s.role),timestamp:value(values,s.timestamp),tz:value(values,s.tz),parameters:value(values,s.parameters),seq:seq,byte:byte};}"' _n
    file write `fh' `"  function offsetSeconds(s){"' _n
    file write `fh' `"    var m=String(s||'').trim().match(/^([+-])?(\d{1,2}):(\d{2})(?::(\d{2}))?$/),v;"' _n
    file write `fh' `"    if(!m)return null;v=Number(m[2])*3600+Number(m[3])*60+Number(m[4]||0);"' _n
    file write `fh' `"    if(Number(m[2])>14||Number(m[3])>59||Number(m[4]||0)>59||v>50400)return null;"' _n
    file write `fh' `"    return m[1]==='-'?-v:v;"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function partsMs(s){"' _n
    file write `fh' `"    var m=String(s||'').trim().match(/^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,3}))?/);"' _n
    file write `fh' `"    if(!m)return null;return Date.UTC(+m[1],+m[2]-1,+m[3],+m[4],+m[5],+m[6],+(m[7]||'0').padEnd(3,'0'));"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function pad(n,w){var s=String(n);while(s.length<w)s='0'+s;return s;}"' _n
    file write `fh' `"  function formatMs(ms){"' _n
    file write `fh' `"    if(ms===null||!isFinite(ms))return '';var d=new Date(ms);"' _n
    file write `fh' `"    return pad(d.getUTCFullYear(),4)+'-'+pad(d.getUTCMonth()+1,2)+'-'+pad(d.getUTCDate(),2)+' '+pad(d.getUTCHours(),2)+':'+pad(d.getUTCMinutes(),2)+':'+pad(d.getUTCSeconds(),2)+'.'+pad(d.getUTCMilliseconds(),3);"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function timeInfo(row,sourceUtc){"' _n
    file write `fh' `"    var off=offsetSeconds(row.tz),base=partsMs(row.timestamp),utc=null,local=null;"' _n
    file write `fh' `"    if(sourceUtc){utc=base;if(base!==null&&off!==null)local=base+off*1000;}"' _n
    file write `fh' `"    else{local=base;if(base!==null&&off!==null)utc=base-off*1000;}"' _n
    file write `fh' `"    return {utcMs:utc,localMs:local,utc:formatMs(utc),local:formatMs(local),offset:off};"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function kind(event){"' _n
    file write `fh' `"    var e=String(event||'').toLowerCase();"' _n
    file write `fh' `"    if(e.indexOf('answerremoved')>=0||e.indexOf('disabled')>=0||e.indexOf('invalid')>=0)return 'warn';"' _n
    file write `fh' `"    if(e.indexOf('answerset')>=0)return 'answer';"' _n
    file write `fh' `"    if(e.indexOf('completed')>=0||e.indexOf('approved')>=0||e.indexOf('rejected')>=0||e.indexOf('assigned')>=0||e.indexOf('received')>=0)return 'workflow';"' _n
    file write `fh' `"    if(e.indexOf('paused')>=0||e.indexOf('resumed')>=0||e.indexOf('started')>=0||e.indexOf('created')>=0)return 'session';"' _n
    file write `fh' `"    return 'system';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function matches(row,q){"' _n
    file write `fh' `"    q=String(q||'').trim().toLowerCase();if(!q)return true;"' _n
    file write `fh' `"    return [row.order,row.event,row.responsible,row.role,row.timestamp,row.tz,row.parameters].join(' ').toLowerCase().indexOf(q)>=0;"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function orderValue(s){var t=String(s||'').trim();if(!/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$/.test(t))return null;var n=Number(t);return isFinite(n)?n:null;}"' _n
    file write `fh' `"  function orderRows(rows){"' _n
    file write `fh' `"    return rows.sort(function(a,b){var x=orderValue(a.order),y=orderValue(b.order);x=x===null?a.seq:x;y=y===null?b.seq:y;if(x!==y)return x-y;return a.seq-b.seq;});"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function formatBytes(n){var u=['B','KB','MB','GB','TB'],i=0,x=Number(n)||0;while(x>=1024&&i<u.length-1){x/=1024;i++;}return x.toFixed(i?1:0)+' '+u[i];}"' _n
    file write `fh' `"  return {decode:decode,parseRecord:parseRecord,field:field,walkRecords:walkRecords,normId:normId,schema:schema,rowFrom:rowFrom,offsetSeconds:offsetSeconds,timeInfo:timeInfo,kind:kind,matches:matches,orderValue:orderValue,orderRows:orderRows,formatBytes:formatBytes};"' _n
    file write `fh' `"}"' _n
    file write `fh' `"var HCore=historyCoreFactory();"' _n
    file write `fh' `"if(typeof module!=='undefined'&&module.exports)module.exports=HCore;"' _n
    file write `fh' `"function historyCompactFactory(){"' _n
    file write `fh' `"  'use strict';"' _n
    file write `fh' `"  var WD=['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],MO=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];"' _n
    file write `fh' `"  function pad2(n,w){var s=String(n);while(s.length<w)s='0'+s;return s;}"' _n
    file write `fh' `"  function clock(ms){var d=new Date(ms);return pad2(d.getUTCHours(),2)+':'+pad2(d.getUTCMinutes(),2)+':'+pad2(d.getUTCSeconds(),2)+'.'+pad2(d.getUTCMilliseconds(),3);}"' _n
    file write `fh' `"  function dayLabel(ms){var d=new Date(ms);return WD[d.getUTCDay()]+' '+d.getUTCDate()+' '+MO[d.getUTCMonth()]+' '+pad2(d.getUTCFullYear(),4);}"' _n
    file write `fh' `"  function shortDur(x){if(x<1000)return x+' ms';if(x<60000)return (x/1000).toFixed(x<10000?1:0)+' s';if(x<3600000)return (x/60000).toFixed(1)+' min';if(x<86400000)return (x/3600000).toFixed(1)+' h';return (x/86400000).toFixed(1)+' d';}"' _n
    file write `fh' `"  function compactGap(ms){"' _n
    file write `fh' `"    if(ms===null||ms===undefined)return null;"' _n
    file write `fh' `"    if(ms<0)return {cls:'rev',txt:'-'+shortDur(-ms),title:'clock reversal: timestamped '+shortDur(-ms)+' before the previous event'};"' _n
    file write `fh' `"    if(ms<1000)return null;"' _n
    file write `fh' `"    if(ms<60000)return {cls:'g1',txt:'+'+(ms<10000?(ms/1000).toFixed(1):String(Math.round(ms/1000)))+' s',title:'quiet gap since the previous event'};"' _n
    file write `fh' `"    return {cls:'g2',txt:'+'+shortDur(ms),title:'quiet gap since the previous event'};"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function rowClock(t){"' _n
    file write `fh' `"    if(t&&t.localMs!==null&&t.localMs!==undefined)return {ms:t.localMs,src:'local'};"' _n
    file write `fh' `"    if(t&&t.utcMs!==null&&t.utcMs!==undefined)return {ms:t.utcMs,src:'utc'};"' _n
    file write `fh' `"    return {ms:null,src:'none'};"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  /* plan() expects rows already annotated by the viewer: _time from HCore.timeInfo and _gap in ms. */"' _n
    file write `fh' `"  function plan(rows,breakMs){"' _n
    file write `fh' `"    var out=[],prevDay=null,prevOff=null,prevTime=null,prevActor=null,i,r,t,c,day,off,g,pill,tstr,actor,mins;"' _n
    file write `fh' `"    if(!(breakMs>0))breakMs=1800000;"' _n
    file write `fh' `"    mins=Math.round(breakMs/60000);"' _n
    file write `fh' `"    for(i=0;i<rows.length;i++){"' _n
    file write `fh' `"      r=rows[i];t=r._time||{};c=rowClock(t);"' _n
    file write `fh' `"      day=c.ms===null?'(no valid timestamp)':dayLabel(c.ms)+(c.src==='utc'?' (UTC clock)':'');"' _n
    file write `fh' `"      off=String(r.tz||'').trim();if(!off)off='(missing)';"' _n
    file write `fh' `"      if(day!==prevDay||off!==prevOff){out.push({k:'day',label:day+' - UTC offset '+off});prevDay=day;prevOff=off;prevTime=null;prevActor=null;}"' _n
    file write `fh' `"      g=(r._gap===undefined)?null:r._gap;pill=null;"' _n
    file write `fh' `"      if(g!==null&&g>=breakMs){out.push({k:'gap',label:shortDur(g)+' pause - at or beyond the '+mins+' min session gap cap',ms:g});prevTime=null;prevActor=null;}"' _n
    file write `fh' `"      else pill=compactGap(g);"' _n
    file write `fh' `"      tstr=c.ms===null?'':clock(c.ms);"' _n
    file write `fh' `"      actor=(r.responsible||'(no responsible actor)')+(r.role?' - '+r.role:'');"' _n
    file write `fh' `"      out.push({k:'r',r:r,i:i,t:tstr,tsrc:c.src,dimT:tstr!==''&&tstr===prevTime,actor:actor,dimA:actor===prevActor,pill:pill});"' _n
    file write `fh' `"      if(tstr!=='')prevTime=tstr;"' _n
    file write `fh' `"      prevActor=actor;"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    return out;"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  return {plan:plan,compactGap:compactGap,shortDur:shortDur,dayLabel:dayLabel,clock:clock};"' _n
    file write `fh' `"}"' _n
    file write `fh' `"var HCompact=historyCompactFactory();"' _n
    file write `fh' `"function historyWorkerMain(){"' _n
    file write `fh' `"  'use strict';"' _n
    file write `fh' `"  var file=null,index=null,keys=[],schema=null,token=0,scanMode=false,quoted=false,CHUNK=4*1024*1024,MAX_RANGES=500000;"' _n
    file write `fh' `"  function send(x){self.postMessage(x);}"' _n
    file write `fh' `"  function cat(a,b){var c=new Uint8Array(a.length+b.length);c.set(a);c.set(b,a.length);return c;}"' _n
    file write `fh' `"  async function scan(start,end,onRecord,onProgress,myToken){"' _n
    file write `fh' `"    var offset=start,carry=new Uint8Array(0),buf,chunk,base,tail,lim;"' _n
    file write `fh' `"    while(offset<end){"' _n
    file write `fh' `"      if(myToken!==token)throw new Error('Cancelled');"' _n
    file write `fh' `"      lim=Math.min(end,offset+CHUNK);chunk=new Uint8Array(await file.slice(offset,lim).arrayBuffer());"' _n
    file write `fh' `"      base=offset-carry.length;buf=carry.length?cat(carry,chunk):chunk;"' _n
    file write `fh' `"      tail=HCore.walkRecords(buf,false,function(rec,s,e){onRecord(rec,base+s,base+e);},quoted);"' _n
    file write `fh' `"      carry=buf.slice(tail);offset=lim;if(onProgress)onProgress(offset,end);"' _n
    file write `fh' `"      if(carry.length>64*1024*1024)throw new Error('A single TSV record exceeds 64 MB or has an unterminated quoted field.');"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    base=end-carry.length;HCore.walkRecords(carry,true,function(rec,s,e){onRecord(rec,base+s,base+e);},quoted);"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  async function build(f,useQuoted){"' _n
    file write `fh' `"    var my=++token,first=true,rows=0,dataRow=0,ranges=0,blank=0,lastPost=0;file=f;quoted=!!useQuoted;index=new Map();keys=[];schema=null;scanMode=false;"' _n
    file write `fh' `"    await scan(0,file.size,function(rec,start,end){"' _n
    file write `fh' `"      var head,id,key,entry,r;"' _n
    file write `fh' `"      if(!rec.length)return;"' _n
    file write `fh' `"      if(first){head=HCore.parseRecord(rec,quoted);schema=HCore.schema(head);first=false;return;}"' _n
    file write `fh' `"      dataRow++;id=HCore.field(rec,schema.id,quoted).trim();if(!id){blank++;return;}key=HCore.normId(id);"' _n
    file write `fh' `"      entry=index.get(key);if(!entry){entry={id:id,ranges:[],n:0};index.set(key,entry);}"' _n
    file write `fh' `"      r=entry.ranges;if(!scanMode){if(r.length&&r[r.length-1][1]===start){r[r.length-1][1]=end;r[r.length-1][3]++;}else{r.push([start,end,dataRow,1]);ranges++;if(ranges>MAX_RANGES){scanMode=true;ranges=0;index.forEach(function(x){x.ranges=[];});}}}"' _n
    file write `fh' `"      entry.n++;rows++;"' _n
    file write `fh' `"    },function(done,total){var now=Date.now();if(now-lastPost>250){lastPost=now;send({type:'progress',done:done,total:total,rows:rows,interviews:index.size});}},my);"' _n
    file write `fh' `"    if(first)throw new Error('The selected file is empty.');"' _n
    file write `fh' `"    keys=Array.from(index.keys()).sort();"' _n
    file write `fh' `"    send({type:'ready',name:file.name,size:file.size,rows:rows,interviews:index.size,ranges:ranges,blank:blank,scanMode:scanMode,fragmented:!scanMode&&ranges>index.size,dialect:quoted?'quoted':'suso',schema:{sourceUtc:schema.sourceUtc}});"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function lowerBound(a,q){var lo=0,hi=a.length,m;while(lo<hi){m=(lo+hi)>>1;if(a[m]<q)lo=m+1;else hi=m;}return lo;}"' _n
    file write `fh' `"  function suggest(q){"' _n
    file write `fh' `"    var out=[],n=HCore.normId(q),i=lowerBound(keys,n),k;if(!n){send({type:'suggestions',items:out});return;}"' _n
    file write `fh' `"    for(;i<keys.length&&out.length<20;i++){k=keys[i];if(k.indexOf(n)!==0)break;out.push(index.get(k).id);}"' _n
    file write `fh' `"    if(!out.length){for(i=0;i<keys.length&&out.length<20;i++)if(keys[i].indexOf(n)>=0)out.push(index.get(keys[i]).id);}"' _n
    file write `fh' `"    send({type:'suggestions',items:out});"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  async function getHistory(id){"' _n
    file write `fh' `"    var my=++token,key=HCore.normId(id),entry=index&&index.get(key),rows=[],i,range,rowNo,first=true,dataRow=0;"' _n
    file write `fh' `"    if(!entry){send({type:'notfound',id:id});return;}"' _n
    file write `fh' `"    if(scanMode){"' _n
    file write `fh' `"      await scan(0,file.size,function(rec,start){var vals;if(!rec.length)return;if(first){first=false;return;}dataRow++;if(HCore.normId(HCore.field(rec,schema.id,quoted))===key){vals=HCore.parseRecord(rec,quoted);rows.push(HCore.rowFrom(vals,schema,dataRow,start));}},function(done,total){send({type:'readprogress',done:done,total:total,id:entry.id});},my);"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    for(i=0;!scanMode&&i<entry.ranges.length;i++){"' _n
    file write `fh' `"      range=entry.ranges[i];"' _n
    file write `fh' `"      rowNo=range[2];await scan(range[0],range[1],function(rec,start){var vals=HCore.parseRecord(rec,quoted);if(HCore.normId(vals[schema.id])===key)rows.push(HCore.rowFrom(vals,schema,rowNo++,start));},null,my);"' _n
    file write `fh' `"    }"' _n
    file write `fh' `"    HCore.orderRows(rows);send({type:'history',id:entry.id,rows:rows,schema:{sourceUtc:schema.sourceUtc}});"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  self.onmessage=function(e){"' _n
    file write `fh' `"    var d=e.data||{};"' _n
    file write `fh' `"    if(d.type==='index')build(d.file,d.quoted).catch(function(err){if(String(err&&err.message)!=='Cancelled')send({type:'error',message:String(err&&err.message||err)});});"' _n
    file write `fh' `"    else if(d.type==='suggest'&&index)suggest(d.q);"' _n
    file write `fh' `"    else if(d.type==='get'&&index)getHistory(d.id).catch(function(err){if(String(err&&err.message)!=='Cancelled')send({type:'error',message:String(err&&err.message||err)});});"' _n
    file write `fh' `"  };"' _n
    file write `fh' `"}"' _n
    file write `fh' `"(function(){"' _n
    file write `fh' `"  if(typeof document==='undefined')return;"' _n
    file write `fh' `"  var worker=null,currentFile=null,ready=false,rows=[],sourceUtc=true,view='compact',shownRows=[],renderToken=0,suggestTimer=null;"' _n
    file write `fh' `"  function E(id){return document.getElementById(id);}"' _n
    file write `fh' `"  function text(tag,cls,value){var n=document.createElement(tag);if(cls)n.className=cls;n.textContent=value===null||value===undefined?'':String(value);return n;}"' _n
    file write `fh' `"  function status(message,bad){var n=E('hv_status');n.textContent=message;n.className=bad?'hv-status bad':'hv-status';}"' _n
    file write `fh' `"  function stopWorker(){if(worker)worker.terminate();worker=null;ready=false;}"' _n
    file write `fh' `"  function workerSource(){return 'var HCore=('+historyCoreFactory.toString()+')();('+historyWorkerMain.toString()+')();';}"' _n
    file write `fh' `"  function makeWorker(){var blob=new Blob([workerSource()],{type:'text/javascript'});return new Worker(URL.createObjectURL(blob));}"' _n
    file write `fh' `"  function startFile(file){"' _n
    file write `fh' `"    currentFile=file;stopWorker();rows=[];E('hv_results').style.display='none';E('hv_load').disabled=true;E('hv_id').disabled=true;E('hv_progress').style.display='block';E('hv_progress').value=0;"' _n
    file write `fh' `"    try{worker=makeWorker();}catch(err){status('This browser could not start the local-file indexer: '+err.message,true);return;}"' _n
    file write `fh' `"    worker.onmessage=onMessage;worker.onerror=function(e){status('Local indexer failed: '+(e.message||'unknown browser error'),true);};"' _n
    file write `fh' `"    status('Indexing '+file.name+' in the background (0 of '+HCore.formatBytes(file.size)+') ...',false);worker.postMessage({type:'index',file:file,quoted:E('hv_dialect').value==='quoted'});"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function onMessage(e){"' _n
    file write `fh' `"    var d=e.data||{},pct;"' _n
    file write `fh' `"    if(d.type==='progress'){pct=d.total?100*d.done/d.total:0;E('hv_progress').value=pct;status('Indexing locally: '+pct.toFixed(1)+'% - '+d.rows.toLocaleString()+' events, '+d.interviews.toLocaleString()+' interviews found ...',false);}"' _n
    file write `fh' `"    else if(d.type==='ready'){ready=true;sourceUtc=d.schema.sourceUtc;E('hv_progress').style.display='none';E('hv_id').disabled=false;E('hv_load').disabled=!E('hv_id').value.trim();status('Ready: '+d.rows.toLocaleString()+' events in '+d.interviews.toLocaleString()+' interviews. Parsing mode: '+(d.dialect==='quoted'?'quoted TSV':'Survey Solutions literal TSV')+'. '+(d.scanMode?'The file is highly interleaved, so each selected ID is found by a safe streaming rescan. ':(d.fragmented?'Non-contiguous interview blocks were indexed. ':''))+(d.blank?d.blank.toLocaleString()+' blank-ID rows were skipped. ':''),false);if(E('hv_id').value.trim())loadHistory();else E('hv_id').focus();}"' _n
    file write `fh' `"    else if(d.type==='readprogress'){pct=d.total?100*d.done/d.total:0;status('Finding '+d.id+' in the interleaved file: '+pct.toFixed(1)+'% ...',false);}"' _n
    file write `fh' `"    else if(d.type==='suggestions')showSuggestions(d.items||[]);"' _n
    file write `fh' `"    else if(d.type==='notfound'){E('hv_results').style.display='none';status('Interview ID not found in the selected paradata file: '+d.id,true);}"' _n
    file write `fh' `"    else if(d.type==='history'){sourceUtc=d.schema.sourceUtc;rows=d.rows||[];E('hv_id').value=d.id;E('hv_search').value='';prepareRows();populateFilters();E('hv_results').style.display='block';status('Loaded '+rows.length.toLocaleString()+' events for '+d.id+'.',false);render();}"' _n
    file write `fh' `"    else if(d.type==='error'){E('hv_progress').style.display='none';status(d.message||'Could not read the selected file.',true);}"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function showSuggestions(items){"' _n
    file write `fh' `"    var box=E('hv_suggest'),i,b;box.textContent='';"' _n
    file write `fh' `"    for(i=0;i<items.length;i++){b=text('button','hv-suggestion mono',items[i]);b.type='button';b.addEventListener('click',function(){E('hv_id').value=this.textContent;box.textContent='';E('hv_load').disabled=false;loadHistory();});box.appendChild(b);}"' _n
    file write `fh' `"    box.style.display=items.length?'block':'none';"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function loadHistory(){var id=E('hv_id').value.trim();if(!ready||!id)return;E('hv_suggest').style.display='none';status('Reading the complete event chain for '+id+' ...',false);worker.postMessage({type:'get',id:id});}"' _n
    file write `fh' `"  function openHistory(id){"' _n
    file write `fh' `"    id=String(id===null||id===undefined?'':id).trim();if(!id||id.length>500)return false;var sb=E('s_hist');if(sb&&String(sb.className).indexOf('open')<0){sb.className=String(sb.className)+' open';var sh=sb.querySelector?sb.querySelector('.shead'):null;if(sh)sh.setAttribute('aria-expanded','true');}E('hv_id').value=id;E('hv_load').disabled=!ready;E('history_explorer').scrollIntoView({behavior:'smooth',block:'start'});"' _n
    file write `fh' `"    if(ready)loadHistory();else{status('Interview '+id+' is queued. Choose the matching paradata.tab once to open its full event chain.',false);E('hv_file').focus();}return true;"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  window.susoOpenHistory=openHistory;"' _n
    file write `fh' `"  /* UI test hook: render synthetic rows without touching any file. Data never leaves the page. */"' _n
    file write `fh' `"  window.susoHistoryPreview=function(sample,isUtc){rows=Array.isArray(sample)?sample.slice():[];sourceUtc=isUtc!==false;view='compact';E('hv_search').value='';E('hv_id').value='(synthetic preview)';prepareRows();populateFilters();E('hv_results').style.display='block';status('Synthetic preview: '+rows.length.toLocaleString()+' events rendered locally. No file was read.',false);render();return rows.length;};"' _n
    file write `fh' `"  function prepareRows(){var prev=null,i,t;for(i=0;i<rows.length;i++){t=HCore.timeInfo(rows[i],sourceUtc);rows[i]._time=t;rows[i]._gap=(prev!==null&&t.utcMs!==null)?t.utcMs-prev:null;if(t.utcMs!==null)prev=t.utcMs;}}"' _n
    file write `fh' `"  function option(select,value,label){var o=document.createElement('option');o.value=value;o.textContent=label;select.appendChild(o);}"' _n
    file write `fh' `"  function populateFilters(){"' _n
    file write `fh' `"    var ev=Object.create(null),ac=Object.create(null),i,a,b,se=E('hv_event'),sa=E('hv_actor');se.textContent='';sa.textContent='';option(se,'','All event types');option(sa,'','All actors');"' _n
    file write `fh' `"    for(i=0;i<rows.length;i++){if(rows[i].event)ev[rows[i].event]=1;a=rows[i].responsible||'(no responsible actor)';ac[a]=1;}"' _n
    file write `fh' `"    a=Object.keys(ev).sort();for(i=0;i<a.length;i++)option(se,a[i],a[i]);b=Object.keys(ac).sort();for(i=0;i<b.length;i++)option(sa,b[i],b[i]);"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function gapText(ms){var sign=ms<0?'clock reversal ':'+',x=Math.abs(ms);if(ms===null)return '';if(x<1000)return sign+x+' ms';if(x<60000)return sign+(x/1000).toFixed(x<10000?1:0)+' s';if(x<3600000)return sign+(x/60000).toFixed(1)+' min';return sign+(x/3600000).toFixed(1)+' h';}"' _n
    file write `fh' `"  function gapBreakMs(){var m=30;try{if(typeof D!=='undefined'&&D&&D.meta&&isFinite(D.meta.gapmins)&&D.meta.gapmins>0)m=Number(D.meta.gapmins);}catch(err){}if(m<1)m=1;if(m>1440)m=1440;return m*60000;}"' _n
    file write `fh' `"  function compactHeader(){var h=document.createElement('div');h.className='hvc-head';h.appendChild(text('span','','#'));h.appendChild(text('span','','event'));h.appendChild(text('span','','parameters'));h.appendChild(text('span','','actor'));h.appendChild(text('span','hvc-time','device local'));h.appendChild(text('span','hvc-gap','gap'));return h;}"' _n
    file write `fh' `"  function compactNode(it){"' _n
    file write `fh' `"    if(it.k==='day')return text('div','hvc-day',it.label);"' _n
    file write `fh' `"    if(it.k==='gap')return text('div','hvc-gapsep',it.label);"' _n
    file write `fh' `"    var r=it.r,n=document.createElement('div'),par,cell,b,seg,j;"' _n
    file write `fh' `"    n.className='hvc-row '+HCore.kind(r.event);n.setAttribute('data-idx',String(it.i));"' _n
    file write `fh' `"    n.appendChild(text('span','hvc-ord mono','#'+(r.order||'?')));"' _n
    file write `fh' `"    n.appendChild(text('span','hvc-kind',r.event||'(blank event)'));"' _n
    file write `fh' `"    par=document.createElement('span');par.className='hvc-par mono';"' _n
    file write `fh' `"    if(r.parameters){seg=String(r.parameters).split('||');for(j=0;j<seg.length;j++){if(j)par.appendChild(text('span','pp','||'));par.appendChild(document.createTextNode(seg[j]));}par.title=r.parameters;}"' _n
    file write `fh' `"    else{par.className='hvc-par mono dim';par.textContent='-';}"' _n
    file write `fh' `"    n.appendChild(par);"' _n
    file write `fh' `"    n.appendChild(text('span','hvc-actor'+(it.dimA?' dim':''),it.actor));"' _n
    file write `fh' `"    cell=text('span','hvc-time mono'+(it.dimT?' dim':'')+(it.tsrc==='utc'?' approx':''),it.t||'--:--:--.---');"' _n
    file write `fh' `"    if(it.tsrc==='utc')cell.title='UTC clock: no valid device-local time on this event';"' _n
    file write `fh' `"    if(it.tsrc==='none')cell.title='no parseable timestamp on this event';"' _n
    file write `fh' `"    n.appendChild(cell);"' _n
    file write `fh' `"    cell=text('span','hvc-gap','');"' _n
    file write `fh' `"    if(it.pill){b=text('span','hvc-pill '+it.pill.cls,it.pill.txt);b.title=it.pill.title;cell.appendChild(b);}"' _n
    file write `fh' `"    n.appendChild(cell);"' _n
    file write `fh' `"    return n;"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function detailPair(dl,k,v,mono){dl.appendChild(text('dt','',k));dl.appendChild(text('dd',mono?'mono':'',v===''||v===null||v===undefined?'(blank)':String(v)));}"' _n
    file write `fh' `"  function buildDetail(r){"' _n
    file write `fh' `"    var t=r._time||{},n=document.createElement('div'),dl=document.createElement('dl'),ph,cp;"' _n
    file write `fh' `"    n.className='hvc-det';dl.className='hvc-grid';"' _n
    file write `fh' `"    detailPair(dl,'Event',r.event||'(blank event)');"' _n
    file write `fh' `"    detailPair(dl,'Order',r.order,true);"' _n
    file write `fh' `"    detailPair(dl,'Source row',r.seq,true);"' _n
    file write `fh' `"    detailPair(dl,'Device local',t.local||'(unavailable)',true);"' _n
    file write `fh' `"    detailPair(dl,'UTC',t.utc||'(unavailable)',true);"' _n
    file write `fh' `"    detailPair(dl,'Source timestamp',r.timestamp,true);"' _n
    file write `fh' `"    detailPair(dl,'UTC offset',r.tz||'(missing)',true);"' _n
    file write `fh' `"    detailPair(dl,'Responsible',r.responsible||'(no responsible actor)');"' _n
    file write `fh' `"    detailPair(dl,'Role',r.role||'(none)');"' _n
    file write `fh' `"    n.appendChild(dl);"' _n
    file write `fh' `"    ph=document.createElement('div');ph.className='hvc-plabel';ph.appendChild(text('span','','Parameters'));"' _n
    file write `fh' `"    cp=text('button','cpy','Copy');cp.type='button';"' _n
    file write `fh' `"    cp.addEventListener('click',function(ev){ev.stopPropagation();copyText(r.parameters||'',cp);});"' _n
    file write `fh' `"    ph.appendChild(cp);n.appendChild(ph);"' _n
    file write `fh' `"    n.appendChild(text('div','hv-parameters mono',r.parameters||'(no parameters)'));"' _n
    file write `fh' `"    return n;"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function copyText(s,btn){"' _n
    file write `fh' `"    var done=function(){var old=btn.textContent;btn.textContent='Copied';setTimeout(function(){btn.textContent=old;},1200);};"' _n
    file write `fh' `"    if(navigator.clipboard&&navigator.clipboard.writeText)navigator.clipboard.writeText(s).then(done,function(){fallbackCopy(s,done);});"' _n
    file write `fh' `"    else fallbackCopy(s,done);"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function fallbackCopy(s,done){var ta=document.createElement('textarea');ta.value=s;ta.setAttribute('readonly','');ta.style.position='fixed';ta.style.left='-9999px';document.body.appendChild(ta);ta.select();try{document.execCommand('copy');done();}catch(err){}document.body.removeChild(ta);}"' _n
    file write `fh' `"  function toggleRow(row){"' _n
    file write `fh' `"    var next=row.nextElementSibling,r;"' _n
    file write `fh' `"    if(next&&next.className&&next.className.indexOf('hvc-det')>=0){next.parentNode.removeChild(next);row.classList.remove('open');return;}"' _n
    file write `fh' `"    r=shownRows[Number(row.getAttribute('data-idx'))];if(!r)return;"' _n
    file write `fh' `"    row.parentNode.insertBefore(buildDetail(r),row.nextSibling);row.classList.add('open');"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function expandAll(){"' _n
    file write `fh' `"    if(shownRows.length>1500){status('Expand all is capped at 1,500 shown events. Filter or search first, then expand.',false);return;}"' _n
    file write `fh' `"    var list=E('hv_compact').querySelectorAll('.hvc-row'),i;"' _n
    file write `fh' `"    for(i=0;i<list.length;i++)if(!list[i].classList.contains('open'))toggleRow(list[i]);"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function collapseAll(){"' _n
    file write `fh' `"    var list=E('hv_compact').querySelectorAll('.hvc-det'),i;"' _n
    file write `fh' `"    for(i=list.length-1;i>=0;i--)list[i].parentNode.removeChild(list[i]);"' _n
    file write `fh' `"    list=E('hv_compact').querySelectorAll('.hvc-row.open');"' _n
    file write `fh' `"    for(i=0;i<list.length;i++)list[i].classList.remove('open');"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function filtered(){var ev=E('hv_event').value,ac=E('hv_actor').value,q=E('hv_search').value,out=[],i,a;for(i=0;i<rows.length;i++){a=rows[i].responsible||'(no responsible actor)';if(ev&&rows[i].event!==ev)continue;if(ac&&a!==ac)continue;if(!HCore.matches(rows[i],q))continue;out.push(rows[i]);}return out;}"' _n
    file write `fh' `"  function clearResult(){renderToken++;shownRows=[];E('hv_compact').textContent='';E('hv_timeline').textContent='';E('hv_raw_body').textContent='';}"' _n
    file write `fh' `"  function render(){"' _n
    file write `fh' `"    var shown=filtered(),actors=Object.create(null),events=Object.create(null),offsets=Object.create(null),i,off;clearResult();"' _n
    file write `fh' `"    for(i=0;i<rows.length;i++){actors[rows[i].responsible||'(none)']=1;events[rows[i].event||'(blank)']=1;off=rows[i].tz||'(missing)';offsets[off]=1;}"' _n
    file write `fh' `"    E('hv_summary').textContent='Full chain: '+rows.length.toLocaleString()+' events, '+Object.keys(events).length+' event types, '+Object.keys(actors).length+' responsible actors, '+Object.keys(offsets).length+' recorded UTC offset(s). Showing '+shown.length.toLocaleString()+'.'+(Object.keys(offsets).length>1?' Offsets change in this history; local times use the offset recorded on each event.':'');"' _n
    file write `fh' `"    E('hv_compact').style.display=view==='compact'?'block':'none';E('hv_timeline').style.display=view==='cards'?'block':'none';E('hv_raw').style.display=view==='raw'?'block':'none';"' _n
    file write `fh' `"    E('hv_bulk').style.display=view==='compact'?'flex':'none';"' _n
    file write `fh' `"    E('hv_view_compact').className=view==='compact'?'pbtn':'pbtn ghost';E('hv_view_timeline').className=view==='cards'?'pbtn':'pbtn ghost';E('hv_view_raw').className=view==='raw'?'pbtn':'pbtn ghost';"' _n
    file write `fh' `"    if(view==='compact'){shownRows=shown;var box=E('hv_compact');box.appendChild(compactHeader());renderBatches(HCompact.plan(shown,gapBreakMs()),box,compactNode);}"' _n
    file write `fh' `"    else if(view==='cards')renderBatches(shown,E('hv_timeline'),timelineRow);"' _n
    file write `fh' `"    else renderBatches(shown,E('hv_raw_body'),rawRow);"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function renderBatches(items,target,maker){"' _n
    file write `fh' `"    var mine=renderToken,pos=0;function batch(){var frag=document.createDocumentFragment(),end=Math.min(items.length,pos+400);if(mine!==renderToken)return;for(;pos<end;pos++)frag.appendChild(maker(items[pos]));target.appendChild(frag);if(pos<items.length)setTimeout(batch,0);}batch();"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function timelineRow(r){"' _n
    file write `fh' `"    var n=document.createElement('div'),head=document.createElement('div'),meta=document.createElement('div'),p=document.createElement('div'),t=r._time||{};n.className='hv-event '+HCore.kind(r.event);"' _n
    file write `fh' `"    head.className='hv-event-head';head.appendChild(text('span','hv-order mono','#'+(r.order||'?')));head.appendChild(text('span','hv-kind',r.event||'(blank event)'));if(r._gap!==null)head.appendChild(text('span','hv-gap',gapText(r._gap)));n.appendChild(head);"' _n
    file write `fh' `"    meta.className='hv-event-meta';meta.appendChild(text('span','hv-local',t.local?('Local '+t.local):'Local time unavailable'));meta.appendChild(text('span','mono',t.utc?('UTC '+t.utc):('Source '+r.timestamp)));meta.appendChild(text('span','mono','offset '+(r.tz||'?')));n.appendChild(meta);"' _n
    file write `fh' `"    if(r.responsible||r.role)n.appendChild(text('div','hv-actor',(r.responsible||'(no responsible actor)')+(r.role?' - '+r.role:'')));"' _n
    file write `fh' `"    if(r.parameters){p.className='hv-parameters mono';p.textContent=r.parameters;n.appendChild(p);}return n;"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  function rawCell(tr,value,cls){var td=text('td',cls||'',value);tr.appendChild(td);}"' _n
    file write `fh' `"  function rawRow(r){var tr=document.createElement('tr'),t=r._time||{};rawCell(tr,r.seq,'r mono');rawCell(tr,r.order,'r mono');rawCell(tr,r.event);rawCell(tr,r.responsible);rawCell(tr,r.role);rawCell(tr,r.timestamp,'mono');rawCell(tr,t.utc,'mono');rawCell(tr,r.tz,'mono');rawCell(tr,t.local,'mono');rawCell(tr,r.parameters,'mono hv-raw-parameters');return tr;}"' _n
    file write `fh' `"  function init(){"' _n
    file write `fh' `"    /* Pure-UI wiring first: views, expansion, and filters work even where file streaming is unsupported (and for susoHistoryPreview rows). */"' _n
    file write `fh' `"    E('hv_view_compact').addEventListener('click',function(){view='compact';render();});E('hv_view_timeline').addEventListener('click',function(){view='cards';render();});E('hv_view_raw').addEventListener('click',function(){view='raw';render();});"' _n
    file write `fh' `"    E('hv_expand').addEventListener('click',expandAll);E('hv_collapse').addEventListener('click',collapseAll);"' _n
    file write `fh' `"    E('hv_compact').addEventListener('click',function(e){var t=e.target;if(!t||!t.closest)return;if(t.closest('.hvc-det'))return;if(window.getSelection&&String(window.getSelection()))return;var row=t.closest('.hvc-row');if(row)toggleRow(row);});"' _n
    file write `fh' `"    E('hv_event').addEventListener('change',render);E('hv_actor').addEventListener('change',render);E('hv_search').addEventListener('input',render);"' _n
    file write `fh' `"    if(typeof Worker==='undefined'||typeof Blob==='undefined'||typeof TextDecoder==='undefined'){status('This browser lacks the local streaming features needed for the history viewer. Use a current Chrome or Edge browser.',true);E('hv_file').disabled=true;return;}"' _n
    file write `fh' `"    E('hv_file').addEventListener('change',function(){if(this.files&&this.files[0])startFile(this.files[0]);});"' _n
    file write `fh' `"    E('hv_dialect').addEventListener('change',function(){if(currentFile)startFile(currentFile);});"' _n
    file write `fh' `"    E('hv_id').addEventListener('input',function(){E('hv_load').disabled=!ready||!this.value.trim();clearTimeout(suggestTimer);if(ready&&this.value.trim())suggestTimer=setTimeout(function(){worker.postMessage({type:'suggest',q:E('hv_id').value});},160);else showSuggestions([]);});"' _n
    file write `fh' `"    E('hv_id').addEventListener('keydown',function(e){if(e.key==='Enter'){e.preventDefault();loadHistory();}});E('hv_load').addEventListener('click',loadHistory);"' _n
    file write `fh' `"  }"' _n
    file write `fh' `"  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();"' _n
    file write `fh' `"})();"' _n
    file write `fh' `"</script>"' _n
end

program _suso_para_report, rclass
    version 14.2
    syntax [, SAVing(string) replace TITle(string) QX(string)                    ///
        DATA(string) FILTERS(string) VARS(string)                                ///
        GAPMins(real 30) FASTsecs(real 2) ALLRoles                               ///
        CASCade(integer 3) WINdow(real 60) LITEcap(integer 15000) HQURL(string)   ///
        SKIPHTML(string) SKIPTOP(integer 15) ]
    _suso_para_need events

    _suso_para_hqbase , hqurl(`"`hqurl'"')
    local hqbase `"`r(url)'"'
    _suso_jsonesc `"`hqbase'"'
    local hqbasej `"`r(js)'"'
    _suso_para_hesc `"`hqbase'"'
    local hqbaseh `"`r(out)'"'

    if `"`saving'"'=="" local saving "suso_paradata_qc.html"
    if "`replace'"=="" {
        capture confirm new file `"`saving'"'
        if _rc {
            di as err "suso: file already exists. Use -replace-."
            exit 602
        }
    }
    if `"`title'"'=="" {
        local title "Paradata QC report"
        if "$SUSO_WS"!="" local title "Paradata QC report — $SUSO_WS"
    }
    _suso_para_hesc `"`title'"'
    local htitle `"`r(out)'"'

    di as txt "suso paradata: building the interactive QC report ..."
    tempfile EVD EVSK SK QT AQT QTK QWS QXO DAILY HHF GGF MERGED RSD RSDFOCUS FLK HQF ///
        KEYF MODEF TZF REJF REJDF OVF OVDF OVB OVP OVACT OVADF OVS PCEF VERF NQF RTF FRF ACTF ACTPF
    tempname derivecap skipcap
    local nevents = _N

    local hasassignment 0
    if `"`data'"'!="" {
        capture confirm file `"`data'"'
        if _rc {
            di as err `"suso paradata report: final data file not found: `data'"'
            exit 601
        }
        preserve
            quietly use `"`data'"', clear
            capture confirm string variable interview__id, exact
            if _rc {
                di as err "suso paradata report: data() requires a string interview__id variable."
                di as err "                         Use the one-row-per-interview Survey Solutions main export."
                exit 459
            }
            quietly count if strtrim(interview__id)==""
            if r(N)>0 {
                di as err "suso paradata report: data() contains blank interview__id values."
                exit 459
            }
        restore
        quietly _suso_para_hqmap using `"`data'"', saving(`"`HQF'"')
        local hasassignment = r(hasassignment)
    }

    * Preserve the questionnaire preview's document order as a compact map.
    * This is the static design/CAPI sequence; effective skip logic means one
    * interview may traverse only a subset of it.  Duplicate variable metadata
    * keeps the first design position, and roster instances later collapse onto
    * their base para_var.  Parsing here also makes a bad qx() fail before the
    * multi-million-event behaviour derivation begins.
    local hasqxorder 0
    local qorderopt ""
    if `"`qx'"'!="" {
        preserve
            quietly _suso_para_qxload , file(`"`qx'"')
            quietly gen long qx_order = _n
            quietly keep qx_var qx_order
            quietly drop if strtrim(qx_var)==""
            quietly bysort qx_var (qx_order): keep if _n==1
            quietly rename qx_var para_var
            quietly isid para_var
            quietly save `"`QXO'"'
        restore
        local hasqxorder 1
        local qorderopt `"qorder(`"`QXO'"')"'
    }
    local qordernote "<b>Default order:</b> first occurrence in the loaded paradata; tied or unavailable source positions are alphabetical. Supply qx() for the questionnaire design order."
    local qorderbutton "Default order"
    if `hasqxorder' local qordernote "<b>Default order:</b> the static design/CAPI sequence in the supplied questionnaire preview, among questions observed in this scope. Skip logic means any one interview may see only its enabled path; roster instances remain at their base variable position, and event variables absent from the preview are appended alphabetically."
    if `hasqxorder' local qorderbutton "Questionnaire order"

    di as txt "  [behaviour 1/5] deriving sessions, actors and answer timing once ..."
    _suso_para_derive , gapmins(`gapmins') fastsecs(`fastsecs') `allroles'     ///
        cachetoken(`derivecap')
    local rolenote `"`r(rolenote)'"'
    quietly save `"`EVD'"'
    local skipbase `"`EVD'"'
    local skiptoken "`derivecap'"
    local nderive 1
    * Skip/removal ownership historically uses the canonical 30-minute/2-second
    * derivation.  A custom report threshold may change the active-time actor
    * tie-break, so build one separate canonical cache only in that uncommon
    * case.  Default reports and suites still derive the 3.5m-row stream once.
    if `gapmins'!=30 | `fastsecs'!=2 {
        quietly _suso_para_derive , gapmins(30) fastsecs(2) `allroles'        ///
            cachetoken(`skipcap')
        quietly save `"`EVSK'"'
        local skipbase `"`EVSK'"'
        local skiptoken "`skipcap'"
        local nderive 2
        quietly use `"`EVD'"', clear
    }
    quietly _suso_para_statusmap , saving(`"`QWS'"') data(`"`data'"') replace
    di as txt "  [behaviour 2/5] building compact interview/question summaries ..."

    * coverage of the event stream (freshness line in the header)
    quietly summarize para_tsu
    local cov0 ""
    local cov1 ""
    if r(N)>0 {
        local cov0 : di %tcCCYY-NN-DD r(min)
        local cov1 : di %tcCCYY-NN-DD r(max)
        local cov0 = trim("`cov0'")
        local cov1 = trim("`cov1'")
    }

    * variable-filter lookup from the main export: value per interview + labels
    local fdimvars ""
    local nfdim 0
    local jfdims ""
    if `"`data'"'!="" & `"`filters'"'!="" {
        preserve
        quietly use `"`data'"', clear
        capture confirm variable interview__id
        if _rc di as txt "  filters(): data() has no interview__id - variable filters skipped."
        else {
            local __fvb 0
            foreach fvv of local filters {
                capture confirm numeric variable `fvv', exact
                if _rc {
                    di as txt "  filters(): " as res "`fvv'" as txt " not found or not numeric in data() - skipped."
                    continue
                }
                quietly levelsof `fvv', local(fl)
                local nfl : word count `fl'
                if `nfl'==0 | `nfl'>20 | `__fvb'+`nfl'>40 {
                    di as txt "  filters(): " as res "`fvv'" as txt " skipped (`nfl' values; limit 20 per variable, 40 total)."
                    continue
                }
                local __fvb = `__fvb' + `nfl'
                local fdimvars "`fdimvars' `fvv'"
                local ++nfdim
                local fdimorig_`nfdim' "`fvv'"
                tempvar __fdalias
                local fdimalias_`nfdim' "`__fdalias'"
                _suso_jsonesc `"`fvv'"'
                local fdimjson_`nfdim' `"`r(js)'"'
                local jv1 ""
                foreach s of local fl {
                    local lb : label (`fvv') `s'
                    _suso_jsonesc `"`lb'"'
                    local lbj `"`r(js)'"'
                    local jv1 `"`jv1'`=cond(`"`jv1'"'=="","",",")'{"c":"`s'","l":"`lbj'"}"'
                }
                local jfdims `"`jfdims'`=cond(`"`jfdims'"'=="","",",")'{"v":"`fdimjson_`nfdim''","vals":[`jv1']}"'
            }
            local fdimvars = strtrim("`fdimvars'")
            if "`fdimvars'"!="" {
                quietly keep interview__id `fdimvars'
                quietly duplicates drop
                tempvar __fdup
                quietly bysort interview__id: gen byte `__fdup' = _N>1
                quietly count if `__fdup'
                if r(N)>0 {
                    di as err "suso paradata report: data() has duplicate interview__id rows with conflicting filters() values."
                    di as err "                         Supply the one-row-per-interview main export, not a roster export."
                    exit 459
                }
                quietly drop `__fdup'
                quietly bysort interview__id: keep if _n==1
                forvalues fi = 1/`nfdim' {
                    quietly rename `fdimorig_`fi'' `fdimalias_`fi''
                }
                quietly save `"`FLK'"'
            }
        }
        restore
    }

    * ---- question timing table ----------------------------------------------------
    * Build exact All / current-status / Approved-only scopes from eligible raw
    * events.  This remains compact in the HTML while preserving pooled quantiles.
    quietly use `"`EVD'"', clear
    quietly _suso_para_questionpayload , statusmap(`"`QWS'"')                 ///
        qsaving(`"`QT'"') aqsaving(`"`AQT'"') peersaving(`"`QTK'"')          ///
        vars(`"`vars'"') `qorderopt'
    local hasq = r(hasq)
    local hasaq = r(hasaq)
    local haspeerq = r(haspeerq)

    * ---- interviewer-day volume + lite decision ----------------------------------
    quietly use `"`EVD'"', clear
    quietly keep if para_fieldans & para_actor_key!=""
    if _N==0 {
        di as err "suso paradata report: no interviewer answer events — nothing to report on."
        exit 2000
    }
    tempvar f1
    quietly bysort interview__id: gen byte `f1' = _n==1
    quietly count if `f1'
    local lite = cond(r(N)>`litecap', 1, 0)
    local haslocal 0
    local dbucket 0
    preserve
        quietly keep if !missing(para_tsl)
        if _N>0 {
            local haslocal 1
            tempvar ddv
            quietly gen long `ddv' = dofc(para_tsl)
            quietly contract para_actor `ddv', freq(__pc)
            quietly rename para_actor responsible
            if _N>2500 {
                local dbucket 1
                quietly replace `ddv' = `ddv' - mod(`ddv', 7)
                collapse (sum) __pc, by(responsible `ddv') fast
            }
            quietly gen long __dd = `ddv'
        }
        else {
            quietly clear
            quietly set obs 0
            quietly gen str244 responsible = ""
            quietly gen long __dd = .
            quietly gen long __pc = 0
        }
        quietly save `"`DAILY'"'
    restore
    if !`haslocal' {
        di as txt "  note: no valid device-local timestamps; local-day/night charts are empty and local-time flags are suppressed."
    }
    local dnote = cond(!`haslocal', "unavailable: no valid device-local timestamps", ///
        cond(`dbucket', "7-day blocks", "per day"))

    * ---- per-interview hour and answer-gap vectors (skipped for huge surveys) ----
    if !`lite' {
        quietly use `"`EVD'"', clear
        quietly keep if para_fieldans & para_firstpass & !missing(para_tsl) & ///
            para_actor_key==ustrlower(strtrim(para_primary))
        if _N>0 {
            quietly gen byte __hh = hh(para_tsl)
            quietly contract interview__id __hh, freq(__pc)
            forvalues h = 0/23 {
                quietly gen long h`h' = cond(__hh==`h', __pc, 0)
            }
            collapse (sum) h0-h23, by(interview__id) fast
        }
        else {
            quietly clear
            quietly set obs 0
            quietly gen str80 interview__id = ""
            forvalues h = 0/23 {
                quietly gen long h`h' = 0
            }
        }
        quietly save `"`HHF'"'
        quietly use `"`EVD'"', clear
        quietly keep if para_firstpass & !missing(para_ansgap) & ///
            para_actor_key==ustrlower(strtrim(para_primary))
        if _N>0 {
            quietly gen byte __g = min(floor(para_ansgap*2), 40)
            quietly contract interview__id __g, freq(__pc)
            forvalues g = 0/40 {
                quietly gen long g`g' = cond(__g==`g', __pc, 0)
            }
            collapse (sum) g0-g40, by(interview__id) fast
            quietly save `"`GGF'"'
        }
        else {
            quietly clear
            quietly set obs 0
            quietly gen str80 interview__id = ""
            forvalues g = 0/40 {
                quietly gen long g`g' = 0
            }
            quietly save `"`GGF'"'
        }
    }

    * ---- NEW: interview key (what the supervisor types into Headquarters) --------
    * KeyAssigned parameters carry the NN-NN-NN-NN key; the latest event is current.
    local haskey 0
    quietly use `"`EVD'"', clear
    quietly keep if para_ev=="keyassigned"
    if _N>0 {
        capture confirm string variable parameters
        if !_rc {
            local haskey 1
            quietly bysort interview__id (para_ord para_seq): keep if _n==_N
            quietly gen ikey = substr(strtrim(parameters), 1, 12)
            quietly keep interview__id ikey
            quietly save `"`KEYF'"'
        }
    }

    * ---- event-segmented interview mode (CAPI vs CAWI) ----------------------------
    * A mixed history is not treated wholly as whichever mode happened to be last.
    local hascawi 0
    quietly use `"`EVD'"', clear
    quietly keep if para_fieldans & para_firstpass
    if _N>0 {
        tempvar ma mc
        quietly gen byte `ma' = para_cawi==1
        quietly gen byte `mc' = para_cawi==0
        collapse (sum) __nwa=`ma' __nca=`mc', by(interview__id) fast
        quietly gen byte iscawi = __nwa>0 & __nca==0
        quietly gen byte mixedmode = __nwa>0 & __nca>0
        quietly count if iscawi | mixedmode
        if r(N)>0 local hascawi 1
        quietly keep interview__id iscawi mixedmode
        quietly save `"`MODEF'"'
    }
    capture confirm file `"`MODEF'"'
    if _rc {
        quietly clear
        quietly set obs 0
        quietly gen interview__id = ""
        quietly gen byte iscawi = 0
        quietly gen byte mixedmode = 0
        quietly save `"`MODEF'"'
    }

    * ---- NEW: device-clock sanity (timezone offsets) ------------------------------
    * Night-work times come from the tablet clock. A tablet whose timezone differs
    * from the team, or changes mid-interview, cannot be trusted for time-of-day.
    quietly use `"`EVD'"', clear
    * tablet clock = interviewer-side events only; supervisor/HQ web actions carry
    * the browser or server offset and would fake a "changed mid-interview" signal
    * on every rejected or approved interview
    quietly keep if para_fieldans & para_firstpass & ///
        para_actor_key==ustrlower(strtrim(para_primary))
    quietly contract interview__id para_off, freq(__pk)
    quietly drop if missing(para_off)
    local tzmode 0
    local hastz 0
    if _N>0 {
        local hastz 1
        * One modal primary-actor offset per interview; the team mode therefore
        * receives one vote per interview, not one vote per high-volume tablet.
        quietly bysort interview__id: gen __k = _N
        gsort interview__id -__pk para_off
        quietly by interview__id: gen byte __pick = _n==1
        preserve
        quietly keep if __pick
        * Do not count the string interview ID directly: Stata's collapse
        * rejects string variables with statistic count (r(109)).  Each retained
        * row is one interview and __pk is numeric/nonmissing.
        collapse (count) __ni=__pk, by(para_off) fast
        gsort -__ni para_off
        local tzmode = para_off[1]
        restore
        quietly keep if __pick
        quietly gen double tzh   = para_off/3600000
        quietly gen byte   tzodd = (para_off!=`tzmode') | (__k>1)
        quietly keep interview__id tzh tzodd
        quietly save `"`TZF'"'
    }
    else {
        quietly clear
        quietly set obs 0
        quietly gen interview__id = ""
        quietly gen double tzh = .
        quietly gen byte tzodd = 0
        quietly save `"`TZF'"'
    }
    local tzmodej "null"
    local tzmodeh "unavailable"
    if `hastz' {
        local tzmodej : di %4.1f `tzmode'/3600000
        local tzmodej = trim("`tzmodej'")
        local tzmodeh "`tzmodej'"
    }

    * ---- rejection/re-completion episodes -----------------------------------------
    * Count both raw edit events and distinct question/roster instances.  A remove
    * plus reset of one question is two events but one question touched.
    quietly use `"`EVD'"', clear
    quietly sort interview__id para_ord para_seq
    quietly by interview__id: gen long rb_cycle = sum(para_rej)
    quietly keep if rb_cycle>0
    if _N>0 {
        tempvar rejidx rejord rejseq rejts cmpidx cmpord cmpseq cmpts inep edit ///
            fieldedit qkey qtag aset arem atag editactor
        quietly egen double `rejidx' = min(cond(para_rej,para_index,.)), ///
            by(interview__id rb_cycle)
        quietly egen double `rejord' = min(cond(para_rej,para_ord,.)), ///
            by(interview__id rb_cycle)
        quietly egen double `rejseq' = min(cond(para_rej,para_seq,.)), ///
            by(interview__id rb_cycle)
        quietly egen double `rejts' = min(cond(para_rej,para_tsu,.)), ///
            by(interview__id rb_cycle)
        quietly egen double `cmpidx' = min(cond(para_fieldcmp & para_index>`rejidx', ///
            para_index,.)), by(interview__id rb_cycle)
        quietly egen double `cmpord' = min(cond(para_index==`cmpidx',para_ord,.)), ///
            by(interview__id rb_cycle)
        quietly egen double `cmpseq' = min(cond(para_index==`cmpidx',para_seq,.)), ///
            by(interview__id rb_cycle)
        quietly egen double `cmpts' = min(cond(para_index==`cmpidx', ///
            para_tsu,.)), by(interview__id rb_cycle)
        quietly gen byte `inep' = para_index>`rejidx' & ///
            (missing(`cmpidx') | para_index<`cmpidx')
        * Any substantive answer edit counts as a change, including a documented
        * Supervisor/HQ correction.  Keep the interviewer subset separately for
        * attribution, but never call a cycle unchanged merely because HQ edited it.
        quietly gen byte `edit' = `inep' & (para_ans | para_rem)
        quietly gen byte `fieldedit' = `inep' & (para_fieldans | para_fieldrem)
        quietly gen str244 `editactor' = ""
        capture confirm string variable responsible
        if !_rc quietly replace `editactor' = strtrim(responsible) if `edit'
        capture confirm string variable role
        if !_rc quietly replace `editactor' = strtrim(role) if `edit' & `editactor'==""
        local rbqknown 0
        capture confirm variable para_qkey, exact
        if !_rc {
            quietly gen str244 `qkey' = para_qkey if `edit'
            local rbqknown 1
        }
        else {
            capture confirm variable para_var, exact
            if !_rc {
                quietly gen str244 `qkey' = para_var if `edit'
                local rbqknown 1
            }
            else quietly gen str244 `qkey' = ""
        }
        quietly egen byte `qtag' = tag(interview__id rb_cycle `qkey') if ///
            `edit' & `qkey'!=""
        quietly gen byte `aset' = `inep' & para_ans
        quietly gen byte `arem' = `inep' & para_rem
        quietly egen byte `atag' = tag(interview__id rb_cycle `editactor') if ///
            `edit' & `editactor'!=""

        * Last correction actor and a compact touched-question list.
        tempvar lastact qpiece qlist
        gsort interview__id rb_cycle -`edit' -para_ord -para_seq `editactor'
        quietly by interview__id rb_cycle: gen str244 `lastact' = `editactor'[1] if `edit'[1]
        quietly sort interview__id rb_cycle para_ord para_seq
        quietly gen str244 `qpiece' = `qkey' if `qtag'==1
        quietly gen strL `qlist' = ""
        quietly by interview__id rb_cycle: replace `qlist' = ///
            cond(_n==1,"",`qlist'[_n-1]) +                             ///
            cond(`qpiece'!="",cond(_n>1 & `qlist'[_n-1]!="","; ","")+`qpiece',"")

        collapse (sum) rbe=`edit' rbe_field=`fieldedit' rbq=`qtag'          ///
            rb_set=`aset' rb_removed=`arem'                                ///
            rb_actor_count=`atag' (max) rb_complete=para_fieldcmp            ///
            (first) rb_reject_index=`rejidx' rb_reject_ord=`rejord'         ///
            rb_reject_seq=`rejseq' rb_reject_ts=`rejts'                    ///
            rb_complete_index=`cmpidx' rb_complete_ord=`cmpord'             ///
            rb_complete_seq=`cmpseq' rb_complete_ts=`cmpts'                 ///
            rb_last_editor=`lastact' (last) rb_questions=`qlist',            ///
            by(interview__id rb_cycle) fast
        * With reduced exports the edit event count is still known, but the
        * number of distinct questions is not.  Missing (serialized as null)
        * prevents an unknowable cycle from being mislabeled as zero-change.
        if !`rbqknown' quietly replace rbq = .
        quietly replace rb_complete = !missing(rb_complete_ord)
        quietly gen byte rb_clockbad = rb_complete &                       ///
            rb_complete_ts<rb_reject_ts & !missing(rb_complete_ts,rb_reject_ts)
        quietly gen double rbm = (rb_complete_ts-rb_reject_ts)/60000 if    ///
            rb_complete & !rb_clockbad
        quietly gen byte rb_severity = cond(rb_complete & rbe==0,3,        ///
            cond(rb_complete & rbe>0 & (missing(rbq) | rbq==0),2,          ///
            cond(rb_complete & inrange(rbq,1,2) & rbm<10,2,                ///
            cond(!rb_complete,1,0))))
        quietly isid interview__id rb_cycle
        quietly save `"`REJDF'"'

        gsort interview__id -rb_severity rbm -rb_cycle
        quietly by interview__id: keep if _n==1
        quietly keep interview__id rbm rbe rbe_field rbq rb_set rb_removed ///
            rb_actor_count rb_last_editor rb_questions rb_complete         ///
            rb_clockbad rb_cycle
        quietly isid interview__id
        quietly save `"`REJF'"'
    }
    else {
        quietly clear
        quietly set obs 0
        quietly gen interview__id = ""
        quietly gen double rbm = .
        quietly gen double rbe = .
        quietly gen double rbe_field = .
        quietly gen double rbq = .
        quietly gen double rb_set = .
        quietly gen double rb_removed = .
        quietly gen double rb_actor_count = .
        quietly gen str244 rb_last_editor = ""
        quietly gen strL rb_questions = ""
        quietly gen byte rb_complete = 0
        quietly gen byte rb_clockbad = 0
        quietly gen long rb_cycle = .
        quietly save `"`REJF'"'
        quietly save `"`REJDF'"'
    }

    * ---- same-UTC-minute cross-interview answering --------------------------------
    * This is a screening bucket, not proof of simultaneity.  Retain the responsible
    * actor, exact UTC minute and counterpart interview instead of collapsing away
    * the evidence and later assigning it to whichever editor happened to be last.
    quietly use `"`EVD'"', clear
    local hasov 0
    quietly keep if para_fieldans & para_actor_key!="" & para_utc_valid & ///
        !missing(para_tsu) & !para_cawi
    if _N>0 {
        quietly gen double ov_minute_utc = floor(para_tsu/60000)
        collapse (count) ov_answers=para_one (first) ov_actor=para_actor, ///
            by(para_actor_key ov_minute_utc interview__id) fast
        quietly bysort para_actor_key ov_minute_utc: gen long ov_group_n = _N
        quietly keep if ov_group_n>=2
        if _N>0 {
            local hasov 1
            quietly isid para_actor_key ov_minute_utc interview__id
            quietly save `"`OVB'"'

            preserve
                collapse (count) ovm_actor=ov_minute_utc (sum) ov_answer_events=ov_answers ///
                    (first) ov_actor=ov_actor, by(interview__id para_actor_key) fast
                quietly isid interview__id para_actor_key
                quietly save `"`OVACT'"'
                quietly bysort interview__id: egen long ovm_total = total(ovm_actor)
                gsort interview__id -ovm_actor para_actor_key
                quietly by interview__id: keep if _n==1
                quietly rename ovm_actor ovm
                quietly rename para_actor_key ov_actor_key
                quietly keep interview__id ovm ovm_total ov_actor ov_actor_key
                quietly isid interview__id
                quietly save `"`OVS'"'
            restore

            preserve
                quietly rename interview__id ov_partner_id
                quietly rename ov_answers ov_partner_answers
                quietly keep para_actor_key ov_minute_utc ov_partner_id ov_partner_answers
                quietly save `"`OVP'"'
            restore
            quietly joinby para_actor_key ov_minute_utc using `"`OVP'"'
            quietly drop if interview__id==ov_partner_id
            quietly isid interview__id para_actor_key ov_minute_utc ov_partner_id
            quietly gen double ov_minute_ts = ov_minute_utc*60000
            format ov_minute_ts %tcCCYY-NN-DD_HH:MM
            quietly gen strL ov_item = ov_actor + " @ " + ///
                string(ov_minute_ts,"%tcCCYY-NN-DD_HH:MM") + " UTC with " + ov_partner_id
            quietly sort interview__id para_actor_key ov_minute_utc ov_partner_id
            quietly gen strL ov_detail_actor = ""
            quietly by interview__id para_actor_key: replace ov_detail_actor = ///
                cond(_n==1,"",ov_detail_actor[_n-1]) +                         ///
                cond(_n>1,"; ","") + ov_item
            preserve
                quietly by interview__id para_actor_key: keep if _n==_N
                quietly keep interview__id para_actor_key ov_detail_actor
                quietly isid interview__id para_actor_key
                quietly save `"`OVADF'"'
            restore
            quietly gen strL ov_detail = ""
            quietly by interview__id: replace ov_detail =                    ///
                cond(_n==1,"",ov_detail[_n-1]) +                             ///
                cond(_n>1,"; ","") + ov_item
            quietly save `"`OVDF'"'
            quietly by interview__id: keep if _n==_N
            quietly keep interview__id ov_detail
            quietly merge 1:1 interview__id using `"`OVS'"', assert(match) nogenerate
            quietly isid interview__id
            quietly save `"`OVF'"'
        }
    }
    if !`hasov' {
        quietly clear
        quietly set obs 0
        quietly gen interview__id = ""
        quietly gen long ovm = 0
        quietly gen long ovm_total = 0
        quietly gen str244 ov_actor = ""
        quietly gen str244 ov_actor_key = ""
        quietly gen strL ov_detail = ""
        quietly save `"`OVF'"', replace
        quietly save `"`OVDF'"', replace
        quietly clear
        quietly set obs 0
        quietly gen str80 interview__id = ""
        quietly gen str244 para_actor_key = ""
        quietly gen long ovm_actor = 0
        quietly gen long ov_answer_events = 0
        quietly gen str244 ov_actor = ""
        quietly save `"`OVACT'"', replace
        quietly clear
        quietly set obs 0
        quietly gen str80 interview__id = ""
        quietly gen str244 para_actor_key = ""
        quietly gen strL ov_detail_actor = ""
        quietly save `"`OVADF'"', replace
    }

    * ---- answers set after the first interviewer completion ----------------------
    quietly use `"`EVD'"', clear
    quietly sort interview__id para_ord para_seq
    tempvar pcopen pcactor pcrole pcq pcitem pcdetail
    quietly gen byte `pcopen' = 0
    quietly by interview__id: replace `pcopen' = cond(para_rej,1, ///
        cond(para_fieldcmp,0,cond(_n==1,0,`pcopen'[_n-1])))
    quietly gen byte __pc1 = para_fieldans & para_rework
    quietly gen byte __pca = (para_ans | para_rem) & para_rework
    quietly gen byte __pcn = __pca & !para_ivw
    quietly gen byte __pco = __pca & !`pcopen'
    quietly gen byte __pcfo = __pco & para_ivw
    quietly gen byte __pcno = __pco & !para_ivw
    quietly gen str244 `pcactor' = ""
    quietly gen str80 `pcrole' = ""
    capture confirm string variable responsible
    if !_rc quietly replace `pcactor' = strtrim(responsible) if __pco
    capture confirm string variable role
    if !_rc {
        quietly replace `pcrole' = strtrim(role) if __pco
        quietly replace `pcactor' = `pcrole' if __pco & `pcactor'==""
    }
    capture confirm variable para_qdisp, exact
    if !_rc quietly gen str244 `pcq' = para_qdisp if __pco
    else {
        capture confirm variable para_var, exact
        if !_rc quietly gen str244 `pcq' = para_var if __pco
        else quietly gen str244 `pcq' = ""
    }
    quietly gen strL `pcitem' = `pcactor' + " [" + `pcrole' + "] " + event + ///
        cond(`pcq'!=""," " + `pcq',"") +                              ///
        cond(!missing(para_tsu)," @ " + string(para_tsu,"%tcCCYY-NN-DD_HH:MM:SS") + " UTC", ///
        " @ event " + string(para_ord)) if __pco
    quietly gen strL `pcdetail' = ""
    quietly by interview__id: replace `pcdetail' =                         ///
        cond(_n==1,"",`pcdetail'[_n-1]) +                                 ///
        cond(__pco,cond(_n>1 & `pcdetail'[_n-1]!="","; ","") + `pcitem',"")
    collapse (sum) pce=__pc1 pce_all=__pca pce_nonfield=__pcn             ///
        pce_outside=__pco pce_field_outside=__pcfo                         ///
        pce_nonfield_outside=__pcno (last) pce_detail=`pcdetail',           ///
        by(interview__id) fast
    quietly save `"`PCEF'"'

    * ---- NEW: validation errors still open at the end (full exports only) ---------
    local hasve 0
    quietly use `"`EVD'"', clear
    capture confirm variable para_qkey
    if !_rc {
        quietly keep if (para_inv | para_ev=="questiondeclaredvalid") & para_qkey!=""
        if _N>0 {
            local hasve 1
            quietly bysort interview__id para_qkey (para_ord para_seq): keep if _n==_N
            quietly gen byte __bad = para_inv
            collapse (sum) verr=__bad, by(interview__id) fast
            quietly save `"`VERF'"'
        }
    }
    if !`hasve' {
        quietly clear
        quietly set obs 0
        quietly gen interview__id = ""
        quietly gen long verr = .
        quietly save `"`VERF'"', replace
    }

    * ---- NEW: distinct questions answered (coverage) ------------------------------
    local hasnq 0
    quietly use `"`EVD'"', clear
    capture confirm variable para_qkey
    if !_rc {
        quietly keep if para_fieldans & para_firstpass & para_qkey!=""
        if _N>0 {
            local hasnq 1
            quietly bysort interview__id para_qkey: keep if _n==1
            collapse (count) nq=para_one, by(interview__id) fast
            quietly save `"`NQF'"'
        }
    }
    if !`hasnq' {
        quietly clear
        quietly set obs 0
        quietly gen interview__id = ""
        quietly gen long nq = .
        quietly save `"`NQF'"', replace
    }

    * ---- NEW: peer-relative speed (controls for question mix) ---------------------
    * Expected time = sum over this interview's timed questions of the survey-median
    * seconds for those same questions. An interview finishing its own question mix
    * in a small fraction of the time colleagues need is speeding relative to peers,
    * whatever the absolute thresholds.
    local hasrt 0
    if `haspeerq' {
        quietly use `"`EVD'"', clear
        quietly keep if para_firstpass & !missing(para_ansgap) & para_var!=""
        if _N>0 {
            quietly merge m:1 para_var using `"`QTK'"', keep(master match) nogenerate
            collapse (sum) __act=para_ansgap __exp=qmed, by(interview__id) fast
            quietly gen double rt = __act/__exp if __exp>0
            quietly keep interview__id rt
            quietly keep if !missing(rt)
            if _N>0 {
                local hasrt 1
                quietly save `"`RTF'"'
            }
        }
    }
    if !`hasrt' {
        quietly clear
        quietly set obs 0
        quietly gen interview__id = ""
        quietly gen double rt = .
        quietly save `"`RTF'"', replace
    }

    * ---- longest first-pass fast streak (actor/session safe) ----------------------
    quietly use `"`EVD'"', clear
    quietly keep if para_firstpass & para_session>0
    if _N>0 {
        collapse (max) fr=para_fastrun, by(interview__id) fast
        quietly save `"`FRF'"'
    }
    else {
        quietly clear
        quietly set obs 0
        quietly gen interview__id = ""
        quietly gen long fr = 0
        quietly save `"`FRF'"'
    }

    * ---- actor-by-interview behaviour table ---------------------------------------
    * This table powers the league and provides primary-actor metrics for the queue.
    * Correction-only actors remain visible but never inherit the primary actor's S/B.
    quietly use `"`EVD'"', clear
    quietly keep if para_ivw & para_actor_key!=""
    if `haspeerq' quietly merge m:1 para_var using `"`QTK'"', keep(master match) nogenerate
    else quietly gen double qmed = .
    tempvar aaf arf aff anf agf aexp aact aqtag astag atbad albad amode acawi aoff
    quietly gen byte `aaf' = para_fieldans & para_firstpass
    quietly gen byte `arf' = para_fieldrem & para_firstpass
    quietly gen byte `aff' = para_fast if para_firstpass
    quietly gen byte `anf' = para_night & para_firstpass
    quietly gen double `agf' = para_ansgap if para_firstpass
    quietly gen double `aact' = para_ansgap if para_firstpass
    quietly gen double `aexp' = qmed if para_firstpass & !missing(para_ansgap)
    quietly gen byte `amode' = para_fieldans & para_firstpass & missing(para_cawi)
    quietly gen byte `atbad' = ((para_clockback | para_time_missing) & para_firstpass) | `amode'
    quietly gen byte `albad' = (para_local_missing & para_firstpass) | `amode'
    quietly gen byte `acawi' = para_cawi if para_fieldans & para_firstpass
    quietly gen double `aoff' = para_off if para_fieldans & para_firstpass
    capture confirm variable para_qkey, exact
    if !_rc quietly egen byte `aqtag' = tag(interview__id para_actor_key para_qkey) ///
        if `aaf' & para_qkey!=""
    else {
        capture confirm variable para_var, exact
        if !_rc quietly egen byte `aqtag' = tag(interview__id para_actor_key para_var) ///
            if `aaf' & para_var!=""
        else quietly gen byte `aqtag' = 0
    }
    quietly egen byte `astag' = tag(interview__id para_actor_key para_session) ///
        if para_brk & para_session>0
    local avecs ""
    if !`lite' {
        forvalues h = 0/23 {
            quietly gen byte ah`h' = `aaf' & !missing(para_tsl) & hh(para_tsl)==`h'
            local avecs "`avecs' ah`h'=ah`h'"
        }
        forvalues g = 0/39 {
            quietly gen byte ag`g' = `aaf' & !missing(para_ansgap) & ///
                floor(para_ansgap*2)==`g'
            local avecs "`avecs' ag`g'=ag`g'"
        }
        quietly gen byte ag40 = `aaf' & !missing(para_ansgap) & para_ansgap>=20
        local avecs "`avecs' ag40=ag40"
    }
    collapse (sum) a_events=para_one a_answers=para_fieldans                  ///
        a_answers_first=`aaf' a_removed=para_fieldrem a_removed_first=`arf'  ///
        a_active_s=para_act a_active_first_s=para_act_first a_fast=`aff'     ///
        a_night=`anf' a_questions=`aqtag' a_sessions=`astag'                ///
        a_actual=`aact' a_expected=`aexp' a_timebad=`atbad'                 ///
        a_localbad=`albad' a_mode_unknown_n=`amode' `avecs'                 ///
        (count) a_timed_total=para_ansgap a_timed=`agf'                      ///
        (p50) a_med_total=para_ansgap a_med=`agf'                            ///
        (p90) a_p90_total=para_ansgap a_p90=`agf'                            ///
        (max) a_fast_run=para_fastrun                                        ///
        (min) a_cawi_min=`acawi' a_off_min=`aoff'                           ///
        (max) a_cawi_max=`acawi' a_off_max=`aoff'                           ///
        (first) actor=para_actor primary_name=para_primary                   ///
        first_name=para_firstinterviewer last_name=para_lasteditor,          ///
        by(interview__id para_actor_key) fast
    * Dropdown and league contributors must have made a substantive answer edit.
    * A sync/resume/completion-only account is workflow context, not an actor whose
    * behaviour can be scored.  Removal-only correction actors remain visible.
    quietly keep if a_answers>0 | a_removed>0
    quietly gen double a_active_min = a_active_s/60
    quietly gen double a_active_first_min = a_active_first_s/60
    quietly gen double a_fast_share = a_fast/a_timed if a_timed>0
    quietly gen double a_night_share = a_night/a_answers_first if a_answers_first>0
    quietly gen double a_churn = a_removed/max(a_answers,1)
    quietly gen double a_peer = a_actual/a_expected if a_expected>0
    quietly gen byte a_timing_ok = a_timebad==0
    quietly gen byte a_local_ok = a_localbad==0
    quietly gen byte a_iscawi = a_cawi_min==1 & a_cawi_max==1
    quietly gen byte a_mixedmode = a_cawi_min!=a_cawi_max & ///
        !missing(a_cawi_min,a_cawi_max)
    quietly gen byte a_mode_unknown = a_answers_first>0 & a_mode_unknown_n>0
    quietly gen double a_tzh = a_off_min/3600000 if !missing(a_off_min)
    quietly gen byte a_tzodd = a_answers_first>0 & ///
        (missing(a_off_min) | a_off_min!=a_off_max)
    if `hastz' quietly replace a_tzodd = 1 if a_answers_first>0 & ///
        !missing(a_off_min) & a_off_min!=`tzmode'
    quietly bysort interview__id: egen double __aint = total(a_answers)
    quietly gen double a_answer_share = a_answers/__aint if __aint>0
    quietly gen byte a_primary = para_actor_key==ustrlower(strtrim(primary_name)) & primary_name!=""
    quietly gen byte a_first = para_actor_key==ustrlower(strtrim(first_name)) & first_name!=""
    quietly gen byte a_last = para_actor_key==ustrlower(strtrim(last_name)) & last_name!=""
    quietly drop __aint a_active_s a_active_first_s a_actual a_expected      ///
        a_timebad a_localbad a_mode_unknown_n a_cawi_min a_cawi_max a_off_min a_off_max
    quietly merge 1:1 interview__id para_actor_key using `"`OVACT'"', ///
        keep(master match) nogenerate
    quietly replace ovm_actor = 0 if missing(ovm_actor)
    quietly replace ov_answer_events = 0 if missing(ov_answer_events)
    quietly merge 1:1 interview__id para_actor_key using `"`OVADF'"', ///
        keep(master match) nogenerate
    quietly replace ov_detail_actor = "" if missing(ov_detail_actor)
    quietly isid interview__id para_actor_key
    quietly save `"`ACTF'"'
    preserve
        quietly keep if a_primary
        quietly keep interview__id a_answers a_answers_first a_active_min       ///
            a_active_first_min a_timed a_med a_p90 a_fast_share a_night_share  ///
            a_churn a_peer a_fast_run a_questions a_sessions a_answer_share     ///
            a_timing_ok a_local_ok a_iscawi a_mixedmode a_mode_unknown a_tzh a_tzodd
        foreach v in answers answers_first active_min active_first_min timed med ///
            p90 fast_share night_share churn peer fast_run questions sessions   ///
            answer_share timing_ok local_ok iscawi mixedmode mode_unknown tzh tzodd {
            quietly rename a_`v' pa_`v'
        }
        quietly isid interview__id
        quietly save `"`ACTPF'"'
    restore

    * ---- skip cascades ------------------------------------------------------------
    * Structural/workflow review signals always come from the complete stream.
    * vars() may focus the expandable removal detail, but must never make a case's
    * cascade counts/tier disappear from the Behaviour queue.
    di as txt "  [behaviour 3/5] reconstructing removal histories ..."
    quietly use `"`skipbase'"', clear
    local __skipout ""
    if `"`skiphtml'"'!="" & `"`vars'"'=="" local __skipout                  ///
        `"html(`"`skiphtml'"') top(`skiptop') replace"'
    quietly _suso_para_skips , cascade(`cascade') window(`window') qx(`"`qx'"') ///
        data(`"`data'"') detail(`"`RSD'"') hqurl(`"`hqbase'"') `allroles'     ///
        precomputed(`skiptoken') statusmap(`"`QWS'"') `__skipout'
    local ncasc = r(ncascades)
    local nhist = r(nhistories)
    local nremevents = r(nremovalevents)
    local noutsideevents = r(noutsideevents)
    local ncompactevents = r(ncompactevents)
    local nwiped = r(nwiped)
    local naffectedq = r(naffectedquestions)
    local nopen = r(nopen)
    local nreanswered = r(nreanswered)
    local nunknown = r(nunknown)
    local nfinalanswered = r(nfinalanswered)
    local nanswereddisabled = r(nanswereddisabled)
    local nexpectedblank = r(nexpectedblank)
    local nfinalcheck = r(nfinalcheck)
    local hasfinaldata = r(hasfinaldata)
    local trignames `"`r(triggers)'"'
    tempname RT
    capture matrix `RT' = r(triggers_stats)
    quietly keep interview__id n_removal_histories removed_view outside_removed ///
        n_cascades casc_removed casc_questions casc_open ///
        casc_reanswered casc_unknown casc_finalanswered casc_answered_disabled ///
        casc_expectedblank                                                       ///
        casc_blank_enabled casc_logicunknown casc_notindata casc_finalcheck      ///
        casc_datachecked n_triggers
    quietly save `"`SK'"'

    local rsdpath `"`RSD'"'
    if `"`vars'"'!="" {
        quietly use `"`skipbase'"', clear
        local __skipout ""
        if `"`skiphtml'"'!="" local __skipout                                ///
            `"html(`"`skiphtml'"') top(`skiptop') replace"'
        quietly _suso_para_skips , cascade(`cascade') window(`window') qx(`"`qx'"') ///
            data(`"`data'"') detail(`"`RSDFOCUS'"') vars(`"`vars'"')             ///
            hqurl(`"`hqbase'"') `allroles' precomputed(`skiptoken')            ///
            statusmap(`"`QWS'"') `__skipout'
        * Point to the focused path even when it was not created: the later
        * confirm-file guard then correctly renders no scoped detail cards.
        local rsdpath `"`RSDFOCUS'"'
    }

    * ---- timing + flags (defaults; live thresholds are client-side) ---------------
    di as txt "  [behaviour 4/5] collapsing the cached stream to interview metrics ..."
    quietly use `"`EVD'"', clear
    quietly _suso_para_timing , by(interview) gapmins(`gapmins') fastsecs(`fastsecs') ///
        `allroles' precomputed(`derivecap')
    quietly merge 1:1 interview__id using `"`SK'"', keep(master match) nogenerate
    foreach v in n_removal_histories removed_view outside_removed              ///
        n_cascades casc_removed casc_questions casc_open casc_reanswered ///
        casc_unknown casc_finalanswered casc_answered_disabled casc_expectedblank ///
        casc_blank_enabled                                                       ///
        casc_logicunknown casc_notindata casc_finalcheck casc_datachecked n_triggers {
        quietly replace `v' = 0 if missing(`v')
    }
    if !`lite' {
        quietly merge 1:1 interview__id using `"`HHF'"', keep(master match) nogenerate
        quietly merge 1:1 interview__id using `"`GGF'"', keep(master match) nogenerate
        forvalues h = 0/23 {
            quietly replace h`h' = 0 if missing(h`h')
        }
        forvalues g = 0/40 {
            quietly replace g`g' = 0 if missing(g`g')
        }
    }
    quietly merge 1:1 interview__id using `"`QWS'"', keep(master match) nogenerate
    if "`fdimvars'"!="" {
        quietly merge 1:1 interview__id using `"`FLK'"', keep(master match) nogenerate
    }
    * merge the new per-interview signals
    quietly gen ikey = ""
    if `haskey' {
        quietly rename ikey __ikfill
        quietly merge 1:1 interview__id using `"`KEYF'"', keep(master match) nogenerate
        quietly replace ikey = "" if missing(ikey)
        quietly drop __ikfill
    }
    quietly gen str40 hq_assignment = ""
    if `hasassignment' {
        quietly rename hq_assignment __hqafill
        quietly merge 1:1 interview__id using `"`HQF'"', keep(master match) nogenerate
        quietly replace hq_assignment = "" if missing(hq_assignment)
        quietly drop __hqafill
    }
    label variable hq_assignment "Survey Solutions assignment id (HTML deep link)"
    capture drop tzh tzodd
    quietly merge 1:1 interview__id using `"`TZF'"',  keep(master match) nogenerate
    quietly replace tzodd = 1 if missing(tzh) & n_answers_first>0
    quietly replace tzodd = 0 if missing(tzodd)
    quietly merge 1:1 interview__id using `"`REJF'"', keep(master match) nogenerate
    quietly replace rb_complete = 0 if missing(rb_complete)
    quietly replace rb_clockbad = 0 if missing(rb_clockbad)
    quietly replace rb_last_editor = "" if missing(rb_last_editor)
    quietly replace rb_questions = "" if missing(rb_questions)
    quietly merge 1:1 interview__id using `"`OVF'"',  keep(master match) nogenerate
    quietly replace ovm = 0 if missing(ovm)
    quietly replace ovm_total = 0 if missing(ovm_total)
    quietly replace ov_actor = "" if missing(ov_actor)
    quietly replace ov_actor_key = "" if missing(ov_actor_key)
    quietly replace ov_detail = "" if missing(ov_detail)
    quietly merge 1:1 interview__id using `"`PCEF'"', keep(master match) nogenerate
    quietly replace pce = 0 if missing(pce)
    quietly replace pce_all = 0 if missing(pce_all)
    quietly replace pce_nonfield = 0 if missing(pce_nonfield)
    quietly replace pce_outside = 0 if missing(pce_outside)
    quietly replace pce_field_outside = 0 if missing(pce_field_outside)
    quietly replace pce_nonfield_outside = 0 if missing(pce_nonfield_outside)
    quietly replace pce_detail = "" if missing(pce_detail)
    quietly merge 1:1 interview__id using `"`VERF'"', keep(master match) nogenerate
    quietly merge 1:1 interview__id using `"`NQF'"',  keep(master match) nogenerate
    quietly merge 1:1 interview__id using `"`RTF'"',  keep(master match) nogenerate
    quietly merge 1:1 interview__id using `"`FRF'"',  keep(master match) nogenerate
    quietly replace fr = 0 if missing(fr)
    quietly merge 1:1 interview__id using `"`ACTPF'"', keep(master match) nogenerate
    * Canonical queue/CSV behaviour belongs to the primary first-pass actor.
    quietly gen byte interview_timing_ok = timing_ok
    quietly gen byte interview_local_time_ok = local_time_ok
    quietly gen byte interview_iscawi = iscawi
    quietly gen byte interview_mixedmode = mixedmode
    quietly gen byte interview_mode_unknown = mode_unknown
    quietly gen double interview_tzh = tzh
    quietly gen byte interview_tzodd = tzodd_first_all | tzodd
    quietly replace n_timed = pa_timed if !missing(pa_timed)
    quietly replace ans_med_s = pa_med if !missing(pa_med)
    quietly replace ans_p90_s = pa_p90 if !missing(pa_p90)
    quietly replace fast_share = pa_fast_share if !missing(pa_fast_share)
    quietly replace night_share = pa_night_share if !missing(pa_night_share)
    quietly replace churn = pa_churn if !missing(pa_churn)
    quietly replace rt = pa_peer if !missing(pa_peer)
    quietly replace fast_run = pa_fast_run if !missing(pa_fast_run)
    quietly replace fr = pa_fast_run if !missing(pa_fast_run)
    quietly replace timing_ok = pa_timing_ok if !missing(pa_timing_ok)
    quietly replace local_time_ok = pa_local_ok if !missing(pa_local_ok)
    quietly replace iscawi = pa_iscawi if !missing(pa_iscawi)
    quietly replace mixedmode = pa_mixedmode if !missing(pa_mixedmode)
    quietly replace mode_unknown = pa_mode_unknown if !missing(pa_mode_unknown)
    quietly replace tzh = pa_tzh if !missing(pa_tzh)
    quietly replace tzodd = pa_tzodd if !missing(pa_tzodd)
    quietly _suso_para_flags , gapmins(`gapmins') fastsecs(`fastsecs')
    quietly gen __d0 = string(dofc(t_first_first_local), "%tdCCYY-NN-DD")
    quietly replace __d0 = "" if missing(t_first_first_local)
    quietly gen __d1 = string(dofc(t_last_first_local), "%tdCCYY-NN-DD")
    quietly replace __d1 = "" if missing(t_last_first_local)
    char _dta[suso_paradata] timing
    local nints = _N
    quietly count if started
    local nstarted = r(N)
    quietly count if n_completed>0
    local ncompleted = r(N)
    local nuntouched = `nints' - `nstarted'
    quietly count if started & iscawi
    local ncawi = r(N)
    quietly summarize active_min
    local tothrc : di %12.0fc r(sum)/60
    local tothrc = trim("`tothrc'")
    local nintsc : di %12.0fc `nints'
    local nintsc = trim("`nintsc'")
    local nstartedc : di %12.0fc `nstarted'
    local nstartedc = trim("`nstartedc'")
    local ncompletedc : di %12.0fc `ncompleted'
    local ncompletedc = trim("`ncompletedc'")
    local nuntouchedc : di %12.0fc `nuntouched'
    local nuntouchedc = trim("`nuntouchedc'")
    local nskipaction = cond(`"`data'"'!="", `nfinalcheck', `nopen'+`nunknown')
    local warnc = cond(`nskipaction'>0, "warn", "dim")
    local remsev = cond(`nfinalcheck'>0,"w","g")
    local histplural = cond(`nhist'==1,"y","ies")
    quietly save `"`MERGED'"'

    * ---- write the HTML -----------------------------------------------------------
    local now = trim("`c(current_date)' `c(current_time)'")
    tempname fh
    di as txt "  [behaviour 5/5] serialising the interactive HTML ..."
    quietly file open `fh' using `"`saving'"', write replace text
    file write `fh' `"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">"' _n
    file write `fh' `"<title>`htitle'</title><style>"' _n
    file write `fh' `"body{margin:0;font-family:Segoe UI,Arial,sans-serif;background:#f4f5f7;color:#1a1a1a}"' _n
    file write `fh' `".logobar{background:#fff;padding:10px 28px;border-bottom:1px solid #e0e0e0}"' _n
    file write `fh' `".logobar .wbtxt{font-size:13px;letter-spacing:.06em;color:#002244;font-weight:600}"' _n
    file write `fh' `".logobar .wbtxt span{color:#8a8a8a;font-weight:400}"' _n
    file write `fh' `".mast{background:#002244;color:#fff;padding:18px 28px}"' _n
    file write `fh' `".mast h1{margin:0;font-size:22px;font-weight:600}"' _n
    file write `fh' `".mast .sub{color:#c9d4e0;font-size:12.5px;margin-top:5px}"' _n
    file write `fh' `".wrap{max-width:1080px;margin:0 auto;padding:16px 28px 40px}"' _n
    file write `fh' `".cards{display:flex;flex-wrap:wrap;gap:10px;margin:12px 0 4px}"' _n
    file write `fh' `".card{flex:1 1 130px;background:#fff;border:1px solid #e3e6ea;border-radius:8px;padding:10px 13px;border-top:3px solid #002244}"' _n
    file write `fh' `".card.dim{border-top-color:#9aa7b5}.card.warn{border-top-color:#C9A227}.card.bad{border-top-color:#a33}"' _n
    file write `fh' `".card .v{font-size:20px;font-weight:700;color:#002244}"' _n
    file write `fh' `".card .k{font-size:11px;color:#666;margin-top:2px;text-transform:uppercase;letter-spacing:.04em}"' _n
    file write `fh' `".panel{background:#fff;border:1px solid #e3e6ea;border-radius:8px;padding:12px 16px;margin:12px 0;box-shadow:0 2px 6px rgba(0,0,0,.06)}"' _n
    file write `fh' `".prow{display:flex;flex-wrap:wrap;gap:14px;align-items:flex-end}"' _n
    file write `fh' `".prow+.prow{margin-top:10px;padding-top:10px;border-top:1px dashed #e3e6ea}"' _n
    file write `fh' `".ctrl{display:flex;flex-direction:column;gap:3px}"' _n
    file write `fh' `".ctrl label{font-size:10.5px;color:#555;text-transform:uppercase;letter-spacing:.03em}"' _n
    file write `fh' `".ctrl input,.ctrl select{font-size:13px;padding:4px 6px;border:1px solid #c9cfd6;border-radius:5px;min-width:64px}"' _n
    file write `fh' `"#c_resp{min-width:210px}"' _n
    file write `fh' `".pbtn{background:#002244;color:#fff;border:0;border-radius:5px;padding:7px 14px;font-size:12.5px;cursor:pointer}"' _n
    file write `fh' `".pbtn.ghost{background:#fff;color:#002244;border:1px solid #c9cfd6}"' _n
    file write `fh' `".verdict{margin:10px 0;padding:10px 14px;border-radius:8px;font-size:13.5px;font-weight:600}"' _n
    file write `fh' `".verdict.ok{background:#eaf5ec;color:#1e6b34;border:1px solid #bfe0c8}"' _n
    file write `fh' `".verdict.warn{background:#fdf6e3;color:#7a5b00;border:1px solid #ecd9a0}"' _n
    file write `fh' `".verdict.bad{background:#fbeaea;color:#8a1f1f;border:1px solid #e8bcbc}"' _n
    file write `fh' `"h2{font-size:15px;color:#002244;border-bottom:2px solid #C9A227;padding-bottom:4px;margin:24px 0 4px}"' _n
    file write `fh' `".note{font-size:12px;color:#555;margin:2px 0 8px}"' _n
    file write `fh' `"section{background:#fff;border:1px solid #e3e6ea;border-radius:8px;padding:8px 16px 14px;margin-top:8px}"' _n
    file write `fh' `"table{border-collapse:collapse;width:100%;font-size:12.5px}"' _n
    file write `fh' `"th{background:#002244;color:#fff;text-align:left;padding:6px 8px;font-weight:600}"' _n
    file write `fh' `"th.srt{cursor:pointer}th.srt:hover{background:#0a3560}"' _n
    file write `fh' `"td{padding:5px 8px;border-bottom:1px solid #eef0f2}tr:nth-child(even) td{background:#fafbfc}"' _n
    file write `fh' `"td.r,th.r{text-align:right}tr.hot td{background:#fdf6e3}"' _n
    file write `fh' `".mono{font-family:Consolas,monospace}"' _n
    file write `fh' `".bar{display:inline-block;height:9px;background:#C9A227;border-radius:2px;vertical-align:middle}"' _n
    file write `fh' `".nodata{color:#888;font-size:12px}"' _n
    file write `fh' `".foot{font-size:11px;color:#777;margin-top:26px;line-height:1.5}"' _n
    file write `fh' `"#lite_note,#q_more,#l_more,#w_none,#n_act{font-size:11.5px;color:#8a6d00}"' _n
    file write `fh' `".tier{display:inline-block;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:700;letter-spacing:.03em}"' _n
    file write `fh' `".tier.A{background:#fbeaea;color:#8a1f1f;border:1px solid #e8bcbc}"' _n
    file write `fh' `".tier.V{background:#fdf6e3;color:#7a5b00;border:1px solid #ecd9a0}"' _n
    file write `fh' `".tier.W{background:#eef3f8;color:#2a4a6b;border:1px solid #c9d4e0}"' _n
    file write `fh' `".chip{display:inline-block;margin:1px 3px 1px 0;padding:1px 7px;border-radius:9px;font-size:10.5px;background:#eef3f8;color:#2a4a6b;border:1px solid #c9d4e0;cursor:default}"' _n
    file write `fh' `".chip.hard{background:#fbeaea;color:#8a1f1f;border-color:#e8bcbc;font-weight:700}"' _n
    file write `fh' `".chip.info{background:#f2f2f2;color:#666;border-color:#ddd}"' _n
    file write `fh' `".ev{font-size:12px;color:#333;margin-top:3px;line-height:1.45}"' _n
    file write `fh' `".ev .cav{color:#8a6d00}"' _n
    file write `fh' `".wrow{cursor:pointer}"' _n
    file write `fh' `".wdet td{background:#f7f9fb !important;border-left:3px solid #C9A227}"' _n
    file write `fh' `".wdet .facts{font-size:12px;color:#444;margin:4px 0 8px}"' _n
    file write `fh' `".cpy{display:inline-block;margin-left:6px;padding:0 6px;border:1px solid #c9cfd6;border-radius:4px;font-size:10.5px;color:#2a4a6b;cursor:pointer;background:#fff}"' _n
    file write `fh' `".cpy:hover{background:#eef3f8}"' _n
    file write `fh' `".hqlinks{display:inline-flex;gap:6px;margin-left:10px;vertical-align:middle}.hqlink{display:inline-block;padding:3px 8px;border-radius:5px;background:#002244;color:#fff;text-decoration:none;font-size:10.5px;font-weight:600}.hqlink.secondary{background:#fff;color:#002244;border:1px solid #9fb0c1}.hqlink:hover{text-decoration:underline}"' _n
    file write `fh' `".legend{font-size:11.5px;color:#555;margin:6px 0 2px}"' _n
    file write `fh' `".hv-privacy{background:#edf5fb;border:1px solid #bfd6ea;border-radius:7px;padding:9px 11px;color:#173b5e;font-size:12px;margin-bottom:10px}"' _n
    file write `fh' `".hv-setup,.hv-filters,.hv-viewbar{display:flex;flex-wrap:wrap;gap:10px;align-items:flex-end}.hv-setup .ctrl{flex:1 1 240px}.hv-setup input[type=file],#hv_id{width:100%;box-sizing:border-box}"' _n
    file write `fh' `".hv-status{font-size:12px;color:#315777;margin:8px 0}.hv-status.bad{color:#8a1f1f;font-weight:600}#hv_progress{width:100%;height:8px;margin:4px 0}"' _n
    file write `fh' `".hv-idbox{position:relative}.hv-suggestions{display:none;position:absolute;left:0;right:0;top:100%;z-index:9;background:#fff;border:1px solid #c9cfd6;border-radius:0 0 6px 6px;box-shadow:0 5px 14px rgba(0,0,0,.12);max-height:210px;overflow:auto}"' _n
    file write `fh' `".hv-suggestion{display:block;width:100%;padding:6px 8px;text-align:left;background:#fff;border:0;border-bottom:1px solid #eef0f2;cursor:pointer;color:#173b5e}.hv-suggestion:hover{background:#edf5fb}"' _n
    file write `fh' `".hv-filters{margin:12px 0 8px}.hv-filters .ctrl{flex:1 1 180px}.hv-summary{font-size:12px;font-weight:600;color:#173b5e;margin:8px 0}.hv-viewbar{justify-content:flex-end;margin-bottom:8px}"' _n
    file write `fh' `".hv-timeline{position:relative;margin:4px 0 0 9px;padding-left:25px;border-left:2px solid #c9d4e0}.hv-event{position:relative;background:#fff;border:1px solid #e1e5e9;border-left:4px solid #9aa7b5;border-radius:7px;padding:8px 10px;margin:0 0 9px}"' _n
    file write `fh' `".hv-event:before{content:'';position:absolute;left:-35px;top:12px;width:10px;height:10px;border-radius:50%;background:#9aa7b5;border:2px solid #fff}.hv-event.answer{border-left-color:#2e75b6}.hv-event.answer:before{background:#2e75b6}.hv-event.workflow{border-left-color:#C9A227}.hv-event.workflow:before{background:#C9A227}.hv-event.warn{border-left-color:#a33}.hv-event.warn:before{background:#a33}.hv-event.session{border-left-color:#2d7d46}.hv-event.session:before{background:#2d7d46}"' _n
    file write `fh' `".hv-event-head{display:flex;gap:8px;align-items:center;flex-wrap:wrap}.hv-order{color:#667}.hv-kind{font-weight:700;color:#002244}.hv-gap{margin-left:auto;color:#667;font-size:11px;background:#f1f3f5;border-radius:10px;padding:1px 7px}"' _n
    file write `fh' `".hv-event-meta{display:flex;gap:12px;flex-wrap:wrap;color:#667;font-size:11px;margin-top:4px}.hv-local{font-weight:600;color:#315777}.hv-actor{font-size:12px;margin-top:5px}.hv-parameters{white-space:pre-wrap;overflow-wrap:anywhere;background:#f6f8fa;border-radius:4px;padding:5px 7px;margin-top:6px;color:#333}"' _n
    file write `fh' `".hv-tablewrap{overflow:auto;max-height:70vh;border:1px solid #e3e6ea}.hv-tablewrap th{position:sticky;top:0;z-index:2;white-space:nowrap}.hv-tablewrap td{vertical-align:top}.hv-raw-parameters{min-width:280px;white-space:pre-wrap;overflow-wrap:anywhere}"' _n
    file write `fh' `".hv-bulk{display:none;gap:6px;margin-right:auto}"' _n
    file write `fh' `".hvc-wrap{border:1px solid #dbe1e8;border-radius:8px;background:#fff;max-height:72vh;overflow:auto;overscroll-behavior:contain;margin-top:2px}"' _n
    file write `fh' `".hvc-head,.hvc-row{display:grid;grid-template-columns:52px minmax(140px,180px) minmax(180px,1fr) minmax(110px,200px) 108px 84px;gap:0 10px;align-items:center;min-width:760px;box-sizing:border-box}"' _n
    file write `fh' `".hvc-head{position:sticky;top:0;z-index:4;background:#f4f6f9;border-bottom:1px solid #dbe1e8;padding:6px 12px;font-size:10px;line-height:13px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:#5a6b7d}"' _n
    file write `fh' `".hvc-day{position:sticky;top:25px;z-index:3;background:#e9eef5;color:#173b5e;font-weight:700;font-size:11px;padding:4px 12px;border-bottom:1px solid #d5dde6;min-width:760px;box-sizing:border-box}"' _n
    file write `fh' `".hvc-gapsep{padding:3px 12px;text-align:center;font-size:10.5px;color:#8a6d00;background:#fffbea;border-top:1px dashed #e8d795;border-bottom:1px dashed #e8d795;min-width:760px;box-sizing:border-box}"' _n
    file write `fh' `".hvc-row{padding:3px 12px;border-bottom:1px solid #f0f2f5;border-left:3px solid #b7c1cc;font-size:12px;line-height:1.55;cursor:pointer}"' _n
    file write `fh' `".hvc-row:hover{background:#f4f8fc}"' _n
    file write `fh' `".hvc-row.open{background:#eef4fa}"' _n
    file write `fh' `".hvc-row.answer{border-left-color:#2e75b6}.hvc-row.workflow{border-left-color:#C9A227}.hvc-row.warn{border-left-color:#a33;background:#fffafa}.hvc-row.warn:hover{background:#fdf1f1}.hvc-row.session{border-left-color:#2d7d46}"' _n
    file write `fh' `".hvc-ord{color:#8a97a5;font-size:11px}"' _n
    file write `fh' `".hvc-kind{font-weight:600;color:#002244;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}"' _n
    file write `fh' `".hvc-par{color:#3d454d;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}"' _n
    file write `fh' `".hvc-par .pp{color:#b9c2cc;padding:0 1px}"' _n
    file write `fh' `".hvc-par.dim,.hvc-time.dim,.hvc-actor.dim{color:#b9c2cc}"' _n
    file write `fh' `".hvc-actor{color:#556575;font-size:11.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}"' _n
    file write `fh' `".hvc-time{text-align:right;white-space:nowrap;font-size:11.5px;color:#315777}"' _n
    file write `fh' `".hvc-time.approx{color:#8a6d00}"' _n
    file write `fh' `".hvc-gap{text-align:right}"' _n
    file write `fh' `".hvc-pill{display:inline-block;font-size:10.5px;border-radius:9px;padding:0 7px;background:#eef1f4;color:#5a6b7d}"' _n
    file write `fh' `".hvc-pill.g2{background:#fdf3d7;color:#8a6d00}"' _n
    file write `fh' `".hvc-pill.rev{background:#fbeaea;color:#8a1f1f;font-weight:700}"' _n
    file write `fh' `".hvc-det{padding:8px 14px 10px;background:#f8fafc;border-bottom:1px solid #e2e8ee;border-left:3px solid #9fb0c1;font-size:12px;cursor:default;min-width:760px;box-sizing:border-box}"' _n
    file write `fh' `".hvc-grid{display:grid;grid-template-columns:130px minmax(180px,1fr) 130px minmax(180px,1fr);gap:3px 12px;margin:0 0 8px}"' _n
    file write `fh' `".hvc-grid dt{color:#66727e;font-size:10.5px;text-transform:uppercase;letter-spacing:.04em;align-self:center}"' _n
    file write `fh' `".hvc-grid dd{margin:0;color:#26313c;overflow-wrap:anywhere}"' _n
    file write `fh' `".hvc-plabel{display:flex;align-items:center;gap:4px;font-size:10.5px;text-transform:uppercase;letter-spacing:.04em;color:#66727e;margin:2px 0 3px}"' _n
    file write `fh' `".hvc-det .hv-parameters{margin-top:0;max-height:200px;overflow:auto}"' _n
    file write `fh' `"@media print{.panel{position:static;box-shadow:none}.pbtn,.cpy,.hqlinks,.hv-bulk{display:none}.hvc-wrap{max-height:none;overflow:visible}.hvc-head,.hvc-day{position:static}.sbody{display:block!important}.chipnav{position:static}.shead .chev{display:none}}"' _n
    file write `fh' `".datasetline{color:#68737f;font-size:12px;margin:-4px 0 12px}"' _n
    file write `fh' `".chipnav{position:sticky;top:0;z-index:6;background:#f4f5f7;padding:8px 0 6px;margin:0 0 4px;border-bottom:1px solid #e3e6ea;display:flex;gap:6px;flex-wrap:wrap;align-items:center}"' _n
    file write `fh' `".chipx{display:inline-flex;align-items:center;gap:6px;background:#fff;border:1px solid #dfe4e8;border-radius:14px;padding:4px 11px;font-size:12px;color:#33404d;text-decoration:none;cursor:pointer}"' _n
    file write `fh' `".chipx:hover{border-color:#9fb2c4}"' _n
    file write `fh' `".chipx .n{font-weight:700;font-size:11px;padding:0 6px;border-radius:8px;font-variant-numeric:tabular-nums}"' _n
    file write `fh' `".chipx .n.b{background:#fbeaea;color:#8a1f1f}.chipx .n.w{background:#fdf6e3;color:#7a5b00}.chipx .n.g{color:#1e6b34}"' _n
    file write `fh' `".chiputil{margin-left:auto;color:#556575;background:transparent;border:0;font:inherit;font-size:12px;cursor:pointer;padding:4px 8px;border-radius:14px}"' _n
    file write `fh' `".chiputil:hover{background:#fff;box-shadow:inset 0 0 0 1px #dfe4e8}"' _n
    file write `fh' `".chiputil+.chiputil{margin-left:0}"' _n
    file write `fh' `".sblock{background:#fff;border:1px solid #e3e6ea;border-radius:8px;margin:10px 0;overflow:hidden}"' _n
    file write `fh' `".sblock.sv-b{border-left:3px solid #a33}.sblock.sv-w{border-left:3px solid #C9A227}.sblock.sv-g{border-left:3px solid #7fbf95}"' _n
    file write `fh' `".shead{display:flex;width:100%;align-items:baseline;gap:10px;padding:11px 16px;background:transparent;border:0;cursor:pointer;text-align:left;font-family:inherit}"' _n
    file write `fh' `".shead h2{margin:0;font-size:15.5px;color:#002244;font-weight:600}"' _n
    file write `fh' `".pillc{font-size:11px;font-weight:700;padding:1px 8px;border-radius:9px;position:relative;top:-1px;font-variant-numeric:tabular-nums}"' _n
    file write `fh' `".pillc.b{background:#fbeaea;color:#8a1f1f}.pillc.w{background:#fdf6e3;color:#7a5b00}.pillc.g{background:#eaf5ec;color:#1e6b34}"' _n
    file write `fh' `".shead .sfind{color:#556575;font-size:12.5px;margin-left:auto;text-align:right;max-width:52%}"' _n
    file write `fh' `".shead .chev{color:#8a97a4;font-size:11px;flex:0 0 auto;transition:transform .15s}"' _n
    file write `fh' `".sblock.open .chev{transform:rotate(90deg)}"' _n
    file write `fh' `".sbody{display:none;padding:2px 16px 14px;border-top:1px solid #eef0f2}"' _n
    file write `fh' `".sblock.open .sbody{display:block}"' _n
    file write `fh' `"@media (prefers-reduced-motion: reduce){.shead .chev{transition:none}}"' _n
    file write `fh' `"</style></head><body>"' _n
    file write `fh' `"<div class="logobar"><!-- wbLogo slot: replace content with the base64 banner img (class wbLogo) -->"' _n
    file write `fh' `"<span class="wbtxt">THE WORLD BANK <span>| Development Economics - Policy Indicators</span> &nbsp;-&nbsp; ENTERPRISE SURVEYS <span>- What Businesses Experience</span></span></div>"' _n
    file write `fh' `"<div class="mast"><h1>`htitle'</h1>"' _n
    local sub "Generated `now'"
    if "$SUSO_BASE"!="" {
        _suso_para_hesc `"$SUSO_BASE"'
        local sub "`sub' &nbsp;-&nbsp; `r(out)'"
    }
    if "$SUSO_GUID"!="" {
        _suso_para_hesc `"$SUSO_GUID"'
        local __gu `"`r(out)'"'
        _suso_para_hesc `"$SUSO_QVER"'
        local sub "`sub' &nbsp;-&nbsp; questionnaire `__gu' v`r(out)'"
    }
    local covline ""
    if "`cov0'"!="" local covline " &nbsp;-&nbsp; events `cov0' to `cov1'"
    file write `fh' `"<div class="sub">`sub' &nbsp;-&nbsp; `nevents' paradata events`covline'</div></div>"' _n
    file write `fh' `"<div class="wrap">"' _n
    file write `fh' `"<div class="cards">"' _n
    file write `fh' `"<div class="card"><div class="v" id="k_started">-</div><div class="k">interviews in view</div></div>"' _n
    file write `fh' `"<div class="card bad"><div class="v" id="k_inv">-</div><div class="k">investigate</div></div>"' _n
    file write `fh' `"<div class="card warn"><div class="v" id="k_ver">-</div><div class="k">verify</div></div>"' _n
    file write `fh' `"<div class="card"><div class="v" id="k_medact">-</div><div class="k">median active min</div></div>"' _n
    file write `fh' `"<div class="card"><div class="v" id="k_medans">-</div><div class="k">median sec / answer</div></div>"' _n
    file write `fh' `"</div>"' _n
    file write `fh' `"<div class="datasetline">Dataset: `nintsc' records in paradata &nbsp;-&nbsp; `nstartedc' started fieldwork &nbsp;-&nbsp; `ncompletedc' completed &nbsp;-&nbsp; `nuntouchedc' never started (preload only) &nbsp;-&nbsp; `tothrc' interviewer hours &nbsp;-&nbsp; `nhist' removal histories (`nfinalcheck' need review; `nexpectedblank' correctly blank; `nfinalanswered' answered; `nanswereddisabled' answered while disabled)</div>"' _n
    file write `fh' `"<div class="panel">"' _n
    file write `fh' `"<div class="prow">"' _n
    file write `fh' `"<div class="ctrl"><label>Actor / enumerator</label><select id="c_resp"></select></div>"' _n
    file write `fh' `"<div class="ctrl"><label>Interview status</label><select id="c_ws"></select></div>"' _n
    file write `fh' `"<div class="ctrl" id="ctl_fd"><label>Filter variable</label><select id="c_fd"></select></div>"' _n
    file write `fh' `"<div class="ctrl" id="ctl_fv"><label>= value</label><select id="c_fv"></select></div>"' _n
    file write `fh' `"<div class="ctrl"><label>Sensitivity</label><select id="c_preset"><option value="standard">Standard</option><option value="lenient">Lenient (fewer flags)</option><option value="strict">Strict (more flags)</option><option value="custom">Custom</option></select></div>"' _n
    file write `fh' `"<div class="ctrl"><label>Show top</label><input id="c_top" type="number" min="5" max="200" step="5" value="25"></div>"' _n
    file write `fh' `"<button id="c_adv" class="pbtn ghost">Advanced thresholds</button>"' _n
    file write `fh' `"<button id="c_reset" class="pbtn">Reset</button>"' _n
    file write `fh' `"<span id="lite_note"></span>"' _n
    file write `fh' `"</div>"' _n
    file write `fh' `"<div class="prow" id="advrow" style="display:none">"' _n
    file write `fh' `"<div class="ctrl"><label title="Live cutoff for the median-speed signal and fast-share display">Speed/share &lt; sec</label><input id="c_fs" type="number" min="0.5" max="10" step="0.5"></div>"' _n
    file write `fh' `"<div class="ctrl"><label title="Flag a streak of this many consecutive first-pass answers; the streak itself was built at the fixed package cutoff shown below">Burst run &ge;</label><input id="c_burst" type="number" min="3" max="40" step="1" value="8"></div>"' _n
    file write `fh' `"<div class="ctrl"><label title="A completed interview under this first-pass active time is too short">Min first-pass active min</label><input id="c_minact" type="number" min="1" max="240" step="1" value="5"></div>"' _n
    file write `fh' `"<div class="ctrl"><label>Night from</label><select id="c_n1"></select></div>"' _n
    file write `fh' `"<div class="ctrl"><label>Night to</label><select id="c_n2"></select></div>"' _n
    file write `fh' `"<div class="ctrl"><label title="Flag when this share of answers falls in the night window">Night share %</label><input id="c_nshare" type="number" min="1" max="100" step="1" value="25"></div>"' _n
    file write `fh' `"<div class="ctrl"><label title="Answers removed per 100 set">Churn %</label><input id="c_churn" type="number" min="1" max="100" step="1" value="20"></div>"' _n
    file write `fh' `"<div class="ctrl"><label title="Robust z-score on log active time">Outlier z</label><input id="c_z" type="number" min="2" max="6" step="0.5" value="3.5"></div>"' _n
    file write `fh' `"<div class="ctrl"><label title="Flag when the interview needed less than this share of the time colleagues typically take on the same questions">Peer speed &lt; %</label><input id="c_peer" type="number" min="5" max="90" step="5" value="35"></div>"' _n
    file write `fh' `"<div class="ctrl"><label title="UTC-minute buckets in which the same actor recorded answers in two interviews; a screening match, not proof">Shared-minute screen &ge;</label><input id="c_ov" type="number" min="1" max="60" step="1" value="3"></div>"' _n
    file write `fh' `"<div class="ctrl"><label title="Rate-based flags need at least this many timed answers">Min answers</label><input id="c_nmin" type="number" min="3" max="100" step="1" value="10"></div>"' _n
    file write `fh' `"<div class="note" style="flex-basis:100%;margin:3px 0 0">Speed/share cutoff is live. Burst streaks are session-safe and fixed at &lt; `fastsecs' sec, the build-time cutoff; changing the speed/share control does not rebuild streaks.</div>"' _n
    file write `fh' `"</div>"' _n
    file write `fh' `"</div>"' _n
    file write `fh' `"<nav class='chipnav' id='chipnav' aria-label='Report sections'>"' _n
    file write `fh' `"<a class='chipx' href='#s_att' data-sec='s_att'>Attention<span class='n' id='cb_att' style='display:none'></span></a>"' _n
    file write `fh' `"<a class='chipx' href='#s_flags' data-sec='s_flags'>Flags</a>"' _n
    file write `fh' `"<a class='chipx' href='#s_dur' data-sec='s_dur'>Durations<span class='n' id='cb_dur' style='display:none'></span></a>"' _n
    file write `fh' `"<a class='chipx' href='#s_speed' data-sec='s_speed'>Answer speed<span class='n' id='cb_speed' style='display:none'></span></a>"' _n
    file write `fh' `"<a class='chipx' href='#s_night' data-sec='s_night'>Night work<span class='n' id='cb_night' style='display:none'></span></a>"' _n
    file write `fh' `"<a class='chipx' href='#s_daily' data-sec='s_daily'>Daily pace</a>"' _n
    file write `fh' `"<a class='chipx' href='#s_enum' data-sec='s_enum'>Enumerators<span class='n' id='cb_enum' style='display:none'></span></a>"' _n
    file write `fh' `"<a class='chipx' href='#s_qt' data-sec='s_qt'>Question timing<span class='n' id='cb_qt' style='display:none'></span></a>"' _n
    if `nhist'>0 {
        file write `fh' `"<a class='chipx' href='#s_rem' data-sec='s_rem'>Removals<span class='n' id='cb_rem' style='display:none'></span></a>"' _n
    }
    file write `fh' `"<a class='chipx' href='#s_hist' data-sec='s_hist'>Event history</a>"' _n
    file write `fh' `"<button type='button' class='chiputil' id='e_expall'>Expand all</button>"' _n
    file write `fh' `"<button type='button' class='chiputil' id='e_collall'>Collapse all</button>"' _n
    file write `fh' `"</nav>"' _n
    file write `fh' `"<div id="verdict" class="verdict"></div>"' _n
    file write `fh' `"<div class='sblock' id='s_att'><button class='shead' type='button' aria-expanded='false'><h2>What needs attention</h2><span class='pillc' id='p_att' style='display:none'></span><span class='sfind' id='f_att'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `fh' `"<div class="note">Every interview here comes with the evidence in plain words. <b>Investigate</b> = an unchanged rejection cycle or signals from at least three independent risk domains. <b>Verify</b> = two risk domains, a concentrated pace/duration pattern, a quick correction cycle, an overlap screen, or an unresolved removal history. <b>Watch</b> = one isolated domain or a long/multi-day continuation. Speed and fast streak belong to one pace domain; short and duration-outlier belong to one duration domain, so correlated measures are not double-counted as independent evidence. Click a row for its detail; the key is what you paste into Headquarters. All signals are screening evidence for review, never proof of fabrication. <span id="w_none"></span></div>"' _n
    file write `fh' `"<section><div style="margin:6px 0"><button id="c_csv" class="pbtn ghost">Download this list (CSV)</button></div><table id="t_worst"></table></section>"' _n
    file write `fh' `"</div></div>"' _n
    file write `fh' `"<div class='sblock' id='s_flags'><button class='shead' type='button' aria-expanded='false'><h2>Behaviour flags</h2><span class='sfind' id='f_flags'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `fh' `"<div class="note">How often each signal fires at the current thresholds. Adjust sensitivity in the panel; everything recomputes instantly. Only interviews with actual fieldwork are analysed; API-preloaded records are set aside.</div>"' _n
    file write `fh' `"<section id="ch_flags"><div class="legend" id="flag_leg"></div></section>"' _n
    file write `fh' `"</div></div>"' _n
    file write `fh' `"<div class='sblock' id='s_dur'><button class='shead' type='button' aria-expanded='false'><h2>How long do interviews take?</h2><span class='pillc' id='p_dur' style='display:none'></span><span class='sfind' id='f_dur'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `fh' `"<div class="note">Active first-pass interviewer time per interview: pauses and session-boundary gaps are excluded; ordinary within-session gaps are capped at `gapmins' min. Rework after an earlier completion is displayed separately in interview detail. <span id="n_act"></span></div>"' _n
    file write `fh' `"<section id="ch_act"></section>"' _n
    file write `fh' `"</div></div>"' _n
    file write `fh' `"<div class='sblock' id='s_speed'><button class='shead' type='button' aria-expanded='false'><h2>How fast are answers?</h2><span class='pillc' id='p_speed' style='display:none'></span><span class='sfind' id='f_speed'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `fh' `"<div class="note">Each interview gets one number: the typical (median) time to answer a newly reached question. Repeat taps on the same question (multi-select choices, list items, immediate corrections) are kept out of this clock, so tapping through a checklist cannot look like speeding. A real interview needs time to ask, listen and type - a sustained 1-2 seconds per question was probably filled in without talking to anyone. <span id="n_med"></span></div>"' _n
    file write `fh' `"<section id="ch_med"></section>"' _n
    file write `fh' `"</div></div>"' _n
    file write `fh' `"<div class='sblock' id='s_night'><button class='shead' type='button' aria-expanded='false'><h2>When is the work happening?</h2><span class='pillc' id='p_night' style='display:none'></span><span class='sfind' id='f_night'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `fh' `"<div class="note">Interviewer answers by hour of day (device-local time). Gold bars mark the night window - night answering on establishment surveys usually means desk work, not fieldwork. Interviews whose tablet clock disagrees with the team are marked in their detail row, because their hours cannot be trusted.</div>"' _n
    file write `fh' `"<section id="ch_hour"></section>"' _n
    file write `fh' `"</div></div>"' _n
    file write `fh' `"<div class='sblock' id='s_daily'><button class='shead' type='button' aria-expanded='false'><h2>Fieldwork over time</h2><span class='sfind' id='f_daily'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `fh' `"<div class="note">Interviewer answers recorded per day (`dnote'). This chart responds to the actor filter only; status and final-data filter controls do not change the event-volume series.</div>"' _n
    file write `fh' `"<section id="ch_daily"></section>"' _n
    file write `fh' `"</div></div>"' _n
    file write `fh' `"<div class='sblock' id='s_enum'><button class='shead' type='button' aria-expanded='false'><h2>Enumerators</h2><span class='pillc' id='p_enum' style='display:none'></span><span class='sfind' id='f_enum'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `fh' `"<div class="note">Actor-level comparison: every contributor is measured from their own events, including correction-only actors; nobody inherits the primary actor's pace or the last editor's identity. <b>vs team</b> is the actor's typical answer speed relative to the team (0.5 = twice as fast). Shared-minute counts are actor-specific screening buckets. Gold rows have at least one flagged contribution; judge shares only where the interview count is reasonable. <span id="l_more"></span></div>"' _n
    file write `fh' `"<section><table id="t_league"></table></section>"' _n
    file write `fh' `"</div></div>"' _n
    file write `fh' `"<div class='sblock' id='s_qt'><button class='shead' type='button' aria-expanded='false'><h2>Question timing</h2><span class='pillc' id='p_qt' style='display:none'></span><span class='sfind' id='f_qt'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `fh' `"<div class="note"><b>Actor / enumerator</b> and <b>Interview status</b> both filter this table. Status is the record's current/final status when this report was built (data() status takes precedence over paradata). <b>Answer events</b> are first-pass AnswerSet saves, so one interview can contribute several events through a revision, repeated save, or roster instance; for example, 405 events across 381 distinct interviews means 24 additional saves/instances. <b>Distinct interviews</b> counts unique interview IDs. <b>Timed reaches</b> is the subset with a valid within-session gap and is the denominator used by median, p90, and the &lt; `fastsecs' s share; repeated taps remain in Answer events but are not timed reaches. `qordernote' vars() limits the questions; the Filter variable/value controls do not currently change Question timing. Every observed matching variable is shown (questionnaire items with zero first-pass events are not); type to search and click a column header to sort. Reset restores the default order. <span id="q_more"></span></div>"' _n
    file write `fh' `"<section><div style="display:flex;flex-wrap:wrap;gap:10px;align-items:flex-end;margin-bottom:8px"><div class="ctrl" style="max-width:280px"><label>Filter questions</label><input id="c_q" type="text" placeholder="variable name contains..."></div><button id="c_qorder" class="pbtn ghost" type="button">`qorderbutton'</button></div><table id="t_q"></table></section>"' _n
    file write `fh' `"</div></div>"' _n
    if `nhist'>0 {
        file write `fh' `"<div class='sblock' id='s_rem'><button class='shead' type='button' aria-expanded='false'><h2>Removal histories</h2><span class='pillc `remsev'' id='p_rem'>`nfinalcheck'</span><span class='sfind' id='f_rem'>`nhist' histor`histplural' in scope - `nfinalcheck' need a final-data check</span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    }
    * Removal summaries are rendered from one compact row per already-detected
    * full-stream run.  This lets the actor control recompute and re-rank the
    * table without ever changing cascade adjacency or attribution.
    if `nhist'>0 {
        file write `fh' `"<details id="rtech" style="margin-top:22px"><summary style="cursor:pointer;color:#556575;font-size:13px;font-weight:600">Technical removal-pattern summary</summary>"' _n
        file write `fh' `"<div class="note">Every consecutive same-actor AnswerRemoved history is included. Actor and current/final interview status filter this table together. Compact histories meet cascade()/window()/near-answer criteria; outside histories are retained. <span id="r_more"></span></div>"' _n
        file write `fh' `"<section><table><thead><tr><th>nearby / linked variable</th><th class="r">all histories</th><th class="r">compact</th><th class="r">interviews</th><th class="r">raw events</th><th class="r">compact events</th><th class="r">outside events</th></tr></thead><tbody id="t_rsum"></tbody></table></section></details>"' _n
    }

    capture confirm file `"`rsdpath'"'
    if !_rc & `nhist'>0 {
        preserve
        quietly use `"`rsdpath'"', clear
        if `hasassignment' quietly merge m:1 interview__id using `"`HQF'"', keep(master match) nogenerate
        capture confirm variable hq_assignment, exact
        if _rc quietly gen str40 hq_assignment = ""
        quietly replace hq_assignment = "" if missing(hq_assignment)
        capture confirm variable tier
        if _rc {
            quietly gen str1 tier = "V"
            quietly gen strL why = "Check final data"
        }
        quietly gen byte __sev = cond(tier=="A",2,cond(tier=="V",1,0))
        gsort -__sev -nopen -nunknown -nqrem interview__id sk_run
        local hasqxt 0
        capture confirm variable qx_text
        if !_rc local hasqxt 1

        quietly gen str120 e_ac = substr(cond(actor!="", actor,              ///
            "Unknown removal actor"),1,120)
        capture confirm variable actor_key, exact
        if _rc quietly gen str244 e_ak = ustrlower(strtrim(actor))
        else {
            quietly gen str244 e_ak = actor_key
            quietly replace e_ak = ustrlower(strtrim(actor)) if e_ak==""
        }
        quietly replace e_ak = "__unknown_removal_actor__" if e_ak==""
        quietly gen strL e_ws = ws
        quietly gen strL e_wc = ws_class
        quietly gen strL e_iid = interview__id
        quietly gen strL e_tg = trigger
        quietly gen strL e_qt = ""
        if `hasqxt' quietly replace e_qt = substr(qx_text,1,160)
        quietly gen strL e_wl = substr(wlc,1,300)
        quietly gen strL e_event = transition_text
        quietly gen strL e_final = trigger_final_text
        quietly gen strL e_check = wl_final_check
        quietly gen strL e_rel = cond(reltype==1, ///
            cond(linkmode==2,"Indirect questionnaire relationship: ", ///
            cond(linkmode==3,"Direct and indirect questionnaire relationship: ", ///
            "Direct questionnaire relationship: ")) + ///
            cond(trigger!="",trigger,"(unknown)"), ///
            cond(reltype==3, "Questionnaire questions with no item-level condition shown", ///
            cond(reltype==4, "Fields outside questionnaire metadata", ///
            cond(reltype==5, "Mixed questionnaire/external fields", ///
            cond(reltype==6, "Questionnaire metadata not supplied", ///
            "Nearest AnswerSet only (not linked by questionnaire): " + cond(trigger!="",trigger,"(unknown)"))))))
        quietly gen strL e_iid_url = ""
        quietly gen strL e_assignment_url = ""
        mata: suso_urlencode_var("e_iid", "e_iid_url")
        mata: suso_urlencode_var("hq_assignment", "e_assignment_url")
        foreach v in e_ac e_ak e_ws e_wc e_iid e_tg e_qt e_wl e_event e_final e_check e_rel hq_assignment {
            quietly replace `v' = subinstr(subinstr(subinstr(`v',"&","&amp;",.),"<","&lt;",.),">","&gt;",.)
            quietly replace `v' = subinstr(subinstr(`v',char(34),"&#34;",.),char(39),"&#39;",.)
        }
        quietly gen strL e_attrs = " data-actor=" + char(34) + e_ak + char(34) + ///
            " data-status=" + char(34) + e_ws + char(34) +                    ///
            " data-statusclass=" + char(34) + e_wc + char(34)
        * Generated cards retain class="bremcase" data-actor="..." and add
        * canonical current/final status attributes for intersection filtering.
        quietly gen strL e_hqlinks = ""
        if `"`hqbase'"'!="" {
            tempvar hqb
            quietly gen strL `hqb' = `"`hqbaseh'"'
            quietly replace e_hqlinks = "<span class=" + char(34) + "hqlinks" + char(34) + ">" + ///
                "<a class=" + char(34) + "hqlink" + char(34) + " target=" + char(34) + "_blank" + char(34) + ///
                " rel=" + char(34) + "noopener noreferrer" + char(34) + " href=" + char(34) + ///
                `hqb' + "/Interview/Review/" + e_iid_url + char(34) + ">Open interview</a>" + ///
                cond(hq_assignment!="", "<a class=" + char(34) + "hqlink secondary" + char(34) + ///
                " target=" + char(34) + "_blank" + char(34) + " rel=" + char(34) + "noopener noreferrer" + char(34) + ///
                " href=" + char(34) + `hqb' + "/Assignments/" + e_assignment_url + char(34) + ">Open assignment</a>", "") + ///
                "</span>"
        }

        quietly gen strL e_eventline = "<b>Historical answer event:</b> " + e_event
        quietly gen strL e_finalline = ""
        quietly replace e_finalline = "<b>Current final export:</b> " + e_final if e_final!=""
        quietly gen strL e_hist = "<b>Removal history:</b> " + strofreal(nrem) + ///
            " AnswerRemoved event(s) affected " + strofreal(nqrem) + ///
            " distinct question/roster unit(s). Pattern: " + cond(compact,    ///
            "compact priority",cond(timing_unknown,"timing unknown",         ///
            "outside compact rule")) + "."
        quietly gen strL e_state = "<b>Current paradata state:</b> " + ///
            strofreal(nreanswered) + " answered again; " + strofreal(nopen) + ///
            " still appear removed; " + strofreal(nunknown) + " unknown."
        quietly gen strL e_action = "<b>Check in final .dta:</b> <span class=" + char(34) + "mono" + char(34) + ">" + e_check + "</span>. Reject only if a listed value is actually blank and should have been asked."
        quietly replace e_action = "<b>Priority check:</b> review the final .dta and interview history because multiple unresolved sequences or sections are involved." if tier=="A"
        quietly gen str24 e_dt = cond(missing(ts0),"time unavailable",       ///
            string(ts0/86400000, "%tdDD_Mon_CCYY"))

        file write `fh' `"<div class="note">Only unresolved histories matching the selected removal actor and current/final interview status are shown here. Fully resolved cases remain available in the Skip/removal tab.</div>"' _n
        file write `fh' `"<section id="r_actions">"' _n
        quietly count if tier!="C"
        local nshow = r(N)
        file write `fh' `"<div id="r_action_note" class="note"><b>"' (strofreal(`nshow')) `"</b> case(s) require a final-data check.</div>"' _n
        if `nshow'>0 {
            quietly keep if tier!="C"
            local kk = _N
            forvalues i = 1/`kk' {
                file write `fh' `"<div class="bremcase""' (e_attrs[`i']) `" style="border-bottom:1px solid #eef0f2;padding:10px 0">"' _n
                file write `fh' `"<div style="font-size:13px"><span class="mono"><b>"' (e_iid[`i']) `"</b></span> &nbsp; enumerator <b>"' (e_ac[`i']) `"</b> &nbsp; "' (e_dt[`i']) `" &nbsp; "' (e_ws[`i']) (e_hqlinks[`i']) `"</div>"' _n
                file write `fh' `"<div style="font-size:12.5px;font-weight:700;color:"' (cond(tier[`i']=="A","#8a1f1f","#7a5b00")) `"">"' (why[`i']) `"</div>"' _n
                file write `fh' `"<div style="font-size:12.5px;margin-top:4px">"' (e_eventline[`i']) `"</div>"' _n
                if e_finalline[`i']!="" file write `fh' `"<div style="font-size:12.5px;margin-top:4px;color:#173b5e;background:#edf5fb;padding:5px 7px;border-radius:5px">"' (e_finalline[`i']) `"</div>"' _n
                file write `fh' `"<div style="font-size:12.5px;margin-top:4px">"' (e_hist[`i']) `"</div>"' _n
                file write `fh' `"<div class="note" style="margin:4px 0 0">"' (e_state[`i']) `"</div>"' _n
                file write `fh' `"<div class="note" style="margin:4px 0 0;color:#333">"' (e_action[`i']) `"</div>"' _n
                file write `fh' `"<details style="margin-top:5px"><summary style="cursor:pointer;color:#556575;font-size:11.5px">Technical details</summary>"' _n
                file write `fh' `"<div class="note">"' (e_rel[`i']) `" &nbsp; Removal events: "' (strofreal(nrem[`i'])) `"</div>"' _n
                if e_qt[`i']!="" file write `fh' `"<div class="note"><span class="mono">"' (e_tg[`i']) `"</span>: &quot;"' (e_qt[`i']) `"&quot;</div>"' _n
                if e_wl[`i']!="" file write `fh' `"<div class="note">Affected questions: <span class="mono">"' (e_wl[`i']) (cond(length(wlc[`i'])>300," ...","")) `"</span></div>"' _n
                file write `fh' `"</details></div>"' _n
            }
        }
        file write `fh' `"<div id="r_action_none" class="note" style="display:none;color:#1e6b34"><b>No final-data checks are indicated for this actor.</b></div>"' _n
        file write `fh' `"</section>"' _n
        restore
    }
    if `nhist'>0 {
        file write `fh' `"</div></div>"' _n
    }
    file write `fh' `"<div class='sblock' id='s_hist'><button class='shead' type='button' aria-expanded='false'><h2>Interview event history</h2><span class='sfind'>Loads your local paradata.tab in this browser tab only - nothing leaves this machine</span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `fh' `"<div class='note'>Select the original <span class='mono'>paradata.tab</span> once per browser tab, then search for any interview ID—or use a queue card's <b>View event history</b> button—to inspect its complete ordered audit trail. The compact timeline lists one event per line, grouped under sticky device-local day rails, marks pauses at or beyond the behaviour gap cap as visible session breaks, and expands any line on click for the full record with copyable parameters. Initial indexing can take some time for a multi-million-row file; later lookups stay local. The source file is streamed in the background and is not embedded in this report.</div>"' _n
    file write `fh' `"<section id='history_explorer'>"' _n
    file write `fh' `"<div class='hv-privacy'><b>Private and local:</b> the selected file is read only inside this browser tab. It is never uploaded, sent over the network, or stored by this report. Raw parameters can contain answers, GPS coordinates, and other sensitive data.</div>"' _n
    file write `fh' `"<div class='hv-setup'><div class='ctrl'><label>1. Choose local paradata file</label><input id='hv_file' type='file' accept='.tab,.tsv,.txt,text/tab-separated-values,text/plain'></div><div class='ctrl'><label>File format</label><select id='hv_dialect'><option value='suso'>Survey Solutions TSV (recommended)</option><option value='quoted'>Quoted TSV (tabs/newlines inside quotes)</option></select></div><div class='ctrl hv-idbox'><label>2. Interview ID</label><input id='hv_id' class='mono' type='text' autocomplete='off' spellcheck='false' placeholder='type or paste interview__id' disabled><div id='hv_suggest' class='hv-suggestions'></div></div><button id='hv_load' class='pbtn' type='button' disabled>Open full history</button></div>"' _n
    file write `fh' `"<progress id='hv_progress' max='100' value='0' style='display:none'></progress><div id='hv_status' class='hv-status'>Choose the matching paradata.tab export to begin.</div>"' _n
    file write `fh' `"<div id='hv_results' style='display:none'><div id='hv_summary' class='hv-summary'></div><div class='hv-filters'><div class='ctrl'><label>Event type</label><select id='hv_event'></select></div><div class='ctrl'><label>Responsible actor</label><select id='hv_actor'></select></div><div class='ctrl'><label>Search this history</label><input id='hv_search' type='search' placeholder='event, role, variable, value, time ...'></div></div><div class='hv-viewbar'><span id='hv_bulk' class='hv-bulk'><button id='hv_expand' class='pbtn ghost' type='button'>Expand all</button><button id='hv_collapse' class='pbtn ghost' type='button'>Collapse all</button></span><button id='hv_view_compact' class='pbtn' type='button'>Compact timeline</button><button id='hv_view_timeline' class='pbtn ghost' type='button'>Detailed cards</button><button id='hv_view_raw' class='pbtn ghost' type='button'>Raw event table</button></div><div id='hv_compact' class='hvc-wrap'></div><div id='hv_timeline' class='hv-timeline' style='display:none'></div><div id='hv_raw' class='hv-tablewrap' style='display:none'><table><thead><tr><th class='r'>source row</th><th class='r'>order</th><th>event</th><th>responsible</th><th>role</th><th>source timestamp</th><th>UTC</th><th>tz offset</th><th>device local (UTC + offset)</th><th>parameters</th></tr></thead><tbody id='hv_raw_body'></tbody></table></div></div>"' _n
    file write `fh' `"</section>"' _n
    file write `fh' `"</div></div>"' _n
    _suso_para_hesc `"`rolenote'"'
    local rnesc `"`r(out)'"'
    local veline ""
    if `hasve' local veline " Open validation errors count the questions whose last validity event is a failure."
    file write `fh' `"<div class="foot"><b>Method.</b> Timing uses `rnesc'. Full-stream lifecycle, session, actor, resubmission, overlap and post-completion metrics are derived before any vars() question scope is applied. Initial CAPI preload AnswerSet events and non-interviewer roles are excluded from field behaviour. First-pass timing stops at the first interviewer completion; later correction work is retained separately. Active time sums ordinary within-session inter-event gaps, caps each at `gapmins' minutes, and contributes zero across pauses, workflow boundaries, actor handoffs and inferred long-gap session boundaries. Answer speed preserves milliseconds and is the gap preceding each newly reached question instance within the same actor and session; repeat taps are excluded. Peer speed compares the primary actor's timed questions with survey medians for those same question instances. Shared-minute overlap is based on the same actor recording answer events in two interviews in a UTC-minute bucket; it retains actor, minute and counterpart as a screening trace and is not proof of simultaneity. Night and field dates use device-local time; missing, changing or atypical offsets are disclosed and unreliable timing flags are suppressed. Pure CAWI and mixed-mode histories suppress interviewer timing signals. Duration outliers use robust median/MAD z-scores on first-pass active time.`veline' Records with no interviewer activity (`nuntouchedc' of `nintsc' here, typically API-preloaded grid points) are excluded from behaviour figures. Flags are screening signals for review, never evidence of fabrication by themselves.<br><b>Produced by</b> suso paradata report (suso v1.7.26) on `now'. Thresholds shown in the control panel are live and local to this page.</div>"' _n
    file write `fh' `"</div>"' _n

    _suso_para_history_js `fh'
    * ---- embedded data ------------------------------------------------------------
    file write `fh' `"<script>"' _n
    file write `fh' `"var D={"meta":{"fastsecs":`fastsecs',"gapmins":`gapmins',"tzmode":`tzmodej',"lite":`lite',"hasve":`hasve',"hascawi":`hascawi',"haskey":`haskey',"hq":"`hqbasej'","hasassignment":`hasassignment',"fdims":[`jfdims']},"' _n
    file write `fh' `""rows":["' _n
    quietly use `"`MERGED'"', clear
    quietly keep if started
    forvalues i = 1/`=_N' {
        _suso_jsonesc `"`=interview__id[`i']'"'
        local ij `"`r(js)'"'
        _suso_jsonesc `"`=responsible[`i']'"'
        local rj `"`r(js)'"'
        _suso_jsonesc `"`=last_editor[`i']'"'
        local lej `"`r(js)'"'
        _suso_jsonesc `"`=first_interviewer[`i']'"'
        local fij `"`r(js)'"'
        _suso_jsonesc `"`=ws[`i']'"'
        local wsj `"`r(js)'"'
        _suso_jsonesc `"`=ws_paradata[`i']'"'
        local wspj `"`r(js)'"'
        _suso_jsonesc `"`=ws_data[`i']'"'
        local wsdj `"`r(js)'"'
        _suso_jsonesc `"`=ws_source[`i']'"'
        local wssj `"`r(js)'"'
        _suso_jsonesc `"`=ws_class[`i']'"'
        local wscj `"`r(js)'"'
        _suso_jsonesc `"`=ikey[`i']'"'
        local kj `"`r(js)'"'
        _suso_jsonesc `"`=hq_assignment[`i']'"'
        local aj `"`r(js)'"'
        _suso_jsonesc `"`=ov_actor[`i']'"'
        local ovaj `"`r(js)'"'
        _suso_jsonesc `"`=ov_detail[`i']'"'
        local ovdj `"`r(js)'"'
        _suso_jsonesc `"`=rb_last_editor[`i']'"'
        local rbaj `"`r(js)'"'
        _suso_jsonesc `"`=rb_questions[`i']'"'
        local rbvj `"`r(js)'"'
        _suso_jsonesc `"`=pce_detail[`i']'"'
        local pcdj `"`r(js)'"'
        local med = cond(missing(ans_med_s[`i']), "null", string(ans_med_s[`i'],"%12.2f"))
        local fsh = cond(missing(fast_share[`i']), "null", string(fast_share[`i'],"%12.3f"))
        local nsh = cond(missing(night_share[`i']), "null", string(night_share[`i'],"%12.3f"))
        local rtj = cond(missing(rt[`i']), "null", string(rt[`i'],"%12.2f"))
        local rbj = cond(missing(rbm[`i']), "null", string(rbm[`i'],"%12.1f"))
        local rej = cond(missing(rbe[`i']), "null", string(rbe[`i'],"%12.0f"))
        local refj = cond(missing(rbe_field[`i']), "null", string(rbe_field[`i'],"%12.0f"))
        local rqj = cond(missing(rbq[`i']), "null", string(rbq[`i'],"%12.0f"))
        local vej = cond(missing(verr[`i']), "null", string(verr[`i'],"%12.0f"))
        local nqj = cond(missing(nq[`i']), "null", string(nq[`i'],"%12.0f"))
        local pqj = cond(missing(pa_questions[`i']), "null", string(pa_questions[`i'],"%12.0f"))
        local pansj = cond(missing(pa_answers[`i']), "null", string(pa_answers[`i'],"%12.0f"))
        local pansfj = cond(missing(pa_answers_first[`i']), "null", string(pa_answers_first[`i'],"%12.0f"))
        local pactj = cond(missing(pa_active_min[`i']), "null", string(pa_active_min[`i'],"%12.3f"))
        local pssj = cond(missing(pa_sessions[`i']), "null", string(pa_sessions[`i'],"%12.0f"))
        local pasj = cond(missing(pa_answer_share[`i']), "null", string(pa_answer_share[`i'],"%12.4f"))
        local pafj = cond(missing(pa_active_first_min[`i']), "null", string(pa_active_first_min[`i'],"%12.3f"))
        local afj = cond(missing(active_first_min[`i']), "null", string(active_first_min[`i'],"%12.3f"))
        local spj = cond(missing(span_min[`i']), "null", string(span_min[`i'],"%12.2f"))
        local spfj = cond(missing(span_first_min[`i']), "null", string(span_first_min[`i'],"%12.2f"))
        local lpj = cond(missing(longest_pause_min[`i']), "null", string(longest_pause_min[`i'],"%12.2f"))
        local lppj = cond(missing(longest_precompletion_pause_min[`i']), "null", string(longest_precompletion_pause_min[`i'],"%12.2f"))
        local onj = cond(missing(overnight_precompletion[`i']), "null", string(overnight_precompletion[`i'],"%12.0f"))
        local vecs ""
        if !`lite' {
            local hv "`=h0[`i']'"
            forvalues h = 1/23 {
                local hv "`hv',`=h`h'[`i']'"
            }
            local gv "`=g0[`i']'"
            forvalues g = 1/40 {
                local gv "`gv',`=g`g'[`i']'"
            }
            local vecs `","h":[`hv'],"g":[`gv']"'
        }
        local fjm ""
        if `nfdim'>0 {
            forvalues fi = 1/`nfdim' {
                local __fa "`fdimalias_`fi''"
                local fval = cond(missing(`__fa'[`i']), "", strofreal(`__fa'[`i']))
                local fjm `"`fjm'`=cond(`"`fjm'"'=="","",",")'"`fdimjson_`fi''":"`fval'""'
            }
        }
        if `"`fjm'"'!="" local fjm `","f":{`fjm'}"'
        local sep = cond(`i'==1, "", ",")
        file write `fh' `"`sep'{"id":"`ij'","k":"`kj'","a":"`aj'","r":"`rj'","le":"`lej'","fi":"`fij'","na":`=n_field_actors[`i']',"ho":`=handoff[`i']',"pas":`pasj',"ws":"`wsj'","wsp":"`wspj'","wsd":"`wsdj'","wss":"`wssj'","wsc":"`wscj'","wsm":`=ws_mismatch[`i']'`fjm',"d0":"`=__d0[`i']'","d1":"`=__d1[`i']'","m":`=iscawi[`i']',"mm":`=mixedmode[`i']',"mu":`=mode_unknown[`i']',"tq":`=timing_ok[`i']',"lq":`=local_time_ok[`i']',"itq":`=interview_timing_ok[`i']',"ilq":`=interview_local_time_ok[`i']',"im":`=interview_iscawi[`i']',"imm":`=interview_mixedmode[`i']',"imu":`=interview_mode_unknown[`i']',"itz":`=cond(missing(interview_tzh[`i']),"null",string(interview_tzh[`i'],"%12.1f"))',"ito":`=interview_tzodd[`i']',"cb":`=n_clockback[`i']',"nt":`=n_timed[`i']',"ntt":`=n_timed_total[`i']',"nc":`=n_completed[`i']',"act":`=string(active_min[`i'],"%12.3f")',"af":`afj',"paf":`pafj',"pact":`pactj',"pans":`pansj',"pansf":`pansfj',"pss":`pssj',"sp":`spj',"spf":`spfj',"lp":`lpj',"lpp":`lppj',"wd":`=work_days_first[`i']',"wdt":`=work_days[`i']',"on":`onj',"pr":`=postcompletion_return[`i']',"med":`med',"fsh":`fsh',"nsh":`nsh',"ch":`=string(churn[`i'],"%12.3f")',"cas":`=n_cascades[`i']',"rem":`=casc_removed[`i']',"wip":`=casc_questions[`i']',"cop":`=casc_open[`i']',"cr":`=casc_reanswered[`i']',"cu":`=casc_unknown[`i']',"fda":`=casc_finalanswered[`i']',"fad":`=casc_answered_disabled[`i']',"feb":`=casc_expectedblank[`i']',"fbe":`=casc_blank_enabled[`i']',"flu":`=casc_logicunknown[`i']',"fnd":`=casc_notindata[`i']',"fck":`=casc_finalcheck[`i']',"fdc":`=casc_datachecked[`i']',"fr":`=fr[`i']'"'
        file write `fh' `","rt":`rtj',"ov":`=ovm[`i']',"ovt":`=ovm_total[`i']',"ova":"`ovaj'","ovd":"`ovdj'","rj":`=n_rejected[`i']',"rb":`rbj',"rq":`rqj',"re":`rej',"ref":`refj',"rba":"`rbaj'","rbv":"`rbvj'","rbc":`=rb_complete[`i']',"rbb":`=rb_clockbad[`i']',"pc":`=pce[`i']',"pca":`=pce_all[`i']',"pcn":`=pce_nonfield[`i']',"pco":`=pce_outside[`i']',"pcf":`=pce_field_outside[`i']',"pcno":`=pce_nonfield_outside[`i']',"pcd":"`pcdj'","ve":`vej',"nq":`nqj',"pq":`pqj',"ss":`=sessions[`i']',"sf":`=sessions_first[`i']',"sr":`=sessions_rework[`i']',"rs":`=n_restarted[`i']',"tz":`=cond(missing(tzh[`i']),"null",string(tzh[`i'],"%12.1f"))',"to":`=tzodd[`i']'`vecs'}"' _n
    }
    file write `fh' `"],"' _n
    file write `fh' `""actors":["' _n
    quietly use `"`ACTF'"', clear
    if _N>0 {
        forvalues i = 1/`=_N' {
            _suso_jsonesc `"`=interview__id[`i']'"'
            local ai `"`r(js)'"'
            _suso_jsonesc `"`=actor[`i']'"'
            local ar `"`r(js)'"'
            _suso_jsonesc `"`=ov_detail_actor[`i']'"'
            local aovd `"`r(js)'"'
            local amed = cond(missing(a_med[`i']), "null", string(a_med[`i'],"%12.2f"))
            local afsh = cond(missing(a_fast_share[`i']), "null", string(a_fast_share[`i'],"%12.4f"))
            local ansh = cond(missing(a_night_share[`i']), "null", string(a_night_share[`i'],"%12.4f"))
            local apr = cond(missing(a_peer[`i']), "null", string(a_peer[`i'],"%12.4f"))
            local aash = cond(missing(a_answer_share[`i']), "null", string(a_answer_share[`i'],"%12.4f"))
            local aact = cond(missing(a_active_min[`i']), "null", string(a_active_min[`i'],"%12.3f"))
            local aaft = cond(missing(a_active_first_min[`i']), "null", string(a_active_first_min[`i'],"%12.3f"))
            local ach = cond(missing(a_churn[`i']), "null", string(a_churn[`i'],"%12.4f"))
            local afr = cond(missing(a_fast_run[`i']), "0", string(a_fast_run[`i'],"%12.0f"))
            local aov = cond(missing(ovm_actor[`i']), "0", string(ovm_actor[`i'],"%12.0f"))
            local atz = cond(missing(a_tzh[`i']), "null", string(a_tzh[`i'],"%12.1f"))
            local avecs ""
            if !`lite' {
                local ahv "`=ah0[`i']'"
                forvalues h = 1/23 {
                    local ahv "`ahv',`=ah`h'[`i']'"
                }
                local agv "`=ag0[`i']'"
                forvalues g = 1/40 {
                    local agv "`agv',`=ag`g'[`i']'"
                }
                local avecs `","h":[`ahv'],"g":[`agv']"'
            }
            local sep = cond(`i'==1, "", ",")
            file write `fh' `"`sep'{"id":"`ai'","r":"`ar'","p":`=a_primary[`i']',"f":`=a_first[`i']',"l":`=a_last[`i']',"ans":`=a_answers[`i']',"ansf":`=a_answers_first[`i']',"q":`=a_questions[`i']',"ss":`=a_sessions[`i']',"share":`aash',"act":`aact',"af":`aaft',"nt":`=a_timed[`i']',"med":`amed',"fsh":`afsh',"nsh":`ansh',"ch":`ach',"rt":`apr',"fr":`afr',"ov":`aov',"ovd":"`aovd'","tq":`=a_timing_ok[`i']',"lq":`=a_local_ok[`i']',"m":`=a_iscawi[`i']',"mm":`=a_mixedmode[`i']',"mu":`=a_mode_unknown[`i']',"tz":`atz',"to":`=a_tzodd[`i']'`avecs'}"' _n
        }
    }
    file write `fh' `"],"' _n
    file write `fh' `""q":["' _n
    if `hasq' {
        quietly use `"`QT'"', clear
        forvalues i = 1/`=_N' {
            _suso_jsonesc `"`=qscope[`i']'"'
            local sj `"`r(js)'"'
            _suso_jsonesc `"`=para_var[`i']'"'
            local vj `"`r(js)'"'
            local med = cond(missing(qmed[`i']), "null", string(qmed[`i'],"%12.1f"))
            local p90 = cond(missing(qp90[`i']), "null", string(qp90[`i'],"%12.1f"))
            local fsh = cond(missing(qfsh[`i']), "null", string(qfsh[`i'],"%12.3f"))
            local qo  = cond(missing(qorder[`i']), "null", string(qorder[`i'],"%12.0f"))
            local sep = cond(`i'==1, "", ",")
            file write `fh' `"`sep'{"s":"`sj'","v":"`vj'","o":`qo',"n":`=qn[`i']',"ni":`=qni[`i']',"nt":`=qnt[`i']',"med":`med',"p90":`p90',"fsh":`fsh'}"' _n
        }
    }
    file write `fh' `"],"' _n
    file write `fh' `""aq":["' _n
    if `hasaq' {
        quietly use `"`AQT'"', clear
        forvalues i = 1/`=_N' {
            _suso_jsonesc `"`=aq_actor[`i']'"'
            local arj `"`r(js)'"'
            _suso_jsonesc `"`=para_actor_key[`i']'"'
            local akj `"`r(js)'"'
            _suso_jsonesc `"`=para_var[`i']'"'
            local vj `"`r(js)'"'
            _suso_jsonesc `"`=qscope[`i']'"'
            local sj `"`r(js)'"'
            local med = cond(missing(aqmed[`i']), "null", string(aqmed[`i'],"%12.1f"))
            local p90 = cond(missing(aqp90[`i']), "null", string(aqp90[`i'],"%12.1f"))
            local fsh = cond(missing(aqfsh[`i']), "null", string(aqfsh[`i'],"%12.3f"))
            local qo  = cond(missing(qorder[`i']), "null", string(qorder[`i'],"%12.0f"))
            local sep = cond(`i'==1, "", ",")
            file write `fh' `"`sep'{"r":"`arj'","k":"`akj'","s":"`sj'","v":"`vj'","o":`qo',"n":`=aqn[`i']',"ni":`=aqni[`i']',"nt":`=aqnt[`i']',"med":`med',"p90":`p90',"fsh":`fsh'}"' _n
        }
    }
    file write `fh' `"],"' _n
    file write `fh' `""rem":["' _n
    capture confirm file `"`rsdpath'"'
    if !_rc & `nhist'>0 {
        preserve
        quietly use `"`rsdpath'"', clear
        capture confirm variable actor_key, exact
        if _rc quietly gen str244 actor_key = ustrlower(strtrim(actor))
        else quietly replace actor_key = ustrlower(strtrim(actor)) if actor_key==""
        quietly replace actor_key = "__unknown_removal_actor__" if actor_key==""
        capture confirm variable tier, exact
        if _rc quietly gen str1 tier = "V"
        capture confirm variable final_data_checked, exact
        if _rc quietly gen byte final_data_checked = 0
        capture confirm variable n_final_check, exact
        if _rc quietly gen long n_final_check = nopen+nunknown
        if _N>0 {
            forvalues i = 1/`=_N' {
                _suso_jsonesc `"`=cond(actor[`i']!="",actor[`i'],"Unknown removal actor")'"'
                local raj `"`r(js)'"'
                _suso_jsonesc `"`=actor_key[`i']'"'
                local rak `"`r(js)'"'
                _suso_jsonesc `"`=trigger[`i']'"'
                local rtj `"`r(js)'"'
                _suso_jsonesc `"`=interview__id[`i']'"'
                local riid `"`r(js)'"'
                _suso_jsonesc `"`=ws[`i']'"'
                local rws `"`r(js)'"'
                _suso_jsonesc `"`=ws_class[`i']'"'
                local rwc `"`r(js)'"'
                local rck = cond(final_data_checked[`i'],n_final_check[`i'],nopen[`i']+nunknown[`i'])
                local sep = cond(`i'==1, "", ",")
                file write `fh' `"`sep'{"a":"`raj'","k":"`rak'","t":"`rtj'","id":"`riid'","ws":"`rws'","wc":"`rwc'","cp":`=compact[`i']',"tu":`=timing_unknown[`i']',"cev":`=nrem[`i']*compact[`i']',"out":`=nrem[`i']*(1-compact[`i'])',"n":`=nrem[`i']',"q":`=nqrem[`i']',"ra":`=nreanswered[`i']',"ck":`rck',"tier":"`=tier[`i']'"}"' _n
            }
        }
        restore
    }
    file write `fh' `"],"' _n
    file write `fh' `""daily":["' _n
    quietly use `"`DAILY'"', clear
    if _N>0 {
        forvalues i = 1/`=_N' {
            _suso_jsonesc `"`=responsible[`i']'"'
            local rj `"`r(js)'"'
            local dl : di %tdCCYY-NN-DD __dd[`i']
            local sep = cond(`i'==1, "", ",")
            file write `fh' `"`sep'{"r":"`rj'","d":"`=trim("`dl'")'","c":`=__pc[`i']'}"' _n
        }
    }
    file write `fh' `"]};"' _n
    _suso_para_report_js `fh'
    file close `fh'

    * ---- finish: leave the combined table in memory --------------------------------
    quietly use `"`MERGED'"', clear
    sort interview__id
    local fullp `"`saving'"'
    if strpos(`"`saving'"',"/")==0 & strpos(`"`saving'"',"\")==0 local fullp `"`c(pwd)'/`saving'"'
    di as txt "suso paradata: interactive report written to " as res `"`fullp'"'
    di as txt `"               {browse "`fullp'":Click to open in your browser}"'
    di as txt "  `nstartedc' of `nintsc' records have fieldwork; `nuntouchedc' are untouched (preload-only) and shown separately."
    if `ncawi'>0 di as txt "  `ncawi' CAWI (web) interview(s) detected - timing flags are suppressed for them."
    if `"`hqbase'"'!="" {
        di as txt "  Headquarters links: " as res `"`hqbase'"' as txt " (interviews" ///
            cond(`hasassignment', " + assignments", " only; assignment__id not found") ")"
    }
    else di as txt "  Headquarters links: disabled (configure server/workspace or add hqurl())."
    di as txt "  timing basis: `rolenote'."
    di as txt "  in memory: one row per record (timing + flags at defaults + cascades + new signals + started marker)."
    return local  report `"`fullp'"'
    return scalar nints    = `nints'
    return scalar nstarted = `nstarted'
    return scalar ncascades = `ncasc'
    return scalar derive_passes = `nderive'
    return local hqurl `"`hqbase'"'
end

* ---- helper: escape text for HTML ----------------------------------------------
program _suso_para_hesc, rclass
    version 14.2
    gettoken s : 0
    local out = subinstr(subinstr(subinstr(`"`s'"', "&", "&amp;", .), "<", "&lt;", .), ">", "&gt;", .)
    local out = subinstr(subinstr(`"`out'"', char(34), "&#34;", .), char(39), "&#39;", .)
    return local out `"`out'"'
end

* ---- qx: parse the questionnaire HTML that ships with every data export --------
* Extracts variable name, section, type, question text, enabling condition (the
* skip logic), validation counts/messages and answer options into a dataset.
program _suso_para_qxload, rclass
    version 14.2
    syntax , FILE(string) [ SAVing(string) replace ]

    * javacall runs inside Stata's JVM, whose process working directory is not
    * guaranteed to equal Stata's current working directory. Resolve a relative
    * questionnaire path here, before it crosses the Java boundary. This keeps
    * Windows paths with spaces and either slash style safe and deterministic.
    local file = subinstr(`"`file'"', "\", "/", .)
    local qxpwd = subinstr(`"`c(pwd)'"', "\", "/", .)
    local qxabs 0
    * Absolute after slash normalization: /root, //server/share or C:/path.
    if substr(`"`file'"',1,1)=="/"  local qxabs 1
    if substr(`"`file'"',2,2)==":/" local qxabs 1
    if !`qxabs' {
        if substr(`"`qxpwd'"',length(`"`qxpwd'"'),1)=="/" ///
            local file `"`qxpwd'`file'"'
        else local file `"`qxpwd'/`file'"'
    }
    confirm file `"`file'"'
    di as txt "suso paradata: parsing questionnaire HTML ..."

    * The hierarchy-aware parser is implemented in the packaged Java bridge.
    * Keeping it out of the ado's Mata block prevents load-time compilation
    * failures while retaining section, subsection and item-level conditions.
    _suso_jar
    tempfile QXCSV
    local qxcsv = subinstr(`"`QXCSV'"', "\", "/", .)
    capture macro drop SUSO_QX_FILE SUSO_QX_OUT SUSO_QX_CWD             ///
        SUSO_QX_RESOLVED SUSO_QX_RC SUSO_QX_MSG
    global SUSO_QX_FILE `"`file'"'
    global SUSO_QX_OUT  `"`qxcsv'"'
    global SUSO_QX_CWD  `"`qxpwd'"'
    global SUSO_QX_RESOLVED ""
    global SUSO_QX_RC ""
    global SUSO_QX_MSG ""
    capture noisily javacall org.worldbank.suso.Stata qxmeta, classpath("$SUSO_JAR")
    local jrc = _rc
    local qxrc "$SUSO_QX_RC"
    local qxmsg `"$SUSO_QX_MSG"'
    local qxresolved `"$SUSO_QX_RESOLVED"'
    capture macro drop SUSO_QX_FILE SUSO_QX_OUT SUSO_QX_CWD                     ///
        SUSO_QX_RESOLVED SUSO_QX_RC SUSO_QX_MSG
    if `jrc' | "`qxrc'"!="0" {
        di as err "suso paradata qx: questionnaire parser failed."
        if `"`qxmsg'"'!="" di as err "  `qxmsg'"
        if `"`qxresolved'"'!="" di as err `"  resolved path: `qxresolved'"'
        exit 459
    }
    capture confirm file `"`qxcsv'"'
    if _rc {
        di as err "suso paradata qx: Java parser did not create its metadata file."
        exit 459
    }

    import delimited using `"`qxcsv'"', delimiter(comma) varnames(1)             ///
        stringcols(_all) bindquote(strict) encoding(utf-8) clear
    quietly destring qx_nval qx_nopts, replace force
    foreach v in qx_var qx_section qx_subsection qx_type qx_text                ///
        qx_section_enable qx_group_enable qx_item_enable qx_parent_enable       ///
        qx_enable qx_enable_deps qx_calc qx_valmsg qx_opts qx_optvals qx_optmap ///
        qx_section_tri qx_group_tri qx_item_tri {
        capture confirm string variable `v'
        if _rc {
            di as err "suso paradata qx: parser output is missing `v'."
            exit 459
        }
    }
    if _N==0 {
        di as err "suso paradata qx: no questions found — expected a Survey Solutions questionnaire preview HTML file."
        exit 459
    }

    label variable qx_var             "variable name"
    label variable qx_section         "section"
    label variable qx_subsection      "subsection/group"
    label variable qx_type            "question type"
    label variable qx_text            "question text"
    label variable qx_section_enable  "section enabling condition"
    label variable qx_group_enable    "subsection/group enabling condition"
    label variable qx_item_enable     "item-level enabling condition"
    label variable qx_parent_enable   "combined parent enabling condition"
    label variable qx_enable          "effective enabling condition"
    label variable qx_enable_deps     "direct and calculated-variable dependencies"
    label variable qx_calc            "calculated-variable expression"
    label variable qx_nval            "number of validation rules"
    label variable qx_valmsg          "first validation message"
    label variable qx_opts            "answer options (first 8 display; map stores first 60)"
    label variable qx_optvals         "answer option values (first 60)"
    label variable qx_optmap          "answer value-label map (internal)"
    label variable qx_nopts           "number of answer options"
    label variable qx_section_tri     "section condition translated for final-data evaluation"
    label variable qx_group_tri       "group condition translated for final-data evaluation"
    label variable qx_item_tri        "item condition translated for final-data evaluation"
    char _dta[suso_paradata] qx

    quietly count if qx_enable!=""
    local ne = r(N)
    quietly count if qx_nval>0
    local nv = r(N)
    di as txt "suso paradata: parsed " as res _N as txt " questions ("             ///
        as res "`ne'" as txt " with effective skip logic, " as res "`nv'" as txt " with validations)."
    di as txt "  inherited section/subsection conditions are included in qx_enable."
    if `"`saving'"'!="" {
        if "`replace'"=="" {
            capture confirm new file `"`saving'"'
            if _rc {
                di as err "suso: file already exists. Use -replace-."
                exit 602
            }
        }
        quietly save `"`saving'"', `replace'
        di as txt "  saved: " as res `"`saving'"'
    }
    return scalar nq = _N
end

* ---- check: evaluate skip logic and option values against the exported data ----
* Builds a codebook from the questionnaire HTML (enabling conditions, types,
* option values), translates the C# conditions to tri-state Stata expressions,
* and audits the exported microdata: answers present on disabled questions
* (hard skip violations), enabled questions left unanswered (item nonresponse),
* and single-select values outside the option list.  The Java parser represents
* true/false/unknown as 1/0/.5 and combines OR with max() and AND with min().
* This preserves Boolean short-circuit information: true OR unknown is true and
* false AND unknown is false.  Unsupported residual conditions remain unknown;
* they are reported, never guessed.
program _suso_para_check, rclass
    version 14.2
    syntax [if] , QX(string) DATA(string) [ SAVing(string) replace MISScodes(numlist) TOP(integer 10) HTML(string) STatus(string) FILTERS(string) ]
    confirm file `"`qx'"'
    confirm file `"`data'"'
    if "`misscodes'"=="" local misscodes "-999999999"

    * ---- codebook: parse questionnaire, retain component tri-state expressions --
    _suso_para_qxload , file(`"`qx'"')
    quietly bysort qx_var (qx_section): keep if _n==1
    quietly count
    local ncb = r(N)
    forvalues i = 1/`ncb' {
        local v_`i'  = qx_var[`i']
        local c_`i'  = qx_enable[`i']
        local cs_`i' = qx_section_tri[`i']
        local cg_`i' = qx_group_tri[`i']
        local ci_`i' = qx_item_tri[`i']
        local t_`i'  = qx_type[`i']
        local ov_`i' = qx_optvals[`i']
        local no_`i' = qx_nopts[`i']
    }
    tempfile CB
    rename qx_var qvar
    quietly keep qvar qx_section qx_type qx_text qx_enable
    quietly save `"`CB'"'

    * ---- data: normalise SuSo sentinels so missing() means unanswered ------------
    di as txt "suso paradata: loading exported data and normalising missing codes ..."
    quietly use `"`data'"', clear
    capture confirm variable interview__id
    if _rc {
        di as err "suso paradata check: data() must be a Survey Solutions main export file (interview__id not found)."
        exit 459
    }
    * optional record restriction: any Stata expression via the if qualifier
    if `"`if'"'!="" {
        capture keep `if'
        if _rc {
            di as err `"suso paradata check: the if expression could not be applied: `if'"'
            exit 198
        }
        if _N==0 {
            di as err "suso paradata check: no records match the if expression."
            exit 2000
        }
        di as txt "  restricted by expression: " as res `"`if'"' as txt " -> " as res _N as txt " records."
    }

    * optional restriction by interview status; status(approved) = 120 + 130
    if `"`status'"'!="" {
        capture confirm numeric variable interview__status
        if _rc {
            di as err "suso paradata check: status() given but interview__status is not in the data."
            exit 111
        }
        local stnums `"`status'"'
        if lower(strtrim(`"`status'"'))=="approved" local stnums "120 130"
        capture numlist "`stnums'"
        if _rc {
            di as err "suso paradata check: status() takes a list of status codes or the word approved."
            exit 198
        }
        tempvar kp
        quietly gen byte `kp' = 0
        foreach s of numlist `stnums' {
            quietly replace `kp' = 1 if interview__status==`s'
        }
        quietly keep if `kp'
        quietly drop `kp'
        if _N==0 {
            di as err "suso paradata check: no records match status(`status')."
            exit 2000
        }
        di as txt "  restricted to interview__status in {" as res "`stnums'" as txt "}: " as res _N as txt " records."
    }
    * Normalize before status/filter inventories so a configured missing code is
    * not advertised as a selectable subgroup whose later count vectors are zero.
    quietly ds, has(type numeric)
    foreach v of varlist `r(varlist)' {
        foreach mc of numlist `misscodes' {
            quietly replace `v' = . if `v'==`mc'
        }
    }
    quietly ds, has(type string)
    foreach v of varlist `r(varlist)' {
        quietly replace `v' = "" if upper(strtrim(`v'))=="##N/A##"
    }
    local nobs = _N
    * status inventory for the dashboard (per-status count vectors)
    local slist ""
    local jmeta ""
    capture confirm numeric variable interview__status
    if !_rc {
        quietly levelsof interview__status, local(slist)
        if `:word count `slist'' > 12 local slist ""
        foreach s of local slist {
            local lb : label (interview__status) `s'
            _suso_jsonesc `"`lb'"'
            local lbj `"`r(js)'"'
            quietly count if interview__status==`s'
            local jmeta `"`jmeta'`=cond(`"`jmeta'"'=="","",",")'{"c":`s',"l":"`lbj'","n":`r(N)'}"'
        }
    }
    * dynamic filter dimensions: per-value count vectors for chosen variables
    local fdimvars ""
    local nfdim 0
    local __fvbudget 0
    local __jfprobe ""
    local jfdims ""
    if `"`filters'"'!="" {
        foreach fvv of local filters {
            capture confirm numeric variable `fvv'
            if _rc {
                di as txt "  filters(): " as res "`fvv'" as txt " not found or not numeric - skipped."
                continue
            }
            quietly levelsof `fvv', local(fl)
            local nfl : word count `fl'
            if `nfl'==0 | `nfl'>20 {
                di as txt "  filters(): " as res "`fvv'" as txt " has `nfl' distinct values (limit 20) - skipped."
                continue
            }
            if `__fvbudget' + `nfl' > 40 {
                di as txt "  filters(): value budget exceeded (40 across all variables) - " as res "`fvv'" as txt " skipped."
                continue
            }
            * Stata 14 postfile accepts str#, not strL.  Admit only complete
            * dimensions whose worst-case per-question JSON remains safely below
            * str2045; never truncate a JSON fragment in the middle of a token.
            local __jfone ""
            foreach s of local fl {
                local __jfone `"`__jfone'`=cond(`"`__jfone'"'=="","",",")'"`s'":[`nobs',`nobs',`nobs',`nobs',`nobs',`nobs']"'
            }
            local __jfone `""`fvv'":{`__jfone'}"'
            local __jfcand `"`__jfprobe'`=cond(`"`__jfprobe'"'=="","",",")'`__jfone'"'
            local __jfbytes = strlen(`"`__jfcand'"')
            if `__jfbytes'>1900 {
                di as txt "  filters(): " as res "`fvv'" as txt                  ///
                    " skipped because its complete dashboard vectors exceed the Stata 14 safe JSON budget."
                continue
            }
            local __jfprobe `"`__jfcand'"'
            local fdimvars "`fdimvars' `fvv'"
            local ++nfdim
            local fdimvar_`nfdim' "`fvv'"
            local fdimvals_`nfdim' "`fl'"
            local __fvbudget = `__fvbudget' + `nfl'
            local jv1 ""
            foreach s of local fl {
                local lb : label (`fvv') `s'
                _suso_jsonesc `"`lb'"'
                local lbj `"`r(js)'"'
                quietly count if `fvv'==`s'
                local jv1 `"`jv1'`=cond(`"`jv1'"'=="","",",")'{"c":"`s'","l":"`lbj'","n":`r(N)'}"'
            }
            _suso_jsonesc `"`fvv'"'
            local fvvj `"`r(js)'"'
            local jfdims `"`jfdims'`=cond(`"`jfdims'"'=="","",",")'{"v":"`fvvj'","vals":[`jv1']}"'
        }
        local fdimvars = strtrim("`fdimvars'")
    }
    * ---- audit every codebook question present in the data -----------------------
    tempname P
    tempfile RES
    postfile `P' str80 qvar str16 qstatus                                        ///
        long n_on long n_off long n_und long n_vund long n_viol long n_imiss      ///
        long n_bad str244 badv str2045 jstat str2045 jfilt using `"`RES'"'
    local k_eval 0
    local k_noev 0
    local k_absent 0
    local k_nocond 0
    local badlist ""
    tempvar en
    forvalues i = 1/`ncb' {
        capture confirm variable `v_`i''
        if _rc {
            local ++k_absent
            post `P' ("`v_`i''") ("not in file") (.) (.) (.) (.) (.) (.) (.) ("") ("") ("")
            continue
        }
        local isnum 1
        capture confirm numeric variable `v_`i''
        if _rc local isnum 0
        local anse = cond(`isnum', "(!missing(`v_`i''))", `"(`v_`i''!="")"')
        local nund 0
        local nvu 0
        local f_on ""
        local f_un ""
        local f_vu ""
        local f_vi ""
        local f_im ""
        if `"`c_`i''"'=="" {
            local ++k_nocond
            local st "always on"
            quietly count if !`anse'
            local nim = r(N)
            local non = `nobs'
            local nof 0
            local nvl 0
            foreach s of local slist {
                quietly count if interview__status==`s'
                local f_on "`f_on',`r(N)'"
                local f_un "`f_un',0"
                local f_vu "`f_vu',0"
                local f_vi "`f_vi',0"
                quietly count if !`anse' & interview__status==`s'
                local f_im "`f_im',`r(N)'"
            }
        }
        else {
            capture drop `en'
            * Evaluate inherited hierarchy components separately, then combine
            * them as logical AND.  Each parser expression returns 0, .5 or 1;
            * min() therefore keeps a known-false parent false even if a child
            * is unknown, while max() inside a component keeps true OR unknown
            * true.  Convert only the final .5 to Stata missing for the existing
            * dashboard/count contract.
            capture quietly gen double `en' = min((`cs_`i''), (`cg_`i''), (`ci_`i''))
            if _rc {
                local ++k_noev
                if `:list sizeof badlist' < 12 local badlist "`badlist' `v_`i''"
                post `P' ("`v_`i''") ("not evaluable") (.) (.) (.) (.) (.) (.) (.) ("") ("") ("")
                continue
            }
            quietly replace `en' = . if missing(`en') | `en'==.5
            quietly replace `en' = . if !missing(`en') & !inlist(`en',0,1)
            local ++k_eval
            local st "evaluated"
            quietly count if missing(`en')
            local nund = r(N)
            quietly count if `en'==1
            local non = r(N)
            quietly count if `en'==0
            local nof = r(N)
            quietly count if `en'==0 & `anse'
            local nvl = r(N)
            quietly count if `en'==1 & !`anse'
            local nim = r(N)
            quietly count if missing(`en') & `anse'
            local nvu = r(N)
            if `non' + `nof' + `nund' != _N {
                di as err "suso paradata check: internal partition failure on `v_`i'' (`non'+`nof'+`nund' != `=_N') - please report this."
            }
            foreach s of local slist {
                quietly count if `en'==1 & interview__status==`s'
                local f_on "`f_on',`r(N)'"
                quietly count if missing(`en') & interview__status==`s'
                local f_un "`f_un',`r(N)'"
                quietly count if missing(`en') & `anse' & interview__status==`s'
                local f_vu "`f_vu',`r(N)'"
                quietly count if `en'==0 & `anse' & interview__status==`s'
                local f_vi "`f_vi',`r(N)'"
                quietly count if `en'==1 & !`anse' & interview__status==`s'
                local f_im "`f_im',`r(N)'"
            }
        }
        local nbd 0
        local bvs ""
        if `isnum' & `no_`i''>0 & `no_`i''<=60 & strpos(lower("`t_`i''"),"single-select")>0 {
            local vl : subinstr local ov_`i' " " ",", all
            if "`vl'"!="" {
                capture quietly count if !missing(`v_`i'') & !inlist(`v_`i'', `vl')
                if !_rc local nbd = r(N)
                if `nbd'>0 {
                    preserve
                    quietly keep if !missing(`v_`i'') & !inlist(`v_`i'', `vl')
                    tempvar __badcount
                    quietly contract `v_`i'', freq(`__badcount')
                    gsort -`__badcount' `v_`i''
                    forvalues b = 1/`=min(5,_N)' {
                        local bvs "`bvs' `=strofreal(`v_`i''[`b'])' (x`=`__badcount'[`b']')"
                    }
                    restore
                }
            }
        }
        local f_bd ""
        foreach s of local slist {
            local bs 0
            if `nbd'>0 {
                capture quietly count if !missing(`v_`i'') & !inlist(`v_`i'', `vl') & interview__status==`s'
                if !_rc local bs = r(N)
            }
            local f_bd "`f_bd',`bs'"
        }
        local jfilt ""
        if `nfdim'>0 {
            forvalues fi = 1/`nfdim' {
                local fvv "`fdimvar_`fi''"
                local jf1 ""
                foreach s of local fdimvals_`fi' {
                if `"`c_`i''"'=="" {
                    quietly count if `fvv'==`s'
                    local o1 = r(N)
                    local u1 0
                    local v1 0
                    local x1 0
                    quietly count if !`anse' & `fvv'==`s'
                    local m1 = r(N)
                }
                else {
                    quietly count if `en'==1 & `fvv'==`s'
                    local o1 = r(N)
                    quietly count if missing(`en') & `fvv'==`s'
                    local u1 = r(N)
                    quietly count if missing(`en') & `anse' & `fvv'==`s'
                    local v1 = r(N)
                    quietly count if `en'==0 & `anse' & `fvv'==`s'
                    local x1 = r(N)
                    quietly count if `en'==1 & !`anse' & `fvv'==`s'
                    local m1 = r(N)
                }
                local b1 0
                if `nbd'>0 {
                    capture quietly count if !missing(`v_`i'') & !inlist(`v_`i'', `vl') & `fvv'==`s'
                    if !_rc local b1 = r(N)
                }
                    local jf1 `"`jf1'`=cond(`"`jf1'"'=="","",",")'"`s'":[`o1',`u1',`v1',`x1',`m1',`b1']"'
                }
                local jfilt `"`jfilt'`=cond(`"`jfilt'"'=="","",",")'"`fvv'":{`jf1'}"'
            }
        }
        if `"`jfilt'"'!="" local jfilt `","fv":{`jfilt'}"'
        local jfrag ""
        if "`slist'"!="" {
            local jfrag `","ons":[`=substr("`f_on'",2,.)'],"uns":[`=substr("`f_un'",2,.)'],"vus":[`=substr("`f_vu'",2,.)'],"vis":[`=substr("`f_vi'",2,.)'],"ims":[`=substr("`f_im'",2,.)'],"bds":[`=substr("`f_bd'",2,.)']"'
        }
        local __jsbytes = strlen(`"`jfrag'"')
        local __jfbytes = strlen(`"`jfilt'"')
        if `__jsbytes'>2045 | `__jfbytes'>2045 {
            postclose `P'
            di as err "suso paradata check: internal dashboard JSON exceeds the Stata 14 fixed-string limit."
            di as err "                       Reduce filters() dimensions; no JSON was truncated."
            exit 459
        }
        post `P' ("`v_`i''") ("`st'") (`non') (`nof') (`nund') (`nvu') (`nvl') (`nim') (`nbd') (strtrim("`bvs'")) (`"`jfrag'"') (`"`jfilt'"')
    }
    postclose `P'
    quietly use `"`RES'"', clear
    quietly merge 1:1 qvar using `"`CB'"', keep(master match) nogenerate
    quietly gen double imiss_share = n_imiss/n_on if n_on>0

    * ---- report -------------------------------------------------------------------
    quietly summarize n_viol
    local tviol = r(sum)
    quietly summarize n_imiss
    local timiss = r(sum)
    quietly summarize n_bad
    local tbad = r(sum)
    di as txt _n "{hline 72}"
    di as res "  suso paradata check" as txt "   (`nobs' records against `ncb' codebook questions)"
    di as txt "{hline 72}"
    di as txt "  conditions evaluated " as res "`k_eval'" as txt "   always-on " as res "`k_nocond'" ///
        as txt "   not evaluable " as res "`k_noev'" as txt "   not in this file " as res "`k_absent'"
    quietly summarize n_vund
    local tvund = r(sum)
    di as txt "  answers on DISABLED questions (hard skip violations) : " as res "`tviol'"
    di as txt "  answered while the gate itself is unanswered          : " as res "`tvund'"
    di as txt "  enabled questions left unanswered (item nonresponse) : " as res "`timiss'"
    di as txt "  single-select values outside the option list         : " as res "`tbad'"
    tempvar sk
    if `tviol'>0 {
        quietly gen double `sk' = cond(missing(n_viol), -1, n_viol)
        gsort -`sk' qvar
        di as txt _n "  hard skip violations by question (top `top'):"
        di as txt "  {ul:variable                }  {ul:answered while off}  {ul:enabled}  {ul:disabled}"
        forvalues i = 1/`=min(`top',_N)' {
            if n_viol[`i']>0 & !missing(n_viol[`i']) {
                local vv : di %-24s abbrev(qvar[`i'],24)
                di as txt "  " as res "`vv'" as txt "  " %18.0f `=n_viol[`i']' "  " %7.0f `=n_on[`i']' "  " %8.0f `=n_off[`i']'
            }
        }
        di as txt "  these answers survived despite the skip logic (preloads, API writes,"
        di as txt "  or a questionnaire version change) - review before analysis."
        quietly drop `sk'
    }
    else {
        quietly summarize n_off
        di as txt _n "  no hard skip violations: " as res %12.0fc r(sum) as txt " disabled question-cases were"
        di as txt "  checked and none carries an answer. SuSo deletes answers when questions are"
        di as txt "  disabled, so violations here mean version changes or API writes - the practical"
        di as txt "  signal is the answered-while-gate-unanswered count above."
    }
    quietly count if n_vund>0 & !missing(n_vund)
    if r(N)>0 {
        tempvar sk2
        quietly gen double `sk2' = cond(missing(n_vund), -1, n_vund)
        gsort -`sk2' qvar
        di as txt _n "  answered while the gate remains undetermined (top `top'):"
        di as txt "  {ul:variable                }  {ul:answered}  {ul:undetermined}"
        forvalues i = 1/`=min(`top',_N)' {
            if n_vund[`i']>0 & !missing(n_vund[`i']) {
                local vv : di %-24s abbrev(qvar[`i'],24)
                di as txt "  " as res "`vv'" as txt "  " %8.0f `=n_vund[`i']' "  " %12.0f `=n_und[`i']'
            }
        }
        di as txt "  review missing inputs/unsupported logic, preloads, API writes, and version changes."
        quietly drop `sk2'
    }
    quietly count if n_imiss>0 & !missing(n_imiss)
    if r(N)>0 {
        quietly gen double `sk' = cond(missing(imiss_share), -1, imiss_share)
        gsort -`sk' -n_imiss qvar
        di as txt _n "  item nonresponse where the question was enabled (top `top' by share):"
        di as txt "  {ul:variable                }  {ul:unanswered}  {ul:enabled}  {ul:share}"
        forvalues i = 1/`=min(`top',_N)' {
            if n_imiss[`i']>0 & !missing(n_imiss[`i']) {
                local vv : di %-24s abbrev(qvar[`i'],24)
                local sh : di %5.2f imiss_share[`i']
                di as txt "  " as res "`vv'" as txt "  " %10.0f `=n_imiss[`i']' "  " %7.0f `=n_on[`i']' "  `sh'"
            }
        }
        quietly drop `sk'
    }
    if `k_noev'>0 di as txt _n "  not evaluable (C# beyond the translator):`badlist'"
    di as txt _n "  complements {bf:suso paradata skips} - skips catches mid-interview gate"
    di as txt "  flips from the paradata; check audits the final exported data state."
    di as txt "  n_und = records where the condition could not be scored because a"
    di as txt "  referenced numeric question was itself unanswered; n_vund counts the"
    di as txt "  suspicious subset of those that nevertheless carry an answer - impossible"
    di as txt "  in a clean interview flow (preloads or a questionnaire version change)."
    di as txt "  data in memory = one row per codebook question (merge/save as needed)."
    di as txt "{hline 72}"

    * ---- dynamic dashboard ------------------------------------------------------
    if `"`html'"'!="" {
        if "`replace'"=="" {
            capture confirm new file `"`html'"'
            if _rc {
                di as err "suso: html() file already exists. Use -replace-."
                exit 602
            }
        }
        * JSON rows built in expression-land: escape backslash, quote, control chars
        foreach v in qvar qstatus qx_section qx_type qx_text qx_enable badv {
            quietly gen strL e_`v' = subinstr(subinstr(`v', char(92), char(92)+char(92), .), char(34), char(92)+char(34), .)
            quietly replace e_`v' = subinstr(subinstr(subinstr(e_`v', char(10), " ", .), char(13), " ", .), char(9), " ", .)
            quietly replace e_`v' = subinstr(e_`v', "<", char(92)+"u003c", .)
            quietly replace e_`v' = subinstr(e_`v', ">", char(92)+"u003e", .)
            quietly replace e_`v' = subinstr(e_`v', "&", char(92)+"u0026", .)
        }
        sort qvar
        quietly gen strL j_row = cond(_n>1, ",", "")                                        ///
            + "{" + char(34)+"v"+char(34)  + ":" + char(34) + e_qvar + char(34)             ///
            + "," + char(34)+"st"+char(34) + ":" + char(34) + e_qstatus + char(34)          ///
            + "," + char(34)+"s"+char(34)  + ":" + char(34) + substr(e_qx_section,1,120) + char(34) ///
            + "," + char(34)+"t"+char(34)  + ":" + char(34) + substr(e_qx_type,1,60) + char(34)     ///
            + "," + char(34)+"on"+char(34) + ":" + cond(missing(n_on), "null", strofreal(n_on))     ///
            + "," + char(34)+"und"+char(34)+ ":" + cond(missing(n_und), "null", strofreal(n_und))   ///
            + "," + char(34)+"vu"+char(34) + ":" + cond(missing(n_vund), "null", strofreal(n_vund)) ///
            + "," + char(34)+"vi"+char(34) + ":" + cond(missing(n_viol), "null", strofreal(n_viol)) ///
            + "," + char(34)+"im"+char(34) + ":" + cond(missing(n_imiss), "null", strofreal(n_imiss)) ///
            + "," + char(34)+"bd"+char(34) + ":" + cond(missing(n_bad), "null", strofreal(n_bad))   ///
            + "," + char(34)+"sh"+char(34) + ":" + cond(missing(imiss_share), "null", strtrim(string(imiss_share, "%9.4f"))) ///
            + "," + char(34)+"q"+char(34)  + ":" + char(34) + substr(e_qx_text,1,400) + char(34)    ///
            + "," + char(34)+"e"+char(34)  + ":" + char(34) + substr(e_qx_enable,1,300) + char(34)  ///
            + "," + char(34)+"bv"+char(34) + ":" + char(34) + e_badv + char(34) + jstat + jfilt + "}"
        _suso_para_hesc `"`data'"'
        local dsrc `"`r(out)'"'
        if `"`if'"'!="" {
            _suso_para_hesc `"`if'"'
            local dsrc `"`dsrc' &nbsp;-&nbsp; restricted: `r(out)'"'
        }
        local nobsc : di %12.0fc `nobs'
        local nobsc = trim("`nobsc'")
        local wst ""
        if "$SUSO_WS"!="" {
            _suso_para_hesc `"$SUSO_WS"'
            local wst " — `r(out)'"
        }
        local now = trim("`c(current_date)' `c(current_time)'")
        tempname hf
        quietly file open `hf' using `"`html'"', write replace text
    file write `hf' `"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Data QC - Skip Logic and Values</title><style>"' _n
    file write `hf' `"body{margin:0;font-family:Segoe UI,Arial,sans-serif;background:#f4f5f7;color:#1a1a1a}"' _n
    file write `hf' `".logobar{background:#fff;padding:10px 28px;border-bottom:1px solid #e0e0e0}"' _n
    file write `hf' `".logobar .wbtxt{font-size:13px;letter-spacing:.06em;color:#002244;font-weight:600}.logobar .wbtxt span{color:#8a8a8a;font-weight:400}"' _n
    file write `hf' `".mast{background:#002244;color:#fff;padding:18px 28px}.mast h1{margin:0;font-size:21px;font-weight:600}.mast .sub{color:#c9d4e0;font-size:12px;margin-top:5px;word-break:break-all}"' _n
    file write `hf' `".wrap{max-width:1040px;margin:0 auto;padding:16px 28px 40px}"' _n
    file write `hf' `".cards{display:flex;flex-wrap:wrap;gap:10px;margin:12px 0 4px}"' _n
    file write `hf' `".card{flex:1 1 130px;background:#fff;border:1px solid #e3e6ea;border-radius:8px;padding:10px 13px;border-top:3px solid #002244}"' _n
    file write `hf' `".card.dim{border-top-color:#9aa7b5}.card.warn{border-top-color:#C9A227}"' _n
    file write `hf' `".card .v{font-size:20px;font-weight:700;color:#002244}.card .k{font-size:11px;color:#666;margin-top:2px;text-transform:uppercase;letter-spacing:.04em}"' _n
    file write `hf' `".panel{background:#fff;border:1px solid #e3e6ea;border-radius:8px;padding:12px 16px;margin:12px 0;display:flex;flex-wrap:wrap;gap:14px;align-items:flex-end;box-shadow:0 2px 6px rgba(0,0,0,.06)}"' _n
    file write `hf' `".ctrl{display:flex;flex-direction:column;gap:3px}"' _n
    file write `hf' `".ctrl label{font-size:10.5px;color:#555;text-transform:uppercase;letter-spacing:.03em}"' _n
    file write `hf' `".ctrl input,.ctrl select{font-size:13px;padding:4px 6px;border:1px solid #c9cfd6;border-radius:5px;min-width:64px}"' _n
    file write `hf' `"#c_q{min-width:200px}#c_sec{min-width:180px}"' _n
    file write `hf' `"h2{font-size:15px;color:#002244;border-bottom:2px solid #C9A227;padding-bottom:4px;margin:22px 0 6px}"' _n
    file write `hf' `".note{font-size:12px;color:#555;margin:2px 0 8px}"' _n
    file write `hf' `"section{background:#fff;border:1px solid #e3e6ea;border-radius:8px;padding:10px 16px 12px;margin-top:8px}"' _n
    file write `hf' `".hrow{display:flex;align-items:center;gap:8px;margin:3px 0;font-size:12px}"' _n
    file write `hf' `".hlab{width:200px;text-align:right;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}"' _n
    file write `hf' `".htrack{flex:1;background:#eef0f2;border-radius:3px;height:12px;overflow:hidden}"' _n
    file write `hf' `".hbar{display:block;height:12px;background:#002244}"' _n
    file write `hf' `".hval{width:120px;white-space:nowrap}"' _n
    file write `hf' `"details.qrow{background:#fff;border:1px solid #e3e6ea;border-radius:6px;margin:4px 0}"' _n
    file write `hf' `".qrow summary{display:flex;gap:10px;align-items:center;padding:7px 12px;cursor:pointer;font-size:12.5px;flex-wrap:wrap;list-style:none}"' _n
    file write `hf' `".qrow summary::-webkit-details-marker{display:none}"' _n
    file write `hf' `".qv{min-width:150px;font-weight:700;color:#002244}"' _n
    file write `hf' `".qsec{color:#777;font-size:11px;flex:1;min-width:120px}"' _n
    file write `hf' `".qn{color:#444;font-size:11.5px;white-space:nowrap}"' _n
    file write `hf' `".strack{display:inline-block;width:60px;background:#eef0f2;height:8px;border-radius:2px;vertical-align:middle;margin-right:4px}"' _n
    file write `hf' `".sbar{display:block;height:8px;background:#C9A227}"' _n
    file write `hf' `".qbody{padding:4px 14px 10px;border-top:1px solid #eef0f2;font-size:12px;color:#333}"' _n
    file write `hf' `".qt{margin:6px 0}.qm{color:#666;margin:3px 0;font-size:11.5px}"' _n
    file write `hf' `".chip{font-size:10px;border-radius:9px;padding:2px 8px;text-transform:uppercase;letter-spacing:.03em}"' _n
    file write `hf' `".chip.ok{background:#eaf0f7;color:#002244}.chip.dim{background:#f0f0f0;color:#666}"' _n
    file write `hf' `".chip.warn{background:#fdf6e3;color:#7a5b00}.chip.off{background:#f7f7f7;color:#999}"' _n
    file write `hf' `".mono{font-family:Consolas,monospace}.nodata{color:#888;font-size:12px}"' _n
    file write `hf' `".legend2{font-size:11.5px;color:#555;background:#fff;border:1px solid #e3e6ea;border-radius:8px;padding:8px 12px;margin:10px 0;line-height:1.5}"' _n
    file write `hf' `".verdict{font-size:13px;font-weight:600;border-radius:8px;padding:10px 14px;margin:10px 0;border:1px solid}"' _n
    file write `hf' `".verdict.ok{background:#eef7f0;border-color:#bfe0c8;color:#1e6b34}.verdict.warn{background:#fdf6e3;border-color:#ecd9a0;color:#7a5b00}.verdict.bad{background:#fbeeee;border-color:#e6c3c3;color:#8a1f1f}"' _n
    file write `hf' `".foot{font-size:11px;color:#777;margin-top:24px;line-height:1.5}"' _n
    file write `hf' `"#l_more{font-size:11.5px;color:#8a6d00}"' _n
    file write `hf' `".datasetline{color:#68737f;font-size:12px;margin:-4px 0 12px}"' _n
    file write `hf' `".chipnav{position:sticky;top:0;z-index:6;background:#f4f5f7;padding:8px 0 6px;margin:0 0 4px;border-bottom:1px solid #e3e6ea;display:flex;gap:6px;flex-wrap:wrap;align-items:center}"' _n
    file write `hf' `".chipx{display:inline-flex;align-items:center;gap:6px;background:#fff;border:1px solid #dfe4e8;border-radius:14px;padding:4px 11px;font-size:12px;color:#33404d;text-decoration:none;cursor:pointer}"' _n
    file write `hf' `".chipx:hover{border-color:#9fb2c4}"' _n
    file write `hf' `".chipx .n{font-weight:700;font-size:11px;padding:0 6px;border-radius:8px;font-variant-numeric:tabular-nums}"' _n
    file write `hf' `".chipx .n.b{background:#fbeaea;color:#8a1f1f}.chipx .n.w{background:#fdf6e3;color:#7a5b00}.chipx .n.g{color:#1e6b34}"' _n
    file write `hf' `".chiputil{margin-left:auto;color:#556575;background:transparent;border:0;font:inherit;font-size:12px;cursor:pointer;padding:4px 8px;border-radius:14px}"' _n
    file write `hf' `".chiputil:hover{background:#fff;box-shadow:inset 0 0 0 1px #dfe4e8}.chiputil+.chiputil{margin-left:0}"' _n
    file write `hf' `".sblock{background:#fff;border:1px solid #e3e6ea;border-radius:8px;margin:10px 0;overflow:hidden}"' _n
    file write `hf' `".sblock.sv-b{border-left:3px solid #a33}.sblock.sv-w{border-left:3px solid #C9A227}.sblock.sv-g{border-left:3px solid #7fbf95}"' _n
    file write `hf' `".shead{display:flex;width:100%;align-items:baseline;gap:10px;padding:11px 16px;background:transparent;border:0;cursor:pointer;text-align:left;font-family:inherit}"' _n
    file write `hf' `".shead h2{margin:0;font-size:15px;color:#002244;font-weight:600;border-bottom:0;padding-bottom:0}"' _n
    file write `hf' `".pillc{font-size:11px;font-weight:700;padding:1px 8px;border-radius:9px;position:relative;top:-1px;font-variant-numeric:tabular-nums}"' _n
    file write `hf' `".pillc.b{background:#fbeaea;color:#8a1f1f}.pillc.w{background:#fdf6e3;color:#7a5b00}.pillc.g{background:#eaf5ec;color:#1e6b34}"' _n
    file write `hf' `".shead .sfind{color:#556575;font-size:12.5px;margin-left:auto;text-align:right;max-width:52%}"' _n
    file write `hf' `".shead .chev{color:#8a97a4;font-size:11px;flex:0 0 auto;transition:transform .15s}"' _n
    file write `hf' `".sblock.open .chev{transform:rotate(90deg)}"' _n
    file write `hf' `".sbody{display:none;padding:2px 16px 14px;border-top:1px solid #eef0f2}"' _n
    file write `hf' `".sblock.open .sbody{display:block}"' _n
    file write `hf' `".sbody section{border:0;padding:0;margin-top:4px}"' _n
    file write `hf' `"@media print{.sbody{display:block!important}.chipnav{position:static}.shead .chev{display:none}.panel{box-shadow:none}}"' _n
    file write `hf' `"@media (prefers-reduced-motion: reduce){.shead .chev{transition:none}}"' _n
    file write `hf' `"</style></head><body>"' _n
    file write `hf' `"<div class="logobar"><!-- wbLogo slot: replace content with the base64 banner img -->"' _n
    file write `hf' `"<span class="wbtxt">THE WORLD BANK <span>| Development Economics - Policy Indicators</span> &nbsp;-&nbsp; ENTERPRISE SURVEYS <span>- What Businesses Experience</span></span></div>"' _n
    file write `hf' `"<div class="mast"><h1>Data QC — Skip Logic and Values`wst'</h1>"' _n
    file write `hf' `"<div class="sub">Generated `now' &nbsp;-&nbsp; `dsrc'</div></div>"' _n
    file write `hf' `"<div class="wrap">"' _n
    file write `hf' `"<div class="cards">"' _n
    file write `hf' `"<div class="card"><div class="v" id="k_recs">-</div><div class="k">records in view</div></div>"' _n
    file write `hf' `"<div class="card"><div class="v" id="k_shown">-</div><div class="k">questions in view</div></div>"' _n
    file write `hf' `"<div class="card warn"><div class="v" id="k_imiss">-</div><div class="k">unanswered when enabled</div></div>"' _n
    file write `hf' `"<div class="card warn"><div class="v" id="k_viol">-</div><div class="k">answers on disabled qs</div></div>"' _n
    file write `hf' `"<div class="card warn"><div class="v" id="k_bad">-</div><div class="k">out-of-list values</div></div>"' _n
    file write `hf' `"<div class="card warn"><div class="v" id="k_vund">-</div><div class="k">answered, gate undetermined</div></div>"' _n
    file write `hf' `"</div>"' _n
    file write `hf' `"<div class="datasetline">Audit: `nobsc' records audited &nbsp;-&nbsp; `k_eval' conditions evaluated &nbsp;-&nbsp; `k_nocond' always on &nbsp;-&nbsp; `k_noev' not evaluable &nbsp;-&nbsp; `k_absent' not in this file</div>"' _n
    file write `hf' `"<div class="panel">"' _n
    file write `hf' `"<div class="ctrl"><label>Search variable or text</label><input id="c_q" type="text" placeholder="e.g. a3 or sales"></div>"' _n
    file write `hf' `"<div class="ctrl"><label>Section</label><select id="c_sec"></select></div>"' _n
    file write `hf' `"<div class="ctrl"><label>Check status</label><select id="c_st"><option value="">All</option><option>evaluated</option><option value="always on">always asked</option><option>not evaluable</option><option>not in file</option></select></div>"' _n
    file write `hf' `"<div class="ctrl" id="ctl_ist"><label>Interview status</label><select id="c_ist"></select></div>"' _n
    file write `hf' `"<div class="ctrl" id="ctl_fd"><label>Filter variable</label><select id="c_fd"></select></div>"' _n
    file write `hf' `"<div class="ctrl" id="ctl_fv"><label>= value</label><select id="c_fv"></select></div>"' _n
    file write `hf' `"<div class="ctrl"><label>Min share % (chart)</label><input id="c_minsh" type="number" min="0" max="100" step="1" value="0"></div>"' _n
    file write `hf' `"<div class="ctrl"><label>Sort questions by</label><select id="c_sort"><option value="hard">hard problems first</option><option value="sh">worst nonresponse share</option><option value="im">most unanswered</option><option value="vi">most violations</option><option value="bd">most out-of-list</option><option value="v">variable name</option></select></div>"' _n
    file write `hf' `"<div class="ctrl"><label>Problems only</label><input id="c_prob" type="checkbox" style="width:20px;height:20px"></div>"' _n
    file write `hf' `"</div>"' _n
    file write `hf' `"<div class="note"><b>Population scope:</b> Interview status and Filter variable are alternative breakdowns. Choosing one clears the other; use the command's <span class="mono">if</span> qualifier when both restrictions must be applied together.</div>"' _n
    file write `hf' `"<div class="legend2"><b>Reading the counts:</b> asked = the skip logic says the question applies to the record &nbsp;&middot;&nbsp; viol = answered while the logic says it should be off (hard problem) &nbsp;&middot;&nbsp; unans = applies but no answer was recorded &nbsp;&middot;&nbsp; bad codes = a value outside the option list &nbsp;&middot;&nbsp; undetermined = the enabling condition could not be resolved after Boolean short-circuiting</div>"' _n
    file write `hf' `"<nav class='chipnav' aria-label='Audit sections'>"' _n
    file write `hf' `"<a class='chipx' href='#s_imiss' data-sec='s_imiss'>Nonresponse<span class='n' id='cb_imiss' style='display:none'></span></a>"' _n
    file write `hf' `"<a class='chipx' href='#sec_viol' data-sec='sec_viol'>Disabled answers<span class='n' id='cb_viol' style='display:none'></span></a>"' _n
    file write `hf' `"<a class='chipx' href='#sec_vund' data-sec='sec_vund'>Undetermined gate<span class='n' id='cb_vund' style='display:none'></span></a>"' _n
    file write `hf' `"<a class='chipx' href='#sec_bad' data-sec='sec_bad'>Out-of-list<span class='n' id='cb_bad' style='display:none'></span></a>"' _n
    file write `hf' `"<a class='chipx' href='#s_list' data-sec='s_list'>Questions</a>"' _n
    file write `hf' `"<button type='button' class='chiputil' id='dq_expall'>Expand all</button>"' _n
    file write `hf' `"<button type='button' class='chiputil' id='dq_collall'>Collapse all</button>"' _n
    file write `hf' `"</nav>"' _n
    file write `hf' `"<div id="v_chk" class="verdict ok"></div>"' _n
    file write `hf' `"<div class='sblock' id='s_imiss'><button class='shead' type='button' aria-expanded='false'><h2>Item nonresponse (enabled but unanswered)</h2><span class='pillc' id='p_imiss' style='display:none'></span><span class='sfind' id='f_imiss'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `hf' `"<div class="note">Top questions by unanswered share among records where the question was enabled (10+ enabled records). Service and desk questions often sit at 100% - use the filters or search to focus on interview content, and raise Min share to cut noise.</div>"' _n
    file write `hf' `"<section id="ch_imiss"></section>"' _n
    file write `hf' `"</div></div>"' _n
    file write `hf' `"<div class='sblock' id='sec_viol'><button class='shead' type='button' aria-expanded='false'><h2>Answers on disabled questions</h2><span class='pillc' id='p_viol' style='display:none'></span><span class='sfind' id='f_viol'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `hf' `"<div class="note">Hard skip violations: an answer is present although the skip logic disables the question. These enter via preloading, API writes, or questionnaire version changes.</div>"' _n
    file write `hf' `"<section id="ch_viol"></section>"' _n
    file write `hf' `"</div></div>"' _n
    file write `hf' `"<div class='sblock' id='sec_vund'><button class='shead' type='button' aria-expanded='false'><h2>Answered while the gate is undetermined</h2><span class='pillc' id='p_vund' style='display:none'></span><span class='sfind' id='f_vund'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `hf' `"<div class="note">An answer exists while the effective gate remains undetermined after Boolean short-circuiting. Review the condition and source data: this can reflect a missing required input, an unsupported residual expression, preloading, or a questionnaire-version change.</div>"' _n
    file write `hf' `"<section id="ch_vund"></section>"' _n
    file write `hf' `"</div></div>"' _n
    file write `hf' `"<div class='sblock' id='sec_bad'><button class='shead' type='button' aria-expanded='false'><h2>Single-select values outside the option list</h2><span class='pillc' id='p_bad' style='display:none'></span><span class='sfind' id='f_bad'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `hf' `"<div class="note">Values not in the questionnaire option list - open the question below to see which values (often special codes missing from the instrument definition).</div>"' _n
    file write `hf' `"<section id="ch_bad"></section>"' _n
    file write `hf' `"</div></div>"' _n
    file write `hf' `"<div class='sblock' id='s_list'><button class='shead' type='button' aria-expanded='false'><h2>Questions</h2><span class='sfind' id='f_list'></span><span class='chev'>&#9654;</span></button><div class='sbody'>"' _n
    file write `hf' `"<div class="note">Click any row for the question text, its skip condition, and the offending values. <span id="l_more"></span></div>"' _n
    file write `hf' `"<div id="list"></div>"' _n
    file write `hf' `"</div></div>"' _n
    file write `hf' `"<div class="foot"><b>Method.</b> Enabling conditions from the questionnaire HTML are translated to tri-state Stata expressions (true / false / unknown). OR uses max() and AND uses min(), so true OR unknown stays true and false AND unknown stays false; only the unresolved final gate is excluded as undetermined. Missing codes normalised: `misscodes' and the ##N/A## string sentinel. Unsupported residual conditions remain unknown and are never guessed. Produced by suso paradata check (suso v1.7.26) on `now'.</div>"' _n
    file write `hf' `"</div><script>"' _n
    file write `hf' `"var D={"meta":{"statuses":[`jmeta'],"fdims":[`jfdims']},"rows":["' _n
    forvalues i = 1/`=_N' {
        file write `hf' (j_row[`i']) _n
    }
    file write `hf' `"]};"' _n
    file write `hf' `"/* suso paradata check - dynamic dashboard engine */"' _n
    file write `hf' `"var C = {"' _n
    file write `hf' `"  deriveF: function(rows, dim, val){"' _n
    file write `hf' `"    var out=[], i, r, cell;"' _n
    file write `hf' `"    for(i=0;i<rows.length;i++){"' _n
    file write `hf' `"      r=rows[i];"' _n
    file write `hf' `"      if(!r.fv || !r.fv[dim] || !r.fv[dim][val]){ out.push(r); continue; }"' _n
    file write `hf' `"      cell=r.fv[dim][val];"' _n
    file write `hf' `"      out.push({v:r.v, st:r.st, s:r.s, t:r.t, q:r.q, e:r.e, bv:r.bv, vu:cell[2],"' _n
    file write `hf' `"        on:cell[0], und:cell[1], vi:cell[3], im:cell[4], bd:cell[5],"' _n
    file write `hf' `"        sh:cell[0]>0?cell[4]/cell[0]:null});"' _n
    file write `hf' `"    }"' _n
    file write `hf' `"    return out;"' _n
    file write `hf' `"  },"' _n
    file write `hf' `"  recsF: function(meta, dim, val){"' _n
    file write `hf' `"    if(!meta || !meta.fdims) return null;"' _n
    file write `hf' `"    var i, j;"' _n
    file write `hf' `"    for(i=0;i<meta.fdims.length;i++){"' _n
    file write `hf' `"      if(meta.fdims[i].v!==dim) continue;"' _n
    file write `hf' `"      for(j=0;j<meta.fdims[i].vals.length;j++)"' _n
    file write `hf' `"        if(meta.fdims[i].vals[j].c===val) return meta.fdims[i].vals[j].n;"' _n
    file write `hf' `"    }"' _n
    file write `hf' `"    return null;"' _n
    file write `hf' `"  },"' _n
    file write `hf' `"  derive: function(rows, meta, sel){"' _n
    file write `hf' `"    if(sel==='' || !meta || !meta.statuses || !meta.statuses.length) return rows;"' _n
    file write `hf' `"    var idxs=[], i, j;"' _n
    file write `hf' `"    if(sel==='APP'){"' _n
    file write `hf' `"      for(i=0;i<meta.statuses.length;i++) if(meta.statuses[i].c===120||meta.statuses[i].c===130) idxs.push(i);"' _n
    file write `hf' `"    } else if(sel==='FIELD'){"' _n
    file write `hf' `"      for(i=0;i<meta.statuses.length;i++) if([65,100,120,125,130].indexOf(meta.statuses[i].c)>=0) idxs.push(i);"' _n
    file write `hf' `"    } else idxs.push(parseInt(sel,10));"' _n
    file write `hf' `"    var out=[];"' _n
    file write `hf' `"    for(i=0;i<rows.length;i++){"' _n
    file write `hf' `"      var r=rows[i];"' _n
    file write `hf' `"      if(!r.ons){ out.push(r); continue; }"' _n
    file write `hf' `"      var d={v:r.v, st:r.st, s:r.s, t:r.t, q:r.q, e:r.e, bv:r.bv, vu:0, on:0, und:0, vi:0, im:0, bd:0, sh:null};"' _n
    file write `hf' `"      for(j=0;j<idxs.length;j++){"' _n
    file write `hf' `"        var k=idxs[j];"' _n
    file write `hf' `"        d.on+=r.ons[k]||0; d.und+=(r.uns?r.uns[k]:0)||0; d.vu+=(r.vus?r.vus[k]:0)||0; d.vi+=(r.vis?r.vis[k]:0)||0;"' _n
    file write `hf' `"        d.im+=(r.ims?r.ims[k]:0)||0; d.bd+=(r.bds?r.bds[k]:0)||0;"' _n
    file write `hf' `"      }"' _n
    file write `hf' `"      d.sh = d.on>0 ? d.im/d.on : null;"' _n
    file write `hf' `"      out.push(d);"' _n
    file write `hf' `"    }"' _n
    file write `hf' `"    return out;"' _n
    file write `hf' `"  },"' _n
    file write `hf' `"  recs: function(meta, sel){"' _n
    file write `hf' `"    if(!meta || !meta.statuses || !meta.statuses.length) return null;"' _n
    file write `hf' `"    var i, t=0;"' _n
    file write `hf' `"    if(sel===''){ for(i=0;i<meta.statuses.length;i++) t+=meta.statuses[i].n||0; return t; }"' _n
    file write `hf' `"    if(sel==='APP'){"' _n
    file write `hf' `"      for(i=0;i<meta.statuses.length;i++) if(meta.statuses[i].c===120||meta.statuses[i].c===130) t+=meta.statuses[i].n||0;"' _n
    file write `hf' `"      return t;"' _n
    file write `hf' `"    }"' _n
    file write `hf' `"    if(sel==='FIELD'){"' _n
    file write `hf' `"      for(i=0;i<meta.statuses.length;i++) if([65,100,120,125,130].indexOf(meta.statuses[i].c)>=0) t+=meta.statuses[i].n||0;"' _n
    file write `hf' `"      return t;"' _n
    file write `hf' `"    }"' _n
    file write `hf' `"    var k=parseInt(sel,10);"' _n
    file write `hf' `"    return meta.statuses[k] ? (meta.statuses[k].n||0) : null;"' _n
    file write `hf' `"  },"' _n
    file write `hf' `"  filt: function(rows, S){"' _n
    file write `hf' `"    var out=[], i, r, q;"' _n
    file write `hf' `"    for(i=0;i<rows.length;i++){"' _n
    file write `hf' `"      r=rows[i];"' _n
    file write `hf' `"      if(S.sec && r.s!==S.sec) continue;"' _n
    file write `hf' `"      if(S.st && r.st!==S.st) continue;"' _n
    file write `hf' `"      if(S.prob && !((r.vi||0)>0 || (r.im||0)>0 || (r.bd||0)>0 || (r.vu||0)>0)) continue;"' _n
    file write `hf' `"      if(S.q){"' _n
    file write `hf' `"        q=S.q.toLowerCase();"' _n
    file write `hf' `"        if(r.v.toLowerCase().indexOf(q)<0 && (r.q||'').toLowerCase().indexOf(q)<0) continue;"' _n
    file write `hf' `"      }"' _n
    file write `hf' `"      out.push(r);"' _n
    file write `hf' `"    }"' _n
    file write `hf' `"    return out;"' _n
    file write `hf' `"  },"' _n
    file write `hf' `"  srt: function(rows, key){"' _n
    file write `hf' `"    var out=rows.slice();"' _n
    file write `hf' `"    if(key==='v'){ out.sort(function(a,b){ return a.v<b.v?-1:1; }); return out; }"' _n
    file write `hf' `"    if(key==='hard'){"' _n
    file write `hf' `"      out.sort(function(a,b){"' _n
    file write `hf' `"        var ah=(a.vi||0)+(a.bd||0)+(a.vu||0), bh=(b.vi||0)+(b.bd||0)+(b.vu||0);"' _n
    file write `hf' `"        if(bh!==ah) return bh-ah;"' _n
    file write `hf' `"        var as2=(a.sh===null||a.sh===undefined)?-1:a.sh, bs2=(b.sh===null||b.sh===undefined)?-1:b.sh;"' _n
    file write `hf' `"        if(bs2!==as2) return bs2-as2;"' _n
    file write `hf' `"        return a.v<b.v?-1:1;"' _n
    file write `hf' `"      });"' _n
    file write `hf' `"      return out;"' _n
    file write `hf' `"    }"' _n
    file write `hf' `"    out.sort(function(a,b){"' _n
    file write `hf' `"      var av=a[key], bv=b[key];"' _n
    file write `hf' `"      if(av===null||av===undefined) av=-1;"' _n
    file write `hf' `"      if(bv===null||bv===undefined) bv=-1;"' _n
    file write `hf' `"      if(bv!==av) return bv-av;"' _n
    file write `hf' `"      return a.v<b.v?-1:1;"' _n
    file write `hf' `"    });"' _n
    file write `hf' `"    return out;"' _n
    file write `hf' `"  },"' _n
    file write `hf' `"  kpis: function(rows){"' _n
    file write `hf' `"    var t={n:rows.length, im:0, vi:0, bd:0, vu:0}, i;"' _n
    file write `hf' `"    for(i=0;i<rows.length;i++){"' _n
    file write `hf' `"      t.im+=rows[i].im||0; t.vi+=rows[i].vi||0; t.bd+=rows[i].bd||0; t.vu+=rows[i].vu||0;"' _n
    file write `hf' `"    }"' _n
    file write `hf' `"    return t;"' _n
    file write `hf' `"  },"' _n
    file write `hf' `"  topBy: function(rows, key, minOn, minSh, n){"' _n
    file write `hf' `"    var out=[], i, r;"' _n
    file write `hf' `"    for(i=0;i<rows.length;i++){"' _n
    file write `hf' `"      r=rows[i];"' _n
    file write `hf' `"      if(!(r[key]>0)) continue;"' _n
    file write `hf' `"      if(minOn && !((r.on||0)>=minOn)) continue;"' _n
    file write `hf' `"      if(minSh && !((r.sh||0)>=minSh)) continue;"' _n
    file write `hf' `"      out.push(r);"' _n
    file write `hf' `"    }"' _n
    file write `hf' `"    out=C.srt(out, key==='im'?'sh':key);"' _n
    file write `hf' `"    return out.slice(0, n||15);"' _n
    file write `hf' `"  }"' _n
    file write `hf' `"};"' _n
    file write `hf' `"if (typeof module!=='undefined' && module.exports) module.exports=C;"' _n
    file write `hf' _n
    file write `hf' `"if (typeof document!=='undefined') {"' _n
    file write `hf' `"var Q=String.fromCharCode(34);"' _n
    file write `hf' `"function at(n,v){ return ' '+n+'='+Q+v+Q; }"' _n
    file write `hf' `"function el(id){ return document.getElementById(id); }"' _n
    file write `hf' `"function esc(s){ return String(s==null?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }"' _n
    file write `hf' `"function fc(x){"' _n
    file write `hf' `"  if(x===null||x===undefined) return '.';"' _n
    file write `hf' `"  var s=String(Math.round(x)), o='', c=0, i;"' _n
    file write `hf' `"  for(i=s.length-1;i>=0;i--){ o=s.charAt(i)+o; c++; if(c%3===0&&i>0) o=','+o; }"' _n
    file write `hf' `"  return o;"' _n
    file write `hf' `"}"' _n
    file write `hf' `"function pct(x){ return (x===null||x===undefined)?'.':(100*x).toFixed(1)+'%'; }"' _n
    file write `hf' _n
    file write `hf' `"function settings(){"' _n
    file write `hf' `"  return {"' _n
    file write `hf' `"    q: el('c_q').value.trim(),"' _n
    file write `hf' `"    sec: el('c_sec').value,"' _n
    file write `hf' `"    st: el('c_st').value,"' _n
    file write `hf' `"    prob: el('c_prob').checked,"' _n
    file write `hf' `"    ist: el('c_ist').value,"' _n
    file write `hf' `"    fd:  el('c_fd').value,"' _n
    file write `hf' `"    fv:  el('c_fv').value,"' _n
    file write `hf' `"    minsh: (parseFloat(el('c_minsh').value)||0)/100,"' _n
    file write `hf' `"    sort: el('c_sort').value"' _n
    file write `hf' `"  };"' _n
    file write `hf' `"}"' _n
    file write `hf' _n
    file write `hf' `"function hbars(cont, rows, key, denomNote){"' _n
    file write `hf' `"  if(!rows.length){ el(cont).innerHTML='<p class='+Q+'nodata'+Q+'>Nothing above the current thresholds.</p>'; return; }"' _n
    file write `hf' `"  var max=0, i;"' _n
    file write `hf' `"  for(i=0;i<rows.length;i++) if(rows[i][key]>max) max=rows[i][key];"' _n
    file write `hf' `"  var s='';"' _n
    file write `hf' `"  for(i=0;i<rows.length;i++){"' _n
    file write `hf' `"    var r=rows[i], w=Math.max(2, Math.round(100*r[key]/max));"' _n
    file write `hf' `"    var val=(key==='im') ? (fc(r.im)+' ('+pct(r.sh)+')') : fc(r[key]);"' _n
    file write `hf' `"    s+='<div class='+Q+'hrow'+Q+'><span class='+Q+'hlab mono'+Q+'>'+esc(r.v)+'</span>'+"' _n
    file write `hf' `"       '<span class='+Q+'htrack'+Q+'><span class='+Q+'hbar'+Q+at('style','width:'+w+'%')+'></span></span>'+"' _n
    file write `hf' `"       '<span class='+Q+'hval'+Q+'>'+val+'</span></div>';"' _n
    file write `hf' `"  }"' _n
    file write `hf' `"  el(cont).innerHTML=s;"' _n
    file write `hf' `"}"' _n
    file write `hf' _n
    file write `hf' `"function chip(st){"' _n
    file write `hf' `"  var cl = st==='evaluated'?'ok':(st==='always on'?'dim':(st==='not evaluable'?'warn':'off'));"' _n
    file write `hf' `"  var lab = st==='always on' ? 'always asked' : st;"' _n
    file write `hf' `"  return '<span class='+Q+'chip '+cl+Q+'>'+esc(lab)+'</span>';"' _n
    file write `hf' `"}"' _n
    file write `hf' _n
    file write `hf' `"function renderList(rows, S){"' _n
    file write `hf' `"  var k=Math.min(rows.length, 250), s='', i;"' _n
    file write `hf' `"  for(i=0;i<k;i++){"' _n
    file write `hf' `"    var r=rows[i];"' _n
    file write `hf' `"    var shb = (r.sh!=null && r.on>0)"' _n
    file write `hf' `"      ? '<span class='+Q+'strack'+Q+'><span class='+Q+'sbar'+Q+at('style','width:'+Math.round(100*Math.min(r.sh,1))+'%')+'></span></span>'+pct(r.sh)"' _n
    file write `hf' `"      : '';"' _n
    file write `hf' `"    s+='<details class='+Q+'qrow'+Q+'><summary>'+"' _n
    file write `hf' `"       '<span class='+Q+'mono qv'+Q+'>'+esc(r.v)+'</span>'+chip(r.st)+"' _n
    file write `hf' `"       '<span class='+Q+'qsec'+Q+'>'+esc(r.s||'')+'</span>'+"' _n
    file write `hf' `"       '<span class='+Q+'qn'+Q+'>asked '+fc(r.on)+'</span>'+"' _n
    file write `hf' `"       '<span class='+Q+'qn'+Q+(r.vi>0?' style='+Q+'color:#a33;font-weight:700'+Q:'')+'>viol '+fc(r.vi)+'</span>'+"' _n
    file write `hf' `"       '<span class='+Q+'qn'+Q+'>unans '+fc(r.im)+' '+shb+'</span>'+"' _n
    file write `hf' `"       '<span class='+Q+'qn'+Q+(r.bd>0?' style='+Q+'color:#7a5b00;font-weight:700'+Q:'')+'>bad codes '+fc(r.bd)+'</span>'+"' _n
    file write `hf' `"       '</summary><div class='+Q+'qbody'+Q+'>'+"' _n
    file write `hf' `"       (r.q?('<div class='+Q+'qt'+Q+'>&quot;'+esc(r.q)+'&quot;</div>'):'')+"' _n
    file write `hf' `"       (r.t?('<div class='+Q+'qm'+Q+'>Type: '+esc(r.t)+'</div>'):'')+"' _n
    file write `hf' `"       (r.e?('<div class='+Q+'qm'+Q+'>Asked only when: <span class='+Q+'mono'+Q+'>'+esc(r.e)+'</span></div>'):'')+"' _n
    file write `hf' `"       (r.bv?('<div class='+Q+'qm'+Q+'>Out-of-list values (count): <span class='+Q+'mono'+Q+'>'+esc(r.bv)+'</span></div>'):'')+"' _n
    file write `hf' `"       ((r.und>0)?('<div class='+Q+'qm'+Q+'>'+fc(r.und)+' records have a gate that remains undetermined after Boolean short-circuiting'+((r.vu>0)?(' - <b>'+fc(r.vu)+' of them carry an answer and require review</b>'):'')+'.</div>'):'')+"' _n
    file write `hf' `"       '</div></details>';"' _n
    file write `hf' `"  }"' _n
    file write `hf' `"  el('list').innerHTML=s || '<p class='+Q+'nodata'+Q+'>No questions match the filters.</p>';"' _n
    file write `hf' `"  el('l_more').textContent = rows.length>k ? ('Showing '+k+' of '+rows.length+' questions - refine the filters.') : '';"' _n
    file write `hf' `"}"' _n
    file write `hf' _n
    file write `hf' `"function fvOptions(){"' _n
    file write `hf' `"  var dim=el('c_fd').value, Q3=String.fromCharCode(34), s='<option value='+Q3+Q3+'>-</option>', i, j;"' _n
    file write `hf' `"  if(dim && D.meta && D.meta.fdims){"' _n
    file write `hf' `"    for(i=0;i<D.meta.fdims.length;i++){"' _n
    file write `hf' `"      if(D.meta.fdims[i].v!==dim) continue;"' _n
    file write `hf' `"      var vv=D.meta.fdims[i].vals;"' _n
    file write `hf' `"      for(j=0;j<vv.length;j++){"' _n
    file write `hf' `"        var lab=(vv[j].l&&vv[j].l!==vv[j].c)?(vv[j].c+' '+vv[j].l):vv[j].c;"' _n
    file write `hf' `"        s+='<option value='+Q3+esc(vv[j].c)+Q3+'>'+esc(lab)+' ('+fc(vv[j].n)+')</option>';"' _n
    file write `hf' `"      }"' _n
    file write `hf' `"    }"' _n
    file write `hf' `"  }"' _n
    file write `hf' `"  el('c_fv').innerHTML=s;"' _n
    file write `hf' `"}"' _n
    file write `hf' `"/* triage sections: live severity, pills, findings (Data QC) */"' _n
    file write `hf' `"var secState=Object.create(null), secDefaultsDone=false;"' _n
    file write `hf' `"function secApply(id){"' _n
    file write `hf' `"  var s=el(id); if(!s) return;"' _n
    file write `hf' `"  var st=secState[id]||(secState[id]={open:false,sev:''});"' _n
    file write `hf' `"  s.className='sblock'+(st.sev?(' sv-'+st.sev):'')+(st.open?' open':'');"' _n
    file write `hf' `"  var b=s.querySelector('.shead');"' _n
    file write `hf' `"  if(b) b.setAttribute('aria-expanded',st.open?'true':'false');"' _n
    file write `hf' `"}"' _n
    file write `hf' `"function secOpen(id,open){ var st=secState[id]||(secState[id]={open:false,sev:''}); st.open=!!open; secApply(id); }"' _n
    file write `hf' `"function secToggle(id){ var st=secState[id]||(secState[id]={open:false,sev:''}); st.open=!st.open; secApply(id); }"' _n
    file write `hf' `"function secSev(id,sev){ var st=secState[id]||(secState[id]={open:false,sev:''}); st.sev=sev||''; secApply(id); }"' _n
    file write `hf' `"function setPill(pid,cid,n,sev){"' _n
    file write `hf' `"  var txt=(n>0)?fc(n):'\u2713', cls=(n>0)?sev:'g';"' _n
    file write `hf' `"  var p=el(pid); if(p){ p.textContent=txt; p.className='pillc '+cls; p.style.display=''; }"' _n
    file write `hf' `"  var c=el(cid); if(c){ c.textContent=txt; c.className='n '+cls; c.style.display=''; }"' _n
    file write `hf' `"}"' _n
    file write `hf' `"function setFind(fid,txt){ var f=el(fid); if(f) f.textContent=txt; }"' _n
    file write `hf' `"function plural(n,s,p){ return n===1?s:(p||(s+'s')); }"' _n
    file write `hf' `"function initDqSections(){"' _n
    file write `hf' `"  var i, hs=document.querySelectorAll('.sblock .shead');"' _n
    file write `hf' `"  for(i=0;i<hs.length;i++)(function(b){ b.addEventListener('click',function(){ var s=b.parentNode; if(s&&s.id) secToggle(s.id); }); })(hs[i]);"' _n
    file write `hf' `"  var cs=document.querySelectorAll('.chipx');"' _n
    file write `hf' `"  for(i=0;i<cs.length;i++)(function(a){ a.addEventListener('click',function(ev){"' _n
    file write `hf' `"    if(ev&&ev.preventDefault) ev.preventDefault();"' _n
    file write `hf' `"    var id=a.getAttribute('data-sec'); if(!id) return;"' _n
    file write `hf' `"    secOpen(id,true);"' _n
    file write `hf' `"    var s=el(id); if(s&&s.scrollIntoView) s.scrollIntoView({behavior:'smooth',block:'start'});"' _n
    file write `hf' `"  }); })(cs[i]);"' _n
    file write `hf' `"  var ea=el('dq_expall'), ec=el('dq_collall'), all=document.querySelectorAll('.sblock'), j;"' _n
    file write `hf' `"  if(ea) ea.addEventListener('click',function(){ for(j=0;j<all.length;j++) if(all[j].id) secOpen(all[j].id,true); });"' _n
    file write `hf' `"  if(ec) ec.addEventListener('click',function(){ for(j=0;j<all.length;j++) if(all[j].id) secOpen(all[j].id,false); });"' _n
    file write `hf' `"}"' _n
    file write `hf' `"function updateDqSections(K,scope){"' _n
    file write `hf' `"  secSev('s_imiss', K.im>0?'w':'g'); setPill('p_imiss','cb_imiss',K.im,'w');"' _n
    file write `hf' `"  setFind('f_imiss', K.im>0"' _n
    file write `hf' `"    ? (fc(K.im)+' unanswered enabled '+plural(K.im,'cell')+' across '+fc(K.n)+' '+plural(K.n,'question'))"' _n
    file write `hf' `"    : 'No enabled-but-unanswered cells in this view');"' _n
    file write `hf' `"  secSev('sec_viol', K.vi>0?'b':'g'); setPill('p_viol','cb_viol',K.vi,'b');"' _n
    file write `hf' `"  setFind('f_viol', K.vi>0"' _n
    file write `hf' `"    ? (fc(K.vi)+' '+plural(K.vi,'answer')+' on disabled questions')"' _n
    file write `hf' `"    : 'No answers on disabled questions in this view');"' _n
    file write `hf' `"  secSev('sec_vund', K.vu>0?'b':'g'); setPill('p_vund','cb_vund',K.vu,'b');"' _n
    file write `hf' `"  setFind('f_vund', K.vu>0"' _n
    file write `hf' `"    ? (fc(K.vu)+' answered while the gate is undetermined')"' _n
    file write `hf' `"    : 'No undetermined-gate answers in this view');"' _n
    file write `hf' `"  secSev('sec_bad', K.bd>0?'b':'g'); setPill('p_bad','cb_bad',K.bd,'b');"' _n
    file write `hf' `"  setFind('f_bad', K.bd>0"' _n
    file write `hf' `"    ? (fc(K.bd)+' out-of-list '+plural(K.bd,'value'))"' _n
    file write `hf' `"    : 'No out-of-list values in this view');"' _n
    file write `hf' `"  setFind('f_list', fc(K.n)+' '+plural(K.n,'question')+' in view - '+scope);"' _n
    file write `hf' `"  if(!secDefaultsDone){ secDefaultsDone=true; secOpen('s_list',true); }"' _n
    file write `hf' `"}"' _n
    file write `hf' `"function renderAll(){"' _n
    file write `hf' `"  var S=settings();"' _n
    file write `hf' `"  var rows0;"' _n
    file write `hf' `"  if(S.fd && S.fv) rows0=C.deriveF(D.rows, S.fd, S.fv);"' _n
    file write `hf' `"  else rows0=C.derive(D.rows, D.meta, S.ist);"' _n
    file write `hf' `"  var rows=C.filt(rows0, S);"' _n
    file write `hf' `"  var K=C.kpis(rows);"' _n
    file write `hf' `"  el('k_shown').textContent=fc(K.n);"' _n
    file write `hf' `"  var rc=(S.fd&&S.fv)?C.recsF(D.meta,S.fd,S.fv):C.recs(D.meta,S.ist);"' _n
    file write `hf' `"  el('k_recs').textContent = rc===null ? '-' : fc(rc);"' _n
    file write `hf' `"  el('k_imiss').textContent=fc(K.im);"' _n
    file write `hf' `"  el('k_viol').textContent=fc(K.vi);"' _n
    file write `hf' `"  el('k_bad').textContent=fc(K.bd);"' _n
    file write `hf' `"  el('k_vund').textContent=fc(K.vu);"' _n
    file write `hf' `"  var hard=(K.vi||0)+(K.bd||0)+(K.vu||0), vtx, vcl;"' _n
    file write `hf' `"  var scope = (S.fd&&S.fv) ? ('filter '+S.fd+' = '+S.fv) : (S.ist==='FIELD' ? 'records with fieldwork done' : (S.ist==='' ? 'ALL records including not-yet-started ones' : 'the selected status'));"' _n
    file write `hf' `"  if(hard>0){"' _n
    file write `hf' `"    vtx='Hard problems: '+fc(K.vi)+' answer(s) on disabled questions, '+fc(K.bd)+' out-of-list value(s), '+fc(K.vu)+' undetermined-with-answer, across '+fc(K.n)+' question(s) in view. Item nonresponse: '+fc(K.im)+' unanswered enabled cell(s). Scope: '+scope+'.';"' _n
    file write `hf' `"    vcl='bad';"' _n
    file write `hf' `"  } else {"' _n
    file write `hf' `"    vtx='No hard problems in this view. The workload is item nonresponse: '+fc(K.im)+' unanswered enabled cell(s) across '+fc(K.n)+' question(s). Scope: '+scope+'.';"' _n
    file write `hf' `"    vcl=(K.im>0)?'warn':'ok';"' _n
    file write `hf' `"  }"' _n
    file write `hf' `"  el('v_chk').textContent=vtx;"' _n
    file write `hf' `"  el('v_chk').className='verdict '+vcl;"' _n
    file write `hf' `"  if(window.parent!==window)window.parent.postMessage({type:'suso-tab-badge',n:hard,sev:(hard>0?'b':(K.im>0?'w':'g'))},'*');"' _n
    file write `hf' `"  updateDqSections(K,scope);"' _n
    file write `hf' `"  hbars('ch_imiss', C.topBy(rows,'im',10,S.minsh,15), 'im');"' _n
    file write `hf' `"  var tv=C.topBy(rows,'vi',0,0,15);"' _n
    file write `hf' `"  if(tv.length) hbars('ch_viol', tv, 'vi'); else el('ch_viol').innerHTML='<p class=\"nodata\">None in this view.</p>';"' _n
    file write `hf' `"  var tb=C.topBy(rows,'bd',0,0,15);"' _n
    file write `hf' `"  if(tb.length) hbars('ch_bad', tb, 'bd'); else el('ch_bad').innerHTML='<p class=\"nodata\">None in this view.</p>';"' _n
    file write `hf' `"  var tu=C.topBy(rows,'vu',0,0,15);"' _n
    file write `hf' `"  if(tu.length) hbars('ch_vund', tu, 'vu'); else el('ch_vund').innerHTML='<p class=\"nodata\">None in this view.</p>';"' _n
    file write `hf' `"  renderList(C.srt(rows, S.sort), S);"' _n
    file write `hf' `"}"' _n
    file write `hf' _n
    file write `hf' `"function init(){"' _n
    file write `hf' `"  var i;"' _n
    file write `hf' `"  var sts=(D.meta&&D.meta.statuses)?D.meta.statuses:[];"' _n
    file write `hf' `"  if(sts.length){"' _n
    file write `hf' `"    var hasApp=false, o='<option value='+Q+Q+'>All statuses</option>';"' _n
    file write `hf' `"    var hasField=false;"' _n
    file write `hf' `"    for(i=0;i<sts.length;i++){ if(sts[i].c===120||sts[i].c===130) hasApp=true; if([65,100,120,125,130].indexOf(sts[i].c)>=0) hasField=true; }"' _n
    file write `hf' `"    if(hasField) o+='<option value='+Q+'FIELD'+Q+'>Fieldwork done (completed + rejected + approved)</option>';"' _n
    file write `hf' `"    if(hasApp) o+='<option value='+Q+'APP'+Q+'>Approved only (Sup + HQ)</option>';"' _n
    file write `hf' `"    for(i=0;i<sts.length;i++) o+='<option value='+Q+i+Q+'>'+esc(sts[i].l||String(sts[i].c))+' ('+fc(sts[i].n)+')</option>';"' _n
    file write `hf' `"    el('c_ist').innerHTML=o;"' _n
    file write `hf' `"    if(hasField) el('c_ist').value='FIELD';"' _n
    file write `hf' `"  } else {"' _n
    file write `hf' `"    el('ctl_ist').style.display='none';"' _n
    file write `hf' `"  }"' _n
    file write `hf' `"  var secs=Object.create(null);"' _n
    file write `hf' `"  for(i=0;i<D.rows.length;i++) if(D.rows[i].s) secs[D.rows[i].s]=1;"' _n
    file write `hf' `"  var names=Object.keys(secs).sort(), s='<option value='+Q+Q+'>All sections</option>';"' _n
    file write `hf' `"  for(i=0;i<names.length;i++) s+='<option>'+esc(names[i])+'</option>';"' _n
    file write `hf' `"  el('c_sec').innerHTML=s;"' _n
    file write `hf' `"  var fds=(D.meta&&D.meta.fdims)?D.meta.fdims:[];"' _n
    file write `hf' `"  if(fds.length){"' _n
    file write `hf' `"    var Q4=String.fromCharCode(34), fo='<option value='+Q4+Q4+'>None</option>';"' _n
    file write `hf' `"    for(i=0;i<fds.length;i++) fo+='<option>'+esc(fds[i].v)+'</option>';"' _n
    file write `hf' `"    el('c_fd').innerHTML=fo;"' _n
    file write `hf' `"    fvOptions();"' _n
    file write `hf' `"  } else {"' _n
    file write `hf' `"    el('ctl_fd').style.display='none';"' _n
    file write `hf' `"    el('ctl_fv').style.display='none';"' _n
    file write `hf' `"  }"' _n
    file write `hf' `"  el('c_fd').addEventListener('change',function(){ fvOptions(); if(el('c_fd').value) el('c_ist').value=''; renderAll(); });"' _n
    file write `hf' `"  el('c_ist').addEventListener('change',function(){ if(el('c_ist').value){ el('c_fd').value=''; fvOptions(); } renderAll(); });"' _n
    file write `hf' `"  var ids=['c_q','c_sec','c_st','c_prob','c_minsh','c_sort','c_fv'];"' _n
    file write `hf' `"  for(i=0;i<ids.length;i++){"' _n
    file write `hf' `"    el(ids[i]).addEventListener('change',renderAll);"' _n
    file write `hf' `"    el(ids[i]).addEventListener('input',renderAll);"' _n
    file write `hf' `"  }"' _n
    file write `hf' `"  initDqSections();"' _n
    file write `hf' `"  renderAll();"' _n
    file write `hf' `"}"' _n
    file write `hf' `"init();"' _n
    file write `hf' `"}"' _n
    file write `hf' _n
    file write `hf' `"</script></body></html>"' _n
    file close `hf'
    local fullh `"`html'"'
    if strpos(`"`html'"',"/")==0 & strpos(`"`html'"',"\")==0 local fullh `"`c(pwd)'/`html'"'
    di as txt "  dashboard written: " as res `"`fullh'"'
    di as txt `"               {browse "`fullh'":Click to open in your browser}"'
    }

    sort qvar
    if `"`saving'"'!="" {
        if "`replace'"=="" {
            capture confirm new file `"`saving'"'
            if _rc {
                di as err "suso: file already exists. Use -replace-."
                exit 602
            }
        }
        quietly save `"`saving'"', `replace'
        di as txt "  saved: " as res `"`saving'"'
    }
    return scalar nviol   = `tviol'
    return scalar nvund   = `tvund'
    return scalar nimiss  = `timiss'
    return scalar nbadval = `tbad'
    return scalar nevaluated = `k_eval'
    return scalar nnoteval   = `k_noev'
end

* ---- suite: the three QC pages combined into one tabbed, self-contained HTML ----
* Tab 1 Behaviour (interactive paradata report), tab 2 Skips & removals (supervisor
* review page), tab 3 Data QC (skip logic + option values vs the exported data).
* Each page is embedded in its own iframe (srcdoc), so its document, styles and
* element ids stay isolated while Headquarters links can open in a new tab.
program _suso_para_suite, rclass
    version 14.2
    syntax [if] [, SAVing(string) replace TITle(string) QX(string) DATA(string)  ///
        GAPMins(real 30) FASTsecs(real 2) ALLRoles LITEcap(integer 15000)         ///
        CASCade(integer 3) WINdow(real 60) TOP(integer 15)                         ///
        MISScodes(numlist) STatus(string) FILTERS(string) VARS(string) HQURL(string) ]
    _suso_para_need events

    _suso_para_hqbase , hqurl(`"`hqurl'"')
    local hqbase `"`r(url)'"'

    * Resolve suite paths against Stata's working directory before any nested
    * command or Java call. The JVM may use a different process directory.
    local suitepwd = subinstr(`"`c(pwd)'"', "\", "/", .)
    if `"`qx'"'!="" {
        local qx = subinstr(`"`qx'"', "\", "/", .)
        local qxabs 0
        if substr(`"`qx'"',2,1)==":" local qxabs 1
        if substr(`"`qx'"',1,1)=="/" local qxabs 1
        if !`qxabs' {
            if substr(`"`suitepwd'"',-1,1)=="/" local qx `"`suitepwd'`qx'"'
            else local qx `"`suitepwd'/`qx'"'
        }
    }
    if `"`data'"'!="" {
        local data = subinstr(`"`data'"', "\", "/", .)
        local dataabs 0
        if substr(`"`data'"',2,1)==":" local dataabs 1
        if substr(`"`data'"',1,1)=="/" local dataabs 1
        if !`dataabs' {
            if substr(`"`suitepwd'"',-1,1)=="/" local data `"`suitepwd'`data'"'
            else local data `"`suitepwd'/`data'"'
        }
    }
    if `"`saving'"'!="" {
        local saving = subinstr(`"`saving'"', "\", "/", .)
        local saveabs 0
        if substr(`"`saving'"',2,1)==":" local saveabs 1
        if substr(`"`saving'"',1,1)=="/" local saveabs 1
        if !`saveabs' {
            if substr(`"`suitepwd'"',-1,1)=="/" local saving `"`suitepwd'`saving'"'
            else local saving `"`suitepwd'/`saving'"'
        }
    }

    if `"`saving'"'=="" local saving "suso_qc_suite.html"
    if "`replace'"=="" {
        capture confirm new file `"`saving'"'
        if _rc {
            di as err "suso: file already exists. Use -replace-."
            exit 602
        }
    }
    if `"`data'"'!="" & `"`qx'"'=="" {
        di as err "suso paradata suite: the Data QC tab needs the questionnaire — add qx(file.html)."
        exit 198
    }
    if `"`qx'"'!="" {
        capture confirm file `"`qx'"'
        if _rc {
            di as err `"suso paradata suite: questionnaire HTML not found: `qx'"'
            exit 601
        }
    }
    if `"`data'"'!="" {
        capture confirm file `"`data'"'
        if _rc {
            di as err `"suso paradata suite: data file not found: `data'"'
            exit 601
        }
    }
    if `"`title'"'=="" {
        local title "Survey QC Suite"
        if "$SUSO_WS"!="" local title "Survey QC Suite — $SUSO_WS"
    }
    di as txt "suso paradata: building the QC suite ..."
    di as txt "  code build: 1.7.26-SUITETRIAGE"
    tempfile EVX T1 T2 T3
    quietly save `"`EVX'"'

    * Fail fast on questionnaire/final-data problems.  This audit is much
    * smaller than the paradata stream, so run it before the expensive event
    * derivation instead of discovering a Data-QC incompatibility hours later.
    local t3p ""
    local note3 "Run the suite with data(mainexport.dta) to add this tab: it audits the exported data against the questionnaire skip logic and option lists."
    local nviol .
    if `"`data'"'!="" {
        di as txt "  [preflight] data QC dashboard (run first to fail fast)"
        local xopt ""
        if "`misscodes'"!="" local xopt "`xopt' misscodes(`misscodes')"
        if `"`status'"'!=""  local xopt `"`xopt' status(`status')"'
        if `"`filters'"'!="" local xopt `"`xopt' filters(`filters')"'
        capture noisily _suso_para_check `if' , qx(`"`qx'"') data(`"`data'"')    ///
            html(`"`T3'"') replace top(`top') `xopt'
        local rc3 = _rc
        if `rc3' {
            quietly use `"`EVX'"', clear
            di as err "suso paradata suite: Data QC preflight failed (rc=`rc3')."
            exit `rc3'
        }
        local nviol = r(nviol)
        local t3p `"`T3'"'
        local note3 ""
        quietly use `"`EVX'"', clear
    }

    di as txt "  [1/3] behaviour report"
    capture noisily _suso_para_report , saving(`"`T1'"') replace qx(`"`qx'"')     ///
        data(`"`data'"') filters(`"`filters'"') vars(`"`vars'"')                  ///
        gapmins(`gapmins') fastsecs(`fastsecs') `allroles'                        ///
        cascade(`cascade') window(`window') litecap(`litecap') hqurl(`"`hqbase'"') ///
        skiphtml(`"`T2'"') skiptop(`top')
    local rc1 = _rc
    if `rc1' {
        quietly use `"`EVX'"', clear
        di as err "suso paradata suite: Behaviour tab failed (rc=`rc1')."
        exit `rc1'
    }
    local nstarted = r(nstarted)
    local ncasc    = r(ncascades)
    local nderive  = r(derive_passes)
    * Nothing below needs the report's in-memory interview table.  Restore the
    * caller's events now, so an outer-HTML write error cannot strand a collapsed
    * dataset in memory.
    quietly use `"`EVX'"', clear

    di as txt "  [2/3] skip/removal review (reused from the Behaviour cache)"
    local t2p `"`T2'"'
    local note2 ""
    capture confirm file `"`T2'"'
    if _rc {
        local t2p ""
        local note2 "No in-scope AnswerRemoved history was available for the Skips & removals review."
        if `"`vars'"'!="" local note2                          ///
            "No AnswerRemoved history matched the vars() scope."
    }

    if `"`data'"'!="" di as txt "  [3/3] data QC dashboard (preflight complete)"
    else di as txt "  [3/3] data QC dashboard skipped (no data() given)"

    _suso_para_hesc `"`title'"'
    local etitle `"`r(out)'"'
    local sub "Generated `c(current_date)' `c(current_time)'"
    if "$SUSO_BASE"!="" local sub "`sub' - $SUSO_BASE"
    local sub "`sub' | Scope: Behaviour metrics/risk = all loaded paradata; vars() focuses Behaviour removal detail and the Skip tab; filters() are interactive; Data QC = data() `if'."
    _suso_para_hesc `"`sub'"'
    local sub `"`r(out)'"'
    local t1p `"`T1'"'
    mata: _suso_suite_write(st_local("saving"), st_local("etitle"), st_local("sub"), ///
        st_local("t1p"), st_local("t2p"), st_local("t3p"),                           ///
        st_local("note2"), st_local("note3"))

    local fullp `"`saving'"'
    if strpos(`"`saving'"',"/")==0 & strpos(`"`saving'"',"\")==0 local fullp `"`c(pwd)'/`saving'"'
    di as txt "suso paradata: QC suite written to " as res `"`fullp'"'
    di as txt `"               {browse "`fullp'":Click to open in your browser}"'
    di as txt "  tabs: Behaviour (interactive) | Skips & removals | Data QC"
    di as txt "  scope: Behaviour metrics/risk use all loaded paradata; vars() focuses removal detail and the Skip tab."
    di as txt "         suite [if] applies to Data QC only; filters() are interactive Behaviour/Data-QC controls."
    if `"`filters'"'!="" di as txt "         filters() adds interactive/data-QC breakdowns; it is not a case-subsetting expression."
    di as txt "  events left in memory, unchanged."
    return local  suite `"`fullp'"'
    return scalar nstarted  = `nstarted'
    return scalar ncascades = `ncasc'
    return scalar derive_passes = `nderive'
    if `"`data'"'!="" return scalar nviol = `nviol'
    return local hqurl `"`hqbase'"'
end

*===============================================================================
* examples — copy/paste recipes printed in the Results window
*===============================================================================
program _suso_examples
    di as txt _n "{hline 72}"
    di as res    "  suso — copy / paste recipes"
    di as txt    "  (replace the bits in <...>; clickable links run the safe ones)"
    di as txt    "{hline 72}"

    di as res _n "  1) CONNECT  (once per Stata session)"
    di as txt    "     suso config , server(<url>) workspace(<ws>) user(<apiuser>) password(<pw>)"
    di as txt    "     suso config , guid(<questionnaire-GUID>) qver(<version>)   {txt}// set your survey ONCE"
    di as txt    "     suso ping"
    di as txt    "     {stata suso doctor:suso doctor}        {txt}// check Stata + Java + settings"
    di as txt    "     Tip: set the SUSO_PASSWORD environment variable and omit password()."

    di as res _n "  2) SEE DATA  (replaces the data in memory; preserve first if needed)"
    di as txt    "     suso questionnaire list                 {txt}// find the GUID + Version"
    di as txt    "     suso assignment list , all"
    di as txt    "     suso interview list , status(Completed) all"
    di as txt    "     suso interview list , status(RejectedBySupervisor) all"
    di as txt    "     suso interview list , all                {txt}// uses your saved questionnaire"
    di as txt    "     suso interview stats   , id(<interview-uuid>)"
    di as txt    "     suso interview get     , id(<interview-uuid>)   {txt}// loads the answers"
    di as txt    "     suso interview history , id(<interview-uuid>)"

    di as res _n "  3) REVIEW  (approve / reject / comment)"
    di as txt    `"     suso interview approve , id(<uuid>) comment("looks good")"'
    di as txt    `"     suso interview reject  , id(<uuid>) comment("please revisit the GPS point")"'
    di as txt    "     suso interview hqapprove , id(<uuid>)"
    di as txt    `"     suso interview hqreject  , id(<uuid>) comment("see notes")"'
    di as txt    `"     suso interview commentbyvar , id(<uuid>) variable(d2_sales) comment("confirm units")"'

    di as res _n "  4) EXPORT + DOWNLOAD  (best way to pull large data)"
    di as txt    "     suso export start , type(STATA) istatus(ApprovedBySupervisor)"
    di as txt    "         {txt}// guid/qver come from your saved questionnaire; add guid()/qver() to override"
    local bq = char(96)
    local eq = char(39)
    di as txt    "     suso export status , id(`bq'=r(jobid)`eq')     {txt}// repeat until status=Completed"
    di as txt    `"     suso export download , id(`bq'=r(jobid)`eq') saving("ises.zip") replace"'
    di as txt    `"     suso export get , type(STATA) saving("ises.zip") unzipw("pw") unzipto("data") replace   {txt}// all of the above in one"'

    di as res _n "  5) PARADATA  (timing + behaviour QC: speeding, night work, churn)"
    di as txt    "     suso paradata get                        {txt}// export -> download -> load events"
    di as txt    `"     suso paradata load , file("para.zip")    {txt}// or reload a saved export offline"'
    di as txt    "     suso paradata flags                      {txt}// red-flag report; data = 1 row/interview"
    di as txt    "     suso paradata timing , by(question)      {txt}// slowest questions first"
    di as txt    "     suso paradata skips                      {txt}// historical removal runs + final-state review"
    di as txt    `"     suso paradata report , saving("qc.html") replace {txt}// one-page HTML QC report"'

    di as res _n "  6) TEAM"
    di as txt    "     suso supervisor list , all"
    di as txt    "     suso supervisor interviewers , id(<supervisor-uuid>)"
    di as txt    "     suso interviewer actionslog , id(<interviewer-uuid>) start(2026-06-01) end(2026-06-17)"
    di as txt    "     suso assignment assign , id(<assignment-id>) responsible(<interviewer-login>)"

    di as res _n "  7) DANGER  (need confirmation; written to the audit log)"
    di as txt    "     suso interview delete , id(<uuid>) confirm"
    di as txt    "     suso export cancel    , id(<jobid>) confirm"
    di as txt    "     suso workspace status , name(<ws>)"
    di as txt    "     suso workspace delete , name(<ws>) iknowthis(<ws>)"

    di as txt _n "  More: {stata suso endpoints:suso endpoints}   (full command list)   |   {help suso}"
    di as txt    "{hline 72}" _n
end

*===============================================================================
* endpoints — one-screen list of every command
*===============================================================================
program _suso_endpoints
    di as txt _n "{hline 72}"
    di as res    "  suso — all commands   (questionnaires use  guid()+qver() ; ids use  id())"
    di as txt    "{hline 72}"
    di as res _n "  setup     " as txt "config | ping | doctor | examples | endpoints | about | raw"
    di as res _n "  assignment" as txt " list  get  history  quantitysettings  create  assign"
    di as txt    "             quantity  close  archive  unarchive  audio  targetarea"
    di as res _n "  interview " as txt " list  get  stats  history  pdf  approve  reject"
    di as txt    "             hqapprove  hqreject  hqunapprove  assign  assignsupervisor"
    di as txt    "             comment  commentbyvar  delete"
    di as res _n "  questionnaire" as txt " list  get  document  interviews  audio  criticality"
    di as res _n "  export    " as txt " list  start  status  download  get  cancel"
    di as res _n "  paradata  " as txt " get  load  timing  flags  skips  report  qx  check  suite"
    di as res _n "  maps      " as txt " list  upload  delete  deleteall  assign  unassign"
    di as res _n "  user      " as txt " get  create  archive  unarchive"
    di as res    "  supervisor" as txt " list  get  interviewers"
    di as res    "  interviewer" as txt " get  actionslog"
    di as res _n "  workspace " as txt " list  get  status  create  update  enable  disable  delete  assign"
    di as res _n "  settings  " as txt " globalnotice get|set|clear"
    di as res    "  statistics" as txt " questionnaires  questions  report"
    di as res _n "  backup    " as txt " full-workspace archive (questionnaires + exports + assignments/users)"
    di as txt _n "  Recipes you can copy: {stata suso examples:suso examples}     Help: {help suso}"
    di as txt    "{hline 72}" _n
end


*===============================================================================
* Mata: questionnaire HTML parser (used by suso paradata qx / skips qx() / report qx())
*===============================================================================
version 14.2
mata:

string scalar _suso_qx_clean(string scalar t0)
{
    string scalar t
    t = ustrregexra(t0, "<[^>]*>", " ")
    t = subinstr(t, "&quot;", char(34))
    t = subinstr(t, "&#39;", "'")
    t = subinstr(t, "&#xD;", " ")
    t = subinstr(t, "&#xA;", " ")
    t = subinstr(t, "&nbsp;", " ")
    t = subinstr(t, "&lt;", "<")
    t = subinstr(t, "&gt;", ">")
    t = subinstr(t, "&amp;", "&")
    t = subinstr(t, char(10), " ")
    t = subinstr(t, char(9), " ")
    return(strtrim(stritrim(t)))
}

string colvector _suso_qx_split(string scalar s, string scalar sep)
{
    string colvector out
    string scalar rest
    real scalar j, L
    out = J(0,1,"")
    rest = s
    L = strlen(sep)
    while ((j = strpos(rest, sep)) > 0) {
        out = out \ substr(rest, 1, j-1)
        rest = substr(rest, j+L, .)
    }
    out = out \ rest
    return(out)
}

string scalar _suso_qx_lastsec(string scalar t)
{
    string scalar pat, out, rest
    pat = `"(?s)<h2[^>]*id="[0-9a-f]{32}">(.*?)</h2>"'
    out = ""
    rest = t
    while (ustrregexm(rest, pat)) {
        out = _suso_qx_clean(ustrregexs(1))
        rest = ustrregexrf(rest, pat, "")
    }
    return(out)
}

string scalar _suso_qx_resolve(string scalar t, string colvector anum, string colvector atxt)
{
    real scalar i
    string scalar num
    if (ustrregexm(strtrim(t), "^\[([0-9]+)\]$")) {
        num = ustrregexs(1)
        for (i=1; i<=rows(anum); i++) {
            if (anum[i]==num) return(atxt[i])
        }
    }
    return(t)
}

void _suso_qx_parse(string scalar fn)
{
    real scalar fh, n, k, p, nvv, nq, nopt
    string scalar s, tail, ch, cursec, v, ti, ty, en, ms, op, omap, rest, pat
    string colvector Cvar, Csec, Cty, Cti, Cen, Cms, Cop, Cov, Comap, chunks, anum, atxt, ovals, olabs
    real colvector Cnv, Cno

    fh = fopen(fn, "r")
    fseek(fh, 0, 1)
    n = ftell(fh)
    fseek(fh, 0, -1)
    s = fread(fh, n)
    fclose(fh)
    s = subinstr(s, char(13), "")

    anum = J(0,1,""); atxt = J(0,1,"")
    n = strpos(s, `"<span class="number">["')
    if (n > 0) {
        tail = substr(s, n, .)
        pat = `"(?s)<span class="number">\[([0-9]+)\]</span>\s*<div class="appendix_detail">(.*?)</div>"'
        while (ustrregexm(tail, pat)) {
            anum = anum \ ustrregexs(1)
            atxt = atxt \ substr(_suso_qx_clean(ustrregexs(2)), 1, 500)
            tail = ustrregexrf(tail, pat, "")
        }
    }

    Cvar = Csec = Cty = Cti = Cen = Cms = Cop = Cov = Comap = J(0,1,"")
    Cnv = Cno = J(0,1,.)
    chunks = _suso_qx_split(s, `"<div class="question-container">"')
    cursec = _suso_qx_lastsec(chunks[1])
    for (k=2; k<=rows(chunks); k++) {
        ch = chunks[k]
        v = ""
        if (ustrregexm(ch, `"(?s)class="variable_name">\s*(.*?)\s*</div>"')) v = strtrim(ustrregexs(1))
        if (v != "") {
            ti = ""
            if (ustrregexm(ch, `"(?s)class="question-title"[^>]*>(.*?)</div>"')) ti = substr(_suso_qx_clean(ustrregexs(1)), 1, 800)
            ty = ""
            if (ustrregexm(ch, `"(?s)class="type">\s*(.*?)\s*</div>"')) ty = substr(_suso_qx_clean(ustrregexs(1)), 1, 60)
            en = ""
            if (ustrregexm(ch, `"(?s)class="condition"><span>E</span>(.*?)</div>"')) en = substr(_suso_qx_resolve(_suso_qx_clean(ustrregexs(1)), anum, atxt), 1, 800)
            nvv = 0
            rest = ch
            while (strpos(rest, `"class="validation-expression""') > 0) {
                nvv = nvv + 1
                rest = subinstr(rest, `"class="validation-expression""', "", 1)
            }
            ms = ""
            if (ustrregexm(ch, `"(?s)class="validation-message"><span>M[0-9]+</span>(.*?)</div>"')) ms = substr(_suso_qx_clean(ustrregexs(1)), 1, 500)
            ovals = J(0,1,""); olabs = J(0,1,"")
            rest = ch
            pat = `"(?s)class="option-value"><span ?>(.*?)</span>"'
            while (rows(ovals)<60 & ustrregexm(rest, pat)) {
                ovals = ovals \ _suso_qx_clean(ustrregexs(1))
                rest = ustrregexrf(rest, pat, "")
            }
            nopt = rows(ovals)
            while (strpos(rest, `"class="option-value""') > 0) {
                nopt = nopt + 1
                rest = subinstr(rest, `"class="option-value""', "", 1)
            }
            rest = ch
            pat = `"(?s)<label[^>]*>(.*?)</label>"'
            while (rows(olabs)<60 & ustrregexm(rest, pat)) {
                olabs = olabs \ _suso_qx_clean(ustrregexs(1))
                rest = ustrregexrf(rest, pat, "")
            }
            op = ""
            omap = ""
            for (p=1; p<=min((rows(ovals), rows(olabs), 60)); p++) {
                if (p<=8) op = op + (p>1 ? " | " : "") + ovals[p] + " " + olabs[p]
                omap = omap + (p>1 ? char(29) : "") + ovals[p] + char(30) + olabs[p]
            }
            Cvar = Cvar \ substr(v,1,80)
            Csec = Csec \ substr(cursec,1,200)
            Cty  = Cty  \ ty
            Cti  = Cti  \ ti
            Cen  = Cen  \ en
            Cms  = Cms  \ ms
            Cop  = Cop  \ substr(op,1,800)
            Cov  = Cov  \ substr(invtokens(ovals'), 1, 800)
            Comap = Comap \ omap
            Cno  = Cno  \ nopt
            Cnv  = Cnv  \ nvv
        }
        rest = _suso_qx_lastsec(ch)
        if (rest != "") cursec = rest
    }

    nq = rows(Cvar)
    if (nq == 0) return
    st_addobs(nq)
    (void) st_addvar("str80",  "qx_var")
    (void) st_addvar("str200", "qx_section")
    (void) st_addvar("str60",  "qx_type")
    (void) st_addvar("strL",   "qx_text")
    (void) st_addvar("strL",   "qx_enable")
    (void) st_addvar("int",    "qx_nval")
    (void) st_addvar("strL",   "qx_valmsg")
    (void) st_addvar("strL",   "qx_opts")
    (void) st_addvar("strL",   "qx_optvals")
    (void) st_addvar("strL",   "qx_optmap")
    (void) st_addvar("int",    "qx_nopts")
    st_sstore(., "qx_var", Cvar)
    st_sstore(., "qx_section", Csec)
    st_sstore(., "qx_type", Cty)
    st_sstore(., "qx_text", Cti)
    st_sstore(., "qx_enable", Cen)
    st_sstore(., "qx_valmsg", Cms)
    st_sstore(., "qx_opts", Cop)
    st_sstore(., "qx_optvals", Cov)
    st_sstore(., "qx_optmap", Comap)
    st_store(., "qx_nopts", Cno)
    st_store(., "qx_nval", Cnv)
}

string scalar _suso_qx_code_norm(string scalar s0)
{
    string scalar s
    real scalar x
    s = strtrim(s0)
    if (ustrregexm(s, "^[+-]?[0-9]+([.][0-9]+)?$")) {
        x = strtoreal(s)
        if (x < .) return(strtrim(strofreal(x, "%21.0g")))
    }
    return(s)
}

string scalar _suso_qx_optlabel(string scalar omap, string scalar val)
{
    string colvector pairs, one
    string scalar target
    real scalar i
    if (omap=="" | val=="") return("")
    target = _suso_qx_code_norm(val)
    pairs = _suso_qx_split(omap, char(29))
    for (i=1; i<=rows(pairs); i++) {
        one = _suso_qx_split(pairs[i], char(30))
        if (rows(one)>=2) {
            if (_suso_qx_code_norm(one[1])==target) return(one[2])
        }
    }
    return("")
}

void _suso_qx_apply_labels(string scalar oldv, string scalar newv,
    string scalar mapv, string scalar oldout, string scalar newout)
{
    real scalar i, n
    string colvector ov, nv, mp, ol, nl
    n = st_nobs()
    if (n==0) return
    ov = st_sdata(., oldv)
    nv = st_sdata(., newv)
    mp = st_sdata(., mapv)
    ol = nl = J(n,1,"")
    for (i=1; i<=n; i++) {
        ol[i] = _suso_qx_optlabel(mp[i], ov[i])
        nl[i] = _suso_qx_optlabel(mp[i], nv[i])
    }
    st_sstore(., oldout, ol)
    st_sstore(., newout, nl)
}

string scalar _suso_suite_read(string scalar fn)
{
    real scalar fh, n
    string scalar s
    fh = _fopen(fn, "r")
    if (fh < 0) return("")
    fseek(fh, 0, 1)
    n = ftell(fh)
    fseek(fh, 0, -1)
    s = fread(fh, n)
    fclose(fh)
    return(s)
}

string scalar _suso_suite_esc(string scalar s0)
{
    string scalar s
    s = subinstr(s0, "&", "&amp;")
    s = subinstr(s, char(34), "&quot;")
    return(s)
}

void _suso_suite_pane(real scalar fh, real scalar k, string scalar src, string scalar note)
{
    string scalar disp
    disp = (k==1 ? "block" : "none")
    fwrite(fh, `"<div class="pane" id="p"' + strofreal(k) + `"" style="display:"' + disp + `"">"')
    if (src != "") {
        fwrite(fh, `"<iframe srcdoc=""')
        fwrite(fh, _suso_suite_esc(_suso_suite_read(src)))
        fwrite(fh, `""></iframe>"')
    }
    else fwrite(fh, `"<div class="empty">"' + note + `"</div>"')
    fwrite(fh, "</div>" + char(10))
}

void _suso_suite_write(string scalar fout, string scalar title, string scalar sub,
    string scalar f1, string scalar f2, string scalar f3,
    string scalar note2, string scalar note3)
{
    real scalar fh
    fh = fopen(fout, "w")
    fwrite(fh, `"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>"' + title + "</title><style>" + char(10))
    fwrite(fh, "html,body{margin:0;height:100%;font-family:Segoe UI,Arial,sans-serif;background:#f4f5f7;color:#1a1a1a}" + char(10))
    fwrite(fh, ".logobar{background:#fff;padding:9px 24px;border-bottom:1px solid #e0e0e0}" + char(10))
    fwrite(fh, ".logobar .wbtxt{font-size:12.5px;letter-spacing:.06em;color:#002244;font-weight:600}.logobar .wbtxt span{color:#8a8a8a;font-weight:400}" + char(10))
    fwrite(fh, ".mast{background:#002244;color:#fff;padding:12px 24px 0}" + char(10))
    fwrite(fh, ".mast h1{margin:0;font-size:19px;font-weight:600}.mast .sub{color:#c9d4e0;font-size:11.5px;margin:3px 0 9px}" + char(10))
    fwrite(fh, ".tabs{display:flex;gap:4px}" + char(10))
    fwrite(fh, ".tb{background:#0a3560;color:#c9d4e0;border:0;border-radius:7px 7px 0 0;padding:8px 18px;font-size:13px;cursor:pointer}" + char(10))
    fwrite(fh, ".tb.on{background:#f4f5f7;color:#002244;font-weight:700}" + char(10))
    fwrite(fh, ".tb .tbadge{display:none;font-weight:700;font-size:11px;padding:0 6px;border-radius:8px;margin-left:7px;font-variant-numeric:tabular-nums}" + char(10))
    fwrite(fh, ".tb .tbadge.on{display:inline-block}" + char(10))
    fwrite(fh, ".tb .tbadge.b{background:#fbeaea;color:#8a1f1f}.tb .tbadge.w{background:#fdf6e3;color:#7a5b00}.tb .tbadge.g{background:#eaf5ec;color:#1e6b34}" + char(10))
    fwrite(fh, ".digest{color:#c9d4e0;font-size:12px;padding:6px 0 10px;min-height:15px}" + char(10))
    fwrite(fh, ".pane iframe{display:block;width:100%;height:calc(100vh - 118px);border:0;background:#f4f5f7}" + char(10))
    fwrite(fh, ".empty{padding:40px;color:#666;font-size:14px;max-width:640px}" + char(10))
    fwrite(fh, "</style></head><body>" + char(10))
    fwrite(fh, `"<div class="logobar"><!-- wbLogo slot: replace content with the base64 banner img -->"' + char(10))
    fwrite(fh, `"<span class="wbtxt">THE WORLD BANK <span>| Development Economics - Policy Indicators</span> &nbsp;-&nbsp; ENTERPRISE SURVEYS <span>- What Businesses Experience</span></span></div>"' + char(10))
    fwrite(fh, `"<div class="mast"><h1>"' + title + "</h1>" + `"<div class="sub">"' + sub + "</div>" + char(10))
    fwrite(fh, `"<div class="tabs"><button class="tb on" id="b1">Behaviour<span class="tbadge" id="tbad1"></span></button><button class="tb" id="b2">Skips &amp; removals<span class="tbadge" id="tbad2"></span></button><button class="tb" id="b3">Data QC<span class="tbadge" id="tbad3"></span></button></div>"' + char(10))
    fwrite(fh, `"<div class="digest" id="sdigest"></div></div>"' + char(10))
    _suso_suite_pane(fh, 1, f1, "")
    _suso_suite_pane(fh, 2, f2, note2)
    _suso_suite_pane(fh, 3, f3, note3)
    fwrite(fh, "<script>" + char(10))
    fwrite(fh, "function sh(k){var i;for(i=1;i<=3;i++){document.getElementById('p'+i).style.display=(i===k)?'block':'none';document.getElementById('b'+i).className=(i===k)?'tb on':'tb';}if(k<=2)sendFilters(document.querySelector('#p'+k+' iframe'));}" + char(10))
    fwrite(fh, "var actorFilter=null,statusFilter=null;function sendFilters(f){if(!f||!f.contentWindow)return;if(actorFilter)f.contentWindow.postMessage(actorFilter,'*');if(statusFilter)f.contentWindow.postMessage(statusFilter,'*');}" + char(10))
    fwrite(fh, "var tabBadge=[null,null,null,null];function fmtBadge(n){return n.toLocaleString();}function digestText(){var p=[],b;b=tabBadge[1];if(b)p.push(b.n>0?(fmtBadge(b.n)+' interview'+(b.n===1?'':'s')+' need'+(b.n===1?'s':'')+' attention'):'behaviour clear');b=tabBadge[2];if(b)p.push(b.n>0?(fmtBadge(b.n)+' removal check'+(b.n===1?'':'s')+' open'):'removals resolved');b=tabBadge[3];if(b)p.push(b.n>0?('Data QC: '+fmtBadge(b.n)+' hard problem'+(b.n===1?'':'s')):'Data QC clean');return p.join(' - ');}function applyBadge(i,d){tabBadge[i]={n:d.n,sev:d.sev};var s=document.getElementById('tbad'+i);if(s){s.textContent=d.n>0?fmtBadge(d.n):'\u2713';s.className='tbadge on '+(d.n>0?d.sev:'g');}var g=document.getElementById('sdigest');if(g)g.textContent=digestText();}" + char(10))
    fwrite(fh, "window.addEventListener('message',function(e){var d=e.data||{},fs,i,tab=0;if(d.type!=='suso-tab-badge')return;fs=document.querySelectorAll('#p1 iframe,#p2 iframe,#p3 iframe');for(i=0;i<fs.length;i++)if(fs[i].contentWindow===e.source){tab=parseInt(fs[i].parentNode.id.substring(1),10);break;}if(!tab)return;if(typeof d.n!=='number'||!isFinite(d.n)||d.n<0||d.n>9999999)return;if(d.sev!=='b'&&d.sev!=='w'&&d.sev!=='g')return;applyBadge(tab,{n:Math.round(d.n),sev:d.sev});});" + char(10))
    fwrite(fh, "window.addEventListener('message',function(e){var d=e.data||{},fs,i,src=false,ok=false;fs=document.querySelectorAll('#p1 iframe,#p2 iframe');for(i=0;i<fs.length;i++)if(fs[i].contentWindow===e.source){src=true;break;}if(!src)return;if(d.type==='suso-actor-filter'&&typeof d.key==='string'&&typeof d.label==='string'&&d.key.length<=500&&d.label.length<=500){actorFilter={type:d.type,key:d.key,label:d.label};ok=true;}if(d.type==='suso-status-filter'&&typeof d.key==='string'&&d.key.length<=500){statusFilter={type:d.type,key:d.key};ok=true;}if(!ok)return;for(i=0;i<fs.length;i++)if(fs[i].contentWindow!==e.source)sendFilters(fs[i]);});" + char(10))
    fwrite(fh, "(function(){var fs=document.querySelectorAll('#p1 iframe,#p2 iframe'),i;for(i=0;i<fs.length;i++)fs[i].addEventListener('load',function(){sendFilters(this);});})();" + char(10))
    fwrite(fh, "document.getElementById('b1').addEventListener('click',function(){sh(1);});" + char(10))
    fwrite(fh, "document.getElementById('b2').addEventListener('click',function(){sh(2);});" + char(10))
    fwrite(fh, "document.getElementById('b3').addEventListener('click',function(){sh(3);});" + char(10))
    fwrite(fh, "</script></body></html>" + char(10))
    fclose(fh)
}

end
