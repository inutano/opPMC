# :)

require 'nokogiri'
require 'open-uri'
  
module PublicationParser
  class PubMedMetadataParser
    def initialize(xml)
      @nkgr = Nokogiri::XML(xml)
    end
    
    def pmid
      @nkgr.css("MedlineCitation PMID").first.inner_text
    end
    
    def pmcid
      array = @nkgr.css("ArticleIdList/ArticleId").select{|node| node.attribute("IdType").value == "pmc" }
      array.first.inner_text if array.first
    end
    
    def journal_title
      @nkgr.css("Journal Title").inner_text
    end
    
    def journal_isoabbreviation
      @nkgr.css("Journal ISOAbbreviation").inner_text
    end
    
    def article_title
      @nkgr.css("ArticleTitle").inner_text
    end
    
    def abstract
      @nkgr.css("AbstractText").inner_text
    end
    
    def affiliation
      @nkgr.css("Affiliation").inner_text
    end
    
    def authors
      @nkgr.css("AuthorList Author").map do |node|
        lastname = node.css("LastName").inner_text
        forename = node.css("ForeName").inner_text
        initial = node.css("Initials").inner_text
        { lastname: lastname, forename: forename, initial: initial }
      end
    end
    
    def comments_corrections
      @nkgr.css("CommentsCorrections").map do |node|
        ref_type = node.attr("RefType").to_s
        ref_source = node.css("RefSource").inner_text
        pmid = node.css("PMID").inner_text
        { ref_type: ref_type, ref_source: ref_source, pmid: pmid }
      end
    end
    
    def chemicals
      @nkgr.css("ChemicalList Chemical").map do |node|
        registry_number = node.css("RegistryNumber").inner_text
        name_of_substance = node.css("NameOfSubstance").inner_text
        { registry_number: registry_number, name_of_substance: name_of_substance }
      end
    end
    
    def mesh_terms
      @nkgr.css("MeshHeading").map do |node|
        descriptor_name = node.css("DescriptorName").inner_text
        qualifier_name = node.css("QualifierName").inner_text
        { descriptor_name: descriptor_name, qualifier_name: qualifier_name }
      end
    end
    
    def date_created
      year = @nkgr.css("DateCreated Year").inner_text
      month = @nkgr.css("DateCreated Month").inner_text
      day = @nkgr.css("DateCreated Day").inner_text
      { year: year, month: month, day: day }
    end
    
    def all
      { pmid: self.pmid,
        pmcid: self.pmcid,
        journal_title: self.journal_title,
        journal_isoabbreviation: self.journal_isoabbreviation,
        article_title: self.article_title,
        abstract: self.abstract,
        affiliation: self.affiliation,
        authors: self.authors,
        comments_corrections: self.comments_corrections,
        mesh_terms: self.mesh_terms,
        date_created: self.date_created }
    end
  end
  
  class PMCMetadataParser
    def initialize(xml)
      @nkgr = Nokogiri::XML(xml)
    end
    
    def is_available?
      @nkgr.css("article-id").first
    end
    
    def pmcid
      @nkgr.css("article-id").select{|n| n.attr("pub-id-type").to_s == "pmc"}.first.inner_text
    end
    
    def pmid
      @nkgr.css("article-id").select{|n| n.attr("pub-id-type").to_s == "pmid"}.first.inner_text
    end
    
    def journal_id
      @nkgr.css("journal-id").inner_text
    end
    
    def journal_title
      @nkgr.css("journal-title").inner_text
    end
    
    def publisher_name
      @nkgr.css("publisher-name").inner_text
    end
    
    def publisher_loc
      @nkgr.css("publisher-loc").inner_text
    end
    
    def article_title
      @nkgr.css("title-group article-title").inner_text
    end
    
    def authors
      @nkgr.css("contrib-group name").map do |node|
        node.css("surname").inner_text + "\s" + node.css("given-names").inner_text
      end
    end
    
    def ppub_date
      node = @nkgr.css("pub-date").select{|n| n.attr("pub-type").to_s == "ppub" }.first
      year = node.css("year").inner_text
      month = node.css("month").inner_text
      day = node.css("day").inner_text
      {year: year, month: month, day: day}
    end
    
    def epub_date
      node = @nkgr.css("pub-date").select{|n| n.attr("pub-type").to_s == "epub" }.first
      year = node.css("year").inner_text
      month = node.css("month").inner_text
      day = node.css("day").inner_text
      {year: year, month: month, day: day}
    end
    
    def abstract
      @nkgr.css("abstract").inner_text
    end
    
    def keywords
      @nkgr.css("kwd").map{|n| n.inner_text }
    end
    
    def body
      @nkgr.css("body").children.map do |node_section|
        begin
          sec_title = node_section.css("title").first.inner_text
          nodeset_subsec = node_section.css("sec")
          unless nodeset_subsec.empty?
            subsec = nodeset_subsec.map do |node_subsec|
              subsec_title = node_subsec.css("title").inner_text
              subsec_text = node_subsec.css("p").map{|n| n.inner_text }
              { subsec_title: subsec_title, subsec_text: subsec_text }
            end
            { sec_title: sec_title, subsec: subsec }
          else
            sec_text = node_section.css("p").map{|n| n.inner_text }
            { sec_title: sec_title, sec_text: sec_text }
          end
        rescue NoMethodError
          next
        end
      end
    end
    
    def ref_journal_list
      cite = @nkgr.css("citation").select{|n| n.attr("citation-type").to_s == "journal" }
      cite.map do |node|
        article_title = node.css("article-title").inner_text
        pmid = node.css("pub-id").select{|n| n.attr("pub-id-type").to_s	== "pmid" }.first
        pmid = pmid.inner_text if pmid
        { article_title: article_title, pmid: pmid }
      end
    end
    
    def cited_by
      pmcid = self.pmcid
      if pmcid
        url = "http://ncbi.nlm.nih.gov/pmc/articles/PMC#{pmcid}/citedby"
        nkgr = Nokogiri::XML(open(url))
        article_list = nkgr.css("div.rprt").select do |node|
          !node.css("dl.rprtid/dd").inner_text.include?(pmcid)
        end
        article_list.map do |node|
          { pmcid: node.css("dl.rprtid/dd").inner_text,
            title: node.css("div.title").inner_text }
        end
      end
    rescue OpenURI::HTTPError
      nil
    end
    
    def all
      { pmcid: self.pmcid,
        pmid: self.pmid,
        journal_id: self.journal_id,
        journal_title: self.journal_title,
        publisher_name: self.publisher_name,
        publisher_loc: self.publisher_loc,
        article_title: self.article_title,
        authors: self.authors,
        ppub_date: self.ppub_date,
        epub_date: self.epub_date,
        abstract: self.abstract,
        keywords: self.keywords,
        body: self.body,
        ref_journal_list: self.ref_journal_list,
        cited_by: self.cited_by }
    end
  end
end
