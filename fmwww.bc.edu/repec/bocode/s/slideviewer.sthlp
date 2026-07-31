{smcl}
{* May2026}{...}
{hline}
help for {hi:slideviewer}
{hline}

{title:Manage and navigate SMCL slides in the Stata Viewer}

{p 4 8 2} 
{cmd:slideviewer}
[{it:filename} | {it:keyword}]
[{cmd:,} {cmdab:s:ubdir}({it:path}) {cmd:navbar} {cmdab:p:ost} {cmd:clear}]

{title:Description}

{p 4 4 2}
{cmd:slideviewer} is a navigation engine for SMCL files (slides) displayed in the Stata Viewer. 
It allows for easy traversal of a slide deck stored in a subdirectory, automatic table of contents 
generation, and an optional interactive navigation bar.

{p 4 4 2}
Version 2.0 is optimized for Stata 16+ and supports UTF-8 encoding.

{title:Navigation Keywords}

{p 4 4 2}
Instead of a filename, you can use the following keywords:

{p 4 8 2}
{cmd:next} {space 6} Moves to the next slide in alphabetical order. Wraps to the first slide after the last. {p_end}
{p 4 8 2}
{cmd:prev} {space 6} Moves to the previous slide in alphabetical order. Wraps to the last slide from the first. {p_end}
{p 4 8 2}
{cmd:first} {space 5} Jumps to the alphabetically first slide. {p_end}
{p 4 8 2}
{cmd:last} {space 6} Jumps to the alphabetically last slide. {p_end}
{p 4 8 2}
{cmd:toc} {space 7} Generates a clickable Table of Contents of all .smcl files in the subdirectory. {p_end}

{title:Options}

{p 4 8 2}
{cmdab:s:ubdir}({it:path}) defines the directory where the .smcl slides are stored. Once set, 
this path is remembered across calls until changed or cleared. The default is a folder named 
"ignore" in the current working directory. {p_end}

{p 4 8 2}
{cmd:navbar} injects a navigation header and footer into the viewer. This provides clickable 
links for [First] [Prev] [TOC] [Next] [Last] without needing to modify your individual slide files. 
It works by generating a temporary SMCL file that wraps your content. {p_end}

{p 4 8 2}
{cmdab:p:ost} stores the name of the current slide in {cmd:r(lastslide)}. {p_end}

{p 4 8 2}
{cmd:clear} resets the persistent state (clears the remembered subdirectory and current slide). {p_end}

{title:Examples}

{marker mwe1}
{dlgtab:Example 1: Basic setup}

{p 4 4 2}
1. Create a folder named "myslides" in your current directory.{break}
2. Put three files in it: {it:slide1.smcl}, {it:slide2.smcl}, {it:slide3.smcl}.{break}
3. Start the viewer:

{p 8 12 2}{cmd:. slideviewer first, subdir("myslides")}{p_end}

{p 4 4 2}
Now you can navigate from the command line or via links in the slides:

{p 8 12 2}{cmd:. slideviewer next}{p_end}

{marker mwe2}
{dlgtab:Example 2: Using the Navigation Bar}

{p 4 4 2}
To enable an interactive navigation bar that appears automatically on every slide:

{p 8 12 2}{cmd:. slideviewer first, subdir("myslides") navbar}{p_end}

{p 4 4 2}
Every slide will now show navigation links at the top and bottom.

{marker mwe3}
{dlgtab:Example 3: Creating a custom TOC}

{p 8 12 2}{cmd:. slideviewer toc}{p_end}

{title:Author}

{p 4 4 2}Eric A. Booth {break} 
         eric.a.booth@gmail.com {break} 
		 {browse "http://www.eric-booth.com"} {break}
		 {browse "https://github.com/ericabooth"}

{title:Also see}

{p 4 8 2}On-line: help for {help view}, {help smcl}
