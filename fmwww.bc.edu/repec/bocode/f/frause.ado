*! v 1.1 Loads data from my PWS site
* Also describes data (if description available)

** This script reads the info in file and shows all datasets available
** or datasets that start with some letters
mata:
	void dir_files(string scalar filex, string scalar srch){
		string matrix file_name
		real scalar slen
		file_name=sort(cat(filex),1)
		
		slen = strlen(srch)
		if (srch==" ") file_name
		else {
			select(file_name,substr(file_name,1,slen):==srch ) 
		}
	}
end
program frause, 
	version 9
	syntax [anything(everything)], [* version DEScribe DIR DIR1(str)]
 
	if "`0'"=="" | "`version'"!="" {
		display "version: 1.1"
		addr scalar version = 1.1
		exit
	}
	
	if "`dir'`dir1'"!="" {
		dir_files, opt(`dir1')
				
		exit
	}
	** for descriptions, gather from site
	if "`describe'"=="" {
		qui:webuse set https://friosavila.github.io/playingwithstata/data2
		webuse `0'
		qui:webuse set
	}
	else {
		gettoken name 0:0
		local name = subinstr("`name'",",","",.)
		type "https://friosavila.github.io/playingwithstata/data2/`name'.des"
	}
end
 
program addr, rclass
	return `0'
end
** the mata wrapper 
program dir_files
	syntax, [opt(str)]
	tempfile f1
	qui: copy "https://friosavila.github.io/playingwithstata/data2/afiles.txt" `f1'
	if "`opt'"=="" local opt =" "
	mata:dir_files("`f1'","`opt'")
end 
** mataFrause


 