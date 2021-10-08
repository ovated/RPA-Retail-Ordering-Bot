*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.Archive
Library           Dialogs
Library           RPA.Robocorp.Vault

*** keywords ***
Open the Ecommerce website
    #${URL}=  User url input
    ${secret}=    Get Secret    secret
    Open Available Browser    ${secret}[url]

*** Keywords ***
Give Consent
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

*** Keywords *** 
Fill form
    #${orders}=  Read table from CSV    orders.csv
    [Arguments]    ${orders}
    Select From List By Value    id:head  ${orders}[Head]
    Input Text    id:address    ${orders}[Address]
    Input Text    css:input[placeholder="Enter the part number for the legs"]   ${orders}[Legs]  
    Select Radio Button    body    ${orders}[Body]


*** Keywords ***
View the robot
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image

*** Keywords ***
Screenshot the robot
    [Arguments]    ${orders}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}${orders}.png
    ${screenshot}    Set Variable    ${CURDIR}${/}output${/}${orders}.png
    [Return]    ${screenshot}

*** Keywords ***
Submit the order
    Wait Until Element Is Visible    id:order
    Click Button    id:order
    ${ans}=  Does Page Contain Element  class:alert
    
    FOR  ${i}  IN  RANGE  100
        ${receipt}    Is Element Visible    id:receipt
        IF  not ${receipt}
            Click Button    id:order
        ELSE
            Exit For Loop
        END
     END

    Wait Until Element Is Visible    id:receipt    3000ms



*** Keywords ***
Save the receipt as a pdf
    [Arguments]    ${order}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${CURDIR}${/}output${/}${order}.pdf
    ${pdf}    Set Variable    ${CURDIR}${/}output${/}${order}.pdf
    [Return]    ${pdf}

*** Keywords ***
Embed the robot screenshot and PDF receipt
    [Arguments]    ${screenshot}    ${pdf}
    Log     ${pdf}
    Open Pdf    ${pdf}   
    Add Watermark Image To Pdf  ${screenshot}   ${pdf}
    Close Pdf

*** Keywords ***
Order another robot
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another
    Wait Until Element Is Visible   class:alert-buttons

*** Keywords ***
Archive of pdf receipts
    Archive Folder With Zip    ${CURDIR}${/}output   orders.zip    include=*.pdf

*** Keywords ****
Log Out
    Close Browser

*** keywords ***
Developer name
        ${dev_name} =	Get Value From User    Name of Developer? 
        [Return]    ${dev_name}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the Ecommerce website
        ${orders}=  Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Give consent
        Fill form   ${order}
        View the robot
        ${screenshot}=  Screenshot the robot    ${order}[Order number]
        Submit the order
        ${pdf}=    Save the receipt as a pdf    ${order}[Order number]
        Log    ${pdf}
        Log    ${screenshot}
        Embed the robot screenshot and PDF receipt     ${screenshot}    ${pdf}
        Order Another Robot
    END
    Log Out
    Archive of pdf receipts
    Developer name
