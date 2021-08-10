version 13
mata:
	void __basetable_to_xl(class basetable scalar tbl, string scalar xl_txt)
	{
		class xl scalar xl
		string vector x_split
		string scalar xlbookname, xlsheetname, suffix, path, fn
		real scalar N, sheetreplace, rowpos, colpos
		
		x_split = strtrim(tokensplit(xl_txt, ","))
		N = length(x_split)
		if ( N > 1 ) { 
			xlbookname = x_split[1]
			xlsheetname = x_split[2]
		} else {
			_error(`"There must be at least an excel file and and a sheet separated with a comma as argument to toxl"')
		}
		rowpos = 1
		colpos = 1
		if ( N > 3 ) { 
			rowpos = strtoreal(x_split[3])
			colpos = strtoreal(x_split[4])
		}
		sheetreplace = 0
		if ( any(N :== (3, 5)) ) {
			if ( regexm(x_split[N], "replace") ) { 
				sheetreplace = 1
			} else {
				_error(`"Last excel option must be "replace""')
			}
		}
		if ( !regexm(xlbookname, "(\.xls|\.xlsx)$") ) {
			_error(sprintf("Excel file |%s| must end with .xls or .xlsx", xlbookname))
		}
		
		xl = xl()
		if ( fileexists(xlbookname) ) {
			xl.load_book(xlbookname)
			if ( all(xl.get_sheets() :!= xlsheetname) ) {
				xl.add_sheet(xlsheetname)
			} else {
				if ( sheetreplace ) {
					//xl.set_sheet(xlsheetname)
					xl.clear_sheet(xlsheetname)
				} else {
					_error(sprintf("Excel sheet |%s| is already in |%s|", 
									xlsheetname, xlbookname))
				}
			}
		} else {
			pathsplit(xlbookname, path, fn)
			if ( direxists(path) ) {
				xl.create_book(xlbookname, xlsheetname)
			} else {
				_error(sprintf("Path |%s| do not exist", path))
			}
		}
		xl.put_string(rowpos, colpos, tbl.output)
	}
end
