
capture program drop songbl
program songbl
	version 14
	
	local cmd `0'
	gettoken com opt: 0, parse(",")
	gettoken do 0 : 0, parse(" ,")
	gettoken kdo opt : 0, parse(",")
	local ldo = length("`do'")
/*
		di "cmd  "   "`cmd'"  //命令
		di "do   "   "`do'"   //子命令
		di "0    "   "`0'"	//命令-子命令
		di "opt  "   "`opt'"  // ,option
		di "com  "   "`com'"  // 命令 - ,option
        di "kdo  "   "`kdo'"
		exit
*/
	if "`do'" == bsubstr("cie",1,max(3,`ldo')) {
		songbl_cie `0'
		exit
	}
	
	else if "`do'" == bsubstr("dir",1,max(3,`ldo')) {
		songbl_dir `0'
		exit
	}
	else if "`do'" == bsubstr("ssc",1,max(3,`ldo')) {
		songbl_ssc `0'
		exit
	}	
	else if "`do'" == bsubstr("excel",1,max(5,`ldo')) {
		songbl_excel `0'
		exit
	}
	
	else if "`do'" == bsubstr("fy",1,max(2,`ldo')) {
		songbl_fy `0'
		exit
	}
	
	else if "`do'" == bsubstr("get",1,max(3,`ldo')) {
		songbl_get `0'
		exit
	}
	
	else if "`do'" == bsubstr("ssci",1,max(2,`ldo')) {
		songbl_ssci `0'
		exit
	}
	
	else if "`do'" == bsubstr("paper",1,max(5,`ldo')) {
		songbl_paper `0'
		exit
	}	
	else if "`do'" == bsubstr("install",1,max(7,`ldo')) {
		songbl_install `0'
		exit
	}		
	
	else {
		songbl_sbl `cmd'
		exit  
	}
end


capture program drop songbl_sbl
program define songbl_sbl

version 14

syntax [anything(name = class)]  ///
	   [,                       ///
		Mlink                   ///   //  - [推文标题](URL)
		MText                   ///   //    [推文标题](URL)
		MUrl		            ///   // n. [推文标题](URL)
		Wlink                   ///   //    推文标题： URL
		WText                   ///   //    推文标题： URL	
		WUrl		            ///   // n. 推文标题： URL		
		NOCat                   ///   //    不呈现推文分类信息 	
		Cls                     ///   //    清屏后显示结果
		Gap                     ///   //    在输出的结果推文之间进行空格一行
		AUTHor(string)          ///   //    按照推文来源进行检索。	   
		SAVE(string)           	///   //    利用文档打开分享的内容。
		REPLACE                 ///   //    生成分享内容的 STATA 数据集。  
		Line                    ///   //    搜索推文的另一种输出风格，具有划线		
		CLIP                    ///   //	点击剪切分享，与 Wlink 搭配使用
		DROP(string)            ///   //     删除关键词   
		Sou(string)            ///   //     删除关键词   		
		Navigation              ///   //     导航功能
		Num(numlist  integer max=1 min=1 >0 )     /// 
		Table  /// 
	   ] 
	   
*		
*==============================================================================* 		
*==============================================================================* 
qui{
	cap local class=stritrim(`"`class'"') 
	if _rc!=0{
		local class=stritrim("`class'") 	
	}
	tokenize `class'
**# cls-option
	if "`cls'" != ""{
		cls
		n dis ""
	}																					

**# gap-option			
	if "`gap'" != "" {		 
		local gap dis ""
		local gap1 post songbl_post  ("" ) 
	} 
	
**# sou-option	
	if "`sou'"!=""{       
		tokenize `sou'
		local 1=ustrleft("`1'",1)             

		if strmatch("计量圈","*`1'*")==1 | "`sou'"=="q"{
			view browse  "https://data.newrank.cn/m/s.html?s=OjAqNjI2LjxI&k=`class'"	
			exit
		}
		
		else if strmatch("百度","*`1'*")==1 | "`sou'"=="b"{	       
			view browse  "https://www.baidu.com/s?&wd=`class'"	  
			exit          
		}
		
		else if strmatch("微信公众号","*`1'*")==1 | "`sou'"=="w"{	  
			view browse  "https://weixin.sogou.com/weixin?type=2&query=`class'"
			exit          
		}
	  
	   
		else if strmatch("经管之家","*`1'*")==1 | "`sou'"=="j"{	       
			view browse  "http://sou.pinggu.org/cse/search?q=`class'&s=4433512227215735158&nsid=0"	 
			exit            
		}	
			  
		else if strmatch("知乎","*`1'*")==1 | "`sou'"=="z"{	       
			view browse  "https://www.zhihu.com/search?type=content&q=`class'"	 
			exit            
		}   
		
		else if strmatch("全部","*`1'*")==1 |  "`sou'"=="all" {	       
			view browse  "https://data.newrank.cn/m/s.html?s=OjAqNjI2LjxI&k=`class'"	 
			view browse  "https://www.baidu.com/s?&wd=`class'"	  
			view browse  "https://weixin.sogou.com/weixin?type=2&query=`class'" 
			view browse  "http://sou.pinggu.org/cse/search?q=`class'&s=4433512227215735158&nsid=0"
			view browse  "https://www.zhihu.com/search?type=content&q=`class'"	            
			exit            
		}         
			 
		else {	  
			dis as error `"  (`sou') 不是正确的搜索来源，仅包括计量圈、百度、微信公众号、经管之家、知乎"' 
			dis as text _n `"  试试："'
			dis as text _col(5)`"  {stata " songbl `class',s(计量圈) "}  或  {stata " songbl `class',s(百度) "}"'                
			dis as text _col(5)`"  {stata " songbl `class',s(公众号) "}  或  {stata " songbl `class',s(知乎) "}"'  _n
			dis as text _col(5)`"  {stata " songbl `class',s(经管家) "}  或  {stata " songbl `class',s(全部) "}"'  _n
			exit         
		} 
	exit 
	}	
	
**# Navigation-option
	//动态导航功能设置
	local path https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com
	local URL "`path'/navigation"
	
	if "`class'"=="" {      
		n songbl_links ,url(`URL'/songbl.txt)
		exit
	}	
	 if "`class'"=="data"{						
		n songbl_links ,url(`URL'/data.txt) 
		exit
	} 
	if "`class'"=="sj"{						
		n songbl_links1 ,url(`URL'/sj.txt) 
		exit
	} 	
	if "`class'"=="happy"{
		n songbl_links ,url(`URL'/happy.txt)
		exit
	} 
	if "`class'"=="zw"{			            	
		n songbl_links1 , url(`URL'/zw.txt)          
		exit
	}	
	if "`class'"=="paper"{
		n songbl_links1  ,url(`URL'/paper.txt)
		exit
	}	        		
	if "`class'"=="stata"{
		n songbl_links1  , url(`URL'/stata.txt)  
		exit
	} 
	if "`class'"=="all"{		
		n songbl_links1  , url(`URL'/all.txt)
		exit
	}  	
	//批量获取导航链接 		
	if "`navigation'"!=""{
		tempfile  html_text
		cap copy `"`URL'/link.txt"' `"`html_text'.txt"', replace  			
		local times = 0
		while _rc ~= 0 {
			local times = `times' + 1
			sleep 1000
			cap copy `"`URL'"' `"`html_text'.txt"', replace
			if `times' > 2 {
				disp as error "Internet speeds is too low to get the data"
				exit 601
			}
		}
		infix strL v 1-100000 using `"`html_text'.txt"', clear
		cap erase `"`html_text'.txt"'       			
		split v,  p("++")       
		keep v1 v2 v3	
		local o_class= "`class'"
		levelsof v1 , clean
		if  strmatch("`r(levels)'","*`class'*")==0{
			dis as error `"  导航格式错误"'  
			dis as error `"  查看导航目录：{stata "songbl all"}"'                
			exit 601
		}
		local N=_N
		forvalues i =1/`N'{
			local v1_`i'=v1[`i']
			local v2_`i'=v2[`i']
			local v3_`i'=v3[`i']
			if "`class'"=="`v1_`i''"{
				local URL   "`v3_`i''"			
				`v2_`i'' , url(`URL')
				exit
			}	     
		}	
	exit	
	}	
		
**# replace-option							            	            			
	if ("`replace'"=="") {
		preserve		
	}	
	
	// 避免变量与用户变量冲突	
	clear    	
	
	//推文链接与标题	
	local path https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com
	local url "`path'/songbl/songbl.txt"
	tempfile  html_text  html_text_dta  html_text_seminar_paper_dta Share_txt  songbl_post 
	capture copy `"`url'"' `"`html_text'.txt"', replace  
	local times = 0
	while _rc ~= 0 {
		local times = `times' + 1
		sleep 1000
		capture copy `"`stata_paper_youdao'"' `"`html_text'.txt"', replace
		if `times' > 3 {
			disp as error "Internet speeds is too low to get the data"
			exit 601
		}
	}
	infix strL v 1-100000 using `"`html_text'.txt"', clear
	capture erase `"`html_text'.txt"'
	
	//文本分割
	split v,p("++")       
	if _rc ~= 0 {
		di as err "Failed to get the data"
		exit 601
	}	

	//链接 标题	内容分类 作者 形式分类 日期                 
	rename (v1-v6) (link title style type seminar_paper date)
	
   //推文作者排序	 
	gen type2=.
	replace type2=1  if type=="连享会"
	replace type2=2  if type=="学术论文"
	replace type2=3  if type=="论文代码"
	replace type2=4  if type=="do文档"
	replace type2=5  if type=="微信公众号"
	replace type2=6  if type=="爬虫俱乐部"
	replace type2=7  if type=="经管之家"
	replace type2=8  if type=="简书"
	replace type2=9  if type=="知乎"
	replace type2=10 if type=="B站"
	replace type2=11 if type=="新浪博客"
	replace type2=12 if type=="Stata书籍" 
	replace type2=13 if type=="其他类型" 
	
	//后续检索关键词不区分大小写		
	gen title1 = lower(title) 
	gen style1 = lower(style) 
	gen text   =title1+" "+style1
	gen ad     = strmatch(type,"*songbl*")
	drop if strmatch(seminar_paper,"*advert*")==1
	drop if strmatch(type,"*ad*")==1
	replace seminar_paper="推文" if seminar_paper=="专题"  

    //获取一些链接
	local link_row1 = link[1]
	*local new_title =title[1]
	*local search_link =link[2]
	drop if seminar_paper==""
    local Verion=usubinstr("`link_row1'","Verion","",.)
	if `Verion'>=2.2{
	    di as error "系统发现 {bf:{it:songbl}} 命令有更新，同意更新请输入：{bf:Y} ,否则输入：{bf:N} _____" _request(updatesongbl) 

		if "$updatesongbl"=="Y"{
		    songbl install songbl,replace
			n dis as txt "更新完毕!"
			n dis "请输入：" `"{stata "clear all":clear all }"' "清除内存中的旧程序,否则会重复更新"			
			exit
		}
		else if "$updatesongbl"=="N"{
		    n dis as txt "旧版本已经停止服务,请及时更新"
		    exit 
		}	
		else{
		    n dis as txt "输入错误，请输入大写 Y 或 N "
			exit 100
		}		
	}
	
**# author-option
	keep if strmatch(type,"*`author'*")==1    
	
**# drop-option
	foreach class_drop of local drop{
		drop if strmatch(text,"*`class_drop'*") 
	}

**# 筛选关键词      
	//输入1个关键词
	if "`1'"!="" & "`2'"=="" {   
		if "`class'"=="new"{	
			if  "`num'"==""{
				local num=10
			}			    
			sort date type style title	
			drop if title=="new_songbl"
			drop in 1
			drop if seminar_paper=="论文"
			drop if type=="songbl"
			cap keep in -`num'/ -1 	    
		}
		else{
		    capture local 1 = strlower(`"`1'"') 
			if _rc!=0{
				local 1 = strlower("`1'")	
			}
			capture gen yjy1 = strmatch(text,`"*`1'*"') 
			if _rc!=0{
				gen yjy1 = strmatch(text,"*`1'*") 
			}
			keep if yjy1==1 | ad==1 
		}			 			 				
	}	
	
	//输入两个及以上关键词 
	else{			
		if strmatch("`class'","*+*")==1 & strmatch("`class'","*-*")==1{
			dis as error `"  "+" 或者 "-" 号不能同时选择"' 
			exit 198
		}				
		if strmatch(`"`class'"',"*+*")==1{
			local class_new = subinstr(`"`class'"',"+"," ",.)		
			tokenize `class_new'
			local wordn = wordcount("`class_new'")
			forvalues i = 1/`wordn'{
				local `i' = strlower(`"``i''"')   
				gen yjy`i'   = strmatch(text,`"*``i''*"') 
			}  			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error  `"  songbl :  invalid songbl type"'	
				exit 198	
			}			
			keep if yjy>=1|ad==1
		}			
		else if strmatch(`"`class'"',"*-*")==1{
			local class_new = subinstr(`"`class'"',"-"," ",.)		
			tokenize `class_new'
			local wordn = wordcount("`class_new'")
			forvalues i = 1/`wordn'{
				local `i' = strlower(`"``i''"')  
				gen yjy`i' = strmatch(text,`"*``i''*"') 
			}  			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error  `"  songbl :  invalid songbl type"'	
				exit 198	
			}
			keep if (yjy1==1 & yjy==1)  | ad==1
		}
		else{
			local class_new = subinstr(`"`class'"',"-"," ",.)		
			tokenize `class_new'
			local wordn = wordcount(`"`class_new'"')
			forvalues i = 1/`wordn'{	
				local `i' = strlower(`"``i''"')  
				gen yjy`i' = strmatch(text,`"*``i''*"') 
			}  
			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error `"  songbl :  invalid songbl type"'	
				exit 198	
			}			
			keep if yjy==`wordn'| ad==1
		}
		
	}  
	
	local n =_N                  
	local ad =ad[1]
	count if ad==1
	local coun_ad=`n'-`r(N)'	
	n if `coun_ad'<=0{		
		dis as error  `"  {bf:抱歉，没有找到与 [ {it:`class'} ] 相关的内容。}"' _n
		dis as red    `"  试试：{stata "songbl":[分类查看推文]}"'  `"  或者  {stata "h songbl_cn":[查看帮助文档]}"' _n
		dis as text   `"  或者试试网页搜索："'
		dis as text _col(5)`"  {stata " songbl `*',s(计量圈) "}  或  {stata " songbl `*',s(百度) "}"'                   
		dis as text _col(5)`"  {stata " songbl `*',s(公众号) "}  或  {stata " songbl `*',s(知乎) "}"'  
		dis as text _col(5)`"  {stata " songbl `*',s(经管家) "}  或  {stata " songbl `*',s(全部) "}"' _n    
		dis as red    `"  或者试试检索代码：{stata "songbl `*',cie"}"' _n 
		dis as text   `"  如果您发现{bf:songbl}命令的使用bug，或者对{bf:songbl}命令的改善有什么建议"'
		dis as text   `"  您可以通过以下链接填写资料告知我们"' 
		dis as error  `"  {bf:点击链接:}"'
		dis as text _col(8)  `"  ({browse "https://www.wjx.top/vm/ekn2Nl0.aspx":https://www.wjx.top/vm/ekn2Nl0.aspx})"'  
		dis ""
		exit
	}       
			
**# 关键词打印  


	if "`table'"!=""{
		local start: disp %dCYND date("`c(current_date)'","DMY")
		local year  = substr("`start'",1,4)
		local month = substr("`start'",5,2)
		local day   = substr("`start'",7,2)
		local cur_time "`year'""年""`month'""月""`day'""日"   
		if  "`num'"==""{
			local num=10
		}	
		sort date type style title	
	    local n =_N
        local all_n=_N	
		n dis as text _skip(45) "{bf:Hello, Songbl Stata}" _n
		
		if  `num'>`all_n'{
			n dis as  text _col(4) "以下为全部`author'推文:共`all_n'篇"  _col(88) "`year'-`month'-`day' `c(current_time)'" 
		}
		else{
			n dis as  text _col(4) "以下为`all_n'篇`author'{bf:`class'}推文"   _col(88) "`year'-`month'-`day' `c(current_time)'" 
		}
		n dis as txt "{hline 135} "	
		n dis in text _col(4) "{bf:Url}" _col(12) "{bf:Model}" _col(29) `"{bf:Author}"' _col(45) `"{bf:Type}"' _col(60) `"{bf:Date}"' _col(75) `"{bf:Title}"'
		n dis as txt "{hline 135} "		
		n `gap'
		forvalues i = 1/`n' {         
			local link=link[`i']
			local title=title[`i']
			local type=type[`i']
			local style=style[`i']
			local seminar_paper =seminar_paper[`i']  
			local date =date[`i']
			if strmatch(`"`link'"',"* *")==1{
				n dis  _col(5) `"{stata `"`link'"':-}"'  _col(9) `"{stata songbl `style',table: `style'}"'   ///
				_col(29) `"`type'"' _col(45)  `"`seminar_paper'"'	  _skip(8)  `"`date'"'  _skip(8)  `"`title'"'
			}
			else {
				n dis  _col(5) `"{browse `"`link'"':-}"'  _col(9) `"{stata songbl `style',table: `style'}"'   ///
				_col(29) `"`type'"' _col(45)  `"`seminar_paper'"'	  _skip(8)  `"`date'"'  _skip(8)  `"`title'"'	                        
			}						                    
			if "`line'"!=""{
				n `gap'
				n dis as txt "{hline 135} "
			} 
			n `gap'
		}   
		if "`line'"==""{
			n dis as txt "{hline 135} "	
		}         
		n dis as  text _col(3) `"{stata  songbl 公告: (Songbl平台公告与资源上传)}"' _n	     
		cap drop if strmatch(`"link,"* *")		
		if  "`mlink'" !="" | "`mtext'" !="" | "`murl'" !=""{
			capture postclose songbl_post
			postfile songbl_post str1000 Share using "`songbl_post'", replace
			local all_n=_N	
			post songbl_post  (`"#### <center>songbl命令中`all_n'篇`author'`class'推文</center>"')                                                           
			post songbl_post    (`" Model | Author |Type  |Date | Title"')
			n dis as text `"#### <center>songbl命令中`all_n'篇`author'`class'推文</center>"' 
			n dis as  text `" Model | Author |Type  |Date | Title"'
			post songbl_post    (`":---|:---|:---|:---|:---"')
			n dis as  text `":---|:---|:---|:---|:---"'
			*local n  =_N
			forvalues i = 1/`n' {         
				local link=link[`i']
				local title=title[`i']
				local type=type[`i']
				local style=style[`i']
				local seminar_paper =seminar_paper[`i']  
				local date =date[`i']
				n dis as  text `"`style'|`type'|`seminar_paper'|`date'|[`title'](`link')"'
				post songbl_post    (`"`style'|`type'|`seminar_paper'|`date'|[`title'](`link')"')
			}
			postclose songbl_post                        
			use "`songbl_post'", clear
			if ("`replace'"!="") {   
				capture format %-200s Share  
				br       
			}                        
			if ("`save'"!="") { 
				capture format %-200s Share  
				export delimited Share using "`Share_txt'.`save'" , ///
				novar nolabel delimiter(tab) replace				
				view browse  "`Share_txt'.`save'"	        
			}	                        
		}
		exit    
	}	
	else if  "`wlink'" =="" & "`wtext'"=="" & "`mlink'"=="" & "`mtext'"=="" & "`murl'"=="" & "`wurl'"=="" {
		//保存关键词 "class" 搜索到的数据   
		save "`html_text_dta'",replace	  
		levelsof seminar_paper,local(seminar_paper) 
		foreach seminar_paper in `seminar_paper'{ 
			use "`html_text_dta'",clear
			keep if seminar_paper==`"`seminar_paper'"'
			save "`html_text_seminar_paper_dta'",replace
			levelsof style,local(number) 
			foreach num in `number' { 
				use "`html_text_seminar_paper_dta'",clear
				keep if style=="`num'"
				local n=_N
				if `n'>0{
					sort type2 title   
					if missing("`nocat'"){										
						n dis as w `" `seminar_paper' >>"' `"{stata "songbl `num'": `num'}"'
					}
					forvalues i = 1/`n'{         
						local link=link[`i']
						local title=title[`i']
						capture dis strmatch(`"`link'"',"* *")==1
						if _rc==0{
							if strmatch(`"`link'"',"* *")==1{										
								n dis _col(4) `"{stata `"`link'"': `title'}"'
							}			 				 
							else{
								n dis _col(4) `"{browse `"`link'"': `title'}"'
							}																
						}
						else{
							if strmatch("`link'","* *")==1{	
								n dis _col(4) `"{stata `"`link'"': `title'}"'
							}			 				 
							else{
								n dis _col(4) `"{browse `"`link'"': `title'}"'
							}															 										
						}
						n `gap'
					}
			   }
				if missing("`nocat'"){
					n dis ""
				}
			}			
		}				
		if "`save'"!="" {
			dis as error `" 命令格式有误，see { stata  " help songbl_cn" }"'
			dis as error `" Note:save 选择项必须与 wlink 、wtext 、mlink 、mtext、murl、wurl 等分享功能一起使用  "' 
			exit 198	
		}		
		use "`html_text_dta'", clear
	}	

	else{	
		if  "`mlink'" !="" | "`mtext'" !="" | "`murl'" !=""{
			drop  if strmatch(link,`"* *"')==1 
		}
		save "`html_text_dta'", replace	  // 保存关键词 "class" 搜索到的数据    
		capture postclose songbl_post
		postfile songbl_post str1000 Share using "`songbl_post'", replace	
		
**# wlink-option						 			  
		if "`wlink'" !=""{	              
			n dis ""	
			n dis as txt _n "{hline 24} wlink文本格式 {hline 24}"	
			n dis as txt	
			n dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
			n dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl `class'"
			post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
			post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl `class'") 	
			n dis as txt	
			post songbl_post  (" ") 
			levelsof seminar_paper,local(seminar_paper) 	
			local m=_N			
			foreach seminar_paper in `seminar_paper' { 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'", replace					                    
				levelsof style,local(number) 
				foreach num in `number'{ 
					use "`html_text_seminar_paper_dta'", clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort type2   title
						if missing("`nocat'"){							
							n dis as w _col(4) " `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 							
							n `gap' 
							`gap1'
							post songbl_post  ("    `seminar_paper' >> `num'" ) 
														
						}														
						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']	
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								post songbl_post (`"`title': `link'"') 
							}
							if  "`clip'"==""{
								n dis as y `"`title': `link'"'
							}
							else{
								local  clip1 `"`title': `link'"'
								local  clip2 `"`title': `link'"'
								n dis `"{stata `"!echo `clip1'       Copy by #公众号:songbl | clip"': `clip2'}"'
							}
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						n dis ""
						post songbl_post  (" " ) 
					}        
				}
			}	
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"			
			n dis as red "{bf:小提示：}" `"使用 {stata `"songbl `class', w clip "':songbl `class', w clip} 后，"' "点击超链接，按Ctrl+V可进行粘贴"                      
			n dis as red  "        建议分多次复制到微信对话框，每次 10 行，否则超链接无法生效"
			n dis as red   "        长链接断行导致打印失败。请使用" `" {stata `"songbl `class',w replace"':songbl `class', w replace }"' "或者" `" {stata `"songbl `class',w save(txt)"':songbl `class',w save(txt)}"'       
		}

**# wtext-option		
		if "`wtext'" !=""{		
			n dis ""	
			n dis as txt _n "{hline 24} wtxt文本格式 {hline 24}"	
			n dis as txt				
			n dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
			n dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl `class'"
			post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
			post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl `class'")  	
			n dis as txt	
			post songbl_post  (" ") 		
			use "`html_text_dta'", clear
			levelsof seminar_paper , local(seminar_paper) 	
			local m=_N			
			foreach  seminar_paper  in  `seminar_paper' { 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'", replace					                    
				levelsof style,local(number) 
				foreach num in `number'{ 
					use "`html_text_seminar_paper_dta'", clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort type2   title
						if missing("`nocat'"){
							n dis as w _col(4) " `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 						
							post songbl_post ("    `seminar_paper' >> `num'" ) 								
							n `gap'
							`gap1'
						}	     					
						forvalues i = 1/`n'{         
							local link=link[`i']
							local title=title[`i']
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								n dis  as text `"`title'"'
								n dis  as text `"`link'"'								
								post songbl_post  (`"`title'"') 
								post songbl_post  (`"`link'"') 	
							}
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						post songbl_post  (" " ) 					
						n dis ""
					}         
				}
			}	
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"
			n dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',wt replace"':songbl `class',wt replace }"' "或者" `" {stata `"songbl `class',wt save(txt)"':songbl `class',wt save(txt)}"' 					
		}		

**# wurl-option		
		if "`wurl'"  !=""{
			n dis ""	
			n dis as txt _n "{hline 24} wurl文本格式 {hline 24}"	
			n dis as txt				
			n dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
			n dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl `class'"
			post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
			post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl `class'") 	
			n dis as txt	
			post songbl_post  (" ") 		
			use "`html_text_dta'", clear
			levelsof seminar_paper , local(seminar_paper) 	
			local m=_N
			foreach  seminar_paper  in  `seminar_paper' { 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'", replace					                    
				levelsof style , local(number) 
				foreach  num  in  `number' { 
					use  "`html_text_seminar_paper_dta'", clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort type2   title 
						if missing("`nocat'"){
							n dis as w _col(4) " `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 
							post songbl_post  ("    `seminar_paper' >> `num'" ) 							
							n `gap' 
							`gap1'
						}	
						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']		
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								if `n'==1{
									n dis as text `"`title': `link'"'
									post songbl_post  (`"`title': `link'"') 								
								}
								else {
									n dis as text `"`i'. `title': `link'"'
									post songbl_post  (`"`i'. `title': `link'"') 
								}	
							}
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						post songbl_post  (" " ) 					
						n dis ""
					}         
				}
			}	
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
			n dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',wu replace"':songbl `class',wu replace }"' "或者" `" {stata `"songbl `class',wu save(txt)"':songbl `class',wu save(txt)}"					
		}		

