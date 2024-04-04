# connect to ms graph
Connect-MgGraph
# fetching AWS groups and extracting suffixes
$groups = Get-MgGroup -Filter "startswith(displayname, 'aad-role-aws-')" 

# preparing data for excel
$dataForExcel = foreach($group in $groups) {
    #checking source
    $source = if ($group.OnPremisesSyncEnabled -eq $null) { "Cloud" } else { "Windows Server AD" }
    #members count
    $members = Get-MgGroupMember -GroupId $group.Id 
    $membersCount = $members.Count
    [PSCustomObject]@{
        DisplayName = $group.DisplayName
        Source = $source
        MembersCount = $membersCount
    }
}

$dataForExcel | Export-Excel -Path ./old_aws_groups.xlsx -AutoSize
