*! version 1.0  2023-09-13 Mark Chatfield


*I shortened Nick Cox's command: niceloglabels, v1.1.0  24 August 2020 
program niceloglabels_shorter  
        gettoken first 0 : 0, parse(" ,")  
        capture confirm numeric variable `first' 
        if _rc == 0 {
                syntax [if] [in] , Local(str) Style(str) [ Fudge(real 1) ] 
                local varlist `first'  
                marksample touse 
                quietly count if `touse'        
                if r(N) == 0 exit 2000 
        } 
        else { 
                confirm number `first' 
                gettoken second 0 : 0, parse(" ,") 
                syntax , Local(str) Style(str) [ Fudge(real 1) ]
                if _N < 2 { 
                        preserve 
                        quietly set obs 2 
                }        
                tempvar varlist touse 
                gen `varlist' = cond(_n == 1, `first', `second') 
                gen byte `touse' = _n <= 2 
        }       

        local style = trim(subinstr("`style'", " ", "", .)) 
        
        tempname dmin dmax 
        su `varlist' if `touse', meanonly 
        scalar `dmin' = r(min) 
        scalar `dmax' = r(max) 
    
        tempvar logx 
        quietly {
                if "`style'" == "2" {
                        gen double `logx' = log10(`varlist')/log(2) if `touse'
                }
                else if "`style'" == "3" { 
                        gen double `logx' = log10(`varlist')/log(3) if `touse'
                }
                else gen double `logx' = log10(`varlist') if `touse' 
        }

        su `logx', meanonly 
        // default is to bump (minimum, maximum) (down, up) by 1%
        // otherwise we can be trapped by precision problems, 
        // e.g. floor(log(1000)) is returned as 2 not 3
        local lmin = ceil(r(min) * (100 - sign(r(min)) * `fudge')/100) 
        local lmax = floor(r(max) * (100 + sign(r(max)) * `fudge')/100) 

		if "`style'" == "1" { 
                forval n = `lmin'/`lmax' { 
                        local this = 10^`n'
                        local all `all' `this' 
                } 
        }
         else if "`style'" == "125" { 
                local nm1 = `lmin' - 1 
                if `dmin' <= 2 * 10^`nm1' & `dmax' >= 2 * 10^`nm1' { 
                        local this = 2 * 10^`nm1' 
                        local all `this' 
                }

                if `dmin' <= 5 * 10^`nm1' & `dmax' >= 5 * 10^`nm1' { 
                        local this = 5 * 10^`nm1' 
                        local all `all' `this' 
                } 

                forval n = `lmin'/`lmax' { 
                        local this = 10^`n' 

                        if `dmax' >= 2 * 10^`n' { 
                                local that = 2 * 10^`n' 
                         }
                        else local that 

                        if `dmax' >= 5 * 10^`n' { 
                                local tother = 5 * 10^`n'                   
                        }
                        else local tother 
                         
                        local all `all' `this' `that' `tother'
                }
        } 
        c_local `local' `"`all'"'  
end 



*my effort at _logscale
program define nicelabels, rclass
args min max
	
	local minext2 = `min'*2^(-0.5)
	local maxext2 = `max'*2^(0.5)
	niceloglabels_shorter `minext2' `maxext2', local(la125) style(125)
	local numswith125 = wordcount("`la125'")

	if `numswith125' > 3 {
		local la "`la125'"
		local minext = `min'*10^(-0.5)
		local maxext = `max'*10^(0.5)
		niceloglabels_shorter `minext' `maxext', local(la1) style(1)
		local numswith1 = wordcount("`la1'")
		if `numswith1' > 3 local la "`la1'"
	}	
	else {
		_natscale `min' `max' 9
		if r(min) / `min' < 0.7  local labstart = r(min) + r(delta)  // as bottom one can be far away when plot on log scale
		else local labstart = r(min)
		local la "`labstart' (`=r(delta)') `=r(max)'"
	}	
	di "`la'"
	return local la "`la'"
end	



