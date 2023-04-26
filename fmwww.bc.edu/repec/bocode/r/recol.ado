
program recol

	// version
	version 10.0

	// syntax
	syntax [varlist][, Maxwidth(integer 50) Userows(integer 100) Full Compress]

	// list the variables
	if "`varlist'" == "" {
		qui ds
		local relevant_vars `r(varlist)'
	}
	else {
		local relevant_vars `varlist'
	}

	// the first chunk of the table (100 obs default for faster execution)
	if `userows' > _N {
		local first_section = _N
	}
	else {
		local first_section = `userows'
	}

	// for each variable
	foreach v of varlist `relevant_vars' {

		// get the number of characters in the variable name
		local varnamelen = strlen("`v'")

		// get the type and format
		local vtype "`: type `v''"
		local fmt "`: format `v''"

		// if string
		if regexm("`vtype'", "^str") {
			tempvar slen maxslen
			if "`full'" == "" {
				// longest string in the column - short version
				// creating a new variable takes forever even if most values are missing
				// put it into a mata matrix to speed things up
				putmata `v' in 1/`first_section'
				// get the length of each string in the vector
				mata: len_vec = strlen(`v')
				// get the max length of the strings
				mata: max_len = colmax(len_vec)
				// put the max value into a local (must be a string)
				mata: st_local("contents", strofreal(max_len))
				// delete the mata matrix
				mata: mata drop `v'
				// side note: it is possible that this part was not the slow part
				// instead it may have been the egen maxslen part below that always ran
			}
			else {
				// longest string in the column - full version
				qui gen `slen' = strlen(`v')
				qui egen `maxslen' = max(`slen')
				local contents = `maxslen'[1]
			}
		}

		// if date
		// unaffected by the "full" option
		else if regexm("`fmt'", "^%[td]") {
			tempvar datestr dstrlen
			if "`full'" == "" {
				// make the string version of the date - short version
				qui gen `datestr' = string(`v', "`fmt'") in 1/`first_section'
				// new column to mata
				putmata `datestr' in 1/`first_section'
			}
			else {
				// make the string version of the date - full version
				qui gen `datestr' = string(`v', "`fmt'")
				// new column to mata
				putmata `datestr'
			}
			// get the length of each string in the vector
			mata: len_vec = strlen(`datestr')
			// get the max length of the strings
			mata: max_len = colmax(len_vec)
			// put the max value into a local (must be a string)
			mata: st_local("contents", strofreal(max_len))
			// delete the mata matrix
			mata: mata drop `datestr'
		}

		// other numeric
		else {
			// make sure the format matches expectations
			// strings and dates have already been handled, so this should work
			assert regexm("`fmt'", "%([0-9]+)\.([0-9]+)([fgc]+)")

			// pieces of regex match
			local main_width = regexs(1)
			local decimal = regexs(2)
			local fmt_details = regexs(3)

			// if no decimal value
			if `decimal' == 0 {
				local contents = `main_width'
			}
			// if decimal value
			else {
				local contents = `main_width'
			}
		}

		// if contents are longer, use that
		if `contents' > `varnamelen' {
			local new_width = `contents'
		}
		// if variable name is longer, use that
		else {
			local new_width = `varnamelen'
		}
		// if max width applies, change it
		if `new_width' > `maxwidth' {
			local new_width = `maxwidth'
		}

		// set width
		// need to +2 for display purposes
		local display_width = `new_width' + 2
		char `v'[_de_col_width_] `display_width'

		// print progress
		di as text "Width set to " as result "`new_width'" as text _col(18) ": " as result "`v'"
	}

	// optional compress
	if "`compress'" != "" {
		capture qui drop __*
		di as result "Compressing data"
		compress
	}
end
