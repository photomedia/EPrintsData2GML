--Pig script written by Tomasz Neugebauer (tomasz.neugebauer@concordia.ca)
--2017
--MIT license

DEFINE XPath org.apache.pig.piggybank.evaluation.xml.XPath();
DEFINE XPathAll org.apache.pig.piggybank.evaluation.xml.XPathAll();

--REGISTER datafu-pig-incubating-1.3.1.jar;
--define Transpose datafu.pig.util.Transpose();
--define TransposeTupleToBag datafu.pig.util.TransposeTupleToBag();

register 'convert-data.py' using jython as UDFToBagConverter ;
-- also uses gml-header-footer.py to output GML results

--======================================================================================
--usage: specify datafile from command line
--for example:
--pig -x local -param datafile="XML/data_humanist_photography.xml" eartexte-convert.pig
--======================================================================================
--%declare datafile 'XML/data_humanist_photography.xml';
--datafile = '../artexte-test.xml';
--datafile = '../automobile.xml'
--datafile = '../artexte-test-23355.xml'
--datafile = '../e-artexte-all.xml'
--datafile = '../artexte-test-two-records.xml';
--datafile = '../artexte-eprint-3479.xml';
--datafile = '../e-artexte-all-photography-or2017.xml';
--datafile = '../data_humanist_photography.xml'


A = load '$datafile' using org.apache.pig.piggybank.storage.XMLLoader('eprint') as (x:chararray);


--=========================================================================================================
--*********************************************************************************************************
--=========================================================================================================
--========================contributors==============
B2 = FOREACH A GENERATE XPath(x, 'eprint/eprintid') as (eprintid:chararray),
XPath(x, 'eprint/title') as (title:chararray),
XPathAll(x, 'eprint/contributors/item/name') as (nodeb:tuple()),
CONCAT ('|', XPath(x, 'eprint/title')) as (separatorPLUStitle:chararray);
data2 = FOREACH B2 GENERATE *,CONCAT (eprintid, separatorPLUStitle) as (nodea:chararray);
C2 = FOREACH data2 GENERATE nodea, UDFToBagConverter.convert(nodeb);
D2 = FOREACH C2 GENERATE nodea, FLATTEN($1);
E2 = FILTER D2 BY TRIM($1) != '';
I2 = FOREACH E2 GENERATE $0,'contributor', REPLACE(TRIM($1), '^, ', '');
I2_1 = FOREACH I2 GENERATE $0,$1, REPLACE(TRIM($2), ',           , ',', ');
I2 = FOREACH I2_1 GENERATE $0,$1, REPLACE(TRIM($2), ',$','');
I2 = FILTER I2 BY TRIM($2) != '';
--==========co-contributors========
inpt = foreach I2 generate CONCAT(SUBSTRING($0, 0, 35),'...') as (id:chararray), REPLACE(REPLACE(REPLACE($2,'\\]','_'),'\\[','_'),'"','_') as (val);
contributors = foreach inpt generate $0,'contributor',$1;
grp = group inpt by (id);
id_grp = foreach grp generate group as id, inpt.val as value_bag;
co_contributor = foreach id_grp generate FLATTEN(value_bag) as v1, id, FLATTEN(value_bag) as v2;
co_contributor = filter co_contributor by v1 <= v2;
co_contributor = filter co_contributor by v1 != v2;
--==========co-contributors - edge file output - GML ========
--==== node list=====
node_idA = foreach inpt generate TRIM($1);
node_idA = filter node_idA by $0 != '';
node_idA = DISTINCT node_idA;
nodelist = foreach node_idA generate 'node','[', 'id', $0,'label',$0,']';
nodelist_co = nodelist;
--==== edge list====
edge = foreach co_contributor generate TRIM($0),$1,TRIM($2);
edge = filter edge by $0 != '';
edge = filter edge by $2 != '';
edgelist_withedgelabels = foreach co_contributor generate 'edge','[', 'source',$0, 'target',$2,'label',REPLACE(REPLACE(REPLACE(id,'\\]','_'),'\\[','_'),'"','_'), ']';
edgelist_co_contributors = foreach edgelist_withedgelabels generate $3,$5;

