* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@zuel.edu.cn)
* Yizhuo Fang, China Stata Club(爬虫俱乐部)(yzhfang1@163.com)
* January 3rd, 2023
* Program written by Dr. Chuntao Li and Yizhuo Fang
* Draw a Candlestick Chart with the Chinese listed stock code or index.
* Can only be used in Stata version 17.0 or above

cap program drop cnkchart
program define cnkchart
	version 17
    qui cap findfile cntrade.ado
    if  _rc>0 {
		disp as error "command cntrade is unrecognized,you need "ssc install cntrade" "
		exit 601
	} 
	if _caller() < 17.0 {
		disp as error "this is version `=_caller()' of Stata; it cannot run version 17.0 programs"
		exit 9
	}
	
	syntax anything(name = stkcd) [, traday(string) filename(string)  index week month]
	
    tempname  i t a1 a2 a3 a4 a5 a6  tradaye tradayn MA5line MA10line MA20line MA30line name type date1 date2 ltw ltm

	if	`"`week'"' != "" &  `"`traday'"' != ""{
			disp as error "You need to use option traday() and option week separately"
			exit 601		
	}
	
	if	`"`month'"' != "" &  `"`traday'"' != ""{
			disp as error "You need to use option traday() and option month separately"
			exit 601		 
	}
	
	if `"`week'"' == ""{
		local `ltw' = 0	
	}
	else{
		local `ltw' = 1	
	}
	
	if `"`month'"' == ""{
		local `ltm' = 0		
	}
	else{
		local `ltm' = 1	
	} 
		
	if `"`traday'"' != ""{
		tokenize "`traday'", parse(",")
		local `tradaye': disp date("`1'","YMD")
		if `"`3'"' != "" {     
			local `tradayn' `3'
		}
		else{
			local `tradayn' 91
		}
			
		if ``tradaye'' > date("`c(current_date)'", "DMY") {
			disp as error %dCY-N-D ``tradaye'' " is an invalid date"
			exit 601			
		} 
	}
	qui{
	    if `"`index'"' == ""{
			cntrade `stkcd'
		}
		else{
			cntrade `stkcd',index	
		} 
		
		while length("`stkcd'")<6{
			local stkcd 0`stkcd'
		}
		rm `stkcd'.dta
	}
	
	if `"`traday'"' != ""{
		local `date1' date[1]
		if ``tradaye'' <``date1'' {
			disp as error "Your trading date lies before the IPO date"
			exit 601			
		} 
	}
	
	qui{
		if ``ltw'' == 1{
		    gen week = mod((date-2),7)
            gen week1 = int((date-2)/7)+1
		    gen month =month(date)
		    bysort week1:gen opnprc1=opnprc[1]
		    bysort week1:gen clsprc1=clsprc[_N]
		    bysort week1:egen hiprc1 = max(hiprc)
		    bysort week1:egen lowprc1 = min(lowprc)
		    bysort week1: gen n = _n 
		    bysort week1: keep if n == n[_N]
		    drop opnprc clsprc hiprc lowprc
		    rename (opnprc1 clsprc1 hiprc1 lowprc1) (opnprc clsprc hiprc lowprc)
		}
		
		if ``ltm'' == 1{
		    gen month =month(date)
		    gen year =year(date)
		    bysort year month: gen n = _n 
		    bysort year month:gen opnprc1=opnprc[1]
		    bysort year month:gen clsprc1=clsprc[_N]
		    bysort year month:egen hiprc1 = max(hiprc)
		    bysort year month:egen lowprc1 = min(lowprc)
		    bysort year month: keep if n == n[_N]
		    drop opnprc clsprc hiprc lowprc
		    rename (opnprc1 clsprc1 hiprc1 lowprc1) (opnprc clsprc hiprc lowprc)	
		}
		
		gen `t' = _n
		sort `t'
		tsset `t' //设定变量t为时间序列数据
		local `a1' clsprc+l.clsprc+l2.clsprc+l3.clsprc+l4.clsprc    //生成局部宏`a1'等于变量clsprc当期观测值与滞后一期、两期、三期、四期观测值之和
		local `a2' l5.clsprc+l6.clsprc+l7.clsprc+l8.clsprc+l9.clsprc
		local `a3' l10.clsprc+l11.clsprc+l12.clsprc+l13.clsprc+l14.clsprc
		local `a4' l15.clsprc+l16.clsprc+l17.clsprc+l18.clsprc+l19.clsprc
		local `a5' l20.clsprc+l21.clsprc+l22.clsprc+l23.clsprc+l24.clsprc
		local `a6' l25.clsprc+l26.clsprc+l27.clsprc+l28.clsprc+l29.clsprc


			gen MA5 = (``a1'')/5  //5日均价
			local `MA5line' "(line MA5 num, lcolor(pink))"   

			gen MA10 = (``a1''+``a2'')/10  //10日均价
			local `MA10line' "(line MA10 num, lcolor(blue))"  

			gen MA20 = (``a1''+``a2''+``a3''+``a4'')/20  //20日均价
			local `MA20line' "(line MA20 num, lcolor(purple))"   

    		gen MA30 = (``a1''+``a2''+``a3''+``a4''+``a5''+``a6'')/30  //30日均价
    		local `MA30line' "(line MA30 num, lcolor(green))"   
	}

	if `"`traday'"' == ""{
    	if _N > 90 {
        qui	keep in -90/-1
		} 
    	else{
			disp as error "The number of observations(" _N ") is less than default(90), please reset by option traday()"
			exit 601
		}	
	}
	else{
		qui keep if date <= ``tradaye''
		if _N > ``tradayn'' {
       	qui	keep in -``tradayn''/-1
		}
    	else{
			disp as error "The range set by option traday() is invalid "
			exit 601
		}
	}

	qui{
	    gen num = _n
		twoway (rspike hiprc lowprc num if opnprc<clsprc, lcolor(red) lwidth(*0.5))  ///
    	(rspike hiprc lowprc num if opnprc>clsprc, lcolor(green) lwidth(*0.5))  ///
		(rspike hiprc lowprc num if opnprc==clsprc, lcolor(black) lwidth(*0.5))  ///
    	(rspike clsprc opnprc num if opnprc<clsprc, lcolor(red) lwidth(*2))  ///
    	(rspike opnprc clsprc num if opnprc>clsprc, lcolor(green) lwidth(*2))  ///
		(rspike opnprc clsprc num if opnprc==clsprc, lcolor(black) lwidth(*2))  ///
    	``MA5line'' ``MA10line'' ``MA20line'' ``MA30line'',  ///
    	xtitle(Date, place(right)) ytitle(Price, place(top))  ///
    	legend(order(7 "MA5" 8 "MA10" 9 "MA20" 10 "MA30")   position(6)) ///
		xlabel(1,format(%tdCCYY-NN-DD) angle(30) )
		
		local m: disp %dCY-N-D date[1]
	 
	    local x: disp int(_N/4)
	    local x1: disp %dCY-N-D date[`x']
	 
	    local y: disp int(_N/2)
	    local y1: disp %dCY-N-D date[`y']
	 
	    local z: disp int(_N/4)*3
	    local z1: disp %dCY-N-D date[`z']
	 
	    local w: disp _N
	    local w1: disp %dCY-N-D date[_N]
		gr_edit .xaxis1.edit_tick 1 1 `"`m'"', tickset(major)
        gr_edit .xaxis1.add_ticks `"`x'"' `"`x1'"', tickset(major)
        gr_edit .xaxis1.add_ticks `"`y'"' `"`y1'"', tickset(major)
        gr_edit .xaxis1.add_ticks `"`z'"' `"`z1'"', tickset(major)
        gr_edit .xaxis1.add_ticks `"`w'"' `"`w1'"', tickset(major)
	
		if `"`filename'"' !=""{
	   		tokenize "`filename'", parse(",")
			local `name' `1'
			if `"`3'"' != ""{
				local `type' `3'
	    		graph export ``name''.``type'', replace
			}
			else{
				graph save ``name''.gph, replace	
			}
		}
		else{
			graph save `stkcd'.gph, replace	
		}
	}
clear
end