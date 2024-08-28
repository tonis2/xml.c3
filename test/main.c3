module xml_test @test;

import std::io;
import std::core;
import std::math;
import std::collections::list;
import xml;
    
fn void! xml_file_parsing1() {

    xml::Document test = xml::load_file("assets/test.xml")!;
    defer test.free();
}  
