[CmdletBinding()]
param(
    [ValidateSet("tabs", "title", "eval", "click", "type", "navigate")]
    [string]$Action = "tabs",
    [int]$Port = 9222,
    [string]$TabMatch,
    [string]$Expression,
    [string]$Selector,
    [string]$Text,
    [string]$Url
)

$ErrorActionPreference = "Stop"

function Get-Tabs {
    param([int]$DebugPort)
    $all = Invoke-RestMethod -Uri "http://127.0.0.1:$DebugPort/json" -ErrorAction Stop
    return @($all | Where-Object { $_.type -eq "page" -and $_.webSocketDebuggerUrl })
}

function Get-TargetTab {
    param(
        [int]$DebugPort,
        [string]$Match
    )
    $tabs = Get-Tabs -DebugPort $DebugPort
    if ($tabs.Count -eq 0) {
        throw "No page tabs found on debug port $DebugPort."
    }

    if ([string]::IsNullOrWhiteSpace($Match)) {
        return $tabs[0]
    }

    $hit = $tabs | Where-Object {
        ($_.title -match $Match) -or ($_.url -match $Match)
    } | Select-Object -First 1

    if ($null -eq $hit) {
        throw "No tab matched pattern: $Match"
    }
    return $hit
}

function Receive-WebSocketMessage {
    param([System.Net.WebSockets.ClientWebSocket]$WebSocket)
    $buffer = New-Object byte[] 65536
    $sb = New-Object System.Text.StringBuilder
    do {
        $segment = [System.ArraySegment[byte]]::new($buffer)
        $result = $WebSocket.ReceiveAsync($segment, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
        if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
            throw "WebSocket closed by target."
        }
        [void]$sb.Append([System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count))
    } while (-not $result.EndOfMessage)
    return $sb.ToString()
}

function Invoke-CDP {
    param(
        [string]$WsUrl,
        [string]$Method,
        [hashtable]$Params = @{},
        [int]$TimeoutMs = 7000
    )

    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $ws.ConnectAsync([Uri]$WsUrl, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
    try {
        $id = [int](Get-Random -Minimum 1000 -Maximum 999999)
        $payload = [ordered]@{
            id = $id
            method = $Method
        }
        if ($Params.Count -gt 0) {
            $payload.params = $Params
        }
        $json = $payload | ConvertTo-Json -Compress -Depth 20
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $segment = [System.ArraySegment[byte]]::new($bytes)
        $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).GetAwaiter().GetResult()

        $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMs)
        while ([DateTime]::UtcNow -lt $deadline) {
            $raw = Receive-WebSocketMessage -WebSocket $ws
            $obj = $raw | ConvertFrom-Json
            if ($null -ne $obj.id -and [int]$obj.id -eq $id) {
                return $obj
            }
        }
        throw "Timeout waiting CDP response for method $Method."
    }
    finally {
        if ($ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
            $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "done", [Threading.CancellationToken]::None).GetAwaiter().GetResult()
        }
        $ws.Dispose()
    }
}

function Invoke-Eval {
    param(
        [string]$WsUrl,
        [string]$Js
    )
    return Invoke-CDP -WsUrl $WsUrl -Method "Runtime.evaluate" -Params @{
        expression = $Js
        returnByValue = $true
    }
}

switch ($Action) {
    "tabs" {
        $tabs = Get-Tabs -DebugPort $Port |
            Select-Object id, title, url
        $tabs | ConvertTo-Json -Depth 5
        break
    }

    "title" {
        $tab = Get-TargetTab -DebugPort $Port -Match $TabMatch
        $res = Invoke-Eval -WsUrl $tab.webSocketDebuggerUrl -Js "document.title"
        [ordered]@{
            tab_id = $tab.id
            title = $res.result.result.value
            url = $tab.url
        } | ConvertTo-Json -Depth 5
        break
    }

    "eval" {
        if ([string]::IsNullOrWhiteSpace($Expression)) {
            throw "Use -Expression with Action=eval."
        }
        $tab = Get-TargetTab -DebugPort $Port -Match $TabMatch
        $res = Invoke-Eval -WsUrl $tab.webSocketDebuggerUrl -Js $Expression
        $res | ConvertTo-Json -Depth 20
        break
    }

    "click" {
        if ([string]::IsNullOrWhiteSpace($Selector)) {
            throw "Use -Selector with Action=click."
        }
        $tab = Get-TargetTab -DebugPort $Port -Match $TabMatch
        $sel = $Selector | ConvertTo-Json -Compress
        $js = @"
(() => {
  const el = document.querySelector($sel);
  if (!el) return { ok: false, reason: "selector_not_found" };
  el.click();
  return { ok: true };
})()
"@
        $res = Invoke-Eval -WsUrl $tab.webSocketDebuggerUrl -Js $js
        $res.result.result.value | ConvertTo-Json -Depth 10
        break
    }

    "type" {
        if ([string]::IsNullOrWhiteSpace($Selector) -or $null -eq $Text) {
            throw "Use -Selector and -Text with Action=type."
        }
        $tab = Get-TargetTab -DebugPort $Port -Match $TabMatch
        $sel = $Selector | ConvertTo-Json -Compress
        $txt = $Text | ConvertTo-Json -Compress
        $js = @"
(() => {
  const el = document.querySelector($sel);
  if (!el) return { ok: false, reason: "selector_not_found" };
  el.focus();
  el.value = $txt;
  el.dispatchEvent(new Event("input", { bubbles: true }));
  el.dispatchEvent(new Event("change", { bubbles: true }));
  return { ok: true, valueLength: el.value.length };
})()
"@
        $res = Invoke-Eval -WsUrl $tab.webSocketDebuggerUrl -Js $js
        $res.result.result.value | ConvertTo-Json -Depth 10
        break
    }

    "navigate" {
        if ([string]::IsNullOrWhiteSpace($Url)) {
            throw "Use -Url with Action=navigate."
        }
        $tab = Get-TargetTab -DebugPort $Port -Match $TabMatch
        $res = Invoke-CDP -WsUrl $tab.webSocketDebuggerUrl -Method "Page.navigate" -Params @{ url = $Url }
        [ordered]@{
            tab_id = $tab.id
            requested_url = $Url
            frame_id = $res.result.frameId
        } | ConvertTo-Json -Depth 10
        break
    }
}
