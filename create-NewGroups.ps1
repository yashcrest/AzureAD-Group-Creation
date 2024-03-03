#importing the data from excel file
$suffixes = Import-Excel -Path ./awsGroup.xlsx | Select-Object -ExpandProperty Suffix

# creating new sec groups
foreach($suffix in $suffixes) {
    $groupName = "ag-az-aad-aws-$suffix"
    $guid = [guid]::NewGuid().ToString() #generating GUID for mailNickName

    #check if the group exists
    $existingGroup = Get-MgGroup -Filter "displayName eq '$groupName'"

    if($existingGroup -eq $null) {

        $params = @{
            description = $suffix
            displayname = $groupName
            mailEnabled = $false
            securityEnabled = $true
            mailNickName = $guid
        }
        try {
            New-MgGroup @params
            Write-Host "Created new group: $groupName"
            Write-Host "$guid"
        } catch {
            Write-Host "Failed to create group: $groupName. Error: $_"
        }
    } else {
        #group already exists msg
        Write-Host "group already exists: $groupName"
    }
}