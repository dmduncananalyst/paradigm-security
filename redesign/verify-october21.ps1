param([string]$ReportPath=(Join-Path $env:TEMP 'paradigm-security-october21-verification.json'))
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$articles=Get-Content "$PSScriptRoot/october21-articles.json" -Raw -Encoding UTF8|ConvertFrom-Json
$pdf=Get-Content "$PSScriptRoot/october21-pdf-extracted.json" -Raw -Encoding UTF8|ConvertFrom-Json
$archive=Get-Content "$root/blog.html" -Raw -Encoding UTF8
$sitemap=Get-Content "$root/sitemap.xml" -Raw
$results=@();$errors=@()
function Plain($text){([Net.WebUtility]::HtmlDecode([regex]::Replace($text,'<[^>]+>','')) -replace '\s+',' ').Trim()}
for($i=0;$i -lt $articles.Count;$i++){
 $article=$articles[$i];$html=Get-Content (Join-Path $root $article.path) -Raw -Encoding UTF8
 $first=1+2*$i;$last=$first+1
 $original=@($pdf|Where-Object {$_.page -ge $first -and $_.page -le $last -and $_.font -eq 'F1' -and $_.size -eq '10'}|ForEach-Object {$_.text}) -join ' '
 $sections=[regex]::Match($html,"(?is)<div class='journal-copy'>(.*?)</div>").Groups[1].Value
 $actual=@([regex]::Matches($sections,'(?is)<p>(.*?)</p>')|ForEach-Object {$_.Groups[1].Value}) -join ' '
 $title=Plain ([regex]::Match($html,'<title>(.*?)</title>').Groups[1].Value)
 $meta=[Net.WebUtility]::HtmlDecode([regex]::Match($html,"<meta name='description' content='([^']*)'>").Groups[1].Value)
 $card=[regex]::Match($archive,"(?is)<a class='journal-preview' href='"+[regex]::Escape($article.path)+"'>.*?</a>").Value
 $source=Join-Path 'C:/Users/Owner/OneDrive/Desktop' ([IO.Path]::GetFileName($article.photo))
 $schema=[regex]::Match($html,"(?is)<script type='application/ld\+json'>(.*?)</script>").Groups[1].Value|ConvertFrom-Json
 $tests=@{
  completePdfProse=((Plain $original) -ceq (Plain $actual));paragraphs=([regex]::Matches($sections,'<p>').Count -eq 10)
  exactTitle=($title -ceq $article.title);exactDescription=($meta -ceq $article.description)
  oneH1=([regex]::Matches($html,'<h1\b').Count -eq 1);headings=([regex]::Matches($sections,'<h2>').Count -eq 6)
  preview=($card -and $card.Contains($article.photo));featured=$html.Contains("src='$($article.photo)'")
  unchangedPhoto=(((Get-Content "$PSScriptRoot/approved-blog-photo-hashes.json" -Raw|ConvertFrom-Json).PSObject.Properties[[IO.Path]::GetFileName($article.photo)].Value) -eq (Get-FileHash -LiteralPath (Join-Path $root $article.photo)).Hash)
  publication=($schema.datePublished -eq '2026-10-21' -and $html.Contains("datetime='2026-10-21'"))
  articleSchema=($schema.'@type' -eq 'BlogPosting' -and $schema.headline -ceq $article.title)
  canonical=$html.Contains("rel='canonical' href='https://paradigmsecurityservices.com/$($article.path)'")
  serviceLink=$sections.Contains("href='$($article.service)'")
  sitemap=([regex]::Matches($sitemap,[regex]::Escape('https://paradigmsecurityservices.com/'+$article.path)).Count -eq 1)
  sources=($true)
 }
 foreach($reference in $article.sections[-1].sources){if(!$sections.Contains("href='$([Net.WebUtility]::HtmlEncode($reference.url))'") -or !(Plain $sections).Contains($reference.label)){$tests.sources=$false}}
 foreach($test in $tests.Keys){if(!$tests[$test]){$errors+="$($article.path): $test"}}
 $results+=@{article=$article.path;checks=$tests;words=((Plain $actual) -split ' ').Count;sources=$article.sections[-1].sources.Count}
}
$adjacent=@()
Get-ChildItem $root -Recurse -Filter '*.html'|Where-Object FullName -NotMatch '\\redesign\\'|ForEach-Object {
 $html=Get-Content $_.FullName -Raw -Encoding UTF8;$main=[regex]::Match($html,'(?is)<main.*?</main>').Value
 $imgs=@([regex]::Matches($main,"<img[^>]*src='([^']+)'"))
 for($j=1;$j -lt $imgs.Count;$j++){if($imgs[$j].Groups[1].Value -eq $imgs[$j-1].Groups[1].Value){$adjacent+=$_.Name}}
}
if($adjacent.Count){$errors+='Adjacent identical photos: '+($adjacent -join ', ')}
if((Get-FileHash "$root/assets/reference/asset-14.jpg").Hash -ne '7308D3BC5CB81EAA702133AC4197F56D17931A170B1BAE4839CC7AC80CFE5942'){$errors+='About photo changed'}
$careers=Get-Content "$root/employment.html" -Raw
if(!$careers.Contains('assets/approved-generated/page-employment.jpg')){$errors+='Careers photo changed'}
$homepageHtml=Get-Content "$root/index.html" -Raw
if($homepageHtml -match '<video' -or !$homepageHtml.Contains('home-hero-badge-free-v3.jpg')){$errors+='Home badge-free fallback missing'}
$report=@{articles=$results;adjacentDuplicates=$adjacent.Count;aboutPhotoPreserved=$true;careersPhotoPreserved=$true;errors=$errors}
$report|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $ReportPath -Encoding UTF8
$report|ConvertTo-Json -Depth 8
if($errors.Count){throw 'October 21 verification failed'}
