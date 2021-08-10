*! version 1.0.1 MLB 13jul2017
program define smclpres, rclass
	version 8
	syntax using/, [replace dir(string) noNAVbar noSUBsec]
	
	// parse stub
	local stub : subinstr local using "/" "\", all
	while `"`stub'"' != "" {
		gettoken path stub : stub, parse("\")
	}
	local stub `path'
	gettoken stub suffix : stub, parse(".")

	// open files
	tempname base toc
	file open `base' using `"`using'"', read
	if `"`dir'"' != "" {
		local olddir `"`c(pwd)'"'
		qui cd `"`dir'"'
	} 
	file open `toc'  using "`stub'.smcl", write `replace' 
	file write `toc' "{smcl}" _n
	//================================================== first pass, build TOC
	
	local snr        = 1
	local lnr        = 1
	local toctxtopen = 0
	
	file read `base' line
	while r(eof) == 0 {
		gettoken first : line
		if `"`first'"' == "//slide" {
			if `"secname"' != "" & "`navbar'" == "" {
				local top`snr' `"{p 4 4 2}{cmd:`macval(secname)'}"'
				if `"`subsecname'"' != "" & "`subsec'" ==  "" {
					local top`snr' `"`macval(top`snr')' {hline 2} `macval(subsecname)'"'
				}
				local top`snr' `"`macval(top`snr')' {p_end}"'
			}
		}
		else if `"`first'"' == "//label" {
			gettoken first lab`snr' : line
			local incl `incl' `lnr'
		}
		else if `"`first'"' == "//section" {
			gettoken first secname : line
			file write `toc' _n `"{p 4 4 2}{view slide`snr'.smcl : `macval(secname)'}{p_end}"'_n
			local incl `incl' `lnr'
			local subsecname ""
		}
		else if `"`first'"' == "//subsection" {
			gettoken first subsecname : line
			file write `toc' `"{p 8 8 2}`macval(subsecname)'{p_end}"'_n
			local incl `incl' `lnr'
		}
		else if `"`first'"' == "//title" {
			gettoken first title`snr' : line
		}
		else if `"`first'"' == "//toctitle" {
			gettoken first toctitle : line
			file write `toc' `"{center:{bf:`macval(toctitle)'}}"'_n
			local incl `incl' `lnr'
		}
		else if `"`first'"' == "/*toctxt" {
			local toctxtopen = 1
		}
		else if `"`first'"' == "toctxt*/" {
			local toctxtopen = 0
		}
		else if `toctxtopen' {
			file write `toc' `"`macval(line)'"'_n
			local incl `incl' `lnr'
		}
		else if `"`first'"' == "//endslide" {
			if `"`lab`snr''"' == "" {
				local lab`snr' "next"
			}
			local snr = `snr' + 1
		}
		local `lnr++'
		file read `base' line
	}

	if `"`macval(secname)'"' == "" {
		file write `toc' _n`"{right:{view "slide1.smcl":`macval(lab1)'}}"' _n
	}

	file close `toc'
	file close `base'
	local kslides = `snr' - 1

	//========================================= second pass, build presentation
	if `"`dir'"' != "" {
		qui cd `"`olddir'"'
	}
	file open `base' using `"`using'"', read
	if `"`dir'"' != "" {
		qui cd `"`dir'"'
	}
	file read `base' line
	
	local snr          = 1
	local lnr          = 1
	local slideopen    = 0
	local exopen       = 0
	local txtopen      = 0
	
	while r(eof) == 0 {
		gettoken first : line
		if `"`first'"' == "//slide" {
			if `slideopen' {
				di as err "tried to open a new slide when one was already open on line `lnr'"
				exit 198
			}
			local exnr = 1
			tempname slide`snr'
			file open `slide`snr'' using "slide`snr'.smcl", write replace
			file write `slide`snr'' "{smcl}" _n
			if `"`top`snr''"' != "" {
				file write `slide`snr'' `"`top`snr''"' _n
				file write `slide`snr''  "{hline}" _n _n
			}
			local slideopen = 1
		}
		else if `"`first'"' == "//endslide" {
			if `slideopen' == 0 {
				di as err "tried to close a slide when none is open on line `lnr'"
				exit 198
			}
			local snrp1 = `snr' +1
			if `snr' < `kslides' {
				file write `slide`snr'' _n`"{view `stub'.smcl:Start} {right:{view "slide`snrp1'.smcl":`macval(lab`snrp1')'}}"' _n
			}
			else {
				file write `slide`snr'' _n`"{view `stub'.smcl:Start}"' _n
			}
			file close `slide`snr''
			local slideopen = 0
			local snr = `snrp1' 
		}
		else if `"`first'"' == "//ex" {
			if `exopen' {
				di as err "tried to open a new example when one was already open on line `lnr'"
				exit 198
			}
			tempname do`snr'ex`exnr'
			file open `do`snr'ex`exnr'' using "slide`snr'ex`exnr'.do", write replace
			file write `slide`snr'' "{cmd}" _n
			local exopen = 1
			
		}
		else if `"`first'"' == "//endex" {
			if `exopen' == 0 {
				di as err "tried to close an example when none was open on line `lnr'"
				exit 198
			}
			file write `slide`snr'' "{txt}{...}" _n
			file write `slide`snr'' `"{p 4 4 2}({stata "do slide`snr'ex`exnr'.do":click to run}){p_end}"' _n _n
			file close `do`snr'ex`exnr++''
			local exopen = 0
		}
		else if `"`first'"' == "//title" {
			if `slideopen' == 0 {
				di as err "tried adding a title when no slide was open on line `lnr'"
				exit 198
			}
			if `exopen' == 1 {
				di as err "tried adding a title when example was open on line `lnr'"
				exit 198
			}
			gettoken first title : line
			file write `slide`snr'' `"{center:{bf:`macval(title)'}}"' _n _n
		}
		else if `"`first'"' == "//txt" {
			if `slideopen' == 0 {
				di as err "tried adding text when no slide was open on line `lnr'"
				exit 198
			}
			if `exopen' == 1 {
				di as err "tried adding text when an example was open on line `lnr'"
				exit 198
			}
			gettoken first line : line
			file write `slide`snr'' `"`macval(line)'"' _n
		}
		else if `"`first'"' == "/*txt" {
			if `txtopen' == 1 {
				di as err "tried to open text on line `lnr' when text was already open"
				exit 198
			}
			if `exopen' == 1 {
				di as err "tried to open text on line `lnr' when example was open"
				exit 198
			}
			local txtopen = 1
		}
		else if `"`first'"' == "txt*/" {
			if `txtopen' == 0 {
				di as err "tried to close text on line `lnr' when text was not open"
				exit 198
			}
			file write `slide`snr'' _n
			local txtopen = 0
		}
		else if `txtopen' == 1 {
			file write `slide`snr'' `"`macval(line)'"' _n
		}
		else if `exopen' == 1 {
			file write `do`snr'ex`exnr''    `"`macval(line)'"' _n
			file write `slide`snr'' `"        `macval(line)'"' _n
		} 
		else {
			local ignored `ignored' `lnr'
		}
		local lnr = `lnr' + 1
		file read `base' line
	}

	if `slideopen' {
		di as err "end of base file, but a slide is still open"
		exit 198
	}
	if `exopen' {
		di as err "end of base file, but example is still open"
		exit 198
	}
	
	file close `base'

	return local ignored `: list ignored - incl'
	return local toc     `stub'.smcl
	return local dir `"`c(pwd)'"'
	
	local presdir "`c(pwd)'"
	
	if `"`dir'"' != "" {
		qui cd `"`olddir'"'
	}
	
	di as txt "{p}to view the presentation:{p_end}"
    di as txt "{p}first change the directory to where the presentation is stored:{p_end}"
    di `"{p}{stata `"cd "`presdir'""'}{p_end}"'
	di as txt "{p}Then type:{p_end}"
	di `"{p}{stata "view `stub'.smcl"}{p_end}"'
	
end
