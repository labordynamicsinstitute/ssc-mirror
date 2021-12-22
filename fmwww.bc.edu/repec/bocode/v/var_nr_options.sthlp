{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr_options} {hline 2}} Set options for var_nr Toolbox SVAR identification and analysis
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr_options}
{cmd:,}
{cmd:}
{opt opt:name("string")}
[{opt ident("string")}
{opt nsteps(num)}
{opt impact(num)}
{opt shut(num)}
{opt pctg(num)}
{opt method("string")}
{opt savefmt("string")}
{opt shckplt("string")}
{opt ndraws(num)}
{opt errlmt(num)}
{opt updtfrqcy(num)}
{opt updt("string")}]


{marker description}{...}
{title:Description}


{pstd}
{cmd:var_nr_options} is used to change the specifications for the named set of 
options specified in {opt opt:name} and generated by {help var_nr:var_nr}. When 
{help var_nr:var_nr} is run, options are set to defaults, which are listed below.
Options for {cmd:var_nr_options} correspond to the options set in {opt opt:name},
and the value specified in parentheses is what the setting will be changed to.

{pstd}
For example,
if the user runs "{it:var_nr_options, opt("my_options") ident("sr") savefmt("gph")}",
then the options object "{it:my_options}" will be changed such that 
the identification method is set to short-run zero restrictions ({it:ident=="sr"}) 
and the file format to auto-save generated plots is set to .gph (Stata graph). 



{dlgtab:Options}

{phang}
{opt ident} specifies the method used to identify the model.
This option will accept one of three strings: "{it:oir}", "{it:bq}", or 
"{it:sr}". "{it:oir}" specifies zero short-run restrictions; "{it:bq}" 
specifies zero long-run restrictions; and "{it:sr}" specifies sign 
restrictions (pure and/or narrative).

{phang}
{opt nsteps} specifies the number of steps for which, or the maximum horizon out
to which, impulse responses are calculated (must be positive integer).

{phang}
{opt impact} sets the size of the shock for the impulse. Options are 0 or 1. 
If it is set to "{it:0}" then shock is one standard deviation. If it is set to 
"{it:1}" the shock is 1.

{phang}
{opt shut} specifies if there is a row of the inverse-A matrix to be set to 0. 
Options are 0 or 1, where 1 specifies that a row be shut.

{phang}
{opt pctg} specifies the size of the confidence bands to be plotted. For example, 
if {it:95} is specified, then a 95% confidence interval is plotted for IRFs and 
FEVDs.

{phang}
{opt method} specifies the method for calculating the uncertainty. If "{it:bs}" 
is specified, then the error is calculated using the residuals to 
calculate bootstraps. If "{it:wild}" is specified, then the error is calculated 
using a wild bootstrap based on a simple distribution using Rademacher weights.

{phang}
{opt savefmt} (stored in Mata as {it:save_fmt}) specifies what format plots should 
be saved to the current working directory in, if any. The default setting is "none", 
which indicates that plots should not be auto-saved when plotted. This setting 
can be changed to any file format that Stata graphs can be saved in, such as "png" 
or "gph".

{phang}
{opt shckplt} (stored in Mata as {it:shck_plt}) indicates which variable or 
structural shock the IRF, FEVD, or HD should be plotted for. The default setting 
is "all", which indicates that plots should be generated for all variables or 
shocks. For example, if the user runs a VAR on variables {it:inflation} and 
{it:unemployment}, identifies the VAR with sign restrictions, and names the shocks 
"Supply" and "Demand", they could specify {opt shckplt} as "unemployment" before 
running {help var_nr_fevd_plot:var_nr_fevd_plot} to plot only the forecast error 
variance decomposition for {it:unemployment}, and specify {opt shckplt} as 
"inflation" or "Supply" before running {help var_nr_irf_plot:var_nr_irf_plot} to 
plot only the impulse responses to the supply shock.

{phang}
{opt ndraws} specifies the number of draws satisfying the [narrative] sign 
restrictions that {help var_nr_sign_restrict:var_nr_sign_restrict} should generate 
and store before stopping (must be positive integer).

{phang}
{opt errlmt} (stored in Mata as {it:err_lmt}) specifies the number of consecutive 
draws that do not satisfy the [narrative] sign restrictions before a successful 
draw that will trigger {help var_nr_sign_restrict:var_nr_sign_restrict} to abort 
(must be positive integer). For example, if {opt errlmt} is set to 1,000, then 
if {help var_nr_sign_restrict:var_nr_sign_restrict} generates 1,000 unsuccessful 
draws and no successful draw has been drawn at that point, the function will 
abort and display an error.

{phang}
{opt updtfrqcy} (stored in Mata as {it:updt_frqcy}) specifies how frequently 
{help var_nr_sign_restrict:var_nr_sign_restrict} should update the user on its 
progress (must be positive integer). For example, if {otp updtfrqcy} is set to 
500, then the function will display after every additonal 500 draws (successful 
or unsuccessful) the total number of attempted draws, the total number of draws 
that have satisfied the sign restrictions, and, if applicable, the total number 
of draws that have satisfied both the sign and the narrative sign restrictions.

{phang}
{opt updt} specifies whether {help var_nr_sign_restrict:var_nr_sign_restrict} 
should update the user on its progress. Options are "yes" or "no". If set to 
"yes", then the function will display the total number of attempted draws, the 
total number of draws that have satisfied the sign restrictions, and, if 
applicable, the total number of draws that have satisfied both the sign and the 
narrative sign restrictions at the frequency specified by {opt updtfrqcy}.


{dlgtab:Default settings}

{col 5}{bf:ident}{...}
{col 20}"sr"

{col 5}{bf:nsteps}{...}
{col 20}40

{col 5}{bf:impact}{...}
{col 20}0

{col 5}{bf:shut}{...}
{col 20}0

{col 5}{bf:pctg}{...}
{col 20}95

{col 5}{bf:method}{...}
{col 20}"bs"

{col 5}{bf:savefmt}{...}
{col 20}"none"

{col 5}{bf:shckplt}{...}
{col 20}"all"

{col 5}{bf:ndraws}{...}
{col 20}100

{col 5}{bf:errlmt}{...}
{col 20}4000

{col 5}{bf:updtfrqcy}{...}
{col 20}10000

{col 5}{bf:updt}{...}
{col 20}"no"


{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
{cmd:var_nr_options} runs function {bf:{help opt_set:opt_set()}} in Mata.

{p 4 4 2}
For an overview of Stata functions in the toolbox, see 

        {bf:{help var_nr_stata_functions:[VAR-NR] var_nr Toolbox {hline 2} Stata functions}}.
