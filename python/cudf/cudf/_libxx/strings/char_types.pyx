# Copyright (c) 2020, NVIDIA CORPORATION.

from cudf._libxx.move cimport move
from cudf._libxx.cpp.column.column_view cimport column_view
from libcpp.memory cimport unique_ptr
from cudf._libxx.column cimport Column

from cudf._libxx.strings.char_types cimport (
    all_characters_of_type as cpp_all_characters_of_type,
    string_character_types as string_character_types
)


def is_decimal(Column source_strings):
    cdef unique_ptr[column] c_result
    cdef column_view source_view = source_strings.view()

    with nogil:
        c_result = move(cpp_all_characters_of_type(
            source_view,
            string_character_types.DECIMAL
        ))

    return Column.from_unique_ptr(move(c_result))


def is_alnum(Column source_strings):
    cdef unique_ptr[column] c_result
    cdef column_view source_view = source_strings.view()

    with nogil:
        c_result = move(cpp_all_characters_of_type(
            source_view,
            string_character_types.ALPHANUM
        ))

    return Column.from_unique_ptr(move(c_result))


def is_alpha(Column source_strings):
    cdef unique_ptr[column] c_result
    cdef column_view source_view = source_strings.view()

    with nogil:
        c_result = move(cpp_all_characters_of_type(
            source_view,
            string_character_types.ALPHA
        ))

    return Column.from_unique_ptr(move(c_result))


def is_digit(Column source_strings):
    cdef unique_ptr[column] c_result
    cdef column_view source_view = source_strings.view()

    with nogil:
        c_result = move(cpp_all_characters_of_type(
            source_view,
            string_character_types.DIGIT
        ))

    return Column.from_unique_ptr(move(c_result))


def is_numeric(Column source_strings):
    cdef unique_ptr[column] c_result
    cdef column_view source_view = source_strings.view()

    with nogil:
        c_result = move(cpp_all_characters_of_type(
            source_view,
            string_character_types.NUMERIC
        ))

    return Column.from_unique_ptr(move(c_result))
