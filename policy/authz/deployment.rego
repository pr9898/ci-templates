package authz

# 部署授权策略：K8s Deployment 必须携带 approved-by 标签，且值非空。
# 用于卡点"未经审批的部署"。

deny[msg] {
    input.kind == "Deployment"
    not input.metadata.labels.approved-by
    name := object.get(input.metadata, "name", "<unknown>")
    msg := sprintf("Deployment %v 缺少 metadata.labels.approved-by 标签", [name])
}

deny[msg] {
    input.kind == "Deployment"
    input.metadata.labels.approved-by == ""
    name := object.get(input.metadata, "name", "<unknown>")
    msg := sprintf("Deployment %v 的 approved-by 标签为空字符串", [name])
}
