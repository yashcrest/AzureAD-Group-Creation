# Import the Excel file
$groupMappings = Import-Excel -Path "./old_aws_groups.xlsx" | Where-Object { $_.Source -eq "Windows Server AD" }

foreach ($mapping in $groupMappings) {
    # Extract the suffix from the old group DisplayName
    $oldSuffix = ($mapping.DisplayName -split "-")[-1]

    #convert to lowercase
    $lowerCaseSuffix = $oldSuffix.ToLower()

    # Construct new group name based on the suffix
    $newGroupName = "ag-az-aad-aws-$lowerCaseSuffix"

    # Fetch the old group ID
    $oldGroup = Get-MgGroup -Filter "displayName eq '$($mapping.DisplayName)'"
    $oldGroup
    
    if ($null -eq $oldGroup) {
        Write-Host "Old group not found: $($mapping.DisplayName)"
        continue
    }
    
    # Fetch the new group ID by its name
    $newGroup = Get-MgGroup -Filter "displayName eq '$newGroupName'"
    if ($null -eq $newGroup) {
        Write-Host "New group not found: $newGroupName"
        continue
    }
    
    # Get members of the old group
    $oldGroupId = [string]$oldGroup.Id
    $members = Get-MgGroupMember -GroupId $oldGroupId

    foreach ($member in $members) {
        try {
            # Copy each member to the new group
            New-MgGroupMember -GroupId $newGroup.Id -DirectoryObjectId $member.Id
            Write-Host "Copied member $($member.Id) to new group: $newGroupName"
        }
        catch {
            Write-Host "Failed to copy member $($member.Id) to $newGroupName. Error: $_"
        }
    }
}
