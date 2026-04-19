{smcl}
{* chse_regime.sthlp  April 2025}{...}
{hline}
{title:chse_regime — Classify CHSE regime from HSI and PI}
{hline}

{title:Syntax}

{p 8 16 2}
{cmd:chse_regime}{cmd:,} {opt hsi(varname|#)} {opt pi(varname|#)}
[{opt gen:erate(stub)} {opt replace}]

{title:Description}

{pstd}
{cmd:chse_regime} computes the CHSE Instability Index Z = HSI^-1*(1+2*PI)
and classifies each observation into one of four dynamic regimes:

{col 6}{hline 44}
{col 6}{it:Z}{col 20}{it:Regime}{col 36}{it:Dynamics}
{col 6}{hline 44}
{col 6}Z < 1{col 20}Stable{col 36}h(t) converges to fixed point
{col 6}1 <= Z < 2{col 20}Oscillatory{col 36}Leadership alternates
{col 6}2 <= Z < 3.5{col 20}Cascade{col 36}Network-wide collapses
{col 6}Z >= 3.5{col 20}Turbulent{col 36}Sensitive dependence
{col 6}{hline 44}

{pstd}
HSI (Hierarchy Stability Index) = lambda_kappa * K_i / (lambda_R * V_j)
measures the ratio of leadership resistance capacity to follower attack capacity.

{pstd}
PI (Propagation Intensity) = Gamma * E[phi(d,G)]
measures network cascade potential.

{title:Options}

{phang}
{opt hsi(varname|#)} specifies the Hierarchy Stability Index. Either a
variable name or a scalar value.

{phang}
{opt pi(varname|#)} specifies the Propagation Intensity. Either a
variable name or a scalar value. Set to 0 for single-edge (no network).

{phang}
{opt gen:erate(stub)} prefix for generated variables. Default is {it:chse}.
Creates {it:stub}_Z (instability index), {it:stub}_regime (string),
{it:stub}_regime_n (numeric, labelled).

{phang}
{opt replace} replaces existing variables with the same name.

{title:Saved results (scalars, when both arguments are scalars)}

{col 6}r(Z){col 24}Instability index
{col 6}r(HSI){col 24}HSI value
{col 6}r(PI){col 24}PI value
{col 6}r(regime){col 24}Regime string

{title:Examples}

{pstd}Scalar call:{p_end}
{cmd:. chse_regime, hsi(2.1) pi(0)}
{cmd:. chse_regime, hsi(0.4) pi(0.3)}

{pstd}Variable call — classify a panel of country-year observations:{p_end}
{cmd:. chse_regime, hsi(hsi_var) pi(pi_var) gen(chse) replace}
{cmd:. tabulate chse_regime}
{cmd:. tabstat chse_Z, by(chse_regime) stat(mean min max)}

{pstd}Phase boundary: stable iff HSI*(1+2*PI) > 1 (Theorem 6.1):{p_end}
{cmd:. chse_regime, hsi(1.0) pi(0.0)}   // exactly on boundary -> oscillatory

{title:References}

{pstd}
Nityahapani (2025). Contested Hierarchy with Social Embedding.
Theorems 6.1 and 6.2.

{title:Author}

{pstd}Nityahapani{p_end}
{pstd}chse package v1.0.0{p_end}

{hline}
