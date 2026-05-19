{smcl}
{* *! v1.0  Enders-Siklos help}{...}
{title:Title}

{p 4 4 2}
{bf:tc_es} {hline 2} Enders & Siklos (2001) TAR / MTAR threshold cointegration test


{title:Syntax}

{p 4 8 2}
{cmd:tc_es} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {opt model(tar|mtar)} {opt threshold(#)} {opt maxlag(#)} {opt criterion(aic|bic)} {opt case(nc|c|ct)}]

{title:Description}

{pstd}
Step 1 estimates the static cointegrating regression of {it:depvar} on {it:indepvars}.
Step 2 fits an asymmetric AR equation on the residuals:

{p 4 4 2}
{it:Δê_t = ρ_1·I_t·ê_{{t-1}} + ρ_2·(1-I_t)·ê_{{t-1}} + Σγ_j·Δê_{{t-j}} + ε_t}

{pstd}where {it:I_t} = {it:1{(ê_{{t-1}}>=τ)}} for {cmd:model(tar)} and {it:I_t} = {it:1{(Δê_{{t-1}}>=τ)}} for {cmd:model(mtar)}.

{pstd}
H{sub:0}: ρ{sub:1} = ρ{sub:2} = 0 (no cointegration).  The Φ statistic = (t{sup:2}{sub:ρ1}+t{sup:2}{sub:ρ2})/2 is compared
to Enders-Siklos critical values, included internally.  An F-test for ρ{sub:1}=ρ{sub:2} (symmetric adjustment) is also reported.

{title:Options}

{synoptset 26 tabbed}{...}
{synopt:{opt model(tar|mtar)}}TAR or M-TAR (default {it:mtar}){p_end}
{synopt:{opt threshold(#)}}threshold τ (default 0){p_end}
{synopt:{opt maxlag(#)}}maximum augmentation lag (default 8){p_end}
{synopt:{opt criterion(aic|bic)}}lag-selection rule (default {it:aic}){p_end}
{synopt:{opt case(nc|c|ct)}}deterministic terms (default {it:c}){p_end}
{synoptline}

{title:Stored results}

{pstd}{cmd:r(phi_stat)} {cmd:r(rho1)} {cmd:r(rho2)} {cmd:r(t_rho1)} {cmd:r(t_rho2)}
{cmd:r(f_asymmetry)} {cmd:r(threshold)} {cmd:r(lags)} {cmd:r(nregime1)} {cmd:r(nregime2)}
{cmd:r(cv)} {cmd:r(conclusion)}

{title:Example}

{phang}{stata "tc_es ln_inv ln_inc, model(mtar) maxlag(6)"}

{title:Author}

{pstd}Dr Merwan Roudane -- see {helpb threshcoint:Package overview}.{p_end}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_glsmtar} | {helpb tc_exes} | {helpb tc_covaug} | {helpb tc_supf} | {helpb tc_bf} | {helpb tc_tar} | {helpb tc_plot}{p_end}

