*! Refactored version: ppp v2.02 (2025-08-25)
*No limits on columns and risk bands
cap program drop ppp
program define ppp
    version 10.1

    syntax anything [if] [in], [bands(string) bandcolor(string) noLR ///
        LEGENDopts(string asis) YSIZE(integer 6) XSIZE(integer 4) ///
        dp(string) skip(integer 0) * ]

    tempname lprev 
    tempvar x
    qui {
        local k: word count `anything'
        tokenize `anything'

        if `k' < 3 {
            di as err "At least 3 arguments required (prev, LR+, LR−)"
            exit 198
        }
        if "`dp'" == "" local dp 2

        local maxl = log(99.9/(100-99.9))
        local minl = log(0.01/(100-0.01))

        scalar `lprev' = log(`1' / (1 - `1'))
        local lpostprob1 = log(`1' / (1 - `1'))
        local postprob1 = 100*`1'
        local notepost1: di "(" %4.`dp'f `postprob1' "%)"
        local path1 = "Start"

        local segment = `""'
        local vertikal = `""'

        local max_depth = floor(log(`k') / log(2))

        forvalues d = 0/`max_depth' {
            if `d' == 0 {
                local xpos0 = 0
            }
            else {
                local xpos`d' = `= 4 * `d' + 4*`skip''
            }
        }

        forvalues i = 2/`k' {
            local parent = floor((`i' - 2) / 2) + 1
            local param_idx = `i'

            if mod(`i',2) == 0 {
                * LR+
                if "`lr'" == "" {
                    local plr = ``i''
                }
                else {
                    if `i' + 1 > `k' continue
                    local Se = ``i''
                    local Sp = ``=`i'+1''
                    local plr = `Se' / (1 - `Sp')
                }
                local lpostprob`i' = `lpostprob`parent'' + log(`plr')
                local path`i' = "`path`parent''->P"
                local color`i' "red"
            }
            else {
                * LR−
                if "`lr'" == "" {
                    local nlr = ``i''
                }
                else {
                    if `i' - 1 < 2 continue
                    local Se = ``=`i'-1''
                    local Sp = ``i''
                    local nlr = (1 - `Se') / `Sp'
                }
                local lpostprob`i' = `lpostprob`parent'' + log(`nlr')
                local path`i' = "`path`parent''->N"
                local color`i' "green"
            }

            local postprob`i' = 100*invlogit(`lpostprob`i'')
            local notepost`i': di "(" %4.`dp'f `postprob`i'' "%)"
			
			//neutral point
            if ("`lr'" == "" & "``i''" == "1") | ("`lr'" != "" & inlist("``i''", ".5", "0.5")) local color`i' "gs5"
        }

        forvalues i = 2/`k' {
            local parent = floor((`i' - 2)/2) + 1
            local col = "`color`i''"
            local level_parent = floor(log(`parent') / log(2))
            local level_child  = floor(log(`i') / log(2))
            local x0 = `xpos`level_parent''
            local x1 = `xpos`level_child''
            local lpat = cond(`level_child' == 1, "solid", "dash")

            local segment `"`segment' (pcarrowi `lpostprob`parent'' `x0' `lpostprob`i'' `x1', lcolor(`col') mcolor(`col') yaxis(2) lpat(`lpat') lwidth(thin))"'
        }

        local ylab ""
        foreach p in 0.01 0.05 0.1 0.5 1 2 5 10 20 50 80 90 95 99 99.5 99.9 {
            local ylab `"`ylab' `=log(`p' / (100 - `p'))' "`p'" "' 
        }

        forvalues d = 1/`=`max_depth'-1' {
            local vertikal = "`vertikal' (pci `minl' `xpos`d'' `maxl' `xpos`d'', recast(pcspike) lcolor(gs5) plotregion(margin(zero)))"
        }

        local area ""
        if "`bands'" != "" {
            local countbands = wordcount("`bands'")

            if "`bandcolor'" == "" {
                if `countbands' == 2 local bandcolor = "green*0.3 orange*0.3 red*0.3"
                if `countbands' == 3 local bandcolor = "blue*0.3 green*0.3 orange*0.3 red*0.3"
                if `countbands' == 4 local bandcolor = "blue*0.3 green*0.3 orange*0.3 brown*0.3 red*0.3"
            }

            local countzones = `countbands' + 1
			preserve
			clear
            set obs `=`max_depth'*4 + 1 + 4*`skip''
            gen `x' = .
            replace `x' = _n - 1
            forvalues i = 1/`countzones' {
                tempname upbound`i'
                if `i' == 1 {
                    local low = log(0.01 / (100 - 0.01))
                }
                else {
                    local val = word("`bands'", `=`i'-1')
                    local low = log(`val' / (1 - `val'))
                }

                if `i' == `countzones' {
                    gen `upbound`i'' = log(99.9 / (100 - 99.9))
                }
                else {
                    local val = word("`bands'", `i')
                    gen `upbound`i'' = log(`val' / (1 - `val'))
                }
                local col = word("`bandcolor'", `i')
                local area `area' (area `upbound`i'' `x', color(`col') base(`low'))
            }
        }

        if `"`legendopts'"' == "on" {
            local legendopts
            local bands_plots = cond("`bands'" == "", 0, wordcount("`bands'") + 1)
            local branches = `k' - 1
            local ncols = `max_depth' + 1
			local blank = `" - " " " " "'
            forvalues coli=1/`ncols' {
                
				if `coli' > 1 {
					local offset = `bands_plots' + `max_depth' - 1
					}
				else {
					local offset = `bands_plots' 
				}
                forvalue key = `=2^(`coli' - 1)'/`=(2^`coli' - 1)' {				
					if ("`lr'" == "" & "``key''" == "1") | ("`lr'" != "" & inlist("``key''", ".5", "0.5")) | ("``key''" == ".") | ("``key''" == "") {
						local addblank 1
						local note 
					}
					else {
						local addblank 0
						local note `" `=`key' + `offset''  "Post(`sign')" "`notepost`key''" "'
					}
                    local sign = cond(mod(`key', 2), "+", "-")
                    local blanks = `"`blank'"'*`=(2^(`ncols' - `coli') - 1 + `addblank')'
                    local legendorder = `" `legendorder' `note' `blanks'"'
                }
				if `skip' > 0 {
					local skipped = `"`blank'"'*`skip'
					local legendorder = `" `legendorder' `skipped'"'
				}
            }
            local legendopts `"order(`legendorder') pos(6) colf col(`ncols') rowgap(1) colgap(20) region(lcolor(none))"'
        }

        #delimit;
        twoway 
            `area' 
            (scatteri `lpostprob1' 0, 
                msym(D) mcolor(black) xlab(none, axis(1))
                xlab(none, axis(2))
                xtitle(" ", axis(1))
                xtitle(" ", axis(2))
                xaxis(1 2)
                ylab(`ylab', angle(0) tpos(cross) nogrid axis(1))
                ylab(`ylab', angle(0) tpos(cross) nogrid axis(2)) 
                yscale(axis(1)) yscale(axis(2))) 
            `segment' 
            `vertikal', 
            ytitle("Post-test Probability (%)", axis(2) placement(0)) 
            ytitle("Pre-test Probability (%)", axis(1) placement(9) margin(l=-5 r=3)) 
            graphregion(color(white) margin(l=5 r=8)) 
            xsize(`xsize') ysize(`ysize') `options' legend(`legendopts')
        ;
        #delimit cr
		restore
    }
end
