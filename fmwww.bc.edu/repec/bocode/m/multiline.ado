*! 1.6.0 NJC 27mar2022 
* 1.5.0 NJC 13jul2020 
* 1.4.1 NJC 5apr2020 
* 1.4.0 NJC 14mar2019 
* 1.3.1 NJC 14jul2017 
* 1`.3.0 NJC 3jul2017 
* 1.2.0 NJC 8mar2017 
* 1.1.0 NJC 2oct2016 
* 1.0.0 NJC 5sept2016 
program multiline 
    version 11
    syntax varlist(numeric) [if] [in] ///
    [, by(str asis) mylabels(str asis) MISSing SEParate SEPby(varname) savedata(str asis) SHOW(varname) addplot(str asis) *] 
    
	// undocumented show() addplot()

    quietly { 
		if "`sepby'" != "" { 
			if "`separate'" != "" { 
				di as err "separate and sepby() options cannot be combined"
				exit 198 
			}
		}
			
        if "`missing'" != "" marksample touse, novarlist 
        else marksample touse 

        count if `touse' 
        if r(N) == 0 exit 2000 

        preserve 
        keep if `touse' 
        drop `touse' 
    
        gettoken yvar rest : varlist 
        local J = 0 
        while "`yvar'" != "" { 
            local ++J 
            local lbl`J' : var label `yvar' 
            if `"`lbl`J''"' == "" local lbl`J' "`yvar'" 
            local last "`yvar'" 
            gettoken yvar rest : rest    
        } 

        local xvar "`last'" 
        local yvar : list varlist - xvar 

        capture tsset 
        if "`r(panelvar)'" != "" local panelvar "`r(panelvar)'" 

        foreach v of local yvar { 
            local call `call' `v' `panelvar' `xvar' `show' `sepby' 
        }

        tempname y
        tempfile myxvar 
        local label : value label `xvar'  
        label save `label' using "`myxvar'"

		if "`panelvar'" != "" { 
			local label2 : value label `panelvar' 
			if "`label2'" != "" { 
				tempfile mypanelvar
				label save `label2' using "`mypanelvar'" 
				local flag1 = 1 
			}
		}	 

		if "`sepby'" != "" { 
			local label3 : value label `sepby' 
			if "`label3'" != "" { 
				tempfile mysepby 
				label save `label3' using "`mysepby'" 
			} 
		} 

        stack `call', into(`y' `panelvar' `xvar' `show' `sepby') clear
 
        do "`myxvar'" 
        if "`label'" != "" { 
            label val `xvar' `label' 
        } 

		if "`label2'" != "" { 
			do "`mypanelvar'" 
			label val `panelvar' `label2' 
		} 

		if "`label3'" != "" {
			do "`mysepby'" 
			label val `sepby' `label3' 
		} 

        local Jm1 = `J' - 1 
        if `"`mylabels'"' != "" { 
            tokenize `mylabels' 
            forval j = 1/`Jm1' { 
                label def _stack `j' `"``j''"', add 
            } 
        } 
        else forval j = 1/`Jm1' { 
            label def _stack `j' `"`lbl`j''"', add 
        } 
        label val _stack _stack 
    } 

    sort `panelvar' `xvar' 
    label var `xvar'  `"`lbl`J''"'

    if `"`by'"' == "" local by "cols(1)"  
    else { 
        local found 0 
        foreach opt in c co col cols { 
            if strpos(`"`by'"', "`opt'(") { 
                local found 1 
                continue, break 
            } 
        }
        if !`found' local by `"`by' cols(1)"' 
    }  

    local Y `y' 

    quietly {
		if "`separate'" != "" { 
        	separate `y', by(_stack) veryshortlabel 
        	local y `r(varlist)' 
    	} 
    	else if "`sepby'" != "" { 
			separate `y', by(`sepby') veryshortlabel 
			local y `r(varlist)' 
    	}
    }  
        
	if "`show'" != "" local show mla(`show') mlabpos(3) 

    line `y' `xvar', by(_stack, yrescale note("") `by') ///
    ytitle("") yla(, ang(h)) c(L) ///
    subtitle(, pos(9) bcolor(none) nobexpand place(e)) `show' `options' ///
    || `addplot'


	if `"`savedata'"' != "" { 
		capture rename `Y' _y 
		save `savedata' 
	} 
end

