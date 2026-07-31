*! statplot - plots of summary statistics
*! 1.3.0  Eric A. Booth and Nicholas J. Cox  18 July 2026
*  1.3.0  Eric A. Booth and Nicholas J. Cox 18 July 2026
*         New, fully backward-compatible options (every earlier option retained):
*           ci level() ciopts()          confidence-interval / error-bar mode
*           percent                       scale a statistic (e.g. mean of 0/1) to 0-100
*           share base()                  express bars as a share (%) of a total/var/over group
*           savedata() listdata frame()   expose the collapsed results set that is graphed
*           wrap(#)                        wrap long axis labels onto multiple lines
*           sort descending               order the plotted variables by their value
*           order() first() last()        fix the order of, or pin, plotted variables
*         statplot is now rclass and returns results in r().
*  1.2.7  Eric A. Booth and Nicholas J. Cox 5 May 2011
*  1.2.6  Eric A. Booth and Nicholas J. Cox 25 April 2011   **put in check that recast opt was hbar, bar, or dot only
*  1.2.5  Eric A. Booth and Nicholas J. Cox 25 March 2011    ** added single quotes to macros in -if- loops to avoid error when by() or over() options contained suboptions with double quotes
*  1.2.4  Eric A. Booth and Nicholas J. Cox 24 February 2011

program statplot, rclass
	version 8.2
	syntax varlist(numeric) [if] [in] ///
	[aweight fweight iweight pweight] ///
	[, MISSing Statistic(str asis) OVER1(str asis) OVER2(str asis)  ///
	xpose recast(str) varnames varopts(str asis) BY(str asis)       ///
	/// ---- new in 1.3.0 (all optional; defaults reproduce prior behaviour) ----
	CI LEVel(cilevel) CIOPTs(str asis) BAROPTs(str asis)            ///
	HEADings(str asis) GROUPs(str asis)                            ///
	PERCENT SHARE BASE(str)                                         ///
	SAVEData(str asis) LISTdata FRame(name)                         ///
	WRAP(integer 0)                                                 ///
	SORT DEScending ORDER(varlist numeric) FIRST(varlist numeric) LAST(varlist numeric) ///
	*]

	/// The user doesn't get told about the different names -over1()- and -over2()-.
	/// Two different options have the same allowed abbreviation, but Stata takes them
	/// in the order given.

	if `"`statistic'"' == "" local statistic mean

	/// -------- validate the new options (fail early, before -preserve-) --------
	if "`percent'" != "" & "`share'" != "" {
		di as err "percent and share may not be combined"
		exit 198
	}
	if "`base'" != "" & "`share'" == "" {
		di as err "base() requires the share option"
		exit 198
	}
	if "`share'" != "" {
		if "`base'" == "" local base total
		if !inlist("`base'", "total", "var", "over") {
			di as err "base() must be total, var, or over"
			exit 198
		}
	}
	if `"`ciopts'"' != "" & "`ci'" == "" {
		di as err "ciopts() requires the ci option"
		exit 198
	}
	if `"`baropts'"' != "" & "`ci'" == "" {
		di as err "baropts() requires the ci option"
		exit 198
	}
	if "`level'" == "" local level = c(level)
	if "`ci'" != "" {
		if "`statistic'" != "mean" {
			di as err "ci requires statistic(mean) (the default)"
			exit 198
		}
		if "`share'" != "" {
			di as err "ci may not be combined with share"
			exit 198
		}
		if "`weight'" == "pweight" {
			di as err "ci does not support pweights; use fweight/aweight or omit weights"
			exit 198
		}
	}
	if "`frame'" != "" & c(stata_version) < 16 {
		di as err "frame() requires Stata 16 or later"
		exit 198
	}

	/// recast default + check (unchanged behaviour)
	if `"`recast'"' == "" local recast "hbar"
	if !inlist(`"`recast'"', "hbar", "bar", "dot") {
		di as err `"recast option must be: hbar, bar, or dot"'
		exit 198
	}

	marksample touse, novarlist

	if `"`over1'"' != "" {
		gettoken by1var by1opts: over1, parse(",")
		if `"`missing'"' == "" {
			markout `touse' `by1var', strok
		}
	}

	if `"`over2'"' != "" {
		gettoken by2var by2opts: over2, parse(",")
		if `"`missing'"' == "" {
			markout `touse' `by2var', strok
		}
	}

	if `"`by'"' != "" {
		gettoken by3var by3opts: by, parse(",")
		if "`missing'" == "" {
			markout `touse' `by3var', strok
		}
		loc over3 `"`by'"'   //over3 is a by() option
	}

	qui count if `touse'
	if r(N) == 0 error 2000
	local rN = r(N)

	preserve
	qui keep if `touse'

	local nvars : word count `varlist'
	local origvl `varlist'

	/// original variable labels, stored by POSITION so they survive -collapse-
	/// and any reordering.  (Keying locals by variable name could overflow the
	/// 31-character macro-name limit for long variable names.)
	local i = 1
	foreach v of local origvl {
		if `"`varnames'"' == "" local olbl`i' : var label `v'
		if `"`olbl`i''"' == "" local olbl`i' `"`v'"'
		local ++i
	}

	/// -over?()- variables if given
	/// using -egen, group()- allows uniform treatment of numeric and string variables
	forval n = 1/3 {
		if `"`over`n''"' != "" {
			tempvar myby`n'
			egen `myby`n'' = group(`by`n'var'), label `missing'
			su `myby`n'', meanonly
			local by`n'max = r(max)

			forval i = 1/`by`n'max' {
				local by`n'label`i' `"`: label (`myby`n'') `i''"'
				if `wrap' > 0 {
					_statplot_wrap , width(`wrap') text(`"`by`n'label`i''"')
					local by`n'label`i' `"`s(wrapped)'"'
				}
			}

			local by`n'label : var label `by`n'var'
			if `"`by`n'label'"' == "" local by`n'label `"`by`n'var'"' //changed
		}
	}

	*=========================================================================*
	if `"`ci'`headings'`groups'"' == "" {
	*------------------- standard graph hbar|bar|dot path ---------------------*
	*=========================================================================*

		if `"`over1'`over2'`over3'"' != "" {
			local byby `"by(`myby1' `myby2' `myby3')"'
		}

		/// -collapse-; restructure as needed
		collapse (`statistic') `varlist' if `touse' [`weight' `exp'],  `byby'

		if `"`over1'`over2'`over3'"' != "" local _Ngroups = _N

		// ---- percent / share transforms (rescale the plotted values) ----
		local ytitle `"`statistic'"'
		if "`percent'" != "" {
			foreach v of local varlist {
				qui replace `v' = 100*`v'
			}
			local ytitle "percent"
		}
		if "`share'" != "" {
			if "`base'" == "var" {
				foreach v of local varlist {
					qui su `v', meanonly
					if r(sum) != 0 qui replace `v' = 100*`v'/r(sum)
					else qui replace `v' = .
				}
			}
			else if "`base'" == "over" {
				tempvar rowtot
				qui egen double `rowtot' = rowtotal(`varlist')
				foreach v of local varlist {
					qui replace `v' = cond(`rowtot'==0, ., 100*`v'/`rowtot')
				}
				drop `rowtot'
			}
			else {
				local grand = 0
				foreach v of local varlist {
					qui su `v', meanonly
					local grand = `grand' + r(sum)
				}
				foreach v of local varlist {
					if `grand' != 0 qui replace `v' = 100*`v'/`grand'
					else qui replace `v' = .
				}
			}
			local ytitle `"percent (share of `base')"'
		}

		// ---- order the plotted variables (sort / order / first / last) ----
		if `nvars' > 1 & ("`sort'`order'`first'`last'" != "") {
			local keyval ""
			foreach v of local varlist {
				qui su `v', meanonly
				local keyval `keyval' `r(mean)'
			}
			_statplot_order , vlist(`varlist') keyval(`keyval') ///
				`sort' `descending' order(`order') first(`first') last(`last')
			local varlist `s(seq)'
			qui order `varlist'
		}

		// ---- indexed labels from (possibly reordered) varlist, with wrapping ----
		local i = 1
		foreach v of local varlist {
			local _p : list posof "`v'" in origvl
			local label`i' `"`olbl`_p''"'
			if `wrap' > 0 {
				_statplot_wrap , width(`wrap') text(`"`label`i''"')
				local label`i' `"`s(wrapped)'"'
			}
			local ++i
		}

		// ---- expose the collapsed results set (values exactly as graphed) ----
		if `"`savedata'"' != "" | "`listdata'" != "" | "`frame'" != "" {
			tempfile _hold
			qui save `_hold'
			forval n = 1/3 {
				if "`myby`n''" != "" {
					capture rename `myby`n'' `by`n'var'
					if _rc == 0 {
						label var `by`n'var' `"`by`n'label'"'
					}
					else {
						capture rename `myby`n'' _group`n'
						capture label var _group`n' `"`by`n'label'"'
					}
				}
			}
			if "`listdata'" != "" {
				di as txt _n "statplot: collapsed results set -- (`statistic') as plotted"
				list, noobs
			}
			if `"`savedata'"' != "" {
				gettoken _sdfile _sdrest : savedata, parse(",")
				local _sdrepl = cond(strpos(`"`_sdrest'"', "replace"), "replace", "")
				qui save `_sdfile', `_sdrepl'
			}
			if "`frame'" != "" {
				version 16: capture frame drop `frame'
				version 16: frame put *, into(`frame')
			}
			qui use `_hold', clear
		}

		tempname what
		tempvar which

		// no over() or by() options called
		if `"`by1var'`by2var'`by3var'"' == "" {
			xpose, clear

			/// varlist labels
			g `which' = _n
			forval i = 1/`nvars' {
				label def `what' `i' `"`label`i''"', modify
			}
			label val `which' `what'

			/// graph
			graph `recast' v1,  ///
				over(`which', `varopts') ///
				yti(`"`ytitle'"') `options'
		}

		// over() and/or by() options called
		else {
			if `nvars' > 1 {
				foreach v of local varlist {
					local call `call' `myby1' `myby2' `myby3' `v'
				}

				stack `call', into(`myby1' `myby2' `myby3' `which') clear
			}
			else {
				gen _stack = 1
				local which `varlist'
			}

			/// varlist labels
			forval i = 1/`nvars' {
				label def `what' `i' `"`label`i''"', modify
			}
			label val _stack `what'

			// sort the group axis by value when there is a single plotted variable
			if "`sort'" != "" & `nvars' == 1 & "`myby1'" != "" {
				local sortsub sort(1)
				if "`descending'" != "" local sortsub sort(1) descending
				if `"`by1opts'"' == "" local by1opts `", `sortsub'"'
				else local by1opts `"`by1opts' `sortsub'"'
			}

			forval n = 1/3 {
				if "`myby`n''" != "" {
					tempname by`n'labels
					forval i = 1/`by`n'max' {
						label def `by`n'labels' `i' `"`by`n'label`i''"', modify
					}
					label val `myby`n'' `by`n'labels'
					label var `myby`n'' `"`by`n'label'"'
					if `n'==1  loc OVER1 over(`myby1' `by1opts')
					else if `n'==2  loc OVER2 over(`myby2' `by2opts')
					else if `n'==3  loc BY by(`myby3' `by3opts')
				}
			}

			if `"`xpose'"'  == "" {
				local overs `OVER1'  `OVER2' `BY' over(_stack, `varopts')
			}
			else local overs over(_stack, `varopts') `OVER1'  `OVER2' `BY'

			/// graph
			graph `recast' `which', `overs' ///
				yti(`"`ytitle'"') `options'
		}
	}

	*=========================================================================*
	else {
	*----- twoway path: ci (error bars) and/or headings()/groups() ------------*
	*=========================================================================*

		local dowhisk = cond("`ci'" != "", 1, 0)

		if "`myby2'" != "" | "`myby3'" != "" {
			di as err "ci does not support two over() options or by(); see -cibar- or -coefplot- (from SSC)"
			exit 198
		}
		if `"`headings'`groups'"' != "" {
			if "`myby1'" != "" {
				di as err "headings() and groups() are supported only for variables plotted without over()"
				exit 198
			}
			if "`recast'" != "hbar" {
				di as err "headings() and groups() require recast(hbar) (the default)"
				exit 198
			}
		}

		// collapse the statistic for each variable (index-based stubs so long
		// variable names cannot overflow the 32-char limit); add SE and N for ci
		local mstubs ""
		local sstubs ""
		local cstubs ""
		local i = 0
		foreach v of local varlist {
			local ++i
			local mstubs `mstubs' _mn_`i'=`v'
			local sstubs `sstubs' _se_`i'=`v'
			local cstubs `cstubs' _ct_`i'=`v'
		}
		local ciby ""
		if "`myby1'" != "" local ciby by(`myby1')
		if `dowhisk' {
			qui collapse (mean) `mstubs' (semean) `sstubs' (count) `cstubs' if `touse' [`weight' `exp'], `ciby'
			qui gen _one = 1
			local ivar = cond("`myby1'" != "", "`myby1'", "_one")
			qui reshape long _mn_ _se_ _ct_, i(`ivar') j(_vni)
			rename _mn_ _mn
			rename _se_ _se
			rename _ct_ _ct
			qui gen double _lo = _mn - invttail(_ct-1, (100-`level')/200)*_se
			qui gen double _hi = _mn + invttail(_ct-1, (100-`level')/200)*_se
			qui replace _lo = _mn if _ct <= 1 | _se >= .
			qui replace _hi = _mn if _ct <= 1 | _se >= .
		}
		else {
			qui collapse (`statistic') `mstubs' if `touse' [`weight' `exp'], `ciby'
			qui gen _one = 1
			local ivar = cond("`myby1'" != "", "`myby1'", "_one")
			qui reshape long _mn_, i(`ivar') j(_vni)
			rename _mn_ _mn
		}

		local ytitle `"`statistic'"'
		if `dowhisk' local ytitle "mean"
		if "`percent'" != "" {
			qui replace _mn = 100*_mn
			if `dowhisk' {
				qui replace _lo = 100*_lo
				qui replace _hi = 100*_hi
			}
			local ytitle "percent"
		}

		if "`myby1'" != "" local _Ngroups = `by1max'

		tempvar xpos
		qui gen double `xpos' = .
		tempname catlab
		local byopt ""
		local grouplab ""
		local phantom ""

		if "`myby1'" == "" {
			// ---- no over: one bar per variable, in reading order (first on top) ----
			local keyval ""
			forval i = 1/`nvars' {
				qui su _mn if _vni==`i', meanonly
				local keyval `keyval' `r(mean)'
			}
			_statplot_order , vlist(`varlist') keyval(`keyval') ///
				`sort' `descending' order(`order') first(`first') last(`last')
			local seq `s(seq)'
			local nseq : word count `seq'

			// parse headings()/groups() into spec = "label" pairs
			local nH 0
			if `"`headings'"' != "" {
				_statplot_hgparse `headings'
				local nH = `s(n)'
				forval h = 1/`nH' {
					local Hspec`h' `"`s(spec`h')'"'
					local Hlab`h' `"`s(lab`h')'"'
				}
			}
			local nG 0
			if `"`groups'"' != "" {
				_statplot_hgparse `groups'
				local nG = `s(n)'
				forval gg = 1/`nG' {
					local Gspec`gg' `"`s(spec`gg')'"'
					local Glab`gg' `"`s(lab`gg')'"'
				}
			}

			// mark a heading before the FIRST variable each heading spec matches
			forval h = 1/`nH' {
				local sp `"`Hspec`h''"'
				local kk 0
				local done 0
				foreach v of local seq {
					local ++kk
					if `done' continue
					foreach tok of local sp {
						if strmatch("`v'", "`tok'") {
							local headAt`kk' `"`Hlab`h''"'
							local done 1
							continue, break
						}
					}
				}
			}

			// build reading rows top->bottom (heading rows + item rows)
			local R 0
			forval k = 1/`nseq' {
				if `"`headAt`k''"' != "" {
					local ++R
					local rHead`R' `"`headAt`k''"'
				}
				local ++R
				local rItem`R' `k'
			}

			// assign y (top = highest position); set xpos for items; label all rows
			forval r = 1/`R' {
				local y = `R' - `r' + 1
				if `"`rHead`r''"' != "" {
					label def `catlab' `y' `"`rHead`r''"', modify
				}
				else {
					local k `rItem`r''
					local v : word `k' of `seq'
					local _p : list posof "`v'" in origvl
					qui replace `xpos' = `y' if _vni==`_p'
					local _lab `"`olbl`_p''"'
					if `wrap' > 0 {
						_statplot_wrap , width(`wrap') text(`"`_lab'"')
						local _lab `"`s(wrapped)'"'
					}
					label def `catlab' `y' `"`_lab'"', modify
					local yOfK`k' = `y'
				}
			}
			local naxis = `R'

			// groups: bracket label at the midpoint of each matched span (axis 2)
			forval gg = 1/`nG' {
				local sp `"`Gspec`gg''"'
				local ymin .
				local ymax .
				local kk 0
				foreach v of local seq {
					local ++kk
					foreach tok of local sp {
						if strmatch("`v'", "`tok'") {
							if `ymin'>=. | `yOfK`kk''<`ymin' local ymin = `yOfK`kk''
							if `ymax'>=. | `yOfK`kk''>`ymax' local ymax = `yOfK`kk''
							continue, break
						}
					}
				}
				if `ymin'<. {
					local mid = (`ymin'+`ymax')/2
					local grouplab `"`grouplab' `mid' `"`Glab`gg''"'"'
				}
			}
			if `"`grouplab'"' != "" local phantom (scatteri 1 0 `naxis' 0, yaxis(2) msymbol(none))
		}
		else if `nvars' == 1 {
			// ---- one over, single variable: one bar per group ----
			if "`sort'" != "" {
				if "`descending'" != "" gsort -_mn
				else sort _mn
			}
			else sort `myby1'
			qui replace `xpos' = _n
			local naxis = _N
			forval j = 1/`naxis' {
				local gid = `myby1'[`j']
				label def `catlab' `j' `"`by1label`gid''"', modify
			}
		}
		else {
			// ---- one over, several variables: small multiples by variable ----
			local keyval ""
			forval i = 1/`nvars' {
				qui su _mn if _vni==`i', meanonly
				local keyval `keyval' `r(mean)'
			}
			_statplot_order , vlist(`varlist') keyval(`keyval') ///
				`sort' `descending' order(`order') first(`first') last(`last')
			local seq `s(seq)'
			tempvar panelv
			qui gen double `panelv' = .
			tempname plabel
			local p = 0
			foreach v of local seq {
				local ++p
				local _p : list posof "`v'" in origvl
				qui replace `panelv' = `p' if _vni==`_p'
				local _lab `"`olbl`_p''"'
				if `wrap' > 0 {
					_statplot_wrap , width(`wrap') text(`"`_lab'"')
					local _lab `"`s(wrapped)'"'
				}
				label def `plabel' `p' `"`_lab'"', modify
			}
			label val `panelv' `plabel'
			qui replace `xpos' = `myby1'
			local naxis = `by1max'
			forval j = 1/`naxis' {
				label def `catlab' `j' `"`by1label`j''"', modify
			}
			local byopt by(`panelv', legend(off) note(""))
		}
		label values `xpos' `catlab'
		local poslist ""
		forval j = 1/`naxis' {
			local poslist `poslist' `j'
		}

		// ---- expose the plotted numbers ----
		if `"`savedata'"' != "" | "`listdata'" != "" | "`frame'" != "" {
			tempfile _hold
			qui save `_hold'
			capture drop `xpos'
			capture drop `panelv'
			capture drop _one
			qui gen str32 variable = ""
			local i = 0
			foreach v of local origvl {
				local ++i
				qui replace variable = "`v'" if _vni==`i'
			}
			capture drop _vni
			capture rename _mn `statistic'
			if _rc rename _mn stat
			if `dowhisk' {
				rename _lo lo
				rename _hi hi
				rename _se se
				rename _ct N
			}
			if "`myby1'" != "" {
				capture rename `myby1' `by1var'
				if _rc {
					capture rename `myby1' _group1
					capture order _group1
				}
				else {
					capture label var `by1var' `"`by1label'"'
					capture order `by1var'
				}
			}
			else capture order variable
			if "`listdata'" != "" {
				if `dowhisk' di as txt _n "statplot: plotted values with `level'% CI"
				else di as txt _n "statplot: plotted values"
				list, noobs
			}
			if `"`savedata'"' != "" {
				gettoken _sdfile _sdrest : savedata, parse(",")
				local _sdrepl = cond(strpos(`"`_sdrest'"', "replace"), "replace", "")
				qui save `_sdfile', `_sdrepl'
			}
			if "`frame'" != "" {
				version 16: capture frame drop `frame'
				version 16: frame put *, into(`frame')
			}
			qui use `_hold', clear
		}

		tempvar zero
		qui gen double `zero' = 0
		if `dowhisk' local xti `"`ytitle' (`level'% CI)"'
		else local xti `"`ytitle'"'

		// draw bars with -rbar- from 0 to the statistic; whiskers only for ci
		if "`recast'" == "hbar" {
			local plots (rbar `zero' _mn `xpos', horizontal barwidth(.62) fcolor(navy) lcolor(navy) `baropts')
			if `"`phantom'"' != "" local plots `plots' `phantom'
			if `dowhisk' local plots `plots' (rcap _lo _hi `xpos', horizontal lcolor(black) `ciopts')
			local yopts ylabel(`poslist', valuelabel angle(0) noticks)
			if `"`grouplab'"' != "" local yopts `"`yopts' ylabel(`grouplab', axis(2) angle(0) noticks tlength(0)) yscale(range(1 `naxis') lstyle(none) axis(2)) ytitle("", axis(2))"'
			twoway `plots', `yopts' ytitle("") xtitle(`"`xti'"') legend(off) `byopt' `options'
		}
		else if "`recast'" == "bar" {
			local plots (rbar `zero' _mn `xpos', barwidth(.62) fcolor(navy) lcolor(navy) `baropts')
			if `dowhisk' local plots `plots' (rcap _lo _hi `xpos', lcolor(black) `ciopts')
			twoway `plots', xlabel(`poslist', valuelabel noticks) xtitle("") ytitle(`"`xti'"') ///
			       legend(off) `byopt' `options'
		}
		else {
			local plots
			if `dowhisk' local plots (rcap _lo _hi `xpos', horizontal lcolor(gs8) `ciopts')
			local plots `plots' (scatter `xpos' _mn, mcolor(navy) msize(medlarge))
			twoway `plots', ylabel(`poslist', valuelabel angle(0) noticks) ytitle("") xtitle(`"`xti'"') ///
			       legend(off) `byopt' `options'
		}
	}

	/// ---- rclass results ----
	return local cmd "statplot"
	return local statistic "`statistic'"
	return local varlist "`varlist'"
	return scalar N = `rN'
	return scalar N_vars = `nvars'
	if "`_Ngroups'" != "" return scalar N_groups = `_Ngroups'
	if "`ci'" != "" return scalar level = `level'
