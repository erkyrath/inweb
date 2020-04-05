[Painter::] The Painter.

A simple syntax-colouring engine.

@ This is a very simple syntax colouring algorithm. The work is done by the
function |Painter::syntax_colour|, which can in principle be applied to texts
of any length. But it's usually convenient to run it on a long file one line
at a time, so that it is called repeatedly. The variable |colouring_state|
remembers where we were at the end of the previous line, so that we can pick
up again later at the start of the next.

Because of that, we need to call the following before we begin a run of calls
to |Painter::syntax_colour|:

=
void Painter::reset_syntax_colouring(programming_language *pl) {
	colouring_state = PLAIN_COLOUR;
}

@ As we begin, the text to colour is in |matter|, while |colouring| is an
equal-length text where each character represents the colour of its
corresponding character in |matter|. For example, we might start as:

	|int x = 55;|
	|ppppppppppp|

with every character having |PLAIN_COLOUR|, but end up with:

	|int x = 55;|
	|rrrpipppnnp|

We get to that by using a language's rules on literals, and then executing
its colouring program.

=
int Painter::syntax_colour(programming_language *pl, text_stream *OUT,
	hash_table *HT, text_stream *matter, text_stream *colouring, int with_comments) {
	int from = 0, to = Str::len(matter) - 1;
	if (with_comments) {
		TEMPORARY_TEXT(part_before_comment);
		TEMPORARY_TEXT(part_within_comment);
		if (LanguageMethods::parse_comment(pl,
			matter, part_before_comment, part_within_comment)) {
			int N = Str::len(matter);
			for (int i=Str::len(part_before_comment); i<N; i++)
				Str::put_at(colouring, i, COMMENT_COLOUR);
			from = 0; to = Str::len(part_before_comment);
		}
		DISCARD_TEXT(part_before_comment);
		DISCARD_TEXT(part_within_comment);
	}
	Painter::syntax_colour_inner(pl, OUT, HT, matter, colouring, from, to);
	return FALSE;
}

void Painter::syntax_colour_inner(programming_language *pl, text_stream *OUT,
	hash_table *HT, text_stream *matter, text_stream *colouring, int from, int to) {
	@<Spot identifiers, literal text and character constants@>;
	@<Spot literal numerical constants@>;
	@<Now run the colouring program@>;
}

@<Spot identifiers, literal text and character constants@> =
	int squote = Str::get_first_char(pl->character_literal);
	int squote_escape = Str::get_first_char(pl->character_literal_escape);
	int dquote = Str::get_first_char(pl->string_literal);
	int dquote_escape = Str::get_first_char(pl->string_literal_escape);
	for (int i=from; i <= to; i++) {
		int skip = 0, one_off = -1, will_be = -1;
		switch (colouring_state) {
			case PLAIN_COLOUR: {
				wchar_t c = Str::get_at(matter, i);
				if (c == dquote) {
					colouring_state = STRING_COLOUR;
					break;
				}
				if (c == squote) {
					colouring_state = CHAR_LITERAL_COLOUR;
					break;
				}
				if (Painter::identifier_at(pl, matter, colouring, i))
					one_off = IDENTIFIER_COLOUR;
				break;
			}
			case CHAR_LITERAL_COLOUR: {
				wchar_t c = Str::get_at(matter, i);
				if (c == squote) will_be = PLAIN_COLOUR;
				if (c == squote_escape) skip = 1;
				break;
			}
			case STRING_COLOUR: {
				wchar_t c = Str::get_at(matter, i);
				if (c == dquote) will_be = PLAIN_COLOUR;
				if (c == dquote_escape) skip = 1;
				break;
			}
		}
		if (one_off >= 0) Str::put_at(colouring, i, (char) one_off);
		else Str::put_at(colouring, i, (char) colouring_state);
		if (will_be >= 0) colouring_state = (char) will_be;
		if (skip > 0) i += skip;
	}

