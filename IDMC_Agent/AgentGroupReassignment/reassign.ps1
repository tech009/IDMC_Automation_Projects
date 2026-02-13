param (
    [Parameter(Mandatory=$true)][string]$IICSBaseUrl,
    [Parameter(Mandatory=$true)][string]$IICSUsername,
    [Parameter(Mandatory=$true)][string]$IICSPassword,
    [Parameter(Mandatory=$true)][string]$SecureAgentGroupName,
    [Parameter(Mandatory=$true)][string]$SecureAgentInstallLocation
)

function ExitWithError($message) {
    Write-Host "ERROR: $message" -ForegroundColor Red
    exit 1
}

# Step 1 & 2: Read InfaAgent.Id from infaagent.ini
$iniPath = Join-Path $SecureAgentInstallLocation "apps\agentcore\conf\infaagent.ini"
if (-Not (Test-Path $iniPath)) {
    ExitWithError "infaagent.ini not found at path: $iniPath"
}

$iniContent = Get-Content $iniPath
$infaAgentIdLine = $iniContent | Where-Object { $_ -match '^InfaAgent.Id=' }
if (-not $infaAgentIdLine) {
    ExitWithError "InfaAgent.Id not found in $iniPath"
}
$infaAgentId = $infaAgentIdLine -replace 'InfaAgent.Id=', ''
$infaAgentId = $infaAgentId.Trim()

# Step 3: Login to get icSessionId and serverUrl
$loginBody = @{ username = $IICSUsername; password = $IICSPassword } | ConvertTo-Json
try {
    $loginResponse = Invoke-RestMethod -Uri "$IICSBaseUrl/ma/api/v2/user/login" -Method POST -Body $loginBody -ContentType 'application/json'
} catch {
    ExitWithError "Login failed: $_"
}

$icSessionId = $loginResponse.icSessionId
$serverUrl = $loginResponse.serverUrl
if (-not $icSessionId -or -not $serverUrl) {
    ExitWithError "Failed to retrieve icSessionId or serverUrl from login response."
}

# Step 4 & 5: Get runtime environment details
try {
    $runtimeEnvResponse = Invoke-RestMethod -Uri "$serverUrl/api/v2/runtimeEnvironment/name/$SecureAgentGroupName" -Method GET -Headers @{ icSessionId = $icSessionId }
} catch {
    ExitWithError "Failed to get runtime environment details: $_"
}

$runtimeEnvId = $runtimeEnvResponse.id
$runtimeEnvName = $runtimeEnvResponse.name
$agents = $runtimeEnvResponse.agents
$isShared = $runtimeEnvResponse.isShared
if ($null -eq $isShared) { $isShared = $false }
if (-not $runtimeEnvId) {
    ExitWithError "Runtime environment '$SecureAgentGroupName' not found."
}

# Step 5 (validation): Get agent details and check agentGroupId
try {
    $agentResponse = Invoke-RestMethod -Uri "$serverUrl/api/v2/agent/$infaAgentId" -Method GET -Headers @{ icSessionId = $icSessionId }
} catch {
    ExitWithError "Failed to get agent details: $_"
}

$agentGroupId = $agentResponse.agentGroupId
if (-not $agentGroupId) {
    ExitWithError "agentGroupId not found for agent $infaAgentId"
}

if ($agentGroupId -eq $runtimeEnvId) {
    Write-Host "Agent already part of same Group and terminate the script"
    # Logout before exit
    Invoke-RestMethod -Uri "$serverUrl/api/v2/user/logout" -Method POST -Headers @{ icSessionId = $icSessionId } | Out-Null
    exit 0
}

# Step 6: Append new agent to agents list
$newAgent = @{ "@type" = "agent"; id = $infaAgentId; orgId = $infaAgentId.Substring(0,6) }

# Append new agent if not already present
if (-not ($agents | Where-Object { $_.id -eq $infaAgentId })) {
    $agents += $newAgent
}

# Step 7: POST updated runtime environment
$updatePayload = @{
    "@type" = "runtimeEnvironment"
    name = $runtimeEnvName
    agents = $agents
    isShared = $isShared
} | ConvertTo-Json -Depth 10

try {
    $updateResponse = Invoke-RestMethod -Uri "$serverUrl/api/v2/runtimeEnvironment/$runtimeEnvId" -Method POST -Headers @{ icSessionId = $icSessionId } -Body $updatePayload -ContentType 'application/json'
} catch {
    ExitWithError "Failed to update runtime environment: $_"
}

# Check if response contains error
if ($updateResponse.'@type' -eq 'error') {
    Write-Host "Error Re-assigning Secure Agent"
    $updateResponse | ConvertTo-Json -Depth 10 | Write-Host
} else {
    Write-Host "Re-Assignment Successful"
}

# Step 8: Logout
try {
    Invoke-RestMethod -Uri "$serverUrl/api/v2/user/logout" -Method POST -Headers @{ icSessionId = $icSessionId } | Out-Null
    Write-Host "Logged out successfully."
} catch {
    Write-Warning "Logout failed: $_"
}
