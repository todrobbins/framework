<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>

	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>
	
	<!-- read request header for content-type -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output indent="yes"/>
				
				<xsl:variable name="content-type" select="//header[name[.='accept']]/value"/>
				
				<xsl:template match="/">
					<content-type>
						<xsl:choose>
							<xsl:when test="$content-type='application/json'">json-ld</xsl:when>
							<xsl:when test="$content-type='application/vnd.google-earth.kml+xml'">kml</xsl:when>
							<xsl:when test="$content-type='application/rdf+xml' or $content-type='application/xml' or $content-type='text/xml'">xml</xsl:when>
							<xsl:when test="$content-type='text/turtle'">turtle</xsl:when>
							<xsl:when test="contains($content-type, 'text/html') or $content-type='*/*' or not(string($content-type))">html</xsl:when>
							<xsl:otherwise>error</xsl:otherwise>
						</xsl:choose>
					</content-type>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="conneg-config"/>
	</p:processor>
	
	<p:choose href="#conneg-config">
		<p:when test="content-type='xml'">
			<p:processor name="oxf:pipeline">
				<p:input name="config" href="../models/get-id.xpl"/>		
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<p:when test="content-type='json-ld'">
			<p:processor name="oxf:pipeline">
				<p:input name="config" href="../serializations/rdf/json-ld.xpl"/>	
				<p:input name="data" href="#data"/>				
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<p:when test="content-type='turtle'">
			<p:processor name="oxf:pipeline">
				<p:input name="config" href="../serializations/rdf/ttl.xpl"/>
				<p:input name="data" href="#data"/>				
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<p:when test="content-type='kml'">
			<p:processor name="oxf:pipeline">
				<p:input name="config" href="../serializations/rdf/kml.xpl"/>
				<p:input name="data" href="#data"/>		
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<p:when test="content-type='html'">
			<!-- read the data. if the RDF contains the dcterms:isReplacedBy property, then create an HTTP 303 redirect -->
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="data" href="#data"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
						<xsl:template match="/">
							<redirect>
								<xsl:choose>
									<xsl:when test="descendant::dcterms:isReplacedBy/@rdf:resource">true</xsl:when>
									<xsl:otherwise>false</xsl:otherwise>
								</xsl:choose>
							</redirect>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:output name="data" id="redirect-config"/>
			</p:processor>
			
			<p:choose href="#redirect-config">
				<p:when test="redirect='true'">
					<p:processor name="oxf:pipeline">
						<p:input name="data" href="#data"/>
						<p:input name="config" href="303-redirect.xpl"/>		
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:when>
				<p:otherwise>
					<p:processor name="oxf:pipeline">
						<p:input name="config" href="../serializations/rdf/html.xpl"/>
						<p:input name="data" href="#data"/>		
						<p:output name="data" ref="data"/>
					</p:processor>
				</p:otherwise>
			</p:choose>
		</p:when>
		<p:otherwise>
			<p:processor name="oxf:pipeline">
				<p:input name="data" href="#data"/>
				<p:input name="config" href="406-not-acceptable.xpl"/>		
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:otherwise>
	</p:choose>
</p:pipeline>
