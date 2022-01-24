* Authors:
* Chuntao Li, Ph.D. , China Stata Club(爬虫俱乐部)(chtl@zuel.edu.cn)
* Yizhuo Fang, China Stata Club(爬虫俱乐部)(13608671126@163.com)
* January 23rd, 2022
* Program written by Dr. Chuntao Li and Yizhuo Fang
* Carry out a standard market model event study with Chinese publicly listed firms and calculate the abnormal returns and cumulative abnormal returns for each event.
* Can only be used in Stata version 16.0 or above


cap program drop cnevent

program define cnevent
	version 16
    qui cap findfile cntrade.ado
    if  _rc>0 {
		disp as error "command cntrade is unrecognized,you need "ssc install cntrade" "
		exit 601
	} 
	if _caller() < 16.0 {
		disp as error "this is version `=_caller()' of Stata; it cannot run version 16.0 programs"
		exit 9
	}	

    syntax varlist(max=2 min=2) [,estw(numlist max=2 min=2 int) eventw(numlist max=2 min=2 int) car(string) ar(string) index(string) estsmpn(int 50) filename(string)]
	qui{
	    tempname stkcd eventdate est_window_s est_window_e eve_window_s eve_window_e temp1 abss a  temp2 event_n temp3 file option temp4 stk Event_date num1 num before
	    tokenize "`varlist'"
	    local `stkcd' `1'
	    local `eventdate' `2'
	
	    if `"`estw'"' == ""{
	      local estw "-200 -10"
	    }
	    tokenize "`estw'"
	    local `est_window_s' = `1'
	    local `est_window_e' = `2'
	
	    if `"`eventw'"' == ""{
		    local eventw "-3 5"
	    }
	    tokenize "`eventw'"
	    local `eve_window_s' = `1'
	    local `eve_window_e' = `2'
	
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
        local `option' `2'`3'
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
                cntrade ``stk''
		        while length("``stk''")<6{
                    local `stk' 0``stk''
                }
	    	    rm ``stk''.dta   
                keep date rit
                frlink 1:1 date, frame(`temp3')
                frget rmt,from(`temp3')
                drop `temp3'
                local `Event_date' = _frval(`temp2', ``eventdate'', `s')
                preserve
                keep if date<``Event_date''
                gsort -date
                gen time= -_n
                save `before', replace
                restore
                keep if date>= ``Event_date''
                sort date  
                gen time = _n-1
                append using `before'
	    	    rm `before'.dta
                sort time
                keep if time>=``est_window_s'' & time<=``eve_window_e''
				local `num' = ``eve_window_e''-``eve_window_s''+1
		    	tempname AR_t
                local `AR_t' "(`ar'[1])"
		
                forvalues i = 2(1)``num'' {
                    local `AR_t' "``AR_t'' (`ar'[`i'])"
                }
				preserve
				keep if time <= ``est_window_e''
		        local `num1' = _N
				restore
	    	    if ``num1'' >= `estsmpn' {
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
	    egen `car' = rowtotal(`ar'*)
		label var `car' "CAR[``eve_window_s'',``eve_window_e'']"
	    replace `car' = . if `car' == 0
	    save ``file''.dta``option''
	    cwf default
	}
    end
	