**# mlink-option					
		if "`mlink'" !=""{
			n dis ""	
			n dis as txt _n "{hline 24} mlik文本格式 {hline 24}"	
			n dis as txt				
			n dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
			n dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl `class'**"
			post songbl_post  ("# <center>`class'</center>") 
			post songbl_post  ("**以下推文列表由 **lianxh** 与 **songbl** 命令生成**")                     
			post songbl_post  ("```")    					
			post songbl_post  ("Note：产生如下推文列表的 Stata 命令为：")  
			post songbl_post  (". lianxh `class'")  
			post songbl_post  (". songbl `class'")  
			post songbl_post  ("安装最新版 lianxh/songbl命令：")    					
			post songbl_post  (". ssc install lianxh, replace ")  
			post songbl_post  (". ssc install songbl, replace")  										
				post songbl_post  ("```")  
			post songbl_post  ("---") 
			n dis as txt "---"				
			use "`html_text_dta'",clear
			levelsof seminar_paper , local(seminar_paper) 		
			local m=_N
			foreach  seminar_paper in `seminar_paper'{ 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'", replace					                    
				levelsof style , local(number) 
				foreach num in `number'{ 
					use "`html_text_seminar_paper_dta'", clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort type2   title
						if missing("`nocat'"){
							n dis as w _col(4) "### `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 
							post songbl_post  ("### `seminar_paper' >> `num'" ) 							
							n `gap' 
							`gap1'
						}	 
						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']		
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								n dis as text `"- [`title'](`link')"'
								post songbl_post  (`"- [`title'](`link')"') 
							}
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						post songbl_post  (" " ) 					
						n dis ""
					}         
				}
			}	
			post songbl_post  ("## **Stata** 交流群微信：songbl_stata")  					
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"		
			n dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用：" `" {stata `"songbl `class',m replace"':songbl `class',m replace }"'
			n dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',m save(txt)"':       songbl `class',m save(txt)}"' 
		}

**# mtext-option
		if "`mtext'" !=""{
			n dis ""	
			n dis as txt _n "{hline 24} mtext文本格式 {hline 24}"	
			n dis as txt				
			n dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
			n dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl `class'**"
			post songbl_post  ("# <center>`class'</center>") 
			post songbl_post  ("**以下推文列表由 **lianxh** 与 **songbl** 命令生成**")                     
			post songbl_post  ("```")    					
			post songbl_post  ("Note：产生如下推文列表的 Stata 命令为：")  
			post songbl_post  (". lianxh `class'")  
			post songbl_post  (". songbl `class'")  
			post songbl_post  ("安装最新版 lianxh/songbl命令：")    					
			post songbl_post  (". ssc install lianxh, replace ")  
			post songbl_post  (". ssc install songbl, replace")  					
				post songbl_post  ("```")  
			n dis as txt "---"	
			post songbl_post  ("---") 			
			use "`html_text_dta'", clear
			levelsof seminar_paper,local(seminar_paper) 
			local m=_N
			foreach  seminar_paper in `seminar_paper'{ 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'",replace					                    
				levelsof style,local(number) 
				foreach num in `number' { 
					use "`html_text_seminar_paper_dta'",clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort type2   title
						if missing("`nocat'"){
							n dis as w _col(4) "### `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 
							post songbl_post  ("### `seminar_paper' >> `num'" ) 							
							n `gap' 
							`gap1'
						}								   
						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']		
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								n dis as text `"[`title'](`link')"'
								post songbl_post  (`"[`title'](`link')"') 
							}														
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						post songbl_post  (" " ) 					
						n dis ""
					}          
				}
			}	
			post songbl_post  ("## **Stata** 交流群微信：songbl_stata")  				
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
			n dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用：" `" {stata `"songbl `class',mt replace"':songbl `class',mt replace }"'
			n dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',mt save(txt)"':       songbl `class',mt save(txt)}"' 
		}		

**# murl-option		
		if "`murl'"  !=""{
			n dis ""	
			n dis as txt _n "{hline 24} murl文本格式 {hline 24}"	
			n dis as txt				
			n dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
			n dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl `class'**"
			post songbl_post  ("# <center>`class'</center>") 
			post songbl_post  ("**以下推文列表由 **lianxh** 与 **songbl** 命令生成**")                     
			post songbl_post  ("```")    					
			post songbl_post  ("Note：产生如下推文列表的 Stata 命令为：")  
			post songbl_post  (". lianxh `class'")  
			post songbl_post  (". songbl `class'")  
			post songbl_post  ("安装最新版 lianxh/songbl命令：")    					
			post songbl_post  (". ssc install lianxh, replace ")  
			post songbl_post  (". ssc install songbl, replace")  					
				post songbl_post  ("```")  
			n dis as txt "---"	
			post songbl_post  ("---") 				
			use "`html_text_dta'", clear
			levelsof seminar_paper,local(seminar_paper) 
			local m=_N
			foreach  seminar_paper in `seminar_paper'{ 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'",replace					                    
				levelsof style,local(number) 
				foreach num in `number' { 
					use "`html_text_seminar_paper_dta'",clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort type2   title
						if missing("`nocat'"){
							n dis as w _col(4) "### `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 
							post songbl_post  ("### `seminar_paper' >> `num'" ) 							
							n `gap' 
							`gap1'
						}   
						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								if `n'==1{
									n dis ""
									n dis as text `"[`title'](`link')"'								
									post songbl_post  ("") 
									post songbl_post  (`"[`title'](`link')"') 	
									
								}
								else {
									n dis as text `"`i'. [`title'](`link')"'
									post songbl_post  (`"`i'. [`title'](`link')"') 	
								}
							}																
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						post songbl_post  (" " ) 					
						n dis ""
					}           
				}
			}		
			post songbl_post  ("## **Stata** 交流群微信：songbl_stata")  				
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
			n dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用：" `" {stata `"songbl `class',mu replace"':songbl `class',mu replace }"'
			n dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',mu save(txt)"':       songbl `class',mu save(txt)}"' 
		}					
		
		postclose songbl_post
		use "`songbl_post'", clear
		cap format %-200s Share          
	}	
	
	if ("`replace'"!="") {
		cap keep  link title style type seminar_paper
		cap label variable link "链接"
		cap label variable title "标题"
		cap label variable style "分类"
		cap label variable type "来源"
		cap label variable seminar_paper "论文 or 推文"     
		cap label variable data "更新时间"    
	}			

**# save-option							
	if ("`save'"!="") {	         
		export delimited Share using "`Share_txt'.`save'" , ///
		novar nolabel delimiter(tab) replace				
		view browse "`Share_txt'.`save'"		
	}		
	cap erase `"`html_text'.txt"'   	
	if ("`replace'"=="") {	
		restore           
	} 	
}
end
	




capture program drop songbl_ssci
program define songbl_ssci

version 14

syntax [anything(name = class)][,Cls Gap DROP(string) Sou(string)] 
	   
*		
*==============================================================================* 		
*==============================================================================* 
qui{
	cap local class=stritrim(`"`class'"') 
	if _rc!=0{
		local class=stritrim("`class'") 	
	}
	tokenize `class'
	
**# cls-option
	if "`cls'" != ""{
		cls
		n dis ""
	}																					

**# gap-option			
	if "`gap'" != "" {		 
		local gap dis ""
	} 
	
	if "`class'" == ""{
		n songbl SSCI期刊
		exit
	}	
	
