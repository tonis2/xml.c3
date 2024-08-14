import std::io;
import std::core;
import std::math;
import std::collections::list;
import xml;

const XML1 = `<command queues="graphics" renderpass="inside" cmdbufferlevel="primary,secondary" tasks="state">
                    <registry name="test">TEST</registry>
                    <registry2 name="test2">
                    </registry2>
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

fn void! main() {
    xml::Node root_node_1 = xml::parse_string(XML1)!!;
    xml::Node root_node_2 = xml::parse_string(XML2)!!;

    defer {
        root_node_1.free();
        root_node_2.free();
    };

    assert(root_node_1.name == "command");
    assert(root_node_1.children[0].name == "registry");
    assert(root_node_1.children[1].name == "registry2");
    assert(root_node_1.children[0].value == "TEST");
    assert(root_node_1.children.len() == 2);

}