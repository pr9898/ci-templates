# 企业微信通知配置

CI 检查开始前与完成后，自动向企业微信群发送 markdown 通知。

## 消息示例

### 开始通知

```
## 🚀 CI 开始
> **仓库**: pr9898/some-app
> **分支**: feature/add-login
> **触发者**: pr9898
> **事件**: pull_request
> **状态**: started
> **项目类型**: bun
> **静态分析**: true
> **安全扫描**: true
> **依赖审计**: true
> [查看 CI 详情](https://github.com/pr9898/some-app/actions/runs/12345678)
```

### 结束通知（成功）

```
## ✅ CI 完成
> **仓库**: pr9898/some-app
> **分支**: feature/add-login
> **触发者**: pr9898
> **事件**: pull_request
> **状态**: success
> **lint**: success
> **security**: success
> **dependency**: success
> [查看 CI 详情](https://github.com/pr9898/some-app/actions/runs/12345678)
```

### 结束通知（失败）

标题变为 `❌ CI 失败`，状态 `failure`，对应阶段的 result 显示 `failure`。被关闭的检查显示 `skipped`。

## 配置步骤

### 1. 创建企业微信群机器人

1. 打开企业微信群
2. 右上角 `...` → 群机器人 → 添加机器人
3. 命名（如 "CI 通知"），完成添加
4. 复制 webhook URL，形如：

```
https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=abc12345-6789-def0-1234-567890abcdef
```

### 2. 提取 WECOM_BOT_KEY

webhook URL 中 `key=` 后面的部分即为 `WECOM_BOT_KEY`。上面的例子中：

```
WECOM_BOT_KEY=abc12345-6789-def0-1234-567890abcdef
```

### 3. 配置 GitHub Secret

在业务仓库：

1. Settings → Secrets and variables → Actions
2. New repository secret
3. Name: `WECOM_BOT_KEY`
4. Secret: 上一步提取的 key 值
5. Add secret

### 4. 在 CI 样板中引用

`templates/bun-ci.yml` 和 `templates/python-ci.yml` 已默认引用 `WECOM_BOT_KEY`，无需额外修改：

```yaml
    secrets:
      WECOM_BOT_KEY: ${{ secrets.WECOM_BOT_KEY }}
```

## 关闭通知

### 完全关闭

在业务仓库的 `.github/workflows/ci.yml` 中设置：

```yaml
    with:
      wecom-notify: false
```

### 仅不配置 secret

删除 `secrets:` 下的 `WECOM_BOT_KEY` 行——未配置 secret 时通知自动跳过，输出 warning。

## 组织级 Secret（推荐）

如果有多个业务仓库都需要通知到同一个群，配置 Organization-level secret 一次即可，无需每个仓库重复配置：

1. GitHub Organization → Settings → Secrets and variables → Actions
2. New organization secret
3. Name: `WECOM_BOT_KEY`
4. Secret: webhook key
5. Repository access: 选择允许的仓库

业务仓库的 `ci.yml` 无需修改，`${{ secrets.WECOM_BOT_KEY }}` 会自动读取 org-level secret。

## 故障排查

### 没收到通知

1. 确认 `WECOM_BOT_KEY` secret 已配置（仓库 Settings → Secrets）
2. 确认 `wecom-notify: true`（默认 true）
3. 查看 CI 日志中 `notify-start` / `notify-end` job 的输出：
   - `WeCom notification sent: 🚀 CI 开始` → 发送成功
   - `::warning::secret WECOM_BOT_KEY not set` → secret 未配置
   - `::warning::WeCom webhook returned errcode=...` → key 错误或机器人被禁用

### 通知延迟

开始通知与三阶段检查并行发出，通常在 CI 启动后几秒内收到。结束通知在所有检查完成后发出。

### errcode 说明

| errcode | 含义 | 解决方法 |
| --- | --- | --- |
| 0 | 成功 | — |
| 93000 | webhook 不存在或被禁用 | 重新创建群机器人 |
| 40014 | key 错误 | 检查 WECOM_BOT_KEY 是否完整复制 |
| 45009 | 超频（20 条/分钟） | 合并 CI 触发，减少频率 |

### 通知内容乱码

确保群机器人支持 markdown 类型消息（默认支持）。如需 text 类型，修改 `.github/actions/notify-wecom/action.yml` 中的 payload。
