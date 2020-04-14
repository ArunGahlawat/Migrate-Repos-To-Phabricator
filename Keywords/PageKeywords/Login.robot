*** Settings ***
Resource            ../Common.robot

*** Variables ***
${field_username}     name=username
${field_password}     name=password
${button_submit}       name=__submit__


*** Keywords ***
Login To Phabricator
    [Arguments]  ${username}=${CRED_USERNAME}  ${password}=${CRED_PASSWORD}
    Go To  ${HOME_URL}
    Wait Until Page Contains  Login
    Wait Until Element Is Visible  ${field_username}
    wait until element is visible  ${field_password}
    Input Text  ${field_username}  ${username}
    Input Password  ${field_password}  ${password}
    Click Button  ${button_submit}
    Wait Until Element Is Not Visible  ${button_submit}
    Wait Until Page Contains  Recent Activity


