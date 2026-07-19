# commitlint + husky 本地钩子

CI 中的 commitlint 检查在 `release-gates.yml` 中（仅 PR 事件触发）。
本地钩子让你在 `git commit` 时就发现格式问题，避免提 PR 后才发现。

## 两种方案

| 方案 | 工具               | 适用                           |
| ---- | ------------------ | ------------------------------ |
| A    | husky + commitlint | JS/TS 项目，已用 npm           |
| B    | pre-commit 框架    | 多语言项目，或偏好 Python 生态 |

## 方案 A: husky + commitlint

### Step 1: 安装依赖

```bash
npm install --save-dev husky @commitlint/cli \
  @commitlint/config-conventional \
  commitlint-plugin-jira-rules commitlint-config-jira
```

### Step 2: 初始化 husky

```bash
npx husky init
```

会创建 `.husky/` 目录并在 `package.json` 添加 `prepare` 脚本。

### Step 3: 复制配置

```bash
cp /path/to/ci-templates/templates/commitlint.config.js .
cp /path/to/ci-templates/templates/.husky/commit-msg .husky/
cp /path/to/ci-templates/templates/.husky/pre-commit .husky/
chmod +x .husky/commit-msg .husky/pre-commit
```

### Step 4: 修改 Jira 前缀

编辑 `commitlint.config.js`，把 `JIRA_PREFIX` 改成你的项目前缀：

```javascript
const JIRA_PREFIX = 'PROJ' // ← 改成你的
```

### Step 5: 验证

```bash
# 应该失败
echo "bad commit message" | npx commitlint

# 应该通过
echo "feat: [PROJ-1234] 添加用户登录" | npx commitlint
```

## 方案 B: pre-commit 框架

### Step 1: 安装 pre-commit

```bash
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg
```

### Step 2: 复制配置

```bash
cp /path/to/ci-templates/templates/_pre-commit-config.yaml .
```

### Step 3: 添加 commitlint hook

在 `.pre-commit-config.yaml` 末尾追加：

```yaml
- repo: https://github.com/alessandrojcm/commitlint-pre-commit-hook
  rev: v9.18.0
  hooks:
    - id: commitlint
      stages: [commit-msg]
      additional_dependencies: ['@commitlint/config-conventional']
```

### Step 4: 验证

```bash
pre-commit run --all-files
```

## commit message 规范

### Conventional Commits 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### type 列表

| type       | 用途                   |
| ---------- | ---------------------- |
| `feat`     | 新功能                 |
| `fix`      | Bug 修复               |
| `docs`     | 文档                   |
| `style`    | 代码风格（不影响功能） |
| `refactor` | 重构                   |
| `perf`     | 性能优化               |
| `test`     | 测试                   |
| `build`    | 构建 / 依赖            |
| `ci`       | CI 配置                |
| `chore`    | 杂项                   |
| `revert`   | 回滚                   |

### Jira 工单 ID

commit message 中必须包含 `[PROJ-1234]` 格式的工单 ID（位置不限，但建议在 subject 或 footer）：

```
feat: [PROJ-1234] 添加用户登录

实现手机号 + 验证码登录流程。

Refs: [PROJ-1234]
```

## CI 与本地一致性

CI 中的 commitlint（`release-gates.yml`）和本地 husky 用**同一份** `commitlint.config.js`。
修改配置后，CI 与本地同时生效。

如果业务仓库未提供 `commitlint.config.js`，CI 会用模板默认配置（Conventional Commits + references-empty 规则）。

## 常见问题

### husky 钩子不触发

检查 `.husky/` 文件是否有可执行权限：

```bash
chmod +x .husky/*
```

检查 `package.json` 是否有 `prepare` 脚本：

```json
{
  "scripts": {
    "prepare": "husky"
  }
}
```

### 跳过单次校验

紧急情况下可跳过（不推荐，CI 仍会校验）：

```bash
git commit --no-verify -m "..."
```

### 团队成员未安装 husky

clone 仓库后执行 `npm install` 会自动触发 `prepare` 脚本安装 husky。
如未生效，手动执行 `npx husky install`。
