var config = require('./config');
var generateVersionPage = require('./generateVersionPage');
var _ = require('lodash');
var JiraApi = require('jira').JiraApi;
var Seq = require('seq');
var url = require('url');

var parsedUrl = url.parse(config.jiraUrl);
var user = parsedUrl.auth.split(':')[0];
var pass = parsedUrl.auth.split(':')[1];
global.jira = new JiraApi(parsedUrl.protocol, parsedUrl.hostname, parsedUrl.port, user, pass, '2', true); 
var projectKey = parsedUrl.pathname.substring(1);


Seq()
  .seq(function() {
    jira.getProject(projectKey, this);
  })
  .seq(function(project) {
    console.error('** project', project);

    var parentThis = this;
    var versionsAscending = _.sortByOrder(project.versions, 'name', true); 
    
    Seq(versionsAscending)
      .seqMap(function(version) {
        console.error('** version', version);
        generateVersionPage(project, version, this);
      })
      .unflatten()
      .seq(function(pages) {
        parentThis(null, pages);
      })
      .catch(function(err) {
        parentThis(err);
      })
    ;
  
  }).seq(function(pages) {
    var doc = pages.join('<div style="page-break-after: always"></div>\r\n');
    console.log(doc);
  
  }).catch(function(err) {
    console.error(err);
  })
;
