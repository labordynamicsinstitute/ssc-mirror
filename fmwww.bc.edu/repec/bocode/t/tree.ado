/*
tree.ado
Decision-Tree facility.
David Kantor, began 2021may03
*/

prog def tree
* version 1.1.1 2021may03
* version 1.2.1 2022dec13
* 2023jun28: public release.
* version 1.3.1 2023jun28
* version 1.3.2 2023oct10
* version 1.4.0 2023oct18
*! version 1.5.0 2024jun10


/*
2023oct02: edited comments.
3032oct18: tree-traversal is now coded in its own ado file: tree_traverse.ado.
PS: later putting it back in!
*/



version 14


#delimit ;
local allowable_subcmd
 "init create node draw verify eval check setvals diffs
 values a_minus_b preserveprob preservepayoff restoreprob restorepayoff
 preserveall restoreall des plot";
#delimit cr

/* Note that "plot" invokes tree_plot, which is defined in a separate filr:
tree_plot.ado.
*/


gettoken subcmd 0 :0 , parse(" ,")
local subcmd = trim("`subcmd'")

/*~~~~debug~~~ disp "subcmd <`subcmd'>" */

if "`subcmd'" == "" | "`subcmd'" == "," {
	local errmsg1 "subcommand required"
}
else if ~`: list subcmd in allowable_subcmd' {
	local errmsg1 "invalid subcommand `subcmd'"
}

if "`errmsg1'" ~= "" {
	disp as err `"`errmsg1'"'
	disp as err "allowable subcommands: " as text "`allowable_subcmd'"
	exit 198
}

tree_`subcmd' `0'

end /* tree */


prog def assert_tree_data_present
if _N<1 {
	disp as err "No data present."
	exit 459
}
capture confirm var __nodename  __branch_head __branch_tail __next prob
if _rc {
	disp as err "Dataset not configured for trees."
	exit 459
}

end /* assert_tree_data_present */



prog def tree_init
/* This creates the superroot node. Its __nodename is set to "superroot". */
syntax namelist, [VERbose]
if "`verbose'" == "" {
	local qui "qui"
}
else {
	disp "you called tree_init `0'"
}

if _N>0 {
	disp as err "You must start with an empty dataset."
	exit 459
}

local namelist_orig: list retokenize namelist
/* We do retokenize because list uniq also reduces spaces; need a fair comparison. */
local namelist: list uniq namelist
if "`namelist_orig'" ~= "`namelist'" {
	disp "namelist contained duplicate elements; reducing to unique names."
}

#delimit ;
local reserved_names "
__nodename
__nodetype
__branch_head
__branch_tail
__next
__probsum
__n_starprobs
__residprob
__residual
__weight
prob R_prob
setvals_qui
setvals_node_id
setvals_varstoset
setvals_vval
setvals_vars_affected
verbose
check
sub
";
#delimit cr
/*
The ones beginning with "setvals_" are locals used in tree_setvals.
"verbose", "check", and "sub" are options to tree_setvals, and are thus,
locals therein as well. Since payoff varnames become options to tree_setvals,
using such names would cause a conflict.
*/

local namelist_reserved: list namelist & reserved_names
if "`namelist_reserved'" ~= "" {
	disp as err "proposed payoff varlist includes reserved name(s) `namelist_reserved'"
	disp as err "reserved names: " as text "`reserved_names'"
	exit 198
}


foreach v of local namelist {
	local len1 = strlen("`v'")	
	if `len1' > 30 {
		disp as err "name `v' exceeds length limit of 30"
		local len_err "Y"
	}
}

if "`len_err'" ~= "" {
	exit 198
}

foreach v of local namelist {
	local len1 = strlen("`v'")	
	if `len1' > 29 {
		disp as text "name `v' exceeds length 29"
		local len_29 "Y"
	}
}

if "`len_29'" ~= "" {
	disp "Note:"
	disp "Names with length exceeding 29 will cause problems if {cmd:tree eval} is called"
	disp "with a {opt rawsum} or {opt means} option, followed by {cmd:tree diffs},"
	disp "{cmd:tree a_minus_b}, or {cmd:tree values} with a prefix longer than 1."
	/* But not fatal at this point. */
}

`qui' set obs 1

gen str32 __nodename = "superroot" 
/* gen str40 __nodelabel = "superroot" */
label def nodetype 0 "superroot" 1 "root" 2 "interior" 3 "terminal"

gen byte __nodetype = "superroot":nodetype
label val __nodetype nodetype
/*
Prior to 2022oct18, __nodetype did not have a label. Also, the numbering scheme was
lower by 1. Notes regarding these values are being rewritten, even if dated prior to 2022oct18.
*/

`qui' {
	gen int __branch_head = .
	gen int __branch_tail = .
	gen int __next = .
	gen double __probsum = . /* sum of non-residual probs in child nodes */
	gen int __n_starprobs = . /* num child nodes with residual probs */
	gen double __residprob = . /* apportioned residual probability in child nodes */
	gen byte __residual = 0  /* whether prob is specified as residual; see note below */
}
/* __branch_head and __branch_tail are for the child nodes;
__next is for the chain that the present node may be in.
*/

gen strL prob = "*"
`qui' gen double R_prob = .z
/*
prob is the user-stated probability; it may be an expression!
R_prob is the evaluated version of prob. It will also potentially be calculated.
It is...
	the evaluation of prob, if prob is nonmissing;
	a calculated (residual) value if prob=="*"; see note, below.
There will also be prob1, prob2, etc -- preserved versions of prob.

A value of "*" for prob is fitting but meaningless in the superroot.

2023oct09: we keep a var named __residual to indicate that the prob is specified
as resudual. We now will be using this rather than testing for prob == "*" -- to
accommodate the case of prob being an expression (say a scalar) that evaluates
to "*". That was not previously handled correctly.

*/


/*
prob holds the probability of the present branch. We allow a node to be
attached to only one parent node.

If specified as "*", we will calculate a residual probability:
(1- sum of all nonmissing probs in sibling nodes) / (num missing probs).

(Earlier plan was to do this whenever it was missing; cancelled that.)


namelist will establish numeric (double) content (payoff) vars.
But the initial "intake" will be string; allow expressions.


*/

local maxlen "0"
foreach v of local namelist {
	`qui' gen strL `v' = ""
	`qui' gen double R_`v' = .
	local maxlen = max(`maxlen', length("`v'"))
}
char _dta[maxlen] "`maxlen'" // max length of elements of payoffvars


