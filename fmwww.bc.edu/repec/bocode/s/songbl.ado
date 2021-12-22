*Inspirit of -lianxh-(Yujun, Lian*;Junjie, Kang;Qingqing, Liu) 

* Authors:
* Program written by Bolin, Song (松柏林) Shenzhen University , China.
* Wechat:songbl_stata
* Please do not use this code for commerical purpose


*Songbl makes it easy for users to search and open thousands of Stata blog posts and useful Stata information in Stata window. You can also browse the papers and replication data & programs etc of China's industrial economy by category.


capture program drop songbl
program define songbl

version 14

syntax [anything(name = class)] 				  ///
	   [,                       				  ///
		Mlink                   				  ///   //  - [推文标题](URL)
		MText                   				  ///   //    [推文标题](URL)
		MUrl		            				  ///   // n. [推文标题](URL)
		Wlink                   				  ///   //    推文标题： URL
		WText                   				  ///   //    推文标题： URL	
		WUrl		            				  ///   // n. 推文标题： URL		
		NOCat                   				  ///   //    不呈现推文分类信息 
		Paper                   				  ///   //    搜索论文。		
		Cls                     				  ///   //    清屏后显示结果
		Gap                     				  ///   //    在输出的结果推文之间进行空格一行
		File(string)            				  ///   //    括号内为文档类型，包括 do 、pdf。
		AUTHor(string)          				  ///   //    按照推文来源进行检索。
	    Navigation              				  ///   //    导航功能
		TIme			        				  ///   //    输出检索结果的末尾带有返回推文分类目录或者论文分类目录的快捷方式	
		SAVE(string)           					  ///   //    利用文档打开分享的内容。
		REPLACE                 				  ///   //    生成分享内容的 STATA 数据集。  
        So                      				  ///   //    网页搜索功能快捷方式	
        Sou(string)             				  ///   //    网页搜索功能    
		Num(numlist  integer max=1 min=1 >0 )     ///   //	  指定要列出的最新推文的数量；N(10)是默认值。与 songbl new 搭配使用
		Line                    				  ///   //    搜索推文的另一种输出风格，具有划线
        SSC                     				  ///	//	  检索外部命令介绍
        SSCI                     				  ///	//	  检索外部命令介绍		
		CLIP                    				  ///   //	  点击剪切分享，与 Wlink 搭配使用
		FY                      				  ///   //    谷歌翻译命令 Help 文档
		DIR                      				  ///   //    搜索电脑文件
		Forum                                     ///   //    检索论坛帖子
		POST(numlist  integer max=1 min=1 >0 <11) ///	//    打印论坛帖子页数
		MAXdeep(numlist  integer max=1 min=1 >0 ) ///	//    检索文件夹层次
		CIE                                       ///   //    检索代码		
	   ] 
	   

        

