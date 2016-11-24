require 'spec_helper'

describe Grom::Helpers do

  let(:extended_class) { Class.new { extend Grom::Helpers } }
  let(:surname_pattern) { RDF::Query::Pattern.new(:subject, RDF::URI.new("#{DATA_URI_PREFIX}/schema/surname"), :object) }
  let(:forename_pattern) { RDF::Query::Pattern.new(:subject, RDF::URI.new("#{DATA_URI_PREFIX}/schema/forename"), :object) }

  describe '#associations_url_builder' do
    it 'should return an endpoint when given a class and an associated class' do
      dummy = DummyPerson.find('1')
      url = extended_class.associations_url_builder(dummy, "Party", {})
      expect(url).to eq "#{API_ENDPOINT}/dummy_people/1/parties.ttl"
    end

    it 'should return an endpoint when given a class, an associated class and an options hash with optional set' do
      dummy = DummyPerson.find('1')
      url = extended_class.associations_url_builder(dummy, "Party", {optional: "current" })
      expect(url).to eq "#{API_ENDPOINT}/dummy_people/1/parties/current.ttl"
    end

    it 'should return an endpoint when given a class, an associated class and an options hash with single set to true' do
      dummy = DummyPerson.find('1')
      url = extended_class.associations_url_builder(dummy, "Party", {single: true })
      expect(url).to eq "#{API_ENDPOINT}/dummy_people/1/party.ttl"
    end
  end

  describe '#find_base_url_builder' do
    it 'should return a url with the api_endpoint and the pluralized, underscored and downcased name of the class and an id when provided' do
      url = extended_class.find_base_url_builder("ContactPerson", "1")
      expect(url).to eq "#{API_ENDPOINT}/contact_people/1"
    end
  end

  describe '#all_base_url_builder' do
    it 'should return a url with the api_endpoint and the pluralized, underscored and downcased name of the class' do
      url = extended_class.all_base_url_builder("ContactPerson")
      expect(url).to eq "#{API_ENDPOINT}/contact_people"
    end

    it 'should return a url with the api_endpoint and the pluralized, underscored and downcased name of the class and given optionals' do
      url = extended_class.all_base_url_builder("ContactPerson", "members", "current")
      expect(url).to eq "#{API_ENDPOINT}/contact_people/members/current"
    end
  end

  describe '#create_class_name' do
    it 'should camelize, capitalize and singularize any plural underscore properties' do
      expect(extended_class.create_class_name('dummy_party_memberships')).to eq 'DummyPartyMembership'
    end
  end

  describe '#create_property_name' do
    it 'should underscore and downcase any singular class name' do
      expect(extended_class.create_property_name('DummyPerson')).to eq 'dummy_person'
    end
  end

  describe '#create_plural_property_name' do
    it 'should underscore, downcase and pluralize any singular class name' do
      expect(extended_class.create_plural_property_name('DummyPerson')).to eq 'dummy_people'
    end
  end

  describe '#collective_graph' do
    it 'should return the collective graph for the objects in the array' do
      dummy_people = DummyPerson.all
      collective_graph = extended_class.collective_graph(dummy_people)
      arya_surname_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/2"), RDF::URI.new("#{DATA_URI_PREFIX}/schema/surname"), :object)
      daenerys_surname_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/1"), RDF::URI.new("#{DATA_URI_PREFIX}/schema/surname"), :object)
      expect(collective_graph.query(arya_surname_pattern).first_object.to_s).to eq 'Stark'
      expect(collective_graph.query(daenerys_surname_pattern).first_object.to_s).to eq 'Targaryen'
    end
  end

  describe '#collective_through_graph' do
    it 'should return a graph that contains statements for teh owner, the associated objects and the through objects' do
      dummy = DummyPerson.find('1')
      party_one_type_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/23"), RDF::URI.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :object)
      party_two_type_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/26"), RDF::URI.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :object)
      party_one_name_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/23"), RDF::URI.new("#{DATA_URI_PREFIX}/schema/partyName"), :object)
      party_two_name_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/26"), RDF::URI.new("#{DATA_URI_PREFIX}/schema/partyName"), :object)
      party_one_connection_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/25"), RDF::URI.new("#{DATA_URI_PREFIX}/schema/partyMembershipHasParty"), :object)
      party_two_connection_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/27"), RDF::URI.new("#{DATA_URI_PREFIX}/schema/partyMembershipHasParty"), :object)
      party_one_membership_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/25"), RDF::URI.new("#{DATA_URI_PREFIX}/schema/partyMembershipEndDate"), :object)
      party_two_membership_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/27"), RDF::URI.new("#{DATA_URI_PREFIX}/schema/partyMembershipEndDate"), :object)
      party_membership_one_type_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/25"), RDF::URI.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :object)
      party_membership_two_type_pattern = RDF::Query::Pattern.new(RDF::URI.new("http://id.example.com/27"), RDF::URI.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), :object)


      collective_graph = extended_class.collective_through_graph(dummy, dummy.dummy_parties, :dummy_party_memberships)
      expect(collective_graph.query(forename_pattern).first_object.to_s).to eq 'Daenerys'
      expect(collective_graph.query(surname_pattern).first_object.to_s).to eq 'Targaryen'
      expect(collective_graph.query(party_one_name_pattern).first_object.to_s).to eq 'Targaryens'
      expect(collective_graph.query(party_two_name_pattern).first_object.to_s).to eq 'Dothrakis'
      expect(collective_graph.query(party_one_type_pattern).first_object.to_s).to eq 'http://id.example.com/schema/DummyParty'
      expect(collective_graph.query(party_two_type_pattern).first_object.to_s).to eq 'http://id.example.com/schema/DummyParty'
      expect(collective_graph.query(party_membership_one_type_pattern).first_object.to_s).to eq 'http://id.example.com/schema/DummyPartyMembership'
      expect(collective_graph.query(party_membership_two_type_pattern).first_object.to_s).to eq 'http://id.example.com/schema/DummyPartyMembership'
      expect(collective_graph.query(party_one_membership_pattern).first_object.to_s).to eq '1954-01-12'
      expect(collective_graph.query(party_two_membership_pattern).first_object.to_s).to eq '1955-03-11'
      expect(collective_graph.query(party_one_connection_pattern).first_object.to_s).to eq 'http://id.example.com/23'
      expect(collective_graph.query(party_two_connection_pattern).first_object.to_s).to eq 'http://id.example.com/26'
    end
  end

end