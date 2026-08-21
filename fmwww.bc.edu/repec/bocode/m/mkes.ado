/*==================================================================
    mkes.ado - Make English Sentences  v3.1.0
    Uses Stata's Python integration (Stata 16+).
    Syntax: mkes "prompt" [, N(#) OUTput(name) REPLACE]
            mkes , UNIts(#) [MODE(string) N(#) OUTput(name) REPLACE START(#)]
            mkes --list
    Authors: WU Lianghai (AHUT) ; WU Hanyan (CityU)
    ==================================================================*/

program define mkes
    version 16.0

    /* ---- special case: --list ---- */
    gettoken arg 0 : 0, parse(" ,")
    if (`"`arg'"' == "--list") {
        python: mkes_list_patterns()
        exit 0
    }

    /* ---- determine mode and parse options ---- */
    if (`"`arg'"' == ",") {
        /* ---- MULTI-UNIT MODE ---- */
        local 0 ", `0'"
        syntax [, UNIts(integer 1) MODE(string) START(integer 1) N(integer 10) OUTput(string) REPLACE]
        local is_multi 1
    }
    else {
        /* ---- SINGLE-PROMPT MODE ---- */
        local full `"`arg'`0'"'
        gettoken prompt rest : full, parse(",")
        local prompt = strtrim(`"`prompt'"')
        syntax [, N(integer 10) OUTput(string) REPLACE]
        local is_multi 0
    }

    /* ---- shared: defaults & overwrite check ---- */
    if ("`output'" == "") local output "mkes_output"
    local outfile "`output'.txt"

    if (!missing("`replace'")) {
        capture confirm file "`outfile'"
        if _rc == 0 capture erase "`outfile'"
    }
    else {
        capture confirm file "`outfile'"
        if _rc == 0 {
            display as error "Error: file `outfile' exists. Use replace."
            exit 602
        }
    }

    /* ---- verify Python ---- */
    capture python query
    if _rc != 0 {
        display as error "Python is required. Run: python search"
        exit 199
    }

    /* ---- execute ---- */
    if (`is_multi') {
        /* --- multi-unit execution --- */
        if ("`mode'" == "") local mode "sequential"
        local mode_lower = lower("`mode'")
        if (!inlist("`mode_lower'", "sequential", "random")) {
            display as error "Error: mode() must be sequential or random."
            exit 198
        }

        python: mkes_multi_main(`units', "`mode_lower'", `n', "`outfile'", `start')

        display as text _newline "{hline 70}"
        display as result "Generated `units' units x `n' sentences each -> `outfile'"
        display as text "Mode: `mode_lower'"
        display as text "{hline 70}"
    }
    else {
        /* --- single-prompt execution --- */
        if (missing(`"`prompt'"')) {
            display as error "Error: please provide an English oral prompt,"
            display as error "       or use units() for multi-unit mode."
            display as text `"Example: mkes "There is no", n(10)"'
            display as text `"Example: mkes , units(3) mode(random) n(5)"'
            exit 198
        }

        local prompt_py = subinstr(`"`prompt'"', `"""', `"\"', .)
        python: mkes_main("`prompt_py'", `n', "`outfile'")

        display as text _newline "{hline 70}"
        display as result "Generated `n' sentences -> `outfile'"
        display as text "{hline 70}"
    }

    display as text "Dingyuan Accounting LAN (D:\dingyuan-system) imports into the Spoken English module."
    display as text "Authors: WU Lianghai (AHUT) ; WU Hanyan (CityU)"
    display as text "{hline 70}"
end

/*==================================================================
   Python section - all logic and data (zero Stata/Mata limits)
   ==================================================================*/

python:

import random

# ============================================================
# WORD BANK — dict: slot_type -> list of (english, chinese)
# ============================================================
WORDS = {
    "noun_exist_no": [
        ("time", "时间"), ("reply", "回应"), ("point", "意义"),
        ("way", "办法"), ("need", "需要"), ("doubt", "疑问"),
        ("reason", "理由"), ("hurry", "着急"), ("choice", "选择"),
        ("hope", "希望"), ("chance", "机会"), ("difference", "区别"),
        ("sign", "迹象"), ("limit", "限制"), ("answer", "答案"),
        ("excuse", "借口"), ("guarantee", "保证"), ("evidence", "证据"),
        ("cure", "治疗方法"), ("shortcut", "捷径"), ("room", "空间"),
        ("sense", "道理"), ("solution", "解决方案"), ("alternative", "替代方案"),
        ("option", "选项"), ("risk", "风险"), ("pressure", "压力"),
        ("rush", "匆忙"), ("problem", "问题"), ("issue", "问题"),
        ("trouble", "麻烦"), ("harm", "害处"), ("connection", "联系"),
        ("relation", "关系"), ("secret", "秘密"), ("rule", "规定"),
        ("law", "法律"), ("right", "权利"), ("mistake", "错误"),
        ("plan", "计划"), ("future", "未来"), ("purpose", "目的"),
        ("meaning", "意义"), ("value", "价值"), ("question", "问题"),
        ("confusion", "混淆"), ("regret", "遗憾"), ("shame", "羞耻"),
        ("comparison", "可比性"), ("competition", "竞争"), ("compromise", "妥协"),
        ("justice", "公正"), ("escape", "逃脱"), ("turning back", "回头路"),
        ("going back", "退路"), ("end", "尽头"), ("shortage", "短缺"),
        ("lack", "缺乏"),
    ],
    "noun_exist_a": [
        ("problem", "问题"), ("chance", "机会"), ("way", "办法"),
        ("reason", "原因"), ("difference", "区别"), ("question", "问题"),
        ("solution", "解决方案"), ("plan", "计划"), ("sign", "迹象"),
        ("limit", "限制"), ("choice", "选择"), ("possibility", "可能性"),
        ("risk", "风险"), ("need", "需求"), ("meeting", "会议"),
        ("party", "聚会"), ("call", "电话"), ("message", "消息"),
        ("mistake", "错误"), ("secret", "秘密"), ("surprise", "惊喜"),
        ("deal", "交易"), ("challenge", "挑战"), ("change", "变化"),
        ("dream", "梦想"), ("goal", "目标"), ("idea", "主意"),
        ("suggestion", "建议"), ("request", "请求"), ("rule", "规则"),
        ("pattern", "模式"), ("habit", "习惯"), ("tradition", "传统"),
        ("story", "故事"), ("lesson", "教训"), ("feeling", "感觉"),
        ("thought", "想法"), ("memory", "回忆"), ("promise", "承诺"),
        ("decision", "决定"), ("offer", "提议"), ("opportunity", "机会"),
        ("project", "项目"), ("task", "任务"), ("job", "工作"),
        ("trip", "旅行"), ("break", "休息"), ("hobby", "爱好"),
        ("skill", "技能"), ("talent", "天赋"), ("gift", "礼物"),
        ("favor", "帮忙"), ("clue", "线索"), ("hint", "提示"),
    ],
    "noun_exist_pl": [
        ("problems", "问题"), ("people", "人"), ("things", "事情"),
        ("reasons", "原因"), ("ways", "方法"), ("questions", "问题"),
        ("answers", "答案"), ("options", "选择"), ("choices", "选项"),
        ("chances", "机会"), ("opportunities", "机遇"), ("challenges", "挑战"),
        ("difficulties", "困难"), ("issues", "问题"), ("mistakes", "错误"),
        ("rules", "规则"), ("exceptions", "例外"), ("limits", "限制"),
        ("signs", "迹象"), ("ideas", "想法"), ("suggestions", "建议"),
        ("plans", "计划"), ("secrets", "秘密"), ("surprises", "惊喜"),
        ("differences", "差异"), ("possibilities", "可能性"), ("risks", "风险"),
        ("benefits", "好处"), ("advantages", "优势"), ("disadvantages", "劣势"),
        ("details", "细节"), ("facts", "事实"), ("feelings", "感受"),
        ("emotions", "情绪"), ("memories", "记忆"), ("experiences", "经历"),
        ("stories", "故事"),
    ],
    "noun_exist_pl_no": [
        ("problems", "问题"), ("complaints", "投诉"), ("questions", "问题"),
        ("answers", "答案"), ("signs", "迹象"), ("witnesses", "目击者"),
        ("survivors", "幸存者"), ("clues", "线索"), ("excuses", "借口"),
        ("guarantees", "保证"), ("shortcuts", "捷径"), ("alternatives", "替代方案"),
        ("options", "选项"), ("limits", "限制"), ("secrets", "秘密"),
        ("exceptions", "例外"), ("mistakes", "错误"), ("regrets", "遗憾"),
        ("conditions", "条件"), ("restrictions", "限制"),
    ],
    "noun_have_a": [
        ("question", "问题"), ("problem", "问题"), ("dream", "梦想"),
        ("plan", "计划"), ("suggestion", "建议"), ("feeling", "感觉"),
        ("headache", "头疼"), ("cold", "感冒"), ("meeting", "会议"),
        ("car", "车"), ("house", "房子"), ("dog", "狗"), ("cat", "猫"),
        ("computer", "电脑"), ("phone", "手机"), ("book", "书"),
        ("pen", "笔"), ("job", "工作"), ("family", "家庭"),
        ("friend", "朋友"), ("garden", "花园"), ("pool", "游泳池"),
        ("gym", "健身房"), ("membership", "会员资格"), ("subscription", "订阅"),
        ("ticket", "票"), ("reservation", "预订"), ("table", "桌子"),
        ("chair", "椅子"), ("sofa", "沙发"), ("TV", "电视"),
        ("laptop", "笔记本电脑"), ("watch", "手表"), ("ring", "戒指"),
        ("necklace", "项链"), ("hat", "帽子"), ("bag", "包"),
        ("backpack", "背包"), ("wallet", "钱包"), ("passport", "护照"),
        ("visa", "签证"), ("degree", "学位"), ("certificate", "证书"),
        ("license", "执照"), ("pet", "宠物"), ("hobby", "爱好"),
        ("collection", "收藏品"), ("blog", "博客"), ("website", "网站"),
        ("channel", "频道"), ("podcast", "播客"),
    ],
    "noun_have_pl": [
        ("time", "时间"), ("money", "钱"), ("energy", "精力"),
        ("patience", "耐心"), ("experience", "经验"), ("confidence", "信心"),
        ("courage", "勇气"), ("freedom", "自由"), ("power", "权力"),
        ("control", "控制"), ("influence", "影响力"), ("knowledge", "知识"),
        ("information", "信息"), ("talent", "才华"), ("skills", "技能"),
        ("friends", "朋友"), ("family", "家人"), ("kids", "孩子"),
        ("children", "孩子"), ("pets", "宠物"), ("books", "书"),
        ("clothes", "衣服"), ("shoes", "鞋子"), ("food", "食物"),
        ("water", "水"), ("coffee", "咖啡"), ("tea", "茶"),
        ("homework", "家庭作业"), ("work", "工作"), ("fun", "乐趣"),
        ("trouble", "麻烦"), ("luck", "运气"), ("hope", "希望"),
        ("faith", "信念"), ("respect", "尊重"), ("trust", "信任"),
        ("support", "支持"), ("love", "爱"), ("peace", "安宁"),
    ],
    "verb_to_do": [
        ("go", "去"), ("leave", "离开"), ("stay", "留下"), ("eat", "吃"),
        ("drink", "喝"), ("sleep", "睡觉"), ("rest", "休息"), ("relax", "放松"),
        ("talk", "说话"), ("speak", "讲话"), ("listen", "听"), ("watch", "看"),
        ("read", "阅读"), ("write", "写"), ("learn", "学习"), ("study", "学习"),
        ("teach", "教"), ("help", "帮助"), ("try", "尝试"), ("start", "开始"),
        ("stop", "停止"), ("quit", "放弃"), ("finish", "完成"), ("begin", "开始"),
        ("change", "改变"), ("improve", "改进"), ("grow", "成长"), ("create", "创造"),
        ("build", "建造"), ("make", "做"), ("do", "做"), ("see", "看"),
        ("hear", "听到"), ("feel", "感觉"), ("think", "思考"), ("know", "知道"),
        ("understand", "理解"), ("remember", "记住"), ("forget", "忘记"),
        ("believe", "相信"), ("hope", "希望"), ("play", "玩"), ("work", "工作"),
        ("travel", "旅行"), ("run", "跑步"), ("walk", "走路"), ("drive", "开车"),
        ("fly", "飞行"), ("swim", "游泳"), ("dance", "跳舞"), ("sing", "唱歌"),
        ("cook", "做饭"), ("clean", "打扫"), ("fix", "修理"), ("buy", "买"),
        ("sell", "卖"), ("give", "给"), ("take", "拿"), ("send", "发送"),
        ("find", "找到"), ("lose", "失去"), ("win", "赢"), ("wait", "等待"),
        ("hurry", "赶快"), ("exercise", "锻炼"), ("meditate", "冥想"),
        ("apologize", "道歉"), ("explain", "解释"), ("complain", "抱怨"),
        ("argue", "争论"), ("agree", "同意"), ("share", "分享"),
        ("join", "加入"), ("volunteer", "志愿"), ("donate", "捐赠"),
        ("invest", "投资"), ("save", "节省"), ("spend", "花费"),
        ("call", "打电话"), ("visit", "拜访"), ("meet", "见面"),
        ("marry", "结婚"), ("move", "搬家"), ("retire", "退休"),
    ],
    "verb_base": [
        ("go", "去"), ("come", "来"), ("stay", "留下"), ("leave", "离开"),
        ("eat", "吃"), ("sleep", "睡"), ("wait", "等"), ("try", "尝试"),
        ("help", "帮助"), ("talk", "谈"), ("listen", "听"), ("watch", "看"),
        ("read", "读"), ("write", "写"), ("learn", "学"), ("teach", "教"),
        ("start", "开始"), ("stop", "停"), ("finish", "完成"), ("continue", "继续"),
        ("change", "改变"), ("work", "工作"), ("play", "玩"), ("rest", "休息"),
        ("run", "跑"), ("walk", "走"), ("drive", "开车"), ("fly", "飞"),
        ("swim", "游泳"), ("sing", "唱"), ("dance", "跳舞"), ("cook", "做饭"),
        ("clean", "打扫"), ("fix", "修"), ("buy", "买"), ("sell", "卖"),
        ("give", "给"), ("take", "拿"), ("send", "发"), ("call", "打电话"),
        ("ask", "问"), ("tell", "告诉"), ("show", "展示"), ("explain", "解释"),
        ("check", "检查"), ("think", "想"), ("speak", "说"), ("move", "移动"),
        ("sit", "坐"), ("stand", "站"), ("open", "打开"), ("close", "关上"),
        ("turn", "转"), ("bring", "带来"), ("pay", "付钱"), ("meet", "见面"),
        ("visit", "拜访"), ("join", "加入"), ("follow", "跟随"),
    ],
    "verb_you_do": [
        ("help me", "帮我"), ("tell me", "告诉我"), ("show me", "给我看"),
        ("give me", "给我"), ("call me", "打电话给我"), ("send me", "发给我"),
        ("teach me", "教我"), ("wait for me", "等我"), ("come with me", "跟我来"),
        ("pick me up", "接我"), ("drop me off", "送我"),
        ("explain that", "解释一下"), ("repeat that", "重复一遍"),
        ("check this", "检查这个"), ("look at this", "看看这个"),
        ("listen to me", "听我说"), ("hear me out", "听我把话说完"),
        ("do me a favor", "帮我个忙"), ("do that", "做那个"),
        ("handle this", "处理这个"), ("take care of it", "处理一下"),
        ("keep it", "留着它"), ("hold on", "等一下"), ("hurry up", "快点"),
        ("slow down", "慢一点"), ("speak up", "大声点"), ("calm down", "冷静"),
        ("sit down", "坐下"), ("stand up", "站起来"), ("turn it on", "打开"),
        ("turn it off", "关掉"), ("open the door", "开门"),
        ("close the window", "关窗"), ("bring me", "给我带来"),
        ("pass me", "递给我"), ("lend me", "借给我"),
        ("forgive me", "原谅我"), ("trust me", "相信我"), ("believe me", "相信我"),
    ],
    "verb_you_do_q": [
        ("know", "知道"), ("think", "认为"), ("like", "喜欢"),
        ("want", "想要"), ("need", "需要"), ("see", "看到"),
        ("hear", "听到"), ("feel", "感觉"), ("believe", "相信"),
        ("understand", "理解"), ("remember", "记得"), ("agree", "同意"),
        ("live", "住"), ("work", "工作"), ("study", "学习"),
        ("speak", "说"), ("have", "有"), ("mean", "意思是"),
        ("say", "说"), ("do", "做"), ("eat", "吃"), ("drink", "喝"),
        ("sleep", "睡觉"), ("exercise", "锻炼"), ("cook", "做饭"),
        ("clean", "打扫"), ("drive", "开车"), ("travel", "旅行"),
        ("go", "去"), ("come", "来"), ("read", "读"), ("write", "写"),
        ("watch", "看"), ("listen", "听"), ("play", "玩"),
        ("talk", "说话"), ("call", "打电话"),
    ],
    "verb_ing": [
        ("going", "去"), ("staying", "留下"), ("leaving", "离开"),
        ("eating", "吃"), ("drinking", "喝"), ("sleeping", "睡觉"),
        ("resting", "休息"), ("talking", "聊天"), ("listening", "听"),
        ("watching", "看"), ("reading", "阅读"), ("writing", "写作"),
        ("learning", "学习"), ("studying", "学习"), ("teaching", "教"),
        ("helping", "帮助"), ("trying", "尝试"), ("working", "工作"),
        ("playing", "玩"), ("running", "跑步"), ("walking", "走路"),
        ("driving", "开车"), ("swimming", "游泳"), ("dancing", "跳舞"),
        ("singing", "唱歌"), ("cooking", "做饭"), ("cleaning", "打扫"),
        ("fixing", "修理"), ("buying", "买"), ("selling", "卖"),
        ("traveling", "旅行"), ("moving", "搬家"), ("waiting", "等待"),
        ("shopping", "购物"), ("hiking", "徒步"), ("camping", "露营"),
        ("fishing", "钓鱼"), ("gardening", "园艺"), ("painting", "画画"),
        ("drawing", "素描"), ("exercising", "锻炼"), ("meditating", "冥想"),
        ("practicing", "练习"), ("planning", "规划"), ("organizing", "整理"),
        ("calling", "打电话"), ("texting", "发短信"), ("chatting", "聊天"),
        ("thinking", "思考"), ("dreaming", "做梦"), ("saving", "节省"),
        ("spending", "花费"), ("investing", "投资"), ("exploring", "探索"),
        ("discovering", "发现"),
    ],
    "verb_ing_about": [
        ("going", "去"), ("staying", "留下"), ("eating out", "出去吃"),
        ("watching a movie", "看电影"), ("taking a walk", "散步"),
        ("having coffee", "喝咖啡"), ("getting lunch", "吃午饭"),
        ("meeting up", "见面"), ("calling her", "给她打电话"),
        ("trying again", "再试一次"), ("taking a break", "休息一下"),
        ("starting over", "重新开始"), ("moving on", "继续前进"),
        ("giving up", "放弃"), ("cooking at home", "在家做饭"),
        ("ordering pizza", "订披萨"), ("playing tennis", "打网球"),
        ("doing yoga", "做瑜伽"), ("listening to music", "听音乐"),
        ("reading a book", "读书"), ("traveling together", "一起旅行"),
        ("learning English", "学英语"),
        ("your help", "你的帮助"), ("your time", "你的时间"),
        ("your support", "你的支持"), ("the invite", "邀请"),
        ("the ride", "顺风车"), ("the advice", "建议"),
        ("the gift", "礼物"), ("the meal", "这顿饭"),
    ],
    "verb_done": [
        ("been there", "去过那里"), ("done that", "做过那个"),
        ("seen it", "看过"), ("heard that", "听说过"),
        ("tried it", "试过"), ("been to China", "去过中国"),
        ("been to Europe", "去过欧洲"), ("been to Japan", "去过日本"),
        ("been abroad", "出过国"), ("eaten sushi", "吃过寿司"),
        ("tried skydiving", "尝试过跳伞"), ("learned to swim", "学会了游泳"),
        ("ridden a horse", "骑过马"), ("climbed a mountain", "爬过山"),
        ("run a marathon", "跑过马拉松"), ("written a book", "写过书"),
        ("made a speech", "发表过演讲"), ("given a presentation", "做过演示"),
        ("taken a photo", "拍过照"), ("sent an email", "发过邮件"),
        ("called her", "给她打过电话"), ("met him", "见过他"),
        ("visited that place", "去过那个地方"), ("read that book", "读过那本书"),
        ("watched that movie", "看过那部电影"), ("heard that song", "听过那首歌"),
        ("played that game", "玩过那个游戏"), ("cooked a meal", "做过一顿饭"),
        ("fixed the problem", "解决过问题"), ("made a mistake", "犯过错"),
        ("lost something", "丢过东西"), ("won a prize", "获过奖"),
        ("failed an exam", "考砸过"), ("passed the test", "通过考试"),
        ("graduated", "毕业了"), ("started", "开始了"), ("finished", "完成了"),
        ("decided", "决定了"), ("thought about it", "考虑过"),
        ("talked about it", "谈过"),
    ],
    "adj_feeling": [
        ("happy", "高兴"), ("sad", "难过"), ("angry", "生气"),
        ("tired", "累"), ("excited", "兴奋"), ("nervous", "紧张"),
        ("worried", "担心"), ("scared", "害怕"), ("bored", "无聊"),
        ("busy", "忙"), ("free", "有空"), ("hungry", "饿"),
        ("thirsty", "渴"), ("full", "饱"), ("sick", "不舒服"),
        ("fine", "好"), ("great", "很棒"), ("wonderful", "非常好"),
        ("terrible", "糟糕"), ("awful", "糟糕透了"), ("stressed", "有压力"),
        ("relaxed", "放松"), ("calm", "平静"), ("anxious", "焦虑"),
        ("depressed", "沮丧"), ("lonely", "孤独"), ("proud", "自豪"),
        ("ashamed", "羞愧"), ("grateful", "感恩"), ("thankful", "感激"),
        ("hopeful", "充满希望"), ("hopeless", "绝望"), ("confused", "困惑"),
        ("surprised", "惊讶"), ("shocked", "震惊"), ("disappointed", "失望"),
        ("satisfied", "满意"), ("comfortable", "舒服"), ("uncomfortable", "不舒服"),
        ("cold", "冷"), ("hot", "热"), ("sleepy", "困"), ("awake", "醒着"),
        ("ready", "准备好了"), ("sure", "确定"), ("not sure", "不确定"),
        ("wrong", "错了"), ("right", "对了"), ("lucky", "幸运"),
        ("blessed", "幸运有福"), ("jealous", "嫉妒"), ("envious", "羡慕"),
        ("curious", "好奇"), ("interested", "感兴趣"), ("motivated", "有动力"),
        ("lazy", "懒"), ("brave", "勇敢"), ("afraid", "害怕"),
    ],
    "adj_describe": [
        ("good", "好"), ("bad", "坏"), ("nice", "不错"),
        ("beautiful", "漂亮"), ("ugly", "丑"), ("big", "大"),
        ("small", "小"), ("long", "长"), ("short", "短"),
        ("high", "高"), ("low", "低"), ("fast", "快"), ("slow", "慢"),
        ("easy", "容易"), ("hard", "难"), ("simple", "简单"),
        ("complex", "复杂"), ("new", "新"), ("old", "旧"),
        ("young", "年轻"), ("rich", "富有"), ("poor", "贫穷"),
        ("strong", "强"), ("weak", "弱"), ("heavy", "重"),
        ("light", "轻"), ("dark", "暗"), ("bright", "亮"),
        ("quiet", "安静"), ("noisy", "吵"), ("clean", "干净"),
        ("dirty", "脏"), ("safe", "安全"), ("dangerous", "危险"),
        ("important", "重要"), ("necessary", "必要"),
        ("possible", "可能的"), ("impossible", "不可能的"),
        ("true", "真的"), ("false", "假的"), ("real", "真实的"),
        ("fake", "假的"), ("clear", "清楚"), ("obvious", "明显"),
        ("strange", "奇怪"), ("normal", "正常"), ("special", "特别"),
        ("common", "常见"), ("rare", "稀有"), ("different", "不同"),
        ("same", "相同"), ("expensive", "贵"), ("cheap", "便宜"),
        ("delicious", "好吃"), ("amazing", "惊人"), ("interesting", "有趣"),
        ("boring", "无聊"), ("funny", "好笑"), ("serious", "严重"),
        ("useful", "有用"), ("useless", "没用"), ("convenient", "方便"),
        ("perfect", "完美"), ("fair", "公平"), ("unfair", "不公平"),
        ("natural", "自然"), ("popular", "受欢迎"), ("famous", "著名"),
        ("successful", "成功"), ("helpful", "有帮助"), ("harmful", "有害"),
        ("comfortable", "舒适"), ("reasonable", "合理"), ("ridiculous", "荒谬"),
    ],
    "adj_opinion": [
        ("good", "好"), ("bad", "坏"), ("great", "很棒"),
        ("terrible", "很糟"), ("wonderful", "很好"), ("awful", "糟糕"),
        ("nice", "不错"), ("important", "重要"), ("necessary", "必要的"),
        ("interesting", "有趣的"), ("boring", "无聊的"),
        ("difficult", "困难的"), ("easy", "容易的"),
        ("possible", "可能的"), ("impossible", "不可能的"),
        ("true", "真的"), ("fair", "公平的"), ("unfair", "不公平的"),
        ("right", "对的"), ("wrong", "错的"), ("strange", "奇怪的"),
        ("normal", "正常的"), ("weird", "怪异的"), ("crazy", "疯狂的"),
        ("ridiculous", "荒谬的"), ("amazing", "惊人的"),
        ("beautiful", "美丽的"), ("ugly", "丑陋的"),
        ("useful", "有用的"), ("useless", "没用的"),
        ("dangerous", "危险的"), ("safe", "安全的"),
        ("expensive", "贵的"), ("cheap", "便宜的"),
        ("worth it", "值得的"), ("a good idea", "一个好主意"),
        ("a bad idea", "一个坏主意"), ("too late", "太晚了"),
        ("too early", "太早了"), ("too much", "太多了"),
        ("too hard", "太难了"), ("too easy", "太容易了"),
    ],
    "clause_opinion": [
        ("it will rain tomorrow", "明天会下雨"),
        ("it's going to be fine", "一切都会好的"),
        ("everything will be okay", "一切都会好的"),
        ("we should go now", "我们现在该走了"),
        ("you are right", "你是对的"),
        ("he is coming", "他会来"),
        ("she will like it", "她会喜欢的"),
        ("they can make it", "他们能做到"),
        ("this is the best way", "这是最好的方法"),
        ("we need more time", "我们需要更多时间"),
        ("it's a good plan", "这是个好计划"),
        ("it's not working", "这不行"),
        ("there is a better way", "有更好的方法"),
        ("we are on the right track", "我们方向是对的"),
        ("this might be a problem", "这可能是个问题"),
        ("it's worth a try", "值得一试"),
        ("we have met before", "我们以前见过"),
        ("I can handle it", "我能处理"),
        ("it's not my business", "这不关我的事"),
        ("you should apologize", "你应该道歉"),
        ("this time is different", "这次不一样"),
        ("it's too late now", "现在太晚了"),
        ("we can work it out", "我们能解决"),
        ("it doesn't matter", "没关系"),
        ("I made the right choice", "我做了正确的选择"),
        ("things will get better", "事情会好起来的"),
        ("we should be careful", "我们应该小心"),
        ("it's a matter of time", "这只是时间问题"),
        ("he is telling the truth", "他说的是实话"),
        ("she has a point", "她说的有道理"),
        ("we are making progress", "我们正在进步"),
        ("something is wrong", "有什么不对劲"),
        ("it's a good sign", "这是个好兆头"),
        ("the worst is over", "最坏的已经过去了"),
        ("we are running out of time", "我们时间不多了"),
        ("you're making a mistake", "你正在犯错误"),
        ("this conversation is over", "这次谈话结束了"),
        ("it's not what it looks like", "事情不像看起来那样"),
        ("we've been through this before", "我们以前经历过这个"),
    ],
    "noun_person": [
        ("teacher", "老师"), ("student", "学生"), ("doctor", "医生"),
        ("nurse", "护士"), ("lawyer", "律师"), ("writer", "作家"),
        ("singer", "歌手"), ("dancer", "舞者"), ("cook", "厨师"),
        ("driver", "司机"), ("pilot", "飞行员"), ("soldier", "士兵"),
        ("police officer", "警察"), ("firefighter", "消防员"),
        ("scientist", "科学家"), ("researcher", "研究员"),
        ("professor", "教授"), ("journalist", "记者"),
        ("photographer", "摄影师"), ("designer", "设计师"),
        ("developer", "开发人员"), ("programmer", "程序员"),
        ("businessman", "商人"), ("manager", "经理"), ("boss", "老板"),
        ("leader", "领导者"), ("beginner", "初学者"),
        ("professional", "专业人士"), ("fan", "粉丝"), ("member", "会员"),
        ("father", "父亲"), ("mother", "母亲"), ("parent", "家长"),
        ("dreamer", "梦想家"), ("fighter", "斗士"), ("survivor", "幸存者"),
        ("winner", "赢家"), ("loser", "输家"),
    ],
    # ============================================================
    # NEW WORD BANKS for v3.0.0 — 13 categories, ~200 entries
    # ============================================================
    "verb_habit": [
        ("usually", "通常"), ("often", "经常"), ("always", "总是"),
        ("rarely", "很少"), ("never", "从不"), ("sometimes", "有时候"),
        ("generally", "一般"), ("normally", "正常情况"), ("occasionally", "偶尔"),
        ("regularly", "定期"), ("frequently", "频繁"), ("constantly", "不断"),
        ("hardly ever", "几乎从不"), ("almost always", "几乎总是"),
        ("every day", "每天"), ("once a week", "每周一次"),
    ],
    "clause_comfort": [
        ("everything will be fine", "一切都会好起来的"),
        ("it's not your fault", "这不是你的错"),
        ("you did your best", "你已经尽力了"),
        ("things happen", "这种事难免的"),
        ("don't worry about it", "别为这个担心"),
        ("it's okay", "没关系的"),
        ("take your time", "慢慢来"),
        ("you're not alone", "你不是一个人"),
        ("it could happen to anyone", "这种事谁都可能遇到"),
        ("you'll get through this", "你会挺过去的"),
        ("better luck next time", "下次好运"),
        ("don't take it too hard", "别太放在心上"),
        ("it will pass", "会过去的"),
        ("you'll be okay", "你会没事的"),
        ("I'm here for you", "我在这里陪着你"),
    ],
    "clause_explain": [
        ("I was stuck in traffic", "我被堵在路上了"),
        ("I didn't get the message", "我没收到消息"),
        ("the meeting ran late", "会议延长了"),
        ("I had an emergency", "我遇到了紧急情况"),
        ("my phone died", "我手机没电了"),
        ("I wasn't feeling well", "我不太舒服"),
        ("the train was delayed", "火车晚点了"),
        ("I got the time wrong", "我搞错时间了"),
        ("there was a misunderstanding", "有个误会"),
        ("I thought it was tomorrow", "我以为是明天"),
        ("I forgot to set the alarm", "我忘了设闹钟"),
        ("nobody told me about it", "没人告诉过我"),
        ("the system was down", "系统坏了"),
        ("I didn't have internet access", "我没有网络"),
        ("my car broke down", "我的车抛锚了"),
    ],
    "clause_suggest": [
        ("take a break", "休息一下"), ("call them back", "给他们回电话"),
        ("try a different approach", "试试别的方法"),
        ("sleep on it", "睡一觉再说"), ("ask for help", "寻求帮助"),
        ("do some research", "做些调研"), ("start from scratch", "从头开始"),
        ("double check", "再确认一下"), ("wait a bit longer", "再等一会儿"),
        ("talk to her directly", "直接跟她谈"), ("write it down", "写下来"),
        ("make a list", "列个清单"), ("set a deadline", "设个截止日期"),
        ("take notes", "做笔记"), ("practice more", "多练习"),
        ("apologize first", "先道歉"), ("be patient", "耐心点"),
        ("keep trying", "继续尝试"), ("focus on one thing", "专注一件事"),
    ],
    "verb_sense": [
        ("good", "很好"), ("bad", "不好"), ("strange", "很奇怪"),
        ("wonderful", "很棒"), ("terrible", "很糟糕"), ("delicious", "很好吃"),
        ("awful", "很可怕"), ("familiar", "很熟悉"), ("different", "不一样"),
        ("interesting", "很有趣"), ("weird", "很怪异"), ("amazing", "很惊人"),
        ("horrible", "很可怕"), ("fantastic", "很棒"),
        ("like a good idea", "像个好主意"), ("like trouble", "像麻烦"),
        ("like the right thing", "像是对的事"), ("like home", "像家一样"),
        ("like a dream", "像梦一样"), ("like forever", "像永远"),
    ],
    "noun_purpose": [
        ("learn English", "学英语"), ("get a better job", "找到更好的工作"),
        ("save money", "省钱"), ("stay healthy", "保持健康"),
        ("make friends", "交朋友"), ("improve my skills", "提升技能"),
        ("have fun", "开心"), ("relax", "放松"),
        ("spend time with family", "陪家人"), ("see the world", "看世界"),
        ("experience new things", "体验新事物"), ("help others", "帮助别人"),
        ("find a solution", "找到解决方案"), ("get some exercise", "锻炼身体"),
        ("clear my mind", "清空思绪"), ("gain experience", "积累经验"),
        ("build my career", "发展事业"), ("make a difference", "有所作为"),
    ],
    "noun_advantage": [
        ("you can save time", "可以节省时间"), ("you learn faster", "学得更快"),
        ("it's more convenient", "更方便"), ("you have more freedom", "有更多自由"),
        ("it's cheaper", "更便宜"), ("there's less stress", "压力更小"),
        ("you meet new people", "认识新的人"), ("it's better for your health", "对健康更好"),
        ("you gain experience", "获得经验"), ("quality is higher", "质量更高"),
        ("it's more flexible", "更灵活"), ("the location is great", "位置很好"),
        ("you can work from home", "可以在家工作"),
        ("there's room for growth", "有成长空间"),
        ("the hours are better", "工作时间更好"),
    ],
    "noun_interest": [
        ("photography", "摄影"), ("cooking", "烹饪"), ("gardening", "园艺"),
        ("painting", "绘画"), ("playing guitar", "弹吉他"), ("hiking", "徒步"),
        ("traveling", "旅行"), ("reading", "阅读"), ("writing", "写作"),
        ("coding", "编程"), ("yoga", "瑜伽"), ("meditation", "冥想"),
        ("swimming", "游泳"), ("dancing", "跳舞"), ("fishing", "钓鱼"),
        ("chess", "下棋"), ("volunteering", "志愿服务"),
        ("learning languages", "学语言"), ("collecting stamps", "集邮"),
        ("DIY projects", "DIY项目"), ("video games", "电子游戏"),
        ("watching movies", "看电影"), ("blogging", "写博客"),
    ],
    "clause_apology": [
        ("I'm late", "我迟到了"),
        ("I forgot your birthday", "我忘了你的生日"),
        ("I didn't call back", "我没有回电话"),
        ("I broke your cup", "我打碎了你的杯子"),
        ("I said the wrong thing", "我说了不该说的话"),
        ("I missed the deadline", "我错过了截止日期"),
        ("I didn't mean to hurt you", "我不是故意伤害你的"),
        ("I wasn't paying attention", "我当时没注意"),
        ("I overreacted", "我反应过度了"),
        ("the mistake was mine", "错误在我"),
        ("I let you down", "我让你失望了"),
        ("I should have told you earlier", "我应该早点告诉你"),
        ("I was wrong about that", "那件事我错了"),
        ("I didn't keep my promise", "我没有遵守承诺"),
        ("I shouldn't have said that", "我不该说那些话"),
    ],
    "noun_time": [
        ("a few minutes", "几分钟"), ("an hour", "一个小时"),
        ("a long time", "很长时间"), ("ages", "很久"), ("a while", "一会儿"),
        ("all day", "一整天"), ("the whole morning", "整个上午"),
        ("about a week", "大约一周"), ("a couple of days", "几天"),
        ("several months", "几个月"), ("a year", "一年"),
        ("forever", "永远"), ("a second", "一秒"), ("a moment", "片刻"),
        ("quite some time", "相当长时间"), ("half an hour", "半小时"),
    ],
    "clause_talk": [
        ("the new project", "新项目"), ("what happened yesterday", "昨天发生的事"),
        ("the upcoming meeting", "即将到来的会议"),
        ("our travel plans", "我们的旅行计划"), ("the budget issue", "预算问题"),
        ("the company news", "公司的消息"), ("last night's game", "昨晚的比赛"),
        ("the weather", "天气"), ("the movie we watched", "我们看的那部电影"),
        ("the problem we're facing", "我们面临的问题"),
        ("what she said", "她说的话"), ("the good news", "好消息"),
        ("the new restaurant", "那家新餐厅"),
        ("the changes at work", "工作上的变化"),
        ("next week's deadline", "下周的截止日期"),
    ],
    "verb_eating": [
        ("try the dessert", "尝尝甜点"), ("order another drink", "再点一杯饮料"),
        ("have some more rice", "再吃点米饭"), ("taste this dish", "尝尝这道菜"),
        ("grab a coffee", "买杯咖啡"), ("have lunch together", "一起吃午饭"),
        ("try the special", "试试特色菜"), ("finish your plate", "把盘子里的吃完"),
        ("share a pizza", "分享一个披萨"), ("drink some water", "喝点水"),
        ("eat more vegetables", "多吃蔬菜"), ("enjoy your meal", "享受美食"),
        ("try the local food", "尝尝当地美食"), ("cook something", "做点吃的"),
        ("skip breakfast", "不吃早餐"), ("get a refill", "续杯"),
    ],
    "clause_invite": [
        ("join us for dinner", "和我们一起吃晚饭"),
        ("come to my party", "来参加我的派对"),
        ("have lunch with me", "和我一起吃午饭"),
        ("see a movie together", "一起看电影"),
        ("go for a walk", "去散步"), ("visit my place", "来我家做客"),
        ("attend the event", "参加活动"), ("join our team", "加入我们团队"),
        ("be my guest", "来做客"), ("come along", "一起来吧"),
        ("hang out this weekend", "这周末一起玩"),
        ("grab a coffee sometime", "改天一起喝咖啡"),
        ("stop by later", "晚点过来"), ("celebrate with us", "和我们一起庆祝"),
        ("stay for dinner", "留下来吃晚饭"),
    ],
}

# ============================================================
# PATTERN DATABASE
# ============================================================
PATTERNS = [
    ("p001", "there is no", "There is / are / was / were / will be (no)...", "noun_exist_no", "There is no", "There is no + noun"),
    ("p002", "there is a", "There is / are / was / were a / an / some...", "noun_exist_a", "There is a", "There is a + noun"),
    ("p003", "there are", "There is / are / was / were / will be...", "noun_exist_pl", "There are", "There are + plural noun"),
    ("p004", "there was no", "There is / are / was / were / will be (no)...", "noun_exist_no", "There was no", "There was no + noun"),
    ("p005", "there were no", "There is / are / was / were / will be (no)...", "noun_exist_pl_no", "There were no", "There were no + plural"),
    ("p006", "there will be", "There is / are / was / were / will be...", "noun_exist_a", "There will be", "There will be + noun"),
    ("p007", "there is", "There is / are / was / were / will be...", "noun_exist_a", "There is", "There is + noun"),
    ("p008", "there's no", "There is / are / was / were / will be (no)...", "noun_exist_no", "There is no", "There is no + noun"),
    ("p009", "there's a", "There is / are / was / were a / an / some...", "noun_exist_a", "There is a", "There is a + noun"),
    ("p010", "i have a", "I have / had / will have / 've got a / an...", "noun_have_a", "I have a", "I have a + noun"),
    ("p011", "i have no", "I have / had / will have / 've got no...", "noun_exist_no", "I have no", "I have no + noun"),
    ("p012", "i have", "I have / had / will have / 've got...", "noun_have_pl", "I have", "I have + noun"),
    ("p013", "i don't have", "I have / had / don't have...", "noun_have_a", "I don't have", "I don't have + noun"),
    ("p014", "i had a", "I have / had / will have / 've got a / an...", "noun_have_a", "I had a", "I had a + noun"),
    ("p015", "i've got a", "I have / had / will have / 've got a / an...", "noun_have_a", "I've got a", "I've got a + noun"),
    ("p016", "i've got no", "I have / had / will have / 've got no...", "noun_exist_no", "I've got no", "I've got no + noun"),
    ("p020", "i want to", "I want / wanted / would like / 'd like to...", "verb_to_do", "I want to", "I want to + verb"),
    ("p021", "i want a", "I want / wanted / would like / 'd like a / an...", "noun_have_a", "I want a", "I want a + noun"),
    ("p022", "i want", "I want / wanted / would like / 'd like...", "noun_have_a", "I want", "I want + noun"),
    ("p023", "i would like to", "I want / wanted / would like / 'd like to...", "verb_to_do", "I would like to", "I would like to + verb"),
    ("p024", "i'd like to", "I want / wanted / would like / 'd like to...", "verb_to_do", "I'd like to", "I'd like to + verb"),
    ("p025", "i'd like a", "I want / wanted / would like / 'd like a / an...", "noun_have_a", "I'd like a", "I'd like a + noun"),
    ("p026", "i feel like", "I feel like (doing)...", "verb_ing", "I feel like", "I feel like + verb-ing"),
    ("p030", "i can", "I can / could / can't / couldn't...", "verb_base", "I can", "I can + verb"),
    ("p031", "i can't", "I can / could / can't / couldn't...", "verb_base", "I can't", "I can't + verb"),
    ("p032", "i could", "I can / could / can't / couldn't...", "verb_base", "I could", "I could + verb"),
    ("p033", "i cannot", "I can / could / can't / couldn't...", "verb_base", "I cannot", "I cannot + verb"),
    ("p040", "can you", "Can / Could / Will / Would you...?", "verb_you_do", "Can you", "Can you + verb?"),
    ("p041", "could you", "Can / Could / Will / Would you...?", "verb_you_do", "Could you", "Could you + verb?"),
    ("p042", "will you", "Can / Could / Will / Would you...?", "verb_you_do", "Will you", "Will you + verb?"),
    ("p043", "would you", "Can / Could / Will / Would you...?", "verb_you_do", "Would you", "Would you + verb?"),
    ("p050", "i think", "I think / believe / guess / suppose / feel (that)...", "clause_opinion", "I think", "I think + clause"),
    ("p051", "i think it's", "I think / believe / guess / suppose it's...", "adj_opinion", "I think it's", "I think it's + adjective"),
    ("p052", "i believe", "I think / believe / guess / suppose / feel (that)...", "clause_opinion", "I believe", "I believe + clause"),
    ("p053", "i don't think", "I think / believe / guess / suppose...", "clause_opinion", "I don't think", "I don't think + clause"),
    ("p054", "i guess", "I think / believe / guess / suppose / feel (that)...", "clause_opinion", "I guess", "I guess + clause"),
    ("p055", "in my opinion", "In my opinion / view...", "clause_opinion", "In my opinion,", "In my opinion, + clause"),
    ("p060", "it is", "It is / was / will be / seems / looks...", "adj_describe", "It is", "It is + adjective"),
    ("p061", "it's", "It is / was / will be / seems / looks...", "adj_describe", "It's", "It's + adjective"),
    ("p062", "it was", "It is / was / will be / seems / looks...", "adj_describe", "It was", "It was + adjective"),
    ("p063", "it seems", "It is / was / will be / seems / looks...", "adj_describe", "It seems", "It seems + adjective"),
    ("p064", "it looks", "It is / was / will be / seems / looks...", "adj_describe", "It looks", "It looks + adjective"),
    ("p065", "it's not", "It is / was / will be / seems / looks (not)...", "adj_describe", "It's not", "It's not + adjective"),
    ("p066", "it's too", "It is / was too...", "adj_describe", "It's too", "It's too + adjective"),
    ("p067", "it's a", "It is / was / will be a / an...", "noun_have_a", "It's a", "It's a + noun"),
    ("p070", "i need to", "I need / must / have to / should...", "verb_to_do", "I need to", "I need to + verb"),
    ("p071", "i need a", "I need / must / have to / should...", "noun_have_a", "I need a", "I need a + noun"),
    ("p072", "i need", "I need / must / have to / should...", "noun_have_pl", "I need", "I need + noun"),
    ("p073", "i have to", "I need / must / have to / should...", "verb_to_do", "I have to", "I have to + verb"),
    ("p074", "i must", "I need / must / have to / should...", "verb_base", "I must", "I must + verb"),
    ("p075", "i should", "I need / must / have to / should...", "verb_base", "I should", "I should + verb"),
    ("p076", "you should", "You should / shouldn't / must / need to...", "verb_base", "You should", "You should + verb"),
    ("p080", "i like", "I like / love / enjoy / prefer...", "noun_have_pl", "I like", "I like + noun/gerund"),
    ("p081", "i like to", "I like / love / enjoy / prefer to...", "verb_to_do", "I like to", "I like to + verb"),
    ("p082", "i love", "I like / love / enjoy / prefer...", "noun_have_pl", "I love", "I love + noun/gerund"),
    ("p083", "i love to", "I like / love / enjoy / prefer to...", "verb_to_do", "I love to", "I love to + verb"),
    ("p084", "i enjoy", "I like / love / enjoy / prefer...", "verb_ing", "I enjoy", "I enjoy + verb-ing"),
    ("p085", "i prefer", "I like / love / enjoy / prefer...", "noun_have_pl", "I prefer", "I prefer + noun"),
    ("p086", "i prefer to", "I like / love / enjoy / prefer to...", "verb_to_do", "I prefer to", "I prefer to + verb"),
    ("p087", "i don't like", "I like / love / enjoy / prefer...", "noun_have_pl", "I don't like", "I don't like + noun"),
    ("p088", "i'm into", "I like / love / enjoy / prefer / 'm into...", "noun_have_pl", "I'm into", "I'm into + noun/gerund"),
    ("p090", "i hope", "I hope / wish...", "clause_opinion", "I hope", "I hope + clause"),
    ("p091", "i wish", "I hope / wish...", "clause_opinion", "I wish", "I wish + clause"),
    ("p092", "i hope to", "I hope / wish / want to...", "verb_to_do", "I hope to", "I hope to + verb"),
    ("p100", "i'm", "I'm / I am / He's / She's / They're...", "adj_feeling", "I'm", "I'm + adjective"),
    ("p101", "i'm not", "I'm / I am (not)...", "adj_feeling", "I'm not", "I'm not + adjective"),
    ("p102", "i'm a", "I'm / I am a / an...", "noun_person", "I'm a", "I'm a + profession"),
    ("p103", "i'm feeling", "I'm / I am feeling...", "adj_feeling", "I'm feeling", "I'm feeling + adjective"),
    ("p104", "i am", "I'm / I am...", "adj_feeling", "I am", "I am + adjective"),
    ("p110", "i'm going to", "I'm going to / I will / I'll / I'm about to...", "verb_to_do", "I'm going to", "I'm going to + verb"),
    ("p111", "i will", "I'm going to / I will / I'll / I'm about to...", "verb_base", "I will", "I will + verb"),
    ("p112", "i'll", "I'm going to / I will / I'll / I'm about to...", "verb_base", "I'll", "I'll + verb"),
    ("p113", "i'm about to", "I'm going to / I will / I'll / I'm about to...", "verb_to_do", "I'm about to", "I'm about to + verb"),
    ("p114", "i plan to", "I plan to / intend to...", "verb_to_do", "I plan to", "I plan to + verb"),
    ("p120", "i've", "I've / I have / I haven't (done)...", "verb_done", "I've", "I've + past participle"),
    ("p121", "i've never", "I've / I have never (done)...", "verb_done", "I've never", "I've never + past participle"),
    ("p122", "i haven't", "I've / I have / I haven't (done)...", "verb_done", "I haven't", "I haven't + past participle"),
    ("p123", "have you ever", "Have you ever (done)...?", "verb_done", "Have you ever", "Have you ever + past participle?"),
    ("p124", "have you", "Have you (done)...?", "verb_done", "Have you", "Have you + past participle?"),
    ("p130", "i used to", "I used to / I'm used to...", "verb_base", "I used to", "I used to + verb"),
    ("p131", "i'm used to", "I used to / I'm used to...", "verb_ing", "I'm used to", "I'm used to + verb-ing"),
    ("p132", "i get used to", "I get used to...", "verb_ing", "I get used to", "I get used to + verb-ing"),
    ("p140", "how do you", "How / What / When / Where / Why do you...?", "verb_you_do_q", "How do you", "How do you + verb?"),
    ("p141", "what do you", "How / What / When / Where / Why do you...?", "verb_you_do_q", "What do you", "What do you + verb?"),
    ("p142", "why do you", "How / What / When / Where / Why do you...?", "verb_you_do_q", "Why do you", "Why do you + verb?"),
    ("p143", "where can i", "Where can I...?", "verb_base", "Where can I", "Where can I + verb?"),
    ("p144", "how can i", "How can I...?", "verb_base", "How can I", "How can I + verb?"),
    ("p145", "how about", "How about / What about...?", "verb_ing_about", "How about", "How about + verb-ing?"),
    ("p146", "what about", "How about / What about...?", "verb_ing_about", "What about", "What about + verb-ing?"),
    ("p150", "let's", "Let's / Let me / Let us...", "verb_base", "Let's", "Let's + verb"),
    ("p151", "let me", "Let's / Let me / Let us...", "verb_base", "Let me", "Let me + verb"),
    ("p152", "don't", "Don't / Never / Always...", "verb_base", "Don't", "Don't + verb"),
    ("p153", "please", "Please / Please don't...", "verb_base", "Please", "Please + verb"),
    ("p160", "this is", "This is / That is / These are / Those are...", "adj_describe", "This is", "This is + adj/noun"),
    ("p161", "that is", "This is / That is / These are / Those are...", "adj_describe", "That is", "That is + adj/noun"),
    ("p162", "that's", "This is / That is / These are / Those are...", "adj_describe", "That's", "That's + adj/noun"),
    ("p163", "this is a", "This is / That is a / an...", "noun_have_a", "This is a", "This is a + noun"),
    ("p164", "that's a", "This is / That is a / an...", "noun_have_a", "That's a", "That's a + noun"),
    ("p170", "i'm trying to", "I'm trying to / working on / looking for...", "verb_to_do", "I'm trying to", "I'm trying to + verb"),
    ("p171", "i'm looking for", "I'm trying to / working on / looking for...", "noun_have_a", "I'm looking for", "I'm looking for + noun"),
    ("p172", "i'm working on", "I'm trying to / working on / looking for...", "noun_have_a", "I'm working on", "I'm working on + noun"),
    ("p173", "i'm thinking about", "I'm thinking about / considering...", "verb_ing", "I'm thinking about", "I'm thinking about + verb-ing"),
    ("p180", "i'm sorry", "I'm sorry / I'm afraid / I'm glad / I'm happy...", "clause_opinion", "I'm sorry,", "I'm sorry, + clause"),
    ("p181", "i'm afraid", "I'm sorry / I'm afraid / I'm glad / I'm happy...", "clause_opinion", "I'm afraid", "I'm afraid + clause"),
    ("p182", "i'm glad", "I'm sorry / I'm afraid / I'm glad / I'm happy...", "clause_opinion", "I'm glad", "I'm glad + clause"),
    ("p183", "i'm surprised", "I'm surprised / shocked / amazed...", "clause_opinion", "I'm surprised", "I'm surprised + clause"),
    ("p184", "i'm sure", "I'm sure / certain / positive...", "clause_opinion", "I'm sure", "I'm sure + clause"),
    ("p190", "do you", "Do you / Did you / Does he...?", "verb_you_do_q", "Do you", "Do you + verb?"),
    ("p191", "do you like", "Do you like / love / enjoy...?", "noun_have_pl", "Do you like", "Do you like + noun?"),
    ("p192", "did you", "Do you / Did you / Does he...?", "verb_you_do_q", "Did you", "Did you + verb?"),
    ("p193", "do you want to", "Do you want to / need to...?", "verb_to_do", "Do you want to", "Do you want to + verb?"),
    ("p194", "do you think", "Do you think / believe...?", "clause_opinion", "Do you think", "Do you think + clause?"),
    ("p200", "it's important", "It's important / necessary / essential / vital to...", "verb_to_do", "It's important to", "It's important to + verb"),
    ("p201", "it's necessary", "It's important / necessary / essential / vital to...", "verb_to_do", "It's necessary to", "It's necessary to + verb"),
    ("p202", "it's hard", "It's hard / difficult / easy / impossible to...", "verb_to_do", "It's hard to", "It's hard to + verb"),
    ("p203", "it's easy", "It's hard / difficult / easy / impossible to...", "verb_to_do", "It's easy to", "It's easy to + verb"),
    ("p204", "it's time", "It's time to...", "verb_to_do", "It's time to", "It's time to + verb"),
    ("p210", "i remember", "I remember / forget / recall...", "verb_ing", "I remember", "I remember + verb-ing"),
    ("p211", "i forget", "I remember / forget / recall...", "verb_ing", "I forget", "I forget + verb-ing"),
    ("p212", "i forgot", "I remember / forget / forgot / recall...", "verb_to_do", "I forgot to", "I forgot to + verb"),
    ("p220", "thank you", "Thank you / Thanks for...", "verb_ing_about", "Thank you for", "Thank you for + noun/verb-ing"),
    ("p221", "thanks for", "Thank you / Thanks for...", "verb_ing_about", "Thanks for", "Thanks for + noun/verb-ing"),
    ("p222", "i appreciate", "I appreciate / I'm grateful for...", "verb_ing_about", "I appreciate", "I appreciate + noun/verb-ing"),
    ("p230", "if i", "If I / you / we...", "verb_base", "If I", "If I + verb"),
    ("p231", "if you", "If I / you / we...", "verb_base", "If you", "If you + verb"),
    ("p232", "if i had", "If I had / were / could...", "noun_have_pl", "If I had", "If I had + noun"),
    ("p233", "if i were you", "If I were you / If I were in your shoes...", "clause_opinion", "If I were you, I would", "If I were you, I would + clause"),
    ("p240", "one of", "One of / Some of / Most of / All of...", "noun_have_pl", "One of", "One of + plural noun"),
    ("p241", "some of", "One of / Some of / Most of / All of...", "noun_have_pl", "Some of", "Some of + plural noun"),
    ("p242", "most of", "One of / Some of / Most of / All of...", "noun_have_pl", "Most of", "Most of + plural noun"),
    ("p243", "a lot of", "A lot of / Lots of / Plenty of...", "noun_have_pl", "A lot of", "A lot of + noun"),
    ("p244", "plenty of", "A lot of / Lots of / Plenty of...", "noun_have_pl", "Plenty of", "Plenty of + noun"),
    ("p250", "i was", "I was / He was / They were...", "adj_feeling", "I was", "I was + adjective"),
    ("p251", "i was a", "I was a / an...", "noun_person", "I was a", "I was a + noun"),
    ("p252", "i was going to", "I was going to / about to...", "verb_to_do", "I was going to", "I was going to + verb"),
    ("p260", "i've been", "I've been / I've had / It's been...", "verb_ing", "I've been", "I've been + verb-ing"),
    ("p261", "i've been a", "I've been a / an...", "noun_person", "I've been a", "I've been a + noun"),
    ("p262", "i've had", "I've been / I've had / It's been...", "noun_have_pl", "I've had", "I've had + noun"),
    ("p270", "i'm looking forward to", "I'm looking forward to...", "verb_ing", "I'm looking forward to", "I'm looking forward to + verb-ing"),
    ("p271", "i look forward to", "I look forward to...", "verb_ing", "I look forward to", "I look forward to + verb-ing"),
    ("p280", "i wonder", "I wonder / I'm wondering / I was wondering...", "clause_opinion", "I wonder", "I wonder + clause"),
    ("p281", "i was wondering", "I wonder / I'm wondering / I was wondering...", "clause_opinion", "I was wondering", "I was wondering + clause"),
    ("p290", "i'd rather", "I'd rather / I'd better / I prefer to...", "verb_base", "I'd rather", "I'd rather + verb"),
    ("p291", "i'd better", "I'd rather / I'd better / I prefer to...", "verb_base", "I'd better", "I'd better + verb"),
    ("p292", "you'd better", "You'd better / You'd rather...", "verb_base", "You'd better", "You'd better + verb"),
    ("p300", "he is", "He is / She is / It is / They are...", "adj_feeling", "He is", "He is + adjective"),
    ("p301", "she is", "He is / She is / It is / They are...", "adj_feeling", "She is", "She is + adjective"),
    ("p302", "they are", "He is / She is / It is / They are...", "adj_feeling", "They are", "They are + adjective"),
    ("p303", "he's a", "He is / She is a / an...", "noun_person", "He's a", "He's a + noun"),
    ("p304", "she's a", "He is / She is a / an...", "noun_person", "She's a", "She's a + noun"),
    ("p310", "i get", "I get / become / feel / turn...", "adj_feeling", "I get", "I get + adjective"),
    ("p311", "i feel", "I get / become / feel / turn...", "adj_feeling", "I feel", "I feel + adjective"),
    # ============================================================
    # NEW PATTERNS for v3.0.0 — ~170 patterns, 23 categories
    # ============================================================
    # --- 1. 习惯 Habits (p312-p319) ---
    ("p312", "i usually", "I usually / often / always / rarely / never / sometimes...", "verb_base", "I usually", "I usually + verb"),
    ("p313", "i often", "I usually / often / always / rarely / never / sometimes...", "verb_base", "I often", "I often + verb"),
    ("p314", "i always", "I usually / often / always / rarely / never / sometimes...", "verb_base", "I always", "I always + verb"),
    ("p315", "i rarely", "I usually / often / always / rarely / never / sometimes...", "verb_base", "I rarely", "I rarely + verb"),
    ("p316", "i never", "I usually / often / always / rarely / never / sometimes...", "verb_base", "I never", "I never + verb"),
    ("p317", "i sometimes", "I usually / often / always / rarely / never / sometimes...", "verb_base", "I sometimes", "I sometimes + verb"),
    ("p318", "i tend to", "I tend to...", "verb_to_do", "I tend to", "I tend to + verb"),
    ("p319", "i'm accustomed to", "I'm accustomed to...", "verb_ing", "I'm accustomed to", "I'm accustomed to + verb-ing"),
    # --- 2. 目的 Purpose (p320-p325) ---
    ("p320", "i came here to", "I came here to / I'm here to...", "verb_to_do", "I came here to", "I came here to + verb"),
    ("p321", "in order to", "In order to / So as to...", "verb_to_do", "In order to", "In order to + verb"),
    ("p322", "so that i can", "So that I can / So that we can...", "verb_base", "So that I can", "So that I can + verb"),
    ("p323", "the reason i'm here is to", "The reason I'm here is to...", "verb_to_do", "The reason I'm here is to", "The reason I'm here is to + verb"),
    ("p324", "my goal is to", "My goal is to / My aim is to...", "verb_to_do", "My goal is to", "My goal is to + verb"),
    ("p325", "i'm doing this to", "I'm doing this to...", "verb_to_do", "I'm doing this to", "I'm doing this to + verb"),
    # --- 3. 安慰 Comfort (p326-p333) ---
    ("p326", "don't worry", "Don't worry / Don't be afraid...", "clause_comfort", "Don't worry,", "Don't worry, + clause"),
    ("p327", "it's okay", "It's okay / It's alright...", "clause_comfort", "It's okay,", "It's okay, + clause"),
    ("p328", "i understand", "I understand / I know...", "clause_comfort", "I understand,", "I understand, + clause"),
    ("p329", "you'll be fine", "You'll be fine / You'll be okay...", "clause_comfort", "You'll be fine,", "You'll be fine, + clause"),
    ("p330", "cheer up", "Cheer up / Chin up...", "clause_comfort", "Cheer up,", "Cheer up, + clause"),
    ("p331", "take it easy", "Take it easy / Relax...", "clause_comfort", "Take it easy,", "Take it easy, + clause"),
    ("p332", "i'm here for you", "I'm here for you / I've got your back...", "clause_comfort", "I'm here for you,", "I'm here for you, + clause"),
    ("p333", "it's not the end of the world", "It's not the end of the world...", "clause_comfort", "It's not the end of the world,", "It's not the end of the world, + clause"),
    # --- 4. 感谢 Gratitude (p334-p336) ---
    ("p334", "i'm grateful for", "I'm grateful for / I'm thankful for...", "noun_have_pl", "I'm grateful for", "I'm grateful for + noun"),
    ("p335", "i owe you one for", "I owe you one for...", "verb_ing_about", "I owe you one for", "I owe you one for + noun/verb-ing"),
    ("p336", "much appreciated for", "Much appreciated for...", "verb_ing_about", "Much appreciated for", "Much appreciated for + noun/verb-ing"),
    # --- 5. 期待 Anticipation (p337-p340) ---
    ("p337", "i can't wait to", "I can't wait to...", "verb_to_do", "I can't wait to", "I can't wait to + verb"),
    ("p338", "i'm counting on", "I'm counting on...", "verb_ing", "I'm counting on", "I'm counting on + verb-ing"),
    ("p339", "i'm excited about", "I'm excited about...", "verb_ing", "I'm excited about", "I'm excited about + verb-ing"),
    ("p340", "i'm eager to", "I'm eager to / I'm dying to...", "verb_to_do", "I'm eager to", "I'm eager to + verb"),
    # --- 6. 喜好 Preferences (p341-p343) ---
    ("p341", "i'm fond of", "I'm fond of...", "verb_ing", "I'm fond of", "I'm fond of + verb-ing"),
    ("p342", "i'm crazy about", "I'm crazy about...", "verb_ing", "I'm crazy about", "I'm crazy about + verb-ing"),
    ("p343", "i'm a big fan of", "I'm a big fan of...", "noun_have_pl", "I'm a big fan of", "I'm a big fan of + noun"),
    # --- 7. 感官 Senses (p344-p351) ---
    ("p344", "it sounds", "It sounds / tastes / smells / feels...", "verb_sense", "It sounds", "It sounds + adjective"),
    ("p345", "it tastes", "It sounds / tastes / smells / feels...", "verb_sense", "It tastes", "It tastes + adjective"),
    ("p346", "it smells", "It sounds / tastes / smells / feels...", "verb_sense", "It smells", "It smells + adjective"),
    ("p347", "it feels", "It sounds / tastes / smells / feels...", "verb_sense", "It feels", "It feels + adjective"),
    ("p348", "that sounds like", "That sounds / looks / seems like...", "verb_sense", "That sounds like", "That sounds like + noun"),
    ("p349", "it looks like", "It looks like / It seems like...", "verb_sense", "It looks like", "It looks like + noun"),
    ("p350", "it seems like", "It seems like / It feels like...", "clause_opinion", "It seems like", "It seems like + clause"),
    ("p351", "i have a feeling that", "I have a feeling that...", "clause_opinion", "I have a feeling that", "I have a feeling that + clause"),
    # --- 8. 解释 Explanation (p352-p359) ---
    ("p352", "the reason is that", "The reason is that / The reason was that...", "clause_explain", "The reason is that", "The reason is that + clause"),
    ("p353", "that's because", "That's because...", "clause_explain", "That's because", "That's because + clause"),
    ("p354", "let me explain", "Let me explain...", "clause_explain", "Let me explain,", "Let me explain, + clause"),
    ("p355", "this is why", "This is why...", "clause_explain", "This is why", "This is why + clause"),
    ("p356", "what i mean is", "What I mean is...", "clause_opinion", "What I mean is", "What I mean is + clause"),
    ("p357", "the thing is", "The thing is...", "clause_explain", "The thing is", "The thing is + clause"),
    ("p358", "as it turns out", "As it turns out...", "clause_explain", "As it turns out,", "As it turns out, + clause"),
    ("p359", "to be honest", "To be honest / Frankly / Honestly...", "clause_opinion", "To be honest,", "To be honest, + clause"),
    # --- 9. 观点 Opinions (p360-p363) ---
    ("p360", "as far as i'm concerned", "As far as I'm concerned...", "clause_opinion", "As far as I'm concerned,", "As far as I'm concerned, + clause"),
    ("p361", "from my perspective", "From my perspective / From my point of view...", "clause_opinion", "From my perspective,", "From my perspective, + clause"),
    ("p362", "personally, i think", "Personally, I think...", "clause_opinion", "Personally, I think", "Personally, I think + clause"),
    ("p363", "if you ask me", "If you ask me...", "clause_opinion", "If you ask me,", "If you ask me, + clause"),
    # --- 10. 建议 Suggestions (p364-p373) ---
    ("p364", "i suggest you", "I suggest you / I recommend you...", "verb_base", "I suggest you", "I suggest you + verb"),
    ("p365", "why don't you", "Why don't you...?", "verb_base", "Why don't you", "Why don't you + verb?"),
    ("p366", "you might want to", "You might want to / You may want to...", "verb_to_do", "You might want to", "You might want to + verb"),
    ("p367", "it might be better to", "It might be better to...", "verb_to_do", "It might be better to", "It might be better to + verb"),
    ("p368", "have you considered", "Have you considered...?", "verb_ing", "Have you considered", "Have you considered + verb-ing?"),
    ("p369", "if i were you, i'd", "If I were you, I'd...", "verb_base", "If I were you, I'd", "If I were you, I'd + verb"),
    ("p370", "i recommend", "I recommend...", "verb_ing", "I recommend", "I recommend + verb-ing"),
    ("p371", "you could try", "You could try...", "verb_ing", "You could try", "You could try + verb-ing"),
    ("p372", "the best thing to do is", "The best thing to do is...", "verb_to_do", "The best thing to do is", "The best thing to do is + verb"),
    ("p373", "you have nothing to lose by", "You have nothing to lose by...", "verb_ing", "You have nothing to lose by", "You have nothing to lose by + verb-ing"),
    # --- 11. 计划 Plans (p374-p376) ---
    ("p374", "i intend to", "I intend to / I aim to...", "verb_to_do", "I intend to", "I intend to + verb"),
    ("p375", "i'm planning on", "I'm planning on...", "verb_ing", "I'm planning on", "I'm planning on + verb-ing"),
    ("p376", "my plan is to", "My plan is to...", "verb_to_do", "My plan is to", "My plan is to + verb"),
    # --- 12. 提醒 Reminders (p377-p384) ---
    ("p377", "don't forget to", "Don't forget to...", "verb_to_do", "Don't forget to", "Don't forget to + verb"),
    ("p378", "remember to", "Remember to...", "verb_to_do", "Remember to", "Remember to + verb"),
    ("p379", "make sure you", "Make sure you / Ensure you...", "verb_base", "Make sure you", "Make sure you + verb"),
    ("p380", "keep in mind that", "Keep in mind that / Bear in mind that...", "clause_opinion", "Keep in mind that", "Keep in mind that + clause"),
    ("p381", "just a reminder", "Just a reminder...", "clause_opinion", "Just a reminder,", "Just a reminder, + clause"),
    ("p382", "be sure to", "Be sure to / Make sure to...", "verb_to_do", "Be sure to", "Be sure to + verb"),
    ("p383", "i want to remind you", "I want to remind you...", "clause_opinion", "I want to remind you,", "I want to remind you, + clause"),
    ("p384", "don't miss", "Don't miss...", "noun_have_a", "Don't miss", "Don't miss + noun"),
    # --- 13. 优点 Advantages (p385-p390) ---
    ("p385", "the advantage is that", "The advantage is that...", "noun_advantage", "The advantage is that", "The advantage is that + clause"),
    ("p386", "one benefit is that", "One benefit is that...", "noun_advantage", "One benefit is that", "One benefit is that + clause"),
    ("p387", "the good thing is that", "The good thing is that...", "noun_advantage", "The good thing is that", "The good thing is that + clause"),
    ("p388", "the best part is", "The best part is...", "clause_opinion", "The best part is", "The best part is + clause"),
    ("p389", "what's great about it is", "What's great about it is...", "clause_opinion", "What's great about it is", "What's great about it is + clause"),
    ("p390", "the upside is", "The upside is / The downside is...", "clause_opinion", "The upside is", "The upside is + clause"),
    # --- 14. 兴趣 Interests (p391-p398) ---
    ("p391", "i'm interested in", "I'm interested in...", "verb_ing", "I'm interested in", "I'm interested in + verb-ing"),
    ("p392", "my hobby is", "My hobby is...", "verb_ing", "My hobby is", "My hobby is + verb-ing"),
    ("p393", "i'm passionate about", "I'm passionate about...", "verb_ing", "I'm passionate about", "I'm passionate about + verb-ing"),
    ("p394", "i spend my free time", "I spend my free time...", "verb_ing", "I spend my free time", "I spend my free time + verb-ing"),
    ("p395", "i'm a fan of", "I'm a fan of...", "noun_have_pl", "I'm a fan of", "I'm a fan of + noun"),
    ("p396", "i'm really into", "I'm really into...", "verb_ing", "I'm really into", "I'm really into + verb-ing"),
    ("p397", "i've been getting into", "I've been getting into...", "verb_ing", "I've been getting into", "I've been getting into + verb-ing"),
    ("p398", "i'm learning to", "I'm learning to...", "verb_to_do", "I'm learning to", "I'm learning to + verb"),
    # --- 15. 情绪 Emotions (p399-p400) ---
    ("p399", "it makes me", "It makes me...", "adj_feeling", "It makes me", "It makes me + adjective"),
    ("p400", "i can't help feeling", "I can't help feeling...", "adj_feeling", "I can't help feeling", "I can't help feeling + adjective"),
    # --- 16. 道歉 Apologies (p401-p408) ---
    ("p401", "i apologize for", "I apologize for...", "verb_ing", "I apologize for", "I apologize for + verb-ing"),
    ("p402", "please forgive me for", "Please forgive me for...", "verb_ing", "Please forgive me for", "Please forgive me for + verb-ing"),
    ("p403", "i didn't mean to", "I didn't mean to...", "verb_to_do", "I didn't mean to", "I didn't mean to + verb"),
    ("p404", "i'm sorry that", "I'm sorry that...", "clause_apology", "I'm sorry that", "I'm sorry that + clause"),
    ("p405", "it was my fault", "It was my fault...", "clause_apology", "It was my fault,", "It was my fault, + clause"),
    ("p406", "i shouldn't have", "I shouldn't have...", "verb_done", "I shouldn't have", "I shouldn't have + past participle"),
    ("p407", "i regret", "I regret...", "verb_ing", "I regret", "I regret + verb-ing"),
    ("p408", "pardon me for", "Pardon me for / Excuse me for...", "verb_ing", "Pardon me for", "Pardon me for + verb-ing"),
    # --- 17. 询问 Inquiries (p409-p412) ---
    ("p409", "could you tell me", "Could you tell me / Can you tell me...", "clause_opinion", "Could you tell me", "Could you tell me + clause?"),
    ("p410", "i'd like to know", "I'd like to know...", "clause_opinion", "I'd like to know", "I'd like to know + clause"),
    ("p411", "can i ask you about", "Can I ask you about...?", "noun_have_a", "Can I ask you about", "Can I ask you about + noun?"),
    ("p412", "do you happen to know", "Do you happen to know...?", "clause_opinion", "Do you happen to know", "Do you happen to know + clause?"),
    # --- 18. 时间 Time (p413-p422) ---
    ("p413", "it takes", "It takes...", "noun_time", "It takes", "It takes + time"),
    ("p414", "i spent", "I spent...", "noun_time", "I spent", "I spent + time"),
    ("p415", "how long does it take to", "How long does it take to...?", "verb_to_do", "How long does it take to", "How long does it take to + verb?"),
    ("p416", "it's been", "It's been...", "noun_time", "It's been", "It's been + time"),
    ("p417", "i haven't done that for", "I haven't done that for...", "noun_time", "I haven't done that for", "I haven't done that for + time"),
    ("p418", "when do you usually", "When do you usually...?", "verb_base", "When do you usually", "When do you usually + verb?"),
    ("p419", "i'll be there in", "I'll be there in...", "noun_time", "I'll be there in", "I'll be there in + time"),
    ("p420", "it's about time we", "It's about time we...", "verb_base", "It's about time we", "It's about time we + verb"),
    ("p421", "sooner or later", "Sooner or later...", "clause_opinion", "Sooner or later,", "Sooner or later, + clause"),
    ("p422", "better late than never", "Better late than never...", "clause_opinion", "Better late than never,", "Better late than never, + clause"),
    # --- 19. 吃喝 Eating/Drinking (p423-p430) ---
    ("p423", "would you like some", "Would you like some...?", "noun_have_pl", "Would you like some", "Would you like some + noun?"),
    ("p424", "let's grab", "Let's grab...", "noun_have_a", "Let's grab", "Let's grab + noun"),
    ("p425", "i'm in the mood for", "I'm in the mood for...", "noun_have_a", "I'm in the mood for", "I'm in the mood for + noun"),
    ("p426", "have you tried", "Have you tried...?", "noun_have_a", "Have you tried", "Have you tried + noun?"),
    ("p427", "i could go for", "I could go for...", "noun_have_a", "I could go for", "I could go for + noun"),
    ("p428", "this tastes", "This tastes / This smells...", "adj_describe", "This tastes", "This tastes + adjective"),
    ("p429", "help yourself to", "Help yourself to...", "noun_have_a", "Help yourself to", "Help yourself to + noun"),
    ("p430", "i recommend the", "I recommend the...", "noun_have_a", "I recommend the", "I recommend the + noun"),
    # --- 20. 愿望 Wishes (p431-p435) ---
    ("p431", "i wish i could", "I wish I could...", "verb_base", "I wish I could", "I wish I could + verb"),
    ("p432", "if only i could", "If only I could...", "verb_base", "If only I could", "If only I could + verb"),
    ("p433", "i dream of", "I dream of...", "verb_ing", "I dream of", "I dream of + verb-ing"),
    ("p434", "i long to", "I long to / I yearn to...", "verb_to_do", "I long to", "I long to + verb"),
    ("p435", "someday i will", "Someday I will...", "verb_base", "Someday I will", "Someday I will + verb"),
    # --- 21. 谈论 Discussing (p436-p443) ---
    ("p436", "speaking of", "Speaking of...", "noun_have_a", "Speaking of", "Speaking of + noun"),
    ("p437", "let's talk about", "Let's talk about...", "noun_have_a", "Let's talk about", "Let's talk about + noun"),
    ("p438", "regarding", "Regarding / Concerning...", "noun_have_a", "Regarding", "Regarding + noun"),
    ("p439", "as for", "As for...", "noun_have_a", "As for", "As for + noun"),
    ("p440", "have you heard about", "Have you heard about...?", "noun_have_a", "Have you heard about", "Have you heard about + noun?"),
    ("p441", "i want to discuss", "I want to discuss...", "noun_have_a", "I want to discuss", "I want to discuss + noun"),
    ("p442", "what do you think about", "What do you think about...?", "noun_have_a", "What do you think about", "What do you think about + noun?"),
    ("p443", "i've been meaning to ask you about", "I've been meaning to ask you about...", "noun_have_a", "I've been meaning to ask you about", "I've been meaning to ask you about + noun"),
    # --- 22. 打听 Asking Around (p444-p451) ---
    ("p444", "i was wondering if", "I was wondering if...", "clause_opinion", "I was wondering if", "I was wondering if + clause"),
    ("p445", "do you by any chance know", "Do you by any chance know...?", "clause_opinion", "Do you by any chance know", "Do you by any chance know + clause?"),
    ("p446", "have you ever heard of", "Have you ever heard of...?", "noun_have_a", "Have you ever heard of", "Have you ever heard of + noun?"),
    ("p447", "can anyone tell me", "Can anyone tell me...?", "clause_opinion", "Can anyone tell me", "Can anyone tell me + clause?"),
    ("p448", "has anyone told you", "Has anyone told you...?", "clause_opinion", "Has anyone told you", "Has anyone told you + clause?"),
    ("p449", "i'm curious about", "I'm curious about...", "noun_have_a", "I'm curious about", "I'm curious about + noun"),
    ("p450", "did you find out about", "Did you find out about...?", "noun_have_a", "Did you find out about", "Did you find out about + noun?"),
    ("p451", "i'd be interested to know", "I'd be interested to know...", "clause_opinion", "I'd be interested to know", "I'd be interested to know + clause"),
    # --- 23. 邀请 Invitations (p452-p459) ---
    ("p452", "would you like to join me for", "Would you like to join me for...?", "noun_have_a", "Would you like to join me for", "Would you like to join me for + noun?"),
    ("p453", "i'd like to invite you to", "I'd like to invite you to...", "verb_to_do", "I'd like to invite you to", "I'd like to invite you to + verb"),
    ("p454", "how would you like to", "How would you like to...?", "verb_to_do", "How would you like to", "How would you like to + verb?"),
    ("p455", "do you want to come to", "Do you want to come to...?", "noun_have_a", "Do you want to come to", "Do you want to come to + noun?"),
    ("p456", "are you free for", "Are you free for...?", "noun_have_a", "Are you free for", "Are you free for + noun?"),
    ("p457", "why don't we", "Why don't we...?", "verb_base", "Why don't we", "Why don't we + verb?"),
    ("p458", "would you care to", "Would you care to...?", "verb_to_do", "Would you care to", "Would you care to + verb?"),
    ("p459", "i was thinking we could", "I was thinking we could...", "verb_base", "I was thinking we could", "I was thinking we could + verb"),
]

# ============================================================
# ZH_TEMPLATE_MAP — Chinese translation templates per match_key
# {} is replaced by the slot word's Chinese translation
# ============================================================
ZH_TEMPLATE_MAP = {
    # There be existential patterns
    "there is no":      "没有{}。",
    "there is a":       "有一个{}。",
    "there are":        "有{}。",
    "there was no":     "没有{}。",
    "there were no":    "没有{}。",
    "there will be":    "会有{}。",
    "there is":         "有{}。",
    "there's no":       "没有{}。",
    "there's a":        "有一个{}。",
    # I have possession patterns
    "i have a":         "我有一个{}。",
    "i have no":        "我没有{}。",
    "i have":           "我有{}。",
    "i don't have":     "我没有{}。",
    "i had a":          "我有一个{}。",
    "i've got a":       "我有一个{}。",
    "i've got no":      "我没有{}。",
    # I want / I'd like patterns
    "i want to":        "我想{}。",
    "i want a":         "我想要一个{}。",
    "i want":           "我想要{}。",
    "i would like to":  "我想{}。",
    "i'd like to":      "我想{}。",
    "i'd like a":       "我想要一个{}。",
    "i feel like":      "我想{}。",
    # I can / I could patterns
    "i can":            "我可以{}。",
    "i can't":          "我不能{}。",
    "i could":          "我可以{}。",
    "i cannot":         "我不能{}。",
    # Can you / Could you request patterns
    "can you":          "你能{}吗？",
    "could you":        "你可以{}吗？",
    "will you":         "你会{}吗？",
    "would you":        "你愿意{}吗？",
    # I think / I believe opinion patterns
    "i think":          "我认为{}。",
    "i think it's":     "我认为这{}。",
    "i believe":        "我相信{}。",
    "i don't think":    "我不认为{}。",
    "i guess":          "我猜{}。",
    "in my opinion":    "在我看来，{}。",
    # It is / It's descriptive patterns
    "it is":            "这{}。",
    "it's":             "这{}。",
    "it was":           "这{}。",
    "it seems":         "这似乎{}。",
    "it looks":         "这看起来{}。",
    "it's not":         "这不{}。",
    "it's too":         "这太{}。",
    "it's a":           "这是一个{}。",
    # I need / I must / I should necessity patterns
    "i need to":        "我需要{}。",
    "i need a":         "我需要一个{}。",
    "i need":           "我需要{}。",
    "i have to":        "我必须{}。",
    "i must":           "我必须{}。",
    "i should":         "我应该{}。",
    "you should":       "你应该{}。",
    # I like / I love / I enjoy preference patterns
    "i like":           "我喜欢{}。",
    "i like to":        "我喜欢{}。",
    "i love":           "我热爱{}。",
    "i love to":        "我热爱{}。",
    "i enjoy":          "我喜欢{}。",
    "i prefer":         "我更喜欢{}。",
    "i prefer to":      "我更喜欢{}。",
    "i don't like":     "我不喜欢{}。",
    "i'm into":         "我喜欢{}。",
    # I hope / I wish patterns
    "i hope":           "我希望{}。",
    "i wish":           "我希望{}。",
    "i hope to":        "我希望{}。",
    # I'm / I am state patterns
    "i'm":              "我{}。",
    "i'm not":          "我不{}。",
    "i'm a":            "我是一个{}。",
    "i'm feeling":      "我感觉{}。",
    "i am":             "我{}。",
    # I'm going to / I will future patterns
    "i'm going to":     "我打算{}。",
    "i will":           "我会{}。",
    "i'll":             "我会{}。",
    "i'm about to":     "我正要{}。",
    "i plan to":        "我计划{}。",
    # I've / I have done perfect patterns
    "i've":             "我已经{}。",
    "i've never":       "我从未{}。",
    "i haven't":        "我还没有{}。",
    "have you ever":    "你曾经{}吗？",
    "have you":         "你已经{}吗？",
    # I used to / I'm used to habitual patterns
    "i used to":        "我以前常常{}。",
    "i'm used to":      "我习惯于{}。",
    "i get used to":    "我开始习惯{}。",
    # How / What question patterns
    "how do you":       "你怎么{}？",
    "what do you":      "你{}什么？",
    "why do you":       "你为什么{}？",
    "where can i":      "我在哪里可以{}？",
    "how can i":        "我怎么才能{}？",
    "how about":        "{}怎么样？",
    "what about":       "{}怎么样？",
    # Let's / Let me imperative patterns
    "let's":            "我们{}吧。",
    "let me":           "让我{}。",
    "don't":            "不要{}。",
    "please":           "请{}。",
    # This is / That is demonstrative patterns
    "this is":          "这{}。",
    "that is":          "那{}。",
    "that's":           "那{}。",
    "this is a":        "这是一个{}。",
    "that's a":         "那是一个{}。",
    # I'm trying to / I'm working on progressive patterns
    "i'm trying to":    "我正在努力{}。",
    "i'm looking for":  "我在找{}。",
    "i'm working on":   "我正在做{}。",
    "i'm thinking about": "我在考虑{}。",
    # I'm sorry / I'm afraid emotional patterns
    "i'm sorry":        "很抱歉，{}。",
    "i'm afraid":       "恐怕{}。",
    "i'm glad":         "我很高兴{}。",
    "i'm surprised":    "我很惊讶{}。",
    "i'm sure":         "我确信{}。",
    # Do you / Did you yes-no question patterns
    "do you":           "你{}吗？",
    "do you like":      "你喜欢{}吗？",
    "did you":          "你{}了吗？",
    "do you want to":   "你想{}吗？",
    "do you think":     "你认为{}吗？",
    # It's important / It's hard evaluative patterns
    "it's important":   "{}很重要。",
    "it's necessary":   "{}是必要的。",
    "it's hard":        "{}很难。",
    "it's easy":        "{}很容易。",
    "it's time":        "是时候{}了。",
    # I remember / I forget memory patterns
    "i remember":       "我记得{}。",
    "i forget":         "我忘记{}。",
    "i forgot":         "我忘记{}了。",
    # Thank you / Thanks for gratitude patterns
    "thank you":        "谢谢你{}。",
    "thanks for":       "谢谢{}。",
    "i appreciate":     "我感谢{}。",
    # If I / If you conditional patterns
    "if i":             "如果我{}。",
    "if you":           "如果你{}。",
    "if i had":         "如果我有{}。",
    "if i were you":    "如果我是你，我会{}。",
    # One of / Some of quantity patterns
    "one of":           "{}之一。",
    "some of":          "一些{}。",
    "most of":          "大多数{}。",
    "a lot of":         "很多{}。",
    "plenty of":        "充足的{}。",
    # I was past state patterns
    "i was":            "我当时{}。",
    "i was a":          "我曾是一个{}。",
    "i was going to":   "我本来打算{}。",
    # I've been / I've had experience patterns
    "i've been":        "我一直在{}。",
    "i've been a":      "我一直是一个{}。",
    "i've had":         "我已有{}。",
    # I'm looking forward to anticipation patterns
    "i'm looking forward to": "我期待{}。",
    "i look forward to":      "我期待{}。",
    # I wonder / I was wondering curiosity patterns
    "i wonder":         "我想知道{}。",
    "i was wondering":  "我在想{}。",
    # I'd rather / I'd better preference patterns
    "i'd rather":       "我宁愿{}。",
    "i'd better":       "我最好{}。",
    "you'd better":     "你最好{}。",
    # He is / She is / They are third-person patterns
    "he is":            "他{}。",
    "she is":           "她{}。",
    "they are":         "他们{}。",
    "he's a":           "他是一个{}。",
    "she's a":          "她是一个{}。",
    # I get / I feel change-of-state patterns
    "i get":            "我变得{}。",
    "i feel":           "我感觉{}。",
    # --- NEW for v3.0.0 ---
    # 1. Habits
    "i usually":        "我通常{}。",
    "i often":          "我经常{}。",
    "i always":         "我总是{}。",
    "i rarely":         "我很少{}。",
    "i never":          "我从不{}。",
    "i sometimes":      "我有时候{}。",
    "i tend to":        "我倾向于{}。",
    "i'm accustomed to": "我习惯于{}。",
    # 2. Purpose
    "i came here to":   "我来这里是为了{}。",
    "in order to":      "为了{}。",
    "so that i can":    "这样我就可以{}。",
    "the reason i'm here is to": "我来这里的原因是为了{}。",
    "my goal is to":    "我的目标是{}。",
    "i'm doing this to": "我做这个是为了{}。",
    # 3. Comfort
    "don't worry":      "别担心，{}。",
    "it's okay":        "没关系，{}。",
    "i understand":     "我理解，{}。",
    "you'll be fine":   "你会没事的，{}。",
    "cheer up":         "振作起来，{}。",
    "take it easy":     "放轻松，{}。",
    "i'm here for you": "我会在你身边，{}。",
    "it's not the end of the world": "这不是世界末日，{}。",
    # 4. Gratitude
    "i'm grateful for": "我很感激{}。",
    "i owe you one for": "我为{}欠你一个人情。",
    "much appreciated for": "非常感谢{}。",
    # 5. Anticipation
    "i can't wait to":  "我等不及要{}。",
    "i'm counting on":  "我指望着{}。",
    "i'm excited about": "我对{}很兴奋。",
    "i'm eager to":     "我渴望{}。",
    # 6. Preferences
    "i'm fond of":      "我喜欢{}。",
    "i'm crazy about":  "我非常喜欢{}。",
    "i'm a big fan of": "我是{}的超级粉丝。",
    # 7. Senses
    "it sounds":        "这听起来{}。",
    "it tastes":        "这尝起来{}。",
    "it smells":        "这闻起来{}。",
    "it feels":         "这感觉{}。",
    "that sounds like": "那听起来像{}。",
    "it looks like":    "这看起来像{}。",
    "it seems like":    "这似乎{}。",
    "i have a feeling that": "我有一种感觉，{}。",
    # 8. Explanation
    "the reason is that": "原因是{}。",
    "that's because":   "那是因为{}。",
    "let me explain":   "让我解释一下，{}。",
    "this is why":      "这就是为什么{}。",
    "what i mean is":   "我的意思是{}。",
    "the thing is":     "问题是{}。",
    "as it turns out":  "结果发现，{}。",
    "to be honest":     "说实话，{}。",
    # 9. Opinions
    "as far as i'm concerned": "就我而言，{}。",
    "from my perspective": "从我的角度来看，{}。",
    "personally, i think": "就我个人而言，我认为{}。",
    "if you ask me":    "如果你问我，{}。",
    # 10. Suggestions
    "i suggest you":    "我建议你{}。",
    "why don't you":    "你为什么不{}？",
    "you might want to": "你不妨{}。",
    "it might be better to": "最好{}。",
    "have you considered": "你考虑过{}吗？",
    "if i were you, i'd": "如果我是你，我会{}。",
    "i recommend":      "我推荐{}。",
    "you could try":    "你可以试试{}。",
    "the best thing to do is": "最好的办法是{}。",
    "you have nothing to lose by": "你{}不会有什么损失。",
    # 11. Plans
    "i intend to":      "我打算{}。",
    "i'm planning on":  "我计划{}。",
    "my plan is to":    "我的计划是{}。",
    # 12. Reminders
    "don't forget to":  "别忘了{}。",
    "remember to":      "记得要{}。",
    "make sure you":    "确保你{}。",
    "keep in mind that": "记住，{}。",
    "just a reminder":  "提醒一下，{}。",
    "be sure to":       "一定要{}。",
    "i want to remind you": "我想提醒你，{}。",
    "don't miss":       "不要错过{}。",
    # 13. Advantages
    "the advantage is that": "优点是{}。",
    "one benefit is that": "一个好处是{}。",
    "the good thing is that": "好的一面是{}。",
    "the best part is": "最好的部分是{}。",
    "what's great about it is": "它好就好在{}。",
    "the upside is":    "好的一面是{}。",
    # 14. Interests
    "i'm interested in": "我对{}感兴趣。",
    "my hobby is":      "我的爱好是{}。",
    "i'm passionate about": "我热爱{}。",
    "i spend my free time": "我空闲时间{}。",
    "i'm a fan of":     "我是{}的粉丝。",
    "i'm really into":  "我非常喜欢{}。",
    "i've been getting into": "我最近开始喜欢{}。",
    "i'm learning to":  "我在学{}。",
    # 15. Emotions
    "it makes me":      "这让我{}。",
    "i can't help feeling": "我不禁感到{}。",
    # 16. Apologies
    "i apologize for":  "我为{}道歉。",
    "please forgive me for": "请原谅我{}。",
    "i didn't mean to": "我不是故意{}。",
    "i'm sorry that":   "我很抱歉，{}。",
    "it was my fault":  "这是我的错，{}。",
    "i shouldn't have": "我不应该{}。",
    "i regret":         "我后悔{}。",
    "pardon me for":    "请原谅我{}。",
    # 17. Inquiries
    "could you tell me": "你能告诉我{}吗？",
    "i'd like to know": "我想知道{}。",
    "can i ask you about": "我能问你关于{}的事吗？",
    "do you happen to know": "你碰巧知道{}吗？",
    # 18. Time
    "it takes":         "这需要{}。",
    "i spent":          "我花了{}。",
    "how long does it take to": "{}需要多长时间？",
    "it's been":        "已经{}了。",
    "i haven't done that for": "我已经{}没做那个了。",
    "when do you usually": "你通常什么时候{}？",
    "i'll be there in": "我{}后到。",
    "it's about time we": "我们是时候{}了。",
    "sooner or later":  "迟早{}。",
    "better late than never": "迟做总比不做好，{}。",
    # 19. Eating/Drinking
    "would you like some": "你想要一些{}吗？",
    "let's grab":       "我们去{}吧。",
    "i'm in the mood for": "我想吃{}。",
    "have you tried":   "你试过{}吗？",
    "i could go for":   "我想来点{}。",
    "this tastes":      "这个尝起来{}。",
    "help yourself to": "请随便吃{}。",
    "i recommend the":  "我推荐{}。",
    # 20. Wishes
    "i wish i could":   "我希望我能{}。",
    "if only i could":  "要是我能{}就好了。",
    "i dream of":       "我梦想着{}。",
    "i long to":        "我渴望{}。",
    "someday i will":   "总有一天我会{}。",
    # 21. Discussing
    "speaking of":      "说到{}，",
    "let's talk about": "我们来谈谈{}。",
    "regarding":        "关于{}，",
    "as for":           "至于{}，",
    "have you heard about": "你听说了{}吗？",
    "i want to discuss": "我想讨论一下{}。",
    "what do you think about": "你觉得{}怎么样？",
    "i've been meaning to ask you about": "我一直想问你关于{}的事。",
    # 22. Asking Around
    "i was wondering if": "我在想是否{}。",
    "do you by any chance know": "你碰巧知道{}吗？",
    "have you ever heard of": "你听说过{}吗？",
    "can anyone tell me": "谁能告诉我{}？",
    "has anyone told you": "有人告诉过你{}吗？",
    "i'm curious about": "我很好奇{}。",
    "did you find out about": "你打听到{}了吗？",
    "i'd be interested to know": "我很想知道{}。",
    # 23. Invitations
    "would you like to join me for": "你愿意和我一起{}吗？",
    "i'd like to invite you to": "我想邀请你{}。",
    "how would you like to": "你觉得{}怎么样？",
    "do you want to come to": "你想来{}吗？",
    "are you free for": "你有空{}吗？",
    "why don't we":     "我们为什么不{}呢？",
    "would you care to": "你愿意{}吗？",
    "i was thinking we could": "我在想我们可以{}。",
}

QUESTION_WORDS = set("can could will would do did does have has how what when where why is are am was were shall should may might must".split())

# ============================================================
# ENGINE
# ============================================================

def match_pattern(prompt):
    p = prompt.lower().strip()
    for i, (_, mk, *_) in enumerate(PATTERNS):
        if p == mk: return i
    for i, (_, mk, *_) in enumerate(PATTERNS):
        if p.startswith(mk): return i
    for i, (_, mk, *_) in enumerate(PATTERNS):
        if mk in p: return i
    if p.startswith("there's"):
        p2 = p.replace("there's", "there is", 1)
        for i, (_, mk, *_) in enumerate(PATTERNS):
            if p2.startswith(mk): return i
    return -1

def pick_words(slot_type, n):
    pool = WORDS.get(slot_type, [])
    if not pool: return []
    if n > len(pool): n = len(pool)
    return random.sample(pool, n)

def get_punctuation(prefix):
    first = prefix.strip().split()[0].lower() if prefix.strip() else ""
    return "?" if first in QUESTION_WORDS else "."

def smart_slot(prompt_lower):
    tokens = prompt_lower.split()
    if not tokens: return None
    last = tokens[-1]
    if last == "no": return "noun_exist_no"
    if last in ("a", "an"): return "noun_exist_a"
    if last == "to": return "verb_to_do"
    if last == "the": return "noun_have_a"
    if last == "for": return "verb_ing_about"
    if last == "about": return "verb_ing"
    if prompt_lower.startswith("there"): return "noun_exist_a"
    if prompt_lower.startswith("i'm") or prompt_lower.startswith("i am"): return "adj_feeling"
    if prompt_lower.startswith("i feel"): return "adj_feeling"
    if prompt_lower.startswith("it's") or prompt_lower.startswith("it is"): return "adj_describe"
    return "noun_have_a"

def generate_sentences(prompt, n):
    idx = match_pattern(prompt)
    if idx >= 0:
        _, mk, unit_title, slot_type, prefix, _ = PATTERNS[idx]
        zh_template = ZH_TEMPLATE_MAP.get(mk, "{}")
    else:
        slot_type = smart_slot(prompt.lower().strip())
        if slot_type is None: return None, []
        prefix = prompt.strip()
        unit_title = prompt.strip() + "..."
        zh_template = "{}"
    words = pick_words(slot_type, n)
    if not words: words = pick_words("noun_exist_no", n)
    if not words: return None, []
    punc = get_punctuation(prefix)
    sentences = [(f"{prefix} {en}{punc}", zh_template.format(zh)) for en, zh in words]
    return unit_title, sentences

def write_output(outfile, unit_title, sentences, unit_num=1):
    with open(outfile, "w", encoding="utf-8") as f:
        f.write(f"# Unit {unit_num}:{unit_title}\n\n")
        for en, zh in sentences:
            f.write(f"{en}  |  {zh}\n")
        f.write("\n---\n")
        f.write("Dingyuan Accounting LAN (D:\\dingyuan-system) imports into the Spoken English module.\n")
        f.write("Authors: WU Lianghai (AHUT) ; WU Hanyan (CityU)\n")

def mkes_main(prompt, n, outfile):
    unit_title, sentences = generate_sentences(prompt, n)
    if unit_title is None:
        print("Error: Cannot generate sentences for this prompt.")
        return
    write_output(outfile, unit_title, sentences)
    # preview
    print(f"\n{'='*70}")
    print(f"Preview (first {min(5, len(sentences))}):")
    for en, zh in sentences[:5]:
        print(f"  {en}  |  {zh}")
    if len(sentences) > 5:
        print(f"  ... ({len(sentences)} total)")

def mkes_list_patterns():
    print(f"\n{'='*70}")
    print("mkes — Supported Sentence Patterns (Python engine)")
    print(f"{'='*70}")
    for pid, mk, title, st, _, desc in PATTERNS:
        count = len(WORDS.get(st, []))
        print(f"[{pid}] {desc}")
        print(f"    Match: {mk}  |  Entries: {count}")
    print(f"{'='*70}")
    print(f"Total: {len(PATTERNS)} pattern templates covering daily life and work scenarios.")
    print('Usage: mkes "prompt", n(#) [output(filename)]')
    print('       mkes , units(#) [mode(sequential|random) n(#) output(filename) replace]')

# ============================================================
# MULTI-UNIT ENGINE (v3.1.0)
# ============================================================

def mkes_multi_main(units, mode, n_per_unit, outfile, start=1):
    """Generate multiple units in one output file (v3.1.0)."""
    selected = select_patterns(units, mode, start)
    if not selected:
        print("Error: No patterns could be selected.")
        return

    all_units = []
    for pat in selected:
        _, mk, unit_title, slot_type, prefix, _ = pat
        words = pick_words(slot_type, n_per_unit)
        if not words:
            # fallback to common word banks
            for fallback_slot in ["noun_exist_no", "noun_have_a", "verb_base"]:
                words = pick_words(fallback_slot, n_per_unit)
                if words:
                    break
        if not words:
            continue
        zh_template = ZH_TEMPLATE_MAP.get(mk, "{}")
        punc = get_punctuation(prefix)
        sentences = [(f"{prefix} {en}{punc}", zh_template.format(zh)) for en, zh in words]
        all_units.append((unit_title, sentences))

    if not all_units:
        print("Error: Could not generate any units.")
        return

    write_multi_output(outfile, all_units)

    # preview
    print(f"\n{'='*70}")
    print(f"Generated {len(all_units)} units:")
    for i, (title, sents) in enumerate(all_units, 1):
        print(f"  Unit {i}: {title} ({len(sents)} sentences)")
    print(f"\nPreview (first few sentences):")
    for i, (title, sents) in enumerate(all_units[:3], 1):
        print(f"  --- Unit {i}: {title} ---")
        for en, zh in sents[:2]:
            print(f"    {en}  |  {zh}")
        if len(sents) > 2:
            print(f"    ... ({len(sents)} total)")
    if len(all_units) > 3:
        print(f"  ... ({len(all_units) - 3} more units)")


def select_patterns(n_units, mode, start=1):
    """Select n_units patterns from PATTERNS according to mode (v3.1.0).

    mode: "sequential" - pick patterns in order starting from 'start'
                         'start' is a pattern number (e.g., 50 = p050)
          "random"     - randomly pick unique patterns; 'start' as random seed
    """
    n_total = len(PATTERNS)

    if mode == "sequential":
        # Find index of the pattern whose ID matches start number (e.g., 50 -> p050)
        target_id = f"p{start:03d}"
        idx_start = 0
        for i, pat in enumerate(PATTERNS):
            if pat[0] >= target_id:
                idx_start = i
                break
        selected = []
        for i in range(n_units):
            idx = (idx_start + i) % n_total
            selected.append(PATTERNS[idx])
        return selected

    elif mode == "random":
        if n_units > n_total:
            n_units = n_total
        if start > 1:
            random.seed(start)
        return random.sample(PATTERNS, n_units)

    return []


def write_multi_output(outfile, all_units):
    """Write multiple units to a single output file (v3.1.0)."""
    with open(outfile, "w", encoding="utf-8") as f:
        for i, (unit_title, sentences) in enumerate(all_units, 1):
            f.write(f"# Unit {i}: {unit_title}\n\n")
            for en, zh in sentences:
                f.write(f"{en}  |  {zh}\n")
            f.write("\n")
        f.write("---\n")
        f.write("Dingyuan Accounting LAN (D:\\dingyuan-system) imports into the Spoken English module.\n")
        f.write("Authors: WU Lianghai (AHUT) ; WU Hanyan (CityU)\n")


end
