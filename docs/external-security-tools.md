# 外部安全服务（SonarQube / Snyk / GitGuardian）

B+ 类扩展，在 `security-scans.yml` 中集成三个外部安全服务。全部 optional secret，缺失时优雅跳过。

## 服务对比

| 服务        | 类型     | 覆盖范围                       | 需要的 secret         |
| ----------- | -------- | ------------------------------ | --------------------- |
| SonarQube   | SAST     | 代码质量 + 安全漏洞 + 重复代码 | `SONAR_TOKEN`         |
| Snyk        | SCA      | 第三方依赖漏洞                 | `SNYK_TOKEN`          |
| GitGuardian | 密钥扫描 | 代码中泄露的密钥 / 凭证        | `GITGUARDIAN_API_KEY` |

## 与现有工具的分工

| 工具            | 位置                 | 用途                         |
| --------------- | -------------------- | ---------------------------- |
| Semgrep         | `security-scans.yml` | 通用 SAST（规则集 auto）     |
| Semgrep 自定义  | `release-gates.yml`  | 项目特定规则（`.semgrep/`）  |
| Gitleaks        | `security-scans.yml` | 密钥扫描（开源）             |
| Trivy           | `security-scans.yml` | 文件系统 + IaC + 依赖        |
| **SonarQube**   | `security-scans.yml` | 代码质量 + 跨文件分析        |
| **Snyk**        | `security-scans.yml` | 依赖漏洞（含许可证）         |
| **GitGuardian** | `security-scans.yml` | 密钥扫描（SaaS，含历史扫描） |

> SonarQube / Snyk / GitGuardian 与现有开源工具有部分重叠，但提供更深入的规则集、更详细的报告、以及 SaaS 仪表盘。

## 启用方式

### Step 1: 配置 secrets

在 GitHub Org 或仓库 Settings → Secrets → Actions 添加：

```
SONAR_TOKEN=<your-sonar-token>
SNYK_TOKEN=<your-snyk-token>
GITGUARDIAN_API_KEY=<your-ggshield-key>
```

全部 optional，配哪个用哪个。

### Step 2: 在 ci.yml 传递

```yaml
jobs:
  ci:
    uses: Yun-Hai-Org/ci-templates/.github/workflows/standard-ci.yml@v1
    secrets:
      WECOM_BOT_KEY: ${{ secrets.WECOM_BOT_KEY }}
      SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      GITGUARDIAN_API_KEY: ${{ secrets.GITGUARDIAN_API_KEY }}
```

不需要在 `with:` 下加开关——`security-scans.yml` 根据 secret 是否存在自动决定执行或跳过。

## SonarQube 配置

### 获取 token

1. 登录 SonarQube（自建或 SonarCloud）
2. Account → Security → Generate Tokens
3. 复制 token

### 可选：项目级配置

在业务仓库根目录添加 `sonar-project.properties`：

```properties
sonar.projectKey=my-project
sonar.organization=my-org
sonar.sources=src
sonar.tests=tests
sonar.exclusions=**/node_modules/**,**/*.spec.ts
sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

不添加也能跑，会用默认值（扫描整个仓库）。

### SonarCloud vs 自建 SonarQube

- SonarCloud：SaaS，免费版支持公开仓库
- 自建 SonarQube：需要额外配置 `SONAR_HOST_URL`（当前 workflow 未暴露，需要时在 `security-scans.yml` 加 `args: -Dsonar.host.url=...`）

## Snyk 配置

### 获取 token

1. 注册 [snyk.io](https://snyk.io)
2. Account Settings → API Tokens → Show
3. 复制 token

### 扫描行为

`security-scans.yml` 中的 Snyk 步骤：

```
snyk test --severity-threshold=high --fail-on=all
```

- `--severity-threshold=high`：仅报告 HIGH / CRITICAL
- `--fail-on=all`：发现任何漏洞即失败

调整阈值需要修改 `security-scans.yml`（或未来通过 input 暴露）。

### Snyk 监控（可选）

除了 CI 阻断式扫描，Snyk 还支持持续监控：

```bash
snyk monitor
```

会定期扫描并通知新漏洞。当前 workflow 未启用，需要时在业务仓库自定义。

## GitGuardian 配置

### 获取 API key

1. 注册 [dashboard.gitguardian.com](https://dashboard.gitguardian.com)
2. API Access → Personal Access Tokens → Create
3. 复制 key

### 扫描行为

`security-scans.yml` 中的 GitGuardian 步骤：

```
ggshield secret scan ci
```

扫描所有 commit 的增量变更，发现密钥泄露则失败。

### 与 Gitleaks 的分工

| 工具        | 优势                                               |
| ----------- | -------------------------------------------------- |
| Gitleaks    | 开源，无需 token，覆盖基础规则                     |
| GitGuardian | SaaS，规则更全，含历史扫描仪表盘，支持自定义检测器 |

二者可同时启用，互补不冲突。

## 缺失 secret 的行为

任一 secret 未配置时：

```bash
::warning::secret SONAR_TOKEN not set, skipping SonarQube scan
```

CI 继续执行，不阻断其他步骤。企业微信通知的"安全扫描"状态反映实际执行的扫描结果。

## 成本提示

| 服务        | 免费额度                     | 超额     |
| ----------- | ---------------------------- | -------- |
| SonarCloud  | 公开仓库无限；私有仓库按行数 | 付费计划 |
| Snyk        | 每月 200 次测试              | 付费计划 |
| GitGuardian | 每月 50 次扫描               | 付费计划 |

私有仓库 + 高频 CI 可能很快用完免费额度。建议：

- PR 事件触发：SonarQube + GitGuardian
- schedule 触发：Snyk 全量扫描
- 仅 main 分支触发外部服务，feature 分支用开源工具
