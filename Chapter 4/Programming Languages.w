[Languages::] Programming Languages.

To characterise the relevant differences in behaviour between the
various programming languages supported.

@h Languages.
The conventions for writing, weaving and tangling a web are really quite
independent of the programming language being written, woven or tangled;
Knuth began literate programming with Pascal, but now uses C, and the original
Pascal webs were mechanically translated into C ones with remarkably little
fuss or bother. Modern LP tools, such as |noweb|, aim to be language-agnostic.
But of course if you act the same on all languages, you give up the benefits
which might follow from knowing something about the languages you actually
write in.

The idea, then, is that Chapters 1 to 3 of the Inweb code treat all
material the same, and Chapter 4 contains all of the funny little exceptions
and special cases for particular programming languages. (This means Chapter 4
can't be understood without having at least browsed Chapters 1 to 3 first.)

Each language supported by Inweb has an instance of the following structure:

=
typedef struct programming_language {
	text_stream *language_name;
	text_stream *file_extension; /* by default output to a file whose name has this extension */
	text_stream *source_file_extension; /* by default input from a file whose name has this extension */
	int supports_enumerations; /* as it will, if it belongs to the C family of languages */
	int supports_namespaces; /* really just for InC */
	METHOD_CALLS
	MEMORY_MANAGEMENT
} programming_language;

programming_language *default_language = NULL;
programming_language *Languages::default(void) { return default_language; }

programming_language *Languages::new_language(text_stream *name, text_stream *ext) {
	programming_language *pl = CREATE(programming_language);
	pl->language_name = Str::duplicate(name);
	pl->file_extension = Str::duplicate(ext);
	pl->supports_enumerations = FALSE;
	pl->source_file_extension = I".w";
	pl->methods = Methods::new_set();
	pl->supports_namespaces = FALSE;
	if (default_language == NULL) default_language = pl;
	return pl;
}

@ =
programming_language *Languages::find_by_name(text_stream *lname) {
	programming_language *pl;
	LOOP_OVER(pl, programming_language)
		if (Str::eq(lname, pl->language_name))
			return pl;
	Errors::fatal_with_text("unsupported programming language '%S'", lname);
	return NULL;
}

@h Creation.
This must be performed very early in Inweb's run.

=
void Languages::create_programming_languages(void) {
	CLike::create_C(); /* must be first, to make C the default language */
	CLike::create_CPP();
	InCSupport::create();
	InformSupport::create_I6();
	InformSupport::create_I7();
	PerlSupport::create();

	/* together with a featureless language: */
	Languages::new_language(I"Plain Text", I".txt");
}

@h Parsing methods.
Really all of the functionality of languages is provided through method calls,
all of them made from this section. That means a lot of simple wrapper routines
which don't do very much. This section may still be useful to read, since it
documents what amounts to an API.

We begin with parsing extensions. When these are used, we have already read
the web into chapters, sections and paragraphs, but for some languages we will
need a more detailed picture.

|FURTHER_PARSING_PAR_MTID| is "further" in that it is called when the main
parser has finished work; it typically looks over the whole web for something
of interest.

@e FURTHER_PARSING_PAR_MTID

=
VMETHOD_TYPE(FURTHER_PARSING_PAR_MTID, programming_language *pl, web *W)
void Languages::further_parsing(web *W, programming_language *pl) {
	VMETHOD_CALL(pl, FURTHER_PARSING_PAR_MTID, W);
}

@ |SUBCATEGORISE_LINE_PAR_MTID| looks at a single line, after the main parser
has given it a category. The idea is not so much to second-guess the parser
(although we can) but to change to a more exotic category which it would
otherwise never produce.

@e SUBCATEGORISE_LINE_PAR_MTID

=
VMETHOD_TYPE(SUBCATEGORISE_LINE_PAR_MTID, programming_language *pl, source_line *L)
void Languages::subcategorise_line(programming_language *pl, source_line *L) {
	VMETHOD_CALL(pl, SUBCATEGORISE_LINE_PAR_MTID, L);
}

@ Comments have different syntax in different languages. The method here is
expected to look for a comment on the |line|, and if so to return |TRUE|,
but not before splicing the non-comment parts of the line before and
within the comment into the supplied strings.

@e PARSE_COMMENT_TAN_MTID

=
IMETHOD_TYPE(PARSE_COMMENT_TAN_MTID, programming_language *pl, text_stream *line, text_stream *before, text_stream *within)

int Languages::parse_comment(programming_language *pl,
	text_stream *line, text_stream *before, text_stream *within) {
	int rv = FALSE;
	IMETHOD_CALL(rv, pl, PARSE_COMMENT_TAN_MTID, line, before, within);
	return rv;
}

@h Tangling methods.
We take these roughly in order of their effects on the tangled output, from
the top to the bottom of the file.

The top of the tangled file is a header called the "shebang". By default,
there's nothing there, but |SHEBANG_TAN_MTID| allows the language to add one.
For example, Perl prints |#!/usr/bin/perl| here.

@e SHEBANG_TAN_MTID

=
VMETHOD_TYPE(SHEBANG_TAN_MTID, programming_language *pl, text_stream *OUT, web *W, tangle_target *target)
void Languages::shebang(OUTPUT_STREAM, programming_language *pl, web *W, tangle_target *target) {
	VMETHOD_CALL(pl, SHEBANG_TAN_MTID, OUT, W, target);
}

@ Next is the disclaimer, text warning the human reader that she is looking
at tangled (therefore not original) material.

@e SUPPRESS_DISCLAIMER_TAN_MTID

=
IMETHOD_TYPE(SUPPRESS_DISCLAIMER_TAN_MTID, programming_language *pl)
void Languages::disclaimer(text_stream *OUT, programming_language *pl, web *W, tangle_target *target) {
	int rv = FALSE;
	IMETHOD_CALLV(rv, pl, SUPPRESS_DISCLAIMER_TAN_MTID);
	if (rv == FALSE)
		Languages::comment(OUT, pl, I"Tangled output generated by inweb: do not edit");
}

@ Next is the disclaimer, text warning the human reader that she is looking
at tangled (therefore not original) material.

@e ADDITIONAL_EARLY_MATTER_TAN_MTID

=
VMETHOD_TYPE(ADDITIONAL_EARLY_MATTER_TAN_MTID, programming_language *pl, text_stream *OUT, web *W, tangle_target *target)
void Languages::additional_early_matter(text_stream *OUT, programming_language *pl, web *W, tangle_target *target) {
	VMETHOD_CALL(pl, ADDITIONAL_EARLY_MATTER_TAN_MTID, OUT, W, target);
}

@ A tangled file then normally declares "definitions". The following write a
definition of the constant named |term| as the value given. If the value spans
multiple lines, the first-line part is supplied to |START_DEFN_TAN_MTID| and
then subsequent lines are fed in order to |PROLONG_DEFN_TAN_MTID|. At the end,
|END_DEFN_TAN_MTID| is called.

@e START_DEFN_TAN_MTID
@e PROLONG_DEFN_TAN_MTID
@e END_DEFN_TAN_MTID

=
IMETHOD_TYPE(START_DEFN_TAN_MTID, programming_language *pl, text_stream *OUT, text_stream *term, text_stream *start, section *S, source_line *L)
IMETHOD_TYPE(PROLONG_DEFN_TAN_MTID, programming_language *pl, text_stream *OUT, text_stream *more, section *S, source_line *L)
IMETHOD_TYPE(END_DEFN_TAN_MTID, programming_language *pl, text_stream *OUT, section *S, source_line *L)

void Languages::start_definition(OUTPUT_STREAM, programming_language *pl,
	text_stream *term, text_stream *start, section *S, source_line *L) {
	int rv = FALSE;
	IMETHOD_CALL(rv, pl, START_DEFN_TAN_MTID, OUT, term, start, S, L);
	if (rv == FALSE)
		Main::error_in_web(I"this programming language does not support @d", L);
}

void Languages::prolong_definition(OUTPUT_STREAM, programming_language *pl,
	text_stream *more, section *S, source_line *L) {
	int rv = FALSE;
	IMETHOD_CALL(rv, pl, PROLONG_DEFN_TAN_MTID, OUT, more, S, L);
	if (rv == FALSE)
		Main::error_in_web(I"this programming language does not support multiline @d", L);
}

void Languages::end_definition(OUTPUT_STREAM, programming_language *pl,
	section *S, source_line *L) {
	int rv = FALSE;
	IMETHOD_CALL(rv, pl, END_DEFN_TAN_MTID, OUT, S, L);
}

@ Then we have some "predeclarations"; for example, for C-like languages we
automatically predeclare all functions, obviating the need for header files.

@e ADDITIONAL_PREDECLARATIONS_TAN_MTID

=
IMETHOD_TYPE(ADDITIONAL_PREDECLARATIONS_TAN_MTID, programming_language *pl, text_stream *OUT, web *W)
void Languages::additional_predeclarations(OUTPUT_STREAM, programming_language *pl, web *W) {
	VMETHOD_CALL(pl, ADDITIONAL_PREDECLARATIONS_TAN_MTID, OUT, W);
}

@ So much for the special material at the top of a tangle: now we're into
the more routine matter, tangling ordinary paragraphs into code.

Languages have the ability to suppress paragraph macro expansion:

@e SUPPRESS_EXPANSION_TAN_MTID

=
IMETHOD_TYPE(SUPPRESS_EXPANSION_TAN_MTID, programming_language *pl, text_stream *material)
int Languages::allow_expansion(programming_language *pl, text_stream *material) {
	int rv = FALSE;
	IMETHOD_CALL(rv, pl, SUPPRESS_EXPANSION_TAN_MTID, material);
	return (rv)?FALSE:TRUE;
}

@ Inweb supports very few "tangle commands", that is, instructions written
inside double squares |[[Thus]]|. These can be handled by attaching methods
as follows, which return |TRUE| if they recognised and acted on the command.

@e TANGLE_COMMAND_TAN_MTID

=
IMETHOD_TYPE(TANGLE_COMMAND_TAN_MTID, programming_language *pl, text_stream *OUT, text_stream *data)

int Languages::special_tangle_command(OUTPUT_STREAM, programming_language *pl, text_stream *data) {
	int rv = FALSE;
	IMETHOD_CALL(rv, pl, TANGLE_COMMAND_TAN_MTID, OUT, data);
	return rv;
}

@ The following methods make it possible for languages to tangle unorthodox
lines into code. Ordinarily, only |CODE_BODY_LCAT| lines are tangled, but
we can intervene to say that we want to tangle a different line; and if we
do so, we should then act on that basis.

@e WILL_TANGLE_EXTRA_LINE_TAN_MTID
@e TANGLE_EXTRA_LINE_TAN_MTID

=
IMETHOD_TYPE(WILL_TANGLE_EXTRA_LINE_TAN_MTID, programming_language *pl, source_line *L)
VMETHOD_TYPE(TANGLE_EXTRA_LINE_TAN_MTID, programming_language *pl, text_stream *OUT, source_line *L)
int Languages::will_insert_in_tangle(programming_language *pl, source_line *L) {
	int rv = FALSE;
	IMETHOD_CALL(rv, pl, WILL_TANGLE_EXTRA_LINE_TAN_MTID, L);
	return rv;	
}
void Languages::insert_in_tangle(OUTPUT_STREAM, programming_language *pl, source_line *L) {
	VMETHOD_CALL(pl, TANGLE_EXTRA_LINE_TAN_MTID, OUT, L);
}

@ In order for C compilers to report C syntax errors on the correct line,
despite rearranging by automatic tools, C conventionally recognises the
preprocessor directive |#line| to tell it that a contiguous extract follows
from the given file; we generate this automatically.

@e INSERT_LINE_MARKER_TAN_MTID

=
VMETHOD_TYPE(INSERT_LINE_MARKER_TAN_MTID, programming_language *pl, text_stream *OUT, source_line *L)
void Languages::insert_line_marker(OUTPUT_STREAM, programming_language *pl, source_line *L) {
	VMETHOD_CALL(pl, INSERT_LINE_MARKER_TAN_MTID, OUT, L);
}

@ The following hooks are provided so that we can top and/or tail the expansion
of paragraph macros in the code. For example, C-like languages, use this to
splice |{| and |}| around the expanded matter.

@e BEFORE_MACRO_EXPANSION_TAN_MTID
@e AFTER_MACRO_EXPANSION_TAN_MTID

=
VMETHOD_TYPE(BEFORE_MACRO_EXPANSION_TAN_MTID, programming_language *pl, text_stream *OUT, para_macro *pmac)
VMETHOD_TYPE(AFTER_MACRO_EXPANSION_TAN_MTID, programming_language *pl, text_stream *OUT, para_macro *pmac)
void Languages::before_macro_expansion(OUTPUT_STREAM, programming_language *pl, para_macro *pmac) {
	VMETHOD_CALL(pl, BEFORE_MACRO_EXPANSION_TAN_MTID, OUT, pmac);
}
void Languages::after_macro_expansion(OUTPUT_STREAM, programming_language *pl, para_macro *pmac) {
	VMETHOD_CALL(pl, AFTER_MACRO_EXPANSION_TAN_MTID, OUT, pmac);
}

@ It's a sad necessity, but sometimes we have to unconditionally tangle code
for a preprocessor to conditionally read: that is, to tangle code which contains
|#ifdef| or similar preprocessor directive.

@e OPEN_IFDEF_TAN_MTID
@e CLOSE_IFDEF_TAN_MTID

=
VMETHOD_TYPE(OPEN_IFDEF_TAN_MTID, programming_language *pl, text_stream *OUT, text_stream *symbol, int sense)
VMETHOD_TYPE(CLOSE_IFDEF_TAN_MTID, programming_language *pl, text_stream *OUT, text_stream *symbol, int sense)
void Languages::open_ifdef(OUTPUT_STREAM, programming_language *pl, text_stream *symbol, int sense) {
	VMETHOD_CALL(pl, OPEN_IFDEF_TAN_MTID, OUT, symbol, sense);
}
void Languages::close_ifdef(OUTPUT_STREAM, programming_language *pl, text_stream *symbol, int sense) {
	VMETHOD_CALL(pl, CLOSE_IFDEF_TAN_MTID, OUT, symbol, sense);
}

@ Now a routine to tangle a comment. Languages without comment should write nothing.

@e COMMENT_TAN_MTID

=
VMETHOD_TYPE(COMMENT_TAN_MTID, programming_language *pl, text_stream *OUT, text_stream *comm)
void Languages::comment(OUTPUT_STREAM, programming_language *pl, text_stream *comm) {
	VMETHOD_CALL(pl, COMMENT_TAN_MTID, OUT, comm);
}

@ The inner code tangler now acts on all code known not to contain CWEB
macros or double-square substitutions. In almost every language this simply
passes the code straight through, printing |original| to |OUT|.

@e TANGLE_CODE_UNUSUALLY_TAN_MTID

=
IMETHOD_TYPE(TANGLE_CODE_UNUSUALLY_TAN_MTID, programming_language *pl, text_stream *OUT, text_stream *original)
void Languages::tangle_code(OUTPUT_STREAM, programming_language *pl, text_stream *original) {
	int rv = FALSE;
	IMETHOD_CALL(rv, pl, TANGLE_CODE_UNUSUALLY_TAN_MTID, OUT, original);
	if (rv == FALSE) WRITE("%S", original);
}

@ We finally reach the bottom of the tangled file, a footer called the "gnabehs":

@e GNABEHS_TAN_MTID

=
VMETHOD_TYPE(GNABEHS_TAN_MTID, programming_language *pl, text_stream *OUT, web *W)
void Languages::gnabehs(OUTPUT_STREAM, programming_language *pl, web *W) {
	VMETHOD_CALL(pl, GNABEHS_TAN_MTID, OUT, W);
}

@ But we still aren't quite done, because some languages need to produce
sidekick files alongside the main tangle file. This method exists to give
them the opportunity.

@e ADDITIONAL_TANGLING_TAN_MTID

=
VMETHOD_TYPE(ADDITIONAL_TANGLING_TAN_MTID, programming_language *pl, web *W, tangle_target *target)
void Languages::additional_tangling(programming_language *pl, web *W, tangle_target *target) {
	VMETHOD_CALL(pl, ADDITIONAL_TANGLING_TAN_MTID, W, target);
}

@h Weaving methods.
This metnod shouldn't do any actual weaving: it should simply initialise
anything that the language in question might need later.

@e BEGIN_WEAVE_WEA_MTID

=
VMETHOD_TYPE(BEGIN_WEAVE_WEA_MTID, programming_language *pl, section *S, weave_target *wv)
void Languages::begin_weave(section *S, weave_target *wv) {
	VMETHOD_CALL(S->sect_language, BEGIN_WEAVE_WEA_MTID, S, wv);
}

@ This method allows languages to tell the weaver to ignore certain lines.

@e SKIP_IN_WEAVING_WEA_MTID

=
IMETHOD_TYPE(SKIP_IN_WEAVING_WEA_MTID, programming_language *pl, weave_target *wv, source_line *L)
int Languages::skip_in_weaving(programming_language *pl, weave_target *wv, source_line *L) {
	int rv = FALSE;
	IMETHOD_CALL(rv, pl, SKIP_IN_WEAVING_WEA_MTID, wv, L);
	return rv;
}

@ Languages most do syntax colouring by having a "state" (this is now inside
a comment, inside qupted text, and so on); the following method is provided
to reset that state, if so. Inweb runs it once per paragraph for safety's
sake, which minimises the knock-on effect of any colouring mistakes.

@e RESET_SYNTAX_COLOURING_WEA_MTID

=
VMETHOD_TYPE(RESET_SYNTAX_COLOURING_WEA_MTID, programming_language *pl)
void Languages::reset_syntax_colouring(programming_language *pl) {
	VMETHOD_CALLV(pl, RESET_SYNTAX_COLOURING_WEA_MTID);
}

@ And this is where colouring is done. The model here is that the code to
be coloured is in |matter|. A parallel text called |colouring| matches it
up, chatacter for character. For example, a language might colour like so:

	|int x = 55;|
	|rrrpipppnnp|

The initial state is |ppp...p|, everything "plain", unless the following
method does something to change that.

@e SYNTAX_COLOUR_WEA_MTID

@d MACRO_COLOUR 		'm'
@d FUNCTION_COLOUR		'f'
@d RESERVED_COLOUR		'r'
@d ELEMENT_COLOUR		'e'
@d IDENTIFIER_COLOUR	'i'
@d CHAR_LITERAL_COLOUR	'c'
@d CONSTANT_COLOUR		'n'
@d STRING_COLOUR		's'
@d PLAIN_COLOUR			'p'
@d EXTRACT_COLOUR		'x'
@d COMMENT_COLOUR		'!'

=
int colouring_state = PLAIN_COLOUR;

IMETHOD_TYPE(SYNTAX_COLOUR_WEA_MTID, programming_language *pl, text_stream *OUT, weave_target *wv, web *W,
	chapter *C, section *S, source_line *L, text_stream *matter, text_stream *colouring)
int Languages::syntax_colour(OUTPUT_STREAM, programming_language *pl, weave_target *wv,
	web *W, chapter *C, section *S, source_line *L, text_stream *matter, text_stream *colouring) {
	Str::copy(colouring, matter);
	for (int i=0; i < Str::len(matter); i++) Str::put_at(colouring, i, PLAIN_COLOUR);
	int rv = FALSE;
	if (L->category != TEXT_EXTRACT_LCAT) {
		IMETHOD_CALL(rv, pl, SYNTAX_COLOUR_WEA_MTID, OUT, wv, W, C, S, L, matter, colouring);
	}
	return rv;
}

@ This method is called for each code line to be woven. If it returns |FALSE|, the
weaver carries on in the normal way. If not, it does nothing, assuming that the
method has already woven something more attractive.

@e WEAVE_CODE_LINE_WEA_MTID

=
IMETHOD_TYPE(WEAVE_CODE_LINE_WEA_MTID, programming_language *pl, text_stream *OUT, weave_target *wv, web *W,
	chapter *C, section *S, source_line *L, text_stream *matter, text_stream *concluding_comment)
int Languages::weave_code_line(OUTPUT_STREAM, programming_language *pl, weave_target *wv,
	web *W, chapter *C, section *S, source_line *L, text_stream *matter, text_stream *concluding_comment) {
	int rv = FALSE;
	IMETHOD_CALL(rv, pl, WEAVE_CODE_LINE_WEA_MTID, OUT, wv, W, C, S, L, matter, concluding_comment);
	return rv;
}

@ When Inweb creates a new |^"Theme"|, it lets everybody know about that.

@e NOTIFY_NEW_TAG_WEA_MTID

=
VMETHOD_TYPE(NOTIFY_NEW_TAG_WEA_MTID, programming_language *pl, theme_tag *tag)
void Languages::new_tag_declared(theme_tag *tag) {
	programming_language *pl;
	LOOP_OVER(pl, programming_language)
		VMETHOD_CALL(pl, NOTIFY_NEW_TAG_WEA_MTID, tag);
}

@h Analysis methods.
These are really a little miscellaneous, but they all have to do with looking
at the code in a web and working out what's going on, rather than producing
any weave or tangle output.

This one provides details to add to the section catalogue if |-structures|
or |-functions| is used at the command line:

@e CATALOGUE_ANA_MTID

=
VMETHOD_TYPE(CATALOGUE_ANA_MTID, programming_language *pl, section *S, int functions_too)
void Languages::catalogue(programming_language *pl, section *S, int functions_too) {
	VMETHOD_CALL(pl, CATALOGUE_ANA_MTID, S, functions_too);
}

@ The "preweave analysis" is an opportunity to look through the code before
any weaving of it occurs. It's never called on a tangle run. These methods
are called first and last in the process, respectively. (What happens in
between is essentially that Inweb looks for identifiers, for later syntax
colouring purposes.)

@e EARLY_PREWEAVE_ANALYSIS_ANA_MTID
@e LATE_PREWEAVE_ANALYSIS_ANA_MTID

=
VMETHOD_TYPE(EARLY_PREWEAVE_ANALYSIS_ANA_MTID, programming_language *pl, web *W)
VMETHOD_TYPE(LATE_PREWEAVE_ANALYSIS_ANA_MTID, programming_language *pl, web *W)
void Languages::early_preweave_analysis(programming_language *pl, web *W) {
	VMETHOD_CALL(pl, EARLY_PREWEAVE_ANALYSIS_ANA_MTID, W);
}
void Languages::late_preweave_analysis(programming_language *pl, web *W) {
	VMETHOD_CALL(pl, LATE_PREWEAVE_ANALYSIS_ANA_MTID, W);
}

@ And finally: in InC only, a few structure element names are given very slightly
special treatment, and this method decides which.

@e SHARE_ELEMENT_ANA_MTID

=
IMETHOD_TYPE(SHARE_ELEMENT_ANA_MTID, programming_language *pl, text_stream *element_name)
int Languages::share_element(programming_language *pl, text_stream *element_name) {
	int rv = FALSE;
	IMETHOD_CALL(rv, pl, SHARE_ELEMENT_ANA_MTID, element_name);
	return rv;
}
