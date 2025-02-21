*! version 1.2.0 20Feb2025 MLB
program define dirtree
    version 14
    syntax, [dir(string) cd *]

    local odir = c(pwd)

    if `"`dir'"' != "" {
        qui cd `"`dir'"'
    }
    
    capture noisily main, `options' directory("")
    
    if _rc {
        cd `"`odir'"'
        exit _rc
    }
    
    if "`cd'" == ""  {
        qui cd `"`odir'"'
    }
end 

program define main
    version 14
    syntax, [hidden ONLYDirs nolink           /// options for users
	        NOEXPand(string asis) NOEXPand2   /// options for users  
            where(string) directory(string)]  //  "bookkeeping" options

    local noexpand : list clean noexpand		
	
	getnames, `hidden'  // makes locals dirs and files

	
    local kd : word count `dirs'
    local kf : word count `files'
    
    local lastchild `"as txt "{c BLC}{c -}{c -} ""'
    local child `"as txt "{c LT}{c -}{c -} ""'
    local enddir `" as txt " \""'

    // display the root
    if "`directory'" == "" {
        mata: st_local("root",pathbasename(st_global("c(pwd)")))
        di as result "`root'"  `enddir'
        local where = c(pwd)
    }

    // display the files
    if "`onlydirs'" == "" {
        local i = 1
        foreach file of local files {
            if (`i++' == `kf' & `kd' == 0) { // last item in directory
                di as txt "`directory'"`lastchild' _continue
            }
            else { // not last item
                di as txt "`directory'"`child' _continue
            }
            difile, file("`file'") where("`where'") `link'
        }
    }

    // display the directories
    local i = 1
    foreach dir of local dirs {
        if `i++' == `kd'  { // last directory
            local newdirectory "`directory'    "
            di as txt "`directory'"`lastchild' as result "`dir'"  `enddir'
        }
        else { // not last directory
            local newdirectory "`directory'{c |}   "
            di as txt "`directory'"`child'  as result "`dir'" `enddir'
        }
        // use recursion to display what is inside those directories
		local dir2  = `""`dir'""'
		local dir2 : list clean dir2
		if "`expand2'" == "" & !`: list dir2 in noexpand' {
			qui cd "`dir'"
			mata : st_local("where_out", pathjoin("`where'", "`dir'"))
			main, directory("`newdirectory'") `hidden' `onlydirs' ///
			      where("`where_out'") `link' noexpand(`noexpand') `noexpand2'
			qui cd ..
		}
		else {
			mata: st_local("hiddendir", pathjoin(pwd(),"`dir'")) 
			di as txt "`newdirectory'"`lastchild'_continue
			if "`link'" == "" {
				di `"{stata `"dirtree, dir("`hiddendir'") `hidden' `onlydirs' `link'"':...}"' 
			}
			else {
				di as result "..."
			}
		}
    }
end

program define getnames
    version 14
    syntax, [hidden]
    
    local dirs: dir "." dirs "*"
    local result = ""
    if "`hidden'" == "" & `"`dirs'"' != "" {
        drophidden `dirs'
        local dirs = `"`list'"'
    }
    
    local files: dir "." files "*"
    local result = ""
    if "`hidden'" == "" & `"`files'"' != "" {
        drophidden `files'
        local files = `"`list'"'
    }    
    c_local dirs `"`dirs'"'
    c_local files = `"`files'"'
end 

program define drophidden
    version 14
    syntax anything(name=list)
    
    local result = ""
    foreach element of local list {
        if substr("`element'",1,1) != "." {
            local result = `"`result' "`element'""'
        }
    }
    local list = strtrim(`"`result'"')
    c_local list `"`list'"'
end

program define difile
    version 14
    syntax, file(string) where(string) [nolink]
    
    mata: st_local("suffix", pathsuffix("`file'"))
    mata: st_local("path", pathjoin("`where'","`file'"))

    local doedit ".ado .do .mata .mps .mpb .md"
    local view ".sthlp .hlp .smcl .txt .log"
    
    if `: list suffix in doedit' & "`link'" == "" & `"`suffix'"' != "" {
        di `"{stata `"doedit "`path'""' :`file'}"'
    }
    else if `: list suffix in view' & "`link'" == "" & `"`suffix'"' != ""  {
        di `"{stata `"view "`path'""':`file'}"'
    }
    else if "`suffix'" == ".dta" & "`link'" == "" {
        di `"{stata `"use "`path'""':`file'}"'
    }
    else {
        di as result "`file'"
    }
end


