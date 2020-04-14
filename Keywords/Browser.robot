*** Settings ***
Documentation       Library imports, setup & teardown keywords
Library             Selenium2Library
Library             robot.libraries.String
Library             robot.libraries.Collections
Library             robot.libraries.Dialogs
Library             ../Lib/Helper.py
Variables           ../config.py

*** Variables ***
${REMOTE_URL}       None

*** Keywords ***
Start Browser
    [Arguments]  ${url}=about:blank
    Run Keyword If  '${BROWSER}' == 'gc' and '${REMOTE_URL}' != 'None'  Execute Remotely  ${url}
    ...  ELSE IF  '${BROWSER}' == 'gc' and '${REMOTE_URL}' == 'None'  Execute Locally  ${url}
    ...  ELSE  Open Browser  ${url}  ${BROWSER}
    Set Window Position  0  0
    Set Window Size  1280  800
    Maximize Browser Window

Quit Browser
    Run Keyword And Ignore Error  Run Keyword If Test Failed  Capture Page Screenshot
    Close Browser

Execute Locally
    [Arguments]  ${url}
    ${chrome_option}  Set Chrome Options
    Create WebDriver  Chrome  chrome_options=${chrome_option}
    Go To  ${url}

Execute Remotely
    [Arguments]  ${url}
    ${chrome_option}  Set Chrome Options
    ${chrome_option}  Call Method  ${chrome_option}  to_capabilities
    Create WebDriver  Remote  command_executor=${REMOTE_URL}  desired_capabilities=${chrome_option}
    Go To  ${url}