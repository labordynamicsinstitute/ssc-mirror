*! 29jan2016
* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).
program projdo 
version 11.1

mata: DoIt()
end

version 11
mata:

void DoIt() { //>>def func
	class recentle_proj scalar prj
	
	scmd=subcmdl(main=st_local("0"),("edit","run"))
	if (scmd=="edit") prj.s_edit(main)
	else if (scmd=="run") prj.s_run(main)
	}
end
