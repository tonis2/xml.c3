module xml_test @test;

import std::io;
import std::core;
import std::math;
import std::collections::list;
import xml;
    
fn void xml_file_parsing1() {

    xml::Parser parser = xml::load_file("assets/test.html")!!;
    defer parser.free();

    Node node = parser.root;
  
    assert(node.header == "DOCTYPE html");
    assert(node.name == "html");
    assert(node.children.len() == 1);
    assert(node.children[0].children.len() == 2);
    assert(node.children[0].children[0].name == "h1");
    assert(node.children[0].children[0].attributes.get("struct")!! == "VkVideoDecodeCapabilitiesKHR");
    assert(node.children[0].children[1].name == "p");
    assert(node.children[0].children[1].attributes.get("type")!! == "jabascript");
    assert(node.children[0].children[1].value == "My first paragraph.");
}

fn void xml_file_parsing2() {
    xml::Parser parser = xml::load_file("assets/vk_test.xml")!!;
    defer parser.free();

    Node node = parser.root;

    assert(node.name == "registry");
    assert(node.children.len() == 4);

    assert(node.children[0].name == "comment");
    assert(node.children[2].children.len() == 16);

    NodeList members;
    defer members.free();

    NodeList types;
    defer types.free();

    NodeList command_nodes;
    defer command_nodes.free();

    node.find(fn (node) => node.name == "member", &members);
    node.find(fn (node) => node.name == "type" && node.attributes.has_key("category"), &types);

    node.find(fn (node) {
        if (node.name == "type" && node.attributes.has_key("name") && node.attributes["name"]!! == "test") {
            Node child_node = node.children[0];
            if (child_node.attributes["values"]!! == "VK_STRUCTURE_TYPE_RENDERING_FRAGMENT_SHADING_RATE_ATTACHMENT_INFO_KHR") {
                return true;
            };
            return false;
        }
        return false;
    }, &command_nodes);

    assert(members.len() == 14);
    assert(types.len() == 4);
    assert(command_nodes.len() == 1);
    
    assert(types[0].attributes.get("name")!! == "VkRenderingAttachmentInfoKHR");
    assert(types[1].attributes.get("name")!! == "VkRenderingFragmentShadingRateAttachmentInfoKHR");
    assert(types[3].attributes.get("name")!! == "VkRenderingFragmentDensityMapAttachmentInfoEXT");
}

fn void xml_file_parsing3() {
    xml::Parser parser = xml::load_file("assets/test.xml")!!;
    defer parser.free();

    Node node = parser.root;
    assert(node.children.len() == 8);
    assert(node.children[2].children.len() == 2);
    assert(node.children[6].children.len() == 2);
    assert(node.children[7].children.len() == 2);
}
