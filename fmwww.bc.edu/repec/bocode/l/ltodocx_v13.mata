*! Part of package matrixtools v. 0.31
*! Support: Niels Henrik Bruun, niels.henrik.bruun@gmail.com
* 2024-02-22 created
*mata mata clear
version 13
mata:
	class mata_string_matrix2docx
	{
		private:
			void new()
		protected:
			real scalar handle, repl
			string scalar docxfile
		public:	
			handle()
			replace()
			real scalar insert_matrix()
			void close(), stringset()
	}
		void mata_string_matrix2docx::new()
		{
			this.docxfile = ""
			this.repl = 0
			this.handle = .
		}
	
		void mata_string_matrix2docx::close()
		{
			real scalar rc
			
			if ( this.repl ) unlink(this.docxfile)
			if ( fileexists(this.docxfile) ) _error(sprintf(`"File "%s" can not be replaced... \n"', this.docxfile))
			rc = _docx_save(this.handle, this.docxfile, 0)
			rc = _docx_close(this.handle)
			if ( fileexists(this.docxfile) ) printf(`"Table saved in "%s"... \n"', this.docxfile)
		}

		function mata_string_matrix2docx::replace(|real scalar repl)
		{
			if ( repl == "" ) return(this.repl)
			else this.repl = repl != 0
		}
		
		function mata_string_matrix2docx::handle(|string scalar docxfile)
		{
			if ( docxfile == "" ) return(this.docxfile)
			else {
				if ( pathsuffix(docxfile) == ".docx" ) this.docxfile = docxfile
				else this.docxfile = pathrmsuffix(docxfile) + ".docx"
				this.handle = _docx_new()
			}
		}

		real scalar mata_string_matrix2docx::insert_matrix(string matrix strmat, |string scalar comment)
		{
			real scalar tbl_id
			
			if ( this.handle != . ) {
				if ( comment != "" ) tbl_id = _docx_paragraph_new(this.handle, comment)
				tbl_id = _docx_add_mata(this.handle, strmat, "")
				return(tbl_id)
			} else {
				_error("Handle is not set")
			}
		}

		void mata_string_matrix2docx::stringset(string scalar parsetxt)
        {
            transmorphic t
            real scalar C
            string rowvector lst
            
						if ( parsetxt == "" ) _error("No text to parse")
            t = tokeninit(",")
            tokenset(t, parsetxt)
            lst = strtrim(tokengetall(t))
            C = cols(lst)
						if ( C < 3 ) {
							this.handle(lst[1])
							if ( C == 2 ) this.replace(regexm(lst[2], "replace"))
						} else _error("Text to parse must be a docx filename and optionally comma replace")
        }
				
				
	void msm2d(string scalar todocx, string matrix msm, string scalar comment)
	{
		class mata_string_matrix2docx scalar msm2d
		real scalar tbl_id
		
		msm2d.stringset(todocx)
		tbl_id = msm2d.insert_matrix(msm, comment)
		msm2d.close()
	}
end
