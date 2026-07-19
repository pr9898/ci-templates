# Organization Ruleset 全局强制接入

通过 GitHub 组织级 Repository Ruleset，对所有仓库的 PR 强制运行 `standard-ci.yml`，业务仓库**无需放任何 ci.yml**——零代码接入，PR 不通过则 Merge 按钮锁定。

## 适用场景

- 团队规模较大，逐个仓库配 ci.yml 维护成本高
- 需要组织级硬性合规卡点，防止开发者绕过 CI
- 所有业务仓库在同一 GitHub Organization 下

## 版本限制

| GitHub 版本             | 公开仓库  | 私有仓库    |
| ----------------------- | --------- | ----------- |
| Free for Organizations  | ✅ 可强制 | ❌ 不可强制 |
| Team / Enterprise Cloud | ✅ 可强制 | ✅ 可强制   |

> 私有仓库 + Free 组织：只能用[仓库内 ci.yml 方式](../README.md#接入方式)，无法用 Ruleset 全局强制。

## 配置步骤

需组织管理员权限。

### 1. 准备中央 CI 模板

确保 `pr9898/ci-templates` 仓库的 `standard-ci.yml` 可正常调用（已完成）。

### 2. 创建规则集

1. 进入 Organization → Settings → Rulesets → **New branch ruleset**
2. 命名，如 `Global Code Quality Gate`

### 3. 选择目标

- **Target repositories**：
  - `All repositories`：强制应用到名下所有仓库
  - `Dynamic rules`：按标签/语言动态筛选（如只强制 `TypeScript` 仓库）
- **Target branches**：`Include default branch`（通常 `main`）

### 4. 绑定强制工作流

1. 勾选 `Require status checks to pass before merging`
2. 勾选 `Require workflows to pass before merging`
3. `Add workflow`：
   - Repository: `pr9898/ci-templates`
   - Workflow: `.github/workflows/standard-ci.yml`
   - Ref: `v1`

### 5. 灰度测试

Enforcement status 先设为 **Evaluate**（评估模式）：

- CI 会在所有目标仓库的 PR 上触发运行
- 失败**不阻断** PR，仅显示结果
- 适合上线前排查兼容性问题

确认无误后切 **Active** 正式生效。

## 业务仓库侧效果

配置后，业务仓库**无需任何 ci.yml**，提 PR 时：

1. GitHub 自动在后台拉取并运行 `pr9898/ci-templates/.github/workflows/standard-ci.yml@v1`
2. PR Checks 显示 `standard-ci.yml` 运行结果
3. 任一检查失败 → Merge 按钮锁定，无法绕过

业务仓库仍可配置 secrets（在仓库 Settings → Secrets → Actions）：

- `WECOM_BOT_KEY`：企业微信通知
- `SEMGREP_APP_TOKEN` / `SONAR_TOKEN` / `SNYK_TOKEN` 等：外部安全服务
- `OPENAI_API_KEY` / `ANTHROPIC_API_KEY`：E 类 AI 内容测试

未配置的 secret 对应检查自动跳过。

## 自定义检查参数

Ruleset 触发的 workflow 使用 `standard-ci.yml` 的默认 inputs。如需为特定仓库启用 D/E 类检查：

### 方式 A：仓库内 ci.yml 覆盖

在业务仓库放一个 ci.yml，显式传 inputs（会覆盖 Ruleset 的默认调用）：

```yaml
# 业务项目 .github/workflows/ci.yml
name: CI
on: [pull_request]
jobs:
  ci:
    uses: pr9898/ci-templates/.github/workflows/standard-ci.yml@v1
    with:
      project-type: 'bun'
      run-release-gates: true
      jira-prefix: 'PROJ'
```

### 方式 B：Ruleset 调用时传 inputs

GitHub Ruleset 当前不支持给 workflow 传 `with:` 参数。如需自定义 inputs，只能用方式 A。

## 与本地钩子的关系

Ruleset 在 CI 层强制卡点。本地钩子（commitlint / husky）在开发者机器上提前拦截，避免提 PR 后才发现问题。两者互补：

- 本地钩子：`git commit` 时校验 message 格式
- Ruleset CI：PR 提交后强制运行完整检查

参考 [commitlint + husky 本地钩子](commitlint-husky.md)。

## 常见问题

### Q: Ruleset 触发的 workflow 在 PR 上看不到？

确认：

1. 规则集 Enforcement status 是 `Active` 或 `Evaluate`
2. 目标仓库在 Target repositories 范围内
3. `pr9898/ci-templates` 仓库的 `standard-ci.yml` 可被访问（公开仓库或同 org）

### Q: Ruleset 和仓库内 ci.yml 冲突吗？

不冲突。两者都会在 PR 上运行。如果业务仓库有自己的 ci.yml，会多一个 check；Ruleset 的 `standard-ci.yml` 也会跑。建议业务仓库要么用 Ruleset（不放 ci.yml），要么用 ci.yml（关闭 Ruleset 对该仓库的强制）。

### Q: 如何临时跳过 Ruleset 强制？

组织管理员可以在规则集里把特定仓库加入排除列表，或临时把 Enforcement status 切回 `Evaluate`。**不建议**用 `--no-verify` 绕过——那只跳过本地钩子，Ruleset 的 CI 检查仍会运行。

## 参考

- [GitHub Rulesets 官方文档](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [Required workflows 迁移到 Rulesets 的说明](https://github.blog/changelog/2023-09-14-required-workflows-is-now-available-in-repository-rulesets/)
