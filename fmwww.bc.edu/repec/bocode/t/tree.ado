**~~~~2025mar24: need debug: do treetest04_2 -- gen option VERBose not allowed.
**~~~~~--apparently fixed, 2025apr29.

**~~ 2024july21: We will need to change the terminology of link to rlink, to
**avoid confusion with "link" being the term for all connections fro node to node.
**--Done, 2024aug13.

**~~~Also maybe have a nodetype for rptbr_root


**~~~2024july16 late at night.
**tree_draw needs special consideration for links.
**As it stands now, it goes INTO the linked rptbr just once.
**Maybe tree_traverse_00 needs an option to go into already-visited nodes.

** july16: later, attempting to fix this. delete this note if successful.


**~~~~Need: tree_draw -- to distinguish link nodes.
**~~~~Also, tree_traverse will need to adapt to handle links to repeatable branches
**-- to NOT go down those descendant branches.
**~~~Prohibit linking from one rptbr to another; prohibit link nodetpes inside an
** rptbr.
**Propagate __rptbr down the tree.  ~~irrelevant 2024july1

** ~~~ presently (2024jun25), tree_traverse follows a link to a given rptbr root
** AND ALL OF ITS "next" siblings, i.e., other rptbr roots.
**2024july1: fixed, but may be adjusted to respond to options.

**~~Consolidate the "required" options; create a program to do it.[DONE]

**~~~~ Operation not allowed indirectly via a link.  -- error being erroneously issued.
**-- fixed 2024july1

**~~ "node not found" error; make it say "tree" or "rptbr" instead of node, as
**appropriate.  PS (2024july09) This may be more trouble than it's worth.


**~~2024july09: is the is_rptbr set an all possible situations. What if we are
**entering via `:char _dta[rptbr]' ??

**~~2024july19: __rptbr is unused. We can remove it. --Done 2024aug6.



/*
2024may20: This began as tree2.ado; began as a copy of tree.ado.
Enhnacements are being made: repeatable branches, which are actually trees,
but on a separate superroot.

Once this is established, it should be renamed tree.ado, and the old version archived.
--doing this, 2025jul25.



tree.ado
Decision-Tree facility.
David Kantor, began 2021may03


~~~~2024may20: check references to superroot; treat rptbr similarly.

~~~~2024jun17: adapt tree_plot to handle the rptbr.

*/

prog def tree
* version 1.1.1 2021may03
* version 1.2.1 2022dec13
* 2023jun28: public release.
* version 1.3.1 2023jun28
* version 1.3.2 2023oct10
* version 1.4.0
*! version 2.0.0, 2024may20

/*
2023oct02: edited comments.
2023oct18: tree-traversal is now coded in its own ado file: tree_traverse.ado.
PS: later putting it back in! It didn't work as expected; it couldn't access the
action routines.
2024nov05: restoring the use of tree_traverse.ado.
*/



version 14


#delimit ;
local allowable_subcmd
 "init create node draw verify eval check setvals diffs
 values a_minus_b preserveprob preservepayoff restoreprob restorepayoff
 preserveall restoreall des plot rptbr rlink";
#delimit cr

/* Note that "plot" invokes tree_plot, which is defined in a separate file:
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




prog def create_superroot, sclass
/* This creates "a superroot". It might be THE superroot (for all regular trees),
or it could be the rptbr root.
*/
syntax name, [VERbose]

if "`verbose'" == "" {
	local qui "qui"
}

local node_id = _N+1
`qui' set obs `node_id'

replace __nodetype = "superroot":nodetype in `node_id'
replace __nodename = "`namelist'" in `node_id'
/* replace __nodelabel = "superroot" in `node_id' */

/* A moot point, but... that assignment of __nodelabel is a default; other uses of
this should subsequently replace values as appropriate.
*/
`qui' replace prob = "*" in `node_id'

