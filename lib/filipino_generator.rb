# frozen_string_literal: true

require 'active_support/all'
require 'ffaker'
require 'psgc'

# Generate a random set of digits not starting with zero
def random_not_starting_with_zero(digits)
  max = 10**digits
  min = 10**(digits - 1)
  Random.rand(min...max).to_s
end

# Typeface name and normalised pt size
FONTS = {
  'Bartdeng Regular' => 20
}.freeze

# PSGC data
PROVINCES = PSGC::Region.all.map(&:provinces).flatten

# Monkey patch PSGC::ProvinceOrDistrict to add a random city or municipality picker
module PSGC
  # PSGC::ProvinceOrDistrict
  class ProvinceOrDistrict
    def cities_or_municipalities
      @cities_or_municipalities ||= (cities + municipalities)
    end

    def random_city_or_municipality
      cities_or_municipalities.sample
    end
  end
end

# Used for place of birth, and as a superclass for Address
class CountryProvinceMunicipality
  attr_accessor :country, :province_or_state, :city_or_municipality

  def self.random
    CountryProvinceMunicipality.new.tap do |cpm|
      cpm.country = 'Philippines'
      province = PROVINCES.sample
      cpm.province_or_state = province.name.tr("',","").capitalize
      cpm.city_or_municipality = province.random_city_or_municipality.name.tr("',","").capitalize
    end
  end
end

# An address
class Address < CountryProvinceMunicipality
  attr_accessor :line_1, :line_2, :zip_code

  def self.random_zip_code
    Random.rand(1000..9999).to_s
  end

  def self.random
    Address.new.tap do |address|
      address.country = 'Philippines'
      province = PROVINCES.sample
      address.province_or_state = province.name.tr("',","").capitalize
      address.city_or_municipality = province.random_city_or_municipality.name.tr("',","").capitalize
      address.line_1 = FFaker::Address.street_address.tr("',","")
      address.line_2 = FFaker::Address.neighborhood.tr("',","")
      address.zip_code = random_zip_code
    end
  end
end

# A struct to hold PH government ID data
class GovernmentId
  attr_accessor :type, :number
  # Date
  attr_accessor :valid_until
  attr_accessor :image_file

  # Also allows
  TYPES = ['TIN', 'GSIS', 'SSS', 'CRN', 'PASSPORT', 'STUDENT ID'].freeze

  # Generates a random government TIN, GSIS, SSS or CRN
  def self.random_tin_gsis_sss_or_crn
    GovernmentId.new.tap do |id|
      id.type = TYPES.take(4).sample
      id.number = case id.type
                  when 'TIN'
                    random_not_starting_with_zero(12)
                  when 'GSIS'
                    random_not_starting_with_zero(11)
                  when 'SSS'
                    random_not_starting_with_zero(10)
                  when 'CRN'
                    random_not_starting_with_zero(12)
                  end
      id.valid_until = FFaker::Time.between(1.year.from_now, 10.years.from_now).to_date.strftime('%m/%d/%Y')
      id.image_file = 'images/' + Random.rand(18).to_s + '.jpeg'
    end
  end
end

