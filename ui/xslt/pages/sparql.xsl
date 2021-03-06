<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
	<xsl:include href="../templates.xsl"/>

	<xsl:variable name="display_path"/>

	<xsl:template match="/">
		<html lang="en">
			<head>
				<title>nomisma.org: SPARQL</title>
				<meta name="viewport" content="width=device-width, initial-scale=1"/>
				<script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"/>
				<!-- bootstrap -->
				<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css"/>
				<script type="text/javascript" src="http://netdna.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/codemirror.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/matchbrackets.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/sparql.js"/>
				<script type="text/javascript" src="{$display_path}ui/javascript/sparql_functions.js"/>
				<link rel="stylesheet" href="{$display_path}ui/css/codemirror.css"/>
				<link rel="stylesheet" href="{$display_path}ui/css/style.css"/>
				<!-- google analytics -->
				<xsl:if test="string(//config/google_analytics)">
					<script type="text/javascript">
						<xsl:value-of select="//config/google_analytics"/>
					</script>
				</xsl:if>
			</head>
			<body>
				<xsl:call-template name="header"/>
				<xsl:call-template name="body"/>
				<xsl:call-template name="footer"/>

			</body>
		</html>
	</xsl:template>

	<xsl:template name="body">
		<xsl:variable name="default-query"><![CDATA[PREFIX rdf:	<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX bio:	<http://purl.org/vocab/bio/0.1/>
PREFIX crm:	<http://www.cidoc-crm.org/cidoc-crm/>
PREFIX dcmitype:	<http://purl.org/dc/dcmitype/>
PREFIX dcterms:	<http://purl.org/dc/terms/>
PREFIX foaf:	<http://xmlns.com/foaf/0.1/>
PREFIX geo:	<http://www.w3.org/2003/01/geo/wgs84_pos#>
PREFIX nm:	<http://nomisma.org/id/>
PREFIX nmo:	<http://nomisma.org/ontology#>
PREFIX org:	<http://www.w3.org/ns/org#>
PREFIX osgeo:	<http://data.ordnancesurvey.co.uk/ontology/geometry/>
PREFIX rdac:	<http://www.rdaregistry.info/Elements/c/>
PREFIX skos:	<http://www.w3.org/2004/02/skos/core#>
PREFIX spatial: <http://jena.apache.org/spatial#>
PREFIX void:	<http://rdfs.org/ns/void#>
PREFIX xsd:	<http://www.w3.org/2001/XMLSchema#>

SELECT * WHERE {
  ?s ?p ?o
} LIMIT 100]]></xsl:variable>

		<div class="container-fluid content">
			<div class="row">
				<div class="col-md-12">
					<h1>SPARQL Query</h1>
					<p>For examples, see <a href="{$display_path}documentation/sparql">SPARQL Examples</a>. A basic tutorial on SPARQL is available from <a
							href="http://jena.apache.org/tutorials/sparql.html">Apache Jena</a>.</p>
					<form role="form" id="sparqlForm" action="{$display_path}query" method="GET" accept-charset="UTF-8">
						<textarea name="query" rows="20" class="form-control" id="code">
							<xsl:value-of select="$default-query"/>
						</textarea>
						<br/>
						<div class="col-md-6">
							<div class="form-group">
								<label for="output">Output</label>
								<select name="output" class="form-control">
									<option value="html">HTML</option>
									<option value="xml">XML</option>
									<option value="json">JSON</option>
									<option value="text">Text</option>
									<option value="csv">CSV</option>
								</select>
							</div>
							<button type="submit" class="btn btn-default">Submit</button>
						</div>
						<div class="col-md-6">
							<p class="text-info">This endpoint (<xsl:value-of select="concat(/config/url, 'query')"/>) supports content negotiation for the following content types with SELECT queries: <code>text/html</code>,
									<code>text/csv</code>, <code>text/plain</code>, <code>application/sparql-results+json</code>, and <code>application/sparql-results+xml</code></p>
						
							<p class="text-info">When querying for geo:lat and geo:long properties, a map will be generated, and geographic data may be downloaded as GeoJSON and KML.</p>
						</div>
					</form>
				</div>
			</div>
		</div>
	</xsl:template>

</xsl:stylesheet>
