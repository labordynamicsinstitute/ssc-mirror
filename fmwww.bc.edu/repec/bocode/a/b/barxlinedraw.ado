*!  barxlinedraw.ado 	Version 1.0		RL Kaufman 	09/28/2016

***  	1.0 Add vertical reference lines(dividers) to bar charts. Called by BARYHAT.ADO.  Writes code to file & then runs it
***	
****		BARTYPE = mod1 (1 mod) barby (2 mods) single (2 mods but 1 chart per 'page'	)  dual (like mod1 but solid line, if 2 mods use mstp1 input from mstp2 and mstp input as 1 1)
***			GRNAME = graph name		 MSTP# = # of categories in M1 or M2 (for single set MSTP2 to 1)

program barxlinedraw, rclass
version 14.2
args bartype grname mstp1 mstp2
      
tempfile barx hold

file open barxgrec using `barx' , write replace text

file write barxgrec "StataFileTM:00001:01100:GREC:                          :" _n
file write barxgrec "00004:00004:00001:" _n
file write barxgrec "*! classname: bygraph_g" _n
file write barxgrec "*! family: by" _n
file write barxgrec "*! date: 19 Sep 2016" _n
file write barxgrec "*! time: 18:28:29" _n
file write barxgrec "*! graph_scheme: s1mono" _n
file write barxgrec "*! naturallywhite: 1" _n
file write barxgrec "*! end" _n _n
file write barxgrec "// File created by Graph Editor Recorder." _n
file write barxgrec "// Edit only if you know what you are doing." _n

loc nline=`mstp1'+1

forvalues m2=1/`mstp2' {
	forvalues m1=1/`nline' {
	
		if "`bartype'" == "barby" {
		
			file write barxgrec ///
				".plotregion1.plotregion1[`m2'].declare_xyline .gridline_g.new `=(`m1'-1)*100/`mstp1'', ordinate(x) plotregion(\`.plotregion1.plotregion1[`m2'].objkey') style(default)" 	_n
			file write barxgrec ///
				".plotregion1.plotregion1[`m2']._xylines_new = `m1'" 	_n
			file write barxgrec ///
				".plotregion1.plotregion1[`m2']._xylines_rec = `m1'" 	_n
			file write barxgrec "// bar region edits" _n _n
			
			file write barxgrec ///
				".plotregion1.plotregion1[`m2']._xylines[`m1'].style.editstyle linestyle(width(thin)) editcopy" _n
			file write barxgrec "// line[`m1'] (x) width" _n _n

			file write barxgrec ///
				".plotregion1.plotregion1[`m2']._xylines[`m1'].style.editstyle linestyle(color(gs7)) editcopy" _n		
			file write barxgrec "// line[`m1'] (x) color" _n _n
			
			file write barxgrec ///
				".plotregion1.plotregion1[`m2']._xylines[`m1'].style.editstyle linestyle(pattern(vshortdash)) editcopy" _n		
			file write barxgrec "// line[3] (`m1') pattern" _n _n
		}
		if "`bartype'" == "mod1" | "`bartype'" == "dual" {
		
			file write barxgrec ///
				".plotregion1.declare_xyline .gridline_g.new `=(`m1'-1)*100/`mstp1'', ordinate(x) plotregion(\`.plotregion1.objkey') style(default)" 	_n
			file write barxgrec ///
				".plotregion1._xylines_new = `m1'" 	_n
			file write barxgrec ///
				".plotregion1._xylines_rec = `m1'" 	_n
			file write barxgrec "// bar region edits" _n _n
			
			file write barxgrec ///
				".plotregion1._xylines[`m1'].style.editstyle linestyle(width(thin)) editcopy" _n
			file write barxgrec "// line[`m1'] (x) width" _n _n

			file write barxgrec ///
				".plotregion1._xylines[`m1'].style.editstyle linestyle(color(gs7)) editcopy" _n		
			file write barxgrec "// line[`m1'] (x) color" _n _n
			
			if "`bartype'" == "mod1" {
			
				file write barxgrec ///
					".plotregion1._xylines[`m1'].style.editstyle linestyle(pattern(vshortdash)) editcopy" _n		
				file write barxgrec "// line[3] (`m1') pattern" _n _n
			}
		}
		if "`bartype'" == "single" {
		
			file write barxgrec ///
				".plotregion1.plotregion1.declare_xyline .gridline_g.new `=(`m1'-1)*100/`mstp1'', ordinate(x) plotregion(\`.plotregion1.plotregion1.objkey') style(default)" 	_n
			file write barxgrec ///
				".plotregion1.plotregion1._xylines_new = `m1'" 	_n
			file write barxgrec ///
				".plotregion1.plotregion1._xylines_rec = `m1'" 	_n
			file write barxgrec "// bar region edits" _n _n
			
			file write barxgrec ///
				".plotregion1.plotregion1._xylines[`m1'].style.editstyle linestyle(width(thin)) editcopy" _n
			file write barxgrec "// line[`m1'] (x) width" _n _n

			file write barxgrec ///
				".plotregion1.plotregion1._xylines[`m1'].style.editstyle linestyle(color(gs7)) editcopy" _n		
			file write barxgrec "// line[`m1'] (x) color" _n _n
			
			file write barxgrec ///
				".plotregion1.plotregion1._xylines[`m1'].style.editstyle linestyle(pattern(vshortdash)) editcopy" _n		
			file write barxgrec "// line[3] (`m1') pattern" _n _n
		}

	}
}		
file write barxgrec "//  <end>" _n 
file close barxgrec

graph play `barx'
graph save `grname' `hold' , replace
end