sreturn local superroot_id = `node_id'

end
/* end create_superroot */


prog def tree_init
/* This does the initialization of the dataset and creates the superroot node. */
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

__n_parents
__surr
__ypos

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

__rptbr -- removed 2024aug6.

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


/* Create vars, even though _N ==0. */
gen str32 __nodename = "" 
/* gen str40 __nodelabel = "" */
label def nodetype 0 "superroot" 1 "root" 2 "interior" 3 "terminal" 4 "rlink" 5 "surrogate"

/* Note that rptbr is...
	a subcommand;
	a root name for all repeatable branches, analogous to superroot;
	an option name in some programs.

We will use "root":nodetype as the type for the (super) root of a repeatable branch;
no need to have a distinct type. But we will have ways to determine when you go
into a repeatable branch.

Also, "superroot":nodetype will serve for all regular trees, plus the set of repeatable
branches.

nodetype "rlink" is for a link to a rptbr. It is a special type of interior node.
I would make it come before "terminal", but I need to maintain backward compatibility,
and not change existing values.

surrogte: introduced 2025mar24. Such a node takes the place of an rptbr in plotting and
drawing. A surrogate is tied to the rlink -- not the rptbr; there will be a __surr
variable for that. __surr functions in place of __branch_head in those cases.
A surrogate may have no descendants.

In an rlink node, __surr shall point ot the surrogate.
In a surrogate node, __surr shall point to the rptbr node -- same __beanch_head
of its parent. So it does double duty, i.e., it is overloaded, which may be confusing.

(In a surrogate node, the value in __surr ought to have a different name, but
there's no need to have a separate variable for it.)

*/

gen byte __nodetype = .
label val __nodetype nodetype
/*
Prior to 2022oct18, __nodetype did not have a label. Also, the numbering scheme was
lower by 1. Notes regarding these values are being rewritten, even if dated prior to 2022oct18.
*/

`qui' {
	gen int __branch_head = .
	gen int __branch_tail = .
	gen int __next = .
	gen int __surr = .
	** gen byte __rptbr = 0
	gen double __probsum = . /* sum of non-residual probs in child nodes */
	gen int __n_starprobs = . /* num child nodes with residual probs */
	gen double __residprob = . /* apportioned residual probability in child nodes */
	gen byte __residual = 0  /* whether prob is specified as residual; see note below */
	gen byte __n_parents = 0
	gen float __ypos = .
}
/* __branch_head and __branch_tail are for the child nodes;
__next is for the chain that the present node may be in.

No need to gen n_visits or __n_visits; it will be done as needed in tree_traverse.
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

create_superroot superroot, `verbose'
if `s(superroot_id)' ~= 1 {
	disp as err "initial superroot not at obs 1"
	exit 459
	/* An internal error. */
}
end /* tree_init */



prog def find_child_node, sclass
/* Look for a given named node among the children of a given node.
Look in only that one level.
*/
syntax name(name= nodename), id(integer) [require(passthru) start_at_id]

/* 2024may28, based on notes from 2024may21:
Previously, we used magic values for `id' to signify to set jj = 1 (superroot).
Now we will use a start_at_id option. This is more general, and removes the use of
magic values.

`start_at_id' shall indicate to begin the search at `id', rather than __branch_head[`id'].
Normally, we look at the children of `id'; this option says to look at `id' and all
of its siblings. More accurately, look at `id' and all its downstream
siblings. If `id' is the lead node in its sibling group, then this will bw the whole
sibling group. That's equivalent to applying the default action on a parent node of `id',
whether such as node exists or not.

BUT in actual use, this would typically apply to a superroot, so the sibling group
would be a singleton set.
*/

