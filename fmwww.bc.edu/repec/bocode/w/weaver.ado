/*******************************************************************************

					   Stata Weaver Package Version 1.0
					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de
										
								   July, 2014


								   
								   
								   
							   Package Description
								   
the Weaver ado file includes several programs which allow you to 
create dynamic reports directly from Stata do-file editor in HTML and PDF formats. 
The codes are presented in the following order:


1) Weaver Writing Codes 
		This part of the ado file includes the codes and commands that are used 
		for writing and styling the report. In short, these are the codes that 
		you will be using for writing the codes in the do-editor in Stata.
		
	
2) open Weaver 
		The weaver codes and all of the options are presented in this part of 
		the ado file. This part also includes most of the CSS codes that are
		used for styling the dynamic report. 


3) close Weaver 
		this part of the ado file includes the codes that are used for closing
		the report. In addition to Stata codes, it also inclused several 
		JavaScript codes that are used for styling the report and also, adding
		some functions to the report.  


4) report 
		this part of the ado file includes the codes that generate the report. 
		
		
		
		
		
                  The Weaver Package comes with no warranty    	*/








********************************************************************************
			      /*          Weaver Writing Codes           */
********************************************************************************
	
	
	/* ----     markup & mp    ---- */
	
	*quietly creates a log file
	program define markup
		version 11
		syntax [anything(name=smclfile id="The smclfile name is")]
		
		if "`r(status)'" == "on" {	
		
				local h = length("`r(filename)'")
				local h = `h'-5
				global log =  substr("`r(filename)'",1,`h')
				qui set more off
				qui set linesize 80
				}
		
		if "`r(status)'" ~= "on" {
		
				*define filename
				if "`smclfile'"~="" {
						global log `smclfile'
						}
		
				if "`smclfile'" == "" {
						global log markdown
						}	
		
				qui set more off
				quietly log using $log , replace
				qui set linesize 80
				}
		
	end
	
	program define mp
		version 11
		
		markup `0'
		
	end
	
	
	
	
	
	
	
	/* ----     markdown & md     ---- */
	program markdown
		version 11
		
		syntax [anything(name=smclfile id="The smclfile name is")], ///
		[erase] [html] [Pandoc(str)]
	
		//Global syntax processing		
		
		*check if Pandoc's path is defined
		if "`pandoc'" ~= "" {
					confirm file `"`pandoc'"'
					}
		
		if "`pandoc'" == "" {	
					if "`c(os)'"=="Windows" {
							local pandoc pandoc
							}

					if "`c(os)'"=="MacOSX" {
							local pandoc /usr/local/bin/pandoc
							cap confirm file "`pandoc'"
							}
							
					if "`c(os)'"=="Unix" {
							local pandoc /usr/bin/pandoc
							cap confirm file "`pandoc'"
							}
					}

			

		
		*default input file
		if "`smclfile'" == "" {
				
				*get the Pandoc default export file from "markup" command
				* which is the $log global
					
				confirm file $log.smcl
				
				cap qui log c
				di _n(2)
				
				*convert to HTML using MarkDoc 
				global useMarkDoc useMarkDoc
				
				markdoc $log, export(html) replace erase
				confirm file $log.html
						
				*if WEAVER is in use, append the HTML file to canvas
				if "$weaver" != "" cap confirm file `"$weaver"'
				
				tempname canvas needle
				tempfile memo
								
				cap set linesize $width  
				set more off   
		
				*openning the canvas
				cap file open `canvas' using `"$weaver"', ///
				write text append
								
				*reading the exported html file
				cap file open `needle' using $log.html, read
				cap file read `needle' line
								
				/* weave the html text to the canvas */
				while r(eof)==0 {
						cap file write `canvas' ///
						`"`line'"' _n      
						cap file read `needle' line    
						}	
				}
				
				
		if "`smclfile'" ~= "" & "`html'"=="" {
				
				cap qui log c
				
				*convert to HTML using MarkDoc 
				global useMarkDoc useMarkDoc
				
				markdoc `smclfile', export(html) replace `erase'
				confirm file "`smclfile'.html"
				
				*if WEAVER is in use, append the HTML file to canvas
				if "$weaver" != "" cap confirm file `"$weaver"'
				
				tempname canvas needle
				tempfile memo
								
				cap set linesize $width  
				set more off   
		
				*openning the canvas
				cap file open `canvas' using `"$weaver"', ///
				write text append
								
				*reading the exported html file
				cap file open `needle' using "`smclfile'.html", read
				cap file read `needle' line
								
				/* weave the html text to the canvas */
				while r(eof)==0 {
						cap file write `canvas' `"`line'"' _n      
						cap file read `needle' line    
						}	
				}
		
		
		if "`smclfile'" ~= "" & "`html'"=="html" {
				
				*confirm the html document
				confirm file "`smclfile'.html"
				
				*if WEAVER is in use, append the HTML file to canvas
				if "$weaver" != "" cap confirm file `"$weaver"'
				
				tempname canvas needle
				tempfile memo
								
				cap set linesize $width  
				set more off   
		
				*openning the canvas
				cap file open `canvas' using `"$weaver"', ///
				write text append
								
				*reading the exported html file
				cap file open `needle' using "`smclfile'.html", read
				cap file read `needle' line
								
				/* weave the html text to the canvas */
				while r(eof)==0 {
						cap file write `canvas' ///
						`"`line'"' _n      
						cap file read `needle' line    
						}	
				}
				
				
				macro drop pandoc
				macro drop useMarkDoc
	end

	
	
	
	program md
		version 11
		
		markdown `0'
		
	end
	
	
	
	
	
	/* ----     knit & kn    ---- */
	
	* knit prints a text paragraph in <p> "text" </p> html format
	program define knit
        version 11
		
        if "$weaver" != "" cap confirm file `"$weaver"'

        tempname canvas
        cap file open `canvas' using `"$weaver"', write text append
		
        cap file write `canvas' "<p>" 
		cap file write `canvas' `"`0'"'		
		cap file write `canvas' "</p>" _n
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}    
	end
	
	
	
	program define kn
        version 11
		
        knit `0'
		
	end
	
	
	
	
	/* ----     div     ---- */
	
	* separates the codes from the results and shows them in separate boxes
	program define div
	version 11
		
		set linesize $width
		
		if "$weaver" != "" cap confirm file `"$weaver"' 

        tempname canvas needle
        tempfile memo
		
        /* open new log, run command and close log */
		set linesize $width  
        set more off    
        
		
		/* saving the results in `memo' */
		cap log c
		quietly log using `memo', replace text
		`0'
		cap quietly log close
                        
						
        /* Using existing log */
        if `"`r(filename)'"' != "" {
                set linesize $width
                cap quietly log using r(filename), append r(type)
                if r(status) != "on" quietly log r(status)
				}
        
        /* open the canvas and print the Stata codes in the code tag */
        cap file open `canvas' using `"$weaver"', write text append 
		cap file write `canvas' "<code>"`"`0'"'"</code>"
		
		/* openning the results tag */
		cap file write `canvas' "<results>"
		
		/* reading the results from the log file */
		cap file open `needle' using `memo', read
        cap file read `needle' line
		
		/* writing the results to the html file */
        while r(eof)==0 {
                cap file write `canvas' `"`line' "' _n      
                cap file read `needle' line
				}
		
		/* closing the results tag */
		cap file write `canvas' "</results>"
		
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}    
		
	end
	

	
	
		
		
	/* ----     codes & cod     ---- */
		
	* show The Code and Hide the Results
	program codes
		version 11
		
		qui `0'		   
        
		if "$weaver" != "" cap confirm file `"$weaver"'
		
		if "$style" == "elegant" {
				local add style="border-radius:10px;"
				}
				
        tempname canvas
        cap file open `canvas' using `"$weaver"', write text append
		cap file write `canvas' `"<code `add'> `0' </code>"' _newline
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}
	end
	
	

	program cod
		version 11
		
		qui `0'		   
        
		if "$weaver" != "" cap confirm file `"$weaver"'
		
		if "$style" == "elegant" {
				local add style="border-radius:10px;"
				}
				
        tempname canvas
        cap file open `canvas' using `"$weaver"', write text append
		cap file write `canvas' `"<code `add'> `0' </code>"' _newline
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}
	
	end
	
	
	
	
	
	
	
	/* ----     results & res     ---- */
		
	* The result command only shows the results, eliminating the code
	program define results
		version 11
        
		
		set linesize $width
		
		if "$weaver" != "" cap confirm file `"$weaver"' 

        tempname canvas needle
        tempfile memo
		
        /* open new log, run command and close log */
		set linesize $width  
        set more off    
        
		
		/* saving the results in `memo' */
		cap log c
		quietly log using `memo', replace text
		`0'
		quietly log close
                        
						
        /* Open previous log */
        if `"`r(filename)'"' != "" {
                set linesize $width
                quietly log using r(filename), append r(type)
                if r(status) != "on" quietly log r(status)
				}
        
        /* open the canvas and print the Stata results in the results tag */
        cap file open `canvas' using `"$weaver"', write text append
		
		
		cap file write `canvas' `"<result>"'
		
				
		/* reading the results from the log file */
		cap file open `needle' using `memo', read
        cap file read `needle' line
		
		/* writing the results to the html file */
        while r(eof)==0 {
                cap file write `canvas' `"`line' "' _n      
                cap file read `needle' line
				}
		
		/* closing the results tag */
		cap file write `canvas' "</result>"
		
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}    
	end
	
	program define res
		version 11
        
		
		set linesize $width
		
		if "$weaver" != "" cap confirm file `"$weaver"' 

        tempname canvas needle
        tempfile memo
		
        /* open new log, run command and close log */
		set linesize $width  
        set more off    
        
		
		/* saving the results in `memo' */
		cap log c
		quietly log using `memo', replace text
		`0'
		quietly log close
                        
						
        /* Open previous log */
        if `"`r(filename)'"' != "" {
                set linesize $width
                quietly log using r(filename), append r(type)
                if r(status) != "on" quietly log r(status)
				}
        
        /* open the canvas and print the Stata results in the results tag */
        cap file open `canvas' using `"$weaver"', write text append
		
		
		cap file write `canvas' `"<result>"'
		
				
		/* reading the results from the log file */
		cap file open `needle' using `memo', read
        cap file read `needle' line
		
		/* writing the results to the html file */
        while r(eof)==0 {
                cap file write `canvas' `"`line' "' _n      
                cap file read `needle' line
				}
		
		/* closing the results tag */
		cap file write `canvas' "</result>"
		
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}    
	end
	
	
	
	
	
	
	
	/* ----     img     ---- */
		
	* importing graphs and images into the report.
	program define img
        version 11
        syntax anything, [Width(numlist max=1 >0 <=1000)] ///
		[Height(numlist max=1 int >0 <=1000)] [left|center|right]
		
		if "$weaver" != "" {
		
				cap confirm file `"$weaver"'
		
				tempname canvas
				file open `canvas' using `"$weaver"', write text append
		

				if "$format" == "normal" & missing("`width'") {
						local width 694
						}
		
				if "$format" == "normal" & missing("`height'") {
						local height 494
						}
		
				if "$format" == "landscape" & missing("`width'") {
						local width 1020
						}
		
				if "$format" == "landscape" & missing("`height'") {
						local height 694
						}
		
		
				if 	"$format" == "normal" & `width' > 694 {
						display as error "image width cannot be more than 694 " ///
						"pixles, unless you choose the {help landscape} option " ///
						"from the {help weave} command"
						exit 198
						}
				
				if 	"$format" == "normal" & `height' > 1000 {
						display as error "image height cannot be more than 1000 pixles"
						exit 198
						}
				
				if 	"$format" == "landscape" & `width' > 1020 {
						display as error "image width cannot be more than 1000 pixles"
						exit 198
						}
				
				if 	"$format" == "landscape" & `height' > 694 {
						display as error "image height cannot be more than 694 " ///
						"pixles, unless you {bf:remove} the {help landscape} " ///
						"option from the {help weave} command"
						exit 198
						}			
		

				*check that only one of the align options is selected
				if "`left'" == "left" & "`center'" == "center" | ///
				"`left'" == "left" & "`right'" == "right" | ///
				"`center'" == "center" & "`right'" == "right" {
		
						di as err `"only one of the {bf:left}, "' ///
						`"{bf:center}, or {bf:right} can be applied"'
						exit 198
						}
		
				*defining the default image alignment
				if missing("`left'") & missing("`center'") & missing("`right'") {
						local left left
						}
		
				if "`left'" == "left" {
						file write `canvas' `"<img rel="zoom"  src="`anything'" "' ///
						`"width="`width'" height="`height'" >"' _newline 
						}
   
				if "`center'" == "center" {
						file write `canvas' `"<img rel="zoom"  src="`anything'" "' ///
						`"class="center"   width="`width'" height="`height'" >"' _newline 
						}
		
				if "`right'" == "right" {
						file write `canvas' `"<img rel="zoom"  src="`anything'" "' ///
						`"align="`right'"  width="`width'" height="`height'" >"' _newline 
						}
				
				}
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				} 
		
	end
	
	

	

	

	

	/* ----     html code     ---- */
		
	* adds html code
	program define html
        version 11
        
        if "$weaver" != "" cap confirm file `"$weaver"'

        tempname canvas
        cap file open `canvas' using `"$weaver"', write text append         
		cap file write `canvas' `"`0'"' _n
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}      
	end
	
	





	/* ----     linebreak     ---- */
		
	* moves to the next line */
	program define linebreak
        version 11
        
        if "$weaver" != "" cap confirm file `"$weaver"'

        tempname canvas
        cap file open `canvas' using `"$weaver"', write text append         
		cap file write `canvas' "<br />" _n
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}      
	end
	






	/* ----     pagebreak     ---- */
		
	* page break, moving to the next page (only appears in prints and PDF) */
	program pagebreak
	
        if "$weaver" != "" cap confirm file `"$weaver"'

        tempname canvas
        cap file open `canvas' using `"$weaver"', write text append
		cap file write `canvas'	`"<div class= "pagebreak" ></div>"' _n
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}     
	end

	
	
	
	
	


	/* ----     quote & quo    ---- */
		
	* creates a distinguished text box to make a point, summary, etc.
	program define quote
		version 11
        
		if "$weaver" != "" cap confirm file `"$weaver"'

		tempname canvas
		cap file open `canvas' using `"$weaver"', write text append
		cap file write `canvas' `"<p class="code">"' _n
		cap file write `canvas' `"`0'"' _n
		cap file write `canvas' "</p>" _n
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}    
	end
		
	
	program define quo	
		version 11
		
		quote `0'
	
	end
	
	
	

