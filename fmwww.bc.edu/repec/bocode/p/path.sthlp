{smcl}
{cmd:help path}
{hline}

{title:Title}

{p 5}
{cmd:path} {hline 2} File path manipulation


{title:Syntax}

{p 5 8 2}
Split path

{p 8 8 2}
{cmd:path split} 
[{cmd:"}]{it:{help filename:path}}[{cmd:"}]


{p 5 8 2}
Cut path into pieces

{p 8 8 2}
{cmd:path pieces} 
[{cmd:"}]{it:{help filename:path}}[{cmd:"}]


{p 5 8 2}
Join path

{p 8 8 2}
{cmd:path join} 
[{cmd:"}]{it:{help filename:path1}}[{cmd:"}]
[{cmd:"}]{it:{help filename:path2}}[{cmd:"}]


{p 5 8 2}
Path to directory

{p 8 8 2}
{cmd:path of} 
[{it:{help filename:directory}}]


{p 5 8 2}
Confirm directory

{p 8 8 2}
{cmd:path} {cmd:confirm} [ {opt new} | {opt url} | {opt abs:olute} ] 
{cmd:"}{it:{help filename:path}}{cmd:"}


{title:Description}

{pstd}
{cmd:path} is a bundle of utility commands for file path 
manipulation.

{pstd}
{cmd:path split} splits {it:path} into directory, filename and 
extension/suffix and returns elements in {cmd:s()}. If path has 
no directory, filename or file extension/suffix, the respective 
elements are omitted from {cmd:s()}.

{pstd}
{cmd:path pieces} cuts {it:path} into pieces and returns the 
elements {cmd:s()}.

{pstd}
{cmd:path join} forms {it:path1}{ccl dirsep}{it:path2} and 
returns it in {cmd:s()}.

{pstd}
{cmd:path of} is a clone of {cmd:pathof} 
({help path##ref:Barker 2014}), conceptually. It returns in 
{cmd:s()} the current working directory up to the specifed 
{it:directory} or the root of the current working directory, 
if {it:directory} is not specified.

{pstd}
{cmd:path confirm} confirms that {it:path} is of the claimed 
type (see {helpb confirm}). Nothing is returned in {cmd:s()} 
and previous contents in {cmd:s()} are preserved. This command 
is similar to {help path##ref:Blanchette's (2011)} 
{cmd:confirmdir}. 


{title:Example}

{phang2}
{cmd:. path split "c:{ccl dirsep}ado{ccl dirsep}plus{ccl dirsep}path.ado"}
{p_end}
{phang2}
{cmd:. sreturn list}
{p_end}

{phang2}
{cmd:. path pieces "c:{ccl dirsep}ado{ccl dirsep}plus{ccl dirsep}path.ado"}
{p_end}
{phang2}
{cmd:. sreturn list}
{p_end}

{phang2}
{cmd:. path join "c:{ccl dirsep}ado" "plus{ccl dirsep}path.ado"}
{p_end}
{phang2}
{cmd:. sreturn list}
{p_end}

{phang2}
{cmd:. path confrim "c:{ccl dirsep}ado"}
{p_end}


{title:Saved results}

{pstd}
{cmd:path split} saves in {cmd:s()}

{pstd}
Macros{p_end}
{synoptset 21 tabbed}{...}
{synopt:{cmd:s(filename)}}{it:filename} 
(without extension/suffix){p_end}
{synopt:{cmd:s(extension)}}{it:extension} of {it:filename}
(same as {cmd:s(suffix)}){p_end}
{synopt:{cmd:s(suffix)}}{it:suffix} of {it:filename}
(same as {cmd:s(extension)}){p_end}
{synopt:{cmd:s(directory)}}{it:directory}{p_end}

{pstd}
{cmd:path pieces} saves in {cmd:s()}

{pstd}
Macros{p_end}
{synoptset 21 tabbed}{...}
{synopt:{cmd:s(pieces)}}number of pieces ({cmd:0} if none){p_end}
{synopt:{cmd:s(piece{it:#})}}elements of {it:path}{p_end}

{pstd}
{cmd:path join} saves in {cmd:s()}

{pstd}
Macros{p_end}
{synoptset 21 tabbed}{...}
{synopt:{cmd:s(path)}}{it:path1}{ccl dirsep}{it:path2}{p_end}

{pstd}
{cmd:path of} saves in {cmd:s()}

{pstd}
Macros{p_end}
{synoptset 21 tabbed}{...}
{synopt:{cmd:s(path)}}{cmd:{ccl pwd}} (up to {it:directory}){p_end}

{pstd}
{cmd:path confirm} saves nothing in {cmd:s()}

{marker ref}
{title:References}

{pstd}
Blanchette, D. (2011). {stata findit confirmdir:CONFIRMDIR}: 
Stata module to confirm if a directory exists. 
{it:Statistical Software Components}.

{pstd}
Barker, M. (2014). {stata findit pathof:PATHOF}: Stata module 
to return the absolute path of any parent directory of the 
current working directory. {it:Statistical Software Components}.


{title:Author}

{pstd}Daniel Klein, University of Kassel, klein.daniel.81@gmail.com


{title:Also see}

{psee}
Online: {helpb mf_pathjoin:pathjoin()}, {helpb confirm}, 
{help _getfilename}
{p_end}

{psee}
if installed: {help pathof}, {help confirmdir}, 
{help getfilename2}, {help normalizepath}, {help extractfilename}
{p_end}

