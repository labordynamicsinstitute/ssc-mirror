*! 1.4.0 NJC 4 Nov 2023 
*! 1.3.0 NJC 29 Mar 2023 
*! 1.2.0 NJC 10 Dec 2022 
*! 1.1.0 TJM 6 Dec 2022
*! 1.0.0 NJC 30 Nov 2022
* note: tab stop = 4 spaces
program upsetplot 
    version 8.2 
    syntax varlist(numeric) ///
    [if] [in]               /// 
    [fweight aweight/]      /// 
    [,                      ///
    fillin                  ///
    percent                 ///
    pcformat(str)           ///  
    frformat(str)           /// 
    varlabels               ///
    varlabs                 /// undocumented
    variablelabels          /// undocumented 
    SEParator(str)          ///
    gsort(str)              /// 
    axisgap(str)            ///
    vargap(str)             /// 
    baropts(str asis)       /// 
    labelopts(str asis)     /// 
    spikeopts(str asis)     /// 
    matrixopts(str asis)    /// 
    select(numlist)         /// 
    savedata(str asis) *] 
    
    /// syntax check 
    if "`variablelabels'" != "" | "`varlabs'" != "" local varlabels "varlabels" 

    local sep "`separator'" 

    quietly { 
        /// data to use and dataset preparation 
        marksample touse 
        
        foreach v of local varlist {
            count if `touse' & !inlist(`v', 0, 1)
            if r(N) > 0 { 
                noisily bad_data `v'            
                exit 450 
            }
        }
                        
        count if `touse'
        if r(N) == 0 error 2000
        
        preserve 

        keep if `touse'
        local nvars = wordcount("`varlist'")
        egen _binary = concat(`varlist')
        decimal `varlist'

        if "`exp'" == "" local exp 1 
        bysort _binary : gen double _freq = sum(`exp')  
        bysort _binary : keep if _n == _N 
        compress _freq 
        keep `varlist' _freq _decimal _binary   

        unab varlist : `varlist' 
        tokenize "`varlist'" 

        /// want to show possible subsets that did not occur
        if "`fillin'" != "" { 
            levelsof _decimal, local(present) 
            
            local ntuples = 2^`nvars' - 1 
            numlist "0/`ntuples'" 
            local complete `r(numlist)' 
            local absent : list complete - present 

            if "`absent'" != "" {
                local n = wordcount("`absent'") 
                set obs `= _N + `n'' 

                foreach x of local absent { 
                    replace _decimal = `x' in -`n' 
                    inbase 2 `x'
                    replace _binary = string(`r(base)', "%0`nvars'.0f") in -`n'

                    forval j = 1/`nvars' { 
                        replace ``j'' = real(substr(_binary, `j', 1)) in -`n'
                    } 
                    
                    local --n 
                } 

                replace _freq = 0 if missing(_freq)
            }  
        } 

        if "`percent'" != "" { 
            su _freq, meanonly 
            gen _percent = 100 * _freq / r(sum)
            if "`pcformat'" == "" local pcformat "%2.1f"
            format _percent `pcformat' 
            local pcshow _percent 
            local yvar _percent 
            gen _pcshow = strofreal(_percent, "`pcformat'") 
        } 
        else { 
            local yvar _freq
        }

        /// text defaults to varnames, 
        /// optionally to variable labels if defined;        
        /// default separator is ", " 
        gen _text = "" 
        if "`sep'" == "" local sep = ", " 
        local lensep = length("`sep'")  

        forval j = 1/`nvars' {
            local label : var label ``j''
            if "`varlabels'" != "" & `"`label'"' != "" & `j' < `nvars' {
                replace _text = _text + `"`label'`sep'"' if substr(_binary, `j', 1) == "1"
            } 
            else if "`varlabels'" != "" & `"`label'"' != "" & `j' == `nvars' {
                replace _text = _text + `"`label'"' if substr(_binary, `j', 1) == "1"
            }
            else if `j' < `nvars' {
                replace _text = _text + "``j''`sep'" if substr(_binary, `j', 1) == "1"
            } 
            else replace _text = _text + "``j''" if substr(_binary, `j', 1) == "1" 
        } 

        replace _text = "<none>" if missing(_text) 
        replace _text = substr(_text, 1, length(_text) - `lensep') if substr(_text, -`lensep', .) == "`sep'" 

        gen _degree = length(_binary) - length(subinstr(_binary, "1", "", .)) 
    } 

    /// list major part  
    sort _decimal 
    capture if "`frformat'" != "" format _freq `frformat' 
    list _binary _decimal _text _freq `pcshow' _degree, noobs sep(0)

    quietly {
        /// we may need to create extra observations to show set frequencies;
        /// if we do, best to drop them before graphics 
        local N = _N   
        if `nvars' >= _N set obs `nvars'

        gen _set = ""
        gen double _setfreq = . 

        forval j = 1/`nvars' { 
            if "`varlabels'" != "" { 
                local label : var label ``j'' 
                if `"`label'"' == "" replace _set = "``j''" in `j' 
                else replace _set = `"`label'"' in `j' 
            } 
            else replace _set = "``j''" in `j' 

            summarize _freq if substr(_binary, `j', 1) == "1", meanonly 
            replace _setfreq = r(sum) in `j' 
        }

        compress _setfreq
    } 

    /// list minor part 
    capture if "`frformat'" != "" format _setfreq `frformat' 
    list _set _setfreq if _set != "", noobs sep(0)  

    /// save dataset if requested 
    if `"`savedata'"' != "" save `savedata' 
 
    /// graph 
    quietly keep in 1/`N'
    
    quietly if "`select'" != "" { 
        tempvar tokeep 
        gen byte `tokeep' = 0 

        foreach s of local select { 
            replace `tokeep' = 1 in `s' 
        }

        keep if `tokeep' 
    } 

    if "`gsort'" == "" gsort - _freq
    else if inlist("`gsort'", "_freq", "_percent") gsort - `gsort'
    else gsort `gsort'

    tempvar order min max  
    gen `order' = _n - 1  

    su `yvar', meanonly 
    _nicelabels 0 `r(max)', local(yla) 

    if "`axisgap'" == "" local axisgap = r(max) / 100 
    c_local axisgap "`axisgap'" 
    if "`vargap'" == "" local vargap = 4 * r(max) / 100
    c_local vargap "`vargap'" 

    quietly forval j = 1/`nvars'{
        local where = -`j' * `vargap' - `axisgap'
        tempvar legend`j'  
        gen `legend`j'' = `where' if ``j''
        local legendvars `legendvars' `legend`j''
        if "`varlabels'" != "" { 
            local label : var label ``j'' 
            if `"`label'"' == "" local call `call' `where' "``j''" 
            else local call `call' `where' `"`label'"'
        } 
        else local call `call' `where' "``j''"
    }

    quietly {   
        egen `max' = rowmax(`legendvars')
        egen `min' = rowmin(`legendvars') 
    } 

    local OK1 230 159 0
    local OK2 86 180 233
    local OK3 0 158 115
    local OK4 240 228 66
    local OK5 0 114 178 
    local OK6 213 94 0 
    local OK7 204 121 167 
    local OK8 0 0 0
    
    if "`labelopts'" == "none" {
        local labelopts ms(none) 
    }
    else local labelopts ms(none)  mlabc(black) mla(`yvar') mlabpos(12) mlabsize(small) `labelopts'

    twoway bar `yvar' `order', yla(`yla', ang(h)) barw(0.8) xsc(off) `baropts' ///
    || scatter `yvar' `order', `labelopts' ///
    || rspike `max' `min' `order', lc(gs8) `spikeopts'  ///
    || scatter `legendvars' `order' ,  ymla(`call', ang(h) noticks) legend(off) aspect(0.8) ///
    ms(O T D S + X) mc("`OK1'" "`OK2'" "`OK3'" "`OK4'" "`OK5'" "`OK6'" "`OK7'" "`OK8'") `matrixopts' `options'  

end

program bad_data
    args v 
    di  
    di "{p}The variable `v' contains values that are not 0 or 1. " /// 
    "You may wish to exclude them, or to recode, or to reconsider. " ///
    "{cmd:upsetplot} is for binary indicators only.{p_end}"
end 

/// essence of _gdecimal from -egenmore- on SSC 
/// original 1.0.0 NJC 26 Oct 2001
program decimal  
    version 8.2
    syntax varlist(numeric min=1)  
    local g _decimal 
    local nvars : word count `varlist'  
    tokenize `varlist' 

    quietly {
        gen long `g' = 0  
        forval i = 1/`nvars' { 
            local power = `nvars' - `i'  
            replace `g' = `g' + ``i'' * 2^`power' 
        }   
        compress `g' 
    }
end

* essence of nicelabels from SSC/SJ 
* original 1.0.0 NJC 29 April 2022 
program _nicelabels           
    version 9

    gettoken first 0 : 0, parse(" ,")  
    gettoken second 0 : 0, parse(" ,") 
    syntax , Local(str) [ nvals(int 5)]
 
    mata: nicelabels(`first', `second', `nvals', 0) 
    c_local `local' "`results'"
end  

mata : 

void nicelabels(real min, real max, real nvals, real tight) { 
    if (min == max) {
        st_local("results", min) 
        exit(0) 
    }

    real range, d, newmin, newmax
    colvector nicevals 
    range = nicenum(max - min, 0) 
    d = nicenum(range / (nvals - 1), 1)
    newmin = tight == 0 ? d * floor(min / d) : d * ceil(min / d)
    newmax = tight == 0 ? d * ceil(max / d) : d * floor(max / d)  
    nvals = 1 + (newmax - newmin) / d 
    nicevals = newmin :+ (0 :: nvals - 1) :* d  
    st_local("interval", strofreal(d)) 
    st_local("results", invtokens(strofreal(nicevals')))   
}

real nicenum(real x, real round) { 
    real expt, f, nf 
    
    expt = floor(log10(x)) 
    f = x / (10^expt) 
    
    if (round) { 
        if (f < 1.5) nf = 1 
        else if (f < 3) nf = 2
        else if (f < 7) nf = 5
        else nf = 10 
    }
    else { 
        if (f <= 1) nf = 1 
        else if (f <= 2) nf = 2 
        else if (f <= 5) nf = 5 
        else nf = 10 
    }

    return(nf * 10^expt)
}

end 
