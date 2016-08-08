# JIRA ChangeLog Generator

Generate a CHANGELOG.md for a project. Uses the JIRA REST API.

## Building

```
$ npm install
```

## Using

```
$ EXPORT JIRA_URL=https://admin:<password>@<my-space>.atlassian.net/<MY-PROJ>
$ node app.js > CHANGELOG.md
```