gml_withedgelabels = union nodelist, edgelist_withedgelabels;
gml_withedgelabels = ORDER gml_withedgelabels BY $0 DESC;

rmf TMP/co_contributor-gml-with_edge_labels
STORE gml_withedgelabels INTO 'TMP/co_contributor-gml-with_edge_labels' USING org.apache.pig.piggybank.storage.CSVExcelStorage(' ', 'NO_MULTILINE', 'WINDOWS');
rmf TMP/merged-file-co_contributor-gml-with_edge_labels.gml
fs -getmerge  TMP/co_contributor-gml-with_edge_labels TMP/merged-file-co_contributor-gml-with_edge_labels.gml
sh python gml-header-footer.py -i TMP/merged-file-co_contributor-gml-with_edge_labels.gml -o OUTPUT/merged-file-co_contributor-gml-with_edge_labels-withheader.gml

rmf TMP/edgelist_co-contributors
STORE edgelist_co_contributors INTO 'TMP/edgelist_co-contributors' USING org.apache.pig.piggybank.storage.CSVExcelStorage('\t', 'NO_MULTILINE', 'WINDOWS');
rmf OUTPUT/EDGELISTS/merged-file-edgelist_co-contributors.csv
fs -getmerge  TMP/edgelist_co-contributors OUTPUT/EDGELISTS/merged-file-edgelist_co-contributors.csv

--=========================================================================================================
--*********************************************************************************************************
--=========================================================================================================
--========================artists=================

B = FOREACH A GENERATE XPath(x, 'eprint/eprintid') as (eprintid:chararray),
XPath(x, 'eprint/title') as (title:chararray),
XPathAll(x, 'eprint/artists/item') as (nodeb:tuple()),
CONCAT ('|', XPath(x, 'eprint/title')) as (separatorPLUStitle:chararray);
data = FOREACH B GENERATE *,CONCAT (eprintid, separatorPLUStitle) as (nodea:chararray);
C = FOREACH data GENERATE nodea, UDFToBagConverter.convert(nodeb);
D = FOREACH C GENERATE nodea, FLATTEN($1);
E = FILTER D BY TRIM($1) != '';
I = FOREACH E GENERATE $0,'artist',$1;
I = FILTER I BY TRIM($2) != '';

--==========co-artist==============================
inpt = foreach E generate CONCAT(SUBSTRING($0, 0, 35),'...') as (id:chararray), REPLACE(REPLACE(REPLACE($1,'\\]','_'),'\\[','_'),'"','_') as (val);
artists = foreach inpt generate $0,'artist',$1;;
grp = group inpt by (id);
id_grp = foreach grp generate group as id, inpt.val as value_bag;
co_artist = foreach id_grp generate FLATTEN(value_bag) as v1, id, FLATTEN(value_bag) as v2;
co_artist = filter co_artist by v1 <= v2;
co_artist = filter co_artist by v1 != v2;

--==========co-artist - edge file output - GML ========
--==== node list=====
node_idA = foreach inpt generate TRIM($1);
node_idA = filter node_idA by $0 != '';
node_idA = DISTINCT node_idA;
nodelist = foreach node_idA generate 'node','[', 'id', $0,'label',$0,']';
nodelist_a = nodelist;
--==== edge list====
edge = foreach co_artist generate TRIM($0),$1,TRIM($2);
edge = filter edge by $0 != '';
edge = filter edge by $2 != '';
edgelist_withedgelabels = foreach co_artist generate 'edge','[', 'source',$0, 'target',$2,'label',REPLACE(REPLACE(REPLACE(id,'\\]','_'),'\\[','_'),'"','_'), ']';
edgelist_co_artists = foreach edgelist_withedgelabels generate $3,$5;

