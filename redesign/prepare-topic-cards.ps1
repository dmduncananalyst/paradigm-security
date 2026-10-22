$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Add-Type -AssemblyName System.Drawing
$pages=Get-Content "$PSScriptRoot/rebuild-content.json" -Raw -Encoding UTF8|ConvertFrom-Json
$used=New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach($file in @('page-photography.json','directory-photography.json','safety-photography.json')){
 $map=Get-Content "$PSScriptRoot/$file" -Raw -Encoding UTF8|ConvertFrom-Json
 foreach($entry in $map.PSObject.Properties){if($file -eq 'page-photography.json' -and $entry.Name -like 'articles/topics/*'){continue};[void]$used.Add($entry.Value)}
}
foreach($name in @('private_security_at_palm_lined_shopping_plaza.jpg','security_officer_reviews_warehouse_inventory.jpg','upscale_retail_security_check_in.jpg','bicycle_patrol_reports_property_observation.jpg','secure_dispensary_shipment_handoff.jpg','private_security_in_a_cannabis_dispensary.jpg','k9_patrol_in_an_empty_event_foyer.jpg','private_security_at_store_entry.jpg')){[void]$used.Add($name)}
$photos=@(Get-ChildItem -LiteralPath (Join-Path $root 'assets/paradigm_all_photos_ONE_ZIP (2)/generated_photos') -Filter '*.jpg' | Where-Object {!$used.Contains($_.Name)} | ForEach-Object {$im=[Drawing.Image]::FromFile($_.FullName);$ratio=$im.Width/$im.Height;$im.Dispose();[pscustomobject]@{name=$_.Name;ratio=$ratio}})
$groups=@{'apartments-residential'='apartment|residen|lobby|community';'banking-transport-cannabis'='bank|cash|transport|dispens|shipment|atm|case';'construction-warehouse'='construction|warehouse|loading|equipment|site|gate';'events-production'='event|gala|film|production|studio|guest';'homes-estates'='estate|home|residen|gate';'hospitals-medical'='medical|hospital|clinic|reception|lobby';'personal-protection'='executive|personal|plainclothes|client|discreet';'police-private-security'='guard|officer|report|patrol|entrance';'retail-shopping-center'='retail|store|shopping|mall|promenade';'schools-campus'='school|campus|visitor';'security-authority-rights'='report|officer|tablet|consultation';'workplace-office'='office|corporate|lobby|business|campus'}
$result=[ordered]@{}
$order=@('hospitals-medical','schools-campus','homes-estates','personal-protection','apartments-residential','banking-transport-cannabis','events-production','construction-warehouse','retail-shopping-center','workplace-office','security-authority-rights','police-private-security')
foreach($page in @($pages|Where-Object path -Like 'articles/topics/*'|Sort-Object {$order.IndexOf([IO.Path]::GetFileNameWithoutExtension($_.path))})){
 $slug=[IO.Path]::GetFileNameWithoutExtension($page.path);$pattern=$groups[$slug];$cards=@()
 foreach($match in [regex]::Matches($page.body,'(?is)<section class=''safety-topic-section''>(.*?)</section>')){
  $html=$match.Groups[1].Value;$title=[regex]::Match($html,'(?is)<h2[^>]*>(.*?)</h2>').Groups[1].Value
  $href=[regex]::Match($html,'(?is)<a[^>]*href=(["''])(.*?)\1').Groups[2].Value
  $tokens=([Net.WebUtility]::HtmlDecode($title) -split '\W+')|Where-Object {$_.Length -gt 4 -and $_ -notin @('security','responsibilities','planning','support','coverage')}
  $ranked=foreach($photo in $photos){
   if($used.Contains($photo.name) -or $photo.name -match 'collage|multi_panel|montage|tiled_grid'){continue}
   if($slug -notmatch 'hospital' -and $photo.name -match 'hospital|clinic|medical'){continue}
   if($slug -notmatch 'banking' -and $photo.name -match 'dispensary|cannabis|atm|bank_'){continue}
   if($slug -notmatch 'schools' -and $photo.name -match 'school_'){continue}
   if($photo.name -match 'handler|labrador|k9|shepherd'){continue}
   if($slug -notmatch 'construction|police|authority' -and $photo.name -match 'warehouse|loading|construction|equipment'){continue}
   if($slug -notmatch 'schools|police|authority' -and $photo.name -match 'bicycle|bike_patrol'){continue}
   $score=0;if($photo.name -match $pattern){$score+=200};foreach($token in $tokens){if($photo.name -match [regex]::Escape($token)){$score+=5}}
   if($photo.ratio -gt 1.25){$score+=15};if([Math]::Abs($photo.ratio-1.5) -lt .025){$score+=20};[pscustomobject]@{photo=$photo.name;score=$score}
  }
  $pick=$ranked|Sort-Object @{Expression='score';Descending=$true},@{Expression='photo';Descending=$false}|Select-Object -First 1
  if(!$pick){throw 'No unused photo remains'};[void]$used.Add($pick.photo)
  if(!$href){throw "Missing link for $title"}
  $cards+=[ordered]@{title=[Net.WebUtility]::HtmlDecode($title);href=$href;image=$pick.photo}
 }
 $result[$page.path]=$cards
}
$json=$result|ConvertTo-Json -Depth 7
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'topic-cards.json'),$json,(New-Object Text.UTF8Encoding $false))
Write-Output ('Prepared '+(@($result.Values|ForEach-Object {$_}).Count)+' topic cards.')
