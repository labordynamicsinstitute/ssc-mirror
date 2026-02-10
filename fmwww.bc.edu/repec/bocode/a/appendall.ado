*! Version 1.3.0 2025-05-06
*! Author: Dejin Xie (Nanchang University, China)

** Version 1.3.0 2025-05-06, option "do" added
** Version 1.2.0 2024-05-01, option "progress" added
** Version 1.1.0 2024-09-22, option "type" and "importopt" added
** Version 1.0.0 2024-02-06, the first version

***** Appending All Eligible Files in the Specified Folder *****

program define appendall
version 13

syntax using/ [, Save(string) Subdirectory Attribute(string) Order(string) Pattern(string) ///
                 Regex Type(string) Importopt(string) Complete Do(string asis) PRogress OPen * ]

if `c(stata_version)'>=14 {
  local ustr "ustr"
}
 
if "`save'"=="" {
  local save = "`using'/AppendAllFile"
}
else {
  if `ustr'regexm("`save'","(\\|/)") {
    local save = subinstr("`save'","\","/",.)
  }
  else {
    local save = "`using'/`save'"
  }
}

if "`order'"~="" {
  local OrDer=subinstr("/`order'","//","/",.)     
}

if "`subdirectory'"=="" {
  !dir "`using'" /B `OrDer' /A-D`attribute' >> "`using'\\APAFle.txt" 
}
else {
  !dir "`using'" /B `OrDer' /A-D`attribute' /S >> "`using'\\APAFle.txt" 
}

