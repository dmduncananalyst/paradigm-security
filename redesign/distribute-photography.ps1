$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$files=@(Get-ChildItem -LiteralPath (Join-Path $root 'assets/paradigm_all_photos_ONE_ZIP (2)/generated_photos') -Filter '*.jpg')+@(Get-ChildItem -LiteralPath (Join-Path $root 'assets/client-photos') -File)
Add-Type -AssemblyName System.Drawing
$canonical=@{};$byPath=@{};$sourceCopies=@()
foreach($f in $files){$hash=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash;$im=[Drawing.Image]::FromFile($f.FullName);$ratio=$im.Width/$im.Height;$im.Dispose();$record=[pscustomobject]@{path=$f.FullName;hash=$hash;name=$f.Name;ratio=$ratio};$byPath[$f.FullName]=$record;if(!$canonical.ContainsKey($hash)){$canonical[$hash]=$record}else{$sourceCopies+=$f.Name}}
$used=New-Object 'Collections.Generic.HashSet[string]'
$reserved=@{}
foreach($name in @('unarmed_security_guard_converses_with_property_man.jpg','unarmed_security_in_a_busy_office_courtyard.jpg')){$reserved[$name]='services/unarmed-security.html'}
foreach($name in @('bicycle_patrol_reports_property_observation.jpg','corporate_security_bike_patrol.jpg','pedestrian_corridor_bicycle_patrol.jpg','vigilant_security_officer_with_bicycle.jpg')){$reserved[$name]='services/asset-protection/vehicle-bike-patrol.html'}
foreach($name in @('handler_and_labrador_inspect_cargo_cases.jpg','handler_and_manager_discuss_k9_observation.jpg','k9_handler_and_shepherd_at_warehouse.jpg','professional_k9_detection_in_warehouse.jpg')){$reserved[$name]='services/asset-protection/k9-narcotic-detection.html'}
function Select-Photo($context,$desiredRatio=0){$tokens=($context.ToLowerInvariant() -split '\W+')|Where-Object {$_.Length -gt 3 -and $_ -notin @('security','services','html','protection')};$ranked=foreach($record in $canonical.Values){if($used.Contains($record.hash) -or $reserved.ContainsKey($record.name)){continue};if($desiredRatio -and [Math]::Abs($record.ratio-$desiredRatio) -gt 0.015){continue};$score=0;foreach($token in $tokens){if($record.name -match [regex]::Escape($token)){$score+=20}};[pscustomobject]@{record=$record;score=$score}};return ($ranked|Sort-Object @{Expression='score';Descending=$true},@{Expression={$_.record.name}}|Select-Object -First 1).record}
$pages=@(Get-ChildItem $root -Recurse -Filter '*.html'|Where-Object FullName -NotMatch '\\redesign\\'|Sort-Object @{Expression={if([IO.File]::ReadAllText($_.FullName) -match 'class=''image-card'){0}else{1}}},FullName)
$changes=@()
foreach($page in $pages){$html=Get-Content $page.FullName -Raw -Encoding UTF8;$context=[regex]::Match($html,'<title>(.*?)</title>').Groups[1].Value
 $html=[regex]::Replace($html,'(?is)<img\b[^>]*src=(["''])(.*?)\1[^>]*>',[Text.RegularExpressions.MatchEvaluator]{param($match)
  $src=[Net.WebUtility]::HtmlDecode($match.Groups[2].Value);$path=[IO.Path]::GetFullPath((Join-Path $page.DirectoryName $src));if(!$byPath.ContainsKey($path)){return $match.Value};$record=$byPath[$path]
    $before=$html.Substring(0,$match.Index);$isCard=$before -match '(?s)<a class=''image-card[^>]*>\s*$';$desiredRatio=if($isCard){if($page.Name -in @('index.html','los-angeles-county-security.html','san-bernardino-county-security.html')){16/9}else{1.5}}else{0}
  if((!$reserved.ContainsKey($record.name) -or $reserved[$record.name] -eq $page.FullName.Substring($root.Length+1).Replace('\','/')) -and (!$desiredRatio -or [Math]::Abs($record.ratio-$desiredRatio) -le 0.015) -and $used.Add($record.hash)){return $match.Value}
  $searchContext=$context+' '+$record.name.Replace('_',' ')
  $replacement=Select-Photo $searchContext $desiredRatio
  if(!$replacement){throw ('No unique replacement photograph remains for '+$page.Name)}
  [void]$used.Add($replacement.hash)
  $prefix='../'*(($page.FullName.Substring($root.Length+1).Split('\')).Count-1);$newSrc=$prefix+$replacement.path.Substring($root.Length+1).Replace('\','/');return $match.Value.Replace($match.Groups[2].Value,[Net.WebUtility]::HtmlEncode($newSrc))
 })
 [IO.File]::WriteAllText($page.FullName,$html,(New-Object Text.UTF8Encoding $false))
}
$galleries=@{}
foreach($record in @($canonical.Values|Sort-Object name)){
 if($used.Contains($record.hash)){continue}
 $page=if($reserved.ContainsKey($record.name)){$reserved[$record.name]}else{switch -Regex($record.name){
  'collage|montage|multi_panel|tiled_grid' {'security.html';break}
  'hospital|medical|clinic' {'protection/hospitals-medical-facilities.html';break}
  'construction|warehouse|loading|equipment' {'protection/construction-sites.html';break}
  'estate|home|residen' {'protection/private-homes-estates.html';break}
  'school|campus' {'protection/schools.html';break}
  'film|production|studio' {'protection/film-production-sites.html';break}
  'gala|event|guest' {'protection/events.html';break}
  'retail|store|mall|shopping|boutique|promenade' {'services/asset-protection/loss-prevention.html';break}
  'dispens|cannabis' {'services/asset-protection/cannabis-dispensaries.html';break}
  'bank|atm|cash|case|shipment|transfer' {'protection/banks.html';break}
  'k9|handler|labrador|shepherd' {'services/asset-protection/k9-narcotic-detection.html';break}
  'bike|bicycle' {'services/asset-protection/vehicle-bike-patrol.html';break}
  'executive|personal|plainclothes|escort' {'protection/individuals-executives.html';break}
  'apartment|courtyard' {'protection/apartments.html';break}
  'office|corporate|business|lobby' {'protection/office-buildings.html';break}
  default {'security.html'}
 }}
 if(!$galleries.ContainsKey($page)){$galleries[$page]=@()};$galleries[$page]+=$record;[void]$used.Add($record.hash)
}
foreach($page in $galleries.Keys){
 $target=Join-Path $root $page;$prefix='../'*(($page.Split('/')).Count-1)
 $html=Get-Content $target -Raw -Encoding UTF8
 $paragraphs=@([regex]::Matches($html,'(?is)<div class=''service-board''>.*?(?=<section class=''page-action''>|</main>)') | ForEach-Object {[regex]::Matches($_.Value,'(?is)<p\b[^>]*>(.*?)</p>')} | ForEach-Object {$_.Value})
 $pictures=@();$index=0
 foreach($record in $galleries[$page]){
  $src=[Net.WebUtility]::HtmlEncode($prefix+$record.path.Substring($root.Length+1).Replace('\','/'))
  $pictures+="<img src='$src' alt='Security coverage at the property' loading='lazy'>";$index++
 }
 if(!$paragraphs.Count){
  $paragraphs=@('<p>Security begins with understanding the property: who uses it, how people arrive, and which areas require attention.</p>','<p>Access coverage brings visitor arrivals, deliveries, and the site contact into the same plan. Responsibilities are agreed before an assignment begins.</p>','<p>Patrol planning considers shared spaces, parking areas, entrances, and the hours when the property is occupied or closed.</p>','<p>Clear communication helps connect the officer on site with the person responsible for the property. Reporting expectations form part of the service plan.</p>','<p>Different settings call for different assignments. Tell Paradigm about the location, schedule, and type of support you need.</p>')
  $html=$html.Replace("<div class='service-board'></div>","<div class='service-board'>$(($paragraphs)-join '')</div>")
 }
 $groups=[Math]::Min($paragraphs.Count,$pictures.Count)
 for($i=0;$i -lt $groups;$i++){
  $groupPictures=for($j=$i;$j -lt $pictures.Count;$j+=$groups){$pictures[$j]}
  $copy=$paragraphs[$i];$position=$html.IndexOf($copy)
  $story="<div class='coverage-story'><figure>$(($groupPictures)-join '')</figure><div>$copy</div></div>"
  if($position -ge 0){$html=$html.Remove($position,$copy.Length).Insert($position,$story)}
 }
 [IO.File]::WriteAllText($target,$html,(New-Object Text.UTF8Encoding $false))
}
$report=@{uniqueAvailable=$canonical.Count;uniqueUsed=$used.Count;unused=@($canonical.Keys|Where-Object {!$used.Contains($_)});identicalSourceCopies=$sourceCopies;supplementalPages=@($galleries.Keys)}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'photo-usage.json'),($report|ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding $false))
Write-Output ('Photographs assigned: '+$used.Count+' unique images; '+$sourceCopies.Count+' identical source copy excluded.')