**# sou-option	
	if "`sou'"!=""{       
		tokenize `sou'
		local 1=ustrleft("`1'",1)             

		if strmatch("计量圈","*`1'*")==1 | "`sou'"=="q"{
			view browse  "https://data.newrank.cn/m/s.html?s=OjAqNjI2LjxI&k=`class'"	
			exit
		}
		
		else if strmatch("百度","*`1'*")==1 | "`sou'"=="b"{	       
			view browse  "https://www.baidu.com/s?&wd=`class'"	  
			exit          
		}
		
		else if strmatch("微信公众号","*`1'*")==1 | "`sou'"=="w"{	  
			view browse  "https://weixin.sogou.com/weixin?type=2&query=`class'"
			exit          
		}
	  
	   
		else if strmatch("经管之家","*`1'*")==1 | "`sou'"=="j"{	       
			view browse  "http://sou.pinggu.org/cse/search?q=`class'&s=4433512227215735158&nsid=0"	 
			exit            
		}	
			  
		else if strmatch("知乎","*`1'*")==1 | "`sou'"=="z"{	       
			view browse  "https://www.zhihu.com/search?type=content&q=`class'"	 
			exit            
		}   
		
		else if strmatch("全部","*`1'*")==1 |  "`sou'"=="all" {	       
			view browse  "https://data.newrank.cn/m/s.html?s=OjAqNjI2LjxI&k=`class'"	 
			view browse  "https://www.baidu.com/s?&wd=`class'"	  
			view browse  "https://weixin.sogou.com/weixin?type=2&query=`class'" 
			view browse  "http://sou.pinggu.org/cse/search?q=`class'&s=4433512227215735158&nsid=0"
			view browse  "https://www.zhihu.com/search?type=content&q=`class'"	            
			exit            
		}         
			 
		else {	  
			dis as error `"  (`sou') 不是正确的搜索来源，仅包括计量圈、百度、微信公众号、经管之家、知乎"' 
			dis as text _n `"  试试："'
			dis as text _col(5)`"  {stata " songbl `class',s(计量圈) "}  或  {stata " songbl `class',s(百度) "}"'                
			dis as text _col(5)`"  {stata " songbl `class',s(公众号) "}  或  {stata " songbl `class',s(知乎) "}"'  _n
			dis as text _col(5)`"  {stata " songbl `class',s(经管家) "}  或  {stata " songbl `class',s(全部) "}"'  _n
			exit         
		} 
	exit 
	}	
	
	preserve		

	
	// 避免变量与用户变量冲突	
	clear    	
	
	//推文链接与标题	
	local path https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com
	local url "`path'/songbl/ssci.txt"
	tempfile  html_text  html_text_dta html_text_seminar_paper_dta
	capture copy `"`url'"' `"`html_text'.txt"', replace  
	local times = 0
	while _rc ~= 0 {
		local times = `times' + 1
		sleep 1000
		capture copy `"`stata_paper_youdao'"' `"`html_text'.txt"', replace
		if `times' > 3 {
			disp as error "Internet speeds is too low to get the data"
			exit 601
		}
	}
	infix strL v 1-100000 using `"`html_text'.txt"', clear
	capture erase `"`html_text'.txt"'
	
	//文本分割
	split v,p("++")       
	if _rc ~= 0 {
		di as err "Failed to get the data"
		exit 601
	}	
	local start: disp %dCYND date("`c(current_date)'","DMY")
	local year  = substr("`start'",1,4)
	local month = substr("`start'",5,2)
	local day   = substr("`start'",7,2)
	local cur_time "`year'""年""`month'""月""`day'""日"   
    capture confirm v6 
	if _rc!=0{
		gen v6 ="`year'"+"/"+"`mouth'"+"/"+"`day'"
	}
	//链接 标题	内容分类 作者 形式分类 日期                 
	rename (v1-v6) (link title style type seminar_paper date)
	
	//后续检索关键词不区分大小写		
	gen title1 = lower(title) 
	gen style1 = lower(style) 
	gen text   =title1+" "+style1
	gen ad     = strmatch(type,"*置顶*")
	drop if strmatch(seminar_paper,"*advert*")==1
	drop if strmatch(type,"*ad*")==1

**# drop-option
	foreach class_drop of local drop{
		drop if strmatch(text,"*`class_drop'*") 
	}

**# 筛选关键词      
	//输入1个关键词
	if "`1'"!="" & "`2'"=="" {   
		capture local 1 = strlower(`"`1'"') 
		if _rc!=0{
			local 1 = strlower("`1'")	
		}
		capture gen yjy1 = strmatch(text,`"*`1'*"') 
		if _rc!=0{
			gen yjy1 = strmatch(text,"*`1'*") 
		}
		keep if yjy1==1 | ad==1 		 			 				
	}	
	
	//输入两个及以上关键词 
	else{			
		if strmatch("`class'","*+*")==1 & strmatch("`class'","*-*")==1{
			dis as error `"  "+" 或者 "-" 号不能同时选择"' 
			exit 198
		}				
		if strmatch(`"`class'"',"*+*")==1{
			local class_new = subinstr(`"`class'"',"+"," ",.)		
			tokenize `class_new'
			local wordn = wordcount("`class_new'")
			forvalues i = 1/`wordn'{
				local `i' = strlower(`"``i''"')   
				gen yjy`i'   = strmatch(text,`"*``i''*"') 
			}  			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error  `"  songbl ssci :  invalid songbl ssci type"'	
				exit 198	
			}			
			keep if yjy>=1|ad==1
		}			
		else if strmatch(`"`class'"',"*-*")==1{
			local class_new = subinstr(`"`class'"',"-"," ",.)		
			tokenize `class_new'
			local wordn = wordcount("`class_new'")
			forvalues i = 1/`wordn'{
				local `i' = strlower(`"``i''"')  
				gen yjy`i' = strmatch(text,`"*``i''*"') 
			}  			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error  `"  songbl ssci :  invalid songbl ssci type"'	
				exit 198	
			}
			keep if (yjy1==1 & yjy==1)  | ad==1
		}
		else{
			local class_new = subinstr(`"`class'"',"-"," ",.)		
			tokenize `class_new'
			local wordn = wordcount(`"`class_new'"')
			forvalues i = 1/`wordn'{	
				local `i' = strlower(`"``i''"')  
				gen yjy`i' = strmatch(text,`"*``i''*"') 
			}  
			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error `"  songbl ssci : invalid songbl ssci type"'	
				exit 198	
			}			
			keep if yjy==`wordn'| ad==1
		}
		
	}  
	
	local n =_N                  
	local ad =ad[1]
	count if ad==1
	local coun_ad=`n'-`r(N)'	
	n if `coun_ad'<=0{		
		dis as error  `"  {bf:抱歉，没有找到与 [ {it:`class'} ] 相关的内容。}"' _n
		dis as red    `"  试试：{stata "songbl":[分类查看推文]}"'  `"  或者  {stata "h songbl_cn":[查看帮助文档]}"' _n
		dis as text   `"  或者试试网页搜索："'
		dis as text _col(5)`"  {stata " songbl `*',s(计量圈) "}  或  {stata " songbl `*',s(百度) "}"'                   
		dis as text _col(5)`"  {stata " songbl `*',s(公众号) "}  或  {stata " songbl `*',s(知乎) "}"'  
		dis as text _col(5)`"  {stata " songbl `*',s(经管家) "}  或  {stata " songbl `*',s(全部) "}"' _n    
		dis as red    `"  或者试试检索代码：{stata "songbl cie `*'"}"' _n 
		dis as text   `"  如果您发现{bf:songbl}命令的使用bug，或者对{bf:songbl}命令的改善有什么建议"'
		dis as text   `"  您可以通过以下链接填写资料告知我们"' 
		dis as error  `"  {bf:点击链接:}"'
		dis as text _col(8)  `"  ({browse "https://www.wjx.top/vm/ekn2Nl0.aspx":https://www.wjx.top/vm/ekn2Nl0.aspx})"'  
		dis ""
		exit
	}       
			
**# 关键词打印  

	save "`html_text_dta'",replace	  
	levelsof seminar_paper,local(seminar_paper) 
	foreach seminar_paper in `seminar_paper'{ 
		use "`html_text_dta'",clear
		keep if seminar_paper==`"`seminar_paper'"'
		save "`html_text_seminar_paper_dta'",replace
		levelsof style,local(number) 
		foreach num in `number' { 
			use "`html_text_seminar_paper_dta'",clear
			keep if style=="`num'"
			local n=_N
			if `n'>0{
				sort title   
				if missing("`nocat'"){										
					n dis as w `" `seminar_paper' >>"' `"{stata "songbl ssci `num'": `num'}"'
				}
				forvalues i = 1/`n'{         
					local link=link[`i']
					local title=title[`i']
					capture dis strmatch(`"`link'"',"* *")==1
					if _rc==0{
						if strmatch(`"`link'"',"* *")==1{										
							n dis _col(4) `"{stata `"`link'"': `title'}"'
						}			 				 
						else{
							n dis _col(4) `"{browse `"`link'"': `title'}"'
						}																
					}
					else{
						if strmatch("`link'","* *")==1{	
							n dis _col(4) `"{stata `"`link'"': `title'}"'
						}			 				 
						else{
							n dis _col(4) `"{browse `"`link'"': `title'}"'
						}															 										
					}
					n `gap'
				}
		   }
			if missing("`nocat'"){
				n dis ""
			}
		}						
		use "`html_text_dta'", clear
	}	

	restore           
	
}
end
	

*Inspirit of -lianxh-(Yujun, Lian*;Junjie, Kang;Qingqing, Liu) 

* Authors:
* Program written by Bolin, Song (松柏林) Shenzhen University , China.
* Wechat:songbl_stata
* Please do not use this code for commerical purpose


*Songbl makes it easy for users to search and open thousands of Stata blog posts and useful Stata information in Stata window. You can also browse the papers and replication data & programs etc of China's industrial economy by category.


capture program drop songbl_ssc
program define songbl_ssc

version 14

syntax [anything(name = class)] [,Cls Gap Line Num(numlist integer max=1 min=1 >0) Drop(string) ] 

qui{
	capture local class=stritrim(`"`class'"') 
	if _rc!=0{
		local class=stritrim("`class'") 	
	}
	tokenize `class'
**# cls-option
	if "`cls'" != ""{
		cls
		n dis ""
	}																				
