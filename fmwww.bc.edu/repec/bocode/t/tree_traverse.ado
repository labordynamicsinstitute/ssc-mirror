/* tree_traverse.ado; 2023oct18, revised 2024nov05, and other dates through
2025apr11. Editing-out debug commands and outdated comments; 2025apr23.

David Kantor.

This extracts the tree-traversal program that had been in tree.ado -- into
its own ado file. We also change the name from traverse_tree to tree_traverse
for consistency.

This is done so as to enable tree.ado and tree_plot.ado to both access the traversal
routine (and not have it replicated within each file).

[2024nov05: there was a plan to have the main part of tree_plot brought into tree.ado,
and tree_plot.ado would have been deemed obsolete. BUT sometime later, tree_plot.ado was
restored as an active component of the tree suite.]

This presumes the structure established by tree_init in tree.ado.

(As of 2024nov05, that's tree2.ado, but that should change back to tree.ado sometime
soon.)

2023oct18: it didn't work out as expected; it can't access the action routines.
2024nov05: It is realized thatthis CAN work if all the action routines are
declared in HERE, rather than in the calling environment.

2025jan14: just edited comments.
2025feb21 ?
2025mar05: just edited comments.

2025apr07: Add the virtual stacking of __n_visits.
*/

prog def tree_traverse

* version 2.0.0 2024nov05
version 14

/* This is a front-end -- the public face -- of tree_traverse_00.
Other programs should call this, and not tree_traverse_00.
*/

/*~~~2025jan27: We could consider making the depth option optional.
Almost every call to this passes depth(0).
Same for parent(0) and id(1).
It's almost consistent for id(1), except for the calls with assign_Rvals.
~~~*/

/* 2025apr07:
Implementing a means of stacking multiple instances of __n_visits.
This is needed for possible concurrent invocations of tree_traverse.

We must distinguish...
	concurrent invocations of tree_traverse
	recursive invocations of tree_traverse_00.
	
The former can happen when an action routine calls
tree_traverse -- as happens in set_ypos.

The latter is just part of the recursive nature of a tree traversal.

You could call both of those situations recursive calls, but the former occurs
when an action happens to need to run a traversal for a purpose other than
recursive descent of the tree.

The stack action is facilitated by the stack of program calls -- built
into Stata.

2025apr09: after considering several options, I settled on...
Each invocation of tree_traverse generates its own instance of __n_visits,
established as a tempvar. This is passed into tree_traverse_00 as a parameter.
tree_traverse has the option to return a copy of __n_visits.
*/

syntax, id(passthru) parent(passthru) depth(passthru) ///
	[location(passthru) action1(passthru) /*action2(passthru)*/ action3(passthru) action4(passthru) ///
	surrogate VERbose assign_Rvals rvals_vars(varlist string) ///
	n_visits(name)]

/* The assign_Rvals option is a kluge. This allows tree.ado to call assign_Rvals
(program), without having an additional copy of assign_Rvals within it.
Thus, there will be just one copy of assign_Rvals.

WIth the assign_Rvals option, this does not actually invoke a tree-traversal!

rvals_vars is the varlist that goes into assign_Rvals (as a feature, not an option).

n_visits is a return parameter; optionally returns a copy of `__n_visits'.
Note that tree_traverse_00 also has an option of the same name; there it
is input: the name of the __n_visits parameter.
*/
if "`assign_Rvals'" ~= "" {
	assign_Rvals `rvals_vars', `id' `location' `verbose'
	exit
}

if "`verbose'" == "" {
	local qui "qui"
}


