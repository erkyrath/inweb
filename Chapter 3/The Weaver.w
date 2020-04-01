[Weaver::] The Weaver.

To weave a portion of the code into instructions for TeX.

@h The Master Weaver.
Here's what has happened so far, on a weave run of Inweb: on any other
sort of run, of course, we would never be in this section of code. The web was
read completely into memory and fully parsed. A request was then made either
to swarm a mass of individual weaves, or to make just a single weave, with the
target in each case being identified by its range. A further decoding layer
then translated each range into rather more basic details of what to weave and
where to put the result: and so we arrive at the front door of the routine
|Weaver::weave_source| below.

=
int Weaver::weave_source(web *W, weave_target *wv) {
	text_stream TO_struct;
	text_stream *OUT = &TO_struct;
	if (STREAM_OPEN_TO_FILE(OUT, wv->weave_to, UTF8_ENC) == FALSE)
		Errors::fatal_with_file("unable to write woven file", wv->weave_to);

	@<Weave the banner@>;
	if ((Str::len(wv->cover_sheet_to_use) > 0) && (W->md->no_sections > 1))
		@<Weave head of the cover sheet, if any@>;
	int lines_woven = 0;
	section *latest_section = NULL;
	@<Weave the body of the material@>;
	if ((Str::len(wv->cover_sheet_to_use) > 0) && (W->md->no_sections > 1))
		@<Weave tail of the cover sheet, if any@>;
	@<Weave the rennab@>;

	STREAM_CLOSE(OUT);
	return lines_woven;
}

@<Weave the banner@> =
	TEMPORARY_TEXT(banner);
	WRITE_TO(banner, "Weave of '%S' generated by %s", wv->booklet_title, INWEB_BUILD);
	Formats::top(OUT, wv, banner);
	DISCARD_TEXT(banner);

@<Weave head of the cover sheet, if any@> =
	if (!(Bibliographic::data_exists(W->md, I"Booklet Title")))
		Bibliographic::set_datum(W->md, I"Booklet Title", wv->booklet_title);
	Indexer::cover_sheet_maker(OUT, W, wv->cover_sheet_to_use, wv, WEAVE_FIRST_HALF);

@<Weave the body of the material@> =
	weaver_state state_at; weaver_state *state = &state_at;
	@<Start the weaver with a clean slate@>;
	chapter *C;
	section *S;
	LOOP_OVER_LINKED_LIST(C, chapter, W->chapters)
		if (C->md->imported == FALSE) {
			Str::clear(state->chaptermark);
			LOOP_OVER_LINKED_LIST(S, section, C->sections)
				if (Reader::range_within(S->sect_range, wv->weave_range)) {
					latest_section = S;
					Languages::begin_weave(S, wv);
					Str::clear(state->sectionmark);
					@<Weave this section@>;
				}
		}

@<Weave tail of the cover sheet, if any@> =
	if (!(Bibliographic::data_exists(W->md, I"Booklet Title")))
		Bibliographic::set_datum(W->md, I"Booklet Title", wv->booklet_title);
	Indexer::cover_sheet_maker(OUT, W, wv->cover_sheet_to_use, wv, WEAVE_SECOND_HALF);

@<Weave the rennab@> =
	TEMPORARY_TEXT(rennab);
	WRITE_TO(rennab, "End of weave");
	Formats::tail(OUT, wv, rennab, latest_section);
	DISCARD_TEXT(rennab);

@h The state.
We can now begin on a clean page, by initialising the state of the weaver:

@e REGULAR_MATERIAL from 1
@e MACRO_MATERIAL          /* when a macro is being defined... */
@e DEFINITION_MATERIAL     /* ...versus when an |@d| definition is being made */
@e CODE_MATERIAL           /* verbatim code */

=
typedef struct weaver_state {
	int kind_of_material; /* one of the enumerated |*_MATERIAL| constants above */
	int line_break_pending; /* insert a line break before the next woven line? */
	int next_heading_without_vertical_skip;
	int show_section_toc_soon; /* is a table of contents for the section imminent? */
	int horizontal_rule_just_drawn;
	int in_run_of_definitions;
	struct section *last_extract_from;
	struct paragraph *last_endnoted_para;
	int substantive_comment;
	struct text_stream *chaptermark;
	struct text_stream *sectionmark;
} weaver_state;

@<Start the weaver with a clean slate@> =
	state->kind_of_material = REGULAR_MATERIAL;
	state->line_break_pending = FALSE;
	state->next_heading_without_vertical_skip = FALSE;
	state->show_section_toc_soon = FALSE;
	state->horizontal_rule_just_drawn = FALSE;
	state->in_run_of_definitions = FALSE;
	state->last_extract_from = NULL;
	state->last_endnoted_para = NULL;
	state->substantive_comment = FALSE;
	state->chaptermark = Str::new();
	state->sectionmark = Str::new();

