$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$issues=@();$titles=@{};$counts=@{};$imagePaths=@{}
function Attribute([string]$tag,[string]$name){
 $match=[regex]::Match($tag,'\b'+[regex]::Escape($name)+'\s*=\s*(["''])(.*?)\1',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
 if($match.Success){return [Net.WebUtility]::HtmlDecode($match.Groups[2].Value)}
 return ''
}
$pages=@(Get-ChildItem $root -Recurse -Filter *.html | Where-Object FullName -NotMatch '\\redesign\\')
foreach($f in $pages){$s=Get-Content $f.FullName -Raw -Encoding UTF8;$rel=$f.FullName.Substring($root.Length+1)
 foreach($m in [regex]::Matches($s,'(?:href|src)=["'']([^"'']+)["'']')){$v=[Net.WebUtility]::HtmlDecode($m.Groups[1].Value);if($v -match '^(https?:|mailto:|tel:|data:|#|javascript:)'){continue};$v=($v -split '[?#]')[0];$target=[IO.Path]::GetFullPath((Join-Path $f.DirectoryName $v));if(!(Test-Path -LiteralPath $target)){$issues+="$rel : missing $v"};if($v -match '\.(png|webp|jpg|jpeg)$'){$imagePaths[$target]=$true}}
 if(([regex]::Matches($s,'<h1\b')).Count -ne 1){$issues+="$rel : H1 count"}
 $descriptions=@([regex]::Matches($s,'(?i)<meta\b[^>]*>')|Where-Object {(Attribute $_.Value 'name') -eq 'description'})
 if($descriptions.Count -ne 1 -or !(Attribute $descriptions[0].Value 'content').Trim()){$issues+="$rel : description missing"}
 $canonicals=@([regex]::Matches($s,'(?i)<link\b[^>]*>')|Where-Object {(Attribute $_.Value 'rel') -eq 'canonical'})
 if($canonicals.Count -ne 1 -or (Attribute $canonicals[0].Value 'href') -notmatch '^https://paradigmsecurityservices\.com/'){$issues+="$rel : canonical domain"}
 foreach($m in [regex]::Matches($s,'(?is)<script\b([^>]*)>(.*?)</script>')){if((Attribute $m.Groups[1].Value 'type') -eq 'application/ld+json'){try{$null=$m.Groups[2].Value|ConvertFrom-Json}catch{$issues+="$rel : invalid structured data"}}}
 if($s -match '(?<![A-Za-z])(?:All Safety|Safety Overview)(?![A-Za-z])'){$issues+="$rel : prohibited Safety label"}
 if($s -match '<h2>Questions About'){$issues+="$rel : FAQ on service page"}
 if($rel -like 'articles\topics\*'){$counts[$rel]=[regex]::Matches($s,"class='[^']*safety-topic-section[^']*'" ).Count;if($counts[$rel] -lt 2){$issues+="$rel : insufficient topic cards"}}
 if($s -match 'â€|Ã¢'){$issues+="$rel : text encoding artifacts"}
 $t=[regex]::Match($s,'<title>(.*?)</title>').Groups[1].Value;if($titles.ContainsKey($t)){$issues+="$rel : duplicate title with $($titles[$t])"}else{$titles[$t]=$rel}
}
$result=@{pages=$pages.Count;uniqueImages=$imagePaths.Count;issues=$issues;safetyTopicCounts=$counts;timestamp=(Get-Date -Format o)}
$result|ConvertTo-Json -Depth 8|Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot 'audit-results.json')
$result|ConvertTo-Json -Depth 8
