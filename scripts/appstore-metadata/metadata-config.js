/**
 * App Store 多语言元数据配置
 *
 * 配置说明：
 * - subtitle: 副标题（30 字符）
 * - description: 描述（4000 字符）
 * - keywords: 关键词（100 字符，用逗号分隔）
 * - marketing_url: 营销 URL（可选）
 * - support_url: 支持 URL
 * - privacy_policy_url: 隐私政策 URL
 */

export const metadata = {
  // 默认值（作为兜底）
  default: {
    subtitle: "Offline Wallet",
    description: `ColorFuLedger is a simple, intuitive offline wallet for tracking your income and expenses.

KEY FEATURES:

• 100% Offline - No internet required, your data stays on your device
• Quick Recording - Add transactions in 3 seconds
• Visual Reports - Pie charts and trends show where your money goes
• Budget Management - Set monthly and category budgets
• Tags - Flexible tagging system for multi-angle tracking
• Templates - Create templates for frequently used transactions
• Reminders - Set recurring reminders for bills and expenses
• Export - Backup to JSON or export to CSV/PDF reports
• Security - Password lock and biometric authentication
• Completely Free - No ads, no subscriptions

CATEGORIES:
Track expenses across Food, Shopping, Transport, Housing, Phone, Entertainment, Clothing, Medical, Education, Travel, Kids, and more. Income categories include Salary, Freelance, Investment, Gift, and Other.

BUDGET CONTROL:
Set spending limits for overall monthly expenses or individual categories. Visual progress bars help you stay on track.

TAGS & TEMPLATES:
Use tags to group transactions flexibly (Travel, Reimbursement, Shared expenses, etc.). Create templates for quick recording of routine transactions.

ACHIEVEMENTS:
Gamified achievements motivate you to maintain good financial habits - streaks, budget discipline, and more.

CALENDAR VIEW:
Review your spending by calendar date for better financial planning.

PRIVACY FIRST:
Your financial data never leaves your device. No account required, no data collection.

Perfect for personal finance, household budgeting, student expense tracking, and anyone who wants simple, private money management.`,
    keywords: "budget,expense tracker,money,finance,accounting,personal finance,spending tracker,offline,wallet,ledger"
  },

  // 各语言配置
  locales: {
    // 英语 - 美国
    'en-US': {
      name: "ColorFuLedger",
      subtitle: "Offline Wallet & Budget",
      keywords: "budget,expense tracker,money,finance,accounting,personal finance,spending,offline,wallet,ledger"
    },

    // 英语 - 英国
    'en-GB': {
      name: "ColorFuLedger",
      subtitle: "Offline Wallet & Budget",
      keywords: "budget,expense tracker,money,finance,accounting,personal finance,spending,offline,wallet,ledger"
    },

    // 加拿大 - 英语
    'en-CA': {
      name: "ColorFuLedger",
      subtitle: "Offline Wallet & Budget",
      keywords: "budget,expense tracker,money,finance,accounting,personal finance,spending,offline,wallet,ledger"
    },

    // 澳大利亚 - 英语
    'en-AU': {
      name: "ColorFuLedger",
      subtitle: "Offline Wallet & Budget",
      keywords: "budget,expense tracker,money,finance,accounting,personal finance,spending,offline,wallet,ledger"
    },

    // 简体中文
    'zh-Hans': {
      name: "多记账",
      subtitle: "不联网的离线钱包",
      keywords: "记账，预算， expense tracker，钱包，理财，个人财务，离线，记账本，收支，账本",
      description: `多记账是一款简单、直观的离线钱包，帮你轻松记录收入和支出。

核心功能：

• 100% 离线 - 无需联网，数据只保存在你的设备
• 快速记账 - 3 秒内完成记录
• 可视化报表 - 饼图和趋势图展示消费去向
• 预算管理 - 设置月度和分类预算
• 标签系统 - 灵活的多角度消费追踪
• 模板功能 - 为常用交易创建模板
• 提醒功能 - 设置定期提醒，不错过房租账单
• 导出备份 - JSON 备份或 CSV/PDF 报表导出
• 安全保护 - 密码锁和生物识别认证
• 完全免费 - 无广告，无订阅

分类齐全：
支出分类涵盖餐饮、购物、交通、住房、通讯、娱乐、服饰、医疗、教育、旅行、育儿等。收入分类包括工资、自由职业、投资、礼金、其他收入。

预算控制：
设置月度总支出上限或分类预算，可视化进度条帮你控制消费。

标签与模板：
灵活使用标签分组交易（旅行、报销、AA 制、项目等）。创建模板快速记录日常交易。

成就系统：
游戏化成就激励你保持良好的财务习惯——连续记账、预算控制等。

日历视图：
按日期查看消费，更好地规划财务。

隐私优先：
财务数据永不离开设备，无需账号，无数据收集。

适合个人理财、家庭预算、学生记账，以及任何追求简单、隐私的财务管理用户。`
    },

    // 繁体中文
    'zh-Hant': {
      name: "多記賬",
      subtitle: "不連網的離線錢包",
      keywords: "記賬，預算，expense tracker，錢包，理財，個人財務，離線，記賬本，收支，賬本"
    },

    // 日文
    'ja': {
      name: "多会計",
      subtitle: "オフライン財布",
      keywords: "予算，家計簿，expense tracker,財布，財務，個人財務，オフライン，財布， Ledger，支出",
      description: `多会計は、収入と支出を記録するためのシンプルで直感的なオフライン財布アプリです。

主な機能：

• 100% オフライン - インターネット不要、データはデバイス内に保存
• クイック記録 - 3 秒で取引を記録
• ビジュアルレポート - 円グラフとトレンドで支出を可視化
• 予算管理 - 月間およびカテゴリ別予算を設定
• タグシステム - 多角度から支出を追跡
• テンプレート - よく使う取引を素早く記録
• リマインダー - 家賃や請求書の定期的なリマインダー
• エクスポート - JSON バックアップまたは CSV/PDF レポート
• セキュリティ - パスワードロックと生体認証
• 完全無料 - 広告なし、サブスクリプションなし

カテゴリ：
食費、ショッピング、交通、住居、通信、娯楽、衣類、医療、教育、旅行、子育てなどの支出カテゴリ。給与、フリーランス、投資、贈答、その他の収入カテゴリ。

予算管理：
月間支出上限やカテゴリ別予算を設定。視覚的な進行状況で管理。

タグとテンプレート：
タグで取引を柔軟にグループ化（旅行、経費精算、共同支出など）。テンプレートで定型取引を素早く記録。

アチーブメント：
連続記録、予算管理など、ゲーム要素で良い習慣を維持。

カレンダービュー：
日付別に支出を確認して財務計画。

プライバシー優先：
財務データはデバイスから出ない、アカウント不要、データ収集なし。

個人財務、家計管理、学生の家計簿、シンプルでプライバシー重視の财务管理に適しています。`
    },

    // 韩文
    'ko': {
      name: "다회계",
      subtitle: "오프라인 지갑",
      keywords: "예산，가계부，expense tracker，지갑，재무，개인 재무，오프라인，지출，수입，가계장"
    },

    // 法文
    'fr': {
      name: "MultiCompta",
      subtitle: "Portefeuille hors ligne",
      keywords: "budget,dépenses,argent,finance,comptabilité,hors ligne,portefeuille,tracking,gestion,revenu"
    },

    // 德文
    'de': {
      name: "MultiLedger",
      subtitle: "Offline Wallet & Budget",
      keywords: "Budget,Ausgaben,Geld,Finanzen,Buchführung,offline,Wallet,Tracking,Haushalt,Einkommen"
    },

    // 西班牙文
    'es': {
      name: "MultiCuenta",
      subtitle: "Cartera offline y presupuesto",
      keywords: "presupuesto,gastos,dinero,finanzas,contabilidad,offline,cartera,tracking,ingresos,ahorro"
    },

    // 意大利文
    'it': {
      name: "MultiRegistro",
      subtitle: "Portafoglio offline",
      keywords: "budget,spese,soldi,finanze,contabilità,offline,portafoglio,tracciamento,entrate,risparmio"
    },

    // 俄文
    'ru': {
      name: "МультиСчет",
      subtitle: "Оффлайн кошелек",
      keywords: "бюджет,расходы,деньги,финансы,учет,оффлайн,кошелек,трекинг,доходы,экономика"
    },

    // 葡萄牙文 - 巴西
    'pt-BR': {
      name: "MultiConta",
      subtitle: "Carteira offline e orçamento",
      keywords: "orçamento,gastos,dinheiro,finanças,contabilidade,offline,carteira,tracking,receitas,economia"
    },

    // 阿拉伯文
    'ar': {
      name: "محاسبتي المتعدد",
      subtitle: "محفظة دون اتصال",
      keywords: "ميزانية،مصروفات،مال،مالية،محاسبة،دون اتصال،محفظة，تتبع،دخل،توفير"
    },

    // 泰国语
    'th': {
      name: "บัญชีหลายบัญชี",
      subtitle: "กระเป๋าสตางค์ออฟไลน์",
      keywords: "งบประมาณ,รายจ่าย,เงิน,การเงิน,บัญชี,ออฟไลน์,กระเป๋า,ติดตาม,รายได้,ประหยัด"
    },

    // 越南语
    'vi': {
      name: "Đa Kế Toán",
      subtitle: "Ví ngoại tuyến",
      keywords: "ngân sách,chi tiêu,tiền,tài chính,kế toán,ngoại tuyến,ví,theo dõi,thu nhập,tiết kiệm"
    },

    // 马来西亚语
    'ms': {
      name: "MultiAkaun",
      subtitle: "Dompet luar talian",
      keywords: "belanjawan,perbelanjaan,wang,kewangan,akaun,luar talian,dompet,jejak,pendapatan,jimat"
    },

    // 印度尼西亚语
    'id': {
      name: "MultiCatatan",
      subtitle: "Dompet offline",
      keywords: "anggaran,pengeluaran,uang,keuangan,akuntansi,offline,dompet,pelacakan,pemasukan,hemat"
    },

    // 土耳其语
    'tr': {
      name: "MultiLedger",
      subtitle: "Çevrimdışı cüzdan",
      keywords: "bütçe,gider,para,finans,muhasebe,çevrimdışı,cüzdan,takip,gelir,tasarruf"
    },

    // 波兰语
    'pl': {
      name: "MultiLedger",
      subtitle: "Portfel offline",
      keywords: "budżet,wydatki,pieniądze,finanse,księgowość,offline,portfel,śledzenie,dochód,oszczędności"
    },

    // 荷兰语
    'nl': {
      name: "MultiLedger",
      subtitle: "Offline portemonnee",
      keywords: "budget,uitgaven,geld,financiën,boekhouding,offline,portemonnee,tracking,inkomen,sparen"
    },

    // 瑞典语
    'sv': {
      name: "MultiLedger",
      subtitle: "Offline plånbok",
      keywords: "budget,utgifter,penningar,finans,redovisning,offline,plånbok,spårning,inkomst,spara"
    },

    // 乌克兰语
    'uk': {
      name: "МультиРахунок",
      subtitle: "Офлайн гаманець",
      keywords: "бюджет,витрати,гроші,фінанси,облік,офлайн,гаманець,відстеження,доходи,економія"
    },

    // 希伯来语
    'he': {
      name: "MultiLedger",
      subtitle: "ארנק לא מקוון",
      keywords: "תקציב,הוצאות,כסף,פיננסים,חשבונאות,לא מקוון,ארנק,מעקב,הכנסות,חיסכון"
    },

    // 印地语
    'hi': {
      name: "MultiLedger",
      subtitle: "ऑफ़लाइन वॉलेट",
      keywords: "बजट,खर्च,पैसा,वित्त,लेखा,ऑफ़लाइन,वॉलेट,ट्रैकिंग,आय,बचत"
    },

    // 菲律宾语
    'fil': {
      name: "MultiLedger",
      subtitle: "Offline na pitaka",
      keywords: "budget,gastos,pera,pananalapi,accounting,offline,pitaka,tracking,kita,tipid"
    },

    // 孟加拉语
    'bn': {
      name: "MultiLedger",
      subtitle: "অফলাইন ওয়ালেট",
      keywords: "বাজেট,খরচ,টাকা,অর্থ,হিসাব,অফলাইন,ওয়ালেট,ট্র্যাকিং,আয়,সঞ্চয়"
    },

    // 丹麦语
    'da': {
      name: "MultiLedger",
      subtitle: "Offline tegnebog",
      keywords: "budget,udgifter,penge,finans,regnskab,offline,tegnebog,sporing,indkomst,spar"
    },

    // 芬兰语
    'fi': {
      name: "MultiLedger",
      subtitle: "Offline lompakko",
      keywords: "budjetti,kulut,raha,rahoitus,kirjanpito,offline,lompakko,seuranta,tulot,säästö"
    },

    // 挪威语
    'nb': {
      name: "MultiLedger",
      subtitle: "Offline lommebok",
      keywords: "budsjett,utgifter,penger,finans,regnskap,offline,lommebok,sporing,inntekt,sparing"
    },

    // 葡萄牙文 - 葡萄牙
    'pt-PT': {
      name: "MultiConta",
      subtitle: "Carteira offline",
      keywords: "orçamento,gastos,dinheiro,finanças,contabilidade,offline,carteira,rastreamento,receitas,economia"
    },

    // 希腊语
    'el': {
      name: "ΠολυΛογαριασμός",
      subtitle: "Πορτοφόλι εκτός σύνδεσης",
      keywords: "προϋπολογισμός,έξοδα,χρήματα,οικονομικά,λογιστική,εκτός σύνδεσης,πορτοφόλι,παρακολούθηση,εισόδημα,αποταμίευση"
    },

    // 加泰罗尼亚语
    'ca': {
      name: "MultiRegistre",
      subtitle: "Moneder sense connexió",
      keywords: "pressupost,despeses,diners,finances,comptabilitat,sense connexió,moneder,seguiment,ingressos,estalvi"
    }
  }
};

export default metadata;
