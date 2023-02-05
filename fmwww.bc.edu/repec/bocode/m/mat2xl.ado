*! Part of package matrixtools v. 0.30  
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2020-08-23 added
* 2020-06-29 created

program define mat2xl
	version 13.1
	syntax anything(name=matrixexpression)/*
	*/, toxl(string) /*
	*/[ /*
		*/Noisily /*
		*/noCleanmata /*
		*/Decimals(string) /*
        */noEqstrip /*
		*/Hidesmall(integer 0) /*
		*/Rownamewidth(integer 25) /*
		*/Cellwidth(integer 15) /*
	*/]

	local QUIETLY quietly
	if `"`noisily'"' != "" local QUIETLY ""
	
	tempname matrixname
	matrix `matrixname' = `matrixexpression'
	mata: __2xl_lm = nhb_mt_labelmatrix()
	mata: __2xl_lm.from_matrix(`"`matrixname'"')
	capture mata: __2xl_decimals = `decimals'
	if _rc mata: __2xl_decimals = 2	
	`QUIETLY' mata: __2xl_lm.print("", __2xl_decimals)
    
    if `c(stata_version)' >= 13 {
        if `c(stata_version)' >= 14 mata: __2xl_xlz = xlsetup14()
        else mata: __2xl_xlz = xlsetup13()

        `QUIETLY' mata: __2xl_xlz.thisversion

        mata: __2xl_xlz.stringset(`"`toxl'"')
        `QUIETLY' mata: __2xl_xlz.xlfile()
        `QUIETLY' mata: __2xl_xlz.sheet()
        `QUIETLY' mata: __2xl_xlz.start()
        if `c(stata_version)' >= 14 {
            mata: __2xl_r = (colsum(__2xl_lm.row_equations() :!= "") > 0) + (colsum(__2xl_lm.row_names() :!= "") > 0)
            mata: __2xl_cw = __2xl_xlz.columnwidths()
            mata: __2xl_cw = __2xl_cw[1] != . ? __2xl_cw ///
                                : J(1, __2xl_r, `rownamewidth'), `cellwidth' 
            mata: __2xl_xlz.columnwidths(__2xl_cw)
            `QUIETLY' mata: __2xl_xlz.columnwidths()
        }

        if `=`hidesmall' <= 0' local hidesmall .
        if `rownamewidth' < 0 mata: _error("rownamewidth must be non-negative.")
        if `cellwidth' < 0 mata: _error("cellwidth must be non-negative.")
        mata: __2xl_xlz.insert_matrix(__2xl_lm.to_strings(__2xl_decimals, "`eqstrip'" == "", `hidesmall'))
        if `c(stata_version)' >= 14 {
            mata: __2xl_c = (colsum(__2xl_lm.column_equations() :!= "") > 0) + (colsum(__2xl_lm.column_names() :!= "") > 0)
            mata: __2xl_R = rows(__2xl_lm.values())
            mata: __2xl_C = cols(__2xl_lm.values())
            mata: __2xl_xlz.set_alignments("left", (0, 0), (__2xl_r + __2xl_R, __2xl_c + __2xl_C), 1)
            mata: __2xl_xlz.set_alignments("right", (__2xl_c, __2xl_r), (__2xl_r + __2xl_R, __2xl_c + __2xl_C), 1)
        }
        mata printf(`"Table saved in "%s", in sheet "%s"... \n"', __2xl_xlz.xlfile(), __2xl_xlz.sheet())
    }
	if `"`cleanmata'"' == "" mata mata drop __2xl_*
end

if `c(stata_version)' >= 13 {
    mata st_local( "__2xl_fn", findfile("ltoxl_v13.mata"))
    include "`__2xl_fn'"
}
if `c(stata_version)' >= 14 {
    mata st_local( "__2xl_fn", findfile("ltoxl_v14.mata"))
    include "`__2xl_fn'"
}
