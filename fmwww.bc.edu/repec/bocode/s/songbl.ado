*Inspirit of -lianxh-(Yujun, Lian*;Junjie, Kang;Qingqing, Liu) 

* Authors:
* Program written by Bolin, Song (松柏林) Shenzhen University , China.
* Wechat:songbl_stata
* Please do not use this code for commerical purpose

*! Verion: 3.0
*! Update: 2021/1/20 12:32

*! Verion: 4.0
*! Update: 2021/3/16 06:35
*1 增加了 NOCat Mlink  MText Navigation
*2 把论文与推文分开储存，提高搜索速度
*3 增加动态导航功能。


*! Verion: 5.0
*! Update: 2021/3/16 06:35
*1 增加了 SAVE(string) 功能，利用文档打开分享的内容。
*2 增加了 REPLACE 功能，生成分享内容的 STATA 数据集。      
*3 增加了 TIME 功能，输出检索结果的末尾带有返回推文分类目录或者论文分类目录的快捷方式。
*4 更改了分享功能的输出风格。


*Songbl makes it easy for users to search and open thousands of Stata blog posts and useful Stata information in Stata window. You can also browse the papers and replication data & programs etc of China's industrial economy by category.



capture program drop songbl
program define songbl

version 14

syntax [anything(name = class)] ///
	   [,                       ///
		Mlink                   ///   //  - [推文标题](URL)
		MText                   ///   //    [推文标题](URL)
		MUrl		            ///   // n. [推文标题](URL)
		Wlink                   ///   //    推文标题： URL
		WText                   ///   //    推文标题： URL	
		WUrl		            ///   // n. 推文标题： URL		
		NOCat                   ///   //    不呈现推文分类信息 
		Paper                   ///   //    搜索论文。		
		Cls                     ///   //    清屏后显示结果
		Gap                     ///   //    在输出的结果推文之间进行空格一行
		File(string)            ///   //    括号内为文档类型，包括 do 、pdf。
		Type(string)            ///   //    按照推文来源进行检索。
	    Navigation              ///   //    导航功能
		TIme			        ///   //    输出检索结果的末尾带有返回推文分类目录或者论文分类目录的快捷方式	
		SAVE(string)            ///   //    利用文档打开分享的内容。
		REPLACE                 ///   //    生成分享内容的 STATA 数据集。  
        So                      ///   //    网页搜索功能快捷方式	
        Sou(string)             ///   //    网页搜索功能          
	   ]

		tokenize `class'
        

*		
*==============================================================================* 		
*==============================================================================*
*       预先设定option    
      
		* "sou" options识别
        
        
		if "`sou'"!=""{

            *local sou =subinstr("`sou'"," ","",.)
            local class=stritrim("`class'") 
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
                dis as text _col(5)`"  {stata " songbl `class',s(计量圈) "}  或  {stata " songbl `class',s(百度) "}"'  _n                 
                dis as text _col(5)`"  {stata " songbl `class',s(公众号) "}  或  {stata " songbl `class',s(知乎) "}"'  _n
                dis as text _col(5)`"  {stata " songbl `class',s(经管家) "}  或  {stata " songbl `class',s(全部) "}"'  _n
                exit         
            } 
        
        }

        if "`so'"!=""{  
                dis as text
                dis as text _col(5)`"  {stata " songbl `*',s(计量圈) "}  或  {stata " songbl `*',s(百度) "}"'  _n                 
                dis as text _col(5)`"  {stata " songbl `*',s(公众号) "}  或  {stata " songbl `*',s(知乎) "}"'  _n
                dis as text _col(5)`"  {stata " songbl `*',s(经管家) "}  或  {stata " songbl `*',s(全部) "}"'  _n  
            exit    
        }
		
		* "time" options识别  
        if "`time'"!=""{
            timer clear 1
            timer on 1
        }
        
		* "cls" options识别   
		if "`cls'" != ""{
			cls
		}
        
		* "type" options识别  
		if "`class'"!=""  {
    
			if "`type'" == "lianxh" | "`type'" == "lxh" {
				local type1  qui keep if type2==1
				local type3  dis as text " 推文来源 >> 连享会"
			}
    
			if  "`type'" == "sc" {
				local type1  qui keep if type2==6
				local type3  dis as text " 推文来源 >> 爬虫俱乐部"
			}
    
			if  "`type'" == "paper" {
				local type1  qui keep if type2==2 | type2==3
				local type3  dis as text " 推文来源 >> 学术论文"
			}
			
			if "`type'" !="" & "`type'" != "lianxh" & "`type'" != "lxh"  & "`type'" != "sc" & "`type'" != "paper"  {    
				disp as error `"  option type(`type') is error. 请点击{stata  " help songbl"}"'   
				exit
			}
    
		}
		
		* "gap" options识别  		
		if "`gap'" != "" {		 
			local gap dis ""
			local gap1 post  songbl_post  ("" ) 
		}
	


		if ("`replace'"=="") {
			preserve		
		}		
        
 
	
		clear    // 避免变量与用户变量冲突