**# gap-option			
	if "`gap'" != "" {		 
		local gap dis ""
	} 
	if "`class'" ==""{
		n songbl_sbl ssc
		exit
	}	
	preserve		
	
	// 避免变量与用户变量冲突	
	clear    	
	
	//推文链接与标题	
	local path https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com
	local url "`path'/songbl/ssc.txt"
	tempfile  html_text  html_text_dta  html_text_seminar_paper_dta Share_txt  songbl_post 
	capture copy `"`url'"' `"`html_text'.txt"', replace  
	local times = 0
	while _rc ~= 0 {
		local times = `times' + 1
		sleep 1000
		capture copy `"`stata_paper_youdao'"' `"`html_text'.txt"', replace
		if `times' > 3 {
			disp as error "Internet speeds is too low to get the data"
			exit 601
		}
	}
	infix strL v 1-100000 using `"`html_text'.txt"', clear
	capture erase `"`html_text'.txt"'		
//文本分割
	split v,p("++")       
	if _rc ~= 0 {
		di as err "Failed to get the data"
		exit 601
	}	

	//链接 标题	内容分类 作者 形式分类 日期                 
	rename (v1-v6) (link title style type seminar_paper date)
	
	//后续检索关键词不区分大小写		
	gen title1 = lower(title) 
	gen style1 = lower(style) 
	gen text   =title1+" "+style1
	gen ad     = strmatch(type,"*置顶*")
	drop if seminar_paper==""
	
**# drop-option
	foreach class_drop of local drop{
		drop if strmatch(text,"*`class_drop'*") 
	}
	

**# 筛选关键词      
	//输入1个关键词
	if "`1'"!="" & "`2'"=="" {   
		if "`class'"=="new"{	
			if  "`num'"==""{
				local num=10
			}			    
			sort date type style title	
			drop if title=="new_songbl"
			drop in 1
			drop if seminar_paper=="论文"
			drop if type=="songbl"
			capture keep in -`num'/ -1 	    
		}
		else{
		    capture local 1 = strlower(`"`1'"') 
			if _rc!=0{
				local 1 = strlower("`1'")	
			}
			capture gen yjy1 = strmatch(text,`"*`1'*"') 
			if _rc!=0{
				gen yjy1 = strmatch(text,"*`1'*") 
			}
			keep if yjy1==1 | ad==1 
		}			 			 				
	}	
	
	//输入两个及以上关键词 
	else{			
		if strmatch("`class'","*+*")==1 & strmatch("`class'","*-*")==1{
			dis as error `"  "+" 或者 "-" 号不能同时选择"' 
			exit 198
		}				
		if strmatch(`"`class'"',"*+*")==1{
			local class_new = subinstr(`"`class'"',"+"," ",.)		
			tokenize `class_new'
			local wordn = wordcount("`class_new'")
			forvalues i = 1/`wordn'{
				local `i' = strlower(`"``i''"')   
				gen yjy`i'   = strmatch(text,`"*``i''*"') 
			}  			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error  `"  songbl :  invalid songbl type"'	
				exit 198	
			}			
			keep if yjy>=1|ad==1
		}			
		else if strmatch(`"`class'"',"*-*")==1{
			local class_new = subinstr(`"`class'"',"-"," ",.)		
			tokenize `class_new'
			local wordn = wordcount("`class_new'")
			forvalues i = 1/`wordn'{
				local `i' = strlower(`"``i''"')  
				gen yjy`i' = strmatch(text,`"*``i''*"') 
			}  			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error  `"  songbl :  invalid songbl type"'	
				exit 198	
			}
			keep if (yjy1==1 & yjy==1)  | ad==1
		}
		else{
			local class_new = subinstr(`"`class'"',"-"," ",.)		
			tokenize `class_new'
			local wordn = wordcount(`"`class_new'"')
			forvalues i = 1/`wordn'{	
				local `i' = strlower(`"``i''"')  
				gen yjy`i' = strmatch(text,`"*``i''*"') 
			}  
			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error `"  songbl :  invalid songbl type"'	
				exit 198	
			}			
			keep if yjy==`wordn'| ad==1
		}
		
	}  
	
	local n =_N                  
	local ad =ad[1]
	count if ad==1
	local coun_ad=`n'-`r(N)'	
	n if `coun_ad'<=0{		
		dis as error  `"  {bf:抱歉，没有找到与 [ {it:`class'} ] 相关的外部命令。}"' _n
		dis as red    `"  试试：{stata "songbl":[分类查看推文]}"'  `"  或者  {stata "h songbl_cn":[查看帮助文档]}"' _n
		dis as text   `"  或者试试网页搜索："'
		dis as text _col(5)`"  {stata " songbl `*',s(计量圈) "}  或  {stata " songbl `*',s(百度) "}"'                   
		dis as text _col(5)`"  {stata " songbl `*',s(公众号) "}  或  {stata " songbl `*',s(知乎) "}"'  
		dis as text _col(5)`"  {stata " songbl `*',s(经管家) "}  或  {stata " songbl `*',s(全部) "}"' _n    
		dis as red    `"  或者试试检索代码：{stata "songbl `*',cie"}"' _n 
		dis as text   `"  如果您发现{bf:songbl}命令的使用bug，或者对{bf:songbl}命令的改善有什么建议"'
		dis as text   `"  您可以通过以下链接填写资料告知我们"' 
		dis as error  `"  {bf:点击链接:}"'
		dis as text _col(8)  `"  ({browse "https://www.wjx.top/vm/ekn2Nl0.aspx":https://www.wjx.top/vm/ekn2Nl0.aspx})"'  
		dis ""
		exit
	}        
                
	sort date type style title	
	local n  =_N
	local all_n=_N
	n dis as  text   "{center:Hello, Songbl Stata}"  _n
	n dis as txt "{hline}"
	n dis in text _col(4)  "{bf:Help}" _col(12)  "{bf:Command}" _col(29) `"{bf:Date}"'  _col(45) `"{bf:Description}"'
	n dis as txt "{hline}"		
	n `gap'
	n forvalues i = 1/`n' {         
		local link=link[`i']
		local title=title[`i']
		local type=type[`i']
		local style=style[`i']
		local seminar_paper =seminar_paper[`i']  
		local date =date[`i']
		local col =45			
		if udstrlen(`"`title'"')<=100{	
			local title1=udsubstr(`"`title'"',1,00)			
			dis  _col(5) `"{stata `"`link'"':-}"'  _col(9) `"{stata `"ssc describe `style'"': `style'}"'   ///
				 _col(29)  `"`date'"'  _col(45)  `"`title'"'                         
			`gap'                           
		}                    	
		if udstrlen(`"`title'"')>100 & udstrlen(`"`title'"')<=200{		
			local title1=udsubstr(`"`title'"',1,100) 
			local title2=usubinstr(`"`title'"',`"`title1'"',"",.)
			local title2=udsubstr(`"`title2'"',1,100) 
			dis  _col(5) `"{stata `"`link'"':-}"'  _col(9) `"{stata `"ssc describe `style'"': `style'}"'   ///
				 _col(29)  `"`date'"'  _col(45)  `"`title1'"'
			dis  _col(`col') `"`title2'"'                              
			`gap'                           
		}		
		if udstrlen(`"`title'"')>200 & udstrlen(`"`title'"')<=300{			
			local title1=udsubstr(`"`title'"',1,100) 
			local title2=usubinstr(`"`title'"',`"`title1'"',"",.)
			local title2=udsubstr(`"`title2'"',1,100) 
			local title3=usubinstr(`"`title'"',`"`title1'`title2'"',"",.)
			local title3=udsubstr(`"`title3'"',1,100) 
			dis  _col(5) `"{stata `"`link'"':-}"'  _col(9) `"{stata `"ssc describe `style'"': `style'}"'   ///
				 _col(29)  `"`date'"'  _col(45)  `"`title1'"'
			dis  _col(`col') `"`title2'"' 
			dis  _col(`col') `"`title3'"'   
			`gap'                           
		}                        
		
		if udstrlen(`"`title'"')>300 & udstrlen(`"`title'"')<=400{		
			local title1=udsubstr(`"`title'"',1,100) 
			local title2=usubinstr(`"`title'"',`"`title1'"',"",.)
			local title2=udsubstr(`"`title2'"',1,100) 
			local title3=usubinstr(`"`title'"',`"`title1'`title2'"',"",.)
			local title3=udsubstr(`"`title3'"',1,100) 
			local title4=usubinstr(`"`title'"',`"`title1'`title2'`title3'"',"",.)
			local title4=udsubstr(`"`title4'"',1,100) 	  
			dis  _col(5) `"{stata `"`link'"':-}"'  _col(9) `"{stata `"ssc describe `style'"': `style'}"'   ///
				 _col(29)  `"`date'"'  _col(45)  `"`title1'"'
			dis  _col(`col') `"`title2'"'  
			dis  _col(`col') `"`title3'"'  
			dis  _col(`col') `"`title4'"'   
			`gap'                           		 
		}
		
		if udstrlen(`"`title'"')>400 & udstrlen(`"`title'"')<=500{			
			local title1=udsubstr(`"`title'"',1,100) 
			local title2=usubinstr(`"`title'"',`"`title1'"',"",.)
			local title2=udsubstr(`"`title2'"',1,100) 
			local title3=usubinstr(`"`title'"',`"`title1'`title2'"',"",.)
			local title3=udsubstr(`"`title3'"',1,100) 
			local title4=usubinstr(`"`title'"',`"`title1'`title2'`title3'"',"",.)
			local title4=udsubstr(`"`title4'"',1,100) 
			local title5=usubinstr(`"`title'"',`"`title1'`title2'`title3'`title4'"',"",.)
			local title5=udsubstr(`"`title5'"',1,100) 	  
			dis  _col(5) `"{stata `"`link'"':-}"'  _col(9) `"{stata `"ssc describe `style'"': `style'}"'   ///
				 _col(29)  `"`date'"'  _col(45)  `"`title1'"'
			dis  _col(`col') `"`title2'"'  
			dis  _col(`col') `"`title3'"'  
			dis  _col(`col') `"`title4'"'  
			dis  _col(`col') `"`title5'"'  
			`gap'                           	 
		}                        
		
		if udstrlen(`"`title'"')>500 & udstrlen(`"`title'"')<=600{			
			local title1=udsubstr(`"`title'"',1,100) 
			local title2=usubinstr(`"`title'"',`"`title1'"',"",.)
			local title2=udsubstr(`"`title2'"',1,100) 
			local title3=usubinstr(`"`title'"',`"`title1'`title2'"',"",.)
			local title3=udsubstr(`"`title3'"',1,100) 
			local title4=usubinstr(`"`title'"',`"`title1'`title2'`title3'"',"",.)
			local title4=udsubstr(`"`title4'"',1,100) 
			local title5=usubinstr(`"`title'"',`"`title1'`title2'`title3'`title4'"',"",.)
			local title5=udsubstr(`"`title5'"',1,100) 
			local title6=usubinstr(`"`title'"',`"`title1'`title2'`title3'`title4'`title5'"',"",.)
			local title6=udsubstr(`"`title6'"',1,100) 
			dis  _col(5) `"{stata `"`link'"':-}"'  _col(9) `"{stata `"ssc describe `style'"': `style'}"'   ///
				 _col(29)  `"`date'"'  _col(45)  `"`title1'"'
			dis  _col(`col') `"`title2'"'  
			dis  _col(`col') `"`title3'"'  
			dis  _col(`col') `"`title4'"'  
			dis  _col(`col') `"`title5'"'  
			dis  _col(`col') `"`title6'"'                            
			`gap'                           	
		} 
		
		if udstrlen(`"`title'"')>600 & udstrlen(`"`title'"')<=700{			
			local title1=udsubstr(`"`title'"',1,100) 
			local title2=usubinstr(`"`title'"',`"`title1'"',"",.)
			local title2=udsubstr(`"`title2'"',1,100) 
			local title3=usubinstr(`"`title'"',`"`title1'`title2'"',"",.)
			local title3=udsubstr(`"`title3'"',1,100) 
			local title4=usubinstr(`"`title'"',`"`title1'`title2'`title3'"',"",.)
			local title4=udsubstr(`"`title4'"',1,100) 
			local title5=usubinstr(`"`title'"',`"`title1'`title2'`title3'`title4'"',"",.)
			local title5=udsubstr(`"`title5'"',1,100) 
			local title6=usubinstr(`"`title'"',`"`title1'`title2'`title3'`title4'`title5'"',"",.)
			local title6=udsubstr(`"`title6'"',1,100) 
			local title7=usubinstr(`"`title'"',`"`title1'`title2'`title3'`title4'`title5'`title6'"',"",.)
			local title7=udsubstr(`"`title7'"',1,100)   		   
		   dis  _col(5) `"{stata `"`link'"':-}"'  _col(9) `"{stata `"ssc describe `style'"': `style'}"'   ///
				 _col(29)  `"`date'"'  _col(45)  `"`title1'"'
			dis  _col(`col') `"`title2'"'  
			dis  _col(`col') `"`title3'"'  
			dis  _col(`col') `"`title4'"'  
			dis  _col(`col') `"`title5'"'  
			dis  _col(`col') `"`title6'"'  
			dis  _col(`col') `"`title7'"'                         
			`gap'                           	
		}  
		
		if udstrlen(`"`title'"')>700 & udstrlen(`"`title'"')<=10000{		
			local title1=udsubstr("`title'",1,100) 
			local title2=usubinstr("`title'","`title1'","",.)
			local title2=udsubstr("`title2'",1,100) 
			local title3=usubinstr("`title'","`title1'`title2'","",.)
			local title3=udsubstr("`title3'",1,100) 
			local title4=usubinstr("`title'","`title1'`title2'`title3'","",.)
			local title4=udsubstr("`title4'",1,100) 
			local title5=usubinstr("`title'","`title1'`title2'`title3'`title4'","",.)
			local title5=udsubstr("`title5'",1,100) 
			local title6=usubinstr("`title'","`title1'`title2'`title3'`title4'`title5'","",.)
			local title6=udsubstr("`title6'",1,100) 
			local title7=usubinstr("`title'","`title1'`title2'`title3'`title4'`title5'`title6'","",.)
			local title7=udsubstr("`title7'",1,100)  
			local title8=usubinstr("`title'","`title1'`title2'`title3'`title4'`title5'`title6'`title7'","",.)
			local title8=udsubstr("`title8'",1,100) 
			dis  _col(5) `"{stata `"`link'"':-}"'  _col(9) `"{stata `"ssc describe `style'"': `style'}"'   ///
				 _col(29)  `"`date'"'  _col(45)  `"`title1'"'
			dis  _col(`col') `"`title2'"'  
			dis  _col(`col') `"`title3'"'  
			dis  _col(`col') `"`title4'"'  
			dis  _col(`col') `"`title5'"'  
			dis  _col(`col') `"`title6'"'  
			dis  _col(`col') `"`title7'"'                        
			dis  _col(`col') `"`title8'"'     			
			if udstrlen("`title'")>800{
				dis   _col(`col') `"{bf:注}：超过八行的内容不再打印，完整内容请：help `style'"' 
			}				
			`gap'                                                                            
		}                                  		
		n if "`line'"!=""{
			 dis as txt "{hline}"	
			`gap'
		}  
	}	
	if "`line'"==""{
		 n dis as txt "{hline}"
	}  
	n dis as  text _col(3) `"注：由谷歌翻译自动转为中文"' _n	
 
}
 restore
end




capture program drop songbl_paper
program define songbl_paper

version 14

syntax [anything(name = class)]  ///
	   [,                       ///
		Mlink                   ///   //  - [论文标题](URL)
		MText                   ///   //    [论文标题](URL)
		MUrl		            ///   // n. [论文标题](URL)
		Wlink                   ///   //    论文标题： URL
		WText                   ///   //    论文标题： URL	
		WUrl		            ///   // n. 论文标题： URL		
		NOCat                   ///   //    不呈现论文分类信息 	
		Cls                     ///   //    清屏后显示结果
		Gap                     ///   //    在输出的结果论文之间进行空格一行	   
		SAVE(string)           	///   //    利用文档打开分享的内容。
		REPLACE                 ///   //    生成分享内容的 STATA 数据集。  
		CLIP                    ///   //	点击剪切分享，与 Wlink 搭配使用
		DROP(string)            ///   //     删除关键词   
		Journal(string)         ///
		fy 						///
	   ] 
	   
*		
*==============================================================================* 		
*==============================================================================* 
qui{
	cap local class=stritrim(`"`class'"') 
	if _rc!=0{
		local class=stritrim("`class'") 	
	}
	tokenize `class'
**# cls-option
	if "`cls'" != ""{
		cls
		n dis ""
	}		
	
	local path https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com
	local URL "`path'/navigation"
	if "`class'"==""{ 
		if missing("`journal'"){
			n songbl_links1  ,url(`URL'/paper.txt)
			exit			
		}
		else{
			local class *
		}
	}
	if missing("`journal'"){
		n dis as error `"需要使用选择项 journal() 指定检索的期刊"'
		n dis as txt "例如检索ARE文章 ：" "{stata songbl paper `class',j(aer):songbl paper `class',j(aer)}"
		n dis as txt _col(19) "{stata songbl paper `class',j(世界经济):songbl paper `class',j(世界经济)}"
		n dis "查看帮助文档    ：" `"{stata "help songbl paper":songbl paper help }"' 
		n dis "分类查看所有期刊：" `"{stata "songbl paper":songbl paper}"' 
		exit
	}
	else{
		local journal = strlower("`journal'")  
	}
	
**# gap-option			
	if "`gap'" != "" {		 
		local gap dis ""
		local gap1 post songbl_post  ("" ) 
	} 
	
**# replace-option							            	            			
	if ("`replace'"=="") {
		preserve		
	}	
	
	else{
	    des 
		if `r(N)'!=0{
			dis as error `"no; dataset in memory has changed since last saved"'	
			exit 4
		}
	}
	
	// 避免变量与用户变量冲突	
	clear    	
	
	//论文链接与标题	
	local path https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com
	if "`fy'"!=""{
		local journal "`journal'_fy"
	}
	percentencode `"`journal'"'
	local url "`path'/songbl/paper/`r(percentencode)'.txt"	
	tempfile  html_text  html_text_dta  html_text_seminar_paper_dta Share_txt  songbl_post 
	capture copy `"`url'"' `"`html_text'.txt"', replace  
	local times = 0
	while _rc ~= 0 {
		local times = `times' + 1
		sleep 1000
		capture copy `"`stata_paper_youdao'"' `"`html_text'.txt"', replace
		if `times' > 3 {
			gettoken name 0 : journal, parse("_")
			disp as error "请检查期刊{bf:《`name'》}是否存在" 
			disp as error "分类查看所有期刊：" `"{stata "songbl paper":songbl paper}"' 
			disp as error "Internet speeds is too low to get the data"
			exit 601
		}
	}
	infix strL v 1-100000 using `"`html_text'.txt"', clear
	capture erase `"`html_text'.txt"'
	//文本分割
	split v,p("++")       
	if _rc ~= 0 {
		di as err "Failed to get the data"
		exit 601
	}	

	//链接 标题	期刊与期号 学术论文 形式分类                  
	rename (v1-v5) (link title style type seminar_paper)
	
	//后续检索关键词不区分大小写	
	replace style = plural(2, style,"-学术论文") 
	gen title1 = lower(title) 
	gen style1 = lower(style) 
	gen text   =title1+" "+style1
	gen ad     = strmatch(type,"*songbl*")
	drop if seminar_paper==""

**# drop-option
	foreach class_drop of local drop{
		drop if strmatch(text,"*`class_drop'*") 
	}

**# 筛选关键词      
	//输入1个关键词
	if "`1'"!="" & "`2'"=="" {    	              				                      
			capture local 1 = strlower(`"`1'"') 
			if _rc!=0{
				local 1 = strlower("`1'")	
			}
			capture gen yjy1 = strmatch(text,`"*`1'*"') 
			if _rc!=0{
				gen yjy1 = strmatch(text,"*`1'*") 
			}
			keep if yjy1==1 | ad==1 			 			 				
	}	
	
	//输入两个及以上关键词 
	else{			
		if strmatch("`class'","*+*")==1 & strmatch("`class'","*-*")==1{
			dis as error `"  "+" 或者 "-" 号不能同时选择"' 
			exit 198
		}				
		if strmatch(`"`class'"',"*+*")==1{
			local class_new = subinstr(`"`class'"',"+"," ",.)		
			tokenize `class_new'
			local wordn = wordcount("`class_new'")
			forvalues i = 1/`wordn'{
				local `i' = strlower(`"``i''"')   
				gen yjy`i'   = strmatch(text,`"*``i''*"') 
			}  			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error  `"  songbl paper :  invalid songbl paper type"'	
				exit 198	
			}			
			keep if yjy>=1|ad==1
		}			
		else if strmatch(`"`class'"',"*-*")==1{
			local class_new = subinstr(`"`class'"',"-"," ",.)		
			tokenize `class_new'
			local wordn = wordcount("`class_new'")
			forvalues i = 1/`wordn'{
				local `i' = strlower(`"``i''"')  
				gen yjy`i' = strmatch(text,`"*``i''*"') 
			}  			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error  `"  songbl paper :  invalid songbl paper type"'	
				exit 198	
			}
			keep if (yjy1==1 & yjy==1)  | ad==1
		}
		else{
			local class_new = subinstr(`"`class'"',"-"," ",.)		
			tokenize `class_new'
			local wordn = wordcount(`"`class_new'"')
			forvalues i = 1/`wordn'{	
				local `i' = strlower(`"``i''"')  
				gen yjy`i' = strmatch(text,`"*``i''*"') 
			}  
			
			capture egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error `"  songbl paper:  invalid songbl paper type"'	
				exit 198	
			}			
			keep if yjy==`wordn'| ad==1
		}
		
	}  
	
	local n =_N                  
	local ad =ad[1]
	count if ad==1
	local coun_ad=`n'-`r(N)'	
	n if `coun_ad'<=0{		
	dis as error  `"  {bf:抱歉，在《`journal'》没有找到与 [ {it:`class'} ] 相关的论文。}"' _n
		dis as red    `"  试试：{stata "songbl paper":[分类查看论文]}"'  `"  或者  {stata "h songbl_cn":[查看帮助文档]}"' _n
		dis as text   `"  或者试试网页搜索："'
		dis as text _col(5)`"  {stata " songbl `*',s(计量圈) "}  或  {stata " songbl `*',s(百度) "}"'                   
		dis as text _col(5)`"  {stata " songbl `*',s(公众号) "}  或  {stata " songbl `*',s(知乎) "}"'  
		dis as text _col(5)`"  {stata " songbl `*',s(经管家) "}  或  {stata " songbl `*',s(全部) "}"' _n    
		dis as red    `"  或者试试检索代码：{stata "songbl `*',cie"}"' _n 
		dis as text   `"  如果您发现{bf:songbl}命令的使用bug，或者对{bf:songbl}命令的改善有什么建议"'
		dis as text   `"  您可以通过以下链接填写资料告知我们"' 
		dis as error  `"  {bf:点击链接:}"'
		dis as text _col(8)  `"  ({browse "https://www.wjx.top/vm/ekn2Nl0.aspx":https://www.wjx.top/vm/ekn2Nl0.aspx})"'  
		dis ""
		exit
	}       
	

**# 关键词打印        	
	if  "`wlink'" =="" & "`wtext'"=="" & "`mlink'"=="" & "`mtext'"=="" & "`murl'"=="" & "`wurl'"=="" {
		//保存关键词 "class" 搜索到的数据   
		save "`html_text_dta'",replace	  
		levelsof seminar_paper,local(seminar_paper) 
		foreach seminar_paper in `seminar_paper'{ 
			use "`html_text_dta'",clear
			keep if seminar_paper==`"`seminar_paper'"'
			save "`html_text_seminar_paper_dta'",replace
			levelsof style,local(number) 
			foreach num in `number' { 
				use "`html_text_seminar_paper_dta'",clear
				keep if style=="`num'"
				local n=_N
				if `n'>0{
					sort  title   
					if missing("`nocat'"){	
						if missing("`journal'"){
							n dis as w `" `seminar_paper' >>"' `"{stata "songbl paper `num' ": `num'}"'		
						}
						else{
							n dis as w `" `seminar_paper' >>"' `"{stata "songbl paper `num',j(`journal') ": `num'}"'	
						}					
					}
					forvalues i = 1/`n'{         
						local link=link[`i']
						local title=title[`i']
						capture dis strmatch(`"`link'"',"* *")==1
						if _rc==0{
							if strmatch(`"`link'"',"* *")==1{										
								n dis _col(4) `"{stata `"`link'"': `title'}"'
							}			 				 
							else{
								n dis _col(4) `"{browse `"`link'"': `title'}"'
							}																
						}
						else{
							if strmatch("`link'","* *")==1{	
								n dis _col(4) `"{stata `"`link'"': `title'}"'
							}			 				 
							else{
								n dis _col(4) `"{browse `"`link'"': `title'}"'
							}															 										
						}
						n `gap'
					}
			   }
				if missing("`nocat'"){
					n dis ""
				}
			}			
		}				
		if "`save'"!="" {
			dis as error `" 命令格式有误，see { stata  " help songbl_cn" }"'
			dis as error `" Note:save 选择项必须与 wlink 、wtext 、mlink 、mtext、murl、wurl 等分享功能一起使用  "' 
			exit 198	
		}		
		use "`html_text_dta'", clear
	}	

	else{	
		if  "`mlink'" !="" | "`mtext'" !="" | "`murl'" !=""{
			drop  if strmatch(link,`"* *"')==1 
		}
		save "`html_text_dta'", replace	  // 保存关键词 "class" 搜索到的数据    
		capture postclose songbl_post
		postfile songbl_post str1000 Share using "`songbl_post'", replace	
		
**# wlink-option						 			  
		if "`wlink'" !=""{	              
			n dis ""	
			n dis as txt _n "{hline 24} wlink文本格式 {hline 24}"	
			n dis as txt	
			n dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
			n dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl paper `class'"
			post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
			post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl paper `class'") 	
			n dis as txt	
			post songbl_post  (" ") 
			levelsof seminar_paper,local(seminar_paper) 	
			local m=_N			
			foreach seminar_paper in `seminar_paper' { 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'", replace					                    
				levelsof style,local(number) 
				foreach num in `number'{ 
					use "`html_text_seminar_paper_dta'", clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort title
						if missing("`nocat'"){							
							if missing("`journal'"){
								n dis as w `" `seminar_paper' >>"' `"{stata "songbl paper `num' ": `num'}"'		
							}
							else{
								n dis as w `" `seminar_paper' >>"' `"{stata "songbl paper `num',j(`journal') ": `num'}"'	
							}					
							n `gap' 
							`gap1'
							post songbl_post  ("    `seminar_paper' >> `num'" ) 
														
						}														
						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']	
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								post songbl_post (`"`title': `link'"') 
							}
							if  "`clip'"==""{
								n dis as y `"`title': `link'"'
							}
							else{
								local  clip1 `"`title': `link'"'
								local  clip2 `"`title': `link'"'
								n dis `"{stata `"!echo `clip1'       Copy by #公众号:songbl | clip"': `clip2'}"'
							}
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						n dis ""
						post songbl_post  (" " ) 
					}        
				}
			}	
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"			
			n dis as red "{bf:小提示：}" `"使用 {stata `"songbl paper `class', w clip j(`journal')"':songbl paper `class', w clip j(`journal')} 后，"' "点击超链接，按Ctrl+V可进行粘贴"                      
			n dis as red  "        建议分多次复制到微信对话框，每次 10 行，否则超链接无法生效"
			n dis as red   "        长链接断行导致打印失败。请使用" `" {stata `"songbl paper `class',w replace j(`journal')"':songbl  paper `class', w replace j(`journal')}"' "或者" `" {stata `"songbl paper `class',w save(txt) j(`journal')"':songbl paper `class',w save(txt) j(`journal')}"'       
		}

**# wtext-option		
		if "`wtext'" !=""{		
			n dis ""	
			n dis as txt _n "{hline 24} wtxt文本格式 {hline 24}"	
			n dis as txt				
			n dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
			n dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl paper `class'"
			post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
			post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl paper `class'")  	
			n dis as txt	
			post songbl_post  (" ") 		
			use "`html_text_dta'", clear
			levelsof seminar_paper , local(seminar_paper) 	
			local m=_N			
			foreach  seminar_paper  in  `seminar_paper' { 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'", replace					                    
				levelsof style,local(number) 
				foreach num in `number'{ 
					use "`html_text_seminar_paper_dta'", clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort title
						if missing("`nocat'"){
							if missing("`journal'"){
								n dis as w `" `seminar_paper' >>"' `"{stata "songbl paper `num' ": `num'}"'		
							}
							else{
								n dis as w `" `seminar_paper' >>"' `"{stata "songbl paper `num',j(`journal') ": `num'}"'	
							}					
							post songbl_post ("    `seminar_paper' >> `num'" ) 								
							n `gap'
							`gap1'
						}	     					
						forvalues i = 1/`n'{         
							local link=link[`i']
							local title=title[`i']
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								n dis  as text `"`title'"'
								n dis  as text `"`link'"'								
								post songbl_post  (`"`title'"') 
								post songbl_post  (`"`link'"') 	
							}
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						post songbl_post  (" " ) 					
						n dis ""
					}         
				}
			}	
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"
			n dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl paper `class',wt replace j(`journal')"':songbl paper `class',wt replace j(`journal')}"' "或者" `" {stata `"songbl paper `class' ,wt save(txt) j(`journal')"':songbl paper `class',wt save(txt) j(`journal')}"' 					
		}		

**# wurl-option		
		if "`wurl'"  !=""{
			n dis ""	
			n dis as txt _n "{hline 24} wurl文本格式 {hline 24}"	
			n dis as txt				
			n dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
			n dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl paper `class'"
			post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
			post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl paper `class'") 	
			n dis as txt	
			post songbl_post  (" ") 		
			use "`html_text_dta'", clear
			levelsof seminar_paper , local(seminar_paper) 	
			local m=_N
			foreach  seminar_paper  in  `seminar_paper' { 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'", replace					                    
				levelsof style , local(number) 
				foreach  num  in  `number' { 
					use  "`html_text_seminar_paper_dta'", clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort title 
						if missing("`nocat'"){
							if missing("`journal'"){
								n dis as w `" `seminar_paper' >>"' `"{stata "songbl paper `num' ": `num'}"'		
							}
							else{
								n dis as w `" `seminar_paper' >>"' `"{stata "songbl paper `num',j(`journal') ": `num'}"'	
							}	
							post songbl_post  ("    `seminar_paper' >> `num'" ) 							
							n `gap' 
							`gap1'
						}	
						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']		
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								if `n'==1{
									n dis as text `"`title': `link'"'
									post songbl_post  (`"`title': `link'"') 								
								}
								else {
									n dis as text `"`i'. `title': `link'"'
									post songbl_post  (`"`i'. `title': `link'"') 
								}	
							}
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						post songbl_post  (" " ) 					
						n dis ""
					}         
				}
			}	
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
			n dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl paper `class',wu replace j(`journal')"':songbl paper `class',wu replace j(`journal')}"' "或者" `" {stata `"songbl paper `class',wu save(txt) j(`journal')"':songbl paper `class',wu save(txt) j(`journal')}"					
		}		

**# mlink-option					
		if "`mlink'" !=""{
			n dis ""	
			n dis as txt _n "{hline 24} mlik文本格式 {hline 24}"	
			n dis as txt				
			n dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
			n dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl paper `class'**"
			post songbl_post  ("# <center>`class'</center>") 
			post songbl_post  ("**以下论文列表由 **songbl** 命令生成**")                     
			post songbl_post  ("```")    					
			post songbl_post  ("Note：产生如下论文列表的 Stata 命令为：")  
			post songbl_post  (". songbl paper `class',j(`journal')")  
			post songbl_post  ("安装最新版 songbl命令：")    					
			post songbl_post  (". ssc install songbl, replace")  										
			post songbl_post  ("```")  
			post songbl_post  ("---") 
			n dis as txt "---"				
			use "`html_text_dta'",clear
			levelsof seminar_paper , local(seminar_paper) 		
			local m=_N
			foreach  seminar_paper in `seminar_paper'{ 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'", replace					                    
				levelsof style , local(number) 
				foreach num in `number'{ 
					use "`html_text_seminar_paper_dta'", clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort title
						if missing("`nocat'"){
							if missing("`journal'"){
								n dis as w _col(4) "### `seminar_paper' >>"`"{stata "songbl paper `num'",j(`journal: `num'}"'" 	
							}
							else{
								n dis as w _col(4) "### `seminar_paper' >>"`"{stata "songbl paper `num',j(`journal')": `num'}"'" 
							}															
							post songbl_post  ("### `seminar_paper' >> `num'" ) 							
							n `gap' 
							`gap1'
						}	 
						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']		
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								n dis as text `"- [`title'](`link')"'
								post songbl_post  (`"- [`title'](`link')"') 
							}
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						post songbl_post  (" " ) 					
						n dis ""
					}         
				}
			}	
			post songbl_post  ("## **Stata** 交流群微信：songbl_stata")  					
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"		
			n dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用：" `" {stata `"songbl paper `class',m replace j(`journal')"':songbl paper `class',m replace   j(`journal')}"'
			n dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl paper `class',m save(txt) j(`journal')"':       songbl paper `class',m save(txt) j(`journal')}"' 
		}

**# mtext-option
		if "`mtext'" !=""{
			n dis ""	
			n dis as txt _n "{hline 24} mtext文本格式 {hline 24}"	
			n dis as txt				
			n dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
			n dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl paper `class'**"
			post songbl_post  ("# <center>`class'</center>") 
			post songbl_post  ("**以下论文列表由 **songbl** 命令生成**")                     
			post songbl_post  ("```")    					
			post songbl_post  ("Note：产生如下论文列表的 Stata 命令为：")  
			post songbl_post  (". songbl paper `class',j(`journal')")  
			post songbl_post  ("安装最新版 songbl命令：")    					 
			post songbl_post  (". ssc install songbl, replace")  					
				post songbl_post  ("```")  
			n dis as txt "---"	
			post songbl_post  ("---") 			
			use "`html_text_dta'", clear
			levelsof seminar_paper,local(seminar_paper) 
			local m=_N
			foreach  seminar_paper in `seminar_paper'{ 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'",replace					                    
				levelsof style,local(number) 
				foreach num in `number' { 
					use "`html_text_seminar_paper_dta'",clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort title
						if missing("`nocat'"){
							if missing("`journal'"){
								n dis as w _col(4) "### `seminar_paper' >>"`"{stata "songbl paper `num'",j(`journal: `num'}"'" 	
							}
							else{
								n dis as w _col(4) "### `seminar_paper' >>"`"{stata "songbl paper `num',j(`journal')": `num'}"'" 
							}	
							post songbl_post  ("### `seminar_paper' >> `num'" ) 							
							n `gap' 
							`gap1'
						}								   
						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']		
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								n dis as text `"[`title'](`link')"'
								post songbl_post  (`"[`title'](`link')"') 
							}														
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						post songbl_post  (" " ) 					
						n dis ""
					}          
				}
			}	
			post songbl_post  ("## **Stata** 交流群微信：songbl_stata")  				
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
			n dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用：" `" {stata `"songbl paper `class',mt replace j(`journal')"':songbl paper `class',mt replace   j(`journal')}"'
			n dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl paper `class',mt save(txt) j(`journal')"':       songbl paper `class',mt save(txt) j(`journal')}"' 
		}		

