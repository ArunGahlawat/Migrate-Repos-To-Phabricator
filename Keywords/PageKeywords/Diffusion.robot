*** Settings ***
Resource            ../Common.robot

*** Variables ***
${field_repo_name}                  name=name
${field_callsign}                   name=callsign
${field_shortname}                  name=shortName
${button_submit}                    name=__submit__
${link_uri}                         xpath=//span[text()='URIs']/parent::a
${link_ssh_uris}                    //table[@class='aphront-table-view']/tbody/tr/td[@class='pri wide']/a[contains(text(),'ssh://git@phabricator.rivigo.com')]
${select_list_io}                   name=io
${back_to_uri_list_link}            xpath=//a/span[text()=' URIs']
${back_to_manage_page}              xpath=//a/span[text()=' Manage']
${new_uri_field}                    name=uri
${select_list_credential}           name=credentialPHID
${select_list_display}              name=display
${link_ssh_uri_phabricator_host}    //table[@class='aphront-table-view']/tbody/tr/td[@class='pri wide']/a[contains(text(),'ssh://git@phabricator.rivigo.com:2222/source/')]
${link_ssh_uri_bitbucket}           //table[@class='aphront-table-view']/tbody/tr/td[@class='pri wide']/a[contains(text(),'git@bitbucket.org')]

*** Keywords ***
Create Git Repo
    [Arguments]  ${name}  ${callsign}  ${shortname}
    Go To Location  diffusion/edit/form/default/?vcs=git
    Wait Until Element Is Visible  ${field_repo_name}  timeout=10
    Wait Until Element Is Visible  ${field_callsign}
    Wait Until Element Is Visible  ${field_shortname}
    Input Text  ${field_repo_name}  ${name}
    Input Text  ${field_callsign}  ${callsign}
    Input Text  ${field_shortname}  ${shortname}
    Click Button  ${button_submit}
    Wait Until Page Contains  Edit Basic Information
    Wait Until Page Contains  Properties

Go To Uris Page
    Wait Until Element Is Visible  ${link_uri}
    Click Link  ${link_uri}
    Wait Until Page Contains  Add New URI

# io_type : none / readwrite / observe / mirror
# display_type : always / never
Set IO For All Phabricator Uris
    [Arguments]  ${io_type}=none  ${display_type}=never
    ${ssh_uri_count}  Get Matching Xpath Count  ${link_ssh_uris}
    :FOR  ${index}  IN RANGE  ${ssh_uri_count}
    \  ${current_index}  Evaluate  ${index} + 1
    \  ${current_uri}  Set Variable  xpath=(${link_ssh_uris})[${current_index}]
    \  Wait Until Element Is Visible  ${current_uri}
    \  Click Link  ${current_uri}
    \  Wait Until Page Contains  Edit URI
    \  Click Link  Edit URI
    \  Wait Until Page Contains  Edit Repository URI
    \  Wait Until Element Is Enabled  ${select_list_io}
    \  Select From List By Value  ${select_list_io}  ${io_type}
    \  Select From List By Value  ${select_list_display}  ${display_type}
    \  Click Button  ${button_submit}
    \  Wait Until Element Is Not Visible  ${button_submit}
    \  Wait Until Page Contains  Edit URI
    \  Go Back To Uri List Page

Add Bitbucket Uri
    [Arguments]  ${uri}  ${io_type}=observe
    Wait Until Page Contains  Add New URI
    Click Link  Add New URI
    Wait Until Page Contains  Create Repository URI
    Wait Until Element Is Enabled  ${new_uri_field}
    Input Text  ${new_uri_field}  ${uri}
    Wait Until Element Is Enabled  ${select_list_io}
    Select From List By Value  ${select_list_io}  ${io_type}
    Select From List By Value  ${select_list_display}  never
    Click Button  ${button_submit}
    Wait Until Element Is Not Visible  ${button_submit}

