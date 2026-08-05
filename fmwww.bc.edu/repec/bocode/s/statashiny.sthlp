{smcl}
{* *! version 1.5.2 02aug2026 Eric A. Booth}{...}
{viewerjumpto "Syntax" "statashiny##syntax"}{...}
{viewerjumpto "Options" "statashiny##options"}{...}
{viewerjumpto "Description" "statashiny##description"}{...}
{viewerjumpto "Integration" "statashiny##integration"}{...}
{viewerjumpto "Examples" "statashiny##examples"}{...}
{viewerjumpto "How it fits together" "statashiny##model"}{...}
{viewerjumpto "Author" "statashiny##author"}{...}
{hline}
Help file for {hi:statashiny}
{hline}

{title:Title}

{phang}
{bf:statashiny} {hline 2} Build interactive calculators and dashboards from Stata


{marker syntax}{...}
{title:Syntax}

{pstd}
Consolidated Syntax (Recommended):

{phang2}
{cmd:statashiny} [{it:id}] {cmd:,} [ {opt i:nput(type)} | {opt o:utput(type)} | {opt c:alc(string)} | {opt build} ] [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr:Core Options}
{synoptline}
{synopt:{opt i:nput(type)}}Define an input component. {it:type} can be {cmd:num} (numeric input) or {cmd:check} (checkbox).{p_end}
{synopt:{opt o:utput(type)}}Define an output component. {it:type} can be {cmd:val} (card with a value), {cmd:table} (DataTable), or {cmd:raw} (raw HTML).{p_end}
{synopt:{opt c:alc(string)}}Add JavaScript logic to the {cmd:updateDashboard()} function.{p_end}
{synopt:{opt build}}Finalize and generate the HTML dashboard.{p_end}
{synoptline}

{marker options}{...}
{title:Options}

{pstd}
{bf:Initialization Options} (Used with {opt build} or on first call)

{phang}
{opt t:itle(string)}: Sets the dashboard title displayed at the top and in the browser tab.

{phang}
{opt subt:itle(string)}: Sets a subtitle displayed below the main title.

{phang}
{opt replace}: Required to overwrite an existing dashboard file.

{pstd}
{bf:Input/Output Options}

{phang}
{opt l:abel(string)}: The label or display text for the component.

{phang}
{opt val(string)}: Initial value for numeric inputs.

{phang}
{opt min(real)}, {opt max(real)}, {opt step(real)}: Constraints for numeric inputs.

{phang}
{opt checked}: Sets a checkbox to checked by default.

{phang}
{opt vars(varlist)}: Specifies variables from Stata memory to include in an {opt output(table)}.
Labeled numeric variables display their value-label text (e.g. {cmd:Foreign} instead of {cmd:1});
unlabeled values fall back to the number, string variables are shown as-is, and missing values
are blank.

{phang}
{opt toggles}: (With {opt output(table)}) Automatically generates column-toggling checkboxes in the sidebar.

{phang}
{opt prefix(string)}, {opt suffix(string)}: Text to prepend or append to card values (e.g., "$").

{pstd}
{bf:Build Options}

{phang}
{opt open}: Automatically opens the generated HTML file in your default web browser.

{phang}
{opt exp:ort(filename)}: Path/filename to write the dashboard HTML to. May be:

{p 12 14 2}{cmd: -} a plain filename ({cmd:dashboard.html}) — saved in the current Stata
working directory ({cmd:c(pwd)}){p_end}
{p 12 14 2}{cmd: -} a relative path ({cmd:reports/dashboard.html}) — saved relative to
the current working directory{p_end}
{p 12 14 2}{cmd: -} an absolute path ({cmd:/Users/me/Desktop/dash.html}) — used verbatim{p_end}

