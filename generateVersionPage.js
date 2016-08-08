var _ = require('lodash');
var config = require('./config');
var fs = require('fs');
var handlebars = require('handlebars');
var handlebarsHelperMoment = require('handlebars-helper-moment')();
var moment = require('moment');
var Seq = require('seq');

handlebars.registerHelper('moment', handlebarsHelperMoment.moment);
handlebars.registerHelper('duration', handlebarsHelperMoment.duration);


module.exports = function (project, version, cb) { 

  var d = '';
  
  Seq()
    .seq('templateSource', function() { // Load template
      fs.readFile('./templates/projectVersion.hbs', this);
    })
    .seq(function() { // Generate header
      var startDate = moment(version.startDate);
      var releaseDate = moment(version.releaseDate);
      this.vars.duration = releaseDate.diff(startDate);
      this();
    })
    .seq(function() { // Fetch issues
      var searchString = 'project = ' + project.key + ' AND fixVersion = ' + version.name + ' AND status = Done'; // ORDER BY priority DESC
      var opts = {
        fields: ['attachment', 'issuetype', 'status', 'summary']
      };
      jira.searchJira(searchString, opts, this); 
    })
    .seq('issues', function(searchResults) { // Sort issues
      var issuesSorted = _.sortBy(searchResults.issues, function(issue) {
        var x;
        if (issue.fields.issuetype.name === 'Story') x = 0;
        else if (issue.fields.issuetype.name === 'New Feature') x = 1;
        else if (issue.fields.issuetype.name === 'Improvement') x = 2;
        else if (issue.fields.issuetype.name === 'Bug') x = 3;
        else if (issue.fields.issuetype.name === 'Task') x = 4;
        else x = 5;
        return x + '_' + issue.key;
      });
      this(null, issuesSorted);
    })
    .seq('issuesByType', function(issues) { // Group issues by type
      var issueTypes = _.uniq(_.pluck(issues, 'fields.issuetype.name'));
      var issuesByType = [];
      _.forEach(issueTypes, function(issueType) {
        issuesForType = _.filter(issues, function(issue) {
          return issue.fields.issuetype.name === issueType;
        });
        issuesByType.push({issuetype:issueType, issues:issuesForType});
      });
      //console.error('** issuesByType', issuesByType);
      this(null, issuesByType);
    })
    .seq('attachments', function() { // Fetch attachments
      var attachments = [];
      _.forEach(this.vars.issues, function(issue) {
        _.forEach(issue.fields.attachment, function(attachment) {
          if (attachment.thumbnail) {
            attachments.push(attachment);
          }
        });
      }); 
      //console.error('** attachments', attachments);
      this(null, attachments);
    })
    .seq(function() { // Merge template and return
      var template = handlebars.compile(this.vars.templateSource.toString());
      var context = {
        startDate: this.vars.startDate,
        releaseDate: this.vars.releaseDate,
        duration: this.vars.duration,
        config: config,
        project: project,
        version: version,
        issues: this.vars.issues,
        issuesByType: this.vars.issuesByType,
        attachments: this.vars.attachments
      };
      var markdown = template(context);
      cb(null, markdown);
    })
    .catch(function(err) {
      cb(err);
    })
  ;
}
