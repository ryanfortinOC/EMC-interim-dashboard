/**
 * Derived from https://bl.ocks.org/mbostock/4339083 
 * Which was released under GPL-3 
 **/
// ************** Generate the tree diagram  *****************
d3.select("#tempID").remove()
var margin = {
        top: 20,
        right: 120,
        bottom: 20,
        left: 120
    },
    width = 1920 - margin.right - margin.left,
    height = 900 - margin.top - margin.bottom;

var i = 0;

var tree = d3.layout.tree()
    .size([height, width]);

var diagonal = d3.svg.diagonal()
    .projection(function(d) {
        return [d.y, d.x];
    });

// point d3.json() at the proper output.json file
d3.json('test4.json', function(error, treeData) {
  var svg = d3.select("#div_tree4").append("svg")
      .attr("id", "svg_tree")
      .attr("width", width + margin.right + margin.left)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    root = treeData[0];
    divText = treeData[1]
    update(root, svg, divText);
});


function update(source, svg, divText) {

  // set ranges for node radius and node text size
  var nodeRadius = d3.scale.sqrt()
      .domain([0, 1])
      .range([5, 60]);

  var nodeText = d3.scale.sqrt()
      .domain([0, 1])
      .range([5, 30]);

  var linkWidth = d3.scale.sqrt()
                          .domain([0, 1])
                          .range([1, 4])

  // set ranges for node colors
  // all nodes with p < 0.25 are red
  // gradient between red and yellow for p \in (0.25, 0.5)
  // gradient between yellow and green for p \in (0.5, 1)
  var nodeColor = function(n) {
      if (n < 0.25) return('#FF0000');
      else if (n < 0.5) {
        return d3.interpolateLab('#FF0000', '#FFC107')(d3.scale.linear()
                                                        .domain([0.3, 0.5])
                                                        .range([0, 1])
                                                        (n));
      } else {
        return d3.interpolateLab('#FFC107', '#2ca02c')(d3.scale.linear()
                                                        .domain([0.5, 1])
                                                        .range([0, 1])
                                                        (n));
      }
  }
  // Compute the new tree layout.
  var nodes = tree.nodes(root).reverse(),
      links = tree.links(nodes);

  // Normalize for fixed-depth.
  nodes.forEach(function(d) {
      d.y = d.depth * 180;
  });
  // Declare the nodes
  var node = svg.selectAll("g.node")
      .data(nodes, function(d) {
          return d.id || (d.id = ++i);
      });

  var div = d3.select("body").append("div")
      .attr("class", "tooltip")

  // Enter the nodes.
  var nodeEnter = node.enter().append("g")
      .attr("class", "node")
      .attr("transform", function(d) {
          return "translate(" + d.y + "," + d.x + ")";
      });

  nodeEnter.append("circle")
      // Set radius and color
      .attr("r", function(d) {
          return nodeRadius(d.wtRelative);
      })
      .style("fill", function(d) {
          return nodeColor(d.yesFloat);
      })
      // Mouseover
      // http://www.d3noob.org/2013/01/adding-tooltips-to-d3js-graph.html
      .on("mouseover", function(d) {
          var matrix = this.getScreenCTM()
              .translate(+this.getAttribute("cx"), +this.getAttribute("cy"));
          div.transition()
              .duration(100)
              .style("opacity", 0.9);
          div.html(function() {
                  function myMap(traits) {
                      var mapped = [];
                      for (var key in traits) {
                          mapped.push("<p class='tooltipsubhead'>" + key + ":</p><br\><ul><li>" + traits[key] + "</li></ul>");
                      }
                      return mapped.join('');
                  };
                  return d.traits ? "<p class='tooltipheader'>" + d.yesNum + divText[0] + d.wtAbsolute + divText[1] + "</p><br\>" + 
                  myMap(d.traits) : "<p class='tooltipsolo'>" + d.yesNum + divText[2] + d.wtAbsolute + divText[3] + "</p>";
              })
              .style("left", (window.pageXOffset + matrix.e + nodeRadius(d.wtRelative)) - 10 + "px")
              .style("top", (window.pageYOffset + matrix.f) + "px")
      })
      .on("mouseout", function(d) {
          div.transition()
            .duration(200)
            .style("opacity", 0);
      });

  // Node labels
  nodeEnter.append("text")
    .attr("class", "splitLab")
    // not sure why this doesn't obey style.css
    .style("font-weight", "bold")
    .attr("dx", function(d) {
        return 10 + nodeRadius(d.wtRelative);
    })
    .text(function(d) {
        if (d.name) {
            // return "Split on " + d.name
            return d.name;
        } else return;
    })
  // Percentages
  nodeEnter.append("text")
    .attr("class", "nodePct")
    .attr("dy", function(d) {
        return nodeRadius(d.wtRelative) / 5 + "px";
    })
    .text(function(d) {
        return d.yesPct;
    })
    .style("font-size", function(d) {
        return nodeText(d.wtRelative) + "px";
    })
    .on("mouseover", function(d) {
      var matrix = this.getScreenCTM()
          .translate(+this.getAttribute("cx"), +this.getAttribute("cy"));
      div.transition()
          .duration(100)
          .style("opacity", 0.9);
      div.html(function() {
              function myMap(traits) {
                  var mapped = [];
                  for (var key in traits) {
                      mapped.push("<p class='tooltipsubhead'>" + key + ":</p><br\><ul><li>" + traits[key] + "</li></ul>");
                  }
                  return mapped.join('');
              };
              return d.traits ? "<p class='tooltipheader'>" + d.yesNum + divText[0] + d.wtAbsolute + divText[1] + "</p><br\>" + 
              myMap(d.traits) : "<p class='tooltipsolo'>" + d.yesNum + divText[2] + d.wtAbsolute + divText[3] + "</p>";
          })
          .style("left", (window.pageXOffset + matrix.e + nodeRadius(d.wtRelative)) - 10 + "px")
          .style("top", (window.pageYOffset + matrix.f) + "px")
      })
      .on("mouseout", function(d) {
        div.transition()
          .duration(200)
          .style("opacity", 0);
      });



  // Declare the links!
  var link = svg.selectAll("path.link")
      .data(links, function(d) {
        return d.target.id;
      })

  // Enter the links.
  var linkEnter = link.enter().insert("path", "g")
    .attr("class", "link")
    .attr("d", diagonal)
    .style("stroke-width", function(d) {
        return linkWidth(d.target.wtRelative);
    })
}
