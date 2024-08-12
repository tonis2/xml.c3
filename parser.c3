module xml;

import std::io;
import std::core;
import std::math;
import std::collections::list;
import std::collections::map;

def Attribute = HashMap(<String, String>);

struct Node {
	String name;
	String value;
	Attribute attributes;
	List(<Node>) children;
}

struct Parser {
	Allocator allocator;
	DString buffer;
	InStream stream;
	XMLToken token;
	Node active_node;
	char current_char;
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
	CLOSE_TAG,
	END_TAG,
	ATTRIBUTE_START,
	TEXT,
	COMMENT,
}

def SearchCallback = fn bool (char value);

fn XMLToken! Parser.advance(&self)
{
	char c;
	while WS: (c = self.read_next()!)
	{
		switch (c)
		{
			case '\n':
				self.line++;
				nextcase;
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
			if (self.peek(fn (character) => character == '/')!) {
				self.stream.seek(self.active_node.name.len + 1, Seek.CURSOR)!;
				nextcase;
			}
			
			self.token = XMLToken.START_TAG;
			// Read token name
			while (self.peek(fn (character) => character != ' ' && character != '>')!) {
				c = self.read_next()!;
				self.buffer.append_char(c);
			}
		case '/':
			self.token = XMLToken.CLOSE_TAG;
		case '>':
			self.token = XMLToken.END_TAG;
		case ' ':
			self.token = XMLToken.ATTRIBUTE_START;
			usz! attribute_size = self.seek(fn (character) => character == '"', .skip = 1);

			if (catch err = attribute_size) {
				io::printfn("failed to parse attribute");
				return XMLParserError.UNEXPECTED_CHARACTER?;
			}
			// Set stream back to start pos
			self.stream.seek(-(attribute_size + 2), Seek.CURSOR)!;

			// Add whole attribute to buffer
			for (uint i; i < attribute_size + 2; i++) {
				self.buffer.append_char(self.read_next()!);
			};
		default:
			io::printfn("not found char %c", c);
			return XMLParserError.UNEXPECTED_CHARACTER?;
	}

	return self.token;
}



fn usz! Parser.seek(&self, SearchCallback search, uint skip = 0)
{
	char c;
	usz offset;
	uint skipped = 0;
	// Find the char
	while (c = self.stream.read_byte()!) {
		if (search(c)) {
			if (skipped == skip) {break;}
			else {
				skipped += 1; 
				continue;
			};
		};
	
		offset++;
	};
	return offset;
}

fn bool! Parser.peek(&self, SearchCallback search)
{
	bool response = search(self.stream.read_byte()!);
	// Set stream back to start pos
	self.stream.seek(-1, Seek.CURSOR)!;
	return response;
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

fn void Node.free(&self)
{
	self.attributes.free();
	self.children.free();
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
		while (try parser.advance()) {
			io::printfn("token %s", parser.token);
			switch (parser.token) {
				case START_TAG: {
					// Add new node
					parser.active_node.name = parser.buffer.copy_str();
					parser.buffer.clear();
					io::printfn("%s", parser.active_node.name);
				}
				case END_TAG: 
				case CLOSE_TAG: {
					// Add new node
					// parser.active_node.name = parser.buffer.copy_str();
					// parser.buffer.clear();
					// io::printfn("%s", parser.active_node.name);
				}
				case ATTRIBUTE_START: {
					// Add new node
					String[] attribute = parser.buffer.str_view().split("=");
					parser.active_node.attributes.set(attribute[0].copy(), attribute[1].copy());
					io::printfn("attribute %s", attribute);

					parser.buffer.clear();
					free(attribute);
				}
				default: {
					break;
				}
			}
		}
	};

	return root_node;
}

