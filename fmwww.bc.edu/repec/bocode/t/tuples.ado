*! 3.3.0 Joseph N. Luchman, daniel klein, & NJC 17 February 2016
* 3.2.1 Joseph N. Luchman 3 March 2015
* 3.2.0 Joseph N. Luchman 16 January 2015
* 3.1.0 Joseph N. Luchman 20 March 2014
* 3.0.1 NJC 1 July 2013
* 3.0.0 Joseph N. Luchman & NJC 22 June 2013
* 2.1.0 NJC 26 January 2011 
* 2.0.0 NJC 3 December 2006 
* 1.0.0 NJC 10 February 2003 
* all subsets of 1 ... k distinct selections from a list of k items 
program tuples
	version 8
	
	if (c(stata_version) >= 10) {
		version 10
		local 10options 			///
			noMata 					///
			CONDitionals(string) 	///
			CVP 					///
			KRONECKER 				///
			noSort 					///
			SEEMATA	// debug
	}
	else {
		local mata "nomata"
	}
	
	syntax anything ///
	[ , ///
		ASIS /* or */ VARlist 			///
		DIsplay 						///
		MAX(numlist max = 1 int > 0) 	///
		MIN(numlist max = 1 int > 1) 	///
		`10options' 					///
	]
	
	if "`varlist'" != "" & "`asis'" != "" { 
		di as err "varlist and asis options may not be combined"
		exit 198 
	}	
	
	if "`cvp'" != "" & "`kronecker'" != "" {
		di as err "options cvp and kronecker may not be combined"
		exit 198
	}

	if "`varlist'" == "" { 
		local capture "capture" 
	}	
	
	if "`asis'" == "" { 
		`capture' unab anything : `anything' 
	} 
	
	tokenize `"`anything'"'  
	local n : word count `anything' 

	if "`max'" == "" local max = `n' 
	else if `max' > `n' { 
		di "{p}{txt}maximum reset to number of items {res}`n'" 
		local max = `n' 
	} 
	
	if "`min'" == "" local min = 1 
	else if `min' > `max' { 
		di "{p}{txt}minimum reset to {res}1" 
		local max = 1 
	}
	
	if "`mata'" != "" {
		if "`conditionals'" != "" {
			local bad "conditionals"
		}
		else if "`cvp'" != "" {
			local bad "cvp"
		}
		else if "`kronecker'" != "" {
			local bad "kronecker"
		}
		else if "`sort'" != "" {
			local bad "nosort"
		}
		
		if "`bad'" != "" {
			di "{err}options nomata and `bad' cannot be combined"
			exit 198
		}
		
		if "`display'" == "" local qui "*"
		local imax = 2^`n' - 1
		local k = 0 
		forval I = `min'/`max' { 
			forval i = 1/`imax' { 
				qui inbase 2 `i'
				local which `r(base)' 
				local nzeros = `n' - `: length local which' 
				local zeros : di _dup(`nzeros') "0" 
				local which `zeros'`which'  
				local which : subinstr local which "1" "1", ///
					all count(local n1) 
				if `n1' == `I' {
					local previous "`out'"  
					local out 
					forval j = 1 / `n' { 
						local char = substr("`which'",`j',1) 
						if `char' local out `out' ``j''  
					}
					c_local tuple`++k' `"`out'"'
					`qui' di as res "tuple`k': " as txt `"`out'"'  
				}	
			} 	
		}
		c_local ntuples `k'
	}
	else {
		if strlen("`conditionals'") {
			tempname enumerate
			mata: st_numscalar("`enumerate'", ///
			sum(J(16, 1, ascii(st_local("conditionals"))) ///
				:==ascii(" 0123456789()!&|")'))
			if strlen("`conditionals'") > `enumerate' {
				display "{err}Illegal characters in {bf:conditionals}. " ///
				"Only digits ({bf:0123456789}), spaces ( )," _newline ///
				"ampersands ({bf:&}), vertical bars ({bf:|}), " ///
				"exclamation marks ({bf:!}), and parentheses ({bf:()}) allowed"
				exit 198
			}
		}
		mata : tuples( 	///
						`"`anything'"', 	///
						`min', `max', 		///
						"`display'", 		///
						"`conditionals'", 	///
						"`cvp'", 			///
						"`kronecker'", 		///
						"`sort'", 			///
						"`seemata'" 		///
				)		
	}
