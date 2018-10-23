
var colorscheme = ["#dc241f","#0087DC","#008142","#70147a","#eeeeee","#dc241f"]
var maxcolour = colorscheme.length

var width = 1000,
    height = 900;


var force = d3.layout.force()
    .charge(-120)
    .linkDistance(30)
    .size([width, height]);

var svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height);

d3.json("graph.json", function(error, graph) {

  var linkNodes = [];

  graph.links.forEach(function(link) {
    linkNodes.push({
      source: graph.nodes[link.source],
      target: graph.nodes[link.target]
    });
  });

  force
      .nodes(graph.nodes.concat(linkNodes))
      .links(graph.links)
      .start();

  var link = svg.selectAll(".link")
      .data(graph.links)
    .enter().append("line")
      .attr("class", "link")
      .style("stroke-width", function(d) { return Math.sqrt(d.value); });

  var node = svg.selectAll(".node")
      .data(graph.nodes)
      .enter().append("g")
      
  node.append("title")
      .text(function(d) { return d.id; });
    
  var circles = node.append("circle")
      .attr("class", "node")
      .attr("r", 5)
      .style("fill", function(d) { return colorscheme[d.group % maxcolour]; })
      .call(force.drag)
      .on("mouseover", mouseOver(.2))
      .on("mouseout", mouseOut);

  var labels = node.append("text")
      .text(function(d) {
        return d.id+1;
      })
      .attr('x', 9)
      .attr('y', 3);



  var linkNode = svg.selectAll(".link-node")
      .data(linkNodes)
    .enter().append("circle")
      .attr("class", "link-node")
      .attr("r", 0)
      .style("fill", "#ccc");

  force.on("tick", function() {
    link.attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

   
    node.attr("transform", function(d) {
        return "translate(" + d.x + "," + d.y + ")";
    })
           
    linkNode.attr("cx", function(d) { return d.x = (d.source.x + d.target.x) * 0.5; })
            .attr("cy", function(d) { return d.y = (d.source.y + d.target.y) * 0.5; });
  });

  // build a dictionary of nodes that are linked
  var linkedByIndex = {};
  graph.links.forEach(function(d) {
      linkedByIndex[d.source.index + "," + d.target.index] = 1;
  });

  // check the dictionary to see if nodes are linked
  function isConnected(a, b) {
    // We're checking if nodes are in the same group(community)
    return a.group == b.group
    //return linkedByIndex[a.index + "," + b.index] || linkedByIndex[b.index + "," + a.index] || a.index == b.index;
  }

  // fade nodes on hover
  function mouseOver(opacity) {
    return function(d) {
        // check all other nodes to see if they're connected
        // to this one. if so, keep the opacity at 1, otherwise
        // fade
        node.style("stroke-opacity", function(o) {
            thisOpacity = isConnected(d, o) ? 1 : opacity;
            return thisOpacity;
        });
        node.style("fill-opacity", function(o) {
            thisOpacity = isConnected(d, o) ? 1 : opacity;
            return thisOpacity;
        });
        // also style link accordingly
        link.style("stroke-opacity", function(o) {
            return o.source === d || o.target === d ? 1 : opacity;
        });
        link.style("stroke", function(o){
            return o.source === d || o.target === d ? o.source.colour : "#ddd";
        });
    };
  }

  function mouseOut() {
    node.style("stroke-opacity", 1);
    node.style("fill-opacity", 1);
    link.style("stroke-opacity", 1);
    link.style("stroke", "#ddd");
  }
});

