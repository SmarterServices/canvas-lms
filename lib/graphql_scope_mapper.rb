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

# Maps GraphQL object type names (their +graphql_name+, e.g. "User", "Course")
# to the REST API "resource" that grants access to the equivalent data.
#
# The resource symbols correspond to the +:resource+ values produced by
# +TokenScopes.named_scopes+, which come from
# +ApiScopeMapper.lookup_resource(controller, action)+ (see
# +lib/base/api_scope_mapper_fallback.rb+). Because Canvas names its REST
# resources after the pluralized model ("users", "courses", "assignment_groups",
# ...) and its GraphQL types after the singular ("User", "Course",
# "AssignmentGroup", ...), most mappings can be derived automatically:
# underscore + pluralize the type name and keep it only when the result is an
# actual REST resource. +TokenScopes.named_scopes+ is the source of truth for
# which resources exist, so the mapping stays in sync as API routes change, and
# the required scope strings are always drawn from the same source the tokens
# are built from.
#
# +OVERRIDES+ covers the types whose +graphql_name+ does not pluralize to their
# REST resource. Keep it small and verified -- an entry pointing at a resource
# that does not exist simply yields no scopes (and therefore a denial).
#
# Enforcement remains deny-by-default / fail-closed: any type that does not
# resolve to a known resource here is treated as forbidden by the caller
# (+AuthenticationMethods.graphql_type_authorized?+).
module GraphQLScopeMapper
  # GraphQL type name => REST resource symbol(s). Only needed where
  # +underscore.pluralize+ does not already match the REST resource.
  OVERRIDES = {
    "Discussion" => :discussion_topics,
  }.freeze

  class << self
    # Returns the REST resource symbol(s) mapped to the given GraphQL type name,
    # or an empty array when the type does not map to a known REST resource.
    def resources_for_type(type_name)
      return Array(OVERRIDES[type_name]) if OVERRIDES.key?(type_name)

      candidate = derived_resource(type_name)
      return [] unless candidate && known_resources.include?(candidate)

      [candidate]
    end

    # Returns the concrete REST scope strings (e.g. "url:GET|/api/v1/users") that
    # grant access to the resource(s) mapped to +type_name+ for the given HTTP
    # +verb+. Returns an empty array when the type is not mapped or no matching
    # scope exists.
    def scopes_for_type(type_name, verb: "GET")
      resources = resources_for_type(type_name)
      return [] if resources.empty?

      TokenScopes.named_scopes.filter_map do |scope|
        scope[:scope] if resources.include?(scope[:resource]) && scope[:verb] == verb
      end
    end

    private

    # The set of REST resource symbols that actually exist, taken from the API
    # routes captured by TokenScopes. Memoized per process.
    def known_resources
      @known_resources ||= TokenScopes.named_scopes.to_set { |scope| scope[:resource] }
    end

    def derived_resource(type_name)
      return nil if type_name.blank?

      type_name.underscore.pluralize.to_sym
    end
  end
end
