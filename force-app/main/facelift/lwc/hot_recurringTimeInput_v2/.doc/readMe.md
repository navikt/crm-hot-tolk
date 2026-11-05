# Recurring Time Input

LWC to allow user to create single, multiple and recurring time intervals

Child component of requestForm_request

Delete buttons retain the visible label "Slett". Their accessible names include the
interval number and any entered date, start time and end time, updating as fields change.

Recurring intervals are previewed in a single panel with the total count, first and last
occurrence dates, and any explanation of adjusted date boundaries. The expandable table
shows weekdays, dates and times in the server-provided time zone. Intervals ending on a
different date include the end date in the "Til" column.
The date-boundary explanation does not repeat the summary dates. The disclosure has a
visible chevron and keyboard focus indicator; the compact table wraps dates on narrow
screens. Guidance uses secondary text styling.

The Salesforce user's time zone is expected to be Europe/Oslo. Preview and creation
continue to use that user's time zone. A Norwegian-time notice is shown outside the
expandable list only when browser-local dates or times differ from the preview at any
interval endpoint. Equivalent time zones do not trigger the notice; comparisons account
for daylight-saving changes across the series.

## Exposed

NO
