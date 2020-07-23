# FrenzyZ80Conv

Manual conversion of Stern's FRENZY arcade game source from 8085 to Z80.

Alan McNeill's original 8085 source code was obtained from his now defunct website a9k.net (still available on the wayback machine here: https://web.archive.org/web/20161024201728/http://a9k.net/frenzy/ )

Why did I do the conversion, you ask? To aid my reverse engineering of BERZERK, which I have noticed shares a lot of code with its sequel Frenzy.
It's much easier to do a text search for similar code if the opcodes are the same. 

And, you can see my progress in reverse engineering Berzerk at http://seanriddle.com/berzerk.asm 

Any questions, ping me at scott.tunstall@ntlworld.com.  

Regards,
Scott.


KNOWN ISSUES:

** Don't expect this repo to be updated much, if at all, I only need Frenzy's source code to help me reverse engineer Berzerk, nothing more. I will accept pull requests though  **

Tabs & spacing - I don't care about them. If anyone wants to format them, feel free :) 

Probably bit shift instructions - rarr <reg8> I mapped to rr <reg8> as its a 9 bit carry and only Z80's RR seemed to match

IX and IY register instructions - haven't translated those, not something I wanted to write RegExes for (benefit vs cost wasn't worth it)

