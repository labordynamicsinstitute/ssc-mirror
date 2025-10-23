{smcl}
{* *! version 1.5.8 22Oct2025}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "bf##syntax"}{...}
{viewerjumpto "Description" "bf##description"}{...}
{viewerjumpto "Options" "bf##options"}{...}
{viewerjumpto "Examples" "bf##examples"}{...}
{viewerjumpto "Example Session" "bf##examplesession"}{...}
{title:Title}

{phang}
{bf:bf} {hline 2} Create directory structure for Dingyuan Accounting academic projects

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:bf} {it:issue} [{cmd:,} {opt lang*uage:(string)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt lang*uage:(string)}}specify language for directory names (en/cn); may be abbreviated to {bf:lang}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:bf} creates a standardized directory structure for Dingyuan Accounting academic projects.
The command automatically detects available hard drives and prioritizes E drive, then D drive,
avoiding the system C drive (unless only C drive is available).

{pstd}
The {opt language()} option allows creating directory structures with either English or Chinese names.

{pstd}
If directories already exist, they will be overwritten/recreated to ensure a clean setup.

{pstd}
The command also creates ready-to-run do files in each subdirectory that demonstrate a complete
data analysis workflow using Stata's built-in auto dataset.

{pstd}
Version 1.5.8 adds example session display and improves error handling for log files and model results.

{marker options}{...}
{title:Options}

{phang}
{it:issue} specifies the issue number for creating the corresponding directory name.

{phang}
{opt lang*uage:(string)} specifies the language for directory names. Valid values are:
{p_end}
{pmore}{opt en}: English directory names (default){p_end}
{pmore}{opt cn}: Chinese directory names{p_end}
{pmore}Minimum abbreviation is {bf:lang}.{p_end}

{marker examples}{...}
{title:Examples}

{phang}
{stata "bf 202501"}

{pstd}
Create directory structure for Dingyuan Accounting Issue 202501 with English names.

{phang}
{stata "bf 202501, lang(en)"}

{pstd}
Create directory structure for Dingyuan Accounting Issue 202501 with English names (using abbreviation).

{phang}
{stata "bf 202501, language(cn)"}

{pstd}
Create directory structure for Dingyuan Accounting Issue 202501 with Chinese names.

{marker examplesession}{...}
{title:Example Session}

{pstd}
After running the {cmd:bf} command, you will see an example session showing how to execute the complete analysis workflow:

{cmd}
. bf 202512, lang(cn)
D:\益友学术\鼎园会计 202512

Current working directory: D:\益友学术\鼎园会计 202512

Dingyuan Accounting Issue 202512 workspace created successfully!
Includes the following subdirectories: 模型 数据 程序 报告
Ready-to-run do files have been created in each subdirectory.
Execution order: 1. data 2. program 3. model 4. report
You can run the complete analysis by executing the report generation do file.

{hline 60}
Example Session:
{hline 60}
To run the complete analysis workflow, use the following commands:

1. Create data management:
    do "D:\益友学术\鼎园会计 202512\数据\数据管理.do"

2. Define programs:
    do "D:\益友学术\鼎园会计 202512\程序\程序定义.do"

3. Run model estimation:
    do "D:\益友学术\鼎园会计 202512\模型\模型估计.do"

4. Generate final report:
    do "D:\益友学术\鼎园会计 202512\报告\报告生成.do"

Or run only the report generation to execute all steps automatically:
    do "D:\益友学术\鼎园会计 202512\报告\报告生成.do"
{hline 60}
{txt}

{pstd}
The command creates the following directory structure on the selected drive:{p_end}
{pstd}English structure:{p_end}
{pstd}1. Academic Friends - base directory{p_end}
{pstd}2. Dingyuan Accounting [issue] - project directory{p_end}
{pstd}3. model - for statistical models{p_end}
{pstd}4. data - for datasets{p_end}
{pstd}5. program - for Stata do-files{p_end}
{pstd}6. report - for reports and outputs{p_end}

