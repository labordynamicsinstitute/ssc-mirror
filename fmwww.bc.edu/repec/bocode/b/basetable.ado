*! Package basetable v 0.2.8
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*version 0.2.8  2022-12-28 > category row titles in italics for style markdown see code in ::log_print()
*version 0.2.8  2022-12-22 > Bug in option toxl fixed. Now more tables can be saved in the same sheet 
*version 0.2.8  2022-04-20 > Option noTOPcount now only for first row
* TODO: Count unique by
*version 0.2.7  2021-11-19 > number format and pct format for missing report too 
*version 0.2.7  2021-11-19 > Help rewritten 
*version 0.2.6  2021-05-24 > Bug in basetable_parser(): basetable::n_pct_by_value() not called when value ends on r. Thanks to Kasper Norman
*version 0.2.6  2021-04-15 > NoTotal and NoPvalue now also for toxl
*version 0.2.5a 2021-01-28 > Bug fixes
*version 0.2.5  2020-12-28 > Converted to ltoxl_v1[34].mata and added columnwidth for toxl
*version 0.2.5  2020-12-07 > varlists instead of varnames
*version 0.2.5  2020-12-07 > First variable _none
*version 0.2.5  2020-12-07 > Overall if kept
*version 0.2.4  2020-10-07 > Bug in basetable::n_pct_by_value() fixed
*version 0.2.4  2020-10-07 > Categorical report as option
*version 0.2.4  2020-10-07 > Fisher's exact test as option
*version 0.2.3	2019-09-13 > 95% ci for geometric mean is added (gci)
*version 0.2.3	2019-08-12 > bugfix quotation around `r(fn)' after run: if "`r(fn)'" != "" & !`toxl_exists' run `"`r(fn)'"'
*version 0.2.3	2019-06-13 > Smothing/bluring are renamed to pseudo percentiles
*version 0.2.3	2019-06-11 > median/deciles as range and interval added
*version 0.2.3	2019-06-11 > Caption/Title added
*version 0.2.3	2019-03-07 > median/range as range and interval added
*version 0.2.2	2019-02-27	> lmatrixtools.mata updated
*version 0.2.1	2018-10-04	> Option for smoothing data when returning median and quartiles
*version 0.2.1	2018-09-20	> Variable label in header
*version 0.2.1	2018-09-20	> Right adjusted table output in toxl excel books, v14 and up
*version 0.2.1	2018-09-20	> Option for column witdh in toxl option, v14 and up
*version 0.2.1	2018-09-18	> Option for drop p-value in print
*version 0.2.1	2018-09-18	> Option for drop total in print
*version 0.2.1	2018-09-17	> Hidesmall for for missings
*version 0.2.0	2017-08-31	> Option pvalueformat is changed to pvformat (as used in the documentation)
*version 0.1.9	2017-03-12	> Bug calculating slct in basetable::n_pct_by_value() fixed
*version 0.1.9	2017-07-26	> Problem with . and : in nhb_sae_summary_row() in variable labels solved for version 14 and up
*version 0.1.9	2017-07-17	> Bug in nhb_msa_variable_description() and nhb_mt_matrix_v_sep() regarding value labels fixed
*version 0.1.9	2017-06-09	> bugfix when repeating basetable after style md
*version 0.1.9	2017-06-09	> latex tablefit in nhb_mt_mata_string_matrix_styled
*version 0.1.8	2017-03-21	> Thousands separator count. Claus Hørup
*version 0.1.8	2017-03-12	> Code partly based on lmatrixtools
*version 0.1.8	2017-03-12	> CI for proportions. Christine Geyti
*version 0.1.8	2017-03-12	> Test values with different decimals, default 2. Christine Geyti
*version 0.1.8	2017-03-12	> col/row pct to col/row %. Christine Geyti
*version 0.1.8	2017-01-18  > Handling all missing values for a variable
*version 0.1.7	2016-09-01	> summarize_by() in lbasetable, all continous variables: Now total correct, when colvar has missing values
*version 0.1.7	2016-09-01	> Error in using output corrected
*version 0.1.7	2016-09-01	> MD modified
*version 0.1.7	2016-09-01	> Caption added
*version 0.1.6	2016-02-24	> Runs at version 12
*version 0.1.6	2016-02-24	> Local if in headers! NOT local in -  can't be controlled. Note error text from comparing medians !!!!
*version 0.1.6	2016-02-24	> Output as xl, csv, md, html and LaTex
*version 0.1.6	2016-02-24	> Option Using together with output except xl - replace append
*version 0.1.6	2016-02-24	> Validate Continousreport and style
*version 0.1.5	2016-02-24	> Most Mata code back in mlib
*version 0.1.41	17dec2015	> Bug with value label has to have same name as variable fixed. Thank you to Richard Goldstein
*version 0.1.41	17dec2015	> Function to validate variable refined
*version 0.1.4	02nov2015	> Global if and in are added, nhb
*version 0.1.4	02nov2015	> Better (as text row/col) marker row/col total in n_pct_by, nhb
*version 0.1.4	02nov2015	> Local type of summary for continous variables. Thank you to Pia Deichgræber
*version 0.1.4	02nov2015	> replace for book and sheet. Thank you to Georgios Bouliotis and Pia Deichgræber
*version 0.1.4	02nov2015	> Tabulate function like summary_by, nhb
*version 0.1.4	02nov2015	> Function summary_by as base for continous variables, nhb
*version 0.1.4	02nov2015	> pi prediction interval, nhb
*version 0.1.4	02nov2015	> iqi interquartile interval, nhb
*version 0.1.4	02nov2015	> Handle when Stata do not return all columns, crashes now - ignored report, nhb
*version 0.1.4	02nov2015	> Hidesmall works on totals, nhb
*version 0.1.4	02nov2015	> Insert Header, nhb
*version 0.1.4	02nov2015	> Logging optional, nhb
*version 0.1.4	02nov2015	> Missing table optional. Thank you to Richard Goldstein
*version 0.1.4	02nov2015	> Move all Mata to basetable.ado, nhb 
*version 0.1.31	13aug2015	> Bug with hidesmall fixed. Thank you to Georgios Bouliotis
*version 0.1.3	05aug2015	> Total and missing report added
*version 0.1.2	06may2015	> toxl is moved from mlib to ado file due to version 14. Tahnk you to Eric Melse

