# xml.c3
XML parser in C3



Check test for examples

XML nodes can be searched like below

```
  NodeList members;
  defer members.free();
  
  NodeList types;
  defer types.free();
  root_node.find(fn (node) => node.name == "member", &members);
  root_node.find(fn (node) => node.name == "type" && node.attributes.has_key("category"), &types);
  
  NodeList command_nodes;
  defer command_nodes.free();

  root_node.find(fn (node) => {|
      if (node.name == "command" && node.children.len() > 0) {
          if (node.attributes.has_key("api") && node.attributes["api"]!! == "vulkansc") {
               return false;
          };
          return true;
      }
      return false;
  |}, &command_nodes);
```

