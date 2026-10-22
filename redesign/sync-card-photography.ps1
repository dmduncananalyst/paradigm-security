$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$pages=@(Get-ChildItem $root -Recurse -Filter '*.html'|Where-Object FullName -NotMatch '\\redesign\\'|Sort-Object FullName)
$destinations=@{};$matchesCount=0
Add-Type -AssemblyName System.Drawing
function Ratio($file){$im=[Drawing.Image]::FromFile($file);$r=$im.Width/$im.Height;$im.Dispose();return $r}
foreach($page in $pages){
 $html=Get-Content $page.FullName -Raw -Encoding UTF8
 $html=[regex]::Replace($html,'(?is)<a class=''image-card[^'']*''[^>]*href=''([^'']+)''[^>]*>\s*<img\b[^>]*src=''([^'']+)''[^>]*>',[Text.RegularExpressions.MatchEvaluator]{param($m)
  $target=[IO.Path]::GetFullPath((Join-Path $page.DirectoryName ([Net.WebUtility]::HtmlDecode($m.Groups[1].Value))))
  if(!(Test-Path -LiteralPath $target)){return $m.Value}
  $photo=[IO.Path]::GetFullPath((Join-Path $page.DirectoryName ([Net.WebUtility]::HtmlDecode($m.Groups[2].Value))))
  if(!$destinations.ContainsKey($target)){$destinations[$target]=@{photo=$photo;displaced=@()}}
  $entry=$destinations[$target]
  if([Math]::Abs((Ratio $photo)-1.5) -lt 0.015 -and [Math]::Abs((Ratio $entry.photo)-1.5) -gt 0.015){$entry.displaced+=$entry.photo;$entry.photo=$photo}
  if($entry.photo -ne $photo){$entry.displaced+= $photo}
  $base=[Uri]($page.DirectoryName+'\');$relative=[Uri]::UnescapeDataString($base.MakeRelativeUri([Uri]$entry.photo).ToString())
  return $m.Value.Replace($m.Groups[2].Value,[Net.WebUtility]::HtmlEncode($relative))
 })
 [IO.File]::WriteAllText($page.FullName,$html,(New-Object Text.UTF8Encoding $false))
}
foreach($target in $destinations.Keys){
 $entry=$destinations[$target];$html=Get-Content $target -Raw -Encoding UTF8
 $base=[Uri]((Split-Path $target)+'\')
 $src=[Net.WebUtility]::HtmlEncode([Uri]::UnescapeDataString($base.MakeRelativeUri([Uri]$entry.photo).ToString()))
 $hero=[regex]::Match($html,'(?is)<figure class=''feature-photo''>\s*<img\b[^>]*src=''([^'']+)''[^>]*>\s*</figure>')
 if($hero.Success){
  $old=[IO.Path]::GetFullPath((Join-Path (Split-Path $target) ([Net.WebUtility]::HtmlDecode($hero.Groups[1].Value))))
  if($old -ne $entry.photo){$entry.displaced+=$old}
  $html=$html.Remove($hero.Index,$hero.Length).Insert($hero.Index,$hero.Value.Replace($hero.Groups[1].Value,$src))
 }else{
  $title=[regex]::Match($html,'(?is)<section class=''page-title[^'']*''>.*?</section>')
  if($title.Success){$html=$html.Insert($title.Index+$title.Length,"<figure class='feature-photo'><img src='$src' alt='Security coverage for this page' loading='lazy'></figure>")}
 }
 foreach($photo in @($entry.displaced|Sort-Object -Unique)){
  $relative=[Net.WebUtility]::HtmlEncode([Uri]::UnescapeDataString($base.MakeRelativeUri([Uri]$photo).ToString()))
  if($html.Contains("src='$relative'")){continue}
  $image="<figure><img src='$relative' alt='Security personnel and property coverage' loading='lazy'></figure>"
  $block="<div class='coverage-story'>$image</div>"
  $paragraph=[regex]::Matches($html,'(?is)<div class=''service-board''>.*?(?=<section class=''page-action''>|</main>)')
  $placed=$false
  if($paragraph.Count){
   $p=[regex]::Matches($paragraph[0].Value,'(?is)<p\b[^>]*>.*?</p>')
   foreach($candidate in $p){
    $at=$paragraph[0].Index+$candidate.Index
    $before=$html.Substring(0,$at)
    if($before.LastIndexOf("class='coverage-story'") -gt $before.LastIndexOf('</section>')){continue}
    $block="<div class='coverage-story'>$image<div>$($candidate.Value)</div></div>"
    $html=$html.Remove($at,$candidate.Length).Insert($at,$block);$placed=$true;break
   }
  }
  if(!$placed){$html=$html.Replace("<section class='page-action'>",$block+"<section class='page-action'>")}
 }
 [IO.File]::WriteAllText($target,$html,(New-Object Text.UTF8Encoding $false));$matchesCount++
}
# Normalize earlier cards after choosing the destination's final photograph.
foreach($page in $pages){
 $html=Get-Content $page.FullName -Raw -Encoding UTF8
 $html=[regex]::Replace($html,'(?is)<a class=''image-card[^'']*''[^>]*href=''([^'']+)''[^>]*>\s*<img\b[^>]*src=''([^'']+)''[^>]*>',[Text.RegularExpressions.MatchEvaluator]{param($m)
  $target=[IO.Path]::GetFullPath((Join-Path $page.DirectoryName ([Net.WebUtility]::HtmlDecode($m.Groups[1].Value))))
  if(!$destinations.ContainsKey($target)){return $m.Value}
  $base=[Uri]($page.DirectoryName+'\');$src=[Net.WebUtility]::HtmlEncode([Uri]::UnescapeDataString($base.MakeRelativeUri([Uri]$destinations[$target].photo).ToString()))
  return $m.Value.Replace($m.Groups[2].Value,$src)
 })
 [IO.File]::WriteAllText($page.FullName,$html,(New-Object Text.UTF8Encoding $false))
}
Write-Output "Card and destination photographs synchronized: $matchesCount pages."
