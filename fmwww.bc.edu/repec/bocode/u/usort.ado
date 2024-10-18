*! version 1.1.0  07oct2024  I I Bolotov
program def usort, sclass byable(onecall)
	version 14
	/*
		This program is a byable sort command, which allows a) custom first and 
		last substrings, including system (.) and all remaining missing values, 
		b) gsort-like syntax for the ascending and descending order, as well as 
		c) conditional [if] and range [in] sorting. The program is built around 
		the Stata sort command and adds the data-sorted flag (sorted by) to the 
		dataset if all rows are selected and applies Mata _collate() otherwise. 
		Sorting large datasets might be taxing on machine memory or disk space. 

		Author: Ilya Bolotov, MBA Ph.D.                                         
		Date: 07 October 2024                                                   
	*/
	// syntax                                                                   
	qui desc
	if c(maxvar) - r(k) < 2 error 900
	****
	tempfile tmpf
	tempvar  byid n p s

	// sort the entire dataset at once or by groups and add the data-sorted flag
	if       !  _by()                       _sort `0'
	else {   /* Use preserve, keep, and append to prepare the final dataset. */
		egen    `byid' =  group(`_byvars'), m autotype // use .-.z/"" as values 
		qui sum `byid'
		forv     i  = `=r(min)'/`=r(max)'             {
			preserve
			qui  keep if `byid' == `i'
		   `=cond("`_byrc0'"!="","cap","")' _sort `0'  // (ignore) group errors 
			cap  append  using  `tmpf',     force
			qui  drop           `byid'
			qui  save           `tmpf',     replace
			restore
		}    /* Do sort on the by- and sortvars to set the data-sorted flag. */
		qui use `tmpf',  clear
		/* Save each sortvar into a string (`svl`) or numeric (`nvl`) macro. */
		foreach  var of  varl `_byvars'  `s(varlist)' {
			cap conf str var  `var'
			if ! _rc loc svl "`svl' `var'"
			else     loc nvl "`nvl' `var'"
		}
		/* Preserving the original string and numeric values of the sortvars in
		   the matrices `s' and `n' in Mata, replace them with `p', perform the
		   regular Stata `sort` (i.e., jumbling and collation), and replace the
		   `p'-s with the sortvar values collated on the permutation vector. */
		mata:                    `p' =          1::     st_nobs();          ///
		mata: if ("`svl'" != "") `s' =  st_sdata(.,      tokens("`svl'"));  ///
			                           st_sstore(.,      tokens("`svl'"),   ///
			          strofreal( `p' #        J(1,ustrwordcount("`svl'"),1)));;
		mata: if ("`nvl'" != "") `n' =   st_data(.,      tokens("`nvl'"));  ///
			                            st_store(.,      tokens("`nvl'"),   ///
			                   ( `p' #        J(1,ustrwordcount("`nvl'"),1)));;
		sort `_byvars'  `s(varlist)'				   // sort and add the flag 
		if ("`svl'" != "") {
			mata:  _collate(`s', `p'); st_sstore(.,       tokens("`svl'"), `s')
			mata: mata drop `s'                        // minimize memory usage 
		}
		if ("`nvl'" != "") {
			mata:  _collate(`n', `p');  st_store(.,       tokens("`nvl'"), `n')
			mata: mata drop `n'                        // minimize memory usage 
		}
		sret loc  varlist   ""						   // drop the sclass macro 
	}
end

program def _sort, sclass
	// syntax                                                                   
	syntax																	///
	anything [if] [in] [,													///
		First(string asis) Last(string asis) ignorec MFirst MLast ignorem	///
		LOCale(string) st(integer -1) case(integer -1) cslv(integer -1)		///
		norm(integer -1) num(integer -1) alt(integer -1) fr(integer -1)		///
		format(string) codepoint(integer 129769) *							///
	]
	// adjust and preprocess options                                            
	loc anything    = subinstr("`anything'", "+", "", .) /* strip plus signs */
	loc varlist     = subinstr("`anything'", "-", "", .) /* obtain variables */
	if ("`mfirst'" != ""                          )  & "`ignorem'" == ""	///
	mata:             st_local("first",invtokens("." :+ (tokens(            ///
		                 /* sort .-.z first */ c("alpha"))) )  +      " .")
	if ("`mlast'"  != "" | `"`first'`last'"' == "")  & "`ignorem'" == ""	///
	mata:             st_local( "last",invtokens("." :+ (tokens(strreverse(	///
		                 /* sort .-.z  last */ c("alpha")))))  +      " .")
	loc format      =     cond("`format'"  != "",   "`format'",  "%32.16f")
	loc locale      =     cond("`locale'"  != "",   "`locale'",				///
													c(locale_functions)   )
	****
	if "`anything'"  == ""                                                    {
		di as err "varlist required"
		exit  100
	}
	if strpos("`anything'", "- ") | ustrregexm("`anything'", "[^ +-_0-9A-z]") {
		error 100
	}
	conf form `format'
	****
	tempvar  select
	tempname n p s

	// obtain the permutation vector `p' in Mata from sorting the sortvar matrix
	/* Generate a selectvar to use in Mata st_sdata()/st_sstore() functions. */
	g   byte     `select'  =  0
	qui replace  `select'  =  1 `if' `in'			   // all rows or [if] [in] 
	preserve
	foreach  var of  varl  `varlist'  {
		/* Since non-numeric string values cannot be 'destringed', the sortvars
		   type must be str#/strL to allow sorting them as a single matrix with
		   the help of Mata `sort()` function. The precision of sorting numeric
		   values is set by the %fmt (default or user-provided value) specified
		   in the `format()` option.                                         */
		cap conf str  var  `var'
		sca `n'  =          cond(_rc, 1, 0)			   // flag numeric sortvars 
		qui tostring `var', replace force format(`format')
		/* Save the maximum string length and the length of the integer part of
		   each number into the macros `s` and `n`.                          */
		mata: st_numscalar("`s'", max(strlen(    st_sdata(.,  "`var'"))));  ///
			                             if (st_numscalar(   " `n'"  ))     ///
			  st_numscalar("`n'", max(strlen( ustrregexrf(                  ///
			                 st_sdata(., "`var'"), "^(\d+)[.,]\d+$", "$1"))));;
		/* Equate string missing values "" and the 'tostringed' sysmiss ".". */
		qui replace `var' = "."      if mi(`var' )
		/* To ensure that substrings from the `first()` option are sorted first
		   in the specified order, they are replaced in each sortvar with " #",
		   where " " is a string of whitespaces, the Unicode character from the
		   top of the UTF-8 table, with a length of `s' = max(strlen(sortvar)).
		   This action is not performed for already 'tostringed' missing values
		   (., .a, ..., .z) if the `ignorem` option is specified.            */
		if `"`first'"' != "" {
			loc  f      = lower(ustrregexrf(`"`first'"',					///
								".+,\s*([ustr]*regex[m]*|[ustr]*pos)$", "$1"))
						if `"`f'"' == lower(`"`first'"'    ) loc f "strmatch"
						else if  ustrregexm("`f'",  "regex") loc f "ustrregexm"
						else if  ustrregexm("`f'", "[r]pos") loc f "ustrrpos"
						else if  ustrregexm("`f'",    "pos") loc f "ustrpos"
						if "`ignorec'" != ""                 loc t "ustrlower"
			loc  first  =   `t'(ustrregexrf(`"`first'"',					///
								",\s*([ustr]*regex[m]*|[ustr]*pos)$",     ""))
			forv     i  = 1(1)  `: word count `first''       {
				loc  w  : word  `i'                                  of `first'
				mata:              st_local("i", "0"                      * ///
				(max(strlen(tokens(st_local("first")))) - strlen("`i'" )) + ///
					/* natural sorting requires leading zeros */ "`i'" )
				qui  replace    `var' = " "                * `s' +			///
																`"`i'"'		///
				if   cond("`ignorem'"                      == "",     1,	///
								!  ustrregexm(`var',  `"^[.a-z]{0,2}$"')) &	///
					 cond("`f'" != "strmatch" , `f'(`t'(`var'), `"`w'"'),	///
												`t'(`var') ==   `"`w'"')
			}
		}
		/* To ensure that substrings from the  `last()` option are sorted  last
		   in the specified order, they are replaced in each sortvar with "©#",
		   where "©" is a string of selected Unicode characters from the bottom
		   of the UTF-8 table, a code point of which (default or user-provided)
		   is specified in the `codepoint()` option, also with a length of `s'.
		   This action is not performed for already 'tostringed' missing values
		   (., .a, ..., .z) if the `ignorem` option is specified.            */
		if  `"`last'"' != "" {
			loc  f      = lower(ustrregexrf( `"`last'"',					///
								".+,\s*([ustr]*regex[m]*|[ustr]*pos)$", "$1"))
						if `"`f'"' == lower( `"`last'"'    ) loc f "strmatch"
						else if  ustrregexm("`f'",  "regex") loc f "ustrregexm"
						else if  ustrregexm("`f'", "[r]pos") loc f "ustrrpos"
						else if  ustrregexm("`f'",    "pos") loc f "ustrpos"
						if "`ignorec'" != ""                 loc t "ustrlower"
			loc   last  =   `t'(ustrregexrf(  `"`last'"',					///
								",\s*([ustr]*regex[m]*|[ustr]*pos)$",     ""))
			forv     i  =         `: word count `last''(-1)1 {
				loc  w  : word  `=`: word count `last'' - `i'  + 1' of  `last'
				mata:              st_local("i", "0"                      * ///
				(max(strlen(tokens(st_local( "last")))) - strlen("`i'" )) + ///
					/* natural sorting requires leading zeros */ "`i'" )
				qui  replace    `var' = uchar(`codepoint') * `s' +			///
																`"`i'"'		///
				if   cond("`ignorem'"                      == "",     1,	///
								!  ustrregexm(`var',  `"^[.a-z]{0,2}$"')) &	///
					 cond("`f'" != "strmatch" , `f'(`t'(`var'), `"`w'"'),	///
												`t'(`var') ==   `"`w'"')
			}
		}
		/* To ensure proper numerical order, natural sorting requires ancillary
		   leading zeros in the integer part of each 'tostringed' number.    */
		if `n' qui replace `var' = "0" * (`n' - strlen(ustrregexrf( `var',	///
							"^(\d+)[.,]\d+$", "$1"))) +             `var'
		/* Transform all sortvars into null-terminated byte arrays based on the
		   specified locale and any of the additional collation options.     */
		if "`st'`case'`cslv'`norm'`num'`alt'`fr'" == ""						///
			   qui replace `var' =   ustrsortkey(`var', "`locale'"        )
		else   qui replace `var' = ustrsortkeyex(`var', "`locale'", `st',	///
												 `case', `cslv',    `norm',	///
												 `num',  `alt',     `fr'  )
	}
	/* The permutation vector is obtained from an ancillary column added to the
	   matrix returned by Mata st_data(., 'sortvars', 'selectvar'), the rows of
	   which are sorted on columns 2 through the number of sortvars + 1, with a
	   negative index indicating descending order in a sortfvar.             */
	qui sum `select'								   // r(sum) = number of 1s 
	mata:   `p'  = strtoreal(sort((strofreal(1::st_numscalar("r(sum)")),    ///
		           st_sdata(., tokens("`varlist'"), "`select'")),           ///
		           (  2..(cols(tokens("`varlist'")) + 1))            :*     ///
		           strtoreal(tokens(ustrregexra(ustrregexra("`anything'",   ///
		           "(^|\s+)\w+", " 1"), "(^|\s+)-\w+", " -1"))))            ///
		     )[.,1]

	// collate for all rows with or a subset without adding the data-sorted flag
	restore
	qui sum `select'
	if r(N) == r(sum) {								   // r(sum) = number of 1s 
		/* Save each sortvar into a string (`svl`) or numeric (`nvl`) macro. */
		foreach  var of  varl `varlist' {
			cap conf str var  `var'
			if ! _rc loc svl "`svl' `var'"
			else     loc nvl "`nvl' `var'"
		}
		/* Preserving the original string and numeric values of the sortvars in
		   the matrices `s' and `n' in Mata, replace them with `p', perform the
		   regular Stata `sort` (i.e., jumbling and collation), and replace the
		   `p'-s with the sortvar values collated on the permutation vector. */
		mata: if ("`svl'" != "") `s' =  st_sdata(.,      tokens("`svl'"));  ///
			                           st_sstore(.,      tokens("`svl'"),   ///
			          strofreal( `p' #        J(1,ustrwordcount("`svl'"),1)));;
		mata: if ("`nvl'" != "") `n' =   st_data(.,      tokens("`nvl'"));  ///
			                            st_store(.,      tokens("`nvl'"),   ///
			                   ( `p' #        J(1,ustrwordcount("`nvl'"),1)));;
		sort `varlist',          `options'			   // sort and add the flag 
		if ("`svl'" != "") {
			mata:  _collate(`s', `p'); st_sstore(.,       tokens("`svl'"), `s')
			mata: mata drop `s'                        // minimize memory usage 
		}
		if ("`nvl'" != "") {
			mata:  _collate(`n', `p');  st_store(.,       tokens("`nvl'"), `n')
			mata: mata drop `n'                        // minimize memory usage 
		}
		sret loc  varlist   `varlist'				   // pass sortvars trhough 
	}
	else              {
		/* Collate the rows of all variables in the dataset, specified with the
		   help of the selectvar, on the permutation vector.                 */
		foreach  var of  varl *         {
			cap conf str var  `var'
			if  ! _rc {
				mata:    _collate((`s'= st_sdata(., "`var'", "`select'")), `p')
				mata:                  st_sstore(., "`var'", "`select'",   `s')
				mata:    mata drop `s'                 // minimize memory usage 
			}
			else      {
				mata:    _collate((`n'=  st_data(., "`var'", "`select'")), `p')
				mata:                   st_store(., "`var'", "`select'",   `n')
				mata:    mata drop `n'                 // minimize memory usage 
			}
		}
	}

	// set a data-have-changed flag if `p' results in collation of variable rows
	mata: if (`p' != (1::rows(`p'))) st_updata(1);;
	mata: mata drop `p'                                // minimize memory usage 
end
