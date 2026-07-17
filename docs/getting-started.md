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
  https://raw.githubusercontent.com/pr9898/ci-templates/v1/templates/bun-ci.yml

# Python 项目
curl -o .github/workflows/ci.yml \
  https://raw.githubusercontent.com/pr9898/ci-templates/v1/templates/python-ci.yml
```

## Step 2: 调整参数

打开 `.github/workflows/ci.yml`，按需调整 `with:` 下的参数：

| 参数 | 默认 | 说明 |
| --- | --- | --- |
| `project-type` | `bun` | `bun` 或 `python` |
| `run-extended-lint` | `false` | 是否跑 hadolint/shellcheck 等 |
| `fail-on-severity` | `high` | 失败阈值 |
| `wecom-notify` | `true` | 是否发企业微信通知 |

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
