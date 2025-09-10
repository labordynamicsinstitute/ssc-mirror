*! citytoprovince v1.0  Xiaokang Wu  07jan2025
*! Generate province names from Chinese city names
*! Author: Xiaokang Wu, Nanjing University of Science and Technology

program define citytoprovince
    version 14.0
    syntax varname [, GENerate(string) REPlace]
    
    * 检查参数
    if "`generate'" == "" & "`replace'" == "" {
        di as error "必须指定 generate() 或 replace 选项"
        exit 198
    }
    
    if "`generate'" != "" & "`replace'" != "" {
        di as error "generate() 和 replace 选项不能同时使用"
        exit 198
    }
    
    * 确定目标变量名
    local targetvar = cond("`generate'" != "", "`generate'", "province")
    
    * 如果是generate选项，检查变量是否已存在
    if "`generate'" != "" {
        capture confirm variable `targetvar'
        if !_rc {
            di as error "变量 `targetvar' 已存在"
            exit 110
        }
    }
    
    * 创建或替换目标变量
    if "`replace'" != "" {
        capture drop `targetvar'
    }
    quietly gen str50 `targetvar' = ""
    
    * 标准化输入的城市名称
    tempvar clean_city
    quietly gen `clean_city' = `varlist'
    
    * 去除常见后缀
    quietly replace `clean_city' = regexr(`clean_city', "回族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "朝鲜族自治州$", "")
	quietly replace `clean_city' = regexr(`clean_city', "哈尼族彝族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "彝族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "白族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "傣族景颇族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "傣族自治州$", "")	
    quietly replace `clean_city' = regexr(`clean_city', "傈僳族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "土家族苗族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "壮族苗族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "蒙古族藏族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "藏族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "藏族羌族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "布依族苗族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "苗族侗族自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "哈萨克自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "柯尔克孜自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "蒙古自治州$", "")
    quietly replace `clean_city' = regexr(`clean_city', "黎族自治县$", "")
    quietly replace `clean_city' = regexr(`clean_city', "特别行政区$", "")
    quietly replace `clean_city' = regexr(`clean_city', "盟$", "")
	quietly replace `clean_city' = regexr(`clean_city', "市$", "")
    quietly replace `clean_city' = regexr(`clean_city', "地区$", "")
    quietly replace `clean_city' = regexr(`clean_city', "自治州$", "")
    
    * 直接使用条件替换进行映射
    * 直辖市
    quietly replace `targetvar' = "北京市" if `clean_city' == "北京"
    quietly replace `targetvar' = "天津市" if `clean_city' == "天津"
    quietly replace `targetvar' = "上海市" if `clean_city' == "上海"
    quietly replace `targetvar' = "重庆市" if `clean_city' == "重庆"
    
    * 特别行政区
    quietly replace `targetvar' = "香港特别行政区" if `clean_city' == "香港"
    quietly replace `targetvar' = "澳门特别行政区" if `clean_city' == "澳门"
    
    * 河北省
    quietly replace `targetvar' = "河北省" if inlist(`clean_city', "石家庄", "唐山", "秦皇岛", "邯郸", "邢台")
    quietly replace `targetvar' = "河北省" if inlist(`clean_city', "保定", "张家口", "承德", "沧州", "廊坊", "衡水")
    
    * 山西省
    quietly replace `targetvar' = "山西省" if inlist(`clean_city', "太原", "大同", "阳泉", "长治", "晋城")
    quietly replace `targetvar' = "山西省" if inlist(`clean_city', "朔州", "晋中", "运城", "忻州", "临汾", "吕梁")
    
    * 内蒙古自治区
    quietly replace `targetvar' = "内蒙古自治区" if inlist(`clean_city', "呼和浩特", "呼市", "包头", "乌海", "赤峰")
    quietly replace `targetvar' = "内蒙古自治区" if inlist(`clean_city', "通辽", "鄂尔多斯", "呼伦贝尔", "巴彦淖尔")
    quietly replace `targetvar' = "内蒙古自治区" if inlist(`clean_city', "乌兰察布", "兴安盟", "锡林郭勒", "阿拉善盟")
    
    * 辽宁省
    quietly replace `targetvar' = "辽宁省" if inlist(`clean_city', "沈阳", "大连", "鞍山", "抚顺", "本溪")
    quietly replace `targetvar' = "辽宁省" if inlist(`clean_city', "丹东", "锦州", "营口", "阜新", "辽阳")
    quietly replace `targetvar' = "辽宁省" if inlist(`clean_city', "盘锦", "铁岭", "朝阳", "葫芦岛")
    
    * 吉林省
    quietly replace `targetvar' = "吉林省" if inlist(`clean_city', "长春", "吉林", "四平", "辽源", "通化")
    quietly replace `targetvar' = "吉林省" if inlist(`clean_city', "白山", "松原", "白城", "延边")
    
    * 黑龙江省
    quietly replace `targetvar' = "黑龙江省" if inlist(`clean_city', "哈尔滨", "齐齐哈尔", "鸡西", "鹤岗", "双鸭山")
    quietly replace `targetvar' = "黑龙江省" if inlist(`clean_city', "大庆", "伊春", "佳木斯", "七台河", "牡丹江")
    quietly replace `targetvar' = "黑龙江省" if inlist(`clean_city', "黑河", "绥化", "大兴安岭")
    
    * 江苏省
    quietly replace `targetvar' = "江苏省" if inlist(`clean_city', "南京", "无锡", "徐州", "常州", "苏州")
    quietly replace `targetvar' = "江苏省" if inlist(`clean_city', "南通", "连云港", "淮安", "盐城", "扬州")
    quietly replace `targetvar' = "江苏省" if inlist(`clean_city', "镇江", "泰州", "宿迁")
    
    * 浙江省
    quietly replace `targetvar' = "浙江省" if inlist(`clean_city', "杭州", "宁波", "温州", "嘉兴", "湖州")
    quietly replace `targetvar' = "浙江省" if inlist(`clean_city', "绍兴", "金华", "衢州", "舟山", "台州", "丽水")
    
    * 安徽省
    quietly replace `targetvar' = "安徽省" if inlist(`clean_city', "合肥", "芜湖", "蚌埠", "淮南", "马鞍山")
    quietly replace `targetvar' = "安徽省" if inlist(`clean_city', "淮北", "铜陵", "安庆", "黄山", "滁州")
    quietly replace `targetvar' = "安徽省" if inlist(`clean_city', "阜阳", "宿州", "六安", "亳州", "池州", "池洲", "宣城")
    quietly replace `targetvar' = "安徽省" if `clean_city' == "巢湖"
    
    * 福建省
    quietly replace `targetvar' = "福建省" if inlist(`clean_city', "福州", "厦门", "莆田", "三明", "泉州")
    quietly replace `targetvar' = "福建省" if inlist(`clean_city', "漳州", "南平", "龙岩", "宁德")
    
    * 江西省
    quietly replace `targetvar' = "江西省" if inlist(`clean_city', "南昌", "景德镇", "萍乡", "九江", "新余")
    quietly replace `targetvar' = "江西省" if inlist(`clean_city', "鹰潭", "赣州", "吉安", "宜春", "抚州", "上饶")
    
    * 山东省
    quietly replace `targetvar' = "山东省" if inlist(`clean_city', "济南", "青岛", "淄博", "枣庄", "东营")
    quietly replace `targetvar' = "山东省" if inlist(`clean_city', "烟台", "潍坊", "济宁", "泰安", "威海")
    quietly replace `targetvar' = "山东省" if inlist(`clean_city', "日照", "莱芜", "临沂", "德州", "聊城")
    quietly replace `targetvar' = "山东省" if inlist(`clean_city', "滨州", "菏泽")
    
    * 河南省
    quietly replace `targetvar' = "河南省" if inlist(`clean_city', "郑州", "开封", "洛阳", "平顶山", "安阳")
    quietly replace `targetvar' = "河南省" if inlist(`clean_city', "鹤壁", "新乡", "焦作", "濮阳", "许昌")
    quietly replace `targetvar' = "河南省" if inlist(`clean_city', "漯河", "三门峡", "南阳", "商丘", "信阳")
    quietly replace `targetvar' = "河南省" if inlist(`clean_city', "周口", "驻马店","济源")
    
    * 湖北省
    quietly replace `targetvar' = "湖北省" if inlist(`clean_city', "武汉", "黄石", "十堰", "宜昌", "襄阳", "襄樊")
    quietly replace `targetvar' = "湖北省" if inlist(`clean_city', "鄂州", "荆门", "孝感", "荆州", "黄冈")
    quietly replace `targetvar' = "湖北省" if inlist(`clean_city', "咸宁", "随州", "恩施","天门","仙桃","潜江")
    
    * 湖南省
    quietly replace `targetvar' = "湖南省" if inlist(`clean_city', "长沙", "株洲", "湘潭", "衡阳", "邵阳")
    quietly replace `targetvar' = "湖南省" if inlist(`clean_city', "岳阳", "常德", "张家界", "益阳", "郴州")
    quietly replace `targetvar' = "湖南省" if inlist(`clean_city', "永州", "怀化", "娄底", "湘西")
    
    * 广东省
    quietly replace `targetvar' = "广东省" if inlist(`clean_city', "广州", "韶关", "深圳", "珠海", "汕头")
    quietly replace `targetvar' = "广东省" if inlist(`clean_city', "佛山", "江门", "湛江", "茂名", "肇庆")
    quietly replace `targetvar' = "广东省" if inlist(`clean_city', "惠州", "梅州", "汕尾", "河源", "阳江")
    quietly replace `targetvar' = "广东省" if inlist(`clean_city', "清远", "东莞", "中山", "潮州", "揭阳", "云浮")
    
    * 广西壮族自治区
    quietly replace `targetvar' = "广西壮族自治区" if inlist(`clean_city', "南宁", "柳州", "桂林", "梧州", "北海")
    quietly replace `targetvar' = "广西壮族自治区" if inlist(`clean_city', "防城港", "钦州", "贵港", "玉林", "百色")
    quietly replace `targetvar' = "广西壮族自治区" if inlist(`clean_city', "贺州", "河池", "来宾", "崇左")
    
    * 海南省
    quietly replace `targetvar' = "海南省" if inlist(`clean_city', "海口", "三亚", "三沙", "儋州", "乐东")
	quietly replace `targetvar' = "海南省" if inlist(`clean_city',"万宁","文昌","琼海","陵水","定安")
    
    * 四川省
    quietly replace `targetvar' = "四川省" if inlist(`clean_city', "成都", "自贡", "攀枝花", "泸州", "德阳")
    quietly replace `targetvar' = "四川省" if inlist(`clean_city', "绵阳", "广元", "遂宁", "内江", "乐山")
    quietly replace `targetvar' = "四川省" if inlist(`clean_city', "南充", "眉山", "宜宾", "广安", "达州")
    quietly replace `targetvar' = "四川省" if inlist(`clean_city', "雅安", "巴中", "资阳", "阿坝", "甘孜")
    quietly replace `targetvar' = "四川省" if inlist(`clean_city', "凉山", "凉山州")
    
    * 贵州省
    quietly replace `targetvar' = "贵州省" if inlist(`clean_city', "贵阳", "六盘水", "遵义", "安顺", "毕节")
    quietly replace `targetvar' = "贵州省" if inlist(`clean_city', "铜仁", "黔西南", "黔东南", "黔南")
    
    * 云南省
    quietly replace `targetvar' = "云南省" if inlist(`clean_city', "昆明", "曲靖", "玉溪", "保山", "昭通")
    quietly replace `targetvar' = "云南省" if inlist(`clean_city', "丽江", "普洱", "临沧", "楚雄", "红河", "红河州", "红河市")
    quietly replace `targetvar' = "云南省" if inlist(`clean_city', "文山", "西双版纳", "大理", "德宏", "怒江", "迪庆")
    
    * 西藏自治区
    quietly replace `targetvar' = "西藏自治区" if inlist(`clean_city', "拉萨", "日喀则", "昌都", "林芝", "山南")
    quietly replace `targetvar' = "西藏自治区" if inlist(`clean_city', "那曲", "阿里")
    
    * 陕西省
    quietly replace `targetvar' = "陕西省" if inlist(`clean_city', "西安", "铜川", "宝鸡", "咸阳", "渭南")
    quietly replace `targetvar' = "陕西省" if inlist(`clean_city', "延安", "汉中", "榆林", "安康", "商洛")
    
    * 甘肃省
    quietly replace `targetvar' = "甘肃省" if inlist(`clean_city', "兰州", "嘉峪关", "金昌", "白银", "天水")
    quietly replace `targetvar' = "甘肃省" if inlist(`clean_city', "武威", "张掖", "平凉", "酒泉", "庆阳")
    quietly replace `targetvar' = "甘肃省" if inlist(`clean_city', "定西", "陇南", "临夏", "甘南")
    
    * 青海省
    quietly replace `targetvar' = "青海省" if inlist(`clean_city', "西宁", "海东", "海北", "海北州", "黄南", "海南")
    quietly replace `targetvar' = "青海省" if inlist(`clean_city', "果洛", "玉树", "海西")
    
    * 宁夏回族自治区
    quietly replace `targetvar' = "宁夏回族自治区" if inlist(`clean_city', "银川", "石嘴山", "吴忠", "固原", "中卫")
    
    * 新疆维吾尔自治区
    quietly replace `targetvar' = "新疆维吾尔自治区" if inlist(`clean_city', "乌鲁木齐", "乌市", "克拉玛依")
    quietly replace `targetvar' = "新疆维吾尔自治区" if inlist(`clean_city', "吐鲁番", "哈密", "昌吉", "博尔塔拉", "博州")
    quietly replace `targetvar' = "新疆维吾尔自治区" if inlist(`clean_city', "巴音郭楞", "巴音郭楞州", "巴音郭楞自治州", "巴音郭勒", "巴州", "巴音")
    quietly replace `targetvar' = "新疆维吾尔自治区" if inlist(`clean_city', "阿克苏", "克孜勒苏", "克州", "喀什", "和田")
    quietly replace `targetvar' = "新疆维吾尔自治区" if inlist(`clean_city', "伊犁", "塔城", "阿勒泰","石河子")
    
    * 统计结果
    quietly count if `targetvar' != ""
    local matched = r(N)
    quietly count
    local total = r(N)
    local unmatched = `total' - `matched'
    
    di as text _n "城市到省份映射完成:"
    di as text "成功匹配: " as result `matched' as text " 条记录"
    di as text "未匹配: " as result `unmatched' as text " 条记录"
    
    
end