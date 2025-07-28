/*
tree_plot.ado  -- 2023Sep20, David Kantor.

NOT TO BE confused with treeplot.ado -- a separate user-generated program,
by Giovanni Cerulli, available from SSC.

This is an adjunct to tree.ado; provides the plotting capability.

Originally, this was intended to be temporary, to be added to tree.ado.
Later (2023oct05 and later), it was decided to keep it as a separate file.


2024jun17: adapting for rptbr.
2024nov20: moved action routines into tree_traverse.ado.
2025jan14: Just editing comments.

~~~See whether the globals can be eliminated ????

*/

program tree_plot

* version 1.0.0 2023oct18
* version 1.0.2 2024jun17
*! version 2.0.0 2025may05
version 14



local prob_places_default "3"


syntax [varlist(default=none)], [superlabel(string) numbers GPHSAVing(string) gphasis gphreplace ///
	dosave(string) doreplace verbose prob_places(integer `prob_places_default') ///
	noprob rptbr BASEnames]
/* Note that this does not have a surrogates option, as found in tree_draw.
Probably not needed; use tree_draw to get that info.

BASEnames: introduced 2025may05. Specifies that `varlist' consists of the basenames
of payoff vars, and that we are to use the R_ versions of these vars. This restores
the pre-2.0 behavior.
*/

global tree_superlabel `"`superlabel'"'
global tree_numbers "`numbers'"
global tree_noprob "`prob'"

if `prob_places' <0 {
	disp as err "prob_places must be non-negative"
	exit 198
}

local prob_places_tot = `prob_places' + 2
global tree_prob_fmt "%`prob_places_tot'.`prob_places'g"



global tree_varstodisp "`varlist'"

if "`varlist'" ~= "" & "`basenames'" ~= "" {
	local payoffvars `: char _dta[payoffvars]'
	if ~`: list varlist in payoffvars' {
		disp as err "varlist must be subset of payoffvars"
		exit 198
	}
	/*
	Form the set of vars to display in a plot.
	User has input the base names; we interpret them to mean the R_ variables.
	*/
	foreach v of local varlist {
		local varstodisp "`varstodisp' R_`v'"
	}
	global tree_varstodisp "`varstodisp'"
}

if "`rptbr'" ~= "" {
	if "`:char _dta[rptbr]'" == "" {
		disp as err "No rptbr established"
		exit 459
	}
	else {
		local startingnode "`:char _dta[rptbr]'"
	}
}
else {
		local startingnode "1"
}




/* Determine the __ypos values. */
tempvar n_visits
global tree_maxdepth -1 /* start below 0; first actual depth is 0 */
tree_traverse, depth(0) n_visits(`n_visits') id(`startingnode') parent(0) action1(set_ypos) action4(set_ypos) surrogate `verbose'

assert ~mi(`n_visits')

summ __ypos if `n_visits'>0, meanonly
global tree_triangle_half_height = (r(max) - r(min))/(2*44)

/* -- r(min) ought to be 0, but we code for the general case. */

global tree_triangle_width = $tree_maxdepth * 16 / 70
global marker_xsep = $tree_triangle_width/2
/* marker_xsep: separation in the x direction to prevent lines from penetrating the circles. */


if `"`dosave'"' ~= "" {
	detect_file_ext, fname(`"`dosave'"')
	if ~`s(ext_detected)' {
		disp "appending .do to dosave name"
		local dosave `"`dosave'.do"'
	}
	local dofilename `"`dosave'"'
}
else {
	tempfile dofilename
}
if "`doreplace'" ~= "" {
	local doreplace "replace"
}

tempname gfile
file open `gfile' using `"`dofilename'"', write text `doreplace'
/* We could add an option for the -all- option to -file open-. */


file write `gfile' `"/* `dofilename'"' _n
file write `gfile' "Created by tree.ado, $S_DATE $S_TIME" _n
file write `gfile' "*/" _n
file write `gfile' "#delimit ;" _n _n

/* Set gfile as a global as well, to communicate with the procedures that
write to it via tree_traverse. The alternative is to add an option to all the
action routines. Using a global is less disruptive.
*/
global tree_gfile "`gfile'"

file write `gfile' "twoway" _n


tree_traverse, depth(0) id(`startingnode') parent(0) action1(plot_node) surrogate `verbose'

file write `gfile' ", yscale(reverse off) xscale(off) legend(off)"

if `"`gphsaving'"' ~= "" {
	file write `gfile' `" saving(`"`gphsaving'"',"'
	if "`gphasis'" ~= "" {
		file write `gfile' " asis"
	}
	if "`gphreplace'" ~= "" {
		file write `gfile' " replace"
	}
	file write `gfile' ")" _n
}

file write `gfile' ";" _n

file close `gfile'


disp "doing the file... "

do `"`dofilename'"'

end /* tree_plot */

prog def detect_file_ext, sclass
/* Determine whether a filename has an extension.
The criterion is that there is a . in the name -- not including the directory
spec if present.
*/
syntax, fname(string)

local fname = subinstr(`"`fname'"', "\", "/", .)
local fnamerev = strreverse(`"`fname'"')

local p1 = strpos(`"`fnamerev'"', "/")
local p2 = strpos(`"`fnamerev'"', ".")

assert ~mi(`p1')
assert ~mi(`p2')

sreturn local ext_detected = `p2' & (~`p1' | (`p2' < `p1'))

end /* detect_file_ext */
