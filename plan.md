这是为您整合了 **交互架构 (v2.1)**、**技术实现 (v3.0)** 以及 **五行卡片深度设计** 的最终版 **《PixelQuest 全链路交互设计规范书 (v4.0)》**。

这份文档是 **Dan Saffer** 为您准备的“开发蓝图”，直接可用作编码参考。

---

# PixelQuest 全链路交互设计规范书 (v4.0)

**Reviewer:** Dan Saffer (Persona)
**Date:** 2026-01-10
**Scope:** 架构重构 / UI 细节 / SwiftUI 技术实现

## 1. 核心设计原则 (Core Principles)

1. **工具优先 (Tool First)**：高频记录操作（记账、打卡）必须在 **1秒 / 2步** 内触发。
2. **数据可视化 (Data HUD)**：首页即仪表盘，用直观的进度条和数值替代静态说明文本。
3. **沉浸式陪伴 (Immersive Companionship)**：利用“时间流逝”和“视差滚动”赋予 App 生命力，而非强行制造游戏关卡。

---

## 2. 信息架构重构 (Information Architecture)

底部导航栏 (Tab Bar) 最终定稿顺序：

| 顺序 | Tab 名称 | 图标 (SF Symbols) | 功能定义 |
| --- | --- | --- | --- |
| **1** | **Dashboard** | `person.crop.circle` | **总控台 (原 Profile)**：五行属性 HUD，核心状态一览。 |
| **2** | **Actions** | `scroll` | **行动中心**：每日任务列表 + **全局快速记录 FAB**。 |
| **3** | **Assets** | `chest.fill` (自定义) | **资产库**：物品与财务（支持 RPG/报表 双模式切换）。 |
| **4** | **World** | `map.fill` | **生活画卷**：基于时间变化的地点卡片展示，用于回顾与欣赏。 |

---

## 3. 首页：五行仪表盘深度设计 (Dashboard Deep Dive)

**设计目标**：将原先静态的卡片改造为 **可交互的数据 HUD**，采用“渐进式披露”原则。

### 3.1 五行卡片逻辑映射

| 属性 | 对应生活维度 | 核心指标 (Gauge 数据) | 展开后详情 (Expanded) |
| --- | --- | --- | --- |
| **🔥 火 (Strength)** | 运动 / 健身 | **本周时长** (例如: 120/150 min) | 最近 3 条运动记录 (Gym, Run) |
| **🌿 木 (Intellect)** | 阅读 / 学习 | **书籍进度** (例如: 45%) | 当前在读书籍封面 + 笔记数 |
| **💧 水 (Health)** | 睡眠 / 饮水 | **今日睡眠** (例如: 7.5/8 hr) | 本周睡眠曲线缩略图 |
| **🟡 金 (Wealth)** | 财务 / 资产 | **净资产** (无上限，仅显示数值) | 本月收支概览 (Income vs Expense) |
| **🏔️ 土 (Spirit)** | 任务完成度 | **今日任务** (例如: 4/5 Done) | 待办任务数概览 |

### 3.2 交互逻辑 (Interaction)

* **默认状态 (Collapsed)**：展示图标、属性名、当前核心数值的进度条 (Gauge)。
* **点击交互 (Tap)**：卡片原地垂直展开 (Accordion Animation)，露出“展开后详情”区域。
* **视觉反馈**：点击时卡片有轻微缩放 (`scale: 0.98`) 和触觉反馈。

### 3.3 SwiftUI 组件实现 (FiveElementCard)

```swift
struct FiveElementCard: View {
    let type: ElementType // 枚举：fire, wood, etc.
    let currentValue: Double
    let targetValue: Double
    let label: String     // e.g., "120 mins"
    
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // --- 头部：常驻显示区 ---
            HStack(alignment: .center) {
                // 1. 图标容器
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(type.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: type.icon)
                        .foregroundStyle(type.color)
                        .font(.title2)
                }
                
                // 2. 进度条区域 (iOS 16 Gauge)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(type.name).font(.custom("VT323", size: 18))
                        Spacer()
                        Text(label).font(.caption).bold().foregroundStyle(.secondary)
                    }
                    
                    // 核心数据可视化
                    Gauge(value: currentValue, in: 0...targetValue) {
                    }
                    .gaugeStyle(.accessoryLinear) // 线性进度条
                    .tint(type.color)
                }
            }
            .contentShape(Rectangle()) // 扩大点击区域
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
            // --- 底部：展开详情区 ---
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    // 这里放置具体子视图，例如最近记录
                    ForEach(0..<2) { _ in
                        HStack {
                            Text("Yesterday's Run").font(.caption)
                            Spacer()
                            Text("+30 mins").font(.caption).foregroundStyle(type.color)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color("CardBackground")) // 适配深色模式的背景色
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

```

---

## 4. 行动中心：全局悬浮按钮 (FAB Technical Specs)

**设计目标**：无需寻找，一键记录。符合菲茨定律。

### 交互与实现

* **位置**：覆盖在 TabView 之上的 `ZStack` 顶层。
* **效果**：点击 `+`，背景高斯模糊，4 个子按钮扇形弹出。
* **路由**：点击子按钮不跳转页面，而是弹出半屏 Sheet (`.sheet(presentationDetents: [.medium])`) 进行快速输入。

