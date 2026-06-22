{smcl}
{* varck.sthlp | 鼎园会计 Dingyuan Accounting | varck 1.0.2 | 2026-06-21 *}
{hline}

{title:Title}

{p 4 4 2}
{bf:varck} -- Check existence of variables in Stata memory dataset
{p_end}

{title:Syntax}

{p 8 8 2}
{cmd:varck} {it:varlist} {cmd:,} {cmd:lang(cn} {cmd:|} {cmd:en} {cmd:|} {cmd:auto)} {cmd:detail} {cmd:table} {cmd:noisily}
{p_end}

{title:Description}

{p 4 4 2}
{bf:varck} checks whether specified variables exist in the dataset in memory.
It handles single or multiple variables, prints color-coded bilingual output
(Chinese / English), and is tailored for interactive data exploration in
accounting empirical research.
{p_end}

{p 4 4 2}
{bf:鼎园会计 (Dingyuan Accounting)} developed this program under the principle:
{it:Science for Good, Humanities as Norm} (科学向善，人文规范).
{p_end}

{title:Version History}

{p 4 4 2}
{bf:1.0.2} (2026-06-21) — Bugfix release.
{p_end}

{p 8 8 2}
Fixed detail mode display where variables concatenated on one line
due to {cmd:_continue} across loop iterations.
{p_end}

{p 8 8 2}
Replaced {cmd:%~60s} centering with SMCL {cmd:{center:}} to avoid
encoding artifacts with Unicode text.
{p_end}

{p 8 8 2}
Fixed unbalanced braces in example do-file (missing {cmd:}} before {cmd:else}).
{p_end}

{p 4 4 2}
{bf:1.0.1} (2026-06-21) — Bugfix release.
{p_end}

{p 8 8 2}
Fixed motto display (r/111, r/198) caused by literal double-quote
characters in macro values. Fixed table mode parsing error (r/198).
Fixed unbalanced braces in example do-file. Improved macro handling.
{p_end}

{p 4 4 2}
{bf:1.0.0} (2026-06-21) — Initial release.
{p_end}

{title:Options}

{p 4 4 2}
{cmd:lang(cn|en|auto)} -- output language.
Default is {cmd:auto}, which detects Stata's locale.
{p_end}

{p 4 4 2}
{cmd:detail} -- show type, label, format, and non-missing count for each
existing variable.
{p_end}

{p 4 4 2}
{cmd:table} -- compact side-by-side table (variable | status | type).
{p_end}

{p 4 4 2}
{cmd:noisily} -- verbose mode with accounting-specific tips.
{p_end}

{title:Remarks}

{p 4 4 2}
{bf:varck} fills a niche among Stata's variable-checking tools.
We compare it with official commands and community packages below.
{p_end}

{title:Comparison with Stata Official Commands}

{p 4 4 2}
{cmd:confirm variable} {it:varname} -- stops at the first missing variable
with error code 111. No cumulative summary. Programmatic, not interactive.
{p_end}

{p 4 4 2}
{cmd:describe} {it:varlist} -- errors if any variable is missing.
Cannot tell you which ones exist and which do not.
{p_end}

{p 4 4 2}
{cmd:unab} {it:abbrev} -- expands abbreviated names. Not designed for batch
checking or user-friendly reporting.
{p_end}

{p 4 4 2}
{bf:Key gaps:} (1) halt on first error, no summary;
(2) no bilingual support; (3) no human-friendly formatting;
(4) no accounting-specific guidance.
{p_end}

{title:Comparison with Third-Party Programs}

