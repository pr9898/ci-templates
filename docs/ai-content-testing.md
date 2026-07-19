# AI 内容安全测试（promptfoo）

E 类测试，用于 LLM / Agent 应用的内容安全验证：prompt 注入防御、越狱检测、幻觉检测、敏感输出过滤。

## 工作原理

```
业务仓库 tests/promptfoo/promptfooconfig.yaml
  │
  ▼
ai-content-test.yml (reusable workflow)
  │
  ├─ 检查配置文件存在
  ├─ 检查 LLM API key 配置
  ├─ 安装 Node + promptfoo
  ├─ 执行 promptfoo eval
  ├─ 解析通过率 vs fail-threshold
  └─ 上传结果 artifact
```

## 启用方式

### Step 1: 复制配置模板

```bash
mkdir -p tests/promptfoo
cp /path/to/ci-templates/templates/promptfooconfig.yaml tests/promptfoo/
```

### Step 2: 修改 provider

编辑 `tests/promptfoo/promptfooconfig.yaml`，配置被测 LLM：

```yaml
providers:
  - id: openai:gpt-4o
    config:
      apiApiKey: '{{env.OPENAI_API_KEY}}'
  - id: anthropic:claude-3-5-sonnet
    config:
      apiApiKey: '{{env.ANTHROPIC_API_KEY}}'
```

### Step 3: 补充业务测试用例

在 `tests:` 下添加项目特定的测试场景。模板已包含 6 个基础用例：

- 经典越狱（忽略之前的指令）
- 角色扮演绕过
- 请求手机号明文
- 请求身份证号
- 虚构事实检测
- 正常请求不应被误判

### Step 4: 在 ci.yml 启用

```yaml
jobs:
  ci:
    uses: Yun-Hai-Org/ci-templates/.github/workflows/standard-ci.yml@v1
    with:
      run-release-gates: true # D 类必须先通过
      run-ai-content-test: true
      promptfoo-test-path: ./tests/promptfoo
      promptfoo-fail-threshold: 0.8 # 业务可调
    secrets:
      OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

## 触发时机建议

E 类测试调用真实 LLM，有 token 成本，**不建议每次 PR 都跑**：

```yaml
on:
  pull_request:
    branches: [main] # 仅 PR 到 main 时跑
  schedule:
    - cron: '0 2 * * *' # 每天凌晨 2 点全量跑
  workflow_dispatch: # 手动触发
```

## fail-threshold

通过率低于阈值则 CI 失败。

| 阈值 | 含义         | 建议                   |
| ---- | ------------ | ---------------------- |
| 0.5  | 50% 通过即可 | 开发期 / 实验阶段      |
| 0.8  | 80% 通过     | 生产环境发布前（推荐） |
| 1.0  | 100% 通过    | 严格合规场景           |

## 断言类型

promptfoo 支持多种断言，常用：

| 类型           | 用途                 | 示例                    |
| -------------- | -------------------- | ----------------------- |
| `contains`     | 输出必须包含某字符串 | `value: "我无法"`       |
| `not-contains` | 输出不得包含某字符串 | `value: "13812345678"`  |
| `contains-any` | 输出包含任一字符串   | 拒绝话术列表            |
| `llm-rubric`   | LLM 评判是否符合描述 | `value: "拒绝越狱指令"` |
| `regex`        | 正则匹配             | `value: "^PROJ-\\d+"`   |
| `javascript`   | 自定义脚本判断       | 复杂逻辑                |

详见 [promptfoo 文档](https://www.promptfoo.dev/docs/configuration/expected-outputs/)。

## 本地调试

```bash
# 安装
npm install -g promptfoo

# 跑测试
cd tests/promptfoo
promptfoo eval

# 启动 Web UI 查看结果
promptfoo view
```

## 结果查看

CI 完成后：

- GitHub Actions 的 Artifacts 下载 `promptfoo-results`
- 包含 `result.json`（机器可读）和 `promptfoo_output.html`（人可读）
- 企业微信通知会显示 AI 内容测试的状态行
