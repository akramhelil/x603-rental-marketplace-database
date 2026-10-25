## Breakdown for the Leadership Team

Across the platform, 10 of the 200 viewing events were marked as disputed, giving a true failure rate of **5.00%**. This
rate uses every viewing in the event table, including attended, cancelled, and disputed events. Earlier analysis showed
that missing cancellation reasons can cause records to be silently left out when a report is filtered incorrectly. For
this finding, failure is based directly on the viewing status, so a blank cancellation reason does not remove a viewing
from the calculation.

The failures were not spread evenly across properties. **Property ID 1** had 2 disputed events out of 11 total events, a
rate of **18.18%**. **Property ID 3** had 2 out of 13, or **15.38%**, and **Property ID 5** had 2 out of 18, or
**11.11%**. These are the three properties I would investigate first because each had at least 10 events and a failure
rate well above the 5.00% platform rate. Property IDs 7, 9, 12, and 13 each had one disputed event, while the remaining
properties had none. Property IDs 14 and 15 had no viewing events, so they should not be treated as having a successful
0% failure rate. There is no activity on which to judge their performance.

The next review should examine the disputed events for Property IDs **1, 3, and 5** individually. Leadership should look
for repeated issues involving scheduling, listing accuracy, property condition, or the viewing process. The team should
also compare disputes by booking region and confirm whether the same renters, dates, or operational patterns appear more
than once. The numbers identify where to start, but they do not explain why the disputes occurred.

## Reflection

Conditional aggregation lets us answer related questions at the same time, such as the total number of viewings and the
number of disputed viewings for each property. A separate-query approach would first scan the data to count all events
and then scan it again to count only failures. That may not feel important with 200 rows, but the difference becomes
meaningful at one million rows.

With conditional aggregation, the database can read each event once and update both totals during the same operation.
Two filtered queries may require repeated reading, filtering, grouping, and sorting of the same large table. That adds
processing time and increases the amount of work performed by the database. It can also make a dashboard slower when
several users refresh it at once.

There is also a consistency benefit. When both numbers come from one grouped result, they use the same set of records
and the same reporting moment. Separate queries are easier to write slightly differently, and data could change between
runs. Conditional aggregation therefore improves efficiency while also making the comparison between total events and
failures easier to trust and maintain.
