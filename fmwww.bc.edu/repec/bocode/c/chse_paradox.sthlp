{smcl}
{* chse_paradox.sthlp  April 2025}{...}
{hline}
{title:chse_paradox — Test the Hierarchy Persistence Paradox}
{hline}

{title:Syntax}

{p 8 16 2}
{cmd:chse_paradox} {it:disruption_var} {it:hsi_var} [{it:if}] [{it:in}]
[{cmd:,} {opt fdi} {opt alpha_r(#)} {opt trust(#)} {opt phi(#)}
{opt acc_floor(#)} {opt acc_ceil:ing(#)} {opt gen:erate(stub)} {opt replace}]

{title:Description}

{pstd}
{cmd:chse_paradox} tests the Hierarchy Persistence Paradox (Bottleneck 8):

{phang2}
H1: dE[cascade|collapse]/dHSI > 0
{p_end}

{pstd}
Stronger hierarchies produce larger collapses when they fall. The command:

{phang2}1. Regresses the disruption variable on HSI (or FDI).{p_end}
{phang2}2. Tests whether the slope is significantly positive.{p_end}
{phang2}3. Computes calibrated theoretical cascade predictions
using the formula E[cascade] = alpha_R / (1 - rho_K), where
rho_K = Acc(HSI) * trust * phi and Acc(HSI) = acc_floor +
(acc_ceiling - acc_floor) * HSI/(1+HSI).{p_end}

{title:Options}

{phang}
{opt fdi} treat {it:hsi_var} as FDI values; convert to HSI via HSI = 1/FDI.
Use this when your input variable is the Fiscal Dominance Index.

{phang}
{opt alpha_r(#)} direct belief drop per reframe. Default 0.3.

{phang}
{opt trust(#)} average cross-edge trust at equilibrium. Default 0.65.

{phang}
{opt phi(#)} average distance decay. Default 0.60.

{phang}
{opt acc_floor(#)} Acc_ij at HSI approaching 0. Default 0.50.

{phang}
{opt acc_ceil:ing(#)} Acc_ij at HSI approaching infinity. Default 0.92.

{phang}
{opt gen:erate(stub)} creates variables {it:stub}_hsi_implied,
{it:stub}_acc, {it:stub}_rhoK, {it:stub}_cascade_pred.

{title:Saved results}

{col 6}r(slope){col 28}OLS slope (post-collapse disruption ~ HSI)
{col 6}r(se_slope){col 28}Standard error of slope
{col 6}r(pval_slope){col 28}Two-sided p-value
{col 6}r(r2){col 28}R-squared
{col 6}r(correlation){col 28}Pearson correlation
{col 6}r(paradox_confirmed){col 28}1 if slope>0 and p<0.10
{col 6}r(acc_min){col 28}Minimum predicted Acc_ij
{col 6}r(acc_max){col 28}Maximum predicted Acc_ij
{col 6}r(rhoK_min){col 28}Minimum predicted rho(K)
{col 6}r(rhoK_max){col 28}Maximum predicted rho(K)

{title:Examples}

{pstd}Using HSI directly:{p_end}
{cmd:. chse_paradox yield_vol hsi_precollapse}
{cmd:  // Tests: do high-HSI countries have larger post-collapse disruptions?}

{pstd}Using FDI (converts to HSI internally):{p_end}
{cmd:. chse_paradox yield_vol fdi, fdi}

{pstd}With generate (to plot cascade predictions):{p_end}
{cmd:. chse_paradox yield_vol hsi, gen(pred) replace}
{cmd:. scatter yield_vol hsi || line pred_cascade_pred pred_hsi_implied, sort}

{pstd}Replicate paper Figure 5 test:{p_end}
{cmd:. input float(disruption hsi)}
{cmd:.   0.10  0.55}  // Turkey
{cmd:.   0.12  0.71}  // Zambia
{cmd:.   0.38  1.10}  // Brazil
{cmd:.   0.59  1.84}  // US 2020-23
{cmd:.   1.38  4.52}  // Chile
{cmd:.   1.61  5.53}  // US 2000-07
{cmd:. end}
{cmd:. chse_paradox disruption hsi}
{cmd:  // slope > 0, r = 0.996, paradox confirmed}

{title:References}

{pstd}
Nityahapani (2025). Contested Hierarchy with Social Embedding. Bottleneck 8.

{title:Author}

{pstd}Nityahapani{p_end}
{pstd}chse package v1.0.0{p_end}

{hline}