```swift
// FAB 核心逻辑
ZStack(alignment: .bottom) {
    // 底层主视图
    TabView { ... }

    // 遮罩层
    if isMenuOpen {
        Rectangle()
            .fill(.ultraThinMaterial) // 磨砂玻璃效果
            .ignoresSafeArea()
            .onTapGesture { withAnimation { isMenuOpen = false } }
        
        // 子按钮群 (扇形布局)
        VStack(spacing: 24) {
            HStack(spacing: 30) {
                ActionButton(icon: "moon.fill", color: .blue, label: "Sleep")
                ActionButton(icon: "figure.run", color: .red, label: "Sport")
            }
            HStack(spacing: 30) {
                ActionButton(icon: "book.fill", color: .green, label: "Read")
                ActionButton(icon: "yen.circle.fill", color: .yellow, label: "Bill")
            }
        }
        .offset(y: -120) // 位于主按钮上方
        .transition(.scale.combined(with: .opacity).animation(.bouncy))
    }

    // 主 FAB 按钮
    Button(action: {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.bouncy(duration: 0.3)) { isMenuOpen.toggle() }
    }) {
        Image(systemName: "plus")
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 64, height: 64)
            .background(Color.accentColor)
            .clipShape(Circle())
            .shadow(radius: 10)
            .rotationEffect(.degrees(isMenuOpen ? 45 : 0)) // 旋转变成 X
    }
    .padding(.bottom, 10) // 稍微悬浮于 TabBar 之上
}

```

---

## 5. 资产库：模式切换 (Assets View Modes)

**设计目标**：解决“RPG 爽感”与“财务焦虑”的冲突。

### 实现方案

* **控制组件**：`Picker(selection: $mode, label: Text("Mode"))`。
* **RPG Mode**：显示大图标 (Pixel Art)、属性加成 (e.g., "INT +5")、稀有度边框。
* **Finance Mode**：显示紧凑列表、折旧计算 (e.g., "¥72.2/day")、总价值。

```swift
// 列表行渲染逻辑
List(items) { item in
    if viewMode == .bag {
        // RPG 样式
        HStack(spacing: 16) {
            PixelIconView(item.iconName) // 大图
            VStack(alignment: .leading) {
                Text(item.name).font(.custom("VT323", size: 20))
                Text("INT +5 • CHA +2").font(.caption).foregroundStyle(.secondary)
            }
        }
    } else {
        // 财务样式
        HStack {
            Text(item.name).font(.body)
            Spacer()
            VStack(alignment: .trailing) {
                Text(item.formattedPrice).bold()
                Text("\(item.dailyCost)/day").font(.caption2).foregroundStyle(.red)
            }
        }
    }
}

```

---

## 6. 世界画卷：视差与时间 (World Tab Technical Specs)

**设计目标**：无需游戏引擎，用 UI 实现动态画卷。

### 6.1 核心逻辑

1. **时间感知 (Time Awareness)**：
* 读取 `Calendar.current.component(.hour)`。
* `06-12`: 加载 `_morning` 图片。
* `12-18`: 加载 `_noon` 图片。
* `18-06`: 加载 `_night` 图片。


2. **视差滚动 (Parallax)**：
* 利用 `GeometryReader` 监控卡片在屏幕上的 Y 轴坐标。
* 反向移动背景图片，创造 2.5D 深度感。



### 6.2 视差卡片完整代码 (ParallaxCard)

```swift
struct ParallaxLocationCard: View {
    let title: String      // e.g. "HOME BASE"
    let baseImage: String  // e.g. "home_pixel"
    
    // 动态计算当前时间后缀
    var timeSuffix: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h >= 6 && h < 18 { return "_day" } else { return "_night" }
    }

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            
            ZStack(alignment: .bottom) {
                // 1. 背景层：动态时间图 + 视差偏移
                Image("\(baseImage)\(timeSuffix)")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    // 视差核心：高度拉伸 + 坐标反向偏移
                    .frame(width: geo.size.width, 
                           height: geo.size.height + (minY > 0 ? minY : 0))
                    .offset(y: -minY * 0.15) // 0.15 为视差强度
                    .clipped()
                
                // 2. 遮罩层：保证文字可读性
                LinearGradient(colors: [.clear, .black.opacity(0.8)], 
                               startPoint: .center, endPoint: .bottom)
                
                // 3. HUD 层：信息展示
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text(title).font(.custom("VT323", size: 32)).foregroundStyle(.white)
                        Text("Level 5 • Rest Area").font(.caption).foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    // 简单的状态灯
                    Circle().fill(.green).frame(width: 8, height: 8)
                        .shadow(color: .green, radius: 4)
                }
                .padding(20)
            }
        }
        .frame(height: 240) // 卡片固定高度
        .cornerRadius(20)
        .shadow(radius: 10, y: 5)
    }
}

```

---

## 7. 开发执行路线图 (Roadmap)

这是 Dan Saffer 建议的 MVP 开发顺序：

1. **Phase 1 (骨架 - Days 1-3)**：
* 搭建 Tab Bar 结构。
* 实现 **Action Center (FAB)** 逻辑（因为这是记录数据的入口，优先级最高）。
* 完成 **Dashboard 五行卡片** 的 Collapsed 状态。


2. **Phase 2 (血液 - Days 4-5)**：
* 实现 **Assets** 的双模式切换。
* 完善五行卡片的 Expanded 状态，接入真实数据。


3. **Phase 3 (灵魂 - Days 6-7)**：
* 切图：准备 Home, Gym, Library, Company 的早晚两套图。
* 实现 **World** 页面的视差组件。
* 加入微交互（打卡震动、金币音效）。