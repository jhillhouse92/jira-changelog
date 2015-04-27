_ = require 'lodash'
config = require './config'
fs = require 'fs'
handlebars = require 'handlebars'
handlebarsHelperMoment = require('handlebars-helper-moment')()
moment = require 'moment'
Seq = require 'seq'

handlebars.registerHelper 'moment', handlebarsHelperMoment.moment
handlebars.registerHelper 'duration', handlebarsHelperMoment.duration


module.exports = (project, version, cb) -> 

  d = ''
  
  Seq().seq('templateSource', -> # Load template
    fs.readFile './templates/projectVersion.hbs', @
  
  ).seq( -> # Generate header
    startDate = moment version.startDate
    releaseDate = moment version.releaseDate
    @vars.duration = releaseDate.diff startDate
    @ null
    
  ).seq( -> # Fetch issues
    searchString = "project = #{project.key} AND fixVersion = #{version.name} AND status = Resolved" # ORDER BY priority DESC
    opts =
      fields: ['attachment', 'issuetype', 'status', 'summary']
    jira.searchJira searchString, opts, @ 
    
  ).seq('issues', (searchResults) -> # Sort issues
    issuesSorted = _.sortBy searchResults.issues, (issue) ->
      x = switch issue.fields.issuetype.name
        when 'Story' then 0
        when 'New Feature' then 1
        when 'Improvement' then 2
        when 'Bug' then 3
        when 'Task' then 4
        else 5
      x + '_' + issue.key
    @ null, issuesSorted

  ).seq('issuesByType', (issues) -> # Group issues by type
    issueTypes = _.uniq _.pluck issues, 'fields.issuetype.name'
    issuesByType = []
    for issueType in issueTypes
      issuesForType = _.filter issues, (issue) -> issue.fields.issuetype.name is issueType
      issuesByType.push {issuetype:issueType, issues:issuesForType}
    #console.error '** issuesByType', issuesByType
    @ null, issuesByType
  
  ).seq('attachments', -> # Fetch attachments
    attachments = []
    for issue in @vars.issues
      for attachment in issue.fields.attachment when attachment.thumbnail
        attachments.push attachment 
    #console.error '** attachments', attachments
    @ null, attachments
  
  ).seq( -> # Merge template and return
    template = handlebars.compile @vars.templateSource.toString()
    context =
      startDate: @vars.startDate
      releaseDate: @vars.releaseDate
      duration: @vars.duration
      config: config
      project: project
      version: version
      issues: @vars.issues
      issuesByType: @vars.issuesByType
      attachments: @vars.attachments
    markdown = template context
    cb null, markdown
  
  ).catch((err) ->
    cb err
  )


