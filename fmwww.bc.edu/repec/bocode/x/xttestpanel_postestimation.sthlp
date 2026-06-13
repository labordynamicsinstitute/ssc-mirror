{smcl}
{* *! version 1.0.0 09jun2026}{...}
{vieweralsosee "xttestpanel" "help xttestpanel"}{...}
{vieweralsosee "xttestpanel het" "help xttestpanel_het"}{...}
{vieweralsosee "xttestpanel serial" "help xttestpanel_serial"}{...}
{vieweralsosee "xttestpanel csd" "help xttestpanel_csd"}{...}
{vieweralsosee "xttestpanel func" "help xttestpanel_func"}{...}
{vieweralsosee "xttestpanel hausman" "help xttestpanel_hausman"}{...}
{vieweralsosee "xttestpanel vif" "help xttestpanel_vif"}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}
{vieweralsosee "xtreg postestimation" "help xtreg postestimation"}{...}
{viewerjumpto "Description" "xttestpanel_postestimation##desc"}{...}
{viewerjumpto "Syntax" "xttestpanel_postestimation##syntax"}{...}
{viewerjumpto "Supported estimators" "xttestpanel_postestimation##support"}{...}
{viewerjumpto "What is reused" "xttestpanel_postestimation##reuse"}{...}
{viewerjumpto "Which model each test uses" "xttestpanel_postestimation##models"}{...}
{viewerjumpto "Recommended workflow" "xttestpanel_postestimation##workflow"}{...}
{viewerjumpto "Worked example" "xttestpanel_postestimation##example"}{...}
{viewerjumpto "Reporting" "xttestpanel_postestimation##report"}{...}
{viewerjumpto "Notes and cautions" "xttestpanel_postestimation##notes"}{...}
{title:Title}

{phang}
{bf:xttestpanel postestimation} {hline 2} Postestimation diagnostics after {helpb xtreg}

{marker desc}{...}
{title:Description}

{pstd}
{cmd:xttestpanel} is designed to be used the way most applied researchers work:
{bf:fit your panel model once with} {helpb xtreg}{bf:, then run the diagnostics on
the model in memory}. When you call any subcommand {bf:without a varlist}, it reads
the dependent variable, the regressors, the model type (FE/RE/pooled) and the
estimation sample {cmd:e(sample)} directly from the last estimation results and runs
the test on exactly that specification.

{pstd}
Each subcommand also {bf:preserves and restores your} {cmd:e()}: it saves your
estimation results on entry and puts them back on exit (even if an error occurs).
You can therefore run as many tests as you like, in any order, after a single
{cmd:xtreg} -- without refitting and without losing your estimates.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtreg} {depvar} {indepvars} {ifin}{cmd:, fe}|{cmd:re}{p_end}

{p 8 17 2}
{cmd:xttestpanel} {it:subcommand} [{cmd:,} {it:options}]

{pstd}where {it:subcommand} is {helpb xttestpanel_het:het}, {helpb xttestpanel_serial:serial},
{helpb xttestpanel_csd:csd}, {helpb xttestpanel_func:func},
{helpb xttestpanel_hausman:hausman}, {helpb xttestpanel_vif:vif}, or {cmd:all}.

{marker support}{...}
{title:Supported estimators in memory}