# A Filipino
# rubocop:disable Metrics/ClassLength
class Person
  # rubocop:enable Metrics/ClassLength
  attr_accessor :first_name, :middle_name, :last_name, :suffix
  attr_accessor :nationality

  # Date
  attr_accessor :birth_date

  # 'male' | 'female'
  attr_accessor :sex

  # CountryProvinceMunicipality
  attr_accessor :place_of_birth

  # Address
  attr_accessor :permanent_address, :present_address

  attr_accessor :mobile_number
  attr_accessor :landline
  attr_accessor :email
  attr_accessor :nature_of_work, :source_of_funds, :industry, :name_of_employer
  attr_accessor :tin, :sss, :gsis, :crn
  attr_accessor :photograph 
  attr_accessor :specimen_signature
  attr_accessor :government_id1
  attr_accessor :government_id2

  def full_name
    [first_name, middle_name, last_name, suffix].reject(&:blank?).join(' ')
  end

  NATURE_OF_WORK = {
    'Employed' => 30,
    'Business Owner/Freelancer' => 25,
    'Unemployed' => 5,
    'Pensioner/Retired/Homemaker' => 10,
    'Student' => 10,
    'OFW' => 20
  }.freeze

  SOURCE_OF_FUNDS = {
    'Employed' => 'Salary',
    'Business Owner' => 'Income from Business',
    'Freelancer' => 'Income from Business',
    'Unemployed' => 'Remittances',
    'Pensioner' => 'Remittances',
    'Retired' => 'Remittances',
    'Homemaker' => 'Remittances',
    'Student' => 'Support from Relatives',
    'OFW' => 'Salary'
  }.freeze

  PSIC = <<~PSIC
    Agriculture forestry and fishing
    Mining and quarrying
    Manufacturing
    Electricity gas steam and air-conditioning supply
    Water supply sewerage waste management and
    remediation activities
    Construction
    Wholesale and retail trade repair of motor vehicles and motorcycles
    Transportation and storage
    Accommodation and food service activities
    Information and communication
    Financial and insurance activities
    Real estate activities
    Professional scientific and technical services
    Administrative and support service activities
    Public administrative and defense compulsory social security
    Education
    Human health and social work activities
    Arts entertainment and recreation
    Household and Domestic Services
  PSIC
         .lines.map { |s| s.chomp }

  class << self
    # Randomized according to
    # 30% Employed
    # 25% Business Owner/Freelancer
    # 5% Unemployed
    # 10% Pensioner/Retired/Homemaker
    # 10% Student
    # 20% OFW
    def random_nature_of_work
      raw_nature_of_work.split('/').sample
    end

    private

    def raw_nature_of_work
      i = Random.rand(100)
      NATURE_OF_WORK.each do |k, w|
        return k if i < w

        i -= w
      end
    end

    def random_passport_number
      (Array.new(2).map { ('A'..'Z').to_a.sample } + Array.new(7).map { Random.rand(10) }).join
    end

    public

    def random_digits(digits, prefix = nil)
      ([prefix] + Array.new(digits).map { Random.rand(10) }).join
    end

    # Generate a Person record using pr
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def generate
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      # rubocop:disable Metrics/BlockLength
      Person.new.tap do |p|
        # rubocop:enable Metrics/BlockLength
        male = Random.rand(2) == 1
        # 20% of the population will have a second name
        n_names = Random.rand(5).zero? ? 2 : 1
        p.first_name = Array.new(n_names).map do
          male ? FFaker::NamePH.first_name_male.tr("',","") : FFaker::NamePH.first_name_female
        end.join(' ').tr("',","")
        p.middle_name = FFaker::NamePH.last_name.tr("',","")
        p.last_name = FFaker::NamePH.last_name.tr("',","")
        # 5% of Male to have Sr. 5% of Male to have Jr.
        if male
          case Random.rand(20)
          when 0
            p.suffix = 'Sr'
          when 1
            p.suffix = 'Jr'
          when 2
            p.suffix = 'II'
          when 3
            p.suffix = 'III'
          when 4
            p.suffix = 'IV'
          end
        end
        p.sex = male ? 'M' : 'F'

        p.birth_date = FFaker::Time.between(70.years.ago, 18.years.ago).to_date.strftime('%m/%d/%Y')

        p.place_of_birth = CountryProvinceMunicipality.random

        p.permanent_address = Address.random
        # 33% will have a different present address from permanent address
        p.present_address = Random.rand(3).zero? ? Address.random : p.permanent_address

        # (+63) + "9" + randomize 9 random numbers
        p.mobile_number = '+639' + Array.new(9) { Random.rand(10) }.join + ''
        p.landline = Array.new(7) {Random.rand(10)}.join 
        p.email = rand(26**5).to_s(10) + '@gmail.com' 
        p.nationality = 'Philippines'

        p.nature_of_work = random_nature_of_work
        p.source_of_funds = SOURCE_OF_FUNDS[p.nature_of_work]
        if ['Employed', 'Business Owner/Freelancer', 'OFW'].include?(p.nature_of_work)
          p.industry = PSIC.sample
          p.name_of_employer = FFaker::Company.name.tr("',","")
        end

        p.photograph = 'images/pic_' + Random.rand(9).to_s + '.jpeg'
        p.specimen_signature = 'images/sig_' + Random.rand(3).to_s + '.jpeg'

        # ONLY IF Nature of Work is NOT Unemployed, Student or Homemaker
        # then choose randomly between generating a TIN, GSIS, SSS, CRN
        unless %w[Unemployed Student Homemaker].include?(p.nature_of_work)
          id1 = GovernmentId.random_tin_gsis_sss_or_crn
          case id1.type
          when 'TIN'
            p.tin = id1.number
          when 'GSIS'
            p.gsis = id1.number
          when 'SSS'
            p.sss = id1.number
          when 'CRN'
            p.crn = id1.number
          end
        end

        id2 = GovernmentId.random_tin_gsis_sss_or_crn
        case p.nature_of_work
        when 'Homemaker'
          id2.type = 'PASSPORT'
          id2.number = random_passport_number
        when 'Student'
          id2.type = 'STUDENT ID'
          id2.number = random_not_starting_with_zero(10)
        end
        p.government_id1 = id1

        unless %w[Unemployed Student Homemaker].include?(p.nature_of_work)
          id2 = GovernmentId.random_tin_gsis_sss_or_crn
          case id2.type
          when 'TIN'
            p.tin = id2.number
          when 'GSIS'
            p.gsis = id2.number
          when 'SSS'
            p.sss = id2.number
          when 'CRN'
            p.crn = id2.number
          end
        end 

        id2 = GovernmentId.random_tin_gsis_sss_or_crn
        case p.nature_of_work
        when 'HOMEMAKER'
          id2.type = 'PASSPORT'
          id2.number = random_passport_number
        when 'STUDENT'
          id2.type = 'STUDENT ID'
          id2.number = random_not_starting_with_zero(10)
        end
        p.government_id2 = id2
      end
    end
  end
end
