[TeX::] TeX Format.

To provide for weaving in the standard maths and science typesetting
software, TeX.

@h Creation.

=
void TeX::create(void) {
	@<Create TeX format@>;
	@<Create DVI format@>;
	@<Create PDF format@>;
}

@<Create TeX format@> =
	weave_format *wf = Formats::create_weave_format(I"TeX", I".tex");
	@<Make this format basically TeX@>;

@<Create DVI format@> =
	weave_format *wf = Formats::create_weave_format(I"DVI", I".tex");
	@<Make this format basically TeX@>;
	METHOD_ADD(wf, POST_PROCESS_POS_MTID, TeX::post_process_DVI);
	METHOD_ADD(wf, POST_PROCESS_POS_MTID, TeX::post_process_report);
	METHOD_ADD(wf, POST_PROCESS_SUBSTITUTE_POS_MTID, TeX::post_process_substitute);
	METHOD_ADD(wf, PRESERVE_MATH_MODE_FOR_MTID, TeX::yes);

@<Create PDF format@> =
	weave_format *wf = Formats::create_weave_format(I"PDF", I".tex");
	METHOD_ADD(wf, PARA_MACRO_FOR_MTID, TeX::para_macro_PDF_1);
	@<Make this format basically TeX@>;
	METHOD_ADD(wf, PARA_MACRO_FOR_MTID, TeX::para_macro_PDF_2);
	METHOD_ADD(wf, CHANGE_COLOUR_FOR_MTID, TeX::change_colour_PDF);
	METHOD_ADD(wf, FIGURE_FOR_MTID, TeX::figure_PDF);
	METHOD_ADD(wf, POST_PROCESS_POS_MTID, TeX::post_process_PDF);
	METHOD_ADD(wf, POST_PROCESS_SUBSTITUTE_POS_MTID, TeX::post_process_substitute);
	METHOD_ADD(wf, INDEX_PDFS_POS_MTID, TeX::yes);
	METHOD_ADD(wf, PRESERVE_MATH_MODE_FOR_MTID, TeX::yes);

@<Make this format basically TeX@> =
	METHOD_ADD(wf, TOP_FOR_MTID, TeX::top);
	METHOD_ADD(wf, SUBHEADING_FOR_MTID, TeX::subheading);
	METHOD_ADD(wf, TOC_FOR_MTID, TeX::toc);
	METHOD_ADD(wf, CHAPTER_TP_FOR_MTID, TeX::chapter_title_page);
	METHOD_ADD(wf, PARAGRAPH_HEADING_FOR_MTID, TeX::paragraph_heading);
	METHOD_ADD(wf, SOURCE_CODE_FOR_MTID, TeX::source_code);
	METHOD_ADD(wf, INLINE_CODE_FOR_MTID, TeX::inline_code);
	METHOD_ADD(wf, DISPLAY_LINE_FOR_MTID, TeX::display_line);
	METHOD_ADD(wf, ITEM_FOR_MTID, TeX::item);
	METHOD_ADD(wf, BAR_FOR_MTID, TeX::bar);
	METHOD_ADD(wf, PARA_MACRO_FOR_MTID, TeX::para_macro);
	METHOD_ADD(wf, PAGEBREAK_FOR_MTID, TeX::pagebreak);
	METHOD_ADD(wf, BLANK_LINE_FOR_MTID, TeX::blank_line);
	METHOD_ADD(wf, AFTER_DEFINITIONS_FOR_MTID, TeX::after_definitions);
	METHOD_ADD(wf, CHANGE_MATERIAL_FOR_MTID, TeX::change_material);
	METHOD_ADD(wf, ENDNOTE_FOR_MTID, TeX::endnote);
	METHOD_ADD(wf, COMMENTARY_TEXT_FOR_MTID, TeX::commentary_text);
	METHOD_ADD(wf, LOCALE_FOR_MTID, TeX::locale);
	METHOD_ADD(wf, TAIL_FOR_MTID, TeX::tail);
	METHOD_ADD(wf, PREFORM_DOCUMENT_FOR_MTID, TeX::preform_document);
	METHOD_ADD(wf, POST_PROCESS_SUBSTITUTE_POS_MTID, TeX::post_process_substitute);
	METHOD_ADD(wf, PRESERVE_MATH_MODE_FOR_MTID, TeX::yes);

