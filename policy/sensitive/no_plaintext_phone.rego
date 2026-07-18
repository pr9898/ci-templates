package sensitive

# 敏感数据防护：配置文件中不得出现中国大陆手机号明文（1[3-9] + 9 位数字）。
# 对应"后台手机号加密"合规要求。Stargate ACL 场景：手机号须加密存储 / 脱敏传输。

phone_pattern := "^1[3-9][0-9]{9}$"

deny[msg] {
	item := walk(input)[_]
	val := item[1]
	path := item[0]
	is_string(val)
	regex.match(phone_pattern, val)
	msg := sprintf("发现手机号明文: %v (路径: %v)", [val, path])
}
