{smcl}
{* January 30, 2024}
{hline}
Help for {hi:odk_validate} 
{hline}

{title:Description}

{pstd}{cmd:odk_validate} streamlines the survey validation process for users employing ODK/XLSForms for data collection and Stata for subsequent data analysis. It meticulously scans the ODK form for prevalent issues that can often go unnoticed prior to deployment, focusing on:

 {pstd}Duplicate variable names particularly those generated from {it:select_multiple} questions (when such data is subsequently exported in separate columns).
 
 {pstd}Unconstrained integer questions that could lead to data inconsistencies.
 
 {pstd}Required notes that may inadvertently block response uploads.
 
 {pstd}Optional questions at risk of being overlooked or skipped by enumerators.

{pstd}Upon detection of these issues, {cmd:odk_validate} generates a detailed Word report outlining the specific concerns, thus facilitating preemptive corrections prior to survey deployment. 

{title:Syntax}

{pstd}{cmd:odk_validate} [, {help USING}(string)]

{synoptset 20 tabbed}{...}
{marker Options}{...}
{synopthdr:Options}
{synoptline}
{synopt:{opt USING}(string)} Specifies the name of the odk file to be used by the program. The default is set to "odk" if no file is specified. The file must be in the current directory. The extension (xlsx) is not required. {p_end}
{synoptline}
{p 6 2 2}{p_end}

{title:Examples}

{ul:Example 1}

{pstd}Running ODK Validate without specifying a file name (assuming that the odk form already exists in the current directory with the file name "odk.xlsx"){p_end}

{phang2}. {stata odk_validate}{p_end}

{ul:Example #2}

{pstd}Running ODK Validate with a specific survey file name.{p_end}

{phang2}. {stata odk_validate, using(malawi_hfc)}{p_end}

{title:Acknowledgments}

{pstd} Thanks to Prabhmeet Kaur and Zaeen de Souza for their thoughtful and constructive feedback. 

{title:Authors}

{pstd}	Kabira Namit, World Bank
{pstd}  knamit@worldbank.org
{smcl}
