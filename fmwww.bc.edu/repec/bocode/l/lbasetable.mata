*!version 0.2.9  2024-02-25 > Option todocx added
*!version 0.2.9  2023-08-02 > Option for column order is added
*!version 0.2.9  2023-04-26 > cleanup in mata must be specific in "mata mata drop __* __*()". A capture is added preliminary
* version 0.2.8  2022-04-20 > Option noTOPcount now only for first row
* version 0.2.6  2021-05-24 > Bug in basetable_parser(): basetable::n_pct_by_value() not called when value ends on r. Thanks to Kasper Norman
* version 0.2.6  2021-04-15 > NoTotal and NoPvalue now also for toxl
* version 0.2.4 2020-10-08 > Bug in basetable::n_pct_by_value() fixed
* version 0.2.4 2020-10-07 > Fisher's exact test as option
* version 0.2.3 2019-09-13 > 95% ci for geometric mean is added (gci)
* version 0.2.3 2019-06-11 > median/deciles as range and interval added
* version 0.2.3 2019-03-07 > median/r* version 0.2.3 2019-09-13 > ange as range and interval added
* version 0.2.1	2018-12-21 > BUG: Placing pvalue on top not working together with missing
* version 0.2.1	2018-10-04 > Option for smoothing data when returning median and quartiles
* version 0.2.1	2018-10-04 > function summarize_by() is now a private method in class basetable
* version 0.2.1	2018-09-18 > Option for drop p-value in print
* version 0.2.1	2018-09-18 > Option for drop total in print
* version 0.2.1 2018-09-17 > Hidesmall for for missings
* version 0.2.0 2018-01-24 > Removed "<" in front of almost p values
* version 0.2.0 2017-12-05 > Do not perform kwallis when colvar is single valued
* version 0.2.0 2017-03-12 > Bug calculating slct in basetable::n_pct_by_value() fixed
* version 0.1.8 2017-03-12 > Code partly based on lmatrixtools
* version 0.1.8 2017-03-12 > Binomial CI added
* version 0.1.5 2016-02-24 > Most Mata code back in mlib
version 12