gml_withedgelabels = union nodelist, edgelist_withedgelabels;
gml_withedgelabels = ORDER gml_withedgelabels BY $0 DESC;

rmf TMP/co-artists-gml-with_edge_labels
STORE gml_withedgelabels INTO 'TMP/co-artists-gml-with_edge_labels' USING org.apache.pig.piggybank.storage.CSVExcelStorage(' ', 'NO_MULTILINE', 'WINDOWS');
rmf TMP/merged-file-co-artists-gml-with_edge_labels.gml
fs -getmerge  TMP/co-artists-gml-with_edge_labels TMP/merged-file-co-artists-gml-with_edge_labels.gml
sh python gml-header-footer.py -i TMP/merged-file-co-artists-gml-with_edge_labels.gml -o OUTPUT/merged-file-co-artists-gml-with_edge_labels-withheader.gml

rmf TMP/edgelist_co-artists
STORE edgelist_co_artists INTO 'TMP/edgelist_co-artists' USING org.apache.pig.piggybank.storage.CSVExcelStorage('\t', 'NO_MULTILINE', 'WINDOWS');
rmf OUTPUT/EDGELISTS/merged-file-edgelist_co-artists.csv
fs -getmerge  TMP/edgelist_co-artists OUTPUT/EDGELISTS/merged-file-edgelist_co-artists.csv

--=========================================================================================================
--*********************************************************************************************************
--=========================================================================================================
--========================critics=================
B1 = FOREACH A GENERATE XPath(x, 'eprint/eprintid') as (eprintid:chararray),
					   XPath(x, 'eprint/title') as (title:chararray),
					   XPathAll(x, 'eprint/critics/item') as (nodeb:tuple()),
					   CONCAT ('|', XPath(x, 'eprint/title')) as (separatorPLUStitle:chararray);
data1 = FOREACH B1 GENERATE *,CONCAT (eprintid, separatorPLUStitle) as (nodea:chararray);
C1 = FOREACH data1 GENERATE nodea, UDFToBagConverter.convert(nodeb);
D1 = FOREACH C1 GENERATE nodea, FLATTEN($1);
E1 = FILTER D1 BY TRIM($1) != '';
I1 = FOREACH E1 GENERATE $0,'critic',$1;
I1 = FILTER I1 BY TRIM($2) != '';


--==========co-critic========
inpt = foreach E1 generate CONCAT(SUBSTRING($0, 0, 35),'...') as (id:chararray), REPLACE(REPLACE(REPLACE($1,'\\]','_'),'\\[','_'),'"','_') as (val);
critics = foreach inpt generate $0,'critic',$1;;
grp = group inpt by (id);
id_grp = foreach grp generate group as id, inpt.val as value_bag;
co_critic = foreach id_grp generate FLATTEN(value_bag) as v1, id, FLATTEN(value_bag) as v2;
co_critic = filter co_critic by v1 <= v2;
co_critic = filter co_critic by v1 != v2;

--==========co-critic - edge file output - GML ========
--==== node list=====
node_idA = foreach inpt generate TRIM($1);
node_idA = filter node_idA by $0 != '';
node_idA = DISTINCT node_idA;
nodelist = foreach node_idA generate 'node','[', 'id', $0,'label',$0,']';
nodelist_cr = nodelist;
--==== edge list====
edge = foreach co_critic generate TRIM($0),$1,TRIM($2);
edge = filter edge by $0 != '';
edge = filter edge by $2 != '';
edgelist_withedgelabels = foreach co_critic generate 'edge','[', 'source',$0, 'target',$2,'label',REPLACE(REPLACE(REPLACE(id,'\\]','_'),'\\[','_'),'"','_'), ']';
edgelist_co_critics = foreach edgelist_withedgelabels generate $3,$5;

gml_withedgelabels = union nodelist, edgelist_withedgelabels;
gml_withedgelabels = ORDER gml_withedgelabels BY $0 DESC;