end


*-----------------------------------------------------------------------------
* helper: greedy word-wrap a label into compound-quoted multiline text.
* returns the (possibly multiline) string in s(wrapped).  width 0 = no change.
*-----------------------------------------------------------------------------
program _statplot_wrap, sclass
	syntax , Width(integer) [ Text(string) ]
	local txt `"`text'"'
	if `width' <= 0 | `"`txt'"' == "" {
		sreturn local wrapped `"`txt'"'
		exit
	}
	local nseg 0
	local line ""
	foreach word of local txt {
		if `"`line'"' == "" local cand `"`word'"'
		else                local cand `"`line' `word'"'
		if length(`"`cand'"') > `width' & `"`line'"' != "" {
			local ++nseg
			local seg`nseg' `"`line'"'
			local line `"`word'"'
		}
		else local line `"`cand'"'
	}
	if `"`line'"' != "" {
		local ++nseg
		local seg`nseg' `"`line'"'
	}
	// single line -> bare text; multiple lines -> compound-quoted multiline
	if `nseg' <= 1 {
		sreturn local wrapped `"`seg1'"'
		exit
	}
	local out ""
	forval q = 1/`nseg' {
		local out `"`out'"`seg`q''" "'
	}
	sreturn local wrapped `"`out'"'
end


*-----------------------------------------------------------------------------
* helper: order a varlist by value (sort/descending) and/or explicitly
* (order/first/last).  keyval is a parallel list, one number per variable in
* vlist order.  order/first/last are validated as subsets of vlist.  Uses only
* positional list operations (no per-variable macros) so long names are safe.
* Returns the ordered list in s(seq).
*-----------------------------------------------------------------------------
program _statplot_order, sclass
	syntax , vlist(str) [ keyval(str) sort DEScending order(str) first(str) last(str) ]

	foreach opt in order first last {
		if "``opt''" != "" {
			local bad : list `opt' - vlist
			if "`bad'" != "" {
				di as err "`opt'() contains variables not in varlist: `bad'"
				exit 198
			}
		}
	}

	local seq `vlist'
	if "`sort'" != "" & `"`keyval'"' != "" {
		local remaining `vlist'
		local remkeys `keyval'
		local sorted ""
		local nn : word count `remaining'
		while `nn' > 0 {
			local besti 1
			local bestk : word 1 of `remkeys'
			forval j = 2/`nn' {
				local kj : word `j' of `remkeys'
				if "`descending'" != "" {
					if `kj' > `bestk' {
						local besti `j'
						local bestk `kj'
					}
				}
				else if `kj' < `bestk' {
					local besti `j'
					local bestk `kj'
				}
			}
			local sorted `sorted' `: word `besti' of `remaining''
			local nr ""
			local nk ""
			forval j = 1/`nn' {
				if `j' != `besti' {
					local nr `nr' `: word `j' of `remaining''
					local nk `nk' `: word `j' of `remkeys''
				}
			}
			local remaining `nr'
			local remkeys `nk'
			local nn : word count `remaining'
		}
		local seq `sorted'
	}
	if "`order'" != "" {
		local rest : list seq - order
		local seq `order' `rest'
	}
	if "`first'" != "" {
		local rest : list seq - first
		local seq `first' `rest'
	}
	if "`last'" != "" {
		local rest : list seq - last
		local seq `rest' `last'
	}
	sreturn local seq `seq'
end


*-----------------------------------------------------------------------------
* helper: parse a headings()/groups() argument of the form
*   spec = "label" [spec = "label" ...]
* where each spec is one or more variable-name tokens (with * / ? wildcards).
* Returns s(n), s(spec1), s(lab1), s(spec2), ... in order.
*-----------------------------------------------------------------------------
program _statplot_hgparse, sclass
	local rest `"`0'"'
	local n 0
	while `"`rest'"' != "" {
		local eqpos = strpos(`"`rest'"', "=")
		if `eqpos' == 0 {
			local rest ""
			continue
		}
		local spec = trim(substr(`"`rest'"', 1, `eqpos'-1))
		local rest = substr(`"`rest'"', `eqpos'+1, .)
		gettoken lab rest : rest
		local ++n
		sreturn local spec`n' `"`spec'"'
		sreturn local lab`n' `"`lab'"'
	}
	sreturn local n `n'
end
