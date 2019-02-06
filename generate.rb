#!/usr/bin/env ruby
# frozen_string_literal: true
require 'csv'
require 'json'

$LOAD_PATH << File.expand_path('lib', __dir__)

require 'filipino_generator'

N = ARGV[0] ? ARGV[0].to_i : 1

GENERATED = Array.new(N).map do
  Person.generate
end

CAMELIZED_HASH = GENERATED.as_json.map do |p|
  p.deep_transform_keys { |key| key.to_s.camelize(:lower) }
end

# puts CAMELIZED_HASH.to_json

# csv_string = CSV.generate do |csv|
#   JSON.parse(CAMELIZED_HASH.to_json).each do |hash|
#     csv << hash.values
#   end
# end

# puts csv_string


data = JSON.parse(CAMELIZED_HASH.to_json)


data.each do |test|
  if (test['governmentId1'] != nil && test['governmentId2'] != nil)  then
    puts "#{test['firstName']},#{test['middleName']},#{test['lastName']},#{test['suffix']},#{test['sex']},,#{test['photograph']},#{test['birthDate']},#{test['placeOfBirth']['country']},#{test['placeOfBirth']['provinceOrState']},#{test['placeOfBirth']['cityOrMunicipality']},#{test['permanentAddress']['line1']},#{test['permanentAddress']['line2']},#{test['permanentAddress']['country']},#{test['permanentAddress']['provinceOrState']},#{test['permanentAddress']['cityOrMunicipality']},#{test['permanentAddress']['zipCode']},#{test['presentAddress']['line1']},#{test['presentAddress']['line2']},#{test['presentAddress']['country']},#{test['presentAddress']['provinceOrState']},#{test['presentAddress']['cityOrMunicipality']},#{test['presentAddress']['zipCode']},#{test['landline']},#{test['mobileNumber']},#{test['email']},#{test['nationality']},#{test['natureOfWork']},#{test['industry']},#{test['nameOfEmployer']},#{test['sourceOfFunds']},#{test['specimenSignature']},#{test['tin']},#{test['sss']},#{test['gsis']},#{test['crn']},#{test['governmentId1']['type']},#{test['governmentId1']['validUntil']},#{test['governmentId1']['number']},#{test['governmentId1']['imageFile']},#{test['governmentId2']['type']},#{test['governmentId2']['validUntil']},#{test['governmentId2']['number']},#{test['governmentId2']['imageFile']}"
  end
end