{pstd}Chinese structure:{p_end}
{pstd}1. 益友学术 - base directory{p_end}
{pstd}2. 鼎园会计 [issue] - project directory{p_end}
{pstd}3. 模型 - for statistical models{p_end}
{pstd}4. 数据 - for datasets{p_end}
{pstd}5. 程序 - for Stata do-files{p_end}
{pstd}6. 报告 - for reports and outputs{p_end}

{title:Ready-to-Run Do Files}

{pstd}
The command creates the following ready-to-run do files in each subdirectory:{p_end}

{pstd}{bf:data/} directory:{p_end}
{pmore}{bf:data_management.do} or {bf:数据管理.do} - Loads and processes the auto dataset, creates new variables{p_end}

{pstd}{bf:program/} directory:{p_end}
{pmore}{bf:program_definition.do} or {bf:程序定义.do} - Defines reusable programs for data description and regression analysis{p_end}

{pstd}{bf:model/} directory:{p_end}
{pmore}{bf:model_estimation.do} or {bf:模型估计.do} - Runs statistical models, performs diagnostics, and saves results in both Stata (.ster) and text (.txt) formats{p_end}

{pstd}{bf:report/} directory:{p_end}
{pmore}{bf:report_generation.do} or {bf:报告生成.do} - Generates tables, graphs, and final reports{p_end}

{title:Data Analysis Workflow}

{pstd}
The do files demonstrate a complete analysis workflow that can be run immediately:{p_end}
{pstd}1. Run {bf:data_management.do} first to process the data{p_end}
{pstd}2. Run {bf:program_definition.do} to define analysis programs{p_end}
{pstd}3. Run {bf:model_estimation.do} to estimate models (automatically runs previous steps){p_end}
{pstd}4. Run {bf:report_generation.do} to generate final outputs (automatically runs all previous steps){p_end}

{pstd}
All do files use absolute paths to ensure they can be run from any location and will find all required files.

{title:Execution Options}

{pstd}
Users can run the do files in two ways:{p_end}
{pstd}{bf:Option 1:} Run files individually in sequence{p_end}
{pstd}{bf:Option 2:} Run only the report generation file, which automatically calls all previous steps{p_end}

{title:Drive Selection Algorithm}

{pstd}
The command uses the following algorithm to select the appropriate drive:{p_end}
{pstd}1. Prefer E drive if available{p_end}
{pstd}2. Then prefer D drive if available{p_end}
{pstd}3. Then any non-C drive{p_end}
{pstd}4. Finally use C drive if no other options{p_end}

{title:Program Definitions}

{pstd}
The program definition do file creates two reusable programs:{p_end}
{pmore}{bf:describe_data} - Provides comprehensive data description with describe, summarize, and tabstat{p_end}
{pmore}{bf:run_regression} - Runs regression analysis and stores estimates{p_end}

{title:Output Files}

{pstd}
The analysis workflow generates the following output files:{p_end}
{pmore}{bf:auto_processed.dta} - Processed dataset in data directory{p_end}
{pmore}{bf:model_results.ster} - Model estimates in Stata format (for internal use){p_end}
{pmore}{bf:regression_results.txt} - Regression results in text format (readable){p_end}
{pmore}{bf:analysis_report.log} - Complete analysis log{p_end}
{pmore}{bf:descriptive_stats.rtf} - Descriptive statistics table{p_end}
{pmore}{bf:regression_results.rtf} - Regression results table{p_end}
{pmore}{bf:price_mpg_scatter.png} - Scatter plot of price vs MPG{p_end}
{pmore}{bf:price_weight_scatter.png} - Scatter plot of price vs weight{p_end}

{title:Authors}

{pstd}
Wu Lianghai{p_end}
{pstd}School of Business, Anhui University of Technology(AHUT), Ma'anshan, China{p_end}
{pstd}E-mail:{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
Chen Liwen{p_end}
{pstd}School of Business, Anhui University of Technology(AHUT), Ma'anshan, China{p_end}
{pstd}E-mail:{browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}

{pstd}
Wu Hanyan{p_end}
{pstd}School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA), Nanjing, China{p_end}
{pstd}E-mail:{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{title:Acknowledgments}

{pstd}
We sincerely appreciate Christopher F. Baum for his prompt guidance and revision suggestions.

{title:Also see}

{pstd}
Online: {help mkdir}, {help cd}
{*}