*		
*==============================================================================* 		
*==============================================================================*
		
		cap local class=stritrim(`"`class'"') 
		if _rc!=0{
			local class=stritrim("`class'") 	
		}
		tokenize `class'		
		
		* "cls" options识别   
		if "`cls'" != ""{
			cls
            dis ""
		}	

        if "`class'"=="help" {
				view browse https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.html
				exit
		}		
				
        if "`class'"=="cie" | "`class'"=="sj" | "`class'"=="论文重现"| "`class'"=="fy"{
				local  navigation navigation
		}		
				
		
		if strmatch("`class'","*+*")==1 & strmatch("`class'","*-*")==1{
			dis as error `"  "+" 或者 "-" 号不能同时选择"' 
			exit 198
		}		
		
		
        if "`paper'"!="" & "`class'"=="new" {		
			dis as error `"暂时无法查看最新的论文资源"'   				
            exit 198
        }	

        if "`paper'"!="" & "`ssc'"!="" {
            dis as error `"不能同时选定 paper 与 ssc "'    
            exit 198
        }
		
        if "`paper'"!="" & "`forum'"!="" {
            dis as error `"不能同时选定 paper 与 forum "'    
            exit 198
        }
		
        if "`ssc'"!="" & "`forum'"!="" {
            dis as error `"不能同时选定 ssc 与 forum "'    
            exit 198
        }
		
        if "`ssc'"!="" & "`ssci'"!="" {
            dis as error `"不能同时选定 ssc 与 ssci "'    
            exit 198
        }		
		
        if "`paper'"!="" & "`ssci'"!="" {
            dis as error `"不能同时选定 paper 与 ssci "'    
            exit 198
        }			
	
        if "`forum'"!="" & "`ssci'"!="" {
            dis as error `"不能同时选定 forum 与 ssci "'    
            exit 198
        }		
	
        if "`ssc'"!="" & ("`wlink'"!="" | "`wtext'"!="" | "`mlink'"!=""   ///   
       |"`mtext'"!="" | "`murl'"!="" | "`wurl'"!="" ) {
            dis as error `"检索ssc外部命令时, 不能使用分享功能"'    
            exit 198
        }

        if "`ssci'"!="" & ("`wlink'"!="" | "`wtext'"!="" | "`mlink'"!=""   ///   
       |"`mtext'"!="" | "`murl'"!="" | "`wurl'"!="" ) {
            dis as error `"ssci不能使用分享功能"'    
            exit 198
        }		
 

 		* "gap" options识别 				
 		
		if "`dir'"!=""  {  
			
			cap which filelist
			if _rc!=0{
				disp as text "欢迎加入300人的Stata微信交流群：" `"{browse "https://note.youdao.com/ynoteshare1/index.html?id=720635d3824de83e0e764a60eb34e54c&type=note":{bf:songbl_stata}}"' _n
			    
				disp as error "需要先安装" " {bf:filelist} 命令,请点击安装："  
				disp as error "         {stata ssc install filelist:ssc install filelist} " 

				exit	
			}			
			if  "`class'"!=""{
				local pattern ="pattern(`class')" 
			}   
			if  "`maxdeep'"!=""{
				local maxdeep ="maxdeep(`maxdeep')" 
			} 
			
			songbl_dir,`gap' `pattern' `line' `nocat' `maxdeep'
			exit
		}  
		
       
	   if "`forum'"!="" {
	       if "`class'"==""{
				sblsf,c `gap' `line' `mlink'  `wlink'   
				exit
		   }
	       if  "`class'"=="new"{
				sblsf, `gap' `line' `mlink'  `wlink' 
				exit
		   }		   
        }		
	
		if "`gap'" != "" {		 
			local gap dis ""
			local gap1 post  songbl_post  ("" ) 
		} 
		
		* "cls" options识别   
		if "`fy'" != ""{
			fy `class'
			exit
		}			
		
		* "sou" options识别        
		if "`sou'"!=""{

            *local sou =subinstr("`sou'"," ","",.)            
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
        exit 
        }

		* "time" options识别  
        if "`time'"!=""{
            timer clear 1
            timer on 1
        }
        
        
        if "`1'"=="install" & "`3'"==""  {    	    
			sbl `2'
            exit  			
		}	        
        		
		if "`class'"=="fy1"  {	
			view browse "https://www.deepl.com/translator"
			exit
		}	
	
        if "`class'"=="care"  {
            
            preserve
            tempfile  html_text 
            local url https://note.youdao.com/yws/api/personal/file/2EC4F4F4D1734665B7E269842F48D42F   ///
					  ?method=download&shareKey=5531c4b5e748def50424abb57f1dd159
    
        qui{
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
            drop if v==""
            local n = _N
            loc n = runiformint(1, `n')
            n dis "" _n
            local dis =v[`n']
            noi di _col(7) "`dis'"	
        }    
            exit
            restore
        }	        
					

		
		
		
		
		if "`class'"=="music"  {
            
			cap which imusic
			if _rc!=0{
				disp as error "需要先安装" " {bf:imusic} 命令,请点击安装："  
				disp as error "         {stata ssc install imusic:ssc install imusic} " 
				exit	
			}
            preserve
            tempfile  html_text 
            local url https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/music/music.txt 
					 
    
        qui{
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
            drop if v==""
            local n = _N
            loc n = runiformint(1, `n')
            n dis ""

            local dis =v[`n']
            n imusic `dis'	
			n dis as error _col(4) "{stata songbl music list:{bf:View all song lists from songbl}}"
        }    
            exit
            restore
        }	 
		
        if  "`1'"=="music" & "`2'"=="list" & "`3'"==""  {
            
            preserve
            tempfile  html_text 
            local url https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/music/music.txt 
					 
    
        qui{
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
            drop if v==""
			local n = _N
			forvalues i = 1/`n'{
				local url=v[`i']
					n dis _col(4) `"{stata "imusic `url'":`url'}"'  
			}
		n dis ""
		n dis as error _col(4) "{bf:松柏林网易云音乐:}"  ///
		`"{browse "https://music.163.com/#/user/home?id=1183627":https://music.163.com/#/user/home?id=1183627}"'	
        }    
            exit
            restore
        }			
	
        if  "`1'"=="text" & "`2'"!="" & "`3'"==""  {
            
            preserve
            tempfile  html_text 
            local url https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/txt/text.txt
			cap copy `"`url'"' `"`html_text'.txt"', replace 
			qui infix strL v 1-100000 using `"`html_text'.txt"', clear	
			local url=v[`2']
			local n =_N
			if `2'>`n'{
			disp as error "没有发现文本内容"
                exit 601			    
			}
        qui{
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
			gen len = strlen(v)
			sum len
			local col =`r(max)'/4
			local col= round(`col')
			local title=v[1]
			n dis   as  txt  _col(`col') `"{bf:`title'}"'	
			*n dis as txt "{hline}"
			local n = _N
			forvalues i = 2/`n'{
				local text=v[`i']
					n dis  as txt  `"`text'"'  
			}
		}	
		
		*n dis as txt "{hline}"
            exit
            restore
        }				
	
		if ("`replace'"=="") {
			preserve		
		}		
        
		clear    // 避免变量与用户变量冲突

	 
*		songbl sgmediation,cie   save(txt)
*==============================================================================* 		
*==============================================================================*
*		动态导航功能设置
		
        * 分类查看所有推文
		if "`class'"=="" {      
			tempfile  html_text
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "5613B258C5FF441B901CD78CAFAE6D6C?method="
			local http3 "download&shareKey=47627301c0a7cd1e39e2fe0577d1f10c"
			local URL1   "`http1'`http2'`http3'"
			local URL https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/navigation/songbl.txt			        	
			cap copy `"`URL'"' `"`html_text'.txt"', replace
			if _rc ~= 0 {
				local URL `URL1'
			}			
			songbl_links ,url(`URL')
            cap erase `"`html_text'.txt"'  
			exit
		}		

		* 知网经济学期刊导航
		if "`class'"=="zw"{			            
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "466C2230BDBD4820A9851180AFCA64BC?method="
			local http3 "download&shareKey=7cf2334a57eb484a478b5c5feeb3d18a"
			local URL   "`http1'`http2'`http3'"		
			songbl_links1 , url(`URL')
            cap erase `"`html_text'.txt"'              
			exit
		}	
        
        * 分类查看所有论文
		if "`class'"=="paper"{
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "0167308C0D354082998D0152DBD6703E?method="
			local http3 "download&shareKey=872dfb4ae9e8e363e59dc551e8f594be"
			local URL   "`http1'`http2'`http3'"
			songbl_links1  ,url(`URL')
            cap erase `"`html_text'.txt"'  
			exit
		}	        
		
        * 常用STATA与经济学网站
		if "`class'"=="stata"{
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "7636593A108F4D2A8822E7FB559DF6A6?method="
			local http3 "download&shareKey=f4b970a98aa619af543e79ff4856992c"
			local URL   "`http1'`http2'`http3'"	
			songbl_links1  , url(`URL')
            cap erase `"`html_text'.txt"'  
			exit
		} 
		
        * 常用数据库网站
        if "`class'"=="data"{
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "0CEDE9E94A1A48318974261726F9F048?method="
			local http3 "download&shareKey=19fb9b5596d80cb85717cc210d7c9b81"
			local URL   "`http1'`http2'`http3'"							
			songbl_links ,url(`URL')
            cap erase `"`html_text'.txt"'  
			exit
		} 
		
        
        * 功能导航
        if "`class'"=="all"{
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "324DE307CAB2440CBC67CC318E9CEB45?method="
			local http3 "download&shareKey=bc1dfb9cd7a3cde598aed799d10ec86b"
			local URL   "`http1'`http2'`http3'"		
			songbl_links1  , url(`URL')
            cap erase `"`html_text'.txt"'  
			exit
		}  
		
        * 科研之余，消遣放松网站
        if "`class'"=="happy"{
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "1E6B86607C214BB79DBDCD957107B208?method="
			local http3 "download&shareKey=fab80cea7b6883d16be1c5b795634d3e"
			local URL   "`http1'`http2'`http3'"	
			songbl_links  ,url(`URL')
            cap erase `"`html_text'.txt"'  
			exit
		} 
		
		*批量获取导航链接 		
		if "`navigation'"!=""{
			tempfile  html_text
			local http1 "https://note.youdao.com/yws/api/personal/file/"
			local http2 "4DCA13297C1947E6BD85A9A14450B9BB?method="
			local http3 "download&shareKey=2ac33ef51b54f89f15b8c71d252ba716"
			local URL   "`http1'`http2'`http3'"
            local URL1 https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/songbl_URL.txt
			
            cap copy `"`URL1'"' `"`html_text'.txt"', replace  			
			if _rc ~= 0 {
				cap copy `"`URL'"' `"`html_text'.txt"', replace  
			}
			local times = 0
			while _rc ~= 0 {
				local times = `times' + 1
				sleep 1000
				cap copy `"`URL'"' `"`html_text'.txt"', replace
				if `times' > 10 {
					disp as error "Internet speeds is too low to get the data"
					exit 601
				}
			}
			qui infix strL v 1-100000 using `"`html_text'.txt"', clear
            cap erase `"`html_text'.txt"'              
			qui split v,  p("++")       
			cap keep v1 v2 v3	
            local o_class= "`class'"
			local class = lower("`class'")
            qui levelsof v1 , local(v1_type)  clean

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
        local ssc_tengxun "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ssc.txt"
        local ssc_youdao  "https://note.youdao.com/yws/api/personal/file/CFF0423DD30F4641BBD78A6B2F32EE28?method=download&shareKey=0f590652fc87c6a5fa2aa18798306cc7"
		
		tempfile  html_text  html_text_dta  html_text_seminar_paper_dta Share_txt  songbl_post 

        if "`cie'"!=""{
            cap which carryforward
            if _rc!=0{
                qui ssc install carryforward,replace
            }
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
			replace v = lower(v) 
			local o_class= "`class'"
			local class = lower("`class'")
			cap erase `"`html_text'.txt"' 
			gen n=_n
			gen title=v if index(v[_n-1],"**#论文标题：") 
			replace title=title[_n+10]
			gen id=n if index(v[_n+9],"**#论文标题：") 
			carryforward title id,replace
			bysort id:gen gap=_n
			levelsof id
			gen num=.
			local j=1
			foreach num in `r(levels)'{
				replace num=`j' if id==`num'
				local j=`j'+1
			}
			tostring num ,replace
			gen cie="cie"+num
			*gen id=n if title!=""
			keep if strmatch(v,`"*`class'*"')
			keep v cie title gap id
			gen 论文题目=title
			gen 发现在do文档第几行=gap
			rename v 详细内容
			*exit
			if ("`save'"=="")&("`replace'"==""){ 
				cap duplicates drop id, force
				if _rc!=0{
					dis as error "《中国工业经济》代码没有发现相关内容"
					exit
				}
			}
			
			if ("`save'"!="") {  
					insobs 2,before(1)
					replace 论文题目="论文题目" in 1
					tostring 发现在do文档第几行,replace
					replace 发现在do文档第几行="发现在do文档第几行" in 1
					replace 详细内容="详细内容" in 1
					qui export delimited 论文题目 发现在do文档第几行 详细内容 using "`Share_txt'.`save'" , ///
					novar nolabel delimiter(tab) replace				
					view browse  "`Share_txt'.`save'"	
					drop in 1/2
					cap duplicates drop id, force
					if _rc!=0{
						dis as error "《中国工业经济》代码没有发现相关内容"
						exit
					}
					*exit	
			}	
				
			local n=_N
			n dis as w `" 代码 >>"' `"{stata "songbl `class',cie save(txt)": 详细检索}"'
			forvalues i =1/`n'{
				local cie  =cie[`i']
				local title=title[`i']
				n dis in text _col(4)  "{stata qui sbldo `cie',replace:`title'}"
				n `gap'
			}	
			n dis ""
			n dis in red  _col(4)"检索到`n'篇存在 {bf:`o_class'} 关键词的do文档"
			if "`replace'"!="" {
				keep 论文题目 发现在do文档第几行 详细内容
				browse
			}
			exit
		}		
        
                       						
	    * 论文链接文本下载
		if "`paper'"!="" {      
			
            if "`class'"=="r" {
                cap copy `"`paper_youdao'"' `"`html_text'.txt"', replace 
            }
            else{
                cap copy `"`paper_tengxun'"' `"`html_text'.txt"', replace  
            }			
			
			if _rc ~= 0 {
				cap copy `"`paper_youdao'"' `"`html_text'.txt"', replace  
			}			
			
			local times = 0
			while _rc ~= 0 {
				local times = `times' + 1
				sleep 1000
				cap copy `"`paper_youdao'"' `"`html_text'.txt"', replace
				if `times' > 10 {
					disp as error "Internet speeds is too low to get the data"
					exit 601
				}
			}
		
		}
		
		* 论坛链接文本下载
		else if "`forum'"!="" {      
			local url https://note.youdao.com/yws/api/personal/file/6416D2AB38AC4FDC930C67B30897380C?method=download&shareKey=9c012a753b99c6a470581d6df10042af
		    
			cap copy `"`url'"' `"`html_text'.txt"', replace  		
			
			if _rc ~= 0 {
				cap copy `"`url'"' `"`html_text'.txt"', replace  
			}			
			
			local times = 0
			while _rc ~= 0 {
				local times = `times' + 1
				sleep 1000
				cap copy `"`url'"' `"`html_text'.txt"'', replace
				if `times' > 10 {
					disp as error "Internet speeds is too low to get the data"
					exit 601
				}
			}
		
		
		}		

	    * 论文链接文本下载
		else if "`ssc'"!="" {      
			
            if "`class'"=="r" {
                cap copy `"`ssc_youdao'"' `"`html_text'.txt"', replace  
            }
            else{
                cap copy `"`ssc_tengxun'"' `"`html_text'.txt"', replace   
            }
            
			if _rc ~= 0 {
				cap copy `"`ssc_youdao'"' `"`html_text'.txt"', replace  
			}			
			
			local times = 0
			while _rc ~= 0 {
				local times = `times' + 1
				sleep 1000
				cap copy `"`ssc_youdao'"' `"`html_text'.txt"', replace
				if `times' > 10 {
					disp as error "Internet speeds is too low to get the data"
					exit 601
				}
			}
		
		}  
     
	    * 论文链接文本下载
		else if "`ssci'"!="" {      
			
            cap copy `"https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/txt/ssci.txt"' `"`html_text'.txt"', replace   

            
			if _rc ~= 0 {
				cap copy `"https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/txt/ssci.txt"' `"`html_text'.txt"', replace  
			}			
			
			local times = 0
			while _rc ~= 0 {
				local times = `times' + 1
				sleep 1000
				cap copy `"https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/txt/ssci.txt"' `"`html_text'.txt"', replace
				if `times' > 10 {
					disp as error "Internet speeds is too low to get the data"
					exit 601
				}
			}
		
		}  	 
	 
	 	
	 
		* 推文链接文本下载
		else{ 
		
            if "`class'"=="r" {
                cap copy `"`stata_paper_youdao'"' `"`html_text'.txt"', replace  
            }
            else{
                cap copy `"`stata_paper_tengxun'"' `"`html_text'.txt"', replace    
            }	        	
			
			if _rc ~= 0 {
				cap copy `"`stata_paper_youdao'"' `"`html_text'.txt"', replace  
			}

			local times = 0
			while _rc ~= 0 {
				local times = `times' + 1
				sleep 1000
				cap copy `"`stata_paper_youdao'"' `"`html_text'.txt"', replace
				if `times' > 10 {
					disp as error "Internet speeds is too low to get the data"
					exit 601
				}
			}
       }	        
        
		
	    * 导入文本数据到stata

*		infix strL v 1-100000 using "forum.txt", clear 
	

	
	
        if "`forum'"!=""{
			import delimited `"`html_text'.txt"', clear
		    cap erase `"`html_text'.txt"'
			rename v1 v
			replace v2 = v2-1
			replace v2=10 if v2>=10
			rename v2 post
			gen v1= "https://www.statalist.org/forums/forum/general-stata-discussion/general/"+v
			gen v2 = ustrregexra(v, "^[0-9]+|-", " ") 
			replace v2 = strproper(v2)
			gen v3 = "The Stata Forums" 
			gen v4 = "Posts From The Stata Forums"
			gen v5 = "帖子"
			gen v6 = "2021/07/21"

			if "`post'"!=""{
				keep if post >=`post'
			}							
		}	
		else{	
			infix strL v 1-100000 using `"`html_text'.txt"', clear
			split v,  p("++")       
			*erase "`html_text'.txt"
			if _rc ~= 0 {
				di as err "Failed to get the data"
				exit 601
			}	
		}
		cap erase `"`html_text'.txt"'

	*==============================================================================*
	*       文本数据处理   		
		
		
	    * 变量重命名
		rename  v1  link                //链接    
        rename  v2  title               //标题 
        rename  v3  style               //推文内容分类
        rename  v4  type                //推文来源分类
        rename  v5  seminar_paper       //推文来源分类
        cap rename  v6  date                //推文来源分类
        

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
        gen title1 = lower(title) 
        gen style1 = lower(style) 
		gen text=title1+" "+style1
		gen ad   = strmatch(type,"*gg*")
        drop if style1=="未分类学术论文"
        drop if  strmatch(seminar_paper,"*advert*")==1
		drop if  strmatch(type,"*ad*")==1
 	   	replace seminar_paper="推文" if seminar_paper=="专题"
	   
	}

*		
*==============================================================================* 		
*==============================================================================*
	cap which sbldo
	if  _rc!=0 {
		dis in red "首次使用需要安装-sbldo-命令..." 
		dis as txt "	正在Installing..."
		dis as txt "	请您稍等数秒钟...^-^" _n
		sleep 2000
	   cap ssc install sbldo,replace
	   cap which sbldo
	   if _rc!=0{
			cap ssc install sbldo,replace
			cap which sbldo
			if _rc!=0{
				dis as error "Cannot install package -sbldo-, please install by hand at " "{stata ssc install sbldo,replace:ssc install sbldo,replace}"
				exit
			}
	   }
	}

	if link[4]=="内测更新"{
		dis in red "songbl命令有更新..." 
		dis as txt "	正在Installing..."
		dis as txt "	请您稍等数秒钟...^-^" _n
		sleep 3000
	    qui cap songbl install songbl
		qui cap songbl install sbldo
		if _rc!=0{
			cap net install songbl, replace from(https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/)
		    if _rc!=0{
					dis as error "无法自动更新 -songbl- 命令, 请按照" `" {browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.html#2-2-命令更新":Songbl命令手册.pdf}"' "进行手动下载更新"
					exit 601
		   }			
		}
		dis as txt  "命令已经更新完成。点击：" `"{browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.html#5-更新日志":Songbl命令更新日志}"'
		dis in red "请输入：clear all 或者重启 Stata ，再重新使用-songbl-命令"		
		dis in red "否则，会重复不断更新！！！" _n
		exit 
	}

	
	if link[4]=="SSC更新"{
		dis in red "songbl命令有更新..." 
		dis as txt "	正在Installing..."
		dis as txt "	请您稍等数秒钟...^-^" _n
		sleep 2000
	    cap ssc install songbl,replace
		cap ssc install sbldo ,replace
		if _rc!=0{
			cap ssc install songbl,replace
			cap ssc install sbldo ,replace
		    if _rc!=0{
					dis as error "由于网络问题，无法自动更新 -songbl- 命令, 请手动更新以下两个命令：" 
					n dis "	{stata ssc install songbl,replace:ssc install songbl,replace}"
					n dis "	{stata ssc install sbldo,replace:ssc install sbldo,replace}"
					exit 601
		   }			
		}
		dis as txt  "命令已经更新完成，点击：" `"{browse "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/s/songbl.html#5-更新日志":Songbl命令更新日志}"'
		dis in red "请输入：clear all 或者重启 Stata ，再重新使用 songbl 命令"		
		dis in red "否则，会重复不断更新！！！" _n
		exit 
	}
	
 
	* 当前日期转为通用年、月、日格式
    local start: disp %dCYND date("`c(current_date)'","DMY")
	local year  = substr("`start'",1,4)
	local month = substr("`start'",5,2)
	local day   = substr("`start'",7,2)
    local cur_time "`year'""年""`month'""月""`day'""日"            
    local new_link =link[1]
	local new_title =title[1]
    local search_link =link[2]
	qui drop in 1/2
	qui drop if link=="*更新*"
    qui drop if seminar_paper==""
    qui keep if strmatch(type,"*`author'*")==1    
*  
*==============================================================================*  
*==============================================================================*
*            关键词"class" 搜索
  	
  
		*------------------------------------------------------------------------*
		***输入1个关键词***
			
        if "`class'"=="公告" & "`paper'"=="" & "`wlink'" =="" & "`wtext'"  =="" & "`mlink'" ==""   ///   
       & "`mtext'" =="" & "`murl'" =="" & "`wurl'" ==""  & "`replace'" =="" & "`save'" ==""  {
            qui dingwei style,c(微信交流群)
            local r(row_n)=`r(row_n)'
            local weixin_link=link[`r(row_n)']
            dis as txt "{hline 110} "	 
            dis  in text _col(30)  "{bf:致各位使用songbl命令的Stata爱好者的一份公告}"
            dis as txt "{hline 110} "	
            dis ""
            dis  in text "{bf:命令介绍：}"
            dis _col(6) in text "songbl是一个用于Stata资源共享与检索的命令" 
            dis _col(6) in text `"关于命令使用方式的详细介绍，请查看:{stata h songbl_cn: {bf:help songbl} }"' _n

            dis ""
            *dis _col(6) in text `"{bf:请注意：}"'  
            dis _col(6) in text `"为了扩大songbl命令的资源库；"'  `"为了songbl命令的可持续发展；"'   `"为了更好地促进stata知识交流"'  _n
            dis  in text "{bf:我们倡议：}"		
            dis ""
            dis _col(6) as red "{bf:凡是使用songbl命令的朋友，请务必通过下面的链接，每半年内至少分享一次资料或相关文章}"  _n
            dis _col(6) in text "资源包括：Stata推文、帖子、理论与实证论文、数据、视频或者其他资源" 
            dis _col(6) in text "资源发布后就可以在Stata窗口搜到，或者在Stata窗口输入：songbl new,n(#)查看最新上传的资源 " 
            dis _col(6) in text "songbl new 默认显示最新上传前10条资源。"  "显示最新上传前20条资源则为:songbl new,n(20) " _n	
            dis _col(6) in text "上传资源到Songbl数据库的链接:" `"{browse "`new_link'": {bf:`new_link'}}"' _n	

            dis _col(6) in text "Distribution-Date: 20210512" 
            dis _col(6) in text "Author:Song Bolin,(松柏林)Shenzhen University, China." 
            dis _col(6) in text  "Support: Stata微信交流群 " `"{browse "`weixin_link'":{bf:songbl_stata}}"' 				     
            dis as txt "{hline 110} "	
            dis as  text _col(3) `"{stata  songbl new,g: (查看最新上传Songbl平台的资源)}"' _n	
            cap erase `"`html_text'.txt"' 
            exit
        }	
        
        if "`class'"=="网页检索" & "`paper'"=="" & "`wlink'" =="" & "`wtext'"  =="" & "`mlink'" ==""   ///   
       & "`mtext'" =="" & "`murl'" =="" & "`wurl'" ==""  & "`replace'" =="" & "`save'" ==""  {
            h songbl_cn
            cap erase `"`html_text'.txt"' 
            exit
        }	
                
        
        if "`class'"=="r" & "`wlink'" =="" & "`wtext'"  =="" & "`mlink'" ==""   ///   
       & "`mtext'" =="" & "`murl'" =="" & "`wurl'" ==""  & "`replace'" =="" & "`save'" ==""  {
            qui drop if v==""
            local n = _N
            loc n = runiformint(1, `n')
            dis "" 
            local link=link[`n']
            local title=title[`n']
            local seminar_paper=seminar_paper[`n']
            local style=style[`n']
            dis as w " `seminar_paper' >>"`"{stata "songbl `style'": `style'}    
            dis "" 
            if strmatch(`"`link'"',"* *")==1{	
                dis _col(9) `"{stata `"`link'"': `title'}"'
            }			 				 
            else{
                dis _col(9) `"{browse `"`link'"': `title'}"'
            }	
            exit
        }
        
    
		if "`1'"!="" & "`2'"=="" {    	                  	
					                      
            if "`1'"=="new" & "`paper'"=="" & "`forum'"=="" & "`wlink'" =="" & "`wtext'"  =="" & "`mlink'" ==""   ///   
		    & "`mtext'" =="" & "`murl'" =="" & "`wurl'" ==""  & "`replace'" =="" & "`save'" ==""  & "`ssc'"=="" {   
				if  "`num'"==""{
					local num=10
				}		
                qui sort date type style title	
				qui drop  if title=="new_songbl"
				qui drop  in 1
				qui drop  if seminar_paper=="论文"
                qui drop  if type=="gg"
				qui cap keep in -`num'/ -1 
                local n  =_N
                local all_n=_N
                dis   as  text   _skip(45) "{bf:Hello, Songbl Stata}" _n
				if  `num'>`all_n'{
					dis as  text _col(4) "以下为全部`author'推文:共`all_n'篇"  _col(88) "`year'-`month'-`day' `c(current_time)'" 
				}
				else{
				    dis as  text _col(4) "以下为最新`num'篇`author'推文"   _col(88) "`year'-`month'-`day' `c(current_time)'" 
				}
                dis as txt "{hline 135} "	
                dis in text _col(4)  "{bf:Url}" _col(12)  "{bf:Model}" _col(29) `"{bf:Author}"' _col(45) `"{bf:Type}"' _col(60) `"{bf:Date}"'  _col(75) `"{bf:Title}"'
			    dis as txt "{hline 135} "		
                `gap'
                forvalues i = 1/`n' {         
                    local link=link[`i']
                    local title=title[`i']
                    local type=type[`i']
                    local style=style[`i']
					local seminar_paper =seminar_paper[`i']  
                    local date =date[`i']
                    if strmatch(`"`link'"',"* *")==1{
                        dis  _col(5) `"{stata `"`link'"':-}"'  _col(9) `"{stata songbl `style': `style'}"'   ///
                        _col(29) `"`type'"' _col(45)  `"`seminar_paper'"'	  _skip(8)  `"`date'"'  _skip(8)  `"`title'"'
                    }
                    else {
                        dis  _col(5) `"{browse `"`link'"':-}"'  _col(9) `"{stata songbl `style': `style'}"'   ///
                        _col(29) `"`type'"' _col(45)  `"`seminar_paper'"'	  _skip(8)  `"`date'"'  _skip(8)  `"`title'"'	                        
                    }						
                    

					if "`line'"!=""{
                        `gap'
						dis as txt "{hline 135} "
					} 
                	`gap'
				}   
 					if "`line'"==""{
						dis as txt "{hline 135} "	
					}         
					dis as  text _col(3) `"{stata  songbl 公告: (Songbl平台公告与资源上传)}"' _n	
				cap erase `"`html_text'.txt"'     
                exit
            }    
                
            if "`1'"=="new" & "`paper'"=="" & "`forum'"=="" & "`wlink'" =="" & "`wtext'"  =="" & "`mlink'" ==""   ///   
		    & "`mtext'" =="" & "`murl'" =="" & "`wurl'" ==""  & "`replace'" =="" & "`save'" ==""  & "`ssc'"!="" {   
				if  "`num'"==""{
					local num=10
				}	
                qui sort date type style title	
				qui drop  if title=="new_songbl"
				qui drop  in 1
				qui drop  if seminar_paper=="论文"
                qui drop  if type=="gg"
				qui cap keep in -`num'/ -1 
                local n  =_N
                local all_n=_N
                dis   as  text   _skip(60) "{bf:Hello, Songbl Stata}" _n
				if  `num'>`all_n'{
					dis as  text _col(4) "以下为全部`author'外部命令:共`all_n'条"  _col(118) "`year'-`month'-`day' `c(current_time)'" 
				}
				else{
				    dis as  text _col(4) "以下为最新`num'条`author'外部命令"   _col(118) "`year'-`month'-`day' `c(current_time)'" 
				}
                dis as txt "{hline 140} "	
                dis in text _col(6)  "{bf:Command}" _col(25) `"{bf:Date}"'  _col(43) `"{bf:Description}"'
			    dis as txt "{hline 140} "		
                `gap'
                forvalues i = 1/`n' {         
                    local link=link[`i']
                    local title=title[`i']
                    local type=type[`i']
                    local style=style[`i']
					local seminar_paper =seminar_paper[`i']  
                    local date =date[`i']
                    local col  =43  
                    local col1 =5
                    local col2 =25
                    local col3 =43

                    local udstrlen=udstrlen(`"`title'"')

                        if udstrlen(`"`title'"')<=100{
                        
                            local title1=udsubstr(`"`title'"',1,100)
                            
                            dis  _col(`col1') `"{stata `"ssc describe `style'"': `style'}"'    ///
                                 _col(`col2')  `"`date'"'  _col(`col3')  `"`title1'"'                         
                            `gap'                           
                        }                    
                    
                            if udstrlen(`"`title'"')>100 & udstrlen(`"`title'"')<=200{
                            
                            local title1=udsubstr(`"`title'"',1,100) 

                            local title2=usubinstr(`"`title'"',`"`title1'"',"",.)
                            local title2=udsubstr(`"`title2'"',1,100) 
                            dis  _col(`col1') `"{stata `"ssc describe `style'"': `style'}"'    ///
                                 _col(`col2')  `"`date'"'  _col(`col3')  `"`title1'"'   
                            dis  _col(`col') `"`title2'"'                              
                            `gap'                           
                        }
                        
                        if udstrlen(`"`title'"')>200 & udstrlen(`"`title'"')<=300{
                            
                            local title1=udsubstr(`"`title'"',1,100) 

                            local title2=usubinstr(`"`title'"',`"`title1'"',"",.)
                            local title2=udsubstr(`"`title2'"',1,100) 

                            local title3=usubinstr(`"`title'"',`"`title1'`title2'"',"",.)
                            local title3=udsubstr(`"`title3'"',1,100) 

                            dis  _col(`col1') `"{stata `"ssc describe `style'"': `style'}"'    ///
                                 _col(`col2')  `"`date'"'  _col(`col3')  `"`title1'"'  
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
                      
                            dis  _col(`col1') `"{stata `"ssc describe `style'"': `style'}"'    ///
                                 _col(`col2')  `"`date'"'  _col(`col3')  `"`title1'"'    
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
                      
                            dis  _col(`col1') `"{stata `"ssc describe `style'"': `style'}"'    ///
                                 _col(`col2')  `"`date'"'  _col(`col3')  `"`title1'"'  
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
                            
                            dis  _col(`col1') `"{stata `"ssc describe `style'"': `style'}"'    ///
                                 _col(`col2')  `"`date'"'  _col(`col3')  `"`title1'"'     
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
                           
                            dis  _col(`col1') `"{stata `"ssc describe `style'"': `style'}"'    ///
                                 _col(`col2')  `"`date'"'  _col(`col3')  `"`title1'"'     
                            dis  _col(`col') `"`title2'"'  
                            dis  _col(`col') `"`title3'"'  
                            dis  _col(`col') `"`title4'"'  
                            dis  _col(`col') `"`title5'"'  
                            dis  _col(`col') `"`title6'"'  
                            dis  _col(`col') `"`title7'"'                         
                            `gap'                           
                        
                        }                         
                        
                        
                        if udstrlen(`"`title'"')>700 & udstrlen(`"`title'"')<=20000{
                            
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
                   
                            dis  _col(`col1') `"{stata `"ssc describe `style'"': `style'}"'    ///
                                 _col(`col2')  `"`date'"'  _col(`col3')  `"`title1'"'   
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
                           
					
                    if "`line'"!=""{
						dis as txt "{hline 140} "	
                        `gap'
					}  
                }
                if "`line'"==""{
                    dis as txt "{hline 140} "	
                }         	
                    dis as  text _col(3) `"注：由谷歌翻译自动转为中文"' _n	
				cap erase `"`html_text'.txt"'     
                exit
            }    
                            
            
            
            if "`1'"=="new" & "`paper'"==""  & "`ssc'"==""  {              

                if  "`num'"==""{
                        local num=10
                    }		
					qui sort date type style title	
                    qui drop  if strmatch(link,"* *")==1		
                    qui drop  if title=="new_songbl"
                    qui drop  in 1
                    qui drop  if seminar_paper=="论文"
                    qui drop  if type=="gg"
                    *qui keep if strmatch(type,"*`author'*")==1
                    qui cap keep in -`num'/ -1      //保留今日更新推文的行号 `nrow'/ `N'	
                    local n  =_N
                    local all_n=_N
                    if  `num'>`all_n'{
                        dis as  text "{bf:#### <center>`cur_time'songbl命令中最新的`all_n'篇`author'Stata推文</center>}" 
                    }
                    else{
                        dis as  text "{bf:#### <center>`cur_time'songbl命令中最新的`num'篇`author'Stata推文</center>}"  
                    }                    
                if  "`mlink'" !="" | "`mtext'" !="" | "`murl'" !=""{
                    if "`line'"!="" & {
                        capture postclose songbl_post
                        qui postfile songbl_post str1000 Share using "`songbl_post'", replace	   
                        if  `num'>`all_n'{
                            post songbl_post  (`"#### <center>songbl命令中最新的`all_n'篇`author'Stata推文</center>"')
                        }
                        else{
                            post songbl_post  (`"#### <center>songbl命令中最新的`num'篇`author'Stata推文</center>"')  
                        }                                                            
                        post songbl_post    (`" Model | Author |Type  |Date | Title"')
                        dis as  text `" Model | Author |Type  |Date | Title"'
                        post songbl_post    (`":---|:---|:---|:---|:---"')
                        dis as  text `":---|:---|:---|:---|:---"'
                        *local n  =_N
                        forvalues i = 1/`n' {         
                            local link=link[`i']
                            local title=title[`i']
                            local type=type[`i']
                            local style=style[`i']
                            local seminar_paper =seminar_paper[`i']  
                            local date =date[`i']
                            dis as  text `"`style'|`type'|`seminar_paper'|`date'|[`title'](`link')"'
                            post songbl_post    (`"`style'|`type'|`seminar_paper'|`date'|[`title'](`link')"')
                        }
                        postclose songbl_post                        
                        use "`songbl_post'", clear
                        if ("`replace'"!="") {   
                            cap format %-200s Share  
                            br       
                        }                        
                        if ("`save'"!="") { 
                            cap format %-200s Share  
                            qui export delimited Share using "`Share_txt'.`save'" , ///
                            novar nolabel delimiter(tab) replace				
                            view browse  "`Share_txt'.`save'"	        
                        }	                        
                        exit   
                    }    
                }                
    
            }      
            
            if "`1'"!="songbl" & "`1'"!="new"{
				cap local 1 = strlower(`"`1'"') 
				if _rc!=0{
					local 1 = strlower("`1'")	
				}
				cap gen yjy1 = strmatch(text,`"*`1'*"') 
				if _rc!=0{
					gen yjy1 = strmatch(text,"*`1'*") 
				}
				quietly keep if yjy1==1 | ad==1 			 			 
			}			
			
		}	

		*------------------------------------------------------------------------*
		***输入2个关键词***    
		
	qui{
		else{
					
			if strmatch(`"`class'"',"*+*")==1{
				local class_new = subinstr(`"`class'"',"+"," ",.)		
				tokenize `class_new'
				local wordn = wordcount("`class_new'")
				forvalues i = 1/`wordn'{
					local `i' = strlower(`"``i''"')   
					gen yjy`i'   = strmatch(text,`"*``i''*"') 
				}  			
			cap egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error  `"  songbl :  invalid songbl type"'	
				exit 198	
			}			
			keep if yjy>=1|ad==1
			}
			
			if strmatch(`"`class'"',"*-*")==1{
				local class_new = subinstr(`"`class'"',"-"," ",.)		
				tokenize `class_new'
				local wordn = wordcount("`class_new'")
				forvalues i = 1/`wordn'{
					local `i' = strlower(`"``i''"')  
					gen yjy`i'   = strmatch(text,`"*``i''*"') 
				}  			
			cap egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error  `"  songbl :  invalid songbl type"'	
				exit 198	
			}
			keep if (yjy1==1 & yjy==1)  | ad==1
			}

			if strmatch(`"`class'"',"*+*")==0 & strmatch(`"`class'"',"*-*")==0{
				local class_new = subinstr(`"`class'"',"-"," ",.)		
				tokenize `class_new'
				local wordn = wordcount(`"`class_new'"')
				forvalues i = 1/`wordn'{	
					local `i' = strlower(`"``i''"')  
					gen yjy`i'   = strmatch(text,`"*``i''*"') 
				}  					
			cap egen yjy=rowtotal(yjy*)	
			if _rc!=0{
				dis as error  `"  songbl :  invalid songbl type"'	
				exit 198	
			}			
			keep if yjy==`wordn'| ad==1
			}
			
		}
	}
	
		
        qui keep if strmatch(type,"*`author'*")==1 | ad==1
        qui drop if seminar_paper=="删除"
		local n  =_N                  //排除无效数据
		local ad =ad[1]
        qui count if ad==1
        local coun_ad=`n'-`r(N) '
		
		if `coun_ad'<=0{
					
			if missing("`paper'") &  missing("`forum'"){
				dis as error  `"  {bf:抱歉，没有找到与 [ {it:`class'} ] 相关的内容。}"' _n
				dis as red    `"  试试：{stata "songbl":[分类查看推文]}"'  `"  或者  {stata "h songbl_cn":[查看帮助文档]}"' _n
				dis as text   `"  或者试试网页搜索："'
				dis as text _col(5)`"  {stata " songbl `*',s(计量圈) "}  或  {stata " songbl `*',s(百度) "}"'                   
				dis as text _col(5)`"  {stata " songbl `*',s(公众号) "}  或  {stata " songbl `*',s(知乎) "}"'  
				dis as text _col(5)`"  {stata " songbl `*',s(经管家) "}  或  {stata " songbl `*',s(全部) "}"'  _n                 
				dis as text   `"  如果您发现Songbl命令的使用Bug，或者对Songbl命令的改善有什么建议"'
				dis as text   `"  您可以通过以下链接填写资料告知我们"' 
				dis as error  `"  {bf:点击链接:}"'
				dis as text _col(8)  `"  ({browse "`search_link'":`search_link'})"'  
				cap erase `"`html_text'.txt"' 
				dis ""
				dis as red    `"  或者试试检索代码：{stata "songbl `*',cie"}"' 
				exit
			}
			else if missing("`paper'") {
				dis as error _col(3) `"没有搜到[ {it:`class'} ]相关的论坛帖子"'   
			}
			else{
				dis as error _col(3) `"没有搜到[ {it:`class'} ]相关的论文。{stata "songbl paper":{bf:[分类查看论文]}}"'
			}	
            cap erase `"`html_text'.txt"'               
			exit 
		}       
                
        qui{
            if "`so'"!=""{ 
                insobs 5, before(1)
                replace link ="songbl `*',s(计量经济圈)"  in 1
                replace link ="songbl `*',s(经管之家)"  in 2            
                replace link ="songbl `*',s(公众号)"  in 3            
                replace link ="songbl `*',s(知乎)"    in 4
                replace link ="songbl `*',s(百度)"    in 5            
                replace title ="计量经济圈检索：`*'"  in 1
                replace title ="经管之家：`*'"  in 2            
                replace title ="微信搜索：`*'"  in 3            
                replace title ="知乎搜索：`*'"    in 4
                replace title ="百度搜索：`*'"    in 5            
                replace style ="网页检索"  in 1
                replace style ="网页检索"  in 2            
                replace style ="网页检索"  in 3            
                replace style ="网页检索" in 4
                replace style ="网页检索"  in 5             
                replace type ="网页"  in 1
                replace type ="网页"  in 2            
                replace type ="网页"  in 3            
                replace type ="网页"  in 4
                replace type ="网页"  in 5             
                replace seminar_paper ="页尾"  in 1
                replace seminar_paper ="页尾"  in 2            
                replace seminar_paper ="页尾"  in 3            
                replace seminar_paper ="页尾"  in 4
                replace seminar_paper ="页尾"  in 5    
            }      
        }              
  
*  
*==============================================================================*  
*==============================================================================*
*          关键词"class" 打印   	

            if  "`ssc'"!=""  {   
                qui sort date type style title	
                local n  =_N
                local all_n=_N
                dis as  text   _skip(55) "{bf:Hello, Songbl Stata}" _n
                dis as txt "{hline 140} "	
                dis in text _col(4)  "{bf:Help}" _col(12)  "{bf:Command}" _col(29) `"{bf:Date}"'  _col(45) `"{bf:Description}"'
			    dis as txt "{hline 140} "		
                `gap'
                forvalues i = 1/`n' {         
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
                    
					if "`line'"!=""{
						dis as txt "{hline 140} "	
                        `gap'
					}  
                
				}
                
				if "`line'"==""{
                    dis as txt "{hline 140} "	
                }  
				
                dis as  text _col(3) `"注：由谷歌翻译自动转为中文"' _n	
				cap erase `"`html_text'.txt"'   
                exit
            }    


		if  "`wlink'" =="" & "`wtext'"  =="" & "`mlink'" =="" & "`mtext'" =="" & "`murl'" =="" & "`wurl'" =="" {
            qui save "`html_text_dta'", replace	  // 保存关键词 "class" 搜索到的数据   
            qui levelsof seminar_paper , local(seminar_paper) 
			foreach  seminar_paper  in  `seminar_paper' { 
                use "`html_text_dta'", clear
				qui keep if seminar_paper=="`seminar_paper'"
                qui save "`html_text_seminar_paper_dta'", replace
				qui levelsof style , local(number) 
				foreach  num  in  `number' { 
                    use  "`html_text_seminar_paper_dta'", clear
                    qui keep if style=="`num'"
					local n=_N
					if `n'>0{
						if  strmatch("`num'","*学术论文*") ==1 {
							sort  title 
							if missing("`nocat'"){
								local name = plural(2,"`num'","-学术论文")							
							
								if missing("`paper'"){ 
									dis as w " `seminar_paper' >>"`"{stata "songbl `name'": `name'}"'"
								}								
								
								else{
									dis as w " `seminar_paper' >>"`"{stata "songbl `name',paper": `name'}"'"
								}
							}	
						}
						
						else {
							sort type2   title        
							if missing("`nocat'"){
								if missing("`ssci'"){
									dis as w `" `seminar_paper' >>"' `"{stata "songbl `num'": `num'}"'
								}
								else{
									dis as w `" `seminar_paper' >>"' `"{stata "songbl `num',ssci": `num'}"'									
								}
								
							}
						}    
						

						forvalues i = 1/`n' {         
							local link=link[`i']
							local title=title[`i']
							cap dis strmatch(`"`link'"',"* *")==1
							if _rc==0{
								if strmatch(`"`link'"',"* *")==1{	
									if "`ssci'"!=""{
										dis _col(4) `"{browse `"`link'"': `title'}"'										
									}
									else{
										dis _col(4) `"{stata `"`link'"': `title'}"'
									}
								}			 				 
								else{
									dis _col(4) `"{browse `"`link'"': `title'}"'
								}															
								if "`file'"!="" & strmatch(`"`title'"', `"*.`file'"')==1  {
									gitee `"`link'"',cla(`file')
								} 	
							}
							else{
								if strmatch("`link'","* *")==1{	
									dis _col(4) `"{stata `"`link'"': `title'}"'
								}			 				 
								else{
									dis _col(4) `"{browse `"`link'"': `title'}"'
								}															
								if "`file'"!="" & strmatch("`title'", "*.`file'")==1  {
									gitee `"`link'"',cla(`file')
								} 										
							}

							`gap'
						}
				   }
					*use "`html_text_dta'", clear
					if missing("`nocat'"){
                        dis ""
					}
				}
			
			}	
			
			if "`save'"!="" {
				dis as error `" 命令格式有误，see { stata  " help songbl_cn" }"'
				dis as error `" Note:save 选择项必须与 wlink 、wtext 、mlink 、mtext、murl、wurl 等分享功能一起使用  "'
				cap erase `"`html_text'.txt"' 
                exit 198	
			}		
		    use "`html_text_dta'", clear
		}	

		else {	
            if  "`mlink'" !="" | "`mtext'" !="" | "`murl'" !=""{
            	qui drop  if strmatch(link,`"* *"')==1 
            }
            qui save "`html_text_dta'", replace	  // 保存关键词 "class" 搜索到的数据    
			capture postclose songbl_post
			qui postfile songbl_post str1000 Share using "`songbl_post'", replace		
		     
			 
            if "`class'"=="new"{
                local cur_time "`year'年`month'月`day'日"
                if  `num' > `all_n'{
                    post songbl_post  (`"# **`cur_time'songbl命令中最新的`all_n'篇`author'Stata推文** "') 
                }
                else{
                    post songbl_post  (`"# **`cur_time'songbl命令中最新的`num'篇`author'Stata推文** "') 
                }                  
               
            }   
			
               
			if "`wlink'" !=""{	
                
				dis ""	
				dis as txt _n "{hline 24} wlink文本格式 {hline 24}"	
				dis as txt	
				if missing("`paper'"){
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl `class'"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl `class'") 
				}
				else {
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl `class',paper"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl `class',paper") 
				}			
				dis as txt	
				post songbl_post  (" ") 
				qui levelsof seminar_paper , local(seminar_paper) 	
				local m=_N			
				foreach  seminar_paper  in  `seminar_paper' { 
                    use "`html_text_dta'", clear
                    qui keep if seminar_paper=="`seminar_paper'"
                    qui save "`html_text_seminar_paper_dta'", replace					                    
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
                        use  "`html_text_seminar_paper_dta'", clear						
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
									dis as w _col(4) " `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 							
									`gap' 
									`gap1'
									post songbl_post  ("    `seminar_paper' >> `num'" ) 
																
								}
							}         
							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']	
								cap di wordcount(`"`title': `link'"')
								if _rc==0{
									post songbl_post (`"`title': `link'"') 
								}
								if  "`clip'"==""{
									dis as y `"`title': `link'"'
								}
								else{
									local  clip1 `"`title': `link'"'
									local  clip2 `"`title': `link'"'
									dis `"{stata `"!echo `clip1'       Copy by #公众号:songbl | clip"': `clip2'}"'
								}

								`gap'
								`gap1'
							}
						}
						if missing("`nocat'"){
							dis ""
							post songbl_post  (" " ) 
						}        
					}
				}	
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"			
				if "`paper'"!=""{
                    dis as red "{bf:小提示：}" `"使用 {stata `"songbl `class',p w clip "':songbl `class',p w clip} 后，"' "点击超链接，按Ctrl+V可进行粘贴"  
					dis as red  "        建议分多次复制到微信对话框，每次 10 行，否则超链接无法生效"
                    dis as red   "        长链接断行导致打印失败。请使用" `" {stata `"songbl `class',w p replace"':songbl `class',p w replace }"' "或者" `" {stata `"songbl `class',w p save(txt)"':songbl `class',w p save(txt)}"'
				}
				
				else if "`forum'"!=""{
                    dis as red "{bf:小提示：}" `"使用 {stata `"songbl `class',f w clip "':songbl `class',f w clip} 后，"' "点击超链接，按Ctrl+V可进行粘贴"  
					dis as red  "        建议分多次复制到微信对话框，每次 10 行，否则超链接无法生效"
                    dis as red   "        长链接断行导致打印失败。请使用" `" {stata `"songbl `class',w f replace"':songbl `class',f w replace }"' "或者" `" {stata `"songbl `class',w f save(txt)"':songbl `class',w f save(txt)}"'
				}				
				
                else{
                    dis as red "{bf:小提示：}" `"使用 {stata `"songbl `class', w clip "':songbl `class', w clip} 后，"' "点击超链接，按Ctrl+V可进行粘贴"                      
					dis as red  "        建议分多次复制到微信对话框，每次 10 行，否则超链接无法生效"
                    dis as red   "        长链接断行导致打印失败。请使用" `" {stata `"songbl `class',w replace"':songbl `class', w replace }"' "或者" `" {stata `"songbl `class',w save(txt)"':songbl `class',w save(txt)}"'       
               }
			}
			
			if "`wtext'" !=""{		
				dis ""	
				dis as txt _n "{hline 24} wtxt文本格式 {hline 24}"	
				dis as txt				
				if missing("`paper'"){
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl `class'"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl `class'")  
				}
				else {
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl `class',paper"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl `class',paper") 
				}		
				dis as txt	
				post songbl_post  (" ") 		
				use "`html_text_dta'", clear
                qui levelsof seminar_paper , local(seminar_paper) 	
				local m=_N			
                foreach  seminar_paper  in  `seminar_paper' { 
                    use "`html_text_dta'", clear
                    qui keep if seminar_paper=="`seminar_paper'"
                    qui save "`html_text_seminar_paper_dta'", replace					                    
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
                        use  "`html_text_seminar_paper_dta'", clear						
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
									dis as w _col(4) " `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 						
									post songbl_post  ("    `seminar_paper' >> `num'" ) 								
									`gap'
									`gap1'
								}	
							}     					
							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']
								cap di wordcount(`"`title': `link'"')
								if _rc==0{
									dis  as text `"`title'"'
									dis  as text `"`link'"'								
									post songbl_post  (`"`title'"') 
									post songbl_post  (`"`link'"') 	
								}
								`gap'
								`gap1'
							}
						}
						if missing("`nocat'"){
							post songbl_post  (" " ) 					
							dis ""
						}         
					}
				}	
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"
				if "`paper'"!=""{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',wt p replace"':songbl `class',wt p replace }"' "或者" `" {stata `"songbl `class',wt p save(txt)"':songbl `class',wt p save(txt)}"'  
                }
				
				else if "`forum'"!=""{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',wt f replace"':songbl `class',wt f replace }"' "或者" `" {stata `"songbl `class',wt f save(txt)"':songbl `class',wt f save(txt)}"'  
                }		
				
				else{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',wt replace"':songbl `class',wt replace }"' "或者" `" {stata `"songbl `class',wt save(txt)"':songbl `class',wt save(txt)}"' 					
				}
			}		
			
			if "`wurl'"  !=""{
				dis ""	
				dis as txt _n "{hline 24} wurl文本格式 {hline 24}"	
				dis as txt				
				if missing("`paper'"){
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl `class'"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl `class'") 
				}
				else {
                    dis as res "* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace"
					dis as res "* 查看更多内容请在 Stata 窗口输入代码：songbl `class',paper"
                    post songbl_post  ("* 以下内容由 -songbl- 命令生成，安装命令：ssc install songbl,replace") 
					post songbl_post  ("* 查看更多内容请在 Stata 窗口输入代码：songbl `class',paper") 
				}		
				dis as txt	
				post songbl_post  (" ") 		
				use "`html_text_dta'", clear
                qui levelsof seminar_paper , local(seminar_paper) 	
				local m=_N
                foreach  seminar_paper  in  `seminar_paper' { 
                    use "`html_text_dta'", clear
                    qui keep if seminar_paper=="`seminar_paper'"
                    qui save "`html_text_seminar_paper_dta'", replace					                    
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
                        use  "`html_text_seminar_paper_dta'", clear						
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
									dis as w _col(4) " `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 
									post songbl_post  ("    `seminar_paper' >> `num'" ) 							
									`gap' 
									`gap1'
								}	
							}      

							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']		
								cap di wordcount(`"`title': `link'"')
								if _rc==0{
									if `n'==1{
										dis as text `"`title': `link'"'
										post songbl_post  (`"`title': `link'"') 								
									}
									else {
										dis as text `"`i'. `title': `link'"'
										post songbl_post  (`"`i'. `title': `link'"') 
									}	
								}
								`gap'
								`gap1'
							}
						}
						if missing("`nocat'"){
							post songbl_post  (" " ) 					
							dis ""
						}         
					}
				}	
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
				if "`paper'"!=""{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',wu p replace"':songbl `class',wu p replace }"' "或者" `" {stata `"songbl `class',wu p save(txt)"':songbl `class',wu p save(txt)}"'  
                }
				
				if "`forum'"!=""{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',wu f replace"':songbl `class',wu f replace }"' "或者" `" {stata `"songbl `class',wu f save(txt)"':songbl `class',wu f save(txt)}"'  
                }				
				
				else{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',wu replace"':songbl `class',wu replace }"' "或者" `" {stata `"songbl `class',wu save(txt)"':songbl `class',wu save(txt)}"' 					
				}
			}		
						
			if "`mlink'" !=""{
				dis ""	
				dis as txt _n "{hline 24} mlik文本格式 {hline 24}"	
				dis as txt				
				if missing("`paper'"){
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl `class'**"
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
			}
				else {
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl `class',paper**"
                    post songbl_post  ("> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**") 
					post songbl_post  ("> 查看更多内容请在 Stata 窗口输入代码：**songbl `class',paper**") 
				}		
				post songbl_post  ("---") 
				dis as txt "---"				
				use "`html_text_dta'", clear
                qui levelsof seminar_paper , local(seminar_paper) 		
				local m=_N
                foreach  seminar_paper  in  `seminar_paper' { 
                    use "`html_text_dta'", clear
                    qui keep if seminar_paper=="`seminar_paper'"
                    qui save "`html_text_seminar_paper_dta'", replace					                    
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
                        use  "`html_text_seminar_paper_dta'", clear						
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
									dis as w _col(4) "### `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 
									post songbl_post  ("### `seminar_paper' >> `num'" ) 							
									`gap' 
									`gap1'
								}	
							}   
							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']		
								cap di wordcount(`"`title': `link'"')
								if _rc==0{
									dis as text `"- [`title'](`link')"'
									post songbl_post  (`"- [`title'](`link')"') 
								}
								`gap'
								`gap1'
							}
						}
						if missing("`nocat'"){
							post songbl_post  (" " ) 					
							dis ""
						}         
					}
				}	
				post songbl_post  ("## **Stata** 交流群微信：songbl_stata")  					
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"		
				if "`paper'"!=""{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',m p replace"':songbl `class',m p replace }"'  
					dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',m p save(txt)"':     songbl `class',m p save(txt)}"' 
                }
				else if "`forum'"!=""{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',m f replace"':songbl `class',m f replace }"'  
					dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',m f save(txt)"':     songbl `class',m f save(txt)}"' 
                }
				
				else{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用：" `" {stata `"songbl `class',m replace"':songbl `class',m replace }"'
					dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',m save(txt)"':       songbl `class',m save(txt)}"' 
				}
			}

			if "`mtext'" !=""{
				dis ""	
				dis as txt _n "{hline 24} mtext文本格式 {hline 24}"	
				dis as txt				
				if missing("`paper'"){
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl `class'**"
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
				}
				else {
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl `class',paper**"
                    post songbl_post  ("> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**") 
					post songbl_post  ("> 查看更多内容请在 Stata 窗口输入代码：**songbl `class',paper**") 
				}
				dis as txt "---"	
				post songbl_post  ("---") 			
				use "`html_text_dta'", clear
                qui levelsof seminar_paper , local(seminar_paper) 
				local m=_N
                foreach  seminar_paper  in  `seminar_paper' { 
                    use "`html_text_dta'", clear
                    qui keep if seminar_paper=="`seminar_paper'"
                    qui save "`html_text_seminar_paper_dta'", replace					                    
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
                        use  "`html_text_seminar_paper_dta'", clear						
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
									dis as w _col(4) "### `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 
									post songbl_post  ("### `seminar_paper' >> `num'" ) 							
									`gap' 
									`gap1'
								}	
								
							}     
							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']		
								cap di wordcount(`"`title': `link'"')
								if _rc==0{
									dis as text `"[`title'](`link')"'
									post songbl_post  (`"[`title'](`link')"') 
								}														
								`gap'
								`gap1'
							}
						}
						if missing("`nocat'"){
							post songbl_post  (" " ) 					
							dis ""
						}          
					}
				}	
				post songbl_post  ("## **Stata** 交流群微信：songbl_stata")  				
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
				if "`paper'"!=""{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',mt p replace"':songbl `class',mt p replace }"'  
					dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',mt p save(txt)"':     songbl `class',mt p save(txt)}"' 
                }
				
				else if "`forum'"!=""{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',mt f replace"':songbl `class',mt f replace }"'  
					dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',mt f save(txt)"':     songbl `class',mt f save(txt)}"' 
                }
				
				else{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用：" `" {stata `"songbl `class',mt replace"':songbl `class',mt replace }"'
					dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',mt save(txt)"':       songbl `class',mt save(txt)}"' 
				}
			}		
			
			if "`murl'"  !=""{
				dis ""	
				dis as txt _n "{hline 24} murl文本格式 {hline 24}"	
				dis as txt				
				if missing("`paper'"){
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl `class'**"
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
				}
				else {
                    dis as res "> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**"
					dis as res "> 查看更多内容请在 Stata 窗口输入代码：**songbl `class',paper**"
                    post songbl_post  ("> 以下内容由 -songbl- 命令生成，安装命令：**ssc install songbl,replace**") 
					post songbl_post  ("> 查看更多内容请在 Stata 窗口输入代码：**songbl `class',paper**") 
				}
				dis as txt "---"	
				post songbl_post  ("---") 				
				use "`html_text_dta'", clear
                qui levelsof seminar_paper , local(seminar_paper) 
				local m=_N
                foreach  seminar_paper  in  `seminar_paper' { 
                    use "`html_text_dta'", clear
                    qui keep if seminar_paper=="`seminar_paper'"
                    qui save "`html_text_seminar_paper_dta'", replace					                    
					qui levelsof style , local(number) 
					foreach  num  in  `number' { 
                        use  "`html_text_seminar_paper_dta'", clear						
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
									dis as w _col(4) "### `seminar_paper' >>"`"{stata "songbl `num'": `num'}"'" 
									post songbl_post  ("### `seminar_paper' >> `num'" ) 							
									`gap' 
									`gap1'
								}
							}    
							forvalues i = 1/`n' {         
								local link=link[`i']
								local title=title[`i']
								cap di wordcount(`"`title': `link'"')
								if _rc==0{
									if `n'==1{
										dis ""
										dis as text `"[`title'](`link')"'								
										post songbl_post  ("") 
										post songbl_post  (`"[`title'](`link')"') 	
										
									}
									else {
										dis as text `"`i'. [`title'](`link')"'
										post songbl_post  (`"`i'. [`title'](`link')"') 	
									}
								}									
							
								`gap'
								`gap1'
							}
						}
					*use "`html_text_dta'", clear
						if missing("`nocat'"){
							post songbl_post  (" " ) 					
							dis ""
						}           
					}
				}		
				post songbl_post  ("## **Stata** 交流群微信：songbl_stata")  				
				dis ""	
				dis as txt "{hline 24} 分享复制以上内容 {hline 24}"	
				if "`paper'"!=""{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',mu p replace"':songbl `class',mu p replace }"'  
					dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',mu p save(txt)"':     songbl `class',mu p save(txt)}"' 
                }
				
				else if "`forum'"!=""{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用" `" {stata `"songbl `class',mu f replace"':songbl `class',mu f replace }"'  
					dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',mu f save(txt)"':     songbl `class',mu f save(txt)}"' 
                }				
				
				else{
					dis as red "{bf:小提示：}多条长链接直接复制会断行。建议使用：" `" {stata `"songbl `class',mu replace"':songbl `class',mu replace }"'
					dis as red _col(9) "利用" `"{browse "https://editor.mdnice.com/": Mdnice }"' "编辑器输出PDF格式"  `" {stata `"songbl `class',mu save(txt)"':       songbl `class',mu save(txt)}"' 
				}
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
				dis as res  _col(4) `"{stata "songbl paper":【快捷查看分类论文】}"'
				dis as res  _col(4) `"搜索共耗时 `timer' 秒"'
				dis as res  _col(4) `"目前北京时间：`cur_time' `c(current_time)' "'
			}
												
		}	
        
        cap erase `"`html_text'.txt"'   
        
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
	copy   `URL' `"`html_text'.`cla'"', replace  
	doedit `"`html_text'.`cla'"'
}

