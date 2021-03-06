<?xml version="1.0" encoding="UTF-8"?>
<!--
	XPL handling SPARQL queries from Fuseki	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

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

	<!-- get query from a text file on disk -->
	<p:processor name="oxf:url-generator">
		<p:input name="config">
			<config>
				<url>oxf:/apps/nomisma/ui/sparql/typological_distribution.sparql</url>
				<content-type>text/plain</content-type>
				<encoding>utf-8</encoding>
			</config>
		</p:input>
		<p:output name="data" id="query"/>
	</p:processor>

	<p:processor name="oxf:text-converter">
		<p:input name="data" href="#query"/>
		<p:input name="config">
			<config/>
		</p:input>
		<p:output name="data" id="query-document"/>
	</p:processor>

	<!-- add in compare queries -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="#request"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
				<!-- request parameters -->
				<xsl:param name="compare" select="/request/parameters/parameter[name='compare']/value"/>
				<xsl:param name="filter" select="/request/parameters/parameter[name='filter']/value"/>

				<xsl:template match="/">
					<queries>
						<xsl:if test="string($filter)">
							<query>
								<xsl:value-of select="normalize-space($filter)"/>
							</query>
						</xsl:if>
						<xsl:for-each select="$compare">
							<query>
								<xsl:value-of select="."/>
							</query>
						</xsl:for-each>
					</queries>
				</xsl:template>

			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="compare-queries"/>
	</p:processor>

	<!-- when there is at least one compare query, then aggregate the compare queries with the primary query into one model -->
	<p:for-each href="#compare-queries" select="//query" root="response" id="sparql-results">
		<p:processor name="oxf:unsafe-xslt">
			<p:input name="filter" href="current()"/>
			<p:input name="query" href="#query-document"/>
			<p:input name="request" href="#request"/>
			<p:input name="data" href="../../../config.xml"/>
			<p:input name="config">
				<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
					<!-- request parameters -->
					<xsl:param name="filter" select="doc('input:filter')/query"/>
					<xsl:param name="dist" select="doc('input:request')/request/parameters/parameter[name='dist']/value"/>
					<xsl:param name="format" select="doc('input:request')/request/parameters/parameter[name='format']/value"/>

					<!-- config variables -->
					<xsl:variable name="sparql_endpoint" select="/config/sparql_query"/>
					<xsl:variable name="query" select="doc('input:query')"/>

					<!-- parse query statements into a data object -->
					<xsl:variable name="statements" as="element()*">
						<statements>
							<!-- parse filters -->
							<xsl:for-each select="tokenize($filter, ';')">
								<xsl:variable name="property" select="substring-before(normalize-space(.), ' ')"/>
								<xsl:variable name="object" select="substring-after(normalize-space(.), ' ')"/>

								<xsl:choose>
									<xsl:when test="$property = 'portrait' or $property='deity'">
										<triple s="?coinType" p="nmo:hasObverse" o="?obv"/>
										<triple s="?coinType" p="nmo:hasReverse" o="?rev"/>
										<union>
											<triple s="?obv" p="nmo:hasPortrait" o="{$object}"/>
											<triple s="?rev" p="nmo:hasPortrait" o="{$object}"/>
										</union>
									</xsl:when>
									<xsl:when test="$property = 'from'">
										<xsl:if test="$object castable as xs:integer">
											<xsl:variable name="gYear" select="format-number(number($object), '0000')"/>
											
											<triple s="?coinType" p="nmo:hasStartDate" o="?startDate">
												<xsl:attribute name="filter">
													<xsl:text>(?startDate >= "</xsl:text>
													<xsl:value-of select="$gYear"/>
													<xsl:text>"^^xsd:gYear)</xsl:text>
												</xsl:attribute>
											</triple>
										</xsl:if>
									</xsl:when>
									<xsl:when test="$property = 'to'">
										<xsl:if test="$object castable as xs:integer">
											<xsl:variable name="gYear" select="format-number(number($object), '0000')"/>
											
											<triple s="?coinType" p="nmo:hasEndDate" o="?endDate">
												<xsl:attribute name="filter">
													<xsl:text>(?endDate &lt;= "</xsl:text>
													<xsl:value-of select="$gYear"/>
													<xsl:text>"^^xsd:gYear)</xsl:text>
												</xsl:attribute>
											</triple>
										</xsl:if>
									</xsl:when>
									<xsl:otherwise>
										<triple s="?coinType" p="{$property}" o="{$object}"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>

							<!-- parse dist -->
							<xsl:choose>
								<xsl:when test="$dist='portrait' or $dist='deity'">
									<xsl:variable name="distClass" select="if ($dist='portrait') then 'foaf:Person' else 'wordnet:Deity'"/>

									<triple s="?coinType" p="nmo:hasObverse" o="?obv"/>
									<triple s="?coinType" p="nmo:hasReverse" o="?rev"/>
									<union>
										<triple s="?obv" p="nmo:hasPortrait" o="?dist"/>
										<triple s="?rev" p="nmo:hasPortrait" o="?dist"/>
									</union>
									<triple s="?dist" p="a" o="{$distClass}"/>
								</xsl:when>
								<xsl:otherwise>
									<triple s="?coinType" p="{$dist}" o="?dist"/>
									<!-- if the dist is mint, then include lat and long, but only for CSV -->
									<xsl:if test="$dist='nmo:hasMint' and $format='csv'">
										<optional>
											<triple s="?dist" p="geo:location" o="?loc"/>
											<triple s="?loc" p="geo:lat" o="?lat"/>
											<triple s="?loc" p="geo:long" o="?long"/>
										</optional>
									</xsl:if>
								</xsl:otherwise>
							</xsl:choose>
						</statements>
					</xsl:variable>

					<xsl:variable name="statementsSPARQL">
						<xsl:apply-templates select="$statements/*"/>
					</xsl:variable>

					<xsl:variable name="service">
						<xsl:value-of
							select="concat($sparql_endpoint, '?query=', encode-for-uri(replace($query, '%STATEMENTS%', $statementsSPARQL)), '&amp;output=xml')"
						/>
					</xsl:variable>

					<xsl:template match="/">
						<config>
							<url>
								<xsl:value-of select="$service"/>
							</url>
							<content-type>application/xml</content-type>
							<encoding>utf-8</encoding>
						</config>
					</xsl:template>

					<xsl:template match="triple">
						<xsl:value-of select="concat(@s, ' ', @p, ' ', @o, if (@filter) then concat(' FILTER ', @filter) else '', '.')"/>						
						<xsl:if test="not(parent::union)">
							<xsl:text>&#x0A;</xsl:text>
						</xsl:if>
					</xsl:template>

					<xsl:template match="optional">
						<xsl:text>OPTIONAL {</xsl:text>
						<xsl:apply-templates select="triple"/>
						<xsl:text>}&#x0A;</xsl:text>
					</xsl:template>

					<xsl:template match="union">
						<xsl:for-each select="triple">
							<xsl:if test="position() &gt; 1">
								<xsl:text>UNION </xsl:text>
							</xsl:if>
							<xsl:text>{</xsl:text>
							<xsl:apply-templates select="self::node()"/>
							<xsl:text>}&#x0A;</xsl:text>
						</xsl:for-each>
					</xsl:template>

				</xsl:stylesheet>
			</p:input>
			<p:output name="data" id="compare-url-generator-config"/>
		</p:processor>

		<!-- get the data from fuseki -->
		<p:processor name="oxf:url-generator">
			<p:input name="config" href="#compare-url-generator-config"/>
			<p:output name="data" ref="sparql-results"/>
		</p:processor>
	</p:for-each>

	<p:processor name="oxf:identity">
		<p:input name="data" href="#sparql-results"/>
		<p:output name="data" ref="data"/>
	</p:processor>
</p:config>