**# murl-option		
		if "`murl'"  !=""{
			n dis ""	
			n dis as txt _n "{hline 24} murl文本格式 {hline 24}"	
			n dis as txt				
			n dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
			n dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl paper `class'**"
			post songbl_post  ("# <center>`class'</center>") 
			post songbl_post  ("**以下论文列表由 **songbl** 命令生成**")                     
			post songbl_post  ("```")    					
			post songbl_post  ("Note：产生如下论文列表的 Stata 命令为：")  
			post songbl_post  (". songbl paper `class',j(`journal')")  
			post songbl_post  ("安装最新版 songbl命令：")    					 
			post songbl_post  (". ssc install songbl, replace")  					
				post songbl_post  ("```")  
			n dis as txt "---"	
			post songbl_post  ("---") 				
			use "`html_text_dta'", clear
			levelsof seminar_paper,local(seminar_paper) 
			local m=_N
			foreach  seminar_paper in `seminar_paper'{ 
				use "`html_text_dta'", clear
				keep if seminar_paper==`"`seminar_paper'"'
				save "`html_text_seminar_paper_dta'",replace					                    
				levelsof style,local(number) 
				foreach num in `number' { 
					use "`html_text_seminar_paper_dta'",clear						
					keep if style=="`num'"
					local n=_N
					if `n'>0{
						sort title
						if missing("`nocat'"){
							if missing("`journal'"){
								n dis as w _col(4) "### `seminar_paper' >>"`"{stata paper "songbl `num',j(`journal": `num'}"'" 	
							}
							else{
								n dis as w _col(4) "### `seminar_paper' >>"`"{stata "songbl paper `num',j(`journal')": `num'}"'" 
							}	
							post songbl_post  ("### `seminar_paper' >> `num'" ) 							
							n `gap' 
							`gap1'
						}   
						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']
							cap di wordcount(`"`title': `link'"')
							if _rc==0{
								if `n'==1{
									n dis ""
									n dis as text `"[`title'](`link')"'								
									post songbl_post  ("") 
									post songbl_post  (`"[`title'](`link')"') 	
									
								}
								else {
									n dis as text `"`i'. [`title'](`link')"'
									post songbl_post  (`"`i'. [`title'](`link')"') 	
								}
							}																
							n `gap'
							`gap1'
						}
					}
					if missing("`nocat'"){
						post songbl_post  (" " ) 					
						n dis ""
					}           
				}
			}		
			post songbl_post  ("## **Stata** 交流群微信：songbl_stata")  				
			n dis ""	
			n dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
			n dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用：" `" {stata `"songbl paper `class',mu replace j(`journal')"':songbl paper `class',mu replace   j(`journal')}"'
			n dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl paper `class',mu save(txt) j(`journal')"':       songbl paper `class',mu save(txt) j(`journal')}"' 
		}					
		
		postclose songbl_post
		use "`songbl_post'", clear
		cap format %-200s Share          
	}	
	
	if ("`replace'"!="") {
		cap keep  link title style type seminar_paper
		cap label variable link "链接"
		cap label variable title "标题"
		cap label variable style "分类"
		cap label variable type "来源"
		cap label variable seminar_paper "论文"     
		cap label variable data "更新时间"    
	}			

