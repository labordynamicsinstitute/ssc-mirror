
program stmerlin, eclass sortpreserve properties(st)
	version 15.1
	local copy0 `0'
	syntax [anything] [if] [in] , [*]
	if replay() & "`options'"=="" {
		if (`"`e(cmd2)'"'!="stmerlin") error 301
		Replay `copy0'
		exit
	}
	else Estimate `copy0'
	ereturn local cmd2 stmerlin
	ereturn local cmdline2 stmerlin `copy0'
end

program Estimate, eclass
	st_is 2 analysis
	syntax [anything] [if] [in], 	Distribution(string)	///
                                                                ///
                [						///
                        DF(passthru)			        ///
                        KNOTS(passthru)			        ///
                        NOORTHog				///
                                                                ///
                        TVC(varlist)			        ///
                        DFTvc(numlist)			        ///
                        TVCTIME					///
                                                                ///
                        TIME2(string)			        ///
                        TIME3(string)			        ///
                        TIME4(string)			        ///
                        TIME5(string)			        ///
                                                                ///
                        NOCONStant				///
                        BHazard(passthru)		        ///
                                                                ///
                        DEBUG					///
                                                                ///
                        Level(passthru)			        /// -display opts-
                        NOLOG					///
                        SHOWMERLIN				///
                        SHOWINIT				///
                        EFORM                                   ///
                                                                ///
                        FROM(passthru)			        ///
                        CHINTPoints(passthru)                   ///
                        EVALtype(passthru)                      ///
                        NOGEN                                   ///
                        *					/// -mlopts-
                ]						//

	//====================================================================//		
	// error checks and setup
		
        local vars `anything'
        
        local family "`distribution'"
        local l = length("`family'")
        if substr("exponential",1,max(1,`l'))=="`family'" {
                local family exponential	
                if "`evaltype'"=="" {
                        if "`bhazard'"=="" {
                                local evaltype evaltype(gf2)
                        }
                        else {
                                local evaltype evaltype(gf0)
                        }
                }
        }
        else if substr("pwexponential",1,max(3,`l'))=="`family'" {
                local family pwexponential	
                if "`evaltype'"=="" {
                        if "`bhazard'"=="" {
                                local evaltype evaltype(gf2)
                        }
                        else {
                                local evaltype evaltype(gf0)
                        }
                }
        }
        else if substr("weibull",1,max(1,`l'))=="`family'" {
                local family weibull
                if "`evaltype'"=="" {
                        if "`bhazard'"=="" {
                                local evaltype evaltype(gf2)
                        }
                        else {
                                local evaltype evaltype(gf0)
                        }
                }
        }
        else if substr("gompertz",1,max(2,`l'))=="`family'" {
                local family gompertz
                if "`evaltype'"=="" {
                        if "`bhazard'"=="" {
                                local evaltype evaltype(gf2)
                        }
                        else {
                                local evaltype evaltype(gf0)
                        }
                }
        }
        else if substr("ggamma",1,max(2,`l'))=="`family'" {
                local family ggamma
        }
        else if substr("lognormal",1,max(4,`l'))=="`family'" {
                local family lognormal
        }
        else if substr("loglogistic",1,max(4,`l'))=="`family'" {
                local family loglogistic
        }
        else if "rcs"=="`family'" {
                local family loghazard
                if "`evaltype'"=="" {
                        if "`bhazard'"=="" {
                                local evaltype evaltype(gf2)
                        }
                        else {
                                local evaltype evaltype(gf0)
                        }
                }
        }
        else if "addrcs"=="`family'" {
                local family hazard
                if "`evaltype'"=="" {
                        if "`bhazard'"=="" {
                                local evaltype evaltype(gf2)
                        }
                        else {
                                local evaltype evaltype(gf0)
                        }
                }
        }
        else if "rp"=="`family'" {
                local family rp
                if "`evaltype'"=="" {
                        if "`bhazard'"=="" {
                                local evaltype evaltype(gf1)
                        }
                        else {
                                local evaltype evaltype(gf0)
                        }
                }
        }
        else if "`family'"=="cox" {
                local family cox
                if "`bhazard'"!="" {
                        di as error "{bf:bhazard()} not supported with the Cox model"
                        exit 198
                }
                if "`evaltype'"=="" {
                        local evaltype evaltype(gf2)
                }
        }
        else {
                di as error "distribution(`distribution') not supported"
                exit 198
        }
        
        if (strpos("`anything'","[") | strpos("`anything'","]")) {
                di as error "Invalid syntax"
                exit 198
        }
        
        //sample
        marksample touse
        local ifin "if `touse'"
        local origifin `if'
        
        //delayed entry
        qui su _t0 `ifin', meanonly
        if `r(max)'>0 {
                local ltruncated ltruncated(_t0)
                di as text "note; a delayed entry model is being fitted"
        }
        
        //parse mlopts
        mlopts mlopts , `options'

        //main timescale
        local df1 `df'
        local knots1 `knots'
        local tvc1 `tvc'
        local dftvc1 `dftvc'
        local tvctime1 `tvctime'
        local orthog1
        local noorthog1 `noorthog'
        if "`noorthog'"=="" local orthog1 orthog
        
        if "`family'"=="loghazard" | "`family'"=="hazard" {
                if "`noorthog'"=="" local orth orthog
                local rcsbase rcs(_t, `df' `knots' `orth' log event)
                local timevar timevar(_t)
                local df1 
                local knots1 
                local noorthog1 
        }
        
        //final family
        local familydef family(`family', failure(_d) `bhazard' `ltruncated' `df1' `knots1' `noorthog1')
							
	//==================================================================================================================================//
	// build tvcs
		
        //tvcs
        if "`tvc'"!="" {
                
                if "`family'"=="ggamma" | "`family'"=="lognormal" | "`family'"=="loglogistic" {
                        di as error "tvc() not supported with family(ggamma|lognormal|loglogistic)"
                        exit 198
                }
                
                if "`dftvc'"=="" {
                        di as error "dftvc() required"
                        exit 198
                }
                
                if "`tvctime'"=="" {
                        local tvclog log
                }
                
                if "`noorthog'"=="" {
                        local tvcorthog orthog 
                }
                
                local Ntvc1 : word count `tvc'
                local Ntvcdf1 : word count `dftvc'
                if `Ntvcdf1'>1 & `Ntvcdf1'!=`Ntvc1' {
                        di as error "Number of dftvc() elements do not match tvc()"
                        exit 198
                }
                
                if `Ntvcdf1'==1 {
                        foreach var in `tvc1' {
                                local tvcs `tvcs' `var'#rcs(_t, df(`dftvc1') event `tvclog' `tvcorthog')
                        }
                }
                else {
                        local ind = 1
                        foreach var in `tvc1' {
                                local dftvcv1 : word `ind' of `dftvc1'
                                local tvcs `tvcs' `var'#rcs(_t, df(`dftvcv1') event `tvclog' `tvcorthog')
                                local ind = `ind' + 1
                        }
                }
        
                local timevar timevar(_t)
        }
		
	//==================================================================================================================================//
	// additional timescales
		
        forval ts = 2/5 {
        
                if "`time`ts''"!="" {
                        
                        local 0 , `time`ts''
                        syntax ,	[								///
                                                        OFFset(passthru)			///
                                                        MOFFset(passthru)			///
                                                        DF(numlist max=1 int >0)	///
                                                        KNOTS(numlist min=2)		///
                                                        NOORTHog					///
                                                        TIME						///
                                                                                                                ///
                                                        TVC(varlist)				///
                                                        DFTvc(numlist)				///
                                                        TVCTime						///
                                                ]
                        
                        local offset`ts' `offset'
                        local moffset`ts' `moffset'
                        local start`ts' `start'
                        local df`ts' `df'
                        local knots`ts' `knots'
                        local orthog`ts'
                        if "`noorthog'"=="" local orthog`ts' orthog
                        local log`ts'
                        if "`time'"=="" local log`ts' log
                        local tvc`ts' `tvc'
                        local dftvc`ts' `dftvc'
                        local tvctime`ts' log
                        if "`tvctime'"!="" local tvctime`ts' 
                        
                        if "`df'"=="" {
                                local knotsopt`ts' knots(`knots')
                                local Ndf`ts' = `: word count `knots'' - 1 
                                local event`ts' event
                        }
                        else {
                                local knotsopt`ts' df(`df')
                                local Ndf`ts' = `df'
                        }
                        
                        local multitimes `multitimes' rcs(_t, `offset' `moffset' `event`ts'' `knotsopt`ts'' `orthog`ts'' `log`ts'')

                        if "`tvc'"!="" {
                                
                                local Ntvc`ts' : word count `tvc`ts''
                                local Ntvcdf`ts' : word count `dftvc`ts''
                                
                                if `Ntvcdf`ts''>1 & `Ntvcdf`ts''!=`Ntvc`ts'' {
                                        di as error "Number of dftvc() elements do not match tvc()"
                                        exit 198
                                }
                                
                                if `Ntvcdf`ts''==1 {
                                        foreach var in `tvc`ts'' {
                                                local multitimes `multitimes' `var'#rcs(_t, `offset' `moffset' `event`ts'' df(`dftvc') `orthog`ts'' `tvctime`ts'')
                                        }
                                }
                                else {
                                        local ind = 1
                                        foreach var in `tvc`ts'' {
                                                local dftvci : word `ind' of `dftvc'
                                                local multitimes `multitimes' `var'#rcs(_t, `offset' `moffset' `event`ts'' df(`dftvci') `orthog`ts'' `tvctime`ts'')
                                                local ind = `ind' + 1
                                        }
                                }

                        }
                        
                }
                
        }
		
	//==============================================================================================================================================//
	// starting values
        
        local qui quietly
        if "`showinit'"!="" {
                local qui
        }

        if "`family'"=="rp" & "`from'"=="" & !strpos("`anything'","(") {
                
                //fit df1 model first
                local tvctest = 0
                if "`tvc1'"!="" {
                        if `Ntvcdf1'>1 {
                                local test : subinstr local dftvc " " ",", all 
                                local tvctest = max(`test')
                        }
                        else local tvctest = `dftvc'
                }
                
                local 0 , `df1' `knots1'
                syntax , [ DF(numlist int max=1 >0) KNOTS(numlist min=2) ]
                
                if "`df'"=="" {
                        local maindf = `: word count `knots''-1
                }
                else {
                        local maindf = `df'
                }
                
                if `maindf'>1 | `tvctest'>1 {
                
                        di as text "Obtaining initial values"
                
                        local family0 family(`family', failure(_d) `bhazard' `ltruncated' df(1) `noorthog1')
                        
                        if "`tvc'"!="" {
                                foreach var in `tvc' {
                                        local tvcs0 `tvcs0' `var'#rcs(_t, df(1) `tvclog' `tvcorthog')
                                }
                        }
                        
                        forval ts = 2/5 {
        
                                if "`time`ts''"!="" {
                                        
                                        local multitimes0 `multitimes0' rcs(_t, `offset`ts'' `moffset`ts'' `event`ts'' df(1) `orthog`ts'' `log`ts'')
                                        
                                        if "`tvc`ts''"!="" {
                                                foreach var in `tvc`ts'' {
                                                        local multitimes0 `multitimes0' `var'#rcs(_t, `offset`ts'' `moffset`ts'' `event`ts'' df(1) `orthog`ts'' `tvctime`ts'')
                                                }
                                        }
                                }
                                
                        }

                        //fit initial model				
                        `qui' merlin 	(_t	`vars' `tvcs0' `multitimes0' `rcs0' `prigifin',			///
                                `family0' `timevar' `noconstant') if _st==1,			///
                                bors													///
                                nogen													///
                                `debug'													///
                                `level' 												///
                                `nolog'													///
                                `evaltype'												///
                                `mlopts'												///
                                `chintpoints'                                                   ///
                                `eform'
                                
                        tempname init init2
                        mat `init2' = e(b)
                        
                        //now add in some 0s
                        
                        //varlist
                        local ind = 1
                        foreach var in `vars' {
                                mat `init' = (nullmat(`init'),`init2'[1,`ind'])
                                local ind = `ind' + 1
                        }
                        
                        //tvcs
                        if "`tvc'"!="" {
                                if `Ntvcdf1'==1 {
                                        foreach var in `tvc' {
                                                mat `init' = (nullmat(`init'),`init2'[1,`ind'])
                                                local ind = `ind' + 1
                                                if `dftvc'>1 {
                                                        forvalues i=2/`dftvc' {
                                                                mat `init' = (nullmat(`init'),0)	
                                                        }
                                                }
                                        }
                                }
                                else {
                                        local ind2 = 1
                                        foreach var in `tvc' {
                                                local dftvcv : word `ind2' of `dftvc'
                                                mat `init' = (nullmat(`init'),`init2'[1,`ind'])
                                                forvalues i=2/`dftvcv' {
                                                        mat `init' = (nullmat(`init'),0)	
                                                }
                                                local ind = `ind' + 1
                                                local ind2 = `ind2' + 1
                                        }
                                }
                        }				
                        
                        forval ts = 2/5 {
        
                                if "`time`ts''"!="" {
                                        
                                        mat `init' = (nullmat(`init'),`init2'[1,`ind'])
                                        local ind = `ind' + 1
                                        if `Ndf`ts''>1 {
                                                forvalues i=2/`Ndf`ts'' {
                                                        mat `init' = (nullmat(`init'),0)
                                                }
                                        }

                                        if "`tvc`ts''"!="" {
                                                
                                                if `Ntvcdf`ts''==1 {
                                                        mat `init' = (nullmat(`init'),`init2'[1,`ind'])
                                                        local ind = `ind' + 1
                                                        if `dftvc`ts''>1 {
                                                                forvalues i=2/`dftvc`ts'' {
                                                                        mat `init' = (nullmat(`init'),0)
                                                                }
                                                        }
                                                }
                                                else {
                                                        local tvcind = 1
                                                        foreach var in `tvc`ts'' {
                                                                local dftvci : word `tvcind' of `dftvc`ts''
                                                                mat `init' = (nullmat(`init'),`init2'[1,`ind'])
                                                                local ind = `ind' + 1
                                                                if `dftvci'>1 {
                                                                        forvalues i=2/`dftvci' {
                                                                                mat `init' = (nullmat(`init'),0)
                                                                        }
                                                                }
                                                                local tvcind = `tvcind' + 1
                                                        }
                                                }
                                                
                                        }
                                        
                                }
                                
                        }
                        
                        
                        //constant
                        mat `init' = (nullmat(`init'),`init2'[1,`ind'])
                        local ind = `ind' + 1

                        //baseline
                        mat `init' = (nullmat(`init'),`init2'[1,`ind'])
                        local ind = `ind' + 1
                        if `maindf'>1 {
                                forvalues i=2/`maindf' {
                                        mat `init' = (nullmat(`init'),0)	
                                }
                        }

                        local from from(`init')
                }
                
        }
        else if "`family'"=="cox" & "`from'"=="" {
        
                di as text "Obtaining initial values"
        
                local familydef0 family(weibull, failure(_d) `bhazard' `ltruncated')
                
                `qui' merlin (_t `vars' `tvcs' `multitimes' `origifin',	///
                        `familydef0' `timevar' `noconstant') if _st==1,	///
                        bors						///
                        nogen						///
                        `from' 						///
                        `debug'						///
                        `level' 					///
                        `nolog'						///
                        `evaltype'					///
                        `mlopts'					///
                        `chintpoints'                                   ///
                        `eform'
                tempname init init2
                mat `init2' = e(b)
                mat `init'  = `init2'[1,1..`=`e(k)'-2']
                
                local from from(`init')
        }
		
	//==============================================================================================================================================//
	// merlin

        if "`showmerlin'"!="" | "`debug'"!="" {
                n di as text 	"merlin (_t `vars' `tvcs' `multitimes' `rcsbase' `origifin'," 			///
                                                "`familydef' `timevar'), `from' `debug' `level' `nolog' `mlopts'"
        }

        merlin 	(_t `vars' `tvcs' `multitimes' `rcsbase' `origifin',    ///
                `familydef' `timevar' `noconstant') if _st==1,		///
                bors							///
                `nogen'                                                 ///
                `from' 							///
                `debug'							///
                `level' 						///
                `nolog'							///
                `evaltype'						///
                `mlopts'						///
                `chintpoints'                                           ///
                `evaltype'                                              ///
                `eform'                                                 //


end

program Replay
	merlin `0'
end
