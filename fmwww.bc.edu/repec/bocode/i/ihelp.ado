*! version 1.2  16Nov2023
*! version 1.06 2023/7/24 22:57
*         2023/7/24 22:57  添加两个功能：ihelp_ms(MS剪切板) & Section定位
*         2023/5/11 14:25  ihelp
*         2023/4/23 22:11  BUG(Stata14, ihelp import eexcel) --> ihelp_similar line264
*         2023/4/19 11:09  weixin option --> txt option
*         2023/4/16 14:52  line 103 121: local hlp ([D] import_fred --> [D] import fred)
*         2023/4/15 16:58  ihelp_ucap (error: ihelp stata) --> add lines: gen link_a
*         2023/2/23 0:02   clipout support Windows, MacOS
*         2023/2/22 11:23  !echo | set /p=text| clip
*         2023/2/22 10:17, ihelp regress postestimation##estatvif
*  v 1.03 2023/2/18 9:28   findfile, path(BASE)
*         2023/2/17 21:18  add option  -web- 
*         2021/8/23 15:01  add option  -latex-
*  v 1.02 2021/5/19 11:51
*! Author: Yongli Chen, Yujun Lian (arlionn@163.com)

// cap program drop ihelp
program define ihelp, rclass
version 14.0

	syntax [anything(everything)]  ///
	    [, Markdown                ///
		   TXT	                   ///
		   Weixin                  ///
		   Latex                   ///
		   Texfull            	   ///
		   Clipoff                 ///
		   Notip                   ///
		   WEB					   ///
		   Format(integer 0) 	   ///
		   MS					   ///
		]
	if "`txt'"!="" {
		local weixin `txt'	
	}
	if "`anything'"=="" {
		dis as error `"Please input an official Stata command name, see {stata `"help"'}"'
		exit 100
	}
	
*-1.get full command

    if index(`"`anything'"', "#"){                /*add: Lian, 2023/2/18 11:02*/
  	    gettoken mainhlp subcmd: anything, parse("#") /*chg: Lian, 2023/2/22 11:26*/
		local section = "yes"
		local subcmd = subinstr("`subcmd'", "#", "", .)
		local subcmd1 = substr("`subcmd'", 1, 1)
		local subcmd2 = substr("`subcmd'", 2, .)
		local anything "`mainhlp'"                    /*chg: Lian, 2023/2/22 11:26*/
    }
    
	local hlp = subinstr("`anything'", " ", "_", .) //identifiable parameters
	if strmatch("`hlp'", "*()") {
		local hlp = subinstr("`hlp'", "()", "", .)
		local hlp "f_`hlp'"
	}
    local Base `"`c(sysdir_base)'"'
    cap findfile `hlp'.sthlp, path(`"`Base'"')	 /*chg: Lian, 2023/2/18 9:36*/
	*cap findfile `hlp'.sthlp // get the full name of the unrecognized parameter
	if _rc != 0 { // ?help_alisa.maint (include "grogramming function")
		ihelp_similar `hlp', sup
		local hlp1 = `"`r(fname)'"'
		if "`hlp1'" != "" local hlp "`hlp1'"
	}
	
