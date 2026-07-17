# FAQ

## 通用

### 本地和 CI 结果不一致怎么办？

CI 用 `bun.lock` / `uv.lock` 锁定工具版本。本地执行 `bun install --frozen-lockfile` 或 `uv sync --frozen` 确保版本一致。pyright / ruff / eslint 等工具版本由 lockfile 决定，不固定会导致规则差异。

### 如何跳过某个检查？

在 `with:` 下设置对应开关为 false：

```yaml
with:
  run-security-scan: false # 跳过整个 B 类
  run-knip: false # 仅跳过 knip
  run-extended-lint: false # 不跑 hadolint 等（默认已关）
```

### secret 未配置时会怎样？

对应工具步骤自动跳过，输出 `::warning::secret XXX not set, skipping <tool>`，不导致 CI 失败。例如未配置 `SEMGREP_APP_TOKEN` 时 semgrep 跳过，其他检查照常跑。

### 缓存失效了怎么办？

CI 缓存 key 基于 lockfile 哈希。`bun.lock` 或 `uv.lock` 变更时缓存自动失效。如需强制刷新：

- 修改 lockfile（如重新 `bun install`），缓存 key 改变
- 或在 GitHub Actions 页面手动清除缓存（Settings → Actions → Caches → Delete cache）

### 紧急升级工具版本怎么做？

中心仓库修改 `.github/actions/setup-security-tools/action.yml` 中的版本号，打新 tag（如 `v1.0.1`），更新 `v1` moving tag。所有用 `@v1` 的业务项目下次 CI 自动生效。

业务项目无需任何改动。

### 如何回滚到旧版本？

将 `uses:` 的 tag 从 `@v1` 改为具体版本 `@v1.0.0`：

```yaml
uses: pr9898/ci-templates/.github/workflows/standard-ci.yml@v1.0.0
```

### 如何 debug？

设置 `debug: true`，会打印 inputs 等上下文信息：

```yaml
with:
  debug: true
```

或启用 GitHub Actions 的 step debug logging（仓库 Settings → Secrets → `ACTIONS_STEP_DEBUG=true`）。

## 通知

### 通知没收到？

查看 [企业微信通知配置](wecom-notification.md) 的故障排查章节。常见原因：

1. `WECOM_BOT_KEY` secret 未配置
2. `wecom-notify` 设为 false
3. webhook key 错误或机器人被禁用

### 能否只在失败时通知？

v1 暂不支持。v1.1 计划新增 `notify-on` input（`start` / `end` / `both` / `failure-only`）。当前可设置 `wecom-notify: true` 接收全部通知，或 `false` 完全关闭。

### 能否 @ 指定人？

v1 暂不支持。v1.1 计划新增 `wecom-at-mobiles-on-failure` input，失败时 @ 指定手机号。

### 通知会发到哪个群？

发到 `WECOM_BOT_KEY` 对应的群机器人所在的群。不同项目配置不同的 `WECOM_BOT_KEY` 可发到不同群；配置相同的 key 则发到同一群。

## 版本

### 用 `@v1` 还是 `@v1.0.0`？

- `@v1`：moving tag，自动获得 v1.x 的补丁和 minor 升级。**推荐大多数项目使用**。
- `@v1.0.0`：immutable tag，固定到具体版本。稳定性要求极高的项目使用。

### 不要用 `@main`

`@main` 跟踪默认分支，可能引入未发布的 breaking change。仅中心仓库自身 CI 使用 `@main`，业务项目禁用。

### 如何升级到 v2？

v2 发布时，中心仓库会提供迁移指南。`@v1` 保持冻结，业务项目可继续用 `@v1` 或按指南迁移到 `@v2`。

### 如何知道中心仓库有新版本？

- Watch 中心仓库的 Releases
- 或关注 `CHANGELOG.md`
- 中心仓库自身的 `_test-internal.yml` 保证每次变更都通过 actionlint 校验，`@v1` 升级是安全的

## 架构

### 为什么要用 reusable workflow 而不是 composite action？

Reusable workflow 可以定义 `on: workflow_call` 的 inputs / secrets 接口，且支持 job 编排（matrix / needs）。Composite action 只能定义 steps，不能定义 job。中心仓库需要编排 lint / security / dependency 三阶段 + 通知 job，必须用 reusable workflow。

### 为什么不直接把所有检查写在一个 workflow 里？

拆成 `lint-checks` / `security-scans` / `dependency-audit` 三个子工作流的好处：

- 每个子工作流可独立测试和维护
- 业务项目未来可直接调用某个子工作流（如仅需安全扫描）
- 中心仓库自身修改某类检查不影响其他类

### 为什么通知在 standard-ci.yml 而不是子工作流里？

通知是 CI 整体状态的通知，不是某个检查阶段的通知。放在编排层：

- 避免每个子工作流都发通知导致消息轰炸
- 可以汇总三阶段结果到一条结束通知
- 子工作流保持纯粹（只做检查）

### knip 为什么在 security-scans 而不是 lint-checks 里？

knip 是死代码检测，迁移文档将其归到 B 类（安全/质量扫描）。虽然语义上更接近 lint，但遵循迁移文档的分类。如需调整，修改 `security-scans.yml` 和 `lint-checks.yml` 的 knip step 即可。
