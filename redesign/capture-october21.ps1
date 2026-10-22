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
 foreach($name in @('home','blog','blog-company-holiday-party-security-risks','blog-holiday-shopping-parking-lot-security','blog-construction-site-theft-holiday-shutdowns','los-angeles-county-security','san-bernardino-county-security')){
  $tag=$name.Replace('/','-')
  $null=Cdp 'Emulation.setDeviceMetricsOverride' @{width=1440;height=1000;deviceScaleFactor=1;mobile=$false}
  $file=if($name -eq 'home'){'index.html'}else{$name+'.html'};$url='file:///'+$root.Replace('\','/')+'/'+$file
  $null=Cdp 'Page.navigate' @{url=$url}
  for($attempt=0;$attempt -lt 80;$attempt++){Start-Sleep -Milliseconds 250;$state=Cdp 'Runtime.evaluate' @{expression="document.readyState==='complete' && document.body.dataset.page==='$file' && !!window.PARADIGM_READY";returnByValue=$true};if($state.result.value){break}}
  $null=Cdp 'Runtime.evaluate' @{expression="document.querySelectorAll('img').forEach(i=>i.loading='eager')";returnByValue=$true}
  Start-Sleep -Milliseconds 1000
  $shot=Cdp 'Page.captureScreenshot' @{format='png';captureBeyondViewport=$true}
  [IO.File]::WriteAllBytes((Join-Path $PSScriptRoot "reference/$tag-interior.png"),[Convert]::FromBase64String($shot.data))
  $state=Cdp 'Runtime.evaluate' @{expression="JSON.stringify({title:document.title,fonts:[...document.querySelectorAll('h1,h2,p,nav')].slice(0,30).map(e=>({tag:e.tagName,text:e.textContent.trim().slice(0,80),font:getComputedStyle(e).fontFamily,size:getComputedStyle(e).fontSize,color:getComputedStyle(e).color})),bodyClass:document.body.className})";returnByValue=$true}
  [IO.File]::WriteAllText((Join-Path $PSScriptRoot "reference/$tag-interior-design.json"),$state.result.value)
  Write-Output ("Captured live "+$name)
 }
}finally{
 if($socket.State -eq [Net.WebSockets.WebSocketState]::Open){try{$null=Cdp 'Browser.close' @{}}catch{}}
 $socket.Dispose()
}