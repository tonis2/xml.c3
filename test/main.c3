module xml_test @test;

import std::io;
import std::core;
import std::math;
import std::collections::list;
import xml;

const XML1 = `<command queues="graphics" renderpass="inside" cmdbufferlevel="primary,secondary" tasks="state">
                    <registry name="test">TEST</registry>
                    <registry2 name="test2"></registry2>
                    
              </command>`;


const XML2 = `<videocodec name="Decode">
                <comment>
                        Copyright 2015-2024 The Khronos Group Inc.

                        SPDX-License-Identifier: Apache-2.0 OR MIT
                </comment>

                <comment>
                        This file, vk.xml, is the Vulkan API Registry. It is a critically important
                        and normative part of the Vulkan Specification, including a canonical
                        machine-readable definition of the API, parameter and member validation
                        language incorporated into the Specification and reference pages, and other
                        material which is registered by Khronos, such as tags used by extension and
                        layer authors. The authoritative public version of vk.xml is maintained in
                        the default branch (currently named main) of the Khronos Vulkan GitHub
                        project. The authoritative private version is maintained in the default
                        branch of the member gitlab server.
                </comment>

                <videocapabilities struct="VkVideoDecodeCapabilitiesKHR"/>
                <videoformat name="Decode Output (Coincide)" usage="VK_IMAGE_USAGE_VIDEO_DECODE_DST_BIT_KHR+VK_IMAGE_USAGE_VIDEO_DECODE_DPB_BIT_KHR">
                    <videorequirecapabilities struct="VkVideoDecodeCapabilitiesKHR" member="flags" value="VK_VIDEO_DECODE_CAPABILITY_DPB_AND_OUTPUT_COINCIDE_BIT_KHR"/>
                </videoformat>
                <videoformat name="Decode Output (Distinct)" usage="VK_IMAGE_USAGE_VIDEO_DECODE_DST_BIT_KHR">
                </videoformat>
                <videoformat name="DPB" usage="VK_IMAGE_USAGE_VIDEO_DECODE_DPB_BIT_KHR"/>
            </videocodec>`;             

fn void! xml_string_parsing() {
    xml::Document doc1 = xml::parse_string(XML1)!!;
    xml::Document doc2 = xml::parse_string(XML2)!!;

    defer {
        doc1.free();
        doc2.free();
    };

    assert(doc1.root.name == "command");
    assert(doc1.root.attributes.get("queues")! == "graphics");
    assert(doc1.root.attributes.get("renderpass")! == "inside");
    assert(doc1.root.children[0].name == "registry");
    assert(doc1.root.children[1].name == "registry2");
    assert(doc1.root.children[1].attributes.get("name")! == "test2");
    assert(doc1.root.children[0].value == "TEST");
    assert(doc1.root.children.len() == 2);
    assert(doc1.children.len() == 3);

    assert(doc2.root.children[0].name == "comment");
    assert(doc2.root.children[1].name == "comment");
    assert(doc2.root.attributes.get("name")! == "Decode");

    assert(doc2.root.children[3].children[0].name == "videorequirecapabilities");
    assert(doc2.root.children[3].children[0].attributes.get("struct")! == "VkVideoDecodeCapabilitiesKHR");
    assert(doc2.root.children[5].attributes.get("name")! == "DPB");
    assert(doc2.root.children[5].attributes.get("usage")! == "VK_IMAGE_USAGE_VIDEO_DECODE_DPB_BIT_KHR");
    assert(doc2.children.len() == 8);

    // Search
    NodeList video_formats;
    defer video_formats.free();
    
    doc2.root.find(fn (node) => node.name == "videoformat", &video_formats);

    assert(video_formats.len() == 3);
    assert(video_formats[0].attributes.len() == 2);
}

fn void! xml_file_parsing() {
    xml::Document html = xml::load_file("assets/test.html")!;
    defer html.free();

    assert(html.header == "DOCTYPE html");
}


// fn void! xml_file_parsing2() {

//     xml::Document vk = xml::load_file("assets/vk_test.xml")!;
//     defer vk.free();
// }   