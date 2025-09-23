cd "E:\益友学术\鼎园会计98期\data\企业投资效率原始数据"
global path "E:\益友学术\鼎园会计98期\data\企业投资效率原始数据"
* Basic usage:
efficiency, folderpath($path)

* With custom sheet name and file prefix:
efficiency, folderpath($path) sheetname("Sheet1") prefix("d")

* Save results to file:
efficiency, folderpath($path) replace  /// 		
	savepath("E:\益友学术\鼎园会计98期\report\efficiency\results.dta") 

