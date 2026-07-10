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
# to the REST API scopes that grant access to the equivalent data.
#
# Rather than hand-maintaining a table, mappings are derived from
# +TokenScopes.named_scopes+ (the source of truth the tokens themselves are
# built from) by looking at each scope's URL *path*. Canvas names its GraphQL
# types after the singular resource ("User", "Course", "AssignmentGroup", ...)
# and exposes that resource under a REST collection path whose final segment is
# the pluralized name ("/users", "/courses", "/assignment_groups", ...). So a
# type maps to exactly the scopes whose path's terminal collection segment (the
# last non-parameter segment) equals +type_name.underscore.pluralize+.
#
# Matching on the path rather than the controller/resource name has two
# benefits:
#
#   * it is environment-independent -- routes are identical whether the
#     generated +ApiScopeMapper+ or the fallback is in use, whereas the
#     +:resource+ symbol is a controller name that can be namespaced
#     (e.g. +:"quizzes/quizzes_api"+) and differ between the two; and
#   * it covers types served by namespaced controllers (Quiz, Module, Page, ...)
#     that a naive controller-name match would miss.
#
# Because a scope is only matched when it *reads that exact collection*, the
# mapping does not leak across types (holding a +courses+ scope never grants the
# +User+ type, etc.).
#
# +SEGMENT_OVERRIDES+ covers the few types whose +graphql_name+ does not
# pluralize to their REST path segment. Keep it small and verified -- an entry
# pointing at a segment that no route uses simply yields no scopes (a denial).
#
# Enforcement remains deny-by-default / fail-closed: any type that resolves to
# no scopes here is treated as forbidden by the caller
# (+AuthenticationMethods.graphql_type_authorized?+).
module GraphQLScopeMapper
  # GraphQL type name => REST path collection segment. Only needed where
  # +underscore.pluralize+ does not already match the path segment that reads
  # the resource.
  SEGMENT_OVERRIDES = {
    "Discussion" => "discussion_topics",
  }.freeze

  class << self
    # Returns the concrete REST scope strings (e.g. "url:GET|/api/v1/users") that
    # grant read access to +type_name+ for the given HTTP +verb+. Returns an
    # empty array when the type maps to no known collection or no matching scope
    # exists.
    def scopes_for_type(type_name, verb: "GET")
      segment = segment_for_type(type_name)
      return [] if segment.nil?

      TokenScopes.named_scopes.filter_map do |scope|
        next unless scope[:verb] == verb

        scope[:scope] if collection_segment(scope[:path]) == segment
      end
    end

    # Returns the REST resource symbol(s) backing +type_name+ for the given
    # +verb+. Purely informational (introspection/specs); enforcement uses
    # +scopes_for_type+. Empty when the type does not map.
    def resources_for_type(type_name, verb: "GET")
      segment = segment_for_type(type_name)
      return [] if segment.nil?

      TokenScopes.named_scopes.filter_map do |scope|
        next unless scope[:verb] == verb

        scope[:resource] if collection_segment(scope[:path]) == segment
      end.uniq
    end

    # The REST collection path segment that reads +type_name+, or nil when the
    # type name is blank.
    def segment_for_type(type_name)
      return nil if type_name.blank?

      SEGMENT_OVERRIDES[type_name] || type_name.underscore.pluralize
    end

    private

    # The final non-parameter segment of a REST path -- the collection being
    # acted on. e.g. "/api/v1/courses/:course_id/quizzes" => "quizzes",
    # "/api/v1/users/:id" => "users". Nil for scopes without a URL path
    # (e.g. the OAuth userinfo scope).
    def collection_segment(path)
      return nil if path.blank?

      path.split("/").reject { |segment| segment.blank? || segment.start_with?(":") }.last
    end
  end
end
