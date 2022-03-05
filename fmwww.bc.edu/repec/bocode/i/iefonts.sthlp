{smcl}
{* 04feb2022}{...}
{vieweralsosee "Inclusion Economics scheme" "help inclusioneconomicsscheme"}{...}
{cmd:help iefonts}
{hline}

{marker title}
{title:Title}

{phang}
{cmd:iefonts} {hline 2} A helper command to configure graph fonts for use with the {it:Inclusion Economics} graph color schemes.

{title:Syntax}

{phang}
{cmd:iefonts} [{cmd:,} {it:options}]

{synoptset 10 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt serif}}Set graph fonts to Lora rather than Montserrat.{p_end}
{synopt :{opt restore}}Restore default Stata graph fonts.{p_end}

{marker description}
{title:Description}

{pstd}
The {helpb inclusioneconomicsscheme:Inclusion Economics scheme} is intended to be used with the {bf:Inclusion Economics} brand fonts, Montserrat and Lora, which can be downloaded and installed from Google Fonts.
Fonts are specified independently of schemes.

{pstd}
This helper command, {cmd:iefonts}, helps configure {it:Inclusion Economics} fonts.
Once Montserrat and Lora are installed to your system, you can run {cmd:iefonts} to configure Stata to use them in graphs.

{marker installation}
{title:Installation}

{pstd}
Before this command has any effect, you must download and install Montserrat and Lora.
Both are available from Google Fonts. Install the entire families.

{pstd}
{bf:Note:} This command cannot install Montserrat and Lora for you, nor can it check that they are properly installed.

{marker usage}
{title:Usage}

{pstd}
To set graph fonts to Montserrat, the {it:Inclusion Economics} sans-serif font:

	{cmd:.} {cmd: iefonts}
	
{pstd}
To set graph fonts to Lora, the {it:Inclusion Economics} serif font:
	
	{cmd:.} {cmd: iefonts, serif}

{pstd}
{bf:Note:} Our brand guidelines state that graphs should use sans-serifs unless there is a compelling reason to use serifs.

{pstd}
In either case, the configuration is permanent.
Therefore there is also an option to restore graph fonts to the Stata defaults:
	
	{cmd:.} {cmd: iefonts, restore}

{marker author}
{title:Author}

{pstd}Nils Enevoldsen, {it:Inclusion Economics}{p_end}
{pstd}nils@wlonk.com{p_end}
