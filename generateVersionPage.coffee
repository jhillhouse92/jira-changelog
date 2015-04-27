_ = require 'lodash'
config = require './config'
moment = require 'moment'
Seq = require 'seq'


module.exports = (project, version, cb) -> 

  d = ''
  
  Seq().seq( -> # Generate header
    startDate = moment version.startDate
    releaseDate = moment version.releaseDate
    duration = moment.duration releaseDate.diff startDate
  
    d += "# Release #{version.name}\r\n"
    
    d += '('
    d += startDate.format 'D-MMM'
    d += startDate.format '-YYYY' if startDate.year() isnt releaseDate.year()
    d += ' to '
    if version.released
      d += releaseDate.format 'D-MMM-YYYY'
      d += ', ' + duration.humanize()
    else
      d += 'ongoing'
    d += ')\r\n\r\n'
    
    if version.description
      d += "#{version.description}\r\n"
    
    @ null
    
  ).seq( -> # Generate issues list
    searchString = "project = #{project.key} AND fixVersion = #{version.name} AND status = Resolved" # ORDER BY priority DESC
    opts =
      fields: ['attachment', 'issuetype', 'status', 'summary']
    jira.searchJira searchString, opts, @ 
    
  ).seq((searchResults) ->
    @vars.issues = searchResults.issues
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
      #console.error '** issue', issue
      if issue.fields.issuetype.name isnt lastType
        d += "\r\n## #{issue.fields.issuetype.name}\r\n"
        lastType = issue.fields.issuetype.name
      d += "  * [#{issue.key}](#{config.url}/browse/#{issue.key}) - #{issue.fields.summary}\r\n"
    @ null
  
  ).seq( -> # Generate images
    attachments = []
    for issue in @vars.issues
      for attachment in issue.fields.attachment
        attachments.push attachment 
    #console.error '** attachments', attachments
    unless _.isEmpty attachments
      d += '\r\n'
      d += '<table cellpadding="2" cellspacing="2">\r\n'
      d += '  <tr>\r\n'
      for attachment in attachments when attachment.thumbnail
        d += '    <td>\r\n'
        d += '      <img src="' + attachment.thumbnail + '" height="200" border="1"/>\r\n'
        d += '    </td>\r\n'
      d += '  </tr>\r\n'
      d += '</table>\r\n\r\n'
    @ null
  
  ).seq( -> # Done
    cb null, d
  
  ).catch((err) ->
    cb err
  )