@h Weaving a section.

@<Weave this section@> =
	paragraph *current_paragraph = NULL;
	for (source_line *L = S->first_line; L; L = L->next_line) {
		if ((Tags::tagged_with(L->owning_paragraph, wv->theme_match)) &&
			(Languages::skip_in_weaving(S->sect_language, wv, L) == FALSE)) {
			lines_woven++;
			@<Weave this line@>;
		}
	}
	source_line *L = NULL;
	@<Complete any started but not-fully-woven paragraph@>;

@<Weave this line@> =
	/* In principle, all of these source lines should be woven, but... */
	@<Certain categories of line are excluded from the weave@>;
	@<Respond to any commands aimed at the weaver, and otherwise skip commands@>;

	/* Some of the more baroque front matter of a section... */
	@<Weave the Purpose marker as a little heading@>;
	@<If we need to work in a section table of contents and this is a blank line, do it now@>;
	@<Deal with the Interface passage@>;
	@<Weave the Definitions marker as a little heading@>;
	@<Weave the section bar as a horizontal rule@>;

	/* The crucial junction point between modes... */
	@<Deal with the marker for the start of a new paragraph, section or chapter@>;

	/* With all exotica dealt with, we now just have material to weave verbatim... */
	TEMPORARY_TEXT(matter); Str::copy(matter, L->text);
	if (L->is_commentary) @<Weave verbatim matter in commentary style@>
	else @<Weave verbatim matter in code style@>;
	DISCARD_TEXT(matter);

@h Reasons to skip things.
We skip these because we weave their contents in some other way:

@<Certain categories of line are excluded from the weave@> =
	if (L->category == INTERFACE_BODY_LCAT) continue;
	if (L->category == PURPOSE_BODY_LCAT) continue;
	if (L->category == BEGIN_CODE_LCAT) {
		state->line_break_pending = FALSE;
		continue;
	}

@ And lastly we ignore commands, or act on them if they happen to be aimed
at us; but we don't weave them into the output, that's for sure.

@<Respond to any commands aimed at the weaver, and otherwise skip commands@> =
	if (L->category == COMMAND_LCAT) {
		if (L->command_code == PAGEBREAK_CMD) Formats::pagebreak(OUT, wv);
		if (L->command_code == GRAMMAR_INDEX_CMD) InCSupport::weave_grammar_index(OUT);
		if (L->command_code == FIGURE_CMD) @<Weave a figure@>;
		/* Otherwise assume it was a tangler command, and ignore it here */
		continue;
	}

@<Weave a figure@> =
	text_stream *figname = L->text_operand;
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, figname, L"(%d+)cm: (%c+)")) {
		if (S->md->using_syntax > V1_SYNTAX)
			Parser::wrong_version(S->md->using_syntax, L, "[[Figure: Xcm:...]]", V1_SYNTAX);
		Formats::figure(OUT, wv, mr.exp[1], Str::atoi(mr.exp[0], 0), -1);
	} else if (Regexp::match(&mr, figname, L"(%c+) width (%d+)cm")) {
		if (S->md->using_syntax < V2_SYNTAX)
			Parser::wrong_version(S->md->using_syntax, L, "[[F width Xcm]]", V2_SYNTAX);
		Formats::figure(OUT, wv, mr.exp[0], Str::atoi(mr.exp[1], 0), -1);
	} else if (Regexp::match(&mr, figname, L"(%c+) height (%d+)cm")) {
		if (S->md->using_syntax < V2_SYNTAX)
			Parser::wrong_version(S->md->using_syntax, L, "[[F height Xcm]]", V2_SYNTAX);
		Formats::figure(OUT, wv, mr.exp[0], -1, Str::atoi(mr.exp[1], 0));
	} else {
		Formats::figure(OUT, wv, figname, -1, -1);
	}
	Regexp::dispose_of(&mr);

@h Headings.
The purpose is set with a little heading. Its operand is that part of
the purpose-text which is on the opening line; the rest follows on
subsequent lines until the next blank.

@<Weave the Purpose marker as a little heading@> =
	if (L->category == PURPOSE_LCAT) {
		Formats::subheading(OUT, wv, 2, S->sect_purpose, NULL);
		Weaver::weave_table_of_contents(OUT, wv, S);
		continue;
	}

@ This normally appears just after the Purpose subheading:

