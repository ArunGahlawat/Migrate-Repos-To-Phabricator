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

Migrate repos to phabricator
    [Tags]  REPO_HOST
    [Setup]  Start Browser
    Login To Phabricator
    Enable Phab Repo Hosting From Csv  ${MIGRATE_SOURCE_CSV}

Set permaent refs for repos
    [Tags]  repo_refs
    [Setup]  Start Browser
    Login To Phabricator
    Update Permanent Refs From Csv  ${PERMANENT_REFS_CSV}