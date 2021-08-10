*! version 3.3.0 07apr2017 daniel klein
program mimrgns
	version 11.2
	
	tempname mh
	.`mh' = .mimrgns_work.new `mh'
	
	version `= _caller()' : .`mh'.main `0'
end
exit

3.3.0	07apr2017	new mimrgns_work version 2.3.0
					new mimrgns_estimate version 2.1.1
3.2.1	11feb2017	new mimrgns_work version 2.2.1
3.2.0	03nov2016	new mimrgns_work version 2.2.0
					new mimrgns_estimate version 2.1.0
3.1.0	05aug2016	new mimrgns_work version 2.1.0
3.0.0	28jun2016	new mimrgns_work version 2.0.0
					new mimrgns_estimate version 2.0.0
					shift everything to mimrgns_work
2.1.6	15jan2016	new mimrgns_work version 1.1.1
2.1.5 	18aug2015	new mimrgns_work version 1.1.0
					change handle _rc in this file
2.1.4 	02jul2015	fix bug on Linux OS (could not find MiMrgns)
					rewrite and reorganize complete code
					new mimrgns_work.class
					new mimrgns_estimate.ado
2.1.3	18feb2015	fix bug with marginlist (triggered contrast)
					new output appropriate coeftitles
2.1.2	17feb2015	new output adds predict label and derivatives
					new output legend above tables
2.1.1	28jan2015	fix bug contrast/pwcompare opts (new _coef_table)
2.1.0	06jan2015	(limited) support for -contrast-
					report -at- legend (code adapted from StataCorp)
					remove -at- matrices if stats are specified
					fix bug with reporting and display options
					option -diopts- no longer documented
					rename subroutine -SetTableOpts- -SetOpts-
					new subroutine -AtLegend2-
2.0.1	30dec2014	(limited) support for -contrast- option
					nicer output for -contrast-
					subroutine -SetTableOpts- sets locals in caller
					sent to Evan Kontopantelis
					beta version (never released on SSC)
2.0.0	09oct2014	support -pwcompare- option
					default prediction is -xb-
					new output replays results (-_coef_table-)
					fix bug get cmd from e(cmdline_mi) not e(cmdline)
					fix bug ignored reporting and display options
					new option -eform-
					new option -diopts-
					new option -cmdmargins- (r|e(cmd) now -mimrgns-)
					new option -miopts- (not documented)
					rewrite code subroutine and Mata functions
1.1.2	18apr2014	fix bug with mixed models syntax (parsing on ||)
					add caller version support
					fix bug with options but no mi options
					fix bug with mi option -noisily-
					code polish remove matrices from results
1.1.1	27mar2014	fix bug ignored weights specified with -mimrgns-
1.1.0	27feb2014	remove potentially missleading/unclear results
					(limited) support for -margins-' -post- option
					Stata version 11.2 declared
					first version sent to SSC
1.0.2	24feb2014	global macros mimrgns_* no longer needed
1.0.1	24feb2014	fix problem with -mi-'s -post- and -eform- opts
					fix problem with -margins-' -at()- option
1.0.0	21feb2014	initial draft
