windowsupdate_ps
=================

An update script that is run locally on each target machine to apply windows updates.

Install
-------
* [Download Script](https://bis-src-prd.ead.ubc.ca/bis-aop/windowsupdate_ps/repository/archive.zip?ref=master)
* Open the maintenance_windows_update.xml​ and edit the following lines to match the schedule that was agreed upon.  NOTE: If the schedule is for the last week of the month, do not use 4, as there can be 5 of the same weekday in a month.  Use the word  "Last".​
​

      <ScheduleByMonthDayOfWeek>
        <Weeks>
          <Week>1</Week>
        </Weeks>
        <DaysOfWeek>
          <Monday />
        </DaysOfWeek>

* ​Copy both the __maintenance_windows_update.xml__​​ and __windowsupdate_ps.ps1__ files to the target system under the folder __"C:\DRS\Scripts\windowsupdate_ps"__.
* On the target system open up an Administrative Shell and enter the following command:
```
​C:\> schtasks.exe /CREATE /XML "C:\DRS\Scripts\windowsupdate_ps\maintenance_windows_update.xml" /TN "maintenance_windows_update" /RU "bopsis" /RP "<BOPSIS PASSWORD from KEYPASS>" /F​
```
* Run the following command to confirm the task was created successfully:
```​
C:\> schtasks.exe /QUERY /TN "maintenance_windows_update"​​​​
```
* Run the follow command if you need to delete the task for any reason:
```
C:\> schtasks.exe /DELETE /TN "maintenance_windows_update" /F
```
