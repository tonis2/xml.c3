module xml;

import std::io;
import std::core;
import std::math;
import std::collections::list;
import std::collections::map;
import std::ascii;

def Attribute = HashMap(<String, String>);
def NodeList = List(<Node*>);

struct Document {
	Node root;
	String header;
}

struct Node {
	String name;
	String value;
	Attribute attributes;
	bool closed;
	List(<Node>) children;
}

struct Parser {
	Allocator allocator;
	InStream stream;
	DString buffer;
	XMLToken token;
	Document* doc;
	Node* active_node;
	usz line;
}

fault XMLParserError
{
	EOF,
	UNEXPECTED_CHARACTER,
	FILE_NOT_FOUND
}

enum XMLToken @local
{
	START_TAG,
	CLOSE_TAG,
	END_TAG,
	ATTRIBUTE,
	VALUE,
	HEADER,
}

def NodeSearch = fn bool (Node*);
def ParserSearch = fn bool (char value);

fn void Node.find(&self, NodeSearch search_fn, NodeList* cache) {
	if (search_fn(self)) cache.push(self);
	foreach (child: self.children) child.find(search_fn, cache);
}

fn void! Parser.advance(&self)
{
	char c;
	while WS: (c = self.stream.read_byte()!)
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

	switch (true)
	{
		case c == '<' && self.peek(fn (character) => character == '!')!: {
			self.token = HEADER;
			self.stream.seek(2, Seek.CURSOR)!;
			
			usz size = self.seek(fn (character) => character == '>', .return_pos = true)!;
			for (uint i; i < size; i++) self.buffer.append(self.stream.read_byte()!);
			break;
		}
		case c == '<' && self.peek(fn (character) => character != '/')!: {
			self.token = START_TAG;
			self.stream.seek(1, Seek.CURSOR)!;
			// Start node
			usz size = self.seek(fn (character) => character == '>' || character == ' ', .return_pos = true)!;
			for (uint i = 0; i < size; i++) self.buffer.append(self.stream.read_byte()!);
			
			break;
		}
		case c == '/' || c == '>': {
			self.token = END_TAG;
			break;
		}
		case c == '<' && self.peek(fn (character) => character == '/')!: {
			self.token = CLOSE_TAG;
			self.seek(fn (character) => character == '>')!;
			break;
		}
		case std::ascii::is_print(c) && (self.token == START_TAG || self.token == ATTRIBUTE): {
			self.token = ATTRIBUTE;
			usz size = self.seek(fn (character) => character == '"', .skip = 1, .return_pos = true)!;
			for (uint i; i < size + 1; i++) self.buffer.append(self.stream.read_byte()!);
			break;
		}
		case std::ascii::is_print(c): {
			self.token = VALUE;
			usz size = self.seek(fn (character) => character == '<', .return_pos = true)!;
			for (uint i; i < size; i++) self.buffer.append(self.stream.read_byte()!);
			break;
		}
		default:
			io::printfn("not found char %c", c);
			return XMLParserError.UNEXPECTED_CHARACTER?;
	}
}



fn usz! Parser.seek(&self, ParserSearch search, uint skip = 0, bool return_pos = false)
{
	usz offset;
	uint skipped = 0;
	char c;
	// Find the char
	while (c = self.stream.read_byte()!) {
		offset++;
		if (search(c)) {
			if (skipped == skip) {break;}
			else {
				skipped += 1; 
				continue;
			};
		};
	};

	if (return_pos) self.stream.seek(-(offset + 1), Seek.CURSOR)!;
	return offset;
}

fn bool! Parser.peek(&self, ParserSearch search)
{
	bool response = search(self.stream.read_byte()!);
	// Set stream back to start pos
	self.stream.seek(-1, Seek.CURSOR)!;
	return response;
}


fn Document! parse_string(String s, Allocator allocator = allocator::temp()) => parse(ByteReader{}.init(s), allocator);
fn Document! load_file (String path, Allocator allocator = allocator::temp()) {
    File! file = file::open(path, "r");
    defer file.close()!!;

    if (catch err = file) {
        io::printfn("Failed to find the xml file");
        return XMLParserError.FILE_NOT_FOUND?;
    }

    return parse(&file, allocator);
}


fn Document! parse(InStream s, Allocator allocator = allocator::temp())
{
	Document document;

	Parser parser = { .buffer = dstring::temp_with_capacity(64), .stream = s, .allocator = allocator, .doc = &document };
	defer parser.free();

	while (try parser.advance()) {
			switch (parser.token) {
				case START_TAG: {
					io::printfn("name %s", parser.buffer);
					parser.buffer.clear();
				}
				case END_TAG: {}
				case CLOSE_TAG: {}
				case VALUE: {
					io::printfn("value %s", parser.buffer);
					parser.buffer.clear();
				}
				case ATTRIBUTE: {
					io::printfn("attr %s", parser.buffer);
					parser.buffer.clear();
				}
				case HEADER: {
					io::printfn("header %s", parser.buffer);
					parser.buffer.clear();
				}
				default: {
					break;
				}
			}
	}

	return document;
}


fn void Parser.free(&self)
{
	self.buffer.free();
}

fn void Node.free(&self)
{
	self.attributes.free();
	self.children.free();
	self.name.free();
	self.value.free();
}

fn void Document.free(&self)
{

}
