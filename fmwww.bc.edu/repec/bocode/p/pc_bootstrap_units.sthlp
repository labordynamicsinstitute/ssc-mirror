{smcl}
{* *! version 1.1 04jan2017}{...}
{vieweralsosee "[R] reghdfe" "help reghdfe"}{...}
{vieweralsosee "[R] pc_simulate" "help pc_simulate"}{...}
{vieweralsosee "[R] pc_dd_analytic" "help pc_dd_analytic"}{...}
{vieweralsosee "[R] pc_dd_covar" "help pc_dd_covar"}{...}
{viewerjumpto "Syntax" "pc_bootstrap_units##syntax""}{...}
{viewerjumpto "Description" "pc_bootstrap_units##description"}{...}
{viewerjumpto "Details" "pc_bootstrap_units##details"}{...}
{viewerjumpto "Examples" "pc_bootstrap_units##examples"}{...}
{viewerjumpto "Contact" "pc_bootstrap_units##contact"}{...}
{title:Title}

{p2colset 5 27 27 2}{...}
{p2col :{cmd:pc_bootstrap_units} {hline 2}}Program to simulate additional units, in order to conduct power calculations by simulation using {help pc_simulate}{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 24 2} {cmd:pc_bootstrap_units} {it:panelvar} {ifin} {cmd:,} {opth n:units(#)} [{opth var:list(varlist)} {opth sort(varlist)}] {p_end}


{marker opt_summary}{...}
{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt n:units(#)}}desired number of cross-sectional units (unique values of {it:panelvar}),
or the number of existing units plus the number of simulated units to be bootstrapped; must be a positive integer.{p_end}

{syntab:Optional}
{synopt :{opth var:list(varlist)}}subset of variables to be bootstrapped; if not specified, program will copy {it:all} variables in dataset to simulated units.{p_end}
{synopt :{opth sort(varlist)}}list of variables to sort by, before bootstrapping simulated units; 
if not specified, program will not sort by variables other than {it:panelvar}.{p_end}
{synoptline}

{break}
{marker description}{...}
{title:Description}

{pstd}
This program adds cross-sectional units to an existing dataset, for the purposes of facilitating power calculations using {help pc_simulate}. It 
creates new "simulated" units by drawing with replacement from existing units in the dataset.
{p_end}

{pstd}
{help pc_bootstrap_units} allows users to simulate power calculations for experiments with samples sizes larger than their existing datasets. By 
bootstrapping "simulated" units from existing sample units, it assumes that these sample units are representative of the full population. It 
also ensures that the outcome variable ({it:depvar}) exhibits the same variance-covariance structure in both real and simulated units.
{p_end}

{hline}
{break}
{marker details}{...}
{title:Details}

{pstd}
The program first calculates the number ({it:nexisting}) of unique values of {it:panelvar}. Then, 
for each additional unit to be bootstrapped, it randomly chooses one of the {it:nexisting} original units 
and appends {it:all} of this unit's observations to the bottom of the dataset. It
repeats this process until the total number of units equals {it:nunits}.

{pstd}
If the dataset is unique by {it:panelvar} (i.e. not a 2-dimensional panel, but suitable for a cross-sectional {opt ONESHOT} power calculation), 
each bootstrapped unit will only add 1 new row to the dataset.

{pstd}
The program assigns a new value of {it:panelvar} for each simulated unit, in order to distinguish it from existing units. It 
also creates a new variable, ORIG{it:panelvar}, which stores each bootstrapped unit's original {it:panelvar} value. ORIG{it:panelvar} 
is missing for all {it:nexisting} original units, and populated for all bootstrapped units.

{pstd}
For large datasets, users may only wish to populate certain variables to the simulated units (i.e. only variables to be used by {help pc_simulate}). 
The option {opth var:list(varlist)} allows users to select which variables to populate.

{pstd}
The option {opth sort(varlist)} allows users to sort along a second panel dimension, 
in order to improve readability. For 
example, {it:sort(timevar)} yields a final dataset sorted by {it: panelvar timevar}, with existing units on top, bootstrapped units on the bottom, and the observations within each unit sorted by time period. 

{hline}

{marker example}{...}
{title:Example}

{pstd}
Suppose the existing dataset is a two-dimensional panel containing 40 unique cross-sectional units, numbered {it:person_id} = {1,...,40}. Suppose each unit has 15 time-period observations.{p_end}

{pstd}
The following command would allow {help pc_simulate} to perform power calculations for an experiment with 60 units:{p_end}

{phang}{cmd:. pc_bootstrap_units person_id, nunits(60)}{p_end}

{pstd}
The resulting dataset would contain 300 new observations for 20 simulated units, numbered {it:person_id} = {41,...,60}. Each 
new observation would contain 15 time periods, and would simply duplicate one of the original 40 observations. {p_end}

{pstd}
The new variable {it:ORIGperson_id} would be missing for all original units, and would be populated for all simulated units, indicating the original unit from which each simulated unit was bootstrapped.{p_end}

{hline}

{marker contact}{...}
{title:Contact}

{pstd}Louis Preonas{break}
Department of Agricultural and Resource Economics{break}
Energy Institute at Haas{break}
UC Berkeley{break}
Email: {browse "mailto:lpreonas@berkeley.edu":lpreonas@berkeley.edu}
{p_end}

{pstd}This program is part of the {help ssc} package {cmd:pcpanel}.{p_end}