rmf TMP/co-critics-gml-with_edge_labels
STORE gml_withedgelabels INTO 'TMP/co-critics-gml-with_edge_labels' USING org.apache.pig.piggybank.storage.CSVExcelStorage(' ', 'NO_MULTILINE', 'WINDOWS');
rmf TMP/merged-file-co-critics-gml-with_edge_labels.gml
fs -getmerge  TMP/co-critics-gml-with_edge_labels TMP/merged-file-co-critics-gml-with_edge_labels.gml
sh python gml-header-footer.py -i TMP/merged-file-co-critics-gml-with_edge_labels.gml -o OUTPUT/merged-file-co-critics-gml-with_edge_labels-withheader.gml


rmf TMP/edgelist_co-critics
STORE edgelist_co_critics INTO 'TMP/edgelist_co-critics' USING org.apache.pig.piggybank.storage.CSVExcelStorage('\t', 'NO_MULTILINE', 'WINDOWS');
rmf OUTPUT/EDGELISTS/merged-file-edgelist_co-critics.csv
fs -getmerge  TMP/edgelist_co-critics OUTPUT/EDGELISTS/merged-file-edgelist_co-critics.csv

--=========================================================================================================
--*********************************************************************************************************
--=========================================================================================================
--========================keywords=================
B4 = FOREACH A GENERATE XPath(x, 'eprint/eprintid') as (eprintid:chararray),
					   XPath(x, 'eprint/title') as (title:chararray),
					   XPathAll(x, 'eprint/kw/item') as (nodeb:tuple()),
					   CONCAT ('|', XPath(x, 'eprint/title')) as (separatorPLUStitle:chararray);
data4 = FOREACH B4 GENERATE *,CONCAT (eprintid, separatorPLUStitle) as (nodea:chararray);

C4 = FOREACH data4 GENERATE nodea, UDFToBagConverter.convert(nodeb);
D4 = FOREACH C4 GENERATE nodea, FLATTEN($1);
E4 = FILTER D4 BY TRIM($1) != '';
I4 = FOREACH E4 GENERATE $0,'keyword',$1;
I4 = FILTER I4 BY TRIM($2) != '';

--=======================================
--==========co-keyword===================
inpt = foreach E4 generate CONCAT(SUBSTRING($0, 0, 35),'...') as (id:chararray), REPLACE(REPLACE(REPLACE($1,'\\]','_'),'\\[','_'),'"','_') as (val);
keywords = foreach inpt generate $0,'keyword',$1;;
grp = group inpt by (id);
id_grp = foreach grp generate group as id, inpt.val as value_bag;
co_keyword = foreach id_grp generate FLATTEN(value_bag) as v1, id, FLATTEN(value_bag) as v2; 
co_keyword = filter co_keyword by v1 <= v2;
co_keyword = filter co_keyword by v1 != v2;

--==========co-keyword - edge file output - GML ========
--==== node list=====
node_idA = foreach inpt generate TRIM($1);
node_idA = filter node_idA by $0 != '';
node_idA = DISTINCT node_idA;
nodelist = foreach node_idA generate 'node','[', 'id', $0,'label',$0,']';
nodelist_k = nodelist;
--==== edge list====
edge = foreach co_keyword generate TRIM($0),$1,TRIM($2);
edge = filter edge by $0 != '';
edge = filter edge by $2 != '';
edgelist_withedgelabels = foreach co_keyword generate 'edge','[', 'source',$0, 'target',$2,'label',REPLACE(REPLACE(REPLACE(id,'\\]','_'),'\\[','_'),'"','_'), ']';
edgelist_co_keywords = foreach edgelist_withedgelabels generate $3,$5;

gml_withedgelabels = union nodelist, edgelist_withedgelabels;
gml_withedgelabels = ORDER gml_withedgelabels BY $0 DESC;

