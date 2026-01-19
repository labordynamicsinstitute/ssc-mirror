*! timeleft CFBaum 6may2025
prog timeleft
version 12
loc cdate=date(c(current_date),"DMY")
loc hesgone=date("20 Jan 2029","DMY")
loc until=`hesgone'-`cdate'
loc rem = `until'
if `until' >= 1000 {
// deal with <1100
	loc rest = string(`until'-1000)
	loc rem = "1,0"+"`rest'"
}
di _n _n _col(30) "ONLY" _n _col(27) "`rem' DAYS" _n _col(29) "TO GO" _n _n
end
