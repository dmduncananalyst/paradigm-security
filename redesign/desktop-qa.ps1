$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$profile=Join-Path $PSScriptRoot 'desktop-browser'
$browser=Start-Process -FilePath 'C:\Program Files\Google\Chrome\Application\chrome.exe' -WindowStyle Hidden -PassThru -ArgumentList @('--headless','--disable-gpu','--no-first-run','--allow-file-access-from-files','--remote-debugging-port=9239',('--user-data-dir="'+$profile+'"'),'about:blank')
$socket=New-Object Net.WebSockets.ClientWebSocket
try{
 $target=$null;for($attempt=0;$attempt -lt 50;$attempt++){try{$target=Invoke-RestMethod 'http://127.0.0.1:9239/json';break}catch{Start-Sleep -Milliseconds 100}}
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
 foreach($size in @(@{tag='desktop';width=1440;height=1100})){
  $null=Cdp 'Emulation.setDeviceMetricsOverride' @{width=$size.width;height=$size.height;deviceScaleFactor=1;mobile=$false}
  $url='file:///'+$root.Replace('\','/')+'/redesign/browser-audit.html'
  $null=Cdp 'Page.navigate' @{url=$url}
  $complete=$false;for($attempt=0;$attempt -lt 120;$attempt++){Start-Sleep -Milliseconds 250;$state=Cdp 'Runtime.evaluate' @{expression="document.querySelector('#qa-results')?.textContent || ''";returnByValue=$true};if($state.result.value){$json=$state.result.value;$complete=$true;break}}
  if(!$complete){throw "Audit did not finish for $($size.tag)"}
  [IO.File]::WriteAllText((Join-Path $PSScriptRoot "browser-$($size.tag).json"),$json)
  $result=$json|ConvertFrom-Json
  $bad=@($result.pages|Where-Object {$_.invisibleHomeHeading -or $_.wrongMastheadBackground -or $_.emptyHomeHeading -or $_.stretchedImages.Count -or $_.heroPreservesProportions -eq $false -or $_.heroGap -or $_.heroDoesNotFillSection -or $_.footerOverlap -or $_.overflow -or $_.images.Count -or $_.croppedImages.Count -or $_.scrollingDropdowns -or $_.headingUnderHeader -or $_.navigationWraps -or $_.headerOverflows -or $_.h1 -ne 1})
  Write-Output "$($size.tag): measured width $($result.width), pages $($result.pages.Count), layout/image issues $($bad.Count)"
  if($bad.Count){$bad|Select-Object path,heroBelowFold,footerOverlap,headingUnderHeader,navigationWraps,headerOverflows,croppedImages|Select-Object -First 5|ConvertTo-Json -Depth 5}
  $null=Cdp 'Page.navigate' @{url=('file:///'+$root.Replace('\','/')+'/index.html')}
  Start-Sleep -Milliseconds 600
  if($size.width -ge 768){
   $hover=@()
   foreach($groupIndex in @(0,1)){
    $position=Cdp 'Runtime.evaluate' @{expression="(()=>{const r=document.querySelectorAll('.nav-group > a')[$groupIndex].getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2}})()";returnByValue=$true}
    $null=Cdp 'Input.dispatchMouseEvent' @{type='mouseMoved';x=$position.result.value.x;y=$position.result.value.y}
    $shown=Cdp 'Runtime.evaluate' @{expression="getComputedStyle(document.querySelectorAll('.dropdown')[$groupIndex]).display !== 'none'";returnByValue=$true}
    $hover+=@{category=$groupIndex;opensOnHover=$shown.result.value}
   }
   Write-Output ('Desktop hover checks: '+($hover|ConvertTo-Json -Compress))
   $destination=Cdp 'Runtime.evaluate' @{expression="(()=>{const r=[...document.querySelectorAll('#header .dropdown a')].find(a=>a.href.endsWith('/protection/apartments.html')).getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2}})()";returnByValue=$true}
   for($step=1;$step -le 10;$step++){
    $fraction=$step/10
    $null=Cdp 'Input.dispatchMouseEvent' @{type='mouseMoved';x=($position.result.value.x+($destination.result.value.x-$position.result.value.x)*$fraction);y=($position.result.value.y+($destination.result.value.y-$position.result.value.y)*$fraction)}
    Start-Sleep -Milliseconds 70
   }
   $reachable=Cdp 'Runtime.evaluate' @{expression="(()=>{const a=[...document.querySelectorAll('#header .dropdown a')].find(a=>a.href.endsWith('/protection/apartments.html'));const r=a.getBoundingClientRect();return getComputedStyle(a.parentElement).display!=='none'&&a===document.elementFromPoint(r.x+r.width/2,r.y+r.height/2)})()";returnByValue=$true}
   if(!$reachable.result.value){throw 'Protection menu disappeared while moving to Apartments'}
   $null=Cdp 'Input.dispatchMouseEvent' @{type='mousePressed';x=$destination.result.value.x;y=$destination.result.value.y;button='left';clickCount=1}
   $null=Cdp 'Input.dispatchMouseEvent' @{type='mouseReleased';x=$destination.result.value.x;y=$destination.result.value.y;button='left';clickCount=1}
   $arrived=$false;for($attempt=0;$attempt -lt 40;$attempt++){Start-Sleep -Milliseconds 100;$state=Cdp 'Runtime.evaluate' @{expression="document.body.dataset.page==='protection/apartments.html' && !!window.PARADIGM_READY";returnByValue=$true};if($state.result.value){$arrived=$true;break}}
   if(!$arrived){throw 'Apartments menu click did not navigate'}
   Write-Output 'Protection hover-to-Apartments click: passed'
   $null=Cdp 'Page.navigate' @{url=('file:///'+$root.Replace('\','/')+'/index.html')}
   Start-Sleep -Milliseconds 700
   $null=Cdp 'Input.dispatchMouseEvent' @{type='mouseMoved';x=($size.width-20);y=15}
  }
  if($size.tag -eq 'desktop'){
   $before=Cdp 'Runtime.evaluate' @{expression="getComputedStyle(document.querySelector('.marquee-track')).transform";returnByValue=$true}
   Start-Sleep -Milliseconds 350
   $after=Cdp 'Runtime.evaluate' @{expression="getComputedStyle(document.querySelector('.marquee-track')).transform";returnByValue=$true}
   if($before.result.value -eq $after.result.value){throw 'Homepage service strip is not moving'}
   Write-Output 'Homepage automatic sliding strip: passed'
  }
  $shot=Cdp 'Page.captureScreenshot' @{format='png';captureBeyondViewport=$false}
  [IO.File]::WriteAllBytes((Join-Path $PSScriptRoot "$($size.tag)-current.png"),[Convert]::FromBase64String($shot.data))
 }
}finally{
 if($socket.State -eq [Net.WebSockets.WebSocketState]::Open){try{$null=Cdp 'Browser.close' @{}}catch{}}
 $socket.Dispose()
}
