{smcl}
{* *! version 1.0.0  2026-07-15}{...}
{viewerjumpto "Syntax" "reshapehelper##syntax"}{...}
{viewerjumpto "Description" "reshapehelper##description"}{...}
{viewerjumpto "What you get back" "reshapehelper##output"}{...}
{viewerjumpto "Options" "reshapehelper##options"}{...}
{viewerjumpto "Examples" "reshapehelper##examples"}{...}
{viewerjumpto "Stored results" "reshapehelper##results"}{...}
{viewerjumpto "Remarks" "reshapehelper##remarks"}{...}
{viewerjumpto "Author" "reshapehelper##author"}{...}

{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{cmd:reshapehelper} {hline 2}}Diagnose the data and suggest (never run) the likely {help reshape} command{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:reshapehelper} [{cmd:long}|{cmd:wide}] [{varlist}] [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Tell it what you know (all optional)}
{synopt :{cmd:to(long}|{cmd:wide)}}the shape you want to END with; bare {cmd:long}/{cmd:wide} before the comma means the same thing{p_end}
{synopt :{cmd:i(}{varlist}{cmd:)}}the identifier variable(s), if you know them{p_end}
{synopt :{cmd:j(}{it:name}|{varname}{cmd:)}}going long: the NAME for the new j variable; going wide: the EXISTING j variable{p_end}
{synopt :{opt stub:s(names)}}the variable stubs, with {cmd:@} allowed, when the scanner cannot find them{p_end}