if "`start_at_id'" ~= "" {
	local jj "`id'"
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

/*~~~~debug: disp "point 1, `nodename'" */
deal_with_require_option `nodename', node_id(`node_id') `require'

end /* find_child_node */



prog def find_node_via_path, sclass
/* Look for node as named by its complete path through the forest. */
syntax namelist(name= path), [norlink]

/*2024july21: This had a -require(passthru)- option. But it was noticed that ALL
invocations of this program had been using the require(exist) option. And it is
natural that all such invocations should be that way. So we are eliminating that
option. Furthermore, require(noexist) makes no sense in this context.
(It does make sense for find_child_node.)
Therefore we eliminate that option, and pass require(exist) to find_child_node.

`rlink', from the norlink option: don't allow a path that comes through an rlink.
Not to be confused with the rlink option in tree_node.
*/

/* 2024may21: check for "rptbr" in addition to "superroot".
Pass the actual value for startingnode, not a magic value.
See notes in find_child_node.
*/

local startingnode "1"  // default
local is_rptbr "0"

gettoken leadname path: path /* path is now the remaining part of the path. */
if "`leadname'" == "superroot" {
	local start_at_id "start_at_id"
}
else if "`leadname'" == "rptbr" {
	if "`:char _dta[rptbr]'" == "" {
		disp as err "No rptbr established"
		exit 459
	}
	local startingnode "`:char _dta[rptbr]'"
	local start_at_id "start_at_id"
	local is_rptbr "1"
}

/* Note that start_at_id applies to to the initial find_child_node only,
as does startingnode.

2024july19: Channge this so that via_rlink is sensitive to only the parental chain;
EXCLUDES the final node. Do this by evaluating via_rlink BEFORE find_child_node in
the loop, so it refers to the parent.
*/

find_child_node `leadname', id(`startingnode') `start_at_id' require(exist)
local via_rlink = 0
/* -- Properly, that should be local via_rlink = __nodetype[`startingnode'] == "rlink":nodetype
But `startingnode' should never be an rlink.
*/

while `s(node_id)' & "`path'" ~= "" {
	local via_rlink = `via_rlink' | __nodetype[`s(node_id)'] == "rlink":nodetype
	gettoken leadname path: path
	find_child_node `leadname', id(`s(node_id)') require(exist)
}


sreturn local node_id = `s(node_id)'
sreturn local is_rptbr "`is_rptbr'"
sreturn local via_rlink "`via_rlink'"

if (`via_rlink' | __nodetype[`s(node_id)'] == "rlink":nodetype) & `is_rptbr' {
	disp as err "rlink detected within an rptbr; node `s(node_id)' or the path leading there"
	exit 459
}


if "`rlink'" ~= "" & `via_rlink' {
	/* Prior to 2024july29, there was the additional condition,
	"rptbr" ~= "", which is erroneous (always true); maybe it was supposed to be
	~`is_rptbr' ??
	Notes indicating that it was to prevent the somewhat confusing/erroneous
	issue of tbis message if you start in rptbr, and go through an rlink.
	BUT THIS SHOULD NEVER HAPPEN, as we a prevented from establishing an rlink
	within an rptbr. It has occurred in testing, prior to the prohibition on
	rlinks within rptbrs.
	
	Also this was in place prior to the "rlink detected" trap, above, est 2024july29.
	*/
	disp as err "Operation not allowed indirectly via an rlink."
	exit 198
}

end /* find_node_via_path */


prog def deal_with_require_option
syntax name, node_id(integer) [require(string)]

if "`require'" == "exist" {
	if ~`node_id' {
		disp as err "node `namelist' not found"
		exit 198
	}
}
else if "`require'" == "noexist" {
	if `node_id' {
		disp as err "node `namelist' already exists."
		exit 198
	}
}

/* Any other value is ignored. */

end /* deal_with_require_option */





prog def tree_create_00
/* This is the internal routine for creating a tree -- or a repeatable
branch.
Formerly, prior to 2024may20, this was tree_create, but with no rptbr option.

tree_create is now a front end; prevents user from specifying tree_create with
the rptbr option. tree_rptbr is another front end.
*/

assert_tree_data_present
syntax namelist(name= treenames), [/*label(string)*/ rptbr VERbose]
/* 2024may20: add the rptbr option. */
if "`verbose'" ~= "" {
	disp "you invoked tree_create_00 `0'"
}

local prohibited_names "superroot rptbr"

local treenames_prohibited: list prohibited_names & treenames
if "`treenames_prohibited'" ~= "" {
	disp as err "`treenames_prohibited' not allowed as tree name."
	disp `"prohibited tree names: `prohibited_names'"'
	exit 198
	/*
	Originally, this is just to avoid confusion to the users.
	BUT, we later implemented the possibility of referring to the superroot
	node in diffs and value extraction; THUS, it is important to prohibit
	superroot as a tree name. (2022sep16)
	(Similarly, for rptbr, but values from that node are usually meaningless.)
	*/
}