*		
*==============================================================================* 		
*==============================================================================*
*		动态导航功能设置
		
        * 分类查看所有推文
		if "`class'"=="" {      
			
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "5613B258C5FF441B901CD78CAFAE6D6C?method="
			local http3 "download&shareKey=47627301c0a7cd1e39e2fe0577d1f10c"
			local URL   "`http1'`http2'`http3'"
			
			songbl_links ,url(`URL')
			exit
		}		

		
		* 知网经济学期刊导航
		if "`class'"=="zw"{			            
			
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "466C2230BDBD4820A9851180AFCA64BC?method="
			local http3 "download&shareKey=7cf2334a57eb484a478b5c5feeb3d18a"
			local URL   "`http1'`http2'`http3'"		
			
			songbl_links1 , url(`URL')
			exit
		}	
        
        * 分类查看所有论文
		if "`class'"=="paper"{
			
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "0167308C0D354082998D0152DBD6703E?method="
			local http3 "download&shareKey=872dfb4ae9e8e363e59dc551e8f594be"
			local URL   "`http1'`http2'`http3'"
			
			songbl_links1  ,url(`URL')
			exit
		}	        
		
        * 常用STATA与经济学网站
		if "`class'"=="stata"{
			
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "7636593A108F4D2A8822E7FB559DF6A6?method="
			local http3 "download&shareKey=f4b970a98aa619af543e79ff4856992c"
			local URL   "`http1'`http2'`http3'"	
			
			songbl_links1  , url(`URL')
			exit
		} 
		
        * 常用数据库网站
        if "`class'"=="data"{
        
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "0CEDE9E94A1A48318974261726F9F048?method="
			local http3 "download&shareKey=19fb9b5596d80cb85717cc210d7c9b81"
			local URL   "`http1'`http2'`http3'"				
							
			songbl_links ,url(`URL')
			exit
		} 
        
        * 功能导航
        if "`class'"=="all"{
			
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "324DE307CAB2440CBC67CC318E9CEB45?method="
			local http3 "download&shareKey=bc1dfb9cd7a3cde598aed799d10ec86b"
			local URL   "`http1'`http2'`http3'"		
			
			songbl_links1  , url(`URL')
			exit
		}  
		
        * 科研之余，消遣放松网站
        if "`class'"=="music"{

			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "1E6B86607C214BB79DBDCD957107B208?method="
			local http3 "download&shareKey=fab80cea7b6883d16be1c5b795634d3e"
			local URL   "`http1'`http2'`http3'"	
			
			songbl_links  ,url(`URL')
			exit
		} 
		
		*批量获取导航链接 		
		if "`navigation'"!=""{
			 
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "4DCA13297C1947E6BD85A9A14450B9BB?method="
			local http3 "download&shareKey=2ac33ef51b54f89f15b8c71d252ba716"
			local URL   "`http1'`http2'`http3'"
            local URL1 https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/songbl_URL.txt
			
            cap copy `"`URL1'"' "`html_text'.txt", replace  			
			if _rc ~= 0 {
				cap copy `"`URL'"' "`html_text'.txt", replace  
			}
			local times = 0
			while _rc ~= 0 {
				local times = `times' + 1
				sleep 1000
				cap copy `"`URL'"' "`html_text'.txt", replace
				if `times' > 10 {
					disp as error "Internet speeds is too low to get the data"
					exit 601
				}
			}
			qui infix strL v 1-100000 using "`html_text'.txt", clear
			qui split v,  p("++")       
			cap keep v1 v2 v3	
            local o_class= "`class'"
			local class = lower("`class'")
            qui levelsof v1 , local(v1_type)  clean

            if  strmatch("`r(levels)'","*`class'*")==0{
                dis as error `"  导航格式错误"'  
                dis as error `"  查看导航目录：{stata "songbl all"}"'                 
                exit
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
	
*		
*==============================================================================* 		
*==============================================================================*
*    数据爬取与处理    


	*==============================================================================*
	*       爬取文本数据保存为临时txt文件并导入Stata    
    	
	
    qui{ 

		* 推文链接与标题	
		local http "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/"
		local http1 "http://note.youdao.com/yws/api/personal/file/"
		local http2 "FDF39DDFF4F047678A9C52FE24F2F054?method=download"
		local http3 "&shareKey=5f6386bfc3519af602fd50cebf0ae642"		
	    local stata_paper_youdao    "`http1'`http2'`http3'"
		local stata_paper_tengxun   "`http'stata_paper.txt"
		
		* 论文链接与标题。推文与论文分开放置有利于提高下载速度。		
		local http4 "DC8CC22ADC89489E8380E4C7829D3C74?method=download"
		local http5 "&shareKey=302e182e47b5771a4ffd839e17544cec"
		local paper_youdao   "`http1'`http4'`http5'"		        
		local paper_tengxun  "`http'paper.txt"	
		
		tempfile  html_text  html_text_dta   Share_txt  songbl_post 

		* 推文链接文本下载
		if missing("`paper'"){ 
		
			cap copy `"`stata_paper_tengxun'"' "`html_text'.txt", replace  
			
			if _rc ~= 0 {
				cap copy `"`stata_paper_youdao'"' "`html_text'.txt", replace  
			}

			local times = 0
			while _rc ~= 0 {
				local times = `times' + 1
				sleep 1000
				cap copy `"`stata_paper_youdao'"' "`html_text'.txt", replace
				if `times' > 10 {
					disp as error "Internet speeds is too low to get the data"
					exit 601
				}
			}
       }	

	   						
	    * 论文链接文本下载
		else {      
			
			cap copy `"`paper_tengxun'"' "`html_text'.txt", replace  			
			
			if _rc ~= 0 {
				cap copy `"`paper_youdao'"' "`html_text'.txt", replace  
			}			
			
			local times = 0
			while _rc ~= 0 {
				local times = `times' + 1
				sleep 1000
				cap copy `"`paper_youdao'"' "`html_text'.txt", replace
				if `times' > 10 {
					disp as error "Internet speeds is too low to get the data"
					exit 601
				}
			}
		
		}

		
	    * 导入文本数据到stata
		infix strL v 1-100000 using "`html_text'.txt", clear 
		split v,  p("++")       
		*erase "`html_text'.txt"
		if _rc ~= 0 {
			di as err "Failed to get the data"
			exit 601
		}

	*==============================================================================*
	*       文本数据处理   		
		
		
	    * 变量重命名
		rename  v1  link                //链接    
        rename  v2  title               //标题 
        rename  v3  style               //推文内容分类
        rename  v4  type                //推文来源分类
        rename  v5  seminar_paper       //推文来源分类
        

       * 推文来源分类排序	 
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
        
		
        * 后续检索关键词不区分大小写		
        local 11 = "`1'" 
        local 22 = "`2'"  
        local 33 = "`3'" 
        local 44 = "`4'" 
        local 55 = "`5'" 
        local 1 = strlower("`1'")  
        local 2 = strlower("`2'") 
        local 3 = strlower("`3'") 
        local 4 = strlower("`4'") 
        local 5 = strlower("`5'") 
        gen title1 = lower(title) 
        gen style1 = lower(style)


	    * 关键词"class"识别		
        gen yjy1 = strmatch(title1,"*`1'*") 
        gen yjy2 = strmatch(title1,"*`2'*") 
        gen yjy3 = strmatch(title1,"*`3'*") 
        gen yjy4 = strmatch(title1,"*`4'*") 
        gen yjy5 = strmatch(title1,"*`5'*") 
        gen y1   = strmatch(style1,"*`1'*") 
        gen y2   = strmatch(style1,"*`2'*") 
        gen y3   = strmatch(style1,"*`3'*") 
        gen y4   = strmatch(style1,"*`4'*") 
        gen y5   = strmatch(style1,"*`5'*")
		gen ad   = strmatch(type,"*ad*")
        qui drop if style1=="未分类学术论文"
        qui drop if seminar_paper=="ad"
 	   		
	   `type1'   // 执行 type option
       `type3'
	   
	}

*		
*==============================================================================* 		
*==============================================================================*

	    * 当前日期转为通用年、月、日格式
    local start: disp %dCYND date("`c(current_date)'","DMY")
	local year  = substr("`start'",1,4)
	local month = substr("`start'",5,2)
	local day   = substr("`start'",7,2)
    local cur_time "`year'""年""`month'""月""`day'""日"            
       
        
*  
*==============================================================================*  
*==============================================================================*
*            关键词"class" 搜索
  	
  
		*------------------------------------------------------------------------*
		***输入1个关键词***

	qui{
    
		if "`1'"!="" & "`2'"=="" {    	                  	
					                      
           if "`1'"=="new"{
                
                dingwei title,c(new_songbl)       //定位今日更新推文的行号			
                local nrow=`r(row_n)'+1
                local N=_N 
                qui cap keep in `nrow'/ `N'       //保留今日更新推文的行号 `nrow'/ `N'					 
                local nn=_N                        //今日更新推文共 n 行
            
                if _rc!=0{
                    dis as text _col(4) " `cur_time'没有更新推文 " _n  //今日更新推文行数为0
                    exit
                }
                
                dis as  text _col(4) " `cur_time'更新了`nn'篇推文" _n  //今日更新推文行数不为0
        
            }    
            
            
			if "`1'"!="songbl" & "`1'"!="new"{
				keep if yjy1==1 | y1==1 | ad==1 			 			 
			}			
			
		}	
		
		*------------------------------------------------------------------------*
		***输入2个关键词***    
			
		if "`2'"!="" & "`3'"==""  {    	    
			
			keep if (yjy1==1 | y1==1) & (yjy2==1 | y2==1) | ad==1 
			
		}	

		*------------------------------------------------------------------------*
		***输入3个关键词***	    
			
		if  "`3'"!="" & "`4'"=="" {

			if "`2'"=="-"{	     	  	  
				keep if (yjy1==1 | y1==1) & (yjy3==0 & y3==0)  | ad==1  //第二个关键词为 "-" 
			} 		 	
	
			else if "`2'"=="+"{	     	  	              
				keep if (yjy1==1 | y1==1)  | (yjy3==1 | y3==1) | ad==1  //第二个关键词为 "+"       
			} 	

			else {  
				keep if (yjy1==1 | y1==1) & (yjy2==1 | y2==1) & (yjy3==1 | y3==1) | ad==1 //其余情况
			}    
		
		}

		*------------------------------------------------------------------------*
		***输入4个关键词***	 

		if "`4'"!="" & "`5'"=="" {     
	
			if "`2'"=="+" {     	  	  
				keep if [(yjy1==1 | y1==1 ) | (yjy3==1 | y3==1)] & (yjy4==1 | y4==1) | ad==1  //第二个关键词为 "+"	
			}	

			else if "`2'"=="-" {     	  	  
				keep if (yjy1==1 | y1==1) & (yjy3==0 & y3==0) & (yjy4==1 | y4==1) | ad==1  //第二个关键词为 "-"	  
			}	

			else if "`3'"=="+" {     	  	  
				keep if (yjy1==1 | y1==1) & (yjy2==1 | y2==1) | (yjy4==1 | y4==1) | ad==1 //第三个关键词为 "+"		
			}	

			else if "`3'"=="-" {     	  	  
				keep if (yjy1==1 | y1==1) & (yjy2==1 | y2==1) & (yjy4==0 & y4==0) | ad==1  //第三个关键词为 "-"	
			}	
					
			else {
     
				keep if (yjy1==1 | y1==1) & (yjy2==1 | y2==1) & (yjy3==1 | y3==1) & (yjy4==1 | y4==1) | ad==1  //其余情况

			}    
		}
	    
    }    
		
        if "`5'"!=""{
        
            if strmatch("`class'","*+*")==1 | strmatch("`class'","*-*")==1{
                dis as error `"  "+" 或者 "-" 号，则最多仅能出现一次"' 
            }
            else {
                dis as error `"最多仅支持4个关键词搜索。"'
            }
		    exit 198
            
		}

		qui save "`html_text_dta'", replace	  // 保存关键词 "class" 搜索到的数据
		local n  =_N                  //排除无效数据
		local ad =ad[1]
		local ad2=ad[2]

		
		if _N==0|(_N==1 & `ad'==1 | `ad'==1 )|(_N==2 & `ad'==1 & `ad2' ){
					
			if missing("`paper'"){
				dis as error `"没有搜到{`*'}相关的推文。{stata "songbl": 点击分类查看推文}"' 
			}
			
			else{
				dis as error `"没有搜到{`*'}相关的论文。{stata "songbl paper": 点击分类查看论文}"'
			}	
            cap erase "`html_text'.txt"               
			exit 
		}    

	  
*  
*==============================================================================*  
*==============================================================================*
*          关键词"class" 打印   	


		if  "`wlink'" =="" & "`wtext'"  =="" & "`mlink'" =="" & "`mtext'" =="" & "`murl'" =="" & "`wurl'" =="" {
			qui levelsof seminar_paper , local(seminar_paper) 				
			foreach  seminar_paper  in  `seminar_paper' { 
				use "`html_text_dta'", clear
				qui keep if seminar_paper=="`seminar_paper'"
				qui levelsof style , local(number) 
				foreach  num  in  `number' { 
					qui keep if style=="`num'"
					*local o_num="`num'"					
					*local num=subinstr("`num'"," ","",.)
					local n=_N
					if `n'>0{
						if  strmatch("`num'","*学术论文*") ==1 {
							sort  title 
							if missing("`nocat'"){
								local name = plural(2,"`num'","-学术论文")							
								if missing("`paper'"){ 
									dis as w " 论文 >>"`"{stata "songbl `name'": `name'}"'"
								}
								else{
									dis as w " 论文 >>"`"{stata "songbl `name',paper": `name'}"'"
								}
							}	
						}
						
						else {
							sort type2   title         //  优先打印"连享会"推文
							if missing("`nocat'"){
								dis as w " 专题 >>"`"{stata "songbl `num'": `num'}"'" 
							}
						}    
						
						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']
							if strmatch("`link'","*http*")==1{	
								dis _col(4) `"{browse "`link'": `title'}"'
							}			 				 
							else{
								dis _col(4) `"{stata "`link'": `title'}"'
							}															
							if "`file'"!="" & strmatch("`title'", "*.`file'")==1  {
								gitee "`link'",cla(`file')
							}     
                            
							`gap'
						}
					}
					use "`html_text_dta'", clear
					if missing("`nocat'"){
                        dis ""
					}
				}
			
			}	
			
			if "`save'"!="" {
				dis as error `" 命令格式有误，see { stata  " help songbl_cn" }"'
				dis as error `" Note:save 选择项必须与 wlink 、wtext 、mlink 、mtext、murl、wurl 等分享功能一起使用  "'
				exit 198	
			}		
		
		}	
		
		else {	
		
			capture postclose songbl_post
			qui postfile songbl_post str1000 Share using "`songbl_post'", replace		
		       
            if "`class'"=="new"{
                local cur_time "`year'年`month'月`day'日"
                post songbl_post  (`"# **`cur_time' 更新了`nn'篇 STATA 推文** "') 
            }   
               
			if "`wlink'" !=""{		
				dis ""	
				dis as txt _n "{hline 24} wlink文本格式 {hline 24}"	
				post songbl_post  ("------------------------ wink文本格式 ------------------------") 
				dis as txt	
				post songbl_post  (" ") 
				if missing("`paper'"){
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 STATA 窗口输入代码：songbl `class'"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 STATA 窗口输入代码：songbl `class'") 
				}
				else {
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 STATA 窗口输入代码：songbl `class',paper"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 STATA 窗口输入代码：songbl `class',paper") 
				}			
				dis as txt	
				post songbl_post  (" ") 
				qui levelsof seminar_paper , local(seminar_paper) 	
				local m=_N			
				foreach  seminar_paper  in  `seminar_paper' { 
					use "`html_text_dta'", clear
					qui keep if seminar_paper=="`seminar_paper'"
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
						qui keep if style=="`num'"
						local n=_N
						if `n'>0{
							if  strmatch("`num'","*学术论文*") ==1 {
								sort title
								if missing("`nocat'"){							
									local name = plural(2,"`num'","-学术论文")
									if missing("`paper'"){ 							
										dis as w _col(4) " 论文 >>"`"{stata "songbl `name'": `name'}"'"
										post songbl_post  ("    论文 >> `name'")							
										`gap' 
										`gap1'
									}
									else{
										dis as w _col(4) " 论文 >>"`"{stata "songbl `name',paper": `name'}"'"
										post songbl_post  ("    论文 >> `name'")
										`gap'
										`gap1'
									}
								}	
							}
							else {
								sort type2   title
								if missing("`nocat'"){							
									dis as w _col(4) " 专题 >>"`"{stata "songbl `num'": `num'}"'" 							
									`gap' 
									`gap1'
									post songbl_post  ("    专题 >> `num'" ) 
																
								}
							}         
							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']	
								dis as y "`title': `link'"
								post songbl_post ("`title': `link'") 
								`gap'
								`gap1'
							}
						}
					use "`html_text_dta'", clear
						if missing("`nocat'"){
							dis ""
							post songbl_post  (" " ) 
						}        
					}
				}	
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"			
				if `m'>=10{
					dis in red  _n "小提示：建议分多次复制到微信对话框，每次 10 行，否则超链接无法生效"
                    dis in red   "        分享长链接直接复制会断行。建议使用 save(txt) 或者 replace 选项，利用 TXT 文档 or STATA 打开"                   
				}
                else{
                    dis in red  _n "小提示：分享长链接直接复制会断行。建议使用 save(txt) 或者 replace 选项，利用 TXT 文档 or STATA 打开"                
               }
			}
			
			if "`wtext'" !=""{		
				dis ""	
				dis as txt _n "{hline 24} wtxt文本格式 {hline 24}"	
				post songbl_post  ("------------------------ wtxt文本格式 ------------------------") 
				dis as txt	
				post songbl_post  (" ") 			
				if missing("`paper'"){
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 STATA 窗口输入代码：songbl `class'"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 STATA 窗口输入代码：songbl `class'")  
				}
				else {
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 STATA 窗口输入代码：songbl `class',paper"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 STATA 窗口输入代码：songbl `class',paper") 
				}		
				dis as txt	
				post songbl_post  (" ") 		
				qui levelsof seminar_paper , local(seminar_paper) 	
				local m=_N			
				foreach  seminar_paper  in  `seminar_paper' { 
					use "`html_text_dta'", clear
					qui keep if seminar_paper=="`seminar_paper'"
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
						qui keep if style=="`num'"
						local n=_N
						if `n'>0{
							if  strmatch("`num'","*学术论文*") ==1 {
								sort title
								if missing("`nocat'"){
									local name = plural(2,"`num'","-学术论文")
									if missing("`paper'"){ 
										dis as w _col(4) " 论文 >>"`"{stata "songbl `name'": `name'}"'"
										post songbl_post  ("    论文 >> `name'")										
										`gap' 									
									}
									else{
										dis as w _col(4) " 论文 >>"`"{stata "songbl `name',paper": `name'}"'"
										post songbl_post  ("    论文 >> `name'")										
										`gap'
										`gap1'
									}
								}	
							}
							else {
								sort type2   title
								if missing("`nocat'"){
									dis as w _col(4) " 专题 >>"`"{stata "songbl `num'": `num'}"'" 						
									post songbl_post  ("    专题 >> `num'" ) 								
									`gap'
									`gap1'
								}	
							}     					
							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']						
								dis  as y "`title'"
								dis  as y "`link'"
								post songbl_post  ("`title'") 
								post songbl_post  ("`link'") 							
								`gap'
								`gap1'
							}
						}
					use "`html_text_dta'", clear
						if missing("`nocat'"){
							post songbl_post  (" " ) 					
							dis ""
						}         
					}
				}	
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"
				if `m'>=10{
					dis in red  _n "小提示：建议分多次复制到微信对话框，每次 10 行，否则超链接无法生效"
                    dis in red   "        分享长链接直接复制会断行。建议使用 save(txt) 或者 replace 选项，利用 TXT 文档 or STATA 打开"                   
				}
                else{
                    dis in red  _n "小提示：分享长链接直接复制会断行。建议使用 save(txt) 或者 replace 选项，利用 TXT 文档 or STATA 打开"                
               }
			}		
			
			if "`wurl'" !=""{
				dis ""	
				dis as txt _n "{hline 24} wurl文本格式 {hline 24}"	
				post songbl_post  ("------------------------ wurl文本格式 ------------------------") 
				dis as txt	
				post songbl_post  (" ") 			
				if missing("`paper'"){
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 STATA 窗口输入代码：songbl `class'"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 STATA 窗口输入代码：songbl `class'") 
				}
				else {
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 STATA 窗口输入代码：songbl `class',paper"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 STATA 窗口输入代码：songbl `class',paper") 
				}		
				dis as txt	
				post songbl_post  (" ") 		
				qui levelsof seminar_paper , local(seminar_paper) 	
				local m=_N
				foreach  seminar_paper  in  `seminar_paper' { 
					use "`html_text_dta'", clear
					qui keep if seminar_paper=="`seminar_paper'"
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
						qui keep if style=="`num'"
						local n=_N
						if `n'>0{
							if  strmatch("`num'","*学术论文*") ==1 {
								sort title
								if missing("`nocat'"){
									local name = plural(2,"`num'","-学术论文")
									if missing("`paper'"){ 
										dis as w _col(4) " 论文 >>"`"{stata "songbl `name'": `name'}"'"
										post songbl_post  ("    论文 >> `name'")									
										`gap'
										`gap1'
									}
									else{
										dis as w _col(4) " 论文 >>"`"{stata "songbl `name',paper": `name'}"'"
										post songbl_post  ("    论文 >> `name'")									
										`gap'
										`gap1'
									}
							   }
							}
							else {
								sort type2   title 
								if missing("`nocat'"){
									dis as w _col(4) " 专题 >>"`"{stata "songbl `num'": `num'}"'" 
									post songbl_post  ("    专题 >> `num'" ) 							
									`gap' 
									`gap1'
								}	
							}      

							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']							
								if `n'==1{
									dis as y "`title': `link'"
									post songbl_post  ("`title': `link'") 								
								}
								else {
									dis as y "`i'. `title': `link'"
									post songbl_post  ("`i'. `title': `link'") 
								}							
								`gap'
								`gap1'
							}
						}
					use "`html_text_dta'", clear
						if missing("`nocat'"){
							post songbl_post  (" " ) 					
							dis ""
						}         
					}
				}	
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
				if `m'>=10{
					dis in red  _n "小提示：建议分多次复制到微信对话框，每次 10 行，否则超链接无法生效"
                    dis in red   "        分享长链接直接复制会断行。建议使用 save(txt) 或者 replace 选项，利用 TXT 文档 or STATA 打开"                   
				}
                else{
                    dis in red  _n "小提示：分享长链接直接复制会断行。建议使用 save(txt) 或者 replace 选项，利用 TXT 文档 or STATA 打开"                
               }
			}		
						
			if "`mlink'" !=""{
				dis ""	
				dis as txt _n "{hline 24} mlik文本格式 {hline 24}"	
				post songbl_post  ("~~------------------------ mlink文本格式 ------------------------~~") 
				dis as txt	
				post songbl_post  (" ") 			
				if missing("`paper'"){
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 STATA 窗口输入代码：**songbl `class'**"
                    post songbl_post  ("> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**") 
					post songbl_post  ("> 查看更多内容请在 STATA 窗口输入代码：**songbl `class'**") 
				}
				else {
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 STATA 窗口输入代码：**songbl `class',paper**"
                    post songbl_post  ("> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**") 
					post songbl_post  ("> 查看更多内容请在 STATA 窗口输入代码：**songbl `class',paper**") 
				}		
				post songbl_post  ("---") 
				dis as txt "---"				
				qui levelsof seminar_paper , local(seminar_paper) 		
				foreach  seminar_paper  in  `seminar_paper' { 
					use "`html_text_dta'", clear
					qui keep if seminar_paper=="`seminar_paper'"
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
						qui keep if style=="`num'"
						local n=_N
						if `n'>0{
							if  strmatch("`num'","*学术论文*") ==1 {
								sort title
								if missing("`nocat'"){
									local name = plural(2,"`num'","-学术论文")
									if missing("`paper'"){ 
										dis as w _col(4) "### 论文 >>"`"{stata "songbl `name'": `name'}"'"
										post songbl_post  ("### 论文 >> `name'")									
										`gap' 	
										`gap1'
									}
									else{
										dis as w _col(4) "### 论文 >>"`"{stata "songbl `name',paper": `name'}"'"
										post songbl_post  ("### 论文 >> `name'")									
										`gap' 
										`gap1'
									}
								}	
							}
							else {
								sort type2   title
								if missing("`nocat'"){
									dis as w _col(4) "### 专题 >>"`"{stata "songbl `num'": `num'}"'" 
									post songbl_post  ("### 专题 >> `num'" ) 							
									`gap' 
									`gap1'
								}	
							}   
							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']						
								dis as y "- [`title'](`link')"
								post songbl_post  ("- [`title'](`link')") 							
								`gap'
								`gap1'
							}
						}
					use "`html_text_dta'", clear
						if missing("`nocat'"){
							post songbl_post  (" " ) 					
							dis ""
						}         
					}
				}	
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"		
				dis in red _n "小提示：分享长链接直接复制会断行。建议使用 save(txt) 或者 replace 选项，利用 TXT 文档 or STATA 打开"
			}

			if "`mtext'" !=""{
				dis ""	
				dis as txt _n "{hline 24} mtext文本格式 {hline 24}"	
				post songbl_post  ("~~------------------------ mtext文本格式 ------------------------~~") 
				dis as txt	
				post songbl_post  (" ") 			
				if missing("`paper'"){
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 STATA 窗口输入代码：**songbl `class'**"
                    post songbl_post  ("> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**") 
					post songbl_post  ("> 查看更多内容请在 STATA 窗口输入代码：**songbl `class'**") 
				}
				else {
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 STATA 窗口输入代码：**songbl `class',paper**"
                    post songbl_post  ("> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**") 
					post songbl_post  ("> 查看更多内容请在 STATA 窗口输入代码：**songbl `class',paper**") 
				}	
				dis as txt "---"	
				post songbl_post  ("---") 			
				qui levelsof seminar_paper , local(seminar_paper) 
				foreach  seminar_paper  in  `seminar_paper' { 
					use "`html_text_dta'", clear
					qui keep if seminar_paper=="`seminar_paper'"
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
						qui keep if style=="`num'"
						local n=_N
						if `n'>0{
							if  strmatch("`num'","*学术论文*") ==1 {
								sort title
								if missing("`nocat'"){
									local name = plural(2,"`num'","-学术论文")
									if missing("`paper'"){ 
										dis as w _col(4) "### 论文 >>"`"{stata "songbl `name'": `name'}"'"
										post songbl_post  ("### 论文 >> `name'")									
										`gap'
										`gap1'
									}
									else{
										dis as w _col(4) "### 论文 >>"`"{stata "songbl `name',paper": `name'}"'"
										post songbl_post  ("### 论文 >> `name'")									
										`gap'
										`gap1'
									}
								}	
							}
							else {
								sort type2   title
								if missing("`nocat'"){
									dis as w _col(4) "### 专题 >>"`"{stata "songbl `num'": `num'}"'" 
									post songbl_post  ("### 专题 >> `num'" ) 							
									`gap' 
									`gap1'
								}	
								
							}     
							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']								
								dis as y "[`title'](`link')"
								post songbl_post  ("[`title'](`link')") 							
								`gap'
								`gap1'
							}
						}
					use "`html_text_dta'", clear
						if missing("`nocat'"){
							post songbl_post  (" " ) 					
							dis ""
						}          
					}
				}	
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
				dis in red  _n "小提示：分享长链接直接复制会断行。建议使用 save(txt) 或者 replace 选项，利用 TXT 文档 or STATA 打开"
			}		
			
			if "`murl'" !=""{
				dis ""	
				dis as txt _n "{hline 24} murl文本格式 {hline 24}"	
				post songbl_post  ("~~------------------------ murl文本格式 ------------------------~~") 
				dis as txt	
				post songbl_post  (" ") 			
				if missing("`paper'"){
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 STATA 窗口输入代码：**songbl `class'**"
                    post songbl_post  ("> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**") 
					post songbl_post  ("> 查看更多内容请在 STATA 窗口输入代码：**songbl `class'**") 
				}
				else {
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 STATA 窗口输入代码：**songbl `class',paper**"
                    post songbl_post  ("> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**") 
					post songbl_post  ("> 查看更多内容请在 STATA 窗口输入代码：**songbl `class',paper**") 
				}	
				dis as txt "---"	
				post songbl_post  ("---") 				
				qui levelsof seminar_paper , local(seminar_paper) 
				foreach  seminar_paper  in  `seminar_paper' { 
					use "`html_text_dta'", clear
					qui keep if seminar_paper=="`seminar_paper'"
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
						qui keep if style=="`num'"
						local n=_N
						if `n'>0{
							if  strmatch("`num'","*学术论文*") ==1 {
								sort title
								if missing("`nocat'"){
									local name = plural(2,"`num'","-学术论文")
									if missing("`paper'"){ 
										dis as w _col(4) "### 论文 >>"`"{stata "songbl `name'": `name'}"'"
										post songbl_post  ("### 论文 >> `name'")								
										`gap'
										`gap1'
									}
									else{
										dis as w _col(4) "### 论文 >>"`"{stata "songbl `name',paper": `name'}"'"
										post songbl_post  ("### 论文 >> `name'")									
										`gap'
										`gap1'
									}
								}	
							}
							else {
								sort type2   title
								if missing("`nocat'"){
									dis as w _col(4) "### 专题 >>"`"{stata "songbl `num'": `num'}"'" 
									post songbl_post  ("### 专题 >> `num'" ) 							
									`gap' 
									`gap1'
								}
							}    
							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']							
								if `n'==1{
									dis ""
									dis as y "[`title'](`link')"								
									post songbl_post  ("") 
									post songbl_post  ("[`title'](`link')") 	
									
								}
								else {
									dis as y "`i'. [`title'](`link')"
									post songbl_post  ("`i'. [`title'](`link')") 	
								}							
								`gap'
								`gap1'
							}
						}
					use "`html_text_dta'", clear
						if missing("`nocat'"){
							post songbl_post  (" " ) 					
							dis ""
						}           
					}
				}	
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
				dis in red  _n "小提示：分享长链接直接复制会断行。建议使用 save(txt) 或者 replace 选项，利用 TXT 文档 or STATA 打开"
			}		
			
			postclose songbl_post
			use "`songbl_post'", clear
			cap format %-200s Share          
		}	
		
			
		if ("`replace'"!="") {
			qui cap keep  link title style type seminar_paper
            qui cap label variable link "链接"
            qui cap label variable title "标题"
            qui cap label variable style "分类"
            qui cap label variable type "来源"
            qui cap label variable seminar_paper "论文 or 推文"           
			browse
		}			
							
		if ("`save'"!="") {	         
			qui export delimited Share using "`Share_txt'.`save'" , ///
			novar nolabel delimiter(tab) replace				
			view browse  "`Share_txt'.`save'"	
            
		}	

	
		if "`time'"!=""{
			timer off 1
			qui timer list 1
			local timer =strofreal(`r(t1)',"%9.3f")
			local cur_time "`year'年`month'月`day'日"
			if "`paper'"==""{
				dis as txt
				dis as  res  _col(4) `"{stata "songbl ":【快捷查看分类推文】}"'
				dis as  res  _col(4) `"搜索共耗时 `timer' 秒"'
				dis as  res  _col(4) `"目前北京时间：`cur_time' `c(current_time)' "'
			}	
					
			else{ 
				dis as txt
				dis as res  _col(4) `"{stata "songbl paper"【快捷查看分类论文】}"'
				dis as res  _col(4) `"搜索共耗时 `timer' 秒"'
				dis as res  _col(4) `"目前北京时间：`cur_time' `c(current_time)' "'
			}
												
		}	
        
        cap erase "`html_text'.txt"   
        
		if ("`replace'"=="") {	

			restore           
		}