@<Spot literal numerical constants@> =
	int base = -1, dec_possible = TRUE;
	for (int i=from; i <= to; i++) {
		if ((Str::get_at(colouring, i) == PLAIN_COLOUR) ||
			(Str::get_at(colouring, i) == IDENTIFIER_COLOUR)) {
			wchar_t c = Str::get_at(matter, i);
			if (ACMESupport::text_at(matter, i, pl->binary_literal_prefix)) {
				base = 2;
				for (int j=0; j<Str::len(pl->binary_literal_prefix); j++)
					Str::put_at(colouring, i+j, (char) CONSTANT_COLOUR);
				dec_possible = TRUE;
				continue;
			} else if (ACMESupport::text_at(matter, i, pl->octal_literal_prefix)) {
				base = 8;
				for (int j=0; j<Str::len(pl->octal_literal_prefix); j++)
					Str::put_at(colouring, i+j, (char) CONSTANT_COLOUR);
				dec_possible = TRUE;
				continue;
			} else if (ACMESupport::text_at(matter, i, pl->hexadecimal_literal_prefix)) {
				base = 16;
				for (int j=0; j<Str::len(pl->hexadecimal_literal_prefix); j++)
					Str::put_at(colouring, i+j, (char) CONSTANT_COLOUR);
				dec_possible = TRUE;
				continue;
			} 
			if ((ACMESupport::text_at(matter, i, pl->negative_literal_prefix)) &&
				(dec_possible) && (base == 0)) {
				base = 10;
				Str::put_at(colouring, i, (char) CONSTANT_COLOUR);
				continue;
			}
			int pass = FALSE;
			switch (base) {
				case -1: 
					if ((dec_possible) && (Characters::isdigit(c))) {
						base = 10; pass = TRUE;
					}
					break;
				case 2: if ((c == '0') || (c == '1')) pass = TRUE; break;
				case 10: if (Characters::isdigit(c)) pass = TRUE; break;
				case 16: if (Characters::isdigit(c)) pass = TRUE;
					int d = Characters::tolower(c);
					if ((d == 'a') || (d == 'b') || (d == 'c') ||
						(d == 'd') || (d == 'e') || (d == 'f')) pass = TRUE;
					break;
			}
			if (pass) {
				Str::put_at(colouring, i, (char) CONSTANT_COLOUR);
			} else {
				if (Characters::is_whitespace(c)) dec_possible = TRUE;
				else dec_possible = FALSE;
				base = -1;
			}
		}
	}

@ For the moment, we always adopt the C rules on identifiers: they have to
begin with an underscore or letter, then continue with underscores or
alphanumeric characters, except that if the language allows it then they
can contain a |::| namespace divider.

=
int Painter::identifier_at(programming_language *pl,
	text_stream *matter, text_stream *colouring, int i) {
	wchar_t c = Str::get_at(matter, i);
	if ((i > 0) && (Str::get_at(colouring, i-1) == IDENTIFIER_COLOUR)) {
		if ((c == '_') ||
			((c >= 'A') && (c <= 'Z')) ||
			((c >= 'a') && (c <= 'z')) ||
			((c >= '0') && (c <= '9'))) return TRUE;
		if ((c == ':') && (pl->supports_namespaces)) return TRUE;
	} else {
		wchar_t d = 0;
		if (i > 0) d = Str::get_at(matter, i);
		if ((d >= '0') && (d <= '9')) return FALSE;
		if ((c == '_') ||
			((c >= 'A') && (c <= 'Z')) ||
			((c >= 'a') && (c <= 'z'))) return TRUE;
	}
	return FALSE;
}

@ With those preliminaries out of the way, the language's colouring program
takes over.

@<Now run the colouring program@> =
	if (pl->program)
		Painter::execute(HT, pl->program, matter, colouring, from, to);

@ The run-type for a block determines what the rules in it apply to: the
whole snippet of text, or each character on its own, or each run of characters
of a given sort. Note that we work width-first, as it were: we complete each
rule across the whole snippet before moving on to the next.

=
void Painter::execute(hash_table *HT, colouring_language_block *block, text_stream *matter,
	text_stream *colouring, int from, int to) {
	if (block == NULL) internal_error("no block");
	TEMPORARY_TEXT(colouring_at_start);
	Str::copy(colouring_at_start, colouring);
	colouring_rule *rule;
	LOOP_OVER_LINKED_LIST(rule, colouring_rule, block->rules) {
		switch (block->run) {
			case WHOLE_LINE_CRULE_RUN:
				Painter::execute_rule(HT, rule, matter, colouring, from, to);
				break;
			case CHARACTERS_CRULE_RUN:
				for (int i=from; i<=to; i++)
					Painter::execute_rule(HT, rule, matter, colouring, i, i);
				break;
			case INSTANCES_CRULE_RUN: {
				int L = Str::len(block->run_instance) - 1;
				if (L >= 0)
					for (int i=from; i<=to - L; i++)
						if (ACMESupport::text_at(matter, i, block->run_instance)) {
							Painter::execute_rule(HT, rule, matter, colouring, i, i+L);
							i += L;
						}
				break;
			}
			default: {
				int ident_from = -1;
				for (int i=from; i<=to; i++) {
					int col = Str::get_at(colouring_at_start, i);
					if ((col == block->run) ||
						((block->run == UNQUOTED_COLOUR) &&
							((col != STRING_COLOUR) && (col != CHAR_LITERAL_COLOUR)))) {
						if (ident_from == -1) ident_from = i;
					} else {
						if (ident_from >= 0)
							Painter::execute_rule(HT, rule, matter, colouring, ident_from, i-1);
						ident_from = -1;
					}
				}
				if (ident_from >= 0)
					Painter::execute_rule(HT, rule, matter, colouring, ident_from, to);
				break;
			}
		}
	}
	DISCARD_TEXT(colouring_at_start);
}

