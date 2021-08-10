*! Part of package matrixtools v. 0.27
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
*!2021-03-01 > function nhb_muf_xlcolumn_nbr() added
*!2021-02-27 > class nhb_mt_onewai() added
*2021-02-17 > nhb_mt_chi2tabulate::set() making error for string variables
*2021-01-29 > nhb_sae_outliers() added
*2020-12-27 > cl_mt_mata_string_matrix_styled::to_html_lines() modified
*2020-09-05 > Bug in nhb_mt_mata_string_matrix_style() regarding justify fixed
*2019-06-23 > nhb_mt_labelmatrix::to_strings() rewritten to become text-based
*2020-05-24 > nhb_msa_variable_description() modified to match class cl_mt_mata_string_matrix_styled()
*2020-02-24 > class cl_mt_mata_string_matrix_styled() replaces code for function nhb_mt_mata_string_matrix_style()
*2020-02-21 > nhb_sae_addvars() has been optimised
*2020-01-29 > nhb_mt_mata_string_matrix_styled: Caption in md added a final space - error in log2markup
*2019-10-10 > nhb_mt_labelmatrix::rowsort() added
*2019-10-10 > nhb_mt_labelmatrix::copy() added
*2019-10-08 > nhb_mt_labelmatrix::to_strings() added
*2019-10-08 > nhb_mt_labelmatrix::from_dataset() added
*2019-10-08 > nhb_sae_isnumvarvector() added
*2019-10-08 > nhb_sae_collapse renamed to nhb_mt_collapse
*2019-09-13 > nhb_sae_summary_row() added geometric mean (gmean) and exponentiated sd for the geometric mean (gsd)
*2019-07-29 > nhb_sae_mata_rc() added.
*2019-06-29 > nhb_sae_stored_scalars() modified to use nhb_mt_labelmatrix, filter now is now regex
*2019-03-14 > nhb_mt_labelmatrix::transposed() added
*2019-01-30 > BUG \resizebox{\textwidth}{!}{" removed from nhb_mt_mata_string_matrix_styled()
*2018-10-09 > BUG nhb_mc_percentiles(): When "data = select(values, values :< .)" returns J(0,0,.) code were run
*2018-10-09 > nhb_sae_summary_row() now returns a class nhb_mt_labelmatrix object
*2018-10-09 > nhb_mt_labelmatrix::add_sideways() added
*2018-09-24 > nhb_sae_summary_row() added optionally smoothed data
*2018-09-24 > nhb_sae_summary_row() now calculates centiles based on formulas from -centiles- instead of -summarize-
*2018-09-21 > nhb_mc_smoothed_minmax()
*2018-09-20 > nhb_mc_smoothed_data() added
*2018-09-20 > nhb_mc_percentiles() added optionally smoothed data
*2018-09-20 > Argument smooth (smothing ordered values for calculations) added to nhb_sae_summary_row(). 
*2018-08-20 > nhb_sae_subselect() added
*2018-08-06 > nhb_mt_labelmatrix::hide_small() do nothing when limit is zero or negative
*2018-06-26 > nhb_muf_tokensplit() added
*2018-06-03 > nhb_List() extended
*2018-06-03 > nhb_mt_labelmatrix::clear() added
*2018-06-03 > nhb_mt_labelmatrix::empty() added 
*2018-06-03 > nhb_mt_labelmatrix::append() added
*2018-06-03 > nhb_mt_labelmatrix::regex_select() added
*2018-05-16 > nhb_mc_post_ci_table() added
*2018-01-09 > nhb_sae_markrows() modified
*2017-12-07 > Added class nhb_List()
*2017-12-07 > Added nhb_fp_map() and nhb_fp_reduce()
*2017-12-07 > Option to return created varnames in nhb_sae_addvars()
*2017-12-03 > modified nhb_sae_stored_scalars()
*2017-11-07 > Added nhb_msa_unab()
*2017-10-21 > Added nhb_mc_predictions()
*2017-10-21 > Added class nhb_mc_splines()
*2017-10-21 > Added nhb_mc_percentiles()
*2017-09-29 > nhb_sae_labelsof() handling non labelled values and missing values
*2017-09-29 > nhb_sae_unique_values() strictly mata and handling missing values
*2017-09-26 > nhb_sae_summary_row() returns number of nonmissing rows for string values. Consistency with numbers
*2017-09-26 > nhb_sae_summary_row() returns .m when no value is found
*2017-09-26 > nhb_sae_num_scalar() returns .m when no value is found
*2017-09-21 > nhb_sae_unique_values() modified to handle non existing variables
*2017-09-21 > nhb_mt_mata_string_matrix_styled(): default html table print split into thead og tbody
*2017-09-19 > Hide missings in nhb_mt_labelmatrix::print()
*2017-07-26 > Problem with . and : in nhb_sae_summary_row() in variable labels solved for version 14 and up
*2017-07-17 Bug in nhb_msa_variable_description() and nhb_mt_matrix_v_sep() regarding value labels fixed
*2017-06-09 bugfix when repeating basetable after style md
*2017-06-09 latex tablefit in nhb_mt_mata_string_matrix_styled
*2017-01-06 class nhb_mt_chi2tabulate added
*2017-01-06 class nhb_mt_labelmatrix added
*2016-12-27 created, revised from previous code

version 12.1

********************************************************************************
*** Matrix utility classes *****************************************************
********************************************************************************
mata:
	class nhb_mt_labelmatrix
	{
		private:
			real scalar hh
			real matrix mat
			string colvector coleq, colnm, roweq, rownm
			string matrix justify
			void new()
			string colvector duplicate_strip()
			real matrix hide_small()
		public:
			column_equations()
			column_names()
			row_equations()
			row_names()
			values()
			void from_matrix()
			void to_matrix()
			void from_labelmatrix()
			void print()
			class nhb_mt_labelmatrix scalar regex_select()
			void append()
			void add_sideways()
			real scalar empty()
			void clear()
			class nhb_mt_labelmatrix scalar transposed()
			void from_dataset()
			string matrix to_strings()
			class nhb_mt_labelmatrix scalar rowsort()
			class nhb_mt_labelmatrix scalar copy()
	}

		void nhb_mt_labelmatrix::new()
		{
			this.clear()
		}
		
		string colvector nhb_mt_labelmatrix::duplicate_strip(colvector x)
		{
			real scalar R
			real colvector slct
			string colvector strx
			
			strx = isreal(x) ? strofreal(x) : x
			R = rows(strx)
			if ( R > 1 ) {
				strx = strx :* (slct = 1 \ strx[2::R] :!= strx[1::(R-1)]) + "" :* slct
			}
			return(strx) 
		}
		
		real matrix nhb_mt_labelmatrix::hide_small(real matrix mat, real scalar limit)
			return(limit > 0 ? mat :/ (mat :>= limit) : mat)
		
		function nhb_mt_labelmatrix::column_equations(|colvector strvec)
		{
			real scalar R

			strvec = isreal(strvec) ? strofreal(strvec) : strvec
			if ( this.mat != J(0,0,.) ) {
				R = cols(this.mat)
				if ( strvec != J(0, 1, "") ) {
					if ( R <= rows(strvec) ) this.coleq = strvec[1..R]
					else this.coleq = nhb_mt_resize_matrix(strvec, R, 1)
				} else {
					if ( this.coleq == J(0,0,"") ) {
						this.coleq = J(R, 1, "")
					} else {
						if ( R <= rows(this.coleq) ) {
							this.coleq = this.coleq[1..R]
						} else {
							this.coleq = nhb_mt_resize_matrix(this.coleq, R, 1)
						}
					}
					return(this.coleq) 
				}
			}
		}
		
		function nhb_mt_labelmatrix::column_names(|colvector strvec)
		{
			real scalar R
			
			strvec = isreal(strvec) ? strofreal(strvec) : strvec
			if ( this.mat != J(0,0,.) ) {
				R = cols(this.mat)
				if ( strvec != J(0, 1, "") ) {
					if ( R <= rows(strvec) ) this.colnm = strvec[1..R]
					else this.colnm = nhb_mt_resize_matrix(strvec, R, 1)
				} else {
					if ( this.colnm == J(0,0,"") ) {
						this.colnm = J(R, 1, "")
					} else {
						if ( R <= rows(this.colnm) ) {
							this.colnm = this.colnm[1..R]
						} else {
							this.colnm = nhb_mt_resize_matrix(this.colnm, R, 1)
						}
					}
					return(this.colnm) 
				}
			}
		}
		
		function nhb_mt_labelmatrix::row_equations(|colvector strvec)
		{
			real scalar R
			
			strvec = isreal(strvec) ? strofreal(strvec) : strvec
			if ( this.mat != J(0,0,.) ) {
				R = rows(this.mat)
				if ( strvec != J(0, 1, "") ) {
					if ( R <= rows(strvec) ) this.roweq = strvec[1..R]
					else this.roweq = nhb_mt_resize_matrix(strvec, R, 1)
				} else {
					if ( this.roweq == J(0,0,"") ) {
						this.roweq = J(R, 1, "")
					} else {
						if ( R <= rows(this.roweq) ) {
							this.roweq = this.roweq[1..R]
						} else {
							this.roweq = nhb_mt_resize_matrix(this.roweq, R, 1)
						}
					}
					return(this.roweq) 
				}
			}
		}
			
		function nhb_mt_labelmatrix::row_names(|colvector strvec)
		{
			real scalar R
			
			strvec = isreal(strvec) ? strofreal(strvec) : strvec
			if ( this.mat != J(0,0,.) ) {
				R = rows(this.mat)
				if ( strvec != J(0, 1, "") ) {
					if ( R <= rows(strvec) ) this.rownm = strvec[1..R]
					else this.rownm = nhb_mt_resize_matrix(strvec, R, 1)
				} else {
					if ( this.rownm == J(0,0,"") ) {
						this.rownm = J(R, 1, "")
					} else {
						if ( R <= rows(this.rownm) ) {
							this.rownm = this.rownm[1..R]
						} else {
							this.rownm = nhb_mt_resize_matrix(this.rownm, R, 1)
						}
					}
					return(this.rownm) 
				}
			}
		}
		
		function nhb_mt_labelmatrix::values(|real matrix mat)
		{
			if ( mat != J(0, 0, .) ) this.mat = mat
			else return(this.mat)
		}
		
		void nhb_mt_labelmatrix::from_matrix(string scalar matrixname)
		{
			if ( st_matrix(matrixname) != J(0,0,.) ) {
				this.values(st_matrix(matrixname))
				this.column_equations(st_matrixcolstripe(matrixname)[.,1])
				this.column_names(st_matrixcolstripe(matrixname)[.,2])
				this.row_equations(st_matrixrowstripe(matrixname)[.,1])
				this.row_names(st_matrixrowstripe(matrixname)[.,2])
                if ( all(regexm(this.row_names(), "^r[0-9]+$")) ) {
                    this.row_names("")
                    this.row_equations("")
                }
                if ( all(regexm(this.column_names(), "^c[0-9]+$")) ) {
                    this.column_names("")
                    this.column_equations("")
                }
			}
		}
		
		void nhb_mt_labelmatrix::to_matrix(string scalar matrixname,| real scalar keep_old)
		{
        	real scalar R
			string colvector roweq, rownm, coleq, colnm
            
			if ( this.values() != J(0,0,.) ) {
				if ( !keep_old ) st_matrix(matrixname, J(0,0,.))
                roweq = this.row_equations()
                rownm = this.row_names()
                coleq = this.column_equations()
                colnm = this.column_names()
                R = rows(roweq)
                if ( all(roweq :== "") ) roweq = J(R, 1, " ")
                if ( all(rownm :== "") ) rownm = J(R, 1, " ")
                R = rows(coleq)
                if ( all(coleq :== "") ) coleq = J(R, 1, " ")
                if ( all(colnm :== "") ) colnm = J(R, 1, " ")
                st_matrix(matrixname, this.values())
                st_matrixcolstripe(matrixname,  abbrev((coleq, colnm), 32))
                st_matrixrowstripe(matrixname,  abbrev((roweq, rownm), 32))
			}
		}
		
		void nhb_mt_labelmatrix::from_labelmatrix(class nhb_mt_labelmatrix scalar m)
		{
			if ( m.values() != J(0,0,.) ) {
				this.mat = m.values()
				this.coleq = m.column_equations()
				this.colnm = m.column_names()
				this.roweq = m.row_equations()
				this.rownm = m.row_names()
			}
		}
		
		void nhb_mt_labelmatrix::print(|string scalar style,
								real matrix decimalwidth,
								real scalar duplicate_strip,
								real scalar hidesmall,
								string scalar caption,
								string scalar top, 
								string scalar undertop, 
								string scalar bottom,
								string scalar savefile, 
								real scalar overwrite
								)
		{
			real scalar R, C, hh
			string colvector roweq, rownm, coleq, colnm, lines
			string matrix m, justify
			
			if ( this.mat != J(0,0,.) ) {
				m = this.to_strings(decimalwidth, duplicate_strip, hidesmall)
				lines = nhb_mt_mata_string_matrix_styled(	m, 
															style, 
															this.justify,
															this.hh,
															caption, 
															top, 
															undertop,
															bottom, 
															savefile, 
															overwrite
															) // Assignment just to prevent list of lines being printed
			} else {
				printf("{error:Nothing to print}")
			}
		}
		
		class nhb_mt_labelmatrix scalar nhb_mt_labelmatrix::regex_select(
			string scalar str_regex,
			| real scalar keep,	// default keep
			real scalar names,	// default names
			real scalar row		// default row
			)
		{
			real vector slct, slct_values
			class nhb_mt_labelmatrix scalar out
			
			if ( !names & row ) slct_values = this.row_equations()
			else if ( names & row ) slct_values = this.row_names()
			else if ( !names & !row ) slct_values = this.column_equations()
			else if ( names & !row ) slct_values = this.column_names()

			slct = regexm(slct_values, str_regex)
			if ( !keep ) slct = !slct
			if ( row ) {
				out.values(select(this.values(), slct))
				out.row_equations(select(this.row_equations(), slct))
				out.row_names(select(this.row_names(), slct))
				out.column_equations(this.column_equations())
				out.column_names(this.column_names())
			} else {
				out.values(select(this.values()', slct)')
				out.row_equations(this.row_equations())
				out.row_names(this.row_names())
				out.column_equations(select(this.column_equations(), slct))
				out.column_names(select(this.column_names(), slct))
			}
			return(out)
		}
		
		real scalar nhb_mt_labelmatrix::empty() return(this.mat == J(0,0,.))

		void nhb_mt_labelmatrix::append(class nhb_mt_labelmatrix scalar m)
		{
			colvector eq, nm
		
			eq = this.row_equations()
			nm = this.row_names()
			this.values(this.values() \ m.values())
			this.row_equations(eq \ m.row_equations())
			this.row_names(nm \ m.row_names())
		}

		void nhb_mt_labelmatrix::add_sideways(class nhb_mt_labelmatrix scalar m)
		{
			colvector eq, nm
		
			eq = this.column_equations()
			nm = this.column_names()
			this.values( (this.values(), m.values()) )
			this.column_equations(eq \ m.column_equations())
			this.column_names(nm \ m.column_names())
		}
		
		void nhb_mt_labelmatrix::clear()
		{
			this.mat = J(0,0,.)
			this.coleq = this.colnm = J(0,0,"")
			this.roweq = this.rownm = J(0,0,"")
			this.hh = 0
			this.justify = ""
		}
		
		class nhb_mt_labelmatrix scalar nhb_mt_labelmatrix::transposed()
		{
			class nhb_mt_labelmatrix scalar out
			
			out.values(this.values()')
			out.column_equations(this.row_equations())
			out.column_names(this.row_names())
			out.row_equations(this.column_equations())
			out.row_names(this.column_names())
			return(out)
		}

		void nhb_mt_labelmatrix::from_dataset(
			string colvector varnames, 
			| string scalar rownames,
			string scalar rowequations,
			real scalar uniqs,
			real scalar add_counts
			)
		{
			real matrix values
			string colvector rnms, rqs
			
			if ( _st_varindex(rownames) != . ) {
				varnames = select(varnames, varnames :!= rownames)
				if ( st_isnumvar(rownames) ) {
					if ( st_varvaluelabel(rownames) != "" ) rnms = nhb_sae_labelsof(rownames, st_data(., rownames)')'
					else rnms = strofreal(st_data(., rownames))
				} else rnms = st_sdata(., rownames)
				if ( _st_varindex(rowequations) != . ) {
					varnames = select(varnames, varnames :!= rowequations)
					if ( st_isnumvar(rowequations) ) {
						if ( st_varvaluelabel(rowequations) != "" ) rqs = nhb_sae_labelsof(rowequations, st_data(., rowequations)')'
						else rqs = strofreal(st_data(., rowequations))
					} else rqs = st_sdata(., rowequations)
					this.row_equations(rqs)
				}
			}
			if ( add_counts == . ) add_counts = 0
			varnames = nhb_sae_isnumvarvector(varnames)
			values = st_data(., varnames')
			if ( !uniqs ) {
				values = uniqrows(values, add_counts)
				if ( add_counts ) varnames = varnames \ "Counts"
			}
			this.values(values)
			this.column_names(varnames)
			this.row_equations(rqs)
			this.row_names(rnms)
		}
	
		string matrix nhb_mt_labelmatrix::to_strings(	|real matrix decimalwidth,
														real scalar duplicate_strip,
														real scalar hidesmall
														)
		{
			real scalar R, C, hh
			string colvector roweq, rownm, coleq, colnm, lines
			string matrix m, justify
			
			if ( this.mat != J(0,0,.) ) {
				R = rows(this.mat)
				C = cols(this.mat)
				decimalwidth = (decimalwidth == J(0,0,.) ? 2 : decimalwidth)
				if ( hidesmall < . ) {
					m = nhb_mt_format_real_matrix(this.hide_small(this.mat, hidesmall), decimalwidth)
				} else {
					m = nhb_mt_format_real_matrix(this.mat, decimalwidth)
				}
				m = m :* (this.mat :< .)
				this.justify = ""
				roweq = this.row_equations()
				rownm = this.row_names()
				coleq = this.column_equations()
				colnm = this.column_names()
				if ( duplicate_strip ) {
					if ( roweq != J(R, 1, "") ) roweq = duplicate_strip(roweq)
					if ( coleq != J(C, 1, "") ) coleq = duplicate_strip(coleq)
				}
				if ( rownm != J(R, 1, "") ) {
					m = rownm, m
					this.justify = "-", this.justify
					coleq = "" \ coleq
					colnm = "" \ colnm
				}
				if ( roweq != J(R, 1, "") ) {
					m = roweq, m
					this.justify = "-", this.justify
					coleq = "" \ coleq
					colnm = "" \ colnm
				}
                
				R = rows(coleq)
                this.hh = 0
                if ( colnm != J(R, 1, "") ) {
					m = colnm' \ m
					this.hh = 1
				} 
                if ( coleq != J(R, 1, "") ) {
					m = coleq' \ m
					this.hh = 2
				}
			} else m = J(0,0,"")
			return(m)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_labelmatrix::copy()
		{
			class nhb_mt_labelmatrix scalar lm
			
			lm.values(this.values())
			lm.column_equations(this.column_equations())
			lm.column_names(this.column_names())
			lm.row_equations(this.row_equations())
			lm.row_names(this.row_names())
			return(lm)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_labelmatrix::rowsort()
		{
			string matrix srts
			real matrix srtmat
			class nhb_mt_labelmatrix scalar lm

			lm = this.copy()
			srts = strofreal(1::rows(lm.values()))
			if ( lm.row_names() != J(0,1,"") ) {
				if ( lm.row_equations() != J(0,1,"") ) {
					srts = sort((srts, lm.row_equations(), lm.row_names()), 2..3)
					lm.row_equations(srts[., 2])
					lm.row_names(srts[., 3])
				} else {
					srts = sort((srts, lm.row_names()), 2)
					lm.row_names(srts[., 2])
				}
				srts = srts[., 1]
				srtmat = strtoreal(srts), lm.values()
				srtmat = sort(srtmat, 1)[.,2..cols(srtmat)]
				lm.values(srtmat)
			}
			return(lm)
		}


	class nhb_mt_chi2tabulate
	{
		private:
			real scalar isset
			real scalar showcode, addquietly
			void new()
			class nhb_mt_labelmatrix scalar counts, tests, greeks
		public:
			void set()
			class nhb_mt_labelmatrix scalar tests()
			class nhb_mt_labelmatrix scalar counts()
			class nhb_mt_labelmatrix scalar greeks()
			class nhb_mt_labelmatrix scalar counts_with_totals()
			class nhb_mt_labelmatrix scalar expected()
			class nhb_mt_labelmatrix scalar proportions()
			class nhb_mt_labelmatrix scalar row_proportions()
			class nhb_mt_labelmatrix scalar column_proportions()
			class nhb_mt_labelmatrix scalar pearson_chisquare_parts()
			class nhb_mt_labelmatrix scalar likelihood_ratio_chisquare_parts()
	}
	
		void nhb_mt_chi2tabulate::new()
		{
			this.isset = 0
			this.counts = nhb_mt_labelmatrix()
			this.tests = nhb_mt_labelmatrix()
			this.greeks = nhb_mt_labelmatrix()
		}
		
		void nhb_mt_chi2tabulate::set(	string scalar var1, 
										| string scalar var2,
										string scalar str_if, 
										string scalar str_in, 
										string scalar str_weight,
										real scalar exactno,
										real scalar missing,
										real scalar no_vlbl,
										real scalar showcode,
										real scalar addquietly
										)	
		{
			string scalar strmiss, statacode, exact, lbl
			real scalar rc, f, chi2, p, chi2_lr, p_lr, CramersV, gamma, ase_gam, taub, ase_taub, p_exact

			strmiss = any(missing :== (0, .)) ? "" : "missing"
			showcode = showcode == . ? 0 : showcode
            if ( !st_isnumvar(var1) ) _error(sprintf("Variable %s must be numeric", var1))
			if ( var2 == "" ) {
				statacode = sprintf("tabulate %s %s %s %s, matcell(__mc) matrow(__lblr) %s", 
								var1, str_if, str_in, str_weight, strmiss)
			} else {
            	if ( !st_isnumvar(var2) ) _error(sprintf("Variable %s must be numeric", var2))
				exact = ( 0 < exactno & exactno < . ? sprintf("exact(%f)", exactno) : "")
				statacode = sprintf("tabulate %s %s %s %s %s, %s all matcell(__mc) matrow(__lblr) matcol(__lblc) %s", 
								var1, var2, str_if, str_in, str_weight, exact, strmiss)
			}
			rc = nhb_sae_logstatacode(statacode, showcode, addquietly)
			this.isset = 0
			if ( !rc & st_matrix("__mc") != J(0,0,.) ) {
				this.isset = 1
				this.counts.values(st_matrix("__mc"))
				if ( no_vlbl != 0 & no_vlbl != . ) {
					this.counts.row_equations(var1)
					this.counts.row_names(st_matrix("__lblr"))
					if (var2 != "") {
						this.counts.column_equations(var2)
						this.counts.column_names(st_matrix("__lblc")')
					} else {
						this.counts.column_names("Frequency")
					}
				} else {
					lbl = (lbl=st_varlabel(var1)) == "" ? var1 : lbl
					this.counts.row_equations(lbl)
					this.counts.row_names(nhb_sae_labelsof(var1, st_matrix("__lblr")')')
					if (var2 != "") {
						lbl = (lbl=st_varlabel(var2)) == "" ? var2 : lbl
						this.counts.column_equations(lbl)
						this.counts.column_names(nhb_sae_labelsof(var2, st_matrix("__lblc"))')
					} else {
						this.counts.column_names("Frequency")
					}
				}
				if ( var2 != "" ) {
					this.isset = 2
					//tests
					f = (nhb_sae_num_scalar("r(r)") - 1) * (nhb_sae_num_scalar("r(c)") - 1)
					chi2 = nhb_sae_num_scalar("r(chi2)")
					p = nhb_sae_num_scalar("r(p)")
					chi2_lr = nhb_sae_num_scalar("r(chi2_lr)")
					p_lr = nhb_sae_num_scalar("r(p_lr)")
					if ( exact == "" ) {
						this.tests.values((chi2, f, p \ chi2_lr, f, p_lr))
						this.tests.row_names(("Pearson", "LR")')
					} else {
						p_exact = nhb_sae_num_scalar("r(p_exact)")
						this.tests.values((chi2, f, p \ chi2_lr, f, p_lr \ ., ., p_exact))
						this.tests.row_names(("Pearson", "LR", "Fisher's exact")')
					}
					this.tests.column_names(("Test", "f", "P")')
					//greeks
					CramersV = nhb_sae_num_scalar("r(CramersV)")
					gamma = nhb_sae_num_scalar("r(gamma)")
					ase_gam = nhb_sae_num_scalar("r(ase_gam)")
					taub = nhb_sae_num_scalar("r(taub)")
					ase_taub = nhb_sae_num_scalar("r(ase_taub)")
					this.greeks.values((CramersV, . \ gamma, ase_gam \ taub, ase_taub))
					this.greeks.column_names(("Estimate", "ASE")')
					this.greeks.row_names(("Cramers V", "Gamma", "Kendalls tau b")')
				}
			} 
		}
		
		class nhb_mt_labelmatrix scalar nhb_mt_chi2tabulate::tests()
		{
			return(this.tests)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_chi2tabulate::counts()
		{
			return(this.counts)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_chi2tabulate::greeks()
		{
			return(this.greeks)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_chi2tabulate::counts_with_totals()
		{
			class nhb_mt_labelmatrix scalar m
			
			if ( this.isset ) {
				m = this.counts
				if ( this.isset == 2 ) {
					m.values( (m.values(), rowsum(m.values())) )
					m.column_equations( (this.counts.column_equations() \ "") )
					m.column_names( (this.counts.column_names() \ "Total") )
				}
				m.values( (m.values() \ colsum(m.values())) )
				m.row_equations( this.counts.row_equations() \ "" )
				m.row_names( this.counts.row_names() \ "Total" )
			}
			return(m)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_chi2tabulate::expected()
		{
			real matrix vm
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset == 2 ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				lm.values(vm[., cols(vm)] # vm[rows(vm), .] :/ vm[rows(vm), cols(vm)])
			}
			return(lm)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_chi2tabulate::proportions()
		{
			real matrix vm
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				lm.values(vm :/ vm[rows(vm), cols(vm)])
				if ( this.isset == 1 ) lm.column_names("%")
			}
			return(lm)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_chi2tabulate::row_proportions()
		{
			real matrix vm
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset == 2 ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				lm.values(vm :/ vm[., cols(vm)])
			}
			return(lm)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_chi2tabulate::column_proportions()
		{
			real matrix vm
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset == 2 ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				lm.values(vm :/ vm[rows(vm), .])
			}
			return(lm)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_chi2tabulate::pearson_chisquare_parts()
		{
			real scalar R, C
			real matrix vm, em
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset == 2 ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				R = rows(vm) - 1
				C = cols(vm) - 1
				vm = vm[1..R, 1..C]
				em = this.expected().values()[1..R, 1..C]
				vm = (vm - em) :^2 :/ em
				vm = vm, rowsum(vm)
				vm = vm \ colsum(vm)
				lm.values(vm)
				return(lm)
			}
			return(lm)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_chi2tabulate::likelihood_ratio_chisquare_parts()
		{
			real scalar R, C
			real matrix vm, em
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset == 2 ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				R = rows(vm) - 1
				C = cols(vm) - 1
				vm = vm[1..R, 1..C]
				em = this.expected().values()[1..R, 1..C]
				vm =  2 :* vm :* ln(vm :/ em)
				vm = vm, rowsum(vm)
				vm = vm \ colsum(vm)
				lm.values(vm)
				return(lm)
			}
			return(lm)
		}
		
		
	real matrix nhb_mt_collapse(real matrix keys, 
								|real colvector marker,
								 real colvector values)
	{
		real scalar r, R, C, uR, uc
		real matrix uniq 
		real colvector summary
		real rowvector uval

		if ( marker != J(0,1,.) ) keys = keys, marker
		R = rows(keys)
		C = cols(keys)
		
		uniq = sort(uniqrows(keys), 1..C)
		uR = rows(uniq)
		summary = J(uR, 1, 0)
		uc = 1
		uval = uniq[uc, .]

		if ( values == J(0,1,.) ) values = J(R, 1, 1)
		keys = keys, values
		keys = sort(keys, 1..C)
		
		for(r=1;r<=R;r++){
			if ( uval != keys[r, 1..C] ) {
				uc++
				uval = uniq[uc, .]
			}
			summary[uc] = summary[uc] + keys[r, C+1]
		}
		if ( marker != J(0,1,.) ) {
			summary = summary :* (uniq[.,C] :!= 0)
			uniq = uniq[., 1..C-1]
			return(nhb_mt_collapse(uniq, J(0,1,.), summary))
		}
		return((uniq, summary))
	}

	
	class nhb_mt_tabulate
	{
		private:
			real scalar isset
			void new()
			real colvector validate_varname()
			class nhb_mt_labelmatrix scalar counts
		public:
			void set()
			class nhb_mt_labelmatrix scalar counts()
			class nhb_mt_labelmatrix scalar counts_with_totals()
			class nhb_mt_labelmatrix scalar expected()
			class nhb_mt_labelmatrix scalar proportions()
			class nhb_mt_labelmatrix scalar row_proportions()
			class nhb_mt_labelmatrix scalar column_proportions()
			class nhb_mt_labelmatrix scalar pearson_chisquare_parts()
			class nhb_mt_labelmatrix scalar likelihood_ratio_chisquare_parts()
			class nhb_mt_labelmatrix scalar tests()
	}

		void nhb_mt_tabulate::new()
			{
				this.isset = 0
				this.counts = nhb_mt_labelmatrix()
			}
		
		real colvector nhb_mt_tabulate::validate_varname(string scalar varname)
		{
			real colvector values
		
			if ( varname == "" ) values = J(0, 1, .)
			else if ( & _st_varindex(varname) == . ) values = J(0, 1, .) 
			else if ( !st_isnumvar(varname) ) values = J(0, 1, .)
			else values = st_data(., varname)
			return( values )
		}
		
		void nhb_mt_tabulate::set(	string scalar row_vname, 
									| string scalar col_vname,
									string scalar str_if, 
									string scalar str_in, 
									string scalar var_weight,
									real scalar drop_missings/*,
									real scalar no_vlbl,
									real scalar hidesmall*/
									)	
		{
			real scalar r, c, v, R, C, V
			real colvector rvalues, cvalues, marker, weights
			string scalar var_ifin
			real matrix keys, m, values
			
			keys = this.validate_varname(row_vname)
			cvalues = this.validate_varname(col_vname)
			if ( cvalues != J(0, 1, .) ) keys = keys, cvalues
			if ( str_if != "" | str_in != "" ) {
				var_ifin = nhb_sae_markrows(str_if, str_in)
				marker = this.validate_varname(var_ifin)
				//keys = keys, marker
				st_dropvar(var_ifin)
			} else marker = J(0, 1, .)
			weights = this.validate_varname(var_weight)
			m = nhb_mt_collapse(keys, marker, weights)
			rvalues = uniqrows(m[.,1])
			if ( drop_missings ) rvalues = select(rvalues, rvalues :< .)
			if ( col_vname != "" ) {
				cvalues = uniqrows(m[.,2])
				if ( drop_missings ) cvalues = select(cvalues, cvalues :< .) 
				V = rows(m)
				r = 1
				c = 1
				R = rows(rvalues)
				C = rows(cvalues)
				values = J(R, C, 0)
				for(v=1;v<=V;v++){
					if ( m[v,1] != rvalues[r] ) r++
					if ( r > R ) break
					for(c=1;c<=C;c++) {
						if ( m[v,2] == cvalues[c] ) {
							values[r,c] = m[v,3]
							break
						}
					}
				}
				this.counts.values(values)
				this.counts.row_names(nhb_sae_labelsof(row_vname)')
				this.counts.column_names(nhb_sae_labelsof(col_vname)')
				this.isset = 2
			} else {
				this.counts.values(m[., 2])
				this.counts.row_names(nhb_sae_labelsof(row_vname)')
				this.counts.column_names("n")
				this.isset = 1
			}
		}

		class nhb_mt_labelmatrix scalar nhb_mt_tabulate::counts()
		{
			return(this.counts)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_tabulate::counts_with_totals()
		{
			class nhb_mt_labelmatrix scalar m
			
			if ( this.isset ) {
				m = this.counts
				if ( this.isset == 2 ) {
					m.values( (m.values(), rowsum(m.values())) )
					m.column_equations( (this.counts.column_equations() \ "") )
					m.column_names( (this.counts.column_names() \ "Total") )
				}
				m.values( (m.values() \ colsum(m.values())) )
				m.row_equations( this.counts.row_equations() \ "" )
				m.row_names( this.counts.row_names() \ "Total" )
			}
			return(m)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_tabulate::expected()
		{
			real matrix vm
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset == 2 ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				lm.values(vm[., cols(vm)] # vm[rows(vm), .] :/ vm[rows(vm), cols(vm)])
			}
			return(lm)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_tabulate::proportions()
		{
			real matrix vm
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				lm.values(vm :/ vm[rows(vm), cols(vm)])
				if ( this.isset == 1 ) lm.column_names("%")
			}
			return(lm)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_tabulate::row_proportions()
		{
			real matrix vm
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset == 2 ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				lm.values(vm :/ vm[., cols(vm)])
			}
			return(lm)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_tabulate::column_proportions()
		{
			real matrix vm
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset == 2 ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				lm.values(vm :/ vm[rows(vm), .])
			}
			return(lm)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_tabulate::pearson_chisquare_parts()
		{
			real scalar R, C
			real matrix vm, em
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset == 2 ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				R = rows(vm) - 1
				C = cols(vm) - 1
				vm = vm[1..R, 1..C]
				em = this.expected().values()[1..R, 1..C]
				vm = (vm - em) :^2 :/ em
				vm = vm, rowsum(vm)
				vm = vm \ colsum(vm)
				lm.values(vm)
				return(lm)
			}
			return(lm)
		}

		class nhb_mt_labelmatrix scalar nhb_mt_tabulate::likelihood_ratio_chisquare_parts()
		{
			real scalar R, C
			real matrix vm, em
			class nhb_mt_labelmatrix scalar lm
		
			if ( this.isset == 2 ) {
				lm = this.counts_with_totals()
				vm = lm.values()
				R = rows(vm) - 1
				C = cols(vm) - 1
				vm = vm[1..R, 1..C]
				em = this.expected().values()[1..R, 1..C]
				vm =  2 :* vm :* ln(vm :/ em)
				vm = vm, rowsum(vm)
				vm = vm \ colsum(vm)
				lm.values(vm)
				return(lm)
			}
			return(lm)
		}
		
		class nhb_mt_labelmatrix scalar nhb_mt_tabulate::tests()
		{
			real scalar R, C, pchi2, lrchi2, f
			real matrix vm
			class nhb_mt_labelmatrix scalar lm
			
			if ( this.isset == 2 ) {
				lm.values(J(2,3,.))
				lm.row_names(("Pearson", "LR")')
				lm.column_names(("Test", "f", "P")')
				vm = this.counts().values()
				R = rows(vm) + 1
				C = cols(vm) + 1
				pchi2 = this.pearson_chisquare_parts().values()[R,C]
				lrchi2 = this.likelihood_ratio_chisquare_parts().values()[R,C]
				if ( (R = sum(rowsum(vm) :> 0)) & (C = sum(colsum(vm) :> 0)) ) {
					f = (R - 1) * (C - 1)
					if ( f > 0 ) {
						(lm.values())[1,1] = pchi2
						(lm.values())[2,1] = lrchi2
						(lm.values())[1,2] = f
						(lm.values())[2,2] = f
						(lm.values())[1,3] = chi2tail(f, pchi2)
						(lm.values())[2,3] = chi2tail(f, lrchi2)
					}
				}
			}
			return(lm)
		}
        
    class nhb_mt_onewai
    {
    	private:
            real colvector n, m, sd
            class nhb_mt_labelmatrix scalar anova
        public:
            counts(), means(), sds()
            void nmsmatrix(), do_anova()
            class nhb_mt_labelmatrix scalar anova(), bartletts(), totalmean(), table(), icc()
    }

        function nhb_mt_onewai::counts(|real rowvector n)
        {
        	if ( n == J(1,0,.) ) return(this.n)
            else {
            	this.n = n'
            }
        }
    
        function nhb_mt_onewai::means(|real rowvector m)
        {
        	if ( m == J(0,1,.) ) return(this.m)
            else {
            	this.m = m'
            }
        }
    
        function nhb_mt_onewai::sds(|real rowvector sd)
        {
        	if ( sd == J(0,1,.) ) return(this.sd)
            else {
            	this.sd = sd'
            }
        }
    
        void nhb_mt_onewai::nmsmatrix(
            string scalar matrixname, 
            |real scalar transpose)
        {
        	real matrix mat
            
            mat = st_matrix(matrixname)
            if ( mat == J(0,0,.) ) _error("Matrix does not exist")
            mat =  transpose == 0 | transpose >= . ? mat : mat'
            if ( cols(mat) != 3 ) _error("Matrix must have 3 columns. Or 3 rows if transpose is set")
            this.n = mat[.,1]
            this.m = mat[.,2]
            this.sd = mat[.,3]
        }
    
        void nhb_mt_onewai::do_anova()
        {
        	real scalar R, N, M, F, p
            real matrix ss
            
            R = rows(this.m)             
        	if ( rows(this.n) != R ) this.n = nhb_mt_resize_matrix(this.n, R, 1)
        	if ( rows(this.sd) != R ) this.sd = nhb_mt_resize_matrix(this.sd, R, 1)
            
            N = sum(this.n)
            M = sum(this.n :* this.m) / N
            
            ss = colsum(this.n:*(this.m :- M) :^2), rows(this.n) - 1 \
                 sum((this.sd :^ 2) :* (this.n :- 1)), N - rows(this.n) \
                 sum((this.sd :^ 2) :* (this.n :- 1) :+ this.n :* this.m :^ 2) - N * M^2, N - 1
            ss = ss, ss[.,1] :/ ss[.,2], J(3,2,.) 
            F = ss[1,3] / ss[2,3]
            p = Ftail(ss[1,2], ss[2,2], F)
            ss[1,4..5] = (F, p)
            this.anova.values(ss)
            this.anova.row_names(("Between groups", "Within groups (Error)", "Total")')
            this.anova.column_names(("SS", "df", "MS", "F", "Prob > F")')
        }
        
        class nhb_mt_labelmatrix scalar nhb_mt_onewai::anova()
        {
            return(this.anova)
        }

        class nhb_mt_labelmatrix scalar nhb_mt_onewai::bartletts()
        {
        	class nhb_mt_labelmatrix scalar lm
            real scalar N, k, sp2, p
            
            N = sum(this.n)
            k = rows(this.n)
            sp2 = (this.n :- 1)' * this.sd :^ 2 / (N - k)
            chi2 = ((N - k) * ln(sp2) - 2 :* (this.n :- 1)' * ln(this.sd)) / 
                    (1 + (sum(1 :/ (this.n :- 1)) - 1 / (N-k)) / 3 / (k - 1))
            p = chi2tail(k-1, chi2)
            lm.values((chi2, k-1, p))
            lm.row_names(("Bartlett's test"))
            lm.column_names(("Chi2", "df", "Prob > chi2")')
            return(lm)            
        }
        
        class nhb_mt_labelmatrix scalar nhb_mt_onewai::totalmean()
        {
        	class nhb_mt_labelmatrix scalar lm
            real scalar N, M, SD, SE, t
            
            N = sum(this.n)
            M = sum(this.n :* this.m) / N
            t = invttail(N-1, (100-c("level"))/200)
            SD = sqrt(this.anova.values()[3,3])
            SE = SD / sqrt(N)
            lm.values((N, M, SD, SE, M - t * SE, M + t * SE))
            lm.row_names(("Total"))
            lm.column_names(("N", "Mean", "Std Dev", "Std Error", 
                sprintf("[%2.0f%% Conf",c("level")), "Interval]")')
        	return(lm)
        }
        
        class nhb_mt_labelmatrix scalar nhb_mt_onewai::table()
        {
        	class nhb_mt_labelmatrix scalar lm
        	real scalar R
            real colvector t, se
            
            R = rows(this.m)
            t = invttail(this.n:-1, (100-c("level"))/200)
            se = sd :/ sqrt(n)
            lm.values((this.n, this.m, this.sd, se, this.m :- t :* se, this.m :+ t :* se))
            lm.row_names(strofreal(1::R))
            lm.column_names(("N", "Mean", "Std Dev", "Std Error", 
                sprintf("[%2.0f%% Conf",c("level")), "Interval]")')
            lm.append(this.totalmean())
            return(lm)
        }
        
        class nhb_mt_labelmatrix scalar nhb_mt_onewai::icc()
        {
        	class nhb_mt_labelmatrix scalar lm
        	real scalar k, N, N2, N3, F, g, rho, A, B, C, SD_rho, z, sd_t, sd_e 
            
            k = rows(this.n)
            N = sum(this.n)
            N2 = sum(this.n :^ 2)
            N3 = sum(this.n :^ 3)
            F = this.anova().values()[1,4]
            g = (N - N2 / N) / (k - 1)
            rho = F > 1 ? (F - 1) / (F - 1 + g) : 0
            A = (1 + rho * (g - 1))^2 / (N - k)
            B = (1 - rho) * (1 + rho * (2 * g - 1)) / (k - 1)
            C = rho^2 * (N2 - 2 * N3 / N + (N2 / N)^2) / (k - 1)^2
            sd_rho = (1 - rho) * sqrt(2 * (A + B + C)) / g
            z = invnormal((100+c("level"))/200)
            sd_e = sqrt(this.anova().values()[2,3])
            sd_t = sqrt((this.anova().values()[1,3] - sd_e) / g)
            lm.values((rho, sd_rho, rho - z * sd_rho, rho + z * sd_rho \ sd_t, ., ., . \  sd_e, ., ., .))
            lm.row_names( ("ICC", "Treatment std dev", "Error within std dev")')
            lm.column_names(("Estimate", "Std Error", 
                sprintf("[%2.0f%% Conf",c("level")), "Interval]")')
            return(lm)
        }
end


/*******************************************************************************
*** Styling mata string matrices ***********************************************
*******************************************************************************/
mata:
	class cl_mt_mata_string_matrix_styled
	{
    	// properties
		private:
			void new(), reset()
			real scalar headerheight
			string matrix justify, string_matrix
			string scalar caption, style
			string colvector top, undertop, bottom
		public:
            string_matrix()
			justify(), headerheight(), style()
			caption(), top(), undertop(), bottom()
        // methods
		private:
			string colvector matrix_to_colvector()
            string matrix justified_matrix()
			string colvector to_smcl_lines(), to_csv_lines(), to_latex_lines(), to_html_lines(), to_md_lines()
		public:
            string colvector styled_lines()
			void print()
	}

		void cl_mt_mata_string_matrix_styled::new()
		{
			this.reset()
            this.style = ""
            this.string_matrix = J(0, 0, "")
		}

		void cl_mt_mata_string_matrix_styled::reset()
		{
			this.headerheight = 1
			this.top = J(0,1,"")
			this.undertop = J(0,1,"")
			this.bottom = J(0,1,"")
			this.caption = ""
			this.justify = J(1, 1, "")
		}
		
		function cl_mt_mata_string_matrix_styled::justify(|string matrix strmat)
        {
            if ( strmat == J(0,0,"") ) return(this.justify)
            else this.justify = strmat
        }
		
		function cl_mt_mata_string_matrix_styled::caption(|string scalar caption)
		{
			if ( caption != "" ) this.caption = caption
			else return(this.caption)
		}
		
		function cl_mt_mata_string_matrix_styled::top(|string colvector top)
		{
			if ( top != J(0,1,"") ) this.top = top
			else return(this.top)
		}
		
		function cl_mt_mata_string_matrix_styled::undertop(|string colvector undertop)
		{
			if ( undertop != J(0,1,"") ) this.undertop = undertop
			else return(this.undertop)
		}
		
		function cl_mt_mata_string_matrix_styled::bottom(|string colvector bottom)
		{
			if ( bottom != J(0,1,"") ) this.bottom = bottom
			else return(this.bottom)
		}
		
		function cl_mt_mata_string_matrix_styled::string_matrix(|string matrix strmat)
        {
            if ( strmat == J(0,0,"") ) return(this.string_matrix)
            else this.string_matrix = strmat
        }
        
		function cl_mt_mata_string_matrix_styled::headerheight(|real scalar headerheight)
		{
			if ( headerheight >= . ) return(this.headerheight)
			if ( ! any(headerheight :== (0,1,2)) ) {
				printf(`"{error: The value of "headerheight" must be 0 (no undertop), 1 or 2, not %f}\n"', headerheight)
				printf(`"{error:"headerheight" is set to 1}\n"')
				this.headerheight = 1
			} else this.headerheight = headerheight
		}
		
		function cl_mt_mata_string_matrix_styled::style(|string scalar style, real scalar headerheight)
		{
        	//When style is set, all other properties are reset
			if ( style != "" ) {
                if ( ! any(style :== ("smcl", "csv", "html", "htm", "latex", "tex", "md")) ) {
                    printf(`"{error:The value of "style" must be one of smcl, csv, html, latex or tex, or md. Not %s}\n"', style)
                    printf(`"{error:"style" is set to smcl}\n"')
                    this.style = "smcl"
                }
            	this.style = style
                this.reset()
                if ( headerheight != . ) this.headerheight(headerheight)
			} else return(this.style)
		}
		
		string colvector cl_mt_mata_string_matrix_styled::matrix_to_colvector(
			string matrix values,
			|string scalar first,
			string matrix strseparator, 
			string scalar last
			)
		{
			real scalar c, C
			string rowvector separated
			
			C = cols(values)
			strseparator = nhb_mt_resize_matrix(strseparator, 1, max((C-1, 1)))
			if ( C ) {
				separated = values[., 1]
				for(c=2; c <= C; c++) {
					separated = separated :+ strseparator[1, c-1] :+ values[., c]
				}
				return(first :+ separated :+ last)
			} else {
				return( J(1,1,"") )
			}
		}
		
		string matrix cl_mt_mata_string_matrix_styled::justified_matrix(|real rowvector columnwidth)
        /* For text-based prints */
		{
			real scalar C, R, r, c
			string matrix fmt, justified, strmat
			
            strmat = this.string_matrix()
            if ( columnwidth == J(1,0,.) ) columnwidth = colmax(strlen(strmat))
            
            R = rows(strmat)
            C = cols(strmat)
            columnwidth = nhb_mt_resize_matrix(columnwidth, R, C)
            this.justify = nhb_mt_resize_matrix(justify, R, C)
            fmt = "%" :+ this.justify :+ strofreal(columnwidth) :+ (stataversion() > 1400 ? "us" : "s")
            justified = J(R, C, "")
            for(c=1; c <= C; c++){
                for(r=1; r <= R; r++){
                    justified[r,c] = sprintf(fmt[r,c], strmat[r,c])
                }
            }
            return(justified)
		}
		
		string colvector cl_mt_mata_string_matrix_styled::to_smcl_lines()
		{
			real scalar C
			real rowvector cw
			
			C = cols(this.justified_matrix())
			cw = strlen(this.justified_matrix()[1,.])
			if ( this.top() == J(0,1,"") ) this.top( (sum(cw[1..C] :+ 2) - 2) * "{c -}" )
			if ( this.caption() != "" ) this.top( sprintf("{bf:%s}:", this.caption()) \ this.top() )
			if ( this.undertop() == J(0,1,"") ) this.undertop( (sum(cw[1..C] :+ 2) - 2) * "{c -}" )
			if ( this.bottom() == J(0,1,"") ) this.bottom( (sum(cw[1..C] :+ 2) - 2) * "{c -}" )
			return(this.matrix_to_colvector(this.justified_matrix(), "", "  ", ""))
		}

		string colvector cl_mt_mata_string_matrix_styled::to_csv_lines(|string scalar separator)
		{
			this.top("")
			this.undertop("")
			this.bottom("")
            if ( separator == "" ) separator = ";"
			return(this.matrix_to_colvector(this.justified_matrix(), "", separator, ""))
		}

		string colvector cl_mt_mata_string_matrix_styled::to_latex_lines()
		{
			// http://texblog.net/latex-archive/uncategorized/symbols/
			// backslash \ and ampersand & not included due to tables
            //DONE: headerheight
            //TODO: two blanks indention replaced with \quad 
            real scalar r
			string colvector lines
			string matrix justify, special_chars, strmat
            
            strmat = this.justified_matrix()

			special_chars = "#", "$", "%", "_", "{", "}", "^"
			special_chars = special_chars', "\" :+ special_chars'
            
			lines = this.matrix_to_colvector(strmat, "", " & ", " \\")
            lines = regexr(lines, "^(  )", "\quad ")
			for(r=1;r<=rows(special_chars);r++) {
				lines = subinstr(lines, special_chars[r,1], special_chars[r,2])
			}

            if ( this.top() == J(0,1,"") ) {
                this.top( "\begin{table}[h]" \ "\centering" )
                if ( this.caption() != "" ) this.top( this.top() \ sprintf("\caption{%s}", this.caption()) )
                justify = nhb_mt_resize_matrix(this.justify(), 1, cols(strmat))
                justify = editvalue(justify, "", "r")
                justify = editvalue(justify, "-", "l")
                justify = editvalue(justify, "~", "c")
                justify =  this.matrix_to_colvector(justify, "", "", "")
                this.top( this.top() \ sprintf("\begin{tabular}{%s}", justify) \ "\hline" \ "\hline" )
            }
			if ( this.undertop() == J(0,1,"") ) this.undertop( "\hline" )
			if ( this.bottom() == J(0,1,"") ) this.bottom( "\hline" \ "\hline" \ "\end{tabular}" \ "\end{table}" )
			return(lines)
		}

		string colvector cl_mt_mata_string_matrix_styled::to_html_lines()
		{
            //DONE: headerheight
            real scalar r, c, R, C, adjust
            string scalar id, htxt
			string colvector style, lines
			string matrix justify, strmat
            
            strmat = this.justified_matrix()
            R = rows(strmat)
            C = cols(strmat)
            justify = nhb_mt_resize_matrix(this.justify(), R, C)
            
            id = "tbl" + strofreal(
                    date(c("current_date"), "DMY") * 10e7 
                    + clock(c("current_time"), "hms") 
                    + hash1(strmat) 
                    + hash1(this.caption)
                    , "%18.0f")
            style = J(R, 1, "")
            for(r=1;r<=R;r++){
                if ( r <= this.headerheight() ) {
                    htxt = "tbody"
                    adjust = 0
                } else {
                    htxt = "tbody"
                    adjust = this.headerheight()
                }
                for(c=1;c<=C;c++){
                    if ( justify[r,c] == "" ) {
                        style[r] = style[r] + sprintf(`" #%s %s>tr:nth-child(%f)>td:nth-child(%f){text-align: right;}"',
                                                id, htxt, r - adjust, c)
                    } else if ( justify[r,c] == "-" ) {
                        style[r] = style[r] + sprintf(`" #%s %s>tr:nth-child(%f)>td:nth-child(%f){text-align: left;}"', 
                                                id, htxt, r - adjust, c)
                    } else if ( justify[r,c] == "~" ) {
                        style[r] = style[r] + sprintf(`" #%s %s>tr:nth-child(%f)>td:nth-child(%f){text-align: center;}"', 
                                                id, htxt, r - adjust, c)
                    }
                }
            }
			if ( this.headerheight() ) style[1..this.headerheight()] = subinstr(style[1..this.headerheight()], "td", "th")
            style = `"<style>"' \
                        style \
                        sprintf(`"#%s {width: 95%%; margin-left: auto; margin-right: auto;}"', id) \ 
                        sprintf(`"#%s tr:last-child>th{border-bottom: 2px solid black;}"', id) \ 
                        `"</style>"'
            if ( this.headerheight() ) { 		
                if ( this.top() == J(0,1,"") ) this.top( style \ sprintf(`"<table id=%s width="95%%">"', id) \ `"<thead>"' )
                if ( this.undertop() == J(0,1,"") ) this.undertop( `"</thead>"' \ `"<tbody>"' )
            } else {
                if ( this.top() == J(0,1,"") ) this.top( style \ sprintf(`"<table id=%s width="95%%">"', id)  \ `"<tbody>"')
            }
			if (this.caption() != "" ) this.top( this.top() \ sprintf("<caption>%s</caption>", this.caption()) )
			if ( this.bottom() == J(0,1,"") ) this.bottom( `"</tbody>"' \ "</table>" )

			lines = this.matrix_to_colvector(this.justified_matrix(), 
                "<tr><td>", "</td><td>", "</td></tr>")
            lines = regexr(lines, "^<tr><td>(  )", "<tr><td>&nbsp;&nbsp; ")
			if ( this.headerheight() ) lines[1..this.headerheight()] = subinstr(lines[1..this.headerheight()], "td>", "th>")
			return(lines)
		}

		string colvector cl_mt_mata_string_matrix_styled::to_md_lines()
		{
			real scalar r, c, R, C
            real rowvector cw
            string rowvector header
			string colvector lines, tmp
			string matrix M, original
			
			M = this.string_matrix()
            original = this.string_matrix()
			R = rows(M)
			C = cols(M)
		
			if ( this.headerheight() == 2 ) {	// Q&D: md do not show/handle coleq
                header = J(1,C,"")
                for(c=1;c<=C;c++) {
                    header[c] = M[1,c] != "" ? M[1,c] :+ ": " :+ M[2,c] : M[2,c]
                }
				this.headerheight(1)
				M = M[2..R, .]
				R = R - 1
                M[1,.] = header
			}
            this.string_matrix(M)
            M = this.justified_matrix(J(1,0,.))
            cw = strlen(M[1,.])
			// Left align strip columns
			M = nhb_mt_resize_matrix(nhb_sae_str_mult_matrix("  ", this.justify() :== ""), R, C) :+ M
			M = M :+ nhb_mt_resize_matrix(nhb_sae_str_mult_matrix("  ", this.justify() :== "-"), R, C)

			lines = this.matrix_to_colvector(M, "", 4*" ", "")
			tmp = lines[1]
            if ( !this.headerheight() ) tmp = tmp \ "" 
			for(r=2;r<=R;r++) {
				tmp = tmp \ lines[r] 
				if ( r < R ) tmp = tmp \ ""
			}
            this.string_matrix(original)

			lines = tmp
			if ( this.top() == J(0,1,"") ) {
            	if (this.headerheight() ) this.top( "" \ strlen(lines[1]) * "-" )
                else this.top( "" \ this.matrix_to_colvector((cw :+ 2) :* "-", "", 4*" ", "") )
            }
			if ( this.undertop() == J(0,1,"") ) this.undertop( this.matrix_to_colvector((cw :+ 2) :* "-", "", 4*" ", "") )
			if ( this.bottom() == J(0,1,"") ) {
            	if (this.headerheight() ) this.bottom( "" \ strlen(lines[1]) * "-" )
                else this.bottom( "" \ this.matrix_to_colvector((cw :+ 2) :* "-", "", 4*" ", "") )
            }
			if ( this.caption() != "" ) this.bottom( this.bottom() \ sprintf("Table: %s\n", this.caption()) )
            this.string_matrix(original)
			return(lines)
		}

		void cl_mt_mata_string_matrix_styled::print()
		{
			real scalar r
            string scalar lines
			
            lines = this.styled_lines()
			for(r=1;r<=rows(lines);r++){
				printf("%s\n", lines[r])
			}
		}

		string colvector cl_mt_mata_string_matrix_styled::styled_lines()
		{
			real scalar R, hh
			string colvector lines

			if ( this.style() == "" | this.style() == "smcl" ) {
				lines = this.to_smcl_lines()
			} else if ( this.style() == "csv" ) {
				lines = this.to_csv_lines()
			} else if ( this.style() == "html" | this.style() == "htm" ) {
				lines = this.to_html_lines()
			} else if ( this.style() == "latex" | this.style() == "tex" ) {
				lines = this.to_latex_lines()
			} else if ( this.style() == "md" ) {
				lines = this.to_md_lines()
			} else lines = J(0,1,"")
			R = rows(lines)
            hh = this.headerheight()
			if ( this.undertop != "" & hh ) {
				lines = lines[1..hh] \ this.undertop \ lines[hh+1..R]
			}
			if ( this.top != "" ) lines = top \ lines
			if ( this.bottom != "" ) lines = lines \ this.bottom
            return(lines)
		}

	
	function nhb_mt_format_real_matrix(	real matrix M, 
										|real matrix decimalwidth
										)
	{
		real scalar R, C
		real matrix integerwidth
		string matrix fmt
		
		R = rows(M)
		C = cols(M)
		
		integerwidth = J(R, C, max(strlen(strofreal(round(M)))))
		decimalwidth = nhb_mt_resize_matrix(decimalwidth, R, C)
		fmt = ("%" :+ strofreal(integerwidth + decimalwidth :+ 1) 
				:+ "." :+ strofreal(decimalwidth) :+ "f")
		return( strofreal(M, fmt) )
	}

    void nhb_msa_string_colvector_to_file(
        string scalar filename,
        string colvector lines,
        |real scalar overwrite
        )
    {
        real scalar rc, fh, r
        
        if ( fileexists(filename) & overwrite ) rc = _unlink(filename)
        fh = _fopen(filename, fileexists(filename) ? "a" : "w")
        if ( fh >= 0 ) {
            for(r=1;r<=rows(lines);r++) fput(fh, lines[r])
            fclose(fh)
        } else {
            printf("{error:fopen error %f}", fh)
        }
    }


	function nhb_mt_resize_matrix(matrix mat, real scalar R, C)
	{
		real scalar tmp
		matrix M
		
		M = mat
		if ( (tmp=cols(M)) < C ) {
			M = M, J(1,C-tmp,M[.,tmp])
		} else {
			M = M[.,1..C]
		}
		if ( (tmp=rows(M)) < R ) {
			M = M \ J(R-tmp,1,M[tmp,.])
		} else {
			M = M[1..R,.]
		}
		M = M[1..R, 1..C]
		return(M)
	}
    
	class cl_mt_mata_string_matrix_styled scalar nhb_mt_mata_string_matrix_styled(
		string matrix M,
		string scalar style,
		string matrix justify,
		|real scalar headerheight,	// must be 1 or 2
		string scalar caption,
		string scalar top, 
		string scalar undertop, 
		string scalar bottom,
		string scalar savefile,
		real scalar overwrite
		)
	{
		class cl_mt_mata_string_matrix_styled scalar sms
		
		sms.string_matrix(M)
        sms.style(style)
        sms.justify(justify)
		sms.headerheight(headerheight == . ? 1 : headerheight)
		if (caption != `""') sms.caption(caption)
		if (top != `""') sms.top(strtrim(top) != "" ? tokens(top)' : top)
		if (undertop != `""') sms.undertop(strtrim(undertop) != "" ? tokens(undertop)' : undertop)
		if (bottom != `""') sms.bottom(strtrim(bottom) != "" ? tokens(bottom)' : bottom)
        if ( savefile != `""' ) nhb_msa_string_colvector_to_file(savefile, sms.styled_lines(), overwrite)
        sms.print()
		return(sms)
	}
end


/*******************************************************************************
*** Stata api extension ********************************************************
*******************************************************************************/
mata:
	function nhb_sae_logstatacode(	string scalar statacode,
									| real scalar showcode, 
									real scalar addquietly)
	{
		if ( addquietly != 0 | addquietly == . ) statacode = "quietly " + statacode
		if ( !any(showcode :== (0, .)) ) printf("{cmd:. %s}\n", statacode)
		return(_stata(statacode))
	}

	function nhb_sae_num_scalar(string scalar scalarname)
	{
		real scalar value
		value = st_numscalar(scalarname)
		return( value != J(0, 0, .) ? value : . )
	} 
	
	class nhb_mt_labelmatrix scalar nhb_sae_stored_scalars(
			|string scalar rgx_fltr, 
			real scalar escalars,
			string scalar matrixname
			)
	{
		real scalar r, R
		real colvector values
		string scalar r_or_e
		string colvector status, names
		class nhb_mt_labelmatrix scalar lm
		
		r_or_e = ( escalars == 0 | escalars == . ) ? "r" : "e"
		names = st_dir(r_or_e + "()", "numscalar", "*")
		R = rows(names)
		status = J(R,1,"")
		for(r=1;r<=R;r++) status[r] = st_numscalar_hcat(sprintf("%s(%s)", r_or_e, names[r]))
		names = select(names, status :== "visible")
		R = rows(names)		
		if ( !R ) {
			names = "No scalars found"
			values = .
		} else {
			values = J(R,1,.)
			for(r=1; r<=R;r++) values[r] = nhb_sae_num_scalar(sprintf("%s(%s)", r_or_e, names[r]))
		}
		lm.values(values)
		lm.row_names(names)
		lm.column_names(sprintf("%s scalars", r_or_e))
		if ( rgx_fltr != "" ) lm = lm.regex_select(rgx_fltr)
		if ( matrixname != "" ) lm.to_matrix(matrixname)
		return(lm)
	}
	
	class nhb_mt_labelmatrix scalar nhb_sae_summary_row(string scalar variable, 
														string scalar statistics, 
														string scalar matrixname,
														string scalar str_if, 
														string scalar str_in, 
														real scalar ppct,
														real scalar N,
														real scalar smooth_width,
														real scalar hide,
														real scalar nolabel,
														real scalar showcode,
														real scalar addquietly
														)
	{
		string scalar stata_code, varlbl
		string vector stats
		real scalar rc, n, c, C, z, mean, se
		real vector values, tmp, sminmax
		real colvector svalues, pct_tiles
		class nhb_mt_labelmatrix scalar lm

		stats = tokens(subinstr(statistics, ",", " "))
		C = cols(stats)
		values = J(1,C,.)
		stata_code = sprintf("count %s %s", str_if, str_in)
		if ( !(rc=nhb_sae_logstatacode(stata_code, showcode, addquietly)) 
				& hide <= (n=nhb_sae_num_scalar("r(N)")) | !n ) {
			if ( st_isnumvar(variable) ) {
				z = invnormal((100 + ppct) / 200)
				stata_code = sprintf("summarize %s %s %s, detail", variable, str_if, str_in)
				if ( !(rc=nhb_sae_logstatacode(stata_code, showcode, addquietly)) ) {
					if ( smooth_width >= . ) smooth_width = 0
					svalues = st_data(., variable, nhb_sae_markrows(str_if, str_in))
					pct_tiles = nhb_mc_percentiles(svalues, 1::99, smooth_width)[.,2]
					sminmax = nhb_mc_smoothed_minmax(svalues, smooth_width)
					for(c=1;c<=C;c++) {
						if ( regexm(strtrim(strlower(stats[c])), "^[n|count]$") ) {
							values[c] = nhb_sae_num_scalar("r(N)")
						} else if ( regexm(strtrim(strlower(stats[c])), "^range$") ) {
							values[c] = sminmax[2] - sminmax[1]
						} else if ( regexm(strtrim(strlower(stats[c])), "^[var|variance]$") ) {
							values[c] = nhb_sae_num_scalar("r(Var)")
						} else if ( regexm(strtrim(strlower(stats[c])), "^cv$") ) {
							values[c] = nhb_sae_num_scalar("r(sd)") / nhb_sae_num_scalar("r(mean)")
						} else if ( regexm(strtrim(strlower(stats[c])), "^semean$") ) {
							values[c] = nhb_sae_num_scalar("r(sd)") / sqrt(nhb_sae_num_scalar("r(N)"))
						} else if ( regexm(strtrim(strlower(stats[c])), "^median$") ) {
							values[c] = pct_tiles[50]
						} else if ( regexm(strtrim(strlower(stats[c])), "^iqr$") ) {
							values[c] = pct_tiles[75] - pct_tiles[25]
						} else if ( regexm(strtrim(strlower(stats[c])), "^iqi$") ) {
							stats[c] = "iq 25%"
							values[c] = pct_tiles[25]
							if ( c == C ) {
								stats = stats, "iq 75%"
								values = values, pct_tiles[75]
							} else {
								stats = stats[1..c], "iq 75%", stats[c+1..C]
								values = values[1..c], pct_tiles[75], values[c+1..C]
								c++
								C++
							}
						} else if ( regexm(strtrim(strlower(stats[c])), "^idi$") ) {
							stats[c] = "idi 10%"
							values[c] = pct_tiles[90] - pct_tiles[10]
							if ( c == C ) {
								stats = stats, "idi 90%"
								values[c] = values, pct_tiles[90]
							} else {
								stats = stats[1..c], "idi 90%", stats[c+1..C]
								values = values[1..c], pct_tiles[90], values[c+1..C]
								c++
								C++
							}
						} else if ( regexm(strtrim(strlower(stats[c])), "^ci$|^ci\((.*)\)$") ) {
							stats[c] = sprintf("ci%2.0f%% lb", ppct)
							if ( regexs(0) != "ci" ) {
							} else {
								mean = nhb_sae_num_scalar("r(mean)")
								se = nhb_sae_num_scalar("r(sd)") / sqrt(nhb_sae_num_scalar("r(N)"))
							}
							values[c] = mean - z * se
							if ( c == C ) {
								stats = stats, sprintf("ci%2.0f%% ub", ppct)	
								values = values, nhb_sae_num_scalar("r(mean)") + z * se
							} else {
								stats = stats[1..c], sprintf("ci%2.0f%% ub", ppct), stats[c+1..C]
								values = values[1..c], nhb_sae_num_scalar("r(mean)") + z * se, values[c+1..C]
								c++
								C++
							}
						} else if ( regexm(strtrim(strlower(stats[c])), "^pi$") ) {
							stats[c] = sprintf("pi%2.0f%% lb", ppct)
							values[c] = nhb_sae_num_scalar("r(mean)") - z * nhb_sae_num_scalar("r(sd)")
							if ( c == C ) {
								stats = stats, sprintf("pi%2.0f%% ub", ppct)
								values = values, nhb_sae_num_scalar("r(mean)") + z * nhb_sae_num_scalar("r(sd)")
							} else {
								stats = stats[1..c], sprintf("pi%2.0f%% ub", ppct), stats[c+1..C]
								values = values[1..c], nhb_sae_num_scalar("r(mean)") + z * nhb_sae_num_scalar("r(sd)"), values[c+1..C]
								c++
								C++
							}
						} else if ( regexm(strtrim(strlower(stats[c])), "^missing$") ) {
							tmp = nhb_sae_variable_data(variable, str_if, str_in)
							values[c] = colsum(tmp :>= .)
						} else if ( regexm(strtrim(strlower(stats[c])), "^gmean$") ) {
							values[c] = exp(mean(log(nhb_sae_variable_data(variable, str_if, str_in))))
						} else if ( regexm(strtrim(strlower(stats[c])), "^gsd$") ) {
							values[c] = exp(sqrt(quadvariance(log(nhb_sae_variable_data(variable, str_if, str_in)))))
						} else if ( regexm(strtrim(strlower(stats[c])), "^gse$") ) {
							values[c] = exp(sqrt(quadvariance(log(nhb_sae_variable_data(variable, str_if, str_in)))/nhb_sae_num_scalar("r(N)")))
						} else if ( regexm(strtrim(strlower(stats[c])), "^unique$") ) {
							tmp = nhb_sae_variable_data(variable, str_if, str_in)
							tmp = select(tmp, tmp :< .)
							values[c] = rows(uniqrows(tmp))
						} else if ( regexm(strtrim(strlower(stats[c])), "^fraction$") ) {
							if ( N > 0 ) {
								values[c] = nhb_sae_num_scalar("r(N)") / N * 100
							} else {
								values[c] = 100
							}
						} else if ( regexm(strtrim(strlower(stats[c])), "^min$") ) {
							values[c] = sminmax[1]
						} else if ( regexm(strtrim(strlower(stats[c])), "^max$") ) {
							values[c] = sminmax[2]
						} else if ( regexm(strtrim(strlower(stats[c])), "^p([1-9][0-9]?)$") ) {
							values[c] = pct_tiles[strtoreal(regexs(1))]
						} else {
							values[c] = nhb_sae_num_scalar(sprintf("r(%s)", stats[c]))
						}
					}
				}
			} else { // Is string variable
				for(c=1;c<=C;c++) {
					values[c] = .
					if ( regexm(strtrim(strlower(stats[c])), "^[n|count]$") ) {
						tmp = nhb_sae_variable_data(variable, str_if, str_in)
						values[c] = rows(tmp) - colsum(tmp :== "")
					} else if ( regexm(strtrim(strlower(stats[c])), "^i[qd]i$") ) {
						stats[c] = sprintf("%s %f%%", 
											substr(stats[c],1,3), 
											substr(stats[c],1,3) == "iqi" ? 25 : 10)
						if ( c == C ) {
							stats = stats, sprintf("%s %f%%", 
													substr(stats[c],1,3), 
													substr(stats[c],1,3) == "iqi" ? 75 : 90)
							values = values, .
						} else {
							stats = stats[1..c], 
									sprintf("%s %f%%", substr(stats[c],1,3), 
									substr(stats[c],1,3) == "iqi" ? 75 : 90), 
									stats[c+1..C]
							values = values[1..c], ., values[c+1..C]
							c++
							C++
						}
					} else if ( regexm(strtrim(strlower(stats[c])), "^[pc]i$") ) {
						stats[c] = sprintf("%s%2.0f%% lb", substr(stats[c],1,2), ppct)
						if ( c == C ) {
							stats = stats, sprintf("%s%2.0f%% ub", substr(stats[c],1,2), ppct)
							values = values, .
						} else {
							stats = stats[1..c], sprintf("%s%2.0f%% ub", substr(stats[c],1,2), ppct), stats[c+1..C]
							values = values[1..c], ., values[c+1..C]
							c++
							C++
						}
					} else if ( regexm(strtrim(strlower(stats[c])), "^missing$") ) {
						tmp = nhb_sae_variable_data(variable, str_if, str_in)
						values[c] = colsum(tmp :== "")
					} else if ( regexm(strtrim(strlower(stats[c])), "^unique$") ) {
						tmp = nhb_sae_variable_data(variable, str_if, str_in)
						tmp = select(tmp, tmp :!= "")
						values[c] = rows(uniqrows(tmp))
					}
				}
			}
		} else {
			values = J(1,C,.h)
		}
		
		lm.values(values)
		if ( !nolabel ) {
			varlbl = abbrev(st_varlabel(variable), 32)
			varlbl = subinstr(varlbl, ".", "")
			varlbl = subinstr(varlbl, ":", "")
			if ( varlbl == "" ) varlbl = variable
		} else {
			varlbl = variable
		}
		lm.row_names(varlbl)
		lm.column_names(stats')
		if ( matrixname != "" ) lm.to_matrix(matrixname)
		return(lm)
	}
	
	function nhb_sae_markrows(string scalar str_if, string scalar str_in)
	{
		real scalar rc
		string scalar statacode, markname
	
		statacode = sprintf("generate %s = 1 %s %s", markname = st_tempname(), str_if, str_in)
		if ( rc=nhb_sae_logstatacode(statacode) ) _error(sprintf("nhb_sae_markrows: %s", statacode))
		statacode = sprintf("replace %s = 0 if missing(%s)", markname, markname)
		if ( rc=nhb_sae_logstatacode(statacode) ) _error(sprintf("nhb_sae_markrows: %s", statacode))
		return(markname)
	}
	
	function nhb_sae_variable_data(	string scalar variable, 
									string scalar str_if,
									|string scalar str_in)
	{
		colvector data
		string scalar slct
	
		slct = nhb_sae_markrows(str_if, str_in)
		if ( st_isnumvar(variable) ) {
			data = st_data(., variable, slct)
		} else if ( st_isstrvar(variable) ) {
			data = st_sdata(., variable, slct)
		} else {
			data = J(0,1,.)
		}
		st_dropvar(slct)
		return(data)
	}
	
	function nhb_sae_addvars(
			string rowvector names, 
			matrix values, 
			| real scalar returnnames,
            string scalar type,
            real scalar compress)
	{
		real scalar rc, obs
		real rowvector vars
		
		names = strtoname(strtrim(names))
        if ( (obs=rows(values) - st_nobs()) > 0 ) st_addobs(obs)
		if ( isreal(values) ) {
        	if ( type == "" ) type = "double"
			rc = _st_addvar(type, names)[1]
			if ( rc < 0 ) exit(_error(-rc))
				st_store(1::rows(values), names, values)
		} else {
			if ( stataversion() > 1300 ) {
                if ( type == "" ) type = "strL"
				rc = _st_addvar(type, names)[1]
			} else {
            	if ( type == "" ) type = "str244"
				rc = _st_addvar(type, names)[1]
			}
			if ( rc < 0 ) exit(_error(-rc))
				st_sstore(1::rows(values), names, values)
		}
		if (compress != 0) rc = nhb_sae_logstatacode("compress")
		if ( returnnames != 0 & returnnames != . ) return(names)
	}
	
	function nhb_sae_appendvars(string rowvector names, matrix values)
	{
		real scalar rc, c, R, C
		real rowvector vars
		real colvector slct, append
		
		if ( cols(names) == cols(values) ) {
			names = strtoname(strtrim(names))
			R = rows(values)
			C = cols(names)
			slct = _st_varindex(names) :< .
			append = st_nobs() :+ (1::R)
			st_addobs(R)
			if ( isreal(values) ) {
				for(c=1;c<=C;c++) {
					if ( !slct[c] ) vars = _st_addvar("double", (names[c]))
					if ( st_isnumvar(names[c]) ) st_store(append, (names[c]), values[.,c])
				}
			} else if ( isstring(values) ) {
				for(c=1;c<=C;c++) {
					if ( !slct[c] ) {
						if ( stataversion() > 1300 ) {
							rc = _st_addvar("strL", names)[1]
						} else {
							rc = _st_addvar("str244", names)[1]
						}
					}
					if ( st_isstrvar(names[c]) ) {
						st_sstore(append, (names[c]), values[.,c])
					} else {
						st_store(append, (names[c]), strofreal(values[.,c]))
					}
				}
			}
		}
	//return(names)
	}
	
	function nhb_sae_validate_variable(string scalar varname, real scalar is_categorical)
	{
		string scalar lblname
		
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

	real rowvector nhb_sae_unique_values(string scalar variable,
										| string scalar str_if, 
										string scalar str_in,
										real scalar drop_missings
										)
	{
		real rowvector levels
		string scalar if_in
		
		levels = J(1, 0, .)
		if ( _st_varindex(variable) < . ) {
			if ( st_isnumvar(variable) ) {
				if_in = nhb_sae_markrows(str_if, str_in)
				levels = uniqrows(st_data(., variable, if_in))'
			}
			if ( drop_missings ) levels = select(levels, levels :< .)
		}
		return(levels == J(0,0,.) ? J(1, 0, .) : levels)
	}

	string rowvector nhb_sae_labelsof(	string scalar variable, 
										| real rowvector levels, 
										string scalar str_if, 
										string scalar str_in,
										real scalar drop_missings
										)
	{
		string scalar vallblname
		string rowvector lbls 
		
		variable = strtrim(variable)
		if ( levels == J(1, 0, .) ) {	//No levels as argument
			levels = nhb_sae_unique_values(variable, str_if, str_in, drop_missings)
		}
		if ( levels == J(1, 0, .) ) {	//No non missing levels for variable
			lbls = J(1, 0, "")
		} else {						//levels non empty
			if ( (vallblname=st_varvaluelabel(variable)) != "" ) {
				lbls = st_vlmap(vallblname, levels)
				lbls = lbls + strofreal(levels) :* (lbls :=="")
			} else {
				lbls = strofreal(levels)
			}
		}
		return(lbls)
	}

	function nhb_sae_str_mult_matrix(string scalar str, real matrix factors)
	{
		real scalar r, c, R, C
		string vector out
		
		R = rows(factors)
		C = cols(factors)
		out = J(R, C, "")
		for(r=1; r <=R; r++) {
			for(c=1; c <=C; c++) {
				out[r,c] = factors[r,c] * str
			}
		}
		return(out)
	}
	
	function nhb_sae_subselect(slctvar, slctname, str_if, str_in)
	{
		string scalar mrk
		rowvector uniq
		colvector dta
		real scalar R
		real rowvector include
	
		mrk = nhb_sae_markrows(str_if, str_in)
		if ( st_isnumvar(slctvar) ) {
			uniq = uniqrows(st_data(., slctvar, mrk))'
			dta = st_data(.,slctvar)
		} else {
			uniq = uniqrows(st_sdata(., slctvar, mrk))'
			dta = st_sdata(.,slctvar)
		}
		st_dropvar(mrk)
		R = rows(dta)
		include = rowsum(dta :== J(R,1,uniq))
		nhb_sae_addvars(slctname, include)
	}

	real scalar nhb_sae_mata_rc(string scalar strmata)
	{
		stata(sprintf(`"capture mata: %s"', strmata))
		return(st_numscalar("c(rc)"))
	}
	
	string colvector nhb_sae_isnumvarvector(string colvector varnames)
	{
		real scalar r, R
		real colvector slct
		
		R = rows(varnames)
		slct = J (R,1,.)
		for(r=1;r<=R;r++) slct[r] = st_isnumvar(varnames[r])
		return(select(varnames, slct))
	}
    
    colvector nhb_sae_outliers(
        /*
            top outliers sorted descending by value counts (highest first)
            bottom outliers sorted ascending by value counts (lowest first)
        */
        string scalar vn,
        | real scalar slct,
        string scalar str_if,
        string scalar str_in
        )
    {
        real scalar R
    	real colvector values, uniqvalues
        
        if (slct >= . ) slct = 5
        values = nhb_sae_variable_data(vn, str_if, str_in)
        uniqvalues = select(uniqvalues=uniqrows(values), uniqvalues :< .)
        R = rows(uniqvalues)
        if (abs(slct) < R) {
            count = rowsum(J(R, 1, values') :== uniqvalues)
            if (slct > 0 ) return(sort((uniqvalues, count), 2)[R..(R-slct+1), 1])
            else return(sort((uniqvalues, count), 2)[1..(-slct), 1])
        } else return(.)
    }    
end


/*******************************************************************************
*** mata system api ************************************************************
*******************************************************************************/
mata:
	function nhb_msa_variable_description(|string scalar names)
	{
		real scalar r
		string vector nms, uval, ulbl
		string matrix vd
		class nhb_mt_labelmatrix scalar lm
		
		nms = ( names != "" ? tokens(names)' : st_varname(1..st_nvar())' )
		vd = J(rows(nms), 9, "")
		vd[.,1] = nms
		for(r=1; r<=rows(nms); r++){
			if ( _st_varindex(vd[r, 1]) < . ) {
				vd[r, 2] = strofreal(st_varindex(vd[r, 1]))
				vd[r, 3] = st_varlabel(vd[r, 1])
				vd[r, 4] = st_varvaluelabel(vd[r, 1])
				vd[r, 5] = st_varformat(vd[r, 1])
				if ( vd[r, 4] != "" & st_nobs() > 0 ) {		// Stata 12 do handle empty datasets here
					uval = strofreal(nhb_sae_unique_values(vd[r, 1]))
					ulbl = nhb_sae_labelsof(vd[r, 1])
					if ( uval != J(1,0,"") & ulbl != "" ) {
						vd[r, 6] = invtokens(uval :+ `" ""' :+ ulbl :+ `"""', " ")
					} else {
						vd[r, 6] = ""
					}
				}
				lm = nhb_sae_summary_row(vd[r, 1], "n unique missing", "", "", "", 95, 0, 0, 0, 0, 0, 1)
				vd[r, 7..9] = strofreal(lm.values())
			}
		}
		vd = ("Name", "Index", "Label", "Value Label Name", "Format", "Value Label Values", "n", "unique", "missing") \ vd
		return(vd)
	}

	function nhb_msa_oswalk(string scalar root, dirfilter, filefilter)
	{
		real scalar r, R
		string colvector files, dirs
		string matrix osw
		
		osw = J(0,2,"")
		dirs = dir(root, "dirs", dirfilter)
		R = rows(dirs)
		if ( R > 0 ) {
			for(r=1;r<=R;r++) {
				osw = osw \ nhb_msa_oswalk(	sprintf(`"%s/%s"', root, dirs[r]), 
									dirfilter, 
									filefilter)
			}
		}
		files = dir(root, "files", filefilter)
		if ( rows(files) > 0 ) osw = osw \ (J(rows(files), 1, root), files)
		for(r=1;r<=rows(osw);r++) {
			osw[r,1] = subinstr(osw[r,1], "\", "/")
			osw[r,1] = subinstr(osw[r,1], "//", "/")
		}
		return(osw)
	}
	
	function nhb_msa_file_size_kb(string scalar fname)
	// From filelist by Robert Picard
	// Also see: http://www.statalist.org/forums/forum/general-stata-discussion/general/1305580-creating-variable-to-record-filesize-of-dataset
	{
		real scalar fh, fsize, filepos
		
		fh = fopen(fname, "r")
		// go to the end of the file; returns negative error codes
		filepos = _fseek(fh, 0, 1)
		if (filepos >= 0) fsize = ftell(fh)
		fclose(fh)
		return(strofreal(fsize/1024, "%21.3f"))
	}

	string scalar nhb_msa_unab(string scalar varlist_fltr)
	{
		string scalar tmp0, out
		
		tmp0 = st_local("0")
		st_local("0", varlist_fltr)
		out = !_stata("syntax varlist") ? st_local("varlist") : ""
		st_local("0", tmp0)
		return(out)
	}
end


********************************************************************************
*** Mata calculations **********************************************************
********************************************************************************
mata:
	real colvector nhb_mc_smoothed_data(real colvector values,
										real scalar smooth_width)
	/***
	Order the values, smooth the values with an average of with smooth_width.
	Endpoints are set to missing.
	Returns the reordered smoothed values.
	***/
	{
		real scalar half
		real colvector r, R, idx, data, out
		
		if ( smooth_width == 0 ) return ( values )

		R = rows(values)
		smooth_width = (smooth_width=trunc(abs(smooth_width))) + !mod(smooth_width, 2)
		if ( smooth_width > R) return( J(R, 1, .) )

		half = trunc(smooth_width / 2)
		out = J(R, 1, .)
		idx = order(values, 1)
		data = values[idx]	//sorted
		for(r=half+1;r<=R-half;r++) out[r] = sum(data[(r-half)..(r+half)]) / smooth_width
		out[1..half] = J(half, 1, out[half+1])
		out[(R-half+1)..R] = J(half, 1, out[R-half])
		return( out[invorder(idx)] )
	}

	real rowvector nhb_mc_smoothed_minmax(	real colvector values,
											real scalar smooth_width)
	{
		real colvector smoothdata
		
		if ( smooth_width >= . ) smooth_width = 0
		smoothdata = nhb_mc_smoothed_data(values, smooth_width)
		return( (min(smoothdata), max(smoothdata)) )
	}
		
	real matrix nhb_mc_percentiles(	real colvector values, 
									real colvector pct,
									| real scalar smooth_width)
	/***
	source:	Stata [R] manual p. 287 (same method as as Stata command centile)

			Mood, A. M., and F. A. Graybill. 1963. 
			Introduction to the Theory of Statistics. 
			2nd ed. New York: McGraw–Hill p. 408
			
	If smooth_width is set, ie not missing or zero the dataset is smoothed 
	before percentiles are calculated.
	***/
	{
		real scalar r, R
		real colvector data

		if ( !all( (pct :> 0 :& pct :< 100)' ) ) return ( J(0, 0, .) )
		if ( smooth_width >= . ) smooth_width = 0
		
		data = select(values, values :< .)
		if ( data != J(0, 1, .) & data != J(0, 0, .) ) {
			r = trunc(R=(rows(data) + 1) / 100 :* pct)
			r = (r :== 0) :+ r
			R = (r :!= 0) :* R :+ (r :== 0) :* r
			data = nhb_mc_smoothed_data(data, smooth_width)		
			data = sort(data, 1)
			data = (data) \ data[rows(data)]
			return(pct, data[r :+ 1] :* (R - r) + data[r] :* (1 :- R + r))
		} else {
			return(pct, J(rows(pct), 1, .))
		}
	}
	
	class nhb_mc_splines
	{
		private:
			real rowvector knots
			void new()
			real vector positive()
		public:
			void add_knots()
			real matrix marginal_linear()
			real matrix restricted_cubic()
	}

		real vector nhb_mc_splines::positive(real vector v) 
		{
			return((abs(v) + v) :* 0.5)
		}
		
		void nhb_mc_splines::new()
		{
			this.knots = J(0,1,.)
		}

		void nhb_mc_splines::add_knots(real rowvector knots)
		{
			this.knots = sort(knots', 1)'	// knots are always ordered
		}

		real matrix nhb_mc_splines::marginal_linear(real colvector values)
		//linear before the first knot and/or after the final knot
		{
			real scalar c, R, C
			real matrix x

			R = rows(values)
			C = cols(this.knots)
			x = values
			for (c=1;c<=C;c++) x = x, positive(values :- this.knots[c])
			return(x)
		}

		real matrix nhb_mc_splines::restricted_cubic(real colvector values)
		//linear before the first knot and/or after the final knot
		{
			real scalar c, R, C
			real vector lambda
			real matrix u, x

			R = rows(values)
			C = cols(this.knots)
			u = J(R, 0, .)
			x = values
			for (c=1;c<=C;c++) u = u, positive(x :- this.knots[c]) :^ 3
			lambda = (this.knots[C] :- this.knots[1..C-2]) :/ (this.knots[C] - this.knots[C-1])
			for(c=1;c<=C-2; c++) {
				x = x, 	((u[.,c] - u[.,C-1] :* lambda[c] + u[.,C] :* (lambda[c] - 1)) 
							:/ (this.knots[C] - this.knots[1]) :^ 2)
			}
			return(x)
		}

		
	real matrix nhb_mc_predictions(	real matrix values, 
									real colvector betas, 
									real matrix variance, 
									|real scalar ci_p
									)
	{
		real scalar z
		real colvector pr, pr_sd, pr_lb, pr_ub
		
		ci_p = ci_p < . ? ci_p : 0.975
		z = invnormal(ci_p)
		pr = values * betas
		//https://www.statalist.org/forums/forum/general-stata-discussion/mata/1407049-how-can-i-calculate-only-the-diagonal-elements-of-a-matrix
		pr_sd = sqrt(rowsum(values :* (values * variance)))
		pr_lb = pr - z :* pr_sd
		pr_ub = pr + z :* pr_sd
		return(pr, pr_lb, pr_ub)
	}
	
	class nhb_mt_labelmatrix scalar nhb_mc_post_ci_table(
		| real scalar eform, 
		real scalar cip
		)
		/*
		Inspired by parmest. However results are saved in mata labelmatrix
		
		*/
	{
		real scalar df, zt
		real vector b, se_b, test, lb, ub, pv
		class nhb_mt_labelmatrix scalar out
	
		cip = cip == . ? 0.025 : (100 - cip) / 200
	
		b = st_matrix("e(b)")'
		se_b = sqrt(diagonal(st_matrix("e(V)")))
		test = b :/ se_b
		if ( (df = nhb_sae_num_scalar("e(df_r)")) != . ) 
		zt = invttail(df, cip)
		else zt = invnormal(1-cip)
		lb = b - zt :* se_b
		ub = b + zt :* se_b
		pv = 2 :* normal(-abs(b :/ se_b))
		if ( eform ) out.values( (exp((b, se_b, lb, ub)), pv) )
		else out.values( (b, se_b, lb, ub, pv) )
		out.row_equations(st_global("e(depvar)"))
		out.column_names((	"b", 
							"se(b)", 
							sprintf("Lower %f%% CI", 100-200*cip), 
							sprintf("Upper %f%% CI", 100-200*cip),
							"P value"
							)')
		out.row_names(st_matrixcolstripe("e(b)")[.,2])
		return( out )
	}
end


********************************************************************************
*** Functional programming *****************************************************
********************************************************************************
mata:
	transmorphic vector nhb_fp_map(
		pointer(transmorphic scalar function) f, 
		transmorphic vector vec) 
	{
		real scalar r, R
		transmorphic vector out
	
		R = length(vec)
		if (isstring((*f)(vec[1]))) out = J(R,1,"")
		else if (isreal((*f)(vec[1]))) out = J(R,1,.)
		else return(J(0,0,.))
		for(r=1;r<=R;r++) out[r] = (*f)(vec[r])
		return(out)
	}

	transmorphic vector nhb_fp_reduce(
		pointer(transmorphic scalar function) f, 
		transmorphic vector vec)
		{
		real scalar R
	
		R = length(vec)
		if (R == 1){
			return(vec[1])
		} else {
			return( (*f)(vec[1], nhb_fp_reduce(&(*f), vec[2::R])) )
		}
	}
end


********************************************************************************
*** Containers *****************************************************************
********************************************************************************
mata:
    class nhb_List {
        private:
			real scalar cursor
			transmorphic colvector lst
		public:
			void reset()
			string scalar type()
			transmorphic colvector content()
			void next_init()
			transmorphic scalar next()
			real scalar has_next()
			real scalar len()
			real find()
			transmorphic colvector apply()
			void append()
			void remove()
			real scalar is_empty()
			transmorphic colvector unique_values()
			real colvector frequency()
			transmorphic colvector union_unique()
			transmorphic colvector intersection_unique()
			transmorphic colvector less_unique()
    }
        
        void nhb_List::reset() {
			this.cursor = 0
			this.lst = J(0,1,.)
        }

		string scalar nhb_List::type() return(eltype(this.content())) 
	
        transmorphic colvector nhb_List::content() 
			return( !this.is_empty() ? this.lst : J(0,1,.) )

        void nhb_List::next_init()
        {
            this.cursor = 0
        }
        
        transmorphic scalar nhb_List::next()
			return( this.has_next() ? this.lst[++this.cursor] : . )
        
        real scalar nhb_List::has_next() 
			return( !this.is_empty() ? this.cursor < this.len() : 0 )
        
        real scalar nhb_List::len()
			return( rows(this.lst) )
        
        real nhb_List::find(value)
			return(  !this.is_empty() ? select((1::rows(this.lst)), this.lst :== value) : J(0,1,.) )
        
        transmorphic colvector nhb_List::apply(f)
			return( !this.is_empty() ? nhb_fp_map(&(*f), this.lst) : J(1,0,.))
        
        void nhb_List::append(transmorphic colvector value)
        {
            this.lst = this.is_empty() ? value : this.lst \ value
        }
        
        void nhb_List::remove(scalar value) {
            this.lst = select(this.lst, this.lst :!= value)
        }
        
        real scalar nhb_List::is_empty() return( !this.len() )

        transmorphic colvector nhb_List::unique_values() return( sort(uniqrows(this.lst), 1) )
        
        real colvector nhb_List::frequency(|colvector vals)
        {
			transmorphic colvector values
		
            values = args() ? vals : this.unique_values()
            return(rowsum(J(rows(values), 1, this.lst') :== values))
        }

        transmorphic colvector nhb_List::union_unique(colvector set_b) {
			transmorphic colvector a_unique, b_unique
			
            a_unique = sort(uniqrows(this.lst), 1)
            b_unique = sort(uniqrows(set_b), 1)
            return( sort(uniqrows(a_unique \ b_unique), 1) )
        }
        
        transmorphic colvector nhb_List::intersection_unique(colvector set_b) {
			real scalar a, A
			real colvector slct
			transmorphic colvector a_unique, b_unique
			
            a_unique = sort(uniqrows(this.lst), 1)
            b_unique = sort(uniqrows(set_b), 1)
            A = rows(a_unique)
            slct = J(A,1,.)
            for(a=1;a<=A;a++) slct[a] = anyof(b_unique, a_unique[a])
            return( select(a_unique, slct) )
        }
        
        transmorphic colvector nhb_List::less_unique(colvector set_b) {
			real scalar a, A
			real colvector slct
			transmorphic colvector a_unique, b_unique
			
            a_unique = sort(uniqrows(this.lst), 1)
            b_unique = sort(uniqrows(set_b), 1)
            A = rows(a_unique)
            slct = J(A,1,.)
            for(a=1;a<=A;a++) slct[a] = !anyof(b_unique, a_unique[a])
            return( select(a_unique, slct) )
        }
end


********************************************************************************
*** Mata Utility functions *****************************************************
********************************************************************************
mata:
    string rowvector nhb_muf_tokensplit(string scalar txt, string scalar delimiter)
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

    real scalar nhb_muf_xlcolumn_nbr(string scalar cname)
    {
        class nhb_List scalar lst
        real scalar lname, col_nbr
        
        if ( (lname = strlen(cname)) > 2 & lname > 0 ) _error("XL column name must have length 1 or 2")
        cname = strlower(cname)
        lst.append(tokens("a b c d e f g h i j k l m n o p q r s t u v w x y z")')
        if ( lname == 1 ) col_nbr = lst.find(cname)
        else col_nbr = 26 * lst.find(substr(cname,1,1)) + lst.find(substr(cname,2,1))
        return(col_nbr)
    }
end
