/*

chimchar 1.0.6 13 March 2023
Tommy Morgan - labhours@tmorg.org
CHanging IMpractical CHARacters: a Stata command
that cleans string variables of all their annoying characters. Turns
Unicode characters into their closest ASCII counterpart (non-extended)
if they represent a letter and removes them if they don't.

Alternatively, strips numeric string variables of their non-numeric
characters as preparation for a destring. Also can switch commas and
periods in datasets that come with decimal commas.

*/

program define chimchar
	version 14
	
	syntax varlist , [NUMOKAY NUMREMOVE NUMONLY] [DPSWITCH]

	foreach strvar in `varlist' {
		if ("`numokay'" != "" & "`numremove'" != "") | ("`numokay'" != "" & "`numonly'" != "") | ("`numonly'" != "" & "`numremove'" != "") {
			di as err "options numonly, numokay, and numremove are mutually exclusive, pick just one"
			exit 198
		}

		if "`numokay'" == "" & "`numremove'" == "" & "`numonly'" == "" {
			di as err "must specify either numokay, numremove, or numonly option"
			exit 198
		}

		if "`dpswitch'"!="" {
			di as text "Now switching all commas in `strvar' to periods and vice-versa"
			replace `strvar' = subinstr(`strvar', ".", "___8375dot_un_matchable^3__", .)
			replace `strvar' = subinstr(`strvar', ",", ".", .)
			replace `strvar' = subinstr(`strvar', "___8375dot_un_matchable^3__", ",", .)
			di as text "All commas in `strvar' have now been switched to periods and vice-versa"
		}
		
		di as text "Now removing uniquely obnoxious characters like ` and () from `strvar'"
		quietly {
			
			*kill the worst, most obnoxious characters
			local grave = char(96)
			local apost = char(39)
			local quote = char(34)
			local leftparenth = char(40)
			local rightparenth = char(41)
			replace `strvar' = subinstr(`strvar', "`macval(grave)'", "", .)
			replace `strvar' = subinstr(`strvar', `"`macval(apost)'"', "", .)
			replace `strvar' = subinstr(`strvar', `"`macval(quote)'"', "", .)
			replace `strvar' = subinstr(`strvar', `"`macval(leftparenth)'"', "", .)
			replace `strvar' = subinstr(`strvar', `"`macval(rightparenth)'"', "", .)
		}
		
		di as text "Uniquely obnoxious characters like ` and () have now been removed from `strvar'"
		di as text "Now replacing special letters like Æ and ĸ with normal letters in `strvar'"
		
		quietly {
			*get all the letters taken care of
			replace `strvar' = subinstr(`strvar', "Æ", "ae", .)
			replace `strvar' = subinstr(`strvar', "Ø", "o", .)
			replace `strvar' = subinstr(`strvar', "Ð", "d", .)
			replace `strvar' = subinstr(`strvar', "ß", "s", .)
			replace `strvar' = subinstr(`strvar', "æ", "ae", .)
			replace `strvar' = subinstr(`strvar', "ø", "o", .)
			replace `strvar' = subinstr(`strvar', "Ð", "d", .)
			replace `strvar' = subinstr(`strvar', "ı", "i", .)
			replace `strvar' = subinstr(`strvar', "Ĳ", "ij", .)
			replace `strvar' = subinstr(`strvar', "ĳ", "ij", .)
			replace `strvar' = subinstr(`strvar', "ĸ", "k", .)
			replace `strvar' = subinstr(`strvar', "ŉ", "n", .)
			replace `strvar' = subinstr(`strvar', "Ŋ", "ng", .)
			replace `strvar' = subinstr(`strvar', "ŋ", "ng", .)
			replace `strvar' = subinstr(`strvar', "Œ", "oe", .)
			replace `strvar' = subinstr(`strvar', "œ", "oe", .)
			replace `strvar' = ustrlower(ustrto(ustrnormalize(`strvar', "nfd"), "ascii", 2))
		}
		
		di as text "Special letters like Æ and ĸ have now been replaced with normal letters in `strvar'"
			
			*kill the extra ASCII characters but keep the numbers
			if "`numokay'"!="" & "`numremove'"=="" & "`numonly'"=="" {
				di as text "Now removing all remaining non-numeric and non-letter ASCII characters from `strvar'"
				qui foreach i of numlist 1/255 {
					if !inrange(`i', 48, 57) & !inrange(`i', 44, 46) & !inrange(`i', 97, 122) & `i'!=96 & `i'!=39 & `i'!=34 & `i'!=40 & `i'!=41 {
							replace `strvar' = subinstr(`strvar', `"`=char(`i')'"', "", .)
					}
				}
				di as text "All remaining non-numeric and non-letter ASCII characters have been removed from `strvar'"
			}
			
			*kill all remaining non-letter ASCII characters
			if "`numokay'"=="" & "`numremove'"!="" & "`numonly'"=="" {
				di as text "Now removing all remaining non-letter ASCII characters from `strvar'"
				qui foreach i of numlist 1/255 {
					if !inrange(`i', 97, 122) & `i'!=96 & `i'!=39 & `i'!=34 & `i'!=40 & `i'!=41 {
							replace `strvar' = subinstr(`strvar', `"`=char(`i')'"', "", .)
					}
				}
				di as text "All remaining non-letter ASCII characters have been removed from `strvar'"
			}
			
			*kill everything but the numeric characters along with . and ,
			if "`numokay'"=="" & "`numremove'"=="" & "`numonly'"!="" {
				di as text "Now removing all remaining non-numeric characters from `strvar'"
				qui foreach i of numlist 1/255 {
					if !inrange(`i', 48, 57) & !inrange(`i', 45, 46) & `i'!=96 & `i'!=39 & `i'!=34 & `i'!=40 & `i'!=41 {
							replace `strvar' = subinstr(`strvar', `"`=char(`i')'"', "", .)
					}
				}
				di as text "All remaining non-numeric characters have been removed from `strvar'"
			}
			
		di as text "`strvar' is clean now!"
		}
		
end