**# save-option							
	if ("`save'"!="") {	         
		export delimited Share using "`Share_txt'.`save'" , ///
		novar nolabel delimiter(tab) replace				
		view browse "`Share_txt'.`save'"		
	}		
	cap erase `"`html_text'.txt"'   	
	if ("`replace'"=="") {	
		restore           
	} 	
	if "`fy'"!=""{
		n dis as txt `" 提示："'  "论文标题由谷歌翻译完成，仅供参考"
	}	
}
end
	
cap program drop songbl_links1
program define songbl_links1
version 8
syntax [anything][,URL(string)]                       ///

preserve
qui{
	clear  
	tempfile  html_text 
	cap copy `"`url'"' `"`html_text'.txt"', replace  			
	local times = 0
	while _rc ~= 0 {
		local times = `times' + 1
		sleep 1000
		cap copy `"`url'"' `"`html_text'.txt"', replace
		if `times' > 10 {
			disp as error "Internet speeds is too low to get the data"
			exit 601
		}
	}
	infix strL v 1-100000 using `"`html_text'.txt"', clear
	cap erase `"`html_text'.txt"'              
	split v,  p("++")       
	cap keep v1 v2 							
}
                           
	local name   =v1[1]         //导航标题
	local number1=v1[2]
	local number2=v1[3]
	local c1     =v1[4]
	local c2     =v1[5]
	local c3     =v1[6]
	
	qui drop if v2==""				
	local G   = 3               // 每行显示个数
	local N   = _N              // 类别数
	local NN  = int(`N'/`G')    // 行数
	local mod = mod(`N',3)      //剩余个数
	dis in w _col(`number1') _n _skip(`number2') `"`name'"' _n
	  
	local k1=1	
	forvalues o = 1/`NN'{
		local a`k1'= v1[`k1']
		local b`k1'= v2[`k1']
		local k2=`k1'+1
		local a`k2'= v1[`k2']
		local b`k2'= v2[`k2']			
		local k3=`k1'+2
		local a`k3'= v1[`k3']
		local b`k3'= v2[`k3']

		if strmatch("`b`k1''","* *")==1{
			dis in w  _col(`c1') `"{stata "`b`k1''":`a`k1''}"'    _continue
		}
		else{
			dis in w  _col(`c1') `"{browse  "`b`k1''":`a`k1''}"'  _continue
		}			

		if strmatch("`b`k2''","* *")==1{
			dis in w  _col(`c2') `"{stata "`b`k2''":`a`k2''}"'        _continue
		}
		else{
			dis in w  _col(`c2') `"{browse  "`b`k2''":`a`k2''}"'      _continue
		}			

		if strmatch("`b`k3''","* *")==1{
			dis in w  _col(`c3') `"{stata "`b`k3''":`a`k3''}"'        _n
		}
		else{
			dis in w  _col(`c3') `"{browse  "`b`k3''":`a`k3''}"'      _n
		}			
					 
		local k1=`k1'+3		
	}
		
	local a_n1   =`NN'*3+1
	local a_n2   =`NN'*3+2		
	local a`a_n1'=v1[`a_n1']
	local b`a_n1'=v2[`a_n1']		
	local a`a_n2'=v1[`a_n2']
	local b`a_n2'=v2[`a_n2']

	if `mod'==1{
		if strmatch("`b`k1''","* *")==1{
			dis in w  _col(`c1') `"{stata "`b`a_n1''":`a`a_n1''}"'  
		}
		else{
			dis in w  _col(`c1') `"{browse "`b`a_n1''":`a`a_n1''}"'  
		}			 	 
	}

	if `mod'==2{
		if strmatch("`b`k1''","* *")==1{
			dis in w  _col(`c1') `"{stata "`b`a_n1''":`a`a_n1''}"' _continue 
		}
		else {
			dis in w  _col(`c1') `"{browse "`b`a_n1''":`a`a_n1''}"'  _continue
		}				 
		if strmatch("`b`k2''","* *")==1{
			dis in w  _col(`c2') `"{stata "`b`a_n2''":`a`a_n2''}"'  
		}
		else{
			dis in w  _col(`c2') `"{browse "`b`a_n2''":`a`a_n2''}"'  
		}				   
	}  
restore
end
	  
	  

cap program drop songbl_links
program define songbl_links

version 8

syntax [anything] [,URL(string)]    
	 
qui{
	preserve
	clear						 
	tempfile  html_text    		
	cap copy `"`url'"' `"`html_text'.txt"', replace  			 			
	local times = 0
	while _rc ~= 0 {
		local times = `times' + 1
		sleep 1000
		cap copy `"`URL'"' `"`html_text'.txt"', replace
		if `times' > 10 {
			disp as error "Internet speeds is too low to get the data"
			cap erase `"`html_text'.txt"' 
			exit 601
		}
	}
	infix strL v 1-100000 using `"`html_text'.txt"', clear
	cap erase `"`html_text'.txt"'          
	split v,  p("++")       
	cap keep v1 v2 							

	local name   =v1[1]   //导航标题
	local number1=v1[2]
	local number2=v1[3]
	local number3=v1[4]	

	count if v2==""
	local r(N)=`r(N)'-7
	forvalues i=1/`r(N)'{
		local j=`i'+4
		local c`i'=v1[`j']  
	}
	drop if v2=="" 		
}	
	local G   = 6               // 每个专题显示个数
	local N   = _N              // 类别数
	local NN  = int(`N'/`G')    // 行数
	local mod = mod(`N',6)      // 剩余个数
	dis in w _col(`number1') _n _skip(`number2') `"`name'"' _n

	local k1=1	
	local m=5
	forvalues o = 1/`NN'{
		forvalues i=1/6{
			local a`k`i''= v1[`k`i''] 
			local b`k`i''= v2[`k`i'']
			local j      =`i'+1
			local k`j'   =`k`i''+1
		}			 
		forvalues i=1/6{			 
			if strmatch("`b`k`i'''","* *")==1{	
				local browse_stata`i' stata
			}			 				 
			else{
				local browse_stata`i' browse
			}				 
		}
		dis in w " `c`m'': "                                     ///
		_col(`c1') `"{`browse_stata1' "`b`k1''":`a`k1''}"'       ///
		_col(`c2') `"{`browse_stata2' "`b`k2''":`a`k2''}"'       ///
		_col(`c3') `"{`browse_stata3' "`b`k3''":`a`k3''}"'       
		dis in w  _col(`number3')                                ///			 		 
		_col(`c1') `"{`browse_stata4' "`b`k4''":`a`k4''}"'       ///
		_col(`c2') `"{`browse_stata5' "`b`k5''":`a`k5''}"'       ///
		_col(`c3') `"{`browse_stata6' "`b`k6''":`a`k6''}"'       ///
		_n 
		local k1=`k1'+6
		local m=`m'+1

	}
	forvalues i=1/5{
		local a_n`i'   =`NN'*6+`i'
		local a`a_n`i''=v1[`a_n`i'']
		local b`a_n`i''=v2[`a_n`i'']
	}
	forvalues i=1/6{			 
		if strmatch("`b`a_n`i'''","* *")==1{	
			 local browse_stata`i' stata
		}			 				 
		else{
			local browse_stata`i' browse
		}				 
	}		 

	if `mod'==1{
		dis in w " `c`m'': "                                         ///
		_col(`c1') `"{`browse_stata1' "`b`a_n1''":`a`a_n1''}"'   
	}
	if `mod'==2{
		dis in w " `c`m'': "                                         ///
		_col(`c1') `"{`browse_stata1' "`b`a_n1''":`a`a_n1''}"'       ///   
		_col(`c2') `"{`browse_stata2' "`b`a_n2''":`a`a_n2''}"'   
	}
	if `mod'==3{
		dis in w " `c`m'': "                                         ///
		_col(`c1') `"{`browse_stata1' "`b`a_n1''":`a`a_n1''}"'       /// 
		_col(`c2') `"{`browse_stata2' "`b`a_n2''":`a`a_n2''}"'       /// 
		_col(`c3') `"{`browse_stata3' "`b`a_n3''":`a`a_n3''}"'	 
	}
	if `mod'==4{
		dis in w " `c`m'': "                                         ///
		_col(`c1') `"{`browse_stata1' "`b`a_n1''":`a`a_n1''}"'       ///  
		_col(`c2') `"{`browse_stata2' "`b`a_n2''":`a`a_n2''}"'       /// 
		_col(`c3') `"{`browse_stata3' "`b`a_n3''":`a`a_n3''}"' 
		dis in w  _col(`number3')                                    ///	
		_col(`c1') `"{`browse_stata4' "`b`a_n4''":`a`a_n4''}"'
	}
	if `mod'==5{
		dis in w " `c`m'': "                                        ///
		_col(`c1') `"{`browse_stata1' "`b`a_n1''":`a`a_n1''}"'      ///  
		_col(`c2') `"{`browse_stata2' "`b`a_n2''":`a`a_n2''}"'      /// 
		_col(`c3') `"{`browse_stata3' "`b`a_n3''":`a`a_n3''}"' 
		dis in w  _col(`number3')                                   ///	
		_col(`c1') `"{`browse_stata4' "`b`a_n4''":`a`a_n4''}"'      ///
		_col(`c2') `"{`browse_stata5' "`b`a_n5''":`a`a_n5''}"'  
	}	
	cap erase `"`html_text'.txt"'              
restore
        
end

cap program drop  songbl_install
program define songbl_install
	gettoken pkgname 0 : 0, parse(" ,")
	CheckPkgname "songbl install" `"`pkgname'"'
	local pkgname `"`s(pkgname)'"'
	syntax [, ALL REPLACE]
	local ltr = bsubstr("`pkgname'",1,1)
	qui net from https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/plus/`ltr'
	capture net describe `pkgname'
	local rc = _rc
	if _rc==601 | _rc==661 {
		di as err /*
*/ `"{bf:ssc install}: "{bf:`pkgname'}" not found at SSC, type {stata search `pkgname'}"'
		di as err /*
*/ "(To find all packages at SSC that start with `ltr', type {stata ssc describe `ltr'})"
		exit `rc'
	}
	if _rc {
		error `rc'
	}
	capture noi net install `pkgname', `all' `replace'
	noi di as txt "see help {help `pkgname':`pkgname'}"
	noi di as txt `"Join a stata {browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/picture/wechat/wechat.jpg":wechat group}"'
	local rc = _rc
	if _rc==601 | _rc==661 {
		di
		di as err /*
*/ `"{p}{bf:ssc install}: apparent error in package file for {bf:`pkgname'}; please notify {browse "mailto:songbl_stata@qq.com":songbl_stata@qq.com}, providing package name{p_end}"'
	}
	exit `rc'
end

cap program drop  CheckPkgname
program define CheckPkgname, sclass
	args id pkgname
	sret clear
	if `"`pkgname'"' == "" {
		di as err `"{bf:`id'}: nothing found where package name expected"'
		exit 198
	}
	if length(`"`pkgname'"')==1 {
		di as err `"{bf:`id'}: "{bf:`pkgname'}" invalid SSC package name"'
		exit 198
	}
	local pkgname = lower(`"`pkgname'"')
	if !index("abcdefghijklmnopqrstuvwxyz_",bsubstr(`"`pkgname'"',1,1)) {
		di as err `"{bf:`id'}: "{bf:`pkgname'}" invalid SSC package name"'
		exit 198
	}
	sret local pkgname `"`pkgname'"'
end     



capture program drop songbl_fy
program define songbl_fy ,rclass
	version 12.0
	syntax [anything(name = content)], [Command PDF REPLACE]
	//下载外部命令
	foreach com in wordconvert moss fs hlp2html{
		cap which  `com'
		if _rc!=0{
			ssc install  `com'
		}		
	}
	if `"`content'"'=="" & `"`pdf'"'==""{
		local path https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com
		local URL "`path'/navigation"     
		n songbl_links1 ,url(`URL'/fanyi.txt)
		exit			
	}
	
	//翻译pdf
	if `"`pdf'"'!=""{
	    if `"`content'"'!=""{
			local htmlfile = usubinstr(`"`content'"',".pdf","",.)
			local htmlfile = usubinstr(`"`htmlfile'"',`"""',"",.)
			cap wordconvert "`htmlfile'.pdf"  "`htmlfile'.html",encoding(gb2312) 
			songbl dir "`htmlfile'.html",max(1)		    
		}
		else{
			qui fs *.pdf
			foreach file in `r(files)'{
				local htmlfile = usubinstr("`file'",".pdf","",.)
				cap wordconvert "`file'"  "`htmlfile'.html",encoding(gb2312)
			}
			songbl dir *html ,max(1)		    
		}
		exit
	}

	//翻译命令
	if "`command'"!="" {
		tokenize `content'
		if `"`content'"'==""{
			disp as error "varlist required"	
			exit 101
		}
		if "`2'"!=""{
			disp as error "varlist not allowed"	
			exit 101
		}
		cap which  hlp2html
		if _rc!=0{
			ssc install hlp2html
		} 	
		cap which  log2html
		if _rc!=0{
			ssc install log2html
		} 	
		
		local class `"`content'"'
		qui hlp2html, fnames(`class') linesize(200) css("./mystyles.css") replace  ///
		erase  ti(Stata communication group wechat : songbl_stata)
		view browse  `class'.html
		songbl dir *html
		exit
	 }			

	
	//以下代码改编来自：https://github.com/r-stata/fanyi
	qui{
	    //翻译句子
		cap preserve
			clear 
			tempfile  temp
			local len = udstrlen(`"`content'"')+5
			percentencode `"`content'"'
			local b = "`r(percentencode)'"
			copy "http://www.youdao.com/w/`b'/#keyfrom=dict2.top" "`temp.txt'", replace
			local times = 0
			while _rc != 0{
				local times = `times' + 1
				sleep 1000
				qui cap copy "http://www.youdao.com/w/`b'/#keyfrom=dict2.top" "`temp.txt'", replace
				if `times' > 10{
					di as error "错误！：因为你的网络速度过慢，无法获得数据"
					exit 601
				}
			}
			infix strL v 1-20000 using "`temp.txt'", clear
			keep if index(v[_n+1], "机器翻译")
			replace v = ustrregexs(1) if ustrregexm(v[1],">(.*)<")
			replace v = subinstr(v, "&#39;", `"'"', .)
			local c = v[1]
			local c = usubinstr("`c'","&quot;","",.)
			local c = usubinstr("`c'",`"""',"",.)
			local c = usubinstr("`c'",`"""',"",.)				
			local len = udstrlen(`"`c'"')+10
			*di as yellow _dup(`len') "-"
			if "`c'"!=""{
				n di as txt "{hline}"
				n di  as text "【译文】：`c'"
				*di as yellow _dup(`len') "-"
				n di as txt "{hline}"	
				ret local result = "`c'"
			}
			//翻译单词
			else{
				foreach word in `content'{
					if ustrregexm("`word'", "[\u4e00-\u9fa5]+"){
						percentencode "`word'"
						local a = "`r(percentencode)'"
						copy "http://cn.bing.com/dict/search?q=`a'&qs=n&form=Z9LH5&sp=-1&pq=`a'&sc=2-2&sk=&cvid=F0EB8DBE335C4C6683304A4D16ECD8FB" "`temp.txt'", replace
						local times = 0
						while _rc != 0{
							local times = `times' + 1
							sleep 1000
							qui cap copy "http://cn.bing.com/dict/search?q=`a'&qs=n&form=Z9LH5&sp=-1&pq=`a'&sc=2-2&sk=&cvid=F0EB8DBE335C4C6683304A4D16ECD8FB" "`temp.txt'", replace
							if `times' > 10{
								di as error "错误！：因为你的网络速度过慢，无法获得数据"
								exit 601
							}
						}
						infix strL v 1-20000 using "`temp.txt'", clear
						keep if index(v, "<title>")
						replace v = subinstr(v, "网络释义：", "net.", .)
						set obs 13
						gen v2 = _n - 3
						gen v3 = _n
						tostring v2, replace
						tostring v3, replace
						replace v2 = "【词语】" if v2 == "-2"
						replace v2 = "【拼音】" if v2 == "-1"
						replace v2 = "【英语】" if v2 == "0"
						replace v3 = "`word'" if v3 == "1"
						replace v3 = ustrregexs(0) if ustrregexm(v[1],"\[(.*)\]") & v3 == "2"
						replace v3 = subinstr(v3, "]", "", .)
						replace v3 = subinstr(v3, "[", "", .)
						replace v3 = ustrregexs(0) if ustrregexm(v[1], "，[a-z].(.*)；") & v3 == "3"
						replace v3 = subinstr(v3, "，", "", .)
						gen strL a = v3[3] in 1
						moss a, match("([a-z]+\.+?)") regex unicode
						levelsof _count, local(b)
						local c = `b' + 3
						forval i = 4/`c'{
							local j = `i' - 3
							replace v2 = _match`j'[1] if v2 == "`j'"
						}
						drop if _n > `c'
						global p = ""
						forval i = 1/`b'{
							global p = "$p" + " " + _match`i'
						}
						keep v v2 v3
						cap split v3 if v3[_n+1] == "4", parse($p)
						if _rc!=0{
						 display as error "  太难了,Stata也不知道怎么翻译"
						 exit 110
						}
						local j = 2
						forval i = 4/`c'{
							replace v3 = v3`j'[3] if v3 == "`i'"
							local j = `j' + 1
						}
						replace v3 = "" if v2 == "【英语】" 
						keep v2 v3
						rename v2 a
						rename v3 b
						replace b = subinstr(b, "2", "", .)
						format b %-50s
						compress
						cap erase "`temp.txt'"
						forval i = 1/`=_N'{
							local temp = a[`i']
							if "`temp'" == "【单词】"{
								local temp = "word"
							}
							if "`temp'" == "【读音】"{
								local temp = "prounciation"
							}
							if "`temp'" == "【释义】"{
								local temp = "means"
							}
							n di as text a[`i'] + ":" + b[`i']
						}
						n di ""
					}
					else{
					copy "http://cn.bing.com/dict/search?q=`word'&qs=n&form=Z9LH5&sp=-1&pq=`word'&sc=7-3&sk=&cvid=E8E3C113211944A69B575B5DA2C9009A" "`temp.txt'", replace
					local times = 0
					while _rc != 0{
						local times = `times' + 1
						sleep 1000
						qui cap copy "http://cn.bing.com/dict/search?q=`word'&qs=n&form=Z9LH5&sp=-1&pq=`word'&sc=7-3&sk=&cvid=E8E3C113211944A69B575B5DA2C9009A" "`temp.txt'", replace
						if `times' > 10{
							di as error "错误！：因为你的网络速度过慢，无法获得数据"
							exit 601
						}
					}
					cap unicode encoding set gb18030
					cap unicode translate "`temp.txt'"
					cap unicode erasebackups, badidea
					infix strL v 1-20000 using "`temp.txt'", clear
					keep if index(v, "keywords")
					set obs 13
					gen v2 = _n - 3
					gen v3 = _n
					tostring v2, replace
					tostring v3, replace
					replace v2 = "【单词】" if v2 == "-2"
					replace v2 = "【读音】" if v2 == "-1"
					replace v2 = "【释义】" if v2 == "0"
					replace v3 = "`word'" if v3 == "1"
					replace v3 = ustrregexs(0) if ustrregexm(v[1],"美\[(.*)\]") & v3 == "2"
					replace v = subinstr(v, " ", "", .)
					replace v3 = ustrregexs(0) if ustrregexm(v[1], "，[a-z].(.*)；") & v3 == "3"
					replace v3 = subinstr(v3, "，", "", .)
					replace v2 = ustrregexs(2) if ustrregexm(v3[3],"([a-z]+\.+?)") & v2 == "8"
					gen strL a = v3[3] in 1
					moss a, match("([a-z]+\.+?)") regex unicode
					levelsof _count, local(b)
					local c = `b' + 3
					forval i = 4/`c'{
						local j = `i' - 3
						replace v2 = _match`j'[1] if v2 == "`j'"
					}
					drop if _n > `c'
					global p = ""
					forval i = 1/`b'{
						global p = "$p" + " " + _match`i'
					}
					keep v v2 v3
					cap split v3 if v3[_n+1] == "4", parse($p)
					if _rc!=0{
						 display as error "	 太难了,Stata也不知道怎么翻译"
						 exit 110
					}
					local j = 2
					forval i = 4/`c'{
						replace v3 = v3`j'[3] if v3 == "`i'"
						local j = `j' + 1
					}
					replace v3 = "" if v2 == "【释义】" 
					keep v2 v3
					rename v2 a
					rename v3 b
					format b %-50s
					compress
					cap erase "`temp.txt'" 
					if index(b[_N], "网络释义"){
						split b if index(b[_N], "网络释义"), parse(网络释义：)
					}
					local obs = `c' + 1
					set obs `obs'
					replace a = "net." if a == ""
					replace b = b2[_n-1] if b == ""
					replace b = b1 if index(b, "网络释义")
					keep a b
					replace b = "`word'" if a == "【单词】"
					forval i = 1/`=_N'{
						local temp = a[`i']
						if "`temp'" == "【单词】"{
							local temp = "word"
						}
						if "`temp'" == "【读音】"{
							local temp = "prounciation"
						}
						if "`temp'" == "【释义】"{
							local temp = "means"
						}
						n di as text a[`i'] + ":" + b[`i']
					}
					n di "" _n
				}
				}
			}	
		restore	
		cap erase "`temp.txt'"  
	}	