@h Methods.
For documentation, see "Weave Fornats".

=
int TeX::yes(weave_format *self) {
	return TRUE;
}

@ =
void TeX::top(weave_format *self, text_stream *OUT, weave_target *wv, text_stream *comment) {
	WRITE("%% %S\n", comment);
	@<Incorporate suitable TeX macro definitions into the woven output@>;
}

@ We don't use TeX's |\input| mechanism for macros because it is so prone to
failures when searching directories (especially those with spaces in the
names) and then locking TeX into a repeated prompt for help from |stdin|
which is rather hard to escape from.

Instead we paste the entire text of our macros file into the woven TeX:

@<Incorporate suitable TeX macro definitions into the woven output@> =
	filename *Macros = Patterns::obtain_filename(wv->pattern, I"inweb-macros.tex");
	FILE *MACROS = Filenames::fopen(Macros, "r");
	if (MACROS == NULL) Errors::fatal_with_file("can't open file of TeX macros", Macros);
	while (TRUE) {
		int c = fgetc(MACROS);
		if (c == EOF) break;
		PUT(c);
	}
	fclose(MACROS);

@ =
void TeX::subheading(weave_format *self, text_stream *OUT, weave_target *wv,
	int level, text_stream *comment, text_stream *head) {
	switch (level) {
		case 1:
			WRITE("\\par\\noindent{\\bf %S}\\mark{%S}\\medskip\n",
				comment, head);
			break;
		case 2:
			WRITE("\\smallskip\\par\\noindent{\\it %S}\\smallskip\\noindent\n",
				comment);
			if (head) Formats::text(OUT, wv, head);
			break;
	}
}

@ =
void TeX::toc(weave_format *self, text_stream *OUT, weave_target *wv, int stage,
	text_stream *text1, text_stream *text2, paragraph *P) {
	switch (stage) {
		case 1:
			if (wv->pattern->show_abbrevs)
				WRITE("\\medskip\\hrule\\smallskip\\par\\noindent{\\usagefont %S.", text1);
			else
				WRITE("\\medskip\\hrule\\smallskip\\par\\noindent{\\usagefont ");
			break;
		case 2:
			WRITE("; ");
			break;
		case 3:
			WRITE("%S~%S", text1, text2);
			break;
		case 4:
			WRITE("}\\par\\medskip\\hrule\\bigskip\n");
			break;
	}
}

@ =
void TeX::chapter_title_page(weave_format *self, text_stream *OUT, weave_target *wv,
	chapter *C) {
	WRITE("%S\\medskip\n", C->rubric);
	section *S;
	LOOP_OVER_LINKED_LIST(S, section, C->sections) {
		WRITE("\\smallskip\\noindent ");
		if (wv->pattern->number_sections) WRITE("%d. ", S->printed_number);
		if (wv->pattern->show_abbrevs) WRITE("|%S|: ", S->range);
		WRITE("{\\it %S}\\qquad\n%S", S->sect_title, S->sect_purpose);
	}
}

