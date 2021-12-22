{smcl}
{* *! version 16.0 18march2021}{...}
{p2colset 1 17 19 2}{...}
{p2col:{bf:[VAR-NR] var_nr Toolbox} {hline 2}}Mata functions
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

{col 5}{bf:{help irf_funct:irf_funct()}}{...}
{col 30}calculate impulse responses of SVAR
{...}

{col 5}{bf:{help irf_bands_funct:irf_bands_funct()}}{...}
{col 30}calculate confidence bands for impulse responses of SVAR
{...}

{col 5}{bf:{help fevd_funct:fevd_funct()}}{...}
{col 30}calculate forecast error variance decompositions of SVAR

{col 5}{bf:{help fevd_bands_funct:fevd_bands_funct()}}{...}
{col 30}calculate confidence bands for forecast error variance decompositions of SVAR
{...}

{col 5}{bf:{help hd_funct:hd_funct()}}{...}
{col 30}calculate historical decompositions of SVAR
{...}



{col 5}   {c TLC}{hline 31}{c TRC}
{col 5}{hline 3}{c RT}{it: Sign & Narrative Restrictions }{c LT}{hline}
{col 5}   {c BLC}{hline 31}{c BRC}

{col 5}{bf:{help sign_restrict:sign_restrict()}}{...}
{col 30}routine to generate sign-identified credible set for SVAR
{...}

{col 5}{bf:{help narr_sign_restrict:narr_sign_restrict()}}{...}
{col 30}routine to generate sign- and narrative-sign-identified credible set for SVAR
{...}

{col 5}{bf:{help shock_create:shock_create()}}{...}
{col 30}initialize object storing sign restrictions on impulse responses to structural shocks
{...}

{col 5}{bf:{help shock_name:shock_name()}}{...}
{col 30}input names of structural shocks (for plotting)
{...}

{col 5}{bf:{help shock_set:shock_set()}}{...}
{col 30}set sign restriction on given shock
{...}

{col 5}{bf:{help nr_create:nr_create()}}{...}
{col 30}initialize object storing narrative sign restrictions on historical decomposition
{...}

{col 5}{bf:{help nr_set:nr_set()}}{...}
{col 30}set narrative sign restriction on given shock for given time period
{...}

{col 5}{bf:{help sr_analysis_funct:sr_analysis_funct()}}{...}
{col 30}calculate IRFs, FEVDs, and HDs for [narrative] sign-identified SVARs
{...}



{col 5}   {c TLC}{hline 20}{c TRC}
{col 5}{hline 3}{c RT}{it: Plotting & Options }{c LT}{hline}
{col 5}   {c BLC}{hline 20}{c BRC}

{col 5}{bf:{help irf_plot:irf_plot()}}{...}
{col 30}plot impulse response(s)

{col 5}{bf:{help fevd_plot:fevd_plot()}}{...}
{col 30}plot forecast error variance decomposition(s)

{col 5}{bf:{help hd_plot:hd_plot()}}{...}
{col 30}plot historical decomposition of structural shocks

{col 5}{bf:{help opt_display:opt_display()}}{...}
{col 30}displays current options settings



{col 5}   {c TLC}{hline 14}{c TRC}
{col 5}{hline 3}{c RT}{it: Subfunctions }{c LT}{hline}
{col 5}   {c BLC}{hline 14}{c BRC}

{col 5}{bf:{cmd:var_funct()}}{...}
{col 30}creates {it:var_struct} structure storing elements needed for SVAR analysis

{col 5}{bf:{cmd:opt_set()}}{...}
{col 30}initializes {it:opt_struct} structure with default options

{col 5}{bf:{cmd:check_mat()}}{...}
{col 30}discerns whether drawn VAR satisfies sign restrictions

{col 5}{bf:{cmd:check_nsr()}}{...}
{col 30}discerns whether drawn VAR satisfies narrative sign restrictions

{col 5}{bf:{cmd:identify()}}{...}
{col 30}calculates the impact matrix using short-run zero, long-run zero, or sign restrictions

{col 5}{bf:{cmd:orth_norm()}}{...}
{col 30}generates a random orthonormal matrix

{col 5}{bf:{cmd:posterior_draw()}}{...}
{col 30}draws coefficient and variance-covariance matrices from their posteriors

{col 5}{bf:{cmd:prctile()}}{...}
{col 30}calculates a percentile of elements in a real matrix

{col 5}{bf:{cmd:prctile_or_mean()}}{...}
{col 30}calculates a percentile or mean of elements across multiple real matrices

{col 5}{bf:{cmd:var_simulation()}}{...}
{col 30}same as {bf:{cmd:var_funct}} but recalculates input VAR's elements with input simulated data


{col 5}{hline}


{marker description}{...}
{title:Description}

{p 4 4 2}
The above functions are included in the {bf:var_nr Toolbox} (Danziger, Koch, Kuchek 2021) and run in Mata.


{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
For corresponding Stata functions, see

        {bf:{help var_nr_stata_functions:[VAR-NR] var_nr Toolbox}}          Stata functions
		
