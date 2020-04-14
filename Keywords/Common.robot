*** Settings ***
Documentation       Library imports, setup & teardown keywords
Resource            Browser.robot
Variables           ../credentials.py

*** Variables ***

*** Keywords ***
Go To Location
    [Arguments]  ${location_path}
    ${uri}  Set Variable  ${HOME_URL}${location_path}
    Go To  ${uri}