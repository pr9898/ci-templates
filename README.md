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
┌──────────────────────────────────────────────────────────────────────┐
│  standard-ci.yml (对外唯一入口)                                       │
│                                                                       │
│  notify-start ──► lint ──────────┐                                    │
│                  security (B+) ──┤                                    │
│                  dependency ─────┤                                    │
│                  release-gates(D)┤──► [ai-content, load-test,        │
│                                  │     db-benchmark] (E) ──► notify-end│
└──────────────────────────────────────────────────────────────────────┘
         │              │              │            │
         ▼              ▼              ▼            ▼
   lint-checks    security-scans  dependency   release-gates
   (A 类)         (B 类 + B+ 外部) (C 类)        (D 类)
                                                       │
                                                       ▼
                                              ai-content / load-test
                                              / db-benchmark (E 类)

  F 类：PR 模板 / release checklist / commitlint+husky / 文档
```

- **A 类 静态分析与格式化**：type-check / lint / extended-lint / format
- **B 类 安全扫描**：semgrep / gitleaks / trivy / knip / checkov / conftest
- **B+ 类 外部安全服务**：SonarQube / Snyk / GitGuardian（v1.1 新增，optional secret）
- **C 类 依赖审计**：dep-audit / pip-audit / lockfile-freshness
- **D 类 上线前卡点**：OPA test / Semgrep 自定义规则 / 敏感数据扫描 / Jira 校验 / Schema 校验 / commitlint（v1.1 新增，默认关闭）
- **E 类 上线后验证**：promptfoo AI 内容安全 / k6 压测 / pgbench DB 基准（v1.1 新增，默认关闭）
- **F 类 流程卡点**：PR 模板 / 发布 checklist / 本地钩子模板（v1.1 新增）
- **企业微信通知**：CI 开始前 + 完成后自动发送 markdown 消息到群机器人

## 如何用本项目做 CI 检查

业务项目只需在自己仓库放一个 `.github/workflows/ci.yml`，`uses:` 指向本仓库的 `standard-ci.yml@v1`，即可获得完整的 A/B/C 三类共 13 项 CI 检查 + 企业微信通知。

### 触发时机

在业务仓库的 ci.yml 里定义 `on:`，常见配置：

```yaml
on:
  pull_request: # 提 PR 时触发（推荐）
  push:
    branches: [main] # push 到 main 时触发
