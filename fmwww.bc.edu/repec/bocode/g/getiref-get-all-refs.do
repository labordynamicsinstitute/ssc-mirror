*----------------------------------------
*----------------------------------------
*
* Get citation information for all references of a paper
*
*           v: 2024/7/12 12:59
*----------------------------------------
*----------------------------------------

*  Including:
*    Citation links,
*    PDFs,
*    .ris / .bibtex files for importing into Endnote and other reference management software

* Author: Yujun Lian, arlionn@163.com, 2024/1/15 20:16
*
* Github repository URL：
  view browse "https://gitee.com/arlionn/getiref"
  
  
  
*======================================================  
*============ A. Parameter Settings ================ begin ======
*======================================================

  *-~~~~~~~ Insert the DOI of the literature to be retrieved here ~~~~~~~~(!!!! important !!!! )
  global DOI "10.1007/s11205-014-0747-y" 
  *           ------------------


  
* The following content generally does not need to be modified

*-Whether to download PDF files and .ris, .bibtex documents
//  global pdf "pdf"
//   global bib "bib"
  global bib ""
  global md  "md"   // Options: md, text, latex 
  
* Clear screen (optional, comment out if not needed)
  cls 

*-Storage path: Path name to store PDF files (if it does not exist, it will be created automatically)
* global Root "D:/_temp_getiref" 
//   global Root "D:\stata\personal\adolian\getiref"
  global Root "D:\JG\助教推文提交\2020助教推文\refs"
  
  qui getiref $DOI, path($Root)
  global filename "`r(author1)'_`r(year)'"
  global path "$Root/$filename"  // Folder for jth paper
  !md "$path"
  cd  "$path"   
  
*======================================================  
*============ A. Parameter Settings ================ over =======
*======================================================



* The following content generally does not need to be modified


*-Install getiref command (ignore these two lines if already installed)
  cap which cnssc
  if _rc   ssc install cnssc, replace 
  cap which getiref
  if _rc   cnssc install getiref, replace 

*-Retrieve data and save as .txt and .dta data
  //   local type "citations"  // Citation, temporarily unavailable
  local type "references"   // References
  local type "citations"
  local api_url "https://opencitations.net/index/coci/api/v1/`type'"   
  local url "`api_url'/$DOI"
  
  qui copy `"`url'"'  "doi_ref.txt", replace 

  qui infix strL v 1-1000 using "doi_ref.txt", clear

  if _N == 1{
      dis as error "No observation"
  }
  
  qui save "doi_ref_OpenCitation.dta", replace  
  

*-----------------
*-Type: references
*-----------------

qui{      // qui ----------------------- begin -----------------
    
  use "doi_ref_OpenCitation.dta", clear 
  
  gen Is_cited = strpos(v, "cited") 
  keep if Is_cited==1 
  
*-get DOI
  clonevar DOI = v
  replace  DOI = subinstr(DOI, `"cited": ""', "", .)  
  replace  DOI = subinstr(DOI, `"","', "", .)  
  
*-get references text using -getiref.ado-  
  
  local N  = _N
  gen strL ref_out = ""
  gen strL ref_dis = ""
  gen fail = 0
  
  local n_ok = 0
  forvalues i = 1/`N'{
      local doi = DOI[`i']

   // ~~~~~~~~~ Energine ----------------------  
      cap noi getiref `doi', path("$path") $md $bib $pdf clipoff notip   
   // ~~~~~~~~~ Energine ----------------------  
   
      if _rc==0{
          qui replace ref_out = "- `r(ref)'" in `i'
          qui replace ref_dis = `"`r(ref_link_pdf_full)'"' in `i'
          local n_ok = `n_ok' + 1 // number of references found sucessfully
      }
      else{ // Errors need to be classified here; some cannot get bib, some cannot get PDF
          qui replace fail = 1 in `i'
          dis as error "failed to get metadata for {DOI}: `doi'"
      }
  }  
     
     
*---------------------
*- Display and Export 
*---------------------

* Note: This part can be executed repeatedly to quickly reproduce the results
  sort ref_out 
  
  // local item "-"
  local n_ok = _N   
  
  forvalues i = 1/`n_ok'{
  
      noi dis "`i'.`item' " ref_dis[`i']
   
  }  

  
*-Export as Markdown document
    local path : pwd
    local saving "${filename}.md"
    
    qui export delimited ref_out using `"`path'/`saving'"' , ///
    	       novar nolabel delimiter(tab) replace
    local save "`saving'"   
    	    noi dis " "
    		noi dis _dup(58) "-" _n ///
    				_col(3)  `"{stata `" view  "`path'/`save'" "': View}"' ///
    				_skip(4) `"{stata `" !open "`path'/`save'" "' : Open_Mac}"' ///
    				_skip(4) `"{stata `" winexec cmd /c start "" "`path'/`save'" "' : Open_Win}"' ///
                    _skip(4) `"{browse `"`path'"': dir}"'
            noi dis _dup(58) "-"

}      // qui ----------------------- over -----------------  
  
*-Statistics
  dis in red ">>>>>>>>>>>>"
  dis `"{cmd:`n_ok'} out of {cmd:`N'} references found sucessfully for the following article:"'
  *-Target literature information
  getiref $DOI, path($path)
  global filename "`r(author1)'_`r(year)'"
  dis "$filename"
  dis `"References' documents are saved in: `path'"' _skip(4)  `"{browse `"`path'"': Browse}"'

  
* ---------------------- over -----------------------
