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
 foreach($size in @(@{tag='desktop';width=1440;height=1000},@{tag='tablet';width=768;height=1024},@{tag='ide-preview';width=730;height=540},@{tag='mobile';width=390;height=844})){
  $name='index';$tag='home-fix-'+$size.tag
  $null=Cdp 'Emulation.setDeviceMetricsOverride' @{width=$size.width;height=$size.height;deviceScaleFactor=1;mobile=$false}
  $file=if($name -eq 'home'){'index.html'}else{$name+'.html'};$url='file:///'+$root.Replace('\','/')+'/'+$file
  $null=Cdp 'Page.navigate' @{url=$url}
  for($attempt=0;$attempt -lt 80;$attempt++){Start-Sleep -Milliseconds 250;$state=Cdp 'Runtime.evaluate' @{expression="document.readyState==='complete' && document.body.dataset.page==='$file' && !!window.PARADIGM_READY";returnByValue=$true};if($state.result.value){break}}
  $null=Cdp 'Runtime.evaluate' @{expression="document.querySelectorAll('img').forEach(i=>i.loading='eager')";returnByValue=$true}
  Start-Sleep -Milliseconds 1000
  $checks=Cdp 'Runtime.evaluate' @{expression="JSON.stringify({width:innerWidth,overflow:document.documentElement.scrollWidth>innerWidth,serviceTabs:(()=>{const tabs=[...document.querySelectorAll('[role=tab]')];let valid=tabs.length===4;tabs.forEach(t=>{t.click();valid=valid&&document.querySelectorAll('.service-panel:not([hidden])').length===1&&!document.getElementById(t.getAttribute('aria-controls')).hidden});tabs[0].click();tabs[0].dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowRight',bubbles:true}));valid=valid&&tabs[1].getAttribute('aria-selected')==='true';tabs[0].click();return valid})(),failedImages:[...document.images].filter(i=>!i.naturalWidth).map(i=>i.src)})";returnByValue=$true};Write-Output $checks.result.value
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