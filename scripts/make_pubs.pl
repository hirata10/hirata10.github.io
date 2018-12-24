# Script to generate publications page
#

$ThisAuthor = qq^Hirata^;

@PubSys = split '#', `cat publist.txt`;

open(OUT, '>../pubs.html') or die;

print OUT qq|<HTML><HEAD><TITLE>Publications</TITLE></HEAD>\n|;
print OUT qq|<BODY bgcolor="#ffffff" text="#000000" link="#0000ff" vlink="#0000ff">\n|;
print OUT qq|<H1 align="center">Publications</H1>\n<HR>\n|;

@Types = ('Preprints', 'Accepted Papers', 'Refereed Papers', 'Conference Proceedings', 'Manuals &amp; Documentation', 'White Papers &amp; Reports');

for $i (0..5) {

  print OUT qq|<H3 align="center">$Types[$i]</H3>\n|;

  print OUT qq|<TABLE border="1">\n<TR><TD width="20%" bgcolor="#ffc080"><B>Links</B></TD><TD width="80%" bgcolor="#ffc080"><B>Paper</B></TD></TR>\n|;

  @tags = split ' ', $PubSys[$i];
  for $t (@tags) {

    $tt = $t;
    $tt =~ s/\&/%26/g;
    $furl = 'http://adsabs.harvard.edu/cgi-bin/nph-bib_query?bibcode='.$tt;
    system "lwp-download \"$furl\" temp";
    $entry = `cat temp`;
#   system "cp temp temp.$tt";
    qx[rm temp];

    $entry =~ m/\n<table>(.*?)<\/table>/gs;
    $block = $1;
    @lines = split "\n", $block;

    # Extract info
    for $l (@lines) {

      # Author list
      if ($l =~ m|<b>Authors:</b>|) {
        $field = $l;
        $field =~ s|.*<td[^>]*>||;
        $field =~ s|</td>.*||;
        $field =~ s|<a [^>]*>||g;
        $field =~ s|</a>||g;
        $field =~ s|<A [^>]*>||g;
        $field =~ s|</A>||g;
        $field =~ s|\&\#160\;|\ |g;
        $field =~ s|\&\#([0-9]{3})\;|$1X|g;

        @authors = split q=\;=, $field; 
        $Na = $Nb = scalar @authors;
        $ithis = -1;
        for $i (0..$Na-1) {$ithis = $i if $authors[$i] =~ m/$ThisAuthor/;}
        $flag=0;
        if ($Na>12) {$Na=1; $flag=1;}
        $Alist = q@@;
        for $i (0..$Na-1) {
          ($LN,$FN) = split /,/, $authors[$i];
          $FN =~ s/([A-Z])[a-zA-Z0-9\-]+/$1\./g;
          $FN =~ s/\..+$/\./;
          if ($i==$ithis) {$Alist .= qq*<font color="#ff0000">*;}
          $Alist .= qq+$FN\ $LN+;
          if ($i==$ithis) {$Alist .= qq*</font>*;}
          if ($i!=$Na-1 and $Na!=2) {$Alist .= qq-,-};
          if ($i!=$Na-1) {$Alist .= q- -;}
          if ($i==$Na-2) {$Alist .= qq-and\ -;}
        }
        if ($flag) {$Alist .= qq: et al. ($Nb authors):;}
      }
      $Alist =~ s|([0-9]{3})X|\&\#$1\;|;

      # Title
      if ($l =~ m|<b>Title:</b>|) {
        $field = $l;
        $field =~ s|.*<td[^>]*>||;
        $field =~ s|</td>.*||;
        $field =~ s|<a [^>]*>||g;
        $field =~ s|</a>||g;
        $field =~ s|<A [^>]*>||g;
        $field =~ s|</A>||g;
        $field =~ s|\&lt\;=|\&le\;|g;
        $field =~ s|\&gt\;=|\&ge\;|g;
        $field =~ s|Lyman-alpha|Lyman-\&alpha\;|g;
        $TITLE = $field;
      }

      # Publication info
      if ($l =~ m|<b>Publication:</b>|) {
        $field = $l;
        $field =~ s|.*<td[^>]*>||;
        $field =~ s|</td>.*||;
        $field =~ s|\(<[aA].*>.*</[aA]>\)||;
        $field =~ s|<a [^>]*>||g;
        $field =~ s|</a>||g;
        $field =~ s|<A [^>]*>||g;
        $field =~ s|</A>||g;

        # Clean up journal or other publication names
        $field =~ s|Monthly\s*Notices?\s*of\s*the\s*Royal\s*Astronomical\s*Society|Mon. Not. R. Astron. Soc.|;
        $field =~ s|Physical\s*Review\s*([A-E])|Phys. Rev. $1|;
        $field =~ s|Astronomy\s*and\s*Astrophysics|Astron. Astrophys.|;
        $field =~ s|The\s*Astrophysical\s*Journal\s*Supplement\s*Series|Astrophys. J. Supp.|;
        $field =~ s|The\s*Astrophysical\s*Journal|Astrophys. J.|;
        $field =~ s|Journal\s*of\s*Cosmology\s*and\s*Astroparticle\s*Physics|J. Cosmo. Astropart. Phys.|;
        $field =~ s|Publications\s*of\s*the\s*Astronomical\s*Society\s*of\s*the\s*Pacific|Pub. Astron. Soc. Pac.|;
        $field =~ s|.*AIP\s*Conference\s*Proceedings|AIP Conf. Proc.|;
        $field =~ s|.*IAU\s*Symposium|IAU Symposium|;
        $field =~ s|Astro2010: The Astron. Astrophys. Decadal Survey, Science White Papers|Astro2010 Science White Paper|;

        $field =~ s%[Ii]ssue\s*(\d+)\,%%;
        $is = $1;
        $x = qq--;
        if ($field =~ m&J. Cosmo. Astropart. Phys.&) {$x = qq~\ $is:~;}
        $field =~ s%,?\s*([vV]olume|[vV]ol)\.?\s*(\d+)\,?(\D\ \.)?% \<B\>$2\<\/B\>:%;
        if ($field =~ m&IAU Symposium&) { $field =~ s/(Symposium.*<\/B>).*p\.(\d+)\D.*$/$1:$2/; }
        $field =~ s%\s*(id|p|pp)\.\s*([0123456789AL]+)\D+.*%$x$2%;
        $field =~ s%\ *article%%;

        $PUBLICATION = $field;
      }

      # Year
      if ($l =~ m|<b>Publication Date:</b>|) {
        $field = $l;
        $field =~ s|.*<td[^>]*>||;
        $field =~ s|</td>.*||;
        $field =~ s|\(<[aA].*>.*</[aA]>\)||;
        $field =~ s|<a [^>]*>||g;
        $field =~ s|</a>||g;
        $field =~ s|<A [^>]*>||g;
        $field =~ s|</A>||g;
        $field =~ m-(\d{4})-;
        $YEAR = $1;
      }
    }

    # ArXiv directive
    $estr = 'arXiv';
    if ($entry =~ m|<[aA]*[^>]*href="([^>]+)"[^>]*>arXiv e-print<|s) {
      $eurl = $1;
      if ($entry =~ m-\(arXiv\:([^\)]*)\)-) {
        $eurl = q*http://arxiv.org/abs/*.$1;
      }
      $estr = qq|<A href="$eurl" target="_top">arXiv</A>|;
    }

    print OUT qq|<TR><TD><A href="$furl" target="_top">ADS</A> $estr</TD>\n|;

    print OUT qq|<TD> $Alist, <I><font color="#00c040">$TITLE</font></I>, $PUBLICATION ($YEAR) </TD></TR>\n|;

  }

  print OUT qq|</TABLE>\n|;
}

$date = qx@date@;
print OUT qq|<HR><font size="-1"><I>Last updated: $date</I></font></BODY></HTML>\n|;
close OUT;