*I shortened Nick Cox's command: mylabels, 1.3.1 NJC 21 Sept 2016 
program mylabels_shorter 
        version 8 
        syntax anything(name=values) , Local(str) ///
        [MYscale(str asis) clean Format(str) PREfix(str) SUFfix(str)]  

        capture numlist "`values'" 
        if _rc == 0 local values "`r(numlist)'"        

        if "`format'" != "" { 
                capture di `format' 1.2345 
        }       

                foreach v of local values { 
                        local val : subinstr local myscale "@" "(`v')", all 
                        local val : di %18.0g `val' 
                        if "`format'" != "" local v : di `format' `v' 
                        local mylabels `"`mylabels' `val' "`prefix'`v'`suffix'""' 
                }       

        di as res `"{p}`mylabels'"' 
        c_local `local' `"`mylabels'"' 
end 




*I shortened Nick Cox's command: myticks, 1.2.0 NJC 21 Sept 2016 
program myticks_shorter 
        version 8 
        syntax anything(name=values),  Local(str) [MYscale(str asis)] 

        capture numlist "`values'" 
        if _rc == 0 local values "`r(numlist)'"      
        
        foreach v of local values { 
                local val : subinstr local myscale "@" "(`v')", all 
                local val : di %18.0g `val' 
                local myticks "`myticks' `val'" 
        } 

        di as res "{p}`myticks'" 
        c_local `local' "`myticks'" 
end 


 
program define box_logscale, sortpreserve rclass

version 11.0

syntax varlist (min=1 numeric) [if] [in] [aweight fweight pweight], [ ///
	LABel(numlist) ///
	MTIck(numlist) ///
	NOOUTsides ///
	Over(string asis) ///
	by(string asis) ///
	Horizontal * ///
	]
	
marksample touse, novarlist
	
tokenize `"`over'"', parse(",")	
local overvarname `1'
*this just gets the first over(), but the second is captured in `options'
*ideally i would figure out one day how to get overvarname2 and overvarname3 and incorporate below

tokenize `"`by'"', parse(",")	
local byvarnames `1'
	
preserve

foreach v of varlist `varlist' {
	
	qui count if `v' <=0  & `touse'
	if r(N)>0 {
		di as error "Some `v' <= 0"
		exit
	} 
	
	qui replace `v' = log10(`v')
	
	qui {
		if "`nooutsides'" != "" { 
			tempvar upq loq upper lower 
			egen `upq' = pctile(`v') if `touse', by(`overvarname' `byvarnames') p(75)
			egen `loq' = pctile(`v') if `touse', by(`overvarname' `byvarnames') p(25)
			egen `upper' = max(`v' / (`v' < `upq' + 1.5 * (`upq' - `loq'))) if `touse', by(`overvarname' `byvarnames')
			egen `lower' = min(`v' / (`v' > `loq' - 1.5 * (`upq' - `loq'))) if `touse', by(`overvarname' `byvarnames')
			su `upper' if `touse'
			local max = r(max)
			su `lower' if `touse'
			local min = r(min)	
			drop `upq' `loq' `upper' `lower'
		}
		else {
			su `v' if `touse'
			local min = r(min)
			local max = r(max)	
		}
	}

	if "`minofmins'"=="" local minofmins "`min'" 
	if "`minofmins'"!="" & "`min'"!="" & `min' < `minofmins'  local minofmins "`min'"
	if "`maxofmaxs'"=="" local maxofmaxs "`max'" 
	if "`maxofmaxs'"!="" & "`max'"!="" & `max' > `maxofmaxs'  local maxofmaxs "`max'"	
}

local expmin = 10^(`minofmins')	
local expmax = 10^(`maxofmaxs')

if "`label'" != "" {
	qui mylabels_shorter `label', myscale(log10(@)) local(labels)
}
else {
	qui nicelabels `expmin' `expmax'
	local la "`r(la)'"
	qui mylabels_shorter `la', myscale(log10(@)) local(labels)
}

if "`mtick'" != "" {
	qui myticks_shorter `mtick', myscale(log10(@)) local(ticks)
	local mtickbit "ymtick(`ticks')"
}

if "`by'" != "" local byexp `"by(`by')"'

if "`horizontal'" == "" local box "box"
else local box "hbox"

if "`weight'" != "" local wt "[`weight' `exp']"

graph `box' `varlist' `if' `in' `wt', ylabel(`labels') `mtickbit' `nooutsides' over(`over') `byexp' `options'

restore
end
