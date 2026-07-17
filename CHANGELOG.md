# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/pr9898/ci-templates/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/pr9898/ci-templates/releases/tag/v1.0.0
