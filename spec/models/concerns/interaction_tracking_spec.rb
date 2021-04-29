require 'rails_helper'

describe InteractionTracking do
  let(:example_subclass) do
    Class.new do
      include InteractionTracking

      def initialize(client)
        @client = client
      end

      def client
        @client
      end
    end
  end

  let(:instance) { example_subclass.new(client) }
  let(:client) { create(:client) }
  let(:fake_time) { Time.utc(2021, 2, 6, 0, 0, 0) }

  context ".record_outgoing_interaction" do
    it "updates Client.last_outgoing_interaction_at" do
      Timecop.freeze(fake_time) do
        expect { instance.record_outgoing_interaction }.to change { client.last_outgoing_interaction_at }.from(nil).to(fake_time)
      end
    end
  end
end