foreach i in  pdf txt docx md .xls .xlsx{
	if "`cla'"=="`i'"{
		local URL `"`git'"'
		tempfile  html_text   
		copy `URL'   `"`html_text'.`cla'"', replace  
		view browse  `"`html_text'.`cla'"'
	}
}

cap erase `"`html_text'.txt"'  
end
*==============================================================================*	
****Sub programs****
*==============================================================================*	

capture program drop sbl
program define sbl
	version 13
syntax anything  (name = pkgname )
	
    tokenize `pkgname'
    local URL "https://songbl-1304948727.cos.ap-guangzhou.myqcloud.com/ado/"
    local PATH     `"`c(sysdir_plus)'"'        
    local path      =substr("`pkgname'",1,1) 
    local PATH     `PATH'\`path'\ 
    cap mkdir `"`PATH'"'        
	local PATH =subinstr("`PATH'","/","\",.) 
	dis as text "the following files will be replaced:"
	dis as text _col(5)   "{bf:`PATH'\`pkgname'.ado}"_n
    dis as text "installing into `PATH'..."
    *sleep 1000
    cap copy  "`URL'`pkgname'.ado"   "`PATH'\`pkgname'.ado"         ,	replace
        while _rc ~= 0 {
			local times = `times' + 1
			sleep 100
			cap copy  "`URL'`pkgname'.ado"   "`PATH'\`pkgname'.ado"     ,replace 
			if `times' > 5 {
				di as err  `"songbl install: "`pkgname'" not found at SONGBL, type {stata ssc install `pkgname'}"'
                di as err  `"(To find all packages at SSC that start with `path', type {stata ssc describe `path'})"'
                exit 601
			}
		}                     
    local cla  hlp  sthlp 
    foreach j in `cla'{
        cap copy  "`URL'`pkgname'.`j'"   "`PATH'\`pkgname'.`j'"       ,replace
    }
    cap copy  "`URL'`pkgname'_cn.sthlp"   "`PATH'\`pkgname'_cn.sthlp"     ,replace 

	dis as text "installation complete."
   
   *local cla  c class css csv dir dlg do docx dta hlp html idlg ihlp ini    ///
    *js mata mlib mo pkl plu plugin png pref py sas scheme stbcal sthlp style ///
    *tex txt zip

end

capture program drop fy
program define fy
version 14.0
syntax anything(name = class)
 qui{
 	tokenize `class'
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
	
	local class "`class'"
	hlp2html, fnames(`class') linesize(200) css("./mystyles.css") replace  ///
	erase  ti(Stata communication group wechat : songbl_stata)
	view browse  `class'.html
 }
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
			if strmatch("`b`a_n`i'''","* *")==1{	
				local browse_stata`i' stata
			}			 				 
			else{
				local browse_stata`i' browse
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
         cap erase `"`html_text'.txt"'              
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
				dis in w  _col(`c1') `"{stata "`b`k1''":`a`k1''}"' _continue
			}
			
			else{
				dis in w  _col(`c1') `"{browse  "`b`k1''":`a`k1''}"'  _continue
			}			
			
			if strmatch("`b`k2''","* *")==1{
				dis in w  _col(`c2') `"{stata "`b`k2''":`a`k2''}"' _continue
			}
			
			else{
				dis in w  _col(`c2') `"{browse  "`b`k2''":`a`k2''}"'  _continue
			}			
			
			if strmatch("`b`k3''","* *")==1{
				dis in w  _col(`c3') `"{stata "`b`k3''":`a`k3''}"' _n
			}
			
			else{
				dis in w  _col(`c3') `"{browse  "`b`k3''":`a`k3''}"'  _n
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

*! Verion: 1.0
*! Update: 2021/5/30 12:32

cap program drop songbl_dir
program define songbl_dir
version 14
syntax [anything(name = paper)][,Gap PATtern(string) Line NOCat MAXdeep(string)] 
preserve  
qui{	
 		tempfile  tempdata2  tempdata3 tempdata4 tempdata5 tempdata6 tempdata7 tempdata8 tempdata9 //可以打印8层文件夹
		if  "`maxdeep'"!=""{
			local maxdeep ="maxdeep(`maxdeep')" 
		}  		
		if  "`pattern'"!=""{
			local pattern ="pattern(`pattern')" 
		}     	
		if "`gap'" != "" {		 
			local gap dis ""
		}	
		n dis ""
		local root_files `c(pwd)'
		cap filelist , `pattern' `maxdeep'
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
					n dis as erro    `"{browse "`root_files'":{bf:>>}}"'  `" {bf:当前目录}"'
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
			n dis as erro    `"{browse "`root_files'":{bf:>>}}"'  `" {bf:当前目录}"' 
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

* Authors:
* Program written by Bolin, Song (松柏林) Shenzhen University , China.
* Wechat:songbl_stata
*! Verion: 1.0
*! Update: 2021/7/21 

* Authors:
* Program written by Song Bolin(松柏林) Shenzhen University , China.
* Wechat:songbl_stata
*! Verion: 1.0
*! Update: 2021/7/21 

capture program drop sblsf
program define sblsf

version 14

 syntax [,Page(numlist integer max=1 min=1 >0 ) CLS Line Gap Mlink Wlink Complete Sort(string)]
	   
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
	
	if ("`mlink'"=="") & ("`wlink'"=="")  {
		preserve		
	}		
	
	clear
	tempfile  html_text  
	cap copy "`url'"  `"`html_text'.txt"', replace
	local times = 0
	while _rc ~= 0 {
		local times = `times' + 1
		sleep 1000
		cap copy `"`url'"' `"`html_text'.txt"', replace
		if `times' > 5 {
			n dis as  text _col(3) `"{browse "`url'":(contacting https://www.statalist.org/forums)}"' 			
			disp as error "Internet speeds is too low to get the data"
			exit 601
		}
	}
	
    infix strL v 1-100000 using `"`html_text'.txt"', clear
    keep if index(v, "js-topic-title") | index(v, "posts-count") | index(v, "views-count")| index(v, "post-date") | ///
			index(v, "Started by") | index(v[_n-2], `"<div class="lastpost-by">"')
	gen id = int((_n - 1)/6) + 1 
	egen year = seq(), from(1) to(6) 
	reshape wide v, i(id) j(year) 
	drop id	
	split v1, p(`"<a href=""' `"" class="topic-title js-topic-title">"' "</a>" )
	split v2, p(`"Started by <a href=""' `"">"' `"</a>, <span class="date">"' `"</span>"')	
	replace v3 = ustrregexra(v3, ",","")  
	replace v4 = ustrregexra(v4, ",","")  
	gen post = ustrregexs(0) if ustrregexm(v3, "\d+$")
	gen view = ustrregexs(0) if ustrregexm(v4, "\d+$")
	split v5, p(`"by <a href=""' `"">"' "</a>")
	split v6, p(`"<span class="post-date">"'  "</span>")
	rename (v12 v13 v22 v23 v24 v52 v53  v62)(link title  start_author_link start_author start_date post_author_link post_author post_date  )
	*replace title = ustrregexra(title, `"""',"") 
	*replace title = ustrregexra(title, "`","") 
	*replace title = ustrregexra(title, "'","") 
	cap keep post view link title  start_author_link start_author start_date post_author_link post_author post_date 
	compress
	keep in -50/-1
	local n=_N 	
	local col1 = 4
	local col2 = 10
	local col3 = 16
	local col4 = 23 
	
	local col11 = 90
	local col22 = 110
	local col33 = 130
	local col44 = 150
    n dis   as  text   "{center:The Stata Forums}" 	
    n dis as txt "{hline}"	
	
	if "`complete'"!=""{
		n dis in text _col(`col1') "{bf:ID}" _col(`col2') "{bf:Posts}" _col(`col3') "{bf:Views}" _col(`col4') "{bf:Topics}" _col(`col11') "{bf:Posted By}" _col(`col22') "{bf:Post Date }" _col(`col33') "{bf:Started By}" _col(`col44')  "{bf:Started Date}"
	}
	
	else{
		n dis in text _col(`col1')  "{bf:ID}" _col(`col2') "{bf:Posts}"  _col(`col3') "{bf:Views}"  _col(`col4')  "{bf:Topics}" 
	}
	
	n dis as txt "{hline}"			
	forvalues i = 1/`n' {         
		local link =link[`i']
		local title=title[`i']
		local post =post[`i']	
		local view =view[`i']	
		local start_author_link=start_author_link[`i']
		local start_author=start_author[`i']
		local start_date=start_date[`i']
		local post_author_link=post_author_link[`i']
		local post_author=post_author[`i']
		local post_date=post_date[`i']	
		
		if "`complete'"==""{
			n dis as text  _col(`col1') `"{browse `"`link'"':`i' }"'  _col(`col2') "`post'"  _col(`col3') "`view'" _col(`col4') `"`title'"' 
		}			
		else{
			n dis as text  _col(`col1') `"{browse `"`link'"':`i' }"'  _col(`col2') "`post'"  _col(`col3') "`view'" _col(`col4') `"`title'"' 
			n dis as text  _col(`col11') `"{browse `"`post_author_link'"':`post_author'}"'    _col(`col22') "`post_date'"  _col(`col33') `"{browse `"`start_author_link'"':`start_author' }"' _col(`col44') `"`start_date'"'  
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

	if "`wlink'"!=""{
		gen wlink = link+"："+title
		br wlink
	}
				
	if "`mlink'"!=""{
		gen mlink ="- "+"["+title+"]"+"("+link+")"
		br mlink
	}	
}
	if ("`mlink'"=="") & ("`wlink'"=="") {
		restore		
	}			
 end

capture program drop cie
program define cie

version 14

 syntax anything(name = class)
 
		preserve
	    qui if "`cie'"!=""{
			tempfile  html_text
			local url https://note.youdao.com/yws/api/personal/file/A591767E58A84994B25171581E136448?method=download&shareKey=a00a0dca31ca8cd8025a890286f08cc3
			cap copy `"`url'"' `"`html_text'.txt"', replace  
			infix strL v 1-100000 using `"`html_text'.txt"', clear 
			cap erase `"`html_text'.txt"' 
			gen n=_n
			gen title=v if index(v[_n-1],"**#论文标题：") 
			replace title=title[_n+10]
			gen id=n if index(v[_n+9],"**#论文标题：") 
			carryforward title id,replace
			bysort id:gen gap=_n
			levelsof id
			gen num=.
			local j=1
			foreach num in `r(levels)'{
				replace num=`j' if id==`num'
				local j=`j'+1
			}
			tostring num ,replace
			gen cie="cie"+num
			*gen id=n if title!=""
			gen row=1  if strmatch(v,"*`class'*")
			keep if row==1
			cap duplicates drop id, force
			if _rc!=0{
				dis as error "《中国工业经济》代码没有发现相关内容"
				exit
			}
			local n=_N
			n dis as w `" 代码 >>"' `"{stata "songbl 论文代码": 论文代码}"'
			forvalues i =1/`n'{
				local cie  =cie[`i']
				local title=title[`i']
				n dis in text _col(4)  "{stata sbldo `cie':`title'}"
				n `gap'
			}	
			n dis ""
			exit
		}	
		restore
end
*! Verion: 3.0
*! Update: 2021/1/20 12:32



*! Verion: 4.0
*! Update: 2021/3/16 06:35
*1 增加了 NOCat Mlink  MText Navigation
*2 把论文与推文分开储存，提高搜索速度
*3 增加动态导航功能。


*! Verion: 5.0
*! Update: 2021/4/12 
*1 增加了 SAVE(string) 功能，利用文档打开分享的内容。
*2 增加了 REPLACE 功能，生成分享内容的 STATA 数据集。      
*3 增加了 TIME 功能，输出检索结果的末尾带有返回推文分类目录或者论文分类目录的快捷方式。
*4 更改了分享功能的输出风格。


*! Verion: 6.0
*! Update: 2021/5/18 
*1 修复了在stata 17上批量获取导航链接的错误。
*2 修复了置顶推文发生的错误。      
*3 分享推文时，删除了非链接的资源。
*4 修复了无法同时使用命令与链接的错误，例如 use www.xxx.dta
*5 上线了资源上传分享的功能
*6 资源类型从专题到论文，更变为推文、论文、数据、视频等
*7 更改了songbl new 的输出风格。
*8 增加了划线输出风格。line	

*! Verion: 6.0
*! Update: 2021/6/18
*1 增加了外部命令的译文搜索：songbl new,ssc。

*! Verion: 7.0
*! Update: 2021/7/1
*1 增加了外部命令的网页翻译：songbl merge,fy
*2 增加了电脑文件的搜索：songbl *.pdf, dir
*3 songbl care
*4 songbl r
*5 songbl music 

*! Verion: 8.0
*! Update: 2021/8/1
*1 增加了 The Stata Forums 帖子资源：songbl did,f
*2 增加了 The Stata Forums 帖子资源：songbl new,f
*3 修复了一些错误
