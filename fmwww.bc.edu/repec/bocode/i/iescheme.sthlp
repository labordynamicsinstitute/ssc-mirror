{smcl}
{* 04feb2022}{...}
{vieweralsosee "iefonts" "help iefonts"}{...}
{cmd:help iescheme}
{hline}

{marker title}
{title:Title}

{phang}
{cmd:Inclusion Economics scheme} {hline 2} A modern Stata scheme for {it:Inclusion Economics}-branded data visualizations.

{marker description}
{title:Description}

{pstd}
The {it:Inclusion Economics} Stata scheme provides a quick set of options for modern-looking graphs from Stata using {it:Inclusion Economics} colors.
The scheme is intended for use by the research team of {it:Inclusion Economics} when designing visualization for presentations and social media.
There are no restrictions on its use.

{pstd}
Two schemes are provided:

	Scheme{col 20}Description
	{hline 60}
	{cmd:ie}{col 20}Three/four-color scheme using core brand palette
	{cmd:ie2}{col 20}Six-color scheme using expanded palette
	{hline 60}

{pstd}
{bf:Note:} Refer to {help iescheme##colors:Colors} for more on {cmd:ie} and {cmd:ie2}.

{pstd}
{bf:Important:} Refer to {help iescheme##fonts:Fonts} for setting up fonts.

{marker usage}
{title:Usage}

{pstd}
Specify the scheme at the start of a do-file:

	{cmd:.} {cmd: set scheme ie}

{pstd}
{it:or}:

	{cmd:.} {cmd: set scheme ie2}

{pstd}
Alternatively, specify the scheme for an individual graph:

	{cmd:.} {cmd: sysuse auto}
	{cmd:.} {cmd: twoway scatter price mpg, scheme(ie)}

{pstd}
Alternatively, specify the default scheme at the command prompt:

	{cmd:.} {cmd: set scheme ie, permanently}

{pstd}
{bf:Note:} Once installed, you will need to restart Stata for the scheme to be recognized.

{marker colors}
{title:Colors}

{pstd}
{it:Inclusion Economics} colors are navy, orange, blue, and beige.
The scheme {cmd:ie} uses these colors for bar, pie, and area graphs.
For other graph types, beige is omitted for readability.

{pstd}
When more than three or four colors are required, you may specify the scheme {cmd:ie2}, which has an extended palette of six colors.

{pstd}
If these colors are not suitable, you may manually override them.
They should appear as the first eight colors in color menus of the Graph Editor, and they may also be specified directly in do-files.
The colors are named {cmd:ienavy}, {cmd:iebeige}, {cmd:ieblue}, {cmd:ieorange}, {cmd:ieteal}, {cmd:iemagenta}, {cmd:ieyellow}, {cmd:iegreen}.
(In menus, they appear as "IE navy", etc.)

{marker fonts}
{title:Fonts}

{pstd}
The {it:Inclusion Economics} scheme is intended to be used with {it:Inclusion Economics} official fonts, Montserrat and Lora, which must be independently downloaded and installed from Google Fonts.
Once they are installed, you can use {helpb iefonts} to configure them.
See {helpb iefonts} for more detail.

{marker attribution}
{title:Attribution}

{pstd}
The {it:Inclusion Economics} scheme was written by Nils Enevoldsen.
Bugs can be reported via the repository at Github ({browse "https://github.com/NilsEnevoldsen/inclusioneconomicsscheme"}).

{pstd}
This scheme is a fork of the {it:Yale} scheme, written by Aaron Wolf, which can be found at {browse "https://github.com/aarondwolf/yalescheme"}.

{pstd}
This scheme used the user-written scheme {bf:cleanplots} as a base, with alterations made to reflect the colors of Inclusion Economics and stylistic preferences.
{bf:cleanplots} was created by Trenton Mize, and documentation can be found at {browse "https://www.trentonmize.com/software/cleanplots"}.
{bf:cleanplots} was itself influenced by Daniel Bischof's very excellent {bf:plotplain} scheme, documentation for which can be found at {browse "https://www.stata-journal.com/article.html?article=gr0070"}.

{pstd}
To make the six-color {cmd:ie2} palette, IE orange and IE blue were used as a base, and off-brand colors were added,
roughly based on the {browse "https://colorbrewer2.org/#type=qualitative&scheme=Set2&n=6":ColorBrewer2 Qualitative 6-Class Set2 palette}.
ColorBrewer2 is made by Cynthia Brewer and Mark Harrower.

{marker author}
{title:Author}

{pstd}Nils Enevoldsen, {it:Inclusion Economics}{p_end}
{pstd}nils@wlonk.com{p_end}