/*
`v': user-stated value; it may be an expression; used in terminal nodes only. 
R_`v' is the corresponding calculated numeric value.
There will also be `v'1, `v'2, etc -- preserved versions of `v'.
*/

char _dta[payoffvars] "`namelist'"
/* char _dta[payoffvars] is the set of BASEnames of payoffvars! */

foreach v of local namelist {
	local payoffvaroptions "`payoffvaroptions' `v'(string)"
}
if "`verbose'" ~= "" {
	disp "payoffvaroptions: `payoffvaroptions'"
}
char _dta[payoffvaroptions] "`payoffvaroptions'"

global tree_rawsumvars_prior
global tree_meansvars_prior

`qui' gen double __weight=.

end /* tree_init */



prog def find_child_node, sclass
/* Look for a given named node among the children of a given node.
Look in only that one level.
*/
syntax name(name= nodename), id(integer) [require(string)]

if `id' == 0 {
	/* `id' 0 is a phantom pre-superroot node.
	This allows you to search for superroot.
	*/
	local jj "1"
}
else {
	local jj = __branch_head[`id']
}

local node_id = 0

while ~mi(`jj') {
	if __nodename[`jj'] == "`nodename'" {
		local node_id = `jj'
		continue, break
	}
	local jj = __next[`jj']
}
sreturn local node_id = `node_id'

if `id' == 1 {
	local nodeortree "tree"
}
else {
	local nodeortree "node"
}


if "`require'" == "exist" {
	if ~`s(node_id)' {
		disp as err "`nodeortree'`nodename' not found"
		exit 198
	}
}
else if "`require'" == "noexist" {
	if `s(node_id)' {
		disp as err "`nodeortree' `nodename' already exists."
		exit 198
	}
}

end /* find_child_node */



prog def find_node_via_path, sclass
/* Look for node as named by its complete path through the forest. */
syntax namelist(name= path),[require(string)]
/* require: exist or noexist; any other value is ignored. */

gettoken leadname path: path /* path is now the remaining part of the path. */
if "`leadname'" == "superroot" {
	local startingnode "0"
}
else {
	local startingnode "1"
}



find_child_node `leadname', id(`startingnode')
while `s(node_id)' & "`path'" ~= "" {
	gettoken leadname path: path
	find_child_node `leadname', id(`s(node_id)')
}

sreturn local node_id = `s(node_id)'

if "`require'" == "exist" {
	if ~`s(node_id)' {
		disp as err "node `leadname' not found"
		exit 198
	}
}
else if "`require'" == "noexist" {
	if `s(node_id)' {
		disp as err "node `leadname' already exists."
		exit 198
	}
}

end /* find_node_via_path */








prog def tree_create
assert_tree_data_present
syntax namelist(name= treename), [/*label(string)*/ VERbose]
if "`verbose'" ~= "" {
	disp "you called tree_create `0'"
}

if "`treename'" == "superroot" {
	disp as err "superroot is not allowed as a tree name."
	exit 198
	/*
	Actually, this is just to avoid confusion to the users.
	BUT, we  may later implement the possibility of referring to the superroot
	node in diffs and value extraction; THEN, it will be important to prohibit
	superroot as a tree name. (2022sep16)
	PS: a wild idea: prohibit a child from having the same name as its parent.
	That would cover this condition. (Actually, it would require programming
	changes both here and in tree_node_00.) Just a wild idea; no need to take it
	seriously.
	*/
}
/* Prior to 2022oct11, there was...
find_tree `treename', require(noexist)
create_node `treename', attach_id(1) nodetype("root":nodetype) label(`label')
-- That was limited to a single tree at a time.

Starting 2022oct11, we do this using create_and_attach_nodes:
*/

create_and_attach_nodes, nodelist1(`treename') nodetype1(`="root":nodetype') ///
		tag1(treename)  id(1) `verbose'

/* Also prior to 2022oct11, there was...
local node_id "`s(node_id)'"
replace prob = "*" in `node_id'

If that were to be used after the 2022oct11 change, it would still work, but...
1: That ref to s(node_id) would be for the LAST one of a series, if multiple
tree names are specified. (This was tested and verified.) To remedy this
(to have it apply to all trees in multitude) would involve some programming tricks
that are not worthwhile.
2: There is no real need to set prob = "*" in the tree roots.
3: The user will be able to set prob in the tree roots.

So we don't do this any more.
*/

end /* tree_create */




prog def one_or_the_other_not_both
syntax, [a(string) b(string)] aname(string) bname(string)

if "`a'" == "" {
	if "`b'" == "" {
		disp as err "you must specify either `aname' or `bname'"
		exit 198
	}
}
else {
	if "`b'" ~= "" {
		disp as err "you may not specify both `aname' and `bname'"
		exit 198
	}
}
end /* one_or_the_other_not_both */



