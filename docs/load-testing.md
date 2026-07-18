# 压测（k6 / Locust）

E 类测试，用于预发环境部署后的回归压测，验证 P99 延迟、错误率、吞吐量。

## 框架选择

| 框架   | 适用场景               | 脚本语言   | 优势                    |
| ------ | ---------------------- | ---------- | ----------------------- |
| k6     | HTTP API 压测          | JavaScript | 性能好，thresholds 内置 |
| Locust | 复杂场景 / Python 生态 | Python     | 灵活，可写复杂逻辑      |

默认 k6。需要 Locust 时 `load-test-framework: locust`。

## 启用方式

### Step 1: 复制脚本模板

```bash
mkdir -p tests/load
cp /path/to/ci-templates/templates/k6-scenario.js tests/load/scenario.js
```

### Step 2: 修改场景

编辑 `tests/load/scenario.js`，修改 `TARGET_URL` 与测试逻辑。

### Step 3: 在 ci.yml 启用

```yaml
jobs:
  ci:
    uses: pr9898/ci-templates/.github/workflows/standard-ci.yml@v1
    with:
      run-release-gates: true
      run-load-test: true
      load-test-framework: k6
      load-test-script: ./tests/load/scenario.js
      load-test-duration: 30s
      load-test-vus: 50
      load-test-target-url: https://staging.example.com
```

## 触发时机建议

压测有副作用（消耗服务器资源、可能触发限流），**不建议每次 PR 都跑**：

```yaml
on:
  workflow_dispatch: # 手动触发
  schedule:
    - cron: '0 4 * * 1' # 每周一凌晨 4 点回归压测
  deployment_status: # 部署到 staging 后触发
    states: [success]
```

## 阈值

| 参数                 | 默认 | 含义                 |
| -------------------- | ---- | -------------------- |
| `fail-on-error-rate` | 0.01 | 错误率超 1% 则失败   |
| `fail-on-p99-ms`     | 2000 | P99 延迟超 2s 则失败 |

业务可按 SLA 调整。

## k6 脚本编写

```javascript
import http from 'k6/http'
import { check, sleep } from 'k6'
import { Rate } from 'k6/metrics'

const errorRate = new Rate('errors')

export const options = {
  thresholds: {
    errors: ['rate<0.01'], // 错误率 < 1%
    http_req_duration: ['p(99)<2000'], // P99 < 2s
  },
}

export default function () {
  const res = http.get('https://staging.example.com/api/health')
  const ok = check(res, {
    'status 200': (r) => r.status === 200,
  })
  errorRate.add(!ok)
  sleep(0.1)
}
```

详见 [k6 文档](https://k6.io/docs/)。

## Locust 脚本编写

```python
from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def health(self):
        self.client.get("/api/health")
```

详见 [Locust 文档](https://docs.locust.io/)。

## 本地调试

### k6

```bash
# 安装
brew install k6

# 跑测试
k6 run tests/load/scenario.js \
  --vus 10 --duration 30s \
  -e TARGET_URL=http://localhost:3000
```

### Locust

```bash
pip install locust
locust -f tests/load/locustfile.py --headless \
  --host http://localhost:3000 \
  --users 10 --run-time 30s
```

## 结果查看

- k6：CI 日志中直接输出 thresholds 通过情况
- Locust：CI 日志输出 CSV 摘要
- Artifacts：`load-test-results` 可下载
- 企业微信通知会显示压测状态行
