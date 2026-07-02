{smcl}
{* 30Jun2026}{...}
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
teaching management, and academic writing. It provides access to 39 specialized
programs available from the SSC archive.

{pstd}
{bf:Core Features:}

{phang2}
- Centralized module discovery and installation{p_end}
{phang2}
- Smart installation: only installs missing modules (with {opt all}){p_end}
{phang2}
- Force reinstall all 39 modules when needed (with {opt all download}){p_end}
{phang2}
- Installation status checking and reporting{p_end}
{phang2}
- List all currently installed modules (with {opt installed}){p_end}

{pstd}
{bf:Operation Modes:}

{phang2}
{bf:MODE 1 - Display}
  No options specified
  → Show program banner, complete list of 39 modules,
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
  → Display a complete list of all currently installed modules.
     Shows installation count summary (e.g., "24/39 modules installed").{p_end}

{phang2}
{bf:MODE 4 - Force Reinstall}
  {opt all} and {opt download} options combined
  → Force reinstall ALL 39 modules regardless of current installation status.
     Useful for updating to latest versions or fixing corrupted installations.{p_end}


{title:Updates in version 1.1.2}

{pstd}
The following improvements have been made in version 1.1.2:

{phang2}
- Two new modules from the {bf:鼎园会计} (Dingyuan Accounting) team have been
  added to the suite and are now available on SSC:
  {bf:fm} (file classification manager) and
  {bf:varck} (variable existence check).{p_end}
{phang2}
- The {bf:ssc} module has been removed from the suite as it is not an original
  work of the {bf:鼎园会计} (Dingyuan Accounting) team.{p_end}
{phang2}
- Total module count: 39.{p_end}


{title:Updates in version 1.1.1}

{pstd}
The following improvements have been made in version 1.1.1:

{phang2}
- A new module {bf:ccgi} (corporate governance indicator) from the
  {bf:鼎园会计} (Dingyuan Accounting) team has been added to the suite
  and is now available on SSC.{p_end}
{phang2}
- Total module count increased from 38 to 39.{p_end}


{title:Updates in version 1.1.0}

{pstd}
The following improvements have been made in version 1.1.0:

{phang2}
- Three new modules from the {bf:鼎园会计} (Dingyuan Accounting) team have been
  added to the suite and are now available on SSC:
  {bf:editprofile} (Stata profile editor),
  {bf:reduce_aigc} (AIGC text reduction tool), and
  {bf:myinterval} (confidence interval computation).{p_end}
{phang2}
- Total module count increased from 33 to 36.{p_end}


{title:Updates in version 1.0.9}

{pstd}
The following improvements have been made in version 1.0.9:

{phang2}
- {bf:bmc} and {bf:conservatism}, previously distributed as local ado-files,
  are now fully available on SSC and can be installed via {cmd:mysuite, all}.{p_end}
{phang2}
- A new module {bf:polishpaper} (academic paper polishing template) has been
  added to the suite and is available on SSC.{p_end}
{phang2}
- {bf:regtex} and {bf:reg2tex} are bundled in a single SSC package. Typing
  {cmd: ssc desc regtex} and clicking the hyperlink in the results window
  downloads both programs at once.{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt All} installs only missing SSC modules in the mysuite collection.
Checks each module's installation status first and only downloads those not found.
Shows installation progress and summary statistics upon completion.

{phang}
{opt Installed} lists all currently installed modules without making any changes.
Displays each of the 39 modules with "Installed" or "Not installed" status,
followed by a count summary.

{phang}
{opt Download} modifies the behavior of {opt all}. When combined:
- {cmd:mysuite, all} → Install missing modules only
- {cmd:mysuite, all download} → Force reinstall ALL 39 modules


{marker examples}{...}
{title:Examples}

{pstd}
{bf:MODE 1 - Display Program Information:}

{phang}{cmd:. mysuite}{p_end}
{phang}Display program banner, complete module list (39 programs),
current installation status (e.g., "SSC modules installed: 20/39"),
and detailed usage instructions. No modules are downloaded or installed.{p_end}

{pstd}
{bf:MODE 2 - Install Missing Modules:}

{phang}{cmd:. mysuite, all}{p_end}
{phang}Smart installation - checks each of the 39 modules and installs
only those not currently found. Already installed modules are skipped.
Example output:
  {bf:sumtex}: Already installed
  Installing {bf:regtex}... Done
  {bf:estout}: Already installed
Installation Summary:
  Already installed: 30 modules
  Newly installed:   2 modules{p_end}

{pstd}
{bf:MODE 3 - List Installed Modules:}

{phang}{cmd:. mysuite, installed}{p_end}
{phang}Display complete list of currently installed modules:
  {bf:Currently Installed SSC Modules:}
    {bf:art2tex}: Installed
    {bf:case2tex}: Installed
    ...
    {bf:varck}: Not installed
  {bf:Summary:} 24/39 SSC modules installed
Useful for quick inventory of your setup.{p_end}

{pstd}
{bf:MODE 4 - Force Reinstall All Modules:}

{phang}{cmd:. mysuite, all download}{p_end}
{phang}Force reinstall ALL 39 modules regardless of current status.
Use this to update to latest versions or fix corrupted installations.
Example output:
  Reinstalling {bf:art2tex}... Done
  Reinstalling {bf:case2tex}... Done
  ...
Reinstallation Summary:
  Successfully reinstalled: 39 modules{p_end}

{pstd}
{bf:Checking Installation Status:}

{phang}{cmd:. mysuite}{p_end}
{phang}Running without options shows current installation status:
"SSC modules installed: 18/39" - quickly see what's missing.{p_end}

{pstd}
{bf:Editing Installed Modules:}

{phang}{cmd:. myedit regtex}{p_end}
{phang}After installation, use {help myedit} to view and edit any module's source code.
This is useful for learning, customization, and debugging.{p_end}

{phang}{cmd:. help regtex}{p_end}
{phang}View help documentation for any installed module.{p_end}

{pstd}
{bf:Common Workflows:}

{phang}1. Check what's installed: {cmd:. mysuite}{p_end}
{phang}2. Install missing modules: {cmd:. mysuite, all}{p_end}
{phang}3. Verify installation: {cmd:. mysuite, installed}{p_end}
{phang}4. Update all modules (quarterly): {cmd:. mysuite, all download}{p_end}


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
{help 2957833979@qq.com:Wu Xinzhuo} (2957833979@qq.com){p_end}
{pstd}University of Bristol (UB){p_end}
{pstd}Leeds, West Yorkshire, England{p_end}

{pstd}
{help 1536496199@qq.com:Li Juan} (1536496199@qq.com){p_end}
{pstd}Red Cross Society of Ma'anshan City{p_end}
{pstd}Ma'anshan, Anhui, China{p_end}

{pstd}
Development Date: 30 Jun 2026{p_end}
{pstd}
Version: 1.1.2{p_end}


{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
We would like to express our sincere gratitude to {bf:Christopher F. Baum}!
Thanks to his enthusiastic support and timely scientific guidance, we have successfully developed a series of intelligent accounting research and teaching toolkits from the end of July 2025 to the present, which have been uploaded to the SSC platform as scheduled.{p_end}


{title:Also see}

{psee}
Online: {help myedit}, {help editprofile}, {help reduce_aigc}, {help myinterval}, {help ccgi}, {help fm}, {help varck}
{p_end}
{*}
