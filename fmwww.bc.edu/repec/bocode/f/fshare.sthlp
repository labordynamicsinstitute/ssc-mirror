*! version 2.1.0 31 Dec 2025
*! fshare - Create course folder structure with syllabus and multiple modules

{smcl}
{* *! version 2.1.0 31 Dec 2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] mkdir" "help mkdir"}{...}
{vieweralsosee "[R] rmdir" "help rmdir"}{...}
{viewerjumpto "Syntax" "fshare##syntax"}{...}
{viewerjumpto "Description" "fshare##description"}{...}
{viewerjumpto "Options" "fshare##options"}{...}
{viewerjumpto "Examples" "fshare##examples"}{...}
{viewerjumpto "Remarks" "fshare##remarks"}{...}
{viewerjumpto "Authors" "fshare##authors"}{...}
{title:Title}

{p 4 4 2}
{bf:fshare} - Create course folder structure with syllabus and multiple modules

{p 4 4 2}
{bf:Keywords:} directory, folder, structure, course, syllabus, module

{p 4 4 2}
{bf:Category:} Utilities, File management

{marker syntax}{title:Syntax}

{p 8 16 2}
{cmd:fshare} {it:path} [{cmd:,} {opt module(numlist)} {opt m(numlist)} {opt language(string)} {opt stata}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt module(numlist)}}Specify module numbers (default: 1){p_end}
{synopt:{opt m(numlist)}}Short form of {opt module()}{p_end}
{synopt:{opt language(string)}}Language for folder names: 'cn' (Chinese, default) or 'en' (English){p_end}
{synopt:{opt stata}}Create Stata subfolder structure within each module{p_end}
{synoptline}

{marker description}{title:Description}

{p 4 4 2}
{cmd:fshare} creates a standardized course folder structure at the specified path. 
This is particularly useful for educators and course administrators who need to 
organize teaching materials in a consistent manner.

{p 4 4 2}
The program creates the following folder structure:

{p 8 12 2}
• Main directory (specified by {it:path}){p_end}
{p 8 12 2}
• {bf:Syllabus/} (Chinese: {bf:教学大纲/}) folder{p_end}
{p 8 12 2}
• {bf:Module#/} (Chinese: {bf:模块#/}) folders for each specified module number{p_end}
{p 8 16 2}
├─ {bf:Cases/} (Chinese: {bf:案例/}){p_end}
{p 8 16 2}
├─ {bf:Slides/} (Chinese: {bf:幻灯片/}){p_end}
{p 8 16 2}
├─ {bf:Lectures/} (Chinese: {bf:教案/}){p_end}
{p 8 16 2}
├─ {bf:Papers/} (Chinese: {bf:论文/}){p_end}
{p 8 16 2}
└─ {bf:Stata/} (if stata option is specified){p_end}
{p 8 20 2}
├─ {bf:Data/} (Chinese: {bf:数据/}){p_end}
{p 8 20 2}
├─ {bf:Models/} (Chinese: {bf:模型/}){p_end}
{p 8 20 2}
├─ {bf:Programs/} (Chinese: {bf:程序/}){p_end}
{p 8 20 2}
└─ {bf:Reports/} (Chinese: {bf:报告/}){p_end}

{p 4 4 2}
When the {opt stata} option is specified, the {bf:Programs/} subfolder includes a 
pre-configured {bf:mytools.do} file with the following content:

{cmd}
/* Developed SSC online ado programs: 
    art2tex; case2tex; area; qta; eui; ……; tab2excel; myedit.
*/ 
 
* Download methods   
    ssc install myedit  
    ssc install art2tex, replace  
    ssc new  
    ssc hot  
    ssc desc tab2excel
{txt}

{marker options}{title:Options}

{phang}
{opt module(numlist)} specifies the module numbers to create. The default is 1. 
Multiple modules can be specified using numlist syntax (e.g., 1 3 5 or 1/5).

{phang}
{opt m(numlist)} is the short form of {opt module()}.

{phang}
{opt language(string)} specifies the language for folder names. 
Valid options are 'cn' for Chinese (default) and 'en' for English.

{phang}
{opt stata} creates an additional Stata subfolder structure within each module.
The Stata folder includes four subfolders: Data, Models, Programs, and Reports.
The Programs subfolder contains a pre-configured {bf:mytools.do} file with 
useful Stata commands and SSC package references.

{marker examples}{title:Examples}

{p 4 4 2}
{bf:Basic usage}{p_end}

{p 8 12 2}
Create default folder structure with one module:{p_end}
{phang2}{cmd:. fshare D:/MyCourse}{p_end}

{p 8 12 2}
Create folder structure with module 2:{p_end}
{phang2}{cmd:. fshare "D:/My Course", m(2)}{p_end}

{p 4 4 2}
{bf:Multiple modules}{p_end}

{p 8 12 2}
Create modules 1, 3, and 5:{p_end}
{phang2}{cmd:. fshare "D:/My Course", m(1 3 5)}{p_end}

{p 8 12 2}
Create modules 1 through 3:{p_end}
{phang2}{cmd:. fshare "D:/MyCourse", m(1/3)}{p_end}

{p 4 4 2}
{bf:Advanced options}{p_end}

{p 8 12 2}
Use English folder names:{p_end}
{phang2}{cmd:. fshare "D:/My Course", m(1 2) language(en)}{p_end}

{p 8 12 2}
Chinese course with multiple modules:{p_end}
{phang2}{cmd:. fshare "D:/智能财务共享理论与实务课程", m(2 4 6) language(cn)}{p_end}

{p 8 12 2}
Create folder structure with Stata subfolders:{p_end}
{phang2}{cmd:. fshare "D:/MyCourse", m(1) stata}{p_end}

{p 8 12 2}
Create multiple modules with Stata subfolders in English:{p_end}
{phang2}{cmd:. fshare "D:/MyCourse", m(1 2 3) language(en) stata}{p_end}

{marker remarks}{title:Remarks}

{p 4 4 2}
{bf:1. Safety features}{p_end}
{p 8 12 2}
• If a directory already exists, the program displays a message and skips creation{p_end}
{p 8 12 2}
• If files with the same name as directories exist, the program terminates with an error{p_end}
{p 8 12 2}
• No replace option is available to prevent accidental data loss{p_end}

{p 4 4 2}
{bf:2. Error handling}{p_end}
{p 8 12 2}
• If directory creation fails, detailed error messages are displayed{p_end}
{p 8 12 2}
• Common issues include permission problems, invalid characters, or full disks{p_end}

{p 4 4 2}
{bf:3. Language support}{p_end}
{p 8 12 2}
• Chinese mode: creates folders with Chinese names (教学大纲, 模块#, 案例, 幻灯片, 教案, 论文, stata, 数据, 模型, 程序, 报告){p_end}
{p 8 12 2}
• English mode: creates folders with English names (Syllabus, Module#, Cases, Slides, Lectures, Papers, stata, data, models, programs, reports){p_end}

{p 4 4 2}
{bf:4. Stata option}{p_end}
{p 8 12 2}
• When the {opt stata} option is used, an additional "stata" folder is created in each module{p_end}
{p 8 12 2}
• The stata folder contains four subfolders: data, models, programs, and reports{p_end}
{p 8 12 2}
• The programs subfolder includes a pre-configured {bf:mytools.do} file with useful Stata commands{p_end}
{p 8 12 2}
• The mytools.do file includes references to SSC packages: {help art2tex:art2tex}, {help case2tex:case2tex}, {help area:area}, {help qta:qta}, {help eui:eui}, {help tab2excel:tab2excel}, {help myedit:myedit}{p_end}

{p 4 4 2}
{bf:5. Path formatting}{p_end}
{p 8 12 2}
• Both forward slashes (/) and backslashes (\) are accepted{p_end}
{p 8 12 2}
• Paths with spaces should be enclosed in quotes{p_end}
{p 8 12 2}
• Relative paths are supported{p_end}

{p 4 4 2}
{bf:6. Windows read-only folder issue}{p_end}
{p 8 12 2}
• On Windows systems, newly created folders may sometimes have read-only attributes{p_end}
{p 8 12 2}
• This can prevent subsequent folder creation or deletion operations{p_end}
{p 8 12 2}
• To fix: Right-click folder → Properties → Uncheck 'Read-only' → Apply{p_end}

{marker authors}{title:Authors}

{p 4 4 2}
Wu Lianghai{p_end}
{p 8 12 2}
School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{p_end}
{p 8 12 2}
Email: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{p 4 4 2}
Chen Liwen{p_end}
{p 8 12 2}
School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{p_end}
{p 8 12 2}
Email: {browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}

{p 4 4 2}
Wu Hanyan{p_end}
{p 8 12 2}
School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA), Nanjing, China{p_end}
{p 8 12 2}
Email: {browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{p 4 4 2}
Liu Rui{p_end}
{p 8 12 2}
School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{p_end}
{p 8 12 2}
Email: {browse "mailto:3221241855@qq.com":3221241855@qq.com}{p_end}

{marker also_see}{title:Also see}

{p 4 4 2}
Manual: {bf:[R] mkdir}, {bf:[R] rmdir}{p_end}
{p 4 4 2}
Online: {browse "https://www.stata.com":Stata website}{p_end}

{marker citation}{title:Citation}

{p 4 4 2}
If you use {cmd:fshare} in your work, please cite it as:{p_end}

{p 8 12 2}
Wu Lianghai, Chen Liwen, Wu Hanyan, & Liu Rui. (2025). fshare: Stata module for creating course folder structure. 
Version 2.1.0. Anhui University of Technology and Nanjing University of Aeronautics and Astronautics.{p_end}

{title:Version history}

{p 4 4 2}
{bf:2.1.0} (31 Dec 2025){p_end}
{p 8 12 2}
• Added {opt stata} option to create Stata subfolder structure{p_end}
{p 8 12 2}
• Added short forms for options: {opt m()} for module{p_end}
{p 8 12 2}
• Removed replace option for safety{p_end}
{p 8 12 2}
• Added multiple authors{p_end}
{p 8 12 2}
• Updated documentation{p_end}

{p 4 4 2}
{bf:2.0.13} (31 Dec 2025){p_end}
{p 8 12 2}
• Added warnings about Windows read-only folder issues{p_end}
{p 8 12 2}
• Improved documentation for folder permission problems{p_end}

{p 4 4 2}
{bf:2.0.12} (30 Dec 2025){p_end}
{p 8 12 2}
• Fixed main directory creation logic when directory already exists{p_end}
{p 8 12 2}
• Improved error messages in English mode{p_end}

{title:Technical support}

{p 4 4 2}
For technical support or bug reports, please contact the authors at 
{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}, 
{browse "mailto:2184844526@qq.com":2184844526@qq.com}, 
{browse "mailto:2325476320@qq.com":2325476320@qq.com}, or
{browse "mailto:3221241855@qq.com":3221241855@qq.com}.{p_end}

{hline}
{pstd}
{it:This help file was generated on 31 Dec 2025.}
{*}