module xml_test @test;

import std::io;
import std::core;
import std::math;
import std::collections::list;
import xml;
    
fn void! xml_file_parsing1() {

    xml::Node node = xml::load_file("assets/test.html")!;
    defer node.free();

    assert(node.header == "DOCTYPE html");
    assert(node.name == "html");
    assert(node.children.len() == 1);
    assert(node.children[0].children.len() == 2);
    assert(node.children[0].children[0].name == "h1");
    assert(node.children[0].children[0].attributes.get("struct")! == "VkVideoDecodeCapabilitiesKHR");
    assert(node.children[0].children[1].name == "p");
    assert(node.children[0].children[1].attributes.get("type")! == "jabascript");
    assert(node.children[0].children[1].value == "My first paragraph.");
}

fn void! xml_file_parsing2() {
    xml::Node root_node = xml::load_file("assets/vk_test.xml")!;
    defer root_node.free();

    assert(root_node.name == "registry");
    assert(root_node.children.len() == 4);
    assert(root_node.children[0].name == "comment");
    assert(root_node.children[2].children.len() == 16);

    List(<Node*>) members;
    defer members.free();

    List(<Node*>) types;
    defer types.free();

    root_node.find(fn (node) => node.name == "member", &members);
    root_node.find(fn (node) => node.name == "type" && node.attributes.has_key("category"), &types);

    assert(members.len() == 9);
    assert(types.len() == 3);
    
    assert(types[0].attributes.get("name")! == "VkRenderingAttachmentInfoKHR");
    assert(types[1].attributes.get("name")! == "VkRenderingFragmentShadingRateAttachmentInfoKHR");
    assert(types[2].attributes.get("name")! == "VkRenderingFragmentDensityMapAttachmentInfoEXT");
}

fn void! xml_file_parsing3() {
    xml::Node root_node = xml::load_file("assets/test.xml")!;
    assert(root_node.children.len() == 8);
    assert(root_node.children[2].children.len() == 2);
    assert(root_node.children[6].children.len() == 2);
    assert(root_node.children[7].children.len() == 2);
    defer root_node.free();
}
