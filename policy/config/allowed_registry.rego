package config

# 镜像仓库白名单：容器镜像必须来自受信 registry。
# 对应"供应链安全"要求，防止拉取来源不明的镜像。

allowed_registries := {
	"docker.io/library/",
	"gcr.io/",
	"registry.cn-hangzhou.aliyuncs.com/",
}

deny[msg] {
	container := input.spec.containers[_]
	not registry_allowed(container.image)
	msg := sprintf("容器 %v 使用了非白名单镜像: %v", [container.name, container.image])
}

deny[msg] {
	container := input.spec.template.spec.containers[_]
	not registry_allowed(container.image)
	msg := sprintf("Pod 模板容器 %v 使用了非白名单镜像: %v", [container.name, container.image])
}

registry_allowed(image) {
	prefix := allowed_registries[_]
	startswith(image, prefix)
}
