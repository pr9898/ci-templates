# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-07-18

### Added

#### D 类：上线前卡点（`release-gates.yml`）

- `release-gates.yml` 可复用 workflow，聚合 6 项上线前检查
- OPA 策略单元测试（`opa test ./policy/...`），验证 Rego 策略逻辑（白盒）
- OPA fmt 检查，确保 Rego 文件格式化
- Semgrep 自定义规则集扫描（`.semgrep/` 目录，无需 token）
- Jira 工单 ID 关联校验（PR 标题 + 所有 commit message）
- Agent 配置 JSON Schema 校验（ajv）
- 测试集目录校验（`tests/` 存在且被 Git 跟踪）
- commitlint CI 检查（Conventional Commits + Jira 规则）
- `policy/` 示例目录：`authz/` / `config/` / `sensitive/` 三组 Rego 策略 + 单元测试
- `.semgrep/` 规则集：`ai-code.yml` / `sensitive-data.yml` / `jira-required.yml`
- `setup-opa` / `setup-ai-tools` composite action

#### B+ 类：外部安全服务（`security-scans.yml`）

- SonarQube 扫描（`SonarSource/sonarqube-scan-action@v4`）
- Snyk 依赖扫描（`snyk/actions@v0.4.0`）
- GitGuardian 密钥扫描（`GitGuardian/ggshield-action@v1`）
- 三个服务全部 optional secret，缺失时优雅跳过

#### E 类：上线后验证

- `ai-content-test.yml`：promptfoo LLM 内容安全测试（prompt 注入 / 越狱 / 幻觉 / 敏感输出）
- `load-test.yml`：k6 / Locust 压测（P99 延迟 / 错误率阈值）
- `db-benchmark.yml`：pgbench PG 入库速度基准（临时容器，不依赖业务 DB）
- `templates/promptfooconfig.yaml`：promptfoo 默认配置（含 6 个基础测试用例）
- `templates/k6-scenario.js`：k6 压测脚本骨架
- `templates/agent-config.schema.json`：Agent 配置 JSON Schema

#### F 类：流程卡点

- `.github/PULL_REQUEST_TEMPLATE.md`：PR 模板（关联工单 / 变更类型 / 上线前 checklist / 行政合规自查）
- `.github/ISSUE_TEMPLATE/release-checklist.md`：发布上线 checklist issue 模板
- `templates/commitlint.config.js`：commitlint 配置模板（Conventional Commits + Jira）
- `templates/.husky/commit-msg` + `templates/.husky/pre-commit`：husky 本地钩子
- `templates/_pre-commit-config.yaml`：pre-commit 框架配置

#### 文档

- `docs/release-gates.md`：D 类上线卡点详解
- `docs/ai-content-testing.md`：promptfoo 集成说明
- `docs/load-testing.md`：k6 / Locust 压测配置
- `docs/db-benchmark.md`：pgbench 配置与 TPS 阈值
- `docs/commitlint-husky.md`：本地钩子安装步骤
- `docs/external-security-tools.md`：SonarQube / Snyk / GitGuardian 接入
- `docs/pr-checklist.md`：PR 模板与发布 checklist 使用说明

### Changed

- `standard-ci.yml` 编排扩展：新增 `release-gates`（D，并行）+ `ai-content` / `load-test` / `db-benchmark`（E，needs D 通过）
- `standard-ci.yml` 新增 12 个 inputs（D/E 类开关与参数）+ 5 个 secrets（B+ 外部服务 + E 类 LLM key）
- `notify-start` / `notify-end` 聚合 D/E 类 job 结果，企业微信通知含 7 个阶段状态行
- `security-scans.yml` 新增 3 个 secrets 声明（`SONAR_TOKEN` / `SNYK_TOKEN` / `GITGUARDIAN_API_KEY`）
- `_test-internal.yml` 新增 `opa-test` / `conftest-verify` / `semgrep-validate` 三个自检 job
- `templates/bun-ci.yml` / `templates/python-ci.yml` 补充 D/E 类开关示例与新 secrets
- `README.md` 架构图扩展为 A/B/B+/C/D/E/F 七类，inputs/secrets 表新增行
- `docs/inputs-reference.md` 拆分为 A/B/C / D / E 三组，新增 12 inputs + 5 secrets
- `docs/getting-started.md` 新增"高级配置：D/E/F 类"章节
- `docs/migration-guide.md` 新增"v1.0 → v1.1 升级"章节

### Compatibility

- **完全向后兼容**：所有新增 inputs 默认关闭，所有新增 secrets 缺失时优雅跳过
- v1.0 用户零改动即可升级到 v1.1（`@v1` moving tag 自动指向）
- A/B/C 类行为完全不变

## [1.0.0] - 2026-07-17

### Added

- 中心化 CI 模板仓库，通过 GitHub Actions Reusable Workflows 对外提供服务
- `standard-ci.yml` 对外唯一入口，内部编排 `lint-checks` / `security-scans` / `dependency-audit` 三阶段
- A 类静态分析与格式化（4 项）：type-check / lint-full / extended-lint / format-full
- B 类安全扫描（6 项）：semgrep / gitleaks / trivy / knip / iac-checkov / opa-conftest
- C 类依赖审计（3 项）：dep-audit / py-dep-audit / lockfile-freshness
- v1 首版支持 `bun` 与 `python` 两种 project-type
- 企业微信群机器人通知：CI 开始前（`notify-start`）与完成后（`notify-end`）发送 markdown 消息
- 4 个 composite action：`setup-bun` / `setup-python` / `setup-security-tools` / `notify-wecom`
- 业务项目接入模板：`templates/bun-ci.yml` / `templates/python-ci.yml`
- 全部 secrets 可选，缺失时优雅跳过并 warning
- 仓库自身 CI `_test-internal.yml`：actionlint + yamllint 校验

[Unreleased]: https://github.com/Yun-Hai-Org/ci-templates/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/Yun-Hai-Org/ci-templates/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Yun-Hai-Org/ci-templates/releases/tag/v1.0.0
