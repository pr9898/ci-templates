package authz

test_deployment_without_label_fails {
	count(deny) == 1 with input as {
		"kind": "Deployment",
		"metadata": {"name": "app"},
	}
}

test_deployment_with_empty_label_fails {
	count(deny) == 1 with input as {
		"kind": "Deployment",
		"metadata": {"name": "app", "labels": {"approved-by": ""}},
	}
}

test_deployment_with_label_passes {
	count(deny) == 0 with input as {
		"kind": "Deployment",
		"metadata": {"name": "app", "labels": {"approved-by": "team-lead"}},
	}
}

test_non_deployment_skipped {
	count(deny) == 0 with input as {
		"kind": "Service",
		"metadata": {"name": "app"},
	}
}