@<If we need to work in a section table of contents and this is a blank line, do it now@> =
	if ((state->show_section_toc_soon == 1) && (Regexp::string_is_white_space(L->text))) {
		state->show_section_toc_soon = FALSE;
		if (Weaver::weave_table_of_contents(OUT, wv, S))
			state->horizontal_rule_just_drawn = TRUE;
		else
			state->horizontal_rule_just_drawn = FALSE;
	}

@ After which we have the Interface -- if we're in Inweb syntax version 1 --
but it weaves nothing:

@<Deal with the Interface passage@> =
	if (L->category == INTERFACE_LCAT) {
		state->horizontal_rule_just_drawn = FALSE;
		continue;
	}

@ And another little heading, again visible only in syntax version 1...

@<Weave the Definitions marker as a little heading@> =
	if (L->category == DEFINITIONS_LCAT) {
		Formats::subheading(OUT, wv, 2, I"Definitions", NULL);
		state->next_heading_without_vertical_skip = TRUE;
		state->horizontal_rule_just_drawn = FALSE;
		continue;
	}

@ ...with the section bar to follow. The bar line completes any half-finished
paragraph and is set as a horizontal rule (and, once again, can exist only
in a version 1 web).

@<Weave the section bar as a horizontal rule@> =
	if (L->category == BAR_LCAT) {
		@<Complete any started but not-fully-woven paragraph@>;
		state->kind_of_material = REGULAR_MATERIAL;
		state->next_heading_without_vertical_skip = TRUE;
		if (state->horizontal_rule_just_drawn == FALSE) Formats::bar(OUT, wv);
		continue;
	}

@h Commentary matter.
Typographically this is a fairly simple business: it's almost the case that
we only have to transcribe it. But not quite!

@<Weave verbatim matter in commentary style@> =
	@<Weave displayed source in its own special style@>;
	@<Weave a blank line as a thin vertical skip and paragraph break@>;
	@<Weave bracketed list indications at start of line into indentation@>;
	@<Weave tabbed code material as a new indented paragraph@>;
	state->substantive_comment = TRUE;
	WRITE_TO(matter, "\n");
	Formats::text(OUT, wv, matter);
	continue;

@ Displayed source is the material marked with |>>| arrows in column 1.

@<Weave displayed source in its own special style@> =
	if (L->category == SOURCE_DISPLAY_LCAT) {
		Formats::display_line(OUT, wv, L->text_operand);
		continue;
	}

@ Our style is to use paragraphs without initial-line indentation, so we
add a vertical skip between them to show the division more clearly.

@<Weave a blank line as a thin vertical skip and paragraph break@> =
	if (Regexp::string_is_white_space(matter)) {
		if ((L->next_line) && (L->next_line->category == COMMENT_BODY_LCAT) &&
			(state->substantive_comment)) {
			match_results mr = Regexp::create_mr();
			if ((state->kind_of_material != CODE_MATERIAL) ||
				(Regexp::match(&mr, matter, L"\t|(%c*)|(%c*?)")))
				Formats::blank_line(OUT, wv, TRUE);
			Regexp::dispose_of(&mr);	
		}
		continue;
	}

@ Here our extension is simply to provide a tidier way to use TeX's standard
|\item| and |\itemitem| macros for indented list items.

@<Weave bracketed list indications at start of line into indentation@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, matter, L"%(...%) (%c*)")) { /* continue single */
		Formats::change_material(OUT, wv, state->kind_of_material, REGULAR_MATERIAL,
			state->substantive_comment);
		state->kind_of_material = REGULAR_MATERIAL;
		Formats::item(OUT, wv, 1, I"");
		Str::copy(matter, mr.exp[0]);
	} else if (Regexp::match(&mr, matter, L"%(-...%) (%c*)")) { /* continue double */
		Formats::change_material(OUT, wv, state->kind_of_material, REGULAR_MATERIAL,
			state->substantive_comment);
		state->kind_of_material = REGULAR_MATERIAL;
		Formats::item(OUT, wv, 2, I"");
		Str::copy(matter, mr.exp[0]);
	} else if (Regexp::match(&mr, matter, L"%((%i+)%) (%c*)")) { /* begin single */
		Formats::change_material(OUT, wv, state->kind_of_material, REGULAR_MATERIAL,
			state->substantive_comment);
		state->kind_of_material = REGULAR_MATERIAL;
		Formats::item(OUT, wv, 1, mr.exp[0]);
		Str::copy(matter, mr.exp[1]);
	} else if (Regexp::match(&mr, matter, L"%(-(%i+)%) (%c*)")) { /* begin double */
		Formats::change_material(OUT, wv, state->kind_of_material, REGULAR_MATERIAL,
			state->substantive_comment);
		state->kind_of_material = REGULAR_MATERIAL;
		Formats::item(OUT, wv, 2, mr.exp[0]);
		Str::copy(matter, mr.exp[1]);
	}
	Regexp::dispose_of(&mr);

