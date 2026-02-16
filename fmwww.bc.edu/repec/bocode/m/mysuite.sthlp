{smcl}
{* 13Feb2026}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "myedit" "help myedit"}{...}
{viewerjumpto "Syntax" "mysuite##syntax"}{...}
{viewerjumpto "Description" "mysuite##description"}{...}
{viewerjumpto "Options" "mysuite##options"}{...}
{viewerjumpto "Examples" "mysuite##examples"}{...}
{viewerjumpto "Authors" "mysuite##authors"}{...}
{viewerjumpto "Acknowledgments" "mysuite##acknowledgments"}{...}
{title:Title}

{phang}
{bf:mysuite} {hline 2} Built-in extensible program suite for empirical research


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:mysuite}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt All}}Install missing SSC modules only{p_end}
{synopt:{opt Installed}}List currently installed modules{p_end}
{synopt:{opt Download}}Force reinstall all modules (when combined with {opt all}){p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mysuite} is a comprehensive Stata program suite designed for empirical research,
teaching management, and academic writing. It provides access to 30 specialized
programs organized into three main categories.

{pstd}
{bf:Module Sources:}

{phang2}
28 modules available for download from SSC Archive{p_end}

{phang2}
2 modules ({bf:bmc}, {bf:conservatism}) included locally in the mysuite package{p_end}

{pstd}
{bf:Core Features:}

{phang2}
- Centralized module discovery and installation{p_end}

{phang2}
- Smart installation: only installs missing modules{p_end}

{phang2}
- Force reinstall all modules when needed{p_end}

{phang2}
- Installation status checking and reporting{p_end}

{phang2}
- List all currently installed modules{p_end}

{pstd}
{bf:Operation Modes:}

{phang2}
{bf:MODE 1 - Display}
  No options specified
  → Show program banner, complete module list (30 programs),
     current installation status, and detailed usage instructions.
     No modules are downloaded or installed.{p_end}

{phang2}
{bf:MODE 2 - Install Missing}
  {opt all} option specified
  → Scan and install only SSC modules that are not currently installed.
     Already installed modules are skipped for efficiency.{p_end}

{phang2}
{bf:MODE 3 - List Installed}
  {opt installed} option specified
  → Display a complete list of all currently installed modules,
     separated into SSC modules and local modules sections.
     Shows installation count summary.{p_end}

{phang2}
{bf:MODE 4 - Force Reinstall}
  {opt all} and {opt download} options combined
  → Force reinstall ALL 28 SSC modules regardless of current installation status.
     Useful for updating to latest versions or fixing corrupted installations.{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt All} installs only missing SSC modules in the mysuite collection.
Checks each module's installation status first and only downloads those not found.
Shows installation progress and summary statistics upon completion.

{phang}
{opt Installed} lists all currently installed modules without making any changes.
Displays separate sections for SSC modules and local modules, with a count summary.

{phang}
{opt Download} modifies the behavior of {opt all}. When combined:
- {cmd:mysuite, all} → Install missing modules only
- {cmd:mysuite, all download} → Force reinstall ALL modules


{marker examples}{...}
{title:Examples}

{pstd}
{bf:MODE 1 - Display Program Information:}

{phang}{cmd:. mysuite}{p_end}
{phang}Display program banner, complete module list (30 programs),
current installation status (e.g., "SSC modules installed: 15/28"),
and detailed usage instructions. No modules are downloaded or installed.{p_end}

{pstd}
{bf:MODE 2 - Install Missing Modules:}

{phang}{cmd:. mysuite, all}{p_end}
{phang}Smart installation - checks each of the 28 SSC modules and installs
only those not currently found. Already installed modules are skipped.
Example output:
  {bf:sumtex}: Already installed
  Installing {bf:regtex}... Done
  {bf:estout}: Already installed
Installation Summary:
  Already installed: 26 modules
  Newly installed:   2 modules{p_end}

{pstd}
{bf:MODE 3 - List Installed Modules:}

{phang}{cmd:. mysuite, installed}{p_end}
{phang}Display complete list of currently installed modules:
  {bf:Currently Installed Modules:}
    {bf:art2tex}: Installed
    {bf:case2tex}: Installed
    ...
  {bf:Local Modules:}
    {bf:bmc}: Installed
    {bf:conservatism}: Installed
  {bf:Summary:} 24/28 SSC modules installed
Useful for quick inventory of your setup.{p_end}

{pstd}
{bf:MODE 4 - Force Reinstall All Modules:}

{phang}{cmd:. mysuite, all download}{p_end}
{phang}Force reinstall ALL 28 SSC modules regardless of current status.
Use this to update to latest versions or fix corrupted installations.
Example output:
  Reinstalling {bf:art2tex}... Done
  Reinstalling {bf:case2tex}... Done
  ...
Reinstallation Summary:
  Successfully reinstalled: 28 modules{p_end}

{pstd}
{bf:Checking Installation Status:}

{phang}{cmd:. mysuite}{p_end}
{phang}Running without options shows current installation status:
"SSC modules installed: 18/28" - quickly see what's missing.{p_end}

{pstd}
{bf:Editing Installed Modules:}

{phang}{cmd:. myedit regtex}{p_end}
{phang}After installation, use {help myedit} to view and edit any module's source code.
This is useful for learning, customization, and debugging.{p_end}

{phang}{cmd:. help regtex}{p_end}
{phang}View help documentation for any installed module.{p_end}

{pstd}
{bf:Common Workflows:}

{phang}{cmd:. mysuite}{p_end}
{phang}1. Check what's installed: {cmd:. mysuite}{p_end}

{phang}{cmd:. mysuite, all}{p_end}
{phang}2. Install missing modules: {cmd:. mysuite, all}{p_end}

{phang}{cmd:. mysuite, installed}{p_end}
{phang}3. Verify installation: {cmd:. mysuite, installed}{p_end}

{phang}{cmd:. mysuite, all download}{p_end}
{phang}4. Update all modules: {cmd:. mysuite, all download} (quarterly){p_end}


{marker authors}{...}
{title:Authors}

{pstd}
{help agd2010@yeah.net:Wu Lianghai} (agd2010@yeah.net){p_end}
{pstd}School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}Ma'anshan, Anhui, China{p_end}

{pstd}
{help 2184844526@qq.com:Chen Liwen} (2184844526@qq.com){p_end}
{pstd}School of Business, Anhui University of Technology (AHUT){p_end}
{pstd}Ma'anshan, Anhui, China{p_end}

{pstd}
{help 2325476320@qq.com:Wu Hanyan} (2325476320@qq.com){p_end}
{pstd}School of Economics and Management{p_end}
{pstd}Nanjing University of Aeronautics and Astronautics (NUAA){p_end}
{pstd}Nanjing, Jiangsu, China{p_end}

{pstd}
Development Date: 13 February 2026{p_end}
{pstd}
Version: 1.0 (Smart Installation){p_end}


{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
We would like to express our sincere gratitude to {bf:Christopher F. Baum}! 
Thanks to his enthusiastic support and timely scientific guidance, we have successfully developed a series of intelligent accounting research and teaching toolkits from the end of July 2025 to the present, which have been uploaded to the SSC platform as scheduled.{p_end}


{title:Also see}

{psee}
Online: {help myedit}, {help ssc}, {help adofile}, {help which}
{p_end}