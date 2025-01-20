
program define open
    version 8.0

    * 获取当前工作路径
    local current_path `"`c(pwd)'"'

    * 打开当前工作路径的文件夹
    winexec cmd /c start `current_path'

    * 将当前工作路径复制到剪贴板
    winexec cmd /c "echo `current_path' | clip"

    * 在结果窗口中以蓝色超链接形式显示当前路径
    di as text "Current working directory: "
    di `"{browse `"`current_path'"'}"'

    * 将当前路径完整显示到屏幕上
    di as text "Full path: `current_path'"
	
	dis as text "Current working directory is on clipboard,Press Ctrl+V  to paste"	

end
