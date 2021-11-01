require "rails_helper"

describe UpdateClientVitaPartnerService do
  describe ".update" do
    before do
      allow(BaseService).to receive(:ensure_transaction).and_yield
    end

    subject { UpdateClientVitaPartnerService.new(clients: [client], vita_partner_id: other_site.id, change_initiated_by: assigned_user) }

    let(:current_site) { create :site }
    let(:other_site) { create :site, parent_organization: current_site.parent_organization }
    let(:client) { create :client, vita_partner: current_site, tax_returns: [tax_return] }
    let(:tax_return) { create :tax_return, year: 2019, assigned_user: assigned_user }
    let(:assigned_user) { create :team_member_user, site: current_site }

    context "when an assigned user does not have access to the new vita partner" do
      it "changes the vita partner" do
        expect { subject.update! }.to change(client, :vita_partner).from(current_site).to(other_site)
      end

      it "leaves a note" do
        expect { subject.update! }.to change(SystemNote::OrganizationChange, :count).by(1)
        expect(SystemNote.last.user).to eq assigned_user
      end

      it "removes the assignee from the tax return" do
        subject.update!
        expect(tax_return.reload.assigned_user).to eq(nil)
      end

      context "and something goes terribly wrong in un-assignment" do
        before do
          allow_any_instance_of(TaxReturn).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        end

        it "raises an exception" do
          expect { subject.update! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "when called without a transaction wrapping it" do
        before do
          allow(BaseService).to receive(:ensure_transaction).and_raise(StandardError, "Service requiring transaction was called without a transaction open")
        end

        it "raises an error" do
          expect { subject.update! }.to raise_error(StandardError, "Service requiring transaction was called without a transaction open")
        end
      end
    end

    context "when the assigned user does have access to the new vita partner" do
      let(:assigned_user) { create :organization_lead_user, organization: current_site.parent_organization }

      it "changes the vita partner" do
        expect { subject.update! }.to change(client, :vita_partner).from(current_site).to(other_site)
      end

      it "leaves the assignee on the return" do
        subject.update!
        expect(tax_return.reload.assigned_user).to eq(assigned_user)
      end
    end
  end
end