end

*==============================================================================*	
****Sub programs****
*==============================================================================*	

capture program drop dingwei
program define dingwei , rclass
version 10.0
syntax anything  (name = varname ) [,C(string) D] 
qui{
        tempvar new_varname  row row_n row_varname
        egen `new_varname' = concat(`varname') 
        local varname  `new_varname'    
        if missing("`d'") {  
            gen `row'=1 if index(`varname',"`c'")
        }
        else{
            gen `row'=1  if strmatch(`varname',"`c'")
        }  
        gen `row_n'=_n
        tempfile mas 
        qui save "`mas'"
        keep if `row'==1
        local j =_N
        levelsof  `row_n'       ,  local(number)
        return local N            `j' 
        return local row_n        `number'        
}         
        use "`mas'", clear
end

*==============================================================================*	
****Sub programs****
*==============================================================================*	

cap program drop gitee
program define gitee
version 14
syntax anything( name = git)  ,Cla(string) 
if "`cla'"=="do"{
	local URL `"`git'"'
	tempfile  html_text   
	copy   `URL' "`html_text'.`cla'", replace  
	doedit "`html_text'.`cla'"
}

foreach i in  pdf txt docx md .xls .xlsx{
	if "`cla'"=="`i'"{
		local URL `"`git'"'
		tempfile  html_text   
		copy `URL'   "`html_text'.`cla'", replace  
		view browse  "`html_text'.`cla'"
	}
}

