package config

test_allowed_registry_passes {
	count(deny) == 0 with input as {
		"spec": {
			"containers": [
				{"name": "app", "image": "gcr.io/my-project/app:1.0"},
			],
		},
	}
}

test_disallowed_registry_fails {
	count(deny) == 1 with input as {
		"spec": {
			"containers": [
				{"name": "app", "image": "evil.com/malware:latest"},
			],
		},
	}
}

test_pod_template_checked {
	count(deny) == 1 with input as {
		"spec": {
			"template": {
				"spec": {
					"containers": [
						{"name": "app", "image": "evil.com/malware:latest"},
					],
				},
			},
		},
	}
}
