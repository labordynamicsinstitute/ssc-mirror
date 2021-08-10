*! version 0.1.8 2017-03-12 > Code partly based on lmatrixtools
*! version 0.1.8 2017-03-12 > Binomial CI added
* version 0.1.5 2016-02-24 > Most Mata code back in mlib
version 12

mata:
	string scalar missings(	string scalar varname,
							|string scalar str_if, 
							string scalar str_in) 
	{
		real colvector counts
	
		counts = nhb_sae_summary_row(varname, "N missing", "", str_if, 
											str_in, 95, 0, 0, 0, 0, 1)
		return(sprintf("%1.0f / %1.0f (%4.2f)", counts[2], 
						counts[1] + counts[2], 
						counts[2] / (counts[1] + counts[2]) * 100))
	}

	function summarize_by(	string scalar variable, 
							string scalar groupby, 
							string scalar statistics,
							| string scalar str_if, 
							string scalar str_in
							)
	{
		string scalar txt_if, lbl_name
		string vector lbls
		real scalar C, R, c
		real matrix out

		txt_if = (str_if != "" ? sprintf("%s & !missing(%s)", str_if, groupby) 
								: sprintf("if !missing(%s)", groupby))
		lbl_name = st_varvaluelabel(groupby)
		lbls = nhb_sae_labelsof(groupby)
		C = cols(lbls)
		out = nhb_sae_summary_row(variable, statistics, "", txt_if, str_in, 
						95, 0, 0, 0, 0, 1)'
		for(c=C; c>=1; c--) {
			out = nhb_sae_summary_row(variable, statistics, "", 
						txt_if + sprintf(`" & %s == "%s":%s"', groupby, lbls[c], lbl_name), 
						str_in, 95, 0, 0, 0, 0, 1)', out
		}
		return(out)
	}

	
	class basetable {
		private string scalar colvar, nfmt, pctfmt, pvfmt 
		private real scalar valuewidth, no_small, missing
		private string matrix n_pct_by_base()
		
		string scalar str_if, str_in
		string matrix output
		void setup_tbl(), log_print(), header()
		void n_pct(), n_pct_by(), n_pct_by_value(), n_bin_by_value()
		void mean_sd(), median_iqr(), median_iqi(), mean_ci(), mean_pi()
	}

		void basetable::setup_tbl(string scalar colvar, 
									string scalar nfmt, 
									string scalar pctfmt, 
									string scalar pvfmt,
									real scalar no_small, 
									real scalar missing,
									| string scalar str_if, 
									string scalar str_in
									)
		{
			this.colvar = colvar
			this.nfmt = nfmt
			this.pctfmt = pctfmt
			this.pvfmt = pvfmt
			this.output = "", nhb_sae_labelsof(colvar), "Total", "P-value"
			this.valuewidth = cols(this.output) - 2
			this.no_small = no_small 
			this.missing = missing
			this.output = (this.missing ? this.output, "Missings / N (Pct)" : this.output)
			this.str_if = str_if
			this.str_in = str_in
		}

		void basetable::log_print(	|string scalar style,
									string scalar filename,
									real scalar replace,
									string scalar caption,
									string vector top,
									string vector undertop,
									string vector bottom)
		{
			string colvector lines
		
			lines = nhb_mt_mata_string_matrix_styled(this.output, style, 
						("-", ""), 1, caption, top, undertop, bottom, 
						filename, replace)
		}

		void basetable::n_pct()
		{
			real scalar r, R, c, C
			string rowvector n, prp, row
			string colvector names
			class nhb_mt_chi2tabulate scalar tbl
			
			tbl.set(this.colvar, "", this.str_if, this.str_in)
			n = strofreal(tbl.counts_with_totals().values(), this.nfmt)'
			prp = strofreal(100 * tbl.proportions().values(), this.pctfmt)'
			C = cols(n)
			if ( C == this.valuewidth ) {
				row = ("n (%)", n + J(1, C, " (") + prp + J(1, C, ")"), "")
			} else {
				row = "n (%)", J(1, this.valuewidth, ". (.)"), ""
				names = tbl.counts().row_names(), "Total"
				for(r=2;r<=this.valuewidth+1;r++) {
					for(c=1;c<=C;c++) {
						if ( names[c] == this.output[1,r] ) {
							row[1,r] = sprintf("%s (%s)", n[c], prp[c])
						}
					}
				}
			}
			row = this.missing ? row, missings(this.colvar, 
					this.str_if, this.str_in) : row
			this.output	=  this.output \ row 
		}

		string matrix basetable::n_pct_by_base(	string scalar variable, 
												real scalar colpct)
		{
			real scalar r, c, R, C
			real matrix has_small
			rowvector n, prp, tmp_n, tmp_p
			string scalar errtxt
			string rowvector header
			string colvector names
			string matrix out
			class nhb_mt_chi2tabulate scalar tbl
		
			if ( (errtxt=nhb_sae_validate_variable(variable, 1)) != "" ) {
				this.header("n_pct_by_base: " + errtxt, "ERROR!!")
				out = J(0,0,"")
			} else {
				tbl.set(variable, this.colvar, this.str_if, this.str_in)
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
					names = tbl.counts().column_names(), "Total"
					n = prp = J(R, this.valuewidth, .)
					for (c=1;c<=cols(names);c++) {
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
				names = "  " :+ tbl.counts().row_names() :+ ", n (%)"
				out = (names, n + J(R, C, " (") + prp + J(R, C, ")"), J(R, 1, ""))
				C = cols(out)
				out[R,C] = strofreal(tbl.tests().values()[1,3], this.pvfmt)
				header = J(1, C, "")
				header[1] = sprintf("%s, n (%%)", st_varlabel(variable))
				out = header \ out
				if ( this.missing ) {
					out = out, (J(R, 1, "") \ missings(variable, this.str_if, this.str_in))
				}
			}
			return(out)
		}

		void basetable::n_pct_by(	string scalar variable, 
											real scalar colpct)
		{
			string matrix n_pct
			
			n_pct = this.n_pct_by_base(variable, colpct)
			if ( n_pct != J(0,0,"") ) this.output = this.output \ n_pct
		}
		
		void basetable::n_pct_by_value(	string scalar variable, 
										string scalar rowvalue, 
										real scalar colpct)
		{
			real scalar R, C
			string matrix n_pct
			real colvector slct
			
			n_pct = this.n_pct_by_base(variable, colpct)
			if ( n_pct != J(0,0,"") ) {
				R = rows(n_pct)
				C = cols(n_pct)
				slct = regexm(n_pct[.,1], rowvalue)
				if ( colsum(slct) ) {
					n_pct = select(n_pct[., 1..(C-1)], slct), n_pct[R, C]
				} else {
					n_pct = "", J(1, C-2, "0 (.)"), "."
				}
				n_pct[1] = sprintf("%s (%s), n (%%)", st_varlabel(variable), rowvalue)
				this.output = this.output \ n_pct
			}
		}
		
		void basetable::n_bin_by_value(string scalar variable, rowvalue)
		{
			real matrix values
			real scalar rc, c, C
			real colvector slct, z
			string scalar tmpvar
			string rowvector str_row
			string matrix sv, test
			
			if ( (errtxt=nhb_sae_validate_variable(variable, 1)) != "" ) {
				this.header("n_bin_by_value: " + errtxt, "ERROR!!")
			} else {
				tmpvar = st_tempname()
				rc = nhb_sae_logstatacode(sprintf(`"generate %s = (%s == "%s":%s) if !missing(%s, %s)"', 
					tmpvar, variable, rowvalue, st_varvaluelabel(variable), 
					variable, this.colvar), 1, 0)
				values = summarize_by(tmpvar, this.colvar, "sum N mean")
				values = values \ sqrt(values[3,.] :* (1 :- values[3,.]) :/ values[2,.]) // Add SE in row 4
				z = invnormal(0.025) \ invnormal(0.975)
				values = values \ values[3,.] :+ z # values[4,.] // Add CI
				values[3..6, .] = 100 * values[3..6, .]
				sv = strofreal(values[1..2, .], "%6.0f") \ strofreal(values[3..6, .], this.pctfmt)
				C = cols(values)
				str_row = sprintf("%s (%s), %% (95%% ci)", st_varlabel(variable), rowvalue), J(1, C, "")
				for(c = 1;c <= C; c++) {
					str_row[1, c+1] = sprintf("%s (%s; %s)", sv[3,c], sv[5,c], sv[6,c])
				}
				test = this.n_pct_by_base(variable, 1)
				str_row = str_row, test[rows(test), cols(test)]
				str_row = this.missing ? str_row, missings(variable, this.str_if, this.str_in) : str_row
				this.output = this.output \ str_row
			}
		}

		void basetable::mean_sd(string scalar variable, fmt)
		{
			real scalar C, rc, df_m, df_r, F
			real matrix data
			string rowvector rows
			string scalar label, p_value
			
			if ( (errtxt=nhb_sae_validate_variable(variable, 0)) != "" ) {
				this.header("mean_sd: " + errtxt, "ERROR!!")
			} else {
				data = summarize_by(variable, this.colvar, "mean sd",
									this.str_if, this.str_in)
				C = cols(data)
				label = sprintf("%s, mean (sd)", st_varlabel(variable))
				p_value = ""
				rc = nhb_sae_logstatacode(sprintf("oneway %s %s %s %s", variable, 
									this.colvar, this.str_if, this.str_in), 1, 0)
				if ( !rc ) {
					df_m = st_numscalar("r(df_m)")
					df_r = st_numscalar("r(df_r)")
					F = st_numscalar("r(F)")
					if ( F != . )  p_value = strofreal(Ftail(df_m, df_r, F), this.pvfmt)
					if ( p_value == strofreal(0, this.pvfmt) ) {
						p_value = "< " + substr(p_value, 1, strlen(p_value)-1) + "1"
					}
				}
				rows = (label, strofreal(data[1,.], fmt)
							+ J(1, C, " (")
							+ strofreal(data[2,.], fmt) 
							+ J(1, C, ")"), 
							p_value)
				rows = this.missing ? rows, missings(variable, this.str_if, this.str_in) : rows
				this.output = this.output \ rows
			}
		}

		void basetable::median_iqr(string scalar variable, fmt)
		{
			real scalar C, df, F
			real matrix data
			string rowvector rows
			string scalar statacode, label, p_value

			if ( (errtxt=nhb_sae_validate_variable(variable, 0)) != "" ) {
				this.header("median_iqr: " + errtxt, "ERROR!!")
			} else {
				data = summarize_by(variable, this.colvar, 
									"p50 p25 p75",
									this.str_if, this.str_in
									)
				data = data[1,.] \ (data[3,.] - data[2,.])
				C = cols(data)
				label = sprintf("%s, median (iqr)", st_varlabel(variable))
				p_value = ""
				statacode = sprintf("kwallis %s %s %s, by(%s)", variable, 
								this.str_if, this.str_in, this.colvar)
				if ( !nhb_sae_logstatacode(statacode, 1, 0) ) {
					df = st_numscalar("r(df)")
					F = st_numscalar("r(chi2)")
					p_value = strofreal(chi2tail(df, F), this.pvfmt)
					if ( p_value == strofreal(0, this.pvfmt) ) {
						p_value = "< " + substr(p_value, 1, strlen(p_value)-1) + "1"
					}
				}
				rows = (label, strofreal(data[1,.], fmt)
							+ J(1, C, " (")
							+ strofreal(data[2,.], fmt) 
							+ J(1, C, ")"), 
							p_value)
				rows = this.missing ? rows, missings(variable, this.str_if, this.str_in) : rows
				this.output = this.output \ rows
			}
		}

		void basetable::median_iqi(string scalar variable, fmt)
		{
			real scalar C, df, F
			real matrix data
			string rowvector rows
			string scalar statacode, label, p_value

			if ( (errtxt=nhb_sae_validate_variable(variable, 0)) != "" ) {
				this.header("median_iqi: " + errtxt, "ERROR!!")
			} else {
				data = summarize_by(variable, this.colvar, 
									"p50 p25 p75",
									this.str_if, this.str_in
									)
				C = cols(data)
				label = sprintf("%s, median (iqi)", st_varlabel(variable))
				p_value = ""
				statacode = sprintf("kwallis %s %s %s, by(%s)", variable, 
								this.str_if, this.str_in, this.colvar)
				if ( !nhb_sae_logstatacode(statacode, 1, 0) ) {
					df = st_numscalar("r(df)")
					F = st_numscalar("r(chi2)")
					p_value = strofreal(chi2tail(df, F), this.pvfmt)
					if ( p_value == strofreal(0, this.pvfmt) ) {
						p_value = "< " + substr(p_value, 1, strlen(p_value)-1) + "1"
					}
				}
				rows = (label, strofreal(data[1,.], fmt)
							+ J(1, C, " (")
							+ strofreal(data[2,.], fmt) 
							+ J(1, C, "; ")
							+ strofreal(data[3,.], fmt) 
							+ J(1, C, ")"), 
							p_value)
				rows = this.missing ? rows, missings(variable, this.str_if, this.str_in) : rows
				this.output = this.output \ rows
			}
		}

		void basetable::mean_ci(string scalar variable, fmt)
		{
			real scalar C, rc, df_m, df_r, F, z
			real matrix data
			string rowvector rows
			string scalar label, p_value

			if ( (errtxt=nhb_sae_validate_variable(variable, 0)) != "" ) {
				this.header("mean_ci: " + errtxt, "ERROR!!")
			} else {
				data = summarize_by(variable, this.colvar, 
									"mean sd N",
									this.str_if, this.str_in
									)
				data = data[1,.] \ (data[2,.] :/ sqrt(data[3,.]))
				C = cols(data)
				label = sprintf("%s, mean (95%% ci)", st_varlabel(variable))
				p_value = ""
				rc = nhb_sae_logstatacode(sprintf("oneway %s %s %s %s", variable, 
									this.colvar, this.str_if, this.str_in), 1, 0)
				if ( !rc ) {
					df_m = st_numscalar("r(df_m)")
					df_r = st_numscalar("r(df_r)")
					F = st_numscalar("r(F)")
					if ( F != . )  p_value = strofreal(Ftail(df_m, df_r, F), this.pvfmt)
					if ( p_value == strofreal(0, this.pvfmt) ) {
						p_value = "< " + substr(p_value, 1, strlen(p_value)-1) + "1"
					}
				}
				z = invnormal(0.975)
				rows = (label, strofreal(data[1,.], fmt)
							+ J(1, C, " (")
							+ strofreal(data[1,.] :- z :* data[2,.], fmt) 
							+ J(1, C, "; ")
							+ strofreal(data[1,.] :+ z :* data[2,.], fmt)
							+ J(1, C, ")"), 
							p_value)
				rows = this.missing ? rows, missings(variable, this.str_if, this.str_in) : rows
				this.output = this.output \ rows
			}
		}

		void basetable::mean_pi(string scalar variable, fmt)
		{
			real scalar C, rc, df_m, df_r, F, z
			real matrix data
			string rowvector rows
			string scalar label, p_value

			if ( (errtxt=nhb_sae_validate_variable(variable, 0)) != "" ) {
				this.header("mean_pi: " + errtxt, "ERROR!!")
			} else {
				data = summarize_by(variable, this.colvar, "mean sd",
									this.str_if, this.str_in
									)
				C = cols(data)
				label = sprintf("%s, mean (95%% pi)", st_varlabel(variable))
				p_value = ""
				rc = nhb_sae_logstatacode(sprintf("oneway %s %s %s %s", variable, 
									this.colvar, this.str_if, this.str_in), 1, 0)
				if ( !rc ) {
					df_m = st_numscalar("r(df_m)")
					df_r = st_numscalar("r(df_r)")
					F = st_numscalar("r(F)")
					if ( F != . )  p_value = strofreal(Ftail(df_m, df_r, F), this.pvfmt)
					if ( p_value == strofreal(0, this.pvfmt) ) {
						p_value = "< " + substr(p_value, 1, strlen(p_value)-1) + "1"
					}
				}
				z = invnormal(0.975)
				rows = (label, strofreal(data[1,.], fmt)
							+ J(1, C, " (")
							+ strofreal(data[1,.] :- z :* data[2,.], fmt) 
							+ J(1, C, "; ")
							+ strofreal(data[1,.] :+ z :* data[2,.], fmt)
							+ J(1, C, ")"), 
							p_value)
				rows = this.missing ? rows, missings(variable, this.str_if, this.str_in) : rows
				this.output = this.output \ rows
			}
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

	
	class basetable scalar basetable_parser(	string scalar txt, 
												string scalar nfmt, 
												string scalar pctfmt, 
												string scalar pvfmt, 
												string scalar continousreport, 
												real scalar no_small, 
												real scalar missing,
												string scalar str_if, 
												string scalar str_in
												)
	{
		class basetable scalar tbl
		transmorphic t
		real scalar r, n_pct
		string scalar e_txt
		string rowvector lst, arguments
		

		t = tokeninit(" ", "", (`"()"', `"[]"'))
		tokenset(t, txt)
		lst = tokengetall(t)
		if ( regexm(lst[1], "^\[|^\(") ) _error("Arguments must not start with a [ or a (")
		if ( (e_txt=nhb_sae_validate_variable(lst[1], 1)) != "" ) _error("First argument: " + e_txt)
		
		tbl.setup_tbl(lst[1], nfmt, pctfmt, pvfmt, no_small, missing, str_if, str_in)
		tbl.n_pct()

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
				if ( regexm(arguments[2], "^ *(.*) *(if *.+) *$") ) {
					tbl.str_if = stritrim(regexs(2))
					tbl.header(arguments[1], stritrim(regexs(1)))
				} else if ( regexm(arguments[2], "^ *(.*) *$") ) {
					tbl.header(arguments[1], stritrim(regexs(1)))
					tbl.str_if = str_if
				} else {
					tbl.header(arguments[1], "")
				}
				if ( n_pct ) tbl.n_pct()
			} else {										// variable
				if ( (e_txt=nhb_sae_validate_variable(lst[r], 0)) != "" ) {
					tbl.header(e_txt, "ERROR!!")
					continue
				}
				if ( !regexm(lst[r+1], "^\((.*)\)") ) {
					tbl.header(sprintf("Arguments in braces () must follow variable %s", lst[r]), "ERROR!!")
					continue
				}
				arguments = strtrim(tokensplit(regexs(1), ","))
				if ( st_isnumfmt(arguments[1]) == 1 ) {		// continous variable
					continousreport = (continousreport == "" ? "sd" : continousreport)
					arguments = length(arguments) == 1 ? arguments, continousreport : arguments
					if ( arguments[2] == "sd" ) {
						tbl.mean_sd(lst[r], arguments[1])
					} else if ( regexm(arguments[2],"^iqr$") ) {
						tbl.median_iqr(lst[r], arguments[1])
					} else if ( regexm(arguments[2],"^iqi$") ) {
						tbl.median_iqi(lst[r], arguments[1])
					} else if ( regexm(arguments[2],"^ci$") ) {
						tbl.mean_ci(lst[r], arguments[1])
					} else if ( regexm(arguments[2],"^pi$") ) {
						tbl.mean_pi(lst[r], arguments[1])
					}					
				} else {									// categorical variable
					if ( (e_txt=nhb_sae_validate_variable(lst[r], 1)) != "" ) {
						tbl.header(e_txt, "ERROR!!")
						continue
					}
					if ( regexm(strlower(arguments[1]), "^[0r1c]$|^ci$") ) {
						// 0 = row pct, 1 = column pct
						tbl.n_pct_by(lst[r], regexm(arguments[1], "^[1cC]$"))
					} else {
						arguments = length(arguments) == 1 ? arguments, "c" : arguments
						if ( regexm(strlower(arguments[2]), "^ci$") ) { 
							tbl.n_bin_by_value(lst[r], arguments[1])
						} else {
							tbl.n_pct_by_value(lst[r], arguments[1], regexm(arguments[2], "[1cC]$"))
						}
					}
				}
				r++
			}
		}
		return(tbl)
	}	
end
