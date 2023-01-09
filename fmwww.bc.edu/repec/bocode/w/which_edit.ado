*! Part of package matrixtools v. 0.29
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2020-08-23 > Added

program define which_edit, rclass
    syntax anything [, Help]
    
    mata: find_ado(`"`anything'"', `"`help'"' != "")
    if `"`filename'"' != "" doedit `"`filename'"'
    display `"`filename'"'
    return local filename = `"`filename'"'
end

mata:
    void find_ado(string scalar txt, real scalar help)
    {
        string scalar fn
        
		if ( pathsuffix(txt) == "" ) txt = txt + ".ado"
		if ( help ) {
			txt = pathrmsuffix(txt) + ".sthlp"
		    fn = findfile(txt)
		} else if ( (fn = findfile(txt)) == "" ) fn = findfile("_g" + txt)		    
		st_local("filename", fn)
    }
end
