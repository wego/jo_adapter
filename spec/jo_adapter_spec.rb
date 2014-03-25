require 'spec_helper'

describe JoAdapter do
  before { I18n.locale = :en }

  let(:klass) do
    Class.new do
      include JoAdapter
      attr_accessor :name, :address, :details

      def name
        @name ||= '{"en":"this is name","id":"this is id","engrish":"hello","klingon":""}'
      end

      def address
        @address ||= '{"en":"this is address","id":"this is id address"}'
      end

      def details
        @details ||= '{"detail_name":"test","detail_address":"test address"}'
      end
    end
  end

  describe '.jo_writable' do
    subject(:instance) do
      klass.instance_eval { jo_writable :details, :detail_name, :detail_address }
      klass.new
    end

    context 'Given non-nil value to write' do
      before do
        subject.details_write = {
          "detail_name" => "name", 
          "detail_address" => "address",
          "unused_attribute" => "unused"
        }
      end
      describe 'accepts and writes the accepted attributes' do
        its(:details) do
          should eq({
            'detail_name' => 'name',
            'detail_address' => 'address'
          }.to_json)
        end
      end
      describe 'write automatically creates _json method' do
        its(:details_json) do
          should eq({
            'detail_name' => 'name',
            'detail_address' => 'address'
          })
        end
      end
    end

    context 'Given nil value' do
      before do
        subject.details_write = nil
      end
      describe 'json method should retain the old value' do
        its(:details_json) do
          should eq({
            'detail_name' => 'test',
            'detail_address' => 'test address'
          })
        end
      end
    end

  end

  describe '.jo' do
    subject(:instance) do
      klass.instance_eval { jo :name }
      klass.new
    end

    its(:name_json) do
      should eq({
        'en' => 'this is name',
        'id' => 'this is id',
        'engrish' => 'hello',
        'klingon' => ''
      })
    end

    describe 'accepts multiple arguments' do
      subject(:instance) do
        klass.instance_eval { jo :name, :address }
        klass.new
      end

      its(:address_json) do
        should eq({ 'en' => 'this is address', 'id' => 'this is id address' })
      end
    end
  end

  describe '.jo_i18n' do
    subject(:instance) do
      klass.instance_eval { jo_i18n :name }
      klass.new
    end

    its(:name_i18n) { should eq('this is name') }
    its(:name_en) { should eq('this is name') }

    it 'returns the value of the requested locale' do
      expect(instance.name_i18n('id')).to eq('this is id')
    end

    it 'returns the value of en when requested locale is present' do
      expect(instance.name_i18n('ru')).to eq('this is name')
    end

    it 'skips the requested fallback' do
      expect(instance.name_i18n(:ru, :en)).to be_nil
    end

    describe 'nil value' do
      subject(:instance) do
        klass.instance_eval do
          define_method(:empty) { nil }
          jo_i18n :empty
        end
        klass.new
      end

      its(:empty_i18n) { should be_blank }
    end

    describe 'accepts multiple arguments' do
      subject(:instance) do
        klass.instance_eval { jo_i18n :name, :address }
        klass.new
      end

      its(:address_i18n) { should eq('this is address') }
    end
  end

  describe '.jo_i18n_accessor' do
    context 'with nil attribute' do
      subject(:instance) do
        klass.instance_eval do
          attr_accessor :empty
          jo_i18n_accessor :empty
        end
        klass.new
      end

      before { instance.empty_i18n = 'a' }
      it 'attrbute should not be blank' do
        expect(instance.empty).not_to be_blank
      end
    end

    subject(:instance) do
      klass.instance_eval { jo_i18n_accessor :name }
      klass.new
    end

    context 'given nil' do
      before { instance.name_i18n = nil }
      it 'should not change' do
        expect(instance.name).to eq '{"en":"this is name","id":"this is id","engrish":"hello","klingon":""}'
      end
    end

    context 'given a value' do
      before { instance.name_i18n = 'a value' }
      it 'should change' do
        expect(instance.name).to eq '{"en":"a value","id":"this is id","engrish":"hello","klingon":""}'
      end
    end

    context 'given a locale' do
      before do
        I18n.locale = :id
        instance.name_i18n = 'new id name'
      end

      it 'should change correct locale' do
        expect(instance.name_json).to eq({
          'en' => 'this is name',
          'id' => 'new id name',
          'engrish' => 'hello',
          'klingon' => ''
        })
      end
    end

    context 'given a new locale' do
      before do
        I18n.locale = :test
        instance.name_i18n = 'name in test locale'
      end

      it 'should add new locale' do
        expect(instance.name_json['test']).to eq 'name in test locale'
      end
    end
  end

  describe 'fallbacks' do
    subject(:instance) do
      klass.instance_eval { jo_i18n :name }
      klass.new
    end

    before do
      JoAdapter.fallback('engrish', 'en')
      JoAdapter.fallback('english', 'en')
      JoAdapter.fallback('klingon', 'en')
    end

    it 'returns the expected fallback' do
      expect(JoAdapter.fallback_for('engrish')).to eq('en')
    end

    it 'returns the value of the fallback locale when given is not available' do
      expect(instance.name_i18n('english')).to eq('this is name')
    end

    it 'returns the value of the fallback locale when given key exists but does not have value' do
      expect(instance.name_i18n('klingon')).to eq('this is name')
    end

    specify 'when both fallback and requested locale is present, return value for requested locale' do
      expect(instance.name_i18n('engrish')).to eq('hello')
    end

    specify 'when both fallback and requested locale are not present, return value for en' do
      expect(instance.name_i18n('zh-cn')).to eq('this is name')
    end
  end

  describe '.jo_delegate' do
    subject(:instance) do
      klass.instance_eval { jo_delegate :details, :detail_name }
      klass.new
    end

    its(:detail_name) { should eq('test') }

    describe 'accepts multiple arguments' do
      subject(:instance) do
        klass.instance_eval { jo_delegate :details, :detail_name, :detail_address }
        klass.new
      end

      its(:detail_address) { should eq('test address') }
    end
  end
end
