{smcl}
{title:MCHS Stata file/CLI boundary adapter}

{pstd}Delegates MCHS workflows to the external CLI/file boundary. No formula logic is implemented in this ado adapter.

{title:Syntax}

{p 8 12 2}{cmd:mchs import using} {it:results.csv} [{cmd:, clear saveas(}{it:results.dta}{cmd:) replace}]

{p 8 12 2}{cmd:mchs run using} {it:input.csv}{cmd:, calculator(}{it:id}{cmd:) year(}{it:YYYY}{cmd:) output(}{it:results.csv}{cmd:)} [{cmd:import clear replace cli(}{it:command}{cmd:)}]

{p 8 12 2}{cmd:mchs validate} [{cmd:, required(}{it:varlist}{cmd:)}]

{title:Description}

{pstd}{cmd:mchs import} imports a shared-core CSV result into Stata and can save a native {cmd:.dta} copy for downstream analysis.

{pstd}{cmd:mchs run} invokes the shared-core CLI through Stata's shell boundary, confirms the output file exists, and can immediately import that output. The default CLI command is {cmd:funding-calculator}.

{pstd}{cmd:mchs validate} checks that imported file-boundary outputs contain provenance columns. By default it requires {cmd:contract_version}, {cmd:calculator_id}, {cmd:pricing_year}, and {cmd:fixture_gate}.

{title:Examples}

{phang2}{cmd:. mchs import using "results.csv", clear}

{phang2}{cmd:. mchs run using "acute_input.csv", calculator(acute) year(2025) output("acute_results.csv") replace import clear}

{phang2}{cmd:. mchs validate}
