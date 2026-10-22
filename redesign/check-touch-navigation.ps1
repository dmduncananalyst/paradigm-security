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
 foreach($size in @(@{width=320;touch=$true},@{width=390;touch=$true},@{width=600;touch=$true},@{width=730;touch=$true},@{width=768;touch=$true},@{width=820;touch=$true},@{width=1024;touch=$true},@{width=1180;touch=$true},@{width=1366;touch=$true})){
  $null=Cdp 'Emulation.setDeviceMetricsOverride' @{width=$size.width;height=1000;deviceScaleFactor=1;mobile=$false}
  $null=Cdp 'Emulation.setTouchEmulationEnabled' @{enabled=$size.touch;maxTouchPoints=5}
  $null=Cdp 'Page.navigate' @{url=('file:///'+$root.Replace('\','/')+'/index.html')}
  Start-Sleep -Milliseconds 500
  $r=Cdp 'Runtime.evaluate' @{expression="(async()=>{const wait=ms=>new Promise(r=>setTimeout(r,ms));const nav=document.querySelector('#navigation'),links=[...document.querySelectorAll('.nav-group>a')];let result={width:innerWidth,touch:matchMedia('(pointer:coarse)').matches,navVisible:getComputedStyle(nav).display!=='none',menuButtons:document.querySelectorAll('.mobile-toggle,.sub-toggle').length,columns:getComputedStyle(document.querySelector('.image-cards')).gridTemplateColumns.split(' ').length,overflow:document.documentElement.scrollWidth>innerWidth,dropdowns:[]};for(const a of links){a.dispatchEvent(new MouseEvent('click',{bubbles:true,cancelable:true}));await wait(600);const drop=a.nextElementSibling;result.dropdowns.push({label:a.textContent,open:getComputedStyle(drop).display!=='none',expanded:a.getAttribute('aria-expanded'),links:drop.querySelectorAll('a').length});a.dispatchEvent(new MouseEvent('click',{bubbles:true,cancelable:true}))}return result})()";returnByValue=$true;awaitPromise=$true}
  $r.result.value|ConvertTo-Json -Depth 5|Set-Content "$PSScriptRoot/navigation-$($size.width)-touch-$($size.touch).json"
  if($size.width -in @(390,730,768,1024)){$shot=Cdp 'Page.captureScreenshot' @{format='png';captureBeyondViewport=$false};[IO.File]::WriteAllBytes((Join-Path $PSScriptRoot "reference/navigation-$($size.width).png"),[Convert]::FromBase64String($shot.data))}
  Write-Output ($r.result.value|ConvertTo-Json -Depth 5 -Compress)
 }
}finally{if($socket.State -eq [Net.WebSockets.WebSocketState]::Open){try{$null=Cdp 'Browser.close' @{}}catch{}};$socket.Dispose()}