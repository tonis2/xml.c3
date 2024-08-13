import std::io;
import std::core;
import std::math;
import std::collections::list;
import xml;

const XML1 = `<registry>
</registry>`;

const XML2 = `<command queues="graphics" renderpass="inside" cmdbufferlevel="primary,secondary" tasks="state">
                    <registry name="test">
                        TEST
                    </registry>
                    <registry name="test2">
                    </registry>
              </command>`;

fn void! main() {
    xml::Node root_node = xml::parse_string(XML2)!!;

    // assert(root_node.name == "command");
    // assert(root_node.children[0].name == "registry");
    // assert(root_node.children.len() == 2);

    io::printfn("children %d", root_node.children.len());
    // io::printfn("name %s", root_node.children[0].value);
    // io::printfn("name2 %s", root_node.children[1].value);
    defer root_node.free();
}