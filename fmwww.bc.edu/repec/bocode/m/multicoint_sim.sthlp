{smcl}
{* *! version 1.0.0  18may2026}{...}
{cmd:help multicoint_sim}{right: (part of {bf:multicoint})}
{hline}

{title:Title}

{phang}
{bf:multicoint_sim} {hline 2} Simulate a multicointegrated time-series DGP

{title:Package}

{p 4 6 2}
This command is part of the {helpb multicoint} library
({help multicoint##syntax:main}, {helpb multicoint_graph},
{helpb multicoint_cv}).

{title:Syntax}

{p 8 14 2}
{cmd:multicoint_sim} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt n(#)}}sample size (default 200){p_end}
{synopt :{opt b:eta(#)}}cointegration coefficient on x (default 1){p_end}
{synopt :{opt g:amma(#)}}multicointegration coefficient on Δx (default 1){p_end}
{synopt :{opt a:lpha(#)}}intercept{p_end}
{synopt :{opt tr:end(#)}}linear-trend coefficient (default 0){p_end}
{synopt :{opt sige(#)}}std-dev of multicoint error (default 1){p_end}
{synopt :{opt sigx(#)}}std-dev of x innovation (default 1){p_end}
{synopt :{opt sigcoint(#)}}std-dev of coint error innovation (default 1){p_end}
{synopt :{opt reg:ime(name)}}{bf:multicoint} (default), {bf:coint}, or {bf:none}{p_end}
{synopt :{opt seed(#)}}random-number seed (default 12345){p_end}
{synopt :{opt clear}}clear data in memory before simulating{p_end}
{synopt :{opt replace}}replace existing data{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:multicoint_sim} generates {it:T} observations from a bivariate
multicointegrated DGP that matches the Granger-Lee (1989, 1990) inventory
example.  Three regimes are supported.

{phang2}{bf:regime(multicoint)} (default){p_end}
{pmore}
y_t and x_t are I(1) flows, cointegrated at the first level, and their
cumulated sums Y_t, X_t admit a {bf:second} long-run relationship
Y_t = α + β X_t + γ x_t + e_t with e_t ∼ I(0).

{phang2}{bf:regime(coint)}{p_end}
{pmore}
y_t and x_t are I(1) and cointegrated only at the first level; there is
{bf:no} multicointegration channel.

{phang2}{bf:regime(none)}{p_end}
{pmore}
y_t and x_t are independent random walks.

{pstd}
Variables created: {bf:y x Y X mc_resid t}.  The data are time-set on
{bf:t}, ready for use with {helpb multicoint}.

{title:Examples}

{phang}{bf:1.  Default multicoint DGP, sample of 200}{p_end}
{p 8 16 2}{stata "multicoint_sim, clear"}{p_end}
{p 8 16 2}{stata "multicoint y x, est(taols) test(all)"}{p_end}

{phang}{bf:2.  No multicointegration (regime=coint) - tests should not reject}{p_end}
{p 8 16 2}{stata "multicoint_sim, regime(coint) n(300) clear"}{p_end}
{p 8 16 2}{stata "multicoint y x, est(fmols) test(all)"}{p_end}

{phang}{bf:3.  No relationship at all}{p_end}
{p 8 16 2}{stata "multicoint_sim, regime(none) clear"}{p_end}
{p 8 16 2}{stata "multicoint y x, est(ols) test(all)"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.{p_end}

{title:Also see}

{psee}Online:  {helpb multicoint}, {helpb multicoint_graph}, {helpb multicoint_cv}{p_end}
