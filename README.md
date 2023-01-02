# Backend Architecture

![Architecture](/Backend.png?raw=true "Backend Architecture")

The backend of the application is created using the API Gateway and an AWS Lambda which fetches the server time and timezone when invoked. The terraform configs used to create the backend application are a part of this project. Open the image in a new tab to see a clearer image!


## CI/CD Setup 
![CI/CD Setup](/cicd_setup.png?raw=true "CI/CD Setup")

The proposed CI/CD setup for the backend application could consist of only `CodeBuild` which is an AWS Native DevOps tool for building and testing. CodeBuild is also `serverless` and we pay by the minute of build time. The builds happen inside a docker container. Below are the proposed stages of the process.

1. CodeBuild is triggered when a pull request is merged with the master branch of the ds_backend repository. 
2. In the build phase a zip file is created with the updated code from python file for AWS Lambda function. 
3. The zip file is then used to update the Lambda version and the alias "staging" should then point to the newly created version. 
4. We should then run unit-tests against the staging api gateway at staging-api.simplifycloud.uk, if the tests fail then we should terminate and fail the build.
5. If the tests from the previous stage are successful then we should update the "prod" alias to point to the latest version of the lambda. If desired we could also do a `canary` release by updating the weights of the version "prod" alias points to. If `canary` or `linear` increase is desired as deployment method to Lambda then we can make use of AWS CodeDeploy which the AWS Native DevOps tool for Continuous Deployment.

## Ideal CI/CD
Due to the reduction in complexity offered by AWS Lambda, the CI/CD footprint is much smaller. However, in the real world where application are usually more complex than the current one the below figure would summarize how a DevOps pipeline with Security in context should look like.

![Ideal CI/CD Setup](/DevOps_Internal_Stages.png?raw=true "Ideal CI/CD Setup")


**Open in Images in new tab for clarity**