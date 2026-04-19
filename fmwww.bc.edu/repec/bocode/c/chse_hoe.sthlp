{smcl}
{* chse_hoe.sthlp  April 2025}{...}
{hline}
{title:chse_hoe — Estimate HOE statistics from observed h(t) series}
{hline}

{title:Syntax}

{p 8 16 2}
{cmd:chse_hoe} {varname} [{it:if}] [{it:in}]
[{cmd:,} {opt burnin(#)} {opt windows(#)} {opt alpha_r(#)} {opt tol(#)}]

{title:Description}

{pstd}
{cmd:chse_hoe} estimates the three empirical statistics that characterise
the Hierarchy Orbit Equilibrium (Definition 10.2):

{phang2}tau_hat — leadership turnover frequency (flips per period){p_end}
{phang2}Var(h) — variance of h in the stationary distribution{p_end}
{phang2}E[cascade size] — expected cascade size (via rho(K) proxy){p_end}

{pstd}
The variable {varname} should contain an observed h(t) time series where
h ∈ [0,1] is the hierarchy belief at each period. In the central bank
application, h(t) can be proxied by:

{phang2}Yield spread response to CB announcements (normalised to [0,1]){p_end}
{phang2}CB forecast dominance share in professional surveys{p_end}
{phang2}Policy divergence index between CB and Treasury{p_end}

{pstd}
Stationarity is tested by comparing window means across the post-burn-in
trajectory. Convergence is declared if max window-mean difference < tol.

{title:Options}

{phang}
{opt burnin(#)} number of initial observations to discard. Default 0.

{phang}
{opt windows(#)} number of windows for stationarity test. Default 4.

{phang}
{opt alpha_r(#)} direct belief drop per successful reframe, used for the
cascade size calculation. Default 0.3.

{phang}
{opt tol(#)} stationarity tolerance (max window-mean difference for
declaring convergence). Default 0.05.

{title:Saved results}

{col 6}r(tau_hat){col 28}Turnover frequency
{col 6}r(var_h){col 28}Variance of h (post burn-in)
{col 6}r(mean_h){col 28}Mean of h
{col 6}r(min_h){col 28}Minimum h
{col 6}r(max_h){col 28}Maximum h
{col 6}r(frac_above){col 28}Fraction of periods h > 0.5
{col 6}r(n_flips){col 28}Total number of leadership flips
{col 6}r(N_post_burnin){col 28}Observations used
{col 6}r(rho_K_proxy){col 28}Proxy for spectral radius rho(K)
{col 6}r(exp_cascade){col 28}Expected cascade size bound
{col 6}r(max_win_diff){col 28}Max window-mean difference
{col 6}r(converged){col 28}1 if stationarity test passed

{title:Examples}

{pstd}Stable HOE — central bank with high independence:{p_end}
{cmd:. use cb_yield_data.dta, clear}
{cmd:. chse_hoe h_proxy, burnin(20)}
{cmd:  // expect: tau_hat≈0, mean_h≈0.8, converged=1}

{pstd}Oscillatory HOE — contested CB period:{p_end}
{cmd:. chse_hoe h_proxy if contested==1, burnin(12) windows(6)}
{cmd:  // expect: tau_hat>0.1, mean_h≈0.5}

{pstd}Time series panel — one group per country:{p_end}
{cmd:. xtset country year}
{cmd:. by country: chse_hoe h_proxy, burnin(5)}

{title:References}

{pstd}
Nityahapani (2025). Contested Hierarchy with Social Embedding.
Section 10, Definitions 10.1 and 10.2.

{title:Author}

{pstd}Nityahapani{p_end}
{pstd}chse package v1.0.0{p_end}

{hline}
