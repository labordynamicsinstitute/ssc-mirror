*! Part of package matrixtools v. 0.28
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2020-08-23 added
* 2020-06-29 created

version 13
mata:
	class xlsetup13
	{
		private:
			void set_xl()
			void new()
		protected:
			real scalar replacesheet, xl_is_set
			real vector start
			string scalar xlfile, sheet
			class xl scalar xl
		public:
			string scalar thisversion
			start(), sheet(), replacesheet()
			void insert_matrix()
			string rowvector stringset()
		virtual xlfile()
	}
	
		void xlsetup13::new()
		{
			this.thisversion = "xlsetup13"
			this.xlfile = "temporary toxl file.xls"
			this.sheet = "toxlSheet1"
			this.start = 1,1
			this.replacesheet = 0
		}
		
		function xlsetup13::xlfile(|string scalar xlfn)
		{
			if ( xlfn == "" ) return(this.xlfile)
			else {
				if ( pathsuffix(xlfn) == ".xls" ) this.xlfile = xlfn
				else this.xlfile = pathrmsuffix(xlfn) + ".xls"
			}
		}

		void xlsetup13::set_xl()
		{
			if ( fileexists(this.xlfile()) ) {
                this.xl.load_book(this.xlfile())
				if ( all(xl.get_sheets() :!= this.sheet()) ) {
					this.xl.add_sheet(this.sheet())
				} else {
					if ( this.replacesheet ) {
						xl.set_sheet(this.sheet())
						this.xl.clear_sheet(this.sheet())
					} else {
						_error(sprintf("Excel sheet |%s| is already in |%s|", 
										this.sheet(), this.xlfile()))
					}
				}
			} else this.xl.create_book(this.xlfile(), this.sheet())				
			this.xl_is_set = 1
		}

		function xlsetup13::start(|real vector start)
		{
			if ( start == J(1,0,.) ) return(this.start)
			else {
				if ( length(start) != 2 ) {
					_error("Start position must a real vector of length 2 specifying row and column number")
				}
				this.start = start
			}
		}

		function xlsetup13::sheet(|string scalar sheet, real scalar replacesheet)
		{
			if ( sheet == "" ) return( this.sheet )
			else this.sheet = sheet
			if ( replacesheet < . ) this.replacesheet = replacesheet != 0
		}

		function xlsetup13::replacesheet(|real scalar replacesheet)
		{
			if ( replacesheet == . ) return( this.replacesheet )
			else this.replacesheet = replacesheet != 0
		}

		void xlsetup13::insert_matrix(string matrix strmat, |real scalar replacesheet)
		{
			if ( replacesheet != . ) this.replacesheet = replacesheet != 0
			if ( this.xl_is_set ) {
            	this.set_xl()
                this.xl.put_string(this.start[1], this.start[2], strmat)
                this.xl.close_book()
            }
		}

		string rowvector xlsetup13::stringset(string scalar parsetxt)
        {
            transmorphic t
            real scalar replace, c, C
            real rowvector start
            string rowvector lst, rest13
            
            t = tokeninit(",", "", (`"()"', `"[]"'))
            tokenset(t, parsetxt)
            lst = strtrim(tokengetall(t))
            C = cols(lst)
            if ( C >= 2 ) {
                this.xlfile(lst[1])
                replace =  C >= 3 ? lst[3] == "replace" : 0 
                this.sheet(lst[2], replace)
                c = 2 + replace
            }
            start = 1,1
            if ( C > c + 1 ) {
            	start = strtoreal(lst[c+1..c+2])
                if ( all(start :< (.,.)) ) c = c + 2
                else start = 1,1
            }
            this.start(start)
            rest13 = J(1, 1, "")
            if ( C > c ) {
            	c = c + 1
                c = c + ( lst[c] == "" )
                rest13 = lst[c..C]
            }
            return(rest13)
        }
end
