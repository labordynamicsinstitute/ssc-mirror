*! mysuite v1.1.2 30Jun2026
*! Authors: Wu Lianghai, Chen Liwen, Wu Hanyan, Wu Xinzhuo, Li Juan
*! Built-in extensible program suite for empirical research
*! 39 modules available from SSC

program define mysuite
    version 18.0

    syntax [, ALL INSTALLed Download]

    * Define SSC module list (39 modules)
    local ssc_online art2tex case2tex mktex sumtex tab2excel corrtex ///
                     corrtex2 regtex reftex getref get2ref conservatism em ///
                     efficiency opacity crash scrash eui qta area ///
                     upoint province_devcat bmc polishpaper cleandisk myedit bf ///
                     fshare thesis_diagram rollbook exam2tex mysuite ///
                     editprofile reduce_aigc myinterval ccgi fm varck

    local ssc_modules art2tex case2tex mktex sumtex tab2excel corrtex ///
                     corrtex2 regtex reg2tex reftex getref get2ref conservatism em ///
                     efficiency opacity crash scrash eui qta area ///
                     upoint province_devcat bmc polishpaper cleandisk myedit bf ///
                     fshare thesis_diagram rollbook exam2tex mysuite ///
                     editprofile reduce_aigc myinterval ccgi fm varck
    *-------------------------------------------------------------------
    * MODE 1: DISPLAY MENU (no options)
    *-------------------------------------------------------------------
    if "`all'" == "" & "`installed'" == "" & "`download'" == "" {
        display as text _n(2)
        display as text "{hline 70}"
        display as text "{bf:mysuite v1.1.2} - Built-in Extensible Program Suite"
        display as text "{hline 70}"
        display as text "Developed by: Wu Lianghai (agd2010@yeah.net)"
        display as text "              Chen Liwen (2184844526@qq.com)"
        display as text "              Wu Hanyan (2325476320@qq.com)"
        display as text "              Wu Xinzhuo (2957833979@qq.com)"
        display as text "              Li Juan (1536496199@qq.com)"
        display as text "Institution: School of Business, Anhui University of Technology (AHUT)"
        display as text "             University of Bristol (UB)"
        display as text "             Red Cross Society of Ma'anshan City"
        display as text "Date: 30 Jun 2026"
        display as text "{hline 70}" _n

        * Display available modules
        display as text "{bf:AVAILABLE MODULES (39 programs from SSC)}" _n

        display as text "{bf:1. Core Components}"
        display as text "  {bf:art2tex}      : Empirical paper framework"
        display as text "  {bf:case2tex}     : Case study framework"
        display as text "  {bf:mktex}        : DOCX to TEX converter"
        display as text "  {bf:fm}           : File classification manager" _n

        display as text "{bf:2. Support Kits}"
        display as text "  {bf:sumtex}       : Descriptive statistics to LaTeX"
        display as text "  {bf:tab2excel}    : Descriptive statistics to Excel"
        display as text "  {bf:corrtex}      : Correlation matrix to LaTeX"
        display as text "  {bf:corrtex2}     : Correlation matrix to LaTeX (alternative)"
        display as text "  {bf:regtex}       : Regression table to LaTeX"
        display as text "  {bf:reg2tex}      : Regression table to LaTeX (alternative)"
        display as text "  {bf:reftex}       : Text to reference conversion"
        display as text "  {bf:getref}       : Retrieve references from DOI"
        display as text "  {bf:get2ref}      : Retrieve references via API"
        display as text "  {bf:conservatism} : Accounting conservatism (Basu/C-Score)"
        display as text "  {bf:em}           : Earnings management (Jones models)"
        display as text "  {bf:efficiency}   : Investment efficiency (Richardson)"
        display as text "  {bf:opacity}      : Information opacity measures"
        display as text "  {bf:crash}        : Stock price crash risk (annual)"
        display as text "  {bf:scrash}       : Stock price crash risk (quarterly)"
        display as text "  {bf:eui}          : Environmental uncertainty"
        display as text "  {bf:qta}          : ESG textual analysis indicators"
        display as text "  {bf:area}         : Regional ordinal variables"
        display as text "  {bf:upoint}       : Inflection point in U-shaped relationship"
        display as text "  {bf:province_devcat} : Regional development classification"
        display as text "  {bf:bmc}          : Chapter configuration file generator"
        display as text "  {bf:polishpaper}  : Academic paper polishing template"
        display as text "  {bf:reduce_aigc}  : AIGC text reduction tool"
        display as text "  {bf:myinterval}   : Confidence interval computation"
        display as text "  {bf:ccgi}         : Corporate governance indicator"
        display as text "  {bf:varck}        : Variable existence check" _n

        display as text "{bf:3. Research & Teaching Management}"
        display as text "  {bf:cleandisk}    : Disk space cleanup"
        display as text "  {bf:myedit}       : ADO file editor"
        display as text "  {bf:bf}           : Folder structure generator"
        display as text "  {bf:fshare}       : Course development folder creator"
        display as text "  {bf:thesis_diagram} : Dissertation framework diagram"
        display as text "  {bf:rollbook}     : Random roll call system"
        display as text "  {bf:exam2tex}     : LaTeX exam template generator"
        display as text "  {bf:mysuite}      : Built-in extensible program suite for empirical research"
        display as text "  {bf:editprofile}  : Stata profile editor" _n


        display as text "{hline 70}"
        display as text "{bf:USAGE INSTRUCTIONS:}" _n
        display as text "  {bf:mysuite}                 : Show this help and module list"
        display as text "  {bf:mysuite, all}            : Install all missing SSC modules"
        display as text "  {bf:mysuite, installed}      : List currently installed modules"
        display as text "  {bf:mysuite, all download}   : Force reinstall all 39 modules"
        display as text "{hline 70}" _n

        * Display installation status
        display as text "{bf:CURRENT INSTALLATION STATUS:}" _n
        local ssc_installed = 0
        foreach mod in `ssc_modules' {
            capture which `mod'
            if _rc == 0 {
                local ++ssc_installed
            }
        }
        display as text "  SSC modules installed: {res:`ssc_installed'}/39"
        exit
    }

    *-------------------------------------------------------------------
    * MODE 2: LIST INSTALLED MODULES
    *-------------------------------------------------------------------
    if "`installed'" != "" {
        display as text _n "{bf:Currently Installed SSC Modules:}" _n
        local ssc_installed = 0
        foreach mod in `ssc_modules' {
            capture which `mod'
            if _rc == 0 {
                display as text "  {bf:`mod'}: {res:Installed}"
                local ++ssc_installed
            }
            else {
                display as text "  {bf:`mod'}: {error:Not installed}"
            }
        }
        display as text _n "{bf:Summary:} {res:`ssc_installed'}/39 SSC modules installed"
        exit
    }

    *-------------------------------------------------------------------
    * MODE 3: INSTALL MISSING MODULES (all)
    *-------------------------------------------------------------------
    if "`all'" != "" & "`download'" == "" {
        display as text _n "{bf:Installing missing SSC modules...}" _n
        local ssc_count = 0
        local already_count = 0
        local fail_count = 0

        foreach mod in `ssc_online' {
            capture which `mod'
            if _rc == 0 {
                display as text "  {bf:`mod'}: {res:Already installed}"
                local ++already_count
            }
            else {
                display as text "  Installing {bf:`mod'}..." _continue
                capture ssc install `mod', replace
                if _rc == 0 {
                    display as result " Done"
                    local ++ssc_count
                }
                else {
                    display as error " Failed"
                    local ++fail_count
                }
            }
        }

        display as text _n "{bf:Installation Summary:}"
        display as text "  Already installed: {res:`already_count'} modules"
        display as text "  Newly installed:   {res:`ssc_count'} modules"
        if `fail_count' > 0 {
            display as error "  Failed to install:  {res:`fail_count'} modules"
        }
        exit
    }

    *-------------------------------------------------------------------
    * MODE 4: FORCE REINSTALL ALL MODULES (all download)
    *-------------------------------------------------------------------
    if "`all'" != "" & "`download'" != "" {
        display as text _n "{bf:Force reinstalling all 39 SSC modules...}" _n
        local ssc_count = 0
        local fail_count = 0

        foreach mod in `ssc_online' {
            display as text "  Reinstalling {bf:`mod'}..." _continue
            capture ssc install `mod', replace
            if _rc == 0 {
                display as result " Done"
                local ++ssc_count
            }
            else {
                display as error " Failed"
                local ++fail_count
            }
        }

        display as text _n "{bf:Reinstallation Summary:}"
        display as text "  Successfully reinstalled: {res:`ssc_count'} modules"
        if `fail_count' > 0 {
            display as error "  Failed to reinstall: {res:`fail_count'} modules"
        }
        display as text _n "Type {bf:help mysuite} for detailed documentation."
        exit
    }

end
