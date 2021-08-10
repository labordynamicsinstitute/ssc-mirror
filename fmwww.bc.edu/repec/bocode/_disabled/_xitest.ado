program define _xitest
	version 8
	syntax , vars(string asis) dialog(name) tab(name) control(name)

* check for i.vars	
	local i = index("`vars'", "i.") 
	
* use the class system to set the value
	if `i' > 0 {
		.`dialog'_dlg.`tab'.`control'.seton
	}
	else {
		.`dialog'_dlg.`tab'.`control'.setoff	
	}
end
/* 
	1) `dialog' is the name of the calling dialog 
	     (note that _dlg must be appended 
	      to identify the class item)
	2) `tab' is the name of the tab where control is found
	3) `control' is the name of the hidden control
	4) seton and setoff is what to do to `control'
*/