@ Finally, matter encased in vertical strokes one tab stop in from column 1
in the source is set indented in code style.

@<Weave tabbed code material as a new indented paragraph@> =
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, matter, L"\t|(%c*)|(%c*?)")) {
		if (state->kind_of_material != CODE_MATERIAL) {
			Formats::change_material(OUT, wv, state->kind_of_material, CODE_MATERIAL, TRUE);
			state->kind_of_material = CODE_MATERIAL;
		}
		TEMPORARY_TEXT(original);
 		Str::copy(original, mr.exp[0]);
		Str::copy(matter, mr.exp[1]);
		TEMPORARY_TEXT(colouring);
		for (int i=0; i<Str::len(original); i++) PUT_TO(colouring, PLAIN_COLOUR);
		Formats::source_code(OUT, wv, 1, I"", original, colouring, I"", TRUE, TRUE, FALSE);
		Formats::text(OUT, wv, matter);
		DISCARD_TEXT(colouring);
		DISCARD_TEXT(original);
		continue;
	} else if (state->kind_of_material != REGULAR_MATERIAL) {
		Formats::change_material(OUT, wv, state->kind_of_material, REGULAR_MATERIAL, TRUE);
		state->kind_of_material = REGULAR_MATERIAL;
	}
	Regexp::dispose_of(&mr);

@h Code-like matter.
Even though Inweb's approach, unlike |CWEB|'s, is to respect the layout
of the original, this is still quite typographically complex: commentary
and macro usage is rendered differently.

@<Weave verbatim matter in code style@> =
	@<Enter beginlines/endlines mode if necessary@>;
	@<Weave a blank line as a thin vertical skip@>;

	int tab_stops_of_indentation = 0;
	@<Convert leading space in line matter to a number of tab stops@>;

	TEMPORARY_TEXT(prefatory);
	TEMPORARY_TEXT(concluding_comment);
	@<Extract any comment matter ending the line to be set in italic@>;
	@<Give constant definition lines slightly fancier openings@>;

	if (Languages::weave_code_line(OUT, S->sect_language, wv,
		W, C, S, L, matter, concluding_comment)) continue;

	TEMPORARY_TEXT(colouring);
	Languages::syntax_colour(OUT, S->sect_language, wv, W, C, S, L, matter, colouring);

	int found = 0;
	@<Find macro usages and adjust syntax colouring accordingly@>;
	if (Str::len(prefatory) > 0) {
		state->in_run_of_definitions = TRUE;
	} else {
		if (state->in_run_of_definitions) Formats::after_definitions(OUT, wv);
		state->in_run_of_definitions = FALSE;
	}
	Formats::source_code(OUT, wv, tab_stops_of_indentation, prefatory,
		matter, colouring, concluding_comment, (found == 0)?TRUE:FALSE, TRUE, TRUE);
	DISCARD_TEXT(colouring);
	DISCARD_TEXT(concluding_comment);
	DISCARD_TEXT(prefatory);
	continue;

@ Code is typeset between the |\beginlines| and |\endlines| macros in TeX,
hence the name of the following paragraph:

@<Enter beginlines/endlines mode if necessary@> =
	int mode_now = state->kind_of_material;
	if (state->kind_of_material != CODE_MATERIAL) {
		if (L->category == MACRO_DEFINITION_LCAT)
			state->kind_of_material = MACRO_MATERIAL;
		else if ((L->category == BEGIN_DEFINITION_LCAT) ||
				(L->category == CONT_DEFINITION_LCAT))
			state->kind_of_material = DEFINITION_MATERIAL;
		else if ((state->kind_of_material == DEFINITION_MATERIAL) &&
			((L->category == CODE_BODY_LCAT) || (L->category == COMMENT_BODY_LCAT)) &&
			(Str::len(L->text) == 0))
			state->kind_of_material = DEFINITION_MATERIAL;
		else
			state->kind_of_material = CODE_MATERIAL;
		Formats::change_material(OUT, wv, mode_now, state->kind_of_material,
			state->substantive_comment);
		state->line_break_pending = FALSE;
	}

@ A blank line is typeset as a thin vertical skip (no TeX paragraph break
is needed):

