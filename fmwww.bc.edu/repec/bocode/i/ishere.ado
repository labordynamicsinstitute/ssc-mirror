program define ishere
    version 17

   gettoken subcmd rest : 0
   local isfig = inlist(lower("`subcmd'"), "fig", "figure")
   local istab = inlist(lower("`subcmd'"), "tab", "table")
   local isdisplay = (lower("`subcmd'")=="display")

   if !`isfig' & !`istab' & !`isdisplay' {
    // first mode: act as placeholder in log-file for report generation
       exit
   }

   // second mode emitting markdown code for tables and figures
    syntax [anything] [using/] [, text(string) Height(string) Width(string) Zoom(string)]

    if "`zoom'"=="" & ("`height'"=="" & "`width'"=="") local zoom "100%"
    removequotes, t(`using')
    local using  `r(s)'
    local using = subinstr("`using'", "\", "/", .)
    local anything `anything'
    if lower("`anything'") == "fig" | lower("`anything'") == "figure"{
        // Process figure content from using clause or from log
        if "`using'" != ""{
            
            // Extract Extension
            local filepath `using'
            if strpos("`filepath'", ".") == 0 {
                display as error "Filepath must have an extension."
                exit 198
            }
            mata: st_local("extension", pathsuffix("`filepath'"))
            local extension = lower("`extension'")
            
            // Handle different image formats
            if inlist("`extension'", ".png", ".jpg", ".jpeg", ".svg", ".gif", ".bmp", ".webp") {
                if "`zoom'" != "" {
                    if strpos("`zoom'", "%") == 0 local zoom "`zoom'%"
                    di
                    display `"<img src="http://fmwww.bc.edu/repec/bocode/i/`filepath'" style="zoom:`zoom';">"'
                }
                else if "`height'" != "" | "`width'" != "" {
                    if "`width'" == "" local width "auto"
                    if "`height'" == "" local height "auto"
                    di
                    display `"<img src="http://fmwww.bc.edu/repec/bocode/i/`filepath'" width="`width'" height="`height'">"'
                }
                else {
                    di 
                    display "![](`filepath')"
                }
            }
            else {
                display as error "Unsupported image format: `extension'"
                exit 198
            }
        }
        // else {
        //     display as error "Figure option requires a file path using the using clause"
        //     exit 198
        // }
    }
    
    if lower("`anything'") == "tab" | lower("`anything'") == "table"{
        // Process table content from using clause
        if "`using'" != "" {
            local filepath `using'
            
            // Extract Extension
            if strpos("`filepath'", ".") == 0 {
                display as error "Filepath must have an extension."
                exit 198
            }
            mata: st_local("extension", pathsuffix("`filepath'"))
            local extension = lower("`extension'")
            
            // HTML Logic (iframe for html tables)
            if inlist("`extension'", ".html", ".htm") {
                if "`height'" == "" local height "400px"
                if "`width'" == "" local width "100%"
                di 
                display `"<iframe src='http://fmwww.bc.edu/repec/bocode/i/`filepath'' width='`width'' height='`height'' frameBorder='0'></iframe>"'
            }
            // Markdown files: emit placeholder for tohtml to inline the md source
            else if "`extension'" == ".md" {
                di
                display `"<iframe `filepath' ></iframe>"'
            }
            // CSV or other delimited files could be handled differently if needed
            else if inlist("`extension'", ".csv", ".txt") {
                display as error "CSV/Text files need special handling - not implemented yet"
                exit 198
            }
            // Other table formats (like exported LaTeX tables converted to HTML)
            else if inlist("`extension'", ".tex") {
                display as error "LaTeX files need conversion to HTML first"
                exit 198
            }
            else {
                // Default: treat as a link
                di 
                display "[Table](`filepath')"
            }
        }
        // else {
        //     display as error "Table option requires a file path using the using clause"
        //     exit 198
        // }
    }
    
    if ustrpos(`"`anything'"',"display")==1{
        gettoken display anything:anything
         display `anything'
    }

    // Support using `ishere` alone or `ishere ``` on a line to emit a code-block marker
    // remove whitespace from argument for robust comparison
    // local _a = subinstr("`anything'", " ", "", .)
    // if "`_a'" == "" | "`_a'" == "```" {
    //     di "```"
    //     exit
    // }

end


cap program drop removequotes
program define removequotes,rclass
	version 16
	syntax, [t(string)]
	return local s `t'
end