mata:
	class basetable {
		private: 
			string scalar colvar, nfmt, pctfmt, pvfmt, categorical_report 
			real scalar valuewidth, pv_on_top, no_small, missing, smooth_width, exact
			string matrix n_pct_by_base()
			real matrix summarize_by()
			string scalar missings()
		public:
			string scalar str_if_base, str_if, str_in
			string matrix output
			void setup_tbl(), log_print(), header()
			void n_pct(), n_pct_by(), n_pct_by_value(), n_bin_by_value()
			void mean_sd(), mean_ci(), gmean_ci(), mean_pi()
			void median_iqr(), median_iqi(), median_idr(), median_idi()
			void median_mrr(), median_mri()
			real rowvector regex_select_columns()
	}

		string scalar basetable::missings(string scalar varname) 
		{
			real colvector counts
			string scalar txt
			class nhb_mt_labelmatrix scalar lm
		
			lm = nhb_sae_summary_row(varname, "N missing", "", this.str_if, 
												this.str_in, 95, 0, 0, 0, 0, 0, 1)
			counts = lm.values()
			if ( counts[1] < this.no_small & counts[1]  > 0 ) {
				/*
                txt = sprintf(". / %1.0f (.)", counts[1] + counts[2]) 
                */
                txt = sprintf(". / %s (.)", strofreal(counts[1] + counts[2], this.nfmt)) 
			} else {
                /*
				txt = sprintf("%1.0f / %1.0f (%4.2f)", counts[2], 
							counts[1] + counts[2], 
							counts[2] / (counts[1] + counts[2]) * 100)
                */
				txt = sprintf("%s / %s (%s)", 
                            strofreal(counts[2], this.nfmt), 
							strofreal(counts[1] + counts[2], this.nfmt), 
							strofreal(counts[2] / (counts[1] + counts[2]) * 100, this.pctfmt))
			}
			return(txt)
		}

		real rowvector basetable::regex_select_columns(	string scalar str_regex, 
														| real scalar drop
														) 
		{
			real colvector col_idx, slct
			
			col_idx = 1::cols(this.output)
			slct = regexm(this.output[1,.]', str_regex)
			if ( str_regex == "" ) slct = !slct
			return( drop ? select(col_idx, !slct)' : select(col_idx, slct)' )
		}

		void basetable::setup_tbl(	string scalar colvar, 
									string scalar nfmt, 
									string scalar pctfmt, 
									string scalar pvfmt,
									real scalar pv_on_top,
									real scalar no_small, 
									real scalar smooth_width, 
									real scalar missing,
									| string scalar str_if, 
									string scalar str_in,
                  real scalar exact,
									string scalar categorical_report
									)
		{
			string scalar col_by
		
			this.colvar = colvar
			this.nfmt = nfmt
			this.pctfmt = pctfmt
			this.pvfmt = pvfmt
			this.pv_on_top = pv_on_top
			col_by = st_varlabel(this.colvar)
			if ( col_by == "" ) col_by = this.colvar
			if ( col_by != "  " ) col_by = sprintf("Columns by: %s", col_by)
      else col_by = "Variables"
			this.output = col_by, nhb_sae_labelsof(colvar), "Total", "P-value"
			this.valuewidth = cols(this.output) - 2
			this.no_small = no_small
			this.smooth_width = smooth_width
			this.missing = missing
			this.output = (this.missing ? this.output, "Missings / N (Pct)" : this.output)
			this.str_if_base = str_if
			this.str_if = str_if
			this.str_in = str_in
      this.exact = exact < . ? exact : 0
			this.categorical_report = rowsum(categorical_report :== ("n", "p")) ? categorical_report : ""
		}

		void basetable::log_print(	|string scalar style,
									string scalar filename,
									real scalar replace,
									string scalar caption,
									string vector top,
									string vector undertop,
									string vector bottom,
									real scalar show_pv,
									real scalar show_total,
									real rowvector order)
		{
			real rowvector slct_columns
			real colvector slct
			string scalar str_regex
			string colvector lines
			string matrix to_print
			
			if ( show_total ) str_regex = "^Total$"
			if ( show_pv ) str_regex = "^P-value$"
			if ( show_total & show_pv ) str_regex = "^Total$|^P-value$"
			
			slct_columns = this.regex_select_columns(str_regex)
			to_print = this.output[.,slct_columns]
			slct = select(1::rows(to_print), strmatch(to_print[.,1], "  *"))
			if (style == "md" & slct != J(0, 1, .) ) {
				to_print[slct,1] = "*" :+ substr(to_print[slct,1],3,.) :+ "*"
			}
			if ( order == J(0, 1, .) ) order = .
			lines = nhb_mt_mata_string_matrix_styled(to_print[., order], 
				style, ("-", ""), 1, caption, top, undertop, bottom, filename, replace)
		}

		void basetable::n_pct()
		{
			real scalar r, c, C
			real rowvector n, prp, n_tmp, prp_tmp
			string rowvector row
			string colvector names
			class nhb_mt_chi2tabulate scalar tbl
			
			tbl.set(this.colvar, "", this.str_if, this.str_in)
			n = tbl.counts_with_totals().values()'
			prp = 100 * tbl.proportions().values()'
			C = cols(n)
			if ( C != this.valuewidth ) {
				n_tmp = n
				prp_tmp = prp
				n = prp = J(1, this.valuewidth, 0)
				names = tbl.counts().row_names() \ "Total"
				for(r=1;r<=this.valuewidth;r++) {
					for(c=1;c<=C;c++) {
						if ( names[c] == this.output[1,r+1] ) {
							n[r] = n_tmp[c]
							prp[r] = prp_tmp[c]
						}
					}
				}
				C = this.valuewidth
			}
			if ( this.categorical_report == "p" ) {
				row = ("%", strofreal(prp, this.pctfmt), "")
			} else if ( this.categorical_report == "n" ) {
				row = ("n", strofreal(n, this.nfmt), "")
			} else {
				row = ("n (%)", strofreal(n, this.nfmt) + J(1, C, " (") 
						+ strofreal(prp, this.pctfmt) + J(1, C, ")"), "")
			}
			row = this.missing ? row, this.missings(this.colvar) : row
      this.output =  this.output \ row
		}

		string matrix basetable::n_pct_by_base( string scalar varname, 
												real scalar colpct)
		{
			real scalar r, c, R, C, p_index
			real matrix has_small
			rowvector n, prp, tmp_n, tmp_p
			string scalar vnm, headertitle
			string rowvector header
			string colvector names
			string matrix out
			class nhb_mt_chi2tabulate scalar tbl

            tbl.set(varname, this.colvar, this.str_if, this.str_in, "", this.exact)
            n = tbl.counts_with_totals().values()
            R = rows(n) - 1	//Ignore bottom total
            n = n[1..R,.]
            C = cols(n)
            if ( colpct ) {
                prp = 100 * tbl.column_proportions().values()[1..R,.]
            } else {
                prp = 100 * tbl.row_proportions().values()[1..R,.]
            }
            if ( C != this.valuewidth ) {
                tmp_n = n
                tmp_p = prp
                names = tbl.counts().column_names() \ "Total"
                n = prp = J(R, this.valuewidth, 0)
                for (c=1;c<=rows(names);c++) {
                    for(r=1;r<=cols(n);r++) {
                        if ( names[c] == this.output[1,r+1] ) {
                            n[.,r] = tmp_n[.,c]
                            prp[.,r] = tmp_p[.,c]
                        }
                    }
                }
                C = this.valuewidth
            }
            if ( this.no_small ) {
                n = n[.,1..C-1]
                has_small = n :> 0 :& n :< this.no_small
                n = n :* !has_small + this.no_small :* has_small
                n = n, rowsum(n)
                has_small = has_small, rowsum(has_small) :> 0
            } else {
                has_small = J(R, this.valuewidth, 0)
            }
            n = ("" :* !has_small + "< " :* has_small) :+ strofreal(n, this.nfmt)
            prp = prp :/ !has_small
            prp = strofreal(prp, this.pctfmt)
            if ( this.categorical_report == "p" ) {
                names = "  " :+ tbl.counts().row_names()
                headertitle = ", %"
                out = (names, prp, J(R, 1, ""))
            } else if ( this.categorical_report == "n" ) {
                names = "  " :+ tbl.counts().row_names()
                headertitle = ", n"
                out = (names, n, J(R, 1, ""))
            } else {
                names = "  " :+ tbl.counts().row_names()
                headertitle = ", n (%)"
                out = (names, n + J(R, C, " (") + prp + J(R, C, ")"), J(R, 1, ""))
            }
            C = cols(out)
            p_index = this.exact ? 3 : 1
            out[R,C] = strofreal(tbl.tests().values()[p_index,3], this.pvfmt)
            header = J(1, C, "")
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
            header[1] = sprintf("%s%s", vnm, headertitle)
            out = header \ out
            if ( this.missing ) {
                out = out, (J(R, 1, "") \ this.missings(varname))
            }
			return(out)
		}
		
	real matrix basetable::summarize_by(	string scalar variable, 
											string scalar statistics
											)
	{
		string scalar txt_if, lbl_name, strslct
		string vector lbls
		real scalar C, c
		real matrix out
		class nhb_mt_labelmatrix scalar lm

		txt_if = (str_if != "" ? sprintf("%s & !missing(%s)", str_if, this.colvar) 
								: sprintf("if !missing(%s)", this.colvar))
		lbl_name = st_varvaluelabel(this.colvar)
        if ( lbl_name != "" ) {
        	lbl_name = sprintf(`"":%s"', lbl_name)
            strslct = `" & %s == "%s%s"'
        } else strslct = `" & %s == %s%s"'
		lbls = nhb_sae_labelsof(this.colvar)
		C = cols(lbls)
		lm = nhb_sae_summary_row(variable, statistics, "", txt_if, this.str_in, 
						95, 0, this.smooth_width, 0, 0, 0, 1)
		out = lm.values()'
		for(c=C; c>=1; c--) {
			lm = nhb_sae_summary_row(variable, statistics, "", 
						txt_if + sprintf(strslct, this.colvar, lbls[c], lbl_name), 
						str_in, 95, 0, this.smooth_width, 0, 0, 0, 1)
			out = lm.values()', out
		}
		return(out)
	}
		
		void basetable::n_pct_by(	string scalar variable, 
									real scalar colpct)
		{
			real scalar R, C
			string matrix n_pct
			
			n_pct = this.n_pct_by_base(variable, colpct)
			if ( this.pv_on_top ) {
				R = rows(n_pct)
				C = (cols(n_pct)-this.missing)..cols(n_pct)				
				n_pct[1,C] = n_pct[R,C]
				n_pct[R,C] = J(1, 1 + this.missing, "")
			}
			if ( n_pct != J(0,0,"") ) this.output = this.output \ n_pct
		}
		
		void basetable::n_pct_by_value(	string scalar varname, 
										string scalar rowvalue, 
										real scalar colpct)
		{
			real scalar R, C
			string scalar vnm, headertitle
			string matrix n_pct, n_pct_row
			real colvector slct
			
			n_pct = this.n_pct_by_base(varname, colpct)
			if ( n_pct != J(0,0,"") ) {
				R = rows(n_pct)
				C = cols(n_pct)
				slct = regexm(n_pct[.,1], sprintf("^  %s", rowvalue))
				if ( colsum(slct) ) {
					n_pct_row = select(n_pct, slct)
					n_pct_row[(C - this.missing)..C] = n_pct[R, (C - this.missing)..C]
				} else {
					n_pct_row = "", J(1, C-2, "0 (.)"), "."
				}
				if ( this.categorical_report == "p" ) headertitle = ", %"
				else if ( this.categorical_report == "n" ) headertitle = ", n"
				else headertitle = ", n (%)"
                vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
				n_pct_row[1] = sprintf("%s (%s)%s", vnm, rowvalue, headertitle)
				this.output = this.output \ n_pct_row
			}
		}

		void basetable::n_bin_by_value(
			string scalar varname, 
			string scalar rowvalue,
			|real scalar colpct)
		{
			real scalar ppct, z, R, C
            string scalar vnm, header
			real colvector slct
			real matrix n, p, sd
			string scalar test
			string matrix str_mat
			class nhb_mt_chi2tabulate scalar chi2tbl
		
			ppct = 95
			z = invnormal((100 + ppct) / 200)
			chi2tbl.set(varname, this.colvar, this.str_if, this.str_in)
			n = chi2tbl.counts_with_totals().values()
			C = cols(n)
			R = rows(n)
			slct = regexm(chi2tbl.counts_with_totals().row_names()[1..(R-1),.], rowvalue)
			if ( colpct ) {
				p = chi2tbl.column_proportions().values()[1..(R-1),.]
				sd = sqrt(p :* (1:-p) :/ n[R,.])
			} else {
				p = chi2tbl.row_proportions().values()[1..(R-1),.]
				sd = sqrt(p :* (1:-p) :/ n[1..(R-1),C])
			}
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
			header = vnm :+ " (" :+ chi2tbl.counts_with_totals().row_names()[1..(R-1),.] :+ "), % (95% CI)"
			str_mat = header, (strofreal(100 * p, this.pctfmt) 
				:+ " (" :+ strofreal(100 * (p :- z :* sd), this.pctfmt) 
				:+ "; " :+ strofreal(100 * (p :+ z :* sd), this.pctfmt) :+ ")")
			str_mat = select(str_mat, slct)
			test = this.n_pct_by_base(varname, 1)
			test = this.pv_on_top ? test[rows(test), cols(test)] \ J(rows(str_mat)-1,1,"") : J(rows(str_mat)-1,1,"") \ test[rows(test), cols(test)]
			str_mat = rowvalue != "" ? str_mat, test[rows(test), cols(test)] : str_mat, test
			str_mat = this.missing ? str_mat, this.missings(varname) : str_mat
			this.output = this.output \ str_mat
		}


		void basetable::mean_sd(string scalar varname, fmt)
		{
			real scalar C, rc, df_m, df_r, F
			real matrix data
			string rowvector rows
			string scalar label, p_value, vnm
			
            data = this.summarize_by(varname, "mean sd")
            C = cols(data)
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
            label = sprintf("%s, mean (sd)", vnm)
            p_value = ""
            rc = nhb_sae_logstatacode(sprintf("oneway %s %s %s %s", varname, 
                                this.colvar, this.str_if, this.str_in), 1, 0)
            if ( !rc ) {
                df_m = st_numscalar("r(df_m)")
                df_r = st_numscalar("r(df_r)")
                F = st_numscalar("r(F)")
                if ( F != . )  p_value = strofreal(Ftail(df_m, df_r, F), this.pvfmt)
            }
            rows = (label, strofreal(data[1,.], fmt)
                        + J(1, C, " (")
                        + strofreal(data[2,.], fmt) 
                        + J(1, C, ")"), 
                        p_value)
            rows = this.missing ? rows, this.missings(varname) : rows
            this.output = this.output \ rows
		}

		void basetable::median_iqr(string scalar varname, fmt)
		{
			real scalar C, df, F
			real matrix data
			string rowvector rows
			string scalar statacode, label, p_value, vnm

            data = this.summarize_by(varname, "p50 p25 p75")
            data = data[1,.] \ (data[3,.] - data[2,.])
            C = cols(data)
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
            label = sprintf("%s, median (iqr)", vnm)
            p_value = ""
            if ( this.valuewidth > 2 ) {
                statacode = sprintf("kwallis %s %s %s, by(%s)", varname, 
                                this.str_if, this.str_in, this.colvar)
                if ( !nhb_sae_logstatacode(statacode, 1, 0) ) {
                    df = st_numscalar("r(df)")
                    F = st_numscalar("r(chi2)")
                    p_value = strofreal(chi2tail(df, F), this.pvfmt)
                }
            }
            rows = (label, strofreal(data[1,.], fmt)
                        + J(1, C, " (")
                        + strofreal(data[2,.], fmt) 
                        + J(1, C, ")"), 
                        p_value)
            rows = this.missing ? rows, this.missings(varname) : rows
            this.output = this.output \ rows
		}

		void basetable::median_iqi(string scalar varname, fmt)
		{
			real scalar C, df, F
			real matrix data
			string rowvector rows
			string scalar statacode, label, p_value, vnm

            data = this.summarize_by(varname, "p50 p25 p75")
            C = cols(data)
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
            label = sprintf("%s, median (iqi)", vnm)
            p_value = ""
            this.valuewidth
            if ( this.valuewidth > 2 ) {
                statacode = sprintf("kwallis %s %s %s, by(%s)", varname, 
                                this.str_if, this.str_in, this.colvar)
                if ( !nhb_sae_logstatacode(statacode, 1, 0) ) {
                    df = st_numscalar("r(df)")
                    F = st_numscalar("r(chi2)")
                    p_value = strofreal(chi2tail(df, F), this.pvfmt)
                }
            }
            rows = (label, strofreal(data[1,.], fmt)
                        + J(1, C, " (")
                        + strofreal(data[2,.], fmt) 
                        + J(1, C, "; ")
                        + strofreal(data[3,.], fmt) 
                        + J(1, C, ")"), 
                        p_value)
            rows = this.missing ? rows, this.missings(varname) : rows
            this.output = this.output \ rows
		}

		void basetable::median_idr(string scalar varname, fmt)
		{
			real scalar C, df, F
			real matrix data
			string rowvector rows
			string scalar statacode, label, p_value, vnm

            data = this.summarize_by(varname, "p50 p10 p90")
            data = data[1,.] \ (data[3,.] - data[2,.])
            C = cols(data)
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
            label = sprintf("%s, median (idr)", vnm)
            p_value = ""
            if ( this.valuewidth > 2 ) {
                statacode = sprintf("kwallis %s %s %s, by(%s)", varname, 
                                this.str_if, this.str_in, this.colvar)
                if ( !nhb_sae_logstatacode(statacode, 1, 0) ) {
                    df = st_numscalar("r(df)")
                    F = st_numscalar("r(chi2)")
                    p_value = strofreal(chi2tail(df, F), this.pvfmt)
                }
            }
            rows = (label, strofreal(data[1,.], fmt)
                        + J(1, C, " (")
                        + strofreal(data[2,.], fmt) 
                        + J(1, C, ")"), 
                        p_value)
            rows = this.missing ? rows, this.missings(varname) : rows
            this.output = this.output \ rows
		}

		void basetable::median_idi(string scalar varname, fmt)
		{
			real scalar C, df, F
			real matrix data
			string rowvector rows
			string scalar statacode, label, p_value, vnm

            data = this.summarize_by(varname, "p50 p10 p90")
            C = cols(data)
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
            label = sprintf("%s, median (idi)", vnm)
            p_value = ""
            this.valuewidth
            if ( this.valuewidth > 2 ) {
                statacode = sprintf("kwallis %s %s %s, by(%s)", varname, 
                                this.str_if, this.str_in, this.colvar)
                if ( !nhb_sae_logstatacode(statacode, 1, 0) ) {
                    df = st_numscalar("r(df)")
                    F = st_numscalar("r(chi2)")
                    p_value = strofreal(chi2tail(df, F), this.pvfmt)
                }
            }
            rows = (label, strofreal(data[1,.], fmt)
                        + J(1, C, " (")
                        + strofreal(data[2,.], fmt) 
                        + J(1, C, "; ")
                        + strofreal(data[3,.], fmt) 
                        + J(1, C, ")"), 
                        p_value)
            rows = this.missing ? rows, this.missings(varname) : rows
            this.output = this.output \ rows
		}

		void basetable::median_mrr(string scalar varname, fmt)
		{
			real scalar C, df, F
			real matrix data
			string rowvector rows
			string scalar statacode, label, p_value, vnm

            data = this.summarize_by(varname, "median min max")
            data = data[1,.] \ (data[3,.] - data[2,.])
            C = cols(data)
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
            label = sprintf("%s, median (range)", vnm)
            p_value = ""
            if ( this.valuewidth > 2 ) {
                statacode = sprintf("kwallis %s %s %s, by(%s)", varname, 
                                this.str_if, this.str_in, this.colvar)
                if ( !nhb_sae_logstatacode(statacode, 1, 0) ) {
                    df = st_numscalar("r(df)")
                    F = st_numscalar("r(chi2)")
                    p_value = strofreal(chi2tail(df, F), this.pvfmt)
                }
            }
            rows = (label, strofreal(data[1,.], fmt)
                        + J(1, C, " (")
                        + strofreal(data[2,.], fmt) 
                        + J(1, C, ")"), 
                        p_value)
            rows = this.missing ? rows, this.missings(varname) : rows
            this.output = this.output \ rows
		}

		void basetable::median_mri(string scalar varname, fmt)
		{
			real scalar C, df, F
			real matrix data
			string rowvector rows
			string scalar statacode, label, p_value, vnm

            data = this.summarize_by(varname, "median min max")
            C = cols(data)
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
            label = sprintf("%s, median (min; max)", vnm)
            p_value = ""
            this.valuewidth
            if ( this.valuewidth > 2 ) {
                statacode = sprintf("kwallis %s %s %s, by(%s)", varname, 
                                this.str_if, this.str_in, this.colvar)
                if ( !nhb_sae_logstatacode(statacode, 1, 0) ) {
                    df = st_numscalar("r(df)")
                    F = st_numscalar("r(chi2)")
                    p_value = strofreal(chi2tail(df, F), this.pvfmt)
                }
            }
            rows = (label, strofreal(data[1,.], fmt)
                        + J(1, C, " (")
                        + strofreal(data[2,.], fmt) 
                        + J(1, C, "; ")
                        + strofreal(data[3,.], fmt) 
                        + J(1, C, ")"), 
                        p_value)
            rows = this.missing ? rows, this.missings(varname) : rows
            this.output = this.output \ rows
		}

		void basetable::mean_ci(string scalar varname, fmt)
		{
			real scalar C, rc, df_m, df_r, F, z
			real matrix data
			string rowvector rows
			string scalar label, p_value, vnm

            data = this.summarize_by(varname, "mean sd N")
            data = data[1,.] \ (data[2,.] :/ sqrt(data[3,.]))
            C = cols(data)
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
            label = sprintf("%s, mean (95%% ci)", vnm)
            p_value = ""
            rc = nhb_sae_logstatacode(sprintf("oneway %s %s %s %s", varname, 
                                this.colvar, this.str_if, this.str_in), 1, 0)
            if ( !rc ) {
                df_m = st_numscalar("r(df_m)")
                df_r = st_numscalar("r(df_r)")
                F = st_numscalar("r(F)")
                if ( F != . )  p_value = strofreal(Ftail(df_m, df_r, F), this.pvfmt)
            }
            z = invnormal(0.975)
            rows = (label, strofreal(data[1,.], fmt)
                        + J(1, C, " (")
                        + strofreal(data[1,.] :- z :* data[2,.], fmt) 
                        + J(1, C, "; ")
                        + strofreal(data[1,.] :+ z :* data[2,.], fmt)
                        + J(1, C, ")"), 
                        p_value)
            rows = this.missing ? rows, this.missings(varname) : rows
            this.output = this.output \ rows
		}

		void basetable::gmean_ci(string scalar varname, fmt)
		{
			real scalar C, rc, df_m, df_r, F, z
			real matrix data
			string rowvector rows
			string scalar label, p_value, log_var, vnm

            data = this.summarize_by(varname, "gmean gse")
            C = cols(data)
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
            label = sprintf("%s, geo. mean (95%% ci)", vnm)
            p_value = ""
            log_var = st_tempname()
            rc = nhb_sae_logstatacode(sprintf("generate %s = log(%s) %s %s", 
                log_var, varname, this.str_if, this.str_in), 1, 0)
            rc = nhb_sae_logstatacode(sprintf("oneway %s %s %s %s", log_var, 
                                this.colvar, this.str_if, this.str_in), 1, 0)
            if ( !rc ) {
                df_m = st_numscalar("r(df_m)")
                df_r = st_numscalar("r(df_r)")
                F = st_numscalar("r(F)")
                if ( F != . )  p_value = strofreal(Ftail(df_m, df_r, F), this.pvfmt)
            }
            z = invnormal(0.975)
            rows = (label, strofreal(data[1,.], fmt)
                        + J(1, C, " (")
                        + strofreal(exp(log(data[1,.]) :- z :* log(data[2,.])), fmt) 
                        + J(1, C, "; ")
                        + strofreal(exp(log(data[1,.]) :+ z :* log(data[2,.])), fmt) 
                        + J(1, C, ")"), 
                        p_value)
            rows = this.missing ? rows, this.missings(varname) : rows
            this.output = this.output \ rows
		}

		void basetable::mean_pi(string scalar varname, fmt)
		{
			real scalar C, rc, df_m, df_r, F, z
			real matrix data
			string rowvector rows
			string scalar label, p_value, vnm

            data = this.summarize_by(varname, "mean sd")
            C = cols(data)
            vnm = st_varlabel(varname) == "" ? varname : st_varlabel(varname)
            label = sprintf("%s, mean (95%% pi)", vnm)
            p_value = ""
            rc = nhb_sae_logstatacode(sprintf("oneway %s %s %s %s", varname, 
                                this.colvar, this.str_if, this.str_in), 1, 0)
            if ( !rc ) {
                df_m = st_numscalar("r(df_m)")
                df_r = st_numscalar("r(df_r)")
                F = st_numscalar("r(F)")
                if ( F != . )  p_value = strofreal(Ftail(df_m, df_r, F), this.pvfmt)
            }
            z = invnormal(0.975)
            rows = (label, strofreal(data[1,.], fmt)
                        + J(1, C, " (")
                        + strofreal(data[1,.] :- z :* data[2,.], fmt) 
                        + J(1, C, "; ")
                        + strofreal(data[1,.] :+ z :* data[2,.], fmt)
                        + J(1, C, ")"), 
                        p_value)
            rows = this.missing ? rows, this.missings(varname) : rows
            this.output = this.output \ rows
		}

		void basetable::header(string scalar headertext,| separator)
		{
			string rowvector row
			
			row = J(1, cols(this.output), (args() == 2 ? separator : "***"))
			row[1] = headertext
			this.output = this.output \ row
		}


	function tokensplit(string scalar txt, delimiter)
	{
		string vector  row
		string scalar filter
		row = J(1,0,"")
		filter = sprintf("(.*)%s(.*)", delimiter)
		while (regexm(txt, filter)) {
			txt = regexs(1)
			row = regexs(2), row
		}
		row = txt, row
		return(row)
	}

	
	class basetable scalar basetable_parser(	string scalar input_lst, 
												string scalar nfmt, 
												string scalar pctfmt, 
												string scalar pvfmt, 
												real scalar pv_on_top, 
												string scalar continousreport, 
												real scalar no_small, 
												real scalar smooth_width, 
												real scalar missing,
												string scalar str_if, 
												string scalar str_in,
                        real scalar exact,
												string scalar categorical_report,
												real scalar topcount
												)
	{
		class basetable scalar tbl
		transmorphic t
		real scalar r, v, n_pct
        string scalar ifin_var, strvarlst
		string rowvector varlst, lst, arguments
		
		t = tokeninit(" ", "", (`"()"', `"[]"'))
		tokenset(t, input_lst)
		lst = tokengetall(t)
		if ( regexm(lst[1], "^\[|^\(") ) _error("Arguments must not start with a [ or a (")
		
        if ( lst[1] == "_none" ) {
        	lst[1] = st_tempname()
        	stata(sprintf("generate %s = 1", lst[1]))
            st_varlabel(lst[1], "  ")
            st_vlmodify(lst[1], 1, "Summary")
            st_varvaluelabel(lst[1], lst[1])
            st_local("pvalue", "pvalue")
            st_local("total", "total")
        }
        
		if ( _st_varindex(lst[1]) >= . ) _error(sprintf(`"First part in arguments "%s" must be variable."', lst[1]))
    tbl.setup_tbl(lst[1], nfmt, pctfmt, pvfmt, pv_on_top, no_small, ///
      smooth_width, missing, str_if, str_in, exact, categorical_report)
		if ( topcount ) tbl.n_pct()
		for(r=2;r<=cols(lst);r++){
			if ( regexm(lst[r], "^\[(.*)\]") ) {			// header, handles local if
				arguments = strtrim(tokensplit(regexs(1), ","))
				arguments = length(arguments) == 1 ? arguments, "" : arguments
				if ( regexm(arguments[1], "(.*)# *$") ) {
					arguments[1] = regexs(1)
					n_pct = 1
				} else {
					n_pct = 0
				}
				if ( regexm(arguments[2], "^ *(.*) *if *(.+) *$") ) {
                    if ( tbl.str_if_base == "" ) {
                        tbl.str_if = "if " + stritrim(regexs(2))
                    } else {
                        tbl.str_if = tbl.str_if_base + " & " + stritrim(regexs(2))
                    }
					tbl.header(arguments[1], stritrim(regexs(1)))
				} else if ( regexm(arguments[2], "^ *(.*) *$") ) {
					tbl.header(arguments[1], stritrim(regexs(1)))
					tbl.str_if = tbl.str_if_base
				} else {
					tbl.header(arguments[1], "")
				}
                if ( !sum(st_data(., nhb_sae_markrows(tbl.str_if, tbl.str_in))) ) {
                    _error(sprintf(`"Nothing selected with if: "%s" and in: "%s""', tbl.str_if, tbl.str_in))
                }
				if ( n_pct ) tbl.n_pct()
			} else {										// variable
				if ( cols(lst) == r - 1 ) {
					_error(sprintf("Arguments in braces () must follow last variable '%s'", lst[r]))
				} else if ( !regexm(lst[r+1], "^\((.*)\)") ) {
					_error(sprintf("Arguments in braces () must follow variable '%s'", lst[r]))
				} else arguments = strtrim(tokensplit(regexs(1), ","))
                strvarlst = nhb_msa_unab(lst[r])
                if ( strvarlst == "" ) _error(sprintf("Arguments part '%s' is no varlist", lst[r]))
                varlst = tokens(strvarlst)
                for (v=1;v<=cols(varlst);v++) {
                    //if ( _st_varindex(varlst[v]) == . ) _error(sprintf("%s is no variable name", varlst[v]))
                	if ( regexm(varlst[v], "^__" ) ) continue   // Temporary variables ignored
                    if ( st_isnumfmt(arguments[1]) == 1 ) {		// continous variable
                        continousreport = (continousreport == "" ? "sd" : continousreport)
                        arguments = length(arguments) == 1 ? arguments, continousreport : arguments
                        if ( arguments[2] == "sd" ) {
                            tbl.mean_sd(varlst[v], arguments[1])
                        } else if ( regexm(arguments[2],"^iqr$") ) {
                            tbl.median_iqr(varlst[v], arguments[1])
                        } else if ( regexm(arguments[2],"^iqi$") ) {
                            tbl.median_iqi(varlst[v], arguments[1])
                        } else if ( regexm(arguments[2],"^idr$") ) {
                            tbl.median_idr(varlst[v], arguments[1])
                        } else if ( regexm(arguments[2],"^idi$") ) {
                            tbl.median_idi(varlst[v], arguments[1])
                        } else if ( regexm(arguments[2],"^imr$") ) {
                            tbl.median_mrr(varlst[v], arguments[1])
                        } else if ( regexm(arguments[2],"^imi$") ) {
                            tbl.median_mri(varlst[v], arguments[1])
                        } else if ( regexm(arguments[2],"^ci$") ) {
                            tbl.mean_ci(varlst[v], arguments[1])
                        } else if ( regexm(arguments[2],"^gci$") ) {
                            tbl.gmean_ci(varlst[v], arguments[1])
                        } else if ( regexm(arguments[2],"^pi$") ) {
                            tbl.mean_pi(varlst[v], arguments[1])
                        }					
                    } else {									// categorical variable
                        // input: r,c,ci/c or value+,+r,c,ci/c
                        if ( regexm(strlower(arguments[1]), "^ci|^[rc]$") ) {	// all row values
                            // 0 = row pct, 1 = column pct
                            if ( length(arguments) == 1 ) {
                                if ( regexm(strlower(arguments[1]), "^ci$") ) arguments = "c", arguments[1] 
                                else arguments = arguments, ""
                            }
                            if ( regexm(strlower(arguments[2]), "^ci$") ) {
                                // string scalar variable, string scalar rowvalue, |real scalar colpct
                                tbl.n_bin_by_value(varlst[v], "", regexm(arguments[1], "[cC]$"))
                            } else {
                                // string scalar variable, real scalar colpct
                                tbl.n_pct_by(varlst[v], regexm(arguments[1], "^[cC]$"))
                            }
                        } else {	// By row value
                            arguments = length(arguments) == 1 ? arguments, "c" : arguments
                            if ( regexm(strlower(arguments[2]), "^ci$") ) {
                            	/*r++*/
                                // string scalar variable, string scalar rowvalue, |real scalar colpct
                                tbl.n_bin_by_value(varlst[v], arguments[1], 1)	// Single value ci only by column
                            } else {
                                // string scalar variable, string scalar rowvalue, real scalar colpct
                                tbl.n_pct_by_value(varlst[v], arguments[1], regexm(arguments[2], "[cC]$"))
                            }
                        }
                    }
                }
                r++
			}
		}
		return(tbl)
	}	
end