version 12

program define basetable
	* input_list is required by syntax, so input_list is not empty 
	syntax anything(name=input_list) [if] [in] [using/] /*
		*/[,/*
			*/Toxl(string) /*
			*/Nthousands /*
			*/PCtformat(string) /*
			*/PVformat(string) /*
			*/Continuousreport(string) /*
			*/TItle(string) /*
			*/CAPtion(string) /*
			*/top(string) /*
			*/undertop(string) /*
			*/bottom(string) /*
			*/Log /*
			*/Missing /*
			*/Hidesmall /*
			*/PSeudo /*
			*/SMall(integer 5) /*
			*/STyle(string) /*
			*/Replace /*
			*/noPvalue /*
			*/noTotal /*
			*/Exact(integer 0) /*
			*/CAtegoricalreport(string) /*
			*/noTOPcount /*
		*/]
        
    local fn `using'
        
	local QUIETLY "quietly"
	if `"`log'"' == "log" local QUIETLY ""
	if `"`title'"' != "" local caption `"`title'"'
	if ! (inlist(`"`continousreport'"', "", "sd", "ci", "pi") | inlist("`continousreport'", "iqr", "iqi", "idr", "idi", "mrr", "mri")) {
		display `"{error}The value of continousreport must be one of sd, iqr, iqi, ci, pi. Not "`continousreport'""'
		display "The value of continousreport is set to default, sd"
		local continousreport sd
	}
	if !inlist(`"`style'"', "", "smcl", "csv", "html", "latex", "tex", "md") {
		display `"{error}The value of style must be one of smcl, csv, html, latex or tex, or md. Not "`style'""'
		display "The value of style is set to the default: smcl"
		local style smcl
	}
	mata: __hide = (`"`hidesmall'"' == "hidesmall" ? strtoreal(`"`small'"') : 0)
	mata: __smooth_width = (`"`pseudo'"' == "pseudo" ? strtoreal(`"`small'"') : 0)
	mata: st_local("nformat", `"`nthousands'"' != "" ? "%200.0fc" : "%200.0f")
	mata: st_local("pctformat", st_isnumfmt(`"`pctformat'"') ? `"`pctformat'"' : "%6.1f")
	
	mata: __pvformat = `"`pvformat'"'
	mata: __pv_to_top = regexm(__pvformat, "^(.*), *to?p?$")
	mata: __pvformat = __pv_to_top ? regexs(1) : __pvformat
	mata: st_local(`"pvformat"', st_isnumfmt(__pvformat) ? __pvformat : "%6.2f")

	`QUIETLY' mata: tbl = basetable_parser(`"`input_list'"', `"`nformat'"', `"`pctformat'"', ///
		`"`pvformat'"', __pv_to_top, `"`continuousreport'"', __hide, __smooth_width, ///
		`"`missing'"' == "missing", `"`if'"', `"`in'"', `exact', ///
		`"`categoricalreport'"', `"`topcount'"' == "")

    mata: tbl.log_print(`"`style'"', `"`fn'"', `"`replace'"' != "", ///
						`"`caption'"', `"`top'"', `"`undertop'"', `"`bottom'"', ///
						`"`pvalue'"' != "", `"`total'"' != "")

    if "`toxl'" != "" { 
        if `c(stata_version)' >= 13 {
            if `c(stata_version)' >= 14 mata: __xlz = xlsetup14()
            else mata: __xlz = xlsetup13()

            `QUIETLY' mata: __xlz.thisversion
            
            mata: __xlz.stringset(`"`toxl'"')
            `QUIETLY' mata: __xlz.xlfile()
            `QUIETLY' mata: __xlz.sheet()
            `QUIETLY' mata: __xlz.start()
            `QUIETLY' mata: __xlz.replacesheet()
            if `c(stata_version)' >= 14 {
            	mata: __2xl_cw = __xlz.columnwidths()
                mata: __2xl_cw = __2xl_cw[1] != . ? __2xl_cw : (70, 20)
                mata: __xlz.columnwidths(__2xl_cw)
                `QUIETLY' mata: __xlz.columnwidths()            	
            }

            mata: __str_regex = ""
            if `"`total'"' != "" mata: __str_regex = "^Total$"
			if  `"`pvalue'"' != "" mata: __str_regex = "^P-value$"
			if `"`total'"' != "" & `"`pvalue'"' != "" mata: __str_regex = "^Total$|^P-value$"
            mata: __slct_columns = tbl.regex_select_columns(__str_regex)
            mata: __output = tbl.output[., __slct_columns]

            mata: __xlz.insert_matrix(__output)
            if `c(stata_version)' >= 14 {
                mata: __xlz.set_alignments("left", (0, 0), (rows(__output)-1, 0), 1)
                mata: __xlz.set_alignments("left", (0, 0), (0, cols(__output)-1), 1)
                mata: __xlz.set_alignments("right", (1, 1), (rows(__output)-1, cols(__output)-1), 1)
            }
            if inlist(`"`style'"', "", "smcl") ///
                mata printf(`"Table saved in "%s", in sheet "%s"... \n"', __xlz.xlfile(), __xlz.sheet())

        }
		else {
			display "{error:Option toxl do not work in version 12 for Stata.}" 
			display "Use csv output file at the {help using:using} modifier and option style(csv) instead"
		}
    }
    mata mata drop __* __*()
end

if `c(stata_version)' >= 13 {
    mata st_local( "__fn", findfile("ltoxl_v13.mata"))
    include "`__fn'"
}
if `c(stata_version)' >= 14 {
    mata st_local( "__fn", findfile("ltoxl_v14.mata"))
    include "`__fn'"
}
