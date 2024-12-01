{smcl}
{cmd:help topsis }
{hline}

{title:Title}

{p2colset 5 16 16 2}{...}
{p2col:{hi: topsis}   {hline 2}}Calculation  comprehensive scores based on the entropy method or the entropy-TOPSIS method
{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}{cmd:topsis} [{cmd:,} {cmdab:positive(}{it:varlist}{cmd:)} {cmdab:negative(}{it:varlist}{cmd:)} {cmdab:topsis}]

{synoptset 10}
{synoptline}
{synopthdr:Options}
{synoptline}
{synopt:{cmdab:positive(}{it:varlist}{cmd:)}} Specifies the list of positive indicators.{p_end}
{synopt:{cmdab:negative(}{it:varlist}{cmd:)}} Specifies the list of negative indicators.{p_end}
{synopt:{cmdab:topsis}}   Uses the TOPSIS method to calculate the comprehensive score.{p_end}
{synoptline}

{title:Notes}

{pstd}o 1. Combined Input Support: The topsis command supports the combined input of positive and negative indicators. If no indicators are specified, the program will return an error message.{p_end}

{pstd}o 2. Correct Variable Naming: Users should ensure the correctness of variable names when inputting positive and negative indicators, and avoid duplication to prevent program errors or inaccurate calculations.{p_end}

{pstd}o 3. Numeric Variables: All input variables should be numeric. Non-numeric variables may lead to program errors or abnormal calculations.{p_end}

{pstd}o 4. TOPSIS Option: When using the topsis option, the program will further calculate the comprehensive score based on the entropy-TOPSIS method.{p_end}

{title:Description}

{pstd}{cmd:topsis} is used to calculate comprehensive scores based on the entropy method or the TOPSIS method.{p_end}

{pstd}This command allows users to specify both positive and negative indicators, and automatically performs data normalization, calculates information entropy, redundancy, and weights, and finally calculates a comprehensive score.{p_end}
{pstd}Additionally, the program can use the TOPSIS method to calculate the score (optional, depending on user preference).{p_end}

{pstd}If the {cmd:topsis} option is not used, the program will output the information entropy, redundancy, and weights of each indicator, and by default, display the comprehensive scores for the first 10 samples.{p_end}

{pstd}Users can also view stored return values, the complete list of comprehensive scores, and descriptive statistical analysis results by clicking the links in the Stata results window.{p_end}

{pstd}If the {cmd:topsis} option is used, the program will display the comprehensive scores based on the entropy-TOPSIS method and provide descriptive statistical analysis.{p_end}

{title:Friendly Reminder}

{pstd}o (1) Normalization: {p_end}
{pstd}The program will automatically normalize the input data. If the maximum and minimum values of a variable are the same, the normalized result will be set to 0.5 to avoid division by zero. Additionally, normalized values of 0 are replaced with 0.0001 to prevent errors such as {cmd:ln(0)} during calculations.{p_end}

{pstd}o (2) Temporary Variables: {p_end}
{pstd}The command will generate many temporary variables upon execution, so when running the command a second time, you need to manually delete the temporary variables.{p_end}
{pstd}You can manually select and delete the temporary variables in the variable window, or use {stata "preserve"} before executing the command and {stata "restore"} afterward to restore the original data.{p_end}

{pstd}o (3) Consistency of Units: {p_end}
{pstd}  The units of the indicators should be consistent or properly normalized to ensure the comparability and scientific validity of the results. Indicators with different units may result in unreasonable comprehensive scores.{p_end}

{pstd}o (4) TOPSIS Data Quality: {p_end}
{pstd} When using the TOPSIS method, the quality and appropriateness of both positive and negative indicators should be ensured to guarantee valid results, especially avoiding extreme values that could adversely affect the calculations.{p_end}

{pstd}o (5) Data Cleaning Recommendations:{p_end} 
{pstd} It is recommended to handle missing values and outliers in the input data before executing {cmd:topsis} to ensure the accuracy of the calculations and results.{p_end}

{pstd}o (6) Data Backup: {p_end}
{pstd}It is advisable to back up the current dataset (e.g., using {stata "preserve"}) before executing the {cmd:topsis} command to prevent data loss in case of improper command execution.{p_end}

{title:Examples}

{pstd}{bf:Note: When running the new command again, you must manually delete the new temporary variables or use the preserve and restore commands in advance. Otherwise, the program topsis will report an error}{p_end}

{marker example1：}{...}
{title:Example 1：Basic Usage: citytemp4 Dataset Case}

{pstd}{bf:Setup}{p_end}
{phang2}{stata sysuse citytemp4.dta, clear}{p_end}
{phang2}Or enter (cnuse is an external command that needs to be downloaded, and can be installed using {stata "ssc install cnuse, replace"}){p_end}
{phang2}{stata cnuse citytemp4.dta, clear}{p_end}

{pstd}{bf:* Drop missing values}{p_end}
{phang2}{stata drop if missing(heatdd)}{p_end}

{pstd}{bf:* Perform entropy method operations assuming heatdd and tempjuly are positive indicators, cooldd and tempjan are negative indicators}{p_end}
{phang2}{stata topsis, positive(heatdd tempjuly) negative(cooldd tempjan)}{p_end}

{marker example2}{...}
{title:Example 2: Further usage：TOPSIS Dataset Case}

{pstd}{bf:* Setup}{p_end}
{phang2}{stata cnuse topsis1.dta, clear}{p_end}

{pstd}{bf:* Use topsis command for entropy analysis}{p_end}
{phang2}{stata preserve}{p_end}
{phang2}{stata topsis, positive(x3 x4 x5 x6) negative(x1 x2)}{p_end}

{pstd}{bf:* View comprehensive score results}{p_end}
{phang2}{stata list Score in 1/10}{p_end}
{phang2}{stata sum Score, detail}{p_end}

{pstd}{bf:* Stata stored return values view}{p_end}
{phang2}{stata return list}{p_end}
{phang2}{stata mat list r(E)}{p_end}
{phang2}{stata mat list r(D)}{p_end}
{phang2}{stata mat list r(W)}{p_end}
{phang2}{stata restore }{p_end}

{pstd}{bf:* Perform entropy-TOPSIS method analysis}{p_end}
{pstd}{bf:* Note: You must manually delete the new temporary variables or use the preserve and restore commands in advance.}{p_end}
{phang2}{stata topsis, positive(x3 x4 x5 x6) negative(x1 x2) topsis}{p_end}

{marker results}{title:Stored Results}

{pstd}{cmd:topsis} will store the following items in {cmd:r()}: {p_end}

{phang}Matrices{p_end}
{pmore}  {cmd:r(E)}: Stores information entropy.{p_end}
{pmore}  {cmd:r(D)}: Stores redundancy coefficients.{p_end}
{pmore}  {cmd:r(W)}: Stores weights.{p_end}

{pstd}These three results are hyperlinked in the command execution section. You can also enter {stata "return list"} to see the stored Stata return values and use {cmd:mat list} to view the stored results.{p_end}

{pstd}For example, enter {stata "mat list r(E)"} to view information entropy, {stata "mat list r(D)"} to view redundancy coefficients, and {stata "mat list r(W)"} to view weights.{p_end}

{marker author}{title:Author}

{phang}Wang Qiang, Xi'an Jiaotong University, China.{break}

{marker issues}{title:Questions and Suggestions}

{pstd}If you have any questions or suggestions, please send an email to: {browse "740130359@qq.com":740130359@qq.com}. {break}{p_end}

{marker also_see}{title:Also see}

{psee}{help cnuse} (if installed), {help enwei} (if installed), {help entropy} (if installed){p_end}

