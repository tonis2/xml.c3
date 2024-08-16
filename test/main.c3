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
                <videocapabilities struct="VkVideoDecodeCapabilitiesKHR"/>
                <videoformat name="Decode Output (Coincide)" usage="VK_IMAGE_USAGE_VIDEO_DECODE_DST_BIT_KHR+VK_IMAGE_USAGE_VIDEO_DECODE_DPB_BIT_KHR">
                    <videorequirecapabilities struct="VkVideoDecodeCapabilitiesKHR" member="flags" value="VK_VIDEO_DECODE_CAPABILITY_DPB_AND_OUTPUT_COINCIDE_BIT_KHR"/>
                </videoformat>
                <videoformat name="Decode Output (Distinct)" usage="VK_IMAGE_USAGE_VIDEO_DECODE_DST_BIT_KHR">
                   
                </videoformat>
                <videoformat name="DPB" usage="VK_IMAGE_USAGE_VIDEO_DECODE_DPB_BIT_KHR"/>
            </videocodec>`;             

fn void! xml_parsing() {
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

    assert(doc2.root.attributes.get("name")! == "Decode");
    assert(doc2.root.children[1].name == "videoformat");
    assert(doc2.root.children[1].children[0].name == "videorequirecapabilities");
    assert(doc2.root.children[1].children[0].attributes.get("struct")! == "VkVideoDecodeCapabilitiesKHR");
    assert(doc2.root.children[3].attributes.get("name")! == "DPB");
    assert(doc2.root.children[3].attributes.get("usage")! == "VK_IMAGE_USAGE_VIDEO_DECODE_DPB_BIT_KHR");
    assert(doc2.children.len() == 6);
}