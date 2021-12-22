{smcl}
{* *! version 16.0 18march2021}{...}
{p2colset 1 17 19 2}{...}
{p2col:{bf:[VAR-NR] var_nr Toolbox} {hline 2}}Stata functions
{p_end}
{p2colreset}{...}


{marker contents}{...}
{title:Contents}

{col 5}   [VAR-NR]
{col 5}Manual entry{col 30}Purpose
{col 5}{hline}

{col 5}   {c TLC}{hline 14}{c TRC}
{col 5}{hline 3}{c RT}{it: Calculations }{c LT}{hline}
{col 5}   {c BLC}{hline 14}{c BRC}

{col 5}{bf:{help var_nr:var_nr}}{...}
{col 30}initializes Stata/Mata objects to run var_nr Toolbox functions
{...}

{col 5}{bf:{help var_nr_irf:var_nr_irf}}{...}
{col 30}calculate impulse responses of SVAR
{...}

{col 5}{bf:{help var_nr_irf_bands:var_nr_irf_bands}}{...}
{col 30}calculate confidence bands for impulse responses of SVAR
{...}

{col 5}{bf:{help var_nr_fevd:var_nr_fevd}}{...}
{col 30}calculate forecast error variance decompositions of SVAR
{...}

{col 5}{bf:{help var_nr_fevd_bands:var_nr_fevd_bands}}{...}
{col 30}calculate confidence bands for forecast error variance decompositions of SVAR
{...}

{col 5}{bf:{help var_nr_hd:var_nr_hd}}{...}
{col 30}calculate historical decompositions of SVAR
{...}



{col 5}   {c TLC}{hline 31}{c TRC}
{col 5}{hline 3}{c RT}{it: Sign & Narrative Restrictions }{c LT}{hline}
{col 5}   {c BLC}{hline 31}{c BRC}

{col 5}{bf:{help var_nr_sign_restrict:var_nr_sign_restrict}}{...}
{col 30}routine to generate [narrative] sign-identified credible set for SVAR
{...}

{col 5}{bf:{help var_nr_shock_create:var_nr_shock_create}}{...}
{col 30}initialize object storing sign restrictions on impulse responses to structural shocks
{...}

{col 5}{bf:{help var_nr_shock_name:var_nr_shock_name}}{...}
{col 30}input names of structural shocks (for plotting)
{...}

{col 5}{bf:{help var_nr_shock_set:var_nr_shock_set}}{...}
{col 30}set sign restriction on given shock
{...}

{col 5}{bf:{help var_nr_narr_create:var_nr_narr_create}}{...}
{col 30}initialize object storing narrative sign restrictions on historical decomposition
{...}

{col 5}{bf:{help var_nr_narr_set:var_nr_narr_set}}{...}
{col 30}set narrative sign restriction on given shock for given time period
{...}



{col 5}   {c TLC}{hline 10}{c TRC}
{col 5}{hline 3}{c RT}{it: Plotting }{c LT}{hline}
{col 5}   {c BLC}{hline 10}{c BRC}

{col 5}{bf:{help var_nr_irf_plot:var_nr_irf_plot}}{...}
{col 30}plot impulse response(s)

{col 5}{bf:{help var_nr_fevd_plot:var_nr_fevd_plot}}{...}
{col 30}plot forecast error variance decomposition(s)

{col 5}{bf:{help var_nr_hd_plot:var_nr_hd_plot}}{...}
{col 30}plot historical decomposition of structural shocks



{col 5}   {c TLC}{hline 10}{c TRC}
{col 5}{hline 3}{c RT}{it: Settings }{c LT}{hline}
{col 5}   {c BLC}{hline 10}{c BRC}

{col 5}{bf:{help var_nr_options:var_nr_options}}{...}
{col 30}set identification, analysis, and plotting options

{col 5}{bf:{help var_nr_options_display:var_nr_options_display}}{...}
{col 30}print current settings



{col 5}{hline}


{marker description}{...}
{title:Description}

{p 4 4 2}
The above functions are included in the {bf:var_nr Toolbox} (Danziger, Koch, Kuchek 2021) and run in Stata.


{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
For corresponding Mata functions, see

        {bf:{help var_nr_mata_functions:[VAR-NR] var_nr Toolbox}}          Mata functions
		
