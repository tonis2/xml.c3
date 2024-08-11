module xml;

import std::io;
import std::core;
import std::math;
import std::collections::list;

struct Attribute {
	String name;
	String value;
}

struct Node {
	String name;
	String value;
	List(<Attribute>) attributes;
	List(<Node>) children;
}

struct Parser {
	Allocator allocator;
	DString buffer;
	InStream stream;
	XMLToken token;
	Node active_node;
	char current;
	uint line;
}

fault XMLParserError
{
	EOF,
	UNEXPECTED_CHARACTER,
	INVALID_ESCAPE_SEQUENCE,
	DUPLICATE_MEMBERS,
	INVALID_NUMBER,
}

enum XMLToken @local
{
	START_DOCUMENT,
	END_DOCUMENT,
	START_TAG,
	END_TAG,
	CLOSE_TAG,
	ATTRIBUTE_START,
	ATTRIBUTE_END,
	TEXT,
	COMMENT,
}

enum SeekDirection @local
{
	FORWARD,
	BACKWARD,
}

fn void! Parser.advance(&self)
{
	char c;
	while WS: (c = self.read_next()!)
	{
		switch (c)
		{
			case '\n':
				self.line++;
				nextcase;
			case ' ':
			case '\t':
			case '\r':
			case '\v':
				continue;
			default:
				break WS;
		}
	}

	switch (c)
	{
		case '<':
			self.token = XMLToken.START_TAG;
		case '>':
			self.token = XMLToken.END_TAG;
		case '/':
			self.token = XMLToken.CLOSE_TAG;
		default:
			io::printfn("not found char %c", c);
			return XMLParserError.UNEXPECTED_CHARACTER?;
	}
}

fn usz! Parser.seek(&self, char value)
{
	char c;
	usz offset;
	// Find the char
	while (c = self.stream.read_byte()!) {
		if (c == value) break;
		offset++;
	};
	// Set stream back to start pos
	self.stream.seek(-(offset + 1), Seek.CURSOR)!;
	return offset;
}

fn char! Parser.read_next(&self)
{
	char! c = self.stream.read_byte()!;
	if (catch err = c)
	{
		case XMLParserError.EOF:
			self.token = END_DOCUMENT;
			return err?;
		default:
			return err?;
	}
	if (c == 0)
	{
		self.token = END_DOCUMENT;
	}
	return c;
}

fn void Parser.free(&self)
{
	self.buffer.free();
}

fn Node! parse_string(String s, Allocator allocator = allocator::heap())
{
	return parse(ByteReader{}.init(s), allocator);
}

fn Node! parse(InStream s, Allocator allocator = allocator::heap())
{
	Node root_node;
	Parser parser = { .buffer = dstring::new_with_capacity(64, allocator), .stream = s, .allocator = allocator, .active_node = root_node };
	defer parser.free();

	@pool(allocator)
	{
		// for (uint i = 0; i < 10; i++) {
		// 	XMLToken token = parser.advance()!;
		// 	switch (parser.token) {
		// 		case START_TAG: {
		// 			usz name_end_pos = parser.seek('>')!;
		// 			io::printfn("name %d", name_end_pos);
		// 		}
		// 		default: {
		// 			break;
		// 		}
		// 	}
		// 	io::printfn("token %s", token);
		// }

		parser.advance()!;

		switch (parser.token) {
			case START_TAG: {
				usz name_size = parser.seek('>')!;
				char[] buffer = allocator::new_array(allocator, char, name_size);
				parser.stream.read(buffer)!;
				parser.active_node.name = (String)buffer;
			}
			default: {
				break;
			}
		}
		io::printfn("token %s", parser.token);
		io::printfn("node name %s", parser.active_node.name);
		// while (parser.token != END_DOCUMENT) {
		// 	XMLToken token = parser.advance();
		// }
	};

	return root_node;
}