{phang2}
Default: {cmd:statashiny_dashboard.html} in the current working directory.
{bf:Tip:} when embedding the dashboard in another HTML page via an
{cmd:<iframe>}, browsers require the dashboard and the parent HTML to live
in the {it:same directory} when opened via {cmd:file://}
(see "Embedding into another HTML report" below).


{marker description}{...}
{title:Description}

{pstd}
{cmd:statashiny} generates standalone, interactive HTML dashboards from Stata. 
It uses Bootstrap 5 for layout, Chart.js for visualization, and DataTables for interactive tables. 
If no inputs are defined, the dashboard automatically adjusts to a full-width layout.


{marker model}{...}
{title:How it fits together}

{pstd}
A dashboard is assembled in four steps, in this order:{p_end}

{phang2}1. {cmd:statashiny, title("...") replace} starts a new dashboard.{p_end}
{phang2}2. {cmd:statashiny} {it:id}{cmd:, input(...)} adds a control; {cmd:output(...)} adds a panel.{p_end}
{phang2}3. {cmd:statashiny, calc("...")} adds JavaScript that runs whenever a control changes.{p_end}
{phang2}4. {cmd:statashiny, build} writes the file.{p_end}

{pstd}
The {it:id} you give in step 2 becomes the HTML element id, and that is the
only link between the two halves: {opt calc()} reaches a control or a panel with
{cmd:document.getElementById('}{it:id}{cmd:')}. {opt calc()} is raw JavaScript,
passed through untouched, so anything the browser understands works.{p_end}

{pstd}
{bf:Each dashboard needs its own} {opt replace}. The pieces accumulate in global
macros until an init clears them, so building a second dashboard without
{opt replace} carries the first one's panels along too. {cmd:build} reports how
many controls and panels it wrote -- if that count is higher than you expect,
that is the reason.{p_end}

{pstd}
{bf:All tables come from the data in memory when} {cmd:build} {bf:runs}, not from
whatever was loaded when {cmd:output(table)} was called. Several tables in one
dashboard therefore have to draw on the same dataset (different variables are
fine). Load the data, register the tables, then build.{p_end}


{marker integration}{...}
{title:Integration (iFrames) & Why Use This?}

{pstd}
{cmd:statashiny} dashboards are standalone HTML files. They can be easily embedded into 
existing websites, reports, or intranet pages using an HTML {cmd:<iframe>}.

{pstd}
Example code to embed a dashboard:

{phang2}
{cmd:<iframe src="http://fmwww.bc.edu/repec/bocode/s/statashiny_dashboard.html" width="100%" height="800px" frameborder="0"></iframe>}

{pstd}
{bf:Embedding into another HTML report — important:} When the parent HTML
is opened via {cmd:file://} (the default when you double-click an HTML
file in your file manager), modern browsers (Chrome, Safari, Firefox)
enforce the same-origin policy {it:per directory} for the {cmd:file://}
scheme — i.e. an iframe in {cmd:/Reports/page.html} cannot load
{cmd:/Dashboards/widget.html} even though both paths resolve correctly
on disk. The iframe silently fails (blank panel, or a CORS error in the
browser's JS console). Safari is the strictest; Chrome and Firefox are
slightly more permissive but still block cross-directory by default.

{pstd}
{bf:Fix:} write the dashboard into the {it:same directory} as the parent
report and use a relative path in the {cmd:<iframe>}:

{hline}
{cmd}
    statashiny, title("Searchable Auto Table") replace
    statashiny mytable, output(table) label("Auto Descriptives") ///
             vars(foreign price mpg weight length)
    statashiny, build export("mytable.html") open

    * In your parent HTML (anywhere in the same directory), write:
    *   <iframe src="http://fmwww.bc.edu/repec/bocode/s/mytable.html" width="100%" height="700px" frameborder="0"></iframe>
{txt}{hline}

{pstd}
Alternative: serve the directory with a one-liner local web server
({cmd:python3 -m http.server} from the report directory) and open the
report via {cmd:http://localhost:8000/} — that lifts the file:// restriction
entirely. Useful for testing dashboards that pull external resources.

{pstd}
{bf:Why use StataShiny?}
Interactivity is a powerful tool for policy communication. While a static regression 
output shows a point estimate, a StataShiny dashboard allows stakeholders to:
(1) {bf:Explore Scenarios}: What happens to predicted prices if MPG increases by 10%?
(2) {bf:Understand Interactions}: How does car origin change the relationship between weight and price?
(3) {bf:Visualize Uncertainty}: See how simulated sample sizes change the "precision" of your estimates.


{marker examples}{...}
{title:Examples}

{pstd}
{it:Copy and paste these examples into your do-file editor to run them.}

{marker example1}{...}
{pstd}
{bf:Example 1: Searchable DataTables (Simplest)}

{hline}
{cmd}
    * 1. Prepare data
    sysuse auto, clear
    collapse (mean) price mpg weight length (count) n=price, by(foreign)
    label var price "Mean Price"
    label var mpg "Mean MPG"
    label var weight "Mean Weight"
    label var length "Mean Length"
    
    * 2. Build Dashboard (No toggles = Full Width layout)
    statashiny, title("Searchable Auto Table") replace
    statashiny mytable, output(table) label("Automobile Descriptives") ///
             vars(foreign price mpg weight length n)
    statashiny, build open
{txt}{hline}


{marker example2}{...}
{pstd}
{bf:Example 2: Interactive Confidence Interval Explorer}

{hline}
{cmd}
    statashiny, title("Interactive CI Explorer") replace
    statashiny mean, input(num) label("Sample Mean") val(50) step(0.1)
    statashiny sd, input(num) label("Sample Std. Dev.") val(10) min(0.1)
    statashiny n, input(num) label("Sample Size (N)") val(100) min(2)
    statashiny z95, input(check) label("Use 95% CI") checked

    statashiny stats, output(val) label("Calculated CI")
    statashiny chart_area, output(val) label("Visual Distribution")

    statashiny, calc("if (!window.ciChart) { ")
    statashiny, calc("  let ctx = document.getElementById('chart_area'); ")
    statashiny, calc("  let cv = document.createElement('canvas'); ctx.appendChild(cv); ")
    statashiny, calc("  window.ciChart = new Chart(cv, { type: 'line', data: { labels: [], ")
    statashiny, calc("    datasets: [ { label: 'Curve', data: [], borderColor: '#0d6efd' }, ")
    statashiny, calc("    { label: 'CI', data: [], backgroundColor: 'rgba(13,110,253,0.2)', ")
    statashiny, calc("    fill: true, pointRadius: 0 } ] }, options: { scales: { y: { display: false } } } }); ")
    statashiny, calc("} ")

    statashiny, calc("let m = parseFloat(document.getElementById('mean').value); ")
    statashiny, calc("let s = parseFloat(document.getElementById('sd').value); ")
    statashiny, calc("let n = parseFloat(document.getElementById('n').value); ")
    statashiny, calc("let z = document.getElementById('z95').checked ? 1.96 : 2.58; ")
    statashiny, calc("let se = s / Math.sqrt(n); let low = m - z*se; let high = m + z*se; ")
    statashiny, calc("document.getElementById('stats').innerHTML = low.toFixed(2) + ' - ' + high.toFixed(2); ")

    statashiny, calc("let labels = []; let curve = []; let fill = []; ")
    statashiny, calc("for (let x = m - 4*s; x <= m + 4*s; x += s/10) { ")
    statashiny, calc("  labels.push(x.toFixed(1)); ")
    statashiny, calc("  let y = Math.exp(-0.5 * Math.pow((x-m)/s,2)) / (s*Math.sqrt(2*Math.PI)); ")
    statashiny, calc("  curve.push(y); fill.push((x >= low && x <= high) ? y : 0); ")
    statashiny, calc("} ")
    statashiny, calc("window.ciChart.data.labels = labels; window.ciChart.data.datasets[0].data = curve; ")
    statashiny, calc("window.ciChart.data.datasets[1].data = fill; window.ciChart.update(); ")

    statashiny, build open
{txt}{hline}


{marker example3}{...}
{pstd}
{bf:Example 3: Auto Policy & Scenario Simulator}

{hline}
{cmd}
    * 1. Run model and capture coefficients
    sysuse auto, clear
    reg price c.mpg##i.foreign weight
    local b_mpg = _b[mpg]
    local b_for = _b[1.foreign]
    local b_int = _b[1.foreign#c.mpg]
    local b_wgt = _b[weight]
    local b_con = _b[_cons]

    * 2. Build Dashboard
    statashiny, title("Auto Policy Simulator") replace
    statashiny n_obs, input(num) label("Effective Sample Size (N)") val(74) min(10) max(500)
    statashiny mpg, input(num) label("Scenario: Miles per Gallon") val(20) min(10) max(50)
    statashiny wgt, input(num) label("Scenario: Weight (lbs)") val(3000) min(1500) max(5000) step(10)
    statashiny is_for, input(check) label("Compare: Foreign Car Interaction") checked
    statashiny show_unc, input(check) label("Visualize Simulated Uncertainty")
    
    statashiny pred, output(val) label("Predicted Price (Scenario)") prefix("$")
    statashiny chart_box, output(raw) label("<div class='card statashiny-component'><div class='card-body'><h6>Marginal Effects & Simulated Confidence Bands</h6><div id='chart_area' style='height:350px;'></div></div></div>")

    * Pass Stata coefficients to JS
    statashiny, calc("let b_mpg = `b_mpg'; let b_for = `b_for'; let b_int = `b_int'; let b_wgt = `b_wgt'; let b_con = `b_con';")
    
    * Chart Setup
    statashiny, calc("if (!window.myChart) { ")
    statashiny, calc("  let ctx = document.getElementById('chart_area'); let cv = document.createElement('canvas'); ctx.appendChild(cv); ")
    statashiny, calc("  window.myChart = new Chart(cv, { type: 'line', data: { labels: [], ")
    statashiny, calc("    datasets: [ ")
    statashiny, calc("      {label: 'Prediction', data: [], borderColor: '#0d6efd', fill: false, zIndex: 10}, ")
    statashiny, calc("      {label: 'Uncertainty (Sim)', data: [], backgroundColor: 'rgba(108,117,125,0.1)', borderDash: [5,5], fill: true, pointRadius: 0} ")
    statashiny, calc("    ] }, options: { maintainAspectRatio: false, scales: { y: { min: 0 } } } }); ")
    statashiny, calc("} ")

    * Update Logic
    statashiny, calc("let m = parseFloat(document.getElementById('mpg').value); ")
    statashiny, calc("let w = parseFloat(document.getElementById('wgt').value); ")
    statashiny, calc("let n = parseFloat(document.getElementById('n_obs').value); ")
    statashiny, calc("let f = document.getElementById('is_for').checked ? 1 : 0; ")
    statashiny, calc("let u = document.getElementById('show_unc').checked; ")
    statashiny, calc("let p = b_con + b_mpg*m + b_for*f + b_int*(m*f) + b_wgt*w; ")
    statashiny, calc("document.getElementById('pred').innerHTML = p.toLocaleString(undefined, {maximumFractionDigits: 0}); ")
    
    statashiny, calc("let labels = []; let path = []; let high = []; let low = []; ")
    statashiny, calc("let se_sim = 2000 / Math.sqrt(n);")
    statashiny, calc("for(let x=10; x<=50; x+=2) { ")
    statashiny, calc("  labels.push(x); let val = b_con + b_mpg*x + b_for*f + b_int*(x*f) + b_wgt*w; ")
    statashiny, calc("  path.push(val); low.push(u ? val - 1.96*se_sim : val); high.push(u ? val + 1.96*se_sim : val); ")
    statashiny, calc("} ")
    statashiny, calc("window.myChart.data.labels = labels; window.myChart.data.datasets[0].data = path; ")
    statashiny, calc("window.myChart.data.datasets[1].data = high; window.myChart.data.datasets[1].fill = u ? 0 : false; ")
    statashiny, calc("window.myChart.update(); ")

    statashiny, build open
{txt}{hline}


{marker example4}{...}
{pstd}
{bf:Example 4: Normal Distribution Simulator (Histogram)}

{hline}
{cmd}
    statashiny, title("Histogram Simulator") replace
    statashiny obs, input(num) label("Sample Size") val(1000) min(100) step(100)
    statashiny bins, input(num) label("Bins") val(20) min(5) max(50)
    statashiny chart_container, output(val) label("Live Histogram")
    
    statashiny, calc("if (!window.hChart) { ")
    statashiny, calc("  let ctx = document.getElementById('chart_container'); ")
    statashiny, calc("  let cv = document.createElement('canvas'); ctx.appendChild(cv); ")
    statashiny, calc("  window.hChart = new Chart(cv, { type: 'bar', data: { labels: [], ")
    statashiny, calc("    datasets: [{label: 'Freq', data: [], backgroundColor: '#0dcaf0'}] } }); ")
    statashiny, calc("} ")
    statashiny, calc("let n = parseInt(document.getElementById('obs').value); ")
    statashiny, calc("let b = parseInt(document.getElementById('bins').value); ")
    statashiny, calc("let data = []; for(let i=0; i<n; i++) { let s=0; for(let j=0; j<6; j++) s+=Math.random(); data.push(s-3); } ")
    statashiny, calc("let counts = new Array(b).fill(0); ")
    statashiny, calc("data.forEach(v => { let idx = Math.floor(((v+3)/6)*b); if(idx>=0 && idx<b) counts[idx]++; }); ")
    statashiny, calc("window.hChart.data.labels = Array.from({length: b}, (_, i) => (i - b/2).toFixed(1)); ")
    statashiny, calc("window.hChart.data.datasets[0].data = counts; window.hChart.update(); ")
    
    statashiny, build open
{txt}{hline}


{marker example5}{...}
{pstd}
{bf:Example 5: Difference-in-Differences (DiD) Policy Explorer}

{pstd}
This example simulates a 12-year panel of US states to explore a hypothetical 
policy implementation. It demonstrates key causal inference concepts:

{pstd}
{bf:1. Parallel Trends Violation}: Checking this box adds a "drift" to the 
treated states {it:before} the policy begins. In the real world, we verify this 
by checking if treatment and control groups have similar slopes pre-policy. 
If they don't, the DiD estimate is {bf:biased}.

{pstd}
{bf:2. Statistical Power}: This is the probability of correctly finding an 
effect when one exists. In this simulator, Power is calculated as a function of 
{it:Effect Size}, {it:Sample Size (Treated States)}, {it:Noise}, and {it:Duration}. 
Notice how Power drops as you add Noise or move the Policy Year later (leaving 
less time to observe results).

{hline}
{cmd}
    * 1. Initialize Dashboard with Subtitle
    statashiny, title("DiD Policy Explorer") replace ///
             subtitle("Simulating Panel Data across 12 Years & 50 States")

    * 2. Interactive Parameters (Controls)
    statashiny p_year,  input(num) label("Policy Implementation Year") val(2028) min(2024) max(2032)
    statashiny p_eff,   input(num) label("True Policy Effect Size") val(5) step(0.1)
    statashiny p_noise, input(num) label("Data Noise (Volatility)") val(5) min(1)
    statashiny n_states,input(num) label("Number of Treated States") val(5) min(1) max(25)
    statashiny show_pt, input(check) label("Check Parallel Trends Violation") 

    * 3. Statistical Outputs
    statashiny est, output(val) label("Estimated DiD Coefficient")
    statashiny pow, output(val) label("Estimated Statistical Power") suffix("%")
    statashiny vis, output(raw) label("<div class='card statashiny-component'><div class='card-body'><h6>Event Study & Policy Trends</h6><div id='did_chart' style='height:400px;'></div></div></div>")

    * 4. JavaScript Engine (Logic)
    statashiny, calc("if (!window.didChart) { ")
    statashiny, calc("  let ctx = document.getElementById('did_chart'); let cv = document.createElement('canvas'); ctx.appendChild(cv); ")
    statashiny, calc("  window.didChart = new Chart(cv, { type: 'line', data: { labels: [], datasets: [ ")
    statashiny, calc("    {label: 'Treated (Avg)', data: [], borderColor: '#dc3545', fill: false}, ")
    statashiny, calc("    {label: 'Control (Avg)', data: [], borderColor: '#6c757d', fill: false} ")
    statashiny, calc("  ] }, options: { maintainAspectRatio: false } }); ")
    statashiny, calc("} ")

    statashiny, calc("let py = parseInt(document.getElementById('p_year').value); ")
    statashiny, calc("let pe = parseFloat(document.getElementById('p_eff').value); ")
    statashiny, calc("let noise = parseFloat(document.getElementById('p_noise').value); ")
    statashiny, calc("let n_tr = parseInt(document.getElementById('n_states').value); ")
    statashiny, calc("let pt_v = document.getElementById('show_pt').checked ? 0.8 : 0; ")

    statashiny, calc("let labels = []; let tr_data = []; let ct_data = []; ")
    statashiny, calc("for(let y=2024; y<=2035; y++) { ")
    statashiny, calc("  labels.push(y); ")
    statashiny, calc("  let base = 50 + (y-2024)*2; ")
    statashiny, calc("  let treat_base = base + (y-2024)*pt_v; ")
    statashiny, calc("  let treat_eff = (y >= py) ? pe : 0; ")
    statashiny, calc("  tr_data.push(treat_base + treat_eff + (Math.random()-0.5)*noise); ")
    statashiny, calc("  ct_data.push(base + (Math.random()-0.5)*noise); ")
    statashiny, calc("} ")

    statashiny, calc("window.didChart.data.labels = labels; window.didChart.data.datasets[0].data = tr_data; ")
    statashiny, calc("window.didChart.data.datasets[1].data = ct_data; window.didChart.update(); ")
    
    statashiny, calc("let diff_pre = (tr_data[0] - ct_data[0]); ")
    statashiny, calc("let diff_post = (tr_data[11] - ct_data[11]); ")
    statashiny, calc("let est_did = (diff_post - diff_pre).toFixed(2); ")
    statashiny, calc("document.getElementById('est').innerHTML = est_did; ")
    
    * More dynamic power formula: Power = f(Effect, N_treated, Noise, Post-Policy Years)
    statashiny, calc("let post_yrs = 12 - (py-2024); ")
    statashiny, calc("let pwr = Math.min(100, (n_tr * post_yrs * (Math.abs(pe)/(noise*2)) * 3)).toFixed(0); ")
    statashiny, calc("document.getElementById('pow').innerHTML = pwr; ")

    statashiny, build open
{txt}{hline}


{marker example6}{...}
{pstd}
{bf:Example 6: Dynamic UI -- the visible panel follows the input}

{pstd}
The Shiny gallery's {browse "https://shiny.posit.co/r/gallery/dynamic-user-interface/dynamic-ui/":dynamic UI}
demo redraws its controls when you change a selector. The same idea works here
without any new options, because every panel {cmd:statashiny} writes is an
ordinary page element and {opt calc()} is plain JavaScript: hide and show them
with {cmd:style.display}.{p_end}

{pstd}
Two things in this example are worth stealing. {cmd:closest('.statashiny-component')}
walks up from an output's id to the card that wraps it, so you can hide a whole
panel rather than just its contents. And the table writer leaves its rows in a
JavaScript array named {cmd:data_}{it:id}, so the summary cards below are computed
from exactly the same data the table shows -- no second pass over the data.{p_end}

{hline}
{cmd}
    sysuse auto, clear
    keep make price mpg weight foreign
    label var make "Model"
    label var price "Price"
    label var mpg "MPG"
    label var weight "Weight (lbs)"
    label var foreign "Origin"

    statashiny, title("Dynamic UI: the panel follows the input") ///
        subtitle("Move the selector - the dashboard shows a different panel") replace

    statashiny view, input(num) label("View: 1 = summary cards, 2 = data table") ///
        val(1) min(1) max(2) step(1)
    statashiny shownotes, input(check) label("Show the notes panel") checked

    * Panel A - two summary cards
    statashiny n_cars, output(val) label("Cars shown")
    statashiny avgprice, output(val) label("Mean price") prefix("$")

    * Panel B - the full table
    statashiny cars, output(table) label("Car detail") ///
        vars(make price mpg weight foreign)

    * Panel C - plain HTML, shown/hidden by the checkbox
    statashiny, output(raw) label("<div id='notes' class='card statashiny-component'><div class='card-body'><h6 class='small fw-bold'>Notes</h6><p class='small mb-0'>Panels are ordinary page elements.</p></div></div>")

    * The dynamic behaviour, one calc() per line
    statashiny, calc("var v = parseInt(document.getElementById('view').value); ")
    statashiny, calc("var card = function(id){ return document.getElementById(id).closest('.statashiny-component'); }; ")
    statashiny, calc("card('n_cars').style.display   = (v === 1) ? '' : 'none'; ")
    statashiny, calc("card('avgprice').style.display = (v === 1) ? '' : 'none'; ")
    statashiny, calc("card('cars').style.display     = (v === 2) ? '' : 'none'; ")
    statashiny, calc("document.getElementById('notes').style.display = document.getElementById('shownotes').checked ? '' : 'none'; ")
    statashiny, calc("document.getElementById('n_cars').textContent = data_cars.length; ")
    statashiny, calc("var s = 0; data_cars.forEach(function(r){ s += r[1]; }); ")
    statashiny, calc("document.getElementById('avgprice').textContent = Math.round(s / data_cars.length); ")
    statashiny, calc("if (v === 2 && window.table_cars) window.table_cars.columns.adjust(); ")

    statashiny, build open
{txt}{hline}

{pstd}
With {cmd:sysuse auto} this shows 74 cars and a mean price of 6165, matching
{cmd:summarize price}. Set the selector to 2 and the cards give way to the
table; untick the box and the notes panel disappears. The last {opt calc()}
line matters: a DataTable that was hidden when it was first drawn has no column
widths to work from, so ask it to recompute them when it becomes visible.{p_end}


{marker author}{...}
{title:Author}

{pstd}
Eric A. Booth{break}
Texas 2036{break}
Email: {browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}{break}
GitHub: {browse "https://www.github.com/ericabooth":www.github.com/ericabooth}
