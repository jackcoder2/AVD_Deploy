clear-host
Logout-AzAccount

[switch] $ValidateOnly = $false
$deploymentRegion = "westus3"
$TemplateFile = '~/Public/code/AVD_Deploy/AVD_Deploy_Infrastructure.json'
$TemplateParametersFile = '~/Public/code/AVD_Deploy/AVD_Deploy_Infrastructure_param.json'
$authObject = Get-Content -Path /home/mmeade/Test/cjPATest6.json | ConvertFrom-Json
$credential = New-Object System.Management.Automation.PSCredential($($authObject.clientId),$($($authObject.secret) | ConvertTo-SecureString -asPlainText -Force))

Connect-AzAccount -Credential $Credential -Tenant $($authObject.tenantId) -ServicePrincipal -Subscription $($authObject.subscriptionId)

function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

if ($ValidateOnly) {
    $ErrorMessages = Format-ValidationOutput (
        Test-AzSubscriptionDeployment -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParametersFile -Location $deploymentRegion -Verbose)
    if ($ErrorMessages) {Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    } else {Write-Output '', 'Template is valid.'}
}
else {
    New-AzSubscriptionDeployment -Name ('AVDDeploy' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParametersFile -Location $deploymentRegion -Verbose -ErrorVariable ErrorMessages
    if ($ErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }
}