end

*! URL 转码
cap program drop percentencode
program define percentencode, rclass
mata: st_local("percentencode", percentencode(`"`1'"'))
return local percentencode "`percentencode'"
*di "`percentencode'"
end
mata:
string scalar percentencode(string scalar s){
  lc = "abcdefghijklmnopqrstuvwxyz"
  uc = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  no = "1234567890"
  re = "-._~"
  str = lc + uc + no + re
  asc = ascii(s)'
  sel = rowmax(asc :== J(rows(asc), 1, ascii(str)))
  chr = sel:* strofreal(asc)
  enc = !sel :* ("%" :+ inbase(16, asc))
  final = strupper(chr :+ enc)
  for(i=1; i<=rows(final); i++) {
    if (substr(final[i], 1, 1)!="%") {
      final[i] = char(strtoreal(final[i]))
    }
  }
  return (invtokens(final', ""))
}
end


*! Verion: 1.0
*! Update: 2021/05/30 12:32
*! Verion: 1.01
*! Update: 2021/08/06 05:58
capture program drop songbl_get
program define songbl_get, rclass
version 14

syntax [anything(name = pkgname)][,REPLACE NOpen Drop(string) ]
 
if `"`pkgname'"'==""{
	di as text "请输入获取{bf:dofile}的提取码：" _request(sbldokey)
	local pkgname "$sbldokey"
}
 
	/*保存原始dofile链接*/
local original_pkgname=`"`pkgname'"'
	/*消去dofile链接的双引号*/
local pkgname `pkgname'

	/*切割dofile链接*/
if strmatch(`"`pkgname'"',"*/*")==1 | strmatch(`"`pkgname'"',"*\*")==1{
	local pkgname: subinstr local pkgname "\" "/", all	
	gettoken pkgname other : pkgname, parse("/:")
	while "`other'" != "" {
		local path "`path'`pkgname'"
		gettoken pkgname other : other, parse("/:")
	}
} 

	/*dofile名称如果是.do结尾则删除.do*/
if  usubstr("`pkgname'",-3,3) ==".do" {
	local pkgname =plural(2, "`pkgname'","-.do") 
}

	/*如果用户只输入dofile名称，不包含链接。则指定默认路径*/
if strpos(`"`original_pkgname'"',"http")==0{
  local URL "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/do/" //默认路径
}

else{
  local URL = "`path'" //切割dofile链接得到的路径
}    

	/*下载的dofile放置到外部命令文件夹*/
local PATH     `"`c(sysdir_plus)'"'    		//外部命令文件夹    
local path      =substr("`pkgname'",1,1) 	//dofile名称首字母
local PATH     `PATH'\`path'\ 				//dofile保存的文件夹
capture mkdir `"`PATH'"'        			//如果文件夹不存在，则生成一个文件夹
local PATH =subinstr("`PATH'","/","\",.) 

	/*检查dofile是否已经下载*/
capture confirm file "`PATH'\`pkgname'.do" //核查dofile是否已经存在于外部命令文件夹
local rc_confirm =_rc     
capture qui checksum `"`PATH'\`pkgname'.do"'   
local rc_path =_rc 
local pathcheck =r(filelen)           	   //核查已存在的dofile文件大小
capture qui checksum  "`URL'`pkgname'.do" 
local rc_url =_rc 
local urlcheck =r(filelen)     		 	   //核查待下载的dofile文件大小    

	/*返回679错误，则表明待下载的dofile文件已经加密*/
if `rc_url' == 679 {
	di as err   `"web error 403"'                    
	di as err _col(5)  `"The data or document have been encrypted."'
	di as err _col(5)  `"To obtain the key, please contact wechat：{browse "https://note.youdao.com/ynoteshare1/index.html?id=720635d3824de83e0e764a60eb34e54c&type=note":{bf:songbl_stata}}"'
	exit 679
} 					

	/*返回非679错误，则表明待下载的dofile文件不存在*/
if `rc_url'!=679 & `rc_url'!=0{              
	di as err  `"songbl copy: "`pkgname'.do" not found. Please check the dofile link carefully."'
	exit 601
}        

dis as text `"checking {bf:`pkgname'.do} consistency and verifying not already installed..."'


	/*核查dofile是否已经存在于外部命令文件夹*/
if `rc_confirm'==0 & "`replace'"==""{
		
	/*核查文件已存在dofile大小与待下载的dofile文件大小是否一致，不一致则表明dofile文件有更新*/		
	if `pathcheck'- `urlcheck'!=0{
		dis ""
		dis as text "the following files already exist and are different:"
		dis as text _col(5) `"{stata `"doedit `"`PATH'\`pkgname'.do"'"':{bf:`PATH'\`pkgname'.do}}"'
		dis ""
		dis as err "no files installed or downloaded"
		dis as err _col(4) `"{stata `"songbl_get `original_pkgname',replace"':{bf: Force download replacing already-downloaded files}}"'
		dis as err "(no action taken)"
		
		if "`nopen'"==""{
			doedit `"`PATH'\`pkgname'.do"'
		}
		/*返回dofile文件的名称与保存路径*/	
		return local filename   `"`pkgname'.do"' 
		return local path  		`"`PATH'"' 
		return local adofile    `"`PATH'\`pkgname'.do"'            
		exit 602
	}
	
	/*一致则表明dofile文件没有更新*/			
	else{
		dis as text _col(5) `"{stata `"doedit `"`PATH'\`pkgname'.do"'"':{bf:`PATH'\`pkgname'.do}} already exist and are up to date."'
		
		if "`nopen'"==""{
			doedit `"`PATH'\`pkgname'.do"'
		}
		/*返回dofile文件的名称与保存路径*/	
		return local filename   `"`pkgname'.do"' 
		return local path  		`"`PATH'"' 
		return local adofile    `"`PATH'\`pkgname'.do"'  
		exit
	}              
	
} 

dis ""
dis as text "the following files will be replaced:"
dis as text _col(5)  `"{stata `"doedit "`PATH'\`pkgname'.do""':{bf:`PATH'\`pkgname'.do}}"' 	 _n
dis as text "installing into `PATH'..."

	/*下载的dofile文件*/	
capture copy  "`URL'`pkgname'.do"   `"`PATH'\`pkgname'.do"',replace                     
local times = 0
while _rc ~= 0 {
	local times = `times' + 1
	sleep 1000
	capture copy  "`URL'`pkgname'.do"   `"`PATH'\`pkgname'.do"',replace    
	if `times' > 10 {		
		disp as error "Internet speeds is too low to get the dofile"
		exit 601
	}
}
	
if "`no'"==""{
	doedit `"`PATH'\`pkgname'.do"'
}

	/*返回dofile文件的名称与保存路径*/
return local filename   `"`pkgname'.do"' 
return local path  		`"`PATH'"' 
return local adofile    `"`PATH'\`pkgname'.do"'  
       
end




*! Verion: 1.0
*! Update: 2021/5/30 12:32

