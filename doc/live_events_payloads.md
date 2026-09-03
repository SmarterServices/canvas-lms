# Live Event Payloads

Reference for the shape of selected Canvas live events, as emitted by
`Canvas::LiveEvents` (`lib/canvas/live_events.rb`) and published to Kinesis by
the `live_events` gem (`gems/live_events/lib/live_events/client.rb`).

Events covered:

- `enrollment_state_updated`
- `assignment_updated`
- `assignment_override_created`
- `assignment_override_updated`
- `user_updated`
- `course_section_created`
- `course_section_updated`
- `course_created`
- `course_updated`

All of these are fired from ActiveRecord callbacks via
`Canvas::LiveEventsCallbacks.after_create` / `after_update`
(`lib/canvas/live_events_callbacks.rb`). They fire on *every* successful
`create` / `update` of the underlying record regardless of which attributes
changed (the only exception is `enrollment_state_updated`, see below). The
payload is always a snapshot of the record *after* the save; no "old value"
data is included.

## Envelope

Every event is written to Kinesis as a single JSON record:

```json
{
  "attributes": { ...context/metadata... , "event_name": "...", "event_time": "..." },
  "body":       { ...event specific payload... }
}
```

> Downstream (Canvas Data Services / live-events-publish webhooks and SQS) the
> `attributes` object is delivered under the key `metadata`. The field set is
> identical.

Serialisation rules that apply to both `attributes` and `body`:

- **IDs are strings.** `StringifyIds.recursively_stringify_ids` converts every
  Integer value whose key ends in `id` (`id`, `*_id`) or `*_ids` to a string.
  Most IDs are *global* IDs (shard-prefixed, e.g. `"10000000000123"`), but
  a few payloads use local IDs — this is called out per field below.
- **`nil` values are removed** from the body (`payload.compact!`). A field
  documented below may therefore simply be absent rather than `null`.
- **Timestamps** are ISO-8601 UTC. `event_time` has millisecond precision
  (`2026-09-03T11:13:00.123Z`); body timestamps are serialised by Rails with
  `time_precision = 0` (`2026-09-03T11:13:00Z`).
- **Text fields** passed through `LiveEvents.truncate` are cut to
  `Setting live_events_text_max_length` (default 8192 chars) on a word boundary.

### Envelope fields – always present

| Field | Description |
|---|---|
| `event_name` | The event name, e.g. `course_updated`. |
| `event_time` | When the event was emitted (ms precision, UTC). |
| `producer` | Always `"canvas"`. |
| `root_account_id` | Global ID of the root account. |
| `root_account_uuid` | UUID of the root account. |
| `root_account_lti_guid` | LTI GUID of the root account. |

### User-generated events (web request context)

When the record is saved inside an HTTP request, `ApplicationController#setup_live_events_context`
builds the context. Fields (in addition to the always-present ones):

| Field | Present when | Description |
|---|---|---|
| `context_type` | request has a `@context` | `"Course"`, `"Account"`, `"Group"`, `"User"`. |
| `context_id` | request has a `@context` | Global ID of that context. |
| `context_account_id` | request has a `@context` | Global ID of the context's account (or the account itself). |
| `context_sis_source_id` | context has one | SIS ID of the context. |
| `context_role` | request has a context membership | Enrollment role name (e.g. `"TeacherEnrollment"`, custom role name) or membership type. |
| `user_id` | logged-in user | Global ID of the acting user. |
| `user_login` | logged-in user | Pseudonym `unique_id` (login). |
| `user_account_id` | logged-in user | Global ID of the account owning the pseudonym. |
| `user_sis_id` | logged-in user | `sis_user_id` of the pseudonym (may be absent). |
| `time_zone` | logged-in user | User's time zone name. |
| `real_user_id` | masquerading | Global ID of the *real* (masquerading) user; `user_id` is the masqueraded user. |
| `developer_key_id` | API token request | Global ID of the developer key used. |
| `request_id` | always | Canvas request UUID. |
| `session_id` | browser session | Session ID. |
| `hostname` | always | `request.host`. |
| `http_method` | always | `GET`/`POST`/`PUT`/… |
| `user_agent` | header present | User-Agent header. |
| `client_ip` | always | Remote IP. |
| `url` | always | Full request URL. |
| `referrer` | header present | Referer header. |

Example (`course_updated` from the course settings page):

