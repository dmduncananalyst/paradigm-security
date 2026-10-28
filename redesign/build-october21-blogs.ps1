$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
function E($value){[Net.WebUtility]::HtmlEncode([string]$value)}
$utf8=New-Object Text.UTF8Encoding $false
$blocks=Get-Content "$PSScriptRoot/october21-pdf-extracted.json" -Raw -Encoding UTF8|ConvertFrom-Json
$specs=@(
 @{start=1;end=2;slug='blog-company-holiday-party-security-risks.html';photo='Holiday Event Security in a Festive Lobby.png';alt='Security officer overlooking a company holiday party in a festive lobby';service='protection/events.html';phrase='professional event coverage';label='Get Event Security';category='Events'},
 @{start=3;end=4;slug='blog-holiday-shopping-parking-lot-security.html';photo='Holiday Mall Watch at Night.png';alt='Security officer watching a busy shopping center parking lot during the holidays';service='protection/malls-shopping-centers.html';phrase='professional security presence';label='Get Shopping Center Security';category='Retail'},
 @{start=5;end=6;slug='blog-construction-site-theft-holiday-shutdowns.html';photo='Golden-Hour Construction Site Security.png';alt='Security officer watching a construction site and equipment at golden hour';service='protection/construction-sites.html';phrase='Professional security';label='Get Construction Site Security';category='Construction'}
)
$template=Get-Content "$root/blog.html" -Raw -Encoding UTF8
$template=[regex]::Replace($template,"<link rel='stylesheet' href='redesign/blog.css[^']*'>",'')
New-Item -ItemType Directory -Path "$root/assets/blog" -Force|Out-Null
$articles=@()
foreach($spec in $specs){
 $selected=@($blocks|Where-Object {$_.page -ge $spec.start -and $_.page -le $spec.end})
 $title=($selected|Where-Object {$_.font -eq 'F2' -and $_.size -eq '20'}|Select-Object -First 1).text
 $description=($selected|Where-Object {$_.text -like 'Meta description:*'}|Select-Object -First 1).text.Substring(18)
 $sections=New-Object Collections.ArrayList
 $current=$null
 foreach($block in $selected){
  if($block.font -eq 'F2' -and $block.size -eq '12'){
   $current=@{heading=$block.text;paragraphs=(New-Object Collections.ArrayList);sources=(New-Object Collections.ArrayList)}
   [void]$sections.Add($current)
  }elseif($block.font -eq 'F1' -and $block.size -eq '10'){
   $paragraphs=@($block.text -split '\r?\n\s*\r?\n')
   if($block.page -eq $spec.end -and $sections.Count -and $current.paragraphs.Count -and $block -eq ($selected|Where-Object {$_.page -eq $spec.end -and $_.size -eq '10'}|Select-Object -First 1)){
    $last=$current.paragraphs.Count-1
    $current.paragraphs[$last]+=' '+$paragraphs[0]
    $paragraphs=@($paragraphs|Select-Object -Skip 1)
   }
   foreach($paragraph in $paragraphs){[void]$current.paragraphs.Add($paragraph)}
  }elseif($current -and $current.heading -eq 'Sources' -and $block.font -eq 'F1' -and $block.size -eq '8.5' -and $block.text -match '^(.*?): (https://\S+)$'){
   [void]$current.sources.Add(@{label=$Matches[1];url=$Matches[2]})
  }
 }
 if($sections.Count -ne 6 -or $sections[-1].sources.Count -lt 2){throw "Incomplete PDF extraction for $title"}
 $source=Join-Path 'C:/Users/Owner/OneDrive/Desktop' $spec.photo
 $image='assets/blog/'+$spec.photo
 $asset=Join-Path $root $image
 if(!(Test-Path -LiteralPath $asset)){Copy-Item -LiteralPath $source -Destination $asset}
 $photoHashes=Get-Content "$PSScriptRoot/approved-blog-photo-hashes.json" -Raw|ConvertFrom-Json
 if($photoHashes.PSObject.Properties[$spec.photo].Value -ne (Get-FileHash -LiteralPath $asset).Hash){throw 'Approved photo differs from its verified project copy'}
 $article=@{title=$title;description=$description;path=$spec.slug;photo=$image;alt=$spec.alt;sections=@($sections);service=$spec.service;phrase=$spec.phrase;label=$spec.label;category=$spec.category;date='2026-10-21'}
 $articles+=,$article
 $content='';$linked=$false
 foreach($section in $sections){
  $content+="<section class='journal-section'><h2>$(E $section.heading)</h2>"
  foreach($paragraph in $section.paragraphs){
   $text=E $paragraph
   if(!$linked -and $text.Contains($spec.phrase)){$text=$text.Replace($spec.phrase,"<a href='$(E $spec.service)'>$(E $spec.phrase)</a>");$linked=$true}
   $content+="<p>$text</p>"
  }
  if($section.sources.Count){$content+="<ul class='journal-sources'>";foreach($source in $section.sources){$content+="<li><a href='$(E $source.url)' target='_blank' rel='noopener noreferrer'>$(E $source.label)</a></li>"};$content+='</ul>'}
  $content+='</section>'
 }
 if(!$linked){throw "No natural internal link for $title"}
 $main="<article class='journal-article'><header class='journal-heading'><a class='journal-back' href='blog.html'>Blog</a><p class='journal-date'><time datetime='2026-10-21'>October 21, 2026</time><span>$(E $spec.category)</span></p><h1>$(E $title)</h1></header><figure class='journal-feature'><img src='$(E $image)' alt='$(E $spec.alt)' width='1672' height='941' fetchpriority='high'></figure><div class='journal-copy'>$content</div><div class='page-action'><button type='button' class='button context-cta' data-open-intake>$(E $spec.label)</button></div></article>"
 $html=[regex]::Replace($template,'(?is)<main id=''main''>.*?</main>',[Text.RegularExpressions.MatchEvaluator]{param($m)"<main id='main'>$main</main>"})
 $html=[regex]::Replace($html,'(?is)<title>.*?</title>',"<title>$(E $title)</title>")
 $html=[regex]::Replace($html,"<meta name='description' content='[^']*'>","<meta name='description' content='$(E $description)'>")
 $canonical='https://paradigmsecurityservices.com/'+$spec.slug
 $html=[regex]::Replace($html,"<link rel='canonical' href='[^']*'>","<link rel='canonical' href='$canonical'>")
 $html=[regex]::Replace($html,"<meta property='og:title' content='[^']*'>","<meta property='og:title' content='$(E $title)'>")
 $html=[regex]::Replace($html,"<meta property='og:description' content='[^']*'>","<meta property='og:description' content='$(E $description)'>")
 $schema=@{'@context'='https://schema.org';'@type'='BlogPosting';headline=$title;description=$description;datePublished='2026-10-21';dateModified='2026-10-21';mainEntityOfPage=$canonical;url=$canonical;image=('https://paradigmsecurityservices.com/'+$image.Replace(' ','%20'));author=@{'@type'='Organization';name='Paradigm Security Services'};publisher=@{'@type'='Organization';name='Paradigm Security Services'};inLanguage='en-US'}|ConvertTo-Json -Depth 8 -Compress
 $html=[regex]::Replace($html,"(?is)<script type='application/ld\+json'>.*?</script>","<script type='application/ld+json'>$schema</script>")
 $html=$html.Replace("data-page='blog.html'","data-page='$($spec.slug)'")
 $html=$html.Replace('</head>',"<meta property='og:type' content='article'><meta property='og:url' content='$canonical'><meta property='og:image' content='https://paradigmsecurityservices.com/$(E $image.Replace(' ','%20'))'><link rel='stylesheet' href='redesign/blog.css?v=20261021-1'></head>")
 # Reuse the corresponding service's tested guided chat, without changing its integration.
 $serviceHtml=Get-Content (Join-Path $root $spec.service) -Raw -Encoding UTF8
 $chat=[regex]::Match($serviceHtml,"(?is)<script type='application/json' id='intake-profile'>.*?</dialog>").Value
 if(!$chat){throw "Missing service chat: $($spec.service)"}
 $html=[regex]::Replace($html,"(?is)<script type='application/json' id='intake-profile'>.*?</dialog>",[Text.RegularExpressions.MatchEvaluator]{param($m)$chat})
 [IO.File]::WriteAllText((Join-Path $root $spec.slug),$html,$utf8)
}
$previews=foreach($article in $articles){"<a class='journal-preview' href='$(E $article.path)'><img src='$(E $article.photo)' alt='$(E $article.alt)' width='1672' height='941'><div class='journal-preview-caption'><span class='journal-category'>$(E $article.category)</span><h2>$(E $article.title)</h2><span class='journal-read'>Read Article</span></div><time datetime='2026-10-21'>October 21, 2026</time></a>"}
$archive="<section class='journal-archive'><header class='journal-archive-heading'><h1>Blog</h1></header><div class='journal-previews'>$(($previews)-join '')</div></section><section class='page-action'><button type='button' class='button context-cta' data-open-intake>Get Security for Your Property</button></section>"
$archiveHtml=[regex]::Replace($template,"(?is)<main id='main'>.*?</main>",[Text.RegularExpressions.MatchEvaluator]{param($m)"<main id='main'>$archive</main>"})
if($archiveHtml -notmatch 'redesign/blog.css'){$archiveHtml=$archiveHtml.Replace('</head>',"<link rel='stylesheet' href='redesign/blog.css?v=20261021-1'></head>")}
[IO.File]::WriteAllText("$root/blog.html",$archiveHtml,$utf8)
$articles|ConvertTo-Json -Depth 12|Set-Content "$PSScriptRoot/october21-articles.json" -Encoding UTF8
[xml]$sitemap=Get-Content "$root/sitemap.xml" -Raw
foreach($article in $articles){$url='https://paradigmsecurityservices.com/'+$article.path;if($url -notin @($sitemap.urlset.url.loc)){$node=$sitemap.CreateElement('url',$sitemap.DocumentElement.NamespaceURI);$loc=$sitemap.CreateElement('loc',$sitemap.DocumentElement.NamespaceURI);$loc.InnerText=$url;[void]$node.AppendChild($loc);$date=$sitemap.CreateElement('lastmod',$sitemap.DocumentElement.NamespaceURI);$date.InnerText='2026-10-21';[void]$node.AppendChild($date);[void]$sitemap.DocumentElement.AppendChild($node)}}
$sitemap.Save("$root/sitemap.xml")
Write-Output 'Implemented three complete October 21 articles, approved images, archive previews, and sitemap entries.'
