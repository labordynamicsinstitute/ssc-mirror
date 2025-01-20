
program define open2
    version 8.0

    syntax [anything] [using/] [, cd]

    * 获取操作系统信息
    local os `c(os)'
    di as text "Step 1: Detecting operating system: `os'"

    * Windows 系统处理逻辑
    if "`os'" == "Windows" {
        di as text "Step 2: Detected Windows system."
        if "`using'" ~= "" {
            di as text "Step 3: Opening file or application: `using'"
            winexec cmd /c start "" "`using'"
        } 
        else {
            if "`cd'" == "cd" {
                di as text "Step 3: Changing directory to current path and opening it."
                winexec cmd /c explorer "`c(pwd)'"
            } 
            else {
                di as text "Step 3: Executing command: `anything'"
                cap winexec `anything'
                if _rc == 193 {
                    di as text "Step 4: Command failed. Trying alternative method."
                    winexec cmd /c start "" "`anything'"
                }
                if _rc == 601 {
                    di as text "Step 4: Command not found. Make sure it is typed correctly."
                }
            }
        }
    } 

    * macOS 系统处理逻辑
    else if "`os'" == "MacOSX" {
        di as text "Step 2: Detected macOS system."
        if "`using'" ~= "" {
            di as text "Step 3: Opening file or application: `using'"
            shell open "`using'"
        } 
        else {
            if "`cd'" == "cd" {
                di as text "Step 3: Changing directory to current path and opening it."
                shell open "`c(pwd)'"
            } 
            else {
                di as text "Step 3: Executing command: `anything'"
                shell open "`anything'"
            }
        }
    } 

    * 非 Windows/macOS 系统
    else {
        di as text "Step 2: Unsupported operating system: `os'"
        if "`using'" ~= "" {
            di as text "Step 3: Attempting to execute command: `using'"
            shell "`using'"
        } 
        else {
            di as text "Step 3: Attempting to execute command: `anything'"
            shell "`anything'"
        }
    }

    di as text "Step 4: Process completed successfully."
end