rmf TMP/co-keyword-gml-with_edge_labels
STORE gml_withedgelabels INTO 'TMP/co-keyword-gml-with_edge_labels' USING org.apache.pig.piggybank.storage.CSVExcelStorage(' ', 'NO_MULTILINE', 'WINDOWS');
rmf TMP/merged-file-co-keyword-gml-with_edge_labels.gml
fs -getmerge  TMP/co-keyword-gml-with_edge_labels TMP/merged-file-co-keyword-gml-with_edge_labels.gml
sh python gml-header-footer.py -i TMP/merged-file-co-keyword-gml-with_edge_labels.gml -o OUTPUT/merged-file-co-keyword-gml-with_edge_labels-withheader.gml



rmf TMP/edgelist_co-keywords
STORE edgelist_co_keywords INTO 'TMP/edgelist_co-keywords' USING org.apache.pig.piggybank.storage.CSVExcelStorage('\t', 'NO_MULTILINE', 'WINDOWS');
rmf OUTPUT/EDGELISTS/merged-file-edgelist_co-keywords.csv
fs -getmerge  TMP/edgelist_co-keywords OUTPUT/EDGELISTS/merged-file-edgelist_co-keywords.csv

--==============cross keywords and artists=================
--==============dependent on E and E4======================

inptARTIST = foreach E generate CONCAT(SUBSTRING($0, 0, 35),'...') as (id:chararray), REPLACE(REPLACE(REPLACE($1,'\\]','_'),'\\[','_'),'"','_') as (val);
inputKEYWORD = foreach E4 generate CONCAT(SUBSTRING($0, 0, 35),'...') as (id:chararray), REPLACE(REPLACE(REPLACE($1,'\\]','_'),'\\[','_'),'"','_') as (val);
inpt = union inptARTIST,inputKEYWORD;
grp = group inpt by (id);
id_grp = foreach grp generate group as id, inpt.val as value_bag;
co_cross_keyword_artist = foreach id_grp generate FLATTEN(value_bag) as v1, id, FLATTEN(value_bag) as v2; 
co_cross_keyword_artist = filter co_cross_keyword_artist by v1 <= v2;
co_cross_keyword_artist = filter co_cross_keyword_artist by v1 != v2;

--==========co-cross-keyword-artist - edge file output - GML ========
--==== node list=====
node_idA = foreach inpt generate TRIM($1);
node_idA = filter node_idA by $0 != '';
node_idA = DISTINCT node_idA;
nodelist = foreach node_idA generate 'node','[', 'id', $0,'label',$0,']';
--==== edge list====
edge = foreach co_cross_keyword_artist generate TRIM($0),$1,TRIM($2);
edge = filter edge by $0 != '';
edge = filter edge by $2 != '';
edgelist_withedgelabels = foreach co_cross_keyword_artist generate 'edge','[', 'source',$0, 'target',$2,'label',REPLACE(REPLACE(REPLACE(id,'\\]','_'),'\\[','_'),'"','_'), ']';
edgelist_co_cross_keyword_artists = foreach edgelist_withedgelabels generate $3,$5;

gml_withedgelabels = union nodelist, edgelist_withedgelabels;
gml_withedgelabels = ORDER gml_withedgelabels BY $0 DESC;

rmf TMP/co-cross-keyword-artist-gml-with_edge_labels
STORE gml_withedgelabels INTO 'TMP/co-cross-keyword-artist-gml-with_edge_labels' USING org.apache.pig.piggybank.storage.CSVExcelStorage(' ', 'NO_MULTILINE', 'WINDOWS');
rmf TMP/merged-file-co-cross-keyword-artist-gml-with_edge_labels.gml
fs -getmerge  TMP/co-cross-keyword-artist-gml-with_edge_labels TMP/merged-file-co-cross-keyword-artist-gml-with_edge_labels.gml
sh python gml-header-footer.py -i TMP/merged-file-co-cross-keyword-artist-gml-with_edge_labels.gml -o OUTPUT/merged-file-co-cross-keyword-artist-gml-with_edge_labels-withheader.gml


