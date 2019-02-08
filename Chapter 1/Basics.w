[Basics::] Basics.

Some fundamental definitions, mostly setting up for the Foundation module
to manage memory for us.

@h Build identity.
First we define the build, using a notation which tangles out to the current
build number as specified in the contents section of this web.

@d INTOOL_NAME "inweb"
@d INWEB_BUILD "[[Version Number]]"

@h Setting up the memory manager.
We need to itemise the structures we'll want to allocate. To explicate this
see Foundation, but these are all struct names with either |_MT| or, in one
case, |_array_MT| appended. MT stands for "memory type".

@e bibliographic_datum_MT
@e c_structure_MT
@e chapter_MT
@e para_macro_MT
@e enumeration_set_MT
@e function_MT
@e hash_table_entry_MT
@e hash_table_entry_usage_MT
@e macro_usage_MT
@e module_MT
@e module_search_MT
@e nonterminal_variable_MT
@e paragraph_MT
@e paragraph_tagging_MT
@e preform_nonterminal_MT
@e programming_language_MT
@e section_MT
@e source_line_array_MT
@e structure_element_MT
@e tangle_target_MT
@e tex_results_MT
@e text_literal_MT
@e theme_tag_MT
@e weave_format_MT
@e weave_pattern_MT
@e weave_target_MT
@e web_MT

@ And then expand the following macros, all defined in Foundation. This
makes all the necessary constructor functions for creating objects of these
types.

=
ALLOCATE_IN_ARRAYS(source_line, 1000)
ALLOCATE_INDIVIDUALLY(bibliographic_datum)
ALLOCATE_INDIVIDUALLY(c_structure)
ALLOCATE_INDIVIDUALLY(chapter)
ALLOCATE_INDIVIDUALLY(para_macro)
ALLOCATE_INDIVIDUALLY(enumeration_set)
ALLOCATE_INDIVIDUALLY(function)
ALLOCATE_INDIVIDUALLY(hash_table_entry_usage)
ALLOCATE_INDIVIDUALLY(hash_table_entry)
ALLOCATE_INDIVIDUALLY(macro_usage)
ALLOCATE_INDIVIDUALLY(module)
ALLOCATE_INDIVIDUALLY(module_search)
ALLOCATE_INDIVIDUALLY(nonterminal_variable)
ALLOCATE_INDIVIDUALLY(paragraph_tagging)
ALLOCATE_INDIVIDUALLY(paragraph)
ALLOCATE_INDIVIDUALLY(preform_nonterminal)
ALLOCATE_INDIVIDUALLY(programming_language)
ALLOCATE_INDIVIDUALLY(tex_results)
ALLOCATE_INDIVIDUALLY(section)
ALLOCATE_INDIVIDUALLY(structure_element)
ALLOCATE_INDIVIDUALLY(tangle_target)
ALLOCATE_INDIVIDUALLY(text_literal)
ALLOCATE_INDIVIDUALLY(theme_tag)
ALLOCATE_INDIVIDUALLY(weave_format)
ALLOCATE_INDIVIDUALLY(weave_pattern)
ALLOCATE_INDIVIDUALLY(weave_target)
ALLOCATE_INDIVIDUALLY(web)