@ =
text_stream *P_literal = NULL;
void TeX::paragraph_heading(weave_format *self, text_stream *OUT, weave_target *wv,
	text_stream *TeX_macro, section *S, paragraph *P, text_stream *heading_text,
	text_stream *chaptermark, text_stream *sectionmark, int weight) {
	if (P_literal == NULL) P_literal = Str::new_from_wide_string(L"P");
	text_stream *orn = (P)?(P->ornament):P_literal;
	text_stream *N = (P)?(P->paragraph_number):NULL;
	TEMPORARY_TEXT(mark);
	WRITE_TO(mark, "%S%S\\quad$\\%S$%S", chaptermark, sectionmark, orn, N);
	TEMPORARY_TEXT(modified);
	Str::copy(modified, heading_text);
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, modified, L"(%c*?): (%c*)")) {
		Str::clear(modified);
		WRITE_TO(modified, "{\\sinchhigh %S}\\quad %S", mr.exp[0], mr.exp[1]);
	}
	if ((weight == 2) && ((S->is_a_singleton) || (wv->pattern->show_abbrevs == FALSE)))
		WRITE("\\%S{%S}{%S}{%S}{\\%S}{%S}%%\n",
			TeX_macro, N, modified, mark, orn, NULL);
	else
		WRITE("\\%S{%S}{%S}{%S}{\\%S}{%S}%%\n",
			TeX_macro, N, modified, mark, orn, S->range);
	DISCARD_TEXT(mark);
	DISCARD_TEXT(modified);
	Regexp::dispose_of(&mr);
}

@ Code is typeset by TeX within vertical strokes; these switch a sort of
typewriter-type verbatim mode on and off. To get an actual stroke, we must
escape from code mode, escape it using a backslash, then re-enter code
mode once again:

=
void TeX::source_code(weave_format *self, text_stream *OUT, weave_target *wv,
	int tab_stops_of_indentation, text_stream *prefatory, text_stream *matter,
	text_stream *colouring, text_stream *concluding_comment,
	int starts, int finishes, int code_mode) {
	if (code_mode == FALSE) WRITE("\\smallskip\\par\\noindent");
	if (starts) {
		@<Weave a suitable horizontal advance for that many tab stops@>;
		if (Str::len(prefatory) > 0) WRITE("{\\ninebf %S} ", prefatory);
		WRITE("|");
	}
	int current_colour = PLAIN_COLOUR, colour_wanted = PLAIN_COLOUR;
	for (int i=0; i < Str::len(matter); i++) {
		colour_wanted = Str::get_at(colouring, i); @<Adjust code colour as necessary@>;
		if (Str::get_at(matter, i) == '|') WRITE("|\\||");
		else WRITE("%c", Str::get_at(matter, i));
	}
	colour_wanted = PLAIN_COLOUR; @<Adjust code colour as necessary@>;
	if (finishes) {
		WRITE("|");
		if (Str::len(concluding_comment) > 0) {
			if ((Str::len(matter) > 0) || (!starts))
				WRITE("\\hfill\\quad ");
			WRITE("{\\ttninepoint\\it %S}", concluding_comment);
		}
		WRITE("\n");
	}
}

@ We actually use |\qquad| horizontal spaces rather than risk using TeX's
messy alignment system:

@<Weave a suitable horizontal advance for that many tab stops@> =
	for (int i=0; i<tab_stops_of_indentation; i++)
		WRITE("\\qquad");

@<Adjust code colour as necessary@> =
	if (colour_wanted != current_colour) {
		Formats::change_colour(OUT, wv, colour_wanted, TRUE);
		current_colour = colour_wanted;
	}

@ =
void TeX::inline_code(weave_format *self, text_stream *OUT, weave_target *wv,
	int enter) {
	WRITE("|");
}

@ =
void TeX::change_colour_PDF(weave_format *self, text_stream *OUT, weave_target *wv,
	int col, int in_code) {
	char *inout = "";
	if (in_code) inout = "|";
	switch (col) {
		case MACRO_COLOUR:
			WRITE("%s\\pdfliteral direct{1 1 0 0 k}%s", inout, inout); break;
		case FUNCTION_COLOUR:
			WRITE("%s\\pdfliteral direct{0 1 1 0 k}%s", inout, inout); break;
		case PLAIN_COLOUR:
			WRITE("%s\\special{PDF:0 g}%s", inout, inout); break;
		case EXTRACT_COLOUR:
			WRITE("%s\\special{PDF:0 g}%s", inout, inout); break;
	}
}

@ =
void TeX::display_line(weave_format *self, text_stream *OUT, weave_target *wv,
	text_stream *text) {
	WRITE("\\quotesource{%S}\n", text);
}