prog def tree_setvals
/* Set the payoff values for a terminal node.
2022jul05: include prob here, too. This absorbs tree_setprobs.
(This may be sort-of restoring an earlier scheme.)

2023mar15: all locals get a prefix of "setvals_", to make it unlikely that a
payoff var will have the same name. But we wll also prohibit such names.
This can't be done with the syntax options (verbose check nosub), but those will be prohibited, as well.

*/
assert_tree_data_present
*** old: syntax namelist(name= nodespec min=2 max=2), [`:char _dta[payoffvaroptions]']
syntax [namelist], [at(namelist) `:char _dta[payoffvaroptions]' prob(string) VERbose check nosub debug]

one_or_the_other_not_both, a(`namelist') b(`at') aname(a namelist) bname(an at() option)
if "`at'" ~= "" {
	local namelist "`at'"
}

if "`verbose'" ~= "" {
	disp `"tree_setvals, 0: `0'"'
}
else {
	local setvals_qui "qui"
}

/*
Note that payoff values should be settable in terminal nodes only;
probs should be settable in terminal or interior nodes.
*/

find_node_via_path `namelist', require(exist)
local setvals_node_id "`s(node_id)'"

local setvals_varstoset `: char _dta[payoffvars]' prob
if "`verbose'" ~= "" {
	disp "setvals_varstoset: `setvals_varstoset'"
}
global tree_eval_errors
foreach v of local setvals_varstoset {
	if "`debug'" ~= "" {
		disp "v: `v', <``v''>"
	}
	local setvals_vval = trim(`"``v''"') // See note below.
	if "`debug'" ~= "" {
		disp "setvals_vval: <`setvals_vval'>"
	}
	if `"`setvals_vval'"' ~= "" {
		if "`v'" ~= "prob" & __nodetype[`setvals_node_id'] < "terminal":nodetype {
			disp as err "payoff vars are settable in terminal nodes only"
			disp as text "var `v'; node_id `setvals_node_id'"
			exit 198
		}
		if "`sub'" == "" {
			`setvals_qui' replace `v' = subinstr(`"`setvals_vval'"', "@", "\$", .) in `setvals_node_id'
		}
		else {
			`setvals_qui' replace `v' = `"`setvals_vval'"' in `setvals_node_id'
		}

		local setvals_vars_affected "`setvals_vars_affected' `v'"
	}
}

if "`setvals_vars_affected'" ~= "" & "`check'" ~= "" {
	assign_Rvals `setvals_vars_affected', id(`setvals_node_id') location(`namelist') `verbose'
}

if "$tree_eval_errors" ~= "" {
	exit 198
}

if "`setvals_vars_affected'" == "" {
	disp "(no settings specified)"
}
/*
Note: setvals_vval is subject to the trim operation; this value then goes into `v'.
Therefore, `v' is always trimmed, and thus, there is no need to do a trim operation
in any subsequent references to `v' (in other subprograms).
I'm removing those trim operations, 2022nov17.
*/
end /* setvals */






prog def create_node, sclass
syntax name(name= nodename), attach_id(integer) nodetype(integer) [/*label(string)*/ VERbose]
if "`verbose'" == "" {
	local qui "qui"
}
/*
Many other programs in this ad-file have an attach option which is of type
name. Here, it is an integer; thus, we give it a distinct name: attach_id.
This is the obsno of the node to which to attach the new node.

The idea is that, if you are creating a node, you better have a place in mind to
attach it. (The superroot could be an exception, but we don't plan to use this
for the superroot -- though we could.)

Distinguish the nodetype option and the __nodetype variable.

*/

local node_id = _N+1
if `attach_id' == `node_id' {
	disp as err "You may not attach a node to itself."
	exit 198
	/* We prevent a node from attaching to itself,
	but we don't go as far as to prevent longer cycles.
	This might be an impossible situation anyway; it would be an internal error.
	*/
}

if __nodetype[`attach_id'] == "terminal":nodetype {
	disp as err "You may not attach to a terminal node."
	exit 198
}

`qui' set obs `node_id'

`qui' replace __nodename = "`nodename'" in `node_id'
`qui' replace __residual = 0 in `node_id'

/*
if "`label'" ~= "" {
	`qui' replace __nodelabel = `"`label'"' in `node_id'
}
*/

/* We will trust that all other vars in `node_id' are missing at this point.
This is especially important for __branch_head, __branch_tail, and __next.
*/

if mi(__branch_head[`attach_id']) {
	/* Really, we want only 1 .. _N-1. */
	`qui' replace __branch_head = `node_id' in `attach_id'
	`qui' replace __branch_tail = `node_id' in `attach_id'
}
else {
	local old_tail = __branch_tail[`attach_id']
	`qui' replace __next = `node_id' in `old_tail'
	`qui' replace __branch_tail = `node_id' in `attach_id'
}

`qui' replace __nodetype = `nodetype' in `node_id'

sreturn local node_id "`node_id'"
end /* create_node */



prog def create_and_attach_nodes
/* Began 2022sep28. This replaces tree_node_00. */

syntax, [nodelist1(namelist) nodelist2(namelist) nodetype1(integer -2) nodetype2(integer -2) ///
	tag1(string) tag2(string) verbose] id(integer)
/* We use -2 to signify unspecified nodetype1 or nodetype2. Actually, 2 ought to be the lowest value
allowed.
*/
local max_nodelists 2
forvalues jj = 1 / `max_nodelists' {
	if "`nodelist`jj''" ~= "" {
		local nodelistb`jj': list uniq nodelist`jj'
		if "`nodelistb`jj''" ~= "`nodelist`jj''" {
			disp "Nodelist `tag`jj'' has duplicates; reducing to unique names."
		}
		if `nodetype`jj'' <= -2 {
			disp as err "nodetype`jj' absent or incorrectly specified"
			/* This would be a programming error, not a user error. */
			exit 198
		}
	}
}

/* Test for overlap. */
forvalues jj = 2 / `max_nodelists' {
	forvalues kk =  1 / `=`jj'-1'  {
		local overlap: list nodelistb`kk' & nodelistb`jj'
		if "`overlap'" ~= "" {
			disp as err "`tag`kk'' and `tag`jj'' options must not have common elements (`overlap')."
			exit 198
		}
	}
}

