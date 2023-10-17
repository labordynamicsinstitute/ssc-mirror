{smcl}
{* *! version 2.1.0  10oct2023}{...}
{vieweralsosee "[P] macro" "help macro"}{...}
{viewerjumpto "Syntax" "preserve_globals##syntax"}{...}
{viewerjumpto "Description" "preserve_globals##description"}{...}
{viewerjumpto "Options" "preserve_globals##options"}{...}
{viewerjumpto "Remarks" "preserve_globals##remarks"}{...}
{viewerjumpto "Acknowledgements" "preserve_globals##acknowledgements"}{...}
{viewerjumpto "Support" "preserve_globals##support"}{...}
{...}
{cmd:preserve_globals} {hline 2} Preserve global macros


{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:preserve_globals}
[ {cmd:,} {opt strict} {cmd::} ]
{it:command}


{...}
{marker description}{...}
{title:Description}

{pstd}
{cmd:preserve_globals} preserves global macros and restores their contents 
when {it:command} has concluded. 
Any changes that {it:command} makes to 
existing global macros are undone as soon as {it:command} concludes. 
However, {it:command} may define new global macros and such global 
macros persist when {it:command} concludes.


{...}
{marker options}{...}
{title:Options}

{phang}
{opt strict} deletes any new global macros that {it:command} defines 
when {it:command} concludes. 


{...}
{marker remarks}{...}
{title:Remarks}

{pstd}
Generally, {cmd:preserve_globals} may be used with commands 
that define local macros, e.g., {help levelsof}. 
However, local macros cannot be deleted by commands prefixed 
with {cmd:preserve_globals}. 
Consider this example:

        {cmd:. sysuse auto}
        {cmd:. local foo "42"}
        {cmd:. preserve_globals levelsof price if make == "", local(foo)}

{pstd}
In {cmd:auto.dta}, the variable {cmd:make} is never missing. 
Thus, {cmd:levelsof} would not return any levels of the variable 
{cmd:price}; the local macro {cmd:foo} should be empty. 
Yet, the local macro {cmd:foo} will remain unchanged; 
it still contains {cmd:"42"}. 

{pstd}
When you use {cmd:preserve_globals} with commands that define local macros,
you must define the respective local macros explicitly; that is, you must 
type

        {cmd:local levels // void}
        {cmd:levelsof} {it:varname}{cmd:, local(levels)}
        
{pstd}
to guarantee that local macros are empty when they should be empty.
 

{...}
{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}
Earlier versions of the command resulted from a suggestion from Clyde Schechter 
and a following discussion on 
{browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1711202-wishlist-for-stata-19?p=1714776#post1714776":Statalist}.


{marker support}{...}
{title:Support}

{pstd}
Daniel Klein{break}
{browse "mailto:klein.daniel.81@gmail.com":klein.daniel.81@gmail.com}
