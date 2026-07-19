# PR 模板与发布 Checklist

F 类流程卡点，覆盖无法通过 CI 自动扫描的行政、合规、文档类事项。

## PR 模板

位置：`.github/PULL_REQUEST_TEMPLATE.md`

提 PR 时自动填充。包含：

### 1. 关联工单

```markdown
Jira ID: PROJ-1234
```

CI 会校验：

- PR 标题包含工单 ID
- 所有 commit message 包含工单 ID

未通过时 `release-gates.yml` 的 Jira 校验步骤失败（或 warning，取决于 `jira-warning-only`）。

### 2. 变更类型

勾选本次 PR 的类型，便于 changelog 自动生成与发布分类。

### 3. 上线前自查清单

D 类卡点对应的人工确认：

- lint / security / dependency CI 全绿
- OPA 策略单元测试通过
- AI 安全扫描通过
- 敏感数据扫描通过
- Schema 校验通过
- 测试集已纳入 Git
- commit message 包含 Jira 工单 ID
- 已更新文档

### 4. 测试说明

本地如何验证本次变更。强制填写，避免"我没测过但应该没问题"。

### 5. 上线注意事项

是否需要 DB migration？是否需要灰度？回滚方案？

### 6. 行政与合规自查

仅在 release / 上线 PR 勾选：

- 域名备案已完成（备案号：**\_\_**）
- 手机号登录合规与隐私政策（PIA）已通过法务审核
- OA 上线审批已发起并获批（OA 流程单号：**\_\_**）
- 设计文档已同步至 Wiki（链接：**\_\_**）
- ICP 证申请已完成（如适用）

这些项**无法通过 CI 自动扫描**，必须人工确认。PR 模板通过 checkbox 形式提醒，由 reviewer 在 Approve 前核对。

## 发布上线 Checklist

位置：`.github/ISSUE_TEMPLATE/release-checklist.md`

发版前创建 issue，逐项确认。覆盖：

### 技术检查

- CI 全绿（含 D/E 类）
- 压测 / DB 基准 / AI 内容测试通过
- CHANGELOG 已更新
- DB migration 已在 staging 验证
- 灰度计划已制定

### 流程检查

- Jira 工单状态已流转到"待上线"
- Code Review 已通过
- 设计文档已同步至 Wiki
- 测试用例已补充

### 合规检查（行政类）

- 域名备案
- PIA 隐私政策
- OA 上线审批
- ICP 证
- 安全合规审核

### 上线操作

- 回滚方案已准备
- 监控告警已配置
- on-call 人员已确认
- 发布窗口已对齐

### 上线后

- 监控指标正常（5 分钟观察期）
- 企业微信通知发布成功
- Jira 工单状态流转到"已发布"
- 发布总结文档已归档

## 使用方式

### 创建发布 issue

1. GitHub Issues → New issue
2. 选择 "发布上线 Checklist" 模板
3. 填写版本号、发布日期、负责人
4. 逐项勾选，全部完成后 close issue

### 与 Jira 联动

建议 Jira workflow 配置：

- "待上线" → "已发布" 的流转条件：必须关联一个标签为 `release` 的 GitHub Issue 且状态为 closed
- 通过 [Jira Automation](https://www.atlassian.com/software/jira/features/automation) 或 [GitHub for Jira](https://www.atlassian.com/software/jira/guides/getting-started-with-jira/integrations) 实现

具体配置见 [Jira workflow 文档](https://support.atlassian.com/jira-software-cloud/docs/configure-workflow/)。

## 自定义

业务仓库可修改 PR 模板和 release checklist：

```bash
# 直接编辑
vim .github/PULL_REQUEST_TEMPLATE.md
vim .github/ISSUE_TEMPLATE/release-checklist.md
```

模板仓库升级时不会覆盖业务仓库已自定义的模板（GitHub 的模板是仓库级文件，不走 reusable workflow）。

## 强制性

PR 模板和 release checklist 是**软约束**：

- PR 模板：reviewer 决定是否严格要求所有 checkbox 勾选
- release checklist：发布流程 owner 决定是否必须 issue closed 才能上线

如需硬卡点，配合：

- GitHub Branch Protection Rules：要求 PR 通过 CI（含 `release-gates`）才能合并
- Jira workflow：要求关联 release issue closed 才能流转状态