forvalues jj = 1 / `max_nodelists' {
	/* Keep the following loops separate; not combined -- so that all errors
	(node already exists) can be caught before making changes to the trees.
	*/

	foreach node of local nodelistb`jj' {
		/* Make sure the node doesn't already exist at `id'. */
		find_child_node `node', id(`id')  require(noexist)
	}
	foreach node of local nodelistb`jj' {
		create_node `node', attach_id(`id') nodetype(`nodetype`jj'') `verbose'
		/* don't bother with label */
	}
}
end /* create_and_attach_nodes */






prog def tree_node
assert_tree_data_present
syntax [namelist], [at(namelist) INTerior(namelist) TERMinal(namelist) VERbose]

one_or_the_other_not_both, a(`namelist') b(`at') aname(a namelist) bname(an at() option)
if "`namelist'" ~= "" {
	local at "`namelist'"
}


if "`verbose'" ~= "" {
	disp "you called tree_node `0'"
}

if "`at'" == "superroot" {
	disp as err "You may not attach an interior or terminal node to superroot."
	disp "Only tree roots may attach to superroot; use " as inp "tree create"
	exit 198
}

if "`terminal'" =="" & "`interior'" == "" {
	disp "(No interior or terminal nodes specified.)"
	/* So no meaningful action will occur. */
}
find_node_via_path `at', require(exist)
local parent_id `s(node_id)'
create_and_attach_nodes, ///
	nodelist1(`interior') nodetype1(`="interior":nodetype') nodelist2(`terminal') nodetype2(`="terminal":nodetype') ///
	tag1(interior) tag2(terminal) id(`parent_id') `verbose'


/* This seeks the `at' node, regardless of whether `interior' and `terminal' are present.
So it will flag a no-existant node, even if no action is specified.
*/

end /* tree_node */



prog def draw_node_prefix
syntax, depth(integer)
forvalues jj = 1 / `=`depth'-1' {
	if "${tree_depth_`jj'_has_more_children}" ~= "" {
		disp "{c |} "   /*"| "*/ _cont
	}
	else {
		disp "  " _cont
	}
}
end /* draw_node_prefix */



prog def draw_node
/* An action1 routine. */
syntax, id(integer) parent(integer) depth(integer) [location(string) verbose]
/* We don't use the verbose option, but all action routines are required to have one. */

if ~mi(__next[`id']) {
	global tree_depth_`depth'_has_more_children "Y"
}
else {
	global tree_depth_`depth'_has_more_children
}

disp %6.0g `id' " " _cont
draw_node_prefix, depth(`depth')
if `depth' > 0 {
	if ~mi(__next[`id']) {
		disp "{c LT}{c -}" /*"+-"*/ _cont
	}
	else {
		disp "{c BLC}{c -}" /*"\-"*/ _cont
	}
}
disp __nodename[`id'] _cont

if __nodetype[`id'] == "terminal":nodetype {
	disp "*" _cont
}
/*if __nodelabel[`id'] ~= "" {
	disp " [" __nodelabel[`id'] "]" _cont
}
*/

if "$tree_drawvars" ~= "" {
	disp _col(35) _cont
}

local sep

foreach v of global tree_drawvars {
	disp "`sep'" `v'[`id'] _cont
	/* values separated by ";". If this is ambiguous, then we can implement an
	option to quote string values.
	*/
	local sep "; "
}




disp /* end line */

end /* draw_node */


prog def tree_draw
assert_tree_data_present
syntax [varlist(default=none)]
/* -- really should do no more than, say, 4 vars. */
global tree_drawvars "`varlist'"
tree_traverse, depth(0) id(1) parent(0) action1(draw_node)
end /* tree_draw */



prog def verify_node
/* an action1 routine */
syntax, id(integer) parent(integer) depth(integer) [location(string) verbose] 
/* We don't use the verbose option, but all action routines are required to have one. */


if __nodetype[`id'] == "terminal":nodetype {
	if ~mi(__branch_head[`id']) {
		disp as err "Terminal node `id' (" __nodename[`id'] ") has branches."
		local errors "Y"
		/* This condition should not happen, assuming that all tree construction
		operations are done by the programs in this do-file.
		*/
	}
}
else {
	if mi(__branch_head[`id']) {
		disp as err "Nonterminal node `id' (" __nodename[`id'] ") has no branches."
		local errors "Y"
	}
}

**~~~Other things to check...?

if "`errors'" ~= "" {
	global tree_eval_errors "Y"
	if "`location'" ~= "" {
		disp as text "location: `location'"
	}
}


end /* verify_node */


prog def tree_verify
assert_tree_data_present
global tree_eval_errors
tree_traverse, depth(0) id(1) parent(0) action1(verify_node)
if "$tree_eval_errors" ~= "" {
	exit 459
}

end /* tree_verify */



prog def init_payoffvars
/* Prior to 2023may05, this was an action1 routine;
2023may09: restoring it to be action1.
*/
syntax, id(integer) parent(integer) depth(integer) [location(string) verbose]
if "`verbose'" == "" {
	local qui "qui"
}
else {
	disp "init_payoffvars, node `id'" _cont
		/* We could display location. */
}

local payoffvars: char _dta[payoffvars]
if __nodetype[`id'] < "terminal":nodetype {
	/* nonterminal; see note 2 */
	if "`verbose'" ~= "" {
		disp " -- clearing"
	}
	foreach v of local payoffvars {
		`qui' replace R_`v' = 0 in `id'
	}
	foreach v of global tree_rawsumvars {
		`qui' replace S_`v' = 0 in `id'
	}
	`qui' replace __weight = 0 in `id'
	foreach v of global tree_meansvars {
		`qui' replace T_`v' = 0 in `id'
	}
}
else /* terminal */ {
	if "`verbose'" ~= "" {
		disp " -- initializing"
	}

	assign_Rvals `payoffvars', id(`id') location(`location') `verbose'

	foreach v of global tree_rawsumvars {
		`qui' replace S_`v' = R_`v' in `id'
	}
	`qui' replace __weight $tree_weight in `id'
	foreach v of global tree_meansvars {
		`qui' replace T_`v' = R_`v' * __weight in `id'
	}
}

/* We previously tried real(`v'), rather than `=`v'[`id']'. */ 

/* Note 2:
We believe that it is correct to do the clearing of values in nonterminal nodes here,
because such nodes will be visited BEFORE the children.
*/

end /* init_payoffvars */



prog def add_payoff_vals_to_parent
/* An action4 routine; new, 2023may09.
A reworking of the prior version add_child_vals_to_payoffvars.
Now it is an action4 routine; needs -parent- option.
(Now all action4 routines will require parent.)
*/
syntax, id(integer) parent(integer) depth(integer) [location(string) verbose]
if "`verbose'" == "" {
	local qui "qui"
}
local payoffvars: char _dta[payoffvars]

/* If there is a parent...*/
if `parent'>0 & ~mi(`parent') {
	foreach v of local payoffvars {
		`qui' replace R_`v' = R_`v' + R_`v'[`id'] * R_prob[`id'] in `parent'
	}
	foreach v of global tree_rawsumvars {
		`qui' replace S_`v' = S_`v' + S_`v'[`id'] in `parent'
	}
	`qui' replace __weight = __weight + __weight[`id'] in `parent'
	foreach v of global tree_meansvars {
		`qui' replace T_`v' = T_`v' + T_`v'[`id'] in `parent'
	}
}
end /* add_payoff_vals_to_parent */



prog def adjust_probtallys
/*
2023may05: converting this from an action3 to an action1 routine.
We expect that init_probs (setting R_prob) shall have been invoked, as well as
the clearing of __probsum and __n_starprobs prior to calling this.

See notes in tree_eval.

*/
syntax, id(integer) parent(integer) depth(integer) [location(string) verbose]
if "`verbose'" == "" {
	local qui "qui"
}
else {
	disp "adjust_probtallys, parent `parent', id `id'"
}


/* If there is a parent...*/
if `parent'>0 & ~mi(`parent') {
	if __residual[`id'] {
		`qui' replace __n_starprobs = __n_starprobs + 1 in `parent'
	}
	else {
		`qui' replace __probsum = __probsum + R_prob[`id'] in `parent'
		/* __probsum can become missing if one or more terms ( R_prob[`id']) is missing. */
	}
}
end /* adjust_probtallys */



prog def init_probs
/* 
An action1 routine.
Initialize the _prob vars; note the leading underscore.

I was tempting to try to do this in a one-line replace command, which might apply
to all records together. But it doesn't work to reference prob -- to extract the
numerical value from an expression as a plain assignment.
Instead, we need the `=prob[`id']' construct. Note that we need to index prob;
otherwise, you get prob[1]. Also note that each invocation applies to ONE observation.

We do this in the context of an action routine to be used in tree_traverse. But it
could also be done by looping through all obs.
*/
syntax, id(integer) parent(integer) depth(integer) [location(string) verbose]

assign_Rvals prob, id(`id') location(`location') `verbose'

/*
Clear __probsum and __n_starprobs. {Inserted 2023may18)
Properly, we want this to apply to the parent. But (1) in a traversal, you will have
visited the parent prior to any child node, so the parent is covered;
(2) doing the parent would cause repeated action multiple times on the same parent,
unnecessarily.

See notes regarding these vars in tree_eval.
*/

if "`verbose'" == "" {
	local qui "qui"
}

`qui' replace __probsum = 0 in `id'
`qui' replace __n_starprobs = 0 in `id'

end /* init_probs */



prog def assign_Rvals
/* Set the R-values for a set of payoff vars or prob.
Created 1023oct14. Factor-out some code that was common to init_payoffvars and
init_probs. Later use this in the -check- option to tree_setvals.
*/
syntax varlist(string), id(integer) [location(string) verbose]
if "`verbose'" == "" {
	local qui "qui"
}

local allowedvars `: char _dta[payoffvars]' prob
/* -- those are the payoff vars (base names) and prob. */

local varlist_excess: list varlist-allowedvars
if "`varlist_excess'" ~= "" {
	disp as err "assign_Rvals: invalid varlist elements: `varlist_excess'"
	exit 198
}

foreach v of local varlist {
	local textval = trim(`v'[`id'])
	if `"`textval'"' == "" {
		if "`v'" ~= "prob" |  __nodetype[`id'] > "root":nodetype {
			/* Blank `v' value; possible problem, but non-fatal; issue a warning.
			But we don't get alarmed for root or superroot.
			It is normal (or optional) for prob to be unassigned there.
			*/
			disp as err "Note: " as txt "`v'[`id'] is unassigned"
			if "`location'" ~= "" {
				disp as text "location: `location'"
			}
			`qui' replace R_`v' = . in `id'
		}
	}
	else {
		/* non-blank `v' value */
		if "`v'" == "prob" & `"`textval'"' ~= "*" {
			capture local qqq = `textval'
			if (~_rc) & (`"`qqq'"' == "*") {
				local textval "*"
				/* This is to handle the case in which `textval' is an expression
				(e.g., a scalar) that evaluates to "*". We change it to an actual "*".
				Otherwise, we would get an error in evaluating R_prob;
				we'd issue a command like
				- replace R_prob = * in 37 -.
				You get the response "*in invalid name".
				2023oct09 & 15.
				*/
			}
		}
		/*~~~*/ /* disp "assign_Rvals, point 1, textval: <`textval'>" */
		if "`v'" == "prob" & `"`textval'"' == "*" {
			`qui' replace R_prob = .z in `id'
		}
		else {
			capture replace R_`v' = (`textval') in `id'
			/* prior to 2024jun6, this was `=`textval''.
			That did not work correctly for non-simple expressios, esp ones
			that reference other variables. Such references would take values from
			obs 1.
			*/
			if _rc {
				global tree_eval_errors "Y"
				disp as err "error evaluating R_`v', node `id'"
				if "`location'" ~= "" {
					disp as text "location: `location'"
				}
			}
		}
	}
	if "`v'" == "prob" {
		`qui' replace __residual = `"`textval'"' == "*" in `id'
	}
}
end /* assign_Rvals */





prog def set_resid_probs
/* 
An action1 routine.
Previously named set_probs, before 2022july02.

Replace R_prob in the case of a residual specification.

We PRESUME that init_probs has already been called.
That will have taken care of the normal prob values.
Furthermore, __residprob should have been calculated, which relies on the initial
clearing of __probsum and __n_starprobs, and the running of adjust_probtallys under tree_traverse.
*/

syntax, id(integer) parent(integer) depth(integer) [location(string) verbose]
if "`verbose'" == "" {
	local qui "qui"
}
else {
	disp "set_resid_probs, id `id', parent `parent'"
}

if __residual[`id'] {
	`qui' replace R_prob = __residprob[`parent'] in `id'
}

/* When `id' == 1, `parent' would be 0, yielding a missing value. But that's okay. */
end /* set_resid_probs */


prog def check_probsum
/*
An action4 routine.
*/
syntax, id(integer) depth(integer) parent(integer) [location(string) verbose]
/* We don't use the verbose option, but all action routines are required to have one.
Same for parent.
 */

if __probsum[`id'] <0 | __probsum[`id'] >1  {
	if __nodetype[`id'] > "superroot":nodetype {
		/* We don't get alarmed for superroot.
		It is normal for __probsum to be unassigned in superroot.
		*/
		disp as err "__probsum out of range or missing; obs `id', node " __nodename[`id'] ", __probsum: " __probsum[`id']
		/* Not fatal. */
		if "`location'" ~= "" {
			disp as text "location: `location'"
		}
	}
}

end /* check_probsum */



prog def compare_varlist_to_payoffvars
/* take a varlist,
	compare it to payoffvars
	display the difference (ones on varlist but not in payoffvars)
	take the intersection and set that as a named global.
*/
syntax [varlist(default=none)], listname(string) globname(name)

if "`varlist'" ~= "" {
	local payoffvars `: char _dta[payoffvars]'
	local varlist_excess: list varlist-payoffvars
	if "`varlist_excess'" ~= "" {
		disp "`listname' vars not in payoffvars: `varlist_excess'"
		disp "will be ignored."
	}
	local varlist_valid: list payoffvars & varlist
	if "`varlist_valid'" == "" {
		disp "no valid `listname' vars specified"
	}
}

global `globname' "`varlist_valid'"

end /* compare_varlist_to_payoffvars  */


prog def note_remove
/* Drop a note, based on its value. */
syntax varlist, note(string) [debug]
/* Not sure if note should be -asis- ?? */

foreach vv of local varlist {

	local n: char `vv'[note0]

	if "`debug'" ~= "" {
		disp "n = `n'"
	}

	if "`n'" ~= "" {
		forvalues jj = 1 / `n' {
			local noteval: char `vv'[note`jj']
			if "`debug'" ~= "" {
				"`vv'  `n' `noteval'"
			}
			if `"`noteval'"' == `"`note'"' {
				if "`debug'" ~= "" {
					disp "dropping note `jj'"
				}
				notes drop `vv' in `jj'
			}
		}
	}
}
end