```json
{
  "attributes": {
    "event_name": "course_updated",
    "event_time": "2026-09-03T11:13:00.421Z",
    "producer": "canvas",
    "context_type": "Course",
    "context_id": "10000000000042",
    "context_account_id": "10000000000003",
    "context_sis_source_id": "FALL26-BIO101",
    "context_role": "TeacherEnrollment",
    "root_account_id": "10000000000001",
    "root_account_uuid": "3ItKcWjkVv3A4pC5cQ3tG0h5QNSoJ0zW1S8cX7Zs",
    "root_account_lti_guid": "3ItKcWjkVv3A4pC5cQ3tG0h5QNSoJ0zW1S8cX7Zs:canvas-lms",
    "user_id": "10000000000017",
    "user_login": "jdoe",
    "user_account_id": "10000000000001",
    "user_sis_id": "E00123",
    "time_zone": "America/Chicago",
    "request_id": "7f2a0b8e-2b7c-4a0e-8a20-2c8e4d9f6a11",
    "session_id": "b1e4c2f0a9d84b6e9d3f",
    "hostname": "school.instructure.com",
    "http_method": "PUT",
    "user_agent": "Mozilla/5.0 ...",
    "client_ip": "203.0.113.10",
    "url": "https://school.instructure.com/courses/42",
    "referrer": "https://school.instructure.com/courses/42/settings"
  },
  "body": { ... }
}
```

### System-generated events (background job context)

When the record is saved inside a delayed job (SIS imports, blueprint sync,
enrollment-state recalculation, content migrations, scheduled term rollovers,
etc.) the context comes from `JobLiveEventsContext#live_events_context`
(`config/initializers/job_live_events_context.rb`). **None of the request/user
fields above are present.** Fields:

| Field | Description |
|---|---|
| `event_name`, `event_time`, `producer` | as above |
| `job_id` | Global ID of the delayed job. |
| `job_tag` | Job tag, e.g. `"SIS::CSV::ImportRefactored#process"`, `"EnrollmentState.process_states_for_ids"`, `"MasterCourses::MasterMigration.perform_exports"`. |
| `root_account_id` / `root_account_uuid` / `root_account_lti_guid` | Taken from `Account.default` of the job's shard, **not** necessarily the record's root account. Use `body` fields (e.g. `account_id`, `root_account_id`, `context_id`) to attribute the record. |

```json
{
  "attributes": {
    "event_name": "enrollment_state_updated",
    "event_time": "2026-09-03T02:00:05.017Z",
    "producer": "canvas",
    "job_id": "10000000098765",
    "job_tag": "EnrollmentState.process_states_for_ids",
    "root_account_id": "10000000000001",
    "root_account_uuid": "3ItKcWjkVv3A4pC5cQ3tG0h5QNSoJ0zW1S8cX7Zs",
    "root_account_lti_guid": "3ItKcWjkVv3A4pC5cQ3tG0h5QNSoJ0zW1S8cX7Zs:canvas-lms"
  },
  "body": { ... }
}
```

Distinguishing the two variants: user-generated events carry `request_id`,
`url`, `http_method` and (when authenticated) `user_id`; system-generated events
carry `job_id` and `job_tag`. An API call made with a token still counts as
user-generated (and additionally carries `developer_key_id`).

A few edge cases:

- A record saved during a request *and* later re-saved in a job produces two
  events, one of each kind (e.g. a SIS import creates a course in a job; a
  teacher then renames it in a request).
- Console / rake / other non-request, non-job code paths emit only the
  always-present fields (`LiveEvents.get_context` is `nil`).
- `body` is identical between user- and system-generated variants; only
  `attributes` differ.

---

## `course_created` / `course_updated`

Trigger: any `Course` create/update (`Canvas::LiveEventsCallbacks`). Not fired
for the shard "dummy" course (`local_id == 0`). Typical sources — user: course
settings page, `PUT /api/v1/courses/:id`, publish/conclude buttons; system: SIS
CSV import, blueprint sync, term-date driven `workflow_state` changes, course
copy/content migration, `Course.batch_update` jobs.

Body (`get_course_data`):

| Field | Type | Description |
|---|---|---|
| `course_id` | string | Global course ID. |
| `uuid` | string | Course UUID. |
| `account_id` | string | Global ID of the course's (sub)account. |
| `account_uuid` | string | UUID of that account. |
| `name` | string | Course name. |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |
| `workflow_state` | string | `created`, `claimed` (unpublished), `available` (published), `completed`, `deleted`. |

```json
{
  "course_id": "10000000000042",
  "uuid": "WvAHhY5FINzq5IyRIJybGeiXyFkG3SvHUUr8Xm5T",
  "account_id": "10000000000003",
  "account_uuid": "8c0ZQb2pSEtq0aChZuFnYlKoGpNzF3sYrg2PYdby",
  "name": "Biology 101",
  "created_at": "2026-08-01T14:02:11Z",
  "updated_at": "2026-09-03T11:13:00Z",
  "workflow_state": "available"
}
```

