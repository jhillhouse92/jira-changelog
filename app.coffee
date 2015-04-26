config = require './config'
generateVersionPage = require './generateVersionPage'
_ = require 'lodash'
JiraApi = require('jira').JiraApi
Seq = require 'seq'

global.jira = new JiraApi 'http', config.host, config.port, config.user, config.password, '2', true 


Seq().seq( ->
  jira.getProject 'PR', @
  
).seq((project) ->
  #console.log '** project', project

  parentThis = @
  versionsDescending = _.sortByOrder project.versions, 'name', false 
    
  Seq(versionsDescending).seqMap((version) ->
    #console.log '** version', version
    generateVersionPage project, version, @
  ).unflatten(
  ).seq((pages) ->
    parentThis null, pages
    
  ).catch((err) ->
    parentThis err
  )

).seq((pages) ->
  doc = pages.join '<div style="page-break-after: always"></div>\r\n'
  console.log doc

).catch((err) ->
  console.log '** err', err
)
