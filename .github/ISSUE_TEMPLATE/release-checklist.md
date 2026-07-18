---
name: 发布上线 Checklist
about: 正式发布前逐项确认，覆盖技术、流程、合规三个维度
title: "[RELEASE] <版本号> 上线 checklist"
labels: release
---

# 发布上线 Checklist

## 版本信息

- 版本号：
- 发布日期：
- 发布负责人：
- 回滚负责人：

## 技术检查

### CI / CD

- [ ] CI 全绿（lint / security / dependency / release-gates）
- [ ] E 类压测通过（`run-load-test: true`，P99 / 错误率达标）
- [ ] DB 基准达标（`run-db-benchmark: true`，TPS ≥ 阈值）
- [ ] AI 内容安全测试通过（`run-ai-content-test: true`，通过率 ≥ 阈值）
- [ ] 企业微信通知已确认收到

### 代码与配置

- [ ] CHANGELOG 已更新
- [ ] 版本号已 bump（语义化版本）
- [ ] 数据库 migration 已在 staging 验证
- [ ] 配置项已同步到生产环境
- [ ] 灰度计划已制定（如适用）

## 流程检查

- [ ] Jira 工单状态已流转到"待上线"
- [ ] Code Review 已通过（≥ 1 reviewer approve）
- [ ] 设计文档已同步至 Wiki
- [ ] 测试用例已补充并纳入 Git

## 合规检查（行政类，须人工确认）

- [ ] 域名备案已完成（备案号：______）
- [ ] 手机号登录合规与隐私政策（PIA）已通过法务审核
- [ ] OA 上线审批已发起并获批（OA 流程单号：______）
- [ ] ICP 证申请已完成（如适用）
- [ ] 安全合规审核已通过（含白盒 / 灰盒扫描报告）

## 上线操作

- [ ] 回滚方案已准备
- [ ] 监控告警已配置
- [ ] on-call 人员已确认
- [ ] 发布窗口已与相关方对齐

## 上线后

- [ ] 监控指标正常（5 分钟观察期）
- [ ] 企业微信通知发布成功
- [ ] Jira 工单状态流转到"已发布"
- [ ] 发布总结文档已归档