@ =
void TeX::item(weave_format *self, text_stream *OUT, weave_target *wv, int depth,
	text_stream *label) {
	if (Str::len(label) > 0) {
		if (depth == 1) WRITE("\\item{(%S)}", label);
		else WRITE("\\itemitem{(%S)}", label);
	} else {
		if (depth == 1) WRITE("\\item{}");
		else WRITE("\\itemitem{}");
	}
}

@ =
void TeX::bar(weave_format *self, text_stream *OUT, weave_target *wv) {
	WRITE("\\par\\medskip\\noindent\\hrule\\medskip\\noindent\n");
}

@ TeX itself has an almost defiant lack of support for anything pictorial,
which is one reason it didn't live up to its hope of being the definitive basis
for typography; even today the loose confederation of TeX-like programs and
extensions lack standard approaches. Here we're going to use |pdftex| features,
having nothing better. All we're trying for is to insert a picture, scaled
to a given width, into the text at the current position.

=
void TeX::figure_PDF(weave_format *self, text_stream *OUT, weave_target *wv,
	text_stream *figname, int w, int h) {
	WRITE("\\pdfximage");
	if (w >= 0)
		WRITE(" width %d cm{../Figures/%S}\n", w, figname);
	else if (h >= 0)
		WRITE(" height %d cm{../Figures/%S}\n", h, figname);
	else
		WRITE("{../Figures/%S}\n", figname);
	WRITE("\\smallskip\\noindent"
		"\\hbox to\\hsize{\\hfill\\pdfrefximage \\pdflastximage\\hfill}"
		"\\smallskip\n");
}

@ Any usage of angle-macros is highlighted in several cute ways: first,
we make use of colour and we drop in the paragraph number of the definition
of the macro in small type; and second, we use cross-reference links.

In the PDF format, these three are all called, in sequence below; in TeX
or DVI, only the middle one is.

=
void TeX::para_macro_PDF_1(weave_format *self, text_stream *OUT, weave_target *wv,
	para_macro *pmac, int defn) {
	if (defn)
		WRITE("|\\pdfdest num %d fit ",
			pmac->allocation_id + 100);
	else
		WRITE("|\\pdfstartlink attr{/C [0.9 0 0] /Border [0 0 0]} goto num %d ",
			pmac->allocation_id + 100);
}
void TeX::para_macro(weave_format *self, text_stream *OUT, weave_target *wv,
	para_macro *pmac, int defn) {
	WRITE("$\\langle${\\xreffont");
	Formats::change_colour(OUT, wv, MACRO_COLOUR, FALSE);
	WRITE("%S ", pmac->macro_name);
	WRITE("{\\sevenss %S}}", pmac->defining_paragraph->paragraph_number);
	Formats::change_colour(OUT, wv, PLAIN_COLOUR, FALSE);
	WRITE("$\\rangle$ ");
}
void TeX::para_macro_PDF_2(weave_format *self, text_stream *OUT, weave_target *wv,
	para_macro *pmac, int defn) {
	if (defn)
		WRITE("$\\equiv$|");
	else
		WRITE("\\pdfendlink|");
}

@ =
void TeX::pagebreak(weave_format *self, text_stream *OUT, weave_target *wv) {
	WRITE("\\vfill\\eject\n");
}

@ =
void TeX::blank_line(weave_format *self, text_stream *OUT, weave_target *wv,
	int in_comment) {
	if (in_comment) WRITE("\\smallskip\\par\\noindent%%\n");
	else WRITE("\\smallskip\n");
}

@ =
void TeX::after_definitions(weave_format *self, text_stream *OUT, weave_target *wv) {
	WRITE("\\smallskip\n");
}

@ =
void TeX::endnote(weave_format *self, text_stream *OUT, weave_target *wv, int end) {
	if (end == 1) {
		WRITE("\\par\\noindent\\penalty10000\n");
		WRITE("{\\usagefont ");
	} else {
		WRITE("}\\smallskip\n");
	}
}

