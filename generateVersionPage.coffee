_ = require 'lodash'
config = require './config'
moment = require 'moment'
Seq = require 'seq'


module.exports = (project, version, cb) -> 

  startDate = moment version.startDate
  releaseDate = moment version.releaseDate
  duration = moment.duration releaseDate.diff startDate

  d = "# Release #{version.name}\r\n"
  
  d += '('
  d += startDate.format 'D-MMM'
  d += startDate.format '-YYYY' if startDate.year() isnt releaseDate.year()
  d += ' to '
  if version.released
    d += releaseDate.format 'D-MMM-YYYY'
    d += ', ' + duration.humanize()
  else
    d += 'ongoing'
  d += ')'
  d += '\r\n\r\n'
  
  Seq().seq( ->
    searchString = "project = #{project.key} AND fixVersion = #{version.name} AND status = Resolved" # ORDER BY priority DESC
    opts =
      fields: ['status', 'summary', 'issuetype']
    jira.searchJira searchString, opts, @ 
    
  ).seq((searchResults) ->
    issuesSortedByType = _.sortBy searchResults.issues, (issue) ->
      x = switch issue.fields.issuetype.name
        when 'Story' then 0
        when 'New Feature' then 1
        when 'Improvement' then 2
        when 'Bug' then 3
        when 'Task' then 4
        else 5
      x + '_' + issue.key
    lastType = null
    for issue in issuesSortedByType
      if issue.fields.issuetype.name isnt lastType
        d += "\r\n## #{issue.fields.issuetype.name}\r\n"
        lastType = issue.fields.issuetype.name
      d += "  * [#{issue.key}](#{config.url}/browse/#{issue.key}) - #{issue.fields.summary}\r\n"
    cb null, d
    
  ).catch((err) ->
    cb err
  )


