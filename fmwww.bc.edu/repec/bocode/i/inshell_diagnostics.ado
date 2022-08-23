*! 1.1 MBH 21 Aug  2022
*!   minor fixes
*! 1.0 MBH 14 July 2022
*!   this do-file is meant to accompany the shell wrapper -inshell-
*!   and functions as a "diagnostic" routine

capture program drop inshell_diagnostics

program define inshell_diagnostics
version 14

if lower(c(os)) == "windows" {
	display ///
		as error ///
			" >>> Sorry, but {bf:inshell} does not currently have a diagnostics mode for {bf:Microsoft Windows}. Stay tuned."
	exit 1
}

if missing(c(console)) cls

if missing("${INSHELL_DISABLE_LOGO}") {
	local sides `= min(int((min(`: set linesize', 128) - 51) / 2), 42)'
	noisily display ///
	  as result ///
	    "{dup `= `sides'*2+51':░}" _n "{dup `sides':░}{dup 43:░}   ░   ░{dup `sides':░}" _n "{dup `sides':▒}▒▒  {dup 19:▒}   {dup 17:▒}   ▒   ▒{dup `sides':▒}" _n "{dup `sides':▒}▒▒▒▒▒   ▒   ▒▒▒▒     ▒▒   {dup 9:▒}   ▒▒▒▒▒   ▒   ▒{dup `sides':▒}" _n "{dup `sides':▓}▓   ▓▓   ▓▓   ▓   ▓▓▓▓▓     ▓▓▓▓▓  ▓▓▓   ▓▓   ▓   ▓{dup `sides':▓}" _n "{dup `sides':▓}▓   ▓▓   ▓▓   ▓▓▓    ▓▓   ▓▓  ▓▓{space 9}▓▓   ▓   ▓{dup `sides':▓}" _n "{dup `sides':▓}▓   ▓▓   ▓▓   ▓▓▓▓▓   ▓  ▓▓▓   ▓  {dup 9:▓}   ▓   ▓{dup `sides':▓}" _n "{dup `sides':█}█   █    ██   █      ██  ███   ███     ████   █   █{dup `sides':█}" _n "{dup `= `sides'*2+51':█}"
	noisily display ///
	  as result "{it}{space `= `sides'+11'}the {ul:ultimate} Stata shell wrapper" _n ///
	  as text   "{it}{space `= `sides'+19'}by Matthew Bryant Hall"
}

*********************** macro options **************************
local non_toggle_options   INSHELL_TERM INSHELL_PATHEXT
local toggle_options       INSHELL_ENABLE_AUTOCD INSHELL_DISABLE_REFOCUS INSHELL_DISABLE_LONGCMDMSG
local toggled_on          : all globals "INSHELL_*ABLE*"
local toggled_off         : list toggle_options - toggled_on
local s1                  3

tempname pathextisvalid

