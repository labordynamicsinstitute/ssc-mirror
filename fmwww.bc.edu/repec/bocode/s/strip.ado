*! strip 3.0.0 NJC 1 April 2026 
*! 2.10.0 NJC 5 May 2024
* 2.9.2 NJC 11 December 2023
* 2.9.1 NJC 30 January 2022     
* 2.9.0 NJC 10 July 2021     
* 2.8.1 NJC 11 October 2020 
* 2.8.0 NJC 4 July 2018 
* 2.7.2 NJC 8 June 2017 
* 2.7.1 NJC 27 March 2017 
* 2.7.0 NJC 2 March 2017 
* 2.6.0 NJC 21 February 2017 
* 2.5.3 NJC 20 December 2016 
* 2.5.2 NJC 23 September 2014 
* 2.5.1 NJC 9 September 2014 
* 2.5.0 NJC 14 August 2014 
* 2.4.7 NJC 28 June 2012 
* 2.4.6 NJC 30 August 2011 
* 2.4.5 NJC 2 December 2010 
* 2.4.4 NJC 10 March 2010 
* 2.4.3 NJC 16 February 2010 
* 2.4.2 NJC 4 February 2010 
* 2.4.1 NJC 30 November 2009 
* 2.4.0 NJC 21 April 2009 
* 2.3.3 NJC 8 November 2007 
* 2.3.2 NJC 2 November 2007 
* 2.3.1 NJC 17 July 2007 
* 2.3.0 NJC 21 June 2007 
* 2.2.0 NJC 28 November 2005
* onewayplot 2.1.3 NJC 27 October 2004
* 2.1.2 NJC 11 August 2004
* 2.1.1 NJC 21 July 2004
* 2.1.0 NJC 13 February 2004
* 2.0.3 NJC 17 July 2003 
* 2.0.2 NJC 7 July 2003 
* 2.0.1 NJC 6 July 2003 
* 2.0.0 NJC 3 July 2003 
* 1.2.1 NJC 18 October 1999 
* 1.1.0 NJC 27 April 1999 
* 1.0.0 NJC 23 April 1999 

