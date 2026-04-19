{smcl}
{* chse_fdi.sthlp  April 2025}{...}
{hline}
{title:chse_fdi — Fiscal Dominance Index}
{hline}

{title:Syntax}

{p 8 16 2}
{cmd:chse_fdi}{cmd:,} {opt vt(varname|#)} {opt kcb(varname|#)}
[{opt lambda(#)} {opt rhoratio(#)} {opt gen:erate(stub)} {opt replace}]

{title:Description}

{pstd}
{cmd:chse_fdi} computes the Fiscal Dominance Index (FDI) from the CHSE
central bank application (Corollary 11.1):

{col 8}FDI = V_T * lambda_R / (K_CB * rho_kappa/rho_nu)

{pstd}
where V_T is a political capital or fiscal pressure index, K_CB is the
central bank independence score (Dincer-Eichengreen scale), lambda_R is
the reframing efficiency parameter, and rho_kappa/rho_nu is the ratio of
credibility to manipulation capital replenishment rates.

{pstd}
Regime classification:

{col 6}{hline 36}
{col 6}{it:FDI}{col 20}{it:Regime}
{col 6}{hline 36}
{col 6}FDI < 0.5{col 20}Monetary dominance
{col 6}0.5 <= FDI <= 1{col 20}Contested
{col 6}FDI > 1{col 20}Fiscal dominance
{col 6}{hline 36}

{pstd}
The implied HSI is 1/FDI: monetary dominance corresponds to high HSI (strong
central bank), fiscal dominance to low HSI (weak institutional resistance).

{title:Options}

{phang}
{opt vt(varname|#)} V_T: political capital / fiscal pressure index.

{phang}
{opt kcb(varname|#)} K_CB: central bank independence score. Typically on
a 0-1 scale (Dincer-Eichengreen) or similar.

{phang}
{opt lambda(#)} reframing efficiency lambda_R. Default 1.0.

{phang}
{opt rhoratio(#)} ratio rho_kappa/rho_nu. Default 1.0.

{phang}
{opt gen:erate(stub)} prefix for generated variables. Creates:
{it:stub}_fdi, {it:stub}_fdi_regime, {it:stub}_hsi.

{title:Saved results}

{col 6}r(FDI){col 20}Computed FDI value
{col 6}r(HSI){col 20}Implied HSI (= 1/FDI)
{col 6}r(regime){col 20}Regime string (monetary/contested/fiscal)
{col 6}r(lambda_R){col 20}lambda_R used
{col 6}r(rho_ratio){col 20}rho ratio used

{title:Examples}

{pstd}Replicate Figure 5 (paper examples):{p_end}
{cmd:. input str8 country str8 period float(vt kcb)}
{cmd:.   "Chile"  "2000-22"  0.21 0.95}
{cmd:.   "US"     "2000-07"  0.17 0.94}
{cmd:.   "US"     "2020-23"  0.51 0.94}
{cmd:.   "Brazil" "2015-18"  0.77 0.85}
{cmd:.   "Zambia" "2020-23"  0.94 0.67}
{cmd:.   "Turkey" "2021-23"  0.82 0.45}
{cmd:. end}
{cmd:. chse_fdi, vt(vt) kcb(kcb) gen(chse) replace}
{cmd:. list country period chse_fdi chse_fdi_regime}

{pstd}Single country:{p_end}
{cmd:. chse_fdi, vt(0.82) kcb(0.45)}   // Turkey 2021-23: FDI=1.82, fiscal

{title:References}

{pstd}
Nityahapani (2025). Contested Hierarchy with Social Embedding.
Corollary 11.1 (Endogenous Fiscal Dominance), Section 11.

{title:Author}

{pstd}Nityahapani{p_end}
{pstd}chse package v1.0.0{p_end}

{hline}
