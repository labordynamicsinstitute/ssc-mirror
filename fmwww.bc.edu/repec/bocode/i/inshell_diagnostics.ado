*! 1.5 MBH 27 Dec 2022
*! this program accompanies -inshell- and functions as a "diagnostic" routine
**!   includes numerous small coding improvements
**! 1.4 MBH 27 Nov 2022
**!   includes an error message directing the user to toggle global macro option
**!    INSHELL_SETSHELL_CSH if it is not properly set
**! 1.3 MBH 15 Oct 2022
**!   compatibility with -inshell- version 2.6
**! 1.2 MBH 13 Sept 2022
**!   minor stylistic changes
**! 1.1 MBH 21 Aug  2022
**!   minor fixes
**! 1.0 MBH 14 July 2022

program define inshell_diagnostics
version 14

if (lower(c(os)) == "windows") {
	display as error ///
		"{p 2 1} >>> Sorry, but {bf:inshell} does not currently have a diagnostics mode for {bf:Microsoft Windows}. Stay tuned."
	exit 1
}

if (missing(c(console))) cls

if (missing("${INSHELL_DISABLE_LOGO}")) {
	local left  = int((c(linesize) - 49) / 2)
	local right = c(linesize) - 49 - `left'
	display as result ///
	  "`="░"*c(linesize)'"                                                                 _n ///
	  "`="░"*`=`left'-1''`="░"*42'   ░   ░`="░"*`right''"                                  _n ///
	  "`="▒"*`=`left'''  `="▒"*19'   `="▒"*17'   ▒   ▒`="▒"*`right''"                      _n ///
	  "`="▒"*`=`left'-1''▒▒▒▒   ▒   ▒▒▒▒     ▒▒   ▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒   ▒   ▒`="▒"*`right''" _n ///
	  "`="▓"*`=`left'-1''   ▓▓   ▓▓   ▓   ▓▓▓▓▓     ▓▓▓▓▓  ▓▓▓   ▓▓   ▓   ▓`="▓"*`right''" _n ///
	  "`="▓"*`=`left'-1''   ▓▓   ▓▓   ▓▓▓    ▓▓   ▓▓  ▓▓         ▓▓   ▓   ▓`="▓"*`right''" _n ///
	  "`="▓"*`=`left'-1''   ▓▓   ▓▓   ▓▓▓▓▓   ▓  ▓▓▓   ▓  ▓▓▓▓▓▓▓▓▓   ▓   ▓`="▓"*`right''" _n ///
	  "`="█"*`=`left'-1''   █    ██   █      ██  ███   ███     ████   █   █`="█"*`right''" _n ///
	  "`="█"*c(linesize)'"
	display ///
	  as result "{it}{space `= `left' + 9'}the {ul:ultimate} Stata shell wrapper" _n ///
	  as text   "{it}{space `= `left' + 17'}by Matthew Bryant Hall"
}

*********************** macro options *********************************************************
local non_toggle_options   INSHELL_TERM                      ///
													 INSHELL_PATHEXT                   ///
													 INSHELL_TAB_SPACES
local toggle_options       INSHELL_ENABLE_AUTOCD             ///
 													 INSHELL_DISABLE_REFOCUS           ///
													 INSHELL_DISABLE_LONGCMDMSG        ///
													 INSHELL_SETSHELL_CSH
local toggled_on         `: all globals "INSHELL_*ABLE*" ' `: all globals "INSHELL_SET*"'
local toggled_off         : list toggle_options - toggled_on
local s1                  3

