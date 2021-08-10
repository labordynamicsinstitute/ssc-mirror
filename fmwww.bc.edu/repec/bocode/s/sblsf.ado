* Authors:
* Program written by Song Bolin(松柏林) Shenzhen University , China.
* Wechat:songbl_stata
*! Verion: 1.0
*! Update: 2021/7/21 

capture program drop sblsf
program define sblsf

version 14

 syntax [,Page(numlist integer max=1 min=1 >0 ) Style(numlist integer max=1 min=1 >0 <4) Cls Line Gap Mlink Wechat SORT(string)]
	   
qui{
 	if "`cls'"!=""{
		cls
		n dis "" _n
	}  
	
	if "`page'"==""{
		local page=1
	}
	
	if "`page'"!=""{
		if `page'==1{
			local url http://www.statalist.org/forums/forum/general-stata-discussion/general
		}
		else {
			local url http://www.statalist.org/forums/forum/general-stata-discussion/general/page`page'
		}
	}
	
	if "`sort'"!=""{
		if "`sort'"=="title"{
			local url="`url'"+"?filter_sort=title"
		}
		else if "`sort'"=="last"{
			local url="`url'"+"?filter_sort=lastcontent"
		}		
		else if "`sort'"=="start"{
			local url="`url'"+"?filter_sort=created"
		}	
		
		else if "`sort'"=="replie"{
			local url="`url'"+"?filter_sort=replies"
		}
		
		else if "`sort'"=="member"{
			local url="`url'"+"?filter_sort=author"
		}
		
		else if "`sort'"=="like"{
			local url="`url'"+"?filter_sort=votes"
		}	
		
		else{
			dis as  error `"sort() :  invalid sort type"' 
			exit 198		
		}
	}
	
	if ("`mlink'"=="") & ("`wechat'"=="")  {
		preserve		
	}		
	
	clear
	tempfile  html_text  
	cap copy "`url'"  "`html_text'.txt", replace
	local times = 0
	while _rc ~= 0 {
		local times = `times' + 1
		sleep 1000
		cap copy `"`url'"' "`html_text'.txt", replace
		if `times' > 5 {
			n dis as  text _col(3) `"{browse "`url'":(contacting https://www.statalist.org/forums)}"' 			
			disp as error "Internet speeds is too low to get the data"
			exit 601
		}
	}
	
    infix strL v 1-100000 using "`html_text'.txt", clear
    keep if index(v, "js-topic-title") | index(v, "posts-count") | index(v, "views-count")
	gen id = int((_n - 1)/3) + 1 
	egen year = seq(), from(1) to(3) 
	reshape wide v, i(id) j(year) 
	drop id
	replace v2 = ustrregexra(v2, ",","")  
	replace v3 = ustrregexra(v3, ",","")  
	gen post = ustrregexs(0) if ustrregexm(v2, "\d+$")
	gen view = ustrregexs(0) if ustrregexm(v3, "\d+$")
	rename v1 v 
	drop v2 v3
	split v, p(`"<a href="sblsf.ado"')
	split v2, p(`"" class="topic-title js-topic-title">"')	
	split v22, p("</a>")	
	rename v21 link
	rename v221	title
	*replace title = ustrregexra(title, `"""',"") 
	*replace title = ustrregexra(title, "`","") 
	*replace title = ustrregexra(title, "'","") 
	cap keep link title post view 
	compress
	keep in -50/-1
	local n=_N 	
	local col1 = 4
	local col2 = 10
	local col3 = 16
	local col4 = 23 
    n dis   as  text   _skip(70) "{bf:The Stata Forums}" 	
    n dis as txt "{hline}"	
    n dis in text _col(`col1')  "{bf:ID}" _col(`col2') "{bf:Posts}"  _col(`col3') "{bf:Views}"  _col(`col4')  "{bf:Topics}" 
	n dis as txt "{hline}"			
	
	forvalues i = 1/`n' {         
		local link =link[`i']
		local title=title[`i']
		local post =post[`i']	
		local view =view[`i']	
		
		if "`style'"==""{
		    local style = 3
		}
		
		if `style'==3{
			n dis as text  _col(`col1') `"{browse `"`link'"':`i' }"'  _col(`col2') "`post'"  _col(`col3') "`view'" _col(`col4') `"`title'"' 			
		}		
		
		if `style'==2{
			n dis as error   _col(`col1') `"{browse `"`link'"':`i' }"'  _col(`col2') "`post'"  _col(`col3') "`view'" _col(`col4') `"`title'"' 			
		}	
		
		if `style'==1{
			n dis as text _col(`col1')  "`i' " 	_col(`col2') "`post'"  _col(`col3') "`view'" _col(`col4') `"{browse `"`link'"': `title'}"' 
		}		
				
		if "`line'"!=""{
			n dis as txt "{hline}"
		}
		
		if "`gap'"!=""{
			n dis ""
		}
	}
	
	if "`line'"==""{
		n dis as txt "{hline}"
	}	
	n dis as  text _col(3) `"{browse "`url'":(contacting https://www.statalist.org/forums)}"' _n

	if "`wechat'"!=""{
		gen wechat = link+"："+title
		br wechat
	}
				
	if "`mlink'"!=""{
		gen mlink ="- "+"["+title+"]"+"("+link+")"
		br mlink
	}	
}
	if ("`mlink'"=="") & ("`wechat'"=="") {
		restore		
	}			
 end
 