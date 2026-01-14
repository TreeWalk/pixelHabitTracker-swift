# PixelQuest 👾

> **"Gamify your life, one pixel at a time."**
> 把生活变成一场复古像素 RPG 冒险。

**PixelQuest** 是一款基于 iOS 原生 **SwiftUI** 开发的习惯养成与生活管理应用。它采用经典的 8-bit 像素风格（致敬 NES/红白机时代），将枯燥的日常任务转化为英雄的成长属性。

---

## 🌟 核心特色 (Features)

### 1. 五行属性系统 (Five Elements)
你的每一次行动都会增强角色的核心属性，基于五行理论设计：

*   � **Fire (Strength)**: 运动健身 \-\> 提升 **力量**
*   🟢 **Wood (Intellect)**: 阅读学习 \-\> 提升 **智力**
*   � **Water (Health)**: 睡眠饮水 \-\> 提升 **活力**
*   🟡 **Metal (Wealth)**: 财务管理 \-\> 提升 **财富**
*   🟤 **Spirit (Earth)**: 任务完成 \-\> 提升 **精神**

### 2. 沉浸式像素 UI (Immersive Pixel UI)
*   **NES 风格交互**: 圆角矩形按钮、黑色描边、复古音效，还原童年游戏体验。
*   **动态仪表盘**: 首页即 HUD (Heads-Up Display)，直观展示角色各项数值。
*   **视差滚动世界**: "World" 页面根据现实时间（清晨/白昼/黄昏/深夜）自动切换背景，并带有视差滚动效果。

### 3. RPG 化生活管理
*   **任务系统 (Quests)**: 像接悬赏任务一样完成待办事项。
*   **库存管理 (Inventory)**: 既然是 RPG，当然有背包！收集虚拟物品，查看稀有度。
*   **地图探索**: Home, Gym, Library, Company 四大地点对应生活的不同维度。

### 4. 快捷操作 (Action Center)
*   全局悬浮按钮 (FAB)，扇形展开子菜单。
*   **快速记录**: 一键记录睡眠、运动、阅读和账单，拒绝繁琐。

---

## 🛠 技术栈 (Tech Stack)

*   **UI 框架**: SwiftUI (iOS 17+)
*   **数据持久化**: SwiftData (本地存储，隐私安全)
*   **架构设计**: MVVM
*   **资源管理**: 
    *   Assets Catalog (像素图标/多分辨率适配)
    *   Localization (中英双语支持)
*   **字体**: VT323 (Google Fonts 像素字体)

---

## 🚀 快速开始 (Getting Started)

1.  克隆项目到本地:
    ```bash
    git clone [repository_url]
    ```
2.  确保安装 **Xcode 15+**。
3.  打开 `PixelQuest/PixelQuest.xcworkspace` (或 `.xcodeproj`)。
4.  选择模拟器 (推荐 iPhone 15/16 Pro) 并运行 `Cmd + R`。

---

## 📂 项目结构

```
PixelQuest/
├── App/                # 入口文件
├── Models/             # SwiftData 模型 (Quest, Log, Item...)
├── Views/
│   ├── Dashboard/      # 首页五行 HUD
│   ├── Quests/         # 任务列表
│   ├── Assets/         # 背包与财务
│   ├── World/          # 地图与视差背景
│   └── Components/     # 复古 UI 组件库
├── ViewModels/         # 状态管理
└── Resources/          # 像素资源与本地化文件
```

---

Designed with ❤️ by Tree.
