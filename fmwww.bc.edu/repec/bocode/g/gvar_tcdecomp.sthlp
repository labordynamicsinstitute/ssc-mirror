{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar solve" "help gvar_solve"}{...}
{vieweralsosee "gvar methods" "help gvar_methods"}{...}
{viewerjumpto "Syntax" "gvar_tcdecomp##syntax"}{...}
{viewerjumpto "Description" "gvar_tcdecomp##description"}{...}
{viewerjumpto "Remarks" "gvar_tcdecomp##remarks"}{...}
{viewerjumpto "Examples" "gvar_tcdecomp##examples"}{...}
{viewerjumpto "Stored results" "gvar_tcdecomp##results"}{...}
{viewerjumpto "Options" "gvar_tcdecomp##options"}{...}
{title:Title}

{phang}
{bf:gvar tcdecomp} {hline 2} Beveridge-Nelson trend/cycle decomposition


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar tcdecomp} [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt var:iables(spec)}}which series to report. Default {cmd:*:y}.{p_end}
{synopt:{opt rest:rict(varlist)}}variables whose deterministic trend is restricted to zero.{p_end}
{synopt:{opt notr:end}}no trend in the deterministic component for any variable.{p_end}
{synopt:{opt resid:uals(string)}}{cmd:eta} (default) or {cmd:zeta}.{p_end}
{synopt:{opt per:iods(#)}}reserved.{p_end}
{synopt:{opt gr:aph}}plot the cycles.{p_end}
{synopt:{opt name(name)}}graph name.{p_end}
{synopt:{opt nosum:mary}}suppress the table.{p_end}
{synopt:{opt saving(name)}}save the cycles.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar tcdecomp} splits every series into a permanent component - the
long-run multiplier times the cumulated innovations, plus a deterministic
term - and a cyclical remainder.


{marker options}{...}
{title:Options}

{phang}
{opt variables(spec)} restricts which series are decomposed.

{phang}
{opt restrict(spec)} and {opt notrend} control the deterministic treatment of
the permanent component. {opt notrend} omits the trend from the trend/cycle
split, which changes what "permanent" means and should be a deliberate choice.

{phang}
{opt residuals(eta|zeta)} which residual is cumulated into the permanent
component. {bf:Default} {cmd:eta}, the reduced-form residual.

{pmore}
This is source defect 1 and the option exists to reproduce it.
{it:TCdecomp.m} documents its third argument as the reduced-form residual and
builds its multiplier from {it:H0\H(:,:,j)}, but {it:gvar.m}:3106 calls it with
{it:zeta}, the structural one. Cumulating {it:zeta} against a reduced-form
long-run multiplier leaves an I(1) term in the "cycle". Measured on the demo, ADF
over all 136 cycle series finds 136 of 136 stationary using {it:eta} against 103
of 136 using {it:zeta}. {cmd:residuals(zeta)} reproduces the Toolbox.

{pmore}
Note what cannot settle this: comparing the size of the two candidate cycles. In
{it:TCdecomp} the cycle is the OLS residual on {it:[1, trend]} and is therefore
orthogonal to the trend by construction under {bf:either} residual. Only a
stationarity test discriminates.

{phang}
{opt periods(numlist)} restricts the window shown.

{phang}
{opt graph}, {opt name()}, {opt saving()} and {opt nosummary} as elsewhere.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:On residuals().} The Toolbox's own routine documents its input as the
reduced-form residual and builds its multiplier from the reduced-form lag
matrices, but the calling code passes the structural residual. Cumulating the
structural residual against a reduced-form multiplier leaves a unit root in
the "cycle": across all 136 series of the demo, ADF finds 136 of 136
stationary using {cmd:eta} and 103 of 136 using {cmd:zeta}. The default is
{cmd:eta}; {cmd:zeta} reproduces the Toolbox.

{pstd}
{bf:On restrict().} The Toolbox's own guidance for its demo is to restrict the
trend for inflation and for the short and long interest rates in every
country, which is {cmd:restrict(Dp r lr)}.

{pstd}
{bf:Comparing the two residual choices by the size of the cycle will not}
{bf:separate them.} The cycle is the OLS residual on a constant and a trend, hence
orthogonal to the trend by construction under either. Only a stationarity test
discriminates.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar tcdecomp, variables(usa:y euro:y china:y)}
        {cmd:. gvar tcdecomp, variables(usa:Dp usa:r) restrict(Dp r lr)}
        {cmd:. gvar tcdecomp, residuals(zeta)}
        {cmd:. gvar tcdecomp, variables(*:y) graph}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar tcdecomp} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(cycle)}}the cyclical component{p_end}
{synopt:{cmd:r(permanent)}}the permanent component{p_end}
{synopt:{cmd:r(permst)}}its stochastic part{p_end}
{synopt:{cmd:r(permdt)}}its deterministic part{p_end}
{synopt:{cmd:r(deviation)}}the check that cycle equals data minus permanent{p_end}
{synopt:{cmd:r(residuals)}}which residual was cumulated{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:TCdecomp.m}, {it:TC_trend_restr.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
