*! version 1.3.0 21Feb2025 MLB
program define dirtree
    version 14
    syntax [anything(id="directory" name=dir)], [DIR2(string) cd *]

	if `"`dir'"' != "" & `"`dir2'"' != "" {
		di as err "{p}You cannot specify the dir() option if you also specified a directory directly after dirtree{p_end}"
		exit 198
	}
	local dir `"`dir'`dir2'"'
	local dir : list clean dir
	
    local odir = c(pwd)

    if `"`dir'"' != "" {
        qui cd `dir'
    }
    
    capture noisily main, `options' directory("") depth(1)
    
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
    syntax, [hidden ONLYDirs nolink export                     /// options for users
	        NOEXPand(string asis) noEXPand2                    /// options for users  
			maxdepth(numlist min=1 max=1 >0 integer missingok) /// options for users
            where(string) directory(string)]                   /// "bookkeeping" options
			depth(integer)                                     //  "bookkeeping" options

    local noexpand : list clean noexpand		
	if "`maxdepth'" == "" {
		local maxdepth = .
	}
	if "`link'" == "" & "`export'" != "" {
		di as err "{p}the export option requires the nolink option{p_end}"
		exit 198
	}
	
	getnames, `hidden'  // makes locals dirs and files

	
    local kd : word count `dirs'
    local kf : word count `files'
    
	if "`export'" == "" {
		local lastchild `"as txt "{c BLC}{c -}{c -} ""'
		local child `"as txt "{c LT}{c -}{c -} ""'
		local bar "{c |}"
	}
	else {
		local lastchild `"as txt "└── ""'
		local child `"as txt "├── ""'
		local bar "│"		
	}
	
    // display the root
    if "`directory'" == "" {
        mata: st_local("root",pathbasename(st_global("c(pwd)")))
        didir, dir("`root'") `link' root
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
            di as txt "`directory'"`lastchild' _continue
			didir, dir("`dir'") `link'
        }
        else { // not last directory
            local newdirectory "`directory'`bar'   "
            di as txt "`directory'"`child'  _continue
			didir, dir("`dir'") `link'
        }
        // use recursion to display what is inside those directories
		local dir2  = `""`dir'""'
		local dir2 : list clean dir2
		if "`expand2'" == "" & !`: list dir2 in noexpand' & `depth' < `maxdepth' {
			qui cd "`dir'"
			mata : st_local("where_out", pathjoin("`where'", "`dir'"))
			main, directory("`newdirectory'") `hidden' `onlydirs' ///
			      where("`where_out'") `link' `export'            ///
				  noexpand(`noexpand') `noexpand2'                ///
				  depth(`=`depth'+1') maxdepth(`maxdepth')
			qui cd ..
		}
		else {
			mata: st_local("hiddendir", pathjoin(pwd(),"`dir'")) 
			di as txt "`newdirectory'"`lastchild'_continue
			if "`link'" == "" {
				di `"{stata `"dirtree "`hiddendir'", `hidden' `onlydirs' "':...}"' 
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

program define didir
	version 14
	syntax, dir(string) [nolink root]
	
	if "`link'" == "" {
		if "`root'" == "" {
			mata: st_local("path", pathjoin(pwd(),`"`dir'"'))
		}
		else {
			local path = c(pwd)
		}
		di `"{stata `"cd "`path'""':`dir'}"' as txt " \"
	}
	else {
		di as result "`dir'" as txt " \"
	}
end

