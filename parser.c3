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
	Node* root;
	String header;
	List(<Node>) children;
}

struct Node {
	String name;
	String value;
	Attribute attributes;
	bool closed;
	List(<Node*>) children;
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
	START_DOCUMENT,
	END_DOCUMENT,
	START_TAG,
	CLOSE_TAG,
	END_TAG,
	ATTRIBUTE_START,
	VALUE_START,
	HEADER,
}

def NodeSearch = fn bool (Node*);
def ParserSearch = fn bool (char value);

fn void Node.find(&self, NodeSearch search_fn, NodeList* cache) {
	if (search_fn(self)) cache.push(self);

	foreach (child: self.children) child.find(search_fn, cache);
}

fn XMLToken! Parser.advance(&self)
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
		case c == '/' && self.peek(fn (character) => character == '>')! : {
			// Close node
			self.token = XMLToken.CLOSE_TAG;
			self.seek(fn (character) => character == '>')!;
			break;
		}
		case c == '<' && self.peek(fn (character) => character == '/')! : {
			// Close node
			self.token = XMLToken.CLOSE_TAG;
			self.seek(fn (character) => character == '>')!;
			break;
		}
		case c == '<' && self.peek(fn (character) => character == '!')! : {
			// Header node
			self.token = XMLToken.HEADER;
			self.stream.seek(1, Seek.CURSOR)!;

			while (self.peek(fn (character) => character != '>')!) {
				self.buffer.append_char(self.stream.read_byte()!);
			}
			break;
		}
		case c == '<': {
			// Start node, read name to buffer
			self.token = XMLToken.START_TAG;
			while (self.peek(fn (character) => character != ' ' && character != '>')!) {
				self.buffer.append_char(self.stream.read_byte()!);
			}
			break;
		}
		case c == '>': {
			self.token = XMLToken.END_TAG;
			break;
		}
		case std::ascii::is_print(c) && (self.token == END_TAG || self.token == CLOSE_TAG): {
			// Read node value
			self.token = XMLToken.VALUE_START;
			self.buffer.append_char(c);

			while (self.peek(fn (character) => character != '<')!) {
				self.buffer.append_char(self.stream.read_byte()!);
			}
			break;
		}
		case std::ascii::is_print(c) && self.token == START_TAG: {
			self.stream.seek(-1, Seek.CURSOR)!;
			
			// Parse node attribute
			self.token = XMLToken.ATTRIBUTE_START;

			while (self.peek(fn (character) => character != '>')!) {
				DString name = dstring::temp_with_capacity(32);
				DString value = dstring::temp_with_capacity(32);

				// Read attribute name
				while (self.peek(fn (character) => character != '=')!) {
					char key = self.stream.read_byte()!;
					if (key != ' ') name.append_char(key);
				}

				// Skip "" on value
				self.stream.seek(2, Seek.CURSOR)!;

				while (self.peek(fn (character) => character != '"')!) {
					value.append_char(self.stream.read_byte()!);
				}

				self.stream.seek(1, Seek.CURSOR)!;
				self.active_node.attributes.set(name.copy_str(), value.copy_str());

				name.free();
				value.free();

				if (self.peek(fn (character) => character == '/')!) break;
			}
			break;
		}
		default:
			io::printfn("not found char %c", c);
			return XMLParserError.UNEXPECTED_CHARACTER?;
	}

	return self.token;
}



fn usz! Parser.seek(&self, ParserSearch search, uint skip = 0, bool debug = false, bool return_pos = false)
{
	usz offset;
	uint skipped = 0;
	char c;
	// Find the char
	while (c = self.stream.read_byte()!) {
		if (debug) io::printf("%c", c);
		if (search(c)) {
			if (skipped == skip) {break;}
			else {
				skipped += 1; 
				continue;
			};
		};
		offset++;
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

fn Node* Parser.get_node(&self, usz index)
{
	if (index > self.doc.children.len()) return null;
	return &self.doc.children[index];
}

fn Node* Parser.get_parent(&self, usz offset = 0)
{
	// Check for nodes that are not closed
	for (usz i = self.doc.children.len(); i > 0; i--) {
		Node* node = &self.doc.children[i - 1];
		if (node.closed == false) return node;
	}
	return null;
}

fn void Parser.close_last_node(&self)
{
	for (usz i = self.doc.children.len(); i > 0; i--) {
		Node* node = &self.doc.children[i - 1];
		if (node.closed == false) {
			node.closed = true;
			break;
		};
	}
}

fn Document! parse_string(String s, Allocator allocator = allocator::heap()) => parse(ByteReader{}.init(s), allocator);
fn Document! load_file (String path, Allocator allocator = allocator::heap()) {
    File! file = file::open(path, "r");
    defer file.close()!!;

    if (catch err = file) {
        io::printfn("Failed to find the xml file");
        return XMLParserError.FILE_NOT_FOUND?;
    }

    return parse(&file, allocator);
}


fn Document! parse(InStream s, Allocator allocator = allocator::heap())
{
	Document document;

	
	@pool() {
		Parser parser = { .buffer = dstring::temp_with_capacity(64), .stream = s, .allocator = allocator, .doc = &document };
		// defer parser.free();

		while (try parser.advance()) {
				switch (parser.token) {
					case START_TAG: {
						Node* parent_node = parser.get_parent();
						
						document.children.push(Node {
							.closed = false,
						});

						// Set created node as active
						parser.active_node = document.children.get_ref(document.children.len() - 1);

						// Set node name
						parser.active_node.name = parser.buffer.copy_str();
						parser.buffer.clear();

						// Push node to as correct parents child
						if (parent_node != null) {
							parent_node.children.push(document.children.get_ref(document.children.len() - 1));
						}
					}
					case END_TAG: {}
					case CLOSE_TAG: {
						// io::printfn("end tag %s %s", parser.active_node.name, parser.active_node.value);
						parser.close_last_node();
					}
					case VALUE_START: {
						// Copy buffer to node value
						Node* parent_node = parser.get_parent();
						if (parent_node != null) {
							parent_node.value = parser.buffer.copy_str();
						} else {
							io::printfn("parentless buffer %s", parser.buffer);
						}
						parser.buffer.clear();
					}
					case ATTRIBUTE_START: {}
					case HEADER: {
						parser.doc.header = parser.buffer.copy_str();
						parser.buffer.clear();
					}
					default: {
						break;
					}
				}
		}
	};
	document.root = &document.children[0];
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
	foreach (child: self.children) child.free();
	self.children.free();
}
