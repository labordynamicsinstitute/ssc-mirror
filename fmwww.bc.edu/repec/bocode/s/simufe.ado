
/* Examples 

simufe
simufe, n(2) rho(0) seed(23579)       // dummy variable 
simufe, n(3) rho(-1) t(500)
simufe, n(20) rho(0)
simufe, n(20) rho(-2)
simufe, n(20) rho(-1) t(50) gap(0)   // no fixed effects
simufe, n(30) rho(-0.8) sigmae(0.5) t(40)  
*/

*! version 1.0  2025/01/08
*! Yujun Lian, arlionn@163.com

* ~~~~ todo ~~~~
* 1. DGP , 自动生成用于描述数据生成过程的 LaTeX 公式和 Markdown 文本
* 2. plotopt, 自动接受 -scatterfit- 和 -twoway- 命令的选项

cap program drop simufe
program define simufe
    version 17

    syntax [,                  ///
             n(integer 5)      ///
             t(integer 20)     ///
             Rho(real -1)      ///
             Gap(real 5)       ///
             Betax(real 0.5)   ///
             Sigmax(real 2)    ///
             SIGMAE(real 1)    ///
             SEED(integer 135) ///
             NOPlot            ///
             Onefit            ///
             SAVing(string)    ///
           ]

qui{        
    * 设置随机种子
    set seed `seed'

    * 清空当前数据
    clear

    * 生成面板数据
    set obs `n'
    gen id = _n
    gen ai = id * `gap'
    expand `t'

    * 生成时间变量
    bysort id: gen t = _n

    * 生成解释变量 x
    gen u_x = rnormal(0, `sigmax')
    gen x = `rho' * ai + u_x
    qui sum x
    replace x = x + int(abs(r(min)))

    * 生成误差项
    gen e = rnormal(0, `sigmae')

    * 生成被解释变量 y
    gen y = ai + `betax' * x + e
}

    * 保存数据（如果指定了 saving 选项）
    if `"`saving'"' != "" {
        save `saving', replace
    }

    * 绘制图形（如果没有指定 noplot 选项）
    if "`noplot'" == "" {
        if "`onefit'" != "" {
            scatterfit y x, by(id) opts(legend(off)) onefit 
        }
        else {
            scatterfit y x, by(id) opts(legend(off))
        }
    }    
    
end

