# EPrintsData2GML

Apache Pig Latin Script to Convert EPrints XML to Graph GML files and geocoded CSV files

eartexte-convert.pig is the main Pig Latin script that converts EPrints XML data from e-artexte (http://e-artexte.ca) 

### About running Pig scriptsn:
  https://pig.apache.org/docs/r0.7.0/setup.html

### Convert data using Pig Generate graph files (GML) and edge files (CSV):
  pig -x local -param datafile="XML/data_humanist_photography.xml" eartexte-convert.pig


## Visualization layout with Gephi 

  Gephi: https://gephi.org/

  File -> Open -> Select GML file

  Statistics -> Run (Network Diameter) -> Select Undirected, Normalize Centralities in [0,1]

  Statistics  -> Run (Modularity)

  Layout – Force Atlas 2 -> scaling (12, depending on size of network)

  Appearance – Nodes -> Size -> Ranking -> Betweenness Centrality (5-20) on a spline

  Appearance – Nodes -> Partition > Modularity Class

  Optional Filters: 

    •	Filters - > Topology > Giant Component

    •	Filters -> Topology -> Degree Range

    •	Filters –> Attributes -> Range -> Betweenness Centrality

    •	Filters -> Edges -> Edge Weight

  Export -> Sigma.js Template -> fill in 

  Sigma Exporter https://marketplace.gephi.org/plugin/sigmajs-exporter/ 

## Visualization using Cytoscape
  
  Cytoscape: http://www.cytoscape.org/

  Import -> Network file > [choose CSV file from the /OUTPUT/EDGELISTS]