if !missing("${INSHELL_PATHEXT}") {
	mata : st_numscalar("`pathextisvalid'", direxists("${INSHELL_PATHEXT}"))
	if scalar(`pathextisvalid') != 1 {
		local save_INSHELL_PATHEXT  "${INSHELL_PATHEXT}"
		macro drop INSHELL_PATHEXT
	}
}

local s2 = max(`s1', max(`: strlen global INSHELL_TERM', `: strlen global INSHELL_PATHEXT'))
local dist1 0

foreach a in `toggle_options' {
	if !missing("${`a'}") global `a' "ON"
}

foreach b in `non_toggle_options' `toggle_options' {
		if `: strlen local b' > `dist1' local dist1 `= `: strlen local b' + 7'
}

noisily display ///
	as text	_n " >>> {it}these are the current {stata help inshell##options:macro options} for {bf:inshell:}{sf}" _n

local maxofcol3 = max(`: strlen global INSHELL_TERM', `: strlen global INSHELL_PATHEXT', 3)
local dropcol  `= 3 + max(60, `maxofcol3', `= 43 + `: strlen global S_SHELL'')'

foreach c in `non_toggle_options' {
	if !missing("${`c'}") {
		if !strpos("${S_SHELL}", "pwsh") {
			noisily display ///
				as result  "{space `s1'}`c'"                                             ///
				as text    "{space `= `dist1' - `: strlen local c' + 2'}{it}is set to"   ///
				as result  _col(`= `dropcol' - 3 - `:strlen global `c''') "{sf}${`c'}"   ///
				as text    _col(`dropcol') `"[{stata "macro drop `macval(c)' ": drop }]"'
		}
		else if strpos("${S_SHELL}", "pwsh") {
			noisily display ///
				as result  "{space `s1'}`c'"                                             ///
				as text    "{space `= `dist1' - `: strlen local c' + 2'}{it} has been"   ///
				as error   _col(`= `dropcol' - 11') "{sf}{bf:DISABLED}"
		}
	}
	else if missing("${`c'}") {
		noisily display ///
			as result "{space `s1'}`c'"                                                ///
			as text   "{space `= `dist1' - `: strlen local c' + 1'}{it}is {ul:not} set{sf}"
	}
}

foreach d in `toggled_on' {
	if !missing("${`d'}") {
		noisily display ///
			as result "{sf}{space `s1'}`d'"                                           ///
			as text   "{space `= `dist1' - `: strlen local d''}{it} is toggled"       ///
			as input  _col(`= `dropcol' - 5')  "{sf}{bf:ON}"                          ///
			as text   _col(`dropcol')      `"[{stata "macro drop `macval(d)' ": drop }]"'
	}
}

foreach e in `toggled_off' {
	noisily display ///
		as result "{sf}{space `s1'}`e'"                                             ///
		as text   "{space `= `dist1' - `: strlen local e''}{it} is toggled"         ///
		as error  _col(`= `dropcol' - 6') "{sf}{bf:OFF}"
}

if !missing("${INSHELL_TERM}") | !missing("${INSHELL_PATHEXT}") | !missing("${INSHELL_DISABLE_REFOCUS}") | !missing("${INSHELL_DISABLE_LONGCMDMSG}") | !missing("${INSHELL_ENABLE_AUTOCD}") {
	noisily display ///
		as text	_col(`dropcol') `"[{stata "macro drop INSHELL*" : drop ALL }]"' _n
}
else noisily display _n
*********************** S_SHELL **************************
if !missing("${S_SHELL}") {
	if strpos("${S_SHELL}", "//") {
		global S_SHELL = subinstr("${S_SHELL}", "//", "/", .)
	}
	noisily display ///
		as text       " >>> {bf:global} {it}shell macro "                                      ///
		as result     "{bf:S_SHELL}"                                                           ///
		as text       "{space `= `s1' - 2'}is set to{sf}"                                      ///
		as result    `"{space `= min(20 - `: strlen global S_SHELL', 4)'}${S_SHELL}{space 1}"' ///
		as text  _col(`dropcol') `"[{stata `"macro drop S_SHELL"': drop S_SHELL macro }]"'
}
************************** shell ********************************
capture noisily inshell_getshell
************************** PATH **************************
tempfile pathfile
if !strpos("${S_SHELL}", "pwsh") {
	capture quietly shell echo \$PATH > "`pathfile'"
}
capture confirm file "`pathfile'"
if (!_rc) {
	local get_path = subinstr(fileread("`pathfile'"), char(10), "", .)
}
if missing("`get_path'") {
	// the following lines are intended for Microsoft PowerShell
	tempfile pwsh_pathfile
	quietly shell \$ENV:PATH > `pwsh_pathfile'
	local get_path = subinstr(fileread("`pwsh_pathfile'"), char(10), "", .)
}
foreach f in `non_toggle_options' {
	if !missing("${`f'}") & strpos("${S_SHELL}", "pwsh") {
		// noisily display ///
		// 	as error ///
		// 		_n " >>> {bf:inshell} macro option `f' is set when global shell macro {bf:S_SHELL} is set to use {bf:Microsoft PowerShell} as Stata's {it:default} shell. This is not allowed. Only Unix shells are supported by this option. However, the setting has been overidden with no adverse risk to the user or their system."
			continue, break
	}
}
if (!missing("${INSHELL_PATHEXT}") & strpos("${S_SHELL}", "pwsh")) | !strpos("${S_SHELL}", "pwsh") {
	noisily display ///
		as text ///
			" >>> {it}your {bf:PATH} when using {bf:shell}`= cond("${INSHELL_PATHEXT}" != "" & strpos("${S_SHELL}", "pwsh") | "${INSHELL_PATHEXT}" == "", " {ul:and} {bf:inshell} ", " ")'is:{sf}" _n ///
		as result "{space `s1'}`get_path'" _n
}

if !strpos("${S_SHELL}", "pwsh") {
	capture which inshell
	if (!_rc) {
		capture inshell echo \$PATH
		local inshell_path "`r(no1)'"
		if !missing("${INSHELL_PATHEXT}") {
				local inshell_path_compare    `: subinstr local inshell_path ":" " ", all'
				local stata_path_compare      `: subinstr local get_path     ":" " ", all'
				local path_diff               `: list inshell_path_compare - stata_path_compare'
				if "`path_diff'" == "${INSHELL_PATHEXT}" local check "✅"
				noisily display ///
					as text     " >>> {it}your {ul:extended} {bf:PATH} when using {bf:inshell} is:{sf}" _n ///
					as result   "{space `s1'}`inshell_path'" _n
				noisily display ///
					as text     " >>> {it}the difference being that"     ///
					as result   "{sf} `path_diff' `check' "              ///
					as text     "{it} has been added to the beginning of your {bf:PATH}"
		}
	}
}
************************** invalid INSHELL_PATHEXT **************************************
if !missing("`save_INSHELL_PATHEXT'") {
	if scalar(`pathextisvalid') != 1 {
		noisily display ///
			as error  _n " >>>  {bf:inshell} path extension macro {bf:INSHELL_PATHEXT} was set to "    ///
			as text   "`save_INSHELL_PATHEXT'"                                                  _n  ///
			as error  " >>> Either this directory does not exist or it is inaccessible."        _n  ///
				" >>> As a result this program has cleared the INSHELL_PATHEXT macro."
	}
}

end
