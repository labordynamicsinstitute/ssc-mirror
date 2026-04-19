{smcl}
{* chse_welfare.sthlp  April 2025}{...}
{hline}
{title:chse_welfare — Compute the three CHSE welfare distortions}
{hline}

{title:Syntax}

{p 8 16 2}
{cmd:chse_welfare} [{varname}] [{it:if}] [{it:in}]{cmd:,}
{opt eta(#)} {opt kap:pa(#)} {opt gam:ma(#)}
[{opt beta_r(#)} {opt zeta_ii(#)} {opt c_mu(#)} {opt c_kappa2(#)}
{opt avg_spi:llover(#)} {opt avg_amb:iguity(#)} {opt avg_deg:ree(#)}
{opt n_edges(#)}]

{title:Description}

{pstd}
{cmd:chse_welfare} computes the three welfare distortions present in any
interior HOE relative to the social optimum (Bottleneck 6):

{phang2}
{bf:Distortion 1} (over-investment in reframing):
Excess = eta_eq * beta_R * Gamma / (1-Gamma).
Policy fix: legal estoppel, institutional precedent.

{phang2}
{bf:Distortion 2} (over-investment in commitment resistance):
Excess = kappa_eq * avg_network_spillover.
Policy fix: legibility subsidies, transparent announcements.

{phang2}
{bf:Distortion 3} (under-investment in hierarchy clarity):
Deficit = zeta_II * avg_degree * avg_ambiguity, where ambiguity =
1 - |2*h - 1| (equals 1 at h=0.5, 0 at h=0 or h=1).
Policy fix: public commitment requirements, board resolutions.

{pstd}
Total welfare loss = D1*c_mu*n_edges + D2*c_kappa*n_edges + D3.

{pstd}
If {varname} is supplied, it is treated as a variable of observed h values
(one per edge), and avg_ambiguity is computed directly from the data.
Otherwise supply avg_ambiguity() and avg_degree() as scalars.

{title:Options}

{phang}{opt eta(#)} equilibrium reframing investment eta_eq.{p_end}
{phang}{opt kap:pa(#)} equilibrium credibility investment kappa_eq.{p_end}
{phang}{opt gam:ma(#)} propagation factor Gamma in [0,1).{p_end}
{phang}{opt beta_r(#)} reframing network spillover. Default 0.1.{p_end}
{phang}{opt zeta_ii(#)} ambiguity spillover rate. Default 0.3.{p_end}
{phang}{opt c_mu(#)} cost of reframing investment. Default 0.5.{p_end}
{phang}{opt c_kappa2(#)} cost of credibility investment. Default 0.5.{p_end}
{phang}{opt avg_spi:llover(#)} average network spillover for D2. Default 0.5.{p_end}
{phang}{opt avg_amb:iguity(#)} average 1-|2h-1| over edges (if no varname). Default 0.5.{p_end}
{phang}{opt avg_deg:ree(#)} average node degree (if no varname). Default 2.0.{p_end}
{phang}{opt n_edges(#)} number of edges. Default 1.{p_end}

{title:Saved results}

{col 6}r(excess_1){col 24}Distortion 1 magnitude
{col 6}r(eta_SO){col 24}Social optimum eta
{col 6}r(excess_2){col 24}Distortion 2 magnitude
{col 6}r(deficit_3){col 24}Distortion 3 magnitude
{col 6}r(welfare_loss){col 24}Total monetised welfare loss
{col 6}r(excess_factor){col 24}beta_R*Gamma/(1-Gamma)

{title:Examples}

{pstd}Scalar (3-player complete network, h=0.65, calibrated params):{p_end}
{cmd:. chse_welfare, eta(0.5) kappa(0.6) gamma(0.4) beta_r(0.15)}
{cmd:.              zeta_ii(0.3) c_mu(0.3) c_kappa2(0.3)}
{cmd:.              avg_ambiguity(0.35) avg_degree(2) n_edges(3)}
{cmd:  // Welfare loss = 1.4043}

{pstd}From edge-level h data:{p_end}
{cmd:. chse_welfare h_edge if wave==2, eta(0.5) kappa(0.6) gamma(0.4)}

{title:References}

{pstd}
Nityahapani (2025). Contested Hierarchy with Social Embedding. Bottleneck 6.

{hline}