cap program drop songbl_dir
program define songbl_dir
version 14
syntax [anything(name = paper)][,Cls Gap Line NOCAT MAXdeep(numlist integer max=1 min=1 >0 <10 )  Drop(string) FY ] 
preserve  
qui{	
		if "`cls'" != ""{
			cls
			dis ""
		}	
		
		if "`fy'" != ""{
			if "`nocat'"==""{
				n dis as erro    `"{browse "`c(pwd)'":{bf:>>}}"' `" {bf:Current Working Directory}"'
			}			
			fs *.pdf
			foreach file in `r(files)'{
				n dis _col(4) in txt `"{stata `"songbl fy "`file'",pdf"':Translate   }"' "`file'"
				 exit
			}
		}			
			
		cap which filelist	
		if _rc!=0{
			ssc install filelist
		}
 		tempfile tempdata2 tempdata3 tempdata4 tempdata5 tempdata6 tempdata7 tempdata8 tempdata9 //可以打印8层文件夹
		if  "`maxdeep'"!=""{
			local maxdeep ="maxdeep(`maxdeep')" 
		}  		
		if "`gap'" != "" {		 
			local gap dis ""
		}	
	
		n dis ""
		local root_files `c(pwd)'
		*cap filelist , `pattern' `maxdeep'
		
		if `"`paper'"'==""{
		cap filelist , `maxdeep'		
		}
		else{
			local i = 1
			foreach class of local paper{
				tempfile class`i'
				local pattern ="pattern(`class')"   
				cap filelist , `pattern' `maxdeep'	
				save "`class`i''",replace
				local ++i
			}
			local n : word count `paper'
			use "`class1'",clear 
			if `n'>1{
				forvalues i = 2/`n'{
					capture append using "`class`i''"
				}			
			}			
		}

		gettoken s1 s2: drop, parse(" ")  
		while "`s1'" !="`s2'" {
		    gettoken s1 s2: drop, parse(" ")  
			drop if strmatch(filename,"`s1'") 
			local drop ="`s2'"
		}
		drop if strmatch(filename,"~*") 
		count
		local Number_of_files_found = r(N)			
		if _rc==601 {
			local RC=601
			*filelist , `pattern'
		}
		replace dirname=substr(dirname,2,.)
		gen url="`root_files'"+dirname+"/"+filename
		cap split dirname,p("/")
		if _rc!=0{
			if `Number_of_files_found'==0{
				n dis as erro "没有搜索到相关文件"
				exit 601				
			}
			else{
			    if "`nocat'"==""{
					n dis as erro    `"{browse "`root_files'":{bf:>>}}"' `" {bf:Current Working Directory}"'
 				}
				sort filename
				local n=_N
				forvalues i = 1/`n'{
					local url=url[`i']
					local filename=filename[`i']
					if usubstr("`url'",-3,3) ==".do" | usubstr("`url'",-4,4) ==".ado" | ///
					   usubstr("`url'",-4,4) ==".hlp"| usubstr("`url'",-6,6) ==".sthlp"	{
					    if "`line'"!=""{
						 n dis _col(4) in txt `"{stata `"doedit `"`url'"'"':{bf:-}}"' `"  `filename'"'  
						}
						else{
						 n dis _col(4) `"{stata `"doedit `"`url'"'"':`filename'}"'
						}							
					}
					else if usubstr("`url'",-4,4) ==".dta"{
					    if "`line'"!=""{
						 n dis _col(4) in txt `"{stata `"use `"`url'"'"':{bf:-}}"' `"  `filename'"'  
						}
						else{
						 n dis _col(4) `"{stata `"use `"`url'"'"':`filename'}"'
						}					    						 						 
					}					
					else{
					    if "`line'"!=""{
							n dis _col(4) in txt `"{browse `"`url'"':{bf:-}}"' `"  `filename'"'  
						}
						else{
							n dis _col(4) `"{browse `"`url'"':`filename'}"'
						}
					} 
					n `gap'
				}
			if "`RC'"==""{
					local RC = 600
			}					
			if `RC'==601{
				filelist , `pattern'    
			}				
			exit
			}
		}
		ds dirname*
		local n : word count `r(varlist)'
		save "`tempdata2'",replace
		if "`nocat'"==""{
			n dis as erro    `"{browse "`root_files'":{bf:>>}}"'  `" {bf:Current Working Directory}"' 
		}
		cap keep if  dirname2==""
		sort filename
		local n=_N
		forvalues i = 1/`n'{
			local url=url[`i']
			local filename=filename[`i']
			if usubstr("`url'",-3,3) ==".do" | usubstr("`url'",-4,4) ==".ado" | ///
			   usubstr("`url'",-4,4) ==".hlp"| usubstr("`url'",-6,6) ==".sthlp"	{
				if "`line'"!=""{
					n dis _col(4) in txt `"{stata `"doedit `"`url'"'"':{bf:-}}"' `"  `filename'"'  
				}
				else{
					n dis _col(4) `"{stata `"doedit `"`url'"'"':`filename'}"'
				}							
			}
			else if usubstr("`url'",-4,4) ==".dta"{
				if "`line'"!=""{
					n dis _col(4) in txt `"{stata `"use `"`url'"'"':{bf:-}}"' `"  `filename'"'  
				}
				else{
					n dis _col(4) `"{stata `"use `"`url'"'"':`filename'}"'
				}					    						 						 
			}					
			else{
				if "`line'"!=""{
					n dis _col(4) in txt `"{browse `"`url'"':{bf:-}}"' `"  `filename'"'  
				}
				else{
					n dis _col(4) `"{browse `"`url'"':`filename'}"'
				}
			} 			
				n `gap'
		}	
		
		use "`tempdata2'", clear

		cap levelsof dirname2, local(dirname2)		
		foreach  dirname2  in  `dirname2' { 		
			use "`tempdata2'", clear
			cap keep if dirname2=="`dirname2'"
			if "`nocat'"==""{
				n dis "" 			
			}
			*else{
			*	n dis "" _n		
			*}
			if "`nocat'"==""{
				n dis as erro   _col(4)  `"{browse "`root_files'/`dirname2'":{bf:>>}}"'  `" {bf:`dirname2'}"' 	
			}
			cap keep if  dirname3==""
			sort filename
			local n=_N
			forvalues i = 1/`n'{
				local url=url[`i']
				local filename=filename[`i']
				if usubstr("`url'",-3,3) ==".do" | usubstr("`url'",-4,4) ==".ado" | ///
				   usubstr("`url'",-4,4) ==".hlp"| usubstr("`url'",-6,6) ==".sthlp"	{
					if "`line'"!=""{
						n dis _col(7) in txt `"{stata `"doedit `"`url'"'"':{bf:-}}"' `"  `filename'"'  
					}
					else{
						n dis _col(7) `"{stata `"doedit `"`url'"'"':`filename'}"'
					}							
				}
				else if usubstr("`url'",-4,4) ==".dta"{
					if "`line'"!=""{
						n dis _col(7) in txt `"{stata `"use `"`url'"'"':{bf:-}}"' `"  `filename'"'  
					}
					else{
						n dis _col(7) `"{stata `"use `"`url'"'"':`filename'}"'
					}					    						 						 
				}					
				else{
					if "`line'"!=""{
						n dis _col(7) in txt `"{browse `"`url'"':{bf:-}}"' `"  `filename'"'  
					}
					else{
						n dis _col(7) `"{browse `"`url'"':`filename'}"'
					}
				} 
				n `gap'
			}	
			use "`tempdata2'", clear
			cap keep if dirname2=="`dirname2'"	
			
			cap levelsof dirname3, local(dirname3)
				if _rc==0{
					save "`tempdata3'",replace
					foreach  dirname3  in  `dirname3' { 
						use "`tempdata3'", clear	
						cap keep if dirname3=="`dirname3'"
						if "`nocat'"==""{
							n dis as erro   _col(7)  `"{browse "`root_files'/`dirname2'/`dirname3'":{bf:>>}}"'  `" {bf:`dirname3'}"' 
						}
						cap keep if  dirname4==""
						sort filename
						local n=_N
						forvalues i = 1/`n'{
							local url=url[`i']
							local filename=filename[`i']
							if usubstr("`url'",-3,3) ==".do" | usubstr("`url'",-4,4) ==".ado" | ///
							   usubstr("`url'",-4,4) ==".hlp"| usubstr("`url'",-6,6) ==".sthlp"	{
								if "`line'"!=""{
									n dis _col(10) in txt `"{stata `"doedit `"`url'"'"':{bf:-}}"' `"  `filename'"'  
								}
								else{
									n dis _col(10) `"{stata `"doedit `"`url'"'"':`filename'}"'
								}							
							}
							else if usubstr("`url'",-4,4) ==".dta"{
								if "`line'"!=""{
									n dis _col(10) in txt `"{stata `"use `"`url'"'"':{bf:-}}"' `"  `filename'"'  
								}
								else{
									n dis _col(10) `"{stata `"use `"`url'"'"':`filename'}"'
								}					    						 						 
							}					
							else{
								if "`line'"!=""{
									n dis _col(10) in txt `"{browse `"`url'"':{bf:-}}"' `"  `filename'"'  
								}
								else{
									n dis _col(10) `"{browse `"`url'"':`filename'}"'
								}
							} 
							n `gap'
						}	
						use "`tempdata3'", clear
						cap keep if dirname3=="`dirname3'"
						
						cap levelsof dirname4, local(dirname4)
							if _rc==0{
								save "`tempdata4'",replace
								foreach  dirname4  in  `dirname4' { 
									use "`tempdata4'", clear	
									cap keep if dirname4=="`dirname4'"
									if "`nocat'"==""{
										n dis as erro   _col(10)  `"{browse "`root_files'/`dirname2'/`dirname3'/`dirname4'":{bf:>>}}"'   `" {bf:`dirname4'}"' 
									}
									cap keep if  dirname5==""
									sort filename
									local n=_N
									forvalues i = 1/`n'{
										local url=url[`i']
										local filename=filename[`i']
										if usubstr("`url'",-3,3) ==".do" | usubstr("`url'",-4,4) ==".ado" | ///
										   usubstr("`url'",-4,4) ==".hlp"| usubstr("`url'",-6,6) ==".sthlp"	{
											if "`line'"!=""{
												n dis _col(13) in txt `"{stata `"doedit `"`url'"'"':{bf:-}}"' `"  `filename'"'  
											}
											else{
												n dis _col(13) `"{stata `"doedit `"`url'"'"':`filename'}"'
											}							
										}
										else if usubstr("`url'",-4,4) ==".dta"{
											if "`line'"!=""{
												n dis _col(13) in txt `"{stata `"use `"`url'"'"':{bf:-}}"' `"  `filename'"'  
											}
											else{
												n dis _col(13) `"{stata `"use `"`url'"'"':`filename'}"'
											}					    						 						 
										}					
										else{
											if "`line'"!=""{
												n dis _col(13) in txt `"{browse `"`url'"':{bf:-}}"' `"  `filename'"'  
											}
											else{
												n dis _col(13) `"{browse `"`url'"':`filename'}"'
											}
										}  
										n `gap'
									}	
									use "`tempdata4'", clear
									cap keep if dirname4=="`dirname4'"	
									
									cap levelsof dirname5, local(dirname5)
										if _rc==0{
											save "`tempdata5'",replace
											foreach  dirname5  in  `dirname5' { 
												use "`tempdata5'", clear	
												cap keep if dirname5=="`dirname5'"
												if "`nocat'"==""{
													n dis as erro   _col(13)  `"{browse "`root_files'/`dirname2'/`dirname3'/`dirname4'/`dirname5'":{bf:>>}}"'  `" {bf:`dirname5'}"'
												}	
												cap keep if  dirname6==""
												sort filename
												local n=_N
												forvalues i = 1/`n'{
													local url=url[`i']
													local filename=filename[`i']
													if usubstr("`url'",-3,3) ==".do" | usubstr("`url'",-4,4) ==".ado" | ///
													   usubstr("`url'",-4,4) ==".hlp"| usubstr("`url'",-6,6) ==".sthlp"	{
														if "`line'"!=""{
															n dis _col(16) in txt `"{stata `"doedit `"`url'"'"':{bf:-}}"' `"  `filename'"'  
														}
														else{
															n dis _col(16) `"{stata `"doedit `"`url'"'"':`filename'}"'
														}							
													}
													else if usubstr("`url'",-4,4) ==".dta"{
														if "`line'"!=""{
															n dis _col(16) in txt `"{stata `"use `"`url'"'"':{bf:-}}"' `"  `filename'"'  
														}
														else{
															n dis _col(16) `"{stata `"use `"`url'"'"':`filename'}"'
														}					    						 						 
													}					
													else{
														if "`line'"!=""{
															n dis _col(16) in txt `"{browse `"`url'"':{bf:-}}"' `"  `filename'"'  
														}
														else{
															n dis _col(16) `"{browse `"`url'"':`filename'}"'
														}
													} 
													n `gap'
												}	
												use "`tempdata5'", clear
												cap keep if dirname5=="`dirname5'"
												
												cap levelsof dirname6, local(dirname6)
													if _rc==0{
														save "`tempdata6'",replace
														foreach  dirname6  in  `dirname6' { 
															use "`tempdata6'", clear	
															cap keep if dirname6=="`dirname6'"
															if "`nocat'"==""{
																n dis as erro   _col(16)  `"{browse "`root_files'/`dirname2'/`dirname3'/`dirname4'/`dirname5'/`dirname6'":{bf:>>}}"'  `" {bf:`dirname6'}"' 	
															}	
															cap keep if  dirname7==""
															sort filename
															local n=_N
															forvalues i = 1/`n'{
																local url=url[`i']
																local filename=filename[`i']
																if usubstr("`url'",-3,3) ==".do" | usubstr("`url'",-4,4) ==".ado" | ///
																   usubstr("`url'",-4,4) ==".hlp"| usubstr("`url'",-6,6) ==".sthlp"	{
																	if "`line'"!=""{
																		n dis _col(19) in txt `"{stata `"doedit `"`url'"'"':{bf:-}}"' `"  `filename'"'  
																	}
																	else{
																		n dis _col(19) `"{stata `"doedit `"`url'"'"':`filename'}"'
																	}							
																}
																else if usubstr("`url'",-4,4) ==".dta"{
																	if "`line'"!=""{
																		n dis _col(19) in txt `"{stata `"use `"`url'"'"':{bf:-}}"' `"  `filename'"'  
																	}
																	else{
																		n dis _col(19) `"{stata `"use `"`url'"'"':`filename'}"'
																	}					    						 						 
																}					
																else{
																	if "`line'"!=""{
																		n dis _col(19) in txt `"{browse `"`url'"':{bf:-}}"' `"  `filename'"'  
																	}
																	else{
																		n dis _col(19) `"{browse `"`url'"':`filename'}"'
																	}
																} 
																n `gap'
															}	
															use "`tempdata6'", clear
															cap keep if dirname6=="`dirname6'"
															
															cap levelsof dirname7, local(dirname7)
																if _rc==0{
																	save "`tempdata7'",replace
																	foreach  dirname7  in  `dirname7' { 
																		use "`tempdata7'", clear	
																		cap keep if dirname7=="`dirname7'"
																		if "`nocat'"==""{
																			n dis as erro   _col(19)  `"{browse "`root_files'/`dirname2'/`dirname3'/`dirname4'/`dirname5'/`dirname6'/`dirname7'":{bf:>>}}"'  `" {bf:`dirname7'}"' 	
																		}
																		cap keep if  dirname8==""
																		sort filename
																		local n=_N
																		forvalues i = 1/`n'{
																			local url=url[`i']
																			local filename=filename[`i']
																			if usubstr("`url'",-3,3) ==".do" | usubstr("`url'",-4,4) ==".ado" | ///
																			   usubstr("`url'",-4,4) ==".hlp"| usubstr("`url'",-6,6) ==".sthlp"	{
																				if "`line'"!=""{
																					n dis _col(22) in txt `"{stata `"doedit `"`url'"'"':{bf:-}}"' `"  `filename'"'  
																				}
																				else{
																					n dis _col(22) `"{stata `"doedit `"`url'"'"':`filename'}"'
																				}							
																			}
																			else if usubstr("`url'",-4,4) ==".dta"{
																				if "`line'"!=""{
																					n dis _col(22) in txt `"{stata `"use `"`url'"'"':{bf:-}}"' `"  `filename'"'  
																				}
																				else{
																					n dis _col(22) `"{stata `"use `"`url'"'"':`filename'}"'
																				}					    						 						 
																			}					
																			else{
																				if "`line'"!=""{
																					n dis _col(22) in txt `"{browse `"`url'"':{bf:-}}"' `"  `filename'"'  
																				}
																				else{
																					n dis _col(22) `"{browse `"`url'"':`filename'}"'
																				}
																			} 
																			n `gap'
																		}	
																		use "`tempdata7'", clear
																		cap keep if dirname7=="`dirname7'"
																		
																		cap levelsof dirname8, local(dirname8)
																			if _rc==0{
																				save "`tempdata8'",replace
																				foreach  dirname8  in  `dirname8' { 
																					use "`tempdata8'", clear	
																					cap keep if dirname8=="`dirname8'"
																					if "`nocat'"==""{
																						n dis as erro   _col(22)  `"{browse "`root_files'/`dirname2'/`dirname3'/`dirname4'/`dirname5'/`dirname6'/`dirname7'/`dirname8'":{bf:>>}}"'  `" {bf:`dirname8'}"' 	
																					}	
																					cap keep if  dirname9==""
																					sort filename
																					local n=_N
																					forvalues i = 1/`n'{
																						local url=url[`i']
																						local filename=filename[`i']
																						if usubstr("`url'",-3,3) ==".do" | usubstr("`url'",-4,4) ==".ado" | ///
																						   usubstr("`url'",-4,4) ==".hlp"| usubstr("`url'",-6,6) ==".sthlp"	{
																							if "`line'"!=""{
																							 n dis _col(25) in txt `"{stata `"doedit `"`url'"'"':{bf:-}}"' `"  `filename'"'  
																							}
																							else{
																							 n dis _col(25) `"{stata `"doedit `"`url'"'"':`filename'}"'
																							}							
																						}
																						else if usubstr("`url'",-4,4) ==".dta"{
																							if "`line'"!=""{
																								n dis _col(25) in txt `"{stata `"use `"`url'"'"':{bf:-}}"' `"  `filename'"'  
																							}
																							else{
																								n dis _col(25) `"{stata `"use `"`url'"'"':`filename'}"'
																							}					    						 						 
																						}					
																						else{
																							if "`line'"!=""{
																								n dis _col(25) in txt `"{browse `"`url'"':{bf:-}}"' `"  `filename'"'  
																							}
																							else{
																								n dis _col(25) `"{browse `"`url'"':`filename'}"'
																							}
																						} 
																							n `gap'
																					}	
																					use "`tempdata8'", clear
																					cap keep if dirname8=="`dirname8'"
																					
																					cap levelsof dirname9, local(dirname9)
																						if _rc==0{
																							save "`tempdata9'",replace
																							foreach  dirname9  in  `dirname9' { 
																								use "`tempdata9'", clear	
																								cap keep if dirname9=="`dirname9'"
																								if "`nocat'"==""{
																									n dis as erro   _col(25)  `"{browse "`root_files'/`dirname2'/`dirname3'/`dirname4'/`dirname5'/`dirname6'/`dirname7'/`dirname8'/`dirname9'":{bf:>>}}"'  `" {bf:`dirname9'}"' 	
																								}	
																								cap keep if  dirname10==""
																								sort filename
																								local n=_N
																								forvalues i = 1/`n'{
																									local url=url[`i']
																									local filename=filename[`i']
																									if usubstr("`url'",-3,3) ==".do" | usubstr("`url'",-4,4) ==".ado" | ///
																									   usubstr("`url'",-4,4) ==".hlp"| usubstr("`url'",-6,6) ==".sthlp"	{
																										if "`line'"!=""{
																											n dis _col(28) in txt `"{stata `"doedit `"`url'"'"':{bf:-}}"' `"  `filename'"'  
																										}
																										else{
																											n dis _col(28) `"{stata `"doedit `"`url'"'"':`filename'}"'
																										}							
																									}
																									else if usubstr("`url'",-4,4) ==".dta"{
																										if "`line'"!=""{
																											n dis _col(28) in txt `"{stata `"use `"`url'"'"':{bf:-}}"' `"  `filename'"'  
																										}
																										else{
																											n dis _col(28) `"{stata `"use `"`url'"'"':`filename'}"'
																										}					    						 						 
																									}					
																									else{
																										if "`line'"!=""{
																											n dis _col(28) in txt `"{browse `"`url'"':{bf:-}}"' `"  `filename'"'  
																										}
																										else{
																											n dis _col(28) `"{browse `"`url'"':`filename'}"'
																										}
																									} 
																									n `gap'
																								}	
																								use "`tempdata9'", clear
																								cap keep if dirname8=="`dirname9'"												
																							}
																						}																																																																															
																																						
																				}
																			}																																																																															
																	
																	}
																}																																												
																										
															
														}
													}																																												
											}
										}										
																	
								}
							}										
					
					}
				}
		}
	if "`RC'"==""{
			local RC = 600
	}	
	if `RC'==601{
		filelist , `pattern'    
	}
}		
restore	
end



cap program drop songbl_cie
program define songbl_cie
version 14
syntax [anything(name = class)] [, CLS Gap NOreplace] 
preserve
qui{
	if "`cls'" != ""{
		cls
		dis ""
	}	
	if "`gap'" != "" {		 
		local gap  dis ""
	} 	
	if "`class'"==""{
		local path https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com
		local URL "`path'/navigation"					
		n songbl_links ,url(`URL'/cie.txt) 
		exit
		exit
	}
	cap which carryforward
	if _rc!=0{
		qui ssc install carryforward,replace
	}
	tempfile  html_text  text  
	local url https://note.youdao.com/yws/api/personal/file/A591767E58A84994B25171581E136448?method=download&shareKey=a00a0dca31ca8cd8025a890286f08cc3
	cap copy `"`url'"' `"`html_text'.txt"', replace  
	if _rc ~= 0 {
		local url https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/cie.txt
		cap copy `"`url'"'  `"`html_text'.txt"', replace  
	}						
	local times = 0
	while _rc ~= 0 {
		local times = `times' + 1
		sleep 1000
		cap copy `"`url'"' `"`html_text'.txt"', replace
		if `times' > 10 {
			disp as error "Internet speeds is too low to get the data"
			exit 601
		}
	}									
	infix strL v 1-100000 using `"`html_text'.txt"', clear 
	cap erase `"`html_text'.txt"' 
	replace v = lower(v) 
	local o_class= "`class'"
	local class = lower("`class'")
	gen n=_n
	gen title=v if index(v[_n-1],"**#论文标题：") 
	replace title=title[_n+10]
	gen id=n if index(v[_n+9],"**#论文标题：") 
	carryforward title id,replace
	gen sort = _n
	save "`text'.dta",replace
	duplicates drop id,force 
	drop if id ==.
	gen num =_n
	keep id num
	merge 1:m id using "`text'.dta"
	cap drop "`text'.dta"
	sort sort
	tostring num ,replace
	gen cie="cie"+num
	keep if strmatch(v,`"*`class'*"')
	capture duplicates drop id, force
	if _rc!=0{
		dis as error "《中国工业经济》代码没有发现相关内容"
		exit
	}	
	local n=_N
	n dis as w `" 代码 >>"' `"{stata "songbl `class',cie save(txt)": 详细检索}"'
	forvalues i =1/`n'{
		local cie   = cie[`i']
		local title = title[`i']
		if "`noreplace'"==""{
			n dis in text _col(4)  "{stata qui songbl get `cie',replace:`title'}"	
		}
		else{
			n dis in text _col(4)  "{stata qui songbl get `cie':`title'}"	
		}
		n `gap'
	}	
	n dis ""
	n dis in red  _col(4)"检索到`n'篇存在 {bf:`o_class'} 关键词的do文档"
	exit
}		
 restore       
end         


**如何把excel数据批量转为stata数据
cap prog drop songbl_excel
prog define songbl_excel
	version 14
	syntax [anything] [,Firstrow REPLACE FRAME]

qui{
    local a=1
    local e=1
    local files: dir "." file "*.xlsx", respectcase
    foreach file in `files' {
        cap import excel using "`file'", describe
                if _rc!=0{
                    local e`e'="`file'"
                    local e=`e'+1
                    continue           
                }  
        forvalues i = 1/`r(N_worksheet)' {
           
           import excel using "`file'", describe 
            cap import excel using "`file'" ,   ///
            sheet(`r(worksheet_`i')')       ///
            cellrange(`r(range_`i')')      ///   
            `firstrow'  clear          
            import excel using "`file'", describe
            local name=subinstr("`file'--`r(worksheet_`i')'",".xlsx","",.)                 
            if `r(N_worksheet)'==1 | "`r(range_2)'"==""{
                local name=subinstr("`file'",".xlsx","",.) 
            }    
			if "`frame'"!=""{
				cap frame copy default `name'
				if _rc!=0{
					cap frame copy default "songbl_`name'"
				}
			}
			else{
				save "`name'.dta",`replace'				
			}    
            local j=`i'+1
            if "`r(range_`j')'"==""{
                continue, break
            }        
        }  
        n dis "." _c     
        local a=`a'+1  
    }

    
    local files: dir "." file "*.xls", respectcase
    foreach file in `files' {
        cap import excel using "`file'", describe
                if _rc!=0{
                    local e`e'="`file'"
                    local e=`e'+1
                    *erase "`file'"
                    continue           
                }  
        forvalues i = 1/`r(N_worksheet)' {
            
            import excel using "`file'", describe  
            cap import excel using "`file'" ,   ///
            sheet(`r(worksheet_`i')')       ///
            cellrange(`r(range_`i')')      ///   
            `firstrow'  clear

            import excel using "`file'", describe
            local name=subinstr("`file'--`r(worksheet_`i')'",".xls","",.)       
            if `r(N_worksheet)'==1 | "`r(range_2)'"==""{
                local name=subinstr("`file'",".xls","",.) 
            }
			if "`frame'"!=""{
				cap frame copy default `name'	
				if _rc!=0{
					cap frame copy default "songbl_`name'"
				}				
			}	
			else{
				save "`name'.dta",`replace'				
			}
            local j=`i'+1
            if "`r(range_`j')'"==""{
                continue, break
            }        
        }  
        n dis "." _c     
        local a=`a'+1
     
    }

    if `e'!=1{
        n dis "" _n
        local e =`e'-1
        n dis as err "The following `e' sets of data could not be loaded into STATA" 
        forvalues i =1/`e'{
            n dis as err "`e`i''"
        }
    }

}  
	if missing("`frame'"){	
		songbl dir *.dta, max(1)  
	}
end