@ Rules have the form: if X, then Y.

=
void Painter::execute_rule(hash_table *HT, colouring_rule *rule, text_stream *matter,
	text_stream *colouring, int from, int to) {
	if (Painter::satisfies(HT, rule, matter, colouring, from, to))
		Painter::follow(HT, rule, matter, colouring, from, to);
}

@ Here we test the "if X":

@d UNSPACED_RULE_PREFIX 2 /* for |prefix P| */
@d SPACED_RULE_PREFIX 3 /* for |spaced prefix P| */
@d OPTIONALLY_SPACED_RULE_PREFIX 4 /* for |optionally spaced prefix P| */
@d UNSPACED_RULE_SUFFIX 5 /* for |suffix P| */
@d SPACED_RULE_SUFFIX 6 /* for |spaced suffix P| */
@d OPTIONALLY_SPACED_RULE_SUFFIX 7 /* for |optionally spaced suffix P| */


=
int Painter::satisfies(hash_table *HT, colouring_rule *rule, text_stream *matter,
	text_stream *colouring, int from, int to) {
	if (Str::len(rule->match_text) > 0) {
		if ((rule->match_prefix == UNSPACED_RULE_PREFIX) ||
			(rule->match_prefix == SPACED_RULE_PREFIX) ||
			(rule->match_prefix == OPTIONALLY_SPACED_RULE_PREFIX)) {
			int pos = from;
			if (rule->match_prefix != UNSPACED_RULE_PREFIX) {
				while ((pos > 0) && (Characters::is_whitespace(pos-1))) pos--;
				if ((rule->match_prefix == SPACED_RULE_PREFIX) && (pos == from))
					return FALSE;
			}
			if (ACMESupport::text_at(matter,
				pos-Str::len(rule->match_text), rule->match_text) == FALSE)
				return FALSE;
			rule->fix_position = pos-Str::len(rule->match_text);
		} else if ((rule->match_prefix == UNSPACED_RULE_SUFFIX) ||
			(rule->match_prefix == SPACED_RULE_SUFFIX) ||
			(rule->match_prefix == OPTIONALLY_SPACED_RULE_SUFFIX)) {
			int pos = from + Str::len(rule->match_text);
			if (rule->match_prefix != UNSPACED_RULE_SUFFIX) {
				while ((pos < Str::len(rule->match_text)) && (Characters::is_whitespace(pos))) pos++;
				if ((rule->match_prefix == SPACED_RULE_SUFFIX) && (pos == from))
					return FALSE;
			}
			if (ACMESupport::text_at(matter, pos, rule->match_text) == FALSE)
				return FALSE;
			rule->fix_position = pos;
		} else {
			if (Str::ne(matter, rule->match_text)) return FALSE;
		}
	} else if (rule->match_keyword_of_colour != NOT_A_COLOUR) {
		TEMPORARY_TEXT(id);
		Str::substr(id, Str::at(matter, from), Str::at(matter, to+1));
		int rw = Analyser::is_reserved_word(HT, id, rule->match_keyword_of_colour);
		DISCARD_TEXT(id);
		if (rw == FALSE) return FALSE;
	} else if (rule->match_colour != NOT_A_COLOUR) {
		for (int i=from; i<=to; i++)
			if (Str::get_at(colouring, i) != rule->match_colour)
				return FALSE;
	}
	return TRUE;
}

@ And here we carry out the "then Y":

=
void Painter::follow(hash_table *HT, colouring_rule *rule, text_stream *matter,
	text_stream *colouring, int from, int to) {
	if (rule->execute_block)
		Painter::execute(HT, rule->execute_block, matter, colouring, from, to);
	else if (rule->debug) @<Print some debugging text@>
	else {
		if (rule->set_to_colour != NOT_A_COLOUR)
			for (int i=from; i<=to; i++)
				Str::put_at(colouring, i, rule->set_to_colour);
		if (rule->set_prefix_to_colour != NOT_A_COLOUR)
			for (int i=rule->fix_position; i<rule->fix_position+Str::len(rule->match_text); i++)
				Str::put_at(colouring, i, rule->set_prefix_to_colour);
	}
}

@<Print some debugging text@> =
	PRINT("[%d, %d] text: ", from, to);
	for (int i=from; i<=to; i++)
		PUT_TO(STDOUT, Str::get_at(matter, i));
	PRINT("\n[%d, %d] cols: ", from, to);
	for (int i=from; i<=to; i++)
		PUT_TO(STDOUT, Str::get_at(colouring, i));
	PRINT("\n");