program strip
	version 9

	#delimit ; 	

	syntax varlist(numeric) [if] [in]                                  
	[,   
	vertical 
	height(real 0.8) 
	width(numlist max=1 >0)                
	stack     
    quantile
	center 
	centre  
	trscale(str asis)                      
	over(varname) 
	by(str asis) 
	variablelabels 
	separate(varname)  
	addplot(str asis) * ] ;  

	#delimit cr 
	
	// parse options 
	if "`floor'" != "" & "`ceiling'" != "" { 
		di as err "must choose between floor and ceiling"
		exit 198 
	}

	if "`quantile'" != "" & "`stack'" != "" { 
		di as err "may not combine quantile and stack options" 
		exit 198 
	} 

	tokenize `varlist' 
	local nvars : word count `varlist' 

	if `"`by'"' != "" { 
		gettoken by opts : by, parse(",") 
		gettoken comma opts : opts, parse(",") 
		
		if "`separate'" == "`by'" { 
			tempvar SEPARATE 
			clonevar `SEPARATE' = `separate'
			local separate `SEPARATE'
		}
	}
	
	if "`trscale'" != "" {
		if "`quantile'" == "" { 
			di as err "trscale() specified without quantile, so ignored"
			local trscale 
		}
		else {
			if !index("`trscale'", "@") { 
				di as err "trscale() does not contain @"
				exit 198 
			}
		}
	}

	// data to use, including by() over() separate() options 
	if `nvars' == 1 marksample touse
	else marksample touse, novarlist 

	if "`by'`over'`separate'" != "" { 
		markout `touse' `by' `over' `separate', strok 
	}

	quietly count if `touse' 
	if r(N) == 0 error 2000 
	
	local noover = "`over'" == ""
		
	quietly if `nvars' > 1 { 
		if "`over'" != "" { 
			di as err "over() may not be combined with more than one variable"
			exit 198
		}	
		else {
			// several variables are stacked into one
			// x axis shows `data' 
			// y axis shows _stack 
			preserve
			if "`variablelabels'" != "" { 
				forval i = 1/`nvars' { 
					local l : variable label ``i''
					local labels `"`labels' `i' `"`l'"'"'
				}
			} 	
			else forval i = 1/`nvars' {
           		local labels "`labels'`i' ``i'' "
	        }
			
			if "`by'" != "" { 
				local bylbl : value label `by' 
				if "`bylbl'" != "" { 
					tempfile bylabel 
					label save `bylbl' using `bylabel' 
				}
			}	

			if "`separate'" != "" { 
				local seplbl : value label `separate' 
				if "`seplbl'" != "" { 
					tempfile seplabel 
					label save `seplbl' using `seplabel'
				}
			}
		
			tempvar data copystack  
			foreach v of local varlist { 
				local stacklist "`stacklist' `v' `by' `exposure' `separate'" 
			}	
			stack `stacklist' if `touse', into(`data' `by' `exposure' `separate') clear
			drop if missing(`data')
			gen `copystack' = _stack  
							
			if "`width'" != "" {
				if "`floor'" != "" {
					replace `data' = `width' * floor(`data'/`width')
				}
				else if "`ceiling'" != "" { 
					replace `data' = `width' * ceil(`data'/`width')
				}	
				else replace `data' = round(`data', `width') 
			}	
			
			label var `data' "`varlist'"
			label var _stack `" "' 

			if "`bylbl'" != "" { 
				do `bylabel' 
				label val `by' `bylbl' 
			}	

			if "`seplbl'" != "" { 
				do `seplabel' 
				label val `separate' `seplbl' 
			}	

			tempname stlbl
			label def `stlbl' `labels' 
	        label val _stack `stlbl'
			su _stack, meanonly 
			local range "`r(min)'/`r(max)'" 
			if "`stack'" != "" { 
				tempvar count
				sort `by' _stack `data' `separate', stable 
				by `by' _stack `data' : gen `count' = _n - 1  
				su `count', meanonly
				if "`centre'`center'" != "" { 
					by `by' _stack `data' : ///
					replace `count' = _n - (_N + 1)/2
				} 
				if r(max) > 0 { 
					replace _stack = _stack + `height' * `count' / r(max) 
				} 	
			}	

			if "`quantile'" != "" { 
				tempvar count negstack 
				gen `negstack' = -_stack 
				sort `by' `negstack' `data' `separate', stable 

				by `by' `negstack' : gen `count' = (_n - 0.5)/_N 

				if "`trscale'" != "" {
					local defn : subinstr local trscale "@" "`count'", all 
					by `by' `negstack': replace `count' = `defn'
					tempvar MIN MAX 
					by `by' `negstack' : egen `MIN' = min(`count')
					by `by' `negstack' : egen `MAX' = max(`count')
					replace `count' = (`count' - `MIN')/(`MAX' - `MIN')
				}

				su `count', meanonly 

				if "`centre'`center'" != "" { 
					if "`quantile'" != "" { 
						by `by' `negstack' : replace `count' = `count' - 0.5 
					}
					else by `by' `negstack' : replace `count' = _n - (_N + 1)/2
				}

				replace _stack = _stack + `height' * `count' / r(max) 
			} 

			local which "`copystack'" 
		}
	}	
	else quietly {
		preserve 
		keep if `touse' 

		if "`over'" == "" {
			// a single variable, no over()
			// x axis shows `varlist' 
			// y axis shows `over' = 1  
			tempvar over
			gen byte `over' = 1 
			tempname overlbl 
			label def `overlbl' 1 "`varlist'"
			label val `over' `overlbl' 
		}
		else {
			// a single variable with over()
			// x axis shows `varlist' 
			// y axis shows `over' (or `overcount' if stack option)
			tempvar over2
			capture confirm numeric variable `over'
			if _rc == 7 { 
				encode `over', gen(`over2')
			}	
			else { 
				gen `over2' = `over' 
				label val `over2' `: value label `over'' 
			} 	
			_crcslbl `over2' `over' 
			local over "`over2'"

			capture levelsof `over' 
			if _rc { 
				su `over', meanonly 
				local range "`r(min)'/`r(max)'" 
			} 
			else local range "`r(levels)'" 
		}

		if "`width'" != "" { 
			tempvar rounded
			if "`floor'" != "" {
				gen `rounded' = `width' * floor(`varlist'/`width')
			}
			else if "`ceiling'" != "" { 
				gen `rounded' = `width' * ceil(`varlist'/`width')
			}	
			else gen `rounded' = round(`varlist', `width') 

			_crcslbl `rounded' `varlist' 
			local varlist "`rounded'" 
		} 	
	
		if "`stack'" != "" { 
			tempvar count overcount 
			sort `by' `over' `varlist' `separate', stable 
			by `by' `over' `varlist': gen `count' = _n - 1 
			su `count', meanonly
			if "`centre'`center'" != "" { 
				by `by' `over' `varlist' : ///
				replace `count' = _n - (_N + 1)/2 
			} 
			gen `overcount' = `over' 
			if r(max) > 0 { 
				replace `overcount' = `overcount' + `height' * `count' / r(max) 
			} 	
			_crcslbl `overcount' `over'
			label val `overcount' `: value label `over'' 
		} 

		if "`quantile'" != "" { 
			tempvar count overcount negover 
			gen `negover' = -`over' 
			sort `by' `negover' `varlist' `separate', stable 

			by `by' `negover': gen `count' = (_n - 0.5)/_N 
			if "`trscale'" != "" {
				local defn : subinstr local trscale "@" "`count'", all 
				by `by' `negover': replace `count' = `defn'
				tempvar MIN MAX 
				by `by' `negover' : egen `MIN' = min(`count')
				by `by' `negover' : egen `MAX' = max(`count')
				replace `count' = (`count' - `MIN')/(`MAX' - `MIN')
			}

			su `count', meanonly

			if "`centre'`center'" != "" { 
				if "`quantile'" != "" { 
					by `by' `negover' : replace `count' = `count' - 0.5 
				} 
				else by `by' `negover': replace `count' = _n - (_N + 1)/2 
			} 

			gen `overcount' = `over' 
			if r(max) > 0 { 
				replace `overcount' = `overcount' + `height' * `count' / r(max) 
			} 	
			_crcslbl `overcount' `over'
			label val `overcount' `: value label `over'' 
		}
		
		local which "`over'" 
	}	

	// plot details 
	if `noover' local axtitle `" "' 
	else { 
		local axtitle : variable label `over' 
		if `"`axtitle'"' == "" local axtitle "`over'" 
	} 	

	if `nvars' > 1 local axtitle2 "`varlist'"
	else { 
		local axtitle2 `"`: var label `varlist''"' 
		if `"`axtitle2'"' == "" local axtitle2 "`varlist'" 
	}	

	if "`over'" != "" { 
		if "`stack'`quantile'" != "" { 
			local yshow "`overcount'" 
			local xshow "`varlist'" 
		} 	
		else { 
			local yshow "`over'" 
			local xshow "`varlist'" 
		} 	
	}
	else {
		local yshow "_stack" 
		local xshow "`data'" 
	}

	local y = cond("`over'" != "", "`over'", "_stack") 
	local Y = cond("`over'" != "", "`over'", "`copystack'") 

	if `noover' & `nvars' == 1 local axlabel ", nolabels noticks nogrid" 
	else { 
		foreach r of num `range' { 
			local axlabel `axlabel' `r' `"`: label (`y') `r''"'  
		}	
		local axlabel `axlabel', ang(h)  
	}	
	
	su `yshow', meanonly
	local margin = cond(r(max) == r(min), 0.1, 0.05 * (r(max) - r(min)))
	local stretch "r(`= r(min) - `margin'' `= r(max) + `margin'')" 
	if "`vertical'" != "" local stretch "xsc(`stretch')" 
	else local stretch "ysc(`stretch')"

	local nprev = 0  

	quietly if "`vertical'" != "" { 
		if "`separate'" != "" { 
			tempname stub 
			separate `xshow', by(`separate') gen(`stub') veryshortlabel 
			local xshow "`r(varlist)'" 
			local first = `nprev' + 1 
			local last = `first' + `: word count `xshow'' - 1 
			numlist "`first'/`last'" 
			local separate legend(order(`r(numlist)')) 
		}
		else local separate "legend(off)" 

		if "`by'" != "" { 
			if "`separate'" == "" local separate "legend(off)" 

			local legoff 0 
			foreach o in leg lege legen legend { 
				local legoff = max(`legoff', strpos(`"`opts'"', "`o'(off)")) 
			} 
			if `legoff' local separate   

			if `noover' & `nvars' == 1 { 
				local byby by(`by', noixla noixtic `separate' `opts') xla(none)
			}
			else local byby by(`by', noixtic `separate' `opts')
			* local separate 
		}

		noisily scatter `xshow' `yshow', pstyle(p1)           ///
		ms(Oh) xti(`"`axtitle'"') yti(`"`axtitle2'"')         /// 
		xla(`axlabel') `stretch' `byby' `separate' `options'  ///
		|| `addplot' 
		// blank
 
		exit 0  
	} 	
	else quietly { 
		if "`separate'" != "" { 
			tempname stub 
			separate `yshow', by(`separate') gen(`stub') veryshortlabel 
			local yshow "`r(varlist)'" 
			local first = `nprev' + 1 
			local last = `first' + `: word count `yshow'' - 1 
			numlist "`first'/`last'" 
			local separate legend(order(`r(numlist)')) 
		}
		else local separate "legend(off)"

		if "`by'" != "" {
			if "`separate'" == "" local separate "legend(off)"   

			local legoff 0 
			foreach o in leg lege legen legend { 
				local legoff = max(`legoff', strpos(`"`opts'"', "`o'(off)")) 
			} 
			if `legoff' local separate  

			if `noover' & `nvars' == 1 { 
				local byby ///
				"by(`by', noiyla noiytic `separate' `opts') yla(none)"
			} 
			else local byby "by(`by', noiytic `separate' `opts')" 

			* local separate 
		} 

		noisily scatter `yshow' `xshow', pstyle(p1)  ///
		ms(Oh) yti(`"`axtitle'"') xti(`"`axtitle2'"')             /// 
		yla(`axlabel') `stretch' `byby' `separate' `options'     /// 
		|| `addplot'  
		// blank 
	} 	
end 	

/* 

	2.1.3 The -sort-s were all made -, stable-. This is important  
	when you want to add -mlabel()- and -mlabel()- contains 
	order-sensitive information e.g. on time of observation. 

*/ 


