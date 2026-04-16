# Architecture - SkillManager

macOS 原生极简 Skill 管理工具的架构文档。

## 项目概览

| 维度 | 说明 |
|------|------|
| **平台** | macOS 原生 Swift + SwiftUI |
| **依赖** | 零第三方依赖（使用原生 `sqlite3` 接口，不需要 SQLite.swift） |
| **编译体积** | < 1MB（压缩后 ~200KB），满足 < 10MB 设计目标 |
| **设计目标** | 极简、原生、快速 |

## 技能启用/禁用规范

SkillManager 遵循 Claude Code / CodeFlicker 原生规范：

| 状态 | 目录命名 | Agent 行为 |
|------|---------|-----------|
| ✅ 启用 | `skill-name` | 正常加载 |
| ⛔ 禁用 | `skill-name.disabled` | 扫描跳过，不加载 |

> 这种方式不需要修改任何配置文件，完全兼容原生加载机制，安全可逆。

## 技术架构

采用标准 SwiftUI 分层架构，清晰分离职责：

```
SkillManager/
├── App/                    # 应用入口
│   └── SkillManagerApp.swift      # App 入口和主窗口配置
├── Views/                  # SwiftUI 视图层
│   ├── SkillListView.swift         # 技能列表主视图
│   ├── SkillDetailView.swift       # 技能详情侧边栏
│   ├── WorkspaceSection.swift      # 工作区分组展示
│   └── SearchBar.swift             # 搜索栏
├── ViewModels/             # 视图状态和业务逻辑
│   ├── SkillListViewModel.swift
│   └── SkillDetailViewModel.swift
├── Models/                 # 数据模型定义
│   ├── Skill.swift
│   ├── Workspace.swift
│   └── SkillLocation.swift
├── Services/               # 基础设施服务
│   ├── SkillScanner.swift          # 扫描技能目录
│   ├── DuetSQLiteReader.swift      # 读取 Duet SQLite 数据库
│   ├── SkillService.swift          # 技能操作（移动/启用禁用/删除）
│   ├── FileSystem.swift            # 文件操作封装
│   └── SkillMetadataParser.swift   # 解析 skill.json/SKILL.md 获取描述
└── Resources/              # 静态资源
    └── SkillManager.icns          # App 图标
```

## 数据模型

### Skill

```swift
struct Skill: Identifiable {
    let id: UUID
    let name: String           // 技能名称（去掉 .disabled 后缀）
    let description: String?   // 从 SKILL.md frontmatter 提取
    let author: String?
    let path: URL              // 完整文件路径
    let location: SkillLocation // 位置：全局/工作区
    var isEnabled: Bool        // 是否启用
    let workspaceId: UUID?     // 如果是工作区技能，关联工作区 ID
    let size: Int64            // 磁盘占用大小
}
```

### Workspace

```swift
struct Workspace: Identifiable {
    let id: UUID
    let name: String
    let rootPath: String
    let skillsPath: URL // .codeflicker/skills 路径
}
```

### SkillLocation

```swift
enum SkillLocation {
    case global
    case workspace(Workspace)
}
```

## 核心服务

| 服务 | 职责 |
|------|------|
| `SkillScanner` | 扫描多个全局技能目录，检测启用/禁用状态，计算大小 |
| `DuetSQLiteReader` | 读取 `~/.codeflicker/data/codeflicker/duet.sqlite` 获取工作区列表 |
| `SkillService` | 封装技能操作：移动位置、切换启用禁用、删除，都通过文件系统操作实现 |
| `SkillMetadataParser` | 解析 SKILL.md YAML frontmatter 获取 description 和 author |

## 核心工作流程

```
App 启动
  ↓
ViewModel 初始化
  ↓
SkillScanner.scanAll() + DuetSQLiteReader.readWorkspaces()
  ↓
合并扫描结果，按分组展示（全局技能 + 各工作区）
  ↓
用户操作（移动/启用禁用/删除/搜索）
  ↓
ViewModel → Service 执行文件系统操作
  ↓
操作完成，重新刷新技能列表
```

## 数据访问

- **SQLite 读取**: 使用原生 `sqlite3` C 接口，不需要引入第三方依赖，保持体积小巧
- **文件系统**: 使用 `FileManager` 原生 API
- **无本地数据库**: 运行时不需要持久化存储，全部从文件系统和现有 Duet 数据库读取

## 安装分发

两种分发方式都已支持：

### 1. 一键脚本安装

```bash
curl -fsSL CDN_URL/SkillManager.zip | bash
```

脚本内置 SHA256 校验，确保下载完整性。

### 2. Homebrew Cask

```ruby
cask "skill-manager" do
  version "1.0.0"
  sha256 "..."
  url "CDN_URL/SkillManager.zip"
  app "SkillManager.app"
end
```

## 发布流程

项目提供自动化发布脚本 `scripts/release.sh`：

```bash
./scripts/release.sh
```

自动执行：
1. 清理构建 → 2. xcodebuild 编译 → 3. 打包 zip → 4. 计算 SHA256
5. 更新 `install.sh` → 6. 更新 Homebrew Formula → 7. 上传 KCDN

## .gitignore 约定

- 不提交编译产物：`SkillManager.app/`, `SkillManager.zip`
- 不提交本地配置：`.codeflicker/`, `build/`, `.build/`
- 保留项目必需的 Xcode 配置：`project.pbxproj`, `contents.xcworkspacedata`
