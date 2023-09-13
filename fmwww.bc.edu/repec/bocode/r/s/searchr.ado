*! Version 1.0 - 15 July 2022
*! By Wanhai You, Fuzhou University, China
*! Please email ywhfzu@163.com for help and support


cap program drop searchr
program define searchr,rclass
version 15.0      
syntax [anything(name=text)] [,NSimilar(numlist) matchit]
        
      if ("`nsimilar'"=="") {
           local nsimilar 15       
      }
	  
	  //copy the data from website
	  tempfile simple123
	  capture noisily copy https://mirrors.tuna.tsinghua.edu.cn/CRAN/web/packages/available_packages_by_date.html "`simple123'.txt",replace //可以多列几个网址
	  if _rc !=0 {
	      dis in red _n "Note: try another source" 
	      copy https://cran.r-project.org/web/packages/available_packages_by_date.html "`simple123'.txt",replace
	  }
	  
	  // import the data
	  qui import delimited using "`simple123'.txt",clear
	  
	  // transfer the numeric variables to character variables
	  qui ds, has(type numeric)
	  foreach var in `r(varlist)' {
	      qui tostring `var',force replace
	  }
	  qui describe v*
	  local n_v = r(k)
	  tempvar all_v 
	  qui gen `all_v' = v1
	  forval j = 2/`n_v' {
          qui replace `all_v' = cond(`all_v' == "", v`j', `all_v' + v`j') if v`j' != ""
      }
      qui keep `all_v' 
	  tempvar m_index
      qui gen `m_index' = ustrregexm(`all_v',"</td> </tr>")
	  
	  // drop the last n obs
      qui drop if inrange(_n,_N-3,_N)
      tempvar m_total
      qui gen `m_total' = sum(`m_index')
      qui drop if `m_total' ==0
      qui replace `all_v' = substr(`all_v', 1, strlen(`all_v') - 4)  // delete the last ... 

      qui drop `m_total'
      tempvar id_index
      qui gen `id_index' = _n
      qui gsort -`id_index'
	  tempvar m2_total
      qui gen `m2_total' = sum(`m_index')

      qui bys `m2_total': replace `all_v' = `all_v' + " "+ `all_v'[_n-1] if _n>=1 // concact multiple obs to one

      qui drop if `m_index'[_n+1]==0
      qui keep `all_v'
      tempvar package_date package_name package_des package_web
      qui gen `package_date' = ustrregexs(0) if ustrregexm(`all_v',"[0-9]{4}-[0-9]{2}-[0-9]{2}")    // extract the published date
      qui gen `package_name' = ustrregexs(4) if ustrregexm(`all_v',`"(.+)(.html")(>)(.+)(</a>)(.+)"')   // extract the package name
      qui gen `package_des' = ustrregexs(3) if ustrregexm(`all_v',`"(.+)(</a> </td> <td>)(.+)(</td> </tr>)"')  // extract the package description
      qui gen `package_web' = ustrregexs(3) if ustrregexm(`all_v',`"(.+)(href="../../)(.+)(html)(.+)"')  //extract the package website
      qui replace `package_web' = "https://cran.r-project.org/" + `package_web' + "html" if `package_web'!=""
	  qui drop if `package_web'==""
      
	  local class `text'
	  tempvar match_v
	  gen `match_v' = "`class'"
	  
	  //if matchit option is specified, the matchit approach is used!
      if ("`matchit'"!=""){
	     qui matchit `package_des' `match_v'
		 qui gsort -similscore
		 forvalues j = 1/`nsimilar' {
		     local links = `package_web'[`j']
			 local pnames = `package_name'[`j']
			 dis in w " `pnames' "  `"          {browse `"`links'"': `Lbb'`pnames'`Rbb'   }"'
         }
		 qui drop similscore
	  }
	  else {  //otherwise, match by using the number of words
          tempvar newvar1
          qui gen `newvar1' = ustrregexra(`match_v',"\w+","($0s?)\\b")

          qui split `newvar1',parse(" ")
          qui drop `newvar1'
	  
          tempvar want1
          qui gen `want1' = 0
          foreach f of varlist `r(varlist)'{
             qui replace `f'="NA" if `f'==""
             qui replace `want1' = `want1' + 1 if ustrregexm(`package_des', `f',1) 
          }
         qui replace `package_des'= subinstr(`package_des', `"""',  "", .)
		 tempvar nw
         //qui egen `nw' = nwords(`package_des')
	     qui gen `nw' = wordcount(`package_des')
		 tempvar ratio
         qui gen `ratio' = cond(`want1'/`nw' >1, 1, `want1'/`nw')
         qui gsort -`ratio'

         forvalues j = 1/`nsimilar' {
            local links = `package_web'[`j']
            local pnames = `package_name'[`j']
            dis in w " `pnames' "  `"     {browse `"`links'"': `Lbb'`pnames'`Rbb'   }"'
         }
	} //end if
end
	
	
