{smcl}
{* chse_fliptime.sthlp  April 2025}{...}
{hline}
{title:chse_fliptime — Leadership flip time and oscillation condition}
{hline}

{title:Syntax}

{p 8 16 2}
{cmd:chse_fliptime}{cmd:,} {opt mu(varname|#)} {opt eta(varname|#)} {opt kappa(varname|#)}
[{opt rbar(#)} {opt h0(varname|#)} {opt eps:ilon(#)} {opt gen:erate(stub)} {opt replace}]

{title:Description}

{pstd}
{cmd:chse_fliptime} computes the expected first-passage time t* for the
hierarchy belief h(t) to cross the 0.5 threshold, using the two-player
benchmark model (Section 3, Definition 3.2):

{col 8}t* = (1/mu_tilde) * ln( (h0 - 0.5) / epsilon )

{pstd}
where mu_tilde = |Re(lambda)| is the effective decay rate from the
linearised Jacobian eigenvalues:

{col 8}lambda = ( -mu +/- sqrt(mu^2 - 4*eta_bar*kappa_bar) ) / 2

{pstd}
The oscillation condition (Definition 3.1) holds when the discriminant
mu^2 - 4*eta_bar*kappa_bar < 0, giving complex eigenvalues and oscillatory
dynamics. In this case the period is:

{col 8}T = 2*pi / Im(lambda)

{pstd}
When the hierarchy is stable (h* > 0.5 and no oscillation), t* = inf:
leadership never flips deterministically.

{title:Options}

{phang}
{opt mu(varname|#)} mean-reversion strength mu > 0.

{phang}
{opt eta(varname|#)} equilibrium reframing rate eta_bar.

{phang}
{opt kappa(varname|#)} equilibrium resistance rate kappa_bar.

{phang}
{opt rbar(#)} reframing attack rate r_bar. Default 1.0.

{phang}
{opt h0(varname|#)} initial hierarchy belief. Default 0.75.
Must be > 0.5 for player 1 to be the initial leader.

{phang}
{opt eps:ilon(#)} flip precision threshold. Default 0.01.

{phang}
{opt gen:erate(stub)} creates variables: {it:stub}_tstar, {it:stub}_disc,
{it:stub}_oscillates.

{title:Saved results (scalar call)}

{col 6}r(t_star){col 26}Flip time (. = stable/never flips)
{col 6}r(discriminant){col 26}mu^2 - 4*eta*kappa
{col 6}r(mu_tilde){col 26}Effective decay rate
{col 6}r(h_star){col 26}Fixed point h*
{col 6}r(oscillates){col 26}1 if oscillation condition holds
{col 6}r(period){col 26}Period (if oscillatory)
{col 6}r(regime){col 26}stable / oscillatory / stable_node

{title:Examples}

{pstd}Oscillatory regime (HSI=1.0, disc < 0):{p_end}
{cmd:. chse_fliptime, mu(0.6) eta(0.4) kappa(0.4)}
{cmd:  // t* = 10.73, regime = oscillatory, period = 23.75}

{pstd}Stable regime (HSI=2.1, disc > 0):{p_end}
{cmd:. chse_fliptime, mu(2.0) eta(0.8) kappa(0.2)}
{cmd:  // t* = ., regime = stable (h* > 0.5)}

{pstd}Panel of parameter settings:{p_end}
{cmd:. chse_fliptime, mu(mu_var) eta(eta_var) kappa(kappa_var) gen(ft) replace}
{cmd:. summarize ft_tstar ft_disc ft_oscillates}

{title:References}

{pstd}
Nityahapani (2025). Contested Hierarchy with Social Embedding.
Section 3, Definitions 3.1 and 3.2.

{title:Author}

{pstd}Nityahapani{p_end}
{pstd}chse package v1.0.0{p_end}

{hline}
