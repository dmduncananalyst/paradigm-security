$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$target=Join-Path $root 'assets/reference'
New-Item -ItemType Directory -Force $target|Out-Null
$urls=@()
foreach($name in @('home','about','contact')){
 $s=Get-Content (Join-Path $PSScriptRoot "reference/$name.html") -Raw -Encoding UTF8
 foreach($m in [regex]::Matches($s,'<link[^>]+rel="stylesheet"[^>]+href="([^"]+)"')){$urls+=[Net.WebUtility]::HtmlDecode($m.Groups[1].Value)}
 foreach($m in [regex]::Matches($s,'(?:https:)?//images\.squarespace-cdn\.com/[^\s"''<>\\]+')){$u=[Net.WebUtility]::HtmlDecode($m.Value);$u=$u -replace '[),;]+$','';if($u.StartsWith('//')){$u='https:'+$u};$urls+=($u -split '\?')[0]}
}
$urls=@($urls|Sort-Object -Unique)
$entries=@();$jobs=@();$n=0
foreach($url in $urls){
 $n++;$ext=if($url -match '(?i)\.css(?:\?|$)'){'.css'}elseif($url -match '(?i)\.(jpg|jpeg|png|webp|svg)(?:\?|$)'){$matches[1];'.'+$matches[1]}else{'.img'}
 if($ext -is [array]){$ext=$ext[-1]}
 $file="asset-$n$ext";$out=Join-Path $target $file
 $entries+=@{url=$url;path="assets/reference/$file"}
 if(!(Test-Path -LiteralPath $out)){
  $jobs+=Start-Job -ScriptBlock {param($u,$p)try{Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 45 -OutFile $p;[pscustomobject]@{url=$u;ok=$true}}catch{[pscustomobject]@{url=$u;ok=$false;message=$_.Exception.Message}}} -ArgumentList $url,$out
 }
}
$entries|ConvertTo-Json -Depth 5|Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot 'reference/assets.json')
if($jobs.Count){$jobs|Wait-Job|Receive-Job|ForEach-Object {if(!$_.ok){Write-Output ("FAILED: "+$_.url+' '+$_.message)}};$jobs|Remove-Job}
Write-Output "Reference assets: $($entries.Count)"