{synoptset 22 tabbed}{...}
{synopt:{bf:Last command}}{bf:Detected model}{p_end}
{synoptline}
{synopt:{cmd:xtreg ..., fe}}one-way fixed effects{p_end}
{synopt:{cmd:xtreg ..., re}}one-way random effects{p_end}
{synopt:{cmd:regress ...}}pooled OLS (for {cmd:csd}){p_end}
{synopt:{cmd:reghdfe ...}}two-way fixed effects{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
If the test you request requires a different or additional model than the one in
memory (for example the FE-only functional-form test, the RE heteroskedasticity
variant, or the Hausman test that needs both FE and RE), {cmd:xttestpanel} refits
that model internally and prints a note; your own {cmd:e()} is restored afterwards.

{marker reuse}{...}
{title:What is reused from e()}

{p 8 8 2}o {bf:depvar} {hline 1} from {cmd:e(depvar)}.{p_end}
{p 8 8 2}o {bf:regressors} {hline 1} the column names of {cmd:e(b)} (the constant is dropped).{p_end}
{p 8 8 2}o {bf:model type} {hline 1} from {cmd:e(model)} / {cmd:e(cmd)} (overridable with {opt model()}).{p_end}
{p 8 8 2}o {bf:estimation sample} {hline 1} from {cmd:e(sample)}, so the tests use exactly the observations your model used.{p_end}

{marker models}{...}
{title:Which model each test uses}

{synoptset 16 tabbed}{...}
{synopt:{bf:Subcommand}}{bf:Model used}{p_end}
{synoptline}
{synopt:het}the model in memory (or {opt model(fe|re|tw)}){p_end}
{synopt:serial}the model in memory (FE or RE){p_end}
{synopt:csd}the model in memory (FE, RE or pooled){p_end}
{synopt:func}{bf:always FE} (Lin-Li-Sun is an FE test; refits FE if needed){p_end}
{synopt:hausman}{bf:both FE and RE} (fit internally; model in memory irrelevant){p_end}
{synopt:vif}the within design (FE) of the regressors{p_end}
{synoptline}
{p2colreset}{...}

{marker workflow}{...}
{title:Recommended workflow}

{pstd}Fit once, then test:{p_end}

{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xtreg y x1 x2 x3, fe}{p_end}
{phang2}{cmd:. xttestpanel all}{space 8}// whole battery + decision summary{p_end}

{pstd}or run individual tests with their graphs:{p_end}

{phang2}{cmd:. xttestpanel het,    graph}{p_end}
{phang2}{cmd:. xttestpanel serial, lags(2) graph}{p_end}
{phang2}{cmd:. xttestpanel csd,    graph}{p_end}
{phang2}{cmd:. xttestpanel vif,    graph}{p_end}
{phang2}{cmd:. xttestpanel hausman, graph}{p_end}
{phang2}{cmd:. xttestpanel func,   reps(299)}{p_end}

{pstd}
You can also get the whole battery plus a single combined diagnostic figure:{p_end}

{phang2}{cmd:. xttestpanel all, dashboard}{p_end}

{marker example}{...}
{title:Worked example}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. xtreg ln_wage age tenure hours, fe}{p_end}
{phang2}{cmd:. xttestpanel all}{p_end}
{phang2}{cmd:. xttestpanel het, graph}{p_end}
{phang2}{cmd:. xttestpanel serial, lags(2)}{p_end}

{pstd}
Switching the model in memory switches what the tests run on:{p_end}

{phang2}{cmd:. xtreg ln_wage age tenure hours, re}{p_end}
{phang2}{cmd:. xttestpanel het}{space 8}// now the RE heteroskedasticity variant{p_end}

{marker report}{...}
{title:Collecting results for a table}

{pstd}
Every subcommand returns its statistics in {cmd:r()}; {cmd:all} returns the headline
p-values. This makes it easy to build your own results table:{p_end}

{phang2}{cmd:. xtreg y x1 x2 x3, fe}{p_end}
{phang2}{cmd:. xttestpanel all}{p_end}
{phang2}{cmd:. scalar p_csd = r(p_csd)}{p_end}
{phang2}{cmd:. scalar p_ser = r(p_serial)}{p_end}
{phang2}{cmd:. scalar p_het = r(p_het)}{p_end}

{pstd}or, test by test:{p_end}

{phang2}{cmd:. xttestpanel csd}{p_end}
{phang2}{cmd:. di "Pesaran CD = " r(cd) "  p = " r(p_cd)}{p_end}

{marker notes}{...}
{title:Notes and cautions}

{p 8 8 2}o The data must be {helpb xtset} (panel and time variables).{p_end}
{p 8 8 2}o Time-series operators in the underlying tests assume reasonably regular
spacing; large gaps are skipped pair-by-pair.{p_end}
{p 8 8 2}o {cmd:func} is O(n{c 94}2) and is capped at n = 5000 observations.{p_end}
{p 8 8 2}o If you give a {it:varlist} explicitly, the command runs standalone and
ignores whatever is in {cmd:e()}; this is handy for ad-hoc checks but the
postestimation form is the recommended workflow.{p_end}
{p 8 8 2}o If no estimation results are in memory and you give no varlist,
{cmd:xttestpanel} stops with an informative error telling you to fit a model first
or to supply variables.{p_end}

{title:Also see}

{psee}
Overview:  {helpb xttestpanel}{p_end}
{psee}
Subcommands:  {helpb xttestpanel_het:het},
{helpb xttestpanel_serial:serial},
{helpb xttestpanel_csd:csd},
{helpb xttestpanel_func:func},
{helpb xttestpanel_hausman:hausman},
{helpb xttestpanel_vif:vif}{p_end}

{title:Author}
{pstd}Merwan Roudane {hline 1} merwanroudane920@gmail.com {hline 1}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