rmf TMP/edgelist_co-cross-keyword-artists
STORE edgelist_co_cross_keyword_artists INTO 'TMP/edgelist_co-cross-keyword-artists' USING org.apache.pig.piggybank.storage.CSVExcelStorage('\t', 'NO_MULTILINE', 'WINDOWS');
rmf OUTPUT/EDGELISTS/merged-file-edgelist_co-cross-keyword-artists.csv
fs -getmerge  TMP/edgelist_co-cross-keyword-artists OUTPUT/EDGELISTS/merged-file-edgelist_co-cross-keyword-artists.csv

--=========================================================================================================
--*********************************************************************************************************
--=========================================================================================================
--========================publishers==============
B3 = FOREACH A GENERATE XPath(x, 'eprint/eprintid') as (eprintid:chararray),
					   XPath(x, 'eprint/title') as (title:chararray),
					   XPathAll(x, 'eprint/publishers/item/name') as (nodeb:tuple()),
					   CONCAT ('|', XPath(x, 'eprint/title')) as (separatorPLUStitle:chararray);
data3 = FOREACH B3 GENERATE *,CONCAT (eprintid, separatorPLUStitle) as (nodea:chararray);

C3 = FOREACH data3 GENERATE nodea, UDFToBagConverter.convert(nodeb);
D3 = FOREACH C3 GENERATE nodea, FLATTEN($1);
E3 = FILTER D3 BY TRIM($1) != '';
I3 = FOREACH E3 GENERATE $0,'publisher',$1;
I3 = FILTER I3 BY TRIM($2) != '';


--=======================================
--==========co-publisher===================
inpt = foreach E3 generate CONCAT(SUBSTRING($0, 0, 35),'...') as (id:chararray), REPLACE(REPLACE(REPLACE($1,'\\]','_'),'\\[','_'),'"','_') as (val);
publishers = foreach inpt generate $0,'publisher',$1;
grp = group inpt by (id);
id_grp = foreach grp generate group as id, inpt.val as value_bag;
co_publisher = foreach id_grp generate FLATTEN(value_bag) as v1, id, FLATTEN(value_bag) as v2;
co_publisher = filter co_publisher by v1 <= v2;
co_publisher = filter co_publisher by v1 != v2;

--==========co-publisher - edge file output - GML ========
--==== node list=====
node_idA = foreach inpt generate TRIM($1);
node_idA = filter node_idA by $0 != '';
node_idA = DISTINCT node_idA;
nodelist = foreach node_idA generate 'node','[', 'id', $0,'label',$0,']';
nodelist_p = nodelist;
--==== edge list====
edge = foreach co_publisher generate TRIM($0),$1,TRIM($2);
edge = filter edge by $0 != '';
edge = filter edge by $2 != '';
edgelist_withedgelabels = foreach co_publisher generate 'edge','[', 'source',$0, 'target',$2,'label',REPLACE(REPLACE(REPLACE(id,'\\]','_'),'\\[','_'),'"','_'), ']';

gml_withedgelabels = union nodelist, edgelist_withedgelabels;
gml_withedgelabels = ORDER gml_withedgelabels BY $0 DESC;

rmf TMP/co-publisher-gml-with_edge_labels
STORE gml_withedgelabels INTO 'TMP/co-publisher-gml-with_edge_labels' USING org.apache.pig.piggybank.storage.CSVExcelStorage(' ', 'NO_MULTILINE', 'WINDOWS');
rmf TMP/merged-file-co-publisher-gml-with_edge_labels.gml
fs -getmerge  TMP/co-publisher-gml-with_edge_labels TMP/merged-file-co-publisher-gml-with_edge_labels.gml
sh python gml-header-footer.py -i TMP/merged-file-co-publisher-gml-with_edge_labels.gml -o OUTPUT/merged-file-co-publisher-gml-with_edge_labels-withheader.gml

--=========================================================================================================
--*********************************************************************************************************
--=========================================================================================================
--================================================--
--=====OUTPUT 2-MODE NETWORK of ALL =================
--====================================================

