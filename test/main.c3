module xml_test @test;

import std::io;
import std::core;
import std::math;
import std::collections::list;
import xml;
    
fn void! xml_file_parsing1() {

    xml::Document test = xml::load_file("assets/test.xml")!;
    defer test.free();


    assert(test.root.children[0].name == "comment");
    assert(test.root.children[1].name == "comment");
    assert(test.root.attributes.get("name")! == "Decode");

    assert(test.root.children[3].children[0].name == "videorequirecapabilities");
    assert(test.root.children[3].children[0].attributes.get("struct")! == "VkVideoDecodeCapabilitiesKHR");
    assert(test.root.children[5].attributes.get("name")! == "DPB");
    assert(test.root.children[5].attributes.get("usage")! == "VK_IMAGE_USAGE_VIDEO_DECODE_DPB_BIT_KHR");
    assert(test.children.len() == 8);

    // Search
    NodeList video_formats;
    defer video_formats.free();
    
    test.root.find(fn (node) => node.name == "videoformat", &video_formats);

    assert(video_formats.len() == 3);
    assert(video_formats[0].attributes.len() == 2);
}  

fn void! xml_file_parsing2() {

    xml::Document vk = xml::load_file("assets/vk_test.xml")!;
    defer vk.free();
}   