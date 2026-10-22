$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$approved=Get-Content "$PSScriptRoot/approved-photography.json" -Raw -Encoding UTF8|ConvertFrom-Json
$byPath=@{};foreach($photo in $approved){$byPath[$photo.path]=$photo}
$used=New-Object 'Collections.Generic.HashSet[string]'
$assignment=@{}
$preferred=@{
 'services/armed-security.html'='a_crisp_cinematic_realistic_outdoor_scene_at_the.jpg'
 'services/unarmed-security.html'='article-unarmed-business-closing.webp'
 'services/asset-protection/vehicle-bike-patrol.html'='bikesecurity.webp'
 'services/asset-protection.html'='security_officer_reviews_warehouse_inventory.jpg'
 'services/asset-protection/cannabis-dispensaries.html'='upscale_dispensary_security_scene.jpg'
 'services/asset-protection/loss-prevention.html'='mall_security_patrol_on_a_sunny_day.jpg'
 'protection/apartments.html'='luxury_estate_security_patrol.jpg'
 'protection/construction-sites.html'='a_crisp_realistic_high_resolution_photo_of_a_mod.jpg'
 'protection/events.html'='gala_entrance_security_check.jpg'
 'protection/film-production-sites.html'='guarding_the_film_set_perimeter.jpg'
 'protection/hospitals-medical-facilities.html'='friendly_security_guidance_at_the_clinic_reception.jpg'
 'protection/schools.html'='friendly_campus_entrance_conversation.jpg'
 'protection/banks.html'='guidance_at_the_modern_atm.jpg'
 'protection/private-homes-estates.html'='twilight_estate_security.jpg'
 'protection/individuals-executives.html'='executive_arrival_with_discreet_close_protection.jpg'
 'protection/office-buildings.html'='discreet_security_in_a_modern_business_foyer.jpg'
 'contact.html'='welcoming_security_guidance_in_modern_lobby.jpg'
}
function Select-Approved($page,$context,$extra=$false){
 $isK9=$page -match 'k9|narcotic'
 $isPatrol=$page -match 'vehicle-bike'
 $candidates=@($approved|Where-Object {
  !$used.Contains($_.path) -and
  (!$_.owner -or $_.owner -eq $page) -and
  (!$_.dog -or $isK9) -and
  ((!$_.bike -and $_.tags -notmatch 'bike|bicycle') -or $isPatrol) -and
  ($_.ratio -and [Math]::Abs($_.ratio-1.5) -lt 0.005)
 })
 if($isK9){$candidates=@($candidates|Where-Object dog)}
 if($page -eq 'services/armed-security.html'){$candidates=@($candidates|Where-Object armed)}
 elseif($page -eq 'services/unarmed-security.html'){$candidates=@($candidates|Where-Object unarmedSafe)}
 else{$candidates=@($candidates|Where-Object {!$_.armed -or $_.owner -eq $page})}
 if($page -match 'vehicle-bike'){$candidates=@($candidates|Where-Object {$_.tags -match 'bike|bicycle'})}
 $subject=switch -Regex($page){
  'hospit|medical|clinic' {'hospit|medical|clinic';break}
  'school|campus' {'school|campus';break}
  'construction|warehouse' {'construction|warehouse|loading';break}
  'apartment|residen|homes|estate' {'estate|residen|apartment';break}
  'cannabis|dispens' {'cannabis|dispens';break}
  'bank|cash|transport' {'bank|atm|cash|cargo|shipment';break}
  'events|production|film' {'event|gala|film|production';break}
  'retail|shopping|mall|loss-prevention' {'retail|shopping|mall|boutique|store';break}
  'executive|personal|individuals' {'executive|vip|suit|close protection';break}
  'office|workplace' {'office|business|corporate|lobby';break}
  default {''}
 }
 if($subject){$candidates=@($candidates|Where-Object {$_.owner -eq $page -or $_.tags -match $subject})}
 $exact=@($candidates|Where-Object {$_.owner -eq $page -and !$_.supportOnly})
 if($exact.Count -and !$extra){$choice=$exact[0];[void]$used.Add($choice.path);return $choice}
 $wanted=$preferred[$page]
 if($wanted -and !$extra){$choice=$candidates|Where-Object {($_.path.Split('/')[-1]) -eq $wanted}|Select-Object -First 1;if($choice){[void]$used.Add($choice.path);return $choice}}
 $tokens=($page+' '+$context).ToLowerInvariant() -split '\W+'|Where-Object {$_ -notin @('security','services','protection','articles','topics','html','assets','page') -and $_.Length -gt 3}
 $ranked=foreach($photo in $candidates){$score=0;foreach($token in $tokens){if($photo.tags -match [regex]::Escape($token)){$score+=10}};[pscustomobject]@{photo=$photo;score=$score}}
 $choice=$ranked|Sort-Object @{Expression='score';Descending=$true},@{Expression={$_.photo.path}}|Select-Object -First 1
 if(!$choice -or ($extra -and $choice.score -eq 0)){return $null}
 [void]$used.Add($choice.photo.path);return $choice.photo
}
$pages=@(Get-ChildItem $root -Recurse -Filter '*.html'|Where-Object FullName -NotMatch '\\redesign\\')
# Reserve accurate service pictures before allocating article and city illustrations.
$ordered=@($pages|Sort-Object @{Expression={if($_.FullName -match '\\services\\'){0}elseif($_.FullName -match '\\protection\\'){1}else{2}}},FullName)
foreach($file in $ordered){
 $page=$file.FullName.Substring($root.Length+1).Replace('\','/')
 if($page -like 'blog-*.html'){continue}
 if($page -in @('index.html','about.html','blog.html','404.html','services.html','protection.html','safety.html','los-angeles-county-security.html','san-bernardino-county-security.html')){continue}
 $html=Get-Content $file.FullName -Raw -Encoding UTF8
 $assignment[$page]=Select-Approved $page ([regex]::Match($html,'<title>(.*?)</title>').Groups[1].Value)
}
function Relative-Photo($page,$photo){('../'*(($page.Split('/')).Count-1))+$photo.path}
$report=@()
foreach($file in $pages){
 $page=$file.FullName.Substring($root.Length+1).Replace('\','/')
 if($page -like 'blog-*.html'){continue}
 $html=Get-Content $file.FullName -Raw -Encoding UTF8
 # Cards and destination heroes use the same approved picture. No replacement images are appended.
 $html=[regex]::Replace($html,'(?is)<a class=''image-card[^'']*''[^>]*href=''([^'']+)''[^>]*>.*?</a>',[Text.RegularExpressions.MatchEvaluator]{param($m)
  $target=[IO.Path]::GetFullPath((Join-Path $file.DirectoryName ([Net.WebUtility]::HtmlDecode($m.Groups[1].Value))))
  $key=$target.Substring($root.Length+1).Replace('\','/')
  $photo=$assignment[$key]
  $clean=[regex]::Replace($m.Value,'(?is)<img\b[^>]*>','')
  if(!$photo){return $clean}
  $image="<img src='$([Net.WebUtility]::HtmlEncode((Relative-Photo $page $photo)))' alt='$([Net.WebUtility]::HtmlEncode($photo.tags))' loading='lazy'>"
  $end=$clean.IndexOf('>')+1;return $clean.Insert($end,$image)
 })
 if($page -ne 'about.html'){
  $photo=$assignment[$page]
  $html=[regex]::Replace($html,'(?is)<figure class=''feature-photo[^'']*''>.*?</figure>',[Text.RegularExpressions.MatchEvaluator]{param($m)
   if(!$photo){return ''}
   return "<figure class='feature-photo'><img src='$([Net.WebUtility]::HtmlEncode((Relative-Photo $page $photo)))' alt='$([Net.WebUtility]::HtmlEncode($photo.tags))' fetchpriority='high'></figure>"
  })
  if($photo -and $html -match 'class=''assignment-introduction'''){
   $html=[regex]::Replace($html,'(?is)<div class=''assignment-introduction''>(.*?)</div>',[Text.RegularExpressions.MatchEvaluator]{param($m)
    $image="<figure><img src='$([Net.WebUtility]::HtmlEncode((Relative-Photo $page $photo)))' alt='$([Net.WebUtility]::HtmlEncode($photo.tags))' loading='lazy'></figure>"
    return "<div class='assignment-introduction coverage-story'>$image<div>$($m.Groups[1].Value)</div></div>"
   })
  }
  if($page -eq 'employment.html'){
   $html=[regex]::Replace($html,'(?is)(<section class=''careers-layout.*?)(<img\b[^>]*>)(</section>)',[Text.RegularExpressions.MatchEvaluator]{param($m)
    $image=if($photo){"<img src='$([Net.WebUtility]::HtmlEncode((Relative-Photo $page $photo)))' alt='Security professional in a marked uniform'>"}else{''};$m.Groups[1].Value+$image+$m.Groups[3].Value
   })
  }
 }
 # Only one supporting picture per existing section with real copy; never add a photo-only section.
 if($page -like 'services/*' -or $page -like 'protection/*'){
  $chapterCount=0
  $html=[regex]::Replace($html,'(?is)<section class="v5-chapter"><div>(.*?)</div></section>',[Text.RegularExpressions.MatchEvaluator]{param($m)
   if($chapterCount -ge 2 -or $m.Groups[1].Value -notmatch '<p\b'){return $m.Value}
   $context=[Net.WebUtility]::HtmlDecode([regex]::Replace($m.Groups[1].Value,'<[^>]+>',' '))
   $support=Select-Approved $page $context $true
   if(!$support){return $m.Value}
   $chapterCount++
   $image="<figure><img src='$([Net.WebUtility]::HtmlEncode((Relative-Photo $page $support)))' alt='$([Net.WebUtility]::HtmlEncode($support.tags))' loading='lazy'></figure>"
   return "<section class='v5-chapter'><div class='coverage-story'>$image<div>$($m.Groups[1].Value)</div></div></section>"
  })
 }
 [IO.File]::WriteAllText($file.FullName,$html,(New-Object Text.UTF8Encoding $false))
 $report+=@{page=$page;primary=if($assignment[$page]){$assignment[$page].path}else{$null}}
}
@{policy='Visible SECURITY on uniform or guard wearing suit; About photograph exempt. No unreviewed photos, no dogs outside K9; no filler galleries.';approved=$approved.Count;used=$used.Count;pages=$report}|ConvertTo-Json -Depth 6|Set-Content "$PSScriptRoot/photo-policy-report.json" -Encoding UTF8
Write-Output "Applied reviewed photo policy: $($approved.Count) approved candidates, $($used.Count) assigned."
