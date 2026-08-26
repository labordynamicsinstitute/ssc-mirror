*! _ardldml_blockgraph 1.0.0  24aug2026
*! graph helper for ardldml -- DML-Bounds
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
*  Lives in its own file rather than inside ardldml.ado because
*  ardldml_estat.ado calls it: a sub-program defined inside another ado is
*  only in memory while that ado is loaded, and Stata resolves a command
*  name to a file of the same name.

program define _ardldml_blockgraph
	version 14.0
	syntax [, NAME(string) *]

	tempname Fm
	matrix `Fm' = e(blocks_tab)
	local K = rowsof(`Fm')
	local h = e(buffer)
	local n = e(N)
	local nm "ardldml_blocks"
	if ("`name'" != "") local nm "`name'"

	preserve
	quietly {
		clear
		svmat double `Fm', name(bk)
		gen int block = _n
		gen double lo = bk1
		gen double hi = bk2

		// The buffer is the point of the picture, so draw the whole
		// withheld span behind the evaluation window: the pale bar is
		// what leaves that block's training set, the solid bar is what
		// is actually evaluated, and the difference is the buffer.
		gen double blo = max(1, lo - `h')
		gen double bhi = min(`n', hi + `h')

		local leg "legend(off)"
		if (`h' > 0) {
			local leg `"legend(order(1 "withheld (evaluation + buffer)" 2 "evaluation window") rows(1) size(small) position(6) ring(1) region(lstyle(none)))"'
		}

		twoway (rbar blo bhi block, horizontal barwidth(.62)				///
					color(navy%18) lcolor(navy%35) lwidth(vthin))			///
			   (rbar lo hi block, horizontal barwidth(.50)					///
					color(navy%75) lcolor(navy)),							///
			   ytitle("cross-fitting block") xtitle("observation index")		///
			   ylabel(1(1)`K', angle(0)) yscale(reverse)					///
			   xscale(range(0 `n'))											///
			   title("h-block cross-fitting structure")						///
			   subtitle("K = `=e(blocks)' blocks, buffer h = `h', n = `n'")	///
			   note("Each block is evaluated by a model fitted on every other"	///
					" observation except the pale span, so the first-stage error"	///
					" is decoupled from the evaluation-fold innovations.")	///
			   `leg' graphregion(color(white)) plotregion(color(white))		///
			   name(`nm', replace) `options'
	}
	restore
end
