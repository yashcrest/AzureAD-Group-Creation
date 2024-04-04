Connect-MgGraph -Scopes "User.Read.All" , "Group.Write.All"
$groupID = "75820176-79f5-471d-a4b3-df3883a4139a"
$path = "./user-details.xlsx"
$members = Import-Excel -Path $path

foreach ($member in $members) {
    $userEmail = $user.Email
    try {
        # retrieve the user object 
        $userObject = Get-MgUser -Filter "mail eq '$userEmail' or userPrincipleName eq '$userEmail'"
        if ($userObject) {

            New-MgGroupMember -GroupId $groupID -DirectoryObjectId $userObject.Id
            Write-Host "$member has been added"
        }
        else {
            Write-Host "$userEmail not found"
        }
    }
    catch {
        Write-Host " Write-Host Failed to copy member $userEmail. Error: $_"
    }
}