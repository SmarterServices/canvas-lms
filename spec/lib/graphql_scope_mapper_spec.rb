# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe GraphQLScopeMapper do
  let(:known_resources) { TokenScopes.named_scopes.pluck(:resource).uniq }

  describe ".resources_for_type" do
    it "auto-derives the resource for conventionally named types" do
      expect(described_class.resources_for_type("User")).to eq [:users]
      expect(described_class.resources_for_type("Course")).to eq [:courses]
      expect(described_class.resources_for_type("Section")).to eq [:sections]
      expect(described_class.resources_for_type("Account")).to eq [:accounts]
    end

    it "derives multi-word resources" do
      expect(described_class.resources_for_type("AssignmentGroup")).to eq [:assignment_groups]
      expect(described_class.resources_for_type("GroupMembership")).to eq [:group_memberships]
    end

    it "applies OVERRIDES for types that do not pluralize to their resource" do
      expect(described_class.resources_for_type("Discussion")).to eq [:discussion_topics]
    end

    it "only ever maps to resources that actually exist in TokenScopes" do
      %w[User Course Section Account AssignmentGroup GroupMembership Discussion Group].each do |type|
        described_class.resources_for_type(type).each do |resource|
          expect(known_resources).to include(resource)
        end
      end
    end

    it "returns an empty array for a type with no matching resource (deny-by-default)" do
      expect(described_class.resources_for_type("CoursePermissions")).to eq []
      expect(described_class.resources_for_type("NotARealType")).to eq []
    end

    it "returns an empty array for a blank type name" do
      expect(described_class.resources_for_type(nil)).to eq []
      expect(described_class.resources_for_type("")).to eq []
    end
  end

  describe ".scopes_for_type" do
    it "returns the REST GET scope strings for a mapped type" do
      scopes = described_class.scopes_for_type("User", verb: "GET")
      expect(scopes).not_to be_empty
      expect(scopes).to all(start_with("url:GET|"))
    end

    it "only returns scopes belonging to the mapped resource and verb" do
      scopes = described_class.scopes_for_type("User", verb: "GET")
      users_get_scopes = TokenScopes.named_scopes.select { |s| s[:resource] == :users && s[:verb] == "GET" }.pluck(:scope)
      expect(scopes).to match_array(users_get_scopes)
    end

    it "honors the requested verb" do
      get_scopes = described_class.scopes_for_type("User", verb: "GET")
      post_scopes = described_class.scopes_for_type("User", verb: "POST")
      expect(get_scopes).not_to match_array(post_scopes)
      post_from_source = TokenScopes.named_scopes.select { |s| s[:resource] == :users && s[:verb] == "POST" }.pluck(:scope)
      expect(post_scopes).to match_array(post_from_source)
    end

    it "returns an empty array for an unmapped type (deny-by-default)" do
      expect(described_class.scopes_for_type("CoursePermissions", verb: "GET")).to eq []
      expect(described_class.scopes_for_type("NotARealType", verb: "GET")).to eq []
    end
  end
end
