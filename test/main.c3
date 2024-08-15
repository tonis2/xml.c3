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

fn void! main() {
    xml::Document doc1 = xml::parse_string(XML1)!!;
    // xml::Document doc2 = xml::parse_string(XML2)!!;

    assert(doc1.root.name == "command");
    assert(doc1.root.children[0].name == "registry");
    assert(doc1.root.children[1].name == "registry2");
    assert(doc1.root.children[0].value == "TEST");
    assert(doc1.root.children.len() == 2);

    defer {
        doc1.free();
        // doc2.free();
    };

    // foreach (child: doc1.children) {
    //     io::printfn("node name %s %s %d", child.name, child.value, child.closed);
    // }

}