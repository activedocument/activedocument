# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Config::Introspection do

  context 'CONFIG_RB_PATH' do
    it 'refers to an actual source file' do
      expect(File.exist?(Mongoid::Config::Introspection::CONFIG_RB_PATH)).to be true
    end
  end

  describe '#options' do
    let(:options) { described_class.options }
    let(:all_options) { described_class.options(include_deprecated: true) }
    let(:deprecated_options) { all_options.select(&:deprecated?) }

    # NOTE: the "with deprecated options" context tests a configuration option
    # that is known to be deprecated (see `let(:option_name)`). When this
    # deprecated option is eventually removed, the "exclude" spec will break.
    # At that time, update the `:option_name` helper to reference a different
    # deprecated option (if any), or else skip the specs in this context.
    #
    # TODO: Currently no options are deprecated
    context 'with deprecated options' do
      let(:option_name) { 'background_indexing' }

      it 'excludes deprecated options by default' do
        skip 'no options are deprecated'
        option = options.detect { |opt| opt.name == option_name }
        expect(option).to be_nil
      end

      it 'deprecated options should be included when requested' do
        skip 'no options are deprecated'
        option = all_options.detect { |opt| opt.name == option_name }
        expect(option).to_not be_nil
      end
    end

    Mongoid::Config.defaults.each do |name, default_value|
      context "for the `#{name}` option" do
        let(:option) { all_options.detect { |opt| opt.name == name.to_s } }
        let(:live_option) { options.detect { |opt| opt.name == name.to_s } }

        it 'is parsed by the introspection scraper' do
          expect(option).to_not be_nil
          expect(option.default).to eq default_value.inspect.gsub(/\A"(.+)"\z/, '\'\1\'')
          expect(option.comment.strip).to_not be_empty
        end

        it 'is excluded by default if it is deprecated' do
          if option.deprecated?
            expect(live_option).to be_nil
          else
            expect(live_option).to eq option
          end
        end
      end
    end
  end

  describe Mongoid::Config::Introspection::Option do
    let(:option) do
      described_class.new(
        'name', 'default', "   # line 1\n    # line 2\n"
      )
    end

    describe '.from_captures' do
      it "populates the option's fields" do
        option = described_class.from_captures([nil, '# comment', 'name', 'default'])
        expect(option.name).to eq 'name'
        expect(option.default).to eq 'default'
        expect(option.comment).to eq '# comment'
      end
    end

    describe '#initialize' do
      it 'unindents the given comment' do
        expect(option.name).to eq 'name'
        expect(option.default).to eq 'default'
        expect(option.comment).to eq "# line 1\n# line 2"
      end
    end

    describe '#indented_comment' do
      it 'has defaults' do
        expect(option.indented_comment).to eq "# line 1\n  # line 2"
      end

      it 'allows indentation to be specified' do
        expect(option.indented_comment(indent: 3)).to eq "# line 1\n   # line 2"
      end

      it 'allows the first line to be indented' do
        expect(option.indented_comment(indent: 3, indent_first_line: true))
          .to eq "   # line 1\n   # line 2"
      end
    end

    describe '#deprecated?' do
      let(:deprecated_option) do
        described_class.new(
          'name', 'default', "# this\n# is (Deprecated), yo\n"
        )
      end

      it 'is not deprecated by default' do
        expect(option.deprecated?).to_not be true
      end

      it 'is deprecated when the comment includes "(Deprecated)"' do
        expect(deprecated_option.deprecated?).to be true
      end
    end
  end
end