{p 4 4 2}
{help isvar##isvar:isvar} (NJC, 2005) -- separates a list into existing and
non-existing. {bf:Limitations:} minimal output (just two printed lists),
English only, no detail/table modes, no summary counts, no guidance.
{p_end}

{p 4 4 2}
{help checkfor2##checkfor2:checkfor2} (Diallo and Hardouin, 2020) -- adds
missing-value analysis with tolerance. {bf:Limitations:} English only,
heavyweight for simple existence checking, verbose output,
no accounting context.
{p_end}

{p 4 4 2}
{help ckvar##ckvar:ckvar} (2007) -- full error-checking framework using
characteristics and validation rules. {bf:Limitations:} complex setup,
designed for data validation not quick queries, English only.
{p_end}

{title:Innovations and Highlights of varck}

{p 4 4 2}
{bf:1. Bilingual Chinese/English.} First variable-checking utility with full
bilingual output. Auto-detects Stata locale. Valuable for Chinese accounting
researchers working with domestic (CSMAR, Wind, CNRDS) and international
(CRSP, Compustat, IBES) data.
{p_end}

{p 4 4 2}
{bf:2. Human-Centered Output.} Color-coded indicators (result for existing,
error for missing), visual symbols, clear summary counts, optional compact
table and verbose modes.
{p_end}

{p 4 4 2}
{bf:3. Accounting Research Orientation.} Designed for the typical workflow:
merge datasets from multiple vendors, check key financial variables
(ROA, ROE, leverage, accruals, etc.), identify naming discrepancies.
Includes accounting-specific diagnostic tips.
{p_end}

{p 4 4 2}
{bf:4. Progressive Information.} Three tiers: default (concise check plus
summary), {cmd:table} (side-by-side scan), {cmd:detail} (type, label,
format, non-missing N).
{p_end}

{p 4 4 2}
{bf:5. Rich Return Values.} Eight r-class macros and scalars:
{cmd:r(exist)}, {cmd:r(notexist)}, {cmd:r(n_total)}, {cmd:r(n_exist)},
{cmd:r(n_notexist)}, {cmd:r(all_exist)}, {cmd:r(any_exist)},
plus isvar-compatible {cmd:r(varlist)} and {cmd:r(badlist)}.
{p_end}

{p 4 4 2}
{bf:6. Non-Disruptive.} Unlike {cmd:confirm}, varck always completes with
a full report. Critical for interactive exploration.
{p_end}

{p 4 4 2}
{bf:7. Academic Identity.} Branded by 鼎园会计 (Dingyuan Accounting)
with the motto: 科学向善，人文规范.
{p_end}

{title:Stored Results}

{p 4 4 2}
Macros:
{p_end}

{p 8 8 2}
{cmd:r(exist)} -- existing variables (space-separated)
{p_end}
{p 8 8 2}
{cmd:r(notexist)} -- non-existing variables (space-separated)
{p_end}
{p 8 8 2}
{cmd:r(varlist)} -- same as r(exist); isvar-compatible
{p_end}
{p 8 8 2}
{cmd:r(badlist)} -- same as r(notexist); isvar-compatible
{p_end}

{p 4 4 2}
Scalars:
{p_end}

{p 8 8 2}
{cmd:r(n_total)} -- total variables queried
{p_end}
{p 8 8 2}
{cmd:r(n_exist)} -- number of existing variables
{p_end}
{p 8 8 2}
{cmd:r(n_notexist)} -- number of non-existing variables
{p_end}
{p 8 8 2}
{cmd:r(all_exist)} -- 1 if all exist, 0 otherwise
{p_end}
{p 8 8 2}
{cmd:r(any_exist)} -- 1 if at least one exists, 0 otherwise
{p_end}

{title:Examples}

{p 4 4 2}
Basic check:
{p_end}
{p 8 8 2}
    . {cmd:varck price mpg turn displacement}
{p_end}

{p 4 4 2}
Chinese output:
{p_end}
{p 8 8 2}
    . {cmd:varck price mpg turn, lang(cn)}
{p_end}

{p 4 4 2}
Table mode for many variables:
{p_end}
{p 8 8 2}
    . {cmd:varck roa roe lev size bm tobinq accrual, table}
{p_end}

{p 4 4 2}
Detailed metadata:
{p_end}
{p 8 8 2}
    . {cmd:varck _all_variables, detail}
{p_end}

{p 4 4 2}
Verbose with accounting tips:
{p_end}
{p 8 8 2}
    . {cmd:varck stkcd year industry roa roe, noisily lang(cn)}
{p_end}

{p 4 4 2}
Programmatic use:
{p_end}
{p 8 8 2}
    . varck roa roe lev size bm
{p_end}
{p 8 8 2}
    . if r(all_exist) {
{p_end}
{p 8 8 2}
    .     reg roa roe lev size bm
{p_end}
{p 8 8 2}
    . else {
{p_end}
{p 8 8 2}
    .     di as error "Missing variables: " r(notexist)
{p_end}
{p 8 8 2}
    . }
{p_end}

{title:Acknowledgments}

{p 4 4 2}
The development team extends our most sincere gratitude to
{bf:Professor Kit Baum} for his humility, generosity, and erudite scholarship.
We deeply appreciate his timely and sustained support of
{bf:鼎园会计 (Dingyuan Accounting)}.
{p_end}

{p 4 4 2}
varck is also inspired by the Stata community's variable-checking utilities
({cmd:isvar}, {cmd:checkfor2}, {cmd:ckvar}). We gratefully acknowledge
their contributions.
{p_end}

{title:Authors}

{p 4 4 2}
{bf:Wu Lianghai}
{p_end}
{p 8 8 2}
School of Business, Anhui University of Technology (AHUT)
{p_end}
{p 8 8 2}
Ma'anshan, Anhui, China
{p_end}
{p 8 8 2}
{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}
{p_end}

{p 4 4 2}
{bf:Yang Lu}
{p_end}
{p 8 8 2}
Rugao City Finance Bureau, Jiangsu Province
{p_end}
{p 8 8 2}
Jiangsu, China
{p_end}
{p 8 8 2}
{browse "mailto:1026835594@qq.com":1026835594@qq.com}
{p_end}

{p 4 4 2}
{bf:Hu Fangfang}
{p_end}
{p 8 8 2}
Wanjiang University of Technology (WJUT)
{p_end}
{p 8 8 2}
Ma'anshan, Anhui, China
{p_end}
{p 8 8 2}
{browse "mailto:huff470@163.com":huff470@163.com}
{p_end}

{p 4 4 2}
{bf:Chen Liwen}
{p_end}
{p 8 8 2}
School of Business, Anhui University of Technology (AHUT)
{p_end}
{p 8 8 2}
Ma'anshan, Anhui, China
{p_end}
{p 8 8 2}
{browse "mailto:2184844526@qq.com":2184844526@qq.com}
{p_end}

{p 4 4 2}
{bf:Wu Hanyan}
{p_end}
{p 8 8 2}
School of Economics and Management, NUAA
{p_end}
{p 8 8 2}
Nanjing, Jiangsu, China
{p_end}
{p 8 8 2}
{browse "mailto:2325476320@qq.com":2325476320@qq.com}
{p_end}

{p 4 4 2}
科学向善，人文规范 -- Science for Good, Humanities as Norm
{p_end}

{title:Also See}

{p 4 4 2}
{help isvar}, {help checkfor2}, {help ckvar}, {help confirm},
{help describe}, {help ds}
{p_end}

{hline}
{p 4 4 2}
varck 1.0.2 | 2026-06-21 | 鼎园会计 Dingyuan Accounting
{p_end}
