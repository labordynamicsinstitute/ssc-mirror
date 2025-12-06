{smcl}
{* *! version 1.1 01Sep2025 Wu LiangHai(AHUT)/Wu HanYan(NUAA)}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "cleandisk##syntax"}{...}
{viewerjumpto "Description" "cleandisk##description"}{...}
{viewerjumpto "Options" "cleandisk##options"}{...}
{viewerjumpto "Examples" "cleandisk##examples"}{...}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{cmd:cleandisk} {hline 2}}Clean disk space by removing temporary and unnecessary files{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cleandisk}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt dr:ives(string)}}specify drives to clean (e.g., "c d e"){p_end}
{synopt:{opt temp:only}}clean temporary files only{p_end}
{synopt:{opt q:uietly}}run in silent mode{p_end}
{synopt:{opt e:xit}}exit Stata automatically after cleaning{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cleandisk} is a utility command that helps clean up disk space by removing temporary and unnecessary files from specified drives. 
By default, it cleans all default drives (C, D, E, F) unless specified otherwise.{p_end}

{pstd}
The command provides progress information and estimated remaining time during the cleaning process, offering a better user experience.{p_end}

{pstd}
The command is particularly useful when working with large datasets or when disk space becomes limited.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt drives(string)} specifies which drives to clean. Separate multiple drives with spaces.
The default is to clean all default drives (C, D, E, F).

{phang}
{opt temponly} specifies that only temporary files should be cleaned, leaving other files untouched.

{phang}
{opt quietly} runs the command in silent mode without displaying any output.

{phang}
{opt exit} automatically exits Stata after the cleaning process is completed. This is useful for batch processing or automated scripts.


{marker examples}{...}
{title:Examples}

{phang}

{pstd}Basic usage (clean all default drives C, D, E, F){p_end}

{pstd}{cmd:. cleandisk}{p_end}

{pstd}Clean specific drives (C and D only){p_end}

{pstd}{cmd:. cleandisk, drives("c d")}{p_end}

{pstd}Clean temporary files only on all default drives{p_end}

{pstd}{cmd:. cleandisk, temponly}{p_end}

{pstd}Run in silent mode (no output displayed){p_end}

{pstd}{cmd:. cleandisk, quietly}{p_end}

{pstd}Clean and automatically exit Stata{p_end}

{pstd}{cmd:. cleandisk, exit}{p_end}

{pstd}Clean specific drives, show progress, and exit Stata afterwards{p_end}

{pstd}{cmd:. cleandisk, drives("c d") exit}{p_end}

{pstd}Run full disk cleaning in silent mode and exit{p_end}

{pstd}{cmd:. cleandisk, quietly exit}{p_end}
{hline}


{marker authors}{...}
{title:Authors}

{pstd}
{bf:Wu Lianghai, Chen Liwen}{p_end}
{pstd}School of Business, Anhui University of Technology(AHUT){p_end}
{pstd}Ma'anshan, China{p_end}
{pstd}{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}
{pstd}{browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}

{pstd}
{bf:Wu Hanyan}{p_end}
{pstd}School of Economics and Management, Nanjing University of Aeronautics and Astronautics(NUAA){p_end}
{pstd}Nanjing, China{p_end}
{pstd}{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}
{bf:Ma Defang}{p_end}
{pstd}Capital Normal University(CNU){p_end}
{pstd}{browse "mailto:6346@cnu.edu.cn":6346@cnu.edu.cn}{p_end}

{*}