#Requires -Version 5.1

Connect-ExchangeOnline

# Function to check if a string is a GUID
function Test-IsGuid {
    param (
        [string]$GuidString
    )
    return [guid]::TryParse($GuidString, [ref][guid]::Empty)
}

Get-DistributionGroup -ResultSize Unlimited | Where-Object {
    $isNameGuid = Test-IsGuid $_.Name
    $nameOrDisplayName = if ($isNameGuid) { $_.DisplayName } else { $_.Name }
    $nameOrDisplayName -match "\.au|\.nz|rhipe|parallo|concierge" -and $nameOrDisplayName -notmatch "rg-"
} | ForEach-Object {
    $isNameGuid = Test-IsGuid $_.Name
    $groupName = if ($isNameGuid) { $_.DisplayName } else { $_.Name }

    $count = 0; $containsNestedDG = $false
    $members = Get-DistributionGroupMember -Identity $_.Identity -ResultSize Unlimited -ErrorAction SilentlyContinue
    foreach ($member in $members) {
        if ($member.RecipientType -eq "UserMailbox" -or $member.RecipientType -eq "MailContact") {
            $count++
        } elseif ($member.RecipientType -eq "MailUniversalDistributionGroup" -or $member.RecipientType -eq "MailUniversalSecurityGroup") {
            $containsNestedDG = $true
            $nestedMembers = Get-DistributionGroupMember -Identity $member.Identity -ResultSize Unlimited -ErrorAction SilentlyContinue
            $count += $nestedMembers.Count
        }
    }

    $managedByResolvedNames = $_.ManagedBy | ForEach-Object {
        if ($_ -eq "Organization Management") {
            return "Organization Management"
        } else {
            $managerDisplayName = $_
            try {
                $managerDetails = Get-User -Identity $_ -ErrorAction Stop
                if ($managerDetails.UserAccountControl -match "AccountDisabled") {
                    $managerDisplayName = "$($managerDetails.DisplayName) (Leaver)"
                } else {
                    $managerDisplayName = $managerDetails.DisplayName
                }
            } catch {
                Write-Warning "Failed to resolve manager details for: $_"
            }
            return $managerDisplayName
        }
    }

    $managedBy = $managedByResolvedNames -join ', '
    
    [PSCustomObject]@{
        Name = $groupName;
        DisplayName = $_.DisplayName;
        PrimarySmtpAddress = $_.PrimarySmtpAddress;
        MembersCount = $count;
        ContainsNestedDG = $containsNestedDG;
        ManagedBy = $managedBy;
        WhenCreatedUTC = $_.WhenCreatedUTC;
        WhenChangedUTC = $_.WhenChangedUTC;
        Environment = if ($_.IsDirSynced) { "Synced from On-Premises" } else { "In cloud" };
    }
} | Export-Csv -Path ('DistributionGroupsDetails-' + (Get-Date -Format "dd-MM-yyyy_HH-mm-ss") + '.csv') -NoTypeInformation -Encoding UTF8

Disconnect-ExchangeOnline -Confirm:$false
