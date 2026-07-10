GraphQL Type Scope Authorization
================================

<!-- GENERATED FILE: do not edit by hand.
     Regenerate with `bundle exec rake graphql:scopes`. -->

When a developer key has `require_scopes` enabled, each GraphQL object
type is authorized against the REST API scopes below (see
[GraphQL API](graphql.html) for the rules). A token must hold at least one
of the listed `GET` scopes to read the type. Types not listed here map to
no scope and are denied (deny-by-default).

This mapping is derived dynamically from `TokenScopes.named_scopes`, so it
reflects the routes present when it was generated.

## Authorized types

### Account

- `url:GET|/api/v1/accounts`
- `url:GET|/api/v1/accounts/:id`
- `url:GET|/api/v1/audit/authentication/accounts/:account_id`
- `url:GET|/api/v1/audit/course/accounts/:account_id`

### AccountNotification

- `url:GET|/api/v1/accounts/:account_id/account_notifications`
- `url:GET|/api/v1/accounts/:account_id/account_notifications/:id`
- `url:GET|/api/v1/accounts/:account_id/users/:user_id/account_notifications`
- `url:GET|/api/v1/accounts/:account_id/users/:user_id/account_notifications/:id`

### Assignment

- `url:GET|/api/sis/accounts/:account_id/assignments`
- `url:GET|/api/sis/courses/:course_id/assignments`
- `url:GET|/api/v1/audit/grade_change/assignments/:assignment_id`
- `url:GET|/api/v1/audit/grade_change/courses/:course_id/assignments/:assignment_id`
- `url:GET|/api/v1/courses/:course_id/assignment_groups/:assignment_group_id/assignments`
- `url:GET|/api/v1/courses/:course_id/assignments`
- `url:GET|/api/v1/courses/:course_id/assignments/:id`
- `url:GET|/api/v1/users/:user_id/courses/:course_id/assignments`

### AssignmentGroup

- `url:GET|/api/v1/courses/:course_id/assignment_groups`
- `url:GET|/api/v1/courses/:course_id/assignment_groups/:assignment_group_id`

### AssignmentOverride

- `url:GET|/api/v1/courses/:course_id/modules/:context_module_id/assignment_overrides`
- `url:GET|/api/v1/courses/:course_id/new_quizzes/assignment_overrides`
- `url:GET|/api/v1/courses/:course_id/quizzes/assignment_overrides`

### CommunicationChannel

- `url:GET|/api/v1/users/:user_id/communication_channels`

### Conversation

- `url:GET|/api/v1/conversations`
- `url:GET|/api/v1/conversations/:id`
- `url:GET|/api/v1/courses/:course_id/ai_experiences/:ai_experience_id/conversations`
- `url:GET|/api/v1/courses/:course_id/ai_experiences/:ai_experience_id/conversations/:id`

### Course

- `url:GET|/api/v1/accounts/:account_id/courses`
- `url:GET|/api/v1/accounts/:account_id/courses/:id`
- `url:GET|/api/v1/audit/course/courses/:course_id`
- `url:GET|/api/v1/audit/grade_change/courses/:course_id`
- `url:GET|/api/v1/courses`
- `url:GET|/api/v1/courses/:id`
- `url:GET|/api/v1/users/:user_id/courses`
- `url:GET|/api/v1/users/self/favorites/courses`

### Discussion

- `url:GET|/api/v1/courses/:course_id/discussion_topics`
- `url:GET|/api/v1/courses/:course_id/discussion_topics/:topic_id`
- `url:GET|/api/v1/groups/:group_id/discussion_topics`
- `url:GET|/api/v1/groups/:group_id/discussion_topics/:topic_id`

### Enrollment

- `url:GET|/api/v1/accounts/:account_id/enrollments/:id`
- `url:GET|/api/v1/courses/:course_id/enrollments`
- `url:GET|/api/v1/sections/:section_id/enrollments`
- `url:GET|/api/v1/users/:user_id/enrollments`

### ExternalTool

- `url:GET|/api/v1/accounts/:account_id/external_tools`
- `url:GET|/api/v1/accounts/:account_id/external_tools/:external_tool_id`
- `url:GET|/api/v1/courses/:course_id/external_tools`
- `url:GET|/api/v1/courses/:course_id/external_tools/:external_tool_id`
- `url:GET|/api/v1/groups/:group_id/external_tools`

### File

- `url:GET|/api/v1/courses/:course_id/files`
- `url:GET|/api/v1/courses/:course_id/files/:id`
- `url:GET|/api/v1/files/:id`
- `url:GET|/api/v1/folders/:id/files`
- `url:GET|/api/v1/groups/:group_id/files`
- `url:GET|/api/v1/groups/:group_id/files/:id`
- `url:GET|/api/v1/users/:user_id/files`
- `url:GET|/api/v1/users/:user_id/files/:id`

### Folder

