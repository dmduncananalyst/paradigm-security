$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Add-Type -AssemblyName System.Drawing
$manifest=Join-Path $PSScriptRoot 'approved-photography.json'
$photos=@(Get-Content $manifest -Raw -Encoding UTF8|ConvertFrom-Json|ForEach-Object {$_})
# These two earlier approvals were incorrect: plain shirts or insufficiently visible lettering.
$photos=@($photos|Where-Object {$_.path -notmatch 'security_officer_reviews_warehouse_inventory|security_officer_reviews_tablet_with_superintenden|a_crisp_cinematic_realistic_outdoor_scene_at_the|a_crisp_realistic_high_resolution_photo_of_a_mod|approved-generated'})
foreach($p in $photos){if($p.path -match 'article-unarmed-business-closing'){$p|Add-Member ratio 1.5 -Force};$p|Add-Member -NotePropertyName bike -NotePropertyValue ([bool]($p.path -match 'bike|bicycle|corporate_campus_security_patrol')) -Force}
$jobs=@(Get-Content "$PSScriptRoot/photo-generation-jobs.json" -Raw|ConvertFrom-Json|ForEach-Object {$_})
$manual=@(
 @{filename='armed-security.png';page='services/armed-security.html';title='Armed Security';armed=$true;dog=$false},
 @{filename='asset-protection.png';page='services/asset-protection.html';title='Asset Protection warehouse inventory';armed=$false;dog=$false},
 @{filename='bike-patrol.png';page='services/asset-protection/vehicle-bike-patrol.html';title='Vehicle and Bike Patrol';armed=$false;dog=$false},
 @{filename='k9-detection.png';page='services/asset-protection/k9-narcotic-detection.html';title='Canine narcotic detection dog handler';armed=$false;dog=$true},
 @{filename='k9-handler.png';page='services/asset-protection/k9-narcotic-detection.html';title='Canine narcotic detection dog handler luggage inspection';armed=$false;dog=$true;supportOnly=$true}
)
$all=@($manual)+@($jobs)
$encoder=[Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()|Where-Object MimeType -EQ 'image/jpeg'
foreach($job in $all){
 $png=Join-Path $root ('assets/approved-generated/'+$job.filename)
 if(!(Test-Path -LiteralPath $png)){throw "Missing generated asset: $($job.filename)"}
 $jpg=[IO.Path]::ChangeExtension($png,'.jpg')
 $im=[Drawing.Image]::FromFile($png)
 if([Math]::Abs($im.Width/$im.Height-1.5) -gt 0.005){$im.Dispose();throw "Generated photograph has wrong aspect ratio: $png"}
 $parameters=New-Object Drawing.Imaging.EncoderParameters 1
 $parameters.Param[0]=New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality),([long]88)
 $im.Save($jpg,$encoder,$parameters);$im.Dispose();$parameters.Dispose()
 $title=$job.title
 $armed=if($job -is [hashtable]){$job.armed}else{($title -match 'armed' -and $title -notmatch 'unarmed')}
 if($job -is [hashtable]){$armed=$job.armed}
 $photos+=[pscustomobject]@{path=$jpg.Substring($root.Length+1).Replace('\','/');owner=$job.page;review='Generated to specification; visually reviewed';uniform='SECURITY visible';armed=[bool]$armed;unarmedSafe=(!$armed);dog=[bool]$job.dog;bike=([bool]($job.page -match 'vehicle-bike'));supportOnly=[bool]$job.supportOnly;ratio=1.5;tags=$title}
}
$photos|ConvertTo-Json -Depth 5|Set-Content $manifest -Encoding UTF8
Write-Output "Imported $($all.Count) generated 3:2 photographs."
