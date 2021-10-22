#Import Active Directory Module. Needed for retrieving the list of all domain nodes via 'Get-ADObject' cmdlet.
Import-Module ActiveDirectory

$key1 = 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$key2 = 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
$valuename = 'WUServer', 'WUStatusServer', 'TargetGroupEnabled', 'Target Group', 'AUOptions', 'ScheduledInstallDay', 'NoAutoUpdate', 'UseWUServer', 'NoAUShutdownOption'
$outputFile = ".\GetWUSettings_Lubes_$(Get-Date -Format MMddyyyy_HHmmss).csv"
$results = New-Object System.Collections.Generic.List[System.Object]
$errors = New-Object System.Collections.Generic.List[System.Object]

Get-ADObject -LDAPFilter "(objectClass=computer)" |  Select-Object -ExpandProperty Name | Sort-Object name | Set-Variable -Name computers
#$computers = ENTER SPECIFIC NODES SEPERATED BY COMMA HERE AND COMMENT OUT (i.e. add a '#' in front of) LINE ABOVE TO TEST SPECIFIC SUBSET OF NODES

Write-Host "`nRunning... Please wait..."

foreach ($computer in $computers) {
	Try { 
        #Test-Connection $computer -Count 1 -ErrorAction Stop > $nul
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
	    $regkey1 = $reg.opensubkey($key1)
        $regkey2 = $reg.opensubkey($key2)
	    #Write-Host "$($computer): $($regkey.getvalue($valuename))"
        #Add-Content -Value "$($computer): Not Available" -Path $outputFile
        $results.add([PSCustomObject]@{'Hostname'=$computer ; 
                                       'WUServer' = $($regkey1.getvalue($valuename[0])) ;
                                       'WUStatusServer' = $($regkey1.getvalue($valuename[1])) ;
                                       'TargetGroupEnabled' = $($regkey1.getvalue($valuename[2])) ;
                                       'TargetGroup' = $($regkey1.getvalue($valuename[3])) ;
                                       'AUOptions' = $($regkey2.getvalue($valuename[4])) ;
                                       'ScheduledInstallDay' = $($regkey2.getvalue($valuename[5])) ;
                                       'NoAutoUpdate' = $($regkey2.getvalue($valuename[6])) ;
                                       'UseWUServer' = $($regkey2.getvalue($valuename[7])) ;
                                       'NoAUShutdownOption' = $($regkey2.getvalue($valuename[8])) ;
                                      }
                    )
    }
    Catch { 
        #Write-Host "$($computer): Not Available"
        #Add-Content -Value "$($computer): Not Available" -Path $outputFile
        $errors.add([PSCustomObject]@{'Hostname'=$computer ; 
                                      'Exception' = [string]$_.Exception.Message
                                      }
                    )
     }
}

$results | Sort-Object WUServer, Hostname | Export-CSV -Path $outputFile -NoTypeInformation
$results | Sort-Object WUServer, Hostname

if ($errors.Count -gt 0) {
    Add-Content -Path $outputFile -Value "`r`n** Unavailable Computers. Check WinRM Settings. **"
    $errors | ForEach-Object { $_.exception  = $_.exception -replace "`"", "" ; $_.exception  = $_.exception -replace "`r`n", "" }
    $errors | ConvertTo-CSV -NoTypeInformation | Add-Content -Path $outputFile
}
$errors | Sort-Object Hostname | Format-List

Write-Host "`n"
Pause


# References
# https://social.technet.microsoft.com/Forums/windows/en-US/0835c303-2edd-4c06-bbc9-5c7952402d0c/powershell-to-get-the-registry-key-value-from-remote-server-with-txt-file?forum=winserverpowershell