- `url:GET|/api/v1/courses/:course_id/folders`
- `url:GET|/api/v1/courses/:course_id/folders/:id`
- `url:GET|/api/v1/folders/:id`
- `url:GET|/api/v1/folders/:id/folders`
- `url:GET|/api/v1/groups/:group_id/folders`
- `url:GET|/api/v1/groups/:group_id/folders/:id`
- `url:GET|/api/v1/users/:user_id/folders`
- `url:GET|/api/v1/users/:user_id/folders/:id`

### GradingPeriod

- `url:GET|/api/v1/accounts/:account_id/grading_periods`
- `url:GET|/api/v1/courses/:course_id/grading_periods`
- `url:GET|/api/v1/courses/:course_id/grading_periods/:id`

### GradingStandard

- `url:GET|/api/v1/accounts/:account_id/grading_standards`
- `url:GET|/api/v1/accounts/:account_id/grading_standards/:grading_standard_id`
- `url:GET|/api/v1/courses/:course_id/grading_standards`
- `url:GET|/api/v1/courses/:course_id/grading_standards/:grading_standard_id`

### Group

- `url:GET|/api/v1/accounts/:account_id/groups`
- `url:GET|/api/v1/appointment_groups/:id/groups`
- `url:GET|/api/v1/courses/:course_id/groups`
- `url:GET|/api/v1/courses/:course_id/quizzes/:quiz_id/groups`
- `url:GET|/api/v1/courses/:course_id/quizzes/:quiz_id/groups/:id`
- `url:GET|/api/v1/group_categories/:group_category_id/groups`
- `url:GET|/api/v1/groups/:group_id`
- `url:GET|/api/v1/permissions/groups`
- `url:GET|/api/v1/users/self/favorites/groups`
- `url:GET|/api/v1/users/self/groups`

### MediaObject

- `url:GET|/api/v1/courses/:course_id/media_objects`
- `url:GET|/api/v1/groups/:group_id/media_objects`
- `url:GET|/api/v1/media_objects`

### MediaTrack

- `url:GET|/api/v1/media_attachments/:attachment_id/media_tracks`
- `url:GET|/api/v1/media_objects/:media_object_id/media_tracks`

### MessageableUser

- `url:GET|/api/v1/courses/:course_id/discussion_topics/:topic_id/messageable_users`
- `url:GET|/api/v1/groups/:group_id/discussion_topics/:topic_id/messageable_users`

### Module

- `url:GET|/api/v1/courses/:course_id/modules`
- `url:GET|/api/v1/courses/:course_id/modules/:id`

### NotificationPreferences

- `url:GET|/api/v1/users/:user_id/communication_channels/:communication_channel_id/notification_preferences`
- `url:GET|/api/v1/users/:user_id/communication_channels/:communication_channel_id/notification_preferences/:notification`
- `url:GET|/api/v1/users/:user_id/communication_channels/:type/:address/notification_preferences`
- `url:GET|/api/v1/users/:user_id/communication_channels/:type/:address/notification_preferences/:notification`

### OutcomeAlignment

- `url:GET|/api/v1/courses/:course_id/outcome_alignments`

### Page

- `url:GET|/api/v1/courses/:course_id/pages`
- `url:GET|/api/v1/courses/:course_id/pages/:url_or_id`
- `url:GET|/api/v1/eportfolios/:eportfolio_id/pages`
- `url:GET|/api/v1/groups/:group_id/pages`
- `url:GET|/api/v1/groups/:group_id/pages/:url_or_id`

### PeerReviews

- `url:GET|/api/v1/courses/:course_id/assignments/:assignment_id/peer_reviews`
- `url:GET|/api/v1/courses/:course_id/assignments/:assignment_id/submissions/:submission_id/peer_reviews`
- `url:GET|/api/v1/sections/:section_id/assignments/:assignment_id/peer_reviews`
- `url:GET|/api/v1/sections/:section_id/assignments/:assignment_id/submissions/:submission_id/peer_reviews`

### Quiz

- `url:GET|/api/v1/courses/:course_id/quizzes`
- `url:GET|/api/v1/courses/:course_id/quizzes/:id`

### Recipients

- `url:GET|/api/v1/search/recipients`

### Rubric

- `url:GET|/api/v1/accounts/:account_id/rubrics`
- `url:GET|/api/v1/accounts/:account_id/rubrics/:id`
- `url:GET|/api/v1/accounts/:account_id/rubrics/upload/:id/rubrics`
- `url:GET|/api/v1/courses/:course_id/rubrics`
- `url:GET|/api/v1/courses/:course_id/rubrics/:id`
- `url:GET|/api/v1/courses/:course_id/rubrics/upload/:id/rubrics`
- `url:GET|/api/v1/search/rubrics`

### Section

- `url:GET|/api/v1/courses/:course_id/sections`
- `url:GET|/api/v1/courses/:course_id/sections/:id`
- `url:GET|/api/v1/sections/:id`

### Submission