*-2. url of the help documents 

  *-2a.  get pdf-link
	
	local pref_text = fileread(`"`r(fn)'"') //open help file (.sthlp)
	
	if strmatch(`"`pref_text'"', "*mansection*") { //get pdf-link
		local fname = substr(`"`pref_text'"', strpos(`"`pref_text'"', "mansection")+11, 50)
		local fname = lower(substr(`"`fname'"', 1, strpos(`"`fname'"', `""}"')-1))
		local pref  = lower(substr(`"`fname'"', 1, strpos(`"`fname'"', " ")-1))
		local fname = subinstr(`"`fname'"', " ", "", .)
		local fname = subinstr(`"`fname'"', "()", "", .) //mata help file
	}
	
	if `"`fname'"'=="" {
		ihelp_ucap `hlp'
		if `"`r(url)'"' != "" {
			local url = `"`r(url)'"'
			local pref = r(pref)
		}
		else {
			ihelp_similar `hlp', sim c
			if `r(N)'==0 {
		        dis as error `"'`anything'' is not an official Stata command. See {stata `"help `anything'"'}, and {stata "help gs"}, {stata "help help"}"'
				*dis as error `"'`anything'' is unrecognized. Only official Stata command is supported. "' 
				*dis in yellow `"See {stata `"help `hlp'"'}, and {stata "help gs"}, {stata "help help"}"' _n
			}
			else {
				dis as error `"Please input the full name of the command to make the link to help file accurate and unique. See {stata `"help `anything'"'}"' _n
				ihelp_similar `hlp', sim
			}
			exit 0
		}
	}
	else {
		local url "https://www.stata.com/manuals/`fname'.pdf"
	}
  *-2b.  get web-link 增加网页版帮助文件的链接
	if "`url'"!="" {
		local url_web "https://www.stata.com/help.cgi?`hlp'"
	}
  *-2c.  Section
	if "`url'"!="" {
		if "`section'"=="yes" {
			local url_section "`url'#`fname'`=upper("`subcmd1'")'`subcmd2'"
			local url_web_section "`url_web'#`subcmd'"
		}
		else {	
			local url_section "`url'"
			local url_web_section "`url_web'"
		}
	}
	
* 3.open pdfhelp | markdown-link | wechat-link

	if "`web'"=="" {
		local hlp = subinstr("`hlp'", "_", " ", .)
		local text_f1 [**[`=upper("`pref'")']** `hlp'](`url')
		local text_f2 [`hlp'](`url')
		local text_f3 [help `hlp'](`url')
		local mtext_m [**[`=upper("`pref'")']** `hlp'](`url')
		local mtext_w [`=upper("`pref'")'] `hlp': `url'
		local mtext_latex \stihelp[`pref']{`hlp'}  // new command Latex text
		local urlManual "https://www.stata.com/manuals/"
		local mtext_Tex_full "\href{`url'}{\bfseries{[\MakeUppercase{`pref'}] `hlp'}}"
		local link_ms `url'
		// Note: 「\;」 表示Latex中的空格
	/*
	\newcommand{\stihelp}[2][r]{
		\href{https://www.stata.com/manuals/#1#2.pdf}{\bfseries{[\MakeUppercase{#1}] #2}}
	}
	% Usesage in Latex: See \stihelp{regress} and \stihelp[xt]{xtreg}
	*/
	}
	else {
		local hlp = subinstr("`hlp'", "_", " ", .)
		local text_f1 [**[`=upper("`pref'")']** `hlp'](`url_web')
		local text_f2 [`hlp'](`url_web')
		local text_f3 [help `hlp'](`url_web')
		local mtext_m [**[`=upper("`pref'")']** `hlp'](`url_web')
		local mtext_w [`=upper("`pref'")'] `hlp': `url_web'
		local mtext_latex \stihelp[`pref']{`hlp'}  // new command Latex text
		local mtext_Tex_full "\href{`url_web'}{\bfseries{[\MakeUppercase{`pref'}] `hlp'}}"  
		local link_ms `url_web'
	}

	if "`markdown'`weixin'`latex'`texfull'`ms'"=="" & `format'==0 {
		if "`web'"=="" {
			view browse `url_section'
		}
		else {
			view browse `url_web_section'
		}
	}
	else {
		if inlist(`format', 1, 2, 3) {
			dis in y `"`text_f`format''"'
			clipout "`text_f`format''", `clipoff' `notip'
		}
		else if "`markdown'"!="" {
			dis in y `"`mtext_m'"'
			clipout "`mtext_m'", `clipoff' `notip'
		}
		else if "`weixin'"!="" {
			dis in y `"`mtext_w'"'
			clipout "`mtext_w'", `clipoff' `notip'
		}
		else if "`latex'"!="" {
			dis in y `"`mtext_latex'"'
			clipout "`mtext_latex'", `clipoff' `notip'
		}	
		else if "`texfull'"!="" {
			dis in y `"`mtext_Tex_full'"'
			clipout "`mtext_Tex_full'", `clipoff' `notip'
		}
		else if "`ms'"!="" {
			ihelp_ms, url("`link_ms'") b("[`=upper("`pref'")']") t("`hlp'") `clipoff'
		}
	}
	return local link_f3 `text_f3'   	  // Format(3)
	return local link_f2 `text_f2'   	  // Format(2)
	return local link_f1 `text_f1'   	  // Format(1)
	return local link_l2 `mtext_latex'    // Latex text
	return local link_l1 `mtext_Tex_full' // Latex text full
	return local link_txt  `mtext_w'        // Weixin
	return local link_m  `mtext_m'        // Markdown 
	return local link_web `url_web'
	return local link `url'
end

*------------------------------------------------------------ clipout.ado --v2--
*  version 1.01 2023/2/23 16:15
*  echo text to clipboard. Support: Windows, MacOSX

* Tips
* 1. The 'notice' appears no more than 3 times
* 2. Once -NOTIP- specified, the 'notice' will not appear before you restart Stata
* 3. You can execute "global  clipout__times_ = 10" to hind 'notice'
* notice := "Text is on clipboard. Press '`shortcut'' to paste"

* =refs:
*  https://www.alphr.com/echo-without-newline/
*  https://linuxhandbook.com/echo-without-newline/

// cap program drop clipout
program define clipout

    syntax anything [, Clipoff NOTIP]
	
	if "`clipoff'" ~= ""{
		exit 
	}
	
	if "`c(os)'" == "Windows" {
		*local shellcmd `"shell echo | set /p="`anything'" | clip"'
		local shellcmd `"shell echo | set /p=`anything'| clip"'
		local shortcut "Ctrl+V"
	}  
	
	if "`c(os)'" == "MacOSX" {
        local shellcmd `"shell echo -n `anything'| pbcopy"'
		local shortcut "Command+V"
	}
	
	`shellcmd'               // auto copy to clipboard
		
	local tip_times = 5      // the notice appears no more than # times	
	if "`notip'" == ""{	
		global clipout__times_ = $clipout__times_ + 1
	}
	else{
		global clipout__times_ = `=`tip_times'+1'
	}
	if $clipout__times_ <= `tip_times'{
		dis as text "Text is on clipboard. Press '`shortcut'' to paste"
	}
end 
*-----------------------------------------



*-------------------------------------------------------- ihelp_similar.ado ----
// cap program drop ihelp_similar
program define ihelp_similar, rclass

	syntax anything(everything)[, SIMilar SUPplement Count]
	
*-1.获取可识别的命令参数

	local hlp = subinstr("`anything'", " ", "_", .)
  preserve

	local s1 = substr("`anything'", 1, 1)
	cap findfile `s1'help_alias.maint
	if _rc!=0 {
		dis as error `"'`anything'' is not an official Stata command. See {stata `"help `anything'"'}, and {stata "help gs"}, {stata "help help"}"'
		exit 198
	}
	qui import delimited using "`r(fn)'", clear delimiters("\t ", collapse)
	qui count if strmatch(v1, "`hlp'")
	
	//Completion command (v1: all abbreviations v2: corresponding full cmd)
	if "`supplement'"!="" & `r(N)' == 1 {
		qui keep if strmatch(v1, "`hlp'")
		local hlp = v2[1]
		cap findfile `hlp'.sthlp
		return local fn = `"`r(fn)'"'
		return local fname = `"`hlp'"'
    //  return scalar N = 1
	}
	
	//Similar commands
	if "`similar'"!="" {
		qui keep if strmatch(v1, "`hlp'*")
		if "`count'" != "" {			
			cap levelsof v2, clean
			return scalar N = wordcount("`r(levels)'")
			exit 0
		}
		if _N == 0 {
			exit 0
		}
// 		gsort v2 -v1
		qui duplicates drop v2, force
// 		qui replace v1 = v2 if strmatch(v2, v1+"*")
		local cnt = _N
		local dis_text ""
// 		sort v1
		forvalues k = 1/`cnt' {
			local hlp = v2[`k']
// 			local hlp = v1[`k']
			local dis_text `dis_text' {stata `"ihelp `hlp'"': `hlp'} | 
		}
		local dis_text = substr(`"`dis_text'"', 1, strlen(`"`dis_text'"')-2)
		local add_s = cond(`cnt'>1, "s", "")
		dis in y `"Find `cnt' similar command`add_s':"'
		dis in w `"`dis_text'"'
	}
	
  restore
	
end
*-----------------------------------------


*----------------------------------------------------------- ihelp_ucap.ado ----
// cap program drop ihelp_ucap
program define ihelp_ucap, rclass
	syntax anything(everything)
	local hlp = subinstr("`anything'", " ", "_", .)
	clear
	qui set obs 1
	cap findfile `hlp'.sthlp, path(`"`Base'"')
	if _rc == 0 {
		local pref_text = fileread(`"`r(fn)'"')
		if strmatch(`"`pref_text'"', "*findalias*") { // `hlp'.sthlp
			local fname = substr(`"`pref_text'"', strpos(`"`pref_text'"', "findalias")+10, 50)
			local fname = lower(substr(`"`fname'"', 1, strpos(`"`fname'"', "}")-1))
// 			dis in y "`fname'"
			if `"`fname'"' !="" { // asmcl_alias.maint
			  preserve
				qui findfile asmcl_alias.maint
				qui import delimited using "`r(fn)'", clear delimiters("{vieweralsosee", asstring)
				qui replace v1 = trim(v1)
				qui replace v2 = trim(v2)
				qui count if strmatch(v1, `"`fname'"')
				if `r(N)' == 1 {
					qui keep if strmatch(v1, "`fname'")
					qui gen link = substr(v2, strpos(v2, "mansection")+11, strpos(v2, `""}"')-strpos(v2, "mansection")-11)
					qui gen link_a = lower(subinstr(subinstr(v2, "] ", "", .), `""["', "", .))
					qui replace link_a = subinstr(link_a, "example ", "example", .) if strmatch(link_a, "*example*")
					format link_a %20s
					qui replace link_a = substr(link_a, 1, strpos(link_a, " ")-1)
					qui replace link_a = substr(link_a, 1, strpos(link_a, `"""')-1) if strmatch(link_a, `"*""')
					qui replace link_a = substr(link_a, 1, strpos(link_a, ".")-1) if strmatch(link_a, "*.*")
					qui split link
					return local pref = link1[1]
					qui replace link2 = lower(link1) + link2
					gen temp_link = "https://www.stata.com/manuals/" + link_a + ".pdf#" + link2
					return local url "https://www.stata.com/manuals/`=link_a[1]'.pdf#`=link2[1]'"
				}				
			  restore
			}
		}
	}
end
*-----------------------------------------


*----------------------------------------------------------- ihelp_ms.ado ----
// cap program drop ihelp_ms
program define ihelp_ms, rclass
	//clipbord text
	syntax, URL(string) [Bold(string) Text(string) Clipoff]
	if "`clipoff'" ~= ""{
		exit 
	}
	local text_ws <html><body><!--StartFragment--><a href='`url''><strong>`bold'</strong> `text'</a><!--EndFragment--></body></html>
	local ws_start: display %09.0f strpos(`"`text_ws'"', "<html>")
	local ws_end: display %09.0f strpos(`"`text_ws'"', "</html>") + strlen("</html>")
	local ws_startf: display %09.0f strpos(`"`text_ws'"', "<!--StartFragment-->") + strlen("<!--StartFragment-->")
	local ws_endf: display %09.0f strpos(`"`text_ws'"', "<!--EndFragment-->")
	local header_ws Version:1.0\r\nStartHTML:`ws_start'\r\nEndHTML:`ws_end'\r\nStartFragment:`ws_startf'\r\nEndFragment:`ws_endf'\r\nSourceURL:None\r\n
	local text_ws `"`header_ws' `text_ws'"'
	//copy to clipboard through python
	cap {
		python: import sys,win32clipboard
		python: ws_text = "`text_ws'"
		python: ws_text = ws_text.encode().decode("unicode_escape").encode()
		python: CF_HTML = win32clipboard.RegisterClipboardFormat('HTML Format')
		python: win32clipboard.OpenClipboard(0)
		python: win32clipboard.EmptyClipboard()
		python: win32clipboard.SetClipboardData(CF_HTML, ws_text)
		python: win32clipboard.SetClipboardData(13, "`bold'`text'")
		python: win32clipboard.CloseClipboard()
		if "`c(os)'" == "Windows" {
			local shortcut "Ctrl+V"
		}
		if "`c(os)'" == "MacOSX" {
			local shortcut "Command+V"
		}
	}
	if _rc==0 {
		dis in y `"`=upper("`bold'")' `text'"'
		dis as text "Text is on clipboard. Press '`shortcut'' to paste"		
	}
	//if Error
	else {
		dis in red "The rich text punctuated with links cannot be copied to MS documents. Please make sure Python can be used through Stata's interface! Instead, a plain text with links is copied to clipboard."
		if "`web'"=="" {
			local mtext_w `=upper("`bold'")' `text': `url'
		}
		else {
			local mtext_w `=upper("`bold'")' `text': `url_web'
		}
		dis in y `"`mtext_w'"'
		clipout "`mtext_w'", `clipoff' `notip'
	}
end
*-----------------------------------------

/* 

  2023/2/18 0:45 (xxx), update: --------------------------------to be ...-------
  ?????
  - bug: ihelp varlist, m 无前缀[U]的问题（修改 ihelp_ucap modular）（原 []varlist，现[U]varlist）
  - bug: ihelp disp, m 无法显示命令全称的问题（原 [P]disp，现 [P]display）
  - web 选项的输出链接修改（原：pdf链接，现：web链接）
  - 错误提示信息和警告信息
	+ 官方命令识别（修改 ihelp_similar 命令，添加 Count option）
	+ 区别两类错误信息：非官方命令 vs 过短导致无法唯一识别的官方命令
	+ 添加仅输入 ihelp 的提示信息
  - 自定制配文
    + 预设定（添加 Format(integer 0) option），增加三个预设定配文方式

  2021/9/7 12:24 (yongli), update:
    - bug: mata help file (line 37)

  2021/8/23 15:34 (Arlionn), update:
    - add option -Latex- and -Texfull-
	-     so that to display LaTeX link text

  2021/5/3 19:01 (yongli), update: 
	- support function()
	- support situations in which pdf-link is not contained in .sthlp file (e.g. help _variables)
		+ situations in which pdf-link is not directly listed in .sthlp file,
		  but given in the form of SMCL like {findalias asfrvarlists}
		+ the real pdf-link can be indexed from file "asmcl_alias.maint",
		  in which each word corresponds with a ChapterName (pdf-link)
		+ e.g. the word "asfrvarlists" --> ChapterName "[U] 13.4 System variables (_variables)"
		  --> "pdf-link": https://www.stata.com/manuals/u13.pdf#u13.4Systemvariables(_variables)

  2021/5/2 00:08 (yongli), update:
	- adjust the order of each module
	- compatible with stata16
	- ihelp_similar modular: list similar commands

  2021/4/28 00:59 (yongli), update: 
	- handles the case of command abbreviation
	(get abbreviations list from ?help_alisa.maint)

  2021/4/27 18:40 (yongli), update: 
	- three options: markdown, weixin, clipoff
	
  2021/4/27 20:39 (Arlionn)
 
   要全面统计一下[docs/Stata_cmd_PDF_online_Items.md] 文件中【anything】不是
   单个单词的情形有哪些？如果不多，可以用 if 语句解决，否则可以找找规律
   
    - ihelp twoway scatter
	- 
    if wordcount(cmd)>1{
	   cap ihelp cmd
	   if _rc{
	      
	   }
	}		  
*/
