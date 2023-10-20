/*
tree_plot.ado  -- 2023Sep20, oct6, 17, 18; David Kantor.

NOT TO BE confused with treeplot.ado -- a separate user-generated program, from SSC.

This is an adjunct to tree.ado; provides the plotting capability.

Originally, this was intended to be temporary, to be added to tree.ado.
Later (2023oct05 and later), it was decided to keep it as a separate file.
*/

program tree_plot

* version 1.0.0 2023oct18
version 14



local prob_places_default "3"


syntax [varlist(default=none)], [superlabel(string) numbers GPHSAVing(string) gphasis gphreplace ///
	dosave(string) doreplace verbose prob_places(integer `prob_places_default') ///
	noprob]

global tree_superlabel `"`superlabel'"'
global tree_numbers "`numbers'"
global tree_noprob "`prob'"

if `prob_places' <0 {
	disp as err "prob_places must be non-negative"
	exit 198
}

local prob_places_tot = `prob_places' + 2
global tree_prob_fmt "%`prob_places_tot'.`prob_places'g"


if "`varlist'" ~= "" {
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
else {
	global tree_varstodisp
}




/* Stuff that should go into tree.ado, in tree_init,
minus the -capture-. This is fo if we ever meld tree_plot into tree.ado.
*/
capture gen float __ypos = .
/* END Stuff that should go into tree.ado, in tree_init */



/* Determine the __ypos values. */
global tree_maxdepth -1 /* start below 0; first actual depth is 0 */
tree_traverse, depth(0) id(1) parent(0) action1(set_ypos_term) action4(set_ypos_int) `verbose'

summ __ypos, meanonly
global tree_triangle_half_height = (r(max) - r(min))/(2*44)
/* -- r(min) ought to be 0, but we code for the general case. */

global triangle_width = $tree_maxdepth * 16 / 70
global marker_xsep = $triangle_width/2
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
action routines. This is less disruptive.
*/
global tree_gfile "`gfile'"

file write `gfile' "twoway" _n


tree_traverse, depth(0) id(1) parent(0) action1(plot_node) `verbose'

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



prog def plot_node
/* An action1 routine. */
syntax, id(integer) parent(integer) depth(integer) [location(string) verbose]
/* The filehandle is communicated via a global: tree_gfile. */


/* The l1 and r1 variants of xpos* are for preventing the lines from penetrating the circles. */ 

local horiz_len "12"
local superroot_horiz_len "5"

local xpos_parent =(`depth'-1) * 16 +4
local xpos_parent_r1 = `xpos_parent' + $marker_xsep



local xpos = `depth' * 16 +4
local xpos_l1 = `xpos' - $marker_xsep
local xpos_l2 = `xpos' - `horiz_len'  /* for the bend between the angled and horizontal line-segments */
local xpos_l3 = `xpos' -`superroot_horiz_len'  /* for the line before the superroot */

local ypos = __ypos[`id']
local ypos_parent = __ypos[`parent']

local state_vec_gap "0"

if `parent' >0 {
	#delimit ;
	file write $tree_gfile " pci `ypos_parent' `xpos_parent_r1' `ypos' `xpos_l2'";  /* angled line */
	file write $tree_gfile "	`ypos' `xpos_l2' `ypos' `xpos_l1', lcolor(black) ||" /* horizontal line */
	_n;
	#delimit cr
	/* Supposedly, you can put "label text" into the pci, but I find that it doesn't work.
	So do the label separately:
	
	*/
	if __nodetype[`id'] == "terminal":nodetype {
		left_facing_triangle, ypos(`ypos') xpos(`xpos') half_height($tree_triangle_half_height) width($triangle_width) xsep($marker_xsep)
		local msym "i" /* invisible; for the next scatteri. */
		local state_vec_pos "3" /* to the right */
		local state_vec_gap = 1-$marker_xsep
		/* ~~~ That 1 should really be a width parameter; same width as in option to left_facing_triangle. */
		
	}
	else {
		local msym "O" /* circle; for the next scatteri. */
		local state_vec_pos "8" /* to the left, below */
	}
	if __nodetype[`id'] == "root":nodetype {
		/* This should line up with depth ==1. */
		local fillcolor "ltblue"
	}
	else {
		local fillcolor "yellow"
	}

	/* Next: scatteri is for the nodes.
	Also put in the nodename ~~~or label~~~.
	*/
	/* Label the node with text (node name ~~~or the node label), plus (prob in parens).
	*/
	if "$tree_noprob" == "" {
		if mi(R_prob[`id']) {
			local probtext: disp %1.0g R_prob[`id']
		}
		else {
			local probtext: disp $tree_prob_fmt R_prob[`id']
		}
		local probtext " (`probtext')"
	}
	local nodelabel =__nodename[`id']
}
else {
	/* `parent' = 0 -- i.e., no parent; this should occur only for the superroot,
	that is, __nodetype[`id'] == "superroot":nodetype.
	*/
	file write $tree_gfile " pci `ypos' `xpos_l3' `ypos' `xpos_l1', lcolor(black) ||" _n
	
	local superlabel "`=__nodename[`id']'"
	if "$tree_superlabel" ~= "" {
		local superlabel "$tree_superlabel"
	}
	
	local nodelabel "`superlabel'"
	local msym "S" /* Square */
	local fillcolor "pink"
}


file write $tree_gfile `" scatteri `ypos' `xpos' "`nodelabel'`probtext'", mlabposition(10)  mlabsize(vsmall) mlabcolor(black) msym(`msym') mcolor(black) mfcolor(`fillcolor') msize(medium) mlabgap(0) ||"' _n


/* The state vector */
if "$tree_varstodisp" ~= "" {
	foreach v of global tree_varstodisp {
		local vars_disp_text "`vars_disp_text' `:disp `v'[`id']'"
	}
	file write $tree_gfile `" scatteri `ypos' `xpos' "`vars_disp_text'", mlabposition(`state_vec_pos') mlabsize(vsmall) mlabcolor(black) msym(i) mlabgap(`state_vec_gap') ||"' _n
}

/* Node numbers */
if "$tree_numbers" ~= "" {
	/* display the node number */
	file write $tree_gfile `" scatteri `ypos' `xpos' "`id'", mlabposition(6) mlabgap(0) ms(i) ||"' _n
}

end /* plot_node */



prog def left_facing_triangle
syntax, ypos(real) xpos(real) half_height(real) width(real) xsep(real)

local xpos_l1 = `xpos' - `xsep'
local xpos_r1 = `xpos' + `width' - `xsep'
local ypos_plus = `ypos'+ `half_height'
local ypos_minu = `ypos'- `half_height'

#delimit ;
file write $tree_gfile " pci
`ypos' `xpos_l1'
`ypos_plus' `xpos_r1'

`ypos_plus' `xpos_r1'
`ypos_minu' `xpos_r1'

`ypos_minu' `xpos_r1'
`ypos' `xpos_l1', lcolor(black) ||"
_n;
#delimit cr

end /* left_facing_triangle */





prog set_ypos_term
/* An action1 routine.
Set __ypos of a given TERMINAL node only.
Also set a few other items (globals).
*/
syntax, id(integer) parent(integer) depth(integer) [location(string) verbose]
if `depth' > $tree_maxdepth {
	/* First time visiting this depth */
	global tree_maxdepth `depth'
	global tree_ypos_`depth' /* clear */
}

if __nodetype[`id'] == "terminal":nodetype {

	if "${tree_ypos_`depth'}" == "" {
		local next_avail_ypos 0
	}
	else {
		local next_avail_ypos = ${tree_ypos_`depth'} + 16
	}
	replace_ypos = `next_avail_ypos' in `id' , depth(`depth') `verbose'
	if "`verbose'" ~= "" {
		disp "set_ypos_term; node `id', dep `depth', __ypos " __ypos[`id']
	}
}

end /* set_ypos_term */



prog set_ypos_int
/* An action3 routine.
Set __ypos of a given INTERIOR node (or root or superroot) only.
Also set a few other items (globals).
*/
syntax, id(integer) parent(integer) depth(integer) [location(string) verbose]
if `depth' > $tree_maxdepth {  /* shouldn't happen */
	global tree_maxdepth `depth'
	global tree_ypos_`depth' /* clear */
}

if __nodetype[`id'] < "terminal":nodetype {

	if "${tree_ypos_`depth'}" == "" {
		local next_avail_ypos 0
	}
	else {
		local next_avail_ypos = ${tree_ypos_`depth'} + 16
	}

	local mean_ypos_of_children = ///
	 (__ypos[__branch_head[`id']] + __ypos[__branch_tail[`id']])/2
	/*~~~*/ /* disp "set_ypos_int; mean_ypos_of_children `mean_ypos_of_children'" */
	if mi(`mean_ypos_of_children') {
		/* There are no children; an improper condition, but can happen easily. */
		local mean_ypos_of_children "`next_avail_ypos'"
	}
	
	replace_ypos = `mean_ypos_of_children' in `id', depth(`depth')

	if "`verbose'" ~= "" {
		disp "set_ypos_int; node `id', dep `depth', __ypos " __ypos[`id']
		disp " ---- next_avail_ypos `next_avail_ypos'"
	}
	if `mean_ypos_of_children' < `next_avail_ypos' {
		global tree_ypos_increment = `next_avail_ypos' - `mean_ypos_of_children'
		/* Increment that node's ypos, as well as all its descendants -- the subtree
		rooted at `id'.
		
		This shall have the effect of making __ypos[`id'] = `next_avail_ypos'.
		Note, too, that this is one tree-traversal routine that invokes
		another tree-traversal routine.
		*/
		if "`verbose'" ~= "" {
			disp " -- incrementing subtree by $tree_ypos_increment"
		}
		tree_traverse, depth(`depth') id(`id') parent(`parent') action1(increment_ypos) `verbose'
		/* increment_ypos will take care of adjusting tree_ypos_`depth' in the depth of the
		present node and all decendant nodes.
		*/
	}
}


end /* set_ypos_int */


prog def replace_ypos
syntax =/exp in, depth(integer) [verbose]
/* replace __ypos at a specified obsno. But also maintain tree_ypos_`depth'.
The in-use syntax will resemble -replace __ypos=...- but is different in that
a depth option is required.

The -in- feature could take a range, but it is intended to take a single value.
*/

tempname newvalue
scalar `newvalue' = `exp'


if "`verbose'" ~= "" {
	disp "replace_ypos = `=`newvalue'' `in' " _cont
}
else {
	local qui "qui"
}

`qui' replace __ypos =`newvalue' `in'
/* -- if not qui, then the report from the -replace- will end the disp line. */


if "${tree_ypos_`depth'}" == "" {
	global tree_ypos_`depth' =`newvalue'
	if "`verbose'" ~= "" {
		disp " initialized tree_ypos_`depth'"
	}
}
else if ${tree_ypos_`depth'} < `newvalue' {
	global tree_ypos_`depth' =`newvalue'
	if "`verbose'" ~= "" {
		disp " reset tree_ypos_`depth'"
	}
}
/* Based on how this program is used, we would proabably activate one of those paths
that initialize or reset tree_ypos_`depth'. I.E., if you put an -else- here,
it would not be reached.
*/

end /* replace_ypos */



prog def increment_ypos
/* An action1 routine. */
syntax, id(integer) parent(integer) depth(integer) [location(string) verbose]

replace_ypos = __ypos[`id'] + $tree_ypos_increment in `id', depth(`depth')
end /* increment_ypos */




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



prog def tree_traverse
/* Regretably, it is necessary to have a copy of this in both tree.ado and
tree_plot.ado.  -- Unless we meld tree_plot into tree.ado.
*/

/* This shall do recursive calling! */
syntax, id(integer) parent(integer) depth(integer) ///
	[location(string) action1(name) action4(name) VERbose]

/*
id: the obs no of the node that is visited; all of the children of this node are
then visited -- recursively.

Presumably, when this is first called, id is the root of the tree being traversed.

action1,4 program names -- to be called at various points.

Prior to 2023may05, we had action2 & 3; eliminating them.
Previous Action3 rotines will be blended into action1 routines, but reverse the parent-child roles.
See tree.ado_save021 for historical reference.

action1 is what is to be DONE at each node as it is visited, prior to
traversing the descendant nodes.

[action3 is done immediately after traversing a child node, for passing info from
child back to the present node.]

action4 is done after traversing all child nodes.
(action4 added 2022mar01.)
Keep the name action4 as historical legacy.

These are the options that action routines must take:
action1: id, parent, depth, location
action4: id, parent, depth, location

All take optional verbose; added 2022oct27.
In action1, parent was added 2022feb28.
[child, for action3, is locally generated -- not passed in.]

Adding a probno option; 2022feb28, 21:57. Removed, 2022jun27.


Each of these is expected to have the options shown above.
BUT because of the generality, an instance of a given species of action routine
must take all the options, but might not use them all.

Similarly, not every call to tree_traverse needs all the options.
*/

if _N <1 {
	disp "(no tree)"
	exit 0
}

/*~~*/  /*disp "tree_traverse; id `id', depth `depth'" */

local location "`location' `=__nodename[`id']'"
/* Note that location initially comes in as the parent's location, but
it now pertains to the present node.
*/

/*~~debug: disp "tree_traverse; location `location'" */


if "`action1'" ~= "" {
	`action1', id(`id') parent(`parent') depth(`depth') location(`location') `verbose'
}

local jj = __branch_head[`id']

/* action2 would go here, conditionally; but never needed it. */

while ~mi(`jj') {
	/* Recursive call: */
	tree_traverse, id(`jj') parent(`id') depth(`=`depth'+1') ///
		location(`location') ///
		action1(`action1') action4(`action4') `verbose'
	local jj = __next[`jj']
}

if "`action4'" ~= "" {
	`action4', id(`id') parent(`parent') depth(`depth') location(`location') `verbose'
}
end /* tree_traverse */