@<Weave a blank line as a thin vertical skip@> =
	if (state->line_break_pending) {
		Formats::blank_line(OUT, wv, FALSE);
		state->line_break_pending = FALSE;
	}
	if (Regexp::string_is_white_space(matter)) {
		state->line_break_pending = TRUE;
		continue;
	}

@ Examine the white space at the start of the code line, and count the
number of tab steps of indentation, rating 1 tab = 4 spaces:

@<Convert leading space in line matter to a number of tab stops@> =
	int spaces_in = 0;
	while (Characters::is_space_or_tab(Str::get_first_char(matter))) {
		if (Str::get_first_char(matter) == '\t') {
			spaces_in = 0;
			tab_stops_of_indentation++;
		} else {
			spaces_in++;
			if (spaces_in == 4) {
				tab_stops_of_indentation++;
				spaces_in = 0;
			}
		}
		Str::delete_first_character(matter);
	}

@ Comments which run to the end of a line are set in italic type. If the
only item on their lines, they are presented at the code tab stop;
otherwise, they are set flush right.

@<Extract any comment matter ending the line to be set in italic@> =
	TEMPORARY_TEXT(part_before_comment);
	TEMPORARY_TEXT(part_within_comment);
	if (Languages::parse_comment(S->sect_language,
		matter, part_before_comment, part_within_comment)) {
		Str::copy(matter, part_before_comment);
		Str::copy(concluding_comment, part_within_comment);
	}
	DISCARD_TEXT(part_before_comment);
	DISCARD_TEXT(part_within_comment);

@ Set the |@d| definition escape very slightly more fancily:

@<Give constant definition lines slightly fancier openings@> =
	match_results mr = Regexp::create_mr();
	if ((Regexp::match(&mr, matter, L"@d (%c*)")) || (Regexp::match(&mr, matter, L"@define (%c*)"))) {
		Str::copy(prefatory, I"define");
		Str::copy(matter, mr.exp[0]);
	} else if ((Regexp::match(&mr, matter, L"@e (%c*)")) || (Regexp::match(&mr, matter, L"@enum (%c*)"))) {
		Str::copy(prefatory, I"enum");
		Str::copy(matter, mr.exp[0]);
	}
	Regexp::dispose_of(&mr);

@<Find macro usages and adjust syntax colouring accordingly@> =
	match_results mr = Regexp::create_mr();
	while (Regexp::match(&mr, matter, L"(%c*?)%@%<(%c*?)%@%>(%c*)")) {
		Str::copy(matter, mr.exp[2]);
		para_macro *pmac = Macros::find_by_name(mr.exp[1], S);
		Formats::source_code(OUT, wv, tab_stops_of_indentation, prefatory,
			mr.exp[0], colouring, concluding_comment, (found == 0)?TRUE:FALSE, FALSE, TRUE);
		Languages::reset_syntax_colouring(S->sect_language);
		found++;
		int defn = (L->owning_paragraph == pmac->defining_paragraph)?TRUE:FALSE;
		if (defn) state->in_run_of_definitions = FALSE;
		Formats::para_macro(OUT, wv, pmac, defn);
		if (defn) Str::clear(matter);
		TEMPORARY_TEXT(temp);
		int L = Str::len(colouring);
		for (int i = L - Str::len(matter); i < L; i++)
			PUT_TO(temp, Str::get_at(colouring, i));
		Str::copy(colouring, temp);
		DISCARD_TEXT(temp);
	}
	Regexp::dispose_of(&mr);

@h How paragraphs begin.

@<Deal with the marker for the start of a new paragraph, section or chapter@> =
	if ((L->category == HEADING_START_LCAT) ||
		(L->category == PARAGRAPH_START_LCAT) ||
		(L->category == CHAPTER_HEADING_LCAT) ||
		(L->category == SECTION_HEADING_LCAT)) {
		state->in_run_of_definitions = FALSE;
		@<Complete any started but not-fully-woven paragraph@>;
		if (wv->theme_match)
			@<If this is a paragraph break forced onto a new page, then throw a page@>;
		Languages::reset_syntax_colouring(S->sect_language); /* a precaution: limits bad colouring accidents to one para */
		int weight = 0;
		if (L->category == HEADING_START_LCAT) weight = 1;
		if (L->category == SECTION_HEADING_LCAT) weight = 2;
		if (L->category == CHAPTER_HEADING_LCAT) weight = 3;

		@<Work out the next mark to place into the TeX vertical list@>;

		text_stream *TeX_macro = NULL;
		@<Choose which TeX macro to use in order to typeset the new paragraph heading@>;

		TEMPORARY_TEXT(heading_text);
		@<Compose the heading text@>;
		Formats::paragraph_heading(OUT, wv, TeX_macro, S, L->owning_paragraph,
			heading_text, state->chaptermark, state->sectionmark, weight);
		DISCARD_TEXT(heading_text);

		if (weight == 0) state->substantive_comment = FALSE;
		else state->substantive_comment = TRUE;

		@<Weave any regular commentary text after the heading on the same line@>;

		if (weight == 3) Formats::chapter_title_page(OUT, wv, C);
		continue;
	}

