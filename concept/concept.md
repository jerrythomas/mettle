# Concept

1. Window of opportunity (anytime, batch window)
2. Actual Schedule
   - Convert to interval slice_value::interval, to_number(slice_value,'999999999999999')
   - Convert to date to_date(slice_start,'yyyy-mm-dd hh24:mi:ss', to_number(slice_start,'999999999999999')
   - last executed slice, decides when the next slice will run. while this is catching up the available schedule can be set to anytime. Once it catches up, the task runs in incremental mode
   - Calculate the next run value based on the max_running and the timetable defined for the task

## Features

    - When can an interface run? (Anytime in the day, Weekends only, Batch window only)
    - What is the repeated schedule (Daily, Weekly, Monthly, Qtr, 1/2 Yr, 1Yr)
    - Nth day of the week, month, Qtr, year (first, last, nth)
    - Day of week (S-S) - 1st friday, last friday
    - Repeat for N days, unlimited, until specific date/DOW, Week Month etc

## Advantages

## Disadvantages

    What do we need to store?

    - Business Hours : S 0, S 0, M-F 8am-5pm,
    - Offset:1hr, (start time, interval)
    - Non business Hours: opp of Bus Hrs +offset,
    - Anytime : 24hrs nth day of month repeat n days nth day of quarter nth day of year

## Sample schedules

    - [[at 5am] on the] [nth][day|{weekday:monday,sunday ....}] of [day|week|month|quarter|year] repeat every [n] [hour|days|weeks|months|years] [until|for] [date|[days|months]]
    - at every [n][hour|minutes] of the [day]
    - 1st day of week repeat every week
    - 1st day of month repeat every 1 month
    - 1st friday of month repeat every month
    - last friday of month repeat every month
    - last day of month repeat every 2 months
    - every hour.
    - every 10 minutes
    - every day at 5am
    - once every day between 8am and 9pm
    - 1st day of every week
    - 0th minute of every hour
    - monday of every week at 8am
    - 1st monday of every month
    - 1st of every month
    - last day of every month repeat for 5 days at 8
    - 1st of every quarter repeat for 5 days st 6 am
    - 1st october of every year

    Month - [1,4,7,10] or [1,2,3,4,5,6,7,8,9,10,11,12] or [mmm month]
    Week - [0,1,2,3,4,5,6]
    Day - [n,R-N,S-m] n=[0-31] 0 => last day, R => repeat, S => skip

Schedule [used to store and retrieve the config] nth [of every] hr,day,wk,mo,qtr,yr [repeat for] n dy,mo,wk [at] time (1 to n) or (-1) (last) == N hour, day, week, month == of_every n days, n months, n weeks == repeat_for 8 am, 6pm == at
Schedule_Values [ used to store granular values for simplifying the scheduling process]
Start_At [ specified for each interface]
Schedule : contains a list of schedules
Schedule ID
Schedule Code
Schedule Name
Built-In (Default Profiles) -> Non business hrs,
Accounting days (1st of month/Qtr/Yr [Jan/apr])
Effective Date
Schedule Rule : Specify the rule to be followed for a schedule in a simple

- e.g Run Between 18:00 and 06:00 On weekdays and Run Between 0:00 and 0:00 On Weekends For every Day
- Run At 8:00, 12:00 , 18:00 On Monday Every week Run Between 18:00 and 06:00 on Weekdays and Run Between 0:00 and 0:00 On Weekends On the 1st of Every Month Repeat for the next 5 Days

Attributes Schedule ID : unique identifier
Rule ID : To uniquely Identify individual rules.
Example Weekday & weekend rule Frequency : Daily/Weekly/Monthly/Quarterly/Yearly
Typical uses
Daily: Once or more every day. Used in typical incremental loads.
Specific times => Manual data or data that is available at specific times
Weekly: Once or more a week for weekly summaries
Monthly: Monthly GL reports/ Account closure activites. Repetition for up to 5 days to ensure data gets updated.
Quarterly: Once a Quarter summaries/updates
Yearly: End of year closure activities Specified in this entity because of the possibility of running the same entity on every monday/ 1st of every month/ 1st of quarter etc.
RunType : At/Between Start Time, End Time (At uses only start time comma separated values HH24:MI:SS)
RunOn : Weekdays/Weekends/Monday ....Sat/ [Nth Day/Wk/Month] of Frequency-1 level?
Repeat: [N] times Every [Day/Week] (at least one level less that top Frequency
Schedule Values : Expand rule into smallest set of values to simplify queries to fetch a single row from the set based on a date time value. Possible attributes total 14 entries for "Non business hrs" schedule total 14 _ [12 + 4 + 1] for non business hours of 1st day of month/qtr/Yr total 14 _ [12 + 4 + 1]_5 for non business hours of 1st day of month/qtr/Yr Repeat for 5 days 2 Entries for 1st day of week [monday] non business hrs [00:00 - 06:00] & [18:00]- [24:00] NULLS signify Any ==> if a null value is present it just matches with current dates value. Frequency : Daily/Weekly/Monthly/Quarterly/Yearly Weekday : 7 Possible Values (Used for On) Month_Nbr : 1-12 for months of the Monthly frequency [4 entries in the case Quarter and 1 entry in the case of annual], month can be null to allow running on any given month RunOn : [Nth Day Of] Frequency [ Not used for Daily] (Example 1st of month) if N = 0 then it is last day, if negative = last day - N days Roll Window Strt: time start Roll Window End : time end Negative number will start from last of the [frequency) //Repeat : Repetition Value (example 5 ) -> //Causes a new copy of the above rule with a new value for Nth day of --Run on [nth][hour|day|weekday] of [every][week|month|quarter|year] -- repeat every [n][days|weeks|months|years] [until|for]date|[days|months]] --Run Every [Hour] During [business/non business hrs] --Run During [business/non business hrs] on [1st] of every [month] repeat for [5] days -- The task contains the last value for which the load request has been submitted -- The scheduler picks this value and the current date (for time limited) else an unlimited record value -- and proceeds to create entries in the process table for all entries based on time split etc -- The scheduler then picks elements from the process table based on the max parallel -- ,limits on when the entities can be run (available time) etc -- Two sets of views to accomplish this & one to see the queue -- a) ready_to_process_v -- b) ready_to_execute_v -- c) queued_v /_

Some possible reasons for any task to be in queue

- 'A Process has errored out and is waiting for reprocessing'
- 'A Process is already running'
- 'A Process has been scheduled'
- 'A Process is pending'
- 'A Process is running'
- 'Waiting for a prior date to complete' -- (instead of collection it can be any stage...)
- 'Waiting for the dependent entity '
- Specific stage of the mapping 'Waiting for a dependent entity which is waiting..'
- 'Waiting for the "wait-for" dependency load to run first'
- 'Scheduled to run at '||TO_CHAR(dttm from the schedule,'DD-Mon-RRRR HH:MI:SS AM')
- 'Waiting for a process which is running.'
- Show as a gantt chart if possible??