```

也可加 `workflow_dispatch:` 支持手动触发，或用 `schedule:` 定时跑依赖审计。

### 检查内容（按 project-type 自动选择）

| 阶段             | bun 项目                                                          | python 项目                                             |
| ---------------- | ----------------------------------------------------------------- | ------------------------------------------------------- |
| **A. 静态分析**  | `bunx tsc --noEmit` → `eslint` → `prettier --check`               | `uv run pyright` → `ruff check` → `ruff format --check` |
| **B. 安全扫描**  | semgrep + gitleaks + trivy + knip + checkov + conftest            | semgrep + gitleaks + trivy + checkov + conftest         |
| **B+. 外部安全** | SonarQube + Snyk + GitGuardian（optional secret）                 | 同左                                                    |
| **C. 依赖审计**  | `bun install --frozen-lockfile` → `bun audit --production`        | `uv sync --frozen` → `uv run pip-audit`                 |
| **D. 上线卡点**  | OPA test / Semgrep 自定义 / 敏感数据 / Jira / Schema / commitlint | 同左                                                    |
| **E. 上线验证**  | promptfoo / k6 / pgbench（默认关闭）                              | 同左                                                    |

A/B/C/D 类**并行执行**，互不阻塞。E 类依赖 D 类通过后触发。`run-extended-lint: true` 还会追加 hadolint / shellcheck / stylelint / sqlfluff。

### 看到的结果

**企业微信群**（配置 `WECOM_BOT_KEY` 后）：

```
🚀 CI 开始
仓库: your-org/your-app | 分支: feature/x | 触发者: someone
[查看 CI 详情](https://github.com/...)

✅ CI 完成（或 ❌ CI 失败）
lint: success | security: success | dependency: failure
[查看 CI 详情](https://github.com/...)
```

**GitHub PR 页面**：

- Checks 标签显示 `Lint & Format` / `Security Scan` / `Dependency Audit` 三个 job 状态
- Semgrep 发现的漏洞出现在仓库 Security 标签页（SARIF 上传）
- Gitleaks 在 PR 上评论泄露位置

### 失败处理

- **HIGH/CRITICAL** 漏洞或检查失败 → 阻断 PR（默认）
- **MEDIUM** → 警告但不阻断
- **LOW** → 仅报告
- 用 `fail-on-severity` 调整阈值：`none` / `low` / `medium` / `high`（默认）/ `critical`

某个工具的 secret 没配？对应 step 自动跳过并 warning，不阻断其他检查。

### 接入只需 3 步

1. **复制样板**：从 `templates/` 选 `bun-ci.yml` 或 `python-ci.yml`，存为业务仓库的 `.github/workflows/ci.yml`
2. **配置 secret**（可选）：在 GitHub Org 层面配一次 `WECOM_BOT_KEY`（见 [Secrets 配置](#secrets-配置)）
3. **提 PR**：自动触发，观察企业微信通知和 PR Checks

详细的参数调整、项目类型选择、迁移步骤见 [docs/getting-started.md](docs/getting-started.md)。

## Quick Start

最小可用的业务仓库 ci.yml（详见上文 [如何用本项目做 CI 检查](#如何用本项目做-ci-检查)）：

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
      project-type: 'bun' # 或 'python'
      wecom-notify: true
    secrets:
      WECOM_BOT_KEY: ${{ secrets.WECOM_BOT_KEY }} # org-level 配一次即可
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

| secret                | 用途                                                      |
| --------------------- | --------------------------------------------------------- |
| `WECOM_BOT_KEY`       | 企业微信群机器人 webhook key，配置后发送 CI 开始/结束通知 |
| `SEMGREP_APP_TOKEN`   | Semgrep App 规则集 token                                  |
| `GITLEAKS_LICENSE`    | Gitleaks 私有仓库许可                                     |
| `DOCKERHUB_USERNAME`  | Trivy 拉镜像避免限流                                      |
| `DOCKERHUB_TOKEN`     | 同上                                                      |
| `SONAR_TOKEN`         | SonarQube 扫描 token（v1.1）                              |
| `SNYK_TOKEN`          | Snyk 依赖扫描 token（v1.1）                               |
| `GITGUARDIAN_API_KEY` | GitGuardian 密钥扫描（v1.1）                              |
| `OPENAI_API_KEY`      | promptfoo 调用 OpenAI（v1.1）                             |
| `ANTHROPIC_API_KEY`   | promptfoo 调用 Anthropic（v1.1）                          |

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

| input                  | 默认    | 说明                                             |
| ---------------------- | ------- | ------------------------------------------------ |
| `project-type`         | `bun`   | `bun` / `python`                                 |
| `run-static-analysis`  | `true`  | A 类总开关                                       |
| `run-security-scan`    | `true`  | B 类总开关（含 B+ 外部服务）                     |
| `run-dependency-audit` | `true`  | C 类总开关                                       |
| `run-extended-lint`    | `false` | hadolint / shellcheck / stylelint / sqlfluff     |
| `fail-on-severity`     | `high`  | `none`/`low`/`medium`/`high`/`critical`          |
| `run-release-gates`    | `false` | D 类上线卡点（OPA / Jira / Schema / commitlint） |
| `run-ai-content-test`  | `false` | E 类 promptfoo AI 内容安全                       |
| `run-load-test`        | `false` | E 类 k6 / Locust 压测                            |
| `run-db-benchmark`     | `false` | E 类 pgbench DB 基准                             |
| `jira-prefix`          | `""`    | Jira 项目前缀（如 `PROJ`）                       |
| `wecom-notify`         | `true`  | 是否发送企业微信通知                             |

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
- [Release Gates（D 类上线卡点）](docs/release-gates.md)
- [AI 内容安全测试](docs/ai-content-testing.md)
- [压测配置](docs/load-testing.md)
- [DB 基准测试](docs/db-benchmark.md)
- [commitlint + husky 本地钩子](docs/commitlint-husky.md)
- [外部安全服务](docs/external-security-tools.md)
- [PR 模板与发布 Checklist](docs/pr-checklist.md)

## License

MIT
