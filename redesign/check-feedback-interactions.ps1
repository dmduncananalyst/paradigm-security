$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$profile=Join-Path $PSScriptRoot 'interior-browser'
$browser=Start-Process -FilePath 'C:\Program Files\Google\Chrome\Application\chrome.exe' -WindowStyle Hidden -PassThru -ArgumentList @('--headless','--disable-gpu','--no-first-run','--allow-file-access-from-files','--remote-debugging-port=9240',('--user-data-dir="'+$profile+'"'),'about:blank')
$socket=New-Object Net.WebSockets.ClientWebSocket
try{
 $target=$null;for($attempt=0;$attempt -lt 50;$attempt++){try{$target=Invoke-RestMethod 'http://127.0.0.1:9240/json';break}catch{Start-Sleep -Milliseconds 100}}
 $page=$target|Where-Object type -EQ 'page'|Select-Object -First 1
 $socket.ConnectAsync([Uri]$page.webSocketDebuggerUrl,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
 $script:sequence=0
 function Cdp($method,$parameters){
  $script:sequence++;$id=$script:sequence
  $payload=@{id=$id;method=$method;params=$parameters}|ConvertTo-Json -Depth 20 -Compress
  $bytes=[Text.Encoding]::UTF8.GetBytes($payload)
  $socket.SendAsync([ArraySegment[byte]]::new($bytes),[Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
  while($true){$buffer=New-Object byte[] 1048576;$stream=New-Object IO.MemoryStream;do{$received=$socket.ReceiveAsync([ArraySegment[byte]]::new($buffer),[Threading.CancellationToken]::None).GetAwaiter().GetResult();$stream.Write($buffer,0,$received.Count)}while(!$received.EndOfMessage);$message=[Text.Encoding]::UTF8.GetString($stream.ToArray())|ConvertFrom-Json;$stream.Dispose();if($message.id -eq $id){if($message.error){throw ($message.error|ConvertTo-Json)};return $message.result}}
 }
 $null=Cdp 'Page.enable' @{}
 $null=Cdp 'Page.navigate' @{url=('file:///'+$root.Replace('\','/')+'/blog.html')}
 Start-Sleep -Seconds 1
 $null=Cdp 'DOM.enable' @{};$null=Cdp 'CSS.enable' @{}
 $doc=Cdp 'DOM.getDocument' @{}
 $node=Cdp 'DOM.querySelector' @{nodeId=$doc.root.nodeId;selector='.journal-preview'}
 $states=@()
 foreach($state in @('hover','active','focus','visited')){
  $null=Cdp 'CSS.forcePseudoState' @{nodeId=$node.nodeId;forcedPseudoClasses=@($state)}
  $r=Cdp 'Runtime.evaluate' @{expression="getComputedStyle(document.querySelector('.journal-read')).color";returnByValue=$true}
  $states+=@{state=$state;color=$r.result.value}
 }
 $states|ConvertTo-Json|Set-Content "$PSScriptRoot/read-article-states.json"
 $null=Cdp 'Page.navigate' @{url=('file:///'+$root.Replace('\','/')+'/services/asset-protection.html')}
 Start-Sleep -Seconds 1
 $r=Cdp 'Runtime.evaluate' @{expression="(async()=>{document.querySelector('[data-open-intake]').click();const d=document.querySelector('#security-intake'),f=d.querySelector('form');for(let i=0;i<20&&!f.hidden;i++){const a=f.elements.answer;a.value=a.inputMode==='tel'?'8185550101':a.inputMode==='email'?'preview@example.com':a.autocomplete==='name'?'Preview Person':'Warehouse inventory, weekday coverage';f.dispatchEvent(new Event('submit',{bubbles:true,cancelable:true}))}return {embeddedForms:d.querySelectorAll('iframe,.hs-form-frame').length,finalQuestion:d.querySelector('[data-intake-log]').lastElementChild.textContent,contactQuestions:d.textContent.includes('email address')&&d.textContent.includes('phone number')}})()";returnByValue=$true;awaitPromise=$true}
 $r.result.value|ConvertTo-Json|Set-Content "$PSScriptRoot/question-chat-preview.json"
 $shot=Cdp 'Page.captureScreenshot' @{format='png';captureBeyondViewport=$false}
 [IO.File]::WriteAllBytes((Join-Path $PSScriptRoot 'reference/question-only-chat.png'),[Convert]::FromBase64String($shot.data))
 Write-Output ($states|ConvertTo-Json -Compress)
}finally{
 if($socket.State -eq [Net.WebSockets.WebSocketState]::Open){try{$null=Cdp 'Browser.close' @{}}catch{}}
 $socket.Dispose()
}