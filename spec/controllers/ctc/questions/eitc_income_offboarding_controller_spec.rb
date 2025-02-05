require "rails_helper"

describe Ctc::Questions::EitcIncomeOffboardingController do
  let(:intake) { create :ctc_intake, :claiming_eitc, had_disqualifying_non_w2_income: had_disqualifying_non_w2_income, client: build(:client, tax_returns: [build(:tax_return, filing_status: filing_status)]) }
  let(:wages_amount) { 1 }
  let(:filing_status) { "single" }
  let(:had_disqualifying_non_w2_income) { "no" }

  describe ".show?" do
    context 'eitc environment variable is disabled' do
      it 'is false' do
        expect(described_class.show?(intake, subject)).to eq false
      end
    end

    context 'eitc environment variable is enabled' do
      before do
        Flipper.enable :eitc
        create :w2, intake: intake, wages_amount: wages_amount
      end

      context 'had_disqualifying_non_w2_income is yes' do
        let(:had_disqualifying_non_w2_income) { "yes" }

        it 'is true' do
          expect(described_class.show?(intake, subject)).to eq true
        end
      end

      context 'had_disqualifying_non_w2_income is no' do
        let(:had_disqualifying_non_w2_income) { "no" }

        context 'single' do
          let(:filing_status) { "single" }

          context 'w2 income less than 11,610' do
            let(:wages_amount) { 11_609 }

            it 'is false' do
              expect(described_class.show?(intake, subject)).to eq false
            end
          end

          context 'w2 income greater than or equal to 11,610' do
            let(:wages_amount) { 11_610 }

            it 'is true' do
              expect(described_class.show?(intake, subject)).to eq true
            end

            context 'but there is a qualifying child' do
              let!(:dependent) { create :qualifying_child, intake: intake }

              it 'is false' do
                expect(described_class.show?(intake, subject)).to eq false
              end
            end
          end
        end

        context 'married_filing_jointly' do
          let(:filing_status) { "married_filing_jointly" }

          context 'w2 income less than 17,550' do
            let(:wages_amount) { 17_549 }

            it 'is false' do
              expect(described_class.show?(intake, subject)).to eq false
            end
          end

          context 'w2 income greater than or equal to 17,550' do
            let(:wages_amount) { 17_550 }

            it 'is true' do
              expect(described_class.show?(intake, subject)).to eq true
            end
          end
        end
      end
    end
  end
end
