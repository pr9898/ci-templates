// k6 压测脚本骨架
// 复制到业务仓库 tests/load/scenario.js，按需修改 URL 与场景。
// 文档：https://k6.io/docs/

import http from 'k6/http'
import { check, sleep } from 'k6'
import { Rate, Trend } from 'k6/metrics'

const TARGET_URL = __ENV.TARGET_URL || 'http://localhost:3000'
const FAIL_ERROR_RATE = parseFloat(__ENV.FAIL_ERROR_RATE || '0.01')
const FAIL_P99_MS = parseInt(__ENV.FAIL_P99_MS || '2000')

// 自定义指标
const errorRate = new Rate('errors')
const responseTime = new Trend('response_time_ms')

export const options = {
  thresholds: {
    errors: [`rate<${FAIL_ERROR_RATE}`],
    http_req_duration: [`p(99)<${FAIL_P99_MS}`],
  },
}

export default function () {
  const res = http.get(`${TARGET_URL}/health`, {
    headers: { 'Content-Type': 'application/json' },
  })

  const ok = check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  })

  errorRate.add(!ok)
  responseTime.add(res.timings.duration)

  sleep(0.1)
}

export function handleSummary(data) {
  const pass =
    data.metrics.errors.rate < FAIL_ERROR_RATE &&
    data.metrics.http_req_duration['p(99)'] < FAIL_P99_MS
  console.log(
    `P99: ${data.metrics.http_req_duration['p(99)'].toFixed(0)}ms, ` +
      `Error rate: ${(data.metrics.errors.rate * 100).toFixed(2)}%, ` +
      `Pass: ${pass}`,
  )
  return {}
}
