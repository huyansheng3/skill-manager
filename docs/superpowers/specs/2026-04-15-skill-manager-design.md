# Skill Manager - Design Spec

macOS 原生极简技能管理工具，用于管理 Claude Code / CodeFlicker Agent Skills。

## 项目概述

- **目标:** 提供一个原生极简的 GUI 工具来管理 Agent Skills，支持全局技能和工作区技能的移动管理
- **平台:** macOS 原生应用，使用 Swift + SwiftUI 开发
- **打包体积目标:** < 10MB（纯原生编译，无额外依赖）
- **分发:** 同时支持 Homebrew Cask 和安装脚本（GitHub Release）两种安装方式

## 功能需求

### 1. 扫描全局技能目录
- 默认扫描路径：
  - `~/.claude/skills`
  - `~/.codeflicker/skills`
- 支持用户添加其他自定义技能扫描路径
- 列出所有已安装技能，显示基本信息

### 2. 读取 Duet 工作区数据库
- 读取 `~/.codeflicker/data/codeflicker/duet.sqlite`
- 提取所有工作区信息（ID、名称、路径）
- 列出每个工作区已关联的技能

### 3. 技能移动操作
- 支持将**全局技能**移动到**某个工作区**，避免全局污染
- 支持将**工作区技能**移回**全局**共享
- 移动实质：文件系统目录移动到对应位置

### 4. 启用/禁用技能
- 通过重命名目录实现（如 `skill-name` → `skill-name.disabled`）
- 不删除文件，只是让 Agent 不再加载
- 可随时重新启用

### 5. 搜索筛选技能
- 按技能名称搜索
- 按位置筛选（全局/工作区）
- 按启用/禁用状态筛选

### 6. 查看技能详情
- 显示技能名称
- 显示技能描述（从 skill.json 或 README 提取）
- 显示作者信息
- 显示完整文件路径
- 显示磁盘占用大小

### 7. 删除技能
- 彻底删除技能目录及所有文件
- 删除前有确认提示，防止误删

## 技术架构

采用标准 SwiftUI 分层架构，清晰分离职责：

```
SkillManager/
├── App/                # 应用入口和主窗口配置
├── Views/              # SwiftUI 视图层
│   ├── SkillList.swift          # 技能列表主视图
│   ├── SkillDetail.swift        # 技能详情侧边栏/页
│   ├── WorkspaceSection.swift  # 工作区分组展示
│   └── SearchBar.swift          # 搜索栏
├── ViewModels/         # 视图状态和业务逻辑
│   ├── SkillListViewModel.swift
│   └── SkillDetailViewModel.swift
├── Models/             # 数据模型定义
│   ├── Skill.swift
│   ├── Workspace.swift
│   └── SkillLocation.swift
├── Services/           # 基础设施服务
│   ├── SkillScanner.swift      # 扫描技能目录
│   ├── DuetSQLiteReader.swift  # 读取 Duet SQLite 数据库
│   ├── SkillService.swift      # 技能操作（移动/启用禁用/删除）
│   ├── FileSystem.swift        # 文件操作封装
│   └── SkillMetadataParser.swift # 解析 skill.json/README 获取描述
└── Resources/          # 静态资源
```

## 数据模型

### Skill
```swift
struct Skill: Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let author: String?
    let path: URL
    let location: SkillLocation
    var isEnabled: Bool
    let workspaceId: UUID? // 如果是工作区技能
    let size: Int64 // 磁盘占用大小
}

enum SkillLocation {
    case global
    case workspace(Workspace)
}
```

### Workspace
```swift
struct Workspace: Identifiable {
    let id: UUID
    let name: String
    let rootPath: String
    let skillsPath: URL // 工作区技能目录: rootPath/.codeflicker/skills
}
```

## 核心工作流程

1. **App 启动** → `App` 初始化 `SkillListViewModel`
2. **ViewModel 调用** → `SkillScanner.scanAll() + DuetSQLiteReader.readWorkspaces()`
3. **扫描结果合并** → 将全局技能和工作区技能合并到一个列表，按分组展示
4. **用户操作**（移动/启用禁用/删除/搜索）→ ViewModel 调用对应的 Service 方法
5. **操作完成** → 重新刷新技能列表

## 数据访问

- **SQLite 读取:** 使用 `SQLite.swift` 或原生 `sqlite3` C 接口（原生更小，推荐）
- **文件系统:** 使用 `FileManager` 原生 API
- **无外部数据库** 运行时不需要持久化存储，全部从文件系统和现有 SQLite 读取

## UI 设计

- **主布局:** 左侧导航（全局技能 + 工作区列表） → 右侧技能列表
- **搜索框:** 顶部常驻搜索框
- **详情:** 点击技能显示侧边详情面板
- **原生样式:** 使用标准 SwiftUI 组件，符合 macOS 设计规范

## 分发安装

### Homebrew Cask
- 项目配置 `Formula` 或 `Cask` 文件
- 用户可通过 `brew install --cask skill-manager` 安装

### 脚本安装
- 编译打包 `.app` → 压缩为 `.zip`
- 上传到 GitHub Release
- 提供一键安装脚本，用户 `curl ... | bash` 即可安装到 `/Applications`

## 成功标准

- [ ] 能正确扫描所有全局技能并展示
- [ ] 能正确读取 Duet SQLite 并列出工作区及其技能
- [ ] 能正常移动技能（全局 ↔ 工作区）
- [ ] 能启用/禁用技能
- [ ] 能搜索筛选
- [ ] 能查看详情
- [ ] 能删除技能
- [ ] 编译后 .app 体积 < 10MB
- [ ] 两种安装方式都可用