if "`n_visits'" ~= "" {
	confirm new var `n_visits'
}

tempvar __n_visits
gen byte `__n_visits' = 0

/*
The main reason for having this front-end to tree_traverse_00 is so that this
activity on __n_visits can be consistently done prior to the "entry-level" call to
tree_traverse_00. Otherwise, every entry-level call would need to do this
prior to the call.

And of course, you would NOT want it done in tree_traverse_00.
*/

tree_traverse_00, `id' `parent' `depth' n_visits(`__n_visits') `location' ///
	`action1' /*`action2'*/ `action3' `action4' `surrogate' `verbose'

if "`n_visits'" ~= "" {
	gen byte `n_visits' = `__n_visits'
}
end /* tree_traverse */



prog def tree_traverse_00

/*
This is the "real work" program that visits nodes and does recursive calling
of child nodes.

This should be called from tree_traverse (the front-end) only.
*/

syntax, id(integer) parent(integer) depth(integer) n_visits(varname numeric) ///
	[location(string) action1(name) /*action2(name)*/ action3(name) action4(name) ///
	surrogate VERbose]
/*
id: the obs no of the node that is visited; all of the children of this node are
then visited -- recursively.

Presumably, when this is first called, id is the root of the tree being traversed.
Or it may be a superroot.

action1, action3, & action4: program names -- to be called at various points.

Prior to 2023may05, we had action2 & 3; eliminating them.
Previous Action3 rotines will be blended into action1 routines, but reverse the parent-child roles.
See tree.ado_save021 for historical reference.
BUT SEE the 2024july12 & 16 notes!

That is, an action3 routine can be replaced by an action1 or action4 routine, with
certain changes in the use of id, parent, and child, and possibky other adjustments.
(Note that action3 is invoked just after an action4 invocation for the child (or action1
if there are no action3 or action4 invocations for the child).


2024july12: action3 is being revived. It can possibly make for more concise programming.
It also may help in coding for the instances when you want to PREVENT visiting
descendants beyond the children.

action1 is what is to be DONE at each node as it is visited, prior to
traversing the descendant nodes. It is done on-the-way-in.

2024july16: action2 was formerly for the case where ther are no children; turned out to be unnecessary.
Now reviving the name, but for a different purpose: for when norlinkdescent is active.
(Later eliminated.)

action3 is done immediately after traversing a child node, for passing info from
child back to the present node.

action4 is done after traversing all child nodes; this includes the case in which
there are no children, That is, we invoke it after all visits to the children;
there may zero or more children.

It is done on-the-way-out.
(action4 added 2022mar01.)

In prior versions of this program, action2 and/or action3 were unused, but are
all back in use as of 2024july16. We never renumbered them, so for a while, we
had only action1 & action4;
or action 1, action3, & action4.


These are the options that action routines must take:
action1: id, parent, depth, location
action2: id, parent, depth, location
action3: id, child, depth, location
action4: id, parent, depth, location

All take optional verbose; added 2022oct27.
In action1, parent was added 2022feb28.
For action3, child is locally generated -- not passed in.

Adding a probno option; 2022feb28, 21:57. Removed, 2022jun27.

2025mar06: all of them also get an actord(integer) option -- for action order.
Tells what action number is in effect -- 1, 3, or 4. This is for action routines
that may be used in more than one action type.

Each of these is expected to have the options shown above.
BUT because of the generality, an instance of a given species of action routine
must take all the options, but might not use them all.

Similarly, not every call to tree_traverse_00 needs all the options.

2024nov04: rewriting so that, under norlinkdescent, we look at __nodetype[`parent'],
rather than __nodetype[`id']. This should obviate the need for action2.
But it means that norlinkdescent really means "we're already visiting the first
(only) child of an rlink; that's okay, but don't visit any further down".
This enables the visit to the child to be just a normal visit, activating
action1.

2024nov05: action2 is, once again, eliminated.

2025mar28: surrogate option replaces the earlier norlinkdescent.
Tells us to follow the
__surr link, rather than __branch_head. Not to be confused with the
surrogate nodetype-- though when you follow __surr, you should land on a
surrogate node. (There is the question of whether to trust the nodetype or
the shape of the graph to determine a node's role. We expect that the data are
accurately populated so that you can rely on nodetype.
*/

if _N <1 {
	disp "(no tree)"
	exit 0
}

if "`verbose'" == "" {
	local qui "qui"
}
else {
	disp "tree_traverse_00; id `id', depth `depth'"
}

local location "`location' `=__nodename[`id']'"
/* Note that location initially comes in as the parent's location, but
it now pertains to the present node.
*/

/*~~debug: disp "tree_traverse_00; location `location'" */

`qui' replace `n_visits' = `n_visits' +1 in `id'
/* `n_visits'[`id'] now inlcudes the present visit. */


if `n_visits'[`id'] > __n_parents[`id'] {
	disp as err "cycle detected; node `id', location `location'"
	exit 459
	/* This may raise a false alarm in the case of a surrogate.
	we may need to adapt to that possibility.
	PS (2025mar28) maybe okay, as we should have __n_parents[`id'] = 1
	for a surrogate.
	*/
}

if (`n_visits'[`id'] >1) & (__nodetype[`id'] ~= "surrogate":nodetype) {
	/* Been here already. No need to do anything. So exit.
	But we make an exception for a surrogate node.
	*/
	if "`verbose'" ~= "" {
		disp "**** tree_traverse_00; id `id'; exiting"
	}
	exit
}

