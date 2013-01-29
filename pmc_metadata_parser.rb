# -*- coding: utf-8 -*-

require "nokogiri"
require "open-uri"
require "ap"

class PMCMetadataParser
  def initialize(xml)
    @nkgr = Nokogiri::XML(xml)
  end
  
  def pmcid
    @nkgr.css("article-id").select{|n| n.attr("pub-id-type") == "pmc"}.first.inner_text
  end
  
  def pmid
    @nkgr.css("article-id").select{|n| n.attr("pub-id-type") == "pmid"}.first.inner_text    
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
    url = "http://ncbi.nlm.nih.gov/pmc/articles/PMC#{pmcid}/citedby"
    nkgr = Nokogiri::XML(open(url))
    article_list = nkgr.css("div.rprt").select{|node| !node.css("dl.rprtid/dd").inner_text.include?(pmcid) }
    article_list.map do |node|
      pmcid = node.css("dl.rprtid/dd").inner_text
      title = node.css("div.title/a").inner_text
      { pmcid: pmcid,
        title: title }
    end
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


if __FILE__ == $0
  p = PMCMetadataParser.new(open("./test.xml"))
  ap p.all
  
  if ARGV.first == "--text"
    text = p.body.map do |section|
      if section.has_key?(:subsec)
        section[:subsec].map do |subsec|
          subsec[:subsec_text]
        end
      else
        section[:sec_text]
      end
    end
    ap text.flatten.join("\s")
  end
end
