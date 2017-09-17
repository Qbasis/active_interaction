require 'spec_helper'

class Thing; end
class Things; end

describe ActiveInteraction::ObjectFilter, :filter do
  include_context 'filters'
  it_behaves_like 'a filter'

  before do
    options[:class] = Thing
  end

  describe '#cast' do
    let(:value) { Thing.new }
    let(:result) { filter.cast(value, nil) }

    context 'with class as a Class' do
      it 'returns the instance' do
        expect(result).to eql value
      end

      it 'handles reconstantizing' do
        expect(result).to eql value

        Object.send(:remove_const, :Thing)
        class Thing; end
        value = Thing.new

        expect(filter.cast(value, nil)).to eql value
      end

      it 'handles reconstantizing subclasses' do
        filter

        Object.send(:remove_const, :Thing)
        class Thing; end
        class SubThing < Thing; end
        value = SubThing.new

        expect(filter.cast(value, nil)).to eql value
      end

      it 'does not overflow the stack' do
        klass = Class.new do
          def self.name
            Thing.name
          end
        end

        expect do
          filter.cast(klass.new, nil)
        end.to raise_error ActiveInteraction::InvalidValueError
      end

      context 'without the class available' do
        before { Object.send(:remove_const, :Thing) }
        after { class Thing; end }

        it 'does not raise an error on initialization' do
          expect { filter }.to_not raise_error
        end
      end

      context 'with bidirectional class comparisons' do
        let(:case_equality) { false }
        let(:class_equality) { false }

        before do
          allow(Thing).to receive(:===).and_return(case_equality)
          allow(value).to receive(:is_a?).and_return(class_equality)
        end

        context 'without case or class equality' do
          it 'raises an error' do
            expect do
              result
            end.to raise_error ActiveInteraction::InvalidValueError
          end
        end

        context 'with case equality' do
          let(:case_equality) { true }

          it 'returns the instance' do
            expect(result).to eql value
          end
        end

        context 'with class equality' do
          let(:class_equality) { true }

          it 'returns the instance' do
            expect(result).to eql value
          end
        end
      end
    end

    context 'with class as a superclass' do
      before do
        options[:class] = Thing.superclass
      end

      it 'returns the instance' do
        expect(result).to eql value
      end
    end

    context 'with class as a String' do
      before do
        options[:class] = Thing.name
      end

      it 'returns the instance' do
        expect(result).to eql value
      end
    end

    context 'with a plural class' do
      let(:value) { Things.new }

      before { options[:class] = Things }

      it 'returns the instance' do
        expect(result).to eql value
      end
    end

    context 'with class as an invalid String' do
      before do
        options[:class] = 'invalid'
      end

      it 'raises an error' do
        expect do
          result
        end.to raise_error ActiveInteraction::InvalidClassError
      end
    end
  end

  describe '#database_column_type' do
    it 'returns :string' do
      expect(filter.database_column_type).to eql :string
    end
  end
end
