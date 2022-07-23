* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@zuel.edu.cn)
* Yizhuo Fang, China Stata Club(爬虫俱乐部)(13608671126@163.com)
* January 23rd, 2022
* Program written by Dr. Chuntao Li and Yizhuo Fang
* Carry out a standard market model event study with Chinese publicly listed firms and calculate the abnormal returns and cumulative abnormal returns for each event.
* Can only be used in Stata version 16.0 or above


cap program drop cnevent

program define cnevent
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

    syntax varlist(max=2 min=2) [,estw(string) eventw(string)  car(string) ar(string) index(string) estsmpn(int 50) filename(string) carg(string) t(string)] 
	qui{
	    tempname stkcd eventdate est_window_s est_window_e eve_window_s eve_window_e eve temp1 abss a  temp2 event_n temp3 file option temp4 stk Event_date num before dol y ynum AR_t
	    tokenize "`varlist'"
	    local `stkcd' `1'
	    local `eventdate' `2'
	
	    if `"`estw'"' == ""{
	      local estw "-200,-10"
	    }
	    tokenize "`estw'",parse(",")
	    local `est_window_s' = `1'
	    local `est_window_e' = `3'
	
	    if `"`eventw'"' == ""{
		    local eventw "-3,5"
	    }
		
		forvalues `eve'=1(1)100{
		    tokenize "`eventw'"
		    if `"```eve'''"' == ""{
			    tempname end
			    local `end' =``eve''-1
			    continue,break
			}
		    tempname eve_window_s``eve'' eve_window_e``eve''
            tokenize "```eve'''",parse(",")
		    local `eve_window_s``eve''' `1'
		    local `eve_window_e``eve''' `3'
			 if ``eve_window_s``eve'''' > ``eve_window_e``eve''''{
			  	disp as error "Your Event window is invalid"
	            exit 198   
			 }
		}
		
		
		if ``end'' > 1 {
		local ma ``eve_window_e1''
		local mi ``eve_window_s1''
	    forvalues e=2(1)``end''{
        local ma "`ma',``eve_window_e`e'''"
		local mi "`mi',``eve_window_s`e'''"
		}
		local `eve_window_e' = max(`ma')
        local `eve_window_s' = min(`mi')  
		}
		else{
		local `eve_window_e' ``eve_window_e1''
        local `eve_window_s' ``eve_window_s1''  	    
		}

	
	
        if `"`ar'"' == ""{
			    local ar AR
	    }
	
	    if `"`car'"' == ""{
		    local car CAR
	    }
	    if `"`index'"' == ""{
		    local index 300
	    }
	    if `"`filename'"' == "" {
		    local filename "CAR,replace"
	    }
	    tokenize "`filename'", parse(",")
	    local `file' `1'
	}
    if``est_window_s'' >=0 |``est_window_e'' >=0   {
	    disp as error "Your Estimation window must be before the event date "
	    exit 198
    }
	
    if ``est_window_s''>=``est_window_e'' {
	    disp as error "Your Estimation window is invalid"
		exit 198
    }
	
    if ``eve_window_s'' < ``est_window_e'' {
	    disp as error "Your Estimation window must be before the event date"
	    exit 198
    }
	
    if ``eve_window_s''> 0 {
	    disp as error "Your Event window must contain the event date"
	    exit 198
    }
	
    if ``eve_window_s'' >= ``eve_window_e'' {
	    disp as error "Your Event window is invalid"
	    exit 198
    }
	qui{
        mkf `temp1' ``stkcd'' ``eventdate''   
	
        frame `temp1':{
            local `a'  =  ``eve_window_s''
        
            while ``a'' <= ``eve_window_e'' {
		    	while ``a'' < 0 {
			    	gen `ar'=.
					label var `ar' "AR(``a'')"
			        local `abss'=abs(``a'')
                    rename `ar' `ar'n``abss''
			    	local `a' = ``a'' + 1 
		    	}
		    	gen `ar' =.
				label var `ar' "AR(``a'')"
		    	rename `ar' `ar'``a''
		    	local `a' = ``a'' + 1 
		    }
        }
        frame copy default `temp2' 
   
        frame `temp2': {
            cap confirm str# variable ``eventdate'' 
        
		    if _rc==0 {
	            gen ``eventdate''1=date(``eventdate'',"YMD")
	            drop ``eventdate''
	            rename ``eventdate''1 ``eventdate''
	            format ``eventdate'' %dCY-N-D
	        }
		      cap confirm str# variable ``stkcd'' 
        
	    	if _rc==0 {
		    	gen ``stkcd''1 = real(``stkcd'')
		    	drop ``stkcd''
	            rename ``stkcd''1 ``stkcd''
	        }
            local `event_n' = _N
        }
        mkf `temp3' 
        frame `temp3':{
            cntrade `index', index
            keep date rmt
        } 
	    while length("`index'")<6{
           local index 0`index'
        }
	    rm `index'.dta
        mkf `temp4'  
        cwf `temp4'
	}	
	    forvalues s = 1/``event_n'' {
			qui{
                local `stk' = _frval(`temp2', ``stkcd'', `s')
                cap cntrade ``stk''
				if _rc>0{
				continue	
				}
		        while length("``stk''")<6{
                    local `stk' 0``stk''
                }
	    	    rm ``stk''.dta   
                keep date rit
                frlink 1:1 date, frame(`temp3')
                frget rmt,from(`temp3')
                drop `temp3'
                local `Event_date' = _frval(`temp2', ``eventdate'', `s')
				local `dol' date[1]
			}
	         if ``Event_date'' < ``dol'' {
		        disp  "Your eventdate of ``stk'' before the date of listing"
			    continue
	         }
			qui{
                preserve
                keep if date<``Event_date''
                gsort -date
                gen time= -_n
                save `before', replace
				local `y' = ``Event_date''-365
				keep if date > ``y''
				local `ynum' = _N
                restore
                keep if date>= ``Event_date''
                sort date  
                gen time = _n-1
                append using `before'
	    	    rm `before'.dta
                sort time
                keep if time>=``est_window_s'' & time<=``eve_window_e''
				local `num' = ``eve_window_e''-``eve_window_s''+1
                local `AR_t' "(`ar'[1])"
                forvalues i = 2(1)``num'' {
                    local `AR_t' "``AR_t'' (`ar'[`i'])"
                }
	    	    if ``ynum'' >= `estsmpn' {
                    reg rit rmt if time <= ``est_window_e''
                    predict `ar' if time >= ``eve_window_s'', res
                    keep if time >= ``eve_window_s''
                    frame post `temp1' (``stk'') (``Event_date'') ``AR_t''
		        }
			   
                else{
			       keep if time >= ``eve_window_s''
				   gen `ar'= . 
			       frame post `temp1' (``stk'') (``Event_date'') ``AR_t''
			    }
			} 
			
			disp "current working on stock code:  ``stk'', event date:" %dCY-N-D ``Event_date'' ", `s'/``event_n''"
		}	 
    qui{
        cwf `temp1'
	    format ``eventdate'' %dCY-N-D
		preserve
		collect clear
		forvalues enum = 1(1)``end''{
		    tempname c d s e
		    if ``eve_window_s`enum''' < 0{
		    local `c'=abs(``eve_window_s`enum''')
		    local `d' `ar'n``c''
		    }
		    else{
		    local `c'=``eve_window_s`enum'''
		    local `d' `ar'``c''
		    }
            local `s' = ``eve_window_s`enum'''+1
		    forvalues `e' = ``s''(1)``eve_window_e`enum''' {
				if ``e''<0 {
				    local `e'=abs(``c'')
				    local `d' "``d'' + `ar'n``e''"
				    continue
				}
		        local `d' "``d'' + `ar'``e''"
            }
		    gen `car'``c''``eve_window_e`enum'''= ``d''
		    label var `car'``c''``eve_window_e`enum''' "CAR[``eve_window_s`enum''',``eve_window_e`enum''']"	
		    if `"`t'"' == ""{
			    continue
		    }
		    else{
		        collect get: ttest `car'``c''``eve_window_e`enum''' == 0
			    local  t`enum' "`enum' "(``eve_window_s`enum''',``eve_window_e`enum''')" "
				
		    }
		    }

	    save ``file''.dta,replace
		if `"`t'"' != ""{
		local tn `t1'
        forvalue tnum = 2(1)``end''{
             local tn "`tn'`t`tnum''"
        }
          
        collect label levels cmdset `tn',modify
        collect style cell, nformat(%9.4f) halign(center) font("Times New Roman")
        collect label levels result mu_1 "mean" t "t", modify
        collect layout (cmdset) (result[mu_1 t])
        putdocx begin
        putdocx collect
        putdocx save `t'.docx, replace
		}
		restore
		if `"`carg'"' !=""{
		tempname c d s n name type
		if ``eve_window_s'' < 0{
		local `c'=abs(``eve_window_s'')
		local `d' `ar'n``c''
		gen `car'n``c'' = ``d''
		sum `car'n``c''
		replace `car'n``c'' = r(mean)
		}
		else{
		local `c'=``eve_window_s''
		local `d' `ar'``c''
		gen `car'``c'' = ``d''
		sum `car'``c''
		replace `car'``c'' = r(mean)
		}
        local `s' = ``eve_window_s''+1
		forvalues `c' = ``s''(1)``eve_window_e'' {
				if ``c''<0 {
				    local `c'=abs(``c'')
				    local `d' "``d'' + `ar'n``c''"
				    gen `car'n``c'' = ``d''
				    sum `car'n``c''
				    replace `car'n``c'' = r(mean)
				    continue
				}
		    local `d' "``d'' + `ar'``c''"
		    gen `car'``c'' = ``d''
		    sum `car'``c''
		    replace `car'``c'' = r(mean)	
		    } 
		keep `car'*
		keep in 1
		xpose,clear
		gen v2 = ``eve_window_s''
		local `d' ``eve_window_s''
		local `n' = ``eve_window_e'' - ``eve_window_s''+1
		forvalue `c' = 2(1)``n''{
				local `d' = ``d''+1
				replace v2 = ``d'' in ``c''
		}
		rename (v1 v2) (`car' ``eventdate'')
		if ``eve_window_s'' < 0{
		twoway line `car' ``eventdate'' ,ytitle(`car'%) xline(0,lc(red))
		}
		else{
		twoway line `car' ``eventdate'' ,ytitle(`car'%)     
		}
	   		tokenize "`carg'", parse(",")
			local `name' `1'
			if `"`3'"' != ""{
				local `type' `3'
	    		graph export ``name''.``type'', replace
			}
			else{
				graph save ``name''.gph, replace	
			}
		}

	}
	cwf default
	use "``file''",clear
    end
	
