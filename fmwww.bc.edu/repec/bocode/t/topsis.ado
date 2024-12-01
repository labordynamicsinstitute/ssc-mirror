program define topsis, rclass  
    version 16
    syntax [, positive(varlist) negative(varlist) topsis]

    * Step 1: Process positive and negative indicators/处理正向和负向指标 

    local positiveVar ""
    local negativeVar ""

    if "`positive'" != "" {
        local positiveVar `positive'
    }

    if "`negative'" != "" {
        local negativeVar `negative'
    }

    local allVarList ""
    if "`positiveVar'" != "" {
        local allVarList "`allVarList' `positiveVar'"
    }
    if "`negativeVar'" != "" {
        local allVarList "`allVarList' `negativeVar'"
    }

    if "`allVarList'" == "" {
        di "错误：必须至少输入正向或负向指标中的一种。"
        exit 198
    }

    * Step 2: Data normalization/数据标准化处理
    if "`positiveVar'" != "" {
        foreach i of local positiveVar {
            qui sum `i'
            if (r(max) == r(min)) {
                gen x_`i' = 0.5
            }
            else {
                gen x_`i' = (`i' - r(min)) / (r(max) - r(min))
            }
            replace x_`i' = 0.0001 if x_`i' == 0
        }
    }

    if "`negativeVar'" != "" {
        foreach i of local negativeVar {
            qui sum `i'
            if (r(max) == r(min)) {
                gen x_`i' = 0.5
            }
            else {
                gen x_`i' = (r(max) - `i') / (r(max) - r(min))
            }
            replace x_`i' = 0.0001 if x_`i' == 0
        }
    }

    * Step 3: Calculate the proportion of each indicator
    foreach i of local allVarList {
        egen `i'_sum = sum(x_`i')
        gen y_`i' = x_`i' / `i'_sum
    }

    * Get the total number of variables获取总变量个数
    local num_vars : word count `allVarList'

    * Step 4: Calculate the information entropy of each indicator步骤4：计算各指标的信息熵
    gen n = _N
    foreach i of local allVarList {
        gen y_lny_`i' = y_`i' * ln(y_`i')
        replace y_lny_`i' = 0 if y_`i' == 0
    }

    * Summation step求和步骤
    foreach i of local allVarList {
        egen y_lny_`i'_sum = sum(y_lny_`i')
    }

    * Step 5: Calculate entropy and redundancy步骤5：计算熵值和冗余度
    matrix E = J(1, `num_vars', .)
    matrix D = J(1, `num_vars', .)
    matrix W = J(1, `num_vars', .)

    local idx = 1
    foreach i of local allVarList {
        * Step 5.1: Generate the entropy variable for each indicator/Step
        gen E_`i' = -1 / ln(n) * y_lny_`i'_sum

        * Step 5.2: Obtain the value of entropy and store it in a local macro
        quietly summarize E_`i'
        local E_value = r(mean)

        * Step 5.3: Store the entropy value in matrix E
        matrix E[1, `idx'] = `E_value'

        * Step 5.4: Calculate redundancy and store it
        gen d_`i' = 1 - `E_value'
        quietly summarize d_`i'
        local D_value = r(mean)

        matrix D[1, `idx'] = `D_value'

        local idx = `idx' + 1
    }

    * Step 6: Calculate the weight of each indicator/计算每个指标的权重
    egen d_sum = rowtotal(d_*)
    local idx = 1
    foreach i of local allVarList {
        gen W_`i' = d_`i' / d_sum
        quietly summarize W_`i'
        local W_value = r(mean)

        matrix W[1, `idx'] = `W_value'

        local idx = `idx' + 1
    }

    * Step 7: Calculate the comprehensive score (Entropy Method)/计算综合得分（熵值法）
    foreach i of local allVarList {
        gen Score_`i' = x_`i' * W_`i'
    }
    egen Score = rowtotal(Score_*)

    * Step 8: TOPSIS Calculation (Optional)
    if "`topsis'" != "" {
		*Step 8.1: Calculate the weighted normalized decision matrix
        foreach i of local allVarList {
            gen A_`i' = y_`i' * W_`i'
        }
        
		* Step 8.2: Calculate the distance to the ideal solution
        foreach i of local allVarList {
            qui sum A_`i'
            gen a1_`i' = (A_`i' - r(max))^2
            replace a1_`i' = 0.00001 if a1_`i' == 0
            
            gen a2_`i' = (A_`i' - r(min))^2
            replace a2_`i' = 0.00001 if a2_`i' == 0
        }
        
		* Step 8.3: Calculate the distances D1 and D2
        egen AAA = rowtotal(a1_*)
        gen D1 = sqrt(AAA)
        
        egen BBB = rowtotal(a2_*)
        gen D2 = sqrt(BBB)
        
		* Step 8.4: Calculate the TOPSIS comprehensive score
        gen Score1 = D2 / (D1 + D2)
    }

    *  Display Results - Show entropy, redundancy, and weights if the TOPSIS option is not selected
	*  Display 结果 - 如果没有选择 topsis 选项时显示熵值、冗余度和权重
    if "`topsis'" == "" {
        matrix colnames E = `allVarList'
        matrix rownames E = "Entropy"
        matrix colnames D = `allVarList'
        matrix rownames D = "Redundancy"
        matrix colnames W = `allVarList'
        matrix rownames W = "Weight"
        
        dis ""
        dis "Entropy value"
        matlist E, format(%9.3f)
        
        dis ""
        dis "Information entropy redundancy"
        matlist D, format(%9.3f)

        dis ""
        dis "weight"
        matlist W, format(%9.3f)
		
		 * Store results in rclass
        return matrix E = E
        return matrix D = D
        return matrix W = W
    }

   

    if "`topsis'" == "" {
        di _n 
		di in red "**********************************************************"
        di in red "*******************  1、熵值、冗余度与权重    *************"
        di in red "**********************************************************"
        di _n
        di "您也可以使用以下命令查看存储返回值：权重矩阵、冗余度、熵值等结果："
        di  "{stata return list: 1、单击此链接查看所有存储返回值}""
        di _col(5)"等价于 {stata return list} 查看所有存储返回值"
        di  "{stata mat list r(W): 2、单击此链接查看权重矩阵}""
        di _col(5)"等价于 {stata mat list r(W)} 查看权重矩阵"
        di  "{stata mat list r(D): 3、单击此链接查看冗余度矩阵}""
        di _col(5)"等价于 {stata mat list r(D)} 查看冗余度矩阵"
        di  "{stata mat list r(E): 4、单击此链接查看熵值矩阵}""
        di _col(5)"等价于 {stata mat list r(E)} 查看熵值矩阵"
        di _n
        di in red "**********************************************************"
        di in red "******************  2、综合得分展示    *******************"
        di in red "**********************************************************"        
        list Score in 1/10
        di _n 
        dis as result "仅列出前10行得分结果，若需列出全部综合得分，可点击下面命令/链接进行查看"
        di _col(5) "{stata list Score: 单击此链接，查看完整综合得分}"
        dis as result "等价于"
        di _col(5) "{stata list Score }"
        di _n 
		di in red "**********************************************************"
        di in red "******************  3、综合得分描述性分析 ****************"
        di in red "**********************************************************"        
        di _n 
        di "您可以选择下面任一方法，输入或点击命令对应链接查看综合得分的描述性统计"
        di _col(5) "{stata sum Score, detail}"
        di "等价于 {stata sum Score, detail} 查看详细统计"
        di "或者点击 {stata tabstat Score, stat(mean sd min max)} 查看快速汇总"
        di _n 
    }
    else {
        di _n 
        di in red "**********************************************************"
        di in red "*****************   1、TOPSIS 综合得分展示    *************"
        di in red "**********************************************************" 
        list Score1 in 1/10
        di _n 
        dis as result "若需要列出全部数据的TOPSIS 综合得分，可以点击下面命令/链接进行查看"
        di _col(5) "{stata list Score1: 单击此链接，查看完整综合得分}"
        dis as result "等价于"
        di _col(5) "{stata list Score1 }"
        di _n 
		di in red "**********************************************************"
        di in red "***************** 2、TOPSIS 综合得分描述性分析 ***********"
        di in red "**********************************************************" 
        di _n 
        di "您可以选择下面任一方法，输入或点击命令对应链接查看综合得分的描述性统计"
        di _col(5) "{stata sum Score1, detail}"
        di "等价于 {stata sum Score1, detail} 查看详细统计"
        di "或者点击 {stata tabstat Score1, stat(mean sd min max)} 查看快速汇总"
        di _n
        di "=================================================================="
    }

end
