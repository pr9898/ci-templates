package sensitive

test_no_phone_passes if {
	count(deny) == 0 with input as {
		"name": "app",
		"version": "1.0.0",
		"contact": "support@example.com",
	}
}

test_phone_detected if {
	count(deny) == 1 with input as {
		"contact": "13812345678",
	}
}

test_phone_in_nested_object_detected if {
	count(deny) == 1 with input as {
		"user": {
			"phone": "15900001111",
		},
	}
}

test_short_number_not_flagged if {
	count(deny) == 0 with input as {
		"port": 8080,
		"zip": "100000",
	}
}
