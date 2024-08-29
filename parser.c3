module xml;

import std::io;
import std::core;
import std::math;
import std::collections::list;
import std::collections::map;
import std::ascii;

def Attribute = HashMap(<String, String>);
def NodeList = List(<Node*>);

struct Node {
	String name;
	String value;
	String header;
	Attribute attributes;
	List(<Node>) children;
}

struct Parser {
	Allocator allocator;
	InStream stream;
	DString buffer;
	XMLToken token;
	Node* active_node;
	List(<Node*>) open_nodes;
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
	foreach (&child: self.children) child.find(search_fn, cache);
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
			// Parses header value
			usz size = self.seek(fn (character) => character == '>', .return_pos = true)!;
			for (uint i; i < size; i++) self.buffer.append(self.stream.read_byte()!);
			break;
		}
		case c == '<' && self.peek(fn (character) => character != '/')!: {
			self.token = START_TAG;
			self.stream.seek(1, Seek.CURSOR)!;
			// Parser tag name
			usz size = self.seek(fn (character) => character == '>' || character == ' ', .return_pos = true)!;
			for (uint i = 0; i < size; i++) self.buffer.append(self.stream.read_byte()!);
			
			break;
		}
		case c == '>' && (self.token == START_TAG || self.token == ATTRIBUTE): {
			self.token = END_TAG;
			break;
		}
		case c == '/' && self.peek(fn (character) => character == '>')!: {
			self.token = CLOSE_TAG;
			self.seek(fn (character) => character == '>')!;
			break;
		}
		case c == '<' && self.peek(fn (character) => character == '/')!: {
			self.token = CLOSE_TAG;
			self.seek(fn (character) => character == '>')!;
			break;
		}
		case std::ascii::is_print(c) && (self.token == START_TAG || self.token == ATTRIBUTE): {
			self.token = ATTRIBUTE;
			//Parser attribute value
			usz size = self.seek(fn (character) => character == '"', .skip = 1, .return_pos = true)!;
			for (uint i; i < size + 1; i++) self.buffer.append(self.stream.read_byte()!);
			break;
		}
		case std::ascii::is_print(c): {
			self.token = VALUE;
			// Parses value
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


fn Node! parse_string(String s, Allocator allocator = allocator::heap()) => parse(ByteReader{}.init(s), allocator);
fn Node! load_file (String path, Allocator allocator = allocator::heap()) {
    File! file = file::open(path, "r");
    defer file.close()!!;

    if (catch err = file) {
        io::printfn("Failed to find the xml file");
        return XMLParserError.FILE_NOT_FOUND?;
    }

    return parse(&file, allocator);
}


fn Node! parse(InStream s, Allocator allocator = allocator::heap())
{
	Node root_node;
	Parser parser = { .buffer = dstring::temp_with_capacity(64), .stream = s, .allocator = allocator, .active_node = &root_node};
	defer parser.free();

	while (try parser.advance()) {
			switch (parser.token) {
				case START_TAG: {
					if (parser.open_nodes.len() == 0) {
						// Root node
						parser.active_node.name = parser.buffer.copy_str();
					} else {
						// Push node as child
						Node* parent_node = parser.open_nodes[parser.open_nodes.len() - 1];

						parent_node.children.push(Node {
							.name = parser.buffer.copy_str()
						});

						parser.active_node = &parent_node.children[parent_node.children.len() - 1];
					}
				
					parser.open_nodes.push(parser.active_node);
					parser.buffer.clear();
				}
				case END_TAG: {
					// io::printfn("end tag %s", parser.active_node.name);
				}
				case CLOSE_TAG: {
					parser.open_nodes.pop()!;
				}
				case VALUE: {
					parser.active_node.value = parser.buffer.copy_str();
					parser.buffer.clear();
				}
				case ATTRIBUTE: {
					String data = parser.buffer.str_view();
					usz split_index = data.index_of_char('=')!;
					bool empty_value = (data.len - split_index) <= 3;

					// Add attribute to hashmap
					parser.active_node.attributes.set(data[0..split_index - 1].copy(), empty_value ? "" : data[split_index + 2..parser.buffer.len() - 2].copy());
					parser.buffer.clear();
				}
				case HEADER: {
					parser.active_node.header = parser.buffer.copy_str();
					parser.buffer.clear();
				}
				default: {
					break;
				}
			}
	}

	return root_node;
}


fn void Parser.free(&self)
{
	self.buffer.free();
	self.open_nodes.free();
}

fn void Node.free(&self)
{
	foreach (child: self.children) child.free();
	self.attributes.free();
	self.children.free();
	self.name.free();
	self.value.free();
	self.header.free();
}