{syntab :Control}
{synopt :{opt samp:le(#)}}rows used for the dry run and probes; default {cmd:sample(500)}{p_end}
{synopt :{opt notes:t}}skip the preserve/restore dry run{p_end}
{synopt :{cmd:smcl(}{it:filename}{cmd:)}}write the unwrapped suggestion to this .smcl file (default: a session temp file){p_end}
{synopt :{cmd:replace}}overwrite an existing {cmd:smcl()} file{p_end}
{synopt :{opt gl:obal(name)}}global macro to hold the suggestion; default {cmd:$reshapehelper_cmd}{p_end}
{synopt :{opt d:etail}}also show the pattern scan and the i/j candidate lists{p_end}
{synoptline}
{pstd}The marked stem of an option name is its minimum abbreviation, so
{cmd:stubs()} may be typed {cmd:stub()}, {cmd:sample()} {cmd:samp()},
{cmd:notest} {cmd:notes}, {cmd:global()} {cmd:gl()}, and {cmd:detail}
{cmd:d}.  The option names shown unmarked must be typed in full.{p_end}
{pstd}A bare {cmd:reshapehelper} with no arguments diagnoses the dataset in memory.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{help reshape} is the Stata command most likely to send an analyst to a
discussion board: is this data wide or long, which variables are i and j,
where does the {cmd:string} option go, why r(9), why
{it:no xij variables found}?
{cmd:reshapehelper} answers those questions {it:before} anything is
reshaped.  It never modifies your data.

{pstd}
It works in four moves:

{phang2}1. {bf:Scan the variable names} for wide patterns: numeric suffixes
({cmd:inc80 inc81}), string suffixes after an underscore
({cmd:bp_before bp_after}), a j buried mid-name ({cmd:inc80r} {c 45} the
{cmd:@} notation), a j hiding in the PREFIX ({cmd:qld_p nsw_p vic_p}), and
doubly-wide names carrying two indices ({cmd:ht_k1_t2}).{p_end}

{phang2}2. {bf:Hunt for i and j}.  Declared structure comes first: an
{help xtset}/{help tsset} panel and time variable and the {help svyset}
primary sampling unit are taken as the analyst's own statement of the
design.  Then come uniqueness tests ({help isid}) over id-looking variables
and, when those fail, bounded searches over single variables and pairs
{c 45} which is how a compound i like (household, year) is found.{p_end}

{phang2}3. {bf:Compose and dry-run the command} on up to {cmd:sample()} rows
inside {cmd:preserve}/{cmd:restore}.  When the test fails, it iterates on
reshape's own error codes: r(109)/r(498) add the {cmd:string} option,
r(110) renames a colliding j, r(9) in a widening triggers a duplicates
diagnosis and one attempt to extend i() with a distinguishing variable.{p_end}

{phang2}4. {bf:Report}, as described next.  For a doubly-wide layout it
suggests (and tests) the two chained reshape commands.  When the job is
really a transpose {c 45} observations stored as columns {c 45} it says so
and points at {help xpose} ({cmd:sxpose} from SSC for string data).{p_end}


{marker output}{...}
{title:What you get back}

{pstd}{bf:1. A diagram.}  A boxed before/after sketch in the style of the
{help reshape} help file, built from your actual variable names and sample
values.  The AFTER box is real: it shows the dry run's result, not a
mock-up.{p_end}

{pstd}{bf:2. The suggested syntax, with a verdict.}  The command line(s),
marked {bf:dry-run PASSED} or {bf:FAILED r(#)}, plus any {it:note} (for
example, that i() keeps a time variable because the rows are a wide-long
panel) and any {it:caution} (for example, mixed suffix widths that smell
like the {cmd:inc2}-beside-{cmd:inc80} false match).  When nothing can be
composed, you get a numbered checklist of what to fix or supply instead
{c 45} confirm the row id, unify near-miss stubs, inspect duplicates, fold
crossed factors into one j with {cmd:egen concat()}, or state {cmd:to()},
{cmd:i()}, {cmd:j()} directly.{p_end}

{pstd}{bf:3. The command, ready to use.}  Stored in {cmd:r(cmd)} (and
{cmd:r(cmd2)} for a chained pair), in the global {cmd:$reshapehelper_cmd}
(and {cmd:$reshapehelper_cmd2}), written unwrapped to a viewable SMCL file,
and offered as click-to-run and click-to-view links in the Results window.
Run it as-is with:{p_end}

{phang2}{cmd:. $reshapehelper_cmd}{p_end}


{marker options}{...}
{title:Options}

{phang}{cmd:to(long|wide)} states the target shape.  Without it,
{cmd:reshapehelper} infers direction from the evidence: wide naming
patterns argue for {cmd:reshape long}; an (i, j) pair that uniquely
identifies rows argues the data are long and offers the widening.  A bare
{cmd:long} or {cmd:wide} before the comma is shorthand for this option.{p_end}

{phang}{cmd:i(}{varlist}{cmd:)} names the identifier(s) and skips the i
hunt.  Supply it whenever you know it; it is the single biggest help you
can give.{p_end}

{phang}{cmd:j(}{it:name}|{varname}{cmd:)} is direction-dependent, exactly as
in {help reshape}: going long it NAMES the new variable to create; going
wide it names the EXISTING variable whose values become suffixes.{p_end}

{phang}{opt stub:s(names)} hands over the stubs when the scanner
cannot find them {c 45} above all for bare string suffixes like
{cmd:incm}/{cmd:incf}, which {cmd:reshapehelper} deliberately does not guess
(the {help reshape} manual's own warning: beside an {cmd:agenda} variable, a
greedy scan would happily read stub {cmd:age} with j {cmd:nda}).  {cmd:@}
notation is allowed.{p_end}

{phang}{opt samp:le(#)} caps the rows used for value probes and
the dry run (default 500, minimum 10).  The suggestion is composed from the
sample; on very tall data a larger sample buys confidence at the cost of
speed.{p_end}

{phang}{opt notes:t} skips the dry run; the suggestion is then composed from
name patterns and identifier tests alone and printed unmarked.{p_end}

{phang}{cmd:smcl(}{it:filename}{cmd:)} and {cmd:replace} persist the
unwrapped suggestion beyond the session; the default writes to a temp-dir
file that the {it:click to VIEW} link opens.  A filename that does not
already end in {cmd:.smcl} has that extension appended, so
{cmd:smcl(mysuggestion)} writes {cmd:mysuggestion.smcl}; the path actually
used is returned in {cmd:r(smcl)}.{p_end}

{phang}{opt gl:obal(name)} renames the global holding the
suggestion (a chained second step lands in {it:name}{cmd:2}).{p_end}

{phang}{opt d:etail} adds the scanner tallies and the i/j candidate lists to
the header {c 45} useful when the suggestion surprises you.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Tier 1 {c 45} the textbook case ({help reshape} Example 1):{p_end}
{phang2}{cmd:. input id sex inc80 inc81 inc82 ...}{p_end}
{phang2}{cmd:. reshapehelper}{p_end}
{phang2}{txt:suggests and dry-runs} {cmd:reshape long inc, i(id) j(year)}{p_end}
{phang2}{cmd:. $reshapehelper_cmd}{p_end}

{pstd}Tier 2 {c 45} string suffixes, {cmd:string} added for you:{p_end}
{phang2}{cmd:. sysuse bpwide, clear}{p_end}
{phang2}{cmd:. reshapehelper}{p_end}
{phang2}{txt:suggests} {cmd:reshape long bp_, i(patient) j(period) string}{p_end}

{pstd}Tier 3 {c 45} tell it what you want and let the dry run find the rest
(here it discovers {cmd:string} by iterating on reshape's r(498)):{p_end}
{phang2}{cmd:. input id kids incm incf ...}{p_end}
{phang2}{cmd:. reshapehelper, to(long) stubs(inc) i(id) j(sex)}{p_end}

{pstd}Tier 4 {c 45} duplicates block a widening; get the remedy menu, not a
guess:{p_end}
{phang2}{cmd:. reshapehelper, to(wide)}{p_end}
{phang2}{txt:diagnosis counts the (i, j) collisions and offers: duplicates report / collapse / sequence with bysort ... gen seq = _n / fold a factor into j with egen concat()}{p_end}

{pstd}Tier 5 {c 45} the wide-long panel: county-year rows whose sector
columns hide a second long dimension (note that i() keeps year):{p_end}
{phang2}{cmd:. xtset county year}{p_end}
{phang2}{cmd:. reshapehelper}{p_end}
{phang2}{txt:suggests} {cmd:reshape long emp_, i(county year) j(period) string}{p_end}

{pstd}Tier 5 {c 45} doubly wide ({browse "https://stats.oarc.ucla.edu/stata/faq/how-can-i-reshape-doubly-or-triply-wide-data-to-long/":UCLA OARC FAQ}): two chained commands, both tested:{p_end}
{phang2}{cmd:. input famid ht_k1_t1 ht_k1_t2 ht_k2_t1 ht_k2_t2 ...}{p_end}
{phang2}{cmd:. reshapehelper}{p_end}
{phang2}{txt:step 1} {cmd:reshape long ht_k1_t ht_k2_t, i(famid) j(time)}{p_end}
{phang2}{txt:step 2} {cmd:reshape long ht_k@_t, i(famid time) j(grp)}{p_end}

{pstd}The bundled {cmd:example_reshapehelper.do} walks seventeen scenarios
across five tiers, from the textbook case through inconsistent stubs, the
{cmd:inc2} trap, prefix-j names, crossed factors, spaces in a string j,
duplicate (i, j) pairs, doubly-wide names, long-long to wide-wide, and the
transpose case.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:reshapehelper} stores the following in {cmd:r()}:{p_end}
{synoptset 16 tabbed}{...}
{synopt :{cmd:r(status)}}{cmd:ok} (suggestion composed), {cmd:blocked} (composed but the dry run failed; see {cmd:r(diagnosis)}), or {cmd:needinfo} (checklist shown){p_end}
{synopt :{cmd:r(direction)}}{cmd:wide2long}, {cmd:long2wide}, {cmd:doubly}, or {cmd:unknown}{p_end}
{synopt :{cmd:r(cmd)}, {cmd:r(cmd2)}}the suggested command(s); {cmd:r(cmd2)} when applicable (a chained doubly-wide pair){p_end}
{synopt :{cmd:r(preclean)}}when applicable, a data-cleaning line to run first (for example, stripping spaces from a string j){p_end}
{synopt :{cmd:r(i)}, {cmd:r(j)}, {cmd:r(stubs)}}the pieces the suggestion uses{p_end}
{synopt :{cmd:r(icands)}, {cmd:r(jcands)}}the candidate lists considered{p_end}
{synopt :{cmd:r(note)}, {cmd:r(caution)}, {cmd:r(diagnosis)}}the annotations printed under the suggestion, each when applicable{p_end}
{synopt :{cmd:r(smcl)}}path of the SMCL suggestion file, returned only when that file was written {c 45} that is, when {cmd:r(status)} is {cmd:ok} or {cmd:blocked}; a {cmd:needinfo} run writes no file and returns no {cmd:r(smcl)}.  The path carries the {cmd:.smcl} extension that {cmd:smcl()} appends when the filename you supply lacks it, so it need not match what you typed{p_end}
{synopt :{cmd:r(tested)}}1 if the dry run passed, else 0{p_end}
{synopt :{cmd:r(rc)}}the final dry-run return code{p_end}
{synopt :{cmd:r(xpose)}}1 when the layout smells like a transpose job{p_end}
{synopt :{cmd:r(sparse)}}a would-be identifier that was set aside as too sparse (returned only when that is why no command was found){p_end}
{p2colreset}{...}

{pstd}A macro that does not apply to a run is not stored at all, so it is
absent from {cmd:return list} rather than returned empty, and which macros
survive varies with the run.  A {cmd:needinfo} run, for instance, has no
{cmd:r(cmd)} and no {cmd:r(smcl)}, yet may still report the piece it did
settle on in {cmd:r(j)} beside its {cmd:r(diagnosis)}.  Test a macro for
emptiness rather than assume it is there.{p_end}

{pstd}The suggestion also lands in {cmd:$reshapehelper_cmd} (and
{cmd:$reshapehelper_cmd2}); rename with {cmd:global()}.  The globals mirror
the LAST run: a run with no second step clears the {cmd:2} global, and a
run that ends in the checklist clears both, so a stale command from an
earlier dataset can never fire.{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}{bf:Suggestions are advisory.}  A dry run proves the command RUNS on a
sample; only you can say whether the result MEANS what you need.  Two
built-in skepticisms help: small numeric suffixes (none above 12) draw a
caution that they may be item numbers rather than repeats over time, and
mixed suffix widths (a stray {cmd:inc2} beside {cmd:inc80}{c 45}{cmd:inc82})
draw a caution to restrict j explicitly or rename the stray {c 45} a case
where reshape itself runs happily and silently builds a mostly-missing j
group.{p_end}

{pstd}{bf:Why a stub is sometimes refused (name coincidences).}  A program
reading only variable names cannot reliably tell a real stub from a
coincidence.  With variables {cmd:incm} {cmd:incf} {cmd:uem} {cmd:uef}
{cmd:agem} {cmd:agef} plus an unrelated {cmd:agenda}, an automatic split
would decide the repeated values are {cmd:m}, {cmd:f}, and {cmd:nda} and
read a stub {cmd:age} out of {cmd:agenda} {c 45} the greedy match the
{help reshape} manual itself warns about.  To avoid confidently-wrong
suggestions, {cmd:reshapehelper} does not auto-detect bare letter-suffix
stubs; you name the stub with {cmd:stubs()} and it works out the rest,
including the {cmd:string} option, from the dry run.  Triple-nested single
commands are likewise never suggested; doubly-wide names get the two-step
chain, and deeper nesting gets the chain plus a rerun of
{cmd:reshapehelper} on the intermediate result.{p_end}

{pstd}{bf:The identifier plausibility bar (and sparse panels).}  When it
hunts for the row identifier, {cmd:reshapehelper} requires that a candidate
{it:repeat}: each unit should appear in more than one row (once per year,
wave, or condition), so a candidate that splits the sample into nearly as
many groups as there are rows is set aside as an accident of the data rather
than a design.  Concretely, the distinct groups must number at most half the
rows examined.  On {cmd:sysuse auto} the rule sets aside {cmd:make}: it does
pair with {cmd:mpg} to identify the rows uniquely, but it names a different
car in every row, so the run ends in the checklist with {cmd:r(sparse)}
reporting {cmd:make} rather than in a technically-valid but meaningless
widening on {cmd:i(make) j(mpg)}.  The one trade-off:
a {it:genuinely sparse} panel {c 45} most units observed once, only a few
repeated {c 45} can be sent to the checklist instead of getting a
suggestion.  When that happens the checklist says so by name and offers to
force the identifier ({cmd:reshapehelper, i(}{it:thatvar}{cmd:) ...}); if
most rows really should share an id, the true identifier may be missing or
mis-typed (for example a name with trailing spaces), so clean it first.{p_end}

{pstd}{bf:The j-candidate ceiling.}  A second bar applies to j when the data
are being widened.  A variable enters the j candidate list only if it takes
at least 2 distinct values and at most 60 or half the sampled rows (rounded
up), whichever is smaller, so beyond the half-the-rows rule there is an absolute
ceiling of 60 distinct j values: a variable with more than 60 levels is
read as an identifier or a measurement rather than an index, and is not
proposed as j even in a very tall dataset.  The fallback pass, which runs
when no candidate carries a time-like name ({cmd:year}, {cmd:wave},
{cmd:visit}, and so on), is stricter still and stops at 30 distinct values.
Naming the variable in {cmd:j()} bypasses both limits, which is the way to
widen on a high-cardinality index deliberately {c 45} bearing in mind that
each level becomes its own set of columns.{p_end}

{pstd}{bf:Rerun it.}  {cmd:reshapehelper} is built to be run again on its own
output: a wide-long panel widens one dimension per pass, and the note tells
you when another dimension remains.{p_end}

{pstd}{bf:Sampling.}  All probes and the dry run use the first
{cmd:sample()} rows, so a duplicate or a rename that only appears deep in a
tall dataset can escape the diagnosis; the final authority is running the
suggestion yourself (and, after a failure, {cmd:reshape error}, which lists
the offending observations).{p_end}


{marker author}{...}
{title:Author}

{pstd}Eric A. Booth{break}
Sr Researcher, Texas 2036{break}
eric.a.booth@gmail.com{p_end}

{pstd}MIT License.  Report issues at the {browse "https://github.com/ericabooth/reshapehelper-stata-public":GitHub repository}.{p_end}


{title:Also see}

{psee}Manual: {manlink D reshape}{p_end}
{psee}Help: {help reshape}, {help xpose}, {help stack}, {help sxpose} (SSC){p_end}