if "`rptbr'" ~= "" {
	if "`:char _dta[rptbr]'" == "" {
		create_superroot rptbr, `verbose'
		char _dta[rptbr] "`s(superroot_id)'"
	}
	local id "`:char _dta[rptbr]'"
	/* See note below regarding why we create_superroot rptbr only as needed. */
	local rptbr1 "rptbr1"
}
else {
	/* Ordinary tree */
	local id 1
	/* superroot is always 1. */
}


/* Prior to 2022oct11, there was...
find_tree `treename', require(noexist)
create_node `treename', attach_id(1) nodetype("root":nodetype) label(`label')
-- That was limited to a single tree at a time.

Starting3 2022oct11, we do this using create_and_attach_nodes:

And why do we create_superroot rptbr only as needed? Why not just do it as part
of tree_init?
The reason is to make the datast compatible with the older (pre-version-2.0)
version -- for testing, and in case a user uses a dataset created in an older version.
*/


create_and_attach_nodes, nodelist1(`treenames') nodetype1(`="root":nodetype') ///
		tag1(treenames) id(`id') `rptbr1' `verbose'

/* Also prior to 2022oct11, there was... [pertaining to regular trees]...
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

end /* tree_create_00 */



prog def tree_create
syntax namelist, [/*label(string)*/ VERbose]
tree_create_00 `0'
end /* tree_creatre */



prog def tree_rptbr
syntax namelist, [/*label(string)*/ VERbose]

count_commas, s(`"`0'"')
if ~mod(`=s(commacount)', 2) {
	local comma ","
}
tree_create_00 `0' `comma' rptbr

/*2024may20, 14:07 -- that call to tree_create_00 in had been faulty if verbose
was specified (or any option, but that's the only one).
2024jun17: we fixed it via the use of count_commas.
*/
end /* tree_rptbr */



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

find_node_via_path `namelist', norlink
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
		if "`v'" ~= "prob" & __nodetype[`setvals_node_id'] ~= "terminal":nodetype {
			disp as err "payoff vars are settable in terminal nodes only"
			disp as text "var `v'; node_id `setvals_node_id'"
			exit 198
		}
		if "`v'" == "prob" & __nodetype[`setvals_node_id'] == "root":nodetype & `s(is_rptbr)' {
			disp as err "You may not set prob for an rptbr root"
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
	/* This invocation of tree_traverse just calls assign_Rvals; it does not
	do a traversal. See notes in tree_traverse.ado.
	*/
	tree_traverse, assign_Rvals rvals_vars(`setvals_vars_affected') ///
		id(`setvals_node_id') location(`namelist') parent(0) depth(0) `verbose'
	/* parent and depth are dummy values; required but irrelevant in this call. */
}

if "$tree_eval_errors" ~= "" {
	exit 198
}

if "`setvals_vars_affected'" == "" {
	disp "(No settings specified.)"
}
/*
Note: setvals_vval is subject to the trim operation; this value then goes into `v'.
Therefore, `v' is always trimmed, and thus, there is no need to do a trim operation
in any subsequent references to `v' (in other subprograms).
I'm removing those trim operations, 2022nov17.
*/
end /* setvals */


prog def attach_node /* introduced 2025mar13 */
syntax, id(integer) parent(integer) [solitary replace VERbose]
/*
`id' will become the child of `parent'.

`solitary': expect there to be 0 or 1 existing children of `parent'.
If there was 1 to begin with, then you also need `replace'.
When done, there will be just 1 child.

`replace': takes effect only under `solitary'; if there is 1 existing child of
`parent', then allow it to be replaced by `id'.


Note that both "attach" and "link" refer to connecting one node to another.
"Attach" is connecting a node to its parent;
"link" is connecting a node to a child.

*/
if "`verbose'" == "" {
	local qui "qui"
}

if `parent' == `id' {
	disp as err "You may not attach a node to itself."
	exit 198
	/* We prevent a node from attaching to itself,
	but we don't go as far as to prevent longer cycles.
	This might be an impossible situation anyway; it would be an internal error.
	*/
}

if __nodetype[`parent'] == "terminal":nodetype {
	disp as err "You may not attach to a terminal node."
	exit 198
}
/* If we ever adopt a scheme of storing the children directly in the nodes
(child1, child2, etc), much of this may become much simpler.
Esp the multiple children detection.
Also, the inconsistent __branch_tail value situation will go away.
*/

if mi(__branch_head[`parent']) {
	/* See note below. */
	if ~mi(__branch_tail[`parent']) {
		disp as err "inconsistent __branch_tail value"
		exit 459
	}
	`qui' replace __branch_head = `id' in `parent'
}
else /* ~mi(__branch_head[`parent']) */ {
	if mi(__branch_tail[`parent']) {
		disp as err "inconsistent __branch_tail value"
		exit 459
	}
	if "`solitary'" ~= "" {
		if __branch_head[`parent'] ~= __branch_tail[`parent'] {
			disp as err "multiple children present; require just one."
			exit 459
		}
		if "`replace'" == "" {
			disp as err "node is already linked."
			exit 198
		}
		local old_head = __branch_head[`parent'] // also equals __branch_tail[`parent']
		local tobereplaced "Y"
		`qui' replace __branch_head = `id' in `parent'  // see note about detached node.
		`qui' replace __n_parents = __n_parents -1 in `old_head'
	}
	else {
		local old_tail = __branch_tail[`parent']
		`qui' replace __next = `id' in `old_tail'
	}
}

`qui' replace __branch_tail = `id' in `parent'
if "`tobereplaced'" ~= "" {
	disp "linkage replaced"
}
`qui' replace __n_parents = __n_parents +1 in `id'

/* Note about testing whether mi(__branch_head[`parent']);
applies to any node of interest, and to __branch_tail as well:
The more specific valid range of these variables is 1 .. _N-1.
But we use missing as standing for "not valid".

About detached node: Yes, that node (at `old_head') becomes detached -- at least,
from the parent. But presumably, it is a rptbr root, and is still accessable as
such.
*/

end /* attach_node */





prog def create_node, sclass
syntax name(name= nodename), attach_id(integer) nodetype(integer) [/*label(string)*/ VERbose surrogate]
if "`verbose'" == "" {
	local qui "qui"
}
/*
This creates one node and attaches it.
This could have been called create_and_attach_node, but that could cause
confusion with create_and_attach_nodes.

attach_id is an integer -- the obsno of the node to which to attach the new node.

The idea is that, if you are creating a node, you better have a place in mind to
attach it. (The superroot could be an exception, but we don't plan to use this
for the superroot -- though we could.)

Distinguish the nodetype option and the __nodetype variable.

`surrogate': attach this as a surrogate node, rather than a child.
*/

local node_id = _N+1
`qui' set obs `node_id'

`qui' replace __nodename = "`nodename'" in `node_id'
`qui' replace __residual = 0 in `node_id'
`qui' replace __nodetype = `nodetype' in `node_id'
`qui' replace __n_parents = 0 in `node_id'
/*
if "`label'" ~= "" {
	`qui' replace __nodelabel = `"`label'"' in `node_id'
}
*/

/* We will trust that all other vars in `node_id' are missing at this point.
This is especially important for __branch_head, __branch_tail, and __next.
*/

if "`surrogate'" ~= "" {
	if `nodetype' ~= "surrogate":nodetype {
		disp as err "Improper nodetype option"
		exit 198
	}
	`qui' replace __surr = `node_id' in `attach_id'
}
else {
	attach_node, id(`node_id') parent(`attach_id') `verbose'
}
sreturn local node_id "`node_id'"
end /* create_node */



prog def create_and_attach_nodes
/* Began 2022sep28. This replaces tree_node_00. */

syntax, [ ///
	nodelist1(namelist) nodetype1(integer -2) tag1(string) rptbr1 ///
	nodelist2(namelist) nodetype2(integer -2) tag2(string) rptbr2 ///
	nodelist3(namelist) nodetype3(integer -2) tag3(string) rptbr3 ///
	verbose] id(integer)
/* We use -2 to signify unspecified nodetype1 or nodetype2. Actually, 2 ought to be the lowest value
allowed.
*/
local max_nodelists 3
forvalues jj = 1 / `max_nodelists' {
	if "`nodelist`jj''" ~= "" {
		local nodelistb`jj': list uniq nodelist`jj'
		if "`nodelistb`jj''" ~= "`nodelist`jj''" {
			disp "Nodelist `tag`jj'' has duplicates; reducing to unique names."
		}
		if `nodetype`jj'' <= -2 {
			disp as err "nodetype`jj' absent or incorrectly specified."
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
		local node_id = s(node_id)
		if "`rptbr`jj''" ~= "" {
			** replace __rptbr = 1 in `node_id'
			replace prob = "1" in `node_id'
		}
	}
}
end /* create_and_attach_nodes */






prog def tree_node
assert_tree_data_present
syntax [namelist], [at(namelist) INTerior(namelist) TERMinal(namelist) rlink(namelist) VERbose]

one_or_the_other_not_both, a(`namelist') b(`at') aname(a namelist) bname(an at() option)
if "`namelist'" ~= "" {
	local at "`namelist'"
}


if "`verbose'" ~= "" {
	disp "you called tree_node `0'"
}

if "`at'" == "superroot" {
	disp as err "You may not attach an interior, terminal, or rlink node to superroot."
	disp "Only tree roots may attach to superroot; use " as inp "tree create"
	exit 198
}
if "`at'" == "rptbr" {
	disp as err "You may not attach an interior, terminal, or rlink node to rptbr."
	disp "Only tree roots may attach to rptbr; use " as inp "tree rptbr"
	exit 198
}

if "`terminal'" =="" & "`interior'" == "" & "`rlink'" == "" {
	disp "(No interior or terminal or rlink nodes specified.)"
	/* So no meaningful action will occur. */
}

find_node_via_path `at', norlink
local parent_id `s(node_id)'
if "`rlink'" ~= "" & `s(is_rptbr)' {
	disp as err "You may not declare an rlink within an rptbr."
	exit 198
}
if __nodetype[`parent_id'] == "rlink":nodetype & ///
	("`interior'" ~= "" | "`terminal'" ~= "" | "`rlink'" ~= "") {
	disp as err "You may not declare nodes on an rlink."
	disp as text "Use " as inp "tree rlink"
	exit 198
}
create_and_attach_nodes, ///
	nodelist1(`interior') nodetype1(`="interior":nodetype') ///
	nodelist2(`terminal') nodetype2(`="terminal":nodetype') ///
	nodelist3(`rlink') nodetype3(`="rlink":nodetype') ///
	tag1(interior) tag2(terminal) tag3(rlink) id(`parent_id') `verbose'


/* This seeks the `at' node, regardless of whether `interior' and `terminal' are present.
So it will flag a no-existant node, even if no action is specified.
*/

end /* tree_node */




prog def tree_draw
assert_tree_data_present
syntax [varlist(default=none)] [, SURRogates]
/* -- really should do no more than, say, 4 vars.

Note that the present surrogates option is different from the surrogate option to
tree_traverse.
The present surrogates option indicates to show the surrogates attributes, rather
than the referent rptbr; it is for debugging.
The surrogate option to tree_traverse indicates that the traversal should follow
surrogate nodes, rather than the regular children.

*/

global tree_drawvars "`varlist'"

if "`surrogates'" ~= "" {
	global tree_show_surrogates "Y"
}
else {
	global tree_show_surrogates
}

tree_traverse, depth(0) id(1) parent(0) ///
	action1(draw_node) /*action2(draw_node_first_child)*/ surrogate

if "`:char _dta[rptbr]'" ~= "" {
	disp _n "repeatable branches"
	tree_traverse, depth(0) id(`:char _dta[rptbr]') parent(0) ///
		action1(draw_node)
}

end /* tree_draw */




prog def tree_rlink
syntax namelist, to(name) [replace verbose]

/* Note that `s(node_id)' gets assigned by find_node_via_path and
find_child_node, at different points, yielding different values.
*/
if "`verbose'" == "" {
	local qui "qui"
}


find_node_via_path `namelist', norlink

if `s(via_rlink)' & `s(is_rptbr)' {
	disp as err "You may not set an rlink within an rptbr."
	/* This should not occur, as rlink nodes are prohibited within an rptbr.
	But is has occurred in testing.
	*/
	exit 198
}

/* That prior error msg might be off-the-mark, as we have not tested
__nodetype[`from_id'] to see if it is an rlink.
Also, can `s(via_rlink)' & `s(is_rptbr)' occur ???, given that s(via_rlink)
does not test the final node in `namelist' ??
But all this is moot.
*/

local from_id `s(node_id)'

if __nodetype[`from_id'] ~= "rlink":nodetype {
	disp as err "node (`namelist') is not an rlink"
	exit 198  /* or 459 ? */
	/* A possible alternative action: if it is interior, and has no descendants,
	convert it to rlink.
	*/
}

if "`:char _dta[rptbr]'" == "" {
	disp as err "No rptbr established"
	exit 459
}
else {
	find_child_node `to', id(`:char _dta[rptbr]') require(exist)
	local rptbrnode `s(node_id)'
	attach_node, id(`rptbrnode') parent(`from_id') solitary `replace' `verbose'
	create_node noname /* dummy value */, attach_id(`from_id') nodetype(`="surrogate":nodetype') `verbose' surrogate
	local surrnode `s(node_id)'
	`qui' replace __surr = `rptbrnode' in `surrnode'
	`qui' replace __n_parents = 1 in `surrnode'
}

end / tree_rlink */


prog def tree_verify
assert_tree_data_present
global tree_eval_errors
tree_traverse, depth(0) id(1) parent(0) action1(verify_node)
if "$tree_eval_errors" ~= "" {
	exit 459
}

end /* tree_verify */






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
		disp "No valid `listname' vars specified."
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
end /* note_remove */


prog def tree_eval
assert_tree_data_present
/* ~~~Potentially, this could be targeted to a subtree, using either an id (number) or
namelist (tree path).
As of 2022jun27, it remains to do the whole forest.

Much of the complexity here pertains to rawsum and means, which may be rarely
used.
*/

syntax [iweight] , [rawsum(varlist) MEANs(varlist) VERbose rptbr retain debug]
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
	note_remove S_`v', note(`retention_note') `debug'nodes 
}
foreach v of local means_commonvars {
	note_remove T_`v' M_`v', note(`retention_note') `debug'
}

if "`rptbr'" ~= "" {
	/* rptbr specifies to do the rptbr trees first.
	Thereby, ALL rptbr trees are evaluated -- not just the ones that are
	actually referenced by other nodes.
	*/
	if "`:char _dta[rptbr]'" == "" {
		disp as err "No rptbr established; rptbr option has no effect"
	}
	else {
		tree_eval_traversals, id(`:char _dta[rptbr]')
	}
}
tree_eval_traversals, id(1)

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


prog def tree_eval_traversals
/* This is the section of tree_eval that does the traversals.
It is done as a program so that we might call it multiple times.
*/
syntax, id(integer)
tree_traverse, depth(0) id(`id') parent(0) ///
	action1(init_probs) action3(adjust_probtallys) action4(check_probsum__set_residprob) `verbose'

tree_traverse, depth(0) id(`id') parent(0) action1(set_residual_R_prob) `verbose'


/*
At this point, we could clear all payoff vars.
But, as noted for __probsum and __n_starprobs, we choose to do it
node-by-node in init_payoffvars, for the same reasons.
*/

tree_traverse, depth(0) id(`id') parent(0) action1(init_payoffvars) ///
	action3(add_child_vals_to_payoffvars) `verbose'

end /* tree_eval_traversals */




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

find_node_via_path `minuend'
local minu_id `s(node_id)'

find_node_via_path `subtrahend'
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
and tree_meansvars_prior, rather than tree_meansvars.
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

find_node_via_path `at'
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

disp _n as text "{ul:repeatable branches}"
if "`:char _dta[rptbr]'" ~= "" {
	local jj = __branch_head[`:char _dta[rptbr]']
	while ~mi(`jj') {
		disp as res __nodename[`jj']
		local jj = __next[`jj']
	}
}
else {
	disp "(No repeatable branches defined.)"
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



prog def count_commas, sclass
syntax, s(string)
local len = length(`"`s'"')
local c = 0
forvalues jj = 1 / `len' {
	if substr(`"`s'"', `jj', 1) == "," {
		local ++c
	}
}
sreturn local commacount "`c'"
end /* count_commas */


