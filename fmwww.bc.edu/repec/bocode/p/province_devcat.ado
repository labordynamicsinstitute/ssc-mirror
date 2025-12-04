*! province_devcat.ado version 1.5
*! Authors: Wu Lianghai, Chen Liwen, Wu Hanyan
*! Affiliation: Anhui University of Technology & Nanjing University of Aeronautics and Astronautics
*! Development Date: 26Nov2025
*! Email: agd2010@yeah.net; 2184844526@qq.com; 2325476320@qq.com
*! 专门用于沪深A股上市公司发达程度分析

program define province_devcat
    version 16.0
    syntax [using/] , [SAVE(string) REPLACE]
    
    * 显示程序开始信息
    di " "
    di "=============================================="
    di "province_devcat程序开始执行 - 沪深A股上市公司发达程度分析"
    di "作者: Wu Lianghai, Chen Liwen, Wu Hanyan"
    di "开发日期: 26Nov2025"
    di "=============================================="
    di " "
    
    * 确定要使用的数据集
    if "`using'" == "" {
        local using "asure.dta"
        di "使用默认数据集: asure.dta"
    }
    else {
        di "使用指定数据集: `using'"
    }
    
    * 检查所需数据集是否存在
    capture confirm file "`using'"
    if _rc != 0 {
        di as error "错误: 未找到 `using' 数据集文件"
        exit 601
    }
    
    capture confirm file "pcgdp2010-2024.dta"
    if _rc != 0 {
        di as error "错误: 未找到pcgdp2010-2024.dta数据集文件"
        exit 601
    }
    
    * 保存当前数据集
    preserve
    
    * 加载并检查pcgdp数据集
    di "步骤1: 加载人均GDP数据集..."
    use "pcgdp2010-2024.dta", clear
    
    * 检查必要变量是否存在
    capture confirm variable province year pcgdp
    if _rc != 0 {
        di as error "错误: pcgdp数据集中缺少必要变量(province, year, pcgdp)"
        restore
        exit 111
    }
    
    * 确认province变量为字符串类型，如果不是则转换
    capture confirm string variable province
    if _rc != 0 {
        di "提示: pcgdp数据集中的province变量不是字符串类型，正在自动转换..."
        tostring province, replace
        di "province变量已转换为字符串类型"
    }
    
    * 标准化省份名称 - 创建统一的省份代码
    di "创建统一的省份代码..."
    gen province_code = province
    
    * 将pcgdp数据集中的省份名称转换为与上市公司数据集匹配的完整名称
    replace province_code = "北京市" if province_code == "北京"
    replace province_code = "天津市" if province_code == "天津"
    replace province_code = "河北省" if province_code == "河北"
    replace province_code = "山西省" if province_code == "山西"
    replace province_code = "内蒙古自治区" if province_code == "内蒙古"
    replace province_code = "辽宁省" if province_code == "辽宁"
    replace province_code = "吉林省" if province_code == "吉林"
    replace province_code = "黑龙江省" if province_code == "黑龙江"
    replace province_code = "上海市" if province_code == "上海"
    replace province_code = "江苏省" if province_code == "江苏"
    replace province_code = "浙江省" if province_code == "浙江"
    replace province_code = "安徽省" if province_code == "安徽"
    replace province_code = "福建省" if province_code == "福建"
    replace province_code = "江西省" if province_code == "江西"
    replace province_code = "山东省" if province_code == "山东"
    replace province_code = "河南省" if province_code == "河南"
    replace province_code = "湖北省" if province_code == "湖北"
    replace province_code = "湖南省" if province_code == "湖南"
    replace province_code = "广东省" if province_code == "广东"
    replace province_code = "广西壮族自治区" if province_code == "广西"
    replace province_code = "海南省" if province_code == "海南"
    replace province_code = "重庆市" if province_code == "重庆"
    replace province_code = "四川省" if province_code == "四川"
    replace province_code = "贵州省" if province_code == "贵州"
    replace province_code = "云南省" if province_code == "云南"
    replace province_code = "西藏自治区" if province_code == "西藏"
    replace province_code = "陕西省" if province_code == "陕西"
    replace province_code = "甘肃省" if province_code == "甘肃"
    replace province_code = "青海省" if province_code == "青海"
    replace province_code = "宁夏回族自治区" if province_code == "宁夏"
    replace province_code = "新疆维吾尔自治区" if province_code == "新疆"
    
    * 检查数据质量
    di "数据质量检查:"
    count if missing(province_code)
    if r(N) > 0 {
        di as error "警告: 发现 `r(N)' 个缺失的省份代码"
    }
    
    count if missing(year)
    if r(N) > 0 {
        di as error "警告: 发现 `r(N)' 个缺失的年份"
    }
    
    count if missing(pcgdp)
    if r(N) > 0 {
        di as error "警告: 发现 `r(N)' 个缺失的人均GDP值"
    }
    
    * 显示基本统计信息
    di " "
    di "人均GDP数据集基本信息:"
    summarize pcgdp
    tab province_code
    
    * 保存处理后的pcgdp数据
    tempfile pcgdp_temp
    save "`pcgdp_temp'", replace
    
    * 加载沪深A股上市公司数据集
    di " "
    di "步骤2: 加载沪深A股上市公司数据集..."
    use "`using'", clear
    
    * 检查数据集中的province变量，如果不是字符串类型则转换
    capture confirm string variable province
    if _rc != 0 {
        di "提示: `using' 中的province变量不是字符串类型，正在自动转换..."
        capture tostring province, replace
        if _rc != 0 {
            di as error "错误: 无法将province变量转换为字符串类型"
            di as error "请检查province变量的数据类型"
            restore
            exit 109
        }
        di "province变量已转换为字符串类型"
    }
    
    * 在上市公司数据集中创建省份代码变量 - 直接使用原始省份名称
    gen province_code = province
    
    * 标准化省份名称 - 转换为完整名称以匹配pcgdp数据集
    di "标准化上市公司数据集中的省份名称..."
    replace province_code = "北京市" if province_code == "北京"
    replace province_code = "天津市" if province_code == "天津"
    replace province_code = "河北省" if province_code == "河北"
    replace province_code = "山西省" if province_code == "山西"
    replace province_code = "内蒙古自治区" if province_code == "内蒙古"
    replace province_code = "辽宁省" if province_code == "辽宁"
    replace province_code = "吉林省" if province_code == "吉林"
    replace province_code = "黑龙江省" if province_code == "黑龙江"
    replace province_code = "上海市" if province_code == "上海"
    replace province_code = "江苏省" if province_code == "江苏"
    replace province_code = "浙江省" if province_code == "浙江"
    replace province_code = "安徽省" if province_code == "安徽"
    replace province_code = "福建省" if province_code == "福建"
    replace province_code = "江西省" if province_code == "江西"
    replace province_code = "山东省" if province_code == "山东"
    replace province_code = "河南省" if province_code == "河南"
    replace province_code = "湖北省" if province_code == "湖北"
    replace province_code = "湖南省" if province_code == "湖南"
    replace province_code = "广东省" if province_code == "广东"
    replace province_code = "广西壮族自治区" if province_code == "广西"
    replace province_code = "海南省" if province_code == "海南"
    replace province_code = "重庆市" if province_code == "重庆"
    replace province_code = "四川省" if province_code == "四川"
    replace province_code = "贵州省" if province_code == "贵州"
    replace province_code = "云南省" if province_code == "云南"
    replace province_code = "西藏自治区" if province_code == "西藏"
    replace province_code = "陕西省" if province_code == "陕西"
    replace province_code = "甘肃省" if province_code == "甘肃"
    replace province_code = "青海省" if province_code == "青海"
    replace province_code = "宁夏回族自治区" if province_code == "宁夏"
    replace province_code = "新疆维吾尔自治区" if province_code == "新疆"
    
    * 标准化省份名称
    replace province_code = strtrim(province_code)
    replace province_code = ustrtrim(province_code)
    
    di "上市公司数据集基本信息:"
    di "观测值数量: " _N
    tab province_code
    
    * 合并数据集
    di " "
    di "步骤3: 合并数据集..."
    
    capture {
        merge m:1 province_code year using "`pcgdp_temp'", keep(match master) 
    }
    if _rc != 0 {
        di as error "错误: 数据集合并失败"
        di "请检查:"
        di "1. 省份名称是否完全匹配"
        di "2. 年份范围是否一致" 
        di "3. 是否存在重复观测"
        restore
        exit 459
    }
    
    * 显示合并结果
    di "合并结果:"
    tab _merge
    drop _merge
    
    di "合并后观测值数量: " _N
    
    * 检查合并后pcgdp的缺失情况
    count if missing(pcgdp)
    if r(N) > 0 {
        di as error "警告: 合并后有 `r(N)' 个观测值的人均GDP为缺失值"
        di "这些观测将被排除在发达程度分类之外"
        
        * 显示哪些省份没有匹配到数据
        di "未匹配到GDP数据的省份:"
        tab province_code if missing(pcgdp)
    }
    else {
        di "成功: 所有观测值都匹配到了人均GDP数据"
    }
    
    * 生成发达程度变量(province_devcat)
    di " "
    di "步骤4: 生成发达程度变量..."
    
    * 按年份分组计算三分位数
    bysort year: egen p33 = pctile(pcgdp), p(33.33)
    bysort year: egen p66 = pctile(pcgdp), p(66.67)
    
    * 生成发达程度变量
    gen province_devcat = .
    replace province_devcat = 1 if pcgdp >= p66 & !missing(pcgdp)  // 发达
    replace province_devcat = 2 if pcgdp >= p33 & pcgdp < p66 & !missing(pcgdp)  // 欠发达
    replace province_devcat = 3 if pcgdp < p33 & !missing(pcgdp)   // 不发达
    
    * 添加变量标签
    label variable province_devcat "发达程度"
    label define province_devcat_label 1 "发达" 2 "欠发达" 3 "不发达"
    label values province_devcat province_devcat_label
    
    * 清理临时变量
    drop p33 p66 province_code
    
    * 描述性统计
    di " "
    di "=============================================="
    di "发达程度变量描述性统计"
    di "=============================================="
    
    * 基本统计信息
    di " "
    di "1. 发达程度分布:"
    tab province_devcat, missing
    
    * 按年份的分布
    di " "
    di "2. 按年份的发达程度分布:"
    tab year province_devcat, row
    
    * 按省份的分布
    di " "
    di "3. 按省份的发达程度分布:"
    tab province province_devcat, row
    
    * 各省份发达程度模式统计
    di " "
    di "4. 各省份主要发达程度模式:"
    bysort province: egen mode_province_devcat = mode(province_devcat), minmode
    tab province mode_province_devcat
    drop mode_province_devcat
    
    * 详细统计表格
    di " "
    di "5. 各发达程度组的人均GDP统计:"
    tabstat pcgdp, by(province_devcat) statistics(mean sd min max count) format(%9.2f)
    
    * 时间趋势分析
    di " "
    di "6. 发达程度的时间趋势:"
    tab year province_devcat
    
    * 保存结果数据集（如果指定了save选项）
    if "`save'" != "" {
        if "`replace'" == "replace" {
            capture save "`save'", replace
            if _rc == 0 {
                di " "
                di "结果数据集已保存至: `save'"
            }
            else {
                di as error "保存失败，错误代码: " _rc
            }
        }
        else {
            capture confirm file "`save'"
            if _rc == 0 {
                di as error "文件 `save' 已存在，使用replace选项覆盖"
            }
            else {
                capture save "`save'"
                if _rc == 0 {
                    di " "
                    di "结果数据集已保存至: `save'"
                }
                else {
                    di as error "保存失败，错误代码: " _rc
                }
            }
        }
    }
    
    * 显示完成信息
    di " "
    di "=============================================="
    di "程序执行完成"
    di "生成的变量: province_devcat (发达程度)"
    di "变量取值: 1=发达, 2=欠发达, 3=不发达"
    di "基于人均GDP的三分位数按年份动态分类"
    di "=============================================="
    
    * 恢复原始数据集
    restore
    
end

* 程序结束