if "`type'"~="" {
  local type = lower("`type'")
  if inlist("`type'","dta","csv","txt","xls","xlsx","excel")==0 {
    dis as error `"The option {it:{ul:t}ype(string)} must be one of "{it:dta}", "{it:csv}", "{it:txt}", "{it:xls}", "{it:xlsx}" or "{it:excel}" !"'
    exit(198)
  }
}
else {
  local type "dta"
}

preserve
quietly {
  if c(stata_version)>=14 {
    local EncOpt "encoding(gb18030)"
  }
  import delimited using "`using'\APAFle.txt", `EncOpt' delimiter(tab) varnames(nonames) clear
  if "`subdirectory'"=="" {
    rename v1 Filename
    drop if Filename=="APAFle.txt"
    erase "`using'\\APAFle.txt"
    if "`type'"=="dta" {
      keep if `ustr'regexm(lower(Filename),"\.dta$")
    }
    else if "`type'"=="xls" {
      keep if `ustr'regexm(lower(Filename),"\.xls$")    
    }
    else if "`type'"=="xlsx" {
      keep if `ustr'regexm(lower(Filename),"\.xlsx$")
    }
    else if "`type'"=="excel" {
      keep if `ustr'regexm(lower(Filename),"\.(xls|xlsx)$")
    }
    else if "`type'"=="csv" {
      keep if `ustr'regexm(lower(Filename),"\.csv$")
    }
    else if "`type'"=="txt" {
      keep if `ustr'regexm(lower(Filename),"\.txt$")    
    }
    if "`pattern'"!="" {
      if "`regex'"=="" {
        keep if strpos(Filename,"`pattern'")>0
      }
      else {
        keep if `ustr'regexm(Filename,"`pattern'")
      }
    }
    if `c(N)'==0 {
      dis as error "Since there is not matched file in `using', you may set option {it:{ui:s}ubdirectory}."
      exit
    }
    else {
      save `save', replace
      tempfile TempFile
      local NumFile = `c(N)'
      forvalues i=1/`NumFile' {
        if "`type'"=="dta" {
          if `"`do'"'!="" {
            use "`using'\\`=Filename[`i']'" , clear
            `do'
            capture save "`TempFile'" , replace
            use `save' , clear
            capture append using "`TempFile'" , force `options'
            compress
            save `save', replace
          }
          else {
            capture append using "`using'\\`=Filename[`i']'" , force `options'
          }
          replace Filename = "`=Filename[`i']'" if Filename==""
        }
        else {
          if inlist("`type'","xls","xlsx","excel") {
            capture import excel using "`using'\\`=Filename[`i']'" , clear `importopt'
          }
          else if "`type'"=="csv" {
            capture import delimited using "`using'\\`=Filename[`i']'" , delimiter(",") clear `importopt'
          }
          else if "`type'"=="txt" {
            capture import delimited using "`using'\\`=Filename[`i']'" , clear `importopt'
          }
          if `"`do'"'!="" {
            `do'
          }
          capture save "`TempFile'" , replace
          use `save' , clear
          capture append using "`TempFile'" , force `options'
          if "`progress'"!="" {
            if !_rc {
              noisily dis as txt "The `i'/`NumFile' file {it:`=Filename[`i']'} is appended successfully."
            }
            else {
              noisily dis as res "The `i'/`NumFile' file {it:`=Filename[`i']'} is failed to append."
            }
          }
          replace Filename = "`=Filename[`i']'" if Filename==""
          compress
          save `save' , replace
          capture erase "`TempFile'"
        }
      }
      if "`complete'"=="" {
        if "`type'"!="excel" {
          replace Filename = subinstr(Filename,".`type'","",.)             
        }
        else {
          replace Filename = subinstr(Filename,".xlsx","",.)
          replace Filename = subinstr(Filename,".xls","",.)
        }
      }
    }
  }
  else {
    rename v1 Filename
    drop if strpos(Filename,"APAFle.txt")>0
    erase "`using'\\APAFle.txt"
    if "`type'"=="dta" {
      keep if `ustr'regexm(lower(Filename),"\.dta$")
    }
    else if "`type'"=="xls" {
      keep if `ustr'regexm(lower(Filename),"\.xls$")    
    }
    else if "`type'"=="xlsx" {
      keep if `ustr'regexm(lower(Filename),"\.xlsx$")
    }
    else if "`type'"=="excel" {
      keep if `ustr'regexm(lower(Filename),"\.(xls|xlsx)$")
    }
    else if "`type'"=="csv" {
      keep if `ustr'regexm(lower(Filename),"\.csv$")
    }
    else if "`type'"=="txt" {
      keep if `ustr'regexm(lower(Filename),"\.txt$")    
    }
    if "`pattern'"!="" {
      if "`regex'"=="" {
        keep if strpos(Filename,"`pattern'")>0
      }
      else {
        keep if `ustr'regexm(Filename,"`pattern'")
      }
    }
    if `c(N)'==0 {
      dis as error "Since there is not matched file in `using', you may set option {it:{ui:s}ubdirectory}."
      exit
    }
    else {
      save `save', replace
      tempfile TempFile
      local NumFile = `c(N)'
      forvalues i=1/`NumFile' {
        if "`type'"=="dta" {
          if `"`do'"'!="" {
            use "`=Filename[`i']'" , clear
            `do'
            capture save "`TempFile'" , replace
            use `save' , clear
            capture append using "`TempFile'" , force `options'
            compress
            save `save', replace
          }
          else {
            capture append using "`=Filename[`i']'" , force `options'
          }
          replace Filename = "`=Filename[`i']'" if Filename==""
        }
        else {
          if inlist("`type'","xls","xlsx","excel") {
            capture import excel using "`=Filename[`i']'" , clear `importopt'
          }
          else if "`type'"=="csv" {
            capture import delimited using "`=Filename[`i']'" , delimiter(",") clear `importopt'
          }
          else if "`type'"=="txt" {
            capture import delimited using "`=Filename[`i']'" , clear `importopt'
          }
          if `"`do'"'!="" {
            `do'
          }
          capture save "`TempFile'" , replace
          use `save' , clear
          capture append using "`TempFile'" , force `options'
          if "`progress'"!="" {
            if !_rc {
              noisily dis as txt "The `i'/`NumFile' file {it:`=Filename[`i']'} is appended successfully."
            }
            else {
              noisily dis as res "The `i'/`NumFile' file {it:`=Filename[`i']'} is failed to append."
            }
          }
          replace Filename = "`=Filename[`i']'" if Filename==""
          compress
          save `save' , replace
          capture erase "`TempFile'"
        }
      }
      if "`complete'"=="" {
        if c(stata_version)>=14 {
          replace Filename = ustrregexrf(Filename,"^.+[\\]","")
        }
        else {
          replace Filename = regexr(Filename,"^.+[\\]","")
        }
        if "`type'"!="excel" {
          replace Filename = subinstr(Filename,".`type'","",.)             
        }
        else {
          replace Filename = subinstr(Filename,".xlsx","",.)
          replace Filename = subinstr(Filename,".xls","",.)
        }
      }
    }
  }
  drop in 1/`NumFile'
  label var Filename "`type' files' names"
  compress
}    /* Close brace of quietly */
save `save' , replace
restore
if "`open'"!="" {
  quietly use `save' , clear
}

end
