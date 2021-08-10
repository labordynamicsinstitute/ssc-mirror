*! Part of package matrixtools v. 0.27
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*! 2019-03-13 nhb >	Zipsettings added
*! 2019-03-12 nhb >	Label on blank separator line
program matrix2stata, rclass
	version 12.1
	syntax anything(name=matrixexp), [Clear Ziprows ZIpsettings(string)]
	local ziprows = "`ziprows'" != "" | "`zipsettings'" != ""
	local 0 , `zipsettings'
	syntax, [Bold, Zipheadertemplate]
	mata: zipheadertemplate = "%s"
	if "`Zipheadertemplate'" != "" mata: zipheadertemplate = "`Zipheadertemplate'" 
	if "`bold'" != "" mata: zipheadertemplate = "{bf:%s}" 
	* TODO: prefix
	tempname varnames matrixname
	capture matrix `matrixname' = `matrixexp'
	if ! _rc {
		`clear'
		mata: st_local("varnames", matrix2stata("`matrixname'", "`matrixexp'", `ziprows', zipheadertemplate))
		tokenize `"`varnames'"'
		if !`ziprows' strtonum `1' `2'
		return local variable_names = `"`varnames'"'
	}
	else return local variable_names = ""
end


mata:
	function nhb_mt_matrix_stripe(	string scalar matrixname, 
								real scalar col,
								|real scalar collapse
								)
	{
		real scalar r
		string scalar eq_duplicate_value
		string matrix stripe
	
		if ( args() == 2 ) collapse = 1
		if ( col ) {
			stripe = st_matrixcolstripe(matrixname)
		} else {
			stripe = st_matrixrowstripe(matrixname)
		}
		if ( collapse ) {
			eq_duplicate_value = stripe[1,1]
			for (r=2; r<=rows(stripe); r++) {
				if ( eq_duplicate_value != "" ) {
					if ( eq_duplicate_value == stripe[r,1] ) {
						stripe[r,1] = ""
					} else {
						eq_duplicate_value = stripe[r,1]
					}
				}
			}
		}
		return( col ? stripe' : stripe)
	}

	function matrix2stata(	string scalar matname, 
							string scalar matexp,
							real scalar ziprows,
							string scalar zipheadertemplate)
	{
		string rowvector names1, names2, roweqnames, tmpnm
		real scalar rc, r, R, C, place
		real colvector position
		matrix values, tmpval
		
		if ( (values=st_matrix(matname)) != J(0,0,.) ) {
			names2 = nhb_mt_matrix_stripe(matname, 1, 0)
			roweqnames = nhb_mt_matrix_stripe(matname, 0, 0)
			if ( ziprows ) {
				names1 = strtoname(matexp + "_roweqnames")
				R = rows(values)
				C = cols(values)
				tmpnm = roweqnames
				roweqnames = sprintf(zipheadertemplate, tmpnm[1,1]) \ tmpnm[1,2]
				tmpval = values
				values = J (1, C, .) \ tmpval[1,.]
				position = 1::2
				place = 2
				for(r=2;r<=R;r++) {
					if ( tmpnm[r-1,1] != tmpnm[r,1] ) {
						roweqnames = roweqnames \ "   " \ sprintf(zipheadertemplate, tmpnm[r,1])
						position = position \ place+1 \ (place=place+2)
						values = values \ J (2, C, .)
					}
					roweqnames = roweqnames \ tmpnm[r,2]
					position = position \ ++place
					values = values \ tmpval[r,.]
				}
			roweqnames = roweqnames \ "   "
			position = position \ place+1
			values = values \ J (1, C, .)
			position = (place+1) :- position // reverse order
			rc = nhb_sae_addvars(names1, position)
			st_vldrop(names1)
			st_vlmodify(names1, position, roweqnames)
			st_varvaluelabel(names1, names1)
			} else {
				names1 = strtoname((matexp :+ ("_eq", "_names")))
				// Add roweq and rownames as 2 variables
				rc = nhb_sae_addvars(names1, roweqnames)
			}
			if ( all(names2[1, .] :== "") ) {
				names2 = strtoname(matexp :+ "_" :+ names2[2, .])
			} else {
				names2 = strtoname(names2[1, .] :+ "_" :+ names2[2, .])
			}
			// Add content of matrix
			rc = nhb_sae_addvars(names2, values)
			return( invtokens((names1, names2)) )
		} else {
			return("")
		}
	}
end
