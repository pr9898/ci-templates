# OPA Policy 示例目录

本目录提供 OPA / Conftest 策略示例，供业务仓库参考或直接复用。

## 目录结构

```
policy/
├── authz/              # 部署授权策略
│   ├── deployment.rego
│   └── deployment_test.rego
├── config/             # 配置合规策略
│   ├── allowed_registry.rego
│   └── allowed_registry_test.rego
└── sensitive/          # 敏感数据防护策略
    ├── no_plaintext_phone.rego
    └── no_plaintext_phone_test.rego
```

## 两类用途

| 工具            | 命令                        | 验证对象                      | 职责                     |
| --------------- | --------------------------- | ----------------------------- | ------------------------ |
| `opa test`      | `opa test ./policy/... -v`  | Rego 策略本身（白盒单元测试） | 确保策略逻辑正确         |
| `conftest test` | `conftest test . --combine` | IaC / 配置文件（黑盒集成）    | 用 Rego 策略校验实际文件 |

- `*_test.rego` 文件被 `opa test` 自动发现并执行
- `conftest test` 默认读取 `policy/` 下的所有 `.rego`（不含 `_test`）作为策略集

## 在 CI 中启用

本仓库的 `release-gates.yml` 会在 `policy/**` 存在时自动运行 `opa test`；
`security-scans.yml` 中的 conftest 步骤同样在 `policy/**` 存在时触发。

业务仓库可直接复制本目录，或按需修改策略。

## Stargate ACL 场景

`sensitive/no_plaintext_phone.rego` 对应"后台手机号加密"合规要求：
配置文件（YAML/JSON）中不得出现 11 位中国大陆手机号明文。
检测到时 `conftest test` 返回失败，阻断 CI。
