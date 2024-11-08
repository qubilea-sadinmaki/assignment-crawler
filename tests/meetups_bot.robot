*** Settings ***
Library    Browser
Library    JSONLibrary
Library    WebCrawlerLibrary
Library    Collections
Library    String
Library    OperatingSystem

Suite Setup       Setup Suite
Suite Teardown    Teardown Suite
*** Variables ***
@{SEARCH_WORDS}    
...    Kubernetes
...    Copilot
...    Robot Framework
...    Playwright
...    Testautomation
...    AWS
...    Ai solutions
...    DevOps
@{QUALIFIED_NOTIFICATION}
${HEADLESS}                   ${True}
${SLACK_URL}
${NOTIFY_SLACK}               ${False}
${JSON_PATH}         ${CURDIR}/testdata/meetups.json

*** Test Cases ***

Should Find Suitable Meetups from Devops-Finland
    [Tags]    devops-finland    skip
    Crawl Meetupcom Group Page    devops-finland    Devops Finland

Should Find Suitable Meetups from Helsinki Python
    [Tags]    helsinki-python    skip
    Crawl Meetupcom Group Page    helpy-meetups    Helsinki Python

Should Find Suitable Meetups from Finnish Testing Meetup Group
    [Tags]    finnish-testing-meetup-group    skip
    Crawl Meetupcom Group Page    finland-testing-meetup-group    Finnish Testing Meetup Group

Should Find Suitable Meetups from Eficode
    [Tags]    eficode
    ${base_url}=    Set Variable    https://www.eficode.com/fi/tapahtumat?location=8
    ${content_type}=    Set Variable    &content_type=4    # &content_type=show-all
    New Page    ${base_url}${content_type}
    Click    [id='onetrust-accept-btn-handler']
    @{blocks}    Get Elements    [class="row post-container row-cols-md-3 row-cols-sm-2 row-cols-1"]
    ${upcoming}    Get From List    ${blocks}    0
    @{meetups}    Get Elements    ${upcoming} >> div[class="card h-100"]

    FOR    ${meetup}    IN    @{meetups}
            ${header}=    Get Text    selector=${meetup} >> .card-body > h4
            ${link}=    Get Attribute    ${meetup} >> .info-section > a    href
            # Go inside to meetup page
            Click    selector=${meetup}
            ${txt}=    Get Text    body
            ${freq}=    Find Words Frequency    ${txt}    ${SEARCH_WORDS}
            
            IF    ${freq} > 0                
                ${anchor}=    Form Slack Link    Eficode: ${header}    ${link}
                Append To List    ${QUALIFIED_NOTIFICATION}    ${anchor}
            END 

            # Go back to the main page
            Go Back
            Wait For Load State    state=load
    END
    
Should Find Suitable Meetups from Meetup.com
    [Tags]    meetup.com
    ${base_url}=    Set Variable    https://www.meetup.com/find
    ${content_type}=    Set Variable    /?location=fi--Helsinki&source=EVENTS&categoryId=546&distance=tenMiles
    New Page    ${base_url}${content_type}
    Click    [id='onetrust-accept-btn-handler']  
    
    @{meetups}    Get Elements    [data-testid="categoryResults-eventCard"]

    FOR    ${meetup}    IN    @{meetups}

        ${header}=    Get Text    selector=${meetup} >> div > div > div > a > h2[class="text-gray7 font-medium text-base pb-1 pt-0 line-clamp-3"]
        ${txt}=    Get Text    ${meetup}
        # Log To Console    message=TXT: ${txt}
        ${freq}=    Find Words Frequency    ${header}    ${SEARCH_WORDS}

        IF    ${freq} > 0
            @{anchors}=    Get Elements    ${meetup} >> div > div > div > a
            ${anchor}=    Get From List    ${anchors}    0
            ${href}=    Get Attribute    ${anchor}    href
            
            ${line}=    Form Slack Link    Meetup.com: ${header}    ${href}
            Append To List    ${QUALIFIED_NOTIFICATION}    ${line}
        END 

    END  

*** Keywords *** 
Crawl Meetupcom Group Page
    [Documentation]    This method should find suitable meetups from page in meetup.com
    [Arguments]    ${page_url}    ${page_name}
    New Page    https://www.meetup.com/${page_url}/events/?type=upcoming
    Click    [id='onetrust-accept-btn-handler'] 
    @{meetups}    Get Elements    a[class="flex h-full flex-col justify-between space-y-5 outline-offset-8 hover:no-underline"]

    FOR    ${meetup}    IN    @{meetups}
            # Go inside to meetup page
            Click    selector=${meetup}
            ${txt}=    Get Text    [id="event-details"]
            ${freq}=    Find Words Frequency    ${txt}    ${SEARCH_WORDS}

            IF    ${freq} > 0
                ${link}=    Get Attribute    ${meetup}    href
                ${header}=    Get Text    selector=div > h1
                ${anchor}=    Form Slack Link    ${page_name}: ${header}    ${link}
                Append To List    ${QUALIFIED_NOTIFICATION}    ${anchor}
            END 

            # Go back to the main page
            Go Back
            Wait For Load State    state=load
    END 
Setup Suite
    IF    ${HEADLESS} == False
        Open Browser    browser=chromium    headless=${HEADLESS}
    END

    IF    ${NOTIFY_SLACK}
        IF   '${SLACK_URL}' == '${EMPTY}'
            ${url}=    Get Environment Variable    name=SLACK_URL
            Set Suite Variable    ${SLACK_URL}    ${url}        
        END
    END
    

Teardown Suite
    @{new_notifications}=    Add Notifications    ${QUALIFIED_NOTIFICATION}    ${JSON_PATH}
    
    ${l}=    Get Length    ${new_notifications}

    IF    ${l} > 0
        ${search_words}=    Catenate    SEPARATOR=,${EMPTY}    @{SEARCH_WORDS}
        Insert Into List    ${new_notifications}    0    ${EMPTY}
        Insert Into List    ${new_notifications}    0    ${l} uutta meetup:pia löydetty!
        Insert Into List    ${new_notifications}    0    Meetup:it avain sanoilla:${search_words}
        ${notifications_str}=    Catenate    SEPARATOR=\n    @{new_notifications}

        IF    ${NOTIFY_SLACK}
            Notify Slack    ${notifications_str}    ${SLACK_URL}
            Log To Console    message=New assignments found! Notifying Slack.
        ELSE
            Log    ${notifications_str}
        END
    ELSE
        Log To Console    No new meetups found!
    END
    
    Remove Old Notifications    file_path=${JSON_PATH}
    Close Browser