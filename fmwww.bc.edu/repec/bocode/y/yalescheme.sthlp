{smcl}
{* 30oct2020}{...}
{cmd:help yalescheme}
{hline}

{title:Title}

{phang}
{cmd:yalescheme} {hline 2} A modern Stata scheme for Yale University-branded data visualizations.


{title:Description}

{pstd}
The Yale Stata scheme provides a quick set of options for
modern-looking graphs from Stata using Yale colors. The scheme is designed for
use by the Yale Economic Growth Center's Research Team when designing
visualizations for presentations and social media. There are no restrictions
on its use.

{title:Usage}

{pstd}
To use, simply specify the scheme at the start of a .do file:

	{cmd:.} {cmd: set scheme yale [, permanently]}

{pstd}
Alternatively, you can specify the scheme in the course of making an individual
graph:

	{cmd:.} {cmd: sysuse auto}
	{cmd:.} {cmd: twoway scatter price mpg, scheme(yale)}

{pstd}
{bf:Note:} Once installed, you will need to restart Stata for the scheme to
be recognized.

{title:Fonts}

{pstd}
The {bf:Yale} scheme is intended to be used with Yale official fonts. If you are
Yale EGC staff, please contact Vestal McIntyre for access to the proprietary
{bf:Mallory }font. Fonts are specified independently of schemes; to set the
fonts for the graph window, add the following to the top of any .do file
using the Yale scheme:

	{cmd:.} {cmd: graph set window fontface "Mallory Thin"}
	{cmd:.} {cmd: graph set window fontfacemono default}
	{cmd:.} {cmd: graph set window fontfacesans "Mallory Thin"}
	{cmd:.} {cmd: graph set window fontfaceserif YaleNew}
	{cmd:.} {cmd: graph set window fontfacesymbol "Mallory Thin"}


{title:Attribution}

{pstd}
The Yale scheme was written by Aaron Wolf. Bugs can be reported via the
repository at Github (https://github.com/aarondwolf/scheme-yale).

{pstd}
This scheme used the user-written scheme {bf:cleanplots} as a base, with
alterations made to reflect Yale's colors and stylistic preferences.
{bf:cleanplots} was created by Trenton Mize, and documentation can be found
at https://www.trentonmize.com/software/cleanplots. {bf:cleanplots} was itself
influenced by Daniel Bischof's very excellent {bf:plotplain} scheme,
documentation for which can be found at https://www.stata-journal.com/article.html?article=gr0070.


{title:Authors}

{pstd}Aaron Wolf, Yale University{p_end}
{pstd}aaron.wolf@yale.edu{p_end}