--=============Edges======================
--OUTPUT_RESULT_EDGES = union I, I1, I2, I3, I4;
OUTPUT_RESULT_EDGES = union artists, contributors, publishers, critics, keywords;
OUTPUT_RESULT_EDGES_withedgelabels = foreach OUTPUT_RESULT_EDGES generate 'edge','[', 'source',REPLACE(REPLACE(REPLACE($0,'\\]','_'),'\\[','_'),'"','_'), 'target',$2,'label',$1, ']';
OUTPUT_RESULT_EDGELIST = foreach OUTPUT_RESULT_EDGES generate $0, $2;
--=========nodelist is a union of all node lists, plus the node list for the items/labels on the edges==============--
nodelist_items = FOREACH OUTPUT_RESULT_EDGES generate REPLACE(REPLACE(REPLACE($0,'\\]','_'),'\\[','_'),'"','_');
nodelist_items = DISTINCT nodelist_items;
nodelist_items = FOREACH nodelist_items generate 'node','[', 'id', $0,'label',$0,']';
TOTAL_NODELIST = union nodelist_items, nodelist_k, nodelist_p, nodelist_a, nodelist_cr, nodelist_co;
TOTAL_NODELIST = DISTINCT TOTAL_NODELIST;
--==========GML is union of nodes and edges ==================
OUTPUT_RESULT = union TOTAL_NODELIST, OUTPUT_RESULT_EDGES_withedgelabels;
OUTPUT_RESULT = ORDER OUTPUT_RESULT BY $0 DESC;


rmf TMP/multi-mode-publishers-artists-critics-contributors-keywords
STORE OUTPUT_RESULT INTO 'TMP/multi-mode-publishers-artists-critics-contributors-keywords' USING org.apache.pig.piggybank.storage.CSVExcelStorage(' ', 'NO_MULTILINE', 'WINDOWS');
rmf TMP/multi-mode-publishers-artists-critics-contributors-keywords-merged-file.gml
fs -getmerge  TMP/multi-mode-publishers-artists-critics-contributors-keywords TMP/multi-mode-publishers-artists-critics-contributors-keywords-merged-file.gml
sh python gml-header-footer.py -i TMP/multi-mode-publishers-artists-critics-contributors-keywords-merged-file.gml -o OUTPUT/multi-mode-publishers-artists-critics-contributors-keywords-merged-file-withheader.gml


rmf TMP/edgelist-multi-mode-publishers-artists-critics-contributors-keywords
STORE OUTPUT_RESULT_EDGELIST INTO 'TMP/edgelist-multi-mode-publishers-artists-critics-contributors-keywords' USING org.apache.pig.piggybank.storage.CSVExcelStorage('\t', 'NO_MULTILINE', 'WINDOWS');
rmf OUTPUT/EDGELISTS/merged-file-edgelist-multi-mode-publishers-artists-critics-contributors-keywords.csv
fs -getmerge  TMP/edgelist-multi-mode-publishers-artists-critics-contributors-keywords OUTPUT/EDGELISTS/merged-file-edgelist-multi-mode-publishers-artists-critics-contributors-keywords.csv

--=========================================================================================================
--*********************************************************************************************************
--=========================================================================================================
--========================place of publication=================



B = FOREACH A GENERATE XPath(x, 'eprint/eprintid') as (eprintid:chararray),
XPath(x, 'eprint/title') as (title:chararray),
XPathAll(x, 'eprint/publishers/item/place') as (nodeb:tuple()),
CONCAT ('|', XPath(x, 'eprint/title')) as (separatorPLUStitle:chararray);
data = FOREACH B GENERATE eprintid,title,UDFToBagConverter.convert(nodeb) as (nodeb),separatorPLUStitle,CONCAT (eprintid, separatorPLUStitle) as (nodea:chararray);
D = FOREACH data GENERATE nodea, FLATTEN(nodeb) as (nodeb),eprintid,title;
E = FILTER D BY nodeb != '';
I = FOREACH E GENERATE nodea,nodeb,eprintid,title;

