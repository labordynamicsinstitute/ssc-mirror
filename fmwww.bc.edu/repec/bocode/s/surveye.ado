*! version 2.2.0 27jul2026

program define surveye, rclass
    version 16.0

    if `"`0'"' == "" {
        display as error "surveye requires a questionnaire HTML file"
        display as error "Try {stata help surveye:help surveye}."
        exit 198
    }

    gettoken subcmd rest : 0
    local subcmd = lower(`"`subcmd'"')

    if `"`subcmd'"' == "describe" {
        _surveye_describe `rest'
        return add
        exit
    }

    if `"`subcmd'"' == "demo" {
        _surveye_demo `rest'
        return add
        exit
    }

    if `"`subcmd'"' == "build" {
        _surveye_main `rest'
        return add
        exit
    }

    _surveye_main `0'
    return add
end


program define _surveye_main, rclass
    version 16.0

    syntax [varlist(default=none max=120000)] [if] [in] using/ ///
        [aweight fweight iweight pweight], ///
        SAVing(string)                                               ///
        [ REPLACE OPEN                                               ///
          TITle(string) SUBTitle(string) BYLine(string)              ///
          QUESTions(string asis)                                    ///
          SECTions(numlist integer >0) SECTIONMatch(string)          ///
          EXclude(string asis) FILters(varlist) HIGHlights(varlist) ///
          KEYMessages(string) CUSTOMSections(string)                 ///
          CUSTOMVars(varlist) ADDToSections(string)                  ///
          VARGroups(string) NOAUTOGroups UNGROUPVars(varlist)        ///
          DISCrete(varlist) CONTinuous(varlist) NOAUTODISCrete      ///
          COMPARE(varlist) COMPAREBy(varname)                        ///
          COMPARETitle(string) COMPARELevels(string)                 ///
          USDVars(varlist) USDRate(numlist min=1 max=1)              ///
          CURRENCY(string)                                          ///
          TABLEBy(varname) TABLEVars(varlist)                        ///
          TABLESTats(string asis) TABLELAbels(string asis)          ///
          TABLETItle(string) TABLESUbtitle(string)                   ///
          TABLETOtal(string) TABLEWeightLabel(string)                ///
          BARs(varlist) DONUTs(varlist) HISTograms(varlist)          ///
          MAXCategories(integer 12) MAXPanels(integer 100)          ///
          MISSingcodes(numlist missingokay)                         ///
          LATitude(varname numeric) LONGitude(varname numeric)       ///
          COUNTRY(string) BOUNDaries(string)                         ///
          MAPLevel(string) MAPTYpe(string) BASEMap(string) MAPBY(varname) ///
          MAPTItle(string) LOGO(string) THEME(string) DENSity(string) ///
          BACKGround(string) TYPOGraphy(string) CORNers(string)      ///
          SHADow(string) MOTion(string) PAGEWidth(integer 0)         ///
          UILANGuage(string) DIRection(string)                       ///
          NOTE(string) SOURCE(string) DISCLAIMer(string)             ///
          CI LEVel(numlist min=1 max=1) STRICT DIAGNostics(string) SHOWEmpty ]

    // ---------- Files and mutually dependent options ----------
    capture confirm file `"`using'"'
    if _rc {
        display as error "surveye: questionnaire file not found"
        display as error `"  `using'"'
        exit 601
    }

    if strtrim(`"`saving'"') == "" {
        display as error "surveye: saving() requires a filename"
        exit 198
    }

    if !regexm(lower(`"`saving'"'), "[.]html?$") {
        local saving `"`saving'.html"'
    }

    if `"`replace'"' == "" {
        capture confirm new file `"`saving'"'
        if _rc {
            display as error `"surveye: output file already exists: `saving'"'
            display as error "Specify {bf:replace} or choose another saving() filename."
            exit 602
        }
    }

    if `"`boundaries'"' != "" {
        capture confirm file `"`boundaries'"'
        if _rc {
            display as error `"surveye: boundaries file not found: `boundaries'"'
            exit 601
        }
    }

    if `"`logo'"' != "" {
        capture confirm file `"`logo'"'
        if _rc {
            display as error `"surveye: logo file not found: `logo'"'
            exit 601
        }
    }

    local qkey = ustrlower(strtrim(`"`using'"'))
    local outkey = ustrlower(strtrim(`"`saving'"'))
    local diagkey = ustrlower(strtrim(`"`diagnostics'"'))
    if `"`outkey'"' == `"`qkey'"' {
        display as error "surveye: saving() may not overwrite the questionnaire"
        exit 198
    }
    if `"`diagkey'"' != "" & inlist(`"`diagkey'"', `"`qkey'"', `"`outkey'"') {
        display as error "surveye: diagnostics() must differ from the questionnaire and saving()"
        exit 198
    }
    if `"`boundaries'"' != "" & `"`diagkey'"' == ustrlower(strtrim(`"`boundaries'"')) {
        display as error "surveye: diagnostics() may not overwrite boundaries()"
        exit 198
    }
    if `"`logo'"' != "" & `"`diagkey'"' == ustrlower(strtrim(`"`logo'"')) {
        display as error "surveye: diagnostics() may not overwrite logo()"
        exit 198
    }

    if `"`diagnostics'"' != "" & `"`replace'"' == "" {
        capture confirm new file `"`diagnostics'"'
        if _rc {
            display as error `"surveye: diagnostics file already exists: `diagnostics'"'
            display as error "Specify {bf:replace} or choose another diagnostics() filename."
            exit 602
        }
    }

    if `"`sections'"' != "" & `"`sectionmatch'"' != "" {
        display as error "surveye: sections() and sectionmatch() may not be combined"
        exit 198
    }

    if `"`customsections'"' != "" & `"`addtosections'"' != "" {
        display as error "surveye: customsections() and addtosections() may not be combined"
        exit 198
    }

    if (`"`latitude'"' == "") != (`"`longitude'"' == "") {
        display as error "surveye: latitude() and longitude() must be specified together"
        exit 198
    }

    local maprequested = (`"`latitude'"' != "")
    if !`maprequested' & ///
        (`"`country'`boundaries'`maplevel'`maptype'`basemap'`mapby'`maptitle'"' != "") {
        display as error "surveye: map options require latitude() and longitude()"
        exit 198
    }

    if `maprequested' & strtrim(`"`country'"') == "" {
        display as error "surveye: country() is required for a GPS map"
        display as error "Specify a country name, ISO-2 code, or ISO-3 code; for example, country(Kenya)."
        exit 198
    }

    if `maprequested' & `"`maptype'"' == "" local maptype "points"

    if `maprequested' & `"`basemap'"' == "" local basemap "google_hybrid"

    if `"`maptype'"' != "" & !inlist(lower(`"`maptype'"'), "cluster", "heat", "points") {
        display as error "surveye: maptype() must be cluster, heat, or points"
        exit 198
    }

    if `"`basemap'"' != "" & !inlist(lower(`"`basemap'"'), ///
        "google_hybrid", "google_sat", "google_road", "osm") {
        display as error "surveye: basemap() must be google_hybrid, google_sat, google_road, or osm"
        exit 198
    }

    if `"`maplevel'"' != "" & !inlist(lower(`"`maplevel'"'), "country", "admin2") {
        display as error "surveye: maplevel() must be country or admin2"
        exit 198
    }

    if `maxcategories' < 2 | `maxcategories' > 200 {
        display as error "surveye: maxcategories() must be between 2 and 200"
        exit 198
    }

    if `maxpanels' < 0 | `maxpanels' > 5000 {
        display as error "surveye: maxpanels() must be between 0 and 5,000"
        exit 198
    }

    if `"`level'"' != "" & `"`ci'"' == "" {
        display as error "surveye: level() requires ci"
        exit 198
    }

    if `"`level'"' == "" local level 95

    if missing(`level') | `level' <= 50 | `level' >= 100 {
        display as error "surveye: level() must be greater than 50 and less than 100"
        exit 198
    }

    local appearance_theme = lower(strtrim(`"`theme'"'))
    if `"`appearance_theme'"' == "" local appearance_theme "editorial"
    local engine_theme `"`appearance_theme'"'
    if `"`appearance_theme'"' == "editorial" local engine_theme "worldbank"

    if !inlist(`"`appearance_theme'"', "editorial", "worldbank", "clean", "forest", "dark") {
        display as error "surveye: theme() must be editorial, worldbank, clean, forest, or dark"
        exit 198
    }

    local background = lower(strtrim(`"`background'"'))
    local typography = lower(strtrim(`"`typography'"'))
    local corners = lower(strtrim(`"`corners'"'))
    local shadow = lower(strtrim(`"`shadow'"'))
    local motion = lower(strtrim(`"`motion'"'))
    if `"`background'"' == "" {
        if `"`appearance_theme'"' == "editorial" local background "glow"
        else local background "auto"
    }
    if `"`typography'"' == "" {
        if `"`appearance_theme'"' == "editorial" local typography "editorial"
        else local typography "auto"
    }
    if `"`corners'"' == "" {
        if `"`appearance_theme'"' == "editorial" local corners "rounded"
        else local corners "auto"
    }
    if `"`shadow'"' == "" {
        if `"`appearance_theme'"' == "editorial" local shadow "soft"
        else local shadow "auto"
    }
    if `"`motion'"' == "" {
        if `"`appearance_theme'"' == "editorial" local motion "subtle"
        else local motion "none"
    }
    if `pagewidth' == 0 & `"`appearance_theme'"' == "editorial" local pagewidth 1280

    if !inlist(`"`background'"', "auto", "glow", "paper", "plain") {
        display as error "surveye: background() must be auto, glow, paper, or plain"
        exit 198
    }
    if !inlist(`"`typography'"', "auto", "editorial", "modern", "system") {
        display as error "surveye: typography() must be auto, editorial, modern, or system"
        exit 198
    }
    if !inlist(`"`corners'"', "auto", "rounded", "soft", "square") {
        display as error "surveye: corners() must be auto, rounded, soft, or square"
        exit 198
    }
    if !inlist(`"`shadow'"', "auto", "soft", "lifted", "none") {
        display as error "surveye: shadow() must be auto, soft, lifted, or none"
        exit 198
    }
    if !inlist(`"`motion'"', "none", "subtle", "reveal") {
        display as error "surveye: motion() must be none, subtle, or reveal"
        exit 198
    }
    if `pagewidth' != 0 & (`pagewidth' < 960 | `pagewidth' > 2000) {
        display as error "surveye: pagewidth() must be 0 or between 960 and 2,000 pixels"
        exit 198
    }

    if `"`density'"' != "" & !inlist(lower(`"`density'"'), "compact", "comfortable") {
        display as error "surveye: density() must be compact or comfortable"
        exit 198
    }

    if `"`uilanguage'"' != "" {
        local uilanguage = lower(strtrim(`"`uilanguage'"'))
        if `"`uilanguage'"' == "en" local uilanguage "english"
        if `"`uilanguage'"' == "ar" local uilanguage "arabic"
        if `"`uilanguage'"' == "ur" local uilanguage "urdu"
        if !inlist(`"`uilanguage'"', "auto", "english", "arabic", "urdu") {
            display as error "surveye: uilanguage() must be auto, english, arabic, or urdu"
            exit 198
        }
    }

    if `"`direction'"' != "" {
        local direction = lower(strtrim(`"`direction'"'))
        if !inlist(`"`direction'"', "auto", "ltr", "rtl") {
            display as error "surveye: direction() must be auto, ltr, or rtl"
            exit 198
        }
    }

    local nhighlights : word count `highlights'
    if `nhighlights' > 6 {
        display as error "surveye: highlights() accepts at most six variables"
        exit 198
    }

    // questions() names questionnaire questions rather than Stata columns.
    // This matters for multiselects exported only as question__code columns.
    local questionlist = subinstr(`"`questions'"', char(34), "", .)
    local questionlist = subinstr(strtrim(`"`questionlist'"'), ",", " ", .)
    local questionlist : list retokenize questionlist
    if strtrim(`"`questions'"') != "" & `"`questionlist'"' == "" {
        display as error "surveye: questions() requires at least one question name"
        exit 198
    }
    foreach question of local questionlist {
        capture confirm names `question'
        if _rc {
            display as error `"surveye: invalid Survey Solutions question name in questions(): `question'"'
            display as error "Question names may contain letters, numbers, and underscores and may not use wildcards."
            exit 198
        }
    }

    // exclude() accepts ordinary Stata varlists and logical questionnaire
    // names.  The latter is needed when a multiselect exists only as q__#
    // expansion columns and no Stata variable named q exists.
    local excluderaw = subinstr(`"`exclude'"', char(34), "", .)
    local excluderaw = subinstr(strtrim(`"`excluderaw'"'), ",", " ", .)
    local excluderaw : list retokenize excluderaw
    local excludelist ""
    foreach item of local excluderaw {
        local expanded ""
        capture unab expanded : `item'
        if !_rc local excludelist `"`excludelist' `expanded'"'
        else {
            capture confirm names `item'
            if _rc {
                display as error `"surveye: invalid name or varlist element in exclude(): `item'"'
                exit 198
            }
            local excludelist `"`excludelist' `item'"'
        }
    }
    local exclude : list uniq excludelist

    local selectedvars `"`varlist' `questionlist'"'
    local selectedvars : list uniq selectedvars

    // Related questionnaire items are grouped automatically by the engine.
    // Manual groups use the deliberately simple Title:: varlist grammar.  Do
    // the Stata varlist expansion here so ranges and wildcards have their
    // usual Stata meaning and Java receives an unambiguous member list.
    local normalizedgroups ""
    local groupedvars ""
    local grouprest `"`macval(vargroups)'"'
    while strtrim(`"`macval(grouprest)'"') != "" {
        local pipe = strpos(`"`macval(grouprest)'"', "|")
        if `pipe' > 0 {
            local onegroup = strtrim(substr(`"`macval(grouprest)'"', 1, `pipe' - 1))
            local grouprest = substr(`"`macval(grouprest)'"', `pipe' + 1, .)
        }
        else {
            local onegroup = strtrim(`"`macval(grouprest)'"')
            local grouprest ""
        }

        local divider = strpos(`"`macval(onegroup)'"', "::")
        if `divider' <= 1 {
            display as error "surveye: vargroups() groups must use Title:: varlist"
            display as error `"Invalid group: `macval(onegroup)'"'
            exit 198
        }
        local grouptitle = strtrim(substr(`"`macval(onegroup)'"', 1, `divider' - 1))
        local groupmembersraw = strtrim(substr(`"`macval(onegroup)'"', `divider' + 2, .))
        if `"`macval(grouptitle)'"' == "" | `"`macval(groupmembersraw)'"' == "" {
            display as error "surveye: every vargroups() group requires a title and at least two variables"
            exit 198
        }

        local expandedmembers ""
        capture unab expandedmembers : `groupmembersraw'
        if _rc {
            display as error `"surveye: invalid or unavailable varlist in vargroups(): `macval(groupmembersraw)'"'
            exit 198
        }
        local ngroupmembers : word count `expandedmembers'
        if `ngroupmembers' < 2 {
            display as error `"surveye: group `macval(grouptitle)' requires at least two variables"'
            exit 198
        }
        local duplicate : list groupedvars & expandedmembers
        if `"`duplicate'"' != "" {
            display as error `"surveye: a variable may appear in only one vargroups() group: `duplicate'"'
            exit 198
        }
        local groupedvars `"`groupedvars' `expandedmembers'"'
        local groupedvars : list uniq groupedvars
        if `"`macval(normalizedgroups)'"' == "" ///
            local normalizedgroups `"`macval(grouptitle)'::`expandedmembers'"'
        else local normalizedgroups `"`macval(normalizedgroups)'|`macval(grouptitle)'::`expandedmembers'"'
    }
    local vargroups `"`macval(normalizedgroups)'"'

    local ungroupvars : list uniq ungroupvars
    local discrete : list uniq discrete
    local continuous : list uniq continuous
    local compare : list uniq compare
    local usdvars : list uniq usdvars
    local tablevars : list uniq tablevars

    local overlap : list groupedvars & ungroupvars
    if `"`overlap'"' != "" {
        display as error `"surveye: variables cannot be both manually grouped and ungrouped: `overlap'"'
        exit 198
    }

    local overlap : list discrete & continuous
    if `"`overlap'"' != "" {
        display as error `"surveye: variables cannot be both discrete and continuous: `overlap'"'
        exit 198
    }

    foreach typeopt in discrete continuous {
        foreach variable of local `typeopt' {
            capture confirm numeric variable `variable'
            if _rc {
                display as error `"surveye: `typeopt'(`variable') requires a numeric variable"'
                exit 109
            }
            local variableformat : format `variable'
            if regexm(lower(strtrim(`"`variableformat'"')), "^%t[bcdwmqhy]") {
                display as error `"surveye: date/time variable `variable' may not be specified in `typeopt'()"'
                exit 198
            }
        }
    }

    local overlap : list discrete & histograms
    if `"`overlap'"' != "" {
        display as error `"surveye: discrete() and histograms() give conflicting instructions for: `overlap'"'
        exit 198
    }
    local overlap : list continuous & bars
    if `"`overlap'"' == "" local overlap : list continuous & donuts
    if `"`overlap'"' != "" {
        display as error `"surveye: continuous() conflicts with a categorical chart override for: `overlap'"'
        exit 198
    }

    local ncompare : word count `compare'
    if `ncompare' > 12 {
        display as error "surveye: compare() accepts at most 12 variables"
        exit 198
    }
    if `"`compare'"' != "" & `"`compareby'"' == "" {
        display as error "surveye: compare() requires compareby()"
        exit 198
    }
    if `"`compare'"' == "" & ///
        (`"`compareby'"' != "" | `"`comparetitle'"' != "" | `"`comparelevels'"' != "") {
        display as error "surveye: compareby(), comparetitle(), and comparelevels() require compare()"
        exit 198
    }
    if `"`compare'"' != "" {
        local overlap : list compare & compareby
        if `"`overlap'"' != "" {
            display as error "surveye: compareby() may not also be one of the compare() variables"
            exit 198
        }
    }

    // ---------- Optional weight/USD switches and summary profile table ----------
    // usdrate() is the number of local-currency units in one US dollar.  The
    // dashboard keeps the original values in DATA and converts only at render
    // time, so switching currencies never changes the analysis sample.
    if `"`usdvars'"' != "" & `"`usdrate'"' == "" {
        display as error "surveye: usdvars() requires usdrate()"
        exit 198
    }
    if `"`usdvars'"' == "" & `"`usdrate'"' != "" {
        display as error "surveye: usdrate() requires usdvars()"
        exit 198
    }
    if `"`usdvars'"' == "" & `"`currency'"' != "" {
        display as error "surveye: currency() requires usdvars()"
        exit 198
    }
    if `"`usdrate'"' != "" {
        local usdratevalue : word 1 of `usdrate'
        if missing(real(`"`usdratevalue'"')) | real(`"`usdratevalue'"') <= 0 {
            display as error "surveye: usdrate() must be greater than zero"
            exit 198
        }
    }
    foreach variable of local usdvars {
        capture confirm numeric variable `variable'
        if _rc {
            display as error `"surveye: usdvars(`variable') requires a numeric variable"'
            exit 109
        }
        local variableformat : format `variable'
        if regexm(lower(strtrim(`"`variableformat'"')), "^%t[bcdwmqhy]") {
            display as error `"surveye: date/time variable `variable' may not be specified in usdvars()"'
            exit 198
        }
    }

    local hastable = (`"`tableby'"' != "" | `"`tablevars'"' != "")
    if (`"`tableby'"' == "") != (`"`tablevars'"' == "") {
        display as error "surveye: tableby() and tablevars() must be specified together"
        exit 198
    }
    if !`hastable' & (`"`macval(tablestats)'"' != "" | ///
        `"`macval(tablelabels)'"' != "" | `"`tabletitle'"' != "" | ///
        `"`tablesubtitle'"' != "" | `"`tabletotal'"' != "" | ///
        `"`tableweightlabel'"' != "") {
        display as error "surveye: table options require tableby() and tablevars()"
        exit 198
    }
    if `hastable' {
        local overlap : list tablevars & tableby
        if `"`overlap'"' != "" {
            display as error "surveye: tableby() may not also appear in tablevars()"
            exit 198
        }

        // string asis preserves Stata's syntax quotes.  Remove one matching
        // outer pair before validating the pipe-delimited entries.
        local tablestatsclean = strtrim(`"`macval(tablestats)'"')
        if strlen(`"`macval(tablestatsclean)'"') >= 2 & ///
            substr(`"`macval(tablestatsclean)'"', 1, 1) == char(34) & ///
            substr(`"`macval(tablestatsclean)'"', strlen(`"`macval(tablestatsclean)'"'), 1) == char(34) {
            local tablestatsclean = substr(`"`macval(tablestatsclean)'"', 2, strlen(`"`macval(tablestatsclean)'"') - 2)
        }
        local tablelabelsclean = strtrim(`"`macval(tablelabels)'"')
        if strlen(`"`macval(tablelabelsclean)'"') >= 2 & ///
            substr(`"`macval(tablelabelsclean)'"', 1, 1) == char(34) & ///
            substr(`"`macval(tablelabelsclean)'"', strlen(`"`macval(tablelabelsclean)'"'), 1) == char(34) {
            local tablelabelsclean = substr(`"`macval(tablelabelsclean)'"', 2, strlen(`"`macval(tablelabelsclean)'"') - 2)
        }

        local ntablevars : word count `tablevars'
        local normalizedstats ""
        local statrest `"`macval(tablestatsclean)'"'
        local statcount = 0
        while strtrim(`"`macval(statrest)'"') != "" {
            local pipe = strpos(`"`macval(statrest)'"', "|")
            if `pipe' > 0 {
                local onestat = strtrim(substr(`"`macval(statrest)'"', 1, `pipe' - 1))
                local statrest = substr(`"`macval(statrest)'"', `pipe' + 1, .)
            }
            else {
                local onestat = strtrim(`"`macval(statrest)'"')
                local statrest ""
            }
            if `"`macval(onestat)'"' == "" {
                display as error "surveye: tablestats() may not contain an empty entry"
                exit 198
            }
            local statkey = lower(`"`macval(onestat)'"')
            local validstat = inlist(`"`statkey'"', "auto", "share", "mean", "median", "sum")
            if !`validstat' & regexm(`"`statkey'"', "^share:.+$") local validstat = 1
            if !`validstat' {
                display as error `"surveye: invalid tablestats() entry: `macval(onestat)'"'
                display as error "Use auto, share, share:<code>, mean, median, or sum."
                exit 198
            }
            local ++statcount
            if `statcount' > `ntablevars' {
                display as error "surveye: tablestats() must have one pipe-delimited entry per tablevars() variable"
                exit 198
            }
            local statvariable : word `statcount' of `tablevars'
            if inlist(`"`statkey'"', "mean", "median", "sum") {
                capture confirm numeric variable `statvariable'
                if _rc {
                    display as error `"surveye: tablestats(`macval(onestat)') requires numeric variable `statvariable'"'
                    exit 109
                }
            }
            if `"`macval(normalizedstats)'"' == "" local normalizedstats `"`macval(onestat)'"'
            else local normalizedstats `"`macval(normalizedstats)'|`macval(onestat)'"'
        }
        if `"`macval(tablestatsclean)'"' != "" & `statcount' != `ntablevars' {
            display as error "surveye: tablestats() must have one pipe-delimited entry per tablevars() variable"
            exit 198
        }
        local tablestats `"`macval(normalizedstats)'"'

        local labelrest `"`macval(tablelabelsclean)'"'
        local labelcount = 0
        while strtrim(`"`macval(labelrest)'"') != "" {
            local pipe = strpos(`"`macval(labelrest)'"', "|")
            if `pipe' > 0 {
                local onelabel = strtrim(substr(`"`macval(labelrest)'"', 1, `pipe' - 1))
                local labelrest = substr(`"`macval(labelrest)'"', `pipe' + 1, .)
            }
            else {
                local onelabel = strtrim(`"`macval(labelrest)'"')
                local labelrest ""
            }
            if `"`macval(onelabel)'"' == "" {
                display as error "surveye: tablelabels() may not contain an empty entry"
                exit 198
            }
            local ++labelcount
        }
        if `"`macval(tablelabelsclean)'"' != "" & `labelcount' != `ntablevars' {
            display as error "surveye: tablelabels() must have one pipe-delimited entry per tablevars() variable"
            exit 198
        }
        local tablelabels `"`macval(tablelabelsclean)'"'
    }

    local overlap : list groupedvars & exclude
    if `"`overlap'"' == "" local overlap : list ungroupvars & exclude
    if `"`overlap'"' == "" local overlap : list discrete & exclude
    if `"`overlap'"' == "" local overlap : list continuous & exclude
    if `"`overlap'"' == "" local overlap : list compare & exclude
    if `"`overlap'"' != "" {
        display as error `"surveye: grouping, type, or comparison options cannot use excluded variables: `overlap'"'
        exit 198
    }

    // With a focused selection, presentation options may only refer to a
    // selected questionnaire item or a variable declared in customvars().
    if `"`selectedvars'"' != "" {
        local allowedselected `"`selectedvars' `customvars'"'
        local allowedselected : list uniq allowedselected
        foreach selectionopt in groupedvars ungroupvars discrete continuous compare {
            local notselected : list `selectionopt' - allowedselected
            if `"`notselected'"' != "" {
                local optionname "`selectionopt'()"
                if `"`selectionopt'"' == "groupedvars" local optionname "vargroups()"
                display as error `"surveye: `optionname' contains variable(s) not selected by the main varlist, questions(), or customvars(): `notselected'"'
                exit 198
            }
        }
    }

    local overlap : list customvars & exclude
    if `"`overlap'"' != "" {
        display as error `"surveye: customvars() variables cannot also be excluded: `overlap'"'
        exit 198
    }

    local strictflag = (`"`strict'"' != "")
    local showemptyflag = (`"`showempty'"' != "")
    local replaceflag = (`"`replace'"' != "")
    local showciflag = (`"`ci'"' != "")
    local noautogroupsflag = (`"`noautogroups'"' != "")
    local noautodiscreteflag = (`"`noautodiscrete'"' != "")

    // Explicit chart-type overrides must be unambiguous.
    local overlap : list bars & donuts
    if `"`overlap'"' == "" local overlap : list bars & histograms
    if `"`overlap'"' == "" local overlap : list donuts & histograms
    if `"`overlap'"' != "" {
        display as error `"surveye: chart type specified more than once for: `overlap'"'
        exit 198
    }

    local chartvars `"`bars' `donuts' `histograms'"'
    local chartvars : list uniq chartvars
    local overlap : list chartvars & exclude
    if `"`overlap'"' != "" {
        display as error `"surveye: variables cannot be both charted and excluded: `overlap'"'
        exit 198
    }

    if `"`selectedvars'"' != "" {
        local overlap : list selectedvars & exclude
        if `"`overlap'"' != "" {
            display as error `"surveye: variables cannot be both selected and excluded: `overlap'"'
            exit 198
        }

        local allowedcharts `"`selectedvars' `customvars'"'
        local allowedcharts : list uniq allowedcharts
        foreach chartopt in bars donuts histograms {
            local notselected : list `chartopt' - allowedcharts
            if `"`notselected'"' != "" {
                display as error `"surveye: `chartopt'() contains variable(s) not selected by the main varlist, questions(), or customvars(): `notselected'"'
                exit 198
            }
        }
    }

    // ---------- Analysis sample and weight ----------
    if c(k) == 0 {
        display as error "surveye: the dataset in memory has no variables"
        exit 102
    }

    // marksample creates the temporary marker and stores its name in the
    // caller's local macro.  Pass the macro name, not an expanded tempvar.
    marksample touse, novarlist

    local weightvar ""
    local weighttype ""
    local weighted = 0
    if `"`weight'"' != "" {
        local weighttype `"`weight'"'
        local rawweight = strtrim(subinstr(`"`exp'"', "=", "", 1))

        capture unab weightvar : `rawweight'
        if _rc {
            display as error "surveye: the weight must be a single numeric variable"
            display as error `"  received: `exp'"'
            exit 198
        }
        local nweight : word count `weightvar'
        if `nweight' != 1 {
            display as error "surveye: the weight must be a single numeric variable"
            display as error `"  received: `exp'"'
            exit 198
        }
        capture confirm numeric variable `weightvar'
        if _rc {
            display as error `"surveye: weight variable `weightvar' must be numeric"'
            exit 109
        }

        quietly count if `touse' & `weightvar' < 0
        if r(N) {
            display as error `"surveye: weight variable `weightvar' contains negative values"'
            exit 402
        }

        if `"`weighttype'"' == "fweight" {
            quietly count if `touse' & !missing(`weightvar') & `weightvar' != floor(`weightvar')
            if r(N) {
                display as error `"surveye: fweight variable `weightvar' must contain integers"'
                exit 401
            }
        }

        // Match ordinary Stata command behavior: missing and zero weights do
        // not belong to the analysis sample.  This also keeps zero-weight rows
        // out of raw counts, filters, highlights, and GPS layers.
        quietly replace `touse' = 0 if missing(`weightvar') | `weightvar' == 0

        // Importance weights have no general sampling interpretation.  Keep
        // their descriptive weighted point estimates, but never imply that a
        // Wilson/Kish interval is inferentially meaningful.
        if `"`weighttype'"' == "iweight" & `showciflag' {
            display as text "note: confidence intervals are disabled for iweights"
            local showciflag = 0
        }
        local weighted = 1
    }

    quietly count if `touse'
    local sample_N = r(N)
    if `sample_N' == 0 {
        display as error "surveye: no observations remain after if/in and weight restrictions"
        exit 2000
    }

    // ---------- Export the smallest rectangular data slice needed ----------
    if `"`selectedvars'"' == "" {
        unab exportvars : _all
    }
    else {
        local exportvars `"`varlist'"'

        // Add exact columns and Survey Solutions multiselect expansions for
        // logical names supplied through questions().  The double-underscore
        // form is canonical.  A single underscore is accepted only with an
        // all-numeric suffix, avoiding accidental prefix matches.
        foreach question of local questionlist {
            capture confirm variable `question', exact
            if !_rc local exportvars `"`exportvars' `question'"'

            local doubleexpanded ""
            capture unab doubleexpanded : `question'__*
            if !_rc local exportvars `"`exportvars' `doubleexpanded'"'

            local singlecandidates ""
            capture unab singlecandidates : `question'_*
            if !_rc {
                local prefixbytes = strlen(`"`question'_"')
                foreach candidate of local singlecandidates {
                    local suffix = substr(`"`candidate'"', `prefixbytes' + 1, .)
                    if regexm(`"`suffix'"', "^[0-9]+$") {
                        local exportvars `"`exportvars' `candidate'"'
                    }
                }
            }
        }
    }

    local exportvars `"`exportvars' `customvars' `filters' `highlights' `latitude' `longitude' `mapby' `compare' `compareby' `usdvars' `tableby' `tablevars' `weightvar'"'
    local exportvars : list uniq exportvars

    if `"`exportvars'"' == "" {
        if !`showemptyflag' {
            display as error "surveye: none of the names in questions() matched data columns"
            display as error "For a multiselect question q, expected q or expansion columns such as q__1 and q__2."
            exit 111
        }
    }

    // Keep one nonmissing internal sentinel in the CSV.  Otherwise an
    // observation missing on every selected field becomes a blank CSV record
    // and is indistinguishable from an empty line to a standards-based parser.
    // The sentinel is not part of selectedvars, so it is never charted.
    local exportvars `"`exportvars' `touse'"'
    local exportvars : list uniq exportvars

    tempfile datafile configfile statusfile

    preserve
    quietly keep if `touse'
    quietly keep `exportvars'
    capture noisily export delimited `exportvars' using `"`datafile'"', ///
        replace nolabel quote
    local export_rc = _rc
    restore

    if `export_rc' {
        display as error "surveye: could not create the temporary UTF-8 data export"
        exit `export_rc'
    }

    // Config values are one UTF-8 key<TAB>value record per line.
    tempname cfg
    file open `cfg' using `"`configfile'"', write text replace
    _surveye_cfgline `cfg' mode             `"build"'
    _surveye_cfgline `cfg' questionnaire    `"`macval(using)'"'
    _surveye_cfgline `cfg' data             `"`macval(datafile)'"'
    _surveye_cfgline `cfg' output           `"`macval(saving)'"'
    _surveye_cfgline `cfg' status           `"`macval(statusfile)'"'
    _surveye_cfgline `cfg' variables        `"`macval(selectedvars)'"'
    _surveye_cfgline `cfg' title            `"`macval(title)'"'
    _surveye_cfgline `cfg' subtitle         `"`macval(subtitle)'"'
    _surveye_cfgline `cfg' byline           `"`macval(byline)'"'
    _surveye_cfgline `cfg' sections         `"`macval(sections)'"'
    _surveye_cfgline `cfg' sectionmatch     `"`macval(sectionmatch)'"'
    _surveye_cfgline `cfg' exclude          `"`macval(exclude)'"'
    _surveye_cfgline `cfg' filters          `"`macval(filters)'"'
    _surveye_cfgline `cfg' highlights       `"`macval(highlights)'"'
    _surveye_cfgline `cfg' keymessages      `"`macval(keymessages)'"'
    _surveye_cfgline `cfg' customsections   `"`macval(customsections)'"'
    _surveye_cfgline `cfg' customvars       `"`macval(customvars)'"'
    _surveye_cfgline `cfg' addtosections    `"`macval(addtosections)'"'
    _surveye_cfgline `cfg' vargroups        `"`macval(vargroups)'"'
    _surveye_cfgline `cfg' noautogroups     `"`macval(noautogroupsflag)'"'
    _surveye_cfgline `cfg' ungroupvars      `"`macval(ungroupvars)'"'
    _surveye_cfgline `cfg' discrete         `"`macval(discrete)'"'
    _surveye_cfgline `cfg' continuous       `"`macval(continuous)'"'
    _surveye_cfgline `cfg' noautodiscrete   `"`macval(noautodiscreteflag)'"'
    _surveye_cfgline `cfg' compare          `"`macval(compare)'"'
    _surveye_cfgline `cfg' compareby        `"`macval(compareby)'"'
    _surveye_cfgline `cfg' comparetitle     `"`macval(comparetitle)'"'
    _surveye_cfgline `cfg' comparelevels    `"`macval(comparelevels)'"'
    _surveye_cfgline `cfg' usdvars          `"`macval(usdvars)'"'
    _surveye_cfgline `cfg' usdrate          `"`macval(usdrate)'"'
    _surveye_cfgline `cfg' currency         `"`macval(currency)'"'
    _surveye_cfgline `cfg' tableby          `"`macval(tableby)'"'
    _surveye_cfgline `cfg' tablevars        `"`macval(tablevars)'"'
    _surveye_cfgline `cfg' tablestats       `"`macval(tablestats)'"'
    _surveye_cfgline `cfg' tablelabels      `"`macval(tablelabels)'"'
    _surveye_cfgline `cfg' tabletitle       `"`macval(tabletitle)'"'
    _surveye_cfgline `cfg' tablesubtitle    `"`macval(tablesubtitle)'"'
    _surveye_cfgline `cfg' tabletotal       `"`macval(tabletotal)'"'
    _surveye_cfgline `cfg' tableweightlabel `"`macval(tableweightlabel)'"'
    _surveye_cfgline `cfg' bars             `"`macval(bars)'"'
    _surveye_cfgline `cfg' donuts           `"`macval(donuts)'"'
    _surveye_cfgline `cfg' histograms       `"`macval(histograms)'"'
    _surveye_cfgline `cfg' maxcategories    `"`macval(maxcategories)'"'
    _surveye_cfgline `cfg' maxpanels        `"`macval(maxpanels)'"'
    _surveye_cfgline `cfg' missingcodes     `"`macval(missingcodes)'"'
    _surveye_cfgline `cfg' latitude         `"`macval(latitude)'"'
    _surveye_cfgline `cfg' longitude        `"`macval(longitude)'"'
    _surveye_cfgline `cfg' country          `"`macval(country)'"'
    _surveye_cfgline `cfg' boundaries       `"`macval(boundaries)'"'
    _surveye_cfgline `cfg' maplevel         `"`macval(maplevel)'"'
    _surveye_cfgline `cfg' maptype          `"`macval(maptype)'"'
    _surveye_cfgline `cfg' basemap          `"`macval(basemap)'"'
    _surveye_cfgline `cfg' mapby            `"`macval(mapby)'"'
    _surveye_cfgline `cfg' maptitle         `"`macval(maptitle)'"'
    _surveye_cfgline `cfg' logo             `"`macval(logo)'"'
    _surveye_cfgline `cfg' theme            `"`macval(engine_theme)'"'
    _surveye_cfgline `cfg' density          `"`macval(density)'"'
    _surveye_cfgline `cfg' uilanguage       `"`macval(uilanguage)'"'
    _surveye_cfgline `cfg' direction        `"`macval(direction)'"'
    _surveye_cfgline `cfg' note             `"`macval(note)'"'
    _surveye_cfgline `cfg' source           `"`macval(source)'"'
    if `"`disclaimer'"' != "" ///
        _surveye_cfgline `cfg' disclaimer   `"`macval(disclaimer)'"'
    _surveye_cfgline `cfg' strict           `"`macval(strictflag)'"'
    _surveye_cfgline `cfg' diagnostics      `"`macval(diagnostics)'"'
    _surveye_cfgline `cfg' showempty        `"`macval(showemptyflag)'"'
    _surveye_cfgline `cfg' replace          `"`macval(replaceflag)'"'
    _surveye_cfgline `cfg' weight           `"`macval(weightvar)'"'
    _surveye_cfgline `cfg' weighttype       `"`macval(weighttype)'"'
    _surveye_cfgline `cfg' showci           `"`macval(showciflag)'"'
    _surveye_cfgline `cfg' cilevel          `"`macval(level)'"'
    // Preserve Stata labels/types anywhere a data-only variable can surface,
    // including panels, filters, highlights, and map groups. Questionnaire
    // metadata remains authoritative when the same name is in the HTML.
    // selectedvars may contain a logical multiselect question name that has no
    // physical Stata column, so add only selected names that actually exist.
    // This lets data-only variables selected through questions() retain a
    // meaningful Stata label without breaking expanded multiselects.
    local metadatavars `"`customvars' `filters' `highlights' `mapby' `compareby' `usdvars' `tableby' `tablevars'"'
    foreach metaselected of local selectedvars {
        capture confirm variable `metaselected'
        if !_rc local metadatavars `"`metadatavars' `metaselected'"'
    }
    local metadatavars : list uniq metadatavars
    foreach metavariable of local metadatavars {
        _surveye_custommeta `cfg' `metavariable' `touse' `maxcategories'
    }
    file close `cfg'

    _surveye_invoke `"`configfile'"' `"`statusfile'"' `"`diagnostics'"'

    mata: st_local("outfile", st_global("r(filename)"))
    mata: st_local("outtitle", st_global("r(title)"))
    local outN = r(N)
    local outsections = r(k_sections)
    local outcharts = r(k_charted)
    mata: st_local("outfilters", st_global("r(filters)"))
    local hasmap = r(has_map)
    local mapN = r(map_N)
    local mapmissing = r(map_missing)
    local mapoutside = r(map_outside)
    local outwarnings = r(warnings)
    mata: st_local("outquestionnaire", st_global("r(questionnaire)"))
    local statusoutfile `"`macval(outfile)'"'

    if `"`macval(outfile)'"' == "" {
        local outfile `"`macval(saving)'"'
    }

    _surveye_apply_appearance `"`macval(outfile)'"' `"`macval(appearance_theme)'"' ///
        `"`macval(background)'"' `"`macval(typography)'"' `"`macval(corners)'"' ///
        `"`macval(shadow)'"' `"`macval(motion)'"' `"`pagewidth'"'

    display as text _newline "{hline 72}"
    display as result "OK" as text "  SurvEye dashboard created"
    if `"`macval(outtitle)'"' != "" display as text "    Title           " as result `"`macval(outtitle)'"'
    if !missing(`outN') display as text "    Observations    " as result %12.0fc `outN'
    if !missing(`outsections') display as text "    Sections        " as result %12.0fc `outsections'
    if !missing(`outcharts') display as text "    Indicators      " as result %12.0fc `outcharts'
    if `"`macval(outfilters)'"' != "" display as text "    Filters         " as result `"`macval(outfilters)'"'
    if `hasmap' == 1 & !missing(`mapN') & ///
        !missing(`mapmissing') & !missing(`mapoutside') {
        display as text "    GPS map         " as result %12.0fc `mapN' ///
            as text " valid; " as result %9.0fc `mapmissing' as text " omitted; " ///
            as result %9.0fc `mapoutside' as text " outside"
    }
    if !missing(`outwarnings') & `outwarnings' > 0 {
        display as text "    Flags           " as result %12.0fc `outwarnings' ///
            as text " (details are shown inside the dashboard)"
    }
    display as text "    Saved           " as result `"`macval(outfile)'"'
    display as text `"    {browse "`macval(outfile)'":Open dashboard}"'
    display as text "{hline 72}"

    if `"`open'"' != "" {
        capture noisily view browse `"`macval(outfile)'"'
        if _rc {
            display as text "Flag  The dashboard was created, but Stata could not open the browser."
        }
    }

    // Return results last so browser handling cannot overwrite r().
    _surveye_read_status using `"`statusfile'"'
    return add
    if `"`macval(statusoutfile)'"' == "" {
        return local output `"`macval(saving)'"'
        return local filename `"`macval(saving)'"'
    }
    if `"`macval(outquestionnaire)'"' == "" return local questionnaire `"`macval(using)'"'
    if missing(`outN') return scalar N = `sample_N'
    return scalar sample_N = `sample_N'
    return scalar weighted = `weighted'
    return local package_version "2.2.0"
end


program define _surveye_apply_appearance
    version 16.0
    args output theme background typography corners shadow motion pagewidth

    local jarname "surveye_2_2_0.jar"
    capture findfile `jarname'
    if _rc {
        display as error "`jarname' is not installed on the Stata ado-path"
        display as error "Reinstall the complete package, type {bf:discard}, and restart Stata."
        exit 601
    }

    capture noisily javacall org.worldbank.surveye.AppearancePlugin apply, ///
        jars(`jarname') args(`"`output'"' `"`theme'"' `"`background'"' ///
        `"`typography'"' `"`corners'"' `"`shadow'"' `"`motion'"' `"`pagewidth'"')
    local appearance_rc = _rc
    if `appearance_rc' {
        display as error "surveye: the dashboard was created, but its appearance layer could not be applied"
        display as error "Reinstall the complete package, type {bf:discard}, and restart Stata."
        exit `appearance_rc'
    }
end


program define _surveye_describe, rclass
    version 16.0

    syntax using/ [, DETAIL STRICT DIAGNostics(string) REPLACE]

    capture confirm file `"`using'"'
    if _rc {
        display as error `"surveye: questionnaire file not found: `using'"'
        exit 601
    }

    if `"`diagnostics'"' != "" & ///
        ustrlower(strtrim(`"`diagnostics'"')) == ustrlower(strtrim(`"`using'"')) {
        display as error "surveye: diagnostics() may not overwrite the questionnaire"
        exit 198
    }

    if `"`diagnostics'"' != "" & `"`replace'"' == "" {
        capture confirm new file `"`diagnostics'"'
        if _rc {
            display as error `"surveye: diagnostics file already exists: `diagnostics'"'
            display as error "Specify {bf:replace} or choose another diagnostics() filename."
            exit 602
        }
    }

    tempfile configfile statusfile
    local detailflag = (`"`detail'"' != "")
    local strictflag = (`"`strict'"' != "")
    local replaceflag = (`"`replace'"' != "")
    tempname cfg
    file open `cfg' using `"`configfile'"', write text replace
    _surveye_cfgline `cfg' mode             `"describe"'
    _surveye_cfgline `cfg' questionnaire    `"`macval(using)'"'
    _surveye_cfgline `cfg' status           `"`macval(statusfile)'"'
    _surveye_cfgline `cfg' detail           `"`macval(detailflag)'"'
    _surveye_cfgline `cfg' strict           `"`macval(strictflag)'"'
    _surveye_cfgline `cfg' diagnostics      `"`macval(diagnostics)'"'
    _surveye_cfgline `cfg' replace          `"`macval(replaceflag)'"'
    file close `cfg'

    _surveye_invoke `"`configfile'"' `"`statusfile'"' `"`diagnostics'"'

    mata: st_local("outtitle", st_global("r(title)"))
    local outsections = r(k_sections)
    local outcharts = r(k_charted)
    mata: st_local("chartvars", st_global("r(chartvars)"))
    mata: st_local("sectionlist", st_global("r(sections)"))
    mata: st_local("filtercandidates", st_global("r(filter_candidates)"))
    mata: st_local("gpscandidates", st_global("r(gps_candidates)"))
    mata: st_local("engine", st_global("r(engine_version)"))
    local outwarnings = r(warnings)
    mata: st_local("outquestionnaire", st_global("r(questionnaire)"))
    display as text _newline "{hline 72}"
    display as result "OK" as text "  Questionnaire read successfully"
    if `"`macval(outtitle)'"' != "" display as text "    Title            " as result `"`macval(outtitle)'"'
    if !missing(`outsections') display as text "    Sections         " as result %12.0fc `outsections'
    if !missing(`outcharts') display as text "    Chartable items  " as result %12.0fc `outcharts'
    if `"`macval(engine)'"' != "" display as text "    Engine           " as result `"`macval(engine)'"'
    if !missing(`outwarnings') ///
        display as text "    Warnings         " as result %12.0fc `outwarnings'
    if `"`detail'"' != "" & `"`macval(sectionlist)'"' != "" {
        display as text _newline "Questionnaire sections"
        local sectionrest `"`macval(sectionlist)'"'
        while `"`macval(sectionrest)'"' != "" {
            local pipe = strpos(`"`macval(sectionrest)'"', "|")
            if `pipe' > 0 {
                local onesection = substr(`"`macval(sectionrest)'"', 1, `pipe' - 1)
                local sectionrest = substr(`"`macval(sectionrest)'"', `pipe' + 1, .)
            }
            else {
                local onesection `"`macval(sectionrest)'"'
                local sectionrest ""
            }
            display as text `"    `macval(onesection)'"'
        }
    }
    if `"`detail'"' != "" & `"`macval(chartvars)'"' != "" {
        display as text _newline "Chartable variables"
        display as text `"`macval(chartvars)'"'
    }
    if `"`detail'"' != "" & `"`macval(filtercandidates)'"' != "" {
        display as text _newline "Possible filters"
        display as text `"`macval(filtercandidates)'"'
    }
    if `"`detail'"' != "" & `"`macval(gpscandidates)'"' != "" {
        display as text _newline "Possible GPS variables"
        display as text `"`macval(gpscandidates)'"'
    }
    display as text "{hline 72}"

    _surveye_read_status using `"`statusfile'"'
    return add
    if `"`macval(outquestionnaire)'"' == "" return local questionnaire `"`macval(using)'"'
    return local package_version "2.2.0"
end


program define _surveye_demo, rclass
    version 16.0

    syntax using/, SAVing(string) ///
        [ N(integer 240) SEED(integer 20260714) MAXPanels(integer 100) REPLACE OPEN ///
          TITle(string) SUBTitle(string) BYLine(string) LOGO(string) THEME(string) DENSity(string) ///
          BACKGround(string) TYPOGraphy(string) CORNers(string) ///
          SHADow(string) MOTion(string) PAGEWidth(integer 0) ///
          UILANGuage(string) DIRection(string) ///
          NOTE(string) SOURCE(string) DISCLAIMer(string) ///
          CI LEVel(numlist min=1 max=1) DIAGNostics(string) ]

    capture confirm file `"`using'"'
    if _rc {
        display as error `"surveye: questionnaire file not found: `using'"'
        exit 601
    }
    if strtrim(`"`saving'"') == "" {
        display as error "surveye demo: saving() requires a filename"
        exit 198
    }
    if `n' < 1 {
        display as error "surveye demo: n() must be at least 1"
        exit 198
    }
    if `n' > 100000 {
        display as error "surveye demo: n() may not exceed 100,000"
        exit 198
    }
    if `maxpanels' < 0 | `maxpanels' > 5000 {
        display as error "surveye demo: maxpanels() must be between 0 and 5,000"
        exit 198
    }
    if `"`level'"' != "" & `"`ci'"' == "" {
        display as error "surveye demo: level() requires ci"
        exit 198
    }

    if `"`level'"' == "" local level 95

    if missing(`level') | `level' <= 50 | `level' >= 100 {
        display as error "surveye demo: level() must be greater than 50 and less than 100"
        exit 198
    }

    if !regexm(lower(`"`saving'"'), "[.]html?$") local saving `"`saving'.html"'
    if `"`replace'"' == "" {
        capture confirm new file `"`saving'"'
        if _rc {
            display as error `"surveye: output file already exists: `saving'"'
            display as error "Specify {bf:replace} or choose another saving() filename."
            exit 602
        }
    }

    if `"`logo'"' != "" {
        capture confirm file `"`logo'"'
        if _rc {
            display as error `"surveye: logo file not found: `logo'"'
            exit 601
        }
    }

    local qkey = ustrlower(strtrim(`"`using'"'))
    local outkey = ustrlower(strtrim(`"`saving'"'))
    local diagkey = ustrlower(strtrim(`"`diagnostics'"'))
    if `"`outkey'"' == `"`qkey'"' {
        display as error "surveye: saving() may not overwrite the questionnaire"
        exit 198
    }
    if `"`diagkey'"' != "" & inlist(`"`diagkey'"', `"`qkey'"', `"`outkey'"') {
        display as error "surveye: diagnostics() must differ from the questionnaire and saving()"
        exit 198
    }
    if `"`logo'"' != "" & `"`diagkey'"' == ustrlower(strtrim(`"`logo'"')) {
        display as error "surveye: diagnostics() may not overwrite logo()"
        exit 198
    }

    local appearance_theme = lower(strtrim(`"`theme'"'))
    if `"`appearance_theme'"' == "" local appearance_theme "editorial"
    local engine_theme `"`appearance_theme'"'
    if `"`appearance_theme'"' == "editorial" local engine_theme "worldbank"

    if !inlist(`"`appearance_theme'"', "editorial", "worldbank", "clean", "forest", "dark") {
        display as error "surveye: theme() must be editorial, worldbank, clean, forest, or dark"
        exit 198
    }

    local background = lower(strtrim(`"`background'"'))
    local typography = lower(strtrim(`"`typography'"'))
    local corners = lower(strtrim(`"`corners'"'))
    local shadow = lower(strtrim(`"`shadow'"'))
    local motion = lower(strtrim(`"`motion'"'))
    if `"`background'"' == "" {
        if `"`appearance_theme'"' == "editorial" local background "glow"
        else local background "auto"
    }
    if `"`typography'"' == "" {
        if `"`appearance_theme'"' == "editorial" local typography "editorial"
        else local typography "auto"
    }
    if `"`corners'"' == "" {
        if `"`appearance_theme'"' == "editorial" local corners "rounded"
        else local corners "auto"
    }
    if `"`shadow'"' == "" {
        if `"`appearance_theme'"' == "editorial" local shadow "soft"
        else local shadow "auto"
    }
    if `"`motion'"' == "" {
        if `"`appearance_theme'"' == "editorial" local motion "subtle"
        else local motion "none"
    }
    if `pagewidth' == 0 & `"`appearance_theme'"' == "editorial" local pagewidth 1280

    if !inlist(`"`background'"', "auto", "glow", "paper", "plain") {
        display as error "surveye: background() must be auto, glow, paper, or plain"
        exit 198
    }
    if !inlist(`"`typography'"', "auto", "editorial", "modern", "system") {
        display as error "surveye: typography() must be auto, editorial, modern, or system"
        exit 198
    }
    if !inlist(`"`corners'"', "auto", "rounded", "soft", "square") {
        display as error "surveye: corners() must be auto, rounded, soft, or square"
        exit 198
    }
    if !inlist(`"`shadow'"', "auto", "soft", "lifted", "none") {
        display as error "surveye: shadow() must be auto, soft, lifted, or none"
        exit 198
    }
    if !inlist(`"`motion'"', "none", "subtle", "reveal") {
        display as error "surveye: motion() must be none, subtle, or reveal"
        exit 198
    }
    if `pagewidth' != 0 & (`pagewidth' < 960 | `pagewidth' > 2000) {
        display as error "surveye: pagewidth() must be 0 or between 960 and 2,000 pixels"
        exit 198
    }

    if `"`density'"' != "" & !inlist(lower(`"`density'"'), "compact", "comfortable") {
        display as error "surveye: density() must be compact or comfortable"
        exit 198
    }

    if `"`uilanguage'"' != "" {
        local uilanguage = lower(strtrim(`"`uilanguage'"'))
        if `"`uilanguage'"' == "en" local uilanguage "english"
        if `"`uilanguage'"' == "ar" local uilanguage "arabic"
        if `"`uilanguage'"' == "ur" local uilanguage "urdu"
        if !inlist(`"`uilanguage'"', "auto", "english", "arabic", "urdu") {
            display as error "surveye: uilanguage() must be auto, english, arabic, or urdu"
            exit 198
        }
    }

    if `"`direction'"' != "" {
        local direction = lower(strtrim(`"`direction'"'))
        if !inlist(`"`direction'"', "auto", "ltr", "rtl") {
            display as error "surveye: direction() must be auto, ltr, or rtl"
            exit 198
        }
    }

    if `"`diagnostics'"' != "" & `"`replace'"' == "" {
        capture confirm new file `"`diagnostics'"'
        if _rc {
            display as error `"surveye: diagnostics file already exists: `diagnostics'"'
            display as error "Specify {bf:replace} or choose another diagnostics() filename."
            exit 602
        }
    }

    local replaceflag = (`"`replace'"' != "")
    local showciflag = (`"`ci'"' != "")

    tempfile configfile statusfile
    tempname cfg
    file open `cfg' using `"`configfile'"', write text replace
    _surveye_cfgline `cfg' mode             `"demo"'
    _surveye_cfgline `cfg' questionnaire    `"`macval(using)'"'
    _surveye_cfgline `cfg' output           `"`macval(saving)'"'
    _surveye_cfgline `cfg' status           `"`macval(statusfile)'"'
    _surveye_cfgline `cfg' demon            `"`macval(n)'"'
    _surveye_cfgline `cfg' seed             `"`macval(seed)'"'
    _surveye_cfgline `cfg' maxpanels        `"`macval(maxpanels)'"'
    _surveye_cfgline `cfg' replace          `"`macval(replaceflag)'"'
    _surveye_cfgline `cfg' title            `"`macval(title)'"'
    _surveye_cfgline `cfg' subtitle         `"`macval(subtitle)'"'
    _surveye_cfgline `cfg' byline           `"`macval(byline)'"'
    _surveye_cfgline `cfg' logo             `"`macval(logo)'"'
    _surveye_cfgline `cfg' theme            `"`macval(engine_theme)'"'
    _surveye_cfgline `cfg' density          `"`macval(density)'"'
    _surveye_cfgline `cfg' uilanguage       `"`macval(uilanguage)'"'
    _surveye_cfgline `cfg' direction        `"`macval(direction)'"'
    _surveye_cfgline `cfg' showci           `"`macval(showciflag)'"'
    _surveye_cfgline `cfg' cilevel          `"`macval(level)'"'
    _surveye_cfgline `cfg' note             `"`macval(note)'"'
    _surveye_cfgline `cfg' source           `"`macval(source)'"'
    if `"`disclaimer'"' != "" ///
        _surveye_cfgline `cfg' disclaimer   `"`macval(disclaimer)'"'
    _surveye_cfgline `cfg' diagnostics      `"`macval(diagnostics)'"'
    file close `cfg'

    _surveye_invoke `"`configfile'"' `"`statusfile'"' `"`diagnostics'"'

    mata: st_local("outfile", st_global("r(filename)"))
    mata: st_local("outtitle", st_global("r(title)"))
    local outN = r(N)
    local outwarnings = r(warnings)
    mata: st_local("outquestionnaire", st_global("r(questionnaire)"))
    local statusoutfile `"`macval(outfile)'"'
    if `"`macval(outfile)'"' == "" {
        local outfile `"`macval(saving)'"'
    }

    _surveye_apply_appearance `"`macval(outfile)'"' `"`macval(appearance_theme)'"' ///
        `"`macval(background)'"' `"`macval(typography)'"' `"`macval(corners)'"' ///
        `"`macval(shadow)'"' `"`macval(motion)'"' `"`pagewidth'"'

    display as text _newline "{hline 72}"
    display as result "OK" as text "  Simulated SurvEye dashboard created"
    display as text "    Data             " as result "SIMULATED -- PREVIEW ONLY"
    if `"`macval(outtitle)'"' != "" display as text "    Title            " as result `"`macval(outtitle)'"'
    if !missing(`outN') display as text "    Simulated rows   " as result %12.0fc `outN'
    if !missing(`outwarnings') & `outwarnings' > 0 ///
        display as text "    Flags            " as result %12.0fc `outwarnings'
    display as text "    Saved            " as result `"`macval(outfile)'"'
    display as text `"    {browse "`macval(outfile)'":Open dashboard}"'
    display as text "{hline 72}"

    if `"`open'"' != "" {
        capture noisily view browse `"`macval(outfile)'"'
        if _rc display as text "Flag  Dashboard created, but Stata could not open the browser."
    }

    _surveye_read_status using `"`statusfile'"'
    return add
    if `"`macval(statusoutfile)'"' == "" {
        return local output `"`macval(saving)'"'
        return local filename `"`macval(saving)'"'
    }
    if `"`macval(outquestionnaire)'"' == "" return local questionnaire `"`macval(using)'"'
    return local package_version "2.2.0"
end


program define _surveye_custommeta
    version 16.0
    args handle variable touse maxcategories

    local variablelabel : variable label `variable'
    if strtrim(`"`macval(variablelabel)'"') == "" local variablelabel `"`variable'"'

    local variableformat : format `variable'
    local variableformat = lower(strtrim(`"`variableformat'"'))
    local datatype "numeric"
    capture confirm string variable `variable'
    if !_rc local datatype "single"
    else {
        local valuelabel : value label `variable'
        if regexm(`"`variableformat'"', "^%t[cdwmqhy]") local datatype "date"
        else if `"`valuelabel'"' != "" local datatype "single"
    }

    _surveye_cfgline `handle' datalabel.`variable' `"`macval(variablelabel)'"'
    _surveye_cfgline `handle' datatype.`variable'  `"`datatype'"'
    if `"`datatype'"' == "date" ///
        _surveye_cfgline `handle' dataformat.`variable' `"`variableformat'"'

    // For a categorical numeric custom variable, preserve observed Stata
    // value-label text. Questionnaire categories remain questionnaire-led.
    if `"`datatype'"' == "single" {
        local valuelabel : value label `variable'
        if `"`valuelabel'"' != "" {
            capture quietly levelsof `variable' if `touse' & !missing(`variable'), local(customlevels)
            if !_rc {
                local customlevelcount : word count `customlevels'
                if `customlevelcount' <= `maxcategories' {
                    local valueindex = 0
                    foreach onelevel of local customlevels {
                        local ++valueindex
                        local labeltext ""
                        capture local labeltext : label `valuelabel' `onelevel'
                        if _rc | strtrim(`"`macval(labeltext)'"') == "" {
                            local labeltext `"`onelevel'"'
                        }
                        _surveye_cfgline `handle' datavalue.`variable'.`valueindex' ///
                            `"`onelevel'::`macval(labeltext)'"'
                    }
                }
            }
        }
    }
end


program define _surveye_cfgline
    version 16.0
    args handle key value

    // The config format is line-oriented. Tabs/newlines in user text are folded
    // to spaces so one option can never create a second record.
    local value = subinstr(`"`macval(value)'"', char(9), " ", .)
    local value = subinstr(`"`macval(value)'"', char(10), " ", .)
    local value = subinstr(`"`macval(value)'"', char(13), " ", .)
    file write `handle' `"`key'"' _tab `"`macval(value)'"' _n
end


program define _surveye_invoke, rclass
    version 16.0
    args configfile statusfile diagnostics

    local jarname "surveye_2_2_0.jar"
    capture findfile `jarname'
    if _rc {
        display as error "`jarname' is not installed on the Stata ado-path"
        display as error "Reinstall the complete package; {bf:net get} is not required."
        exit 601
    }
    local jar `"`r(fn)'"'

    // jars() is documented to search the ado-path.  Use the installed JAR's
    // name here (rather than feeding javacall findfile's platform-specific
    // path) so Windows drive letters, mixed separators, and spaces never
    // become part of javacall's JAR-list parsing.  noisily is intentional:
    // the Java entry point is silent during normal Stata use, while Stata can
    // still show a class-loader/JVM diagnostic if invocation fails before the
    // engine has a chance to create its status file.
    capture noisily javacall org.worldbank.surveye.StataPlugin stata, ///
        jars(`jarname') args(`"`configfile'"' `"`statusfile'"')
    local java_rc = _rc

    capture confirm file `"`statusfile'"'
    if _rc {
        display as error "surveye: Stata could not start the installed Java engine"
        if `java_rc' display as error `"javacall returned code `java_rc'; its diagnostic is shown above."'
        display as error `"Installed JAR: `jar'"'
        if `java_rc' == 5100 {
            display as error "The JAR found first on your ado-path is stale or incompatible."
            display as error "In particular, it may not contain the required Stata bridge entry point."
        }
        local hasdiagnostics = 0
        if `"`diagnostics'"' != "" {
            capture confirm file `"`diagnostics'"'
            if !_rc local hasdiagnostics = 1
        }
        if `hasdiagnostics' display as error `"See diagnostics: `diagnostics'"'
        else if `java_rc' {
            display as error "This failure occurred before engine diagnostics could be written."
            display as error "Reinstall the complete package, type {bf:discard}, and try again."
            display as error "If it persists, run {bf:java query} and include that output in the report."
        }
        else display as error "Rerun with diagnostics(filename) for technical details."
        exit 499
    }

    capture noisily _surveye_read_status using `"`statusfile'"'
    local status_rc = _rc
    if `status_rc' {
        if `"`diagnostics'"' != "" {
            capture confirm file `"`diagnostics'"'
            if !_rc display as error `"See diagnostics: `diagnostics'"'
        }
        exit `status_rc'
    }
    return add

    if `java_rc' {
        display as error `"surveye: Java engine returned code `java_rc'"'
        if `"`diagnostics'"' != "" display as error `"See diagnostics: `diagnostics'"'
        exit 499
    }
end


program define _surveye_read_status, rclass
    version 16.0
    syntax using/

    local success ""
    local message ""
    local title ""
    local N ""
    local k_charted ""
    local k_panels ""
    local k_families ""
    local k_comparisons ""
    local k_skipped ""
    local k_sections ""
    local k_filters ""
    local k_questions ""
    local chartvars ""
    local skippedvars ""
    local filters ""
    local sections ""
    local warnings ""
    local weighted ""
    local has_map ""
    local map_N ""
    local map_missing ""
    local map_outside ""
    local engine_version ""
    local output ""
    local questionnaire ""
    local filter_candidates ""
    local gps_candidates ""

    tempname fh
    file open `fh' using `"`using'"', read text
    file read `fh' line
    while r(eof) == 0 {
        local tab = char(9)
        local pos = strpos(`"`macval(line)'"', `"`tab'"')
        if `pos' > 0 {
            local key = lower(strtrim(substr(`"`macval(line)'"', 1, `pos' - 1)))
            local value = substr(`"`macval(line)'"', `pos' + 1, .)

            if `"`key'"' == "success"       local success `"`macval(value)'"'
            else if `"`key'"' == "message"        local message `"`macval(value)'"'
            else if `"`key'"' == "title"          local title `"`macval(value)'"'
            else if `"`key'"' == "n"              local N `"`macval(value)'"'
            else if inlist(`"`key'"', "k_charted", "k_chartable") local k_charted `"`macval(value)'"'
            else if `"`key'"' == "k_panels"       local k_panels `"`macval(value)'"'
            else if `"`key'"' == "k_families"     local k_families `"`macval(value)'"'
            else if `"`key'"' == "k_comparisons"  local k_comparisons `"`macval(value)'"'
            else if `"`key'"' == "k_skipped"      local k_skipped `"`macval(value)'"'
            else if `"`key'"' == "k_sections"     local k_sections `"`macval(value)'"'
            else if `"`key'"' == "k_filters"      local k_filters `"`macval(value)'"'
            else if `"`key'"' == "k_questions"    local k_questions `"`macval(value)'"'
            else if `"`key'"' == "chartvars"      local chartvars `"`macval(value)'"'
            else if `"`key'"' == "skippedvars"    local skippedvars `"`macval(value)'"'
            else if `"`key'"' == "filters"        local filters `"`macval(value)'"'
            else if `"`key'"' == "sections"       local sections `"`macval(value)'"'
            else if `"`key'"' == "warnings"       local warnings `"`macval(value)'"'
            else if `"`key'"' == "weighted"       local weighted `"`macval(value)'"'
            else if `"`key'"' == "has_map"        local has_map `"`macval(value)'"'
            else if `"`key'"' == "map_n"          local map_N `"`macval(value)'"'
            else if `"`key'"' == "map_missing"    local map_missing `"`macval(value)'"'
            else if `"`key'"' == "map_outside"    local map_outside `"`macval(value)'"'
            else if `"`key'"' == "engine_version" local engine_version `"`macval(value)'"'
            else if `"`key'"' == "output"         local output `"`macval(value)'"'
            else if `"`key'"' == "questionnaire"  local questionnaire `"`macval(value)'"'
            else if `"`key'"' == "filter_candidates" local filter_candidates `"`macval(value)'"'
            else if `"`key'"' == "gps_candidates" local gps_candidates `"`macval(value)'"'
        }
        file read `fh' line
    }
    file close `fh'

    local success_l = lower(strtrim(`"`macval(success)'"'))
    if !inlist(`"`success_l'"', "1", "true", "yes") {
        if `"`macval(message)'"' == "" local message "The Java engine reported an unspecified error."
        display as error `"surveye: `macval(message)'"'
        exit 499
    }

    return scalar success = 1
    return local message `"`macval(message)'"'
    return local title `"`macval(title)'"'
    return local chartvars `"`macval(chartvars)'"'
    return local skippedvars `"`macval(skippedvars)'"'
    return local filters `"`macval(filters)'"'
    return local sections `"`macval(sections)'"'
    return local engine_version `"`macval(engine_version)'"'
    return local output `"`macval(output)'"'
    return local filename `"`macval(output)'"'
    return local questionnaire `"`macval(questionnaire)'"'
    return local filter_candidates `"`macval(filter_candidates)'"'
    return local gps_candidates `"`macval(gps_candidates)'"'

    foreach scalar in N k_charted k_panels k_families k_comparisons k_skipped k_sections k_filters k_questions warnings ///
        weighted has_map map_N map_missing map_outside {
        // Resolve the loop-selected local by name, without recursively
        // expanding anything that may be stored in its value.
        local value : copy local `scalar'
        local value = strtrim(`"`macval(value)'"')
        // Many status fields are mode-specific.  For example, describe has
        // k_questions but no N or map counts, while build has N but no
        // k_questions.  Return Stata missing for an absent field without
        // relying on confirm number's handling of a standalone '.'.
        if inlist(`"`macval(value)'"', "", ".") {
            return scalar `scalar' = .
        }
        else {
            capture confirm number `value'
            if _rc {
                display as error `"surveye: malformed numeric value for `scalar' in the Java status file"'
                exit 498
            }
            return scalar `scalar' = real(`"`macval(value)'"')
        }
    }
end
