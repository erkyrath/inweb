Webs, Tangling and Weaving.

How to use Inweb to weave or tangle a web already written.

@h All-in-one webs.
A program written for use with Inweb is called a "web". Inweb was primarily
designed for large, multisection webs, but it can also be used in a much
simpler way on smaller webs. In this documentation we'll call those
"all-in-one webs", meaning that there is just a single source code file for
the program.

Such a file should be a UTF-8 encoded plain text file with the file
extension |.inweb|. The following is a "hello world" example, which can
be found in the Inweb distribution as |inweb/Examples/hellow.inweb|:

= (text as Inweb)
	Title: hellow
	Author: Graham Nelson
	Purpose: A minimal example of a C program written for inweb.
	Language: C

	@ =
	#include <stdio.h>

	int main(int argc, char *argv[]) {
		printf("Hello world!\n");
	}

@ This of course is just a regular C "hello world" program written below
the |@ =| marker, and some metadata written above it. The metadata above
is called the "contents section": for a larger web, it would expand out
to something more like a contents page, though here it's more like a
title page. The Title, Author and Purpose make no functional difference
to the program produced - they are purely descriptive - but the Language
setting is another matter, as we shall see.

The contents end, and the code begins, when the first "paragraph" begins.
Code in an Inweb web is divided into paragraphs. The core Inform compiler
currently has 8362 paragraphs, whereas |hellow| has just one. (If you are
reading this documentation in a web page or a PDF, you will see that it's
divided up into little numbered sections: those are individual paragraphs
from the |inweb| web.) More on this below, but the use of an |@| character
in column 1 of the web file is what marks a paragraph break.

As mentioned earlier, there are two basic things we can do with a web:
tangle, to make a program ready to compile and run; and weave, to make
a comfortably legible version for human eyes instead. Let's now tangle:
= (text as ConsoleText)
	$ inweb/Tangled/inweb inweb/Examples/hellow.inweb -tangle
	web "hellow": 1 section(s) : 1 paragraph(s) : 9 line(s)
	tangling <inweb/Examples/hellow.c> (written in C)
=
And |inweb/Examples/hellow.c| is now a regular C program which can then be
compiled. If we had wanted it to be written somewhere else, or called
something else, we could have used |-tangle-to F| to specify a file |F|
to create instead.

In general, you never need to look at or edit tangled code, but if
we take a look at this one to see what has happened, two things are worth
noting.

(a) First, the use of the |#line| C preprocessor feature, which ensures that
any compilation errors occurring will be reported at the correct point of
origin in the original Inweb file, not in the tangled file.

(b) Secondly, notice that the |main| function has automatically been
predeclared at the top of the file. Because Inweb does this for C programs,
the programmer can freely call functions defined lower down in the source
code, without having to write tiresome predeclarations or header files. (As it
happens, there was no need in the case of |main|, but nor was there any harm.)

= (text as C)
	/* Tangled output generated by inweb: do not edit */
	#include <stdio.h>
	#line 9 "inweb/Examples/hellow.inweb"
	int  main(int argc, char *argv[]) ;
	#line 8 "inweb/Examples/hellow.inweb"

	int main(int argc, char *argv[]) {
		printf("Hello world!\n");
	}

@ So much for tangling: we can also weave. |hellow| is so uninteresting
to look at that this seems a good point to switch to |inweb/Examples/twinprimes.inweb|,
a C program to find twin prime numbers. If we weave:
= (text as ConsoleText)
	$ inweb/Tangled/inweb inweb/Examples/twinprimes.inweb -weave
	web "twinprimes": 1 section(s) : 4 paragraph(s) : 48 line(s)
	[Complete Program: HTML -> inweb/Examples/twinprimes.html]
=
As with tangling, we can override this destination with |-weave-to F|, telling
Inweb to weave into just a single file (which in this instance it was going
to do anyway) and call it |F|; or we can similarly |-weave-into D|, telling
Inweb to weave a set of file into the directory |D|, rather than the usual
|Woven| subdirectory of the web in question.