end

if (c(stata_version) < 10) {
	exit 0
}

//mata-based implementation of tuples macro generation

version 10

local TS tuples_strct_def
loc TSS struct `TS' scalar

mata:

mata set matastrict on

struct `TS' {
	string colvector list
	real scalar min
	real scalar max
	real scalar is_display
	string scalar conditionals 
	real scalar is_cvp
	real scalar is_kronecker
	real scalar is_sort
	real scalar is_debug
	
	real scalar n
	real matrix indicators
}

void tuples(string scalar list, 
			real scalar min, 
			real scalar max, 
			string scalar display, 
			string rowvector conditionals, 
			string scalar cvp, 
			string scalar kronecker, 
			string scalar nosort,
			string scalar seemata)
{
	`TSS' T
	
	T.list 			= list
	T.min 			= min
	T.max 			= max
	T.is_display 	= strlen(display)
	T.conditionals 	= conditionals
	T.is_cvp 		= strlen(cvp)
	T.is_kronecker 	= strlen(kronecker)
	T.is_sort 		= !(strlen(nosort))
	T.is_debug 		= strlen(seemata)
	
	tuples_get_list(T)
	
	tuples_get_indicators(T)
	
	if (strlen(conditionals)) {
		tuples_get_conditionals(T)
	}
	
	tuples_return(T)
}

void tuples_get_list(`TSS' T)
{
	transmorphic scalar t
	real scalar x
	
	t = tokeninit()
	tokenset(t, T.list)
	T.list = tokengetall(t)'
	for(x = 1; x <= rows(T.list); x++) {
		if (substr(T.list[x], 1, 1) == `"""') {
			T.list[x] = substr(T.list[x], 2, strlen(T.list[x]) - 2)
		}
	}
	T.n = rows(T.list)
}

void tuples_get_indicators(`TSS' T)
{
	real scalar N, x
	real matrix combin
	
	if (T.is_cvp) {
		tuples_get_indicators_cvp(T)
	}
	else if (T.is_kronecker) {
		tuples_get_indicators_kronecker(T)
	}
	else {
		N = 2^T.n
		T.indicators = J(T.n, N, .)
		for (x = 1; x <= T.n; ++x) {
			N = N/2
			combin = J(1, N, 0), J(1, N, 1)
			T.indicators[x, .] = J(1, 2^(x-1), combin)
			if (T.is_debug) {
				T.indicators /**/
			}
		}
		T.indicators = T.indicators[|., 2\ ., .|]
		if (T.is_debug) {
			T.indicators /**/
		}
		if ((T.n > 2) & (T.is_sort)) {
			T.indicators = (colsum(T.indicators)\ T.indicators)'
			T.indicators = sort(T.indicators, (1..cols(T.indicators)))
			T.indicators = T.indicators[|1, 2\ ., .|]'
		}
		T.indicators = select(T.indicators, ///
			(colsum(T.indicators) :>= T.min :& colsum(T.indicators) :<= T.max))
		if (T.is_debug) {
			T.indicators /**/
		}
	}
}

void tuples_get_indicators_cvp(`TSS' T)
{
	real scalar x, y
	real matrix base, combin
	transmorphic scalar basis
	
	for (x = T.min; x <= T.max; x++) {
		base = J(x, 1, 1)
		base = (base \ J(T.n - x, 1, 0))
		basis = cvpermutesetup(base)
		for(y = 1; y <= comb(T.n, x); y++) {
			combin = cvpermute(basis)
			if ((y == 1) & (x == T.min)) {
				T.indicators = combin
			}
			else {
				T.indicators = (T.indicators, combin)
			}
			if (T.is_debug) {
				T.indicators	/**/
			}
		}		
	}
}

void tuples_get_indicators_kronecker(`TSS' T)
{
	real scalar x
	real matrix base, combin
	
	for (x = 1; x <= T.max; x++) {
		if (x == 1) {
			combin = base = I(T.n)
			if (x >= T.min) {
				T.indicators = uniqrows(base)
			}
		}
		else if ((x == T.n) & (x > T.min)) {
			T.indicators = (T.indicators, J(T.n, 1, 1))
		}
		else if ((x == T.n) & (x == T.min)) {
			T.indicators = J(T.n, 1, 1)
		}
		else {
			combin = uniqrows((select( ///
			(J(1, cols(combin), 1)#base):+(combin#J(1, cols(base), 1)), ///
			!colsum( ///
			((J(1, cols(combin), 1)#base):+(combin#J(1, cols(base), 1))) ///
			:==2)))')'
			if (x == T.min) {
				T.indicators = combin
			}
			else if (x > T.min) {
				T.indicators = (T.indicators, combin)
			}
		}
		if ((T.is_debug) & (x >= T.min)) {
			T.indicators	/**/
		}
	}
}

void tuples_get_conditionals(`TSS' T)
{
	real rowvector nums
	real scalar x
	
	if (T.is_debug) {
		T.conditionals	/**/
	}
	nums = J(1, cols(T.indicators), 1)
	T.conditionals = tokens(T.conditionals)
	for(x = 1; x <= cols(T.conditionals); x++) {
		if (T.is_debug) {
			T.conditionals[x]	/**/
		}
		nums = tuples_parse_condit(T, T.conditionals[x]):*nums
	}
	T.indicators = select(T.indicators, nums)
}

real rowvector tuples_parse_condit(`TSS' T, string scalar conditions)
{

	real rowvector changes
	string rowvector condition
	transmorphic t, x, wchars, pchars, qchars

	if (T.is_debug) {
		printf("begin tuples_parse_condit()\n") /**/
	}
	
	t = tokeninit(wchars=(""), pchars=("(", ")"))
	tokenset(t, conditions)
	condition = tokengetall(t)
	
	if (sum(strmatch(condition, "("):+strmatch(condition, ")")) == 1) { 
		printf("{err}Illegal use of parentheses - look to see if there " ///
		+ "are\n extra spaces in a parentetical statement\n")
		exit(198)
	}

	if ((condition[1] == "(") & (condition[cols(condition)] == ")")) {
		conditions = invtokens(condition[2..cols(condition)-1])
	}
	
	t = tokeninit(wchars=(""), pchars=("&", "!", "|"), qchars=("()"))
	tokenset(t, conditions)
	condition = tokengetall(t)
	condition = select(condition, condition:!=" ")
		
	if ((max(editmissing(strtoreal(condition), -1)) > rows(T.indicators)) | ///
	(sum(strtoreal(condition):==0))) {
		printf("{err}Statement " + char(34) + invtokens(condition) ///
		+ char(34) + " contains an illegal list element reference\n")
		exit(198)
	}
	
	if (T.is_debug) {
		condition	/**/
	}
	if (cols(condition) == 1) {
		if (regexm(condition, "^\(")) {
			if (T.is_debug) {
				printf("only one, pass..\n")	/**/
			}
			changes = tuples_parse_condit(T, condition)
		}
		else if (regexm(condition, "[0-9]+")) {
			if (T.is_debug) {
				printf("digit(s)\n")	/**/
			}
			changes = T.indicators[strtoreal(condition), .]
			if (T.is_debug) {
				changes	/**/
			}
		}
		else {
			changes = J(1, cols(T.indicators), 1)
			if (T.is_debug) {
				changes	/**/
			}
		}
	}
	else {
		for(x = 1; x <= cols(condition); x++) {
			if (T.is_debug) {
				condition[x]	/**/
			}
			if (x == 1) {
				if (T.is_debug) {
					printf("#1\n")	/**/
				}
				if (regexm(condition[x], "^\(")) {
					if (T.is_debug) {
						printf("..pass..\n")	/**/
					}
					changes = tuples_parse_condit(T, condition)
					if (T.is_debug) {
						changes	/**/
					}
				}
				else if (regexm(condition[x], "[0-9]+")) {
					if (T.is_debug) {
						printf("digit(s)\n")	/**/
					}
					changes = T.indicators[strtoreal(condition[x]), .]
					if (T.is_debug) {
						changes	/**/
					}
				}
				else {
					changes = J(1, cols(T.indicators), 1)
					if (T.is_debug) {
						changes	/**/
					}
				}
			}
			else {
				if (T.is_debug) {
					printf(">#1\n")	/**/
				}
				if (regexm(condition[x], "^\(")) {
					if (T.is_debug) {
						printf("pass!\n")	/**/
					}
					if (condition[x-1] != "!") {
						changes = tuples_parse_condit(T, condition[x]):*changes
					}
					else {
						changes = !tuples_parse_condit(T, condition[x]):*changes
					}
					if (T.is_debug) {
						changes	/**/
					}
				}
				else if (regexm(condition[x], "[0-9]+")) {
					if (T.is_debug) {
						printf("digit(s)\n")	/**/
					}
					if (T.is_debug) {
						condition[x-1]	/**/
					}
					if (condition[x-1] == "&") {
						if (T.is_debug) {
							printf("&\n")	/**/
						}
						changes = T.indicators[strtoreal(condition[x]), .]:*changes
						if (T.is_debug) {
							changes	/**/
						}
					}
					else if (condition[x-1] == "|") {
						if (T.is_debug) {
							printf("|\n")	/**/
						}
						changes = ///
							sign(T.indicators[strtoreal(condition[x]), .]:+changes)
						if (T.is_debug) {
							changes	/**/
						}
					}
					else if (condition[x-1] == "!") {
						if (T.is_debug) {
							printf("!\n")	/**/
						}
						if (x >= 3) {
							if (condition[x-2] == "&") {
								if (T.is_debug) {
									printf("&\n")	/**/
								}
								changes = !T.indicators[strtoreal(condition[x]), .]:*changes
								if (T.is_debug) {
									changes	/**/
								}
							}
							else if (condition[x-2] == "|")  {
								if (T.is_debug) {
									printf("|\n")	/**/
								}
								changes = sign(!T.indicators[strtoreal(condition[x]), .]:+changes)
								if (T.is_debug) {
									changes	/**/
								}
							}
						}
						else {
							if (T.is_debug) {
								printf("!\n")	/**/
							}
							changes = !T.indicators[strtoreal(condition[x]), .]
							if (T.is_debug) {
								changes	/**/					
							}
						}
					}
				}
			}
		}
	}
	if (T.is_debug) {
		printf("end tuples_parse_condit()\n")	/**/
	}
	return(changes)
}

void tuples_return(`TSS' T)
{
	real scalar x
	string rowvector tuple
	string scalar invtuple
	
	if (T.is_debug) {
		T.indicators	/**/
		T.list	/**/
	}
	for (x = 1; x <= cols(T.indicators); x++) {
		tuple = (T.list:*T.indicators[., x])'
		invtuple = strtrim(stritrim(invtokens(tuple)))
		stata("c_local tuple" + strofreal(x) + " " + invtuple)
		if (T.is_display) {
			printf("{res}tuple%f: {txt}%s\n", x, invtuple)
		}
	}
	stata("c_local ntuples " + strofreal(cols(T.indicators)))
}

end