@ =
void TeX::commentary_text(weave_format *self, text_stream *OUT, weave_target *wv,
	text_stream *id) {
	int math_mode = FALSE;
	for (int i=0; i < Str::len(id); i++) {
		switch (Str::get_at(id, i)) {
			case '$': math_mode = (math_mode)?FALSE:TRUE;
				WRITE("%c", Str::get_at(id, i)); break;
			case '_': if (math_mode) WRITE("_"); else WRITE("\\_"); break;
			case '"':
				if ((Str::get_at(id, i) == '"') &&
					((i==0) || (Str::get_at(id, i-1) == ' ') ||
						(Str::get_at(id, i-1) == '(')))
					WRITE("``");
				else
					WRITE("''");
				break;
			default: WRITE("%c", Str::get_at(id, i));
				break;
		}
	}
}

@ =
void TeX::locale(weave_format *self, text_stream *OUT, weave_target *wv,
	paragraph *par1, paragraph *par2) {
	WRITE("$\\%S$%S", par1->ornament, par1->paragraph_number);
	if (par2) WRITE("-%S", par2->paragraph_number);
}

@ =
void TeX::change_material(weave_format *self, text_stream *OUT, weave_target *wv,
	int old_material, int new_material, int content) {
	if (old_material != new_material) {
		switch (old_material) {
			case REGULAR_MATERIAL:
				switch (new_material) {
					case CODE_MATERIAL:
						WRITE("\\beginlines\n");
						break;
					case DEFINITION_MATERIAL:
						WRITE("\\beginlines\n");
						break;
					case MACRO_MATERIAL:
						WRITE("\\beginlines\n");
						break;
				}
				break;
			default:
				if (new_material == REGULAR_MATERIAL)
					WRITE("\\endlines\n");
				break;
		}
	}
}

@ =
void TeX::tail(weave_format *self, text_stream *OUT, weave_target *wv,
	text_stream *comment) {
	WRITE("%% %S\n", comment);
	WRITE("\\end\n");
}

@ The following is called only when the language is InC, and the weave is of
the special Preform grammar document.

=
int TeX::preform_document(weave_format *self, text_stream *OUT, web *W, weave_target *wv,
	chapter *C, section *S, source_line *L, text_stream *matter,
	text_stream *concluding_comment) {
	if (L->preform_nonterminal_defined) {
		preform_production_count = 0;
		@<Weave the opening line of the nonterminal definition@>;
		return TRUE;
	} else {
		if (L->category == PREFORM_GRAMMAR_LCAT) {
			@<Weave a line from the body of the nonterminal definition@>;
			return TRUE;
		}
	}
	return FALSE;
}

@<Weave the opening line of the nonterminal definition@> =
	WRITE("\\nonterminal{%S} |::=|",
		L->preform_nonterminal_defined->unangled_name);
	if (L->preform_nonterminal_defined->as_function) {
		WRITE("\\quad{\\it internal definition");
		if (L->preform_nonterminal_defined->voracious)
			WRITE(" (voracious)");
		else if (L->preform_nonterminal_defined->min_word_count ==
			L->preform_nonterminal_defined->min_word_count)
			WRITE(" (%d word%s)",
				L->preform_nonterminal_defined->min_word_count,
				(L->preform_nonterminal_defined->min_word_count != 1)?"s":"");
		WRITE("}");
	}
	WRITE("\n");

