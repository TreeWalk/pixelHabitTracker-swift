# PixelQuest 👾

> **"Gamify your life, one pixel at a time."**  
> 把生活变成一场复古像素 RPG 冒险。

**PixelQuest** 是一款基于 iOS 原生 **SwiftUI** 开发的习惯养成与生活管理应用。它采用经典的 8-bit 像素风格（致敬 NES/红白机时代），将枯燥的日常任务转化为英雄的成长冒险。

---

## 🌟 核心特色 (Features)

### 1. 角色属性系统 (Character Stats)

你的每一次行动都会增强角色的核心属性：

| 属性 | 图标 | 对应活动 | 描述 |
|------|------|----------|------|
| 🔥 **Strength** | `flame.fill` | 运动健身 | 记录健身时长，提升力量值 |
| � **Intellect** | `book.fill` | 阅读学习 | 追踪阅读进度，增长智慧 |
| 💧 **Health** | `drop.fill` | 睡眠休息 | 监测睡眠质量，恢复活力 |
| � **Wealth** | `yensign.circle.fill` | 财务管理 | 记账理财，积累财富 |
| ⚡ **Spirit** | `bolt.fill` | 任务完成 | 完成日常任务，提升精神力 |

### 2. 沉浸式像素 UI (Immersive Pixel UI)

- **NES 风格交互**: 复古像素按钮、双层描边边框、硬阴影效果
- **动态仪表盘**: 首页即角色状态面板，直观展示各项属性进度条
- **自定义像素字体**: 使用 VT323 字体呈现经典红白机文字风格
- **视差滚动地图**: 根据现实时间自动切换背景氛围（清晨/白昼/黄昏/深夜）

### 3. RPG 化生活管理

- **任务系统 (Quests)**: 支持单次/每日/每周/每月周期任务，任务完成带振动反馈
- **图书馆 (Library)**: 管理阅读清单、追踪阅读进度、评分与笔记
- **收藏品系统 (Items)**: 像素风格背包，收集不同稀有度物品（普通/稀有/史诗/传奇）
- **地图探索 (Map)**: Home、Gym、Library、Company 四大地点，各维度数据统计

### 4. 快捷记录中心 (Quick Entry)

中央悬浮按钮 (FAB)，扇形展开 5 个快捷入口：

| 按钮 | 功能 | 描述 |
|------|------|------|
| 🛏️ **Sleep** | 睡眠记录 | 记录睡眠时间与质量 |
| 🏃 **Sport** | 运动记录 | 选择运动类型并记录时长 |
| 💸 **Bill** | 账单记录 | 快速记录收支明细 |
| 📖 **Read** | 阅读记录 | 更新阅读进度页数 |
| ✅ **Quest** | 快速任务 | 一键完成待办任务 |

### 5. 数据可视化

- **热力图**: Quest Log 页面展示任务完成情况热力图
- **统计面板**: 各维度详情页展示周/月统计数据
- **进度条**: 分段式像素进度条直观展示属性值

---

## 🛠 技术栈 (Tech Stack)

### 核心框架
| 技术 | 用途 |
|------|------|
| **SwiftUI** | UI 框架 (iOS 17+) |
| **SwiftData** | 本地数据持久化 |
| **Combine** | 响应式数据流 |

### 架构设计
- **MVVM 模式**: View ↔ ViewModel (Store) ↔ Model
- **EnvironmentObject**: 全局状态注入
- **@Observable**: SwiftData 模型观察

### 数据存储 (SwiftData Stores)
| Store | 职责 |
|-------|------|
| `SwiftDataQuestStore` | 任务与任务日志管理 |
| `SwiftDataBookStore` | 图书与阅读记录 |
| `SwiftDataExerciseStore` | 运动数据 |
| `SwiftDataSleepStore` | 睡眠记录 |
| `SwiftDataFinanceStore` | 财务账单与快照 |
| `SwiftDataItemStore` | 收藏品管理 |

### 资源与设计系统
| 资源 | 描述 |
|------|------|
| **VT323 字体** | Google Fonts 像素字体 |
| **DesignSystem.swift** | 统一设计系统（颜色、边框、阴影） |
| **Localization** | 中英双语支持 |
| **Assets Catalog** | 像素图标与多分辨率适配 |

---

## 📂 项目结构

```
PixelQuest/
├── PixelQuestApp.swift      # 应用入口，注入环境对象
├── ContentView.swift        # 主视图，TabBar + FAB
├── DesignSystem.swift       # 像素风格设计系统
├── Font+Pixel.swift         # 自定义像素字体扩展
│
├── Models/                  # 数据模型
│   ├── Quest.swift          # 任务模型 (类型/周期)
│   ├── BookEntry.swift      # 图书模型
│   ├── ExerciseEntry.swift  # 运动记录
│   ├── SleepEntry.swift     # 睡眠记录
│   ├── FinanceEntry.swift   # 账单记录
│   ├── ItemData.swift       # 收藏品模型
│   └── SwiftData/           # SwiftData @Model 实体
│
├── ViewModels/              # 状态管理 (Stores)
│   ├── SwiftDataQuestStore.swift
│   ├── SwiftDataBookStore.swift
│   ├── SwiftDataExerciseStore.swift
│   ├── SwiftDataSleepStore.swift
│   ├── SwiftDataFinanceStore.swift
│   └── SwiftDataItemStore.swift
│
├── Views/
│   ├── Dashboard/           # 首页仪表盘
│   │   ├── DashboardView.swift
│   │   ├── FiveElementCard.swift
│   │   └── RecordsViews.swift
│   ├── Quests/              # 任务列表
│   ├── Map/                 # 地图与地点详情
│   ├── Items/               # 收藏品背包
│   ├── QuickEntry/          # 快捷记录弹窗
│   ├── Settings/            # 设置页面
│   └── Components/          # 复用 UI 组件
│
├── Services/                # 业务服务层
├── Managers/                # 管理器 (音效等)
├── Intents/                 # App Intents (Shortcuts)
└── Resources/               # 本地化文件
```

---

## 🚀 快速开始 (Getting Started)

### 环境要求
- **Xcode 15+**
- **iOS 17.0+**
- **Swift 5.9+**

### 运行步骤

1. 克隆项目:
   ```bash
   git clone [repository_url]
   cd frontend-swift
   ```

2. 打开项目:
   ```bash
   open PixelQuest/PixelQuest.xcodeproj
   ```

3. 选择模拟器 (推荐 iPhone 15/16 Pro) 并运行:
   ```
   Cmd + R
   ```

---

## 🎮 主要功能模块

### Dashboard (仪表盘)
首页展示 5 张属性卡片，点击可展开查看详情并跳转至对应记录页面。

### Quests (任务)
- 创建不同类型任务 (Health/Intellect/Strength/Spirit/Skill)
- 支持多种周期 (单次/每日/每周/每月)
- 完成任务时触发振动反馈

### Map (地图)
像素风格世界地图，4 大地点对应不同生活维度，可查看各地点历史记录。

### Items (收藏)
4x4 格子背包系统，物品分 4 个稀有度等级，支持添加和删除。

### Quick Entry (快捷入口)
中央 FAB 按钮，扇形展开 5 个快捷记录入口，无需进入子页面即可完成记录。

---

## 📱 App Intents

支持 iOS Shortcuts 快捷指令，可通过 Siri 或快捷指令 App 快速记录数据。

---

Designed with ❤️ by Tree.