/*
One possible thing that could be done here is, if node `id' is an rlink, then
replace id with __branch_head[`id']. That is, jump directly to the node that
node `id' links to.

But this might require a repeat of the activities regarding `n_visits', as
seen above. (They could be made into a program and called a second time.)

But we'd need to be careful about the identity of the parent in the calls to
the action routines. Maybe it would work out naturally.

This would just eliminate one recursive call; not much to worry about, and
things are working okay as-is (2024aug6).
*/

if "`action1'" ~= "" {
	`action1', id(`id') parent(`parent') depth(`depth') actord(1) location(`location') `verbose'
}


if "`surrogate'" ~= "" & __nodetype[`id'] == "rlink":nodetype & ~mi(__surr[`id']) {
	/* Recursive call: */
	tree_traverse_00, id(`=__surr[`id']') parent(`id') depth(`=`depth'+1') ///
		n_visits(`n_visits') location(`location') ///
		action1(`action1') /*action2(`action2')*/ action3(`action3') action4(`action4') `surrogate' `verbose'
	/* ??? Should we invoke action3 here????  Probably not.*/
}
else {
	/* visit the children */
	local jj = __branch_head[`id']
	while ~mi(`jj') {
		/* Recursive call: */
		tree_traverse_00, id(`jj') parent(`id') depth(`=`depth'+1') ///
			n_visits(`n_visits') location(`location') ///
			action1(`action1') /*action2(`action2')*/ action3(`action3') action4(`action4') `surrogate' `verbose'
		if "`action3'" ~= "" {
			`action3', id(`id') child(`jj') depth(`depth') actord(3) location(`location')`verbose'
		}
		if __nodetype[`id'] == "rlink":nodetype {
			local jj "."
			/* Prevent visiting siblings. See note below.*/
		}
		else {
			local jj = __next[`jj']
		}
	}
}

/* Note that for a surrogate node, you shouldn't visit children, but there
should be no children. So no need to do anything special in that regard.
*/

if "`action4'" ~= "" {
	`action4', id(`id') parent(`parent') depth(`depth') actord(4) location(`location') `verbose'
}



/*
If __nodetype[`id'] is an rlink, then we want to prevent visiting the siblings.
Thus, we set jj to missing -- a bit of a kluge.

The reason is that, in this case, we want to visit only this one branch.
The normal operation would be to visit all the siblings of `jj', which are all
the siblings -- all the other repeatable branches.
More precisely, it is the set of repeatable branches that are downstream from the
present one, in the chain defined by __next.

Note that, while a node normally has only one parent, an rlinked repeatable branch
has two or more parents:
	1: the rlink (`id') (there may be multiple rlinks, but that's not important here);
	2: the rptbr superroot.
The __next chain belongs to the latter, but we need to approach the branch from the
perspective of the rlink, which has only one child - the pertinent repeatable branch.

The problem is that the __next chain is stored in the child nodes, but pertains to
the parent. A parent node knows ONLY its first child; each child knows who its next
sibling is. That is, the list of children of node x is stored in the nodes of the
children of x, not in x itself!

This works fine as long as the parent is unique.

[2024nov01} This creates a false representation of the children of an rlink node;
there may appear to be many, but there really should be just one!

We could remedy this situation by letting each node to have its full list of
children. The possibilities are ...

(1) Each node could have its list of children recorded in a linked list
of nodes that are just there to hold the list. This would require a new nodetype!
Each node in the chain would then have a pointer to the actual node that holds
the payoff an prob values. This separates the linked list of children from the
data that pertains to the children. The list of children would belong to the parent.
But this scheme involves an extra level of indirection, and additional nodes --
like about twice as many as we would otherwise.

(2) Another possibility, and a very simple one, would be to not have a linked list;
instead have variables child1, child2, etc.. (We could add more of these variables
dynamically.) Again, this would put the list of children in the direct possession
of the parent.

--> Both of these are interesting ideas. But I don't want to make such a fundamental
change at this point (2024july15 & Aug 6).
PS, 2025apr11: that is an appealing option, but won't implement it presently.

Note that `id' is the current node.
`jj' is initially the first child of `id'; subsequently, it is the second, third,
etc. child of `id'.

BUT from the perspective of the recursive call, `jj' is the visited node, and
`id' is its parent.

*/
end /* tree_traverse_00 */


/* Below are the action routines. */

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
syntax, id(integer) parent(integer) depth(integer) actord(integer) [location(string) verbose]
/* We don't use the verbose option, but all action routines are required to have one.
Same for location.
*/

if ~mi(__next[`id']) & (__nodetype[`parent'] ~= "rlink":nodetype) {
	global tree_depth_`depth'_has_more_children "Y"
}
else {
	global tree_depth_`depth'_has_more_children
}


disp %6.0g `id' " " _cont
draw_node_prefix, depth(`depth')
if `depth' > 0 {
	if ~mi(__next[`id']) & (__nodetype[`parent'] ~= "rlink":nodetype) {
		disp "{c LT}{c -}" /*"+-"*/ _cont
	}
	else {
		disp "{c BLC}{c -}" /*"\-"*/ _cont
	}
}

local referent "`id'"


if __nodetype[`id'] == "terminal":nodetype {
	local typemark "*"
}
else if __nodetype[`id'] == "rlink":nodetype {
	local typemark "**"
}
else if __nodetype[`id'] == "surrogate":nodetype {
	local typemark "***"
	if "$tree_show_surrogates" =="" {
		local referent = __surr[`id']
	}
}

disp __nodename[`referent'] _cont
if "`typemark'" ~= ""{
	disp " `typemark'" _cont
}

if "$tree_drawvars" ~= "" {
	disp _col(35) _cont
}

local sep

foreach v of global tree_drawvars {
	disp "`sep'" `v'[`referent'] _cont
	/* values separated by ";". If this is ambiguous, then we can implement an
	option to quote string values.
	*/
	local sep "; "
}

disp /* end line */

end /* draw_node */

/*--not needed
prog def draw_node_first_child
/* An action2 routine.
Draw the node of the first child of `id'.
*/
syntax, id(integer) parent(integer) depth(integer) [location(string) verbose]
local child1 = __branch_head[`id']
if ~mi(`child1') {
	draw_node , id(`child1') parent(`id') depth(`=`depth'+1') location(`location') `verbose'
	/* `location' would be inaccurate; but unused. */
}
end /* draw_node_first_child */
--*/


prog def verify_node
/* an action1 routine */
syntax, id(integer) parent(integer) depth(integer) actord(integer) [location(string) verbose] 
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



prog def init_payoffvars
/* Prior to 2023may05, this was an action1 routine;
2023may09: restoring it to be action1.
*/
syntax, id(integer) parent(integer) depth(integer) actord(integer) [location(string) verbose]
if "`verbose'" == "" {
	local qui "qui"
}
else {
	disp "init_payoffvars, node `id'" _cont
		/* We could display location. */
}

local payoffvars: char _dta[payoffvars]
if __nodetype[`id'] ~= "terminal":nodetype {
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



prog def add_child_vals_to_payoffvars
/* An action3 routine. */
syntax, id(integer) child(integer) depth(integer) actord(integer) [location(string) verbose]

/* Originally named eval_node; later converted to an action4 routine, under the
name add_child_vals_to_payoffvars.
Then converted to and action4 routine named add_payoff_vals_to_parent.

2024july12: this is being revived, under the (original) name add_child_vals_to_payoffvars
as an action3 routine.


This depends on there having been a call to init_payoffvars prior to the invocatio
of the present program.

Prior to 2021may09, we had a section for __nodetype[`id'] == "terminal":nodetype.
The action was to obtain values from the scalar references.
See tree.ado_save001.

Now, we do nothing under that condition; the values shall have been already
in place.
*/

local payoffvars: char _dta[payoffvars]
if "`verbose'" == "" {
	local qui "qui"
}


/* Earlier, the remaining code in this program was undet the condition:
	if __nodetype[`id'] ~= "terminal":nodetype
But this is unnecessary.
*/
if "`verbose'" ~= "" {
	disp "add_child_vals_to_payoffvars 3; id `id' child `child'"
}
foreach v of local payoffvars {
	`qui' replace R_`v' = R_`v' + R_`v'[`child'] * R_prob[`child'] in `id'
}
foreach v of global tree_rawsumvars {
	`qui' replace S_`v' = S_`v' + S_`v'[`child'] in `id'
}
`qui' replace __weight = __weight + __weight[`child'] in `id'
foreach v of global tree_meansvars {
	`qui' replace T_`v' = T_`v' + T_`v'[`child'] in `id'
}


end /* add_child_vals_to_payoffvars */






prog def adjust_probtallys
/*
2023may05: converting this from an action3 to an action1 routine.
We expect that init_probs (setting R_prob) shall have been invoked, as well as
the clearing of __probsum and __n_starprobs prior to calling this.

See notes in tree_eval.

2024july12: converting BACK to an action3 routine!
(But not axactly the same as the old action3 edition.)
*/
syntax, id(integer) child(integer) depth(integer) actord(integer) [location(string) verbose]
if "`verbose'" == "" {
	local qui "qui"
}
else {
	disp "adjust_probtallys, id `id', child `child'"
}

