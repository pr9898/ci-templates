# Inputs 与 Secrets 参考

`standard-ci.yml` 通过 `workflow_call` 暴露以下接口。业务项目在 `with:` 和 `secrets:` 下传递。

## Inputs

| input | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `project-type` | string | `bun` | `bun` 或 `python`（v1 仅这两种） |
| `run-static-analysis` | boolean | `true` | A 类总开关（type-check / lint / format） |
| `run-security-scan` | boolean | `true` | B 类总开关（semgrep / gitleaks / trivy / knip / checkov / conftest） |
| `run-dependency-audit` | boolean | `true` | C 类总开关（dep-audit / lockfile-freshness） |
| `run-extended-lint` | boolean | `false` | hadolint / shellcheck / stylelint / sqlfluff |
| `run-knip` | boolean | `true` | JS 死代码检测（仅 bun 类型生效） |
| `run-osv-scanner` | boolean | `false` | OSV 全量扫描（慢，建议定时任务用） |
| `fail-on-severity` | string | `high` | `none` / `low` / `medium` / `high` / `critical` |
| `bun-version` | string | `latest` | setup-bun 安装的 Bun 版本 |
| `python-version` | string | `3.12` | setup-python 安装的 Python 版本 |
| `working-directory` | string | `.` | 工作子目录（monorepo 支持） |
| `wecom-notify` | boolean | `true` | 是否发送企业微信开始/结束通知 |
| `debug` | boolean | `false` | 开启 debug 输出（打印 inputs 等） |

## Secrets

全部可选，缺失时优雅跳过并 warning，不阻断 CI。

| secret | 用途 | 缺失行为 |
| --- | --- | --- |
| `WECOM_BOT_KEY` | 企业微信群机器人 webhook 的 key | 跳过通知，warning |
| `SEMGREP_APP_TOKEN` | Semgrep App 规则集 token | 跳过 semgrep step，warning |
| `GITLEAKS_LICENSE` | Gitleaks 私有仓库许可 | gitleaks 用社区版（功能受限） |
| `DOCKERHUB_USERNAME` | Trivy 拉镜像避免限流 | 跳过登录，trivy 仍跑（可能慢） |
| `DOCKERHUB_TOKEN` | 同上 | 同上 |

## 使用示例

### 最简接入（bun 项目，无 secret）

```yaml
jobs:
  ci:
    uses: pr9898/ci-templates/.github/workflows/standard-ci.yml@v1
    with:
      project-type: 'bun'
```

### 完整配置（python 项目，带通知和 semgrep）

```yaml
jobs:
  ci:
    uses: pr9898/ci-templates/.github/workflows/standard-ci.yml@v1
    with:
      project-type: 'python'
      python-version: '3.11'
      run-extended-lint: true
      fail-on-severity: 'medium'
      wecom-notify: true
    secrets:
      WECOM_BOT_KEY: ${{ secrets.WECOM_BOT_KEY }}
      SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

### 仅安全扫描（legacy 项目）

```yaml
jobs:
  ci:
    uses: pr9898/ci-templates/.github/workflows/standard-ci.yml@v1
    with:
      project-type: 'bun'
      run-static-analysis: false
      run-dependency-audit: false
      run-security-scan: true
      wecom-notify: true
    secrets:
      WECOM_BOT_KEY: ${{ secrets.WECOM_BOT_KEY }}
```

## fail-on-severity 行为

影响 trivy / semgrep / gitleaks / pip-audit 的失败阈值：

| 值 | trivy severity | audit 行为 |
| --- | --- | --- |
| `none` | LOW,MEDIUM,HIGH,CRITICAL（exit 0） | 发现漏洞不 fail |
| `low` | LOW,MEDIUM,HIGH,CRITICAL | fail |
| `medium` | MEDIUM,HIGH,CRITICAL | fail |
| `high` | HIGH,CRITICAL | fail（默认） |
| `critical` | CRITICAL | fail |
