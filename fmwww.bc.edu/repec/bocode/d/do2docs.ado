*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* version 1.0.9 Niels Henrik Bruun	2020-08-23  added
program define do2docs, rclass
	syntax using/, [ ///
		DOCtype(string) Extension(string) Pandocstring(string) ///
        Timeout(integer 0) Cleanup Datestamp ///
		Bibliography(string) ///
        PAndocpath(string) ///
        Savein(string) ///
        SHow ///
		codestart(passthru) codeend(passthru) ///
		samplestart(passthru) sampleend(passthru)]

        
    *** Validation *************************************************************   
	confirm file `"`using'"'
    mata: st_local("__path", pathgetparent(`"`using'"'))
    mata: st_local("__base", pathbasename(pathrmsuffix(`"`using'"')))
    mata: st_local("__ext", pathsuffix(`"`using'"'))
    mata: st_local("__savein_exists", strofreal(direxists(`"`savein'"')))
    assert `"`__ext'"' == ".do"
	if "`datestamp'" != "" {
		local __date: display %td_CCYY_NN_DD date(c(current_date), "DMY")
		local __date = subinstr(trim("`__date'"), " " , "-", .)
		local __base `"`__date'_`__base'"'
	}
    if !`__savein_exists' mata: _error("Savein path do not exist!")
    if `"`savein'"' == `""' local savein `"`__path'"'
    if `"`savein'"' != `""' local savein `"`savein'/`__base'"'
    else local savein `"`__base'"'
    
    if `"`pandocpath'"' == "" local pandocpath `"C:/Program Files/Pandoc/pandoc.exe"'
    *capture confirm file `"`pandocpath'"'
    *if _rc local pandocpath `"C:/Program Files/Pandoc/pandoc.exe"'
    confirm file `"`pandocpath'"'
    if !regexm(`"`pandocpath'"', "pandoc.exe$")  mata: _error("No pandoc.exe path")

	if "`bibliography'" != "" {
        capture confirm file `"`bibliography'"'
        if _rc mata: _error("Path to bibliography file not found")
		local bibliography `"--bibliography `bibliography' --filter pandoc-citeproc"'	
	}
    if `"`doctype'"' != "" mata: set_doctype(`"`doctype'"')
    assert `"`extension'"' != ""

	local pandocstring `"-s `pandocstring' `bibliography' "`savein'.md" -o "`savein'.`extension'" "'
	
	if `timeout' > 0 local strtimeout "& timeout `timeout'"
	else local strtimeout ""
    
    *** Generate output ********************************************************
	local __linesize `c(linesize)'
	set linesize 255
	capture log close do2docs
	log using `"`savein'.log"', replace name(do2docs)
	do `"`using'"'
	log close do2docs
	set linesize `__linesize'

	log2markup using `"`savein'.log"', replace extension(md) ///
		`codestart' `codeend' `samplestart' `sampleend'

	*shell "`pandocpath'" `pandocstring' `strtimeout'
    shell pandoc `pandocstring' `strtimeout'

	if "`cleanup'" != "" {
		capture rm  `"`savein'.log"'
		capture rm  `"`savein'.md"'
	}
	
    macro drop __*
	return local pandocstring = `"`pandocstring'"'
    return local savein "`savein'.`extension'"
    if `"`show'"' != `""' shell "`savein'.`extension'"
end

mata:
    void set_doctype(string scalar doctype)
    {
        real colvector slct
        string matrix doctypes, selected
        
        // type, extension, pandocstring
        doctypes =  "beamer", "pdf", "-t beamer" \ 
                    "html", "html", "--mathjax" \
                    "pdf", "pdf", "" \
                    "latex", "tex", "" \
                    "tex", "tex", "" \
                    "word", "docx", "" \
                    "ppt", "pptx", "" \
                    "powerpoint", "pptx", ""
        slct = doctypes[.,1] :== strlower(doctype)
        selected = select(doctypes, slct)
        if ( selected != J(0,3,"") ){
            st_local("extension", selected[2])
            st_local("pandocstring", selected[3])
        }
    }
end
