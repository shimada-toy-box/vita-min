require 'rails_helper'

RSpec.describe IntercomService do
  let(:fake_intercom) { instance_double(Intercom::Client) }
  let(:client) { create(:client, intake: create(:intake, email_address: "beep@example.com")) }

  before do
    allow(EnvironmentCredentials).to receive(:dig).with(:intercom, :intercom_access_token).and_return("fake_access_token")
    allow(Intercom::Client).to receive(:new).with(token: "fake_access_token").and_return(fake_intercom)
  end

  describe "#create_intercom_message_from_email" do
    let(:incoming_email) { create :incoming_email, client: client, stripped_text: "hi i would like some help", sender: "beep@example.com" }

    context "with no existing contact with email" do
      before do
        allow(described_class).to receive(:contact_id_from_email).with(incoming_email.sender).and_return(nil)
        allow(described_class).to receive(:contact_id_from_client_id).with(client.id).and_return(nil)
        allow(fake_intercom).to receive_message_chain(:contacts, :create, :id).and_return("fake_new_contact_id")
        allow(described_class).to receive(:create_new_intercom_thread).with("fake_new_contact_id", incoming_email.body)
        allow(ClientMessagingService).to receive(:send_system_email)
      end

      it "creates a new contact, message and conversation for email, and sends forwarding message" do
        described_class.create_intercom_message_from_email(incoming_email, inform_of_handoff: true)
        expect(described_class).to have_received(:create_new_intercom_thread).with("fake_new_contact_id", "hi i would like some help")
        expect(ClientMessagingService).to have_received(:send_system_email).once
      end
    end

    context "with existing contact and conversation associated with email in intercom" do
      before do
        allow(described_class).to receive(:contact_id_from_email).with(incoming_email.sender).and_return("fak3_1d")
        allow(described_class).to receive(:most_recent_conversation).with("fak3_1d").and_return("fake_convo_id")
        allow(described_class).to receive(:reply_to_existing_intercom_thread).with("fak3_1d", incoming_email.body)
      end

      it "replies to the contacts' conversation thread" do
        described_class.create_intercom_message_from_email(incoming_email, inform_of_handoff: true)
        expect(described_class).to have_received(:reply_to_existing_intercom_thread).with("fak3_1d", "hi i would like some help")
      end
    end

    context "with existing contact but no conversation associated with email in intercom" do
      before do
        allow(described_class).to receive(:contact_id_from_email).with(incoming_email.sender).and_return("fak3_1d")
        allow(described_class).to receive(:most_recent_conversation).with("fak3_1d").and_return(nil)
        allow(described_class).to receive(:create_new_intercom_thread).with("fak3_1d", incoming_email.body)
      end

      it "creates a new message for existing contact" do
        described_class.create_intercom_message_from_email(incoming_email, inform_of_handoff: true)
        expect(described_class).to have_received(:create_new_intercom_thread).with("fak3_1d", "hi i would like some help")
      end
    end
  end

  describe "#create_intercom_message_from_sms" do
    let(:incoming_text_message) { create :incoming_text_message, from_phone_number: "+14152515239", client: client, body: "halp" }

    context "with no existing contact with phone number" do
      before do
        allow(described_class).to receive(:contact_id_from_sms).with("+14152515239").and_return(nil)
        allow(described_class).to receive_message_chain(:create_or_update_intercom_contact, :id).and_return("fake_new_contact_id")
        allow(described_class).to receive(:create_new_intercom_thread).with("fake_new_contact_id", incoming_text_message.body)
        allow(ClientMessagingService).to receive(:send_system_text_message)
      end

      it "creates a new contact, message and conversation for phone number, and sends forwarding message" do
        described_class.create_intercom_message_from_sms(incoming_text_message, inform_of_handoff: true)
        expect(described_class).to have_received(:create_new_intercom_thread).with("fake_new_contact_id", "halp")
        expect(ClientMessagingService).to have_received(:send_system_text_message).once
      end
    end

    context "with an existing contact and conversation for phone number" do
      before do
        allow(described_class).to receive(:contact_id_from_sms).with(incoming_text_message.from_phone_number).and_return("fake_existing_contact_id")
        allow(described_class).to receive(:most_recent_conversation).with("fake_existing_contact_id").and_return("fake_convo")
        allow(described_class).to receive(:reply_to_existing_intercom_thread).with("fake_existing_contact_id", incoming_text_message.body)
      end

      it "replies to the existing thread for phone number" do
        described_class.create_intercom_message_from_sms(incoming_text_message, inform_of_handoff: true)
        expect(described_class).to have_received(:reply_to_existing_intercom_thread).with("fake_existing_contact_id", "halp")
      end
    end
  end
end