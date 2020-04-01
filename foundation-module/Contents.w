Title: foundation
Author: Graham Nelson
Purpose: A library of common code used by all of the Inform tools.
Language: InC
Licence: Artistic License 2.0

Chapter 1: Setting Up
"Absolute basics."
	Foundation
	POSIX Platforms ^"ifdef-PLATFORM_POSIX"
	Windows Platform ^"ifdef-PLATFORM_WINDOWS"

Chapter 2: Memory, Streams and Collections
"Creating objects in memory, and forming lists, hashes, and text streams."
	Debugging Log
	Memory
	Streams
	Writers and Loggers
	Methods
	Linked Lists and Stacks
	Dictionaries

Chapter 3: The Operating System
"Dealing with the host operating system."
	Error Messages
	Command Line Arguments
	Pathnames
	Filenames
	Case-Insensitive Filenames
	Shell
	Directories
	Time

Chapter 4: Text Handling
"Reading, writing and parsing text."
	Characters
	C Strings
	Wide Strings
	String Manipulation
	Text Files
	Tries and Avinues
	Pattern Matching

Chapter 5: Generating Websites
"For making individual web pages, or gathering them into mini-sites or ebooks."
	HTML
	Epub Ebooks

Chapter 6: Media
"Examining image and sound files."
	Binary Files
	Image Dimensions
	Sound Durations

Chapter 7: Semantic Versioning
"For reading, storing and comparing standard semantic version numbers."
	Version Numbers
	Version Number Ranges

Chapter 8: Literate Programming
	Bibliographic Data for Webs
	Web Structure
	Web Modules
	Build Files
