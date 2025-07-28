{smcl}
{* 2022july15, 2023jun27, sep26, oct18, 2024may13, aug13, 2025jul25}
{hline}
help for {hi:tree}
{hline}

{title:Facility for creating, managing, and evaluating decision trees}

{p 4 4 2}
This suite of commands enables you to...{p_end}
{p 6 6 2}{c 149} specify the structure and payoff variables for one or more decision trees;{p_end}
{p 6 6 2}{c 149} specify values for payoff variables in terminal nodes;{p_end}
{p 6 6 2}{c 149} specify probability values in all nodes;{p_end}
{p 6 6 2}{c 149} propagate payoff values toward the roots;{p_end}
{p 6 6 2}{c 149} extract payoff values at a specified node;{p_end}
{p 6 6 2}{c 149} take differences in payoff values between a specified pair of nodes.{p_end}

{title:A Brief Note on Compatibility}

{p 4 4 2}
With Version 2 there has been a change in the data format which is unlikely to
have any impact on your work if you are continuing work that began under Version 1.
See {help tree##data_compatibility:Data Compatibility}

{title:Preliminary Disucssion}

{p 4 4 2}
This facility provides the capability to construct a representation of decision trees,
or, more generally, directed, rooted trees. These are
abstract structures that can be used for modeling decision processes or hierarchical relationships.
While this facility was initially developed for use with decision processes,
it may also be useful in modeling hierarchical relationships.
See {help tree##sums_and_means:Raw Sums and Means} for details on this matter.

{p 4 4 2}
The following discussion relies on an understanding of certain concepts:{p_end}
{p 6 6 2}{c 149} Graph and Tree (in the topological sense){p_end}
{p 6 6 2}{c 149} Connected graph{p_end}
{p 6 6 2}{c 149} Cycles in a graph{p_end}
{p 6 6 2}{c 149} Forest{p_end}
{p 6 6 2}{c 149} Node (or point or vertex){p_end}
{p 6 6 2}{c 149} Link (or edge or connection){p_end}
{p 6 6 2}{c 149} Directed link{p_end}
{p 6 6 2}{c 149} To follow a link in the forward or reverse direction{p_end}
{p 6 6 2}{c 149} Rooted tree{p_end}
{p 6 6 2}{c 149} Root node{p_end}
{p 6 6 2}{c 149} Interior node{p_end}
{p 6 6 2}{c 149} Terminal node{p_end}
{p 6 6 2}{c 149} Parent node{p_end}
{p 6 6 2}{c 149} Child node{p_end}
{p 6 6 2}{c 149} Sibling nodes and sibling set{p_end}
{p 6 6 2}{c 149} Path{p_end}
{p 6 6 2}{c 149} Directed (forward) path, or path of descendancy{p_end}
{p 6 6 2}{c 149} Reverse path, or path of parentage{p_end}
{p 6 6 2}{c 149} Subtree (or branch){p_end}
{p 6 6 2}{c 149} Directed Acyclic Graph (DAG){p_end}

{p 4 4 2}
If you need clarification on these concepts, you should see
{help tree##about_trees:About Trees}, below.

{p 4 4 2}
You can {help tree##syntax:click here to jump to the section on syntax}.

{p 4 4 2}
The trees are constructed in the current dataset, which must be empty
prior to the start of the construction phase. Such trees will contain{p_end}
{p 6 6 2}{c 149} "payoff" variables,{p_end}
{p 6 6 2}{c 149} a probability variable.{p_end}

{p 4 4 2}
The payoff variables, are user-defined, and carry numeric quantities that are of interest to the analyst.
The probability variable contains values of a discrete distribution function,
as will be explained below.

{p 4 4 2}
Trees can model decision processes in that each interior node (or root) corresponds to a
juncture in a decision process; the forward links and the nodes that they lead to
(the children) correspond to the choices that one might take as one passes through that juncture.
That is, a decision juncture is modeled by an interior node or root; the possible choices are
modeled by the children. There are other places in the decision process where there are no more
choices to be made; those correspond to terminal nodes.

{col 12}{hline}
{p 12 12 12}
There may be places where there
is a next step in the decisions process, but where there is only one available "choice".
In the corresponding tree, such a node is not terminal; it is an interior node with
just one child. You can, optionally, reduce the parent and child to one teminal node,
or you may elect to keep them
as separate nodes, to model the various stages of the decision process.{p_end}
{col 12}{hline}

{p 4 4 2}
Another way to view the decision process is that there is a starting
population which divides into several sub-populations according to some particular characteristic,
thus, partitioning the initial population.
In similar fashion, the sub-populations divide further, and so on, until they stop dividing.
The root corresponds to the initial population, but it also represents the 
point at which that initial population divides;
each child of the root corresponds to
one of the initial sub-populations.
Similarly, an interior node corresponds to a sub-population,
but it also represents the 
point at which that sub-population divides.
The children of that node correspond to
the sub-populations of the sub-population corresponding to the given node.
A terminal node corresponds to a sub-population, but one which does not divide
further.

{p 4 4 2}
The probability value can be considered as...{p_end}
{p 6 6 2}{c 149} the probability of
taking a particular choice at a given juncture in a decision process;{p_end}
{p 6 6 2}{c 149} the proportion
of instances of the decision process that take the specified choice at that juncture;{p_end}
{p 6 6 2}{c 149} the proportion of a population (at a parent node) that has the characteristic represented by the
particular child node.

{p 4 4 2}
The probability values ostensibly belong to the links. But each link leads to a
unique child node, so that there is a one-to-one correspondnce between links and
children. Thus, we can associate the probability with the child node.
That is, we consider the probability as an attribute of the child node,
rather than the link.
(This holds in a directed rooted tree. It breaks down in a DAG, where the mapping
from link to child node may be many-to-one. While the use of repeatable branches
makes for a DAG structure, it remains valid to associate the probability with the
child node. See {help tree##rptbr:Repeatable Branches} for an explanantion of
this matter.)

{p 4 4 2}
Payoff variables are assigned values in the terminal nodes; probability values are
assigned to all nodes except for roots, usually not the roots. (See {help tree##superroot:Superroot}
for an exception.) The purpose of the
{cmd:tree} facility is to facilitate the propagation of payoff values toward the roots of the
trees, according to the probability values encountered along the way as the
reverse path to the roots is traced. Typically, analysts are interested in the
resulting payoff values at the roots or at one link away from the roots. Also,
typically, analysts are interested in the difference between payoff values
at two selected nodes.

{p 4 4 2}
The {cmd:tree} facility is capable of modeling a multitude of trees taken together,
that is, a forest. In this case, all trees in the forest have the same set of
payoff variables.

{p 4 4 2}
In this facility, there are two types of names that you will be concerned with:
node names and variable names; we will discuss node names first. Every node is
given a name, which is a sequence of characters that adheres to the Stata convention on names:

{p 8 8 2}
A name is a sequence of letters, digits, or underscore characters; it begins with
a letter or underscore, and may contain digits thereafter.
It is contiguous, in that it does not contain spaces.
There is a maximal length of 32 characters. Certain names are reserved and cannot be used:
{cmd:if}, {cmd:in}, {cmd:using}, {cmd:with}.
(These are names that are syntactically significant in Stata commands, which
comprise a proper subset of the Stata {help reswords:reserved} names.
Thus, node names are slightly less restrictive than variable names.)

{p 8 8 2}
Presumably, one may use non-plain-ASCII Unicode characters such as {cmd:é}, however
this has not been tested.

{p 4 4 2}Node names are case-sensitive, and are "locally unique", which will be explained below.
Also, the names {cmd:superroot} and {cmd:rptbr} are not allowed as root names.
(They are allowed in other nodes, though there is probably no need for such node names, and
may prove confusing to the user. See {help tree##superroot:Superroot} and {help tree##rptbr:Repeatable Branches}
for more on this matter.)

{p 4 4 2}
We may sometimes speak of the "tree name", which is the name of the root node.

{p 4 4 2}
Every node is designated as {ul:root}, {ul:interior}, {ul:rlink}, or {ul:terminal},
a distinction known as
the {ul:node type}, which is a fixed attribute of every node. That is, a node's
type is determined when the node is created, and is unalterable.
This differs from the graph-theoretic notion of a node type, which is determined
by its connections to other nodes. See {help tree##further_remarks:Further Remarks}
for more on this matter.

{p 4 4 2}
A root is a distinct node type, but, aside from its role as the entry point
of a tree, functions like an interior node.

{p 4 4 2}
An rlink is like an interior node, but has a special purpose: to link to a repeatable
branch. See {help tree##rptbr:Repeatable Branches} for more on this topic.

{col 12}{hline}
{p 12 12 12}
There are other node types: {ul:superroot} and {ul:surrogate}, which are used internally,
though there are situations in which you may access a superroot.
See {help tree##superroot:Superroot}.{p_end}
{col 12}{hline}

{p 4 4 2}
A root or an interior node may have forward connections to other nodes {c -} interior,
rlink, or terminal, but never to a root. For a given node, a node that it
directly connects to in the forward direction is known as a {ul:child} of that node;
there may be a multitude of such nodes, known as the {ul:children}.
You can also
follow connections in the reverse direction, leading to the {ul:parent} of a given
node, which may be an interior node or a root. The parent relation is unique; a node may have
many children, but only one parent (but see below); a root has no parent; every non-root node has a parent.
Since the parent relation
is unique, you can trace a unique path of parentage (backward) from any non-root node to a root.
If you trace that path in the opposite direction (which is forward), you get the
unique forward path from a root to any given node. Call this a {ul:path of descendancy};
every node has its own unique path of descendancy.

{p 4 4 2}
Starting at a root, if you trace any path in the forward direction, you should eventually
get to a node with no children, ostensibly, a terminal node. This is a consequence of the
trees being acyclic and finite.

{col 12}{hline}
{p 12 12 12}
{hi:Technical note:}
We just noted that a root has no parent. This statement is correct in the study
of topological trees, however, in the implementation of trees in the present program,
root nodes do have a parent: the {help tree##superroot:superroot}. But it is true that
the superroot has no parent.

{p 12 12 12}
Also, we stated that the parent relation is unique.
This restriction is relaxed in
the case of Repeatable Branches, though it is done in a limited
fashion so as to minimize confusion. In particular, within a repeatable branch,
the parent relation is unique, and any parental chain (reverse sequence) leads back
to the root of that repeatable branch. Similarly, within a repeatable branch,
every node has its own unique path of descendancy starting from the root of the
repeatable branch. Thus, the claims of unique parentage and unique path of
descendancy hold if you regard a repeatable branch as a tree, and ignore the
references via rlink nodes. See {help tree##rptbr:Repeatable Branches} for more on
this matter.{p_end}
{col 12}{hline}

{p 4 4 2}
Any interior node, along with all of its descendant nodes, may be seen as a
tree in its own right, with the given starting node as its root. 
Thus, it is a subtree of the larger tree. (We are using the
term "root" loosely here, as it relates to the present program, since the node
in question does not have its node type as {ul:root}. But in terms of graph theory,
it is a root.)

{p 4 4 2}
A subtree may also be referred to as a {ul:branch}.

{p 4 4 2}
A subtree (or branch) is often identified with its root node. That is, we may speak of
the branch rooted at {cmd:x}. Similarly, in the case of multiple trees,
we may speak of the tree rooted at {cmd:y}. A given tree or branch is the set of
nodes that have {cmd:y} or {cmd:x} as their common ancestor.
(The parentage paths of these nodes lead back to {cmd:y} or {cmd:x}.)
Loosely speaking, we might refer to tree {cmd:y} or branch {cmd:x}, when we really
mean the tree or branch rooted at those nodes.

{p 4 4 2}
It's worth noting that every node belongs to a unique tree,
identified by the root that its parentage path leads to.
(In the case of a repeatable branch, this holds if we limit the scope to rlink
nodes.)

{p 4 4 2}
While we define a tree as a graph with certain properties, it is helpful to think
of a tree in terms of constructing it from the roots outward, by attaching child nodes
as you go. Each node that is added must be new {c -} distinct from any existing node.

{p 4 4 2}
The {ul:locally unique} property states that the names of the children of any
given node are unique within that set of children (a sibling set).
Similarly, the names of roots are unique among the set of root names. This implies that the
path of descendancy from a root to any descendant node is has a corresponding unique
sequence of node names. Therefore, every node can be uniquely identified by the sequence
of node names along its path of descendancy. This will be a useful property in
many of the {cmd:tree} commands, as will be described below.

{p 4 4 2}
In terms of Stata data, the nodes are observations, and the payoff and probability variables
are Stata data variables. Therefore, all nodes carry the {it:same} set of payoff
variables plus a probability variable. (There may be a multitude of payoff variables,
but just one probability variable.) The names of the payoff variables are
user-specified (in {cmd:tree init}); the name of the probabilty variable is fixed
as {cmd:prob}.

{p 4 4 2}
When we speak of payoff variables, each of these is actually
a family of variables with a common "basename", where the basenames are what you specify in
{cmd:tree init}. {cmd:prob} is also a basename.

{p 4 4 2}
Each basename becomes a variable, but one or more additional related variables
are generated; their names are modified versions of the basename, by applying various prefixes.
Additionally, certain
commands (e.g., {cmd:tree diffs}) will generate scalars with names derived from the basename.

{p 4 4 2}
Each basename is the name of a textual ({help datatypes:strL}) variable which holds expressions to
be evaluated for that payoff variable or {cmd:prob}.
Additionally, there is always at least one related variable generated:
a numeric ({help double}) variable to receive the evaluation of those expressions.
The latter variable is named {cmd:R_}{it:basename}, that is, it acquires an {cmd:R_} prefix.
Thus, if there is a payoff variable with basename {cmd:cost}, the corresponding numeric
numeric variable is {cmd:R_cost}. You also get {cmd:R_prob} along with {cmd:prob}, automatically.

{p 4 4 2}There may be additional manifestations of payoff variables, depending on commands that the
user may issue; see {help tree##sums_and_means:Raw Sums and Means}.

{p 4 4 2}The basenames are subject to the usual restrictions
on variable names (see {help reswords:naming conventions}), but they also are limited to a length of 30 characters.
Certain other restrictions apply, as will be explained under {help tree##further_remarks:Further Remarks}.

{p 4 4 2}The length should be <=29 if you intend to call {cmd:tree eval} with the
{opt rawsum} or {opt means} option(s), followed by {cmd:tree diffs},
{cmd:tree a_minus_b}, or {cmd:tree values} with a prefix longer than 1.

{p 4 4 2}
The contents of the textual variables are expected to be valid numeric expressions, in that they can be evaluated
as numeric values {c -} not necessarily immediately, but at the time that {cmd:tree eval}
is called. This will be explained further under {help tree##further_remarks:Further Remarks}.

{p 4 4 2}
The numeric variables may be considered as internal to the {cmd:tree} program, but
there may be occasions to reference them, as will be shown in {help tree##further_remarks:Further Remarks}.

{p 4 4 2}
In what follows, "payoff variable" may refer to the textual or numeric
manifestation of the variable, or the basename, or to the family of variables, depending on the context.

{p 4 4 2}
You specify expressions for the payoff variables in the terminal nodes, and for {cmd:prob}
in any type of node; these expressions are stored in the textual manifestation of these variables.
Later, when you call {cmd:tree eval},{p_end}
{p 6 6 2}{c 149} these expressions get evaluated, and the values are stored
in the corresponding numeric variables ({cmd:R_}{it:basename} and {cmd:R_prob});{p_end}
{p 6 6 2}{c 149} the payoff values are propagated from the terminal nodes into
parent interior nodes and toward the roots in accordance with {cmd:R_prob} values.
Think of this as having payoff values flow from terminal nodes
backwards toward the roots.{p_end}
{p 6 6 2}{c 149} Optionally, other variants on the payoff variables may be generated and
propagated toward the roots. See {help tree##sums_and_means:Raw Sums and Means}.

{p 4 4 2}
Payoff variable
names are independent of node names. That is, a node and a payoff variable may have the same name;
you probably don't want to do this, as it may confuse people, but won't confuse the tree program.

{hline}

{marker syntax}{title:Syntax}

{p 4 4 2}
Some of these syntax descriptions include various namelists, which are
space-separated sequences of node names {c -} nodes to be created.

{p 4 4 2}
Some of these syntax descriptions include {it:treepath}, which serves to identify
a tree root or any node. It is a space-separated sequence of existing node names,
starting with a root name, followed by 0 or more interior node names, tracing
the path of descendancy to a given node; it is the unique node-name sequence that corresponds
to the node's path of descendancy. It may or may not end at a terminal node, depending on the
context.

{p 4 4 2}
Some of these syntax descriptions include references to {cmd:rptbr} or {cmd:rlink},
which pertain to repeatable branches.
This will be described under {help tree##rptbr:Repeatable Branches}.
We will use the term {ul:regular tree} to refer to all a tree that is not
a repeatable branch. A regular tree may have a node that links to a repeatable branch,
but the tree itself is not a repeatable branch.

{p 4 4 2}
Some of the options to these commands will be explained below.

{p 4 4 2}
Initialize the current (empty) dataset to hold decision trees

{p 8 10 2}
{cmd:tree init} {it:payoffvarlist} [{cmd:,} {opt ver:bose}]

{p 6 6 2}
where {it:payoffvarlist} establishes the basenames of payoff variables to be included
in the trees.

{p 4 4 2}
Create one or more decision trees

{p 8 10 2}
{cmd:tree create} {it:treenamelist} [{cmd:,} {opt ver:bose}]

{p 6 6 2}
Where {it:treenamelist} is a list of root names of trees to be created.

{p 4 4 2}
Establish one or more nodes to be attached at a specified tree or interior node

{p 8 10 2}
{cmd:tree node,} {opt at(treepath)} [{opt int:erior(intnodenamelist)} {opt term:inal(termnodenamelist)}
{opt rlink(rlinknodenamelist)}
{opt ver:bose}]

{p 6 6 2}
Alternative syntax

{p 8 10 2}
{cmd:tree node} {it:treepath} [{cmd:,} {opt int:erior(intnodenamelist)} {opt term:inal(termnodenamelist)}
{opt rlink(rlinknodenamelist)}
{opt ver:bose}]


{p 6 6 2}
Where {it:treepath} (described above) identifies an existing tree or interior node.

{p 6 6 2}
{it:intnodenamelist}, {it:termnodenamelist}, and {it:rlinknodenamelist} are names of interior, terminal,
and rlink nodes to be established as children of the node identified in {it:treepath}.

{p 4 4 2}
Establish one or more repeatable branches

{p 8 10 2}
{cmd:tree rptbr} {it:rptbrnamelist} [{cmd:,} {opt ver:bose}]

{p 6 6 2}
Where {it:rptbrnamelist} is a list of root names of repeatable branches to be created.

{p 4 4 2}
Establish a link to a repeatable branch

{p 8 10 2}
{cmd:tree rlink} {it:treepath} {cmd:,} {opt to(rptbrrootname)} [replace]

{p 6 6 2}
Where {it:treepath} identifies an rlink node, and {it:rptbrrootname} names an
existing repeatable branch.

{p 4 4 2}
Draw a textual diagram of the tree structure

{p 8 10 2}
{cmd:tree draw} [{it:varlist}] [{cmd:,} {opt surr:ogates}]

{p 4 4 2}
Draw an image of the tree using Stata graphics capabilities

{p 8 10 2}
{cmd:tree plot} [{it:varlist}] [{cmd:,} {opt superlabel(superlabeltext)}
{opt numbers}
{opt gphsav:ing(gphfilename)}
{opt gphasis} {opt gphreplace}
{opt dosave(dofilename)} {opt doreplace} {opt prob_places(#)} {opt noprob}
{opt base:names}
{opt rptbr}
]

{p 6 6 2}
Due to the way this is programmed, you can also write{p_end}
{p 8 10 2}
{cmd:tree_plot} ...

{p 6 6 2}
Either way, this is not to be confused with {cmd:treeplot}, a separate user-written program,
which does a much different task. ({cmd:ssc des treeplot})

{p 4 4 2}
See {help tree##draw_and_plot:Draw and Plot} for more on the use of the
{cmd:draw} and {cmd:plot} subcommands.

{p 4 4 2}
List the payoff variables and trees

{p 8 10 2}
{cmd:tree des}

{p 4 4 2}
Set the values of payoff variables and/or probabilities for a given node

{p 8 10 2}
{cmd:tree setvals,} {opt at(treepath)} [{it:v1}{cmd:(}{it:v1exp}{cmd:)} {it:v2}{cmd:(}{it:v2exp}{cmd:)}
... {it:vn}{cmd:(}{it:vnexp}{cmd:)} {cmd:prob(}{it:probexp}{cmd:)}
{opt check} {opt nosub} {opt ver:bose}]

{p 6 6 2}
Alternative syntax

{p 8 10 2}
{cmd:tree setvals} {it:treepath} [{cmd:,} {it:v1}{cmd:(}{it:v1exp}{cmd:)} {it:v2}{cmd:(}{it:v2exp}{cmd:)}
... {it:vn}{cmd:(}{it:vnexp}{cmd:)} {cmd:prob(}{it:probexp}{cmd:)}
{opt check} {opt nosub} {opt ver:bose}]

{p 6 6 2}
Where {it:treepath} (described above) identifies a tree or an interior node.

{p 6 6 2}
{it:v1}, {it:v2}, etc. are basenames of payoff variables, as specified in {cmd:tree init}.
That is, the basenames of the payoff variables become options in {cmd:tree setvals}.
So does {cmd:prob}.

{p 6 6 2}
{it:v1exp}, {it:v2exp}, etc. and {it:probexp} are expressions that can be evaluated
as numeric values, or rather, they can be evaluated when {cmd:tree eval} is called.

{p 6 6 2}
The setting of
payoff values is allowed only on terminal nodes. Thus, for an interior node, you may
set {cmd:prob} only:

{p 8 10 2}
{cmd:tree setvals} {it:treepath} [{cmd:, prob(}{it:probexp}{cmd:)} {opt check} {opt nosub} {opt ver:bose}]

{p 6 6 2}or alternatively:

{p 8 10 2}
{cmd:tree setvals,} at({it:treepath}) [{cmd:prob(}{it:probexp}{cmd:)} {opt check} {opt nosub} {opt ver:bose}]

{p 6 6 2}These expressions may include references to {help global} macros to be evaluated later,
when {cmd:tree eval} is called. However, you must use {cmd:@} rather than {cmd:$} to indicate
global-macro dereferencing.

{p 6 6 2}
{it:probexp} may also take the special value {cmd:*} to indicate a residual probability.

{p 6 6 2}
For a given node, you may set all the payoff variables and {cmd:prob} in one command,
or spread these actions over several commands. You may also change the values by issuing additional
{cmd:tree setvals} commands for the same node and payoff variables and/or {cmd:prob}.

{p 6 6 2}
When setting values in repeatable branches, certain considerations are pertinent.
See {help tree##rptbr:Repeatable Branches}.

{p 4 4 2}
Evaluate the payoff and probability values; propagate payoff values toward the roots;
optionally compute raw sums or means

{p 8 10 2}
{cmd:tree eval} [{help weight}] [{cmd:,} {opt rawsum(rawsumvars)} {opt mean:s(meansvars)}
{opt rptbr} {opt retain} {opt ver:bose}]

{p 6 6 2}
The {help weight} feature applies to the {opt mean:s} option only.

{p 4 4 2}
Check that the expressions for payoff variables and {cmd:prob} are valid
numeric expressions. (Missing values count as valid in this context.)

{p 8 10 2}
{cmd:tree check} [{cmd:,} {opt ver:bose}]

{p 4 4 2}
Take differences of payoff values between two nodes

{p 8 10 2}
{cmd:tree diffs,} {opt minu:end(treepath1)} {opt subtra:hend(treepath2)} [{opt pref:ix(pref)}]

{p 6 6 2}
Alternative command and syntax for differences

{p 8 10 2}
{cmd:tree a_minus_b,} {opt a(treepath1)} {opt b(treepath2)} [{opt pref:ix(pref)}]

{p 4 4 2}
Extract payoff values at a particular node

{p 8 10 2}
{cmd:tree values,} {opt at(treepath)} [{opt pref:ix(pref)}]

{p 4 4 2}
Preserve the probability settings

{p 8 10 2}
{cmd:tree preserveprob} [{cmd:,} {opt chan:nel(#)} {cmd:replace} {opt ver:bose}]

{p 4 4 2}
Restore the probability settings

{p 8 10 2}
{cmd:tree restoreprob} [{cmd:,} {opt chan:nel(#)} {opt ver:bose}]

{p 4 4 2}
Preserve the payoff value settings

{p 8 10 2}
{cmd:tree preservepayoff} [{cmd:,} {opt chan:nel(#)} {cmd:replace} {opt ver:bose}]

{p 4 4 2}
Restore the payoff value  settings

{p 8 10 2}
{cmd:tree restorepayoff} [{cmd:,} {opt chan:nel(#)} {opt ver:bose}]

{p 4 4 2}
Preserve the probability and payoff value settings

{p 8 10 2}
{cmd:tree preserveall} [{cmd:,} {opt chan:nel(#)} {cmd:replace} {opt ver:bose}]

{p 4 4 2}
Restore the probability and payoff value settings

{p 8 10 2}
{cmd:tree restoreall} [{cmd:,} {opt chan:nel(#)} {opt ver:bose}]

{p 4 4 2}
Verify proper tree structure in the dataset

{p 8 10 2}
{cmd:tree verify} 


{hline}

{title:Options not explained above}

{p 4 4 2}
{opt verbose}: additional information is displayed as the command is executed.

{p 4 4 2}
{opt chan:nel(#)} for the {cmd:preserve} and {cmd:restore} commands: 
specify which, of possibly many "channels", the
preserve or restore operation is to use. The channel value may be any integer
from 0 to 99, with 0 being the default.

{p 4 4 2}
{opt replace} for the {cmd:preserve} subcommands: specify that the preserved
values may overwrite existing values in the indicated channel.

{p 4 4 2}
For the {cmd:tree rlink} command, it specifies that you are replacing an existing
link to a repeatable branch.

{p 4 4 2}
{opt nosub} for the {cmd:setvals} subcommand: prevent the substitution of {cmd:$}
for {cmd:@}.

{p 4 4 2}
{opt check} for the {cmd:setvals} subcommand: check that the expressions for payoff variables and prob are valid
numeric expressions. (Missing values count as valid in this context.)
This is meaningful only if all the components of the expressions are defined at
the time that {cmd:setvals} is called.

{p 4 4 2}
Note that there is also a {cmd:tree check} command. The {opt check} option in
{cmd:tree setvals} performs the check for the specific node indicated and for only the
variables specified; the {cmd:tree check} command performs the check for all nodes
and all payoff variables and prob.

{p 4 4 2}
{opt pref:ix(pref)} for {cmd:tree diffs}, {cmd:tree a_minus_b}, and {cmd:tree values}:
set a prefix for
the names of {help scalar}s that are to be defined. The defaults are
{cmd:d_} for {cmd:tree diffs} and {cmd:tree a_minus_b}, and {cmd:v_} for {cmd:tree values}.

{p 4 4 2}
{opt rawsum(rawsumvars)} for {cmd:tree eval}: specify variables for which to propagate
raw sums toward the roots. See {help tree##sums_and_means:Raw Sums and Means}, below.

{p 4 4 2}
{opt mean:s(meansvars)} for {cmd:tree eval}: specify variables for which to propagate
weighted sums and means toward the roots. See {help tree##sums_and_means:Raw Sums and Means}, below.

{p 4 4 2}
{opt retain} for {cmd:tree eval}: specify that variables pertaining to rawsums or means
from an earlier invocation of {cmd:tree eval} are to be retained. The default action
is to drop them. See {help tree##sums_and_means:Raw Sums and Means}, below.

{p 4 4 2}
{opt superlabel(superlabeltext)} for the {cmd:plot} subcommand: specify alternative
text to be written for labeling the superroot in the plot; the default is {cmd:superroot}.

{p 4 4 2}
{opt numbers} for the {cmd:plot} subcommand: specify that node numbers are to be
displayed in the plot.

{p 4 4 2}
{opt gphsav:ing(gphfilename)} for the {cmd:plot} subcommand: save the plot as a
Stata graphics (.gph) file.

{p 6 6 2}
As with the {help graph save} command, if {it:gphfilename} is specified without an extension,
{cmd:.gph} is assumed.

{p 4 4 2}
{opt gphasis} for the {cmd:plot} subcommand: employ the {cmd:asis} option in saving
the plot. See {help graph save}.

{p 4 4 2}
{opt gphreplace} for the {cmd:plot} subcommand: employ the {cmd:replace} option in saving
the plot; the file may be replaced if it already exists.

{p 4 4 2}
{opt dosave(dofilename)} for the {cmd:plot} subcommand: save the generated do-file
under the specified name. If {it:dofilename} is specified without an extension,
{cmd:.do} is assumed.

{p 4 4 2}
{opt doreplace} used with {opt dosave(dofilename)}, specifies that {it:dofilename}
may be replaced if it already exists.

{p 4 4 2}
{opt prob_places(#)} for the {cmd:plot} subcommand: specify the number of decimal places
to report probability values. The default is 3.

{p 6 6 2}
The plot will, by default, display probability values after the node names, in parentheses. Note that
this is R_prob {c -} the numeric value, rather than the prob expression. Therefore,
you will not get correct R_prob values unless you have called {cmd:tree eval} after
the most recent setting of {cmd:prob} (via {cmd:tree setvals}).

{p 6 6 2}
Note that{p_end}
{p 8 10 2}
{cmd:tree setvals} {it:treepath}{cmd:, prob(}{it:probexp}{cmd:)} {opt check}{p_end}
{p 6 6 2}
will suffice to evaluate R_prob, but that is node-specific.

{p 4 4 2}
{opt noprob} for the {cmd:plot} subcommand: suppress the reporting of probability
values.

{p 4 4 2}
{opt base:names} for the {cmd:plot} subcommand: the variables listed in {it:varlist}
are taken as basenames of payoff variables, and the {cmd:R_} versions are substituted.

{p 6 6 2}
Prior to Version 2.0, this was the treatment of {it:varlist} in {cmd:tree plot}.
See {help tree##draw_and_plot:Draw and Plot} for more on this matter.

{p 4 4 2}
{opt rptbr} for the {cmd:plot} subcommand: draw the repeatable branches, rather
than the regular trees.

{p 4 4 2}
{opt rptbr} for the {cmd:eval} subcommand: evaluate all repeatable branches
before evaluating the regular trees. This assures that all repeatable branches
get evaluated, whereas the default procedure is to evaluate repeatable branches
on an as-needed basis {c -} that is, evaluate only those repeatable branches
that are linked to nodes in the regular trees.

{p 4 4 2}
This may be useful if you want to obtain values or differences of payoff variables
in repeatble branches regardless of whether they are actually used.

{p 4 4 2}
{opt surr:ogates} for the {cmd:draw} subcommand: show the nodename and values
of specified variables of surrogate nodes, rather than those of the referent nodes;
programmer's/debugging option.

{hline}

{title:How to use the tree commands {c -} overview}

{p 4 4 2}
The {cmd:tree} suite of commands is designed to facilitate the creation and evaluation of decision trees.
For a discussion about trees, see {help tree##about_trees:About Trees}, below.
Another benefit is that it can utilize payoff and probability values that you develop
in Stata, Thus, if the payoff and probability value development process is done in Stata
(or if the values can be imported into Stata), then these values can be automatically
conveyed into the tree(s). See {help tree##pract:Practical Considerations}.

{p 4 4 2}
{cmd:tree} is used in several phases and sub-phases:

{p 5 10 2}(1) Construction; defining the shape of the tree or forest:{p_end}
{p 10 10 2}{c 149} Establish the tree (or forest) structure; call {cmd:tree init} (once).{p_end}
{p 10 10 2}{c 149} Establish roots and nodes; call {cmd:tree create} and {cmd:tree node}
(typically many times); you may optionally also call {cmd:tree rptbr}.{p_end}
{p 5 10 2}(2) Populating the payoff and probability values:{p_end}
{p 10 10 2}{c 149} Call {cmd:tree setvals} to populate the payoff values in terminal nodes,
and the probability values in all nodes.{p_end}
{p 5 10 2}(3) Analysis:{p_end}
{p 10 10 2}{c 149} Call {cmd:tree eval} to propagate payoff values toward the roots.{p_end}
{p 10 10 2}{c 149} Call {cmd:tree diffs} to calculate differences in payoff values, or 
{cmd:tree values} to obtain payoff values.{p_end}
{p 10 10 2}{c 149} Optionally, use the results of {cmd:tree diffs} and/or {cmd:tree values} in
your choice of calculations.{p_end}

{title:How to use the tree commands {c -} details}

{p 4 4 2}
{cmd:tree init} initializes the dataset to model a set of decision trees.
The current dataset must be empty prior to calling this; it is called just once
as the first {cmd:tree} command in a tree-analysis session. Subsequently, any other
{cmd:tree} command may be called multiple times.

{p 4 4 2}
As there may be a multitude of trees, {cmd:tree init} actually enables you to
establish a forest.

{p 4 4 2}
You must specify {it:payoffvarlist}, a set of basenames for the payoff variables.
These names are limited to a length of 30, with certain other restrictions;
see {help tree##further_remarks:Further Remarks}.

{p 4 4 2}
As noted above, each name in {it:payoffvarlist}, as well as {cmd:prob}
(provided automatically) will establish two variables:
a string and a numeric variable, which are common to all nodes in all trees. 
More on this below, under{help tree##further_remarks:Further Remarks}.

{p 4 4 2}
{cmd:tree create} will create one or more directed rooted trees.
More accurately, it establishes root nodes, on which you may
subsequently build trees. Thus, "tree" may refer to either a whole tree or just
its root node, depending on the context.

{p 4 4 2}
{it:treenamelist} is a list of names for the trees.

{p 4 4 2}
{cmd:tree create} may be called as many times as you like; each call just adds more roots
on which you may grow trees.
Thus,{p_end}
{p 6 6 2}{cmd:tree create abc xyz}{p_end}
{p 4 4 2}is equivalent to{p_end}
{p 6 6 2}{cmd:tree create abc}{p_end}
{p 6 6 2}{cmd:tree create xyz}{p_end}

{p 4 4 2}
You can create a multitude of trees, or just one, according to your design and preference.
That is, you may be modeling the relative benefits of two courses of action.
Each of these courses may be modeled by a tree, or they may be branches
located on a master tree. You can do it either way. (See {help tree##superroot:Superroot} for more on
this matter.)

{p 4 4 2}
If there are multiple trees, they all share the same set of payoff variables.

{p 4 4 2}
Once one or more trees are established, you can add nodes by using the {cmd:tree node}
command. Typically, you call it multiple times, building up trees from the roots
outward, adding node upon (interior or root) node, and also establishing terminal nodes.
Thus, while the root may be considered as an "entry point" for tracing a path
through an existing directed, rooted tree, it also may be viewed as the "starting point" for
building a tree.

{p 4 4 2}
The first calls to {cmd:tree node} would have just a tree root name in {it:treepath};
later calls would cite a path to an interior node. Thus, for example, you could
code:{p_end}
{p 6 6 2}{cmd:tree init qaly cost}{p_end}
{p 6 6 2}{cmd:tree create a}{p_end}
{p 6 6 2}{cmd:tree node, at(a) int(b c)}{p_end}
{p 6 6 2}{cmd:tree node, at(a b) term(d e)}{p_end}
{p 6 6 2}{cmd:tree node, at(a c) term(f g)}{p_end}

{p 4 4 2}Once an interior node is created, it is allowed to have children;{p_end}
{p 4 4 2}once a terminal node is created, it is prohibited from having children.{p_end}

{p 4 4 2}
Notice that {cmd:tree node} performs two actions:{p_end}
{p 6 6 2}creates one or more new nodes;{p_end}
{p 6 6 2}attaches these nodes to a specified tree or interior node, which becomes the parent of
the new node(s).{p_end}

{p 4 4 2}
Thus, it can attach only new nodes, thereby preventing cycles (directed or non-directed).

{p 4 4 2}
Once the tree structure is established, you can call {cmd:tree setvals} to set the
payoff and probability values. Each payoff variable becomes an option in the syntax
of {cmd:tree setvals}; so is {cmd:prob}. But note that the setting of payoff values
is allowed only in terminal nodes, while {cmd:prob} may be specified in interior
or terminal nodes. Thus, if you have {cmd:cost} and {cmd:qaly}
as payoff variables, then you can specify{p_end}

{p 6 6 2}
{cmd:tree setvals} {it:treepath}{cmd:, cost(}{it:costexp}{cmd:)} {cmd:qaly(}{it:qalyexp}{cmd:)} {cmd:prob(}{it:probexp}{cmd:)}{p_end}

{p 4 4 2}
in a terminal node, but only{p_end}

{p 6 6 2}
{cmd:tree setvals} {it:treepath}{cmd:, prob(}{it:probexp}{cmd:)}{p_end}

{p 4 4 2}
in an interior node.{p_end}

{p 4 4 2}
Also note that the contents of these options are expressions, which are more encompassing
than literal numeric values. Thus, you may specify {cmd:cost(12000*2)}, rather than {cmd:cost(24000)}.
This possiblity can be useful, as will be explained later.

{p 4 4 2}
The contents of these options are stored for later evaluation; they are not evaluated
at the time they are specified, unless you specify the {opt check} option, in which case
they must be valid expressions. Therefore, with the {opt check} option, any references to
data variables, scalars, or global macros must refer to entities that exist at that time, though the
values at that time are irrelevant.

{p 4 4 2}
You can refer to global macros, but you use the {cmd:@} character in place of {cmd:$}. Thus, you may
specify{p_end}
{p 6 6 2}
{cmd:tree setvals} {it:treepath}{cmd:, cost(@cost_lr_mm70)}{p_end}

{p 4 4 2}
assuming that {cmd:cost_lr_mm70} is a global macro containing a number or a numeric expression.

{p 4 4 2}
As the expression is captured and stored, {cmd:@} characters will be converted to {cmd:$}.
Then at {cmd:eval} time, the {cmd:$} will trigger the evaluation of a global macro.
This is done to enable that deferred evaluation. If, instead, you were to specify{p_end}
{p 6 6 2}
{cmd:tree setvals} {it:treepath}{cmd:, cost($cost_lr_mm70)}{p_end}
{p 4 4 2}
then, {cmd:$cost_lr_mm70} would be evaluated at the time that this {cmd:tree setvals} command
is executed, and the resulting value, rather than {cmd:$cost_lr_mm70}, would be stored.
As this would be a constant, this stored expression would not be sensitive to subsequent changes
to the value of the macro {cmd:cost_lr_mm70}.

{p 4 4 2}
In case you need the {cmd:@} to remain as-is, specify the {opt nosub} option.

{p 4 4 2}
There is one special value allowed for {it:probexp}: {cmd:*}. Thus, you may specify
{cmd:prob(*)}. This signifies a residual probability value:{p_end}
{p 8 8 2}1 - (sum of sibling {cmd:prob} values that are not {cmd:*}){p_end}

{p 8 8 2}
If there are multiple instances of {cmd:prob(*)} among a sibling set, then the
residual probability is distributed equally among them.

{p 4 4 2}
{cmd:tree eval} will invoke the evaluation process. Probability expression are evaluated
in all nodes; payoff expression are evaluated in terminal nodes.
Then, for each payoff variable, values are propagated toward the roots by taking, at each
interior node and root, the product of the value and probability in each child, and summing them across all child nodes.
(This can be considered as an inner product, a weighted sum, or an expected value.) This is done iteratively from the terminal
nodes toward the roots.

{p 4 4 2}Optionally, raw sums and means may be generated and
propagated toward the roots. See {help tree##sums_and_means:Raw Sums and Means}.

{p 4 4 2}
After {cmd:tree eval} has been called, you can call {cmd:tree diffs}, which will,
for each payoff variable, take the difference between the numeric values at the two specified nodes,
yielding{p_end}
{p 6 6 2}
(value at {it:treepath1}) - (value at {it:treepath2})

{p 4 4 2}
The results are stored in {help scalar}s named {it:prefbasename}
({it:pref} and {it:basename} are separate entities, but they runtogether, lexically);
The default {it:pref} is {cmd:d_}, yielding {cmd:d_}{it:basename}.
Subsequently, you can refer to these scalars for other calculations.
Thus, with the example of {cmd:cost} and {cmd:qaly}, using the default {it:pref},
you get scalars {cmd:d_cost} and {cmd:d_qaly}.

{p 4 4 2}
{it:pref} must not be longer than 32-(maximal length of payoff basenames).
It is not possible to specify a null {it:pref}.

{p 4 4 2}
{cmd:tree a_minus_b,} is a synonym for {cmd:tree diffs}. It is provided as a convenience,
as the syntax and semantics may be easier to remember.

{p 4 4 2}
Another possibility is to use {cmd:tree values}, which is similar to {cmd:tree diffs}, but it extracts the values of
payoff variables at a single specified node, rather than the differences at a pair
of nodes. Its default {it:pref} is {cmd:v_}.

{p 4 4 2}
For {cmd:tree diffs}, {cmd:tree a_minus_b}, or {cmd:tree values}, any pre-existing
scalars of the name {it:prefbasename} would be overwritten. Therefore, if you use both
{cmd:tree diffs} (or {cmd:a_minus_b}) and {cmd:tree values} in the
same analysis, then the use of distinct {it:pref} values is wise, so as to keep the resulting
scalar names distinct. You might also run alternative analyses on the same setup,
or extract values from a different pair of nodes (or single node),
using distinct {it:pref} values to preserve the results under distinct scalar names.

{p 4 4 2}
The various {cmd:preserve} and {cmd:restore} subcommands will preserve and restore
payoff or probability expressions, or both. These may be used to facilitate
the running of alternative scenarios and sensitivity analyses. 
You might establish a set of probabilities and terminal-node payoff expressions that you
regard as a base-case scenario. After running analyses on this base case, you may
then want to adjust certain probabilities and/or payoff expressions, and rerun
the analysis. (You would rerun {cmd:tree eval}, {cmd:tree diffs}, and any necessary further
calculations.)

{p 4 4 2}
The benefit of the {cmd:preserve} and {cmd:restore} subcommands occurs when you want to run
a multitude of alternative scenarios and sensitivity analyses.
Typically, each such analysis deviates from the base case in a different way, and
you would want to return the values to the base case before making the adjustments
that pertain to the next analysis. For example, if one analysis changes {cmd:cost} (in a
multitude of terminal nodes}, and another analysis changes {cmd:qaly}, then you would
want to return {cmd:cost} to its base-case value before doing the second scenario.
The {cmd:restore} subcommands conveniently take care of this.

{p 4 4 2}
Any of the {cmd:preserve} subcommands ({cmd:tree preserveprob} or {cmd:tree preservepayoff} or {cmd:tree preserveall})
may be issued at any time; they will save the present state of the probability or payoff (or all) expressions.
It is appropriate to do this after the base-case values are established, but before any
adjustments are made for scenario/sensitivity analyses.

{p 4 4 2}
Whether you use {cmd:tree preserveprob} or {cmd:tree preservepayoff} or {cmd:tree preserveall}
would depend on which of the settings (probability or payoff variables or both)
you expect to alter and need to be restored later.

{p 4 4 2}
A corresponding {cmd:restore} subcommand ({cmd:tree restoreprob} or {cmd:tree restorepayoff} or {cmd:tree restoreall})
should be issued prior to making adjustments for a subsequent scenario/sensitivity analysis.

{p 4 4 2}
As noted above, the {cmd:preserve} and {cmd:restore} subcommands have an optional 
{opt chan:nel(#)} option, allowing you to specify which, of possibly many "channels", that the
preserve or restore operation is to use. The channel value may be any integer
from 0 to 99, with 0 being the default. Thus, you may establish a multitude of base cases,
in case that is useful. If you have only one base case, then you can ignore this option.

{p 4 4 2}
The {cmd:preserve} subcommands have a {cmd:replace} option. This is used if you nave already
done a preserve (using the same channel), and want to overwrite the previously-preserved values.

{p 4 4 2}
At any point, you may view the tree structure in a textual representation by calling
{cmd:tree draw}, or in graphic form with {cmd:tree plot}.
See {help tree##draw_and_plot:Draw and Plot} for more on this matter.



{hline}

{marker further_remarks}{title:Further Remarks}

{p 4 4 2}
As noted previously, node types are permanently set when a node is created. This
can potentially create a discrepancy with the graph-theoretic idea of node type,
which is determined by the connectedness of nodes. In this latter sense, any node
with no children is terminal. By contrast, the {cmd:tree} facility allows you to
create interior nodes with no children, which seems like a contradiction from a
theoretical viewpoint. But actually, all interior nodes have no children
when they are first created; you subsequently have the option to attach nodes to
them. However, if an interior node is left with no children, then the
tree may be regarded as incomplete, and may prove to be useless. The result is that,
after {cmd:tree eval}, a value of 0 will occur for all payoff variables at such a node,
and will contribute 0 to the parent node.  More on this at {help tree##misc:Miscellaneous Remarks}.

{p 4 4 2}
The converse situation, a terminal node with children, is impossible to
generate with the {cmd:tree} facility.

{p 4 4 2}
The children of an interior nodes might be...{p_end}
{p 8 8 2}{c 149} all interior;{p_end}
{p 8 8 2}{c 149} all terminal;{p_end}
{p 8 8 2}{c 149} a mixture of interior and terminal.{p_end}

{p 4 4 2}
Whether a mixture of types occurs will depend on the structure of the decision process being modeled.
Probably, most sibling sets are exclusively of one type, but mixtures can occur, in which case the
{cmd:tree node} command would have both the {opt int(intnodenamelist)}
and {opt term(termnodenamelist)} options.

{p 4 4 2}
The child nodes of a particular interior node may be specified in one or a multitude of {cmd:tree node} commands.
Thus,{p_end}
{p 6 6 2}{cmd:tree node, at(a b c d) int(e f g}}{p_end}
{p 4 4 2}is equivalent to the three commands:{p_end}
{p 6 6 2}{cmd:tree node, at(a b c d) int(e)}{p_end}
{p 6 6 2}{cmd:tree node, at(a b c d) int(f)}{p_end}
{p 6 6 2}{cmd:tree node, at(a b c d) int(g}}{p_end}

{p 4 4 2}
That is, each call to {cmd:tree node} for a given location ({opt at(treepath)})
will attach additional child nodes to that location.
You may build up the set of children of a given interior node in stages or all at once, whichever suits you.

{p 4 4 2}
As noted above, the names of the children of a given node must be "locally unique" {c -} unique
within that sibling set, though not necessarily unique over all.
This is similar to filenames in a computer's file system, in which a name is unique
within its directory (aka folder), but not necessarily unique across different directories.
(Typically, the file system in most computer systems is a directed rooted tree,
or possibly a forest, depending on the system. Directories are interior nodes; files
are terminal nodes; the whole system may be one tree with one root, or each storage device is
a root of a tree, depending on the system.)

{p 4 4 2}
Also as noted above, for each payoff variable specified in {it:payoffvarlist}, as well as {cmd:prob},
two Stata variables will be generated: a string (strL) and a
"shadow" double variable. The string variable has the same name as given in {it:payoffvarlist}
(i.e., the basename) (or {cmd:prob}); the double has the same name, but with an {cmd:R_} prefix.
For example, if you specify {cmd:cost} as a payoff variable, then you will have
{cmd:cost} (strL) and {cmd:R_cost} (double). You also automatically get {cmd:R_prob}.
The string variable is for `expressions that you specify in {cmd:tree setvals};
the double variable holds the numeric evaluation of those expressions.
The {cmd:tree eval} command performs the evaluation of the expressions
prior to propagating payoff values toward the roots.

{col 12}{hline}
{p 12 12 12}
{hi:Technical note:}
For payoff variables, the expression variables pertain to terminal nodes only.{p_end}
{col 12}{hline}

{p 4 4 2}
Certain other shadow variables may be generated: {cmd:S_}{it:basename}, {cmd:T_}{it:basename},
and {cmd:M_}{it:basename}, in response to certain options in {cmd:tree eval}.
See {help tree##sums_and_means:Raw Sums and Means}.

{p 4 4 2}
If you invoke {cmd:tree preservepayoff}, then each payoff variable acquires another
shadow variable, {it:basename}{it:channel}, for example, {cmd:cost0}.

{p 4 4 2}
If you invoke {cmd:tree preserveprob}, then you get {cmd:prob}{it:channel},
e.g., {cmd:prob0}.

{p 4 4 2}
Because of these shadow variables, you should not attempt to create a payoff variable with
the base name being the same as another, but with a {cmd:R_} prefix. Thus, for example, you should
not have both {cmd:cost} and {cmd:R_cost}. The same goes for the variant variables
that result from the {opt rawsum} and {opt means} options, for example,
{cmd:S_cost}, {cmd:T_cost}, and {cmd:M_cost}.
See {help tree##sums_and_means:Raw Sums and Means}.

{p 4 4 2}
Similarly, if you plan to use {cmd:tree preservepayoff}, then you 
should not create a payoff variable name that is the same as another, but with a
suffix of your chosen channel number. For example (using the default channel 0), you should not specify both
{cmd:cost} and {cmd:cost0} as payoff variable names. Similarly, if you plan to use {cmd:tree preserveprob},
then you should not create a payoff variable named {cmd:prob0}.

{p 4 4 2}
Payoff variable names are subject to the usual restrictions regarding {help reswords:reserved} names.
Additionally, they must not replicate variables or local macros that are used internally by the
tree program. These mostly start with {cmd:__} or {cmd:setvals_}, which are unlikely
to be chosen by the user; the complete list is{p_end}
{p 6 6 2}
{cmd:__nodename},
{cmd:__nodetype},
{cmd:__branch_head},
{cmd:__branch_tail},
{cmd:__next},
{cmd:__probsum},
{cmd:__n_starprobs},
{cmd:__residprob},
{cmd:__residual},
{cmd:__weight},
{cmd:__n_parents},
{cmd:__ypos},
{cmd:__surr},
{cmd:prob},
{cmd:R_prob},
{cmd:setvals_qui},
{cmd:setvals_node_id},
{cmd:setvals_varstoset},
{cmd:setvals_vval},
{cmd:setvals_vars_affected},
{cmd:verbose},
{cmd:check},
{cmd:sub}.

{p 4 4 2}
What is the advantage of having the payoff and probability values input as {it:expressions}?
There are at least two uses for this.

{p 4 4 2}
1: You can use "global" factors in the specifications, by using {help scalar}s:{p_end}
{p 6 6 2}{cmd:tree setvals} {it:treepath}{cmd:, cost(24000 * scalar(costfactor))}{p_end}
{p 4 4 2}(...and similar expressions for cost in all terminal nodes...}{p_end}
{p 6 6 2}{cmd:scalar costfactor=1}{p_end}
{p 4 4 2}(...run analysis...}{p_end}
{p 6 6 2}{cmd:scalar costfactor=1.1}{p_end}
{p 4 4 2}(...run analysis again...}{p_end}

{p 4 4 2}
This way, you have done an alternative, with cost increased by 10%.
(Note that this does not involve a change to any payoff variable expression, and
there is no need to use a {cmd:preserve} subcommand.)

{p 4 4 2}
Alternatively, this setup could be done using {help global} macros:{p_end}
{p 6 6 2}{cmd:tree setvals} {it:treepath}{cmd:, cost(24000 * @costfactor)}{p_end}
{p 6 6 2}{cmd:global costfactor=1}{p_end}
{p 4 4 2}(...run analysis...}{p_end}
{p 6 6 2}{cmd:global costfactor=1.1}{p_end}
{p 4 4 2}(...run analysis again...}{p_end}

{p 4 4 2}
2: You can have dependency of one variable on another:{p_end}
{p 6 6 2}{cmd:#delimit ;}{p_end}
{p 6 6 2}{cmd:tree setvals tavr_avail low_interm_risk tavr_elig age65_79 tavr lr,}{p_end}
{p 8 8 2}...{p_end}
{p 6 6 2}{cmd:age(70) sal_labor(1315.0) unpaid_work(15341.0) active_leisure(10855.8)}{p_end}
{p 6 6 2}{cmd: valact((R_sal_labor+R_unpaid_work+R_active_leisure) * `wage_cba_70') prob(.471805);}

{p 4 4 2}
There are some things worth noting here.

{p 4 4 2}
{cmd:valact} is a payoff variable. Therefore, it is an option in {cmd:tree setvals}.

{p 4 4 2}
{cmd:wage_cba_70} is a local macro, one of a series of similar macros which have been
defined prior to this command. More on this, below.

{p 4 4 2}
Importantly, references to other payoff variables use the {cmd:R_} versions of these variables:
{cmd:R_sal_labor}, etc. This is because we need a reference to the numeric value,
not the expression (which is a string). (There is a way to invoke the evaluation
of such an expression, but it is more complicated, and would replicate what
{cmd:tree eval} does internally.)

{p 4 4 2}
Finally, and this is not apparent from what was shown here, the referenced variables
({cmd:R_sal_labor}, etc.) come before the variable being evaluated ({cmd:valact}) in
the order as declared in {cmd:tree init}. The reason is that {cmd:tree eval}
evaluates the variables in the order as declared in {cmd:tree init}, and you want each
referenced variable to have been evaluated prior to being referenced. Otherwise, you
get a leftover or unassigned (missing) value, which is probably wrong.

{p 4 4 2}
Therefore, if you plan to have any such dependence of some variables on others, you must
declare them in {cmd:tree init} in an order which conforms to the order of dependency
in the expressions in {cmd:tree setvals}. Consequently, if there are multiple instances
of dependency of some variables on others within any given instance of {cmd:tree setvals},
then all such dependencies must be compatible with the same ordering of variables.
Note, too, that there must be no cycles of dependency,
however, this latter point is implicit in the reliance on a single order of variables.

{p 4 4 2}
Similarly, if such depencencies occur in multiple instances of {cmd:tree setvals},
then they all must conform to the same order of variables as was declared in {cmd:tree init}.

{p 4 4 2}
In this {cmd:tree setvals} example, the expressions for {cmd:sal_labor}, {cmd:unpaid_work}, and {cmd:active_leisure}
appear before that of {cmd:valact}, but that is irrelevant, and could have occured in
any order. What matters is the order in {cmd:tree init}.

{p 4 4 2}
({cmd:R_prob} is evaluated prior to any payoff variables, but you shouldn't have a need to
reference it. For the same reason, the expression for {cmd:prob()} should not reference payoff variables;
you would not get the current value. But again, you shouldn't need to do this.)

{p 4 4 2}
Returning to the local {cmd:wage_cba_70}, we could, aternatively, use a variable:{p_end}
{p 8 8 2}...{p_end}
{p 6 6 2}{cmd: valact((R_sal_labor+R_unpaid_work+R_active_leisure) * wage_cba) prob(.471805);}

{p 4 4 2}
where {cmd:wage_cba} is a numeric variable that gets assigned appropriate values,
presumably dependent on age, in this case.
(If you use the {cmd:check} option, then it must be defined previously, though the
values are not relevant until {cmd:tree eval} is called. One could initially set {cmd:wage_cba}
to missing, prior to this call to {cmd:tree setvals}; then, later replace it with useful
values prior to calling {cmd:tree eval}.)

{p 4 4 2}
Note that, by having {cmd:wage_cba} be a variable,
you can adjust it and rerun the analysis to implement alternative scenarios.
(Or it could be a global macro or scalar, but then there ought to be a multitude of them,
corresponding to different ages.)

{p 4 4 2}
As noted, the {cmd:tree diffs} command generates scalars named {cmd:d_}{it:basename}
(or generally, {it:prefbasename}).
Some of these scalars may be of direct interest for analysis,
or they may be useful in further calculations, but that is for the user to work out.
One commonly used calculation is an icer (Incremental Cost-Effectiveness Ratio):{p_end}
{p 6 6 2}scalar(d_cost)/scalar(d_qaly)


{hline}

{marker draw_and_plot}{title:Draw and Plot}

{p 4 4 2}
There are two methods for producing a visual image of the trees:
{cmd:tree draw} and {cmd:tree plot}.

{p 6 6 2}
{cmd:tree draw} produces a represenatation of the trees by displaying textual
characters in the results window, using connecting lines and indentation to
indicate the hirearchical relations; this is similar to the output of the
{cmd:tree} command in the Windows command prompt.

{p 6 6 2}
{cmd:tree plot} will draw an image using Stata graphics capabilities.

{p 4 4 2}
{cmd:tree draw} is the faster of the two, and it may be a better choice for
viewing values of selected variables. {cmd:tree plot} may provide a 
more natural image of the tree.

{p 4 4 2}
For both {cmd:tree draw} and {cmd:tree plot}, {it:varlist} specifies variables
to be displayed in the drawing or plot. But be aware that the resulting image
can become crowded if too many variables are specified.

{p 4 4 2}
{cmd:tree draw} will display one line for each node.
Integer numerals will be displayed on the left side; these are the Stata observation numbers,
or "node numbers", which may be helpful in diagnosing data problems that may arise.

{p 4 4 2}
{cmd:tree plot} can also display the node numbers, but this feature is turned off
by default. Use the {opt numbers} option to turn this on; numbers will appear
before the node name, 

{p 6 6 2}
For both {cmd:draw} and {cmd:plot}, the node numbers will not necessarily
appear in sequential order.
Instead, the order diplayed reflects the tree structure, whereas the node (observation)
numbers reflect the order in which the tree was built {c -} the order in which nodes
were added during the construction phase.

{p 6 6 2}
You can use the node number to {help list} a given observation, though {cmd:tree draw} can give you the
same information. You can also use it to index a variable to retrieve
a value from a specific observation, though {cmd:tree values} can also do that.

{p 4 4 2}
In {cmd:tree draw}, terminal nodes are marked with an asterisk to the right of the node name.
rlink nodes are marked with two asterisks; the rptbr nodes that they link to
are marked with three asterisks.

{p 4 4 2}
In {cmd:tree plot}, terminal nodes appear as left-facing triangles.
rlink nodes appear as blue circles; the rptbr nodes that they link to appear as
light blue diamonds.

{p 4 4 2}
With {cmd:tree plot}, values of {it:varlist} variables will appear below and to the
left of the node symbol for most nodes; for terminal nodes, they appear to the right.

{p 4 4 2}
For both {cmd:draw} and {cmd:plot}, rptbr nodes appear as often as they are linked.
That is, a given rptbr node may appear multiple times; they will be labeled with the
same name and they represent the same node, appearing more than once. (Actually, they
are surrogate nodes, but you don't need to know that.)

{p 4 4 2}
But the branches that emanate from rptbr nodes are not shown directly in the drawing
or plot. Instead,...

{p 6 6 2}
For {cmd:tree draw}, they are shown separately, below the regular trees.

{p 6 6 2}
For {cmd:tree plot}, they are displayed when you use the 
{opt rptbr} option, in which case they are displayed instead of the regular
trees.

{p 4 4 2}
{cmd:tree plot} produces a Stata graph, which can be printed using the Print
option in the Graph window (File-Print, or Ctrl+P).

{p 4 4 2}
To produce this graph, {cmd:tree plot} creates a do-file containing Stata graphing commands,
which is subsequently executed (via {cmd:do}).
By default, this is a {help tempfile}; it is deleted after is is executed.
With the {opt dosave(dofilename)} option, you can, instead, save the file,
which can be executed at a later time.

{p 4 4 2}
You can also use the {opt gphsav:ing(gphfilename)} option, which saves the
graph as a {cmd:.gph} file, which can be subsequently reinvoked using {help graph use}.

{p 4 4 2}
For {cmd:tree draw}, you can {help log} the output, which you can subsequently
{help print}.

{p 4 4 2}
For {cmd:tree plot}, the {opt base:names} option restores the Version-1 treatment
of {it:varlist}. Under this option, the variables of {it:varlist}
are taken as (required to be) basenames of payoff variables, and the {cmd:R_} versions are substituted.
For example, if you specify{p_end}
{p 6 6 2}
{cmd:tree plot cost, basenames}{p_end}
{p 4 4 2}
then the values of {cmd:R_cost} are displayed, assuming that {cmd:cost} is a payoff
variable.

{p 4 4 2}
Without this option, any variable is permitted and taken as-is. Thus,{p_end}
{p 6 6 2}
{cmd:tree plot cost}{p_end}
{p 4 4 2}
will display {cmd:cost} {c -} the payoff variable.

{p 4 4 2}
This is done for consistency with the action of {cmd:tree draw}.


{hline}

{marker sums_and_means}{title:Raw Sums and Means}

{p 4 4 2}
{cmd:tree eval} can also calculate raw sums and means. This may be useful when modeling
hierarchical relationships.

{p 4 4 2}
The {opt rawsum(rawsumvars)} option allows you to specify payoff variables for which
you want raw sums to be propagated toward the roots. That is, at each interior node,
the sum of the values at the children is calculated. These values are carried in
variables named {cmd:S_}{it:basename}, for example, {cmd:S_cost}.

{p 4 4 2}
The {opt mean:s(meansvars)} option allows you to specify payoff variables for which
you want means to be propagated toward the roots. That is, at each interior node,
the mean of the values at the children is calculated. This calculation is weighted
by the {help weight} feature, which accepts {cmd:iweight}s. The default weight is 1.
Thus, in the absence of a weight specification, the weight is the
count of terminal nodes that lie beyond the given node (in the subtree rooted at
the given node). See additional notes at {help tree##misc:Miscellaneous Remarks}.

{p 4 4 2}
A variable named {cmd:__weight} is created (actually, it is present at all times,
not just when specifying a weighted mean). The weight expression may refer to {cmd:R_} variables,
since these values are calculated prior to computing {cmd:__weight}.
{cmd:__weight} is calculated in the terminal nodes and summed back to the roots. (That is, references to
{cmd:R_} variables are evaluated only in the terminal nodes. At an interior node, the
weight is the sum of weights in descendant nodes {c -} not based on the "local" values
of {cmd:R_} variables.)

{p 4 4 2}
If {opt mean:s(meansvars)} is specified, then these variables are created:{p_end}
{p 6 6 2}{cmd:T_}{it:basename} {c -} the weighted sum of {it:basename}{p_end}
{p 6 6 2}{cmd:M_}{it:basename} {c -} the weighted mean of {it:basename}{p_end}
{p 4 4 2}For example, {cmd:T_cost} and {cmd:M_cost}.

{p 4 4 2}
The {opt mean:s(meansvars)} option is the only action that is affected by the
weight feature.

{p 4 4 2}
In the absence of a weight specification (or with {cmd:[weight=1]}), {cmd:T_}{it:basename}={cmd:S_}{it:basename}
if both the {opt means} and {opt rawsum} options are specified for the same payoff
variable(s).

{p 4 4 2}
The default behavior is that, any variables that result from earlier invocations of
{cmd:tree eval} with the {opt rawsum} or {opt means} options (that is, {cmd:S_}{it:basename},
{cmd:T_}{it:basename}, or {cmd:M_}{it:basename}), such that the basenames
are not specified in the present invocation, will be dropped.

{p 4 4 2}
With the {opt retain} option, such variables are retained.

{p 4 4 2}
These rules apply, regardless
of whether {opt rawsum} or {opt means} was specified. (The option(s) might be absent,
or might be present, but not mentioning the variable basename(s) in question.)

{p 4 4 2}
When such variables are retained, they hold values that may or may not differ from
what they would have been, had you included their basenames in
{opt rawsum} or {opt means} options {c -} that is, had they been recalculated in
the latest invocation of {cmd:tree eval}. This depends on whether the relevant input
values have changed since their original calculation. So it is the user's resposibility
to be aware and keep track of these effects.

{p 4 4 2}
When such variables are retained, {help notes} are attached to the pertinent variables,
warning of this potential discrepancy. The text reads{p_end}
{p 6 6 2}retains value from earlier eval step{p_end}

{p 4 4 2}
Additional instances of this note will be attached for each
relevant invocation of {cmd:tree eval}. Thus, of example, if 
this note appears three times for {cmd:S_cost}, then the retained values came from
the third prior invocation of {cmd:tree eval}.

{p 4 4 2}
These notes are removed whenever the given variable is recalculated, that is
whenever the basename is mentioned in {opt rawsum} or {opt means} options in {cmd:tree eval}.

{p 4 4 2}
To illustrate the capability of modeling hierarchical relationships, we will show how to
constuct a tree of the states and counties of the US. We will include two payoff variables,
pop (population) and pcinc (per-capita income).

{p 6 6 2}{cmd:tree init pop pcinc}{p_end}
{p 6 6 2}{cmd:tree create usa}{p_end}
{p 6 6 2}{cmd:tree node, at(usa) int(al ak az ar ca co ct de)}{p_end}
{p 4 4 2}etc., for all the states of the US.

{p 4 4 2}
(We used the postal abbreviations for the states)

{p 6 6 2}{cmd:tree node, at(usa al) term(jefferson montgomery chilton bibb morgan calhoun autauga)}{p_end}
{p 4 4 2}etc., for all the counties in Alabama, then for Alaska, etc..

{p 6 6 2}{cmd:tree setvals usa al jefferson, pop(660) pcinc(20892)}{p_end}
{p 6 6 2}{cmd:tree setvals usa al montgomery, pop(230) pcinc(19385)}{p_end}
{p 6 6 2}{cmd:tree setvals usa al chilton, pop(44) pcinc(15303)}{p_end}
{p 6 6 2}{cmd:tree setvals usa al bibb, pop(23) pcinc(19918)}{p_end}
{p 6 6 2}{cmd:tree setvals usa al morgan, pop(120) pcinc(19223)}{p_end}
{p 6 6 2}{cmd:tree setvals usa al calhoun, pop(120) pcinc(20574)}{p_end}
{p 6 6 2}{cmd:tree setvals usa al autauga, pop(55) pcinc(24571)}{p_end}

{p 4 4 2}etc., for all the counties in Alabama, and then for Alaska, and
so forth.

{p 4 4 2}(For convenience pop is entered in thousands.)

{p 4 4 2}You can then do...{p_end}
{p 6 6 2}{cmd:tree eval [w=R_pop], mean(pcinc) rawsum(pop)}{p_end}

{p 4 4 2}which will calculate the summed pop values and the mean pcinc, propagated
toward the roots, that is, the states and the whole US.

{p 4 4 2}(Many warning messages appear because no {cmd:prob} values were set, but we are not
concerned with that in this case.)

{p 4 4 2}At this point, you can type{p_end}
{p 6 6 2}{cmd:tree draw pop pcinc S_pop M_pcinc}{p_end}

{p 4 4 2}which will show S_pop (summed population) and M_pcinc (mean per-capita income)
in each state and the whole US, in addition to the counties. This is assuming that we had
completed the tree and entered all the pop and pcinc values for all the counties of the US.

{p 4 4 2}Note that, in this case, the {cmd:tree eval} command has a weight factor and a rawsum
variable that are the same: pop. Consequently, we get __weight = S_pop.

{p 4 4 2}
The foregoing example started with the creation of a "main" tree named {cmd:usa},
with the states as children of {cmd:usa}.
Another possibility is to set all the states as trees.
The construction would go like this:

{p 6 6 2}{cmd:tree init pop pcinc}{p_end}
{p 6 6 2}{cmd:tree create al ak az ar ca co ct de}{p_end}
{p 4 4 2}etc.. 

{p 6 6 2}{cmd:tree node, at(al) term(jefferson montgomery chilton bibb morgan calhoun autauga)}{p_end}
{p 4 4 2}etc.. 

{p 6 6 2}{cmd:tree setvals al jefferson, pop(660) pcinc(20892)}{p_end}
{p 6 6 2}{cmd:tree setvals al montgomery, pop(230) pcinc(19385)}{p_end}
{p 6 6 2}{cmd:tree setvals al chilton, pop(44) pcinc(15303)}{p_end}
{p 6 6 2}{cmd:tree setvals al bibb, pop(23) pcinc(19918)}{p_end}
{p 6 6 2}{cmd:tree setvals al morgan, pop(120) pcinc(19223)}{p_end}
{p 6 6 2}{cmd:tree setvals al calhoun, pop(120) pcinc(20574)}{p_end}
{p 6 6 2}{cmd:tree setvals al autauga, pop(55) pcinc(24571)}{p_end}
{p 4 4 2}etc.. 

{p 4 4 2}The {cmd:tree eval} command would be unchanged.

{p 4 4 2}Note that {cmd:superroot} (see below) would take the place of the {cmd:usa} tree.
That needs to be accounted for in any instances of {cmd:tree values} or {cmd:tree diffs}.

{p 4 4 2}
The data contained in this structure (either version) could also be configured in
a more traditional Stata manner, with state identifier values repeated. And results
could be effected by the use of {help egen} or {help collapse} commands.
But you may find it intuitive to use this tree-based approach, as it eliminates the
repitition of state identifier values.

{p 4 4 2}
(Another approach would be to split the state and county level data into separate but linked frames.
That still retains the repitition of state identifier values in the county table.)

{hline}

{marker superroot}{title:Superroot}

{p 4 4 2}
The trees are implemented as branches on (children of) a single master node, named superroot,
which is the parent of all trees in the whole forest.

{p 4 4 2}
Every treepath implicitly starts with {cmd:superroot}, which you may optionally include
when specifying a treepath. Thus,{p_end}
{p 6 6 2}{cmd:tree node, at(a b) term(d e)}{p_end}
{p 4 4 2}may, alternatively, be written as{p_end}
{p 6 6 2}{cmd:tree node, at(superroot a b) term(d e)}{p_end}

{p 4 4 2}
The treepath {cmd:superroot} (alone) refers to this node, however there is a restriction
on how you may use it: you may not attach nodes to {cmd:superroot} using {cmd:tree node};
only {cmd:tree create} does that, and it only attaches (new) tree roots.

{p 4 4 2}You have the option to set {cmd:prob} in the tree roots. If you do so, then
{cmd:tree eval} will bring values back to the superroot. Thus, for example, if you code{p_end}
{p 6 6 2}{cmd:tree setvals, at(x) prob(.25)}{p_end}
{p 6 6 2}{cmd:tree setvals, at(y) prob(*)}{p_end}

{p 4 4 2}
and if {cmd:x} and {cmd:y} are all the roots of the forest, then, {cmd:tree eval}
will bring payoff values into superroot. You may then refer to them in
{cmd:tree values}:{p_end}
{p 6 6 2}{cmd:tree values, at(superroot)}

{p 4 4 2}
This may be useful if the forest constitutes a meaningful whole entity, and you
can provide meaningful {cmd:prob} values for the trees. The same effect may be obtained
by placing all these "trees" as branches on a user-defined top-level tree.

{p 4 4 2}
You may also refer to superroot in {cmd:tree diffs}, however, this is an unlikely
situation.

{p 4 4 2}
Note that it is possible to set prob at superoot:{p_end}
{p 6 6 2}{cmd:tree setvals, at(superroot) prob(.25)}{p_end}
{p 4 4 2}
however, this has no effect on a {cmd:tree eval} operation, and is therefore useless.

{p 4 4 2}
Note that the superroot is a feature of the {cmd:tree} program, and is not
generally included in the subject of topological trees.

{hline}

{marker rptbr}{title:Repeatable Branches}

{p 4 4 2}
Repeatable branches, introduced in Version 2.0, is a feature that may simplify the
construction and setvals operations in certain situations. It may also make the
{cmd: tree eval} operation more efficient, though the gain may be imperceptible
in most cases.

{p 4 4 2}
The use of repeatable branches is optional; you can get along
without them, even in situations where they would be appropriate. 
But they offer an advantage in applicable situations.

{p 4 4 2}
Repeatable branches can be used when the tree (or forest) contains a multitude of same-shaped branches.
In order to be considered as a repeatable branch, every instance of the branch
must have the same structure, as well as the same
payoff values (in terminal nodes) and prob values.

{p 4 4 2}
A repeatable branch is specified and stored once, instead of multiple times.
You can then refer to it (via an {cmd:rlink} node) in multiple locations in the tree or forest.
Each reference to the repeatable branch
serves as a virtual copy of the repeatable branch, but it really exists just once..
This takes the place of declaring a multitude of same-shaped branches,
thereby eliminating redundant code (in both the construction ({cmd:tree node})
and the {cmd:tree setvals} operations);
it will also eliminate redundant calculation in the {cmd:tree eval} process

{col 12}{hline}
{p 12 12 12}
With repeatable branches, the graph structure is a DAG. However, the use of 
rlink nodes enables us to maintain the one-to-one correspondence of
links and relevant (rlink) nodes. Therefore, it still valid to store prob values 
with the child nodes.{p_end}
{col 12}{hline}

{p 4 4 2}
To create a repeatable branch, use the {cmd:tree rptbr} command. For example,{p_end}
{p 6 6 2}
{cmd:tree rptbr disease_outcomes}

{p 4 4 2}
You then build a repeatable branch as you would for any regular tree, but you
refer to the {it:treepath} with {cmd:rptbr} as the initial element:{p_end}
{p 6 6 2}
{cmd:tree node rptbr disease_outcomes, term(recovery st_disab lt_disab death)}

{p 4 4 2}
Then, you can populate the payoff variables and {cmd:prob} with {cmd:tree setvals}:{p_end}
{p 6 6 2}
{cmd:tree setvals rptbr disease_outcomes recovery, cost(1600) prob(.65)}{p_end}
{p 6 6 2}
{cmd:tree setvals rptbr disease_outcomes st_disab, cost(22000) prob(.15)}{p_end}
{p 6 6 2}
{cmd:tree setvals rptbr disease_outcomes lt_disab, cost(36000) prob(.1)}{p_end}
{p 6 6 2}
{cmd:tree setvals rptbr disease_outcomes death, cost(2000) prob(*)}{p_end}

{p 4 4 2}
For the {cmd:tree node} and {cmd:tree setvals} commands, 
it may seem as if {cmd:rptbr} is part of the syntax, and you may think of it that way,
but it is actually the leading name in {it:treepath}. That is, to refer to any
node in a repeatable branch, {it:treepath} starts with {cmd:rptbr}, followed by
the root name of the repeatable branch.

{p 4 4 2}
To place a reference to the branch, you first specify an {cmd:rlink} node in a
{cmd:tree node} command. For example,{p_end}
{p 6 6 2}
{cmd:tree node treatment_avail age_ge60, rlink(untreated)}{p_end}
{p 6 6 2}
{cmd:tree node treatment_avail age_ge60, rlink(treated)}{p_end}

{p 6 6 2}
(We suppose that we have already established a tree named {cmd:treatment_avail}
with a child interior node {cmd:age_ge60}.)

{p 4 4 2}
The forefoing commands specify only that{p_end}
{p 6 6 2}
{cmd:treatment_avail age_ge60 untreated}{p_end}
{p 4 4 2}and{p_end}
{p 6 6 2}
{cmd:treatment_avail age_ge60 treated}{p_end}
{p 4 4 2}are rlink nodes; it does not connect them to any particlar repeatable branch.
To make that connection, you use the {cmd:tree rlink} command, with the {cmd:to}
option.{p_end}

{p 6 6 2}
{cmd:tree rlink treatment_avail age_ge60 untreated, to(disease_outcomes)}{p_end}
{p 6 6 2}
{cmd:tree rlink treatment_avail age_ge60 treated, to(disease_outcomes)}{p_end}

{p 4 4 2}
Once this is established, the branch of {cmd:disease_outcomes} is attached as
a child of both of those rlink nodes.

{p 4 4 2}
Given that structure and linkage, you may notice that there can be more than one way to refer
to a particular node in a repeatable branch: directly via a 
{it:treepath} starting with {cmd:rptbr}, or indirectly through an rlink node.
Thus, in our example, we might have{p_end}
{p 6 6 2}
{cmd:rptbr disease_outcomes recovery}{p_end}
{p 6 6 2}
{cmd:treatment_avail age_ge60 untreated recovery}{p_end}
{p 6 6 2}
{cmd:treatment_avail age_ge60 treated recovery}{p_end}
{p 4 4 2}
all as equivalent; the first is direct; the others are indirect references.

{p 4 4 2}
Because of this possibility of aliases for some nodes, and the potential confusion
that may ensue, commands that
alter data ({cmd:tree node}, {cmd:tree setvals}, {cmd:tree rlink}) allow only
a direct reference.

{hline}

{marker pract}{title:Practical considerations}

{p 4 4 2}
You may have a process that generates some of the input values for the tree(s):
payoff values in terminal nodes and/or probability values. You will need a way to
perform that process and then transfer the results into the tree(s); presumably, that
process will yield its output in scalars or global macros.

{p 4 4 2}
If this process involves calculations on Stata data, then you will need to switch
that dataset out; then bring in, or construct, the tree(s).

{p 4 4 2}
If you need to run that process just once, then you can...{p_end}
{p 6 8 2}{c 149} run the input-generation process, yielding scalars or global macros;
presumably, this involves the use of other data;{p_end}
{p 6 8 2}{c 149} {help clear} the dataset;{p_end}
{p 6 8 2}{c 149} constuct the tree(s), populate the payoff variables with references to
the scalars or global macros, and run the {cmd:tree eval} and analysis steps.{p_end}

{p 4 4 2}
If you use scalars as the means for carrying values fromn the input-generation process
to the trees, then the {cmd:clear} step should not be {cmd:clear all} or {cmd:clear *}.
Similarly, do not type {cmd:scalar drop _all}. Any of these commands will drop all scalars.

{p 4 4 2}
Since the trees exist in a Stata dataset, you can constuct the tree(s) in advance,
and {help save} it. Then, your procedure would be...{p_end}
{p 6 8 2}{c 149} construct the tree dataset, including {cmd:tree setvals} to populate the
expressions for payoff variables and {cmd:prob}, with references to scalars or global macros;{p_end}
{p 6 8 2}{c 149} {cmd:save} the dataset;{p_end}
{p 6 8 2}{c 149} run the input-generation process, yielding scalars or global macros;{p_end}
{p 6 8 2}{c 149} {cmd:clear};{p_end}
{p 6 8 2}{c 149} {help use} the tree dataset and run the {cmd:tree eval} and analysis steps.{p_end}

{p 4 4 2}
If you intend to repeatedly run the input-generation process, say, with varying input parameter
values, then you would definitely want to constuct the tree(s) in advance. Each iteration
would repeat the final three steps shown above. A {help program} could be created to
perform these steps.

{p 4 4 2}
As this involves switching back and forth between different datasets, an natural technique
might be to use {help frames}, switching between frames, rather than swapping datasets in and out.
{cmd:frames} is available in Stata 16 and higher. The author has tried this technique
with some success.

{p 4 4 2}
Some other possibilities for transferring values from the input-generation process
may include...{p_end}

{p 6 6 2}
{c 149} Use {help return}ed results. (One likely option is {cmd:sreturn}, but note that
{cmd:tree} uses the {cmd:sreturn} name node_id, so you should avoid using that name.)

{p 6 6 2}
{c 149} Write the input-generation process in {help mata}.

{p 6 6 2}
{c 149} Write the input-generation process in Python. {help python:Python Integration} is
available in Stata 16 and higher.

{p 4 4 2}
Presumably, the latter two options could obviate the need to swap the tree dataset
out and back in. But note that the author has not yet tried these techniques.

{hline}

{marker data_compatibility}{title:Data Compatibility}

{p 4 4 2}
As of Version 2, with the introduction of Repeatable Branches, there has been a
change in the data format. This should have no impact on your work if you are
rerunning legacy Version 1 {cmd:tree} commands that begin with the construction
phase. However,
if you {help use} a tree dataset that was created and {help save}d under Version 1, many of the
Version 2 tree commands will not work. Thus, it is best to start over from the 
beginning phase, and reconstruct the tree dataset.

{p 4 4 2}
Note that it is possible to go in the other direction, with one constraint.
It is possible for Version 1 to use a tree dataset that was created by Version 2,
as long as it contains no repeatable branches.

{hline}

{marker about_trees}{title:About trees}

{p 4 4 2}
A tree, in the mathematical sense, is topological {ul:graph} that is {ul:connected} and {ul:acyclic}.
A graph is a set of nodes (or vertices), together with a set of {it:links}, which are pairs of these same nodes.
Thus, a link, also known as an edge, serves to connect a pair of nodes.
The node set is typically taken to be finite, though infinite graphs can be considered;
they constitute a special topic,
with special considerations, and are not pertinent to the present discussion.
For more info, see 
{browse "https://en.wikipedia.org/wiki/Graph_theory":the Wikipedia article on Graph Theory}.

{p 4 4 2}
An important feature is that one may construct a sequence of nodes
in which each consecutive pair of nodes has a link joining them.
Call this a {ul:connected path} (often just called a "path" if the meaning
is clear). A link connects "neighboring" (or "adjacent") nodes; a connected path
of more than one link connects a more distant pair of nodes.
We often consider a connected path as corresponding to a process of {ul:visiting}
the nodes in the specified sequence.

{p 4 4 2}
Note that a connected path has a corresponding sequence of
links, in which each consecutive pair of links shares a common node.
So you can think of a connected path as either a sequence of nodes or a sequence
of links.

{p 4 4 2}
We allow at most one link between any given pair of nodes.
(Actually, this is implicit if you regard the links as a {it:set}
of pairs of nodes.) The {ul:connected} property states that
there is a connected path joining any two
distinct nodes. The {ul:acyclic} property states that, as you follow a connected path,
without backtracking, you never
return to a node that was visited previously. This implies...{p_end}
{p 6 6 2}{c 149} there is never a link from a node directly to itself;{p_end}
{p 6 6 2}{c 149} the connected path from one node to another is unique;{p_end}
{p 6 6 2}{c 149} there is at most one link between any given pair of nodes.

{p 4 4 2}
The trees that are managed by the {cmd:tree} commands have some additional properties:
they are {it:directed} and {it:rooted}.

{p 8 8 2}
{ul:Directed}: the links have direction; they are {it:ordered} pairs of nodes.
Every link is {it:from} one node {it:to} another node. Thus, we may speak of following
a link in the forward direction, or the reverse direction.

{p 8 8 2}
{ul:Rooted}: there is a unique distinguished node, known as the root, having the property
that there is a directed path (explained below) from the root to any other node.
More on this later.

{p 4 4 2}
If there is a directed link from node {cmd:A} to node {cmd:B}, then we say that 
{cmd:A} is a parent of {cmd:B}, and {cmd:B} is a child of {cmd:A}.
A node may have multiple children; the children
of a node constitute a set of siblings. (Whether a node may
have multiple parents is not determined by just the directed and acyclic properties;
we will return to this soon.) The children of a node, and the children of the children
(etc...) are called descendants.

{p 4 4 2}
Some nodes may have no children; they are {it:terminal} nodes; all others are
{it:interior} or {it:non-terminal}. (The root can be considered as its own category,
or it may be regarded as interior, since it usually has children. One might consider
a tree that has only one node, which would be both the root and a terminal node. This
is a degenerate case, which we will ignore.)

{p 4 4 2}
In a directed tree, we may consider a {it:directed path}, a connected path
in which every link proceeds in the forward direction.

{p 4 4 2}
For directed trees, we must clarify that the {ul:acyclic} property
is to be interpreted in the non-directed sense {c -} in the underlying undirected graph.
There is another, related structure
known as a Directed Acyclic Graph (DAG), in which the acyclic property is interpreted
in the directed sense; a directed path never returns to a previously visited node.
A directed tree is more restrictive than a DAG. That is, every directed tree is a DAG;
not every DAG is a directed tree. A DAG may have a node that is the child of more than
one parent; multiple links converge on the same node. That situation is not allowed in a directed tree.

{p 4 4 2}
The {ul:rooted} property states that the tree has a unique "entry point".
This designated node, the root, has no parents, and it is the {it:only} node to not
have any parents; all other nodes have at least one parent. (Actually, they have exactly one parent,
but that's a consequence of other properties, as we will soon see.)

{p 4 4 2}
As noted, a directed tree is more restrictive than a DAG.
When you combine the {ul:directed}, {ul:acyclic}, and {ul:rooted} properties, one result is that
you never can have multiple edges converging to one node; a DAG may have such
edges. Thus, in a directed rooted tree, all non-root nodes have exactly one parent.
(In other words, the inverse of the directed link relation is a function.)

{p 4 4 2}
Since all non-root nodes have exactly one parent, then from any node, there is a unique
chain of parent nodes, a reverse route through a directed path, which must ultimately
end at the root. If you trace this path in the forward direction, you get a path from
the root to the given node. Since the graph is acyclic, this path is unique.

{p 4 4 2}
A forward-moving trip through the nodes presents you, at each interior node,
with a choice of which of possibly many children to go to;
these are the decisions that are modeled {c -} the junctures in the decision process.

{p 4 4 2}
A directed rooted tree can model a hierarchy, though this may or may not be
relevant to a decision process. Also, a directed rooted tree  
can be defined recursively: A directed rooted tree is either a terminal node or a node that
has children, where each child is a directed rooted tree.

{p 4 4 2}
A possibly multitudinous set of trees is called a forest. Within a forest, the trees
can be viewed as the connected components.

{p 4 4 2}
Terminal nodes are so-called because every directed path must eventially come to
one such node, and can go no further.

{p 4 4 2}
For further reading on trees, see
{browse "https://en.wikipedia.org/wiki/Tree_(graph_theory)":the Wikipedia article on trees}.

{hline}

{marker misc}{title:Miscellaneous Remarks}

{p 4 4 2}
In {cmd:tree eval}, the evaluation of {cmd:R_}{it:basename} occurs for all payoff variables
every time {cmd:tree eval} is invoked, but {cmd:S_}{it:basename}, {cmd:T_}{it:basename},
and {cmd:M_}{it:basename} are evaluated only when {opt rawsum} or {opt means} are
specified, and only for the specified payoff variables.

{p 4 4 2}
In {cmd:tree eval}, if a given payoff variable basename appears in both the
{opt rawsum} and {opt means} options, and the weight factor is 1 or absent, then 
{cmd:T_}{it:basename} = {cmd:S_}{it:basename}.

{p 4 4 2}
The {cmd:tree eval} with the {opt means} option propagates the weights all the way
back to the roots. That is, the weight at an interior node is the sum of all weights
in the descendant terminal nodes. If you use a weight factor of 1 (or any non-zero constant),
then, the weight at any interior node is proportional to the number of descendant terminal nodes.
If the weight factor is 1 (or any non-zero constant), then,...{p_end}
{p 6 6 2}{c 149} if a node has terminal nodes as its only children, then the resulting means at that
node are the simple (evenly weighted) means of the child values;{p_end}
{p 6 6 2}{c 149} otherwise, the resulting means at that
node are not necessarily the simple means of the child values;{p_end}
{p 4 4 2}There is presently no provision for computing a simple mean at each interior node.

{p 4 4 2}
Be sure that the scalars generated by {cmd:tree diffs} or {cmd:tree values}
do not conflict with scalars that you reference in {cmd:tree setvals}.

{p 4 4 2}
Scalars persist; they stay around until explicitly dropped. Thus, when you reference a scalar,
either as input in {cmd:tree setvals} or output from {cmd:tree values} or {cmd:tree diffs},
be sure that the value is from the desired instance in which the scalar was set. 

{p 4 4 2}
In the expressions in {cmd:tree setvals}, if you type {cmd:\@}, it will be interpreted
as {cmd:\$} but that {cmd:\} will block the dereferencing of the global macro at eval time.
There is probably no need to use such a construct, but be warned that the appearance
of {cmd:\} in such expressions may have undesired consequences, which the author makes
no claims about.

{p 4 4 2}
If a payoff variable has not yet been given a value in a terminal node, the result will be
a missing value in {cmd:R_}{it:basename}. The same goes for {cmd:R_prob} in any node.
Of course, you could also have an expression that evaluates to a missing value.
A missing value, for whatever reason, in {cmd:R_}{it:basename} will propagate to {cmd:S_}{it:basename},
{cmd:T_}{it:basename} and {cmd:M_}{it:basename} if {opt rawsum} or {opt means} is
specified on the variable in question.

{p 4 4 2}
If a missing value occurs in a {cmd:R_}{it:basename} in a terminal node, or in {cmd:R_prob}
at any node, then a missing value will be propagated in {cmd:R_}{it:basename} back
to the root. That is, a missing value infects all nodes going back to the root.

{p 4 4 2}
This same effect occurs for {cmd:S_}{it:basename} and {cmd:T_}{it:basename}
where appropriate, except that
{cmd:R_prob} does not affect this situation; instead, {cmd:__weight} affects
{cmd:T_}{it:basename} (in terminal nodes). Also, since {cmd:__weight} is
summed back to the roots, it, too, can propagate missing values back to the roots.
(But omitting the weight factor in {cmd:tree eval} command (with {opt means}) does not generate
missing values in {cmd:__weight}; instead, it defaults to 1.)

{p 4 4 2}
On the other hand, and as noted elsewhere, an interior node with no children will
have {cmd:R_}{it:basename} evaluate to 0; the same holds for {cmd:S_}{it:basename} and {cmd:T_}{it:basename},
as well as {cmd:__weight}, where appropriate. Note that{p_end}
{p 6 6 2}{cmd:M_}{it:basename} = {cmd:T_}{it:basename} / {cmd:__weight},{p_end}
{p 4 4 2}which will yield a missing value in {cmd:M_}{it:basename} if {cmd:__weight}=0
or if {cmd:T_}{it:basename} is missing.

{p 4 4 2}
In {cmd:tree setvals}: you can't clear an expression value. But you shouldn't need to.

{p 4 4 2}
There is no capability to change a node type. Again, you shouldn't need to.
But you will likely do the tree construction using a {help do}-file. This way, if
you decide to change the structure, you can edit the do-file, then {help clear}
and rerun the file.

{p 4 4 2}
Do not sort the tree data; do not delete or insert observations. The {cmd:tree}
facility depends heavily on each observation remaining it its original location.

{p 4 4 2}
Similarly, do not alter any of the internal variables.

{p 4 4 2}
Some commands have a debug option; not documented.

{hline}

{title:Acknowledgement}

{p 4 4 2}
The author is grateful to Jessica Klusty of Data for Decisions, for assistance in designing
the syntax and actions of this suite of programs.

{title:Author}

{p 4 4 2}
David Kantor.  Email {browse "mailto:kantor.d@att.net":kantor.d@att.net} if you observe any
problems.
