import std::io;
import std::core;
import std::math;
import std::collections::list;
import xml;

const XML1 = `<registry>
</registry>`;

const XML2 = `<command queues="graphics" renderpass="inside" cmdbufferlevel="primary,secondary" tasks="state">
    <registry name="test">
    </registry>
</command>`;

fn void! main() {
    xml::Node root_node = xml::parse_string(XML2)!!;

    io::printfn("%d", root_node.children.len());
    defer root_node.free();
}