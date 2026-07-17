{smcl}
{* *! version 1.0.0  15jul2026}{...}
{cmd:help okpreserve}{right: VVK}
{hline}

{title:Title}

{p2colset 5 25 27 2}{...}
{p2col:{bf:okpreserve}/{bf:okrestore}}{hline 2}Nested preserve and restore for data workflows{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:okpreserve}

{p 8 16 2}
{cmd:okrestore}


{title:Description}

{pstd}
{cmd:okpreserve} and {cmd:okrestore} provide a solution for managing 
complex, multi-level data transformations in Stata. These commands enable 
true nested preservation of data states, which is essential when your 
analysis involves multiple stages of data aggregation, filtering, and 
transformation.

{pstd}
Unlike Stata{c 39}s built-in {cmd:preserve}/{cmd:restore}, which do not 
support nesting, {cmd:okpreserve}/{cmd:okrestore} maintain a stack of 
saved data states. This allows you to work with different levels of data 
granularity within a single do-file.


{title:Key Features}

{phang}
{bf:Nested Levels}: Save and restore data at multiple levels simultaneously
{p_end}

{phang}
{bf:Stack-Based}: Each level is independent and fully preserves state
{p_end}

{phang}
{bf:Memory Efficient}: Uses tempfiles, no duplicate in-memory datasets
{p_end}

{phang}
{bf:Easy to Use}: Simple two-command workflow (okpreserve / okrestore)
{p_end}


{title:Motivation}

{pstd}
Complex econometric analyses often require working with data at multiple 
levels of aggregation:

{phang2}
{c 183} Individual-level data
{p_end}

{phang2}
{c 183} Collapse to state-year for regression
{p_end}

{phang2}
{c 183} Further subset for heterogeneity checks
{p_end}

{phang2}
{c 183} Return to original for next analysis
{p_end}

{pstd}
{cmd:okpreserve} makes this workflow seamless and error-free.


{title:Workflow}

{pstd}
Use {cmd:okpreserve} before making changes to your data. Use {cmd:okrestore} 
to restore to the most recently saved state.

{pstd}
{bf:Important:} Each {cmd:okpreserve} increments the nesting level; each 
{cmd:okrestore} restores and decrements. Use LIFO order (Last In, First Out).


{title:Example 1: Single-Level Preserve and Restore}

{pstd}
Preserve original data, filter, analyze, and restore:

{phang2}
. use auto.dta
{p_end}

{phang2}
. display "Original N = " _N
{p_end}

{phang2}
. okpreserve
{p_end}

{phang2}
. keep if price > 5000
{p_end}

{phang2}
. display "Filtered N = " _N
{p_end}

{phang2}
. summarize price
{p_end}

{phang2}
. okrestore
{p_end}

{phang2}
. display "Restored N = " _N
{p_end}

{pstd}
{bf:Expected Output:}

{phang2}
Original N = 74
{p_end}

{phang2}
Filtered N = 37
{p_end}

{phang2}
Restored N = 74
{p_end}


{title:Example 2: Two-Level Nested Preserve and Restore}

{pstd}
Collapse to state-year level, then subset by year:

{phang2}
. use mydata.dta
{p_end}

{phang2}
. display "Level 0 (Individual): " _N
{p_end}

{phang2}
. okpreserve
{p_end}

{phang2}
. collapse (sum) income (mean) age, by(state year)
{p_end}

{phang2}
. display "Level 1 (Collapsed): " _N
{p_end}

{phang2}
. okpreserve
{p_end}

{phang2}
. keep if year > 2015
{p_end}

{phang2}
. regress income age
{p_end}

{phang2}
. eststo model_recent
{p_end}

{phang2}
. okrestore
{p_end}

{phang2}
. display "Back to Level 1: " _N
{p_end}

{phang2}
. okrestore
{p_end}

{phang2}
. display "Back to Level 0: " _N
{p_end}

{pstd}
{bf:Expected Output:}

{phang2}
Level 0 (Individual): 50,000 obs
{p_end}

{phang2}
Level 1 (Collapsed): 200 obs
{p_end}

{phang2}
Restored to Level 1: 200 obs
{p_end}

{phang2}
Restored to Level 0: 50,000 obs
{p_end}


{title:Example 3: Three-Level Nested Preserve and Restore}

{pstd}
Full workflow: individual {c 174} collapsed {c 174} filtered {c 174} cleaned

{phang2}
. use mydata.dta
{p_end}

{phang2}
. display "Level 0 (Original): " _N
{p_end}

{phang2}
. okpreserve
{p_end}

{phang2}
. collapse (mean) price mpg, by(foreign)
{p_end}

{phang2}
. display "Level 1 (Collapsed): " _N
{p_end}

{phang2}
. okpreserve
{p_end}

{phang2}
. keep if foreign == 1
{p_end}

{phang2}
. display "Level 2 (Foreign only): " _N
{p_end}

{phang2}
. okpreserve
{p_end}

{phang2}
. drop if missing(price)
{p_end}

{phang2}
. display "Level 3 (No missing): " _N
{p_end}

{phang2}
. summarize price mpg
{p_end}

{phang2}
. eststo foreign_clean
{p_end}

{phang2}
. okrestore
{p_end}

{phang2}
. display "Restored to Level 2: " _N
{p_end}

{phang2}
. okrestore
{p_end}

{phang2}
. display "Restored to Level 1: " _N
{p_end}

{phang2}
. okrestore
{p_end}

{phang2}
. display "Restored to Level 0: " _N
{p_end}

{pstd}
{bf:Expected Output Flow:}

{phang2}
Level 0 (Original): 74 obs
{p_end}

{phang2}
Level 1 (Collapsed): 2 obs
{p_end}

{phang2}
Level 2 (Foreign = 1): 1 obs
{p_end}

{phang2}
Level 3 (No missing): 1 obs {c 174} Analysis performed here
{p_end}

{phang2}
Restored to Level 2: 1 obs
{p_end}

{phang2}
Restored to Level 1: 2 obs
{p_end}

{phang2}
Restored to Level 0: 74 obs
{p_end}


{title:Use Cases}

{pstd}
{bf:Staggered Difference-in-Differences Analysis}

{phang2}
{c 183} Load individual-level data with treatment assignment and outcomes
{p_end}

{phang2}
{c 183} Collapse to state-year level for main DiD regression
{p_end}

{phang2}
{c 183} Subset by demographic groups for heterogeneity analysis
{p_end}

{phang2}
{c 183} Return to original data for robustness checks
{p_end}

{pstd}
{bf:Multi-Stage Data Pipelines}

{phang2}
{c 183} Load raw administrative data
{p_end}

{phang2}
{c 183} Clean and validate (preserve original safely)
{p_end}

{phang2}
{c 183} Aggregate to analysis level
{p_end}

{phang2}
{c 183} Conduct sensitivity analyses at different granularity levels
{p_end}


{title:Technical Notes}

{pstd}
{cmd:okpreserve} uses temporary files to store data snapshots. Each level 
maintains its own state independently. The nesting level is tracked globally 
as {cmd:$vpres_cnt}. Do not modify this global manually.


{title:Author}

{pstd}
Vikrant V. Kamble

{pstd}
Economics PhD Candidate, University of Delaware, USA

{pstd}
Former Short-Term Consultant, World Bank Group, Washington, DC

{pstd}
{it:Email: vvkamble@udel.edu}

{pstd}
{bf:Version 1.0.0} — July 15, 2026