Note: `sis_source_id` is **not** in the body. For user-generated events it may
appear as `attributes.context_sis_source_id` when the request's context is the
course. Also fires when a `syllabus_body` change happens (alongside a separate
`course_syllabus_updated` event).

## `course_section_created` / `course_section_updated`

Trigger: any `CourseSection` create/update. Sources — user: Sections tab,
`POST/PUT /api/v1/courses/:id/sections`, cross-listing UI; system: SIS import,
course creation (default section is created with the course), cross-list /
de-cross-list jobs, course/term date changes that touch the section.

Body (`get_course_section_data`). **All IDs in this payload are local (non
shard-prefixed) IDs**, but still stringified.

| Field | Type | Description |
|---|---|---|
| `course_section_id` | string | Local section ID. |
| `sis_source_id` | string | Section SIS ID. |
| `sis_batch_id` | string | Local ID of the SIS batch that last touched it. |
| `course_id` | string | Local ID of the course it currently belongs to (changes when cross-listed). |
| `root_account_id` | string | Local root account ID. |
| `enrollment_term_id` | string | Local term ID (may be absent). |
| `name` | string | Section name. |
| `default_section` | boolean | Whether this is the course's default section. |
| `accepting_enrollments` | boolean | |
| `can_manually_enroll` | boolean | |
| `start_at` | timestamp | Section start override. |
| `end_at` | timestamp | Section end override. |
| `workflow_state` | string | `active`, `deleted`. |
| `restrict_enrollments_to_section_dates` | boolean | |
| `nonxlist_course_id` | string | Local ID of the *original* course when the section is cross-listed. |
| `stuck_sis_fields` | array of strings | Fields that have been changed in the UI and are protected from SIS overwrite, e.g. `["name","start_at"]`. Serialised as an array. |
| `integration_id` | string | Section integration ID. |

```json
{
  "course_section_id": "77",
  "sis_source_id": "FALL26-BIO101-01",
  "sis_batch_id": "5123",
  "course_id": "42",
  "root_account_id": "1",
  "enrollment_term_id": "12",
  "name": "Biology 101 – Section 01",
  "default_section": true,
  "accepting_enrollments": true,
  "can_manually_enroll": true,
  "start_at": "2026-08-24T05:00:00Z",
  "end_at": "2026-12-18T05:59:59Z",
  "workflow_state": "active",
  "restrict_enrollments_to_section_dates": false,
  "stuck_sis_fields": [],
  "integration_id": "ext-1234"
}
```

## `user_updated`

