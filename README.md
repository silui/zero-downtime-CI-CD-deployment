# No more 404
A Ci/CD pipeline with zero-downtime deployment

By commiting to development branch, jenkins will automatically spawn a django test container, then run smoke test in postman format using newman. After smokecheck succeded, Production branch will be updated which ten trigers codedeploy. Codedeploy will then perform rolling update to the server.


