*===================================================================================*
* Ado-file: OneText Version 2.0 
* Author: Shutter Zor(左祥太)
* Affiliation: School of Accountancy, Wuhan Textile University
* E-mail: Shutter_Z@outlook.com 
* Date: 2022/7/13                                          
*===================================================================================*
program define onetext
	version 16.0
	
	syntax varlist(min=1 max=2) [if] [in], [Keyword(string)] 	///
			 Method(string)	 Generate(string)
	
	capture confirm new variable `generate'
	if _rc{
		dis as err "generate() should give a new variable name"
		exit
	}
	
	qui gen `generate' = .
	
	if wordcount("`varlist'") == 1{

		if "`method'" == "count" {
			local word "`keyword'"
			local word_length length("`keyword'")
			replace `generate' = (length(`varlist') 				///
				- length(subinstr(`varlist', "`word'", "", .))) 	///
				/ `word_length'
		}

		else if "`method'" == "exist" {
			local word "`keyword'"
			replace `generate' = 1 if strmatch(`varlist', "*`word'*")
			replace `generate' = 0 if `generate' == .
		}
		
		else {
			dis as err "onetext can only use count/exist when you set one variable, and keyword() option must be specified"
			drop `generate'
		}
	}
	
	if wordcount("`varlist'") == 2{
	
		if "`method'" == "cosine" {
			tokenize "`varlist'"
			local var1 `1'
			local var2 `2'
			quietly {
				*- Numerator of cosine similarity (Fraction1)
					gen timesFraction1 = `var1' * `var2'	
					egen Fraction1 = sum(timesFraction1)

				*- Denominator of cosine similarity (Fraction2)
					foreach v in `var1' `var2'{	
						gen times`v' = `v' * `v'
						egen sum`v' = sum(times`v')
						gen sqrt`v' = sqrt(sum`v')
					}
					gen Fraction2 = sqrt`var1' * sqrt`var2'
					*- Value of cosine similarity (`generate')
						replace `generate' = Fraction1 / Fraction2
						drop times* sum* sqrt* Fraction*
			}
		}
		
		else if "`method'" == "jaccard" {
			dis "Note: The jaccard similarity is calculated by the ratio of intersection and union, which may not be applicable to binary sets."
			tokenize "`varlist'"
			local var1 `1'
			local var2 `2'
			quietly{
				sort `var1' `var2'
				*- Numerator of jaccard similarity (Fraction1)
					preserve
						gen temp = .
						local n = _N
						forvalues i = 1/`n'{
							forvalues j = 1/`n'{
								if var1[`i'] == var2[`j'] {
									replace temp = 1 in `i'
								}
							}
						}
						qui sum temp
						local Fraction1 `r(N)'
					restore
				*- Denominator of jaccard similarity (Fraction2)
					preserve
						local n = _N
						set obs `=2*_N'
						replace `var1' = `var2'[_n-`n'] if _n > `n' & _n <= 2*`n'
						duplicates drop `var1', force
						qui sum `var1'
						local Fraction2 `r(N)'
					restore
				*- Value of jaccard similarity (`generate')
					replace `generate' = `Fraction1' / `Fraction2'
			}
		}
		
		else {
			dis as err "onetext can only calculate cosine similarity and jaccard similarity when you set two variables"
			drop `generate'
		}
	}

end