prog def tree_eval
assert_tree_data_present
/* ~~~Potentially, this could be targeted to a subtree, using either an id (number) or
namelist (tree path).
As of 2022jun27, it remains to do the whole forest.
*/
syntax [iweight] , [rawsum(varlist) MEANs(varlist) VERbose retain debug]
if "`verbose'" == "" {
	local qui "qui"
}
else {
	disp "doing the evaluation"
}


compare_varlist_to_payoffvars `rawsum', listname(rawsum) globname(tree_rawsumvars)
compare_varlist_to_payoffvars `means', listname(means) globname(tree_meansvars)

if "`exp'" == "" {
	global tree_weight "=1"
}
else {
	global tree_weight `"`exp'"'
}

global tree_eval_errors

/* At this point, we could clear __probsum and __n_starprobs for all obs.
But instead, we choose to do it node-by-node in init_probs.

To clear those vars for all obs is okay, presuming that we intend to evaluate the
whole forest -- which is, actually,  what we do (as of 2023may18).

But if we would want the option to evaluate a single tree or branch, then the
scheme of node-by-node clearing (in init_probs) is necessary.
*/


/* Pay attention to tree_rawsumvars_prior;
	drop "discarded" vars
	gen new vars
Do the same tree_meansvars_prior.
*/
local rawsum_newvars: list global(tree_rawsumvars) - global(tree_rawsumvars_prior)
local rawsum_exvars: list global(tree_rawsumvars_prior) - global(tree_rawsumvars)
local rawsum_commonvars: list global(tree_rawsumvars_prior) & global(tree_rawsumvars)

