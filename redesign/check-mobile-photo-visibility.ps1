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
 $records=@()
 foreach($width in @(320,390,500,768,1440)){
  $null=Cdp 'Emulation.setDeviceMetricsOverride' @{width=$width;height=1000;deviceScaleFactor=1;mobile=$false}
  foreach($file in @('index.html','blog.html','about.html')){
   $null=Cdp 'Page.navigate' @{url=('file:///'+$root.Replace('\','/')+'/'+$file)}
   Start-Sleep -Milliseconds 450
   $r=Cdp 'Runtime.evaluate' @{expression="(()=>{const h=document.querySelector('.home-motion-hero'),cards=[...document.querySelectorAll('.journal-preview')];return {page:document.body.dataset.page,width:innerWidth,overflow:document.documentElement.scrollWidth>innerWidth,arrows:[...document.querySelectorAll('.nav-group>a')].some(a=>getComputedStyle(a,'::after').display!=='none'),licenseVisible:getComputedStyle(document.querySelector('.header-license')).display!=='none',credentialsVisible:!!document.querySelector('.credentials')&&getComputedStyle(document.querySelector('.credentials')).display!=='none',footerCentered:getComputedStyle(document.querySelector('.site-footer')).textAlign==='center',heroTextCoversPhoto:h?h.querySelector('.motion-copy').getBoundingClientRect().top<h.querySelector('img').getBoundingClientRect().bottom-1:null,blogTextCoversPhotos:cards.some(a=>a.querySelector('.journal-preview-caption').getBoundingClientRect().top<a.querySelector('img').getBoundingClientRect().bottom-1),aboutHeadings:[...document.querySelectorAll('.company-values h3')].map(e=>e.textContent),heroColumns:document.querySelector('.image-cards')?getComputedStyle(document.querySelector('.image-cards')).gridTemplateColumns.split(' ').length:null}})()";returnByValue=$true}
   $records+=$r.result.value
   if($width -eq 390 -and $file -ne 'about.html'){$shot=Cdp 'Page.captureScreenshot' @{format='png';captureBeyondViewport=$true};[IO.File]::WriteAllBytes((Join-Path $PSScriptRoot "reference/$file-mobile-clear-photos.png"),[Convert]::FromBase64String($shot.data))}
  }
 }
 $records|ConvertTo-Json -Depth 6|Set-Content "$PSScriptRoot/mobile-photo-visibility.json"
 $records|ConvertTo-Json -Depth 6 -Compress|Write-Output
}finally{if($socket.State -eq [Net.WebSockets.WebSocketState]::Open){try{$null=Cdp 'Browser.close' @{}}catch{}};$socket.Dispose()}