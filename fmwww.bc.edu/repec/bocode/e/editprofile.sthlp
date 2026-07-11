{smcl}
{* *! version 1.0.8  10July2026  Wu Lianghai (agd2010@yeah.net)}{...}
{hline}

{title:help for editprofile}

{title:Syntax}

{p 4 8}
{cmd:editprofile}                  {it:(open existing profile.do)}
{p_end}

{p 4 8}
{cmd:editprofile,} {bf:create} [{bf:path(}{it:filename}{bf:)}]
{p_end}

{p 4 8}
{cmd:editprofile,} {bf:open}   [{bf:path(}{it:filename}{bf:)}]
{p_end}

{p 4 8}
{cmd:editprofile,} {bf:showpath} [{bf:path(}{it:filename}{bf:)}]
{p_end}

{title:Description}

{pstd}
{cmd:editprofile} locates, opens, and optionally creates the
user-specific {bf:profile.do} file.  Stata executes
{bf:profile.do} automatically whenever it is launched, allowing
users to set custom defaults (working directory, graphics scheme,
memory allocation, extra ado directories, etc.).
{p_end}

{pstd}
Called without any options, {cmd:editprofile} opens the first
{bf:profile.do} found in Stata's standard search order — the
current working directory, the Stata installation directory, or
the PERSONAL ado directory.  If no {bf:profile.do} exists yet,
an error message is shown and the user is advised to use the
{bf:create} option.
{p_end}

{title:Options}

{phang}
{bf:create} creates a new {bf:profile.do} from a template if
one does not already exist at the target location.  The template
includes commented settings for common customisations (working
directory, graphics scheme, memory, labels, matrices, scrollback,
ado paths, packages, and log type).  If a {bf:profile.do}
already exists, the existing file is opened in the do-file editor
instead of being overwritten.
{p_end}

{phang}
{bf:open} explicitly opens an existing {bf:profile.do} in the
do-file editor.  This is the default action when no option is
specified.  The option is mainly provided for explicitness in
do-files and scripts.
{p_end}

{phang}
{bf:showpath} displays the full path of the {bf:profile.do}
that {cmd:editprofile} would act on, without opening or modifying
the file.  Useful for confirming which {bf:profile.do} Stata is
using before making changes.
{p_end}

{phang}
{bf:path(}{it:filename}{bf:)} specifies a custom location for
{bf:profile.do}.  The argument may be a full file path (ending
in {bf:profile.do}) or a directory; if a directory is given,
{bf:profile.do} is appended to it automatically.  By default,
{cmd:editprofile} searches Stata's standard locations.
{p_end}

{title:Search order}

{pstd}
When {bf:path()} is not supplied, {cmd:editprofile} searches
the following locations in order:
{p_end}

{p 8 12}
1.  Current working directory ({cmd:profile.do})
{p_end}

{p 8 12}
2.  Stata executable directory
`c(sysdir_stata)'
{p_end}

{p 8 12}
3.  PERSONAL ado directory
`c(sysdir_personal)'
{p_end}

{pstd}
The first location at which a {bf:profile.do} is found is used.
If no existing {bf:profile.do} is found anywhere, the PERSONAL
directory is proposed as the default location for creating a new
one.  Placing {bf:profile.do} in the PERSONAL directory is the
recommended practice — it keeps user customisations separate
from the Stata installation and travels with the user's ado
files.
{p_end}

{title:Remarks}

{pstd}
{bf:profile.do} is a plain-text do-file that Stata looks for and
executes automatically on startup.  It is distinct from
{bf:sysprofile.do}, which is a system-wide startup file that
affects all users sharing a Stata installation.  {cmd:editprofile}
only manages the user-specific {bf:profile.do}.
{p_end}

{pstd}
Changes made to {bf:profile.do} take effect the next time Stata
is launched.  To apply changes immediately without restarting,
you can run the file manually:
{p_end}

{p 8 12}
{stata "do profile.do":do profile.do}
{p_end}

{title:Examples}

{pstd}
{bf:1.  Open your profile.do (the default).}
{p_end}

{p 8 12}
{input:. editprofile}
{p_end}

{pstd}
{bf:2.  Find out where your profile.do is (or would be).}
{p_end}

{p 8 12}
{input:. editprofile, showpath}
{p_end}

{pstd}
{bf:3.  Create a fresh profile.do from the template.}
{p_end}

{p 8 12}
{input:. editprofile, create}
{p_end}

{pstd}
{bf:4.  Create profile.do in a custom location.}
{p_end}

{p 8 12}
{input:. editprofile, create path("C:/myproject/")}
{p_end}

{pstd}
{bf:5.  Open an existing profile.do at a known location.}
{p_end}

{p 8 12}
{input:. editprofile, path("D:/ado/personal/profile.do")}
{p_end}

{title:Author}

{pstd}
Wu Lianghai (吴良海){break}
School of Business{break}
Anhui University of Technology (AHUT){break}
Ma'anshan, China{break}
Email: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}
{p_end}

{title:Version history}

{pstd}
{bf:1.0.8} 10July2026.  Revised release.{break}
{bf:1.0.0} 17June2026.  Initial release.
{p_end}

{hline}
{center:{it:end of help for editprofile}}