local means_newvars: list global(tree_meansvars) - global(tree_meansvars_prior)
local means_exvars: list global(tree_meansvars_prior) - global(tree_meansvars)
local means_commonvars: list global(tree_meansvars_prior) & global(tree_meansvars)

/* Create or drop the S_ variant of the var -- not the var itself!.
Here, rawsum_exvars refers to vars from a previous invocation which were
not specified in the current invocation. We may drop them now, depending on `retain'.

The -retain- option means to not drop rawsum_exvars. But does this mean...
	A: keep the vars and their existing values;
	B: add the vars to the tree_rawsumvars, so they get reevaluated.
I believe A is the right choice, because the user could just specify the vars in the eval
command. BUT user beware that the values may be old -- not necessarily the same as you would get
if you just specify the vars in the eval command. We should put a -note- on such vars.

Do the same for the T_ and M_ variants.
*/

local retention_note "retains value from earlier eval step"

if "`debug'" ~= "" {
	disp "rawsum_exvars: `rawsum_exvars'"
	disp "means_exvars:  `means_exvars'"
}

if "`retain'" == "" {
	foreach v of local rawsum_exvars {
		drop S_`v'
	}
	foreach v of local means_exvars {
		drop T_`v' M_`v'
	}
}
else {
	foreach v of local rawsum_exvars {
		notes S_`v': `retention_note'
		if "`debug'" ~= "" {
			disp "added note for S_`v'"
		}
	}
	foreach v of local means_exvars {
		notes T_`v': `retention_note'
		notes M_`v': `retention_note'
		if "`debug'" ~= "" {
			disp "added note for T_`v' & M_`v'"
		}
	}
	local rawsum_retained "`rawsum_exvars'"
	local means_retained "`means_exvars'"
}