if __residual[`child'] {
	`qui' replace __n_starprobs = __n_starprobs + 1 in `id'
	}
else {
	`qui' replace __probsum = __probsum + R_prob[`child'] in `id'
}
end /* adjust_probtallys */



prog def init_probs
/* 
An action1 routine.
Initialize the _prob vars; note the leading underscore.

It was tempting to try to do this in a one-line replace command, which might apply
to all records together. But it doesn't work to reference prob -- to extract the
numerical value from an expression as a plain assignment.
Instead, we need the `=prob[`id']' construct. Note that we need to index prob;
otherwise, you get prob[1]. Also note that each invocation applies to ONE observation.

We do this in the context of an action routine to be used in tree_traverse. But it
could also be done by looping through all obs.
*/
syntax, id(integer) parent(integer) depth(integer) actord(integer) [location(string) verbose]

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




prog def set_residual_R_prob
/* 
An action1 routine.
Previously named set_probs, before 2022july02. Later, set_resid_probs.

Replace R_prob in the case of a residual specification.

We PRESUME that init_probs has already been called.
That will have taken care of the normal prob values.
Furthermore, __residprob should have been calculated, which relies on the initial
clearing of __probsum and __n_starprobs, and the running of adjust_probtallys under tree_traverse.
*/

syntax, id(integer) parent(integer) depth(integer) actord(integer) [location(string) verbose]
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
end /* set_residual_R_prob */




