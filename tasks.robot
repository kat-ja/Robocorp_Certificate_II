*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Archive
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    website
    Open Available Browser    ${secret}[order_url]
    #Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button When Visible    css:.btn.btn-dark

Get orders
    Add heading    Upload CSV File
    Add text input    label=Give URL for CSV-file    name=url   
    ${response}=    Run dialog
    Download    ${response.url}    overwrite=True   
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True      
    ${table}=    Read table from CSV    orders.csv    header=True       
    [Return]    ${table}

Fill the form
    [Arguments]    ${row}
    Select From List By Value   id:head    ${row}[Head]
    Select Radio Button    body    id-body-${row}[Body]
    Input Text    css:.form-control    ${row}[Legs]
    Input Text    name:address    ${row}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    Wait Until Keyword Succeeds    5x    1 sec    Submit Form    tag:form

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    tag:form    5    # preview takes some time to load

    # variables for head and body
    ${head}=    Get Selected List Label    id:head
    ${body}=    Get Text    //*[@id="root"]/div/div[1]/div/div[1]/form/div[2]/div/div[${row}[Body]]/label
    
    ${order_html}=    Catenate      
    ...    <html><h3>Order number: ${row}[Order number]</h3><p>Head: ${head}<br>Body: ${body}<br>Legs: ${row}[Legs]<br>Address: ${row}[Address]</p></html>
    Log    ${order_html}

    Html To Pdf    ${order_html}    ${CURDIR}\\output\\pdf\\${row}[Order number].pdf

    [Return]    ${CURDIR}\\output\\pdf\\${row}[Order number].pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:robot-preview-image    2
    Set Screenshot Directory    ${CURDIR}\\output\\screenshots
    ${scrshot}=    Capture Element Screenshot    id:robot-preview-image    ${row}[Order number].png
    [Return]     ${scrshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}      
    ${files}=    Create List   ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=True
    Close Pdf    ${pdf}

Go to order another robot
    # what was expected here? to order just some extra robot?
    # filling form
    Select From List By Value   id:head    1
    Select Radio Button    body    id-body-1
    Input Text    css:.form-control    2
    ${legs}=   Get Element Attribute    css:.form-control      value
    Input Text    name:address    My Address 1
    ${address}=    Get Element Attribute    name:address    value

    # clicking preview button
    Click Button    id:preview

    # submitting form
    Wait Until Keyword Succeeds    5x    1 sec    Submit Form    tag:form

    # making pdf
    Wait Until Element Is Visible    tag:form
    # variables for head and body
    ${head}=    Get Selected List Label    id:head
    ${body}=    Get Text    //*[@id="root"]/div/div[1]/div/div[1]/form/div[2]/div/div[1]/label

    ${order_html}=    Catenate      
    ...    <html><h3>Order number: Another robot </h3><p>Head: ${head}<br>Body: ${body}<br>Legs: ${legs}<br>Address: ${address}</p></html>

    ${path}=    Set Variable    ${CURDIR}\\output\\pdf\\another_robot.pdf
    Html To Pdf    ${order_html}    ${path}

    # taking screenshot
    Wait Until Element Is Visible    id:robot-preview-image    2
    Set Screenshot Directory    ${CURDIR}\\output\\screenshots
    ${scrshot}=    Capture Element Screenshot    id:robot-preview-image    another_robot.png

    # embed screenshot in pdf
    Open Pdf    ${path}       
    ${files}=    Create List   ${scrshot}
    Log    ${files}
    Add Files To Pdf    ${files}    ${path}    append=True
    Close Pdf    ${path} 

Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}\\output\\pdf    pdfs.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}   
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}
        ${screenshot}=    Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}   
    END
    Go to order another robot  
    Create a ZIP file of the receipts