foreach v of local rawsum_newvars {
	`qui' gen double S_`v' = .
	label var S_`v' "rawsum of `v'"
}

foreach v of local means_newvars {
	`qui' gen double T_`v' = .
	label var T_`v' "weighted sum of `v'"
}

foreach v of local rawsum_commonvars {
	note_remove S_`v', note(`retention_note') `debug'
}
foreach v of local means_commonvars {
	note_remove T_`v' M_`v', note(`retention_note') `debug'
}


tree_traverse, depth(0) id(1) parent(0) action1(init_probs) `verbose'

tree_traverse, depth(0) id(1) parent(0) action1(adjust_probtallys) ///
	action4(check_probsum) `verbose'
`qui' replace __residprob = (1-__probsum)/__n_starprobs
tree_traverse, depth(0) id(1) parent(0) action1(set_resid_probs) `verbose'


/*
At this point, we could clear all payoff vars.
But, as noted for __probsum and __n_starprobs, we choose to do it
node-by-node in init_payoffvars, for the same reasons.
*/

tree_traverse, depth(0) id(1) parent(0) action1(init_payoffvars) ///
	action4(add_payoff_vals_to_parent) `verbose'

foreach v of local means_newvars {
	`qui' gen double M_`v' = T_`v' / __weight
	label var M_`v' "weighted mean of `v'"
}

	
global tree_rawsumvars_prior: list global(tree_rawsumvars) | rawsum_retained
global tree_meansvars_prior: list global(tree_meansvars) | means_retained
/*
tree_rawsumvars: the rawsumvars as named in the most recent call to tree_eval.
tree_rawsumvars_prior: all the current the rawsumvars, including the retained.
"prior" may be misleading. Between calls to tree_eval, tree_rawsumvars_prior
is "current", as in most recent.

Same goes for tree_meansvars_prior.
*/

if "$tree_eval_errors" ~= "" {
	exit 198
}

end /* tree_eval */



prog def tree_check
/* This is a scaled-down version of tree_eval; do only the init... procedures, so
as to check whether the expressions can be evaluated.
See notes in tree_eval.
*/
assert_tree_data_present
syntax, [VERbose]
if "`verbose'" == "" {
	local qui "qui"
}
else {
	disp "doing the checking"
}

global tree_eval_errors

tree_traverse, depth(0) id(1) parent(0) action1(init_probs) `verbose'
tree_traverse, depth(0) id(1) parent(0) action1(init_payoffvars) `verbose'

if "$tree_eval_errors" ~= "" {
	exit 459
}

end /* tree_check */


prog def check_pref_length
/* for use with tree_diffs or tree_values */
syntax, PREFix(name)

if length("`prefix'") > (32 - `:char _dta[maxlen]') {
	disp as err "prefix `prefix' is too long for maximal length of payoffvars `:char _dta[maxlen]'"
	exit 198
	/* If we hadn't raised error here, an error will occur when scalars are created." */
}

/* tree_rawsumvars and tree_meansvars require more space.
Actually, the relevant macros are tree_rawsumvars_prior and tree_meansvars_prior.
*/
if ("$tree_rawsumvars_prior" ~= "" | "$tree_meansvars_prior" ~= "") & length("`prefix'") > (31 - `:char _dta[maxlen]') {
	disp as err "prefix `prefix' is too long for maximal length of payoffvars `:char _dta[maxlen]',"
	disp "with rawsum or means variables."
	exit 198
}
end /* check_pref_length */




prog def tree_diffs
assert_tree_data_present
syntax, MINUend(namelist) SUBTRAhend(namelist) [PREFix(name)]

disp as err "Reminder:" as text " have you called tree eval?"

if "`prefix'" == "" {
	/* use default */
	local prefix "d_"
}