Trigger: any `User` update. Not fired for cross-shard shadow records. Sources —
user: profile / settings page, `PUT /api/v1/users/:id`, avatar changes, the
user's own `updated_at` being touched by many actions (e.g. login updates
`last_logged_in`, preference changes); system: SIS import, account-level merge
/ delete jobs, `users_bulk_updated` (fired from `Attachment.batch_destroy` when
a deleted file was the user's avatar and `avatar_image_url` is cleared).

Body (`get_user_data`):

| Field | Type | Description |
|---|---|---|
| `user_id` | string | Global user ID. |
| `uuid` | string | User UUID. |
| `name` | string | Full name. |
| `short_name` | string | Display name. |
| `workflow_state` | string | `pre_registered`, `pending_approval`, `creation_pending`, `registered`, `deleted`. |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |
| `user_login` | string | `unique_id` of the user's primary/SIS pseudonym (`SisPseudonym.for(user, nil, type: :implicit, require_sis: false)`). Absent if the user has no pseudonym. |
| `user_sis_id` | string | `sis_user_id` of that pseudonym. Absent if none. |

```json
{
  "user_id": "10000000000017",
  "uuid": "ipdHCJ0LaLsEmDnQYzvN0DqQxmmqsNmT1IfhFW4b",
  "name": "Jane Doe",
  "short_name": "Jane",
  "workflow_state": "registered",
  "created_at": "2025-01-10T16:20:00Z",
  "updated_at": "2026-09-03T11:13:00Z",
  "user_login": "jdoe",
  "user_sis_id": "E00123"
}
```

Note: pseudonym (login / SIS ID) changes do not by themselves emit a
`user_updated` event unless the `User` row is also saved; `user_login` /
`user_sis_id` reflect the pseudonym state at the time the user event fires.

## `enrollment_state_updated`

Trigger: an `EnrollmentState` update where something *other than*
`state_is_current`, `lock_version`, or `access_is_current` changed (i.e. one of
`state`, `state_started_at`, `state_valid_until`, `restricted_access`).

`EnrollmentState` is a lazily-recomputed cache of the enrollment's *effective*
state (workflow state + course/section/term dates). It is recalculated:

- **in a request** the next time anything reads the enrollment's state after it
  was invalidated (e.g. a student loading the dashboard after the term
  started) — user-generated context, possibly for a *different* user than the
  enrollment's owner;
- **in a job** by `EnrollmentState.process_states_for_ids` /
  `process_term_states_in_ranges` / `force_recalculation` after course, section
  or term date changes, or when `state_valid_until` passes — system-generated
  context;
- immediately when the parent `Enrollment.workflow_state` changes (concluding,
  deleting, accepting an invitation, SIS import).

Body (`get_enrollment_state_data`):

| Field | Type | Description |
|---|---|---|
| `enrollment_id` | string | Global enrollment ID (this is the only identifier — join to `enrollment_created/updated` for course/user). |
| `state` | string | Effective state: `active`, `invited`, `pending_active`, `pending_invited`, `creation_pending`, `completed`, `inactive`, `rejected`, `deleted`. |
| `state_started_at` | timestamp | When the current state became effective (absent if not date-driven). |
| `state_is_current` | boolean | Whether the cached state is valid. |
| `state_valid_until` | timestamp | When the state will need recomputing (e.g. term end). Absent if open-ended. |
| `restricted_access` | boolean | `true` when the user is locked out (e.g. past course end with "restrict students from viewing course after end date"). |
| `access_is_current` | boolean | Whether `restricted_access` is up to date. |

```json
{
  "enrollment_id": "10000000000901",
  "state": "completed",
  "state_started_at": "2026-12-18T05:59:59Z",
  "state_is_current": true,
  "restricted_access": true,
  "access_is_current": true
}
```

## `assignment_updated`

Trigger: any `Assignment` update. Sources — user: assignment edit page,
`PUT /api/v1/courses/:id/assignments/:id`, publish/unpublish, bulk due date
editor (`assignments_bulk_updated`, run in a job), muting/posting grades,
moving between groups; system: SIS import (assignment integration), blueprint
sync, course copy/import, LTI deep-linking/AGS line item updates, the
"conditional release"/mastery paths pipeline, `updated_at` touches from
submission/grading side effects.

Body (`get_assignment_data`):

| Field | Type | Description |
|---|---|---|
| `assignment_id` | string | Global assignment ID. |
| `assignment_group_id` | string | Global assignment group ID. |
| `assignment_id_duplicated_from` | string | Global ID of the source assignment if this was created via "Duplicate". |
| `context_id` | string | Global ID of the course. |
| `context_type` | string | `"Course"`. |
| `context_uuid` | string | UUID of the course. |
| `created_on_blueprint_sync` | boolean | `true` if the course is a blueprint child course and this assignment was created by a blueprint sync. |
| `title` | string | Assignment name (truncated). |
| `description` | string | HTML description (truncated). |
| `lti_assignment_description` | string | Same value as `description`. |
| `lti_assignment_id` | string | `lti_context_id` — the stable UUID used in LTI launches/AGS. |
| `lti_resource_link_id` | string | LTI resource link ID, if the assignment is an external-tool assignment. |
| `lti_resource_link_id_duplicated_from` | string | Resource link ID of the duplicated-from assignment. |
| `due_at` | timestamp | Base (non-override) due date. |
| `unlock_at` | timestamp | |
| `lock_at` | timestamp | |
| `points_possible` | number | Float (e.g. `100.0`). |
| `submission_types` | string | Comma-separated: `online_text_entry,online_upload`, `external_tool`, `none`, `on_paper`, `discussion_topic`, `online_quiz`, etc. |
| `workflow_state` | string | `published`, `unpublished`, `duplicating`, `failed_to_duplicate`, `importing`, `fail_to_import`, `migrating`, `failed_to_migrate`, `outcome_alignment_cloning`, `failed_to_clone_outcome_alignment`, `deleted`. |
| `anonymous_grading` | boolean | |
| `anonymous_participants` | boolean | `true` for anonymous peer review / anonymous discussion assignments. |
| `resource_map` | string | URL of the content-migration asset map when the assignment was created via import (used by New Quizzes). |
| `updated_at` | timestamp | |
| `domain` | string | Canvas domain of the root account (e.g. `school.instructure.com`). Present when resolvable. |
| `domain_duplicated_from` | string | Domain of the source assignment's root account (duplicates only). |
| `associated_integration_id` | string | GUID of the LTI 2 tool proxy (e.g. plagiarism platform) associated via `assignment_configuration_tool_lookups`. |

```json
{
  "assignment_id": "10000000005150",
  "assignment_group_id": "10000000000310",
  "context_id": "10000000000042",
  "context_type": "Course",
  "context_uuid": "WvAHhY5FINzq5IyRIJybGeiXyFkG3SvHUUr8Xm5T",
  "created_on_blueprint_sync": false,
  "title": "Midterm Exam",
  "description": "<p>Proctored midterm.</p>",
  "lti_assignment_description": "<p>Proctored midterm.</p>",
  "lti_assignment_id": "8b1d7a26-3c1e-4f39-9d1a-0f0e5d9b2f7c",
  "lti_resource_link_id": "e3f8d5a0c4b7a1d2e6f9b8c7d6a5e4f3c2b1a0d9",
  "due_at": "2026-10-15T04:59:59Z",
  "unlock_at": "2026-10-08T05:00:00Z",
  "lock_at": "2026-10-16T04:59:59Z",
  "points_possible": 100.0,
  "submission_types": "external_tool",
  "workflow_state": "published",
  "anonymous_grading": false,
  "anonymous_participants": false,
  "updated_at": "2026-09-03T11:13:00Z",
  "domain": "school.instructure.com"
}
```

## `assignment_override_created` / `assignment_override_updated`

Trigger: any `AssignmentOverride` create/update. Overrides are per-section,
per-group, per-course, or ad-hoc (per-student list) date overrides on an
assignment (or quiz/discussion/page). Sources — user: "Assign to" UI on the
assignment edit page, `POST/PUT /api/v1/courses/:id/assignments/:id/overrides`,
differentiation tray; system: blueprint sync, course import, bulk due-date
job, SIS-driven section changes, soft-delete of overrides when a section is
deleted.

Body (`get_assignment_override_data`). **All IDs in this payload are local
IDs**, stringified.

| Field | Type | Description |
|---|---|---|
| `assignment_override_id` | string | Local override ID. |
| `assignment_id` | string | Local assignment ID. Absent for overrides on quizzes/discussions/pages that are not backed by an assignment. |
| `type` | string | `set_type`: `CourseSection`, `Group`, `ADHOC`, `Course`, `Noop`. |
| `course_section_id` | string | Local section ID — only when `type == "CourseSection"`. |
| `group_id` | string | Local group ID — only when `type == "Group"`. |
| `due_at` | timestamp | Override due date (absent if the override does not override due_at). |
| `all_day` | boolean | Whether `due_at` is an all-day date. |
| `all_day_date` | date | `YYYY-MM-DD` date part of `due_at`. |
| `unlock_at` | timestamp | |
| `lock_at` | timestamp | |
| `workflow_state` | string | `active`, `deleted`. |

For `ADHOC` overrides the individual student IDs are **not** included; they
live in `assignment_override_students` and are not part of this event.
For `Noop` (mastery paths) and `Course` overrides no target ID is included.

```json
{
  "assignment_override_id": "8812",
  "assignment_id": "5150",
  "type": "CourseSection",
  "course_section_id": "77",
  "due_at": "2026-10-16T04:59:59Z",
  "all_day": true,
  "all_day_date": "2026-10-15",
  "unlock_at": "2026-10-08T05:00:00Z",
  "lock_at": "2026-10-17T04:59:59Z",
  "workflow_state": "active"
}
```

---

## Source of truth

| Event | Body builder | Trigger |
|---|---|---|
| `course_*` | `Canvas::LiveEvents.get_course_data` | `LiveEventsCallbacks` `when Course` |
| `course_section_*` | `Canvas::LiveEvents.get_course_section_data` | `when CourseSection` |
| `user_updated` | `Canvas::LiveEvents.get_user_data` | `when User` |
| `enrollment_state_updated` | `Canvas::LiveEvents.get_enrollment_state_data` | `when EnrollmentState` (filtered) |
| `assignment_updated` | `Canvas::LiveEvents.get_assignment_data` | `when Assignment` |
| `assignment_override_*` | `Canvas::LiveEvents.get_assignment_override_data` | `when AssignmentOverride` |
| envelope (request) | `ApplicationController#setup_live_events_context` | `around_action :manage_live_events_context` |
| envelope (job) | `JobLiveEventsContext#live_events_context` | `config/initializers/delayed_job.rb` |
| envelope (wire) | `LiveEvents::Client#post_event` | |
