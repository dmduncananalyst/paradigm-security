$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$utf8=New-Object Text.UTF8Encoding $false
$jobs=@(Get-Content "$PSScriptRoot/photo-variety-results.json" -Raw|ConvertFrom-Json|ForEach-Object {$_})+@(Get-Content "$PSScriptRoot/topic-variety-results.json" -Raw|ConvertFrom-Json|ForEach-Object {$_})
$approved=Get-Content "$PSScriptRoot/approved-photography.json" -Raw|ConvertFrom-Json
$report=Get-Content "$PSScriptRoot/photo-policy-report.json" -Raw|ConvertFrom-Json
$replace=@{}
foreach($job in $jobs){
 $newPath='assets/approved-generated/'+$job.key+'-v3.jpg'
 if(!(Test-Path (Join-Path $root $newPath))){throw "Missing reviewed photograph $newPath"}
 if($job.owner -eq 'index.html'){continue}
 $record=$report.pages|Where-Object page -EQ $job.owner|Select-Object -First 1
 if($record -and $record.primary -and $record.primary -ne $newPath){$replace[$record.primary]=$newPath;$record.primary=$newPath}
 foreach($old in @($approved|Where-Object {$_.owner -eq $job.owner -and $_.path -ne $newPath})){if(!$old.PSObject.Properties['supportOnly']){$old|Add-Member supportOnly $true}else{$old.supportOnly=$true}}
 if($newPath -notin $approved.path){$approved+= [pscustomobject]@{path=$newPath;owner=$job.owner;review='Visually reviewed October 21, varied scene';uniform='SECURITY visible';armed=($job.key -eq 'cash-transport-loading');unarmedSafe=($job.key -ne 'cash-transport-loading');dog=$false;bike=$false;ratio=1.5;tags=$job.scene}}
}
$files=Get-ChildItem $root -Recurse -Filter '*.html'|Where-Object FullName -NotMatch '\\redesign\\'
foreach($file in $files){
 $html=Get-Content $file.FullName -Raw -Encoding UTF8
 foreach($old in $replace.Keys){$html=$html.Replace($old,$replace[$old])}
 # Repeated topic cards can link to the same service. Give those distinct,
 # relevant illustrations rather than repeating that service photo in a row.
 if($file.FullName -match '\\articles\\topics\\'){
  $topic=$file.BaseName
  $seen=New-Object 'Collections.Generic.HashSet[string]'
  $script:lastTopicSource=''
  $alternatives=@('assets/approved-generated/topic-'+$topic+'-v3.jpg')
  if($topic -eq 'construction-warehouse'){$alternatives+='assets/approved-generated/city-upland-v3.jpg'}
  if($topic -in @('police-private-security','security-authority-rights')){$alternatives+=@('assets/approved-generated/topic-workplace-office-v3.jpg','assets/approved-generated/topic-security-authority-rights-v3.jpg','assets/approved-generated/topic-police-private-security-v3.jpg')}
  $html=[regex]::Replace($html,"(?is)<a class='image-card[^']*'[^>]*>.*?</a>",[Text.RegularExpressions.MatchEvaluator]{param($m)
   $img=[regex]::Match($m.Value,"<img[^>]*src='([^']+)'[^>]*>")
   if(!$img.Success){return $m.Value}
   $source=$img.Groups[1].Value
   if($source -ne $script:lastTopicSource){[void]$seen.Add($source);$script:lastTopicSource=$source;return $m.Value}
   $alternative=$alternatives|Where-Object {!$seen.Contains('../../'+$_)}|Select-Object -First 1
   if(!$alternative){throw "No distinct topic illustration for $topic"}
   [void]$seen.Add('../../'+$alternative)
   $script:lastTopicSource='../../'+$alternative
   $alt=[Net.WebUtility]::HtmlEncode(($jobs|Where-Object {('assets/approved-generated/'+$_.key+'-v3.jpg') -eq $alternative}|Select-Object -First 1).scene)
   $replacement="<img src='../../$alternative' alt='$alt' loading='lazy'>"
   return $m.Value.Replace($img.Value,$replacement)
  })
 }
 if($file.Name -eq 'index.html'){
  $html=[regex]::Replace($html,"(?is)(<section class='home-motion-hero'>)<video\b.*?</video>",'$1'+"<img class='home-hero-still' src='assets/approved-generated/home-hero-badge-free-v3.jpg' alt='Security officer watching a Southern California commercial property at twilight' width='1672' height='941' fetchpriority='high'>")
  $html=[regex]::Replace($html,"(?is)<button\b[^>]*data-video-toggle[^>]*>.*?</button>",'')
 }
 [IO.File]::WriteAllText($file.FullName,$html,$utf8)
}
$approved|ConvertTo-Json -Depth 8|Set-Content "$PSScriptRoot/approved-photography.json" -Encoding UTF8
$report|ConvertTo-Json -Depth 8|Set-Content "$PSScriptRoot/photo-policy-report.json" -Encoding UTF8
Write-Output "Applied $($replace.Count) varied photo assignments and replaced the homepage video with a badge-free still."
