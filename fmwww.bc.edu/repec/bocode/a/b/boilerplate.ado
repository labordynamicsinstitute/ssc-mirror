*! version 1.2.0 13Nov2022 MLB 
program define boilerplate
	version 10
    syntax anything(id="file name" name=fn), [dta ana smclpres git noopen]
	
	opts_exclusive "`dta' `ana' `smclpres'"
	if "`dta'`ana'`smclpres'" == "" local dta "dta"
		
    // adds .do if fn has no suffix and makes locals stub and abbrev
	mata: Parsedirs(`"`fn'"')
	
	if "`smclpres'" == "" {
		normaldo, stub("`stub'") abbrev("`abbrev'") fn(`"`fn'"') `dta' `ana' `git'
	}
	else {
		smcldo, fn(`"`fn'"')
	}
	
	if "`open'" == "" {
		doedit "`fn'"
	}
end

program define normaldo
	syntax, stub(string) abbrev(string) fn(string) [dta ana git]
    
    tempname do
	file open  `do' using `fn', write text
    file write `do' "capture log close"_n
    file write `do' "log using `stub'.txt, replace text"_n
    file write `do' _n
    file write `do' "// What this .do file does"_n
    file write `do' "// Who wrote it"_n
    file write `do' _n
    file write `do' "version `c(stata_version)'"_n
    file write `do' "clear all"_n
    file write `do' "macro drop _all"_n
    file write `do' _n
	if "`dta'" != "" {
		if "`git'" == "" {
			file write `do' "*use ../posted/data/<original_data_file.dta>"_n	
		}
		else {
			file write `do' "*use ../protected/data/<original_data_file.dta>"_n
		}
		file write `do' _n
		file write `do' "*rename *, lower"_n
		file write `do' "*keep"_n
		file write `do' _n
		file write `do' "// prepare data"_n
		file write `do' _n
		file write `do' "*compress"_n
		file write `do' "*note: `abbrev'##.dta \ <description> \ `stub'.do \ <author> TS "_n
		file write `do' "*label data <description>"_n
		file write `do' "*datasignature set, reset"_n
		file write `do' "*save `abbrev'##.dta, replace"_n
	}
	if "`ana'" != "" {
        file write `do' "*use `abbrev'##.dta"_n
		file write `do' "*datasignature confirm"_n
		file write `do' "*codebook, compact"_n
		file write `do' _n
		file write `do' "// do your analysis"_n
	}
    file write `do' _n
    file write `do' "log close"_n
    file write `do' "exit"_n
    file close `do'
end

program define smcldo
	syntax, fn(string)
    tempname do
	file open  `do' using `fn', write text
	file write `do' `"//version #.#.#"'_n
	file write `do' `""'_n
	file write `do' `"//layout toc"'_n 
	file write `do' `"//toctitle"'_n
	file write `do' `""'_n
	file write `do' `"//titlepage --------------------------------------------------------------------"'_n
	file write `do' `"//title "'_n
	file write `do' `""'_n
	file write `do' `"/*txt"'_n
	file write `do' `"{center:Author}"'_n
	file write `do' `"{center:institution}"'_n
	file write `do' `""'_n
	file write `do' `"{center:email}"'_n
	file write `do' `"txt*/"'_n
	file write `do' `""'_n
	file write `do' `"//endtitlepage -----------------------------------------------------------------"'_n
    file write `do' `""'_n
    file write `do' `"// ............................................................................."'_n
	file write `do' `"//section"'_n
	file write `do' `""'_n
	file write `do' `"//slide ------------------------------------------------------------------------"'_n
	file write `do' `"//title "'_n
	file write `do' `""'_n
	file write `do' `"/*txt"'_n
	file write `do' `"{pstd}"'_n
	file write `do' `""'_n
	file write `do' `"txt*/"'_n
	file write `do' `""'_n
	file write `do' `"//ex"'_n
	file write `do' `""'_n
	file write `do' `"//endex"'_n
	file write `do' `""'_n
	file write `do' `"//slide ------------------------------------------------------------------------"'_n
    file close `do'
end

mata:
void Parsedirs(string scalar fn)
{
    string scalar    stub, suf
    string rowvector abbrev
    real   scalar    k

    suf = pathsuffix(fn)
    if (suf == "") st_local("fn", fn+".do")
    
    stub = pathbasename(fn)
    stub = pathrmsuffix(stub)
    st_local("stub", stub)

    abbrev = tokens(stub, "_")
    k = cols(abbrev)
    if (k < 3) {
        st_local("abbrev","<abbrev>")
    }
    else {
        k = k - 2
        abbrev = abbrev[1..k]
        abbrev = invtokens(abbrev, "")
        st_local("abbrev", abbrev)
    }
}
end
