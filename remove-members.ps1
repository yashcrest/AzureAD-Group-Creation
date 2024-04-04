$groupMapping = Import-Excel -Path ./new_aws_groups.xlsx | Select-Object Suffix , OriginalDisplayName
 

foreach($map in $groupMapping) {
    $groupName = $map.OriginalDisplayName

    #fetch members
    $group = Get-MgGroup -Filter "displayName eq '$groupName'"
    
    if($group -eq $null) {
        Write-Host "Group not found: $groupName"
        continue
    }
    $groupId = $group.Id

    #get members of each group
    $members = Get-MgGroupMember -GroupId $groupId

    foreach($member in $members) {
        try {
            #remove each member from groups
            Remove-MgGroupMemberByRef -DirectoryObjectId $member.Id -GroupId $groupId
            Write-Host "removed member $($member.Id) from group: $groupName"
        } catch {
            Write-Host "Failed to remove member $($member.Id) from $groupName. Error: $_"
        }
`    }
}