import std::io;
import std::core;
import std::math;
import std::collections::list;
import xml;

const XML_STRING = `<registry>
</registry>`;

fn void! main() {
    xml::Node root_node = xml::parse_string(XML_STRING)!!;
}