By default, |-weave| makes an HTML representation of the program. (On a larger
web, with multiple sections, it would make a set of linked pages, but here
there's just one.) This can then be looked at with a browser such as Chrome or
Safari. HTML is not the only format we can produce. Inweb performs the weave
by following a "pattern", and it has several patterns built in, notably |HTML|,
|Ebook| and |TeX|.

Running Inweb with |-weave-as P| tells it to weave with pattern |P|; the
plain command |-weave| is equivalent to |-weave-as HTML|. The |Ebook| pattern
makes an EPUB file suitable for readers such as Apple's Books app, but that
would be overkill for such a tiny program. Instead:
= (text as ConsoleText)
	$ inweb/Tangled/inweb inweb/Examples/twinprimes.inweb -weave-as TeX
=
This will only work if you have the mathematical typesetting system TeX
installed, and in particular, the |pdftex| tool. (This comes as part of
the standard TeXLive distribution, so simply "installing TeX" on your
platform will probably install |pdftex| automatically.) Now the response
is like so:
= (text as ConsoleText)
	$ inweb/Tangled/inweb inweb/Examples/twinprimes.inweb -weave-as TeX
	web "twinprimes": 1 section(s) : 4 paragraph(s) : 48 line(s)
	[Complete Program: PDF -> inweb/Examples/twinprimes.tex: 1pp 103K]
=
Inweb automatically creates |twinprimes.tex| and runs it through |pdftex|
to produce |twinprimes.pdf|: it reads over the TeX log file to see how
many pages that comes to, and reports back. All being well, the |.tex|
and |.log| files are silently removed, leaving just |twinprimes.pdf| behind.

@h Multi-section webs.
The |twinprimes.inweb| example was a program so small that it could
comfortably fit into one source file, but for really large programs, that
would be madness. The core Inform compiler, for example, runs to about
210,000 lines of code, and distributes those across 418 source files
called "sections", together with a special 419th section which forms
its contents page. It's a matter of personal taste how much should be
in a section, but an ideal section file might contain 500 to 1000 lines
of material and weave to a standalone essay, describing and implementing
a single well-defined component of the whole program.

In this documentation, we'll call such webs "multi-section".

A multi-section web is stored as a directory, whose name should be (a
short version of) the name of the program. For example, Inweb's own
source is in a directory called |inweb|. A web directory is a tidy,
self-contained area in which the program can be written, compiled and
used.

Inweb expects that a multi-section web will contain at least two source
files, each of which is a UTF-8 encoded text file with the file extension
|.w|. One source file is special, must always be called |Contents.w|,
and must be directly stored in the web directory. All other section files
are stored in subdirectories of the web directory:

(a) If the web is still relatively small, there may only be a few of these,
stored in a single subdirectory called |Sections|.

(b) Alternatively (not additionally), a larger web can use chapter
subdirectories called |Manual|, |Preliminaries|, |Chapter 1|, |Chapter 2|, ...,
|Appendix A|, |Appendix B|, ...; preliminaries and appendices being optional.
(There can't be a Chapter 0, though there can be Appendix A, B, C, ..., L.)

A multi-section web can contain a variety of other subdirectories as needed.
Two in particular, |Woven| and |Tangled|, are automatically created by Inweb
as needed to store the results of tangling and weaving, respectively: they
are not intended to hold any material of lasting value, and can be emptied
at any time and regenerated later.

@ Uniquely, the |Contents.w| section provides neither typeset output nor
compiled code: it is instead a roster telling Inweb about the rest of the
web, and how the other sections are organised. It has a completely different
syntax from all other sections. (It's essentially a fuller version of the
top part of an all-in-one web file as demonstrated above, but now it
occupies the whole file.)

The contents section opens with some bibliographic data. For example:
= (text as Inweb)
	Title: inter
	Author: Graham Nelson
	Purpose: For handling intermediate Inform code
	Language: InC
	Licence: Artistic License 2.0
	Version Number: 1
	Version Name: Axion
=
This is a simply a block of name-value pairs specifying some bibliographic
details; there is then a skipped line, and the roster of sections begins.

Note that the program's |Title| need not be the same as the directory-name
for the web, which is useful if the program has a long or file-system-unfriendly
name. The |Purpose| should be brief enough to fit onto one line. |Licence| can
also have the US spelling, |License|; Inweb treats these as equivalent.
Version number and name are, of course, optional.

The |Language| is the programming language in which the code is written: much
more on that later on, but for now, the important ones are probably |C|, |InC|
and |Plain Text|.

@ After the header block of details, then, we have the roster of sections.
This is like a contents page -- the order is the order in which the sections
are presented on any website, or in any of the larger PDFs woven. For a short,
unchaptered web, we might have for instance:
= (text)
	Sections
	    Program Control
	    Command Line and Configuration
	    Scan Documentation
	    HTML and Javascript
	    Renderer
=
And then Inweb will expect to find, for instance, the section file
|Scan Documentation.w| in the |Sections| directory.

A larger web, however, won't have a "Sections" directory. It may have a
much longer roster, such as:
= (text)
	Preliminaries
	    Preface
	    Thematic Index
	    Licence and Copyright Declaration
	    BNF Grammar
	
	Chapter 1: Definitions
	"In which some globally-used constants are defined and the standard C libraries
	are interfaced with, with all the differences between platforms (Mac OS X,
	Windows, Linux, Solaris, Sugar/XO and so forth) taken care of once and for all."
	    Basic Definitions
	    Platform-Specific Definitions
=
... and so on...
= (text)
	Appendix A: The Standard Rules (Independent Inform 7)
	"This is the body of Inform 7 source text automatically included with every
	project run through the NI compiler, and which defines most of what end users
	see as the Inform language."
	    SR0 - Preamble
	    SR1 - Physical World Model
=
... and so on. Here the sections appear in directories called Preliminaries,
Chapter 1, Chapter 2, ..., Appendix A. (There can't be a Chapter 0, though
there can be Appendix B, C, ..., O; there can also be a Manual chapter, in
the sense of documentation.)

In case of any doubt we can use the following command-line switch to see
how Inweb is actually reading the sections of a web |W|:
= (text as ConsoleText)
	$ inweb/Tangled/inweb W -catalogue -verbose
=
@h Tangling.
At this point, it may be worth experimenting with a second mathematical
example: |inweb/Examples/goldbach|, which is to do with a problem in number
theory called the Goldbach Conjecture. This is a multi-section web, though
really only for the sake of an example: it's still a very small web.

This is once again a C program. Actually building and running this is a
little trouble, of course, and because there are multiple source files, it's
not so easy to keep track of whether the program is built up to date.
So a convenience of Inweb is that it can make makefiles to help with this:
= (text as ConsoleText)
	$ inweb/Tangled/inweb inweb/Examples/goldbach -makefile inweb/Examples/goldbach/goldbach.mk
=
With this done,
= (text as ConsoleText)
	$ make -f inweb/Examples/goldbach/goldbach.mk
=
tangles and then compiles the program as necessary. The tangling part of that
is nothing fancy - as before, it's just
= (text as ConsoleText)
	$ inweb/Tangled/inweb inweb/Examples/goldbach -tangle
=
Assuming all goes well:
= (text as ConsoleText)
	$ inweb/Examples/goldbach/Tangled/goldbach
=
should then print out some results.

@ It is legal in some circumstances to tangle only part of a web. This is done
by specifying a "range", much as will be seen later with weaving - but
because it's not normally meaningful to tangle only part of a program, the
possible ranges are much more restricted. In fact, the only partial tangles
allowed are for chapters or sections marked in the |Contents.w| as being
"Independent". For example:
= (text)
	Appendix A: The Standard Rules (Independent Inform 7)
=
declares that Appendix A is a sort of sidekick program, written in the
language "Inform 7". As a result, it won't be included in a regular |-tangle|,
and to obtain it we have to:
= (text as ConsoleText)
	$ inweb/Tangled/inweb inform7 -tangle A
=
@ In some C programs, it's useful to require that a header file be added to
a tangle. This can be done by adding:
= (text)
	Header: H
=
to the contents page of a web. The heacer file |H| in question should then
be stored in the web's |Headers| subdirectory. (At one time, the Foundation
module used this to bring in a Windows-only header file.)

@h Weaving.
As with all-in-one webs, the commands for weaving are like so:
= (text as ConsoleText)
	$ inweb inweb/Examples/goldbach -weave
	$ inweb inweb/Examples/goldbach -weave-as TeX
=
This will produce single HTML or PDF files of the woven form of the whole
program. (Note that the PDF file now has a cover page: on a web with just
a single section, this wouldn't happen.) But with a growing web, that can
be cumbersome.

@ After setting |-weave| or |-weave-as|, we can also optionally choose a
range. The default range is |all|, so up to now we have implicitly
been running weaves like these:
= (text as ConsoleText)
	$ inweb inweb/Examples/goldbach -weave all
	$ inweb inweb/Examples/goldbach -weave-as TeX all
=
The opposite extreme from |all| is |sections|. This still weaves the entire
web, but now cuts it up into individual files, one for each section. For
example,
= (text as ConsoleText)
	$ inweb inweb/Examples/goldbach -weave sections
=
makes a miniature website of four files:
= (text)
	inweb/Examples/goldbach/Woven/index.html
	inweb/Examples/goldbach/Woven/inweb.css
	inweb/Examples/goldbach/Woven/S-tgc.html
	inweb/Examples/goldbach/Woven/S-tsoe.html
=
Those abbreviated names |S-tgc| and |S-tsoe| are cut down from the full
names of the sections involved, "The Goldbach Conjecture" and "The Sieve
of Eratosthenes". Similarly,
= (text as ConsoleText)
	$ inweb inweb/Examples/goldbach -weave-as TeX sections
=
creates the files:
= (text)
	inweb/Examples/goldbach/Woven/index.html
	inweb/Examples/goldbach/Woven/S-tgc.pdf
	inweb/Examples/goldbach/Woven/S-tsoe.pdf
=
The index file here is a table of contents offering links to the PDFs.

An intermediate level of granularity is the range |chapters|, which makes
sense only for chaptered webs, and puts each chapter into its own file.

@ Ranges can also be used to weave only part of a web:

(a) In a chaptered web, chapters are abbreviated to just their numbers: for
example, the range |2| means "just Chapter 2". The Preliminaries alone is |P|;
the Manual, |M|. Appendix A, B, C are |A|, |B|, |C| and so on. (This is why
Appendices can only run up to L.)

(b) In an unchaptered web, |S| means "all the sections". This is almost but not
quite the same as |all|: the cover sheet (a sort of title page) is omitted.

(c) The abbreviation for a section makes a range of just that section. For
example, |S/tgc| and |S/tsoe| in the Goldbach web example, or |2/ec| for
the "Enumerated Constants" section of Chapter 2 of Inweb itself. Note that
running Inweb with |-catalogue| shows all the sections of a web, and their
abbreviations. If it's a nuisance that these section ranges are hard to
predict, run with |-sequential| to have them simply be |X/s1|, |X/s2|, ...,
within each chapter, where |X| is the chapter range.

@h Weave tags.
An alternative to a range is to specify a tag. Rather than weaving contiguous
pieces of the web, this collates together all those paragraphs with a given
tag. The result is a booklet of extracts.

Most paragraphs are never tagged. A tag is simply a word; paragraphs can have
multiple tags, but for each individual tags they either have it or don't.
A very few tags are automatically applied by Inweb:

If the program is for a C-like language, Inweb automatically tags any
paragraph containing a |typedef struct| with the tag |Structures|. So,
for example,
= (text as ConsoleText)
	$ inweb/Tangled/inweb inweb -weave-tag Structures
=
weaves just the structure definitions culled from a much larger web; this
can make a convenient reference. Similarly, any paragraph containing an
illustration is automatically tagged |Figures|, and any paragraph in an
|InC| web which defines Preform grammar is automatically tagged |Preform|.
(In the Inform project, this is used to generate the PDF of the formal
syntax of the language.)

All other tags must be typed by hand. If the line introducing a paragraph
is marked at the end with |^"Fun"|, then that paragraph will be tagged
as |Fun|, and so on. Paragraphs can have multiple tags:
= (text as Inweb)
	@ ^"Algorithms" ^"History"
	The original version of the program used an in-place insertion sort, but
	...
=
A tag can optionally supply a caption. For example:
= (text as Inweb)
	@ ^"Algorithms: Sorting rulebooks"
	The original version of the program used an in-place insertion sort, but
	...
=
Here the tag is just |Algorithms|, but when a |-weave-to Algorithms| is
performed, the caption text "Sorting rulebooks" will be used in a subheading
in the resulting booklet.

Beyond that, an entire section can be tagged from the |Contents.w| page.
For example:
= (text)
	Sections
	    The Goldbach Conjecture
	    The Sieve of Eratosthenes ^"Greek"
=
tags every paragraph in the section "The Sieve of Eratosthenes" with the
tag |Greek|. In this instance, a caption is not allowed.

Note that if we |-weave-to| a tag which does not exist - or rather, which no
paragraph in the range has - then rather than producing an empty document,
Inweb will halt with an "empty weave request" error.

@h Modules.
Up to now, the webs described have all been self-contained: one web makes
one program, and contains the code in its entirety. But Inweb also supports
"modules". A module is simply a web which provides a compoment of a program
but is not a program in its own right.

For example, all of the Inform tools (including Inweb itself) make use of
a module called |foundation|, which is written in InC and provides
facilities for managing memory, manipulating strings, filenames, and so on.
On the other hand, the Inform project also includes a module called |inter|
which is used only by the core compiler |inform7| and by a wrapper utility
also called |inter|; in fact, |inform7| is entirely divided up into modules,
some of which are used only by itself.

@ It makes little sense to tangle a module on its own. Instead, a web which
wishes to use a module needs to declare this on its |Contents.w| page. This
is done with a list of "imports", after the metadata but before the list
of sections. For example,
= (text)
	Import: foundation
	
	Chapter 1
	    Startup
=
...and so on. When this new web is tangled, the module's code will tangled
into it. Any functions or variables defined in the module will thus be
available to the new web.

However, it makes perfectly good sense to weave a module. For example:
= (text as ConsoleText)
	$ inweb/Tangled/inweb inweb/foundation-module -weave sections
=
@ That's everything there is to say about modules, except where Inweb looks
to find them. When it reads a request from a web |W| to import a module |M|,
it looks for a web directory called |M-module| (note the hyphen). For
example, |Import: fruit| would look for the directory |fruit-module|. Inweb
tries the following locations, in sequence, until it finds it:

(1) Directly inside |W|.
(2) In the directory containing |W| (i.e., one directory higher up).
(3) Directly inside Inweb's own web directory.
(4) In the directory specified by |-import-from D| at the command line, if any.

@h The section catalogue.
Inweb can do a handful of other things. One is to list the contents of a web:

(a) |-catalogue| (or |-catalog|) lists the sections in the web.

(b) |-structures| lists the sections, and all of the structure definitions
made in them (for C-like languages).

(c) |-functions| lists the sections, with all structure definitions and also
all function definitions.

In addition, for debugging purposes, |-scan| shows how Inweb is parsing lines
of source code in the web, and |-verbose| makes it generally print out more
descriptive output.

@h Makefile.
As mentioned earlier, Inweb can construct a suitable makefile for a web:
= (text as ConsoleText)
	$ inweb/Tangled/inweb W -makefile M
=
creates a makefile for the web |W| and stores it in |M|. For example,
= (text as ConsoleText)
	$ inweb/Tangled/inweb inweb -makefile inweb/inweb.mk
=
The makefile is constructed using a prototype file called a "makescript".
Ordinarily the script used will be the one stored in
= (text)
	W/makescript.txt
=
or, if no such file exists, the default one stored in Inweb:
= (text)
	inweb/Materials/makescript.txt
=
but this can be changed by using |-prototype S|, which tells Inweb to use
|S| as the script. If a |-prototype| is given, then there's no need to
specify any one web for Inweb to use: this allows Inweb to construct more
elaborate makefiles for multi-web projects. (This is how the main makefile
for the Inform project is constructed.)

To see how makescripts work, it's easiest simply to look at the default one.

@h Gitignore.
A similar convenience exists for users who want to use the git source control
tool with a web: for example, uploading it to Github.

The files produced by weaving or tangling a web are not significant and should
probably not be subject to source control: they should be "ignored", in git
terminology. This means writing a special file called |.gitignore| which
specifies the files to be ignored. The following does so for a web |W|:
= (text as ConsoleText)
	$ inweb/Tangled/inweb W -gitignore W/.gitignore
=
Once again, Inweb does this by working from a script, this time called
|gitignorescript.txt|.

@h README files.
Repositories at Github customarily have |README.mk| files, in Markdown
syntax, explaining what they are. These of course should probably include
current version numbers, and it's a pain keeping that up to date. For
really complicated repositories, containing multiple webs, some automation
is essential, and once again Inweb can oblige.
= (text as ConsoleText)
	$ inweb/Tangled/inweb W -write-me W/README.mk
=
expands a script called |READMEscript.txt| into |README.mk|. Alternatively,
the script can be specified explicitly:
= (text as ConsoleText)
	$ inweb/Tangled/inweb W -prototype MySpecialThang.txt -write-me W/README.mk
=
@ Everything in the script is copied over verbatim except where the |@| character
is used, which was chosen because it isn't significant in Github's form of
Markdown. |@name(args)| is like a function call (or, in more traditional
language, a macro): it expands out to something depending on the arguments.
|args| is a comma-separated list of fragments of text, which can themselves
contain further uses of |@|. (If these fragments of text need to contain
commas or brackets, they can be put into single quotes: |@thus(4,',')| has
two arguments, |4| and |,|.) Three functions are built in:

(a) |@version(A)| expands to the version number of |A|, which is normally the
path to a web; it then produces the value of the |[[Version Number]]| for
that web. But |A| can also be the filename of an Inform extension, provided
that it ends in |.i7x|, or a few other Inform-specific things for which
Inweb is able to deduce a version number.

(b) |@purpose(A)| is the same, but for the |[[Purpose]]| of a web. It's
blank for everything else.

(c) |@var(A,D)| is more general, and reads the bibliographic datum |D| from
the web indicated by |A|. In fact, |@version(A)| is an abbreviation for
|@var(A,Version Number)| and |@purpose(A)| for |@var(A,Purpose)|, so this
is really the only one needed.

@ It is also possible to define new functions. For example:
= (text)
	@define book(title, path, topic)
	* @title - @topic. Ebook in Indoc format, stored at path @path.
	@end
=
The definition lies between |@define| and |@end| commands. This one takes
three parameters, and inside the definition, their values can be referred
to as |@title|, |@path| and |@topic|. Functions are free to use other
functions:
= (text)
	@define primary(program, language)
	* @program - @purpose(@program) - __@version(@program)__
	@end
=
However, each function needs to have been defined before any line on which
it is actually expanded. A definition of one function |A| can refer to another
function |B| not yet defined; but any actual use of |A| must be made after
both |A| and |B| have been defined. So, basically, declare before use.

@h GitHub Pages support.
If a project is hosted at GitHub, then the GitHub Pages service is the ideal
place to serve a woven copy of the project to the world. To that end,
= (text as ConsoleText)
	$ inweb/Tangled/inweb W -weave-docs
=
performs a weave which is special in two ways:

(a) It uses the pattern called |GitHubPages|, and
(b) Material is by default placed in |W/docs/NAME|, where |NAME| is the
short title of the project.

The reason for this scheme is that GitHub Pages, if enabled, serves a
website using part or all of a git repository. Here, we just want part of
the project's repository to be served: that being so, GitHub mandates that
we use a top-level directory in the repository called |docs|.

|-weave-docs| expects that there will be a page at |W/docs/webs.html| to
give readers a choice of which web to browse -- since some Inweb projects
contain multiple webs. There will later be a way to create the |webs.html|
poge automatically, but for now it's made by hand.

Note that:
= (text as ConsoleText)
	$ inweb/Tangled/inweb W -weave-docs -weave-into P
=
substitutes the path |P| for |W/docs/NAME|. But the files created there still
expect that to be able to link to a |../webs.html|, that is, in the directory
above them.

@h Semantic version numbering and build metadata.
When Inweb reads in a web, it also looks for a file called |build.txt| in
the web's directory; if that isn't there, it looks for the same file in the
current working directory; if that's not there either, never mind.

Such a file contains up to three text fields, all optional:
= (text)
	Prerelease: alpha.1
	Build Date: 23 March 2020
	Build Number: 6Q26
=
The bibliographic variables |Prerelease| and so on are then set from this
file. (They can equally well be set by the Contents section of the web, and
if so then that takes priority.)

The Prerelease and Build Number, if given, are used in combination with the
Version Number (set in the Contents) to produce the semantic version number,
or semver, for the web. For example, if the Contents included:
= (text)
	Version Number: 6.2.12
=
then the semver would be |6.2.12-alpha.1+6Q26|. This is accessible within
the web as the variable |Semantic Version Number|.

For more on semvers, see: https://semver.org

@ A special advancing mechanism exists to update build numbers and dates.
Running Inweb with |-advance-build W| checks the build date for web |W|:
if it differs from today, then it is changed to today, and the build code
is advanced by one.

Running |-advance-build-file B| does this for a stand-alone build file |B|,
without need of a web.