@<If this is a paragraph break forced onto a new page, then throw a page@> =
	if ((L->owning_paragraph) &&
		(L->owning_paragraph->starts_on_new_page)) Formats::pagebreak(OUT, wv);

@ "Marks" are the contrivance by which TeX produces running heads on pages
which follow the material on those pages: so that the running head for a page
can show the paragraph range for the material which tops it, for instance.

The ornament has to be set in math mode, even in the mark. |\S| and |\P|,
making a section sign and a pilcrow respectively, only work in math mode
because they abbreviate characters found in math fonts but not regular ones,
in TeX's deeply peculiar font encoding system.

@<Work out the next mark to place into the TeX vertical list@> =
	if (weight == 3) {
		Str::copy(state->chaptermark, L->text_operand);
		Str::clear(state->sectionmark);
	}
	if (weight == 2) {
		Str::copy(state->sectionmark, L->text_operand);
		if (wv->pattern->show_abbrevs == FALSE) Str::clear(state->chaptermark);
		else if (Str::len(S->sect_range) > 0) Str::copy(state->chaptermark, S->sect_range);
		if (Str::len(state->chaptermark) > 0) {
			Str::clear(state->sectionmark);
			WRITE_TO(state->sectionmark, " - %S", L->text_operand);
		}
	}

@ We want to have different heading styles for different weights, and TeX is
horrible at using macro parameters as function arguments, so we don't want
to pass the weight that way. Instead we use

	|\weavesection|
	|\weavesections|
	|\weavesectionss|
	|\weavesectionsss|

where the weight is the number of terminal |s|s, 0 to 3. (TeX macros,
lamentably, are not allowed digits in their name.) In the cases 0 and 1, we
also have variants |\nsweavesection| and |\nsweavesections| which are
the same, but with the initial vertical spacing removed; these allow us to
prevent unsightly excess white space in certain configurations of a section.

@<Choose which TeX macro to use in order to typeset the new paragraph heading@> =
	switch (weight) {
		case 0: TeX_macro = I"weavesection"; break;
		case 1: TeX_macro = I"weavesections"; break;
		case 2: TeX_macro = I"weavesectionss"; break;
		default: TeX_macro = I"weavesectionsss"; break;
	}
	if (wv->theme_match) @<Apply special rules for thematic extracts@>;
	if ((state->next_heading_without_vertical_skip) && (weight < 2)) {
		state->next_heading_without_vertical_skip = FALSE;
		switch (weight) {
			case 0: TeX_macro = I"nsweavesection"; break;
			case 1: TeX_macro = I"nsweavesections"; break;
		}
	}

@ If we are weaving a selection of extracted paragraphs, normal conventions
about breaking pages at chapters and sections fail to work. So:

@<Apply special rules for thematic extracts@> =
	switch (weight) {
		case 0: TeX_macro = I"tweavesection"; break;
		case 1: TeX_macro = I"tweavesections"; break;
		case 2: TeX_macro = I"tweavesectionss"; break;
		default: TeX_macro = I"tweavesectionsss"; break;
	}
	if (weight >= 0) { weight = 0; }
	text_stream *cap = Tags::retrieve_caption(L->owning_paragraph, wv->theme_match);
	if (Str::len(cap) > 0) {
		Formats::subheading(OUT, wv, 1, cap, C->md->ch_title);
		state->last_extract_from = S;
	} else if (state->last_extract_from != S) {
		state->last_extract_from = S;
		TEMPORARY_TEXT(extr);
		WRITE_TO(extr, "From %S: %S", C->md->ch_title, S->md->sect_title);
		Formats::subheading(OUT, wv, 1, extr, C->md->ch_title);
		DISCARD_TEXT(extr);
	}