inpt = foreach I generate *,CONCAT(SUBSTRING(nodea, 0, 35),'...') as (id:chararray), nodeb as (publisher_loc);
--publisher_place = foreach inpt generate id,publisher_loc,CONCAT('http://e-artexte.ca/',eprintid),title;
publisher_place = foreach inpt generate publisher_loc,CONCAT('http://e-artexte.ca/',eprintid) as (url);
 
rmf TMP/publisher_place
STORE publisher_place INTO 'TMP/publisher_place' USING org.apache.pig.piggybank.storage.CSVExcelStorage(' ', 'NO_MULTILINE', 'WINDOWS');
rmf TMP/publisher_place-merged-file.csv
fs -getmerge  TMP/publisher_place OUTPUT/publisher_place-merged-file.csv


--generate location - count list 
urlcount = group publisher_place by (publisher_loc);
urlcount = FOREACH urlcount GENERATE *,
  group as url,  
  COUNT(publisher_place);
  
urlcount = foreach urlcount generate $0 as publisher_loc,$3 as count,$1 as urls;
  
rmf TMP/urlcount
STORE urlcount INTO 'TMP/urlcount' USING org.apache.pig.piggybank.storage.CSVExcelStorage(' ', 'NO_MULTILINE', 'WINDOWS');
rmf TMP/urlcount-merged-file.csv
fs -getmerge  TMP/urlcount OUTPUT/urlcount-merged-file.csv

--------------------------
--to do: run the geocode.py to generate geocoded-locations.csv
--sh python geocode.py
--... should skip this step if it is up to date and complete --
--if you run this step separately from this script, you have to re-run the pig script so that it uses 
--the most up-to-date locations file
-- uses Google Maps API and other geo-coding services
--------------------------

--join publisher_place with geocoded locations.csv
DEFINE CSVExcelStorage org.apache.pig.piggybank.storage.CSVExcelStorage();
geo_locations = load 'OUTPUT/geocoded-locations.csv' USING CSVExcelStorage(',') as (location:chararray,count:int,urls,latitude:float,longitude:float);
geo = foreach geo_locations generate location,latitude,longitude;

items_with_locations = join publisher_place by publisher_loc LEFT OUTER, geo by location;
items_with_locations = foreach items_with_locations generate *;

rmf TMP/items_with_locations
STORE items_with_locations INTO 'TMP/items_with_locations' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'NO_MULTILINE', 'WINDOWS');
rmf TMP/items_with_locations-merged-file.csv
fs -getmerge  TMP/items_with_locations OUTPUT/items_with_locations-merged-file.csv

--join url_count with geocoded locations.csv
urlcount_locations = join urlcount by publisher_loc LEFT OUTER, geo by location;
urlcount_with_locations = foreach urlcount_locations generate *;
urlcount_with_locations = foreach urlcount_with_locations generate 
	urlcount::publisher_loc as publisher_loc, 
	urlcount::count as count,
	geo::latitude as latitude,
	geo::longitude as longitude,
	urlcount::urls.url as urls;
	

urlcount_with_locations = group urlcount_with_locations by (latitude,longitude);
urlcount_with_locations = foreach urlcount_with_locations generate 
	group.latitude as latitude,
	group.longitude as longitude,
	urlcount_with_locations.publisher_loc as publisher_loc, 
	SUM(urlcount_with_locations.count) as count,
	urlcount_with_locations.urls as urls;


rmf TMP/urlcount_with_locations
STORE urlcount_with_locations INTO 'TMP/urlcount_with_locations' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'NO_MULTILINE', 'WINDOWS');
rmf TMP/urlcount_with_locations-merged-file.csv
fs -getmerge  TMP/urlcount_with_locations OUTPUT/urlcount_with_locations-merged-file.csv
	 
sh python geocode-generate-fusion-table.py

--======END OF FILE=======
