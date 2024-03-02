*! Part of package matrixtools v. 0.31
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2020-08-23 added
* 2020-06-29 created

version 14
mata:
	class xlsetup14 extends xlsetup13
	{
		private:
			real rowvector cw
			void set_columnwidths()
		public:
			void new(), insert_matrix()
			string rowvector stringset()
			xlfile(), columnwidths()
			void set_alignments()
	}

		void xlsetup14::new()
		{
			this.thisversion = "xlsetup14"
			this.xlfile = "temporary toxl file.xlsx"
			this.cw = J(1, 2, .)
		}
	
		function xlsetup14::xlfile(|string scalar xlfn)
		{
			if ( xlfn == "" ) return(this.xlfile)
			else {
				if ( pathsuffix(xlfn) == ".xlsx" ) this.xlfile = xlfn
				else this.xlfile = pathrmsuffix(xlfn) + ".xlsx"
			}
		}
		
		function xlsetup14::columnwidths(|real rowvector colwidths)
		{
		    if ( colwidths == J(1,0,.) ) return(this.cw)
			else this.cw = colwidths
		}
		
		void xlsetup14::set_columnwidths(real scalar firstcol, real rowvector colwidths)
		{
			real scalar c
			for(c=0; c < cols(colwidths); c++) {
				if (colwidths[c+1] < . & colwidths[c+1] > 0) {
					this.xl.set_column_width(firstcol + c, firstcol + c, colwidths[c+1])
				}
			}
		}
		
		void xlsetup14::set_alignments(
			string scalar alignment, 
			real vector lefttop, 
			real vector rightbottom,
			real scalar relative)
		{
      string rowvector al_types
      
			al_types = "left", "center", "right", "fill", "justify", "merge", "distributed"
			if ( relative ) {
				lefttop = this.start() + lefttop
				rightbottom = this.start() + rightbottom
			}
			this.xl.set_horizontal_align(
				(lefttop[1], rightbottom[1]), 
				(lefttop[2], rightbottom[2]), 
				alignment)
		}
	
		string rowvector xlsetup14::stringset(string scalar parsetxt)
		{
            real scalar C
			string rowvector rest14
			string vector strcw
			
			rest14 = super.stringset(parsetxt)
            C = cols(rest14)
			if ( rest14 != J(1, 1, "") ) {
				if ( regexm(rest14[1], `"\(([0-9 ,.]+)\)$"') ) {
					this.columnwidths(strtoreal(select(strcw = strtrim(tokens(regexs(1), ","))', strcw :!= ","))')
				} else {
					printf(`"%s Error help:\n"', this.thisversion)
					printf(`"Optional column widths must be a vector.\n\n"')
					_error(sprintf(`"ERROR: "%s" can not be parsed!"', rest14[1]))
				} 
			}
            rest14 =  C > 1 ? rest14[2..C] : J(1, 1, "")
			return(rest14)
		}

		void xlsetup14::insert_matrix(string matrix strmat, |real scalar replacesheet)
		{
			real vector cw
			
			super.insert_matrix(strmat, replacesheet)
			cw = nhb_mt_resize_matrix(this.cw, 1, cols(strmat))
			this.set_columnwidths(this.start()[2], cw)	
		}
end
