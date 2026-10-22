$ErrorActionPreference='Stop'
$source='C:/Users/Owner/OneDrive/Desktop/Paradigm_Security_October_21_Blogs_Photo_Assignments_Updated.pdf'
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Collections.Generic;
public static class LocalPdfText {
 public static byte[] A85(string s){var b=new List<byte>();ulong v=0;int n=0;foreach(char c in s){if(char.IsWhiteSpace(c))continue;if(c=='~')break;if(c=='z'&&n==0){b.AddRange(new byte[4]);continue;}if(c<33||c>117)continue;v=v*85+(uint)(c-33);n++;if(n==5){for(int k=3;k>=0;k--)b.Add((byte)(v>>(k*8)));v=0;n=0;}}if(n>0){int count=n-1;for(;n<5;n++)v=v*85+84;for(int k=3;k>3-count;k--)b.Add((byte)(v>>(k*8)));}return b.ToArray();}
 public static string Inflate(byte[] b){using(var input=new MemoryStream(b,2,b.Length-2))using(var zip=new DeflateStream(input,CompressionMode.Decompress))using(var output=new MemoryStream()){zip.CopyTo(output);return Encoding.GetEncoding(1252).GetString(output.ToArray());}}
 public static string Literal(string s){var b=new List<byte>();for(int i=1;i<s.Length-1;i++){char c=s[i];if(c=='\\'&&i<s.Length-2){c=s[++i];if(c>='0'&&c<='7'){int v=c-'0';for(int k=0;k<2&&i+1<s.Length-1&&s[i+1]>='0'&&s[i+1]<='7';k++)v=v*8+s[++i]-'0';b.Add((byte)v);continue;}switch(c){case 'n':c='\n';break;case 'r':c='\r';break;case 't':c='\t';break;case 'b':c='\b';break;case 'f':c='\f';break;case '\n':continue;}}b.Add((byte)c);}return Encoding.GetEncoding(1252).GetString(b.ToArray());}
 public static string Hex(string s){s=s.Trim('<','>');byte[] b=new byte[s.Length/2];for(int i=0;i<b.Length;i++)b[i]=Convert.ToByte(s.Substring(i*2,2),16);return Encoding.GetEncoding(1252).GetString(b);}
}
'@
$latin=[Text.Encoding]::GetEncoding(28591)
$pdf=$latin.GetString([IO.File]::ReadAllBytes($source))
$objects=@{};foreach($m in [regex]::Matches($pdf,'(?s)(\d+) 0 obj\s*(.*?)\s*endobj')){$objects[[int]$m.Groups[1].Value]=$m.Groups[2].Value}
$records=@();$page=0
foreach($id in @(4,7,8,12,13,17)){
 $page++;$obj=$objects[$id];$refs=[regex]::Match($obj,'/Contents(?:\[([^]]+)\]|\s+(\d+) 0 R)');$ids=if($refs.Groups[1].Success){[regex]::Matches($refs.Groups[1].Value,'(\d+) 0 R')|ForEach-Object {[int]$_.Groups[1].Value}}else{@([int]$refs.Groups[2].Value)}
 foreach($contentId in $ids){
  $raw=$objects[$contentId];$stream=[regex]::Match($raw,'(?s)stream\r?\n(.*?)\r?\n?endstream').Groups[1].Value
  $decoded=if($raw -match 'ASCII85Decode'){[LocalPdfText]::Inflate([LocalPdfText]::A85($stream))}elseif($raw -match 'FlateDecode'){[LocalPdfText]::Inflate($latin.GetBytes($stream))}else{$stream}
  [IO.File]::WriteAllText((Join-Path $PSScriptRoot "pdf-stream-$contentId.txt"),$decoded)
  foreach($bt in [regex]::Matches($decoded,'(?s)BT(.*?)ET')){
   $block=$bt.Groups[1].Value;$font=[regex]::Match($block,'/(\w+)\s+([\d.]+)\s+Tf');$position=[regex]::Match($block,'([-\d.]+)\s+([-\d.]+)\s+Tm')
   $previous=$null;$chunks=foreach($t in [regex]::Matches($block,'\((?:\\.|[^\\)])*\)|<[a-fA-F0-9]+>')){
    if($previous){$gap=$block.Substring($previous.Index+$previous.Length,$t.Index-$previous.Index-$previous.Length);$breaks=[regex]::Matches($gap,'T\*').Count;if($breaks -gt 1){"`n`n"}elseif($breaks -eq 1){' '}}
    if($t.Value.StartsWith('(')){[LocalPdfText]::Literal($t.Value)}else{[LocalPdfText]::Hex($t.Value)}
    $previous=$t
   }
   $text=$chunks -join ''
   if($text){$records+=[pscustomobject]@{page=$page;object=$contentId;font=$font.Groups[1].Value;size=$font.Groups[2].Value;x=$position.Groups[1].Value;y=$position.Groups[2].Value;text=$text}}
  }
 }
}
$records|ConvertTo-Json -Depth 5|Set-Content "$PSScriptRoot/october21-pdf-extracted.json" -Encoding UTF8
$records|ForEach-Object {"[page $($_.page), $($_.font) $($_.size), y=$($_.y)] $($_.text)"}|Set-Content "$PSScriptRoot/october21-pdf-full.txt" -Encoding UTF8
Write-Output "Extracted $($records.Count) text blocks across $page pages."
