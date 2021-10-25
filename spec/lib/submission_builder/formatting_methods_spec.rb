require 'rails_helper'

describe SubmissionBuilder::FormattingMethods do
  let(:dummy_class) { Class.new() { extend SubmissionBuilder::FormattingMethods } }

  describe '#name_line_1_type' do
    subject(:formatted_name) { dummy_class.name_line_1_type(primary_first, primary_middle, primary_last, primary_suffix, spouse_first, spouse_middle, spouse_last) }

    let(:primary_first) { "Samantha" }
    let(:primary_middle) { nil }
    let(:primary_last) { "Seashells" }
    let(:primary_suffix) { nil }
    let(:spouse_first) { nil }
    let(:spouse_middle) { nil }
    let(:spouse_last) { nil }

    context 'when there is only a primary name' do
      context 'with a middle initial' do
        let(:primary_middle) { "C" }
        it 'formats it correctly' do
          expect(formatted_name).to eq("SAMANTHA C<SEASHELLS")
        end
      end

      context 'with an accent' do
        let(:primary_first) { "Sám" }
        it 'formats it correctly' do
          expect(formatted_name).to eq("SAM<SEASHELLS")
        end
      end

      context 'with an apostrophe' do
        let(:primary_last) { "S/'shells" }
        it 'formats it correctly' do
          expect(formatted_name).to eq("SAMANTHA<SSHELLS")
        end
      end

      context 'with a hyphenated last name' do
        let(:primary_last) { "Sea-shells" }
        it 'formats it correctly' do
          expect(formatted_name).to eq("SAMANTHA<SEA-SHELLS")
        end
      end

      context 'with a suffix' do
        let(:primary_suffix) { "Jr" }
        it 'formats it correctly' do
          expect(formatted_name).to eq("SAMANTHA<SEASHELLS<JR")
        end
      end

      context "when the name line is > 35" do
        context "due to a long first name" do
          let(:primary_first) { "Sssssaaaaaammmaaaannnthhhhaaaaaaaaaa"}
          it "truncates it correctly" do
            expect(formatted_name).to eq("S<S")
          end
        end

        context "due to a long last name" do
          let(:primary_last) { "Seeeeeeeeeeeeaaashhhhhhhhhhhhellllls"}
          let(:primary_middle) { "C" }
          it "truncates it correctly" do
            expect(formatted_name).to eq("SAMANTHA C<S")
          end
        end
      end
    end

    context 'when there is a spouse name' do
      let(:spouse_first) { "Cora" }
      let(:spouse_middle) { "O" }

      context "with a different last name" do
        let(:spouse_last) { "Coconut" }
        it 'formats it correctly' do
          expect(formatted_name).to eq("SAMANTHA<SEASHELLS<& CORA O COCONUT")
        end

        context 'with a primary suffix' do
          let(:primary_suffix) { "Jr" }
          it 'formats it correctly' do
            expect(formatted_name).to eq("SAMANTHA<SEASHELLS<JR & CORA O C")
          end
        end

        context "when the name line is > 35" do
          context "due to a long first name" do
            let(:spouse_first) { "Coooooooooooooooooooooooooooooooooora"}
            it "truncates it correctly" do
              expect(formatted_name).to eq("SAMANTHA<S<& C C")
            end
          end

          context "due to a long last name" do
            let(:spouse_last) { "Coooooooocoooooooooooonut" }
            it "truncates it correctly" do
              expect(formatted_name).to eq("SAMANTHA<SEASHELLS<& CORA O C")
            end
          end
        end
      end

      context "with the same last name" do
        let(:spouse_last) { "Seashells" }
        it 'formats it correctly' do
          expect(formatted_name).to eq("SAMANTHA & CORA O<SEASHELLS")
        end

        context 'with a primary suffix' do
          let(:primary_suffix) { "Jr" }
          it 'formats it correctly' do
            expect(formatted_name).to eq("SAMANTHA & CORA O<SEASHELLS<JR")
          end
        end

        context "when the name line is > 35" do
          let(:spouse_first) { "Coooooooooooooooooooooooooooooooooora"}
          it "truncates it correctly" do
            expect(formatted_name).to eq("SAMANTHA & C<S")
          end
        end
      end
    end
  end

  describe "#phone_type" do
    context "with a California phone number" do
      it "returns a 10-digit version without country code or formatting" do
        expect(dummy_class.phone_type("+14158161286")).to eq("4158161286")
      end
    end

    context "with a Puerto Rico phone number" do
      it "returns a 10-digit version without country code or formatting" do
        expect(dummy_class.phone_type("+17877640000")).to eq("7877640000")
      end
    end
  end
end