check_pref_length, pref(`prefix')


disp "tree_diffs; using prefix `prefix'"

find_node_via_path `minuend', require(exist)
local minu_id `s(node_id)'

find_node_via_path `subtrahend', require(exist)
local subtra_id `s(node_id)'

local varstodiff `: char _dta[payoffvars]'

foreach v of local varstodiff {
	scalar `prefix'`v' = R_`v'[`minu_id'] - R_`v'[`subtra_id']
}
/* This requires that the names in varstodiff be not too long. */

foreach v of global tree_rawsumvars_prior {
	scalar `prefix'S`v' = S_`v'[`minu_id'] - S_`v'[`subtra_id']
	/* see note below */
}

foreach v of global tree_meansvars_prior {
	scalar `prefix'M`v' = M_`v'[`minu_id'] - M_`v'[`subtra_id']
	scalar `prefix'T`v' = T_`v'[`minu_id'] - T_`v'[`subtra_id']
	/* see note below */
}

/* Note that in the scalar names, the underscore after S or M or T is removed.
Also, we reference tree_rawsumvars_prior, rather than tree_rawsumvars,
and tree_meansvars_prior, rathern than tree_meansvars.
These "prior" versions are relevant because they contain the basenames of the
most recently-generated S_, M_, & T_ variables. The non-prior versions do not
include the retained variables. This was a bug, discovered 2023jun27.
*/



end /* tree_diffs */


prog def tree_a_minus_b
/* A synonym and front-end for diffs; maybe easier to remember the syntax. */
syntax, a(namelist) b(namelist) [PREFix(name)]
tree_diffs, minuend(`a') subtrahend(`b') prefix(`prefix')
end /* tree_a_minus_b */



prog def tree_values
/* tree_values: similar to tree_diffs, but for a single location. */
assert_tree_data_present
syntax, at(namelist) [PREFix(name)]

disp as err "Reminder:" as text " have you called tree eval?"

if "`prefix'" == "" {
	/* use default */
	local prefix "v_"
}

check_pref_length, pref(`prefix')

disp "tree_values: using prefix `prefix'"

find_node_via_path `at', require(exist)
local at_id `s(node_id)'


local varstotakevalues `: char _dta[payoffvars]'

foreach v of local varstotakevalues {
	scalar `prefix'`v' = R_`v'[`at_id']
}
/* This requires that the names in varstotakevalues be not too long. */


foreach v of global tree_rawsumvars_prior {
	scalar `prefix'S`v' = S_`v'[`at_id']
	/* see note below */
}

foreach v of global tree_meansvars_prior {
	scalar `prefix'M`v' = M_`v'[`at_id']
	scalar `prefix'T`v' = T_`v'[`at_id']
	/* see note below */
}

/*
See note in tree_diffs regarding why we reference the "prior" versions of these
macros. The same applies here.
*/

end /* tree_values */



prog def tree_des
/* Introduced 2022aug08 */

disp _n as text "{ul:trees}"
assert_tree_data_present
capture confirm var __branch_head
if _rc {
	disp "(Dataset not configured for trees.)"
}
else {
	local jj = __branch_head[1]
	if mi(`jj') {
		disp "(No trees defined.)"
	}
	while ~mi(`jj') {
		disp as res __nodename[`jj']
		local jj = __next[`jj']
	}
}

disp _n as text "{ul:payoff variables}"
local payoffvars "`: char _dta[payoffvars]'"
if "`payoffvars'" ~= "" {
	foreach v of varlist `payoffvars' {
		disp as res "`v'"
	}
}
else {
	disp "(No payoff variables defined.)"
	/* Really, dataset is not configured for trees. */
}

end /* tree_des */





prog def preserve_var
syntax varname, suff(integer) [replace VERbose]
/* `suff' is an integer; it must not be negative, but we expect the caller
to have done that check.
*/
if "`verbose'" == "" {
	local qui "qui"
}

local v "`varlist'`suff'"

confirm name `v'
capture confirm var `v'
if ~_rc {
	if "`replace'"== "" {
		disp as err "`v' already exists"
		exit 198
	}
	else {
		`qui' replace `v' = `varlist'
	}
}
else {
	if "`replace'"~= "" {
		disp as text "(note: variable `v' not found)"
	}
	`qui' clonevar `v' = `varlist'
}
end /* preserve_var */


prog def tree_preserveprob
syntax, [CHANnel(integer 0) replace VERbose]
check_channel, channel(`channel')
preserve_var prob, suff(`channel') `replace' `verbose'
disp "prob preserved in channel `channel'"
end /* tree_preserveprob */


prog def tree_preservepayoff
syntax, [CHANnel(integer 0) replace VERbose]
check_channel, channel(`channel')
local varstopreserve `: char _dta[payoffvars]'

foreach q of local varstopreserve {
	preserve_var `q', suff(`channel') `replace' `verbose'
}
disp "payoff variables preserved in channel `channel'"
end /* tree_preservepayoff */


prog def tree_preserveall
syntax, [CHANnel(integer 0) replace VERbose]
tree_preserveprob, channel(`channel') `replace' `verbose'
tree_preservepayoff, channel(`channel') `replace' `verbose'
end /* tree_preserveall */



prog def restore_var
syntax varname, suff(integer) [VERbose]
/* `suff' is an integer; it must not be negative, but we expect the caller
to have done that check.
*/
if "`verbose'" == "" {
	local qui "qui"
}

local v "`varlist'`suff'"
confirm name `v'
capture confirm var `v'
if _rc {
	disp as err "var `v' not found for restore operation"
	exit 198
}
`qui' replace `varlist' = `v'
end /* restore_var */


prog def tree_restoreprob
syntax, [CHANnel(integer 0) VERbose]
check_channel, channel(`channel')
restore_var prob, suff(`channel') `verbose'
disp "prob restored from channel `channel'"
end /* tree_restoreprob */



prog def tree_restorepayoff
syntax, [CHANnel(integer 0) VERbose]
check_channel, channel(`channel')
local varstopreserve `: char _dta[payoffvars]'

foreach q of local varstopreserve {
	restore_var `q', suff(`channel') `verbose'
}
disp "payoff variables restored from channel `channel'"
end /* tree_restorepayoff */


prog def tree_restoreall
syntax, [CHANnel(integer 0) VERbose]
tree_restoreprob, channel(`channel') `verbose'
tree_restorepayoff, channel(`channel') `verbose'
end /* tree_restoreall */



prog def check_channel
syntax, CHANnel(integer)
if `channel' < 0 | `channel'>99 {
	disp as err "channel spec out of range (0..99)"
	exit 198
}
end /* check_channel */


prog def tree_traverse

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

