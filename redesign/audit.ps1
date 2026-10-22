$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$issues=@();$titles=@{};$counts=@{};$imagePaths=@{}
$pages=@(Get-ChildItem $root -Recurse -Filter *.html | Where-Object FullName -NotMatch '\\redesign\\')
foreach($f in $pages){$s=Get-Content $f.FullName -Raw -Encoding UTF8;$rel=$f.FullName.Substring($root.Length+1)
 foreach($m in [regex]::Matches($s,'(?:href|src)=["'']([^"'']+)["'']')){$v=[Net.WebUtility]::HtmlDecode($m.Groups[1].Value);if($v -match '^(https?:|mailto:|tel:|data:|#|javascript:)'){continue};$v=($v -split '[?#]')[0];$target=[IO.Path]::GetFullPath((Join-Path $f.DirectoryName $v));if(!(Test-Path -LiteralPath $target)){$issues+="$rel : missing $v"};if($v -match '\.(png|webp|jpg|jpeg)$'){$imagePaths[$target]=$true}}
 if(([regex]::Matches($s,'<h1\b')).Count -ne 1){$issues+="$rel : H1 count"}
 if($s -notmatch '<meta name=''description'' content=''[^'']+''>'){$issues+="$rel : description missing"}
 if($s -notmatch '<link rel=''canonical'' href=''https://www.paradigmsecurityservices.com/'){$issues+="$rel : canonical domain"}
 foreach($m in [regex]::Matches($s,'<script type=''application/ld\+json''>(.*?)</script>')){try{$null=$m.Groups[1].Value|ConvertFrom-Json}catch{$issues+="$rel : invalid structured data"}}
 if($s -match 'All Safety|Safety Overview'){$issues+="$rel : prohibited Safety label"}
 if($s -match '<h2>Questions About'){$issues+="$rel : FAQ on service page"}
 if($rel -like 'articles\topics\*'){$counts[$rel]=[regex]::Matches($s,"class='[^']*safety-topic-section[^']*'" ).Count;if($counts[$rel] -lt 2){$issues+="$rel : insufficient topic cards"}}
 if($s -match 'â€|Ã¢'){$issues+="$rel : text encoding artifacts"}
 $t=[regex]::Match($s,'<title>(.*?)</title>').Groups[1].Value;if($titles.ContainsKey($t)){$issues+="$rel : duplicate title with $($titles[$t])"}else{$titles[$t]=$rel}
}
$result=@{pages=$pages.Count;uniqueImages=$imagePaths.Count;issues=$issues;safetyTopicCounts=$counts;timestamp=(Get-Date -Format o)}
$result|ConvertTo-Json -Depth 8|Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot 'audit-results.json')
$result|ConvertTo-Json -Depth 8
