*! version 0.1.5 2016-02-24 > Most Mata code back in mlib


mata:
	function validate_variable(string scalar varname, real scalar is_categorical)
	{
		if ( _st_varindex(varname) == . ) {
			return(sprintf("Argument |%s| must be variable name", varname))
		}
		if ( !st_isnumvar(varname) ) {
			return(sprintf("Variable |%s| must be numerical", varname))
		}
		if ( st_varlabel(varname) == "" ) {
			return(sprintf("Variable |%s| must have a variable label", varname))
		}
		if ( is_categorical ) {
			if ( (lblname=st_varvaluelabel(varname)) == "") {
				return(sprintf("Variable |%s| must have a value label assigned!", varname))
			}
			if ( !st_vlexists(lblname) ) {
				return(sprintf("The assigned value label |%s| do not exist!", lblname))
			}
		}
		return("")
	}

	real rowvector label_values(string scalar variable, | str_if, str_in)
	{
		real rowvector levels
		string scalar error_txt, statacode
		real scalar rc
		
		if ( (error_txt=validate_variable(variable, 1)) != "" ) {
			_error(error_txt)
		}
		str_if = (args() > 1 ? str_if : "")
		str_in = (args() > 2 ? str_in : "")
		statacode = sprintf("levelsof %s %s %s, local(levels)", variable, 
								str_if, str_in)
		if ( !(rc=logstatacode(statacode)) ) {
			levels = strtoreal(tokens(st_global("_levels")))
			stata("macro drop _levels")
			return(levels)
		} else {
			_error(sprintf("Stata code |%s| failed with error %f", statacode, rc))
		}
	}

	string rowvector labelsof(string scalar variable, | real rowvector levels, 
						string scalar str_if, str_in)
	{
		string scalar error_txt
		
		if ( (error_txt=validate_variable(variable, 1)) != "" ) {
			_error(error_txt)
		}
		str_if = (args() > 2 ? str_if : "")
		str_in = (args() > 3 ? str_in : "")
		if ( levels == J(1, 0, .) ) {
			levels =label_values(variable, str_if, str_in)
		}
		return(st_vlmap(st_varvaluelabel(variable), levels))
	}
	
	real scalar logstatacode(string scalar statacode)
	{
		printf("{cmd:. %s}\n", statacode)
		return(_stata(statacode))
	}

	function justify_matrix(string matrix values, |real vector columnwidth, string scalar justify)
	{
		real scalar C, Cv, R, r, c
		string scalar strfmt
		string matrix justified
		
		if ( args() == 1 ) columnwidth = colmax(strlen(values))
		if ( !any(("", "~", "-") :== justify) ) {
			error(`"Argument justify must be one of "" (right), "~" (center), "-" (left)"')
		}
		if ( (Cv=cols(values)) > (C=cols(columnwidth)) ) {
			columnwidth = columnwidth, J(rows(columnwidth), Cv-C, columnwidth[., C])
		} else {
			columnwidth = columnwidth[., (1..Cv)] 
		}
		columnwidth = colmax((strlen(values) \ columnwidth))
		justified = J((R=rows(values)), Cv, "")
		for(c=1; c <= Cv; c++){
			strfmt = sprintf("%%%s%fs", justify, columnwidth[c])
			for(r=1; r <= R; r++){
				justified[r,c] = sprintf(strfmt, values[r,c])
			}
		}
		return(justified) 
	}

	function matrix_separate_vertically(string matrix values, string scalar first, |string scalar strseparator, string scalar last)
	{
		real scalar c
		string rowvector separated
		
		separated = values[., 1]
		for(c=2; c <= cols(values); c++) {
			separated = separated :+ strseparator :+ values[., c]
		}
 		return(first :+ separated :+ last)
	}
	
	function horizontal_line(real rowvector columnwidths, string scalar first
			, string scalar iterate, string scalar separate, string scalar last)
	{
		real scalar c, C
		string scalar line
		
		line = first
		for(c = 1; c <= (C=cols(columnwidths)); c++){
			line = line + columnwidths[c] * iterate
			if ( c < C ) line = line + separate
		}
		return(line + last)
	}
	
	function column_block(string matrix content, string matrix format)
	{
		string matrix out
		real colvector cw
	
		out = content
		cw = strlen(out[1,.])
		out = matrix_separate_vertically(out, format[3,2], format[3,3], format[3,4])
		out = horizontal_line(cw, format[1,1], format[1,2], format[1,3],format[1,4]) \ 
				out[1] \
				horizontal_line(cw, format[2,1], format[2,2], format[2,3],format[2,4]) \
				out[2..rows(out),.] \
				horizontal_line(cw, format[4,1], format[4,2], format[4,3],format[4,4])
		return(out)
	}
	
	function print_smcl(string matrix tbl, |real scalar nbr_totals)
	{
		real scalar C
		string colvector prnt
		
		nbr_totals = min((nbr_totals, (C=cols(tbl)) - 2))
		lines_left =	"{c TLC}", "{c -}", "{c TT}", "{c -}" \		// top line
						"{c LT}", "{c -}", "{c +}", "{c -}" \		// header line
						"", "{c |}", "{c |}", " " \ 				// the last 3 content lines
						"{c BLC}", "{c -}", "{c BT}", "{c -}"		// bottom line
		lines_middle =	"{c TT}", "{c -}", "{c -}", "{c -}" \		// top line
						"{c +}", "{c -}", "{c -}", "{c -}" \		// header line
						"", "{c |}", " ", " " \ 					// the last 3 content lines
						"{c BT}", "{c -}", "{c -}", "{c -}"			// bottom line
		lines_right =	"{c TT}", "{c -}", "{c TT}", "{c TRC}" \	// top line
						"{c +}", "{c -}", "{c +}", "{c |}" \		// header line
						"", "{c |}", "{c |}", "{c |}" \ 			// the last 3 content lines
						"{c BT}", "{c -}", "{c BT}", "{c BRC}"		// bottom line

		prnt = (column_block(" " :+ justify_matrix(tbl[., 1], 1,  "-"), lines_left) 
				+ column_block(" " :+ justify_matrix(tbl[., (2..C-nbr_totals)]), lines_middle)
				+ column_block(" " :+ justify_matrix(tbl[., (C-nbr_totals+1..C)]), lines_right)
				:+ "\n")
		return(prnt)
	}

	string scalar missings(string scalar varname,| string scalar str_if, str_in) 
	{
		transmorphic colvector test
		real scalar nbrmiss, N
		string scalar tmp
		
		str_if = (args() > 1 ? str_if : "")
		str_in = (args() > 2 ? str_in : "")
		stata(sprintf("mark %s %s %s", tmp=st_tempname(), str_if, str_in))
		if ( st_isnumvar(varname) ) {
			test = st_data(., varname, tmp)
			nbrmiss = colsum(J(rows(test), 1, .) :<= test)
		} else if ( st_isstrvar(varname) ) {
			test = strtrim(st_sdata(., varname, tmp))
			nbrmiss = colsum(J(rows(test), 1, "") :== test)
		} else {
			nbrmiss = .
		}
		N = rows(test)
		return(sprintf("%1.0f / %1.0f (%6.2f)", nbrmiss, N, nbrmiss / N * 100))
	}

	function summarize_by(string scalar variable, groupby, 
							string vector value_names,
							| string scalar str_if, str_in
							)
	{
		string scalar lbl_name, statacode
		string vector lbls
		real scalar C, R, c, r
		real matrix out
		
		str_if = (args() > 3 ? str_if : "")
		str_in = (args() > 4 ? str_in : "")
		lbl_name = st_varvaluelabel(groupby)
		lbls = labelsof(groupby)
		C = cols(lbls)
		R = length(value_names)
		out = J(R, C+1, .)
		for(c=1; c<=C; c++) {
			statacode = sprintf(`"summarize %s if %s == "%s":%s %s %s, detail"', 
									variable, groupby, lbls[c], lbl_name, 
									subinstr(str_if, "if", "&"), str_in)
			if ( !logstatacode(statacode) ) {
				for(r=1; r<=R; r++) {
					if ( st_numscalar(value_names[r]) != J(0,0,.) ) {
						out[r, c] = st_numscalar(value_names[r])
					}
				}
			}
		}
		statacode = sprintf(`"summarize %s %s %s, detail"', 
								variable, str_if, str_in)
		if ( !logstatacode(statacode) ) {
			for(r=1; r<=R; r++) {
				if ( st_numscalar(value_names[r]) != J(0,0,.) ) {
					out[r, C+1] = st_numscalar(value_names[r])
				}
			}
		}
		return(out)
	}

	function n_pct_tbl(string scalar variable, colvar, fmt, 
						real scalar colpct, no_small,
						| string scalar str_if, str_in
						)	
	{
		string scalar statacode, p_str
		string vector labels, test, total_hs
		string matrix less_than, out
		real scalar p, rc, ir, r, ic, c, R, C 
		real vector row_values, col_values, Row_values, Col_values, total
		real colvector slct
		real matrix cell_values, n, pct, has_small, ignore_pct
		
		str_if = (args() > 5 ? str_if : "")
		str_in = (args() > 6 ? str_in : "")
		statacode = sprintf("tabulate %s %s %s %s, chi2 matcell(mce) matrow(mr) matcol(mc)", 
							variable, colvar, str_if, str_in)
		rc = logstatacode(statacode)
		if ( !rc ) {
			p_str = (p=st_numscalar("r(p)")) != J(0, 0, .) ? strofreal(p, "%6.4f") : "."
			Row_values = label_values(variable)'
			Col_values = label_values(colvar)'
			R = length(Row_values)
			C = length(Col_values)
			n = J(R, C, .)
			cell_values = st_matrix("mce")
			row_values = st_matrix("mr")
			col_values = st_matrix("mc")
			for (r = 1; r <= rows(cell_values); r++) {
				ir = select(1::rows(Row_values), Row_values :== row_values[r])
				for (c = 1; c <= cols(cell_values); c++) {
					ic = select(1::rows(Col_values), Col_values :== col_values[c])
					n[ir, ic] = cell_values[r, c]
				}
			}
			slct = rowmissing(n) :< C
			labels = J(R, 1, "    ") + labelsof(variable, Row_values')'
			test = J(R, 1, "")
			if ( colpct ) {
				pct = 100 :* n :/ colsum(n)
			} else {
				pct = 100 :* n :/ rowsum(n)
			}
			total = rowsum(n)
			out = (labels, 
					strofreal(n) 
						+ J(R, C, " (") 
						+ strofreal(pct, fmt) 
						+ J(R, C, ")"), 
					strofreal(total), 
					test)
			if ( no_small ) { 
				has_small = (n :< no_small) :& (n :> 0)
				n = has_small :* no_small + (1 :- has_small) :* n
				total = rowsum(n)
				ignore_pct = has_small
				_editvalue(ignore_pct, 1, .)
				pct = ignore_pct :+ pct
				less_than = strofreal(has_small)
				_editvalue(less_than, "0", "")
				_editvalue(less_than, "1", "< ")
				total_hs = strofreal(rowsum(has_small) :> 0)
				_editvalue(total_hs, "0", "")
				_editvalue(total_hs, "1", "< ")
				out = (labels,
							less_than
							+ strofreal(n) 
							+ J(R, C, " (") 
							+ strofreal(pct, fmt) 
							+ J(R, C, ")"), 
						total_hs + strofreal(total), 
						test)
			}
			out = select(out, slct)
			out[rows(out), cols(out)] = p_str
			return(out)
		}
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

	real scalar _matrix2csv(string matrix x, string scalar fn, separator, real scalar replace)
	{
		real scalar rc
	
		if ( fileexists(fn) & replace) rc = _unlink(fn)
		if ( !fileexists(fn) ) { 
			fh = fopen(fn, "w")
			for(r=1;r<=rows(x);r++) fput(fh, invtokens(x[r,.], separator))
			fclose(fh)
			return(0)
		} else {
			printf(`"{red}File %s already exists. Choose option "replace" to overwrite file"', fn)
			return(-1)
		}
	}
	

	class basetable {
		private string scalar colvar, fmt 
		private real scalar valuewidth, no_small, missing
		string scalar str_if, str_in
		string matrix output
		void setup_tbl(), log_print(), n_pct(), n_pct_by(), n_pct_by_value(), mean_sd(), median_iqr(), median_iqi(), mean_ci(), mean_pi(), header()
	}

		void basetable::setup_tbl(string scalar colvar, fmt, 
									real scalar no_small, missing,
									| string scalar str_if, str_in
									)
		{
			this.colvar = colvar
			this.fmt = fmt
			this.output = "", labelsof(colvar), "Total", "P-value"
			this.valuewidth = cols(this.output) - 2
			this.no_small = no_small 
			this.missing = missing
			this.output = (this.missing ? this.output, "Missings / N (Pct)" : this.output)
			this.str_if = (args() > 5 ? str_if : "")
			this.str_in = (args() > 6 ? str_in : "")
		}

		void basetable::log_print(|string scalar style, filename, real scalar replace)
		{
			if ( style == "smcl" | style == "" ) {
				prnt = print_smcl(this.output, 2 + round(this.missing))
			} else if ( style == "csv" ) {
				prnt = this.output
				prnt[., 1] = justify_matrix(prnt[., 1], 0, "-")
				prnt[., 2..cols(prnt)] = justify_matrix(prnt[., 2..cols(prnt)])
				prnt = matrix_separate_vertically(prnt, "", ";", "\n")
			} else if ( style == "latex" | style == "tex" ) {
				prnt = this.output
				prnt[., 1] = justify_matrix(prnt[., 1], 0, "-")
				prnt[., 2..cols(prnt)] = justify_matrix(prnt[., 2..cols(prnt)])
				prnt = matrix_separate_vertically(prnt, "", " & ", " \\\ \n")
				prnt = prnt[1] \ "\hline \n" \ prnt[2..rows(prnt)]
			} else if ( style == "html" ) {
				prnt = this.output
				prnt[., 1] = justify_matrix(prnt[., 1], 0, "-")
				prnt[., 2..cols(prnt)] = justify_matrix(prnt[., 2..cols(prnt)])
				prnt = matrix_separate_vertically(prnt, "<tr><td> ", " </td><td> ", " </td></tr> \n")
				prnt[1, 1] = subinstr(prnt[1, 1], "td", "th")
			} else if ( style == "md" ) {
				prnt = this.output
				prnt[., 1] = justify_matrix(prnt[., 1], 0, "-")
				prnt[., 2..cols(prnt)] = justify_matrix(prnt[., 2..cols(prnt)])
				prnt = prnt[1, .] \ strlen(prnt[1, .]) :* "-" \ prnt[2..rows(prnt), .]
				prnt = matrix_separate_vertically(prnt, "", "  ", "\n")
			}			
			prnt = subinstr(prnt, "%", "%%") // For confidence intervals
			printf("\n")
			for(r=1; r<=rows(prnt); r++) printf(prnt[r])
			if ( filename != "" ) {
				if ( fileexists(filename) & replace ) rc = _unlink(filename)
				if ( !fileexists(filename) ) { 
					fh = fopen(filename, "w")
					for(r=1; r<=rows(prnt); r++) fput(fh, prnt[r])
					fclose(fh)
					printf("%s table is saved into %s ...", style, filename)
				} else {
					printf("{error}%s already exists!!", filename)
				}
			}
		}

		void basetable::n_pct()
		{
			real vector n, pct, col_values, Col_values
			string rowvector row
			string scalar statacode
			real scalar rc, C
			
			statacode = sprintf("tabulate %s %s %s, matcell(mce) matrow(mc)", this.colvar, 
								this.str_if, this.str_in)
			rc = logstatacode(statacode)
			if ( !rc ) {
				Col_values = label_values(this.colvar)'
				C = length(Col_values)
				n = J(1, C, .)
				cell_values = st_matrix("mce")
				col_values = st_matrix("mc")
				for (c = 1; c <= rows(cell_values); c++) {
					ic = select(1::C, Col_values :== col_values[c])
					n[ic] = cell_values[c]
				}
				pct = 100 * n / (n * J(1, cols(n), 1)')
				row = ("n (pct)", strofreal(n) 
								+ J(1, cols(n), " (") 
								+ strofreal(pct, this.fmt) 
								+ J(1, cols(n), ")"), 
								strofreal(rowsum(n)),
								""
								)
				row = this.missing ? row, missings(this.colvar, 
						this.str_if, this.str_in) : row
				this.output	=  this.output \ row 
			} else {
				this.header(sprintf("n_pct: Stata code |%s| has failed with error %f", 
						statacode, rc), "ERROR!!")
			}
		}

		void basetable::n_pct_by(string scalar variable, real scalar colpct)
		{
			string scalar pct_txt
			string rowvector header
			string colvector missings
			string matrix rows
			real scalar R			
		
			if ( _st_varindex(variable) == . ) {
				this.header(sprintf("n_pct_by: |%s| does not exist!", variable), "ERROR!!")				
			} else if ( st_varvaluelabel(variable) == "" ) {
				this.header(sprintf("n_pct_by: |%s| has no value label!", variable), "ERROR!!")
			} else {
				pct_txt = (colpct ? "column" : "row")
				header = J(1, cols(this.output), "")
				header[1] = sprintf("%s, n (%s pct)", st_varlabel(variable), pct_txt)
				this.output = this.output \ header
				rows = n_pct_tbl(variable, this.colvar, this.fmt, colpct, 
									this.no_small, this.str_if, this.str_in)
				R = rows(rows)
				missings = J(R, 1, "")
				missings[R] = missings(variable, this.str_if, this.str_in)
				rows = this.missing ? rows, missings : rows
				this.output = this.output \ rows
			}
		}
		
		void basetable::n_pct_by_value(string scalar variable, rowvalue, real scalar colpct)
		{
			string matrix rows
			real scalar R, C
			real colvector slct
			
			if ( _st_varindex(variable) == . ) {
				this.header(sprintf("n_pct_by_value: |%s| does not exist!", variable), "ERROR!!")
			} else if ( st_varvaluelabel(variable) == "" ) {
				this.header(sprintf("n_pct_by: |%s| has no value label!", variable), "ERROR!!")
			} else {
				rows = n_pct_tbl(variable, this.colvar, this.fmt, colpct, 
									this.no_small, this.str_if, this.str_in)
				slct = (strtrim(rows[.,1]) :== rowvalue)
				R = rows(rows)
				C = cols(rows)
				if ( colsum(slct) ) {
					rows = select(rows[., 1..(C-1)], slct), rows[R, C]
					rows[1] = sprintf("%s (%s), n (%s pct)", 
									st_varlabel(variable), 
									rowvalue,
									colpct ? "column" : "row"
									)
					rows = this.missing ? rows, missings(variable, this.str_if, this.str_in) : rows
					this.output = this.output \ rows
				} else {
					this.header(sprintf("n_pct_by_value: |%s| does not have value |%s|!", 
									variable, rowvalue), "ERROR!!")
				}
			}
		}

		void basetable::mean_sd(string scalar variable, fmt)
		{
			real scalar C, rc, df_m, df_r, F
			real matrix data
			string rowvector rows
			string scalar label, p_value
			
			if ( _st_varindex(variable) != . ) {
				data = summarize_by(variable, this.colvar, ("r(mean)", "r(sd)"),
									this.str_if, this.str_in)
				C = cols(data)
				label = sprintf("%s, mean (sd)", st_varlabel(variable))
				p_value = ""
				rc = logstatacode(sprintf("oneway %s %s %s %s", variable, 
									this.colvar, this.str_if, this.str_in))
				if ( !rc ) {
					df_m = st_numscalar("r(df_m)")
					df_r = st_numscalar("r(df_r)")
					F = st_numscalar("r(F)")
					if ( F != . )  p_value = strofreal(Ftail(df_m, df_r, F), "%6.4f")
				}
				rows = (label, strofreal(data[1,.], fmt)
							+ J(1, C, " (")
							+ strofreal(data[2,.], fmt) 
							+ J(1, C, ")"), 
							p_value)
				rows = this.missing ? rows, missings(variable, this.str_if, this.str_in) : rows
				this.output = this.output \ rows
			} else {
				this.header(sprintf("mean_sd: |%s| does not exist!", variable), "ERROR!!")
			}
		}

		void basetable::median_iqr(string scalar variable, fmt)
		{
			real scalar C, df, F
			real matrix data
			string rowvector rows
			string scalar statacode, label, p_value
			if ( _st_varindex(variable) != . ) {
				data = summarize_by(variable, this.colvar, 
									("r(p50)", "r(p25)", "r(p75)"),
									this.str_if, this.str_in
									)
				data = data[1,.] \ (data[3,.] - data[2,.])
				C = cols(data)
				label = sprintf("%s, median (iqr)", st_varlabel(variable))
				p_value = ""
				statacode = sprintf("kwallis %s %s %s, by(%s)", variable, 
								this.str_if, this.str_in, this.colvar)
				if ( !logstatacode(statacode) ) {
					df = st_numscalar("r(df)")
					F = st_numscalar("r(chi2)")
					p_value = strofreal(chi2tail(df, F), "%6.4f")
				}
				rows = (label, strofreal(data[1,.], fmt)
							+ J(1, C, " (")
							+ strofreal(data[2,.], fmt) 
							+ J(1, C, ")"), 
							p_value)
				rows = this.missing ? rows, missings(variable, this.str_if, this.str_in) : rows
				this.output = this.output \ rows
			} else {
				this.header(sprintf("median_iqr: |%s| does not exist!", variable), "ERROR!!")
			}
		}

		void basetable::median_iqi(string scalar variable, fmt)
		{
			real scalar C, df, F
			real matrix data
			string rowvector rows
			string scalar statacode, label, p_value
			if ( _st_varindex(variable) != . ) {
				data = summarize_by(variable, this.colvar, 
									("r(p50)", "r(p25)", "r(p75)"),
									this.str_if, this.str_in
									)
				C = cols(data)
				label = sprintf("%s, median (iqi)", st_varlabel(variable))
				p_value = ""
				statacode = sprintf("kwallis %s %s %s, by(%s)", variable, 
								this.str_if, this.str_in, this.colvar)
				if ( !logstatacode(statacode) ) {
					df = st_numscalar("r(df)")
					F = st_numscalar("r(chi2)")
					p_value = strofreal(chi2tail(df, F), "%6.4f")
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
			} else {
				this.header(sprintf("median_iqr: |%s| does not exist!", variable), "ERROR!!")
			}
		}

		void basetable::mean_ci(string scalar variable, fmt)
		{
			real scalar C, rc, df_m, df_r, F, z
			real matrix data
			string rowvector rows
			string scalar label, p_value
			if ( _st_varindex(variable) != . ) {
				data = summarize_by(variable, this.colvar, 
									("r(mean)", "r(sd)", "r(N)"),
									this.str_if, this.str_in
									)
				data = data[1,.] \ (data[2,.] :/ sqrt(data[3,.]))
				C = cols(data)
				label = sprintf("%s, mean (95%% ci)", st_varlabel(variable))
				p_value = ""
				rc = logstatacode(sprintf("oneway %s %s %s %s", variable, 
									this.colvar, this.str_if, this.str_in))
				if ( !rc ) {
					df_m = st_numscalar("r(df_m)")
					df_r = st_numscalar("r(df_r)")
					F = st_numscalar("r(F)")
					if ( F != . )  p_value = strofreal(Ftail(df_m, df_r, F), "%6.4f")
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
			} else {
				this.header(sprintf("mean_ci: |%s| does not exist!", variable), "ERROR!!")
			}
		}

		void basetable::mean_pi(string scalar variable, fmt)
		{
			real scalar C, rc, df_m, df_r, F, z
			real matrix data
			string rowvector rows
			string scalar label, p_value
			if ( _st_varindex(variable) != . ) {
				data = summarize_by(variable, this.colvar, ("r(mean)", "r(sd)"),
									this.str_if, this.str_in
									)
				C = cols(data)
				label = sprintf("%s, mean (95%% pi)", st_varlabel(variable))
				p_value = ""
				rc = logstatacode(sprintf("oneway %s %s %s %s", variable, 
									this.colvar, this.str_if, this.str_in))
				if ( !rc ) {
					df_m = st_numscalar("r(df_m)")
					df_r = st_numscalar("r(df_r)")
					F = st_numscalar("r(F)")
					if ( F != . )  p_value = strofreal(Ftail(df_m, df_r, F), "%6.4f")
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
			} else {
				this.header(sprintf("mean_pi: |%s| does not exist!", variable), "ERROR!!")
			}
		}

		void basetable::header(string scalar headertext,| separator)
		{
			string rowvector row
			
			row = J(1, cols(this.output), (args() == 2 ? separator : "***"))
			row[1] = headertext
			this.output = this.output \ row
		}


	class basetable scalar basetable_parser(	string scalar txt, fmt, continousreport, 
												real scalar no_small, missing,
												string scalar str_if, str_in
												)
	{
		class basetable scalar tbl

		t = tokeninit(" ", "", (`"()"', `"[]"'))
		tokenset(t, txt)
		lst = tokengetall(t)
		if ( regexm(lst[1], "^\[|^\(") ) _error("Arguments must not start with a [ or a (")
		if ( (e_txt=validate_variable(lst[1], 1)) != "" ) _error("First argument: " + e_txt)
		
		tbl.setup_tbl(lst[1], fmt, no_small, missing, str_if, str_in)
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
				if ( (e_txt=validate_variable(lst[r], 0)) != "" ) {
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
					if ( (e_txt=validate_variable(lst[r], 1)) != "" ) {
						tbl.header(e_txt, "ERROR!!")
						continue
					}
					if ( regexm(arguments[1], "^[0rR1cC]$") ) {
						// 0 = row pct, 1 = column pct
						tbl.n_pct_by(lst[r], regexm(arguments[1], "^[1cC]$"))
					} else {
						arguments = length(arguments) == 1 ? arguments, "c" : arguments
						tbl.n_pct_by_value(lst[r], arguments[1], regexm(arguments[2], "[1cC]$"))
					}
				}
				r++
			}
		}
		return(tbl)
	}	
end
