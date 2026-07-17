# Central CI Templates

中心化 CI 模板仓库，通过 GitHub Actions **Reusable Workflows** 让业务项目用几行 `uses:` 调用统一的 CI 流水线。升级工具、调整规则只改本仓库，所有调用方自动生效——告别"复制粘贴地狱"。

## 架构

```
业务项目 .github/workflows/ci.yml
  │
  │  uses: pr9898/ci-templates/.github/workflows/standard-ci.yml@v1
  │  with: { project-type: 'bun', ... }
  │  secrets: { WECOM_BOT_KEY: ..., SEMGREP_APP_TOKEN: ... }
  ▼
┌─────────────────────────────────────────────────────────┐
│  standard-ci.yml (对外唯一入口)                          │
│                                                          │
│  notify-start ──► lint ──┐                               │
│                  security ├─► notify-end                 │
│                  dep ─────┘                               │
└─────────────────────────────────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
   lint-checks    security-scans  dependency-audit
   (A 类 4 项)    (B 类 6 项)      (C 类 3 项)
```

- **A 类 静态分析与格式化**：type-check / lint / extended-lint / format
- **B 类 安全扫描**：semgrep / gitleaks / trivy / knip / checkov / conftest
- **C 类 依赖审计**：dep-audit / pip-audit / lockfile-freshness
- **企业微信通知**：CI 开始前 + 完成后自动发送 markdown 消息到群机器人

## Quick Start

1. **复制模板**：从 `templates/` 选对应项目类型的样板到你的仓库 `.github/workflows/ci.yml`
2. **改参数**：修改 `project-type`（`bun` 或 `python`）和 `secrets` 映射
3. **配置 secrets**（可选，全部缺失也能跑）：推荐在 GitHub **Organization 层面**配一次 `WECOM_BOT_KEY`，所有仓库自动继承（见下文 [Secrets 配置](#secrets-配置)）
4. **提交 PR**：观察 CI 结果与企业微信通知

```yaml
# 业务项目 .github/workflows/ci.yml
name: CI
on:
  pull_request:
  push:
    branches: [main]
jobs:
  ci:
    uses: pr9898/ci-templates/.github/workflows/standard-ci.yml@v1
    with:
      project-type: 'bun'
      run-extended-lint: true
      fail-on-severity: 'high'
      wecom-notify: true
    secrets:
      WECOM_BOT_KEY: ${{ secrets.WECOM_BOT_KEY }}
      SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

## Project Types

v1 首版支持：

| project-type | 适用场景                    | type-check       | lint         | format                | knip | dep-audit   | lockfile                        |
| ------------ | --------------------------- | ---------------- | ------------ | --------------------- | ---- | ----------- | ------------------------------- |
| `bun`        | JS/TS 项目（含 MCP Server） | `bunx tsc`       | `eslint`     | `prettier`            | ✅   | `bun audit` | `bun install --frozen-lockfile` |
| `python`     | Python 项目                 | `uv run pyright` | `ruff check` | `ruff format --check` | —    | `pip-audit` | `uv sync --frozen`              |

所有 project-type 默认跑 B 类安全扫描（semgrep / gitleaks / trivy）。

## Secrets

**全部可选**，缺失时优雅跳过并 warning，不阻断 CI：

| secret               | 用途                                                      |
| -------------------- | --------------------------------------------------------- |
| `WECOM_BOT_KEY`      | 企业微信群机器人 webhook key，配置后发送 CI 开始/结束通知 |
| `SEMGREP_APP_TOKEN`  | Semgrep App 规则集 token                                  |
| `GITLEAKS_LICENSE`   | Gitleaks 私有仓库许可                                     |
| `DOCKERHUB_USERNAME` | Trivy 拉镜像避免限流                                      |
| `DOCKERHUB_TOKEN`    | 同上                                                      |

### Secrets 配置

**推荐：Organization-level Secret（配一次，所有仓库通用）**

业务仓库都在同一个 GitHub Organization 下时，在 org 层面配一次，所有仓库自动继承，业务仓库 **无需各自配置**：

1. 打开 GitHub Organization → Settings → Secrets and variables → Actions
2. New organization secret
3. Name: `WECOM_BOT_KEY`
4. Value: 企业微信群机器人 webhook URL 中 `key=` 后面的部分
   （webhook 形如 `https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=abc12345-...`，只取 `abc12345-...`）
5. Repository access: 选 `All repositories`
6. Add secret

配置后，业务仓库的 ci.yml 写 `secrets: WECOM_BOT_KEY: ${{ secrets.WECOM_BOT_KEY }}`，GitHub 会自动从 org 级别取值——**业务仓库 Settings 里不需要再配**。换 webhook key 时只改 org 一处，所有仓库立即生效。

> **技术说明**：GitHub Actions 的 secret 查找是层级继承的（Repository → Organization → Environment）。业务仓库未配置同名 secret 时，自动向上找到 org 级别的值。reusable workflow 跨仓库调用时无法直接读取调用方未传递的 secret，所以"中心仓库代发"不可行——org-level secret 是实现"配一次通用"的唯一方式。

**备选：Repository-level Secret**

业务仓库不在同一 org，或需要不同仓库发到不同群时，在每个业务仓库 Settings → Secrets and variables → Actions 单独配置。详见 [企业微信通知配置](docs/wecom-notification.md)。

## Inputs

详见 [docs/inputs-reference.md](docs/inputs-reference.md)。常用：

| input                  | 默认    | 说明                                         |
| ---------------------- | ------- | -------------------------------------------- |
| `project-type`         | `bun`   | `bun` / `python`                             |
| `run-static-analysis`  | `true`  | A 类总开关                                   |
| `run-security-scan`    | `true`  | B 类总开关                                   |
| `run-dependency-audit` | `true`  | C 类总开关                                   |
| `run-extended-lint`    | `false` | hadolint / shellcheck / stylelint / sqlfluff |
| `fail-on-severity`     | `high`  | `none`/`low`/`medium`/`high`/`critical`      |
| `wecom-notify`         | `true`  | 是否发送企业微信通知                         |

## 版本管理

业务项目统一使用 `@v1`（moving tag，自动获得 minor 补丁）：

```yaml
uses: pr9898/ci-templates/.github/workflows/standard-ci.yml@v1
```

稳定性要求高的项目可锁精确版本 `@v1.0.0`。**不要用 `@main`**。

## 文档

- [快速开始](docs/getting-started.md)
- [Inputs 与 Secrets 参考](docs/inputs-reference.md)
- [项目类型详解](docs/project-types.md)
- [企业微信通知配置](docs/wecom-notification.md)
- [迁移指南](docs/migration-guide.md)
- [FAQ](docs/faq.md)

## License

MIT