prog def check_probsum__set_residprob
/*
An action4 routine.
*/
syntax, id(integer) depth(integer) parent(integer) actord(integer) [location(string) verbose]
/* We don't use the parent option, but all action routines are required to have one.
*/
if "`verbose'" == "" {
	local qui "qui"
}
 
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

`qui' replace __residprob = (1-__probsum[`id'])/__n_starprobs[`id'] in `id'


end /* check_probsum__set_residprob */


/* Action routines for tree_plot, plus some programs that are called by them. */

prog def plot_node
/* An action1 routine. */
syntax, id(integer) parent(integer) depth(integer) actord(integer) [location(string) verbose]
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
local referent "`id'"

if `parent' >0 {
	file write $tree_gfile " pci `ypos_parent' `xpos_parent_r1' `ypos' `xpos_l2'"  /* angled line */
	file write $tree_gfile "	`ypos' `xpos_l2' `ypos' `xpos_l1', lcolor(black) ||" _n /* horizontal line */
	/* Supposedly, you can put "label text" into the pci, but I find that it doesn't work.
	So do the label separately:
	*/
	/* Defaults for most nodetypes: */
	local msym "O" /* circle; for the next scatteri. */
	local state_vec_pos "8" /* to the left, below */
	local fillcolor "yellow"
	local probfmt "$tree_prob_fmt"
	
	if __nodetype[`id'] == "terminal":nodetype {
		left_facing_triangle, ypos(`ypos') xpos(`xpos') half_height($tree_triangle_half_height) width($tree_triangle_width) xsep($marker_xsep)
		local msym "i" /* invisible; for the next scatteri. */
		local state_vec_pos "3" /* to the right */
		local state_vec_gap = 1-$marker_xsep
		/* ~~~ That 1 could be a width parameter, similar to the width option to left_facing_triangle.
		Possibly that same value.
		*/
	}
	else if __nodetype[`id'] == "root":nodetype {
		/* This should line up with depth ==1. */
		local fillcolor "ltblue"
	}
	else if __nodetype[`id'] == "rlink":nodetype {
		local fillcolor "blue"
	}
	else if __nodetype[`id'] == "surrogate":nodetype {
		local fillcolor "cyan"
		local msym "D" /* Diamond */
		local referent = __surr[`id']
	}

	/* Next: scatteri is for the nodes.
	Also put in the nodename.
	*/
	/* Label the node with text (node name, plus (prob in parens). */
	if "$tree_noprob" == "" {
		if mi(R_prob[`referent']) {
			local probfmt %1.0g
		}
		local probtext: disp `probfmt' R_prob[`referent']
		local probtext " (`probtext')"
	}
	local nodelabel =__nodename[`referent']
}
else {
	/* `parent' = 0 -- i.e., no parent; this should occur only for the superroot,
	that is, __nodetype[`id'] == "superroot":nodetype.
	*/
	file write $tree_gfile " pci `ypos' `xpos_l3' `ypos' `xpos_l1', lcolor(black) ||" _n
	
	local superlabel "`=__nodename[`referent']'"
	if "$tree_superlabel" ~= "" {
		local superlabel "$tree_superlabel"
	}
	
	local nodelabel "`superlabel'"
	local msym "S" /* Square */
	local fillcolor "pink"
}

/* Node numbers */
if "$tree_numbers" ~= "" {
	local nodenum "`referent':"
}


file write $tree_gfile `" scatteri `ypos' `xpos' "`nodenum'`nodelabel'`probtext'", mlabposition(10)  mlabsize(vsmall) mlabcolor(black) msym(`msym') mcolor(black) mfcolor(`fillcolor') msize(medium) mlabgap(0) ||"' _n


/* The state vector */
if "$tree_varstodisp" ~= "" {
	foreach v of global tree_varstodisp {
		local vars_disp_text "`vars_disp_text' `:disp `v'[`referent']'"
	}
	file write $tree_gfile `" scatteri `ypos' `xpos' "`vars_disp_text'", mlabposition(`state_vec_pos') mlabsize(vsmall) mlabcolor(black) msym(i) mlabgap(`state_vec_gap') ||"' _n
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



prog set_ypos
/* An action1 OR action4 routine.
Set __ypos of a given node; could be terminal or interior.
terminal for action1, non-terminl for action4.

Also set a few other items (globals).

Why have this program that serves two distinct purposes, depending on `actord'
and corresponding limitations on __nodetype[`id']?

Actually, we previously (prior to 2025mar12) had two separate programs:
set_ypos_term and set_ypos_int. But there was enough in common between them so
that it made sense to combine them and reduce redundant code.
*/
syntax, id(integer) parent(integer) depth(integer) actord(integer) [location(string) verbose]

if (`actord'==1) & (`depth' > $tree_maxdepth) {
	/* First time visiting this depth */
	global tree_maxdepth `depth'
	global tree_ypos_`depth' /* clear */
}

if (`actord'==1) & (__nodetype[`id'] == "terminal":nodetype) ///
 | (`actord'==4) & (__nodetype[`id'] ~= "terminal":nodetype) {
	if "${tree_ypos_`depth'}" == "" {
		local next_avail_ypos 0
	}
	else {
		local next_avail_ypos = ${tree_ypos_`depth'} + 16
	}
	if __nodetype[`id'] == "terminal":nodetype {
		replace_ypos = `next_avail_ypos' in `id' , depth(`depth') `verbose'
		if "`verbose'" ~= "" {
			disp "set_ypos (term); node `id', dep `depth', __ypos " __ypos[`id']
		}
	}
	else /* __nodetype[`id'] non-terminal */ {
		local mean_ypos_of_children = ///
		 (__ypos[__branch_head[`id']] + __ypos[__branch_tail[`id']])/2
		if mi(`mean_ypos_of_children') {
			/* There are no children; an improper condition, but can happen easily. */
			local mean_ypos_of_children "`next_avail_ypos'"
		}
		
		replace_ypos = `mean_ypos_of_children' in `id', depth(`depth')

		if "`verbose'" ~= "" {
			disp "set_ypos (nonterm); node `id', dep `depth', __ypos " __ypos[`id']
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
			tree_traverse, depth(`depth') id(`id') parent(`parent') action1(increment_ypos) ///
				`verbose' surrogate
			/* increment_ypos will take care of adjusting tree_ypos_`depth' in the depth of the
			present node and all decendant nodes.
			*/
		}
	}
}

end /* set_ypos */


prog def replace_ypos
syntax =/exp in, depth(integer) [verbose]
/* replace __ypos at a specified obsno. But also maintain (global) tree_ypos_`depth'.
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
syntax, id(integer) parent(integer) depth(integer) actord(integer) [location(string) verbose]

replace_ypos = __ypos[`id'] + $tree_ypos_increment in `id', depth(`depth')
end /* increment_ypos */