cap erase "`html_text'.txt"  
end

*==============================================================================*	
****Sub programs****    // 借鉴 lianxh_links
*==============================================================================*
cap program drop songbl_links
program define songbl_links

version 8

syntax [anything] [,URL(string)]    
	 
	qui{
        preserve
        clear
                    					     
		tempfile  html_text    		

        cap copy `"`url'"' "`html_text'.txt", replace  			 			
        local times = 0
        while _rc ~= 0 {
            local times = `times' + 1
            sleep 1000
            cap copy `"`URL'"' "`html_text'.txt", replace
            if `times' > 10 {
                disp as error "Internet speeds is too low to get the data"
                exit 601
                }
        }
        infix strL v 1-100000 using "`html_text'.txt", clear
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
				if strmatch("`b`k`i'''","*http*")==1{	
					local browse_stata`i' browse
				}			 				 
				else{
					local browse_stata`i' stata
				}				 
			}
			 
			dis in w " `c`m'': "                                        ///
				_col(`c1') `"{`browse_stata1' "`b`k1''":`a`k1''}"'       ///
				_col(`c2') `"{`browse_stata2' "`b`k2''":`a`k2''}"'       ///
				_col(`c3') `"{`browse_stata3' "`b`k3''":`a`k3''}"'       

			dis in w  _col(`number3')                                    ///			 		 
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
			if strmatch("`b`a_n`i'''","*http*")==1{	
				local browse_stata`i' browse
			}			 				 
			else{
				local browse_stata`i' stata
			}				 
		}		 
		 
	
		if `mod'==1{
		     dis in w " `c`m'': "                                      ///
				_col(`c1') `"{`browse_stata1' "`b`a_n1''":`a`a_n1''}"'   
		}

		if `mod'==2{
		     dis in w " `c`m'': "                                       ///
				_col(`c1') `"{`browse_stata1' "`b`a_n1''":`a`a_n1''}"'   ///   
				_col(`c2') `"{`browse_stata2' "`b`a_n2''":`a`a_n2''}"'   
		}
		 
		if `mod'==3{
		     dis in w " `c`m'': "                                       ///
				_col(`c1') `"{`browse_stata1' "`b`a_n1''":`a`a_n1''}"'   /// 
				_col(`c2') `"{`browse_stata2' "`b`a_n2''":`a`a_n2''}"'   /// 
				_col(`c3') `"{`browse_stata3' "`b`a_n3''":`a`a_n3''}"'	 
		}
		 
		if `mod'==4{
		     dis in w " `c`m'': "                                       ///
				_col(`c1') `"{`browse_stata1' "`b`a_n1''":`a`a_n1''}"'   ///  
				_col(`c2') `"{`browse_stata2' "`b`a_n2''":`a`a_n2''}"'   /// 
				_col(`c3') `"{`browse_stata3' "`b`a_n3''":`a`a_n3''}"' 
			 dis in w  _col(`number3')                                  ///	
				_col(`c1') `"{`browse_stata4' "`b`a_n4''":`a`a_n4''}"'
		}
		 
		if `mod'==5{
		     dis in w " `c`m'': "                                        ///
				_col(`c1') `"{`browse_stata1' "`b`a_n1''":`a`a_n1''}"'    ///  
				_col(`c2') `"{`browse_stata2' "`b`a_n2''":`a`a_n2''}"'    /// 
				_col(`c3') `"{`browse_stata3' "`b`a_n3''":`a`a_n3''}"' 
			 dis in w  _col(`number3')                                   ///	
				_col(`c1') `"{`browse_stata4' "`b`a_n4''":`a`a_n4''}"'    ///
				_col(`c2') `"{`browse_stata5' "`b`a_n5''":`a`a_n5''}"'  
		}	
         cap erase "`html_text'.txt"              
	     restore
         

end


cap program drop songbl_links1
program define songbl_links1
version 8
syntax [anything][,URL(string)]                       ///

	qui{
        preserve
        clear  
		
        tempfile  html_text 
        cap copy `"`url'"' "`html_text'.txt", replace  			
        local times = 0
        while _rc ~= 0 {
            local times = `times' + 1
            sleep 1000
            cap copy `"`url'"' "`html_text'.txt", replace
            if `times' > 10 {
                disp as error "Internet speeds is too low to get the data"
                exit 601
                }
        }
            infix strL v 1-100000 using "`html_text'.txt", clear
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
			 
			if strmatch("`b`k1''","*http*")==1{
				dis in w  _col(`c1') `"{browse "`b`k1''":`a`k1''}"' _continue
			}
			
			else{
				dis in w  _col(`c1') `"{stata  "`b`k1''":`a`k1''}"'  _continue
			}			
			
			if strmatch("`b`k2''","*http*")==1{
				dis in w  _col(`c2') `"{browse "`b`k2''":`a`k2''}"' _continue
			}
			
			else{
				dis in w  _col(`c2') `"{stata  "`b`k2''":`a`k2''}"'  _continue
			}			
			
			if strmatch("`b`k3''","*http*")==1{
				dis in w  _col(`c3') `"{browse "`b`k3''":`a`k3''}"' _n
			}
			
			else{
				dis in w  _col(`c3') `"{stata  "`b`k3''":`a`k3''}"'  _n
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
			if strmatch("`b`k1''","*http*")==1{
				dis in w  _col(`c1') `"{browse "`b`a_n1''":`a`a_n1''}"'  
		}
			
			else{
				dis in w  _col(`c1') `"{stata "`b`a_n1''":`a`a_n1''}"'  
			}			 
			     
		 }
		 
		if `mod'==2{
		     
			if strmatch("`b`k1''","*http*")==1{
				dis in w  _col(`c1') `"{browse "`b`a_n1''":`a`a_n1''}"' _continue 
			}
			
			else {
				dis in w  _col(`c1') `"{stata "`b`a_n1''":`a`a_n1''}"'  _continue
			}				 
			 
			if strmatch("`b`k1''","*http*")==1{
				dis in w  _col(`c2') `"{browse "`b`a_n2''":`a`a_n2''}"'  
			}
			
			else{
				dis in w  _col(`c2') `"{stata "`b`a_n2''":`a`a_n2''}"'  
			}				   
		}
    cap erase "`html_text'.txt"    
	restore

end