@<Compose the heading text@> =
	if (weight == 3) {
		TEMPORARY_TEXT(brief_title);
		match_results mr = Regexp::create_mr();
		if (Regexp::match(&mr, C->md->ch_title, L"%c*?: (%c*)"))
			Str::copy(brief_title, mr.exp[0]);
		else
			Str::copy(brief_title, C->md->ch_title);
		WRITE_TO(heading_text, "%S: %S", C->md->ch_range, brief_title);
		DISCARD_TEXT(brief_title);
		Regexp::dispose_of(&mr);
	} else if ((weight == 2) && (W->md->no_sections == 1)) {
		Str::copy(heading_text, Bibliographic::get_datum(W->md, I"Title"));
	} else {
		if ((weight == 2) && (wv->pattern->number_sections) && (S->printed_number >= 0))
			WRITE_TO(heading_text, "%d. ", S->printed_number);
		WRITE_TO(heading_text, "%S", L->text_operand);
	}

@ There's quite likely ordinary text on the line following the paragraph
 start indication, too, so we need to weave this out:

@<Weave any regular commentary text after the heading on the same line@> =
	if (Str::len(L->text_operand2) > 0) {
		TEMPORARY_TEXT(matter);
		WRITE_TO(matter, "%S\n", L->text_operand2);
		Formats::text(OUT, wv, matter);
		DISCARD_TEXT(matter);
		state->substantive_comment = TRUE;
	}

@h How paragraphs end.
At the end of a paragraph, on the other hand, we do this:

@<Complete any started but not-fully-woven paragraph@> =
	int mode_now = state->kind_of_material;
	if (state->kind_of_material != REGULAR_MATERIAL) {
		state->kind_of_material = REGULAR_MATERIAL;
		Formats::change_material(OUT, wv, mode_now, state->kind_of_material, TRUE);
	}
	if ((current_paragraph) && (current_paragraph != state->last_endnoted_para)) {
		state->last_endnoted_para = current_paragraph;
		Weaver::show_endnotes_on_previous_paragraph(OUT, wv, current_paragraph);
	}
	if (L) current_paragraph = L->owning_paragraph;

@h Endnotes.
The endnotes describe function calls from far away, or unexpected
structure usage, or how |CWEB|-style code substitutions were made.

=
void Weaver::show_endnotes_on_previous_paragraph(OUTPUT_STREAM, weave_target *wv, paragraph *P) {
	Tags::show_endnote_on_ifdefs(OUT, wv, P);
	if (P->defines_macro)
		@<Show endnote on where paragraph macro is used@>;
	function *fn;
	LOOP_OVER_LINKED_LIST(fn, function, P->functions)
		@<Show endnote on where this function is used@>;
	c_structure *st;
	LOOP_OVER_LINKED_LIST(st, c_structure, P->structures)
		@<Show endnote on where this C structure is accessed@>;
}

@<Show endnote on where paragraph macro is used@> =
	Formats::endnote(OUT, wv, 1);
	Formats::text(OUT, wv, I"This code is ");
	int ct = 0;
	macro_usage *mu;
	LOOP_OVER_LINKED_LIST(mu, macro_usage, P->defines_macro->macro_usages)
		ct++;
	if (ct == 1) Formats::text(OUT, wv, I"never used");
	else {
		int k = 0, used_flag = FALSE;
		LOOP_OVER_LINKED_LIST(mu, macro_usage, P->defines_macro->macro_usages)
			if (P != mu->used_in_paragraph) {
				if (used_flag) {
					if (k < ct-1) Formats::text(OUT, wv, I", ");
					else Formats::text(OUT, wv, I" and ");
				} else {
					Formats::text(OUT, wv, I"used in ");
				}
				Formats::locale(OUT, wv, mu->used_in_paragraph, NULL);
				used_flag = TRUE; k++;
				switch (mu->multiplicity) {
					case 1: break;
					case 2: Formats::text(OUT, wv, I" (twice)"); break;
					case 3: Formats::text(OUT, wv, I" (three times)"); break;
					case 4: Formats::text(OUT, wv, I" (four times)"); break;
					case 5: Formats::text(OUT, wv, I" (five times)"); break;
					default: {
						TEMPORARY_TEXT(mt);
						WRITE_TO(mt, " (%d times)", mu->multiplicity);
						Formats::text(OUT, wv, mt);
						DISCARD_TEXT(mt);
						break;
					}
				}
			}
	}
	Formats::text(OUT, wv, I".");
	Formats::endnote(OUT, wv, 2);

