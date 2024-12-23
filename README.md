# xml.c3
XML parser in C3

-----
#### Installing
Add this [file](https://github.com/tonis2/xml.c3/raw/refs/heads/main/xml.c3l) to C3 dependencies folder

And then `xml` to project.json like below

`"dependencies": ["xml"]`


Check tests for examples



----
#### Using in code

XML nodes can be searched like below

```c  
  xml::Node node = xml::load_file("assets/test.xml")!;
  defer node.free();

  NodeList members;
  defer members.free();
  
  NodeList types;
  defer types.free();

  node.find(fn (node) => node.name == "member", &members);
  node.find(fn (node) => node.name == "type" && node.attributes.has_key("category"), &types);
  
  NodeList command_nodes;
  defer command_nodes.free();

  node.find(fn (node) => {|
      if (node.name == "command" && node.children.len() > 0) {
          if (node.attributes.has_key("api") && node.attributes["api"]!! == "vulkansc") {
               return false;
          };
          return true;
      }
      return false;
  |}, &command_nodes);
```

