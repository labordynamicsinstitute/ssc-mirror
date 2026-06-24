*! suso v1.6.4  18jun2026  (fix: flattened scalar names capped to Stata 32-char macro limit (was overflowing on e.g. ExistingQuestionnairesCount); workspace status count restored)
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
capture mata: mata drop suso_jsonesc()
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

string scalar suso_jsonesc(string scalar s)
{
    s = subinstr(s, "\", "\\")
    s = subinstr(s, char(34), "\" + char(34))
    s = subinstr(s, char(13), "\r")
    s = subinstr(s, char(10), "\n")
    s = subinstr(s, char(9),  "\t")
    return(s)
}
end

*===============================================================================
* Router
*===============================================================================
program suso, rclass
    version 14.2
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

    if !inlist("`noun'","assignment","interview","questionnaire","export","user","maps") ///
     & !inlist("`noun'","supervisor","interviewer","workspace","settings","statistics") {
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
        SHOW CLEAR ]

    if "`clear'"!="" {
        capture macro drop SUSO_BASE SUSO_WS SUSO_USER SUSO_PWD SUSO_TOKEN          ///
            SUSO_AUTHTYPE SUSO_PROXYHOST SUSO_PROXYPORT SUSO_PROXYUSER SUSO_PROXYPWD ///
            SUSO_INSECURE SUSO_CONNTO SUSO_READTO SUSO_MAXROWS SUSO_AUDIT            ///
            SUSO_GUID SUSO_QVER
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
    if `conntimeout'>0   global SUSO_CONNTO  = `conntimeout'*1000
    if `readtimeout'>0   global SUSO_READTO  = `readtimeout'*1000
    if `maxrows'>0       global SUSO_MAXROWS "`maxrows'"
    if "`auditfile'"!="" global SUSO_AUDIT   "`auditfile'"
    if "`guid'"!=""      global SUSO_GUID    "`guid'"
    if `qver'>0          global SUSO_QVER    "`qver'"

    _suso_init

    if "`insecure'"!="" {
        di as err "suso: WARNING — TLS certificate/hostname verification is DISABLED for this session."
        di as err "      Use this only as a last resort behind the corporate proxy. Prefer importing"
        di as err "      the WBG root CA into your Stata JVM trust store (see the README)."
    }

    if "`show'"!="" | trim("`server'`workspace'`user'`password'`token'`auth'`jar'`proxyhost'")=="" {
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
    di as txt "  jar         : " as res cond("$SUSO_JAR"=="","(auto-locate on adopath)","$SUSO_JAR")
    if "$SUSO_PROXYHOST"!="" di as txt "  proxy       : " as res "$SUSO_PROXYHOST:$SUSO_PROXYPORT"
    di as txt "  TLS verify  : " as res cond("$SUSO_INSECURE"=="1","DISABLED (insecure)","on")
    di as txt "  timeouts ms : " as res "connect=$SUSO_CONNTO  read=$SUSO_READTO"
    di as txt "  max rows    : " as res "$SUSO_MAXROWS"
    local af "$SUSO_AUDIT"
    if "`af'"=="" local af "`c(sysdir_personal)'suso_audit.log"
    di as txt "  audit log   : " as res `"`af'"'
    di as txt "{hline 62}"
end

program _suso_about
    di as txt _n "{hline 66}"
    di as txt "  suso  v1.6.4  —  Survey Solutions REST API client for Stata"
    di as txt "{hline 66}"
    di as txt "  Author       : Attique Ur Rehman, Economist, The World Bank"
    di as txt "                 Development Economics (DEC) · Enterprise Surveys"
    di as txt "  Email        : attique@worldbank.org"
    di as txt "  Web          : https://sites.google.com/view/attique-ur-rehman"
    di as txt "{hline 66}"
    di as txt "  Java backend : suso.jar (requires a Java 11+ runtime)"
    di as txt "  Help         : {help suso}        Diagnostics: {stata suso doctor:suso doctor}"
    di as txt "{hline 66}"
end

*===============================================================================
* Diagnostics
*===============================================================================
program _suso_doctor
    version 14.2
    di as txt _n "{hline 62}"
    di as txt "suso doctor — environment check"
    di as txt "{hline 62}"
    di as txt "Stata"
    di as txt "  version       : " as res "`c(flavor)' `c(stata_version)'"
    di as txt "  sysdir PLUS   : " as res "`c(sysdir_plus)'"
    di as txt "  sysdir PERSON : " as res "`c(sysdir_personal)'"

    di as txt "Java backend"
    capture _suso_jar
    if _rc {
        di as err "  suso.jar      : NOT FOUND — put it on the adopath or set -suso config , jar(...)-"
    }
    else {
        di as txt "  suso.jar      : " as res "$SUSO_JAR"
        capture noisily javacall org.worldbank.suso.Stata jvm , classpath("$SUSO_JAR")
        if _rc {
            di as err "  javacall      : FAILED (rc=`=_rc') — is Java available to Stata? See {help java}."
        }
        else if "$SUSO_JAVAOK"=="1" {
            di as txt "  Java 11+      : " as res "yes  ($SUSO_JAVAVER)"
        }
        else {
            di as err "  Java 11+      : NO ($SUSO_JAVAVER) — PATCH operations require Java 11 or newer."
        }
    }
    _suso_showconfig
    capture macro drop SUSO_JAVAVER SUSO_JAVAOK
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
    if "`todata'"!="" clear
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
        if length("SUSO_F_`k'") <= 32 local F_`k' `"${SUSO_F_`k'}"'
    }
    capture macro drop SUSO_GQL_BODY SUSO_GQL_OPERATIONS SUSO_GQL_MAP SUSO_UP_FILE ///
        SUSO_UP_NAME SUSO_GQL_NODEPATH SUSO_GQL_TODATA SUSO_VERBOSE
    if `jrc' {
        di as err "suso: the Java call failed (Stata rc=`jrc'). See:  suso doctor"
        exit `jrc'
    }
    if "`rc'"=="" {
        di as err "suso: no response from the Java backend."
        exit 459
    }
    if "`rc'"!="0" {
        _suso_transport_err `"`macval(msg)'"'
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
    * Start one export, poll to completion (showing progress as it changes), then
    * download it (optionally unzip). Errors (exit 459) on failure/timeout so callers
    * can wrap in capture. A Completed job with no data file returns r(status)=="NoFile"
    * (not an error). Mirrors the backup notebook's start/wait/download chain.
    syntax , TYPE(string) SAVING(string) [ GUID(string) QVER(integer 0)          ///
        ISTATUS(string) META NOMETA POLLSecs(integer 10) JOBTimeout(integer 3600) ///
        replace UNZIP UNZIPW(string) UNZIPto(string) VERBOSE ]
    if "`istatus'"=="" local istatus "All"
    local metaopt = cond("`nometa'"!="","nometa","meta")
    suso export start , type(`type') guid(`guid') qver(`qver') istatus(`istatus') `metaopt' `verbose'
    local jid `"`r(jobid)'"'
    if `"`jid'"'=="" {
        di as err "suso: export start returned no JobId."
        exit 459
    }
    local elapsed  = 0
    local status   ""
    local hasfile  "true"
    local lastline ""
    while 1 {
        quietly suso export status , id(`jid') `verbose'
        local status  `"`r(exportstatus)'"'
        local hasfile `"`r(hasexportfile)'"'
        local pct     `"`r(progress)'"'
        if "`status'"=="Completed" local pct "100"
        * print a progress line only when it changes (auto-suppressed under capture)
        if "`status' `pct'"!="`lastline'" {
            di as txt "  export " as res "`jid'" as txt "  {col 50}" as res "`status'" as txt "  " as res "`pct'%"
            local lastline "`status' `pct'"
        }
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
    capture suso export download , id(`jid') saving(`"`saving'"') `replace' `unzip' unzipw(`"`unzipw'"') unzipto(`"`unzipto'"') `verbose'
    if _rc {
        * the /file endpoint can 403/404 for a beat right after Completed: retry once
        sleep 2000
        suso export download , id(`jid') saving(`"`saving'"') `replace' `unzip' unzipw(`"`unzipw'"') unzipto(`"`unzipto'"') `verbose'
    }
    return add
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
            if length(`"`tag'"') > 60 local tag = substr(`"`tag'"',1,60)
            local stub "`tag'_v`ver'"

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

program _suso_transport_err
    * Display a backend transport error and, if it is a TLS/certificate trust
    * failure, explain how to fix it on ANY server (not just the WBG network).
    local msg `"`macval(0)'"'
    * drop the legacy WBG-specific hint the backend may append
    local msg = subinstr(`"`macval(msg)'"', `"  (TLS/proxy issue on the WBG network? See 'suso doctor' and the SSL notes in the README.)"', "", .)
    di as err `"suso: `macval(msg)'"'
    local low = lower(`"`macval(msg)'"')
    if strpos(`"`low'"',"sslhandshake") | strpos(`"`low'"',"pkix") | strpos(`"`low'"',"certification path") | strpos(`"`low'"',"certpath") | strpos(`"`low'"',"unable to find valid cert") {
        di as txt ""
        di as txt "  Stata's Java runtime does not trust this server's TLS certificate. This is"
        di as txt "  common for non-World-Bank servers, self-signed certificates, or an outdated"
        di as txt "  Java trust store. Fix it in one of these ways:"
        di as txt "    1) {bf:Trust the certificate (recommended).}  Run {bf:suso doctor} to find the"
        di as txt "       Java home, then import the server's root CA into that JVM with keytool"
        di as txt "       (see the SSL / proxy notes in {bf:help suso} or the README)."
        di as txt "    2) {bf:Skip TLS verification for this session (quick, less secure).}"
        di as txt "         {bf:. suso config , insecure}"
        di as txt "       then re-run your command. Use only against a server you trust."
    }
end

program _suso_jar
    if "$SUSO_JAR"=="" {
        * 1) anywhere on the adopath
        capture findfile suso.jar
        if !_rc global SUSO_JAR "`r(fn)'"
    }
    if "$SUSO_JAR"=="" {
        * 2) right next to suso.ado
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

    if "`todata'"!="" clear

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
        if length("SUSO_F_`k'") <= 32 local F_`k' `"${SUSO_F_`k'}"'
    }

    if `jrc' {
        _suso_clearbridge
        di as err "suso: the Java call failed (Stata rc=`jrc')."
        di as err "      Check suso.jar and that Stata runs Java 11+ :  suso doctor"
        exit `jrc'
    }
    if "`rc'"=="" {
        _suso_clearbridge
        di as err "suso: no response from the Java backend (it may not have executed)."
        exit 459
    }
    if "`rc'"!="0" {
        _suso_clearbridge
        _suso_transport_err `"`macval(msg)'"'
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
        quietly gen double `t' = clock(subinstr(substr(`v',1,19),"T"," ",1), "YMDhms")
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
    else                local pos = cond(`page'>=0, `page', 1)

    local maxrows = real("$SUSO_MAXROWS")
    if `maxrows'<=0 local maxrows 100000

    tempfile acc
    local got 0
    local total .
    local first 1

    while (1) {
        local q "`baseq'"
        if "`q'"!="" local q "`q'&"
        local q "`q'`pageparam'=`pos'&`sizeparam'=`size'"

        _suso_call , method(GET) path(`path') query(`q') todata arraykey(`arraykey') `rootopt' `vopt'
        local n = r(nobs)
        if "`n'"=="" local n 0
        if !missing(r(totalcount)) local total = r(totalcount)

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
                di as txt "suso: stopping pagination (column types differ across pages); returning rows so far."
                quietly save `"`acc'"', replace
                continue, break
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
        BODY(string) ROOT ALLOWdestructive VERBOSE ]
    if "`method'"=="" local method GET
    if `"`body'"'!="" global SUSO_BODY_REQ `"`body'"'
    local allowopt = cond("`allowdestructive'"!="","allow","")
    local destopt  = cond("`allowdestructive'"!="","destructive","")
    local rootopt  = cond("`root'"!="","root","")
    local vopt     = cond("`verbose'"!="","verbose","")
    local todopt   = cond("`todata'"!="","todata","")
    _suso_call , method(`method') path(`path') query(`query') ct(`ctype') acc(`accept') ///
        `todopt' arraykey(`arraykey') savefile(`savefile') `rootopt' `destopt' `allowopt' `vopt'
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
        if "`on'"=="" & "`off'"=="" {
            di as err "suso: specify -on- or -off-."
            exit 198
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
            _suso_jsonesc `"`rnm'"' ; global SUSO_BODY_REQ `"{"ResponsibleName":"`r(js)'"}"'
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
            _suso_unzip , file(`"`zsaved'"') dir(`"`unzipto'"') pwd(`"`unzipw'"')
            return local unzipdir `"`r(unzipdir)'"'
            return scalar unzipped = r(nfiles)
            return scalar http = `zhttp'
        }
        exit
    }

    if "`verb'"=="get" {
        * One-shot: start -> poll (live progress) -> auto-download when 100%.
        syntax , TYPE(string) SAVING(string) [ GUID(string) QVER(integer 0)      ///
            ISTATUS(string) META NOMETA POLLSecs(integer 10) JOBTimeout(integer 3600) ///
            replace UNZIP UNZIPW(string) UNZIPto(string) VERBOSE ]
        if "`replace'"=="" {
            capture confirm new file `"`saving'"'
            if _rc {
                di as err "suso: file already exists. Use -replace-."
                exit 602
            }
        }
        _suso_export_get , type(`type') saving(`"`saving'"') guid(`guid') qver(`qver') ///
            istatus(`istatus') `meta' `nometa' pollsecs(`pollsecs')                 ///
            jobtimeout(`jobtimeout') `replace' `unzip' unzipw(`"`unzipw'"')          ///
            unzipto(`"`unzipto'"') `verbose'
        if "`r(status)'"=="NoFile" {
            di as txt "suso: export completed but has no data file for this filter — nothing downloaded."
        }
        return add
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
        local _enq `"`r(existingquestionnairescou)'"'
        if `"`_enq'"'=="" local _enq `"`r(existingquestionnairescount)'"'
        di as txt "  questionnaires    : " as res `"`_enq'"'
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
        syntax [, VERBOSE]
        _suso_call , method(DELETE) path(/api/v1/settings/globalnotice) `verbose'
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

    di as res _n "  5) TEAM"
    di as txt    "     suso supervisor list , all"
    di as txt    "     suso supervisor interviewers , id(<supervisor-uuid>)"
    di as txt    "     suso interviewer actionslog , id(<interviewer-uuid>) start(2026-06-01) end(2026-06-17)"
    di as txt    "     suso assignment assign , id(<assignment-id>) responsible(<interviewer-login>)"

    di as res _n "  6) DANGER  (need confirmation; written to the audit log)"
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
