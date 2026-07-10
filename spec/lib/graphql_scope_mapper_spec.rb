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
  describe ".resources_for_type" do
    it "returns the mapped resource symbol for a known type" do
      expect(described_class.resources_for_type("User")).to eq [:users]
      expect(described_class.resources_for_type("Course")).to eq [:courses]
    end

    it "returns an empty array for an unmapped type (deny-by-default)" do
      expect(described_class.resources_for_type("Group")).to eq []
      expect(described_class.resources_for_type("NotARealType")).to eq []
    end
  end

  describe ".scopes_for_type" do
    it "returns the REST GET scope strings for a mapped type" do
      scopes = described_class.scopes_for_type("User", verb: "GET")
      expect(scopes).not_to be_empty
      expect(scopes).to all(start_with("url:GET|"))
    end

    it "only returns scopes belonging to the mapped resource" do
      scopes = described_class.scopes_for_type("User", verb: "GET")
      users_scopes = TokenScopes.named_scopes.select { |s| s[:resource] == :users && s[:verb] == "GET" }.pluck(:scope)
      expect(scopes).to match_array(users_scopes)
    end

    it "honors the requested verb" do
      get_scopes = described_class.scopes_for_type("User", verb: "GET")
      post_scopes = described_class.scopes_for_type("User", verb: "POST")
      expect(get_scopes).not_to match_array(post_scopes)
      matching = TokenScopes.named_scopes.select { |s| s[:resource] == :users && s[:verb] == "POST" }.pluck(:scope)
      expect(post_scopes).to match_array(matching)
    end

    it "returns an empty array for an unmapped type (deny-by-default)" do
      expect(described_class.scopes_for_type("Group", verb: "GET")).to eq []
    end
  end
end
