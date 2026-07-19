# 快速开始

3 步完成接入。

## 前置条件

- 仓库托管在 GitHub
- 仓库有 `bun.lock`（bun 项目）或 `uv.lock`（python 项目）
- （可选）企业微信群机器人 webhook key，用于 CI 通知

## Step 1: 复制 CI 样板

根据项目类型，从 `templates/` 复制对应文件到你的仓库 `.github/workflows/ci.yml`：

- Bun 项目：[`templates/bun-ci.yml`](../templates/bun-ci.yml)
- Python 项目：[`templates/python-ci.yml`](../templates/python-ci.yml)

或直接从 GitHub raw 下载：

```bash
# Bun 项目
curl -o .github/workflows/ci.yml \
  https://raw.githubusercontent.com/Yun-Hai-Org/ci-templates/v1/templates/bun-ci.yml

# Python 项目
curl -o .github/workflows/ci.yml \
  https://raw.githubusercontent.com/Yun-Hai-Org/ci-templates/v1/templates/python-ci.yml
```

## Step 2: 调整参数

打开 `.github/workflows/ci.yml`，按需调整 `with:` 下的参数：

| 参数                | 默认    | 说明                          |
| ------------------- | ------- | ----------------------------- |
| `project-type`      | `bun`   | `bun` 或 `python`             |
| `run-extended-lint` | `false` | 是否跑 hadolint/shellcheck 等 |
| `fail-on-severity`  | `high`  | 失败阈值                      |
| `wecom-notify`      | `true`  | 是否发企业微信通知            |

完整参数见 [Inputs 参考](inputs-reference.md)。

## Step 3: 配置 secrets（可选）

在仓库 Settings → Secrets and variables → Actions → New repository secret 添加：

- `WECOM_BOT_KEY`：企业微信群机器人 webhook key（配置后发 CI 通知）
- `SEMGREP_APP_TOKEN`：Semgrep App token（配置后启用 Semgrep 规则集）

所有 secret 均可选。未配置时对应工具自动跳过，不影响 CI 运行。详见 [企业微信通知配置](wecom-notification.md)。

## Step 4: 提交并观察

提交 `.github/workflows/ci.yml` 到仓库。提 PR 或 push 到 main 时，CI 自动触发：

1. 企业微信收到 "CI 开始" 通知
2. lint / security / dependency 三阶段并行检查
3. 企业微信收到 "CI 完成" 或 "CI 失败" 通知，含各阶段结果与 CI 链接

## 下一步

- [Inputs 参考](inputs-reference.md)
- [项目类型详解](project-types.md)
- [企业微信通知配置](wecom-notification.md)
- [迁移指南](migration-guide.md)
- [FAQ](faq.md)

## 高级配置：D/E/F 类

v1.1 新增 D/E/F 三类能力，全部默认关闭，按需开启。

### D 类：上线前卡点

适合团队成熟后逐步启用。开启后 PR 必须通过 OPA 策略、敏感数据扫描、Jira 工单关联、Agent 配置 Schema 校验、commitlint 才能 merged。

```yaml
with:
  run-release-gates: true
  jira-prefix: 'PROJ' # 你的 Jira 项目前缀
  jira-warning-only: true # 过渡期先 warning
  schema-check-paths: 'agents/*.json' # 有 Agent 配置时启用
```

详见 [Release Gates](release-gates.md)。

### E 类：上线后验证

调用真实 LLM 或压测目标服务，有成本，**不建议每次 PR 都跑**。建议 `schedule` 或 `workflow_dispatch` 触发。

```yaml
on:
  schedule:
    - cron: '0 3 * * 1' # 每周一凌晨
  workflow_dispatch:

jobs:
  ci:
    uses: Yun-Hai-Org/ci-templates/.github/workflows/standard-ci.yml@v1
    with:
      run-release-gates: true # E 类依赖 D 类通过
      run-ai-content-test: true
      run-load-test: true
      run-db-benchmark: true
    secrets:
      OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

详见 [AI 内容测试](ai-content-testing.md) / [压测](load-testing.md) / [DB 基准](db-benchmark.md)。

### F 类：流程卡点

PR 模板和发布 checklist 已内置在模板仓库的 `.github/` 下，业务仓库可参考修改。

- [PR 模板与发布 Checklist](pr-checklist.md)
- [commitlint + husky 本地钩子](commitlint-husky.md)

### B+ 类：外部安全服务

引入 SonarQube / Snyk / GitGuardian，全部 optional secret。

详见 [外部安全服务](external-security-tools.md)。