@<Weave a line from the body of the nonterminal definition@> =
	TEMPORARY_TEXT(problem);
	match_results mr = Regexp::create_mr();
	if (Regexp::match(&mr, matter, L"Issue (%c*?) problem")) Str::copy(problem, mr.exp[0]);
	else if (Regexp::match(&mr, matter, L"FAIL_NONTERMINAL %+")) WRITE_TO(problem, "fail and skip");
	else if (Regexp::match(&mr, matter, L"FAIL_NONTERMINAL")) WRITE_TO(problem, "fail");
	preform_production_count++;
	WRITE_TO(matter, "|%S|", L->text_operand);
	while (Regexp::match(&mr, matter, L"(%c+?)|(%c+)")) {
		Str::clear(matter);
		WRITE_TO(matter, "%S___stroke___%S", mr.exp[0], mr.exp[1]);
	}
	while (Regexp::match(&mr, matter, L"(%c*?)___stroke___(%c*)")) {
		Str::clear(matter);
		WRITE_TO(matter, "%S|\\||%S", mr.exp[0], mr.exp[1]);
	}
	while (Regexp::match(&mr, matter, L"(%c*)<(%c*?)>(%c*)")) {
		Str::clear(matter);
		WRITE_TO(matter, "%S|\\nonterminal{%S}|%S",
			mr.exp[0], mr.exp[1], mr.exp[2]);
	}
	TEMPORARY_TEXT(label);
	int N = preform_production_count;
	int L = ((N-1)%26) + 1;
	if (N <= 26) WRITE_TO(label, "%c", 'a'+L-1);
	else if (N <= 52) WRITE_TO(label, "%c%c", 'a'+L-1, 'a'+L-1);
	else if (N <= 78) WRITE_TO(label, "%c%c%c", 'a'+L-1, 'a'+L-1, 'a'+L-1);
	else {
		int n = (N-1)/26;
		WRITE_TO(label, "%c${}^{%d}$", 'a'+L-1, n);
	}
	WRITE("\\qquad {\\hbox to 0.4in{\\it %S\\hfil}}%S", label, matter);
	if (Str::len(problem) > 0)
		WRITE("\\hfill$\\longrightarrow$ {\\ttninepoint\\it %S}", problem);
	else if (Str::len(concluding_comment) > 0) {
		WRITE(" \\hfill{\\ttninepoint\\it ");
		if (concluding_comment) Formats::text(OUT, wv, concluding_comment);
		WRITE("}");
	}
	WRITE("\n");
	DISCARD_TEXT(label);
	DISCARD_TEXT(problem);
	Regexp::dispose_of(&mr);

@h Post-processing.

=
void TeX::post_process_PDF(weave_format *self, weave_target *wv, int open) {
	RunningTeX::post_process_weave(wv, open, FALSE);
}
void TeX::post_process_DVI(weave_format *self, weave_target *wv, int open) {
	RunningTeX::post_process_weave(wv, open, TRUE);
}

@ =
void TeX::post_process_report(weave_format *self, weave_target *wv) {
	RunningTeX::report_on_post_processing(wv);
}

@ =
int TeX::post_process_substitute(weave_format *self, text_stream *OUT,
	weave_target *wv, text_stream *detail, weave_pattern *pattern) {
	return RunningTeX::substitute_post_processing_data(OUT, wv, detail);
}

@h Removing math mode.
"Math mode", in TeX jargon, is what happens when a mathematical formula
is written inside dollar signs: in |Answer is $x+y^2$|, the math mode
content is |x+y^2|. But since math mode doesn't (easily) exist in HTML,
for example, we want to strip it out if the format is not TeX-related.
To do this, the weaver calls the following.

=
void TeX::remove_math_mode(OUTPUT_STREAM, text_stream *text) {
	int math_mode = FALSE;
	for (int i=0; i < Str::len(text); i++) {
		switch (Str::get_at(text, i)) {
			case '$': math_mode = (math_mode)?FALSE:TRUE; break;
			case '\\': @<Do something to strip out a TeX macro@>; break;
			default: WRITE("%c", Str::get_at(text, i)); break;
		}
	}
}

@<Do something to strip out a TeX macro@> =
	TEMPORARY_TEXT(macro);
	i++;
	while ((i < Str::len(text)) && (Characters::isalpha(Str::get_at(text, i))))
		PUT_TO(macro, Str::get_at(text, i++));
	if (Str::eq(macro, I"leq")) WRITE("<=");
	else if (Str::eq(macro, I"geq")) WRITE("<=");
	else if (Str::eq(macro, I"neq")) WRITE("!=");
	else {
		if (Str::len(macro) > 0)
			PRINT("[Passing through unknown TeX macro \\%S: on '%S']\n", macro, text);
		WRITE("\\%S", macro);
	}
	DISCARD_TEXT(macro);
	i--;
