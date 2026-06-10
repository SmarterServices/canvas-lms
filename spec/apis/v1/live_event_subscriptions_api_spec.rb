# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require_relative "../api_spec_helper"

describe LiveEventSubscriptionsController, type: :request do
  let(:root_account) { Account.default }
  let(:admin) { account_admin_user(account: root_account, active_all: true) }
  let(:sub_account) { root_account.sub_accounts.create!(name: "Sub Account") }

  let(:sample_subscription) do
    {
      "Id" => "71d6dfba-0547-477d-b41d-db8cb528c6d1",
      "ContextId" => root_account.global_id.to_s,
      "ContextType" => "root_account",
      "EventTypes" => ["course_created", "enrollment_created"],
      "Format" => "live-event",
      "TransportType" => "sqs",
      "TransportMetadata" => { "Url" => "https://sqs.us-east-1.amazonaws.com/123456789012/my-queue" },
      "State" => "Active",
      "aws_access_key_id" => "AKIAIOSFODNN7EXAMPLE",
      "aws_secret_access_key" => "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    }
  end

  let(:service_response) do
    instance_double(HTTParty::Response, body: [sample_subscription].to_json, code: 200)
  end

  let(:show_service_response) do
    instance_double(HTTParty::Response, body: sample_subscription.to_json, code: 200)
  end

  before do
    allow(DynamicSettings).to receive(:find).and_call_original
    allow(DynamicSettings).to receive(:find)
      .with("live-events-subscription-service", default_ttl: 5.minutes)
      .and_return({ "app-host" => "http://live-event-service" })
    allow(CanvasSecurity::ServicesJwt).to receive_messages(
      encryption_secret: "setecastronomy92" * 2,
      signing_secret: "donttell" * 10
    )
  end

  describe "GET /api/v1/accounts/:account_id/live_event_subscriptions (index)" do
    def api_list_subscriptions(account = root_account, opts = {})
      api_call(:get,
               "/api/v1/accounts/#{account.id}/live_event_subscriptions",
               { controller: "live_event_subscriptions",
                 action: "index",
                 format: "json",
                 account_id: account.id.to_s },
               {},
               {},
               opts)
    end

    context "as an account admin" do
      before do
        user_session(admin)
        allow(HTTParty).to receive(:send).and_return(service_response)
      end

      it "returns subscriptions for the root account" do
        json = api_list_subscriptions
        expect(json).to be_an(Array)
        expect(json.length).to eq(1)
        expect(json.first["Id"]).to eq("71d6dfba-0547-477d-b41d-db8cb528c6d1")
        expect(json.first["EventTypes"]).to eq(["course_created", "enrollment_created"])
      end

      it "masks sensitive fields" do
        json = api_list_subscriptions
        sub = json.first
        expect(sub["aws_access_key_id"]).to eq("AK******LE")
        expect(sub["aws_secret_access_key"]).to eq("wJ******EY")
      end

      it "does not mask non-sensitive fields" do
        json = api_list_subscriptions
        sub = json.first
        expect(sub["TransportType"]).to eq("sqs")
        expect(sub["Format"]).to eq("live-event")
        expect(sub["State"]).to eq("Active")
        expect(sub["TransportMetadata"]["Url"]).to eq("https://sqs.us-east-1.amazonaws.com/123456789012/my-queue")
      end

      it "rejects sub-account requests with 400" do
        sub_account_admin = account_admin_user(account: sub_account, active_all: true)
        user_session(sub_account_admin)
        raw_api_call(:get,
                     "/api/v1/accounts/#{sub_account.id}/live_event_subscriptions",
                     { controller: "live_event_subscriptions",
                       action: "index",
                       format: "json",
                       account_id: sub_account.id.to_s })
        assert_status(400)
      end
    end

    context "as a non-admin user" do
      let(:regular_user) { user_model }

      before do
        user_session(regular_user)
      end

      it "returns 401 unauthorized" do
        raw_api_call(:get,
                     "/api/v1/accounts/#{root_account.id}/live_event_subscriptions",
                     { controller: "live_event_subscriptions",
                       action: "index",
                       format: "json",
                       account_id: root_account.id.to_s })
        assert_status(401)
      end
    end

    context "when service is not configured" do
      before do
        user_session(admin)
        allow(DynamicSettings).to receive(:find)
          .with("live-events-subscription-service", default_ttl: 5.minutes)
          .and_return({})
      end

      it "returns 503 service unavailable" do
        raw_api_call(:get,
                     "/api/v1/accounts/#{root_account.id}/live_event_subscriptions",
                     { controller: "live_event_subscriptions",
                       action: "index",
                       format: "json",
                       account_id: root_account.id.to_s })
        assert_status(503)
      end
    end
  end

  describe "GET /api/v1/accounts/:account_id/live_event_subscriptions/:id (show)" do
    let(:subscription_id) { "71d6dfba-0547-477d-b41d-db8cb528c6d1" }

    def api_show_subscription(account = root_account, id = subscription_id, opts = {})
      api_call(:get,
               "/api/v1/accounts/#{account.id}/live_event_subscriptions/#{id}",
               { controller: "live_event_subscriptions",
                 action: "show",
                 format: "json",
                 account_id: account.id.to_s,
                 id: },
               {},
               {},
               opts)
    end

    context "as an account admin" do
      before do
        user_session(admin)
        allow(HTTParty).to receive(:send).and_return(show_service_response)
      end

      it "returns the subscription" do
        json = api_show_subscription
        expect(json["Id"]).to eq(subscription_id)
        expect(json["EventTypes"]).to eq(["course_created", "enrollment_created"])
      end

      it "masks sensitive fields" do
        json = api_show_subscription
        expect(json["aws_access_key_id"]).to eq("AK******LE")
        expect(json["aws_secret_access_key"]).to eq("wJ******EY")
      end

      it "preserves non-sensitive fields" do
        json = api_show_subscription
        expect(json["ContextType"]).to eq("root_account")
        expect(json["TransportType"]).to eq("sqs")
        expect(json["TransportMetadata"]["Url"]).to eq("https://sqs.us-east-1.amazonaws.com/123456789012/my-queue")
      end
    end

    context "as a non-admin user" do
      let(:regular_user) { user_model }

      before do
        user_session(regular_user)
      end

      it "returns 401 unauthorized" do
        raw_api_call(:get,
                     "/api/v1/accounts/#{root_account.id}/live_event_subscriptions/#{subscription_id}",
                     { controller: "live_event_subscriptions",
                       action: "show",
                       format: "json",
                       account_id: root_account.id.to_s,
                       id: subscription_id })
        assert_status(401)
      end
    end
  end

  describe "credential masking" do
    before do
      user_session(admin)
    end

    it "masks keys with only 4 characters by leaving them as-is" do
      controller = LiveEventSubscriptionsController.new
      expect(controller.send(:mask_value, "ABCD")).to eq("ABCD")
    end

    it "masks keys with 5+ characters" do
      controller = LiveEventSubscriptionsController.new
      expect(controller.send(:mask_value, "ABCDE")).to eq("AB******DE")
    end

    it "masks nested sensitive values in hashes" do
      controller = LiveEventSubscriptionsController.new
      input = { "credentials" => { "api_key" => "my-secret-key-123" } }
      result = controller.send(:mask_sensitive_fields, input)
      expect(result["credentials"]).to eq({ "api_key" => "my******23" })
    end

    it "masks sensitive values in arrays" do
      controller = LiveEventSubscriptionsController.new
      input = { "secret_tokens" => ["token-abc-123", "token-xyz-789"] }
      result = controller.send(:mask_sensitive_fields, input)
      expect(result["secret_tokens"]).to eq(["to******23", "to******89"])
    end

    it "handles nil values gracefully" do
      controller = LiveEventSubscriptionsController.new
      expect(controller.send(:mask_value, nil)).to be_nil
    end
  end
end
