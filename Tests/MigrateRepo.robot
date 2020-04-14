*** Settings ***
Resource  ../Keywords/PageKeywords/Login.robot
Resource  ../Keywords/PageKeywords/Diffusion.robot

*** Test Cases ***
Test Login
    [Tags]  LOGIN
    [Setup]  Start Browser
    Login To Phabricator

Migrate Repos
    [Tags]  MIGRATE
    [Setup]  Start Browser
    Login To Phabricator
    Create Git Repo And Set Observe Mode From Csv  ${SOURCE_CSV}
