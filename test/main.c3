import std::io;
import std::core;
import std::math;
import std::collections::list;
import xml;

const XML1 = `<registry>
</registry>`;

const XML2 = `<command queues="graphics" renderpass="inside" cmdbufferlevel="primary,secondary" tasks="state"></command>`;

fn void! main() {
    xml::Node root_node = xml::parse_string(XML2)!!;
    defer root_node.free();
}