Edit Bitbucket Uri
    [Arguments]  ${io_type}  ${display_type}
    Wait Until Element Is Visible  xpath=${link_ssh_uri_bitbucket}
    Click Element  xpath=${link_ssh_uri_bitbucket}
    Wait Until Page Contains  Edit URI
    Click Link  Edit URI
    Wait Until Page Contains  Edit Repository URI
    Wait Until Element Is Enabled  ${select_list_io}
    Select From List By Value  ${select_list_io}  ${io_type}
    Select From List By Value  ${select_list_display}  ${display_type}
    Click Button  ${button_submit}
    Wait Until Element Is Not Visible  ${button_submit}
    Wait Until Page Contains  Edit URI

Edit Phabricator Uri
    [Arguments]  ${io_type}  ${display_type}
    Wait Until Element Is Visible  xpath=${link_ssh_uri_phabricator_host}
    Click Element  xpath=${link_ssh_uri_phabricator_host}
    Wait Until Page Contains  Edit URI
    Click Link  Edit URI
    Wait Until Page Contains  Edit Repository URI
    Wait Until Element Is Enabled  ${select_list_io}
    Select From List By Value  ${select_list_io}  ${io_type}
    Select From List By Value  ${select_list_display}  ${display_type}
    Click Button  ${button_submit}
    Wait Until Element Is Not Visible  ${button_submit}
    Wait Until Page Contains  Edit URI


Set Ssh Credentials
    [Arguments]  ${credential_label}=K78 jenkins@rivigo.com
    Wait Until Page Contains  Set Credential
    Click Link  Set Credential
    Wait Until Element Is Visible  ${select_list_credential}
    Select From List By Label  ${select_list_credential}  ${credential_label}
    Click Button  ${button_submit}
    Wait Until Element Is Not Visible  ${button_submit}
    Wait Until Page Contains  Edit URI

Go Back To Uri List Page
    Wait Until Element Is Visible  ${back_to_uri_list_link}
    Click Element  ${back_to_uri_list_link}

Go To Basic Details Page
    Wait Until Element Is Visible  ${back_to_manage_page}
    Click Element  ${back_to_manage_page}

Activate Repository
    Wait Until Page Contains  Activate Repository
    Click Link  Activate Repository
    Wait Until Element Is Visible  ${button_submit}
    Sleep  2 Seconds
    Click Button  ${button_submit}
    Run Keyword And Ignore Error
    ...  Wait Until Element Is Not Visible  ${button_submit}  timeout=20
    Wait Until Page Contains  Importing...  timeout=20


Create Git Repo And Set Observe Mode
    [Arguments]  ${name}  ${callsign}  ${shortname}  ${uri}  ${io_type}
    Create Git Repo  ${name}  ${callsign}  ${shortname}
    Go To Uris Page
    Set IO For All Phabricator Uris
    Add Bitbucket Uri  ${uri}
    Set Ssh Credentials
    Go Back To Uri List Page
    ${uri_page_url}  Get Location
    ${repo_details}  Create Dictionary  name=${name}  Repo Status=Migrated  callsign=${callsign}  shortname=${shortname}  ssh link=${uri}  Phab Sync Status=${io_type}  uri_page_url=${uri_page_url}
    Write In Csv  ${REPO_CREATED_CSV}  ${repo_details}
    Go To Basic Details Page
    Activate Repository

Create Git Repo And Set Observe Mode From Csv
    [Arguments]  ${csv_data}
    ${csv_data}  Read From Csv As Dict  ${csv_data}
    ${csv_length}  Get Length  ${csv_data}
    :FOR  ${INDEX}  IN RANGE  ${csv_length}
    \  ${repo_details}  Get From List  ${csv_data}  ${INDEX}
    \  ${name}  Get From Dictionary  ${repo_details}  Name
    \  ${name}  Convert To Lowercase  ${name}
    \  ${callsign}  Set Variable  ${EMPTY}
    \  ${shortname}  Set Variable  ${name}
    \  ${uri}  Get From Dictionary  ${repo_details}  ssh link
    \  ${io_type}  Set Variable  observe
    \  ${status}  Get From Dictionary  ${repo_details}  Repo Status
    \  ${status}  Convert To Uppercase  ${status}
    \  Run Keyword If  '${status}' != 'INACTIVE' and '${status}' != 'MIGRATED'
    \  ...  Create Git Repo And Set Observe Mode  ${name}  ${callsign}  ${shortname}  ${uri}  ${io_type}
