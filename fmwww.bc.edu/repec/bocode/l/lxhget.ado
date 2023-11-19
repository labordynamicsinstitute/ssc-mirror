*! version 1.4  11Sep2023
*! www.lianxh.cn, StataChina@163.com
*! Codes from -bcuse.ado- by Prof. C.F. Baum have been incorporated

*cap prog drop lxhget
prog define lxhget
	version 11
	syntax [anything(name = FileName)]  ///
	       [, Desc install REPLACE Url(string) ]

	if "`FileName'" == ""{  // browse dataset list
        br_datalist
		exit
	}
	
	if "`url'" == ""{
		mata: vfile = cat("https://file.lianxh.cn/data/data_catalogue.txt")
		capt mata: st_local("DataURL", select(vfile, regexm(vfile,`"`FileName'"')))
		
		if "`DataURL'" == ""{
			di as err _n "Error: file `FileName' not found. "
			di as text _col(3) `"o  Use - {stata "help lxhget":lxhget} .suffix is needed such as .dta, .xlsx, .do, .rar, .txt, .csv, .pkg, etc files."' 
			di as text _col(3) `"o  To view the filelist, {browse "https://gitee.com/arlionn/data/blob/master/data_catalogue_md.md":Click here}"'		
			exit 
		}
	}
	else{
	    local DataURL "`url'"
	}
	
	if regexm("`FileName'", ".+.pkg$") {
		local DataURL = subinstr("`DataURL'", "/`FileName'", "",.)
		if "`desc'" == "" & "`install'" == ""{
		     net get "`FileName'", from("`DataURL'") `replace'
		}
		if "`desc'" == "desc"{
			 net des "`FileName'", from("`DataURL'")
		}
		if "`install'" == "install"{
		     net install "`FileName'", from("`DataURL'") `replace'
		}
        exit
	}
    if regexm("`FileName'", ".+.zip$") & "`install'" == "install"{
    	copy "`DataURL'" "`FileName'", `replace'	
        unzipfile "`FileName'", replace
        local tmpfile = subinstr("`FileName'", ".zip", "",.)
        local path: pwd 
        cap net install "`tmpfile'.pkg", from("`path'/`tmpfile'") replace
        cap rm "`FileName'"
        cap !rmdir "`tmpfile'" /S/Q
        exit
    }
    
	else{
		copy "`DataURL'" "`FileName'", `replace'	
	}

	exit
	}
	
end


program define br_datalist
version 11

	  dis _col(5) "View: " `"{browse "https://gitee.com/arlionn/data/blob/master/data_catalogue_md.md": dataset list}"' ///
	      _skip(4) `"{browse "https://www.lianxh.cn": blog list}"'

end



/* 如下三条命令等价：
. use "https://file.lianxh.cn/data/auto_test.dta"
. lxhuse auto_test
. lxhuse auto_test.dta
*/

* v 1.2  use Mata statements
