*! latexlog_run 0.5.0 25aug2026
*! Program to run examples from the help file.
*! This code for including examples from the help file into a do file is based on Robert Picard's geo2xy.ado file.
program define latexlog_run

	version 18
	
	syntax anything(name=example_name id="example name") ///
		using/			///
		,				///
		[requires(string)]	///
		[preserve]
	
	
	// if `"`requires'"' != "" {
	// 	foreach f of local requires {
	// 		cap confirm file `f'
	// 		if _rc {
	// 			dis as err "a dataset used in this example is not in the current directory"
	// 			dis as err `"> {it:{stata `"net get geo2xy, from("http://fmwww.bc.edu/repec/bocode/g")"':click to install geo2xy example datasets from SSC}}"'
	// 			exit 601
	// 		}
	// 	}
	// }
	
	
	quietly {

		capture confirm file `"`using'"'
		if _rc {
			findfile `"`using'"'
			local helpfile `"`r(fn)'"'
		}
		else local helpfile `"`using'"'

		`preserve'
		
		infix str s 1-244 using `"`helpfile'"', clear
		
		gen long obs = _n
		
		sum obs if strpos(s, "{* example_start - `example_name'}{...}")
		if r(min) == . {
			dis as err "example `example_name' not found"
			exit 111
		}
		local pos1 = r(min) + 1
		sum obs if strpos(s, "{* example_end}{...}") & obs > `pos1'
		local pos2 = r(min) - 1
	
		if mi(`pos1',`pos2') exit
		
		keep in `pos1'/`pos2'
		
		// remove code hidden in SMCL comments
		replace s = regexr(trim(s), "}{...}", "") if substr(s,1,3) == "{* "
		replace s = substr(s,4,.) if substr(s,1,3) == "{* "
		
	}
	
	tempfile f
	outfile s using "`f'", noquote
	do "`f'"
	
end
