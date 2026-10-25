# Unit 4: Analysis

## Who Should Act on the Results?

The **Property Operations Manager** would be the main person responsible for acting on the per-property breakdown. This
manager could identify properties with unusually high or low-viewing activity, investigate properties with no viewings,
and work with local teams to improve listing performance. Regional managers could also use the property-and-city
breakdown to understand whether a property performs differently depending on where renters are booking from.

The results show that viewing activity is not evenly distributed across the properties. Some properties received many
viewing requests, while Property_14 and Property_15 received none. Before assuming these properties are underperforming,
the operations manager should check whether they were available for the full reporting period, properly displayed to
renters, and correctly included in search results. A property with no events may represent low renter interest, but it
could also indicate a listing or availability issue.

## What the Aggregates Hide

The overall average viewing duration provides a useful summary, but it hides how the individual viewing durations are
distributed. A property could have the same average as another property while having very different activity. For
example, one property might have mostly consistent viewing durations, while another might have several zero-minute
cancellations mixed with a few unusually long viewings. Task 3.1 showed why this distinction matters: missing values and
filtering choices can silently exclude records or change what a result appears to mean. Similarly, including cancelled
events with zero-minute durations can lower an average and make a property appear to have shorter viewings than it
actually does.

The event count also hides who is being counted. A property with 20 viewing events does not necessarily have 20
different renters. The same renter may have scheduled multiple viewings. A high count could therefore represent broad
interest from many renters or repeated activity from only a small group. The count also does not distinguish between
attended, cancelled, and disputed events. Without that context, a high event count could look positive even if many of
those events never resulted in an actual viewing.

## What We Need to See Next

The next report should show the distribution of viewing durations rather than only the average. This should include the
median duration, the number of zero-minute events, and the number of unusually short or long viewings for each property.
Viewing durations should also be separated by status so that attended viewings are not mixed with cancelled or disputed
events. This would help managers distinguish actual viewing performance from scheduling and cancellation activity.

We should also see the number of distinct renters for each property, the number and percentage of attended, cancelled,
and disputed viewings, and the most common cancellation reasons. For the regional analysis, these measures should be
broken down by property and booking city. Finally, properties with very few events should be clearly identified because
an average or rate based on a small number of events may not represent normal performance. Together, these additions
would give the Property Operations Manager a more complete view of demand, renter participation, cancellations, and
actual viewing performance.