- `url:GET|/api/v1/courses/:course_id/assignments/:assignment_id/submissions`
- `url:GET|/api/v1/courses/:course_id/assignments/:assignment_id/submissions/:user_id`
- `url:GET|/api/v1/courses/:course_id/gradebook_history/:date/graders/:grader_id/assignments/:assignment_id/submissions`
- `url:GET|/api/v1/courses/:course_id/quizzes/:quiz_id/submissions`
- `url:GET|/api/v1/courses/:course_id/quizzes/:quiz_id/submissions/:id`
- `url:GET|/api/v1/courses/:course_id/students/submissions`
- `url:GET|/api/v1/sections/:section_id/assignments/:assignment_id/submissions`
- `url:GET|/api/v1/sections/:section_id/assignments/:assignment_id/submissions/:user_id`
- `url:GET|/api/v1/sections/:section_id/students/submissions`

### Term

- `url:GET|/api/v1/accounts/:account_id/terms`
- `url:GET|/api/v1/accounts/:account_id/terms/:id`

### User

- `url:GET|/api/v1/accounts/:account_id/users`
- `url:GET|/api/v1/appointment_groups/:id/users`
- `url:GET|/api/v1/audit/authentication/users/:user_id`
- `url:GET|/api/v1/courses/:course_id/users`
- `url:GET|/api/v1/courses/:course_id/users/:id`
- `url:GET|/api/v1/group_categories/:group_category_id/users`
- `url:GET|/api/v1/groups/:group_id/users`
- `url:GET|/api/v1/groups/:group_id/users/:user_id`
- `url:GET|/api/v1/sections/:id/users`
- `url:GET|/api/v1/users/:id`

## Types with no scope mapping (denied under require_scopes)

`AIGradeCriterionResult`, `AIGradeRating`, `AIGradeResult`, `ActivityStream`, `AdhocStudents`, `AllocationRule`, `AnonymousStudentIdentity`, `AnonymousUser`, `AssessmentRequest`, `AssignmentAllocationRules`, `AssignmentGroupRules`, `AssignmentRubricAssessment`, `AssignmentScoreStatistic`, `AuditEvent`, `AuditEventExternalTool`, `AuditEventQuiz`, `AuditEventUser`, `AuditLogs`, `AutoGradeEligibility`, `AutoGradeIssue`, `Checkpoint`, `CommentBankItem`, `ConversationMessage`, `ConversationParticipant`, `CourseDashboardCard`, `CourseDashboardCardLink`, `CourseOutcomeAlignmentStats`, `CoursePermissions`, `CourseProgression`, `CourseRequirements`, `CourseSettings`, `CustomGradeStatus`, `DateHash`, `DateHashSet`, `DiscussionEntry`, `DiscussionEntryCounts`, `DiscussionEntryPermissions`, `DiscussionEntryReportTypeCounts`, `DiscussionEntryVersion`, `DiscussionParticipant`, `DiscussionPermissions`, `EligibilityIssue`, `EnrollmentRole`, `EntryParticipant`, `ExternalToolPlacements`, `ExternalToolSettings`, `ExternalUrl`, `GraderIdentity`, `Grades`, `GradingPeriodGroup`, `GradingStandardItem`, `GroupMembership`, `GroupSet`, `InboxSettings`, `InstitutionalTag`, `InstitutionalTagAssociation`, `InstitutionalTagCategory`, `InstructorCourseInfo`, `InstructorEnrollmentInfo`, `InstructorUserInfo`, `InstructorWithEnrollments`, `InternalSetting`, `LearningOutcome`, `LearningOutcomeGroup`, `LockInfo`, `LtiAsset`, `LtiAssetProcessor`, `LtiAssetProcessorIframe`, `LtiAssetProcessorWindowSettings`, `LtiAssetReport`, `MediaSource`, `MessagePermissions`, `MessageableContext`, `ModeratedGrading`, `ModuleCompletionRequirement`, `ModuleExternalTool`, `ModuleItem`, `ModuleItemMasterCourseRestriction`, `ModuleItemMasteryPathInfo`, `ModulePrerequisite`, `ModuleProgression`, `ModuleProgressionStatistics`, `ModuleStatistics`, `Mutation`, `MutationLog`, `Noop`, `Notification`, `NotificationPolicy`, `OutcomeCalculationMethod`, `OutcomeFriendlyDescriptionType`, `OutcomeProficiency`, `PageViewAnalysis`, `PeerReviewDates`, `PeerReviewStatus`, `PeerReviewSubAssignment`, `PostPolicy`, `ProficiencyRating`, `Progress`, `ProvisionalGrade`, `Query`, `QuizItem`, `QuizSubmission`, `Requirement`, `RubricAssessment`, `RubricAssessmentRating`, `RubricAssociation`, `RubricCriterion`, `RubricRating`, `ScheduledPost`, `StandardGradeStatus`, `StreamSummaryItem`, `StudentSummaryAnalytics`, `SubAssignmentSubmission`, `SubHeader`, `SubmissionComment`, `SubmissionDraft`, `SubmissionHistory`, `SubmissionStatistics`, `TardinessBreakdown`, `TurnitinData`, `UsageRights`, `ValidationError`, `VericiteData`

