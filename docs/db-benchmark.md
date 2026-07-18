# PostgreSQL 基准测试（pgbench）

E 类测试，启动临时 PG 容器跑 pgbench，验证 TPS / 延迟是否达标。**不依赖业务仓库的 DB 连接**。

## 工作原理

```
db-benchmark.yml
  │
  ├─ 启动 postgres:16-alpine 容器
  ├─ pgbench -i -s <scale>   # 初始化
  ├─ pgbench -c <clients> -T <duration>  # 跑测
  ├─ 解析 tps = N
  ├─ 与 report-threshold-tps 对比
  └─ 上传 pgbench-output.txt artifact
```

## 启用方式

```yaml
jobs:
  ci:
    uses: pr9898/ci-templates/.github/workflows/standard-ci.yml@v1
    with:
      run-release-gates: true
      run-db-benchmark: true
      db-pg-version: '16'
      db-scale-factor: 10
      db-duration: 60
      db-threshold-tps: 500
```

## 参数说明

| 参数               | 默认 | 含义                                           |
| ------------------ | ---- | ---------------------------------------------- |
| `db-pg-version`    | 16   | PostgreSQL 版本                                |
| `db-scale-factor`  | 10   | pgbench scale factor，约等于 clients × 100k 行 |
| `db-duration`      | 60   | 测试时长（秒）                                 |
| `db-threshold-tps` | 500  | TPS 阈值，低于则失败                           |

## 触发时机建议

DB 基准测试运行时间较长（含容器启动约 90s+），**不建议每次 PR 都跑**：

```yaml
on:
  workflow_dispatch:
  schedule:
    - cron: '0 3 * * 1' # 每周一凌晨 3 点
```

## 解读 pgbench 输出

```
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 10
query mode: simple
number of clients: 10
number of threads: 10
duration: 60 s
number of transactions actually processed: 28543
number of failed transactions: 0 (0.000%)
latency average = 21.028 ms
latency stddev = 12.341 ms
tps = 475.314434 (including connections establishing)
tps = 475.421876 (excluding connections establishing)
```

关键指标：

- `tps`：每秒事务数，越大越好
- `latency average`：平均延迟
- `latency stddev`：延迟标准差，越小越稳定
- `number of failed transactions`：应为 0

## 阈值建议

| 场景     | scale | clients | duration | TPS 阈值 |
| -------- | ----- | ------- | -------- | -------- |
| 快速冒烟 | 5     | 5       | 30       | 800      |
| 标准基准 | 10    | 10      | 60       | 500      |
| 压力测试 | 50    | 50      | 120      | 300      |

> 阈值是相对值，受 runner 规格（GitHub Actions ubuntu-latest 是 2 vCPU / 7GB）影响。
> 建议先跑几次基线，再设定阈值。

## 业务仓库自有 DB 的基准

本 workflow 用临时容器跑，**不测试业务仓库的真实 DB**。如需对生产/staging DB 跑基准：

1. 在业务仓库新建独立 workflow
2. 用 `pgbench` 直连业务 DB（需配置 DB 连接 secret）
3. 谨慎：会消耗 DB 资源，仅在非生产环境执行

```yaml
# .github/workflows/db-benchmark-prod.yml
name: DB Benchmark (Staging)
on: [workflow_dispatch]
jobs:
  bench:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Install pgbench
        run: sudo apt-get install -y postgresql-client
      - name: Run pgbench
        env:
          DATABASE_URL: ${{ secrets.STAGING_DB_URL }}
        run: |
          pgbench -i -h "$DB_HOST" -U "$DB_USER" "$DB_NAME"
          pgbench -c 10 -T 60 -h "$DB_HOST" -U "$DB_USER" "$DB_NAME"
```

## 结果查看

- CI 日志：输出 pgbench 完整结果
- Artifacts：`pgbench-report` 可下载 `pgbench-output.txt`
- 企业微信通知显示 DB 基准状态行