if (!missing("${INSHELL_PATHEXT}")) {
	tempname pathextisvalid
	mata : st_numscalar("`pathextisvalid'", direxists("${INSHELL_PATHEXT}"))
	if (scalar(`pathextisvalid') != 1) {
		local save_INSHELL_PATHEXT  "${INSHELL_PATHEXT}"
		macro drop INSHELL_PATHEXT
	}
}

local s2 = max(`s1', `: strlen global INSHELL_TERM', `: strlen global INSHELL_PATHEXT', `: strlen global INSHELL_TAB_SPACES')
local dist 0

foreach a in `toggle_options' {
	if (!missing("${`a'}")) global `a' "ON"
}

foreach b in `non_toggle_options' `toggle_options' {
		if (`: strlen local b' > `dist') {
			local dist `= `: strlen local b' + 7'
		}
}

display as text ///
	_n " >>> {it}these are the current {help inshell##options :macro options} for {bf:inshell:}{sf}" _n

local maxofcol3 = max(`: strlen global INSHELL_TERM', `: strlen global INSHELL_PATHEXT', 3)
local dropcol   = 3 + max(60, `maxofcol3', `= 43 + `: strlen global S_SHELL'')

foreach c in `non_toggle_options' {
	if (!missing("${`c'}")) {
		if (!strpos("${S_SHELL}", "pwsh")) {
			display ///
				as result  "{space `s1'}`c'"                                              ///
				as text    "{space `= `dist' - `: strlen local c' + 2'}{it}is set to"     ///
				as result  _col(`= `dropcol' - 3 - `: strlen global `c''') "{sf}${`c'}"   ///
				as text    _col(`dropcol') `"[{stata "macro drop `macval(c)' ": drop }]"'
		}
		else if (strpos("${S_SHELL}", "pwsh")) {
			display ///
				as result  "{space `s1'}`c'"                                            ///
				as text    "{space `= `dist' - `: strlen local c' + 2'}{it} has been"   ///
				as error   _col(`= `dropcol' - 11') "{sf}{bf:DISABLED}"
		}
	}
	else if (missing("${`c'}")) {
		display ///
			as result "{space `s1'}`c'"                                                    ///
			as text   "{space `= `dist' - `: strlen local c' + 1'}{it}is {ul:not} set{sf}"
	}
}

foreach d in `toggled_on' {
	if (!missing("${`d'}")) {
		display ///
			as result "{sf}{space `s1'}`d'"                                               ///
			as text   "{space `= `dist' - `: strlen local d''}{it} is toggled"            ///
			as input  _col(`= `dropcol' - 5')  "{sf}{bf:ON}"                              ///
			as text   _col(`dropcol')      `"[{stata "macro drop `macval(d)' ": drop }]"'
	}
}

foreach e in `toggled_off' {
	display ///
		as result "{sf}{space `s1'}`e'"                                     ///
		as text   "{space `= `dist' - `: strlen local e''}{it} is toggled"  ///
		as error  _col(`= `dropcol' - 6') "{sf}{bf:OFF}"
}

if ((!missing("${INSHELL_TERM}")) | (!missing("${INSHELL_PATHEXT}")) | (!missing("${INSHELL_DISABLE_REFOCUS}")) | (!missing("${INSHELL_DISABLE_LONGCMDMSG}")) | (!missing("${INSHELL_ENABLE_AUTOCD}")) | (!missing("${INSHELL_TAB_SPACES}")) | (!missing("${INSHELL_SETSHELL_CSH}"))) {
	display as text ///
		_col(`dropcol') `"[{stata "macro drop INSHELL*" : drop ALL }]"' _n
}
else display _n
*********************** S_SHELL ***************************************************************
if (!missing("${S_SHELL}")) {
	if (strpos("${S_SHELL}", "//")) {
		global S_SHELL = subinstr("${S_SHELL}", "//", "/", .)
	}
	display ///
		as text       " >>> {bf:global} {it}shell macro "                                      ///
		as result     "{bf:S_SHELL}"                                                           ///
		as text       "{space `= `s1' - 2'}is set to{sf}"                                      ///
		as result    `"{space `= max(min(20 - `: strlen global S_SHELL', 4), 1)'}${S_SHELL}{space 1}"' ///
		as text  _col(`dropcol') `"[{stata `"macro drop S_SHELL"': drop S_SHELL macro }]"'
}
************************** shell **************************************************************
capture noisily inshell_getshell
if ((strpos(r(shell), "csh")) & (missing("${INSHELL_SETSHELL_CSH}")) & (!strpos("${S_SHELL}", "csh"))) {
	local profile_os = substr(lower(c(os)), 1, 1)
	display as error ///
		`"{p 2 1}{cmd:inshell} has detected that your default shell is a {bf:csh}-type shell, however, global macro option {bf:INSHELL_SETSHELL_CSH} is unset. This option is required to be toggled {bf:ON} if your default shell is a {bf:csh}-type shell. [{stata "global INSHELL_SETSHELL_CSH ON": Click here to set it }]"' ///
		_n `"Furthermore, it is recommended that you set this within your {cmd:profile.do} so that it will persist across launches of Stata. See [{help profile`profile_os': help profile`profile_os' }] for more information."' _n
}
************************** PATH ***************************************************************
tempfile pathfile
if (!strpos("${S_SHELL}", "pwsh")) {
	quietly shell echo \$PATH > "`pathfile'"
}
capture confirm file "`pathfile'"
if (!_rc) {
	local get_path = subinstr(fileread("`pathfile'"), char(10), "", .)
}
if (missing("`get_path'")) {
	// the following lines are intended for Microsoft PowerShell
	tempfile pwsh_pathfile
	quietly shell \$ENV:PATH > "`pwsh_pathfile'"
	local get_path = subinstr(fileread("`pwsh_pathfile'"), char(10), "", .)
}

if ((!missing("${INSHELL_PATHEXT}") & (strpos("${S_SHELL}", "pwsh"))) | (!strpos("${S_SHELL}", "pwsh"))) {
	display as text ///
		" >>> {it}your {bf:PATH} when using {bf:shell}`= cond((missing("${INSHELL_PATHEXT}")) & (strpos("${S_SHELL}", "pwsh")) | (missing("${INSHELL_PATHEXT}")), " {ul:and} {bf:inshell} ", " ")'is:{sf}" _n ///
		as result "{space `s1'}`get_path'" _n
}

if (!strpos("${S_SHELL}", "pwsh")) {
	capture which inshell
	if (!_rc) {
		capture inshell echo \$PATH
		local inshell_path = r(no1)
		if (!missing("${INSHELL_PATHEXT}")) {
			local inshell_path_compare    `: subinstr local inshell_path ":" " ", all'
			local stata_path_compare      `: subinstr local get_path     ":" " ", all'
			local path_diff               `: list inshell_path_compare - stata_path_compare'
			if ("`path_diff'" == "${INSHELL_PATHEXT}") local check "✅"
			display ///
				as text  " >>> {it}your {ul:extended} {bf:PATH} when using {bf:inshell} is:{sf}" _n ///
				as result  "{space `s1'}`inshell_path'" _n
			display ///
				as text    " >>> {it}the difference being that"     ///
				as result  "{sf} `path_diff' `check' "              ///
				as text    "{it} has been added to the beginning of your {bf:PATH}"
		}
	}
}
************************** invalid INSHELL_PATHEXT ********************************************
if (!missing("`save_INSHELL_PATHEXT'")) {
	if (scalar(`pathextisvalid') != 1) {
	display as error ///
		_n " >>>  {bf:inshell} path extension macro {bf:INSHELL_PATHEXT} was set to "      ///
		as text  "`save_INSHELL_PATHEXT'"                                               _n ///
		as error  " >>> Either this directory does not exist or it is inaccessible."    _n ///
		" >>> As a result this program has cleared the {bf:INSHELL_PATHEXT} macro."
	}
}

end
