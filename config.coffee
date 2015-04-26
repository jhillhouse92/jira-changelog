config = {}

config.host = process.env.JIRA_HOST || 'jira.megalithic.us'
config.port = process.env.JIRA_PORT || 8080
config.url = "http://#{config.host}:#{config.port}"
config.user = process.env.JIRA_USER
config.password = process.env.JIRA_PASSWORD
  
module.exports = config
