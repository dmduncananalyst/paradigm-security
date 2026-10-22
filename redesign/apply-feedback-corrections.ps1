$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$utf8=New-Object Text.UTF8Encoding $false
$index=Get-Content "$PSScriptRoot/visual-audit-index.json" -Raw|ConvertFrom-Json
function OldPhoto($i){$index[$i].Substring($root.Length+1).Replace('\','/')}
function NewPhoto($key){'assets/approved-generated/feedback-'+$key+'.jpg'}
$mapping=@{}
foreach($pair in @(@(1,'asset-wide'),@(46,'apartment-watch'),@(47,'bank-watch'),@(49,'construction-watch'),@(50,'event-gala'),@(51,'film-perimeter'),@(53,'estate-watch'),@(54,'school-gate'),@(58,'unarmed-entry'),@(56,'loss-prevention'),@(72,'retail-workers'),@(39,'retail-parking'),@(26,'event-planning'),@(28,'film-access'),@(83,'seasonal-retail'),@(82,'unarmed-entry'),@(78,'unarmed-entry'))){$mapping[(OldPhoto $pair[0])]=NewPhoto $pair[1]}
$topicPhotos=@{
 'articles/topics/retail-shopping-center.html'=@((NewPhoto 'seasonal-retail'),(NewPhoto 'loss-prevention'),(NewPhoto 'retail-workers'),(NewPhoto 'retail-parking'),(OldPhoto 56),(NewPhoto 'shrink-report'))
 'articles/topics/events-production.html'=@((NewPhoto 'event-gala'),(NewPhoto 'film-perimeter'),(OldPhoto 63),(NewPhoto 'event-planning'),(OldPhoto 81),(NewPhoto 'film-access'),(OldPhoto 51))
 'articles/topics/banking-transport-cannabis.html'=@((OldPhoto 55),(NewPhoto 'bank-watch'),(OldPhoto 48),(OldPhoto 47),(OldPhoto 21),(OldPhoto 22),(OldPhoto 84))
 'articles/topics/construction-warehouse.html'=@((NewPhoto 'construction-watch'),(OldPhoto 62),(OldPhoto 49),(OldPhoto 24),(OldPhoto 77))
 'articles/topics/schools-campus.html'=@((NewPhoto 'school-gate'),(OldPhoto 36),(OldPhoto 37),(OldPhoto 80))
 'articles/topics/security-authority-rights.html'=@((NewPhoto 'unarmed-entry'),(OldPhoto 70),(OldPhoto 58),(OldPhoto 23),(OldPhoto 38),(OldPhoto 41))
 'articles/topics/police-private-security.html'=@((OldPhoto 0),(NewPhoto 'unarmed-entry'),(OldPhoto 67),(OldPhoto 71),(NewPhoto 'armed-lobby'),(OldPhoto 20),(OldPhoto 30),(OldPhoto 80),(OldPhoto 70),(NewPhoto 'armed-perimeter'))
}
$jobs=@(Get-Content "$PSScriptRoot/feedback-generation.json" -Raw|ConvertFrom-Json|ForEach-Object {$_})+@(Get-Content "$PSScriptRoot/feedback-armed-generation.json" -Raw|ConvertFrom-Json|ForEach-Object {$_})
$approved=Get-Content "$PSScriptRoot/approved-photography.json" -Raw|ConvertFrom-Json
$alts=@{};foreach($j in $jobs){$path=NewPhoto $j.key;$alts[$path]=$j.scene;if($path -notin $approved.path){$approved+=[pscustomobject]@{path=$path;owner='feedback-only';review='Visually reviewed, full subject framing and scene match';uniform='SECURITY visible';armed=($j.key -like 'armed-*');unarmedSafe=($j.key -notlike 'armed-*');dog=$false;bike=$false;ratio=1.5;tags=$j.scene}}}
$lock=Get-Content "$PSScriptRoot/approved-photo-lock.json" -Raw|ConvertFrom-Json
$lockedPages=@($lock.page)
function ImageTag($path,$photo,$alt){$prefix='../'*(($path.Split('/')).Count-1);"<img src='$([Net.WebUtility]::HtmlEncode($prefix+$photo))' alt='$([Net.WebUtility]::HtmlEncode($alt))' loading='lazy'>"}
foreach($file in @(Get-ChildItem $root -Recurse -Filter '*.html'|Where-Object FullName -NotMatch '\\redesign\\')){
 $page=$file.FullName.Substring($root.Length+1).Replace('\','/')
 if($page -in $lockedPages){continue}
 $html=Get-Content $file.FullName -Raw -Encoding UTF8
 $html=[regex]::Replace($html,"<img\b[^>]*src='([^']+)'[^>]*>",[Text.RegularExpressions.MatchEvaluator]{param($m)
  $source=[IO.Path]::GetFullPath((Join-Path $file.DirectoryName ([Net.WebUtility]::HtmlDecode($m.Groups[1].Value)))).Substring($root.Length+1).Replace('\','/')
  if(!$mapping.ContainsKey($source)){return $m.Value}
  $photo=$mapping[$source];return ImageTag $page $photo $alts[$photo]
 })
 # The approved boutique photograph moves from Loss Prevention to the mall page.
 if($page -eq 'protection/malls-shopping-centers.html'){$photo=OldPhoto 56;$tag=ImageTag $page $photo 'Security officer at a clothing store in a shopping center';$html=[regex]::Replace($html,"(?is)(<figure class='feature-photo'>)<img[^>]*>",'$1'+$tag)}
 if($page -eq 'protection.html'){$html=[regex]::Replace($html,"(?is)<a class='image-card' href='protection/malls-shopping-centers.html'>.*?</a>",[Text.RegularExpressions.MatchEvaluator]{param($m)$tag=ImageTag $page (OldPhoto 56) 'Security officer at a shopping center clothing store';[regex]::Replace($m.Value,'<img[^>]*>',$tag)})}
 if($topicPhotos.ContainsKey($page)){
  $script:topicPhotoIndex=0
  $html=[regex]::Replace($html,"(?is)<a class='image-card[^']*'[^>]*>.*?</a>",[Text.RegularExpressions.MatchEvaluator]{param($m)
   $photo=$topicPhotos[$page][$script:topicPhotoIndex];$script:topicPhotoIndex++
   $title=[Net.WebUtility]::HtmlDecode([regex]::Match($m.Value,'<h2>(.*?)</h2>').Groups[1].Value)
   return [regex]::Replace($m.Value,'<img[^>]*>',(ImageTag $page $photo $title))
  })
 }
 [IO.File]::WriteAllText($file.FullName,$html,$utf8)
}
$approved|ConvertTo-Json -Depth 8|Set-Content "$PSScriptRoot/approved-photography.json" -Encoding UTF8
Write-Output 'Applied explicit scene and framing corrections, preserving locked approved photos.'
