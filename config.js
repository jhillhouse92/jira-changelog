var Config = module.exports = {};
var url = require('url');

// JIRA_URL
Config.jiraUrl = process.env.JIRA_URL;
Config.parsedUrl = url.parse(process.env.JIRA_URL);
