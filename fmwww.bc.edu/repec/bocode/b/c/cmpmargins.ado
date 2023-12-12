program cmpmargins
	version 15.1

	syntax [anything] [if] [in] [aw pw fw iw] , cmplabel(string) saving(string asis) [ * ]

	di `"options: [`options']"'
	margins `anything' `if' `in' [`weight'`exp'] , `options' saving(`saving')

	if `"`cmplabel'"' != "" {
		local 0 `saving'
		syntax anything , [replace]
		// confirm file "`anything'"
		preserve
		drop _all
		qui use "`anything'"
		char _dta[cmp_label] `"`cmplabel'"'
		qui save, replace
		di `"{p 0 0 10}{txt}labelled `anything':{res} `: char _dta[cmp_label]'{p_end}"'
	}

end

