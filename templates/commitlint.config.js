// commitlint 配置模板
// 复制到业务仓库根目录 commitlint.config.js
// 配合 templates/.husky/commit-msg 与 CI 中的 commitlint 检查使用。
//
// 安装依赖：
//   npm install --save-dev @commitlint/cli @commitlint/config-conventional \
//     commitlint-plugin-jira-rules commitlint-config-jira
//
// 自定义 JIRA_PREFIX 后即可强制 commit message 包含工单 ID。

const JIRA_PREFIX = 'PROJ' // ← 改成你的 Jira 项目前缀

module.exports = {
  extends: ['@commitlint/config-conventional'],
  plugins: ['commitlint-plugin-jira-rules'],
  rules: {
    // Conventional Commits 格式：<type>(<scope>): <subject>
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'build',
        'ci',
        'chore',
        'revert',
      ],
    ],
    'subject-case': [0], // 允许中文，不强制 case

    // Jira 工单 ID 规则
    // commit message body 或 footer 中必须包含 [PROJ-1234] 工单 ID
    'jira-taskId-in-body': [2, 'always', [JIRA_PREFIX]],
    'jira-taskId-in-subject': [0], // subject 不强制（PR 标题已校验）
  },
}
