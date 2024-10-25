*** Settings ***
Library    Browser
Library    JSONLibrary
Library    WebCrawlerLibrary
Library    Collections
Library    String
Library    RequestsLibrary

Suite Setup    Setup Suite
Suite Teardown    Teardown Suite
*** Variables ***
@{ASSIGNMENT_SEARCH_WORDS}    Test    QA    quality    tester    automaatiotestaus    Testiautomaatioasiantuntija
@{QUALIFIED_ASSIGNMENTS}
${HEADLESS}    True
${SLACK_URL}    https://hooks.slack.com/services/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
${SLACK_NAME}    incoming-webhook
${USER_NAME}    RF Assignments Bot
${NOTIFY_SLACK}    True
${ANNOUNCEMENTS_JSON}    ${CURDIR}/testdata/assignments.json

*** Test Cases ***

Should Find Suitable Assigments from Finitec
    [Documentation]    This test case should find suitable assigments from Finitec
    [Tags]    finitec
    ${baseUrl}=    Set Variable    https://www.finitec.fi
    Open Browser    ${baseUrl}/gigs    headless=${HEADLESS}
    Click    [id='accept']
    @{assignments}    Get Elements    selector=div > div > div > div > div > div > div > div > a

    FOR    ${assignment}    IN    @{assignments}
            ${txt}=    Get Text    ${assignment}
            ${freq}=    Find Words Frequency    ${txt}    ${ASSIGNMENT_SEARCH_WORDS}

            IF    ${freq} > 0
                ${link}=    Get Attribute    ${assignment}    href
                ${header}=    Get First Line    ${txt}
                ${anchor}=    Form Slack Link    ${header}    ${baseUrl}${link}
                Append To List    ${QUALIFIED_ASSIGNMENTS}    ${anchor}
            END 
    END

Should Find Suitable Assigments from Digia
    [Documentation]    This test case should find suitable assigments from Digia
    [Tags]    digia
    ${baseUrl}=    Set Variable    https://digiahub.com/Project/OpenProjects
    Open Browser    ${baseUrl}    headless=${HEADLESS}
    @{assignments}    Get Elements    selector=div > div > div > div > div > div:has(h4)        # div > div > div > div > h4

    FOR    ${assignment}    IN    @{assignments}
            ${txt}=    Get Text    ${assignment}
            ${freq}=    Find Words Frequency    ${txt}    ${ASSIGNMENT_SEARCH_WORDS}

            IF    ${freq} > 0
                # Open assignment panel
                Click    ${assignment} >> div[class="panel-button panel-button-event"]
                ${apply_btn}=    Get Element    ${assignment} >> div[class="panel-button apply-button-event"]
                # Extract assignment id from onclick attribute
                ${onclick}=    Get Attribute    ${apply_btn}    onclick
                ${assignment_id}=    Extract Word Between    ${onclick}    '    '
                ${header}=    Get Line From    ${txt}    1     
                ${anchor}=    Form Slack Link    ${header}    https://digiahub.com/Project/ApplyForProject/${assignment_id}
                Append To List    ${QUALIFIED_ASSIGNMENTS}    ${anchor}
            END 
    END

Should Find Suitable Assigments from Onsiter
    [Documentation]    This test case should find suitable assigments from Onsiter
    [Tags]    onsiter
    ${baseUrl}=    Set Variable    https://onsiter.com
    Open Browser    ${baseUrl}/fi/projects    headless=${HEADLESS}
    ${cookie_btn}=    Get Element    css=button.button-inline-green
    Click    ${cookie_btn}    

    @{assignments}    Get Elements    selector=strong[class='cards__title cards-title']

    FOR    ${assignment}    IN    @{assignments}
            ${txt}=    Get Text    ${assignment}
            ${freq}=    Find Words Frequency    ${txt}    ${ASSIGNMENT_SEARCH_WORDS}

            IF    ${freq} > 0
                ${show_assignment_btn}=    Get Element    ${assignment} >> a
                ${link}=    Get Attribute    ${show_assignment_btn}    href
                ${anchor}=    Form Slack Link    ${txt}    ${baseUrl}${link}
                Append To List    ${QUALIFIED_ASSIGNMENTS}    ${anchor}       
            END 
    END

Should Find Suitable Assigments from Verama
    [Documentation]    This test case should find suitable assigments from Onsiter
    [Tags]    verama
    ${baseUrl}=    Set Variable    https://app.verama.com
    Open Browser    ${baseUrl}/en/job-requests?page=0&size=20&sortConfig=%5B%7B%22sortBy%22%3A%22firstDayOfApplications%22%2C%22order%22%3A%22DESC%22%7D%5D&filtersConfig=%7B%22location%22%3A%7B%22id%22%3Anull%2C%22signature%22%3A%22%22%2C%22city%22%3Anull%2C%22country%22%3A%22Suomi%22%2C%22name%22%3A%22Suomi%22%2C%22locationId%22%3A%22here%3Acm%3Anamedplace%3A20241487%22%2C%22countryCode%22%3A%22FIN%22%2C%22suggestedPhoneCode%22%3A%22FI%22%7D%2C%22remote%22%3A%5B%5D%2C%22query%22%3A%22%22%2C%22skillRoleCategories%22%3A%5B%5D%2C%22frequency%22%3A%22DAILY%22%2C%22radius%22%3A0%2C%22dedicated%22%3Afalse%2C%22originIds%22%3A%5B%5D%2C%22favouritesOnly%22%3Afalse%2C%22recommendedOnly%22%3Afalse%2C%22languages%22%3A%5B%5D%2C%22level%22%3A%5B%5D%2C%22skillIds%22%3A%5B%5D%2C%22skills%22%3A%5B%5D%7D    
    ...    headless=${HEADLESS}
    ${cookie_btn}=    Get Element    selector=#cookies-bar > div > button > div > div > i
    Click    ${cookie_btn}    

    @{assignments}    Get Elements    css=a.route-section

    FOR    ${assignment}    IN    @{assignments}
            ${txt}=    Get Text    ${assignment}
            ${freq}=    Find Words Frequency    ${txt}    ${ASSIGNMENT_SEARCH_WORDS}
            Log    message=${txt}
            IF    ${freq} > 0
                ${link}=    Get Attribute    ${assignment}    href
                ${header}=    Get First Line    ${txt}
                ${anchor}=    Form Slack Link    ${header}    ${baseUrl}/en${link}           
                Append To List    ${QUALIFIED_ASSIGNMENTS}    ${anchor}       
            END 
    END
    
*** Keywords ***  
Setup Suite
    Log    message=Setup Suite

Teardown Suite
    @{new_assinments}=    Add Announcements    ${QUALIFIED_ASSIGNMENTS}    ${ANNOUNCEMENTS_JSON}
    
    ${l}=    Get Length    ${new_assinments}

    IF    ${l} > 0
        ${search_words}=    Catenate    SEPARATOR=,${EMPTY}    @{ASSIGNMENT_SEARCH_WORDS}
        Insert Into List    ${new_assinments}    0    ${EMPTY}
        Insert Into List    ${new_assinments}    0    ${l} uutta toimeksiantoa löydetty!
        Insert Into List    ${new_assinments}    0    Toimeksiannot avain sanoilla:${search_words}
        ${assingments_str}=    Catenate    SEPARATOR=\n    @{new_assinments}

        IF    ${NOTIFY_SLACK}
            Notify Slack    ${assingments_str}    ${SLACK_URL}
        ELSE
            Log    ${assingments_str}
        END
    ELSE
        Log    No new assignments found!
    END
    
    Remove Old Announcements    file_path=${ANNOUNCEMENTS_JSON}
    Close Browser