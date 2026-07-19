# 迁移指南

从自维护 CI 迁移到 `Yun-Hai-Org/ci-templates`。

## 迁移步骤

### 1. 备份现有 CI

```bash
cp -r .github/workflows .github/workflows.backup
git commit -am "backup: existing CI before migration"
```

### 2. 确定项目类型

根据项目主要语言：

- TypeScript / JavaScript → `bun`
- Python → `python`

如项目同时包含两者，v1 暂不支持 `fullstack`，选择主要语言对应的类型，或拆分两个 workflow。

### 3. 复制样板

```bash
# Bun 项目
cp /path/to/ci-templates/templates/bun-ci.yml .github/workflows/ci.yml

# Python 项目
cp /path/to/ci-templates/templates/python-ci.yml .github/workflows/ci.yml
```

或从 GitHub raw 下载：

```bash
curl -o .github/workflows/ci.yml \
  https://raw.githubusercontent.com/Yun-Hai-Org/ci-templates/v1/templates/bun-ci.yml
```

### 4. 迁移 secrets

将原有 secrets 映射到新接口：

| 原 secret            | 新 secret                                | 说明             |
| -------------------- | ---------------------------------------- | ---------------- |
| 自定义 semgrep token | `SEMGREP_APP_TOKEN`                      | Semgrep 规则集   |
| 自定义通知 webhook   | `WECOM_BOT_KEY`                          | 企业微信群机器人 |
| DockerHub 凭证       | `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` | Trivy 拉镜像用   |
| Gitleaks 许可        | `GITLEAKS_LICENSE`                       | 私有仓库需要     |

原有不在新接口里的 secret，如果是项目特有的，在业务仓库新增独立 workflow 引用。

### 5. 删除旧 workflow 文件

确认新 CI 跑通后，删除旧的 workflow 文件。`.github/workflows.backup` 可保留一段时间作为回滚参考。

```bash
rm .github/workflows/old-ci.yml
# 或删除所有旧文件，只保留 ci.yml
```

### 6. 验证

提 PR 观察新 CI：

- 三阶段检查（lint / security / dependency）是否跑通
- 企业微信通知是否收到（开始 + 结束）
- 各 secret 是否正确传递（无 warning）
- 失败阈值是否符合预期

## 迁移检查清单

- [ ] 项目类型已确定（bun / python）
- [ ] `.github/workflows/ci.yml` 已替换为样板
- [ ] `WECOM_BOT_KEY` secret 已配置（如需通知）
- [ ] `SEMGREP_APP_TOKEN` secret 已配置（如需 semgrep）
- [ ] 首次 PR 的 CI 全绿
- [ ] 企业微信收到开始 / 结束通知
- [ ] 旧 workflow 文件已删除
- [ ] 团队已知晓新 CI 的开关参数

## v1.0 → v1.1 升级

v1.1 新增 D/E/F 类能力，**完全向后兼容**——v1.0 用户零改动即可升级。

### 无需任何改动

- `@v1` moving tag 自动指向 v1.1.0
- 所有新增 inputs 默认关闭
- 所有新增 secrets 缺失时优雅跳过
- A/B/C 类行为完全不变

### 可选：启用 D 类上线卡点

```yaml
with:
  run-release-gates: true
  jira-prefix: 'PROJ'
  jira-warning-only: true # 过渡期先 warning
```

业务仓库需准备：

- `policy/` 目录（参考模板仓库 `policy/` 示例，或留空跳过 OPA）
- `.semgrep/` 目录（参考模板仓库 `.semgrep/` 规则集，或留空跳过自定义规则）
- `commitlint.config.js`（参考 `templates/commitlint.config.js`，或用 CI 默认配置）

### 可选：启用 B+ 类外部安全服务

```yaml
secrets:
  SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  GITGUARDIAN_API_KEY: ${{ secrets.GITGUARDIAN_API_KEY }}
```

配哪个用哪个，未配的自动跳过。详见 [外部安全服务](external-security-tools.md)。

### 可选：启用 E 类上线后验证

建议单独配 `schedule` workflow，避免每次 PR 都跑：

```yaml
# .github/workflows/weekly-e2e.yml
name: Weekly E2E
on:
  schedule:
    - cron: '0 3 * * 1'
jobs:
  ci:
    uses: Yun-Hai-Org/ci-templates/.github/workflows/standard-ci.yml@v1
    with:
      run-release-gates: true
      run-ai-content-test: true
      run-load-test: true
      run-db-benchmark: true
    secrets:
      OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

### 新增 secrets 映射

| v1.1 新增 secret      | 用途                 | 是否必须 |
| --------------------- | -------------------- | -------- |
| `SONAR_TOKEN`         | SonarQube 扫描       | 否       |
| `SNYK_TOKEN`          | Snyk 依赖扫描        | 否       |
| `GITGUARDIAN_API_KEY` | GitGuardian 密钥扫描 | 否       |
| `OPENAI_API_KEY`      | promptfoo 调用 LLM   | 否       |
| `ANTHROPIC_API_KEY`   | promptfoo 调用 LLM   | 否       |

### F 类流程模板

业务仓库可参考模板仓库的 `.github/PULL_REQUEST_TEMPLATE.md` 和 `.github/ISSUE_TEMPLATE/release-checklist.md`，复制到自己的 `.github/` 目录即可启用。这些是仓库级文件，不走 reusable workflow，模板仓库升级不会自动同步。

## 常见迁移问题

### 本地与 CI 结果不一致

CI 用 `bun.lock` / `uv.lock` 锁定工具版本。本地执行：

```bash
# Bun 项目
bun install --frozen-lockfile

# Python 项目
uv sync --frozen
```

确保本地版本与 CI 一致。pyright / ruff / eslint 等工具版本由 lockfile 决定。

### 某些检查不需要

在 `with:` 下关闭：

```yaml
with:
  run-extended-lint: false # 不跑 hadolint 等
  run-knip: false # 仅跳过 knip
  run-osv-scanner: false # 不跑 OSV（默认已关）
```

### 需要保留原有自定义检查

在业务仓库新增独立 workflow（如 `.github/workflows/custom.yml`），与 `ci.yml` 并存。`ci.yml` 负责标准检查，`custom.yml` 负责项目特有检查。

```yaml
# .github/workflows/custom.yml
name: Custom Checks
on: [pull_request]
jobs:
  my-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/my-custom-check.sh
```

### 原有 SARIF 上传怎么办

`security-scans.yml` 已内置 semgrep SARIF 上传（`github/codeql-action/upload-sarif@v3`）。业务项目无需额外配置，semgrep 结果会自动出现在仓库 Security 标签页。

### monorepo 怎么办

使用 `working-directory` input 指定子目录：

```yaml
with:
  project-type: 'python'
  working-directory: 'services/api'
```

注意：`working-directory` 影响所有 run step 的 cwd。如果不同子目录需要不同 project-type，目前需要在业务仓库配置多个 job 分别调用 `standard-ci.yml`。

### 原有缓存配置要迁移吗

不需要。中心仓库已内置缓存策略（bun / uv / trivy db / semgrep），业务项目无需重复配置。