********************************************************************************
				    /*            open Weaver              */
********************************************************************************


	program define weave
        version 11
        syntax using/, [append|replace] [Erase] [UNbreak] [Title(str)] ///
		[AUthor(str)] [AFFiliation(str)] [ADDress(str)] [Date] ///
		[RUNhead(str)] [SUMmary(str)] [CONTents] [LANDscape] ///
		[STYle(name)] [NOScheme] [Font(str)] [Printer(name)] [SETpath(str)]
        
		
		
		//CHECKING THE COMMANDS AND OPTIONS
		
		*Store the current scheme
		global savescheme `c(scheme)'
		
		/* check if the HTML canvas is in use */
        if "$weaver" != "" {
                di as err `"You are still weaving the $weaver canvas. "' ///
				`"To begin a new canvas, type {stata weavend} to close "' ///
				`"the current canvas."'
				exit 110
				}    
		
		/*check that append and replace options are not used together */
        if "`append'" != "" & "`replace'" != "" {
                di as err `"Oops! You cannot use {bf:append} and "' ///
				`"{bf:replace} options together."'
                exit 198
				}       
		
		if "`erase'" == "erase" {
				global erase erase
				}
				
		if `"`landscape'"' == "landscape" {
				global format landscape
                global width 150
				}
		
		if `"`landscape'"' != "landscape" {
				global format normal
                global width 90
				}
		
		*check the printer names
		if "`printer'" == "princexml" {
				local printer prince
				}
		
		if "`printer'" == "wk" {
				local printer wkhtmltopdf
				}
		
		if "`printer'" ~= "" & "`printer'" ~= "prince" & "`printer'" ///
		~= "wkhtmltopdf" {
				di as err "Printer name can be {bf:prince} or {bf:wkhtmltopdf}}"
                exit 198
				}
		
		/*check that printer and setpath both are used together */
        if "`printer'" == "" & "`setpath'" != "" {
                di as err `"If you specify the {bf:ptinter path}"' ///
				`" you should also use the {bf:printer(name) option }"'
                exit 198
				}  
		
		*define the printer's global
		global printer `printer'
		
		
		*check the Printer path
		if "`setpath'" ~= "" {
				global path `"`setpath'"'
				confirm file "$setpath"
				}
		
		
		/* Setup Style & Font */
		global style `style'
		
		if "`style'" ~= "" & "`style'" ~= "modern" & "`style'" ~= "minimal" ///
				& "`style'" ~= "elegant" & "`style'" ~= "classic" ///
				& "`style'" ~= "stata" {
				di as err `"Style option can be {bf:classic}, {bf:modern},"' ///
				`" {bf:stata}, {bf:elegant}, or {bf:minimal}"'
                exit 198
				}
		
		if "`style'" == "" | "`style'" == "modern" {
				if "`font'"=="" & "`printer'"=="prince" {
						local font Calibri, Arial, Helvetica, sans-serif
						}
				if "`font'"=="" & "`printer'"~="prince" {
						local font Arial, Helvetica, sans-serif
						}
						
				if "`noscheme'" == "" {
						set scheme s2color8
						}
				
				}
		
		if "`style'" == "classic" {
				if "`font'"=="" {
						local font Times New Roman, Times, serif
						}
						
				if "`noscheme'" == "" {
						set scheme s1color
						}		
				}
				
		
		
		if "`style'" == "minimal" {
				if "`font'"=="" {
						local font Courier New, Courier, monospace
						}
						
				if "`noscheme'" == "" {
						set scheme lean2
						}			
				}
				
		if "`style'" == "elegant" {
				if "`font'"=="" & "`printer'"=="prince" {
						local font Calibri, Arial, Helvetica, sans-serif
						}
				if "`font'"=="" & "`printer'"~="prince" {
						local font Arial, Helvetica, sans-serif
						}
						
				if "`noscheme'" == "" {
						set scheme s1color
						}			
				}

		
		if "`style'" == "stata" {
				if "`font'"=="" & "`printer'"=="prince" {
						local font Calibri, Arial, Helvetica, sans-serif
						}
				if "`font'"=="" & "`printer'"~="prince" {
						local font Arial, Helvetica, sans-serif
						}
						
				if "`noscheme'" == "" {
						set scheme s2color
						}			
				}

						
				
		/*----- DEFINING THE FILE NAMES -----*/	
		
		/* PDF file */
		global pdfdoc `"`using'.pdf"'
		
		/* CANVAS file*/
		local using `"`using'.html"'
		
		/* HTML file */
		global htmldoc `"`using'"'
				
			
		/* creating the HTML canvas */
        tempname canvas 
        capture file open `canvas' using `"`using'"', write text ///
		`append' `replace' 
		
		/* checking if the HTML canvas already exists */
        if _rc == 602 { 
				di as err `"Oops! `using' canvas is already weaved!"' ///
				`"Use {bf:append} or {bf:replace} options to extend or"' ///
				`"replace the existing canvas."'
				exit 602
				}
        
		if "`append'" == "" {
				/* defining HTML5 */
                file write `canvas' `"<!doctype html>"' _n
				file write `canvas' `"<html>"' _n
				file write `canvas' "<head>" _n
				file write `canvas' `"<meta charset="UTF-8">"' _n
				
				if `"`title'"' ~= "" {
						file write `canvas' `"<title>`title'</title>"' _n
						}






		/* MODERN (DEFAULT) STYLE */
		
		if "`style'" == "" | "`style'" == "modern" {
		
		file write `canvas' _n(2) "<!-- Modern Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "font-size:28px;" _newline ///
		_skip(8) "padding-bottom:20px; " _newline ///
		_skip(8) "margin:0px 0 20px 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///		
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "margin:24px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "color:#17365D;" _newline ///
		_skip(8) "font-size: 22px;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1 > a:hover, h1 > a:hover{" _newline ///
		"color:#345A8A;" _newline ///
		"} " _newline(2) ///
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "color:#345A8A;" _newline ///
		_skip(8) "font-size: 18px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "color:#4F81BD;" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4, .h4 {" _newline ///
		_skip(8) "margin:10px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "color:#4F81BD;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5, .h5 {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "color:#4F81BD;" _newline ///
		_skip(8) "}" _newline(2) ///				
"h6, .h6 {"  _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "color:#4F81BD;" _newline ///
		_skip(8) "}" _newline(2) ///
"p {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height: 16px;" _newline ///
		_skip(8) "margin-bottom:10px;" _newline ///
		_skip(8) "}" _newline(2) ///
"code, p > code {" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "padding: 4px 4px 2px 5px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height:16px;" _newline ///
		_skip(8) "background-color:#E1E6F0;" _newline ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #345A8A; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
		_skip(8) "}" _newline(2) ///
".code, #code {" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "margin: 15px 30px 15px 30px;" _newline /// 
		_skip(8) "padding: 15px 15px 15px 15px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height:16px;" _newline ///
		_skip(8) "background-color:#E1E6F0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #345A8A; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "}" _newline(2) ///			
"onlycode {" _newline ///		
		_skip(8) "color: black;" _newline ///
        _skip(8) "padding: 4px 4px 2px 5px;" _newline /// 
        _skip(8) "display:block;" _newline ///
        _skip(8) "font-size:14px;" _newline ///
        _skip(8) "line-height:16px;" _newline ///
        _skip(8) "background-color:#DDD;" _newline ///
        _skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
        _skip(8) "text-shadow:#FFF;" _newline ///
        _skip(8) "margin-top:5px;" _newline ///
		/*_skip(8) "border-radius:10"  
*/		_skip(8) "}" _newline(2) ///
"results, pre > code {" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #345A8A; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "border-top-style:none;" _newline /// 
		_skip(8) "}" _newline(2) ///
"result {" _newline ///
		_skip(8) "display: block;" _newline ///
	  	_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:11px; " _newline ///
		_skip(8) "line-height: 11px;" _newline ///
		_skip(8) "}" _newline(2) ///		
".border, #border {" _n ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "}" _newline(2) ///	
"resultbox {" _newline ///
		_skip(8) "display: block;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "white-space:pre;" _newline ///
	  	_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:11px; " _newline ///
		_skip(8) "line-height: 11px;" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "}" _newline(2) ///		
"</style>" _newline(4)
}		
		

		
		
		
		
		/* Stata STYLE */
		
		if "`style'" == "stata" {
		
		file write `canvas' _n(2) "<!-- Stata Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "font-size:28px;" _newline ///
		_skip(8) "padding-bottom:20px; " _newline ///
		_skip(8) "margin:0px 0 20px 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///		
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "margin:24px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 22px;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1 > a:hover, h1 > a:hover{" _newline ///
		"color:#345A8A;" _newline ///
		"} " _newline(2) ///
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 18px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4, .h4 {" _newline ///
		_skip(8) "margin:10px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5, .h5 {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "}" _newline(2) ///				
"h6, .h6 {"  _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"p {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height: 16px;" _newline ///
		_skip(8) "margin-bottom:10px;" _newline ///
		_skip(8) "}" _newline(2) ///
"code, p > code {" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "padding: 4px 4px 2px 5px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:12px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "line-height:16px;" _newline ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "background-color:#EAF2F3;" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #D2DADC; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "margin-top:10px;" _newline ///
		_skip(8) "}" _newline(2) ///
".code, #code {" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "margin: 15px 30px 15px 30px;" _newline /// 
		_skip(8) "padding: 15px 15px 15px 15px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height:16px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "background-color:#EAF2F3;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #D2DADC; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "border-radius:10px;" _n ///
		_skip(8) "}" _newline(2) ///				
"onlycode {" _newline ///		
		_skip(8) "color: black;" _newline ///
        _skip(8) "padding: 4px 4px 2px 5px;" _newline /// 
        _skip(8) "display:block;" _newline ///
        _skip(8) "font-size:14px;" _newline ///
        _skip(8) "line-height:16px;" _newline ///
        _skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
        _skip(8) "text-shadow:#FFF;" _newline ///
        _skip(8) "margin-top:5px;" _newline ///
		_skip(8) "border-radius:10" ///	
		_skip(8) "}" _newline(2) ///
"results, pre > code {" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #D2DADC; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "border-top-style:none;" _newline /// 
		_skip(8) "}" _newline(2) ///
"result {" _newline ///
		_skip(8) "display: block;" _newline ///
	  	_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:11px; " _newline ///
		_skip(8) "line-height: 11px;" _newline ///
		_skip(8) "}" _newline(2) ///		
".border, #border {" _n ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "}" _newline(2) ///	
"resultbox {" _newline ///
		_skip(8) "display: block;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "white-space:pre;" _newline ///
	  	_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:11px; " _newline ///
		_skip(8) "line-height: 11px;" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "}" _newline(2) ///		
"</style>" _newline(4)
}		

		
		
		
		
		
		/* CLASSIC STYLE */
		
		if "`style'" == "classic" {
		
		file write `canvas' _n(2) "<!-- CLASSIC Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "font-size:28px;" _newline ///
		_skip(8) "padding-bottom:20px; " _newline ///
		_skip(8) "margin:0px 0 20px 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///		
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "margin:24px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 22px;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1 > a:hover, h1 > a:hover{" _newline ///
		"color:#345A8A;" _newline ///
		"} " _newline(2) ///
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 18px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4, .h4 {" _newline ///
		_skip(8) "margin:10px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5, .h5 {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "}" _newline(2) ///				
"h6, .h6 {"  _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"p {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height: 16px;" _newline ///
		_skip(8) "margin-bottom:10px;" _newline ///
		_skip(8) "}" _newline(2) ///
"code, p > code {" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "padding: 4px 4px 2px 5px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height:16px;" _newline ///
		_skip(8) "background-color:#EBEBEB;" _newline ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #EBEBEB; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
		_skip(8) "}" _newline(2) ///
".code, #code {" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "margin: 15px 30px 15px 30px;" _newline /// 
		_skip(8) "padding: 15px 15px 15px 15px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height:16px;" _newline ///
		_skip(8) "background-color:#EBEBEB;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #EBEBEB; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "}" _newline(2) ///				
"onlycode {" _newline ///		
		_skip(8) "color: black;" _newline ///
        _skip(8) "padding: 4px 4px 2px 5px;" _newline /// 
        _skip(8) "display:block;" _newline ///
        _skip(8) "font-size:14px;" _newline ///
        _skip(8) "line-height:16px;" _newline ///
        _skip(8) "background-color:#DDD;" _newline ///
        _skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
        _skip(8) "text-shadow:#FFF;" _newline ///
        _skip(8) "margin-top:5px;" _newline ///
		/*_skip(8) "border-radius:10"  
*/		_skip(8) "}" _newline(2) ///
"results, pre > code {" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "border-top-style:none;" _newline /// 
		_skip(8) "}" _newline(2) ///
"result {" _newline ///
		_skip(8) "display: block;" _newline ///
	  	_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:11px; " _newline ///
		_skip(8) "line-height: 11px;" _newline ///
		_skip(8) "}" _newline(2) ///		
".border, #border {" _n ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "}" _newline(2) ///	
"resultbox {" _newline ///
		_skip(8) "display: block;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "white-space:pre;" _newline ///
	  	_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:11px; " _newline ///
		_skip(8) "line-height: 11px;" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "}" _newline(2) ///		
"</style>" _newline(4)
}		
	
	
	
	
	
	
		/* MINIMAL STYLE */
		
		if "`style'" == "minimal" {
		
		file write `canvas' _n(2) "<!-- Minimal Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "font-size:28px;" _newline ///
		_skip(8) "padding-bottom:20px; " _newline ///
		_skip(8) "margin:0px 0 20px 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///		
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "margin:24px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 22px;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1 > a:hover, h1 > a:hover{" _newline ///
		"color:#345A8A;" _newline ///
		"} " _newline(2) ///
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 18px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4, .h4 {" _newline ///
		_skip(8) "margin:10px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5, .h5 {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "}" _newline(2) ///				
"h6, .h6 {"  _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"p {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height: 16px;" _newline ///
		_skip(8) "margin-bottom:10px;" _newline ///
		_skip(8) "}" _newline(2) ///
"code, p > code {" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "padding: 4px 4px 2px 5px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:12px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "line-height:16px;" _newline ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
		_skip(8) "background-color:#EBEBEB;" _newline ///
        _skip(8) "border-style: dotted;" _newline ///
		_skip(8) "margin-top:10px;" _newline ///
		_skip(8) "border-radius:10px" ///
		_skip(8) "}" _newline(2) ///
".code, #code {" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "margin: 15px 30px 15px 30px;" _newline /// 
		_skip(8) "padding: 15px 15px 15px 15px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height:16px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "background-color:#EBEBEB;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #828282; " _newline ///
        _skip(8) "border-style: dotted;" _newline ///
		_skip(8) "}" _newline(2) ///				
"onlycode {" _newline ///		
		_skip(8) "color: black;" _newline ///
        _skip(8) "padding: 4px 4px 2px 5px;" _newline /// 
        _skip(8) "display:block;" _newline ///
        _skip(8) "font-size:14px;" _newline ///
        _skip(8) "line-height:16px;" _newline ///
        _skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
        _skip(8) "text-shadow:#FFF;" _newline ///
        _skip(8) "margin-top:5px;" _newline ///
		_skip(8) "border-radius:10" ///	
		_skip(8) "}" _newline(2) ///
"results, pre > code {" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:none;" _newline /// 
		_skip(8) "}" _newline(2) ///
"result {" _newline ///
		_skip(8) "display: block;" _newline ///
	  	_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:11px; " _newline ///
		_skip(8) "line-height: 11px;" _newline ///
		_skip(8) "}" _newline(2) ///		
".border, #border {" _n ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "}" _newline(2) ///	
"resultbox {" _newline ///
		_skip(8) "display: block;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "white-space:pre;" _newline ///
	  	_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:11px; " _newline ///
		_skip(8) "line-height: 11px;" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "}" _newline(2) ///		
"</style>" _newline(4)
}		





		/* ELEGANT STYLE */
		
		if "`style'" == "elegant" {
		
		file write `canvas' _n(2) "<!-- ELEGANT Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "font-size:28px;" _newline ///
		_skip(8) "padding-bottom:20px; " _newline ///
		_skip(8) "margin:0px 0 20px 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///		
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "margin:24px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 22px;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1 > a:hover, h1 > a:hover{" _newline ///
		"color:#345A8A;" _newline ///
		"} " _newline(2) ///
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 2px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 18px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "margin:14px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4, .h4 {" _newline ///
		_skip(8) "margin:10px 0px 0px 0px;" _newline ///
		_skip(8) "padding: 0;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 16px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5, .h5 {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-size: 14px;" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "}" _newline(2) ///				
"h6, .h6 {"  _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "}" _newline(2) ///
"p {" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height: 16px;" _newline ///
		_skip(8) "margin-bottom:10px;" _newline ///
		_skip(8) "}" _newline(2) ///
"code, p > code {" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "padding: 4px 4px 2px 5px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:12px;" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "line-height:16px;" _newline ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "background-color:#EBEBEB;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #EBEBEB; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "margin:10px 0 5px 0;" _newline ///
		_skip(8) "border-radius:10px;" _n ///
		_skip(8) "}" _newline(2) ///
".code, #code {" _newline ///
		_skip(8) "color: black;" _newline ///
		_skip(8) "margin: 15px 30px 15px 30px;" _newline /// 
		_skip(8) "padding: 15px 15px 15px 15px;" _newline /// 
		_skip(8) "display:block;" _newline ///
		_skip(8) "font-size:14px;" _newline ///
		_skip(8) "line-height:16px;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "background-color:#EBEBEB;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "text-shadow:#FFF;" _newline ///
		_skip(8) "border:thin;" _newline ///
        _skip(8) "border-color: #EBEBEB; " _newline ///
        _skip(8) "border-style: solid;" _newline ///
		_skip(8) "border-radius:10px;" _n ///
		_skip(8) "}" _newline(2) ///				
"onlycode {" _newline ///		
		_skip(8) "color: black;" _newline ///
        _skip(8) "padding: 4px 4px 2px 5px;" _newline /// 
        _skip(8) "display:block;" _newline ///
        _skip(8) "font-size:14px;" _newline ///
        _skip(8) "line-height:16px;" _newline ///
        _skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
        _skip(8) "text-shadow:#FFF;" _newline ///
        _skip(8) "margin-top:5px;" _newline ///
		_skip(8) "border-radius:10" ///	
		_skip(8) "}" _newline(2) ///
"results, pre > code {" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-bottom-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "border-top-style:none;" _newline /// 
		_skip(8) "}" _newline(2) ///
"result {" _newline ///
		_skip(8) "display: block;" _newline ///
	  	_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:11px; " _newline ///
		_skip(8) "line-height: 11px;" _newline ///
		_skip(8) "}" _newline(2) ///		
".border, #border {" _n ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "}" _newline(2) ///	
"resultbox {" _newline ///
		_skip(8) "display: block;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "white-space:pre;" _newline ///
	  	_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "font-size:11px; " _newline ///
		_skip(8) "line-height: 11px;" _newline ///
		_skip(8) "margin-bottom:5px;" _newline ///
		_skip(8) "border:thin; " _newline ///
		_skip(8) "border-color: #EBEBEB; " _newline ///
		_skip(8) "border-style: solid; " _newline ///
		_skip(8) "padding:5px 0 10px 5px;" _newline ///
		_skip(8) "}" _newline(2) ///		
"</style>" _newline(4)
}		


		/*----- CSS STYLING -----*/
		
		file write `canvas'  _n(2) ///
		"<!-- General Style  -->" _newline(2) ///
		`"<style type="text/css">"' _newline ///
"body {" _newline(2) ///
		_skip(8) "min-height:900px;" _newline ///
		_skip(8) "margin:10px 30px 10px 30px;" _newline /// 
		_skip(8) "font-family: `font';" _newline ///
		_skip(8) "}" _newline(2) ///
"@page {" _newline ///
		_skip(8) "size: auto;" _newline ///
        _skip(8) "margin: 10mm 20px 15mm 20px;" _newline ///
		_skip(8) "color:#828282;" _newline ///
		_skip(8) "font-family: `font';" _newline ///
		`" @top-left "' ///
		`"{ content: "`runhead'" ; font-size:11px; margin-top:5px; } "' _n /// 
		"@bottom {" _newline ///
		_skip(8) `"content: "Page " counter(page); font-size:14px; "' _n ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
"@page:first {" _newline ///
		"@top-left {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		"@bottom {" _newline ///
		_skip(8) "content: normal" _newline ///
		_skip(8) "}" _newline ///
		_skip(8) "}" _newline(2) ///		
"header {" _newline ///
		_skip(8) "margin-top:0;" _newline ///
		_skip(8) "padding-top:200px; " _newline ///
		_skip(8) "background-color:white; " _newline ///
		_skip(8) "text-align:center;" _newline ///
		_skip(8) "display:block;" _newline ///
		_skip(8) "}" _newline(2) ///
"h1, h1 > a, h1 > a:link {" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h2, h2 > a, h2 > a, h2 > a:link {" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "}" _newline(2) ///	
"h3, h3 > a,h3 > a, h3 > a:link,h3 > a:link {" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "}" _newline(2) ///
"h4, .h4 {" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "}" _newline(2) ///
"h5, .h5 {" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "}" _newline(2) ///		
"h6 {"  _newline ///
		_skip(8) "text-align:center;" _newline ///
		_skip(8) "}" _newline(2) ///	
"p {" _newline ///
		_skip(8) `"font-family:`font';"' _n  _newline ///
		_skip(8) "margin:0;" _n _newline ///
		_skip(8) "display: block;" _newline ///
		_skip(8) "line-height:14px;" _n ///
		_skip(8) "font-size:14px;" _n  ///
		_skip(8) "text-align:justify;" _n  ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "text-justify:inter-word;" _n ///
		_skip(8) "}" _newline(2) ///
"ul {"	_skip(8) "list-style:circle;" _newline ///
		_skip(8) "margin-top:0;" _newline ///
		_skip(8) "margin-bottom:0;" _newline ///
		_skip(8) "}" _newline(2) /// 
"div ul a {" _newline ///
		_skip(8) "color:black;" _newline ///
		_skip(8) "text-decoration:none;" _newline ///
		_skip(8) "}" _newline(2) ///
"div ul {" _newline ///
		_skip(8) "list-style: none;" _newline ///
		_skip(8) "margin: 0px 0 10px -15px;" _newline ///
		_skip(8) "padding-left:15px;" _newline ///
		_skip(8) "}" _newline(2) /// 
"div ul li {" _newline ///
		_skip(8) "font-weight:bold;" _newline ///
		_skip(8) "margin-top:20px;" _newline ///
        _skip(8) "}" _newline(2) ///	
"div ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "margin-left:20px;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:none;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///
"div ul li ul li ul li ul li {" _newline ///
        _skip(8) "font-weight: normal;" _newline ///
		_skip(8) "font-style:italic;" _newline ///
		_skip(8) "margin-top:5px;" _newline ///
        _skip(8) "}" _newline(2) ///	
"img {" _newline ///
		_skip(8) "margin: 5px 0 5px 0;" _newline ///
		_skip(8) "padding: 0px;" _newline ///
		_skip(8) "cursor:-webkit-zoom-in;" _newline ///
		_skip(8) "cursor:-moz-zoom-in;" _newline ///
		_skip(8) "display:inline-block;" _newline ///
		_skip(8) "text-align: left;" _newline ///
		_skip(8) "clear: both;" _newline ///
		_skip(8) "-webkit-box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n ///
		_skip(8) "-moz-box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n ///
		_skip(8) "box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n ///
		_skip(8) "}" _newline(2) ///							
"h1,h2,h3,h4,h5,h6		{" _newline ///
		_skip(8) `"font-family:`font';"' _n   /// 
		_skip(8) `"text-align: left;"' _n    ///
		_skip(8) "}" _newline(2) ///
"pre {" _newline ///
		_skip(8) "padding:0;" _n  /// 
		_skip(8) "margin: 0;" _n    ///
		_skip(8) "white-space:normal;" _newline ///
		_skip(8) "background: white;" _newline ///
		_skip(8) "min-width:500px;" _newline ///
		_skip(8) "}" _newline(2) ///
"p > code {" _newline ///
		_skip(8) "display:block;" _n /// 
		_skip(8) "margin:10px 0 0 0;" _n   ///
		_skip(8) "line-height:14px;" _n   ///
		_skip(8) "font-size:14px;" _n   ///
		_skip(8) "font-weight:normal;" _n  ///
		_skip(8) "}" _newline(2) ///
"results {" _newline ///
		_skip(8) "display:block;" _n /// 
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "margin:0 0 14px 0;" _n  ///
		_skip(8) "line-height:12px;" _n  ///
		_skip(8) "font-size:12px;" _n  ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "border-top:hidden;" _n ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "background-color:transparent;" _n ///
		_skip(8) "white-space:pre;" _newline ///
		_skip(8) "}" _newline(2) ///		
"pre > code {" _newline ///
		_skip(8) "display:block;" _n /// 
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "margin:0 0 14px 0;" _n  ///
		_skip(8) "padding:8px 0px 0 0px;" _n  ///
		_skip(8) "line-height:12px;" _n  ///
		_skip(8) "font-size:12px;" _n  ///
		_skip(8) "font-weight:normal;" _newline ///
		_skip(8) "border-top:hidden;" _n ///
		_skip(8) "font-family:Courier New, Courier, monospace;" _newline ///
		_skip(8) "background-color:transparent;" _n ///
		_skip(8) "white-space:pre;" _newline ///
		_skip(8) "}" _newline(2) ///		
"results:empty, pre > code:empty  {" _newline ///
		_skip(8) "display: none;" _newline(2) ///
		_skip(8) "}" _newline(2) ///	
"code:empty, p > code:empty  {" _newline ///
		_skip(8) "display: none;" _newline(2) ///
		_skip(8) "}" _newline(2) ///			
"result {" _newline ///
		_skip(8) "display: block;" _newline ///
		_skip(8) "unicode-bidi: embed;" _newline ///
		_skip(8) "white-space:pre;" _newline ///
		_skip(8) "}" _newline(2) ///			
"point {" _newline ///
		_skip(8) "font-size:160%;" _newline ///
		_skip(8) "line-height:14px;" _newline ///
		_skip(8) "color:#FFC500;" _newline ///
		_skip(8) "vertical-align:-15%" _newline ///
		_skip(8) "}" _newline(2) ///		
".center, #center {" _newline ///
		_skip(8) "display: block;" _newline ///
		_skip(8) "margin-left: auto;" _newline ///
		_skip(8) "margin-right: auto;" _newline ///
		_skip(8) "-webkit-box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n ///
		_skip(8) "-moz-box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n ///
		_skip(8) "box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n(2) ///
		_skip(8) "padding: 0px;" _newline ///
		_skip(8) "border-width: 0px;" _newline ///
		_skip(8) "border-style: solid;" _newline ///
		_skip(8) "cursor:-webkit-zoom-in;" _newline ///
		_skip(8) "cursor:-moz-zoom-in;" _newline ///
		_skip(8) "}" _newline(2) ///
".right, #right {" _newline ///
		_skip(8) "display: block;" _newline ///
		_skip(8) "margin-right: 5px;" _newline ///	
		_skip(8) "-webkit-box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n ///
		_skip(8) "-moz-box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n ///
		_skip(8) "box-shadow: 0px 0px 2px rgba( 0, 0, 0, 0.5 );" _n(2) ///
		_skip(8) "padding: 0px;" _newline ///
		_skip(8) "border-width: 0px;" _newline ///
		_skip(8) "border-style: solid;" _newline ///
		_skip(8) "cursor:-webkit-zoom-in;" _newline ///
		_skip(8) "cursor:-moz-zoom-in;" _newline ///
		_skip(8) "}" _newline(2) ///				
"empty {" _newline ///
		_skip(8) "display:none;" _newline ///
		_skip(8) "}" _newline(2) ///			
"pagebreak {" _newline ///
		_skip(8) "page-break-before: always;" _newline ///
		_skip(8) "}" _newline(2) ///
".pagebreak, #pagebreak {" _newline ///
		_skip(8) "page-break-before: always;" _newline ///
		_skip(8) "}" _newline(2) ///
".blue, #blue {" _newline ///
		_skip(8) "color:#00F;" _newline ///
		_skip(8) "}" _newline(2) ///		
".pink, #pink {" _newline ///
		_skip(8) "color:#FF0080;" _newline ///
		_skip(8) "}" _newline(2) ///	
".purple, #purple {" _newline ///
		_skip(8) "color:#8000FF;" _newline ///
		_skip(8) "}" _newline(2) ///		
".green, #green {" _newline ///
		_skip(8) "color:#408000;" _newline ///
		_skip(8) "}" _newline(2) ///
".orange, #orange {" _newline ///
		_skip(8) "color:#FF8000;" _newline ///
		_skip(8) "}" _newline(2) ///
".red, #red {" _newline ///
		_skip(8) "color:#F00;" _newline ///
		_skip(8) "}" _newline(2) ///
".bkblue, #bkblue {" _newline ///
		_skip(8) "background-color:#ABC5F6;" _newline ///
		_skip(8) "}" _newline(2) ///
".bkyellow, #bkyellow {" _newline ///
		_skip(8) "background-color:#FAE768;" _newline ///
		_skip(8) "}" _newline(2) ///
".bkgreen, #bkgreen {" _newline ///
		_skip(8) "background-color:#CBEF66;" _newline ///
		_skip(8) "}" _newline(2) ///
".bkpink, #bkpink {" _newline ///
		_skip(8) "background-color:#F1A8D0;" _newline ///
		_skip(8) "}" _newline(2) ///		
".bkpurple, #bkpurple {" _newline ///
		_skip(8) "background-color:#D6ABEF;" _newline ///
		_skip(8) "}" _newline(2) ///	
".bkgray, #bkgray {" _newline ///
		_skip(8) "background-color:#D6D6D6;" _newline ///
		_skip(8) "}" _newline(4) ///		
				///
"/* ---- This is Smooth Zoom CSS ---- */" _newline /// 
"#lightwrap {" _newline ///
		_skip(8) "position:fixed;" _newline ///
		_skip(8) "top:0;" _newline ///
		_skip(8) "left:0;" _newline ///
		_skip(8) "width:100%;" _newline ///
		_skip(8) "height:100%;" _newline ///
		_skip(8) "text-align:center;" _newline ///
		_skip(8) "cursor:-webkit-zoom-out;" _newline ///
		_skip(8) "cursor:-moz-zoom-out;" _newline ///
		_skip(8) "z-index:999;" _newline ///
		_skip(8) "}" _newline(2) ///
/// /* overlay covering website */
"#lightbg {" _newline ///
		_skip(8) "position:fixed;" _newline ///
		_skip(8) "display:none;" _newline ///
		_skip(8) "top:0;" _newline ///
		_skip(8) "left:0;" _newline ///
		_skip(8) "width:100%;" _newline ///
		_skip(8) "height:100%;" _newline ///
		_skip(8) "background:rgba(255, 255, 255, .9);}" _newline(2) ///
"#lightwrap img {" _newline ///
		_skip(8) "position:absolute;" _newline ///
		_skip(8) "display:none;" _newline ///
		_skip(8) "cursor:-webkit-zoom-out;cursor:-moz-zoom-out;" _newline ///
		_skip(8) "}" _newline(2) ///
"#lightzoomed {" _newline ///
		_skip(8) "opacity:0;" _newline ///
		_skip(8) "}" _newline(2) ///
"#off-screen {" _newline ///
		_skip(8) "position: fixed;" _newline ///
		_skip(8) "right:100%;" _newline ///
		_skip(8) "opacity: 0;" _newline ///
		_skip(8) "}" _newline(2) ///
"</style>" _newline(4)



	/*  LANDSCAPE MODE STYLING  */
	*this options are used to style the landscape mode document.
			
		if `"`landscape'"' == "landscape" {
		file write `canvas' `"<style type="text/css">"' _newline ///
		///
"@page {" _newline ///
		_skip(8) "size: A4 landscape" _newline /// 
		_skip(8) "}" _newline(2) ///
"</style>" _newline(4)
		}	
		
		else {
		file write `canvas' `"<style type="text/css">"' _newline ///
		///
"@page {" _newline ///
		_skip(8) "size: A4 " _newline /// 
		_skip(8) "}" _newline(2) ///
"</style>" _newline(4)
		}			
		
		
		/* ending the HTML head tag */
		file write `canvas' "</head>" _n

		file write `canvas' `"<body onload="generateTOC(document."' ///
		`"getElementById("'"'toc'"`"));">"' _newline
		
		/* defining the title of the report, which appears on the first page */
		if `"`title'"' != "" {
				file write `canvas' `"<header>`title'</header>"' _n
				}
	
		else {
				file write `canvas' "<header></header>" _newline
				}
		
		/* author name */
		if `"`author'"' ~= "" {
				file write `canvas' `"<h6>`author'</h6>"' _n
				}
		
		/* adding the author's affiliation on the fitst page */
		if `"`affiliation'"' ~= "" {
				file write `canvas' `"<h6 style="font-size: 14px; "' ///
				`"margin-top:-25px;">`affiliation'</h6>"' _n
				}
		
		/* adding the author email/contact information in the fitst page */
		if `"`address'"' ~= "" {
				file write `canvas' `"<h6 style="font-size: 14px; "' ///
				`"margin-top:-30px;">`address'</h6>"' _n
				}
		
		
		/* adding the date in the fitst page */
		if "`date'" == "date" {
				file write `canvas' ///
				`"<span style="font-size: 14px;text-align:center;"' ///
				`"display:block; padding: 0 0 36px 0;">"' ///
				`"<span id="spanDate"></span></span>"' _n(2)
				}
	
		/* adding the summary in the first page */
		if `"`summary'"' ~= "" {
				
				file write  `canvas' _newline(4) _n
				file write `canvas' `"<p style="padding-right:15%; "' ///
				`"padding-left:15%;padding-top:100px;">`summary'</p>"' _n
				}
	
		if  "`unbreak'" == "" {
				file write `canvas' `"<div class= "pagebreak" ></div>"' _n
				}      
		
		/* styling the first page, if "break" option selected */
		if "`unbreak'" == "unbreak" {
				file write `canvas' ///
				`"<span style="font-size:14; font-weight:normal; "' ///
				`"display:block; border-bottom:thin;  border-bottom-style:"' ///
				`"solid;border-bottom-color:#ACACAC;margin-top:0px; "' ///
				`"padding-bottom:0px; margin-bottom:0px; text-align:"' ///
				`"center;"></span>"' _n 
				}
		
		if "`contents'" == "contents" & "`unbreak'" == "" {
				file write `canvas' ///
				`"<span style="font-size:16; font-weight:bold;"' ///
				`"display:block; border-bottom:thin; "' ///
				`"border-bottom-style:solid;border-bottom-color:"' ///
				`"#ACACAC;margin-top:10px; padding-bottom:5px; "' ///
				`"margin-bottom:10px;">Contents</span>"' _n ///
				`"<div id="toc"></div>"' _n ///
				`"<div class= "pagebreak" ></div>"' _n 
				}
		
		if "`contents'" == "contents" & "`unbreak'" == "unbreak" {
				file write `canvas' ///
				`"<span style="font-size:14; font-weight:normal;"' ///
				`"display:block; border-bottom:thin;  "' ///
				`"border-bottom-style:solid;border-bottom-color:"' ///
				`"#ACACAC;margin-top:0px; padding-bottom:0px; "' ///
				`"margin-bottom:0px; text-align:center;"></span>"' _n ///
				`"<div id="toc"></div>"' _n ///
				`"<span style="font-size:14; font-weight:normal;"' ///
				`"display:block; border-bottom:thin;  "' ///
				`"border-bottom-style:solid;border-bottom-color:"' ///
				`"#ACACAC;margin-top:0px; padding-bottom:0px; "' ///
				`"margin-bottom:0px; text-align:center;"></span>"' _n(4) 
				}
		
		
    }
	
	
	
	
	
	/* THIS IS THE TABLE OF CONTENT JAVASCRIPT */

	/*
	* Dynamic Table of Contents script
	* Based on a program by Matt Whitlock http://www.whitsoftdev.com
	* Rewritten and eddited by E. F. Haghish http://www.haghish.com
	*/
 
	file write `canvas' "<script>" _newline ///
	"function createLink(href, innerHTML) {" _newline ///
        _skip(4) `"var a = document.createElement("a");"' _newline ///
        _skip(4) `"a.setAttribute("href", href);"' _newline ///
        _skip(4) `"a.innerHTML = innerHTML;"' _newline ///
        _skip(4) "return a;" _newline ///
	"}" _newline ///
	"function generateTOC(toc) {" _newline ///
        _skip(4) `"var i1 = 0, i2 = 0, i3 = 0, i4 = 0;"' _newline ///
        _skip(4) `"toc = toc.appendChild(document.createElement("ul"));"' _n ///
        _skip(4) "for (var i = 0; i < document.body.childNodes.length;" ///
		"++i) {" _newline ///
        _skip(4) `"var node = document.body.childNodes[i];"' _newline ///
        _skip(4) `"var tagName = node.nodeName.toLowerCase();"' _newline(2) ///
	    _skip(4) "if (tagName == "`"""'"h4"`"""'") {" _newline ///
		  ///
          _skip(6) "++i4;" _newline ///
          _skip(6) `"if (i4 == 1) toc.lastChild.lastChild.lastChild."' ///
		  `"lastChild.lastChild.appendChild(document.createElement"' ///
		  `"("ul"));"' _newline ///
          _skip(6) `"var section = i1 + "." + i2 + "." + i3 + "." + "' ///
		  `"i4;"' _newline ///
          _skip(6) `"node.insertBefore(document.createTextNode"' ///
		  `"(section + ". "), node.firstChild);"' _newline ///
          _skip(6) `"node.id = "section" + section;"' _newline ///
		  `"toc.lastChild.lastChild.lastChild.lastChild.lastChild."' ///
		  `"lastChild.appendChild(document.createElement("li"))."' ///
		  `"appendChild(createLink("#section" + section, node."' ///
		  `"innerHTML));"' _newline ///
          _skip(4) "}" _newline(2) ///
          ///
		  _skip(6) "else if (tagName == "`"""'"h3"`"""'") {" _newline ///
          _skip(6) "++i3, i4 = 0;" _newline ///
          _skip(6) `"if (i3 == 1) toc.lastChild.lastChild.lastChild."' ///
		  `"appendChild(document.createElement("ul"));"' _newline ///
          _skip(6) `"var section = i1 + "." + i2 + "." + i3;"' _newline ///
          _skip(6) `"node.insertBefore(document.createTextNode"' ///
		  `"(section + ". "), node.firstChild);"' _newline ///
          _skip(6) `"node.id = "section" + section;"' _newline ///
          `"toc.lastChild.lastChild.lastChild.lastChild.appendChild"' ///
		  `"(document.createElement("li")).appendChild(createLink"' ///
		  `"("#section" + section, node.innerHTML));"' _newline ///
          _skip(4) "}" _newline(2) ///
		  ///
          _skip(4) "else if (tagName == "`"""'"h2"`"""'") {" _newline ///
          _skip(6) `"++i2, i3 = 0, i4 = 0;"' _newline ///
		  _skip(6) `"if (i2 == 1) toc.lastChild.appendChild"' ///
		  `"(document.createElement("ul"));"' _newline ///
          _skip(6) `"var section = i1 + "." + i2;"' _newline ///
          _skip(6) `"node.insertBefore(document.createTextNode"' ///
		  `"(section + ". "), node.firstChild);"' _newline ///
          _skip(6) `"node.id = "section" + section;"' _newline ///
          _skip(6) `"toc.lastChild.lastChild.appendChild(h2item = "' ///
		  `"document.createElement("li")).appendChild(createLink"' ///
		  `"("#section" + section, node.innerHTML));"' _newline ///
		  _skip(4) "}" _newline ///
		  ///
		  _skip(6) "else if (tagName == "`"""'"h1"`"""'") {" _newline ///
          _skip(6) "++i1, i2 = 0, i3 = 0, i4 = 0;" _newline ///
          _skip(6) "var section = i1;" _newline ///
          _skip(6) `"node.insertBefore(document.createTextNode"' ///
		  `"(section + ". "), node.firstChild);"' _newline ///
          _skip(6) `"node.id = "section" + section;"' _newline ///
          _skip(6) `"toc.appendChild(h2item = document.createElement"' ///
		  `"("li")).appendChild(createLink("#section" + section, "' ///
		  `"node.innerHTML));"' _newline ///
		  _skip(4) "}" _newline ///
	_skip(4) "}" _newline ///
	_skip(4) "}" _newline ///
	_skip(4) "</script>" _newline(2) 
	

    global weaver `"`using'"' 
	
	di _newline(5)
	di as txt "| |     / /__  ____ __   _____  _____	"
	di as txt "| | /| / / _ \/ __ `/ | / / _ \/ ___/	"
	di as txt "| |/ |/ /  __/ /_/ /| |/ /  __/ /    	"
	di as txt "|__/|__/\___/\__,_/ |___/\___/_/      produced " ///
	`"{bf:{browse `"${htmldoc}"'}} "' _n
                                 
	end








********************************************************************************
				   /*             close Weaver              */
********************************************************************************

	program define weavend
        version 11
		
		/* checking that the Weaver is currently weaving a canvas */
        if "$weaver" == "" {
                di as err "Oops! You can't close the Weaver because you haven't been weaving anything! Begin weaving by using {stata weave} command. See {help weaver} package for help."
                exit 111
        }
		
        
		else { 
			cap confirm file `"$weaver"'
                
			if _rc == 0 {
				tempname canvas         
                file open `canvas' using `"$weaver"', write text append 
 
		


	/* ---- Markdown Syntax ---- */

	
file write `canvas' _newline(2) "<!-- Markdown Syntax  -->" _newline(2) ///
"<script>" _newline ///
		_newline ///
		_skip(4) "(function() {" _newline ///
		_skip(4) "document.body.innerHTML = document.body.innerHTML" _newline ///
				_skip(8) ".replace(/<results><\/results>/g, '')" _newline ///
				_skip(8) ".replace(/<\/result><result>/g, '')" _newline ///
				/// defining the H1, H2, H3, H4 symbols
				_skip(8) ".replace(/\*----/g, '<h4>')" _newline ///
				_skip(8) ".replace(/----\*/g, '</h4><p>')" _newline ///
				_skip(8) ".replace(/\*---/g, '<h3>')" _newline ///
				_skip(8) ".replace(/---\*/g, '</h3><p>')" _newline ///
				_skip(8) ".replace(/\*--/g, '<h2>')" _newline ///
				_skip(8) ".replace(/--\*/g, '</h2><p>')" _newline ///
				_skip(8) ".replace(/\*-/g, '<h1>')" _newline ///
				_skip(8) ".replace(/-\*/g, '</h1><p>')" _newline ///
				/// break and pagebreak
				_skip(8) ".replace(/page-break/g, '<div class="`"""'"pagebreak"`"""'" ></div>')" _newline ///
				_skip(8) ".replace(/line-break/g, '<br />')" _newline ///
				/// text decoration
				_skip(8) ".replace(/#___/g, '<strong><em>')" _newline ///
				_skip(8) ".replace(/___#/g, '</em></strong>')" _newline ///
				_skip(8) ".replace(/#__/g, '<strong>')" _newline ///
				_skip(8) ".replace(/__#/g, '</strong>')"  _newline ///
				_skip(8) ".replace(/#_/g, '<em>')" _newline ///
				_skip(8) ".replace(/_#/g, '</em>')" _newline ///
				_skip(8) ".replace(/#\*_/g, '<u>')" _newline ///
				_skip(8) ".replace(/_\*#/g, '</u>')" _newline ///
				/// link codes
				_skip(8) ".replace(/\[--/g, '<a href=')" _newline ///
				_skip(8) ".replace(/\--]\[-/g, ' >')" _newline ///
				_skip(8) ".replace(/-\]/g, '</a>')" _newline ///
				_skip(8) ".replace(/\[#\]/g, '</span>')" _newline ///
				/// background colors
				_skip(8) ".replace(/\[-yellow\]/g, '<span style="`"""'"background-color:#FAE768"`"""'">')" _newline ///
				_skip(8) ".replace(/\[-green\]/g, '<span style="`"""'"background-color:#CBEF66"`"""'">')" _newline ///
				_skip(8) ".replace(/\[-blue\]/g, '<span style="`"""'"background-color:#ABC5F6"`"""'">')" _newline ///
				_skip(8) ".replace(/\[-pink\]/g, '<span style="`"""'"background-color:#F1A8D0"`"""'">')" _newline ///
				_skip(8) ".replace(/\[-purple\]/g, '<span style="`"""'"background-color:#D6ABEF"`"""'">')" _newline ///
				_skip(8) ".replace(/\[-gray\]/g, '<span style="`"""'"background-color:#D6D6D6"`"""'">')" _newline ///
				/// font colors
				_skip(8) ".replace(/\[blue\]/g, '<span style="`"""'"color:#00F"`"""'">')" _newline ///
				_skip(8) ".replace(/\[pink\]/g, '<span style="`"""'"color:#FF0080"`"""'">')" _newline ///
				_skip(8) ".replace(/\[purple\]/g, '<span style="`"""'"color:#8000FF"`"""'">')" _newline ///
				_skip(8) ".replace(/\[green\]/g, '<span style="`"""'"color:#408000"`"""'">')" _newline ///
				_skip(8) ".replace(/\[orange\]/g, '<span style="`"""'"color:#FF8000"`"""'">')" _newline ///
				_skip(8) ".replace(/\[red\]/g, '<span style="`"""'"color:#F00"`"""'">')" _newline ///
				/// text positionning 
				_skip(8) ".replace(/\[center\]/g, '<span style="`"""'"display:block; text-align:center"`"""'">')" _newline ///
				_skip(8) ".replace(/\[right\]/g, '<span style="`"""'"display:block; text-align:right"`"""'">')" _newline ///
		_skip(4) "})();" ///
"</script>" _newline(2)

/* Add Jquery */
file write `canvas' `" <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script> "' _newline   



  
/* ADDING THE JQUERY */
file write `canvas' "<script src=" `""http://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.js"></script> "' _newline

  * ---- JavaScript code for date (alternative to !date) ---- */
	
file write `canvas' _newline(2) "<!-- JavaScript Date  -->" _newline(2) ///
"<script type="  `"""'  "text/javascript" `"""' ">" _newline ///
	_skip(8) "var months = ['January','February','March','April','May','June','July','August'," _newline ///
	_skip(8) "'September','October','November','December'];" _newline ///
	_skip(8) "var tomorrow = new Date(); tomorrow.setTime(tomorrow.getTime() + (1000*3600*24));" _newline ///
	_skip(8) "document.getElementById(" `"""' "spanDate" `"""' ")" _newline ///
	_skip(8) ".innerHTML = months[tomorrow.getMonth()] + " `"""' " " `"""' " + " _newline ///
	_skip(8) "tomorrow.getDate()+ " `"""' "<sup style=font-size:60%;>th</sup>, " `"""' " + tomorrow.getFullYear();" _newline ///
"</script>"  _newline(2)


	/* ---- JavaScript "Easing" Code ---- */
file write `canvas' _newline(2) "<script>" _newline /// 
"jQuery.easing['jswing'] = jQuery.easing['swing'];" _newline /// 
"jQuery.extend( jQuery.easing," _newline /// 
"{" _newline /// 
		_skip(4) "def: 'easeOutQuad'," _newline /// 
		_skip(4) "swing: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	/// /* --- alert(jQuery.easing.default); --- */
		_skip(6) 	"return jQuery.easing[jQuery.easing.def](x, t, b, c, d);" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInQuad: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c*(t/=d)*t + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutQuad: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return -c *(t/=d)*(t-2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutQuad: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return c/2*t*t + b;" _newline /// 
		_skip(6) 	"return -c/2 * ((--t)*(t-2) - 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInCubic: function (x, t, b, c, d) {" _newline /// 
		_skip(4) "return c*(t/=d)*t*t + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutCubic: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c*((t=t/d-1)*t*t + 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutCubic: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return c/2*t*t*t + b;" _newline /// 
		_skip(6) 	"return c/2*((t-=2)*t*t + 2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInQuart: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c*(t/=d)*t*t*t + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutQuart: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return -c * ((t=t/d-1)*t*t*t - 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutQuart: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return c/2*t*t*t*t + b;" _newline /// 
		_skip(6) 	"return -c/2 * ((t-=2)*t*t*t - 2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInQuint: function (x, t, b, c, d) {" _newline /// 
		_skip(6) "return c*(t/=d)*t*t*t*t + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutQuint: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c*((t=t/d-1)*t*t*t*t + 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutQuint: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return c/2*t*t*t*t*t + b;" _newline /// 
		_skip(6) 	"return c/2*((t-=2)*t*t*t*t + 2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInSine: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return -c * Math.cos(t/d * (Math.PI/2)) + c + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutSine: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c * Math.sin(t/d * (Math.PI/2)) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutSine: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return -c/2 * (Math.cos(Math.PI*t/d) - 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInExpo: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return (t==0) ? b : c * Math.pow(2, 10 * (t/d - 1)) + b" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutExpo: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return (t==d) ? b+c : c * (-Math.pow(2, -10 * t/d) + 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutExpo: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if (t==0) return b;" _newline /// 
		_skip(6) 	"if (t==d) return b+c;" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return c/2 * Math.pow(2, 10 * (t - 1)) + b;" _newline /// 
		_skip(6) 	"return c/2 * (-Math.pow(2, -10 * --t) + 2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInCirc: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return -c * (Math.sqrt(1 - (t/=d)*t) - 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutCirc: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"return c * Math.sqrt(1 - (t=t/d-1)*t) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutCirc: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"if ((t/=d/2) < 1) return -c/2 * (Math.sqrt(1 - t*t) - 1) + b;" _newline /// 
		_skip(6) 	"return c/2 * (Math.sqrt(1 - (t-=2)*t) + 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInElastic: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"var s=1.70158;var p=0;var a=c;" _newline /// 
		_skip(6) 	"if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;" _newline /// 
		_skip(4) 	"if (a < Math.abs(c)) { a=c; var s=p/4; }" _newline /// 
		_skip(4) 	"else var s = p/(2*Math.PI) * Math.asin (c/a);" _newline /// 
		_skip(4) 	"return -(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutElastic: function (x, t, b, c, d) {" _newline /// 
		_skip(6) 	"var s=1.70158;var p=0;var a=c;" _newline /// 
		_skip(6) 	"if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;" _newline /// 
		_skip(6) 	"if (a < Math.abs(c)) { a=c; var s=p/4; }" _newline /// 
		_skip(4) 	"else var s = p/(2*Math.PI) * Math.asin (c/a);" _newline /// 
		_skip(6) 	"return a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*(2*Math.PI)/p ) + c + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutElastic: function (x, t, b, c, d) {" _newline /// 
		_skip(6)	"var s=1.70158;var p=0;var a=c;" _newline /// 
		_skip(6)	"if (t==0) return b;  if ((t/=d/2)==2) return b+c;  if (!p) p=d*(.3*1.5);" _newline /// 
		_skip(6)	"if (a < Math.abs(c)) { a=c; var s=p/4; }" _newline /// 
		_skip(6)	"else var s = p/(2*Math.PI) * Math.asin (c/a);" _newline /// 
		_skip(6)	"if (t < 1) return -.5*(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;" _newline /// 
		_skip(6)	"return a*Math.pow(2,-10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )*.5 + c + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInBack: function (x, t, b, c, d, s) {" _newline /// 
		_skip(6)	"if (s == undefined) s = 1.70158;" _newline /// 
		_skip(6)	"return c*(t/=d)*t*((s+1)*t - s) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutBack: function (x, t, b, c, d, s) {" _newline /// 
		_skip(6)	"if (s == undefined) s = 1.70158;" _newline /// 
		_skip(6)	"return c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutBack: function (x, t, b, c, d, s) {" _newline /// 
		_skip(6)	"if (s == undefined) s = 1.70158; " _newline /// 
		_skip(6)	"if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;" _newline /// 
		_skip(6)	"return c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInBounce: function (x, t, b, c, d) {" _newline /// 
		_skip(6)	"return c - jQuery.easing.easeOutBounce (x, d-t, 0, c, d) + b;" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeOutBounce: function (x, t, b, c, d) {" _newline /// 
		_skip(6)	"if ((t/=d) < (1/2.75)) {" _newline /// 
		_skip(6)		"return c*(7.5625*t*t) + b;" _newline /// 
		_skip(6)	"} else if (t < (2/2.75)) {" _newline /// 
		_skip(6)		"return c*(7.5625*(t-=(1.5/2.75))*t + .75) + b;" _newline /// 
		_skip(6)	"} else if (t < (2.5/2.75)) {" _newline /// 
		_skip(6)		"return c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b;" _newline /// 
		_skip(6)	"} else {" _newline /// 
		_skip(6)		"return c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b;" _newline /// 
		_skip(6)	"}" _newline /// 
		_skip(4) "}," _newline /// 
		_skip(4) "easeInOutBounce: function (x, t, b, c, d) {" _newline /// 
		_skip(6)	"if (t < d/2) return jQuery.easing.easeInBounce (x, t*2, 0, c, d) * .5 + b;" _newline /// 
		_skip(6)	"return jQuery.easing.easeOutBounce (x, t*2-d, 0, c, d) * .5 + c*.5 + b;" _newline /// 
		_skip(2) "}"_newline /// 
"});" _newline /// 
"</script>" _newline(2)





	/* THIS IS THE SMOOTH ZOOM JAVASCRIPT */


	/*
	* Smoothzoom
	* http://kthornbloom.com/smoothzoom
	*
	* Copyright 2014, Kevin Thornbloom
	* Free to use and modify under the MIT license.
	* http://www.opensource.org/licenses/mit-license.php
	*/

file write `canvas' "<script>" _newline ///
"(function($) {" _newline ///
    "$.fn.extend({" _newline ///
        _skip(4)"smoothZoom: function(options) {" _newline ///
			///
            _skip(6)"var defaults = {" _newline ///
                _skip(8)"zoominSpeed: 800," _newline ///
                _skip(8)"zoomoutSpeed: 400," _newline ///
                _skip(8)"resizeDelay: 400," _newline ///
                _skip(8)"zoominEasing: 'easeOutExpo'," _newline ///
                _skip(8)"zoomoutEasing: 'easeOutExpo'" _newline ///
            _skip(6)"}" _newline ///
			///
            _skip(6)"var options = $.extend(defaults, options);" _newline ///
			///
			///		
			///
            /// // CLICKING AN IMAGE
			///
            _skip(6)"$('img[rel=" `"""'"zoom"`"""' "]').click(function(event) {" _newline ///
			///
                _skip(8)"var link = $(this).attr('src')," _newline ///
                    _skip(10)"largeImg = $(this).parent().attr('href')," _newline ///
                    _skip(10)"target = $(this).parent().attr('target')," _newline ///
                    _skip(10)"offset = $(this).offset()," _newline ///
                    _skip(10)"width = $(this).width()," _newline ///
                    _skip(10)"height = $(this).height()," _newline ///
                    _skip(10)"amountScrolled = $(window).scrollTop()," _newline ///
                    _skip(10)"viewportWidth = $(window).width()," _newline ///
                    _skip(10)"viewportHeight = $(window).height();" _newline ///
                /// IF THERE IS NO ANCHOR WRAP
                _skip(8)"if ((!largeImg) || (largeImg == " `"""'"#"`"""'")) {" _newline ///
				///
                    _skip(6)"$('body').append(" `"""'"<div id='lightwrap'><img src="`"""'" + link + "`"""'"></div><div id='lightbg'></div><img id='off-screen' src="`"""'" + link + "`"""'">"`"""'");" _newline ///
                   _skip(6) "$("`"""'"#off-screen"`"""'").load(function() {" _newline ///
                        _skip(8)"$('#lightwrap img').css({" _newline ///
                            _skip(10)"width: width," _newline ///
                            _skip(10)"height: height," _newline ///
                            _skip(10)"top: (offset.top - amountScrolled)," _newline ///
                            _skip(10)"left: offset.left" _newline ///
                        _skip(8)"});" _newline ///
                        _skip(8)"fitWidth();" _newline ///
                        _skip(8)"$('#lightbg').fadeIn();" _newline ///
                    _skip(6)"});" _newline ///
                    _skip(6)"$(this).attr('id', 'lightzoomed');" _newline ///
					///
                    /// IF THERE IS AN ANCHOR, AND IT'S AN IMAGE
                _skip(6) "} else if (largeImg.match("`"""'"jpg$"`"""'")) {" _newline ///
                    "$('body').append("`"""'"<div id='lightwrap'><img src="`"""'" + largeImg + "`"""'"></div><div id='lightbg'></div><img id='off-screen' src="`"""'" + largeImg + "`"""'">"`"""'");" _newline ///
                    _skip(8)"$("`"""'"#off-screen"`"""'").load(function() {" _newline ///
                        _skip(10)"$('#lightwrap img').css({" _newline ///
                            _skip(10)"width: width," _newline ///
                            _skip(10)"height: height," _newline ///
                            _skip(10)"top: (offset.top - amountScrolled)," _newline ///
                            _skip(10)"left: offset.left" _newline ///
                        _skip(10)"});" _newline ///
                        _skip(8)"fitWidth();" _newline ///
                        _skip(8)"$('#lightbg').fadeIn();" _newline ///
                    _skip(6)"});" _newline ///
                    _skip(6)"$(this).attr('id', 'lightzoomed');" _newline ///
					///	
                    /// IF THERE IS AN ANCHOR, BUT NOT AN IMAGE
                _skip(4)"} else {" _newline ///
                    /// SHOULD IT OPEN IN A NEW WINDOW?
                    _skip(4)"if (target = '_blank') {" _newline ///
                        _skip(4)"window.open(largeImg, '_blank');" _newline ///
                    _skip(4)"} else {" _newline ///
                        _skip(4)"window.location = largeImg;" _newline ///
                    _skip(4)"}" _newline ///
                _skip(4)"}" _newline ///
                _skip(4)"event.preventDefault();" _newline ///
            _skip(4)"});" _newline ///
			///	
            /// CLOSE MODAL
			///
            _skip(4)"$(document.body).on("`"""'"click"`"""'", "`"""'"#lightwrap, #lightbg"`"""'", function(event) {" _newline ///
                _skip(6)"var offset = $("`"""'"#lightzoomed"`"""'").offset()," _newline ///
                    _skip(6)"originalWidth = $("`"""'"#lightzoomed"`"""'").width()," _newline ///
                    _skip(6)"originalHeight = $("`"""'"#lightzoomed"`"""'").height()," _newline ///
                    _skip(6)"amountScrolled = $(window).scrollTop();" _newline ///
                _skip(6)"$('#lightbg').fadeOut(500);" _newline ///
                _skip(6)"$('#lightwrap img').animate({" _newline ///
                    _skip(6)"height: originalHeight," _newline ///
                    _skip(6)"width: originalWidth," _newline ///
                    _skip(6)"top: (offset.top - amountScrolled)," _newline ///
                    _skip(6)"left: offset.left," _newline ///
                    _skip(6)"marginTop: '0'," _newline ///
                    _skip(6)"marginLeft: '0'" _newline ///
                _skip(6)"}, options.zoomoutSpeed, options.zoomoutEasing, function() {" _newline ///
                    _skip(6)"$('#lightwrap, #lightbg, #off-screen').remove();" _newline ///
                    _skip(6)"$('#lightzoomed').removeAttr('id');" _newline ///
					///
                _skip(6)"});" _newline ///
            _skip(6)"});" _newline ///
			///
            /// DELAY FUNCTION FOR WINDOW RESIZE
            _skip(6)"var delay = (function() {" _newline ///
                _skip(6)"var timer = 0;" _newline ///
                _skip(6)"return function(callback, ms) {" _newline ///
                    _skip(6)"clearTimeout(timer);" _newline ///
                    _skip(6)"timer = setTimeout(callback, ms);" _newline ///
                _skip(6)"};" _newline ///
            _skip(6)"})();" _newline ///
			///
            /// CHECK WINDOW SIZE EVERY _ MS
            _skip(6)"$(window).resize(function() {" _newline ///
                _skip(6)"delay(function() {" _newline ///
                    _skip(6)"fitWidth();" _newline ///
                _skip(6)"}, options.resizeDelay);" _newline ///
            _skip(4)"});" _newline ///
			///
            /// FIT IMAGE BASED ON HEIGHT
            _skip(4)"function fitHeight() {" _newline ///
			///
                _skip(6)"var viewportHeight = $(window).height()," _newline ///
                    _skip(6)"viewportWidth = $(window).width()," _newline ///
                    _skip(6)"naturalWidth = $('#off-screen').width()," _newline ///
                    _skip(6) "naturalHeight = $('#off-screen').height()," _newline ///
                    _skip(6)"newHeight = (viewportHeight * 0.95)," _newline ///
                    _skip(6)"ratio = (newHeight / naturalHeight)," _newline ///
                    _skip(6)"newWidth = (naturalWidth * ratio);" _newline ///
                _skip(6)"$('#lightwrap img').show();" _newline ///
                _skip(6)"if (newHeight > naturalHeight) {" _newline ///
                    _skip(6)"$('#lightwrap img').animate({" _newline ///
                        _skip(6)"height: naturalHeight," _newline ///
                        _skip(6)"width: naturalWidth," _newline ///
                        _skip(6)"left: '50%'," _newline ///
                        _skip(6)"top: '50%'," _newline ///
                        _skip(6)"marginTop: -(naturalHeight / 2)," _newline ///
                        _skip(6)"marginLeft: -(naturalWidth / 2)" _newline ///
                    _skip(6)"}, options.zoominSpeed, options.zoominEasing);" _newline ///
                _skip(6)"} else {" _newline ///
                    _skip(6)"if (newWidth > viewportWidth) {" _newline ///
                        _skip(6)"fitWidth();" _newline ///
                    _skip(6)"} else {" _newline ///
                        _skip(6)"$('#lightwrap img').animate({" _newline ///
                            _skip(6)"height: newHeight," _newline ///
                            _skip(6)"width: newWidth," _newline ///
                            _skip(6)"left: '50%'," _newline ///
                            _skip(6)"top: '2.5%'," _newline ///
                            _skip(6)"marginTop: '0'," _newline ///
                            _skip(6)"marginLeft: -(newWidth / 2)" _newline ///
                        _skip(6)"}, options.zoominSpeed, options.zoominEasing);" _newline ///
                    _skip(6)"}" _newline ///
                _skip(6)"}" _newline ///
            _skip(4)"}" _newline ///
			///
            /// FIT IMAGE BASED ON WIDTH
            _skip(4)"function fitWidth() {" _newline ///
                _skip(6)"var naturalWidth = $('#off-screen').width()," _newline ///
                    _skip(6)"naturalHeight = $('#off-screen').height()," _newline ///
                    _skip(6)"viewportWidth = $(window).width()," _newline ///
                    _skip(6)"viewportHeight = $(window).height()," _newline ///
                    _skip(6)"newWidth = (viewportWidth * 0.95)," _newline ///
                    _skip(6)"ratio = (newWidth / naturalWidth)," _newline ///
                    _skip(6)"newHeight = (naturalHeight * ratio);" _newline ///
                _skip(6)"$('#lightwrap img').show();" _newline ///
                _skip(6)"if (newHeight > naturalHeight) {" _newline ///
                    _skip(6)"if (naturalHeight > viewportHeight) {" _newline ///
                        _skip(6)"fitHeight();" _newline ///
                    _skip(6)"} else {" _newline ///
                        _skip(6)"$('#lightwrap img').animate({" _newline ///
                            _skip(6)"height: naturalHeight," _newline ///
                            _skip(6)"width: naturalWidth," _newline ///
                            _skip(6)"top: '50%'," _newline ///
                            _skip(6)"left: '50%'," _newline ///
                            _skip(6)"marginTop: -(naturalHeight / 2)," _newline ///
                            _skip(6)"marginLeft: -(naturalWidth / 2)" _newline ///
                        _skip(6)"}, options.zoominSpeed, options.zoominEasing);" _newline ///
                    _skip(6)"}" _newline ///
                _skip(6)"} else {" _newline ///
                    _skip(6)"if (newHeight > viewportHeight) {" _newline ///
                        _skip(6)"fitHeight();" _newline ///
                    _skip(6)"} else {" _newline ///
                        _skip(6)"$('#lightwrap img').animate({" _newline ///
                            _skip(6)"height: newHeight," _newline ///
                            _skip(6)"width: newWidth," _newline ///
                            _skip(6)"top: '50%'," _newline ///
                            _skip(6)"left: '2.5%'," _newline ///
                            _skip(6)"marginTop: -(newHeight / 2)," _newline ///
                            _skip(6)"marginLeft: '0'" _newline ///
                        _skip(6)"}, options.zoominSpeed, options.zoominEasing);" _newline ///
                    _skip(4)"}" _newline ///
                _skip(4)"}" _newline ///
            _skip(4)"}" _newline ///
///
///
        _skip(2)"}" _newline ///
    _skip(2)"});" _newline ///
"})(jQuery);" _newline ///
"</script>" _newline(4)





 


	/* ADDING THE SMOOTH ZOOM SCRIPT */
	file write `canvas' "<script type=" `" "text/javascript">"' ///
    " $(window).load( function() {$('img').smoothZoom({ " ///
    "});});</script> " _newline
	   
				file write `canvas' _n "</body>" _n  
				file write `canvas' _n "</html>" _n             
        }
    }
	
		
		if "$format" == "landscape" {
				local add --orientation Landscape --margin-right 13mm ///
				--margin-left 6mm ///
				--margin-top 12mm ///
				--margin-bottom 6mm
				}
				
		if "$format" ~= "landscape" {
				local add ///
				--margin-right 13mm ///
				--margin-left 6mm 
				}		
				

				/* SETTING THE PDF PRINTER */
		
		* Microsoft Windows
		if "`c(os)'"=="Windows" {
				
				*Prince and the default printer setting
				if "$printer" == "prince" | "$printer" == "" {
						
						if "$path" == "" { 
							  cap shell ///
							  C:\program files\prince\engine\bin\prince.exe ///
							  --no-network  --javascript "$htmldoc" -o "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								cap shell $path --no-network  --javascript ///
								"$htmldoc" -o "$pdfdoc"
								}
						}		
						
				if "$printer" == "wkhtmltopdf" {
				
						if "$path" == "" { 
							  shell ///
							  c:\program files\wkhtmltopdf\bin\wkhtmltopdf.exe ///
							  --footer-center [page] --footer-font-size 10 ///
							  `add' ///
							  "$htmldoc" "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								shell $path ///
								--footer-center [page] --footer-font-size 10 ///
								`add' ///
								"$htmldoc" "$pdfdoc"
								}
						}		
				
				*open the pdfdoc
				winexec explorer "$pdfdoc"
				di as txt _newline(2)
				di as txt "| |     / /__  ____ __   _____  _____ "       
				di as txt "| | /| / / _ \/ __ `/ | / / _ \/ ___/ "       
				di as txt "| |/ |/ /  __/ /_/ /| |/ /  __/ /     "       
				
				if "$erase"~="erase" {
				di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' ///
				`"{it:produced {bf:{browse `"${pdfdoc}"'}} and {bf:{browse `"${htmldoc}"'}} reports}"'
				}
				
				if "$erase"=="erase" {
				di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' ///
				`"{it:produced {bf:{browse `"${pdfdoc}"'}} }"'
				}
				
				}
				
				
		
		* Macintosh
		if "`c(os)'"=="MacOSX" {
				
				*Prince and the default printer setting
				if "$printer" == "prince" | "$printer" == "" {
						
						if "$path" == "" { 
							  cap shell /usr/local/bin/prince  ///
							  --no-network  --javascript "$htmldoc" -o "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								cap shell $path --no-network  --javascript ///
								"$htmldoc" -o "$pdfdoc"
								
								}		
						}		
						
				if "$printer" == "wkhtmltopdf" {
				
						if "$path" == "" { 
							  shell /usr/local/bin/wkhtmltopdf ///
							  --footer-center [page] --footer-font-size 10 ///
							  `add' ///
							  "$htmldoc" "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								shell $path ///
								--footer-center [page] --footer-font-size 10 ///
								`add' ///
								"$htmldoc" "$pdfdoc"
								}						
						}
				
				*open the pdfdoc
				shell open "$pdfdoc"
				di as txt _newline(2)
				di as txt "| |     / /__  ____ __   _____  _____ "       
				di as txt "| | /| / / _ \/ __ `/ | / / _ \/ ___/ "       
				di as txt "| |/ |/ /  __/ /_/ /| |/ /  __/ /     "       
				
				if "$erase"~="erase" {
				di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' ///
				`"{it:produced {bf:{browse `"${pdfdoc}"'}} and {bf:{browse `"${htmldoc}"'}} reports}"'
				}
				
				if "$erase"=="erase" {
				di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' ///
				`"{it:produced {bf:{browse `"${pdfdoc}"'}}}"'
				}
					
				}
			
			
		
		*Linux
		if "`c(os)'"=="Unix" {
				
				*Prince and the default printer setting
				if "$printer" == "prince" | "$printer" == "" {
						
						if "$path" == "" { 
							  cap shell /usr/bin/prince  ///
							  --no-network  --javascript "$htmldoc" -o "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								cap shell $path --no-network  --javascript ///
								"$htmldoc" -o "$pdfdoc"
								}		
						}		
						
				if "$printer" == "wkhtmltopdf" {
				
						if "$path" == "" { 
							  shell /usr/bin/wkhtmltopdf ///
							  --footer-center [page] --footer-font-size 10 ///
							  `add' ///
							  "$htmldoc" "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								shell $path ///
								--footer-center [page] --footer-font-size 10 ///
								`add' ///
								"$htmldoc" "$pdfdoc"
								}						
						}
				
				*open the pdfdoc
				shell xdg-open "$pdfdoc"
				di as txt _newline(2)
				di as txt "| |     / /__  ____ __   _____  _____ "       
				di as txt "| | /| / / _ \/ __ `/ | / / _ \/ ___/ "       
				di as txt "| |/ |/ /  __/ /_/ /| |/ /  __/ /     "       
				if "$erase"~="erase" {
				
				di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' ///
				`"{it:produced {bf:{browse `"${pdfdoc}"'}} and {bf:{browse `"${htmldoc}"'}} reports}"'
				}
				
				if "$erase"=="erase" {
				di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     "' ///
				`"{it:produced {bf:{browse `"${pdfdoc}"'}}}"'
				}
				
				}
		
		
		if "$erase"=="erase" {
				cap erase $htmldoc
				}
				
		
		*restore the original scheme
		cap set scheme $savescheme
		
		macro drop weaver
		macro drop format
		macro drop erase
		macro drop style
		macro drop savescheme
		
		
	end










********************************************************************************
				   /*             Weaver reports              */
********************************************************************************


	
	/* ----     report     ---- */
	
	/* create PDF report and opens it up */
	program define report
		version 11
		syntax [anything] [, Export(name) Printer(name) SETpath(str)]
		
		
		if "`anything'"~="" {
				global htmldoc `anything'
				}
				
		if "`export'"~="" {
				global pdfdoc `export'.pdf 
				}		
		
		
				/* SETTING THE PDF PRINTER */
		
				if "$format" == "landscape" {
				local add --orientation Landscape --margin-right 13mm ///
				--margin-left 6mm ///
				--margin-top 12mm ///
				--margin-bottom 6mm
				}
				
		if "$format" ~= "landscape" {
				local add ///
				--margin-right 13mm ///
				--margin-left 6mm 
				}		
				

		
		/* SETTING THE PDF PRINTER */
		
		* Microsoft Windows
		if "`c(os)'"=="Windows" {
				
				*Prince and the default printer setting
				if "$printer" == "prince" | "$printer" == "" {
						
						if "$path" == "" { 
							  cap shell ///
							  C:\program files\prince\engine\bin\prince.exe ///
							  --no-network  --javascript "$htmldoc" -o "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								cap shell $path --no-network  --javascript ///
								"$htmldoc" -o "$pdfdoc"
								}
						}		
						
				if "$printer" == "wkhtmltopdf" {
				
						if "$path" == "" { 
							  shell ///
							  c:\program files\wkhtmltopdf\bin\wkhtmltopdf.exe ///
							  --footer-center [page] --footer-font-size 10 ///
							  `add' ///
							  "$htmldoc" "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								shell $path ///
								--footer-center [page] --footer-font-size 10 ///
								`add' ///
								"$htmldoc" "$pdfdoc"
								}
						}		
				
				*open the pdfdoc
				winexec explorer "$pdfdoc"
				di as txt _newline(2)
				di as txt "| |     / /__  ____ __   _____  _____ "       
				di as txt "| | /| / / _ \/ __ `/ | / / _ \/ ___/ "       
				di as txt "| |/ |/ /  __/ /_/ /| |/ /  __/ /     "       
				di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     {it:produced {bf:{browse `"${pdfdoc}"'}} and {bf:{browse `"${htmldoc}"'}} reports}"'

					
				}
				
				
		
		* Macintosh
		if "`c(os)'"=="MacOSX" {
				
				*Prince and the default printer setting
				if "$printer" == "prince" | "$printer" == "" {
						
						if "$path" == "" { 
							  cap shell /usr/local/bin/prince  ///
							  --no-network  --javascript "$htmldoc" -o "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								cap shell $path --no-network  --javascript ///
								"$htmldoc" -o "$pdfdoc"
								
								}		
						}		
						
				if "$printer" == "wkhtmltopdf" {
				
						if "$path" == "" { 
							  shell /usr/local/bin/wkhtmltopdf ///
							  --footer-center [page] --footer-font-size 10 ///
							  `add' ///
							  "$htmldoc" "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								shell $path ///
								--footer-center [page] --footer-font-size 10 ///
								`add' ///
								"$htmldoc" "$pdfdoc"
								}						
						}
				
				*open the pdfdoc
				shell open "$pdfdoc"
				di as txt _newline(2)
				di as txt "| |     / /__  ____ __   _____  _____ "       
				di as txt "| | /| / / _ \/ __ `/ | / / _ \/ ___/ "       
				di as txt "| |/ |/ /  __/ /_/ /| |/ /  __/ /     "       
				di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     {it:produced {bf:{browse `"${pdfdoc}"'}} and {bf:{browse `"${htmldoc}"'}} reports}"'
					
				}
			
			
		
		*Linux
		if "`c(os)'"=="Unix" {
				
				*Prince and the default printer setting
				if "$printer" == "prince" | "$printer" == "" {
						
						if "$path" == "" { 
							  cap shell /usr/bin/prince  ///
							  --no-network  --javascript "$htmldoc" -o "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								cap shell $path --no-network  --javascript ///
								"$htmldoc" -o "$pdfdoc"
								}		
						}		
						
				if "$printer" == "wkhtmltopdf" {
				
						if "$path" == "" { 
							  shell /usr/bin/wkhtmltopdf ///
							  --footer-center [page] --footer-font-size 10 ///
							  `add' ///
							  "$htmldoc" "$pdfdoc"
							  }
						
						if "$path" ~= "" { 
								shell $path ///
								--footer-center [page] --footer-font-size 10 ///
								`add' ///
								"$htmldoc" "$pdfdoc"
								}						
						}
				
				*open the pdfdoc
				shell xdg-open "$pdfdoc"
				di as txt _newline(2)
				di as txt "| |     / /__  ____ __   _____  _____ "       
				di as txt "| | /| / / _ \/ __ `/ | / / _ \/ ___/ "       
				di as txt "| |/ |/ /  __/ /_/ /| |/ /  __/ /     "       
				di as txt `"|__/|__/\___/\__,_/ |___/\___/_/     {it:produced {bf:{browse `"${pdfdoc}"'}} and {bf:{browse `"${htmldoc}"'}} reports}"'
				
				}

	end	
	
	
	
	
	
	
