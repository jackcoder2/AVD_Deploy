
clear-host
Logout-AzAccount

[switch] $ValidateOnly = $false

[string] $ResourceGroupLocation = 'westus3'
[string] $ResourceGroupName = 'AVDHub'

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

# Create the resource group only when it doesn't already exist
if ($null -eq (Get-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force -ErrorAction Stop
}

if ($ValidateOnly) {
    $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParametersFile -Verbose)
    if ($ErrorMessages) {Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    } else {Write-Output '', 'Template is valid.'}
}
else {
    New-AzResourceGroupDeployment -Name ('TestDeploy' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $TemplateParametersFile -Force -Verbose -ErrorVariable ErrorMessages
    if ($ErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }
}








<#
# ntapImageGallery Service Principal
$credential = New-Object System.Management.Automation.PSCredential('804af138-38b2-4c08-99aa-5affe9604194',$('Bh7~I_l2F4480QsFOnOOhF9_M1iRHyo_NO' | ConvertTo-SecureString -asPlainText -Force))

# CloudJumper Automation
Connect-AzAccount -Credential $Credential -Tenant 'e35ad54b-a665-4bb1-a157-c2a131131a6c' -ServicePrincipal -Subscription '0ef77462-ff9d-4823-8a72-401842a86204'

# cjPATest5
Connect-AzAccount -Credential $Credential -Tenant '1c8e790c-7cfd-499c-bc4e-2ffce4b73071' -ServicePrincipal -Subscription 'e5eb1a3f-3921-4ebc-aa24-78fbbc17ce6e'
#>