@<Show endnote on where this function is used@> =
	Formats::endnote(OUT, wv, 1);
	hash_table_entry *hte =
		Analyser::find_hash_entry(fn->function_header_at->owning_section, fn->function_name, FALSE);
	Formats::text(OUT, wv, I"The function ");
	Formats::text(OUT, wv, fn->function_name);
	int used_flag = FALSE;
	hash_table_entry_usage *hteu = NULL;
	section *last_cited_in = NULL;
	int count_under = 0;
	LOOP_OVER_LINKED_LIST(hteu, hash_table_entry_usage, hte->usages)
		if ((P != hteu->usage_recorded_at) &&
			(P->under_section == hteu->usage_recorded_at->under_section))
			@<Cite usage of function here@>;
	LOOP_OVER_LINKED_LIST(hteu, hash_table_entry_usage, hte->usages)
		if (P->under_section != hteu->usage_recorded_at->under_section)
			@<Cite usage of function here@>;
	if (used_flag == FALSE) Formats::text(OUT, wv, I" appears nowhere else");
	if ((last_cited_in != P->under_section) && (last_cited_in))
		Formats::text(OUT, wv, I")");
	Formats::text(OUT, wv, I".");
	Formats::endnote(OUT, wv, 2);

@<Cite usage of function here@> =
	if (used_flag == FALSE) Formats::text(OUT, wv, I" is used in ");
	used_flag = TRUE;
	section *S = hteu->usage_recorded_at->under_section;
	if ((S != last_cited_in) && (S != P->under_section)) {
		count_under = 0;
		if (last_cited_in) {
			if (last_cited_in != P->under_section) Formats::text(OUT, wv, I"), ");
			else Formats::text(OUT, wv, I", ");
		}
		Formats::text(OUT, wv, hteu->usage_recorded_at->under_section->sect_range);
		Formats::text(OUT, wv, I" (");
	}
	if (count_under++ > 0) Formats::text(OUT, wv, I", ");
	Formats::locale(OUT, wv, hteu->usage_recorded_at, NULL);
	last_cited_in = hteu->usage_recorded_at->under_section;

@<Show endnote on where this C structure is accessed@> =
	Formats::endnote(OUT, wv, 1);
	Formats::text(OUT, wv, I"The structure ");
	Formats::text(OUT, wv, st->structure_name);

	section *S;
	LOOP_OVER(S, section) S->scratch_flag = FALSE;
	structure_element *elt;
	LOOP_OVER_LINKED_LIST(elt, structure_element, st->elements) {
		hash_table_entry *hte =
			Analyser::find_hash_entry(elt->element_created_at->owning_section, elt->element_name, FALSE);
		if (hte) {
			hash_table_entry_usage *hteu;
			LOOP_OVER_LINKED_LIST(hteu, hash_table_entry_usage, hte->usages)
				if (hteu->form_of_usage & ELEMENT_ACCESS_USAGE)
					hteu->usage_recorded_at->under_section->scratch_flag = TRUE;
		}
	}

	int usage_count = 0, external = 0;
	LOOP_OVER(S, section)
		if (S->scratch_flag) {
			usage_count++;
			if (S != P->under_section) external++;
		}
	if (external == 0) Formats::text(OUT, wv, I" is private to this section");
	else {
		Formats::text(OUT, wv, I" is accessed in ");
		int c = 0;
		LOOP_OVER(S, section)
			if ((S->scratch_flag) && (S != P->under_section)) {
				if (c++ > 0) Formats::text(OUT, wv, I", ");
				Formats::text(OUT, wv, S->sect_range);
			}
		if (P->under_section->scratch_flag) Formats::text(OUT, wv, I" and here");
	}
	Formats::text(OUT, wv, I".");
	Formats::endnote(OUT, wv, 2);

@h Section tables of contents.
These appear at the top of each woven section, and give links to the paragraphs
marked as |@h| headings.

=
int Weaver::weave_table_of_contents(OUTPUT_STREAM, weave_target *wv, section *S) {
	int noteworthy = 0;
	paragraph *P;
	LOOP_OVER_LINKED_LIST(P, paragraph, S->paragraphs)
		if ((P->weight > 0) && ((S->barred == FALSE) || (P->above_bar == FALSE)))
			noteworthy++;
	if (noteworthy == 0) return FALSE;

	Formats::toc(OUT, wv, 1, S->sect_range, I"", NULL);
	noteworthy = 0;
	LOOP_OVER_LINKED_LIST(P, paragraph, S->paragraphs)
		if ((P->weight > 0) && ((S->barred == FALSE) || (P->above_bar == FALSE))) {
			if (noteworthy > 0) Formats::toc(OUT, wv, 2, I"", I"", NULL);
			TEMPORARY_TEXT(loc);
			WRITE_TO(loc, "%S%S", P->ornament, P->paragraph_number);
			Formats::toc(OUT, wv, 3, loc, P->first_line_in_paragraph->text_operand, P);
			DISCARD_TEXT(loc);
			noteworthy++;
		}
	Formats::toc(OUT, wv, 4, I"", I"", NULL);
	return TRUE;
}
